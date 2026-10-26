/*
    Universidad: Universidad de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Probar los procedimientos almacenados de ABM del esquema integracion,
    contemplando casos exitosos y validaciones de error.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;


PRINT '1. FUENTE DE DATOS - INSERTAR';

BEGIN TRY
    EXEC integracion.usp_FuenteDatos_Insertar
        @id = 9800,
        @nombre = 'API Test',
        @tipo = 'API',
        @url = 'https://api.test.com';

    PRINT 'OK - Fuente de datos insertada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '2. FUENTE DE DATOS - VALIDACIONES';

BEGIN TRY
    EXEC integracion.usp_FuenteDatos_Insertar
        @id = -1,
        @nombre = '',
        @tipo = 'INVALIDO',
        @url = NULL;

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron múltiples validaciones:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '3. FUENTE DE DATOS - ACTUALIZAR';

BEGIN TRY
    EXEC integracion.usp_FuenteDatos_Actualizar
        @id = 9800,
        @nombre = 'API Test Actualizada',
        @tipo = 'API',
        @url = 'https://api.test.com/v2';

    PRINT 'OK - Fuente actualizada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '4. LOG IMPORTACIÓN - INSERTAR';

BEGIN TRY
    EXEC integracion.usp_LogImportacion_Insertar
        @id = 9800,
        @id_fuente = 9800,
        @fecha = '2026-10-26T18:00:00',
        @archivo = 'datos_test.json',
        @resultado = 'PARCIAL';

    PRINT 'OK - Log de importación insertado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '5. LOG IMPORTACIÓN - VALIDACIONES';

BEGIN TRY
    EXEC integracion.usp_LogImportacion_Insertar
        @id = -2,
        @id_fuente = 999999,
        @fecha = NULL,
        @archivo = '',
        @resultado = 'DESCONOCIDO';

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron múltiples validaciones:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '6. LOG IMPORTACIÓN - ACTUALIZAR';

BEGIN TRY
    EXEC integracion.usp_LogImportacion_Actualizar
        @id = 9800,
        @id_fuente = 9800,
        @fecha = '2026-10-26T18:30:00',
        @archivo = 'datos_test.json',
        @resultado = 'ERROR';

    PRINT 'OK - Log actualizado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '7. DETALLE ERROR - INSERTAR';

BEGIN TRY
    EXEC integracion.usp_DetalleErrorImportacion_Insertar
        @id = 9800,
        @id_log_importacion = 9800,
        @fila = 12,
        @error = 'Formato inválido en el campo nombre';

    PRINT 'OK - Detalle de error insertado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '8. DETALLE ERROR - VALIDACIONES';

BEGIN TRY
    EXEC integracion.usp_DetalleErrorImportacion_Insertar
        @id = -5,
        @id_log_importacion = 999999,
        @fila = 0,
        @error = '';

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron múltiples validaciones:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '9. DETALLE ERROR - ACTUALIZAR';

BEGIN TRY
    EXEC integracion.usp_DetalleErrorImportacion_Actualizar
        @id = 9800,
        @id_log_importacion = 9800,
        @fila = 15,
        @error = 'Dato obligatorio faltante';

    PRINT 'OK - Detalle de error actualizado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '10. NO ELIMINAR LOG CON ERRORES';

BEGIN TRY
    EXEC integracion.usp_LogImportacion_Eliminar
        @id = 9800;

    PRINT 'ERROR - El log no debería poder eliminarse.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se impidió eliminar el log:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '11. NO ELIMINAR FUENTE CON LOGS';

BEGIN TRY
    EXEC integracion.usp_FuenteDatos_Eliminar
        @id = 9800;

    PRINT 'ERROR - La fuente no debería poder eliminarse.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se impidió eliminar la fuente:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '12. DETALLE ERROR - ELIMINAR';

BEGIN TRY
    EXEC integracion.usp_DetalleErrorImportacion_Eliminar
        @id = 9800;

    PRINT 'OK - Detalle de error eliminado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '13. LOG IMPORTACIÓN - ELIMINAR';

BEGIN TRY
    EXEC integracion.usp_LogImportacion_Eliminar
        @id = 9800;

    PRINT 'OK - Log eliminado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '14. FUENTE DE DATOS - ELIMINAR';

BEGIN TRY
    EXEC integracion.usp_FuenteDatos_Eliminar
        @id = 9800;

    PRINT 'OK - Fuente de datos eliminada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
GO


PRINT '';
PRINT 'PRUEBAS FINALIZADAS - DATOS REVERTIDOS';
GO