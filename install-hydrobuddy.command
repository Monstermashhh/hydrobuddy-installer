#!/bin/bash

# Auto-fix permissions if needed (for users who download without execute bit)
if [ ! -x "$0" ]; then
    chmod +x "$0" 2>/dev/null || {
        echo ""
        echo "❌ Error: This script needs execute permissions."
        echo ""
        echo "Please run this command in Terminal:"
        echo "  chmod +x $(basename "$0")"
        echo ""
        echo "Then double-click the script again."
        read -p "Press Enter to exit..." || true
        exit 1
    }
    # Re-execute with proper permissions
    exec "$0" "$@"
fi

# HydroBuddy macOS Installer
# This script helps install HydroBuddy on macOS by removing the quarantine flag
# that prevents unsigned applications from running.

# Strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly REQUIRED_DBS=("formulations_unix.dbf" "waterquality_unix.dbf" "substances_unix.dbf" "substances_used_unix.dbf" "tissue_analysis_unix.dbf")

# Variables
LOG_FILE="/tmp/hydrobuddy-install-$(date +%Y%m%d-%H%M%S).log"

# Start logging
exec 1> >(tee -a "$LOG_FILE")
exec 2>&1

cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║              HydroBuddy macOS Installer                       ║
║              Version 1.0.1                                    ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝

This installer will:
  1. Validate application bundle integrity
  2. Check for required database files
  3. Move HydroBuddy folder to Applications
  4. Modify app to auto-detect database files
  5. Remove macOS quarantine flag from all files
  6. Launch HydroBuddy

Why is this needed?
  HydroBuddy is free, open-source software. Apple's code signing
  costs $99/year, which isn't feasible for this free project.
  This script tells macOS that you trust this application.

EOF

echo "Log file: $LOG_FILE"
echo ""

# Function to display errors
error_exit() {
    echo ""
    echo "❌ Error: $1"
    echo ""
    echo "Log saved to: $LOG_FILE"
    read -p "Press Enter to exit..." || true
    exit 1
}

# Function to check if running on macOS
check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error_exit "This script is for macOS only"
    fi
    
    # Check macOS version
    local macos_version macos_major_version macos_minor_version
    macos_version=$(sw_vers -productVersion)
    macos_major_version=$(echo "$macos_version" | cut -d. -f1)
    macos_minor_version=$(echo "$macos_version" | cut -d. -f2)
    
    # Gatekeeper was introduced in 10.7.5, but reliable quarantine handling is 10.8+
    if [ "$macos_major_version" -lt 10 ] || 
       ([ "$macos_major_version" -eq 10 ] && [ "$macos_minor_version" -lt 8 ]); then
        error_exit "This script requires macOS 10.8 (Mountain Lion) or later. You have: $macos_version"
    fi
    
    if [ "$macos_major_version" -ge 15 ]; then
        echo "ℹ️  Detected macOS 15 (Sequoia) - enhanced security measures in effect"
        echo ""
    fi
}

# Function to validate app bundle
validate_app_bundle() {
    local app_path="$1"
    
    echo "Validating application bundle..."
    
    # Check if it's a directory
    if [ ! -d "$app_path" ]; then
        error_exit "Path is not a directory: $app_path"
    fi
    
    # Check for Contents directory
    if [ ! -d "$app_path/Contents" ]; then
        error_exit "Not a valid macOS application bundle (missing Contents/)"
    fi
    
    # Check for Info.plist
    if [ ! -f "$app_path/Contents/Info.plist" ]; then
        error_exit "Not a valid macOS application bundle (missing Info.plist)"
    fi
    
    # Check for executable
    if [ ! -d "$app_path/Contents/MacOS" ] || [ -z "$(ls -A "$app_path/Contents/MacOS" 2>/dev/null)" ]; then
        error_exit "Application bundle appears to be incomplete (missing executable)"
    fi
    
    echo "✓ Application bundle is valid"
}

