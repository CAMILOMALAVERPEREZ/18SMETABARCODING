#!/usr/bin/env bash
set -euo pipefail

# ========= RUTAS =========
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IN_BASE="$ROOT/data/04_dada2_asvs"
OUT_BASE="$ROOT/data/05_taxonomy_SILVA138_custom"

CLASSIFIER="$ROOT/data/02_custom_db/silva_18S_groups/silva-138.2-groups-V4V5-min400-clean-v2-classifier.qza"

CONFIDENCE="0.9"
ENV21="qiime2-2021.8-py38"
ENV24="qiime2-amplicon-2024.10"

# Metadata para barplots
META_1="$IN_BASE/metadata_qiime.tsv"
META_2="$IN_BASE/metadata.tsv"
META_3="$IN_BASE/metadatacontrol.txt"

# ========= CONDA =========
source "$(conda info --base)/etc/profile.d/conda.sh"

conda_safe_activate() {
  set +u
  conda activate "$1"
  set -u
}

abspath() {
  python3 - "$1" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
}

# ========= VERIFICACIONES =========
mkdir -p "$OUT_BASE"

[[ -f "$CLASSIFIER" ]] || {
  echo "[ERROR] Clasificador no existe: $CLASSIFIER"
  exit 1
}
echo "[INFO] Custom SILVA138 classifier: $(abspath "$CLASSIFIER")"

# ========= METADATA =========
METADATA=""
for m in "$META_1" "$META_2" "$META_3"; do
  if [[ -f "$m" ]]; then
    METADATA="$m"
    break
  fi
done

if [[ -n "$METADATA" ]]; then
  echo "[INFO] Metadata: $(abspath "$METADATA")"
else
  echo "[WARN] Sin metadata: se omitirá taxa barplot."
fi

ONLY="${ONLY:-}"

# ========= LOOP =========
mapfile -t STRATS < <(find "$IN_BASE" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)

for S in "${STRATS[@]}"; do
  [[ "$S" == "subset_nb" ]] && continue

  if [[ -n "$ONLY" ]]; then
    ok=false
    for x in $ONLY; do
      [[ "$S" == "$x" ]] && ok=true
    done
    $ok || continue
  fi

  IN_DIR="$IN_BASE/$S"
  REP="$IN_DIR/rep_seqs.qza"
  TBL="$IN_DIR/table.qza"

  [[ -f "$REP" ]] || {
    echo "[WARN] Omito $S (no existe rep_seqs.qza)"
    continue
  }

  echo "=============================================="
  echo "=== Estrategia: $S"

  OUT="$OUT_BASE/$S"
  rm -rf "$OUT"
  mkdir -p "$OUT"

  # 1) Export FASTA desde rep_seqs
  if [[ "$S" == *"M&C"* ]]; then
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV24"
    conda_safe_activate "$ENV24"
  else
    echo "[STEP] Export FASTA (rep_seqs) usando $ENV21"
    conda_safe_activate "$ENV21"
  fi

  EXP="$OUT/export"
  rm -rf "$EXP"
  mkdir -p "$EXP"

  qiime tools export \
    --input-path "$REP" \
    --output-path "$EXP" >/dev/null 2>&1

  [[ -f "$EXP/dna-sequences.fasta" ]] || {
    echo "[ERROR] No se exportó dna-sequences.fasta en $S"
    continue
  }

  # 2) Import FASTA + clasificar
  echo "[STEP] Clasificar con SILVA138_custom en $ENV24 (confidence=$CONFIDENCE)"
  conda_safe_activate "$ENV24"

  REP21="$OUT/rep_seqs_from_fasta_2021.qza"
  TAX="$OUT/taxonomy_nb_SILVA138custom.qza"
  TAXV="$OUT/taxonomy_nb_SILVA138custom.qzv"

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

  qiime tools export \
    --input-path "$TAX" \
    --output-path "$OUT/export_tax" >/dev/null 2>&1 || true

  [[ -f "$OUT/export_tax/taxonomy.tsv" ]] && mv -f "$OUT/export_tax/taxonomy.tsv" "$OUT/taxonomy_nb_SILVA138custom.tsv" || true

  echo "[OK] Taxonomía SILVA138 custom lista: $TAX"

  # 3) Barplot
    if [[ -n "$METADATA" && -f "$TBL" ]]; then
    echo "[STEP] Taxa barplot en $ENV24"
    conda_safe_activate "$ENV24"

    BAR="$OUT/taxa_barplot_nb_SILVA138custom.qzv"
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
echo "[DONE] Clasificación SILVA138 custom (Naive Bayes, confidence=$CONFIDENCE)."
echo "[OUT ] Resultados en: $(abspath "$OUT_BASE")"
