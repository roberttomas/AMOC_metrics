;------------------------------------------------------------------------------------------------------------------------
; 13 June 2019
; This code is an exploratory effort to reproduce some of the Roberts code calculations in an ncl framework, written by me.
;
; For now, I'm just working with the LR decadal mean history file.
; I have decadal mean single variable files for the HR case on /glade/work/tomas for later.
; I'm not using the modified data that I fed into the Roberts code because some of the grid variables were not in the files
;
; I started this code by copying /gpfs/u/home/tomas/amoc_metrics/ncl/plot_26N_cross_section/plot_26N_cross_section.ncl   
;           to calc_normalflux.ncl
;---------------------
; 21 June 2019
; order of operations:
; 1) calculate vvel * dx * dz on model grid (z, lon, lat)
; 2) linearly interpolate (1) in latitude to get a cross section at latofflow (z, lon, latofflow)
; 3) sum values at appropriate subset of longitudes (in the x-direction) to get the Atlantic sector at latofflow (z, latofflow )
; 4) form cumulative sum in z, starting at the bottom, to get the stream function (z, latofflow )
; When comparing to moc output by pop or calculated off line using the same methodology, note that these are at z_w levels
; and what I calculate is at z_t levels.  These needs to be taken into account when plotting.  
;------------------------------------------------------------------------------------------------------------------------
begin
; resolution
   cres = "LR"
   latofflow = 26.5
;
   if(cres .eq. "HR") then
      print("HR not operational yet...")
      exit
      file_in = "/gpfs/fs1/work/tomas/RapidMoc/data/g.e20.G.TL319_t13.control.001_hfreq/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.004301_avg_005212_mod.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_lr_mod
      imin = 988
      imax = 1680
      jmin = 1456
      jmax = 1456
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;
   if(cres .eq. "ASD") then
      print("ASD not operational yet...")
      exit
      file_in = "/gpfs/fs1/work/tomas/RapidMoc/data/hybrid_v5_rel04_BC5_ne120_t12_pop62/hybrid_v5_rel04_BC5_ne120_t12_pop62.pop.h.VVEL.0077_avg_0086_mod.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_lr_mod
      imin = 988
      imax = 1680
      jmin = 1456
      jmax = 1456
      gsnLeftString = "Fully Coupled; Yrs. 77-86"
   end if
;
;
   if(cres .eq. "LR") then
      file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.004301_avg_005212.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_mod
      imin = 87; 87, 88
      imax = 151; 148
      jmin = 270; 271
      jmax = 271; 271
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;------------------------------------------------------------------------------------------------------------------------
   f_in    = addfile(file_in, "r")
;
   ulat = f_in->ULAT
   ulon = f_in->ULONG
   dxu  = f_in->DXU
   angle = f_in->ANGLE
;------------
; remove time dimension with leading zero dimension followed by colons
   vvel = f_in->VVEL(0,:,:,:)
; subtract cosine of the angle?  probably shouldn't unless you also bring in UVEL
;   vvel = (/ doubletofloat(vvel * conform(vvel, cos(angle), (/1,2/)) ) /) 
   z_t = f_in->z_t
   z_t_m = z_t/100.
   dz = f_in->dz
   dzmin = dz(0)
   dzmax = dz(dimsizes(dz)-1)
;   print("dzmin: " + dzmin + " dzmax: " + dzmax)
;
; This is a quick and dirty calculation.  I have not checked to make sure the indexing is correct; I think it
; could be off by a little in the x and/or y directtion. That is, vvel and dxu do not line up properly
   print("Indexing of vvel, dxu, dz is at least close; need to verify that they are correct")
   flux = vvel
   flux = (/ doubletofloat(vvel * conform(vvel, dxu, (/1,2/)) * conform(vvel, dz, 0)) /)
   flux@long_name = "flux"
   flux@units     = "cm^3/s"
;   flux = where( fabs(flux ) .gt. 9.e36, flux@_FillValue, flux)
;   printVarSummary(flux)
;---------------------------------------------------------------------------------------------------------------------------------------
; shift so that 0 degrees longitude is ~in the middle for most of the grid and have longitudes increase monotonically, left to rignt and
; range between -180 to 180
;
;----------
; initialize some indicies
;----------
   imaxgrid = 320
   ipivot = 194  ; for ULONG
;   ipivot = 195 ; for TLONG
;----------
; shift longitude array
;----------
;
   ulon_shift = ulon
   ulon_shift(:,imaxgrid-ipivot-1:imaxgrid-1) = ulon(:,0:ipivot)
   ulon_shift(:,0:imaxgrid-ipivot-2)      = ulon(:,ipivot+1:imaxgrid-1)
   ulon_shift = where(ulon_shift .gt. 180.d0, ulon_shift - 360.d0, ulon_shift)
