# Load libraries
library(tidyverse)
library(rvest)

# Load the rundata
rundata <- readRDS("~/runedata/data-raw/data/rundata.RDS")

geo <- rundata %>%
  select(signum, coordinates) %>%
  filter(str_detect(coordinates, "^\\d+\\.\\d+$")) %>%
  extract(coordinates, c("x", "y"), "(\\d+).(\\d+)", remove = FALSE)

geo %>%
  select(x, y) %>%
  write_csv("data-raw/coordinates_to_convert.csv")

# Then convert coordinates here:
# https://pap.as/sweref/

# Read in the converted coordinates
converted_coordinates <- read_delim("data-raw/converted_coordinates.csv",
                                    ";", escape_double = FALSE,
                                    locale = locale(encoding = "WINDOWS-1252"),
                                    trim_ws = TRUE) %>%
  mutate(x = as.character(x),
         y = as.character(y))


rt90 <- geo %>%
  left_join(converted_coordinates) %>%
  distinct() %>%
  select(signum, lat, lng)

####

wgs84 <- rundata %>%
  select(signum, coordinates) %>%
  filter(!str_detect(coordinates, "^\\d+\\.\\d+$"))

wgs84$coordinates  <- map_chr(wgs84$coordinates, function(x){
  x <- str_extract_all(x, "\\d+\\.\\d+\\s*;\\s*-*\\d+\\.\\d+") %>%
    unlist() %>%
    str_replace_all("\\s*", "")

  if(length(x) == 0) x <- NA_character_

  return(x)
})

wgs84 <- wgs84 %>%
  extract(coordinates, c("lat", "lng"), "(.+);(.+)") %>%
  mutate(lat = as.numeric(lat), lng = as.numeric(lng))

###

with_coodinates <- bind_rows(rt90, wgs84)

rundata <- rundata %>%
  left_join(with_coodinates)

# Save the data
write_rds(rundata, "data-raw/data/rundata.RDS")
