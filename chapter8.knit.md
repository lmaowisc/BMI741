---
title: "Chapter 8 - Multivariate Failure Times"
---


## Slides

Lecture slides [here](chap8.html){target="_blank"}. (To convert html to pdf, press E $\to$ Print $\to$ Destination: Save to pdf)

## Base R Code


::: {.cell}

```{.r .cell-code  code-fold="true" code-summary="Show the code"}
##################################################################
# This code generates all numerical results in chapter 8.      ##
##################################################################

library("survival")

################################
# NCCTG lung cancer study      #
################################

## read in the NCCTG lung cancer study
## (clustered data by institution)
data <- read.table("Data//NCCTG//lung.txt")
head(data)




## Follow up plot
library(tidyverse)
library(patchwork)

# function to plot follow-up by
# institution and sex
inst_by_sex_fu_plot <- function(df){
  
  df |> 
  ggplot(aes(y = reorder(id, time), x = time, color = factor(2 - sex))) +
  geom_linerange(aes(xmin = 0, xmax = time)) +
  geom_point(aes(shape = factor(status)), size = 2, fill = "white") +
  geom_vline(xintercept = 0, linewidth = 1) +
  facet_grid(inst ~ ., scales = "free", space = "free", switch = "y")   +
  theme_minimal() +
  scale_x_continuous("Time (months)", limits = c(0, 36), breaks = seq(0, 36, by = 12),
                     expand = c(0, 0.25)) +
  scale_y_discrete("Patients (by institution)") +
  scale_shape_manual(values = c(23, 19), labels = c("Censoring", "Death")) +
  scale_color_brewer(palette = "Set1", labels = c("Female", "Male"))+
  theme(
    strip.background =  element_rect(fill = "gray90", color = "gray90"),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.y = element_blank(),
    panel.grid.major.y = element_blank(),
    legend.title = element_blank()
  )
  
}

p1 <- inst_by_sex_fu_plot(data |> filter(inst <= 11))

p2 <- inst_by_sex_fu_plot(data |> filter(inst > 11))

mul_lung_fu <- p1 + p2 + plot_layout(ncol = 2, guides = "collect") & theme(legend.position = "top")

# ggsave("mul_lung_fu.pdf", mul_lung_fu, width = 8, height = 10)
# ggsave("mul_lung_fu.eps", mul_lung_fu, width = 8, height = 10)


# Fit a Cox model with institution-specific frailty
# to account for correlation within institution
obj <- coxph(Surv(time, status) ~ age+ factor(sex) + phec + phkn + ptkn +
        wl + frailty(inst, distribution="gamma"), data = data)

summary(obj)

# fit a naive Cox model without institution-specific frailty
obj.naive <- coxph(Surv(time,status)~age+factor(sex)+phec+phkn+ptkn +
                           wl,data=data)

summary(obj.naive)


####################################################
#  Prediction of subject-specific survival curves
#  
################################################

# Median age
med_age <- median(data$age)
# Median ph.karno
med_phkn <- median(data$phkn,na.rm=T)
# Median pat.karno
med_ptkn <- median(data$ptkn,na.rm=T)
# Median wt.loss
med_wl <- median(data$wl,na.rm=T)

# Extract the regression coefficients
beta <- obj$coefficients
# Extract the (only) baseline function
base_obj <- basehaz(obj,centered=F)
eta <- base_obj$hazard
t <- base_obj$time


# Figure 8.2 Prediction of survival probabilities for a typical patient 
# of median age (63 years), with median physician-
#         and patient-rated Karnofsky scores (each 80), and with median
# weighted loss (7 pounds) by sex and ECOG score.

# Obtain the covariate profiles.
## Female
zf0 <- c(med_age,1,0,med_phkn,med_ptkn,med_wl)
zf1 <- c(med_age,1,1,med_phkn,med_ptkn,med_wl)                              
zf2 <- c(med_age,1,2,med_phkn,med_ptkn,med_wl) 
zf3 <- c(med_age,1,3,med_phkn,med_ptkn,med_wl) 

## Male
zm0 <- c(med_age,0,0,med_phkn,med_ptkn,med_wl)
zm1 <- c(med_age,0,1,med_phkn,med_ptkn,med_wl)                              
zm2 <- c(med_age,0,2,med_phkn,med_ptkn,med_wl) 
zm3 <- c(med_age,0,3,med_phkn,med_ptkn,med_wl) 

# Plot the preducted survival curves
par(mfrow=c(1,2))
plot(t,exp(-exp(sum(beta*zf0))*eta),type="s",xlim=c(0,35),
     ylim=c(0,1),frame=F,lty=1,main="Female",
     xlab="Time (months)",ylab="Survival probabilities",lwd=2,cex.lab=1.3,
     cex.axis=1.3,cex.main=1.3)
lines(t,exp(-exp(sum(beta*zf1))*eta),lty=2,lwd=2)
lines(t,exp(-exp(sum(beta*zf2))*eta),lty=3,lwd=2)
lines(t,exp(-exp(sum(beta*zf3))*eta),lty=4,lwd=2)
legend("topright",lty=1:4,lwd=2,cex=1.2,paste("ECOG",0:3))

plot(t,exp(-exp(sum(beta*zm0))*eta),type="s",xlim=c(0,35),
     ylim=c(0,1),frame=F,lty=1,main="Male",
     xlab="Time (months)",ylab="Survival probabilities",lwd=2,cex.lab=1.3,
     cex.axis=1.3,cex.main=1.3)
lines(t,exp(-exp(sum(beta*zm1))*eta),lty=2,lwd=2)
lines(t,exp(-exp(sum(beta*zm2))*eta),lty=3,lwd=2)
lines(t,exp(-exp(sum(beta*zm3))*eta),lty=4,lwd=2)
legend("topright",lty=1:4,lwd=2,cex=1.2,paste("ECOG",0:3))



################################
# Diabetic retinopathy study   #
################################

# read in the data
data <- read.table("Data//Diabetic Retinopathy Study//drs.txt")
head(data)

# fit a bivariate marginal Cox model
# with treatment, diabetic type
# risk score, and treatment*type interaction
# as covariates
obj <- coxph(Surv(time, status) ~ trt + type + trt * type + risk
             + cluster(id), data = data)

summary(obj)

# Table 8.1 Marginal Cox model analysis of the Diabetic Retinopathy Study
# output table
coeff <- summary(obj)$coeff
# beta estimate
c1 <- coeff[,1]
# robust se and p-value
c2 <- coeff[,4]
c3 <- coeff[,6]
# naive se and p-value
c4 <- coeff[,3]
c5 <- 1-pchisq((c1/c4)^2,1)

#output the table
noquote(round(cbind(c1,c2,c3,c4,c5),3))



# Fig. 8.4 Prediction of vision-retention probabilities 
# for patients with a median risk
# score (10) by treatment for each diabetic type.

# Lambda_0(t) and t
Lt <- basehaz(obj,centered = F)
t <- Lt$time
L <- Lt$hazard

# beta
beta <- coeff[,1]

# plot the predicted survival functions

par(mfrow=c(1,2))
# Compute the survival function for 
# adult and juvenile patients in control and treatment
adult.contr <- exp(-exp(sum(beta*c(0,0,10,0)))*L)
adult.trt <- exp(-exp(sum(beta*c(1,0,10,0)))*L)
juv.contr <- exp(-exp(sum(beta*c(0,1,10,0)))*L)
juv.trt <- exp(-exp(sum(beta*c(1,1,10,1)))*L)

# Plot the predicted survival curves
plot(t,adult.contr,type="s",xlim=c(0,80),ylim=c(0,1),frame.plot=F,lty=3,main="Adult",
     xlab="Time (months)",ylab="Vision-retention probabilities",lwd=2, cex.lab=1.2,
     cex.axis=1.2,cex.main=1.2)
lines(t,adult.trt,lty=1,lwd=2)

plot(t,juv.contr,type="s",xlim=c(0,80),ylim=c(0,1),frame.plot=F,lty=3,main="Juvenile",
     xlab="Time (months)",ylab="Vision-retention probabilities",lwd=2,cex.lab=1.2,
     cex.axis=1.2,cex.main=1.2)
lines(t,juv.trt,lty=1,lwd=2)
```
:::


