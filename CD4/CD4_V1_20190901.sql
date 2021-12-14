---- =========================================================================================================
---- WORKING SQL QUERY FOR CD4 DATASET PRODUCTION (IMMUNOLOGICAL FAILURE)
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- CREATION DATE: 9/8/2019
---- DESCRIPTION: NID, Test Type, 
---- Date of First Result, Value of First Result (absolute and percent), 
---- Date of Next Result, Value of Next Result (absolute and percent),
---- Month(s) between First and Last Result Date, Day(s) between First and Last Result Date
---- =========================================================================================================

------------------------------------------------------ CD4 Percent ------------------------------------------------------

SELECT DISTINCT cdFirst.nid, cdFirst.codexame, first_result_date, 
first_result_percent, last_result_date, last_result_percent,
DATEDIFF(m, first_result_date, last_result_date) month_diff, DATEDIFF(d, first_result_date, last_result_date) day_diff
FROM
(
	SELECT nid, codexame, resultado as first_result_percent, CAST(dataresultado AS DATE) AS first_result_date,
	RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS first_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'PERCENTUAL'
) cdFirst
LEFT JOIN
(
	SELECT nid, codexame, resultado as last_result_percent, CAST(dataresultado AS DATE) AS last_result_date,
	RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) DESC) last_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'PERCENTUAL'
) cdLast
ON cdFirst.nid = cdLast.nid
WHERE first_rank = '1' AND last_rank = '1'
ORDER BY cdFirst.nid


------------------------------------------------------ CD4 Percent First-Next  ------------------------------------------------------

SELECT DISTINCT tp.hdd, hd.Provincia, hd.Distrito, hd.designacao, cdFirst.nid, tp.datanasc, Current_Age, 
tp.idade as idadeiniciotarv, tp.datainiciotarv,
first_result_date, first_result_percent, next_result_date, next_result_percent,
datediff(dd, first_result_date, next_result_date) AS first_second_datediff,
datediff(dd, datainiciotarv, first_result_date) AS initiation_first_datediff,
datediff(dd, datainiciotarv, next_result_date) AS initiation_second_datediff
FROM
(
	SELECT nid, codexame, resultado as first_result_percent, AccessFilePath, CAST(dataresultado AS DATE) AS first_result_date,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS first_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'PERCENTUAL' AND dataresultado IS NOT NULL
) cdFirst
LEFT JOIN
(
	SELECT * FROM
		(
			SELECT nid, codexame, resultado as next_result_percent, AccessFilePath, CAST(dataresultado AS DATE) AS next_result_date,
			DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS next_rank
			FROM t_resultadoslaboratorio
			WHERE codexame = 'CD4' AND codparametro = 'PERCENTUAL' AND dataresultado IS NOT NULL
		) cdNextInt 
	WHERE next_rank = '2'
) cdNext
ON cdFirst.nid = cdNext.nid
LEFT JOIN
t_paciente tp
ON cdFirst.nid = tp.nid AND cdFirst.AccessFilePath = tp.AccessFilePath
LEFT JOIN
t_hdd hd
ON tp.hdd = hd.HdD
WHERE first_rank = '1'






------------------------------------------ CD4 Absolute Counts (First and Last All Time) ------------------------------------------

SELECT DISTINCT cdFirst.nid, cdFirst.codexame, first_result_date, first_result_absolute,
CASE 
	WHEN first_result_absolute < 200 THEN 'SEVERE IMMUNOSUPPRESION'
	WHEN first_result_absolute between 200 AND 349 THEN 'ADVANCED IMMUNOSUPPRESION'
	WHEN first_result_absolute between 350 AND 499 THEN 'MILD IMMUNOSUPPRESION'
	WHEN first_result_absolute >= 500 THEN 'NOT SIGNIFICANT IMMUNOSUPPRESION'
	ELSE NULL
	END AS first_severity,
