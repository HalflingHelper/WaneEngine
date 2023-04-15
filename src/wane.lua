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


--TODO: Game end states (includes handling movecounts and shit)
--TODO: Repetitions, 50 move rule, end states

require 'util'
require 'move'
require 'test'

Board = require 'board'

Board:init()
-- Use various FEN testing string here
--Board:fromFEN("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq -")

local st = os.clock()
--print(perft(Board, 4)) 
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
