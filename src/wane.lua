--[[
    Wane - A chess engine

    Author: Calvin Josenhans
    Purpose: A chess engine, made as a beginner project to understand the basics of how they work.
    Date: March 2023
]]


--TODO: ???? Change board representation to a piece array and a color array to reduce overhead of math.abs / signum functions

require 'util'
require 'move'

Board = require 'board'

Board:init()

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
