#!/bin/bash

# ========================================
# Script maestro: calcular distribución de tamaños por filtro
# Autor: Camilo Malaver
# Fecha: 2025-07-29
# ========================================

INPUT_BASE="data/02_filtered"
OUTPUT_BASE="results/resumen_filtrado"

mkdir -p "$OUTPUT_BASE"

echo "📏 Iniciando cálculo de distribución de tamaños por filtro..."

# Función para analizar la distribución de tamaños de un archivo
analizar_tamano() {
    archivo=$1
    nombre=$(basename "$archivo")

    awk 'NR % 4 == 2 {print length($0)}' "$archivo" | \
    sort | uniq -c | \
    awk -v archivo="$nombre" '{print archivo "\t" $2 "\t" $1}' >> "$OUTFILE"
}

# Recorrer todas las subcarpetas de filtros
for FILTRO_DIR in "$INPUT_BASE"/*; do
    [ -d "$FILTRO_DIR" ] || continue
    FILTRO=$(basename "$FILTRO_DIR")
    OUTFILE="$OUTPUT_BASE/distribucion_tamanos_${FILTRO}.tsv"

    echo "🔍 Procesando filtro: $FILTRO"
    echo -e "Archivo\tLongitud_bp\tConteo" > "$OUTFILE"

    for archivo in "$FILTRO_DIR"/*.fastq; do
        [ -f "$archivo" ] || continue
        analizar_tamano "$archivo"
    done

    echo "✅ Distribución generada: $OUTFILE"
done

echo "🎯 Análisis de distribución de tamaños completado para todos los filtros."

