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
║              Version 1.1.0                                    ║
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

# Add custom fertilizers to database
APP_MACOS_DIR="$APP_PATH/Contents/MacOS"

if command -v python3 &> /dev/null; then
    echo "Adding custom fertilizers to database..."
    echo ""
    
    # Look for fertilizers.csv - check external files first, then use embedded data
    SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/fertilizers.csv" ]; then
        CSV_TO_USE="$SCRIPT_DIR/fertilizers.csv"
        echo "  ✓ Using custom fertilizers.csv from same directory"
    elif [ -f "$SCRIPT_DIR/docs/fertilizers.csv" ]; then
        CSV_TO_USE="$SCRIPT_DIR/docs/fertilizers.csv"
        echo "  ✓ Using fertilizers.csv from docs/ directory"
    else
        # No external CSV found - create from embedded data
        CSV_TO_USE="/tmp/hydrobuddy-fertilizers-$$.csv"
        echo "  ✓ Using built-in fertilizer database (58 fertilizers)"
        cat > "$CSV_TO_USE" << 'CSV_EOF'
Name,Formula,Source,Purity,N_NO3,N_NH4,P,K,Mg,Ca,S,B,Fe,Zn,Mn,Cu,Mo,Na,Si,Cl,isLiquid,Density,Cost,ConcType
Jacks 5-12-26 Part A,NPK blend,Jack's Nutrients,1.0,5.0,0.0,5.24,21.58,6.3,0.0,8.5,0.05,0.3,0.015,0.05,0.015,0.019,0.0,0.0,0.0,0,0.0,0.0,0
Jacks 0-12-26 Part A,PK blend,Jack's Nutrients,1.0,0.0,0.0,5.24,21.58,6.0,0.0,13.0,0.05,0.3,0.015,0.05,0.015,0.0009,0.0,0.0,0.0,0,0.0,0.0,0
Jacks Calcium Nitrate,Ca(NO3)2,Jack's Nutrients,1.0,15.5,0.0,0.0,0.0,0.0,19.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
Calcium Sulfate,CaSO4·2H2O,Generic,1.0,0.0,0.0,0.0,0.0,0.0,22.0,17.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Athena Pro Core,14-0-0,Athena,1.0,14.0,0.0,0.0,0.0,0.0,17.0,0.0,0.015,0.1,0.013,0.04,0.01,0.01,0.0,0.0,0.0,0,0.0,0.0,0
Athena Pro Grow,2-8-20,Athena,1.0,2.0,0.0,3.49,16.6,3.0,0.0,8.0,0.0,0.1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Athena Pro Bloom,0-12-24,Athena,1.0,0.0,0.0,5.24,19.92,3.0,0.0,9.0,0.0,0.1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Athena Grow A,4-0-1,Athena,1.0,3.8,0.2,0.0,0.83,0.19,4.2,0.0,0.01,0.06,0.0045,0.013,0.0,0.0007,0.0,0.0,0.0,1,1.0,0.0,0
Athena Grow B,1-3-5,Athena,1.0,0.2,0.8,1.31,4.15,0.89,0.0,1.3,0.0,0.0,0.0,0.0,0.005,0.0,0.0,0.0,0.0,1,1.0,0.0,0
Athena Bloom A,4-0-5,Athena,1.0,3.8,0.2,0.0,4.15,0.17,3.2,0.0,0.01,0.06,0.0045,0.013,0.0,0.0007,0.0,0.0,0.0,1,1.0,0.0,0
Athena Bloom B,0.7-6-5,Athena,1.0,0.5,0.2,2.62,4.15,0.94,0.0,1.3,0.0,0.0,0.0,0.0,0.005,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CropSalt Veg A,5-0-0.3,CropSalt,1.0,5.0,0.0,0.0,0.25,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
CropSalt Veg B,1.3-2-5.9,CropSalt,1.0,1.3,0.0,0.87,4.90,1.0,0.0,1.3,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
FloraFlex V1,14-0-4,FloraFlex,1.0,13.0,1.0,0.0,3.32,0.0,15.0,0.0,0.0,0.0,0.0,0.0,0.0,0.001,0.0,0.0,0.0,0,0.0,0.0,0
FloraFlex V2,6-17-25,FloraFlex,1.0,4.0,2.0,7.42,20.75,2.0,0.0,6.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
FloraFlex B1,14-0-22,FloraFlex,1.0,13.5,0.5,0.0,18.26,0.0,7.0,0.0,0.0,0.0,0.0,0.0,0.0,0.001,0.0,0.0,0.0,0,0.0,0.0,0
FloraFlex B2,0-28-18,FloraFlex,1.0,0.0,0.0,12.22,14.94,7.0,0.0,11.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
FloraFlex Bulky B,0-14-43,FloraFlex,1.0,0.0,0.0,6.11,35.69,1.0,0.0,11.0,0.0,0.0,0.0,0.0,0.0,0.001,1.0,0.0,0.0,0,0.0,0.0,0
FloraFlex Full Tilt,0-47-35,FloraFlex,1.0,0.0,0.0,20.51,29.05,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Front Row AG Part A,14-0-8,Front Row AG,1.0,14.0,0.0,0.0,6.64,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Front Row AG Part B,2-13-17,Front Row AG,1.0,2.0,0.0,5.67,14.11,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Front Row AG Bloom,0-35-29,Front Row AG,1.0,0.0,0.0,15.27,24.07,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
GH FloraMicro,5-0-1,General Hydroponics,1.0,4.7,0.3,0.0,0.83,0.0,5.0,0.0,0.01,0.1,0.015,0.05,0.01,0.0008,0.0,0.0,0.0,1,1.0,0.0,0
GH FloraGro,2-1-6,General Hydroponics,1.0,1.75,0.25,0.44,4.98,0.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
GH FloraBloom,0-5-4,General Hydroponics,1.0,0.0,0.0,2.18,3.32,1.5,0.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
GH CaliMagic,1-0-0,General Hydroponics,1.0,1.0,0.0,0.0,0.0,1.5,5.0,0.0,0.0,0.1,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
GH Armor Si,0-0-4,General Hydroponics,1.0,0.0,0.0,0.0,3.32,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,10.0,0.0,1,1.0,0.0,0
GH KoolBloom Liquid,0-10-10,General Hydroponics,1.0,0.0,0.0,4.36,8.30,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
GH KoolBloom Dry,2-45-28,General Hydroponics,1.0,0.0,2.0,19.64,23.24,1.0,0.0,1.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
CANNA Coco A,4-0-1,CANNA,1.0,4.0,0.0,0.0,0.83,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CANNA Coco B,0-4-2,CANNA,1.0,0.0,0.0,1.75,1.66,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CANNA PK 13/14,0-13-14,CANNA,1.0,0.0,0.0,5.67,11.62,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CANNA Mono Calcium,Calcium,CANNA,1.0,0.0,0.0,0.0,0.0,0.0,15.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CANNA Mono Magnesium,MgSO4,CANNA,1.0,0.0,0.0,0.0,0.0,9.8,0.0,12.9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
H&G Aqua Flakes A,3-0-2,House & Garden,1.0,3.0,0.0,0.0,1.66,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
H&G Aqua Flakes B,1-3-5,House & Garden,1.0,1.0,0.0,1.31,4.15,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
H&G Magnesium Boost,5-0-0,House & Garden,1.0,5.0,0.0,0.0,0.0,5.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
H&G CalMag Powder,12-0-0,House & Garden,1.0,11.9,0.1,0.0,0.0,3.0,10.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Calcium Nitrate 15-0-0,Ca(NO3)2,Generic,1.0,15.0,0.0,0.0,0.0,0.0,19.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
Magnesium Sulfate,MgSO4·7H2O,Generic,1.0,0.0,0.0,0.0,0.0,9.8,0.0,12.9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Mono Potassium Phosphate,KH2PO4,Generic,1.0,0.0,0.0,22.7,28.2,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
MasterBlend 4-18-38,4-18-38,MasterBlend,1.0,3.5,0.5,7.86,31.54,0.5,0.0,0.0,0.20,0.40,0.05,0.20,0.05,0.01,0.0,0.0,0.0,0,0.0,0.0,0
MasterBlend Calcium Nitrate,Ca(NO3)2,MasterBlend,1.0,15.5,0.0,0.0,0.0,0.0,19.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
MasterBlend Magnesium Sulfate,MgSO4·7H2O,MasterBlend,1.0,0.0,0.0,0.0,0.0,9.8,0.0,12.9,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Haifa Calcium Nitrate,Ca(NO3)2,Haifa,1.0,15.5,0.0,0.0,0.0,0.0,19.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
Haifa MKP,KH2PO4,Haifa,1.0,0.0,0.0,22.7,28.2,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Haifa MAP,NH4H2PO4,Haifa,1.0,0.0,12.0,26.6,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Haifa SOP,K2SO4,Haifa,1.0,0.0,0.0,0.0,41.5,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Yara Calcinit,Ca(NO3)2,Yara,1.0,15.5,0.0,0.0,0.0,0.0,26.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
Yara Krista MKP,KH2PO4,Yara,1.0,0.0,0.0,22.7,28.2,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Yara Krista MAP,NH4H2PO4,Yara,1.0,0.0,12.0,26.6,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Yara Krista SOP,K2SO4,Yara,1.0,0.0,0.0,0.0,42.3,0.0,0.0,18.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Impello Dune,Si(OH)4,Impello,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,2.2,0.0,1,1.0,0.0,0
Power Si Original,1-3-1,Power Si,1.0,1.0,0.0,1.31,0.83,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.008,0.0,2.21,0.0,1,1.0,0.0,0
Power Si Bloom,1-2-0.5,Power Si,1.0,0.8,0.0,0.87,0.42,0.0,0.0,0.0,0.007,0.0,0.3,0.0,0.0,0.0,0.0,0.66,0.0,1,1.0,0.0,0
RAW Silica,SiO2,NPK Industries,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,21.15,0.0,0,0.0,0.0,0
Dyna-Gro Pro-TeKt,0-0-3.7,Dyna-Gro,1.0,0.0,0.0,0.0,3.07,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,3.67,0.0,1,1.0,0.0,0
AgSil 16H,K-Silicate,PQ Corporation,1.0,0.0,0.0,0.0,26.56,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,24.44,0.0,0,0.0,0.0,0
Grotek Gro-Silic,Si(OH)4,Grotek,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.009,0.0,0.0,0.0,0.0,0.0015,0.0,44.0,0.0,1,1.0,0.0,0
Rhizoflora Terpinator,0-0-4,Rhizoflora,1.0,0.0,0.0,0.0,3.32,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.0,0.0,0
CSV_EOF
    fi
    
    # Create temporary Python script
    TEMP_SCRIPT="/tmp/hydrobuddy-add-fertilizers-$$.py"
    
    cat > "$TEMP_SCRIPT" << 'PYTHON_SCRIPT_EOF'
