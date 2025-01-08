// Author: Ramiro Barrera
// Date: 4/29/2024
// Update: 5/1/2024
// Paper: Gender Wage Gap in the Teaching Profession:
//			Evidence from Mexico and Chile
// Purpose: Appending FONE databases

***************
// Initializing 

clear all          
set more off       

***************
**# Directories
***************

global user = 3		// 1: Cristian, 2: Ramiro, 3: Overleaf

if $user == 1 {				
	gl dir = "/Users/cristian/Dropbox/research/Gender_Teachers"
}
if $user == 2 {
	gl dir = "/Users/56966/Dropbox/Gender_Teachers"
}
if $user == 3 {
	gl dir = "/Users/56966/Dropbox/Gender_Teachers"
}


gl work = "$dir/data/work"
gl original = "$dir/data/original"
gl latex = "$dir/latex"
gl figures = "$dir/output/figures"
gl tables = "$dir/output/tables"

if $user == 3 {
	gl figures = "\Users\56966\Dropbox\Aplicaciones\Overleaf\Gender Pay Gap Teachers/figures"
	gl tables = "\Users\56966\Dropbox\Aplicaciones\Overleaf\Gender Pay Gap Teachers/tables"
}

cd "$work\\FONE"

//Package installation
foreach ado in tabstatmat outtable{
    cap which `ado'
	di _rc
    if _rc!=0 ssc install `ado'
}
capture net install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
if _rc == 0 {
    di _rc
}
else{
    install scheme-modern, from("https://raw.githubusercontent.com/mdroste/stata-scheme-modern/master/")
}

///
*LOG FILE
log using "$dir\codes\LOG\FONE_data_sum.log", replace

////////////////////////////////
**#  DATAFRAMES WORK 
///////////////////////////////

*2016Q2 - 2018
forval agno = 2016(1)2017{
forval trime = 1(1)4{

if (`agno' == 2016 & `trime' == 1) | (`agno' == 2024 & `trime' > 1){
	break
}

else {
clear

import delimited "${original}/FONE_publico\\`agno'\\Q`trime'\\AnalíticoPlazas_R01_Trimestre_0`trime'_`agno'.csv",  stringcols(9) varnames(1) clear
rename modelo modelo_2
save "${work}\\FONE\\aux2" , replace

import delimited "${original}\FONE_publico\\`agno'\\Q`trime'\\PlazasDocAdmtvasDirec_R01_Trimestre_0`trime'_`agno'.csv", varnames(1) clear
bys curp: egen sec = seq()
replace sec = 0 if sec>1
gen has_model2 =1 if model == 2
replace has_model2 = 0 if has_model2 ==.
bys curp: egen docente = max(has_model2)
keep if docente == 1

merge m:1 clave_plaza using "${work}\\FONE\\aux2", gen(_merge_plaza) keep(1 3)
gen trime = `trime'
gen estado = 1
gen year = `agno'

forvalues i = 2/8 {

	save "${work}\\FONE\\aux_`agno'.dta"  , replace
	qui import delimited "${original}/FONE_publico\\`agno'\\Q`trime'\\AnalíticoPlazas_R0`i'_Trimestre_0`trime'_`agno'.csv", varnames(1)  stringcols(9) clear
	rename modelo modelo_2
	save "aux2" , replace
	qui	import delimited "C:/Users/56966/Dropbox/Gender_Teachers/data/original/FONE_publico\\`agno'\\Q`trime'\\PlazasDocAdmtvasDirec_R0`i'_Trimestre_0`trime'_`agno'.csv", varnames(1) clear 
	bys curp: egen sec = seq()
	replace sec = 0 if sec>1
	gen has_model2 =1 if model == 2
	replace has_model2 = 0 if has_model2 ==.
	bys curp: egen docente = max(has_model2)
	keep if docente == 1
	gen trime = `trime'
	gen estado = `i'
	gen year = `agno'
	
	di "PlazasDocAdmtvasDirec_R0`i'_Trimestre_0`trime'_`agno'.csv"
	merge m:1 clave_plaza  using "aux2", gen(_merge_plaza) keep(1 3)
	
	qui	append using "aux_`agno'.dta"
   
}

forvalues i = 10/32 {
    
	save "${work}\\FONE\\aux_`agno'.dta" , replace
	qui import delimited "${original}/FONE_publico\\`agno'\\Q`trime'\\AnalíticoPlazas_R`i'_Trimestre_0`trime'_`agno'.csv",  stringcols(9) varnames(1) clear
	rename modelo modelo_2
	save "aux2" , replace
qui	import delimited "${original}/FONE_publico\\`agno'\\Q`trime'\\PlazasDocAdmtvasDirec_R`i'_Trimestre_0`trime'_`agno'.csv", varnames(1) clear 
	bys curp: egen sec = seq()
	replace sec = 0 if sec>1
	gen has_model2 =1 if model == 2
	replace has_model2 = 0 if has_model2 ==.
	bys curp: egen docente = max(has_model2)
	keep if docente == 1
	gen trime = `trime'
	gen estado = `i'
	gen year = `agno'
	
	di "PlazasDocAdmtvasDirec_R`i'_Trimestre_0`trime'_`agno'.csv"
	merge m:1 clave_plaza using "aux2", gen(_merge_plaza) keep(1 3)
	
	qui	append using "aux_`agno'.dta"
	
}

erase "$work\\FONE\\aux_`agno'.dta"
erase "$work\\FONE\\aux2.dta"
dis "LLEGO AL ERASE"


////////////////////////////////
duplicates tag trimestre curp , gen(rep_total_job)

bys curp: egen percepciones_totales_alljobs = total( percepciones_trimestrales )

gen modelo_dif2 = 1
replace modelo_dif2 = 0 if modelo == 2
replace modelo_dif2 = 3 if modelo == 3
replace modelo_dif2 = 7 if modelo == 7
bys curp trimestre: egen otro_modelo = max(modelo_dif2)
keep if modelo == 2

merge m:1 categoria ///
 using "$work\\FONE\\D_categorias.dta", ///
	gen(m_categorias) keep(1 3) 
	
 foreach j in 9A 9B 9C 9D 9E {
	drop if nivel_categoria == "`j'" | nivel_categoria == "'`j'" 
}

g agno_n = substr(curp,5,2)
destring agno_n, force replace
g pre_1999 = substr(curp, 17 , 1 )
replace agno_n = agno_n + 2000 if (pre_1999 == "A"|pre_1999 == "B"|pre_1999 == "C"|pre_1999 == "D") 
replace agno_n = agno_n + 1900 if agno< 2000
g agno_df = substr(trimestre,1,4)
destring agno_df, force replace
g edad = agno_df - agno_n

g sexo =  substr(curp,11,1)
replace sexo = "error" if sexo != "M" & sexo != "H" & sexo !="X"

*
encode tipo_plaza, gen(t_plaza)
replace t_plaza = t_plaza - 1
label values t_plaza .
gen t_plaza_1 = 1 if (t_plaza == 1)
gen t_plaza_0 = 1 if (t_plaza == 0)
bysort curp trimestre: egen has_t_plaza_1 = max(t_plaza_1)
bysort curp trimestre: egen has_t_plaza_0 = max(t_plaza_0)
gen t_plaza_both = 2 if (has_t_plaza_1 == 1 & has_t_plaza_0 == 1)
replace t_plaza_both = 1 if t_plaza == 1 & t_plaza_both == .
replace t_plaza_both = 0 if t_plaza == 0 & t_plaza_both == .
drop  t_plaza_1 t_plaza_0 has_t_plaza_1 has_t_plaza_0 tipo_plaza
*

duplicates tag trimestre curp , gen(rep2)
encode entidad_federativa, gen(ef)
drop modelo_dif2 pre_1999 descripcion_modelo ///
nombre_centro_trabajo nombre entidad_federativa
compress
export delimited using "${work}\FONE\\PlazasDocQ`trime'`agno'.csv", replace
}
}
dis "CAMBIO DE AGNO"
}

beep


////////////////////////////////
**#  DATAFRAMES HOMICIDIOS
///////////////////////////////
{	
	import delimited "C:\Users\56966\Dropbox\Gender_Teachers\data\original\HOMICIDIOS\2015.csv", varnames(1) clear

drop if cod_muni == ""  | cod_muni == "FUENTE: INEGI. Estadísticas de mortalidad."


split cod_muni, p(" ")
{
	g estado = ""
	destring cod_muni1, force replace
replace estado = "AGUASCALIENTES" if cod_muni1 == 1
replace estado = "BAJA CALIFORNIA" if cod_muni1 == 2
replace estado = "BAJA CALIFORNIA SUR" if cod_muni1 == 3
replace estado = "CAMPECHE" if cod_muni1 == 4
replace estado = "COAHUILA DE ZARAGOZA" if cod_muni1 == 5
replace estado = "COLIMA" if cod_muni1 == 6
replace estado = "CHIAPAS" if cod_muni1 == 7
replace estado = "CHIHUAHUA" if cod_muni1 == 8
replace estado = "CIUDAD DE MEXICO" if cod_muni1 == 9
replace estado = "DURANGO" if cod_muni1 == 10
replace estado = "GUANAJUATO" if cod_muni1 == 11
replace estado = "GUERRERO" if cod_muni1 == 12
replace estado = "HIDALGO" if cod_muni1 == 13
replace estado = "JALISCO" if cod_muni1 == 14
replace estado = "MEXICO" if cod_muni1 == 15
replace estado = "MICHOACAN DE OCAMPO" if cod_muni1 == 16
replace estado = "MORELOS" if cod_muni1 == 17
replace estado = "NAYARIT" if cod_muni1 == 18
replace estado = "NUEVO LEON" if cod_muni1 == 19
replace estado = "OAXACA" if cod_muni1 == 20
replace estado = "PUEBLA" if cod_muni1 == 21
replace estado = "QUERETARO" if cod_muni1 == 22
replace estado = "QUINTANA ROO" if cod_muni1 == 23
replace estado = "SAN LUIS POTOSI" if cod_muni1 == 24
replace estado = "SINALOA" if cod_muni1 == 25
replace estado = "SONORA" if cod_muni1 == 26
replace estado = "TABASCO" if cod_muni1 == 27
replace estado = "TAMAULIPAS" if cod_muni1 == 28
replace estado = "TLAXCALA" if cod_muni1 == 29
replace estado = "VERACRUZ DE IGNACIO DE LA LLAVE" if cod_muni1 == 30
replace estado = "YUCATAN" if cod_muni1 == 31
replace estado = "ZACATECAS" if cod_muni1 == 32
}

drop cod_muni1 
rename cod_muni2 codigo_comuna

drop if codigo_comuna == "" | estado == ""

foreach vari in total_total hombre_total mujer_total total_enero hombre_enero mujer_enero total_febrero hombre_febrero mujer_febrero total_marzo hombre_marzo mujer_marzo total_abril hombre_abril mujer_abril total_mayo hombre_mayo mujer_mayo total_junio hombre_junio mujer_junio total_julio hombre_julio mujer_julio total_agosto hombre_agosto mujer_agosto total_septiembre hombre_septiembre mujer_septiembre total_octubre hombre_octubre mujer_octubre total_noviembre hombre_noviembre mujer_noviembre total_diciembre hombre_diciembre mujer_diciembre {
destring `vari', force replace
replace `vari' = 0 if `vari' == .	
}


foreach sexo in "H" "M" {
	if "`sexo'" == "H"{	
g `sexo'_Q1 = hombre_enero + hombre_febrero + hombre_marzo  
g `sexo'_Q2 = hombre_abril + hombre_mayo + hombre_junio 
g `sexo'_Q3 = hombre_julio + hombre_agosto + hombre_septiembre
g `sexo'_Q4 = hombre_octubre + hombre_noviembre + hombre_diciembre
	}
	else{
g `sexo'_Q1 = mujer_enero + mujer_febrero + mujer_marzo  
g `sexo'_Q2 = mujer_abril + mujer_mayo + mujer_junio 
g `sexo'_Q3 = mujer_julio + mujer_agosto + mujer_septiembre
g `sexo'_Q4 = mujer_octubre + mujer_noviembre + mujer_diciembre	
	}
}
  
g TOT_Q1 = total_enero + total_febrero + total_marzo  
g TOT_Q2 = total_abril + total_mayo + total_junio 
g TOT_Q3 = total_julio + total_agosto + total_septiembre
g TOT_Q4 = total_octubre + total_noviembre + total_diciembre

keep cod_muni muni TOT* H* M* codigo_comuna estado
reshape long H_Q M_Q TOT_Q, i( cod_muni muni ) j(trimestre)
rename (H_Q M_Q TOT_Q) (homicidio_H homicidio_M homicidio_TOT)
g year = 2015

save "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta",replace

forval year = 2016(1)2023{
import delimited "C:\Users\56966\Dropbox\Gender_Teachers\data\original\HOMICIDIOS\\`year'.csv", varnames(1) clear

drop if cod_muni == ""  | cod_muni == "FUENTE: INEGI. Estadísticas de mortalidad."

split cod_muni, p(" ")
{
	g estado = ""
	destring cod_muni1, force replace
replace estado = "AGUASCALIENTES" if cod_muni1 == 1
replace estado = "BAJA CALIFORNIA" if cod_muni1 == 2
replace estado = "BAJA CALIFORNIA SUR" if cod_muni1 == 3
replace estado = "CAMPECHE" if cod_muni1 == 4
replace estado = "COAHUILA DE ZARAGOZA" if cod_muni1 == 5
replace estado = "COLIMA" if cod_muni1 == 6
replace estado = "CHIAPAS" if cod_muni1 == 7
replace estado = "CHIHUAHUA" if cod_muni1 == 8
replace estado = "CIUDAD DE MEXICO" if cod_muni1 == 9
replace estado = "DURANGO" if cod_muni1 == 10
replace estado = "GUANAJUATO" if cod_muni1 == 11
replace estado = "GUERRERO" if cod_muni1 == 12
replace estado = "HIDALGO" if cod_muni1 == 13
replace estado = "JALISCO" if cod_muni1 == 14
replace estado = "MEXICO" if cod_muni1 == 15
replace estado = "MICHOACAN DE OCAMPO" if cod_muni1 == 16
replace estado = "MORELOS" if cod_muni1 == 17
replace estado = "NAYARIT" if cod_muni1 == 18
replace estado = "NUEVO LEON" if cod_muni1 == 19
replace estado = "OAXACA" if cod_muni1 == 20
replace estado = "PUEBLA" if cod_muni1 == 21
replace estado = "QUERETARO" if cod_muni1 == 22
replace estado = "QUINTANA ROO" if cod_muni1 == 23
replace estado = "SAN LUIS POTOSI" if cod_muni1 == 24
replace estado = "SINALOA" if cod_muni1 == 25
replace estado = "SONORA" if cod_muni1 == 26
replace estado = "TABASCO" if cod_muni1 == 27
replace estado = "TAMAULIPAS" if cod_muni1 == 28
replace estado = "TLAXCALA" if cod_muni1 == 29
replace estado = "VERACRUZ DE IGNACIO DE LA LLAVE" if cod_muni1 == 30
replace estado = "YUCATAN" if cod_muni1 == 31
replace estado = "ZACATECAS" if cod_muni1 == 32
}

drop cod_muni1 
rename cod_muni2 codigo_comuna

drop if codigo_comuna == "" | estado == ""

foreach vari in total_total hombre_total mujer_total total_enero hombre_enero mujer_enero total_febrero hombre_febrero mujer_febrero total_marzo hombre_marzo mujer_marzo total_abril hombre_abril mujer_abril total_mayo hombre_mayo mujer_mayo total_junio hombre_junio mujer_junio total_julio hombre_julio mujer_julio total_agosto hombre_agosto mujer_agosto total_septiembre hombre_septiembre mujer_septiembre total_octubre hombre_octubre mujer_octubre total_noviembre hombre_noviembre mujer_noviembre total_diciembre hombre_diciembre mujer_diciembre {
destring `vari', force replace
replace `vari' = 0 if `vari' == .	
}


foreach sexo in "H" "M" {
	if "`sexo'" == "H"{	
g `sexo'_Q1 = hombre_enero + hombre_febrero + hombre_marzo  
g `sexo'_Q2 = hombre_abril + hombre_mayo + hombre_junio 
g `sexo'_Q3 = hombre_julio + hombre_agosto + hombre_septiembre
g `sexo'_Q4 = hombre_octubre + hombre_noviembre + hombre_diciembre
	}
	else{
g `sexo'_Q1 = mujer_enero + mujer_febrero + mujer_marzo  
g `sexo'_Q2 = mujer_abril + mujer_mayo + mujer_junio 
g `sexo'_Q3 = mujer_julio + mujer_agosto + mujer_septiembre
g `sexo'_Q4 = mujer_octubre + mujer_noviembre + mujer_diciembre	
	}
}
  
g TOT_Q1 = total_enero + total_febrero + total_marzo  
g TOT_Q2 = total_abril + total_mayo + total_junio 
g TOT_Q3 = total_julio + total_agosto + total_septiembre
g TOT_Q4 = total_octubre + total_noviembre + total_diciembre

keep cod_muni muni TOT* H* M* codigo_comuna estado
reshape long H_Q M_Q TOT_Q, i( cod_muni muni ) j(trimestre)
rename (H_Q M_Q TOT_Q) (homicidio_H homicidio_M homicidio_TOT)
g year = `year'

append using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta"
save "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta",replace

}

replace muni = subinstr(muni, "á", "a", .)
replace muni = subinstr(muni, "é", "e", .)
replace muni = subinstr(muni, "í", "i", .)
replace muni = subinstr(muni, "ó", "o", .)
replace muni = subinstr(muni, "ú", "u", .)

* Para mayúsculas, también reemplaza las vocales con tilde en mayúscula
replace muni = subinstr(muni, "Á", "A", .)
replace muni = subinstr(muni, "É", "E", .)
replace muni = subinstr(muni, "Í", "I", .)
replace muni = subinstr(muni, "Ó", "O", .)
replace muni = subinstr(muni, "Ú", "U", .)
replace muni = strupper(muni)
drop if estado == "CIUDAD DE MEXICO"
split cod_muni, p(" ")
drop cod_muni

replace cod_muni1 = subinstr(cod_muni1, " ", "", .)
replace cod_muni2 = subinstr(cod_muni2, " ", "", .)
rename trimestre trime

gen trimestre = (year - 2016) * 4 + trime

save "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta",replace


import delimited "C:\Users\56966\Dropbox\Gender_Teachers\data\original\POB\INEGI_exporta_11_11_2024_6_43_57.csv", varnames(1) rowrange(5) clear
rename (v1 v2 v3 v4 v5) (cod_muni muni P_total P_H P_M)

split cod_muni, p(" ")
drop if muni == "" | cod_muni2 ==""
drop cod_muni3 cod_muni4 cod_muni5 cod_muni6 cod_muni7 cod_muni8 cod_muni9 cod_muni10 muni

replace cod_muni1 = subinstr(cod_muni1, " ", "", .)
replace cod_muni2 = subinstr(cod_muni2, " ", "", .)

merge 1:m cod_muni1 cod_muni2 using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta"
drop if cod_muni2 == "999"

foreach vari in total H M{
	replace P_`vari' = subinstr(P_`vari', ",", "", .)
}

destring P_total, force replace 
destring P_H, force replace 
destring P_M, force replace 

g homicidios_xt = (homicidio_TOT / P_total) * 1000
g homicidios_xm = (homicidio_H / P_H) * 1000
g homicidios_xh = (homicidio_M / P_M) * 1000

drop homicidio_H homicidio_M homicidio_TOT _merge  ///
cod_muni muni codigo_comuna ///
estado

save "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios.dta",replace

{
clear 
import delimited "C:\Users\56966\Dropbox\Gender_Teachers\data\original\HOMICIDIOS\FEM\2015.csv", varnames(1) clear

rename (v1 v2) (cod_muni ef)
drop if ef == ""
drop if cod_muni == ""  | cod_muni == "FUENTE: INEGI. Estadísticas de mortalidad."

split cod_muni, p(" ")
drop if cod_muni2 == ""

foreach vari in enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre{
	destring `vari', replace force
	replace `vari' = 0 if `vari' ==.
}
  
g FEM_Q1 = enero + febrero + marzo  
g FEM_Q2 = abril + mayo + junio 
g FEM_Q3 = julio + agosto + septiembre
g FEM_Q4 = octubre + noviembre + diciembre

keep cod_muni1 cod_muni2 FEM_Q* 
reshape long FEM_Q, i( cod_muni1 cod_muni2 ) j(trime)
g year = 2015

save "${work}\FONE\homicidios_aux.dta",replace

forvalues i = 2016(1)2023{
	dis `i'
import delimited "${original}\\HOMICIDIOS\\FEM\\`i'.csv", varnames(1) clear

rename (v1 v2) (cod_muni ef)
drop if ef == ""
drop if cod_muni == ""  | cod_muni == "FUENTE: INEGI. Estadísticas de mortalidad."
split cod_muni, p(" ")
drop if cod_muni2 == ""

if `i' == 2018{
	g julio = 0
}
if `i' == 2019{
	g marzo = 0
}
if `i' == 2020{
	g octubre = 0
}
if `i' == 2021{
	g agosto = 0
}
if `i' == 2022{
	g diciembre = 0
}

foreach vari in enero febrero marzo abril mayo junio julio agosto septiembre octubre noviembre diciembre{
	destring `vari', replace force
	replace `vari' = 0 if `vari' ==.
}
  
  
  
g FEM_Q1 = enero + febrero + marzo  
g FEM_Q2 = abril + mayo + junio 
g FEM_Q3 = julio + agosto + septiembre
g FEM_Q4 = octubre + noviembre + diciembre

keep cod_muni1 cod_muni2 FEM_Q* 
reshape long FEM_Q, i( cod_muni1 cod_muni2 ) j(trime)

