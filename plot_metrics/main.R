library(tidyverse)

source("func.R")
metrics <- c("accuracy", "precision", "recall", "F1", "AUC area")
data_set <- c("cirrhosis_PRJEB6337", "CRC_PRJEB6070", "IBD_PRJEB2054")
target_dir1 = "metaphlan_filter_train_res/"
target_dir2 = "kssd_filter_train_res/"

all_accuracy_df <- vector("list", length = length(data_set))
for(i in 1:length(data_set)) {
  all_accuracy_df[[i]]  <- get_metric_df(data_set[i], "accuracy", 
                                         target_dir1 = "metaphlan_filter_train_res/", 
                                         target_dir2 = "kssd_filter_train_res/")
  all_accuracy_df[[i]]$disease <- data_set[i]
}
all_accuracy <- data.frame()
for(i in 1:length(data_set)) {
  all_accuracy <- rbind(all_accuracy, all_accuracy_df[[i]])
}
all_accuracy %>% ggplot(aes(x=disease, y=accuracy, fill=tools)) +
  geom_boxplot(width=0.5,position=position_dodge(0.8), alpha=0.6, outlier.shape = NA) + 
  geom_jitter(aes(colour=tools), position = position_jitterdodge(dodge.width = 0.5)) +
  labs(x="", y="Accuracy") +
  my_theme +  theme(axis.text.x = element_text(angle=45, hjust=1, vjust=1)) +
  scale_y_continuous(expand = c(0, 0),limits=c(0.8, 1.01),
                     breaks = c(seq(0.8, 1, by=0.05)))

# AUC
all_auc_df <- vector("list", length = length(data_set))
for(i in 1:length(data_set)) {
  all_auc_df[[i]]  <- get_metric_df(data_set[i], "AUC area",
                                    target_dir1 = target_dir1,
                                    target_dir2 = target_dir2)
  all_auc_df[[i]]$disease <- data_set[i]
}
all_auc_df[[1]] %>% View()
all_auc <- data.frame()
for(i in 1:length(data_set)) {
  all_auc <- rbind(all_auc, all_auc_df[[i]])
}
all_auc %>% head()
t.test(all_auc$`AUC area`[all_auc$disease=="cirrhosis_PRJEB6337"&all_auc$tools=="kssd"], 
       all_auc$`AUC area`[all_auc$disease=="cirrhosis_PRJEB6337"&all_auc$tools=="metaphlan3"])
t.test(all_auc$`AUC area`[all_auc$disease=="CRC_PRJEB6070"&all_auc$tools=="kssd"], 
       all_auc$`AUC area`[all_auc$disease=="CRC_PRJEB6070"&all_auc$tools=="metaphlan3"])

t.test(all_auc$`AUC area`[all_auc$disease=="IBD_PRJEB2054"&all_auc$tools=="kssd"], 
       all_auc$`AUC area`[all_auc$disease=="IBD_PRJEB2054"&all_auc$tools=="metaphlan3"])


all_auc %>% ggplot(aes(x=disease, y=`AUC area`, fill=tools)) +
  geom_boxplot(width=0.5,position=position_dodge(0.8), alpha=0.6, outlier.shape = NA) + 
  geom_jitter(aes(colour=tools), position = position_jitterdodge(dodge.width = 0.5)) +
  labs(x="", y="AUC") +
  my_theme +  theme(axis.text.x = element_text(angle=45, hjust=1, vjust=1)) +
  scale_y_continuous(expand = c(0, 0),limits=c(0.8, 1.01),
                                breaks = c(seq(0.8, 1, by=0.05)))

all_auc_df[[1]]
names(all_auc_df) <- data_set
all_auc_df[[1]] %>% head()

auc_li <- data.frame()
disease <- vector()
for(i in data_set) {
  for(j in c("kssd", "metaphlan3")) {
    auc_li <- rbind(auc_li, ci_value(all_auc_df[[i]], j))
    disease <- c(disease, i)
  }
}


auc_li$disease <- disease
write.table(auc_li, "AUC_CI.txt", row.names = F, quote = F)
auc_li %>% ggplot(aes(x=disease, y=AUC, fill=tools)) +
  geom_bar(width = 0.5, position=position_dodge(), stat = "identity") +
  geom_errorbar(aes(ymin=AUC-SE, ymax=AUC+SE), size=0.75,width=0.1, position=position_dodge(0.5)) +
  my_theme + labs(x="") + theme(axis.text.x = element_text(angle=45, hjust=1, vjust=1)) +
  scale_y_continuous(expand = c(0, 0),limits=c(0,1.05),
                     breaks = c(seq(0, 1, by=0.1))) +
  geom_hline(aes(yintercept=0.9), colour="#990000", linetype="dashed") +
  geom_hline(aes(yintercept=0.95), colour="#990000", linetype="dashed")

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
  pdf(paste0(data_set[i], "_filter_ROC_curve.pdf"), width = 5, height = 5)
  p <- plot_ROC_curve(all_roc_curve_df[[i]], data_set[i]) 
  print(p)
  dev.off()
}

#
species_num <- read_csv("species_num.csv", col_names = T)
head(species_num)
species_num %>% 
  ggplot(aes(x=tools, y=species_num)) +
  geom_bar(aes(fill=type),width = 0.5, stat = "identity",position = "stack") + 
  facet_grid(. ~ disease) +
  geom_text(aes(label=species_num, y=species_num-0.5), colour="white", position = "stack", vjust=1) +
  labs(x= "", y="Number") + my_theme + scale_y_continuous(expand = c(0, 0), limits=c(0,3400))                                                       
