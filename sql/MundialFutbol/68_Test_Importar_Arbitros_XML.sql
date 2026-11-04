/*
    Prueba mínima del importador XML de árbitros.
    Las rutas apuntan al checkout local solicitado por el trabajo y deben ser
    ajustadas si SQL Server no puede leer esa ubicación.
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @id_confederacion int = 6800;
DECLARE @id_pais int;
DECLARE @id_fuente int = 6800;
DECLARE @id_log_1 int;
DECLARE @id_log_2 int;

IF NOT EXISTS (SELECT 1 FROM general.Confederacion WHERE id = @id_confederacion)
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (@id_confederacion, 'Confederacion Test Arbitros XML');

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE ISO2 = 'AR')
BEGIN
    SELECT @id_pais = ISNULL(MAX(id), 0) + 1 FROM general.Pais;
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES (@id_pais, 'Argentina', 'AR', 'UTC-3', @id_confederacion);
END;

SELECT @id_pais = id FROM general.Pais WHERE ISO2 = 'AR';

IF NOT EXISTS (SELECT 1 FROM integracion.FuenteDatos WHERE id = @id_fuente)
    INSERT INTO integracion.FuenteDatos (id, nombre, tipo, url)
    VALUES (@id_fuente, 'Wikipedia FIFA referees', 'XML', NULL);

SELECT @id_log_1 = ISNULL(MAX(id), 0) + 1 FROM integracion.LogImportacion;

EXEC integracion.usp_ImportarArbitrosXML
    @id_log = @id_log_1,
    @id_fuente = @id_fuente,
    @ruta_archivo = 'C:\Users\marti\Downloads\Base-de-Datos-Aplicada\Import\arbitros_test.xml',
    @nombre_archivo = 'arbitros_test.xml';

IF (SELECT COUNT(*) FROM arbitraje.Arbitro
    WHERE id_pais = @id_pais AND nombre = 'Carlos' AND apellido = 'Garcia') <> 1
    THROW 50100, 'ERROR: no se insertó el árbitro válido.', 1;

IF NOT EXISTS (
    SELECT 1 FROM integracion.LogImportacion
    WHERE id = @id_log_1 AND resultado = 'PARCIAL'
)
    THROW 50101, 'ERROR: el primer log no quedó PARCIAL.', 1;

IF (SELECT COUNT(*) FROM integracion.DetalleErrorImportacion
    WHERE id_log_importacion = @id_log_1) <> 1
    THROW 50102, 'ERROR: no se registró el país inexistente.', 1;

SELECT @id_log_2 = ISNULL(MAX(id), 0) + 1 FROM integracion.LogImportacion;

EXEC integracion.usp_ImportarArbitrosXML
    @id_log = @id_log_2,
    @id_fuente = @id_fuente,
    @ruta_archivo = 'C:\Users\marti\Downloads\Base-de-Datos-Aplicada\Import\arbitros_test_actualizacion.xml',
    @nombre_archivo = 'arbitros_test_actualizacion.xml';

IF (SELECT COUNT(*) FROM arbitraje.Arbitro
    WHERE id_pais = @id_pais AND nombre = 'Carlos' AND apellido = 'Garcia') <> 1
    THROW 50103, 'ERROR: la actualización generó duplicados.', 1;

IF NOT EXISTS (
    SELECT 1 FROM arbitraje.Arbitro
    WHERE id_pais = @id_pais
      AND nombre = 'Carlos'
      AND apellido = 'Garcia'
      AND categoria = 'Elite'
)
    THROW 50104, 'ERROR: no se actualizó la categoría.', 1;

IF NOT EXISTS (
    SELECT 1 FROM integracion.LogImportacion
    WHERE id = @id_log_2 AND resultado = 'EXITO'
)
    THROW 50105, 'ERROR: el segundo log no quedó EXITO.', 1;

PRINT 'OK - importación parcial, error por país inexistente, upsert y logs verificados.';
GO
