clear all
cd "S:\ESME Branch\EPI\CD4 calculations\CD4_SQL new all 2012-2018"   /*change this folder link to the current month folder*/


	****** 1
clear all
import delimited CD4_initiation_FY14.txt, delimiters(",")


drop v14

foreach var of varlist * {
    rename `var' `=`var'[1]'
}
drop in 1
destring, replace


*drop maxofdataseguimento maxofdatatarv maxofdataproxima maxofdataproximaconsult
save CD4_initiation_FY12, replace

	****** 2
clear all
import delimited t_enrolled_3MDD_2.txt, delimiters(",")

*drop maxofdataseguimento maxofdatatarv maxofdataproxima maxofdataproximaconsulta
save enrolled_3MDD_2, replace

	****** 3
clear all
import delimited t_enrolled_3MDD_3.txt, delimiters(",")

*drop maxofdataseguimento maxofdatatarv maxofdataproxima maxofdataproximaconsulta
save enrolled_3MDD_3, replace
************************************************************
clear all
use enrolled_3MDD_1

append using enrolled_3MDD_2 enrolled_3MDD_3, force

rename designacao facilityname

replace provincia="Maputo" if provincia=="" & distrito=="Matola"
replace provincia="Maputo" if provincia=="" & distrito=="CS Liberdade"
replace provincia="Zambezia" if provincia=="" & distrito=="Ile"
replace provincia="Zambezia" if provincia=="Zambézia"
replace provincia="Inhambane" if provincia=="inhambane"

drop if nid==.
	
	sort *
	quietly by * : gen dupl=cond(_N==1,0,_n)
	drop if dupl>1


save enrolled_3MDD_all_new



/*
keep provincia distrito designacao nid

sort *
quietly by * : gen dupl=cond(_N==1,0,_n)
drop if dupl>1

list * if nid=="."

*/

clear all
use enrolled_3MDD_all_new

drop caminho local

*rename designacao facilityname
sort nid facilityname


rename maxofdataseguimento consult
rename maxofdataproximaconsulta nextconsult
rename maxofdatatarv ARVpickup
rename maxofdataproxima nextpickup

***************************************************************

			replace datainiciotarv=substr(datainiciotarv,1,strpos(datainiciotarv, " ")-1)
			gen datainiciotarv2=date(datainiciotarv,"DMY")
			format datainiciotarv2 %td
			
			drop datainiciotarv
			rename  datainiciotarv2 datainiciotarv




foreach var in consult ARVpickup nextpickup nextconsult {

	replace `var'=subinstr(`var',"Jan", "1",.)
	replace `var'=subinstr(`var',"Feb", "2",.)
	replace `var'=subinstr(`var',"Mar", "3",.)
	replace `var'=subinstr(`var',"Apr", "4",.)
	replace `var'=subinstr(`var',"May", "5",.)
	replace `var'=subinstr(`var',"Jun", "6",.)
	replace `var'=subinstr(`var',"Jul", "7",.)
	replace `var'=subinstr(`var',"Aug", "8",.)
	replace `var'=subinstr(`var',"Sep", "9",.)
	replace `var'=subinstr(`var',"Oct", "10",.)
	replace `var'=subinstr(`var',"Nov", "11",.)
	replace `var'=subinstr(`var',"Dec", "12",.)
	}

		foreach var in consult ARVpickup nextpickup nextconsult {
		split `var', p("")
		}

			foreach var in consult1 ARVpickup1 nextpickup1 nextconsult1 {
			replace `var'=subinstr(`var',"-13", "-2013",.)
			replace `var'=subinstr(`var',"-14", "-2014",.)
			replace `var'=subinstr(`var',"-15", "-2015",.)
			replace `var'=subinstr(`var',"-16", "-2016",.)
			replace `var'=subinstr(`var',"-17", "-2017",.)
			replace `var'=subinstr(`var',"-18", "-2018",.)
			replace `var'=subinstr(`var',"-19", "-2019",.)
			
			}
	
	drop consult2 ARVpickup2 nextpickup2 nextconsult2 consult3 ARVpickup3 nextpickup3 nextconsult3 
	