g year = `i'
append using "${work}\FONE\homicidios_aux.dta"

save "${work}\FONE\homicidios_aux.dta",replace

}

}

use "${work}\FONE\homicidios.dta",clear
merge 1:1 cod_muni1 cod_muni2 trime year using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\homicidios_aux.dta" ,keep(1 3)
erase "${work}\FONE\homicidios_aux.dta" 
replace FEM_Q = 0 if FEM_Q == .
g femicidios = (FEM_Q / P_M) * 1000
keep cod_muni1 cod_muni2 trime year trimestre homicidios_xt homicidios_xm homicidios_xh femicidios
save "${work}\FONE\homicidios.dta",replace
}
	
	
////////////////////////////////
**#  DATAFRAMES MUNICIPALITIES/CCT
///////////////////////////////
{
import delimited "${original}\Catalogo CT\Catálogo_SIC 2023.csv", clear
keep cv_cct cv_tipo c_nombre cv_administrativa inmueble_cv_mun inmueble_c_nom_mun inmueble_c_nom_ambito sostenimiento_c_control tiponivelsub_c_servicion2

rename (cv_cct cv_administrativa inmueble_cv_mun inmueble_c_nom_mun inmueble_c_nom_ambito sostenimiento_c_control ) ///
(clave_centro_trabajo entidad_federativa municipio nom_municipio rural sostenimiento)
 
g orden = 2
save "${work}\FONE\aux_school.dta", replace
**
import delimited "${original}\Catalogo CT\cct_NACIONAL.csv", clear
keep v1 v4 v6 v25 v26 v36 v83
rename (v1 v4 v6 v25 v26 v36 v83) /// 
(clave_centro_trabajo cv_tipo entidad_federativa municipio nom_municipio sostenimiento tiponivelsub_c_servicion2) 
g orden = 1
append using "${work}\FONE\aux_school.dta", force
sort clave_centro_trabajo orden
bys clave_centro_trabajo: egen sec = seq()
drop if sec>1
drop sec
save "${work}\FONE\aux_school.dta", replace
**
import excel "${original}\Catalogo CT\cct_2021.xlsx", sheet("CCT 2021") firstrow clear

keep CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2
rename (CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2) /// 
(clave_centro_trabajo cv_tipo entidad_federativa municipio nom_municipio rural sostenimiento tiponivelsub_c_servicion2) 
append using "${work}\FONE\aux_school.dta", force

foreach vari in cv_tipo entidad_federativa municipio nom_municipio rural c_nombre sostenimiento tiponivelsub_c_servicion2 {
	dis `vari'
replace `vari' = "" if `vari' == "NA"
bys clave_centro_trabajo (`vari'): egen `vari'2 = mode(`vari')
replace `vari' = `vari'2 if `vari' == "" 
drop `vari'2
}


duplicates drop clave_centro_trabajo, force
save "${work}\FONE\aux_school.dta", replace

**
import excel "${original}\Catalogo CT\Catalogo_centros_trabajo_21_22_datos_abiertos.xlsx", sheet("CENTROS TRABAJO 21-22") firstrow clear
keep CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2
rename (CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2) /// 
(clave_centro_trabajo cv_tipo entidad_federativa municipio nom_municipio rural sostenimiento tiponivelsub_c_servicion2) 
append using "${work}\FONE\aux_school.dta", force

foreach vari in cv_tipo entidad_federativa municipio nom_municipio rural c_nombre sostenimiento tiponivelsub_c_servicion2{
replace `vari' = "" if `vari' == "NA"
bys clave_centro_trabajo (`vari'): egen `vari'2 = mode(`vari')
replace `vari' = `vari'2 if `vari' == "" 
drop `vari'2
}
duplicates drop clave_centro_trabajo, force
save "${work}\FONE\aux_school.dta", replace


**
import excel "${original}\Catalogo CT\Catalogo_SIC_2024.xlsx", sheet("Resultado1") firstrow clear
keep CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2
rename (CV_CCT C_TIPO C_ADMINISTRATIVA INMUEBLE_CV_MUN INMUEBLE_C_NOM_MUN INMUEBLE_C_NOM_AMBITO SOSTENIMIENTO_C_CONTROL TIPONIVELSUB_C_SERVICION2) /// 
(clave_centro_trabajo cv_tipo entidad_federativa municipio nom_municipio rural sostenimiento tiponivelsub_c_servicion2) 
append using "${work}\FONE\aux_school.dta", force

foreach vari in cv_tipo entidad_federativa municipio nom_municipio rural c_nombre sostenimiento tiponivelsub_c_servicion2 {
replace `vari' = "" if `vari' == "NA"
bys clave_centro_trabajo (`vari'): egen `vari'2 = mode(`vari')
replace `vari' = `vari'2 if `vari' == "" 
drop `vari'2
}
duplicates drop clave_centro_trabajo, force
save "${work}\FONE\aux_school.dta", replace

g lengg = strlen(clave_centro_trabajo)
keep if lengg == 10
drop lengg

replace nom_municipio = subinstr(nom_municipio, "á", "a", .)
replace nom_municipio = subinstr(nom_municipio, "é", "e", .)
replace nom_municipio = subinstr(nom_municipio, "í", "i", .)
replace nom_municipio = subinstr(nom_municipio, "ó", "o", .)
replace nom_municipio = subinstr(nom_municipio, "ú", "u", .)

* Para mayúsculas, también reemplaza las vocales con tilde en mayúscula
replace nom_municipio = subinstr(nom_municipio, "Á", "A", .)
replace nom_municipio = subinstr(nom_municipio, "É", "E", .)
replace nom_municipio = subinstr(nom_municipio, "Í", "I", .)
replace nom_municipio = subinstr(nom_municipio, "Ó", "O", .)
replace nom_municipio = subinstr(nom_municipio, "Ú", "U", .)
replace nom_municipio = strupper(nom_municipio)
drop c_nombre orden

gen cod_muni1 =""
replace cod_muni1 = "31" if entidad_federativa == "YUCATAN" | entidad_federativa == "YUCATÁN"
replace cod_muni1 = "11" if entidad_federativa == "GUANAJUATO"
replace cod_muni1 = "05" if entidad_federativa == "COAHUILA DE ZARAGOZA"
replace cod_muni1 = "28" if entidad_federativa == "TAMAULIPAS"
replace cod_muni1 = "19" if entidad_federativa == "NUEVO LEON" | entidad_federativa == "NUEVO LEÓN"
replace cod_muni1 = "20" if entidad_federativa == "OAXACA"
replace cod_muni1 = "07" if entidad_federativa == "CHIAPAS"
replace cod_muni1 = "30" if entidad_federativa == "VERACRUZ DE IGNACIO DE LA LLAVE"
replace cod_muni1 = "21" if entidad_federativa == "PUEBLA"
replace cod_muni1 = "15" if entidad_federativa == "MEXICO"  | entidad_federativa ==  "MÉXICO"
replace cod_muni1 = "18" if entidad_federativa == "NAYARIT"
replace cod_muni1 = "12" if entidad_federativa == "GUERRERO"
replace cod_muni1 = "14" if entidad_federativa == "JALISCO"
replace cod_muni1 = "13" if entidad_federativa == "HIDALGO"
replace cod_muni1 = "26" if entidad_federativa == "SONORA"
replace cod_muni1 = "29" if entidad_federativa == "TLAXCALA"
replace cod_muni1 = "16" if entidad_federativa == "MICHOACAN DE OCAMPO" | entidad_federativa == "MICHOACÁN DE OCAMPO"
replace cod_muni1 = "01" if entidad_federativa == "AGUASCALIENTES"
replace cod_muni1 = "25" if entidad_federativa == "SINALOA"
replace cod_muni1 = "24" if entidad_federativa == "SAN LUIS POTOSI" | entidad_federativa == "SAN LUIS POTOSÍ"
replace cod_muni1 = "08" if entidad_federativa == "CHIHUAHUA"
replace cod_muni1 = "17" if entidad_federativa == "MORELOS"
replace cod_muni1 = "22" if entidad_federativa == "QUERETARO" | entidad_federativa == "QUERÉTARO"
replace cod_muni1 = "32" if entidad_federativa == "ZACATECAS"
replace cod_muni1 = "06" if entidad_federativa == "COLIMA"
replace cod_muni1 = "23" if entidad_federativa == "QUINTANA ROO"
replace cod_muni1 = "27" if entidad_federativa == "TABASCO"
replace cod_muni1 = "04" if entidad_federativa == "CAMPECHE"
replace cod_muni1 = "10" if entidad_federativa == "DURANGO"
replace cod_muni1 = "03" if entidad_federativa == "BAJA CALIFORNIA SUR"
replace cod_muni1 = "02" if entidad_federativa == "BAJA CALIFORNIA"
drop if cod_muni1 == ""

rename municipio cod_muni2
replace cod_muni1 = subinstr(cod_muni1, " ", "", .)
replace cod_muni2 = subinstr(cod_muni2, " ", "", .)
recast str clave_centro_trabajo
drop entidad_federativa


g instruction_level = 0 
replace instruction_level = 1 if tiponivelsub_c_servicion2 == "INICIAL"
replace instruction_level = 2 if tiponivelsub_c_servicion2 == "PREESCOLAR"
replace instruction_level = 3 if tiponivelsub_c_servicion2 == "PRIMARIA" | tiponivelsub_c_servicion2 == "BÁSICA"
replace instruction_level = 4 if tiponivelsub_c_servicion2 == "SECUNDARIA"
replace instruction_level = 5 if tiponivelsub_c_servicion2 == "MEDIA SUPERIOR"
replace instruction_level = 6 if tiponivelsub_c_servicion2 == "SUPERIOR"

label define inst_lvl 0 "Other" 1 "Inicial" 2 "Prescolar" 3 "Primaria" 4 "Secundaria" 5 "Media Superior" 6 "Superior" , replace
label values instruction_level inst_lvl
drop tiponivelsub_c_servicion2

encode sostenimiento, gen(sosten_)
drop sostenimiento nom_municipio

save "${work}\FONE\aux_school.dta", replace


import excel "${original}\IRS\IRS_entidades_mpios_2015.xlsx", ///
sheet("Municipios") cellrange(A6:R2457) firstrow clear
drop if E == .
drop A
keep C Q R
rename (C Q R ) (cod_muni  ind_des_2015 cal_des_2015)

g cod_muni1 = substr(cod_muni,1,2)
g cod_muni2 = substr(cod_muni,3,3)

drop cod_muni 
merge 1:m cod_muni1 cod_muni2 ///
using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\aux_school.dta" ///
, keep( 2 3 ) nogen
save "${work}\FONE\aux_school.dta", replace

import excel "${original}\IRS\IRS_entidades_mpios_2020.xlsx", ///
sheet("Municipios") cellrange(A6:R2457) firstrow clear
drop if E == .
drop A
keep C Q R
rename (C Q R ) (cod_muni  ind_des_2020 cal_des_2020)

g cod_muni1 = substr(cod_muni,1,2)
g cod_muni2 = substr(cod_muni,3,3)
merge 1:m cod_muni1 cod_muni2 ///
using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\aux_school.dta" ///
, keep( 2 3 ) nogen


save "${work}\FONE\aux_school.dta", replace

 }


////////////////////////////////
**#  DATAFRAMES APPEND
///////////////////////////////
{
clear all
import delimited using "${work}\\FONE\\PlazasDocQ12017", clear varnames(1)

drop rfc trimestre has_model2 ///
	modelo_2  m_categorias agno_n  modelo docente _merge_plaza
	 
drop if curp == ""
compress
**2017-2018
forval agno = 2016(1)2024{
forvalues i = 1(1)4{
	
	if (`i' == 1 & (`agno' == 2017 | `agno' == 2016)) | ///
	(`i' > 1 & (`agno' == 2024)) {
		break
		}
else {
	dis "`agno' y `i'"
save "${work}\\FONE\\aux_1", replace
import delimited using "${work}\\FONE\\PlazasDocQ`i'`agno'", clear varnames(1)
if agno_df < 2019{
	keep curp clave_plaza modelo clave_centro_trabajo percepciones_trimestrales sec trime estado year categoria descripcion_categoria nivel_categoria zona_economica rep_total_job percepciones_totales_direc otro_modelo agno_df edad sexo t_plaza t_plaza_both rep2 ef
}
else{
	keep curp clave_plaza modelo clave_centro_trabajo percepciones_trimestrales sec trime categoria descripcion_categoria nivel_categoria zona_economica rep_total_job  otro_modelo agno_df edad sexo t_plaza t_plaza_both rep2 entidad_federativa
	
}
drop if curp == ""
compress
*merge m:1 descripcion_categoria using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\D_categorias.dta", keep(1 3)
qui	append using "${work}\\FONE\\aux_1", force

}
}
}

drop modelo sec
drop if curp == ""
save "${work}\\FONE\\aux_1", replace


//Arreglar categorias
{ 
*g cateogoria_71 = 1 if (nivel_categoria == "71" | nivel_categoria == "'71") 
*replace cateogoria_71 = 0 if cateogoria_71  == .
*g cateogoria_72 = 1 if (nivel_categoria == "72" | nivel_categoria == "'72") 
*replace cateogoria_72 = 0 if cateogoria_72  == .

{
	gen keep_ = 1 ///
if categoria == "E261" |  categoria == "E280" |  ///
categoria == "E281" |  categoria == "E361" |  ///
categoria == "E363" |  categoria == "E364" |  categoria == "E365" |  ///
categoria == "E371" |  categoria == "E461" |  ///
categoria == "E463" |  categoria == "E465" |  ///
categoria == "E763" |  categoria == "E962" |  categoria == "E0260" |  ///
categoria == "E0261" |  categoria == "E0263" |  ///
categoria == "E0265" |  categoria == "E0280" |  ///
categoria == "E0281" |  categoria == "E0285" |  ///
categoria == "E0286" |  categoria == "E0289" |  ///
categoria == "E0291" |  categoria == "E0360" |  ///
categoria == "E0361" |  categoria == "E0362" |  ///
categoria == "E0363" |  categoria == "E0365" |  ///
categoria == "E0371" |  categoria == "E0460" |  ///
categoria == "E0461" |  categoria == "E0462" |  ///
categoria == "E0463" |  categoria == "E0464" |  ///
categoria == "E0465" |  categoria == "E0571" |  ///
categoria == "E0761" | categoria == "E0762"| categoria == "E0763" |  ///
categoria == "E0765" | categoria == "E0773"|categoria == "E1062" |  ///
categoria == "E1063" | categoria == "E1065"| categoria == "E1067" |  ///
categoria == "E1090" | categoria == "E1161"| categoria == "E1163" |  ///
categoria == "E1435" | categoria == "E1441"| categoria == "E1443" |  ///
categoria == "E1451" | categoria == "E1471"| categoria == "E1473" |  ///
categoria == "E1485" | categoria == "E1486"| categoria == "E1493" |  ///
categoria == "E1495" | categoria == "E1497"| categoria == "E1499" |  ///
categoria == "E2781" | categoria == "E3001"| categoria == "CFF3481" 
keep if keep_ == 1
drop keep_
}	


replace nivel_categoria = "Not reported" if nivel_categoria == ""
replace nivel_categoria = 	"07"	if nivel_categoria == "'07"
replace nivel_categoria = 	"07"	if nivel_categoria ==	"'71" | nivel_categoria ==	"71"
replace nivel_categoria = 	"07"	if nivel_categoria ==	"'72" | nivel_categoria ==	"72"
replace nivel_categoria = 	"7A"	if nivel_categoria ==	"'7A"
replace nivel_categoria = 	"7B"	if nivel_categoria ==	"'7B"
replace nivel_categoria = 	"7BC"	if nivel_categoria ==	"'7BC"
replace nivel_categoria = 	"7C"	if nivel_categoria ==	"'7C"
replace nivel_categoria = 	"7D"	if nivel_categoria ==	"'7D"
replace nivel_categoria = 	"7E"	if nivel_categoria ==	"'7E"
replace nivel_categoria = 	"9A"	if nivel_categoria ==	"'9A"
replace nivel_categoria = 	"9B"	if nivel_categoria ==	"'9B"
replace nivel_categoria = 	"9C"	if nivel_categoria ==	"'9C"
replace nivel_categoria = 	"9D"	if nivel_categoria ==	"'9D"
replace nivel_categoria = 	"9E"	if nivel_categoria ==	"'9E"
replace nivel_categoria = 	"7BC"	if nivel_categoria ==	"'BC"
replace nivel_categoria = 	"7BC"	if nivel_categoria ==	"BC"
replace nivel_categoria = 	"07"	if nivel_categoria ==	"7"
}

foreach j in 9A 9B 9C 9D 9E {
	drop if nivel_categoria == "`j'"
}
**ARREGLOS
{
save "${work}\\FONE\\aux_1", replace

{
	use "${work}\\FONE\\aux_1.dta", clear

	replace descripcion_categoria = lower(descripcion_categoria)	
	replace descripcion_categoria = subinstr(descripcion_categoria, "á", "a", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "é", "e", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "í", "i", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "ó", "o", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "ú", "u", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "Á", "a", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "É", "e", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "Í", "i", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "Ó", "o", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "Ú", "u", .)
	replace descripcion_categoria = subinstr(descripcion_categoria, "Ñ", "ñ", .)
	
	gen contiene_primaria= strpos(categoria, "E02") > 0
	gen contiene_secundaria  = strpos(categoria, "E03") > 0
	
	g primaria = .
	replace primaria = 1 if contiene_primaria == 1
	replace primaria = 0 if contiene_secundaria == 1
	
	drop contiene_secundaria contiene_primaria
	
	replace categoria = "E0261" if categoria == "E261"
	replace categoria = "E0280" if categoria == "E280"
	replace categoria = "E0281" if categoria == "E281"
	replace categoria = "E0361" if categoria == "E361"
	replace categoria = "E0363" if categoria == "E363"
	replace categoria = "E0364" if categoria == "E364"
	replace categoria = "E0365" if categoria == "E365"
	replace categoria = "E0371" if categoria == "E371"
	replace categoria = "E0461" if categoria == "E461"
	replace categoria = "E0463" if categoria == "E463"
	replace categoria = "E0465" if categoria == "E465"
	replace categoria = "E0763" if categoria == "E763"
	replace categoria = "E0962" if categoria == "E962"

drop descripcion_categoria
}

replace year = agno_df if year == .
drop agno_df
drop rep2
drop percepciones_totales 

gen date = string(year) + "q" + string(trime)
encode date , gen(trimestre)
drop date 

bys curp year trime : egen sec = seq()
bys curp year trime : egen percepciones_totales = sum(percepciones_trimestrales) 
merge m:1 trimestre using "C:\Users\56966\Dropbox\Gender_Teachers\data\original\INPC\INPC.dta"
g p_trim_real = percepciones_trimestrales/(1+(INPC_ac_p))
g p_total_real = percepciones_totales/(1+(INPC_ac_p))

drop percepciones_trimestrales percepciones_totales INPC_ac_p _merge

bys curp (sexo): egen sexo2 = mode(sexo)
replace sexo = sexo2 if sexo == "" | sexo == "error"
drop if sexo == ""
drop sexo2

mat errores = J(4,1,.)
tab edad if edad<22
mat errores[1,1] = r(N) 
tab edad if edad>65
mat errores[2,1] = r(N) 
tab trimestre if sexo == "error" 
mat errores[3,1] = r(N) 
mat errores[4,1] = errores[1,1] + errores[2,1]  + errores[3,1] 
mat rownames errores = "Age < 22" "Age > 65" "Sexo = error" "Total"
mat colnames errores = "Count"
outtable using "${tables}\\descriptive\\errores", ///
caption("Observations dropped from sample") mat(errores) longtable ///
replace nobox center format(%20.0fc) 

drop if edad>65 | edad<22 | sexo =="error"

bys categoria: egen conteo = count(categoria)
drop if conteo < 1000	
drop conteo
save "${work}\\FONE\\aux_1", replace
}
** GEN VARS
{

gsort curp trimestre -p_trim_real
bys curp trimestre: egen secc = seq()
duplicates tag curp trimestre, gen(n_jobs)
replace n_jobs = n_jobs + 1
gen duplicate = 0 
replace duplicate = 1 if n_jobs > 1

encode sexo, gen(sex)
drop sexo

replace ef = entidad_federativa if ef == ""
replace ef = "AGUASCALIENTES" if ef == "AGUASCALIENTDS" 
drop entidad_federativa
encode ef, gen(entidad_federativa)
drop estado

foreach value in 7BC 9A 9B 9C 9D 9E{
drop if nivel_categoria == "`value'"
}
replace nivel_categoria = "Not reported" if nivel_categoria == ""
encode nivel_categoria , gen(n_categoria)
drop nivel_categoria

egen edad_cut = cut(edad), at(20, 25, 30, 35, 40, 45, 50, 55, 60, 66) icodes

gen t_plaza_1 = 1 if (t_plaza_both == 1)
gen t_plaza_0 = 1 if (t_plaza_both == 0)
gen t_plaza_2 = 1 if (t_plaza_both == 2)

bysort curp trimestre: egen has_t_plaza_1 = max(t_plaza_1)
bysort curp trimestre: egen has_t_plaza_0 = max(t_plaza_0)
bysort curp trimestre: egen has_t_plaza_2 = max(t_plaza_2)
gen t_plaza_b = .
replace t_plaza_b = 2 if (has_t_plaza_2 == 1) | (has_t_plaza_1 == 1 & has_t_plaza_0 == 1)
replace t_plaza_b = 1 if has_t_plaza_1 == 1 & t_plaza_b == .
replace t_plaza_b = 0 if has_t_plaza_0 == 1 & t_plaza_b == .

drop t_plaza_0 t_plaza_1 t_plaza_2 has_t_plaza* 

}

**LABELS
{
label define dup 0 "1 Work" 1 "2 or more works", replace
label values duplicate dup
label define sex 1 "Male" 2 "Female", replace
label define tplaza 0 "Part-time" 1 "Full-time", replace
label values t_plaza tplaza
label define secu 1 "Primary" 0 "Secondary", replace
label values primaria secu
label define tplaza2 0 "Part-time" 1 "Full-time" 2 "Both", replace
label values t_plaza_b tplaza2
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 
label define otrom 0 "Dont' have'" 1 "Have another type of work" 
label values otro_modelo otrom 

drop sec 

{
replace ef  = "AGS" if ef == "AGUASCALIENTES"
replace ef  = "BC" if ef == "BAJA CALIFORNIA"
replace ef  = "BCS" if ef == "BAJA CALIFORNIA SUR"
replace ef  = "CAMP" if ef == "CAMPECHE"
replace ef  = "CHIS" if ef == "CHIAPAS"
replace ef  = "CHIH" if ef == "CHIHUAHUA"
replace ef  = "COAH" if ef == "COAHUILA"
replace ef  = "COL" if ef == "COLIMA"
replace ef  = "DGO" if ef == "DURANGO"
replace ef  = "GTO" if ef == "GUANAJUATO"
replace ef  = "GRO" if ef == "GUERRERO"
replace ef  = "HGO" if ef == "HIDALGO"
replace ef  = "JAL" if ef == "JALISCO"
replace ef  = "MEX" if ef == "MÉXICO"
replace ef  = "MICH" if ef == "MICHOACÁN"
replace ef  = "MOR" if ef == "MORELOS"
replace ef  = "NAY" if ef == "NAYARIT"
replace ef  = "NL" if ef == "NUEVO LEÓN"
replace ef  = "OAX" if ef == "OAXACA"
replace ef  = "PUE" if ef == "PUEBLA"
replace ef  = "QRO" if ef == "QUERÉTARO"
replace ef  = "Q.ROO" if ef == "QUINTANA ROO"
replace ef  = "S.L.P" if ef == "SAN LUIS POTOSÍ"
replace ef  = "SIN" if ef == "SINALOA"
replace ef  = "SON" if ef == "SONORA"
replace ef  = "TAB" if ef == "TABASCO"
replace ef  = "TAMPS" if ef == "TAMAULIPAS"
replace ef  = "TLAX" if ef == "TLAXCALA"
replace ef  = "VER" if ef == "VERACRUZ"
replace ef  = "YUC" if ef == "YUCATÁN"
replace ef  = "ZAC" if ef == "ZACATECAS"
}

bys categoria: egen counti = count(categoria)
drop if counti < 1000
drop counti

save "${work}\\FONE\\aux_1", replace
beep
}

