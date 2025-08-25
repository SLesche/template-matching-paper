## Bootstrapping REL----
library(tidyverse)
library(future.apply)

load("./markdown/analysis/processed_data/long_data_exp23_revision.Rdata")
source("./markdown/analysis/helper_functions_exp23.R")
source("./markdown/analysis/helper_funcs_analysis.R")

data_for_boot <- full_data %>% 
  mutate(
    latency = ifelse(
      approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5),
      NA,
      latency
    )
  ) %>%
  group_by(task, filter, group, bin, approach, component, weight, penalty, normalization) %>%
  mutate(is_outlier = is_outlier(latency)) %>%
  ungroup() %>%
  mutate(latency = ifelse(is_outlier == 0, latency, NA)) %>%
  pivot_wider(
    id_cols = c("task", "group", "filter", "component", "approach", "weight", "penalty", "subject"),
    names_from = "bin",
    names_prefix = "bin_",
    values_from = "latency"
  )

# ---- Original pipeline as a function ----
compute_reliabilities <- function(data) {
  data %>%
    group_by(task, filter, group, component, approach, weight, penalty) %>%
    summarize(
      alpha_1 = performance::cronbachs_alpha(data.frame(as.numeric(bin_1), as.numeric(bin_2))),
      alpha_2 = performance::cronbachs_alpha(data.frame(as.numeric(bin_3), as.numeric(bin_4))),
      n = n(),
      .groups = "drop"
    ) %>%
    pivot_longer(
      cols = c("alpha_1", "alpha_2"),
      names_to = "condition_alpha",
      values_to = "reliability"
    ) %>%
    filter(!grepl("manual", approach)) %>% 
    group_by(component, approach, weight, penalty) %>% 
    summarize(
      mean_rel = mean(reliability, na.rm = TRUE),
      meadian_rel = median(reliability, na.rm = TRUE),
      max_rel = max(reliability, na.rm = TRUE),
      min_rel = min(reliability, na.rm = TRUE),
      n = n()
    ) 
}

# ---- Bootstrap function ----
bootstrap_reliabilities <- function(data, R = 1000, seed = 123, workers = parallel::detectCores() - 1) {
  subjects <- unique(data$subject)
  
  # Pre-split data by subject
  split_data <- split(data, data$subject)
  
  plan(multisession, workers = workers)
  
  results <- future_lapply(seq_len(R), future.seed = seed, function(i) {
    sampled_ids <- sample(subjects, length(subjects), replace = TRUE)
    boot_data <- data.table::rbindlist(split_data[sampled_ids])
    compute_reliabilities(boot_data)
  })
  
  data.table::rbindlist(results, idcol = "bootstrap_id")
}

# ---- Run bootstrap ----
rel_boot_results <- bootstrap_reliabilities(data_for_boot, R = 5000)

save(rel_boot_results, file = "./markdown/analysis/processed_data/bootstrap_reliability_kathrin.Rdata")

# ---- Summarize bootstrap CI ----
ci_summary_rel <- rel_boot_results %>%
  group_by(component, approach, weight, penalty) %>%
  summarize(
    mean_reliability = mean(mean_rel , na.rm = TRUE),
    ci_lower = quantile(mean_rel , 0.025, na.rm = TRUE),
    ci_upper = quantile(mean_rel , 0.975, na.rm = TRUE),
    .groups = "drop"
  )



## Bootstrapping ICC----

library(irr)

load("./markdown/analysis/processed_data/long_data_exp23_revision.Rdata")
source("./markdown/analysis/helper_functions_exp23.R")
source("./markdown/analysis/helper_funcs_analysis.R")

manual_peak <- full_data %>% 
  filter(approach == "individualmanual", component == "p3_peak") %>% 
  mutate(manual_peak_lat = latency) %>% 
  select(task, filter, group, bin, subject, manual_peak_lat)

manual_area <- full_data %>% 
  filter(approach == "individualmanual", component == "p3_area") %>% 
  mutate(manual_area_lat = latency) %>% 
  select(task, filter, group, bin, subject, manual_area_lat)

cor_data <- full_data %>% 
  filter(approach != "individualmanual", approach != "jackknifemanual") %>% 
  left_join(., manual_peak, by = c("task", "filter", "group", "bin", "subject")) %>% 
  left_join(., manual_area, by = c("task", "filter", "group", "bin", "subject"))

data_for_boot <- cor_data %>%
  mutate(
    latency = ifelse(
      approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency
    )
  ) %>%
  filter(bin %in% c(5, 6)) %>%
  group_by(task, filter, group, bin, approach, component, weight, penalty, normalization) %>% 
  mutate(
    is_outlier = is_outlier(latency)
  ) %>% 
  ungroup() %>% 
  mutate(latency = ifelse(is_outlier == 0, latency, NA))

# ---- Original pipeline as a function ----
compute_icc <- function(data) {
  boot_data %>%
    group_by(task, filter, group, bin, approach, component, weight, penalty, normalization) %>% 
    summarize(
      cor_with_peak = custom_icc(latency, manual_peak_lat),
      cor_with_area = custom_icc(latency, manual_area_lat)
    ) %>% 
    pivot_longer(
      cols = starts_with("cor_with"),
      names_to = "manual_approach",
      values_to = "icc"
    ) %>% 
    mutate(
      manual_approach = str_extract(manual_approach, "[a-z]+$")
    ) %>% 
    group_by(component, approach, weight, penalty) %>% 
    summarize(
      mean_icc = mean(icc, na.rm = TRUE),
      median_icc = median(icc, na.rm = TRUE),
      min_icc = min(icc, na.rm = TRUE),
      max_icc = max(icc, na.rm = TRUE),
      n = n()
    )
}

# ---- Bootstrap function ----
bootstrap_icc <- function(data, R = 1000, seed = 123, workers = parallel::detectCores() - 1) {
  subjects <- unique(data$subject)
  split_data <- split(data, data$subject)
  
  plan(multisession, workers = workers)
  
  results <- future_lapply(seq_len(R), future.seed = seed, function(i) {
    sampled_ids <- sample(subjects, length(subjects), replace = TRUE)
    boot_data <- data.table::rbindlist(split_data[sampled_ids])
    compute_icc(boot_data)
  })
  
  data.table::rbindlist(results, idcol = "bootstrap_id")
}

# ---- Run bootstrap ----
icc_boot_results <- bootstrap_icc(data_for_boot, R = 5000)

save(icc_boot_results, file = "./markdown/analysis/processed_data/bootstrap_icc_kathrin.Rdata")

# ---- Summarize bootstrap CI ----
ci_summary_icc <- icc_boot_results %>%
  group_by(component, approach, weight, penalty) %>%
  summarize(
    mean_icc_boot = mean(mean_icc , na.rm = TRUE),
    ci_lower = quantile(mean_icc , 0.025, na.rm = TRUE),
    ci_upper = quantile(mean_icc , 0.975, na.rm = TRUE),
    .groups = "drop"
  )
