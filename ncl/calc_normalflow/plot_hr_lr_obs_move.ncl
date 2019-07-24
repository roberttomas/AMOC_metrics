begin
;====================
; read in LR data
   file_in = "calc_normalflow_move_slice_LR.nc"
   f_in    = addfile(file_in, "r")
;   
   flux_move_sv_lr = f_in->flux_move_sv
   flux_above_move_sv_lr = f_in->flux_above_move_sv
   z_min_lr     = f_in->z_min
   z_max_lr     = f_in->z_max
;
   time_lr      = f_in->time
   time_year_lr = f_in->time_year
   lat_min_lr   = f_in->lat_min
   lon_min_lr   = f_in->lon_min
   lat_max_lr   = f_in->lat_max 
   lon_max_lr   = f_in->lon_max
;====================
; read in HR data
   file_in = "calc_normalflow_move_slice_HR.nc"
   f_in    = addfile(file_in, "r")
;   
   flux_move_sv_hr = f_in->flux_move_sv
   z_min_hr     = f_in->z_min
   z_max_hr     = f_in->z_max
;
   time_hr      = f_in->time
   time_year_hr = f_in->time_year
   lat_min_hr   = f_in->lat_min
   lon_min_hr   = f_in->lon_min
   lat_max_hr   = f_in->lat_max 
   lon_max_hr   = f_in->lon_max
;====================
; read in observations and calculate the monthly average
   file_in = "./transport_move_for_website.csv"
   dummy = asciiread(file_in, -1, "float")
   year  = dummy(25::4)
   month = dummy(26::4)
   day   = dummy(27::4)
   transport = dummy(28::4)
   delete(dummy)
;----------
; create the time coordinate
; make up an hour of  midnight
   hour  = day
   hour  = 0.0
; mintue of 0
   minute = day
   minute = 0.0
; and second of 0
   second = day
   second = 0.0
;
   units = "days since 1900-01-01 00:00:0.0"
;
   time   = cd_inv_calendar(year, month, day, hour, minute, second, units, 0)
   time!0 = "time"
   time&time = time
; to check that the original numbers are returned
   time2  = cd_calendar(time, 3)
   print("start  in: " + year(0) + "0" +  month(0) + day(0) + hour(0) )
   print("start out: " + time2(0) )
   dims = dimsizes(time2)
; check that in = out
   print("end    in: " + year(dims-1) +  "0" + month(dims-1) + "0" + day(dims-1) + hour(dims-1) )
   print("end   out: " + time2(dims-1) )
;----------  
; assign time coordinate and calculate montly averages
   transport!0 = "time"
   transport&time = time
   flux_move_sv_obs  = calculate_monthly_values(transport, "avg", 0, False)
   time_obs = flux_move_sv_obs&time
   time_year_obs = cd_calendar(time_obs, 4)
;======================================================================================================================
; make the plot
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
   res@trYReverse = False
   res@vpWidthF   = 0.6
   res@vpHeightF  = 0.2
;
   res@tiXAxisString = "Year"
   res@tiYAxisString = "Transport(Sv)"
   res@tiMainString = "Ocean Volume Transport Across MOVE Section (16~S~o~N~N, 61~S~o~N~W-51~S~o~N~W)"
   res@tiMainFontHeightF = 0.018
   
;
; add a legend
   res@pmLegendDisplayMode    = "Always"              ; turn on legend
;
   res@pmLegendSide           = "Bottom"                 ; Change location of
   res@pmLegendParallelPosF   =  0.50                 ; move units right
   res@pmLegendOrthogonalPosF =  0.00                 ; more neg = down
;
   res@pmLegendWidthF         = 0.25                  ; Change width and
   res@pmLegendHeightF        = 0.10                  ; height of legend.
   res@lgLabelFontHeightF     = .013                  ; change font height
   res@lgPerimOn              = False                 ; no box around
;
   plot   = new(1, graphic)
