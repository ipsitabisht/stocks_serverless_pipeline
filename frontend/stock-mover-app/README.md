# Stock Movers Frontend Site

This page displays the last 7 movers of the market. 

## Install node and npm packages 
```npm install```
## Run locally
``` npm run dev ```

## Autodeploy changes to frontend 
Github Action workflow for updating S3 build files are integrated into this repo. At each push, any change to the frontend will be deployed automatically, updating the s3 site and invalidating the cloudfront cache