;-------------------------------------------------------------------------------------------
; 7 March 2019
;
; Script to modify pop monthly single variable time series files so that they are
; compatible with the rapidmoc software.  
;-----------
; 1) If z_t exist, replace with variable named z_t_m for z_t with units of meters and replace z-coordinate variable in data variable 
;
; 2) convert units from cgs to mks
;    A) TAUX: 1 dyne/cm2 = 0.1  N/m2 - should do a vector remapping
;    B) VVEL: 1 cm/s     = 0.001 m/s - should do a vector remapping
;    C) SALT: no changes 
;    D) TEMP: no changes
;
; 3) Change longitude range from 0-360 to -180 to 180 and shift so that the GM is near the middle for most of the grid
; 
;-------------------------------------------------------------------------------------------
begin
   cvar = "TAUX"
;----------
   case = "g20a10.GIAF_JRA.gx1v7.C03"
   cyear = "004301-005212"
;-------------------------------------------------------------------------------------------
   if ( (cvar .ne. "TAUX")  .and.  (cvar .ne. "SALT")  .and.  (cvar .ne. "TEMP")   .and.  (cvar .ne. "VVEL") ) then 
      print("This script does not currently support this variable: " + cvar)
      exit
   end if
;-------------------------------------------------------------------------------------------
; Add file.  Create new file without coordinates that will be changed by this script - need to treat velocity and tracer fields differently.
   file_in = case + ".pop.h." + cvar + "." + cyear + ".nc"
   f_in = addfile(file_in,"r")
   file_out = case + ".pop.h." + cvar + "." + cyear + "_mod.nc"
   if( (cvar .eq. "VVEL") .or. (cvar .eq. "TAUX") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,ULAT,ULONG $case + ".pop.h." + cvar + "." + cyear + ".nc -o temp_" + cvar + ".nc")
      clat = "ULAT"
      clon = "ULONG"
   end if
;
   if( (cvar .eq. "TEMP") .or. (cvar .eq. "SALT") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,TLAT,TLONG $case + ".pop.h." + cvar + "." + cyear + ".nc -o temp_" + cvar + ".nc")
      clat = "TLAT"
      clon = "TLONG"
   end if
   f_out = addfile("temp_" + cvar + ".nc", "w")
;
   var_in = f_in->$cvar$
   lat    = f_in->$clat$
   lon    = f_in->$clon$
;---------------------------------------------------------------------------------------------------------------------------------------
; shift so that 0 degrees longitude is ~in the middle for most of the grid and have longitudes increase monotonically, left to rignt and 
; range between -180 to 180
;
;----------
; initialize some indicies
;----------
   imax = 320
; pivot i-index (~corresponding to the date line) is different for U-grid and T-grid
   if(clon .eq. "ULONG") then
      ipivot = 194
   end if
   if(clon .eq. "TLONG") then
      ipivot = 195
   end if
;----------
; shift longitude array
;----------
;
   lon_shift = lon
   lon_shift(:,imax-ipivot-1:imax-1) = lon(:,0:ipivot)
   lon_shift(:,0:imax-ipivot-2)      = lon(:,ipivot+1:imax-1)
   lon_shift = where(lon_shift .gt. 180.d0, lon_shift - 360.d0, lon_shift)
;----------
; shift latitude array
;----------
;
   lat_shift = lat
   lat_shift(:,imax-ipivot-1:imax-1) = lat(:,0:ipivot)
   lat_shift(:,0:imax-ipivot-2)      = lat(:,ipivot+1:imax-1)
;----------
; shift data array
;----------
;
   rank = dimsizes(dimsizes(var_in))
   if( rank .ne. 3 .and. rank .ne. 4 ) then
      print("var_in must be rank 3 or 4")
      print(dimsizes(dimsizes(var_in)))
      exit
   end if
;
   if( dimsizes(dimsizes(var_in)) .eq. 3 ) then
      var_in_shift = var_in
      var_in_shift(:,:,imax-ipivot-1:imax-1) = var_in(:,:,0:ipivot)
      var_in_shift(:,:,0:imax-ipivot-2)      = var_in(:,:,ipivot+1:imax-1)
   end if
   if( dimsizes(dimsizes(var_in)) .eq. 4 ) then
      var_in_shift = var_in
      var_in_shift(:,:,:,imax-ipivot-1:imax-1) = var_in(:,:,:,0:ipivot)
      var_in_shift(:,:,:,0:imax-ipivot-2)      = var_in(:,:,:,ipivot+1:imax-1)
   end if
;
;   system("rm junk.nc")
;   f_out2 = addfile("junk.nc","c")
;   f_out2->$clon$ = lon_shift
;   f_out2->$clat$ = lat_shift
;   exit
;---------------------------------------------------------------------------------------------------------------------------------------
;
; For TAUX, convert dyne/centimeter^2 to Newtons/meter^2
   if(cvar .eq. "TAUX")
      var_in_shift = (/ 0.1 * var_in_shift /)
      var_in_shift@units = "Newton/meter^2"
   end if

; For VVEL convert centimeters/second to meters/second
   if(cvar .eq. "VVEL")
      var_in_shift = (/ 0.01 * var_in_shift /)
      var_in_shift@units = "meter/s"
   end if

; if coordinate variable z_t exists, then replace it with z_t_m 
   if(var_in_shift!1 .eq. "z_t") then

; create and add coordinte variable z_t_m for z_t in units of meters
      z_t = f_in->z_t
      z_t_m = z_t
      z_t_m = (/ z_t_m/100. /)
      z_t_m!0 = "z_t_m"
      z_t_m@units = "m"
      z_t_m@valid_min = 5.
      z_t_m@valid_max = 5375.
      f_out->z_t_m = z_t_m
;----------
; overwrite existing z_t coordinate variable with z_t_m
;----------
      var_in_shift!1 = "z_t_m"
      var_in_shift&z_t_m = z_t_m
   end if
;---------------------------------------------------------------------------------------------------------------------------------------
; write out data to skelton file created above
;----------
   f_out->$clat$ = lat_shift
   f_out->$clon$ = lon_shift
   f_out->$cvar$ = var_in_shift
;----------
; rename file_out_temp to file_out
;----------
   system("mv /temp_" + cvar + ".nc " + file_out)
;
end
