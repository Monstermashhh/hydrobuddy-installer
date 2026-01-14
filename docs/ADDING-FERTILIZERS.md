# Adding Custom Fertilizers to HydroBuddy

This guide explains how to add your own custom fertilizers to HydroBuddy's database using the CSV import system.

## Quick Start

### Option 1: Re-run Installer (Easiest!)

1. Copy `fertilizers.csv` to the same folder as `install-hydrobuddy.command`
2. Edit `fertilizers.csv` to add your fertilizers  
3. **Double-click `install-hydrobuddy.command` again**
4. Restart HydroBuddy - your fertilizers will be available!

The installer automatically detects and uses your custom CSV!

### Option 2: Standalone Script

1. Edit `fertilizers.csv` to add your fertilizers
2. Run the script: `python3 add-fertilizers.py /Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS fertilizers.csv`
3. Restart HydroBuddy - your fertilizers will be available!

## CSV Format

The `fertilizers.csv` file has the following columns:

| Column | Description | Example | Notes |
|--------|-------------|---------|-------|
| Name | Fertilizer name | `Jacks 5-12-26 Part A` | Max 80 characters |
| Formula | Chemical formula | `NPK blend` | Max 80 characters |
| Source | Manufacturer | `Jack's Nutrients` | Max 80 characters |
| Purity | Purity percentage | `1.0` | Usually 1.0 (100%) |
| N_NO3 | Nitrate nitrogen % | `5.0` | Elemental % |
| N_NH4 | Ammonium nitrogen % | `0.0` | Elemental % |
| P | Phosphorus % | `5.24` | **Elemental P** (not P₂O₅) |
| K | Potassium % | `21.58` | **Elemental K** (not K₂O) |
| Mg | Magnesium % | `6.3` | Elemental % |
| Ca | Calcium % | `19.0` | Elemental % |
| S | Sulfur % | `8.5` | Elemental % |
| B | Boron % | `0.05` | Elemental % |
| Fe | Iron % | `0.3` | Elemental % |
| Zn | Zinc % | `0.015` | Elemental % |
| Mn | Manganese % | `0.05` | Elemental % |
| Cu | Copper % | `0.015` | Elemental % |
| Mo | Molybdenum % | `0.019` | Elemental % |
| Na | Sodium % | `0.0` | Elemental % |
| Si | Silicon % | `0.0` | Elemental % |
| Cl | Chlorine % | `0.0` | Elemental % |
| isLiquid | Is liquid? | `0` | 0 = solid, 1 = liquid |
| Density | Density g/mL | `0.0` | For liquids only |
| Cost | Cost per kg/L | `0.0` | Optional |
| ConcType | Concentration type | `0` | 0 = standard, 1 = Part B (two-part systems) |

## Important: Converting NPK Values

Fertilizer labels typically show **P₂O₅** and **K₂O** values, but HydroBuddy needs **elemental** values.

### Converting P₂O₅ to Elemental P

**Formula:** `P (elemental) = P₂O₅ × 0.4364`

**Example:** Jack's 5-12-26
- Label shows: 12% P₂O₅
- Convert: 12 × 0.4364 = **5.24% P** ✓

### Converting K₂O to Elemental K

**Formula:** `K (elemental) = K₂O × 0.8301`

**Example:** Jack's 5-12-26
- Label shows: 26% K₂O
- Convert: 26 × 0.8301 = **21.58% K** ✓

### Nitrogen (N)

Nitrogen is usually already shown as elemental on labels, but pay attention to the form:
- **N (NO₃⁻)** - Nitrate nitrogen (fast-acting)
- **N (NH₄⁺)** - Ammonium nitrogen (slow-release)

Most fertilizers specify the form. If not specified, assume it's nitrate.

## Example: Adding a New Fertilizer

Let's say you want to add "Masterblend 4-18-38":

### Step 1: Get the label information
- NPK: 4-18-38
- Mg: 3%
- S: 2%
- B: 0.02%
- Fe: 0.1%
- Mn: 0.05%
- Zn: 0.05%
- Cu: 0.05%
- Mo: 0.0009%

### Step 2: Convert P and K
- P: 18 × 0.4364 = 7.86%
- K: 38 × 0.8301 = 31.54%

