# load variable
source("setup.R")

# prepare detecting new submissions
dir.create("tmp", showWarnings = FALSE)
dir.create("log", showWarnings = FALSE)
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
      setNames(c("timestamp", "firstName", "lastName", "userName"))

    new_usernames <- unique(new_response$userName)

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

    footer <- "Thank you!<br><br>Challenge Administrator"
    # find user who is in the diff, aka users in the pre-registrant team, but not in the validate team
    waitList_users <- lapply(intersect(new_usernames, diff$userName), function(id) {
      user <- syn$getUserProfile(id)
      list(userName = user["userName"], userId = user["ownerId"])
    })

    if (length(waitList_users) != 0) {
      invisible(
        lapply(seq_along(waitList_users), function(i) {
          usr <- waitList_users[[i]]["userName"]
          id <- not_waitList_users[[i]]["userId"]

          # compare first name, last name and user name
          a <- new_response %>%
            filter(userName == usr & timestamp == max(timestamp)) %>%
            # only take the latest submission
            select(-timestamp) %>%
            as.character()
          b <- diff %>%
            filter(userName == usr) %>%
            select(firstName, lastName, userName) %>%
            as.character()

          if (identical(a, b)) { # if validate
            # invite to the team
            # syn$invite_to_team(config$validated_teamID, id)

            msg <- paste0(
              "Hello ", usr, ",<br><br>",
              "The invitation has been sent, please accept and join the validated Team.<br><br>",
              footer
            )
            # log
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "validate\n"), collapse = ","),
              file = "log/out.log", append = TRUE
            )
          } else { # if not validate
            inx <- which(a != b)
            errorMsg <- sapply(inx, function(i) {
              paste0(
                colnames(new_response)[-1][i], ": '",
                a[i], "' does not match the '",
                b[i], "' in your synapse profile<br>"
              )
            }) %>% paste0(collapse = "")
            msg <- paste0(
              "Hello ", usr, ",<br><br>",
              errorMsg, "<br>",
              "Please double check your filled information that matches your synapse profile ",
              "and submit the <a href='", config$google_form_url, "' target='_blank'>google form</a>", " again.<br><br>",
              footer
            )
            # log
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "mismatched names\n"), collapse = ","),
              file = "log/out.log", append = TRUE
            )
          }
          invisible(
            syn$sendMessage(
              userIds = list(""), messageSubject = "Form Response Validation Results",
              messageBody = msg, contentType = "text/html"
            )
          )
        })
      )
    }

    # find who is not in the diff:
    # they could not in the preregistrant team yet or
    # already in the validated team
    not_waitList_users <- lapply(setdiff(new_usernames, diff$userName), function(id) {
      user <- syn$getUserProfile(id)
      list(userName = user["userName"], userId = user["ownerId"])
    })

    if (length(not_waitList_users) != 0) {
      invisible(
        lapply(seq_along(not_waitList_users), function(i) {
          usr <- not_waitList_users[[i]]["userName"]
          id <- not_waitList_users[[i]]["userId"]
          # if users not in the pre-registrant team, but already in the validate team, like admin
          if (usr %in% team2_memberIds) {
            msg <- paste0(
              "Hello ", usr, ",<br><br>",
              "You are already in the validated team.<br><br>",
              footer
            )
            # log
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "already in the validated team\n"), collapse = ","),
              file = "log/out.log", append = TRUE
            )
          } else { # if user not in either of team
            msg <- paste0(
              "Hello ", usr, ",<br><br>",
              "You are not in the preregistrant team<br><br>",
              "Please register the challenge first and ",
              "and submit the <a href='", config$google_form_url, "' target='_blank'>google form</a>", " again.<br><br>",
              footer
            )
            # log
            cat(paste0(c(format(Sys.time(), " %Y-%m-%dT%H-%M-%S"), usr, "not in the preregistrant team\n"), collapse = ","),
              file = "log/out.log", append = TRUE
            )
          }
          # if username is incorrect, then you wont' get an email, since we cant get their userId
          try(invisible(
            syn$sendMessage(
              userIds = list(""), messageSubject = "Form Response Validation Results",
              messageBody = msg, contentType = "text/html"
            )
          ),
          silent = TRUE
          )
        })
      )
    }
  }

  # remove cronR log and replace old
  unlink(c("validateResponse.log", "tmp/after"))
  write_csv(response, "tmp/before.csv")
}
