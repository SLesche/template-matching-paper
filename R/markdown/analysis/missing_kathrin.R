library(tidyverse)

load("./markdown/analysis/processed_data/long_data_exp23_revision.Rdata")
source("./markdown/analysis/helper_functions_exp23.R")
source("./markdown/analysis/helper_funcs_analysis.R")

missing_data_kathrin <- full_data %>% 
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
  mutate(lateny = ifelse(is_outlier == 0, latency, NA)) %>% 
  group_by(task, filter, group, bin, approach, component, weight, penalty, normalization) %>% 
  summarize(
    n = n(),
    n_missing = sum(is.na(latency)),
    freq_missing = round(100 * sum(is.na(latency)) / n(), 2)
  )

mean_missing_by_method_kathrin <- missing_data_kathrin %>% 
  group_by(component, approach, weight, penalty) %>% 
  summarize(
    mean_missing = mean(freq_missing),
    median_missing = median(freq_missing)
  )

mean_missing_by_method_task_kathrin <- missing_data_kathrin %>% 
  group_by(task, component, approach, weight, penalty) %>% 
  summarize(
    mean_missing = mean(freq_missing),
    median_missing = median(freq_missing)
  )

mean_missing_by_method_filter_kathrin <- missing_data_kathrin %>% 
  group_by(filter, component, approach, weight, penalty) %>% 
  summarize(
    mean_missing = mean(freq_missing),
    median_missing = median(freq_missing)
  )

# Direct computation for rmarkdown
mean_missing_minsq_nopenalty_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "minsq", penalty == "none") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_maxcor_nopenalty_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "maxcor", penalty == "none") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_minsq_penalty_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "minsq", penalty == "exponential_penalty") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_maxcor_penalty_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "maxcor", penalty == "exponential_penalty") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_peak_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "peak", component == "p3_250_900") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_area_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "area", component == "p3_250_700") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_liesefeld_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "liesefeld_area", component == "p3_250_700") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_liesefeldp2p_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "liesefeld_p2p_area", component == "p3_250_700") %>% pull(mean_missing) %>%
  mean() %>% print_percent()

mean_missing_manual_kathrin <- mean_missing_by_method_kathrin %>% 
  filter(approach == "individualmanual") %>% pull(mean_missing) %>%
  mean() %>% print_percent()


# Tables for presentation
missing_note <- "Frequency of missing values per algorithm. The rows indicate combinations of similarity measure and weighting function. The columns denote the measurement window and indicate if a penalty was used."
overview_table_missing_kathrin <- mean_missing_by_method_kathrin %>% 
  prepare_data_kathrin("mean_missing", c("approach", "weight"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.1, "less", missing_note, 2, c(4, 8))

overview_table_missing_by_task_kathrin <- mean_missing_by_method_task_kathrin %>% 
  prepare_data_kathrin("mean_missing", c("approach", "weight", "task"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.1, "less", missing_note, 3, seq(3, 33, 3))

overview_table_missing_by_filter_kathrin <- mean_missing_by_method_filter_kathrin %>% 
  prepare_data_kathrin("mean_missing", c("approach", "weight", "filter"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.1, "less", missing_note, 3, seq(5, 55, 5))