# Preprocess the population data to reorganize into a format that's
# more useful for our purposes
import json

IN_FILE = "population.json"
ABBRV_FILE = "abbreviations.json"
OUT_FILE = "swift-challenge.playground/Resources/population.json"

out_data = {}
with open(IN_FILE) as input_file:
    with open(ABBRV_FILE) as abbrv_file:
        data = json.load(input_file)
        abbrvs = json.load(abbrv_file)

        for state in sorted(data["data"], key=lambda s: s["State"]):
            name = state["State"]
            abbrv = abbrvs[name]
            out_data[abbrv] = state["Population"]
            
        with open(OUT_FILE, "w") as output_file:
            json.dump(out_data, output_file)