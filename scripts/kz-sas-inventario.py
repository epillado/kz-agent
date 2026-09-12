#!/usr/bin/env python
# -*- coding: utf-8 -*-
from __future__ import print_function, division
"""
kz-sas-inventario.py — Analizador y clasificador forense del acervo digital SAS.
Diseñado para ejecutarse tanto en local como directamente en el servidor de la SECON
usando únicamente la librería estándar (compatible dual Python 2.7+ y Python 3.x).

Clasifica archivos en los patrones descubiertos:
- Patrón 1 (Ficha completa con RFC): SAS-1.2-YYYYMM-RFC<FOLIO><TIPO>-<ESTADO>.xml
- Patrón 2 (Estándar con Folio): SAS-1.2-YYYYMM-<FOLIO><TIPO>.pdf
- Patrón 3 (Opacos / T&C / Hash): 4883211TwBMbGFEz.xml
- Patrón 4 (Consecutivo con ceros): 0007422mB3TgE3QC.pdf
- Patrón 5 (Otros / No clasificados)

Mide tiempos de ejecución para extrapolar el costo y duración real sobre 5.1 TB.
"""

import os
import sys
import re
import time
import json
import csv
import argparse
from collections import Counter

# Expresiones regulares para los patrones observados
RE_PATRON_1 = re.compile(
    r"^SAS-(?P<version>[\d\.]+)-(?P<periodo>\d{6})-(?P<rfc>[A-Z&Ñ]{3,4}\d{6}[A-Z0-9]{3})(?P<folio>\d+)(?P<tipo>[A-Z]+)(?:-(?P<estado>[A-Za-z0-9_]+))?\.(?P<ext>xml|pdf)$",
    re.IGNORECASE
)

RE_PATRON_2 = re.compile(
    r"^SAS-(?P<version>[\d\.]+)-(?P<periodo>\d{6})-(?P<folio>\d+)(?P<tipo>[A-Z]+)\.(?P<ext>xml|pdf)$",
    re.IGNORECASE
)

RE_PATRON_3 = re.compile(
    r"^(?P<id_prefix>\d{6,8})(?P<token>[A-Za-z0-9]{6,16})\.(?P<ext>xml|pdf)$"
)

RE_PATRON_4 = re.compile(
    r"^(?P<ceros>0{2,6}\d+)(?P<token>[A-Za-z0-9]{6,16})\.(?P<ext>xml|pdf)$"
)

def clasificar_archivo(nombre):
    """Clasifica un nombre de archivo y extrae sus campos estructurados."""
    m1 = RE_PATRON_1.match(nombre)
    if m1:
        d = m1.groupdict()
        return {
            "patron": "P1_RFC_COMPLETO",
            "version": d.get("version"),
            "periodo": d.get("periodo"),
            "rfc": d.get("rfc"),
            "folio": d.get("folio"),
            "tipo_doc": d.get("tipo"),
            "estado": d.get("estado") or "NORMAL"
        }
    
    m2 = RE_PATRON_2.match(nombre)
    if m2:
        d = m2.groupdict()
        return {
            "patron": "P2_FOLIO_ESTANDAR",
            "version": d.get("version"),
            "periodo": d.get("periodo"),
            "rfc": None,
            "folio": d.get("folio"),
            "tipo_doc": d.get("tipo"),
            "estado": "NORMAL"
        }

    m4 = RE_PATRON_4.match(nombre)
    if m4:
        d = m4.groupdict()
        return {
            "patron": "P4_CEROS_HASH",
            "version": None,
            "periodo": None,
            "rfc": None,
            "folio": d.get("ceros"),
            "tipo_doc": "DESCONOCIDO",
            "estado": d.get("token")
        }

    m3 = RE_PATRON_3.match(nombre)
    if m3:
        d = m3.groupdict()
        return {
            "patron": "P3_OPACO_TYC",
            "version": None,
            "periodo": None,
            "rfc": None,
            "folio": d.get("id_prefix"),
            "tipo_doc": "TYC_VIEJO",
            "estado": d.get("token")
        }

    return {
        "patron": "P5_OTRO",
        "version": None,
        "periodo": None,
        "rfc": None,
        "folio": None,
        "tipo_doc": "OTRO",
        "estado": "SIN_CLASIFICAR"
    }

