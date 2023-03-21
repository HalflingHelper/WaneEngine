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
                    -- Pawn Moves are specifies
                    local pawnDist = 10
                    local rank = getRank(i)
                    local to = i - self.data.side * pawnDist

                    -- Check pushes
                    if self.board[to] == EMPTY then
                        list[#list + 1] = move(i, to, 0)
                        if (self.data.side == WHITE and rank == 2) or (self.data.side == BLACK and rank == 7) then
                            --Push two squares if the square is free
                            if self.board[to - pawnDist * self.data.side] == EMPTY then
                                --Need to set the en passant flag
                                list[#list + 1] = move(i, to - pawnDist * self.data.side, 0)
                            end
                        end
                    end

                    -- Check Captures: TODO: Repeated code, should be in a method
                    if self.board[to + 1] ~= INVALID and self.board[to + 1] ~= EMPTY and signum(self.board[to + 1]) ~= self.data.side then
                        list[#list + 1] = move(i, to + 1, 0)
                    end
                    
                    if self.board[to - 1] ~= INVALID and self.board[to - 1] ~= EMPTY and signum(self.board[to - 1]) ~= self.data.side then
                        list[#list + 1] = move(i, to - 1, 0)
                    end

                elseif pieceID == KING then
                    -- Castling moves and king moves
                    for j, dir in ipairs(offset[pieceID]) do
                        --Normal King moves
                        if self.board[i + dir] == EMPTY or (self.board[i + dir] ~= INVALID and signum(self.board[i + dir]) ~= self.data.side) then
                            list[#list+1] = move(i, i + dir, 0)
                        end
                    end

                    local c = self.data.castle
                    --Makes it so that bit 1 is KC and bit 2 is QC
                    if self.data.side == WHITE then c = c >> 2 end

                    if c & 2 then
                        -- Check and add QC move
                        if self.board[i-3] == EMPTY and self.board[i-2] == EMPTY and self.board[i-1] == EMPTY then
                            list[#list+1] = move(i, i - 2, CASTLE_BIT)
                        end
                    end

                    if c & 1 then
                        -- Check and add KC move
                        if self.board[i+2] == EMPTY and self.board[i+1] == EMPTY then
                            list[#list+1] = move(i, i + 2, CASTLE_BIT)
                        end
                    end

                else
                    -- All other piece moves
                    if slide[pieceID] then
                        -- Bishops, Rooks, Queens
                        for j, dir in ipairs(offset[pieceID]) do
                            for dist = 1, 8 do
                                local to = i + dist * dir
                                if self.board[to] == EMPTY then
                                    list[#list+1] = move(i, to, 0)
                                elseif self.board[to] == INVALID or signum(self.board[to]) == self.data.side then
                                    -- We run into an allied piece or the edge of the board
                                    break
                                else
                                    -- We're capturing a piece and there aren't any more moves
                                    list[#list+1] = move(i, to, CAPTURE_BIT)
                                    break
                                end
                            end              
                        end
                    else
                        --Horses
                        for j, dir in ipairs(offset[pieceID]) do
                            if self.board[i + dir] == EMPTY or (self.board[i + dir] ~= INVALID and signum(self.board[i + dir]) ~= self.data.side) then
                                local moveFlags = signum(self.board[i + dir]) == -1 * self.data.side and CAPTURE_BIT or 0

                                list[#list+1] = move(i, i + dir, moveFlags)
                            end
                        end
                    end
                end
            end            
        end

        self.moveList = list
        --[[
        for i, m in ipairs(list) do
            print(m.from, m.to)
        end
        print(#list)
        --]]
    end,

    --Makes the listed move on the board
    --Returns true if the move is successful, false if there was a problem
    makeMove = function(self, move)
        --Make sure that move exists in the move list
        for i, v in ipairs(self.moveList) do
            if moveEqual(v, move) then
                local pieceType = math.abs(self.board[move.from]) 
                local pieceColor = signum(self.board[move.from])

                -- Make the move
                self.data.side = -1 * self.data.side
                self.board[move.to] = self.board[move.from]
                self.board[move.from] = EMPTY

                if pieceType == KING and move.flags & CASTLE_BIT then
                    if move.to > move.from then
                        --We want the KS rook
                        self.board[move.to - 1] = self.board[move.to+1]
                        self.board[move.to + 1] = EMPTY
                    else
                        --We want the QS rook
                        self.board[move.to + 1] = self.board[move.to-2]
                        self.board[move.to - 2] = EMPTY
                    end
                end

                --Update castle flags
                if pieceType == KING then
                    self.data.castle = pieceColor == BLACK and (self.data.castle & 12) or (self.data.castle & 3)
                end

                if pieceType == ROOK then
                    if move.from == 22 then
                        self.data.castle = self.data.castle & 13
                    elseif move.from == 29 then
                        self.data.castle = self.data.castle & 14
                    elseif move.from == 92 then
                        self.data.castle = self.data.castle & 7
                    elseif move.from == 99 then
                        self.data.castle = self.data.castle & 11
                    end
                end


                --Update EP flags

                --Update 50 move counter
                if pieceType == PAWN or move.flags & CAPTURE_BIT then
                    self.data.fiftyMoveRule = 0
                end

                self.data.fiftyMoveRule = self.data.fiftyMoveRule + 1

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