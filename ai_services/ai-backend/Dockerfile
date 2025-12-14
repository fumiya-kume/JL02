FROM python:3.12-slim

WORKDIR /app

# Copy and install requirements
COPY ai_services/ai-backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ai_services/ai-backend/src ./src

# Copy GinzaDB database into container for location lookup
# This makes the database accessible to LocationDBLookup at runtime
COPY GinzaDB ./GinzaDB

# AppRun will inject PORT environment variable
EXPOSE 8080

CMD ["sh", "-c", "uvicorn src.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
