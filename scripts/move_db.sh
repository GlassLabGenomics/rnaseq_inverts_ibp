#!/bin/bash
#SBATCH --job-name=moveblast
#SBATCH --partition=transfer
#SBATCH --nodes=1

set -o errexit
#set -o nounset
module --quiet purge 

### Read in paths
SOURCEDIR=$1
DESTDIR=$2

rsync -av $SOURCEDIR $DESTDIR