*	drop consult ARVpickup nextpickup nextconsult
	
	gen consult2=date(consult1,"DMY")
	gen ARVpickup2=date(ARVpickup1,"DMY")
	gen nextpickup2=date(nextpickup1,"DMY")
	gen nextconsult2=date(nextconsult1,"DMY")
	format consult2 ARVpickup2 nextpickup2 nextconsult2 %td
	
	drop consult1 ARVpickup1 nextpickup1 nextconsult1
	
	sort nid
	
	by nid: egen lastconsult = max(consult2)
	
	by nid: egen lastARV = max(ARVpickup2)
	
	
	gen consultfilter =.
	replace consultfilter=1 if lastconsult==consult2
	
	gen ARVfilter=.
	replace ARVfilter=1 if lastARV==ARVpickup2
	
	drop if consultfilter!=1 | ARVfilter!=1
	
	
	save enrolled_3MDD_all_1_new, replace
	******************************************************************************
	
	clear all
	use enrolled_3MDD_all_1_new
	
	
	****** 3 months pickups ******
	gen consultTime=(nextconsult2-consult2)/(365/12)
	replace consultTime=round(consultTime,1)
		*replace consultTime=. if nextconsult2==. | consult2==.

	
	
	gen enrol6mo=.
	replace enrol6mo=1  if consultTime==6
	replace enrol6mo=0 if enrol6mo==.
	
	
	****** 6 months visits *******
	gen pickupTime=(nextpickup2-ARVpickup2)/(365/12)
	replace pickupTime=round(pickupTime,1)
		*replace pickupTime=. if nextpickup2==. | ARVpickup2==.
	
	gen enrol3mo=.
	replace enrol3mo=1 if pickupTime==3
	replace enrol3mo=0 if enrol3mo==.

	
/*	
	
	foreach var in datanasc {

	replace `var'=subinstr(`var',"Jan", "1",.)
	replace `var'=subinstr(`var',"Feb", "2",.)
	replace `var'=subinstr(`var',"Mar", "3",.)
	replace `var'=subinstr(`var',"Apr", "4",.)
	replace `var'=subinstr(`var',"May", "5",.)
	replace `var'=subinstr(`var',"Jun", "6",.)
	replace `var'=subinstr(`var',"Jul", "7",.)
	replace `var'=subinstr(`var',"Aug", "8",.)
	replace `var'=subinstr(`var',"Sep", "9",.)
	replace `var'=subinstr(`var',"Oct", "10",.)
	replace `var'=subinstr(`var',"Nov", "11",.)
	replace `var'=subinstr(`var',"Dec", "12",.)
	}


			foreach var in datanasc {
			replace `var'=subinstr(`var',"-13", "-2013",.)
			replace `var'=subinstr(`var',"-14", "-2014",.)
			replace `var'=subinstr(`var',"-15", "-2015",.)
			replace `var'=subinstr(`var',"-16", "-2016",.)
			replace `var'=subinstr(`var',"-17", "-2017",.)
			replace `var'=subinstr(`var',"-18", "-2018",.)
			replace `var'=subinstr(`var',"-19", "-2019",.)
			
			}
	
	
gen Today=date("25-Mar-2019","DMY")
gen datanasc2=date(datanasc,"DMY")

	format Today datanasc2 %td
	
	
	gen	idade2=(Today-datanasc)
	idade2=('
*/	
save enrolled_3MDD_patient_new, replace

************************************************************
clear
use enrolled_3MDD_patient_new

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

save enrolled_3MDD_HF_new, replace


****export excel
export excel using "S:\Timoteo\Mozart Queries\3MDD_repeat\Enrolled\Results\t_enrolled_3MDD_HF_new.xlsx", sheetreplace firstrow(variables)


