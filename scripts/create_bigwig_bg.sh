#!/bin/bash
#SBATCH --job-name=bigwig
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=5MB
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

GENOMEPATH="/export/scratch/yhsieh/rnaseq/genomes"
INPATH="/export/scratch/yhsieh/rnaseq/alignments/bedgraphfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/bigwigfiles"

GENOME=$1

READSFILE=$2
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

bedGraphToBigWig "${INPATH}/${sampleID}.bg" "${GENOMEPATH}/${GENOME}/${GENOME}.fa.fai" "${OUTPATH}/${sampleID}.bw"

mamba deactivate
