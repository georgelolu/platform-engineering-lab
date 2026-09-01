from flask import Flask

app = Flask(__name__)


@app.route("/")
def home():
    return "Hello from the Platform Engineering Lab!\n"


@app.route("/health")
def health():
    return "healthy\n"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
