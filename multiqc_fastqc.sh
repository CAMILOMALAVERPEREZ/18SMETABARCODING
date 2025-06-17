#!/bin/bash
# --------------------------------------------
# SCRIPT: multiqc_fastqc.sh
# USO: Resume los resultados de FastQC con MultiQC
# AUTOR: Camilo Malaver Pérez
# FECHA: 2025-06-15
# --------------------------------------------

# Carpeta donde están los resultados de FastQC
INPUT_DIR="data/02_fastqc"

# Carpeta donde se guardará el resumen de MultiQC
OUTPUT_DIR="data/02_fastqc/multiqc_report"

# Crear carpeta de salida si no existe
mkdir -p "$OUTPUT_DIR"

# Ejecutar MultiQC
multiqc "$INPUT_DIR" -o "$OUTPUT_DIR"

echo "✅ MultiQC generado en: $OUTPUT_DIR"
