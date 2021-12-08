* Christian Rasmussen

* data assigment 3

* NYT github data 


import delimited "C:\Users\raz44\Downloads\data assignment 3\us-counties-2020 - Copy.csv",clear

generate fips = substr(geoid,5,5)

destring fips, replace

collapse (sum) cases deaths, by(county fips)

save 2020Covid.dta, replace


* Census Data

import delimited "C:\Users\raz44\Downloads\data assignment 3\DECENNIALPL2020.P1_data_with_overlays_2021-11-16T083211.csv", clear

rename v1 id

rename v2 county

rename v3 totalPop

rename v5 white

rename v6 black
keep id county totalPop white black
drop if _n<3
generate fips = substr(id,10,5)
destring fips, replace
destring white black, replace 
destring totalPop, replace
generate whitePop=(white/totalPop)*100
generate blackPop = (black/totalPop)*100

save census.dta, replace

* crosswalk --Zip County Data

import delimited "C:\Users\raz44\Downloads\data assignment 3\ZIP_COUNTY_092021.csv", clear


rename ïzip fips

replace fips = floor(county/100)

save crossWalk.dta, replace 



* HPI Data 2021


import delimited "C:\Users\raz44\Downloads\data assignment 3\HPI_AT_3zip (1).csv", clear

drop if _n <7

split v1, parse(",")

drop v1

rename v11 fips

rename v12 year

rename v13 quarter

rename v14 index21

rename v15 type

keep fips year quarter index

destring fips year quarter index21, replace force



keep if year == 2021 

keep if quarter == 3

drop quarter year 

collapse (mean) index21, by (fips)

save NPI21.dta, replace

* HPI Data 2020 


import delimited "C:\Users\raz44\Downloads\data assignment 3\HPI_AT_3zip (1).csv", clear

drop if _n <7

split v1, parse(",")

rename v11 fips

rename v12 year

rename v13 quarter

rename v14 index20

rename v15 type

keep fips year quarter index

destring fips year quarter index20, replace force

keep if year == 2020 

keep if quarter == 3

drop quarter year 

collapse (mean) index20, by (fips)

save NPI20.dta, replace

* merging the NPI 20 and 21 data 


merge 1:1 fips using NPI21.dta, nogen keep(3)

generate HPIratio = ((index21/index20) - 1) * 100

save zipHPI.dta, replace


use zipHPI.dta, clear

* merge HPI with the zip county crosswalk data

merge 1:m fips using crossWalk.dta

keep if _merge == 3

drop _merge

* rename zip county

save zipTable.dta, replace

* merge the census and the nyt github data


use census.dta, clear

merge 1:1 fips using 2020Covid.dta

keep if _merge == 3

drop _merge

drop county

rename fips county

save censusNYT.dta, replace

* merge the census- nyt table with the HPI-cross walk data

use censusNYT.dta, clear

merge 1:m county using zipTable.dta

keep if _merge == 3

drop _merge

destring totalPop, replace

* generate the mortality variable

generate mortalityRate = (deaths/totalPop)*100 

* run regression 

reg HPIratio mortalityRate whitePop blackPop

twoway (scatter mortalityRate HPIratio, mfc(green) mlc(black))