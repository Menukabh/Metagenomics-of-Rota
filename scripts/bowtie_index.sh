#!/bin/bash
#SBATCH --account=PAS3107
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=menuka/results/logs/bowtie_index_%j.output

set -euo pipefail

# Define constant
CONTAINER=oras://community.wave.seqera.io/library/bowtie2:2.5.5--21b0835eb76ba3c0

## Define variables
MAG_catalogue=$1
out_dir=$2

echo "Started script for bowties2 for indexing a MAG catalogue plus"
date

## Run Bowties2
##apptainer exec $CONTAINER bowtie2-build --help
apptainer exec $CONTAINER bowtie2-build \
--large-index \
--threads 4 \
"$MAG_catalogue" "$out_dir"

echo "Successfully Ran bowties2 for indexing"
date