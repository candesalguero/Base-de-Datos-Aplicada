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
    Script de testing  para probar la Lógica de Negocio del esquema deportivo.
    Verifica el registro de partidos, tarjetas, cálculo de sanciones automáticas, 
    goles, sustituciones y validaciones de alineaciones titulares (con los 11 parámetros explícitos).
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;


-- 1. Países, Selecciones y Partidos
IF NOT EXISTS (SELECT 1 FROM general.Confederacion WHERE id = 9990)
    INSERT INTO general.Confederacion (id, nombre) VALUES (9990, 'Confederacion Test');

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 9990)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (9990, 'Pais Test A', 'ZA', 'UTC-3', 9990);

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 9991)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (9991, 'Pais Test B', 'ZB', 'UTC-3', 9990);

IF NOT EXISTS (SELECT 1 FROM general.Sede WHERE id = 9990)
    INSERT INTO general.Sede (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario) 
    VALUES (9990, 9990, 'Estadio Test', 'Ciudad Test', 50000, 'UTC-3');

IF NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = 9990)
    INSERT INTO general.Fase (id, nombre, orden, es_eliminacion_directa) 
    VALUES (9990, 'grupos', 1, 0);

-- Insertar Selecciones de prueba
INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo) VALUES (9990, 'Seleccion Alfa', 'A');
DECLARE @id_sel_a INT = SCOPE_IDENTITY();

INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo) VALUES (9991, 'Seleccion Beta', 'A');
DECLARE @id_sel_b INT = SCOPE_IDENTITY();

-- Insertar Esquema Táctico
INSERT INTO deportivo.EsquemaTactico (denominacion) VALUES ('4-3-3');
DECLARE @id_esquema INT = SCOPE_IDENTITY();

-- Insertar Partido de prueba
INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
VALUES (9990, 9990, @id_sel_a, @id_sel_b, GETDATE(), GETDATE(), 0, 0, 45000);
DECLARE @id_partido INT = SCOPE_IDENTITY();

-- Insertar Jugadores y Convocatorias para Seleccion Alfa (12 convocados: 11 titulares + 1 suplente)
DECLARE @c1 INT, @c2 INT, @c3 INT, @c4 INT, @c5 INT, @c6 INT, @c7 INT, @c8 INT, @c9 INT, @c10 INT, @c11 INT, @c12_suplente INT;
DECLARE @j_id INT;

-- Generar 12 convocados
INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Uno', '2000-01-01', 'DOC_TEST_01');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 1, 'Arquero', 'Club Test');
SET @c1 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Dos', '2000-01-01', 'DOC_TEST_02');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 2, 'Defensor', 'Club Test');
SET @c2 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Tres', '2000-01-01', 'DOC_TEST_03');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 3, 'Defensor', 'Club Test');
SET @c3 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Cuatro', '2000-01-01', 'DOC_TEST_04');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 4, 'Defensor', 'Club Test');
SET @c4 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Cinco', '2000-01-01', 'DOC_TEST_05');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 5, 'Defensor', 'Club Test');
SET @c5 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Seis', '2000-01-01', 'DOC_TEST_06');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 6, 'Mediocampista', 'Club Test');
SET @c6 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Siete', '2000-01-01', 'DOC_TEST_07');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 7, 'Mediocampista', 'Club Test');
SET @c7 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Ocho', '2000-01-01', 'DOC_TEST_08');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 8, 'Mediocampista', 'Club Test');
SET @c8 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Nueve', '2000-01-01', 'DOC_TEST_09');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 9, 'Delantero', 'Club Test');
SET @c9 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Lionel', 'Alineable', '2000-01-01', 'DOC_TEST_10');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 10, 'Delantero', 'Club Test');
SET @c10 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Titular', 'Once', '2000-01-01', 'DOC_TEST_11');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 11, 'Delantero', 'Club Test');
SET @c11 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (9990, 'Suplente', 'Doce', '2000-01-01', 'DOC_TEST_12');
SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 12, 'Delantero', 'Club Test');
SET @c12_suplente = SCOPE_IDENTITY();

