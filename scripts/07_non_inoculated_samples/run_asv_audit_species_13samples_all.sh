#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTBASE="$ROOT/data/07_non_inoculated_samples/asv_audit_species_13samples"
META="${META:-$ROOT/data/07_non_inoculated_samples/metadata_13_muestras.tsv}"

PIPELINES=(
  Cuta_CA
  Fastp_CA
  T4_CA
  Cuta_F
  Fastp_F
  T4_F
)

mkdir -p "$OUTBASE"
mkdir -p "$ROOT/scripts/07_non_inoculated_samples"

if [[ ! -f "$META" ]]; then
  echo "[ERROR] No existe metadata: $META"
  exit 1
fi

# --------------------------------------------------
# Script Python reusable para construir tabla ASV especie
# --------------------------------------------------
cat > "$OUTBASE/.build_asv_audit_species_generic.py" << 'PY'
#!/usr/bin/env python3
import csv
import sys
from pathlib import Path

if len(sys.argv) != 5:
    print("Uso: build_asv_audit_species_generic.py <BASE_DIR> <DB_NAME> <SPECIES_LEVEL> <OUT_TSV>")
    sys.exit(1)

base_dir = Path(sys.argv[1])
db_name = sys.argv[2]
species_level = int(sys.argv[3])
out_tsv = Path(sys.argv[4])

table_tsv = base_dir / "table_13samples.tsv"
taxonomy_tsv = base_dir / "export_taxonomy" / "taxonomy.tsv"
fasta_file = base_dir / "export_seqs" / "dna-sequences.fasta"

if not table_tsv.exists():
    raise FileNotFoundError(f"No existe: {table_tsv}")
if not taxonomy_tsv.exists():
    raise FileNotFoundError(f"No existe: {taxonomy_tsv}")
if not fasta_file.exists():
    raise FileNotFoundError(f"No existe: {fasta_file}")

# 1. Leer taxonomía
tax_map = {}
with open(taxonomy_tsv, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f, delimiter="\t")
    for row in reader:
        tax_map[row["Feature ID"]] = row["Taxon"]

# 2. Leer FASTA
seq_map = {}
current_id = None
seq_chunks = []
with open(fasta_file, encoding="utf-8") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        if line.startswith(">"):
            if current_id is not None:
                seq_map[current_id] = "".join(seq_chunks)
            current_id = line[1:]
            seq_chunks = []
        else:
            seq_chunks.append(line)
if current_id is not None:
    seq_map[current_id] = "".join(seq_chunks)

def extraer_nivel(tax, pos_1based):
    if not tax:
        return ""
    parts = [p.strip() for p in tax.split(";")]
    idx = pos_1based - 1
    if len(parts) > idx:
        return parts[idx]
    return ""

# 3. Leer tabla biom convert
with open(table_tsv, encoding="utf-8") as f:
    lines = [line.rstrip("\n") for line in f if line.strip()]

if lines and lines[0].startswith("# Constructed from biom file"):
    lines = lines[1:]

header = lines[0].split("\t")
header[0] = "ASV_ID"
sample_ids = header[1:]

col_species = f"species_{db_name}"

with open(out_tsv, "w", newline="", encoding="utf-8") as f_out:
    writer = csv.writer(f_out, delimiter="\t")
    writer.writerow([
        "db", "ASV_ID", "sample_id", "abundancia",
        "taxonomia_completa", col_species, "secuencia"
    ])

    for line in lines[1:]:
        parts = line.split("\t")
        asv = parts[0]
        abunds = parts[1:]
        tax = tax_map.get(asv, "")
        species = extraer_nivel(tax, species_level)
        seq = seq_map.get(asv, "")

        for sample_id, abund in zip(sample_ids, abunds):
            try:
                abund_num = float(abund)
            except:
                abund_num = 0.0
            if abund_num > 0:
                writer.writerow([
                    db_name, asv, sample_id, abund_num,
                    tax, species, seq
                ])

print(f"[OK] Generado: {out_tsv}")
PY

chmod +x "$OUTBASE/.build_asv_audit_species_generic.py"

