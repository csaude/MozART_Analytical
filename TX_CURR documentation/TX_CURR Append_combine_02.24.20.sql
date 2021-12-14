SELECT *,

CASE WHEN [Status_adjusteddates]='Active' THEN 'Active'
	WHEN [Status_adjusteddates]= null THEN null 
	ELSE 'Not Active'
	END AS [Active_adjusteddates]
INTO [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_step1]
FROM
(
SELECT *,
CAST(Evaluation_Date as DATE) Evaluation_Date_format2

/*,CASE	WHEN [days_sched_encounter]>30 
AND [datasaidatarv]>=[Max_datatarv] AND [datasaidatarv]>=[Max_dataseguimento] AND [Status_originaldates] is not null THEN [Status_originaldates] /*left before and have confirmed status*/
		WHEN [days_sched_encounter]>30 
AND [datasaidatarv]<[Max_datatarv] OR [datasaidatarv]<[Max_dataseguimento] THEN 'LTFU' /*left before and have confirmed status*/
	WHEN [days_sched_encounter]>30 AND  [Status_originaldates] is null THEN 'LTFU'															/*>30 days are missing, no status confirmed*/

	WHEN [days_sched_encounter]<=30 AND [Status_originaldates] is not null THEN [Status_originaldates]										/*<30 days missing but confirmed status, left before*/
	WHEN [days_sched_encounter]<=30 AND [Status_originaldates] is null AND [datasaidatarv] is NULL THEN 'Active'														/*<30 days, no status confirmed*/
	END AS [Status_adjusteddates]
	/*	WHEN [days_sched_encounter]>30 AND [datasaidatarv]<[Evaluation_Date] AND [Revised_Codestado] is null THEN 'LTFU'					/*>30 days are missing, no status confirmed*/---can summarize all next three in one without datasaida.
	WHEN [days_sched_encounter]>30 AND [datasaidatarv] is null AND [Revised_Codestado] is null THEN 'LTFU'								/*>30 days are missing, no status confirmed*/
	WHEN [[days_sched_encounter]]>30 AND [datasaidatarv] is not null AND [Revised_Codestado] is null THEN 'LTFU'							/*>30 days are missing, no status confirmed--corrected codestado*/*/

	*/


,CASE WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Abandon' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Abandon'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'ART Suspend' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'ART Suspend'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Transferred Out' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Transferred Out'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Dead' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Dead'
	
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Abandon' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(Max_dataseguimento as date) is null) THEN 'Abandon'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'ART Suspend' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(Max_dataseguimento as date) is null) THEN 'ART Suspend'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Transferred Out' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(Max_dataseguimento as date) is null) THEN 'Transferred Out'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Dead' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(datasaidatarv as date)>=cast(Max_datatarv as date)) AND  (cast(Max_dataseguimento as date) is null) THEN 'Dead'

	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Abandon' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(Max_datatarv as date) is null) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Abandon'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'ART Suspend' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(Max_datatarv as date) is null) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'ART Suspend'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Transferred Out' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(Max_datatarv as date) is null) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Transferred Out'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Dead' AND cast(datasaidatarv as date) <= cast(Evaluation_Date as date) AND  (cast(Max_datatarv as date) is null) AND  (cast(datasaidatarv as date)>=cast(Max_dataseguimento as date)) THEN 'Dead'
	
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] ='LTFU' THEN 'LTFU'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] IS NULL THEN 'LTFU'
	WHEN ([days_sched_encounter]>30 AND  cast(datasaidatarv as date)<cast(Max_datatarv as date)) OR  ([days_sched_encounter]>30 AND cast(datasaidatarv as date)<cast(Max_dataseguimento as date)) THEN 'LTFU'
	WHEN [days_sched_encounter]>30 AND [Status_originaldates] = 'Active' THEN 'LTFU'   /*when adjusting the dates changed the status*/
	WHEN [days_sched_encounter]<=30 Then 'Active'
	ELSE NULL
	END AS [Status_adjusteddates]


