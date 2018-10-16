SSD-based upper-body and head detectors
=======================================
Pablo Medina-Suarez and Manuel J. Marin-Jimenez

Quick start
-----------

Start Matlab and setup Matconvnet with contrib modules:  

```matlab
vl_contrib('setup', 'mcnSSD')  
vl_contrib('setup', 'mcnExtraLayers')  
vl_contrib('setup', 'mcnDatasets')  

cd <root_ava_ssd_detector>  
addpath(genpath(pwd))   % Just in case  
  
ssd_people_demo;  
```
