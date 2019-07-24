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
   csec = "FULL"
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
      imin =  84   ; 105 is -61.36 at j = 245
      imax = 146   ; 114 is -51.24 at j = 245
      jmin = 245   ; 245 is  15.93 at i = 105
      jmax = 245   ; 245 is  15.90 at i = 114
      kmin =  0
      kmax = 59
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
   print("about to read data")
; meridional velocity field
   if(cres .eq. "LR") then
      f_inv    = addfile(file_inv, "r")
      vvel_at16n = dim_avg_n_Wrap(f_inv->VVEL(:,:,jmin:jmax,:), 2)
; Dimensions and sizes:    [time | 204] x [z_t | 60] x [nlon | 320]
      time = f_inv->time
   end if
   if(cres .eq. "HR") then
      f_inv    = addfiles(files_inv, "r")
      vvel_at16n = dim_avg_n_Wrap(f_inv[:]->VVEL(:,:,jmin:jmax,:), 2)
      time = f_inv[:]->time
   end if
   print("read data")
;
;-------
   time_year = cd_calendar(time,4)
   time_year!0 = "time"
   time_year&time = time
;   printVarSummary(vvel)
   time4label = cd_calendar(time,0)
;-------
   dzmin = dz(0)
   dzmax = dz(dimsizes(dz)-1)
   print("dzmin: " + dzmin + " dzmax: " + dzmax)
;------------------------------------------------------------------------------------------------------------------------
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
   vvel_shift_at16n = vvel_at16n
   vvel_shift_at16n(:,:,imaxgrid-ipivot-1:imaxgrid-1) = vvel_at16n(:,:,0:ipivot)
   vvel_shift_at16n(:,:,0:imaxgrid-ipivot-2) = vvel_at16n(:,:,ipivot+1:imaxgrid-1)
;   print("vvel_shift_at16n:  Min: " + min(vvel_shift_at16n) + "  Max: " + max(vvel_shift_at16n) )
   print("shifted data")
;   printVarSummary(vvel_shift_at16n)
; remove the time mean
;   tmean = dim_avg_n_Wrap(vvel_shift_at16n, 0 )
;   vvel_shift_at16n = vvel_shift_at16n - conform(vvel_shift_at16n, dim_avg_n_Wrap(vvel_shift_at16n, 0 ), (/1,2/) )

;----------
; Assign coordinate variables to vvel for plotting
   ulon_at16n = dim_avg_n_Wrap(ulon_shift(jmin:jmax,:),0)
   vvel_shift_at16n!2 = "ulon_at16n"
   vvel_shift_at16n&ulon_at16n = ulon_at16n
   vvel_shift_at16n&z_t = z_t/100.
;======================================================================================================================
   do np = 0,  dimsizes(time) - 1
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + "_" + csec + "_" + cres + "_" + sprinti("%0.3i",np) + ".png"
   print("plotting: " + file_out)
   wks = gsn_open_wks("png",file_out)
   gsn_define_colormap(wks,"amwg_blueyellowred")
;
   plot = new(1, "graphic")
   pline = new(10, "graphic")
   pmark = new(10, "graphic")
;
   res=True
   res@gsnDraw = False
   res@gsnFrame = False
   res@trYReverse = True
;
   res@tmXBMinorLengthF = 0.0
   if(csec .eq. "WEST") then
      res@trXMinF = -62
      res@trXMaxF = -51
      res@tmXBTickStartF  = -80.
      res@tmXBTickEndF    = -5.
      res@tmXBTickSpacingF = 1.
;      res@cnLevels  = (/  -16., -8., -4., -2., -1., 0., 1., 2., 4., 8., 16. /)/100.
      res@cnLevels  = (/  -25., -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20., 25. /)/100.
   end if
   if(csec .eq. "FULL") then
      res@trXMinF = -85
      res@trXMaxF = -12
      res@tmXBTickStartF  = -80.
      res@tmXBTickEndF    = -5.
      res@tmXBTickSpacingF = 5.
;      res@cnLevels  = (/  -16., -8., -4., -2., -1., 0., 1., 2., 4., 8., 16. /)/100.
      res@cnLevels  = (/  -25., -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20., 25. /)/5.
   end if
   if(csec .eq. "Bryden") then
      res@trXMinF = -77
      res@trXMaxF = -70.5
      res@tmXBTickStartF  = -80.
      res@tmXBTickEndF    = -5.
      res@tmXBTickSpacingF = 1.

; for zoom in on western most 1.75 degrees
      res@trXMinF = -77
      res@trXMaxF = -75.25
     res@tmXBTickStartF  = res@trXMinF
      res@tmXBTickEndF    = res@trXMaxF
      res@tmXBTickSpacingF = 1.00
      res@tmXBMinorLengthF = 0.02

;      res@cnLevels  = (/  -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15. /)/100.
      res@cnLevels  = (/  -25., -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20., 25. /)/100.
      res@vpWidthF  = 0.6
      res@vpHeightF = 0.4
   end if
