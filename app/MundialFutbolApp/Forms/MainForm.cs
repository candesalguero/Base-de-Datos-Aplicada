using System.Drawing;
using System.Windows.Forms;
using MundialFutbolApp.UI;

namespace MundialFutbolApp.Forms;

public class MainForm : Form
{
    public MainForm()
    {
        Text = "MundialFutbol";
        Width = 1120;
        Height = 720;
        MinimumSize = new Size(1060, 620);
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = Theme.Fondo;

        var header = new Panel { Dock = DockStyle.Top, Height = 64, BackColor = Theme.Primario };
        header.Controls.Add(new Label
        {
            Text = "MundialFutbol",
            ForeColor = Color.White,
            Font = new Font("Segoe UI", 16F, FontStyle.Bold),
            AutoSize = true,
            Location = new Point(18, 7)
        });
        header.Controls.Add(new Label
        {
            Text = "ABM de designaciones arbitrales · Importación CSV · Reportes XML",
            ForeColor = Color.FromArgb(200, 226, 218),
            Font = new Font("Segoe UI", 9F),
            AutoSize = true,
            Location = new Point(21, 38)
        });

        var tabs = new TabControl
        {
            Dock = DockStyle.Fill,
            Font = new Font("Segoe UI", 10F),
            ItemSize = new Size(150, 32),
            SizeMode = TabSizeMode.Fixed,
            Padding = new Point(12, 6)
        };

        var tabDesignaciones = new TabPage("Designaciones") { BackColor = Theme.Fondo, Padding = new Padding(12) };
        tabDesignaciones.Controls.Add(new DesignacionesForm { Dock = DockStyle.Fill });

        var tabImportacion = new TabPage("Importación CSV") { BackColor = Theme.Fondo, Padding = new Padding(12) };
        tabImportacion.Controls.Add(new ImportacionForm { Dock = DockStyle.Fill });

        var tabReportes = new TabPage("Reportes") { BackColor = Theme.Fondo, Padding = new Padding(12) };
        tabReportes.Controls.Add(new ReportesForm { Dock = DockStyle.Fill });

        tabs.TabPages.Add(tabDesignaciones);
        tabs.TabPages.Add(tabImportacion);
        tabs.TabPages.Add(tabReportes);

        Controls.Add(tabs);
        Controls.Add(header);
    }
}
