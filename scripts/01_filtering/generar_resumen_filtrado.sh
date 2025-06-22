#!/bin/bash

# Validar argumentos
if [ "$#" -ne 3 ]; then
    echo "Uso: bash generar_resumen_filtrado.sh <dir_raw> <dir_filtrado> <archivo_salida>"
    echo "Ejemplo: bash generar_resumen_filtrado.sh data/01_raw data/02_filtered/cutadapt results/resumen_filtrado/resumen_cutadapt.tsv"
    exit 1
fi

RAW_DIR=$1
FILTERED_DIR=$2
OUTPUT=$3

mkdir -p "$(dirname "$OUTPUT")"

# Encabezado
echo -e "Archivo\tTotal_Secuencias\tTotal_Bases\tSecuencias_Filtradas\tBases_Filtradas\tSecuencias_<210pb" > "$OUTPUT"

# Iterar sobre archivos raw
for FILE in "$RAW_DIR"/*.fastq; do
    BASENAME=$(basename "$FILE" .fastq)
    TOTAL_SEQ=$(($(wc -l < "$FILE") / 4))
    TOTAL_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILE")

    # Buscar el archivo correspondiente filtrado
    for FILTERED in "$FILTERED_DIR"/${BASENAME}*.fastq; do
        [ -f "$FILTERED" ] || continue
        FILENAME=$(basename "$FILTERED")
        CUR_SEQ=$(($(wc -l < "$FILTERED") / 4))
        CUR_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILTERED")
        LT_210=$(awk 'NR%4==2{if(length($0)<210) c++}END{print c}' "$FILTERED")

        echo -e "$FILENAME\t$TOTAL_SEQ\t$TOTAL_BASES\t$((TOTAL_SEQ - CUR_SEQ))\t$((TOTAL_BASES - CUR_BASES))\t$LT_210" >> "$OUTPUT"
    done
done

echo "✅ Resumen generado en: $OUTPUT"
