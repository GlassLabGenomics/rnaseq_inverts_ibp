#!/usr/bin/python3
"""
visualise_blast_tsv.py

Takes in a blast tsv file (fmt 7) and parses it
into a pandas dataframe. Visualises hits as a 
coverage plot in vega-altair.
"""

from pathlib import Path
import pandas as pd
import altair as alt

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


def find_chr_regions(tsvdf):
    """
    Looks into sseqid field of dataframe and finds target chromosomal regions to segment plotting.

    :param tsvdf: pandas dataframe
    :returns chr_regions: set of str
    """
    field = 'sseqid'
    return set(tsvdf[field])

def get_html_out_names(tsvfile, chr_region_set):
    """
    Takes in path to tsvfile, and set of chromosome region names.
    Returns set of HTML file names.

    :param tsvfile: path to tsv file
    :param chr_region_set: list of str from 'sseqid' field
    """
    outfile_list = []
    for region in chr_region_set:
        genome = str(tsvfile.parent)
        query = tsvfile.stem
        ext = '.html'
        outfile_list.append(f'{genome}_{query}_{region}{ext}')
    return outfile_list


def coverage_plot(tsvdf, region, plt_title='coverage plot'):
    """
    Reads in pandas dataframe with blast tsv data.
    Plots coverage plot with genome boundaries on x-axis and 
    percentage identity on y-axis.
    """
    df = tsvdf.loc[tsvdf['sseqid']==region]
    chart = alt.Chart(df).mark_bar().encode(
        x=alt.X('sstart:Q').scale(zero=False),
        x2=alt.X2('send:Q'),
        y=alt.Y('index:N'),
        color=('pident:Q')
        ).properties(
            width=700,
            height=300,
            title=plt_title
            ).interactive()
    return chart


if __name__ == '__main__':

    import argparse

    def argumentsparser():
        parser = argparse.ArgumentParser(usage="python3 %(prog)s [-h] blast_tsvfile", description="plots coverage plot of genomic hits")
        parser.add_argument('blast_tsvfile', help='path to tsvfile', type=str)
        args=parser.parse_args()
        return args
    
    args = argumentsparser()
    tsvfile = Path(args.blast_tsvfile)

    datsdf = parse_in_tsv(tsvfile)
    regionnames = find_chr_regions(datsdf)
    outfileslist = get_html_out_names(tsvfile, regionnames)
    regiondict = dict(zip(regionnames, outfileslist))
    for k, v in regiondict.items():
        covplot = coverage_plot(datsdf, k, v.split('.html')[0]) # 
        covplot.save(v)


        
