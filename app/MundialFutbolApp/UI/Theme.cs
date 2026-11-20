using System.Drawing;
using System.Windows.Forms;

namespace MundialFutbolApp.UI;

public static class Theme
{
    public static readonly Color Fondo = Color.FromArgb(245, 247, 250);
    public static readonly Color Superficie = Color.White;
    public static readonly Color Primario = Color.FromArgb(13, 92, 70);
    public static readonly Color PrimarioHover = Color.FromArgb(18, 115, 88);
    public static readonly Color Texto = Color.FromArgb(33, 41, 54);
    public static readonly Color TextoSuave = Color.FromArgb(110, 120, 133);
    public static readonly Color Borde = Color.FromArgb(222, 228, 235);
    public static readonly Color HoverSecundario = Color.FromArgb(238, 242, 247);
    public static readonly Color Seleccion = Color.FromArgb(219, 236, 230);

    public static Button Boton(string texto, bool primario = false)
    {
        var b = new Button
        {
            Text = texto,
            Size = new Size(88, 30),
            FlatStyle = FlatStyle.Flat,
            Font = new Font("Segoe UI", 9.75F),
            Cursor = Cursors.Hand,
            BackColor = primario ? Primario : Superficie,
            ForeColor = primario ? Color.White : Texto
        };
        b.FlatAppearance.BorderSize = primario ? 0 : 1;
        b.FlatAppearance.BorderColor = Borde;
        b.FlatAppearance.MouseOverBackColor = primario ? PrimarioHover : HoverSecundario;
        return b;
    }

    public static Label Etiqueta(string texto, int x = 0, int y = 0) => new()
    {
        Text = texto,
        AutoSize = true,
        ForeColor = Texto,
        Location = new Point(x, y)
    };

    public static void Grid(DataGridView g)
    {
        g.BackgroundColor = Superficie;
        g.BorderStyle = BorderStyle.None;
        g.GridColor = Borde;
        g.CellBorderStyle = DataGridViewCellBorderStyle.SingleHorizontal;
        g.RowHeadersVisible = false;
        g.AllowUserToAddRows = false;
        g.AllowUserToResizeRows = false;
        g.ReadOnly = true;
        g.SelectionMode = DataGridViewSelectionMode.FullRowSelect;
        g.MultiSelect = false;
        g.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
        g.EnableHeadersVisualStyles = false;
        g.ColumnHeadersHeight = 34;
        g.ColumnHeadersHeightSizeMode = DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
        g.RowTemplate.Height = 28;

        g.ColumnHeadersDefaultCellStyle = new DataGridViewCellStyle
        {
            BackColor = Color.FromArgb(238, 242, 246),
            ForeColor = Texto,
            Font = new Font("Segoe UI Semibold", 9.75F),
            Padding = new Padding(8, 0, 0, 0),
            SelectionBackColor = Color.FromArgb(238, 242, 246),
            SelectionForeColor = Texto
        };
        g.DefaultCellStyle = new DataGridViewCellStyle
        {
            BackColor = Superficie,
            ForeColor = Texto,
            SelectionBackColor = Seleccion,
            SelectionForeColor = Texto,
            Padding = new Padding(8, 0, 0, 0)
        };
        g.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(250, 251, 253);
    }

    public static Panel Barra()
    {
        var barra = new Panel { Dock = DockStyle.Top, Height = 56, BackColor = Superficie };
        barra.Controls.Add(new Panel { Dock = DockStyle.Bottom, Height = 1, BackColor = Borde });
        return barra;
    }

    public static Label Estado() => new()
    {
        Dock = DockStyle.Bottom,
        Height = 30,
        ForeColor = TextoSuave,
        Padding = new Padding(14, 0, 0, 0),
        TextAlign = ContentAlignment.MiddleLeft
    };
}
