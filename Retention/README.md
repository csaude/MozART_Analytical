Analytical Datasets: Retention
===

*These are working scripts requiring QC before they are ready for production*

## SQL Query

The SQL code can be run as-is inside of SQL Server Management Studio or in R using ODBC::dbGetQuery.

### SELECT Statement

```
SELECT f.HdD, f.Provincia, f.Distrito, f.designacao, f.local,
p.nid, p.sexo, p.idade, p.datainiciotarv, Outcome_Date = dateadd(yy, 1, datainiciotarv), p.datadiagnostico, p.datasaidatarv, p.codestado,
t.MaxOfdatatarv, t.MaxOfdataproxima,
s.MaxOfdataseguimento, s.MaxOfdataproximaconsulta, gg.datainicio as DatainicioGAAC, s.Gravidez,
p.AccessFilePath as Caminho
```

The SELECT statement is used to select the variables of interest from the tables of MozART. The order of the variables inside the SELECT statement is the order of the columns of the final output.

I also want to draw your attention to a couple of interesting things going on in the SELECT statement:

```
SELECT f.HdD...
```
Notice the prefix "f." in front of the variables. These are what SQL calls aliases - temporary names for columns or tables. Each variable has an alias prefix indicating the source table of that variable. This is important if you have two or more tables with the same variable name. Aliases are also very useful for a number of other reasons as well. I use aliases so that I can pull in a subset of the table I'm interested instead of pulling in the entire table. This speeds up processing as I don't need all of the columns for every table of interest.

```
Outcome_Date = dateadd(yy, 1, datainiciotarv)
```
This snippet takes the "datainiciotarv" variable and adds one year to each initiation date using `dateadd()` to get the 12 month retention date.


### INTO Statement

```
INTO Sandbox.dbo.retention_cohort_2012_2019
```
INTO saves the results of the query into a table inside of the Sandbox database (a working environment for your SQL queries). Word of advice for working with SQL databases: you should always make a copy of your raw database and work off of that copy so that you have a backup of the database should anything go awry.

### FROM Statement

