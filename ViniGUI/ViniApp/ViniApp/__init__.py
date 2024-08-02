from flask import Flask, render_template, request

app = Flask(__name__, template_folder="templates", static_folder="static")

@app.route("/", methods=["GET", "POST"])
def home():
    if request.method == "POST":
        drug = request.form["drug-choice"]
        cancer = request.form["cancer-choice"]
        
        return render_template("result.html", drug=drug)
    
    else:
        return render_template("index.html")

if __name__ == "__main__":
   app.run()