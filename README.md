## Gut metagenomic aata predicting disease: Based on kssd and classical machine learning algorithms

#### 1. Download SRA data from NCBI and ENA ,then sketch data by kssd
```shell
$ bash sketch.sh SRR22280929
```

#### 2. Profiling
```shell
$ bash composite_gtdb.sh SRR22280929_sketch
```

#### 3. Merge all data of a data set
```shell
$ ls *_profile|cut -f1 -d"_" > file_list.txt
$ python merge_species.py file_list.txt
```

#### 4.Train 20 times
```shell
$ for i in {1..20};do python model_train.py all_disease_info.csv IBD_PRJEB2054.txt -f 5 -m RF -o IBD_PRJEB2054/IBD_PRJEB2054_${i};done
```

#### 5. contrast kssd and metaphlan3
```shell
$ Rscript main.R --input_dir1 metaphlan_train_res --input_dir2 kssd_train_res -m ROC -s cirrhosis_PRJEB6337,IBD_PRJEB2054 -o result
```
