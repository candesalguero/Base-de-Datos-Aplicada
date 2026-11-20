using System;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;
using System.Xml.Linq;
using Microsoft.Data.SqlClient;
using MundialFutbolApp.Db;
using MundialFutbolApp.UI;

namespace MundialFutbolApp.Forms;

public class ReportesForm : UserControl
{
    private readonly ComboBox cbReporte = new()
    {
        Location = new Point(85, 13),
        Width = 360,
        BackColor = Theme.Superficie,
        DropDownStyle = ComboBoxStyle.DropDownList,
        TabIndex = 0
    };
    private readonly Button btnEjecutar = Theme.Boton("Ejecutar reporte", primario: true);
    private readonly Button btnGuardar = Theme.Boton("Guardar XML");
    private readonly Label lblDescripcion = new()
    {
        Location = new Point(14, 56),
        Width = 900,
        Height = 22,
        AutoSize = false,
        ForeColor = Theme.TextoSuave
    };
    private readonly Label lblMeta = new()
    {
        Location = new Point(650, 18),
        Width = 300,
        Height = 22,
        AutoSize = false,
        TextAlign = ContentAlignment.MiddleRight,
        ForeColor = Theme.TextoSuave
    };
    private readonly TextBox txtXml = new()
    {
        Dock = DockStyle.Fill,
        Multiline = true,
        ReadOnly = true,
        WordWrap = false,
        ScrollBars = ScrollBars.Both,
        BorderStyle = BorderStyle.None,
        BackColor = Theme.Superficie,
        ForeColor = Theme.Texto,
        Font = new Font("Consolas", 9.5F),
        TabIndex = 10
    };
    private readonly Label lblEstado = Theme.Estado();

    private string _xml = "";

    public ReportesForm()
    {
        BackColor = Theme.Fondo;
        Font = new Font("Segoe UI", 9.75F);

        var barra = Theme.Barra();
        barra.Height = 88;
        barra.Controls.Add(Theme.Etiqueta("Reporte:", 14, 17));
        barra.Controls.Add(cbReporte);
        barra.Controls.Add(lblMeta);
        barra.Controls.Add(lblDescripcion);
        barra.Controls.Add(btnEjecutar);
        barra.Controls.Add(btnGuardar);

        btnEjecutar.SetBounds(460, 12, 160, 30);
        btnEjecutar.TabIndex = 1;
        btnGuardar.SetBounds(960, 12, 120, 30);
        btnGuardar.TabIndex = 2;
        btnGuardar.Enabled = false;

        var marco = new Panel
        {
            Dock = DockStyle.Fill,
            BackColor = Theme.Superficie,
            Padding = new Padding(10, 6, 10, 6)
        };
        marco.Controls.Add(txtXml);

        Controls.Add(marco);
        Controls.Add(lblEstado);
        Controls.Add(barra);

        btnEjecutar.Click += (_, _) => Ejecutar();
        btnGuardar.Click += (_, _) => Guardar();
        cbReporte.SelectedIndexChanged += (_, _) => ActualizarDescripcion();
        Load += (_, _) => { CargarReportes(); lblEstado.Text = "Elija un reporte y presione Ejecutar reporte."; };
    }

    private void CargarReportes()
    {
        cbReporte.Items.Clear();
        cbReporte.Items.Add(new Reporte(
            "Resultados de encuentros",
            "deportivo.usp_ReporteResultadosEncuentros",
            "Partidos con fase, sede, equipos, marcador, goles y tarjetas."));
        cbReporte.Items.Add(new Reporte(
            "Tarjetas por selección y jugador",
            "deportivo.usp_ReporteTarjetasPorSeleccionJugador",
            "Totales de tarjetas y suspensiones por jugador."));
        cbReporte.Items.Add(new Reporte(
            "Designaciones arbitrales",
            "arbitraje.usp_ReporteDesignacionesArbitrales",
            "Árbitros designados por partido, con rol y estado."));
        cbReporte.Items.Add(new Reporte(
            "Ocupación publicitaria",
            "publicidad.usp_ReporteOcupacionPublicitaria",
            "Espacios publicitarios e ingresos por partido.",
            EsPublicidad: true));
        cbReporte.SelectedIndex = 0;
    }

    private void ActualizarDescripcion()
    {
        if (cbReporte.SelectedItem is not Reporte reporte) return;
        lblDescripcion.Text = reporte.Descripcion;
        Limpiar();
        lblEstado.Text = "Elija un reporte y presione Ejecutar reporte.";
    }

