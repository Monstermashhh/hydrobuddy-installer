# HydroBuddy macOS Installer - Quick Start Guide

## What Is This?

A simple installer that fixes HydroBuddy on macOS by removing Apple's security blocks and configuring automatic database detection.

## Why Is This Needed?

HydroBuddy is excellent free software for hydroponic nutrient calculations, but on macOS:

1. **Apple blocks it** - macOS Gatekeeper prevents unsigned apps from running
2. **Database files aren't found** - You have to manually locate database files every time you launch

This installer fixes both problems automatically.

## How to Use It

### Step 1: Download

Download `install-hydrobuddy.command` from this release page (see Assets below).

### Step 2: Place the File

Put `install-hydrobuddy.command` in the **same folder** as your `HydroBuddy.app`.

### Step 3: Run the Installer

Double-click `install-hydrobuddy.command` and follow the prompts.

**Note:** If the script doesn't have execute permissions, it will automatically fix itself or show you the exact command to run in Terminal.

The installer will:

- Move HydroBuddy to your Applications folder
- Remove Apple's security blocks
- Configure automatic database detection
- Launch the app

### Step 4: First Launch Security Prompt

The first time you open HydroBuddy, macOS will still show a security warning. This is normal! To allow it:

1. Go to **System Settings** → **Privacy & Security**
2. Scroll down to the **Security** section
3. Click **"Open Anyway"** next to the HydroBuddy message
4. Click **"Open"** to confirm

After this one-time approval, HydroBuddy will open normally every time.

## That's It!

HydroBuddy is now installed and ready to use. Launch it from your Applications folder.

---

## Troubleshooting

### Permission Issues

If you get a message about execute permissions:

1. The script will show you the exact Terminal command to run
2. Copy and paste that command into Terminal
3. Try running the script again

The script has built-in permission fixing, so this should only happen once (if at all).

---

**Need more help?** See the full [README](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/README.md) for detailed documentation and troubleshooting.

**System Requirements:** macOS 10.8 (Mountain Lion) or later
