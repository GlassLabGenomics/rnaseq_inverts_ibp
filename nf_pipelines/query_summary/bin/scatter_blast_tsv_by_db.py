#!/usr/bin/python3
"""
scatter_blast_tsv_by_db.py

To be run as an alone-standing CL script.

Takes in a list of paths to folders containing tsv files.

Parses each blast tsv file (fmt 7) into a pandas dataframe. 
Visualises all hits together as a multifeature scatter plot in vega-altair.

Does this PER DATABASE to generate:
1. summary file with how many hits to that protein per database
2. scatter plot per database of all hits to all proteins, if non-zero nr. hits,
   one scatterplot per database
"""

from pathlib import Path
import pandas as pd
import altair as alt
import os

def parse_out_query_db(pathobj):
    filename = Path(pathobj).stem
    parts = filename.split('_vs_')
    if len(parts) != 2:
        print(f"Warning: Unexpected filename format for '{filename}'. Expected exactly one '_vs_' separator.")
        return filename, "unknown_db"
    # protid, dbid
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
    
def aggregate_tsvpaths_by_db(filewithfolderpaths):
    """
    Loops over each folder to get a master list of all tsv files.
    Subsets them based on database.

    :param filewithfolderpaths: path to file with list of folders
    :returns datadict: dict of form {'db':[tsvpathlist]}
    """
    folderpath_list = []
    with open(filewithfolderpaths, 'r') as f:
        for line in f.readlines():
            folder = line.strip()
            if not folder or folder.startswith('#'):
                continue
            folderpath_list.append(folder)

     # collect all tsv files from the listed folders
    all_tsvs = []
    for folder in folderpath_list:
        tsvs = get_tsvs_from_path(folder)
        if tsvs:
            all_tsvs.extend(tsvs)

    # aggregate by database id parsed from filenames
    datadict = {}
    for tsvpath in all_tsvs:
        _, dbid = parse_out_query_db(tsvpath)
        datadict.setdefault(dbid, []).append(tsvpath)

    return datadict

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
    
def aggregate_tsvdata_by_db(dictofdb_vs_tsvs):
    """Takes in a dict of format {'db':[tsvpath1, tsvpath2, ...]}
    Parses each tsv into pandas dataframe.
    Concatenates the non-empty ones into one final df.

    Checks if there are no tsvs associated with the folder.
    Checks if there are no hits in the tsvs.
    """
    tsvdata_aggr_by_db = {}
    for db, tsvpathlist in dictofdb_vs_tsvs.items():
        if not tsvpathlist: 
            tsvdata_aggr_by_db[db] = pd.DataFrame()
        else:
            df_list = read_in_tsvs([Path(item) for item in tsvpathlist])
            # keep only dfs with hits
            non_empty = [df for df in df_list if not df.empty]
            if not non_empty:
                tsvdata_aggr_by_db[db] = pd.DataFrame()
            else:
                tsvdata_aggr_by_db[db] = concat_tsvdf(non_empty)
    return tsvdata_aggr_by_db

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

def summarise_hits_by_db(filewithfolderpaths, outdir_path):
    """
    Takes in list of paths to folders, and an output path.
    Makes scatterplot of hits per db.
    Makes aggregated summary of hits per db.
    """
    # make output folder if it doesn't exist
    outdir_path.mkdir(parents=True, exist_ok=True) 

    dictofpaths_per_db = aggregate_tsvpaths_by_db(Path(filewithfolderpaths))
    dictofhits_per_db = aggregate_tsvdata_by_db(dictofpaths_per_db)

    for db, df in dictofhits_per_db.items():
        # make the aggregate scatterplot
        above30 = df.loc[df['pident']>=30]
        scatterpt = multifeat_scatter_plot(above30)
        filename = f'aggregated_{db}_scatter.html'
        filepath = outdir_path / filename
        scatterpt.save(filepath)
        # make the summary file
        summary = df.groupby('qseqid').agg({
            'sseqid': 'nunique',  # Number of unique sequences hit
            'pident': ['mean', 'max'], # Average and best percent identity
            'length': 'mean', # Average alignment length
            'evalue': 'min',  # Best (lowest) e-value
            'bitscore': 'max',  # Best bitscore
            'qseqid': 'count'}).round(2)

        # Rename the count column
        summary.columns = ['unique_hits', 'avg_pident', 'max_pident','avg_length', 'best_evalue', 'best_bitscore', 'total_hits']

        # Write to text file
        filename = f'aggregated_{db}_summary.txt'
        filepath = outdir_path / filename
        with open(filepath, 'w') as f:
            f.write("BLAST Results Summary by Query Sequence\n")
            f.write("=" * 80 + "\n\n")
    
            for qseq in summary.index:
                f.write(f"Query: {qseq}\n")
                f.write(f"  Total hits: {summary.loc[qseq, 'total_hits']}\n")
                f.write(f"  Unique subjects: {summary.loc[qseq, 'unique_hits']}\n")
                f.write(f"  Average % identity: {summary.loc[qseq, 'avg_pident']:.2f}%\n")
                f.write(f"  Max % identity: {summary.loc[qseq, 'max_pident']:.2f}%\n")
                f.write(f"  Average alignment length: {summary.loc[qseq, 'avg_length']:.2f}\n")
                f.write(f"  Best e-value: {summary.loc[qseq, 'best_evalue']:.2e}\n")
                f.write(f"  Best bitscore: {summary.loc[qseq, 'best_bitscore']}\n")
                f.write("\n")

        print(f'Summary written to aggregated_{db}_summary.txt')

if __name__ == '__main__':

    import argparse

    def argumentsparser():
        parser = argparse.ArgumentParser(usage="python %(prog)s [-h] filewithfolderpaths outputpath", description="summarizes and plots multifeature scatter plot of genomic hits, per database")
        parser.add_argument('filewithfolderpaths', help='path to file with folder paths', type=str)
        parser.add_argument('outputpath', help='path to output results', type=str)
        args=parser.parse_args()
        return args
    
    args = argumentsparser()
    folders = Path(args.filewithfolderpaths)
    outdir = Path(args.outputpath)

    summarise_hits_by_db(folders, outdir)
