-- title:   Stacked tic tac toe
-- author:  Rokas Puzonas <rokas.puz@gmail.com>
-- desc:    Standard tic tac toe, but you can stack certain pieces on top of others
-- site:    https://github.com/RokasPuzonas/stacked-tic-tac-toe
-- license: MIT License
-- script:  lua

local DISPLAY_WIDTH = 240
local DISPLAY_HEIGHT = 136

local CELL_SIZE = 33
local CELL_GAP = 3
local BOARD_SIZE = 3*CELL_SIZE + 2*CELL_GAP
local SIDE_PANEL_WIDTH = 60

local P1_COLOR = 3
local P2_COLOR = 10

local p1_turn = true
local board = {0, 0, 0, 0, 0, 0, 0, 0, 0}
local p1_pieces = {1, 1, 2, 2, 3, 3}
local p2_pieces = {1, 1, 2, 2, 3, 3}
local is_dragging_piece = false
local dragging_piece_size = 0
local was_mouse_down = false
local finished = false

local function contains(t, v)
	for _, value in pairs(t) do
		if value == v then
			return true
		end
	end
	return false
end

local function countValue(t, v)
	local count = 0
	for _, value in pairs(t) do
		if value == v then
			count = count + 1
		end
	end
	return count
end

local function sign(x)
	if x > 0 then
		return 1
	elseif x < 0 then
		return -1
	else
		return 0
	end
end

local function removeValue(t, v)
	for i, value in ipairs(t) do
		if value == v then
			table.remove(t, i)
			break
		end
	end
end

local function drawPiece(x, y, size, color)
	local outer_size
	if size == 3 then
		outer_size = CELL_SIZE*0.4
	elseif size == 2 then
		outer_size = CELL_SIZE*0.3
	else
		outer_size = CELL_SIZE*0.2
	end

	circ(x, y, outer_size, 15)
	circ(x, y, outer_size*0.7, color)
end

local function drawGrid(x, y)
	local grid_color = 14

	rect(
		x + CELL_SIZE - CELL_GAP/2, y,
		CELL_GAP, BOARD_SIZE,
		grid_color
	)
	rect(
		x + 2*CELL_SIZE + CELL_GAP/2, y,
		CELL_GAP, BOARD_SIZE,
		grid_color
	)

	rect(
		x, y + CELL_SIZE - CELL_GAP/2,
		BOARD_SIZE, CELL_GAP,
		grid_color
	)
	rect(
		x, y + 2*CELL_SIZE + CELL_GAP/2,
		BOARD_SIZE, CELL_GAP,
		grid_color
	)
end

local function drawBoard(x, y)
	drawGrid(x, y)

	for i, piece_size in ipairs(board) do
		if piece_size == 0 then goto continue end
		local color
		if piece_size > 0 then
			color = P1_COLOR
		else
			color = P2_COLOR
		end

		local marker_x = (i-1) % 3
		local marker_y = math.floor((i-1) / 3)
		drawPiece(
			x + (marker_x * (CELL_SIZE + CELL_GAP) - CELL_GAP) + CELL_SIZE/2,
			y + (marker_y * (CELL_SIZE + CELL_GAP) - CELL_GAP) + CELL_SIZE/2,
			math.abs(piece_size),
			color
		)
		::continue::
	end
end

local function drawPlayerSidePanel(panel_x, panel_y, color, pieces)
	for i=3, 1, -1 do
		if contains(pieces, i) then
			local x = panel_x + (SIDE_PANEL_WIDTH-CELL_SIZE)/2
			local y = panel_y + (((3 - i)) * (CELL_SIZE + CELL_GAP) - CELL_GAP)
			drawPiece(x + CELL_SIZE/2, y + CELL_SIZE/2, math.abs(i), color)

			local count = countValue(pieces, i)
			print(("%dx"):format(count), x-10, y+CELL_SIZE/2-3)
		end
	end
end

local function drawTurnLabel()
	local x = (DISPLAY_WIDTH-80)/2
	local y = 4
	print("Player   turn", x, y)
	if p1_turn then
		rect(x+38, y+1, 5, 5, P1_COLOR)
	else
		rect(x+38, y+1, 5, 5, P2_COLOR)
	end
end

local function drawWinningLabel()
	local x = (DISPLAY_WIDTH-80)/2
	local y = 4
	print("Player   won", x, y)
	if p1_turn then
		rect(x+38, y+1, 5, 5, P1_COLOR)
	else
		rect(x+38, y+1, 5, 5, P2_COLOR)
	end
end

local function isInRect(target_x, target_y, x, y, w, h)
	return target_x >= x and target_x < x + w and target_y >= y and target_y < y + h
