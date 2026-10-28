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

DECLARE @idSeleccionLocal int;
DECLARE @idSeleccionVisitante int;
DECLARE @idPartido int;


PRINT 'DATOS AUXILIARES';


IF NOT EXISTS (
    SELECT 1 FROM general.Confederacion WHERE id = 9900
)
BEGIN
    INSERT INTO general.Confederacion (id, nombre)
    VALUES (9900, 'Confederacion Test');
END;


IF NOT EXISTS (
    SELECT 1 FROM general.Pais WHERE id = 9900
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9900, 'Pais Test A', 'ZZ', 'UTC-3', 9900);
END;


IF NOT EXISTS (
    SELECT 1 FROM general.Pais WHERE id = 9901
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9901, 'Pais Test B', 'ZY', 'UTC-3', 9900);
END;


IF NOT EXISTS (
    SELECT 1 FROM general.Idioma WHERE ISO639 = 'tst'
)
BEGIN
    INSERT INTO general.Idioma (ISO639, nombre)
    VALUES ('tst', 'Idioma Test');
END;

IF NOT EXISTS (
    SELECT 1 FROM general.Idioma WHERE ISO639 = 'zzz'
)
BEGIN
    INSERT INTO general.Idioma (ISO639, nombre)
    VALUES ('zzz', 'Idioma Test 2');
END;


IF NOT EXISTS (
    SELECT 1 FROM general.Fase WHERE id = 9900
)
BEGIN
    INSERT INTO general.Fase
        (id, nombre, orden, es_eliminacion_directa)
    VALUES
        (9900, 'Fase Test', 99, 0);
END;


IF NOT EXISTS (
    SELECT 1 FROM general.Sede WHERE id = 9900
)
BEGIN
    INSERT INTO general.Sede
        (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario)
    VALUES
        (9900, 9900, 'Estadio Test', 'Ciudad Test', 10000, 'UTC-3');
END;


INSERT INTO deportivo.Seleccion
    (id_pais, nombre, grupo)
VALUES
    (9900, 'Seleccion Test A', 'A');

SET @idSeleccionLocal = SCOPE_IDENTITY();


INSERT INTO deportivo.Seleccion
    (id_pais, nombre, grupo)
VALUES
    (9901, 'Seleccion Test B', 'B');

SET @idSeleccionVisitante = SCOPE_IDENTITY();


INSERT INTO deportivo.Partido
(
    id_sede,
    id_fase,
    id_seleccion_local,
    id_seleccion_visitante,
    fecha_hora_local,
    fecha_hora_utc
)
VALUES
(
    9900,
    9900,
    @idSeleccionLocal,
    @idSeleccionVisitante,
    '2026-11-10T18:00:00',
    '2026-11-10T21:00:00'
);

SET @idPartido = SCOPE_IDENTITY();


PRINT '';
PRINT '1. ROL ARBITRAL - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_RolArbitral_Insertar
        @id = 9900,
        @nombre = 'Principal Test';

    PRINT 'OK - Rol arbitral insertado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


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


PRINT '';
PRINT '3. ROL ARBITRAL - ACTUALIZAR';

BEGIN TRY

    EXEC arbitraje.usp_RolArbitral_Actualizar
        @id = 9900,
        @nombre = 'Arbitro Principal Test';

    PRINT 'OK - Rol actualizado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '4. ARBITRO - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_Arbitro_Insertar
        @id = 9900,
        @nombre = 'Carlos',
        @apellido = 'Arbitro Test',
        @categoria = 'Internacional',
        @id_pais = 9900;

    PRINT 'OK - Árbitro insertado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '5. ARBITRO - VALIDACIONES';

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


PRINT '';
PRINT '6. ARBITRO - ACTUALIZAR';

BEGIN TRY

    EXEC arbitraje.usp_Arbitro_Actualizar
        @id = 9900,
        @nombre = 'Carlos',
        @apellido = 'Arbitro Actualizado',
        @categoria = 'FIFA',
        @id_pais = 9900;

    PRINT 'OK - Árbitro actualizado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '7. ARBITRO IDIOMA - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_ArbitroIdioma_Insertar
        @id_arbitro = 9900,
        @id_idioma = 'tst';

    PRINT 'OK - Idioma asociado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '8. ARBITRO IDIOMA - DUPLICADO';

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


PRINT '';
PRINT '9. ARBITRO IDIOMA - ACTUALIZAR';

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


PRINT '';
PRINT '10. DESIGNACION ARBITRAL - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_DesignacionArbitral_Insertar
        @id = 9900,
        @id_partido = @idPartido,
        @id_arbitro = 9900,
        @id_rol_arbitral = 9900,
        @estado = 'CONFIRMADA',
        @motivo_descarte = NULL;

    PRINT 'OK - Designación arbitral insertada correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '11. DESIGNACION ARBITRAL - DUPLICADA';

