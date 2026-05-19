#!/bin/bash
#SBATCH --account=PAS3107
#SBATCH --time=01:00:00
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --output=slurm-blastdb_create_%j.output

set -euo pipefail

# Load blast module
module load blast-plus/2.16.0
cd /fs/ess/PAS3107/menuka/amrfinder/amrfinder_db/latest

# Create blast database
makeblastdb -in AMRProt.fa -dbtype prot -parse_seqids

echo "Blast database created"
date