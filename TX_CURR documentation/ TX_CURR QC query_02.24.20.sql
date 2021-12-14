SELECT  top 20

[HdD]
      ,[Provincia]
      ,[Distrito]
      ,[designacao]
      ,[nid]
 ---     ,[sexo]
 ---     ,[datanasc]

	  ,[confirmed_initiated]

      ,[datainiciotarv]
---	  ,[Period_Month]

	  ,[Max_datatarv]		,[Max_dataseguimento] 	
      
	  ,[Max_dataproxima_tarv]    ,[Max_dataproximaconsult]      

      ,[Revised_dataproxima_tarv]  ,[Revised_dataproximaconsult]

      ,[last_scheduled_encounter]
	  ,[Evaluation_Date]   ,[days_sched_encounter]
/*      ,[last_actual_encounter] 
      ,[days_actual_encounter]
*/
      
      ,[datasaidatarv]
	  
	       
	/*  ,[datatarv_second]
      ,[proximatarv_second]
      ,[dataseguimento_second]
      ,[proximaconsult_second]
---,[Revised_second_dataproxima_tarv]
---,[Revised_second_dataproximaconsult]

	*/
	,[codestado]

	  ,[Active_originaldates]  ,[Status_originaldates]
    
      ,[Active_adjusteddates]   ,[Status_adjusteddates]
   
    ---	,[NewPatient]
---      ,[second_last_actual_encounter]	,[second_last_sched_encounter]
 ----     ,[Revised_Codestado]
  ----    ,[Evaluation_Date_format2]

/*    ,[Returning_time_categ]
      ,[Retained_time_categ]
      ,[Active_Patient]
      ,[Abandon_time_categ]    */
  FROM [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]

  Where [Status_adjusteddates] is null
  
  ---and [nid]='0105010018000217596'
  
  
  ----and [days_sched_encounter]<30
 --- Where 	  [Active_adjusteddates]='Active' and [Status_adjusteddates]!='Active'   
  ---- [nid]='0105010018000217596'



 select distinct  nid
from [TX_CURR_JUN18_JUN19_Final]
Where [Status_adjusteddates] is null


 select top 50 [HdD]
      ,[Provincia]
      ,[Distrito]
      ,[designacao]
      ,[nid]
 ---     ,[sexo]
 ---     ,[datanasc]


---	  ,[Period_Month]

	  	,[Max_dataseguimento] 	
      
	  ,[Max_dataproxima_tarv]    ,[Max_dataproximaconsult]      

      ,[Revised_dataproxima_tarv]  ,[Revised_dataproximaconsult]

      ,[last_scheduled_encounter]
	  ,[Evaluation_Date]   ,[days_sched_encounter]
      ,[last_actual_encounter] 
      ,[days_actual_encounter]

      
      ,[datasaidatarv]
	  
	       
	  ,[datatarv_second]
      ,[proximatarv_second]
      ,[dataseguimento_second]
      ,[proximaconsult_second]
,[Revised_second_dataproxima_tarv]
,[Revised_second_dataproximaconsult]

	
	,[codestado]

	  ,[Active_originaldates]  ,[Status_originaldates]
    
      ,[Active_adjusteddates]   ,[Status_adjusteddates]
	  ,[confirmed_initiated]
	  ,Evaluation_date
	  ,cast(DATEADD(dd,-31, Evaluation_Date) as date) beginmonth
	  ,cast(DATEADD(dd,-1,Evaluation_Date) as date) endmonth
      ,[datainiciotarv]   
    ,[NewPatient]
	,[Max_datatarv]	
    ,[second_last_actual_encounter]	,[second_last_sched_encounter]
 ----     ,[Revised_Codestado]
  ----    ,[Evaluation_Date_format2]

    ,[Returning_time_categ]
      ,[Retained_time_categ]
     --- ,[Active_Patient]
      ,[Abandon_time_categ]  
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
Where [NewPatient] like '%New%' and  [Abandon_time_categ]='Abandoned_2_5_mo'

select *
from [TX_CURR_JUN18_JUN19_Final]
Where cast([revised_datainiciotarv] as date) between cast(DATEADD(dd,-31, Evaluation_Date) as date) AND cast(DATEADD(dd,-1,Evaluation_Date) as date) 
and [Returning_time_categ] is not null
and nid='090108095331269'


/*No new patients are abandon*/
select *
from [TX_CURR_JUN18_JUN19_Final]
Where [NewPatient]='New Patient' and [Abandon_time_categ] is not null


