library(raster)
library(sf)
library(dplyr)
library(ggplot2)
library(rgeos)
library(maps)
library(rgdal)

# load catchments boundaries
dir_caravan<-'~/Google Drive/caravan/'
dir_shapefiles_us<-paste0(dir_caravan,'caravan_data/camels_us/shapefiles/')
shape_us<-read_sf(dsn =dir_shapefiles_us, layer = "HCDN_nhru_final_671")
plot(shape_us["elev_mean"])

# load grid as raster
soil_tif<-paste0(dir_caravan,'raw_data/SNDPPT_M_sl1_250m_ll.tif')
GDALinfo(soil_tif)
soil_dat<-raster(soil_tif)
names(soil_dat)

# simple extraction of averages
avrgs <- extract(soil_dat,
                 shape_us,
                 fun = mean,
                 na.rm = T,
                 df = T)

save.image(paste0(dir_caravan,'image.rdata'))
