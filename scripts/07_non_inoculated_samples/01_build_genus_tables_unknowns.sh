#!/usr/bin/env bash
set -euo pipefail

PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
META="${META:-$ROOT/data/07_non_inoculated_samples/metadata_13_muestras.tsv}"
OUTDIR="${PROJECT}/data/07_non_inoculated_samples/genus_unknowns_13samples"

mkdir -p "$OUTDIR"

PIPELINES=(
  Cuta_CA Fastp_CA T4_CA
  Cuta_F  Fastp_F  T4_F
)

echo "[INFO] Proyecto: $PROJECT"
echo "[INFO] Metadata: $META"
echo "[INFO] Salida:   $OUTDIR"

# =========================
# PR2
# género = nivel 8
# usa filtered_table_interest_MAIN.qza
# =========================
for p in "${PIPELINES[@]}"; do
  echo "========================================"
  echo "[PR2] Pipeline: $p"

  INDIR="${PROJECT}/data/05_taxonomy/${p}"
  TABLE_IN="${INDIR}/filtered_table_interest_MAIN.qza"
  TAX_IN="${INDIR}/taxonomy_nb_PR2.qza"

  if [[ ! -f "$TABLE_IN" ]]; then
    echo "[WARN] No existe tabla PR2: $TABLE_IN"
    continue
  fi
  if [[ ! -f "$TAX_IN" ]]; then
    echo "[WARN] No existe taxonomía PR2: $TAX_IN"
    continue
  fi

  mkdir -p "${OUTDIR}/PR2/${p}"

  qiime feature-table filter-samples \
    --i-table "$TABLE_IN" \
    --m-metadata-file "$META" \
    --o-filtered-table "${OUTDIR}/PR2/${p}/table_13samples.qza"

  qiime taxa collapse \
    --i-table "${OUTDIR}/PR2/${p}/table_13samples.qza" \
    --i-taxonomy "$TAX_IN" \
    --p-level 8 \
    --o-collapsed-table "${OUTDIR}/PR2/${p}/table_genus.qza"

  qiime tools export \
    --input-path "${OUTDIR}/PR2/${p}/table_genus.qza" \
    --output-path "${OUTDIR}/PR2/${p}/export"

  biom convert \
    -i "${OUTDIR}/PR2/${p}/export/feature-table.biom" \
    -o "${OUTDIR}/PR2/${p}/table_genus.tsv" \
    --to-tsv

  echo "[OK] PR2 $p"
done

# =========================
# SILVA132
# género = nivel 6
# usa filtered_table_interest_MAIN_SILVA.qza
# =========================
for p in "${PIPELINES[@]}"; do
  echo "========================================"
  echo "[SILVA132] Pipeline: $p"

  INDIR="${PROJECT}/data/05_taxonomy_SILVA132/${p}"
  TABLE_IN="${INDIR}/filtered_table_interest_MAIN_SILVA.qza"
  TAX_IN="${INDIR}/taxonomy_nb_SILVA132.qza"

  if [[ ! -f "$TABLE_IN" ]]; then
    echo "[WARN] No existe tabla SILVA132: $TABLE_IN"
    continue
  fi
  if [[ ! -f "$TAX_IN" ]]; then
    echo "[WARN] No existe taxonomía SILVA132: $TAX_IN"
    continue
  fi

  mkdir -p "${OUTDIR}/SILVA132/${p}"

  qiime feature-table filter-samples \
    --i-table "$TABLE_IN" \
    --m-metadata-file "$META" \
    --o-filtered-table "${OUTDIR}/SILVA132/${p}/table_13samples.qza"

  qiime taxa collapse \
    --i-table "${OUTDIR}/SILVA132/${p}/table_13samples.qza" \
    --i-taxonomy "$TAX_IN" \
    --p-level 6 \
    --o-collapsed-table "${OUTDIR}/SILVA132/${p}/table_genus.qza"

  qiime tools export \
    --input-path "${OUTDIR}/SILVA132/${p}/table_genus.qza" \
    --output-path "${OUTDIR}/SILVA132/${p}/export"

  biom convert \
    -i "${OUTDIR}/SILVA132/${p}/export/feature-table.biom" \
    -o "${OUTDIR}/SILVA132/${p}/table_genus.tsv" \
    --to-tsv

  echo "[OK] SILVA132 $p"
done

# =========================
# SILVA138custom
# género = nivel 6
# usa table.qza de 04_dada2_asvs + taxonomy_nb_SILVA138custom.qza
# =========================
for p in "${PIPELINES[@]}"; do
  echo "========================================"
  echo "[SILVA138custom] Pipeline: $p"

  TABLE_IN="${PROJECT}/data/04_dada2_asvs/${p}/table.qza"
  TAX_IN="${PROJECT}/data/05_taxonomy_SILVA138_custom/${p}/taxonomy_nb_SILVA138custom.qza"

  if [[ ! -f "$TABLE_IN" ]]; then
    echo "[WARN] No existe tabla DADA2 para custom: $TABLE_IN"
    continue
  fi
  if [[ ! -f "$TAX_IN" ]]; then
    echo "[WARN] No existe taxonomía custom: $TAX_IN"
    continue
  fi

  mkdir -p "${OUTDIR}/SILVA138custom/${p}"

  qiime feature-table filter-samples \
    --i-table "$TABLE_IN" \
    --m-metadata-file "$META" \
    --o-filtered-table "${OUTDIR}/SILVA138custom/${p}/table_13samples.qza"

  qiime taxa collapse \
    --i-table "${OUTDIR}/SILVA138custom/${p}/table_13samples.qza" \
    --i-taxonomy "$TAX_IN" \
    --p-level 6 \
    --o-collapsed-table "${OUTDIR}/SILVA138custom/${p}/table_genus.qza"

  qiime tools export \
    --input-path "${OUTDIR}/SILVA138custom/${p}/table_genus.qza" \
    --output-path "${OUTDIR}/SILVA138custom/${p}/export"

  biom convert \
    -i "${OUTDIR}/SILVA138custom/${p}/export/feature-table.biom" \
    -o "${OUTDIR}/SILVA138custom/${p}/table_genus.tsv" \
    --to-tsv

  echo "[OK] SILVA138custom $p"
done

echo "========================================"
echo "[DONE] Tablas de género generadas en: $OUTDIR"
