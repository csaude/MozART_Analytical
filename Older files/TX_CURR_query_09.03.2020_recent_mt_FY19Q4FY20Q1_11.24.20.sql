---- =========================================================================================================
---- WORKING SQL QUERY FOR Artifactual high LTFU Analysis (Active_originaldates (AJUDA) DATASET PRODUCTION)
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: Mala (CDC/GDIT) and Timoteo (CDC-MOZ) based on original by Randy (CDC/GDIT)
---- REV DATE: 6/AUG/2019 - 9/SEPT/2020 Marcela Torres  - 24/NOV/2020 Marcela Torres
---- Pickup: Maxes on datatarv and dataseguimento before Status_originaldates date on filtered subset USING ROWNUMBERS
---- =========================================================================================================

--******************CHANGES.....08.29.2019.....**************************
----need to change 'Status_originaldates date' to 'status evaluation date'
--need to define status evaluation date ( can we define 6 different ones?) 
---		ADD that patient need to be enrolled in program (dataabertura in t_patiente is not null) (done)
---		exclude patients who do not have Max_dataproxima
----	Don't need the condition of being active if in future because it is already included (done)
			/*-- For transfer outs ensure that if saida is after MAX_TARV (actual pick up) and after MAX_Seguimento (actual consultation) 
			--	but before evaluation date patients are considered not active (done)*/

--******************CHANGES.....09.09.2019.....  **************************
----exclude people who are not in the program. They are not LTFU. So don't calculate Active_originaldates Active or not for them.

--******************CHANGES.....09.02.2020....Marcela Torres**************************
----Added calculation for current age and agebands
---- Used MozART_q1_2020_Clean to compare FY19Q4 and FY20Q1 Evaluation_Date = '2019-12-21' and FY19Q4 Evaluation_Date = '2019-09-21')

--******************CHANGES.....11.24.2020....Marcela Torres**************************
--- Change -30 days in active status calculation to -28 to align with TX_CURR definition 



-----TX_CURR_FY19Q4

WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	,person.datadiagnostico,  
	tt.Max_datatarv, ss.Max_dataseguimento,
	first_datatarv, first_dataproxima_tarv, person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date, tt.Max_dataproxima_tarv, DayswithARV, ss.Max_dataproximaconsult
	,datatarv_second, proximatarv_second, Second_DayswithARV
	 ,dataseguimento_second, proximaconsult_second /*, person.Gravidez*/

	 ,CASE	WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)<=cast([first_datatarv] AS DATE) THEN cast([datainiciotarv] AS DATE)
		WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)>cast([first_datatarv] AS DATE) THEN cast([first_datatarv] AS DATE)
		WHEN [first_datatarv] is null and [datainiciotarv] is not null THEN cast([datainiciotarv] AS DATE)
		WHEN [first_datatarv] is not null and [datainiciotarv] is null THEN cast([first_datatarv] AS DATE)
		END AS revised_datainiciotarv,
		CurrentAge=(datediff(mm,datanasc,'2019-09-21')/12.0)
	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	
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

	-- Joining subset of filtered dates from t_tarv below @RetentionType Status_originaldates date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as Max_datatarv, ntv.dataproxima as Max_dataproxima_tarv, ntv.dias as DayswithARV
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date, dias
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-09-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

	----------------------------JOING the first pick-up
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) asc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as first_datatarv, ntv.dataproxima as first_dataproxima_tarv
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-09-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '1') t1
	ON person.nid = t1.nid AND person.AccessFilePath = t1.AccessFilePath
	---------------------------------------------------


	-- Joining subset of filtered dates from t_seguimento below @RetentionType Status_originaldates date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY cast(nts.dataseguimento as date) desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento, nts.dataproximaconsulta as Max_dataproximaconsult
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-09-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

