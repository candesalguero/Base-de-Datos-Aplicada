using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Data.SqlClient;
using MundialFutbolApp.Db;
using MundialFutbolApp.UI;

namespace MundialFutbolApp.Forms;

public class DesignacionesForm : UserControl
{
    private readonly DataGridView grid = new() { Dock = DockStyle.Fill, TabIndex = 20, TabStop = false };
    private readonly ComboBox cbPartido = Combo(80, 13, 360, 0);
    private readonly ComboBox cbArbitro = Combo(525, 13, 250, 1);
    private readonly ComboBox cbRol = Combo(55, 53, 160, 2);
    private readonly ComboBox cbEstado = Combo(300, 53, 140, 3);
    private readonly TextBox txtMotivo = new()
    {
        Location = new Point(600, 55),
        Width = 310,
        BorderStyle = BorderStyle.FixedSingle,
        TabIndex = 4,
        Enabled = false
    };
    private readonly Button btnAgregar = Theme.Boton("Agregar", primario: true);
    private readonly Button btnModificar = Theme.Boton("Modificar");
    private readonly Button btnEliminar = Theme.Boton("Eliminar");
    private readonly Button btnRefrescar = Theme.Boton("Refrescar");
    private readonly Label lblEstado = Theme.Estado();

    private bool _cargando;

    public DesignacionesForm()
    {
        BackColor = Theme.Fondo;
        Font = new Font("Segoe UI", 9.75F);
        Theme.Grid(grid);

        var barra = Theme.Barra();
        barra.Height = 136;

        barra.Controls.Add(Theme.Etiqueta("Partido:", 14, 17));
        barra.Controls.Add(cbPartido);
        barra.Controls.Add(Theme.Etiqueta("Árbitro:", 460, 17));
        barra.Controls.Add(cbArbitro);
        barra.Controls.Add(Theme.Etiqueta("Rol:", 14, 57));
        barra.Controls.Add(cbRol);
        barra.Controls.Add(Theme.Etiqueta("Estado:", 235, 57));
        barra.Controls.Add(cbEstado);
        barra.Controls.Add(Theme.Etiqueta("Motivo de descarte:", 460, 57));
        barra.Controls.Add(txtMotivo);

        btnAgregar.SetBounds(648, 92, 96, 30);
        btnModificar.SetBounds(752, 92, 96, 30);
        btnEliminar.SetBounds(856, 92, 96, 30);
        btnRefrescar.SetBounds(960, 92, 100, 30);
        btnAgregar.TabIndex = 5;
        btnModificar.TabIndex = 6;
        btnEliminar.TabIndex = 7;
        btnRefrescar.TabIndex = 8;

        barra.Controls.Add(btnAgregar);
        barra.Controls.Add(btnModificar);
        barra.Controls.Add(btnEliminar);
        barra.Controls.Add(btnRefrescar);

        Controls.Add(grid);
        Controls.Add(lblEstado);
        Controls.Add(barra);

        btnAgregar.Click += (_, _) => Agregar();
        btnModificar.Click += (_, _) => Modificar();
        btnEliminar.Click += (_, _) => Eliminar();
        btnRefrescar.Click += (_, _) => Cargar();
        cbEstado.SelectedIndexChanged += (_, _) => AjustarMotivo();
        grid.SelectionChanged += (_, _) => { if (!_cargando) MostrarSeleccionada(); };
        Load += (_, _) => { CargarCombos(); Cargar(); ActiveControl = cbPartido; };
    }

    private static ComboBox Combo(int x, int y, int width, int tab)
        => new()
        {
            Location = new Point(x, y),
            Width = width,
            BackColor = Theme.Superficie,
            DropDownStyle = ComboBoxStyle.DropDownList,
            TabIndex = tab
        };

    private static void AbrirClave(SqlConnection cn)
    {
        using var cmd = new SqlCommand("dbo.usp_AbrirClaveCifrado", cn) { CommandType = CommandType.StoredProcedure };
        cmd.ExecuteNonQuery();
    }

