type piece_type
	public:
	dim as integer alive
	dim as int2d position
	dim as ulong tileColor(0 to 3)
	dim as int2d tilePos(0 to 3) 'relative to piecePos
	dim as int2d offsetPos
	dim as integer areaSize
	public:
	declare sub init(shape as integer, allPieces as all_pieces)
	declare sub rotRight()
	declare sub rotLeft()
	declare function getTilePos(tileNum as integer) as int2d
	declare sub disable()
end type

sub piece_type.init(shape as integer, allPieces as all_pieces)
	alive = true
	if shape = -1 then shape = int(rnd * N_SHAPES) 'choose a random one
	for iTile as integer = 0 to 3
		tileColor(iTile) = colors(int(rnd * N_COLORS))
		tilePos(iTile) = allPieces.baseTilePos(shape, iTile)
	next
	offsetPos = allPieces.offsetPos(shape)
	areaSize = allPieces.areaSize(shape)
	position.x = 3 + offsetPos.x 'for placement on a 10 wide board, left alignment
	position.y = -1 + offsetPos.y 'TO BE DEFINED !!!
end sub

sub piece_type.rotRight()
	dim as piece_type clone
	clone = this
	dim as integer tileBound = areaSize - 1
	for i as integer = 0 to 3
		tilePos(i).x = tileBound - clone.tilePos(i).y
		tilePos(i).y = clone.tilePos(i).x
		tileColor(i) = clone.tileColor(i)
	next
end sub

sub piece_type.rotLeft()
	dim as piece_type clone
	clone = this
	dim as integer tileBound = areaSize - 1
	for i as integer = 0 to 3
		tilePos(i).x = clone.tilePos(i).y
		tilePos(i).y = tileBound - clone.tilePos(i).x
		tileColor(i) = clone.tileColor(i)
	next
end sub

function piece_type.getTilePos(tileNum as integer) as int2d
	return position + tilePos(tileNum)
end function

sub piece_type.disable()
	alive = false
end sub

'-------------------------------------------------------------------------------

'~ 'Does not contain the tile positions itself

'~ const as integer NUM_SQUARES = 4
'~ const as integer NUM_ORIENT = 4
'~ const as integer NUM_PIECES = 7
'~ const as integer NUM_COLORS = NUM_PIECES

'~ type piece_type
	'~ dim as int2d p 'grid postion index (central piece position)
	'~ dim as integer id, rot 
	'~ public:
	'~ dim as integer colorIdx(NUM_SQUARES-1)  'color index
	'~ declare sub init(gridPos as int2d, iPiece as integer, iOrient as integer, iColor as integer)
	'~ declare sub disable()
'~ end type

'~ sub piece_type.init(gridPos as int2d, iPiece as integer, iOrient as integer, iColor as integer)
	'~ p.x = gridPos.x
	'~ p.y = gridPos.y
	'~ id  = iif(iPiece = -1, int(rnd * NUM_PIECES), iPiece)
	'~ rot = iif(iOrient = -1, int(rnd * NUM_ORIENT), iOrient)
	'~ for i as integer = 0 to NUM_SQUARES-1
		'~ colorIdx(i) = iif(iColor = -1, int(rnd * NUM_COLORS), iColor)
	'~ next
'~ end sub

'~ sub piece_type.disable
	'~ id = -1
'~ end sub
