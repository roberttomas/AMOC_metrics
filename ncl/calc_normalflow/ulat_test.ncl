begin
   file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.004301_avg_005212.nc"
   f_in    = addfile(file_in, "r")
;
   ulat = f_in->ULAT
   ulon = f_in->ULONG
;Variable: ulat
;Type: double
;Total Size: 983040 bytes
;            122880 values
;Number of Dimensions: 2
;Dimensions and sizes:    [nlat | 384] x [nlon | 320]
;Coordinates:
;Number Of Attributes: 4
;  long_name :    array of u-grid latitudes
   dims = dimsizes(ulat)
   nlat = dims(0)
   nlon = dims(1)
   delete(dims)
;
   ulatjp1 = ulat
   do nj = 0, nlat - 2
      ulatjp1(nj,:) = ulat(nj+1,:)
   end do
   ulatjp1(nlat-1,:) = ulatjp1@_FillValue
;
   ulatjm1 = ulat
   do nj = 1, nlat - 1
      ulatjm1(nj,:) = ulat(nj-1,:)
   end do
   ulatjm1(0,:) = ulatjm1@_FillValue
;
   ulatn = ulat
   ulatn = (ulatjp1 + ulat)/2.
   ulats = ulat
   ulats = (ulatjm1 + ulat)/2.
   printVarSummary(ulatn)
;
;
   locs = ulat
   locs = where( 26.5 .ge. ulats .and.  26.5 .le. ulatn, locs, locs@_FillValue)
   locs = where(ulon .ge. 280.  .and. ulon .le. 350., locs, locs@_FillValue)
;
   system("rm junk.nc")
   f_out = addfile("junk.nc","c")
   f_out->ulatn=ulatn
   f_out->ulats=ulats
   f_out->locs=locs
   
;
end
