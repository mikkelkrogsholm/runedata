library(tidyverse)
library(rvest)

# Main url
url <- "http://runer.ku.dk/AdvSearch.aspx"

# Create the session
s <- html_session(url)

# Search for all using the form
f <- s %>%
  html_node("form") %>%
  html_form()

f <- f %>%
  set_values("ctl00$MainContentPlaceHolder$drpdnMotiveksistens" = "ja")

# Submit form
s <- submit_form(s, f)

# Get the first table
table_ja <- s %>%
  html_node("#ctl00_MainContentPlaceHolder_pnlResult") %>%
  html_node("table") %>%
  html_table()


# Create the session
s <- html_session(url)

# Search for all using the form
f <- s %>%
  html_node("form") %>%
  html_form()

f <- f %>%
  set_values("ctl00$MainContentPlaceHolder$drpdnMotiveksistens" = "nej")

# Submit form
s <- submit_form(s, f)

# Get the first table
table_nej <- s %>%
  html_node("#ctl00_MainContentPlaceHolder_pnlResult") %>%
  html_node("table") %>%
  html_table()

###
out <- bind_rows(table_ja, table_nej) %>%
  .[,2:3] %>%
  as_tibble()

out <- out %>%
  mutate(links = str_c("http://runer.ku.dk/VisGenstand.aspx?Titel=", Titel %>% str_replace_all(" ", "_")))

################################################################################

library(future)
library(furrr)

plan("multiprocess")

url <- out$links[10]

# create a dir for today
dir_name <- str_c("data-raw/natmus-", Sys.Date(), "/")
dir.create(dir_name)

# Walk through urls and get them all
furrr::future_map(out$links, function(url){

  filename <- str_split(url, "Titel=") %>% unlist()
  filename <- filename[length(filename)]
  filename <- str_c(dir_name,filename, ".html")

  raw_html <- read_file(url)

  write_file(raw_html, path = filename)

  invisible(NULL)
}, .progress = TRUE)


# Get missing
gotten <- list.files(dir_name) %>% str_remove_all(".html")

missing <- out %>%
  filter(!str_replace_all(out$Titel, " ", "_") %in% gotten)

# Walk through urls and get them all
furrr::future_map(missing$links, function(url){

  filename <- str_split(url, "Titel=") %>% unlist()
  filename <- filename[length(filename)]
  filename <- str_c(dir_name,filename, ".html")

  raw_html <- read_file(url)

  write_file(raw_html, path = filename)

  invisible(NULL)
}, .progress = TRUE)

gotten <- list.files(dir_name) %>% str_remove_all(".html")

missing <- out %>%
  filter(!str_replace_all(out$Titel, " ", "_") %in% gotten)

################################################################################
##### PARSE

path <- "data-raw/natmus-2019-03-29/Ådum-sten.html"

parse_natmus <- function(path){
  print(path)
  html_data <- read_html(path, encoding = "utf-8" )

  uuid <- uuid::UUIDgenerate()

  # Stamdata ----
  ps <- html_data %>%
    html_node("#ctl00_MainContentPlaceHolder_Stamdata") %>%
    html_nodes("p")

  header <- ps %>%
    html_nodes("strong") %>%
    html_text() %>%
    str_remove_all("[[:punct:]]") %>%
    str_squish() %>%
    str_to_lower() %>%
    str_replace_all(" ", "_")

  stamdata <- ps %>%
    html_nodes("span") %>%
    html_text() %>%
    str_squish() %>%
    as.list() %>%
    set_names(header) %>%
    as_tibble()

  stamdata$uuid <- uuid

  # Indskrift ----
  ps <- html_data %>%
    html_node("#ctl00_MainContentPlaceHolder_Indskrifter") %>%
    html_nodes("p")

  header <- ps %>%
    html_nodes("strong") %>%
    html_text() %>%
    str_remove_all("[[:punct:]]") %>%
    str_squish() %>%
    str_to_lower() %>%
    str_replace_all(" ", "_")

  indskrift <- ps %>%
    html_nodes("span") %>%
    html_text() %>%
    str_squish() %>%
    as.list() %>%
    set_names(header) %>%
    as_tibble()

  indskrift$uuid <- uuid

  # Litteraturhenvisning ----
  divs <- html_data %>%
    html_node("#ctl00_MainContentPlaceHolder_pnlLitHenv") %>%
    html_nodes("div")

  litt <- map_dfr(divs, function(div){
    spans <- div %>%
      html_nodes("span")

    s <- spans %>%
      html_attr("id") %>%
      str_split("_") %>%
      map_chr(function(x) x[length(x)]) %>%
      snakecase::to_snake_case()

    litt <- spans %>%
      html_text() %>%
      as.list() %>%
      set_names(s) %>%
      as_tibble()

    litt

  })

  if(nrow(litt) > 0){
    litt$uuid <- uuid
  } else {
    litt <- NULL
  }


  # return
  out <- list(stamdata = stamdata,
              indskrift = indskrift,
              litt = litt)

  return(out)
}

dir_name <- "data-raw/natmus-2019-03-29"

paths <- list.files(dir_name, full.names = T) %>% str_replace_all("//", "/")

parsed <- map(paths, parse_natmus)

stamdata <- parsed %>% map_dfr(`[[`, "stamdata")
indskrift <- parsed %>% map_dfr(`[[`, "indskrift")
litt <- parsed %>% map_dfr(`[[`, "litt")

write_rds(stamdata, "data-raw/data/natmus_stamdata.RDS")
write_rds(indskrift, "data-raw/data/natmus_indskrift.RDS")
write_rds(litt, "data-raw/data/natmus_litt.RDS")
