#!/usr/bin/env python3

import os
import json
import pandas as pd
import plotly.graph_objects as go
import plotly.io as pio

os.makedirs("data", exist_ok=True)

with open("data/history.json") as f:
    raw_data = json.load(f)

records = []
for date_str, data in raw_data.items():
    total = data.get("total")
    if not total:
        continue

    for engine, passed in data.items():
        if engine in ["time", "total", "versions", "test262"]:
            continue
        if not isinstance(passed, int):
            continue

        records.append({
            "date": date_str,
            "engine": engine,
            "passed_tests": passed,
            "total_tests": total,
            "percent_passed": (passed / total) * 100
        })

df = pd.DataFrame(records)
df["date"] = pd.to_datetime(df["date"])
df = df.sort_values(["engine", "date"])

csv_path = os.path.join("data", "test262_pass_rates.csv")
df.to_csv(csv_path, index=False)
print(f"Saved CSV to {csv_path}")

default_engines = {"v8", "jsc", "sm"}

fig = go.Figure()
for engine in df["engine"].unique():
    engine_df = df[df["engine"] == engine]
    visible = True if engine in default_engines else "legendonly"

    fig.add_trace(go.Scatter(
        x=engine_df["date"],
        y=engine_df["percent_passed"],
        mode="lines",
        name=engine,
        visible=visible,
        hovertemplate="%{x|%Y-%m-%d}: %{y:.2f}%<extra>" + engine + "</extra>"
    ))

fig.update_layout(
    title="Test262 Pass Rates by Engine",
    xaxis_title="Date",
    yaxis_title="Pass Rate (%)",
    yaxis=dict(range=[0, 100]),
    hovermode="x unified",
    template="plotly_white",
    legend_title="Engine"
)

html_str = pio.to_html(fig, full_html=True, include_plotlyjs="cdn")

footer_html = """
<footer style="text-align: center; position: fixed; bottom: 10px; right: 15px; font-family: sans-serif; font-size: 0.8em; color: gray;">
  Data source: <a href="https://test262.fyi" target="_blank">test262.fyi</a>
</footer>
</body>
"""

html_str = html_str.replace("</body>", footer_html)

html_path = os.path.join("docs", "index.html")

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_str)
print(f"Saved interactive report to {html_path}")
