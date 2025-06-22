
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

- **Recorte**: `cutadapt`, `trimmomatic_5W`, `fastp`
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

Total de combinaciones: 3 (recortes) × 5 (ensambles) × 3 (BD) = **45 pipelines**

---
## 🧰 Análisis de calidad posterior al recorte

Después de aplicar los filtros con **cutadapt** y **trimmomatic**, se ejecutaron análisis complementarios para evaluar el efecto del recorte sobre la calidad de las secuencias y las características de los fragmentos:

- **Resumen de filtrado:** total de secuencias, bases y porcentaje de pérdida tras el recorte.
- **Bases con calidad Q<20:** conteo y porcentaje de bases por debajo del umbral Q20.
- **Distribución de tamaños:** distribución de longitudes de secuencias tras el filtrado.

Los resultados de estos análisis se encuentran organizados en:
results/
└── resumen_filtrado/
├── cutadapt_Q20/
│ ├── tabla_resumen_cutadapt
│ ├── resumen_bases_Q20
│ └── distribucion_tamanos
├──trimmomatic_Q20/
│ ├── tabla_resumen_trimmomatic
│ ├── resumen_bases_Q20
│ └── distribucion_tamanos
├── fastp_Q20/
│ ├── tabla_resumen_fastp
│ ├── resumen_bases_Q20
│ └── distribucion_tamanos
Estos archivos pueden utilizarse para análisis estadísticos y visualización comparativa entre métodos de filtrado.

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
├── 01_filtering/
│   ├── cutadapt_batch.sh             # Recorte con Cutadapt
│   ├── trimmomatic_batch_SE.sh          # Recorte con Trimmomatic
│   ├── fastp_run.sh                # Recorte con fastp
├── 02_assembly/ # Scripts de ensamblaje y concatenación
├── 03_dada2/ # Scripts de generación de ASVs
├── 04_tax_assignment/ # Scripts de clasificación taxonómica
├── 05_visualization/ # Scripts para análisis gráfico y estadístico

results/
├── tablas_genero/ # Tablas de abundancia por género
├── graficos/ # Gráficos de diversidad, composición, etc.
├── comparaciones_pipeline/ # Comparaciones cruzadas entre combinaciones
├── resumen_filtrado/ # Resultados de calidad y fragmentación post-filtrado

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
Doctorante en Ciencias Quimico Biológicas

---

## 📜 Licencia

Este repositorio es de uso académico e investigativo. Puedes adaptarlo, reutilizarlo o citarlo apropiadamente.


