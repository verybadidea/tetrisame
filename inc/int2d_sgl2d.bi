type sgl2d_fwd as sgl2d
type int2d_fwd as int2d

type int2d
	dim as integer x, y
	'declare constructor
	'declare constructor(x as integer, y as integer)
	declare operator cast () as string
	'~ declare operator cast () byref as sgl2d_fwd
	'~ declare operator let (v as sgl2d_fwd)
end type

'~ constructor int2d
'~ end constructor

'~ constructor int2d(x as integer, y as integer)
	'~ this.x = x : this.y = y
'~ end constructor

type sgl2d
	dim as single x, y
	declare operator cast () as string
	'~ declare operator cast () byref as int2d_fwd
	'~ declare operator let (v as int2d_fwd)
end type

'-------------------------------------------------------------------------------

operator int2d.cast () as string
	return "(" & str(x) & "," & str(y) & ")"
end operator

'~ operator int2d.cast () byref as sgl2d
	'~ static as sgl2d temp
	'~ temp.x = x
	'~ temp.y = y
	'~ return temp
'~ end operator

'~ operator int2d.let (v as sgl2d)
	'~ x = cint(v.x)
	'~ y = cint(v.y)
'~ end operator

operator = (a as int2d, b as int2d) as boolean
	if a.x <> b.x then return false
	if a.y <> b.y then return false
	return true
end operator

operator + (v1 as int2d, v2 as int2d) as int2d
	return type(v1.x + v2.x, v1.y + v2.y)
end operator

'-------------------------------------------------------------------------------

operator sgl2d.cast () as string
	return "(" & str(x) & "," & str(y) & ")"
end operator

'~ operator sgl2d.cast () byref as int2d
	'~ static as int2d temp
	'~ temp.x = cint(x)
	'~ temp.y = cint(y)
	'~ return temp
'~ end operator

'~ operator sgl2d.let (v as int2d)
	'~ x = v.x
	'~ y = v.y
'~ end operator

operator + (v1 as sgl2d, v2 as sgl2d) as sgl2d
	return type(v1.x + v2.x, v1.y + v2.y)
end operator

operator * (v as sgl2d, mul as single) as sgl2d
	return type(v.x * mul, v.y * mul)
end operator

function distSql(p1 as sgl2d, p2 as sgl2d) as single
	dim as single dx = p1.x - p2.x
	dim as single dy = p1.y - p2.y
	return sqr(dx * dx + dy * dy)
end function 

'-------------------------------------------------------------------------------

function toInt2d(v as sgl2d) as int2d
	return type(int(v.x), int(v.y))
end function

function toCint2d(v as sgl2d) as int2d
	return type(cint(v.x), cint(v.y))
end function

function toSgl2d(v as int2d) as sgl2d
	return type(v.x, v.y)
end function
