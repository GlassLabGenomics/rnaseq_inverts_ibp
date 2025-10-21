# rnaseq_invert_ibp
Collection of scripts for RNA-seq analysis on intertidal inverts

### General Workflow

FASTQC

```
run_fastqc_array.sh
```

TRIMMOMATIC 

```
run_trimmomatic_array.sh
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
