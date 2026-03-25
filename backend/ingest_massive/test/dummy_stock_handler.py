import os
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

def lambda_handler(event, context):
    item = {
        "date": "2026-03-20",
        "ticker": "AAPL",
        "percent_change": "2.30",
        "closing_price": "247.99"
    }

    table.put_item(Item=item)

    return {
        "statusCode": 200,
        "body": "Inserted test item"
    }