#!/bin/bash

# ========================
# Script: distribucion_tamanos.sh
# Uso: bash distribucion_tamanos.sh carpeta_input carpeta_output
# Ejemplo: bash distribucion_tamanos.sh data/02_filtered/cutadapt results/cutadapt_Q20
# ========================

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Validación de argumentos
if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "❌ Uso: bash distribucion_tamanos.sh carpeta_input carpeta_output"
  echo "   Ejemplo: bash distribucion_tamanos.sh data/02_filtered/cutadapt results/cutadapt_Q20"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/distribucion_tamanos.tsv"
echo -e "Archivo\tLongitud_bp\tConteo" > "$OUTPUT"

# Función para calcular distribución de tamaños
analizar_tamano() {
    archivo=$1
    nombre=$(basename "$archivo")

    awk 'NR % 4 == 2 {print length($0)}' "$archivo" | \
    sort | uniq -c | \
    awk -v archivo="$nombre" '{print archivo "\t" $2 "\t" $1}' >> "$OUTPUT"
}

# Iterar sobre los archivos .fastq en el directorio de entrada
for archivo in "$INPUT_DIR"/*.fastq; do
    analizar_tamano "$archivo"
done

echo "✅ Distribución de tamaños guardada en: $OUTPUT"
