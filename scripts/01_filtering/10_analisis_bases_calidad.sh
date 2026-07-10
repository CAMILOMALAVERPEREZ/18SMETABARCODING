#!/bin/bash

# ========================================
# Script maestro: analizar bases Q<30 para todas las subcarpetas de 02_filtered
# Autor: Camilo Malaver
# Fecha: 2025-07-29
# ========================================

INPUT_BASE="data/02_filtered"
OUTPUT_BASE="results/resumen_filtrado"

mkdir -p "$OUTPUT_BASE"

echo "📊 Iniciando análisis de calidad (Q<30) para todas las subcarpetas de $INPUT_BASE"

# Función para calcular bases Q<30
analizar_archivo() {
    archivo=$1
    nombre=$(basename "$archivo")

    total_bases=$(awk 'NR%4==2 {sum += length($0)} END {print sum}' "$archivo")

    # Carácteres Phred+33 con Q < 30  →  ASCII 33..62  →  '!'..'>'
    bases_q30=$(awk 'NR%4==0 {
        for (i = 1; i <= length($0); i++) {
            q = substr($0, i, 1)
            if (index("!\"#$%&'\''()*+,-./0123456789:;<=>", q)) c++
        }
    }
    END {print c+0}' "$archivo")

    if [[ "$total_bases" -gt 0 ]]; then
        perc_q30=$(awk -v q30="$bases_q30" -v total="$total_bases" 'BEGIN{printf "%.2f", (q30/total)*100}')
    else
        perc_q30="NA"
    fi

    echo -e "$nombre\t$total_bases\t$bases_q30\t$perc_q30" >> "$OUTFILE"
}

# Recorrer cada subcarpeta de filtros
for FILTRO_DIR in "$INPUT_BASE"/*; do
    [ -d "$FILTRO_DIR" ] || continue
    FILTRO=$(basename "$FILTRO_DIR")
    OUTFILE="$OUTPUT_BASE/resumen_bases_Q30_${FILTRO}.tsv"

    echo "🔍 Analizando filtro: $FILTRO"
    echo -e "Archivo\tTotal_bases\tBases_Q<30\t%Q<30" > "$OUTFILE"

    # Iterar sobre los archivos .fastq del filtro
    for archivo in "$FILTRO_DIR"/*.fastq; do
        [ -f "$archivo" ] || continue
        analizar_archivo "$archivo"
    done

    echo "✅ Resumen generado: $OUTFILE"
done

echo "🎯 Análisis de calidad Q<30 completado para todos los filtros."
