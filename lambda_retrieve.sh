#!/bin/bash
aws lambda invoke --function-name retrieve_week_lambda --payload '{}' --cli-read-timeout 300 response.json