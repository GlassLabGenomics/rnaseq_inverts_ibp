# rnaseq_invert_ibp
Collection of scripts for RNA-seq analysis on intertidal inverts

### General Workflow

FASTQC

---

```
run_fastqc_array.sh
```

---

MULTIQC
- load the gombessa module MultiQC/1.28
- navigate into your folder with all the fastqc files

`multiqc --filename rnaseq_qc_report .`

---

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
---

FASTQC

```
run_fastqc_array.sh
```
---

MULTIQC

---

HISAT2
- build index
- run alignment
  
```
build_hisat2_idx.sh
run_hisat2_array.sh
```
---

SAM to BAM conversion

```
convert_sam_bam.sh
```
---

BEDTOOLS
- bedgraph

```
run_bedtools_array.sh
```

---

GENOME INDEX

```
make_genome_idx.sh
```

---

BIGWIG

```
create_bigwig_bg.sh
```

---
QUALIMAP

```
get_qc_bamfiles.sh
```

STRINGTIE

join together sorted and mapped reads into transcripts

GFFREAD

sample command

```
gffread -w p_heli_tube_feet_transcripts.fa -g $SCRATCH/rnaseq/genomes/p_helianthoides/GCA_032158295.1_ASM3215829v1_genomic.fna p_heli_tube_feet.gtf
```
