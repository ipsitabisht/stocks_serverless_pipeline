import os
import time
import boto3
import json
from decimal import Decimal

# Resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def to_json_safe(item):
    return {
        "date": item["date"],
        "ticker": item["ticker"],
        "percent_change": float(item["percent_change"]),
        "closing_price": float(item["closing_price"]),
    }

def lambda_handler(event, context):
    # read from dynamo
    response = table.scan()
    items = response.get('Items', [])
    # order by dates (recent-oldest)
    items.sort(key=lambda x: x["date"], reverse=True)
    latest = items[:7]
    print("Items from the last couple days: ", items)
    # return as the response 
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "items": [to_json_safe(item) for item in latest]
        })
    }
