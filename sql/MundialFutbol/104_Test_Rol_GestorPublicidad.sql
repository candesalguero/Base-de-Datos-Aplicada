/*
    Test de permisos - rol_gestor_publicidad (usuario usr_publicidad)
    Esperado: puede leer referencias y CRUD en publicidad; NO puede escribir en deportivo.Partido.
*/
USE MundialFutbol;
GO

EXECUTE AS USER = 'usr_publicidad';
GO

-- Lectura permitida
BEGIN TRY
    SELECT TOP 1 id FROM publicidad.Anunciante;
    PRINT 'OK - SELECT publicidad.Anunciante';
END TRY
BEGIN CATCH
    PRINT 'FALLO - SELECT publicidad.Anunciante: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura permitida en publicidad
BEGIN TRY
    INSERT INTO publicidad.Anunciante (id_pais_origen, tax_id, nombre_empresa)
    VALUES (1, 'TEST-TAX-PUB', 'Empresa Pub Test');
    DELETE FROM publicidad.Anunciante WHERE tax_id = 'TEST-TAX-PUB';
    PRINT 'OK - INSERT/DELETE publicidad.Anunciante';
END TRY
BEGIN CATCH
    PRINT 'FALLO - INSERT/DELETE publicidad.Anunciante: ' + ERROR_MESSAGE();
END CATCH
GO

-- Escritura NO permitida en deportivo.Partido
BEGIN TRY
    INSERT INTO deportivo.Partido (id_sede, id_fase, id_seleccion_local, id_seleccion_visitante, fecha_hora_local, fecha_hora_utc, goles_local, goles_visitante, asistencia_publico)
    VALUES (1, 1, 11, 12, '2026-06-02 10:00:00', '2026-06-02 13:00:00', 0, 0, 1000);
    PRINT 'ERROR - INSERT deportivo.Partido debio fallar pero tuvo exito';
END TRY
BEGIN CATCH
    PRINT 'OK - INSERT deportivo.Partido bloqueado: ' + ERROR_MESSAGE();
END CATCH
GO

REVERT;
GO