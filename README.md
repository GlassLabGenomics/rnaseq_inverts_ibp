# rnaseq_invert_ibp

RNA-seq analysis workflow for intertidal invertebrates, developed as part of the ice-binding protein (IBP) project. The pipeline covers raw read QC and trimming, genome alignment, transcript assembly, and BLAST-based sequence querying. Work is ongoing to extend the workflow through differential expression and to wrap the full pipeline in Nextflow.

Modular Nextflow components live in [`nf_pipelines/`](https://github.com/GlassLabGenomics/rnaseq_inverts_ibp/tree/master/nf_pipelines). The remaining shell scripts (in [`scripts/`](https://github.com/GlassLabGenomics/rnaseq_inverts_ibp/tree/master/scripts)) represent the step-by-step workflow and have not yet been wrapped into the pipeline. Check on the status below for more information.

## Repository Structure

```
├── images/               # QC comparison plots (adapter content)
├── nf_pipelines/         # Nextflow pipeline modules
│   └── seq_query/        # make_blastdb.nf, run_blast_m2m.nf
│   └── query_summary/    # summarise_blastres.nf
├── scripts/              # Shell scripts for each workflow step
├── README.md
└── useful_links_and_literature.md
```

## Status

| Component | Status |
| -------- | -------- |
| QC → Alignment → StringTie → gffread | Working |
| LAST database build (NF module) | Working |
| Many-to-many BLAST (NF module) | Working |
| Differential expression | In progress |
| Full pipeline Nextflow wrapper | In progress | 


## Environment Setup

All bioinformatics tools are managed via `conda/mamba`. The primary environment is `bioenv`; a separate `env_nf` environment is used for running Nextflow pipelines. Send me an email if you want an exact copy of these environments, or else create the environments on your own machine. Activate the corresponding environment depending on what you want to do.

```bash
# Activate the main analysis environment
mamba activate bioenv

# Or, activate the Nextflow environment
mamba activate env_nf
```

Key tools installed in `bioenv`: `hisat2, samtools, trimmomatic, bbtools, stringtie, gffread, qualimap, bedtools, salmon, mafft, iqtree`

Note on Trimmomatic Java errors on Gombessa: If you hit a Java memory error, load the Java module after activating bioenv and set the library path manually:
```bash
module load Java/21.0.5
export LD_LIBRARY_PATH=/home/yhsieh/.local/easybuild/software/Miniforge3/24.11.3-0/envs/bioenv/lib/jvm/lib/
```
Also reduce threads to 4 and CPUs to 1 in the Trimmomatic script.

## Nextflow Modules [(`nf_pipelines/`)](https://github.com/GlassLabGenomics/rnaseq_inverts_ibp/tree/master/nf_pipelines)
Ready-to-run modular pipelines. Requires `env_nf`.

1. Build a BLAST database: Takes a list of FASTA file paths and builds BLAST-searchable databases.

```
nextflow run nf_pipelines/seq_query/make_blastdb.nf \
  --input_fastalist <path/to/fasta_list.txt> \
  --outdir <path/to/blast_dbs>
```

2. Run many-to-many BLAST: Runs a BLAST search for each query sequence against each database in the provided lists. Supports `blastn, tblastn`, and other BLAST algorithms.

```
nextflow run nf_pipelines/seq_query/run_blast_m2m.nf \
  --query_file   <path/to/query_list.txt> \
  --db_file      <path/to/database_names.txt> \
  --db_location  <path/to/blast_dbs/> \
  --outdir       <path/to/output/> \
  --blast_alg    tblastn \
  --outfmt       7        # optional; default is tabular (6)
```

Output is organized as `<outdir>/<query_name>/<query>_vs_<db>.tsv`

## RNAseq Workflow [(`scripts/`)](https://github.com/GlassLabGenomics/rnaseq_inverts_ibp/tree/master/scripts)
Run steps in order. Array jobs submit one task per sample; single-sample scripts are available for testing.

#### Step 1 — Quality Control (raw reads)

`sbatch --array=1-N scripts/run_fastqc_array.sh`

Then run MultiQC to aggregate reports:

```
# Load MultiQC module (Gombessa: MultiQC/1.28)
# navigate to your folder with all the fastqc files
multiqc --filename rnaseq_qc_report_raw .
```

#### Step 2 — Adapter Trimming

**Option A: Trimmomatic**

`sbatch --array=1-N scripts/run_trimmomatic_array.sh`

**Option B: BBDuk** see Wiki for discussion of comparison between the two

`sbatch scripts/run_bbduk.sh`

#### Step 3 — Quality Control (trimmed reads)

```
sbatch --array=1-N scripts/run_fastqc_array.sh   # or run_fastqc_array_trim.sh
multiqc --filename rnaseq_qc_report_trimmed .
```

#### Step 4 - Genome Alignment (HISAT2)

Build the genome index (run once per genome):

`sbatch scripts/build_hisat2_idx.sh <genome.fna> <index_prefix>`

Run alignment: 

`sbatch --array=1-N scripts/run_hisat2_array.sh`

#### Step 5 - SAM to BAM conversion

`sbatch scripts/convert_sam_bam.sh <list_of_sam_basenames.txt>`

#### Step 6 - Coverage Tracks (optional)

Generate bedGraph files:

`sbatch --array=1-N scripts/run_bedtools_array.sh`

Build genome index for bigWig conversion:

`sbatch scripts/make_genome_idx.sh`

Convert bedGraph to bigWig:

`sbatch scripts/create_bigwig_bg.sh`

#### Step 7 - BAM QC (Qualimap)

`sbatch scripts/get_qc_bamfiles.sh`

#### Step 8 - Transcript Assembly (StringTie)

**8a. Assemble transcripts per sample**

```
sbatch --array=1-9 scripts/run_stringtie_single.sh \
  alignments/reads_truseq3pe_aln_seastar/bamfiles \
  alignments/reads_truseq3pe_aln_seastar/transcriptome \
  alnconfigs/p_helianthoides_aln.config
```

**8b. Merge replicate GTFs per tissue**

```
stringtie --merge UAFJRG0146_1.gtf UAFJRG0146_2.gtf UAFJRG0146_3.gtf -o p_heli_tube_feet.gtf
stringtie --merge UAFJRG0147_1.gtf UAFJRG0147_2.gtf UAFJRG0147_3.gtf -o p_heli_pyloriccaeca.gtf
stringtie --merge UAFJRG0148_1.gtf UAFJRG0148_2.gtf UAFJRG0148_3.gtf -o p_heli_ampullae.gtf
```

#### Step 9 — Extract Transcript Sequences (gffread)

Pull FASTA sequences for genomic regions defined in each tissue GTF:

```
gffread -w p_heli_tube_feet_transcripts.fa \
  -g /path/to/genome/GCA_032158295.1_ASM3215829v1_genomic.fna \
  p_heli_tube_feet.gtf
```

#### Step 10 - Make BLAST Databases from Transcripts

```
sbatch scripts/single_genome_makeblastdb.sh \
  /path/to/p_heli_ampullae_transcripts.fa \
  /path/to/p_heli_ampullae_transcripts
```

### Step 11 - BLAST Query (tBLASTn / BLASTn)
Use the `run_blast_m2m.nf` Nextflow module (see above) or run single queries manually:

`sbatch scripts/search_nuclseq_in_alltissue_transcripts.sh`



### Step 12 - Summarise BLAST Results
Use the `summarise_blastres.nf` Nextflow module (see above) to summarise and visualise the BLAST `.tsv` files produced in Step 11. For each query protein, it reports hit counts per database (`*_hits_summary.tsv`) and, for any query/database pair with hits, an interactive scatter plot of alignment length vs. percent identity (`*_scatter.html`, `pident >= 30`).
