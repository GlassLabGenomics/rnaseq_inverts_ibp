#!/bin/bash
#SBATCH --job-name=hisat_aln
#SBATCH --partition=defq
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=1G
#SBATCH --time=04:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

INPATH="/export/scratch/yhsieh/rnaseq/trimdata_TruSeq3PE/paired"
OUTPATH="/export/scratch/yhsieh/rnaseq/alignments"

HISAT2IDX=$1
READSFILE=$2
sampleID=$(awk "NR==$SLURM_ARRAY_TASK_ID" $READSFILE)

R1FQ="${sampleID}_trim_1P.fq.gz"
R2FQ="${sampleID}_trim_2P.fq.gz"
SAMOUT="${sampleID}.sam"
SUMMARYOUT="${sampleID}_hisat2_summary.txt"

echo "Starting HISAT2 alignment..."
hisat2 \
    -p $SLURM_CPUS_PER_TASK \
    -x ${HISAT2IDX} \
    -1 ${INPATH}/${R1FQ} \
    -2 ${INPATH}/${R2FQ} \
    --summary-file ${OUTPATH}/${SUMMARYOUT} \
    --dta \
    -S ${OUTPATH}/${SAMOUT}

echo "HISAT2 alignment complete."

mamba deactivate
