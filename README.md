# MozART Analytical Datasets and Views

Note: 
When developing new SQL queries for the production of analytical datasets, there are certain things to look out for (that aren't accounted for in the SQL cleaning script): 
=============================================================================================================================================================================
(1) Using datainiciotarv (from t_paciente): 
  We use datainiciotarv (date of ART initiation) to caluclate evaluation dates for retention, time on ART, and more. If it's NULL, there are certain steps to take (i.e. using the date of the first drug pick-up). Here's sample code that creates a revised datainiciotarv: 
  
  CASE	
    WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)<=cast([first_datatarv] AS DATE) THEN cast([datainiciotarv] AS DATE)
		WHEN [datainiciotarv] is not null AND [first_datatarv] is not null AND cast([datainiciotarv] AS DATE)>cast([first_datatarv] AS DATE) THEN cast([first_datatarv] AS DATE)
		WHEN [first_datatarv] is null and [datainiciotarv] is not null THEN cast([datainiciotarv] AS DATE)
		WHEN [first_datatarv] is not null and [datainiciotarv] is null THEN cast([first_datatarv] AS DATE)
	END AS revised_datainiciotarv
  
  =============================================================================================================================================================================
  (2) Nullifying datasaida (exit date) if there's a drug pick-up (datatarv) or consult (dataseguimento) that follows it 
  
  =============================================================================================================================================================================
  (3) When using lab results, note the following: 
  - there are lab results that are NOT associated with a date (i.e. there's a value for "resultado" but not for "dataresultado") - for that analysis, is a date required? 
  - there are illogical values for certain test results (whether because of differences among IPs in data entry, different lab platforms providing output in different ways ("<200" can't be typed in, so it's entered as "-200"), so restricting to specific test results may be necessary 
