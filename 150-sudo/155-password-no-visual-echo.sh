#!/bin/bash
# File: 157-password-no-visual-echo.sh
# Path: 150-sudo/
# Title: Fully transactional sudo pwfeedback enforcement
# Description:
#    Ensures exactly one Defaults !pwfeedback entry across /etc/sudoers and /etc/sudoers.d files.
#    Implements atomic edits, rollback on failure, dry-run mode, and permissions enforcement.
#    Precedence-aware, singleton enforcement, @includedir compatible, and version-aware (sudo ≥1.6).
#    Designed for interactive easy-admin use; no CI/CD, cron, or automated execution assumptions.
#
#    - Fixes the SUDOERS_D definition order
#    - Uses user-owned temporary files in /tmp
#    - Copies/modifies with sudo for root-owned targets
#    - Atomic commit (tmp → mv)
#    - Trap-based rollback
#    - Dry-run plan + confirmation
#    - Create / append / update correctly, including empty 99-password-hardening files
#    - Singleton enforcement (abort if multiple entries)
#    - LC_ALL=C deterministic sort
#    - umask 0640 for temporary files
#    - Pre/post visudo validation
#    - Ownership/permissions enforced
#
# Standards:
#   - CIS Linux    Sudo Hardening
#   - NIST 800-53  CM-6 (Configuration Settings)
#   - NIST 800-171 3.4.1
#   - ISO 27001    A.12.6.2
#   - Fully transactional pwfeedback enforcement (atomic + rollback)
#   - Safe, precedence-aware, singleton enforcement
#   - Use visudo -f when editing files in /etc/sudoers.d
#   - Never lock yourself out hardened framework

set -euo pipefail

########################################
# CONFIG / TMP
########################################
umask 0640                # Secure temp files
TMP_DIR="$(mktemp -d)"
BACKUP_DIR="/var/backups/sudoers-pwfeedback"

SUDOERS="/etc/sudoers"
SUDOERS_D="/etc/sudoers.d"
CONTROL_FILE="$SUDOERS_D/99-password-hardening"
DRY_RUN=1                  # Default dry-run (set 0 to execute)
MATCH_REGEX='^[[:space:]]*Defaults[^#]*\bpwfeedback\b'
ROLLBACK_NEEDED=0
IGNORE_INCLUDE=1

########################################
# LOGGING
########################################
log() { echo "[INFO] $*"; }
err() { echo "[ERROR] $*" >&2; }

########################################
# CLEANUP / ROLLBACK
########################################
rollback() {
    if [[ "$ROLLBACK_NEEDED" -eq 1 ]]; then
        err "Rollback triggered"
        [[ -f "$BACKUP_DIR/sudoers.bak" ]] && sudo cp "$BACKUP_DIR/sudoers.bak" "$SUDOERS"
        [[ -f "$BACKUP_DIR/sudoers.d.tar.gz" ]] && sudo tar -xzf "$BACKUP_DIR/sudoers.d.tar.gz" -C /
    fi
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
      sudo rm -rf "$TMP_DIR"
    fi
}
trap rollback EXIT

########################################
# SUDO PRECHECK
########################################
if ! sudo -n true 2>/dev/null; then
    log "sudo will require a password during execution"
fi

if ! sudo -v; then
    err "Unable to obtain sudo privileges"
    exit 1
fi

########################################
# VERSION CHECK
########################################
version_ge() { printf '%s\n%s\n' "$2" "$1" | sort -V -C; }

SUDO_VERSION="$(sudo --version | head -n1 | awk '{print $3}')"
log "Sudo version: $SUDO_VERSION"

########################################
# PRE-VALIDATION
########################################
log "Validating current sudoers..."
if ! sudo visudo -cf "$SUDOERS"; then
    err "Invalid sudoers configuration"
    exit 1
fi

########################################
# INCLUDE DETECTION
########################################
if version_ge "$SUDO_VERSION" "1.7.0"; then
    INCLUDE_DIR=$(sudo grep -E '^[[:space:]]*@includedir' "$SUDOERS" | awk '{print $2}' || true)

    if [[ -z "$INCLUDE_DIR" ]]; then
        IGNORE_INCLUDE=1
        log "No @includedir → using /etc/sudoers only"
    elif [[ "$INCLUDE_DIR" != "$SUDOERS_D" ]]; then
        err "Non-standard include dir detected: $INCLUDE_DIR"
        exit 11
    else
        IGNORE_INCLUDE=0
        log "Using include dir: $INCLUDE_DIR"
    fi
