#!/usr/bin/env python3
"""
Step 2: Query Sakura AI Engine RAG
This script queries the uploaded documents using the RAG API.
"""

import json
import os
import sys
import logging
from urllib.request import Request, urlopen
from urllib.error import URLError, HTTPError

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


def get_api_token():
    """Retrieve API token from environment variable."""
    token = os.environ.get('SAKURA_OPENAI_API_TOKEN')
    if not token:
        logger.error("SAKURA_OPENAI_API_TOKEN environment variable not set")
        sys.exit(1)
    logger.info("API token loaded from environment variable")
    return token


def query_rag(api_token, query, top_k=3, threshold=0.3):
    """
    Query the RAG database.

    Args:
        api_token: API token for authentication
        query: Query string in Japanese
        top_k: Number of top results to retrieve
        threshold: Similarity threshold for filtering results

    Returns:
        Response JSON containing answer and sources
    """
    url = "https://api.ai.sakura.ad.jp/v1/documents/chat/"

    # Prepare the request payload
    payload = {
        "model": "multilingual-e5-large",
        "chat_model": "gpt-oss-120b",
        "query": query,
        "top_k": top_k,
        "threshold": threshold
    }

    # Convert payload to JSON
    json_data = json.dumps(payload).encode('utf-8')

    # Create request
    req = Request(
        url,
        data=json_data,
        headers={
            'Authorization': f'Bearer {api_token}',
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        },
        method='POST'
    )

    try:
        logger.info(f"Querying RAG: '{query}'")
        logger.debug(f"Parameters: top_k={top_k}, threshold={threshold}")

        with urlopen(req, timeout=30) as response:
            response_data = response.read().decode('utf-8')
            response_json = json.loads(response_data)

            logger.info(f"Query successful! Response status: {response.status}")

            return response_json

    except HTTPError as e:
        error_body = e.read().decode('utf-8')
        logger.exception(f"HTTP Error {e.code}: {e.reason}")
        logger.debug(f"Error response: {error_body}")
        return None
    except URLError as e:
        logger.exception(f"URL Error: {e.reason}")
        return None
    except Exception as e:
        logger.exception(f"Unexpected error: {e}")
        return None


def format_answer(response_json):
    """Format the RAG response for display."""
    if not response_json:
        return "Error: No response received"

    answer = response_json.get('answer', 'No answer provided')
    sources = response_json.get('sources', [])

    output = f"\n{'=' * 60}\n"
    output += "RAG ANSWER:\n"
    output += f"{'=' * 60}\n\n"
    output += answer
    output += f"\n\n{'=' * 60}\n"
    output += "SOURCES:\n"
    output += f"{'=' * 60}\n\n"

    if sources:
        for i, source in enumerate(sources, 1):
            doc = source.get('document', {})
            chunk_index = source.get('chunk_index', 'N/A')
            distance = source.get('distance', 'N/A')

            output += f"[{i}] Document: {doc.get('name', 'Unknown')}\n"
            output += f"    ID: {doc.get('id', 'N/A')}\n"
            output += f"    Status: {doc.get('status', 'N/A')}\n"
            output += f"    Model: {doc.get('model', 'N/A')}\n"
            output += f"    Chunk Index: {chunk_index}\n"
            output += f"    Similarity Distance: {distance:.4f}\n"
            output += f"    Content Preview: {source.get('content', 'N/A')[:150]}...\n\n"
    else:
        output += "No sources found.\n"

    output += f"{'=' * 60}\n"

    return output


def main():
    """Main execution function."""
    logger.info("=" * 60)
    logger.info("Step 2: Query RAG")
    logger.info("=" * 60)

    # Get API token
    api_token = get_api_token()

    # Example queries
    queries = [
        "銀座の有名な百貨店はどこですか？",
        "銀座で美術館や文化施設はありますか？",
        "銀座で買い物ができる商業施設を教えてください",
    ]

    logger.info(f"Running {len(queries)} example queries...\n")

    results = []

    for i, query in enumerate(queries, 1):
        logger.info(f"\n--- Query {i}/{len(queries)} ---")
        response = query_rag(api_token, query)

        if response:
            results.append({
                "query": query,
                "response": response
            })

            # Print formatted answer
            formatted = format_answer(response)
            print(formatted)
        else:
            logger.error(f"Failed to get response for query: {query}")

    logger.info("=" * 60)
    logger.info(f"Completed {len(results)} queries")
    logger.info("=" * 60)

    return results


if __name__ == '__main__':
    main()