```
FROM
(SELECT nid, sexo, idade, hdd, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
FROM t_paciente) p
```
In this snippet, I am using the FROM clause to tell the SQL server where to get the required data. After the FROM command, I am specifying a subset of t_paciente (as I don't need every column from t_paciente) and assigning the alias of "p" after my SELECT statement.

Notice in the SELECT statement I use the function `cast()` to turn the date variables into date. The reason being is that the SQL import script stores all the date fields in MozART as varchar types. In order to do calculations (`max()`, `min()`, `dateadd`, etc) on these date variables, you will have to convert them back into dates using `cast()`.


### LEFT JOIN Statements
```
LEFT JOIN
(SELECT HdD, Provincia, Distrito, designacao, local, AccessFilePath
FROM t_hdd) f
ON p.hdd = f.HdD AND p.AccessFilePath = f.AccessFilePath
```
Now using the t_paciente subset as my base table, I am going to start joining all of the other retention variables to each "nid" using `LEFT JOIN`. Here again, I am just taking a subset of t_hdd assigning the alias of "f" then doing my left join (joining the health facility information from t_hdd to t_paciente) using the unique keys of "hdd" and "AccessFilePath."

```
LEFT JOIN
(SELECT nid, AccessFilePath, max(cast(datatarv as date)) as MaxOfdatatarv, max(cast(dataproxima as date)) as MaxOfdataproxima
FROM t_tarv
GROUP BY nid, AccessFilePath) t
ON p.nid = t.nid AND p.AccessFilePath = t.AccessFilePath
```
There is a lot going on in the next LEFT JOIN statement, but hopefully by now you understand what's going on! The next table I want to invite to the party is t_tarv. Again, I don't need all of the information inside of t_tarv because there's ~32 million observations! I select only the variables and observations I'm interested in - "nid", "AccessFilePath", "datatarv", and "dataproxima". I also don't need all of the dates, just the most recent ones. Remember earlier I mentioned that in order to work with the date variables inside the tables of MozART, you first need to change them to actual date variables using `cast()`. After changing "datatarv" and "dataproxima" to dates, you can then use `max()` to find the most recent date of each nid. `GROUP BY` ensures that SQL finds the most recent date for each nid and not the entire column (all nids)! I then assign this subset to the alias "t".

Finally, I left join the t_tarv subset to the growing t_paciente table using the "nid" and "AccessFilePath".

The rest of the SQL query is much of the same.

### Retention Flow Chart Coding
```
CTE1 AS
( 
	SELECT *, 
	CASE WHEN ((datasaidatarv < Max_datatarv) OR (datasaidatarv IS NULL) OR (datasaidatarv < Max_dataseguimento) OR(datasaidatarv > Outcome_Date)) AND 
	((Max_datatarv > dateadd(dd,-90,Outcome_Date) AND Max_datatarv <= Outcome_Date) OR (Max_dataproxima > dateadd(dd,-60,Outcome_Date) AND Max_dataproxima <= Outcome_Date) OR (Max_dataseguimento > dateadd(dd, -90, Outcome_Date) AND Max_dataseguimento <= Outcome_Date)) THEN 'Retained'
	Else 'Not Retained'
	END AS [Retained_Status]
	FROM CTE0
),
CTE2 AS
( 
	SELECT *, CASE WHEN Retained_Status = 'Not Retained' AND ((codestado = 'ABANDONO') OR (codestado IS NULL) AND (datasaidatarv < Outcome_Date)) THEN 'LTFU'
	WHEN Retained_Status = 'Not Retained' AND ((codestado = 'TRANSFERIDO PARA') AND (datasaidatarv < Outcome_Date)) THEN 'Transferred Out'
	WHEN Retained_Status = 'Not Retained' AND ((codestado = 'OBITOU') AND (datasaidatarv < Outcome_Date)) THEN 'Dead'
	WHEN Retained_Status = 'Not Retained' AND ((codestado IS NULL)) THEN 'LTFU'
	WHEN Retained_Status = 'Retained' Then 'Retained'
	END AS [Outcome]
	FROM CTE1)
```
This is the working query based on the APR 2019 revised retention definitions.


## Querying in R

The R code would follow the same logic as the SQL query.

### Required Libraries
```
library(odbc)
library(tidyverse)
```
These are the main libraries for the R retention script.

### MozART Connection
```
connect_MozART <- DBI::dbConnect(odbc::odbc(),
                                 Driver   = "ODBC Driver 13 for SQL Server",
                                 Server   = "SERVER NAME",
                                 Database = "Mozart",
                                 trusted_connection= "yes",
                                 Port     = 0000)
```
In order to connect to MozART, you must be on the CDC network and approved for access. Once approved, you can use the code above to form a connection with MozART. I've ommitted the server name and port number for security.

*Note: Your driver may be different! Check your computer's registry for the name of your SQL Server Driver*

### R/SQL Queries
```
t_patiente <- dbGetQuery(connect_MozART, "SELECT nid, sexo, idade, hdd, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
FROM t_paciente")

t_hdd <- dbGetQuery(connect_MozART, "SELECT HdD as hdd, Provincia, Distrito, designacao, local, AccessFilePath
FROM t_hdd")

t_tarv <- dbGetQuery(connect_MozART, "SELECT nid, AccessFilePath, max(cast(datatarv as date)) as MaxOfdatatarv, max(cast(dataproxima as date)) as MaxOfdataproxima
FROM t_tarv
GROUP BY nid, AccessFilePath")

t_seguimento <- dbGetQuery(connect_MozART, "SELECT nid, Gravidez, AccessFilePath, max(cast(dataseguimento as date)) as MaxOfdataseguimento, max(cast(dataproximaconsulta as date)) as MaxOfdataproximaconsulta
FROM t_seguimento
GROUP BY nid, Gravidez, AccessFilePath")

t_gaac <- dbGetQuery(connect_MozART, "SELECT gaa.nid, cast(ga.datainicio as date) as datainicio, ga.AccessFilePath
FROM t_gaac_actividades gaa
LEFT JOIN
t_gaac ga
ON gaa.numGAAC = ga.numGAAC AND gaa.AccessFilePath = ga.AccessFilePath")
```
These statements are simple SQL query pulling MozART table subsets into the R environment as dataframes.

### R Wrangling
```
patiente_hdd <- left_join(t_patiente, t_hdd, by = c("hdd", "AccessFilePath"))

patiente_hdd_tarv <- left_join(patiente_hdd, t_tarv, by = c("nid", "AccessFilePath"))

patiente_hdd_tarv_seguimento <- left_join(patiente_hdd_tarv, t_seguimento, by = c("nid", "AccessFilePath"))

patiente_hdd_tarv_seguimento_gaac <- left_join(patiente_hdd_tarv_seguimento, t_gaac, by = c("nid", "AccessFilePath"))
```
Here, I perform left joins to the patient table as above.

### Retention Outcome Coding
Outcomes will follow the same conditional statements as the SQL query.

===

Disclaimer: The findings, interpretation, and conclusions expressed herein are those of the authors and do not necessarily reflect the views of United States Agency for International Development, Centers for Disease Control and Prevention, Department of State, Department of Defense, Peace Corps, or the United States Government. All errors remain our own.
