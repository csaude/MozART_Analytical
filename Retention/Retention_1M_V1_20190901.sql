---- =========================================================================================================
---- WORKING SQL QUERY FOR 1M RETENTION DATASET PRODUCTION
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- REV DATE: 9/8/2019
---- Retention Definition: Newly enrolled on antiretroviral therapy (ART) who returned for 2nd Clinical consultation or 2nd ART pick up within 33 days of treatment initiation
---- 1) Evaluation Date: ART initiation date + 33 days
---- 2) Variables : Maxes on datatarv and dataseguimento before outcome date on filtered subset USING ROWNUMBERS
---- 3) Patient is 'Not Evaluated' status if outcome date is beyond current date of dataset creation
---- =========================================================================================================

IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID('[dbo].[RetentionGenerator_1m]') AND type IN ('P', 'PC', 'RF', 'X'))
  DROP PROCEDURE [dbo].[RetentionGenerator_1m]
GO

IF OBJECT_ID('[Sandbox].[dbo].[Retention_1m]', N'U') IS NOT NULL
  DROP TABLE [Sandbox].[dbo].[Retention_1m]
GO

CREATE PROCEDURE [dbo].[RetentionGenerator_1m] @CreationDate Date
AS


WITH CTE0 AS
(
	SELECT DISTINCT 
	person.HdD, facility.Provincia as Province, facility.Distrito as District, facility.designacao as Health_Facility,
	person.nid as NID, person.sexo as Sex, person.datanasc as DOB, person.datadiagnostico as Diagnosis_Date,
	person.idade as Initiation_Age, person.datainiciotarv as Initiation_Date, YEAR(person.datainiciotarv) as Cohort_Year, --USG_Year, 
	tt.Outcome_Date, person.datasaidatarv as Exit_Date, person.codestado as Last_Status,
	tt.Max_datatarv as Last_Drug_Pickup_Date, --tt.dataproxima as Next_Drug_Pickup_Date,
	ss.Max_dataseguimento as Last_Consultation_Date--, ss.dataproximaconsulta as Next_Consultation_Date

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	--,Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1
	--END,
	--USG_Year = CASE WHEN cast(datainiciotarv as date) < cast(CONCAT('09/21','/',DATEPART(YY,cast(datainiciotarv as date))) as date) THEN DATEPART(YY, (DATEADD(year,0,cast(datainiciotarv as date))))
	--WHEN cast(datainiciotarv as date) >= cast(CONCAT('09/21','/',DATEPART(YY,cast(datainiciotarv as date))) as date) THEN DATEPART(YY, (DATEADD(year,1,cast(datainiciotarv as date))))
	--ELSE NULL
	--END
	FROM t_paciente) person

	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Outcome_Date, ntv.datatarv as Max_datatarv, ntv.dataproxima
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Outcome_Date
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Outcome_Date = dateadd(dd, 33, cast(datainiciotarv as date)), AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE datatarv <= Outcome_Date
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	-- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath, nts.dataseguimento as Max_dataseguimento, nts.dataproximaconsulta
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta, tpo1.Outcome_Date
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Outcome_Date = dateadd(dd, 33, cast(datainiciotarv as date)), AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE dataseguimento <= Outcome_Date
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),
CTE1 AS
( 
	SELECT *, 
	CASE 
	WHEN Outcome_Date > @CreationDate THEN 'Not Evaluated'
	WHEN 
	(
		(Exit_Date < Last_Drug_Pickup_Date) OR 
		(Exit_Date IS NULL) OR 
		(Exit_Date < Last_Consultation_Date) OR
		(Exit_Date > Outcome_Date)
	) AND
	( 
		(Last_Drug_Pickup_Date IS NOT NULL) OR 
		(Last_Consultation_Date IS NOT NULL)
	) AND
	(	
		((Last_Drug_Pickup_Date BETWEEN Initiation_Date AND Outcome_Date) AND Last_Drug_Pickup_Date!= Initiation_Date) OR 
		((Last_Consultation_Date BETWEEN Initiation_Date AND Outcome_Date) AND Last_Consultation_Date!= Initiation_Date)
	) THEN 'Retained'
	ELSE 'Not Retained'
	END AS [Retained_Status_1m]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, 
	CASE WHEN Retained_Status_1m = 'Not Retained' AND ((Last_Status = 'ABANDONO') OR (Last_Status IS NULL) AND (Exit_Date < Outcome_Date)) THEN 'LTFU'
	WHEN Retained_Status_1m = 'Not Retained' AND ((Last_Status = 'TRANSFERIDO PARA') AND (Exit_Date < Outcome_Date)) THEN 'Transferred Out'
	WHEN Retained_Status_1m = 'Not Retained' AND ((Last_Status = 'OBITOU') AND (Exit_Date < Outcome_Date)) THEN 'Dead'
	WHEN Retained_Status_1m = 'Not Retained' AND ((Last_Status IS NULL)) THEN 'LTFU'
	WHEN Retained_Status_1m = 'Retained' THEN 'Retained'
	WHEN Retained_Status_1m = 'Not Evaluated' THEN 'Not Evaluated'
	ELSE 'LTFU'
	END AS [Outcome_1m]
	FROM CTE1
)
SELECT *
INTO Sandbox.dbo.Retention_1m
FROM CTE2
WHERE Initiation_Date >= '2012-01-01' AND 
Outcome_Date IS NOT NULL AND 
Initiation_Date IS NOT NULL AND 
Last_Drug_Pickup_Date >= Initiation_Date
ORDER BY nid

