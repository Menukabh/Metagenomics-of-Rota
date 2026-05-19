#!/bin/bash
#SBATCH --account=PAS3107
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=menuka/results/logs/slurm-AMRgenes_%j.output

set -euo pipefail

# Define constant
CONTAINER=oras://community.wave.seqera.io/library/ncbi-amrfinderplus:4.2.7--83fb0e0d410b6f76

## Define variables
fasta=$1
database=$2
outfile=$3

echo "Started script for AMRFinder plus"
date

## Run AMRfinder plus
apptainer exec $CONTAINER amrfinder \
-p "$fasta" \
--database "$database" \
-o "$outfile"


echo "Successfully Ran AMRfinder plus"
date