    private static void CerrarClave(SqlConnection cn)
    {
        using var cmd = new SqlCommand("dbo.usp_CerrarClaveCifrado", cn) { CommandType = CommandType.StoredProcedure };
        cmd.ExecuteNonQuery();
    }

    private void CargarCombos()
    {
        CargarPartidos();
        CargarArbitros();
        CargarRoles();

        cbEstado.Items.Clear();
        cbEstado.Items.AddRange(new object[] { "PENDIENTE", "CONFIRMADA", "DESCARTADA" });
        cbEstado.SelectedIndex = 0;
    }

    private void CargarPartidos()
    {
        cbPartido.Items.Clear();
        try
        {
            using var cn = Conexion.Abrir();
            using var cmd = new SqlCommand(
                """
                SELECT p.id,
                       sl.nombre + ' vs ' + sv.nombre + ' · ' +
                       CONVERT(varchar(10), p.fecha_hora_local, 103) AS nombre
                FROM deportivo.Partido AS p
                INNER JOIN deportivo.Seleccion AS sl ON sl.id = p.id_seleccion_local
                INNER JOIN deportivo.Seleccion AS sv ON sv.id = p.id_seleccion_visitante
                ORDER BY p.fecha_hora_local, p.id;
                """, cn);
            using var r = cmd.ExecuteReader();
            while (r.Read()) cbPartido.Items.Add(new ComboItem(r.GetInt32(0), r.GetString(1)));
            if (cbPartido.Items.Count > 0) cbPartido.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error cargando partidos: " + ex.Message);
        }
    }

    private void CargarArbitros()
    {
        cbArbitro.Items.Clear();
        try
        {
            using var cn = Conexion.Abrir();
            AbrirClave(cn);
            try
            {
                using var cmd = new SqlCommand(
                    "SELECT id, nombre + ' ' + apellido FROM arbitraje.vw_ArbitroDescifrado ORDER BY apellido, nombre", cn);
                using var r = cmd.ExecuteReader();
                while (r.Read()) cbArbitro.Items.Add(new ComboItem(r.GetInt32(0), r.GetString(1)));
            }
            finally
            {
                CerrarClave(cn);
            }
            if (cbArbitro.Items.Count > 0) cbArbitro.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error cargando árbitros: " + ex.Message);
        }
    }

    private void CargarRoles()
    {
        cbRol.Items.Clear();
        try
        {
            using var cn = Conexion.Abrir();
            using var cmd = new SqlCommand("SELECT id, nombre FROM arbitraje.RolArbitral ORDER BY id", cn);
            using var r = cmd.ExecuteReader();
            while (r.Read()) cbRol.Items.Add(new ComboItem(r.GetInt32(0), r.GetString(1)));
            if (cbRol.Items.Count > 0) cbRol.SelectedIndex = 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error cargando roles: " + ex.Message);
        }
    }

    private void Cargar()
    {
        try
        {
            _cargando = true;
            using var cn = Conexion.Abrir();
            AbrirClave(cn);
            try
            {
                using var da = new SqlDataAdapter(
                    """
                    SELECT d.id,
                           d.id_partido,
                           d.id_arbitro,
                           d.id_rol_arbitral,
                           CONVERT(varchar(10), p.fecha_hora_local, 103) AS fecha,
                           sl.nombre + ' vs ' + sv.nombre AS encuentro,
                           ISNULL(NULLIF(LTRIM(RTRIM(a.nombre + ' ' + a.apellido)), ''),
                                  'Árbitro #' + CAST(d.id_arbitro AS varchar(10))) AS arbitro,
                           ro.nombre AS rol,
                           d.estado,
                           d.motivo_descarte
                    FROM arbitraje.DesignacionArbitral AS d
                    INNER JOIN deportivo.Partido AS p ON p.id = d.id_partido
                    INNER JOIN deportivo.Seleccion AS sl ON sl.id = p.id_seleccion_local
                    INNER JOIN deportivo.Seleccion AS sv ON sv.id = p.id_seleccion_visitante
                    INNER JOIN arbitraje.RolArbitral AS ro ON ro.id = d.id_rol_arbitral
                    LEFT JOIN arbitraje.vw_ArbitroDescifrado AS a ON a.id = d.id_arbitro
                    ORDER BY p.fecha_hora_local, d.id;
                    """, cn);
                var dt = new DataTable();
                da.Fill(dt);
                grid.DataSource = dt;
                ConfigurarColumnas();
                lblEstado.Text = dt.Rows.Count == 1 ? "1 designación" : $"{dt.Rows.Count} designaciones";
            }
            finally
            {
                CerrarClave(cn);
            }
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error al listar designaciones: " + ex.Message);
        }
        finally
        {
            _cargando = false;
        }
    }

