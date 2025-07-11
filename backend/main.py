import os
import openai
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import time
import re
import PyPDF2
from typing import Optional
import docx

# Initialize FastAPI app
app = FastAPI()

# Set OpenAI API key from environment variable (never hardcode secrets)
openai.api_key = os.getenv("OPENAI_API_KEY")

# --- Rate Limiting Configuration ---
REQUEST_LIMIT = 20  # Max requests allowed per time window
WINDOW_SECONDS = 3600  # Time window in seconds (1 hour)
request_times = []  # Stores timestamps of recent requests

# --- Input Size Limit ---
MAX_CHARS = 3000  # Maximum allowed characters for resume or job description

# --- Prompt Template for ChatGPT ---
# This template guides the AI to evaluate the resume against the job description
PROMPT_TEMPLATE = """
You are a professional resume coach and AI hiring assistant. Your task is to evaluate how well a resume matches a given job description using the criteria below, and provide clear, actionable suggestions to improve the candidate's chances of passing automated resume screening systems (ATS) and securing a first interview.

Use only the information provided in the resume. Do not fabricate or invent new experience, skills, or qualifications. You may reframe or rephrase existing content to better align with the job description.

### Evaluation Criteria:
1. **Keyword Match:** Does the resume contain terminology and skills that match the job description? Evaluate how closely the wording in the resume reflects the job listing, especially in required skills, tools, and responsibilities.
2. **Relevant Experience:** Does the candidate's work history clearly align with the core responsibilities of the role?
3. **Qualifications Match:** Does the resume reflect the required experience level, certifications, or domain knowledge asked for in the job description?
4. **ATS Compatibility:** Does the resume follow formatting and phrasing practices that make it readable by ATS software (e.g., standard section headings, no graphics, consistent title formatting)?

Before returning a response, critique your findings and make sure you are not missing any important information or potential recommendations.
---

Using the following job description and candidate resume, evaluate the alignment on a 100-point scale. Consider:

- Core Requirements Match (40%) — Does the resume meet all must-have qualifications?
- Preferred/Bonus Criteria (20%) — Are additional skills/qualifications present?
- Domain/Industry Alignment (20%) — Does the resume reflect experience in the company’s domain or customer base?
- Soft Skills/Culture Fit (20%) — Does the resume signal alignment with the company's stated values, team structure, or ways of working?

### Output Format:
Respond with:

- A numeric match score out of 100
- A brief explanation of how the score was calculated
- Highlights of strong matches and potential gaps (2-5 items)
- Suggestions (3-10 items) for how the resume could be tailored to improve alignment (using only resume content). Provide specific feedback on changes that should be made to the resume to improve the match score. Focus on areas where wording could be improved to better reflect the language of the job description. If the resume is strong, still provide subtle suggestions for refinement.

---

### Input:
**Resume:**
{resume}

**Job Description:**
{job_description}
"""

# --- Request Model ---
class ResumeRequest(BaseModel):
    resume: str
    job_description: str

# --- Main API Endpoint ---
@app.post("/analyze_resume")
async def analyze_resume(req: ResumeRequest):
    print("Received:", req)
    # --- Rate Limiting Logic ---
    now = time.time()
    global request_times
    # Remove timestamps outside the current window
    request_times = [t for t in request_times if now - t < WINDOW_SECONDS]
    if len(request_times) >= REQUEST_LIMIT:
        raise HTTPException(status_code=429, detail="API rate limit exceeded. Please try again later.")
    request_times.append(now)

    # --- (Optional) Input Size Check ---
    # Uncomment to enforce input size limits
    # if len(req.resume) > MAX_CHARS or len(req.job_description) > MAX_CHARS:
    #     print("Input too long:", len(req.resume), len(req.job_description))
    #     raise HTTPException(status_code=400, detail="Input too long.")

    # --- Construct the AI Prompt ---
    prompt = PROMPT_TEMPLATE.format(
        resume=req.resume,
        job_description=req.job_description
    )

    # --- Call OpenAI ChatGPT API ---
    response = openai.chat.completions.create(
        model="gpt-4.1-mini",  # Use GPT-4.0 or GPT-3.5 as needed
        messages=[{"role": "user", "content": prompt}],
        max_tokens=600,
        temperature=0.7,
    )
    # Get the AI's response content (may be None, so default to empty string)
    content = response.choices[0].message.content or ""

    # --- Parse the AI's Response for Score, Justification, and Suggestions ---
    score, justification, suggestions = parse_openai_response(content)
    return {
        "match_score": score,
        "justification": justification,
        "suggestions": suggestions
    }

