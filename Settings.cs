using System.Text.Encodings.Web;
using System.Text.Json;

namespace Vozvraty;

class Settings
{
    public const string ProfileReturns = "Отдел возвратов";
    public const string ProfileDeka = "Дека";

    public string Profile { get; set; } = ProfileReturns;
    public bool AutostartInitialized { get; set; }   // автозапуск включается сам только при первом запуске
    public string SearchNumber { get; set; } = "66811";     // поиск по клиентскому
    public string SearchNumber1 { get; set; } = "86958";    // приём через счёт
    public string AcceptComment { get; set; } = "Товар с реализации";

    // Особый случай (Ctrl+F5)
    public string ClientNumber { get; set; } = "";
    public string Months { get; set; } = "";
    public bool UsePercent { get; set; }
    public string Percent { get; set; } = "";
    public bool UseComment { get; set; }
    public string Comment { get; set; } = "";

    // Профиль «Дека»
    public string DekaCode1 { get; set; } = "]C04WjP7O8j03fMZPHPvqEA8A0r+cUP/XLX";
    public string DekaCode2 { get; set; } = "]C00Wjhz/xLVeod5LTxah1T9EodPWB/2tHx";

    static string Dir => Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "Vozvraty");
    static string FilePath => Path.Combine(Dir, "settings.json");

    public static Settings Load()
    {
        try
        {
            if (File.Exists(FilePath))
            {
                var s = JsonSerializer.Deserialize<Settings>(File.ReadAllText(FilePath)) ?? new Settings();
                if (s.Profile != ProfileReturns && s.Profile != ProfileDeka) s.Profile = ProfileReturns;
                return s;
            }
        }
        catch { /* битый файл — начинаем с дефолтов */ }
        return new Settings();
    }

    public void Save()
    {
        Directory.CreateDirectory(Dir);
        var opts = new JsonSerializerOptions { WriteIndented = true, Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping };
        File.WriteAllText(FilePath, JsonSerializer.Serialize(this, opts));
    }
}

/// <summary>Все экранные координаты в одном месте. Если в рабочей программе что-то съехало — правь здесь.</summary>
static class Pt
{
    // Ctrl+Numpad1 — приём через счёт
    public static readonly Point AcceptSearchField = new(865, 367);
    public static readonly Point AcceptCommentField = new(980, 310);   // двойной клик

    // Ctrl+Numpad2 — поиск по коду на портале
    public static readonly Point SourceCodeCell = new(312, 240);       // двойной клик
    public static readonly Point PortalSearchField = new(1796, 94);

    // Ctrl+Numpad4 — «47»
    public static readonly Point P47_Field = new(833, 143);
    public static readonly Point P47_Ok = new(274, 126);
    public static readonly Point P47_C1 = new(321, 882);
    public static readonly Point P47_C2 = new(256, 795);
    public static readonly Point P47_C3 = new(174, 947);

    // Ctrl+F5 — особый случай
    public static readonly Point F5_Field = new(830, 138);
    public static readonly Point F5_Ok = new(235, 124);
    public static readonly Point F5_C1 = new(264, 879);
    public static readonly Point F5_C2 = new(264, 612);
    public static readonly Point F5_Percent = new(173, 947);
    public static readonly Point F5_Comment = new(1157, 905);

    // Ctrl+Numpad5 — поиск по клиентскому
    public static readonly Point ClientField = new(828, 143);

    // Поздний возврат (Ctrl+Numpad7/8/9)
    public static readonly Point Late_C1 = new(370, 877);
    public static readonly Point Late_C2 = new(352, 813);
    public static readonly Point Late_Field = new(181, 951);
    public static readonly Point Late_Comment = new(779, 914);

    // Дека
    public static readonly Point Deka_List = new(52, 623);
    public static readonly Point Deka_New = new(16, 68);
    public static readonly Point Deka_Name = new(719, 418);
    public static readonly Point Deka_Combo = new(931, 556);
    public static readonly Point Deka_Create = new(1200, 702);
    public static readonly Point Deka_T1 = new(758, 658);
    public static readonly Point Deka_T2 = new(875, 453);
    public static readonly Point Deka_T3 = new(1053, 660);
    public static readonly Point Deka_CodeField = new(959, 380);
}
