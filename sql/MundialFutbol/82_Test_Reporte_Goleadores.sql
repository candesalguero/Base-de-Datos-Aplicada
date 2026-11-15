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
    Probar el reporte de goleadores por selección,
    fase y torneo.

    Resultado esperado:
    El procedimiento debe devolver tres conjuntos de resultados:
    1. goleadores ordenados dentro de cada selección;
    2. goleadores ordenados dentro de cada fase;
    3. tabla general de goleadores del torneo.
*/

USE MundialFutbol;
GO


EXEC deportivo.usp_ReporteGoleadores;

GO