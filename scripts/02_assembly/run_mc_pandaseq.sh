#!/bin/bash
# --------------------------------------------
# SCRIPT: run_mc_pandaseq.sh
# USO: Hace Merge a lecturas que tienen como minimo 10 pb similares, el resto concatena y al final lo unifica en una sola carpeta
# AUTOR: Camilo Malaver Pérez
# FECHA: 2025-08-22
# --------------------------------------------
#!/usr/bin/env bash
set -euo pipefail

# ========= CONFIG =========
PROJ="/home/camilomalaver/18SMETABARCODING_local"
IN_BASE="${PROJ}/data/02_filtered"
OUT_BASE="${PROJ}/data/03_assembled"

# Subcarpetas de salida por filtro (abreviaturas pedidas)
declare -A OUTMAP=(
  ["cutadapt"]="Cuta_M&C"
  ["fastp"]="Fastp_M&C"
  ["trimmomatic_win4"]="T4_M&C"
  ["trimmomatic_win3"]="T3_M&C"
)

# Mínimo solapamiento para MERGE (PANDAseq -o)
MIN_OVL=10

# Conda env con pandaseq disponible
CONDA_ENV="qiime2-amplicon-2024.10"
# ==========================

echo "[INFO] Activando entorno con PANDAseq: ${CONDA_ENV}"
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate "${CONDA_ENV}"

mkdir -p "${OUT_BASE}"

# Procesar solo los cuatro filtros solicitados
for FILTER in cutadapt fastp trimmomatic_win4 trimmomatic_win3; do
  IN_DIR="${IN_BASE}/${FILTER}/filtrados"
  OUT_DIR="${OUT_BASE}/${OUTMAP[$FILTER]}"

  if [[ ! -d "${IN_DIR}" ]]; then
    echo "[WARN] No existe ${IN_DIR}. Se omite ${FILTER}."
    continue
  fi
  mkdir -p "${OUT_DIR}"

  echo "==========================================================="
  echo "[INFO] Filtro: ${FILTER}"
  echo "[INFO]    Entrada : ${IN_DIR}"
  echo "[INFO]    Salida  : ${OUT_DIR}"
  echo "==========================================================="

  shopt -s nullglob
  # Buscar todos los R1 emparejados producidos por tu paso anterior
  for R1 in "${IN_DIR}"/*_R1_filt.fastq "${IN_DIR}"/*_R1_filt.fastq.gz; do
    base="$(basename "$R1")"
    # Derivar R2 correlativo
    R2="${R1/_R1_filt/_R2_filt}"
    if [[ ! -f "$R2" ]]; then
      echo "  [WARN] Sin par para: $(basename "$R1")  -> no existe $(basename "$R2"). Se omite."
      continue
    fi

    SAMPLE="${base%%_R1_filt*}"
    echo "  [OK] Procesando muestra: ${SAMPLE}"

    # Salidas por muestra
    MERGED="${OUT_DIR}/${SAMPLE}_merged.fastq"
    CONCAT="${OUT_DIR}/${SAMPLE}_concat.fastq"
    COMBINED="${OUT_DIR}/${SAMPLE}_combined.fastq.gz"

    # Manejo de entrada (si vienen .gz, descomprimir a temporales)
    TMPDIR="$(mktemp -d)"
    trap 'rm -rf "$TMPDIR"' EXIT

    if [[ "$R1" == *.gz ]]; then
      R1_IN="${TMPDIR}/${SAMPLE}_R1.tmp.fastq"
      R2_IN="${TMPDIR}/${SAMPLE}_R2.tmp.fastq"
      gzip -cd "$R1" > "$R1_IN"
      gzip -cd "$R2" > "$R2_IN"
    else
      R1_IN="$R1"
      R2_IN="$R2"
    fi

    # Ejecutar PANDAseq:
    # -f FWD -r REV
    # -o MIN_OVL    (solapamiento mínimo para MERGE)
    # -F            (forzar salida fastq)
    # -w MERGED     (salida merged)
    # -U CONCAT     (salida concatenada cuando no hay merge)
    pandaseq \
      -f "$R1_IN" \
      -r "$R2_IN" \
      -o ${MIN_OVL} \
      -F \
      -w "$MERGED" \
      -U "$CONCAT"

    # Unir merged + concat en un solo archivo comprimido (resultado M&C)
    cat "$MERGED" "$CONCAT" | gzip -c > "$COMBINED"

    echo "    [DONE] $(basename "$MERGED"), $(basename "$CONCAT") y $(basename "$COMBINED")"

    # Limpiar temporales
    rm -rf "$TMPDIR"
    trap - EXIT
  done
  shopt -u nullglob
done

echo "[OK] Ensamblaje M&C finalizado. Resultados en: ${OUT_BASE}"

