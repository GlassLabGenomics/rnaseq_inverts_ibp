#!/bin/bash
#SBATCH --job-name=quant
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1GB
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

GENOMEPATH="/export/scratch/yhsieh/rnaseq/genomes/m_trossulus"
READPATH="/export/scratch/yhsieh/rnaseq/rawdata"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/readcounts/m_trossulus"

INDEX=$1

READSFILE=$2
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)


salmon quant -i "${GENOMEPATH}/${INDEX}" -l "A" -1 "${READPATH}/${sampleID}/${sampleID}_1.fq.gz" -2 "${READPATH}/${sampleID}/${sampleID}_2.fq.gz" --validateMappings -o "${OUTPATH}/${sampleID}_salmon_quant" -p 8

mamba deactivate
