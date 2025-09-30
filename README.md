# caravan

[![Binder](https://binder.pangeo.io/badge_logo.svg)](https://binder.pangeo.io/v2/gh/naddor/caravan/master)

CARAVAN is a project whose aim is to move the creation of large-sample hydrological (LSH) datasets to the cloud. LSH datasets include data from large samples (tens to thousands) of catchments and enable researchers to go beyond individual case studies and derive robust conclusions on hydrological processes and models. 

CARAVAN should enable users to create LSH datasets similar to the [CAMELS](https://ncar.github.io/hydrology/datasets/CAMELS_timeseries) (Catchment Attributes and MEteorology for Large-sample Studies) dataset on the cloud, eventually leading to a suite of CAMELS, aka a [CARAVAN](https://en.wikipedia.org/wiki/Camel_train).

# Motivation

Currently, LSH creators download different versions of various data products and process them using different scripts. As an alternative, the relevant global datasets should be available in a single place in the cloud, together with scripts necessary to process them. Users would upload shapefiles of their catchments and the extraction of hydrometeorological time series and catchment attributes would happen online. This would i) improve inter-dataset comparability as both data products and scripts would be the same, ii) facilitate the production of time series and attributes for new catchments, iii) enable the simultaneous update of LSH datasets, for instance when a new data product becomes available or covers a longer period. Such a system, accessible and maintained by the community instead of a few individuals, would increase the perennity of LSH datasets, i.e., make them easier to produce and maintain in the mid- to long-term.
