#!/bin/bash
# --------------------------------------------
# SCRIPT: fastqc_batch.sh
# USO: Ejecuta FastQC en todos los archivos .fastq en data/01_raw
# AUTOR: Camilo Malaver Pérez
# FECHA: 2025-06-15
# --------------------------------------------

# Carpeta donde están los archivos FASTQ
INPUT_DIR="data/01_raw"

# Carpeta donde se guardarán los informes FastQC
OUTPUT_DIR="data/02_fastqc"

# Crear carpeta de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Ejecutar FastQC en todos los archivos .fastq
fastqc -o "$OUTPUT_DIR" "$INPUT_DIR"/*.fastq

echo "✅ FastQC finalizado. Resultados en: $OUTPUT_DIR"
