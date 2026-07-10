#!/bin/bash

# ===============================================
# Script maestro para generar resúmenes de filtrado
# para todas las subcarpetas de data/02_filtered/
# ===============================================
# Autor: Camilo Malaver
# Fecha: 2025-07-29
# ===============================================

RAW_DIR="data/01_raw"
FILTERED_BASE_DIR="data/02_filtered"
OUTPUT_BASE_DIR="results/resumen_filtrado"

# Crear carpeta de salida si no existe
mkdir -p "$OUTPUT_BASE_DIR"

# Encabezado común
HEADER="Archivo\tFiltro\tTotal_Secuencias\tTotal_Bases\tSecuencias_Filtradas\tBases_Filtradas\tSecuencias_<210pb"

# Recorrer cada subcarpeta dentro de data/02_filtered/
for FILTERED_DIR in "$FILTERED_BASE_DIR"/*; do
    [ -d "$FILTERED_DIR" ] || continue

    FILTRO=$(basename "$FILTERED_DIR")
    OUTPUT_FILE="$OUTPUT_BASE_DIR/resumen_${FILTRO}.tsv"

    echo "📊 Generando resumen para filtro: $FILTRO"
    echo -e "$HEADER" > "$OUTPUT_FILE"

    for FILE in "$RAW_DIR"/*.fastq; do
        BASENAME=$(basename "$FILE" .fastq)
        TOTAL_SEQ=$(($(wc -l < "$FILE") / 4))
        TOTAL_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILE")

        for FILTERED in "$FILTERED_DIR"/${BASENAME}*.fastq; do
            [ -f "$FILTERED" ] || continue
            FILENAME=$(basename "$FILTERED")
            CUR_SEQ=$(($(wc -l < "$FILTERED") / 4))
            CUR_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILTERED")
            LT_210=$(awk 'NR%4==2{if(length($0)<210) c++}END{print c}' "$FILTERED")

            echo -e "$FILENAME\t$FILTRO\t$TOTAL_SEQ\t$TOTAL_BASES\t$((TOTAL_SEQ - CUR_SEQ))\t$((TOTAL_BASES - CUR_BASES))\t$LT_210" >> "$OUTPUT_FILE"
        done
    done

    echo "✅ Resumen generado: $OUTPUT_FILE"
done

echo "🎯 Todos los resúmenes han sido generados exitosamente."

