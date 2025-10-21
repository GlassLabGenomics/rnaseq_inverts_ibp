# rnaseq_invert_ibp
Collection of scripts for RNA-seq analysis on intertidal inverts

### General Workflow

FASTQC

```
run_fastqc_array.sh
```

TRIMMOMATIC 
- if there is a java memory error, you need to load the java module after activating your mamba env, and give the full path as such:
```
module load Java/21.0.5
export LD_lIBRARY_PATH=/home/yhsieh/.local/easybuild/software/Miniforge3/24.11.3-0/envs/bioenv/lib/jvm/lib/
```
- not sure why this is an error now on gombessa
- reduce nr of threads to 4 and cpu to 1

```
run_trimmomatic_array.sh
```

or BBDUK

```
run_bbduk.sh
```

FASTQC

```
run_fastqc_array.sh
```

HISAT2
- build index
- run alignment
  
```
run_hisat2_array.sh
```

SAM to BAM conversion

```
convert_sam_bam.sh
```

BEDTOOLS
- bedgraph

```
run_bedtools_array.sh
```
  
GENOME INDEX

```
make_genome_idx.sh
```

BIGWIG

```
create_bigwig_bg.sh
```

QUALIMAP

```
get_qc_bamfiles.sh
```
