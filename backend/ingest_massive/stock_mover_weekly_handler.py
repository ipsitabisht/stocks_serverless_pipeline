import os
import time
import boto3
import json
import requests
from decimal import Decimal
from datetime import datetime, timedelta
from zoneinfo import ZoneInfo

# Resources
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

# Environment variables
API_KEY = os.environ["MASSIVE_API_KEY"]
WATCHLIST = os.environ["WATCHLIST"].split(",")

MASSIVE_BASE_URL = "https://api.massive.com/v1/open-close"


def get_last_7_trading_days():
    """Return the last 7 weekdays (Mon-Fri) as YYYY-MM-DD strings, most recent first."""
    now_et = datetime.now(ZoneInfo("America/New_York"))
    candidate = now_et.date()

    # Don't include today if market hasn't closed yet
    if now_et.hour < 20:
        candidate = candidate - timedelta(days=1)

    trading_days = []
    while len(trading_days) < 7:
        if candidate.weekday() < 5:  # Mon-Fri
            trading_days.append(candidate.strftime("%Y-%m-%d"))
        candidate -= timedelta(days=1)

    return trading_days

"""
Retry logic for Massive API requests.
Args:
    ticker: Ticker to fetch data for
    date: Date to fetch data for
    max_retries: Maximum retries
Returns:
    Response JSON dict
"""
def fetch_with_backoff(ticker, date, max_retries=5):
    url = f"{MASSIVE_BASE_URL}/{ticker}/{date}"
    params = {"adjusted": "true", "apiKey": API_KEY}
    delay = 15

    for attempt in range(max_retries):
        response = requests.get(url, params=params, timeout=30)

        if response.status_code == 200:
            return response.json()

        # retry failures
        if response.status_code in {429, 500, 502, 503, 504}:
            if attempt == max_retries - 1:
                response.raise_for_status()
            time.sleep(delay)
            delay *= 2
            continue

        # fail fast on 403 failures
        raise Exception(
            f"Massive request failed for ticker={ticker}, date={date}, "
            f"status={response.status_code}, body={response.text[:200]}"
        )

"""
Lambda handler for the weekly stock mover detector.
Fetches the last 7 trading days (Mon-Fri only) for each ticker in the watchlist
and writes the biggest daily mover per day to DynamoDB. Weekend dates are skipped
since the market is closed.

Args:
    event: Event object (unused — dates are derived automatically)
    context: Context object
"""
def lambda_handler(event, context):
    trading_days = get_last_7_trading_days()
    print({"resolved_trading_days": trading_days})

    results = []

    for date in trading_days:
        all_ticker_data = []

        for ticker in WATCHLIST:
            try:
                response = fetch_with_backoff(ticker, date)
                open_price = response["open"]
                close_price = response["close"]
                percent_change = ((close_price - open_price) / open_price) * 100
                all_ticker_data.append({
                    "ticker": ticker,
                    "date": date,
                    "open": Decimal(str(open_price)),
                    "close": Decimal(str(close_price)),
                    "percent_change": Decimal(str(round(percent_change, 2))),
                })
            except Exception as e:
                print(f"Massive request failed for ticker={ticker}, date={date}, error={str(e)[:300]}")
                continue

            time.sleep(13)

        if not all_ticker_data:
            print(f"No ticker data retrieved for date={date}, skipping")
            continue

        winner = max(all_ticker_data, key=lambda x: abs(x["percent_change"]))

        item = {
            "date": winner["date"],
            "ticker": winner["ticker"],
            "percent_change": winner["percent_change"],
            "closing_price": winner["close"],
        }

        print(f"Winner for {date}: {item}")
        print(json.dumps({
            "date": date,
            "all_ticker_data": [
                {
                    "ticker": row["ticker"],
                    "open": float(row["open"]),
                    "close": float(row["close"]),
                    "percent_change": float(row["percent_change"]),
                }
                for row in all_ticker_data
            ]
        }))

        table.put_item(Item=item)
        results.append({
            "date": item["date"],
            "ticker": item["ticker"],
            "percent_change": float(item["percent_change"]),
            "closing_price": float(item["closing_price"]),
        })

    return {
        "statusCode": 200,
        "body": json.dumps(results)
    }
