---- =========================================================================================================
---- WORKING SQL QUERY FOR TX_CURR (AJUDA) DATASET PRODUCTION
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: Mala (CDC/GDIT) and Timoteo (CDC-MOZ) based on original by Randy (CDC/GDIT)
---- REV DATE: 6/AUG/2019
---- Pickup: Maxes on datatarv and dataseguimento before outcome date on filtered subset USING ROWNUMBERS
---- =========================================================================================================

--******************CHANGES.....08.29.2019.....**************************
----need to change 'outcome date' to 'status evaluation date'
--need to define status evaluation date ( can we define 6 different ones?) 
---		ADD that patient need to be enrolled in program (dataabertura in t_patiente is not null) (done)
---		exclude patients who do not have Max_dataproxima
----	Don't need the condition of being active if in future because it is already included (done)
			/*-- For transfer outs ensure that if saida is after MAX_TARV (actual pick up) and after MAX_Seguimento (actual consultation) 
			--	but before evaluation date patients are considered not active (done)*/

--******************CHANGES.....09.09.2019.....**************************
----exclude people who are not in the program. They are not LTFU. So don't calculate TX_CURR Active or not for them.



-----	=================================== OCTOBER 2018   

WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	, YEAR(person.datainiciotarv) as Year_Inicio, person.datadiagnostico,  
	tt.Max_datatarv_OCT18, ss.Max_dataseguimento_OCT18,person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date_OCT18, tt.Max_dataproxima_tarv_OCT18, ss.Max_dataproximaconsult_OCT18 /*, person.Gravidez*/

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	/*,Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1 END */
	FROM t_paciente) person
	/*
	LEFT JOIN
	(SELECT nid, gravida, AccessFilePath
	FROM t_adulto) adult
	on person.nid=adult.nid AND person.AccessFilePath=adult.AccessFilePath
	*/
	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date_OCT18
	, ntv.datatarv as Max_datatarv_OCT18, ntv.dataproxima as Max_dataproxima_tarv_OCT18
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date_OCT18
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date_OCT18 = '2018-10-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date_OCT18
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	-- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento_OCT18, nts.dataproximaconsulta as Max_dataproximaconsult_OCT18
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date_OCT18
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date_OCT18 = '2018-10-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date_OCT18
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating TX_CURR (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/
CTE1 AS   
( 
	SELECT *, 
	CASE WHEN 
	dataabertura IS NOT NULL AND
	(Max_dataproxima_tarv_OCT18 IS NOT NULL AND Max_dataproximaconsult_OCT18 IS NOT NULL) AND
(
	(
		(cast(datainiciotarv AS DATE) <Evaluation_Date_OCT18) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv_OCT18 >= dateadd(dd,-30,Evaluation_Date_OCT18)) OR 
						(Max_dataproximaconsult_OCT18 >= dateadd(dd, -30, Evaluation_Date_OCT18))
				)
				 
	)
		
	
							OR
	
	(	
		(cast(datainiciotarv AS DATE) <Evaluation_Date_OCT18) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date_OCT18) AND
			
				(	(Max_dataproxima_tarv_OCT18 >= dateadd(dd,-30,Evaluation_Date_OCT18)) OR 
					(Max_dataproximaconsult_OCT18 >= dateadd(dd, -30, Evaluation_Date_OCT18)) 
				)
					
			)
	)

	
							OR 
	(	
		(cast(datainiciotarv AS DATE) < Evaluation_Date_OCT18) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date_OCT18) AND 
					((datasaidatarv<Max_datatarv_OCT18 AND datasaidatarv<Max_dataseguimento_OCT18)	OR
					(datasaidatarv<Max_datatarv_OCT18 AND Max_dataseguimento_OCT18 IS NULL)			OR
					(Max_datatarv_OCT18 IS NULL AND datasaidatarv <Max_dataseguimento_OCT18))		AND
					
						(Max_dataproxima_tarv_OCT18 >= dateadd(dd,-30,Evaluation_Date_OCT18))		OR 
						(Max_dataproximaconsult_OCT18 >= dateadd(dd, -30, Evaluation_Date_OCT18))
			
		)
)
)
	THEN 'Active'

	Else 'Not Active'
	END AS [TX_CURR_OCT18]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_OCT18 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date_OCT18 THEN 'Abandon'
	WHEN TX_CURR_OCT18 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date_OCT18 THEN 'ART Suspend'
	WHEN TX_CURR_OCT18 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date_OCT18 THEN 'Transferred Out'
	WHEN TX_CURR_OCT18 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date_OCT18 THEN 'Dead'
	WHEN TX_CURR_OCT18 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_OCT18 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_OCT18]
	FROM CTE1)


