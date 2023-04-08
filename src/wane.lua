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

require 'util'
require 'move'
require 'test'

Board = require 'board'

Board:init()
-- Use various FEN testing string here
Board:fromFEN("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - ")

print(perft(Board, 2))

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
