PATH=/home/changqing/public_data/software/public_kssd
PREFIX=$1
SKETCH=${PREFIX}_sketch
OUT=${PREFIX}_profile.txt

$PATH/kssd composite -r $PATH/data/specuq_grp_gtdb317kgenome_kssd -q $SKETCH | /usr/bin/perl $PATH/src/kssdcomposite2taxonomy_profilefmt.pl - $PATH/data/best.gtdbr207_psid2ncbi_specid.tsv $PATH/data/ncbitaxid_rank_parentnode_name.gtdbr207_pseudoidrelated.tsv > $OUT
