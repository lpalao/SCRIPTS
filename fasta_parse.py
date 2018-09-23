# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

from itertools import groupby
import pandas as pd
import os

def fasta_iter(fasta_name):
    """
    modified from Brent Pedersen
    Correct Way To Parse A Fasta File In Python
    given a fasta file. yield tuples of header, sequence
    """
    "first open the file outside "
    fh = open(fasta_name)

    # ditch the boolean (x[0]) and just keep the header or sequence since
    # we know they alternate.
    faiter = (x[1] for x in groupby(fh, lambda line: line[0] == ">"))

    for header in faiter:
        # drop the ">"
        headerStr = header.__next__()[1:].strip()
        
        # join all sequence lines to one.
        seq = "".join(s.strip() for s in faiter.__next__())
        
        yield (headerStr, seq)

# put all your files into one directory. chdir to that directory
os.chdir("/Users/beatrizpalao/Documents/dna_seq/test")

#input files
fa_file = "349DEGs.fasta"
fa_pp_results = "349DEGs.fasta.results.csv"

df_pp_results = pd.read_csv(fa_pp_results, header = 0, encoding = "ISO-8859-1")
seq_id_pp = df_pp_results["ID"]

faiter = fasta_iter(fa_file)
seq_id_fa = []
seq_fa = []
for ff in faiter:
    headerStr, seq = ff
    seq_id_fa.append(headerStr)
    seq_fa.append(seq)

seq_dict = dict(zip(seq_id_fa, seq_fa))
#seq_dict['ITC1587_BchrUn_random_T39713_consensus']

#some list comprehension here, seq_id = [x for x in seq_id_pp if x in seq_id_fa]
seq_pp = []
for x in seq_id_pp:
    if x in seq_id_fa:
        seq_pp.append(seq_dict[x])

fasta_file = open(os.path.splitext(fa_file)[0] + ".txt", "w")
for i in range(len(seq_id_pp)):
    fasta_file.write(">" + seq_id_pp[i] + "\n" + seq_pp[i] + "\n")

fasta_file.close()

# open file