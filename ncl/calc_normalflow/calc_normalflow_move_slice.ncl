;------------------------------------------------------------------------------------------------------------------------
; 1 July 2019
; This code calculates the normal flow using the MOVE recipe, p. 14 of the proposal.
; I am trying to use data that has been modified (shifted) so that I only read in a subsection.
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
; not used
;   latofflow = 16.0
;   zmin = 1200.
;   zmax = 5000.
;   lat_min = -61.0
;   lat_max = -51.0
   cm3pstosv = 1./(100.*100*100*1.e6) ; cm->m  &  1.e6 m^3/s->Sv
;
   if(cres .eq. "HR") then
      print("HR in testing ...") 
      file_inv = "/glade/scratch/tomas/g.e20.G.TL319_t13.control.001_hfreq/ocn/proc/tseries/monthly/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.004301-004312.nc"
      files_inv = systemfunc("ls /glade/scratch/tomas/g.e20.G.TL319_t13.control.001_hfreq/ocn/proc/tseries/monthly/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.00{43,44,45,46,47,48,49,50,51,52}01-00??12.nc")
;      files_inv = systemfunc("ls /glade/scratch/tomas/g.e20.G.TL319_t13.control.001_hfreq/ocn/proc/tseries/monthly/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.004301-00??12.nc")
      file_ing = "/glade/scratch/altuntas/archive/g.e20.G.TL319_t13.control.001_hfreq/ocn/hist/mavg/g.e20.G.TL319_t13.control.001_hfreq.pop.h.0043-01.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_lr_mod
      imin = 1189
      imax = 1289
      jmin = 1343
      jmax = 1343
      kmin = 40
      kmax = 58
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;
   if(cres .eq. "ASD") then
      print("ASD not operational yet...")
      exit
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

;      file_inv = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.VVEL.004301-005212.nc"
      file_inv = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.VVEL.025001-026612.nc"


; These indicies are appropriate for data that has been shifted so that the GM is near the center of the domain.
; Shifting is done after the flux calculations, below
      imin = 105   ; 105 is -61.36 at j = 245
      imax = 114   ; 114 is -51.24 at j = 245
      jmin = 245   ; 245 is  15.93 at i = 105
      jmax = 245   ; 245 is  15.90 at i = 114
      kmin = 40
      kmax = 58
;
; span nearly fully basin
      imin_full =  84   ;  84 is -84.96 at j = 245
      imax_full = 146   ; 146 is -15.27 at j = 245
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
;------------------------------------------------------------------------------------------------------------------------
; grid information
   f_ing    = addfile(file_ing, "r")
;
   ulat  = f_ing->ULAT
   ulon  = f_ing->ULONG
;-------
;   dxu   = f_ing->DXU(jmin:jmax,:,:)
   dxu_at16n   = dim_avg_n_Wrap(f_ing->DXU(jmin:jmax,:),0)
;   dxu_m = dxu/100.
;   dxu_m@units = "m"
;-------
   angle = f_ing->ANGLE
   z_t   = f_ing->z_t
   z_t_m = z_t/100.
   z_t_m@units = "m"
   dz    = f_ing->dz
   dz_m  = dz/100.
   dz_m@units = "m"
;------------------------------------------------------------------------------------------------------------------------
; meridional velocity field
   if(cres .eq. "LR") then
      f_inv    = addfile(file_inv, "r")
      vvel_at16n = dim_avg_n_Wrap(f_inv->VVEL(:,:,jmin:jmax,:), 2)
      time = f_inv->time
   end if
   if(cres .eq. "HR") then
      f_inv    = addfiles(files_inv, "r")
      vvel_at16n = dim_avg_n_Wrap(f_inv[:]->VVEL(:,:,jmin:jmax,:), 2)
      time = f_inv[:]->time
   end if
;
   print("about to read data")
;-------
   if(cres .eq. "LR") then
   end if
;
   if(cres .eq. "HR") then
   end if
;
   time_year = cd_calendar(time,4)
   time_year!0 = "time"
   time_year&time = time
;   printVarSummary(vvel)
;-------
   print("read data")
; include cosine of the angle VVEL makes with the grid face?  probably shouldn't unless you also bring in UVEL
;   vvel = (/ doubletofloat(vvel * conform(vvel, cos(angle), (/1,2/)) ) /) 
   dzmin = dz(0)
   dzmax = dz(dimsizes(dz)-1)
   print("dzmin: " + dzmin + " dzmax: " + dzmax)
