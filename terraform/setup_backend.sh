#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration from backend.tf ---
RG_NAME="tf-state-rg"
SA_NAME="tfstatelocker01-hosa"
CONTAINER_NAME="tfstate"
LOCATION="eastus"

# --- Log Configuration ---
LOG_DIR="./log"
LOG_ARCHIVE_DIR="./log_archive"
LOG_FILE="${LOG_DIR}/backend_setup_$(date +%Y%m%d_%H%M%S).log"

# --- Log Directory Setup ---
if [ ! -d "${LOG_DIR}" ]; then
  echo "INFO: Creating log directory '${LOG_DIR}'..."
  mkdir -p "${LOG_DIR}"
fi

# --- Logging Function ---
log_message() {
  local level="$1"
  local message="$2"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  local log_line="[${timestamp}] [${level}] ${message}"
  echo "${log_line}"
  echo "${log_line}" >> "${LOG_FILE}"
}

log_message "INFO" "Script starting. Log file: ${LOG_FILE}"
log_message "INFO" "Targeting Azure location: ${LOCATION}"

# =============================================================================
# 1. Create Resource Group (Idempotent Check)
# =============================================================================
log_message "INFO" "Checking for Resource Group: ${RG_NAME}..."

# Check: If 'az group show' FAILS (meaning RG not found), then create it.
if ! az group show --name "${RG_NAME}" &> /dev/null; then
  
  log_message "INFO" "Resource Group '${RG_NAME}' not found. Creating it now..."
  
  # Action: Create the Resource Group synchronously.
  if az group create --name "${RG_NAME}" --location "${LOCATION}" &> /dev/null; then
    log_message "SUCCESS" "Resource Group created successfully."
  else
    log_message "ERROR" "Failed to create Resource Group. Exiting."
    exit 1
  fi
else
  log_message "SKIP" "Resource Group '${RG_NAME}' already exists."
fi


# -----------------------------------------------------------------------------
# 2. Create Storage Account (Idempotent Check with Reliable Error Capture)
# -----------------------------------------------------------------------------
log_message "INFO" "Checking for Storage Account: ${SA_NAME}..."

# Check for existence: (Logic remains good here)
if ! az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" &> /dev/null; then
  
  log_message "INFO" "Storage Account '${SA_NAME}' not found. Attempting creation..."
  
  # Action: Create the Storage Account and capture output/error
  # 1. Execute the command and direct ALL output (STDOUT & STDERR) to a pipe.
  # 2. Capture the exact exit status into AZ_STATUS.
  
  ERROR_OUTPUT=$(
    az storage account create \
      --name "${SA_NAME}" \
      --resource-group "${RG_NAME}" \
      --location "${LOCATION}" \
      --sku Standard_LRS \
      --kind StorageV2 \
      --allow-blob-public-access false \
      --output none 2>&1
    
    # Capture the exit status of the AZ command immediately
    AZ_STATUS=$?
    # Ensure the main shell sees a successful exit from the subshell 
    # (so it doesn't break due to 'set -e' prematurely)
    echo "::AZ_STATUS::${AZ_STATUS}"
  )
  
  # Extract the status code from the captured output
  AZ_STATUS=$(echo "${ERROR_OUTPUT}" | grep -o "::AZ_STATUS::[0-9]*" | cut -d: -f3)
  
  # Remove the status message from the error output for clean logging
  ERROR_OUTPUT=$(echo "${ERROR_OUTPUT}" | sed '/::AZ_STATUS::[0-9]*$/d')
  

  # Now, check the reliably captured status code
  if [ "${AZ_STATUS}" -eq 0 ]; then
    log_message "SUCCESS" "Storage Account created successfully."
  else
    # FAILURE BLOCK: Log the high-level error and the detailed error captured above
    log_message "ERROR" "Failed to create Storage Account. Exiting."
    log_message "DEBUG" "Azure CLI Failure Details (Status ${AZ_STATUS}):"
    log_message "DEBUG" "${ERROR_OUTPUT}" # ⬅️ Logs the exact Azure error
    exit 1
  fi
else
  log_message "SKIP" "Storage Account '${SA_NAME}' already exists."
fi


# =============================================================================
# 3. Create Blob Container (Idempotent Check)
# =============================================================================
log_message "INFO" "Retrieving Storage Account Key for container creation..."

# The key list relies on the Storage Account being fully created. The script waits here.
SA_KEY=$(az storage account keys list --resource-group "${RG_NAME}" --account-name "${SA_NAME}" --query '[0].value' -o tsv)
log_message "INFO" "Storage Account Key retrieved."

# Check: If 'az storage container show' FAILS, then create it.
if ! az storage container show \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --account-key "${SA_KEY}" &> /dev/null; then
  
  log_message "INFO" "Blob Container '${CONTAINER_NAME}' not found. Creating it now..."
  
  # Action: Create the container synchronously.
  if az storage container create \
    --name "${CONTAINER_NAME}" \
    --account-name "${SA_NAME}" \
    --account-key "${SA_KEY}" \
    --public-access off \
    --output none &> /dev/null; then
    
    log_message "SUCCESS" "Blob Container created successfully."
  else
    log_message "ERROR" "Failed to create Blob Container. Exiting."
    exit 1
  fi
else
  log_message "SKIP" "Blob Container '${CONTAINER_NAME}' already exists."
fi

# =============================================================================
# 4. Log Archiving
# =============================================================================
log_message "INFO" "Checking and creating log archive directory..."
if [ ! -d "${LOG_ARCHIVE_DIR}" ]; then
  mkdir -p "${LOG_ARCHIVE_DIR}"
fi

log_message "INFO" "Moving successful log file to archive..."
mv "${LOG_FILE}" "${LOG_ARCHIVE_DIR}/"

log_message "SUCCESS" "Backend Setup complete. Log moved to ${LOG_ARCHIVE_DIR}/"

exit 0