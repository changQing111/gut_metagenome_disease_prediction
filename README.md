## Gut microbes predict disease based on kssd and machine learning algorithms

#### 1. Download sra data from NCBI and ENA ,then sketch data by kssd
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

#### 4.Train model

