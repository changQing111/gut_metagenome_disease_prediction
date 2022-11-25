KSSD=/home/changqing/softwared/public_kssd-master/
SHUF=$KSSD/shuf_file/L3K10.shuf
RUN=$1
OUT=${1}_sketch

prefetch $RUN && \
$KSSD/kssd dist -p 16 -A -L $SHUF -n 2 -o $OUT --pipecmd "fastq-dump --skip-technical --split-spot -Z" $RUN && \
rm -rf $RUN
