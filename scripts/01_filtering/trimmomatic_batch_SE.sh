#!/bin/bash

# Script para recorte con Trimmomatic (modo SINGLE-END)
# Aplica SLIDINGWINDOW de 1 a 7 y MINLEN=150 a cada archivo .fastq
# Autor: Camilo Malaver

TRIMMOMATIC_JAR="/usr/share/java/trimmomatic.jar"
INPUT_DIR="data/01_raw"
BASE_OUTPUT_DIR="data/02_filtered/trimmomatic_win"
MIN_LENGTH="MINLEN:150"

# Crear salida base
mkdir -p "$BASE_OUTPUT_DIR"

# Obtener todos los archivos .fastq en la carpeta de entrada
for FASTQ in "$INPUT_DIR"/*.fastq; do
    BASENAME=$(basename "$FASTQ" .fastq)
    echo "🔹 Procesando archivo: $BASENAME"

    # Iterar por cada ventana de calidad
    for WIN_SIZE in {1..7}; do
        WIN_PARAM="${WIN_SIZE}:20"
        OUTPUT_DIR="${BASE_OUTPUT_DIR}${WIN_SIZE}"
        mkdir -p "$OUTPUT_DIR"

        OUTPUT_FASTQ="$OUTPUT_DIR/${BASENAME}_trimmomatic150len${WIN_SIZE}win.fastq"

        echo "  - Aplicando SLIDINGWINDOW:$WIN_PARAM -> $OUTPUT_FASTQ"

        java -jar "$TRIMMOMATIC_JAR" SE -phred33 \
            "$FASTQ" \
            "$OUTPUT_FASTQ" \
            SLIDINGWINDOW:$WIN_PARAM $MIN_LENGTH
    done
done

echo "✔ Todos los archivos han sido procesados con Trimmomatic en modo SE (ventanas 1 a 7)"

