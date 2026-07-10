#!/usr/bin/env python3
from pathlib import Path
import csv
import re
from collections import defaultdict
from biom import load_table
import subprocess

ROOT = Path(__file__).resolve().parents[2]

MOCKS = {"Cmcontrol1", "Cmcontrol2"}

TABLE_BASE = ROOT / "data/04_dada2_asvs"
TAX_BASES = {
    "PR2": ROOT / "data/05_taxonomy",
    "SILVA132": ROOT / "data/05_taxonomy_SILVA132",
    "SILVA138custom": ROOT / "data/05_taxonomy_SILVA138_custom",
}

OUTDIR = ROOT / "data/07_non_inoculated_samples/mock_counts"
TMPDIR = OUTDIR / "tmp_tables"
OUT = OUTDIR / "mock_taxon_slot_counts_long.tsv"

STRATEGIES = [
    "Cuta_CA","Cuta_CAN","Cuta_F","Cuta_M&C","Cuta_R",
    "Fastp_CA","Fastp_CAN","Fastp_F","Fastp_M&C","Fastp_R",
    "T3_CA","T3_F","T3_M&C","T3_R",
    "T4_CA","T4_F","T4_M&C","T4_R"
]

def ensure_biom_export(strategy: str) -> Path:
    outdir = TMPDIR / strategy
    outdir.mkdir(parents=True, exist_ok=True)
    biom_fp = outdir / "feature-table.biom"
    if biom_fp.exists():
        return biom_fp

    subprocess.run([
        "qiime", "tools", "export",
        "--input-path", str(TABLE_BASE / strategy / "table.qza"),
        "--output-path", str(outdir)
    ], check=True)
    return biom_fp

def read_taxonomy_tsv(path: Path):
    tax = {}
    with path.open() as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            tax[row["Feature ID"]] = row["Taxon"]
    return tax

def extract_slots(taxon: str, base: str):
    if not taxon or taxon == "Unassigned":
        return None, None, None

    if base == "SILVA138custom":
        order_slot = None
        genus_slot = None
        species_slot = None

        mo = re.search(r"o__([^;]+)", taxon)
        if mo:
            order_slot = mo.group(1).strip()

        mg = re.search(r"g__([^;]+)", taxon)
        if mg:
            genus_slot = mg.group(1).strip()

        ms = re.search(r"s__([^;]+)", taxon)
        if ms:
            species_slot = ms.group(1).strip()

        return order_slot, genus_slot, species_slot

    parts = [p.strip() for p in taxon.split(";")]

    if base == "PR2":
        # orden = pos 6 ; genero = pos 8 ; especie = pos 9
        order_slot   = parts[5] if len(parts) >= 6 and parts[5] else None
        genus_slot   = parts[7] if len(parts) >= 8 and parts[7] else None
        species_slot = parts[8] if len(parts) >= 9 and parts[8] else None
        return order_slot, genus_slot, species_slot

    if base == "SILVA132":
        # orden = nivel 5 ; genero = nivel 6 ; especie = nivel 7
        order_slot   = parts[4] if len(parts) >= 5 and parts[4] else None
        genus_slot   = parts[5] if len(parts) >= 6 and parts[5] else None
        species_slot = parts[6] if len(parts) >= 7 and parts[6] else None
        return order_slot, genus_slot, species_slot

    return None, None, None

rows = []

for strat in STRATEGIES:
    table_qza = TABLE_BASE / strat / "table.qza"
    if not table_qza.exists():
        continue

    biom_fp = ensure_biom_export(strat)
    table = load_table(str(biom_fp))

    samples = set(table.ids(axis="sample"))
    mock_samples = sorted(MOCKS.intersection(samples))
    if not mock_samples:
        continue

    asv_ids = list(table.ids(axis="observation"))

    for base_name, tax_dir in TAX_BASES.items():
        if base_name == "PR2":
            tax_file = tax_dir / strat / "taxonomy_nb_PR2.tsv"
        elif base_name == "SILVA132":
            tax_file = tax_dir / strat / "taxonomy_nb_SILVA132.tsv"
        else:
            tax_file = tax_dir / strat / "taxonomy_nb_SILVA138custom.tsv"

        if not tax_file.exists():
            continue

        taxonomy = read_taxonomy_tsv(tax_file)

        slot_counts = defaultdict(int)

        for fid in asv_ids:
            taxon = taxonomy.get(fid, "Unassigned")
            order_slot, genus_slot, species_slot = extract_slots(taxon, base_name)

            for mock in mock_samples:
                n = table.get_value_by_ids(fid, mock)
                if n is None or n <= 0:
                    continue
                n = int(n)

                if order_slot not in (None, "", "Unassigned"):
                    slot_counts[(base_name, strat, mock, "order", order_slot)] += n

                if genus_slot not in (None, "", "Unassigned"):
                    slot_counts[(base_name, strat, mock, "genus", genus_slot)] += n

                if species_slot not in (None, "", "Unassigned"):
                    slot_counts[(base_name, strat, mock, "species", species_slot)] += n

        for key, reads in sorted(slot_counts.items()):
            rows.append([*key, reads])

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w", newline="") as fh:
    writer = csv.writer(fh, delimiter="\t")
    writer.writerow(["Base", "Pipeline", "Mock", "Level", "TaxonSlot", "Reads"])
    writer.writerows(rows)

print(f"[OK] Archivo generado: {OUT}")
print(f"[OK] Total filas: {len(rows)}")
