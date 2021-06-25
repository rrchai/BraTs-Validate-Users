# load variable
source("setup.R")

# prepare detecting new submissions
dir.create("tmp", showWarnings = FALSE)
# tools::md5sum("tmp_old.csv") != tools::md5sum("tmp_new.csv")
if (!file.exists("tmp/before.csv")) {
  readr::write_csv(response, "tmp/before.csv")
} else {
  readr::write_csv(response, "tmp/after.csv")
}

# validation ----------------------------------------------------------
if (file.exists("tmp/after.csv")) {
  # read all characters to avoid errors for empty sheet
  old_data <- readr::read_csv("tmp/before.csv", col_types = cols(.default = "c"))
  new_data <- readr::read_csv("tmp/after.csv", col_types = cols(.default = "c"))

  if (!identical(old_data, new_data, ignore.environment = TRUE)) {

    # identify new submissions
    new_response <- anti_join(new_data, old_data, by = colnames(new_data)) %>%
      setNames(janitor::make_clean_names(colnames(.))) %>%
      select(timestamp, questions[[1]], questions[[2]], questions[[3]]) %>%
      setNames(c("timestamp", "firstName", "lastName", "userId")) %>%
      mutate(timestamp = as.Date(timestamp))

    new_userIds <- unique(new_response$userId)

    # find difference of users between two teams
    diff <- pd$DataFrame(
      cu$teams$team_members_diff(
        syn,
        config$preregistrant_teamID,
        config$validated_teamID
      )
    )

    un <- pd$DataFrame(
      cu$teams$team_members_union(
        syn,
        config$preregistrant_teamID,
        config$validated_teamID
      )
    )

    team2_memberIds <- setdiff(un$userName, diff$userName)

    footer <- "Thank you!\n\nChallenge Administrator\n"
    # find user who is in the diff, aka users in the pre-registrant team, but not in the validate team
    waitList_users <- lapply(intersect(new_userIds, diff$userName), function(id) {
      user <- syn$getUserProfile(id)
      list(username = user["userName"], userId = user["ownerId"])
    })

    if (length(waitList_users) != 0) {
      invisible(
        lapply(seq_along(waitList_users), function(i) {
          usr <- waitList_users[[i]]["username"]
          # compare first name, last name and user name
          a <- new_response %>%
            filter(userId == usr & timestamp == max(timestamp)) %>%
            # only take the latest submission
            select(-timestamp) %>%
            as.character()
          b <- diff %>%
            filter(userName == usr) %>%
            select(firstName, lastName, userName) %>%
            as.character()

          if (identical(a, b)) { # if validate
            # invite to the team
            # syn$invite_to_team(teamIDs$validate_teamID, id)

            msg <- paste0(
              "Hello ", usr, ",\n\n",
              "The invitation has been sent, please accept and join the validated Team.\n\n",
              footer
            )
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "validate"), sep = ",")) # log
          } else { # if not validate
            inx <- which(a != b)
            errorMsg <- sapply(inx, function(i) {
              paste0(
                colnames(new_response)[-1][i], ": '",
                a[i], "' does not match the '",
                b[i], "' in your synapse profile\n"
              )
            }) %>% paste0(collapse = "")
            msg <- paste0(
              "Hello ", usr, ",\n\n",
              errorMsg, "\n",
              "Please double check your filled information that matches your synapse profile",
              " and submit the google form again.\n\n",
              footer
            )
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "mismatched names"), sep = ",")) # log
          }
          cat(msg) # log
          invisible(syn$sendMessage(userIds = list(""), messageSubject = "Form Response Validation Results", messageBody = msg))
        })
      )
    }

    # find who is not in the diff:
    # they could not in the preregistrant team yet or
    # already in the validated team
    not_waitList_users <- lapply(setdiff(new_userIds, diff$userName), function(id) {
      user <- syn$getUserProfile(id)
      list(username = user["userName"], userId = user["ownerId"])
    })

    if (length(not_waitList_users) != 0) {
      invisible(
        lapply(seq_along(not_waitList_users), function(i) {
          usr <- not_waitList_users[[i]]["username"]
          # if users not in the pre-registrant team, but already in the validate team, like admin
          if (usr %in% team2_memberIds) {
            msg <- paste0(
              "Hello ", usr, ",\n\n",
              "You are already in the validated team.\n\n",
              footer
            )
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "already in the validated team"), sep = ",")) # log
          } else { # if user not in either of team
            msg <- paste0(
              "Hello ", usr, ",\n\n",
              "You are not in the preregistrant team\n\n",
              "Please register the challenge first and submit the google form again.\n\n",
              footer
            )
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "not in the preregistrant team"), sep = ",")) # log
          }
          # if username is incorrect, then you wont' get an email, since we cant get their userId
          try(invisible(syn$sendMessage(userIds = list(""), messageSubject = "Form Response Validation Results", messageBody = msg)),
            slient = TRUE
          )
        })
      )
    }
  }

  # replace old
  unlink("tmp/after")
  write_csv(response, "tmp/before.csv")
}
