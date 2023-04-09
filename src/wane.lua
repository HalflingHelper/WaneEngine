--[[
    Wane - A chess engine

    Author: Calvin Josenhans
    Purpose: A chess engine, made as a beginner project to understand the basics of how they work.
    Date: March 2023
]]

--[[
    Notes in case I ever make another one of these:
        Have robust move flags that allow undoing of a move simply from looking at the move type
        Checking for checks without having to make the move on the board might make the rest of the stuff more elegant
]]


--TODO: ???? Change board representation to a piece array and a color array to reduce overhead of math.abs / signum functions?
--TODO: Game end states (includes handling movecounts and shit)

--TODO: Movegen doesn't work, 4,865,608 instaed of 4,865,609 at depth 5
--TODO: Something better than FEN conversion for taking back moves
    --Flags I would need: Type of piece captured. If it was EP, State of castle flags for king and rook moves

require 'util'
require 'move'
require 'test'

Board = require 'board'

Board:init()
-- Use various FEN testing string here
--Board:fromFEN("r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10 ")

local st = os.clock()
print(perft(Board, 3))
local et = os.clock()

print(et - st)

-- Core loop of the engine
while true do
    Board:genMoves()

    local m

    repeat 
        local s = io.read()
        local status, err = pcall(function() m = parseMove(s) end)

        if (not status) then print(err) end
    until (status == true)

    if (not Board:makeMove(m)) then
        print("Illegal move.")
    else
        Board:print()
    end
end