process_one() {
  local DB="$1"
  local PIPE="$2"
  local TABLE_IN="$3"
  local TAX_IN="$4"
  local SEQS_IN="$5"
  local SPECIES_LEVEL="$6"

  local OUTDIR="$OUTBASE/$DB/$PIPE"
  mkdir -p "$OUTDIR"

  echo "=============================================="
  echo "[INFO] DB=$DB PIPE=$PIPE"

  if [[ ! -f "$TABLE_IN" ]]; then
    echo "[WARN] Falta table: $TABLE_IN"
    return 0
  fi
  if [[ ! -f "$TAX_IN" ]]; then
    echo "[WARN] Falta taxonomy: $TAX_IN"
    return 0
  fi
  if [[ ! -f "$SEQS_IN" ]]; then
    echo "[WARN] Falta seqs: $SEQS_IN"
    return 0
  fi

  qiime feature-table filter-samples \
    --i-table "$TABLE_IN" \
    --m-metadata-file "$META" \
    --o-filtered-table "$OUTDIR/table_13samples.qza"

  qiime tools export \
    --input-path "$OUTDIR/table_13samples.qza" \
    --output-path "$OUTDIR/export_table_13samples"

  biom convert \
    -i "$OUTDIR/export_table_13samples/feature-table.biom" \
    -o "$OUTDIR/table_13samples.tsv" \
    --to-tsv

  qiime tools export \
    --input-path "$TAX_IN" \
    --output-path "$OUTDIR/export_taxonomy"

  qiime tools export \
    --input-path "$SEQS_IN" \
    --output-path "$OUTDIR/export_seqs"

  python3 "$OUTBASE/.build_asv_audit_species_generic.py" \
    "$OUTDIR" "$DB" "$SPECIES_LEVEL" "$OUTDIR/ASV_audit_species_${DB}_${PIPE}.tsv"
}

# PR2: especie = posición 9
for P in "${PIPELINES[@]}"; do
  process_one \
    "PR2" \
    "$P" \
    "$ROOT/data/05_taxonomy/$P/filtered_table_interest_MAIN.qza" \
    "$ROOT/data/05_taxonomy/$P/taxonomy_nb_PR2.qza" \
    "$ROOT/data/05_taxonomy/$P/filtered_seqs_interest.qza" \
    "9"
done

# SILVA132: especie = posición 7
for P in "${PIPELINES[@]}"; do
  process_one \
    "SILVA132" \
    "$P" \
    "$ROOT/data/05_taxonomy_SILVA132/$P/filtered_table_interest_MAIN_SILVA.qza" \
    "$ROOT/data/05_taxonomy_SILVA132/$P/taxonomy_nb_SILVA132.qza" \
    "$ROOT/data/05_taxonomy_SILVA132/$P/filtered_seqs_interest_SILVA.qza" \
    "7"
done

# SILVA138custom: especie = posición 7
for P in "${PIPELINES[@]}"; do
  process_one \
    "SILVA138custom" \
    "$P" \
    "$ROOT/data/04_dada2_asvs/$P/table.qza" \
    "$ROOT/data/05_taxonomy_SILVA138_custom/$P/taxonomy_nb_SILVA138custom.qza" \
    "$ROOT/data/05_taxonomy_SILVA138_custom/$P/rep_seqs_from_fasta_2021.qza" \
    "7"
done

MASTER="$OUTBASE/ASV_audit_species_MASTER_13samples.tsv"

python3 - << 'PY'
from pathlib import Path
import csv

root = ROOT / "data" / "07_non_inoculated_samples" / "asv_audit_species_13samples"
out_file = root / "ASV_audit_species_MASTER_13samples.tsv"

files = sorted(root.glob("*/*/ASV_audit_species_*.tsv"))

with open(out_file, "w", newline="", encoding="utf-8") as fout:
    writer = None

    for f in files:
        db = f.parent.parent.name
        pipeline = f.parent.name

        if "_" in pipeline:
            prerecorte, enfoque = pipeline.split("_", 1)
        else:
            prerecorte, enfoque = pipeline, ""

        with open(f, newline="", encoding="utf-8") as fin:
            reader = csv.DictReader(fin, delimiter="\t")

            for row in reader:
                row_out = {
                    "db": db,
                    "pipeline": pipeline,
                    "prerecorte": prerecorte,
                    "enfoque": enfoque,
                    "ASV_ID": row["ASV_ID"],
                    "sample_id": row["sample_id"],
                    "abundancia": row["abundancia"],
                    "taxonomia_completa": row["taxonomia_completa"],
                    "species": row.get("species_PR2", row.get("species_SILVA132", row.get("species_SILVA138custom", ""))),
                    "secuencia": row["secuencia"]
                }

                if writer is None:
                    writer = csv.DictWriter(fout, fieldnames=list(row_out.keys()), delimiter="\t")
                    writer.writeheader()

                writer.writerow(row_out)

print(f"[OK] Tabla maestra final: {out_file}")
print(f"[INFO] Archivos unidos: {len(files)}")
PY

echo
echo "[DONE] Auditoría ASV de especie completada."
echo "[OUT] Base:   $OUTBASE"
echo "[OUT] Master: $MASTER"
