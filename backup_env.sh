#!/bin/bash

# File to save the environment variables
ENV_FILE="/tmp/backup_env.sh"

# Start with a shebang
echo '#!/bin/bash' >"$ENV_FILE"

# Save all current environment variables
while IFS='=' read -r key value; do
  # Use declare -p to preserve the integrity of multi-line values
  declare -p "$key" >>"$ENV_FILE" 2>/dev/null
done < <(env)

# Make the file executable
chmod +x "$ENV_FILE"
