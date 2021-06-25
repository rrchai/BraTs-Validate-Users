suppressPackageStartupMessages({
  library(googlesheets4)
  library(reticulate)
  library(dplyr)
  library(readr)
  library(janitor)
})

# read config
source("config.R")

# hide warning
oldw <- getOption("warn")
options(warn = -1) # options(warn = oldw)
options(gargle_oauth_email = config$your_email_address) # for googlesheet

# TODO: add testing for input, now assume config is fine
# clean up config info
config <- lapply(config, function(x) toString(x) %>% trimws("both"))
questions <- lapply(
  config[c(
    "first_name_question",
    "last_name_question",
    "username_question"
  )],
  janitor::make_clean_names
)

# load py modules
use_condaenv("brats-tool", required = TRUE)
cu <- reticulate::import("challengeutils")
pd <- reticulate::import("pandas")
synapseclient <- reticulate::import("synapseclient")

# log in to synapse
syn <- synapseclient$Synapse()
syn$login(config$username, config$password, silent = TRUE)

# Reading google sheet from response of form
suppressMessages(response <- remove_empty(read_sheet(config$google_sheet_url), which = "rows"))
