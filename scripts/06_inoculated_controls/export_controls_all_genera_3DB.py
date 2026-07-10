#!/usr/bin/env python3
from pathlib import Path
import subprocess
import csv
import re
from collections import defaultdict
from biom import load_table

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"

PIPELINES = [
    "Cuta_CA","Cuta_CAN","Cuta_F","Cuta_M&C","Cuta_R",
    "Fastp_CA","Fastp_CAN","Fastp_F","Fastp_M&C","Fastp_R",
    "T3_CA","T3_CAN","T3_F","T3_M&C","T3_R",
    "T4_CA","T4_CAN","T4_F","T4_M&C","T4_R",
]

MOCKS = ["Cmcontrol1", "Cmcontrol2"]

OUTDIR = DATA / "07_non_inoculated_samples"
OUTDIR.mkdir(parents=True, exist_ok=True)

TMP = OUTDIR / "tmp_controls_all_genera_3db"
TMP.mkdir(parents=True, exist_ok=True)

OUT_TSV = OUTDIR / "controls_all_genera_PR2_SILVA132_SILVA138custom.tsv"

DBS = {
    "PR2": {
        "base_dir": DATA / "05_taxonomy",
        "tax_qza": "taxonomy_nb_PR2.qza",
        "table_candidates": ["table_controls_only.qza", "filtered_table_interest_CONTROLS.qza"],
        "collapse_with_qiime": True,
        "genus_level": 8,
    },
    "SILVA132": {
        "base_dir": DATA / "05_taxonomy_SILVA132",
        "tax_qza": "taxonomy_nb_SILVA132.qza",
        "table_candidates": ["table_controls_only.qza", "filtered_table_interest_CONTROLS_SILVA.qza"],
        "collapse_with_qiime": True,
        "genus_level": 6,
    },
    "SILVA138custom": {
        "base_dir": DATA / "05_taxonomy_SILVA138_custom",
        "tax_qza": "taxonomy_nb_SILVA138custom.qza",
        "table_candidates": ["table_controls_only.qza"],
        "collapse_with_qiime": False,  # <- clave
        "genus_level": None,
    },
}

