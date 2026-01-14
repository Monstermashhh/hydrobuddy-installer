# HydroBuddy Database Structure Reference

## Overview

HydroBuddy uses dBase III (DBF) format files to store substance/fertilizer data:

- **macOS/Unix:** `substances_unix.dbf`
- **Windows:** `substances_win.dbf`

Each record is **681 bytes** and contains information about a single fertilizer or substance.

## DBF File Structure

### Header

- **Bytes 0-3:** File signature and version
- **Bytes 4-7:** Number of records (32-bit little-endian integer)
- **Bytes 8-9:** Header length (16-bit little-endian integer)
- **Bytes 10-11:** Record length (16-bit little-endian integer, always 681)

### Records

Records start at the header length offset. Each record is 681 bytes.

## Complete Record Layout (681 bytes)

| Byte Range | Length | Field Name    | Type    | Format                            | Notes                        |
| ---------- | ------ | ------------- | ------- | --------------------------------- | ---------------------------- |
| 0          | 1      | Deletion Flag | Binary  | `0x20` = active, `0x2A` = deleted | Space char = active          |
| 1-80       | 80     | Name          | String  | Left-aligned, space-padded        | Fertilizer name              |
| 81-160     | 80     | Formula       | String  | Left-aligned, space-padded        | Chemical formula             |
| 161-240    | 80     | Source        | String  | Left-aligned, space-padded        | Manufacturer/supplier        |
| 241-258    | 18     | Purity        | Numeric | Right-aligned, 8 decimals         | Usually 1.0 (100%)           |
| 259-276    | 18     | N (NO₃⁻)      | Numeric | Right-aligned, 8 decimals         | Nitrate nitrogen %           |
| 277-294    | 18     | N (NH₄⁺)      | Numeric | Right-aligned, 8 decimals         | Ammonium nitrogen %          |
| 295-312    | 18     | P             | Numeric | Right-aligned, 8 decimals         | Phosphorus % (elemental)     |
| 313-330    | 18     | K             | Numeric | Right-aligned, 8 decimals         | Potassium % (elemental)      |
| 331-348    | 18     | Mg            | Numeric | Right-aligned, 8 decimals         | Magnesium %                  |
| 349-366    | 18     | Ca            | Numeric | Right-aligned, 8 decimals         | Calcium %                    |
| 367-384    | 18     | S             | Numeric | Right-aligned, 8 decimals         | Sulfur %                     |
| 385-402    | 18     | B             | Numeric | Right-aligned, 8 decimals         | Boron %                      |
| 403-420    | 18     | Fe            | Numeric | Right-aligned, 8 decimals         | Iron %                       |
| 421-438    | 18     | Zn            | Numeric | Right-aligned, 8 decimals         | Zinc %                       |
| 439-456    | 18     | Mn            | Numeric | Right-aligned, 8 decimals         | Manganese %                  |
| 457-474    | 18     | Cu            | Numeric | Right-aligned, 8 decimals         | Copper %                     |
| 475-492    | 18     | Mo            | Numeric | Right-aligned, 8 decimals         | Molybdenum %                 |
| 493-510    | 18     | Na            | Numeric | Right-aligned, 8 decimals         | Sodium %                     |
| 511-528    | 18     | Si            | Numeric | Right-aligned, 8 decimals         | Silicon %                    |
| 529-546    | 18     | Cl            | Numeric | Right-aligned, 8 decimals         | Chlorine %                   |
| 547-564    | 18     | isLiquid      | Numeric | Right-aligned, 8 decimals         | 0 = solid, 1 = liquid        |
| 565-582    | 18     | Density       | Numeric | Right-aligned, 8 decimals         | Density (g/mL for liquids)   |
| 583-600    | 18     | Cost          | Numeric | Right-aligned, 8 decimals         | Cost per kg/L                |
| 601-680    | 80     | ConcType      | String  | Left-aligned, space-padded        | '0' = standard, '1' = Part B |

**Total: 681 bytes**

## Field Format Details

### String Fields (Name, Formula, Source, ConcType)

- Left-aligned
- Space-padded to fill the entire field width
- ASCII encoded
- Example: `"Jacks 5-12-26 Part A"` becomes `"Jacks 5-12-26 Part A" + (60 spaces)`

### Numeric Fields (All nutrient values, purity, etc.)

- **Width:** Exactly 18 bytes
- **Format:** Right-aligned with 8 decimal places
- **Encoding:** ASCII text representation of the number
- **Examples:**
  - `5.0` → `"        5.00000000"` (8 leading spaces)
  - `15.5` → `"       15.50000000"` (7 leading spaces)
  - `0.015` → `"        0.01500000"` (8 leading spaces)
  - `21.58` → `"       21.58000000"` (7 leading spaces)

