import os
import json
import time
import logging
from typing import Any, List
from azure.identity import DefaultAzureCredential
from azure.cosmos import ContainerProxy, CosmosClient

cosmos_client = CosmosClient(url=os.getenv("COSMOSDB_URL"), credential=DefaultAzureCredential())

database_name = "vectorSearchDB"

db = cosmos_client.get_database_client(database=database_name)

container = db.get_container_client(container="Movies")


def _write_vectors_to_file(vectors: Any) -> None:
    try:
        base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data"))
        os.makedirs(base_dir, exist_ok=True)
        filename = f"vectors_{int(time.time())}.json"
        path = os.path.join(base_dir, filename)
        with open(path, "w", encoding="utf-8") as f:
            json.dump({"vectors": vectors}, f, ensure_ascii=False, indent=2)
    except Exception:
        return


def _write_query_debug(query: str, parameters: Any) -> None:
    """Write the full query and parameters to a timestamped JSON file for debugging."""
    try:
        base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "data"))
        os.makedirs(base_dir, exist_ok=True)
        filename = f"query_{int(time.time())}.json"
        path = os.path.join(base_dir, filename)
        payload = {
            "query": query,
            "parameters": parameters,
        }
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2, default=str)
    except Exception:
        return


def vector_search(vectors: List[float], similarity_score: float = 0.02, num_results: int = 5):

    # _write_vectors_to_file(vectors)

    query_text = '''
        SELECT TOP @num_results c.overview, VectorDistance(c.vector, @embedding) as SimilarityScore 
        FROM c
        WHERE VectorDistance(c.vector,@embedding) > @similarity_score
        ORDER BY VectorDistance(c.vector,@embedding)
    '''

    parameters = [
        {"name": "@embedding", "value": vectors},
        {"name": "@num_results", "value": num_results},
        {"name": "@similarity_score", "value": similarity_score},
    ]

    # Write debug file with full query and params (best-effort)
    # _write_query_debug(query_text, parameters)

    query_result = container.query_items(
        query=query_text,
        parameters=parameters,
        enable_cross_partition_query=True,
        populate_query_metrics=True,
    )

    results = list(query_result)

    logging.info("Effective query result: %s", results)

    formatted_results = [{"SimilarityScore": result.pop("SimilarityScore"), "document": result} for result in results]

    return formatted_results

def get_chat_history():
    pass