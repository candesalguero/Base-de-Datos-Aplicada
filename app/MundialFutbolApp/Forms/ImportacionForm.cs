using System;
using System.Collections.Generic;
using System.Data;
using System.Drawing;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Data.SqlClient;
using MundialFutbolApp.Db;
using MundialFutbolApp.UI;

namespace MundialFutbolApp.Forms;

public class ImportacionForm : UserControl
{
    private readonly ComboBox cbFuente = new()
    {
        Location = new Point(80, 13),
        Width = 340,
        BackColor = Theme.Superficie,
        DropDownStyle = ComboBoxStyle.DropDownList,
        TabIndex = 0
    };
    private readonly TextBox txtArchivo = new()
    {
        Location = new Point(510, 13),
        Width = 380,
        BorderStyle = BorderStyle.FixedSingle,
        TabIndex = 1
    };
    private readonly Button btnExaminar = Theme.Boton("Elegir archivo");
    private readonly Button btnImportar = Theme.Boton("Importar", primario: true);
    private readonly DataGridView grid = new() { Dock = DockStyle.Fill, TabIndex = 10, TabStop = false };
    private readonly Label lblResumen = new()
    {
        Location = new Point(14, 58),
        Width = 900,
        Height = 24,
        AutoSize = false,
        ForeColor = Theme.TextoSuave,
        Font = new Font("Segoe UI Semibold", 10F)
    };
    private readonly Label lblEstado = Theme.Estado();

    public ImportacionForm()
    {
        BackColor = Theme.Fondo;
        Font = new Font("Segoe UI", 9.75F);
        Theme.Grid(grid);
        grid.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;

        var barra = Theme.Barra();
        barra.Height = 96;
        barra.Controls.Add(Theme.Etiqueta("Fuente:", 14, 17));
        barra.Controls.Add(cbFuente);
        barra.Controls.Add(Theme.Etiqueta("Archivo:", 450, 17));
        barra.Controls.Add(txtArchivo);
        barra.Controls.Add(btnExaminar);
        barra.Controls.Add(lblResumen);
        barra.Controls.Add(btnImportar);

        btnExaminar.SetBounds(900, 12, 110, 30);
        btnExaminar.TabIndex = 2;
        btnImportar.SetBounds(960, 52, 120, 30);
        btnImportar.TabIndex = 3;

        Controls.Add(grid);
        Controls.Add(lblEstado);
        Controls.Add(barra);

        btnExaminar.Click += (_, _) => ElegirArchivo();
        btnImportar.Click += BtnImportar_Click;
        Load += (_, _) => { CargarFuentes(); lblEstado.Text = "Seleccione el CSV de partidos y presione Importar."; };
    }

    private void CargarFuentes()
    {
        cbFuente.Items.Clear();
        try
        {
            using var cn = Conexion.Abrir();
            using var cmd = new SqlCommand(
                "SELECT id, nombre FROM integracion.FuenteDatos WHERE tipo = 'CSV' ORDER BY id", cn);
            using var r = cmd.ExecuteReader();
            while (r.Read()) cbFuente.Items.Add(new ComboItem(r.GetInt32(0), r.GetString(1)));
            if (cbFuente.Items.Count > 0) cbFuente.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error cargando fuentes: " + ex.Message);
        }
    }

    private void ElegirArchivo()
    {
        using var dialogo = new OpenFileDialog
        {
            Title = "Seleccionar archivo CSV",
            Filter = "Archivos CSV (*.csv)|*.csv|Todos los archivos (*.*)|*.*"
        };
        if (dialogo.ShowDialog() == DialogResult.OK)
        {
            txtArchivo.Text = dialogo.FileName;
            lblEstado.Text = Path.GetFileName(dialogo.FileName);
        }
    }

    private async void BtnImportar_Click(object? sender, EventArgs e)
    {
        if (cbFuente.SelectedItem is not ComboItem fuente)
        {
            MessageBox.Show("Seleccione una fuente de datos.");
            return;
        }

        var ruta = txtArchivo.Text.Trim();
        if (ruta == "" || !File.Exists(ruta))
        {
            MessageBox.Show("Elija un archivo CSV existente. La ruta debe ser legible por SQL Server.");
            return;
        }

        Bloquear(true);
        lblEstado.Text = "Importando…";

        try
        {
            var nombre = Path.GetFileName(ruta);
            var resultado = await Task.Run(() => Ejecutar(fuente.Id, ruta, nombre));
            Mostrar(resultado);
            lblEstado.Text = resultado.Errores == 0
                ? "Importación finalizada sin errores."
                : $"Importación finalizada con {resultado.Errores} filas rechazadas.";
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error al importar: " + ex.Message);
            lblEstado.Text = "La importación falló.";
        }
        finally
        {
            Bloquear(false);
        }
    }

