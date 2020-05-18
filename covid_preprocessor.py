# Preprocess the COVID data to reorganize into a format that's
# more efficient for our purposes
import json

IN_FILE = "daily.json"
OUT_FILE = "swift-challenge.playground/Resources/covid.json"

out_data = {}
with open(IN_FILE) as input_file:
    data = json.load(input_file)

    for pt in data:
        key = pt["state"]
        existing = out_data.get(key, [])
        existing.append(pt)

        out_data[key] = existing
        
    with open(OUT_FILE, "w") as output_file:
        json.dump(out_data, output_file)