;
   if(csec .eq. "FLC") then
      res@trXMinF = -80.
      res@trXMaxF = -78.8
      res@trYMinF =   0.
      res@trYMaxF = 1000.
      res@tmXBTickStartF  = res@trXMinF
      res@tmXBTickEndF    =  res@trXMaxF
      res@tmXBTickSpacingF = 1.0
      res@tmXBMinorLengthF = 0.02
      res@tmXBMinorPerMajor = 10

;      res@cnLevels  = (/  -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15. /)/100.
      res@cnLevels  = (/   -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20. /)/10.
      res@vpWidthF  = 0.45
      res@vpHeightF = 0.60
   end if
;
   res@gsnYAxisIrregular2Linear = True
   res@cnMissingValFillColor = "gray"
;   res@cnMissingValFillPattern = 1
;
   res@tmXBMode = "Manual"
   res@tmXBLabelAngleF = 45.
   res@tmXBLabelFontHeightF = 0.015
   res@tmXMajorGrid= True
   res@tmXMajorGridLineDashPattern= 2

;
   res@cnLevelSelectionMode = "ExplicitLevels"
   res@cnFillOn = True
   res@cnNoDataLabelOn = False
   res@cnLinesOn = False
   res@cnLineLabelsOn = False
   res@cnInfoLabelOn   = False

   res@gsnLeftString = "G-JRA55, Cycle 5   Yr: " + time4label(np,0) + "  Mon: " + time4label(np,1)
   res@gsnRightString = "ms~S~-1~N~"
;   res@tiMainString= "V-velocity at 16~S~o~N~N, time mean removed " + cres
;   res@tiMainString= "V-velocity at 16~S~o~N~N " + cres
   res@tiXAxisString = "Longitude(deg)"
   res@tiYAxisString = "Depth(m)"

   res@lbLabelBarOn = True
   res@lbOrientation = "Vertical"

   plineres = True
   plineres@gsLineThicknessF = 5.0
   plineres@gsLineColor      = "green"
   plineres@tfPolyDrawOrder  = "postdraw"

   plot(0) = gsn_csm_contour(wks,vvel_shift_at16n(np,:,:),res)      ; contour the variable

   if(csec .eq. "dontplot") then
; fc_minlon - ~eastern edge of topography in LR model at 16 in plot
      plineres@gsLineLabelString = "FC Min"
      pline(0) = gsn_add_polyline(wks, plot(0), (/ -80.3, -80.3 /) , (/ zmin, zmax /), plineres)

;fc_maxlon - From Roberts, Auxilary material all years except 2005/2006 when expanded to -76.5
      plineres@gsLineLabelString = "FC Max"
      pline(1) = gsn_add_polyline(wks, plot(0), (/ -76.75, -76.75 /) , (/ zmin, zmax /), plineres)

;wbw_maxlon - From Roberts, Auxilary material
      plineres@gsLineLabelString = "WBW Max"
      pline(2) = gsn_add_polyline(wks, plot(0), (/ -76.25, -76.25 /) , (/ zmin, zmax /), plineres)

;int_maxlon - ~western edge of topography in LR model at 16N
      plineres@gsLineLabelString = "Int Max"
      pline(3) = gsn_add_polyline(wks, plot(0), (/ -13.0, -13.0 /) , (/ zmin, zmax /), plineres)

;geostrophic reference level - from Roberts
      plineres@gsLineLabelString = "Geo. Ref."
      pline(4) = gsn_add_polyline(wks, plot(0), (/ -85.0, -10.0 /) , (/ 4750., 4750. /), plineres)
;
   end if ; end polyline
;
; markers
   if(csec .ne. "dontplot") then
      pmarkres                    = True
      pmarkres@gsMarkerIndex      = 8           ; polymarker style
      pmarkres@gsMarkerColor      = "black"
      pmarkres@gsMarkerThicknessF = 20.         ; polymarker Thickness
  pmarkres@gsMarkerSizeF      = 20.         ; polymarker size
      pmarkres@gsFillBackgroundColor = "black"
      pmarkres@gsFillIndex           = 1
; Fron Singha et al., 2018 Table C1; Real lon
      xloc_mark = (/ -60.50, -51.50 /)
;
      yloc_mark = (/ 100.0, 100.0 /)
; commenting triangles open (not filled) marker      pmark(0) = gsn_add_polymarker(wks, plot(0), xloc_mark, yloc_mark, pmarkres)

; sharpen the edges
;should be same size as above, is this block of code is used to sharpen edges
      pmarkres@gsMarkerSizeF      = 18.         ; polymarker size
;
      pmarkres@gsMarkerThicknessF = 4.          ; polymarker Thickness
      pmarkres@gsMarkerColor      = "black"
      pmark(1) = gsn_add_polymarker(wks, plot(0), xloc_mark, yloc_mark, pmarkres)
   end if ; end polymarkers
;
   draw(plot)
   frame(wks)
   end do
;
end
