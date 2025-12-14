#!/usr/bin/env python3
"""
Step 1: Upload GinzaDB documents to Sakura AI Engine RAG
This script uploads the ginzaDB.json file to Sakura AI Engine's RAG database.
"""

import json
import os
import sys
import logging
import tempfile
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


def load_ginza_db(file_path):
    """Load the GinzaDB JSON file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        logger.info(f"Successfully loaded GinzaDB from {file_path}")
        logger.info(f"Found {len(data.get('ginza_tourist_spots', []))} tourist spots")
        return data
    except FileNotFoundError:
        logger.error(f"File not found: {file_path}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in {file_path}: {e}")
        sys.exit(1)


def format_document_text(spot):
    """Format a tourist spot as document text for RAG."""
    text = f"""名前: {spot.get('name', 'N/A')}
住所: {spot.get('address', 'N/A')}
説明: {spot.get('description', 'N/A')}
緯度: {spot.get('latitude', 'N/A')}
経度: {spot.get('longitude', 'N/A')}"""
    return text.strip()


def upload_file(api_token, file_path, file_name):
    """
    Upload a single file to Sakura AI Engine RAG.

    Args:
        api_token: API token for authentication
        file_path: Path to the file to upload
        file_name: Name of the file for the API
    """
    url = "https://api.ai.sakura.ad.jp/v1/documents/upload/"

    try:
        logger.info(f"Uploading file: {file_name}")

        # Read file
        with open(file_path, 'rb') as f:
            file_data = f.read()

        # Create multipart form data manually
        boundary = '----WebKitFormBoundary' + os.urandom(16).hex()
        body = b''
        body += f'--{boundary}\r\n'.encode()
        body += f'Content-Disposition: form-data; name="file"; filename="{file_name}"\r\n'.encode()
        body += b'Content-Type: text/plain\r\n\r\n'
        body += file_data
        body += b'\r\n'
        body += f'--{boundary}--\r\n'.encode()

        req = Request(
            url,
            data=body,
            headers={
                'Authorization': f'Bearer {api_token}',
                'Accept': 'application/json',
                'Content-Type': f'multipart/form-data; boundary={boundary}'
            },
            method='POST'
        )

        logger.debug(f"Request body size: {len(body)} bytes")

        with urlopen(req, timeout=30) as response:
            response_data = response.read().decode('utf-8')
            response_json = json.loads(response_data)

            logger.info(f"Upload successful! Response status: {response.status}")
            logger.info(f"Response: {json.dumps(response_json, ensure_ascii=False, indent=2)}")

            return response_json

    except HTTPError as e:
        error_body = e.read().decode('utf-8')
        logger.error(f"HTTP Error {e.code}: {e.reason}")
        logger.error(f"Error response: {error_body}")
        return None
    except URLError as e:
        logger.error(f"URL Error: {e.reason}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return None


def main():
    """Main execution function."""
    logger.info("=" * 60)
    logger.info("Step 1: Upload GinzaDB to Sakura AI Engine RAG")
    logger.info("=" * 60)

    # Get API token
    api_token = get_api_token()

    # Load GinzaDB
    ginza_db_path = os.path.join(
        os.path.dirname(__file__),
        '../../GinzaDB/ginzaDB.json'
    )
    db_data = load_ginza_db(ginza_db_path)

    # Prepare documents
    tourist_spots = db_data.get('ginza_tourist_spots', [])

    logger.info(f"Preparing {len(tourist_spots)} individual document files...")

    # Create temporary directory for files
    with tempfile.TemporaryDirectory() as tmpdir:
        upload_results = []

        for i, spot in enumerate(tourist_spots, 1):
            spot_name = spot.get('name', 'unknown').replace(' ', '_').replace('　', '_')
            file_name = f"{i:02d}_{spot_name}.txt"
            file_path = os.path.join(tmpdir, file_name)

            # Format and write individual spot file
            doc_text = format_document_text(spot)

            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(doc_text)

            logger.debug(f"[{i}/{len(tourist_spots)}] Created file: {file_name}")

            # Upload individual file
            logger.info(f"[{i}/{len(tourist_spots)}] Uploading: {file_name}")
            response = upload_file(api_token, file_path, file_name)

            if response:
                upload_results.append({
                    'spot_name': spot.get('name'),
                    'file_name': file_name,
                    'document_id': response.get('id'),
                    'status': response.get('status'),
                    'success': True
                })
                logger.info(f"  ✓ Success! Document ID: {response.get('id')}")
            else:
                upload_results.append({
                    'spot_name': spot.get('name'),
                    'file_name': file_name,
                    'success': False
                })
                logger.warning(f"  ✗ Failed to upload {file_name}")

    logger.info("=" * 60)
    logger.info("Upload Summary:")
    logger.info("=" * 60)

    successful = sum(1 for r in upload_results if r.get('success'))
    failed = sum(1 for r in upload_results if not r.get('success'))

    logger.info(f"Total documents: {len(upload_results)}")
    logger.info(f"Successful: {successful}")
    logger.info(f"Failed: {failed}")

    if successful > 0:
        logger.info("\nSuccessfully uploaded documents:")
        for result in upload_results:
            if result.get('success'):
                logger.info(f"  - {result['spot_name']}: {result['document_id']}")

    if failed > 0:
        logger.warning("\nFailed documents:")
        for result in upload_results:
            if not result.get('success'):
                logger.warning(f"  - {result['spot_name']}")

    logger.info("=" * 60)

    return upload_results


if __name__ == '__main__':
    main()
