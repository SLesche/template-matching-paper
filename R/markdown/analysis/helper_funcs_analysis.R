prepare_data_kathrin <- function(data, row_of_interest, id_cols, name_cols){
  prep = data %>%
    filter(!grepl("manual", approach)) %>%
    mutate(
      approach = factor(ifelse(approach == "liesefeld_area", "liesefeld", approach)),
      weight = factor(str_remove_all(weight, "^get_|_weights$")),
      penalty = factor(ifelse(str_detect(penalty, "none"), "none", "penalized")),
      window = paste0("[", str_replace(str_remove(component, "^p3_"), "_", " "), "]")
    ) %>% 
    mutate(
      approach = fct_relevel(approach, "maxcor", "minsq", "peak", "area", "liesefeld"),
      weight = fct_relevel(weight, "none", "hamming", "tukey", "normalized"),
      penalty = fct_relevel(penalty, "none", "exponential")
    ) %>% 
    ungroup() %>%
    arrange(across(all_of(id_cols))) %>% 
    pivot_wider(
      id_cols = all_of(id_cols),
      names_from = all_of(name_cols),
      values_from = all_of(row_of_interest)
    )
  return(prep)
}

make_flextable_kathrin <- function(data, cutoff, comparison, note, nstart = 2, hlines = c()){
  ncol = ncol(data)
  if (comparison == "greater"){
    color_mat = ifelse(data[, (nstart+1):ncol] > cutoff, "forestgreen", "darkorange")
  } else {
    color_mat = ifelse(data[, (nstart+1):ncol] < cutoff, "forestgreen", "darkorange")
  }
  
  flextable = data %>%
    flextable() %>%
    colformat_double(j = -c(1:(nstart)), digits = 2) %>%
    separate_header() %>%
    align(align = "center", part = "all", j = -c(1:(nstart))) %>%
    merge_v(j = 1) %>%
    # valign(j = 1, valign = "top") %>%
    hline(i = hlines) %>%
    # color(
    #   j = 3:ncol,
    #   color = color_mat
    # ) %>%
    apa_footer(note) %>%
    line_spacing(space = 0.5, part = "all") %>%
    # set_caption("Reliability - Nback Task") %>%
    set_table_properties(layout = "autofit", width = 0.75)
  return(flextable)
}
