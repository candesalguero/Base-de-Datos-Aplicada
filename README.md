# MundialFutbol — Base de Datos Aplicada

Proyecto desarrollado para la materia **Bases de Datos Aplicada** de la Universidad Nacional de La Matanza.

## Integrantes

- Salguero, Candela
- Ocaranza, Lucila
- Dimattia Damm, Malena
- Fuentes, Martina Alejandra

## Objetivo

Desarrollar una base de datos para la gestión integral de un Mundial de Fútbol, centralizando información relacionada con:

- selecciones y jugadores;
- convocatorias y cuerpos técnicos;
- partidos y sedes;
- formaciones y sustituciones;
- goles, tarjetas y sanciones;
- árbitros y designaciones;
- publicidad;
- fuentes externas e importaciones;
- indicadores económicos y tipos de cambio;
- reportes estadísticos.

El proyecto fue desarrollado utilizando **Microsoft SQL Server** y **SQL Server Management Studio (SSMS)**.

## Estructura principal

La base de datos `MundialFutbol` se divide en los siguientes esquemas:

### `general`

Contiene información general utilizada por los distintos módulos:

- países;
- confederaciones;
- idiomas;
- monedas;
- tipos de cambio;
- indicadores económicos;
- fases;
- sedes.

### `deportivo`

Contiene la información relacionada con el desarrollo deportivo del torneo:

- selecciones;
- jugadores;
- convocatorias;
- cuerpo técnico;
- partidos;
- alineaciones;
- sustituciones;
- goles;
- tarjetas;
- sanciones.

### `arbitraje`

Gestiona:

- árbitros;
- idiomas;
- roles arbitrales;
- designaciones;
- informes posteriores a los partidos.

### `publicidad`

Gestiona:

- anunciantes;
- campañas;
- tarifas;
- piezas de contenido;
- espacios publicitarios;
- mercados de interés;
- exhibiciones publicitarias.

### `integracion`

Se utiliza para los procesos de importación:

- fuentes de datos;
- logs de importación;
- detalle de errores;
- tablas de staging.

## Stored Procedures

Se implementaron procedimientos almacenados para:

- ABM de las entidades principales;
- reglas de negocio;
- registro de goles;
- formaciones;
- sustituciones;
- tarjetas y sanciones;
- validación de plantillas;
- importación de datos externos;
- carga mediante APIs;
- generación de reportes.

Los procedimientos realizan validaciones y utilizan `THROW` para informar errores.

En los procesos que requieren iteración se prioriza la lógica de conjuntos y, cuando es necesario, se utilizan bucles `WHILE`. No se utilizan cursores.

## Importaciones

El sistema permite importar información externa y registrar el resultado de cada proceso.

### Partidos mediante CSV

Se utiliza un archivo `matches.csv`.

Flujo:

```text
CSV
→ tabla staging
→ validaciones y transformaciones
→ INSERT / UPDATE
→ LogImportacion
→ DetalleErrorImportacion
```

La importación soporta procesamiento parcial: los registros válidos se procesan aunque otros registros presenten errores.

También implementa **upsert**, evitando generar duplicados al importar nuevamente el mismo dataset.

### Árbitros mediante XML

Se implementó una importación desde XML para incorporar información arbitral.

### World Bank API

Se utiliza la API del Banco Mundial para obtener información de **PBI per cápita**.

El proceso:

```text
World Bank API
→ Python
→ JSON
→ Stored Procedure
→ general.IndicadorEconomico
```

### Frankfurter API

Se utiliza Frankfurter para obtener tipos de cambio entre las monedas registradas.

El proceso:

```text
general.Moneda
→ Frankfurter API
→ Python
→ JSON
→ Stored Procedure
→ general.TipoCambio
```

Las importaciones mediante API también implementan lógica de actualización para evitar registros duplicados.

## Testing

Los Stored Procedures cuentan con scripts de testing separados.

Las pruebas incluyen:

- casos exitosos;
- validaciones esperadas;
- manejo de errores;
- rollback de datos temporales;
- savepoints;
- pruebas de importación parcial;
- pruebas de upsert.

Cuando una prueba debe fallar de manera intencional, se utilizan transacciones y savepoints para evitar perder los datos auxiliares necesarios para continuar con el resto de los tests.

## Carga de datos

Se incluye un script de carga masiva con información representativa para permitir la ejecución de los reportes.

La carga contempla, entre otros:

- países;
- selecciones;
- jugadores;
- convocatorias;
- partidos;
- goles;
- tarjetas;
- sanciones;
- árbitros;
- campañas publicitarias;
- exhibiciones.

Los scripts evitan depender de IDs fijos cuando los datos pueden existir previamente.

## Reportes

Se implementan Stored Procedures para los reportes solicitados por la materia.

Entre ellos:

### Goleadores por selección, fase y torneo

El procedimiento devuelve:

1. ranking de goleadores por selección;
2. ranking de goleadores por fase;
3. ranking general del torneo.

Se utilizan:

- `GROUP BY`;
- `COUNT`;
- `DENSE_RANK`;
- funciones de ventana.

Los goles en contra no son contabilizados como goles personales del jugador.

### Validación final

Se incluye un script de validación de carga que permite comprobar:

- cantidad de registros de las tablas principales;
- posibles duplicados;
- relaciones entre entidades;
- indicadores económicos;
- tipos de cambio;
- fuentes externas;
- logs de importación;
- errores registrados.

Este script no modifica la información de la base.

## Aplicación de escritorio

Se incluye una aplicación WinForms (.NET 10) en `app/MundialFutbolApp/` con tres pantallas:

- **Designaciones**: ABM completo de `arbitraje.DesignacionArbitral` 
- **Importación CSV**: carga de partidos desde `matches.csv` usando `integracion.usp_ImportarPartidosCSV`, con resumen (insertados/actualizados/errores) y grilla de filas rechazadas.
- **Reportes**: ejecución de los 4 reportes XML (resultados, tarjetas, designaciones, publicidad) con formateo, metadatos y guardado en disco.

Guía de uso detallada: [`app/MundialFutbolApp/GUIA_USO.md`](app/MundialFutbolApp/GUIA_USO.md).

Compilación:

```powershell
cd app\MundialFutbolApp
dotnet restore
dotnet build
dotnet run
```

Requisitos: .NET SDK 10, SQL Server con la base `MundialFutbol` creada y los scripts ejecutados, y usuario de Windows con permisos de conexión (y `bulkadmin` para importar CSV).

## Ejecución

Los archivos SQL están numerados para indicar su orden de ejecución.

Para reconstruir el proyecto desde cero:

1. Ejecutar el script de eliminación de la base, si corresponde.
2. Crear `MundialFutbol`.
3. Crear los esquemas.
4. Crear las tablas.
5. Crear funciones y Stored Procedures.
6. Ejecutar los scripts de importación.
7. Ejecutar la carga de datos.
8. Ejecutar los tests.
9. Ejecutar los reportes y validaciones finales.

## Requisitos

- Microsoft SQL Server
- SQL Server Management Studio
- Python 3.13 o superior para los procesos que consumen APIs
- Librerías Python:
  - `requests`
  - `pyodbc`
- ODBC Driver 18 for SQL Server

## Consideraciones

Los scripts fueron diseñados para poder recrear la base de datos desde cero y demostrar durante la defensa:

- creación completa de la base;
- carga de datos;
- importaciones;
- procesamiento parcial de errores;
- upsert;
- reglas de negocio;
- ejecución de reportes.