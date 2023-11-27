#include "block_collection.bi"

type bcl_type 'block (collection) list class
	public:
	dim as bc_type bc(any)
	public:
	declare function getSize() as integer
	declare function getUsed() as integer
	declare function alloc() as integer
	declare function free() as integer
	'declare function free(index as integer) as integer
	declare sub show()
	declare function update(board as board_type) as integer
	'~ declare sub changeDrop(vSpeed as single)
	declare sub drawBlocks(board as board_type)
end type

function bcl_type.getSize() as integer
	return ubound(bc) + 1
end function

function bcl_type.getUsed() as integer
	dim as integer count = 0 
	for i as integer = 0 to ubound(bc)
		if bc(i).inUse = true then count += 1
	next
	return count
end function

function bcl_type.alloc() as integer
	dim as integer index = -1
	dim as integer ub = ubound(bc)
	for i as integer = 0 to ub
		if bc(i).inUse = false then
			index = i
			exit for
		end if
	next
	if index < 0 then
		redim preserve bc(ub + 1)
		index = ub + 1
	end if
	bc(index).inUse = true
	return index
end function

function bcl_type.free() as integer
	for i as integer = 0 to ubound(bc)
		bc(i).cleanUp()
	next
	return 0
end function

sub bcl_type.show()
	for i as integer = 0 to ubound(bc)
		print "list index: " & str(i)
		'bc(i).show()
		print
	next
end sub

'update position of block sections
'copy to board if next position not possible
function bcl_type.update(board as board_type) as integer
	dim as integer blUpdate = 0
	for iBc as integer = 0 to getSize()-1
		'update position
		with bc(iBc)
			if .inUse then
				.relPos.y += 1 'move down
				'check further drop possible
				if .possible(.relPos + type(0, 1), board) then
					'nothing, chack next update again
				else
					.copyToBoard(.relPos, board)
					.cleanUp() 'remove from list
					blUpdate = 1
				end if
			end if
		end with
	next
	return blUpdate
end function

'draw all alive block collections on board
sub bcl_type.drawBlocks(board as board_type)
	for iBc as integer = 0 to getSize()-1
		if bc(iBc).inUse = true then
			for iBlock as integer = 0 to bc(iBc).getSize() - 1
				dim as int2d blockPos = bc(iBc).getAbsPosBlocks(iBlock)
				dim as tile_type tile = bc(iBc).getBlock(iBlock)
				board.drawTilePos(blockPos, tile)
			next
		end if
	next
end sub


'~ function bcl_type.update(board as board_type) as integer
	'~ dim as integer blUpdate = 0
	'~ for iBc as integer = 0 to getSize()-1
		'~ 'update position
		'~ with bc(iBc)
			'~ 'check if target reached --> Now, move 1 step!!!
			'~ if .update() = 1 then '<-- always true now? -------- MOVE CURRENT 1 DOWN -----------
				'~ 'clear reservation
				'~ '.copyToBoard(.relPosCurrent, BLOCK_FREE, board) RESERVERING 1 tE lAAG wordt VREWIJDERD?
				'~ 'set next target
				'~ .extendTarget()
				'~ 'check next pos. possible
				'~ if .possible(.relPosTarget, board) then
					'~ 'set new reservation
					'~ .copyToBoard(.relPosTarget, BLOCK_RES, board) 
				'~ else
					'~ .copyToBoard(.relPosCurrent, BLOCK_PIECE, board)
					'~ .cleanUp() 'remove from list
					'~ blUpdate = 1
				'~ end if
			'~ end if
		'~ end with
	'~ next
	'~ return blUpdate
'~ end function

'~ sub bcl_type.changeDrop(vSpeed as single)
	'~ for iBc as integer = 0 to getSize()-1
		'~ with bc(iBc)
			'~ if .inUse = true then
				'~ 'check, only block collections dropping down
				'~ if .speed.x = 0 and .speed.y > 0 then
					'~ .speed.y = vSpeed
				'~ end if
			'~ end if
		'~ end with
	'~ next
'~ end sub
