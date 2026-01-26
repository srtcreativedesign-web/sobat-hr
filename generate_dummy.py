import pandas as pd
import random

# Constants
DIVISION = 'Wrapping'
# Operational positions for Wrapping
POSITIONS = ['Crew Wrapping', 'Senior Wrapper', 'Quality Control', 'Helper', 'Team Leader Wrapping']

def generate_nik():
    return "".join([str(random.randint(0, 9)) for _ in range(16)])

def generate_phone():
    return "08" + "".join([str(random.randint(0, 9)) for _ in range(10)])

def generate_account():
    return "".join([str(random.randint(0, 9)) for _ in range(10)])

# Generate 50 dummy data for Wrapping
data = []
for i in range(1, 51):
    first_names = ["Budi", "Siti", "Ahmad", "Dewi", "Rudi", "Nina", "Eko", "Rina", "Joko", "Maya", "Adit", "Putri", "Bayu", "Sarah", "Dimas", "Hana", "Fajar", "Lia", "Rizky", "Tia"]
    last_names = ["Santoso", "Wijaya", "Saputra", "Utami", "Pratama", "Kusuma", "Hidayat", "Lestari", "Wibowo", "Anggraini", "Nugroho", "Sari", "Firmansyah", "Rahayu", "Setiawan", "Mardiana", "Kurniawan", "Susanti", "Purnomo", "Handayani"]
    
    name = f"{random.choice(first_names)} {random.choice(last_names)} {i}"
    
    record = {
        'No': i,
        'Nama Karyawan': name,
        'NIK': generate_nik(),
        'Divisi': DIVISION,
        'Jabatan': random.choice(POSITIONS),
        'No HP': generate_phone(),
        'No Rekening': generate_account(),
        'Nama Pemilik Rekening': name
    }
    data.append(record)

# Create DataFrame
df = pd.DataFrame(data)

# Save to Excel
output_path = 'dummy_employees_wrapping.xlsx'
df.to_excel(output_path, index=False)

print(f"File created: {output_path}")
