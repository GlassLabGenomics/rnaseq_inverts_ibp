#!/bin/bash
#SBATCH --job-name=hisatidx
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1G
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

GENOMEFA=$1
INDEXDIR=$2

mkdir -p $(dirname "${INDEXDIR}")

hisat2-build -p ${SLURM_CPUS_PER_TASK} "${GENOMEFA}" "${INDEXDIR}"

mamba deactivate

echo "HISAT2 index build completed."
