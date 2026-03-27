import os
import time
import boto3
import json
from decimal import Decimal
from botocore.exceptions import ClientError

# Resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

RETRYABLE_ERRORS = {
    "ProvisionedThroughputExceededException",
    "RequestLimitExceeded",
    "InternalServerError",
    "ServiceUnavailable",
}

def to_json_safe(item):
    return {
        "date": item["date"],
        "ticker": item["ticker"],
        "percent_change": float(item["percent_change"]),
        "closing_price": float(item["closing_price"]),
    }

"""
If the DynamoDB scan fails, attempt 3 retries before raising an error
"""
def scan_with_retry(max_retries=3):
    delay = 1
    for attempt in range(max_retries):
        try:
            return table.scan()
        except ClientError as e:
            error_code = e.response["Error"]["Code"]
            if error_code in RETRYABLE_ERRORS and attempt < max_retries - 1:
                print(f"DynamoDB scan failed with {error_code}, retrying in {delay}s (attempt {attempt + 1}/{max_retries})")
                time.sleep(delay)
                delay *= 2
            else:
                raise

"""
Scan the Stock Mover Table, retrieve and filter to get the last 7 items, order them by recency
Return the array of latest 7 items
"""
def lambda_handler(event, context):
    response = scan_with_retry()
    items = response.get('Items', [])
    # order by dates (recent-oldest)
    items.sort(key=lambda x: x["date"], reverse=True)
    latest = items[:7]
    print("Items from the last couple days: ", items)
    return {
        "statusCode": 200,
        "meta": {
            "source": "DynamoDB",
            "sort_order": "date_desc"
        },
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Content-Type": "application/json",
            "Cache-Control": "public, max-age=300",
            "X-Data-Source": "DynamoDB"
        },
        "body": json.dumps({
            "items": [to_json_safe(item) for item in latest]
        })
    }
