library(tidyverse)

metrics <- c("accuracy", "precision", "recall", "F1", "AUC area")
data_set <- c("cirrhosis_PRJEB6337", "CRC_PRJEB6070", "IBD_PRJEB2054")

all_auc_df <- vector("list", length = length(data_set))
for(i in 1:length(data_set)) {
  all_auc_df[[i]]  <- get_auc_df(data_set[i])
  #plot_auc_violin(i)  
}
names(all_auc_df) <- data_set

x = runif(100000)
y = x
subline = data.frame(x = x, y=y)

all_roc_curve_df <- vector("list", length = length(data_set))
for(i in 1:length(data_set)) {
  all_roc_curve_df[[i]]  <- get_roc_curve_data(data_set[i])
  #plot_auc_violin(i)  
}
all_roc_curve_df[[1]] %>% head()

for(i in 1:length(all_roc_curve_df)) {
  pdf(paste0(data_set[i], "_ROC_curve.pdf"), width = 5, height = 5)
  p <- plot_ROC_curve(all_roc_curve_df[[i]], data_set[i]) 
  print(p)
  dev.off()
}