## Descriptive analysis of TOPCAT trial


::: {.cell}

```{.r .cell-code}
library(survival)
library(tidyverse)
library(knitr)

##########################
#   TOPCAT               #
##########################

# read in the data
topcat <- read.table("Data//TOPCAT//topcat.txt")
# head(topcat)

# median follow-up
topcat |> 
  group_by(id) |> 
  slice_max(time) |> 
  slice_head() |> 
  ungroup() |> 
  summarize(
    median(time)
  )
```

::: {.cell-output .cell-output-stdout}
```
# A tibble: 1 × 1
  `median(time)`
           <dbl>
1           3.55
```
:::

```{.r .cell-code}
# table(topcat$drug)
# table(topcat$race)

# topcat |> 
#   count(endpoint, status)


# Descriptive analysis ----------------------------------------------------

## clean up data

tmp <- topcat |> 
  mutate( # clean up the levels of drug, gender
    drug = if_else(drug == "Spiro", "Spironolactone", "Placebo"),
    gender = if_else(gender == "1:Male", "Male", "Female")
  ) 
  
## de-duplicate
df <- tmp |> 
  pivot_wider( # flatten endpoints
    id_cols = id,
    # names_prefix = c(time, status),
    names_from = endpoint,
    values_from = c(time, status),
  ) |> # join with baseline data
  left_join(
    tmp |> filter(endpoint == "HF"),
    join_by(id)
  )

## a function to compute median (IQR) for x
## rounded to the rth decimal place
med_iqr <- function(x, r = 1){
  qt <- quantile(x, na.rm = TRUE)
  
  str_c(round(qt[3], r), " (", 
        round(qt[2], r), ", ",
        round(qt[4], r), ")")
}

# create summary table for quantitative variables
# age, size, nodes, prog, estrg
tab_quant <- df |> 
  filter(endpoint == "HF") |> 
  group_by(drug) |> 
  summarize(
    across(c(age,  bmi, hr), med_iqr)
  ) |> 
  pivot_longer( # long format: value = median (IQR); name = variable names
    !drug,
    values_to = "value",
    names_to = "name"
  ) |> 
  pivot_wider( # wide format: name = variable names; hormone levels as columns
    values_from = value,
    names_from = drug
  ) |> 
  mutate(
    name = case_when( # format the variable names
      name == "age" ~ "Age (years)",
      name == "bmi" ~ "BMI (kg/m^2)",
      name == "hr" ~ "Heart rate (per min)"
    )
  )

## a function that computes N (%) for each level of var
## by group in data frame df (percent rounded to rth point)
freq_pct<- function(df, group, var, r = 1){
  # compute the N for each level of var by group
  var_counts <- df |> 
    group_by({{ group }}, {{ var }}) |> 
    summarize(
      n = n(),
      .groups = "drop"
    ) 
  # compute N (%)
  var_counts |> 
    left_join( # compute the total number (demoninator) in each group
      # and joint it back to the numerator
      var_counts |> group_by({{ group }}) |> summarize(N = sum(n)),
      by = join_by({{ group }})
    ) |> 
    mutate( # N (%)
      value = str_c(n, " (", round(100 * n / N, r), "%)")
    ) |> 
    select(- c(n, N)) |> 
    pivot_wider( # put group levels on columns
      names_from = {{ group }},
      values_from = value
    ) |> 
    rename(
      name = {{ var }} # name = variable names 
    )
}

## gender
gender <- df |>
  freq_pct(drug, gender) |> 
  mutate(
    name = str_c("Gender - ", name)
  )
## race
race <- df |>
  freq_pct(drug, race) |> 
  mutate(
    name = str_c("Race - ", name)
  )
## nyha
nyha <- df |>
  freq_pct(drug, nyha) |> 
  mutate(
    name = str_c("NYHA - ", name)
  ) |> 
  filter(!is.na(name))




## function to compute N (%) for binary condition
bin_pct <- function(condition, r = 1){
  n <- sum(condition, na.rm = TRUE)
  N <- n()
  str_c(n, " (", round(100 * n / N, r), "%)")
}

## tabulate binary variables, including number of endpoints
tabin <- df |> 
  group_by(drug) |> 
  summarize(
    N = n(),
    across(c(smoke:cabg, status_HF, status_MI, status_Stroke), bin_pct)
  ) |> 
  select(!N) |> 
  pivot_longer( # long format: value = median (IQR); name = variable names
    !drug,
    values_to = "value",
    names_to = "name"
  ) |> 
  pivot_wider( # wide format: name = variable names; hormone levels as columns
    values_from = value,
    names_from = drug
  ) |> 
  mutate(
      name = case_when( # format the variable names
      name == "smoke" ~ "Smoker",
      name == "chf_hosp" ~ "CHF",
      name == "copd" ~ "COPD",
      name == "asthma" ~ "Asthma",
      name == "dm" ~ "Diabetes",
      name == "htn" ~ "Hypertension",
      name == "cabg" ~ "Coronary surgery",
      name == "status_HF" ~ "HF",
      name == "status_MI" ~ "MI",
      name == "status_Stroke" ~ "Stroke"
    )
  )

## tabulate event rates
event_rates <- df |> 
  group_by(drug) |> 
  summarize(
    `HF rate (per person-year)` = sum(status_HF) / sum(time_HF),
    `MI rate (per person-year)` = sum(status_MI) / sum(time_MI),
    `Stroke rate (per person-year)` = sum(status_Stroke) / sum(time_Stroke)
  ) |> 
  pivot_longer( # long format: value = median (IQR); name = variable names
    !drug,
    values_to = "value",
    names_to = "name"
  ) |> 
  pivot_wider( # wide format: name = variable names; hormone levels as columns
    values_from = value,
    names_from = drug
  ) |> 
  mutate(
    Placebo = as.character(round(Placebo, 4)),
    Spironolactone = as.character(round(Spironolactone, 4))
  )


## combine tables

tabone <- bind_rows(
  tab_quant[1, ],
  gender,
  race,
  nyha,
  tab_quant[- 1, ],
  tabin,
  event_rates
)

## add N to group names  
colnames(tabone) <- c(" ", str_c(colnames(tabone)[2:3], " (N=", table(df$drug),")"))
## print out the table
kable(tabone)
```

