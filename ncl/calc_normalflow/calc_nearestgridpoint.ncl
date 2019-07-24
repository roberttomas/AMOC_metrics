begin
   lat_loc =  16.0
   lon_loc = -15.0
   l_mod = True
;
; use for original pop grids that have not been modified to put the GM near the middle of the domain
   if(.not. l_mod) then
      if(lon_loc .lt. 0) then
         lon_loc = lon_loc + 360.
      end if
   end if
;----------
; LR
   file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.UVEL.004301_avg_005212_mod.nc"
;----------
; HR
;   file_in = "/glade/work/tomas/RapidMoc/data/g.e20.G.TL319_t13.control.001_hfreq/g.e20.G.TL319_t13.control.001_hfreq.pop.h.UVEL.004301_avg_005212_mod.nc"
   f_in    = addfile(file_in, "r")
;----------
;
   ulat = f_in->ULAT
   ulon = f_in->ULONG
;
   dist_array = sqrt ( (ulat - lat_loc)^2 + (ulon - lon_loc)^2 )
   dims = dimsizes(dist_array)
;
   oned_dist_array = ndtooned(dist_array)
   oned_min_loc = minind(oned_dist_array)
   indices_min_loc = ind_resolve(oned_min_loc,dims)
   min_lat = ulat(indices_min_loc(0,0), indices_min_loc(0,1))
   min_lon = ulon(indices_min_loc(0,0), indices_min_loc(0,1))
;
   if(.not. l_mod) then
      if(min_lon .gt. 180.) then
         min_lon = min_lon - 360.
      end if
   end if
;   
   print("this is from a file modified to put the GM near the middle of the domain")
   print("min_loc:  j: " + indices_min_loc(0,0) + ", i: " + indices_min_loc(0,1))
   print("min_loc:  lat: " + min_lat + ", lon: " + min_lon)
;
end
