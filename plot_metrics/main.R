suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("optparse"))

# load function
source("func.R")

# default args
metrics <- c("accuracy", "precision", "recall", "F1", "AUC area")
data_set <- "cirrhosis_PRJEB6337,CRC_PRJEB6070,IBD_PRJEB2054"
target_dir1 = "metaphlan_train_res" # args1
target_dir2 = "kssd_train_res"  # args2
tools1 = "metaphlan3"
tools2 = "kssd"

# parse args
parser <- OptionParser(description = "kssd and metaphlan3 comparison")
parser <- add_option(parser, c("--input_dir1"), default=target_dir1, help="Input first dir")
parser <- add_option(parser, c("--input_dir2"), default=target_dir2, help="Input second dir")
parser <- add_option(parser, c("--tool1"), default=tools1, help="Input first tool")
parser <- add_option(parser, c("--tool2"), default=tools2, help="Input second tool")
parser <- add_option(parser, c("-m", "--metric"), type = "character", 
                     help="all(accuracy, precision, recall, F1, AUC) or ROC")
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
t1 <- parse$tools1
t2 <- parse$tools2
m <- parse$metric
s <- str_split(parse$set, ",") %>% unlist()
o <- parse$out

if(!dir.exists(o)) {
  dir.create(o)
}

# metrics boxplot
if(m != "ROC") {
  all_metric_li <- lapply(s, function(x) { 
                              get_metric_df(disease = x, 
                                            target_dir1 = i1, 
                                            target_dir2 = i2, 
                                            tools_1 = t1, 
                                            tools_2 = t2)})
  all_metric_df <- li_to_df(all_metric_li)
  write.table(all_metric_df, paste0(o, "/", m, "_metrics.txt"), quote = F, row.names = F)
  for(i in unique(all_metric_df$metrics)) {
    pdf(paste0(o, "/", i, "_metrics.pdf"), width = 5, height = 5)
    p <- all_metric_df[all_metric_df$metrics==i,] %>% plot_metric_box(i) 
    print(p)
    dev.off()
  }

} else { # ROC curve
  all_roc_curve_df <- lapply(s, function(x) {
                                  get_roc_curve_data(disease =  x, 
                                                     target_dir1 = i1, 
                                                     target_dir2 = i2,
                                                     tools_1 = t1,
                                                     tools_2 = t2)})
  for(i in 1:length(all_roc_curve_df)) {
    write.table(all_roc_curve_df[[i]], paste0(o, "/", s[i], "_roc_curve_value.txt"), quote=F, row.names = F)
    pdf(paste0(o, "/", s[i], "_ROC_curve.pdf"), width = 5, height = 5)
    p <- plot_ROC_curve(all_roc_curve_df[[i]], s[i]) 
    print(p)
    dev.off()
  }
}
