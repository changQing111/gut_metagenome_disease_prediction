import argparse
import sys
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_predict
from sklearn.metrics import confusion_matrix, accuracy_score, precision_score, recall_score, f1_score
from sklearn.metrics import roc_auc_score, roc_curve

def read_params():
    parser = argparse.ArgumentParser(description="use machine learning to predict disease")
    # add arguments
    parser.add_argument("profile", help="input profile file")
    parser.add_argument("study", help="input experiment file")
    parser.add_argument("-a", "--add", action="store", nargs='*', help="a list, choice one or more from [Gender, Age, BMI]")
    parser.add_argument("-m", "--model", default="RF", choices=["RF", "SVM"], help="choose a model")
    parser.add_argument("-f", "--fold", type=int, default=4, help="cv")
    parser.add_argument("-l", "--label", default="Y", action="store", help="positive label name")
    parser.add_argument("-o", "--outdir", default=".", action="store", help="output file")
    args = parser.parse_args()
    return args

def merge_data(design, profile, label='Y'):
    disease_info = pd.merge(design, profile, on="run_accession")
    y_label = sum(disease_info["State"]=="Y")
    n_label = sum(disease_info["State"]=="N")
    if y_label / n_label >= 0.8 and y_label / n_label <= 1.2:
        return disease_info
    else:
        if min(y_label, n_label) == y_label:
            n_label = round(y_label * 1.2)
        else:
            y_label = round(n_label * 1.2)
        y_tmp = disease_info[disease_info["State"]==label].sample(n=y_label)
        n_tmp = disease_info[disease_info["State"]!=label].sample(n=n_label)
        disease_info = pd.concat([y_tmp,n_tmp],  ignore_index = True)
        return disease_info
    
def select_train_set(disease_info, feature_li=0):
    col_index = []
    if feature_li != 0:
        for i in feature_li:
            col_index.append(list(disease_info.columns).index(i))
    for i in range(10, len(disease_info.columns)):
        col_index.append(i)
    X = disease_info.iloc[:, col_index]
    Y = disease_info["State"]
    return (X, Y)

def metrics_test(y, y_train_pred, label):
    accuracy = accuracy_score(y, y_train_pred)
    precision = precision_score(y, y_train_pred, pos_label=label)
    recall = recall_score(y, y_train_pred, pos_label=label)
    f1 = f1_score(y, y_train_pred, pos_label=label)
    return {"accuracy":accuracy, "precision":precision, "recall":recall, "F1":f1}

def train_model(model, x_train, y, label, cv):
    y_train_pred = cross_val_predict(model, x_train, y, cv=cv)
    metrics_res = metrics_test(y, y_train_pred, label)
    return metrics_res

def roc_auc(model, x_train, y, cv=4):
    y_scores = cross_val_predict(model, x_train, y, cv=cv, method="predict_proba")
    auc_area = roc_auc_score(y, y_scores[:,1])
    return [auc_area, y_scores]
   

if __name__ == "__main__":
    args = read_params()
    run_design = pd.read_csv(args.profile)
    run_profile = pd.read_table(args.study)
    model_name = args.model

    label = args.label
    cv = args.fold

    disease_info = merge_data(run_design, run_profile)

    if(args.add):
        feature_li = args.add
        disease_info.dropna(axis=0,subset = feature_li)
    else:
        feature_li = 0

    X, Y = select_train_set(disease_info, feature_li)
    
    if model_name == "RF":
        model = RandomForestClassifier(n_estimators=500, n_jobs=-1)
    elif model_name == "SVM":
        pass

    metrics = train_model(model=model, x_train = X, y = Y, label=label, cv=cv)
    auc_area, y_scores = roc_auc(model=model, x_train = X, y = Y, cv=cv)

    outdir = args.outdir
    if not os.path.exists(outdir):
        os.mkdir(outdir)
    f_metrics = open(outdir + '/' + "metrics.txt", 'w')
    for i in metrics:
        print("%s:%f" % (i, metrics[i]))
        f_metrics.write(i + ":"+str(metrics[i]) + '\n')
    print("AUC:%f" % auc_area)
    f_metrics.write("AUC area:" + str(auc_area) + '\n')
    f_metrics.close()

    fpr_forest, tpr_forest, thresholds_forest = roc_curve(Y, y_scores[:,1], pos_label="Y")
    f_roc = open(outdir + '/' + "ROC.txt", 'w')
    f_roc.write("FPR\tTPR" + '\n')
    for i, j in zip(fpr_forest, tpr_forest):
        f_roc.write(str(i) + '\t' + str(j) + '\n')
    f_roc.close()