* MERGE WITH MUNICIPIOS
{
use "${work}\\FONE\\aux_1.dta", clear

merge m:1 clave_centro_trabajo using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\aux_school.dta", gen(merge_comuna) keep(1 3)
drop  merge_comuna 
g rural_c = .
replace rural_c = 1 if rural == "RURAL"
replace rural_c = 0 if rural == "URBANO"

drop rural
rename rural_c rural
drop if trime ==.
drop if curp == "" | curp == " " 
encode cv_tipo , gen(c_tipo)
drop cv_tipo

foreach vari in ind_des cal_des {
g `vari' = `vari'_2015 if year< 2020 
replace `vari' = `vari'_2020 if year>2019
replace `vari' = `vari'_2015 if ind_des ==.
}

save "${work}\\FONE\\aux_1.dta", replace
}
beep

* MERGE WITH QUALITY
{
use "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\aux_3.dta", clear
*keep if TIPO == "basica"
merge 1:m year curp using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\\FONE\\aux_1.dta", generate(_merge_calidad)

	sort curp trimestre
	drop gpo_desemp real TIPO secundarias g_desmp
	*bys curp : gen desempeno_ff = g_desmp
	*bys curp : replace desempeno_ff = desempeno_ff[_n-1] if desempeno_ff == .
	*bys curp : replace desempeno_ff = desempeno_ff[_n+1] if desempeno_ff == .
	*replace desempeno_ff = 99 if desempeno_ff  == .

	bys curp : replace p_sg = p_sg[_n-1] if p_sg == .
	bys curp : replace p_sg = p_sg[_n+1] if p_sg == .
	bys curp : replace desv_p = desv_p[_n-1] if desv_p == .
	bys curp : replace desv_p = desv_p[_n+1] if desv_p == .
	
*replace gpo_desemp = "Not defined" if gpo_desemp == ""
	*drop if _merge_calidad == 1
	*label define rend ///
	*99 "Not defined" 0 "Did not take the exam" 1 "Insufficient" ///
	*2 "Enought"  3 "Good" 4 "Outstanding" ///
	
	*label values desempeno_ff rend
	
save "${work}\\FONE\\aux_1", replace

 beep
}
beep

**APPEND HOMICIDES
{
use "${work}\\FONE\\homicidios.dta", clear

rename trimestre trime
drop if estado == "CIUDAD DE MEXICO"
drop estado
/*
{
	g entidad_federativa = .
replace entidad_federativa = 1 if estado == "AGUASCALIENTES"
replace entidad_federativa = 2 if estado == "BAJA CALIFORNIA"
replace entidad_federativa = 3 if estado == "BAJA CALIFORNIA SUR"
replace entidad_federativa = 4 if estado == "CAMPECHE"
replace entidad_federativa = 5 if estado == "CHIAPAS"
replace entidad_federativa = 6 if estado == "CHIHUAHUA"
replace entidad_federativa = 7 if estado == "COAHUILA DE ZARAGOZA"
replace entidad_federativa = 8 if estado == "COLIMA"
replace entidad_federativa = 9 if estado == "DURANGO"
replace entidad_federativa = 10 if estado == "GUANAJUATO"
replace entidad_federativa = 11 if estado == "GUERRERO"
replace entidad_federativa = 12 if estado == "HIDALGO"
replace entidad_federativa = 13 if estado == "JALISCO"
replace entidad_federativa = 14 if estado == "MICHOACAN DE OCAMPO"
replace entidad_federativa = 15 if estado == "MORELOS"
replace entidad_federativa = 16 if estado == "MEXICO"
replace entidad_federativa = 17 if estado == "NAYARIT"
replace entidad_federativa = 18 if estado == "NUEVO LEON"
replace entidad_federativa = 19 if estado == "OAXACA"
replace entidad_federativa = 20 if estado == "PUEBLA"
replace entidad_federativa = 21 if estado == "QUERETARO"
replace entidad_federativa = 22 if estado == "QUINTANA ROO"
replace entidad_federativa = 23 if estado == "SAN LUIS POTOSI"
replace entidad_federativa = 24 if estado == "SINALOA"
replace entidad_federativa = 25 if estado == "SONORA"
replace entidad_federativa = 26 if estado == "TABASCO"
replace entidad_federativa = 27 if estado == "TAMAULIPAS"
replace entidad_federativa = 28 if estado == "TLAXCALA"
replace entidad_federativa = 29 if estado == "VERACRUZ DE IGNACIO DE LA LLAVE"
replace entidad_federativa = 30 if estado == "YUCATAN"
replace entidad_federativa = 31 if estado == "ZACATECAS"
}
*/
merge 1:m cod_muni1 cod_muni2 trime year using ///
 "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\aux_1.dta" ///
, gen(_merge_homicidio)

drop if _merge_homicidio == 1
*keep if nivel_inst == 2 | nivel_inst == 3 | instruction_level == 3 | instruction_level == 4
save "${work}\\FONE\\aux_1", replace
erase "${work}\\FONE\\homicidios.dta"
}

}



////////////////////////////////
**#  TOTAL WAGE IN ALL JOBS
///////////////////////////////
{
clear all
import delimited using "${work}\\FONE\\PlazasDocQ12017", clear varnames(1)

keep curp percepciones_totales_alljobs trimestre
duplicates drop curp trimestre, force
drop if curp == ""
compress
**2017-2018
forval agno = 2016(1)2024{
forvalues i = 1(1)4{
	
	if (`i' == 1 & (`agno' == 2017 | `agno' == 2016)) | ///
	(`i' > 1 & (`agno' == 2024)) {
		break
		}
else {
	dis "`agno' y `i'"
save "${work}\\FONE\\aux_wage", replace
import delimited using "${work}\\FONE\\PlazasDocQ`i'`agno'", clear varnames(1)
if agno_df < 2019{
	keep curp percepciones_totales_alljobs trimestre
}
else{
	keep curp percepciones_totales_alljobs trimestre
	
}
drop if curp == ""
compress
*merge m:1 descripcion_categoria using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\D_categorias.dta", keep(1 3)
qui	append using "${work}\\FONE\\aux_wage", force
	

}
}
}
save "${work}\\FONE\\aux_wage", replace
}
				 
				 
				 *  TABLES  *
