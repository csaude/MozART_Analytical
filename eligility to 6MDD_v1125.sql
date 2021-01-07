With CT0 as
(

SELECT
hf.Provincia
,hf.Distrito
,hf.HdD
,hf.designacao
,pa.AccessFilePath
,pa.nid
,(datediff(yy, cast(pa.datanasc AS DATE), '2019-12-21')) AS idade						--age  ----Where datediff(mm,'2019-12-21',cast([datainiciotarv] as date)) >=12
,pa.sexo
,(datediff(mm, cast(pa.datainiciotarv AS DATE), '2019-12-21')) AS timeinART				--How long in ART  /*patients started >12months*/
,cast(pa.datainiciotarv AS DATE) AS datainicio
,pa.codestado AS estadopaciente

,lastVLDate
,lastVL
,lastcd4date
,lastcd4
,secondlastcd4date 
,secondlastcd4
,Pregnant
,Bfeeding
,DatestartGAAC
,DatexistGAAC
,first_datatarv
,last_datatarv
,last_dataproxima_tarv
,lastDayswithARV

,isoniazid
,aderencia
,estadiooms_final
,suppression
,lastcd4_ab
,secondlastcd4_ab
,pregbf
,gaac
/*********============================================================================
Criterios de elegibilidade
	--Patient age >14 (done)
	--Time on ART >12 months (done)
	--last VL <1000 absolute value | last two CD4 taken within 6 months & >350 Cel/ml (done)
	-- Not in WHO level III (done but could also use  table [t_adulto] where [hipotesedediagnostico] like 'OMS III% |OMS IV%')
	-- Not in WHO level IV (done but could also use  table [t_adulto] where [hipotesedediagnostico] like 'OMS III% |OMS IV%')
	-- Not pregnant or lactating (done)
	-- No adverse reaction (this means No change in ART regimen? not really because they can change for other reasons) (not sure how to get this)
	-- Not in GAAC (done)
	-- Not currently on Isoniazid (done)
	-- Good adherence to consultations and pick up in the last 6 months (done-needs to exclude dates>6months)
=====================================================================****************/

---INTO Sandbox.dbo.sixMDD_step1
FROM 
t_paciente pa
  
LEFT JOIN
t_hdd hf
ON pa.hdd = hf.HdD AND pa.AccessFilePath = hf.AccessFilePath

LEFT JOIN
(
SELECT	 [nid]   /*last date of isoniazid was more than 6 months ago*/
		,[AccessFilePath]
		,[codtratamento]
		, case when [codtratamento] like 'ISONIAZ%' and cast([data] as date)>='2019-06-21' then 'on isoniazid'
		  else 'not on isoniazid' 
		  end as isoniazid 
		  
  FROM [MozART_q1_2020].[dbo].[t_tratamentoseguimento]
 
  ) iso
  on pa.nid=iso.nid and pa.AccessFilePath=iso.AccessFilePath
 
 LEFT JOIN
 (
 Select  ad2.nid, 
		case when aderenciacode2<6 then'nao aderiu'		---nao aderiu a todas consultas, soma <6
		when aderenciacode2=6 then 'aderiu'				---aderiu a todas consultas, soma =6 (6x1)
		end as aderencia 
		, ad2.AccessFilePath
		
FROM
(
 SELECT ad1.nid, aderenciacode2=sum(ad1.aderenciacode1), ad1.AccessFilePath
 FROM
 (

 Select *, datediff(dd,t.previousdataproxima,t.datatarv) as daysmissed
		, case when datediff(dd,t.previousdataproxima,t.datatarv)>5 then 0 ---Mudei de 0 dias para 5 dias***(Nao aderiu) Positivo sao dias apos a marcacao. veio x dias depois
		when datediff(dd,t.previousdataproxima,t.datatarv)<=5 then 1       ---Mudei de 0 dias para 5 dias***(Aderiu) Negativo ou 0 veio -x dias antes ou no dia da marcacao
	   end as aderenciacode1
from (
SELECT [idtarv], [nid]    
      ,datatarv
      ,dataproxima
	  ,LAG( cast([dataproxima] as date), 1, Null) 
	  OVER (PARTITION BY  [nid], [AccessFilePath] 
	  ORDER BY cast([datatarv] as date), cast([dataproxima] as date) ) AS Previousdataproxima
	  ,Nrpick
	  ,[AccessFilePath]
  FROM (
  		SELECT fp.[idtarv], fp.nid,fp.AccessFilePath, fp.[datatarv], fp.[dataproxima], Nrpick
		FROM
			(
				SELECT ROW_NUMBER() OVER (PARTITION BY nid, AccessFilePath ORDER BY cast(datatarv AS DATE) DESC) AS Nrpick, 
				nid, [AccessFilePath], cast(datatarv AS DATE) AS [datatarv], cast(dataproxima AS DATE) as [dataproxima], [idtarv]
				FROM 
				[MozART_q1_2020].[dbo].[t_tarv]
				
			) fp
		WHERE 
		Nrpick>=1 and Nrpick<=7 ----and cast([datatarv] as date) between '2020-04-01' and '2019-12-21' ---and nid='000000000703313372'
	) fp1
 ) t
WHERE Nrpick<7

)ad1
group by ad1.nid, ad1.AccessFilePath
)ad2
) ad3
on pa.nid=ad3.nid and pa.AccessFilePath=ad3.AccessFilePath
  
  
LEFT JOIN
(				
SELECT [Nid] as nid
      ,[AccessFilePath]	/*patient is not on OMS estadio II or IV*/
      ,[estadiooms]
	  ,case when [estadiooms] like 'III%' or [estadiooms] like 'IV%' then 'OMS III/IV'
	  else 'not III/IV'
	  end as estadiooms_final
	  
FROM [MozART_q1_2020].[dbo].[t_infeccoesoportunisticaseguimento]
  ) oms
on pa.nid=oms.nid and pa.AccessFilePath=oms.AccessFilePath


LEFT JOIN	/*last VL of the patient was suppressed ***September 2020*/
       (
              SELECT re1.nid, re1.codexame, AccessFilePath, resultado as lastVL, cast(dataresultado AS DATE) AS lastVLDate
			  ,case when resultado<=1000 then 'suppressed'
			   when resultado>1000 then 'not suppressed'
			   end as suppression   
              FROM t_resultadoslaboratorio re1
              INNER JOIN   
			(
                      SELECT nid, codexame, max(cast(dataresultado AS DATE)) AS Mindate
                      FROM t_resultadoslaboratorio
                      Where codexame='Carga Viral' AND cast(dataresultado AS DATE) < '2019-12-21'
                      GROUP BY nid, codexame
              ) res1
              ON re1.nid = res1.nid AND re1.dataresultado = res1.Mindate AND re1.codexame = res1.codexame
      ) ri
ON pa.nid = ri.nid AND pa.AccessFilePath = ri.AccessFilePath


LEFT JOIN /*last CD4>350  of the patient was suppressed ***September 2020*/
       (
  		SELECT  nid,AccessFilePath, lastcd4date, lastcd4
		,case when lastcd4>=350 then 'above 350'
		 when lastcd4<350 then 'below 350'
		end as lastcd4_ab 
		FROM
			(
				SELECT ROW_NUMBER() OVER (PARTITION BY nid, AccessFilePath ORDER BY cast(dataresultado as DATE) DESC) AS Nrpick, 
				nid, AccessFilepath, cast(dataresultado AS DATE) AS lastcd4date, [resultado] as lastcd4
				FROM 
				t_resultadoslaboratorio
				WHERE cast(dataresultado as DATE)<'2019-12-21' and codexame='CD4' and codparametro!='ABSOLUTO'
			) sp
		WHERE Nrpick=1
			  
       ) cd 
ON pa.nid = cd.nid AND pa.AccessFilePath = cd.AccessFilePath

LEFT JOIN  /*secondlast CD4>350  of the patient was suppressed ***September 2020 */
	(
  		SELECT  nid,AccessFilePath, secondlastcd4date, secondlastcd4
		,case when secondlastcd4>=350 then 'above 350'
		 when secondlastcd4<350 then 'below 350'
		end as secondlastcd4_ab 
		FROM
			(
				SELECT ROW_NUMBER() OVER (PARTITION BY nid, AccessFilePath ORDER BY cast(dataresultado as DATE) DESC) AS Nrpick, 
				nid, AccessFilepath, cast(dataresultado AS DATE) AS secondlastcd4date, [resultado] as secondlastcd4
				FROM 
				t_resultadoslaboratorio
				WHERE cast(dataresultado as DATE)<'2019-12-21' and codexame='CD4' and codparametro!='ABSOLUTO'
			) sp
		WHERE Nrpick=2
	) sp1
	ON pa.nid=sp1.nid AND pa.AccessFilePath=sp1.AccessFilePath


LEFT JOIN   /*patient is not pregnant or BF*/
	(
		SELECT nid, gravida AS Pregnant, tipoaleitamento AS Bfeeding, AccessFilePath
		,case when gravida=1 OR tipoaleitamento like 'M%'  then 'preg/BF' 
		 else 'not preg/bf' 
		 end as pregbf      ----/*have to verify quality of pregnancy variable*/
		FROM t_adulto  
		GROUP BY nid, AccessFilePath, gravida, tipoaleitamento
	) grav
	 ON pa.nid=grav.nid AND pa.AccessFilePath=grav.AccessFilePath
	 

LEFT JOIN  /*Elegible have never started or started and left gaac*/
		(
				SELECT nid, AccessFilePath, cast(dataInscricao AS DATE) AS DatestartGAAC, cast(dataSaida AS DATE) AS DatexistGAAC
				,case when dataSaida is null or cast(dataSaida AS DATE)<='2019-12-21' then 'gaac'
				else 'not on gaac' 
				end as gaac   
				FROM t_gaac_actividades 
				GROUP BY nid, dataInscricao, dataSaida,AccessFilePath
		) gac
	 ON pa.nid=gac.nid AND pa.AccessFilePath=gac.AccessFilePath


-------JOING the first pick-up :not in criteria
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
	ON pa.nid = t1.nid AND pa.AccessFilePath = t1.AccessFilePath

	-- Joining subset of filtered dates from t_tarv below @RetentionType Status_originaldates date
	LEFT JOIN
	(SELECT * FROM(
	SELECT ROW_NUMBER() OVER (PARTITION BY ntv.nid, ntv.AccessFilePath ORDER BY cast(ntv.datatarv as date) desc) as rownum, ntv.nid, ntv.AccessFilePath, ntv.Evaluation_Date
	, ntv.datatarv as last_datatarv, ntv.dataproxima as last_dataproxima_tarv, ntv.dias as lastDayswithARV
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
	WHERE t.rownum = '1') tf
	ON pa.nid = tf.nid AND pa.AccessFilePath = tf.AccessFilePath

)
    	--- patient active:	pa.codestado IS NULL
		--- patient active: AND (pa.datasaidatarv IS NULL OR pa.datasaidatarv>='2019-12-21') 
		---initiation condition: (datediff(mm, cast(pa.datainiciotarv AS DATE), '2019-12-21'))>=12
		---age condition: AND (datediff(yy, cast(pa.datanasc AS DATE), '2019-12-21'))>=15
/*COULD include the active patients using TX_CURR query to determine wheter patient was active or not*/

select distinct *, 
/*case 1*/
case when	idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and suppression='suppressed' 
then 'eligible'
/*case 2*/
when		idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and lastcd4_ab='above 350' and secondlastcd4_ab='above 350'
then 'eligible'
else 'not elegible' 
end as sixmddelig,
/*second version of the variable elegible*/
case when	idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and suppression='suppressed' 
then 'eligible'
/*case 2*/
when		idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and suppression is null and (lastcd4_ab='above 350' or secondlastcd4_ab='above 350')
then 'eligible'
else 'not elegible' 
end as sixmddeligv2
into Sandbox.dbo.elegibility_sixMDDstep1
from CT0
where first_datatarv is not null


select elg.Provincia
,elg.Distrito
,elg.HdD
,elg.designacao
,elg.AccessFilePath
,elg.nid
,elg.idade						
,elg.sexo
,elg.timeinART				
,elg.datainicio
,elg.first_datatarv
,last_datatarv
,isoniazid
,aderencia
,estadiooms_final
,suppression
,lastcd4_ab
,secondlastcd4_ab
,pregbf
,gaac
,sixmddelig
,sixmddeligv2
,Active_originaldates
,Status_originaldates
into Sandbox.dbo.elegibility_sixMDDstep2
from Sandbox.dbo.TX_CURR_6MDDpat tx
left join
Sandbox.dbo.elegibility_sixMDDstep1 elg 
on tx.nid=elg.nid and tx.HdD=elg.HdD


select *,
/*second version of the variable elegible*/
case when	idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and suppression='suppressed'
			and Active_originaldates='Active'
then 'eligible'
/*case 2*/
when		idade>14 and timeinART>=12 
			and (isoniazid='not on isoniazid' or isoniazid is null)
			and aderencia='aderiu' 
			and (estadiooms_final='not III/IV' or estadiooms_final is null)
			and (pregbf='not preg/bf' or pregbf is null)
			and (gaac='not on gaac' or gaac is null)
			and suppression is null and (lastcd4_ab='above 350' or secondlastcd4_ab='above 350')
			and Active_originaldates='Active'
then 'eligible'
else 'not elegible' 
end as sixmddeligvfinal 
into Sandbox.dbo.elegibility_sixMDDfinal
from Sandbox.dbo.elegibility_sixMDDstep2


/***************selecting for table***************/
--- Active status
select
Provincia
,Distrito
,designacao
,Active_originaldates
,count(Active_originaldates) countactive
from Sandbox.dbo.elegibility_sixMDDfinal
Where designacao is not null
group by 
Provincia
,Distrito
,designacao
,Active_originaldates
ORDER BY Provincia, Distrito, designacao, Active_originaldates



---- elegibility status
select
Provincia
,Distrito
,designacao
,sixmddeligvfinal
,count(sixmddeligvfinal) countelegible
from Sandbox.dbo.elegibility_sixMDDfinal_mod
Where designacao is not null
group by 
Provincia
,Distrito
,designacao
,sixmddeligvfinal
ORDER BY Provincia, Distrito, designacao, sixmddeligvfinal

