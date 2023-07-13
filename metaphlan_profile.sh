REF_DB=/home/changqing/Document/metaphlan_db/bowtie_db/mpa_v31_CHOCOPhlAn_201901
/home/changqing/Document/metaphlan_db
FPATH=.
INPUT=$FPATH${1}.fastq
TEMP=${1}.bowtie2.bz2
OUT=${1}_profile.txt

metaphlan $INPUT \
 --input_type fastq \
 --bowtie2db $REF_DB \
 --bowtie2out $TEMP \
 --nproc 8 \
 -o $OUT
