# Stock Mover App
The Stock Mover App displays the top moving tickers of the week (by % change) according to open/close dates. 

## Architecture Overview 
This project was created using a variety of AWS Resources and frontend technologies, all deployed using Terraform and Github Actions 

### System Flow
- EventBridge Scheduler: Triggers ingestion Lambda (daily)
- Ingestion Lambda: 
    - Fetches stock data from Massive API
    - Computes % change for each ticker
    - Stores the top mover in DynamoDB
- DynamoDB: Stores one record per day
- Retrieval Lambda: Reads last 7 records from DynamoDB
- API Gateway: Exposes GET /movers
- Frontend (React + Vite): Calls API and renders results
- S3 + CloudFront: Hosts frontend with HTTPS
- GitHub Actions: Automatically deploys frontend on commit
### Frontend 
- React
- Vite 
- Hosted on S3 + CloudFront

### Backend 
- AWS Lambda (ingestion + retrieval)
- EventBridge Scheduler (automation)
- API Gateway V2 (HTTP API)
- DynamoDB (Storage)

### Infrastructure
- AWS serverless services
- Terraform (IaC)
- Github Action (CI/CD for frontend) 

### API ```GET/movers```
Retrieves an array of ticker objects, ordered by date (descending)
```
{
  "items": [
    {
      "date": "2026-03-20",
      "ticker": "TSLA",
      "percent_change": -3.13,
      "closing_price": 367.96
    },
    {
      "date": "2026-03-19",
      "ticker": "NVDA",
      "percent_change": 2.11,
      "closing_price": 170.80
    },
    ...
  ]
}
```
## Environment set up
1. Create a Massive account and generate an API key
2. Create a ```terraform.tfvars``` file under ```infra/``` and add the following information:
```
massive_api_key="<your-api-key>"
stock_mover_bucket_name="<your-bucket-name>"
github_owner = "<your-github-username>"
github_repo = "<your-github-repo-name>"
```
3. In the frontend if you want to test changes locally with the api, create a ```.env``` file with your vite api url:
```
VITE_API_URL=https://<your-aws-api-id>.execute-api.<your-aws-region>.amazonaws.com/movers
```
## How to Deploy
### Create an IAM user with the following policies/access:
1. IAM Roles
2. Lambda 
3. EventBridge Scheduler
4. API Gateway V2 
5. DynamoDB 
6. CloudWatch Logs
7. CloudFront
8. S3
- As of now, you can be permissive with these resources if you are setting up for personal use. However it is best to use the least-priviledged policy when assigning the user its permissions.

### Set up lambda packages and dependencies 
1. In the root directory, execute ``` sh build.sh``` to create dependency packages for Lambda functions
- This should create 2 folders called ```lambda_packages``` and  ```build``` which will be zipped into your Lambda execution environment.
### Terraform Resource Deployment and Creation
1. Next, cd into the ```infra/``` directory and execute ```terraform init``` then ```terraform apply```
2. Your infrastructure should be set up and ready to use! 

## Quick Set Up
```
# 1. Clone repo
git clone <repo-url>
cd stock-mover-app

# 2. Set up secrets
cp terraform.tfvars.example terraform.tfvars
# fill in values

# 3. Build lambda packages 
sh build.sh

# 4. Deploy infrastructure
cd infra
terraform init
terraform apply

# 5. Run frontend locally
cd frontend
npm install
npm run dev
```
## CI/CD For Frontend Deployment
- Trigger with Git Push
- Steps 
  - Builds Vite App
  - Uploads build files to S3 bucket
  - Invaliates CloudFront cache to allow updates to persist
- This workflow allows for a smoother frontend development experience, eliminating manual deploys and speeds up iterative development

## Frontend Hosting
Access the page here!: https://d3kikyfo6yfcer.cloudfront.net/

## Challenges and Tradeoffs
1. Working with Massive API
- One of the challenges that I came across was the timing of using the Massive API. Within the free-tier, Massive only allows requests to go through at the end of the day. So in order to test with the endpoint, I had to use the previous day's date in order to build out the lambda function and test manually. This also impacted scheduling with EventBridge Scheduler, as I would test the lambda trigger only after a certain time (8 or 9pm).
  - **Tradeoff:** having to wait for the data to be available and stay within the free plan. 
- Rate Limits: The API only allows 5 requests per minute so timing each of the 6 ticker's API requests required time intervals between each call in order to work around that.
  - **Tradeoff:** data retrieval is slower but more reliable. 

2. Cloud deployments
- Setting up the resources using Terraform required learning how to translate processes/set up into modular documents. This was my introduction to using Terraform to provision and manage AWS resources so there was a slight learning curve in understanding how to format the files however the ease of creating and updating the resources all within the CLI was valuable. 
  - **Tradeoff:** the initial setup took time to figure out compared to manual configuration, but in return I gained a repeatable process that makes the infrastructure easy to reproduce and maintain as a developer.

3. Setting up Automatic Deployments for Frontend hosted on S3
- When setting up the the frontend, it was convenient seeing the updates on local host. However when it came to deploying and dumping all the build files into S3, that is where the process became clunky and manual. After each update, if I wanted my S3 hosted site to display the changes made locally, I would need to rebuild using ```npm run dev``` then use the AWS CLI to dump the ```dist/``` file content into the S3 bucket and after incorporating CloudFront Distribution to the workflow, I needed to also clear its cache through CLI. This is not the best developer experience for making a small update on the frontend. Thus, I looked into using Github Action workflows to see how I can automate this process for any change done in the frontend folder. The challenge was in understanding how to hook up everything and ensuring the right accesses are given but after that the set up and process initialization was smooth. 
  - **Tradeoff:** setting up CI/CD required extra upfront effort and access configuration, but it made future deployments faster and more reliable.

## Future Improvements
- Full CI/CD pipeline
    - Run integration, unit, and end-2-end tests at each push
    - Package Lambda functions automatically 
    - Validate Terraform formatting and configuration
- Testing
Currently the tests for lambda ingestion + retrieval are done with shell scripts 
  - Unit
  - Integration
  - End-2-end tests
- Data Visualizations
Current visuals only use the data from the stock winners. An improvement would be incorporating more data for a comprehensive overview.
    - Incorporate more data from each ticker to show weekly summaries 
    - AI Summary for per-ticker performance 
    - Forecasting for stock perforamnce
- API improvements
    - Pagination
    - Retrieve based on any date interval instead of restricting to last 7 days
