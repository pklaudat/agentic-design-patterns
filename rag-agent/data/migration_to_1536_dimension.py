import json
import time
import random
from tqdm import tqdm
from openai import OpenAI, RateLimitError, APIError, APITimeoutError

# ---------------- CONFIG ----------------
INPUT_FILE = "MovieLens-4489-256D.json"
OUTPUT_FILE = "movies_fixed_v2.json"

EMBEDDING_MODEL = "text-embedding-3-small"
EXPECTED_DIM = 1536
MAX_RETRIES = 6
BASE_DELAY = 1.0  # seconds
# ---------------------------------------

client = OpenAI()


def build_embedding_text(doc: dict) -> str:
    genres = ", ".join(g["name"] for g in doc.get("genres", []))
    return f"""
Title: {doc.get("title", "")}
Overview: {doc.get("overview", "")}
Genres: {genres}
Tagline: {doc.get("tagline", "")}
""".strip()


def embed_with_retry(text: str) -> list[float]:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            response = client.embeddings.create(
                model=EMBEDDING_MODEL,
                input=text
            )

            embedding = response.data[0].embedding

            if len(embedding) != EXPECTED_DIM:
                raise ValueError(
                    f"Embedding dimension mismatch: {len(embedding)}"
                )

            return embedding

        except (RateLimitError, APITimeoutError, APIError) as e:
            if attempt == MAX_RETRIES:
                raise

            sleep = BASE_DELAY * (2 ** (attempt - 1))
            sleep += random.uniform(0, 0.5)

            print(
                f"Retry {attempt}/{MAX_RETRIES} "
                f"({type(e).__name__}) — sleeping {sleep:.2f}s"
            )
            time.sleep(sleep)


def main():
    # Load input once (array of docs)
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        documents = json.load(f)

    print(f"Loaded {len(documents)} documents")

    # Open output file and stream-write JSON array
    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        out.write("[\n")

        first = True
        for doc in tqdm(documents, desc="Embedding"):
            text = build_embedding_text(doc)
            doc["vector"] = embed_with_retry(text)

            if not first:
                out.write(",\n")
            first = False

            json.dump(doc, out, ensure_ascii=False)

        out.write("\n]")

    print(f"✅ Done. File written incrementally to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
