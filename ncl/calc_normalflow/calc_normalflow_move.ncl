;------------------------------------------------------------------------------------------------------------------------
; 1 July 2019
; This code calculates the normal flow using the MOVE recipe, p. 14 of the proposal.  
; I am trying to work on the pop native grid for all calculations. 
; I am also trying to work with the pop grid native lat/lon format
;
;---------------------
; 21 June 2019
; order of operations:
; 1) calculate vvel * dx * dz on model grid (z, lon, lat)
; 2) linearly interpolate (1) in latitude to get a cross section at latofflow (z, lon, latofflow) - or uses value at a j-index point.  See code.
; 3) sum values at appropriate subset of longitudes (in the x-direction) to get the Atlantic sector at latofflow (z, latofflow )
; 4) form cumulative sum in z, starting at the bottom, to get the stream function (z, latofflow )
; When comparing to moc output by pop or calculated off line using the same methodology, note that these are at z_w levels
; and what I calculate is at z_t levels.  These needs to be taken into account when plotting.  
;------------------------------------------------------------------------------------------------------------------------
begin
; resolution
   cres = "LR"
   latofflow = 16.0
   zmin = 1200.
   zmax = 5000.
   lat_min = -61.0
   lat_max = -51.0
   cm3pstosv = 1./(100.*100*100*1.e6) ; cm->m  &  1.e6 m^3/s->Sv
;
   if(cres .eq. "HR") then
      print("HR not operational yet...")
      exit
      file_in = "/gpfs/fs1/work/tomas/RapidMoc/data/g.e20.G.TL319_t13.control.001_hfreq/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.004301_avg_005212_mod.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_lr_mod
      imin = 920
      imax = 1680
      jmin = 1343
      jmax = 1343
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;
   if(cres .eq. "ASD") then
      print("ASD not operational yet...")
      exit
      file_in = "/gpfs/fs1/work/tomas/RapidMoc/data/hybrid_v5_rel04_BC5_ne120_t12_pop62/hybrid_v5_rel04_BC5_ne120_t12_pop62.pop.h.VVEL.0077_avg_0086_mod.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_lr_mod
      imin = 920
      imax = 1680
      jmin = 1343
      jmax = 1343
      gsnLeftString = "Fully Coupled; Yrs. 77-86"
   end if
;
;
   if(cres .eq. "LR") then
; grid file zzz
      file_ing = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/grid_info.gx1v7.nc"
      file_inv = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.VVEL.004301-005212.nc"
; these indicies are appropriate for data that has been shifted so that the GM is near the center of the domain.
; shifting is done after the flux calculations, below
      imin = 105   ; 105 is -61.36 at j = 245
      imax = 114   ; 114 is -51.24 at j = 245
      jmin = 245   ; 245 is  15.93 at i = 105
      jmax = 245   ; 245 is  15.90 at i = 114
      kmin = 40
      kmax = 58
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;------------------------------------------------------------------------------------------------------------------------
; grid information
   f_ing    = addfile(file_ing, "r")
;
   ulat  = f_ing->ULAT
   ulon  = f_ing->ULONG
   dxu   = f_ing->DXU
   dxu_m = dxu/100.
   dxu_m@units = "m"
   angle = f_ing->ANGLE
   z_t   = f_ing->z_t
   z_t_m = z_t/100.
   z_t_m@units = "m"
   dz    = f_ing->dz
   dz_m  = dz/100.
   dz_m@units = "m"
;------------
; meridional velocity field
   f_inv    = addfile(file_inv, "r")
;
   vvel = f_inv->VVEL(:,:,:,:)
; include cosine of the angle VVEL makes with the grid face?  probably shouldn't unless you also bring in UVEL
;   vvel = (/ doubletofloat(vvel * conform(vvel, cos(angle), (/1,2/)) ) /) 
   dzmin = dz(0)
   dzmax = dz(dimsizes(dz)-1)
   print("dzmin: " + dzmin + " dzmax: " + dzmax)