# Function to check database files
check_database_files() {
    local app_dir
    app_dir="$(dirname "$1")"
    
    echo "Checking for database files..."
    
    local missing_files=()
    for file in "${REQUIRED_DBS[@]}"; do
        if [ ! -f "$app_dir/$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "⚠️  Warning: Missing database files:"
        printf '    - %s\n' "${missing_files[@]}"
        echo ""
        echo "HydroBuddy will prompt you to locate these files on first launch."
        echo ""
        read -p "Continue installation? [y/n] " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
    else
        echo "✓ All database files found"
    fi
    echo ""
}

# Check system
check_macos

# Find the script directory (where HydroBuddy.app should be)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Looking for HydroBuddy.app..."
echo ""

# Check script directory
if [ -d "$SCRIPT_DIR/hydrobuddy.app" ]; then
    APP_PATH="$SCRIPT_DIR/hydrobuddy.app"
elif [ -d "$SCRIPT_DIR/HydroBuddy.app" ]; then
    APP_PATH="$SCRIPT_DIR/HydroBuddy.app"
# Check if already in Applications (search in subfolders)
elif [ -n "$(find /Applications -maxdepth 2 -name "hydrobuddy.app" -type d 2>/dev/null | head -1)" ]; then
    APP_PATH="$(find /Applications -maxdepth 2 -name "hydrobuddy.app" -type d 2>/dev/null | head -1)"
elif [ -n "$(find /Applications -maxdepth 2 -name "HydroBuddy.app" -type d 2>/dev/null | head -1)" ]; then
    APP_PATH="$(find /Applications -maxdepth 2 -name "HydroBuddy.app" -type d 2>/dev/null | head -1)"
else
    error_exit "Could not find HydroBuddy.app. Please place this script in the same folder as HydroBuddy.app"
fi

# Remove trailing slashes
APP_PATH="${APP_PATH%/}"

echo "✓ Found: $APP_PATH"
echo ""

# Validate the app bundle
validate_app_bundle "$APP_PATH"
echo ""

# Check database files
check_database_files "$APP_PATH"

# Get the folder containing the app
APP_FOLDER="$(dirname "$APP_PATH")"
FOLDER_NAME="$(basename "$APP_FOLDER")"
INSTALL_DIR=""

# Remove quarantine BEFORE moving (no sudo needed for user's own files)
echo "Removing quarantine from source files..."
xattr -cr "$APP_FOLDER" 2>/dev/null || true
echo "✓ Quarantine removed from source files"
echo ""

# Check if already in Applications
if [[ "$APP_FOLDER" == /Applications/* ]] || [[ "$APP_FOLDER" == $HOME/Applications/* ]]; then
    echo "✓ Already installed in Applications folder"
    echo "   Location: $APP_FOLDER"
    INSTALL_DIR="$APP_FOLDER"
    echo ""
    echo "Skipping move step - running in-place modifications..."
    echo ""
else
    echo "Moving HydroBuddy folder to Applications..."
    echo "Source: $APP_FOLDER"
    echo "Target: /Applications/$FOLDER_NAME"
    echo ""
    
    # Check if folder already exists in Applications
    if [ -d "/Applications/$FOLDER_NAME" ]; then
        echo "⚠️  Folder already exists: /Applications/$FOLDER_NAME"
        read -p "Replace it? [y/n] " -n 1 -r REPLACE_RESPONSE
        echo ""
        echo ""
        
        if [[ $REPLACE_RESPONSE =~ ^[Yy]$ ]]; then
            echo "Creating backup..."
            BACKUP_PATH="/Applications/${FOLDER_NAME}.backup-$(date +%Y%m%d-%H%M%S)"
            mv "/Applications/$FOLDER_NAME" "$BACKUP_PATH" || error_exit "Failed to backup existing folder"
            echo "✓ Backup created: $BACKUP_PATH"
        else
            echo "Installation cancelled by user."
            exit 0
        fi
    fi
    
    # Move the entire folder to Applications
    echo "Moving folder to Applications..."
    
    if mv "$APP_FOLDER" /Applications/; then
        echo "✓ Folder moved successfully"
        
        # Update paths to new location
        INSTALL_DIR="/Applications/$FOLDER_NAME"
        APP_PATH="$INSTALL_DIR/$(basename "$APP_PATH")"
        
        # Remove backup if successful
        if [ -d "${BACKUP_PATH:-}" ]; then
            read -p "Remove backup? [y/n] " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$BACKUP_PATH"
                echo "✓ Backup removed"
            else
                echo "✓ Backup kept: $BACKUP_PATH"
            fi
        fi
    else
        # Restore backup if move failed
        if [ -d "${BACKUP_PATH:-}" ]; then
            mv "$BACKUP_PATH" "/Applications/$FOLDER_NAME"
            echo "✓ Backup restored"
        fi
        error_exit "Failed to move folder to Applications"
    fi
    
    echo ""
fi

# Modify the app bundle to auto-find database files
APP_DIR="$(dirname "$APP_PATH")"
MACOS_DIR="$APP_PATH/Contents/MacOS"
ORIGINAL_EXEC="$MACOS_DIR/hydrobuddy"
BINARY_EXEC="$MACOS_DIR/hydrobuddy-bin"

echo "Modifying app bundle for automatic database detection..."

# Check if already modified
if [ ! -f "$BINARY_EXEC" ]; then
    cd "$MACOS_DIR"
    
    # If it's a symlink, copy the target and remove symlink
    if [ -L "hydrobuddy" ]; then
        cp "../../../hydrobuddy" "hydrobuddy-bin"
        rm "hydrobuddy"
    else
        # Move original executable
        mv "hydrobuddy" "hydrobuddy-bin"
    fi
    
    # Create wrapper script
    printf '#!/bin/bash\n# HydroBuddy Wrapper - Auto-detects database files\n\n# Get the app bundle'"'"'s parent directory\nAPP_BUNDLE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../../.." && pwd )"\n\n# Change to that directory\ncd "$APP_BUNDLE"\n\n# Launch the actual executable\nexec "$APP_BUNDLE/hydrobuddy.app/Contents/MacOS/hydrobuddy-bin" "$@"\n' > "$ORIGINAL_EXEC"
    
    chmod +x "$ORIGINAL_EXEC"
    echo "✓ App bundle modified"
else
    echo "✓ App bundle already modified"
fi
echo ""

# Also create a launcher command script as backup
LAUNCHER_COMMAND="$APP_DIR/Launch-HydroBuddy.command"

echo "Creating launcher command (alternative method)..."

printf '#!/bin/bash\n# HydroBuddy Launcher\n# This script launches HydroBuddy with the correct working directory\n# so it can automatically find its database files.\n\n# Get the directory where this script is located\nSCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"\n\n# Change to the directory containing the database files\ncd "$SCRIPT_DIR"\n\n# Launch HydroBuddy\nexec "$SCRIPT_DIR/hydrobuddy.app/Contents/MacOS/hydrobuddy"\n' > "$LAUNCHER_COMMAND"

chmod +x "$LAUNCHER_COMMAND"

echo "✓ Launcher command created as backup method"
echo ""

# Final cleanup: Remove any quarantine attributes that may have been re-added
echo "Final security cleanup..."

# Remove quarantine from the final location
xattr -cr "$INSTALL_DIR" 2>/dev/null || true

# Check if any attributes remain
if xattr -l "$APP_PATH" 2>/dev/null | grep -q "com.apple.quarantine"; then
    echo "⚠️  Note: Some quarantine attributes remain"
    echo "   This is normal. macOS will prompt you to allow the app on first launch."
    echo ""
    echo "   If you get 'damaged or incomplete' errors, run:"
    echo "   sudo xattr -cr \"$INSTALL_DIR\""
else
    echo "✓ Security attributes cleaned successfully"
fi

echo ""

echo "Installed at: $INSTALL_DIR"
echo ""

# Open Finder to show the installed location
echo "Opening Finder to Applications folder..."
open /Applications
sleep 1

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installation complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Launching HydroBuddy..."
echo ""
echo "NOTE: If macOS still blocks the app:"
echo "  1. Go to System Settings > Privacy & Security"
echo "  2. Scroll down to the Security section"
echo "  3. Click 'Open Anyway' next to the HydroBuddy message"
echo "  4. Click 'Open' to confirm"
echo ""

# Launch the modified app
open "$APP_PATH"

sleep 1
echo ""
echo "✓ HydroBuddy launched!"
echo ""
echo "✨ Database files are auto-detected - no folder selection needed!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "How to launch HydroBuddy in the future:"
echo ""
echo "  Method 1 (Recommended):"
echo "    Double-click: hydrobuddy.app"
echo "    Just like any other Mac app!"
echo ""
echo "  Method 2 (Alternative):"  
echo "    Double-click: Launch-HydroBuddy.command"
echo ""
echo "  Both methods work automatically - no folder selection needed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo ""
echo "Log saved to: $LOG_FILE"
echo ""
read -p "Press Enter to close (auto-close in 10s)..." -t 10 || true
