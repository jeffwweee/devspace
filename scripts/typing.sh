#!/bin/bash
# typing.sh - Send typing indicator to Telegram via gateway
# Usage: ./scripts/typing.sh <bot_id> <chat_id>

BOT_ID="${1:-pichu}"
CHAT_ID="$2"

if [ -z "$CHAT_ID" ]; then
  echo "Usage: $0 <bot_id> <chat_id>"
  exit 1
fi

# Build JSON payload with jq
PAYLOAD=$(jq -n \
  --arg bot_id "$BOT_ID" \
  --argjson chat_id "$CHAT_ID" \
  '{bot_id: $bot_id, chat_id: $chat_id}')

curl -s -X POST http://localhost:3100/typing \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
