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
    Script de testing integral para probar la Lógica de Negocio del esquema deportivo.
    Verifica el registro de partidos en La Bombonera, reemplazos por lesión (Alta/Baja), 
    tarjetas, cálculo de sanciones automáticas, goles, sustituciones (ventanas y entretiempo) 
    y validaciones de alineaciones titulares (con los 11 parámetros explícitos).
*/

USE MundialFutbol;
GO

SET NOCOUNT ON;
BEGIN TRANSACTION;

PRINT '  1. Datos Generales';


-- 1. Confederación, Países y Fase del Torneo
IF NOT EXISTS (SELECT 1 FROM general.Confederacion WHERE id = 1990)
    INSERT INTO general.Confederacion (id, nombre) VALUES (1990, 'AFA - Asoc. del Fútbol Argentino');

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 1990)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (1990, 'Argentina', 'AR', 'UTC-3', 1990);

IF NOT EXISTS (SELECT 1 FROM general.Pais WHERE id = 1991)
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion) 
    VALUES (1991, 'Inglaterra', 'EN', 'UTC+0', 1990);

IF NOT EXISTS (SELECT 1 FROM general.Fase WHERE id = 1990)
    INSERT INTO general.Fase (id, nombre, orden, es_eliminacion_directa) 
    VALUES (1990, 'grupos', 1, 0);
--sede
DECLARE @id_sede_test INT;
IF NOT EXISTS (SELECT 1 FROM general.Sede WHERE nombre_estadio = 'Estadio Alberto J. Armando (La Bombonera)')
BEGIN
    INSERT INTO general.Sede (id, id_pais, nombre_estadio, ciudad, capacidad, huso_horario) 
    VALUES (1990, 1990, 'Estadio Alberto J. Armando (La Bombonera)', 'Buenos Aires', 54000, 'UTC-3');
    SET @id_sede_test = 1990;
END
ELSE
BEGIN
    SELECT TOP 1 @id_sede_test = id FROM general.Sede WHERE nombre_estadio = 'Estadio Alberto J. Armando (La Bombonera)';
END

-- 2. Selecciones y Esquema Táctico
INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo) VALUES (1990, 'Argentina (Boca Edition)', 'A');
DECLARE @id_sel_a INT = SCOPE_IDENTITY();

INSERT INTO deportivo.Seleccion (id_pais, nombre, grupo) VALUES (1991, 'Inglaterra', 'A');
DECLARE @id_sel_b INT = SCOPE_IDENTITY();

INSERT INTO deportivo.EsquemaTactico (denominacion) VALUES ('4-3-1-2');
DECLARE @id_esquema INT = SCOPE_IDENTITY();

-- Jugador Libre para Alta/Baja de Convocatoria por Lesión
INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) 
VALUES (1990, 'Luca', 'Langoni', '2002-02-09', 'DOC_BOCA_LANGONI');
DECLARE @j_lesion_entra INT = SCOPE_IDENTITY();

-- 3. Creación de Jugadores Xeneizes y Convocatorias (11 Titulares + 6 Suplentes)
DECLARE @c1 INT, @c2 INT, @c3 INT, @c4 INT, @c5 INT, @c6 INT, @c7 INT, @c8 INT, @c9 INT, @c10 INT, @c11 INT;
DECLARE @s12 INT, @s13 INT, @s14 INT, @s15 INT, @s16 INT, @s17 INT;
DECLARE @j_id INT;

-- Titulares (@c1 a @c11)
INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Roberto', 'Abbondanzieri', '1972-08-19', 'DOC_BOCA_01'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 1, 'Arquero', 'Boca Juniors'); SET @c1 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Hugo', 'Ibarra', '1974-04-01', 'DOC_BOCA_02'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 4, 'Defensor', 'Boca Juniors'); SET @c2 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Rolando', 'Schiavi', '1973-01-18', 'DOC_BOCA_03'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 2, 'Defensor', 'Boca Juniors'); SET @c3 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Walter', 'Samuel', '1978-03-23', 'DOC_BOCA_04'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 6, 'Defensor', 'Boca Juniors'); SET @c4 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Clemente', 'Rodriguez', '1981-07-31', 'DOC_BOCA_05'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 3, 'Defensor', 'Boca Juniors'); SET @c5 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Sebastián', 'Battaglia', '1980-11-08', 'DOC_BOCA_06'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 5, 'Mediocampista', 'Boca Juniors'); SET @c6 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Leandro', 'Paredes', '1994-06-29', 'DOC_BOCA_07'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 8, 'Mediocampista', 'Boca Juniors'); SET @c7 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Alexis', 'Mac Allister', '1998-12-24', 'DOC_BOCA_08'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 7, 'Mediocampista', 'Boca Juniors'); SET @c8 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Martín', 'Palermo', '1973-11-07', 'DOC_BOCA_09'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 9, 'Delantero', 'Boca Juniors'); SET @c9 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Juan Roman', 'Riquelme', '1978-06-24', 'DOC_BOCA_10'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 10, 'Mediocampista', 'Boca Juniors'); SET @c10 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Carlos', 'Tevez', '1984-02-05', 'DOC_BOCA_11'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 11, 'Delantero', 'Boca Juniors'); SET @c11 = SCOPE_IDENTITY();

