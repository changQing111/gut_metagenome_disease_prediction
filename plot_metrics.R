# ROC AUC
roc_li <- dir("gut_metagenome_disease/ROC/")
roc_auc_li <- lapply(paste0("gut_metagenome_disease/", "ROC/", roc_li, "/ROC.txt"),
                                            function(x){read_tsv(x, col_names = T)})
names(roc_auc_li) <- roc_li

for(i in 1:length(roc_auc_li)){
  roc_auc_li[[i]]$run <- roc_li[i]
}
roc_auc_tbl <- roc_auc_li[[1]]
for(i in 2:length(roc_auc_li)) {
  roc_auc_tbl <- rbind(roc_auc_tbl, roc_auc_li[[i]])
}

x = runif(100000)
y = x
subline = data.frame(x = x, y=y)

roc_auc_tbl %>% 
  ggplot(aes(x=FPR, y=TPR)) + 
  geom_line(data = subline, aes(x = x, y=y), colour="#990000", linetype="dashed") +
  geom_smooth( aes(colour=run), se = FALSE) + 
  labs(x= "False positive rate", y="True positive rate", title = "Random Forest") +
  my_theme 
  
# metrics
metrics_li <- lapply(paste0("gut_metagenome_disease/", "ROC/", roc_li, "/metrics.txt"), 
                                                  function(x) {read_delim(x, col_names = c("metrics", "ratio"), delim=":")})
head(metrics_li[[1]])

for(i in 1:length(metrics_li)) {
  metrics_li[[i]]$metrics[which(metrics_li[[i]]$metrics=="AUC area")] <- "AUC"
  metrics_li[[i]]$run <- roc_li[i]
}
metrics_tbl <- metrics_li[[1]]
for(i in 2:length(metrics_li)) {
  metrics_tbl <- rbind(metrics_tbl, metrics_li[[i]])
}
metrics_tbl$metrics <- factor(metrics_tbl$metrics, levels = c("accuracy", "precision", "recall", "F1", "AUC"))
p <- metrics_tbl %>% 
      ggplot(aes(x=run, y=ratio)) +
      geom_bar(aes(fill=metrics), width = 0.75, stat = "identity", position = "dodge") +
      labs(x="", y="Ratio", title = "Random Forest")
p + my_theme + 
    theme(axis.text.x = element_text(angle=45, hjust=1, vjust=1)) +
    scale_y_continuous(limits=c(0,1),
                   breaks = c(seq(0, 1, by=0.2))) +
  geom_hline(aes(yintercept=0.8), colour="#990000", linetype="dashed") +
  geom_hline(aes(yintercept=0.9), colour="#990000", linetype="dashed")
