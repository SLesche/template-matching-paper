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

cor_data %>% 
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