-- Suplentes (@s12 a @s17)
INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Sergio', 'Romero', '1987-02-22', 'DOC_BOCA_12'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 12, 'Arquero', 'Boca Juniors'); SET @s12 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Cristian', 'Medina', '2002-06-01', 'DOC_BOCA_13'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 13, 'Mediocampista', 'Boca Juniors'); SET @s13 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Nicolás', 'Valentini', '2001-04-06', 'DOC_BOCA_14'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 14, 'Defensor', 'Boca Juniors'); SET @s14 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Exequiel', 'Zeballos', '2002-04-24', 'DOC_BOCA_15'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 15, 'Delantero', 'Boca Juniors'); SET @s15 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Alan', 'Varela', '2001-07-04', 'DOC_BOCA_16'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 16, 'Mediocampista', 'Boca Juniors'); SET @s16 = SCOPE_IDENTITY();

INSERT INTO deportivo.Jugador (id_pais_nacimiento, nombre, apellido, fecha_nacimiento, documento_identidad) VALUES (1990, 'Mateo', 'Retegui', '1999-04-29', 'DOC_BOCA_17'); SET @j_id = SCOPE_IDENTITY();
INSERT INTO deportivo.Convocatoria (id_jugador, id_seleccion, dorsal, posicion_habitual, club_origen) VALUES (@j_id, @id_sel_a, 17, 'Delantero', 'Boca Juniors'); SET @s17 = SCOPE_IDENTITY();

PRINT 'OK - Datos de prueba inicializados correctamente .';
PRINT '';


PRINT ' 2. Remplazo por lesion previo al debut.';

BEGIN TRY
    -- Se reemplaza a Retegui (@s17) por Luca Langoni antes de que empiece el partido debut
    EXEC deportivo.usp_ReemplazarConvocadoPorLesion
        @id_convocatoria_sale = @s17,
        @id_jugador_nuevo = @j_lesion_entra,
        @motivo = 'Esguince severo en practica previa';

    PRINT 'OK - Reemplazo por lesión procesado exitosamente.';

    -- Evidencia: Verificación en AltaBajaConvocatoria y actualización en Convocatoria
    SELECT 
        ab.id AS id_registro, 
        ab.id_convocatoria_sale, 
        j_entra.nombre + ' ' + j_entra.apellido AS jugador_ingresante,
        ab.motivo, 
        c.dorsal,
        c.club_origen
    FROM deportivo.AltaBajaConvocatoria ab
    JOIN deportivo.Jugador j_entra ON ab.id_jugador_entra = j_entra.id
    JOIN deportivo.Convocatoria c ON ab.id_convocatoria_sale = c.id
    WHERE ab.id_convocatoria_sale = @s17;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';

-- 4. Partido Principal de Prueba
INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
VALUES (@id_sede_test, 1990, @id_sel_a, @id_sel_b, GETDATE(), GETDATE(), 0, 0, 54000);
DECLARE @id_partido INT = SCOPE_IDENTITY();

PRINT '  3. Registrar Formación Titular (Los 11 Parámetros)';

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
    
    
    SELECT ap.id AS id_alineacion, ap.id_partido, s.nombre AS seleccion, c.dorsal, j.nombre + ' ' + j.apellido AS titular, aj.es_titular
    FROM deportivo.AlineacionPartido ap
    JOIN deportivo.AlineacionJugador aj ON ap.id = aj.id_alineacion
    JOIN deportivo.Convocatoria c ON aj.id_convocatoria = c.id
    JOIN deportivo.Jugador j ON c.id_jugador = j.id
    JOIN deportivo.Seleccion s ON ap.id_seleccion = s.id
    WHERE ap.id_partido = @id_partido AND ap.id_seleccion = @id_sel_a;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';



