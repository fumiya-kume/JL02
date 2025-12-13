from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello from AppRun + FastAPI"}

@app.get("/health")
def health():
    return {"status": "ok"}
