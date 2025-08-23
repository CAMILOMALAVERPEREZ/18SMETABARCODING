#!/usr/bin/env python3
import os
import gzip
from Bio import SeqIO
from Bio.Seq import Seq

# ========= CONFIG =========
PROJ = "/home/camilomalaver/18SMETABARCODING_local"
IN_BASE = os.path.join(PROJ, "data/02_filtered")
OUT_BASE = os.path.join(PROJ, "data/03_assembled")

# Mapeo filtros -> carpetas de salida
OUTMAP = {
    "cutadapt": "Cuta_C",
    "fastp": "Fastp_C",
    "trimmomatic_win4": "T4_C",
    "trimmomatic_win3": "T3_C",
}
# ==========================

def open_maybe_gz(path, mode="rt"):
    """Abrir archivo .gz o normal en modo texto."""
    return gzip.open(path, mode) if path.endswith(".gz") else open(path, mode)

def process_sample(forward_path, reverse_path, output_path):
    # Streams de lectura
    fwd_it = SeqIO.parse(open_maybe_gz(forward_path, "rt"), "fastq")
    rev_it = SeqIO.parse(open_maybe_gz(reverse_path, "rt"), "fastq")

    concatenated = []
    for fwd, rev in zip(fwd_it, rev_it):
        # Reverse-complement de la secuencia R2
        rev_rc = rev.seq.reverse_complement()

        # Concatenar con un separador '-' (como pediste)
        new_seq = fwd.seq + Seq("N") + rev_rc

        # Construir calidades: forward + [0 para '-' ] + reverse invertida
        new_qual = (
            fwd.letter_annotations.get("phred_quality", [])
            + [0]
            + list(rev.letter_annotations.get("phred_quality", []))[::-1]
        )

        # Copiar el record de FWD y reconstruir campos
        new_rec = fwd[:]                    # clona metadatos (id, name, desc, etc.)
        new_rec.letter_annotations = {}     # ⚠️ vaciar ANTES de cambiar la longitud
        new_rec.seq = new_seq               # ahora sí, nueva secuencia (longitud distinta)
        new_rec.letter_annotations["phred_quality"] = new_qual

        # (Opcional) si quieres marcar que está concatenado en la descripción:
        # new_rec.description = (f"{fwd.description} | CONCAT")

        concatenated.append(new_rec)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    SeqIO.write(concatenated, output_path, "fastq")
    print(f"✅ {os.path.basename(output_path)}: {len(concatenated)} secuencias concatenadas.")

def main():
    os.makedirs(OUT_BASE, exist_ok=True)

    for filt, out_sub in OUTMAP.items():
        in_dir = os.path.join(IN_BASE, filt, "filtrados")
        out_dir = os.path.join(OUT_BASE, out_sub)

        if not os.path.isdir(in_dir):
            print(f"[WARN] No existe {in_dir}, omitiendo {filt}")
            continue
        os.makedirs(out_dir, exist_ok=True)

        print(f"\n=== Procesando filtro {filt} ===")
        for fname in os.listdir(in_dir):
            if fname.endswith("_R1_filt.fastq") or fname.endswith("_R1_filt.fastq.gz"):
                sample = fname.split("_R1_filt")[0]
                fwd = os.path.join(in_dir, fname)
                rev = os.path.join(in_dir, fname.replace("_R1_filt", "_R2_filt"))
                if not os.path.exists(rev):
                    print(f"[WARN] No se encontró {rev}, omitiendo {sample}")
                    continue

                out_file = os.path.join(out_dir, f"{sample}_concat.fastq")
                process_sample(fwd, rev, out_file)

    print(f"\n[OK] Concatenación personalizada finalizada. Resultados en {OUT_BASE}")

if __name__ == "__main__":
    main()

