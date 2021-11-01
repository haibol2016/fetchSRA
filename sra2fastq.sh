#!/bin/bash

#BSUB -n 4  # minmal numbers of processors required for a parallel job
#BSUB -R rusage[mem=4000] # ask for memory 5G
#BSUB -W 24:00 #limit the job to be finished in 12 hours
#BSUB -J "fastQC[1-8]"
#BSUB -q long   # which queue we want to run in
#BSUB -o logs/out.%J.%I.txt # log
#BSUB -e logs/err.%J.%I.txt # error
#BSUB -R "span[hosts=1]" # All hosts on the same chassis"
##BSUB -w "done(39527)"

i=$(($LSB_JOBINDEX- 1))
mkdir -p logs

set -e
set -u
set -o pipefail

out_dir=published.data
mkdir -p ${out_dir}

module load sratoolkit/2.10.8


link=(`cut -f 2 docs/Cheung.et.epithilial.data.SraRunInfo.txt`)
name=(`cut -f 2 docs/Cheung.et.epithilial.data.SraRunInfo.txt | perl -p -e 's{.+/(.+)}{$1}'`)
wget  --directory-prefix published.data -c  ${link[$i]}

chunck=(published.data/${name[$i]})

for j in ${chunck[@]}
do
   fasterq-dump --outdir  ${out_dir}  --threads 4  --split-files  ${j}
   name=`basename "${j}"`

   OUT=$?
   if [ $OUT -eq 0 ];then
       echo "rm -rf ${j}"

       rm -rf ${j}

       ## process read 1 to extract Cell barcode and UMIs
       ## compress reads to fastq.gz  
       awk '{if (NR % 4 ==1) {print $1} else if (NR % 4 ==2 || NR % 4 == 0) {print substr($0, 1, 21)} else {print "+"}}' \
             ${out_dir}/${name}_1.fastq | gzip -f -9   > ${out_dir}/${name}_1.fastq.gz
       out1=$?
       
       if [ $out1 -eq 0 ];then
          rm -rf  ${out_dir}/${name}_1.fastq
       fi    
       gzip -f -9  ${out_dir}/${name}_2.fastq
   fi
done
