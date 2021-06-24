suppressPackageStartupMessages({
  library(googlesheets4)
  library(reticulate)
  library(dplyr)
  library(readr)
  library(janitor)
})

# read config
source(config.R)

# hide warning
oldw <- getOption("warn")
options(warn = -1) # options(warn = oldw)
options(gargle_oauth_email = config$your_email_address) # for googlesheet

# TODO: add testing for input, now assume config is fine
# clean up config info
url <- toString(config$google_sheet_url)
questions <- lapply(config[2:4], function(x) toString(x) %>% janitor::make_clean_names())
teamIDs <- lapply(config[5:6], function(x) toString(x))
token <- toString(config$synapse_api_key)

# load py modules
use_condaenv("brats-tool", required = TRUE)
cu <- reticulate::import("challengeutils")
pd <- reticulate::import("pandas")
synapseclient <- reticulate::import("synapseclient")

# log in to synapse
syn <- synapseclient$Synapse()
invisible(reticulate::py_capture_output(syn$login(apiKey = token), type = "stdout"))

# Reading google sheet from response of form
suppressMessages(response <- remove_empty(read_sheet(url), which = "rows"))