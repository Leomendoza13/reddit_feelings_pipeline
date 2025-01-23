# Reddit Public Sentiment Analysis Pipeline

This project analyzes public sentiment on Reddit posts and comments. It is designed to process data from any subject and classify the sentiment and topics discussed, enabling insights into opinions on products, personalities, and general topics. **This project is still under development.**

## Project Overview

The pipeline performs the following tasks:
1. Extracts data from a specified subject using the Reddit API in batch mode.
2. Processes posts and comments to classify sentiment (positive/negative) and identify discussion topics using NLP techniques.
3. Stores processed data into BigQuery for further analysis.

## Architecture Overview

A high-level view of the data flow:

![Reddit Data Pipeline Architecture](assets/reddit-pipeline.svg)

- **VM Instance** handles data extraction from Reddit and initial transformations.
- **Apache Spark** processes data for sentiment analysis and topic classification.
- **Google Cloud Storage** stores raw and processed data.
- **BigQuery** enables structured data analysis and querying.

## Prerequisites

- **Google Cloud Platform** with access to Storage and BigQuery services.
- **Terraform** installed on your local machine.
- **Reddit Developer Account** with access to API credentials.

## Setup Instructions

### Step 1: Clone the Repository

Clone this repository and navigate to the project directory:

```bash
git clone git@github.com:Leomendoza13/reddit_feelings_pipeline
cd reddit_sentiment_pipeline
```
