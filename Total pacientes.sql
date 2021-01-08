Select Distinct 
a.nid
,a.AccessFilePath
,b.Provincia
,YEAR(cast(datainiciotarv AS DATE)) AS Anoinicio

FROM t_paciente a

Inner Join
	(
		SELECT HdD, Provincia,
		AccessFilePath
		FROM t_hdd
	) b

on a.hdd=b.HdD AND a.AccessFilePath=b.AccessFilePath

WHERE YEAR(cast(datainiciotarv AS DATE)) >=2015 -- and Provincia='Inhambane'
Group BY
b.Provincia
,a.datainiciotarv
,a.nid
,a.AccessFilePath