#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from deltalake import DeltaTable


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", required=True)
    parser.add_argument("--first-report", required=True, type=Path)
    parser.add_argument("--second-report", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    return parser.parse_args()


def read_json(path: Path) -> dict[str, object]:
    with path.open("r", encoding="utf-8") as handle:
        document = json.load(handle)
    if not isinstance(document, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return document


def main() -> None:
    arguments = parse_arguments()
    first = read_json(arguments.first_report)
    second = read_json(arguments.second_report)
    table = DeltaTable(arguments.table)
    rows = table.to_pyarrow_table().to_pylist()

    if len(rows) != 1:
        raise ValueError(f"expected exactly one Delta row, got {len(rows)}")
    if first.get("records_written") != 1 or first.get("records_already_present") != 0:
        raise ValueError("first ingestion did not write exactly one new event")
    if second.get("records_written") != 0 or second.get("records_already_present") != 1:
        raise ValueError("duplicate ingestion did not resolve to one already-present event")
    if rows[0].get("event_type") != "safety.telemetry.validated":
        raise ValueError("unexpected Delta event_type")

    result = {
        "delta_rows": len(rows),
        "delta_table_version": table.version(),
        "first_records_written": first["records_written"],
        "duplicate_records_written": second["records_written"],
        "duplicate_records_already_present": second["records_already_present"],
        "event_type": rows[0]["event_type"],
        "payload_sha256": json.loads(rows[0]["payload_json"])["payload_sha256"],
    }
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
