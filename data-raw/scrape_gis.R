
# Can we scrape this

"RuntextdatabasenGIS_v2_9195"

url <- "https://www.arcgis.com/apps/webappviewer/index.html?id=33398b84bf8f44f99faee2f0366ad878&extent=-1874522.6465%2C7044751.3049%2C5639542.9821%2C10581645.4777%2C102100"

url <- "https://www.arcgis.com/sharing/rest/content/items/33398b84bf8f44f99faee2f0366ad878/data"

out <- jsonlite::fromJSON(url)

out[["map"]][["itemId"]]

url <- "https://www.arcgis.com/sharing/rest/content/items/4427acf931524b4589fb4fa09b4c0c36/data"
out <- jsonlite::fromJSON(url)

out$operationalLayers$url



https://services2.arcgis.com/gWRYLIS16mKUskSO/arcgis/rest/services/VHR_Areas/FeatureServer/0/query?where=0%3D0&outFields=%2A&f=json


url <- "https://services3.arcgis.com/NOhNis5i9PGy01Lu/arcgis/rest/services/RuntextdatabasenGIS_v2/FeatureServer/0/query?where=0%3D0&outFields=%2A&f=json"
out2 <- jsonlite::fromJSON(url)

attributes <- out2$features$attributes %>% as_tibble()
geometry <- out2$features$geometry %>% as_tibble()
