#!/usr/bin/env python3
import os, sys, gzip, itertools, argparse
from pathlib import Path

# ======== CONFIG FIJA (según tu repo) ========
REPO_ROOT = Path(__file__).resolve().parents[2]
IN_BASE   = REPO_ROOT / "data" / "02_filtered"
OUT_BASE  = REPO_ROOT / "data" / "03_assembled"

FILTERS = {
    "cutadapt": "Cuta",
    "fastp": "Fastp",
    "trimmomatic_win3": "T3",
    "trimmomatic_win4": "T4",
}

# Separador para CAN
SEP_BASE = "N"
SEP_QUAL = "?"  # calidad pedida
# =============================================

def open_auto(p, mode="rt"):
    p = str(p)
    return gzip.open(p, mode) if p.endswith(".gz") else open(p, mode)

def rc_dna(seq: str) -> str:
    comp = str.maketrans("ACGTNacgtn", "TGCANtgcan")
    return seq.translate(comp)[::-1]

def rc_qual(q: str) -> str:
    return q[::-1]

def yield_fastq(path):
    with open_auto(path, "rt") as fh:
        it = iter(fh)
        for h, s, plus, q in itertools.zip_longest(*[it]*4):
            if h is None: break
            yield h.rstrip(), s.rstrip(), plus.rstrip(), q.rstrip()

def write_fastq(path, records):
    path.parent.mkdir(parents=True, exist_ok=True)
    opener = gzip.open if str(path).endswith(".gz") else open
    with opener(path, "wt") as out:
        for h, s, plus, q in records:
            out.write(f"{h}\n{s}\n{plus}\n{q}\n")

def find_pairs(fdir: Path):
    r1s = sorted([p for p in fdir.glob("*_R1_filt.fastq*")])
    for r1 in r1s:
        r2 = Path(str(r1).replace("_R1_filt", "_R2_filt"))
        if r2.exists():
            sample = r1.name.split("_R1_filt")[0]
            yield sample, r1, r2

def concat_records(r1_path, r2_path, with_sep=False):
    for (h1, s1, p1, q1), (_, s2, _, q2) in zip(yield_fastq(r1_path), yield_fastq(r2_path)):
        s2_rc = rc_dna(s2)
        q2_rc = rc_qual(q2)
        if with_sep:
            seq = s1 + SEP_BASE + s2_rc
            qual = q1 + SEP_QUAL + q2_rc
        else:
            seq = s1 + s2_rc
            qual = q1 + q2_rc
        yield h1, seq, p1, qual

def process_filter(filter_name: str, tag: str, force: bool):
    fdir = IN_BASE / filter_name / "filtrados"
    if not fdir.is_dir():
        print(f"[WARN] No existe: {fdir} (se omite)")
        return

    out_ca  = OUT_BASE / f"{tag}_CA"
    out_can = OUT_BASE / f"{tag}_CAN"

    pairs = list(find_pairs(fdir))
    if not pairs:
        print(f"[WARN] Sin pares en {fdir}")
        return

    for sample, r1, r2 in pairs:
        # CA (sin N)
        out_ca_file = out_ca / f"{sample}_concat.fastq"
        if out_ca_file.exists() or Path(str(out_ca_file)+".gz").exists():
            if force:
                print(f"[OVERWRITE][CA]  {sample} -> {out_ca_file}")
            else:
                print(f"[SKIP] Existe CA: {out_ca_file.name}")
                pass
        if force or not (out_ca_file.exists() or Path(str(out_ca_file)+".gz").exists()):
            write_fastq(out_ca_file, concat_records(r1, r2, with_sep=False))

        # CAN (con N y calidad '?')
        out_can_file = out_can / f"{sample}_concat.fastq"
        if out_can_file.exists() or Path(str(out_can_file)+".gz").exists():
            if force:
                print(f"[OVERWRITE][CAN] {sample} -> {out_can_file}")
            else:
                print(f"[SKIP] Existe CAN: {out_can_file.name}")
                pass
        if force or not (out_can_file.exists() or Path(str(out_can_file)+".gz").exists()):
            write_fastq(out_can_file, concat_records(r1, r2, with_sep=True))

def main():
    parser = argparse.ArgumentParser(description="Concatenación CA/CAN (F + revcomp(R))")
    parser.add_argument("--force", action="store_true",
                        help="Sobrescribir archivos existentes")
    args = parser.parse_args()

    print(f"[INFO] IN : {IN_BASE}")
    print(f"[INFO] OUT: {OUT_BASE}")
    for f, tag in FILTERS.items():
        print(f"\n=== Filtro: {f} → {tag} ===")
        process_filter(f, tag, force=args.force)
    print("\n[OK] CA y CAN generados.")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit(130)
