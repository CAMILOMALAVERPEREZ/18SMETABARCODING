# Non-overlapping paired-end reads in 18S metabarcoding

This repository contains the bioinformatic workflow associated with the manuscript:

**Non-overlapping paired-end reads in 18S metabarcoding: concatenation of prefiltered reads enables fecal eukaryome profiling**

The workflow evaluates preprocessing, read-processing and taxonomic-assignment strategies for 18S rRNA metabarcoding of fecal samples amplified with VESPA primers targeting the V4-V5 region.

## Project overview

This study addresses a common challenge in 18S metabarcoding: paired-end reads generated from variable-length amplicons may fail to overlap consistently. To evaluate alternatives for non-overlapping paired-end reads, the workflow compared pre-trimming tools, read-processing strategies, DADA2 ASV inference and taxonomic assignment using multiple reference databases.

The main components of the analysis were:

- evaluation of pre-trimming effects on read loss, base loss, Q<30 bases and read-length distributions;
- comparison of paired-end read-processing strategies, including direct concatenation of R1 and R2 reads;
- ASV inference using DADA2;
- taxonomic assignment using PR2, SILVA132 and SILVA138_custom;
- assessment of taxon recovery in two inoculated fecal controls;
- taxonomic inspection of 13 non-inoculated market fecal samples.

## Amplicon and sequencing context

The workflow was designed for 18S rRNA V4-V5 amplicons generated with VESPA primers:

Forward primer:
AGCAGCCGCGGTAATTCC

Reverse primer:
TCAATTYCTTIAASTTTC

The analysis was applied to paired-end Illumina reads from fecal samples. Raw FASTQ files are not included in this repository.

## Main workflow

The repository is organized around the following analysis stages:

scripts/
├── 01_filtering/
├── 02_assembly/
├── 03_dada2/
├── 04_taxonomy/
├── 06_inoculated_controls/
└── 07_non_inoculated_samples/

These folders contain scripts and workflow documentation used for pre-trimming evaluation, read processing, ASV inference, taxonomic assignment and taxonomic comparisons.

Exploratory or deprecated analyses are not part of the recommended final workflow.

## Pre-trimming tools

The workflow evaluated:

- Cutadapt
- fastp
- Trimmomatic sliding-window configurations

Pre-trimming was assessed using script outputs summarizing read retention, base retention, Q<30 bases and read-length distributions.

## Read-processing strategies

The evaluated read-processing strategies included:

- direct concatenation of forward and reverse reads;
- concatenation using an N spacer;
- merge-and-concat strategy;
- forward-only reads;
- reverse-only reads.

The final manuscript focuses on the strategies that produced usable DADA2 outputs and were relevant for downstream taxonomic comparison.

## ASV inference

ASV inference was performed with DADA2 using QIIME 2 workflows. The deposited processed data include ASV feature tables and representative sequences for the final deposited strategies.

## Taxonomic assignment

Taxonomic assignment was performed using QIIME 2 feature-classifier classify-sklearn with Naive Bayes classifiers.

The databases evaluated were:

- PR2
- SILVA132
- SILVA138_custom

## SILVA138_custom database

The SILVA138_custom classifier and associated reference files are provided as part of the processed-data deposit.

The classifier can be used directly in QIIME 2 with:

qiime feature-classifier classify-sklearn \
  --i-classifier silva-138.2-groups-V4V5-min400-clean-v2-classifier.qza \
  --i-reads rep_seqs.qza \
  --o-classification taxonomy_SILVA138_custom.qza

The custom database package includes:

- silva-138.2-groups-V4V5-min400-clean-v2-classifier.qza
- silva-138.2-groups-V4V5-seqs-min400-clean-v2.qza
- silva-138.2-groups-V4V5-tax-min400-clean-v2.qza
- V4V5_min400_clean_v2.fasta
- V4V5_min400_taxonomy_clean_v2.tsv

Users of this custom database should cite the associated manuscript and the original SILVA database release from which the reference files were derived.

## Data availability

Raw sequencing reads are not stored in this GitHub repository.

Data are organized across three platforms:

NCBI SRA:
Raw paired-end FASTQ files.

Zenodo:
Processed data, QIIME 2 artifacts, taxonomy tables, metadata and SILVA138_custom database.

GitHub:
Scripts, workflow documentation and usage instructions.

Accession numbers and DOI links will be added after deposition.

## Repository contents

This GitHub repository is intended to contain code and documentation only.

Large files are excluded from version control, including:

- raw FASTQ files;
- QIIME 2 artifacts;
- processed data tables;
- result folders;
- logs and temporary files.

## Citation

Please cite the associated manuscript when using this workflow or the SILVA138_custom database.

## Author

Sergio Camilo Malaver Pérez

## License

This repository is intended for academic and research use. A formal license file should be added before final release.
