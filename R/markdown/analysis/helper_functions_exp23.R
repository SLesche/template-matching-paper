spearman_brown_double <- function(rel){
  corrected_rel = c()
  
  for (i in seq_along(rel)){
    if (is.na(rel[i])){
      corrected_rel[i] = NA
    } else if (rel[i] > 0){
      corrected_rel[i] = (2*rel[i]) / (1 + rel[i])
    } else {
      corrected_rel[i] = -1*(2*abs(rel[i])) / (1 + abs(rel[i]))
    }
  }
  
  
  return(corrected_rel)
}

is_outlier <- function(vector){
  mean = mean(vector, na.rm = TRUE)
  sd = sd(vector, na.rm = TRUE)
  
  is_outlier = (vector < mean - 3*sd) | (vector > mean + 3*sd)
  return(is_outlier)
}



FisherZ <- function(rho)  {0.5*log((1+rho)/(1-rho)) }   #converts r to z

FisherZInv <- function(z) {(exp(2*z)-1)/(1+exp(2*z)) }   #converts back again

fisher_cor_mean <- function(corr_values){
  corr_values[corr_values == 1] = 0.99
  corr_values[corr_values == -1] = -0.99
  corr_values[corr_values > 1 | corr_values < -1] = NA
  z_values = FisherZ(corr_values)
  mean_value = mean(z_values, na.rm = TRUE)
  mean_corr = FisherZInv(mean_value)
  return(mean_corr)
}

get_homogeneity <- function(corr_matrix){
  n_entries = nrow(corr_matrix)
  homogeneity = data.frame(
    name = vector(mode = "character", length = n_entries),
    value = vector(mode = "numeric", length = n_entries)
  )
  for (i in 1:nrow(corr_matrix)){
    homogeneity$name[i] = rownames(corr_matrix)[i]
    homogeneity$value[i] = fisher_cor_mean(corr_matrix[, i][-i])
  }
  
  return(homogeneity)
}


turn_cormatrix_into_vector <- function(cormat){
  colnames = colnames(cormat)
  rownames = rownames(cormat)
  
  cormat[!upper.tri(cormat)] = NA
  size = length(colnames)
  
  vector = vector(mode = "numeric", length = size*size)
  vector_names = vector(mode = "character", length = size*size)
  
  for (col in seq_along(colnames)){
    for (row in seq_along(rownames)){
      vector[(col-1)*size + row] = cormat[row, col]
      vector_names[(col-1)*size + row] = paste0(colnames[col], "___", rownames[row])
    }
  }
  
  data = t(data.frame(vector))
  colnames(data) = vector_names
  data = t(as.data.frame(data[, colSums(is.na(data)) == 0]))
  rownames(data) = c()
  data = data.table::transpose(as.data.frame(data), keep.names = "vars")
  return(data)
}

custom_icc <- function(vec_1, vec_2){
  icc = irr::icc(data.frame(vec_1, vec_2), model = "twoway", type = "agreement")$value
  return(icc)
}

compute_icc_mat <- function(dataframe){
  colnames = colnames(dataframe)
  n_vecs = ncol(dataframe)
  icc_mat = matrix(0, n_vecs, n_vecs)
  
  for (icol in seq_along(colnames)){
    vec_1 = dataframe[, colnames[icol]]
    for (jcol in seq_along(colnames)){
      vec_2 = dataframe[, colnames[jcol]]
      icc = custom_icc(vec_1, vec_2)
      icc_mat[icol, jcol] = icc
    }
  }
  
  rownames(icc_mat) = colnames
  colnames(icc_mat) = colnames
  
  return(icc_mat)
}

two_coeff_alpha <- function(vec_1, vec_2){
  alpha = ((4 * cov(vec_1, vec_2, use = "pairwise.complete.obs")) / (var(vec_1, na.rm = TRUE) + var(vec_2, na.rm = TRUE) + 2 * cov(vec_1, vec_2, use = "pairwise.complete.obs")))
  
  return(alpha)
}