;
   res@xyLineThicknesses := (/ 5.0, 5.0, 5.0 /)
   res@xyDashPatterns := (/ 0, 0, 0 /) ;    2, 12
   res@xyLineColors   := (/ "red", "blue", "black" /)
   res@trXMinF = 2000.0
   res@trXMaxF = 2016.25
   res@trYMinF = -36.0
   res@trYMaxF =  0.0
;   res@gsnXRefLine = 0.
;

   sd_hr  = sprintf("%3.1f", dim_stddev(flux_move_sv_hr))
   sd_lr  = sprintf("%3.1f", dim_stddev(flux_move_sv_lr))
   sd_obs = sprintf("%3.1f", dim_stddev(flux_move_sv_obs))

   mn_hr   = sprintf("%5.1f", dim_avg(flux_move_sv_hr))
   mn_lr   = sprintf("%5.1f", dim_avg(flux_move_sv_lr))
   mn_obs  = sprintf("%5.1f", dim_avg(flux_move_sv_obs))

;   sd_hr = decimalPlaces(dim_stddev(flux_move_sv_hr), 1, True)
;   sd_lr = decimalPlaces(dim_stddev(flux_move_sv_lr), 1, True)
;   sd_obs = decimalPlaces(dim_stddev(flux_move_sv_obs), 1, True)
;   mn_hr = decimalPlaces(dim_avg(flux_move_sv_hr), 1, True)
;   mn_lr = decimalPlaces(dim_avg(flux_move_sv_lr), 1, True)
;   mn_obs = decimalPlaces(dim_avg(flux_move_sv_obs), 1, True)

   res@xyExplicitLegendLabels := (/"LR Pop  Mean: " + mn_lr + " SD:" + sd_lr, "HR Pop   Mean:" + mn_hr + " SD:" + sd_hr, "Obs        Mean: " + mn_obs + " SD:" + sd_obs /)
;
; I believe (double check) that forcing year 2000 corresponds to model year 43
; Move data is from move web site
; 
;----------
; low resolution, cycle 5 has the most data so use its size to make plot_data array.
; flux_move_sv_lr: 204     - starts Jan 2000
; flux_move_sv_hr: 120     - starts Jan 2000
; flux_move_sv_obs: 193    - starts Feb 2000
;----------
; create a time coordinate of length dimsizes(flux_move_sv_lr) starting at year 2000
   time_coordinate = time_year_lr
   time_coordinate = time_coordinate + 1750
   plot_data = new( (/3,dimsizes(flux_move_sv_lr)/), "float") ; monthly averaged obs have a time coordinate that
                                                                 ; starts Feb 2000  and  ends  Feb 2016  
                                                                 ; note that the daily data used to make monthly averages
                                                                 ; starts 10 Feb 2000  and  ends 3 Feb 2016
;
   plot_data(0,0:dimsizes(flux_move_sv_lr)-1) = flux_move_sv_lr
   plot_data(1,0:dimsizes(flux_move_sv_hr)-1) = flux_move_sv_hr
   plot_data(2,1:dimsizes(flux_move_sv_obs)-0) = flux_move_sv_obs
;   plot_data(3,0:dimsizes(flux_above_move_sv_lr)-1) = -1.*flux_above_move_sv_lr

   plot  = gsn_csm_xy(wks, time_coordinate,  plot_data, res)         ;
;----------
;
   rho_hr_lr  = escorc(plot_data(0,:), plot_data(1,:))
   rho_lr_obs = escorc(plot_data(0,:), plot_data(2,:))
   rho_hr_obs = escorc(plot_data(1,:), plot_data(2,:))
;   rho_lr_above_lr = escorc(plot_data(0,:), plot_data(3,:))
   print("HR,LR correlation: " + rho_hr_lr )
   print("HR,obs correlation: " + rho_hr_obs )
   print("LR,obs correlation: " + rho_lr_obs )
;   print("LR, above LR correlation: " + rho_lr_above_lr )
   pres = True
   gsn_panel(wks,plot,(/1,1/),pres)             ;
end
