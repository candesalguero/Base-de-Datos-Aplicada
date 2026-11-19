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
    Crear y configurar un usuario de solo lectura para permitir
    la conexión de Metabase con la base MundialFutbol.

    IMPORTANTE:
    Reemplazar la contraseña de ejemplo antes de ejecutar.
*/

USE master;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = 'metabase_user'
)
BEGIN
    CREATE LOGIN metabase_user
    WITH PASSWORD = 'CAMBIAR_PASSWORD';
END;
GO


USE MundialFutbol;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = 'metabase_user'
)
BEGIN
    CREATE USER metabase_user
    FOR LOGIN metabase_user;
END;
GO


ALTER ROLE db_datareader
ADD MEMBER metabase_user;
GO

GRANT EXECUTE TO metabase_user;
GO