-- Second to last tarv pick up joined
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as datatarv_second, ntv.dataproxima as proximatarv_second, ntv.dias as Second_DayswithARV
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date, dias
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-09-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '2') t2
	ON person.nid = t2.nid AND person.AccessFilePath = t2.AccessFilePath


		-- Second to last consultation pick up joined
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY cast(nts.dataseguimento as date) desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as dataseguimento_second, nts.dataproximaconsulta as proximaconsult_second
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-09-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date
		) nts
	) s
	WHERE s.rownum = '2') s2
	ON person.nid = s2.nid AND person.AccessFilePath = s2.AccessFilePath
),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating Active_originaldates (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/


CTE1 AS   
( 
	SELECT *
	, YEAR(revised_datainiciotarv) as Year_Inicio
	 , CASE WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)<1 THEN 'LT_1_Year_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>=1 AND datediff(yy,revised_datainiciotarv,Evaluation_Date)<3 THEN '1_3_Years_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>=3 AND datediff(yy,revised_datainiciotarv,Evaluation_Date)<5 THEN '3_5_Years_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>5 THEN 'GT_5_Years_ART'
			END AS time_ART_categ
	,
	CASE WHEN 
	dataabertura IS NOT NULL AND
	---(Max_dataproxima_tarv IS NOT NULL AND Max_dataproximaconsult IS NOT NULL) AND
(
	(     /*case 1 no exit, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) <Evaluation_Date) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date)) OR 
						(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date))
				)
				 
	)
		
							OR
	
	(	/*case 2 exit after evaluation, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) <Evaluation_Date) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date) AND
			
				(	(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date)) OR 
					(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date)) 
				)
					
			)
	)

	
							OR 
	(	/*case 3 exit before evaluation but before one of the dates, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) < Evaluation_Date) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date) AND 

					((datasaidatarv<Max_datatarv)	OR   /*IF exit is before either tarv or consult then compare dates*/
					 (datasaidatarv<Max_dataseguimento))		AND
					
						(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date))		OR 
						(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date))
			
		)
)
)
	THEN 'Active'
	Else 'Not Active'
	END AS [TX_CURR_FY19]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_FY19 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Abandon'
	WHEN TX_CURR_FY19 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) AND datasaidatarv <= Evaluation_Date THEN 'ART Suspend'
	WHEN TX_CURR_FY19 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Transferred Out'
	WHEN TX_CURR_FY19 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Dead'
	WHEN TX_CURR_FY19 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_FY19 = 'Not Active' AND  (datasaidatarv<Max_datatarv) OR (datasaidatarv<Max_dataseguimento) THEN 'LTFU'
	WHEN TX_CURR_FY19 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_FY19],
		AgeBand= CASE WHEN CurrentAge>= 0 AND CurrentAge < 1 Then '0-11 mths' 
	         WHEN CurrentAge>= 1 AND CurrentAge < 5 Then '1-4'
			 WHEN CurrentAge>= 5 AND CurrentAge < 10 Then '5-9'
			 WHEN CurrentAge>= 10 AND CurrentAge < 15 Then '10-14'
			 WHEN CurrentAge>= 15 AND CurrentAge < 20 Then '15-19'
			 WHEN CurrentAge>= 20 AND CurrentAge < 25 Then '20-24'
			 WHEN CurrentAge>= 25 AND CurrentAge < 30 Then '25-29'
			 WHEN CurrentAge>= 30 AND CurrentAge < 35 Then '30-34'
			 WHEN CurrentAge>= 35 AND CurrentAge < 40 Then '35-39'
			 WHEN CurrentAge>= 40 Then '40+'
			 ELSE NULL
	END
	FROM CTE1)


/******just insert new Active_originaldates based on status******/

-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_FY19Q4_A
FROM CTE2
WHERE datainiciotarv >= '2012-01-01'
/*ORDER BY nid, Outcome_FY20  desc*/


UPDATE Sandbox.dbo.TX_CURR_FY19Q4_A
SET Evaluation_Date='2019-09-21'
Where Evaluation_Date is null

UPDATE Sandbox.dbo.TX_CURR_FY19Q4_A
SET Outcome_FY19='LTFU' WHERE Outcome_FY19 is null AND datasaidatarv > Evaluation_Date AND 
((Max_dataproxima_tarv < dateadd(dd,-28,Evaluation_Date)) OR 
(Max_dataproximaconsult < dateadd(dd, -28, Evaluation_Date)))


