import json
import azure.functions as func
import azure.durable_functions as df
from config import Config
from agents import Agent, Runner

from tools.weather import weather_tool

config = Config()
app = func.FunctionApp()


# ---------------------------
# HTTP STARTER
# ---------------------------
@app.route(route="orchestrators/{functionName}")
@app.durable_client_input(client_name="client")
async def start_orchestrator(req: func.HttpRequest, client):
    fn = req.route_params.get("functionName")

    try:
        payload = req.get_json()
        print(f"Payload: {payload}")
    except ValueError:
        payload = None

    city = None
    if payload:
        if isinstance(payload, dict) and "city" in payload:
            city = payload["city"]
        else:
            city = payload
    else:
        city = req.params.get("city")

    instance_id = await client.start_new(fn, None, city)
    print(f"Started orchestration instance_id={instance_id} input={city}")
    return client.create_check_status_response(req, instance_id)


# ---------------------------
# CHAINED AGENT ORCHESTRATOR
# ---------------------------
@app.orchestration_trigger(context_name="context")
def chained_agent_orchestration_orchestrator(context: df.DurableOrchestrationContext):
    city = context.get_input()

    print(f"Orchestrator started with city: {city}")

    result1 = yield context.call_activity("normalize_city", city)

    result2 = yield context.call_activity("weather_retriever", result1)

    result3 = yield context.call_activity("explain_the_weather", result2)

    print(f"City: {result1} Weather: {result2} Explanation: {result3}")

    return {"city": result1, "weather": result2, "explanation": result3}


# ---------------------------
# Agent & Tasks
# ---------------------------
@app.activity_trigger(input_name="city")
def normalize_city(city: str):
    if not city:
        return ""

    normalizer = Agent(
        name="city_normalizer",
        instructions="Fix typos and return a valid city name.",
    )

    try:
        result = Runner.run_sync(normalizer, str(city))
        return result.final_output
    except Exception as e:
        return f"[normalize_city_error] {e}"


@app.activity_trigger(input_name="city")
def weather_retriever(city):
    try:
        agent = Agent(
            name="weather_retriever",
            instructions="Given a city name, call the get_weather tool and return the raw weather data.",
            tools=[weather_tool()],
        )

        result = Runner.run_sync(agent, str(city))

        return result.final_output
    except Exception as e:
        return {"error": str(e)}


@app.activity_trigger(input_name="weather")
def explain_the_weather(weather):
    try:
        prompt = ""
        if isinstance(weather, dict):
            prompt = json.dumps(weather)
        else:
            prompt = str(weather)

        explainer = Agent(
            name="weather_explainer",
            instructions="Explain the weather in a friendly, concise tone.",
        )

        result = Runner.run_sync(explainer, prompt)
        return result.final_output
    except Exception as e:
        return f"[explain_the_weather_error] {e}"
