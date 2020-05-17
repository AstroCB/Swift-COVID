# Convert bordpnts.asc file to JSON data
import json
from point import Sorter, Point

IN_FILE = "bordpnts.asc"
OUT_FILE = "borders.json"
STATE_IND = 1
LAT_IND = 3
LNG_IND = 4

read_format = False
borders = {}
with open(IN_FILE) as border_data:
    for line in border_data:
        if not read_format:
            read_format = True
        else:
            # Extract data from csv-ish-formatted line
            data = list(map(lambda s: s.strip(), line.split(",")))
            state1, state2 = data[STATE_IND].split("-")
            lat = float(data[LAT_IND])
            # Longitude doesn't include negative in data set for some reason
            lng = -float(data[LNG_IND])

            # Insert lat/long border point for both states
            for state in [state1, state2]:
                existing = borders.get(state, [])
                existing.append({"lat": lat, "lng": lng})
                borders[state] = existing

# Convert JSON representation to something that will translate better to Swift
borders_out = []
for state, coords in borders.items():
    coord_points = list(map(lambda c: Point(c["lat"], c["lng"]), coords))
    sorted_points = Sorter(coord_points).sorted()
    sorted_coords = list(map(lambda p: p.to_json(), sorted_points))
    borders_out.append({
        "state": state,
        "coords": sorted_coords
    })

with open(OUT_FILE, "w") as output_file:
    json.dump(borders_out, output_file)

