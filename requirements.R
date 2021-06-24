if(!require("pacman", character.only = TRUE)) install.packages("pacman")

pkg_list <- c("googlesheets4", "reticulate", "dplyr", "readr", "janitor", "cronR")

pacman::p_load(pkg_list, character.only = TRUE)
 