### ConcType Field (Special)

- Used for two-part fertilizer systems (A/B solutions)
- `'0'` = Standard fertilizer (can be used with anything)
- `'1'` = Part B fertilizer (HydroBuddy manages tank separation)
- Controls whether the fertilizer is kept in a separate tank

## Important Notes

### Nutrient Conversions

When entering fertilizer data, convert from oxide forms to elemental:

- **P₂O₅ to P:** Multiply by 0.4364 (e.g., 12% P₂O₅ = 5.24% P)
- **K₂O to K:** Multiply by 0.8301 (e.g., 26% K₂O = 21.58% K)

### Record Operations

#### Adding a Record

1. Read the entire DBF file
2. Parse the header to get record count
3. Create a new 681-byte record with proper formatting
4. Remove EOF marker (0x1A) if present
5. Append the new record
6. Increment record count in header (bytes 4-7)
7. Update date in header (bytes 1-3)
8. Add EOF marker at the end
9. Write back to file

#### Checking for Duplicates

- Read all records
- Compare the Name field (bytes 1-80 of each record)
- Use case-insensitive comparison after stripping whitespace

### Backup Strategy

Always create a timestamped backup before modifying the database:

```bash
substances_unix.dbf.backup-YYYYMMDD-HHMMSS
```

## Python Implementation Example

```python
def format_string_field(value, length):
    """Format string field - left-aligned, space-padded"""
    return value[:length].ljust(length).encode('ascii', errors='replace')

def format_numeric_field(value):
    """Format numeric field - 18 bytes, right-aligned with 8 decimals"""
    formatted = f"{float(value):18.8f}"
    return formatted.encode('ascii')

def create_fertilizer_record(name, formula, source, purity, nutrients,
                            isliquid, density, cost, conctype):
    """Create a 681-byte DBF record"""
    record = bytearray(681)
    offset = 0

    # Deletion flag
    record[offset] = 0x20
    offset += 1

    # String fields (80 bytes each)
    record[offset:offset+80] = format_string_field(name, 80)
    offset += 80
    record[offset:offset+80] = format_string_field(formula, 80)
    offset += 80
    record[offset:offset+80] = format_string_field(source, 80)
    offset += 80

    # Numeric fields (18 bytes each, in order)
    record[offset:offset+18] = format_numeric_field(purity)
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('N_NO3', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('N_NH4', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('P', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('K', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mg', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Ca', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('S', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('B', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Fe', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Zn', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mn', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Cu', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Mo', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Na', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Si', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(nutrients.get('Cl', 0))
    offset += 18
    record[offset:offset+18] = format_numeric_field(isliquid)
    offset += 18
    record[offset:offset+18] = format_numeric_field(density)
    offset += 18
    record[offset:offset+18] = format_numeric_field(cost)
    offset += 18

    # ConcType (remaining 80 bytes)
    remaining = 681 - offset
    record[offset:offset+remaining] = format_string_field(conctype, remaining)

    return bytes(record)
```

## Real-World Example: Potassium Nitrate

```
Name:     "Potassium Nitrate" (+ spaces to 80 bytes)
Formula:  "KNO3" (+ spaces to 80 bytes)
Source:   "" (80 spaces)
Purity:   "        1.00000000"
N (NO3-): "       13.85600000"
N (NH4+): "        0.00000000"
P:        "        0.00000000"
K:        "       38.67000000"
Mg-Cl:    All "        0.00000000"
isLiquid: "        0.00000000"
Density:  "        0.00000000"
Cost:     "        0.00000000"
ConcType: "0" (+ spaces to 80 bytes)
```

## Troubleshooting

### Records Don't Show in HydroBuddy

- **Check file location:** macOS uses files inside the `.app` bundle at `/Applications/HydroBuddy-X.XXX-MacOS/hydrobuddy.app/Contents/MacOS/`
- **Check numeric format:** Must be exactly 18 bytes with 8 decimals
- **Check field alignment:** Strings left-aligned, numbers right-aligned
- **Check deletion flag:** Must be `0x20` (space character)

### Data Appears Garbled

- Verify the byte offsets match exactly as documented
- Check that numeric fields are 18 bytes (not 10 or other values)
- Ensure ASCII encoding is used throughout

## References

- Main application code: `hb_main.pas` (lines 3059-3100 for schema)
- Add salt dialog: `hb_newcustomsalt.pas` (lines 108-157 for field names)
- Implementation: Python code embedded in `install-hydrobuddy.command` and `install-macos.command`
  - Standalone version also available: `add-fertilizers.py` (optional, for manual use)

---

**Last Updated:** January 14, 2026
**Verified With:** HydroBuddy 1.100 macOS
