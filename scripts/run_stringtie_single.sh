#!/bin/bash
#SBATCH --job-name=stringtie
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1G
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

BAMPATH=$1 ##directory with sorted BAM files
OUTPATH=$2 ##directory to output GTF files

SAMPLESFILE=$3 ##config file with sample IDs
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $SAMPLESFILE)

BAMFILE="${sampleID}.bam"
GTFOUT="${sampleID}.gtf"

echo "Starting StringTie transcriptome assembly..."

echo "stringtie ${BAMPATH}/${BAMFILE} -o ${OUTPATH}/${GTFOUT} -p $SLURM_CPUS_PER_TASK"

stringtie ${BAMPATH}/${BAMFILE} -o ${OUTPATH}/${GTFOUT} -p $SLURM_CPUS_PER_TASK

echo "StringTie on ${sampleID} complete."

mamba deactivate
