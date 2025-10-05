
#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration from backend.tf ---
RG_NAME="tf-state-rg"
SA_NAME="tfstatelocker"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# --- Log Configuration ---
LOG_DIR="./log" # ⬅️ Define the log folder name relative to the current directory
LOG_FILE="${LOG_DIR}/backend_setup_$(date +%Y%m%d_%H%M%S).log" # ⬅️ Set the file path

# --- Log Directory Check ---
if [ ! -d "${LOG_DIR}" ]; then
  echo "INFO: Log directory '${LOG_DIR}' does not exist. Creating it now..."
  mkdir -p "${LOG_DIR}"
  echo "INFO: Directory created."
fi

# --- Logging Function ---
# Logs a message to both the console (stdout) and the log file.
log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  # Format the log line
  local log_line="[${timestamp}] [${level}] ${message}"
  
  # Output to console
  echo "${log_line}"
  
  # Append to log file
  echo "${log_line}" >> "${LOG_FILE}"
}

# --- Main Script Start ---
log_message "INFO" "Script starting. Log file: ${LOG_FILE}"
log_message "INFO" "Targeting Azure location: ${LOCATION}"

# -----------------------------------------------------------------------------
# 1. Create Resource Group (Idempotent)
# -----------------------------------------------------------------------------
log_message "INFO" "Checking for Resource Group: ${RG_NAME}..."
if az group show --name "${RG_NAME}" &> /dev/null; then
  log_message "SKIP" "Resource Group '${RG_NAME}' already exists."
else
  log_message "INFO" "Creating Resource Group '${RG_NAME}'..."
  # Use 'set -x' temporarily to log the actual command being executed
  set +e # Temporarily disable exit-on-error for the creation check
  az group create --name "${RG_NAME}" --location "${LOCATION}" 
  if [ $? -eq 0 ]; then
    log_message "SUCCESS" "Resource Group created successfully."
  else
    log_message "ERROR" "Error creating Resource Group. Check Azure permissions. Exiting."
    exit 1
  fi
  set -e # Re-enable exit-on-error
fi

# -----------------------------------------------------------------------------
# 2. Create Storage Account (Idempotent)
# -----------------------------------------------------------------------------
log_message "INFO" "Checking for Storage Account: ${SA_NAME}..."
if az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" &> /dev/null; then
  log_message "SKIP" "Storage Account '${SA_NAME}' already exists."
else
  log_message "INFO" "Creating Storage Account '${SA_NAME}'..."
  # Note: Storage Account names must be globally unique!
  az storage account create \
    --name "${SA_NAME}" \
    --resource-group "${RG_NAME}" \
    --location "${LOCATION}" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false \
    --output none
  log_message "SUCCESS" "Storage Account created successfully."
fi

# -----------------------------------------------------------------------------
# 3. Create Blob Container (Idempotent)
# -----------------------------------------------------------------------------
log_message "INFO" "Retrieving Storage Account Key for container creation..."

# Retrieve the key securely (output redirected to tsv)
SA_KEY=$(az storage account keys list --resource-group "${RG_NAME}" --account-name "${SA_NAME}" --query '[0].value' -o tsv)

# Check if the container exists
if az storage container show \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --account-key "${SA_KEY}" &> /dev/null; then
  
  log_message "SKIP" "Blob Container '${CONTAINER_NAME}' already exists."
else
  log_message "INFO" "Creating Blob Container '${CONTAINER_NAME}'..."
  az storage container create \
    --name "${CONTAINER_NAME}" \
    --account-name "${SA_NAME}" \
    --account-key "${SA_KEY}" \
    --public-access off \
    --output none
  log_message "SUCCESS" "Blob Container created successfully."
fi

log_message "INFO" "Azure Backend Setup complete. Ready for 'terraform init'."


# --- Log Archive Configuration ---
LOG_ARCHIVE_DIR=".${LOG_DIR}/log_archive"

# --- Main Script Finish & Log Archiving ---

# 1. Create the archive directory if it doesn't exist
log_message "INFO" "Checking and creating log archive directory..."
if [ ! -d "${LOG_ARCHIVE_DIR}" ]; then
  mkdir -p "${LOG_ARCHIVE_DIR}"
  log_message "SUCCESS" "Created log archive directory..."
fi

# 2. Check if the script reached this point (success)
# The 'set -e' at the top ensures that if any command failed, the script would have exited.
# If we reach this line, the script was successful.

log_message "INFO" "Moving successful log file to archive..."
mv "${LOG_FILE}" "${LOG_ARCHIVE_DIR}/"

log_message "SUCCESS" "Backend Setup complete. Log moved to ${LOG_ARCHIVE_DIR}/"

exit 0