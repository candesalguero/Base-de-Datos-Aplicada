# MundialFutbolApp

Aplicación de escritorio hecha con WinForms, .NET 10 para operar sobre la base **MundialFutbol**.
Tiene tres pantallas:

1. **Designaciones**: ABM completo de `arbitraje.DesignacionArbitral`.
2. **Importación CSV**: carga de partidos desde `matches.csv` con la lógica de la Entrega 6.
3. **Reportes**: ejecución de los reportes XML de la Entrega 7 y guardado en disco.

Las tres secciones comparten el encabezado verde, la tipografía Segoe UI, las grillas claras y una barra de estado inferior que informa el resultado de cada operación.

---

## 1. Requisitos

| Requisito | Detalle |
|---|---|
| Sistema operativo | Windows 10 u 11 |
| SDK | .NET SDK 10 (el proyecto apunta a `net10.0-windows`) |
| Base de datos | SQL Server 2017 o superior, instancia local |
| Base creada | `MundialFutbol` con los scripts del repositorio ejecutados |
| Permisos SQL | El usuario de Windows debe poder conectarse; para importar, además, `bulkadmin` o `ADMINISTER BULK OPERATIONS` |
| Acceso a archivos | La ruta del CSV debe ser legible **por el servicio de SQL Server**, no por la app |

### 1.1. Scripts necesarios

Ejecutar los scripts de `sql/MundialFutbol` en orden. Para la app son indispensables:

| Script | Para qué lo usa la app |
|---|---|
| `03` a `07` | Tablas de todos los esquemas |
| `10_SP_ABM_Arbitraje.sql` | SP de alta, modificación y baja de designaciones |
| `32_SP_Negocio_Integracion.sql` | Registro del log y de los errores de importación |
| `60_Tablas_Staging_Partidos.sql` | Tabla staging del CSV |
| `61_SP_Importar_Partidos_CSV.sql` | Importación de partidos |
| `90_SP_Reporte_Publicidad.sql` | Reporte de ocupación publicitaria |
| `91_SP_Reporte_Tarjetas.sql` | Reporte de tarjetas |
| `92_SP_Reporte_Designaciones_Arbitrales.sql` | Vista y reporte de designaciones |
| `93_SP_Reporte_Resultados_Encuentros.sql` | Reporte de resultados |
| `100_SP_Cifrado.sql` | Cifrado y procedimientos `usp_AbrirClaveCifrado` / `usp_CerrarClaveCifrado` |

También debe existir la fuente `6100 - World Cup Historical Matches` en `integracion.FuenteDatos`, que es la que se usa para el CSV de partidos.

> **Importante:** los nombres y apellidos de los árbitros están cifrados.
> La app abre la clave simétrica antes de listar árbitros y designaciones, y la cierra al terminar.
> Si `100_SP_Cifrado.sql` no se ejecutó, la pantalla de designaciones muestra un error al cargar los árbitros.

### 1.2. Cadena de conexión

Está en `app/MundialFutbolApp/Db/Conexion.cs`:

```csharp
public static string ConnectionString { get; set; } =
    "Server=localhost;Database=MundialFutbol;Trusted_Connection=True;TrustServerCertificate=True;";
```

Si la instancia es nombrada (por ejemplo `SQLEXPRESS`) o está en otra máquina, ajustar `Server=`.
La app usa autenticación de Windows (`Trusted_Connection=True`), por lo que toma el usuario que ejecuta el programa.

---

## 2. Compilar y ejecutar

Desde la raíz del repositorio:

```powershell
cd app\MundialFutbolApp
dotnet restore
dotnet build
dotnet run
```

También se puede ejecutar el binario ya compilado:

```powershell
.\bin\Debug\net10.0-windows\MundialFutbolApp.exe
```


---

## 3. Pantalla “Designaciones”

Es un ABM completo de la tabla **`arbitraje.DesignacionArbitral`** (la tabla de designaciones arbitrales del modelo).

### 3.1. Elementos

