library(tidyverse)
library(R.matlab)

raw_data <- readMat("../scripts/results/results_kathrinexp23_revision.mat")
comb <- read.csv("../scripts/results/method_combinations_revision.csv")

# Full files
tasks <- c("flanker", "nback", "switching")
groups <- c("young", "old")
filters <- c(0, 4, 8, 16, 32)


component_names <- c("p3_250_700", "p3_250_900", "p3_200_700", "p3_300_600")
n_components <- length(component_names)
component_windows <- list(c(250, 700), c(250, 900), c(200, 700), c(300, 600))
n_bins <- 6
data_tib <- data.frame()

for (itask in seq_along(tasks)){
  for (igroup in seq_along(groups)){
    for (ifilter in seq_along(filters)){
      for (icomponent in seq_along(component_names)){
        for (imethod in 1:nrow(comb)){
          for (ibin in 1:n_bins){
            data = data.frame(
              task = tasks[itask],
              group = groups[igroup],
              filter = filters[ifilter],
              component = component_names[icomponent],
              approach = comb[imethod, "possible_approaches"],
              weight = comb[imethod, "possible_weights"],
              penalty = comb[imethod, "possible_penalty"],
              normalization = comb[imethod, "possible_normalization"],
              bin = ibin
            )
            results = as.data.frame(raw_data$full.results[itask, igroup, ifilter][[1]][[1]][icomponent, imethod, ,ibin ,])
            subject = 1:nrow(results)
            
            data = cbind(data, results)
            data$subject = subject
            data_tib = rbind(data_tib, data)
          }
        }
      }
    }
  }
}

# Save data
data <- data_tib %>% 
  rename(
    "a_param" = "V1",
    "b_param" = "V2",
    "latency" = "V3",
    "fit_cor" = "V4",
    "fit_dist" = "V5"
  )

load("./markdown/analysis/raw_data/rater_data_long.rdata")

subject_young <- list.files("./markdown/analysis/raw_data/erp_young_list", pattern = "*.erp")
subject_old <- list.files("./markdown/analysis/raw_data/erp_old_list", pattern = "*.erp")

subject_data <- data.frame(
  subject_nr = parse_number(c(subject_young, subject_old)),
  group = factor(rep(c("young", "old"), each = 30), levels = c("young", "old"))
)

subject_data$algo_position <- 1:nrow(subject_data)

subject_data_order <- subject_data %>% 
  arrange(group, subject_nr) %>% 
  mutate(
    rater_position = row_number()
  ) %>% 
  mutate(
    algo_position = ifelse(group == "old", algo_position - 30, algo_position)
  ) %>% 
  select(algo_position, position = rater_position)

rater_data <- rater_data_long %>% 
  mutate(
    weight = "none",
    penalty = "none",
    normalization = "none",
    component = paste0("p3_", type),
    a_param = NA,
    b_param = NA,
    fit_dist = NA,
    fit_cor = NA
  ) %>% 
  left_join(., subject_data_order) %>% 
  select(
    subject = algo_position, task, group, filter, component,
    approach, weight, penalty, normalization,
    bin, latency, a_param, b_param, fit_cor, fit_dist
  ) 

full_data <- rbind(data, rater_data)

save(full_data, file ="./markdown/analysis/processed_data/long_data_exp23_revision.Rdata")