FROM
(
SELECT *, CASE WHEN [Revised_dataproximaconsult]>[Revised_dataproxima_tarv] THEN DATEDIFF(dd, [Revised_dataproximaconsult], Evaluation_Date)
		WHEN [Revised_dataproximaconsult]<[Revised_dataproxima_tarv] THEN DATEDIFF(dd,[Revised_dataproxima_tarv], Evaluation_Date)
		WHEN [Revised_dataproximaconsult] is not null AND [Revised_dataproxima_tarv] is null THEN DATEDIFF(dd, [Revised_dataproximaconsult], Evaluation_Date)
		WHEN [Revised_dataproximaconsult] is null AND [Revised_dataproxima_tarv] is not null THEN DATEDIFF(dd,[Revised_dataproxima_tarv], Evaluation_Date)
		WHEN [Revised_dataproximaconsult]=[Revised_dataproxima_tarv] THEN DATEDIFF(dd,[Revised_dataproxima_tarv], Evaluation_Date)
		ELSE NULL
	END AS [days_sched_encounter]

, CASE WHEN [Revised_dataproximaconsult]>[Revised_dataproxima_tarv] THEN [Revised_dataproximaconsult]
		WHEN [Revised_dataproximaconsult]<[Revised_dataproxima_tarv] THEN [Revised_dataproxima_tarv]
		WHEN [Revised_dataproximaconsult] is not null AND [Revised_dataproxima_tarv] is null THEN [Revised_dataproximaconsult]
		WHEN [Revised_dataproximaconsult] is null AND [Revised_dataproxima_tarv] is not null THEN [Revised_dataproxima_tarv]
		WHEN [Revised_dataproximaconsult]=[Revised_dataproxima_tarv] THEN [Revised_dataproxima_tarv]
		ELSE null
	END AS [last_scheduled_encounter]


, CASE WHEN [Revised_second_dataproximaconsult]>[Revised_second_dataproxima_tarv] THEN [Revised_dataproximaconsult]
		WHEN [Revised_second_dataproximaconsult]<[Revised_second_dataproxima_tarv] THEN [Revised_second_dataproxima_tarv]
		WHEN [Revised_second_dataproximaconsult] is not null AND [Revised_second_dataproxima_tarv] is null THEN [Revised_dataproximaconsult]
		WHEN [Revised_second_dataproximaconsult] is null AND [Revised_second_dataproxima_tarv] is not null THEN [Revised_second_dataproxima_tarv]
		WHEN [Revised_second_dataproximaconsult]=[Revised_second_dataproxima_tarv] THEN [Revised_second_dataproxima_tarv]
		ELSE null
	END AS [second_last_sched_encounter]


, CASE WHEN [Max_dataseguimento]>[Max_datatarv] THEN DATEDIFF(dd, [Max_dataseguimento], Evaluation_Date)
		WHEN [Max_dataseguimento]<[Max_datatarv] THEN DATEDIFF(dd,[Max_datatarv], Evaluation_Date)
		WHEN [Max_dataseguimento] is not null AND [Max_datatarv] is null THEN DATEDIFF(dd, [Max_dataseguimento], Evaluation_Date)
		WHEN [Max_dataseguimento] is null AND [Max_datatarv] is not null THEN DATEDIFF(dd, [Max_datatarv], Evaluation_Date)
		WHEN [Max_dataseguimento]=[Max_datatarv] THEN DATEDIFF(dd,[Max_datatarv], Evaluation_Date)
		ELSE NULL
	END AS [days_actual_encounter]

, CASE WHEN [Max_dataseguimento]>[Max_datatarv] THEN [Max_dataseguimento]
		WHEN [Max_dataseguimento]<[Max_datatarv] THEN [Max_datatarv]
		WHEN [Max_dataseguimento] is not null AND [Max_datatarv] is null THEN [Max_dataseguimento]
		WHEN [Max_dataseguimento] is null AND [Max_datatarv] is not null THEN [Max_datatarv]
		WHEN [Max_dataseguimento]=[Max_datatarv] THEN [Max_datatarv]
		ELSE null
	END AS [last_actual_encounter]

, CASE WHEN [dataseguimento_second]>[datatarv_second] THEN [dataseguimento_second]
		WHEN [dataseguimento_second]<[datatarv_second] THEN [datatarv_second]
		WHEN [dataseguimento_second] is not null AND [datatarv_second] is null THEN [dataseguimento_second]
		WHEN [dataseguimento_second] is null AND [datatarv_second] is not null THEN [datatarv_second]
		WHEN [dataseguimento_second]=[datatarv_second] THEN [datatarv_second]
		ELSE null
	END AS [second_last_actual_encounter]




, CASE WHEN [datasaidatarv]>[Evaluation_Date] THEN NULL
	WHEN [datasaidatarv]<[Revised_dataproximaconsult] OR [datasaidatarv]<[Revised_dataproxima_tarv] THEN NULL
	ELSE [Status_originaldates]
END AS [Revised_Codestado]

FROM
(
SELECT *,

CASE	WHEN cast([revised_datainiciotarv] as date) between cast(DATEADD(dd,-31, Evaluation_Date) as date) AND cast(DATEADD(dd,-1,Evaluation_Date) as date) THEN 'New Patient'
		WHEN cast([revised_datainiciotarv] as date) < cast(DATEADD(dd,-31, Evaluation_Date) as date) OR ([revised_datainiciotarv] is null and first_datatarv< cast(DATEADD(dd,-31, Evaluation_Date) as date)) THEN 'Returning Patient'
ELSE null
END 
AS [NewPatient]



,CASE WHEN ([first_datatarv] is not null and [first_datatarv]<=Evaluation_Date) THEN 'Initiated'   /*patient really only initiated if they pick up ARV*/
ELSE 'Not Initiated' 
END AS [confirmed_initiated]

,
CASE WHEN Max_dataproxima_tarv is not null AND Max_datatarv<Max_dataproxima_tarv AND DayswithARV<=180 THEN  DATEADD(dd,DayswithARV,Max_datatarv)
	 WHEN Max_dataproxima_tarv is not null AND Max_datatarv<Max_dataproxima_tarv AND DayswithARV>180 THEN  DATEADD(dd,100,Max_datatarv)
	 WHEN Max_dataproxima_tarv is not null AND Max_datatarv>Max_dataproxima_tarv THEN  DATEADD(dd,30,Max_datatarv)
	 WHEN Max_dataproxima_tarv is not null AND Max_datatarv=Max_dataproxima_tarv THEN  DATEADD(dd,30,Max_datatarv)
	 WHEN Max_dataproxima_tarv is null AND MAX_datatarv is not null THEN DATEADD(dd,30,Max_datatarv)
	 ELSE null
END AS [Revised_dataproxima_tarv]

,
CASE WHEN Max_dataproximaconsult is not null AND Max_dataseguimento<Max_dataproximaconsult AND DATEDIFF(dd, Max_dataseguimento,Max_dataproximaconsult)<=180 THEN  Max_dataproximaconsult
	 WHEN Max_dataproximaconsult is not null AND Max_dataseguimento<Max_dataproximaconsult AND DATEDIFF(dd, Max_dataseguimento,Max_dataproximaconsult)>180 THEN  DATEADD(dd,100,Max_dataseguimento)
	 WHEN Max_dataproximaconsult is not null AND Max_dataseguimento>Max_dataproximaconsult THEN  DATEADD(dd,30,Max_dataseguimento)
	 WHEN Max_dataproximaconsult is not null AND Max_dataseguimento=Max_dataproximaconsult THEN DATEADD(dd,30,Max_dataseguimento)
	 WHEN Max_dataproximaconsult is null THEN DATEADD(dd,30,Max_dataseguimento)
	 ELSE null
END AS [Revised_dataproximaconsult]

,
CASE WHEN proximatarv_second is not null AND datatarv_second<proximatarv_second AND Second_DayswithARV<=180 THEN  DATEADD(dd,Second_DayswithARV,datatarv_second)
	 WHEN proximatarv_second is not null AND datatarv_second<proximatarv_second AND Second_DayswithARV>180 THEN  DATEADD(dd,100,datatarv_second)
	 WHEN proximatarv_second is not null AND datatarv_second>proximatarv_second THEN  DATEADD(dd,30,datatarv_second)
	 WHEN proximatarv_second is not null AND datatarv_second=proximatarv_second THEN  DATEADD(dd,30,datatarv_second)
	 WHEN proximatarv_second is null AND datatarv_second is not null THEN DATEADD(dd,30,datatarv_second)
	 ELSE null
END AS [Revised_second_dataproxima_tarv]

,
CASE WHEN proximaconsult_second is not null AND dataseguimento_second<proximaconsult_second AND DATEDIFF(dd, dataseguimento_second,proximaconsult_second)<=180 THEN  proximaconsult_second
	 WHEN proximaconsult_second is not null AND dataseguimento_second<proximaconsult_second AND DATEDIFF(dd, dataseguimento_second,proximaconsult_second)>180 THEN  DATEADD(dd,100,dataseguimento_second)
	 WHEN proximaconsult_second is not null AND dataseguimento_second>proximaconsult_second THEN  DATEADD(dd,30,dataseguimento_second)
	 WHEN proximaconsult_second is not null AND dataseguimento_second=proximaconsult_second THEN  DATEADD(dd,30,dataseguimento_second)
	 WHEN proximaconsult_second is null THEN DATEADD(dd,30,dataseguimento_second)
	 ELSE null
END AS [Revised_second_dataproximaconsult]


,
 REPLACE(REPLACE(REPLACE(REPLACE(codestado
			,'ABANDONO','Abandon')
			,'OBITOU', 'Dead')
			,'SUSPENDER TRATAMENTO', 'ART Suspend')
			,'TRANSFERIDO PARA','Transferred Out') [Codestado_English]

FROM
(
	
	SELECT *, CASE WHEN nid IS NOT NULL THEN 'June 2018' ELSE NULL END AS Period_Month  
	FROM Sandbox.dbo.TX_CURR_JUN18
	WHERE [revised_datainiciotarv]<=Evaluation_Date /*AND (Max_datatarv<Evaluation_Date OR Max_datatarv is null)  conditions 2 and 3 are actually taken into account by [confirm_initiated] variable
	AND (Max_dataseguimento<Evaluation_Date OR Max_dataseguimento is null)*/


	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'July 2018' ELSE NULL END AS Period_Month     /*check if there are more null nids in MAY 2019*/
	FROM Sandbox.dbo.TX_CURR_JUL18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'August 2018' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_AUG18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'September 2018' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_SEP18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'October 2018' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_OCT18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'November 2018' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_NOV18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'December 2018' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_DEC18
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'January 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_JAN19
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'February 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_FEB19
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'March 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_MAR19
	WHERE [revised_datainiciotarv]<=Evaluation_Date

	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'April 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_APR19
	WHERE [revised_datainiciotarv]<=Evaluation_Date


	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'May 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_MAY19
	WHERE [revised_datainiciotarv]<=Evaluation_Date


	UNION ALL

	SELECT * , CASE WHEN nid IS NOT NULL THEN 'Jun 2019' ELSE NULL END AS Period_Month
	FROM Sandbox.dbo.TX_CURR_JUN19
	WHERE [revised_datainiciotarv]<=Evaluation_Date


) master
) master2
WHERE [confirmed_initiated]='Initiated') master3
) master4


