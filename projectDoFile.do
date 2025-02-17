set more off
clear all
capture log close
*
capture ssc install outreg2
*
*
cd "C:\Users\bushb25\Box\Econometrics Project\"
*
* Ben Bankston and Bradford Bush
* March 16, 2023
* Econ 203 Project Proposal
* Purpose: Review the relationship between beer taxes and alchol-related traffic fatalities using state level data from the years 2000-2019
*
log using "projectProposal.log", replace
*
import excel "Effect of Beer Taxes on Alcohol Related Traffic Fatalities.xlsx", sheet("Sheet1") firstrow clear
*
//dropping DC due to outliers
gen Var = 1 if state == "District Of Columbia"
drop if Var ==1
*
//labelling variables
label variable state "The state's name"
label variable stateAb "Abbreviation for the state's name"
label variable stateid "Used to identify the state"
label variable year "The year, ranging from 2000-2020"
label variable beerTax "Amount of statewide tax on beer purchased per gallon in a given year"
label variable ignInt "Dummy variable indicating whether a state had implemented an Ignition Interlock Device requirement for first-time drunk driving convictions over the limit of 0.08 BAC."
label variable pctAlcFtl01 "Percentage of traffic-related fatalities in which the driver causing the accident was proven or strongly suspected to have a BAC of greater than or equal to 0.01 in a given state in a given year."
label variable pctAlcFtl08 "Percentage of traffic-related fatalities in which the driver causing the accident wasproven or strongly suspected to have a BAC of greater than or equal to 0.08 in a given state in a given year"
label variable pct18to24 "Percentage of the state population that is between the ages of 18-24 in a given year"
label variable policeForce "size of police force for a given state"
label variable population "a given state's population"
label variable stateSize "the size of a given state measured in miles"
label variable scanner "Dummy variable indicating if a state provides incentives to retailers using electronic scanners to validate customer IDs in a given year"
label variable openContainer "Dummy variable indicating if a state had in place a law that prohibits open containers of alcoholic beverages in the passenger compartments of non-commercial motor vehicles in a given year."
label variable unemployRate "the proportion of a state's population that is unemployed"
label variable vehicleMiles "number of miles driven on interstates per state per year measured in millions"
label variable totKill "the total number of vehicular fatalities per year"
label variable stateDeficit "state budget deficit in thousands of dollars"
label variable medIncome "the median household income by state by year"
*
//including polPerCap to gain a better sense of police presence
gen polPerCap = (policeForce/population)*100
label variable polPerCap "Number of employed police officers statewide in a given year divided by the state's population in that year."
*
//same logic applies for polPerMile
gen polPerMile = (policeForce/stateSize)*100
label variable polPerMile "Number of employed police officers statewide in a given year divided by the state's land area"
*
//cleaning data
replace stateDeficit = "." if stateDeficit == "-"
replace vehicleMiles = "." if vehicleMiles == "#######"
destring stateDeficit, replace
destring vehicleMiles, replace
//changing percentages to whole numbers for sake of ease of interpretation
replace pct18to24 = pct18to24 *100
*
//Looking at these traffic fatalities as a percentage of the population 
gen drunkPop = ((totKill * pctAlcFtl08)/population)*100
label variable drunkPop "Percentage of alcohol-related fatalities as it relates to the population"
graph box drunkPop, name(g1, replace)
*
*
//summary statistics
sum drunkPop beerTax pct18to24 polPerCap polPerMile unemployRate vehicleMiles 
*
//looking at alcohol culture seperately for sake of ease
sum scanner openContainer ignInt
*
//Distribution of beer taxes
graph hbox beerTax
*
//Prevalence of ignition interlock over time
graph bar (mean) ignInt, over(year)
*
//Distribution of dependent variable
graph box drunkPop
*
//Comparing raw data of drunk driving fatalities and beer taxes
graph twoway (scatter drunkPop beerTax) (lfit drunkPop beerTax)
*
*
//Budget Deficit per Capita (Instrumental Variable)
gen defPerCap = stateDeficit/population*100
label variable defPerCap "State Budget Deficit per Capita"
*
//Initial Regression
regress drunkPop beerTax
outreg2 using Regression, word bdec(5) bracket addstat(Adj R-Squared, `e(r2_a)') replace
*
//Including Controls
regress drunkPop beerTax ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24
outreg2 using Regression, word bdec(5) bracket addstat(Adj R-Squared, `e(r2_a)') append
*
//Including State and Time Fixed Effects
regress drunkPop beerTax ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24 i.stateid i.year
outreg2 using Regression, word bdec(5) bracket drop(i.stateid i.year) addstat(Adj R-Squared, `e(r2_a)') append
*
*
//2SLS Regressions
*
//Initial Regression
regress beerTax defPerCap
predict double beerHat
label variable beerHat "Manipulated beerTax based on exogenous variation"
regress drunkPop beerHat
outreg2 using Regression, word bdec(5) bracket addstat(Adj R-Squared, `e(r2_a)') append
*
//Including Controls
regress beerTax defPerCap ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24
predict double beerHat_2
label variable beerHat_2 "Manipulated beerTax based on exogenous variation"
regress drunkPop beerHat_2 ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24
outreg2 using Regression, word bdec(5) bracket addstat(Adj R-Squared, `e(r2_a)') append
*
//Including State and Time Fixed Effects
regress beerTax defPerCap ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24 i.stateid i.year
predict double beerHat_3
label variable beerHat_3 "Manipulated beerTax based on exogenous variation"
regress drunkPop beerHat_3 ignInt polPerCap vehicleMiles scanner openContainer unemployRate pct18to24 i.stateid i.year
outreg2 using Regression, word bdec(5) bracket drop(i.stateid i.year) addstat(Adj R-Squared, `e(r2_a)') append
*
*