last_result_date, last_result_absolute,
CASE 
	WHEN last_result_absolute < 200 THEN 'SEVERE IMMUNOSUPPRESION'
	WHEN last_result_absolute between 200 AND 349 THEN 'ADVANCED IMMUNOSUPPRESION'
	WHEN last_result_absolute between 350 AND 499 THEN 'MILD IMMUNOSUPPRESION'
	WHEN last_result_absolute >= 500 THEN 'NOT SIGNIFICANT IMMUNOSUPPRESION'
	ELSE NULL
	END AS last_severity,
DATEDIFF(m, first_result_date, last_result_date) month_diff, DATEDIFF(d, first_result_date, last_result_date) day_diff
FROM
(
	SELECT nid, codexame, resultado as first_result_absolute, CAST(dataresultado AS DATE) AS first_result_date,
	RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS first_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO'
) cdFirst
LEFT JOIN
(
	SELECT nid, codexame, resultado as last_result_absolute, CAST(dataresultado AS DATE) AS last_result_date,
	RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) DESC) last_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO'
) cdLast
ON cdFirst.nid = cdLast.nid
WHERE first_rank = '1' AND last_rank = '1'
ORDER BY cdFirst.nid


------------------------------------------------------ CD4 Absolute Counts First-Next  ------------------------------------------------------

SELECT DISTINCT tp.hdd, hd.Provincia, hd.Distrito, hd.designacao, cdFirst.nid, tp.datanasc, Current_Age, 
tp.idade as idadeiniciotarv, tp.datainiciotarv,
first_result_date, 
CASE 
	WHEN first_result_absolute < 200 THEN 'SEVERE IMMUNOSUPPRESION'
	WHEN first_result_absolute between 200 AND 349 THEN 'ADVANCED IMMUNOSUPPRESION'
	WHEN first_result_absolute between 350 AND 499 THEN 'MILD IMMUNOSUPPRESION'
	WHEN first_result_absolute >= 500 THEN 'NOT SIGNIFICANT IMMUNOSUPPRESION'
	ELSE NULL
	END AS first_severity, 
next_result_date,
CASE 
	WHEN next_result_absolute < 200 THEN 'SEVERE IMMUNOSUPPRESION'
	WHEN next_result_absolute between 200 AND 349 THEN 'ADVANCED IMMUNOSUPPRESION'
	WHEN next_result_absolute between 350 AND 499 THEN 'MILD IMMUNOSUPPRESION'
	WHEN next_result_absolute >= 500 THEN 'NOT SIGNIFICANT IMMUNOSUPPRESION'
	ELSE NULL
	END AS next_severity,
datediff(dd, first_result_date, next_result_date) AS first_second_datediff,
datediff(dd, datainiciotarv, first_result_date) AS initiation_first_datediff,
datediff(dd, datainiciotarv, next_result_date) AS initiation_second_datediff
FROM
(
	SELECT nid, codexame, resultado as first_result_absolute, AccessFilePath, CAST(dataresultado AS DATE) AS first_result_date,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS first_rank
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
) cdFirst
LEFT JOIN
(
	SELECT * FROM
		(
			SELECT nid, codexame, resultado as next_result_absolute, AccessFilePath, CAST(dataresultado AS DATE) AS next_result_date,
			DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS next_rank
			FROM t_resultadoslaboratorio
			WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
		) cdNextInt 
	WHERE next_rank = '2'
) cdNext -- Gets the next date and result of 
ON cdFirst.nid = cdNext.nid
LEFT JOIN
t_paciente tp
ON cdFirst.nid = tp.nid AND cdFirst.AccessFilePath = tp.AccessFilePath
LEFT JOIN
t_hdd hd
ON tp.hdd = hd.HdD
WHERE first_rank = '1'


------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- Matrices ---------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------

-- 1) Date Matrix
-- 2) Absolute CD4 Matrix
-- 3) Categorized CD4 Matrix
-- 4) Percentage CD4 Matrix (May not match Absolute CD4 Matrix and may require a separate Date Matrix)

------------------------------------------------------ CD4 Date Matrix  ------------------------------------------------------

-- NID CD4 Date Matrix
--SELECT DISTINCT nid, codexame, CAST(dataresultado AS DATE) AS result_date,
--DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked, AccessFilePath
--FROM t_resultadoslaboratorio
--WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
--ORDER BY nid, ranked