#!/usr/bin/env python3
"""
Add custom fertilizers to HydroBuddy database from CSV file
Reads fertilizer data from fertilizers.csv and adds them to the DBF database
"""

import struct
import os
import sys
import csv
from datetime import datetime


def format_string_field(value, length):
    """Format string field - left-aligned, space-padded"""
    return value[:length].ljust(length).encode('ascii', errors='replace')


def format_numeric_field(value):
    """Format numeric field - 18 bytes, right-aligned with 8 decimal places"""
    # Format as 18 characters with 8 decimals
    formatted = f"{float(value):18.8f}"
    return formatted.encode('ascii')


def create_fertilizer_record(name, formula, source, purity, nutrients, isliquid, density, cost, conctype):
    """
    Create a 681-byte DBF record
    
    nutrients dict should contain: N_NO3, N_NH4, P, K, Mg, Ca, S, B, Fe, Zn, Mn, Cu, Mo, Na, Si, Cl
    """
    record = bytearray(681)
    offset = 0
    
    # Deletion flag (space = active)
    record[offset] = 0x20
    offset += 1
    
    # Name (80 bytes)
    record[offset:offset+80] = format_string_field(name, 80)
    offset += 80
    
    # Formula (80 bytes)
    record[offset:offset+80] = format_string_field(formula, 80)
    offset += 80
    
    # Source (80 bytes)
    record[offset:offset+80] = format_string_field(source, 80)
    offset += 80
    
    # Numeric fields (each 18 bytes with 8 decimals)
    # Purity
    record[offset:offset+18] = format_numeric_field(purity)
    offset += 18
    
    # N (NO3-)
    record[offset:offset+18] = format_numeric_field(nutrients.get('N_NO3', 0))
    offset += 18
    
    # N (NH4+)
    record[offset:offset+18] = format_numeric_field(nutrients.get('N_NH4', 0))
    offset += 18
    
    # P
    record[offset:offset+18] = format_numeric_field(nutrients.get('P', 0))
    offset += 18
    
    # K
    record[offset:offset+18] = format_numeric_field(nutrients.get('K', 0))
    offset += 18
    
    # Mg
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mg', 0))
    offset += 18
    
    # Ca
    record[offset:offset+18] = format_numeric_field(nutrients.get('Ca', 0))
    offset += 18
    
    # S
    record[offset:offset+18] = format_numeric_field(nutrients.get('S', 0))
    offset += 18
    
    # B
    record[offset:offset+18] = format_numeric_field(nutrients.get('B', 0))
    offset += 18
    
    # Fe
    record[offset:offset+18] = format_numeric_field(nutrients.get('Fe', 0))
    offset += 18
    
    # Zn
    record[offset:offset+18] = format_numeric_field(nutrients.get('Zn', 0))
    offset += 18
    
    # Mn
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mn', 0))
    offset += 18
    
    # Cu
    record[offset:offset+18] = format_numeric_field(nutrients.get('Cu', 0))
    offset += 18
    
    # Mo
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mo', 0))
    offset += 18
    
    # Na
    record[offset:offset+18] = format_numeric_field(nutrients.get('Na', 0))
    offset += 18
    
    # Si
    record[offset:offset+18] = format_numeric_field(nutrients.get('Si', 0))
    offset += 18
    
    # Cl
    record[offset:offset+18] = format_numeric_field(nutrients.get('Cl', 0))
    offset += 18
    
    # isLiquid
    record[offset:offset+18] = format_numeric_field(isliquid)
    offset += 18
    
    # Density
    record[offset:offset+18] = format_numeric_field(density)
    offset += 18
    
    # Cost
    record[offset:offset+18] = format_numeric_field(cost)
    offset += 18
    
    # ConcType (remaining bytes - 240 bytes)
    remaining = 681 - offset
    record[offset:offset+remaining] = format_string_field(conctype, remaining)
    
    return bytes(record)


