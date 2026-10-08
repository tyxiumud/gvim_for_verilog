#!/usr/bin/env python3
"""Generate a self-hosted GitHub Star History SVG, using only the standard library.

History is reconstructed from the accounts that CURRENTLY star the repository.
GitHub does not provide historical unstar events through this endpoint.
"""
from __future__ import annotations

from collections import Counter
from datetime import date, datetime, timedelta
from html import escape
import json
import math
import os
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen


def get_star_dates(repository: str, token: str) -> list[date]:
    dates: list[date] = []
    page = 1
    while True:
        url = (
            f"https://api.github.com/repos/{repository}/stargazers"
            f"?per_page=100&page={page}"
        )
        headers = {
            "Accept": "application/vnd.github.star+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "gvim-for-verilog-star-history-action",
        }
        if token:
            headers["Authorization"] = f"Bearer {token}"

        try:
            with urlopen(Request(url, headers=headers), timeout=30) as response:
                items = json.load(response)
        except HTTPError as exc:
            raise RuntimeError(
                f"GitHub API request failed (page {page}, HTTP {exc.code}). "
                "The existing chart has not been replaced."
            ) from exc

        if not isinstance(items, list):
            raise RuntimeError("Unexpected GitHub API response: expected a list.")
        for item in items:
            timestamp = item.get("starred_at")
            if not timestamp:
                raise RuntimeError(
                    "GitHub did not return starred_at timestamps. "
                    "Check the API Accept header; existing chart is unchanged."
                )
            dates.append(datetime.fromisoformat(
                timestamp.replace("Z", "+00:00")
            ).date())

        if len(items) < 100:
            break
        page += 1
        if page > 1000:
            raise RuntimeError("Aborting: more than 100,000 stars.")

    return sorted(dates)


def svg_chart(repository: str, dates: list[date]) -> str:
    width, height = 960, 500
    left, right, top, bottom = 90, 920, 100, 417
    plot_width, plot_height = right - left, bottom - top
    counts = Counter(dates)
    total = len(dates)

    if dates:
        first, last = dates[0], dates[-1]
        raw_span = (last - first).days
        padding = max(1, min(14, raw_span // 30 + 1))
        start = first - timedelta(days=padding)
        end = last + timedelta(days=padding)
    else:
        end = date.today()
        start = end - timedelta(days=30)

    span = max(1, (end - start).days)
    rough_step = max(1, math.ceil(total / 4))
    scale = 10 ** (len(str(rough_step)) - 1)
    step = next(m * scale for m in (1, 2, 5, 10)
                if m * scale >= rough_step)
    y_max = max(step, math.ceil(total / step) * step)

    def px(day: date) -> float:
        return left + (day - start).days / span * plot_width

    def py(value: int) -> float:
        return bottom - value / y_max * plot_height

    def coord(day: date, value: int) -> str:
        return f"{px(day):.1f},{py(value):.1f}"

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" role="img" aria-label="GitHub Star History for {escape(repository)}">',
        f'<title>Star History: {escape(repository)}</title>',
        '<defs><linearGradient id="area" x1="0" y1="0" x2="0" y2="1">',
        '<stop offset="0%" stop-color="#f97316" stop-opacity="0.22"/>',
        '<stop offset="100%" stop-color="#f97316" stop-opacity="0.01"/>',
        '</linearGradient></defs>',
        '<rect width="960" height="500" fill="#ffffff" rx="16"/>',
        '<text x="90" y="48" font-family="Arial,sans-serif" font-size="27" font-weight="700" fill="#1f2937">Star History</text>',
        f'<text x="90" y="75" font-family="Arial,sans-serif" font-size="15" fill="#64748b">{escape(repository)}</text>',
        f'<text x="920" y="52" text-anchor="end" font-family="Arial,sans-serif" font-size="26" font-weight="700" fill="#ea580c">{total} ★</text>',
    ]

    for value in range(0, y_max + 1, step):
        y = py(value)
        parts.extend([
            f'<line x1="{left}" y1="{y:.1f}" x2="{right}" y2="{y:.1f}" stroke="#e5e7eb" stroke-width="1"/>',
            f'<text x="{left - 14}" y="{y + 5:.1f}" text-anchor="end" font-family="Arial,sans-serif" font-size="13" fill="#64748b">{value:,}</text>',
        ])

    tick_days = sorted({
        start + timedelta(days=round(i * span / 5)) for i in range(6)
    })
    fmt = "%Y-%m" if span > 120 else "%m-%d"
    for day in tick_days:
        x = px(day)
        parts.append(
            f'<text x="{x:.1f}" y="443" text-anchor="middle" '
            f'font-family="Arial,sans-serif" font-size="12" fill="#64748b">'
            f'{day.strftime(fmt)}</text>'
        )

    parts.extend([
        f'<line x1="{left}" y1="{bottom}" x2="{right}" y2="{bottom}" stroke="#94a3b8"/>',
        f'<line x1="{left}" y1="{top}" x2="{left}" y2="{bottom}" stroke="#94a3b8"/>',
    ])

    if dates:
        points = [(start, 0)]
        running = 0
        for day, count in sorted(counts.items()):
            points.append((day, running))
            running += count
            points.append((day, running))
        points.append((end, running))
        path = " ".join(
            ("M" if i == 0 else "L") + coord(day, value)
            for i, (day, value) in enumerate(points)
        )
        area = (
            f"M{coord(start, 0)} "
            + " ".join(f"L{coord(day, value)}" for day, value in points[1:])
            + f" L{px(end):.1f},{bottom} Z"
        )
        parts.extend([
            f'<path d="{area}" fill="url(#area)"/>',
            f'<path d="{path}" stroke="#f15b32" stroke-width="3.3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
            f'<circle cx="{px(end):.1f}" cy="{py(total):.1f}" r="5" fill="#f15b32"/>',
        ])
    else:
        parts.append(
            '<text x="505" y="260" text-anchor="middle" '
            'font-family="Arial,sans-serif" font-size="18" fill="#94a3b8">'
            'Waiting for the first Star</text>'
        )

    parts.extend([
        '<text x="90" y="480" font-family="Arial,sans-serif" font-size="12" fill="#94a3b8">Source: GitHub API · Based on currently starred accounts</text>',
        '</svg>',
    ])
    return "\n".join(parts) + "\n"


def main() -> None:
    repository = os.environ.get("GITHUB_REPOSITORY", "tyxiumud/gvim_for_verilog")
    token = os.environ.get("GH_TOKEN", "")
    dates = get_star_dates(repository, token)
    target = Path("assets/star-history.svg")
    target.parent.mkdir(parents=True, exist_ok=True)
    result = svg_chart(repository, dates)
    if not target.exists() or target.read_text(encoding="utf-8") != result:
        target.write_text(result, encoding="utf-8")
        print(f"Updated {target} ({len(dates)} stars)")
    else:
        print(f"No change ({len(dates)} stars)")


if __name__ == "__main__":
    main()
