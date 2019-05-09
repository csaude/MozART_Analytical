---- =========================================================================================================
---- WORKING SQL QUERY FOR RETENTION DATASET PRODUCTION
---- BASED ON CDC MOZAMBIQUE RETENTION DATA TEMPLATE
---- AUTHOR: RANDY YEE (CDC/GDIT)
---- DATE: 4/16/2019
---- =========================================================================================================

/******************** "Data Mart" Step ********************/
SELECT f.HdD, f.Provincia, f.Distrito, f.designacao, f.local,
p.nid, p.sexo, p.idade, p.datainiciotarv, Outcome_Date = dateadd(yy, 1, datainiciotarv), p.datadiagnostico, p.datasaidatarv, p.codestado,
t.MaxOfdatatarv, t.MaxOfdataproxima,
s.MaxOfdataseguimento, s.MaxOfdataproximaconsulta, gg.datainicio as DatainicioGAAC, s.Gravidez,
p.AccessFilePath as Caminho
INTO Sandbox.dbo.retention_cohort_2012_2019
FROM
(SELECT nid, sexo, idade, hdd, cast(datainiciotarv as date) as datainiciotarv, cast(datadiagnostico as date) as datadiagnostico, codestado, cast(datasaidatarv as date) as datasaidatarv, AccessFilePath
FROM t_paciente) p
LEFT JOIN
(SELECT HdD, Provincia, Distrito, designacao, local, AccessFilePath
FROM t_hdd) f
ON p.hdd = f.HdD AND p.AccessFilePath = f.AccessFilePath
LEFT JOIN
(SELECT nid, AccessFilePath, max(cast(datatarv as date)) as MaxOfdatatarv, max(cast(dataproxima as date)) as MaxOfdataproxima
FROM t_tarv
GROUP BY nid, AccessFilePath) t
ON p.nid = t.nid AND p.AccessFilePath = t.AccessFilePath
LEFT JOIN
(SELECT nid, Gravidez, AccessFilePath, max(cast(dataseguimento as date)) as MaxOfdataseguimento, max(cast(dataproximaconsulta as date)) as MaxOfdataproximaconsulta
FROM t_seguimento
GROUP BY nid, Gravidez, AccessFilePath) s
ON p.nid = s.nid AND p.AccessFilePath = s.AccessFilePath
LEFT JOIN
(SELECT gaa.nid, cast(ga.datainicio as date) as datainicio, ga.AccessFilePath
FROM t_gaac_actividades gaa
LEFT JOIN
t_gaac ga
ON gaa.numGAAC = ga.numGAAC AND gaa.AccessFilePath = ga.AccessFilePath) gg
ON p.nid = gg.nid AND p.AccessFilePath = gg.AccessFilePath
ORDER BY nid

/******************** Retention Flow Chart Coding  -  TODO: QC ********************/
SELECT *,
Outcome = CASE WHEN ((datasaidatarv < MaxOfdataproxima) OR (datasaidatarv IS NULL) OR (datasaidatarv < MaxOfdataseguimento)) AND ((MaxOfdatatarv < dateadd(dd,90,datainiciotarv)) OR (MaxOfdataproxima < dateadd(dd,60,datainiciotarv)) OR (MaxOfdataseguimento < dateadd(dd, 90, datainiciotarv))) THEN 'Retained'
WHEN ((codestado = 'ABANDONO') OR (codestado IS NULL) OR (MaxOfdataproximaconsulta > dateadd(mm, 10, datainiciotarv))) THEN 'LTFU'
WHEN ((codestado = 'TRANSFERIDO PARA') AND (datasaidatarv < Outcome_Date)) THEN 'Transferred Out'
WHEN ((codestado = 'OBITOU') AND (datasaidatarv < Outcome_Date)) THEN 'Dead'
end
INTO Sandbox.dbo.retention_cohort_2012_2019_final
FROM Sandbox.dbo.retention_cohort_2012_2019
WHERE datainiciotarv >= '2012'
ORDER BY datainiciotarv asc

/******************** Retention Counts ********************/
SELECT Outcome, count(*) as Count
FROM Sandbox.dbo.retention_cohort_2012_2019_final
GROUP BY Outcome
