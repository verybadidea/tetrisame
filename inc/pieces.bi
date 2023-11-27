	'contains all piece tiles in all rotations + unrotated base_piece tiles

const as integer N_SHAPES = 7
const as integer N_COLORS = 4 'N_SHAPES
const as integer N_TILES = 4

const as integer T_I = 0
const as integer T_J = 1
const as integer T_L = 2
const as integer T_O = 3
const as integer T_S = 4
const as integer T_T = 5
const as integer T_Z = 6

dim shared as const ulong colors(N_SHAPES-1) = {_ 'req: N_SHAPES >= N_COLORS
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

'-------------------------------------------------------------------------------

'~ const as integer PIECE_O = 0
'~ const as integer PIECE_I = 1
'~ const as integer PIECE_S = 2
'~ const as integer PIECE_Z = 3
'~ const as integer PIECE_L = 4
'~ const as integer PIECE_J = 5
'~ const as integer PIECE_T = 6

'~ dim shared as const ulong pieceColor(NUM_PIECES-1) = {&h00FFFF00, &h0000FFFF, _
	'~ &h0000FF00, &h00FF0000, &h00FFAA00, &h000000FF, &h009900FF}

'~ dim shared as const ulong pieceColor(NUM_PIECES-1) = {_
	'~ &h00F0F0,_ 'lightblue
	'~ &h0000F0,_ 'blue
	'~ &hF0A100,_ 'orange
	'~ &hF0F000,_ 'yellow
	'~ &h00E000,_ 'green
	'~ &H922B8C,_ 'purple
	'~ &hF00000}  'red

'~ 'Official colors:
'~ ' Yellow O
'~ ' Cyan I
'~ ' Green S
'~ ' Red Z
'~ ' Orange L
'~ ' Blue J
'~ ' Purple T

'~ type pieces_type
	'~ private:
	'~ dim as int2d baseTilePos(NUM_PIECES-1, NUM_SQUARES-1) = _
	'~ {_
		 '~ {(-1,  0), ( 0,  0), (-1, +1), ( 0, +1)}, _ 'O
		 '~ {(-2,  0), (-1,  0), ( 0,  0), (+1,  0)}, _ 'I
		 '~ {( 0,  0), (+1,  0), (-1, +1), ( 0, +1)}, _ 'S
		 '~ {(-1,  0), ( 0,  0), ( 0, +1), (+1, +1)}, _ 'Z
		 '~ {(-1,  0), ( 0,  0), (+1,  0), (-1, +1)}, _ 'L
		 '~ {(-1,  0), ( 0,  0), (+1,  0), (+1, +1)}, _ 'J
		 '~ {(-1,  0), ( 0,  0), (+1,  0), ( 0, +1)}  _ 'T
	'~ }
	'~ dim as int2d tilePos(NUM_PIECES-1, NUM_ORIENT-1, NUM_SQUARES-1)
	'~ dim as integer orientation(NUM_PIECES-1) = {1, 2, 2, 2, 4, 4, 4}
	'~ public:
	'~ 'functions/subs
	'~ declare function rotatedSquare(orientation as integer, p as int2d) as int2d
	'~ declare sub init()
	'~ declare function getSquarePos(iPiece as integer, iOrient as integer, _
		'~ iSquare as integer) as int2d
'~ end type

'~ 'get grid position of 1 square for a specified rotation
'~ function pieces_type.rotatedSquare(orientation as integer, p as int2d) as int2d
	'~ select case orientation
	'~ case 0: return type(+p.x, +p.y)
	'~ case 1: return type(-p.y, +p.x)
	'~ case 2: return type(-p.x, -p.y)
	'~ case 3: return type(+p.y, -p.x)
	'~ end select
'~ end function

'~ 'Fill pieces array for all possibly orientations use base_pieces data
'~ 'Can be converted to constructor
'~ sub pieces_type.init()
	'~ dim as integer iOrient, iPiece, iSquare, iOrientMod
	'~ for iPiece = 0 to NUM_PIECES-1
		'~ for iOrient = 0 to NUM_ORIENT-1
			'~ for iSquare = 0 to NUM_SQUARES-1
				'~ iOrientMod = iOrient mod orientation(iPiece)
				'~ tilePos(iPiece, iOrient, iSquare) = _
				'~ rotatedSquare(iOrientMod, baseTilePos(iPiece, iSquare))
			'~ next
		'~ next
	'~ next
'~ end sub

'~ function pieces_type.getSquarePos(iPiece as integer, iOrient as integer, _
	'~ iSquare as integer) as int2d
	'~ return tilePos(iPiece, iOrient, iSquare)
'~ end function

