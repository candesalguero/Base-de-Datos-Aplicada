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
        Entrega 7 -Reporte Selecciones y plantillas: listado de selecciones con un vector
        anidado de convocados (nombre, posición, club, dorsal). La salida es XML.

	Estructura del XML:
        <selecciones>
          <seleccion nombre="..." grupo="..." cantidad_convocados="23">
            <convocados>
              <convocado>
                <nombre>...</nombre><posicion_habitual>...</posicion_habitual>
                <club_origen>...</club_origen><dorsal>..</dorsal>
              </convocado> ...
            </convocados>
          </seleccion> ...
        </selecciones>

    Las selecciones salen ordenadas por nombre y los convocados por dorsal. Una selección
    sin convocados figura con cantidad_convocados="0" y sin el nodo <convocados>.
*/
USE MundialFutbol
go

CREATE OR ALTER PROCEDURE deportivo.usp_Selecciones_Plantel
AS
BEGIN
	SET Nocount on;
	SELECT
	s.nombre as [nombre],
	s.grupo as [grupo],
	(select count(*) from deportivo.Convocatoria as cc
	where cc.id_seleccion = s.id) as [cantidad_convocados],

		(
			select concat(j.nombre,' ',j.apellido) as nombre,c.posicion_habitual,c.club_origen,c.dorsal
			from deportivo.Convocatoria as c
			inner join deportivo.Jugador as j on j.id=c.id_jugador
			where c.id_seleccion=s.id
			order by c.dorsal
			for xml path('convocado'), Type
		) as [convocados]

	from deportivo.Seleccion as s
	order by s.nombre
	For xml path('seleccion'),root ('selecciones'),TYPE;
END;