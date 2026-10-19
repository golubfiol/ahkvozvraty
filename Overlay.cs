using System.Drawing.Drawing2D;
using System.Drawing.Text;

namespace Vozvraty;

/// <summary>Панель-подсказка: тёмная карточка со скруглёнными углами, поверх всех окон, клики проходят сквозь.</summary>
class Overlay : Form
{
    record Bind(string Keys, string Text);

    // ---- палитра ----
    static readonly Color CBg = Color.FromArgb(24, 26, 33);
    static readonly Color CPanel = Color.FromArgb(34, 38, 48);
    static readonly Color CBorder = Color.FromArgb(52, 57, 70);
    static readonly Color CText = Color.FromArgb(233, 236, 242);
    static readonly Color CMuted = Color.FromArgb(138, 146, 162);
    static readonly Color CChip = Color.FromArgb(40, 45, 58);
    static readonly Color CChipText = Color.FromArgb(150, 190, 255);
    static readonly Color CGreen = Color.FromArgb(74, 222, 128);
    static readonly Color CAmber = Color.FromArgb(251, 191, 36);
    static readonly Color CRed = Color.FromArgb(248, 113, 113);

    const float W = 380;       // ширина в условных пикселях (масштабируется по DPI)
    const float Pad = 16;
    const float RowH = 26;
    const float SysRowH = 24;

    static readonly Bind[] ReturnsBinds =
    {
        new("Ctrl+Num 1", "Приём через счёт"),
        new("Ctrl+Num 2", "Поиск по коду на портале"),
        new("Ctrl+Num 4", "47"),
        new("Ctrl+F5",    "Особый случай"),
        new("Ctrl+Num 5", "Поиск по клиентскому"),
        new("Ctrl+Num 7", "Поздний возврат 9"),
        new("Ctrl+Num 8", "Поздний возврат 18"),
        new("Ctrl+Num 9", "Поздний возврат 27"),
        new("Ctrl+Num 0", "Настройки"),
        new("Ctrl+Num +", "Продолжить задачу"),
        new("Ctrl+Num −", "Сброс"),
    };

    static readonly Bind[] DekaBinds =
    {
        new("Ctrl+Num 1", "Создать список v-склады"),
        new("Ctrl+Num 7", "Триал Виталий"),
        new("Ctrl+Num 8", "Триал Георгий"),
    };

    static readonly Bind[] SystemBinds =
    {
        new("Ctrl+Num /", "Сменить профиль"),
        new("Insert",     "Скрыть / показать"),
        new("Home",       "Перезапуск"),
        new("End",        "Закрыть"),
    };

    readonly Font fTitle = new("Segoe UI Semibold", 13f);
    readonly Font fLabel = new("Segoe UI Semibold", 7.5f);
    readonly Font fRow = new("Segoe UI", 9.5f);
    readonly Font fSys = new("Segoe UI", 8.5f);
    readonly Font fChip = new("Segoe UI Semibold", 8f);
    readonly Font fStatus = new("Segoe UI Semibold", 10f);
    readonly System.Windows.Forms.Timer timer = new() { Interval = 500 };

    string profile = Settings.ProfileReturns;
    string statusText = "Готов";
    bool pulse;

    public volatile string Current = "";
    public string WaitText = "";
    public volatile bool Running;
    public Action<string, string>? NotifyHandler;

