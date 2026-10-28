/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Probar la lógica de negocio del registro de importaciones,
    incluyendo resultados exitosos, parciales, fallidos
    y validaciones.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;


PRINT 'DATOS AUXILIARES';


EXEC integracion.usp_FuenteDatos_Insertar
    @id = 9600,
    @nombre = 'Dataset Test',
    @tipo = 'CSV',
    @url = 'https://ejemplo.com/dataset.csv';


PRINT '';
PRINT '1. IMPORTACION EXITOSA';

BEGIN TRY

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9600,
        @id_fuente = 9600,
        @archivo = 'jugadores.csv',
        @registros_correctos = 10,
        @errores_xml = NULL;


    IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = 9600
          AND resultado = 'EXITO'
    )
        PRINT 'OK - La importación quedó registrada como EXITO.';
    ELSE
        PRINT 'ERROR - El resultado debería ser EXITO.';


END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '2. IMPORTACION PARCIAL';

BEGIN TRY

    DECLARE @errores_parcial xml =
    N'
    <errores>
        <error id="9600" fila="4">Fecha inválida</error>
        <error id="9601" fila="8">País inexistente</error>
    </errores>';


    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9601,
        @id_fuente = 9600,
        @archivo = 'partidos.csv',
        @registros_correctos = 8,
        @errores_xml = @errores_parcial;


    IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = 9601
          AND resultado = 'PARCIAL'
    )
        PRINT 'OK - La importación quedó registrada como PARCIAL.';
    ELSE
        PRINT 'ERROR - El resultado debería ser PARCIAL.';


    IF (
        SELECT COUNT(*)
        FROM integracion.DetalleErrorImportacion
        WHERE id_log_importacion = 9601
    ) = 2
        PRINT 'OK - Se registraron los dos errores.';
    ELSE
        PRINT 'ERROR - Deberían existir dos errores.';


END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '3. IMPORTACION CON ERROR TOTAL';

BEGIN TRY

    DECLARE @errores_total xml =
    N'
    <errores>
        <error id="9602" fila="1">Formato de archivo inválido</error>
        <error id="9603" fila="2">Dato obligatorio faltante</error>
    </errores>';


    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9602,
        @id_fuente = 9600,
        @archivo = 'arbitros.csv',
        @registros_correctos = 0,
        @errores_xml = @errores_total;


    IF EXISTS (
        SELECT 1
        FROM integracion.LogImportacion
        WHERE id = 9602
          AND resultado = 'ERROR'
    )
        PRINT 'OK - La importación quedó registrada como ERROR.';
    ELSE
        PRINT 'ERROR - El resultado debería ser ERROR.';


END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '4. IMPORTACION SIN REGISTROS';

BEGIN TRY

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9603,
        @id_fuente = 9600,
        @archivo = 'vacio.csv',
        @registros_correctos = 0,
        @errores_xml = NULL;


    PRINT 'ERROR - El procedimiento debería haber fallado.';


END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó una importación sin registros:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '5. FUENTE INEXISTENTE';

BEGIN TRY

    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9604,
        @id_fuente = 999999,
        @archivo = 'datos.csv',
        @registros_correctos = 5,
        @errores_xml = NULL;


    PRINT 'ERROR - El procedimiento debería haber fallado.';


END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó la fuente inexistente:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '6. IDS DE ERROR DUPLICADOS';

BEGIN TRY

    DECLARE @errores_duplicados xml =
    N'
    <errores>
        <error id="9610" fila="2">Primer error</error>
        <error id="9610" fila="5">Segundo error</error>
    </errores>';


    EXEC integracion.usp_RegistrarResultadoImportacion
        @id_log = 9605,
        @id_fuente = 9600,
        @archivo = 'duplicados.csv',
        @registros_correctos = 3,
        @errores_xml = @errores_duplicados;


    PRINT 'ERROR - El procedimiento debería haber fallado.';


END TRY
BEGIN CATCH

    PRINT 'OK - Se detectaron ids de error duplicados:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT 'LOGS GENERADOS';


SELECT
    id,
    id_fuente,
    fecha,
    archivo,
    resultado
FROM integracion.LogImportacion
WHERE id IN (9600, 9601, 9602)
ORDER BY id;



PRINT '';
PRINT 'ERRORES GENERADOS';


SELECT
    id,
    id_log_importacion,
    fila,
    error
FROM integracion.DetalleErrorImportacion
WHERE id_log_importacion IN (9600, 9601, 9602)
ORDER BY id_log_importacion, fila;


IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;


PRINT '';
PRINT 'PRUEBAS FINALIZADAS - DATOS REVERTIDOS';
GO