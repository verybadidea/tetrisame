const as ulong C_BLACK = &h00000000
const as ulong C_DARK_GRAY = &h00404040
const as ulong C_GRAY = &h00808080
const as ulong C_LIGHT_GRAY = &h00C0C0C0
const as ulong C_WHITE = &h00F0F0F0
const as ulong C_RED = &h00F04040
const as ulong C_DARK_RED = &h00A02020
const as ulong C_YELLOW = &h00F0F000

'clockwise like in pieces class
const as integer DIR_DN = 0
const as integer DIR_LE = 1
const as integer DIR_UP = 2
const as integer DIR_RI = 3

sub panic(text as string)
	screenunlock()
	print "Panic: " & text
	getkey()
	end -1
end sub

sub imageKill(p_img as any ptr)
	imageDestroy(p_img)
	p_img = 0
end sub

function inRange(value as integer, min as integer, max as integer) as integer
	if value >= min and value <= max then
		return true
	else
		return false
	end if
end function

'~ type int2d
	'~ dim as integer x, y
'~ end type

'~ operator + (v1 as int2d, v2 as int2d) as int2d
	'~ return type(v1.x + v2.x, v1.y + v2.y)
'~ end operator

const as ushort KEY_UP = &h48FF
const as ushort KEY_RI = &h4DFF
const as ushort KEY_DN = &h50FF
const as ushort KEY_LE = &h4BFF
const as ushort KEY_W = &h77
const as ushort KEY_A = &h61
const as ushort KEY_S = &h73
const as ushort KEY_D = &h64
'const as ushort KEY_P = &h50
const as ushort KEY_P = &h70
const as ushort KEY_ENTER = &h0D
const as ushort KEY_ESC = &h1B
const as ushort KEY_TAB = &h09
const as ushort KEY_BACK = &h08
const as ushort KEY_SPACE = &h20

function waitKeyCode() as ushort
	return getkey() 'getkey is weird
end function

function pollKeyCode() as ushort
	dim as string key = inkey()
	if (key = "") then return 0
	if (key[0] = 255) then
		return *cast(ushort ptr, strptr(key))
		'return (key[1] shl 8) or key[0]
	else
		return key[0]
	end if
end function
