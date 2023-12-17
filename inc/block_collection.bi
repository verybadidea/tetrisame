type bd_type 'block descriptor
	dim as int2d relPos
	dim as tile_type block
end type

'-------------------------------------------------------------------------------

type bc_type 'block collection class
	public:
	dim as boolean inUse
	dim as int2d relPos 'relative to absPosSource
	dim as bd_type bd(any) 'positions relative to relPosCurrent 
	dim as int2d absPosSource 'initial position ??????????????????????????????????
	public:
	declare function getSize() as integer
	'declare sub setSpeed(speed as sgl2d)
	declare sub cleanUp()
	declare sub addBlock(blockPos as int2d, block as tile_type)
	declare function getAbsPosBlocks(blockNum as integer) as int2d
	declare function getBlock(blockNum as integer) as tile_type
	'declare function update() as integer
	'declare sub copyToBoard(relPos as int2d, blockType as TILE_T, board as board_type)
	declare sub copyToBoard(relPos as int2d, board as board_type)
	declare function possible(checkPos as int2d, board as board_type) as boolean
	'declare sub extendTarget()
end type

function bc_type.getSize() as integer
	return ubound(bd) + 1
end function

sub bc_type.cleanUp()
	inUse = false
	erase bd
	relPos = type(0, 0)
	absPosSource = type(0, 0)
end sub

sub bc_type.addBlock(blockPos as int2d, block as tile_type)
	dim as integer ub = ubound(bd)
	redim preserve bd(ub + 1)
	bd(ub + 1).relPos = blockPos
	bd(ub + 1).block = block
end sub

function bc_type.getAbsPosBlocks(blockNum as integer) as int2d
	dim as int2d blockPos
	if blockNum >= 0 and blockNum <= ubound(bd) then
		blockPos = relPos + absPosSource + bd(blockNum).relPos
	end if
	return blockPos
end function

function bc_type.getBlock(blockNum as integer) as tile_type
	if blockNum >= 0 and blockNum <= ubound(bd) then
		return bd(blockNum).block
	end if
	return type(BLOCK_INVALID, -1)
end function

'updates position of block collection
'return 1 on target position reached <-- IS REMOVED NOW
'~ function bc_type.update() as integer
	'~ if inUse = true then
		'~ relPosCurrent.y += 1
		'~ return 1
	'~ end if
	'~ return 0
'~ end function

'IS NIET GOED, moet ook tColor kopieren! ???
sub bc_type.copyToBoard(relPos as int2d, board as board_type)
	dim as int2d blockPos
	for iBlock as integer = 0 to ubound(bd)
		blockPos = relPos + absPosSource + bd(iBlock).relPos
		board.setTile(blockPos.x, blockPos.y, bd(iBlock).block)
	next
end sub

'~ sub bc_type.copyToBoard(relPos as int2d, blockType as TILE_T, board as board_type)
	'~ dim as int2d blockPos
	'~ for iBlock as integer = 0 to ubound(bd)
		'~ 'blockPos = relPos + toSgl2d(absPosSource + bd(iBlock).relPos)
		'~ blockPos = relPos + absPosSource + bd(iBlock).relPos
		'~ if blockType = BLOCK_FREE or blockType = BLOCK_RES then
			'~ 'board.setType(toCint2d(blockPos), blockType)
			'~ board.setTileType(blockPos.x, blockPos.y, blockType)
		'~ elseif blockType = BLOCK_PIECE then
			'~ 'board.setBlock(toCint2d(blockPos), bd(iBlock).block)
			'~ board.setTile(blockPos.x, blockPos.y, bd(iBlock).block)
		'~ end if
	'~ next
'~ end sub

function bc_type.possible(checkPos as int2d, board as board_type) as boolean
	dim as int2d blockPos
	dim as TILE_T blockType
	for iBlock as integer = 0 to ubound(bd)
		blockPos = checkPos + absPosSource + bd(iBlock).relPos
		blockType = board.getTileType(blockPos.x, blockPos.y)
		if blockType <> BLOCK_FREE then return false
	next
	return true
end function

'~ sub bc_type.extendTarget()
	'~ if inUse = true then
		'~ relPosTarget.y += 1
	'~ end if
'~ end sub
