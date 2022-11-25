PATH=/home/changqing/softwared/public_kssd
PERL=/home/changqing/miniconda3/bin/perl
FILE=$1
PREFIX=`echo $FILE | /usr/bin/awk -F "/" '{print $NF}' | /usr/bin/cut -f1 -d"_"`
OUT=${PREFIX}_profile
LOG=${PREFIX}.log
ERR=${PREFIX}.err

$PATH/kssd composite -r $PATH/data/specuq_grp_gtdb317kgenome_kssd -q $FILE | $PERL $PATH/src/kssdcomposite2gtdb_tax_kronafmt.pl - $PATH/data/gtdbr207_psid2krona_taxonomy.tsv $OUT 1>$LOG 2>$ERR