;------------------------------------------------------------------------------------------------------------------------
; work with only the latitude or latitude average that is needed
;   vvel_at16n  = dim_avg_n_Wrap(vvel(:,:,jmin:jmax,:),2)
; Dimensions and sizes:    [time | 120] x [z_t_m | 60] x [nlon | 320]

;   dxu_at16n   = dim_avg_n_Wrap(dxu(jmin:jmax,:), 0)
; Dimensions and sizes:    [nlon | 320]
;------------------------------------------------------------------------------------------------------------------------
;
; This is a quick and dirty calculation.  I have not double checked to make sure the indexing is correct; I think it
; is, but it could be off by a little in the x and/or y directtion. That is, vvel and dxu do not line up properly
   print("Indexing of vvel, dxu, dz is at least close; need to verify that they are correct")
   flux_at16n = vvel_at16n
   print("about to calculate flux")
   flux_at16n = (/ doubletofloat(vvel_at16n * conform(vvel_at16n, dxu_at16n, 2) * conform(vvel_at16n, dz, 1)) /)
   print("calculated flux_at16n")
   flux_at16n@long_name = "flux"
   flux_at16n@units     = "cm^3/s"
;---------------------------------------------------------------------------------------------------------------------------------------
   print("about to shift data")
; shift so that 0 degrees longitude is ~in the middle for most of the grid and have longitudes increase monotonically, left to rignt and
; range between -180 to 180
;
;----------
; initialize some indicies
;----------
   if(cres .eq. "LR") then
      imaxgrid = 320
      ipivot = 194  ; for ULONG
;      ipivot = 195 ; for TLONG
   end if
   if(cres .eq. "HR") then
      imaxgrid = 3600
; pivot i-index (~corresponding to the date line) is different for U-grid and T-grid
         ipivot = 2899 ; 2898 ; for ULONG
;         ipivot = 2900 ; 2899 ; for TLONG
   end if
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
   lat_min_used = ulat_shift(jmin,imin)
   lon_min_used = ulon_shift(jmin,imin)
   lat_max_used = ulat_shift(jmax,imax)
   lon_max_used = ulon_shift(jmax,imax)
   z_min_used   = z_t(kmin)
   z_max_used   = z_t(kmax)
   lat_min_used!0 = "ncl_scalar"
   lon_min_used!0 = "ncl_scalar"
   lat_max_used!0 = "ncl_scalar"
   lon_max_used!0 = "ncl_scalar"
   z_min_used!0 = "ncl_scalar"
   z_max_used!0 = "ncl_scalar"
   print("----------------------------------------------------------------------------------------------------")
   print("Are these lat/lon values what you expect them to be?")
   print("lat_min: " + lat_min_used + "  lon_min: " + lon_min_used )
   print("lat_max: " + lat_max_used + "  lon_max: " + lon_max_used )
   print("z_min(cm): " + z_min_used + "  z_max(cm): " + z_max_used )
   print("----------------------------------------------------------------------------------------------------")
;----------
; shift data array
;----------
; flux is vvel_at16n * dx_at16n *dz
   flux_shift_at16n = flux_at16n
   flux_shift_at16n(:,:,imaxgrid-ipivot-1:imaxgrid-1) = flux_at16n(:,:,0:ipivot)
   flux_shift_at16n(:,:,0:imaxgrid-ipivot-2) = flux_at16n(:,:,ipivot+1:imaxgrid-1)
;   print("flux_shift_at16n:  Min: " + min(flux_shift_at16n) + "  Max: " + max(flux_shift_at16n) )
   print("shifted data")
;
;---------------------------------------------------------------------------------------------------------------------------------------
;----------
; Sum the Atlantic subsection defined by imax, imin
;----------
;
   flux_atl_at16n  = dim_sum_n_Wrap(flux_shift_at16n(:,:,imin:imax), 2)
;   system("rm junk.nc")
;   f_out = addfile("junk.nc","c")
;   f_out->flux_atl_at16n = flux_atl_at16n
;----------
; Sum over kmax to kmin
   flux_move  = dim_sum_n_Wrap(flux_atl_at16n(:, kmin:kmax), 1)
   flux_above_move  = dim_sum_n_Wrap(dim_sum_n_Wrap(flux_shift_at16n(:, 0:kmin-1,imin_full:imax_full), 1), 1)
