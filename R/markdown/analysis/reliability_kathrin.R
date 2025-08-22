library(tidyverse)

load("./markdown/analysis/processed_data/long_data_exp23_revision.Rdata")
source("./markdown/analysis/helper_functions_exp23.R")
source("./markdown/analysis/helper_funcs_analysis.R")

rel_overview_kathrin <- full_data %>% 
  mutate(
    latency = ifelse(
      approach %in% c("maxcor", "minsq") & (fit_cor < 0.3 | b_param > 1.9 | b_param < 0.5), NA, latency
    )
  ) %>% 
  group_by(task, filter, group, bin, approach, component, weight, penalty, normalization) %>% 
  mutate(
    is_outlier = is_outlier(latency)
  ) %>% 
  ungroup() %>% 
  mutate(lateny = ifelse(is_outlier == 0, latency, NA)) %>% 
  pivot_wider(
    id_cols = c("task", "group", "filter", "component", "approach", "weight", "penalty", "subject"),
    names_from = "bin",
    names_prefix = "bin_",
    values_from = "latency"
  ) %>% 
  group_by(task, filter, group, component, approach, weight, penalty) %>% 
  summarize(
    # rel_1 = spearman_brown_double(cor(as.numeric(bin_1), as.numeric(bin_2), use = "pairwise.complete.obs")),
    # rel_2 = spearman_brown_double(cor(as.numeric(bin_3), as.numeric(bin_4), use = "pairwise.complete.obs")),
    alpha_1 = performance::cronbachs_alpha(data.frame(as.numeric(bin_1), as.numeric(bin_2))),
    alpha_2 = performance::cronbachs_alpha(data.frame(as.numeric(bin_3), as.numeric(bin_4))),
    n = n()
  ) %>%
  # pivot_longer(
  #   cols = c("rel_1", "rel_2"),
  #   names_to = "condition",
  #   values_to = "reliability"
  # ) %>%
  pivot_longer(
    cols = c("alpha_1", "alpha_2"),
    names_to = "condition_alpha",
    values_to = "reliability"
  ) %>%
  ungroup()

plot_rel_overview <- rel_overview_kathrin %>%
  filter(!grepl("manual", approach)) %>%
  filter(weight == "get_normalized_weights" | !approach %in% c("minsq", "maxcor")) %>% 
  arrange(approach, reliability) %>%
  group_by(approach) %>%
  mutate(
    rel_order = (row_number() - 1) / (n() - 1)  # from 0 to 1
  ) %>%
  ggplot(aes(x = rel_order, y = reliability, color = approach)) +
  geom_line(alpha = 0.9, linewidth = 1.5) +
  labs(
    x = "Relative Position in Approach (0 = lowest reliability, 1 = highest)",
    y = "Reliability"
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
  
mean_reliability_by_method_kathrin <- rel_overview_kathrin %>% 
  filter(!grepl("manual", approach)) %>% 
  group_by(component, approach, weight, penalty) %>% 
  summarize(
    mean_rel = mean(reliability, na.rm = TRUE),
    meadian_rel = median(reliability, na.rm = TRUE),
    max_rel = max(reliability, na.rm = TRUE),
    min_rel = min(reliability, na.rm = TRUE),
    five_perc_rel = quantile(reliability, 0.05)[[1]],
    ninetyfive_perc_rel = quantile(reliability, 0.95)[[1]],
    n = n()
  )

mean_reliability_by_method_task_kathrin <- rel_overview_kathrin %>% 
  filter(!grepl("manual", approach)) %>% 
  group_by(task, component, approach, weight, penalty) %>% 
  summarize(
    mean_rel = mean(reliability, na.rm = TRUE),
    meadian_rel = median(reliability, na.rm = TRUE),
    max_rel = max(reliability, na.rm = TRUE),
    min_rel = min(reliability, na.rm = TRUE),
    n = n()
  )

mean_reliability_by_method_filter_kathrin <- rel_overview_kathrin %>% 
  filter(!grepl("manual", approach)) %>% 
  group_by(filter, component, approach, weight, penalty) %>% 
  summarize(
    mean_rel = mean(reliability, na.rm = TRUE),
    meadian_rel = median(reliability, na.rm = TRUE),
    max_rel = max(reliability, na.rm = TRUE),
    min_rel = min(reliability, na.rm = TRUE),
    n = n()
  )

mean_reliability_minsq_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "minsq") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_maxcor_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "maxcor") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_peak_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "peak", component == "p3_250_900") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_area_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "area", component == "p3_250_700") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_liesefeld_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "liesefeld_area", component == "p3_250_700") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_liesefeldp2p_kathrin <- mean_reliability_by_method_kathrin %>% 
  filter(approach == "liesefeld_p2p_area", component == "p3_250_700") %>% pull(mean_rel) %>%
  mean() %>% print_rel()

mean_reliability_manual_kathrin <- 0.89 %>% print_rel()

# Tables
rel_note <- "Reliability has been estimated by Spearman-Brown corrected split-half correlations. The rows indicate combinations of similarity measure and weighting function. The columns denote the measurement window and indicate if a penalty was used."

overview_table_rel_kathrin <- mean_reliability_by_method_kathrin %>% 
  prepare_data_kathrin("mean_rel",  c("approach", "weight"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", rel_note, 2, c(4, 8))

overview_table_rel_by_task_kathrin <- mean_reliability_by_method_task_kathrin %>% 
  prepare_data_kathrin("mean_rel", c("approach", "weight", "task"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", rel_note, 3, seq(3, 33, 3))

overview_table_rel_by_filter_kathrin <- mean_reliability_by_method_filter_kathrin %>% 
  prepare_data_kathrin("mean_rel", c("approach", "weight", "filter"), c("window", "penalty")) %>% 
  make_flextable_kathrin(., 0.8, "greater", rel_note, 3, seq(5, 55, 5))