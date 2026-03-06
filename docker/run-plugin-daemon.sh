#!/bin/bash
# Wrapper to start plugin-daemon with correct env vars from App Runner
export SERVER_PORT=5002
export SERVER_KEY="${PLUGIN_DAEMON_KEY}"
export DB_DATABASE="dify_plugin"
export DB_SSL_MODE="require"
export DIFY_INNER_API_URL="http://127.0.0.1:5100"
export DIFY_INNER_API_KEY="${INNER_API_KEY_FOR_PLUGIN}"
export PLUGIN_STORAGE_TYPE="local"
export PLUGIN_STORAGE_LOCAL_ROOT="/app/plugin-daemon/storage"
export PLUGIN_WORKING_PATH="/app/plugin-daemon/storage/cwd"
export PLUGIN_INSTALLED_PATH="plugin"
export PLUGIN_PACKAGE_CACHE_PATH="plugin_packages"
export PLUGIN_MEDIA_CACHE_PATH="assets"
export GIN_MODE="release"
export FORCE_VERIFYING_SIGNATURE="false"
export PLUGIN_REMOTE_INSTALLING_HOST="0.0.0.0"
export PLUGIN_REMOTE_INSTALLING_PORT="5003"
export PYTHON_ENV_INIT_TIMEOUT="120"
export PLUGIN_MAX_EXECUTION_TIMEOUT="600"

export PLATFORM="local"
exec /app/plugin-daemon/main
