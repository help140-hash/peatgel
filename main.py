from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
import httpx

app = FastAPI()

PLANTNET_API_KEY = "2b10aT7PlbjHJ89m6pbWY3EnN"
PLANTNET_URL = "https://my-api.plantnet.org/v2/identify/all"

@app.get("/")
def root():
    return {"status": "ok", "message": "PlantNet proxy"}

@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    image_data = await file.read()

    async with httpx.AsyncClient() as client:
        response = await client.post(
            PLANTNET_URL,
            params={"api-key": PLANTNET_API_KEY},
            files={"images": (file.filename, image_data, file.content_type)},
            data={"organs": "leaf"},
            timeout=30.0,
        )

    if response.status_code != 200:
        return JSONResponse(
            status_code=response.status_code,
            content={"error": response.text},
        )

    data = response.json()
    results = data.get("results", [])

    if not results:
        return JSONResponse({"label": "Не распознано", "confidence": 0.0})

    first = results[0]
    label = first.get("species", {}).get("scientificNameWithoutAuthor", "Unknown")
    score = first.get("score", 0.0)

    return JSONResponse({
        "label": label,
        "confidence": round(score, 4),
        "top3": [
            {
                "label": r.get("species", {}).get("scientificNameWithoutAuthor", ""),
                "confidence": round(r.get("score", 0.0), 4),
            }
            for r in results[:3]
        ],
    })