;----------
; shift latitude array
;----------
;
   ulat_shift = ulat
   ulat_shift(:,imaxgrid-ipivot-1:imaxgrid-1) = ulat(:,0:ipivot)
   ulat_shift(:,0:imaxgrid-ipivot-2)      = ulat(:,ipivot+1:imaxgrid-1)
;----------
; shift data array
;----------
; flux is vvel * dx *dz, then cumulative sum in the z direction, starting at the bottom 
   flux_shift = flux
   flux_shift(:,:,imaxgrid-ipivot-1:imaxgrid-1) = flux(:,:,0:ipivot)
   flux_shift(:,:,0:imaxgrid-ipivot-2)      = flux(:,:,ipivot+1:imaxgrid-1)
;   print("flux_shift:  Min: " + min(flux_shift) + "  Max: " + max(flux_shift) )
;---------------------------------------------------------------------------------------------------------------------------------------
; Interpolate in latitutde to latofflow
; Use a sub-section around 26.6 rather than all latitudes at a longitude because latitude is not always monotonic at all longitudes 
; near the NP and linit1 requires monotonicity
;----------
; create array and assign appropriate coordinate names
   flux_shift_at26n = dim_sum_n_Wrap(flux_shift,1)
   flux_shift_at26n = 0.
;
;   do ni = 0, imaxgrid - 1
;      xin = ulat_shift(jmin-5:jmax+5,ni)
;      flux_shift_at26n(:,ni) = linint1(xin, flux_shift(:,jmin-5:jmax+5,ni), False, latofflow, 0) 
;   end do
; As a test: don't interpolate.  Use the jmin values instead.
;   print("not interpolating to a latitude!!!")
;   print("using values averaged over jmin: " + jmin + "  jmax: " + jmax)
;   flux_shift_at26n(:,:) = dim_avg_n_Wrap(flux_shift(:,jmin:jmax,:),1)
;---------
   print("not interpolating to a latitude!!!")
   print("using latitude ranges to estimate where to use flux values")
   dims = dimsizes(ulat_shift)
   nlat = dims(0)
   nlon = dims(1)
   delete(dims) 
;
   ulatjp1_shift = ulat_shift
   do nj = 0, nlat - 2
      ulatjp1_shift(nj,:) = ulat_shift(nj+1,:)
   end do
   ulatjp1_shift(nlat-1,:) = ulatjp1_shift@_FillValue
;
   ulatjm1_shift = ulat_shift
   do nj = 1, nlat - 1
      ulatjm1_shift(nj,:) = ulat_shift(nj-1,:)
   end do
   ulatjm1_shift(0,:) = ulatjm1_shift@_FillValue
;
   ulatn_shift = ulat_shift
   ulatn_shift = (ulatjp1_shift + ulat_shift)/2.
   ulats_shift = ulat_shift
   ulats_shift = (ulatjm1_shift + ulat_shift)/2.
;   printVarSummary(ulatn_shift)
;
   ulats_shift_3d = conform(flux_shift, ulats_shift, (/1,2/))
   ulatn_shift_3d = conform(flux_shift, ulatn_shift, (/1,2/))
;
   dummy = flux_shift
   dummy = where( 26.5 .ge. ulats_shift_3d .and.  26.5 .le. ulatn_shift_3d, dummy, 0.)
   system("rm junk.nc")
   f_out = addfile("junk.nc","c")
   f_out->dummy=dummy
;
   flux_shift_at26n = dim_sum_n_Wrap(dummy,1)
   delete(dummy)
;---------
;
;----------
; Sum the Atlantic subsection defined by imax, imin
;----------
;
   sf_atl_at26n  = dim_sum_n_Wrap(flux_shift_at26n(:,imin:imax), 1)
;   printVarSummary(sf_atl_at26n)
;----------
; Calculate cumulative sum in z starting at the bottom to get the stream function
;----------
; 
   sf_atl_at26n = (/ -1.*sf_atl_at26n /)
   do nz = dimsizes(dz) - 2, 1, 1
      sf_atl_at26n(nz) = sf_atl_at26n(nz+1) +  sf_atl_at26n(nz)
   end do
; scale
   sf_atl_at26n = (/ sf_atl_at26n / 1.e12 /)
