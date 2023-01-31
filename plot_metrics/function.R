my_theme <- theme(panel.background = element_blank(), 
                  legend.key = element_blank(),
                  legend.title=element_blank(),
                  plot.title = element_text(hjust = 0.5),
                  axis.text.x = element_text(size = 12, colour = "black"),
                  axis.title.x = element_text(size=14),
                  axis.text.y = element_text(size=12, colour = "black"),
                  axis.title.y = element_text(size=14),
                  strip.text.x = element_text(size = 14), 
                  panel.border = element_rect(colour = "black", fill=NA, size = 1))



# ROC curve values
read_roc_data <- function(target_dir, data_set, ...) {
  disease_li <- paste(target_dir, data_set, sep = "/")
  roc_li <- lapply(paste(disease_li, dir(disease_li), "ROC.txt", sep = "/"), 
                       function(x) {read_tsv(x, col_names = T)})  
  return(roc_li)
}

# read metrics: accuracy, precision, recall, F1, AUROC value
read_metrics_data <- function(target_dir, tool, disease, ...) {
  disease_li <- paste(target_dir, disease, sep = "/")
  metrics_li <- lapply(paste(disease_li, dir(disease_li), "metrics.txt", sep = "/"), 
                       function(x) {read_delim(x, col_names = c("metrics", "ratio"), delim=":")})
  for(i in 1:length(metrics_li)) {
    metrics_li[[i]]$disease <- disease
    metrics_li[[i]]$tools <- tool
  }
  metrics_df <- li_to_df(metrics_li)
  return(metrics_df)
}


# get metaphlan3 and kssd metrics
get_metric_df <- function(disease, metric, target_dir1="metaphlan_train_res", target_dir2="kssd_train_res",
                          tools_1="metaphlan3", tools_2="kssd")  {
  metrics_df1 <- read_metrics_data(target_dir1, tool = tools_1, disease)
  metrics_df2 <- read_metrics_data(target_dir2, tool = tools_2, disease)

  df_metric <- rbind(metrics_df1, metrics_df2)
  return(df_metric)
}


# list transform datafarm
li_to_df <- function(li) {
  df <- data.frame()
  for(i in 1:length(li)) {
    df <- rbind(df, li[[i]])
  }
  return(df)
}

plot_auc_violin <- function(df, disease) {
  pdf(paste0(disease, "_AUC.pdf"), width = 6, height = 5)
  p <- df %>% ggplot(aes(x=tools, y=`AUC area`)) +
    geom_violin(aes(fill=tools), width=0.7, trim = FALSE) + 
    geom_boxplot(width=0.1) + 
    geom_jitter(colour="grey", width = 0.1) +
    labs(x="", y="AUC", title = disease) +
    my_theme 
  print(p)
  dev.off()  
}

# 20 groups ROC curve
tpr_mean <- function(roc) {
  roc_fpr <- roc$FPR
  roc_tpr <- roc$TPR
  tpr <- vector(length = 10)
  lower = 0
  for(i in 1:10) {
    upper = 0.1*i
    tpr[i] <- mean(roc_tpr[roc_fpr>lower & roc_fpr <= upper])
    lower = upper
  }
  if(length(which(is.na(tpr))) != 0) {
    tpr[is.na(tpr)] <- tpr[max(which(tpr %>% is.na())) + 1] 
  }
  return(tpr)
}
#tpr_mean(roc_li_1[[2]])

# add 95% CI
add_ci <- function(roc_li, tool) {
  fpr <- seq(0.05, 0.95, 0.1) 
  len <- length(roc_li)
  tpr_li <- vector('list', length = len)
  for(i in 1:len) {
    tpr_li[[i]] <- tpr_mean(roc_li[[i]])  
  }
  n_row = length(tpr_li[[1]])
  tpr_m <- matrix(nrow = n_row, ncol = len)
  for(i in 1:len) {
    tpr_m[,i] <- tpr_li[[i]]
  }
  
  aver_tpr <- vector(length = n_row)
  ci_l <- vector(length = n_row)
  ci_r <- vector(length = n_row)
  for(i in 1:n_row) {
    average <- tpr_m[i,] %>% mean()
    aver_tpr[i] <- average
    std_err <- tpr_m[i,] %>% sd()
    ci_l[i] <- average - 1.96*std_err/sqrt(len)
    ci_r[i] <- average + 1.96*std_err/sqrt(len) 
  }
  roc_curve_tbl <- data.frame(FPR=c(0, fpr, 1), TPR=c(0,aver_tpr,1), 
                              CI_l=c(0, ci_l, 1), CI_r=c(0, ci_r, 1), tools=tool)
  return(roc_curve_tbl)
}

get_roc_curve_data <- function(disease, target_dir1="metaphlan_train_res", target_dir2="kssd_train_res",
                               tools_1="metaphlan3", tools_2="kssd") {
  roc_li_1 <- read_roc_data(target_dir1, disease)
  roc_li_2 <- read_roc_data(target_dir2, disease)
  
  roc_1 <- add_ci(roc_li_1, tools_1)
  roc_2 <- add_ci(roc_li_2, tools_2)
  return(rbind(roc_1, roc_2))
}

plot_ROC_curve <- function(df, title) {
  x = runif(100000)
  y = x
  subline = data.frame(x = x, y=y)
  p <- ggplot(df, aes(x=FPR, y=TPR)) +
    geom_line(data = subline, aes(x = x, y=y), colour="#990000", linetype="dashed", size=1) +
    geom_line(aes(colour=tools), size = 1) +
    geom_ribbon(aes(ymin = CI_l, ymax = CI_r, fill=tools), alpha=0.3) +
    labs(x= "False positive rate", y="True positive rate", title = title) +
    my_theme + theme(legend.position = c(0.8,0.2))
  return(p)
}

ci_value <- function(auc_df, tool) {
  arr = auc_df$`AUC area`[auc_df$tools==tool]
  len = length(arr)
  mean_arr <- mean(arr)
  sd_arr <- sd(arr)
  #ci_l <- mean_arr - 1.96*sd_arr/sqrt(len)
  #ci_r <- mean_arr + 1.96*sd_arr/sqrt(len)
  #df <- data.frame(AUC=mean_arr, CI_l=ci_l, CI_r=ci_r, tools=tool)
  se = sd_arr/sqrt(len)
  df <- data.frame(AUC=mean_arr, SE=se, tools=tool)
  return(df)
}



# plot metrics boxplot
plot_metric_box <- function(df, metric) {
  p <- ggplot(df, aes(x=disease, y=ratio, fill=tools)) +
    geom_boxplot(width=0.5,position=position_dodge(0.8), alpha=0.6, outlier.shape = NA) + 
    geom_jitter(aes(colour=tools), position = position_jitterdodge(dodge.width = 0.5)) +
    labs(x="", y=metric) +
    my_theme +  theme(axis.text.x = element_text(angle=45, hjust=1, vjust=1)) +
    scale_y_continuous(expand = c(0, 0),limits=c(0.8, 1.01),
                       breaks = c(seq(0.8, 1, by=0.05)))
  return(p)
}
