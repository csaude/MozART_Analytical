select Provincia, Distrito, designacao
, pa.hdd, pa.nid
, sexo as gender
, datediff(yy,pa.datanasc,bu.date_LTFU) as Age
, cast(datainiciotarv as DATE) as ARTinitiationDate
, datediff(mm,pa.datainiciotarv,bu.date_LTFU) as timeARTtoLTU
, date_LTFU, Year_LTFU
, Quarter_LTFU
, CASE	WHEN codmotivoabandono='DISTANCIA/DINHEIRO TRANSPORTE' THEN 'Distance/Transportation Cost'
		WHEN codmotivoabandono='ESTA ACAMADO EM CASA' THEN 'Bedridden at Home'
		WHEN codmotivoabandono='PROBLEMAS FAMILIARES' THEN 'Family Issues'
		WHEN codmotivoabandono='INSATISFACCAO COM SERVICO NO HDD' THEN 'Unsatisfied with HF Services'
		WHEN codmotivoabandono='DESMOTIVACAO' THEN 'No Motivation'
		WHEN codmotivoabandono='TRATAMENTO TRADICIONAL' THEN 'Taking Traditional Medication'
		WHEN codmotivoabandono='ESQUECEU A DATA' THEN 'Forgot the Date'
		WHEN codmotivoabandono='PROBLEMAS DE ALIMENTACAO' THEN 'Lack of Food'
		WHEN codmotivoabandono='EFEITOS SECUNDARIOS ARV' THEN 'Side Effects of ARVs'
		WHEN codmotivoabandono='TRABALHO' THEN 'Work'
		WHEN codmotivoabandono='OUTRO' THEN 'Other'
		WHEN codmotivoabandono='VIAJOU' THEN 'Travel'
		WHEN codmotivoabandono is null THEN 'No reason Specified'

		END AS LTUreason
, codreferencia AS LTFUmoreinfo
, pa.AccessFilePath

Into Sandbox.dbo.LTFUreasons
From t_paciente pa

INNER JOIN
(
Select
nid, codmotivoabandono, codreferencia, AccessFilePath
, cast(datacomecoufaltar as date) AS date_LTFU
, datepart(yy,cast(datacomecoufaltar AS DATE)) AS Year_LTFU

,	/*------FY19------*/
	CASE	
			WHEN cast(datacomecoufaltar AS DATE) between '2018-09-21' AND '2018-12-20' THEN 1
			WHEN cast(datacomecoufaltar AS DATE) between '2018-12-21' AND '2019-03-20' THEN 2
			WHEN cast(datacomecoufaltar AS DATE) between '2019-03-21' AND '2019-06-20' THEN 3
			WHEN cast(datacomecoufaltar AS DATE) between '2019-06-21' AND '2019-09-20' THEN 4
	/*------FY18------*/
			WHEN cast(datacomecoufaltar AS DATE) between '2017-09-21' AND '2017-12-20' THEN 1
			WHEN cast(datacomecoufaltar AS DATE) between '2017-12-21' AND '2018-03-20' THEN 2
			WHEN cast(datacomecoufaltar AS DATE) between '2018-03-21' AND '2018-06-20' THEN 3
			WHEN cast(datacomecoufaltar AS DATE) between '2018-06-21' AND '2018-09-20' THEN 4
	END AS Quarter_LTFU

from t_buscaactiva
Where cast(datacomecoufaltar AS DATE) between '2017-09-21' AND '2019-09-20'
) bu
on pa.nid=bu.nid AND pa.AccessFilepath=bu.AccessFilePath

LEFT JOIN
t_hdd hd
on pa.hdd=hd.HdD AND pa.AccessFilePath=hd.AccessFilePath


