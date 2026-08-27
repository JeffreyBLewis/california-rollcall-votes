library(targets)
source("functions.R")
options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("tidyverse"))
list(
  tar_target(name = year,
             command = current_session_year_fn()),
  tar_target(
    name = url_tar,
    command = paste(
      "https://downloads.leginfo.legislature.ca.gov/pubinfo_",
      year,
      ".zip",
      sep = ""
    ),
    format = "url",
    resources = list(handle = curl::new_handle(nobody = TRUE))
  ),
  tar_target(name = get_and_read,
             command = get_and_read_fn(url_tar)),
  tar_target(name = clean,
             command = clean_fn(get_and_read)),
  tar_target(name = zip_file_name,
             command = zip_fn(clean, year),
	     format = "file")
)