### Step 3: Add to CSV

```csv
Masterblend 4-18-38,NPK blend,Masterblend,1.0,4.0,0.0,7.86,31.54,3.0,0.0,2.0,0.02,0.1,0.05,0.05,0.05,0.0009,0.0,0.0,0.0,0,0.0,0.0,0
```

### Step 4: Run the script

```bash
python3 add-fertilizers.py /Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS
```

Replace `X.XXX` with your actual HydroBuddy version number.

## Two-Part Systems (A/B Solutions)

For fertilizers that are part of a two-part system (like Part A and Part B), use the `ConcType` field:

- **ConcType = 0**: Standard fertilizer (can be mixed with anything)
- **ConcType = 1**: Part B (HydroBuddy will keep it in a separate tank)

**Example:** Jack's Calcium Nitrate is typically used as Part B because calcium can precipitate with phosphates/sulfates:

```csv
Jacks Calcium Nitrate,Ca(NO3)2,Jack's Nutrients,1.0,15.5,0.0,0.0,0.0,0.0,19.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
```

Note the `1` at the end (ConcType = 1).

## Liquid Fertilizers

For liquid fertilizers, set `isLiquid = 1` and provide the density:

```csv
General Hydroponics FloraGrow,Liquid NPK,General Hydroponics,1.0,2.0,0.0,0.22,2.65,0.0,0.0,0.0,0.0,0.13,0.0,0.0,0.0,0.0,0.0,0.0,0.0,1,1.08,0.0,0
```

## Tips

1. **Always make a backup** - The script automatically creates backups, but you can also manually backup the database file
2. **Test with one fertilizer first** - Make sure it works before adding many
3. **Use consistent naming** - Makes it easier to find fertilizers in the list
4. **Check for duplicates** - The script will skip fertilizers that already exist (matched by name)
5. **Restart HydroBuddy** - You must restart the app to see new fertilizers

## Troubleshooting

### "Fertilizer already exists"
The database already has a fertilizer with that exact name. Either:
- Use a different name
- Delete the existing one in HydroBuddy first

### "CSV file not found"
Make sure `fertilizers.csv` is in the same directory as `add-fertilizers.py`, or specify the full path:

```bash
python3 add-fertilizers.py /path/to/hydrobuddy /path/to/fertilizers.csv
```

### "Values don't match the label"
- Double-check your P and K conversions (× 0.4364 and × 0.8301)
- Make sure you're using elemental percentages, not oxide forms
- Verify the purity is set correctly (usually 1.0)

## CSV Template

Here's a blank template you can use:

```csv
Name,Formula,Source,Purity,N_NO3,N_NH4,P,K,Mg,Ca,S,B,Fe,Zn,Mn,Cu,Mo,Na,Si,Cl,isLiquid,Density,Cost,ConcType
My Fertilizer,Chemical Formula,Manufacturer,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
```

## Advanced: Batch Import

You can add many fertilizers at once. Just add multiple rows to the CSV:

```csv
Name,Formula,Source,Purity,N_NO3,N_NH4,P,K,Mg,Ca,S,B,Fe,Zn,Mn,Cu,Mo,Na,Si,Cl,isLiquid,Density,Cost,ConcType
Fertilizer 1,Formula 1,Source 1,1.0,5.0,0.0,2.0,10.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Fertilizer 2,Formula 2,Source 2,1.0,0.0,0.0,8.0,32.0,5.0,0.0,3.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,0
Fertilizer 3,Formula 3,Source 3,1.0,15.0,0.0,0.0,0.0,0.0,20.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0,0.0,0.0,1
```

The script will process all rows and skip any that already exist.

---

## Quick Reference Card

### Conversion Formulas
```
P (elemental) = P₂O₅ × 0.4364
K (elemental) = K₂O × 0.8301
```

### Common Values
- **Purity:** Usually `1.0` (100%)
- **isLiquid:** `0` for powders, `1` for liquids
- **ConcType:** `0` for standard, `1` for Part B
- **Empty nutrients:** Use `0.0` for nutrients not present

### Database Location (macOS)
```
/Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS/substances_unix.dbf
```

---

**Need help?** Check the [DBF Structure Reference](DBF-STRUCTURE-REFERENCE.md) for technical details.
