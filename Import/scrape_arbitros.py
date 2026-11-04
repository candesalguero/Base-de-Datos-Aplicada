#!/usr/bin/env python3
"""Extrae árbitros de los Mundiales desde Wikipedia y genera XML."""

from __future__ import annotations

import argparse
import re
import unicodedata
from html.parser import HTMLParser
from pathlib import Path
from typing import Iterable
from xml.etree import ElementTree as ET


URL_FUENTE = "https://en.wikipedia.org/wiki/List_of_FIFA_World_Cup_referees"
SALIDA_POR_DEFECTO = Path(__file__).with_name("arbitros.xml")


def texto_limpio(valor: str) -> str:
    """Elimina referencias editoriales, espacios redundantes y extremos."""
    valor = re.sub(r"\[[^\]]+\]", "", valor)
    valor = re.sub(r"\s+", " ", valor)
    return valor.strip()


def texto_comparable(valor: str) -> str:
    """Normaliza texto para comparar encabezados sin considerar acentos."""
    valor = unicodedata.normalize("NFKD", texto_limpio(valor))
    return "".join(caracter for caracter in valor if not unicodedata.combining(caracter)).casefold()


def pais_iso2(valor: str) -> str:
    """Obtiene el ISO2 recortando las dos primeras letras limpias del país."""
    letras_limpias = "".join(caracter for caracter in texto_limpio(valor) if caracter.isalpha())
    return letras_limpias[:2].upper()


def separar_nombre(valor: str) -> tuple[str, str]:
    """Divide un nombre completo en nombre y apellido."""
    valor = texto_limpio(valor)
    if "," in valor:
        apellido, nombre = (parte.strip() for parte in valor.split(",", 1))
        return nombre, apellido
    partes = valor.split()
    if len(partes) < 2:
        raise ValueError(f"el nombre debe contener nombre y apellido: {valor!r}")
    return partes[0], " ".join(partes[1:])


def clave_encabezado(valor: str) -> str:
    """Normaliza un encabezado para buscar columnas."""
    return texto_comparable(valor).replace(" ", "").replace("_", "")


def buscar_columna(
    encabezados: list[str],
    candidatos: Iterable[str],
    obligatoria: bool = True,
) -> int | None:
    """Busca la primera columna cuyo encabezado coincide con los candidatos."""
    encabezados_normalizados = [clave_encabezado(encabezado) for encabezado in encabezados]
    for candidato in candidatos:
        clave_candidato = clave_encabezado(candidato)
        if clave_candidato in encabezados_normalizados:
            return encabezados_normalizados.index(clave_candidato)
    if obligatoria:
        raise ValueError(
            "la tabla no contiene ninguna de estas columnas: "
            + ", ".join(candidatos)
        )
    return None


class AnalizadorTablasHTML(HTMLParser):
    """Extrae filas y celdas de tablas HTML sin dependencias externas."""

    def __init__(self) -> None:
        super().__init__()
        self.filas: list[list[str]] = []
        self._fila: list[str] | None = None
        self._celda: list[str] | None = None
        self._profundidad_tabla = 0

    def handle_starttag(self, etiqueta: str, atributos: list[tuple[str, str | None]]) -> None:
        if etiqueta == "table":
            self._profundidad_tabla += 1
        elif etiqueta == "tr" and self._profundidad_tabla == 1:
            self._fila = []
        elif etiqueta in ("th", "td") and self._fila is not None:
            self._celda = []

    def handle_data(self, datos: str) -> None:
        if self._celda is not None:
            self._celda.append(datos)

    def handle_endtag(self, etiqueta: str) -> None:
        if etiqueta in ("th", "td") and self._celda is not None and self._fila is not None:
            self._fila.append(texto_limpio(" ".join(self._celda)))
            self._celda = None
        elif etiqueta == "tr" and self._fila:
            self.filas.append(self._fila)
            self._fila = None
        elif etiqueta == "table":
            self._profundidad_tabla -= 1


def extraer_filas_de_tablas(
    tablas: Iterable[list[list[str]]],
) -> list[tuple[str, str, str]]:
    """Encuentra una tabla de árbitros y devuelve nombre, país y categoría."""
    for filas in tablas:
        if not filas:
            continue
        encabezados = filas[0]
        try:
            indice_nombre = buscar_columna(encabezados, ("Name", "Referee"))
        except ValueError:
            continue

        indice_pais = buscar_columna(
            encabezados,
            ("Country", "Nation", "Association"),
            obligatoria=False,
        )
        extraidas: list[tuple[str, str, str]] = []
        for celdas in filas[1:]:
            if indice_nombre >= len(celdas):
                continue
            nombre = texto_limpio(celdas[indice_nombre])
            if not nombre:
                continue
            if indice_pais is not None and indice_pais < len(celdas):
                pais = celdas[indice_pais]
            else:
                coincidencia = re.search(r"\(\s*([A-Z]{3})\s*\)", nombre)
                if not coincidencia:
                    continue
                pais = coincidencia.group(1)
                nombre = texto_limpio(nombre[:coincidencia.start()])
            extraidas.append((nombre, pais, "Internacional"))
        if extraidas:
            return extraidas
    raise ValueError(
        "no se encontró una tabla de árbitros con columna Referee "
        "y país identificable"
    )


