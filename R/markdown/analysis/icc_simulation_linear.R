library(DBI)
library(RSQLite)
library(tidyverse)


source("./markdown/analysis/helper_functions_simulation.R")
compute_new = FALSE

if(compute_new == TRUE){
  possible_filters <- c("4hz", "8hz", "16hz", "32hz")
  data_list <- vector(mode = "list", length(possible_filters))
  
  for (i in seq_along(data_list)){
    
    query <- paste0(
      "SELECT * FROM data
     JOIN method ON data.method_id = method.method_id
     JOIN task ON method.task_id = task.task_id"
    )
    
    conn = dbConnect(SQLite(), paste0("../scripts/results//simulation_results_exp23_", possible_filters[i], "_revision_linear_spline.db"))
    
    data = dbGetQuery(conn, query)
    data[, c(1, 2, 12)] = c()
    data_list[[i]] = data
    
    dbDisconnect(conn)
  }
  
  full_data <- data.table::rbindlist(data_list)
  
  mean_missing_by_method_simulation <- full_data %>% 
    ungroup() %>% 
    mutate(
      latency = ifelse(approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency)
    ) %>% 
    group_by(task_id, filter, approach, component, weight, penalty, normalize, simulation_id) %>% 
    mutate(
      is_outlier = is_outlier(latency)
    ) %>% 
    ungroup() %>% 
    mutate(lateny = ifelse(is_outlier == 0, latency, NA)) %>% 
    group_by(window_name, approach, weight, penalty) %>% 
    summarize(
      n = n(),
      missing = round(100* sum(is.na(latency))/n(), 2)
    ) %>% 
    rename("component" = "window_name")
  
  fit_dist_plot <- full_data %>% 
    filter(approach %in% c("minsq", "maxcor")) %>% 
    # filter(weight == "get_normalized_weights") %>% 
    group_by(approach, weight, component, penalty) %>% 
    ggplot(
      aes(
        x = fit_cor,
        group = interaction(approach),
        fill = approach
      )
    )+
    geom_density(alpha = 0.5)+
    facet_wrap(~weight, ncol = 2)+
    labs(
      x = "Correlation-based fit statistic (fit_cor)",
      y = "density"
    )+
    theme_classic()+
    geom_vline(xintercept = 0.3, color = "red", linewidth = 1.2)+
    theme(text=element_text(size=30),
          axis.text.x = element_text(size=20),
    )
  
  save(mean_missing_by_method_simulation, file = "./markdown/analysis/processed_data/mean_missing_by_method_simulation_revision_linear_spline.Rdata")
  
  average_data <- full_data %>% 
    mutate(
      latency = ifelse(approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency)
    ) %>% 
    pivot_wider(
      id_cols = c(task_id, method_id, simulation_id, filter, task_description, component, window_name, approach, weight, normalize, penalty, subject),
      names_from = is_simulation,
      values_from = c(simulation_shift, latency, fit_cor, fit_distance, b_param)
    ) %>% 
    mutate(true_shift = simulation_shift_1, empirical_shift = latency_1 - latency_0) %>% 
    # Average the empirical shift over simulations
    group_by(task_id, task_description, method_id, filter, component, window_name, approach, weight, normalize, penalty, subject) %>% 
    summarize(
      n = n(),
      n_na = sum(is.na(empirical_shift)),
      mean_true_shift = mean(true_shift, na.rm = TRUE),
      mean_emp_shift = mean(empirical_shift, na.rm = TRUE)
    ) %>%
    ungroup()
  
  save(average_data, file = "./markdown/analysis/processed_data/average_data_simulation_revision_linear_spline.Rdata")
} else {
  load(file = "./markdown/analysis/processed_data/mean_missing_by_method_simulation_revision_linear_spline.Rdata")
  load(file = "./markdown/analysis/processed_data/average_data_simulation_revision_linear_spline.Rdata")
}
# Direct computation for rmarkdown
mean_missing_minsq_nopenalty_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "minsq", penalty == "none") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_maxcor_nopenalty_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "maxcor", penalty == "none") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_minsq_penalty_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "minsq", penalty == "exponential_penalty") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_maxcor_penalty_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "maxcor", penalty == "exponential_penalty") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_minsq_nopenalty_normalized_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "minsq", penalty == "none", weight == "get_normalized_weights") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_maxcor_nopenalty_normalized_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "maxcor", penalty == "none", weight == "get_normalized_weights") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_peak_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "peak", component == "p3_250_900") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_area_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "area", component == "p3_250_700") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_liesefeld_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "liesefeld_area", component == "p3_250_700") %>% pull(missing) %>%
  mean() %>% print_percent()

mean_missing_liesefeldp2p_simulation <- mean_missing_by_method_simulation %>% 
  filter(approach == "liesefeld_p2p_area", component == "p3_250_700") %>% pull(missing) %>%
  mean() %>% print_percent()

