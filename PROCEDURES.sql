USE Hospital_Database;

DELIMITER //

//


//

CREATE PROCEDURE InsertPatient(
  IN patient_name VARCHAR(255),
  IN patient_address VARCHAR(255),
  IN patient_phone VARCHAR(20)
)
BEGIN
  INSERT INTO Patient (name, address, phone)
  VALUES (patient_name, patient_address, patient_phone);
END;
//


CREATE PROCEDURE InsertDoctor(
  IN doctor_name VARCHAR(255),
  IN doctor_specialty VARCHAR(255)
)
BEGIN
  INSERT INTO Doctor (name, speciality)
  VALUES (doctor_name, doctor_specialty);
END;
//

CREATE PROCEDURE InsertMedicalStaff(
  IN staff_name VARCHAR(255)
)
BEGIN
  INSERT INTO MedicalStaff (name)
  VALUES (staff_name);
END;
//


CREATE PROCEDURE UpdateRoomStatus(
  IN r_id INT,
  IN new_availability BOOLEAN
)
BEGIN
  UPDATE Room
  SET availability = new_availability
  WHERE room_id = r_id;
END;
//


CREATE PROCEDURE AllotFirstAvailableStaffToRoom(
  IN r_id INT
)
BEGIN
  DECLARE available_staff_id INT;
 
SELECT staff_id into available_staff_id
FROM MedicalStaff
WHERE staff_id NOT IN (
  SELECT staff_id FROM Room
  WHERE staff_id IS NOT NULL
)
LIMIT 1;
 
  UPDATE Room
  SET staff_id = available_staff_id
  WHERE room_id = r_id;
END;
//


CREATE PROCEDURE FreeStaffFromRoom(
  IN r_id INT
)
BEGIN
  UPDATE Room
  SET staff_id = NULL
  WHERE room_id = r_id;
END;
//


CREATE PROCEDURE makeAppointment (
  IN patient_id INT,
  IN specialization VARCHAR(255),
  IN appt_date DATE,
  IN appt_start_time DATETIME,
  IN appt_end_time DATETIME
)
BEGIN
  DECLARE doc_id INT;
  DECLARE r_id INT;
  DECLARE s_id INT;

  -- Get the doctor of the specified specialization
  SELECT doctor_id INTO doc_id
  FROM Doctor
  WHERE speciality = specialization
  AND doctor_id NOT IN (
    SELECT doctor_id FROM Appointment WHERE date = appt_date
    AND ((appt_start_time BETWEEN start_time AND end_time) OR (appt_end_time BETWEEN start_time AND end_time))
  )
  ORDER BY RAND()
  LIMIT 1;

  IF doc_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available doctor found for the specified specialization on the given date and time';
  END IF;

  -- Get an available room with staff
  SELECT room_id, staff_id INTO r_id, s_id
  FROM Room
  WHERE availability = 1
  AND staff_id IS NOT NULL
  AND room_id NOT IN (
    SELECT room_id FROM Appointment WHERE date = appt_date
    AND ((appt_start_time BETWEEN start_time AND end_time) OR (appt_end_time BETWEEN start_time AND end_time))
  )
  ORDER BY RAND()
  LIMIT 1;

  IF r_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available room found for the given date and time';
  END IF;

  -- Insert the appointment
  INSERT INTO Appointment (patient_id, room_id, doctor_id, start_time, end_time, date) VALUES (patient_id, r_id, doc_id, appt_start_time, appt_end_time, appt_date);

  -- Update the room availability
  UPDATE Room SET availability = 0 WHERE room_id = r_id;

  SELECT CONCAT('Appointment created with doctor ', (SELECT name FROM Doctor WHERE doctor_id = doc_id), ' in room ', r_id, ' with staff ', (SELECT name FROM MedicalStaff WHERE staff_id = s_id)) AS message;
END;

//


