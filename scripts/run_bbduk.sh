#!/bin/bash
#SBATCH --job-name=bbduk
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem=4GB
#SBATCH --time=03:00:00

set -o errexit

module --quiet purge
module load Miniforge3/24.11.3-0

source ~/.bashrc
mamba activate bioenv

#module load Java/21.0.5

#export LD_lIBRARY_PATH=/home/yhsieh/.local/easybuild/software/Miniforge3/24.11.3-0/envs/bioenv/lib/jvm/lib/

DIRLIST=$1
SAMPLNAME=$(awk "NR==$SLURM_ARRAY_TASK_ID" $DIRLIST)

RAWDATDIR=$2
TRIMDATDIR=$3
TRIMLOGDIR=$4

trimlog_suffix="_bbduk.log"
read1file_suffix="_1.fq.gz"
read2file_suffix="_2.fq.gz"
trim_basename="_trim.fq.gz"

time bbduk.sh \
	-Xmx2g \
	in1="${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read1file_suffix}" \
	in2="${RAWDATDIR}/${SAMPLNAME}/${SAMPLNAME}${read2file_suffix}" \
	out1="${TRIMDATDIR}/${SAMPLNAME}_1${trim_basename}" \
	out2="${TRIMDATDIR}/${SAMPLNAME}_2${trim_basename}" \
	outm="${TRIMDATDIR}/${SAMPLNAME}_unpaired${trim_basename}" \
	ref=adapters \
	ktrim=r \
	k=23 \
	mink=11 \
	hdist=1 \
	qtrim=rl \
	trimq=15 \
	minlen=50 \
	tbo \
	tpe \
	stats="${TRIMLOGDIR}/${SAMPLNAME}${trimlog_suffix}" \
	overwrite=true
	

mamba deactivate