SELECT *
,CASE	WHEN [Status_adjusteddates]='Active' AND datediff(dd,[second_last_sched_encounter],[last_actual_encounter])<=30 /*patient was Active because they came to last encounter less than 30 days after it was scheduled*/ 
			AND datediff(dd,[second_last_sched_encounter],[last_actual_encounter])>6 THEN 'Retained_7_30_late'
		WHEN [Status_adjusteddates]='Active' AND datediff(dd,[second_last_sched_encounter],[last_actual_encounter])>=1
			AND datediff(dd,[second_last_sched_encounter],[last_actual_encounter])<=6 THEN 'Retained_1_6_late'
		WHEN ([Status_adjusteddates]='Active' AND datediff(dd,[second_last_sched_encounter],[last_actual_encounter])<1) OR 
		([Status_adjusteddates]='Active' AND [second_last_actual_encounter] is null) OR ([Status_adjusteddates]='Active' AND [NewPatient]='New Patient' AND [datatarv_second] is null) THEN 'Retained_0_late'    /*this includes all patients who have had only one encounter*/
		END AS Retained_time_categ

,CASE	WHEN datediff(dd,cast([second_last_sched_encounter] as date),cast([last_actual_encounter] as date))>30 /*patient was LTFU because they came to last encounter more than 30 days after it was scheduled*/ 
			AND datediff(dd,cast([second_last_sched_encounter] as date), cast([last_actual_encounter] as date))<=60 AND [Status_adjusteddates]='Active' AND ([NewPatient]!='New Patient' or [NewPatient] is null) THEN 'Returned_care_31_60'
		WHEN datediff(dd,cast([second_last_sched_encounter] as date),cast([last_actual_encounter] as date))>60  
			AND datediff(dd,cast([second_last_sched_encounter] as date), cast([last_actual_encounter] as date))<=180 AND [Status_adjusteddates]='Active' AND ([NewPatient]!='New Patient' or [NewPatient] is null) THEN 'Returned_care_60_180'
		WHEN datediff(dd,cast([second_last_sched_encounter] as date),cast([last_actual_encounter] as date))>180 AND [Status_adjusteddates]='Active' AND ([NewPatient]!='New Patient' or [NewPatient] is null) THEN 'Returned_care_GT180'
		END AS Returning_time_categ
