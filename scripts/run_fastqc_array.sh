#!/bin/bash
#SBATCH --job-name=fastqc
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=800MB
#SBATCH --time=01:00:00
#SBATCH --array=1-90

### check arguments
if [ "$#" -ne 2 ]; then
	echo "Usage: $0 folderfile outpath"
	echo "folderfile: txt file with list of sample folders"
	echo "outpath: path to output folder for fastqc outputh"
	exit 1
fi

set -o errexit

module --quiet purge
module load FastQC/0.12.1-Java-11

### read in folders
FILEWITHPATHS=$1
findfolder=$(awk "NR==$SLURM_ARRAY_TASK_ID" $FILEWITHPATHS)

### set IO paths
INPATH="/export/scratch/yhsieh/rnaseq/rawdata/${findfolder}"
OUTPATH="/export/scratch/yhsieh/rnaseq/${2}"

for qcfile in ${INPATH}/*.fq.gz
do
	echo "===== reading in fastqc files from ${INPATH}"
	echo "+++++ starting on ${qcfile}"
        fastqc -o ${OUTPATH} $qcfile
	echo "----- writing output to ${OUTPATH}"
done