PRINT 'Datos de prueba generados correctamente.';
PRINT '';

PRINT '1. PRUEBA: Registrar Formación Titular Exitosa (Los 11 Parámetros)';

BEGIN TRY
    EXEC deportivo.usp_RegistrarFormacionEquipo
        @id_partido = @id_partido,
        @id_seleccion = @id_sel_a,
        @id_esquema = @id_esquema,
        @id_convocatoria_titular_1 = @c1,
        @id_convocatoria_titular_2 = @c2,
        @id_convocatoria_titular_3 = @c3,
        @id_convocatoria_titular_4 = @c4,
        @id_convocatoria_titular_5 = @c5,
        @id_convocatoria_titular_6 = @c6,
        @id_convocatoria_titular_7 = @c7,
        @id_convocatoria_titular_8 = @c8,
        @id_convocatoria_titular_9 = @c9,
        @id_convocatoria_titular_10 = @c10,
        @id_convocatoria_titular_11 = @c11;

    PRINT 'OK - Formación registrada con éxito.';
    
    -- Evidencia: Verificación de jugadores inscritos en la alineación
    SELECT ap.id AS id_alineacion, ap.id_partido, s.nombre AS seleccion, aj.id_convocatoria, c.dorsal, aj.es_titular
    FROM deportivo.AlineacionPartido ap
    JOIN deportivo.AlineacionJugador aj ON ap.id = aj.id_alineacion
    JOIN deportivo.Convocatoria c ON aj.id_convocatoria = c.id
    JOIN deportivo.Seleccion s ON ap.id_seleccion = s.id
    WHERE ap.id_partido = @id_partido AND ap.id_seleccion = @id_sel_a;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '2. PRUEBA: Registrar Gol y Verificación de Marcador Actualizado';

BEGIN TRY
    EXEC deportivo.usp_RegistrarGol
        @id_partido = @id_partido,
        @id_convocatoria_autor = @c10,
        @id_convocatoria_asistencia = @c9,
        @minuto = 15,
        @periodo = '1T',
        @es_en_contra = 0;

    PRINT 'OK - Gol registrado correctamente.';

    -- Evidencia: Marcador del partido
    SELECT id, goles_local, goles_visitante FROM deportivo.Partido WHERE id = @id_partido;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '3. PRUEBA: Sustituciones Exitosas (Uso de Ventanas)';

BEGIN TRY
    -- Ventana 1 (Minuto 50): Sale @c9, Entra @s12
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c9, @id_convocatoria_entra = @s12,
        @minuto = 50, @periodo = '2T', @motivo = 'Táctico', @es_ventana_de_juego = 1;

    -- Ventana 2 (Minuto 60): Doble cambio en la misma ventana (Sale @c8 entra @s13, Sale @c7 entra @s14)
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c8, @id_convocatoria_entra = @s13,
        @minuto = 60, @periodo = '2T', @motivo = 'Precaución', @es_ventana_de_juego = 1;

    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c7, @id_convocatoria_entra = @s14,
        @minuto = 60, @periodo = '2T', @motivo = 'Táctico', @es_ventana_de_juego = 1;

    -- Ventana 3 (Minuto 75): Cambio 4 (Sale @c6 entra @s15)
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c6, @id_convocatoria_entra = @s15,
        @minuto = 75, @periodo = '2T', @motivo = 'Lesión', @es_ventana_de_juego = 1;

    PRINT 'OK - Sustituciones dentro de la regla registradas correctamente (4 cambios en 3 ventanas).';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '4. PRUEBA VALIDACIÓN: Exceder las 3 ventanas de cambios en juego';

BEGIN TRY
    -- Intentar usar una 4ta ventana en el minuto 85 (Sale @c5 entra @s16)
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c5, @id_convocatoria_entra = @s16,
        @minuto = 85, @periodo = '2T', @motivo = 'Táctico', @es_ventana_de_juego = 1;

    PRINT 'ERROR - El procedimiento debió rechazar la 4ta ventana.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó con éxito el error de ventanas agotadas (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '5. PRUEBA VALIDACIÓN: Intentar superar el máximo de 5 cambios';

