# Personal Job Application Tracker

## Purpose
JobFlow is a job application tracking and personal career management tool. It is designed to intelligently manage and optimize the job search experience by connecting with the user’s email, providing tailored resume recommendations, and integrating budgeting tools to support life planning around career transitions.

## Problem Statement
Managing job applications across multiple platforms and tailoring resumes for each opportunity is time-consuming, disorganized, and stressful. Users need a centralized system that automates status tracking, intelligently evaluates fit, and supports financial planning.

## Target User
- Job seekers applying to mid-to-senior level roles
- Users who want to increase resume alignment with job postings
- Users with existing resumes but seeking tailored versions 

## Goals
- Automatically track and update job application statuses via email parsing
- Evaluate resume fit based on job descriptions
- Help users tailor and generate ATS-optimized resumes
- Offer centralized notes, scoring, and comparison tools
- Provide interview tracking and salary visibility
- Support basic financial planning through a dual-salary budgeting tool (based on potential salaries/offers)

## User Stories
- As a job seeker, I want to connect my inbox so that application statuses update automatically. (Coming soon)
- As a job seeker, I want to evaluate how well my resume fits a job description so I can focus on high-fit roles. (Coming soon)
- As a job seeker, I want to generate tailored resumes that will perform better with ATS. (Coming soon)
- As a job seeker, I want to keep notes on each application so I can remember key details.
- As a job seeker, I want to rate my interest in each job so I can prioritize where to follow up.
- As a job seeker, I want to track each stage of the interview process so I never lose track of a role.
- As a job seeker, I want to compare my job options easily.
- As a job seeker, I want to see salary info so I can assess compensation expectations.
- As a person planning my life, I want to input two potential incomes and estimate monthly budget flexibility. (Coming soon)

## Core Functionality & Requirements
### AI Resume Optimization
#### 1. Upload Resume 
- FR1.1: Users must be able to upload a .pdf or .docx resume
- FR1.2: System parses and stores content for editing and tailoring 

#### 2. Paste Job Description 
- FR2.1: Users can paste a full job description into a large text input field
- FR2.2: System parses content for role title, responsibilities, and key skills 

#### 3. Paste Job Link 
- FR3.1: Users can paste a URL linking to a job post
- FR3.2: System scrapes the page and extracts job title, description, and employer info 

#### 4. Company Research (via AI API) 
- FR4.1: When a link is pasted, system queries a company info API (or uses web scraping + LLM summarization)
- FR4.2: Return a short company overview (what it does, size, industry)
- FR4.3: Summarize values/mission from the About or Careers page if available 

#### 5. Glassdoor Summary 
- FR5.1: Use Glassdoor API or web search to find reviews
- FR5.2: Generate a short summary of employee sentiment (pros, cons, average rating, culture notes) 

#### 6. AI Clarification Chat 
- FR6.1: AI asks follow-up questions to fill in missing details (e.g., “Do you have experience with Agile methodology?”)
- FR6.2: User can interact in chat form and responses are stored in context
- FR6.3: Clarified responses can be appended to experience bullets 

#### 7. ATS-Optimized Resume Generation 
- FR7.1: System uses NLP/LLM to tailor the uploaded resume to the job description
- FR7.2: Includes matching keywords, skills, and phrasing common in job listings
- FR7.3: System preserves formatting that is ATS-compatible (e.g., no text boxes, no images) 

#### 8. Match Score Generation 
- FR8.1: Display a match score as a percentage (0–100%)
- FR8.2: Break down by:
  -   Technical Skills Match
  -   Experience Level
  -   Keywords Match 

#### 9. Match Score Explanation 
- FR9.1: Display a brief summary explaining how the score was calculated 
- FR9.2: Highlight areas where the resume aligned or fell short 

#### 10. Suggestions for Improvement 
- FR10.1: Provide a list of 3–5 actionable suggestions to improve the score
  - Example: “Add ‘Agile methodology’ to experience section” 

#### 11. Change Summary 
- FR11.1: After resume generation, show a comparison summary
- FR11.2: Highlight what sections were changed, added, or removed and why  

#### 12. Downloadable ATS-Optimized .docx 
- FR12.1: System must allow user to download the final tailored resume as a .docx file
- FR12.2: Document must retain clean, professional formatting compatible with common ATS software
- FR12.3: Optionally allow PDF download too 


