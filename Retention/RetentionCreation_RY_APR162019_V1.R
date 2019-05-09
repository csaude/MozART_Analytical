#---- =========================================================================================================
#---- WORKING R CODE WITH SQL QUERIES FOR RETENTION DATASET PRODUCTION
#---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
#---- AUTHOR: RANDY YEE (CDC/GDIT)
#---- DATE: 4/16/2019
#---- =========================================================================================================


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ============= LOAD REQUIRED LIBRARIES ~~~~~~~==============
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#install.packages(odbc)
#install.packages(tidyverse)

library(odbc)
library(tidyverse)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ============= SQL CONNECTION ~~~~~~~==============
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Creating connection object
# NOTE: Your driver may be different! Check your computer's registry for SQL Server Driver
connect_MozART <- DBI::dbConnect(odbc::odbc(),
                                 Driver   = "ODBC Driver 13 for SQL Server",
                                 Server   = "SERVER NAME",
                                 Database = "Mozart",
                                 trusted_connection= "yes",
                                 Port     = 0000)



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ============= R/SQL QUERIES ~~~~~~~==============
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Using queries to pull in required variables for the retention dataset into R dataframes
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



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ============= R WRANGLING ~~~~~~~==============
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Left joins on unique keys (nid, hdd, AccessFilePath)
patiente_hdd <- left_join(t_patiente, t_hdd, by = c("hdd", "AccessFilePath"))

patiente_hdd_tarv <- left_join(patiente_hdd, t_tarv, by = c("nid", "AccessFilePath"))

patiente_hdd_tarv_seguimento <- left_join(patiente_hdd_tarv, t_seguimento, by = c("nid", "AccessFilePath"))

patiente_hdd_tarv_seguimento_gaac <- left_join(patiente_hdd_tarv_seguimento, t_gaac, by = c("nid", "AccessFilePath"))


# Defining the cohort range
patiente_hdd_tarv_seguimento_gaac[,"datainiciotarv"] <- as.Date(patiente_hdd_tarv_seguimento_gaac$datainiciotarv)
retention_cohort_2019 <- patiente_hdd_tarv_seguimento_gaac %>% filter(datainiciotarv >= 2012-01-01)
retention_cohort_2019 <- patiente_hdd_tarv_seguimento_gaac %>% mutate("Transferred Out" = (codestado == "TRANSFERIDO PARA"))
