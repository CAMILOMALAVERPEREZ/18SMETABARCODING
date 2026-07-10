#!/usr/bin/env bash
set -euo pipefail

# ========= RUTAS =========
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IN_BASE="$ROOT/data/04_dada2_asvs"
OUT_BASE="$ROOT/data/05_taxonomy_SILVA132"

# Carpeta con el clasificador de SILVA v132 (¡tiene espacio!)
SILVA_DIR="${SILVA132_DIR:-$ROOT/data/external_classifiers/SILVA132}"
# Si quieres fijar el archivo exacto, descomenta y ajusta:
# CLASSIFIER="$SILVA_DIR/silva_132_99_nb_classifier.qza"

CONFIDENCE="0.9"
ENV21="qiime2-2021.8-py38"         # clasificar
ENV24="qiime2-amplicon-2024.10"    # exportar artefactos “nuevos” (p.ej. M&C)

# Metadata para barplots (toma el primero que exista)
META_1="$IN_BASE/metadata_qiime.tsv"
META_2="$IN_BASE/metadata.tsv"

# ========= CONDA =========
if command -v conda >/dev/null 2>&1; then
  source "$(conda info --base)/etc/profile.d/conda.sh"
else
  echo "[ERROR] conda was not found in PATH."
  exit 1
fi
conda_safe_activate() { set +u; conda activate "$1"; set -u; }

abspath() { python3 - "$1" <<'PY'
import os,sys; print(os.path.abspath(sys.argv[1]))
PY
}

# ========= DETECCIÓN CLASIFICADOR =========
if [[ -z "${CLASSIFIER:-}" ]]; then
  mapfile -t _cands < <(find "$SILVA_DIR" -maxdepth 1 -type f -name "*.qza" | sort)
  if (( ${#_cands[@]} == 0 )); then
    echo "[ERROR] No se encontró ningún .qza en: $SILVA_DIR"; exit 1
  fi
  CLASSIFIER="${_cands[0]}"
fi
[[ -f "$CLASSIFIER" ]] || { echo "[ERROR] Clasificador no existe: $CLASSIFIER"; exit 1; }
echo "[INFO] SILVA classifier: $(abspath "$CLASSIFIER")"

# ========= METADATA =========
if   [[ -f "$META_1" ]]; then METADATA="$META_1"
elif [[ -f "$META_2" ]]; then METADATA="$META_2"
else METADATA=""
fi
[[ -n "$METADATA" ]] && echo "[INFO] Metadata: $(abspath "$METADATA")" || echo "[WARN] Sin metadata: se omitirá taxa barplot."

mkdir -p "$OUT_BASE"

# Permite filtrar estrategias al vuelo: export ONLY="Cuta_CAN T3_F"
ONLY="${ONLY:-}"

# ========= LOOP =========
mapfile -t STRATS < <(find "$IN_BASE" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)
for S in "${STRATS[@]}"; do
  if [[ -n "$ONLY" ]]; then
    ok=false; for x in $ONLY; do [[ "$S" == "$x" ]] && ok=true; done; $ok || continue
  fi

  IN_DIR="$IN_BASE/$S"
  REP="$IN_DIR/rep_seqs.qza"
  TBL="$IN_DIR/table.qza"
  [[ -f "$REP" ]] || { echo "[WARN] Omito $S (no existe rep_seqs.qza)"; continue; }

  echo "=============================================="
  echo "=== Estrategia: $S"

  OUT="$OUT_BASE/$S"
  rm -rf "$OUT"; mkdir -p "$OUT"

  # 1) Export FASTA desde rep_seqs
  if [[ "$S" == *"M&C"* ]]; then
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV24"
    conda_safe_activate "$ENV24"
  else
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV21"
    conda_safe_activate "$ENV21"
  fi
  EXP="$OUT/export"; rm -rf "$EXP"; mkdir -p "$EXP"
  qiime tools export --input-path "$REP" --output-path "$EXP" >/dev/null 2>&1
  [[ -f "$EXP/dna-sequences.fasta" ]] || { echo "[ERROR] No se exportó dna-sequences.fasta en $S"; continue; }

  # 2) Import FASTA + clasificar con SILVA (siempre en 2021)
  echo "[STEP] Clasificar con SILVA v132 en $ENV21 (confidence=$CONFIDENCE)"
  conda_safe_activate "$ENV21"

  REP21="$OUT/rep_seqs_from_fasta_2021.qza"
  TAX="$OUT/taxonomy_nb_SILVA132.qza"
  TAXV="$OUT/taxonomy_nb_SILVA132.qzv"

  qiime tools import \
    --type 'FeatureData[Sequence]' \
    --input-path "$EXP/dna-sequences.fasta" \
    --output-path "$REP21"

  qiime feature-classifier classify-sklearn \
    --i-classifier "$CLASSIFIER" \
    --i-reads "$REP21" \
    --p-confidence "$CONFIDENCE" \
    --o-classification "$TAX"

  qiime metadata tabulate \
    --m-input-file "$TAX" \
    --o-visualization "$TAXV"

  # TSV legible
  qiime tools export --input-path "$TAX" --output-path "$OUT/export_tax" >/dev/null 2>&1
  [[ -f "$OUT/export_tax/taxonomy.tsv" ]] && mv -f "$OUT/export_tax/taxonomy.tsv" "$OUT/taxonomy_nb_SILVA132.tsv"

  echo "[OK] Taxonomía SILVA lista: $TAX"

  # 3) Barplot (si hay metadata y table.qza)
  if [[ -n "$METADATA" && -f "$TBL" ]]; then
    if [[ "$S" == *"M&C"* ]]; then
      echo "[STEP] Taxa barplot en $ENV24 (table.qza 2024)"
      conda_safe_activate "$ENV24"
    else
      echo "[STEP] Taxa barplot en $ENV21"
      conda_safe_activate "$ENV21"
    fi
    BAR="$OUT/taxa_barplot_nb_SILVA132.qzv"
    qiime taxa barplot \
      --i-table "$TBL" \
      --i-taxonomy "$TAX" \
      --m-metadata-file "$METADATA" \
      --o-visualization "$BAR"
    echo "[OK] Barplot: $BAR"
  else
    echo "[INFO] Sin barplot para $S (falta metadata o table.qza)"
  fi
done

echo
echo "[DONE] Clasificación SILVA v132 (Naive Bayes, confidence=$CONFIDENCE)."
echo "[OUT ] Resultados en: $(abspath "$OUT_BASE")"
