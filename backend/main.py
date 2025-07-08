import os
import openai
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import time
import re

app = FastAPI()

openai.api_key = os.getenv("OPENAI_API_KEY")

REQUEST_LIMIT = 20  # max requests
WINDOW_SECONDS = 3600  # per hour

request_times = []

MAX_CHARS = 3000

PROMPT_TEMPLATE = """
You are a professional resume coach and AI hiring assistant. Your task is to evaluate how well a resume matches a given job description using the criteria below, and provide clear, actionable suggestions to improve the candidate's chances of passing automated resume screening systems (ATS) and securing a first interview.

Use only the information provided in the resume. Do not fabricate or invent new experience, skills, or qualifications. You may reframe or rephrase existing content to better align with the job description.

### Evaluation Criteria:
1. **Keyword Match:** Does the resume contain terminology and skills that match the job description? Evaluate how closely the wording in the resume reflects the job listing, especially in required skills, tools, and responsibilities.
2. **Relevant Experience:** Does the candidate's work history clearly align with the core responsibilities of the role?
3. **Qualifications Match:** Does the resume reflect the required experience level, certifications, or domain knowledge asked for in the job description?
4. **ATS Compatibility:** Does the resume follow formatting and phrasing practices that make it readable by ATS software (e.g., standard section headings, no graphics, consistent title formatting)?

---

### Output Format:
Respond with:
- A **Match Score** (0–100%)
- A **Concise Justification** (2–3 sentences)
- **3–5 Full-Sentence Suggestions for Improvement** (in professional tone, focused on keyword alignment, content reframing, or formatting improvements)

Each suggestion should include specific examples based on the resume. Focus on areas where wording could be improved to better reflect the language of the job description. If the resume is strong, still provide subtle suggestions for refinement.

---

### Input:
**Resume:**
{resume}

**Job Description:**
{job_description}
"""

class ResumeRequest(BaseModel):
    resume: str
    job_description: str

@app.post("/analyze_resume")
async def analyze_resume(req: ResumeRequest):
    print("Received:", req)
    # Rate limiting
    now = time.time()
    # Remove requests outside the window
    global request_times
    request_times = [t for t in request_times if now - t < WINDOW_SECONDS]
    if len(request_times) >= REQUEST_LIMIT:
        raise HTTPException(status_code=429, detail="API rate limit exceeded. Please try again later.")
    request_times.append(now)

    # if len(req.resume) > MAX_CHARS or len(req.job_description) > MAX_CHARS:
    #     print("Input too long:", len(req.resume), len(req.job_description))
    #     raise HTTPException(status_code=400, detail="Input too long.")

    prompt = PROMPT_TEMPLATE.format(
        resume=req.resume,
        job_description=req.job_description
    )
    response = openai.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        max_tokens=600,
        temperature=0.7,
    )
    content = response.choices[0].message.content or ""
    score, justification, suggestions = parse_openai_response(content)
    return {
        "match_score": score,
        "justification": justification,
        "suggestions": suggestions
    }

def parse_openai_response(content: str):
    # Extract Match Score
    score_match = re.search(r"Match Score[:\s]*([0-9]{1,3})%", content, re.IGNORECASE)
    score = int(score_match.group(1)) if score_match else 0

    # Extract Concise Justification
    justification_match = re.search(r"Concise Justification[:\s]*([^\n#-]+)", content, re.IGNORECASE)
    justification = justification_match.group(1).strip() if justification_match else ""

    # Extract Suggestions (numbered list)
    suggestions = re.findall(r"\d+\.\s*([^\n]+)", content)
    if not suggestions:
        # fallback: try to split by newlines after "Suggestions for Improvement:"
        sugg_section = re.split(r"Suggestions for Improvement[:\s]*", content, flags=re.IGNORECASE)
        if len(sugg_section) > 1:
            suggestions = [line.strip() for line in sugg_section[1].split('\n') if line.strip()]

    return score, justification, suggestions[:5]