    private void ConfigurarColumnas()
    {
        grid.Columns["id_partido"]!.Visible = false;
        grid.Columns["id_arbitro"]!.Visible = false;
        grid.Columns["id_rol_arbitral"]!.Visible = false;

        grid.Columns["id"]!.HeaderText = "Id";
        grid.Columns["id"]!.FillWeight = 35;
        grid.Columns["fecha"]!.HeaderText = "Fecha";
        grid.Columns["fecha"]!.FillWeight = 65;
        grid.Columns["encuentro"]!.HeaderText = "Partido";
        grid.Columns["encuentro"]!.FillWeight = 230;
        grid.Columns["arbitro"]!.HeaderText = "Árbitro";
        grid.Columns["arbitro"]!.FillWeight = 150;
        grid.Columns["rol"]!.HeaderText = "Rol";
        grid.Columns["rol"]!.FillWeight = 130;
        grid.Columns["estado"]!.HeaderText = "Estado";
        grid.Columns["estado"]!.FillWeight = 90;
        grid.Columns["motivo_descarte"]!.HeaderText = "Motivo de descarte";
        grid.Columns["motivo_descarte"]!.FillWeight = 200;
    }

    private void MostrarSeleccionada()
    {
        if (grid.CurrentRow == null) return;

        var id = Convert.ToInt32(grid.CurrentRow.Cells["id"].Value);
        Seleccionar(cbPartido, Convert.ToInt32(grid.CurrentRow.Cells["id_partido"].Value));
        Seleccionar(cbArbitro, Convert.ToInt32(grid.CurrentRow.Cells["id_arbitro"].Value));
        Seleccionar(cbRol, Convert.ToInt32(grid.CurrentRow.Cells["id_rol_arbitral"].Value));

        var estado = grid.CurrentRow.Cells["estado"].Value?.ToString() ?? "PENDIENTE";
        cbEstado.SelectedItem = estado;
        txtMotivo.Text = grid.CurrentRow.Cells["motivo_descarte"].Value?.ToString() ?? "";
        AjustarMotivo();

        lblEstado.Text = $"Editando designación #{id}";
    }

    private void SeleccionarFila(int id)
    {
        foreach (DataGridViewRow row in grid.Rows)
        {
            if (Convert.ToInt32(row.Cells["id"].Value) == id)
            {
                row.Selected = true;
                grid.CurrentCell = row.Cells["fecha"];
                return;
            }
        }
    }

    private static void Seleccionar(ComboBox combo, int id)
    {
        foreach (var item in combo.Items)
        {
            if (item is ComboItem opcion && opcion.Id == id)
            {
                combo.SelectedItem = item;
                return;
            }
        }
    }

    private void AjustarMotivo()
    {
        var descartada = (cbEstado.SelectedItem as string) == "DESCARTADA";
        txtMotivo.Enabled = descartada;
        if (!descartada) txtMotivo.Clear();
    }

    private bool DatosValidos(out ComboItem? partido, out ComboItem? arbitro, out ComboItem? rol, out string estado)
    {
        partido = cbPartido.SelectedItem as ComboItem;
        arbitro = cbArbitro.SelectedItem as ComboItem;
        rol = cbRol.SelectedItem as ComboItem;
        estado = cbEstado.SelectedItem as string ?? "";

        if (partido == null || arbitro == null || rol == null || estado == "")
        {
            MessageBox.Show("Seleccione partido, árbitro, rol y estado.");
            return false;
        }

        if (estado == "DESCARTADA" && string.IsNullOrWhiteSpace(txtMotivo.Text))
        {
            MessageBox.Show("Una designación descartada debe indicar el motivo.");
            return false;
        }

        return true;
    }

