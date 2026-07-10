#!/bin/bash
set -euo pipefail

# ========================================
# Bases Q<30 antes (RAW) y después (02_filtered/*)
# Salida: results/resumen_filtrado/resumen_bases_Q30_before_after.tsv
# Estructura esperada:
#   RAW:           data/01_raw/*_{R1,R2}.fastq[.gz]
#   FILTRADOS:     data/02_filtered/<filtro>/*_{R1,R2}*.fastq[.gz]
# ========================================

RAW_DIR="data/01_raw"
FILT_BASE="data/02_filtered"
OUT_DIR="results/resumen_filtrado"
OUT_TSV="$OUT_DIR/resumen_bases_Q30_before_after.tsv"

mkdir -p "$OUT_DIR"

# Conjunto de caracteres Phred+33 con Q<30: ASCII 33 ('!') a 62 ('>') inclusive
Q30_CHARS="!\"#$%&'()*+,-./0123456789:;<=>"

# Función: imprime "TOTAL\tLT30" para un archivo .fastq(.gz)
calc_q30_fastq() {
  local f="$1"
  if [[ "$f" == *.gz ]]; then
    gzip -dc -- "$f" | awk -v chars="$Q30_CHARS" '
      NR%4==2 {total += length($0)}
      NR%4==0 {
        line=$0
        for (i=1;i<=length(line);i++){
          c=substr(line,i,1)
          if (index(chars, c)) lt30++
        }
      }
      END {printf "%d\t%d\n", total+0, lt30+0}
    '
  else
    awk -v chars="$Q30_CHARS" '
      NR%4==2 {total += length($0)}
      NR%4==0 {
        line=$0
        for (i=1;i<=length(line);i++){
          c=substr(line,i,1)
          if (index(chars, c)) lt30++
        }
      }
      END {printf "%d\t%d\n", total+0, lt30+0}
    ' "$f"
  fi
}

echo -e "Muestra\tLectura\tCondicion\tTotal_bases\tBases_Q<30\t%Q<30" > "$OUT_TSV"

# Recorre muestras en RAW tomando como referencia R1
shopt -s nullglob
for R1 in "$RAW_DIR"/*_R1.fastq "$RAW_DIR"/*_R1.fastq.gz; do
  basefile=$(basename "$R1")
  sample="${basefile%_R1.fastq}"
  sample="${sample%_R1.fastq.gz}"
  R2="$RAW_DIR/${sample}_R2.fastq"
  [[ -f "$R2" ]] || R2="$RAW_DIR/${sample}_R2.fastq.gz"

  # --- RAW R1
  if [[ -f "$R1" ]]; then
    read -r tot lt30 < <(calc_q30_fastq "$R1")
    perc=$(awk -v a="$lt30" -v b="$tot" 'BEGIN{if(b>0) printf "%.4f", (a/b)*100; else print "NA"}')
    echo -e "${sample}\tR1\tRAW\t${tot}\t${lt30}\t${perc}" >> "$OUT_TSV"
  fi
  # --- RAW R2
  if [[ -f "$R2" ]]; then
    read -r tot lt30 < <(calc_q30_fastq "$R2")
    perc=$(awk -v a="$lt30" -v b="$tot" 'BEGIN{if(b>0) printf "%.4f", (a/b)*100; else print "NA"}')
    echo -e "${sample}\tR2\tRAW\t${tot}\t${lt30}\t${perc}" >> "$OUT_TSV"
  fi

  # --- FILTRADOS (todas las subcarpetas)
  for FDIR in "$FILT_BASE"/*; do
    [[ -d "$FDIR" ]] || continue
    cond=$(basename "$FDIR")

    # Busca archivos que empiecen por la muestra y terminen en R1/R2 (admite sufijos)
    FR1=()
    FR2=()
    FR1+=( "$FDIR/${sample}"*_R1*.fastq "$FDIR/${sample}"*_R1*.fastq.gz )
    FR2+=( "$FDIR/${sample}"*_R2*.fastq "$FDIR/${sample}"*_R2*.fastq.gz )

    # R1 filtrado(s)
    for f in "${FR1[@]}"; do
      [[ -f "$f" ]] || continue
      read -r tot lt30 < <(calc_q30_fastq "$f")
      perc=$(awk -v a="$lt30" -v b="$tot" 'BEGIN{if(b>0) printf "%.4f", (a/b)*100; else print "NA"}')
      echo -e "${sample}\tR1\t${cond}\t${tot}\t${lt30}\t${perc}" >> "$OUT_TSV"
      break  # toma el primero que machee (evita duplicados)
    done

    # R2 filtrado(s)
    for f in "${FR2[@]}"; do
      [[ -f "$f" ]] || continue
      read -r tot lt30 < <(calc_q30_fastq "$f")
      perc=$(awk -v a="$lt30" -v b="$tot" 'BEGIN{if(b>0) printf "%.4f", (a/b)*100; else print "NA"}')
      echo -e "${sample}\tR2\t${cond}\t${tot}\t${lt30}\t${perc}" >> "$OUT_TSV"
      break
    done
  done
done
shopt -u nullglob

echo "✅ Listo: $OUT_TSV"
