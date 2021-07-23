#contains:
#get_and_read_fn
#clean_fn
#zip_and_publish_fn

get_and_read_fn <- function(url_tar) {
  #get data from url
  files_list <- c(
    "BILL_VERSION_AUTHORS_TBL.dat",
    "BILL_VERSION_TBL.dat",
    "COMMITTEE_AGENDA_TBL.dat",
    "BILL_MOTION_TBL.dat",
    "BILL_SUMMARY_VOTE_TBL.dat",
    "BILL_DETAIL_VOTE_TBL.dat"
  )
  options(timeout=300) # Avoid timeout when large files is downloading.
  temp_zip <- tempfile(fileext = ".zip")
  download.file(url_tar, temp_zip, mode="wget", cacheOK=FALSE)
  options(timeout=60)
  
  #read into r objects
  bill_version_authors <-
    read_tsv(unz(temp_zip, "BILL_VERSION_AUTHORS_TBL.dat"),
      col_names = c(
        "bill_version_id",
        "type",
        "house",
        "name",
        "contribution",
        "committee_members",
        "active_flag",
        "trans_uid",
        "trans_update",
        "primary_author_flag"
      ),
      quote = "`"
    ) %>% filter(primary_author_flag == "Y")
  
  
  
  bill_version_summary <- read_tsv(
    unz(temp_zip, "BILL_VERSION_TBL.dat"),
    col_names = c(
      "bill_version_id",
      "bill_id",
      "version_num",
      "bill_version_action_date",
      "bill_version_action",
      "request_num",
      "subject",
      "vote_required",
      "appropriation",
      "fiscal_committee",
      "local_program",
      "substantive_changes",
      "urgency",
      "taxlevy",
      "var1",
      "active_flg",
      "trans_uid",
      "trans_update"
    ),
    quote = "`"
  ) %>%
    left_join(bill_version_authors, by = "bill_version_id") %>%
    select(bill_version_id,
           bill_id,
           bill_version_action_date,
           name,
           subject,
           version_num) %>%
    rename(author = name) %>%
    arrange(bill_version_id)
  
  committee_dat <- read_tsv(
    unz(temp_zip, "COMMITTEE_AGENDA_TBL.dat"),
    col_names = c(
      "committee_code",
      "COMMITTEE_DESC",
      "AGENDA_DATE",
      "AGENDA_TIME",
      "LINE1",
      "LINE2",
      "LINE3",
      "BUILDING_TYPE",
      "ROOM_NUM"
    ),
    quote = "`"
  ) %>%
    group_by(committee_code) %>%
    summarize(COMMITTEE_DESC = COMMITTEE_DESC[1])
  
  motion_dat <- read_tsv(
    unz(temp_zip, "BILL_MOTION_TBL.dat"),
    col_names = c("motion_id", "motion_text", "trans_uid",
                  "trans_update"),
    quote = "`"
  )
  
  vote_summary <- read_tsv(
    unz(temp_zip, "BILL_SUMMARY_VOTE_TBL.dat"),
    col_names = c(
      "bill_id",
      "committee_code",
      "vote_date_time",
      "vote_date_seq",
      "motion_id",
      "ayes",
      "noes",
      "abstain",
      "result",
      "trans_uid",
      "trans_update",
      "file_item_num",
      "file_location",
      "display_lines",
      "session_date"
    ),
    quote = "`"
  ) %>%
    left_join(committee_dat, by = "committee_code") %>%
    left_join(motion_dat, by = "motion_id") %>%
    left_join(bill_version_summary, by = "bill_id") %>%
    select(
      bill_id,
      author,
      subject,
      vote_date_time,
      vote_date_seq,
      COMMITTEE_DESC,
      committee_code,
      motion_text,
      bill_version_action_date,
      version_num,
      motion_id,
      ayes,
      noes,
      result
    ) %>%
    filter(bill_version_action_date < vote_date_time) %>%
    group_by(bill_id, COMMITTEE_DESC, vote_date_time, motion_id) %>%
    filter(version_num == max(version_num))
  
  
  vote_dat <- read_tsv(
    unz(temp_zip, "BILL_DETAIL_VOTE_TBL.dat"),
    col_names = c(
      "bill_id",
      "location",
      "member",
      "datetime",
      "date_seq",
      "vote",
      "motion_id",
      "trans_uid",
      "committee_code",
      "session_date",
      "member_order",
      "speaker",
      "junk"
    ),
    quote = "`"
  ) %>%
    group_by(datetime, date_seq, bill_id, location, motion_id) %>%
    mutate(rcnum = group_indices()) %>%
    ungroup()
  
  unlink(temp_zip) # rm the zip file
   
  #return list of r objects
  list(
    bill_version_authors = bill_version_authors,
    bill_version_summary = bill_version_summary,
    committee_dat = committee_dat,
    motion_dat = motion_dat,
    vote_summary = vote_summary,
    vote_dat = vote_dat
  )
}


clean_fn <- function(dat) {
  vote_dat_all <- dat$vote_dat %>%
    left_join(
      dat$vote_summary,
      by = c(
        "bill_id",
        "location" = "committee_code",
        "motion_id",
        "datetime" = "vote_date_time",
        "date_seq" = "vote_date_seq"
      )
    )
  
  
  vote_dat_all %>%
    group_by(rcnum) %>%
    summarize(
      yy = sum(vote == "AYE"),
      nn = sum(vote == "NOE"),
      y = max(ayes),
      n = max(noes)
    ) %>%
    filter(y != yy | n != nn | is.na(n) | is.na(y))
  
  desc <- vote_dat_all %>%
    mutate(
      bill = str_extract(bill_id, "(?<=\\d{9}).+"),
      datetime = as.Date(datetime, format = "%Y-%m-%d")
    ) %>%
    distinct(
      rcnum,
      bill,
      author,
      subject,
      datetime,
      COMMITTEE_DESC,
      motion_text,
      ayes,
      noes,
      result
    ) %>%
    arrange(rcnum)
  
  votes <- vote_dat_all %>%
    select(member, rcnum, vote) %>%
    mutate(vote = recode(
      vote,
      AYE = 1,
      NOE = 6,
      ABS = 9
    )) %>%
    spread(rcnum, vote, fill = 0)  %>%
    apply(1, function(x)
      sprintf("%-20s%s", x[1],
              paste0(as.character(x[-1]),
                     collapse = "")))
  
  list(desc = desc, votes = votes)
}


zip_fn <- function(clean, year) {
  short_year <- year - ifelse(year > 1999, 2000, 1900)
  yr <- sprintf("%i-%i",  short_year, short_year + 1)
  temp_dir <- tempdir()
  
  #write files
  write_tsv(clean$desc,
            file = file.path(temp_dir, sprintf("ca%sdesc.dat", yr)),
            col_names = FALSE)
  write(clean$votes,
        file = file.path(temp_dir, sprintf("ca%svotes.dat", yr)))
  
  #zip into one folder
  zip_file_name <- sprintf("../Data/caleg%s.zip", yr)
  utils::zip(zipfile = zip_file_name,
             files = c(sprintf("ca%sdesc.dat", yr),
                       sprintf("ca%svotes.dat", yr)))

  unlink(file.path(temp_dir, sprintf("ca%sdesc.dat", yr)))
  unlink(file.path(temp_dir, sprintf("ca%svotes.dat", yr)))
  return(zip_file_name)
}

push_to_github <- function(zip_file_name) {
  git2r::pull()
  git2r::add(path = zip_file_name)
  git2r::commit(message = "Data update...")
  #git2r::push() # Not authenticating correctly
  system("git push") # Hacky way to get git login to work easily 
}
