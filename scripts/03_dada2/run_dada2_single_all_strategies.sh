#!/usr/bin/env bash
# =========================================================
# QIIME2 DADA2 (single-end) para 12 estrategias ensambladas
# Activa entorno QIIME2 distinto según estrategia:
#   - CA/CAN  -> QENV_CA_CAN  (e.g., qiime2-2021.8-py38)
#   - M&C     -> QENV_MC      (e.g., qiime2-amplicon-2024.10)
# No recorta (trunc=0, trim-left=0), elimina quimeras.
# =========================================================
set -euo pipefail

# --------- AJUSTA ESTOS NOMBRES DE ENTORNO ---------
QENV_CA_CAN="qiime2-2021.8-py38"
QENV_MC="qiime2-amplicon-2024.10"
# ---------------------------------------------------

# Parámetros DADA2 (conserva longitudes variables)
THREADS=0
TRIM_LEFT=0
TRUNC_LEN=0
TRUNC_Q=0
MAX_EE=2
CHIMERA="consensus"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ASM="${ROOT}/data/03_assembled"
OUT_BASE="${ROOT}/data/04_dada2_asvs"

STRATS=(
  "Cuta_CA" "Fastp_CA" "T3_CA" "T4_CA"
  "Cuta_CAN" "Fastp_CAN" "T3_CAN" "T4_CAN"
  "Cuta_M&C" "Fastp_M&C" "T3_M&C" "T4_M&C"
)

activate_env() {
  local envname="$1"
  if command -v conda >/dev/null 2>&1; then
    # Desactivar 'nounset' mientras corre la activación de conda
    set +u
    # shellcheck disable=SC1091
    source "$(conda info --base)/etc/profile.d/conda.sh"
    conda deactivate >/dev/null 2>&1 || true
    conda activate "$envname"
    set -u
    echo "[ENV] Activado: $envname"
    # Asegurar que 'qiime' está disponible
    if ! command -v qiime >/dev/null 2>&1; then
      echo "[ERROR] 'qiime' no está en PATH tras activar '$envname'." >&2
      exit 1
    fi
  else
    echo "[WARN] conda no encontrado; asumo 'qiime' en PATH (env: $envname)"
  fi
}

abs_path() { python3 - "$1" << 'PY'
import os,sys
print(os.path.abspath(sys.argv[1]))
PY
}

