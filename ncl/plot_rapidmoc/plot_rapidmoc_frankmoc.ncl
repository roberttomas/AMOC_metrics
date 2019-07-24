begin
;
; RapidMoc data file - hr model
   file_in = "/gpfs/u/home/tomas/amoc_metrics/RapidMoc/test1.0_2009-2010_natl_meridional_transports_at_26N.nc"
;
   f_in = addfile(file_in, "r")
   sf_rapid = dim_avg_n_Wrap(f_in->sf_rapid, 0)
;   printVarSummary(sf_rapid)
   sf_model = dim_avg_n_Wrap(f_in->sf_model, 0)
;   printVarSummary(sf_model)
   depth = f_in->depth
;
; components
   sf_ek     = dim_avg_n_Wrap(f_in->sf_ek, 0);        "Ekman overturning streamfunction."
   sf_geoint = dim_avg_n_Wrap(f_in->sf_geoint, 0);    "Geostrophic interior overturning streamfunction."
   sf_wbw    = dim_avg_n_Wrap(f_in->sf_wbw, 0);       "Western boundary wedge overturning streamfunction."
   sf_fc     = dim_avg_n_Wrap(f_in->sf_fc, 0);        "Florida current overturning streamfunction." ;
   sf_mo     = dim_avg_n_Wrap(f_in->sf_mo, 0);        "Mid ocean overturning streamfunction (sf_mo = sf_wbw + sf_int)." 
;
; POP data file processed by Frank and annually averaged by me
   file_in = "/glade/scratch/tomas/g.e20.G.TL319_t13.control.001_hfreq/ocn/proc/MOC.g.e20.G.TL319_t13.control.001_hfreq.pop.h.0052.nc"
   f_in = addfile(file_in, "r")
;
; float MOC(time, transport_reg, moc_comp, moc_z, lat_aux_grid) ;
;   transport_regions(3) =
;   "Global Ocean",
;   "Atlantic Ocean",
;   "Pacific+Indian Ocean" ;
; moc_comp(1)
;
   moc   = f_in->MOC(0,1,0,:,{26.0})
;   printVarSummary(moc)
   moc_z = f_in->moc_z
   lat_aux_grid = f_in->lat_aux_grid
;======================================================================================================================
   print("Plotting")
   script_name = get_script_prefix_name()
   time_date = systemfunc("date")
   file_out = script_name + ".png"
   wks = gsn_open_wks("png",file_out)
;
   res=True
   res@gsnDraw = False
   res@gsnFrame = False
;
   res@trYReverse = True
   res@vpWidthF   = 0.6
   res@vpHeightF  = 0.6
;
   res@tiMainString  = "Atlantic Overturning at 26N"
   res@tiXAxisString = "Moc(Sv)"
   res@tiYAxisString = "Depth(m)"
;
   plot  = new(1, graphic)
   oplot = new(1, graphic)
   plot_data = new( (/ 4, dimsizes(sf_rapid) /), typeof(sf_rapid) )
   plot_data(0,:) = sf_rapid
   plot_data(1,:) = sf_model
   printVarSummary(plot_data)
   printVarSummary(moc)
   plot_data(2,:) = (/ moc(0:61) /)
   plot_data(3,:) = sf_mo + sf_fc + sf_ek

;
   res@xyLineThicknesses = (/ 3.0, 3.0, 3.0 /)
   res@xyDashPatterns = (/ 0, 0, 0 /)
   res@xyLineColors   = (/ "red", "blue", "black" /)
;
   plot(0) = gsn_xy(wks, plot_data, depth, res)         ; 
   draw(plot)
   frame(wks)
;
end
