import pandas as pd

# Load the reference payroll file
try:
    df = pd.read_excel('Payroll Wrapping.xlsx')
    print("Reference Headers:")
    print(df.columns.tolist())
    
    # Also peek first few rows to see data format
    print("\nFirst row sample:")
    print(df.iloc[0].to_dict())

except Exception as e:
    print(f"Error reading reference: {e}")

# Load the employee file
try:
    df_emp = pd.read_excel('dummy_employees_wrapping.xlsx')
    print("\nEmployee Headers:")
    print(df_emp.columns.tolist())
    print(f"\nTotal Employees Found: {len(df_emp)}")
except Exception as e:
    print(f"Error reading employees: {e}")