/******just insert new tx_curr based on status******/

-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_OCT18
FROM CTE2
/*WHERE datainiciotarv >= '2012' AND  Evaluation_Date IS NOT NULL*/
ORDER BY nid, Outcome_OCT18  desc

UPDATE Sandbox.dbo.TX_CURR_OCT18
SET Evaluation_Date_OCT18='2018-10-21'
Where Evaluation_Date_OCT18 is null

UPDATE Sandbox.dbo.TX_CURR_OCT18
SET Outcome_OCT18='LTFU' WHERE Outcome_OCT18 is null AND datasaidatarv > Evaluation_Date_OCT18 AND 
((Max_dataproxima_tarv_OCT18 < dateadd(dd,-30,Evaluation_Date_OCT18)) OR 
(Max_dataproximaconsult_OCT18 < dateadd(dd, -30, Evaluation_Date_OCT18)))

Update Sandbox.dbo.TX_CURR_OCT18			/*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_OCT18='LTFU' WHERE Outcome_OCT18 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv_OCT18 < dateadd(dd,-30,Evaluation_Date_OCT18)) OR 
(Max_dataproximaconsult_OCT18 < dateadd(dd, -30, Evaluation_Date_OCT18)))


Go





---	===================++++++++++++++++++++++++++++++ NOVEMBER 2018
WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	, YEAR(person.datainiciotarv) as Year_Inicio, person.datadiagnostico,  
	tt.Max_datatarv_NOV18, ss.Max_dataseguimento_NOV18,person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date_NOV18, tt.Max_dataproxima_tarv_NOV18, ss.Max_dataproximaconsult_NOV18 /*, person.Gravidez*/

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	/*,Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1 END */
	FROM t_paciente) person
	/*
	LEFT JOIN
	(SELECT nid, gravida, AccessFilePath
	FROM t_adulto) adult
	on person.nid=adult.nid AND person.AccessFilePath=adult.AccessFilePath
	*/
	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD AND person.AccessFilePath = facility.AccessFilePath

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date_NOV18
	, ntv.datatarv as Max_datatarv_NOV18, ntv.dataproxima as Max_dataproxima_tarv_NOV18
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date_NOV18
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date_NOV18 = '2018-11-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date_NOV18
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	-- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento_NOV18, nts.dataproximaconsulta as Max_dataproximaconsult_NOV18
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date_NOV18
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date_NOV18 = '2018-11-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date_NOV18
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating TX_CURR (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/
CTE1 AS   
( 
	SELECT *, 
	CASE WHEN 
	dataabertura IS NOT NULL AND
	(Max_dataproxima_tarv_NOV18 IS NOT NULL AND Max_dataproximaconsult_NOV18 IS NOT NULL) AND
(
	(
		(cast(datainiciotarv AS DATE) <Evaluation_Date_NOV18) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv_NOV18 >= dateadd(dd,-30,Evaluation_Date_NOV18)) OR 
						(Max_dataproximaconsult_NOV18 >= dateadd(dd, -30, Evaluation_Date_NOV18))
				)
				 
	)
		
	
							OR
	
	(	
		(cast(datainiciotarv AS DATE) <Evaluation_Date_NOV18) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date_NOV18) AND
			
				(	(Max_dataproxima_tarv_NOV18 >= dateadd(dd,-30,Evaluation_Date_NOV18)) OR 
					(Max_dataproximaconsult_NOV18 >= dateadd(dd, -30, Evaluation_Date_NOV18)) 
				)
					
			)
	)

	
							OR 
	(	
		(cast(datainiciotarv AS DATE) < Evaluation_Date_NOV18) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date_NOV18) AND 
					((datasaidatarv<Max_datatarv_NOV18 AND datasaidatarv<Max_dataseguimento_NOV18)	OR
					(datasaidatarv<Max_datatarv_NOV18 AND Max_dataseguimento_NOV18 IS NULL)			OR
					(Max_datatarv_NOV18 IS NULL AND datasaidatarv <Max_dataseguimento_NOV18))		AND
					
						(Max_dataproxima_tarv_NOV18 >= dateadd(dd,-30,Evaluation_Date_NOV18))		OR 
						(Max_dataproximaconsult_NOV18 >= dateadd(dd, -30, Evaluation_Date_NOV18))
			
		)
)
)
	THEN 'Active'

	Else 'Not Active'
	END AS [TX_CURR_NOV18]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_NOV18 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date_NOV18 THEN 'Abandon'
	WHEN TX_CURR_NOV18 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date_NOV18 THEN 'ART Suspend'
	WHEN TX_CURR_NOV18 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date_NOV18 THEN 'Transferred Out'
	WHEN TX_CURR_NOV18 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date_NOV18 THEN 'Dead'
	WHEN TX_CURR_NOV18 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_NOV18 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_NOV18]
	FROM CTE1)

