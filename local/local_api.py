from massive import RESTClient
import os
import time
from dotenv import load_dotenv
from datetime import datetime
from zoneinfo import ZoneInfo

load_dotenv()

massive_api_key = os.getenv("MASSIVE_API_KEY")
watchlists = os.getenv("WATCHLIST").split(",")
DATE = '2026-03-22'


def fetch_with_backoff(client, ticker, date, max_retries=5):
    delay = 5
    for attempt in range(max_retries):
        try:
            return client.get_daily_open_close_agg(ticker, date, adjusted=True)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            print(f"Rate limited on {ticker}, retrying in {delay}s... (attempt {attempt + 1}/{max_retries})")
            time.sleep(delay)
            delay *= 2


def main():
    client = RESTClient(api_key=massive_api_key)
    all_ticker_data = []

    for ticker in watchlists:
        try:
            response = fetch_with_backoff(client, ticker, DATE)

            open_price = response.open
            close_price = response.close
            percent_change = ((close_price - open_price) / open_price) * 100

            ticker_info = {
                "ticker": ticker,
                "date": DATE,
                "open": open_price,
                "close": close_price,
                "percent_change": round(percent_change, 2)
            }

            all_ticker_data.append(ticker_info)
            time.sleep(13)

        except Exception as e:
            print(f"Failed to fetch data for {ticker}: {e}")

    print(all_ticker_data)


main()