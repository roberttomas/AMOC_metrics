;-------------------------------------------------------------------------------------------
; 8 February 2019
;
; Script to modify pop monthly single variable time series files so that they are better 
; compatible with the rapidmoc software.  
;-----------
; 1) If z_t exist, replace with variable named z_t_m for z_t with units of meters and replace coordinate variable in data variable 
; 2) convert units from cgs to mks
;    A) TAUX: 1 dyne/cm2 = 0.1  N/m2 - should do a vector remapping
;    B) VVEL: 1 cm/s     = 0.001 m/s - should do a vector remapping
;    C) SALT: (not done: apply scale factor and delete attribute)
;    D) TEMP: no changes
; 3)
; 
;-----------
; Need to set an environmental variable to let the ncl remapping function know where the remapping file resides.  
; setenv NCL_POP_REMAP "."
;-------------------------------------------------------------------------------------------
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl" 
   load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/popRemap.ncl" 
;-------------------------------------------------------------------------------------------
begin
   cvar = "SALT"
;----------
   case = "b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001"
   cyear = "200001-200912"
;-------------------------------------------------------------------------------------------
; specify some parameters defining the remapping file.  These are part of the file name, by convention.
;
   cgrid_in    = "gx1v7"
   cgrid_out   = "fv1.9x2.5"
   cmap_date   = "181205"
   cmap_type   = "bilin"
   carea_type  = "da"
;
; Need to change the name of the remapping file that is in the cseg inputdata to conform to what is expected by the ncl
; regridding functions
; create link to rename remapping file using the convention that the ncl routine expects
   system("rm map_" + cgrid_in + "_to_" + cgrid_out +"_" + cmap_type + "_" + carea_type + "_" + cmap_date + ".nc")
   system("ln -s /glade/p/cesm/cseg/inputdata/cpl/gridmaps/" + cgrid_in + "/map_" + cgrid_in +"_TO_" + cgrid_out + "_blin." + cmap_date + ".nc map_" + cgrid_in + "_to_" + cgrid_out +"_" + cmap_type  + "_" + carea_type + "_" + cmap_date + ".nc")
;-------------------------------------------------------------------------------------------
   if ( (cvar .ne. "TAUX")  .and.  (cvar .ne. "SALT")  .and.  (cvar .ne. "TEMP")   .and.  (cvar .ne. "VVEL") ) then 
      print("Variable not currently supported in this script.")
      exit
   end if
;-------------------------------------------------------------------------------------------
   if( cvar .eq. "VVEL") then
      print("Not using vector remapping for a velocity")
      print("Change at your earliest convenience")
   end if
;-------------------------------------------------------------------------------------------
;
   file_in = case + ".pop.h." + cvar + "." + cyear + ".nc"
   f_in = addfile(file_in,"r")
   file_out = case + ".pop.h." + cvar + "." + cyear + "_" + cgrid_out+ ".nc"
   if( (cvar .eq. "VVEL") .or. (cvar .eq. "TAUX") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,ULAT,ULONG b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001.pop.h." + cvar + ".200001-200912.nc -o temp_" + cvar + ".nc")
   end if
;
   if( (cvar .eq. "TEMP") .or. (cvar .eq. "SALT") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,TLAT,TLONG b.e21.BWHIST.f09_g17.CMIP6-historical-WACCM.001.pop.h." + cvar + ".200001-200912.nc -o temp_" + cvar + ".nc")
   end if
   f_out = addfile("temp_" + cvar + ".nc", "w")
;
   var_in = f_in->$cvar$
;
; For TAUX, convert dyne/centimeter^2 to Newtons/meter^2
   if(cvar .eq. "TAUX")
      var_in = (/ 0.1 * var_in /)
      var_in@units = "Newton/meter^2"
   end if
; For VVEL convert centimeters/second to meters/second
   if(cvar .eq. "VVEL")
      var_in = (/ 0.01 * var_in /)
      var_in@units = "meter/s"
   end if
; For SALT apply scale factor and delete scale factor attribure
; 20 Feb 19 didn't remove "S" shape from AMOC profile curve
;   if(cvar .eq. "SALT")
;      var_in = (/ var_in@scale_factor * var_in /)
;      delete(var_in@scale_factor)
;   end if
;
; if coordinate variable z_t exists, then replace it with z_t_m 
   if(var_in!1 .eq. "z_t") then

; create and add coordinte variable z_t_m for z_t in units of meters
      z_t = f_in->z_t
      z_t_m = z_t
      z_t_m = (/ z_t_m/100. /)
      z_t_m!0 = "z_t_m"
      z_t_m@units = "m"
      z_t_m@valid_min = 5.
      z_t_m@valid_max = 5375.
      f_out->z_t_m = z_t_m
;
      var_in!1 = "z_t_m"
      var_in&z_t_m = z_t_m
   end if
;
   var_in_regrid = PopLatLon (var_in, "gx1v7", cgrid_out, cmap_type, carea_type, "181205")
;
; "normalized regridding" to remove bad data sometimes produced along the coastlines by regridding 
; see example 4: https://www.ncl.ucar.edu/Applications/pop2lat.shtml 
   notmissing  = where(.not.ismissing(var_in),1.,0.)   
   notmissing_regrid = PopLatLon (notmissing, "gx1v7", "fv1.9x2.5", cmap_type, carea_type, "181205")
   delete(notmissing)
;
   notmissing_regrid = where(notmissing_regrid.eq.0,notmissing_regrid@_FillValue,notmissing_regrid) ; set points = 0 to @_FillValue
;
   var_in_regrid = (/ var_in_regrid/notmissing_regrid /)     ; normalize the original regridded field by using notmissing_regrid
   delete(notmissing_regrid)            
   dummy = var_in_regrid
   delete(var_in_regrid)
   var_in_regrid = lonFlip(dummy)
   delete(dummy)

;
; get lat and lon coordinate variables
   lat = var_in_regrid&lat
   lat!0 = "lat"
   lat&lat = lat
   lon = var_in_regrid&lon
   lon!0 = "lon"
   lon&lon = lon
;
   f_out->lat = lat
   f_out->lon = lon
   f_out->$cvar$ = var_in_regrid
;
   system("mv temp_" + cvar + ".nc " + file_out)
;
end
