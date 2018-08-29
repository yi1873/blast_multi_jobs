#!/bin/bash
# Author: xiang_zhi_@126.com

set -e
num=10
pronum=5
cpu=2

while getopts "i:o:npd:m:t" opt;
do
        case $opt in
                  i) input=$OPTARG;;
                  o) outdir=$OPTARG;;
                  n) num=$OPTARG;;
                  p) pronum=$OPTARG;;
                  d) db=$OPTARG;;
                  m) model=$OPTARG;;
                  t) cpu=$OPTARG;;

esac
done

if [[ $# -lt 1 ]];then
     echo "USAGE: bash $0 -m blastp -i input.fa -d nr -o outdir "
     echo "       bash $0 -m blastx -i input.fa -d nr -n 10 -p 5 -t 2 -o outdir"
     echo "[Options]: -i: inputfile;"
     echo "           -m: blast program, eg blastn, blastx, blastp, tblastn, tblastx;"
     echo "           -d: db path;"
     echo "           -o: path of outdir;"
     echo "           -n: the number of splited files, default 10;"
     echo "           -p: the number of jobs run, default 5;"
     echo "           -t: num of threads for every run job, default 2;"
     exit 1
fi

# step1: cut the fasta file
python $outdir/split_fasta.py -i $input -n $num

# step2: makeblastdb
if [[ $model =~ "blastp" ]] || [[ $model =~ "blastx" ]]; then
    if [[ ! -e "$db.phr" ]]; then
        /usr/bin/makeblastdb -in $db -dbtype prot -parse_seqids
    fi
elif [[ $model =~ "blastn" ]] || [[ $model =~ "tblastn" ]] || [[ $model =~ "tblastx" ]]; then
    if [[ ! -e "$db.nhr" ]]; then
        /usr/bin/makeblastdb -in $db -dbtype nucl -parse_seqids
    fi
fi

# step3: multi jobs run
tmpfile="$$.filo"
mkfifo $tmpfile
exec 6<>$tmpfile
rm $tmpfile

for(( i=0; i< $pronum; i++))
do
    echo "init."
done >&6
for(( i=1; i<= $num; i++))
do
    read line
    {
    /usr/bin/$model -query $input.cut/$input.$i -db $db -out $outdir/$input.cut/$input.$i.$model -evalue 1e-5 -num_threads 2 -num_descriptions 10 -outfmt 0
    echo "$input.$i finished" >> $outdir/$model.log
    echo "line${i} finished."
    } >&6 &
done  <&6

wait

cat $outdir/$input.cut/$input*.$model > $outdir/$input.$model
