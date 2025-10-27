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
BAMPATH="/export/scratch/yhsieh/rnaseq/alignments/bamfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/readcounts/m_trossulus"

TRANSCRIPTFILE=$1

READSFILE=$2
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

salmon quant -t "${GENOMEPATH}/${TRANSCRIPTFILE}" -l "A" -a "${BAMPATH}/${sampleID}.bam" -o "${OUTPATH}/${sampleID}_salmon_quant" -p 8

echo 'salmon quant -t "${GENOMEPATH}/${TRANSCRIPTFILE}" -l "A" -a "${BAMPATH}/${sampleID}.bam" -o "${OUTPATH}/${sampleID}_salmon_quant" -p 8'

mamba deactivate
