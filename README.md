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
QUALIMAP: `get_qc_bamfiles.sh`


---
STRINGTIE: `run_stringtie_single.sh`

1. aggregate sorted-mapped reads into transcriptomes

<details>

<summary>sample command</summary>

```
sbatch --array=1-9 scripts/run_stringtie_single.sh alignments/reads_truseq3pe_aln_seastar/bamfiles alignments/reads_truseq3pe_aln_seastar/transcriptome alnconfigs/p_helianthoides_aln.config
```


</details>

2. merge replicates for each tissue into one single tissue-based gtf

<details>

<summary>sample command</summary>

```
stringtie --merge UAFJRG0146_1.gtf UAFJRG0146_2.gtf UAFJRG0146_3.gtf -o p_heli_tube_feet.gtf
stringtie --merge UAFJRG0147_1.gtf UAFJRG0147_2.gtf UAFJRG0147_3.gtf -o p_heli_pyloriccaeca.gtf
stringtie --merge UAFJRG0148_1.gtf UAFJRG0148_2.gtf UAFJRG0148_3.gtf -o p_heli_ampullae.gtf
```

</details>

GFFREAD

pull out sequences corresponding to the genomic regions defined in GTF file per tissue per species

<details>

<summary>sample command</summary>

```
gffread -w p_heli_tube_feet_transcripts.fa -g $SCRATCH/rnaseq/genomes/p_helianthoides/GCA_032158295.1_ASM3215829v1_genomic.fna p_heli_tube_feet.gtf
```

</details>