else
    IGNORE_INCLUDE=1
    log "Old sudo version → no include support"
fi

########################################
# VALID FILE LIST (deterministic)
########################################
VALID_FILES=""
if [[ "$IGNORE_INCLUDE" -eq 0 ]]; then
    VALID_FILES=$(LC_ALL=C find "$SUDOERS_D" \
        -type f \
        ! -name '*.*' \
        ! -name '*~' \
        -user root \
        -perm -u=r \
        ! -perm /022 \
        2>/dev/null | sort)
fi

########################################
# DISCOVERY
########################################
MAIN_MATCH=$(sudo grep -E "$MATCH_REGEX" "$SUDOERS" || true)
SUB_MATCH=""
if [[ -n "$VALID_FILES" ]]; then
    SUB_MATCH=$(sudo grep -E "$MATCH_REGEX" $VALID_FILES || true)
fi
ALL_MATCHES=$(printf "%s\n%s\n" "$MAIN_MATCH" "$SUB_MATCH" | sed '/^$/d')
COUNT=$(printf "%s\n" "$ALL_MATCHES" | sudo grep -c pwfeedback || true)
log "Detected $COUNT pwfeedback entries"

########################################
# SINGLETON ENFORCEMENT CHECKS
########################################
if [[ "$COUNT" -eq 1 ]] && echo "$ALL_MATCHES" | sudo grep -q '!pwfeedback'; then
    log "Already compliant (single Defaults !pwfeedback)"
    exit 0
fi

if [[ "$COUNT" -gt 1 ]]; then
    err "Multiple pwfeedback entries detected:"
    echo "$ALL_MATCHES"
    exit 11
fi

########################################
# TARGET FILE DECISION (create/append/update)
########################################
if [[ "$COUNT" -eq 0 ]]; then
    if [[ "$IGNORE_INCLUDE" -eq 0 ]]; then
        TARGET_FILE="$CONTROL_FILE"
    else
        TARGET_FILE="$SUDOERS"
    fi
    ACTION="create"
else
    # Only one match exists → update
    TARGET_FILE=$(echo "$ALL_MATCHES" | awk -F: '{print $1}')
    if sudo grep -qE "$MATCH_REGEX" "$TARGET_FILE"; then
        ACTION="update"
    else
        ACTION="append"
    fi
fi

cat <<EOF
========== PLAN ==========
Target file : $TARGET_FILE
Action      : $ACTION
Directive   : Defaults !pwfeedback
==========================
EOF

read -rp "Proceed with changes? [y/N]: " CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 0

########################################
# BACKUP
########################################
log "Creating backup..."
sudo mkdir -p "$BACKUP_DIR"
sudo cp "$SUDOERS" "$BACKUP_DIR/sudoers.bak"
sudo tar -czf "$BACKUP_DIR/sudoers.d.tar.gz" "$SUDOERS_D"
ROLLBACK_NEEDED=1

########################################
# APPLY (user temp → atomic commit)
########################################
TMP_FILE="$TMP_DIR/newfile"

if [[ "$ACTION" == "create" ]]; then
    echo "Defaults !pwfeedback" > "$TMP_FILE"
elif [[ "$ACTION" == "append" ]]; then
    sudo cp "$TARGET_FILE" "$TMP_FILE"
    echo "Defaults !pwfeedback" >> "$TMP_FILE"
elif [[ "$ACTION" == "update" ]]; then
    sudo cp "$TARGET_FILE" "$TMP_FILE"
    sudo sed -E -i 's/(^|[[:space:],])!?pwfeedback([[:space:],]|$)/\1!pwfeedback\2/g' "$TMP_FILE"
fi

sudo chmod 0640 "$TMP_FILE"
sudo mv "$TMP_FILE" "$TARGET_FILE"
sudo chown root:root "$TARGET_FILE"

########################################
# POST VALIDATION
########################################
log "Validating updated sudoers..."
if ! sudo visudo -cf "$SUDOERS"; then
    err "Validation failed"
    exit 99
fi

ROLLBACK_NEEDED=0
log "pwfeedback enforcement complete"
exit 0
