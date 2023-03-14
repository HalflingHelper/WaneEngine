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
        local list = {}
        --Iterate over every square on the board
        for i, square in ipairs(self.board) do
            --If the piece is the correct color
            if (square ~= INVALID and square ~= EMPTY and signum(square) == self.data.side) then
                local pieceID = self.data.side * square
                if pieceID == PAWN then
                    -- Pawn Moves are special

                elseif pieceID == KING then
                    -- Castling moves and king moves

                else
                    -- All other piece moves
                    if slide[pieceID] then
                        -- Bishops, Rooks, Queens
                        for j, dir in ipairs(offset[pieceID]) do
                            for dist = 1, 8 do
                                local to = self.board[i + dist * dir]
                                if to == EMPTY then
                                    list[#list+1] = move(i, to, 0)
                                elseif to == INVALID or signum(self.board[to]) ~= self.data.side then
                                    -- We run into an allied piece or the edge of the board
                                    break
                                else
                                    -- We're capturing a piece and there aren't any more moves
                                    list[#list+1] = move(i, to, 0)
                                    break
                                end
                            end              
                        end
                    else
                        for j, dir in ipairs(offset[pieceID]) do
                            if self.board[i + dir] == EMPTY or self.board[i + dir] ~= INVALID and signum(self.board[i + dir]) ~= self.data.side then
                                list[#list+1] = move(i, i + dir, 0)
                                print("added move")
                            end
                        end
                    end
                end
            end            
        end

        self.moveList = list
    end,

    --Makes the listed move on the board
    --Returns true if the move is successful, false if there was a problem
    makeMove = function(self, move)
        --Make sure that move exists in the move list
        for i, v in ipairs(self.moveList) do
            if moveEqual(v, move) then
                

                -- Make the move
                self.data.side = -1 * self.data.side
                self.board[move.to] = self.board[move.from]
                self.board[move.from] = EMPTY

                return true
            end
        end
        -- Return false if the move doesn't match
        return false
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