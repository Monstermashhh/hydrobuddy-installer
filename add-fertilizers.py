#!/usr/bin/env python3
"""
Add custom fertilizers to HydroBuddy database
Adds Jack's nutrients and Calcium Sulfate
"""

import struct
import os
import sys
from datetime import datetime


class DBFWriter:
    """Simple DBF record writer"""
    
    def __init__(self, dbf_path):
        self.dbf_path = dbf_path
        self.header = None
        self.records = []
        self.field_descriptors = []
        
    def read_dbf(self):
        """Read existing DBF file"""
        with open(self.dbf_path, 'rb') as f:
            # Read header
            header_data = f.read(32)
            self.header = {
                'version': header_data[0],
                'year': header_data[1],
                'month': header_data[2],
                'day': header_data[3],
                'num_records': struct.unpack('<I', header_data[4:8])[0],
                'header_length': struct.unpack('<H', header_data[8:10])[0],
                'record_length': struct.unpack('<H', header_data[10:12])[0],
            }
            
            # Read field descriptors
            while True:
                field_data = f.read(32)
                if field_data[0] == 0x0D:
                    break
                    
                field_name = field_data[0:11].decode('ascii').strip('\x00')
                field_type = chr(field_data[11])
                field_length = field_data[16]
                field_decimal = field_data[17]
                
                self.field_descriptors.append({
                    'name': field_name,
                    'type': field_type,
                    'length': field_length,
                    'decimal': field_decimal
                })
            
            # Read all records
            for _ in range(self.header['num_records']):
                record = f.read(self.header['record_length'])
                self.records.append(record)
    
    def record_exists(self, name):
        """Check if a record with this name already exists"""
        for record in self.records:
            if record[0:1] == b'*':  # Skip deleted records
                continue
            # Name field is typically first after the deletion flag
            # Extract name (usually starts at byte 1, length varies)
            record_name = record[1:81].decode('ascii', errors='ignore').strip()
            if record_name.lower() == name.lower():
                return True
        return False
    
    def format_value(self, value, field_type, field_length, field_decimal):
        """Format a value according to DBF field specifications"""
        if field_type == 'N':  # Numeric
            if value is None or value == '':
                return b' ' * field_length
            try:
                if field_decimal > 0:
                    formatted = f"{float(value):{field_length}.{field_decimal}f}"
                else:
                    formatted = f"{int(float(value)):{field_length}d}"
                return formatted.encode('ascii')[:field_length].rjust(field_length)
            except:
                return b' ' * field_length
        elif field_type == 'C':  # Character
            if value is None:
                value = ''
            return str(value).encode('ascii', errors='ignore')[:field_length].ljust(field_length)
        elif field_type == 'L':  # Logical
            if value:
                return b'T'
            return b'F'
        else:
            return b' ' * field_length
    
    def add_record(self, field_values):
        """Add a new record with the given field values (dict)"""
        record = bytearray(self.header['record_length'])
        record[0] = 0x20  # Active record marker
        
        offset = 1
        for field in self.field_descriptors:
            value = field_values.get(field['name'], None)
            formatted = self.format_value(value, field['type'], field['length'], field['decimal'])
            record[offset:offset + field['length']] = formatted
            offset += field['length']
        
        self.records.append(bytes(record))
        self.header['num_records'] += 1
    
    def write_dbf(self):
        """Write modified DBF file"""
        # Create backup
        backup_path = f"{self.dbf_path}.backup-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
        if os.path.exists(self.dbf_path):
            os.rename(self.dbf_path, backup_path)
            print(f"  ✓ Backup created: {os.path.basename(backup_path)}")
        
        with open(self.dbf_path, 'wb') as f:
            # Update header
            today = datetime.now()
            header = bytearray(32)
            header[0] = self.header['version']
            header[1] = today.year - 1900
            header[2] = today.month
            header[3] = today.day
            header[4:8] = struct.pack('<I', self.header['num_records'])
            header[8:10] = struct.pack('<H', self.header['header_length'])
            header[10:12] = struct.pack('<H', self.header['record_length'])
            f.write(header)
            
            # Write field descriptors (read from original file)
            with open(backup_path, 'rb') as orig:
                orig.seek(32)
                while True:
                    field_data = orig.read(32)
                    if field_data[0] == 0x0D:
                        f.write(b'\x0D')
                        break
                    f.write(field_data)
            
            # Write all records
            for record in self.records:
                f.write(record)
            
            # Write end-of-file marker
            f.write(b'\x1A')


