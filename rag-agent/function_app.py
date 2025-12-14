import json
import azure.functions as func
import azure.durable_functions as df
import logging
from openai import OpenAI
from agents import Agent, Runner
from tools.knowledge_base import vector_search

oai = OpenAI()

app = func.FunctionApp()

EMBEDDING_MODEL = "text-embedding-3-small"
EMBEDDING_DIMENSION = 1536
CHAT_MODEL = "gpt-4o-mini"


@app.route(route="orchestrations/{functionName}")
@app.durable_client_input(client_name="client")
async def http_start(req: func.HttpRequest, client):
    function_name = req.route_params.get('functionName')
    payload = req.get_json()
    instance_id = await client.start_new(function_name, None, payload['chat'])
    return client.create_check_status_response(req, instance_id)


@app.activity_trigger(input_name="text")
def convert_to_embeddings(text):
    try:
        response = oai.embeddings.create(
            input=text,
            model=EMBEDDING_MODEL,
            dimensions=EMBEDDING_DIMENSION
        )

        embeddings = response.model_dump()

        return json.dumps({
            "question": text,
            "vector": embeddings["data"][0]["embedding"]
        })
    except Exception as e:
        logging.error("An error occured while generating embeddings.", exc_info=True)
        raise


@app.activity_trigger(input_name="question")
def question_optmizer(question):
    agent = Agent(
        name="Query Optmizer",
        instructions="""You're a helpful assistant that improve questions for knowledge
        retrieval. Your role is to improve a question for a future vector search.
        """,
        model=CHAT_MODEL
    )

    response = Runner.run_sync(agent, question)

    return response.final_output

@app.activity_trigger(input_name="question")
def ask_movie_specialist(question: str):

    content = json.loads(question)

    if not content.get("vector") or not content.get("question"):
        return "Question could not be processed. Ask again."

    results = vector_search(content.get("vector"), similarity_score=0.02)

    logging.info("Results from vector search %s", results)

    agent = Agent(
        name="Movie Specialist",
        instructions=f"""You're a helpful movie specialist which is able to indicate the best movies that fit customer needs.
        Use this result list: {results} information as reference. If no result is provided say you dont know.
        """,
        tools=[],
        model=CHAT_MODEL
    )

    response = Runner.run_sync(agent, content.get("question"))

    return response.final_output



@app.orchestration_trigger(context_name="context")
def start_conversation(context: df.DurableOrchestrationContext):
    logging.info("Orchestrator started")

    input_data = context.get_input()
    logging.info(f"Input data: {input_data}")

    better_question = yield context.call_activity("question_optmizer", input_data)

    logging.info(f"improved question: {better_question}")

    question_as_embedding = yield context.call_activity_with_retry(
        "convert_to_embeddings",
        retry_options=df.RetryOptions(
            first_retry_interval_in_milliseconds=500,
            max_number_of_attempts=5
        ),
        input_=better_question
    )


    specialist_advice = yield context.call_activity("ask_movie_specialist", question_as_embedding)

    logging.info(f"Answer:\n {specialist_advice}")


