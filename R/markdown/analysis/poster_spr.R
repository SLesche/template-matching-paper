library(tidyverse)
source("./markdown/analysis/helper_functions_simulation.R")

load(file = "./markdown/analysis/processed_data/mean_missing_by_method_simulation.Rdata")
load(file = "./markdown/analysis/processed_data/average_data_simulation.Rdata")

average_data %>% 
  filter(n_na < 125) %>%
  filter(window_name == "p3_250_700" | approach == "peak") %>% 
  filter((window_name == "p3_250_900" & approach %in% c("peak")) | !approach %in% c("peak")) %>% 
  filter(penalty == "none") %>%
  filter(weight == "get_normalized_weights" | approach %in% c("peak", "area", "liesefeld_area")) %>% 
  mutate(approach = fct_relevel(factor(approach), "peak", "area", "liesefeld_area", "minsq", "maxcor")) %>% 
  filter(approach %in% c("peak", "liesefeld_area", "minsq")) %>% 
  group_by(approach, weight, window_name) %>% 
  mutate(
    is_outlier = is_outlier(mean_emp_shift)
  ) %>% 
  filter(is_outlier == 0) %>% 
  ggplot(
    aes(
      x = mean_true_shift,
      y = mean_emp_shift,
      color = interaction(approach)
    )
  ) +
  # Adding a geom_rect to manually fill the background of each facet
  geom_rect(
    aes(xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = Inf, fill = interaction(approach)),
    alpha = 0.05
  ) +
  facet_wrap(~interaction(approach)) +
  geom_point(alpha = 1, size = 3) +
  xlim(0.7, 1.1) +
  ylim(0.5, 1.3) +
  geom_smooth(method = "lm", linewidth = 2) +
  labs(
    x = "True shift",
    y = "Mean estimated shift",
    color = "Approach"
  ) +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed", linewidth = 2) +
  theme_classic() +
  theme(
    text = element_text(size = 30),
    axis.text = element_text(size = 20),
    legend.position = "none",  # Disable the legend
    strip.background = element_blank(),  # Removing the default background of the facet grid labels
    strip.text = element_text(size = 45)
  ) +
  scale_fill_manual(values = c("peak" = "lightpink", "liesefeld_area" = "lightgreen", "minsq" = "lightblue"))


average_data %>%
  # filter(penalty == "exponential_penalty" | !approach %in% c("maxcor", "minsq")) %>% 
  # filter(window_name == "p3_normal") %>%
  # filter(weight %in% c("none", "get_normalized_weights")) %>%
  filter(window_name == "p3_250_700" | approach == "peak") %>% 
  # filter((window_name == "p3_250_700" & approach %in% c("area", "liesefeld_area")) |!approach %in% c("area", "liesefeld_area")) %>% 
  filter((window_name == "p3_250_900" & approach %in% c("peak")) |!approach %in% c("peak")) %>% 
  filter(penalty == "none") %>%
  filter(weight == "get_normalized_weights" | approach %in% c("peak", "area", "liesefeld_area")) %>% 
  mutate(approach = fct_relevel(factor(approach), "peak", "area", "liesefeld_area", "minsq", "maxcor")) %>% 
  filter(approach %in% c("peak", "liesefeld_area", "minsq")) %>% 
  group_by(filter, approach, window_name, weight, penalty) %>% 
  filter(n_na < 125) %>%
  mutate(
    is_outlier = is_outlier(mean_emp_shift)
  ) %>% 
  filter(is_outlier == 0) %>% 
  summarize(
    measurements = n(),
    missing = 1 - n() / (142),
    cor = cor(mean_true_shift, mean_emp_shift, use = "pairwise.complete.obs"),
    icc = custom_icc(mean_true_shift, mean_emp_shift)
  ) %>% 
  # filter(!(window_name != "oldmethods" & approach %in% c("peak", "area", "liesefeld_area"))) %>%
  # filter(window_name %in% c("oldmethods", "p3_wide")) %>% 
  # filter(penalty == "exponential_penalty" | approach %in% c("peak", "area", "liesefeld_area")) %>%
  filter(penalty == "none") %>%
  filter(weight == "get_normalized_weights" | approach %in% c("peak", "area", "liesefeld_area")) %>%
  mutate(combination = interaction(approach, weight, penalty)) %>% 
  ggplot(
    aes(x = forcats::fct_reorder(combination, icc, .desc = TRUE), y = icc, fill = approach)
  )+
  geom_bar(stat = "identity")+
  facet_wrap(~filter)+
  geom_hline(yintercept = 0.8, color = "red", linetype = "dashed", linewidth = 1)+
  geom_hline(yintercept = 0.9, color = "darkgreen", linetype = "dashed", linewidth = 1)+
  labs(
    x = "method",
    y = "ICC",
    fill = "Approach"
  )+ 
  ylim(0, 1)+
  scale_x_discrete(guide = guide_axis(n.dodge=2), labels = function(x) gsub("(.+)(\\..+)(\\..*$)", "\\1", x))+
  theme_classic()+
  theme(text=element_text(size=30),
        axis.text = element_text(size=20),
        legend.position = "none",  # Disable the legend
  )

