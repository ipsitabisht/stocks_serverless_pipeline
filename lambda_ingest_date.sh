aws lambda invoke --function-name ingest_lambda --cli-binary-format raw-in-base64-out --payload '{"date": "2026-03-19"}' --cli-read-timeout 300 response.json
