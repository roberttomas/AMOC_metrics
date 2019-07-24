;================================================;
;  maponly_17.ncl
;================================================;
;
; Concepts illustrated:
;   - Drawing the Hammer map projection
;   - Drawing the Winkel tripel map projection
;   - Drawing the Aitoff map projection
;
;================================================;
;
; These files are loaded by default in NCL V6.2.0 and newer
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"

;
; Three new map projections were added in V5.1.0:  "Hammer",
; "Aitoff" and "WinkelTripel". In addition, the Mollweide
; projection was improved (see maponly_18.ncl for an example).
;
begin
  wks  = gsn_open_wks("png","maponly")  ; send graphics to PNG file

  colors   = (/"peru","coral","burlywood"/)         ; fill colors for land
  patterns = (/  2,   7,   14  /)                   ; patterns for grid lines

  res                = True               ; plot mods desired
  res@gsnMaximize    = True               ; maximize plot in frame
  
  res@mpGridAndLimbOn        = True        ; turn on lat/lon lines
  res@mpGridLineColor        = "Gray21"    ; line color
  res@mpGridAndLimbDrawOrder = "PreDraw"   ; draw lines first, so
                                           ; filled land is on top
  res@mpPerimOn              = False       ; turn off map perimeter
  res@mpOutlineOn            = True        ; turn on map outlines
  res@mpGeophysicalLineColor = "Gray21"    ; map outline color

  res@mpMaxLatF                   = 35           ; choose a different subregion
  res@mpMinLatF                   = 10
  res@mpMaxLonF                   = -90
  res@mpMinLonF                   = -10

  projections = (/"Mercator","Aitoff","WinkelTripel"/)

  do i=0,dimsizes(projections)-1
    res@mpProjection          = projections(i)   ; projection
    res@mpGridLineDashPattern = patterns(i)      ; grid line pattern
    res@mpLandFillColor       = colors(i)        ; land fill color
    res@tiMainString          = "~F25~" + projections(i) + " Projection"

    map = gsn_csm_map(wks,res)
  end do

end 
