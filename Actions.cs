using static Vozvraty.VK;

namespace Vozvraty;

/// <summary>Сценарии для хоткеев. Выполняются в рабочем потоке.</summary>
class Actions
{
    readonly Settings S;
    readonly Overlay O;

    public Actions(Settings s, Overlay o) { S = s; O = o; }

    void St(string t) => O.SetStatus(t);

    void Finish(string msg = "Задача завершена")
    {
        O.Current = "";
        O.WaitText = "";
        St(msg);
        Input.Wait(1200);
        St("Готов");
    }

    // ---- Ctrl+Numpad1 ----
    public void Numpad1()
    {
        if (S.Profile == Settings.ProfileDeka) { DekaCreateList(); return; }

        O.Current = "1";
        O.WaitText = "Ожидание приём через счёт";
        St("Приём через счёт: часть 1...");
        Input.Combo(N, Ctrl);
        Input.Tap(Up);
        Input.Click(Pt.AcceptSearchField);
        Input.Type(S.SearchNumber1);
        Input.Tap(Enter);
    }

    void DekaCreateList()
    {
        St("Дека: Создать список v-склады...");
        Input.Click(Pt.Deka_List);
        Input.Wait(3000);
        Input.Click(Pt.Deka_New);
        Input.Wait(1000);
        Input.Click(Pt.Deka_Name);
        Input.Paste("v-склады из Елино на Лит");
        Input.Click(Pt.Deka_Combo);
        Input.Type("м");
        Input.Tap(Down); Input.Tap(Down); Input.Tap(Down);
        Input.Tap(Enter);
        Input.Click(Pt.Deka_Create);
        St("Дека: готово");
        Input.Wait(1200);
        St("Готов");
    }

    // ---- Ctrl+Numpad2 ----
    static readonly string[] PortalTabs =
        { "Информация по коду", "НОВОСТИ", "Коды последних запросов", "Уточнение кода" };

    static bool TitleMatches(string title) => PortalTabs.Any(t => title.Contains(t, StringComparison.Ordinal));

    public void Numpad2()
    {
        if (S.Profile != Settings.ProfileReturns) return;

        St("Numpad2: Win+Up...");
        Input.Combo(Up, LWin);
        St("Numpad2: пауза...");
        Input.Wait(1000);

        St("Numpad2: копирую код...");
        Input.Click(Pt.SourceCodeCell, 2, 100);
        Input.Combo(C, Ctrl);

        if (!Input.ActivateProcessWindow("msedge"))
        {
            O.Notify("Vozvraty", "Edge не запущен");
            St("Готов");
            return;
        }

        bool found = false;
        Input.Combo(D1, Ctrl);
        Input.Wait(300);
        for (int i = 0; i < 20 && !found; i++)
        {
            if (TitleMatches(Input.ForegroundTitle())) { found = true; break; }
            Input.Combo(Tab, Ctrl, Shift);
            Input.Wait(200);
        }
        if (!found)
        {
            Input.Combo(D1, Ctrl);
            Input.Wait(300);
            for (int i = 0; i < 20 && !found; i++)
            {
                if (TitleMatches(Input.ForegroundTitle())) { found = true; break; }
                Input.Combo(Tab, Ctrl);
                Input.Wait(200);
            }
        }
        if (!found)
        {
            St("Numpad2: вкладка не найдена");
            O.Notify("Vozvraty", "Не найдена ни одна из вкладок портала");
            Input.Wait(2500);
            St("Готов");
            return;
        }

        Input.Wait(200);
        Input.Tap(Esc);
        Input.Click(Pt.PortalSearchField);
        Input.Combo(V, Ctrl);
        Input.Tap(Enter);
        St("Numpad2: Готово");
        Input.Wait(800);
        St("Готов");
    }

    // ---- Ctrl+Numpad4 («47») ----
    public void Numpad4()
    {
        O.Current = "4";
        O.WaitText = "Ожидание 47";
        St("47: часть 1...");
        Input.Combo(N, Ctrl);
        Input.Tap(Tab);
        Input.Tap(Enter);
        Input.Paste("%Василия петушкова, 25%");
        Input.Tap(Enter);
        Input.Click(Pt.P47_Field);
        Input.Combo(Left, Ctrl, Shift);
        Input.Type("3");
        Input.Click(Pt.P47_Ok);
    }

