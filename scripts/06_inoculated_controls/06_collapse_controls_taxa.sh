#!/usr/bin/env bash
# Ojo: NO usamos -e para que no se detenga todo el script si algo falla
set -uo pipefail

########################################
#  CONFIGURACIÓN GENERAL
########################################

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DATA_DIR="${BASE_DIR}/data"
OUT_DIR="${DATA_DIR}/06_taxa_controls"

# Lista de pipelines (no necesitas editarla)
PIPELINES=(
  "Cuta_CA"
  "Cuta_CAN"
  "Cuta_F"
  "Cuta_M&C"
  "Cuta_R"
  "Fastp_CA"
  "Fastp_CAN"
  "Fastp_F"
  "Fastp_M&C"
  "Fastp_R"
  "T3_CA"
  "T3_CAN"
  "T3_F"
  "T3_M&C"
  "T3_R"
  "T4_CA"
  "T4_CAN"
  "T4_F"
  "T4_M&C"
  "T4_R"
)

# Comprobar que qiime está disponible en el entorno actual
if ! command -v qiime >/dev/null 2>&1; then
  echo "[ERROR] 'qiime' no está en el PATH. Activa primero tu entorno QIIME2, por ejemplo:"
  echo "        conda activate qiime2-amplicon-2024.10"
  exit 1
fi

########################################
#  FUNCIONES AUXILIARES
########################################

