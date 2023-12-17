
const as integer SCREEN_W = 800
const as integer SCREEN_H = SCREEN_W
const as integer FONT_W = 8, FONT_H = 16

sub printSpecial(x as long, y as long, text as string, c1 as ulong, c2 as ulong, c3 as ulong)
	for yi as integer = -2 to +2
		for xi as integer = -2 to +2
			if (abs(xi) + abs(yi)) > 3 then continue for
			if (abs(xi) < 1) and (abs(yi) < 2) then continue for
			if (abs(yi) < 1) and (abs(xi) < 2) then continue for
			draw string(x+xi,y+yi), text, c3
		next
	next
	for yi as integer = -1 to +1
		for xi as integer = -1 to +1
			if (abs(xi) + abs(yi)) > 1 then continue for
			if xi = 0 and yi = 0 then continue for
			draw string(x+xi,y+yi), text, c2
		next
	next
	draw string(x,y), text, c1
end sub


screenres SCREEN_W, SCREEN_H, 32
width SCREEN_W \ FONT_W, SCREEN_H \ FONT_H
line(0,0)-(SCREEN_W-1, SCREEN_H-1),&hff404040, bf

dim shared as const ulong colors(0to 6) = {_
	&h00F0F0,_ 'lightblue
	&h0000F0,_ 'blue
	&hF0A000,_ 'orange
	&hF0F000,_ 'yellow
	&h00F000,_ 'green
	&HA000F0,_ 'purple
	&hF00000}  'red

dim as string text = "QWErtyahmM1256!@#$%^&*()?"


dim as integer x = 50
dim as integer y = 50

for i as integer = 0 to 6
	printSpecial(x, y+i*20, text, &hffffffff, &hff404040, colors(i))
	printSpecial(x+250, y+i*20, text, colors(i), &hff404040, &hff000000)
	printSpecial(x+500, y+i*20, text, &hffffffff, colors(i), &hff000000)
next

getkey()

