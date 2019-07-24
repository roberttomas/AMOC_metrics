;-------------------------------------------------------------------------------------------
; 7 March 2019
;
; Script to modify HR pop monthly single variable time series files so that they are better 
; compatible with the rapidmoc software.  
;-----------
; 1) If z_t exist, replace with variable named z_t_m for z_t with units of meters and replace z-coordinate variable in data variable 
; 2) convert units from cgs to mks
;    A) TAUX: 1 dyne/cm2 = 0.1  N/m2 
;    B) UVEL: 1 cm/s     = 0.001 m/s
;    C) VVEL: 1 cm/s     = 0.001 m/s 
;    D) SALT: no changes 
;    E) TEMP: no changes
; 3) Change longitude range from 0-360 to -180 to 180 and shift so that the GM is near the middle for most of the grid
; 4) Relpace ULAT, ULONG, VLAT, VLONG with fields that don't have missing values
; 5) sub-sample every 10th point  if l_subsample 
; 
;-------------------------------------------------------------------------------------------
begin
   case = "g.e20.G.TL319_t13.control.001_hfreq"
   l_subsample = False
;
;   cyear = "0050-01"
;   cvar = "VVEL"
;----------
   if(.not. isvar("cyear")) then
      cyear = getenv("CYEAR")
   end if
;
   if(.not. isvar("cvar")) then
      cvar  = getenv("CVAR")
   end if
;-------------------------------------------------------------------------------------------
   if ( (cvar .ne. "TAUX")  .and.  (cvar .ne. "SALT")  .and.  (cvar .ne. "TEMP") .and.  (cvar .ne. "UVEL")  .and.  (cvar .ne. "VVEL") ) then 
      print("This script does not currently supported this variable: " + cvar)
      exit
   end if