def escanear(root_dir, csv_out=None, max_files=None):
    print("[*] Iniciando escaneo e inventario en: {}".format(root_dir))
    t_start = time.time()
    
    contador_patrones = Counter()
    contador_extensiones = Counter()
    contador_entidades = Counter()
    total_bytes = 0
    total_archivos = 0
    
    csv_writer = None
    csv_file = None
    if csv_out:
        if sys.version_info[0] >= 3:
            csv_file = open(csv_out, "w", newline="", encoding="utf-8")
        else:
            csv_file = open(csv_out, "wb")
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow([
            "rel_path", "filename", "ext", "size_bytes", "patron",
            "entidad", "periodo", "folio", "rfc", "tipo_doc", "estado"
        ])
    
    try:
        for root, dirs, files in os.walk(root_dir):
            rel_root = os.path.relpath(root, root_dir)
            entidad = "RAIZ"
            if rel_root != ".":
                partes = rel_root.split(os.sep)
                for p in partes:
                    if p.startswith("ent"):
                        entidad = p
                        break
            
            for f in files:
                ext = f.split(".")[-1].lower() if "." in f else ""
                if ext not in ("xml", "pdf"):
                    continue
                
                full_path = os.path.join(root, f)
                try:
                    fsize = os.path.getsize(full_path)
                except OSError:
                    fsize = 0
                
                info = clasificar_archivo(f)
                patron = info["patron"]
                
                total_archivos += 1
                total_bytes += fsize
                contador_patrones[patron] += 1
                contador_extensiones[ext] += 1
                contador_entidades[entidad] += 1
                
                if csv_writer:
                    row = [
                        os.path.join(rel_root, f),
                        f,
                        ext,
                        fsize,
                        patron,
                        entidad,
                        info["periodo"] or "",
                        info["folio"] or "",
                        info["rfc"] or "",
                        info["tipo_doc"] or "",
                        info["estado"] or ""
                    ]
                    if sys.version_info[0] < 3:
                        row = [str(col).encode("utf-8") if isinstance(col, unicode) else str(col) for col in row]
                    csv_writer.writerow(row)
                
                if total_archivos % 50000 == 0:
                    elapsed = time.time() - t_start
                    rate = total_archivos / elapsed if elapsed > 0 else 0
                    print("  -> Procesados: {:,} archivos ({:,.0f} archivos/seg)".format(total_archivos, rate))
                
                if max_files and total_archivos >= max_files:
                    print("[!] Límite de prueba alcanzado: {} archivos.".format(max_files))
                    break
            
            if max_files and total_archivos >= max_files:
                break
                
    finally:
        if csv_file:
            csv_file.close()

    t_end = time.time()
    duracion = max(t_end - t_start, 0.001)
    rate = total_archivos / duracion

    resumen = {
        "ruta_analizada": root_dir,
        "total_archivos": total_archivos,
        "total_gb": round(total_bytes / (1024**3), 2),
        "duracion_segundos": round(duracion, 2),
        "velocidad_archivos_seg": round(rate, 2),
        "por_patron": dict(contador_patrones),
        "por_extension": dict(contador_extensiones),
        "top_entidades": contador_entidades.most_common(10)
    }

    print("\n" + "="*60)
    print("           RESUMEN DE EJECUCIÓN Y BENCHMARK")
    print("="*60)
    print("Total archivos analizados : {:,}".format(total_archivos))
    print("Tamaño total acumulado    : {} GB".format(resumen["total_gb"]))
    print("Tiempo transcurrido       : {:.2f} segundos".format(duracion))
    print("Rendimiento de escaneo    : {:,.1f} archivos/segundo".format(rate))
    print("\n--- Desglose por Patrón ---")
    for pat, cnt in contador_patrones.most_common():
        pct = (cnt / total_archivos * 100) if total_archivos > 0 else 0
        print("  * {:<20}: {:>10,} ({:5.1f}%)".format(pat, cnt, pct))
    print("\n--- Desglose por Extensión ---")
    for ext, cnt in contador_extensiones.most_common():
        print("  * .{:<10}: {:>10,}".format(ext, cnt))
    print("="*60 + "\n")
    
    # Proyección a escala de 10 millones de archivos
    archivos_proyeccion = 10000000
    segundos_proyectados = archivos_proyeccion / rate if rate > 0 else 0
    minutos_proyectados = segundos_proyectados / 60
    print("[BENCHMARK] Tiempo estimado para procesar 10M de archivos completos en este CPU:")
    print("            ~{:.1f} minutos ({:.2f} horas)".format(minutos_proyectados, segundos_proyectados / 3600))
    print("="*60 + "\n")

    return resumen

def main():
    parser = argparse.ArgumentParser(description="Clasificador e inventariador de acervo SAS")
    parser.add_argument("--root", default="/run/media/lalo/Backups/sas-standalone-mirror",
                        help="Directorio raíz a escanear")
    parser.add_argument("--csv", default=None, help="Ruta del CSV para exportar detalle")
    parser.add_argument("--max", type=int, default=None, help="Límite de archivos para benchmark rápido")
    args = parser.parse_args()

    if not os.path.exists(args.root):
        print("Error: La ruta {} no existe.".format(args.root))
        sys.exit(1)

    escanear(args.root, args.csv, args.max)

if __name__ == "__main__":
    main()
