# models/inference.py

from flask import Flask, request, jsonify
import joblib
import numpy as np
import pandas as pd
import traceback
from web3 import Web3
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Load model and scaler
model = joblib.load("models/credit_model.pkl")
scaler = joblib.load("models/credit_scaler.pkl")

# Blockchain setup
WEB3_PROVIDER = os.getenv("AVAX_RPC_URL")
PRIVATE_KEY = os.getenv("ORACLE_PRIVATE_KEY")
REPUTATION_MANAGER_ADDRESS = os.getenv("REPUTATION_MANAGER_ADDRESS")

w3 = Web3(Web3.HTTPProvider(WEB3_PROVIDER))
oracle_account = w3.eth.account.from_key(PRIVATE_KEY)

# ABI stub for ReputationManager
REPUTATION_MANAGER_ABI = [
    {
        "inputs": [
            {"internalType": "address", "name": "user", "type": "address"},
            {"internalType": "int256", "name": "delta", "type": "int256"}
        ],
        "name": "adjustScore",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

rep_contract = w3.eth.contract(address=REPUTATION_MANAGER_ADDRESS, abi=REPUTATION_MANAGER_ABI)

@app.route("/predict", methods=["POST"])
def predict():
    try:
        data = request.get_json()
        features = data.get("features")
        user_address = data.get("user")

        if not features or not user_address:
            return jsonify({"error": "Missing 'features' or 'user' in request body"}), 400

        df = pd.DataFrame([features])
        X_scaled = scaler.transform(df)
        prob = model.predict_proba(X_scaled)[0][1]

        score_delta = int((prob - 0.5) * 200)

        nonce = w3.eth.get_transaction_count(oracle_account.address)
        chain_id = w3.eth.chain_id

        txn = rep_contract.functions.adjustScore(user_address, score_delta).build_transaction({
            'from': oracle_account.address,
            'nonce': nonce,
            'gas': 250000,
            'gasPrice': w3.eth.gas_price,
            'chainId': chain_id
        })

        signed_txn = w3.eth.account.sign_transaction(txn, private_key=PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

        return jsonify({
            "default_probability": round(float(prob), 4),
            "score_delta": score_delta,
            "tx_hash": tx_hash.hex(),
            "status": receipt.status
        })

    except Exception as e:
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
