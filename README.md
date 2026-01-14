# HydroBuddy macOS Installer

A simple installer script that enables users on macOS 10.8+ to use HydroBuddy by removing quarantine flags and configuring automatic database file detection.

[![macOS](https://img.shields.io/badge/macOS-10.8+-blue.svg)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

## 🌟 What This Solves

HydroBuddy, created by Dr. Daniel Fernandez, is excellent free, open-source software for hydroponic nutrient calculations. However, on macOS it faces two challenges:

1. **macOS Gatekeeper blocks it** - Apple requires a $99/year developer certificate to sign apps, which isn't feasible for free software
2. **Database files aren't auto-detected** - Users have to manually locate database files on every launch

This installer fixes both issues automatically.

## ✨ Features

- ✅ **One-file installation** - Just drag and drop a single file!
- ✅ **Custom fertilizers included** - Automatically adds Jack's nutrients and Calcium Sulfate to database
- ✅ Script auto-fixes permissions if needed
- ✅ Validates application bundle integrity
- ✅ Checks for required database files
- ✅ Moves HydroBuddy to Applications folder
- ✅ Configures automatic database file detection
- ✅ Removes macOS quarantine flags
- ✅ Creates backup launcher script
- ✅ Comprehensive error handling and logging
- ✅ Works with macOS 10.8 (Mountain Lion) through macOS 15 (Sequoia) and later

## 📋 Prerequisites

- macOS 10.8 (Mountain Lion) or later

## 🚀 Quick Start

**It's this simple:**

1. Download the ZIP from [Releases](https://github.com/Monstermashhh/hydrobuddy-installer/releases)
2. Unzip and drag `install-hydrobuddy.command` into your HydroBuddy folder
3. Double-click the file
4. Done! 🎉

The installer will:
- Install HydroBuddy to Applications
- Configure database auto-detection
- Add custom fertilizers (Jack's nutrients, Calcium Sulfate)
- Launch the app

See [troubleshooting](#-troubleshooting) if you encounter any issues.

## 🚀 Installation

### Method 1: Download Release (Recommended)

1. Download the latest release from the [Releases](https://github.com/Monstermashhh/hydrobuddy-installer/releases) page
2. Extract the ZIP file
3. Place `install-hydrobuddy.command` in the same folder as `HydroBuddy.app`
4. Double-click `install-hydrobuddy.command`
   - The script will automatically fix its own permissions if needed
5. Follow the on-screen instructions (see [troubleshooting](#-troubleshooting) section for issues)

### Method 2: Clone Repository

```bash
# Clone the repository
git clone https://github.com/Monstermashhh/hydrobuddy-installer.git

# Copy the installer to your HydroBuddy folder
cp hydrobuddy-installer/install-hydrobuddy.command /path/to/your/hydrobuddy/folder/

# Run the installer (permissions are auto-fixed on first run)
cd /path/to/your/hydrobuddy/folder/
./install-hydrobuddy.command
```

**Note:** If cloning from git, the script already has execute permissions. If downloading directly, the script will automatically fix its own permissions when run.

## 📖 Usage

### Running the Installer

1. **Place the script** in the same directory as your `HydroBuddy.app` folder
2. **Double-click** `install-hydrobuddy.command`
3. **Follow the prompts** - the installer will:
   - Validate your HydroBuddy installation
   - Check for database files
   - Move everything to `/Applications`
   - Configure auto-detection
   - Launch the app

### After Installation

Launch HydroBuddy using either method:

**Method 1 (Recommended):** Double-click `hydrobuddy.app` in Applications  
**Method 2 (Alternative):** Double-click `Launch-HydroBuddy.command`

Both methods automatically detect database files - no manual folder selection needed!

## 🧪 Adding More Fertilizers

### Method 1: Re-run Installer with Custom CSV (Easiest!)

1. Download/copy [`docs/fertilizers.csv`](docs/fertilizers.csv) to the same folder as `install-hydrobuddy.command`
2. Edit `fertilizers.csv` - add your fertilizers (see [guide](docs/ADDING-FERTILIZERS.md))
3. **Double-click `install-hydrobuddy.command` again**
4. Done! ✨ The installer will update your database with the new fertilizers

**The installer automatically detects `fertilizers.csv` in its folder and uses it instead of defaults!**

### Method 2: Standalone Script (Advanced)

If you've already installed HydroBuddy:

1. Edit [`docs/fertilizers.csv`](docs/fertilizers.csv)
2. Run:
   ```bash
   python3 docs/add-fertilizers.py /Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS fertilizers.csv
   ```
3. Restart HydroBuddy

**Includes automatic P₂O₅ → P and K₂O → K conversion guide!**

See the [Adding Fertilizers Guide](docs/ADDING-FERTILIZERS.md) for complete instructions and examples.

## 🔧 What the Installer Does

### 1. Validation

- Checks macOS version compatibility
- Validates the app bundle structure
- Verifies database files (warns if missing)

### 2. Installation

- Moves the entire HydroBuddy folder to `/Applications`
- Creates backups of existing installations
- Removes Apple's quarantine flags from all files

### 3. Configuration

- Creates a wrapper script that sets the correct working directory
- Ensures database files are auto-detected on launch
- Generates an alternative launcher as backup

### 4. Database Customization

- Automatically adds custom fertilizers to the database:
  - Jack's 5-12-26 Part A
  - Jack's 0-12-26 Part A
  - Jack's Calcium Nitrate (15.5-0-0)
  - Calcium Sulfate (Gypsum)
- Creates backups before making any database changes

### 5. Launch

- Opens Finder to show installation location
- Launches HydroBuddy automatically

## 🐛 Troubleshooting

### "Cannot be opened because the developer cannot be verified"

This is normal on first launch. To fix:

1. Go to **System Settings** > **Privacy & Security**
2. Scroll to the **Security** section
3. Click **"Open Anyway"** next to the HydroBuddy message
4. Click **"Open"** to confirm

### "This script needs execute permissions"

If you see this message when trying to run the installer, don't worry! The script has detected it doesn't have execute permissions and will show you the exact command to run. Simply:

1. Open Terminal
2. Run the command shown in the error message
3. Double-click the script again

Alternatively, the script will attempt to fix its own permissions automatically.

### "App is damaged and can't be opened"

If you see this error, run in Terminal:

```bash
sudo xattr -cr /Applications/YourHydroBuddyFolder/
```

Replace `YourHydroBuddyFolder` with your actual folder name.

### Database Files Not Found

The installer will warn you if database files are missing. You can:

- Redownload a fresh copy of HydroBuddy and try again (recommended)
- Continue installation (HydroBuddy will prompt for files on launch)

## 📚 Documentation

- **[Installation Guide](docs/INSTALLATION-GUIDE.md)** - Detailed step-by-step instructions
- **[Adding Fertilizers Guide](docs/ADDING-FERTILIZERS.md)** - How to add your own custom fertilizers using CSV
- **[fertilizers.csv](docs/fertilizers.csv)** - CSV template for custom fertilizers
- **[add-fertilizers.py](docs/add-fertilizers.py)** - Standalone script for adding fertilizers (embedded in installer)
- **[DBF Structure Reference](docs/DBF-STRUCTURE-REFERENCE.md)** - Technical documentation for database format

## 📝 Technical Details

### How It Works

The installer modifies the HydroBuddy app bundle by:

1. Renaming the original executable: `hydrobuddy` → `hydrobuddy-bin`
2. Creating a wrapper script that:
   - Changes to the app bundle's parent directory
   - Launches the renamed executable
   - This ensures database files in the same folder are detected

### Files Modified

- `hydrobuddy.app/Contents/MacOS/hydrobuddy` - becomes wrapper script
- `hydrobuddy.app/Contents/MacOS/hydrobuddy-bin` - original executable
- `Launch-HydroBuddy.command` - alternative launcher (created during install)

### Quarantine Removal

HydroBuddy often can't open on macOS due to Apple's security system called Gatekeeper. Here's what's happening:

**The Problem:**

- When you download HydroBuddy from the internet, macOS automatically marks it as "quarantined"
- macOS expects apps to be digitally signed with an Apple Developer certificate
- This certificate costs $99/year - which isn't practical for free, open-source software like HydroBuddy
- Without the signature, macOS blocks the app with messages like "cannot be opened because the developer cannot be verified" or "damaged and can't be opened"

**The Solution:**
This installer removes the quarantine flags (using the command `xattr -cr`) which tells macOS that you trust this application. It's the same as what happens when you manually approve an app in System Settings, but automated for all the HydroBuddy files at once.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

This installer is not affiliated with or endorsed by the HydroBuddy project. It's a community tool to help macOS users run HydroBuddy more easily.

**Use at your own risk.** The script modifies your HydroBuddy installation. Always keep backups of important data.

## 🤖 Built With AI

This project was created with the assistance of **[Cursor AI](https://cursor.sh)**, an AI-powered code editor. The entire installer script, documentation, and project structure were developed through an iterative collaboration with AI.

## 🙏 Acknowledgments

- **HydroBuddy**
- The most excellent hydroponic calculator software this installer supports
- The open-source community for making projects like this possible

## 🔗 Related Links

- [HydroBuddy GitHub Repository](https://github.com/danielfppps/hydrobuddy)
- [HydroBuddy Official Website](https://scienceinhydroponics.com/2016/08/the-first-free-hydroponic-nutrient-calculator-program-o.html)
- [HydroBuddy Downloads](https://scienceinhydroponics.com/p/hydrobuddy.html)

---
