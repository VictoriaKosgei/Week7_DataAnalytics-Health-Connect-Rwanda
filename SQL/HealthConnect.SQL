CREATE DATABASE HealthConnect;
USE HealthConnect;

DESCRIBE hc_patients `ï»¿PatientID`;
ALTER TABLE hc_patients CHANGE `ï»¿PatientID` PatientID VARCHAR(50);
SELECT * FROM hc_provinces;
ALTER TABLE hc_provinces CHANGE `ï»¿ProvinceID` ProvinceID VARCHAR(50);
SELECT * FROM hc_villages;
ALTER TABLE hc_villages CHANGE `ï»¿VillageID` VillageID VARCHAR(50);
SELECT * FROM hc_districts;
SELECT * FROM hc_sectors;
ALTER TABLE hc_sectors CHANGE `ï»¿SectorID` SectorID VARCHAR(50);
SELECT * FROM hc_departments;
ALTER TABLE hc_departments CHANGE `ï»¿DepartmentID` DepartmentID VARCHAR(50);
SELECT * FROM hc_doctor;
ALTER TABLE hc_doctor CHANGE `ï»¿StaffID` StaffID VARCHAR(50);
SELECT * FROM hc_diagnoses;
ALTER TABLE hc_diagnoses CHANGE `ï»¿DiagnosisID` DiagnosisID VARCHAR(50);
SELECT * FROM hc_billing;
ALTER TABLE hc_billing CHANGE `ï»¿BillingID` BillingID VARCHAR(50);
SELECT * FROM hc_services;
ALTER TABLE hc_services CHANGE `ï»¿ServiceID` ServiceID VARCHAR(50);
SELECT * FROM insurance_claims;
ALTER TABLE insurance_claims CHANGE `ï»¿ClaimID` ClaimID VARCHAR(50);
SELECT * FROM hc_payments;
ALTER TABLE hc_payments CHANGE `ï»¿PaymentID` PaymentID VARCHAR(50);

-- PATIENT ANALYSIS
-- 1. Retrieve all registered patients
SELECT * FROM hc_patients;

-- 2.Count of Patients by Gender
SELECT Gender, COUNT(*) AS TotalCount FROM hc_patients
GROUP BY Gender
ORDER BY Gender DESC;

-- 3. Count Patients by Provinces
SELECT pr.ProvinceName, COUNT(p.PatientID) AS PatientsCount FROM hc_patients p
JOIN hc_villages v
ON p.VillageID = v.VillageID
JOIN hc_sectors s
ON v.SectorID = s.SectorID
JOIN hc_districts d
ON s.DistrictID = d.DistrictID
JOIN hc_provinces pr
ON d.ProvinceID = pr.ProvinceID
GROUP BY pr.ProvinceName
ORDER BY PatientsCount DESC;

-- 4. Identify Patients Above 65 Years
SELECT * FROM hc_patients
WHERE Age > 65;

-- 5. Find Patients with Chronic Diseases
SELECT ChronicCondition, COUNT(*) AS TotalCount FROM hc_patients
WHERE ChronicCondition IS NOT NULL
GROUP BY ChronicCondition 
ORDER BY TotalCount DESC;

-- 6. Retrieve Patients by Blood Groups
SELECT BloodGroup, COUNT(*) AS TotalCount FROM hc_patients
GROUP BY BloodGroup
ORDER BY TotalCount DESC;

-- 7. Retrieve Patients Covered by Assurance
SELECT InsuranceID, COUNT(*) AS CoveredPatients FROM hc_patients
WHERE InsuranceID IS NOT NULL
GROUP By InsuranceID;

-- 8. List of the youngest and the oldest patients
(SELECT 'Youngest' AS Category, PatientID, FirstName, LastName, Age FROM hc_patients ORDER BY Age ASC LIMIT 1)
UNION ALL
(SELECT 'Oldest' AS Category, PatientID, FirstName, LastName, Age FROM hc_patients ORDER BY Age DESC LIMIT 1);

-- 9. Identify duplicate phone numbers
SELECT Phone, COUNT(*) AS DuplicateNumbers FROM hc_patients
WHERE Phone > 1
GROUP BY Phone 
ORDER BY DuplicateNumbers DESC;

-- 10. Calculate Average Patient Age
SELECT ROUND(AVG(Age),2) as AverageAge FROM hc_patients;

