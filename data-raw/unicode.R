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
  snakecase::to_snake_case()

out <- as_tibble(out)

out[,4:8] <- map(out[,4:8], function(x){
  ifelse(x == "", FALSE, TRUE)
})

out %>%
  filter(younger_futhark_long_branch) %>%
  select(code_point, rune, name)


write_rds(out, "data-raw/data/runes_unicode.RDS")