make_manifest_single() {
  local strat_dir="$1"
  local manifest="$2"

  echo -e "sample-id\tabsolute-filepath\tdirection" > "$manifest"
  shopt -s nullglob

  # M&C prioriza *_combined.fastq(.gz); si no existe, lo genera desde merged+concat
  if [[ "$(basename "$strat_dir")" == *"M&C" ]]; then
    local files=( "$strat_dir"/*_combined.fastq "$strat_dir"/*_combined.fastq.gz )
    if (( ${#files[@]} == 0 )); then
      local merged=( "$strat_dir"/*_merged.fastq "$strat_dir"/*_merged.fastq.gz )
      for m in "${merged[@]}"; do
        local base="$(basename "$m")"
        local sample="${base%_merged.fastq}"
        sample="${sample%_merged.fastq.gz}"
        local c1="$strat_dir/${sample}_concat.fastq"
        local c2="$strat_dir/${sample}_concat.fastq.gz"
        local combined="$strat_dir/${sample}_combined.fastq.gz"
        if [[ -f "$c1" || -f "$c2" ]]; then
          echo "[INFO] Generando combinado: $(basename "$combined")"
          if [[ "$m" == *.gz ]]; then zcat "$m" > "$combined"; else cat "$m" | gzip -c > "$combined"; fi
          if [[ -f "$c1" ]]; then cat "$c1" | gzip -c >> "$combined"; else zcat "$c2" >> "$combined"; fi
        fi
      done
      files=( "$strat_dir"/*_combined.fastq "$strat_dir"/*_combined.fastq.gz )
    fi
  else
    local files=( "$strat_dir"/*_concat "$strat_dir"/*_concat.fastq "$strat_dir"/*_concat.fastq.gz )
  fi

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    local base="$(basename "$f")"
    local sample="$base"
    sample="${sample%_concat.fastq.gz}"; sample="${sample%_concat.fastq}"; sample="${sample%_concat}"
    sample="${sample%_combined.fastq.gz}"; sample="${sample%_combined.fastq}"
    local ap="$(abs_path "$f")"
    echo -e "${sample}\t${ap}\tforward" >> "$manifest"
  done

  shopt -u nullglob
}

run_one_strat() {
  local strat="$1"
  local in_dir="${ASM}/${strat}"
  local out_dir="${OUT_BASE}/${strat}"
  local man="${out_dir}/manifest_single_end.tsv"
  local qza="${out_dir}/sequences_SE.qza"

  [[ -d "$in_dir" ]] || { echo "[WARN] No existe: $in_dir"; return; }
  mkdir -p "$out_dir"

  # Selección de entorno según estrategia
  if [[ "$strat" == *"M&C" ]]; then
    activate_env "$QENV_MC"
  else
    activate_env "$QENV_CA_CAN"
  fi

  echo "[*] Manifest: $strat"
  make_manifest_single "$in_dir" "$man"
  local n_lines; n_lines=$(($(wc -l < "$man") - 1))
  (( n_lines > 0 )) || { echo "[WARN] Manifest vacío: $strat"; return; }

  echo "[*] Import: $strat"
  qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path "$man" \
    --input-format SingleEndFastqManifestPhred33V2 \
    --output-path "$qza"

  echo "[*] DADA2: $strat"
  if qiime dada2 denoise-single \
      --i-demultiplexed-seqs "$qza" \
      --p-trim-left "$TRIM_LEFT" \
      --p-trunc-len "$TRUNC_LEN" \
      --p-trunc-q "$TRUNC_Q" \
      --p-max-ee "$MAX_EE" \
      --p-chimera-method "$CHIMERA" \
      --p-n-threads "$THREADS" \
      --o-table "${out_dir}/table.qza" \
      --o-representative-sequences "${out_dir}/rep_seqs.qza" \
      --o-denoising-stats "${out_dir}/denoise_stats.qza" \
      >/dev/null 2>&1; then
    :
  else
    echo "[INFO] Reintentando con flags mínimos (compatibilidad)."
    qiime dada2 denoise-single \
      --i-demultiplexed-seqs "$qza" \
      --p-trim-left "$TRIM_LEFT" \
      --p-trunc-len "$TRUNC_LEN" \
      --p-max-ee "$MAX_EE" \
      --p-chimera-method "$CHIMERA" \
      --o-table "${out_dir}/table.qza" \
      --o-representative-sequences "${out_dir}/rep_seqs.qza" \
      --o-denoising-stats "${out_dir}/denoise_stats.qza"
  fi

  echo "[*] Visualizaciones: $strat"
  qiime feature-table summarize \
    --i-table "${out_dir}/table.qza" \
    --o-visualization "${out_dir}/table_summary.qzv"

  qiime feature-table tabulate-seqs \
    --i-data "${out_dir}/rep_seqs.qza" \
    --o-visualization "${out_dir}/rep_seqs.qzv"

  qiime metadata tabulate \
    --m-input-file "${out_dir}/denoise_stats.qza" \
    --o-visualization "${out_dir}/denoise_stats.qzv"

  echo "[OK] $strat listo."
}

main() {
  echo "[INFO] IN : $ASM"
  echo "[INFO] OUT: $OUT_BASE"
  for S in "${STRATS[@]}"; do
    echo "=============================================="
    echo ">>> $S"
    run_one_strat "$S"
  done
  echo "=============================================="
  echo "[DONE] DADA2 single-end en todas las estrategias."
}

main "$@"
