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
    Probar los procedimientos almacenados de ABM del esquema arbitraje,
    contemplando casos exitosos y validaciones de error.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

PRINT 'DATOS AUXILIARES PARA LAS PRUEBAS';


IF NOT EXISTS (
    SELECT 1
    FROM general.Confederacion
    WHERE id = 9900
)
BEGIN
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (9900, 'Confederacion Test');
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE id = 9900
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9900, 'Pais Test', 'ZZ', 'UTC-3', 9900);
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Idioma
    WHERE ISO639 = 'tst'
)
BEGIN
    INSERT INTO general.Idioma (ISO639, nombre)
    VALUES ('tst', 'Idioma Test');
END;

IF NOT EXISTS (
    SELECT 1
    FROM general.Idioma
    WHERE ISO639 = 'zzz'
)
BEGIN
    INSERT INTO general.Idioma (ISO639, nombre)
    VALUES ('zzz', 'Idioma Test 2');
END;


PRINT '';
PRINT '1. ROL ARBITRAL - INSERTAR CORRECTO';


BEGIN TRY
    EXEC arbitraje.usp_RolArbitral_Insertar
        @id = 9900,
        @nombre = 'Rol Test';

    PRINT 'OK - Rol arbitral insertado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '2. ROL ARBITRAL - VALIDACIONES';

BEGIN TRY
    EXEC arbitraje.usp_RolArbitral_Insertar
        @id = -1,
        @nombre = '';

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron las validaciones:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '3. ROL ARBITRAL - ACTUALIZAR';

BEGIN TRY
    EXEC arbitraje.usp_RolArbitral_Actualizar
        @id = 9900,
        @nombre = 'Rol Test Actualizado';

    PRINT 'OK - Rol arbitral actualizado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '4. ÁRBITRO - INSERTAR CORRECTO';

BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Insertar
        @id = 9900,
        @nombre = 'Arbitro',
        @apellido = 'Prueba',
        @categoria = 'Internacional',
        @id_pais = 9900;

    PRINT 'OK - Árbitro insertado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '5. ÁRBITRO - MÚLTIPLES VALIDACIONES';

BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Insertar
        @id = -1,
        @nombre = '',
        @apellido = '',
        @categoria = '',
        @id_pais = 999999;

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectaron múltiples errores:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '6. ÁRBITRO - ACTUALIZAR';

BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Actualizar
        @id = 9900,
        @nombre = 'Arbitro Actualizado',
        @apellido = 'Prueba',
        @categoria = 'FIFA',
        @id_pais = 9900;

    PRINT 'OK - Árbitro actualizado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '7. ÁRBITRO IDIOMA - INSERTAR';

BEGIN TRY
    EXEC arbitraje.usp_ArbitroIdioma_Insertar
        @id_arbitro = 9900,
        @id_idioma = 'tst';

    PRINT 'OK - Idioma asociado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '8. ÁRBITRO IDIOMA - DUPLICADO';

BEGIN TRY
    EXEC arbitraje.usp_ArbitroIdioma_Insertar
        @id_arbitro = 9900,
        @id_idioma = 'tst';

    PRINT 'ERROR - El procedimiento debería haber fallado.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se detectó el idioma duplicado:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '9. ÁRBITRO - ELIMINAR CON IDIOMA';

BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Eliminar
        @id = 9900;

    PRINT 'ERROR - No debería permitirse eliminar el árbitro.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se impidió eliminar el árbitro:';
    PRINT ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '10. ÁRBITRO IDIOMA - ACTUALIZAR';

BEGIN TRY
    EXEC arbitraje.usp_ArbitroIdioma_Actualizar
        @id_arbitro = 9900,
        @id_idioma_actual = 'tst',
        @id_idioma_nuevo = 'zzz';

    PRINT 'OK - Idioma actualizado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '11. ÁRBITRO IDIOMA - ELIMINAR';

BEGIN TRY
    EXEC arbitraje.usp_ArbitroIdioma_Eliminar
        @id_arbitro = 9900,
        @id_idioma = 'zzz';

    PRINT 'OK - Asociación árbitro-idioma eliminada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '12. ÁRBITRO - ELIMINAR CORRECTO';

BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Eliminar
        @id = 9900;

    PRINT 'OK - Árbitro eliminado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
GO


PRINT '';
PRINT '13. ROL ARBITRAL - ELIMINAR';

BEGIN TRY
    EXEC arbitraje.usp_RolArbitral_Eliminar
        @id = 9900;

    PRINT 'OK - Rol arbitral eliminado correctamente.';
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