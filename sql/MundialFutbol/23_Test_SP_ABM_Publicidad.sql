/*
    Objetivo:
    Probar los procedimientos ABM del esquema publicidad,
    contemplando altas, validaciones y bajas fisicas.

    Los datos auxiliares se crean dentro de una transaccion y se revierten
    al finalizar la prueba.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

DECLARE @id_pais int = 9950;
DECLARE @id_confederacion int = 9950;
DECLARE @id_moneda int = 9950;
DECLARE @id_idioma char(3) = 'pbt';
DECLARE @id_anunciante int;

IF NOT EXISTS (SELECT 1 FROM general.Confederacion WHERE id = @id_confederacion)
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (@id_confederacion, 'Confederacion Publicidad Test');

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = @id_pais)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES (@id_pais, 'Pais Publicidad Test', 'PB', 'UTC-3', @id_confederacion);

IF NOT EXISTS (SELECT 1 FROM general.Moneda WHERE id = @id_moneda)
    INSERT INTO general.Moneda (id, cod_iso3, nombre)
    VALUES (@id_moneda, 'PBT', 'Moneda Publicidad Test');

IF NOT EXISTS (SELECT 1 FROM general.Idioma WHERE ISO639 = @id_idioma)
    INSERT INTO general.Idioma (ISO639, nombre)
    VALUES (@id_idioma, 'Idioma Publicidad Test');



PRINT '1. ANUNCIANTE - INSERTAR';
BEGIN TRY
    EXEC publicidad.usp_Anunciante_Insertar
        @id_pais_origen = @id_pais,
        @tax_id = 'PBT-0001',
        @nombre_empresa = 'Empresa Publicidad Test',
        @id_anunciante = @id_anunciante OUTPUT;
    PRINT 'OK - Anunciante insertado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

PRINT '2. ANUNCIANTE - VALIDACIONES';
BEGIN TRY
    EXEC publicidad.usp_Anunciante_Insertar
        @id_pais_origen = NULL,
        @tax_id = '',
        @nombre_empresa = '';
    PRINT 'ERROR - El procedimiento deberia haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron las validaciones:';
    PRINT ERROR_MESSAGE();
END CATCH;


PRINT '3. ANUNCIANTE - ELIMINAR FISICAMENTE';
DECLARE @id_anunciante_eliminar int;
BEGIN TRY
    EXEC publicidad.usp_Anunciante_Insertar
        @id_pais_origen = @id_pais,
        @tax_id = 'PBT-0002',
        @nombre_empresa = 'Empresa A Eliminar',
        @id_anunciante = @id_anunciante_eliminar OUTPUT;

    EXEC publicidad.usp_Anunciante_Eliminar
        @id_anunciante = @id_anunciante_eliminar;

    IF NOT EXISTS (
        SELECT 1 FROM publicidad.Anunciante WHERE id = @id_anunciante_eliminar
    )
        PRINT 'OK - Anunciante eliminado fisicamente.';
    ELSE
        PRINT 'ERROR - El anunciante no fue eliminado fisicamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

PRINT '4. ANUNCIANTE - ELIMINAR INEXISTENTE';
BEGIN TRY
    EXEC publicidad.usp_Anunciante_Eliminar @id_anunciante = 999999;
    PRINT 'ERROR - La eliminacion deberia haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se rechazo el anunciante inexistente:';
    PRINT ERROR_MESSAGE();
END CATCH;

IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

PRINT 'PRUEBAS ABM FINALIZADAS - DATOS REVERTIDOS';
GO

