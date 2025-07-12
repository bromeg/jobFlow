# Enhanced Company Research Functionality

This document describes the enhanced company research features added to the JobFlow backend.

## Overview

The enhanced company research functionality goes beyond analyzing job descriptions. It now researches companies from external sources including their official websites, LinkedIn pages, news articles, and other public sources to provide comprehensive and accurate company information.

## Key Improvements

1. **External Research**: AI researches companies from multiple external sources
2. **Company Name Extraction**: Automatically extracts company names from job descriptions
3. **Real-time Data**: Provides current information from public sources
4. **Comprehensive Analysis**: Covers all aspects of company information

## New Endpoints

### 1. `/research_company` (POST)

Researches a company from external sources based on the job description.

**Request Body:**
```json
{
  "job_description": "Job description text..."
}
```

**Response:**
```json
{
  "company_overview": "Comprehensive company information including founding year, headquarters, and size",
  "market_customers": "Detailed target customers and market analysis",
  "key_products": "Specific product names and technologies offered",
  "culture_values": "Work culture, values, mission, and benefits information",
  "industry_competition": "Industry analysis and main competitors",
  "growth_opportunities": "Growth stage, funding status, and recent developments",
  "additional_insights": "Recent news, awards, partnerships, and achievements"
}
```

### 2. `/scrape_and_research` (POST)

Combines job scraping and enhanced company research in a single call.

**Request Body:**
```json
{
  "url": "https://job-posting-url.com"
}
```

**Response:**
```json
{
  "job_description": "Extracted job description text",
  "company_info": {
    "company_overview": "...",
    "market_customers": "...",
    "key_products": "...",
    "culture_values": "...",
    "industry_competition": "...",
    "growth_opportunities": "...",
    "additional_insights": "..."
  }
}
```

## Research Sources

The AI researches companies from multiple external sources:

- **Official Company Website**: About pages, company information, products/services
- **LinkedIn Company Page**: Company overview, employee information, recent updates
- **Crunchbase/Business Databases**: Funding information, company details, market data
- **Recent News Articles**: Latest developments, partnerships, acquisitions
- **Company Social Media**: Brand messaging, culture insights, recent announcements
- **Press Releases**: Official company announcements and updates

## Information Extracted

The enhanced research provides comprehensive insights on:

1. **Company Overview**: 
   - What the company does and their business model
   - Founding year and headquarters location
   - Company size and employee count
   - Value proposition and market position

2. **Market & Customers**: 
   - Target customer segments and geographic markets
   - B2B/B2C focus and industry verticals
   - Customer base size and characteristics

3. **Key Product Areas**: 
   - Specific product names and features
   - Technology stack and solutions offered
   - Product categories and market segments

4. **Company Culture & Values**: 
   - Stated mission and values
   - Work environment and benefits
   - Company philosophy and employee policies

5. **Industry & Competition**: 
   - Industry sector and market position
   - Main competitors and competitive advantages
   - Market share and industry trends

6. **Growth & Opportunities**: 
   - Growth stage and funding status
   - Recent funding rounds or acquisitions
   - Expansion plans and market opportunities

7. **Additional Insights**: 
   - Recent news and developments
   - Awards and recognition
   - Partnerships and notable achievements

## Company Name Extraction

The system automatically extracts company names from job descriptions using AI, looking for patterns like:
- "at [Company Name]"
- "[Company Name] is hiring"
- "Join [Company Name]"
- "[Company Name] - [Job Title]"
- Company names in "About" sections

## Usage Examples

### Python Example
```python
import requests

# Enhanced company research from job description
response = requests.post("http://localhost:8000/research_company", 
                        json={"job_description": "Senior Engineer at Google..."})
company_info = response.json()

# Scrape and research in one call
response = requests.post("http://localhost:8000/scrape_and_research",
                        json={"url": "https://job-posting-url.com"})
result = response.json()
job_desc = result["job_description"]
company_info = result["company_info"]
```

### cURL Example
```bash
# Enhanced company research
curl -X POST "http://localhost:8000/research_company" \
     -H "Content-Type: application/json" \
     -d '{"job_description": "Senior Engineer at Microsoft..."}'

# Scrape and research
curl -X POST "http://localhost:8000/scrape_and_research" \
     -H "Content-Type: application/json" \
     -d '{"url": "https://job-posting-url.com"}'
```

## Testing

Run the enhanced test script to verify functionality:
```bash
python test_company_research.py
```

## Rate Limiting

The company research endpoints are subject to the same rate limiting as other endpoints:
- 20 requests per hour
- Requests are tracked globally across all endpoints

## Error Handling

- **400 Bad Request**: Invalid input data
- **404 Not Found**: Could not extract job description from URL
- **429 Too Many Requests**: Rate limit exceeded

## Technical Details

- Uses GPT-4o-mini model for both company name extraction and research
- AI-powered external research from multiple sources
- Structured response parsing with fallback mechanisms
- Integrates with existing job scraping functionality
- Follows the same rate limiting and error handling patterns as other endpoints
- Increased token limits for comprehensive research (2000 tokens)

## Benefits

1. **More Accurate Information**: Real-time data from official sources
2. **Comprehensive Coverage**: Information beyond what's in job descriptions
3. **Current Data**: Up-to-date company information and recent developments
4. **Better Decision Making**: Job seekers get complete company context
5. **Professional Research**: AI conducts thorough research like a business analyst 