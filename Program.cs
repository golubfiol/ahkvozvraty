using System.Diagnostics;
using Microsoft.Win32;
using static Vozvraty.VK;

namespace Vozvraty;

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        bool restart = args.Contains("--restart");
        using var mutex = new Mutex(false, "Vozvraty.SingleInstance");
        bool owned;
        try { owned = mutex.WaitOne(restart ? 10000 : 0); }
        catch (AbandonedMutexException) { owned = true; }
        if (!owned) return;

        try
        {
            ApplicationConfiguration.Initialize();
            Updater.CleanupOld();
            Application.Run(new TrayApp());
        }
        finally
        {
            try { mutex.ReleaseMutex(); } catch { }
        }
    }
}

/// <summary>Окно-приёмник сообщений WM_HOTKEY.</summary>
class HotkeyWindow : NativeWindow
{
    public event Action<int>? Pressed;
    public HotkeyWindow() => CreateHandle(new CreateParams());
    protected override void WndProc(ref Message m)
    {
        if (m.Msg == 0x0312) Pressed?.Invoke(m.WParam.ToInt32());
        base.WndProc(ref m);
    }
}

class TrayApp : ApplicationContext
{
    const uint MOD_CTRL = 0x0002, MOD_NOREPEAT = 0x4000;
    const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";

    readonly Settings S = Settings.Load();
    readonly Overlay O = new();
    readonly Actions A;
    readonly NotifyIcon tray = new();
    readonly HotkeyWindow hk = new();
    readonly Dictionary<int, Action> handlers = new();
    int busy;

    public TrayApp()
    {
        A = new Actions(S, O);
        O.NotifyHandler = Notify;
        O.Rebuild(S.Profile);
        O.Show();

        // Первый запуск: включаем автозапуск. Дальше уважаем выбор из меню в трее.
        if (!S.AutostartInitialized)
        {
            SetAutostart(true, silent: true);
            S.AutostartInitialized = true;
            S.Save();
        }

        BuildTray();
        RegisterHotkeys();
        hk.Pressed += id => { if (handlers.TryGetValue(id, out var h)) h(); };

        _ = CheckUpdatesAsync(manual: false);
    }

    // ---------- хоткеи ----------

    void Bind(bool ctrl, ushort vk, Action a)
    {
        int id = handlers.Count + 1;
        if (Native.RegisterHotKey(hk.Handle, id, (ctrl ? MOD_CTRL : 0) | MOD_NOREPEAT, vk))
            handlers[id] = a;
        else
            Notify("Vozvraty", $"Не удалось занять хоткей (vk=0x{vk:X2}) — он уже используется другой программой");
    }

    /// <summary>Запуск сценария в отдельном STA-потоке (нужен для буфера обмена). Параллельно — только один.</summary>
    void Run(Action<Actions> body, string? profile = null)
    {
        if (profile != null && S.Profile != profile) return;
        if (Interlocked.Exchange(ref busy, 1) == 1) return;

        var t = new Thread(() =>
        {
            O.Running = true;
            try { Input.WaitCtrlReleased(); body(A); }
            catch (Exception ex) { O.SetStatus("Ошибка: " + ex.Message); }
            finally { O.Running = false; Interlocked.Exchange(ref busy, 0); }
        });
        t.SetApartmentState(ApartmentState.STA);
        t.IsBackground = true;
        t.Start();
    }

    void RegisterHotkeys()
    {
        const string R = Settings.ProfileReturns, D = Settings.ProfileDeka;

        Bind(true, NumDiv, SwitchProfile);
        Bind(false, Insert, ToggleOverlay);
        Bind(false, Home, Restart);
        Bind(false, End, ExitApp);
        Bind(true, NumSub, ResetTask);
        Bind(true, Num0, () => { if (S.Profile == R) OpenSettings(); });

        Bind(true, Num1, () => Run(a => a.Numpad1()));            // профиль проверяется внутри
        Bind(true, Num2, () => Run(a => a.Numpad2(), R));
        Bind(true, Num4, () => Run(a => a.Numpad4(), R));
        Bind(true, F5, () => Run(a => a.F5(), R));
        Bind(true, NumAdd, () => Run(a => a.Continue(), R));
        Bind(true, Num5, () => Run(a => a.Numpad5(), R));
        Bind(true, Num7, () => { if (S.Profile == D) Run(a => a.DekaTrial(S.DekaCode1)); else Run(a => a.LateReturn("9"), R); });
        Bind(true, Num8, () => { if (S.Profile == D) Run(a => a.DekaTrial(S.DekaCode2)); else Run(a => a.LateReturn("18"), R); });
        Bind(true, Num9, () => Run(a => a.LateReturn("27"), R));
    }