def add_fertilizers_to_db(db_path):
    """Add Jack's nutrients and Calcium Sulfate to database"""
    
    print(f"\n📊 Adding fertilizers to: {os.path.basename(db_path)}")
    
    if not os.path.exists(db_path):
        print(f"  ⚠️  File not found, skipping")
        return False
    
    db = DBFWriter(db_path)
    db.read_dbf()
    
    # Define fertilizers to add
    fertilizers = [
        {
            'Name': 'Jacks 5-12-26 Part A',
            'Formula': 'NPK blend',
            'Source': "Jack's Nutrients",
            'Purity': 1.0,
            'N (NO3-)': 5.0,
            'N (NH4+)': 0.0,
            'P': 5.24,  # 12% P2O5 converted to elemental
            'K': 21.58,  # 26% K2O converted to elemental
            'Mg': 6.3,
            'Ca': 0.0,
            'S': 8.5,
            'B': 0.05,
            'Fe': 0.3,
            'Zn': 0.015,
            'Mn': 0.05,
            'Cu': 0.015,
            'Mo': 0.019,
            'Na': 0.0,
            'Si': 0.0,
            'Cl': 0.0,
            'isLiquid': 0,
            'Density': 0.0,
            'Cost': 0.0,
            'ConcType': '0'
        },
        {
            'Name': 'Jacks 0-12-26 Part A',
            'Formula': 'PK blend',
            'Source': "Jack's Nutrients",
            'Purity': 1.0,
            'N (NO3-)': 0.0,
            'N (NH4+)': 0.0,
            'P': 5.24,
            'K': 21.58,
            'Mg': 6.0,
            'Ca': 0.0,
            'S': 13.0,
            'B': 0.05,
            'Fe': 0.3,
            'Zn': 0.015,
            'Mn': 0.05,
            'Cu': 0.015,
            'Mo': 0.0009,
            'Na': 0.0,
            'Si': 0.0,
            'Cl': 0.0,
            'isLiquid': 0,
            'Density': 0.0,
            'Cost': 0.0,
            'ConcType': '0'
        },
        {
            'Name': 'Jacks Calcium Nitrate',
            'Formula': 'Ca(NO3)2',
            'Source': "Jack's Nutrients",
            'Purity': 1.0,
            'N (NO3-)': 15.5,
            'N (NH4+)': 0.0,
            'P': 0.0,
            'K': 0.0,
            'Mg': 0.0,
            'Ca': 19.0,
            'S': 0.0,
            'B': 0.0,
            'Fe': 0.0,
            'Zn': 0.0,
            'Mn': 0.0,
            'Cu': 0.0,
            'Mo': 0.0,
            'Na': 0.0,
            'Si': 0.0,
            'Cl': 0.0,
            'isLiquid': 0,
            'Density': 0.0,
            'Cost': 0.0,
            'ConcType': '1'
        },
        {
            'Name': 'Calcium Sulfate',
            'Formula': 'CaSO4·2H2O',
            'Source': 'Generic',
            'Purity': 1.0,
            'N (NO3-)': 0.0,
            'N (NH4+)': 0.0,
            'P': 0.0,
            'K': 0.0,
            'Mg': 0.0,
            'Ca': 22.0,
            'S': 17.0,
            'B': 0.0,
            'Fe': 0.0,
            'Zn': 0.0,
            'Mn': 0.0,
            'Cu': 0.0,
            'Mo': 0.0,
            'Na': 0.0,
            'Si': 0.0,
            'Cl': 0.0,
            'isLiquid': 0,
            'Density': 0.0,
            'Cost': 0.0,
            'ConcType': ''
        }
    ]
    
    added_count = 0
    for fert in fertilizers:
        if db.record_exists(fert['Name']):
            print(f"  ℹ️  '{fert['Name']}' already exists, skipping")
        else:
            db.add_record(fert)
            print(f"  ✓ Added '{fert['Name']}'")
            added_count += 1
    
    if added_count > 0:
        db.write_dbf()
        print(f"  ✓ {added_count} fertilizer(s) added successfully!")
        return True
    else:
        print(f"  ℹ️  No new fertilizers added")
        return False


def main():
    """Main function"""
    print("=" * 70)
    print("HydroBuddy - Add Custom Fertilizers")
    print("=" * 70)
    
    if len(sys.argv) < 2:
        print("\nUsage: add-fertilizers.py <hydrobuddy-folder>")
        print("\nExample:")
        print("  ./add-fertilizers.py /Applications/HydroBuddy")
        sys.exit(1)
    
    base_path = sys.argv[1]
    
    if not os.path.isdir(base_path):
        print(f"\n❌ Error: Directory not found: {base_path}")
        sys.exit(1)
    
    print(f"\nBase directory: {base_path}")
    
    # Detect platform
    substances_db = None
    
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
        print("Expected files:")
        print(f"  - {unix_db}")
        print(f"  - {win_db}")
        sys.exit(1)
    
    # Add fertilizers
    any_changes = add_fertilizers_to_db(substances_db)
    
    print("\n" + "=" * 70)
    if any_changes:
        print("✅ Fertilizers added successfully!")
        print("\nAdded:")
        print("  • Jacks 5-12-26 Part A")
        print("  • Jacks 0-12-26 Part A")
        print("  • Jacks Calcium Nitrate (15.5-0-0)")
        print("  • Calcium Sulfate (Gypsum)")
    else:
        print("✅ All fertilizers already exist in database")
    print("=" * 70)


if __name__ == "__main__":
    main()