def fertilizer_exists(dbf_path, name):
    """Check if fertilizer with given name already exists"""
    with open(dbf_path, 'rb') as f:
        data = f.read()
    
    header_length = struct.unpack('<H', data[8:10])[0]
    record_length = struct.unpack('<H', data[10:12])[0]
    num_records = struct.unpack('<I', data[4:8])[0]
    
    for i in range(num_records):
        offset = header_length + (i * record_length)
        record = data[offset:offset + record_length]
        if record[0] == 0x2A:  # Deleted record
            continue
        record_name = record[1:81].decode('ascii', errors='ignore').strip()
        if record_name.lower() == name.lower():
            return True
    return False


def load_fertilizers_from_csv(csv_path):
    """Load fertilizers from CSV file"""
    fertilizers = []
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                # Convert string values to appropriate types
                fert = {
                    'name': row['Name'],
                    'formula': row['Formula'],
                    'source': row['Source'],
                    'purity': float(row['Purity']),
                    'nutrients': {
                        'N_NO3': float(row['N_NO3']),
                        'N_NH4': float(row['N_NH4']),
                        'P': float(row['P']),
                        'K': float(row['K']),
                        'Mg': float(row['Mg']),
                        'Ca': float(row['Ca']),
                        'S': float(row['S']),
                        'B': float(row['B']),
                        'Fe': float(row['Fe']),
                        'Zn': float(row['Zn']),
                        'Mn': float(row['Mn']),
                        'Cu': float(row['Cu']),
                        'Mo': float(row['Mo']),
                        'Na': float(row['Na']),
                        'Si': float(row['Si']),
                        'Cl': float(row['Cl'])
                    },
                    'isliquid': int(row['isLiquid']),
                    'density': float(row['Density']),
                    'cost': float(row['Cost']),
                    'conctype': row['ConcType']
                }
                fertilizers.append(fert)
        
        return fertilizers
    except Exception as e:
        print(f"  ❌ Error reading CSV file: {e}")
        return []


