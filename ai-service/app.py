from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return "Secure AI Platform Running"

@app.route("/predict", methods=["POST"])
def predict():
    data = request.json
    text = data.get("text","")

    # simple AI logic simulation
    if "attack" in text.lower():
        result = "Threat Detected"
    else:
        result = "Safe"

    return jsonify({"result": result})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)