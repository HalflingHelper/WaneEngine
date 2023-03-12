--The core board representation, using a 10x12 board, movegen implementation based on TSCP engine
require 'util'
require 'data'
require 'move'

local Board = {
    --Fields in Board
    board = {}, data = {}, moveList = {},

    --Sets the board and flags in their initial states
    init = function (self)
        -- Pieces
        local b = {}
        for i, v in ipairs(initBoardState) do
            b[#b + 1] = v
        end
        -- Data for ep, fiftyMoveRule, etc.
        for k, v in pairs(initBoardData) do
            self.data[k] = v
        end
        -- Initialize the moveList as empty
        self.moveList = {}

        self.board = b
    end,

    --Generates all available moves in the position for the current color
    genMoves = function(self)
        --Iterate over every square on the board
        for i, square in ipairs(self.board) do
            --If the piece is the correct color
            if (signum(square) == self.data.side) then
                
            end            
        end
    end,

    --Makes the listed move on the board
    --Returns true if the move is successful, false if there was a problem
    makeMove = function(self, move)
        --Make sure that move exists in the move list

        self.board[move.to] = self.board[move.from]
        self.board[move.from] = EMPTY

    end,

    print = function(self)
        io.write('\n8  ')

        for i, v in ipairs(self.board) do
            if v ~= INVALID then
                io.write(' ', pieceCharCodes[v])
                if i % 10 == 9 and i ~= 99 then
                    io.write('\n', 10 - math.ceil(i/10), '  ')
                end
            end
        end

        io.write('\n\n    a b c d e f g h\n')
    end
}

return Board