import os
import openai
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from pydantic import BaseModel
import time
import re
import PyPDF2
from typing import Optional
import docx
import requests
from bs4 import BeautifulSoup
from fastapi.middleware.cors import CORSMiddleware
import asyncio
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Initialize FastAPI app
app = FastAPI()

# Allow CORS for local development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Set OpenAI API key from environment variable (never hardcode secrets)
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    print("WARNING: OPENAI_API_KEY environment variable is not set!")
    print("Please set it using: export OPENAI_API_KEY='your-key-here'")
    print("Or create a .env file with: OPENAI_API_KEY=your-key-here")
else:
    print("OpenAI API key loaded successfully")
openai.api_key = api_key

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
    print("Calling OpenAI API...")
    print(f"Resume length: {len(req.resume)} characters")
    print(f"Job description length: {len(req.job_description)} characters")
    
    response = openai.chat.completions.create(
        model="gpt-4o-mini",  # Fixed model name
        messages=[{"role": "user", "content": prompt}],
        max_tokens=1000,  # Increased for better responses
        temperature=0.7,
    )
    # Get the AI's response content (may be None, so default to empty string)
    content = response.choices[0].message.content or ""
    
    print("=== OPENAI RESPONSE ===")
    print(content)
    print("=== END OPENAI RESPONSE ===")

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
    print("Calling OpenAI API for file analysis...")
    print(f"Resume text length: {len(resume_text)} characters")
    print(f"Job description length: {len(job_description)} characters")
    
    response = openai.chat.completions.create(
        model="gpt-4o-mini",  # Fixed model name
        messages=[{"role": "user", "content": prompt}],
        max_tokens=1000,  # Increased for better responses
        temperature=0.7,
    )
    content = response.choices[0].message.content or ""
    
    print("=== OPENAI RESPONSE (FILE) ===")
    print(content)
    print("=== END OPENAI RESPONSE (FILE) ===")
    
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
    print("=== PARSING OPENAI RESPONSE ===")
    print(f"Content length: {len(content)} characters")
    
    # Try multiple patterns for score extraction
    score = 0
    score_patterns = [
        r"Match Score[:\s]*([0-9]{1,3})%",
        r"([0-9]{1,3})%",
        r"score[:\s]*([0-9]{1,3})",
        r"([0-9]{1,3}) out of 100",
        r"([0-9]{1,3})/100"
    ]
    
    for pattern in score_patterns:
        score_match = re.search(pattern, content, re.IGNORECASE)
        if score_match:
            score = int(score_match.group(1))
            print(f"Found score using pattern '{pattern}': {score}")
            break
    
    if score == 0:
        print("WARNING: No score found in response!")
        print("Response content:")
        print(content[:500] + "..." if len(content) > 500 else content)
    
    # Extract justification - try multiple patterns
    justification = ""
    justification_patterns = [
        r"explanation[:\s]*([^\n#-]+)",
        r"justification[:\s]*([^\n#-]+)",
        r"how the score was calculated[:\s]*([^\n#-]+)",
        r"brief explanation[:\s]*([^\n#-]+)"
    ]
    
    for pattern in justification_patterns:
        justification_match = re.search(pattern, content, re.IGNORECASE)
        if justification_match:
            justification = justification_match.group(1).strip()
            print(f"Found justification using pattern '{pattern}'")
            break
    
    # Extract suggestions - try multiple patterns
    suggestions = []
    
    # Try numbered list first
    suggestions = re.findall(r"\d+\.\s*([^\n]+)", content)
    if suggestions:
        print(f"Found {len(suggestions)} numbered suggestions")
    else:
        # Try bullet points
        suggestions = re.findall(r"[-*]\s*([^\n]+)", content)
        if suggestions:
            print(f"Found {len(suggestions)} bullet point suggestions")
        else:
            # Try after "Suggestions" section
            sugg_section = re.split(r"Suggestions[:\s]*", content, flags=re.IGNORECASE)
            if len(sugg_section) > 1:
                lines = [line.strip() for line in sugg_section[1].split('\n') if line.strip() and len(line.strip()) > 10]
                suggestions = lines[:5]
                print(f"Found {len(suggestions)} suggestions from section")
    
    print(f"Final parsed result: Score={score}, Justification length={len(justification)}, Suggestions count={len(suggestions)}")
    print("=== END PARSING ===")
    
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

class ScrapeRequest(BaseModel):
    url: str

class ScrapeResponse(BaseModel):
    job_description: str

@app.post("/scrape_job_posting", response_model=ScrapeResponse)
async def scrape_job_posting(req: ScrapeRequest):
    print("=== JOB SCRAPING STARTED ===")
    print(f"URL to scrape: {req.url}")
    
    # First try with regular requests
    job_text = await try_basic_scraping(req.url)
    
    # If basic scraping failed, try with Playwright
    if not job_text:
        print("Basic scraping failed, trying with Playwright...")
        job_text = await try_playwright_scraping(req.url)
    
    if not job_text:
        print("ERROR: No job text extracted!")
        raise HTTPException(status_code=404, detail="Could not extract job description.")

    print("=== JOB SCRAPING COMPLETED SUCCESSFULLY ===")
    return ScrapeResponse(job_description=job_text)

