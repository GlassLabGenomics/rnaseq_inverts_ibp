#!/usr/bin/env nextflow

/*
 * Pipeline default parameters
 */
params.query_file = "${projectDir}/query_list.txt"
params.db_file = "${projectDir}/database_list.txt"
params.db_location = "${projectDir}/database"
params.outdir = "${projectDir}/blast_results"
params.blast_alg = "blastn"
params.evalue = "1e-5"
params.max_target_seqs = 100
params.outfmt = 7


/*
 * Print help message
 */
 def helpMessage() {
    log.info"""
    === Run Blast 'Many-to-Many': Fastas x DBs ===
    
    Usage:
      nextflow run ${workflow.scriptName} [--query_file filewithfastapaths] [--db_file filewithdbnames] [--db_location path] [--outdir path]
    
    Example:
        nextflow run run_blast_m2m.nf -profile slurmlite -with-trace trace.txt
    
    Required arguments (check defaults in the script):
      --query_file  file with paths to fasta inputs
      --db_file     file with database names (not paths)
      --db_location path to database location (one folder only)
      --outdir      path to output results
    
    Optional arguments:
      -profile              run with slurm profile in nextflow.config
      --outdir              output directory (default: ${params.outdir})
      --blast_alg           'blastn', 'blastp', etc: default = ${params.blast_alg})
      --evalue              default = ${params.evalue}
      --max_target_seqs     default = ${params.max_target_seqs}
      --outfmt              default = ${params.outfmt}
      --help                show this help message and exit
    """.stripIndent()
}

 /*
 * Run blast for each query fasta against each database
 */
 process runBlast {

    tag "${sample_id}_vs_${db_id}"
    publishDir { "${params.outdir}/${sample_id}" }, mode: 'copy'

    input:
    tuple val(sample_id), path(fasta_path)
    each db_id
    val ext

    output:
    path "${sample_id}_vs_${db_id}.${ext}"

    script:
    """
    #!/bin/bash

    # clear and load necessary modules
    module --quiet purge
    module load GCC/13.3.0
    module load OpenMPI/5.0.3
    module load BLAST+/2.16.0

    # set path to look for db files
    export BLASTDB="${params.db_location}"

    # run blast many-to-many
    ${params.blast_alg} \
        -query ${fasta_path} \
        -db ${db_id} \
        -out "${sample_id}_vs_${db_id}.${ext}" \
        -evalue ${params.evalue} \
        -max_target_seqs ${params.max_target_seqs} \
        -outfmt ${params.outfmt} \
        -num_threads ${task.cpus}
    """
 }

 /*
 * Workflow
 */

 workflow {
    // Show help message if requested
    if (params.help) {
        helpMessage()
        exit 0
    }
    /*
    * Print pipeline parameters
     */
     log.info """\
        BLAST MANY-to-MANY PIPELINE
        ===================================
        fasta files    : ${params.query_file}
        database list  : ${params.db_file}
        database path  : ${params.db_location}
        blast type     : ${params.blast_alg}
        output dir     : ${params.outdir}
        e-value        : ${params.evalue}
        max targets    : ${params.max_target_seqs}
        output format  : ${params.outfmt}
        """.stripIndent()
    /*
    * Create I/O channels
    */
    query_ch = Channel
        .fromPath(params.query_file)
        .splitText()
        .map { it.trim() }
        .map { filepath ->
            def f = file(filepath)
            tuple(f.simpleName, f)
        }

    db_ch = Channel
        .fromPath(params.db_file)
        .splitText()
        .map { it.trim() }

    def ext = (params.outfmt in [6, 7]) ? "tsv" : (params.outfmt in [5, 14, 16]) ? "xml" : "tab"
    runBlast(query_ch, db_ch, ext)
 }
