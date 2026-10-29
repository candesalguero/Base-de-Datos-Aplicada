/*
    Objetivo:
    Probar la logica de negocio del esquema publicidad,
    contemplando operaciones atomicas, calculo de prime time,
    validaciones acumuladas, duplicados, dependencias y rollback.

    El partido auxiliar se crea exclusivamente porque
    publicidad.ExhibicionPublicitaria referencia deportivo.Partido y la
    logica de publicidad necesita su fecha, hora UTC y sede para calcular
    el indicador de prime time. Todos los datos auxiliares se revierten
    al finalizar la prueba.
*/

USE MundialFutbol;
GO

BEGIN TRANSACTION;

DECLARE @id_pais int = 9950;
DECLARE @id_confederacion int = 9950;
DECLARE @id_moneda int = 9950;
DECLARE @id_idioma char(3) = 'pbt';
DECLARE @id_fase int = 9950;
DECLARE @id_sede int = 9950;
DECLARE @id_seleccion_local int;
DECLARE @id_seleccion_visitante int;
DECLARE @id_partido int;
DECLARE @fecha_partido date = '2026-11-20';
DECLARE @hora_partido_local time(0) = '18:00:00';
DECLARE @hora_partido_utc time(0) = '22:00:00';
DECLARE @id_anunciante int;
DECLARE @id_campana int;
DECLARE @id_pieza int;
DECLARE @id_exhibicion int;
DECLARE @id_tarifa int;
DECLARE @id_espacio int;
DECLARE @mensaje_error nvarchar(2047);

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

IF NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = @id_fase)
    INSERT INTO general.Fase (id, nombre, orden, es_eliminacion_directa)
    VALUES (@id_fase, 'Fase Publicidad Test', 95, 0);

IF NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = @id_sede)
    INSERT INTO general.Sede
        (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario)
    VALUES
        (@id_sede, @id_pais, 'Estadio Publicidad Test', 'Ciudad Publicidad Test',
         10000, 'UTC-3');

INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo)
VALUES (@id_pais, 'Seleccion Publicidad Local', 'A');
SET @id_seleccion_local = SCOPE_IDENTITY();

INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo)
VALUES (@id_pais, 'Seleccion Publicidad Visitante', 'B');
SET @id_seleccion_visitante = SCOPE_IDENTITY();

INSERT INTO deportivo.Partido
    (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante,
     fecha_hora_local, fecha_hora_utc)
VALUES
    (@id_sede, @id_fase, @id_seleccion_local, @id_seleccion_visitante,
     DATEADD(SECOND,
             DATEDIFF(SECOND, CAST('00:00:00' AS time(0)), @hora_partido_local),
             CAST(@fecha_partido AS datetime)),
     DATEADD(SECOND,
             DATEDIFF(SECOND, CAST('00:00:00' AS time(0)), @hora_partido_utc),
             CAST(@fecha_partido AS datetime)));
SET @id_partido = SCOPE_IDENTITY();



EXEC publicidad.usp_Anunciante_Insertar
    @id_pais_origen = @id_pais,
    @tax_id = 'PBT-0001',
    @nombre_empresa = 'Empresa Publicidad Test',
    @id_anunciante = @id_anunciante OUTPUT;
PRINT '5. CAMPANA Y PIEZA - VALIDACIONES ACUMULADAS';
BEGIN TRY
    EXEC publicidad.usp_RegistrarCampanaConPieza
        @id_anunciante = NULL,
        @id_moneda = NULL,
        @nombre_campana = '',
        @fecha_inicio = NULL,
        @fecha_fin = NULL,
        @presupuesto = -1,
        @id_tarifa = NULL,
        @id_idioma = NULL,
        @titulo = '',
        @duracion = 0;

    PRINT 'ERROR - La operacion deberia haber acumulado errores.';
END TRY
BEGIN CATCH
    SET @mensaje_error = ERROR_MESSAGE();

    IF CHARINDEX('El anunciante es obligatorio', @mensaje_error) > 0
       AND CHARINDEX('La moneda es obligatoria', @mensaje_error) > 0
       AND CHARINDEX('El nombre de la campana es obligatorio', @mensaje_error) > 0
       AND CHARINDEX('El presupuesto no puede ser negativo', @mensaje_error) > 0
    BEGIN
        PRINT 'OK - Se acumularon varias validaciones en un unico THROW:';
        PRINT @mensaje_error;
    END
    ELSE
    BEGIN
        PRINT 'ERROR - El mensaje no contiene todas las validaciones esperadas:';
        PRINT @mensaje_error;
    END
END CATCH;

INSERT INTO publicidad.Tarifa
    (id_moneda, nombre, costo_base, vigente_desde)
VALUES
    (@id_moneda, 'Tarifa Publicidad Test', 1250.00, '2026-01-01');
SET @id_tarifa = SCOPE_IDENTITY();

SELECT @id_espacio = id
FROM publicidad.EspacioPublicitario
WHERE ubicacion_panel = 'Panel 1';

