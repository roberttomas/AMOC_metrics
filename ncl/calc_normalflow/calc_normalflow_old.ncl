;------------------------------------------------------------------------------------------------------------------------
; 13 June 2019
; This code is an exploratory effort to reproduce some of the Roberts code calculations in an ncl framework, written by me.
;
; For now, I'm just working with the LR decadal mean history file.
; I have decadal mean single variable files for the HR case on /glade/work/tomas for later.
; I'm not using the modified data that I fed into the Roberts code because some of the grid variables were not in the files
;
; I started this code by copying /gpfs/u/home/tomas/amoc_metrics/ncl/plot_26N_cross_section/plot_26N_cross_section.ncl   
;           to calc_normalflow.ncl
;------------------------------------------------------------------------------------------------------------------------
begin
; resolution
   cres = "LR"
   csec = "FULL" ; WEST or FULL or Bryden or FLC
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
      file_in = "/glade/work/tomas/RapidMoc/data/g20a10.GIAF_JRA.gx1v7.C03/g20a10.GIAF_JRA.gx1v7.C03.pop.h.004301_avg_005212.nc"
; from: /gpfs/u/home/tomas/amoc_metrics/RapidMoc/etc/config.ini.pop1_mod
      imin = 87; 87, 88
      imax = 150; 148
      jmin = 271; 271
      jmax = 271; 271
      gsnLeftString = "G-JRA55; Yrs. 2000-2009, Cycle 1"
   end if
   f_in    = addfile(file_in, "r")
;
   ulat = f_in->ULAT
; remove latitude dimension (if 1) or average over latitudes and remove dimension
   ulon = f_in->ULONG
   dxu  = f_in->DXU
;
; remove time dimension with leading zero dimension followed by colons
   vvel = f_in->VVEL(0,:,:,:)
;   vvel!1 = "Longitude"
;   vvel&Longitude = ulon
;   printVarSummary(vvel)
;
   z_t = f_in->z_t
   dz = f_in->dz
   dzmin = dz(0)
   dzmax = dz(dimsizes(dz)-1)
;   print("dzmin: " + dzmin + " dzmax: " + dzmax)
;
;   system("rm junk.nc")
;   f_out = addfile("junk.nc","c")
;   f_out->VVEL = vvel
;   printVarSummary(vvel)
;   printVarSummary(dxu)
;   printVarSummary(dz)
;   exit
; This is a quick and dirty calculation.  I have not checked to make sure the indexing is correct; I think it
; could be off by a little in the x and/or y directtion. That is, vvel and dxu do not line up properly
   print("Indexing of vvel, dxu, dz is at least close; need to verify that they are correct")
   flow = vvel
   flow = (/ doubletofloat(vvel * conform(vvel, dxu, (/1,2/)) * conform(vvel, dz, 0)) /)
   flow@long_name = "flow"
   flow@units     = "cm^3/s"
;   flow = where( fabs(flow ) .gt. 9.e36, flow@_FillValue, flow)
;   printVarSummary(flow)
;
;---------------------------------------------------------------------------------------------------------------------------------------
; shift so that 0 degrees longitude is ~in the middle for most of the grid and have longitudes increase monotonically, left to rignt and
; range between -180 to 180
;
;----------
; initialize some indicies
;----------
   imaxgrid = 320
   ipivot = 194  ; for ULONG
;   ipivot = 195 ; for TLONG
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
;----------
; shift data array
;----------
;
   flow_shift = flow
   flow_shift(:,:,imaxgrid-ipivot-1:imaxgrid-1) = flow(:,:,0:ipivot)
   flow_shift(:,:,0:imaxgrid-ipivot-2)      = flow(:,:,ipivot+1:imaxgrid-1)
;
; average in latitude and/or remove the 1 dimenstion
   flow_section = dim_avg_n_Wrap(flow_shift(:,jmin:jmax,imin:imax), 1 )
;
; or interpolate in latitutde to 26.5N
   dims = dimsizes(flow)
   flow_shift_at26n = new((/dims(0),dims(2)/), typeof(flow_shift) )
   delete(dims)
;   printVarSummary(flow_shift_at26n) ; 60 x 320
   latval = 26.27356
   do ni = 0, imaxgrid - 1
      xin = ulat_shift(:,ni)
      flow_shift_at26n(:,ni) = linint1(xin(0:339), flow_shift(:,0:339,ni), False, latval, 0) 
   end do
;
   flow_section = flow_shift_at26n(:,imin:imax)
;
;   system("rm junk.nc")
;   f_out = addfile("junk.nc","c")
;   f_out->flow_section=flow_section
;   exit
   zzz = dim_sum_n(flow_section,1)
;   printVarSummary(zzz)
; multiply -1 and integrate over depth, bottom to top
   sf = -1.*zzz
   do nz = dimsizes(dz) - 2, 1, 1
      sf(nz) = sf(nz+1) +  sf(nz)
   end do
   system("rm junk.nc")
   f_out = addfile("junk.nc","c")
   f_out->sf=sf
; 
   print("ulon_shift(jmin,imin): " + ulon_shift(jmin,imin) + "  ulon_shift(jmin,imax): " + ulon_shift(jmin,imax) )
   print("ulat_shift(jmin,imin): " + ulat_shift(jmin,imin) + "  ulat_shift(jmax,imax): " + ulat_shift(jmax,imax) )
;
;======================================================================================================
end
