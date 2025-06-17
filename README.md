HEAD
# Proyecto de Metabarcoding 18S - Análisis comparativo de pipelines

Este repositorio contiene el flujo de trabajo bioinformático completo para el análisis de secuencias Illumina MiSeq PE 250x250 dirigidas a la región V4/V5 del gen 18S, amplificada mediante los cebadores VESPA.

Se evaluaron múltiples **combinaciones de pipelines bioinformáticos** mediante el uso de distintas herramientas de recorte, estrategias de ensamblado y bases de datos para asignación taxonómica.

---

## 🔬 Objetivo del proyecto

Comparar el impacto de diferentes combinaciones bioinformáticas sobre la detección y clasificación de taxones eucariotas, usando datos reales de muestras fecales de aves.

---

## 🧪 Combinaciones evaluadas

El análisis contempla combinaciones formadas por:

- **Recorte**: `cutadapt`, `trimmomatic_5W`
- **Estrategias de ensamblado**:
  - `concat_CS`: concatenación con script personalizado
  - `concat_CP`: concatenación con PandaSeq
  - `merge_and_concat`: fusión y concatenación con PandaSeq
  - `forward_only`: uso de solo lecturas forward
  - `reverse_only`: uso de solo lecturas reverse
- **Bases de datos** para asignación taxonómica:
  - `PR2`
  - `SILVA132`
  - `SILVA138`

Total de combinaciones: 2 (recortes) × 5 (ensambles) × 3 (BD) = **30 pipelines**

---

## 📁 Estructura del repositorio

data/
├── 01_raw/ # Secuencias FASTQ originales
├── 02_fastqc/ # Informes de calidad con FastQC
├── 02_filtered/ # Lecturas recortadas por estrategia
│ ├── cutadapt/
│ └── trimmomatic_5W/
├── 03_assembled/ # Ensamblado (concat, merge, forward, reverse)
├── 04_dada2_asvs/ # Resultado de DADA2 (ASVs por combinación)
├── 05_taxonomy/ # Clasificación taxonómica (por estrategia y BD)

scripts/
├── 01_filtering/ # Scripts de recorte
├── 02_assembly/ # Scripts de ensamblaje y concatenación
├── 03_dada2/ # Scripts de generación de ASVs
├── 04_tax_assignment/ # Scripts de clasificación taxonómica
├── 05_visualization/ # Scripts para análisis gráfico y estadístico

results/
├── tablas_genero/ # Tablas de abundancia por género
├── graficos/ # Gráficos de diversidad, composición, etc.
└── comparaciones_pipeline/ # Comparaciones cruzadas entre combinaciones

notebooks/ # Jupyter Notebooks para visualización
envs/ # Archivos de entorno (conda, QIIME, etc.)

---

## 🚀 Cómo usar este repositorio

1. Clona este repositorio:
git clone https://github.com/CAMILOMALAVERPEREZ/METABARCODING18S.git
cd METABARCODING18S

2. Ejecuta los scripts en orden, comenzando desde `scripts/01_filtering/`.

3. Coloca tus archivos FASTQ originales en `data/01_raw/`.

4. Revisa los resultados en la carpeta `results/`.

---

## 👨‍🔬 Autor

M. sc Sergio Camilo Malaver Pérez  
Doctorado en Ciencias Biológicas

---

## 📜 Licencia

Este repositorio es de uso académico e investigativo. Puedes adaptarlo, reutilizarlo o citarlo apropiadamente.

# METABARCODING_18S
7a4c811d8fd54ccac71cc3c1362cc41d1466d329
