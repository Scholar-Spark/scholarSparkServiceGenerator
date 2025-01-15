from fastapi import FastAPI
from app.api.routes.router import router

app = FastAPI(
    title="<%= name %>",
    description="<%= description %>",
    version="1.0.0"
)

app.include_router(router)

@app.get("/health")
async def health_check():
    return {"status": "healthy"}