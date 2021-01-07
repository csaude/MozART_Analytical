clear all
cd "L:\INS\First buletin"   /*change this folder link to the current month folder*/


	****** 1
clear all
import delimited viral_load_age_interval.csv, delimiters(",")

rename v5 testnaosuprimidos
rename v6 testsuprimidos

save viral_load_age_interval, replace

sort ano

by ano: summarize testsuprimidos, detail


	

************************************************************
clear
use t_enrolled_3MDD_patient

egen m3temp = sum(enrol3mo), by(facilityname)
egen m6temp = sum(enrol6mo), by(facilityname)

bysort facilityname: gen keep = _n
	keep if keep==1
		replace enrol3mo = m3temp
		replace enrol6mo = m6temp

			drop m3temp m6temp keep
			
			keep provincia distrito hdd facilityname enrol6mo enrol3mo
			
			rename facilityname facility
			sort facility

save t_enrolled_3MDD_facility, replace


****export excel
export excel using "L:\Queries\3mdd\Enrolled in 3MDD\t_enrolled_3MDD_facility.xlsx", sheetreplace firstrow(variables)


*******joining elegible and enrolled**********

clear all
cd "L:\Queries\3mdd\Elegible for DSD"

use 3MDD_HF
gen helper=provincia+distrito+facility

cd "L:\Queries\3mdd\Enrolled in 3MDD" 

save 3MDD_HF, replace



clear all

cd "L:\Queries\3mdd\Enrolled in 3MDD"   /*change this folder link to the current month folder*/ /****had to mannually copy 3MDD_HF to this folder****/

use t_enrolled_3MDD_facility

gen helper=provincia+distrito+facility



merge 1:1 helper using 3MDD_HF, force

drop _merge helper

sort hdd

save 3MDD_eleg_enrol, replace

******************************
clear all

use 3MDD_eleg_enrol


export excel using "L:\Queries\3mdd\Enrolled in 3MDD\3MDD_eleg_enrol.xlsx", sheetreplace firstrow(variables)