;
; This is a quick and dirty calculation.  I have not double checked to make sure the indexing is correct; I think it
; is, but it could be off by a little in the x and/or y directtion. That is, vvel and dxu do not line up properly
   print("Indexing of vvel, dxu, dz is at least close; need to verify that they are correct")
   flux = vvel
   flux = (/ doubletofloat(vvel * conform(vvel, dxu, (/2,3/)) * conform(vvel, dz, 1)) /)
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
;-----------
; check to see if lat, lon are what the user expects
   print("----------------------------------------------------------------------------------------------------")
   print("Are these lat/lon values what you expect them to be?")
   print("lat_min: " + ulat_shift(jmin,imin) + "  lon_min: " + ulon_shift(jmin,imin) )
   print("lat_max: " + ulat_shift(jmax,imax) + "  lon_max: " + ulon_shift(jmax,imax) )
   print("zmin(cm): " + z_t(kmin) + "  zmax(cm): " + z_t(kmax) )
   print("----------------------------------------------------------------------------------------------------")
;----------
; shift data array
;----------
; flux is vvel * dx *dz, then cumulative sum in the z direction, starting at the bottom 
   flux_shift = flux
   flux_shift(:,:,:,imaxgrid-ipivot-1:imaxgrid-1) = flux(:,:,:,0:ipivot)
   flux_shift(:,:,:,0:imaxgrid-ipivot-2)      = flux(:,:,:,ipivot+1:imaxgrid-1)
;   print("flux_shift:  Min: " + min(flux_shift) + "  Max: " + max(flux_shift) )
;---------------------------------------------------------------------------------------------------------------------------------------
; Interpolate in latitutde to latofflow
; Use a sub-section around 26.6 rather than all latitudes at a longitude because latitude is not always monotonic at all longitudes 
; near the NP and linit1 requires monotonicity
;----------
; create array with the appropriate dimenstions, sizes and names  Dimensions and sizes:    [time | 12] x [z_t | 60] x [nlon | 320]
   flux_shift_at16n = dim_sum_n_Wrap(flux_shift,2)
   flux_shift_at16n = 0.
;
;   do ni = 0, imaxgrid - 1
;      xin = ulat_shift(jmin-5:jmax+5,ni)
;      flux_shift_at16n(:,ni) = linint1(xin, flux_shift(:,jmin-5:jmax+5,ni), False, latofflow, 0) 
;   end do
; As a test: don't interpolate.  Use the jmin values instead.
      print("not interpolating to a latitude!!!")
      print("using values averaged over jmin: " + jmin + "  jmax: " + jmax)
;      printVarSummary(flux_shift)
;      printVarSummary(flux_shift_at16n)
      flux_shift_at16n  = dim_avg_n_Wrap(flux_shift(:,:,jmin:jmax,:),2)
;----------
; Sum the Atlantic subsection defined by imax, imin
;----------
;
   flux_atl_at16n  = dim_sum_n_Wrap(flux_shift_at16n(:,:,imin:imax), 2)
;----------
; Sum over zmax to zmin
   flux_move  = dim_sum_n_Wrap(flux_atl_at16n(:, kmin:kmax), 1)
;   printVarSummary(flux_move)
   flux_move_sv = flux_move*cm3pstosv
   do nt = 0, dimsizes(flux_move_sv) - 1
      print("flux_move(Sv): " + flux_move_sv(nt))
   end do
   exit
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
   print("MOC Bob: " + dim_sum(sf_atl_at16n) )
;
   res@xyExplicitLegendLabels := (/"LR - POP Eul.Mean" /);    , "LR - POP Bob's" /)
;;;;;                                       "LR - Bob's ncl"/)
   plot  = gsn_csm_xy(wks, moc_pop_lr, moc_z_m, res)         ;
;----------
   res@xyLineColors   := (/  "black" /)
   res@xyExplicitLegendLabels := (/ "LR - POP Bob's" /)
   res@pmLegendOrthogonalPosF = -0.65                 ; more neg = down
   oplot = gsn_csm_xy(wks, sf_atl_at16n, z_t_m, res)         ;
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
