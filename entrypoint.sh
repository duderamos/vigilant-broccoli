#!/bin/sh
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Now running any arbitrary commands that might have been passed in
exec "$@"
