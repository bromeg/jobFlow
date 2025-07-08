from fastapi import FastAPI, Request
from pydantic import BaseModel

app = FastAPI()

class ResumeRequest(BaseModel):
    resume: str

@app.post("/analyze_resume")
async def analyze_resume(req: ResumeRequest):
    # Mock analysis logic
    return {
        "match_score": 87,
        "suggestions": [
            "Add more keywords from the job description.",
            "Quantify your achievements.",
            "Highlight leadership experience."
        ]
    }
