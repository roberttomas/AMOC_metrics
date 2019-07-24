begin
; resolution
   cres = "HR"
   csec = "WEST" ; WEST or FULL or Bryden or FLC
;
   if( (csec .ne. "WEST") .and.  (csec .ne. "FULL") .and. (csec .ne. "Bryden") .and. (csec .ne. "FLC") ) then
      print("csec not set to valid value: " + csec)
      exit
   end if
;
   if(cres .eq. "HR") then
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
      file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.VVEL.004301_avg_005212_mod.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_mod
      imin = 80; 88
      imax = 150; 148
      jmin = 271
      jmax = 271
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
   f_in    = addfile(file_in, "r")
;
   ulat = f_in->ULAT(jmin:jmax,imin:imax)
   ulon = dim_avg_n_Wrap(f_in->ULONG(jmin:jmax,imin:imax), 0)
;   print( ulon )
;
; remove latitude dimension (if 1) or average over latitudes and remove dimension
   vvel = dim_avg_n_Wrap(f_in->VVEL(0,:,jmin:jmax,imin:imax), 1)
   vvel!1 = "Longitude"
   vvel&Longitude = ulon
;   printVarSummary(vvel)
;
   z_t_m = f_in->z_t_m
   zmin = z_t_m(0)
   zmax = z_t_m(dimsizes(z_t_m)-1)
   print("zmin: " + zmin + " zmax: " + zmax)
   
;
   system("rm junk.nc")
   f_out = addfile("junk.nc","c")
   f_out->VVEL = vvel
;======================================================================================================
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + "_" + csec + "_" + cres + ".png"
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
      res@trXMinF = -81
      res@trXMaxF = -70.0; -76
      res@tmXBTickStartF  = -80. 
      res@tmXBTickEndF    = -5.
      res@tmXBTickSpacingF = 1.
      res@tmXBMinorLengthF = 0.02
      res@tmXBMinorPerMajor = 9  
;      res@cnLevels  = (/  -16., -8., -4., -2., -1., 0., 1., 2., 4., 8., 16. /)/100.
      res@cnLevels  = (/  -25., -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20., 25. /)/100.
   end if
   if(csec .eq. "FULL") then
      res@trXMinF = -81
      res@trXMaxF = -12
      res@tmXBTickStartF  = -80. 
      res@tmXBTickEndF    = -5.
      res@tmXBTickSpacingF = 5.
;      res@cnLevels  = (/  -16., -8., -4., -2., -1., 0., 1., 2., 4., 8., 16. /)/100.
      res@cnLevels  = (/  -25., -20., -15., -10., -5., -2., -1., 0., 1., 2., 5., 10., 15., 20., 25. /)/100.
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
      res@tmXBMinorPerMajor = 9  

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

   res@gsnRightString = "ms~S~-1~N~"
   res@gsnLeftString = gsnLeftString
   res@tiMainString= "V-velocity at 26.5~S~o~N~N, " + cres
   res@tiXAxisString = "Longitude(deg)"
   res@tiYAxisString = "Depth(m)"

   res@lbLabelBarOn = True
   res@lbOrientation = "Vertical"

   plineres = True
   plineres@gsLineThicknessF = 5.0
   plineres@gsLineColor      = "green"
   plineres@tfPolyDrawOrder  = "postdraw"

   plot(0) = gsn_csm_contour(wks,vvel,res)      ; contour the variable

   if(csec .eq. "dontplot") then
; fc_minlon - ~eastern edge of topography in LR model at 26.5N in plot
      plineres@gsLineLabelString = "FC Min"
      pline(0) = gsn_add_polyline(wks, plot(0), (/ -80.3, -80.3 /) , (/ zmin, zmax /), plineres)

;fc_maxlon - From Roberts, Auxilary material?
      plineres@gsLineLabelString = "FC Max"
      pline(1) = gsn_add_polyline(wks, plot(0), (/ -77.20, -77.20 /) , (/ zmin, zmax /), plineres)

;wbw_maxlon - From Roberts, Auxilary material, all years except 2005/2006 when expanded to -76.5
      plineres@gsLineLabelString = "WBW Max"
      pline(2) = gsn_add_polyline(wks, plot(0), (/ -76.75, -76.75 /) , (/ zmin, zmax /), plineres)

;int_maxlon - ~western edge of topography in LR model at 26.5N
      plineres@gsLineLabelString = "Int Max"
      pline(3) = gsn_add_polyline(wks, plot(0), (/ -13.0, -13.0 /) , (/ zmin, zmax /), plineres)

;geostrophic reference level - from Roberts
      plineres@gsLineLabelString = "Geo. Ref."
      pline(4) = gsn_add_polyline(wks, plot(0), (/ -81.0, -10.0 /) , (/ 4750., 4750. /), plineres)
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
      xloc_mark = (/ -76.74, -49.75, -41.09, -21.27, -15.42, -14.21, -13.75, -13.54 /)
; 
      yloc_mark = (/ 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0 /)
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
;
end

