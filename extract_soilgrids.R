library(raster)
library(rgeos)
library(maps)
library(rgdal)
library(sf)
library(dplyr)
library(data.table)
library(ggplot2)

# set lon/lat range covered by CONUS 
extent_conus<-extent(-130,-60,22,53)

# load catchments boundaries
dir_caravan<-'~/Google Drive/caravan/'
dir_shapefiles_us<-paste0(dir_caravan,'caravan_data/camels_us/shapefiles/')
shape_us<-read_sf(dsn =dir_shapefiles_us, layer = "HCDN_nhru_final_671")
plot(shape_us["elev_mean"]) # plot all catchments, colouring based on mean elevation
shape_us[ , "ID"] <- 1:nrow(shape_us) # create an ID field

# select subsample of catchments
plot(shape_us[shape_us$elev_mean<400,"elev_mean"])
sub_us<-shape_us[1:4,]
plot(sub_us["elev_mean"]) # plot all catchments, colouring based on mean elevation

# load SoilGrids grid as raster
soil_tif<-paste0(dir_caravan,'raw_data/SNDPPT_M_sl1_250m_ll.tif')
GDALinfo(soil_tif) # show basic infos
soil_dat<-raster(soil_tif) # load data
soil_dat_us<-crop(soil_dat,extent_conus) # only keep data over CONUS
plot(soil_dat_us,add=TRUE)

### TODO: transform SpatialPolygons to the CRS of the Raster

# is extraction quicker with clipped grid? 
system.time(avrgs <- extract(soil_dat,sub_us,fun = mean,na.rm = T,df = T))    # 29 sec
system.time(avrgs <- extract(soil_dat_us,sub_us,fun = mean,na.rm = T,df = T)) # 25 sec - marginally quicker

# compute averages on the fly
extract(soil_dat,sub_us,fun = mean,na.rm = T,df=T)

# weighted mean
# v <- extract(r, polys, weights=TRUE, fun=mean)
# equivalent to:
v <- extract(soil_dat, sub_us, weights=TRUE)
sapply(v, function(x) if (!is.null(x)) {sum(apply(x, 1, prod)) / sum(x[,2])} else NA)

# compute averages from weights
compute_catch_avg<-function(dat){
  sum(dat[,'value']*dat[,'weight'],na.rm=TRUE)/sum(dat[,'weight'])
}

compute_catch_avg_grid<-function(dat,grid){
  sum(grid[dat[,'cell']]*dat[,'weight'],na.rm=TRUE)/sum(dat[,'weight'])
}

cell_weights <- extract(soil_dat,sub_us,cellnumbers=TRUE,weights=TRUE,normalizeWeights=FALSE)
sapply(cell_weights,compute_catch_avg) # use values in cell_weights
sapply(cell_weights,compute_catch_avg_grid,soil_dat) # extract from grid

## merge averages to shapes
sub_us <- merge(sub_us, avrgs, by = "ID")

