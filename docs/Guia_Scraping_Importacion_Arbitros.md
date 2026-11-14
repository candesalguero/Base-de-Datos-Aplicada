# Scraping e importación de árbitros

Esta guía describe el flujo completo para generar el XML de árbitros y
ejecutar su importación en SQL Server. Las rutas de ejemplo corresponden a
Windows y deben adaptarse al checkout local y al servidor que ejecuta SQL
Server.

El scraper usa `requests` si está instalado y, si no, utiliza `urllib` de la
biblioteca estándar. No es obligatorio instalar dependencias adicionales.

## Generar el XML

Desde la raíz del repositorio:

```powershell
python Import\scrape_arbitros.py
```

El resultado se escribe en:

```text
Import\arbitros.xml
```

Wikipedia proporciona códigos FIFA/ISO3 dentro del nombre del árbitro, por
ejemplo `ITA`, `BRA` o `ENG`. El scraper descarga una sola vez por ejecución el
catálogo público
[`all.csv`](https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.csv),
que contiene `alpha-3` y `alpha-2`, carga un diccionario en memoria y genera
`<pais_iso2>` con dos letras mayúsculas. Las equivalencias FIFA indispensables
que no son alpha-3 oficiales de ISO-3166 son `ENG` → `GB`, `GDR` → `DE`,
`SUI` → `CH` y `URS` → `RU`. 

El importador SQL trabaja directamente con ese `<pais_iso2>` y resuelve el
país mediante `general.Pais.ISO2`.

### Modo offline opcional

Para evitar la consulta a Wikipedia, pasar un XML o HTML local con
`--entrada`:

```powershell
python Import\scrape_arbitros.py --entrada Import\arbitros_test.xml --salida Import\arbitros_offline.xml
```

Un código ISO2 de dos letras recibido en modo offline se acepta directamente.
Los códigos ISO3 necesitan estar en el catálogo o ser una de las equivalencias
FIFA documentadas arriba.

## Ejecutar los scripts SQL

Ejecutar los scripts en este orden, dentro de la base `MundialFutbol`:

1. **`sql\MundialFutbol\66_Tablas_Staging_Arbitros_XML.sql`**  
   Crea, si todavía no existe, `integracion.StagingArbitroXML`, la tabla
   temporal de staging que recibe las filas leídas del XML.
2. **`sql\MundialFutbol\67_SP_Importar_Arbitros_XML.sql`**  
   Crea o actualiza `integracion.usp_ImportarArbitrosXML`. El procedimiento
   lee el archivo con `OPENROWSET`, valida el XML y los campos, registra
   errores, y realiza la importación acumulativa/upsert usando país, nombre y
   apellido.
3. **`sql\MundialFutbol\68_Test_Importar_Arbitros_XML.sql`**  
   Ejecuta la prueba de integración con los XML de prueba, verificando
   importación parcial, error por país inexistente, actualización sin
   duplicados y registros de log. Sus rutas son ejemplos y deben adaptarse.

## Permisos para `OPENROWSET`

El procedimiento 67 usa `OPENROWSET(BULK ..., SINGLE_BLOB)`. Por eso:

- La cuenta del servicio de SQL Server debe tener permiso de lectura sobre la
  carpeta y el archivo XML.
- La ruta debe existir y ser accesible desde el servidor SQL.
- La instancia puede requerir que se habilite `Ad Hoc Distributed Queries`
  para permitir `OPENROWSET`. Esa configuración debe realizarla un
  administrador de SQL Server según las políticas del entorno.
- El usuario que ejecuta el procedimiento necesita permisos para ejecutar el
  procedimiento y acceder a las tablas involucradas.

Si SQL Server no puede abrir el archivo, corregir permisos o ruta antes de
reintentar. No copiar una ruta de `Downloads` del cliente si el servidor SQL
está en otra máquina.

## Ejecutar la importación

El procedimiento requiere un `@id_log` nuevo, un `@id_fuente` existente en
`integracion.FuenteDatos`, la ruta absoluta visible para SQL Server y el nombre
del archivo. Ejemplo:

```sql
USE MundialFutbol;
GO

DECLARE @id_log int = 1001; -- usar un id nuevo
DECLARE @id_fuente int = 1; -- usar una fuente existente

EXEC integracion.usp_ImportarArbitrosXML
    @id_log = @id_log,
    @id_fuente = @id_fuente,
    @ruta_archivo = N'C:\ruta\del\repositorio\Import\arbitros.xml',
    @nombre_archivo = 'arbitros.xml';
GO
```

Adaptar `@id_log`, `@id_fuente` y `@ruta_archivo` al entorno real. El
procedimiento valida que el log no exista, que la fuente exista y que el XML
sea válido; los errores por fila quedan registrados en las tablas de
integración.