PRINT '  4.  Intentar Reemplazo por Lesión Post-Debut';

SAVE TRANSACTION Test_LesionPostDebut;
BEGIN TRY
    -- Como la Selección ya jugó/debutó el partido arriba, debe ser rechazado
    EXEC deportivo.usp_ReemplazarConvocadoPorLesion
        @id_convocatoria_sale = @c11,
        @id_jugador_nuevo = @j_lesion_entra,
        @motivo = 'Lesión producida post partido debut';

    PRINT 'ERROR - El procedimiento debió rechazar el reemplazo post-debut.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION Test_LesionPostDebut;
    PRINT 'OK - Se capturó con éxito el error de reemplazo post-debut (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  5.  Registrar Gol y Verificación de Marcador Actualizado';

BEGIN TRY

    EXEC deportivo.usp_RegistrarGol
        @id_partido = @id_partido,
        @id_convocatoria_autor = @c10,
        @id_convocatoria_asistencia = @c9,
        @minuto = 38,
        @periodo = '1T',
        @es_en_contra = 0;

    PRINT 'OK - Gol registrado correctamente.';

    --  Marcador del partido
    SELECT id AS id_partido, goles_local AS Argentina, goles_visitante AS Inglaterra FROM deportivo.Partido WHERE id = @id_partido;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';



PRINT '  6. Sustituciones Exitosas (Uso de Ventanas)';

BEGIN TRY
    -- Ventana 1 (Minuto 55): Entra Zeballos (@s15) por Palermo (@c9)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c9, @id_convocatoria_entra = @s15,
        @minuto = 55, @periodo = '2T', @motivo_cambio = 'Táctico';

    -- Ventana 2 (Minuto 68): Doble cambio en la misma ventana (Medina y Varela)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c8, @id_convocatoria_entra = @s13,
        @minuto = 68, @periodo = '2T', @motivo_cambio = 'Precaución';

    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c6, @id_convocatoria_entra = @s16,
        @minuto = 68, @periodo = '2T', @motivo_cambio = 'Táctico';

    -- Ventana 3 (Minuto 80): Cambio 4 (Valentini por Samuel)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c4, @id_convocatoria_entra = @s14,
        @minuto = 80, @periodo = '2T', @motivo_cambio = 'Lesión';

    PRINT 'OK - Sustituciones reglamentarias registradas correctamente (4 cambios en 3 ventanas).';

    -- Evidencia: Historial de Cambios y Ventanas creadas
    SELECT v.numero_ventana, v.minuto, v.periodo, 
           js.nombre + ' ' + js.apellido AS sale, 
           je.nombre + ' ' + je.apellido AS entra, 
           s.motivo_cambio
    FROM deportivo.VentanaCambio v
    JOIN deportivo.Sustitucion s ON v.id = s.id_ventana
    JOIN deportivo.Convocatoria cs ON s.id_convocatoria_sale = cs.id
    JOIN deportivo.Jugador js ON cs.id_jugador = js.id
    JOIN deportivo.Convocatoria ce ON s.id_convocatoria_entra = ce.id
    JOIN deportivo.Jugador je ON ce.id_jugador = je.id
    WHERE v.id_partido = @id_partido AND v.id_seleccion = @id_sel_a;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  7. PRUEBA VALIDACIÓN: Exceder las 3 ventanas de cambios en juego';

SAVE TRANSACTION Test_Ventanas;
BEGIN TRY
    -- Intentar usar una 4ta ventana en el minuto 85 (Sale Clemente @c5, entra Langoni @s17)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, 
        @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c5, 
        @id_convocatoria_entra = @s17,
        @minuto = 85, 
        @periodo = '2T', 
        @motivo_cambio = 'Táctico';

    PRINT 'ERROR - El procedimiento debió rechazar la 4ta ventana.';
END TRY
BEGIN CATCH
    -- Revertimos únicamente la prueba 7 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION Test_Ventanas; 
    PRINT 'OK - Se capturó con éxito el error de ventanas agotadas (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  8. PRUEBA VALIDACIÓN: Intentar superar el máximo de 5 cambios';