-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_NOV18
FROM CTE2
/*WHERE datainiciotarv >= '2012' AND  Evaluation_Date_NOV18 IS NOT NULL*/
ORDER BY nid, Outcome_NOV18  desc


UPDATE Sandbox.dbo.TX_CURR_NOV18
SET Evaluation_Date_NOV18='2018-11-21'
Where Evaluation_Date_NOV18 is null

UPDATE Sandbox.dbo.TX_CURR_NOV18
SET Outcome_NOV18='LTFU' WHERE Outcome_NOV18 is null AND datasaidatarv > Evaluation_Date_NOV18 AND 
((Max_dataproxima_tarv_NOV18 < dateadd(dd,-30,Evaluation_Date_NOV18)) OR 
(Max_dataproximaconsult_NOV18< dateadd(dd, -30, Evaluation_Date_NOV18)))

Update Sandbox.dbo.TX_CURR_NOV18  /*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_NOV18='LTFU' WHERE Outcome_NOV18 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv_NOV18 < dateadd(dd,-30,Evaluation_Date_NOV18)) OR 
(Max_dataproximaconsult_NOV18< dateadd(dd, -30, Evaluation_Date_NOV18)))
Go




-----============================== MAY 2019



WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	, YEAR(person.datainiciotarv) as Year_Inicio, person.datadiagnostico,  
	tt.Max_datatarv_MAY19, ss.Max_dataseguimento_MAY19,person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date_MAY19, tt.Max_dataproxima_tarv_MAY19, ss.Max_dataproximaconsult_MAY19 /*, person.Gravidez*/

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	/*,Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1 END */
	FROM t_paciente) person
	/*
	LEFT JOIN
	(SELECT nid, gravida, AccessFilePath
	FROM t_adulto) adult
	on person.nid=adult.nid AND person.AccessFilePath=adult.AccessFilePath
	*/
	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD AND person.AccessFilePath = facility.AccessFilePath

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date_MAY19
	, ntv.datatarv as Max_datatarv_MAY19, ntv.dataproxima as Max_dataproxima_tarv_MAY19
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date_MAY19
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date_MAY19 = '2019-05-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date_MAY19
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	-- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento_MAY19, nts.dataproximaconsulta as Max_dataproximaconsult_MAY19
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date_MAY19
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date_MAY19 = '2019-05-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date_MAY19
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating TX_CURR (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/
CTE1 AS   
( 
	SELECT *, 
	CASE WHEN 
	dataabertura IS NOT NULL AND
	(Max_dataproxima_tarv_MAY19 IS NOT NULL AND Max_dataproximaconsult_MAY19 IS NOT NULL) AND
(
	(
		(cast(datainiciotarv AS DATE) <Evaluation_Date_MAY19) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv_MAY19 >= dateadd(dd,-30,Evaluation_Date_MAY19)) OR 
						(Max_dataproximaconsult_MAY19 >= dateadd(dd, -30, Evaluation_Date_MAY19))
				)
				 
	)
		
	
							OR
	
	(	
		(cast(datainiciotarv AS DATE) <Evaluation_Date_MAY19) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date_MAY19) AND
			
				(	(Max_dataproxima_tarv_MAY19 >= dateadd(dd,-30,Evaluation_Date_MAY19)) OR 
					(Max_dataproximaconsult_MAY19 >= dateadd(dd, -30, Evaluation_Date_MAY19)) 
				)
					
			)
	)

	
							OR 
	(	
		(cast(datainiciotarv AS DATE) < Evaluation_Date_MAY19) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date_MAY19) AND 
					((datasaidatarv<Max_datatarv_MAY19 AND datasaidatarv<Max_dataseguimento_MAY19)	OR
					(datasaidatarv<Max_datatarv_MAY19 AND Max_dataseguimento_MAY19 IS NULL)			OR
					(Max_datatarv_MAY19 IS NULL AND datasaidatarv <Max_dataseguimento_MAY19))		AND
					
						(Max_dataproxima_tarv_MAY19 >= dateadd(dd,-30,Evaluation_Date_MAY19))		OR 
						(Max_dataproximaconsult_MAY19 >= dateadd(dd, -30, Evaluation_Date_MAY19))
			
		)
)
)
	THEN 'Active'

	Else 'Not Active'
	END AS [TX_CURR_MAY19]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_MAY19 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date_MAY19 THEN 'Abandon'
	WHEN TX_CURR_MAY19 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date_MAY19 THEN 'ART Suspend'
	WHEN TX_CURR_MAY19 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date_MAY19 THEN 'Transferred Out'
	WHEN TX_CURR_MAY19 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date_MAY19 THEN 'Dead'
	WHEN TX_CURR_MAY19 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_MAY19 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_MAY19]
	FROM CTE1)

