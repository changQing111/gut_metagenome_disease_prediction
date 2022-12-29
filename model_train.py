import warnings
import argparse
import sys
import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.model_selection import cross_val_score, cross_val_predict
from sklearn.metrics import confusion_matrix, accuracy_score, precision_score, recall_score, f1_score
from sklearn.metrics import roc_auc_score, roc_curve

def read_params():
    parser = argparse.ArgumentParser(description="use machine learning to predict disease")
    # add arguments
    parser.add_argument("study", help="input experiment file")
    parser.add_argument("profile", help="input profile file")
    parser.add_argument("-a", "--add", action="store", nargs='*', help="a list, choice one or more from [Gender, Age, BMI]")
    parser.add_argument("-m", "--model", default="RF", choices=["RF", "SVM"], help="choose a model")
    parser.add_argument("-f", "--fold", type=int, default=5, help="cv")
    #parser.add_argument("-l", "--label", default="Y", action="store", help="positive label name")
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
        #shuffle_index = np.random.permutation(len(disease_info))
        #disease_info = disease_info.iloc[shuffle_index]
        return disease_info
    
def select_set(disease_info, feature_li=0):
    col_index = []
    if feature_li != 0:
        for i in feature_li:
            col_index.append(list(disease_info.columns).index(i))
    for i in range(10, len(disease_info.columns)):
        col_index.append(i)
    X = disease_info.iloc[:, col_index]
    Y = disease_info["State"]
    return (X, Y)

def metrics_test(y, y_train_pred):
    accuracy = accuracy_score(y, y_train_pred)
    precision = precision_score(y, y_train_pred)
    recall = recall_score(y, y_train_pred)
    f1 = f1_score(y, y_train_pred)
    return {"accuracy":accuracy, "precision":precision, "recall":recall, "F1":f1}

# Grid search para
def grid_search(model, param_grid, x_train, y_train, cv=5):
    search_res = GridSearchCV(model, param_grid, cv=cv, scoring='neg_mean_squared_error', return_train_score=True)
    search_res.fit(x_train, y_train)
    return search_res

# train model and predict
def train_model(model, x_train, y_train, x_test):
    model.fit(x_train, y_train)
    y_pred = model.predict(x_test)
    y_pred_score = model.predict_proba(x_test)
    return [y_pred, y_pred_score]


if __name__ == "__main__":
    # ignore warnings
    warnings.filterwarnings('ignore')
    args = read_params()
    run_design = pd.read_csv(args.study)
    run_profile = pd.read_table(args.profile)
    model_name = args.model
    #label = args.label
    cv = args.fold
    disease_info = merge_data(run_design, run_profile)
    disease_info["State"][disease_info["State"]=="N"] = 0
    disease_info["State"][disease_info["State"]=="Y"] = 1

    if(args.add):
        feature_li = args.add
        disease_info.dropna(axis=0,subset = feature_li)
    else:
        feature_li = 0
    # blance positive instance and negative instance
    X, Y = select_set(disease_info, feature_li)
    Y = Y.astype("int")

    # divide train and test set
    X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.3, stratify=Y)

    # select model and grid search
    if model_name == "RF":
        rf_param = [{"n_estimators": [500, 750, 1000]}]
        model = RandomForestClassifier(n_estimators=500, n_jobs=-1)
    '''  
        search_res = grid_search(model, rf_param, X_train, Y_train)
      #print(search_res.best_params_)
       # for i, j in search_res.best_params_:
       #     print("%s: %d" % (i, j))
        best_model = search_res.best_estimator_
    
    elif model_name == "SVM":
        model = SVC(C=1, probability=True)
        pass
    '''
    # train model and predict
    y_pred, y_pred_score = train_model(model, X_train, Y_train, X_test)
    metrics = metrics_test(Y_test, y_pred)
    auc_area = roc_auc_score(Y_test, y_pred_score[:,1])

    outdir = args.outdir
    if not os.path.exists(outdir):
        os.makedirs(outdir)
    f_metrics = open(outdir + '/' + "metrics.txt", 'w')
    for i in metrics:
        print("%s:%f" % (i, metrics[i]))
        f_metrics.write(i + ":"+str(metrics[i]) + '\n')
    print("AUC:%f" % auc_area)
    
    f_metrics.write("AUC area:" + str(auc_area) + '\n')
    f_metrics.close()

    fpr_forest, tpr_forest, thresholds_forest = roc_curve(Y_test, y_pred_score[:,1])
    f_roc = open(outdir + '/' + "ROC.txt", 'w')
    f_roc.write("FPR\tTPR" + '\n')
    for i, j in zip(fpr_forest, tpr_forest):
        f_roc.write(str(i) + '\t' + str(j) + '\n')
    f_roc.close()