def add_fertilizers_to_db(dbf_path, fertilizers):
    """Add fertilizers to database"""
    
    print(f"\n📊 Adding fertilizers to: {os.path.basename(dbf_path)}")
    
    if not os.path.exists(dbf_path):
        print(f"  ⚠️  File not found, skipping")
        return False
    
    if not fertilizers:
        print(f"  ⚠️  No fertilizers to add")
        return False
    
    try:
        # Read existing database
        with open(dbf_path, 'rb') as f:
            data = bytearray(f.read())
        
        original_size = len(data)
        num_records = struct.unpack('<I', data[4:8])[0]
        header_length = struct.unpack('<H', data[8:10])[0]
        record_length = struct.unpack('<H', data[10:12])[0]
        
        print(f"  ✓ Read database: {num_records} records, {record_length} bytes each")
        print(f"  ✓ Loaded {len(fertilizers)} fertilizer(s) from CSV")
        
        added_count = 0
        for fert in fertilizers:
            if fertilizer_exists(dbf_path, fert['name']):
                print(f"  ℹ️  '{fert['name']}' already exists, skipping")
            else:
                # Create new record
                new_record = create_fertilizer_record(
                    fert['name'],
                    fert['formula'],
                    fert['source'],
                    fert['purity'],
                    fert['nutrients'],
                    fert['isliquid'],
                    fert['density'],
                    fert['cost'],
                    fert['conctype']
                )
                
                # Remove EOF marker if present
                if data[-1] == 0x1A:
                    data = data[:-1]
                
                # Append new record
                data.extend(new_record)
                num_records += 1
                print(f"  ✓ Added '{fert['name']}'")
                added_count += 1
        
        if added_count > 0:
            # Update header with new record count
            data[4:8] = struct.pack('<I', num_records)
            
            # Update date
            today = datetime.now()
            data[1] = today.year - 1900
            data[2] = today.month
            data[3] = today.day
            
            # Add EOF marker
            data.append(0x1A)
            
            # Create backup
            backup_path = f"{dbf_path}.backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
            os.rename(dbf_path, backup_path)
            print(f"  ✓ Backup created: {os.path.basename(backup_path)}")
            
            # Write modified database
            with open(dbf_path, 'wb') as f:
                f.write(data)
            
            print(f"  ✓ {added_count} fertilizer(s) added successfully!")
            return True
        else:
            print(f"  ℹ️  No new fertilizers added")
            return False
            
    except Exception as e:
        print(f"  ❌ Error: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Main function"""
    print("=" * 70)
    print("HydroBuddy - Add Custom Fertilizers from CSV")
    print("=" * 70)
    
    if len(sys.argv) < 2:
        print("\nUsage: add-fertilizers.py <hydrobuddy-folder> [csv-file]")
        print("\nExamples:")
        print("  ./add-fertilizers.py /Applications/HydroBuddy")
        print("  ./add-fertilizers.py /Applications/HydroBuddy fertilizers.csv")
        sys.exit(1)
    
    base_path = sys.argv[1]
    
    if not os.path.isdir(base_path):
        print(f"\n❌ Error: Directory not found: {base_path}")
        sys.exit(1)
    
    # Determine CSV file path
    if len(sys.argv) >= 3:
        csv_path = sys.argv[2]
    else:
        # Default: look for fertilizers.csv in same directory as script
        script_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(script_dir, 'fertilizers.csv')
    
    if not os.path.exists(csv_path):
        print(f"\n❌ Error: CSV file not found: {csv_path}")
        print("\nExpected CSV format:")
        print("  Name,Formula,Source,Purity,N_NO3,N_NH4,P,K,Mg,Ca,S,B,Fe,Zn,Mn,Cu,Mo,Na,Si,Cl,isLiquid,Density,Cost,ConcType")
        sys.exit(1)
    
    print(f"\nBase directory: {base_path}")
    print(f"CSV file: {csv_path}")
    
    # Load fertilizers from CSV
    fertilizers = load_fertilizers_from_csv(csv_path)
    
    if not fertilizers:
        print("\n❌ Error: No fertilizers loaded from CSV")
        sys.exit(1)
    
    # Detect platform
    unix_db = os.path.join(base_path, "substances_unix.dbf")
    win_db = os.path.join(base_path, "substances_win.dbf")
    
    if os.path.exists(unix_db):
        substances_db = unix_db
        print("Platform: Unix/macOS")
    elif os.path.exists(win_db):
        substances_db = win_db
        print("Platform: Windows")
    else:
        print("\n❌ Error: Could not find substances database")
        sys.exit(1)
    
    # Add fertilizers
    any_changes = add_fertilizers_to_db(substances_db, fertilizers)
    
    print("\n" + "=" * 70)
    if any_changes:
        print("✅ Fertilizers added successfully!")
        print("\nAdded fertilizers:")
        for fert in fertilizers:
            if not fertilizer_exists(substances_db, fert['name']) or any_changes:
                print(f"  • {fert['name']}")
    else:
        print("✅ All fertilizers already exist in database")
    print("=" * 70)


if __name__ == "__main__":
    main()
PYTHON_SCRIPT_EOF
    
    # Run the temporary script with CSV file
    python3 "$TEMP_SCRIPT" "$APP_MACOS_DIR" "$CSV_TO_USE" && {
        # Success! Now create fertilizers.csv in current folder for future edits
        OUTPUT_CSV="$SCRIPT_DIR/fertilizers.csv"
        
        # Create the CSV in the same folder as the installer if it doesn't exist
        # (Don't overwrite if user already has a custom one)
        if [ ! -f "$OUTPUT_CSV" ]; then
            cp "$CSV_TO_USE" "$OUTPUT_CSV"
            echo ""
            echo "  ✓ Created fertilizers.csv (58 fertilizers)"
            echo "    Edit this file and re-run the installer to add more!"
        fi
    } || {
        echo "⚠️  Warning: Failed to add fertilizers, but installation will continue"
        echo ""
    }
    
    # Clean up temporary files
    rm -f "$TEMP_SCRIPT"
    # Only remove CSV if it was created from embedded data (in /tmp)
    if [[ "$CSV_TO_USE" == /tmp/* ]]; then
        rm -f "$CSV_TO_USE"
    fi
else
    echo "⚠️  Python 3 not found - skipping fertilizer addition"
    echo ""
fi

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