-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_MAY19
FROM CTE2
/*WHERE datainiciotarv >= '2012' AND  Evaluation_Date_MAY19 IS NOT NULL*/
ORDER BY nid, Outcome_MAY19  desc

UPDATE Sandbox.dbo.TX_CURR_MAY19
SET Evaluation_Date_MAY19='2019-05-21'
Where Evaluation_Date_MAY19 is null

UPDATE Sandbox.dbo.TX_CURR_MAY19
SET Outcome_MAY19='LTFU' WHERE Outcome_MAY19 is null AND datasaidatarv > Evaluation_Date_MAY19 AND 
((Max_dataproxima_tarv_MAY19 < dateadd(dd,-30,Evaluation_Date_MAY19)) OR 
(Max_dataproximaconsult_MAY19 < dateadd(dd, -30, Evaluation_Date_MAY19)))

Update Sandbox.dbo.TX_CURR_MAY19    /*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_MAY19='LTFU' WHERE Outcome_MAY19 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv_MAY19 < dateadd(dd,-30,Evaluation_Date_MAY19)) OR 
(Max_dataproximaconsult_MAY19 < dateadd(dd, -30, Evaluation_Date_MAY19)))

Go



---================+++++++++++++++++++++++++++++++++++++++	JUNE 2019

WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	, YEAR(person.datainiciotarv) as Year_Inicio, person.datadiagnostico,  
	tt.Max_datatarv_JUN19, ss.Max_dataseguimento_JUN19,person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date_JUN19, tt.Max_dataproxima_tarv_JUN19, ss.Max_dataproximaconsult_JUN19 /*, person.Gravidez*/

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	/*,Gravidez = CASE WHEN codproveniencia = 'PTV' AND idade >= '14' Then 1 END */
	FROM t_paciente) person
	/*
	LEFT JOIN
	(SELECT nid, gravida, AccessFilePath
	FROM t_adulto) adult
	on person.nid=adult.nid AND person.AccessFilePath=adult.AccessFilePath
	*/
	LEFT JOIN
	(SELECT HdD, Provincia, Distrito, designacao, AccessFilePath
	FROM t_hdd) facility
	ON person.hdd = facility.HdD AND person.AccessFilePath = facility.AccessFilePath

	-- Joining subset of filtered dates from t_tarv below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY ntv.datatarv desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date_JUN19
	, ntv.datatarv as Max_datatarv_JUN19, ntv.dataproxima as Max_dataproxima_tarv_JUN19
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date_JUN19
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date_JUN19 = '2019-06-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date_JUN19
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	-- Joining subset of filtered dates from t_seguimento below @RetentionType outcome date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.dataseguimento desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento_JUN19, nts.dataproximaconsulta as Max_dataproximaconsult_JUN19
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date_JUN19
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date_JUN19 = '2019-06-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date_JUN19
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating TX_CURR (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/
CTE1 AS   
( 
	SELECT *, 
	CASE WHEN 
	dataabertura IS NOT NULL AND
	(Max_dataproxima_tarv_JUN19 IS NOT NULL AND Max_dataproximaconsult_JUN19 IS NOT NULL) AND
(
	(
		(cast(datainiciotarv AS DATE) <Evaluation_Date_JUN19) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv_JUN19 >= dateadd(dd,-30,Evaluation_Date_JUN19)) OR 
						(Max_dataproximaconsult_JUN19 >= dateadd(dd, -30, Evaluation_Date_JUN19))
				)
				 
	)
		
	
							OR
	
	(	
		(cast(datainiciotarv AS DATE) <Evaluation_Date_JUN19) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date_JUN19) AND
			
				(	(Max_dataproxima_tarv_JUN19 >= dateadd(dd,-30,Evaluation_Date_JUN19)) OR 
					(Max_dataproximaconsult_JUN19 >= dateadd(dd, -30, Evaluation_Date_JUN19)) 
				)
					
			)
	)

	
							OR 
	(	
		(cast(datainiciotarv AS DATE) < Evaluation_Date_JUN19) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date_JUN19) AND 
					((datasaidatarv<Max_datatarv_JUN19 AND datasaidatarv<Max_dataseguimento_JUN19)	OR
					(datasaidatarv<Max_datatarv_JUN19 AND Max_dataseguimento_JUN19 IS NULL)			OR
					(Max_datatarv_JUN19 IS NULL AND datasaidatarv <Max_dataseguimento_JUN19))		AND
					
						(Max_dataproxima_tarv_JUN19 >= dateadd(dd,-30,Evaluation_Date_JUN19))		OR 
						(Max_dataproximaconsult_JUN19 >= dateadd(dd, -30, Evaluation_Date_JUN19))
			
		)
)
)
	THEN 'Active'

	Else 'Not Active'
	END AS [TX_CURR_JUN19]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_JUN19 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date_JUN19 THEN 'Abandon'
	WHEN TX_CURR_JUN19 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date_JUN19 THEN 'ART Suspend'
	WHEN TX_CURR_JUN19 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date_JUN19 THEN 'Transferred Out'
	WHEN TX_CURR_JUN19 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date_JUN19 THEN 'Dead'
	WHEN TX_CURR_JUN19 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_JUN19 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_JUN19]
	FROM CTE1)

-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_JUN19
FROM CTE2
/*WHERE datainiciotarv >= '2012' AND  Evaluation_Date_JUN19 IS NOT NULL*/
ORDER BY nid, Outcome_JUN19  desc

UPDATE Sandbox.dbo.TX_CURR_JUN19
SET Evaluation_Date_JUN19='2019-06-21'
Where Evaluation_Date_JUN19 is null

UPDATE Sandbox.dbo.TX_CURR_JUN19
SET Outcome_JUN19='LTFU' WHERE Outcome_JUN19 is null AND datasaidatarv > Evaluation_Date_JUN19 AND 
((Max_dataproxima_tarv_JUN19 < dateadd(dd,-30,Evaluation_Date_JUN19)) OR 
(Max_dataproximaconsult_JUN19 < dateadd(dd, -30, Evaluation_Date_JUN19)))

Update Sandbox.dbo.TX_CURR_JUN19	/*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_JUN19='LTFU' WHERE Outcome_JUN19 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv_JUN19< dateadd(dd,-30,Evaluation_Date_JUN19)) OR 
(Max_dataproximaconsult_JUN19 < dateadd(dd, -30, Evaluation_Date_JUN19)))

Go

