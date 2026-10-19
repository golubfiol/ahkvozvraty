namespace Vozvraty;

class SettingsForm : Form
{
    public SettingsForm(Settings s)
    {
        Text = "Настройки";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen;
        MaximizeBox = MinimizeBox = false;
        TopMost = true;
        ClientSize = new Size(500, 420);

        int y = 15;
        void Header(string t)
        {
            Controls.Add(new Label { Text = t, Left = 15, Top = y, Width = 460, Font = new Font(Font, FontStyle.Bold) });
            y += 28;
        }
        TextBox Row(string label, string val, int indent = 0)
        {
            Controls.Add(new Label { Text = label, Left = 15 + indent, Top = y + 3, Width = 200 - indent });
            var tb = new TextBox { Left = 220, Top = y, Width = 265, Text = val };
            Controls.Add(tb);
            y += 32;
            return tb;
        }
        CheckBox Check(string label, bool v)
        {
            var cb = new CheckBox { Text = label, Left = 15, Top = y, Width = 460, Checked = v };
            Controls.Add(cb);
            y += 28;
            return cb;
        }

        Header("Общие");
        var search = Row("Поиск по клиентскому:", s.SearchNumber);
        var accept = Row("Приём через счёт:", s.SearchNumber1);
        var acceptComment = Row("Комментарий (приём):", s.AcceptComment);

        y += 8;
        Header("Особый случай (Ctrl+F5)");
        var client = Row("Клиентский номер:", s.ClientNumber);
        var months = Row("Количество месяцев:", s.Months);
        var usePct = Check("Изменить дефолтный процент", s.UsePercent);
        var pct = Row("Процент:", s.Percent, 20);
        var useCom = Check("Добавить комментарий", s.UseComment);
        var com = Row("Комментарий:", s.Comment, 20);

        usePct.CheckedChanged += (_, _) => pct.Enabled = usePct.Checked;
        useCom.CheckedChanged += (_, _) => com.Enabled = useCom.Checked;
        pct.Enabled = usePct.Checked;
        com.Enabled = useCom.Checked;

        var ok = new Button { Text = "Сохранить", Left = 285, Top = y + 10, Width = 200, Height = 32, DialogResult = DialogResult.OK };
        var cancel = new Button { Text = "Отмена", Left = 15, Top = y + 10, Width = 200, Height = 32, DialogResult = DialogResult.Cancel };
        Controls.Add(ok);
        Controls.Add(cancel);
        AcceptButton = ok;
        CancelButton = cancel;
        ClientSize = new Size(500, y + 60);

        ok.Click += (_, _) =>
        {
            if (!string.IsNullOrWhiteSpace(search.Text)) s.SearchNumber = search.Text.Trim();
            if (!string.IsNullOrWhiteSpace(accept.Text)) s.SearchNumber1 = accept.Text.Trim();
            if (!string.IsNullOrWhiteSpace(acceptComment.Text)) s.AcceptComment = acceptComment.Text;
            s.ClientNumber = client.Text.Trim();
            s.Months = months.Text.Trim();
            s.UsePercent = usePct.Checked;
            s.Percent = pct.Text.Trim();
            s.UseComment = useCom.Checked;
            s.Comment = com.Text;
        };
    }
}
