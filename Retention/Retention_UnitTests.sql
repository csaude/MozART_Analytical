---- =========================================================================================================
---- RETENTION DATASET TESTS AND DEDUP
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- DATE: 6/14/2019
---- RetentionType: 12m Retention
---- =========================================================================================================

/******************** Declaring variables ********************/
DECLARE @idtest_AccessPath nvarchar(255)


/******************** Partner Lookup ********************/

-- Return the desired partner subset of patients
-- You will need to include % at the end of the partner abbreviation
-- FGH, FHI, EGP
DECLARE @partnertest nvarchar(255)
SET @partnertest = 'FGH%'
SELECT *
FROM Sandbox.dbo.retention_cohort_2012_2019
WHERE HdD like @partnertest


/******************** Patient Lookup ********************/

-- To trace a nid, change @idtest
DECLARE @idtest nvarchar(255)
SET @idtest = '0405000112000595990'

-- Check patient info in t_paciente
Select nid, datainiciotarv, datasaidatarv, codestado
From Mozart.dbo.t_paciente
where nid = @idtest

-- Checking patient drug pickup dates
---- 1) Check the latest drug pickup date (datatarv) within the outcome date 
---- 2) Check the latest next drug pickup date (dataproxima) within the outcome date
SELECT nid, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima
FROM Mozart.dbo.t_tarv
where nid = @idtest
ORDER BY datatarv ASC

-- Check patient followup dates
---- 1) Check the latest followup date (dataseguimento) within the outcome date
---- 2) Check the latest next date (dataproximaconsulta) within the outcome date
Select nid, idade, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
From Mozart.dbo.t_seguimento
where nid = @idtest
ORDER BY dataseguimento ASC

-- Check retention dataset
---- 1) Compare drug pickup and followup information in retention dataset
---- 2) Check outcome matches flowchart definitions
SELECT nid, datainiciotarv, Outcome_Date, datasaidatarv, codestado, Max_datatarv, Max_dataproxima, Max_dataseguimento, Max_dataproximaconsulta, Retained_Status, Outcome
FROM Sandbox.dbo.retention_cohort_2012_2019
where nid = @idtest




/******************** Patient Transfers ********************/
-- FINDING ALL duplicate nids with different outcomes
-- 1) Check if transfers, see if they have new and old facility
-- 2) True duplicates will have same facility, dates, and codestado

SELECT *
FROM Sandbox.dbo.retention_cohort_2012_2019
WHERE nid IN (
	SELECT nid
	FROM Sandbox.dbo.retention_cohort_2012_2019
	GROUP BY nid
	HAVING COUNT(*) > 1
)
ORDER BY nid ASC


-- Same nid, DOB, sex, BUT different facility -> should be coded transferred out
Select nid, datanasc, sexo, Count(Distinct designacao) As UniqueDesignacao
From Sandbox.dbo.retention_cohort_2012_2019
Group By nid, datanasc, sexo
Having Count(Distinct designacao) > 1


/******************** Dedup True Duplicates ********************/
---- Remove nids with same fields (would remove the repeated designacao)
--SELECT Distinct HdD, Provincia, Distrito, designacao, local, nid, sexo, idade, datainiciotarv, Cohort_Year, Outcome_Date, datadiagnostico, datasaidatarv,
--codestado, Max_datatarv, Max_dataproxima, Max_dataseguimento, Max_dataproximaconsulta, DatainicioGAAC, Gravidez, Outcome
----INTO Sandbox.dbo.retention_cohort_2012_2019_DEDUP
--FROM Sandbox.dbo.retention_cohort_2012_2019
--ORDER BY HdD, Provincia, Distrito, designacao, nid ASC


/******************** Remaining Duplicates ********************/
SELECT *
FROM Sandbox.dbo.retention_cohort_2012_2019_DEDUP
WHERE nid IN (
	SELECT nid
	FROM Sandbox.dbo.retention_cohort_2012_2019_DEDUP
	GROUP BY nid
	HAVING COUNT(*) > 1
)
ORDER BY nid ASC


-- Quality Issues? Followup dates < Actual Visits
SELECT *
FROM Sandbox.dbo.retention_cohort_2012_2019
WHERE Max_dataproxima < Max_datatarv OR Max_dataproximaconsulta < Max_dataseguimento


-- Duplicate nids with different DOBs
Select nid, sexo, Count(Distinct datanasc) As UniqueDOB
From Sandbox.dbo.retention_cohort_2012_2019
Group By nid, sexo
Having Count(Distinct datanasc) > 1

-- Duplicate nids with different Sex (ok?)
Select nid, datanasc, Count(Distinct sexo) As UniqueSEX
From Sandbox.dbo.retention_cohort_2012_2019
Group By nid, datanasc
Having Count(Distinct sexo) > 1

-- Duplicate nids with different initiation dates
Select nid, datanasc, sexo, Count(Distinct initiation_age) As UniqueIdade
From Sandbox.dbo.retention_cohort_2012_2019
Group By nid, datanasc, sexo
Having Count(Distinct initiation_age) > 1

-- Duplicate everything but nids?
-- These might be the same pts but were entered  > 1 times, nids erroneously assigned, or nids not preserved
Select designacao, datainiciotarv, datanasc, sexo, Max_datatarv, Count(Distinct nid) As Uniquenid
From Sandbox.dbo.retention_cohort_2012_2019
Group By designacao, datainiciotarv, datanasc, sexo, Max_datatarv
Having Count(Distinct nid) > 1