    public Overlay()
    {
        FormBorderStyle = FormBorderStyle.None;
        TopMost = true;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        BackColor = CBg;
        Opacity = 0.94;
        DoubleBuffered = true;
        ResizeRedraw = true;

        timer.Tick += (_, _) =>
        {
            pulse = !pulse;
            if (Current != "" || Running) Invalidate();
        };
        timer.Start();
    }

    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            var cp = base.CreateParams;
            cp.ExStyle |= 0x80 | 0x20 | 0x08000000; // TOOLWINDOW | TRANSPARENT | NOACTIVATE
            return cp;
        }
    }

    public void SetStatus(string text)
    {
        if (IsDisposed) return;
        void Apply() { statusText = text; Invalidate(); }
        if (InvokeRequired) BeginInvoke(Apply); else Apply();
    }

    public void Notify(string title, string text) => NotifyHandler?.Invoke(title, text);

    float Scale => DeviceDpi / 96f;

    Bind[] ProfileBinds => profile == Settings.ProfileReturns ? ReturnsBinds : DekaBinds;
    Color Accent => profile == Settings.ProfileReturns ? Color.FromArgb(96, 165, 250) : Color.FromArgb(251, 146, 60);

    public void Rebuild(string newProfile)
    {
        profile = newProfile;
        float k = Scale;
        float h = 278 + RowH * ProfileBinds.Length;

        ClientSize = new Size((int)(W * k), (int)(h * k));
        var area = Screen.PrimaryScreen!.WorkingArea;
        Location = new Point(area.Right - Width - 20, area.Top + Math.Max(0, (area.Height - Height) / 2));

        using var path = Rounded(new RectangleF(0, 0, Width, Height), 14 * k);
        Region = new Region(path);
        Invalidate();
    }

    static GraphicsPath Rounded(RectangleF r, float radius)
    {
        float d = radius * 2;
        var p = new GraphicsPath();
        p.AddArc(r.X, r.Y, d, d, 180, 90);
        p.AddArc(r.Right - d, r.Y, d, d, 270, 90);
        p.AddArc(r.Right - d, r.Bottom - d, d, d, 0, 90);
        p.AddArc(r.X, r.Bottom - d, d, d, 90, 90);
        p.CloseFigure();
        return p;
    }

    void Txt(Graphics g, string s, Font f, Color c, float x, float y, float w, float h, StringAlignment align = StringAlignment.Near)
    {
        using var br = new SolidBrush(c);
        using var sf = new StringFormat
        {
            Alignment = align,
            LineAlignment = StringAlignment.Center,
            Trimming = StringTrimming.EllipsisCharacter,
            FormatFlags = StringFormatFlags.NoWrap
        };
        g.DrawString(s, f, br, new RectangleF(x, y, w, h), sf);
    }

    void FillRound(Graphics g, Color c, float x, float y, float w, float h, float r)
    {
        using var p = Rounded(new RectangleF(x, y, w, h), r);
        using var b = new SolidBrush(c);
        g.FillPath(b, p);
    }

    void Chip(Graphics g, Bind b, float k, float y, float rowH, bool muted)
    {
        float chipW = 92, chipH = rowH - 6;
        float cy = y + (rowH - chipH) / 2;
        FillRound(g, CChip, Pad * k, cy * k, chipW * k, chipH * k, 5 * k);
        Txt(g, b.Keys, fChip, muted ? CMuted : CChipText, Pad * k, cy * k, chipW * k, chipH * k, StringAlignment.Center);
        Txt(g, b.Text, muted ? fSys : fRow, muted ? CMuted : CText,
            (Pad + chipW + 10) * k, y * k, (W - Pad * 2 - chipW - 10) * k, rowH * k);
    }

    protected override void OnPaint(PaintEventArgs e)
    {
        var g = e.Graphics;
        g.SmoothingMode = SmoothingMode.AntiAlias;
        g.TextRenderingHint = TextRenderingHint.ClearTypeGridFit;
        float k = Scale;

        // рамка
        using (var bp = new Pen(CBorder, 1.5f * k))
        using (var path = Rounded(new RectangleF(0.75f * k, 0.75f * k, Width - 1.5f * k, Height - 1.5f * k), 14 * k))
            g.DrawPath(bp, path);

        // шапка: акцентная полоска + название профиля
        FillRound(g, Accent, Pad * k, 18 * k, 4 * k, 38 * k, 2 * k);
        Txt(g, "ПРОФИЛЬ", fLabel, CMuted, (Pad + 14) * k, 16 * k, 200 * k, 16 * k);
        Txt(g, profile, fTitle, CText, (Pad + 14) * k, 30 * k, (W - Pad * 2 - 14) * k, 28 * k);

        float y = 70;
        using var divider = new Pen(CBorder, 1f * k);
        g.DrawLine(divider, Pad * k, y * k, (W - Pad) * k, y * k);

        // горячие клавиши профиля
        Txt(g, "ГОРЯЧИЕ КЛАВИШИ", fLabel, CMuted, Pad * k, 78 * k, 250 * k, 16 * k);
        y = 100;
        foreach (var b in ProfileBinds) { Chip(g, b, k, y, RowH, false); y += RowH; }

        y += 6;
        g.DrawLine(divider, Pad * k, y * k, (W - Pad) * k, y * k);
        y += 8;

        // системные
        foreach (var b in SystemBinds) { Chip(g, b, k, y, SysRowH, true); y += SysRowH; }
        y += 8;

        // статус
        FillRound(g, CPanel, Pad * k, y * k, (W - Pad * 2) * k, 44 * k, 9 * k);

        bool waiting = Current != "" && !Running;
        string text = waiting ? WaitText : statusText;
        Color dot = waiting ? CAmber
            : text == "Готов" ? CGreen
            : text.StartsWith("Ошибка") ? CRed
            : CAmber;
        if ((waiting || Running) && pulse) dot = Color.FromArgb(110, dot);

        using (var db = new SolidBrush(dot))
            g.FillEllipse(db, (Pad + 14) * k, (y + 16) * k, 12 * k, 12 * k);

        float tx = (Pad + 36) * k, tw = (W - Pad * 2 - 46) * k;
        if (waiting)
        {
            Txt(g, text, fStatus, CText, tx, (y + 5) * k, tw, 20 * k);
            Txt(g, "Ctrl+Num + — продолжить", fSys, CMuted, tx, (y + 24) * k, tw, 16 * k);
        }
        else
        {
            Txt(g, text, fStatus, CText, tx, y * k, tw, 44 * k);
        }
    }
}