-- APPOINTMENTS ANALYSIS
-- 11. Count of Appointments by Months
SELECT DATE_FORMAT(STR_TO_DATE(`Date`, '%Y-%m-%d'),'%Y-%m') AS AppointmentMonth,
       COUNT(*) AS TotalAppointments
FROM hc_clinical_transactions
GROUP BY AppointmentMonth
ORDER BY AppointmentMonth;

-- 12. Identify the busiest hospital
SELECT FacilityID, COUNT(*) AS TotalAppointments FROM hc_clinical_transactions_appointments
GROUP BY FacilityID
ORDER BY TotalAppointments DESC;

-- 13. Find the busiest Departments
SELECT  d.DepartmentID, d.DepartmentName, COUNT(a.AppointmentID)AS TotalAppointments FROM hc_departments d
JOIN hc_clinical_transactions_appointments a
ON d.DepartmentID = a.DepartmentID
GROUP BY  d.DepartmentID, d.DepartmentName
ORDER BY TotalAppointments DESC;

-- 14. Find doctors with the highest work load
SELECT doc.StaffID AS DoctorID,
       doc.FirstName,
       doc.LastName,
       doc.Specialty,
       COUNT(a.AppointmentID) AS TotalConsultations
FROM hc_clinical_transactions_appointments a
JOIN hc_doctor doc
ON a.DoctorID = doc.StaffID
GROUP BY doc.StaffID, doc.FirstName, doc.LastName, doc.Specialty
ORDER BY TotalConsultations DESC;

-- 15. Identify Referral Patterns
SELECT a.FacilityID AS OriginalFacilty,
       r.ReferredFacilityID AS DestinationFacilityID,
       COUNT(*) AS ReferralCount 
FROM hc_clinical_transactions_referrals r
JOIN hc_clinical_transactions_appointments a
ON r.AppointmentID = a.AppointmentID 
GROUP BY a.FacilityID, r.ReferredFacilityID
ORDER BY ReferralCount DESC;

SELECT COUNT(ReferralID) FROM hc_clinical_transactions_referrals;

-- 16. Count Emergency Appointments
SELECT VisitType,
	   COUNT(*) AS AppointmentCount,
       ROUND((COUNT(*) * 100 / (SELECT COUNT(*) FROM hc_clinical_transactions_appointments)), 2) AS Percentage
FROM hc_clinical_transactions_appointments
WHERE VisitType = "Emergency"
GROUP BY VisitType;

-- 17. Count Average Appointments per Doctor
SELECT 
    ROUND(COUNT(a.AppointmentID) / COUNT(DISTINCT d.StaffID), 2) AS AvgAppointmentsPerDoctor
FROM hc_doctor d
LEFT JOIN hc_clinical_transactions_appointments a ON d.StaffID = a.DoctorID;

-- 18. Rerieve appointments by province
SELECT pr.ProvinceName, COUNT(a.AppointmentID) AS TotalAppointments
FROM hc_clinical_transactions_appointments a
JOIN hc_patients p
ON a.PatientID = p.PatientID
JOIN hc_villages v
ON p.VillageID = v.VillageID
JOIN hc_sectors s
ON v.SectorID = s.SectorID
JOIN hc_districts d
ON s.DistrictID = d.DistrictID
JOIN hc_provinces pr
ON d.ProvinceID = pr.ProvinceID
GROUP BY pr.ProvinceName
ORDER BY TotalAppointments DESC;

-- 19. Identify facilities with the highest patient volume.
SELECT FacilityID,
       COUNT(DISTINCT(PatientID)) AS UniquePatientCount,
       COUNT(AppointmentID) AS TotalVisits
FROM hc_clinical_transactions_appointments 
GROUP BY FacilityID
ORDER BY UniquePatientCount DESC;

-- 20. Find Peak Consultation period
SELECT DATE_FORMAT(STR_TO_DATE(`Date`, '%Y-%m-%d'),'%W') AS DayOfWeek,
    COUNT(*) AS TotalAppointments
FROM hc_clinical_transactions_appointments
GROUP BY DayOfWeek
ORDER BY DayOfWeek;

-- CLINICAL ANALYSIS
-- 21. Top Diagnoses
SELECT Diagnosis, COUNT(DiagnosisID) AS TotalCount FROM hc_diagnoses
GROUP BY Diagnosis
ORDER BY TotalCount DESC;

