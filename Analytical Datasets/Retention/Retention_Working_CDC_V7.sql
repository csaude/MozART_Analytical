---- =========================================================================================================
---- WORKING SQL QUERY FOR RETENTION DATASET PRODUCTION
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- REV DATE: 6/27/2019
---- RetentionType: Variable in months to specify retention range (i.e. 1 for 1m retention, 12 for 12m retention
---- Pickup: Maxes on datatarv and dataseguimento before outcome date on filtered subset USING ROWNUMBERS
---- REMOVED GAAC and local
---- =========================================================================================================

IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID('[dbo].[RetentionGenerator]') AND type IN ('P', 'PC', 'RF', 'X'))
  DROP PROCEDURE [dbo].[RetentionGenerator]
GO

IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID('[Sandbox].[dbo].[retention_cohort_2012_2019]') AND type IN ('P', 'PC', 'RF', 'X'))
  DROP TABLE [Sandbox].[dbo].[retention_cohort_2012_2019]
GO


CREATE PROCEDURE [dbo].[RetentionGenerator] @RetentionType INTEGER 
AS


WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv, YEAR(person.datainiciotarv) as Cohort_Year, USG_Year, tt.Outcome_Date, person.datadiagnostico, person.datasaidatarv, person.codestado,
	tt.Max_datatarv, tt.dataproxima,
	ss.Max_dataseguimento, ss.dataproximaconsulta, person.Gravidez

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath,
	Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1
	END,
	USG_Year = CASE WHEN cast(datainiciotarv as date) < cast(CONCAT('09/21','/',DATEPART(YY,cast(datainiciotarv as date))) as date) THEN DATEPART(YY, (DATEADD(year,0,cast(datainiciotarv as date))))
	WHEN cast(datainiciotarv as date) >= cast(CONCAT('09/21','/',DATEPART(YY,cast(datainiciotarv as date))) as date) THEN DATEPART(YY, (DATEADD(year,1,cast(datainiciotarv as date))))
	ELSE NULL
	END
	FROM t_paciente) person

	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD AND person.AccessFilePath = facility.AccessFilePath

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Outcome_Date, ntv.datatarv as Max_datatarv, ntv.dataproxima
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Outcome_Date
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Outcome_Date = dateadd(mm, @RetentionType, cast(datainiciotarv as date)), AccessFilePath
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
		(SELECT nid, Outcome_Date = dateadd(mm, @RetentionType, cast(datainiciotarv as date)), AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE dataseguimento <= Outcome_Date
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),
/******************** Retention Flow Chart Coding ********************/
CTE1 AS
( 
	SELECT *, 
	CASE WHEN ((datasaidatarv < Max_datatarv) OR (datasaidatarv IS NULL) OR (datasaidatarv < Max_dataseguimento) OR(datasaidatarv > Outcome_Date)) AND 
	((Max_datatarv > dateadd(dd,-90,Outcome_Date) AND Max_datatarv <= Outcome_Date) OR (dataproxima > dateadd(dd,-60,Outcome_Date) AND dataproxima <= Outcome_Date) OR (Max_dataseguimento > dateadd(dd, -90, Outcome_Date) AND Max_dataseguimento <= Outcome_Date)) THEN 'Retained'
	Else 'Not Retained'
	END AS [Retained_Status]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN Retained_Status = 'Not Retained' AND ((codestado = 'ABANDONO') OR (codestado IS NULL) AND (datasaidatarv < Outcome_Date)) THEN 'LTFU'
	WHEN Retained_Status = 'Not Retained' AND ((codestado = 'TRANSFERIDO PARA') AND (datasaidatarv < Outcome_Date)) THEN 'Transferred Out'
	WHEN Retained_Status = 'Not Retained' AND ((codestado = 'OBITOU') AND (datasaidatarv < Outcome_Date)) THEN 'Dead'
	WHEN Retained_Status = 'Not Retained' AND ((codestado IS NULL)) THEN 'LTFU'
	WHEN Retained_Status = 'Retained' Then 'Retained'
	ELSE 'LTFU'
	END AS [Outcome]
	FROM CTE1)

SELECT *
INTO Sandbox.dbo.retention_cohort_2012_2019
FROM CTE2
WHERE datainiciotarv >= '2012' AND Outcome_Date IS NOT NULL
ORDER BY nid asc


Go
