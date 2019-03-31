library(tidyverse)
library(rvest)

rundata <- read_rds("data-raw/rundata.RDS")

# Get links to Digitala Sveriges runinskrifter – publicerade volymer
url<- "https://www.raa.se/kulturarv/runor-och-runstenar/digitala-sveriges-runinskrifter/digitala-sveriges-runinskrifter-publicerade-volymer/"

html_data <- read_html(url)

runinskrifter_links <- html_data %>%
  html_nodes("a") %>%
  html_attr("href") %>%
  str_subset("runinskrifter") %>%
  str_subset("pdf")

link_text <- html_data %>%
  html_nodes("a") %>%
  html_text()

link_url <- html_data %>%
  html_nodes("a") %>%
  html_attr("href")

df <- tibble(
  text = link_text[link_url %in% runinskrifter_links],
  urls = link_url[link_url %in% runinskrifter_links]
) %>%
  filter(str_detect(text, "\\d"))

df <- df %>%
  mutate(signum_refs = map(text, function(x){
    my_eval <- x %>%
      str_remove_all("[[:alpha:]]") %>%
      str_replace_all("-", ":") %>%
      str_replace_all("/", ",") %>%
      str_replace_all("[.+]", "") %>%
      str_squish() %>%
      str_c("c(", . , ")")

    digits <- eval(parse(text = my_eval))

    signums <- x %>%
      str_remove_all("[^[:alpha:]]") %>%
      str_c(., " ", digits)

    signums
  }))

df <- df %>%
  unnest(signum_refs) %>%
  select(-text) %>%
  distinct(signum_refs, .keep_all = T)

###

xx <- rundata %>% select(signum)

zero_to_na <- function(mylist){
  lapply(mylist, function(x){
    if(is.list(x)){
      zero_to_na(x)
    } else {
      if(length(x) == 0) NA else x
    }
  })
}

xx$signum_refs <- xx$signum %>%
  str_extract_all("[[:alpha:]]+ \\d+") %>%
  zero_to_na() %>%
  unlist()

xx_df <- left_join(xx, df) %>%
  select(signum, sri = urls) %>%
  drop_na()





