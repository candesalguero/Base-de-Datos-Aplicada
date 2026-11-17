/*
    Test de permisos - rol_administrador (usuario usr_admin)
    Esperado: todas las operaciones (lectura, escritura, ejecucion de SPs) deben tener EXITO.
*/
USE MundialFutbol;
GO

EXECUTE AS USER = 'usr_admin';
GO

-- Lectura
BEGIN TRY
    SELECT TOP 1 id FROM deportivo.Jugador;
    PRINT 'OK - SELECT deportivo.Jugador';
END TRY
BEGIN CATCH
    PRINT 'FALLO - SELECT deportivo.Jugador: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura
BEGIN TRY
    INSERT INTO general.Pais (id, nombre, ISO2, huso_horario, id_confederacion)
    VALUES (9999, 'Pais Test', 'TT', 'UTC+0', 1);
    DELETE FROM general.Pais WHERE id = 9999;
    PRINT 'OK - INSERT/DELETE general.Pais';
END TRY
BEGIN CATCH
    PRINT 'FALLO - INSERT/DELETE general.Pais: ' + ERROR_MESSAGE();
END CATCH
GO

-- Ejecucion de SP de reporte
BEGIN TRY
    EXEC deportivo.usp_ReporteResultadosEncuentros;
    PRINT 'OK - EXEC usp_ReporteResultadosEncuentros';
END TRY
BEGIN CATCH
    PRINT 'FALLO - EXEC usp_ReporteResultadosEncuentros: ' + ERROR_MESSAGE();
END CATCH
GO

REVERT;
GO