#!/usr/bin/env bash
set -euo pipefail

# ========= RUTAS =========
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IN_BASE="$ROOT/data/04_dada2_asvs"
OUT_BASE="$ROOT/data/05_taxonomy"
CLASSIFIER="${PR2_CLASSIFIER:-$ROOT/data/external_classifiers/pr2_classifier.qza}"
CONFIDENCE="0.9"

# Dos entornos: 2021 (clasificar) y 2024 (artefactos nuevos tipo M&C)
ENV21="qiime2-2021.8-py38"
ENV24="qiime2-amplicon-2024.10"

# Metadata (para barplots): usa la primera que exista
META_1="$IN_BASE/metadata_qiime.tsv"
META_2="$IN_BASE/metadata.tsv"
META_3="$IN_BASE/metadatacontrol.txt"

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

mkdir -p "$OUT_BASE"

[[ -f "$CLASSIFIER" ]] || { echo "[ERROR] No encuentro el clasificador PR2: $CLASSIFIER"; exit 1; }
echo "[INFO] Classifier: $(abspath "$CLASSIFIER")"

# Metadata (opcional)
METADATA=""
for m in "$META_1" "$META_2" "$META_3"; do
  if [[ -f "$m" ]]; then METADATA="$m"; break; fi
done
if [[ -n "$METADATA" ]]; then
  echo "[INFO] Metadata: $(abspath "$METADATA")"
else
  echo "[WARN] Sin metadata: se omitirá taxa barplot."
fi

# ========= ESTRATEGIAS =========
mapfile -t STRATS < <(find "$IN_BASE" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)

for S in "${STRATS[@]}"; do
  [[ "$S" == "subset_nb" ]] && continue

  IN_DIR="$IN_BASE/$S"
  REP="$IN_DIR/rep_seqs.qza"
  TBL="$IN_DIR/table.qza"

  if [[ ! -f "$REP" ]]; then
    echo "[WARN] Omito $S (no existe rep_seqs.qza)"; continue
  fi

  echo "=============================================="
  echo "=== Estrategia: $S"

  OUT="$OUT_BASE/$S"
  rm -rf "$OUT"; mkdir -p "$OUT"

  # 1) Export FASTA desde rep_seqs
  if [[ "$S" == *"M&C"* ]]; then
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV24 (artefacto 'nuevo')"
    conda_safe_activate "$ENV24"
  else
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV21"
    conda_safe_activate "$ENV21"
  fi
  EXP="$OUT/export"
  rm -rf "$EXP"; mkdir -p "$EXP"
  qiime tools export --input-path "$REP" --output-path "$EXP" >/dev/null 2>&1
  [[ -f "$EXP/dna-sequences.fasta" ]] || { echo "[ERROR] No se exportó dna-sequences.fasta en $S"; continue; }

  # 2) Importar FASTA (2021) y clasificar con PR2
  echo "[STEP] Clasificar con PR2 en $ENV21 (confidence=$CONFIDENCE)"
  conda_safe_activate "$ENV21"
  REP21="$OUT/rep_seqs_from_fasta_2021.qza"
  TAX="$OUT/taxonomy_nb_PR2.qza"
  TAXV="$OUT/taxonomy_nb_PR2.qzv"

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

  # Export rápido a TSV
  qiime tools export --input-path "$TAX" --output-path "$OUT/export_tax" >/dev/null 2>&1 || true
  [[ -f "$OUT/export_tax/taxonomy.tsv" ]] && mv -f "$OUT/export_tax/taxonomy.tsv" "$OUT/taxonomy_nb_PR2.tsv" || true

  echo "[OK] Taxonomía PR2 lista: $TAX"

  # 3) Barplot (si hay metadata y table.qza)
  if [[ -n "${METADATA:-}" && -f "$TBL" ]]; then
    if [[ "$S" == *"M&C"* ]]; then
      echo "[STEP] Taxa barplot en $ENV24 (table.qza de 2024)"
      conda_safe_activate "$ENV24"
    else
      echo "[STEP] Taxa barplot en $ENV21"
      conda_safe_activate "$ENV21"
    fi
    BAR="$OUT/taxa_barplot_nb_PR2.qzv"
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
echo "[DONE] Clasificación PR2 (Naive Bayes, confidence=$CONFIDENCE) para todas las estrategias."
echo "[OUT ] Resultados en: $(abspath "$OUT_BASE")"