/*******joining elegible and enrolled**********

clear all
cd "S:\Timoteo\Mozart Queries\3MDD_repeat\Elegible\Results"

use 3MDD_HF_new3
gen helper=provincia+distrito+facility

cd "S:\Timoteo\Mozart Queries\3MDD_repeat\Enrolled\Results" 

save 3MDD_HF_elegible, replace



clear all

cd "S:\Timoteo\Mozart Queries\3MDD_repeat\Enrolled\Results"   /*change this folder link to the current month folder*/ /****had to mannually copy 3MDD_HF to this folder****/

use enrolled_3MDD_HF_new

gen helper=provincia+distrito+facility



merge 1:1 helper using 3MDD_HF_elegible, force

drop _merge helper

sort hdd

save 3MDD_eleg_enrol_new, replace



********************************************/

/******************************
clear all

use 3MDD_eleg_enrol_new


export excel using "S:\Timoteo\Mozart Queries\3MDD_repeat\Enrolled\Results.xlsx", sheetreplace firstrow(variables)


************************/

clear all

use 3MDD_eleg_enrol_new

cd "L:\Queries\3mdd\Enrolled in 3MDD"

save 3MDD_eleg_enrol_new, replace


clear all 

use 3MDD_eleg_enrol

append using 3MDD_eleg_enrol_new, force

	sort helper
	quietly by helper: gen duplicate=cond(_N==1,0,_n)
	drop if duplicate>1 

	drop helper duplicate
	
	save 3MDD_eleg_enrol_final, replace


*********************************
		**********************************
				**************Elegible*******************
*merging all data.
clear all
cd "S:\Timoteo\Mozart Queries\3MDD_repeat\Elegible\Results"

use 3MDD_HF_new3

gen matcher=facility+distrito

rename elegible elegible2

cd "L:\Queries\3mdd\Elegible for DSD"

save 3MDD_HF_new3, replace


clear all

use 3MDD_HF

gen matcher=facility+distrito
	merge m:m matcher using 3MDD_HF_new3, force

replace elegible=elegible2 if _merge==2

replace elegible=elegible2 if _merge==3 & elegible<elegible2


sort *
	quietly by *: gen duplicate=cond(_N==1,0,_n)
		drop if duplicate>1
		drop elegible2 _merge duplicate

save 3MDD_HF_final, replace


***************************Enrolled******************************
clear all

cd "S:\Timoteo\Mozart Queries\3MDD_repeat\Enrolled\Results"

use enrolled_3MDD_HF_new

gen matcher=facility+distrito

	rename enrol6mo enrol6mo_2 
	rename enrol3mo enrol3mo_2
	
	
cd "L:\Queries\3mdd\Enrolled in 3MDD"
	save  enrolled_3MDD_HF_new, replace

clear all
use t_enrolled_3MDD_facility

gen matcher=facility+distrito
	merge m:m matcher using enrolled_3MDD_HF_new, force

	replace enrol6mo=enrol6mo_2 if _merge==2
	replace enrol3mo=enrol3mo_2 if _merge==2
	
		replace enrol6mo=enrol6mo_2 if _merge==3 & enrol6mo<enrol6mo_2
		replace enrol3mo=enrol3mo_2 if _merge==3 & enrol3mo<enrol3mo_2

			sort *
			quietly by *:gen dup=cond(_N==1,0,_n)
			drop if dup>1
			
			drop  enrol6mo_2 enrol3mo_2 dup _merge
			
save enrolled_3MDD_final, replace

**************************************************************************
	********************Join elegible and enrolled*******************
	
clear all
cd "L:\Queries\3mdd\Elegible for DSD"
	use 3MDD_HF_final
		cd "L:\Queries\3mdd\Enrolled in 3MDD"
			save 3MDD_HF_final, replace
			
clear all
	use enrolled_3MDD_final
		merge m:m matcher using 3MDD_HF_final, force
			
			sort *
			quietly by *:gen dup=cond(_N==1,0,_n)
			drop if dup>1
				drop dup matcher _merge

save el_enr_all_final, replace

export excel using "L:\Queries\3mdd\el_enr_all_final.xlsx", sheetreplace firstrow(variables)
				
				







