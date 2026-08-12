# Local Waterway Safety to Kafka to Delta Pipeline

This integration executes three published components through authentic local protocols: the Rust telemetry validator, the official Apache Kafka broker and the Python governed Delta consumer. It does not emulate an agency gateway or claim a Ministry deployment.

```bash
./integration/local-safety-kafka-delta/run.sh
```

The runner validates actual payload bytes in Rust, publishes only the resulting normalized metadata inside the governed event envelope, consumes the event with two independent Kafka groups, persists it through the insert-only Delta writer, commits both group offsets and proves replay idempotency. The final verifier also requires that the retained Delta payload exactly equals the Rust validator output.

The deterministic local telemetry document is a conformance fixture, not an agency record. Production credit remains gated on an approved gateway, device identity and key lifecycle, authenticated/encrypted broker access, telemetry registration, geofence/rules configuration, response workflow, target observability and operational acceptance.
