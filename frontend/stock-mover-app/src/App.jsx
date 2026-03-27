import React, { useEffect, useState } from "react";
import "./App.css";

const API_URL = import.meta.env.VITE_API_URL;

function getTodayDataStatus() {
  const now = new Date();
  const pstTime = new Date(now.toLocaleString("en-US", { timeZone: "America/Los_Angeles" }));
  const hour = pstTime.getHours();
  const day = pstTime.getDay(); // 0=Sun, 6=Sat

  const isWeekend = day === 0 || day === 6;
  const isAfterClose = hour >= 22;

  if (isWeekend) {
    return { available: false, message: "Markets are closed on weekends. Showing last available trading day." };
  }
  if (!isAfterClose) {
    return { available: false, message: `Today's data is not yet available. Updates after 9 PM PST (currently ${hour}:${String(pstTime.getMinutes()).padStart(2, "0")} PM PST).` };
  }
  return { available: true, message: "Today's data is available." };
}

export default function App() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const dataStatus = getTodayDataStatus();

  useEffect(() => {
    async function fetchMovers() {
      try {
        setLoading(true);
        setError("");

        const response = await fetch(API_URL);

        if (!response.ok) {
          throw new Error(`Request failed with status ${response.status}`);
        }

        const data = await response.json();
        setItems(data.items || []);
      } catch (err) {
        setError(err.message || "Something went wrong while loading data.");
      } finally {
        setLoading(false);
      }
    }

    fetchMovers();
  }, []);

  return (
    <div className="page">
      <div className="card">
        <h1 className="title">This Week's Stock Movers:</h1>
        <p className="subtitle">Last 7 Day Winners</p>

        <div className={`status-banner ${dataStatus.available ? "status-available" : "status-unavailable"}`}>
          {dataStatus.message}
        </div>

        {loading && <p className="message">Loading winners...</p>}

        {error && (
          <div className="error-box">
            <strong>Error:</strong> {error}
          </div>
        )}

        {!loading && !error && items.length === 0 && (
          <p className="message">No winner data found yet.</p>
        )}

        {!loading && !error && items.length > 0 && (
          <div className="table-wrapper">
            <table className="table">
              <thead>
                <tr>
                  <th className="th">Date</th>
                  <th className="th">Ticker</th>
                  <th className="th">% Change</th>
                  <th className="th">Closing Price</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => {
                  const isPositive = Number(item.percent_change) >= 0;

                  return (
                    <tr key={item.date}>
                      <td className="td">{item.date}</td>
                      <td className="td">{item.ticker}</td>
                      <td className={`td ${isPositive ? "positive" : "negative"}`}>
                        {Number(item.percent_change).toFixed(2)}%
                      </td>
                      <td className="td">
                        ${Number(item.closing_price).toFixed(2)}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
