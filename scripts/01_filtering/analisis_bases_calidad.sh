#!/bin/bash

# ========================
# Script: analisis_bases_calidad.sh
# Uso: bash analisis_bases_calidad.sh carpeta_input carpeta_output
# Ejemplo: bash analisis_bases_calidad.sh data/02_filtered/cutadapt results/cutadapt_Q20
# ========================

INPUT_DIR="$1"
OUTPUT_DIR="$2"

# Validar argumentos
if [ -z "$INPUT_DIR" ] || [ -z "$OUTPUT_DIR" ]; then
  echo "❌ Uso: bash analisis_bases_calidad.sh carpeta_input carpeta_output"
  echo "   Ejemplo: bash analisis_bases_calidad.sh data/02_filtered/cutadapt results/cutadapt_Q20"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/resumen_bases_Q20.tsv"
echo -e "Archivo\tTotal_bases\tBases_Q<20\t%Q<20" > "$OUTPUT"

analizar_archivo() {
    archivo=$1
    nombre=$(basename "$archivo")

    total_bases=$(awk 'NR%4==2 {sum += length($0)} END {print sum}' "$archivo")

    bases_q20=$(awk 'NR%4==0 {
        for (i = 1; i <= length($0); i++) {
            q = substr($0, i, 1)
            if (index("!\"#$%&'\''()*+,-./01234", q)) c++
        }
    }
    END {print c}' "$archivo")

    if [[ "$total_bases" -gt 0 ]]; then
        perc_q20=$(awk -v q20="$bases_q20" -v total="$total_bases" 'BEGIN{printf "%.2f", (q20/total)*100}')
    else
        perc_q20="NA"
    fi

    echo -e "$nombre\t$total_bases\t$bases_q20\t$perc_q20" >> "$OUTPUT"
}

for archivo in "$INPUT_DIR"/*.fastq; do
    analizar_archivo "$archivo"
done

echo "✅ Análisis completado. Resultado en: $OUTPUT"

