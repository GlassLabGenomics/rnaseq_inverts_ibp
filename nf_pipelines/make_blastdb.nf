#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */
params.input_fasta = "${projectDir}/transcripts/*fa"
// params.input_fasta = "${projectDir}/transcripts/p_heli_pyloriccaeca_transcripts.fa"
params.outdir = "database"
params.dbtype = "nucl"

/*
 * Print pipeline parameters
 */
log.info """\
    MAKE BLAST DBS PIPELINE
    ===================================
    fasta file(s)  : ${params.input_fasta}
    output folder  : ${params.outdir}
    database type  : ${params.dbtype}
    """
    .stripIndent()

/*
 * Create channels for input files
 */
fasta_ch = Channel
    .fromPath(params.input_fasta)
    .map { file -> tuple(file.baseName, file) }

/*
 * Generate blast db files
 */
process MAKE_BLASTdb {

    publishDir params.outdir, mode: 'symlink'

    input:
        tuple val(sample_id), path(fasta)

    output:
        tuple val(sample_id), path("${sample_id}_db.ndb")
        tuple val(sample_id), path("${sample_id}_db.nhr")
        tuple val(sample_id), path("${sample_id}_db.nin")
        tuple val(sample_id), path("${sample_id}_db.njs")
        tuple val(sample_id), path("${sample_id}_db.nog")
        tuple val(sample_id), path("${sample_id}_db.nos")
        tuple val(sample_id), path("${sample_id}_db.not")
        tuple val(sample_id), path("${sample_id}_db.nsq")
        tuple val(sample_id), path("${sample_id}_db.ntf")
        tuple val(sample_id), path("${sample_id}_db.nto")

    script:
    """
    #!/bin/bash

    # clear and load necessary modules
    module --quiet purge
    module load GCC/13.3.0
    module load OpenMPI/5.0.3
    module load BLAST+/2.16.0

    # run makeblastdb
    makeblastdb -in '$fasta' -out '${sample_id}_db' -parse_seqids -dbtype '${params.dbtype}'
    """
}

workflow {

    // Create index file for input BAM file
    MAKE_BLASTdb(fasta_ch)
}

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Results directory: ${params.outdir}"
}
