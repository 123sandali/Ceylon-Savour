from fastapi import FastAPI

app = FastAPI(
    title="CeylonSavour API",
    description="Backend API for the CeylonSavour culinary tourism recommender.",
    version="0.1.0",
)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {"status": "ok"}