    // ---- Ctrl+F5 (особый случай) ----
    public void F5()
    {
        O.Current = "F5";
        O.WaitText = "Ожидание особого случая";
        St("Особый случай: часть 1...");
        Input.Combo(N, Ctrl);
        Input.Tap(Tab);
        Input.Tap(Enter);
        Input.Type(S.ClientNumber);
        Input.Click(Pt.F5_Field);
        Input.Combo(Left, Ctrl, Shift);
        Input.Tap(Back);
        Input.Type(S.Months);
        Input.Click(Pt.F5_Ok);
    }

    // ---- Ctrl+Numpad+ (продолжить) ----
    public void Continue()
    {
        switch (O.Current)
        {
            case "1":
                St("Продолжение: Приём через счёт...");
                Input.Click(Pt.AcceptCommentField, 2);
                Input.Paste(S.AcceptComment);
                Input.Tap(Enter);
                Input.Tap(F10);
                Finish();
                break;

            case "4":
                St("Продолжение: 47...");
                Input.Combo(Up, LWin);
                Input.Click(Pt.P47_C1);
                Input.Click(Pt.P47_C2);
                Input.Click(Pt.P47_C3);
                Input.Combo(Left, Ctrl, Shift);
                Input.Type("0");
                Input.Tap(F10);
                Finish();
                break;

            case "F5":
                St("Продолжение: Особый случай...");
                Input.Combo(Up, LWin);
                Input.Click(Pt.F5_C1);
                Input.Click(Pt.F5_C2);
                Input.Click(Pt.F5_Percent);
                Input.Combo(Left, Ctrl, Shift);
                Input.Tap(Back);
                if (S.UsePercent) Input.Type(S.Percent);
                Input.Click(Pt.F5_Comment);
                if (S.UseComment) Input.Paste(S.Comment);
                Input.Tap(Enter);
                Input.Tap(Enter);
                Input.Tap(F10);
                Finish();
                break;

            default:
                St("Нет активной задачи. Нажми Ctrl+Numpad1, Ctrl+Numpad4 или Ctrl+F5");
                Input.Wait(1500);
                St("Готов");
                break;
        }
    }

    // ---- Ctrl+Numpad5 (поиск по клиентскому) ----
    public void Numpad5()
    {
        St("Numpad5: поиск...");
        Input.Combo(N, Ctrl);
        Input.Tap(Down);
        Input.Tap(Enter);
        Input.Type(S.SearchNumber);
        Input.Tap(Enter);
        Input.Click(Pt.ClientField);
        Input.Combo(Left, Ctrl, Shift);
        Input.Tap(Delete);
        Input.Type("3");
        Input.Tap(Enter);
        Input.Tap(Enter);
        St("Numpad5: Готово");
        Input.Wait(800);
        St("Готов");
    }

    // ---- Ctrl+Numpad7/8/9 ----
    public void LateReturn(string num)
    {
        St("Возврат " + num);
        Input.Combo(Up, LWin);
        Input.Click(Pt.Late_C1);
        Input.Click(Pt.Late_C2);
        Input.Click(Pt.Late_Field);
        Input.Combo(Left, Ctrl, Shift);
        Input.Tap(Delete);
        Input.Type(num);
        Input.Click(Pt.Late_Comment);
        Input.Paste("Поздний возврат");
        Input.Tap(Enter);
        Input.Tap(F10);
        Input.Wait(800);
        St("Готов");
    }

    public void DekaTrial(string code)
    {
        St("Дека: вставка кода...");
        Input.Click(Pt.Deka_T1); Input.Wait(300);
        Input.Click(Pt.Deka_T2); Input.Wait(300);
        Input.Click(Pt.Deka_T3); Input.Wait(300);
        Input.Click(Pt.Deka_CodeField);
        Input.Paste(code);
        Input.Tap(Enter);
        St("Дека: готово");
        Input.Wait(1200);
        St("Готов");
    }
}
