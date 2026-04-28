"""Observability — metrics, activity log, OpenTelemetry span helpers.

- ``metrics``  — Prometheus text-format registry (counter, gauge, histogram)
- ``activity`` — JSONL activity log with query API (every tool call /
                  agent step / finding is appended as a structured event)
- ``tracing``  — OpenTelemetry span helpers (no-op fallback when the
                  ``opentelemetry-api`` package is absent so the main
                  runtime stays dependency-free)
"""

from __future__ import annotations

from botron.observability.activity import ActivityLog, LogEvent
from botron.observability.metrics import Counter, Gauge, Histogram, Registry, render
from botron.observability.tracing import span

__all__ = [
    "ActivityLog",
    "Counter",
    "Gauge",
    "Histogram",
    "LogEvent",
    "Registry",
    "render",
    "span",
]
