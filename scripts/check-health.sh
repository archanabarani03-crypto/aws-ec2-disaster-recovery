cat > scripts/check-health.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

URL="${1:?Usage: ./scripts/check-health.sh http://PUBLIC_IP}"

echo "Checking application: $URL"

for attempt in $(seq 1 12); do
  if curl --fail --silent --show-error \
      --max-time 5 "$URL/health"; then
    echo
    echo "RESULT: HEALTHY"
    exit 0
  fi

  echo "Attempt $attempt failed; retrying..."
  sleep 5
done

echo "RESULT: UNHEALTHY"
exit 1
EOF

chmod +x scripts/check-health.sh
