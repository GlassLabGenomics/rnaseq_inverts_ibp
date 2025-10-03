#!/bin/bash
#SBATCH --job-name=transfer
#SBATCH --partition=defq
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=1GB
#SBATCH --time=11:00:00

set -o errexit

module --quiet purge

SOURCEPATH=$1
TARGETPATH=$2

time rsync -azP ${SOURCEPATH} ${TARGETPATH}