/*
,CASE	WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>60 AND [days_sched_encounter]<180) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>60 AND [days_sched_encounter]<180) THEN 'Abandoned_2_5_mo' /*Abandoned beetwen [2-6months[*/ 
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=180 AND [days_sched_encounter]<360) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=180 AND [days_sched_encounter]<360) THEN 'Abandoned_6_11mo' /*Abandoned beetwen [6-12months[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=360 AND [days_sched_encounter]<720) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=360 AND [days_sched_encounter]<720) THEN 'Abandoned_1yr' /*Abandoned beetwen [1-2year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=720 AND [days_sched_encounter]<1080) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=720 AND [days_sched_encounter]<1080) THEN 'Abandoned_2yr' /*Abandoned beetwen [2-3year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=1080 AND [days_sched_encounter]<1440) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=1080 AND [days_sched_encounter]<1440) THEN 'Abandoned_3yr' /*Abandoned beetwen [3-4year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=1440 AND [days_sched_encounter]<1800) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=1440 AND [days_sched_encounter]<1800) THEN 'Abandoned_4yr' /*Abandoned beetwen [4-5year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=1800 AND [days_sched_encounter]<2160) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=1800 AND [days_sched_encounter]<2160) THEN 'Abandoned_5yr' /*Abandoned beetwen [5-6year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=2160 AND [days_sched_encounter]<2520) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=2160 AND [days_sched_encounter]<2520) THEN 'Abandoned_6yr' /*Abandoned beetwen [6-7year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=2520 AND [days_sched_encounter]<2880) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=2520 AND [days_sched_encounter]<2880) THEN 'Abandoned_7yr' /*Abandoned beetwen [7-8year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=2880 AND [days_sched_encounter]<3240) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=2880 AND [days_sched_encounter]<3240) THEN 'Abandoned_8yr' /*Abandoned beetwen [8-9year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=3240 AND [days_sched_encounter]<3600) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=3240 AND [days_sched_encounter]<3600) THEN 'Abandoned_9yr' /*Abandoned beetwen [8-9year[*/
		WHEN ([Status_adjusteddates]='LTFU' AND [days_sched_encounter]>=3600) OR ([Status_adjusteddates]='Abandon' AND [days_sched_encounter]>=3600) THEN 'Abandoned_>10yr' /*Abandoned more than [10years[*/
		END AS Abandon_time_categ
