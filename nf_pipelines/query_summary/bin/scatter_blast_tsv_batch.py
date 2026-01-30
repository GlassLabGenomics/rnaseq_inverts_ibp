#!/usr/bin/python3
"""
scatter_blast_tsv_batch.py

To be run via summarise_blastres.nf

Takes in a list of paths to folders containing tsv files.

Parses each blast tsv file (fmt 7) into a pandas dataframe. 
Visualises hits as a multifeature scatter plot in vega-altair.

Does this PER PROTEIN to generate:
1. summary file with how many hits to that protein per database
2. scatter plot per protein of all hits, if non-zero nr. hits
   one scatterplot per protein

To-dos:
[] put header info in to summary, at the parsing step return an additional metadata obj
[] add additional specs to the summary, like average pid, aln length
"""

from pathlib import Path
import pandas as pd
import altair as alt
import os

# /export/scratch/yhsieh/seastars/tblastn_swissprot/O16119

def parse_out_query_db(pathobj):
    filename = Path(pathobj).stem
    parts = filename.split('_vs_')
    if len(parts) != 2:
        print(f"Warning: Unexpected filename format for '{filename}'. Expected exactly one '_vs_' separator.")
        return filename, "unknown_db"
    return parts[0], parts[1]

def get_tsvs_from_path(folderpath):
    """
    Looks into a given directory for tsv files.

    :param folderpath: path to tsv folder
    :returns tsv_paths: list of tsv paths
    """
    try:
        items = os.listdir(folderpath)
        files = [item for item in items if os.path.isfile(os.path.join(folderpath, item))]
        filepaths = [os.path.join(folderpath, filename) for filename in files]
        return filepaths
    except FileNotFoundError:
        print(f"Error: Folder '{folderpath}' not found")
        return []
    except PermissionError:
        print(f"Error: Permission denied to access '{folderpath}'")
        return []

def parse_in_tsv(tabularfile):
    """
    Reads in blast tsv output file.
    Parses to pandas dataframe.

    :param tabularfile: path to tsv file 
    :returns tsv_df: pandas dataframe
    """
    column_names = ['qseqid', 'sseqid', 'pident', 'length', 'mismatch', 'gapopen', 'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore']
    tsvdats = pd.read_csv(tabularfile, sep='\t', header=None, names=column_names, comment='#')
    return tsvdats.reset_index()

def read_in_tsvs(file_list):
    """Reads in a list of file paths,
    converts each file into df, puts in list"""
    tsvdf_list = []
    for tsv in file_list:
        tsvdf_list.append(parse_in_tsv(tsv))
    return tsvdf_list

def concat_tsvdf(tsvdf_list):
    """Concatenates list of tsv dataframes into one,
    or just returns the one, to be used if you want 
    to aggregate hits for the same database 
    (e.g. one species' genome or transcriptome)
    """
    if len(tsvdf_list) != 1:
        return pd.concat(tsvdf_list)
    else:
        return tsvdf_list[0]

def multifeat_scatter_plot(tsvdf):
    """
    Reads in one pandas dataframe with blast tsv data.
    Plots multifeature scatterplot formatted as:
        alignment length (X)
        percentage identity (Y)
        hit scaffold (color)
        bit score (point size)
    """
    chart = alt.Chart(tsvdf).mark_circle().encode(
        alt.X('length').scale(zero=False),
        alt.Y('pident').scale(zero=False, padding=1),
        color='evalue',
        size='bitscore',
        tooltip=['qseqid','sseqid']
        ).properties(
            width=700,
            height=300,
            ).interactive()
    return chart

def summarise_hits(file_paths, tsvdf_list, outdir_path):
    """
    Takes in list of paths to tsvs, and a list of dataframes 
    with blast hits, writes out a summary of hits table, 
    then plots the results with hits in a scatterplot.

    1. table of search results, how many hits
    2. scatterplot for non-zero hit results
    """
    ### make output folder if it doesn't exist
    outdir_path.mkdir(parents=True, exist_ok=True) 
    ### dict of hit results {path:df}
    hitres_dict = dict(zip(file_paths, tsvdf_list))
    ### dataframe of search results
    dbnames, querynames, hitnum = [], [], []
    protid = ''
    for tsvpath, df in hitres_dict.items():
        protid, dbid = parse_out_query_db(tsvpath)
        querynames.append(protid)
        dbnames.append(dbid)
        if not df.empty:
            hitnum.append(len(df))
            above30 = df.loc[df['pident']>=30]
            scatterpt = multifeat_scatter_plot(above30)
            filename = f'{protid}_{dbid}_scatter.html'
            filepath = outdir_path / filename
            scatterpt.save(filepath)
            filtered_df = df[df['pident'] >= 50]
            if not filtered_df.empty:
                filename = f'{protid}_above_50pid.tsv'
                filepath = outdir_path / filename
                filtered_df.to_csv(filepath, sep='\t', index=False)
        else:
            hitnum.append(0)
    summary_dict = {'query':querynames, 'hits':hitnum, 'database':dbnames}
    summary_df = pd.DataFrame(summary_dict)
    filename = f'{protid}_hits_summary.tsv'
    filepath = outdir_path / filename
    summary_df.to_csv(filepath, sep='\t', index=False)
    return 

if __name__ == '__main__':

    import argparse

    def argumentsparser():
        parser = argparse.ArgumentParser(usage="python3 %(prog)s [-h] folderpath outputpath", description="summarizes and plots multifeature scatter plot of genomic hits")
        parser.add_argument('folderpath', help='path to search for tsvs', type=str)
        parser.add_argument('outputpath', help='path to output results', type=str)
        args=parser.parse_args()
        return args
    
    args = argumentsparser()
    folder = Path(args.folderpath)
    outdir = Path(args.outputpath)
    tsvs_in_folder = get_tsvs_from_path(folder)
    tsvdflist = read_in_tsvs(tsvs_in_folder)
    summarise_hits(tsvs_in_folder, tsvdflist, outdir)