begin
; resolution
   cres = "LR"
; depth (meters)
   nearestz2plot = 1600. ;
;
   if(cres .eq. "HR") then
      file_in = "/glade/work/tomas/RapidMoc/data/g.e20.G.TL319_t13.control.001_hfreq/g.e20.G.TL319_t13.control.001_hfreq.pop.h.UVEL.004301_avg_005212_mod.nc"
      f_in    = addfile(file_in, "r")
;
      ulat = f_in->ULAT
      ulon = f_in->ULONG
;
      uvel = f_in->UVEL(0,{nearestz2plot},:,:)
      uvel@lat2d = ulat
      uvel@lon2d = ulon
;
      z_t_m = f_in->z_t_m
      z_plotted = z_t_m({nearestz2plot})
;      print("z_plotted: " + z_plotted)
;      printVarSummary(uvel)
;
;
      file_in = "/glade/work/tomas/RapidMoc/data/g.e20.G.TL319_t13.control.001_hfreq/g.e20.G.TL319_t13.control.001_hfreq.pop.h.VVEL.004301_avg_005212_mod.nc"
      f_in    = addfile(file_in, "r")
      vvel = f_in->VVEL(0,{nearestz2plot},:,:)
      vvel@lat2d = ulat
      vvel@lon2d = ulon
;      print("HR functionality not installed...")
;      exit
   end if
;
   if(cres .eq. "LR") then
      file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.UVEL.004301_avg_005212_mod.nc"
      f_in    = addfile(file_in, "r")
;
      ulat = f_in->ULAT
      ulon = f_in->ULONG
;
      uvel = f_in->UVEL(0,{nearestz2plot},:,:)
      uvel@lat2d = ulat
      uvel@lon2d = ulon
;
      z_t_m = f_in->z_t_m
      z_plotted = z_t_m({nearestz2plot})
;      print("z_plotted: " + z_plotted)
;      printVarSummary(uvel)
;
;
      file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.VVEL.004301_avg_005212_mod.nc"
      f_in    = addfile(file_in, "r")
      vvel = f_in->VVEL(0,{nearestz2plot},:,:)
      vvel@lat2d = ulat
      vvel@lon2d = ulon
   end if
;
   if(cres .eq. "ASD") then
      file_in = "/glade/work/tomas/RapidMoc/data/hybrid_v5_rel04_BC5_ne120_t12_pop62/hybrid_v5_rel04_BC5_ne120_t12_pop62.pop.h.UVEL.0077_avg_0086_mod.nc"
      f_in    = addfile(file_in, "r")
;
      ulat = f_in->ULAT
      ulon = f_in->ULONG
;
      uvel = f_in->UVEL(0,{nearestz2plot},:,:)
      uvel@lat2d = ulat
      uvel@lon2d = ulon
;
      z_t_m = f_in->z_t_m
      z_plotted = z_t_m({nearestz2plot})
;      print("z_plotted: " + z_plotted)
;      printVarSummary(uvel)
;
;
      file_in = "/glade/work/tomas/RapidMoc/data/hybrid_v5_rel04_BC5_ne120_t12_pop62/hybrid_v5_rel04_BC5_ne120_t12_pop62.pop.h.VVEL.0077_avg_0086_mod.nc"
      f_in    = addfile(file_in, "r")
      vvel = f_in->VVEL(0,{nearestz2plot},:,:)
      vvel@lat2d = ulat
      vvel@lon2d = ulon
   end if
;
;======================================================================================================
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + "_" + nearestz2plot + "m_" + cres + ".png"
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
;
   res@tmXBMode = "Manual"
   res@tmXBTickStartF  = -80. 
   res@tmXBTickEndF    = -5.
   res@tmXBLabelAngleF = 45.
   res@tmXBTickSpacingF = 5. ; 1.
   res@tmXBMinorLengthF = 0.
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
   res@cnLevels  = (/  -16., -8., -4., -2., -1., 0., 1., 2., 4., 8., 16. /)/100.

   res@gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   res@gsnRightString = "ms~S~-1~N~"
   res@tiMainString= "V-velocity at 26.5~S~o~N~N, " + cres
   res@tiXAxisString = "Longitude(deg)"
   res@tiYAxisString = "Depth(m)"

   res@lbLabelBarOn = False
;   res@lbLabelvertical = "Right"
; 
   vcres                         = True             ; plot mods desired
   vcres@gsnFrame                = False            ; so we can draw time stamp
   vcres@gsnDraw = False
;   
   vcres@vcRefAnnoOrthogonalPosF = -1.0             ; move ref vector up
   vcres@vcRefLengthF            = 0.05             ; define length of vec ref
   vcres@vcMinDistanceF          = 0.017
   vcres@vcLineArrowThicknessF   = 3
;
   vcres@vcRefMagnitudeF         = 0.10             ; define vector ref mag
;   if( nearestz2plot .ge. 1000.) then
;      vcres@vcRefMagnitudeF      = 0.10             ; define vector ref mag
;   end if
;
;
   vcres@gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   vcres@gsnRightString = "ms~S~-1~N~"
   vcres@tiMainString= "Velocity at " + z_plotted + "m," + " " + cres
;
;   vcres@mpMinLonF            = -95.               ; select a subregion
;   vcres@mpMaxLonF            = -60.
;   vcres@mpMinLatF            =  10. 
;   vcres@mpMaxLatF            =  35.

   vcres@mpMinLonF            = -70.               ; select a subregion
   vcres@mpMaxLonF            = -50.
   vcres@mpMinLatF            =  10. 
   vcres@mpMaxLatF            =  25.



   plineres = True
   plineres@gsLineThicknessF = 5.0
   plineres@gsLineColor      = "green"
   plineres@tfPolyDrawOrder  = "postdraw"

;   plot(0) = gsn_csm_streamline_map_ce(wks,uvel,vvel,vcres)      ; contour the variable
   plot(0) = gsn_csm_vector_map(wks,uvel,vvel,vcres)      ; contour the variable

; fc_minlon - ~eastern edge of topography in LR model at 26.5N in plot
   plineres@gsLineLabelString = ""
   pline(0) = gsn_add_polyline(wks, plot(0), (/ vcres@mpMinLonF, vcres@mpMaxLonF /) , (/ 16.0, 16.0 /), plineres)

if(0 .eq. 1) then
; markers
   pmarkres                    = True
   pmarkres@gsMarkerIndex      = 8           ; polymarker style
   pmarkres@gsMarkerColor      = "black"
   pmarkres@gsMarkerThicknessF = 20.         ; polymarker Thickness
   pmarkres@gsMarkerSizeF      = 20.         ; polymarker size
   pmarkres@gsFillBackgroundColor = "black"
   pmarkres@gsFillIndex           = 1
   xloc_mark = (/ -76.74, -49.75, -41.09, -21.27, -15.42, -14.21, -13.75, -13.54 /)
   yloc_mark = (/ 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0 /)
   pmark(0) = gsn_add_polymarker(wks, plot(0), xloc_mark, yloc_mark, pmarkres)

; sharpen the edges
   pmarkres@gsMarkerThicknessF = 5.          ; polymarker Thickness
   pmarkres@gsMarkerColor      = "black"
   pmarkres@gsMarkerSizeF      = 41.         ; polymarker size
   pmark(1) = gsn_add_polymarker(wks, plot(0), xloc_mark, yloc_mark, pmarkres)
;
end if
   draw(plot)
   frame(wks)

;
end