PRINT '6. CAMPANA Y PIEZA - OPERACION TRANSACCIONAL';
BEGIN TRY
    EXEC publicidad.usp_RegistrarCampanaConPieza
        @id_anunciante = @id_anunciante,
        @id_moneda = @id_moneda,
        @nombre_campana = 'Campana Publicidad Test',
        @fecha_inicio = '2026-01-01',
        @fecha_fin = '2026-12-31',
        @presupuesto = 100000.00,
        @id_tarifa = @id_tarifa,
        @id_idioma = @id_idioma,
        @titulo = 'Pieza Publicidad Test',
        @descripcion = 'Contenido de prueba',
        @duracion = 30,
        @id_campana = @id_campana OUTPUT,
        @id_pieza = @id_pieza OUTPUT;

    IF EXISTS (
        SELECT 1
        FROM publicidad.Campana AS c
        INNER JOIN publicidad.PiezaDeContenido AS p ON p.id_campana = c.id
        WHERE c.id = @id_campana AND p.id = @id_pieza
    )
        PRINT 'OK - Campana y pieza creadas atomicamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

PRINT '7. ANUNCIANTE CON CAMPANA - BLOQUEO DE DELETE FISICO';
BEGIN TRY
    EXEC publicidad.usp_Anunciante_Eliminar @id_anunciante = @id_anunciante;
    PRINT 'ERROR - No deberia eliminarse un anunciante con campanas asociadas.';
END TRY
BEGIN CATCH
    IF CHARINDEX('campanas asociadas', ERROR_MESSAGE()) > 0
    BEGIN
        PRINT 'OK - Se bloqueo el DELETE por dependencia referencial:';
        PRINT ERROR_MESSAGE();
    END
    ELSE
    BEGIN
        PRINT 'ERROR - Mensaje inesperado:';
        PRINT ERROR_MESSAGE();
    END
END CATCH;

PRINT '8. EXHIBICION - CALCULO DE PRIME TIME';
BEGIN TRY
    EXEC publicidad.usp_RegistrarExhibicionPublicitaria
        @id_partido = @id_partido,
        @id_pieza = @id_pieza,
        @id_espacio_publicitario = @id_espacio,
        @id_exhibicion = @id_exhibicion OUTPUT;

    IF EXISTS (
        SELECT 1
        FROM publicidad.ExhibicionPublicitaria
        WHERE id = @id_exhibicion
          AND estado = 'VIGENTE'
          AND fue_prime_time = 1
    )
        PRINT 'OK - Exhibicion vigente y prime time calculado.';
    ELSE
        PRINT 'ERROR - La exhibicion no quedo en el estado esperado.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;

PRINT '9. EXHIBICION DUPLICADA - ROLLBACK';
BEGIN TRY
    EXEC publicidad.usp_RegistrarExhibicionPublicitaria
        @id_partido = @id_partido,
        @id_pieza = @id_pieza,
        @id_espacio_publicitario = @id_espacio;
    PRINT 'ERROR - No deberia permitirse una exhibicion duplicada.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se rechazo la exhibicion duplicada y se revirtio la transaccion:';
    PRINT ERROR_MESSAGE();
END CATCH;

PRINT '10. EXHIBICION - VALIDACIONES ACUMULADAS';
BEGIN TRY
    EXEC publicidad.usp_RegistrarExhibicionPublicitaria
        @id_partido = NULL,
        @id_pieza = NULL,
        @id_espacio_publicitario = NULL;

    PRINT 'ERROR - La operacion deberia haber acumulado errores.';
END TRY
BEGIN CATCH
    SET @mensaje_error = ERROR_MESSAGE();

    IF CHARINDEX('El partido indicado no existe', @mensaje_error) > 0
       AND CHARINDEX('La pieza es obligatoria', @mensaje_error) > 0
       AND CHARINDEX('El espacio publicitario es obligatorio', @mensaje_error) > 0
       AND CHARINDEX('El huso horario de la sede no es valido', @mensaje_error) > 0
    BEGIN
        PRINT 'OK - Se acumularon varias validaciones en un unico THROW:';
        PRINT @mensaje_error;
    END
    ELSE
    BEGIN
        PRINT 'ERROR - El mensaje no contiene todas las validaciones esperadas:';
        PRINT @mensaje_error;
    END
END CATCH;

PRINT '11. PIEZA FUERA DE VIGENCIA - ERROR';
BEGIN TRY
    EXEC publicidad.usp_RegistrarExhibicionPublicitaria
        @id_partido = @id_partido,
        @id_pieza = 999999,
        @id_espacio_publicitario = @id_espacio;
    PRINT 'ERROR - No deberia permitirse una pieza inexistente.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se rechazo la pieza inexistente:';
    PRINT ERROR_MESSAGE();
END CATCH;

SELECT id, id_partido, id_pieza, id_espacio_publicitario, estado, fue_prime_time
FROM publicidad.ExhibicionPublicitaria
WHERE id = @id_exhibicion;


IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

PRINT 'PRUEBAS DE NEGOCIO FINALIZADAS - DATOS REVERTIDOS';
GO