SAVE TRANSACTION Test_MaxCambios;
BEGIN TRY
    -- Cambio en entretiempo (ET no consume ventana de juego, pero suma al límite de 5)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, 
        @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c5, 
        @id_convocatoria_entra = @s12,
        @minuto = 45, 
        @periodo = 'ET', 
        @motivo_cambio = 'Táctico';

    -- Intento de 6to cambio (Debiera fallar)
    EXEC deportivo.usp_RegistrarSustitucion 
        @id_partido = @id_partido, 
        @id_seleccion = @id_sel_a,
        @id_convocatoria_sale = @c3, 
        @id_convocatoria_entra = @s17,
        @minuto = 88, 
        @periodo = '2T', 
        @motivo_cambio = 'Táctico';

    PRINT 'ERROR - El procedimiento debió rechazar el 6to cambio.';
END TRY
BEGIN CATCH
    -- Revertimos ÚNICAMENTE la prueba 8
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION Test_MaxCambios; 
    PRINT 'OK - Se capturó con éxito el error de máximo de sustituciones alcanzado (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';



PRINT '  9.  Registrar Roja Directa a Schiavi y Cálculo de Sanción';

BEGIN TRY
    -- Se sanciona al Flaco Schiavi (@c3) con Roja Directa por corte táctico
    EXEC deportivo.usp_RegistrarTarjetaYCalcularSancion
        @id_partido = @id_partido,
        @id_convocatoria = @c3,
        @minuto = 85,
        @periodo = '2T',
        @color = 'Roja',
        @es_roja_directa = 1,
        @motivo = 'Falta grave como último recurso';

    PRINT 'OK - Tarjeta Roja y Sanción de 2 partidos generadas exitosamente.';

    -- Evidencia: Sanción generada en estado Pendiente
    SELECT s.id, j.nombre + ' ' + j.apellido AS expulsado, c.club_origen, s.cantidad_partidos_sancion, s.motivo, s.estado
    FROM deportivo.Sancion s
    JOIN deportivo.Convocatoria c ON s.id_convocatoria = c.id
    JOIN deportivo.Jugador j ON c.id_jugador = j.id
    WHERE s.id_convocatoria = @c3;
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH;
PRINT '';



PRINT '  10.  Intentar Formar con Jugador Suspendido';

SAVE TRANSACTION Test_Formacion;
BEGIN TRY
    -- Insertar un SEGUNDO partido para la fecha siguiente
    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc)
    VALUES (@id_sede_test, 1990, @id_sel_a, @id_sel_b, GETDATE(), GETDATE());
    
    DECLARE @id_partido_siguiente INT = SCOPE_IDENTITY();

    -- Intentar alinear al Flaco Schiavi (@c3) que fue expulsado en la prueba 9
    EXEC deportivo.usp_RegistrarFormacionEquipo
        @id_partido = @id_partido_siguiente,
        @id_seleccion = @id_sel_a,
        @id_esquema = @id_esquema,
        @id_convocatoria_titular_1 = @c1,
        @id_convocatoria_titular_2 = @c2,
        @id_convocatoria_titular_3 = @c3, -- JUGADOR SUSPENDIDO (SCHIAVI)
        @id_convocatoria_titular_4 = @c4,
        @id_convocatoria_titular_5 = @c5,
        @id_convocatoria_titular_6 = @c6,
        @id_convocatoria_titular_7 = @c7,
        @id_convocatoria_titular_8 = @c8,
        @id_convocatoria_titular_9 = @c9,
        @id_convocatoria_titular_10 = @c10,
        @id_convocatoria_titular_11 = @c11;

    PRINT 'ERROR - El procedimiento debió rechazar al titular suspendido.';
END TRY
BEGIN CATCH
    -- Revertimos ÚNICAMENTE la prueba 10
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION Test_Formacion;
    PRINT 'OK - Se capturó con éxito la excepción esperada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';


PRINT '  11. Registrar Gol con Jugador Inexistente';

BEGIN TRY
    EXEC deportivo.usp_RegistrarGol
        @id_partido = @id_partido,
        @id_convocatoria_autor = 999999, -- Convocatoria Inexistente
        @minuto = 89,
        @periodo = '2T',
        @es_en_contra = 0;

    PRINT 'ERROR - El procedimiento debió validar al autor.';
END TRY
BEGIN CATCH
    PRINT 'OK - Se capturó con éxito la excepción esperada (THROW 50000):';
    PRINT ERROR_MESSAGE();
END CATCH;
PRINT '';

-- Limpieza y Reversión Global al finalizar todo el archivo de pruebas
IF @@TRANCOUNT > 0 
    ROLLBACK TRANSACTION;

PRINT ' Prueba Finalizada';

GO