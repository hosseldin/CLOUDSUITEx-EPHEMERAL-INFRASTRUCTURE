#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration from backend.tf ---
RG_NAME="tf-state-rg"
SA_NAME="tfstatelocker01hosa" # Use a new, unique name here!
CONTAINER_NAME="tfstate"
LOCATION="uaenorth"

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
# Function to Execute, Capture, and Check Exit Status
# =============================================================================
# Runs a command, captures all output/errors, and logs diagnostic details on failure.
# Arguments: $1 = command string (e.g., "az group create ...")
execute_az_command() {
  local command="$1"
  local description="$2"
  local error_output=""
  local az_status=0
  
  # Execute command and capture all output/errors into error_output
  error_output=$($command 2>&1)
  az_status=$? # Capture the exit status immediately
  
  if [ $az_status -eq 0 ]; then
    log_message "SUCCESS" "${description} successful."
    return 0 # Success
  else
    # FAILURE BLOCK: Log the exact error
    log_message "ERROR" "Failed to execute: ${description}"
    log_message "DEBUG" "Azure CLI Status Code: ${az_status}"
    log_message "DEBUG" "Azure CLI Failure Details: ${error_output}"
    return 1 # Failure
  fi
}


# =============================================================================
# 1. Create Resource Group (Idempotent Check with Error Capture)
# =============================================================================
log_message "INFO" "Checking for Resource Group: ${RG_NAME}..."

if ! az group show --name "${RG_NAME}" &> /dev/null; then
  
  log_message "INFO" "Resource Group '${RG_NAME}' not found. Attempting creation..."
  
  # Command: Create the Resource Group
  if ! execute_az_command "az group create --name \"${RG_NAME}\" --location \"${LOCATION}\" --output none" "Resource Group creation"; then
    exit 1 # Exit due to failure handled inside execute_az_command
  fi
else
  log_message "SKIP" "Resource Group '${RG_NAME}' already exists."
fi


# =============================================================================
# 2. Create Storage Account (Idempotent Check with Error Capture)
# =============================================================================
log_message "INFO" "Checking for Storage Account: ${SA_NAME}..."

if ! az storage account show --name "${SA_NAME}" --resource-group "${RG_NAME}" &> /dev/null; then
  
  log_message "INFO" "Storage Account '${SA_NAME}' not found. Attempting creation..."
  
  # Command: Create the Storage Account
  SA_CREATE_CMD="az storage account create \
    --name \"${SA_NAME}\" \
    --resource-group \"${RG_NAME}\" \
    --location \"${LOCATION}\" \
    --sku Standard_LRS \
    --kind StorageV2 \
    --allow-blob-public-access false \
    --output none"
    
  if ! execute_az_command "$SA_CREATE_CMD" "Storage Account creation"; then
    exit 1 # Exit due to failure handled inside execute_az_command
  fi
else
  log_message "SKIP" "Storage Account '${SA_NAME}' already exists."
fi


# =============================================================================
# 3. Create Blob Container (Idempotent Check with Error Capture)
# =============================================================================
log_message "INFO" "Retrieving Storage Account Key for container creation..."

# The 'az storage account keys list' command should only fail if the RG or SA is missing
SA_KEY_CMD="az storage account keys list --resource-group \"${RG_NAME}\" --account-name \"${SA_NAME}\" --query '[0].value' -o tsv"
SA_KEY=$(eval $SA_KEY_CMD) # Use eval here because the command is complex and must run synchronously
log_message "INFO" "Storage Account Key retrieved."


# Check: If 'az storage container show' FAILS, then create it.
if ! az storage container show \
  --name "${CONTAINER_NAME}" \
  --account-name "${SA_NAME}" \
  --account-key "${SA_KEY}" &> /dev/null; then
  
  log_message "INFO" "Blob Container '${CONTAINER_NAME}' not found. Attempting creation..."
  
  # Command: Create the Container
  CONTAINER_CREATE_CMD="az storage container create \
    --name \"${CONTAINER_NAME}\" \
    --account-name \"${SA_NAME}\" \
    --account-key \"${SA_KEY}\" \
    --public-access off \
    --output none"
    
  if ! execute_az_command "$CONTAINER_CREATE_CMD" "Blob Container creation"; then
    exit 1 # Exit due to failure handled inside execute_az_command
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