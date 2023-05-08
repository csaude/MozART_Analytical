library(rstudioapi)
library(dplyr)
library(odbc)
library(DBI)
library(RODBC)

con <- dbConnect(odbc(),
                 Driver = "MySQL ODBC 8.0 ANSI Driver",
                 Server = "160.242.33.26",
                 Database = "Mozart2",
                 UID = rstudioapi::askForPassword("Please Enter Username"),
                 PWD = rstudioapi::askForPassword("Please Enter Password"),
                 Port = 49760,
                 MULTI_HOST = 1)

---------------------------------------------------------------------------------------------------------------
Medication_Named <- dbReadTable(con, "medication")
Type_id_lookup <- dbReadTable(con, "type_id_lookup")

as.numeric(Type_id_lookup$id_type_lookup) 

Regimen <- subset(Type_id_lookup, column_name == "REGIMEN_ID", select =
                    -c(id, table_name, column_name, notes)) %>% rename(Regimen = 
                      id_type_desc, regimen_id = id_type_lookup)
Regimen$regimen_id<-as.numeric((Regimen$regimen_id))

Formulation <- subset(Type_id_lookup, column_name == "FORMULATION_ID", select =
                        -c(id, table_name, column_name, notes)) %>% rename(Formulation = 
                          id_type_desc, formulation_id = id_type_lookup)
Formulation$formulation_id<-as.numeric((Formulation$formulation_id))

Mode_dispensation <- subset(Type_id_lookup, column_name == "MODE_DISPENSATION_ID", select =
                          -c(id, table_name, column_name, notes)) %>% rename(Mode_dispensation = 
                          id_type_desc, mode_dispensation_id = id_type_lookup)
Mode_dispensation$mode_dispensation_id<-as.numeric((Mode_dispensation$mode_dispensation_id))

Med_line <-subset(Type_id_lookup, column_name == "MED_LINE_ID", select =
                          -c(id, table_name, column_name, notes)) %>% rename(Med_line = 
                          id_type_desc, med_line_id = id_type_lookup)
Med_line$med_line_id<-as.numeric((Med_line$med_line_id))

Type_dispensation <- subset(Type_id_lookup, column_name == "TYPE_DISPENSATION_ID", select =
                       -c(id, table_name, column_name, notes)) %>% rename(Type_dispensation = 
                        id_type_desc, type_dispensation_id = id_type_lookup)
Type_dispensation$type_dispensation_id<-as.numeric((Type_dispensation$type_dispensation_id))

Alternative_line <-subset(Type_id_lookup, column_name == "ALTERNATIVE_LINE_ID", select =
                            -c(id, table_name, column_name, notes)) %>% rename(Alternative_line = 
                            id_type_desc, alternative_line_id = id_type_lookup)
Alternative_line$alternative_line_id<-as.numeric((Alternative_line$alternative_line_id))

Reason_change_regimen <- subset(Type_id_lookup, column_name == "REASON_CHANGE_REGIMEN_ID", select =
                           -c(id, table_name, column_name, notes)) %>% rename(Reason_change_regimen = 
                           id_type_desc, reason_change_regimen_id = id_type_lookup)
Reason_change_regimen$reason_change_regimen_id<-as.numeric((Reason_change_regimen$reason_change_regimen_id))

Arv_side_effects <- subset(Type_id_lookup, column_name == "ARV_SIDE_EFFECT_ID", select =
                             -c(id, table_name, column_name, notes)) %>% rename(ARV_side_effects = 
                            id_type_desc, arv_side_effects_id = id_type_lookup)
Arv_side_effects$arv_side_effects_id<-as.numeric((Arv_side_effects$arv_side_effects_id))

Adherence <- subset(Type_id_lookup, column_name == "ADHERENCE_ID", select =
                      -c(id, table_name, column_name, notes)) %>% rename(Adherence = 
                          id_type_desc, adherence_id = id_type_lookup)
Adherence$adherence_id<-as.numeric((Adherence$adherence_id))


Medication_Named1 <- left_join(Medication_Named, Regimen,
                      by = "regimen_id")  

Medication_Named1 <-left_join(Medication_Named1, Formulation,
                      by = "formulation_id")  

Medication_Named1 <-left_join(Medication_Named1, Mode_dispensation,
                      by = "mode_dispensation_id") 

Medication_Named1 <-left_join(Medication_Named1, Med_line,
                      by = "med_line_id") 

Medication_Named1 <-left_join(Medication_Named1, Type_dispensation,
                      by = "type_dispensation_id") 
                      
Medication_Named1 <-left_join(Medication_Named1, Alternative_line,
                      by = "alternative_line_id")
                      
Medication_Named1 <-left_join(Medication_Named1, Reason_change_regimen, 
                      by = "reason_change_regimen_id") 

Medication_Named1 <-left_join(Medication_Named1, Arv_side_effects,
                      by = "arv_side_effects_id")

Medication_Named1 <-left_join(Medication_Named1, Adherence, 
                      by = "adherence_id")
-----------------------------------------------------------------------------------






