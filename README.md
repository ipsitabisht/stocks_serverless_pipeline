# Stock Mover App

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
Example Response
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
      "closing_price": 270.80
    },
    ...
  ]
}
```

## Environment set up
1. Create a Massive account and generate an API key
2. Create a ```terraform.tfvars``` file and add the following information:
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
- As of now, you can be permissive with these resources however if you have a larger team with clear rules and access permissions, use the least-priviledged policy when assigning the user. 
### Set up lambda packages and dependencies 
1. In the root directory execute ``` sh build.sh``` to create dependency packages for Lambda functions
- This should create a directory called ```lambda_packages``` which will be zipped into your Lambda execution environment along with all the lambda functions under ```backend/```
### Terraform Resource Deployment and Creation
1. Next, cd into the ```infra/``` directory and execute ```terraform init``` then ```terraform apply```
2. Your infrastructure should be set up and ready to use! 


## Frontend Hosting

Access the page here!: https://d3kikyfo6yfcer.cloudfront.net/

## Challenges and Tradeoffs
1. Working with Massive API
- One of the challenges that I came across was the timing of using the Massive API. Within the free-tier, Massive only allows requests to go through at the end of the day. So in order to test with the endpoint, I had to use the previous day's date in order to build out the lambda function and test manually. This also impacted scheduling with EventBridge Scheduler, as I would test the lambda trigger only after a certain time (8pm)
- Rate Limits: The API only allows 5 requests per minute so timing each of the 6 ticker's API requests required time intervals between each call in order to work around that. The tradeoff here is that retrieving all 6 tickers takes more than a minute, but, in turn, we work around the rate limitation 

2. Cloud deployments
- Setting up the resources using Terraform required learning how to translate processes/set up into modular documents. This was my introduction to using Terraform to provision and manage AWS resources so there was a slight learning curve in understanding how to format the files however the ease of creating and updating the resources all within the CLI was valuable. 

3. Setting up Automatic Deployments for Frontend hosted on S3
- When setting up the the frontend, it was convenient seeing the updates on local host. However when it came to deploying and dumping all the build files into S3, that is where the process became clunky and manual. After each update, if I wanted my S3 hosted site to display the changes made locally, I would need to rebuild using ```npm run dev``` then use the AWS CLI to dump the ```dist/``` file content into the S3 bucket and after incorporating CloudFront Distribution to the workflow, I needed to also clear its cache through CLI. This is not the best developer experience for making a small update on the frontend. Thus, I looked into using Github Action workflows to see how i can automatically do this whole process in one go after creating a change in the repo. The challenge was in understanding how to hook up everything and ensuring the right accesses are given but after that the set up and process initialization was smooth. 

