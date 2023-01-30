suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("optparse"))
options (warn = -1) # ignore warnings 

# load function
source("func.R")

# default args
metrics <- c("accuracy", "precision", "recall", "F1", "AUC area")
data_set <- "cirrhosis_PRJEB6337,CRC_PRJEB6070,IBD_PRJEB2054"
target_dir1 = "metaphlan_filter_train_res/" # args1
target_dir2 = "kssd_filter_train_res/"  # args2

# parse args
parser <- OptionParser(description = "kssd and metaphlan3 comparison")
parser <- add_option(parser, c("-i1", "--input_dir1"), default=target_dir1, help="Input first dir")
parser <- add_option(parser, c("-i2", "--input_dir2"), default=target_dir2, help="Input second dir")
parser <- add_option(parser, c("-m", "--metric"), type = "character", 
                     help="accuracy, precision, recall, F1, AUC area, ROC")
parser <- add_option(parser, c("-s", "--set"), default = data_set, type = "character", help = "data set, 
                            If multiple entries are entered, separate them with commas")
parser <- add_option(parser, c("-o", "--out"), type = "character", help="out file name")

parse <- parse_args(parser)

# input help info
if(is.null(parse$metric) || is.null(parse$out) || is.null(parse$set)) {
  parse_args(parser, args = c("-h", "--help"))
}

# receiving args
i1 <- parse$input_dir1
i2 <- parse$input_dir2
m <- parse$metric
s <- str_split(parse$set, ",") %>% unlist()
o <- parse$out

if(!dir.exists(o)) {
  dir.create(o)
}
setwd(o)

# metrics boxplot
if(m != "ROC") {
  all_metri_df <- merge_diff_tools_disease(s, m, i1, i2)
  write.table(all_metri_df, paste0(m, ".txt"), quote = F, row.names = F)
  pdf(paste0(m, "_metrics.pdf"), width = 5, height = 5)
  plot_metric_box(all_metri_df)  
} else { # ROC curve
  all_roc_curve_df <- lapply(s, function(x) {get_roc_curve_data(x)})
  for(i in 1:length(all_roc_curve_df)) {
    write.table(all_roc_curve_df[[i]], paste0(s[i], "_roc_curve_value.txt", quote=F, row.names = F))
    pdf(paste0(s[i], "_ROC_curve.pdf"), width = 5, height = 5)
    p <- plot_ROC_curve(all_roc_curve_df[[i]], s[i]) 
    print(p)
    dev.off()
  }
}
