#include once "file.bi"
#include once "common.bi"

union rgba_union
	value as ulong
	type
		b as ubyte
		g as ubyte
		r as ubyte
		a as ubyte
	end type
end union

function createPixel(r as ubyte, g as ubyte, b as ubyte) as rgba_union
	dim as rgba_union pixel
	pixel.r = r
	pixel.g = g
	pixel.b = b
	return pixel
end function

type bitmap_header field = 1
	bfType          as ushort
	bfsize          as ulong
	bfReserved1     as ushort
	bfReserved2     as ushort
	bfOffBits       as ulong
	biSize          as ulong
	biWidth         as ulong
	biHeight        as ulong
	biPlanes        as ushort
	biBitCount      as ushort
	biCompression   as ulong
	biSizeImage     as ulong
	biXPelsPerMeter as ulong
	biYPelsPerMeter as ulong
	biClrUsed       as ulong
	biClrImportant  as ulong
end type

type image_type
	dim as any ptr pFbImg
	dim as int2d size, half 
	declare sub create(sizeInit as int2d, colorInit as ulong)
	declare function createFromBmp(fileName as string) as integer
	declare sub destroy()
	declare destructor()
end type

sub image_type.create(sizeInit as int2d, colorInit as ulong)
	pFbImg = imagecreate(sizeInit.x, sizeInit.y, colorInit)
	size = sizeInit
	half.x = size.x \ 2
	half.y = size.y \ 2
	'center = 0
	'method = 0
end sub

function image_type.createFromBmp(fileName as string) as integer
	dim as bitmap_header bmp_header
	dim as int2d bmpSize
	if fileExists(filename) then
		open fileName for binary as #1
			get #1, , bmp_header
		close #1
		bmpSize.x = bmp_header.biWidth
		bmpSize.y = bmp_header.biHeight
		create(bmpSize, &hff000000)
		bload fileName, pFbImg
		print "Bitmap loaded: " & filename
	else
		print "File not found: " & filename
		sleep 1000
		return -1
	end if
	return 0
end function

sub image_type.destroy()
	if (pFbImg <> 0) then
		imagedestroy(pFbImg)
		pFbImg = 0
	end if
end sub

destructor image_type()
	destroy()
end destructor

'===============================================================================

type area_type
	dim as integer x1, y1
	dim as integer x2, y2
end type

function imageGrayInt(pFbImg as any ptr, area as area_type, intOffs as integer) as integer
	dim as integer w, h, bypp, pitch
	dim as integer xi, yi, intensity
	dim as any ptr pPixels
	dim as rgba_union ptr pRow
	if imageinfo(pFbImg, w, h, bypp, pitch, pPixels) <> 0 then return -1
	if bypp <> 4 then return -2 'only 32-bit images
	if pPixels = 0 then return -3
	if area.x1 < 0 or area.x1 >= w then return -4
	if area.y1 < 0 or area.y1 >= h then return -5
	if area.x2 < 0 or area.x2 >= w then return -6
	if area.y2 < 0 or area.y2 >= h then return -7
	for yi = area.y1 to area.y2
		pRow = pPixels + yi * pitch
		for xi = area.x1 to area.x2
			intensity = cint(0.3 * pRow[xi].r + 0.5 * pRow[xi].g + 0.2 * pRow[xi].b) + intOffs
			if intensity < 0 then intensity = 0
			if intensity > 255 then intensity = 255
			pRow[xi].r = intensity
			pRow[xi].g = intensity
			pRow[xi].b = intensity
		next
	next
	return 0
end function
