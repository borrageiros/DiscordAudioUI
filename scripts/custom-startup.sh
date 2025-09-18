#!/bin/bash
set -o pipefail

CUSTOM_SCRIPT_PATH="/app/custom.sh"

if [ -f "$CUSTOM_SCRIPT_PATH" ]; then
    echo "--- Executing custom startup script ---"
    chmod +x "$CUSTOM_SCRIPT_PATH"
    if yes | /bin/bash "$CUSTOM_SCRIPT_PATH"; then
        echo "--- Custom script executed successfully ---"
    else
        echo "--- Custom script failed to execute ---"
    fi
else
    echo "--- No custom startup script found ---"
fi
