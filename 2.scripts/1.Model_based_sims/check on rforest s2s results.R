#####################################################################
#   The when, the why, and the how to impute (simulation generator) #
#   Translation of Stata code to R                                  #
#   Version: R edition – No Stata output                            #
#####################################################################

library(dplyr)
library(randomForest)
library(ggplot2)

set.seed(51564)                   # ensures replicability

## --- PARAMETERS ---------------------------------------------------
obsnum        <- 20000             # total observations
sigma_eps     <- 0.5               # residual SD
out_sample    <- 4000              # sample size
target_sample <- 4000              #Target size

## --- SIMULATE HOUSEHOLD DATA --------------------------------------
df <- tibble(
  hhid   = seq_len(obsnum),
  hhsize = 1,
  e      = rnorm(obsnum, 0, sigma_eps),
  x1     = pmax(1, rpois(obsnum, 4)),
  x2     = as.numeric(runif(obsnum) <= 0.20),
  x4     = rnorm(obsnum, 2.5, 2),
  x5     = rt(obsnum, df = 5) * 0.25
) %>%
  mutate(
    x3 = if_else(x2 == 1, as.numeric(runif(obsnum) < 0.5), 0),
    linear_fit = 3 + 0.1*x1 + 0.5*x2 - 0.25*x3 - 0.2*x4 - 0.15*x5,
    Y_B = linear_fit + e,
    e_y = exp(Y_B)
  )

## --- POVERTY LINES (CENTILES) -------------------------------------
plines <- quantile(df$e_y, probs = seq(0.05, 1, 0.05))
pline_values <- as.numeric(plines)

## --- ADD CENTILE GROUP (xtile) ------------------------------------
df <- df %>% mutate(NQ = ntile(e_y, 100))

## --- SIMPLE RANDOM SAMPLE (n = 20) --------------------------------
srs_sample <- df %>%
  sample_n(out_sample) %>%
  arrange(hhid)    # to mimic `sort hhid`
target_sample <- df %>%
  sample_n(target_sample) %>%
  arrange(hhid)    # to mimic `sort hhid`

## --- Now fit model using OLS
ols_model <- lm(Y_B ~ x1 + x2 + x3 + x4 + x5, data = srs_sample)
rf_model <- randomForest(Y_B ~ x1 + x2 + x3 + x4 + x5, data = srs_sample)

#Now predict Yhat
srs_sample$Y_ols <- predict(ols_model, newdata = srs_sample)
srs_sample$Y_rf  <- predict(rf_model,  newdata = srs_sample)

#Predict residuals
srs_sample$e_ols = srs_sample$Y_B - srs_sample$Y_ols
srs_sample$e_rf  = srs_sample$Y_B - srs_sample$Y_rf

#predict yhat to target
target_sample$Y_ols <- predict(ols_model, newdata = target_sample)
target_sample$Y_rf  <- predict(rf_model,  newdata = target_sample)


#Poverty
y_ols_draws <- replicate(100, target_sample$Y_ols + sample(srs_sample$e_ols, nrow(target_sample), replace = TRUE))
y_rf_draws  <- replicate(100, target_sample$Y_rf  + sample(srs_sample$e_rf,  nrow(target_sample), replace = TRUE))

# Names of the draw matrices (as strings)
draw_names <- c("ols", "rf")

results <- list()

# Loop over each matrix and compute poverty shares
for (name in draw_names) {
  draws <- get(paste0("y_", name, "_draws"))
  poverty_shares <- sapply(pline_values, function(pl) {
    colMeans(draws < log(pl))
  })
  # Transpose so: rows = poverty lines, cols = draws
  poverty_shares <- t(poverty_shares)
  rownames(poverty_shares) <- names(plines)
  poverty_means <- rowMeans(poverty_shares)
  
  # Convert row names like "5%" to numeric: 0.05
  results[[name]] <- poverty_means
}

# Convert row names like "5%" to numeric: 0.05
true_percentile <- as.numeric(sub("%", "", names(results$ols)))/100

# Difference = estimated share – true percentile
poverty_diff_ols <- (results$ols - true_percentile)
poverty_diff_rf  <- (results$rf - true_percentile)

plot_df <- data.frame(
  percentile = true_percentile,  # convert to percentage for x-axis
  OLS = poverty_diff_ols,
  RF  = poverty_diff_rf
) %>%
  tidyr::pivot_longer(cols = c("OLS", "RF"), names_to = "Model", values_to = "Difference")

ggplot(plot_df, aes(x = percentile, y = Difference, color = Model)) +
  geom_line(data = subset(plot_df, Model == "OLS"), size = 1) +
  geom_point(data = subset(plot_df, Model == "RF"), size = 2) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  labs(
    x = "True Percentile (Poverty Line)",
    y = "Difference (% points)",
    title = "Bias in Poverty Estimates across Percentiles",
    subtitle = "Imputed estimates vs. true distribution"
  ) +
  scale_x_continuous(breaks = seq(0, 1, 0.05)) +
  theme_minimal() +
  theme(legend.position = "top")