::: {.cell-output-display}
|                              |Placebo (N=1446)  |Spironolactone (N=1465) |
|:-----------------------------|:-----------------|:-----------------------|
|Age (years)                   |68 (60, 74)       |68 (60, 75)             |
|Gender - Female               |763 (52.8%)       |790 (53.9%)             |
|Gender - Male                 |683 (47.2%)       |675 (46.1%)             |
|Race - Caucasian              |1422 (98.3%)      |1432 (97.7%)            |
|Race - Other                  |24 (1.7%)         |33 (2.3%)               |
|NYHA - 1-2                    |993 (68.7%)       |1003 (68.5%)            |
|NYHA - 3-4                    |451 (31.2%)       |461 (31.5%)             |
|BMI (kg/m^2)                  |30.8 (27.2, 35.6) |31.1 (27.3, 35.6)       |
|Heart rate (per min)          |68 (61.2, 76)     |68 (61, 75)             |
|Smoker                        |154 (10.7%)       |146 (10%)               |
|CHF                           |1057 (73.1%)      |1057 (72.2%)            |
|COPD                          |152 (10.5%)       |166 (11.3%)             |
|Asthma                        |84 (5.8%)         |93 (6.3%)               |
|Diabetes                      |439 (30.4%)       |456 (31.1%)             |
|Hypertension                  |1335 (92.3%)      |1336 (91.2%)            |
|Coronary surgery              |173 (12%)         |171 (11.7%)             |
|HF                            |147 (10.2%)       |127 (8.7%)              |
|MI                            |40 (2.8%)         |44 (3%)                 |
|Stroke                        |36 (2.5%)         |29 (2%)                 |
|HF rate (per person-year)     |0.0303            |0.0255                  |
|MI rate (per person-year)     |0.0079            |0.0086                  |
|Stroke rate (per person-year) |0.0071            |0.0056                  |
:::
:::

