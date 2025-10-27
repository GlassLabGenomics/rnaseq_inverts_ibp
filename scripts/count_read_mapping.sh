#!/bin/bash
#SBATCH --job-name=qualimap
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2GB
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

BAMPATH="/export/scratch/yhsieh/rnaseq/alignments/bamfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/readcounts"

READSFILE=$1
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

GTFFILE=$2

echo "Running qualimap rnaseq on ${sampleID}..."

qualimap comp-counts -bam "${BAMPATH}/${sampleID}.bam" -gtf "${GTFFILE}" -out "${OUTPATH}/${sampleID}_counts"  

mamba deactivate