async def try_basic_scraping(url: str) -> str:
    """Try to scrape content using requests and BeautifulSoup"""
    try:
        print("Making HTTP request...")
        resp = requests.get(url, timeout=10)
        resp.raise_for_status()
        print(f"HTTP Status Code: {resp.status_code}")
        print(f"Response Content Length: {len(resp.text)} characters")
    except Exception as e:
        print(f"ERROR: Failed to fetch URL: {e}")
        return ""

    print("Parsing HTML with BeautifulSoup...")
    soup = BeautifulSoup(resp.text, "html.parser")
    
    # Print page title for debugging
    title = soup.find('title')
    if title:
        print(f"Page Title: {title.get_text(strip=True)}")
    else:
        print("No page title found")
    
    # Debug: Print some basic HTML structure info
    print(f"Total <div> elements: {len(soup.find_all('div'))}")
    print(f"Total <p> elements: {len(soup.find_all('p'))}")
    print(f"Total <h1>, <h2>, <h3> elements: {len(soup.find_all(['h1', 'h2', 'h3']))}")
    
    # Debug: Check what's in the single div if there's only one
    if len(soup.find_all('div')) == 1:
        div = soup.find('div')
        if div:
            div_text = div.get_text(strip=True)
            print(f"Single div text length: {len(div_text)} characters")
            if len(div_text) > 0:
                print(f"Single div content preview: {div_text[:200]}...")
            else:
                print("Single div is empty")

    # Try to extract main content heuristically
    print("Extracting text blocks from HTML elements...")
    text_blocks = []
    
    # First pass: look for longer text blocks
    for tag in soup.find_all(['h1', 'h2', 'h3', 'p', 'li']):
        txt = tag.get_text(strip=True)
        if txt and len(txt) > 20:  # Reduced minimum length
            text_blocks.append(txt)
            print(f"  Found text block ({len(txt)} chars): {txt[:100]}...")

    # If we didn't find much content, try a broader approach
    if len(text_blocks) < 3:
        print("Not enough content found, trying broader extraction...")
        # Look for any div with substantial text content
        for div in soup.find_all('div'):
            txt = div.get_text(strip=True)
            if txt and len(txt) > 50 and len(txt) < 2000:  # Reasonable length
                # Check if it looks like job content (contains keywords)
                job_keywords = ['job', 'position', 'role', 'responsibilities', 'requirements', 'qualifications', 'experience', 'skills']
                if any(keyword in txt.lower() for keyword in job_keywords):
                    text_blocks.append(txt)
                    print(f"  Found job-related div ({len(txt)} chars): {txt[:100]}...")

    # If still no content, try extracting all text from the page
    if len(text_blocks) == 0:
        print("No structured content found, extracting all page text...")
        all_text = soup.get_text(separator='\n', strip=True)
        print(f"Total page text length: {len(all_text)} characters")
        print(f"All page text: '{all_text}'")
        if len(all_text) > 100:
            print(f"First 500 chars of page text: {all_text[:500]}...")
            # Split into reasonable chunks
            lines = [line.strip() for line in all_text.split('\n') if line.strip() and len(line.strip()) > 10]
            text_blocks = lines[:20]  # Take first 20 meaningful lines
            print(f"Extracted {len(text_blocks)} text lines from page")
        else:
            print("Page appears to be a JavaScript SPA with minimal initial content")
            return ""

    print(f"Total text blocks extracted: {len(text_blocks)}")

    # Join blocks, limit length
    job_text = "\n".join(text_blocks)[:4000]  # Limit to 4000 chars
    print(f"Final job text length: {len(job_text)} characters")
    
    if len(job_text) > 100:
        print(f"First 200 chars of extracted text: {job_text[:200]}...")
        print(f"Last 200 chars of extracted text: ...{job_text[-200:]}")

    return job_text

async def try_playwright_scraping(url: str) -> str:
    """Try to scrape content using Playwright (handles JavaScript)"""
    try:
        print("Attempting Playwright scraping...")
        
        # Import playwright here to avoid import errors if not installed
        try:
            from playwright.async_api import async_playwright
        except ImportError:
            print("Playwright not installed. Install with: pip install playwright && playwright install")
            return ""
        
        async with async_playwright() as p:
            browser = await p.chromium.launch(headless=True)
            page = await browser.new_page()
            
            # Set user agent to look more like a real browser
            await page.set_extra_http_headers({
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            })
            
            print("Loading page with Playwright...")
            try:
                # Try with a shorter timeout and different wait strategy
                await page.goto(url, wait_until='domcontentloaded', timeout=15000)
                print("Page loaded, waiting for content...")
                
                # Wait for any dynamic content to load
                await page.wait_for_timeout(5000)
                
                # Try to wait for some content to appear
                try:
                    await page.wait_for_selector('body', timeout=10000)
                except:
                    print("No body selector found, continuing anyway...")
                    
            except Exception as e:
                print(f"Page load timeout or error: {e}")
                # Try to get whatever content is available
                pass
            
            print("Extracting content from rendered page...")
            content = await page.content()
            soup = BeautifulSoup(content, "html.parser")
            
            # Debug: Check what we got
            print(f"Playwright HTML content length: {len(content)} characters")
            print(f"Playwright page title: {await page.title()}")
            
            # Extract text content
            all_text = soup.get_text(separator='\n', strip=True)
            print(f"Playwright extracted text length: {len(all_text)} characters")
            
            if len(all_text) > 100:
                print(f"First 500 chars of Playwright text: {all_text[:500]}...")
                
                # Split into meaningful lines
                lines = [line.strip() for line in all_text.split('\n') if line.strip() and len(line.strip()) > 10]
                text_blocks = lines[:30]  # Take first 30 meaningful lines
                
                job_text = "\n".join(text_blocks)[:4000]  # Limit to 4000 chars
                print(f"Playwright final job text length: {len(job_text)} characters")
                
                await browser.close()
                return job_text
            else:
                print("Playwright also found minimal content")
                await browser.close()
                return ""
                
    except Exception as e:
        print(f"Playwright scraping failed: {e}")
        return ""