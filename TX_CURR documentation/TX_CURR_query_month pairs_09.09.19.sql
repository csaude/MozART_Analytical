---Oct18 to May19 Pair Script
-------------------
SELECT Sandbox.dbo.TX_CURR_OCT18.nid, Sandbox.dbo.TX_CURR_OCT18.HdD, Sandbox.dbo.TX_CURR_OCT18.Provincia, Sandbox.dbo.TX_CURR_OCT18.Distrito,
      Sandbox.dbo.TX_CURR_OCT18.designacao,
	 
	  Sandbox.dbo.TX_CURR_OCT18.sexo 
	  ,Sandbox.dbo.TX_CURR_OCT18.datanasc, Sandbox.dbo.TX_CURR_OCT18.idadeiniciotarv
	  ,Sandbox.dbo.TX_CURR_OCT18.datainiciotarv, Sandbox.dbo.TX_CURR_OCT18.Year_Inicio
	  ,Sandbox.dbo.TX_CURR_OCT18.datadiagnostico
      ,Sandbox.dbo.TX_CURR_OCT18.datasaidatarv
      ,Sandbox.dbo.TX_CURR_OCT18.codestado
	  
      ,Max_datatarv_OCT18 ,Max_dataseguimento_OCT18
      ,Max_dataproxima_tarv_OCT18 ,Max_dataproximaconsult_OCT18
	  ,Max_datatarv_NOV18 ,Max_dataseguimento_NOV18
	  ,Max_dataproxima_tarv_NOV18 ,Max_dataproximaconsult_NOV18
      ,Evaluation_Date_OCT18 ,Evaluation_Date_NOV18
	  ,Outcome_OCT18, Outcome_NOV18 ,TX_CURR_OCT18 ,TX_CURR_NOV18
	  
	   
,CASE WHEN TX_CURR_OCT18 = 'Active'
 AND
TX_CURR_NOV18 = 'Not Active'
THEN
'Dropped Out' 
WHEN
TX_CURR_NOV18 = 'Active'
THEN
'Active' 
ELSE 'Not Active'
END AS OCT_NOV_DropOuts


INTO Sandbox.dbo.TX_CURR_Final_NOV18
FROM Sandbox.dbo.TX_CURR_OCT18
FULL OUTER JOIN Sandbox.dbo.TX_CURR_NOV18
ON TX_CURR_OCT18.nid = TX_CURR_NOV18.nid AND TX_CURR_OCT18.HdD = TX_CURR_NOV18.HdD


ALTER TABLE [Sandbox].[dbo].[TX_CURR_Final_NOV18] ADD [Time_on_ART_OCT] 
 AS CASE WHEN datainiciotarv<'2018-10-21' THEN DATEDIFF(month, datainiciotarv, '2018-10-21')
ELSE NULL END

ALTER TABLE [Sandbox].[dbo].[TX_CURR_Final_NOV18] ADD [Time_on_ART_NOV] 
 AS CASE WHEN datainiciotarv<'2018-11-21' THEN DATEDIFF(month, datainiciotarv, '2018-11-21')
ELSE NULL END




--=============================================

SELECT Sandbox.dbo.TX_CURR_MAY19.nid, Sandbox.dbo.TX_CURR_MAY19.HdD, Sandbox.dbo.TX_CURR_MAY19.Provincia, Sandbox.dbo.TX_CURR_MAY19.Distrito,
      Sandbox.dbo.TX_CURR_MAY19.designacao
	  
	  ,Sandbox.dbo.TX_CURR_MAY19.sexo 
	  ,Sandbox.dbo.TX_CURR_MAY19.datanasc, Sandbox.dbo.TX_CURR_MAY19.idadeiniciotarv
	  ,Sandbox.dbo.TX_CURR_MAY19.datainiciotarv, Sandbox.dbo.TX_CURR_MAY19.Year_Inicio
	  ,Sandbox.dbo.TX_CURR_MAY19.datadiagnostico
      ,Sandbox.dbo.TX_CURR_MAY19.datasaidatarv
      ,Sandbox.dbo.TX_CURR_MAY19.codestado
      
	  ,Max_datatarv_MAY19 ,Max_dataseguimento_MAY19
      ,Max_dataproxima_tarv_MAY19 ,Max_dataproximaconsult_MAY19
	  ,Max_datatarv_JUN19 ,Max_dataseguimento_JUN19
	  ,Max_dataproxima_tarv_JUN19 ,Max_dataproximaconsult_JUN19
      ,Evaluation_Date_MAY19 ,Evaluation_Date_JUN19
	  ,Outcome_MAY19, Outcome_JUN19 ,TX_CURR_MAY19 ,TX_CURR_JUN19
	  
	   
,CASE WHEN TX_CURR_MAY19 = 'Active'
 AND
TX_CURR_JUN19 = 'Not Active'
THEN
'Dropped Out' 
WHEN
TX_CURR_JUN19 = 'Active'
THEN
'Active' 
ELSE 'Not Active'
END AS MAY_JUN_DropOuts


INTO Sandbox.dbo.TX_CURR_Final_JUN19
FROM Sandbox.dbo.TX_CURR_MAY19
FULL OUTER JOIN Sandbox.dbo.TX_CURR_JUN19
ON TX_CURR_MAY19.nid = TX_CURR_JUN19.nid AND TX_CURR_MAY19.HdD = TX_CURR_JUN19.HdD




ALTER TABLE [Sandbox].[dbo].[TX_CURR_Final_JUN19] ADD [Time_on_ART_MAY] 
 AS CASE WHEN datainiciotarv<'2019-05-21' THEN DATEDIFF(month, datainiciotarv, '2019-05-21')
ELSE NULL END

ALTER TABLE [Sandbox].[dbo].[TX_CURR_Final_JUN19
] ADD [Time_on_ART_JUN] 
 AS CASE WHEN datainiciotarv<'2019-06-21' THEN DATEDIFF(month, datainiciotarv, '2019-06-21')
ELSE NULL END
-----+++++++++++++++++++++++++++++++++++++++++====================