*/
,CASE	WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>30 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<180) THEN 'Abandoned_1_5_mo' /*Abandoned beetwen [2-6months[*/ 
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=180 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<360) THEN 'Abandoned_6_11mo' /*Abandoned beetwen [6-12months[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=360 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<720) THEN 'Abandoned_1yr' /*Abandoned beetwen [1-2year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=720 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<1080) THEN 'Abandoned_2yr' /*Abandoned beetwen [2-3year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=1080 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<1440) THEN 'Abandoned_3yr' /*Abandoned beetwen [3-4year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=1440 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<1800) THEN 'Abandoned_4yr' /*Abandoned beetwen [4-5year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=1800 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<2160) THEN 'Abandoned_5yr' /*Abandoned beetwen [5-6year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=2160 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<2520) THEN 'Abandoned_6yr' /*Abandoned beetwen [6-7year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=2520 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<2880) THEN 'Abandoned_7yr' /*Abandoned beetwen [7-8year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=2880 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<3240) THEN 'Abandoned_8yr' /*Abandoned beetwen [8-9year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=3240 AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))<3600) THEN 'Abandoned_9yr' /*Abandoned beetwen [8-9year[*/
		WHEN ([Status_adjusteddates] IN ('LTFU', 'Abandon') AND datediff(dd,cast([last_scheduled_encounter] as date),cast([Evaluation_Date] as date))>=3600) THEN 'Abandoned_>10yr' /*Abandoned more than [10years[*/
		END AS Abandon_time_categ


INTO [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_Final]
FROM [Sandbox].[dbo].[TX_CURR_JUN18_JUN19_step1]




--We still have new patients who still don't have a status, they are wrong dates essentially. Correct the dates so that all who are new are classified as retained. Also use corrected date of initiation.