CREATE PROCEDURE rescheduleAppointment (
  IN apt_id INT,
  IN new_date DATE,
  IN new_start_time DATETIME,
  IN new_end_time DATETIME
)
BEGIN
  DECLARE r_id INT;
  DECLARE s_id INT;

  -- Check if the appointment has already been diagnosed
  IF EXISTS (SELECT * FROM Diagnosis WHERE appt_id = apt_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The appointment has already been diagnosed and cannot be rescheduled';
  END IF;

  -- Check if the new date/time is available for the same room
  IF EXISTS (
    SELECT * FROM Appointment
    WHERE room_id = (SELECT room_id FROM Appointment WHERE appt_id = apt_id)
    AND date = new_date
    AND ((new_start_time BETWEEN start_time AND end_time) OR (new_end_time BETWEEN start_time AND end_time))
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The new date/time is not available for the same room';
  END IF;

  -- Get an available room with staff
  SELECT room_id, staff_id INTO r_id, s_id
  FROM Room
  WHERE availability = 1
  AND staff_id IS NOT NULL
  AND room_id NOT IN (
    SELECT room_id FROM Appointment WHERE date = new_date
    AND ((new_start_time BETWEEN start_time AND end_time) OR (new_end_time BETWEEN start_time AND end_time))
    AND appt_id != apt_id
  )
  ORDER BY RAND()
  LIMIT 1;

  IF r_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No available room found for the given date and time';
  END IF;

  -- Update the appointment
  UPDATE Appointment SET start_time = new_start_time, end_time = new_end_time, date = new_date, room_id = r_id WHERE appt_id = apt_id;

  -- Update the room availability
  UPDATE Room SET availability = 0 WHERE room_id = r_id;
  UPDATE Room SET availability = 1 WHERE room_id = (SELECT room_id FROM Appointment WHERE appt_id = apt_id AND room_id != r_id);

  SELECT CONCAT('Appointment rescheduled to room ', r_id, ' with staff ', (SELECT name FROM MedicalStaff WHERE staff_id = s_id)) AS message;
END;
//


CREATE PROCEDURE diagnose (
  IN apt_id INT,
  IN diagnosis VARCHAR(255),
  IN treatment VARCHAR(255)
)
BEGIN
  DECLARE p_id INT;

  -- Check if patient has already been diagnosed in the same appointment
  SELECT patient_id INTO p_id
  FROM DiagnosisPatient
  WHERE diagnosis_id IN (
    SELECT diagnosis_id FROM Diagnosis WHERE appt_id = apt_id
  )
  AND patient_id IN (
    SELECT patient_id FROM Appointment WHERE appt_id = apt_id
  );

  IF p_id IS NOT NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient has already been diagnosed in this appointment';
  END IF;

  -- Insert the diagnosis
  INSERT INTO Diagnosis (appt_id, diagnosis, treatment) VALUES (apt_id, diagnosis, treatment);

  -- Update room availability
  UPDATE Room SET availability = 1 WHERE room_id = (SELECT room_id FROM Appointment WHERE appt_id = apt_id);

  -- Insert into DiagnosisPatient
  INSERT INTO DiagnosisPatient (patient_id, diagnosis_id)
  SELECT patient_id, LAST_INSERT_ID()
  FROM Appointment
  WHERE appt_id = apt_id;
END;
//

CREATE PROCEDURE insert_billing(
IN p_diagnosis_id INT, 
    IN p_cost DECIMAL(10,2)
)
BEGIN
    DECLARE v_appointment_date DATE;
    DECLARE v_patient_id INT;
    SELECT date, patient_id INTO v_appointment_date, v_patient_id FROM Appointment WHERE appt_id = (SELECT appt_id FROM Diagnosis WHERE diagnosis_id = p_diagnosis_id);
    INSERT INTO Billing(diagnosis_id, cost, bill_date) VALUES(p_diagnosis_id, p_cost, v_appointment_date);
    INSERT INTO BillingPatient(patient_id, billing_id) VALUES(v_patient_id, LAST_INSERT_ID());
END;
//

CREATE PROCEDURE generate_bill(IN p_patient_id INT)
BEGIN
  DECLARE total_cost DECIMAL(10, 2) DEFAULT 0;
  DECLARE patient_name VARCHAR(255);
  DECLARE patient_address VARCHAR(255);
  DECLARE patient_phone VARCHAR(20);
  
  SELECT name, address, phone INTO patient_name, patient_address, patient_phone
  FROM Patient
  WHERE patient_id = p_patient_id;

  SELECT SUM(cost) INTO total_cost
  FROM Billing
  JOIN Diagnosis ON Billing.diagnosis_id = Diagnosis.diagnosis_id
  JOIN DiagnosisPatient ON Diagnosis.diagnosis_id = DiagnosisPatient.diagnosis_id
  WHERE DiagnosisPatient.patient_id = p_patient_id;

  SELECT patient_name AS 'Patient Name', patient_address AS 'Patient Address', patient_phone AS 'Patient Phone Number', CONCAT('Total cost: $', total_cost) AS 'Bill Summary';
END;
 //
 
 CREATE VIEW all_doctors AS
SELECT doctor_id, name, speciality
FROM Doctor;
//

CREATE VIEW patient_medical_history AS
SELECT p.patient_id, p.name AS patient_name, p.address, p.phone, d.diagnosis, d.treatment, b.cost, b.bill_date
FROM Patient p
LEFT JOIN DiagnosisPatient dp ON p.patient_id = dp.patient_id
LEFT JOIN Diagnosis d ON dp.diagnosis_id = d.diagnosis_id
LEFT JOIN Billing b ON d.diagnosis_id = b.diagnosis_id;
//

CREATE PROCEDURE total_earnings_doctor(IN doctor_name VARCHAR(255))
BEGIN
  DECLARE doctor_id INT;
  DECLARE total DECIMAL(10,2);
 
  SELECT doctor_id INTO doctor_id FROM Doctor WHERE name = doctor_name;
 
  SELECT SUM(b.cost) INTO total
  FROM Billing b
  INNER JOIN Diagnosis d ON b.diagnosis_id = d.diagnosis_id
  INNER JOIN Appointment a ON d.appt_id = a.appt_id
  INNER JOIN Doctor doc ON a.doctor_id = doc.doctor_id
  WHERE doc.name = doctor_name;
 
  SELECT CONCAT(doctor_name, ' has earned ', total, ' in total.') AS result;
END;
//

//

CREATE PROCEDURE total_earnings_specialization(IN speciality_name VARCHAR(255))
BEGIN
  DECLARE total DECIMAL(10,2);
 
  SELECT SUM(b.cost) INTO total
  FROM Billing b
  INNER JOIN Diagnosis d ON b.diagnosis_id = d.diagnosis_id
  INNER JOIN Appointment a ON d.appt_id = a.appt_id
  INNER JOIN Doctor doc ON a.doctor_id = doc.doctor_id
  WHERE doc.speciality = speciality_name;
 
  SELECT CONCAT('The specialization ', speciality_name, ' has earned ', total, ' in total.') AS result;
END;
//


CREATE PROCEDURE find_patients_for_doctor(IN doc_name VARCHAR(255))
BEGIN
  SELECT DISTINCT p.patient_id, p.name
  FROM Patient p
  JOIN Appointment a ON a.patient_id = p.patient_id
  JOIN Doctor d ON d.doctor_id = a.doctor_id
  WHERE d.name = doc_name;
END;
//


CREATE PROCEDURE fetch_previous_diagnoses(IN patient_name VARCHAR(255))
BEGIN
  SELECT d.diagnosis, d.treatment, a.start_time, a.end_time, a.date, doc.name AS doctor_name
  FROM Diagnosis d
  JOIN Appointment a ON d.appt_id = a.appt_id
  JOIN Doctor doc ON a.doctor_id = doc.doctor_id
  JOIN Patient p ON a.patient_id = p.patient_id
  WHERE p.name = patient_name;
END;
//
