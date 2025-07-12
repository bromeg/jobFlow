#!/usr/bin/env python3
"""
Test script for the enhanced company research functionality
"""

import requests
import json

# Test job description with a well-known company
SAMPLE_JOB_DESCRIPTION = """
Senior Software Engineer at Microsoft

About Microsoft:
Microsoft Corporation is an American multinational technology company with headquarters in Redmond, Washington. We develop, manufacture, license, support, and sell computer software, consumer electronics, personal computers, and related services.

We're looking for a senior engineer with:
- 5+ years experience in C#, .NET, and Azure
- Experience with cloud computing and distributed systems
- Knowledge of software development best practices
- Passion for building innovative solutions

Join our mission to empower every person and every organization on the planet to achieve more.
"""

def test_enhanced_company_research():
    """Test the enhanced company research endpoint"""
    print("=== Testing Enhanced Company Research Endpoint ===")
    print("This will now research the company from external sources, not just the job description!")
    
    url = "http://localhost:8000/research_company"
    data = {"job_description": SAMPLE_JOB_DESCRIPTION}
    
    try:
        response = requests.post(url, json=data)
        response.raise_for_status()
        
        result = response.json()
        
        print("\n=== ENHANCED COMPANY RESEARCH RESULTS ===")
        print("Note: This information is now researched from external sources!")
        print(f"\nCompany Overview: {result['company_overview']}")
        print(f"\nMarket & Customers: {result['market_customers']}")
        print(f"\nKey Products: {result['key_products']}")
        print(f"\nCulture & Values: {result['culture_values']}")
        print(f"\nIndustry & Competition: {result['industry_competition']}")
        print(f"\nGrowth & Opportunities: {result['growth_opportunities']}")
        print(f"\nAdditional Insights: {result['additional_insights']}")
        
    except requests.exceptions.RequestException as e:
        print(f"Error testing enhanced company research: {e}")

def test_company_name_extraction():
    """Test company name extraction from various job description formats"""
    print("\n=== Testing Company Name Extraction ===")
    
    test_cases = [
        "Senior Developer at Apple - Join our team in Cupertino",
        "Google is hiring a Software Engineer in Mountain View",
        "Join Tesla as a Full Stack Developer",
        "Amazon - Senior Solutions Architect position available",
        "Netflix seeks a talented engineer to join our streaming team"
    ]
    
    url = "http://localhost:8000/research_company"
    
    for i, job_desc in enumerate(test_cases, 1):
        print(f"\nTest Case {i}: {job_desc}")
        try:
            response = requests.post(url, json={"job_description": job_desc})
            if response.status_code == 200:
                print("✓ Company research completed successfully")
            else:
                print(f"✗ Error: {response.status_code}")
        except Exception as e:
            print(f"✗ Error: {e}")

def test_scrape_and_research():
    """Test the combined scrape and research endpoint"""
    print("\n=== Testing Scrape and Research Endpoint ===")
    print("This will scrape a job posting and then research the company from external sources")
    
    # Using a real job posting URL (LinkedIn example)
    url = "http://localhost:8000/scrape_and_research"
    data = {"url": "https://www.linkedin.com/jobs/view/software-engineer-at-google-123456789"}
    
    try:
        response = requests.post(url, json=data)
        response.raise_for_status()
        
        result = response.json()
        
        print(f"\nJob Description Length: {len(result['job_description'])} characters")
        print(f"Company Info Sections: {len([v for v in result['company_info'].values() if v])}")
        
        if result['company_info']['company_overview']:
            print(f"\nCompany Overview: {result['company_info']['company_overview'][:300]}...")
        
    except requests.exceptions.RequestException as e:
        print(f"Error testing scrape and research: {e}")

if __name__ == "__main__":
    print("Starting enhanced company research tests...")
    print("Make sure the backend server is running on http://localhost:8000")
    print("\n" + "="*60)
    print("NEW: Company research now uses external sources!")
    print("The AI will research companies from their websites,")
    print("LinkedIn, news articles, and other public sources.")
    print("="*60)
    
    test_enhanced_company_research()
    test_company_name_extraction()
    test_scrape_and_research()
    
    print("\n=== Enhanced Tests completed ===")
    print("\nKey improvements:")
    print("1. Company name extraction from job descriptions")
    print("2. External research from company websites and sources")
    print("3. More comprehensive and accurate company information")
    print("4. Real-time data from public sources") 