# --- New Endpoint: Analyze Resume File Upload ---
@app.post("/analyze_resume_file")
async def analyze_resume_file(
    file: UploadFile = File(...),
    job_description: str = Form(...)
):
    # --- Rate Limiting Logic ---
    now = time.time()
    global request_times
    request_times = [t for t in request_times if now - t < WINDOW_SECONDS]
    if len(request_times) >= REQUEST_LIMIT:
        raise HTTPException(status_code=429, detail="API rate limit exceeded. Please try again later.")
    request_times.append(now)

    # --- Extract resume text from file ---
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded.")
    filename = str(file.filename)
    _, ext = os.path.splitext(filename)
    ext = ext.lower()
    resume_text = ""
    if ext == ".pdf":
        temp_path = f"/tmp/{filename}"
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        resume_text = extract_pdf_text(temp_path)
        os.remove(temp_path)
    elif ext == ".docx":
        temp_path = f"/tmp/{filename}"
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        resume_text = extract_docx_text(temp_path)
        os.remove(temp_path)
    else:
        raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or DOCX file.")

    # --- Construct the AI Prompt ---
    prompt = PROMPT_TEMPLATE.format(
        resume=resume_text,
        job_description=job_description
    )

    # --- Call OpenAI ChatGPT API ---
    response = openai.chat.completions.create(
        model="gpt-4.1-mini",
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

# --- New Endpoint: Extract Resume Text from File (no OpenAI call) ---
@app.post("/extract_resume_text_file")
async def extract_resume_text_file(file: UploadFile = File(...)):
    print("Extracting resume text from file")
    if not file.filename:
        raise HTTPException(status_code=400, detail="No file uploaded.")
    filename = str(file.filename)
    print("Extracting resume text from file:", filename)
    _, ext = os.path.splitext(filename)
    ext = ext.lower()
    print("File extension:", ext)
    resume_text = ""
    if ext == ".pdf":
        temp_path = f"/tmp/{filename}"
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        resume_text = extract_pdf_text(temp_path)
        os.remove(temp_path)
    elif ext == ".docx":
        temp_path = f"/tmp/{filename}"
        with open(temp_path, "wb") as f:
            f.write(await file.read())
        resume_text = extract_docx_text(temp_path)
        os.remove(temp_path)
    else:
        raise HTTPException(status_code=400, detail="Unsupported file type. Please upload a PDF or DOCX file.")
    return {"resume_text": resume_text}

# --- Helper Function: Parse AI Output ---
def parse_openai_response(content: str):
    # Extract Match Score (looks for e.g. "Match Score: 85%")
    score_match = re.search(r"Match Score[:\s]*([0-9]{1,3})%", content, re.IGNORECASE)
    score = int(score_match.group(1)) if score_match else 0
    print("Score:", score)

    # Extract Concise Justification (looks for "Concise Justification: ...")
    justification_match = re.search(r"Concise Justification[:\s]*([^\n#-]+)", content, re.IGNORECASE)
    justification = justification_match.group(1).strip() if justification_match else ""

    # Extract Suggestions (numbered list, e.g. "1. ...")
    suggestions = re.findall(r"\d+\.\s*([^\n]+)", content)
    if not suggestions:
        # Fallback: try to split by newlines after "Suggestions for Improvement:"
        sugg_section = re.split(r"Suggestions for Improvement[:\s]*", content, flags=re.IGNORECASE)
        if len(sugg_section) > 1:
            suggestions = [line.strip() for line in sugg_section[1].split('\n') if line.strip()]

    return score, justification, suggestions[:5]  # Limit to 5 suggestions for UI clarity

# --- Extract resume text from a file ---
@app.post("/extract_resume_text")
def extract_resume_text(file_path: str):
    # Check if file exists
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"File not found: {file_path}")

    # Check file extension
    _, file_extension = os.path.splitext(file_path)
    if file_extension.lower() == ".pdf":
        return extract_pdf_text(file_path)

def extract_pdf_text(file_path: str):
    print("extracting pdf text")
    # Use PyPDF2 to extract text from PDF
    with open(file_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        text = ""
        for page in reader.pages:
            text += page.extract_text()
        return text

# --- DOCX Extraction Helper ---
def extract_docx_text(file_path: str) -> str:
    print("extracting docx text")
    doc = docx.Document(file_path)
    text = "\n".join([para.text for para in doc.paragraphs])
    return text