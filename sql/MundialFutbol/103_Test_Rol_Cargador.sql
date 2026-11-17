/*
    Test de permisos - rol_cargador_resultados (usuario usr_cargador)
    Esperado: puede leer referencias e insertar en tablas de partido; NO puede escribir en publicidad.
*/
USE MundialFutbol;
GO

EXECUTE AS USER = 'usr_cargador';
GO

-- Lectura permitida
BEGIN TRY
    SELECT TOP 1 id FROM deportivo.Partido;
    PRINT 'OK - SELECT deportivo.Partido';
END TRY
BEGIN CATCH
    PRINT 'FALLO - SELECT deportivo.Partido: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura permitida en Partido
BEGIN TRY
    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
    VALUES (1, 1, 11, 12, '2026-06-01 10:00:00', '2026-06-01 13:00:00', 0, 0, 1000);
    DELETE FROM deportivo.Partido WHERE fecha_hora_local = '2026-06-01 10:00:00';
    PRINT 'OK - INSERT/DELETE deportivo.Partido';
END TRY
BEGIN CATCH
    PRINT 'FALLO - INSERT/DELETE deportivo.Partido: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura NO permitida en publicidad
BEGIN TRY
    INSERT INTO publicidad.Anunciante (id_pais_origen, tax_id, nombre_empresa)
    VALUES (1, 'TEST-TAX', 'Empresa Test');
    PRINT 'ERROR - INSERT publicidad.Anunciante debio fallar pero tuvo exito';
END TRY
BEGIN CATCH
    PRINT 'OK - INSERT publicidad.Anunciante bloqueado: ' + ERROR_MESSAGE();
END CATCH
GO

REVERT;
GO