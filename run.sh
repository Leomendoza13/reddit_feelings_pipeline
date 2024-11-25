#!/bin/bash
source venv/bin/activate
python ./src/utils/reddit_sub_analyzer.py

cp config/output.json src/extraction
cp config/reddit_credentials.json src/extraction

#pip freeze > utils/extraction_function/requirements.txt
#pip install -r utils/extraction_function/requirements.txt -t utils/extraction_function/packages

cd infra/terraform/
terraform init
terraform apply
