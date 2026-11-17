/*
    Test de permisos - rol_consulta (usuario usr_consulta)
    Esperado: puede leer y ejecutar reportes; NO puede escribir.
*/
USE MundialFutbol;
GO

EXECUTE AS USER = 'usr_consulta';
GO

-- Lectura permitida
BEGIN TRY
    SELECT TOP 1 id FROM deportivo.Seleccion;
    PRINT 'OK - SELECT deportivo.Seleccion';
END TRY
BEGIN CATCH
    PRINT 'FALLO - SELECT deportivo.Seleccion: ' + ERROR_MESSAGE();
END CATCH
GO

-- Ejecucion de reporte permitida
BEGIN TRY
    EXEC deportivo.usp_ReporteResultadosEncuentros;
    PRINT 'OK - EXEC usp_ReporteResultadosEncuentros';
END TRY
BEGIN CATCH
    PRINT 'FALLO - EXEC usp_ReporteResultadosEncuentros: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura NO permitida
BEGIN TRY
    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
    VALUES (1, 1, 11, 12, '2026-06-03 10:00:00', '2026-06-03 13:00:00', 0, 0, 1000);
    PRINT 'ERROR - INSERT deportivo.Partido debio fallar pero tuvo exito';
END TRY
BEGIN CATCH
    PRINT 'OK - INSERT deportivo.Partido bloqueado: ' + ERROR_MESSAGE();
END CATCH
GO

REVERT;
GO