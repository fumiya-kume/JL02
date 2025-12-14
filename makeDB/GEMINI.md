# Project Overview

This project is a Python-based system for automatically generating descriptions of tourist spots. It takes a geographical location name (e.g., "Ginza") as input, gathers information from various reliable sources, and uses a Large Language Model (LLM) to create detailed, high-quality descriptions. The final output is a JSON file containing the generated tourist spot data.

The system is designed to be fully automatic, prevent LLM hallucinations by using only collected factual data, and is cost-effective.

## Key Technologies

*   **Language:** Python 3.11+
*   **Package Manager:** uv
*   **Core Libraries:**
    *   `google-generativeai`: For using the Gemini LLM.
    *   `anthropic`: For using the Claude LLM.
    *   `openai`: (Implied, for using OpenAI LLMs).
    *   `requests`: For making HTTP requests to APIs.
    *   `wikipedia-api`: For fetching data from Wikipedia.
    *   `pyyaml`: For configuration management.
*   **APIs:**
    *   Google Places API: To find spots and gather initial data.
    *   Google Custom Search API: For supplementary web search.
    *   Wikipedia API: For detailed historical and descriptive information.
    *   LLM APIs: Gemini, Claude, or OpenAI for generating the final text.

## Architecture

The process flow is as follows:
1.  **Input:** A region name is provided by the user.
2.  **Spot Finding:** The `SpotFinder` class uses the Google Places API to find a list of relevant tourist spots in the given region.
3.  **Data Collection:** The `DataCollector` class gathers detailed information for each spot from multiple sources:
    *   Google Places API (details like ratings, opening hours).
    *   Wikipedia API (summaries, history).
    *   Google Custom Search (if Wikipedia data is insufficient).
4.  **Data Verification:** The `DataVerifier` class performs a sanity check on the collected data, ensuring essential fields like name and address are present and valid. It assigns a confidence score.
5.  **Description Generation:** The `AIDescriptionGenerator` class constructs a detailed prompt containing only the verified, factual data and instructs an LLM (configurable between Gemini, Claude, and OpenAI) to write a description within strict constraints (e.g., length, content).
6.  **Quality Validation:** The `QualityValidator` class checks the LLM-generated text against rules, such as character count and the absence of speculative language.
7.  **Output:** The final, structured data, including the generated description, is written to a `{region_name}_tourist_spots.json` file.

## Building and Running

### 1. Setup

The project uses `uv` for managing dependencies. To set up the environment, you would typically run:

```bash
# First time setup
python -m venv .venv
source .venv/bin/activate # or .\.venv\Scripts\activate on Windows
pip install uv
uv pip install -r requirements.txt # Assuming pyproject.toml dependencies are in requirements.txt
```
*(Note: As `requirements.txt` is not present, the dependencies are listed in `pyproject.toml`)*

### 2. Configuration

Before running, you must configure API keys in the `config.yaml` file. This includes keys for your chosen LLM and the Google Cloud services (Places API, Custom Search).

```yaml
# config.yaml
llm:
  provider: "gemini"  # "gemini", "openai", or "claude"
  # ... Add API keys for the selected provider
  gemini:
    api_key: "YOUR_GEMINI_API_KEY"

data_collection:
  google_places:
    api_key: "YOUR_GOOGLE_PLACES_API_KEY"
  web_search:
    api_key: "YOUR_GOOGLE_SEARCH_API_KEY"
    search_engine_id: "YOUR_SEARCH_ENGINE_ID"
```

### 3. Running the Application

The main entry point is the `tourist_spot_generator.py` script.

```bash
python tourist_spot_generator.py
```

The script will then prompt you to enter a region name.

## Development Conventions

*   **Configuration:** All external keys, model choices, and generation parameters (like description length) are managed in `config.yaml`.
*   **Modularity:** The code is well-structured into classes, each with a specific responsibility (`SpotFinder`, `DataCollector`, `AIDescriptionGenerator`, etc.), making it easy to maintain and extend.
*   **Data Flow:** Data is passed between components using a `SpotData` dataclass, which clearly defines the data structure.
*   **Error Handling:** The script includes `try...except` blocks to handle potential API errors and file-not-found issues gracefully.
*   **Hallucination Prevention:** A key design principle is to constrain the LLM by providing it only with pre-verified, factual data and explicitly instructing it not to add any outside information.
