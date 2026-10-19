using System.Diagnostics;
using System.Net.Http;
using System.Reflection;
using System.Security.Cryptography;
using System.Text.Json;

namespace Vozvraty;

/// <summary>
/// Автообновление из GitHub Releases: берёт последний релиз, сравнивает тег (v8.0.1) с версией сборки,
/// скачивает Vozvraty.exe из ассетов, подменяет себя и перезапускается.
/// </summary>
static class Updater
{
    const string Repo = "golubfiol/ahkvozvraty";
    const string AssetName = "Vozvraty.exe";

    public static Version Current
    {
        get
        {
            var v = Assembly.GetExecutingAssembly().GetName().Version ?? new Version(0, 0, 0, 0);
            return Normalize(v);
        }
    }

    static Version Normalize(Version v) => new(v.Major, v.Minor, Math.Max(v.Build, 0), Math.Max(v.Revision, 0));

    public static void CleanupOld()
    {
        try { File.Delete(Environment.ProcessPath + ".old"); } catch { }
        try { File.Delete(Environment.ProcessPath + ".new"); } catch { }
    }

    /// <returns>true — обновление установлено, новый процесс запущен, текущий надо закрыть.</returns>
    public static async Task<bool> TryUpdateAsync(Action<string> notify)
    {
        using var http = new HttpClient { Timeout = TimeSpan.FromSeconds(60) };
        http.DefaultRequestHeaders.UserAgent.ParseAdd("Vozvraty-Updater");

        var json = await http.GetStringAsync($"https://api.github.com/repos/{Repo}/releases/latest");
        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        var tag = root.GetProperty("tag_name").GetString()?.TrimStart('v', 'V') ?? "";
        if (!Version.TryParse(tag, out var parsed)) return false;
        var latest = Normalize(parsed);
        if (latest <= Current) return false;

        string? url = null, digest = null;
        foreach (var a in root.GetProperty("assets").EnumerateArray())
        {
            if (a.GetProperty("name").GetString() == AssetName)
            {
                url = a.GetProperty("browser_download_url").GetString();
                if (a.TryGetProperty("digest", out var d)) digest = d.GetString();
                break;
            }
        }
        if (url == null) return false;

        notify($"Найдена версия {latest}. Обновляю...");

        var bytes = await http.GetByteArrayAsync(url);
        if (bytes.Length < 100_000 || bytes[0] != (byte)'M' || bytes[1] != (byte)'Z')
            throw new InvalidDataException("Скачан не exe-файл");

        if (digest != null && digest.StartsWith("sha256:", StringComparison.OrdinalIgnoreCase))
        {
            var actual = Convert.ToHexString(SHA256.HashData(bytes));
            if (!actual.Equals(digest[7..], StringComparison.OrdinalIgnoreCase))
                throw new InvalidDataException("Контрольная сумма не совпала");
        }

        var exe = Environment.ProcessPath!;
        var tmp = exe + ".new";
        await File.WriteAllBytesAsync(tmp, bytes);

        // Работающий exe на NTFS можно переименовать, но нельзя перезаписать.
        File.Move(exe, exe + ".old", true);
        File.Move(tmp, exe, true);

        Process.Start(new ProcessStartInfo(exe, "--restart") { UseShellExecute = false });
        return true;
    }
}
