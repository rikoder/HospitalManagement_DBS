
create schema if not exists Hospital_Database;
use Hospital_Database;

CREATE TABLE Patient (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255),
  address VARCHAR(255),
  phone VARCHAR(20)
);

CREATE TABLE Doctor (
  doctor_id INT auto_increment PRIMARY KEY,
  name VARCHAR(255),
  speciality VARCHAR(255)
);

CREATE TABLE MedicalStaff (
  staff_id INT auto_increment PRIMARY KEY,
  name VARCHAR(255)
);

CREATE TABLE Room (
  room_id INT auto_increment PRIMARY KEY,
  staff_id INT,
  availability BOOLEAN,
  FOREIGN KEY (staff_id) REFERENCES MedicalStaff(staff_id)
);

CREATE TABLE Appointment (
  appt_id INT auto_increment PRIMARY KEY,
  patient_id INT,
  room_id INT,
  doctor_id INT,
  start_time DATETIME,
  end_time DATETIME,
  date DATE,
  FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
  FOREIGN KEY (room_id) REFERENCES Room(room_id),
  FOREIGN KEY (doctor_id) REFERENCES Doctor(doctor_id)
);

CREATE TABLE Diagnosis (
  diagnosis_id INT auto_increment PRIMARY KEY,
  appt_id INT,
  diagnosis VARCHAR(255),
  treatment VARCHAR(255),
  FOREIGN KEY (appt_id) REFERENCES Appointment(appt_id)
);

CREATE TABLE DiagnosisPatient (
  patient_id INT,
  diagnosis_id INT,
  PRIMARY KEY (patient_id, diagnosis_id),
  FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
  FOREIGN KEY (diagnosis_id) REFERENCES Diagnosis(diagnosis_id)
);

CREATE TABLE Billing (
  billing_id INT auto_increment PRIMARY KEY,
  diagnosis_id INT,
  cost DECIMAL(10, 2),
  bill_date DATE,
  FOREIGN KEY (diagnosis_id) REFERENCES Diagnosis(diagnosis_id)
);

CREATE TABLE BillingPatient (
  patient_id INT,
  billing_id INT,
  PRIMARY KEY (patient_id, billing_id),
  FOREIGN KEY (patient_id) REFERENCES Patient(patient_id),
  FOREIGN KEY (billing_id) REFERENCES Billing(billing_id)
);

INSERT INTO Patient (name, address, phone)
VALUES
  ('Kshitish', 'Ghaziabad', '1234512345'),
  ('Aryan', '6th Street Pune', '4567845678'),
  ('Nikesh', '1st Sector Faridabad', '9876598765'),
  ( 'Sanshrav', '2nd Sector Faridabad', '3467934679'),
  ( 'Harshit', '3rd Sector Faridabad', '56342184723'),
  ( 'Mayank', '5th Street Gurgaon', '34565902284'),
  ( 'Munish', 'Ranchi', '5482927282'),
  ('Rishabh', '6th Sector Faridabad', '987654321'),
  ('Samarth', '6th Street Gurgaon', '4682738723'),
  ('Chirag', 'Dhanbad', '6483927483');


INSERT INTO Doctor ( name, speciality)
VALUES
  ('Dr. Tarak', 'Cardiology'),
  ('Dr. Siddhardh', 'Oncology'),
  ('Dr. Sanah Sheik', 'Neurology'),
  ('Dr. Srikruti', 'Pediatrics'),
  ('Dr. Malhar Patel', 'Dermatology'),
  ('Dr. Gabriel Joe', 'Endocrinology'),
  ('Dr. Nishant DMello', 'Gastroenterology'),
  ('Dr. Nishant K', 'Hematology'),
  ('Dr. Stuti Agarwal', 'Infectious Disease'),
  ('Dr. Jeevitha Reddy', 'Internal Medicine');


INSERT INTO MedicalStaff (name)
VALUES
  ('Ravi'),
  ('Priya'),
  ('Shruti'),
  ('Akhil'),
  ('Aryan'),
  ('Amandeep'),
  ( 'Rijul'),
  ('Aadeesh'),
  ( 'Aakash'),
  ('Pranav');


INSERT INTO Room (staff_id, availability)
VALUES
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE),
  (NULL, TRUE);


