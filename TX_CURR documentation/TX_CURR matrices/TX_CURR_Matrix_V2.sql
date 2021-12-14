---- =========================================================================================================
---- WORKING SQL QUERY FOR TX_CURR MATRICES PRODUCTION
---- AUTHOR: RANDY YEE (CDC/GDIT) BASED ON WORK BY Mala (CDC/GDIT) and Timoteo (CDC-MOZ)
---- CREATION DATE: 9/12/2019
---- CRITERIA:
---- 1) Initiation date assessed for each month period
---- 2) Any drug pickup, scheduled drug pickup, consultation during the month period will be defined as 'Activity'
---- =========================================================================================================

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------- Drug Pickup Matrix  ----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS [Sandbox].[dbo].[TXC_Drug_Pickup_Matrix],
[Sandbox].[dbo].[TXC_Next_Drug_Pickup_Matrix],
[Sandbox].[dbo].[TXC_Consultation_Matrix],
[Sandbox].[dbo].[TXC_Exit_Matrix],
[Sandbox].[dbo].[TXC_Coded_Exit_Matrix],
[Sandbox].[dbo].[TXC_Initiation_Matrix]

DECLARE @StartDate DATE;
SET @StartDate = '2018-05-21'

SELECT * 
INTO Sandbox.dbo.TXC_Drug_Pickup_Matrix 
FROM(
 
 SELECT nid, drug_pickup, 
 --CASE WHEN nid IS NOT NULL THEN 1 ELSE 0 END AS pick_up,
 CASE 
	WHEN drug_pickup BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN drug_pickup BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN drug_pickup BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN drug_pickup BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN drug_pickup BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'Not Activity'
	END as 'Activity'
 FROM 
 (
	SELECT *, cast(datatarv as date) as drug_pickup FROM t_tarv) tt 
	WHERE cast(datatarv as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm
PIVOT(
	MAX(drug_pickup)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS drug_pickup_matrix
ORDER BY nid


 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ----------------------------------------------------------------------------- Next Drug Pickup Matrix  -----------------------------------------------------------------------------
 ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
INTO Sandbox.dbo.TXC_Next_Drug_Pickup_Matrix 
FROM(
 
 SELECT nid, next_drug_pickup,
 CASE 
	WHEN next_drug_pickup BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN next_drug_pickup BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'No Activity'
	END as 'Activity'
 FROM 
 (
	SELECT *, cast(dataproxima as date) as next_drug_pickup FROM t_tarv) tt 
	WHERE cast(dataproxima as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm
PIVOT(
	MAX(next_drug_pickup)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS next_drug_pickup_matrix
 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------- Consultation Matrix  ---------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * 
INTO Sandbox.dbo.TXC_Consultation_Matrix 
FROM(
 
 SELECT nid, consultation_date,
 CASE 
	WHEN consultation_date BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN consultation_date BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN consultation_date BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN consultation_date BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN consultation_date BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'No Activity'
	END as 'Activity'
 FROM 
 (SELECT *, cast(dataseguimento as date) as consultation_date FROM t_seguimento) tt 
 WHERE cast(dataseguimento as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm

PIVOT(
	MAX(consultation_date)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS consultation_matrix


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------- Initiation Matrix  -----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 SELECT * 
 INTO Sandbox.dbo.TXC_Initiation_Matrix 
 FROM(
 
 SELECT nid, initiation_date,
 CASE 
	WHEN initiation_date BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN initiation_date BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN initiation_date BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN initiation_date BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN initiation_date BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'No Activity'
	END as 'Activity'
 FROM 
 (SELECT *, cast(datainiciotarv as date) as initiation_date FROM t_paciente) tt 
 WHERE cast(datainiciotarv as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm

PIVOT(
	MAX(initiation_date)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS initation_matrix


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------- Exit Matrix  -----------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 SELECT * 
 INTO Sandbox.dbo.TXC_Exit_Matrix 
 FROM(
 
 SELECT nid, exit_date,
 CASE 
	WHEN exit_date BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'Not Activity'
	END as 'Activity'
 FROM 
 (SELECT *, cast(datasaidatarv as date) as exit_date FROM t_paciente) tt 
 WHERE cast(datasaidatarv as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm

PIVOT(
	MAX(exit_date)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS exit_matrix

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------- Coded Exit Matrix  -----------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

 SELECT * 
 INTO Sandbox.dbo.TXC_Coded_Exit_Matrix 
 FROM(
 
 SELECT nid, codestado,
 CASE 
	WHEN exit_date BETWEEN @StartDate AND DATEADD(mm, 1,  DATEADD(dd, -1, @StartDate)) THEN '1_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 1, @StartDate) AND DATEADD(mm, 2, DATEADD(dd, -1, @StartDate)) THEN '2_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 2, @StartDate) AND DATEADD(mm, 3, DATEADD(dd, -1, @StartDate)) THEN '3_Activity' 
	WHEN exit_date BETWEEN DATEADD(mm, 3, @StartDate) AND DATEADD(mm, 4, DATEADD(dd, -1, @StartDate)) THEN '4_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 4, @StartDate) AND DATEADD(mm, 5, DATEADD(dd, -1, @StartDate)) THEN '5_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 5, @StartDate) AND DATEADD(mm, 6, DATEADD(dd, -1, @StartDate)) THEN '6_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 6, @StartDate) AND DATEADD(mm, 7, DATEADD(dd, -1, @StartDate)) THEN '7_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 7, @StartDate) AND DATEADD(mm, 8, DATEADD(dd, -1, @StartDate)) THEN '8_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 8, @StartDate) AND DATEADD(mm, 9, DATEADD(dd, -1, @StartDate)) THEN '9_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 9, @StartDate) AND DATEADD(mm, 10, DATEADD(dd, -1, @StartDate)) THEN '10_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 10, @StartDate) AND DATEADD(mm, 11, DATEADD(dd, -1, @StartDate)) THEN '11_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 11, @StartDate) AND DATEADD(mm, 12, DATEADD(dd, -1, @StartDate)) THEN '12_Activity'
	WHEN exit_date BETWEEN DATEADD(mm, 12, @StartDate) AND DATEADD(mm, 13, DATEADD(dd, -1, @StartDate)) THEN '13_Activity'
	ELSE 'No Activity'
	END as 'Activity'
 FROM 
 (SELECT *, cast(datasaidatarv as date) as exit_date FROM t_paciente) tt 
 WHERE cast(datasaidatarv as date) BETWEEN @StartDate AND DATEADD(mm, 13, @StartDate)
 ) dpm

PIVOT(
	MAX(codestado)
	FOR Activity IN(
	[1_Activity],
	[2_Activity],
	[3_Activity],
	[4_Activity],
	[5_Activity],
	[6_Activity],
	[7_Activity],
	[8_Activity],
	[9_Activity],
	[10_Activity],
	[11_Activity],
	[12_Activity],
	[13_Activity]
	)
)
AS coded_exit_matrix
