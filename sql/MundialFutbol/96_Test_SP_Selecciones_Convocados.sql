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
        Testing de deportivo.usp_Selecciones_Plantel (Entrega 7, salida XML).
        Requiere haber ejecutado antes 70_Carga_Datos_Masiva_Corregido.sql y 86_SP_Selecciones_Convocados.sql.
        Cada prueba indica en comentarios el resultado esperado.
*/

USE MundialFutbol
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 1 - Ejecución y visualización
   Esperado: una única celda con XML (en SSMS, hacer clic en el enlace para verlo).
     <selecciones> con una <seleccion nombre grupo cantidad_convocados> por selección,
     ordenadas por nombre. Dentro, <convocados> con un <convocado> por jugador, ordenado por dorsal,
     con los elementos nombre, posicion_habitual, club_origen y dorsal.
--------------------------------------------------------------------------------------- */
EXEC deportivo.usp_Selecciones_Plantel;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 2 - Cantidad de selecciones
   Esperado: el número devuelto (16 con el seed actual) es igual a la cantidad de nodos
   <seleccion> del XML de la prueba 1.
--------------------------------------------------------------------------------------- */
SELECT COUNT(*) AS selecciones
FROM deportivo.Seleccion;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 3 - Convocados por selección
   Esperado: 16 filas en orden alfabético (el mismo orden del XML), con 23 convocados cada una.
   Cada valor coincide con el atributo cantidad_convocados y con los nodos <convocado> de
   esa selección en el XML.
--------------------------------------------------------------------------------------- */
SELECT s.nombre AS seleccion, COUNT(c.id) AS convocados
FROM deportivo.Seleccion AS s
LEFT JOIN deportivo.Convocatoria AS c ON c.id_seleccion = s.id
GROUP BY s.nombre
ORDER BY s.nombre;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 4 - Orden por dorsal (ejemplo: Argentina)
   Esperado: en el XML, los <convocado> de Argentina aparecen en este mismo orden.
     Primer convocado: dorsal 1 (Franco Armani). Último: dorsal 26 (Nahuel Molina).
--------------------------------------------------------------------------------------- */
SELECT c.dorsal, CONCAT(j.nombre, ' ', j.apellido) AS jugador, c.posicion_habitual, c.club_origen
FROM deportivo.Convocatoria AS c
INNER JOIN deportivo.Jugador AS j ON j.id = c.id_jugador
INNER JOIN deportivo.Seleccion AS s ON s.id = c.id_seleccion
WHERE s.nombre = 'Argentina'
ORDER BY c.dorsal;
GO

/* ---------------------------------------------------------------------------------------
   PRUEBA 5 - Mínimo de 23 convocados por selección (criterio de aceptación del TP)
   Esperado: 0 filas con el seed actual.
--------------------------------------------------------------------------------------- */
SELECT s.nombre AS seleccion, COUNT(c.id) AS convocados
FROM deportivo.Seleccion AS s
LEFT JOIN deportivo.Convocatoria AS c ON c.id_seleccion = s.id
GROUP BY s.nombre
HAVING COUNT(c.id) < 23;
GO
