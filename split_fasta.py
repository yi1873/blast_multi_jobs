# -*- coding: utf-8 -*-
'''
Author: xiang_zhi_@126.com
Date:   2017/06/13
Used:   split fasta file into a number of subfiles in *.cut folder
Usage:  python $0 -i <input fasta> -n <num of subfile to product>
        eg: python split_fasta.py -i test.fa -n 100
            results in test.fa.cut folder
'''
from Bio import SeqIO
import argparse
import sys
import re
import os
import string


parser = argparse.ArgumentParser(description='Split a FASTA file into a number of subfiles')
parser.add_argument('-i', type=file, help='Input FASTA file, to link the fasta file to the current directory')
parser.add_argument('-n', type=int, help='Number of subfiles to split ')
argv = vars(parser.parse_args())

filein = argv['i'] # no path, to link the fasta file to the current directory
prefix = str(filein).split(r"'")[1]  # prefix of output
num = argv['n']

record_count = 0
for line in filein:
    if line.lstrip().startswith('>'):
        record_count += 1

records_per_chunk = round(float(record_count) / num )

#output_dir
if os.path.isdir(prefix + '.cut'):
    pass
else:
    os.mkdir(prefix + '.cut')

count = 1
filein.seek(0)
output_filename = '%s.%d' % (prefix, count)
output_dirname = os.path.join(prefix + '.cut',output_filename)
chunk_record_count = 0
records = []
for record in SeqIO.parse(filein, 'fasta'):
    if count < num and chunk_record_count >= records_per_chunk:
        SeqIO.write(records, output_dirname, 'fasta')
        records = []
        count += 1
        output_filename = '%s.%d' % (prefix, count)
        output_dirname = os.path.join(prefix + '.cut',output_filename)
        chunk_record_count = 0
    records.append(record)
    chunk_record_count += 1

if records:
    SeqIO.write(records, output_dirname, 'fasta')
