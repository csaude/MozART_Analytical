---- =========================================================================================================
---- WORKING SQL QUERY FOR 6M RETENTION DATASET PRODUCTION
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: Neha Kamat and Marcela Torres
---- REV DATE:3/9/2020
---- Retention Definition: All patients who have either a clinical consultation or drug pick up within 60 days
---- 1) Evaluation Date: ART initiation date + 33 days
---- 2) Variables : Maxes on datatarv and dataseguimento before outcome date on filtered subset USING ROWNUMBERS
---- 3) Patient is 'Not Evaluated' status if outcome date is beyond current date of dataset creation
---- 4) Restricted cohort 
---- =========================================================================================================


WITH CTE0 AS
(
       SELECT DISTINCT 
       facility.HdD, facility.Provincia as Province, facility.Distrito as District, facility.designacao as Health_Facility,
       person.nid as NID, person.sexo as Sex, person.datanasc as DOB, person.datadiagnostico as Diagnosis_Date,
       person.idade as Initiation_Age, person.datainiciotarv as Initiation_Date, first_datatarv, YEAR(person.datainiciotarv) as Cohort_Year, --USG_Year, 
       dateadd(mm, 6, cast(datainiciotarv as date)) as Outcome_Date_Sixm, person.datasaidatarv as Exit_Date, person.codestado as Last_Status,
       tt.Max_datatarv as Last_Drug_Pickup_Date_Sixm, tt.dataproxima as Next_Drug_Pickup_Date_Sixm,
       ss.Max_dataseguimento as Last_Consultation_Date_Sixm, ss.dataproximaconsulta as Next_Consultation_Date_Sixm, person.AccessFilePath

       FROM
       (SELECT nid, sexo, cast(datanasc as date) as datanasc, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
       FROM t_paciente) person

       LEFT JOIN
       (SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
       FROM t_hdd) facility
       ON person.hdd = facility.HdD

       -- Joining subset of filtered dates from t_tarv below @RetentionType outcome date

       LEFT JOIN
       (SELECT * FROM(
       SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Outcome_Date_Sixm, ntv.datatarv as Max_datatarv, ntv.dataproxima
       FROM
              (
              SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Outcome_Date_Sixm
              FROM t_tarv tv
              LEFT JOIN
              (SELECT nid, Outcome_Date_Sixm = dateadd(mm, 6, cast(datainiciotarv as date)), AccessFilePath
              FROM t_paciente) tpo
              ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
              WHERE datatarv <= Outcome_Date_Sixm
              ) ntv
       ) t
       WHERE t.rownum = '1') tt
       ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

       -- Joining t_tarv to calculate first pick up
	          LEFT JOIN
       (SELECT * FROM(
       SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) asc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
       , ntv.datatarv as first_datatarv, ntv.dataproxima as first_dataproxima_tarv
       FROM
              (
              SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date
              FROM t_tarv tv
              LEFT JOIN
              (SELECT nid, Evaluation_Date = '2018-12-31', AccessFilePath
              FROM t_paciente) tpo
              ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
              WHERE cast(datatarv AS date) <= Evaluation_Date
              ) ntv
       ) t
       WHERE t.rownum = '1') t1
       ON person.nid = t1.nid AND person.AccessFilePath = t1.AccessFilePath

       -- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
       LEFT JOIN
       (SELECT * FROM(
       SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath, nts.dataseguimento as Max_dataseguimento, nts.dataproximaconsulta
       FROM 
              (
              SELECT ts.nid, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta, tpo1.Outcome_Date_Sixm
              FROM t_seguimento  ts
              LEFT JOIN
              (SELECT nid, Outcome_Date_Sixm = dateadd(mm, 6, cast(datainiciotarv as date)), AccessFilePath
              FROM t_paciente) tpo1
              ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
              WHERE dataseguimento <= Outcome_Date_Sixm
              ) nts
       ) s
       WHERE s.rownum = '1') ss
       ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),
CTE1 AS
( 
       SELECT *, 
       CASE 
       WHEN Outcome_Date_Sixm > '2/10/2020' THEN 'Not Evaluated'
       WHEN 
       (
              (Exit_Date < Last_Drug_Pickup_Date_Sixm) OR 
              (Exit_Date IS NULL) OR 
              (Exit_Date < Last_Consultation_Date_Sixm) OR
              (Exit_Date > Outcome_Date_Sixm)
       ) AND
       ( 
              (Last_Drug_Pickup_Date_Sixm IS NOT NULL) OR 
              (Last_Consultation_Date_Sixm IS NOT NULL)
       ) AND
       (      
              Last_Drug_Pickup_Date_Sixm > dateadd(mm,-3,Outcome_Date_Sixm) OR 
			  Next_Drug_Pickup_Date_Sixm > dateadd(mm,-2,Outcome_Date_Sixm) OR 
			  Last_Consultation_Date_Sixm > dateadd(mm,-3,Outcome_Date_Sixm) OR
			  Next_Consultation_Date_Sixm > dateadd(mm,-3,Outcome_Date_Sixm)
       ) THEN 'Retained'
       ELSE 'Not Retained'
       END AS [Retained_Status_6m]
       FROM CTE0
),
CTE2 AS
( 
       SELECT *, 
       CASE WHEN Retained_Status_6m = 'Not Retained' AND ((Last_Status = 'ABANDONO') OR (Last_Status IS NULL) AND (Exit_Date < Outcome_Date_Sixm)) THEN 'LTFU'
       WHEN Retained_Status_6m = 'Not Retained' AND ((Last_Status = 'TRANSFERIDO PARA') AND (Exit_Date < Outcome_Date_Sixm)) THEN 'Transferred Out'
       WHEN Retained_Status_6m = 'Not Retained' AND ((Last_Status = 'OBITOU') AND (Exit_Date < Outcome_Date_Sixm)) THEN 'Dead'
       WHEN Retained_Status_6m = 'Not Retained' AND ((Last_Status IS NULL)) THEN 'LTFU'
       WHEN Retained_Status_6m = 'Retained' THEN 'Retained'
       WHEN Retained_Status_6m = 'Not Evaluated' THEN 'Not Evaluated'
       ELSE 'LTFU'
       END AS [Outcome_6m]
       FROM CTE1
)
SELECT *
INTO Sandbox.dbo.Retention_6m_2017_FinalM
FROM CTE2
WHERE Cohort_Year = '2017' AND 
--Outcome_Date_Sixm IS NOT NULL AND 
Initiation_Date IS NOT NULL AND
first_datatarv<= dateadd(mm,6, Initiation_Date)
--(Last_Drug_Pickup_Date_Sixm IS NULL OR Last_Drug_Pickup_Date_Sixm >= Initiation_Date) AND
--WHERE first_datatarv< dateadd(mm,6,cast(datainiciotarv as date)
ORDER BY nid
-- Included nulls for last drug pick ups because they were getting dropped
---Timoteo suggested to use dataproximatarv and dataproxima seguimento
---modified lines 107 and 108 to take the not equal to initiation data for pick ups and consultations as this is redundant and to use scheduled pick up and schedule consultation
