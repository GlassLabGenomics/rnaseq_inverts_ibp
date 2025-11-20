#!/usr/bin/env nextflow

/*
 * Pipeline parameters
 */
params.input_fastalist = "${projectDir}/transcripts_file.txt"
params.outdir = "${projectDir}/database"
params.dbtype = "nucl"

/*
 * Print pipeline parameters
 */
log.info """\
    MAKE BLAST DATABASE PIPELINE
    ===================================
    fasta file(s)  : ${params.input_fastalist}
    output folder  : ${params.outdir}
    database type  : ${params.dbtype}
    """
    .stripIndent()

/*
 * Create channels for input files
 */
fasta_ch = Channel
    .fromPath(params.input_fastalist)
    .splitText()
    .map { it.trim() }
    .map { filepath -> 
        def inputfile = file(filepath)
        def sampleid = inputfile.simpleName
        return tuple(sampleid, filepath)
    }

/*
 * Generate blast db files
 */
process MAKE_BLASTdb {
    tag "$sample_id"
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
