import React, { useEffect, useState } from "react";

const API_URL = "https://50k5cfhwzj.execute-api.us-east-1.amazonaws.com/movers";

export default function App() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

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
    <div style={styles.page}>
      <div style={styles.card}>
        <h1 style={styles.title}>Weekly Stock Movers</h1>
        <p style={styles.subtitle}>Last 7 Day Winners</p>

        {loading && <p style={styles.message}>Loading winners...</p>}

        {error && (
          <div style={styles.errorBox}>
            <strong>Error:</strong> {error}
          </div>
        )}

        {!loading && !error && items.length === 0 && (
          <p style={styles.message}>No winner data found yet.</p>
        )}

        {!loading && !error && items.length > 0 && (
          <div style={styles.tableWrapper}>
            <table style={styles.table}>
              <thead>
                <tr>
                  <th style={styles.th}>Date</th>
                  <th style={styles.th}>Ticker</th>
                  <th style={styles.th}>% Change</th>
                  <th style={styles.th}>Closing Price</th>
                </tr>
              </thead>
              <tbody>
                {items.map((item) => {
                  const isPositive = Number(item.percent_change) >= 0;

                  return (
                    <tr key={item.date}>
                      <td style={styles.td}>{item.date}</td>
                      <td style={styles.td}>{item.ticker}</td>
                      <td
                        style={{
                          ...styles.td,
                          color: isPositive ? "#1f7a1f" : "#b42318",
                          fontWeight: 600,
                        }}
                      >
                        {Number(item.percent_change).toFixed(2)}%
                      </td>
                      <td style={styles.td}>
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

const styles = {
  page: {
    minHeight: "100vh",
    backgroundColor: "#f7f7fb",
    display: "flex",
    justifyContent: "center",
    alignItems: "flex-start",
    padding: "40px 16px",
    fontFamily: "Arial, sans-serif",
  },
  card: {
    width: "100%",
    maxWidth: "900px",
    backgroundColor: "#ffffff",
    borderRadius: "16px",
    boxShadow: "0 8px 24px rgba(0,0,0,0.08)",
    padding: "24px",
  },
  title: {
    margin: 0,
    fontColor:"rgba(0, 0, 0, 1)",
    marginBottom: "8px",
    fontSize: "2rem",
  },
  subtitle: {
    marginTop: 0,
    marginBottom: "24px",
    color: "#555",
  },
  message: {
    fontSize: "1rem",
    color: "#444",
  },
  errorBox: {
    backgroundColor: "#fef3f2",
    color: "#b42318",
    border: "1px solid #fecdca",
    borderRadius: "8px",
    padding: "12px 16px",
    marginBottom: "16px",
  },
  tableWrapper: {
    overflowX: "auto",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
  },
  th: {
    textAlign: "left",
    padding: "12px",
    borderBottom: "2px solid #e5e7eb",
    backgroundColor: "#fafafa",
  },
  td: {
    padding: "12px",
    borderBottom: "1px solid #e5e7eb",
  },
};