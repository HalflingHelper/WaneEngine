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

require 'util'
require 'move'
require 'test'
require 'hash'
require 'search'

Board = require 'board'
init_hash()

Board:init()
-- Use various FEN testing string here
--Board:fromFEN("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - ")
local testDepth = 6
--local st = os.clock()
--print(perft(Board, testDepth))
--local et = os.clock()
--print("Perft benchmark for depth " .. testDepth .. ": " .. et - st)

testSearch(Board, testDepth)

--Setting up player information.
local comp_side = WHITE
local side = WHITE

-- Core loop of the engine
while true do
    Board:genMoves()
    Board:checkResult()

    local alpha, m

    if side == comp_side then
        --No functionality for search timeout
        alpha, m = searchRoot(Board)
        alpha = side*alpha
        print("Eval", alpha)
    else
        repeat
            local s = io.read()
            local status, err = pcall(function() m = parseMove(s) end)

            if (not status) then print(err) end
        until (status == true)
    end

    if (not Board:makeLegalMove(m)) then
        print("Illegal move.")
    else
        Board:print()
        side = -side
    end
end