**# ////////////  TEACHER LEVEL ///////////////////////
{

**# 	*FONE category level
{
use "${work}\\FONE\\aux_1.dta", clear
keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
bys curp: egen seqq = seq()
keep if seqq == 1

tab year n_categoria if sex == 1, matcell(mat1)
tab year n_categoria if sex == 2, matcell(mat2)
mat mat12 = J(9,1,.)
mat mat22 = J(9,1,.)
foreach matriz in mat1 mat2{
	
	forval i = 1(1)9{
		mat `matriz'2[`i',1] = `matriz'[`i',1] + `matriz'[`i',2] + ///
		`matriz'[`i',3] + `matriz'[`i',4] + `matriz'[`i',5] + ///
		`matriz'[`i',6] 
	}
	
	mat `matriz' = `matriz', `matriz'2
	mat colnames `matriz' =  ///
"07" "7A" "7B" "7C" "7D" "7E"  "Total" 
	mat rownames `matriz' =  "2016" "2017" "2018" "2019" ///
							"2020" "2021" "2022" "2023" "2024" 
}

outtable using "${tables}\\descriptive\\teachers\\categoria_trim_Male", ///
caption("Male teachers by pay category and year") ///
mat(mat1) replace nobox center format(%20.0fc) ///
 clabel("cat_trim_male")

outtable using "${tables}\\descriptive\\teachers\\categoria_trim_Female", ///
caption("Female teachers by pay category and year") ///
 mat(mat2) replace nobox center format(%20.0fc) ///
  clabel("cat_trim_fem")


///////
use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	bys curp: egen seqq = seq()
	keep if seqq == 1

matrix drop mat1
matrix drop mat2
 
foreach j in 1 2 3 4 5 6 {
matrix drop mat1_`j'
matrix drop mat2_`j'
}

////////////////////// PLOTS
*

use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	
collapse (max) n_categoria (first) sex , by(curp year)

foreach agno in 2016 2024{

		preserve
			replace sex = 0 if sex == 2
			label values n_categoria n_categoria
			keep if year == `agno'
			bys n_categoria: egen freq_h = count(sex) if sex==1
			bys n_categoria: egen freq_m = count(sex) if sex==0
			bys n_categoria: egen freq = count(sex) 
			bys n_categoria: gen ratio_M = 100*(freq_m / freq)
			bys n_categoria: gen ratio_H = 100*(freq_h / freq)
			
			
			graph hbar (max) ratio_M ratio_H    , ///
			over(n_categoria, sort()) stack 	///
				legend(order(1 "Female" 2 "Male" )) ytitle("Proportion (%)") 
				
			graph export "${figures}\\descriptive\\category\\ratio_teacher_cat_`agno'.png" , replace
		restore
		}
	

foreach agno in 2016 2024{

		preserve
			keep if year == `agno'
			bys sex: egen freq_a = count(sex) if n_categoria==1
			bys sex: egen freq_b = count(sex) if n_categoria==2
			bys sex: egen freq_c = count(sex) if n_categoria==3
			bys sex: egen freq_d = count(sex) if n_categoria==4
			bys sex: egen freq_e = count(sex) if n_categoria==5
			bys sex: egen freq_f = count(sex) if n_categoria==6
			bys sex: egen freq = count(sex) 
			
			bys sex: gen ratio_a = 100*(freq_a / freq) if n_categoria==1
			bys sex: gen ratio_b = 100*(freq_b / freq) if n_categoria==2
			bys sex: gen ratio_c = 100*(freq_c / freq) if n_categoria==3
			bys sex: gen ratio_d = 100*(freq_d / freq) if n_categoria==4
			bys sex: gen ratio_e = 100*(freq_e / freq) if n_categoria==5
			bys sex: gen ratio_f = 100*(freq_f / freq) if n_categoria==6

			
	graph hbar (max) ratio_a ratio_b ratio_c ratio_d ratio_e ratio_f  ///
	 ,  over(sex) stack ///
			legend(order(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" )) ///
			ytitle("Proportion (%)") 
			graph export "${figures}\\descriptive\\category\\ratio_sex_cat_`agno'.png" , replace
		restore
		}
	

	
use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	bys curp: egen seqq = seq()
	keep if seqq == 1
	foreach categoria in 1 2 3 4 5 6  {
	twoway ///
	(kdensity edad if sex==2 & n_categoria == `categoria' , bwidth(3)) ///
(kdensity edad if sex == 1 & n_categoria == `categoria' , bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\category\\teacher_edad_cat`categoria'.png" , replace
}

}

**# 	*FONE category AND age
{
use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	
collapse (first) edad edad_cut sex (max) n_categoria , by(curp trimestre)

label values n_categoria n_categoria
label values edad_cut edadcut 
tab edad_cut n_categoria if n_categoria != 0

}

**# 	*Contract type
{
	use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	bys curp: egen seqq = seq()
	keep if seqq == 1

sort trimestre 

sort secc
collapse (first) t_plaza_b sex edad primaria , by(curp year)
tab year t_plaza_b if  sex == 1, matcell(mat1)  
tab year t_plaza_b if sex == 2, matcell(mat2)  
mat plaza_trimestre_sexo = mat2, mat1

mat J = J(9,1,.)
forval j = 1(1)9{
mat J[`j',1] = plaza_trimestre_sexo[`j',1] + plaza_trimestre_sexo[`j',2] +  ///
plaza_trimestre_sexo[`j',3] + plaza_trimestre_sexo[`j',4] + ///
plaza_trimestre_sexo[`j',5] + plaza_trimestre_sexo[`j',6]  
}

mat plaza_trimestre_sexo = plaza_trimestre_sexo , J
mat rownames plaza_trimestre_sexo = "2016" "2017" "2018" "2019" "2020" ///
	"2021" "2022" "2023" "2024" 

frmttable using "${tables}\\descriptive\\teachers\\plaza_trimestre_sexo_agno", ///
 fragment tex statmat(plaza_trimestre_sexo) varlabels replace ///
 sfmt(fc)   sdec(0)  ///
 ctitles("" "" "Female" "" "" "Male" ""  ///
 \"Year" "Part-time" "Full-time" "Both" "Part-time" "Full-time" "Both" "Total") 



twoway ///
(kdensity edad if sex==2 & t_plaza_b == 0 , bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 0 , bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place0.png" , replace

twoway (kdensity edad if sex==2 & t_plaza_b == 1 , bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 1, bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place1.png" , replace

twoway (kdensity edad if sex==2 & t_plaza_b == 2, bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 2 , bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place2.png" , replace

foreach agno in 2016 2024{
    		
		twoway (kdensity edad if sex==2 & t_plaza_b == 0 & year == `agno', bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 0 & year == `agno', bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place0_`agno'.png" , replace

		twoway (kdensity edad if sex==2 & t_plaza_b == 1 & year == `agno', bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 1 & year == `agno', bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place1_`agno'.png" , replace

		twoway (kdensity edad if sex==2 & t_plaza_b == 2 & year == `agno', bwidth(3)) ///
(kdensity edad if sex == 1 & t_plaza_b == 2 & year == `agno', bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\contract_type\\teacher_place2_`agno'.png" , replace
			
		}


 
}

**#		*N* of repetitions
{
    use "${work}\\FONE\\aux_1", clear
		keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	
preserve
{
collapse (first) duplicate sex rep_total_job n_jobs, by(curp year)

	qui tab year duplicate if sex==1, matcell(mat1) 	
	qui tab year duplicate if sex==2, matcell(mat2) 	

	mat rep_quart = (mat1 , mat2)

mat totals = J(9, 1,.)
forvalues i = 1/9 {
    matrix totals[`i',1] = rep_quart[`i',1] + ///
	rep_quart[`i',2] + rep_quart[`i',3]  + rep_quart[`i',4]  
}

matrix rep_quart = (rep_quart , totals)
mat colnames rep_quart =  "1 Work" "2 or more works" ///
 "1 Work"  "2 or more works" "Total" 
mat rownames rep_quart = "2016" "2017" "2018" "2019" "2020" ///
	"2021" "2022" "2023" "2024"

outtable using "${tables}\\descriptive\\teachers\\rep_quart", ///
caption("Teachers by number of jobs, quarter and sex") ///
mat(rep_quart) replace  nobox center ///
format(%20.0fc) clabel(rep_quart)
matrix drop rep_quart
beep
}
restore

collapse (first) duplicate sex rep_total_job n_jobs, by(curp year)


foreach repes in n_jobs rep_total_job {
mat mat`repes' = J(3,11,.)
foreach sex in 1 2 {
	_pctile `repes' if sex == `sex', ///
	p(1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 99)
		forval i = 1/11{
			if `sex' == 1 {
			mat mat`repes'[1,`i'] = r(r`i')	
			}
			else{
			mat mat`repes'[2,`i'] = r(r`i')		
			}
		}
} 

	_pctile `repes' , ///
	p(1, 10, 20, 30, 40, 50, 60, 70, 80, 90, 99)
		forval i = 1/11{
		mat mat`repes'[3,`i'] = r(r`i')	
		}
		

		mat rownames mat`repes' = ///
		"Male" "Female" "Total"
		
		mat colnames mat`repes' = ///
		"p1" "p10" "p20" "p30" "p40" "p50" "p60" "p70" ///
		"p80" "p90" "p99"
}


outtable using "${tables}\\descriptive\\teachers\\percentil_rep1", ///
caption("Number of jobs distribution by sex (all jobs)") ///
mat(matrep_total_job)  replace nobox center ///
f(%20.0fc) clabel(t_rep1)

outtable using "${tables}\\descriptive\\teachers\\percentil_rep2", ///
caption("Number of jobs distribution by sex (just teacher jobs)") ///
mat(matn_jobs)  replace nobox center ///
f(%20.0fc) clabel(t_rep2)

g rep4 = rep_total_job
replace rep4 = 16 if rep4>=16
g rep5 = n_jobs
replace rep5 = 16 if rep5>=16

* HIST PLOT
forval i = 1/2{
	local j = `i' + 3
twoway 	(hist rep`j' if sex == 2, freq color(navy%60) width(1)) ///
		(hist rep`j' if sex == 1, freq color(red%60) width(1)), ///
		xtitle(Num. jobs) ///
		legend(order(1 "Female" 2 "Male" )) ///
		ylabel(, format(%20.0fc)) ///
		xlabel(1(3)15)
graph export "${figures}\\descriptive\\teacher_rep\\t_h_freq_`i'.png" , replace
		
twoway (hist rep`j' if sex == 2, percent color(navy%60) width(1)) ///
	   (hist rep`j' if sex == 1, percent color(red%60) width(1)), ///
		xtitle(Num. jobs) ///
		ytitle("%") ///
		legend(order(1 "Female" 2 "Male" )) ///
		ylabel(, format(%20.0fc)) ///
		xlabel(1(3)15) 
graph export "${figures}\\descriptive\\teacher_rep\\t_h_p_`i'.png" , replace

preserve
replace rep`j' = -rep`j' if sex ==2

twoway (hist rep`j' if sex == 2, percent color(navy%60) width(1)) ///
	   (hist rep`j' if sex == 1, percent color(red%60) width(1)), ///
		xtitle(Num. jobs) ///
		ytitle("%") ///
		legend(order(1 "Female" 2 "Male" )) ///
		ylabel(, format(%20.0fc)) 
graph export "${figures}\\descriptive\\teacher_rep\\mixto_t_h_p_`i'.png" , replace
restore
}


*KDENSITY PLOT   
{
twoway 	(kdensity rep_total_job if sex==2 & rep_total_job<22, bwidth(3) ) ///
		(kdensity rep_total_job if sex==1 & rep_total_job<22, bwidth(3) ), ///
ytitle("Density") xtitle("N. of jobs") xlabel( #10)  ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\teacher_rep\\t_rep1.png" , replace


twoway 	(kdensity n_jobs if sex==2 & n_jobs<22, bwidth(3) ) ///
		(kdensity n_jobs if sex==1 & n_jobs<22, bwidth(3) ), ///
ytitle("Density") xtitle("N. of jobs") xlabel( #10)  ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\descriptive\\teacher_rep\\t_re2.png" , replace
}

}

**# 	*PRIMARY/SECONDARY
{
use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	bys curp: egen seqq = seq()
	keep if seqq == 1


*SEXO_CUT-GENDER
	foreach agno in 2016 2024{
	use "${work}\\FONE\\aux_1", clear
	bys curp year : egen seqq = seq()
	keep if seqq == 1
	
	label define primaria 0 "Secondary" 1 "Primary" , replace
	label values primaria primaria
	
	bys primaria:	tab year sex , matcell(mat1)
	
	tab edad_cut  sex if year == `agno' & primaria == 1, matcell(mat1) 
	preserve
	clear
	svmat mat1
	rename (mat11 mat12) (male female)
	g interval = _n - 1
	g total_ = male + female 
	g pmale  = male / total_ * 100
	g pfemale  = female / total_ * 100
	label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
	label values interval edadcut
	
	graph hbar (sum) pfemale pmale ///
	,  over(interval) stack legend(order(1 "Female" 2 "Male" )) ///
	ytitle("%") 
	graph export "${figures}\\Descriptive\\SECONDARY\\teachers\\ratio_edad_sex_`agno'_primary.png" , replace
	restore
	beep
	tab edad_cut sex if year == `agno' & primaria == 0, matcell(mat1) 
	clear
	svmat mat1
	rename (mat11 mat12) (male female)
	g interval = _n - 1
	g total_ = male + female 
	g pmale  = male / total_ * 100
	g pfemale  = female / total_ * 100
	label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
	3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
	label values interval edadcut
	
	graph hbar (sum) pfemale pmale ///
	,  over(interval) stack legend(order(1 "Female" 2 "Male" )) ///
	ytitle("%") 
	graph export "${figures}\\Descriptive\\SECONDARY\\teachers\\ratio_edad_sex_`agno'_secondary.png" , replace
	}
beep


* STATE
{
use "${work}\\FONE\\aux_1.dta", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	

label define primaria 0 "Secondary" 1 "Primary" , replace
label values primaria primaria
	

collapse (first) sex , by(year ef curp primaria) 

foreach prim in 0 1 {
foreach agno in 2016 2024{

		preserve
			keep if year == `agno' & primaria == `prim'
			bys ef: egen freq_h = count(ef) if sex==1
			bys ef: egen freq_m = count(ef) if sex==2
			bys ef: egen freq = count(ef) 
			bys ef: gen ratio_M = freq_m / freq
			bys ef: gen ratio_H = freq_h / freq
			
			graph hbar (max) ratio_M  ratio_H , ///
			over(ef, sort(ratio_M )) stack ///
				legend(order(1 "Female" 2 "Male" )) ytitle("Freq.") 
				
			graph export "${figures}\\descriptive\\SECONDARY\\teachers\\ratio_teacher_state_`agno'_primaria_`prim'.png" , replace
		restore
		}
	}
beep
}

*N REPTS
{
use "${work}\\FONE\\aux_1", clear
	keep if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
	
label define primaria 0 "Secondary" 1 "Primary" , replace
label values primaria primaria
	
bys curp year: egen has_primaria = max(primaria)
bys curp year: egen secundaria = min(primaria)
gen has_secundaria = 0
replace has_secundaria = 1 if secundaria == 0

g primaria_b = .
replace primaria_b = 2 if has_primaria == 1 & has_secundaria == 1
replace primaria_b = 1 if has_primaria == 1 
replace primaria_b = 0 if has_secundaria == 1

preserve
collapse (first) duplicate sex rep_total_job n_jobs primaria_b , by(curp year)


	qui tab year duplicate if sex==2 & primaria_b == 1, matcell(mat1) 
	qui tab year duplicate if sex==1 & primaria_b == 1, matcell(mat2)
 	qui tab year duplicate if sex==2 & primaria_b == 0, matcell(mat3) 
	qui tab year duplicate if sex==1 & primaria_b == 0, matcell(mat4) 
	
mat rep_quart = (mat1 , mat2, mat3 , mat4)
frmttable using "${tables}\\descriptive\\SECONDARY\\repes_sexo", ///
 fragment tex statmat(rep_quart) varlabels replace ///
 sfmt(fc)   sdec(0)  ///
 ctitles("" "" "Primary" "" "" "" "Secondary" "" ///
  \ "" "Female" "" "Male" "" "Female" "" "Male" ///
 \"0" "1" "0" "1" "0" "1" "0" "1" ) 

 
	}
restore
}

**#  	*HOMOCIDES
{
	
use "${work}\FONE\homicidios.dta", clear

collapse (mean) homicidios_xt homicidios_xm homicidios_xh femicidios, by(trimestre)
g homicidios_t = ln(homicidios_xt + 1)
g homicidios_m = ln(homicidios_xm + 1)
g homicidios_h = ln(homicidios_xh + 1)
g femicidios_m = ln(homicidios_xh + 1)

{
preserve

twoway (scatter homicidios_t trimestre) ///
(scatter homicidios_m trimestre) (scatter homicidios_h trimestre) ///
if trimestre>=0 , ///
legend(order(1 "Total per persons" 2 "Female per womans" 3 "Male per mans")) xtitle("Period") ytitle("NL. Homicide per 1000")
graph export "${figures}\\descriptive\\HOMICIDE\\per_sex.png" , replace
	
	
twoway (scatter femicidios_m trimestre) ///
if trimestre>=0 , ///
legend(order(1 "Femicides per woman")) xtitle("Period") ytitle("NL. Homicide per 1000")
graph export "${figures}\\descriptive\\HOMICIDE\\per_femicide_sex.png" , replace
	restore
}	

use "${work}\\FONE\\aux_1.dta", clear
drop p_total_real p_trim_real clave_plaza otro_modelo edad c_tipo 

drop if secc > 1

merge m:1 trimestre cod_muni1 cod_muni2 using "${work}\FONE\homicidios.dta", keep(1 3)


foreach homi in homicidios_xt homicidios_xm homicidios_xh femicidios {
	replace `homi' = 0 if `homi' == .
	replace `homi' = ln(`homi' + 1)
}

sum homicidios_xt homicidios_xm homicidios_xh femicidios

tabstat homicidios_xt homicidios_xm homicidios_xh femicidios, stats(mean sd min p10 med p90 max)

g ind_des2 =ind_des*ind_des
g ind_des3 =ind_des*ind_des*ind_des
g ind_des4 =ind_des*ind_des*ind_des*ind_des


	qui reghdfe duplicate i.sex##c.homicidios_xt ///
i.zona_economica i.rural ind_des ind_des2 ind_des3 ind_des4 i.t_plaza_b ///
if secc==1  & ind_des!=. & t_plaza_b !=2 ///
, a(ef trimestre categoria edad_cut n_categoria) vce(cluster curp)
estimates sto d1


	qui reghdfe duplicate ///
	c.homicidios_xm##sex c.homicidios_xh##sex ///
i.zona_economica i.rural ind_des ind_des2 ind_des3 ind_des4 i.t_plaza_b ///
if secc==1  & ind_des!=. & t_plaza_b !=2 ///
, a(ef trimestre categoria edad_cut n_categoria) vce(cluster curp)
estimates sto d2
beep

esttab h1 h2 d1 d2  using ///
	"${tables}\\descriptive\\HOMICIDE\\est_dup_type.tex" ///
	, se(%5.3fc) mtitles("Total Homicides" "Homicides per gender" "Total Homicides" "Homicides per gender") ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	replace nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt homicidios_xm homicidios_xh ) ///
	title("Estimations on teaching jobs") nonotes


 
	qui reghdfe n_jobs i.sex##c.homicidios_xt ///
i.zona_economica i.rural c.ind_des##c.ind_des i.t_plaza_b ///
if secc==1  & ind_des!=. & t_plaza_b !=2 ///
, a(ef trimestre categoria edad_cut n_categoria) vce(cluster curp)
estimates sto h1
		
	qui reghdfe n_jobs ///
	c.homicidios_xm##sex c.homicidios_xh##sex ///
i.zona_economica i.rural c.ind_des##c.ind_des  i.t_plaza_b ///
if secc==1  & ind_des!=. & t_plaza_b !=2 ///
, a(ef trimestre categoria edad_cut n_categoria) vce(cluster curp)
estimates sto h2

	qui reghdfe n_jobs ///
	c.femicidios##sex ///
i.zona_economica i.rural c.ind_des##c.ind_des  i.t_plaza_b ///
if secc==1  & ind_des!=. & t_plaza_b !=2 ///
, a(ef trimestre categoria edad_cut n_categoria) vce(cluster curp)
estimates sto h3

esttab h1 h2  using ///
	"${tables}\\descriptive\\HOMICIDE\\est_dup_type.tex" ///
	, se(%5.3fc) ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	append nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt homicidios_xm homicidios_xh ) ///
	 nonotes

qui tabstat homicidios_xt if sex == 2 & rural == 0 , stat(mean n) save
mat mat1 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 1 & rural == 0 , stat(mean n) save
mat mat2 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 2 & rural == 1 , stat(mean n) save
mat mat3 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 1 & rural == 1 , stat(mean n) save
mat mat4 = r(StatTotal)' 

mat hom_rur = (mat1, mat2) \ (mat3, mat4)
mat rownames hom_rur = "Urban" "Rural"

frmttable using "${tables}\\descriptive\\HOMICIDE\\mean_by_rural", ///
 fragment tex statmat(hom_rur) varlabels replace ///
 sfmt(fc)   sdec(3,0,3,0)  ///
 ctitles("" "Male" "" "Female" "" ///
  \ "" "Mean" "N" "Mean" "N") 
  
	
	label define primaria 0 "Secondary" 1 "Primary" , replace
	label values primaria primaria
	  
qui tabstat homicidios_xt if sex == 2 & primaria == 1, stat(mean n) save
mat mat1 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 1 & primaria == 1, stat(mean n) save
mat mat2 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 2 & primaria == 0, stat(mean n) save
mat mat3 = r(StatTotal)' 
qui tabstat homicidios_xt if sex == 1 & primaria == 0, stat(mean n) save
mat mat4 = r(StatTotal)' 

mat hom_rur = (mat1, mat2) \ (mat3, mat4)
mat rownames hom_rur = "Primary" "Secondary"

frmttable using "${tables}\\descriptive\\HOMICIDE\\mean_by_instruction", ///
 fragment tex statmat(hom_rur) varlabels replace ///
 sfmt(fc)   sdec(3,0,3,0)  ///
 ctitles("" "Male" "" "Female" "" ///
  \ "" "Mean" "N" "Mean" "N") 

  
 foreach rurali in 0 1{
qui tabstat homicidios_xt ///
if sex == 2 & primaria == 1 & rural==`rurali' , stat(mean n) save
mat mat1 = r(StatTotal)' 
qui tabstat homicidios_xt ///
if sex == 1 & primaria == 1 & rural==`rurali' , stat(mean n) save
mat mat2 = r(StatTotal)' 
qui tabstat homicidios_xt ///
if sex == 2 & primaria == 0 & rural==`rurali' , stat(mean n) save
mat mat3 = r(StatTotal)' 
qui tabstat homicidios_xt ///
if sex == 1 & primaria == 0 & rural==`rurali' , stat(mean n) save
mat mat4 = r(StatTotal)' 

mat hom_`rurali' = (mat1, mat2) \ (mat3, mat4)
mat rownames hom_rur = "Primary" "Secondary"
}

mat hom = hom_0 \ hom_1
mat rownames hom = "Primary" "Secondary" "Primary" "Secondary"

frmttable using "${tables}\\descriptive\\HOMICIDE\\mean_by_instruction_rural", ///
 fragment tex statmat(hom) varlabels replace ///
 sfmt(fc)   sdec(3,0,3,0)  ///
 ctitles("" "Male" "" "Female" "" ///
  \ "" "Mean" "N" "Mean" "N") 
}

**#		*SUMARRY TABLE
{
use "${work}\\FONE\\aux_1.dta", clear


g sexo = 1 if sex == 2
replace sexo = 0 if sexo == .

foreach vari in primaria rural t_plaza sexo {
	replace `vari' = `vari' * 100
}
	
 
	
	
qui tabstat edad primaria  p_trim_real t_plaza rural n_jobs ind_des, by(sex) stats(mean sd p10 p90) save
qui tabstatmat mat1

mat summary = J(7,8,.)

forval i = 1(1)7{
	local auxii = `i' + 7
	mat summary[`i',1] =mat1[`auxii',1]
	mat summary[`i',2] =mat1[`auxii',2] 
	mat summary[`i',3] =mat1[`auxii',3] 
	mat summary[`i',4] =mat1[`auxii',4]
	
	mat summary[`i',5] =mat1[`i',1]
	mat summary[`i',6] =mat1[`i',2]
	mat summary[`i',7] =mat1[`i',3]
	mat summary[`i',8] =mat1[`i',4]
}

mat rownames summary = "Age" "Primary (%)" "Wage per Job" "Full-time (%)" "Rural (%)" "Num of jobs" "Dev index" 


frmttable using "${tables}\\descriptive\\Summary\\Summary_ricardo", ///
 fragment tex statmat(summary) varlabels replace ///
 sfmt(fc)   sdec(2,2,0,0,2,2,0,0)  ///
 ctitles("" "Female" "" "" ""  "Male" "" "" ""  ///
  \ "" "Mean" "SD" "P10" "P90" "Mean" "SD" "P10" "P90" ) 



qui tabstat edad sexo p_trim_real t_plaza rural n_jobs ind_des, by(primaria) stats(mean sd p10 p90) save
tabstatmat mat1

mat summary = J(7,8,.)

forval i = 1(1)7{
	local auxii = `i' + 7
	mat summary[`i',1] =mat1[`auxii',1]
	mat summary[`i',2] =mat1[`auxii',2] 
	mat summary[`i',3] =mat1[`auxii',3] 
	mat summary[`i',4] =mat1[`auxii',4]
	
	mat summary[`i',5] =mat1[`i',1]
	mat summary[`i',6] =mat1[`i',2]
	mat summary[`i',7] =mat1[`i',3]
	mat summary[`i',8] =mat1[`i',4]
}
	
mat rownames summary = "Age" "Female (%)" "Wage per Job" "Full-time (%)" "Rural (%)" "Num of jobs" "Dev index" 
	
frmttable using "${tables}\\descriptive\\Summary\\Summary2_ricardo", ///
 fragment tex statmat(summary) varlabels replace ///
 sfmt(fc)  sdec(2,2,0,0,2,2,0,0)  ///
 ctitles("" "Primary" "" "" ""  "Secondary" "" "" "" ///
  \ "" "Mean" "SD" "P10" "P90" "Mean" "SD" "P10" "P90"  )
	
}	

}

///////////////////////////////////
**# OBSERVATION LEVEL
//////////////////////////////////
clear all
use "${work}\\FONE\\aux_1.dta", clear

drop p_total_real p_trim_real 
drop if year == 2015
drop if edad<22 | edad>65

{
/// Observaciones por zona de trabajo y sexo 
{
bys ef: egen freq_h = count(entidad_federativa) if sex==1
bys ef: egen freq_m = count(entidad_federativa) if sex==2
bys ef: egen freq = count(entidad_federativa) 

graph hbar (mean) freq_m freq_h  , ///
over(ef, sort(freq)) stack ///
legend(order(1 "Female" 2 "Male" )) ytitle("Freq.") ylabel(,format(%20.0fc))
graph export "${figures}\\descriptive\\state_sex.png" , replace

tab ef sex, matcell(mat1)
mat mat2 = J(31,1,.)
mat mat3 = J(31,1,.)
forval fila = 1(1)31{
	mat mat2[`fila',1] = mat1[`fila',1]
	mat mat3[`fila',1] = mat1[`fila',2]
}
mat mat4 = mat2 + mat3
mat mat1 = mat2,mat3,mat4

mat colnames mat1 = "Male" "Female" "Total"
mat rownames mat1 = "AGUASCALIENTES" "BAJA CALIFORNIA" "BAJA CALIFORNIA SUR" ///
"CAMPECHE" "CHIAPAS" "CHIHUAHUA" "COAHUILA" "COLIMA" "DURANGO" "GUANAJUATO" ///
"GUERRERO" "HIDALGO" "JALISCO" "MICHOACÁN" "MORELOS" "MÉXICO" "NAYARIT" ///
"NUEVO LEÓN" "OAXACA" "PUEBLA" "QUERÉTARO" "QUINTANA ROO" ///
"SAN LUIS POTOSÍ" "SINALOA" "SONORA" "TABASCO" "TAMAULIPAS" ///
"TLAXCALA" "VERACRUZ" "YUCATÁN" "ZACATECAS"

outtable using "${tables}\\descriptive\\Observations\\state_sex", ///
caption("Observation by state and sex") mat(mat1) ///
replace nobox center format(%20.0fc) longtable  clabel(obs_state)
}
**
// Observaciones por edad segun sexo
{ 
tab edad sex if sex ==2, matcell(edad_sexo1) 
tab edad sex if sex ==1, matcell(edad_sexo2) 
mat define edad_sexo = edad_sexo1,edad_sexo2

mat totals = J(1,2,.)
forvalues i = 1/2 {
    local sum = 0
    forvalues j = 1/44 {
        local sum = `sum' + edad_sexo[`j', `i']
    }
    matrix totals[1, `i'] = `sum'
}

mat edad_sexo = (edad_sexo \ totals)

local rownames
forvalues i = 22/66 {
    if `i' < 66{
	local rownames `rownames' `i'
	}
	else{
	local rownames `rownames' "Total"	
	}
	}
matrix rownames edad_sexo = `rownames'

mat J = J(45,1,.)
forval j = 1(1)45{
mat J[`j',1] = edad_sexo[`j',1] + edad_sexo[`j',2] 
}
mat edad_sexo = edad_sexo, J
mat colnames edad_sexo = "Female" "Male" "Total"
outtable using "${tables}\\descriptive\\Observations\\edad_sexo", ///
caption("Observation by age and sex") mat(edad_sexo) ///
replace nobox center format(%20.0fc) longtable  clabel(obs_sexo_edad)
}
**
//Observaciones por edad segun sexo y tipo contrato
{ 
	
	*Agno
qui tab year t_plaza if sex == 1, m matcell(mat1) 
qui tab year t_plaza if sex == 2, m matcell(mat2) 
mat plaza_trimestre_sexo = mat2,mat1

mat J = J(9,1,.)
mat H = J(9,1,.)
mat M = J(9,1,.)
forval j = 1(1)9{
mat J[`j',1] = plaza_trimestre_sexo[`j',1] + plaza_trimestre_sexo[`j',2] +  ///
plaza_trimestre_sexo[`j',3] + plaza_trimestre_sexo[`j',4] 
mat H[`j',1] = mat1[`j',1] + mat1[`j',2] 
mat M[`j',1] = mat2[`j',1] + mat2[`j',2] 
}
mat plaza_trimestre_sexo = plaza_trimestre_sexo , J
mat mat1 = mat1 , H
mat mat2 = mat2 , M

mat colnames plaza_trimestre_sexo  =  ///
"Hour" "Position" ///
"Hour" "Position" "Total"

foreach j in mat1 mat2{
mat colnames `j'  =  ///
"Hour" "Position" "Total"
}

foreach j in plaza_trimestre_sexo mat1 mat2{
mat rownames `j'  =  "2016" "2017" "2018" "2019" ///
							"2020" "2021" "2022" "2023" "2024" 
}


frmttable using "${tables}\\descriptive\\Observations\\plaza_trimestre_sexo_agno_all", ///
 fragment tex statmat(plaza_trimestre_sexo) varlabels replace ///
 sfmt(fc)   sdec(0)  ///
 ctitles("" "" "Female" "" "Male" "" ///
 \"" "Part-time" "Full-time" "Part-time" "Full-time" "Total" ) 
	

outtable using "${tables}\\descriptive\\Observations\\plaza_trimestre_sexo", ///
caption("Observations by type of contracts and quarter") ///
mat(plaza_trimestre_sexo)  ///
clabel(obs_contract_quart) replace nobox center format(%20.0fc)

outtable using /// 
"${tables}\\descriptive\\Observations\\plaza_trimestre_male" ///
, caption("Observations by type of contracts and quarter (Male)") ///
mat(mat1)  ///
clabel(obs_contract_quart_male) replace nobox center format(%20.0fc)

outtable using /// 
"${tables}\\descriptive\\Observations\\plaza_trimestre_female" ///
, caption("Observations by type of contracts and quarter (Female)") ///
mat(mat2)  ///
clabel(obs_contract_quart_female) replace nobox center format(%20.0fc)


}
**
// Observaciones por cantidad de repeticiones y sexo
{
qui tab n_jobs sex if n_jobs== 1, matcell(mat1) 
qui tab n_jobs sex if n_jobs== 2, matcell(mat2) 
qui tab n_jobs sex if n_jobs== 3, matcell(mat3) 
qui tab n_jobs sex if n_jobs== 4, matcell(mat4)
qui tab n_jobs sex if n_jobs== 5, matcell(mat5)
qui tab n_jobs sex if n_jobs== 6, matcell(mat6) 
qui tab sex if n_jobs>= 7 & n_jobs<= 8 , matcell(mat7) 
qui tab sex if n_jobs>= 9 & n_jobs<= 10 , matcell(mat8) 
qui tab sex if n_jobs>= 11 & n_jobs<= 15 , matcell(mat9) 
qui tab sex if n_jobs>= 16, matcell(mat10) 


mat rep_sexo_rep = J(10,2,.)
forval i = 1/6{
mat rep_sexo_rep[`i',1] = mat`i'[1,1]
mat rep_sexo_rep[`i',2] = mat`i'[1,2]
}

forval i = 7/10{
mat rep_sexo_rep[`i',1] = mat`i'[1,1]
mat rep_sexo_rep[`i',2] = mat`i'[2,1]
}

mat totals = J(1, 2,.)
forvalues i = 1/2 {
    local sum = 0
    forvalues j = 1/10 {
        local sum = `sum' + rep_sexo_rep[`j', `i']
    }
    matrix totals[1, `i'] = `sum'
}

matrix rep_sexo_rep = (rep_sexo_rep \ totals)

mat j = J(11,1,.)
forval i = 1/11{
	mat j[`i',1]= rep_sexo_rep[`i', 1] +rep_sexo_rep[`i', 2]
}

matrix rep_sexo_rep = rep_sexo_rep, j

matrix rownames rep_sexo_rep = "1" "2" "3" "4" "5" "6" "7-8" "9-10" ///
"11-16" "More than 16" "Total"
matrix colnames rep_sexo_rep = "Male" "Female" "Total"

outtable using "${tables}\\descriptive\\Observations\\rep_sex", ///
caption("Observation by sex and number of repetitions on the same quarter") ///
 mat(rep_sexo_rep) replace nobox center format(%20.0fc)  ///
  clabel(obs_rep_sex)

***************
qui tab duplicate sex, matcell(mat1)
mat totals_v = J(1, 2,.)
forvalues i = 1/2 {
    matrix totals_v[1, `i'] = mat1[1,`i'] + mat1[2,`i']
}

matrix mat1 = (mat1 \ totals_v)

mat j = J(3,1,.)
forval i = 1/3{
	mat j[`i',1]= mat1[`i', 1] + mat1[`i', 2]
}
mat mat1 = mat1, j
mat colnames mat1 = "Male" "Female" "Total"
mat rownames mat1 = "1" "2 or more" "Total"

outtable using "${tables}\\descriptive\\Observations\\rep_sex_dummy", ///
caption("Observation by sex and number of repetitions on the same quarter") mat(mat1) replace ///
nobox center format(%20.0fc) clabel(rep_sex_dummy)
}
**
/// Observaciones por trimestre y tipo de categoria
{
foreach j in 1 2 3 4 5 6 {
qui tab year n_categoria if sex == 1 & n_categoria ==`j', matcell(mat1_`j')
qui tab year n_categoria if sex == 2 & n_categoria ==`j', matcell(mat2_`j')
} 

qui tab trimestre n_categoria if sex == 1 & n_categoria == 7, matcell(mat1_Notreported)
qui tab trimestre n_categoria if sex == 2 & n_categoria ==7, matcell(mat2_Notreported)

foreach matriz in mat1 mat2{
	mat `matriz'_total = `matriz'_1 + `matriz'_2 + `matriz'_3 ///
	+ `matriz'_4 + `matriz'_5 + `matriz'_6  
	
	mat `matriz' = `matriz'_1 , `matriz'_2 , `matriz'_3 ///
 , `matriz'_4 , `matriz'_5 , `matriz'_6  , `matriz'_total
	mat colnames `matriz' =  ///
"07" "7A" "7B" "7C" "7D" "7E" "Total"
	mat rownames `matriz' =  "2016" "2017" "2018" "2019" ///
							"2020" "2021" "2022" "2023" "2024" 
}

outtable using "${tables}\\descriptive\\Observations\\cat_trim_M_dropdup", ///
caption("Male observations by category level and quarter") ///
mat(mat1) replace nobox center format(%20.0fc)  ///
clabel(obs_cat_trim_M)

outtable using "${tables}\\descriptive\\Observations\\cat_trim_F_dropdup", ///
caption("Female observations by category level and quarter") ///
mat(mat2) replace nobox center format(%20.0fc)  ///
clabel(obs_cat_trim_F)

}

/// Observaciones por agno y tipo de educacion (primaria/secundaria)
{
tab year nivel_inst

bys sex: tab year nivel_inst

}

/// Observaciones por agno y ruralidad
{
tab year rural

bys sex: tab year rural
}
}

///////////////////////////////////
**# SUM ON WAGES
//////////////////////////////////

clear all
use "${work}\\FONE\\aux_1.dta", clear


{
	* TOTAL VS PERJOB
	{
	tabstat p_total_real if  secc == 1, stats(mean sd n) by( sex ) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_trim_real, stats(mean sd n) by(sex) format(%20.2fc) save
	tabstatmat mat2
	
	mat total_vs_trimestral = mat2, mat1
	mat colnames total_vs_trimestral= "Per Job: Mean" "Per Job: SD" "Per Job: N" ///
	"Total wage: Mean" "Total wage: SD" "Total wage: N" 
	
	mat rownames total_vs_trimestral= "Male" "Female" "Total"

	outtable using "${tables}\\descriptive\\Income_sum\\total_vs_trimestral", ///
caption("Average wage by sex and variable construction") ///
mat(total_vs_trimestral)  replace nobox center ///
f(%20.2fc %20.2fc %20.0fc %20.2fc %20.2fc %20.0fc) ///
clabel(total_vs_trimestral)
	}

	* TOTAL VS PERJOB BY SECONDARY
	{
	tabstat p_total_real if secc == 1 & primaria == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat11
	
	tabstat p_total_real if secc == 1 & primaria == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat12
	
	
	tabstat p_trim_real if primaria == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat21
	
	tabstat p_trim_real if primaria == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat22
	
	
	mat total_vs_trimestral = (mat11, mat12) \ (mat21, mat22) 
	
	mat rownames total_vs_trimestral= "Male" "Female" "Total" "Male" "Female" "Total"
	 matrix roweq  total_vs_trimestral = ""
	 
	 frmttable using "${tables}\\descriptive\\SECONDARY\\WAGE\\sum_totvstrim", ///
	fragment tex statmat(total_vs_trimestral) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Primary" ""  "Secondary" ///
	\"Mean" "N" "Mean" "N") 
	
	
	}
	
	* TOTAL VS PERJOB and year
	{
	forval j = 2016(1)2024{
	tabstat p_total_real if secc == 1 & year == `j' & sex == 2, ///
	stats(mean sd n) format(%20.2fc) save
	tabstatmat matM`j'
	
	tabstat p_total_real if secc == 1 & year == `j' & sex == 1, ///
	stats(mean sd n) format(%20.2fc) save
	tabstatmat matH`j'
	}
	
	mat define totalvsjob_agno = J(18,3,.)
	forval i = 1(1)3{
	mat totalvsjob_agno[1,`i'] = matM2016[`i',1]
	mat totalvsjob_agno[2,`i'] = matM2017[`i',1]
	mat totalvsjob_agno[3,`i'] = matM2018[`i',1]
	mat totalvsjob_agno[4,`i'] = matM2019[`i',1]
	mat totalvsjob_agno[5,`i'] = matM2020[`i',1]
	mat totalvsjob_agno[6,`i'] = matM2021[`i',1]
	mat totalvsjob_agno[7,`i'] = matM2022[`i',1]
	mat totalvsjob_agno[8,`i'] = matM2023[`i',1]
	mat totalvsjob_agno[9,`i'] = matM2024[`i',1]
	mat totalvsjob_agno[10,`i'] = matH2016[`i',1]
	mat totalvsjob_agno[11,`i'] = matH2017[`i',1]
	mat totalvsjob_agno[12,`i'] = matH2018[`i',1]
	mat totalvsjob_agno[13,`i'] = matH2019[`i',1]
	mat totalvsjob_agno[14,`i'] = matH2020[`i',1]
	mat totalvsjob_agno[15,`i'] = matH2021[`i',1]
	mat totalvsjob_agno[16,`i'] = matH2022[`i',1]
	mat totalvsjob_agno[17,`i'] = matH2023[`i',1]
	mat totalvsjob_agno[18,`i'] = matH2024[`i',1]
	}
	
	
	
	forval j = 2016(1)2024{
		tabstat p_trim_real if year == `j' & sex == 2, ///
	stats(mean sd n) format(%20.2fc) save
	tabstatmat matM`j'
	
		tabstat p_trim_real if year == `j' & sex == 1, ///
	stats(mean sd n) format(%20.2fc) save
	tabstatmat matH`j'
	}
	
	mat define totalvsjob_agno_trim = J(18,3,.)
	forval i = 1(1)3{    
	mat totalvsjob_agno_trim[1,`i'] = matM2016[`i',1]
	mat totalvsjob_agno_trim[2,`i'] = matM2017[`i',1]
	mat totalvsjob_agno_trim[3,`i'] = matM2018[`i',1]
	mat totalvsjob_agno_trim[4,`i'] = matM2019[`i',1]
	mat totalvsjob_agno_trim[5,`i'] = matM2020[`i',1]
	mat totalvsjob_agno_trim[6,`i'] = matM2021[`i',1]
	mat totalvsjob_agno_trim[7,`i'] = matM2022[`i',1]
	mat totalvsjob_agno_trim[8,`i'] = matM2023[`i',1]
	mat totalvsjob_agno_trim[9,`i'] = matM2024[`i',1]
	mat totalvsjob_agno_trim[10,`i'] = matH2016[`i',1]
	mat totalvsjob_agno_trim[11,`i'] = matH2017[`i',1]
	mat totalvsjob_agno_trim[12,`i'] = matH2018[`i',1]
	mat totalvsjob_agno_trim[13,`i'] = matH2019[`i',1]
	mat totalvsjob_agno_trim[14,`i'] = matH2020[`i',1]
	mat totalvsjob_agno_trim[15,`i'] = matH2021[`i',1]
	mat totalvsjob_agno_trim[16,`i'] = matH2022[`i',1]
	mat totalvsjob_agno_trim[17,`i'] = matH2023[`i',1]
	mat totalvsjob_agno_trim[18,`i'] = matH2024[`i',1]
	}
	
	mat totalvsjob_agno = totalvsjob_agno_trim , totalvsjob_agno
	mat rownames totalvsjob_agno= ///
	"2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" "2024" ///
	"2016" "2017" "2018" "2019" "2020" "2021" "2022" "2023" "2024"
	
	frmttable using "${tables}\\descriptive\\\\Income_sum\\totalvstrimestre_agno", ///
 fragment tex statmat(totalvsjob_agno) varlabels replace ///
 sfmt(fc)   sdec(2)  ///
 ctitles("" "" "Wages per job" "" "" "Total earnings" ""  ///
 \"" "Mean" "SD" "N" "Mean" "SD" "N") 
	}
	
	* TOTAL BY SEX AND AGE
	{
	qui tabstat p_total_real if sex==1 & sec == 1, stats(mean sd n) by( edad ) save format(%20.2fc)
	tabstatmat perc_age_h

	qui tabstat p_total_real if sex==2 & sec == 1, stats(mean sd n) by( edad ) save format(%20.2fc)
	tabstatmat perc_age_m 
	
	mat perc_age = perc_age_m, perc_age_h 
	mat j = J(45,1,.)
	forval i = 1/45{
		mat j[`i',1] = perc_age_m[`i',1]  - perc_age_h[`i',1] 
	local auxili = `i' + 21
	*if `i'<45{
	*qui ttest p_total_real if sec == 1 & edad== `auxili', by( sexo )
	*}
	*else{
	*qui ttest p_total_real if sec == 1, by( sexo )	
	*}	
	*	mat j[`i',2] = e(p)	
	*	dis `i' `auxili'
	}

	local rownames
forvalues i = 22/65 {
	local rownames `rownames' `i'
	}
	local rownames `rownames' "Total"
matrix rownames perc_age = `rownames'
	
	mat perc_age = perc_age , j
	
	*frmttable using "${tables}\\descriptive\\Income_sum\\prueba", ///
	*fragment tex statmat(perc_age) replace ///
	*ctitles("" "" "Male" "" "" "Female" "" "Total" "" \ "" "Mean" "SD" "N" "Mean" "SD" "N" "Difference" )  ///
	*title("Average wage by age and sex")

	
matrix colnames perc_age = "Mean" "SD" "N"  ///
"Mean" "SD" "N" "Difference"
	 matrix roweq perc_age = ""

	 
	 
	outtable using "${tables}\\descriptive\\Income_sum\\age_sex", ///
	caption("") mat(perc_age) ///
	longtable replace nobox center ///
	clabel(wage_age_sex) ///
	f(%20.2fc %20.2fc %20.0fc %20.2fc %20.2fc %20.0fc %20.2fc ) 
	
	}
	**

	*Total by sex and state 
	{
	qui tabstat p_total_real if secc == 1 & sex == 1, stats(mean sd) save by(ef) format(%20.2f)
	tabstatmat perc_tot_map_H
	qui tabstat p_total_real if secc == 1 & sex == 2, stats(mean sd) save by(ef) format(%20.2f)
	tabstatmat perc_tot_map_M
	
	mat perc_tot_map = perc_tot_map_M, perc_tot_map_H
	
	putexcel set "C:\Users\56966\Dropbox\Gender_Teachers\data\work\Mexico_map\mexican-states-master\datos", replace // Esto es para hacer el mapa en R
	putexcel B2 = matrix(perc_tot_map)  
	
	
	qui tabstat p_total_real if secc == 1, stats(mean sd n) save by(duplicate) format(%20.2f)
	tabstatmat perc_tot_repet_Q 
	mat rownames perc_tot_repet_Q = "1" "2 or more" "Total"
	matrix roweq perc_tot_repet_Q  = ""
	
	outtable using "${tables}\\descriptive\\Income_sum\\rep_wage", ///
	caption("Average wage by number of repetitions on the same quarter") mat(perc_tot_repet_Q)  ///
	replace nobox center clabel(wage_rep_sex) ///
	f(%20.2fc %20.2fc %20.0fc)
	}
		
	*Per wage by sex and state 
	{
	qui tabstat p_trim_real if secc == 1 & sex == 1, stats(mean sd) save by(entidad_federativa) format(%20.2f)
	tabstatmat perc_trim_map_H
	qui tabstat p_trim_real if secc == 1 & sex == 2, stats(mean sd) save by(entidad_federativa) format(%20.2f)
	tabstatmat perc_trim_map_M
	
	mat perc_trim_map = perc_trim_map_M, perc_trim_map_H
	
	putexcel set "C:\Users\56966\Dropbox\Gender_Teachers\data\work\Mexico_map\mexican-states-master\datos", modify // Esto es para hacer el mapa en R
	putexcel F2 = matrix(perc_trim_map)  
	
	
	qui tabstat p_total_real if sec == 1, stats(mean sd n) save by(duplicate) format(%20.2f)
	tabstatmat perc_tot_repet_Q 
	mat rownames perc_tot_repet_Q = "1" "2 or more" "Total"
	matrix roweq perc_tot_repet_Q  = ""
	
	outtable using "${tables}\\descriptive\\Income_sum\\rep_wage", ///
	caption("Average wage by number of repetitions on the same quarter") mat(perc_tot_repet_Q)  ///
	replace nobox center clabel(wage_rep_sex) ///
	f(%20.2fc %20.2fc %20.0fc)
	}
	
	** TOTAL BY CATEGORY
	{
preserve
keep if secc == 1
	
	tabstat p_total_real if sex ==1, stats(mean sd n) ///
		by(n_categoria) m save format(%20.2f)
		tabstatmat perc_t_ncat_H
		
	tabstat p_total_real if sex ==2, stats(mean sd n) ///
		by(n_categoria) m save format(%20.2f)
		tabstatmat perc_t_ncat_M
		
mat perc_t_ncat = perc_t_ncat_M, perc_t_ncat_H
	mat j = J(7,1,.)
	forval i = 1/7{
	    mat j[`i',1] = perc_t_ncat[`i',1] - perc_t_ncat[`i',4] 
	}
mat perc_t_ncat = perc_t_ncat , j

	mat rownames perc_t_ncat = "07" "7A" "7B" "7C" "7D" "7E" "Total"
	mat colnames perc_t_ncat = "Mean" "SD" "N" "Mean" "SD" "N" "Difference"
	matrix roweq perc_t_ncat  = ""
	
frmttable using "${tables}\\descriptive\\CALIDAD\\cat_tot_wage", ///
 fragment tex statmat(perc_t_ncat) varlabels replace ///
 sfmt(fc)   sdec(0)  ///
 ctitles("" ""  "Female" "" "" "Male" ""  "" ///
 \"" "Mean" "SD" "N" "Mean" "SD" "N" "Difference")
	
	restore	
}

	** TRIM REAL BY CATEGORY
	{
	tabstat p_trim_real if sex == 1, stats(mean sd n) save ///
		by(n_categoria) m format(%20.2f)
		tabstatmat perc_trim_ncat_H
		
	tabstat p_trim_real if sex == 2, stats(mean sd n) save ///
		by(n_categoria) m format(%20.2f)
		tabstatmat perc_trim_ncat_M
		
mat perc_t_ncat = perc_trim_ncat_M , perc_trim_ncat_H
	mat j = J(7,1,.)
	forval i = 1/7{
	    mat j[`i',1] = perc_t_ncat[`i',1] - perc_t_ncat[`i',4] 
	}
mat perc_t_ncat = perc_t_ncat , j

	mat rownames perc_t_ncat = "07" "7A" "7B"  "7C" "7D" "7E"  "Total"
	mat colnames perc_t_ncat = "Mean" "SD" "N" "Mean" "SD" "N" "Difference"
	matrix roweq perc_t_ncat  = ""
outtable using "${tables}\\descriptive\\Income_sum\\cat_trim_wage", ///
	caption("Average wage per job by category level and sex") ///
	mat(perc_t_ncat)  ///
	replace nobox center clabel(wage_cat_trime_sex) ///
	f(%20.2fc %20.2fc %20.0fc %20.2fc %20.2fc %20.0fc %20.2fc)
	}

	**TOTAL BY TYPE OF CONTRACT AND SECONDARY
	{
	tabstat p_total_real if secc == 1 & primaria == 1 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_total_real if secc == 1 & primaria == 0 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat2
	
	tabstat p_total_real if secc == 1 & primaria == 1 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat3
	
	tabstat p_total_real if secc == 1 & primaria == 0 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat4
	
	mat total_type_secondary = (mat1, mat2) \ (mat3, mat4) 
	
	mat rownames total_type_secondary= "Male" "Female" "Total" "Male" "Female" "Total"
	matrix roweq  total_type_secondary = ""
	
	frmttable using "${tables}\\descriptive\\SECONDARY\\WAGE\\total_type_secondary", ///
	fragment tex statmat(total_type_secondary) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Primary" ""  "Secondary" ///
	\"" "Mean" "N" "Mean" "N") 
	}
	
	{
	tabstat p_trim_real if primaria == 1 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_trim_real if nivel_inst == 3 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat2
	
	tabstat p_trim_real if nivel_inst == 2 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat3
	
	tabstat p_trim_real if nivel_inst == 3 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat4
	
	mat trim_type_secondary = (mat1, mat2) \ (mat3, mat4) 
	
	mat rownames trim_type_secondary= "Male" "Female" "Total" "Male" "Female" "Total"
	matrix roweq  trim_type_secondary = ""
	 
	 frmttable using "${tables}\\descriptive\\SECONDARY\\WAGE\\trim_type_secondary", ///
	fragment tex statmat(trim_type_secondary) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Primary" ""  "Secondary" ///
	\"" "Mean" "N" "Mean" "N") 
	}
	
	**TOTAL BY RURALITY 
	{
	tabstat p_total_real if secc == 1 & rural == 0 , stats(mean n) by( sex) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_total_real if secc == 1 & rural == 1 , stats(mean n) by( sex) format(%20.2fc) save
	tabstatmat mat2
	
	tabstat p_trim_real if rural == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat3
	
	tabstat p_trim_real if rural == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat4
	
	mat total_vs_trimestral = (mat1, mat2) \ (mat3, mat4) 
	
	mat rownames total_vs_trimestral= "Male" "Female" "Total" "Male" "Female" "Total"
	 matrix roweq  total_vs_trimestral = ""
	 
	 frmttable using "${tables}\\descriptive\\RURAL\\sum_totvstrim_rural", ///
	fragment tex statmat(total_vs_trimestral) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Urban" ""  "Rural" ///
	\"Mean" "N" "Mean" "N") 	
	}
	
	**TOTAL BY RURALITY AND TYPE OF CONTRACT
	{
		{
	tabstat p_total_real if secc == 1 & rural == 0 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_total_real if secc == 1 & rural == 1 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat2
	
	tabstat p_total_real if secc == 1 & rural == 0 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat3
	
	tabstat p_total_real if secc == 1 & rural == 1 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat4
	
	mat total_type_secondary = (mat1, mat2) \ (mat3, mat4) 
	
	mat rownames total_type_secondary= "Male" "Female" "Total" "Male" "Female" "Total"
	matrix roweq  total_type_secondary = ""
	
	frmttable using "${tables}\\descriptive\\RURAL\\total_type_rural", ///
	fragment tex statmat(total_type_secondary) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Urban" ""  "Rural" ///
	\"" "Mean" "N" "Mean" "N") 
	}
	
	{
	tabstat p_trim_real if rural == 0 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat1
	
	tabstat p_trim_real if rural == 1 & t_plaza_b == 0 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat2
	
	tabstat p_trim_real if rural == 0 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat3
	
	tabstat p_trim_real if rural == 1 & t_plaza_b == 1 , stats(mean n) by( sex ) format(%20.2fc) save
	tabstatmat mat4
	
	mat trim_type_secondary = (mat1, mat2) \ (mat3, mat4) 
	
	mat rownames trim_type_secondary= "Male" "Female" "Total" "Male" "Female" "Total"
	matrix roweq  trim_type_secondary = ""
	 
	 frmttable using "${tables}\\descriptive\\RURAL\\trim_type_secondary", ///
	fragment tex statmat(trim_type_secondary) varlabels replace ///
	sfmt(fc)   sdec(0)  ///
	ctitles(""  "Urban" ""  "Rural" ///
	\"" "Mean" "N" "Mean" "N") 
	}
	
	}
	
	}

***************************************************** 
**# REGRESIONES
*****************************************************


*** 
{
	*** DF PREPARATION
{
clear all
use "${work}\\FONE\\aux_1.dta", clear

gen core = 1 if categoria =="E0281"|categoria == "E0363"|categoria == "E365" |categoria =="E0461" |categoria =="E0463" |categoria =="E0465"  |categoria =="E2781"
replace core = 0 if core == .
bys curp: egen max_core = max(core)
keep if max_core == 1

merge m:1 clave_centro_trabajo using "${work}\FONE\aux_school.dta", keepusing(cv_tipo) generate(_mergex)
keep if cv_tipo == "ESCUELA"
drop secc cv_tipo max_core

gsort curp trimestre -core -p_trim_real
bys curp trimestre: egen secc = seq() 
			
bys curp trimestre: egen wage_core = total(p_trim_real) if core == 1
g ln_wage_core = ln(wage_core)			

foreach j in rural{
	replace `j' = 0 if `j' == .
}

label define otrom 0 "Don't have" 1 "Other" 3 "Director" 7 "Administrative", replace
label values otro_modelo otrom

label define tplaza 0 "Part-time" 1 "Full-time", replace
label values t_plaza tplaza
label define tplaza2 0 "Part-time" 1 "Full-time" 2 "Both", replace
label values t_plaza_b tplaza2
label define rural 0 "Urban" 1 "Rural" , replace
label values rural rural
label define economic_zone 0 "" 3 "Vulnerable" , replace
label values zona_economica economic_zone

g ln_trim = ln(p_trim_real)
g ln_total = ln(p_total_real) 

g dup_total = 0
replace dup_total = 1 if rep_total_job > 0
replace rep_total_job = rep_total_job + 1
keep ln_trim ln_total edad_cut n_categoria t_plaza t_plaza_b ef trimestre curp sex instruction_level duplicate trime year rural cod_muni1 cod_muni2 zona_economica categoria secc clave_centro_trabajo primaria ind_des dup_total rep_total_job n_jobs core ln_wage_core

compress

merge m:1 trimestre cod_muni1 cod_muni2 using "${work}\FONE\homicidios.dta", keep(3)
drop homicidios_xm homicidios_xh femicidios _merge

replace homicidios_xt = 0 if homicidios_xt  == .

merge m:1 trimestre curp using "${work}\FONE\aux_wage.dta", keep(3)

duplicates tag curp trimestre if core == 1, gen(core_rep)
g dup_core = 0 if core_rep == 0
replace dup_core = 1 if dup_core == .
replace core_rep = core_rep + 1

}
	
	** NORMAL
{
		** LN TRIM CORE TEACHING
		{
	
**PRIMARY
qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 & core == 1, ///
a(ef trimestre) vce(cluster curp)
estimate sto trim1

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 & core == 1, ///
a(ef trimestre edad_cut) vce(cluster curp)
estimate sto trim2

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 & core == 1, ///
a(ef trimestre edad_cut categoria) vce(cluster curp)
estimate sto trim3

qui reghdfe ln_trim  i.sex i.zona_economica ///
if ind_des!=. & primaria ==1 & core == 1, ///
 a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto trim4

qui reghdfe ln_trim ///
i.sex i.zona_economica ///
if ind_des!=. & primaria ==1 & core == 1, ///
  a(ef trimestre edad_cut categoria n_categoria) vce(cluster curp)
estimates sto trim5

	esttab trim1 trim2 trim3 trim4 trim5 using "${tables}\\estimations\\new_trim_core.tex",  ///
 mtitles("" ""  ""  ""  "" ) ///
 se(%20.3fc) keep(2.sex ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  replace  nogaps   b(%20.3fc) noomitted  nobaselevels nonotes ///
	title("Regression on natural logarithm of wage per job by instruction level (CORE Teaching Jobs)")

**SECUNDARY
qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre) vce(cluster curp)
estimate sto trim1

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut) vce(cluster curp)
estimate sto trim2

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria) vce(cluster curp)
estimate sto trim3

qui reghdfe ln_trim  i.sex i.zona_economica ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto trim4

qui reghdfe ln_trim ///
i.sex i.zona_economica ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria n_categoria) vce(cluster curp)
estimates sto trim5

	esttab trim1 trim2 trim3 trim4 trim5 using "${tables}\\estimations\\new_trim_core.tex",  ///
 nomtitles ///
 se(%20.3fc) keep(2.sex ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  append  nogaps   b(%20.3fc) noomitted  nobaselevels nonotes 
	 
	}

		** LN TRIM TEACHING
		{
	
**PRIMARY
qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 , ///
a(ef trimestre) vce(cluster curp)
estimate sto trim1

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 , ///
a(ef trimestre edad_cut) vce(cluster curp)
estimate sto trim2

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==1 , ///
a(ef trimestre edad_cut categoria) vce(cluster curp)
estimate sto trim3

qui reghdfe ln_trim  i.sex i.zona_economica ///
if ind_des!=. & primaria ==1 , ///
 a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto trim4

qui reghdfe ln_trim ///
i.sex i.zona_economica ///
if ind_des!=. & primaria ==1 , ///
 a(ef trimestre edad_cut categoria n_categoria) vce(cluster curp)
estimates sto trim5

	esttab trim1 trim2 trim3 trim4 trim5 using "${tables}\\estimations\\new_trim_notcore.tex",  ///
 mtitles("" ""  ""  ""  "" ) ///
 se(%20.3fc) keep(2.sex ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  replace  nogaps   b(%20.3fc) noomitted  nobaselevels nonotes ///
	title("Regression on natural logarithm of wage per job by instruction level (Teaching Jobs)")

**SECUNDARY
qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre) vce(cluster curp)
estimate sto trim1

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut) vce(cluster curp)
estimate sto trim2

qui reghdfe ln_trim i.sex ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria) vce(cluster curp)
estimate sto trim3

qui reghdfe ln_trim  i.sex i.zona_economica ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto trim4

qui reghdfe ln_trim ///
i.sex i.zona_economica ///
if ind_des!=. & primaria ==0 & core == 1, ///
a(ef trimestre edad_cut categoria n_categoria) vce(cluster curp)
estimates sto trim5

	esttab trim1 trim2 trim3 trim4 trim5 using "${tables}\\estimations\\new_trim_notcore.tex",  ///
 nomtitles ///
 se(%20.3fc) keep(2.sex ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  append  nogaps   b(%20.3fc) noomitted  nobaselevels nonotes 
	 
	}

		** DUP TEACHING JOBS
		{
			
	**** PRIMARY
qui reg duplicate i.sex if secc==1 & ind_des!=. & primaria == 1 ///
, vce(cluster curp)
estimate sto dup1

qui reghdfe duplicate i.sex ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto dup2

qui reghdfe duplicate i.sex ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup3

qui reghdfe duplicate ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup4

qui reghdfe duplicate ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto dup5

	esttab dup1 dup2 dup3 dup4 dup5 using "${tables}\\estimations\\new_dup_teachers.tex", ///
mtitles("" "" "" "") ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
replace nogaps  b(%20.3fc) noomitted nobaselevels ///
	title("Regression on having more than 1 teaching job")
	

	*** SECONDARY
qui reg duplicate i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, vce(cluster curp)
estimate sto dup1

qui reghdfe duplicate i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto dup2

qui reghdfe duplicate i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup3

qui reghdfe duplicate ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup4

qui reghdfe duplicate ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto dup5

	esttab dup1 dup2 dup3 dup4 dup5 using "${tables}\\estimations\\new_dup_teachers.tex", ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
append nogaps  b(%20.3fc) noomitted nobaselevels 
	
	
		}

		** DUP CORE JOBS
		{
		
	**** PRIMARY
qui reg dup_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, vce(cluster curp)
estimate sto dup1

qui reghdfe dup_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto dup2

qui reghdfe dup_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup3

qui reghdfe dup_core ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup4

qui reghdfe dup_core ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto dup5

	esttab dup1 dup2 dup3 dup4 dup5 using "${tables}\\descriptive\\Regresiones\\new_dup_cut.tex", ///
mtitles("" "" "" "") ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
replace nogaps  b(%20.3fc) noomitted nobaselevels ///
	title("Regression on having more than 1 job")
	

	*** SECONDARY
qui reg dup_core i.sex if secc==1 & ind_des!=. & primaria == 0 ///
, vce(cluster curp)
estimate sto dup1

qui reghdfe dup_core i.sex if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto dup2

qui reghdfe dup_core i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup3

qui reghdfe dup_core ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto dup4

qui reghdfe dup_core ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto dup5

	esttab dup1 dup2 dup3 dup4 dup5 using "${tables}\\descriptive\\Regresiones\\new_dup_cut.tex", ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
append nogaps  b(%20.3fc) noomitted nobaselevels 
	
	
		}
		
		** LN TOT TEACHING
		{	
**** PRIMARY
qui reg ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 1 ///
, vce(cluster curp)
estimate sto tot1

qui reghdfe ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto tot2

qui reghdfe ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot3

qui reghdfe ln_total ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot4

qui reghdfe ln_total ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto tot5

	esttab tot1 tot2 tot3 tot4 tot5 using "${tables}\\estimations\\new_total_teaching.tex", ///
mtitles("" "" "" "") ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
replace nogaps  b(%20.3fc) noomitted nobaselevels ///
	title("Regression on total earnings")
	

	*** SECONDARY
qui reg ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, vce(cluster curp)
estimate sto tot1

qui reghdfe ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto tot2

qui reghdfe ln_total i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot3

qui reghdfe ln_total ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot4

qui reghdfe ln_total ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto tot5

	esttab tot1 tot2 tot3 tot4 tot5 using "${tables}\\estimations\\new_total_teaching.tex", ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
append nogaps  b(%20.3fc) noomitted nobaselevels 
	}
		
		** LN TOT CORE TEACHING
		{	
			
**** PRIMARY
qui reg ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, vce(cluster curp)
estimate sto tot1

qui reghdfe ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto tot2

qui reghdfe ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot3

qui reghdfe ln_wage_core ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot4

qui reghdfe ln_wage_core ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 1 & core == 1 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto tot5

	esttab tot1 tot2 tot3 tot4 tot5 using "${tables}\\estimations\\new_total_core.tex", ///
mtitles("" "" "" "") ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
replace nogaps  b(%20.3fc) noomitted nobaselevels ///
	title("Regression on total earnings")
	

	*** SECONDARY
qui reg ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, vce(cluster curp)
estimate sto tot1

qui reghdfe ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut ) vce(cluster curp)
estimate sto tot2

qui reghdfe ln_wage_core i.sex ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot3

qui reghdfe ln_wage_core ///
i.sex i.zona_economica ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre edad_cut categoria ) vce(cluster curp)
estimates sto tot4

qui reghdfe ln_wage_core ///
i.sex i.zona_economica i.n_categoria ///
if secc==1 & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut) vce(cluster curp)
estimates sto tot5

	esttab tot1 tot2 tot3 tot4 tot5 using "${tables}\\estimations\\new_total_core.tex", ///
stats(N, fmt(%20.0fc) labels("Obs."))  label ///
se(%20.3fc) nonotes keep(2.sex) ///
append nogaps  b(%20.3fc) noomitted nobaselevels 
	}

		
}
	
	** BY INSTRUCTION LEVEL
	{
		
		** LN TOT
		{	

		g ln_alljobs = ln(percepciones_totales_alljobs)
drop percepciones_totales_alljobs

qui reghdfe ln_wage_core ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot1

qui reghdfe ln_total ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot2

qui reghdfe  ln_alljobs ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot3

qui reghdfe ln_wage_core ///
i.sex ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot4

qui reghdfe ln_total ///
i.sex ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot5

qui reghdfe ln_alljobs ///
i.sex  ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto tot6
		 
	 

	}
			
		** DUP
		{
			

qui reghdfe dup_core ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup1			

qui reghdfe duplicate ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup2

qui reghdfe dup_total ///
i.sex ///
if secc==1  & primaria == 1 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup3

qui reghdfe duplicate ///
i.sex ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup4

qui reghdfe dup_total ///
i.sex  ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup5

qui reghdfe dup_core ///
i.sex ///
if secc==1  & primaria == 0 & ind_des!=. ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) vce(cluster curp)
estimates sto dup6

esttab tot1 tot2 tot3 dup1 dup2 dup3 using "${tables}\\estimations\\primary\\sum_cut.tex",  ///
 mtitles("CORE Teaching jobs" "Teaching jobs" "All jobs") ///
 se(%20.3fc) keep(2.sex ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  replace  nogaps  b(%20.3fc) noomitted  nobaselevels nonotes ///
	title("Estimated results by instruction level" )
	
	esttab tot4 tot5 tot6 dup4 dup5 dup6 using "${tables}\\estimations\\primary\\sum_cut.tex",  ///
 se(%20.3fc)  ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  append  nogaps  b(%20.3fc) noomitted  nobaselevels nonotes 
	 beep
		
		}
	
	}
		
	** WITH DISTANCE & HOMICIDE & DEV. INDEX
	{
		
		drop _merge
		merge m:1 clave_centro_trabajo using "C:\Users\56966\Dropbox\Gender_Teachers\data\work\FONE\mejores_colegios.dta", force	
		keep if _merge == 3
		
		g ind_des2 = ind_des *ind_des
		g ind_des3 = ind_des * ind_des * ind_des
		g ind_des4 = ind_des * ind_des * ind_des * ind_des
		
		
		** DUP WITH HOMICIDES
		{
		
qui reghdfe dup_core i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d1

		
qui reghdfe duplicate i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d2

qui reghdfe dup_total i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=.  & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica ) ///
vce(cluster curp)
estimates sto d3


qui reghdfe core_rep i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h1


qui reghdfe n_jobs i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h2
 

qui reghdfe rep_total_job i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h3
			
esttab h1 h2 h3 d1 d2 d3 using ///
	"${tables}\\descriptive\\HOMICIDE\\est_dup_type.tex" ///
	, se(%5.3fc) ///
	mtitles("Teaching Jobs" "All Jobs" "Teaching Jobs" "All Jobs") ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	replace nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt ) ///
	title("Estimations on teaching jobs") nonotes

		
qui reghdfe dup_core i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d1

		
qui reghdfe duplicate i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d2

qui reghdfe dup_total i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=.  & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica ) ///
vce(cluster curp)
estimates sto d3


qui reghdfe core_rep i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h1


qui reghdfe n_jobs i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h2
 

qui reghdfe rep_total_job i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto h3

esttab h1 h2 h3 d1 d2 d3 using ///
	"${tables}\\descriptive\\HOMICIDE\\est_dup_type.tex" ///
	, se(%5.3fc) ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	append nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt ) nonotes


	
		}

		** DISTANCE TO SCHOOL WITH BEST AV. WAGE
		{

qui reghdfe distance_p i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d1


qui reghdfe distance_t i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d2
			
esttab d1 d2 using ///
	"${tables}\\descriptive\\HOMICIDE\\DISTANCE_to_best.tex" ///
	, se(%5.3fc) ///
	mtitles("" "" ) ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	replace nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt ) ///
	title("Estimations on Distance to School with Best Salary") ///
	nonotes

		
qui reghdfe dist_to_center i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 1 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d1

qui reghdfe dist_to_center i.sex##c.homicidios_xt ///
ind_des ind_des2 ind_des3 ind_des4 ///
if secc==1  & ind_des!=. & primaria == 0 ///
, a(ef trimestre categoria edad_cut n_categoria zona_economica) ///
 vce(cluster curp)
estimates sto d2

esttab d1 d2 using ///
	"${tables}\\descriptive\\HOMICIDE\\DISTANCE_to_mun.tex" ///
	, se(%5.3fc) ///
	mtitles("" "" ) ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	replace nogaps  b(%20.3fc) nobaselevels ///
	keep(2.sex* homicidios_xt ) ///
	title("Estimations on Distance to Municipality Center") nonotes
		}

		
		
		** LN TOT
		{	

qui reghdfe ln_total i.sex##c.distance_p i.rural ///
if secc==1 & cal!=.  ///
, a(ef trimestre edad_cut categoria n_categoria zona_economica) vce(cluster curp)
estimate sto tot1

qui reghdfe ln_total i.sex##c.distance_p i.rural ///
if secc==1 & primaria == 1 & cal!=. ///
, a(ef trimestre edad_cut categoria zona_economica n_categoria) vce(cluster curp)
estimate sto tot2

qui reghdfe ln_total i.sex##c.distance_p i.rural ///
if secc==1 & primaria == 0 & cal!=., ///
a(ef trimestre edad_cut categoria n_categoria zona_economica) vce(cluster curp)
estimate sto tot3
		
	esttab tot1 tot2 tot3 using "${tables}\\estimations\\distance_bs\\totales_cut.tex",  ///
 mtitles("All Sample" "Only Primary" "Only Secondary") ///
 se(%20.3fc) keep(2.sex* distance_p ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  replace  nogaps  b(%20.3fc) noomitted  nobaselevels nonotes ///
	title("Estimations with Distance to Best School" )
	
	
	 
	 

	}
		
		** LN TRIM
		{
			
qui reghdfe ln_trim ///
i.sex##c.distance_p i.rural if ///
 cal!=., ///
 a(ef trimestre edad_cut categoria zona_economica n_categoria) vce(cluster curp)
estimates sto trim1		
			
qui reghdfe ln_trim ///
i.sex##c.distance_p i.rural if primaria == 1 ///
 & cal!=., a(ef trimestre edad_cut categoria zona_economica n_categoria ) vce(cluster curp)
estimates sto trim2

qui reghdfe ln_trim ///
i.sex##c.distance_p i.rural if primaria == 0 ///
& cal!=. , a(ef trimestre edad_cut categoria zona_economica n_categoria ) vce(cluster curp)
estimates sto trim3


esttab trim1 trim2 trim3 using "${tables}\\estimations\\distance_bs\\totales_cut.tex",  ///
  ///
 se(%20.3fc) keep(2.sex* distance_p ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  append  nogaps  b(%20.3fc) noomitted  nobaselevels nonotes 
	
	
esttab tot1 tot2 tot3 using "${tables}\\estimations\\distance_bs\\totales_cut.tex",  ///
  ///
 se(%20.3fc) keep(2.sex* distance_p ) ///
  stats(N, fmt(%20.0fc) labels("Obs."))  label ///
  append  nogaps  b(%20.3fc) noomitted  nobaselevels nonotes 
	 
	}

	
		
	}

	
**PRIMARY - AGGREGATED INTERACTIVE EFFECTS
{
	**	INTERACCIONES PER WAGE
	{

		* Age
		{
	qui reghdfe ln_trim ///
		i.sex##ib0.edad_cut  i.zona_economica ///
 if primaria == 1, a(categoria ef trimestre n_categoria) ///
 vce(cluster curp)


mat define trim_plot_age = J(1,3,.)	
 forval i = 0/8{
		lincom 2.sex+2.sex#`i'.edad_cut
		mat define auxi = J(1,3,.)
		mat auxi[1,1] = r(estimate)
		mat auxi[1,2] = r(lb)
		mat auxi[1,3] = r(ub)
		mat trim_plot_age = (trim_plot_age\auxi)
		 }

	}
		
		* Type of category
		{

	qui reghdfe ln_trim  ///
		i.sex##ib1.n_categoria   ///
if primaria == 1, a(categoria ef trimestre edad_cut n_categoria) ///

		mat define trim_plot_cat = J(1,3,.)	
mat trim_plot_cat[1,1] = r(table)[1,2]
mat trim_plot_cat[1,2] = r(table)[5,2]
mat trim_plot_cat[1,3] = r(table)[6,2]

forvalues i = 20/25{

	mat define auxi = J(1,3,.)
	mat auxi[1,1] = r(table)[1,`i']
	mat auxi[1,2] = r(table)[5,`i']
	mat auxi[1,3] = r(table)[6,`i']
	
	mat trim_plot_cat = (trim_plot_cat\auxi)
	}

	
	
}

		}
 
	**	INTERACCIONES TOTAL EARNINGS
	{
		
		* Age
		{

	qui reghdfe ln_total  ///
		i.sex##ib0.edad_cut  ///
 if secc==1 & primaria == 1, ///
 a(categoria ef trimestre edad_cut n_categoria zona_economica ) ///
 vce(cluster curp)


mat define tot_plot_age = J(1,3,.)	
 forval i = 0/8{
		lincom 2.sex+2.sex#`i'.edad_cut
		mat define auxi = J(1,3,.)
		mat auxi[1,1] = r(estimate)
		mat auxi[1,2] = r(lb)
		mat auxi[1,3] = r(ub)
		mat tot_plot_age = (tot_plot_age\auxi)
		 }
	
	}
	
 
		* Type of category
		{

		
qui reghdfe ln_total  ///
	i.sex##i.n_categoria ///
 if secc==1 & primaria == 1, ///
 a(categoria ef trimestre edad_cut zona_economica ) ///
 vce(cluster curp)

		mat define tot_plot_cat = J(1,3,.)	
mat tot_plot_cat[1,1] = r(table)[1,2]
mat tot_plot_cat[1,2] = r(table)[5,2]
mat tot_plot_cat[1,3] = r(table)[6,2]

forvalues i = 20/25{

	mat define auxi = J(1,3,.)
	mat auxi[1,1] = r(table)[1,`i']
	mat auxi[1,2] = r(table)[5,`i']
	mat auxi[1,3] = r(table)[6,`i']
	
	mat tot_plot_cat = (tot_plot_cat\auxi)
	}

}

  }
  	
    **	INTERACCIONES DUPLICATES
	{
		*Age
		{

	qui reghdfe duplicate  ///
		i.sex##ib0.edad_cut  ///
 if secc==1 & primaria == 1, ///
 a(categoria ef trimestre edad_cut n_categoria zona_economica ) ///
 vce(cluster curp)

 
 mat define dup_plot_age = J(1,3,.)	
mat dup_plot_age[1,1] = r(table)[1,2]
mat dup_plot_age[1,2] = r(table)[5,2]
mat dup_plot_age[1,3] = r(table)[6,2]

forval i = 22/29{
	mat define auxi = J(1,3,.)
	mat auxi[1,1] = r(table)[1,`i']
	mat auxi[1,2] = r(table)[5,`i']
	mat auxi[1,3] = r(table)[6,`i']
	
	mat dup_plot_age = (dup_plot_age\auxi)
}
}
  	
		* Type of category
		{
	qui reghdfe duplicate  ///
	i.sex##i.n_categoria ///
 if secc==1 & primaria == 1, ///
 a(categoria ef trimestre edad_cut zona_economica ) ///
 vce(cluster curp)
 
 
		mat define dup_plot_cat = J(1,3,.)	
mat dup_plot_cat[1,1] = r(table)[1,2]
mat dup_plot_cat[1,2] = r(table)[5,2]
mat dup_plot_cat[1,3] = r(table)[6,2]

forvalues i = 20/25{

	mat define auxi = J(1,3,.)
	mat auxi[1,1] = r(table)[1,`i']
	mat auxi[1,2] = r(table)[5,`i']
	mat auxi[1,3] = r(table)[6,`i']
	
	mat dup_plot_cat = (dup_plot_cat\auxi)
	}
	

	}
	
	}	

	preserve
	foreach catego in _age  { 
clear 
svmat tot_plot`catego'
svmat trim_plot`catego'
rename (tot_plot`catego'1 tot_plot`catego'2 tot_plot`catego'3) (coef_tot lb_tot ub_tot)
rename (trim_plot`catego'1 trim_plot`catego'2 trim_plot`catego'3) (coef_trim lb_trim ub_trim)
drop if coef_tot == .
g cate = _n - 1.05
g cate2 = _n - 0.95

twoway 	(rcap lb_tot ub_tot cate, color("red")) ///
		(scatter coef_tot cate, color("black")) ///
		(rcap lb_trim ub_trim cate2, color("red")) ///
		(scatter coef_trim cate2, color("gray")), ///
    legend(order(2 "Total earning coeff." ///
	4 "Per job wage coeff."  1 "95% CI") position(1) ring(0)) ///
    xlabel(0 "22-24 x F" 1 "25-29 x F" 2 "30-34 x F" ///
	3 "35-39 x F" 4 "40-44 x F" 5 "45-49 x F"  ///
	6 "50-54 x F" 7 "55-59 x F" 8 "60-65 x F" , angle(vertical) ) ///
	ylabel(-0.08(0.02)0.08, format(%9.2f)) ///
	xtitle("Age interval")

graph export "${figures}\\Descriptive\\Interaction\\new_dot`catego'_prim.png" , replace

}
	restore
	
	preserve
{ 
clear 
svmat dup_plot_age 
rename (dup_plot_age1 dup_plot_age2 dup_plot_age3) (coef_tot lb_tot ub_tot)
drop if coef_tot == .
g cate = _n 


twoway 	(rcap lb_tot ub_tot cate, color("red")) ///
		(scatter coef_tot cate, color("black")), ///
		legend(order(2 "Total earning coeff." ///
	4 "Per job wage coeff."  1 "95% CI") position(1) ring(0)) ///
    xlabel(0 "22-24 x F" 1 "25-29 x F" 2 "30-34 x F" ///
	3 "35-39 x F" 4 "40-44 x F" 5 "45-49 x F"  ///
	6 "50-54 x F" 7 "55-59 x F" 8 "60-65 x F" , angle(vertical) ) ///
	xtitle("Age interval")

	ylabel(-0.08(0.02)0.08, format(%9.2f)) ///
	
graph export "${figures}\\Descriptive\\Interaction\\new_dot`catego'_prim.png" , replace

}
	restore
	
}


** RICARDO REQUEST
{
	clear all
use "${work}\\FONE\\aux_1.dta", clear

drop  OP desv_p p_sg t_plaza_both edad nom_municipio telesecundaria foraneo sec rep2 entidad_federativa

gen tipo = substr(categoria , 1, 3)

replace clave_centro_trabajo = ""  if clave_centro_trabajo == "#N/A"

g cat_ = substr( clave_centro_trabajo ,4 , 2  )
g instruction_level = .
replace instruction_level = 1 if ///
				cat_ == "CC" | cat_ == "JN" // PREESCOLAR
replace instruction_level = 2 if ///
				cat_ == "PB" | cat_ == "PR" | cat_ == "IN" // BASUCA
replace instruction_level = 3 if ///
				cat_ == "ES" | cat_ == "TV" | cat_ == "ST" // SECUNDARIA
replace instruction_level = 4 if ///
				cat_ == "DG" | cat_ == "IZ" 
replace instruction_level = 5 if ///
				cat_ == "ML"  // ED. ESPECIAL 		
label define ins_lvl 1 "Prescholar" 2 "Primary" 3 "Secondary" 4 "Administrative" 5 "Special ed."
	label values instruction_level ins_lvl

drop clave_centro_trabajo 

encode nivel_categoria, gen(n_cat)
drop nivel_categoria

drop cat_ 
drop primaria 

label define yrural 1 "Rural" 0 "Urban", replace
label values rural yrural
	
replace rural = 0 if rural == .

label define otrom 0 "Don't have" 1 "Other" 3 "Director" 7 "Administrative", replace
label values otro_modelo otrom

label define tplaza 0 "Part-time" 1 "Full-time", replace
label values t_plaza tplaza
label define tplaza2 0 "Part-time" 1 "Full-time" 2 "Both", replace
label values t_plaza_b tplaza2

g ln_trim = ln(p_trim_real)
g ln_total = ln(p_total_real) 
encode tipo, gen(tipo_c)
drop tipo

keep ln_trim ln_total instruction_level edad_cut n_cat t_plaza t_plaza_b ef trimestre curp sex  duplicate trime year rural cod_muni1 cod_muni2 zona_economica tipo_c //   

compress
	
sort curp ln_trim
bys curp trimestre: egen secc = seq()

*ESTIMATIONS	
{
	
** TOTAL EARNINGS
qui reghdfe ln_total i.sex i.edad_cut if secc == 1 ///
, a(ef trimestre instruction_level) vce(cluster curp)
est sto tot1 
qui reghdfe ln_total i.sex i.edad_cut if secc == 1 ///
, a(ef trimestre instruction_level tipo_c ) vce(cluster curp)
est sto tot2	
qui reghdfe ln_total i.sex i.edad_cut i.zona_economica  ///
if secc == 1 ///
, a(ef trimestre instruction_level tipo_c ) vce(cluster curp)
est sto tot3	


esttab tot1 tot2 tot3 using /// tot4 
	"${tables}\\descriptive\\Regression\\RICARDO_tot.tex" ///
	, se(%5.2fc) mtitles("" "" "" "") ///
	stats(N, fmt(%20.0fc) labels("Obs."))  label ///
	replace nogaps longtable b(%20.2fc) noomitted nobaselevels ///
	title("Regression on total earnigns") nonotes /// 
}
	
}	

 

////////////////////////////////
**#		PLOTS 
///////////////////////////////

clear all
set scheme modern, perm
use "${work}\\FONE\\aux_1.dta", clear

*KDENSITY's

**All KDENSITY
{
twoway (kdensity edad if sex==2, bwidth(3) ) (kdensity edad if sex==1, bwidth(3) ), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
*title("Age distribution of teacher by gender") 
graph export "${figures}\\Descriptive\\obs_edad_sex.png" , replace

*KDENSITY BY TYPE OF CONTRACT
foreach plaza in 0 1{
	twoway (kdensity edad if sex==2 & t_plaza == `plaza' , bwidth(3)) ///
(kdensity edad if sex==1 & t_plaza == `plaza' , bwidth(3)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\Descriptive\\obs_edad_place`plaza'.png" , replace
}

*KDENSITY BY CATEGORY TYPE
foreach categoria in 1 2 3 4 5 6 {
	twoway (kdensity edad if sex==2 & n_categoria == `categoria' , bwidth(4)) ///
(kdensity edad if sex==1 & n_categoria == `categoria' , bwidth(4)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\Descriptive\\obs_edad_cat`categoria'.png" , replace

}

*KDENSITY BY SECONDARY
	twoway (kdensity edad if sex==2 & primaria == 0 & secc == 1, bwidth(4)) ///
(kdensity edad if sex==1 & primaria == 0 & secc == 1, bwidth(4)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\Descriptive\\SECONDARY\\obs_edad_secondary.png" , replace

	twoway (kdensity edad if sex==2 & primaria == 1 & secc == 1, bwidth(4)) ///
(kdensity edad if sex==1 & primaria == 1 & secc == 1, bwidth(4)), ///
ytitle("Density") xtitle("Age")  xlabel( 20 (10) 60) ///
legend(order(1 "Female" 2 "Male" )) 
graph export "${figures}\\Descriptive\\obs_edad_primary.png" , replace


}

** WAGES
{

// TOTAL WAGE EVOLUTION 
{
preserve
keep if secc == 1
collapse (mean) p_total_real , by(sex trimestre)
replace trimestre = trimestre + 224
format %tqCCYY-!Qq trimestre
twoway (line p_total_real trimestre if sex==2 ) ///
		(line p_total_real trimestre if sex==1), ///
		ytitle("Mexican Pesos (adjusted at 2016Q1 value)") ///
		xtitle("Quarter")  ///
		legend(order(1 "Female" 2 "Male") position(5) ring(0)) ///
		ylabel(#6, format(%20.0fc)) ///
		xlabel(#6 , angle(vertical))
graph export "${figures}\\Descriptive\\Evolution\\evo_total.png" , replace
		
restore
}


// TOTAL WAGE GENDER RATIO - BY STATE
{
save "${work}\\FONE\\aux2" , replace
keep if secc == 1 
collapse (mean) p_total_real , by(sex entidad_federativa trimestre)  
foreach trime in 1 32 {
preserve
keep if  trimestre == `trime'
sort entidad_federativa sex
bys entidad_federativa: egen p_total_real_H = max( p_total_real) if sex==1
bys entidad_federativa: gen p_total_real_M = p_total_real[_n+1] if sex==1
duplicates drop entidad_federativa, force
gen ratio_p_total = p_total_real_M / p_total_real_H
		graph hbar (mean) ratio_p_total, ///
over(entidad_federativa, sort(ratio_p_total))  exclude0  ///
legend(order(1 "Female" 2 "Male" )) ytitle("Female/Male Wage Ratio") ylabel(0.6(0.1)1,format(%6.2fc))
graph export "${figures}\\Descriptive\\ratio\\`trime'_total_ratio.png" , replace
restore
		}
	


use "${work}\\FONE\\aux2" , clear
keep if secc == 1
collapse (mean) p_total_real, by(sex entidad_federativa)
sort entidad_federativa sex
bys entidad_federativa: egen p_total_real_H = max( p_total_real) if sex==1
bys entidad_federativa: gen p_total_real_M = p_total_real[_n+1] if sex==1
duplicates drop entidad_federativa, force
gen ratio_p_total = p_total_real_M / p_total_real_H

		graph hbar (mean) ratio_p_total, ///
over(entidad_federativa, sort(ratio_p_total))  exclude0  ///
legend(order(1 "Female" 2 "Male" )) ytitle("Female/Male Wage Ratio") ylabel(0.6(0.1)1,format(%6.2fc))
graph export "${figures}\\Descriptive\\ratio\\total_ratio.png" , replace
use "${work}\\FONE\\aux2" , clear
erase "${work}\\FONE\\aux2.dta"

}


// TOTAL WAGE - BY CATEGORY TYPE AND QUARTER (DOT PLOT)
{
preserve
keep if secc == 1
g std = p_total_real
collapse (mean) p_total_real (semean) std , by(sex n_categoria)


	g lb = p_total_real - (std * 1.96)
	g ub = p_total_real + (std * 1.96)


twoway (rcap lb ub n_cat, color("red")) ///
(scatter p_total_real n_categoria if sex ==2, msize(medium) color("maroon")) ///
(scatter p_total_real n_categoria if sex ==1, msize(medium) color("navy")), ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Category level") ///
xlabel( 1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" )  ///
legend(order(2 "Female" 3 "Male" 1 "CI. 95%")) ///
ylabel(#6 , format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\wage_catsex_total.png" , replace
restore

preserve
keep if secc == 1
g std = p_total_real
collapse (mean) p_total_real (semean) std , by(sex n_categoria trimestre)

	g lb = p_total_real - (std * 1.96)
	g ub = p_total_real + (std * 1.96)
	
foreach trime in 1 32{
		
twoway  (rcap lb ub n_categoria if trimestre ==`trime', color("red")) ///
(scatter p_total_real n_categoria if sex ==2 & trimestre ==`trime', msize(medium) color("maroon")) ///
		(scatter p_total_real n_cat if sex ==1 & trimestre ==`trime', msize(medium) color("navy")), ///
	ytitle("Mexican Pesos (adjusted at 2016Q1 value)") ///
	xtitle("Category level") ///
	xlabel(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" ) ///
	ylabel(#6, format(%20.2fc)) ///
	legend(order(2 "Female" 3 "Male" 1 "CI. 95%")) 
	graph export "${figures}\\Descriptive\\Wage\\catsex_total_`trime'.png" , replace

		}
restore
}


// WAGE PER JOB - BY CATEGORY LEVEL AND QUARTER (DOT PLOT)
{
preserve 

g std = p_trim_real 
collapse (mean) p_trim_real (semean) std , by(sex n_categoria trimestre)
g lb = p_trim_real - (std * 1.96)
g ub = p_trim_real + (std * 1.96)

foreach trime in 1 32 {
twoway (rcap lb ub n_categoria if trimestre == `trime' , color("red")) ///
		(scatter p_trim_real n_categoria if sex ==2 & trimestre ==`trime', msize(medium) color("maroon") ) ///
		(scatter p_trim_real n_categoria if sex ==1 & trimestre ==`trime', msize(medium) color("navy")), ///
	ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Category level") ///
	xlabel(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" ) ///
	ylabel(#6, format(%20.0fc)) ///
	legend(order(2 "Female" 3 "Male" 1 "CI. 95%"))
	graph export "${figures}\\Descriptive\\Wage\\perjob\\catsex_trim_`trime'.png" , replace
}

restore

preserve 

g std = p_trim_real 
collapse (mean) p_trim_real (semean) std, by(sex n_categoria)
g lb = p_trim_real - (std * 1.96)
g ub = p_trim_real + (std * 1.96)

		twoway (rcap lb ub n_categoria, color("red")) ///
(scatter p_trim_real n_categoria if sex ==2, msize(medium) color("maroon")) ///
(scatter p_trim_real n_categoria if sex ==1, msize(medium) color("navy")), ///
	ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Category level") ///
	xlabel(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E") ///
	ylabel(#6, format(%20.0fc)) ///
	legend(order(2 "Female" 3 "Male" 1 "CI. 95%" ))
	graph export "${figures}\\Descriptive\\Wage\\perjob\\catsex_trimtrime.png" , replace

restore
}

// PER JOB WAGE BY AGE AND SEX
{
preserve
collapse (mean) p_trim_real , by(edad sex )
twoway  (line p_trim_real edad if sex==2) ///
 (line p_trim_real edad if sex==1) , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 20 (10) 60) legend(order(1 "Woman" 2  "Men" )) ///
ylabel(#6, format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\wage_sex_perjob.png" , replace

twoway  (line p_trim_real edad if sex==2 & edad>=30 & edad<=50) ///
 (line p_trim_real edad if sex==1 & edad>=30 & edad<=50) , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 30 (5) 50) legend(order(1 "Woman" 2  "Men" )) ///
ylabel(#6, format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\wage_sex_perjob_cut1.png" , replace

twoway  (line p_trim_real edad if sex==2 & edad>=45 & edad<=65) ///
 (line p_trim_real edad if sex==1 & edad>=45 & edad<=65) , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 45 (5) 65) legend(order(1 "Woman" 2  "Men" )) ///
ylabel(#6, format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\wage_sex_perjob_cut2.png" , replace

gen ln_p = ln(p_trim_real)

twoway  (line ln_p edad if sex==2) ///
 (line ln_p edad if sex==1) , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 20 (10) 60) legend(order(1 "Woman" 2  "Men" )) ///
ylabel(#6, format(%20.3fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\ln_wage_sex_perjob.png" , replace

restore
}

// Wage per job age-sex-trimester:
{
preserve
collapse (mean) p_trim_real , by(sex edad trimestre)
foreach trime in 1 32 {
	twoway (line p_trim_real edad if sex==2 & trimestre ==`trime') ///
		(line p_trim_real edad if sex==1 & trimestre ==`trime') , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 20 (10) 60) legend(order(1 "Woman (mean)" 2  "Men (mean)" )) ///
ylabel(#6, format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\trime\\wage_sex_perjob_`trime'.png" , replace
	}

restore
}

// Wage per job age-sex-contracttype:
{
preserve
collapse (mean) p_trim_real , by(sex edad t_plaza trimestre)
foreach trime in 1 32 {
		foreach contrato in 0 1 {
		twoway  (line p_trim_real edad if trimestre == `trime' & sex==2 & t_plaza == `contrato') ///
		(line p_trim_real edad if trimestre == `trime' & sex==1 & t_plaza == `contrato') , ///
		ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
		xlabel( 20 (10) 60) legend(order(1 "Female" 2  "Male" )) ///
		ylabel(#6, format(%20.0fc))
					if `contrato' == 0 {
					local aux = "hora"	
										}

					if `contrato' == 1 {
					local aux = "plaza"	
										}				
graph export "${figures}\\Descriptive\\Wage\\perjob\\c_type\\wage_sex_perjob_`agno'`trime'_`aux'.png" , replace	
		}
	}

restore


preserve
collapse (mean) p_trim_real , by(sex edad t_plaza)
		foreach contrato in 0 1 {
		twoway  (line p_trim_real edad if sex==2 & t_plaza == `contrato') ///
		(line p_trim_real edad if sex==1 & t_plaza == `contrato') , ///
	ytitle("Mexican Pesos (adjusted at 2016Q1 value)") ///
	xtitle("Age")  ///
	xlabel( 20 (10) 60) legend(order(1 "Female" 2  "Male" )) ///
		ylabel(#6, format(%20.0fc))
					if `contrato' == 0 {
					local aux = "hora"	
										}

					if `contrato' == 1 {
					local aux = "plaza"	
										}

graph export "${figures}\\Descriptive\\Wage\\perjob\\c_type\\wage_sex_perjob_`aux'.png" , replace	
		}
restore
}

// Wage per job age-sex-category level:
{
preserve
collapse (mean) p_trim_real , by(sex edad n_categoria)

foreach j in 1 2 3 4 5 6 {
twoway  (line p_trim_real edad if sex==2 & n_categoria == `j') ///
 (line p_trim_real edad if sex==1 & n_categoria == `j') , ///
ytitle("Mexican Pesos (adjusted at 2016Q1 value)") xtitle("Age")  ///
xlabel( 20 (10) 60) legend(order(1 "Woman (mean)" 2  "Men (mean)" )) ///
ylabel(#6, format(%20.0fc))
graph export "${figures}\\Descriptive\\Wage\\perjob\\wage_sex_perjob_`j'.png" , replace
}
restore
}

// WAGE PER JOB EVOLUTION 
{
preserve
collapse (mean) p_trim_real , by(sex trimestre)
replace trimestre = trimestre + 224
format %tqCCYY-!Qq trimestre
twoway (line p_trim_real trimestre if sex==2 ) ///
		(line p_trim_real trimestre if sex==1), ///
		ytitle("Mexican Pesos (adjusted at 2016Q1 value)") ///
		xtitle("Quarter")  ///
		legend(order(1 "Female" 2 "Male") position(5) ring(0)) ///
		ylabel(#6, format(%20.0fc)) ///
		xlabel(#6 , angle(vertical))
graph export "${figures}\\Descriptive\\Evolution\\evo_trim.png" , replace
		
restore
}

}

// SCATTER BY TIPES (CURVES)
{
use "${work}\\FONE\\aux_1.dta", clear
keep if secc == 1 & year == 2016


{
g n_category = .
replace n_category = 1 if primaria == 1 & t_plaza_b == 0
replace n_category = 2 if primaria == 1 & t_plaza_b == 1
replace n_category = 3 if primaria == 0 & t_plaza_b == 0
replace n_category = 4 if primaria == 0 & t_plaza_b == 1

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_category_contract.png" , replace
}
restore

*------------- MALE
drop n_category 
g n_category = .
replace n_category = 1 if primaria == 1 & t_plaza_b == 0 & sex == 1
replace n_category = 2 if primaria == 1 & t_plaza_b == 1 & sex == 1
replace n_category = 3 if primaria == 0 & t_plaza_b == 0 & sex == 1
replace n_category = 4 if primaria == 0 & t_plaza_b == 1 & sex == 1

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_category_contract_male.png" , replace
}
restore

*------------- FEMALE
drop n_category 
g n_category = .
replace n_category = 1 if primaria == 1 & t_plaza_b == 0 & sex == 2
replace n_category = 2 if primaria == 1 & t_plaza_b == 1 & sex == 2
replace n_category = 3 if primaria == 0 & t_plaza_b == 0 & sex == 2
replace n_category = 4 if primaria == 0 & t_plaza_b == 1 & sex == 2

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_category_contract_female.png" , replace
}
restore

*******

drop n_category 
replace rural = 0 if rural == .

g n_category = .
replace n_category = 1 if rural  == 1 & t_plaza_b == 0
replace n_category = 2 if rural == 1 & t_plaza_b == 1
replace n_category = 3 if rural == 0 & t_plaza_b == 0
replace n_category = 4 if rural == 0 & t_plaza_b == 1

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Rural & Part-time" 2 "Rural & Full-time" ///
		3 "Urban & Part-time" 4 "Urban & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_urbanity_contract.png" , replace
}
restore

*-------------- MALE
drop n_category 
replace rural = 0 if rural == .

g n_category = .
replace n_category = 1 if rural == 1 & t_plaza_b == 0 & sex ==1 
replace n_category = 2 if rural == 1 & t_plaza_b == 1 & sex ==1 
replace n_category = 3 if rural == 0 & t_plaza_b == 0 & sex ==1 
replace n_category = 4 if rural == 0 & t_plaza_b == 1 & sex ==1 

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Rural & Part-time" 2 "Rural & Full-time" ///
		3 "Urban & Part-time" 4 "Urban & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_urbanity_contract_male.png" , replace
}
restore

*-------------- FEMALE
drop n_category 
replace rural = 0 if rural == .

g n_category = .
replace n_category = 1 if rural == 1 & t_plaza_b == 0 & sex ==2 
replace n_category = 2 if rural == 1 & t_plaza_b == 1 & sex ==2
replace n_category = 3 if rural == 0 & t_plaza_b == 0 & sex ==2 
replace n_category = 4 if rural == 0 & t_plaza_b == 1 & sex ==2 

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Rural & Part-time" 2 "Rural & Full-time" ///
		3 "Urban & Part-time" 4 "Urban & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_urbanity_contract_female.png" , replace
}
restore


*****************************

drop n_category 

g n_category = .
replace n_category = 1 if zona_economica == 2 & t_plaza_b == 0
replace n_category = 2 if zona_economica == 2 & t_plaza_b == 1
replace n_category = 3 if zona_economica == 3 & t_plaza_b == 0
replace n_category = 4 if zona_economica == 3 & t_plaza_b == 1

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "2E.Z. & Part-time" 2 "2E.Z. & Full-time" ///
		3 "3E.Z. & Part-time" 4 "3E.Z. & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_economiczone_contract.png" , replace
}
restore

drop n_category 
replace rural = 0 if rural == .

*----------------- MALE

g n_category = .
replace n_category = 1 if zona_economica == 2 & t_plaza_b == 0 & sex ==1
replace n_category = 2 if zona_economica == 2 & t_plaza_b == 1 & sex ==1
replace n_category = 3 if zona_economica == 3 & t_plaza_b == 0 & sex ==1
replace n_category = 4 if zona_economica == 3 & t_plaza_b == 1 & sex ==1

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "2E.Z. & Part-time" 2 "2E.Z. & Full-time" ///
		3 "3E.Z. & Part-time" 4 "3E.Z. & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_economiczone_contract_male.png" , replace
}
restore

*----------------- FEMALE
drop n_category 

g n_category = .
replace n_category = 1 if zona_economica == 2 & t_plaza_b == 0 & sex ==2
replace n_category = 2 if zona_economica == 2 & t_plaza_b == 1 & sex ==2
replace n_category = 3 if zona_economica == 3 & t_plaza_b == 0 & sex ==2
replace n_category = 4 if zona_economica == 3 & t_plaza_b == 1 & sex ==2

mat level = J(5,2,.)
mat complete_list = J(1,3,.)
forval j = 0(1)8{
tabstat p_total_real if edad_cut==`j', stats(mean) by(n_category) save
tabstatmat m`j'
	forval lev = 1(1)5{
		mat level[`lev',1] = `j'
	}
	forval lev = 1(1)5{
		mat level[`lev',2] = `lev'
	}
mat m`j' = m`j',level
mat complete_list = complete_list\m`j'
}
preserve
{
clear 
svmat complete_list
drop if complete_list1 ==.
rename (complete_list1 complete_list2 complete_list3) (mean edad_cut n_cat)
label define edadcut 0 "22-24" 1 "25-29" 2 "30-34" ///
3 "35-39" 4 "40-44" 5 "45-49" 6 "50-54" 7 "55-59" 8 "60-65"
label values edad_cut edadcut 

twoway 	(scatter mean edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter mean edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter mean edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter mean edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "2E.Z. & Part-time" 2 "2E.Z. & Full-time" ///
		3 "3E.Z. & Part-time" 4 "3E.Z. & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\by_economiczone_contract_female.png" , replace
}
restore
}


use "${work}\\FONE\\aux_1.dta", clear
keep if  year == 2016

g n_category = .
replace n_category = 1 if primaria == 1 & t_plaza_b == 0
replace n_category = 2 if primaria == 1 & t_plaza_b == 1
replace n_category = 3 if primaria == 0 & t_plaza_b == 0
replace n_category = 4 if primaria == 0 & t_plaza_b == 1

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut )
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_contract.png" , replace
}
restore

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut sex)
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut  if n_cat == 1 & sex == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 1, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 1, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 1, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_contract_male.png" , replace

twoway 	(scatter p_trim_real edad_cut if n_cat == 1 & sex == 2, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 2, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 2, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Part-time" 2 "Primary & Full-time" ///
		3 "Secondary & Part-time" 4 "Secondary & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(10000(5000)45000, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_contract_female.png" , replace
}
restore

drop n_category
g n_category = .
replace n_category = 1 if primaria == 1 & rural == 0
replace n_category = 2 if primaria == 1 & rural == 1
replace n_category = 3 if primaria == 0 & rural == 0
replace n_category = 4 if primaria == 0 & rural == 1

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut )
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Urban" 2 "Primary & Rural" ///
		3 "Secondary & Urban" 4 "Secondary & Rural")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_rural.png" , replace
}
restore

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut sex)
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut if n_cat == 1 & sex == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 1, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 1, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 1, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Urban" 2 "Primary & Rural" ///
		3 "Secondary & Urban" 4 "Secondary & Rural")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_rural_male.png" , replace

twoway 	(scatter p_trim_real edad_cut if n_cat == 1 & sex == 2, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 2, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 2, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Primary & Urban" 2 "Primary & Rural" ///
		3 "Secondary & Urban" 4 "Secondary & Rural")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_category_rural_female.png" , replace
}
restore


drop n_category
g n_category = .
replace n_category = 1 if rural == 0 & t_plaza_b == 0
replace n_category = 2 if rural == 0 & t_plaza_b == 1
replace n_category = 3 if rural == 1 & t_plaza_b == 0
replace n_category = 4 if rural == 1 & t_plaza_b == 1

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut )
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut  if n_cat == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Urban & Part-time" 2 "Urban & Full-time" 3 "Rural & Part-time" 4 "Rural & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_rural_contract.png" , replace
}
restore

preserve
{
collapse (mean) p_trim_real, by( n_category edad_cut sex)
drop if n_category == .
twoway 	(scatter p_trim_real edad_cut if n_cat == 1 & sex == 1, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 1, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 1, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 1, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Urban & Part-time" 2 "Urban & Full-time" 3 "Rural & Part-time" 4 "Rural & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_rural_contract_male.png" , replace

twoway 	(scatter p_trim_real edad_cut if n_cat == 1 & sex == 2, msymbol(O)) ///
		(scatter p_trim_real edad_cut if n_cat == 2 & sex == 2, msymbol(D)) ///
		(scatter p_trim_real edad_cut if n_cat == 3 & sex == 2, msymbol(T)) ///
		(scatter p_trim_real edad_cut if n_cat == 4 & sex == 2, msymbol(S)) , ///
		xtitle("Age interval") ytitle("Mexican pesos (adjusted at 2016Q1 value)") ///
		legend(order(1 "Urban & Part-time" 2 "Urban & Full-time" 3 "Rural & Part-time" 4 "Rural & Full-time")) ///
		xlabel(0 "22-24"  2 "30-34"  4 "40-44" ///
		6 "50-54" 8 "60-65", angle(vertical)) ///
		ylabel(#4, format(%20.0fc))
graph export "${figures}\\Descriptive\\category\\Wage\perjob_rural_contract_female.png" , replace
}
restore

}

** CATEGORY
{
	
********
*Observation level
********
{
preserve
tab edad_cut n_categoria if sex==2, matcell(mujer)

tab edad_cut n_categoria if sex==1, matcell(hombre)

mat mat1 = mujer\hombre
clear 

svmat mat1

g edad_ = ""
replace edad_ = "22-25" in 1 
replace edad_ = "22-25" in 10
replace edad_ = "26-30" in 2 
replace edad_ = "26-30" in 11
replace edad_ = "31-35" in 3 
replace edad_ = "31-35" in 12
replace edad_ = "36-40" in 4 
replace edad_ = "36-40" in 13
replace edad_ = "41-45" in 5 
replace edad_ = "41-45" in 14
replace edad_ = "46-50" in 6 
replace edad_ = "46-50" in 15
replace edad_ = "51-55" in 7 
replace edad_ = "51-55" in 16
replace edad_ = "56-60" in 8 
replace edad_ = "56-60" in 17
replace edad_ = "61-65" in 9
replace edad_ = "61-65" in 18
 
rename (mat11 mat12 mat13 mat14 mat15 mat16  ) ///
(cat07 cat7A cat7B cat7C cat7D cat7E )

g sex = 1
replace sex = 2 if _n<10

* Convertir la estructura de datos de amplia a larga
reshape long cat, i(edad_ sex) j(n_categoria) string

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED {
		g cat`categori' = cat if n_categoria == "`categori'" 
}


/*
graph hbar (sum) 	cat07 cat7A cat7B cat7BC cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.")  ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7BC" 5 "7C" 6 "7D" 7 "7E" 8 "Not Reported"))
*/
	
encode edad_, gen(edad)

forval i = 1/9{
	egen total`i'_F = total(cat) if edad == `i' & sex ==0
	egen total`i'_M = total(cat) if edad == `i' & sex ==1
}

egen total_F = rowmax(total1_F total2_F total3_F total4_F ///
 total5_F total6_F total7_F total8_F total9_F) 

egen total_M = rowmax(total1_M total2_M total3_M total4_M ///
 total5_M total6_M total7_M total8_M total9_M) 

forval i = 1/9{
	drop total`i'_F total`i'_M
	}

egen total_ = rowmax(total_M total_F) 

drop total_M total_F

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		replace cat`categori' = cat`categori'/total_ if n_categoria == "`categori'" 
}

label define sexo2 2 "Female" 1 "Male", replace
label values sex sexo2


graph hbar (sum) 	cat07 cat7A cat7B cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("%") ylabel( , format(%6.2fc)) ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" ))
		graph export "${figures}\\Descriptive\\category\\Age\\edad_categoria_prop_obs.png" , replace

restore
}
****
* Teacher (with  repetation per quarter) level
****
{
preserve

keep if secc == 1

tab edad_cut n_categoria if sex==2, matcell(mujer)

tab edad_cut n_categoria if sex==1, matcell(hombre)

mat mat1 = mujer\hombre
clear 

svmat mat1

g edad_ = ""
replace edad_ = "22-25" in 1 
replace edad_ = "22-25" in 10
replace edad_ = "26-30" in 2 
replace edad_ = "26-30" in 11
replace edad_ = "31-35" in 3 
replace edad_ = "31-35" in 12
replace edad_ = "36-40" in 4 
replace edad_ = "36-40" in 13
replace edad_ = "41-45" in 5 
replace edad_ = "41-45" in 14
replace edad_ = "46-50" in 6 
replace edad_ = "46-50" in 15
replace edad_ = "51-55" in 7 
replace edad_ = "51-55" in 16
replace edad_ = "56-60" in 8 
replace edad_ = "56-60" in 17
replace edad_ = "61-65" in 9
replace edad_ = "61-65" in 18
 
rename (mat11 mat12 mat13 mat14 mat15 mat16  ) ///
(cat07 cat7A cat7B cat7C cat7D cat7E )

g sexo = "H"
replace sexo = "M" if _n<10

* Convertir la estructura de datos de amplia a larga
reshape long cat, i(edad_ sexo) j(categoria) string

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		g cat`categori' = cat if categoria == "`categori'" 
}

gen sex = 0
replace sex = 1 if sexo=="H"
label define sexo2 0 "Female" 1 "Male", replace
label values sex sexo2

/*
graph hbar (sum) 	cat07 cat7A cat7B cat7BC cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.")  ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7BC" 5 "7C" 6 "7D" 7 "7E" 8 "Not Reported"))
*/
	
encode edad_, gen(edad)

forval i = 1/9{
	egen total`i'_F = total(cat) if edad == `i' & sex ==0
	egen total`i'_M = total(cat) if edad == `i' & sex ==1
}

egen total_F = rowmax(total1_F total2_F total3_F total4_F ///
 total5_F total6_F total7_F total8_F total9_F) 

egen total_M = rowmax(total1_M total2_M total3_M total4_M ///
 total5_M total6_M total7_M total8_M total9_M) 

forval i = 1/9{
	drop total`i'_F total`i'_M
	}

egen total_ = rowmax(total_M total_F) 

drop total_M total_F

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		replace cat`categori' = cat`categori'/total_ if categoria == "`categori'" 
}

graph hbar (sum) 	cat07 cat7A cat7B cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("%") ylabel( , format(%6.2fc)) ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7C" 5  "7D" 6 "7E" ))
		graph export "${figures}\\Descriptive\\category\\Age\\edad_categoria_prop_teacher.png" , replace
		
restore
}

****
* Teacher-quarter level
****
*2016/02
{
preserve

keep if secc == 1 & trimestre == 1

tab edad_cut n_categoria if sex==2, matcell(mujer)

tab edad_cut n_categoria if sex==1, matcell(hombre)

mat mat1 = mujer\hombre
clear 

svmat mat1

g edad_ = ""
replace edad_ = "22-25" in 1 
replace edad_ = "22-25" in 10
replace edad_ = "26-30" in 2 
replace edad_ = "26-30" in 11
replace edad_ = "31-35" in 3 
replace edad_ = "31-35" in 12
replace edad_ = "36-40" in 4 
replace edad_ = "36-40" in 13
replace edad_ = "41-45" in 5 
replace edad_ = "41-45" in 14
replace edad_ = "46-50" in 6 
replace edad_ = "46-50" in 15
replace edad_ = "51-55" in 7 
replace edad_ = "51-55" in 16
replace edad_ = "56-60" in 8 
replace edad_ = "56-60" in 17
replace edad_ = "61-65" in 9
replace edad_ = "61-65" in 18
 
rename (mat11 mat12 mat13 mat14 mat15 mat16  ) ///
(cat07 cat7A cat7B cat7C cat7D cat7E )

g sexo = "H"
replace sexo = "M" if _n<10

* Convertir la estructura de datos de amplia a larga
reshape long cat, i(edad_ sexo) j(categoria) string

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		g cat`categori' = cat if categoria == "`categori'" 
}

gen sex = 0
replace sex = 1 if sex==1
label define sexo2 0 "Female" 1 "Male", replace
label values sex sexo2

/*
graph hbar (sum) 	cat07 cat7A cat7B cat7BC cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.")  ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7BC" 5 "7C" 6 "7D" 7 "7E" 8 "Not Reported"))
*/
	
encode edad_, gen(edad)

forval i = 1/9{
	egen total`i'_F = total(cat) if edad == `i' & sex ==0
	egen total`i'_M = total(cat) if edad == `i' & sex ==1
}

egen total_F = rowmax(total1_F total2_F total3_F total4_F ///
 total5_F total6_F total7_F total8_F total9_F) 

egen total_M = rowmax(total1_M total2_M total3_M total4_M ///
 total5_M total6_M total7_M total8_M total9_M) 

forval i = 1/9{
	drop total`i'_F total`i'_M
	}

egen total_ = rowmax(total_M total_F) 

drop total_M total_F

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		replace cat`categori' = cat`categori'/total_ if categoria == "`categori'" 
}

graph hbar (sum) 	cat07 cat7A cat7B cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.") ylabel( , format(%6.2fc)) ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E" ))
		graph export "${figures}\\Descriptive\\category\\Age\\edad_categoria_prop_teacher_201602.png" , replace
	
restore
}

*2018/04
{
preserve

keep if secc == 1 & trimestre == 32

tab edad_cut n_categoria if sex==2, matcell(mujer)

tab edad_cut n_categoria if sex==1, matcell(hombre)

mat mat1 = mujer\hombre
clear 

svmat mat1

g edad_ = ""
replace edad_ = "22-25" in 1 
replace edad_ = "22-25" in 10
replace edad_ = "26-30" in 2 
replace edad_ = "26-30" in 11
replace edad_ = "31-35" in 3 
replace edad_ = "31-35" in 12
replace edad_ = "36-40" in 4 
replace edad_ = "36-40" in 13
replace edad_ = "41-45" in 5 
replace edad_ = "41-45" in 14
replace edad_ = "46-50" in 6 
replace edad_ = "46-50" in 15
replace edad_ = "51-55" in 7 
replace edad_ = "51-55" in 16
replace edad_ = "56-60" in 8 
replace edad_ = "56-60" in 17
replace edad_ = "61-65" in 9
replace edad_ = "61-65" in 18
 
rename (mat11 mat12 mat13 mat14 mat15 mat16  ) ///
(cat07 cat7A cat7B cat7C cat7D cat7E )

g sexo = "H"
replace sexo = "M" if _n<10

* Convertir la estructura de datos de amplia a larga
reshape long cat, i(edad_ sexo) j(categoria) string

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		g cat`categori' = cat if categoria == "`categori'" 
}

gen sex = 0
replace sex = 1 if sex==1
label define sexo2 0 "Female" 1 "Male", replace
label values sex sexo2

/*
graph hbar (sum) 	cat07 cat7A cat7B cat7BC cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.")  ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7BC" 5 "7C" 6 "7D" 7 "7E" 8 "Not Reported"))
*/
	
encode edad_, gen(edad)

forval i = 1/9{
	egen total`i'_F = total(cat) if edad == `i' & sex ==0
	egen total`i'_M = total(cat) if edad == `i' & sex ==1
}

egen total_F = rowmax(total1_F total2_F total3_F total4_F ///
 total5_F total6_F total7_F total8_F total9_F) 

egen total_M = rowmax(total1_M total2_M total3_M total4_M ///
 total5_M total6_M total7_M total8_M total9_M) 

forval i = 1/9{
	drop total`i'_F total`i'_M
	}

egen total_ = rowmax(total_M total_F) 

drop total_M total_F

foreach categori in 07 7A 7B 7C 7D 7E NOT_REPORTED{
		replace cat`categori' = cat`categori'/total_ if categoria == "`categori'" 
}

graph hbar (sum) 	cat07 cat7A cat7B cat7C ///
					cat7D cat7E catNOT_REPORTED ///
,  over(sex)  over(edad_) stack ///
	ytitle("Freq.") ylabel( , format(%6.2fc)) ///
    legend(order(1 "07" 2 "7A" 3 "7B" 4 "7C" 5 "7D" 6 "7E"))
		graph export "${figures}\\Descriptive\\category\\Age\\edad_categoria_prop_teacher_201804.png" , replace
	
restore
}

}


}


////////////////////////////////
**#		MIGUEL INQUIRIES 
///////////////////////////////


use "${work}\\FONE\\aux_1.dta", clear
{
**# WORK BY COHORTS

*# FIRST PROMOTION
{
* ONLY THOSE WHO WHERE WORKING IN 2016
{
use "${work}\\FONE\\aux_1.dta", clear
encode nivel_categoria, gen(n_cat)
replace n_cat = 0 if n_cat == 7
g neg_cat = -n_cat
sort curp trimestre neg_cat
bys curp trimestre : egen seccc = seq()
keep if seccc == 1 

collapse (first) sexo edad year (max) n_cat, by(curp trimestre)
preserve
sort curp trimestre
keep if trimestre <= 15
bys curp: egen seqq = seq()
keep if seqq == 1
gen keeep_ = 1 

tempfile temp_data

* Guardar la base actual en ese archivo temporal
save `temp_data'

restore 

merge m:1 curp using `temp_data'
keep if _merge == 3
keep if keeep_ == 1
drop if year == 2015
drop keeep_ _merge seqq

bys curp (sexo): egen sexo2 = mode(sexo)
replace sexo = sexo2 if missing(sexo)
drop if sexo == ""
sort curp trimestre
bys curp : egen sec = seq()

g nivel_base = n_cat if sec == 1
bys curp: replace nivel_base = nivel_base[_n-1] if nivel_base[_n-1] != .
g dif = n_cat - nivel_base

bys curp (trimestre): gen primer_aumento = trimestre if dif > 0 & dif[_n-1] <= 0
bys curp: egen primer_aumento_individuo = min(primer_aumento)
drop primer_aumento
g tiempo_primer = primer_aumento_individuo - 1

collapse (first) nivel_base tiempo_primer , by(curp)

save "${work}\\FONE\\aux_99.dta", replace

use "${work}\\FONE\\aux_1.dta", clear
keep if year < 2020
encode nivel_categoria, gen(n_cat)
replace n_cat = 0 if n_cat == 7
g neg_cat = -n_cat
sort curp year neg_cat
bys curp year: egen seccc = seq()
keep if seccc == 1 

drop _merge
merge m:1 curp using "${work}\\FONE\\aux_99.dta"
erase "${work}\\FONE\\aux_99.dta"
keep if _merge == 3

duplicates drop curp tiempo_primer, force

foreach vari in edad mision_cultural maestro_indigena telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado{
	replace `vari' = 0 if `vari' == .
}

encode sexo , gen(sex)
label define sex 1 "Male" 2 "Female", replace


forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    capture reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i' & t_plaza_both == 1 & tiempo_primer<32, a(entidad_federativa)

    * Verificar si ocurrió el error 2001 (error de regresión)
    if _rc == 2001 {
        break
    } 
	else {
		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i' & t_plaza_both == 1 & tiempo_primer<32, a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo tr`i'

        * Mostrar el valor de i
        display "`i'"
		
				if `i' == 0 {
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }
}

		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base if t_plaza_both == 1 ///
        , a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo trcom
		
		            esttab trcom using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
				
		
replace tiempo_primer = 32 if tiempo_primer == .
*FULL-TIME
forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    capture reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i' & t_plaza_both == 1, a(entidad_federativa)

    * Verificar si ocurrió el error 2001 (error de regresión)
    if _rc == 2001 {
        break
    } 
	else {
		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i'  & t_plaza_both == 1, a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo tr`i'

        * Mostrar el valor de i
        display "`i'"
		
				if `i' == 0 {
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }
}

		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base if t_plaza_both == 1 ///
        , a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo trcom
		
		            esttab trcom using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
	
*PART-TIME
forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    capture reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i' & t_plaza_both == 0, a(entidad_federativa)

    * Verificar si ocurrió el error 2001 (error de regresión)
    if _rc == 2001 {
        break
    } 
	else {
		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base ///
        if edad_cut == `i'  & t_plaza_both == 0, a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo tr`i'

        * Mostrar el valor de i
        display "`i'"
		
				if `i' == 0 {
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\part_trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\part_trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }
}

		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado nivel_base if t_plaza_both == 0 ///
        , a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo trcom
		
		            esttab trcom using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\part_trim_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
				

**TOBIT FULL-TIME
forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    
	
		tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
    i.entidad_federativa if edad_cut == `i' & t_plaza_both == 1, ll(31) vce(robust)
        eststo tr`i'

        * Mostrar el valor de i
        display "`i'"
		
				if `i' == 0 {
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }


		tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
    i.entidad_federativa if  t_plaza_both == 1, ll(31) vce(robust)
        * Si no hay error, almacenar el modelo
        eststo trcom
		
		            esttab trcom using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
				
				
				
**TOBIT PART-TIME
forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    
	
		tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
    i.entidad_federativa if edad_cut == `i' & t_plaza_both == 0, ll(31) vce(robust)
        eststo tr`i'

        * Mostrar el valor de i
        display "`i'"
		
				if `i' == 0 {
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit_part.tex" ///
                , se(%5.4fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.4fc) noomitted nobaselevels ///
                title("First upgrade (part-ime)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab tr`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit_part.tex" ///
                , se(%5.4fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.4fc) noomitted nobaselevels nonotes
        }
    }


		tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
    i.entidad_federativa if  t_plaza_both == 0, ll(31) vce(robust)
        * Si no hay error, almacenar el modelo
        eststo trcom
		
		            esttab trcom using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\trim_tobit_part.tex" ///
                , se(%5.4fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.4fc) noomitted nobaselevels nonotes
				
}
beep

* Annual Analysis
{
use "${work}\\FONE\\aux_1.dta", clear
encode nivel_categoria, gen(n_cat)
replace n_cat = 0 if n_cat == 7
g neg_cat = -n_cat
sort curp year neg_cat
bys curp year: egen seccc = seq()
keep if seccc == 1 

collapse (first) sexo edad (max) n_cat, by(curp year )
preserve
keep if year <= 2019
sort curp year 
bys curp: egen seqq = seq()
keep if seqq == 1
gen keeep_ = 1 
g nivel_base = n_cat 

tempfile temp_data

* Guardar la base actual en ese archivo temporal
save `temp_data'

restore 

merge m:1 curp using `temp_data'
keep if keeep_ == 1
drop if year == 2015
drop keeep_ _merge 

bys curp (sexo): egen sexo2 = mode(sexo)
replace sexo = sexo2 if missing(sexo)
drop if sexo == ""
drop if sexo == "error"

bys curp: replace nivel_base = nivel_base[_n-1] if nivel_base[_n-1] != .
g dif = n_cat - nivel_base

bys curp (year): gen primer_aumento = year if dif > 0 & dif[_n-1] <= 0
bys curp: egen primer_aumento_individuo = min(primer_aumento)
drop primer_aumento
g tiempo_primer = primer_aumento_individuo - 2016

collapse (first) sexo edad nivel_base tiempo_primer , by(curp)

save "${work}\\FONE\\aux_99.dta", replace

use "${work}\\FONE\\aux_1.dta", clear
keep if year <= 2019
encode nivel_categoria, gen(n_cat)
replace n_cat = 0 if n_cat == 7
g neg_cat = -n_cat
sort curp year neg_cat
bys curp year: egen seccc = seq()
keep if seccc == 1 

drop _merge
merge m:1 curp using "${work}\\FONE\\aux_99.dta"
erase "${work}\\FONE\\aux_99.dta"
keep if _merge == 3

duplicates drop curp, force

foreach vari in edad mision_cultural maestro_indigena telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado{
	replace `vari' = 0 if `vari' == .
}

encode sexo, gen(sex)
label define sex 1 "Male" 2 "Female", replace

forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    capture reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
        if edad_cut == `i' & t_plaza_both==1 , a(entidad_federativa)

    * Verificar si ocurrió el error 2001 (error de regresión)
    if _rc == 2001 {
        break
    } 
	else {
		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
        if edad_cut == `i' & t_plaza_both==1 , a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo anu`i'

        * Mostrar el valor de i
        display "`i'"
		
		if `i' == 0 {
            esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }
}
	
reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
		if t_plaza_both==1, a(entidad_federativa)

        eststo anu9
		
		
            esttab anu9 using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
	
replace tiempo_primer = 9 if tiempo_primer == .
	
	forval i = 0(1)8 {
    * Intentar ejecutar la regresión
    capture reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
        if edad_cut == `i' & t_plaza_both==1 , a(entidad_federativa)

    * Verificar si ocurrió el error 2001 (error de regresión)
    if _rc == 2001 {
        break
    } 
	else {
		reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
        if edad_cut == `i' & t_plaza_both==1 , a(entidad_federativa)
        * Si no hay error, almacenar el modelo
        eststo anu`i'

        * Mostrar el valor de i
        display "`i'"
		
		if `i' == 0 {
            esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels ///
                title("First upgrade (all sample-quarterly values)") nonotes
        } 
		else {
            * Para las siguientes iteraciones, añadir al archivo con append
            esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
        }
    }
}
	
reghdfe tiempo_primer i.sex ///
        i.t_plaza_both i.nivel_base mision_cultural maestro_indigena ///
        telesecundaria ed_especial mc MI FC preyjardin primaria ed_fisica ///
        rural foraneo postgraduado ///
		if t_plaza_both==1, a(entidad_federativa)

        eststo anu9
		
		
            esttab anu9 using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_replace.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
				

				forvalues i = 0(1)8{
						
						tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
   i.entidad_federativa  if edad_cut == `i' & t_plaza_both == 1 , ll(8.1) vce(robust)		
   eststo anu`i' 
   
   if `i' == 0{
   	            esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                replace nogaps b(%20.3fc) noomitted nobaselevels nonotes
   }
	else{
			     esttab anu`i' using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(`i') ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
	}
				}
		
			tobit tiempo_primer i.sex i.t_plaza_both i.nivel_base ///
    mision_cultural maestro_indigena telesecundaria ed_especial ///
    mc MI FC preyjardin primaria ed_fisica rural foraneo postgraduado ///
	i.entidad_federativa if  t_plaza_both == 1 , ll(8.1) vce(robust)		
   eststo anu9 
   
   	            esttab anu9 using ///
                "${tables}\descriptive\CALIDAD\Regresion\PRIMER_ASCENSO\\anual_tobit.tex" ///
                , se(%5.3fc) keep(2.sex) ///
				title(9) ///
                stats(N, fmt(%20.0fc) labels("Obs.")) label ///
                append nogaps b(%20.3fc) noomitted nobaselevels nonotes
		
}
beep


}

	