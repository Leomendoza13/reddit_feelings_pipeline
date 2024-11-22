#!/bin/bash
source venv/bin/activate
python ./utils/reddit_sub_analyzer.py

cp config/output.json utils/extraction
cp config/reddit_credentials.json utils/extraction

#pip freeze > utils/extraction_function/requirements.txt
#pip install -r utils/extraction_function/requirements.txt -t utils/extraction_function/packages

cd terraform/
terraform init
terraform apply
