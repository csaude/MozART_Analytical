-----------Regimens information-----------------------------------------------------------------
----Query created by: Marcela Torres
----Updated on 6.10.20 MozARTQ12020 data
----Create a summary view before running the queries below
-------------------------------------------------------------------------------------------------
  ---Data Quality check patient count---
 SELECT count (DISTINCT nid)
 FROM MozART_q1_2020.dbo.v_SummaryQ1FY20

  ---Data Quality checks patient counts---
 SELECT count (DISTINCT nid)
 FROM MozART_q1_2020.dbo.v_SummaryQ1FY20
  GROUP BY Province
 -- ORDER BY Province

  ---Data Quality checks health facility counts---
 SELECT Province, count (DISTINCT Health_Facility)
 FROM MozART_q1_2020.dbo.v_SummaryQ1FY20
  GROUP BY Province
  ORDER BY Province

 SELECT Province, count (DISTINCT nid)
 FROM MozART_q1_2020.dbo.v_SummaryQ1FY20
 WHERE Last_Regimen IS NULL AND (Last_Drug_Pickup_Date BETWEEN '10/01/2019' AND '12/31/2019')
 GROUP BY Province

  ----------------------------------------------------------------------------------------------
  ---Regimen counts including province, district, and health facility

SELECT p.Province,p.District, p.CurrentAgeBand, p.Last_Regimen,p.AgeGroup,p.Recent_Viral_Load,
  COUNT (p.Last_Regimen) Nr_patientes
  
  FROM (SELECT DISTINCT nid, CurrentAgeBand, Last_Regimen, Last_Drug_Pickup_Date,Recent_Viral_Result, Province, District,
      Recent_Viral_Load,
      Recent_Viral_Load_Date,
	  
	   Case       
           WHEN datediff(yy,Birth_Date,'12/31/2019')  < 15 THEN 'Peds' ELSE 'Adults' 
  END AS AgeGroup 

  FROM [MozART_q1_2020].[dbo].[v_SummaryQ1FY20]) p
  WHERE p.Last_Drug_Pickup_Date BETWEEN '10/01/2019' AND '12/31/2019'
  GROUP BY p.Province, p.District, p.Last_Regimen, p.AgeGroup, p.CurrentAgeBand, p.Recent_Viral_Load
  ORDER BY p.Last_Regimen
 


---Saving results in a table as a test to connect from PowerBi

SELECT Province,District, CurrentAgeBand, Last_Regimen,Recent_Viral_Load,
  COUNT (DISTINCT nid) Nr_patientes

  INTO Sandbox.dbo.Regimens_FY20Q1_Test 
  FROM [MozART_q1_2020].[dbo].[v_SummaryQ1FY20]
  WHERE Last_Drug_Pickup_Date BETWEEN '10/01/2019' AND '12/31/2019'
  GROUP BY Province, District, Last_Regimen,CurrentAgeBand, Recent_Viral_Load
  ORDER BY Last_Regimen
  


---Regimen with patients counts only
  SELECT p.CurrentAgeBand, p.Last_Regimen,p.AgeGroup,p.Recent_Viral_Load,
  COUNT (p.Last_Regimen) Nr_patientes 
  
  FROM (SELECT DISTINCT nid, CurrentAgeBand, Last_Regimen, Last_Drug_Pickup_Date,Recent_Viral_Result
      ,Recent_Viral_Load
      ,Recent_Viral_Load_Date,
	  
	   Case       
                     WHEN datediff(yy,Birth_Date,'12/31/2019')  < 15 THEN 'Peds' ELSE 'Adults' 
  END AS AgeGroup 
  
  FROM [MozART_q1_2020].[dbo].[v_SummaryQ1FY20]) p


  WHERE p.Last_Drug_Pickup_Date BETWEEN '10/01/2019' AND '12/31/2019'

  GROUP BY p.Last_Regimen, p.AgeGroup, p.CurrentAgeBand, p.Recent_Viral_Load

  ORDER BY p.Last_Regimen
  

  ---Regimen Switch--
  /*## Define Cohort ##*/
  