| Elemento | Función |
|---|---|
| **Partido** | Combo con los partidos cargados: `Local vs Visitante · dd/mm/aaaa` |
| **Árbitro** | Combo con los árbitros; el nombre se lee descifrado |
| **Rol** | Combo con `arbitraje.RolArbitral` (principal, asistentes, cuarto árbitro, VAR) |
| **Estado** | `PENDIENTE`, `CONFIRMADA` o `DESCARTADA` |
| **Motivo de descarte** | Solo se habilita cuando el estado es `DESCARTADA` |
| **Agregar** | Inserta una designación nueva |
| **Modificar** | Actualiza la designación seleccionada en la grilla |
| **Eliminar** | Borra la designación seleccionada (pide confirmación) |
| **Refrescar** | Vuelve a leer la tabla |
| **Grilla** | Muestra `Id`, `Fecha`, `Partido`, `Árbitro`, `Rol`, `Estado` y `Motivo de descarte` |
| **Barra de estado** | Indica la cantidad de registros o la designación que se está editando |

Al hacer clic en una fila, los combos y el motivo se cargan solos con los datos de esa designación.

### 3.2. Alta

1. Elegir **Partido**, **Árbitro** y **Rol**.
2. Elegir el **Estado**. Si es `DESCARTADA`, completar el **Motivo de descarte**.
3. Presionar **Agregar**.

La app calcula el id como `MAX(id) + 1` y llama a `arbitraje.usp_DesignacionArbitral_Insertar`.
Si todo sale bien, recarga la grilla, deja seleccionada la fila creada y muestra `Designación #N agregada.`

### 3.3. Modificación

1. Hacer clic en la fila de la grilla.
2. Cambiar partido, árbitro, rol, estado o motivo.
3. Presionar **Modificar** (llama a `arbitraje.usp_DesignacionArbitral_Actualizar`).

### 3.4. Baja

1. Seleccionar la fila.
2. Presionar **Eliminar** y confirmar.

La app llama a `arbitraje.usp_DesignacionArbitral_Eliminar`.

### 3.5. Validaciones

La app valida antes de llamar al SP:

- Partido, árbitro, rol y estado son obligatorios.
- Una designación `DESCARTADA` debe indicar el motivo.

El SP, además, rechaza:

- Un árbitro con dos designaciones para el mismo partido.
- Un estado fuera de `PENDIENTE`, `CONFIRMADA` o `DESCARTADA`.
- Un motivo de descarte en una designación que no está descartada.

Los mensajes del SP se muestran en un cartel.

---

## 4. Pantalla “Importación CSV”

### 4.1. Cómo funciona

La app no lee el CSV: solo indica la ruta. El archivo lo lee SQL Server con `BULK INSERT` dentro de `integracion.usp_ImportarPartidosCSV`. Por eso:

- La ruta debe existir **en la máquina donde corre SQL Server**.
- El servicio de SQL Server debe tener permiso de lectura sobre el archivo y la carpeta.
- El usuario de la app necesita permiso de bulk load (`bulkadmin`).

Pasos:

1. Elegir la **Fuente** (el combo lista solo las fuentes con `tipo = 'CSV'`; hoy, `6100 - World Cup Historical Matches`).
2. Presionar **Elegir archivo** y seleccionar el CSV (por ejemplo `Import/matches.csv`).
3. Presionar **Importar**.

Mientras se procesa, los controles se deshabilitan y el cursor pasa a espera. Al terminar, la app muestra:

| Dato | Significado |
|---|---|
| **Log** | Id del registro creado en `integracion.LogImportacion` |
| **Resultado** | `EXITO` (verde), `PARCIAL` (ámbar) o `ERROR` (rojo) |
| **Insertados** | Partidos nuevos |
| **Actualizados** | Partidos existentes que se actualizaron |
| **Errores** | Cantidad de filas rechazadas |

Debajo, la grilla **Filas rechazadas** muestra `Fila` y `Error`.
El log y los errores quedan en `integracion.LogImportacion` y `integracion.DetalleErrorImportacion` (columna `id_log_importacion`).

### 4.2. Verificar por SQL

```sql
SELECT TOP 10 *
FROM integracion.LogImportacion
ORDER BY id DESC;

SELECT *
FROM integracion.DetalleErrorImportacion
WHERE id_log_importacion = (SELECT MAX(id) FROM integracion.LogImportacion);
```

