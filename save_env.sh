#!/bin/bash

# File to save the environment variables
ENV_FILE="/tmp/current_env.sh"

# Start with a shebang
echo '#!/bin/bash' >"$ENV_FILE"

# Save all current environment variables
env | while IFS='=' read -r key value; do
  # Properly quote the value to handle multi-line and special characters
  printf 'export %s=%q\n' "$key" "$value" >>"$ENV_FILE"
done

# Make the file executable
chmod +x "$ENV_FILE"

echo "Environment variables saved to $ENV_FILE"
