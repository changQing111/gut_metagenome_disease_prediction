suppressPackageStartupMessages(library("tidyverse"))
suppressPackageStartupMessages(library("optparse"))
suppressPackageStartupMessages(library("Rmisc")) 
#options (warn = -1) # ignore warnings 

# load function
source("/mnt/d/R_Project/gut_metagenome_disease_predict/func.R")

# default args
metrics <- c("accuracy", "precision", "recall", "F1", "AUC area")
data_set <- "cirrhosis_PRJEB6337,CRC_PRJEB6070,IBD_PRJEB2054"
target_dir1 = "metaphlan_train_res" # args1
target_dir2 = "kssd_train_res"  # args2
tools1 = "metaphlan3"
tools2 = "kssd"

parser <- OptionParser(description = "kssd and metaphlan3 comparison")
parser <- add_option(parser, c("--input_dir1"), default=target_dir1, help="Input first dir, default: metaphlan_train_res")
parser <- add_option(parser, c("--input_dir2"), default=target_dir2, help="Input second dir, default: kssd_train_res")
parser <- add_option(parser, c("--tools1"), default=tools1, help="Input first tool, default: metaphlan3")
parser <- add_option(parser, c("--tools2"), default=tools2, help="Input second tool, default: kssd")
parser <- add_option(parser, c("-m", "--metric"), type = "character", 
                     help="all ( accuracy, precision, recall, F1, AUC ) or ROC")
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
#plt <- parse$plot
o <- parse$out

# output args
#out_args(parser=parse)

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
  write.csv(all_metric_df, paste0(o, "/", m, "_metrics.csv"), quote = F, row.names = F)
  mean_auc <- get_mean_auc(all_metric_df)
  write.csv(mean_auc, paste0(o, "/", "mean_AUC.csv"), quote = F, row.names = F)
  
  for(i in unique(all_metric_df$metrics)) {
      pdf(paste0(o, "/", i, "_metrics_box.pdf"), width = 5, height = 5)
      p <- all_metric_df[all_metric_df$metrics==i,] %>% plot_metric_box(i) 
      print(p)
      dev.off()
  
      pdf(paste0(o, "/", i, "_metrics_bar.pdf"), width = 5, height = 5)
      p <- all_metric_df[all_metric_df$metrics==i,] %>% plot_metric_bar(i)
      print(p)
      dev.off()
  }

} else { # ROC curve
  mean_AUC <- read_csv(paste0(o, "/", "mean_AUC.csv"), col_names = T)
  
  all_roc_curve_df <- lapply(s, function(x) {
                                  get_roc_curve_data(disease =  x,
                                                     mean_auc = mean_AUC,
                                                     target_dir1 = i1, 
                                                     target_dir2 = i2,
                                                     tools_1 = t1,
                                                     tools_2 = t2)})

  for(i in 1:length(all_roc_curve_df)) {
    write.csv(all_roc_curve_df[[i]], paste0(o, "/", s[i], "_roc_curve_value.csv"), quote=F, row.names = F)
    pdf(paste0(o, "/", s[i], "_ROC_curve.pdf"), width = 5, height = 5)
    p <- plot_ROC_curve(all_roc_curve_df[[i]], s[i]) 
    print(p)
    dev.off()
  }
}
