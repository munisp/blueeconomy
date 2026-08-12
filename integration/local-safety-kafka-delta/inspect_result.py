#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

from deltalake import DeltaTable


def read_object(path: Path) -> dict[str, object]:
    with path.open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--table", required=True)
    parser.add_argument("--normalized", required=True, type=Path)
    parser.add_argument("--first-report", required=True, type=Path)
    parser.add_argument("--second-report", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()

    normalized = read_object(arguments.normalized)
    first = read_object(arguments.first_report)
    second = read_object(arguments.second_report)
    table = DeltaTable(arguments.table)
    rows = table.to_pyarrow_table().to_pylist()
    if len(rows) != 1:
        raise ValueError(f"expected one Delta row after Kafka replay, got {len(rows)}")
    stored_payload = json.loads(rows[0]["payload_json"])
    if stored_payload != normalized:
        raise ValueError("Delta payload does not equal the Rust validator output")
    if first.get("records_written") != 1 or first.get("messages_received") != 1:
        raise ValueError("first Kafka group did not write one validated telemetry event")
    if second.get("records_written") != 0 or second.get("records_already_present") != 1:
        raise ValueError("second Kafka group did not produce an idempotent replay")
    for report in (first, second):
        offsets = report.get("committed_offsets")
        if not isinstance(offsets, dict) or list(offsets.values()) != [1]:
            raise ValueError("Kafka consumer offset was not committed at 1")

    result = {
        "rust_payload_verified": True,
        "payload_sha256": normalized["payload_sha256"],
        "payload_byte_count": normalized["payload_byte_count"],
        "kafka_consumer_groups": 2,
        "committed_offset": 1,
        "delta_rows": 1,
        "delta_table_version": table.version(),
        "replay_records_already_present": second["records_already_present"],
        "event_type": rows[0]["event_type"],
    }
    arguments.output.parent.mkdir(parents=True, exist_ok=True)
    arguments.output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, sort_keys=True))


if __name__ == "__main__":
    main()