---

## 5. Pantalla “Reportes”

1. Elegir un reporte en el combo **Reporte**: debajo aparece una descripción.
2. Presionar **Ejecutar reporte**.
3. El XML se muestra formateado (con sangría) en el visor monoespaciado; arriba a la derecha se indica el tamaño y la raíz, por ejemplo `19.085 caracteres · raíz <resultados_encuentros>`.
4. **Guardar XML** abre un diálogo para elegir la ruta y guarda el documento en UTF-8.

Si el reporte no devuelve datos, el visor queda vacío y la barra de estado lo informa.
Si SQL Server devuelve un error, se muestra un cartel con el mensaje.

### 5.1. Reportes disponibles

| Opción | Procedimiento | Contenido | Raíz del XML |
|---|---|---|---|
| Resultados de encuentros | `deportivo.usp_ReporteResultadosEncuentros` | Partidos con fase, sede, equipos, marcador, goles y tarjetas | `<resultados_encuentros>` |
| Tarjetas por selección y jugador | `deportivo.usp_ReporteTarjetasPorSeleccionJugador` | Totales de tarjetas y suspensiones por jugador | `<reporte_tarjetas>` |
| Designaciones arbitrales | `arbitraje.usp_ReporteDesignacionesArbitrales` | Árbitros designados por partido | `<reporte_designaciones_arbitrales>` |
| Ocupación publicitaria | `publicidad.usp_ReporteOcupacionPublicitaria` | Espacios publicitarios e ingresos por partido | `<reporte_publicidad>` |

Notas:

- Los SP se ejecutan **sin filtros** (parámetros en `NULL`), por lo que devuelven el reporte completo.
- El reporte de **tarjetas** devuelve una tabla y además un documento XML; la app toma el documento.
- El reporte de **designaciones** devuelve la tabla analítica y el XML. La app toma el XML.
  Si no hay designaciones cargadas, el reporte no devuelve datos: se pueden agregar desde la pantalla **Designaciones**.
- El reporte de **publicidad** devuelve fragmentos XML por fila. La app arma un documento raíz `<reporte_publicidad>` con un `<partido>` por registro, y dentro los fragmentos `<espacios>` e `<ingresos>`.
- Los reportes de tarjetas, resultados y designaciones abren y cierran la clave de cifrado dentro del SP (`WITH EXECUTE AS OWNER`), por lo que muestran los nombres descifrados.

---

## 6. Estructura del proyecto

```text
app/MundialFutbolApp/
├── MundialFutbolApp.csproj     # net10.0-windows + Microsoft.Data.SqlClient
├── Program.cs                  # arranque de la ventana principal
├── Db/
│   └── Conexion.cs             # cadena de conexión y apertura
├── UI/
│   ├── Theme.cs                # colores, botones, grillas y barra de estado
│   └── ComboItem.cs            # item id + nombre para los combos
├── Forms/
│   ├── MainForm.cs             # encabezado y pestañas
│   ├── DesignacionesForm.cs    # ABM de arbitraje.DesignacionArbitral
│   ├── ImportacionForm.cs      # importación del CSV de partidos
│   └── ReportesForm.cs         # ejecución y guardado de reportes XML
└── GUIA_USO.md                 # este documento
```

El CSV real de ejemplo está en `Import/matches.csv`, en la raíz del repositorio.

### 6.1. Objetos de base usados

| Funcionalidad | Objetos                                                                                                                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| ABM           | `arbitraje.DesignacionArbitral`, `deportivo.Partido`, `arbitraje.vw_ArbitroDescifrado`, `arbitraje.RolArbitral`, `usp_DesignacionArbitral_Insertar/Actualizar/Eliminar`              |
| Importación   | `integracion.FuenteDatos`, `StagingPartidoCSV`, `LogImportacion`, `DetalleErrorImportacion`, `integracion.usp_ImportarPartidosCSV`                                                   |
| Reportes      | `deportivo.usp_ReporteResultadosEncuentros`, `usp_ReporteTarjetasPorSeleccionJugador`, `arbitraje.usp_ReporteDesignacionesArbitrales`, `publicidad.usp_ReporteOcupacionPublicitaria` |