-- 22. Most Requested Laboratory Tests
SELECT Test, COUNT(LabID) AS TotalCount FROM hc_clinical_transactions_laboratorytests
GROUP BY Test
ORDER BY TotalCount DESC;

-- 23. Most Prescribed Medications
SELECT Medication, COUNT(PrescriptionID) AS TotalCount FROM hc_clinical_transactions_prescriptions
GROUP BY Medication
ORDER BY TotalCount DESC;

-- 24. Average Admission Durations
SELECT ROUND(AVG(LengthOfStayDays),2) AS AVGAdmissionDuration 
FROM hc_clinical_transactions_admissions;

-- 25. Disease severity distribution
SELECT Severity, 
       COUNT(*) AS CaseCount,
       ROUND((COUNT(*) * 100.0 / (SELECT COUNT(*) FROM hc_diagnoses)), 2) AS Percentage
FROM hc_diagnoses
GROUP BY Severity
ORDER BY CaseCount DESC;

-- 26.Laboratory Test Utilizations
SELECT a.FacilityID,
       COUNT(l.LabID) AS TotalLabTests
FROM hc_clinical_transactions_laboratorytests l
JOIN hc_clinical_transactions_appointments a 
ON l.AppointmentID = a.AppointmentID
GROUP BY a.FacilityID
ORDER BY TotalLabTests DESC;

-- 27. Prescription Trends
SELECT DATE_FORMAT(STR_TO_DATE(`Date`, '%Y-%m-%d'),'%Y-%m') AS Month,
    p.Medication,
    COUNT(*) AS PrescriptionCount
FROM hc_clinical_transactions_prescriptions p
JOIN hc_clinical_transactions_appointments a
ON p.AppointmentID = a.AppointmentID
GROUP BY Month, p.Medication
ORDER BY Month, PrescriptionCount DESC;

-- 28. Referral Destinations
SELECT ReferredFacilityID AS DestinationFacilityID,
       COUNT(*) AS TotalReferrals
FROM hc_clinical_transactions_referrals
GROUP BY ReferredFacilityID
ORDER BY TotalReferrals DESC;

-- 29. Admission Rate by Diagnosis
SELECT d.Diagnosis,
       COUNT(DISTINCT ad.AdmissionID) AS AdmissionCount,
	   COUNT(DISTINCT d.AppointmentID) AS TotalCases,
       ROUND((COUNT(DISTINCT ad.AdmissionID) * 100.0 / COUNT(DISTINCT d.AppointmentID)), 2) AS AdmissionRatePercentage
FROM hc_diagnoses d
LEFT JOIN hc_clinical_transactions_admissions ad 
ON d.AppointmentID = ad.AppointmentID
GROUP BY d.Diagnosis
ORDER BY AdmissionRatePercentage DESC;

-- 30. Clinical Workload by Dpt
SELECT dept.DepartmentID,
       dept.DepartmentName,
       COUNT(d.DiagnosisID) AS TotalDiagnoses,
       COUNT(l.LabID) AS TotalLabTests,
       COUNT(p.PrescriptionID) AS TotalPrescriptions
FROM hc_clinical_transactions_appointments a
JOIN hc_departments dept 
ON a.DepartmentID = dept.DepartmentID
LEFT JOIN hc_diagnoses d 
ON a.AppointmentID = d.AppointmentID
LEFT JOIN hc_clinical_transactions_laboratorytests l 
ON a.AppointmentID = l.AppointmentID
LEFT JOIN hc_clinical_transactions_prescriptions p 
ON a.AppointmentID = p.AppointmentID
GROUP BY dept.DepartmentID, dept.DepartmentName
ORDER BY TotalDiagnoses DESC;
    -- OR  -------
SELECT 
    dept.DepartmentID,
    dept.DepartmentName,
    COUNT(DISTINCT d.DiagnosisID) AS TotalDiagnoses,
    COUNT(DISTINCT l.LabID) AS TotalLabTests,
    COUNT(DISTINCT p.PrescriptionID) AS TotalPrescriptions,
    -- Simple addition of the distinct counts for total workload
    (COUNT(DISTINCT d.DiagnosisID) + COUNT(DISTINCT l.LabID) + COUNT(DISTINCT p.PrescriptionID)) AS TotalWorkload
