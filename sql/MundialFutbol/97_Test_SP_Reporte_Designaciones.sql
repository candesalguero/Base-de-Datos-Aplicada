/*
Universidad: Universidad Nacional de La Matanza
Materia: Bases de Datos Aplicada
Integrantes:
    - Salguero, Candela
    - Ocaranza, Lucila
    - Dimattia Damm, Malena
    - Fuentes, Martina Alejandra

Fecha: Noviembre 2026

Objetivo:
    Entrega 7 - Script de testing (1:1) para validar la vista
    arbitraje.vw_DesignacionesArbitralesDetalle y el procedimiento almacenado
    arbitraje.usp_ReporteDesignacionesArbitrales (consulta general, filtros
    por fase/árbitro/estado, salida XML y manejo de excepciones THROW 50000).
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;

PRINT '  1. PRUEBA GENERAL: Reporte completo sin filtros (Tabular + XML)';

BEGIN TRY
    EXEC arbitraje.usp_ReporteDesignacionesArbitrales;
    PRINT 'OK - Reporte general ejecutado correctamente (grilla + XML).';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  2. PRUEBA FILTRO POR ESTADO: Solo designaciones CONFIRMADAS';

BEGIN TRY
    EXEC arbitraje.usp_ReporteDesignacionesArbitrales
        @estado = 'CONFIRMADA';

    PRINT 'OK - Filtro por estado CONFIRMADA ejecutado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  3. PRUEBA FILTRO POR ÁRBITRO: Designaciones de Szymon Marciniak';

BEGIN TRY
    DECLARE @id_marciniak int = (
        SELECT TOP 1 id
        FROM arbitraje.Arbitro
        WHERE apellido LIKE '%Marciniak%'
    );

    IF @id_marciniak IS NOT NULL
    BEGIN
        EXEC arbitraje.usp_ReporteDesignacionesArbitrales
            @id_arbitro = @id_marciniak;

        PRINT 'OK - Filtro por árbitro específico ejecutado correctamente.';
    END
    ELSE
        PRINT 'AVISO - No se encontró a Marciniak en arbitraje.Arbitro.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  4. PRUEBA FILTRO POR FASE: Primera fase disponible en general.Fase';

BEGIN TRY
    DECLARE @id_fase_prueba int = (SELECT TOP 1 id FROM general.Fase ORDER BY orden DESC);

    IF @id_fase_prueba IS NOT NULL
    BEGIN
        EXEC arbitraje.usp_ReporteDesignacionesArbitrales
            @id_fase = @id_fase_prueba;

        PRINT 'OK - Filtro por fase ejecutado correctamente.';
    END
    ELSE
        PRINT 'AVISO - No hay fases cargadas en general.Fase.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  5. PRUEBA VALIDACIÓN: Estado inválido (debe lanzar THROW 50000)';

BEGIN TRY
    EXEC arbitraje.usp_ReporteDesignacionesArbitrales
        @estado = 'ESTADO_INEXISTENTE';

    PRINT 'ERROR - El procedimiento debería haber rechazado el estado inválido.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó la validación esperada:';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  6. PRUEBA VALIDACIÓN: Árbitro inexistente (debe lanzar THROW 50000)';

BEGIN TRY
    EXEC arbitraje.usp_ReporteDesignacionesArbitrales
        @id_arbitro = 999999;

    PRINT 'ERROR - El procedimiento debería haber rechazado el árbitro inexistente.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó la validación esperada:';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  7. PRUEBA VALIDACIÓN: Fase inexistente (debe lanzar THROW 50000)';

BEGIN TRY
    EXEC arbitraje.usp_ReporteDesignacionesArbitrales
        @id_fase = 999999;

    PRINT 'ERROR - El procedimiento debería haber rechazado la fase inexistente.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó la validación esperada:';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  PRUEBAS DEL REPORTE DE DESIGNACIONES ARBITRALES FINALIZADAS';

GO