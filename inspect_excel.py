import pandas as pd
import sys
import json

try:
    file_path = "payslip hans.xlsx"
    # Load the spreadsheet
    # We'll try to load the first few rows to find the header
    df = pd.read_excel(file_path, header=None, nrows=10)
    
    print("Raw first 10 rows:")
    print(df.to_string())
    
    # Try to identify header row
    header_row_idx = -1
    for idx, row in df.iterrows():
        # Look for "Nama Karyawan" or similar common header
        row_str = " ".join([str(x) for x in row.values if pd.notna(x)])
        if "Nama" in row_str or "NAMA" in row_str or "No" in row_str:
            header_row_idx = idx
            break
            
    if header_row_idx != -1:
        print(f"\nPotential Header found at row {header_row_idx}")
        # Reload with header
        df = pd.read_excel(file_path, header=header_row_idx, nrows=5)
        print("\nColumns:")
        for i, col in enumerate(df.columns):
            print(f"Column {i} ({chr(65+i)}): {col}")
    else:
        print("\nCould not identify header row automatically.")

except Exception as e:
    print(f"Error: {e}")
