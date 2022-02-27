
#
# Remember, non-terminal do not get ANSI_COLOR
#
readonly LOG_FILE="/tmp/$(basename "$0").log"

log_info()  { echo "[INFO]    $*" | tee -a "$LOG_FILE" >&2 ; }
log_warn()  { echo "[WARNING] $*" | tee -a "$LOG_FILE" >&2 ; }
log_error() { echo "[ERROR]   $*" | tee -a "$LOG_FILE" >&2 ; }
log_fatal() { echo "[FATAL]   $*" | tee -a "$LOG_FILE" >&2 ; exit 1
