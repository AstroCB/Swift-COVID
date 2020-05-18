# Convert tl_2017_us_state.shp to JSON
import json
import shapefile
from point import Sorter, Point

IN_FILE = "tl_2017_us_state/tl_2017_us_state"
OUT_FILE = "swift-challenge.playground/Resources/borders.json"
# Data set is extremely large and precise; using every point is unnecessary
# and performance-prohibitive. Only keep 1 in DROP_RATE points for performance.
# Decrease DROP_RATE to improve accuracy of borders.
DROP_RATE = 25
# Continental US only
EXCLUDED_STATES = ["PR", "GU", "AS", "VI"]

read_format = False
states = []

counter = 0
with shapefile.Reader(IN_FILE) as sf:
    for shp in sf.shapeRecords():
        data = shp.__geo_interface__
        info = data["properties"]
        state = info["STUSPS"] # Postal abbreviation
        coords = data["geometry"]["coordinates"]

        if state not in EXCLUDED_STATES:
            borders = []
            for poly in coords:
                if not isinstance(poly[0][0], float):
                    # Needs to be flattened further
                    poly = [coord for subpoly in poly for coord in subpoly]

                # Convert to JSON point
                json_coords = []
                for lng, lat in poly:
                    if counter % DROP_RATE == 0:
                        json_coords.append({"lat": lat, "lng": lng})
                    counter += 1
                borders.append(json_coords)
            
            states.append({
                "state": state,
                "borders": borders
            })

# Write out JSON data
with open(OUT_FILE, "w") as output_file:
    json.dump(states, output_file)