    private void Agregar()
    {
        if (!DatosValidos(out var partido, out var arbitro, out var rol, out var estado)) return;

        try
        {
            using var cn = Conexion.Abrir();
            using var idCmd = new SqlCommand("SELECT ISNULL(MAX(id), 0) + 1 FROM arbitraje.DesignacionArbitral", cn);
            var id = Convert.ToInt32(idCmd.ExecuteScalar());

            using var cmd = new SqlCommand("arbitraje.usp_DesignacionArbitral_Insertar", cn) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@id_partido", partido!.Id);
            cmd.Parameters.AddWithValue("@id_arbitro", arbitro!.Id);
            cmd.Parameters.AddWithValue("@id_rol_arbitral", rol!.Id);
            cmd.Parameters.AddWithValue("@estado", estado);
            cmd.Parameters.AddWithValue("@motivo_descarte", Motivo());
            cmd.ExecuteNonQuery();

            Cargar();
            SeleccionarFila(id);
            lblEstado.Text = $"Designación #{id} agregada.";
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error: " + ex.Message);
        }
    }

    private void Modificar()
    {
        if (grid.CurrentRow == null) { MessageBox.Show("Seleccione una fila del listado."); return; }
        if (!DatosValidos(out var partido, out var arbitro, out var rol, out var estado)) return;

        var id = Convert.ToInt32(grid.CurrentRow.Cells["id"].Value);

        try
        {
            using var cn = Conexion.Abrir();
            using var cmd = new SqlCommand("arbitraje.usp_DesignacionArbitral_Actualizar", cn) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@id_partido", partido!.Id);
            cmd.Parameters.AddWithValue("@id_arbitro", arbitro!.Id);
            cmd.Parameters.AddWithValue("@id_rol_arbitral", rol!.Id);
            cmd.Parameters.AddWithValue("@estado", estado);
            cmd.Parameters.AddWithValue("@motivo_descarte", Motivo());
            cmd.ExecuteNonQuery();

            Cargar();
            SeleccionarFila(id);
            lblEstado.Text = $"Designación #{id} actualizada.";
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error: " + ex.Message);
        }
    }

    private void Eliminar()
    {
        if (grid.CurrentRow == null) { MessageBox.Show("Seleccione una fila del listado."); return; }

        var id = Convert.ToInt32(grid.CurrentRow.Cells["id"].Value);
        var partido = grid.CurrentRow.Cells["encuentro"].Value?.ToString() ?? "";

        if (MessageBox.Show($"¿Eliminar la designación #{id} de {partido}?", "Confirmar",
                MessageBoxButtons.YesNo) != DialogResult.Yes) return;

        try
        {
            using var cn = Conexion.Abrir();
            using var cmd = new SqlCommand("arbitraje.usp_DesignacionArbitral_Eliminar", cn) { CommandType = CommandType.StoredProcedure };
            cmd.Parameters.AddWithValue("@id", id);
            cmd.ExecuteNonQuery();

            Cargar();
            if (grid.Rows.Count > 0) SeleccionarFila(Convert.ToInt32(grid.Rows[0].Cells["id"].Value));
            else Limpiar();
            lblEstado.Text = $"Designación #{id} eliminada.";
        }
        catch (Exception ex)
        {
            MessageBox.Show("Error: " + ex.Message);
        }
    }

    private object Motivo()
        => string.IsNullOrWhiteSpace(txtMotivo.Text) ? DBNull.Value : txtMotivo.Text.Trim();

    private void Limpiar()
    {
        if (cbPartido.Items.Count > 0) cbPartido.SelectedIndex = 0;
        if (cbArbitro.Items.Count > 0) cbArbitro.SelectedIndex = 0;
        if (cbRol.Items.Count > 0) cbRol.SelectedIndex = 0;
        if (cbEstado.Items.Count > 0) cbEstado.SelectedIndex = 0;
        txtMotivo.Clear();
        cbPartido.Focus();
    }
}