process_pipeline() {
  local pipe="$1"

  echo "------------------------------------------------------------"
  echo "[PIPELINE] ${pipe}"

  ##############################
  # PR2  → data/05_taxonomy/<pipeline>/
  ##############################
  local tax_dir_pr2="${DATA_DIR}/05_taxonomy/${pipe}"
  local table_controls_pr2="${tax_dir_pr2}/filtered_table_interest_CONTROLS.qza"
  local tax_pr2="${tax_dir_pr2}/taxonomy_nb_PR2.qza"

  if [[ -d "${tax_dir_pr2}" && -f "${table_controls_pr2}" && -f "${tax_pr2}" ]]; then
    echo "  [PR2]  Procesando ${pipe}"
    echo "         Directorio: ${tax_dir_pr2}"

    # PR2: género = nivel 8, especie = nivel 9
    if qiime taxa collapse \
        --i-table "${table_controls_pr2}" \
        --i-taxonomy "${tax_pr2}" \
        --p-level 8 \
        --o-collapsed-table "${tax_dir_pr2}/table_genus_controls_PR2.qza"; then

      local out_genus_pr2="${OUT_DIR}/${pipe}/PR2/genus"
      mkdir -p "${out_genus_pr2}"

      qiime tools export \
        --input-path "${tax_dir_pr2}/table_genus_controls_PR2.qza" \
        --output-path "${out_genus_pr2}"

      if [[ -f "${out_genus_pr2}/feature-table.biom" ]]; then
        biom convert -i "${out_genus_pr2}/feature-table.biom" \
                     -o "${out_genus_pr2}/table_genus.tsv" \
                     --to-tsv
      else
        echo "  [PR2]  WARNING: no se encontró feature-table.biom (género) en ${pipe}"
      fi
    else
      echo "  [PR2]  WARNING: fallo en taxa collapse (género, nivel 8) para ${pipe}. Se continúa con el resto."
    fi

    if qiime taxa collapse \
        --i-table "${table_controls_pr2}" \
        --i-taxonomy "${tax_pr2}" \
        --p-level 9 \
        --o-collapsed-table "${tax_dir_pr2}/table_species_controls_PR2.qza"; then

      local out_species_pr2="${OUT_DIR}/${pipe}/PR2/species"
      mkdir -p "${out_species_pr2}"

      qiime tools export \
        --input-path "${tax_dir_pr2}/table_species_controls_PR2.qza" \
        --output-path "${out_species_pr2}"

      if [[ -f "${out_species_pr2}/feature-table.biom" ]]; then
        biom convert -i "${out_species_pr2}/feature-table.biom" \
                     -o "${out_species_pr2}/table_species.tsv" \
                     --to-tsv
      else
        echo "  [PR2]  WARNING: no se encontró feature-table.biom (especie) en ${pipe}"
      fi
    else
      echo "  [PR2]  WARNING: fallo en taxa collapse (especie, nivel 9) para ${pipe}. Se continúa con el resto."
    fi

  else
    echo "  [PR2]  Saltando ${pipe}: no se encontraron ${tax_dir_pr2} o archivos necesarios."
  fi

  ##############################
  # SILVA132 → data/05_taxonomy_SILVA132/<pipeline>/
  ##############################
  local tax_dir_silva="${DATA_DIR}/05_taxonomy_SILVA132/${pipe}"
  local table_controls_silva="${tax_dir_silva}/filtered_table_interest_CONTROLS_SILVA.qza"
  local tax_silva="${tax_dir_silva}/taxonomy_nb_SILVA132.qza"

  if [[ -d "${tax_dir_silva}" && -f "${table_controls_silva}" && -f "${tax_silva}" ]]; then
    echo "  [SILVA] Procesando ${pipe}"
    echo "          Directorio: ${tax_dir_silva}"

    # SILVA: género = nivel 6
    if qiime taxa collapse \
        --i-table "${table_controls_silva}" \
        --i-taxonomy "${tax_silva}" \
        --p-level 6 \
        --o-collapsed-table "${tax_dir_silva}/table_genus_controls_SILVA132.qza"; then

      local out_genus_silva="${OUT_DIR}/${pipe}/SILVA132/genus"
      mkdir -p "${out_genus_silva}"

      qiime tools export \
        --input-path "${tax_dir_silva}/table_genus_controls_SILVA132.qza" \
        --output-path "${out_genus_silva}"

      if [[ -f "${out_genus_silva}/feature-table.biom" ]]; then
        biom convert -i "${out_genus_silva}/feature-table.biom" \
                     -o "${out_genus_silva}/table_genus.tsv" \
                     --to-tsv
      else
        echo "  [SILVA] WARNING: no se encontró feature-table.biom (género) en ${pipe}"
      fi
    else
      echo "  [SILVA] WARNING: fallo en taxa collapse (género, nivel 6) para ${pipe}. Se continúa con el resto."
    fi

    # SILVA: especie = nivel 7 → puede fallar si la taxonomía solo llega hasta 6
    if qiime taxa collapse \
        --i-table "${table_controls_silva}" \
        --i-taxonomy "${tax_silva}" \
        --p-level 7 \
        --o-collapsed-table "${tax_dir_silva}/table_species_controls_SILVA132.qza"; then

      local out_species_silva="${OUT_DIR}/${pipe}/SILVA132/species"
      mkdir -p "${out_species_silva}"

      qiime tools export \
        --input-path "${tax_dir_silva}/table_species_controls_SILVA132.qza" \
        --output-path "${out_species_silva}"

      if [[ -f "${out_species_silva}/feature-table.biom" ]]; then
        biom convert -i "${out_species_silva}/feature-table.biom" \
                     -o "${out_species_silva}/table_species.tsv" \
                     --to-tsv
      else
        echo "  [SILVA] WARNING: no se encontró feature-table.biom (especie) en ${pipe}"
      fi
    else
      echo "  [SILVA] WARNING: no se pudo colapsar a nivel 7 (especie) para ${pipe}."
      echo "                 Probablemente la taxonomía solo llega a nivel 6."
      echo "                 Se continúa SOLO con género para SILVA en este pipeline."
    fi

  else
    echo "  [SILVA] Saltando ${pipe}: no se encontraron ${tax_dir_silva} o archivos necesarios."
  fi
}

########################################
#  PROGRAMA PRINCIPAL
########################################

echo "=== Colapsando y exportando tablas de CONTROLES (PR2 y SILVA132) ==="
echo "Base: ${BASE_DIR}"
echo

for pipe in "${PIPELINES[@]}"; do
  process_pipeline "${pipe}"
done

echo
echo "=== Listo. TSV en: ${OUT_DIR} ==="
