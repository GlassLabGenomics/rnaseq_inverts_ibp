#!/bin/bash
#SBATCH --job-name=hisat_aln
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1G
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

HISAT2IDX=$1
R1FQ=$2
R2FQ=$3
SAMOUT=$4

echo "Starting HISAT2 alignment..."
hisat2 \
    -p $SLURM_CPUS_PER_TASK \
    -x ${HISAT2IDX} \
    -1 ${R1FQ} \
    -2 ${R2FQ} \
    --dta \
    -S ${SAMOUT}

echo "HISAT2 alignment complete."

mamba deactivate

