import requests
from agents.tool import function_tool


def get_weather(city: str):
    geo = requests.get(
        f"https://geocoding-api.open-meteo.com/v1/search?name={city}"
    ).json()["results"][0]

    lat, lon = geo["latitude"], geo["longitude"]

    weather = requests.get(
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}&current_weather=true"
    ).json()["current_weather"]

    return weather


# Tool registration - return a FunctionTool wrapping `get_weather` so agents can call it
def weather_tool():
    return function_tool(get_weather)
