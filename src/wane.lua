require 'util'
require 'move'

Board = require 'board'

Board:init()

--Core loop of the engine
-- while true do
--     local s = io.read()

--     local m = parseMove(s)

--     if (not Board:makeMove(m)) then
--         print("Illegal move.")
--     else
--         Board:print()
--     end

-- end

Board:print()

Board:makeMove({from = 89, to = 79})

Board:print()
