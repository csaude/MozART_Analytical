--*********

/******************* THIS code has been changed to only calculate the enrolled not elegible **************/
WITH eleg1 as
(
SELECT
hf.Provincia
,hf.Distrito
,hf.HdD
,hf.designacao
,pa.AccessFilePath
,pa.nid
,(datediff(yy, cast(pa.datanasc AS DATE), '2019-09-21')) AS idades						--age in October
,cast(pa.datanasc AS DATE) dob
,pa.sexo
----,(datediff(mm, cast(pa.datainiciotarv AS DATE), '2019-03-21')) AS timeinART				--How long in ART by OCTOBER 2017
----,(datediff(dd, cast(pa.datadiagnostico AS DATE),cast(pa.datainiciotarv AS DATE))) AS timetoSTART
,cast(pa.datainiciotarv AS DATE) AS datainicio_entered
,pa.codestado AS estadopaciente

	,b4OCTVLDate
	,ri.resultado AS b4OCTVL
	
,firstpickupever
,DatestartGAAC
,DatexistGAAC

FROM t_paciente pa
LEFT JOIN
t_hdd hf
ON pa.hdd = hf.HdD AND pa.AccessFilePath = hf.AccessFilePath

INNER JOIN	/*patient needs to have a suppressed Viral load result before October 2019*/
       (
              SELECT re1.nid, re1.codexame, AccessFilePath, resultado, cast(dataresultado AS DATE) AS b4OCTVLDate
              FROM t_resultadoslaboratorio re1
              INNER JOIN   
			(
                      SELECT nid, codexame, max(cast(dataresultado AS DATE)) AS Mindate
                      FROM t_resultadoslaboratorio
                      Where codexame='Carga Viral' AND cast(dataresultado AS DATE) < '2019-09-21' AND resultado<10000000  /*date is not october***review*/
                      GROUP BY nid, codexame
              ) res1
              ON re1.nid = res1.nid AND re1.dataresultado = res1.Mindate AND re1.codexame = res1.codexame
      ) ri
ON pa.nid = ri.nid AND pa.AccessFilePath = ri.AccessFilePath

LEFT JOIN
	(
		SELECT  fp.nid,fp.AccessFilePath, firstpickupever
		FROM
			(
				SELECT ROW_NUMBER() OVER (PARTITION BY nid, AccessFilePath ORDER BY cast(datatarv AS DATE) ASC) AS Nrpick, 
				nid, AccessFilepath, cast(datatarv AS DATE) AS firstpickupever
				FROM 
				t_tarv
				WHERE cast(datatarv AS DATE)<'2019-09-21'
			) fp
		WHERE 
		Nrpick=1
	) fpev
	ON pa.nid=fpev.nid AND pa.AccessFilePath=fpev.AccessFilePath


LEFT JOIN  /*choosing only dates for people who didn't leave or left after October 1---Cut these people out in other sofware*/
		(
				SELECT nid, AccessFilePath, cast(dataInscricao AS DATE) AS DatestartGAAC, cast(dataSaida AS DATE) AS DatexistGAAC
				FROM t_gaac_actividades 
				WHERE dataSaida is null or cast(dataSaida AS DATE)>='2019-09-21' /*left after evaluation (2019-03-21) so they were still in GACC*/
				GROUP BY nid, dataInscricao, dataSaida,AccessFilePath
		) gac
	 ON pa.nid=gac.nid AND pa.AccessFilePath=gac.AccessFilePath
	 
WHERE	(datediff(yy, cast(pa.datanasc AS DATE), '2019-09-21'))>=9
),

		/*COULD include the active patients using TX_CURR query to determine wheter patient was active or not*/


/*********============================================================================

/*Criterios de elegibilidade*/
-- 1. At least 6 months on ART: October 1 - data inicio> 6months
-- 2. Had a viral load test before October and most recent VL test, within 1 year before October 2017 was suppressed. 	
-- 3. Older than 9 years: October - Data Nascimento> 9 year ****we are using 9 years becouse from 2 year to 6 they need caretaker criteria.
-- 4. Se proveniencia for CCR (adulto) or PTV deve ser sido diagnosticado pelo menos 1 ano antes.
-- 5. Excluir pacientes que estavam em GAACs and dataSaida in t_gaac_activities is null.

=====================================================================****************/

eleg2 AS
(
SELECT *,
Case when firstpickupever>datainicio_entered or firstpickupever is null then datainicio_entered
	 when firstpickupever<datainicio_entered or datainicio_entered is null then firstpickupever
	 when firstpickupever=datainicio_entered then datainicio_entered
end as [datainicio_revised]

FROM eleg1 

)


SELECT
Provincia
,Distrito
,HdD
,designacao
,AccessFilePath
,nid
,idades					
,sexo
,[datainicio_revised]
,b4OCTVLDate
,b4OCTVL

,firstpickupever
,DatestartGAAC
,DatexistGAAC
,Elegible3MDD=(
				CASE WHEN ((DatestartGAAC is null) 
				OR (DatestartGAAC is not null AND DatexistGAAC<'2019-09-21')) AND b4OCTVL<1000
				THEN 'Elegible' ELSE ' Not Elegible'
				END)
INTO Sandbox.dbo.DSD_eleg_final_covid19
FROM eleg2
Where (datediff(mm, cast([datainicio_revised] AS DATE), '2019-09-21'))>=6

go
---

Select Provincia,
Distrito, tx.HdD,
designacao
nid, Active_patient, age=datediff(yy,cast(tx.datanasc as date),'2019-09-21') , tx.sexo,
el.Elegible3MDD

INTO Sandbox.dbo.DSD_eleg_TXCURR_final_covid19
from [Sandbox].[dbo].[TX_CURR_Covid19_step3Q42019] tx
LEFT JOIN 
(
Select nid, AccessFilePath, HdD, Elegible3MDD
from [Sandbox].[dbo].[DSD_eleg_final_covid19]
) el
on tx.nid=el.nid and tx.HdD=el.HdD


SELECT [Provincia]
      ,[Distrito]
      ,count([nid]) #elegible
  FROM [Sandbox].[dbo].[DSD_eleg_TXCURR_final_covid19]
  Where [Active_patient]='Active' AND [Elegible3MDD]='Elegible'
  Group by [Provincia]
      ,[Distrito]