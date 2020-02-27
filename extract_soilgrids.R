rm(list=ls())

library(raster)
library(rgeos)
library(maps)
library(rgdal)
library(sf)
library(doParallel)
library(dplyr)
library(data.table)
library(ggplot2)

# set dirs
dir_caravan<-'~/Google Drive/caravan/'

# load SoilGrids grid as raster
soil_tif<-paste0(dir_caravan,'raw_data/SNDPPT_M_sl1_250m_ll.tif')
GDALinfo(soil_tif) # show basic infos
soil_dat<-raster(soil_tif) # load data
extent_conus<-extent(-130,-60,22,53) # set lon/lat range covered by CONUS 
soil_dat_us<-crop(soil_dat,extent_conus) # only keep data over CONUS
epsg_soil<-st_crs(soil_dat_us)$epsg # retrieve coordinate reference system / EPSG Geodetic Parameter Dataset
plot(soil_dat_us) # plot soil data for CONUS
map('usa',add=TRUE) # add boundaries

# load catchments boundaries
dir_shapefiles_us<-paste0(dir_caravan,'caravan_data/camels_us/shapefiles/')
shape_us<-read_sf(dsn =dir_shapefiles_us, layer = "HCDN_nhru_final_671")

if(st_crs(shape_us)$epsg!=epsg_soil){ # convert to soil CRS if necessary
  shape_us<-st_transform(shape_us, epsg_soil, check = FALSE)
}
  
shape_us[ , "ID"] <- 1:nrow(shape_us) # create an ID field
plot(shape_us$geometry,add=TRUE)

# select subsample of catchments
which(shape_us$hru_id==12043000)
sub_us<-shape_us[500:600,]
plot(sub_us$geometry) 
plot(soil_dat_us,add=TRUE) # plot soil data for CONUS
map('usa',add=TRUE) # add boundaries
plot(sub_us$geometry,add=TRUE) # plot all catchments, colouring based on mean elevation

# is extraction quicker with clipped grid? 
system.time(avrgs <- extract(soil_dat,sub_us,fun = mean,na.rm = T,df = T))    # 12 sec
system.time(avrgs <- extract(soil_dat_us,sub_us,fun = mean,na.rm = T,df = T)) # 6 sec

# extract cell weights
cell_weights <- extract(soil_dat_us,sub_us,cellnumbers=TRUE,weights=TRUE,normalizeWeights=FALSE)
earth_radius<-6371
cell_res<-0.0020833 
cell_area_48N<-(2*3.1416*earth_radius*cell_res/360)^2*cos(48/360*2*3.14)
area_soil<-rapply(cell_weights,function(x){sum(x[,3])})*cell_area_48N
area_catch<-sub_us$AREA/1E6
(area_soil-area_catch)/area_catch

# compute averages from weights
compute_catch_avg<-function(dat){
  dat<-dat[!is.na(dat[,'value']),] # remove grid cells with NA (they still get assigned a weight)
  sum(dat[,'value']*dat[,'weight'])/sum(dat[,'weight'])
}

compute_catch_avg_grid<-function(dat,grid){
  dat<-dat[!is.na(dat[,'value']),] # remove grid cells with NA (they still get assigned a weight)
  sum(grid[dat[,'cell']]*dat[,'weight'])/sum(dat[,'weight'])
}

# test parrallel computing
library(doParallel)  
no_cores <- detectCores() - 1  
registerDoParallel(cores=no_cores)  
cl <- makeCluster(no_cores, type="FORK")  
system.time(ext_seq<-extract(soil_dat,sub_us,fun = mean,na.rm = T,df=T)[,2]) # seq using global map
system.time(ext_seq_us<-extract(soil_dat_us,sub_us,fun = mean,na.rm = T,df=T)[,2]) # seq using CONUS map
system.time(ext_foreach<-foreach(i=1:length(sub_us)) %dopar% extract(soil_dat_us,sub_us[i,],fun=mean,na.rm = T)) # parLapply

system.time(res_parLapply<-parLapply(cl,cell_weights,compute_catch_avg_grid,grid=soil_dat_us)) # parLapply
system.time(res_foreach<-foreach(i=1:length(cell_weights)) %dopar% compute_catch_avg_grid(dat=cell_weights[[i]],grid=soil_dat_us)) # parLapply
stopCluster(cl)

# compare consistency 
data.frame(ext_seq,ext_seq_us,unlist(ext_foreach),unlist(res_parLapply), unlist(res_foreach))

## merge averages to shapes
sub_us <- merge(sub_us, avrgs, by = "ID")
