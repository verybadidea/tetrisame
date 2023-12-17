type timer_type
	private:
	dim as double tEnd
	dim as double tStart
	dim as double tSpan
	dim as integer active
	public:
	declare sub start(duration as double)
	declare function inactive() as boolean
	declare function ended() as boolean
	declare sub restart()
	declare sub pause()
	declare sub unpause()
end type

sub timer_type.start(duration as double)
	tStart = timer()
	tSpan = duration
	tEnd = tStart + tSpan
	active = 1
end sub

'does NOT update the timer status
function timer_type.inactive() as boolean
	if active = 0 then return true
end function

function timer_type.ended() as boolean
	if active = 0 then return false
	if timer() >= tEnd then
		active = 0
		return true
	else
		return false
	end if
end function

'continue timer, add same delay to original tStart
sub timer_type.restart()
	tStart = tEnd
	tEnd = tStart + tSpan
	active = 1
end sub

sub timer_type.pause()
	active = 0
end sub

sub timer_type.unpause()
	tStart = timer()
	tEnd = tStart + tSpan
	active = 1
end sub
