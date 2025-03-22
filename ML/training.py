# models/train_model.py

import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import roc_auc_score, classification_report
import joblib

# Load and prepare data
def load_and_prepare_data():
    df = pd.read_csv("data/combined_dataset.csv")
    df.fillna(0, inplace=True)
    X = df.drop(columns=["defaulted"])
    y = df["defaulted"]
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    return X_scaled, y, scaler

# Train model
def train_model(X, y):
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = RandomForestClassifier(n_estimators=100, max_depth=6, random_state=42)
    model.fit(X_train, y_train)
    y_pred = model.predict(X_test)
    y_prob = model.predict_proba(X_test)[:, 1]

    print("ROC-AUC:", roc_auc_score(y_test, y_prob))
    print(classification_report(y_test, y_pred))

    return model

# Save model
if __name__ == "__main__":
    X, y, scaler = load_and_prepare_data()
    model = train_model(X, y)
    joblib.dump(model, "models/credit_model.pkl")
    joblib.dump(scaler, "models/credit_scaler.pkl")