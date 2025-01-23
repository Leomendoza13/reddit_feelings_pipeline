# Reddit Public Sentiment Analysis Pipeline

This project analyzes public sentiment on Reddit posts and comments. It is designed to process data from any subject and classify the sentiment and topics discussed, enabling insights into opinions on products, personalities, and general topics. **⚠️This project is still under development.⚠️**

## Project Overview

The pipeline performs the following tasks:
1. Extracts data from a specified subject using the Reddit API in batch mode.
2. Processes posts and comments to classify sentiment (positive/negative) and identify discussion topics using NLP techniques.
3. Stores processed data into BigQuery for further analysis.

## Architecture Overview

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

### Step 2: Create your new project on Google Cloud Platform Console

1. Create a [Google Cloud Platform Account](https://console.cloud.google.com/) if you haven’t already. New users get a free 3-month trial.

2. Go to your [console](https://console.cloud.google.com/) and create a new project using the "Create Project" button.

3. Go to **Compute Engine** tab and enable **Compute Engine API**. Repeat this for **BigQuery API** to enable both services.

### Step 3: Configure GCloud CLI

1. Install [gcloud CLI](https://cloud.google.com/sdk/docs/install) if it’s not already installed.

2. Connect to your Google Cloud account and authenticate:

```bash
gcloud auth application-default login
```

This will generate a URL in your CLI, click on it, and log in to your Google Cloud account.

3. Set the project ID:

```bash
gcloud config set project [PROJECT_ID]
```

### Step 4: Configure Reddit API

1. Create a Reddit Developer Account and register your app to obtain API credentials.
2. Replace the placeholders in `config/reddit_credentials.json` with your credentials:
   ```json
   {
       "client_id": "your_client_id",
       "client_secret": "your_client_secret",
       "user_agent": "your_user_agent"
   }
   ```

### Step 5: Configure Terraform Variables

1. Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/install-cli) if it’s not already installed.

2. Create a `terraform.tfvars` file based on `example.tfvars`:

```bash
cp terraform/example.tfvars terraform/terraform.tfvars
```

3. Edit `terraform/terraform.tfvars` to add your specific values:

```
project_id       = "your-project-id"  
ssh_user         = "your-ssh-username"  
ssh_pub_key_path = "~/.ssh/id_rsa.pub"  
source_folder    = "../dags/"  
ids_path         = "../config/"
```

### Step 6: Deploy the Infrastructure

Navigate to the root project folder, initialize Terraform with the script:

```bash
./scripts/run.sh
```

Confirm the resources to be deployed. This command will set up:

- A VM instance for data extraction and processing.
- A Spark master VM instance.
- Two Spark worker VM instances.
- A Cloud Storage bucket for data storage.
- BigQuery tables for storing and analyzing Reddit data.

### Step 7: Actions After `terraform apply`

### **Step 8: ⚠️ DON'T FORGET TO `terraform destroy` WHEN IT IS DONE ⚠️**

```bash
./scripts/destroy.sh
```

Running `terraform destroy` is essential after you’re done to prevent unnecessary costs. Google Cloud resources like Compute Engine instances and BigQuery storage incur charges as long as they’re active. By running `terraform destroy`, you ensure that all deployed resources are deleted, helping to avoid unexpected expenses.

### Usage

### Contributing

Contributions to this project are welcome! By submitting a pull request, contributors agree to license their work under the same MIT License.

### License

This project is licensed under the MIT License. See the LICENSE file for more details.

### Author

This project was created and developed by me :) **Léo Mendoza**.

Feel free to reach out for questions, contributions, or feedback at [leo.mendoza@epita.com](mailto:leo.mendoza@epita.com).


