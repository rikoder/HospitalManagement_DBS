
use  hospital_database;

DELIMITER //
//

CALL InsertPatient('Rikhil Gupta', 'Elec City Blr', '123-456');
//
CALL InsertDoctor('Nachiket Shastry', 'Cardiology');
//
CALL InsertMedicalStaff('Manas');
//
CALL UpdateRoomStatus(1, 1);

-- takes room_id as input and allots a medical staff to it
//
CALL AllotFirstAvailableStaffToRoom(2);
CALL AllotFirstAvailableStaffToRoom(1);
CALL AllotFirstAvailableStaffToRoom(4);
CALL AllotFirstAvailableStaffToRoom(5);
CALL AllotFirstAvailableStaffToRoom(6);
CALL AllotFirstAvailableStaffToRoom(3);
CALL AllotFirstAvailableStaffToRoom(7);
//


-- takes room_id as input and frees a staff from that room
//
CALL FreeStaffFromRoom(1);
//

-- takes patient_id ,specialisation required, date, start_time and end_time as input for booking an appointment
//
CALL makeappointment(1,'Cardiology','2023-08-01', '2023-08-01 11:00:00', '2023-08-01 12:00:00');
CALL makeappointment(3,'Neurology','2023-09-01', '2023-09-01 04:00:00', '2023-09-01 05:00:00');
CALL makeappointment(7,'Endocrinology','2023-10-01', '2023-10-01 07:00:00', '2023-10-01 08:00:00');
CALL makeappointment(3,'Oncology','2023-09-01', '2023-09-01 05:00:00', '2023-09-01 06:00:00');
//



-- takes apointment_id, new_date, new_start_time,new_end_time 
//
CALL rescheduleAppointment(1, '2023-08-01', '2023-08-01 14:00:00', '2023-08-01 15:00:00');
//

-- takes appointment_id, diagnosis, treatment as inputs for that particular appointment and updates them in the diagnosis table
//
CALL diagnose(1,'CANCER','Chemo');
CALL diagnose(3,'Malaria','BesRest');
CALL diagnose(2,'AIDS','NoCure');
CALL diagnose(2,'AIDS','NoCure');
//
CALL diagnose(4,'Fever','Dolo');

//

-- takes diagnosis_id and cost as input inserts billing
//
CALL insert_billing(1, 100);
CALL insert_billing(2, 25);
//

CREATE TRIGGER add_gst_to_billing
BEFORE INSERT ON Billing
FOR EACH ROW
BEGIN
  SET NEW.cost = NEW.cost * 1.18;
END;

//
CALL insert_billing(3, 50);



-- takes patient_id as input and generates that patients bill
//

CALL generate_bill(3);
//



-- takes name of doctor as input and displays his earnings
//

CALL total_earnings_doctor('Dr. Sanah Sheik');
//
CALL total_earnings_doctor('Dr. Gabriel Joe');
//
CALL total_earnings_doctor('Nachiket Shastry');
//



-- takes specialisation as input and displays it's earnings
//
CALL total_earnings_specialization('Cardiology');
//
CALL total_earnings_specialization('Endocrinology');
//
CALL total_earnings_specialization('Neurology');
//



-- takes name of doctor as input and displays the patients
//
CALL find_patients_for_doctor('Dr. Tarak');
//
CALL find_patients_for_doctor('Dr. Siddhardh');
//
CALL find_patients_for_doctor('Dr. Sanah Sheik');
//
CALL find_patients_for_doctor('Nachiket Shastry');
//


-- takes name of patient as input and displays the patient's previous medical records
//
CALL fetch_previous_diagnoses('Kshitish');
//
CALL fetch_previous_diagnoses('Nikesh');
//
CALL fetch_previous_diagnoses('Sanshrav');
//
CALL fetch_previous_diagnoses('Aryan');

//