;
;   system("rm junk.nc")
;   f_out = addfile("junk.nc","c")
;   f_out->sf=sf_atl_at26n
;   f_out->ulat_shift=ulat_shift
;   f_out->ulon_shift=ulon_shift
; 
   print("ulon_shift(jmin,imin): " + ulon_shift(jmin,imin) + "  ulon_shift(jmin,imax): " + ulon_shift(jmin,imax) )
   print("ulat_shift(jmin,imin): " + ulat_shift(jmin,imin) + "  ulat_shift(jmax,imax): " + ulat_shift(jmax,imax) )
;------------------------------------------------------------------------------------------------------------
; Read MOC from file
; LR
;   file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.MOC.004301-005212.nc"
   file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.004301_avg_005212.nc"
   f_in = addfile(file_in, "r")
;-----------
;   float MOC(time, transport_reg, moc_comp, moc_z, lat_aux_grid) ;
;
;   transport_regions =
;  "Global Ocean - Marginal Seas",
;  "Atlantic Ocean + Mediterranean Sea + Labrador Sea + GIN Sea + Arctic Ocean + Hudson Bay" ;
;
;   moc_components =
;  "Eulerian Mean",
;  "Eddy-Induced (bolus)",
;  "Submeso" ;

; Atlantic Ocean(2nd subscript, 1) +, Eulerian Mean(3rd subscript, 0)
; Dimensions and sizes:    [time | 1] x [transport_reg | 2] x [moc_comp | 3] x [moc_z | 61] x [lat_aux_grid | 395]
   lat_aux_grid = f_in->lat_aux_grid
   moc_z        = f_in->moc_z
   moc_z_m      = (/ moc_z/100. /)
   moc_all  = dim_avg_n_Wrap(f_in->MOC(:,1,0,:,:),0)
; interpolate to latofflow
   dummy    = linint1(lat_aux_grid, moc_all, False, latofflow, 0)
   moc_temp = dummy(:,0)
   delete(dummy)
   moc_temp!0 = "moc_z"
   moc_temp&moc_z = moc_z
;
; plot all three components summed together - they are different only near the surface, need to ask why
;   moc_temp = (/ dim_avg_n_Wrap(f_in->MOC(:,1,0,:,{latofflow}),0) + dim_avg_n_Wrap(f_in->MOC(:,1,1,:,{latofflow}),0) + dim_avg_n_Wrap(f_in->MOC(:,1,2,:,{latofflow}),0) /)
   moc_pop_lr = moc_temp
   delete(moc_temp)
;------------------------------------------------------------------------------------------------------------
; RapidMoc output
file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/lr_2000-2010_natl_meridional_transports_at_26N.nc"
;
   f_in = addfile(file_in, "r")
   sf_rapid_lr = dim_avg_n_Wrap(f_in->sf_rapid, 0)
;   printVarSummary(sf_rapid_lr)
   sf_model_lr = dim_avg_n_Wrap(f_in->sf_model, 0)
;----------
;   printVarSummary(sf_model_lr) 
   print("Fudging RapidMoc model amoc to zero at botton")
; subract bottom value of amoc from all levels
   sf_model_lr = (/ sf_model_lr - sf_model_lr(dimsizes(sf_model_lr)-1) /)
;----------
   depth_lr = f_in->depth
;
; components
   sf_ek_lr     = dim_avg_n_Wrap(f_in->sf_ek, 0);        "Ekman overturning streamfunction."
   sf_geoint_lr = dim_avg_n_Wrap(f_in->sf_geoint, 0);    "Geostrophic interior overturning streamfunction."
   sf_wbw_lr    = dim_avg_n_Wrap(f_in->sf_wbw, 0);       "Western boundary wedge overturning streamfunction."
   sf_fc_lr     = dim_avg_n_Wrap(f_in->sf_fc, 0);        "Florida current overturning streamfunction." ;
   sf_mo_lr     = dim_avg_n_Wrap(f_in->sf_mo, 0);        "Mid ocean overturning streamfunction (sf_mo = sf_wbw + sf_int)."
;------------------------------------------------------------------------------------------------------------
; Calculate imin_calc, imax_calc, jmin_calc, jmax_calc  - prototype 26 June 19
; Longitudes specified must range between -180. and 180.
;
   lat_loc     =  26.5
   lon_min_loc = -81.0
   lon_max_loc =  -10.0
   dims = dimsizes(ulat_shift)
; 1) 
; lat_loc, lon_min_loc
   dist_array = sqrt ( (ulat_shift - lat_loc)^2 + (ulon_shift - lon_min_loc)^2 )
