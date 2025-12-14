
def extract_data():
    import json

    file_name = "movies_fixed_v2"

    data = []
    with open(f"{file_name}.json", "r", encoding="utf-8-sig") as d:
        data = json.load(d)

    len(data)

    return data
