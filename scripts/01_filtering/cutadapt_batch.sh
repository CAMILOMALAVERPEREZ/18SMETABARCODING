#!/bin/bash

# ========================================
# Script para aplicar cutadapt a múltiples muestras (forward y reverse)
# ========================================

# Ubicaciones
INPUT_DIR="data/01_raw"
OUTPUT_DIR="data/02_filtered/cutadapt"
mkdir -p "$OUTPUT_DIR"

# Parámetros de corte
LENGTHCUT=150
QUALITY=20

# Lista de archivos forward (los reverse se asumen con _R2)
ARCHIVOS_FORWARD=($(ls ${INPUT_DIR}/*_R1.fastq))

# Iterar sobre archivos forward
for FASTQR1 in "${ARCHIVOS_FORWARD[@]}"; do
  # Obtener el nombre base de la muestra (sin extensión y sin _R1/_R2)
  MUESTRA=$(basename "$FASTQR1" | sed 's/_R1.fastq//')

  # Definir reverse automáticamente
  FASTQR2="${INPUT_DIR}/${MUESTRA}_R2.fastq"

  # Salidas
  OUTPUT_R1="${OUTPUT_DIR}/${MUESTRA}_R1_cutadapt_q${QUALITY}_m${LENGTHCUT}.fastq"
  OUTPUT_R2="${OUTPUT_DIR}/${MUESTRA}_R2_cutadapt_q${QUALITY}_m${LENGTHCUT}.fastq"

  echo "Procesando muestra: $MUESTRA"

  # Recorte FORWARD
  cutadapt -q $QUALITY -m $LENGTHCUT -o "$OUTPUT_R1" "$FASTQR1"

  # Recorte REVERSE
  cutadapt -q $QUALITY -m $LENGTHCUT -o "$OUTPUT_R2" "$FASTQR2"

  echo "✓ Finalizado: $MUESTRA"
done

echo "✅ Recorte con Cutadapt completado para todas las muestras."
