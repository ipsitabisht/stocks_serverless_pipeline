# Stock Movers Frontend Site

This page displays the last 7 movers of the market. 


## Environment set up

# Set up the .env file
''' VITE_API_URL = <name-of-your-api-endpoint>'''
## Install node and npm packages 
''' npm install '''

## Autodeploy changes to frontend 
Github Action workflow for updating S3 build files are integrated into this repo. At each push, any change to the frontend will be deployed automatically, updating the s3 site and invalidating the cloudfront cache