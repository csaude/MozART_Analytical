---Created by: Marcela Torres, Neha Kamat, and Randy Yee 2/10/2020 version 1
---Used the Retention_6m table and added VL and CD4 data from MozART
---Restricting to those patients who initiated treatment in 2017
---Results need to be QCed
--Adding VL and CD4 to 18M dataset - note that var names still say 12

       SELECT person.HdD, person.AccessFilePath, Province, District, Health_Facility, person.nid, Sex, DOB, Diagnosis_Date, Initiation_Age, Initiation_Date, Cohort_Year, Outcome_Date_Eighteenm,
       Exit_Date, Last_Status, Last_Drug_Pickup_Date_Eighteenm, Last_Consultation_Date_Eighteenm, Retained_Status_18m, Outcome_18m, lastVL_18m, resultVL_18m, firstcd, resultcd_18m,Next_Drug_Pickup_Date_Eighteenm,
       Next_Consultation_Date_Eighteenm
	   INTO Sandbox.dbo.Retention_18m_2017_CDVL_Final
	   FROM Sandbox.dbo.Retention_18m_2017_FinalM person

       ---joining latest VL results
              LEFT JOIN
       (SELECT * FROM(
       SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.datavl desc) as rownum, nts.nid, nts.AccessFilePath
       , nts.datavl as lastVL_18m, nts.resultado as resultVL_18m
       FROM 
              (
              SELECT ts.nid, ts.AccessFilePath, cast(dataresultado as date) as datavl, codexame, resultado
              FROM MozART_q3_2019_Clean.dbo.t_resultadoslaboratorio  ts 
              LEFT JOIN
              (SELECT nid, AccessFilePath, cast(datainiciotarv as date) Iniciotarv
              FROM MozART_q3_2019_Clean.dbo.t_paciente) tpo1
              ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
              WHERE cast(dataresultado AS date) <= dateadd(mm,18,tpo1.Iniciotarv)  AND codexame='Carga Viral'
              ) nts
       ) s
       WHERE s.rownum = '1') ss1
       ON person.nid = ss1.nid AND person.AccessFilePath = ss1.AccessFilePath
       
       ---joining latest CD4 results
              LEFT JOIN
       (SELECT * FROM(
       SELECT ROW_NUMBER() OVER (PARTITION BY nts.nid, nts.AccessFilePath ORDER BY nts.datacd asc) as rownum, nts.nid, nts.AccessFilePath
       , nts.datacd as firstcd, nts.resultado as resultcd_18m
       FROM 
              (
              SELECT ts.nid, ts.AccessFilePath, cast(dataresultado as date) as datacd, codexame, resultado
              FROM MozART_q3_2019_Clean.dbo.t_resultadoslaboratorio  ts
              LEFT JOIN
              (SELECT nid, AccessFilePath, cast(datainiciotarv as date) Iniciotarv
              FROM MozART_q3_2019_Clean.dbo.t_paciente) tpo1
              ON ts.nid = tpo1.nid AND ts.AccessFilePath = tpo1.AccessFilePath
              WHERE codexame='CD4'
              ) nts
       ) s
       WHERE s.rownum = '1') ss2
       ON person.nid = ss2.nid AND person.AccessFilePath = ss2.AccessFilePath
      --- WHERE Cohort_Year = '2017'

       


