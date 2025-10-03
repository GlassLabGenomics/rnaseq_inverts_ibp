#!/bin/bash
#SBATCH --job-name=qualimap
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1GB
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

BAMPATH="/export/scratch/yhsieh/rnaseq/alignments/bamfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/qc_bamfiles"

READSFILE=$1
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

echo "Running qualimap bamqc on ${sampleID}..."

qualimap bamqc -bam "${BAMPATH}/${sampleID}.bam" -outdir "${OUTPATH}/${sampleID}_qc" -nt 8

mamba deactivate
