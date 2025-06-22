#!/bin/bash

# Script para recorte con Trimmomatic (modo SINGLE-END)
# Aplica SLIDINGWINDOW de 1 a 7 y MINLEN=150 a cada archivo
# Autor: Camilo Malaver

TRIMMOMATIC_JAR="/usr/share/java/trimmomatic.jar"
INPUT_DIR="data/01_raw"
OUTPUT_DIR="data/02_filtered/trimmomatic_5W"
MIN_LENGTH="MINLEN:150"

mkdir -p "$OUTPUT_DIR"

# Archivos a procesar (forward y reverse individuales)
ARCHIVOS=("Cmcontrol1_R1.fastq" "Cmcontrol1_R2.fastq" "Cmcontrol2_R1.fastq" "Cmcontrol2_R2.fastq")

# Ventanas de calidad a probar
WINDOWS=("1:20" "2:20" "3:20" "4:20" "5:20" "6:20" "7:20")

for ARCHIVO in "${ARCHIVOS[@]}"; do
    echo "🔹 Procesando archivo: $ARCHIVO"

    for WIN in "${WINDOWS[@]}"; do
        echo "  - Aplicando SLIDINGWINDOW: $WIN"

        ARCHIVO_ENTRADA="$INPUT_DIR/$ARCHIVO"
        ARCHIVO_SALIDA="$OUTPUT_DIR/${ARCHIVO%.fastq}_trimmomatic150len${WIN//:/}win.fastq"

        java -jar "$TRIMMOMATIC_JAR" SE -phred33 \
            "$ARCHIVO_ENTRADA" \
            "$ARCHIVO_SALIDA" \
            SLIDINGWINDOW:$WIN $MIN_LENGTH
    done
done

echo "✔ Todos los archivos han sido procesados con Trimmomatic (modo SE)"

