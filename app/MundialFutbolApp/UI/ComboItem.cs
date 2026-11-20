namespace MundialFutbolApp.UI;

public class ComboItem
{
    public int Id { get; }
    public string Nombre { get; }

    public ComboItem(int id, string nombre)
    {
        Id = id;
        Nombre = nombre;
    }

    public override string ToString() => $"{Id} - {Nombre}";
}
