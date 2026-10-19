using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text;
using static Vozvraty.Native;

namespace Vozvraty;

/// <summary>Эмуляция клавиатуры/мыши. Вызывать только из рабочего STA-потока.</summary>
static class Input
{
    public static int Delay = 50;

    static void Send(params INPUT[] i) => SendInput((uint)i.Length, i, Marshal.SizeOf<INPUT>());

    static bool IsExtended(ushort vk) => (vk >= 0x21 && vk <= 0x28) || vk == 0x2D || vk == 0x2E;

    static INPUT Kb(ushort vk, bool up) => new()
    {
        type = 1,
        u = new InputUnion { ki = new KEYBDINPUT { wVk = vk, dwFlags = (up ? 2u : 0u) | (IsExtended(vk) ? 1u : 0u) } }
    };

    static INPUT Mouse(uint flags) => new() { type = 0, u = new InputUnion { mi = new MOUSEINPUT { dwFlags = flags } } };

    public static void Wait(int ms) => Thread.Sleep(ms);

    public static void Tap(ushort vk)
    {
        Send(Kb(vk, false));
        Thread.Sleep(10);
        Send(Kb(vk, true));
        Thread.Sleep(Delay);
    }

    /// <summary>Сочетание: модификаторы зажимаются, нажимается клавиша, всё отпускается.</summary>
    public static void Combo(ushort vk, params ushort[] mods)
    {
        foreach (var m in mods) { Send(Kb(m, false)); Thread.Sleep(10); }
        Send(Kb(vk, false)); Thread.Sleep(10);
        Send(Kb(vk, true)); Thread.Sleep(10);
        foreach (var m in mods.Reverse()) { Send(Kb(m, true)); Thread.Sleep(10); }
        Thread.Sleep(Delay);
    }

    public static void Type(string text)
    {
        foreach (char c in text)
        {
            Send(new INPUT { type = 1, u = new InputUnion { ki = new KEYBDINPUT { wScan = c, dwFlags = 4 } } });
            Send(new INPUT { type = 1, u = new InputUnion { ki = new KEYBDINPUT { wScan = c, dwFlags = 4 | 2 } } });
            Thread.Sleep(10);
        }
        Thread.Sleep(Delay);
    }

    public static void Click(Point p, int count = 1, int gapMs = 50)
    {
        for (int i = 0; i < count; i++)
        {
            SetCursorPos(p.X, p.Y);
            Thread.Sleep(10);
            Send(Mouse(0x0002), Mouse(0x0004));
            Thread.Sleep(i < count - 1 ? gapMs : Delay);
        }
    }

    public static void Paste(string text)
    {
        if (string.IsNullOrEmpty(text)) return;
        for (int i = 0; i < 10; i++)
        {
            try { Clipboard.SetText(text); break; }
            catch (ExternalException) { Thread.Sleep(50); }
        }
        Combo(VK.V, VK.Ctrl);
    }

    /// <summary>Ждём, пока пользователь отпустит Ctrl, иначе он примешается к эмулируемым нажатиям.</summary>
    public static void WaitCtrlReleased()
    {
        var sw = Stopwatch.StartNew();
        while ((GetAsyncKeyState(VK.Ctrl) & 0x8000) != 0 && sw.ElapsedMilliseconds < 3000)
            Thread.Sleep(10);
        Thread.Sleep(30);
    }

    public static string ForegroundTitle()
    {
        var sb = new StringBuilder(512);
        GetWindowText(GetForegroundWindow(), sb, sb.Capacity);
        return sb.ToString();
    }

    public static bool ActivateProcessWindow(string processName)
    {
        var p = Process.GetProcessesByName(processName).FirstOrDefault(x => x.MainWindowHandle != IntPtr.Zero);
        if (p == null) return false;
        var h = p.MainWindowHandle;
        if (IsIconic(h)) ShowWindow(h, 9);

        uint fgThread = GetWindowThreadProcessId(GetForegroundWindow(), out _);
        uint me = GetCurrentThreadId();
        AttachThreadInput(me, fgThread, true);
        SetForegroundWindow(h);
        AttachThreadInput(me, fgThread, false);

        var sw = Stopwatch.StartNew();
        while (GetForegroundWindow() != h && sw.ElapsedMilliseconds < 2000) Thread.Sleep(20);
        Thread.Sleep(300);
        return GetForegroundWindow() == h;
    }
}
