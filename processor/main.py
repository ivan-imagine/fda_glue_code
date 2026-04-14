from fastapi import FastAPI

app = FastAPI()

@app.post("/process")
async def process_event(data: dict):
    channel = data.get("channel", {})
    user = data.get("user", {})
    message = data.get("message", "Sin mensaje")

    response = {
        "status": "success",
        "formatted_message": message,
        "channel": channel.get("id", "unknown"),
        "phone": user.get("phone", "unknown")
    }

    return response