end

local function didCurrentPlayerWin()
	local player_sign
	if p1_turn then
		player_sign = 1
	else
		player_sign = -1
	end

	local player_board = {}
	for _, piece in ipairs(board) do
		table.insert(player_board, sign(piece) == player_sign)
	end

	for row=0,6,3 do
		if player_board[row+1] and player_board[row+2] and player_board[row+3] then
			return true
		end
	end

	for col=0,2 do
		if player_board[col+0] and player_board[col+3] and player_board[col+6] then
			return true
		end
	end

	return (player_board[1] and player_board[5] and player_board[9]) or (player_board[3] and player_board[5] and player_board[7])
end

local function drawDisplayCorners()
	local corner_size = 20
	tri(0, 0, corner_size, 0, 0, corner_size, 0)
	tri(DISPLAY_WIDTH, 0, DISPLAY_WIDTH-corner_size, 0, DISPLAY_WIDTH, corner_size, 0)
	tri(0, DISPLAY_HEIGHT, corner_size, DISPLAY_HEIGHT, 0, DISPLAY_HEIGHT-corner_size, 0)
	tri(DISPLAY_WIDTH, DISPLAY_HEIGHT, DISPLAY_WIDTH-corner_size, DISPLAY_HEIGHT, DISPLAY_WIDTH, DISPLAY_HEIGHT-corner_size, 0)
end

function TIC()
	cls(13)

	drawDisplayCorners()

	local board_x = (DISPLAY_WIDTH-BOARD_SIZE)/2
	local board_y = (DISPLAY_HEIGHT-BOARD_SIZE)/2
	drawBoard(board_x, board_y)
	if not finished then
		drawTurnLabel()
	else
		drawWinningLabel()
		print("Ctrl+R to restart", (DISPLAY_WIDTH-100)/2, DISPLAY_HEIGHT-10)
	end

	local side_panel_gap = (DISPLAY_WIDTH-BOARD_SIZE-2*SIDE_PANEL_WIDTH)/4
	local side_panel_y = board_y
	local p1_side_panel_x = side_panel_gap
	local p2_side_panel_x = DISPLAY_WIDTH-SIDE_PANEL_WIDTH-side_panel_gap
	drawPlayerSidePanel(p1_side_panel_x, board_y, P1_COLOR, p1_pieces)
	drawPlayerSidePanel(p2_side_panel_x, board_y, P2_COLOR, p2_pieces)

	local mx, my, is_mouse_down = mouse()

	if not finished then
		if not was_mouse_down and is_mouse_down then
			local pieces
			local side_panel_x
			if p1_turn then
				pieces = p1_pieces
				side_panel_x = p1_side_panel_x
			else
				pieces = p2_pieces
				side_panel_x = p2_side_panel_x
			end

			local piece_size = 3-math.floor((my - side_panel_y) / (CELL_SIZE+CELL_GAP))
			if isInRect(mx, my, side_panel_x, side_panel_y, SIDE_PANEL_WIDTH, BOARD_SIZE) and countValue(pieces, piece_size) > 0 then
				dragging_piece_size = piece_size
				is_dragging_piece = true
			end
		elseif was_mouse_down and not is_mouse_down then
			if is_dragging_piece and isInRect(mx, my, board_x, board_y, BOARD_SIZE, BOARD_SIZE) then
				local piece_x = math.floor((mx - board_x) / (CELL_SIZE+CELL_GAP))
				local piece_y = math.floor((my - board_y) / (CELL_SIZE+CELL_GAP))
				local board_index = 1+piece_x + piece_y * 3
				if math.abs(board[board_index]) < dragging_piece_size then
					if p1_turn then
						removeValue(p1_pieces, dragging_piece_size)
						board[board_index] = dragging_piece_size
					else
						removeValue(p2_pieces, dragging_piece_size)
						board[board_index] = -dragging_piece_size
					end

					if didCurrentPlayerWin() then
						finished = true
					else
						p1_turn = not p1_turn
					end
				end
			end
			is_dragging_piece = false
		end
		was_mouse_down = is_mouse_down

		if is_dragging_piece then
			if p1_turn then
				drawPiece(mx, my, dragging_piece_size, P1_COLOR)
			else
				drawPiece(mx, my, dragging_piece_size, P2_COLOR)
			end
		end
	end
end

