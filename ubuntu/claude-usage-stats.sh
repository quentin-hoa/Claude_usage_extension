#!/bin/bash
# Fetches Claude usage from claude.ai API using local OAuth token.
# Token is read from ~/.claude/.credentials.json — never hardcoded.
python3 "$(dirname "$0")/../shared/fetch_usage.py"