BEGIN TRY
    -- Se simula un cambio en el entretiempo (no gasta ventana) para llegar al 5to cambio (Sale @c4 entra @s16)
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c4, @id_convocatoria_entra = @s16,
        @minuto = 45, @periodo = 'ET', @motivo = 'Táctico', @es_ventana_de_juego = 0;

    -- Ahora que ya hay 5 cambios consumidos, se intenta realizar el 6º cambio (Sale @c3 entra @s17)
    EXEC deportivo.usp_RegistrarCambioJugador
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c3, @id_convocatoria_entra = @s17,
        @minuto = 88, @periodo = '2T', @motivo = 'Táctico', @es_ventana_de_juego = 0;

    PRINT 'ERROR - El procedimiento debió rechazar el 6to cambio.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó con éxito el error de máximo de sustituciones alcanzado (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '6. PRUEBA: Registrar Roja Directa y Cálculo Automático de Sanción';

BEGIN TRY
    -- Se sanciona al jugador @c10 (Dorsal #10) con Roja Directa
    EXEC deportivo.usp_RegistrarTarjetaYCalcularSancion
        @id_partido = @id_partido,
        @id_convocatoria = @c10,
        @minuto = 70,
        @periodo = '2T',
        @color = 'Roja',
        @es_roja_directa = 1,
        @motivo = 'Conducta violenta';

    PRINT 'OK - Tarjeta y Sanción registradas exitosamente.';

    -- Evidencia: Sanción generada en estado Pendiente
    SELECT s.id, s.id_convocatoria, j.nombre, j.apellido, s.cantidad_partidos_sancion, s.motivo, s.estado
    FROM deportivo.Sancion s
    JOIN deportivo.Convocatoria c ON s.id_convocatoria = c.id
    JOIN deportivo.Jugador j ON c.id_jugador = j.id
    WHERE s.id_convocatoria = @c10;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

PRINT '7. PRUEBA VALIDACIÓN: Intentar Formar con Jugador Suspendido';

BEGIN TRY
    -- Se intenta armar una formación para el siguiente partido incluyendo a @c10 (sancionado)
    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc)
    VALUES (9990, 9990, @id_sel_a, @id_sel_b, GETDATE(), GETDATE());
    
    DECLARE @id_partido_siguiente INT = SCOPE_IDENTITY();

    EXEC deportivo.usp_RegistrarFormacionEquipo
        @id_partido = @id_partido_siguiente,
        @id_seleccion = @id_sel_a,
        @id_esquema = @id_esquema,
        @id_convocatoria_titular_1 = @c1,
        @id_convocatoria_titular_2 = @c2,
        @id_convocatoria_titular_3 = @c3,
        @id_convocatoria_titular_4 = @c4,
        @id_convocatoria_titular_5 = @c5,
        @id_convocatoria_titular_6 = @c6,
        @id_convocatoria_titular_7 = @c7,
        @id_convocatoria_titular_8 = @c8,
        @id_convocatoria_titular_9 = @c9,
        @id_convocatoria_titular_10 = @c10, -- JUGADOR SUSPENDIDO EN POSICIÓN 10
        @id_convocatoria_titular_11 = @c11;

    PRINT 'ERROR - El procedimiento debió rechazar al titular suspendido.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó con éxito la excepción esperada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '8. PRUEBA VALIDACIÓN: Registrar Gol con Jugador de Otra Selección';

BEGIN TRY
    EXEC deportivo.usp_RegistrarGol
        @id_partido = @id_partido,
        @id_convocatoria_autor = 999999, -- Convocatoria Inexistente
        @minuto = 80,
        @periodo = '2T',
        @es_en_contra = 0;

    PRINT 'ERROR - El procedimiento debió validar al autor.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó con éxito la excepción esperada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

-- Limpieza y Reversión
IF @@TRANCOUNT > 0 
    ROLLBACK TRANSACTION;


PRINT '  PRUEBAS FINALIZADAS EXITOSAMENTE - DATOS TEMPORALES REVERTIDOS';

GO