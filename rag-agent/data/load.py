


import os
import asyncio
import time
from concurrent.futures import ThreadPoolExecutor
from azure.cosmos import ThroughputProperties, PartitionKey, exceptions
from azure.cosmos import CosmosClient
from azure.identity import DefaultAzureCredential
from extract import extract_data


cosmos_client = CosmosClient(url=os.getenv("COSMOSDB_URL"), credential=DefaultAzureCredential())

database_name = "vectorSearchDB"

db = cosmos_client.get_database_client(database=database_name)

movie_container = db.get_container_client(container="Movies")

data = extract_data()

async def insert_data():
    start_time = time.time()

    counter = 0
    tasks = []
    max_concurrency = 2
    semaphore = asyncio.Semaphore(max_concurrency)
    print("Loading the docs, please wait ...")

    def upsert_item_sync(object):
       movie_container.upsert_item(body=object)


    async def upsert_object(object):
        nonlocal counter
        async with semaphore:
            await asyncio.get_event_loop().run_in_executor(None, upsert_item_sync, object)
            counter += 1
            if counter % 100 == 0:
                print(f"Sent {counter} documents for insertion into collection")

    
    for obj in data:
        tasks.append(asyncio.create_task(upsert_object(obj)))

    
    await asyncio.gather(*tasks)

    end_time = time.time()
    duration = end_time - start_time
    print(f"All {counter} documents inserted!")
    print(f"Time taken: {duration:.2f} seconds ({duration:.3f} milliseconds)")

asyncio.run(insert_data())