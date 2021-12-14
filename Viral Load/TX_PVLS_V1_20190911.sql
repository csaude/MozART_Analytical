---- =========================================================================================================
---- WORKING SQL QUERY FOR TX_PVLS MozART EDITION
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- REV DATE: 9/11/2019
---- DEFINITION: Number of ART patients with suppressed VL results (<1,000 copies/ml) documented in the medical or laboratory records/LIS within the past 12 months
---- If there is more than one VL result for a patient during the past 12 months, report the most recent result.
---- Only patients who have been on ART for at least 3 months should be considered.
---- =========================================================================================================


IF EXISTS (SELECT * FROM sys.all_objects WHERE object_id = OBJECT_ID('[dbo].[TX_PVLS_Generator]') AND type IN ('P', 'PC', 'RF', 'X'))
  DROP PROCEDURE [dbo].[TX_PVLS_Generator]
GO

IF OBJECT_ID('[Sandbox].[dbo].[TX_PVLS]', N'U') IS NOT NULL
  DROP TABLE [Sandbox].[dbo].[TX_PVLS]
GO

CREATE PROCEDURE [dbo].[TX_PVLS_Generator] @CreationDate Date
AS

SELECT DISTINCT tp.HdD, provincia as Province, distrito AS District, designacao as Health_Facility, 
tr.nid as NID, tp.sexo as Sex, Initiation_Date, Time_on_ART,
Result_Date, VL_Status
INTO Sandbox.dbo.TX_PVLS
FROM (
	SELECT * FROM(
		SELECT nid, codexame, AccessFilePath, CAST(dataresultado as date) as Result_Date,
			CASE WHEN resultado >= 1000 THEN 'FAILED'
			WHEN resultado < 1000 THEN 'NOT FAILED'
			ELSE NULL
			END AS VL_Status,
			ROW_NUMBER() OVER (PARTITION BY nid, codexame ORDER BY cast(dataresultado as date) desc) as rownum
		FROM t_resultadoslaboratorio
		WHERE codexame = 'CARGA VIRAL' AND 
			dataresultado IS NOT NULL AND 
			resultado IS NOT NULL
		) trr WHERE rownum = '1'
	) tr
LEFT JOIN
(SELECT hdd, nid, sexo, cast(datainiciotarv as date) as Initiation_Date, Time_on_ART = DATEDIFF(mm, CAST(datainiciotarv as date), @CreationDate), AccessFilePath
FROM t_paciente) tp
ON tr.nid = tp.nid AND tr.AccessFilePath = tp.AccessFilePath
LEFT JOIN
t_hdd th
ON tp.hdd = th.HdD
WHERE
datediff(mm, Initiation_Date, @CreationDate) >= '3'
AND Result_Date BETWEEN dateadd(yy, -1, @CreationDate) AND @CreationDate
ORDER BY tr.nid
