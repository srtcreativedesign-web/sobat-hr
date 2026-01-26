import pandas as pd
import random
from datetime import datetime, timedelta

# Load dummy employees to get names
try:
    df_emp = pd.read_excel('dummy_employees_wrapping.xlsx')
    employees = df_emp['Nama Karyawan'].tolist()
    accounts = df_emp['No Rekening'].tolist()
except:
    print("Could not read dummy_employees_wrapping.xlsx. Generating fake names.")
    employees = [f"Employee {i}" for i in range(1, 51)]
    accounts = [f"123456{i}" for i in range(1, 51)]

# Current Period
period = datetime.now().replace(day=1) # First day of current month
period_str = period.strftime("%Y-%m-%d")

data = []
for i, name in enumerate(employees):
    # Random Stats
    days_present = random.randint(20, 26)
    days_off = 26 - days_present
    days_sick = 0
    days_permission = 0
    days_alpha = 0
    days_leave = 0
    total_days = days_present + days_off + days_sick + days_permission + days_alpha + days_leave
    
    basic_salary = random.choice([3500000, 4000000, 4500000, 5000000])
    meal_rate = 15000
    meal_amount = days_present * meal_rate
    trans_rate = 10000
    trans_amount = days_present * trans_rate
    
    tunj_hadir = 200000 if days_alpha == 0 else 0
    tunj_sehat = 150000
    bonus = random.choice([0, 500000, 1000000])
    
    ot_hours = random.randint(0, 20)
    ot_rate = 20000
    ot_amount = ot_hours * ot_rate
    
    target_koli = random.randint(0, 100000)
    fee_acc = random.randint(0, 50000)
    
    gross = basic_salary + meal_amount + trans_amount + tunj_hadir + tunj_sehat + bonus + ot_amount + target_koli + fee_acc
    
    bpjs = 100000
    adm = 6500
    loan = 0
    deduction = bpjs + adm + loan
    
    net = gross - deduction
    
    row = {
        'No': i + 1, # A
        'Nama Karyawan': name, # B
        'Periode': period, # C
        'No Rekening': accounts[i], # D
        'Total Hari': total_days, # E
        'Off': days_off, # F
        'Sakit': days_sick, # G
        'Ijin': days_permission, # H
        'Alpha': days_alpha, # I
        'Cuti': days_leave, # J
        'Hadir': days_present, # K
        'Gaji Pokok': basic_salary, # L
        'Gaji Training': 0, # M
        'Meal Rate': meal_rate, # N
        'Meal Amount': meal_amount, # O
        'Trans Rate': trans_rate, # P
        'Trans Amount': trans_amount, # Q
        'Tunj Hadir': tunj_hadir, # R
        'Tunj Sehat': tunj_sehat, # S
        'Bonus': bonus, # T
        'Spacer1': '', # U
        'Lembur Header': 'Lembur', # V
        'Lembur Jam': ot_hours, # W
        'Lembur Rp': ot_amount, # X
        'Target Koli': target_koli, # Y
        'Fee Aksesoris': fee_acc, # Z
        'Gross': gross, # AA
        'Adj BPJS': 0, # AB
        'Pot Absen': 0, # AC
        'Pot Telat': 0, # AD
        'Pot Alpha': 0, # AE
        'Pot Kasbon': loan, # AF
        'Adm Bank': adm, # AG
        'BPJS TK': bpjs, # AH
        'Total Pot': deduction, # AI
        'Spacer2': '', # AJ
        'EWA': 0, # AK
        'Net Salary': net, # AL
        'Net Salary 2': net # AM
    }
    data.append(row)

df = pd.DataFrame(data)

# Save
# Note: Saving with headers. The controller expects data from row 4 (default headers 1-3 maybe?)
# Controller: $name = $sheet->getCell('B' . $row)->getValue(); for $row = 4
# So we need 3 header rows. 
# We'll use openpyxl to insert empty rows to simulate the header structure.

file_name = 'dummy_payroll_wrapping_generated.xlsx'
df.to_excel(file_name, index=False, startrow=3, header=False) 

# Add fake headers manually
import openpyxl
wb = openpyxl.load_workbook(file_name)
ws = wb.active

# Add a simple header in row 2 (index 2) to help human readability, though controller ignores it
headers = list(row.keys())
for col, h in enumerate(headers, 1):
    ws.cell(row=2, column=col, value=h)

wb.save(file_name)
print(f"File created: {file_name}")
