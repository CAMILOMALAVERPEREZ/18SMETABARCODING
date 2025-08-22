#!/bin/bash

# ========================================
# Script maestro: Dejar solo secuencias pareadas despues de la aplicacion de cada filtro
# Autor: Camilo Malaver
# Fecha: 2025-08-21
# ========================================


#!/usr/bin/env bash
set -euo pipefail

# ======= CONFIG =======
BASE_DIR="/home/camilomalaver/18SMETABARCODING_local/data/02_filtered"
FILTERS=("cutadapt" "fastp" "trimmomatic_win4" "trimmomatic_win3")
# ======================

command -v seqkit >/dev/null 2>&1 || { echo "[ERROR] seqkit no está en PATH"; exit 1; }

for F in "${FILTERS[@]}"; do
  FDIR="${BASE_DIR}/${F}"
  [[ -d "$FDIR" ]] || { echo "[WARN] Carpeta no existe: $FDIR, se omite."; continue; }
  echo "[INFO] Procesando filtro: $F"

  OUTDIR="${FDIR}/filtrados"
  mkdir -p "$OUTDIR"

  shopt -s nullglob
  for R1 in "$FDIR"/*R1*.fastq "$FDIR"/*R1*.fastq.gz; do
    base="$(basename "$R1")"
    R2="${base/_R1/_R2}"
    R2_PATH="$FDIR/$R2"

    if [[ ! -f "$R2_PATH" ]]; then
      R2="${base/R1/R2}"
      R2_PATH="$FDIR/$R2"
    fi
    [[ -f "$R2_PATH" ]] || { echo "  [WARN] Sin par para $base, se omite."; continue; }

    SAMPLE="${base%%_R1*}"
    echo "  [OK] Emparejando muestra: $SAMPLE"

    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    FWD_IDS="$TMPDIR/${SAMPLE}_R1.ids"
    REV_IDS="$TMPDIR/${SAMPLE}_R2.ids"
    COM_IDS="$TMPDIR/${SAMPLE}_common.ids"

    seqkit seq -n "$R1" > "$FWD_IDS"
    seqkit seq -n "$R2_PATH" > "$REV_IDS"

    comm -12 <(cut -d " " -f1 "$FWD_IDS" | LC_ALL=C sort) \
             <(cut -d " " -f1 "$REV_IDS" | LC_ALL=C sort) \
             > "$COM_IDS"

    NCOM=$(wc -l < "$COM_IDS" | tr -d ' ')
    [[ "$NCOM" -eq 0 ]] && { echo "    [WARN] 0 IDs comunes en $SAMPLE"; rm -rf "$TMPDIR"; trap - EXIT; continue; }

    if [[ "$base" == *.gz ]]; then
      R1_OUT="${OUTDIR}/${SAMPLE}_R1_filt.fastq.gz"
      R2_OUT="${OUTDIR}/${SAMPLE}_R2_filt.fastq.gz"
    else
      R1_OUT="${OUTDIR}/${SAMPLE}_R1_filt.fastq"
      R2_OUT="${OUTDIR}/${SAMPLE}_R2_filt.fastq"
    fi

    seqkit grep -f "$COM_IDS" "$R1" > "$R1_OUT"
    seqkit grep -f "$COM_IDS" "$R2_PATH" > "$R2_OUT"

    echo "    [DONE] Guardados: $(basename "$R1_OUT"), $(basename "$R2_OUT")"
    rm -rf "$TMPDIR"
    trap - EXIT
  done
  shopt -u nullglob
done

echo "[FIN] Archivos filtrados creados en subcarpetas 'filtrados/'"
