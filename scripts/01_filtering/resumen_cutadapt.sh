#!/bin/bash

# Crear carpeta de resultados si no existe
mkdir -p results/filtered_cutadapt

# Archivo de salida
OUTFILE="results/filtered_cutadapt/resumen_cutadapt.tsv"
echo -e "Archivo\tNumSecuencias\tBasesTotales\tBasesPromedio\tSecuencias<210bp" > "$OUTFILE"

# Iterar sobre archivos
for archivo in data/02_filtered/cutadapt/*.fastq; do
    nombre=$(basename "$archivo")
    
    # Número total de secuencias
    num_seqs=$(grep -c "^+$" "$archivo")

    # Longitudes de cada secuencia
    total_bases=$(awk 'NR%4==2 {total+=length($0)} END {print total}' "$archivo")

    # Secuencias menores a 210bp
    menores210=$(awk 'NR%4==2 {if(length($0)<210) c++} END {print c}' "$archivo")

    # Promedio
    if [ "$num_seqs" -gt 0 ]; then
        prom=$(echo "$total_bases / $num_seqs" | bc)
    else
        prom=0
    fi

    # Guardar resultados
    echo -e "$nombre\t$num_seqs\t$total_bases\t$prom\t$menores210" >> "$OUTFILE"
done

echo "✅ Resumen generado: $OUTFILE"
