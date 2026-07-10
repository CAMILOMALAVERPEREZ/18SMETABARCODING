#!/usr/bin/env bash
# DADA2 single-end para lecturas F y R a partir de data/02_filtered/{cutadapt,fastp,trimmomatic_win3,trimmomatic_win4}
# Salida: data/04_dada2_asvs/{Cuta_F,Cuta_R,Fastp_F,Fastp_R,T3_F,T3_R,T4_F,T4_R}
# Requiere: entorno QIIME2 activo

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
IN_BASE="$ROOT/data/02_filtered"
OUT_BASE="$ROOT/data/04_dada2_asvs"

# Mapeo: carpeta de entrada -> prefijo de estrategia de salida
declare -A TAG=( ["cutadapt"]="Cuta" ["fastp"]="Fastp" ["trimmomatic_win3"]="T3" ["trimmomatic_win4"]="T4" )

# Función para obtener ruta absoluta (compatible WSL)
abspath() { python3 - "$1" <<'PY'
import os,sys
p=sys.argv[1]
print(os.path.abspath(p))
PY
}

# Genera manifest SingleEnd para un conjunto de archivos (pattern) y ejecuta DADA2
run_one() {
  local in_dir="$1"       # p.ej. /.../data/02_filtered/cutadapt
  local label="$2"        # p.ej. Cuta
  local which="$3"        # "F" o "R"
  local pattern           # patrón para R1 o R2
  if [[ "$which" == "F" ]]; then pattern="*_R1*"; else pattern="*_R2*"; fi

  [[ -d "$in_dir" ]] || { echo "[WARN] No existe $in_dir, omito."; return; }

  # Salida por estrategia
  local OUT="$OUT_BASE/${label}_${which}"
  mkdir -p "$OUT"

  # Manifest
  local MAN="$OUT/manifest_single_end.tsv"
  echo -e "sample-id\tabsolute-filepath\tdirection" > "$MAN"

  shopt -s nullglob
  local files=( "$in_dir"/$pattern )
  shopt -u nullglob

  if [[ ${#files[@]} -eq 0 ]]; then
    echo "[WARN] Sin archivos para $label/$which en $in_dir (pattern $pattern)."
    return
  fi

  # Construir manifest: sample-id = prefijo antes del primer "_"
  for f in "${files[@]}"; do
    base="$(basename "$f")"
    sample="${base%%_*}"
    abs="$(abspath "$f")"
    echo -e "${sample}\t${abs}\tforward" >> "$MAN"
  done

  echo "[INFO] Importando ($label-$which) a QIIME2…"
  qiime tools import \
    --type 'SampleData[SequencesWithQuality]' \
    --input-path "$MAN" \
    --output-path "$OUT/sequences_SE.qza" \
    --input-format SingleEndFastqManifestPhred33V2

  echo "[INFO] Denoising DADA2 ($label-$which)…"
  qiime dada2 denoise-single \
    --i-demultiplexed-seqs "$OUT/sequences_SE.qza" \
    --p-trim-left 0 \
    --p-trunc-len 0 \
    --p-trunc-q 0 \
    --p-max-ee 2 \
    --p-chimera-method consensus \
    --p-n-threads 0 \
    --o-table "$OUT/table.qza" \
    --o-representative-sequences "$OUT/rep_seqs.qza" \
    --o-denoising-stats "$OUT/denoise_stats.qza"

  echo "[INFO] Visualizaciones ($label-$which)…"
  qiime demux summarize \
    --i-data "$OUT/sequences_SE.qza" \
    --o-visualization "$OUT/demux_summary.qzv"

  qiime feature-table summarize \
    --i-table "$OUT/table.qza" \
    --o-visualization "$OUT/table_summary.qzv"

  qiime feature-table tabulate-seqs \
    --i-data "$OUT/rep_seqs.qza" \
    --o-visualization "$OUT/rep_seqs.qzv"

  qiime metadata tabulate \
    --m-input-file "$OUT/denoise_stats.qza" \
    --o-visualization "$OUT/denoise_stats.qzv"

  echo "[OK] $label-$which listo en $OUT"
}

echo "[INFO] IN : $IN_BASE"
echo "[INFO] OUT: $OUT_BASE"
echo "=============================================="

for dir in "cutadapt" "fastp" "trimmomatic_win3" "trimmomatic_win4"; do
  tag="${TAG[$dir]}"
  in_dir="$IN_BASE/$dir"
  echo ">>> $tag (F)"
  run_one "$in_dir" "$tag" "F"
  echo ">>> $tag (R)"
  run_one "$in_dir" "$tag" "R"
done

echo "[DONE] DADA2 single-end para F y R en 4 estrategias."
