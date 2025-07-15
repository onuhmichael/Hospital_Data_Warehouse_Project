import csv
import random
import time
import datetime
import os
import names

# --- 1. Define Functions for Realistic Data ---

def generate_nhs_number():
    """
    Generates a valid 10-digit NHS number using the Modulus 11 algorithm.
    This number is structurally valid but entirely fictional.
    """
    first_9_digits = [random.randint(0, 9) for _ in range(9)]
    weighted_sum = sum((10 - i) * digit for i, digit in enumerate(first_9_digits))
    checksum = 11 - (weighted_sum % 11)
    if checksum == 11:
        checksum = 0
    if checksum == 10:
        return generate_nhs_number()
    nhs_number_list = first_9_digits + [checksum]
    return ''.join(map(str, nhs_number_list))

def generate_patient_pool(num_patients=100):
    """
    Generates a fixed list of unique patient dictionaries to act as our 'Patient Dimension'.
    """
    print(f"Generating a consistent pool of {num_patients} unique patients...")
    patient_pool = []
    postcode_prefixes = ['CF', 'NP', 'SA', 'LL']
    for i in range(num_patients):
        patient_id = f"P{500 + i}"
        first_name = names.get_first_name()
        last_name = names.get_last_name()
        birth_year = random.randint(1940, 2010)
        birth_month = random.randint(1, 12)
        birth_day = random.randint(1, 28)
        patient_dob = f"{birth_year}-{birth_month:02d}-{birth_day:02d}"
        patient_postcode = f"{random.choice(postcode_prefixes)}{random.randint(10, 40)} {random.randint(1,9)}{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}{random.choice('ABCDEFGHIJKLMNOPQRSTUVWXYZ')}"
        patient = {
            "PatientID": patient_id, "NHS_ID": generate_nhs_number(),
            "PatientFirstName": first_name, "PatientLastName": last_name,
            "PatientDOB": patient_dob, "PatientPostcode": patient_postcode
        }
        patient_pool.append(patient)
    print("✅ Patient pool generated.")
    return patient_pool

# --- 2. Define Data Pools (Clinics, Providers, etc.) ---

CLINICS = [
    ('University Hospital', 'Cardiology'), ('Royal Glamorgan', 'Dermatology'),
    ('Prince Charles', 'Orthopaedics'), ('Royal Glamorgan', 'Gastroenterology'),
    ('Singleton Hospital', 'Oncology'), ('Morriston Hospital', 'Neurology')
]
PROVIDERS = [
    ('D21', 'Dr. Evans'), ('D45', 'Dr. Jones'), ('D67', 'Dr. Williams'),
    ('D88', 'Dr. Davies'), ('D12', 'Dr. Thomas'), ('D33', 'Dr. Roberts')
]
DIAGNOSES = [
    ('I10', 'Essential hypertension'), ('L20.9', 'Atopic dermatitis, unspecified'),
    ('M54.5', 'Low back pain'), ('K21.9', 'Gastro-oesophageal reflux disease'),
    ('S82.1', 'Fracture of upper end of tibia'), ('J45.9', 'Asthma, unspecified'),
    ('E11.9', 'Type 2 diabetes mellitus without complications')
]
APPOINTMENT_STATUSES = ['Attended', 'Attended', 'Attended', 'DNA']

# --- 3. Setup CSV File and Global Variables ---

# This is the special folder where your appointment list will be saved!
CSV_FILE_NAME = r'C:\DWH_Project\Hospital_Data_Warehouse\datasets -INP\source_crm\outpatient_data_realistic.csv'

# These are the column titles for our list
HEADERS = [
    'AppointmentID', 'AppointmentDateTime', 'PatientID', 'NHS_ID', 'PatientFirstName',
    'PatientLastName', 'PatientDOB', 'PatientPostcode', 'ClinicName', 'Specialty',
    'ProviderID', 'ProviderName', 'DiagnosisCode', 'DiagnosisDescription', 'AppointmentStatus'
]

# --- 4. Main Generation Script ---

# First, create the folder if it doesn't exist
output_dir = os.path.dirname(CSV_FILE_NAME)
if not os.path.exists(output_dir):
    print(f"Folder did not exist. Creating it now at: {output_dir}")
    os.makedirs(output_dir)

patient_pool = generate_patient_pool(150)
appointment_id_counter = 1000
file_exists = os.path.exists(CSV_FILE_NAME)

print("\n🚀 Starting realistic synthetic outpatient data generation...")
print(f"Data will be added to '{CSV_FILE_NAME}' every 5 seconds.")
print("Press Ctrl+C to stop the script.")

try:
    with open(CSV_FILE_NAME, mode='a', newline='', encoding='utf-8') as csv_file:
        writer = csv.writer(csv_file)
        if not file_exists:
            writer.writerow(HEADERS)
        while True:
            appointment_id_counter += 1
            patient = random.choice(patient_pool)
            appointment_datetime = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            clinic_name, specialty = random.choice(CLINICS)
            provider_id, provider_name = random.choice(PROVIDERS)
            diagnosis_code, diagnosis_description = random.choice(DIAGNOSES)
            status = random.choice(APPOINTMENT_STATUSES)
            new_row = [
                f"A{appointment_id_counter}", appointment_datetime, patient['PatientID'],
                patient['NHS_ID'], patient['PatientFirstName'], patient['PatientLastName'],
                patient['PatientDOB'], patient['PatientPostcode'], clinic_name, specialty,
                provider_id, provider_name, diagnosis_code, diagnosis_description, status
            ]
            writer.writerow(new_row)
            csv_file.flush()
            print(f"✅ Record A{appointment_id_counter} for {patient['PatientFirstName']} {patient['PatientLastName']} added.")
            time.sleep(0.1)
except KeyboardInterrupt:
    print("\n🛑 Data generation stopped by user. Goodbye!")
except Exception as e:
    print(f"\n❌ An error occurred: {e}")