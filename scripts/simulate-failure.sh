cat > scripts/simulate-failure.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

INSTANCE_ID="${1:?Usage: ./scripts/simulate-failure.sh i-INSTANCE_ID}"

echo "WARNING: This stops the selected EC2 instance."
echo "Instance: $INSTANCE_ID"

read -r -p "Type STOP to continue: " CONFIRM

if [[ "$CONFIRM" != "STOP" ]]; then
  echo "Cancelled."
  exit 1
fi

aws ec2 stop-instances --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --instance-ids "$INSTANCE_ID"

echo "Instance stopped. Check the CloudWatch alarms."
EOF

chmod +x scripts/simulate-failure.sh
