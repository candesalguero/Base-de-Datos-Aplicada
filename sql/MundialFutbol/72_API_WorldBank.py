# Universidad: Universidad Nacional de La Matanza
# Materia: Bases de Datos Aplicada
# Integrantes:
#     - Salguero, Candela
#     - Ocaranza, Lucila
#     - Dimattia Damm, Malena
#     - Fuentes, Martina Alejandra

# Fecha: Noviembre 2026

# Objetivo:
# Obtener desde la API del Banco Mundial el indicador de PBI per cápita
# para los años 2022 a 2025(hay más viejos si se decea puede cambiarse 
# el rando del año en la linea ), filtrar los datos correspondientes a países
# reales y relacionarlos con los países registrados en la base de datos
# MundialFutbol.

# Los datos obtenidos se guardan en  formato JSON y los envía al
# SP  general.usp_ImportarIndicadoresEconomicosAPI,
# que se encarga de realizar la importación en SQL Server.

# Al final se muestra el resultado de la importación para verificar la
# cantidad de registros procesados y los posibles errores.

# --------------------------------------------------
# INSTRUCCIONES DE EJECUCIÓN
# --------------------------------------------------
# Este archivo debe ejecutarse con Python 3.13 o superior.
#
# Requisitos:
# - Tener instalada la librería requests.
# - Tener instalada la librería pyodbc.
# - Tener SQL Server en ejecución.
# - Tener creada la base de datos MundialFutbol.
#
# Ejecutar desde una terminal ubicada en esta carpeta:
#
#     py -3.13 72_API_WorldBank.py
#
# El script se conecta a la base MundialFutbol y carga
# los datos obtenidos desde la API de World Bank.
# --------------------------------------------------

import pyodbc

import requests

import json

# --------------------------------------------------
# 1. Obtener PBI per cápita desde World Bank
# --------------------------------------------------

url = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.PCAP.CD?date=2022:2025&format=json"

respuesta = requests.get(url)
print("Estado API PBI:", respuesta.status_code)

datos = respuesta.json()

cantidad_paginas = datos[0]["pages"]
registros = datos[1]

# La primera página ya está cargada.
# Descargamos las páginas restantes.
for pagina in range(2, cantidad_paginas + 1):
    respuesta = requests.get(url + f"&page={pagina}")
    datos = respuesta.json()
    registros.extend(datos[1])

print("\nComprobación en la respuesta original de la API:")

for codigo in ["QA", "AR", "MX"]:
    encontrados = 0

    for registro in registros:
        if registro["country"]["id"] == codigo:
            encontrados += 1
            print(
                codigo,
                registro["date"],
                registro["value"]
            )

    print("Total para", codigo, ":", encontrados)

# --------------------------------------------------
# 2. Obtener listado de países
# --------------------------------------------------

url_paises = "https://api.worldbank.org/v2/country?format=json"

respuesta_paises = requests.get(url_paises)
print("Estado API países:", respuesta_paises.status_code)

datos_paises = respuesta_paises.json()

cantidad_paginas_paises = datos_paises[0]["pages"]
paises = datos_paises[1]

# Descargar las páginas restantes
for pagina in range(2, cantidad_paginas_paises + 1):
    respuesta_paises = requests.get(url_paises + f"&page={pagina}")
    datos_paises = respuesta_paises.json()
    paises.extend(datos_paises[1])


# --------------------------------------------------
# 3. Obtener códigos ISO2 de países reales
# --------------------------------------------------

codigos_paises = set()

for pais in paises:
    codigos_paises.add(pais["iso2Code"])


# --------------------------------------------------
# 4. Filtrar los registros del indicador
#    dejando solamente países reales (dejando fuera por ejemplo regiones)
# --------------------------------------------------

registros_paises = []

for registro in registros:
    if registro["country"]["id"] in codigos_paises:
        registros_paises.append(registro)


print("\nRegistros encontrados en la API:")

for codigo in ["QA", "AR", "MX"]:
    encontrados = 0

    for registro in registros_paises:
        if registro["country"]["id"] == codigo:
            encontrados += 1

    print(codigo, ":", encontrados, "registros")

print("Registros de países:", len(registros_paises))

conexion = pyodbc.connect(
    "DRIVER={ODBC Driver 18 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=MundialFutbol;"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

cursor = conexion.cursor()

cursor.execute("""
    SELECT id, nombre, ISO2
    FROM general.Pais
""")

paises_bd = cursor.fetchall()

# Diccionario: código ISO2 -> datos del país en SQL Server
paises_bd_por_iso = {}

print("\nPaíses cargados en SQL Server:")

for pais in paises_bd:
    paises_bd_por_iso[pais.ISO2] = {
        "id": pais.id,
        "nombre": pais.nombre
    }

for codigo, pais in paises_bd_por_iso.items():
    print(codigo, pais["nombre"])

# Relacionar todos los registros de la API con los países de SQL Server

registros_preparados = []

for registro in registros_paises:
    codigo_pais = registro["country"]["id"]

    if codigo_pais in paises_bd_por_iso and registro["value"] is not None:

        pais_bd = paises_bd_por_iso[codigo_pais]

        registros_preparados.append({
            "id_pais": pais_bd["id"],
            "pais": pais_bd["nombre"],
            "anio": int(registro["date"]),
            "pbi": registro["value"]
        })

print("Registros preparados para importar:", len(registros_preparados))

for registro in registros_preparados:
    print(registro)

# --------------------------------------------------
# 5. Preparar datos para enviar al procedimiento de SQL
# --------------------------------------------------

datos_importacion = []

for registro in registros_preparados:
    datos_importacion.append({
        "id_pais": registro["id_pais"],
        "anio": registro["anio"],
        "pbi": registro["pbi"]
    })

json_importacion = json.dumps(datos_importacion)

print("\nJSON enviado al procedimiento SQL:")
print(json_importacion)

# --------------------------------------------------
# 6. Enviar los datos al procedimiento en SQL
# --------------------------------------------------

cursor.execute(
    "EXEC general.usp_ImportarIndicadoresEconomicosAPI @datos = ?, @archivo = ?",
    json_importacion,
    "WorldBank_API_NY.GDP.PCAP.CD"
)

resultado = cursor.fetchall()

conexion.commit()

print("\nResultado de la importación:")
for fila in resultado:
    print(fila)