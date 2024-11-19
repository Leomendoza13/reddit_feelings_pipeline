#!/bin/bash
source venv/bin/activate
python ./utils/reddit_sub_analyzer.py

cp config/output.json utils/extraction_function
cp config/reddit_credentials.json utils/extraction_function
cp requirements.txt utils/extraction_function

cd terraform/
terraform init
terraform apply
