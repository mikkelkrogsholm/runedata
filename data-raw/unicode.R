library(tidyverse)
library(rvest)

url <- "https://en.wikipedia.org/wiki/Runic_(Unicode_block)"

html_data <- read_html(url)

tables <- html_data %>%
  html_nodes("table")

out <- tables[[2]] %>%
  html_table(header = T)

out$Rune <- out$Rune %>% str_sub(-1,-1)

# font-family:"BabelStone Runic Beagnoth","BabelStone Runic Beorhtnoth","BabelStone Runic Beorhtric","BabelStone Runic Beowulf","BabelStone Runic Berhtwald","BabelStone Runic Byrhtferth",Junicode,Kelvinch,"Free Monospaced",Code2000,Hnias,"Noto Sans Runic","Segoe UI Historic","Segoe UI Symbol"


names(out) <- names(out) %>%
  str_to_lower() %>%
  str_replace_all("[[:punct:]]", "_") %>%
  str_replace_all(" ", "_") %>%
  str_remove_all("_$")

