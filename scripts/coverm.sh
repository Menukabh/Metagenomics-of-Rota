#!/bin/bash
#SBATCH --account=PAS3107
#SBATCH --time=15:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=menuka/results/logs/coverM/MAGs_counts_%j.output

set -euo pipefail

# Define constant
CONTAINER=oras://community.wave.seqera.io/library/coverm:0.7.0--3f8692fdcfa2f9c7

## Define variables
infile=$1
outfile=$2

echo "input file: $infile"
echo "Output file: $outfile"

echo "Started script for coverM to get counts of MAGs"
date

## Run coverM
#apptainer exec "$CONTAINER" coverm --help
# Follow below to get the abundance coverage as done by IDI
#apptainer exec "$CONTAINER" coverm genome \
    #-b "$infile" \
   # -d menuka/results/dereplicated_MAGS \
    #-m trimmed_mean \
    #--min-read-percent-identity 0.95 \
    #--min-read-aligned-percent 0.75 \
    #--min-covered-fraction 0.70 \
    #-t 4 \
    #> "$outfile"

apptainer exec "$CONTAINER" coverm genome \
    -b "$infile" \
    -d menuka/results/dereplicated_MAGS \
    -m count \
    -t 4 \
    --min-covered-fraction 0 \
    > "$outfile"

# We need to provide MAGS becuase BAM file contain the info of the contig that belong to MAG
# CoverM needs to know which contigs belongs to MAG, 
# Covered fraction means how complete the coverage is or how deep your reads spread across the genome
# It gives completeness of coverage
echo "Successfully Ran coverM to get counts of MAGs"
date