Update Sandbox.dbo.TX_CURR_FY19Q4_A			/*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_FY19='LTFU' WHERE Outcome_FY19 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv < dateadd(dd,-28,Evaluation_Date)) OR 
(Max_dataproximaconsult < dateadd(dd, -28, Evaluation_Date)))


Update Sandbox.dbo.TX_CURR_FY19Q4_A
SET Outcome_FY19='LTFU' WHERE Outcome_FY19 is null AND TX_CURR_FY19 ='Not Active' AND codestado='ABANDONO' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY19Q4_A
SET Outcome_FY19='LTFU' WHERE Outcome_FY19 is null AND TX_CURR_FY19 ='Not Active' AND codestado ='SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY19Q4_A
SET Outcome_FY19='Transferred Out' WHERE Outcome_FY19 is null AND TX_CURR_FY19 ='Not Active' AND codestado ='TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY19Q4_A
SET Outcome_FY19='Dead' WHERE Outcome_FY19 is null AND TX_CURR_FY19 ='Not Active' AND codestado ='OBITOU' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)


SELECT *,
CASE WHEN Max_datatarv>Max_dataseguimento
	THEN DATEDIFF(dd,Evaluation_Date,Max_datatarv)
	ELSE DATEDIFF(dd,Evaluation_Date,Max_dataseguimento)
END AS [days_complete],

CASE WHEN Max_dataproxima_tarv>Max_dataproximaconsult
	THEN DATEDIFF(dd,Evaluation_Date,Max_dataproxima_tarv)
	ELSE DATEDIFF(dd,Evaluation_Date,Max_dataproximaconsult)
END AS [days_schedul]

FROM Sandbox.dbo.TX_CURR_FY19Q4_A

Go


----------TX_CURR_FY20Q1

WITH CTE0 AS
(
	SELECT DISTINCT 
	facility.HdD, facility.Provincia, facility.Distrito, facility.designacao,
	person.nid, person.sexo, person.datanasc, person.idade as idadeiniciotarv, person.datainiciotarv
	,person.datadiagnostico,  
	tt.Max_datatarv, ss.Max_dataseguimento,
	first_datatarv, first_dataproxima_tarv, person.dataabertura
	,person.codestado, person.datasaidatarv, tt.Evaluation_Date, tt.Max_dataproxima_tarv, DayswithARV, ss.Max_dataproximaconsult
	,datatarv_second, proximatarv_second, Second_DayswithARV
	 ,dataseguimento_second, proximaconsult_second /*, person.Gravidez*/
     ,CurrentAge=(datediff(mm,datanasc,'2019-12-21')/12.0)
	 ,CASE	WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)<=cast([first_datatarv] AS DATE) THEN cast([datainiciotarv] AS DATE)
		WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)>cast([first_datatarv] AS DATE) THEN cast([first_datatarv] AS DATE)
		WHEN [first_datatarv] is null and [datainiciotarv] is not null THEN cast([datainiciotarv] AS DATE)
		WHEN [first_datatarv] is not null and [datainiciotarv] is null THEN cast([first_datatarv] AS DATE)
		END AS revised_datainiciotarv

	FROM
	(SELECT nid, sexo, cast(datanasc as date) as datanasc, cast(dataabertura as date) as dataabertura, idade, hdd, codproveniencia, cast(datainiciotarv as date) as datainiciotarv
	, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
	
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

	-- Joining subset of filtered dates from t_tarv below @RetentionType Status_originaldates date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as Max_datatarv, ntv.dataproxima as Max_dataproxima_tarv, ntv.dias as DayswithARV
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date, dias
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-12-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '1') tt
	ON person.nid = tt.nid AND person.AccessFilePath = tt.AccessFilePath

		--------------------------------------------
	-------JOING the first pick-up
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) asc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as first_datatarv, ntv.dataproxima as first_dataproxima_tarv
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-12-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '1') t1
	ON person.nid = t1.nid AND person.AccessFilePath = t1.AccessFilePath
	---------------------------------------------------

	-- Joining subset of filtered dates from t_seguimento below @RetentionType Status_originaldates date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY cast(nts.dataseguimento as date) desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as Max_dataseguimento, nts.dataproximaconsulta as Max_dataproximaconsult
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-12-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date
		) nts
	) s
	WHERE s.rownum = '1') ss
	ON person.nid = ss.nid AND person.AccessFilePath = ss.AccessFilePath

