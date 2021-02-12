#####################################################################################
##
##    File Name:        map.R
##    Date:             2021-02-11
##    Author:           Daniel Weitzel
##    Email:            daniel.weitzel@univie.ac.at
##    Webpage:          www.danweitzel.net
##    Purpose:          Generating map of Europe
##    Date Used:        2021-02-11
##    Data Used:        (none)
##    Output File:      (none)
##    Data Output:      (none)
##    Data Webpage:     (none)
##    Log File:         (none)
##    Notes:            (none)
##
#####################################################################################

## Setting the working directory
setwd(githubdir)
setwd("autnes_visualizations")

## Loading the libraries
## This loads the required packages, if they are not installed it also installs them
if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, grid, rworldmap, mapproj)


# Get the world map
worldMap <- getMap()
temp_map = getMap(resolution='coarse')
temp_map@data


# Member States of the European Union
europeanUnion <- c("Austria","Belgium","Bulgaria","Croatia","Cyprus",
                   "Czech Rep.","Denmark","Estonia","Finland","France",
                   "Germany","Greece","Hungary","Ireland","Italy","Latvia",
                   "Lithuania","Luxembourg","Malta","Netherlands","Poland",
                   "Portugal","Romania","Slovakia","Slovenia","Spain",
                   "Sweden","United Kingdom", "Norway", "Switzerland")

# Countries in the CCDP data set
ccdp <- c("Czech Rep.","Denmark", "Germany","Hungary", "Netherlands",
          "Poland", "Portugal", "Spain", "Sweden","United Kingdom")


# Select only the index of states member of the E.U.
indEU <- which(worldMap$NAME%in%europeanUnion)

# Extract longitude and latitude border's coordinates of members states of E.U. 
europeCoords <- lapply(indEU, function(i){
  df <- data.frame(worldMap@polygons[[i]]@Polygons[[1]]@coords)
  df$region =as.character(worldMap$NAME[i])
  colnames(df) <- list("long", "lat", "region")
  return(df)
})

europeCoords <- do.call("rbind", europeCoords)


# Add some data for each member
europeanUnionTable <- 
  as.data.frame(europeanUnion) %>% 
  rename(region = europeanUnion) %>% 
  mutate(value = if_else(region %in% ccdp, "CCDP", NA_character_))

# Join the data with with coordinates   
europeCoords <-
  europeCoords %>% 
  left_join(europeanUnionTable)


# Plot the map
ggplot() + geom_polygon(data = europeCoords, aes(x = long, y = lat, group = region, fill = value),
                        colour = "white", size = 0.3) +
  coord_map(xlim = c(-13, 35),  ylim = c(32, 71)) + theme_void()   + theme(legend.position = "none") +
  scale_fill_manual(values = "#005692", na.value = "grey80")
