---- =========================================================================================================
---- WORKING SQL QUERY FOR TX_CURR COMBINED MATRIX PRODUCTION
---- AUTHOR: RANDY YEE (CDC/GDIT) BASED ON WORK BY Mala (CDC/GDIT) and Timoteo (CDC-MOZ)
---- CREATION DATE: 9/12/2019
---- CRITERIA:
---- 1) Initiation date assessed for each month period
---- 2) Any drug pickup, scheduled drug pickup, consultation during the month period will be defined as 'Activity'
---- =========================================================================================================

DECLARE @StartDate DATE;
SET @StartDate = '2018-05-21'

SELECT DISTINCT tp.hdd, tp.nid,
im.[1_Activity] as Initiation1, em.[1_Activity] as Exit1, ce.[1_Activity] as Code1, dp.[1_Activity] as DrugPickup1, cm.[1_Activity] as Consultation1, ndp.[1_Activity] as NextPickup1 ,
im.[2_Activity] as Initiation2, em.[2_Activity] as Exit2, ce.[2_Activity] as Code2, dp.[2_Activity] as DrugPickup2, cm.[2_Activity] as Consultation2, ndp.[2_Activity] as NextPickup2 ,
im.[3_Activity] as Initiation3, em.[3_Activity] as Exit3, ce.[3_Activity] as Code3, dp.[3_Activity] as DrugPickup3, cm.[3_Activity] as Consultation3, ndp.[3_Activity] as NextPickup3 ,
im.[4_Activity] as Initiation4, em.[4_Activity] as Exit4, ce.[4_Activity] as Code4, dp.[4_Activity] as DrugPickup4, cm.[4_Activity] as Consultation4, ndp.[4_Activity] as NextPickup4 ,
im.[5_Activity] as Initiation5, em.[5_Activity] as Exit5, ce.[5_Activity] as Code5, dp.[5_Activity] as DrugPickup5, cm.[5_Activity] as Consultation5, ndp.[5_Activity] as NextPickup5 ,
im.[6_Activity] as Initiation6, em.[6_Activity] as Exit6, ce.[6_Activity] as Code6, dp.[6_Activity] as DrugPickup6, cm.[6_Activity] as Consultation6, ndp.[6_Activity] as NextPickup6 ,
im.[7_Activity] as Initiation7, em.[7_Activity] as Exit7, ce.[7_Activity] as Code7, dp.[7_Activity] as DrugPickup7, cm.[7_Activity] as Consultation7, ndp.[7_Activity] as NextPickup7 ,
im.[8_Activity] as Initiation8, em.[8_Activity] as Exit8, ce.[8_Activity] as Code8, dp.[8_Activity] as DrugPickup8, cm.[8_Activity] as Consultation8, ndp.[8_Activity] as NextPickup8 ,
im.[9_Activity] as Initiation9, em.[9_Activity] as Exit9, ce.[9_Activity] as Code9, dp.[9_Activity] as DrugPickup9, cm.[9_Activity] as Consultation9, ndp.[9_Activity] as NextPickup9 ,
im.[10_Activity] as Initiation10, em.[10_Activity] as Exit10, ce.[10_Activity] as Code10, dp.[10_Activity] as DrugPickup10, cm.[10_Activity] as Consultation10, ndp.[10_Activity] as NextPickup10 ,
im.[11_Activity] as Initiation11, em.[11_Activity] as Exit11, ce.[11_Activity] as Code11, dp.[11_Activity] as DrugPickup11, cm.[11_Activity] as Consultation11, ndp.[11_Activity] as NextPickup11 ,
im.[12_Activity] as Initiation12, em.[12_Activity] as Exit12, ce.[12_Activity] as Code12, dp.[12_Activity] as DrugPickup12, cm.[12_Activity] as Consultation12, ndp.[12_Activity] as NextPickup12 ,
im.[13_Activity] as Initiation13, em.[13_Activity] as Exit13, ce.[13_Activity] as Code13, dp.[13_Activity] as DrugPickup13, cm.[13_Activity] as Consultation13, ndp.[13_Activity] as NextPickup13  

INTO Sandbox.dbo.TXC_Core_Jun18_Jun19

FROM
t_paciente tp
LEFT JOIN
Sandbox.dbo.TXC_Drug_Pickup_Matrix dp
ON
tp.nid = dp.nid
LEFT JOIN
Sandbox.dbo.TXC_Next_Drug_Pickup_Matrix ndp
ON
tp.nid = ndp.nid
LEFT JOIN
Sandbox.dbo.TXC_Consultation_Matrix cm
ON
tp.nid = cm.nid
LEFT JOIN
Sandbox.dbo.TXC_Initiation_Matrix im
ON
tp.nid = im.nid
LEFT JOIN
Sandbox.dbo.TXC_Exit_Matrix em
ON
tp.nid = em.nid
LEFT JOIN
Sandbox.dbo.TXC_Coded_Exit_Matrix ce
ON
tp.nid = ce.nid
--WHERE tp.nid = '10008143936686'