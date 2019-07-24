begin
   file_in = "/gpfs/fs1/p/cgd/oce/projects/JRA55/IAF/g.e20.G.TL319_t13.control.001/ocn/proc/g.e20.G.TL319_t13.control.001.pop.h.000101-006112.MOC.nc"
   f_in    = addfile(file_in, "r")
   time    = f_in->time
   time2   = cd_calendar(time,2)
   print(time2)
end