Create view Regimen_switch_Q4 as

SELECT        Province, District, Health_Facility, NID, AgeGroup, Sex, Last_Regimen,AccessFilePath
FROM            (SELECT DISTINCT Province, District, Health_Facility, NID, Sex, Last_Regimen, Last_Drug_Pickup_Date, CASE WHEN datediff(yy, Birth_Date, '09/30/2019') < 15 THEN 'Peds' ELSE 'Adults' END AS AgeGroup,AccessFilePath
                          FROM            dbo.v_Summary) AS p
WHERE        (Last_Drug_Pickup_Date BETWEEN '06/20/2019' AND '09/21/2019');

/*## Last and Prior Drug pick up Q4##*/

select res.* from 
(select reg.*, p.codregime,p.datatarv,
ROW_NUMBER() OVER (PARTITION BY reg.nid 
                           ORDER BY p.datatarv DESC) as RowNum 

 from Regime_swith_Q4 reg
left join 
(select tv.nid,tv.datatarv,tv.codregime,tv.AccessFilePath from t_tarv tv
where cast(tv.datatarv as date) BETWEEN '01/20/2019' AND '06/19/2019')p
on reg.nid=p.nid 
and reg.AccessFilePath=p.AccessFilePath) res
where res.RowNum in (1,2)

/*## compare regimen##*/

/*drop view compare_regimen;*/
create view compare_regimen as
select g.Province, g.District,g.Health_Facility,g.NID,g.AgeGroup,g.Sex,g.Last_Regimen,g.codregime as codregime1,h.codregime as codregime2,l.codregime as codregime3,g.datatarv as datatarv1,h.datatarv as datatarv2,l.datatarv as datatarv3, 
Case when g.codregime<>h.codregime or h.codregime<>l.codregime  then 'changed_regime' else 'same_regime' end as result

from

(select res.* from 
(select reg.*, p.codregime,p.datatarv,
ROW_NUMBER() OVER (PARTITION BY reg.nid 
                           ORDER BY p.datatarv DESC) as RowNum 

 from Regime_swith_Q4 reg
left join 
(select tv.nid,tv.datatarv,tv.codregime,tv.AccessFilePath from t_tarv tv
where cast(tv.datatarv as date) BETWEEN '01/20/2019' AND '06/19/2019')p
on reg.nid=p.nid 
and reg.AccessFilePath=p.AccessFilePath) res
where res.RowNum =1) g

inner join

(select res.* from 
(select reg.*, p.codregime,p.datatarv,
ROW_NUMBER() OVER (PARTITION BY reg.nid 
                           ORDER BY p.datatarv DESC) as RowNum 

 from Regime_swith_Q4 reg
left join 
(select tv.nid,tv.datatarv,tv.codregime,tv.AccessFilePath from t_tarv tv
where cast(tv.datatarv as date) BETWEEN '01/20/2019' AND '06/19/2019')p
on reg.nid=p.nid 
and reg.AccessFilePath=p.AccessFilePath) res
where res.RowNum =2) h

on g.nid=h.nid

left join

(select res.* from 
(select reg.*, p.codregime,p.datatarv,
ROW_NUMBER() OVER (PARTITION BY reg.nid 
                           ORDER BY p.datatarv DESC) as RowNum 

 from Regimen_switch_Q4 reg
left join 
(select tv.nid,tv.datatarv,tv.codregime,tv.AccessFilePath from t_tarv tv
where cast(tv.datatarv as date) BETWEEN '01/20/2019' AND '06/19/2019')p
on reg.nid=p.nid 
and reg.AccessFilePath=p.AccessFilePath) res
where res.RowNum =3) l

on g.nid=l.nid
 /*and g.codregime<>h.codregime*/