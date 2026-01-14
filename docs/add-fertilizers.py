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
