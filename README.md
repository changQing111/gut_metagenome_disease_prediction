## Gut metagenomic aata predicting disease: Based on classical machine learning algorithms

#### 1. Download SRA data from NCBI and ENA ,then sketch data by kssd
```shell
$ bash sketch.sh SRR22280929 &
```
  #### multi-task running
```shell
$ bash sleep_run.sh run_list.txt &
```

#### 2. Profiling
```shell
$ bash composite_gtdb.sh SRR22280929_sketch
```

#### 3. Merge all data of a data set
```shell
$ ls *_profile|cut -f1 -d"_" > file_list.txt
$ python merge_species.py -l file_list.txt -n IBD_PRJEB2054
```

#### 4. Train 20 times
```shell
$ for i in {1..20};do python model_train.py all_disease_info.csv IBD_PRJEB2054.txt -f 5 -m RF -s $i -o IBD_PRJEB2054/IBD_PRJEB2054_${i};done
```

#### 5. contrast kssd and metaphlan3
```shell
$ Rscript metrics.R --input_dir1 metaphlan_train_res --input_dir2 kssd_train_res -m all -s cirrhosis_PRJEB6337,IBD_PRJEB2054 -o result
```
```shell
$ Rscript metrics.R --input_dir1 metaphlan_train_res --input_dir2 kssd_train_res -m ROC -s cirrhosis_PRJEB6337,IBD_PRJEB2054 -o result
```