-- <SPRITES>
-- 000:00000000000000000000000000000fff00000fff0000ffff0000ffff000fffff
-- 001:00000000000000000ffffffffffffffffffffffffffffffffffff333f3333333
-- 002:0000000000000000fffffff0ffffffffffffffffffffffff3333ffff33333fff
-- 003:00000000000000000000000000000000f0000000ff000000fff00000fff00000
-- 004:000000000000000000000000000000000000000000000000000000000000000f
-- 005:000000000000000000000000000000000000ffff0fffffff0fffffffffffff33
-- 006:00000000000000000000000000000000fffffff0ffffffffffffffff3333ffff
-- 007:000000000000000000000000000000000000000000000000f0000000ff000000
-- 010:00000000000000000000000000000000000000000000000000000000fffff000
-- 016:000fffff000fffff00fffff300fffff300fffff300ffff330fffff330fffff33
-- 017:3333333333333333333333333333333333333333333333333333333333333333
-- 018:33333fff333333ff3333333f3333333f33333333333333333333333333333333
-- 019:ffff0000fffff000fffff000fffff000fffff0003fffff003fffff003fffff00
-- 020:000000ff000000ff000000ff000000ff00000fff00000fff00000fff00000fff
-- 021:ffff3333ffff3333ff333333f3333333f3333333f3333333f333333333333333
-- 022:33333fff333333ff3333333f3333333f33333333333333333333333333333333
-- 023:ff000000ff000000fff00000fff00000fff00000fff00000fff00000fff00000
-- 025:0000ffff00ffffff0ffffffffffff333ffff3333fff33333fff33333fff33333
-- 026:fffffff0ffffffffffffffff3333ffff33333fff33333fff333333ff333333ff
-- 027:00000000000000000000000000000000f0000000f0000000f0000000f0000000
-- 032:0fffff330fffff330fffff330ffffff300fffff300ffffff00ffffff000fffff
-- 033:3333333333333333333333333333333333333333f3333333ff333333ffff3333
-- 034:3333333333333333333333333333333333333333333333333333333f33333fff
-- 035:3fffff0033ffff0033ffff0033ffff003fffff003fffff00ffffff00fffff000
-- 036:00000fff00000fff00000fff00000fff00000fff00000fff000000ff0000000f
-- 037:33333333333333333333333333333333f3333333fff33333ffffff33ffffffff
-- 038:33333333333333333333333f3333333f333333ff33333fff3333ffffffffffff
-- 039:fff00000fff00000fff00000fff00000ff000000ff000000ff000000f0000000
-- 041:fff33333ffff33330fffff330fffffff0fffffff000fffff0000000000000000
-- 042:33333fff33333fff33fffffffffffffffffffff0fffff0000000000000000000
-- 043:f0000000f0000000f00000000000000000000000000000000000000000000000
-- 048:0000ffff00000fff000000ff0000000000000000000000000000000000000000
-- 049:ffffff33ffffffffffffffffffffffff00ffffff00000fff0000000000000000
-- 050:3333ffff33ffffffffffffffffffffffffffffffffffff000000000000000000
-- 051:fffff000ffff0000ff000000f000000000000000000000000000000000000000
-- 053:0fffffff000fffff000000000000000000000000000000000000000000000000
-- 054:ffffffffffffff00000000000000000000000000000000000000000000000000
-- 064:0000000000000000000000000000000f0000000f000000ff00000fff0000ffff
-- 065:00000000000000000ffffffffffffffffffffffffffffffffffff33fff333333
-- 066:0000000000000000ffff0000ffffff00fffffff0ffffffffffffffff33ffffff
-- 067:000000000000000000000000000000000000000000000000f0000000f0000000
-- 080:000fffff000fffff00fffff300fffff300fffff300ffff330fffff330ffff333
-- 081:f333333333333333333333333333333333333333333333333333333333333333
-- 082:333fffff3333ffff33333fff333333ff3333333f333333333333333333333333
-- 083:ff000000fff00000ffff0000ffff0000ffff0000fffff000fffff000fffff000
-- 096:0ffff3330ffff3330ffff3330ffff3330fffff330ffffff300ffffff00ffffff
-- 097:33333333333333333333333333333333333333333333333333333333f3333333
-- 098:33333333333333333333333333333333333333333333333f33333fff3333ffff
-- 099:3fffff003fffff003fffff00fffff000fffff000fffff000ffff0000ffff0000
-- 112:000fffff000fffff0000ffff00000fff000000ff000000000000000000000000
-- 113:ff333333ffff3333ffffffffffffffffffffffffffffffff0000000000000000
-- 114:3fffffff3ffffffffffffffffffffff0ffff0000ffff00000000000000000000
-- 115:fff00000ff000000f00000000000000000000000000000000000000000000000
-- </SPRITES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:1a1c2c5d275db13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>
