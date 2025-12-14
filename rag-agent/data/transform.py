import logging
from openai import OpenAI
from tenacity import retry, stop_after_attempt, wait_random_exponential

openai_client = OpenAI()

@retry(wait=wait_random_exponential(min=2, max=300), stop=stop_after_attempt(20))
def generate_embeddings(text, embeddings_model, embeddings_dimension):
    try:
        response = openai_client.embeddings.create(
            input=text,
            model=embeddings_model,
            dimensions=embeddings_dimension
        )

        embeddings = response.model_dump()

        return embeddings["data"][0]["embedding"]
    except Exception as e:
        logging.error("An error occured while generating embeddings.", exc_info=True)
        raise