FROM hc_departments dept
LEFT JOIN hc_clinical_transactions_appointments a ON dept.DepartmentID = a.DepartmentID
LEFT JOIN hc_diagnoses d ON a.AppointmentID = d.AppointmentID
LEFT JOIN hc_clinical_transactions_laboratorytests l ON a.AppointmentID = l.AppointmentID
LEFT JOIN hc_clinical_transactions_prescriptions p ON a.AppointmentID = p.AppointmentID
GROUP BY dept.DepartmentID, dept.DepartmentName
ORDER BY TotalWorkload DESC;

-- FINANCIAL ANALYSIS
-- 31. Revenue by Facility
SELECT a.FacilityID,
       SUM(b.Amount) AS TotalRevenue
FROM hc_billing b
JOIN hc_clinical_transactions_appointments a
ON b.AppointmentID = a.AppointmentID
GROUP BY a.FacilityID
ORDER BY TotalRevenue DESC;

-- 32. Revenue By Dpt
SELECT dept.DepartmentID, dept.DepartmentName, SUM(b.Amount) AS TotalRevenue FROM hc_billing b
JOIN hc_clinical_transactions_appointments a
ON b.AppointmentID = a.AppointmentID
JOIN hc_departments dept
ON a.DepartmentID = dept.DepartmentID
GROUP BY dept.DepartmentID, dept.DepartmentName
ORDER BY TotalRevenue DESC;

-- 33. Revenue by Services
SELECT s.ServiceID, s.ServiceName, SUM(b.Amount) AS TotalRevenue FROM hc_billing b
JOIN hc_clinical_transactions_appointments a
ON b.AppointmentID = a.AppointmentID
JOIN hc_services s
ON a.DepartmentID = s.DepartmentID
GROUP BY s.ServiceID, s.ServiceName
ORDER BY TotalRevenue DESC;

-- 34. Insurance Claims by Provider
SELECT Provider, 
       SUM(ClaimAmount) AS TotalClaims,
       COUNT(*) ClaimCount
       FROM insurance_claims
GROUP BY Provider
ORDER BY TotalClaims DESC;

-- 35. Outstanding Payments(Money Owed)
SELECT Status,
       COUNT(*) AS InvoiceCount,
       SUM(Amount) AS OutstandingAmount
FROM hc_billing
WHERE Status != 'Paid'
GROUP BY Status;

-- 36. Average Billing Amount
SELECT ROUND(AVG(Amount),2) FROM hc_billing;

-- 37. Monthly Revenue Trend
SELECT DATE_FORMAT(STR_TO_DATE(`Date`, '%Y-%m-%d'),'%Y-%m') AS RevenueMonth,
    SUM(b.Amount) AS MonthlyRevenue
FROM hc_billing b
JOIN hc_clinical_transactions_appointments a 
ON b.AppointmentID = a.AppointmentID
GROUP BY RevenueMonth
ORDER BY RevenueMonth;

-- 38. Payment Methods
SELECT Method,
       COUNT(*) AS TransactionCount,
	   SUM(AmountPaid) AS TotalPaid
FROM hc_payments
GROUP BY Method
ORDER BY TotalPaid DESC;

-- 39. Top Revenue Generated by Hospitals
SELECT a.FacilityID,
       SUM(Amount) AS Revenue
FROM hc_billing b
JOIN hc_clinical_transactions_appointments a 
ON b.AppointmentID = a.AppointmentID
GROUP BY a.FacilityID
ORDER BY Revenue DESC
LIMIT 5;

-- 40. Fincancial Performance Ranking
SELECT FacilityID,
       SUM(Amount) AS TotalRevenue,
       RANK() OVER (ORDER BY SUM(Amount) DESC) AS FinancialRank
FROM hc_billing b
JOIN hc_clinical_transactions_appointments a 
ON b.AppointmentID = a.AppointmentID
GROUP BY FacilityID;

-- END!!!!!!!!!!!!!!


SELECT * FROM hc_payments;
SELECT * FROM insurance_claims;
SELECT * FROM hc_services;
SELECT * FROM hc_billing;
SELECT * FROM hc_clinical_transactions_admissions;
SELECT * FROM hc_clinical_transactions_prescriptions;
SELECT * FROM hc_clinical_transactions_laboratorytests;
SELECT * FROM hc_departments;
SELECT * FROM hc_clinical_transactions_appointments;
SELECT * FROM hc_doctor;
SELECT * FROM hc_clinical_transactions_referrals;
SELECT * FROM hc_provinces;
SELECT * FROM hc_diagnoses;