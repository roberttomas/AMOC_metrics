begin
;----------
   file_in = "./transport_move_for_website.csv"
   dummy = asciiread(file_in, -1, "float")
   year  = dummy(25::4)
   month = dummy(26::4)
   day   = dummy(27::4)
   transport = dummy(28::4)
   delete(dummy)
;----------
; make up an hour of midnight
   hour  = day
   hour  = 00.0
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
   time2  = cd_calendar(time, 0)
   print(time2)
   print("start  in: " + year(0) + " " +  month(0) + " " + day(0) + " " + hour(0) )
   print("start out: " + time2(0,0) + " " + time2(0,1) + " " + time2(0,2) + " " + time2(0,3) )
   print("")

   dims = dimsizes(time)
   print("end    in: " + year(dims-1) +  " " + month(dims-1) + " " + day(dims-1) + " " + hour(dims-1) )
   print("end   out: " + time2(dims-1,0) + " " + time2(dims-1,1) + " " + time2(dims-1,2) + " " + time2(dims-1,3) )
   
;
   transport!0 = "time"
   transport&time = time
   monthly_transport = calculate_monthly_values(transport, "avg", 0, False)
   monthly_time = monthly_transport&time
   tt = cd_calendar(monthly_time, 2)
;   print(tt)
;----------
end
