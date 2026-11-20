using System;
using Microsoft.Data.SqlClient;

namespace MundialFutbolApp.Db;

public static class Conexion
{
    // Ajustar si el servidor/instancia cambia
    public static string ConnectionString { get; set; } =
        "Server=localhost;Database=MundialFutbol;Trusted_Connection=True;TrustServerCertificate=True;";

    public static SqlConnection Abrir()
    {
        var cn = new SqlConnection(ConnectionString);
        cn.Open();
        return cn;
    }
}
