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
        Entrega 8 - Roles de seguridad implementados mediante Stored Procedures.
        Cada rol se configura a traves de un SP que crea el login/usuario,
        el rol y asigna los permisos granulares.
*/
USE MundialFutbol;
GO

-- ============================================================
-- SP: configurar rol administrador
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_Rol_Administrador_Configurar
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_admin')
        CREATE LOGIN usr_admin WITH PASSWORD = 'Admin_2026_Seguro!';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_admin')
        CREATE USER usr_admin FOR LOGIN usr_admin;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_administrador' AND type = 'R')
        CREATE ROLE rol_administrador;

    ALTER ROLE rol_administrador ADD MEMBER usr_admin;

    GRANT CONTROL ON SCHEMA::deportivo TO rol_administrador;
    GRANT CONTROL ON SCHEMA::general TO rol_administrador;
    GRANT CONTROL ON SCHEMA::arbitraje TO rol_administrador;
    GRANT CONTROL ON SCHEMA::publicidad TO rol_administrador;
    GRANT CONTROL ON SCHEMA::integracion TO rol_administrador;
    GRANT EXECUTE ON SCHEMA::dbo TO rol_administrador;
END
GO

-- ============================================================
-- SP: configurar rol cargador de resultados
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_Rol_Cargador_Configurar
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_cargador')
        CREATE LOGIN usr_cargador WITH PASSWORD = 'Cargador_2026_Seguro!';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_cargador')
        CREATE USER usr_cargador FOR LOGIN usr_cargador;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_cargador_resultados' AND type = 'R')
        CREATE ROLE rol_cargador_resultados;

    ALTER ROLE rol_cargador_resultados ADD MEMBER usr_cargador;

    GRANT SELECT ON SCHEMA::deportivo TO rol_cargador_resultados;
    GRANT SELECT ON SCHEMA::general TO rol_cargador_resultados;
    GRANT SELECT ON SCHEMA::arbitraje TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.Partido TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.Gol TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.Tarjeta TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.Sustitucion TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.VentanaCambio TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.AlineacionPartido TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.AlineacionJugador TO rol_cargador_resultados;
    GRANT INSERT, UPDATE, DELETE ON deportivo.AltaBajaConvocatoria TO rol_cargador_resultados;
    GRANT EXECUTE ON SCHEMA::deportivo TO rol_cargador_resultados;
END
GO

-- ============================================================
-- SP: configurar rol gestor de publicidad
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_Rol_GestorPublicidad_Configurar
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_publicidad')
        CREATE LOGIN usr_publicidad WITH PASSWORD = 'Publicidad_2026_Seguro!';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_publicidad')
        CREATE USER usr_publicidad FOR LOGIN usr_publicidad;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_gestor_publicidad' AND type = 'R')
        CREATE ROLE rol_gestor_publicidad;

    ALTER ROLE rol_gestor_publicidad ADD MEMBER usr_publicidad;

    GRANT SELECT ON SCHEMA::deportivo TO rol_gestor_publicidad;
    GRANT SELECT ON SCHEMA::general TO rol_gestor_publicidad;
    GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::publicidad TO rol_gestor_publicidad;
    GRANT EXECUTE ON SCHEMA::publicidad TO rol_gestor_publicidad;
END
GO

-- ============================================================
-- SP: configurar rol consulta
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_Rol_Consulta_Configurar
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sys.server_principals WHERE name = 'usr_consulta')
        CREATE LOGIN usr_consulta WITH PASSWORD = 'Consulta_2026_Seguro!';

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'usr_consulta')
        CREATE USER usr_consulta FOR LOGIN usr_consulta;

    IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'rol_consulta' AND type = 'R')
        CREATE ROLE rol_consulta;

    ALTER ROLE rol_consulta ADD MEMBER usr_consulta;

    GRANT SELECT ON SCHEMA::deportivo TO rol_consulta;
    GRANT SELECT ON SCHEMA::general TO rol_consulta;
    GRANT SELECT ON SCHEMA::arbitraje TO rol_consulta;
    GRANT SELECT ON SCHEMA::publicidad TO rol_consulta;
    GRANT SELECT ON SCHEMA::integracion TO rol_consulta;
    GRANT EXECUTE ON deportivo.usp_ReporteTarjetasPorSeleccionJugador TO rol_consulta;
    GRANT EXECUTE ON deportivo.usp_ReporteResultadosEncuentros TO rol_consulta;
    GRANT EXECUTE ON publicidad.usp_ReporteOcupacionPublicitaria TO rol_consulta;
END
GO

-- ============================================================
-- SP maestro: configura todos los roles
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.usp_ConfigurarRolesSeguridad
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.usp_Rol_Administrador_Configurar;
    EXEC dbo.usp_Rol_Cargador_Configurar;
    EXEC dbo.usp_Rol_GestorPublicidad_Configurar;
    EXEC dbo.usp_Rol_Consulta_Configurar;
    PRINT 'OK - Roles de seguridad configurados.';
END
GO

-- Ejecutar la configuracion
EXEC dbo.usp_ConfigurarRolesSeguridad;
GO