-- Second to last tarv pick up joined
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as datatarv_second, ntv.dataproxima as proximatarv_second, ntv.dias as Second_DayswithARV
	FROM
		(
		SELECT tv.nid, tv.AccessFilePath, cast(datatarv as date) as datatarv, cast(dataproxima as date) as dataproxima, tpo.Evaluation_Date, dias
		FROM t_tarv tv
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-12-21', AccessFilePath
		FROM t_paciente) tpo
		ON tv.nid = tpo.nid AND tv.AccessFilePath = tpo.AccessFilePath
		WHERE cast(datatarv AS date) <= Evaluation_Date
		) ntv
	) t
	WHERE t.rownum = '2') t2
	ON person.nid = t2.nid AND person.AccessFilePath = t2.AccessFilePath


		-- Second to last consultation pick up joined
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY cast(nts.dataseguimento as date) desc) as rownum, nts.nid, nts.AccessFilePath
	, nts.dataseguimento as dataseguimento_second, nts.dataproximaconsulta as proximaconsult_second
	FROM 
		(
		SELECT ts.nid, Gravidez, ts.AccessFilePath, cast(dataseguimento as date) as dataseguimento, cast(dataproximaconsulta as date) as dataproximaconsulta
		, tpo1.Evaluation_Date
		FROM t_seguimento  ts
		LEFT JOIN
		(SELECT nid, Evaluation_Date = '2019-12-21', AccessFilePath
		FROM t_paciente) tpo1
		ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
		WHERE cast(dataseguimento AS date) <= Evaluation_Date
		) nts
	) s
	WHERE s.rownum = '2') s2
	ON person.nid = s2.nid AND person.AccessFilePath = s2.AccessFilePath
),

/*
===================================== Calculations for active patients ============================
====General conditions====
1. Patients must be enrolled.
2. Patients has to have next pick date (maybe consultation as well???)
3. Patients have started ART before the date when we are evaluating Active_originaldates (end of period or any other date chosen)
======Calculations============
1. There is no data de saida--> Compare the dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
2. Data de saida is after Evaluation--> Compare dates to confirm patient has not left (activity within 60 days/has not missed more than 30 days of visit of pick up).
3. Data saida is before Evaluation but there was activity after saida --> Compare dates to confirm activity registered was within 60 days of Evaluation.
4. All others are not active including all who left before Evaluation and have not registered actual activity after data saida.

*/


CTE1 AS   
( 
	SELECT *
	, YEAR(revised_datainiciotarv) as Year_Inicio
	 , CASE WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)<1 THEN 'LT_1_Year_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>=1 AND datediff(yy,revised_datainiciotarv,Evaluation_Date)<3 THEN '1_3_Years_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>=3 AND datediff(yy,revised_datainiciotarv,Evaluation_Date)<5 THEN '3_5_Years_ART'
			WHEN datediff(yy,revised_datainiciotarv,Evaluation_Date)>5 THEN 'GT_5_Years_ART'
			END AS time_ART_categ
	, 
	CASE WHEN 
	dataabertura IS NOT NULL AND
	---(Max_dataproxima_tarv IS NOT NULL AND Max_dataproximaconsult IS NOT NULL) AND
(
	(     /*case 1 no exit, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) <Evaluation_Date) AND
	
				((datasaidatarv IS NULL) AND
							
						(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date)) OR 
						(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date))
				)
				 
	)
		
	
							OR
	
	(	/*case 2 exit after evaluation, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) <Evaluation_Date) AND

			((datasaidatarv IS NOT NULL) AND
			(datasaidatarv > Evaluation_Date) AND
			
				(	(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date)) OR 
					(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date)) 
				)
					
			)
	)

	
							OR 
	(	/*case 3 exit before evaluation but before one of the dates, just compare dates*/
		(cast(revised_datainiciotarv AS DATE) < Evaluation_Date) AND

		((datasaidatarv IS NOT NULL) AND
			
					(datasaidatarv<=Evaluation_Date) AND 

					((datasaidatarv<Max_datatarv)	OR   /*IF exit is before either tarv or consult then compare dates*/
					 (datasaidatarv<Max_dataseguimento))		AND
					
						(Max_dataproxima_tarv >= dateadd(dd,-28,Evaluation_Date))		OR 
						(Max_dataproximaconsult >= dateadd(dd, -28, Evaluation_Date))
			
		)
)
)
	THEN 'Active'

	Else 'Not Active'
	END AS [TX_CURR_FY20]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN TX_CURR_FY20 = 'Not Active' AND codestado = 'ABANDONO' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Abandon'
	WHEN TX_CURR_FY20 = 'Not Active' AND codestado = 'SUSPENDER TRATAMENTO' AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) AND datasaidatarv <= Evaluation_Date THEN 'ART Suspend'
	WHEN TX_CURR_FY20 = 'Not Active' AND codestado = 'TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Transferred Out'
	WHEN TX_CURR_FY20 = 'Not Active' AND codestado = 'OBITOU' AND datasaidatarv <= Evaluation_Date AND  (datasaidatarv>=Max_datatarv) AND  (datasaidatarv>=Max_dataseguimento) THEN 'Dead'
	WHEN TX_CURR_FY20 = 'Not Active' AND codestado IS NULL THEN 'LTFU'
	WHEN TX_CURR_FY20 = 'Not Active' AND  (datasaidatarv<Max_datatarv) OR  (datasaidatarv<Max_dataseguimento) THEN 'LTFU'
	WHEN TX_CURR_FY20 = 'Active' Then 'Active'
	ELSE NULL
	END AS [Outcome_FY20],
	AgeBand= CASE WHEN CurrentAge>= 0 AND CurrentAge < 1 Then '0-11 mths' 
	         WHEN CurrentAge>= 1 AND CurrentAge < 5 Then '1-4'
			 WHEN CurrentAge>= 5 AND CurrentAge < 10 Then '5-9'
			 WHEN CurrentAge>= 10 AND CurrentAge < 15 Then '10-14'
			 WHEN CurrentAge>= 15 AND CurrentAge < 20 Then '15-19'
			 WHEN CurrentAge>= 20 AND CurrentAge < 25 Then '20-24'
			 WHEN CurrentAge>= 25 AND CurrentAge < 30 Then '25-29'
			 WHEN CurrentAge>= 30 AND CurrentAge < 35 Then '30-34'
			 WHEN CurrentAge>= 35 AND CurrentAge < 40 Then '35-39'
			 WHEN CurrentAge>= 40 Then '40+'
			 ELSE NULL
	END

	FROM CTE1)



