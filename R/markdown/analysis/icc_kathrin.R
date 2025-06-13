library(tidyverse)

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


icc_data <- cor_data %>%
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
  )

plot_icc_overview <- icc_data %>%
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
  )+
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

mean_icc_by_method_kathrin <- icc_data %>% 
  group_by(component, approach, weight, penalty) %>% 
  summarize(
    mean_icc = mean(icc, na.rm = TRUE),
    median_icc = median(icc, na.rm = TRUE),
    min_icc = min(icc, na.rm = TRUE),
    max_icc = max(icc, na.rm = TRUE),
    n = n()
  )

mean_icc_by_method_task_kathrin <- icc_data %>% 
  group_by(task, component, approach, weight, penalty) %>% 
  summarize(
    mean_icc = mean(icc, na.rm = TRUE),
    median_icc = median(icc, na.rm = TRUE),
    min_icc = min(icc, na.rm = TRUE),
    max_icc = max(icc, na.rm = TRUE),
    n = n()
  )

mean_icc_by_method_filter_kathrin <- icc_data %>% 
  group_by(filter, component, approach, weight, penalty) %>% 
  summarize(
    mean_icc = mean(icc, na.rm = TRUE),
    median_icc = median(icc, na.rm = TRUE),
    min_icc = min(icc, na.rm = TRUE),
    max_icc = max(icc, na.rm = TRUE),
    n = n()
  )

mean_icc_hammingtukey_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(weight %in% c("get_hamming_weights", "get_tukey_weights")) %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_normalized_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(weight %in% c("get_normalized_weights")) %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_minsq_hamming_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "minsq", weight == "get_hamming_weights") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_minsq_normalized_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "minsq", weight == "get_normalized_weights") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_maxcor_hamming_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "maxcor", weight == "get_hamming_weights") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_maxcor_normalized_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "maxcor", weight == "get_normalized_weights") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_peak_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "peak", component == "p3_250_900") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_area_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "area", component == "p3_250_700") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_liesefeld_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "liesefeld_area", component == "p3_250_700") %>% pull(mean_icc) %>%
  mean() %>% print_icc()

mean_icc_liesefeldp2p_kathrin <- mean_icc_by_method_kathrin %>% 
  filter(approach == "liesefeld_p2p_area", component == "p3_250_700") %>% pull(mean_icc) %>%
  mean() %>% print_icc()


# Overview table
icc_note <- "Intra-class correlations focusing on absolute agreement. The rows indicate combinations of similarity measure and weighting function. The columns denote the measurement window and indicate if a penalty was used."
overview_table_icc_kathrin <- mean_icc_by_method_kathrin %>% 
  prepare_data_kathrin("mean_icc", c("approach", "weight"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", icc_note, 2, c(4, 8))

overview_table_icc_by_task_kathrin <- mean_icc_by_method_task_kathrin %>% 
  prepare_data_kathrin("mean_icc", c("approach", "weight", "task"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", icc_note, 3, seq(3, 33, 3))

overview_table_icc_by_filter_kathrin <- mean_icc_by_method_filter_kathrin %>% 
  prepare_data_kathrin("mean_icc", c("approach", "weight", "filter"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", icc_note, 3, seq(5, 55, 5))