missing_note <- "Frequency of missing values per algorithm. The rows indicate combinations of similarity measure and weighting function. The columns denote the measurement window and indicate if a penalty was used."
overview_table_missing_simulation <- mean_missing_by_method_simulation %>% 
  prepare_data_kathrin("missing", c("approach", "weight"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.1, "less", missing_note, 2, c(4, 8))


mean_icc_by_method_filter_simulation <- average_data %>%
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
  rename("component" = "window_name")

mean_icc_by_method_simulation <- mean_icc_by_method_filter_simulation %>% 
  group_by(approach, component, weight, penalty) %>% 
  summarize(missing = mean(missing), 
            cor = mean(cor),
            icc = mean(icc))

plot_icc_overview_simulation <- mean_icc_by_method_filter_simulation %>%
  filter(weight == "get_normalized_weights" | !approach %in% c("minsq", "maxcor")) %>% 
  arrange(approach, icc) %>%
  group_by(approach) %>%
  mutate(
    rel_order = (row_number() - 1) / (n() - 1)  # from 0 to 1
  ) %>%
  ggplot(aes(x = rel_order, y = icc, color = approach)) +
  geom_line(alpha = 0.9, linewidth = 1.5) +
  labs(
    x = "Relative Position in Approach (0 = lowest ICC, 1 = highest)",
    y = "ICC"
  ) +
  ylim(0, 1)+
  theme_classic()+
  theme(text=element_text(size=30),
        axis.text.x = element_text(size=20),
  )+
  theme(
    legend.title = element_text(size = 35, face = "bold"),  # size and style of title
    legend.key.size = unit(2, "cm"),              # size of color boxes
    legend.spacing.y = unit(0.5, "cm")            # vertical spacing
  )

mean_icc_hammingtukey_simulation <- mean_icc_by_method_simulation %>% 
  filter(weight %in% c("get_hamming_weights", "get_tukey_weights")) %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_normalized_simulation <- mean_icc_by_method_simulation %>% 
  filter(weight %in% c("get_normalized_weights")) %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_minsq_hamming_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "minsq", weight == "get_hamming_weights") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_minsq_normalized_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "minsq", weight == "get_normalized_weights") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_maxcor_hamming_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "maxcor", weight == "get_hamming_weights") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_maxcor_normalized_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "maxcor", weight == "get_normalized_weights") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_peak_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "peak", component == "p3_250_900") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_area_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "area", component == "p3_250_700") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_liesefeld_simulation <- mean_icc_by_method_simulation %>% 
  filter(approach == "liesefeld_area", component == "p3_250_700") %>% pull(icc) %>%
  mean() %>% print_icc()

mean_icc_by_method_filter_simulation <- average_data %>%
  filter(n_na < 50) %>%
  group_by(filter, approach, window_name, weight, penalty) %>% 
  mutate(
    is_outlier = is_outlier(mean_emp_shift)
  ) %>%
  filter(is_outlier == 0) %>%
  group_by(filter, approach, window_name, weight, penalty) %>% 
  summarize(
    measurements = n(),
    missing = 1 - n() / (142*4),
    cor = cor(mean_true_shift, mean_emp_shift, use = "pairwise.complete.obs"),
    icc = custom_icc(mean_true_shift, mean_emp_shift)
  ) %>% 
  rename("component" = "window_name")

icc_note <- "Intra-class correlations focusing on absolute agreement. The rows indicate combinations of similarity measure and weighting function. The columns denote the measurement window and indicate if a penalty was used."
overview_table_icc_simulation_linear <- mean_icc_by_method_simulation %>% 
  prepare_data_kathrin("icc", c("approach", "weight"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", icc_note, 2, c(4, 8))

overview_table_icc_by_filter_simulation_linear <- mean_icc_by_method_filter_simulation %>%
  prepare_data_kathrin("icc", c("approach", "weight", "filter"), c("window", "penalty")) %>%
  make_flextable_kathrin(., 0.8, "greater", icc_note, 2, seq(4, 44, 4))



# Average icc
# icc_across_simulations <- full_data %>%
#   mutate(
#     latency = ifelse(approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency)
#   ) %>%
#   pivot_wider(
#     id_cols = c(task_id, method_id, simulation_id, filter, task_description, component, window_name, approach, weight, normalize, penalty, subject),
#     names_from = is_simulation,
#     values_from = c(simulation_shift, latency, fit_cor, fit_distance, b_param)
#   ) %>%
#   mutate(true_shift = simulation_shift_1, empirical_shift = latency_1 - latency_0) %>%
#   group_by(task_id, task_description, method_id, simulation_id, filter, component, window_name, approach, weight, normalize, penalty) %>%
#   mutate(
#     is_outlier_true = is_outlier(true_shift),
#     is_outlier_emp = is_outlier(empirical_shift)
#   ) %>%
#   filter(is_outlier_emp == 0 & is_outlier_true == 0) %>%
#   summarize(
#     measurements = sum(!is.na(true_shift) & !is.na(empirical_shift)),
#     missing = 1 - n() / (142),
#     cor = cor(true_shift, empirical_shift, use = "pairwise.complete.obs"),
#     icc = custom_icc(true_shift, empirical_shift)
#   )
# 
# icc_across_simulations %>%
#   group_by(window_name, approach, weight, normalize, penalty) %>%
#   filter(measurements > 100) %>%
#   summarize(
#     mean_icc = mean(icc, na.rm = TRUE)
#   ) %>% arrange(mean_icc) %>% View()
