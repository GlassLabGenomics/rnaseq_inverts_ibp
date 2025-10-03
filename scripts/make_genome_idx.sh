#!/bin/bash
#SBATCH --job-name=indexfa
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem=100MB
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load GCC/13.3.0
module load OpenMPI/5.0.3
module load SAMtools/1.21


INPATH="/export/scratch/yhsieh/rnaseq/genomes"
OUTPATH="/export/scratch/yhsieh/rnaseq/genomes"

GENOMEDIR=$1
GENOMEFILE=$2

echo "Starting indexing of reference genome...for ${GENOMEDIR}"

samtools faidx ${INPATH}/${GENOMEDIR}/${GENOMEFILE} -o ${OUTPATH}/${GENOMEDIR}/${GENOMEDIR}.fa.fai -@ 8

echo "Indexing of reference genome complete."