    private void Ejecutar()
    {
        if (cbReporte.SelectedItem is not Reporte reporte) return;

        btnEjecutar.Enabled = false;
        UseWaitCursor = true;
        lblEstado.Text = "Ejecutando reporte…";

        try
        {
            _xml = ObtenerXml(reporte);

            if (string.IsNullOrWhiteSpace(_xml))
            {
                Limpiar();
                lblMeta.Text = "Sin XML";
                lblEstado.Text = reporte.Nombre + ": el reporte no devolvió datos.";
                return;
            }

            txtXml.Text = Formatear(_xml);
            btnGuardar.Enabled = true;

            var raiz = "documento";
            try
            {
                var doc = XDocument.Parse(_xml);
                if (doc.Root != null) raiz = doc.Root.Name.LocalName;
            }
            catch (Exception)
            {
                raiz = "XML sin formatear";
            }

            lblMeta.Text = $"{txtXml.TextLength:N0} caracteres · raíz <{raiz}>";
            lblEstado.Text = reporte.Nombre + ": reporte generado.";
        }
        catch (Exception ex)
        {
            Limpiar();
            lblMeta.Text = "Error";
            lblEstado.Text = "No se pudo generar el reporte.";
            MessageBox.Show("Error al ejecutar el reporte: " + ex.Message);
        }
        finally
        {
            btnEjecutar.Enabled = true;
            UseWaitCursor = false;
        }
    }

    private static string ObtenerXml(Reporte reporte)
    {
        using var cn = Conexion.Abrir();
        using var cmd = new SqlCommand(reporte.Procedimiento, cn)
        {
            CommandType = System.Data.CommandType.StoredProcedure,
            CommandTimeout = 120
        };
        using var r = cmd.ExecuteReader();

        if (reporte.EsPublicidad) return LeerPublicidad(r);

        var mejor = "";
        do
        {
            if (r.FieldCount == 0) continue;

            var indice = -1;
            for (var i = 0; i < r.FieldCount; i++)
            {
                if (r.GetName(i).Equals("reporte_xml", StringComparison.OrdinalIgnoreCase))
                {
                    indice = i;
                    break;
                }
            }

            while (r.Read())
            {
                if (indice >= 0)
                {
                    var valor = r.GetValue(indice)?.ToString() ?? "";
                    if (valor.Length > mejor.Length) mejor = valor;
                    continue;
                }

                for (var i = 0; i < r.FieldCount; i++)
                {
                    var valor = r.GetValue(i)?.ToString() ?? "";
                    if (valor.TrimStart().StartsWith("<") && valor.Length > mejor.Length) mejor = valor;
                }
            }
        } while (r.NextResult());

        return mejor;
    }

    private static string LeerPublicidad(SqlDataReader r)
    {
        var sb = new StringBuilder();
        sb.AppendLine("<reporte_publicidad>");

        while (r.Read())
        {
            var idPartido = r["id_partido"]?.ToString() ?? "";
            var fecha = r["fecha_hora_local"] == DBNull.Value ? "" : Convert.ToDateTime(r["fecha_hora_local"]).ToString("yyyy-MM-dd HH:mm");
            var local = r["seleccion_local"]?.ToString() ?? "";
            var visitante = r["seleccion_visitante"]?.ToString() ?? "";

            sb.Append("  <partido id_partido=\"").Append(Atributo(idPartido))
              .Append("\" fecha=\"").Append(Atributo(fecha))
              .Append("\" local=\"").Append(Atributo(local))
              .Append("\" visitante=\"").Append(Atributo(visitante))
              .AppendLine("\">");

            AgregarFragmento(sb, r["espacios_xml"]);
            AgregarFragmento(sb, r["ingresos_generados_xml"]);
            sb.AppendLine("  </partido>");
        }

        sb.AppendLine("</reporte_publicidad>");
        return sb.ToString();
    }

    private static void AgregarFragmento(StringBuilder sb, object? valor)
    {
        if (valor == null || valor == DBNull.Value) return;
        var texto = valor.ToString() ?? "";
        if (texto.Length == 0) return;
        sb.Append("    ").AppendLine(texto);
    }

    private static string Atributo(string texto)
        => texto.Replace("&", "&amp;").Replace("<", "&lt;").Replace(">", "&gt;").Replace("\"", "&quot;");

    private static string Formatear(string xml)
    {
        try
        {
            return XDocument.Parse(xml).ToString();
        }
        catch (Exception)
        {
            return xml;
        }
    }

    private void Guardar()
    {
        if (_xml == "") return;

        using var dialogo = new SaveFileDialog
        {
            Title = "Guardar reporte XML",
            Filter = "Archivo XML (*.xml)|*.xml",
            FileName = "reporte.xml"
        };
        if (dialogo.ShowDialog() != DialogResult.OK) return;

        try
        {
            File.WriteAllText(dialogo.FileName, Formatear(_xml), new UTF8Encoding(false));
            lblEstado.Text = "XML guardado en " + dialogo.FileName;
        }
        catch (Exception ex)
        {
            MessageBox.Show("No se pudo guardar el archivo: " + ex.Message);
        }
    }

    private void Limpiar()
    {
        _xml = "";
        txtXml.Clear();
        lblMeta.Text = "";
        btnGuardar.Enabled = false;
    }

    private sealed record Reporte(string Nombre, string Procedimiento, string Descripcion, bool EsPublicidad = false)
    {
        public override string ToString() => Nombre;
    }
}
