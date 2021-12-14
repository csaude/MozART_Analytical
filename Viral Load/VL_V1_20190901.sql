---- =========================================================================================================
---- WORKING SQL QUERY FOR VIRAL LOAD DATASET PRODUCTION (VIROLOGICAL FAILURE)
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- CREATION DATE: 9/8/2019
---- CRITERIA: Viral load above 1,000 copies/ml based on two consecutive viral load measurements in a
---- 3-month interval, with adherence support following the first viral load test, after at least six
---- months of starting a new ART regimen.
---- =========================================================================================================


SELECT DISTINCT tr.nid, codexame, CAST(dataresultado AS DATE) AS result_date,
	DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS date_ranked,
	CASE WHEN resultado >= 1000 THEN 'FAILED'
	WHEN resultado < 1000 THEN 'NOT FAILED'
	ELSE NULL
	END AS VL_Status
FROM t_resultadoslaboratorio tr
LEFT JOIN
t_paciente tp
ON tp.nid = tr.nid AND tp.AccessFilePath = tr.AccessFilePath
WHERE codexame = 'CARGA VIRAL' AND 
dataresultado IS NOT NULL AND 
resultado IS NOT NULL
ORDER BY nid
-- Carga Viral does not have codparametro
-- Removed resultado to capture repeat tests with same outcome
-- Import into Power BI to pivot


-------------------------------------------------------------------------------------------------------------------------------------------------------

-- TX_PVLS
-- Number of ART patients with suppressed VL results (<1,000 copies/ml) documented in the medical or laboratory records/LIS within the past 12 months
-- If there is more than one VL result for a patient during the past 12 months, report the most recent result.
-- Only patients who have been on ART for at least 3 months should be considered.


SELECT DISTINCT tp.HdD, distrito, provincia, designacao, tr.nid, tp.sexo, Time_on_ART = datediff(mm, cast(datainiciotarv as date), '2019-06-30'), codexame, --CAST(dataresultado AS DATE) AS result_date,
	CASE WHEN resultado >= 1000 THEN 'FAILED'
	WHEN resultado < 1000 THEN 'NOT FAILED'
	ELSE NULL
	END AS VL_Status
--INTO Sandbox.dbo.TX_PVLSQ3
FROM t_resultadoslaboratorio tr
LEFT JOIN
t_paciente tp
ON tr.nid = tp.nid AND tr.AccessFilePath = tp.AccessFilePath
LEFT JOIN
t_hdd th
ON tp.hdd = th.HdD
WHERE codexame = 'CARGA VIRAL' AND 
dataresultado IS NOT NULL AND 
resultado IS NOT NULL AND
datediff(mm, cast(datainiciotarv as date), '2019-06-21') >= '3'
AND CAST(dataresultado AS DATE) BETWEEN '2018-06-21' AND '2019-06-21'
ORDER BY nid


------------------------------------------------------ VL Date Matrix  ------------------------------------------------------

-- Dynamic Pivot to create wide visit format
DECLARE @Columns as VARCHAR(MAX)
SELECT @Columns =
COALESCE(@Columns + ', ','') + QUOTENAME(ranked)
FROM
   (
   SELECT DISTINCT DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked
	FROM t_resultadoslaboratorio
	WHERE codexame = 'Carga Viral' AND dataresultado IS NOT NULL
   ) AS vl
   ORDER BY vl.ranked
 SELECT @Columns

DECLARE @SQL as VARCHAR(MAX)
SET @SQL = 'SELECT nid, ' + @Columns + '
FROM
(
   SELECT DISTINCT nid, codexame, CAST(dataresultado AS DATE) AS result_date,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranking
	FROM t_resultadoslaboratorio
	WHERE codexame = ''Carga Viral'' AND dataresultado IS NOT NULL
) as PivotData
PIVOT
(
   MAX(result_date)
   FOR ranking IN (' + @Columns + ')
) AS PivotResult
ORDER BY nid'

EXEC(@SQL)


--------------------------------------------------------------- VL Result Matrix -------------------------------------------------------------

-- Dynamic Pivot to create wide visit format
DECLARE @Columns as VARCHAR(MAX)
SELECT @Columns =
COALESCE(@Columns + ', ','') + QUOTENAME(ranked)
FROM
   (
   SELECT DISTINCT DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked
	FROM t_resultadoslaboratorio
	WHERE codexame = 'Carga Viral' AND dataresultado IS NOT NULL
   ) AS vl
   ORDER BY vl.ranked
 SELECT @Columns

DECLARE @SQL as VARCHAR(MAX)
SET @SQL = 'SELECT nid, ' + @Columns + '
FROM
(
   SELECT DISTINCT nid, codexame, resultado as result_absolute,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranking
	FROM t_resultadoslaboratorio
	WHERE codexame = ''Carga Viral'' AND dataresultado IS NOT NULL
) as PivotData
PIVOT
(
   MAX(result_absolute)
   FOR ranking IN (' + @Columns + ')
) AS PivotResult
ORDER BY nid'

EXEC(@SQL)
