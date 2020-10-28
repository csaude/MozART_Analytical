-----------Regimen Counts Using Summary View-----------------------------------------------------------------
----Query created by: Marcela Torres based on Randy Yee's summary view query
----Added agebands
----Execute Drop view lines first then create view
----Extracts 
-------------------------------------------------------------------------------------------------


DROP VIEW IF EXISTS [dbo].[v_SummaryQ1FY20];
GO

CREATE View  v_SummaryQ1FY20
AS
SELECT distinct a.nid as NID,

           a.hdd,
           aa.Provincia as Province,
           aa.distrito as District,
           aa.designacao as Health_Facility,

            convert(varchar(10), a.datanasc, 101) AS Birth_Date,
				CASE WHEN datediff(yy,datanasc,'2019-12-30') BETWEEN  0 AND 4 THEN '0-4'
				WHEN datediff(yy,datanasc,'2019-12-30')	 BETWEEN  5 AND 9 THEN '5-9'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  10 AND 14 THEN '10-14'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  15 AND 19 THEN '15-19'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  20 AND 24 THEN '20-24'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  25 AND 29 THEN '25-29'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  30 AND 34 THEN '30-34'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  35 AND 39 THEN '35-39'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  40 AND 44 THEN '40-44'
				WHEN datediff(yy,datanasc,'2019-12-30')  BETWEEN  45 AND 49 THEN '45-49'
				WHEN datediff(yy,datanasc,'2019-12-30')  >50 THEN '50+'
				END AS CurrentAgeBand,
            a.sexo AS Sex,
            convert(varchar(10), a.datadiagnostico, 101) AS Diagnosis_Date,
            year(datadiagnostico) AS Diagnosis_Year,
            a.codproveniencia AS Patient_Origin,
            convert(varchar(10), a.dataabertura, 101) AS Enrollment_Date,
            year(a.dataabertura) AS Enrollment_Year,
           a.idade AS Enrollment_Age,
           a.meses AS Enrollment_Months,
            datediff(day, a.datadiagnostico, a.dataabertura) AS Diagnosis_to_Care,
            convert(varchar(10), a.datainiciotarv, 101) AS ART_Initiation_Date,   
            year(datainiciotarv) AS ART_Initiation_Year,
            convert(varchar(10), a.datasaidatarv, 101) AS Exit_Date,
           a.codestado AS Exit_Status,

 
            b.gravida AS Gravida,
            b.codestadocivil AS Civil_Status,
            b.nrfilhos AS Number_Children,
            b.codnivel AS Academic_Level,
            b.codprofissao AS Occupation,

            convert(varchar(10), f.datatarv, 101) AS First_Drug_Pickup_Date,
            year(f.datatarv) AS First_Drug_Pickup_Year,
            f.codregime AS First_Regimen,
            f.tipotarv AS First_Drug_Pickup_Type,      
            convert(varchar(10), g.max_datatarv, 101) AS Last_Drug_Pickup_Date,
           convert(varchar(10), g.dataproxima_l, 101) AS Next_Drug_Pickup_Date,
           g.codregime_l AS Last_Regimen,
            g.tipotarv_l AS Last_Drug_Pickup_Type,
           datediff(dd, convert(varchar(10), g.max_datatarv, 101), convert(varchar(10), f.datatarv, 101)) AS Time_on_ART_Days,

            convert(varchar(10), h.max_dataseguimento, 101) AS Last_Consultation_Date,
            convert(varchar(10), h.dataproximaconsulta_l, 101) AS Next_Consultation_Date,

           ii.resultado AS First_Viral_Result,
           CASE WHEN ii.resultado < 1000 THEN 'SUPPRESSED'
                     WHEN ii.resultado >= 1000 THEN 'NOT SUPPRESSED'
                     ELSE NULL
                     END AS First_Viral_Load,
            convert(varchar(10), ii.dataresultado, 101) AS First_Viral_Load_Date, 
           i.resultado AS Recent_Viral_Result,
           CASE WHEN i.resultado < 1000 THEN 'SUPPRESSED'
                     WHEN i.resultado >= 1000 THEN 'NOT SUPPRESSED'
                     ELSE NULL
                     END AS Recent_Viral_Load,
            convert(varchar(10), i.dataresultado, 101) AS Recent_Viral_Load_Date, 

            k.codparametro AS PCR,
            convert(varchar(10), k.dataresultado, 101) AS PCR_Date,    

            convert(varchar(10), l.datainscricao, 101) AS GAAC_Enrollment_Date,
            convert(varchar(10), l.datasaida, 101) AS GAAC_Exit_Date,
            l.motivo AS Reason_Left_GAAC,
            l.numGAAC AS numGAAC,        
            convert(varchar(10), o.min_datainicio, 101) AS GAAC_Creation_Date,   
            m.afinidade AS GAAC_Creation_Reason,

           a.AccessFilePath

 FROM
         -- A) PATIENT
         [t_paciente] a


         -- AA) GEOGRAPHIC
         LEFT JOIN
         [t_hdd] aa
         ON a.hdd = aa.HdD

      -- B) ADULT
         left join
         [t_adulto] b
         ON a.nid = b.nid and a.AccessFilePath = b.AccessFilePath

      -- C) CHILD
         left join
         [t_crianca] c
         ON a.nid = c.nid and a.AccessFilePath = c.AccessFilePath

      -- F) ART START INFO                                               
      left join
         (
                SELECT AccessFilePath, nid, datatarv, codregime, tipotarv
                FROM [t_tarv]
                where tipotarv = 'Inicia'
         ) AS F
         ON A.nid = F.nid and A.AccessFilePath = F.AccessFilePath

       -- G) ART MOST RECENT INFO

      left join
         (
              SELECT a1.AccessFilePath, a1.nid, b1.codregime AS codregime_l, b1.tipotarv AS tipotarv_l, b1.dataproxima AS dataproxima_l, b1.datatarv AS datatarv_l, a1.max_datatarv
              FROM
        (
                     SELECT AccessFilePath, nid, max(convert(datetime, datatarv, 101)) AS max_datatarv
                     FROM [t_tarv]
                     where convert(datetime, datatarv) < getdate()
                     group by AccessFilePath, nid
              ) a1
              left join
              t_tarv b1 on a1.nid=b1.nid and a1.max_datatarv=b1.datatarv and a1.AccessFilePath = b1.AccessFilePath
         ) AS g
         ON a.nid = g.nid and a.AccessFilePath = g.AccessFilePath

      -- H) CONSULTATION MOST RECENT DATE
         left join
         (
                SELECT a2.AccessFilePath, a2.nid, b2.dataseguimento AS dataseguimento_l, b2.dataproximaconsulta AS dataproximaconsulta_l, a2.max_dataseguimento
                FROM
                (
                     SELECT AccessFilePath, nid, max(convert(datetime2, dataseguimento, 101)) AS max_dataseguimento
                     FROM [t_seguimento]
                     where convert(datetime2, dataseguimento) < getdate()
                     group by AccessFilePath, nid
                ) a2
                left join
                [t_seguimento] b2
                on a2.nid=b2.nid and a2.max_dataseguimento=b2.dataseguimento and a2.AccessFilePath = b2.AccessFilePath
         ) AS h
         on a.nid = h.nid and a.AccessFilePath = h.AccessFilePath

         -- I) MOST RECENT VIRAL LOAD
         left join
         (
              SELECT a4.AccessFilePath, a4.nid, b4.codexame, b4.resultado, b4.dataresultado, a4.max_dataresultado
              FROM
              (
                     SELECT AccessFilePath, nid, max(convert(datetime2, dataresultado, 101)) AS max_dataresultado
                     FROM [t_resultadoslaboratorio] where convert(datetime2, dataresultado) < getdate() and codexame = 'Carga Viral'
                     group by AccessFilePath, nid
              ) a4
              left join [t_resultadoslaboratorio] b4
              on a4.nid=b4.nid and a4.max_dataresultado=b4.dataresultado and a4.AccessFilePath = b4.AccessFilePath
       ) AS i
          on a.nid = i.nid and a.AccessFilePath = i.AccessFilePath

         -- II) FIRST VIRAL LOAD
         left join
         (
              SELECT a44.AccessFilePath, a44.nid, b44.codexame, b44.resultado, b44.dataresultado, a44.min_dataresultado
              FROM
              (
                     SELECT AccessFilePath, nid, min(convert(datetime2, dataresultado, 101)) AS min_dataresultado
                     FROM [t_resultadoslaboratorio] where convert(datetime2, dataresultado) < getdate() and codexame = 'Carga Viral'
                     group by AccessFilePath, nid
              ) a44
              left join [t_resultadoslaboratorio] b44
              on a44.nid=b44.nid and a44.min_dataresultado=b44.dataresultado and a44.AccessFilePath = b44.AccessFilePath
       ) AS ii
          on a.nid = ii.nid and a.AccessFilePath = ii.AccessFilePath

         -- J) CD4

         left join
         (
              SELECT a5.AccessFilePath, a5.nid, b5.codexame, b5.resultado, b5.dataresultado, a5.max_dataresultado
              FROM
              (
                    SELECT AccessFilePath, nid, max(convert(datetime2, dataresultado, 101)) AS max_dataresultado
                     FROM [t_resultadoslaboratorio] where convert(datetime2, dataresultado) < getdate() and codexame = 'CD4' and codparametro = 'ABSOLUTO'
                     group by AccessFilePath, nid
              ) a5

              left join [t_resultadoslaboratorio] b5
              on a5.nid=b5.nid and a5.max_dataresultado=b5.dataresultado and a5.AccessFilePath = b5.AccessFilePath
       ) AS j
          on a.nid = j.nid and a.AccessFilePath = j.AccessFilePath


      -- K) PCR
         left join
         (
              SELECT a3.AccessFilePath, a3.nid, b3.codexame, b3.codparametro, b3.dataresultado, a3.max_dataresultado
              FROM
              (
                     SELECT AccessFilePath, nid, max(convert(datetime2, dataresultado, 101)) AS max_dataresultado
                     FROM [t_resultadoslaboratorio] where convert(datetime2, dataresultado) < getdate() and codexame = 'PCR' and codparametro is not null
                     group by AccessFilePath, nid
              ) a3
              left join [t_resultadoslaboratorio] b3
              on a3.nid=b3.nid and a3.max_dataresultado=b3.dataresultado and a3.AccessFilePath = b3.AccessFilePath
       ) AS k
          on a.nid = k.nid and a.AccessFilePath = k.AccessFilePath
 
          -- L) GAAC GROUP INFO
          left join [t_gaac_actividades] l
          ON a.nid = l.nid and a.AccessFilePath = l.AccessFilePath
          -- M) GAAC GROUP
          left join [t_gaac] m
          ON l.numGAAC = m.numGAAC and l.AccessFilePath = m.AccessFilePath
       -- N) GAAC CREATION INFO
       left join
          (
              SELECT AccessFilePath, min(datainscricao) AS min_datainscricao
              FROM [t_gaac_actividades] group by AccessFilePath
          ) AS n
          on a.AccessFilePath = n.AccessFilePath   
          left join
          (
              SELECT AccessFilePath, min(datainicio) AS min_datainicio
              FROM [t_gaac]
              group by AccessFilePath
          ) AS o
          on a.AccessFilePath = o.AccessFilePath       
      ;
go

 