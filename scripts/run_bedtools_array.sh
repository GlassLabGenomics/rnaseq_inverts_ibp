#!/bin/bash
#SBATCH --job-name=bedtools
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1G
#SBATCH --time=01:00:00

set -o errexit

module --quiet purge
module load GCC/13.3.0
module load BEDTools/2.31.1

INPATH="/export/scratch/yhsieh/rnaseq/alignments/bamfiles"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments/bedgraphfiles"

READSFILE=$1
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

BAMFILE="${sampleID}.bam"
BGOUT="${sampleID}.bg"

echo "Starting Bedtools to make bedgraph...${sampleID}"

bedtools genomecov -ibam ${INPATH}/${BAMFILE} -split -bg > ${OUTPATH}/$BGOUT

echo "Bedgraph complete."