    private static ResultadoImportacion Ejecutar(int idFuente, string ruta, string nombre)
    {
        using var cn = Conexion.Abrir();

        using var idCmd = new SqlCommand(
            "SELECT ISNULL(MAX(id), 0) + 1 FROM integracion.LogImportacion", cn);
        var idLog = Convert.ToInt32(idCmd.ExecuteScalar());

        var resultado = "";
        var insertados = 0;
        var actualizados = 0;
        var errores = 0;

        using (var cmd = new SqlCommand("integracion.usp_ImportarPartidosCSV", cn)
               {
                   CommandType = CommandType.StoredProcedure,
                   CommandTimeout = 300
               })
        {
            cmd.Parameters.AddWithValue("@id_log", idLog);
            cmd.Parameters.AddWithValue("@id_fuente", idFuente);
            cmd.Parameters.AddWithValue("@ruta_archivo", ruta);
            cmd.Parameters.AddWithValue("@nombre_archivo", nombre);

            using var r = cmd.ExecuteReader();
            do
            {
                if (r.FieldCount == 0) continue;

                var columnas = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
                for (var i = 0; i < r.FieldCount; i++) columnas.Add(r.GetName(i));

                while (r.Read())
                {
                    if (columnas.Contains("resultado"))
                        resultado = r["resultado"]?.ToString() ?? "";
                    if (columnas.Contains("insertados"))
                        insertados = Convert.ToInt32(r["insertados"]);
                    if (columnas.Contains("actualizados"))
                        actualizados = Convert.ToInt32(r["actualizados"]);
                    if (columnas.Contains("errores"))
                        errores = Convert.ToInt32(r["errores"]);
                }
            } while (r.NextResult());
        }

        var detalle = new DataTable();
        using (var da = new SqlDataAdapter(
                   "SELECT fila, error FROM integracion.DetalleErrorImportacion " +
                   "WHERE id_log_importacion = @id_log ORDER BY fila", cn))
        {
            da.SelectCommand!.Parameters.AddWithValue("@id_log", idLog);
            da.Fill(detalle);
        }

        if (errores == 0) errores = detalle.Rows.Count;

        return new ResultadoImportacion(idLog, resultado, insertados, actualizados, errores, detalle);
    }

    private void Mostrar(ResultadoImportacion resultado)
    {
        grid.DataSource = resultado.Detalle;
        if (grid.Columns["fila"] != null)
        {
            grid.Columns["fila"]!.HeaderText = "Fila";
            grid.Columns["fila"]!.FillWeight = 60;
        }
        if (grid.Columns["error"] != null)
        {
            grid.Columns["error"]!.HeaderText = "Error";
            grid.Columns["error"]!.FillWeight = 600;
        }

        lblResumen.Text =
            $"Log {resultado.Log} · {resultado.Resultado} · " +
            $"{resultado.Insertados} insertados · {resultado.Actualizados} actualizados · " +
            $"{resultado.Errores} errores";

        lblResumen.ForeColor = resultado.Resultado switch
        {
            "EXITO" => Color.FromArgb(21, 128, 61),
            "PARCIAL" => Color.FromArgb(180, 120, 10),
            "ERROR" => Color.FromArgb(185, 28, 28),
            _ => Theme.TextoSuave
        };
    }

    private void Bloquear(bool bloqueado)
    {
        cbFuente.Enabled = !bloqueado;
        txtArchivo.Enabled = !bloqueado;
        btnExaminar.Enabled = !bloqueado;
        btnImportar.Enabled = !bloqueado;
        UseWaitCursor = bloqueado;
    }

    private sealed record ResultadoImportacion(
        int Log,
        string Resultado,
        int Insertados,
        int Actualizados,
        int Errores,
        DataTable Detalle);
}
