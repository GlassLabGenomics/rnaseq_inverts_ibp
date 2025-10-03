#!/bin/bash
#SBATCH --job-name=samtobam
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem=30G
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load GCC/13.3.0
module load OpenMPI/5.0.3
module load SAMtools/1.21


INPATH="/export/scratch/yhsieh/rnaseq/alignments/samfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/bamfiles"

LISTOFSAMS=$1
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $LISTOFSAMS)

SAMFILE="${sampleID}.sam"
BAMOUT="${sampleID}.bam"
IDXBAMOUT="${sampleID}.bam.bai"

echo "Starting conversion of SAM to BAM...for ${sampleID}"

samtools sort --threads 8 -o ${OUTPATH}/${BAMOUT} ${INPATH}/${SAMFILE}

echo "Conversion of SAM to BAM complete."

echo "Starting indexing of BAM...for ${sampleID}"

samtools index --threads 8 -b ${OUTPATH}/${BAMOUT} ${OUTPATH}/${IDXBAMOUT}

echo "Indexing of BAM complete."
