#Title: MozART MySQL Connection Script
#Author: Josh Fortmann
#Original Date of Authorship: 4/19/2023
#Contact information: Rzy8@cdc.gov

#Please make sure that the following packages are installed in R before running the script

#Also make sure that an appropriate driver has been installed on your computer (see troubleshooting notes for how to check this)
library(rstudioapi)
library(dplyr)
library(odbc)
library(DBI)
library(RODBC)
#This section of code will establish an active connection to the MozART server. Please check with the HIS lead in order to be certain that you
#Have the most up to date server and port information. You will be prompted to enter your username and password that should have been provided to you
#after signing the MozART NDA

con <- dbConnect(odbc(),
                 Driver = "MySQL ODBC 8.0 ANSI Driver",
                 Server = "160.242.33.26",
                 Database = "Mozart2",
                 UID = rstudioapi::askForPassword("Please Enter Username"),
                 PWD = rstudioapi::askForPassword("Please Enter Password"),
                 Port = 49760,
                 MULTI_HOST = 1)
--------------------------------------------------------------------------------------------
  

  
--------------------------------------------------------------------------------------------
  #Whenever you are finished with a work session please use the following code to clear your environment and 
  #disconnect from the server. Remember that downloading/saving patient level data onto your computer and/or maintaining
  #an open connection to MozART when it is not in use are violations of CDC data security policy. Failure to abide by this
  #policy may result in the loss of your credentials for MozART use and possible disciplinary action.
  
  #This command halts the active connection to the MozART server
dbDisconnect(con)
  
#Please note that this command will remove everything currently in your environment. Make sure that any Non-Mozart data/work
#is properly saved before executing
rm(list=ls())
  
  
--------------------------------------------------------------------------------------------
  #Useful Common Commands 
  
  #This command will return a full list of tables available through your connection, change database as needed
  
  Example_Table_List_Mozart2 <- dbListTables(con, "Mozart2")
  list(Example_Table_List_Mozart2)
  
  #This command will return all of the columns (variables) in a specific table (note that the full dbo namepath is not used like
  # it would be in a SQL query)

  Example_columns_medication <- dbListcolumns(con, "medication")
  list(Example_Fields_observation)
  
  #This command allows you to read an entire table from the SQL server into an R dataframe. PLEASE CLEAR THESE TABLES AFTER THE WORK
  #SESSION AND DO NOT SAVE THEM ANYWHERE ON YOUR COMPUTER IN ACCORDANCE WITH CDC POLICY
  
  Example_Table_Medication <- dbReadTable(con, "medication")
  
  #Generates a quick view and summary of your imported table 
  
  tibble::as_tibble(Example_Table_Medication)
  
  #If you have some familiarity with SQL Syntax it is also possible to submit queries formatted in SQL language through R
  #Since many of the tables are very large, it might be faster/easier on your system resources to bring tables in with some restrictions
  #versus importing the entire table like we did with dbReadTable command
  
  #In order to generate an identical table to our Example_Table_Medication we can use the following code:
  
  Example_Table_Medication_SQL <- dbGetQuery(con, "Select * from Mozart2.dbo.medication" )
  
  #If for example, we only wanted to pull observations with a specific regimen (1651 aka AZT+3TC+NVP) we could use the following code
  
  Example_Table_Medication_SQL_Regimine <- dbGetQuery(con, "Select * from Mozart2.dbo.medication 
                                                            Where regimen_id = 1651" )
  
  #Longer, more complicated queries can be submitted using this operation, however they get progressively more difficult to proofread
  #when written outside of a native SQL environment. The author of this code would suggest using either simple queries or queries that have
  #been proven to work in a different environment 

--------------------------------------------------------------------------------------------
  #Troubleshooting: Common Issues/Errors and Solutions 
  
  #If the system returns an error about Data source name not being found please use
  #the below command to determine if the driver you are attempting to use is installed
  #on your computer (also be certain that you are using the correct driver for the server type)
  
  odbcListDrivers()
  
  #If the system returns an error stating the login failed for user 'your_username' then please check your credentials
  
  #If the system returns an error stating Invalid connection string attribute, please check that the server and port are
  #correctly written and up to date
  
  #If the system returns an error stating that the wait operation timed out, please make sure that your network connection is
  #working. Alternatively check with the management team to verify that the server firewall is configured for access through
  #this medium and from your IP address/computer
  