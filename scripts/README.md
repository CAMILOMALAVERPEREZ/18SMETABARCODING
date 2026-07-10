# Workflow scripts

This folder contains the scripts associated with the 18S metabarcoding workflow described in the manuscript:

**Non-overlapping paired-end reads in 18S metabarcoding: concatenation of prefiltered reads enables fecal eukaryome profiling**

The scripts are organized according to the main analysis stages used in the manuscript.

## Folder overview

### 01_filtering/

Initial quality assessment, pre-trimming and post-filtering summaries.

Order of execution:

- `01_fastqc_batch.sh`: initial read-quality assessment with FastQC.
- `02_multiqc_fastqc.sh`: MultiQC summary of initial quality reports.
- `03_cutadapt_batch.sh`: pre-trimming with Cutadapt.
- `04_fastp_run.sh`: pre-trimming with fastp.
- `05_trimmomatic_batch_SE.sh`: pre-trimming with Trimmomatic sliding-window configurations.
- `06_pair_filter_to_subfolder.sh`: removal of reads without their corresponding pair.
- `07_generar_resumen_filtrado.sh`: summary of removed reads and bases.
- `08_analisis_bases_q30_before_after.sh`: Q<30 base analysis before and after filtering.
- `09_distribucion_tamanos.sh`: read-length distribution after pre-trimming.
- `10_analisis_bases_calidad.sh`: quality-base summary tables.

### 02_assembly/

Read-pair processing strategies.

Main scripts:

- `concat_CA_CAN_allinone.py`: direct concatenation of R1 and R2 reads, with and without an N spacer.
- `run_mc_pandaseq.sh`: merge-and-concat strategy using PANDAseq.

### 03_dada2/

DADA2 ASV inference.

Main scripts:

- `run_dada2_single_FR.sh`: DADA2 processing for forward-only and reverse-only reads.
- `run_dada2_single_all_strategies.sh`: DADA2 processing for concatenated and merge-and-concat strategies.
- `summary_counts.sh`: summary of ASVs and read-retention statistics after DADA2.

### 04_taxonomy/

Taxonomic assignment with the three reference databases used in the manuscript.

Main scripts:

- `run_pr2_all_strats.sh`: taxonomic assignment using PR2.
- `run_silva132_all_strats.sh`: taxonomic assignment using SILVA132.
- `run_silva138custom_all_strats.sh`: taxonomic assignment using SILVA138_custom.

External classifiers are not stored in this GitHub repository. They should be obtained from the associated data repositories or configured through environment variables when applicable.

### 06_inoculated_controls/

Taxonomic summaries of the two inoculated fecal controls.

Main scripts:

- `06_collapse_controls_taxa.sh`: collapse control ASV tables by taxonomic level.
- `export_controls_all_genera_3DB.py`: integrate genus-level control results across PR2, SILVA132 and SILVA138_custom.
- `build_mock_taxon_slot_counts.py`: generate long-format taxon-slot count tables for inoculated controls.

### 07_non_inoculated_samples/

ASV audit tables from the 13 non-inoculated market fecal samples analyzed in the manuscript.

Main scripts:

- `01_build_genus_tables_unknowns.sh`: build genus-level tables for the 13 non-inoculated samples.
- `run_asv_audit_genus_13samples_all.sh`: generate genus-level ASV audit tables across selected pipelines and databases.
- `run_asv_audit_species_13samples_all.sh`: generate species-level ASV audit tables across selected pipelines and databases.

## Notes

Raw FASTQ files, QIIME 2 artifacts, processed data tables and result folders are not included in this GitHub repository.

Processed data and the SILVA138_custom database are intended to be deposited in Zenodo or a similar research data repository.

Raw sequencing reads are intended to be deposited in NCBI SRA.