    // ---------- команды ----------

    void SwitchProfile()
    {
        S.Profile = S.Profile == Settings.ProfileReturns ? Settings.ProfileDeka : Settings.ProfileReturns;
        S.Save();
        Notify("Профиль", "Активен: " + S.Profile);
        O.Rebuild(S.Profile);
    }

    void ToggleOverlay() { if (O.Visible) O.Hide(); else O.Show(); }

    void ResetTask()
    {
        if (S.Profile != Settings.ProfileReturns) return;
        O.Current = "";
        O.WaitText = "";
        O.SetStatus("Сброшено. Готов к новой задаче.");
    }

    void OpenSettings()
    {
        using var f = new SettingsForm(S);
        if (f.ShowDialog() == DialogResult.OK)
        {
            S.Save();
            O.SetStatus("Настройки сохранены");
        }
    }

    void Restart()
    {
        Process.Start(new ProcessStartInfo(Environment.ProcessPath!, "--restart") { UseShellExecute = false });
        ExitApp();
    }

    void ExitApp()
    {
        foreach (var id in handlers.Keys) Native.UnregisterHotKey(hk.Handle, id);
        tray.Visible = false;
        tray.Dispose();
        O.Close();
        ExitThread();
    }

    // ---------- трей ----------

    void BuildTray()
    {
        var autostart = new ToolStripMenuItem("Автозапуск") { Checked = IsAutostart(), CheckOnClick = true };
        autostart.CheckedChanged += (_, _) => SetAutostart(autostart.Checked, silent: false);

        var menu = new ContextMenuStrip();
        menu.Items.Add("Показать/скрыть панель", null, (_, _) => ToggleOverlay());
        menu.Items.Add("Настройки", null, (_, _) => OpenSettings());
        menu.Items.Add("Проверить обновления", null, async (_, _) => await CheckUpdatesAsync(manual: true));
        menu.Items.Add(autostart);
        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Перезапуск", null, (_, _) => Restart());
        menu.Items.Add("Выход", null, (_, _) => ExitApp());

        tray.Icon = SystemIcons.Application;
        tray.Text = $"Vozvraty {Updater.Current}";
        tray.ContextMenuStrip = menu;
        tray.Visible = true;
    }

    public void Notify(string title, string text)
    {
        if (O.IsDisposed) return;
        void Show() => tray.ShowBalloonTip(3000, title, text, ToolTipIcon.Info);
        if (O.InvokeRequired) O.BeginInvoke(Show); else Show();
    }

    // ---------- автозапуск и обновления ----------

    static bool IsAutostart()
    {
        using var k = Registry.CurrentUser.OpenSubKey(RunKey);
        return k?.GetValue("Vozvraty") is string v && v.Trim('"') == Environment.ProcessPath;
    }

    void SetAutostart(bool on, bool silent)
    {
        try
        {
            using var k = Registry.CurrentUser.OpenSubKey(RunKey, true)!;
            if (on)
            {
                var want = $"\"{Environment.ProcessPath}\"";
                if (k.GetValue("Vozvraty") as string == want) return;
                k.SetValue("Vozvraty", want);
                if (!silent) Notify("Автозапуск", "Включён");
            }
            else
            {
                k.DeleteValue("Vozvraty", false);
                if (!silent) Notify("Автозапуск", "Выключен");
            }
        }
        catch (Exception ex) { Notify("Автозапуск", "Ошибка: " + ex.Message); }
    }

    async Task CheckUpdatesAsync(bool manual)
    {
        try
        {
            bool updated = await Updater.TryUpdateAsync(msg => Notify("Обновление", msg));
            if (updated) { ExitApp(); return; }
            if (manual) Notify("Обновление", "Установлена последняя версия");
        }
        catch (Exception ex)
        {
            if (manual) Notify("Обновление", "Ошибка: " + ex.Message);
        }
    }
}
