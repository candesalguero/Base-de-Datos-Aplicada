/*
    Universidad: Universidad Nacional de La Matanza
    Materia: Bases de Datos Aplicada
    Integrantes:
        - Salguero, Candela
        - Ocaranza, Lucila
        - Dimattia Damm, Malena
        - Fuentes, Martina Alejandra

    Fecha: Octubre 2026

    Objetivo:
    Crear la tabla staging utilizada para recibir los datos crudos
    provenientes del archivo matches.csv antes de su validación,
    transformación e importación a las tablas definitivas.
*/

USE MundialFutbol;
GO


/* ============================================================
   STAGING DE PARTIDOS CSV
   ============================================================ */

IF NOT EXISTS (
    SELECT 1
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = 'integracion'
      AND TABLE_NAME = 'StagingPartidoCSV'
)
BEGIN

    CREATE TABLE integracion.StagingPartidoCSV
    (
        key_id                          varchar(100) NULL,
        tournament_id                   varchar(100) NULL,
        tournament_name                 nvarchar(200) NULL,
        match_id                        varchar(100) NULL,
        match_name                      nvarchar(200) NULL,
        stage_name                      nvarchar(100) NULL,
        group_name                      nvarchar(100) NULL,
        group_stage                     varchar(20) NULL,
        knockout_stage                  varchar(20) NULL,
        replayed                        varchar(20) NULL,
        replay                          varchar(100) NULL,
        match_date                      varchar(50) NULL,
        match_time                      varchar(50) NULL,
        stadium_id                      varchar(100) NULL,
        stadium_name                    nvarchar(200) NULL,
        city_name                       nvarchar(150) NULL,
        country_name                    nvarchar(150) NULL,
        home_team_id                    varchar(100) NULL,
        home_team_name                  nvarchar(150) NULL,
        home_team_code                  varchar(20) NULL,
        away_team_id                    varchar(100) NULL,
        away_team_name                  nvarchar(150) NULL,
        away_team_code                  varchar(20) NULL,
        score                           varchar(50) NULL,
        home_team_score                 varchar(20) NULL,
        away_team_score                 varchar(20) NULL,
        home_team_score_margin          varchar(20) NULL,
        away_team_score_margin          varchar(20) NULL,
        extra_time                      varchar(20) NULL,
        penalty_shootout                varchar(20) NULL,
        score_penalties                 varchar(50) NULL,
        home_team_score_penalties       varchar(20) NULL,
        away_team_score_penalties       varchar(20) NULL,
        result                          varchar(50) NULL,
        home_team_win                   varchar(20) NULL,
        away_team_win                   varchar(20) NULL,
        draw                            varchar(20) NULL
    );

END;
GO