load("./markdown/analysis/processed_data/long_data_exp23.Rdata")
source("./markdown/analysis/helper_functions_exp23.R")
source("./markdown/analysis/helper_funcs_analysis.R")

rel_overview <- full_data %>% 
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
    rel_1 = spearman_brown_double(cor(as.numeric(bin_1), as.numeric(bin_2), use = "pairwise.complete.obs")),
    rel_2 = spearman_brown_double(cor(as.numeric(bin_3), as.numeric(bin_4), use = "pairwise.complete.obs")),
    n = n()
  ) %>%
  pivot_longer(
    cols = c("rel_1", "rel_2"),
    names_to = "condition",
    values_to = "reliability"
  ) %>%
  ungroup() 

# Plot for PSQ
rel_overview %>%
  filter(component == "p3_250_700" | approach == "peak") %>% 
  # filter((window_name == "p3_250_700" & approach %in% c("area", "liesefeld_area")) |!approach %in% c("area", "liesefeld_area")) %>% 
  filter((component == "p3_250_900" & approach %in% c("peak")) |!approach %in% c("peak")) %>% 
  filter(penalty == "none") %>%
  filter(weight == "get_normalized_weights" | approach %in% c("peak", "area", "liesefeld_area")) %>% 
  mutate(approach = fct_relevel(factor(approach), "peak", "area", "liesefeld_area", "minsq", "maxcor")) %>% 
  filter(approach %in% c("peak", "liesefeld_area", "minsq")) %>% 
  mutate(combination = factor(interaction(approach, weight, penalty))) %>% 
  ggplot(
    aes(x = forcats::fct_reorder(combination, reliability, .desc = TRUE), y = reliability, fill = approach)
  )+
  geom_violin()+
  # facet_wrap(~component)+
  geom_jitter(width = 0.1, alpha = 0.2)+
  geom_hline(yintercept = 0.8, color = "red", linetype = "dashed", linewidth = 1)+
  geom_hline(yintercept = 0.9, color = "darkgreen", linetype = "dashed", linewidth = 1)+
  labs(
    x = "method"
  )+ 
  ylim(0, 1)+
  scale_x_discrete(labels = c("liesefeld_area", "peak", "minsq"))+
  theme_classic()+
  theme(text=element_text(size=30),
        axis.text.x = element_text(size=45),
        legend.position = "none",  # Disable the legend
  )

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


# Plot for PSQ
icc_data %>% 
  ungroup() %>% 
  filter(component == "p3_250_700" | approach == "peak") %>% 
  # filter((window_name == "p3_250_700" & approach %in% c("area", "liesefeld_area")) |!approach %in% c("area", "liesefeld_area")) %>% 
  filter((component == "p3_250_900" & approach %in% c("peak")) |!approach %in% c("peak")) %>% 
  filter(penalty == "none") %>%
  filter(weight == "get_normalized_weights" | approach %in% c("peak", "area", "liesefeld_area")) %>% 
  mutate(approach = fct_relevel(factor(approach), "peak", "liesefeld_area", "minsq")) %>%
  filter(approach %in% c("peak", "liesefeld_area", "minsq")) %>% 
  mutate(combination = interaction(approach),
         correlation = icc) %>%
  ggplot(
    aes(
      x = forcats::fct_reorder(combination, correlation, .desc = TRUE),
      y = correlation,
      fill = approach
    )
  )+
  geom_violin()+
  geom_jitter(width = 0.1, alpha = 0.2)+
  geom_hline(yintercept = 0.8, color = "red", linetype = "dashed", linewidth = 2)+
  geom_hline(yintercept = 0.9, color = "darkgreen", linetype = "dashed", linewidth = 2)+
  labs(
    x = "method"
  )+ 
  ylim(0, 1)+
  scale_x_discrete(labels = c("minsq", "liesefeld_area", "peak"))+
  theme_classic()+
  theme(text=element_text(size=30),
        axis.text.x = element_text(size=45),
        legend.position = "none",  # Disable the legend
  )
