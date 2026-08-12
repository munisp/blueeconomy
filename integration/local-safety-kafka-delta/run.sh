#!/usr/bin/env bash
set -euo pipefail

programme="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
rust_repo="${BLUEECONOMY_WATERWAY_SAFETY_REPO:-/home/ubuntu/blueeconomy-waterway-safety}"
data_repo="${BLUEECONOMY_DATA_PLATFORM_REPO:-/home/ubuntu/blueeconomy-data-platform}"
integration="$programme/integration/local-safety-kafka-delta"
output="${1:-$integration/results}"
work="$(mktemp -d)"
compose=(sudo docker compose -f "$data_repo/integration/kafka-delta/compose.yaml")
cleanup() {
  "${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

for command in cargo docker jq python3 sudo; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "required command missing: $command" >&2
    exit 1
  }
done
[[ -d "$rust_repo/.git" ]] || { echo "Rust repository not found: $rust_repo" >&2; exit 1; }
[[ -d "$data_repo/.git" ]] || { echo "data-platform repository not found: $data_repo" >&2; exit 1; }

rm -rf "$output"
mkdir -p "$output"
"${compose[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
"${compose[@]}" up -d
for _ in $(seq 1 120); do
  if "${compose[@]}" exec -T kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server 127.0.0.1:59092 >/dev/null 2>&1; then
    break
  fi
  sleep 1
done
"${compose[@]}" exec -T kafka /opt/kafka/bin/kafka-broker-api-versions.sh --bootstrap-server 127.0.0.1:59092 >/dev/null

readonly topic="blueeconomy.safety.telemetry.validated.local"
"${compose[@]}" exec -T kafka /opt/kafka/bin/kafka-topics.sh \
  --bootstrap-server 127.0.0.1:59092 \
  --create --if-not-exists --topic "$topic" --partitions 1 --replication-factor 1

cat > "$work/telemetry.json" <<'JSON'
{"device_id":"device-local-conformance","gateway_id":"gateway-local-conformance","source_sequence":1,"observed_at":"2026-08-12T12:00:00Z","received_at":"2026-08-12T12:00:01Z","data_classification":"internal","payload_base64":"Ynl0ZXM=","payload_sha256":"277089d91c0bdf4f2e6862ba7e4a07605119431f5d13f726dd352b06f1b206a9"}
JSON

cd "$rust_repo"
cargo build --locked --release
"$rust_repo/target/release/blueeconomy-waterway-safety" "$work/telemetry.json" > "$work/normalized.json"
jq -nc --argjson payload "$(cat "$work/normalized.json")" '{
  event_id:"local-safety-kafka-event-0001",
  event_type:"safety.telemetry.validated",
  producer:"blueeconomy-waterway-safety",
  occurred_at:"2026-08-12T12:00:00Z",
  recorded_at:"2026-08-12T12:00:02Z",
  data_classification:"internal",
  source_system:"local-safety-kafka-conformance",
  source_record_reference:"local-safety-telemetry-0001",
  correlation_id:"local-safety-kafka-correlation-0001",
  payload:$payload
}' > "$work/event.ndjson"
"${compose[@]}" exec -T kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server 127.0.0.1:59092 --topic "$topic" < "$work/event.ndjson"

export PYTHONPATH="$data_repo/src"
table="$work/delta-table"
for ordinal in first second; do
  group="blueeconomy-safety-local-$ordinal"
  python3 -m blueeconomy_data_platform.kafka_ingest \
    --bootstrap-servers 127.0.0.1:59092 \
    --topic "$topic" \
    --group-id "$group" \
    --security-protocol PLAINTEXT \
    --allow-insecure-localhost \
    --max-messages 1 \
    --idle-timeout-seconds 20 \
    --table-uri "$table" \
    --schema "$data_repo/schemas/event-envelope.schema.json" \
    --report "$work/$ordinal-report.json" \
    > "$output/$ordinal.stdout.json"
  cp "$work/$ordinal-report.json" "$output/$ordinal-report.json"
  "${compose[@]}" exec -T kafka /opt/kafka/bin/kafka-consumer-groups.sh \
    --bootstrap-server 127.0.0.1:59092 --describe --group "$group" \
    > "$output/$ordinal-consumer-group.txt"
done

python3 "$integration/inspect_result.py" \
  --table "$table" \
  --normalized "$work/normalized.json" \
  --first-report "$work/first-report.json" \
  --second-report "$work/second-report.json" \
  --output "$output/result.json"
printf '%s\n' "$(git -C "$rust_repo" rev-parse HEAD)" > "$output/waterway-safety.commit"
printf '%s\n' "$(git -C "$data_repo" rev-parse HEAD)" > "$output/data-platform.commit"
sudo docker image inspect apache/kafka:4.3.1 --format '{{index .RepoDigests 0}}' > "$output/kafka-image-digest.txt"
cat "$output/result.json"