-- Dynamic Pivot to create wide visit format
DECLARE @Columns as VARCHAR(MAX)
SELECT @Columns =
COALESCE(@Columns + ', ','') + QUOTENAME(ranked)
FROM
   (
   SELECT DISTINCT DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
   ) AS CD4A
   ORDER BY CD4A.ranked
 SELECT @Columns

DECLARE @SQL as VARCHAR(MAX)
SET @SQL = 'SELECT nid, ' + @Columns + '
FROM
(
   SELECT DISTINCT nid, codexame, CAST(dataresultado AS DATE) AS result_date,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranking
	FROM t_resultadoslaboratorio
	WHERE codexame = ''CD4'' AND codparametro = ''ABSOLUTO'' AND dataresultado IS NOT NULL
) as PivotData
PIVOT
(
   MAX(result_date)
   FOR ranking IN (' + @Columns + ')
) AS PivotResult
ORDER BY nid'

EXEC(@SQL)



--------------------------------------------------------------- NID CD4 Absolute Result Matrix -------------------------------------------------------------
--SELECT DISTINCT nid, codexame, resultado as result_absolute,
--DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked, AccessFilePath
--FROM t_resultadoslaboratorio
--WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
--ORDER BY nid, ranked

-- Dynamic Pivot to create wide visit format
DECLARE @Columns as VARCHAR(MAX)
SELECT @Columns =
COALESCE(@Columns + ', ','') + QUOTENAME(ranked)
FROM
   (
   SELECT DISTINCT DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
   ) AS CD4A
   ORDER BY CD4A.ranked
 SELECT @Columns

DECLARE @SQL as VARCHAR(MAX)
SET @SQL = 'SELECT nid, ' + @Columns + '
FROM
(
   SELECT DISTINCT nid, codexame, resultado as result_absolute,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranking
	FROM t_resultadoslaboratorio
	WHERE codexame = ''CD4'' AND codparametro = ''ABSOLUTO'' AND dataresultado IS NOT NULL
) as PivotData
PIVOT
(
   MAX(result_absolute)
   FOR ranking IN (' + @Columns + ')
) AS PivotResult
ORDER BY nid'

EXEC(@SQL)

------------------------------------------------------------- NID CD4 Coded Absolute Result Matrix -------------------------------------------------------------

-- Dynamic Pivot to create wide visit format
DECLARE @Columns as VARCHAR(MAX)
SELECT @Columns =
COALESCE(@Columns + ', ','') + QUOTENAME(ranked)
FROM
   (
   SELECT DISTINCT DENSE_RANK() OVER(PARTITION BY nid, codexame ORDER BY CAST(dataresultado AS DATE) ASC) AS ranked
	FROM t_resultadoslaboratorio
	WHERE codexame = 'CD4' AND codparametro = 'ABSOLUTO' AND dataresultado IS NOT NULL
   ) AS CD4A
   ORDER BY CD4A.ranked
 SELECT @Columns

DECLARE @SQL as VARCHAR(MAX)
SET @SQL = 'SELECT nid, ' + @Columns + '
FROM
(
   SELECT DISTINCT nid, codexame, CASE 
	WHEN resultado < 200 THEN ''SEVERE IMMUNOSUPPRESION''
	WHEN resultado between 200 AND 349 THEN ''ADVANCED IMMUNOSUPPRESION''
	WHEN resultado between 350 AND 499 THEN ''MILD IMMUNOSUPPRESION''
	WHEN resultado >= 500 THEN ''NOT SIGNIFICANT IMMUNOSUPPRESION''
	ELSE NULL
	END AS severity,
	DENSE_RANK() OVER(PARTITION BY nid, codexame, codparametro ORDER BY CAST(dataresultado AS DATE) ASC) AS ranking
	FROM t_resultadoslaboratorio
	WHERE codexame = ''CD4'' AND codparametro = ''ABSOLUTO'' AND dataresultado IS NOT NULL
) as PivotData
PIVOT
(
   MAX(severity)
   FOR ranking IN (' + @Columns + ')
) AS PivotResult
ORDER BY nid'

EXEC(@SQL)
