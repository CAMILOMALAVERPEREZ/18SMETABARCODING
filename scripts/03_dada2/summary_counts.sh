#!/usr/bin/env bash
#Activa conda antes de ejecutar este script
# Calcula #ASVs y lecturas totales por estrategia en data/04_dada2_asvs/*
# Soporta nombres con espacios o '&'

set -euo pipefail

OUT="data/04_dada2_asvs"
TMP="$(mktemp -d)"
printf "Estrategia\tASVs\tLecturas_totales\n"

# Recorre cada subcarpeta presente (descubre estrategias automáticamente)
for DIR in "$OUT"/*/; do
  # nombre de la estrategia
  S="$(basename "$DIR")"
  TQZA="$OUT/$S/table.qza"

  if [[ -f "$TQZA" ]]; then
    # exporta la tabla y convierte a TSV si es BIOM
    qiime tools export --input-path "$TQZA" --output-path "$TMP/$S" >/dev/null 2>&1 || true
    if [[ -f "$TMP/$S/feature-table.biom" ]]; then
      biom convert -i "$TMP/$S/feature-table.biom" -o "$TMP/$S/table.tsv" --to-tsv >/dev/null 2>&1 || true
    fi

    TSV="$TMP/$S/table.tsv"
    if [[ -f "$TSV" ]]; then
      # ASVs = nº de filas (excluye encabezado/comentarios)
      ASVS=$(awk 'NR>1 && $1!~/^#/{c++} END{print c+0}' "$TSV")
      # Lecturas totales = suma de todas las celdas numéricas (excepto 1ª col)
      READS=$(awk 'NR>1 && $1!~/^#/{for(i=2;i<=NF;i++) s+=$i} END{print s+0}' "$TSV")
      printf "%s\t%s\t%s\n" "$S" "$ASVS" "$READS"
    else
      printf "%s\tNA\tNA\n" "$S"
    fi
  else
    printf "%s\tNA\tNA\n" "$S"
  fi
done

rm -rf "$TMP"
