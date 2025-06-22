#!/bin/bash

RAW_DIR="data/01_raw"
OUTPUT_DIR="data/02_filtered/fastp"
REPORT_DIR="results/fastp_reports"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$REPORT_DIR"

for fwd in "$RAW_DIR"/*_R1.fastq; do
    base=$(basename "$fwd" _R1.fastq)
    rev="$RAW_DIR/${base}_R2.fastq"

    # Salidas
    fwd_out="$OUTPUT_DIR/${base}_R1.fastq"
    rev_out="$OUTPUT_DIR/${base}_R2.fastq"
    html_report="$REPORT_DIR/${base}_fastp.html"
    json_report="$REPORT_DIR/${base}_fastp.json"

    echo "Procesando muestra: $base"

    fastp \
        -i "$fwd" \
        -I "$rev" \
        -o "$fwd_out" \
        -O "$rev_out" \
        --detect_adapter_for_pe \
        --thread 4 \
        --qualified_quality_phred 20 \
        --length_required 100 \
        --html "$html_report" \
        --json "$json_report" \
        --report_title "Fastp Report for $base"
done

echo "✅ Procesamiento con fastp completado."