BEGIN TRY

    EXEC arbitraje.usp_DesignacionArbitral_Insertar
        @id = 9901,
        @id_partido = @idPartido,
        @id_arbitro = 9900,
        @id_rol_arbitral = 9900,
        @estado = 'CONFIRMADA';

    PRINT 'ERROR - La designación duplicada debería haber fallado.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó la designación duplicada:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '12. DESIGNACION DESCARTADA SIN MOTIVO';

BEGIN TRY

    EXEC arbitraje.usp_DesignacionArbitral_Actualizar
        @id = 9900,
        @id_partido = @idPartido,
        @id_arbitro = 9900,
        @id_rol_arbitral = 9900,
        @estado = 'DESCARTADA',
        @motivo_descarte = NULL;

    PRINT 'ERROR - Debería exigir motivo de descarte.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó la falta de motivo:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '13. INFORME POST PARTIDO - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_InformePostPartido_Insertar
        @id = 9900,
        @id_partido = @idPartido,
        @id_arbitro = 9900,
        @observaciones = 'Buen desempeño general',
        @calificacion_desempeno = 8.5;

    PRINT 'OK - Informe insertado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '14. INFORME POST PARTIDO - DUPLICADO';

BEGIN TRY

    EXEC arbitraje.usp_InformePostPartido_Insertar
        @id = 9901,
        @id_partido = @idPartido,
        @id_arbitro = 9900,
        @observaciones = 'Segundo informe',
        @calificacion_desempeno = 7;

    PRINT 'ERROR - El informe duplicado debería haber fallado.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó el informe duplicado:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '15. INFORME POST PARTIDO - ACTUALIZAR';

BEGIN TRY

    EXEC arbitraje.usp_InformePostPartido_Actualizar
        @id = 9900,
        @observaciones = 'Desempeño actualizado',
        @calificacion_desempeno = 9;

    PRINT 'OK - Informe actualizado correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '16. SANCION ARBITRAL - INSERTAR';

BEGIN TRY

    EXEC arbitraje.usp_SancionArbitral_Insertar
        @id = 9900,
        @id_arbitro = 9900,
        @id_informe = 9900,
        @descripcion = 'Sanción de prueba',
        @motivo = 'Incumplimiento reglamentario',
        @cantidad_partidos_inhabilitados = 2,
        @estado = 'ACTIVA';

    PRINT 'OK - Sanción insertada correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '17. SANCION ARBITRAL - VALIDACIONES';

BEGIN TRY

    EXEC arbitraje.usp_SancionArbitral_Insertar
        @id = 9901,
        @id_arbitro = 9900,
        @id_informe = 9900,
        @descripcion = '',
        @motivo = '',
        @cantidad_partidos_inhabilitados = 0,
        @estado = '';

    PRINT 'ERROR - El procedimiento debería haber fallado.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectaron las validaciones:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '18. SANCION ARBITRAL - ACTUALIZAR';

BEGIN TRY

    EXEC arbitraje.usp_SancionArbitral_Actualizar
        @id = 9900,
        @descripcion = 'Sanción actualizada',
        @motivo = 'Motivo actualizado',
        @cantidad_partidos_inhabilitados = 3,
        @estado = 'ACTIVA';

    PRINT 'OK - Sanción actualizada correctamente.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '19. NO ELIMINAR INFORME CON SANCION';

BEGIN TRY

    EXEC arbitraje.usp_InformePostPartido_Eliminar
        @id = 9900;

    PRINT 'ERROR - El informe no debería poder eliminarse.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se impidió eliminar el informe:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '20. NO ELIMINAR ARBITRO CON RELACIONES';

BEGIN TRY

    EXEC arbitraje.usp_Arbitro_Eliminar
        @id = 9900;

    PRINT 'ERROR - El árbitro no debería poder eliminarse.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se impidió eliminar el árbitro:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '21. LIMPIEZA DE DATOS';


BEGIN TRY
    EXEC arbitraje.usp_SancionArbitral_Eliminar
        @id = 9900;

    PRINT 'OK - Sanción eliminada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


BEGIN TRY
    EXEC arbitraje.usp_InformePostPartido_Eliminar
        @id = 9900;

    PRINT 'OK - Informe eliminado.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


BEGIN TRY
    EXEC arbitraje.usp_DesignacionArbitral_Eliminar
        @id = 9900;

    PRINT 'OK - Designación eliminada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


BEGIN TRY
    EXEC arbitraje.usp_ArbitroIdioma_Eliminar
        @id_arbitro = 9900,
        @id_idioma = 'zzz';

    PRINT 'OK - Idioma del árbitro eliminado.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


BEGIN TRY
    EXEC arbitraje.usp_Arbitro_Eliminar
        @id = 9900;

    PRINT 'OK - Árbitro eliminado.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


/* Rol */
BEGIN TRY
    EXEC arbitraje.usp_RolArbitral_Eliminar
        @id = 9900;

    PRINT 'OK - Rol arbitral eliminado.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;


IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

PRINT '';
PRINT 'PRUEBAS FINALIZADAS - DATOS REVERTIDOS';
GO