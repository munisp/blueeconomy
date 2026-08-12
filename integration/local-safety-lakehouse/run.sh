#!/usr/bin/env bash
set -euo pipefail

programme="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
rust_repo="${BLUEECONOMY_WATERWAY_SAFETY_REPO:-/home/ubuntu/blueeconomy-waterway-safety}"
data_repo="${BLUEECONOMY_DATA_PLATFORM_REPO:-/home/ubuntu/blueeconomy-data-platform}"
output="${1:-$programme/integration/local-safety-lakehouse/results}"
work="$(mktemp -d)"
cleanup() { rm -rf "$work"; }
trap cleanup EXIT

for command in cargo jq python3 sha256sum; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "required command missing: $command" >&2
    exit 1
  }
done
[[ -d "$rust_repo/.git" ]] || { echo "Rust repository not found: $rust_repo" >&2; exit 1; }
[[ -d "$data_repo/.git" ]] || { echo "data-platform repository not found: $data_repo" >&2; exit 1; }

rm -rf "$output"
mkdir -p "$output"

cat > "$work/telemetry.json" <<'JSON'
{"device_id":"device-local-conformance","gateway_id":"gateway-local-conformance","source_sequence":1,"observed_at":"2026-08-12T12:00:00Z","received_at":"2026-08-12T12:00:01Z","data_classification":"internal","payload_base64":"Ynl0ZXM=","payload_sha256":"277089d91c0bdf4f2e6862ba7e4a07605119431f5d13f726dd352b06f1b206a9"}
JSON

cd "$rust_repo"
cargo build --locked --release
"$rust_repo/target/release/blueeconomy-waterway-safety" "$work/telemetry.json" > "$work/normalized.json"

jq -nc --argjson payload "$(cat "$work/normalized.json")" '{
  event_id:"local-safety-conformance-0001",
  event_type:"safety.telemetry.validated",
  producer:"blueeconomy-waterway-safety",
  occurred_at:"2026-08-12T12:00:00Z",
  recorded_at:"2026-08-12T12:00:02Z",
  data_classification:"internal",
  source_system:"local-conformance-harness",
  source_record_reference:"local-conformance-telemetry-0001",
  correlation_id:"local-safety-conformance-correlation-0001",
  payload:$payload
}' > "$work/events.ndjson"

table="$work/delta-table"
export PYTHONPATH="$data_repo/src"
python3 -m blueeconomy_data_platform.ingest \
  --input "$work/events.ndjson" \
  --table-uri "$table" \
  --schema "$data_repo/schemas/event-envelope.schema.json" \
  --report "$work/first-report.json" \
  > "$output/first-ingestion.stdout.json"
python3 -m blueeconomy_data_platform.ingest \
  --input "$work/events.ndjson" \
  --table-uri "$table" \
  --schema "$data_repo/schemas/event-envelope.schema.json" \
  --report "$work/second-report.json" \
  > "$output/second-ingestion.stdout.json"
python3 "$programme/integration/local-safety-lakehouse/inspect_delta.py" \
  --table "$table" \
  --first-report "$work/first-report.json" \
  --second-report "$work/second-report.json" \
  --output "$output/result.json"

sha256sum "$work/telemetry.json" | awk '{print $1}' > "$output/input.sha256"
printf '%s\n' "$(git -C "$rust_repo" rev-parse HEAD)" > "$output/waterway-safety.commit"
printf '%s\n' "$(git -C "$data_repo" rev-parse HEAD)" > "$output/data-platform.commit"
cat "$output/result.json"