;
   oned_dist_array = ndtooned(dist_array)
   oned_min_loc = minind(oned_dist_array)
   indices_min_loc = ind_resolve(oned_min_loc,dims)
;
; min_lat_loc is latitude index at minimum longitude location
   min_lat_loc = ulat_shift(indices_min_loc(0,0), indices_min_loc(0,1))
   min_lon_loc = ulon_shift(indices_min_loc(0,0), indices_min_loc(0,1))
;
   print("min_loc:  j: " + indices_min_loc(0,0) + ", i: " + indices_min_loc(0,1))
   print("min_loc:  lon: " + min_lon_loc + ", lat: " + min_lat_loc)
;
; 2) 
; lat_loc, lon_max_loc
   dist_array = sqrt ( (ulat_shift - lat_loc)^2 + (ulon_shift - lon_max_loc)^2 )
;
   oned_dist_array = ndtooned(dist_array)
   oned_min_loc = minind(oned_dist_array)
   indices_max_loc = ind_resolve(oned_min_loc,dims)
;
; max_lat_loc is latitude index at maximum longitude location
   max_lat_loc = ulat_shift(indices_max_loc(0,0), indices_max_loc(0,1))
   max_lon_loc = ulon_shift(indices_max_loc(0,0), indices_max_loc(0,1))
;
   print("max_loc:  j: " + indices_max_loc(0,0) + ", i: " + indices_max_loc(0,1))
   print("min_loc:  lon: " + max_lon_loc + ", lat: " + max_lat_loc)
;
;
;======================================================================================================================
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + ".png"
   wks_type = "png"
   wks_type@wkWidth = 1024   ; 1024 is default
   wks_type@wkHeight = 1024  ; 1024 is default
   wks = gsn_open_wks(wks_type,file_out)
;
   res=True
   res@gsnDraw = False
   res@gsnFrame = False
;
   res@trYReverse = True
   res@vpWidthF   = 0.6
   res@vpHeightF  = 0.6
;
   res@tiXAxisString = "Moc(Sv)"
   res@tiYAxisString = "Depth(m)"
   res@tiMainString = "Two methods, LR POP AMOC at " + latofflow +  "N: POP vs. vvel*dx*dz"
;
; add a legend
   res@pmLegendDisplayMode    = "Always"              ; turn on legend
;
   res@pmLegendSide           = "Bottom"              ; Change location of
   res@pmLegendParallelPosF   =  0.65                 ; move units right
   res@pmLegendOrthogonalPosF = -0.60                 ; more neg = down
;
   res@pmLegendWidthF         = 0.25                  ; Change width and
   res@pmLegendHeightF        = 0.25                  ; height of legend.
   res@lgLabelFontHeightF     = .017                  ; change font height
   res@lgPerimOn              = False                 ; no box around
;
   plot   = new(1, graphic)
   oplot  = new(1, graphic)
   plot_data = new( (/2,dimsizes(moc_pop_lr)/), "float")
   plot_data(0,:) = moc_pop_lr
   plot_data(1,:) = 0.
;
   res@xyLineThicknesses := (/ 5.0 /)
   res@xyDashPatterns := (/ 0 /) ;    2, 12
   res@xyLineColors   := (/ "red" /)
;   res@trYMaxF = 500.
;   res@trYMinF = 0.
   res@gsnXRefLine = 0.
;
   print("MOC POP: " + dim_sum(moc_pop_lr) )
   print("MOC Bob: " + dim_sum(sf_atl_at26n) )
;
   res@xyExplicitLegendLabels := (/"LR - POP Eul.Mean" /);    , "LR - POP Bob's" /)
;;;;;                                       "LR - Bob's ncl"/)
   plot  = gsn_csm_xy(wks, moc_pop_lr, moc_z_m, res)         ;
;----------
   res@xyLineColors   := (/  "black" /)
   res@xyExplicitLegendLabels := (/ "LR - POP Bob's" /)
   res@pmLegendOrthogonalPosF = -0.65                 ; more neg = down
   oplot = gsn_csm_xy(wks, sf_atl_at26n, z_t_m, res)         ;
   overlay(plot, oplot)
;----------
   res@xyLineColors   := (/  "green" /)
   res@xyExplicitLegendLabels := (/ "LR - RapidMoc model" /)
   res@pmLegendOrthogonalPosF = -0.70                 ; more neg = down
   oplot = gsn_csm_xy(wks, sf_model_lr, depth_lr, res)         ;
   overlay(plot, oplot)
;----------
 
;
   pres = True
   gsn_panel(wks,plot,(/1,1/),pres)             ;
end
