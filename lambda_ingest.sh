#!/bin/bash
aws lambda invoke --function-name ingest_lambda --payload '{}' --cli-read-timeout 300 response.json