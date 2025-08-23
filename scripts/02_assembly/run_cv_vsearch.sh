#!/bin/bash
# --------------------------------------------
# SCRIPT: run_cv_vsearch.sh
# USO: Concatena todas las secuencias filtradas/emparejadas usando la herramienta Vsearch y dejando como Ns entre lectura F Y R
# AUTOR: Camilo Malaver Pérez
# FECHA: 2025-08-22
# --------------------------------------------

#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
PROJ="/home/camilomalaver/18SMETABARCODING_local"
IN_BASE="${PROJ}/data/02_filtered"
OUT_BASE="${PROJ}/data/03_assembled"

# Filtros -> subcarpetas de salida
declare -A OUTMAP=(
  ["cutadapt"]="Cuta_CV"
  ["fastp"]="Fastp_CV"
  ["trimmomatic_win3"]="T3_CV"
  ["trimmomatic_win4"]="T4_CV"
)

# Entorno (opcional): si vsearch está en tu PATH, no hace falta activar nada
CONDA_ENV="qiime2-amplicon-2024.10"
# ==========================

# Activa conda si quieres usar el vsearch del entorno
if command -v conda >/dev/null 2>&1; then
  source "$(conda info --base)/etc/profile.d/conda.sh"
  conda activate "${CONDA_ENV}" || true
fi

# Chequeo de vsearch
command -v vsearch >/dev/null 2>&1 || { echo "[ERROR] vsearch no está en PATH"; exit 1; }

mkdir -p "${OUT_BASE}"

for FILTER in cutadapt fastp trimmomatic_win3 trimmomatic_win4; do
  IN_DIR="${IN_BASE}/${FILTER}/filtrados"
  OUT_DIR="${OUT_BASE}/${OUTMAP[$FILTER]}"

  if [[ ! -d "${IN_DIR}" ]]; then
    echo "[WARN] No existe ${IN_DIR}. Omitiendo ${FILTER}."
    continue
  fi
  mkdir -p "${OUT_DIR}"

  echo "==========================================================="
  echo "[INFO] Filtro: ${FILTER}"
  echo "[INFO]    Entrada : ${IN_DIR}"
  echo "[INFO]    Salida  : ${OUT_DIR}"
  echo "==========================================================="

  shopt -s nullglob
  for R1 in "${IN_DIR}"/*_R1_filt.fastq "${IN_DIR}"/*_R1_filt.fastq.gz; do
    base="$(basename "$R1")"
    R2="${R1/_R1_filt/_R2_filt}"
    [[ -f "$R2" ]] || { echo "  [WARN] Sin par para $(basename "$R1")"; continue; }

    SAMPLE="${base%%_R1_filt*}"
    OUT_FASTQ="${OUT_DIR}/${SAMPLE}_concat_CV_vsearch.fastq"

    echo "  [OK] Concatenando (VSEARCH join) muestra: ${SAMPLE}"

    vsearch \
      --fastq_join "$R1" \
      --reverse "$R2" \
      --fastqout "$OUT_FASTQ"

    if [[ ! -s "$OUT_FASTQ" ]]; then
      echo "    [WARN] Archivo vacío: $(basename "$OUT_FASTQ"). Revisa entradas/IDs."
    else
      echo "    [DONE] $(basename "$OUT_FASTQ")"
    fi
  done
  shopt -u nullglob
done

echo "[OK] Concatenación CV con VSEARCH finalizada: ${OUT_BASE}"