def filas_desde_html(html: str) -> list[tuple[str, str, str]]:
    """Analiza HTML con BeautifulSoup si está instalado o con la biblioteca estándar."""
    try:
        from bs4 import BeautifulSoup
    except ImportError:
        analizador = AnalizadorTablasHTML()
        analizador.feed(html)
        return extraer_filas_de_tablas([analizador.filas])

    sopa = BeautifulSoup(html, "html.parser")
    tablas = []
    for tabla in sopa.find_all("table"):
        filas = [
            [texto_limpio(celda.get_text(" ", strip=True)) for celda in fila.find_all(["th", "td"])]
            for fila in tabla.find_all("tr")
        ]
        tablas.append(filas)
    return extraer_filas_de_tablas(tablas)


def filas_desde_xml(raiz: ET.Element) -> list[tuple[str, str, str]]:
    """Lee filas del formato XML opcional para reproducir pruebas sin red."""
    if raiz.tag != "arbitros":
        raise ValueError("la raíz del XML offline debe ser <arbitros>")
    filas = []
    for arbitro in raiz.findall("arbitro"):
        nombre_completo = arbitro.findtext("nombre_completo")
        if not nombre_completo:
            nombre = arbitro.findtext("nombre")
            apellido = arbitro.findtext("apellido")
            nombre_completo = " ".join(parte for parte in (nombre, apellido) if parte)
        pais = (
            arbitro.findtext("pais")
            or arbitro.findtext("pais_nombre")
            or arbitro.findtext("pais_iso2")
        )
        categoria = arbitro.findtext("categoria") or "Internacional"
        if not nombre_completo or not pais:
            raise ValueError(
                "las filas XML offline requieren nombre_completo y pais"
            )
        filas.append((nombre_completo, pais, categoria))
    if not filas:
        raise ValueError("el XML offline no contiene elementos <arbitro>")
    return filas


def generar_xml(filas: Iterable[tuple[str, str, str]]) -> ET.Element:
    """Construye la salida XML esperada por el importador SQL."""
    raiz = ET.Element("arbitros")
    for nombre_original, pais_original, categoria_original in filas:
        nombre, apellido = separar_nombre(nombre_original)
        arbitro = ET.SubElement(raiz, "arbitro")
        ET.SubElement(arbitro, "nombre").text = nombre
        ET.SubElement(arbitro, "apellido").text = apellido
        ET.SubElement(arbitro, "pais_iso2").text = pais_iso2(pais_original)
        ET.SubElement(arbitro, "categoria").text = (
            texto_limpio(categoria_original) or "Internacional"
        )
    return raiz


def cargar_filas(entrada: Path | None, url: str) -> list[tuple[str, str, str]]:
    """Carga filas desde un XML/HTML local o desde la URL de Wikipedia."""
    if entrada:
        contenido = entrada.read_bytes()
        if entrada.suffix.lower() == ".xml":
            return filas_desde_xml(ET.fromstring(contenido))
        return filas_desde_html(contenido.decode("utf-8"))

    try:
        import requests
    except ImportError:
        from urllib.request import Request, urlopen

        solicitud = Request(
            url,
            headers={"User-Agent": "Extractor de árbitros de Bases de Datos Aplicada/1.0"},
        )
        with urlopen(solicitud, timeout=30) as respuesta:
            if respuesta.status < 200 or respuesta.status >= 300:
                raise RuntimeError(f"la solicitud HTTP falló con estado {respuesta.status}")
            return filas_desde_html(respuesta.read().decode("utf-8"))

    respuesta = requests.get(
        url,
        headers={"User-Agent": "Extractor de árbitros de Bases de Datos Aplicada/1.0"},
        timeout=30,
    )
    respuesta.raise_for_status()
    return filas_desde_html(respuesta.text)


def principal() -> int:
    """Punto de entrada de la línea de comandos."""
    parser = argparse.ArgumentParser(
        description="Extrae árbitros de Wikipedia y genera un XML compatible con SQL Server."
    )
    parser.add_argument(
        "--entrada",
        type=Path,
        help="archivo HTML/XML local; evita la solicitud HTTP",
    )
    parser.add_argument("--url", default=URL_FUENTE, help="URL de la fuente")
    parser.add_argument(
        "--salida",
        type=Path,
        default=SALIDA_POR_DEFECTO,
        help="archivo XML de salida",
    )
    argumentos = parser.parse_args()

    raiz = generar_xml(cargar_filas(argumentos.entrada, argumentos.url))
    argumentos.salida.parent.mkdir(parents=True, exist_ok=True)
    ET.ElementTree(raiz).write(
        argumentos.salida,
        encoding="utf-8",
        xml_declaration=True,
    )
    print(
        f"se escribieron {len(raiz.findall('arbitro'))} árbitros en "
        f"{argumentos.salida}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(principal())
