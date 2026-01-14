# HydroBuddy macOS Installer v1.0.0

A simple installer that makes HydroBuddy work seamlessly on macOS by fixing quarantine issues and auto-detecting database files.

## 🚀 Quick Start

**For most users:**

1. **Download** `install-hydrobuddy.command` (below)
2. **Drag** it into your HydroBuddy folder (next to `hydrobuddy.app`)
3. **Double-click** it
4. Follow the on-screen instructions

That's it! HydroBuddy will be installed with 4 bonus fertilizers already in the database.

## ✨ What's Included

### Default Fertilizers

This installer automatically adds these fertilizers to your database:
- **Jack's 5-12-26 Part A** - Complete NPK blend with micronutrients
- **Jack's 0-12-26 Part A** - PK blend without nitrogen
- **Jack's Calcium Nitrate** - High-quality calcium and nitrogen source (Part B)
- **Calcium Sulfate (Gypsum)** - Calcium and sulfur supplement

### Features

- ✅ Removes macOS quarantine flags
- ✅ Configures automatic database detection
- ✅ Adds custom fertilizers to database
- ✅ Works with macOS 10.8+ through macOS 15+ (Sequoia)
- ✅ Creates automatic backups
- ✅ No manual folder selection needed after install

## 🧪 Adding Your Own Fertilizers (Optional)

Want to add more fertilizers? It's easy!

### Method 1: Using the Installer (Recommended)

1. **Download** `fertilizers.csv` (below)
2. **Edit** it to add your fertilizers:
   ```csv
   Name,Formula,Source,Purity,N_NO3,N_NH4,P,K,Mg,Ca,S,B,Fe,Zn,Mn,Cu,Mo,Na,Si,Cl,isLiquid,Density,Cost,ConcType
   My Fertilizer,NPK,My Brand,1.0,10.0,0.0,5.24,21.58,3.0,0.0,2.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
   ```
3. **Place** `fertilizers.csv` next to `install-hydrobuddy.command`
4. **Run** `install-hydrobuddy.command` again
5. **Restart** HydroBuddy - your fertilizers will be there!

### Method 2: Advanced Users

Use the standalone Python script:
```bash
python3 add-fertilizers.py /Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS fertilizers.csv
```

### Need Help?

- **[Adding Fertilizers Guide](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/ADDING-FERTILIZERS.md)** - Complete tutorial with examples
- **[CSV Template](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/fertilizers.csv)** - Pre-configured with Jack's nutrients
- **[NPK Conversion Calculator](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/ADDING-FERTILIZERS.md#important-converting-npk-values)** - P₂O₅ → P and K₂O → K formulas

## 📥 Download

### Required Files

**Everyone needs this:**
- **`install-hydrobuddy.command`** - The main installer script

### Optional Files

**Download if you want to add custom fertilizers:**
- **`fertilizers.csv`** - Template for adding your own fertilizers
- **`add-fertilizers.py`** - Standalone script (advanced users)

## 🛠️ Troubleshooting

### "Cannot be opened because the developer cannot be verified"

This is normal on first launch:

1. Go to **System Settings** > **Privacy & Security**
2. Scroll to the **Security** section
3. Click **"Open Anyway"** next to the HydroBuddy message
4. Click **"Open"** to confirm

### Database files not auto-detected

The installer configures this automatically. If you still need to select folders manually, try running the installer again.

### Fertilizers not appearing

1. Make sure you restarted HydroBuddy after installation
2. Check that `fertilizers.csv` was in the same folder as the installer
3. Look for "✓ Added [fertilizer name]" in the installer output

### More Help

See the [Installation Guide](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/INSTALLATION-GUIDE.md) or [open an issue](https://github.com/Monstermashhh/hydrobuddy-installer/issues).

## 📚 Documentation

- **[README](https://github.com/Monstermashhh/hydrobuddy-installer)** - Full project overview
- **[Installation Guide](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/INSTALLATION-GUIDE.md)** - Detailed step-by-step instructions
- **[Adding Fertilizers Guide](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/ADDING-FERTILIZERS.md)** - How to customize your fertilizer database
- **[DBF Structure Reference](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/docs/DBF-STRUCTURE-REFERENCE.md)** - Technical documentation

## 🙏 Credits

- **[HydroBuddy](https://github.com/danielfppps/hydrobuddy)** by Dr. Daniel Fernandez - The excellent hydroponic calculator this installer supports
- Built with **[Cursor AI](https://cursor.sh)** - An AI-powered code editor

## ⚠️ Important Notes

- This installer is **not affiliated with** the official HydroBuddy project
- Always keep backups of your important data
- The installer creates automatic database backups before making changes
- Use at your own risk

## 📄 License

MIT License - See [LICENSE](https://github.com/Monstermashhh/hydrobuddy-installer/blob/main/LICENSE) file for details

---

**Questions?** [Open an issue](https://github.com/Monstermashhh/hydrobuddy-installer/issues) or check the [documentation](https://github.com/Monstermashhh/hydrobuddy-installer).