/*No new patients are returning*/
select *
from [TX_CURR_JUN18_JUN19_Final]
Where [NewPatient]='New Patient' and [Returning_time_categ] is not null 


/*Count of new patient*/
select count(NewPatient) newpatients
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
Where cast([revised_datainiciotarv] as date) between cast(DATEADD(dd,-31, Evaluation_Date) as date) AND cast(DATEADD(dd,-1,Evaluation_Date) as date)
group by NewPatient

/*Count of new patient*/
select count(nid) newpatients
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
Where [NewPatient]='New Patient'

/*Count of returning patient*/
select count(NewPatient) returningpatients
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where cast([revised_datainiciotarv] as date) < cast(DATEADD(dd,-31, Evaluation_Date) as date) OR ([revised_datainiciotarv] is null and first_datatarv< cast(DATEADD(dd,-31, Evaluation_Date) as date))

/*Count of returning patient*/
select count(NewPatient) returningpatients
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where [NewPatient]='Returning Patient'


/*no patient is abandon and return*/
select Top 10 *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where [Abandon_time_categ] is not null and [Returning_time_categ] is not null


/*no patient is retained and abandon or retain and return*/
select  *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where ([Retained_time_categ] is not null and [Abandon_time_categ] is not null) or ([Returning_time_categ] is not null and [Retained_time_categ] is not null)


/*
/*Count of returning patient*/
select count([Retained_time_categ]) retained, count([Abandon_time_categ]) abandon, count([Returning_time_categ]) returned
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where [Retained_time_categ] is not null or [Abandon_time_categ] is not null or [Returning_time_categ] is not null and [Period_Month] like '%May%'
----Group by nid, Province
*/


/*were active, are now active and they were not classified under retained time*/
select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  datediff(dd,[second_last_sched_encounter],[last_actual_encounter])<=30 and [Status_adjusteddates]='Active' and [Retained_time_categ] is null

/*were not active are now active and were not classified under returned time*/
select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  datediff(dd,[second_last_sched_encounter],[last_actual_encounter])>30 and [Status_adjusteddates]='Active' and [Returning_time_categ] is null

select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Abandon_time_categ] is null and [Status_adjusteddates] IN ('Abandon', 'LTFU') and [days_sched_encounter] is not null


select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Abandon_time_categ] is null and [Returning_time_categ] is null and [Retained_time_categ] is null and [Status_adjusteddates] IN ('Abandon', 'LTFU', 'Active') 


select top 10 *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Abandon_time_categ] is null and [Status_adjusteddates] IN ('Abandon', 'LTFU') and [days_sched_encounter] is not null

/*miss classified LTFU*/
select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Abandon_time_categ] is null and [Status_adjusteddates] IN ('Abandon', 'LTFU') and [days_sched_encounter]<30

/*All active patients are correct they don't have exit after all encounter and before evaluation* they are still active because their status has not been validated in next month*/
select count(*)
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Status_adjusteddates]='Active' AND [datasaidatarv]<[Evaluation_date]  AND [days_sched_encounter]<=30 AND [datasaidatarv]>[Max_datatarv] AND [datasaidatarv]>[Max_dataseguimento]

select count(*) nrabandon
from [Sandbox].[dbo].[TX_CURR_OCT18]
where [Status_originaldates] in ('Abandon', 'LTFU')


select top 10 *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Returning_time_categ] is not null and [Retained_time_categ] is not null   and [Status_adjusteddates] IN ('Abandon', 'LTFU', 'Active') 

and [Abandon_time_categ] is not null


/*There are new patients that are also classifed as returned time because their scheduled second pick up is less than 30 days TIPICALLY 15 days and they were late*/
select top 100 *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Status_adjusteddates]='Active' AND [Retained_time_categ]='Retained_7_30_late' and [NewPatient]='New Patient'


select *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Status_adjusteddates]='Active' AND [Retained_time_categ] is null and [Returning_time_categ] is null and [Abandon_time_categ] is null


select *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Status_adjusteddates]='Active' AND ([Returning_time_categ] is not null OR [Abandon_time_categ] is not null)  and [NewPatient]='New Patient'


select top 100 *
from [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
where  [Status_adjusteddates]='Active' AND [Retained_time_categ] is not null
AND [second_last_actual_encounter] is null AND datediff(dd,[last_scheduled_encounter],[Evaluation_Date])>1


--We still have new patients who still don't have a status, they are wrong dates essentially. Correct the dates so that all who are new are classified as retained. Also use corrected date of initiation.


and nid='02/009/13/2395'

and nid='011005550120184171523'

AND nid='01100555012018861628'



