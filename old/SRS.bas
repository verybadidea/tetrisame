type int2d
	dim as integer x, y
end type

type sgl2d
	dim as single x, y
end type

const as integer N_SHAPES = 7
const as integer N_COLORS = N_SHAPES
const as integer N_TILES = 4

const as integer T_I = 0
const as integer T_J = 1
const as integer T_L = 2
const as integer T_O = 3
const as integer T_S = 4
const as integer T_T = 5
const as integer T_Z = 6

'-------------------------------------------------------------------------------

dim shared as const ulong colors(N_COLORS-1) = {_
	&h00F0F0,_ 'lightblue
	&h0000F0,_ 'blue
	&hF0A000,_ 'orange
	&hF0F000,_ 'yellow
	&h00F000,_ 'green
	&HA000F0,_ 'purple
	&hF00000}  'red

type all_pieces
	dim as int2d baseTilePos(N_SHAPES-1, N_TILES-1) = _
	{_
		 {( 0, 1), ( 1, 1), ( 2, 1), ( 3, 1)}, _ 'I
		 {( 0, 0), ( 0, 1), ( 1, 1), ( 2, 1)}, _ 'J
		 {( 2, 0), ( 0, 1), ( 1, 1), ( 2, 1)}, _ 'L
		 {( 0, 0), ( 0, 1), ( 1, 0), ( 1, 1)}, _ 'O
		 {( 1, 0), ( 2, 0), ( 0, 1), ( 1, 1)}, _ 'S
		 {( 1, 0), ( 0, 1), ( 1, 1), ( 2, 1)}, _ 'T
		 {( 0, 0), ( 1, 0), ( 1, 1), ( 2, 1)}  _ 'Z
	}
	dim as int2d offsetPos(N_SHAPES-1) = _
		{( 0, 0), ( 0, 0), ( 0, 0), ( 1, 0), ( 0, 0), ( 0, 0), ( 0, 0)}
	dim as integer areaSize(N_SHAPES-1) = _
		{4, 3, 3, 2, 3, 3, 3}
end type

type piece_type
	dim as ulong tileColor(0 to 3)
	dim as int2d tilePos(0 to 3)
	dim as int2d offsetPos
	dim as integer areaSize
	declare sub init(shape as integer, allPieces as all_pieces)
	declare sub rotRight()
end type

sub piece_type.init(shape as integer, allPieces as all_pieces)
	if shape = -1 then shape = int(rnd * N_SHAPES) 'choose a random one
	for iTile as integer = 0 to 3
		tileColor(iTile) = colors(int(rnd * N_COLORS))
		tilePos(iTile) = allPieces.baseTilePos(shape, iTile)
	next
	offsetPos = allPieces.offsetPos(shape)
	areaSize = allPieces.areaSize(shape)
end sub

sub piece_type.rotRight()
	dim as piece_type clone
	'fb_memcopy(clone, this, sizeof(piece_type))
	clone = this
	dim as integer tileBound = areaSize - 1
	for i as integer = 0 to 3
		tilePos(i).x = tileBound - clone.tilePos(i).y
		tilePos(i).y = clone.tilePos(i).x
		tileColor(i) = clone.tileColor(i)
	next
end sub

dim as all_pieces allPieces
dim as piece_type piece

screenres 800,600,32

const as integer SZ = 16

randomize timer
for iPiece as integer = 0 to N_SHAPES-1
	piece.init(iPiece, allPieces)

	for iOrient as integer = 0 to 3
		dim as integer xOffset = 30 + SZ * 5 * iOrient
		dim as integer yOffset = 30 + SZ * 5 * iPiece
		'show grid
		for xi as integer = 0 to 3 'piece.tileSize-1
			for yi as integer = 0 to 3 'piece.tileSize-1
				dim as integer x = xOffset + xi * SZ
				dim as integer y = yOffset + yi * SZ
				line(x, y)-step(SZ-2, SZ-2), &h404040, b
			next
		next
		'show piece
		for i as integer = 0 to 3
			dim as integer x = xOffset + (piece.offsetPos.x + piece.tilePos(i).x) * SZ
			dim as integer y = yOffset + (piece.offsetPos.y + piece.tilePos(i).y) * SZ
			line(x, y)-step(SZ-2, SZ-2), piece.tileColor(i), bf
		next
		'
		piece.rotRight()
	next
next

getkey()
