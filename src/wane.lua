require 'util'
require 'move'

Board = require 'board'

Board:init()

-- Core loop of the engine
while true do
    Board:genMoves()

    local s = io.read()

    local m = parseMove(s)

    if (not Board:makeMove(m)) then
        print("Illegal move.")
    else
        Board:print()
    end

end
