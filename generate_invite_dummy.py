import pandas as pd

data = [
    {"Nama": "Budi Santoso", "Email": "budi.santoso@sobat.co.id"},
    {"Nama": "Siti Aminah", "Email": "siti.aminah@sobat.co.id"},
    {"Nama": "Rizky Pratama", "Email": "rizky.pratama@sobat.co.id"},
    {"Nama": "Dewi Kartika", "Email": "dewi.kartika@sobat.co.id"},
    {"Nama": "Agus Setiawan", "Email": "agus.setiawan@sobat.co.id"},
    {"Nama": "Nina Marlina", "Email": "nina.marlina@sobat.co.id"},
    {"Nama": "Hendra Wijaya", "Email": "hendra.wijaya@sobat.co.id"},
    {"Nama": "Ratna Sari", "Email": "ratna.sari@sobat.co.id"},
    {"Nama": "Doni Saputra", "Email": "doni.saputra@sobat.co.id"},
    {"Nama": "Eka Putri", "Email": "eka.putri@sobat.co.id"}
]

df = pd.DataFrame(data)
output_path = 'dummy_invite_employees.xlsx'
df.to_excel(output_path, index=False)

print(f"Success! File created: {output_path}")
