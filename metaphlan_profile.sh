INPUT=$1
FASTQ=${1}.fastq
REF_DB=/home/changqing/Document/metaphlan_db/
TEMP=${1}.bowtie2.bz2
OUT=${1}_profile.txt
LOG=${1}.log
ERR=${1}.err

metaphlan $FASTQ \
 --input_type fastq \
 --bowtie2db $REF_DB \
 --bowtie2out $TEMP \
 --nproc 24 \
 -o $OUT 1>$LOG 2>$ERR 