;-------------------------------------------------------------------------------------------
; Add file.  Create new file without coordinates that will be changed by this script - need to treat velocity and tracer fields differently.
   dir_in = "." ;    "/glade/scratch/altuntas/archive/" + case + "/ocn/hist/mavg"
   file_in = case + ".pop.h." + cvar + "." + cyear + ".nc"
   print("Processing file: " + file_in)
   f_in = addfile(dir_in + "/" + file_in,"r")
   file_out = case + ".pop.h." + cvar + "." + cyear + "_mod.nc"
   if(l_subsample) then
      file_out = case + ".pop.h." + cvar + "." + cyear + "_mod_ss.nc"
   end if
   if( (cvar .eq. "UVEL") .or. (cvar .eq. "VVEL") .or. (cvar .eq. "TAUX") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,ULAT,ULONG " + case + ".pop.h." + cvar + "." + cyear + ".nc -o temp_" +cyear + "_" + cvar + ".nc")
      clat = "ULAT"
      clon = "ULONG"
   end if
;
   if( (cvar .eq. "TEMP") .or. (cvar .eq. "SALT") ) then
      system("ncks -O -C -x -v " + cvar + ",z_t,TLAT,TLONG " + case + ".pop.h." + cvar + "." + cyear + ".nc -o temp_" +cyear + "_" + cvar + ".nc")
      clat = "TLAT"
      clon = "TLONG"
   end if
   f_out = addfile("temp_" + cyear + "_" + cvar + ".nc", "w")
;
   var_in = f_in->$cvar$
;--------------
; It looks like the fill values got rounded down in the least signficiant digit during the time series extraction using ncks.
; So here, reset the fill value areas 
   if( (cvar .eq. "TAUX") .or. (cvar .eq. "TEMP") .or. (cvar .eq. "UVEL") .or. (cvar .eq. "VVEL") ) then
         var_in = where(var_in .gt. 9.969e36, var_in@_FillValue, var_in)
   end if
   if( (cvar .eq. "SALT") ) then
         var_in = where(var_in .gt. 9.969e33, var_in@_FillValue, var_in)
   end if
;--------------
; read these in from a file that has the fields w/o any missing values
;   lat    = f_in->$clat$
;   lon    = f_in->$clon$
   time   = f_in->time
;
; read in lat/lon arrays from a file that has the fields w/o missing values
   file_grid_in = "/glade/work/bryan/global_0.1_tripole/aux_data/grid/grid.tx01_62l.2013-07-13.nc"
   f_grid_in = addfile(file_grid_in, "r")
   lat = f_grid_in->$clat$
   lon = f_grid_in->$clon$
;---------------------------------------------------------------------------------------------------------------------------------------
; shift so that 0 degrees longitude is ~in the middle for most of the grid and have longitudes increase monotonically, left to rignt and 
; range between -180 to 180
;
;----------
; initialize some indicies
;----------
   imax = 3600
; pivot i-index (~corresponding to the date line) is different for U-grid and T-grid
   if(clon .eq. "ULONG") then
      ipivot = 2899 ; 2898
   end if
   if(clon .eq. "TLONG") then
      ipivot = 2900 ; 2899
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
   var_in_shift = var_in
   if( dimsizes(dimsizes(var_in)) .eq. 3 ) then
      var_in_shift(:,:,imax-ipivot-1:imax-1) = var_in(:,:,0:ipivot)
      var_in_shift(:,:,0:imax-ipivot-2)      = var_in(:,:,ipivot+1:imax-1)
   end if
   if( dimsizes(dimsizes(var_in)) .eq. 4 ) then
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
      var_in_shift = 0.1 * var_in_shift
      var_in_shift@units = "Newton/meter^2"
   end if

; For VVEL convert centimeters/second to meters/second
   if(  (cvar .eq. "UVEL") .or. (cvar .eq. "VVEL") )
      var_in_shift = 0.01 * var_in_shift
      var_in_shift@units = "meter/s"
   end if

;---------------------------------------------------------------------------------------------------------------------------------------
; if coordinate variable z_t exists, then replace it with z_t_m 
   if(var_in_shift!1 .eq. "z_t") then

; create and add coordinte variable z_t_m for z_t in units of meters
      z_t = f_in->z_t
      z_t_m = z_t
      z_t_m = z_t_m/100. 
      z_t_m!0 = "z_t_m"
      z_t_m@units = "m"
      z_t_m@valid_min = 5.
      z_t_m@valid_max = 5874.991
      f_out->z_t_m = z_t_m
;----------
; overwrite existing z_t coordinate variable with z_t_m
;----------
      var_in_shift!1 = "z_t_m"
      var_in_shift&z_t_m = z_t_m
   end if
;---------------------------------------------------------------------------------------------------------------------------------------
; add 1957*365 to time  (so that first model year is 1958, corresponding to first year of JRA55 forcing)
; 27 March 19: This resulted in times corresponding to 20080201 to 20180101 and 
; 27 March 19: This may cause problems with the RapidMoc code when it looks to compare to observations.  The rapid MOC
; 27 March 19: code did play well when my CESM data time corresponed to 20010201 to 20110101
   time_shift = time
   time_shift = (/ time + 1957.*365. /)
   var_in_shift&time = time_shift
;---------------------------------------------------------------------------------------------------------------------------------------
; write out data to skelton file created above
;----------
;
   rank = dimsizes(dimsizes(var_in))
   if( rank .ne. 3 .and. rank .ne. 4 ) then
      print("var_in must be rank 3 or 4")
      print(dimsizes(dimsizes(var_in)))
      exit
   end if
;
   if(l_subsample) then
      nss = 10
   else
      nss = 1
   end if

   f_out->$clat$ = lat_shift(::nss,::nss)
   f_out->$clon$ = lon_shift(::nss,::nss)
   f_out->time = time_shift
   if( rank .eq. 3) then
      f_out->$cvar$ = var_in_shift(:,::nss,::nss)
   end if
   if( rank .eq. 4) then
      f_out->$cvar$ = var_in_shift(:,:,::nss,::nss)
   end if
;----------
; rename file_out_temp to file_out
;----------
   system("mv temp_" + cyear + "_" + cvar + ".nc " + file_out)
;
end