;   printVarSummary(flux_move)
   flux_move_sv = flux_move*cm3pstosv
   flux_move_sv!0 = "time"
   flux_move_sv&time = time
;
   flux_above_move_sv = flux_above_move*cm3pstosv
   flux_above_move_sv!0 = "time"
   flux_above_move_sv&time = time
;   do nt = 0, dimsizes(flux_move_sv) - 1
;      print("flux_move(Sv): " + flux_move_sv(nt))
;   end do
;----------------------------------------------------------------------------------------------------------------------
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + "_" + cres + ".nc"
   system("rm " + file_out)
   f_out = addfile(file_out,"c")

   fatt = True
   fatt@creation_date = systemfunc("date")
   script_name = get_script_name()
   pwd = systemfunc("echo $PWD")
   fatt@creation_script = pwd + "/" + script_name
   fatt@author = "Bob Tomas"
   fatt@lat_min = lat_min_used
   fatt@lat_max = lat_max_used
   fatt@lon_min = lon_min_used
   fatt@lon_max = lon_max_used
   fatt@z_min = z_min_used
   fatt@z_max = z_max_used
   fileattdef( f_out, fatt )

   f_out->time      = time
   f_out->time_year = time_year
   f_out->flux_move_sv = flux_move_sv
   f_out->flux_above_move_sv = flux_above_move_sv
   f_out->lat_min = lat_min_used
   f_out->lon_min = lon_min_used
   f_out->lat_max = lat_max_used
   f_out->lon_max = lon_max_used
   f_out->z_min   = z_min_used
   f_out->z_max   = z_max_used
;======================================================================================================================
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + "_" + cres + ".png"
   wks_type = "png"
   wks_type@wkWidth = 1024   ; 1024 is default
   wks_type@wkHeight = 1024  ; 1024 is default
   wks = gsn_open_wks(wks_type,file_out)
;
   res=True
   res@gsnDraw = False
   res@gsnFrame = False
;
   res@trYReverse = False
   res@vpWidthF   = 0.6
   res@vpHeightF  = 0.2
;
   res@tiXAxisString = "Year"
   res@tiYAxisString = "Transport(Sv)"
   res@tiMainString = "Ocean Volume Transport Across MOVE Section (16~S~o~N~)"
;
; add a legend
   res@pmLegendDisplayMode    = "Always"              ; turn on legend
;
   res@pmLegendSide           = "Bottom"                 ; Change location of
   res@pmLegendParallelPosF   =  0.90                 ; move units right
   res@pmLegendOrthogonalPosF = -0.60                 ; more neg = down
;
   res@pmLegendWidthF         = 0.25                  ; Change width and
   res@pmLegendHeightF        = 0.25                  ; height of legend.
   res@lgLabelFontHeightF     = .017                  ; change font height
   res@lgPerimOn              = False                 ; no box around
;
   plot   = new(1, graphic)
;
   res@xyLineThicknesses := (/ 5.0 /)
   res@xyDashPatterns := (/ 0 /) ;    2, 12
   res@xyLineColors   := (/ "red" /)
;   res@trXMinF = 43.0
;   res@trXMaxF = 53.08
   res@trYMinF = -24.0
   res@trYMaxF =  0.0
;   res@gsnXRefLine = 0.
;
   sd = decimalPlaces(dim_stddev(flux_move_sv), 1, True)
   mn = decimalPlaces(dim_avg(flux_move_sv), 1, True)
   if(cres .eq. "LR") then
      res@xyExplicitLegendLabels := (/"LR Pop ~C~Mean: " + mn + "~C~SD: " + sd /);    , "LR - POP Bob's" /)
   end if
   if(cres .eq. "HR") then
      res@xyExplicitLegendLabels := (/"HR Pop ~C~Mean: " + mn + "~C~SD: " + sd /);    , "LR - POP Bob's" /)
   end if
;;;;;                                       "LR - Bob's ncl"/)
   plot  = gsn_csm_xy(wks, time_year, flux_move_sv, res)         ;
;----------
;
   pres = True
   gsn_panel(wks,plot,(/1,1/),pres)             ;
end
