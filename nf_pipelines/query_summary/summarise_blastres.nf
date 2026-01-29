#!/usr/bin/env nextflow

/*
 * Pipeline default parameters
 */
params.input_folderlist = "${projectDir}/folderpaths.txt"
params.outdir = "${projectDir}/test"

/*
 * Print help message
 */
def helpMessage() {
    log.info"""
    ================================================================
    Summarise Blast Results Pipeline
    ================================================================
    
    Usage:
      nextflow run ${workflow.scriptName} --input_folderlist <file> --outdir <dir>
    
    Required arguments:
      --input_folderlist    Path to text file containing absolute 
                            paths to folders containg Blast tsvs 
                            (one per line)
    
    Optional arguments:
      --outdir              Output directory (default: ${params.outdir})
      --help                Show this help message and exit
    
    ================================================================
    """.stripIndent()
}

// Show help message if requested
if (params.help) {
    helpMessage()
    exit 0
}

/*
 * Print pipeline parameters
 */
log.info """\
    SUMMARISE BLAST PIPELINE
    ===================================
    fasta file(s)  : ${params.input_folderlist}
    output folder  : ${params.outdir}
    """
    .stripIndent()

/*
 * Create channels for input folders
 */
folder_ch = Channel
    .fromPath(params.input_folderlist)
    .splitText()
    .map { it.trim() }
    .map { folderpath -> 
        def folder = file(folderpath)
        def foldername = folder.baseName
        return tuple(foldername, folderpath)
    }

/*
 * Generate blast db files
 */
process SUMMARISE_Blasthits {
    tag "$foldername"
    publishDir params.outdir, mode: 'move'
    //conda '/home/yhsieh/.conda/envs/bioenv'

    input:
        tuple val(foldername), val(folderpath)

    output:
    path("*hits_summary.tsv"), optional: true
    path("*.html"), optional: true

    script:
    """
    echo "Processing folder: ${foldername}"
    echo "Folder path: ${folderpath}"
    /home/yhsieh/.conda/envs/bioenv/bin/python ${projectDir}/bin/scatter_blast_tsv_batch.py ${folderpath} .
    """
}

workflow {

    // Create index file for input BAM file
    SUMMARISE_Blasthits(folder_ch)
}

workflow.onComplete {
    log.info "Pipeline completed at: $workflow.complete"
    log.info "Execution status: ${ workflow.success ? 'OK' : 'failed' }"
    log.info "Results directory: ${params.outdir}"
}
