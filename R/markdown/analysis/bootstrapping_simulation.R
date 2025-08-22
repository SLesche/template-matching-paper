## Bootstrapping ICC----

library(irr)
library(tidyverse)
library(future.apply)
library(data.table)

load("./markdown/analysis/processed_data/full_data_simulation_revision.Rdata")
source("./markdown/analysis/helper_functions_simulation.R")
source("./markdown/analysis/helper_funcs_analysis.R")

data_for_boot <- full_data %>% 
  ungroup() %>% 
  mutate(
    latency = ifelse(approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency)
  ) %>% 
  group_by(task_id, filter, approach, component, weight, penalty, normalize, simulation_id) %>% 
  mutate(
    is_outlier = is_outlier(latency)
  ) %>% 
  ungroup() %>% 
  mutate(lateny = ifelse(is_outlier == 0, latency, NA))

# ---- Original pipeline as a function ----
compute_icc <- function(data) {
  data %>% 
    pivot_wider(
      id_cols = c(task_id, method_id, simulation_id, filter, task_description, component, window_name, approach, weight, normalize, penalty, bootstrap_subject),
      names_from = is_simulation,
      values_from = c(simulation_shift, latency, fit_cor, fit_distance, b_param)
    ) %>% 
    mutate(true_shift = simulation_shift_1, empirical_shift = latency_0 / latency_1) %>% 
    # Average the empirical shift over simulations
    group_by(task_id, task_description, method_id, filter, component, window_name, approach, weight, normalize, penalty, bootstrap_subject) %>% 
    summarize(
      n = n(),
      n_na = sum(is.na(empirical_shift)),
      mean_true_shift = mean(true_shift, na.rm = TRUE),
      mean_emp_shift = mean(empirical_shift, na.rm = TRUE)
    ) %>%
    ungroup() %>%
    filter(n_na < 50) %>%
    group_by(filter, approach, window_name, weight, penalty) %>% 
    mutate(
      is_outlier = is_outlier(mean_emp_shift)
    ) %>%
    filter(is_outlier == 0) %>%
    group_by(filter, approach, window_name, weight, penalty) %>% 
    summarize(
      measurements = n(),
      missing = 1 - n() / (142),
      cor = cor(mean_true_shift, mean_emp_shift, use = "pairwise.complete.obs"),
      icc = custom_icc(mean_true_shift, mean_emp_shift)
    ) %>% 
    rename("component" = "window_name") %>% 
    group_by(approach, component, weight, penalty) %>% 
    summarize(missing = mean(missing), 
              cor = mean(cor),
              icc = mean(icc))
}

# ---- Bootstrap function ----

# ---- Safe memory-efficient bootstrap ----
bootstrap_icc_safe <- function(data, R = 1000, seed = 123, workers = 1, out_dir = tempdir()) {
  setDT(data)  # ensure data.table
  
  subjects <- unique(data$subject)
  
  # Store row indices per subject (lightweight)
  split_idx <- split(seq_len(nrow(data)), data$subject)
  
  # Make sure output directory exists
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Set up future plan (optional)
  if (workers > 1) {
    plan(multisession, workers = workers)
  } else {
    plan(sequential)
  }
  
  # Iterate over bootstrap samples
  future_lapply(seq_len(R), future.seed = seed, function(i) {
    sampled_ids <- sample(subjects, length(subjects), replace = TRUE)
    # Create a vector of unique bootstrap IDs for each sampled subject
    bootstrap_subject_id <- paste0(sampled_ids, "_", seq_along(sampled_ids))
    
    # Subset the data and add the bootstrap-specific subject ID
    boot_data <- rbindlist(
      Map(function(subj, bs_id) {
        dt <- data[split_idx[[subj]], ]
        dt[, bootstrap_subject := bs_id]
      }, sampled_ids, bootstrap_subject_id)
    )

    # Compute ICC
    icc_res <- compute_icc(boot_data)
    
    # Save this iteration to disk
    file_name <- file.path(out_dir, paste0("icc_boot_", sprintf("%04d", i), ".rds"))
    saveRDS(icc_res, file_name)
    
    return(NULL)  # keep memory usage minimal
  })
  
  # Combine all saved bootstrap results
  boot_files <- list.files(out_dir, pattern = "^icc_boot_\\d+\\.rds$", full.names = TRUE)
  icc_list <- lapply(boot_files, readRDS)
  icc_boot_results <- rbindlist(icc_list, idcol = "bootstrap_id")
  
  return(icc_boot_results)
}

# ---- Run bootstrap ----
options(future.globals.maxSize = 6 * 1024^3)  # 6 GB
icc_boot_results <- bootstrap_icc_safe(data_for_boot, R = 5000)

save(icc_boot_results, file = "./markdown/analysis/processed_data/bootstrap_icc_simulation.Rdata")

# ---- Summarize bootstrap CI ----
ci_summary_icc_simulation <- icc_boot_results %>%
  group_by(component, approach, weight, penalty) %>%
  summarize(
    mean_icc_boot = mean(icc , na.rm = TRUE),
    ci_lower = quantile(icc , 0.025, na.rm = TRUE),
    ci_upper = quantile(icc , 0.975, na.rm = TRUE),
    .groups = "drop"
  )

## Linear shift ----

load("./markdown/analysis/processed_data/full_data_simulation_linear_revision.Rdata")

data_for_boot <- full_data %>% 
  ungroup() %>% 
  mutate(
    latency = ifelse(approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency)
  ) %>% 
  group_by(task_id, filter, approach, component, weight, penalty, normalize, simulation_id) %>% 
  mutate(
    is_outlier = is_outlier(latency)
  ) %>% 
  ungroup() %>% 
  mutate(lateny = ifelse(is_outlier == 0, latency, NA))

# ---- Run bootstrap ----
options(future.globals.maxSize = 6 * 1024^3)  # 6 GB
icc_boot_results <- bootstrap_icc_safe(data_for_boot, R = 5000)

save(icc_boot_results, file = "./markdown/analysis/processed_data/bootstrap_icc_linear_simulation.Rdata")

# ---- Summarize bootstrap CI ----
ci_summary_icc_simulation <- icc_boot_results %>%
  group_by(component, approach, weight, penalty) %>%
  summarize(
    mean_icc_boot = mean(icc , na.rm = TRUE),
    ci_lower = quantile(icc , 0.025, na.rm = TRUE),
    ci_upper = quantile(icc , 0.975, na.rm = TRUE),
    .groups = "drop"
  )
