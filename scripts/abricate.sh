#!/bin/bash
#SBATCH --account=PAS3107
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=results/logs/Abricate/slurm-vir_%j.output

set -euo pipefail

# Define constant
CONTAINER=oras://community.wave.seqera.io/library/abricate:1.2.0--7c88ad85ae2e42ea

## Define variables
db=$1
fasta=$2
outfile=$3

echo "Started script for abricate to find virulence genes"
date

## Run AMRfinder plus
apptainer exec "$CONTAINER" abricate \
--db "$db" \
"$fasta" \
> "$outfile"

echo "Successfully Ran abricate to find virulence genes"
date