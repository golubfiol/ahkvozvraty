using System.Runtime.InteropServices;
using System.Text;

namespace Vozvraty;

static class Native
{
    [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mod, uint vk);
    [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h, int id);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vk);
    [DllImport("user32.dll", SetLastError = true)] public static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint a, uint b, bool attach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder sb, int max);

    [StructLayout(LayoutKind.Sequential)]
    public struct INPUT { public uint type; public InputUnion u; }

    [StructLayout(LayoutKind.Explicit)]
    public struct InputUnion
    {
        [FieldOffset(0)] public MOUSEINPUT mi;
        [FieldOffset(0)] public KEYBDINPUT ki;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public UIntPtr dwExtraInfo; }

    [StructLayout(LayoutKind.Sequential)]
    public struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public UIntPtr dwExtraInfo; }
}

/// <summary>Виртуальные коды клавиш.</summary>
static class VK
{
    public const ushort Back = 0x08, Tab = 0x09, Enter = 0x0D, Shift = 0x10, Ctrl = 0x11, Esc = 0x1B;
    public const ushort End = 0x23, Home = 0x24, Left = 0x25, Up = 0x26, Down = 0x28;
    public const ushort Insert = 0x2D, Delete = 0x2E, LWin = 0x5B;
    public const ushort N = 0x4E, C = 0x43, V = 0x56, D1 = 0x31;
    public const ushort Num0 = 0x60, Num1 = 0x61, Num2 = 0x62, Num4 = 0x64, Num5 = 0x65,
                        Num7 = 0x67, Num8 = 0x68, Num9 = 0x69, NumAdd = 0x6B, NumSub = 0x6D, NumDiv = 0x6F;
    public const ushort F5 = 0x74, F10 = 0x79;
}
