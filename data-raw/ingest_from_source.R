library(tidyverse)

# Download the data from the website
url <- "http://www.runforum.nordiska.uu.se/filer/srd2014.zip"
my_dir <- tempdir()
filename <- str_c(my_dir, "/srd2014.zip")
download.file(url = url, destfile = filename)
unzip(filename, exdir = my_dir)

# Move the description pdf to inst/extdata
from_filename <- str_c(my_dir, "/bskr_rdm.pdf")
to_filename <- str_c(getwd(), "/inst/extdata/bskr_rdm.pdf")
file.copy(from_filename, to_filename)

# Read in the rundata excel file
filename <- str_c(my_dir, "/RUNDATA.xls")
rundata <- readxl::read_excel(filename)
names(rundata) <- names(rundata) %>% tolower()

# Extract the rune texts
filenames <- str_c(my_dir, c("/RUNTEXTX", "/FORNSPRX", "/FVNX", "/ENGLISH"))
txts <- map(filenames, function(filename){
  txt <- read_lines(filename)
  lang <- txt[1] %>% str_remove("!/R ") %>%
    str_to_lower() %>% str_replace_all(" ", "_")
  txt <- tail(txt, nrow(rundata))

  clean_txt <- map2_chr(rundata$signum, txt, function(signum, txt){
    signum <- signum %>%
      str_replace_all("\\$", "\\\\$") %>%
      str_replace_all("\\?", ".")
    str_remove(txt, signum) %>% str_squish()
  })

  df <- tibble(signum = rundata$signum, txt = clean_txt) %>%
    set_names(c("signum", lang))
})
df <- txts %>% reduce(inner_join, by = "signum")

# Join them to the data base
rundata <- rundata %>% inner_join(df, by = "signum")

# translate the column names to english
replacements <- c("signum" = "signum", "plats" = "place", "socken" = "parish",
                  "härad" = "district", "kommun" = "municipality", "placering" = "location",
                  "koordinater" = "coordinates", "urspr. plats?" = "original_place",
                  "nuv. koord." = "present_coordinates", "sockenkod/fornlämningsnr." = "parish_id_monument_no",
                  "runtyper" = "rune_type", "korsform" = "cruciform",
                  "period/datering" = "period_dating", "stilgruppering" = "style_group",
                  "ristare" = "maker", "materialtyp" = "material_type", "material" = "material",
                  "föremål" = "subject", "övrigt" = "other", "alternativt signum" = "alternative_signum",
                  "referens" = "reference", "bildlänk" = "picture_link", "runtext" = "runic_text",
                  "nationellt_fornspråk" = "old_norse", "fornvästnordisk_text" = "old_west_norse",
                  "engelsk_översättning" = "english_translation")

names(rundata) <- recode(names(rundata), !!!replacements)

# Save the data
write_rds(rundata, "data-raw/data/rundata.RDS")
