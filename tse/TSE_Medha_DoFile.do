clear 

*********** Importing the debt-to-GDP dataset from the RBI website ***************
*********** (The dataset has been cleaned and only consists of the long-term *****
*********** external debt-to-GDP ratio from 1951 to 2024) ************************

import excel "C:\MDAE\TSE\debt-to-gdp - Copy.xlsx"

* Describe is used to get an idea of the structure and type of variables
describe

* Renaming columns to meaningful variable names
rename A year
rename B debtgdp_raw

* Converting string variables to numeric format
gen year_num = real(year)
gen debtgdp = real(debtgdp_raw)

* Dropping the first row (header) which got converted to '.'
drop if year_num == .
drop if debtgdp == .

* Dropping original string variables
drop year debtgdp_raw

* Renaming cleaned numeric variable to 'year'
rename year_num year

* Declaring the dataset as time series with annual frequency
tsset year, yearly

corrgram debtgdp, lags(12)
* Plotting the original series to visualize the trend
tsline debtgdp
graph export debt_to_gdp_plotted.png, replace


* Running Dickey-Fuller test to check for stationarity
dfuller debtgdp

* Interpretation:
* Fail to reject the null hypothesis of unit root as p-value = 0.5730 > 0.05
* Conclusion: The series is non-stationary

* First-differencing the series to attempt stationarity
gen d_debtgdp = D.debtgdp

* Plotting the differenced series
tsline d_debtgdp

* Running Dickey-Fuller test again on the differenced series
dfuller d_debtgdp

* Interpretation:
* Strongly reject the null hypothesis (p-value = 0.0000)
* Conclusion: The differenced series is stationary ⇒ debtgdp is I(1)

* Plotting ACF and PACF to understand autocorrelation in the differenced series
ac d_debtgdp
pac d_debtgdp
corrgram d_debtgdp, lags(12)

* Interpretation:
* ACF and PACF show no significant spikes — all values are within 95% confidence bounds
* This suggests the series is white noise after differencing
* Therefore, ARIMA(0,1,0) is appropriate

* Estimating ARIMA model: 0 AR terms, 1 difference, 0 MA terms
* noconstant: assuming a random walk without drift
arima debtgdp, arima(0,1,0) noconstant

* Checking AIC and BIC for model selection
estat ic

* Output from estat ic:
* Log likelihood = -76.17428
* Akaike Information Criterion (AIC) = 154.35
* Bayesian Information Criterion (BIC) = 155.85

* Interpretation:
* These values help compare different ARIMA models. Lower AIC/BIC = better model.
* Since ARIMA(0,1,0) has the lowest complexity and no strong patterns remain, it is preferred.

* Interpretation:
* The model treats the series as a random walk — each year's value depends only on the previous year

* Predicting future values starting from 2024 onward
predict yhat, dynamic(2024)
rename yhat forecasted_debtgdp
label variable forecasted_debtgdp "Forecasted Debt-to-GDP"

* Plotting actual vs forecasted debt-to-GDP ratio
tsline debtgdp forecasted_debtgdp

* Interpretation:
* Forecasts closely follow the last observed value, which is expected under a random walk