def ensure_qiime():
    r = subprocess.run(["bash","-lc","command -v qiime"], capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError("No encuentro 'qiime' en PATH. Activa tu ambiente QIIME2.")

def pick_existing(pipe_dir: Path, names):
    for n in names:
        p = pipe_dir / n
        if p.exists():
            return p
    return None

def qiime_export(input_qza: Path, outdir: Path):
    outdir.mkdir(parents=True, exist_ok=True)
    subprocess.run(["qiime","tools","export","--input-path",str(input_qza),"--output-path",str(outdir)], check=True)

def qiime_taxa_collapse(i_table: Path, i_tax: Path, level: int, out_qza: Path):
    subprocess.run([
        "qiime","taxa","collapse",
        "--i-table", str(i_table),
        "--i-taxonomy", str(i_tax),
        "--p-level", str(level),
        "--o-collapsed-table", str(out_qza),
    ], check=True)

def read_taxonomy_tsv(tax_tsv: Path):
    tax = {}
    conf = {}
    with tax_tsv.open() as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            fid = row["Feature ID"]
            tax[fid] = row.get("Taxon","Unassigned")
            conf[fid] = row.get("Confidence","")
    return tax, conf

def parse_genus_silva_custom(taxon: str) -> str:
    """
    Extrae g__XXXX de strings como:
    d__Eukaryota,p__Apicomplexa,...,g__Eimeria,s__Eimeria_praecox
    """
    if not taxon or taxon == "Unassigned":
        return ""
    m = re.search(r"g__([^,;]+)", taxon)
    return m.group(1).strip() if m else ""

def main():
    ensure_qiime()

    with OUT_TSV.open("w", newline="") as out_fh:
        w = csv.writer(out_fh, delimiter="\t")
        w.writerow(["DB","Pipeline","Genus","TaxonomyString","Cmcontrol1_reads","Cmcontrol2_reads","Total_mock_reads"])

        for db, cfg in DBS.items():
            base_dir = cfg["base_dir"]

            for pipe in PIPELINES:
                pipe_dir = base_dir / pipe
                if not pipe_dir.exists():
                    continue

                table_qza = pick_existing(pipe_dir, cfg["table_candidates"])
                tax_qza = pipe_dir / cfg["tax_qza"]
                if table_qza is None or not table_qza.exists() or not tax_qza.exists():
                    continue

                if cfg["collapse_with_qiime"]:
                    # PR2/SILVA132 -> usamos taxa collapse
                    collapsed_qza = TMP / f"{db}__{pipe}__genus_collapsed.qza"
                    export_dir = TMP / f"export__{db}__{pipe}"
                    biom_fp = export_dir / "feature-table.biom"

                    if not collapsed_qza.exists():
                        qiime_taxa_collapse(table_qza, tax_qza, cfg["genus_level"], collapsed_qza)

                    if not biom_fp.exists():
                        qiime_export(collapsed_qza, export_dir)

                    table = load_table(str(biom_fp))
                    samples = set(table.ids(axis="sample"))
                    if not any(m in samples for m in MOCKS):
                        continue

                    for fid in table.ids(axis="observation"):
                        c1 = int(table.get_value_by_ids(fid,"Cmcontrol1")) if "Cmcontrol1" in samples else 0
                        c2 = int(table.get_value_by_ids(fid,"Cmcontrol2")) if "Cmcontrol2" in samples else 0
                        tot = c1 + c2
                        if tot <= 0:
                            continue
                        tax_string = str(fid)
                        # Género = último token
                        parts = [p.strip() for p in tax_string.split(";") if p.strip() and p.strip()!="Unassigned"]
                        genus = parts[-1] if parts else tax_string
                        w.writerow([db, pipe, genus, tax_string, c1, c2, tot])

                else:
                    # SILVA138custom -> colapso en Python por g__
                    # exporta tabla BIOM y taxonomía TSV
                    t_export = TMP / f"export_table__{db}__{pipe}"
                    tx_export = TMP / f"export_tax__{db}__{pipe}"
                    biom_fp = t_export / "feature-table.biom"
                    tax_tsv = tx_export / "taxonomy.tsv"

                    if not biom_fp.exists():
                        qiime_export(table_qza, t_export)
                    if not tax_tsv.exists():
                        qiime_export(tax_qza, tx_export)

                    table = load_table(str(biom_fp))
                    tax_map, _ = read_taxonomy_tsv(tax_tsv)

                    samples = set(table.ids(axis="sample"))
                    if not any(m in samples for m in MOCKS):
                        continue

                    genus_counts = defaultdict(lambda: {"c1":0,"c2":0,"tax":""})

                    for asv in table.ids(axis="observation"):
                        taxon = tax_map.get(asv, "Unassigned")
                        genus = parse_genus_silva_custom(taxon)
                        if not genus:
                            continue

                        c1 = int(table.get_value_by_ids(asv,"Cmcontrol1")) if "Cmcontrol1" in samples else 0
                        c2 = int(table.get_value_by_ids(asv,"Cmcontrol2")) if "Cmcontrol2" in samples else 0
                        if (c1+c2) <= 0:
                            continue

                        genus_counts[genus]["c1"] += c1
                        genus_counts[genus]["c2"] += c2
                        # guarda un ejemplo de taxonomía asociada (primera que aparezca)
                        if not genus_counts[genus]["tax"]:
                            genus_counts[genus]["tax"] = taxon

                    for genus, d in genus_counts.items():
                        tot = d["c1"] + d["c2"]
                        if tot > 0:
                            w.writerow([db, pipe, genus, d["tax"], d["c1"], d["c2"], tot])

    print(f"[OK] TSV generado: {OUT_TSV}")

if __name__ == "__main__":
    main()
