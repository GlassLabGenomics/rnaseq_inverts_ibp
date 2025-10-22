#!/bin/bash
#SBATCH --job-name=trim
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem=3GB
#SBATCH --time=03:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

module load Java/21.0.5

export LD_lIBRARY_PATH=/home/yhsieh/.local/easybuild/software/Miniforge3/24.11.3-0/envs/bioenv/lib/jvm/lib/

DIRLIST=$1
SAMPLNAME=$(awk "NR==$SLURM_ARRAY_TASK_ID" $DIRLIST)

RAWDATDIR=$2
TRIMDATDIR=$3
TRIMLOGDIR=$4

THREADS=4

trimlog_suffix="_trimmomatic.log"
read1file_suffix="_1.fq.gz"
read2file_suffix="_2.fq.gz"
trim_basename="_trim.fq.gz"

echo time trimmomatic PE -threads $THREADS -phred33 \
	-trimlog "${TRIMLOGDIR}/${SAMPLNAME}${trimlog_suffix}" \
	"${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read1file_suffix}" \
	"${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read2file_suffix}" \
	-baseout "${TRIMDATDIR}/${SAMPLNAME}${trim_basename}" \
	ILLUMINACLIP:TruSeq3-PE-2-GGGGG.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

time trimmomatic PE -threads $THREADS -phred33 \
	-trimlog "${TRIMLOGDIR}/${SAMPLNAME}${trimlog_suffix}" \
	"${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read1file_suffix}" \
	"${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read2file_suffix}" \
	-baseout "${TRIMDATDIR}/${SAMPLNAME}${trim_basename}" \
	ILLUMINACLIP:TruSeq3-PE-2-GGGGG.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

mamba deactivate
