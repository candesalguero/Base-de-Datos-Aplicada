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
    Probar la lógica de negocio correspondiente a las designaciones
    arbitrales y la validación de conflicto de nacionalidad.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

DECLARE @id_seleccion_local int;
DECLARE @id_seleccion_visitante int;
DECLARE @id_partido int;


IF NOT EXISTS (
    SELECT 1
    FROM general.Confederacion
    WHERE id = 9700
)
BEGIN
    INSERT INTO general.Confederacion
        (id, nombre)
    VALUES
        (9700, 'Confederacion Test Negocio');
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE id = 9700
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9700, 'Pais Local Test', 'XL', 'UTC-3', 9700);
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE id = 9701
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9701, 'Pais Visitante Test', 'XV', 'UTC-3', 9700);
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Pais
    WHERE id = 9702
)
BEGIN
    INSERT INTO general.Pais
        (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES
        (9702, 'Pais Neutral Test', 'XN', 'UTC-3', 9700);
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Fase
    WHERE id = 9700
)
BEGIN
    INSERT INTO general.Fase
        (id, nombre, orden, es_eliminacion_directa)
    VALUES
        (9700, 'Fase Negocio Test', 98, 0);
END;


IF NOT EXISTS (
    SELECT 1
    FROM general.Sede
    WHERE id = 9700
)
BEGIN
    INSERT INTO general.Sede
        (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario)
    VALUES
        (9700, 9700, 'Estadio Negocio Test',
         'Ciudad Test', 20000, 'UTC-3');
END;


INSERT INTO deportivo.Seleccion
    (id_pais, nombre, grupo)
VALUES
    (9700, 'Seleccion Local Test', 'A');

SET @id_seleccion_local = SCOPE_IDENTITY();


INSERT INTO deportivo.Seleccion
    (id_pais, nombre, grupo)
VALUES
    (9701, 'Seleccion Visitante Test', 'B');

SET @id_seleccion_visitante = SCOPE_IDENTITY();


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
    9700,
    9700,
    @id_seleccion_local,
    @id_seleccion_visitante,
    '2026-11-20T18:00:00',
    '2026-11-20T21:00:00'
);

SET @id_partido = SCOPE_IDENTITY();


EXEC arbitraje.usp_RolArbitral_Insertar
    @id = 9700,
    @nombre = 'Principal Negocio Test';


EXEC arbitraje.usp_Arbitro_Insertar
    @id = 9700,
    @nombre = 'Arbitro',
    @apellido = 'Local',
    @categoria = 'FIFA',
    @id_pais = 9700;


EXEC arbitraje.usp_Arbitro_Insertar
    @id = 9701,
    @nombre = 'Arbitro',
    @apellido = 'Visitante',
    @categoria = 'FIFA',
    @id_pais = 9701;


EXEC arbitraje.usp_Arbitro_Insertar
    @id = 9702,
    @nombre = 'Arbitro',
    @apellido = 'Neutral',
    @categoria = 'FIFA',
    @id_pais = 9702;


EXEC arbitraje.usp_Arbitro_Insertar
    @id = 9703,
    @nombre = 'Segundo',
    @apellido = 'Neutral',
    @categoria = 'FIFA',
    @id_pais = 9702;


PRINT '';
PRINT '1. ARBITRO DEL PAIS LOCAL';

BEGIN TRY

    EXEC arbitraje.usp_DesignarArbitro
        @id_designacion = 9700,
        @id_partido = @id_partido,
        @id_arbitro = 9700,
        @id_rol_arbitral = 9700;


    IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id = 9700
          AND estado = 'DESCARTADA'
          AND motivo_descarte IS NOT NULL
    )
        PRINT 'OK - El árbitro local fue descartado por nacionalidad.';
    ELSE
        PRINT 'ERROR - El árbitro local debería haber sido descartado.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '2. ARBITRO DEL PAIS VISITANTE';

BEGIN TRY

    EXEC arbitraje.usp_DesignarArbitro
        @id_designacion = 9701,
        @id_partido = @id_partido,
        @id_arbitro = 9701,
        @id_rol_arbitral = 9700;


    IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id = 9701
          AND estado = 'DESCARTADA'
          AND motivo_descarte IS NOT NULL
    )
        PRINT 'OK - El árbitro visitante fue descartado por nacionalidad.';
    ELSE
        PRINT 'ERROR - El árbitro visitante debería haber sido descartado.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '3. ARBITRO NEUTRAL';

BEGIN TRY

    EXEC arbitraje.usp_DesignarArbitro
        @id_designacion = 9702,
        @id_partido = @id_partido,
        @id_arbitro = 9702,
        @id_rol_arbitral = 9700;


    IF EXISTS (
        SELECT 1
        FROM arbitraje.DesignacionArbitral
        WHERE id = 9702
          AND estado = 'CONFIRMADA'
          AND motivo_descarte IS NULL
    )
        PRINT 'OK - El árbitro neutral fue confirmado correctamente.';
    ELSE
        PRINT 'ERROR - El árbitro neutral debería estar confirmado.';

END TRY
BEGIN CATCH

    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '4. ARBITRO DUPLICADO';

BEGIN TRY

    EXEC arbitraje.usp_DesignarArbitro
        @id_designacion = 9703,
        @id_partido = @id_partido,
        @id_arbitro = 9702,
        @id_rol_arbitral = 9700;

    PRINT 'ERROR - El árbitro no debería poder designarse nuevamente.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó que el árbitro ya fue evaluado:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT '5. ROL ARBITRAL YA OCUPADO';

BEGIN TRY

    EXEC arbitraje.usp_DesignarArbitro
        @id_designacion = 9704,
        @id_partido = @id_partido,
        @id_arbitro = 9703,
        @id_rol_arbitral = 9700;

    PRINT 'ERROR - No debería poder ocupar un rol ya confirmado.';

END TRY
BEGIN CATCH

    PRINT 'OK - Se detectó que el rol ya está ocupado:';
    PRINT ERROR_MESSAGE();

END CATCH;


PRINT '';
PRINT 'DESIGNACIONES GENERADAS:';

SELECT
    d.id,
    d.id_partido,
    d.id_arbitro,
    a.nombre,
    a.apellido,
    d.id_rol_arbitral,
    d.estado,
    d.motivo_descarte
FROM arbitraje.DesignacionArbitral AS d
INNER JOIN arbitraje.Arbitro AS a
    ON a.id = d.id_arbitro
WHERE d.id IN (9700, 9701, 9702)
ORDER BY d.id;


IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;


PRINT '';
PRINT 'PRUEBAS FINALIZADAS - DATOS REVERTIDOS';
GO