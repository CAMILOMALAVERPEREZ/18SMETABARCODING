#!/bin/bash

RAW_DIR="data/01_raw"
FILTERED_DIR="data/02_filtered/trimmomatic_5W"
OUTPUT="results/tabla_resumen_trimmomatic.tsv"

mkdir -p results

echo -e "Archivo\tTotal_Secuencias\tTotal_Bases\tSecuencias_Filtradas\tBases_Filtradas\tSecuencias_<210pb" > $OUTPUT

for FILE in "$RAW_DIR"/*.fastq; do
    BASENAME=$(basename "$FILE" .fastq)

    # Total original
    TOTAL_SEQ=$(($(wc -l < "$FILE") / 4))
    TOTAL_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILE")

    for FILTERED in "$FILTERED_DIR"/${BASENAME}_trimmomatic150len*win.fastq; do
        FILENAME=$(basename "$FILTERED")
        CUR_SEQ=$(($(wc -l < "$FILTERED") / 4))
        CUR_BASES=$(awk 'NR%4==2{bases+=length($0)}END{print bases}' "$FILTERED")
        LT_210=$(awk 'NR%4==2{if(length($0)<210) c++}END{print c}' "$FILTERED")

        echo -e "$FILENAME\t$TOTAL_SEQ\t$TOTAL_BASES\t$((TOTAL_SEQ - CUR_SEQ))\t$((TOTAL_BASES - CUR_BASES))\t$LT_210" >> $OUTPUT
    done
done

echo "✅ Resumen generado en: $OUTPUT"

