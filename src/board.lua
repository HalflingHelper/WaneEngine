--The core board representation, using a 10x12 board, movegen implementation based on TSCP engine
require 'data'

local Board = {
    board = {},
    flags = {
        ep = -1, --En Passant, is set to the index of the potential targeted square when a pawn is pushed forward 2 squares
        castle = 15, --4 bits, from left to right, 8=wq, 4=wk, 2=bq, 1=bk
        side = 1, --1 for white, 2 for black
    },
    --Need a fifty move counter

    --Sets the board and variables in their initial state
    init = function (self)
        local b = {}
        for i, v in pairs(initBoardState) do
            b[#b + 1] = v
        end

        self.board = b
    end,

    gen_moves = function(self)
        --Iterate over every square on the board
        for i, v in ipairs(self.board) do
            
        end
            --If the piece is the correct color
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