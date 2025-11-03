#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=800MB
#SBATCH --time=01:00:00
#SBATCH --array=1-360

set -o errexit

module --quiet purge
module load FastQC/0.12.1-Java-11

### read in folders
FILEWITHPATHS=$1
filename=$(awk "NR==$SLURM_ARRAY_TASK_ID" $FILEWITHPATHS)

### set IO paths
INPATH="/export/scratch/yhsieh/rnaseq/${2}/${filename}"
OUTPATH="/export/scratch/yhsieh/rnaseq/${3}"

echo "===== reading in fastqc files from ${INPATH}"
fastqc -o ${OUTPATH} ${INPATH}
echo "----- writing output to ${OUTPATH}"