---test 2,513,536
--SELECT COUNT (DISTINCT nid)
--FROM CTE0
--GROUP BY nid

/******just insert new Active_originaldates based on status******/
-----rename table
SELECT *
INTO Sandbox.dbo.TX_CURR_FY20Q1_B
FROM CTE2
WHERE datainiciotarv >= '2012-01-01'
/*ORDER BY nid, Outcome_FY19  desc*/



UPDATE Sandbox.dbo.TX_CURR_FY20Q1_B
SET Evaluation_Date='2019-12-21'
Where Evaluation_Date is null

UPDATE Sandbox.dbo.TX_CURR_FY20Q1_B
SET Outcome_FY20='LTFU' WHERE Outcome_FY20 is null AND datasaidatarv > Evaluation_Date AND 
((Max_dataproxima_tarv < dateadd(dd,-28,Evaluation_Date)) OR 
(Max_dataproximaconsult < dateadd(dd, -28, Evaluation_Date)))


Update Sandbox.dbo.TX_CURR_FY20Q1_B	/*****check how JEMBI handles cases without datasaida tarv****/
SET Outcome_FY20='LTFU' WHERE Outcome_FY20 is null AND datasaidatarv is NULL AND 
((Max_dataproxima_tarv < dateadd(dd,-28,Evaluation_Date)) OR 
(Max_dataproximaconsult < dateadd(dd, -28, Evaluation_Date)))


Update Sandbox.dbo.TX_CURR_FY20Q1_B
SET Outcome_FY20='Abandon' WHERE Outcome_FY20 is null AND TX_CURR_FY20 ='Not Active' AND codestado='ABANDONO' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY20Q1_B
SET Outcome_FY20='ART Suspend' WHERE Outcome_FY20 is null AND TX_CURR_FY20 ='Not Active' AND codestado ='SUSPENDER TRATAMENTO' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY20Q1_B
SET Outcome_FY20='Transferred Out' WHERE Outcome_FY20 is null AND TX_CURR_FY20 ='Not Active' AND codestado ='TRANSFERIDO PARA' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)

Update Sandbox.dbo.TX_CURR_FY20Q1_B
SET Outcome_FY20='Dead' WHERE Outcome_FY20 is null AND TX_CURR_FY20 ='Not Active' AND codestado ='OBITOU' AND datasaidatarv <= Evaluation_Date AND (Max_datatarv<Evaluation_Date OR Max_dataseguimento<Evaluation_Date)


SELECT *,
CASE WHEN Max_datatarv>Max_dataseguimento
	THEN DATEDIFF(dd,Evaluation_Date,Max_datatarv)
	ELSE DATEDIFF(dd,Evaluation_Date,Max_dataseguimento)
END AS [days_complete],

CASE WHEN Max_dataproxima_tarv>Max_dataproximaconsult
	THEN DATEDIFF(dd,Evaluation_Date,Max_dataproxima_tarv)
	ELSE DATEDIFF(dd,Evaluation_Date,Max_dataproximaconsult)
END AS [days_schedul]

FROM Sandbox.dbo.TX_CURR_FY20Q1_B

Go
