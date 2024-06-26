package.path = "./WaneEngine/src/?.lua;"..package.path

--The engine's core board representation, using a 10x12 board, and partially inspired by TSCP engine
require 'util'
require 'data'
require 'move'
require 'hash'

-- The Main Board Class
local Board = {
    --Fields in Board
    pieces = {},
    colors = {},
    data = {},
    hist = {},
    hash = {},
    moveList = {},
    --Sets the board and flags in their initial states
    init = function(self)
        -- Pieces
        for i, v in ipairs(initPieces) do
            self.pieces[i] = initPieces[i]
            self.colors[i] = initColors[i]
        end
        -- Data for ep, fiftyMoveCount, etc.
        for k, v in pairs(initBoardData) do
            self.data[k] = v
        end

        for k, v in pairs(initBoardData.castle) do
            self.data.castle[k] = v
        end
        self.hash = { {} } --Initialzing hist with the first partition already
        -- Initialize the moveList as empty
        self.moveList = {}
    end,
    --[[
        Returns true if square is a valid target for pawn captures
        Valid squares either contain pieces of the opposing side or are targets for EnPassant
    ]]
    checkPawnCaps = function(self, square)
        return self.colors[square] == -1 * self.data.side or self.data.ep == square
    end,

    --Adds pawn moves to the list
    genPawnMove = function(self, from, to, promo, list)
        if promo then
            for type = KNIGHT, QUEEN do
                --Promos at the beginning of the list
                table.insert(list, 1, move(from, to, self.pieces[to], type))
            end
        else
            if self.colors[to] ~= EMPTY then
                table.insert(list, 1, move(from, to, self.pieces[to]))
            else
                list[#list + 1] = move(from, to, self.pieces[to])
            end
        end
    end,

    --[[
        Generates all available pseudo-legal moves in the position for the current color
        Returns the board's moveList
    ]]
    genMoves = function(self)
        local list = {}
        local s = self.data.side
        --Iterate over every square on the board
        for i = 22, 99 do
            --for i, piece in ipairs(self.pieces) do
            local piece = self.pieces[i]
            --If the piece is the correct color
            if self.colors[i] == s then
                if piece == PAWN then
                    -- Pawn Moves are specifies
                    local pawnDist = -10 * s
                    local rank = getRank(i)
                    local to = i + pawnDist

                    local isPromo = to < 22 or to > 91

                    -- Check pushes
                    if self.pieces[to] == EMPTY then
                        -- Normal push
                        self:genPawnMove(i, to, isPromo, list)
                        --Double push
                        if (s == WHITE and rank == 2) or (s == BLACK and rank == 7) then
                            if self.pieces[to + pawnDist] == EMPTY then
                                list[#list + 1] = move(i, to + pawnDist)
                            end
                        end
                    end

                    -- Check Captures in both directions
                    if self:checkPawnCaps(to + 1) then
                        self:genPawnMove(i, to + 1, isPromo, list)
                    end
                    if self:checkPawnCaps(to - 1) then
                        self:genPawnMove(i, to - 1, isPromo, list)
                    end
                elseif piece == KING then
                    -- Castling moves and king moves
                    for j, dir in ipairs(offset[piece]) do
                        --Normal King moves
                        if self.pieces[i + dir] == EMPTY then
                            list[#list + 1] = move(i, i + dir)
                        elseif self.colors[i + dir] == -s then
                            table.insert(list, 1, move(i, i + dir, self.pieces[i + dir]))
                        end
                    end

                    local c = self.data.castle
                    --Queenside castling
                    if s == WHITE and c.wq or s == BLACK and c.bq then
                        -- Check and add QC move
                        if self.pieces[i - 3] == EMPTY and self.pieces[i - 2] == EMPTY and self.pieces[i - 1] == EMPTY then
                            list[#list + 1] = move(i, i - 2)
                        end
                    end

                    --Kingside castling
                    if s == WHITE and c.wk or s == BLACK and c.bk then
                        -- Check and add KC move
                        if self.pieces[i + 2] == EMPTY and self.pieces[i + 1] == EMPTY then
                            list[#list + 1] = move(i, i + 2)
                        end
                    end
                else
                    -- All other piece moves
                    if slide[piece] then
                        -- Bishops, Rooks, Queens
                        for j, dir in ipairs(offset[piece]) do
                            for dist = 1, 7 do
                                local to = i + dist * dir
                                if self.pieces[to] == EMPTY then
                                    list[#list + 1] = move(i, to)
                                elseif self.pieces[to] == INVALID or self.colors[to] == s then
                                    -- We run into an allied piece or the edge of the board
                                    break
                                else
                                    -- We're capturing a piece and there aren't any more moves
                                    table.insert(list, 1, move(i, to, self.pieces[to]))
                                    break
                                end
                            end
                        end
                    else
                        --Horses
                        for j, dir in ipairs(offset[piece]) do
                            if self.colors[i + dir] == EMPTY then
                                list[#list + 1] = move(i, i + dir)
                            elseif self.colors[i + dir] == -s then
                                table.insert(list, 1, move(i, i + dir, self.pieces[i + dir]))
                            end
                        end
                    end
                end
            end
        end

        self.moveList = list
    
        return list
    end,
    --[[
        Returns true if the square at said sqIndex is attacked by pieces of the current color
    ]]
    isAttacked = function(self, idx)
        --Look for knights
        for i, dir in ipairs(offset[KNIGHT]) do
            if self.pieces[idx + dir] == KNIGHT and self.colors[idx + dir] == self.data.side then
                return true
            end
        end
        --Look for sliding pieces (rook, bishop, queen)
        for i, dir in ipairs(offset[BISHOP]) do
            for dist = 1, 7 do
                local to = idx + dist * dir
                if self.pieces[to] == INVALID or self.colors[to] == -1 * self.data.side then
                    -- We run into a piece the same color as the king or the edge of the board
                    break
                end

                local pieceType = self.pieces[to]

                if pieceType ~= EMPTY then
                    if pieceType == BISHOP or pieceType == QUEEN or (dist == 1 and pieceType == KING) then
                        return true
                    else
                        break
                    end
                end
            end
        end

        for i, dir in ipairs(offset[ROOK]) do
            for dist = 1, 7 do
                local to = idx + dist * dir
                if self.pieces[to] == INVALID or self.colors[to] == -1 * self.data.side then
                    -- We run into an allied piece or the edge of the board
                    break
                end

                local pieceType = self.pieces[to]

                if pieceType ~= EMPTY then
                    if pieceType == ROOK or pieceType == QUEEN or (dist == 1 and pieceType == KING) then
                        return true
                    else
                        break
                    end
                end
            end
        end
        -- Look for pawns, going in the opposite direct of self.side
        -- Pawns to the left
        if self.colors[idx + 11 * self.data.side] == self.data.side and self.pieces[idx + 11 * self.data.side] == PAWN then
            return true
        end
        -- Pawns to the right
        if self.colors[idx + 9 * self.data.side] == self.data.side and self.pieces[idx + 9 * self.data.side] == PAWN then
            return true
        end
        -- We didn't find anything
        return false
    end,
    --[[
        Scans the board to see if the current side is checking the opponent's king
        Used for determining the legality of moves.
    ]]
    inCheck = function(self)
        -- Find the king
        for i, piece in ipairs(self.pieces) do
            if piece == KING and self.colors[i] ~= self.data.side then
                -- Returns true if the square the king is on is attacked
                return self:isAttacked(i)
            end
        end
        -- Unreachable
        return false
    end,
    -- Blindly assumes that move was the last move made, this could create issues
    takebackMove = function(self, move)
        --Set flags according to what they were before the move
        self.data = table.remove(self.hist)

        local from, to = move.from, move.to
        --Move the  piece back to the square it came from
        self.pieces[from] = self.pieces[to]
        self.colors[from] = self.colors[to]

        --Reverting back to a pawn
        if move.promo ~= EMPTY then
            self.pieces[from] = PAWN
        end

        if move.captured ~= EMPTY then
            self.pieces[to] = move.captured
            self.colors[to] = -self.data.side
        else
            self.pieces[to] = EMPTY
            self.colors[to] = EMPTY
        end

        --Need to replace en-passant pawns
        if self.pieces[from] == PAWN and to == self.data.ep then
            self.pieces[to + self.data.side * 10] = PAWN
            self.colors[to + self.data.side * 10] = -self.data.side
            --Moving the rook for castling
        elseif self.pieces[from] == KING then
            if to - from == 2 then
                --We want the KS rook
                self.pieces[to + 1] = self.pieces[to - 1]
                self.pieces[to - 1] = EMPTY
                self.colors[to + 1] = self.colors[to - 1]
                self.colors[to - 1] = EMPTY
            elseif from - to == 2 then
                --We want the QS rook
                self.pieces[to - 2] = self.pieces[to + 1]
                self.pieces[to + 1] = EMPTY
                self.colors[to - 2] = self.colors[to + 1]
                self.colors[to + 1] = EMPTY
            end
        end

        -- Takeback the hash
        table.remove(self.hash[#self.hash])
        if #(self.hash[#self.hash]) == 0 and #self.hash > 1 then
            table.remove(self.hash)
        end
    end,
    --[[
        Makes the listed move on the board, doesn't check for legality
        If the move is illegal, it undoes whatever it did and returns false. Otherwise, it returns true.
    ]]
    makeMove = function(self, move)
        --Make sure that move exists in the move list
        for i, v in ipairs(self.moveList) do
            if moveEqual(v, move) then
                local newdata = {
                    ep             = -1,                  -- En Passant is set to the index of the potential targeted square
                    side           = self.data.side * -1, -- White goes first
                    castle         = {
                        wq = self.data.castle.wq,
                        wk = self.data.castle.wk,
                        bq = self.data.castle.bq,
                        bk = self.data.castle.bk
                    },
                    fiftyMoveCount = self.data.fiftyMoveCount,
                    fullMoves      = self.data.fullMoves,
                }

                local to, from = move.to, move.from

                -- Noting some information about the move
                local pieceType = self.pieces[from]
                local pieceColor = self.colors[from]

                -- Make the move on the board
                self.pieces[to] = self.pieces[from]
                self.pieces[from] = EMPTY

                self.colors[to] = self.colors[from]
                self.colors[from] = EMPTY

                self.data.side = -1 * self.data.side

                --Piece specific move checks
                if pieceType == PAWN then
                    if move.promo ~= EMPTY then
                        --Promotion activation
                        self.pieces[to] = move.promo
                    elseif to == self.data.ep then
                        -- Remove the captured piece if the move was an EP capture
                        self.pieces[to + 10 * pieceColor] = EMPTY
                        self.colors[to + 10 * pieceColor] = EMPTY
                    end
                elseif pieceType == KING then
                    --Castling, returns false if castle through check.
                    if math.abs(from - to) == 2 then
                        if to > from then
                            --Make sure the king didn't move through check
                            if self:isAttacked(from + 1) or self:isAttacked(from) then
                                self.pieces[from] = self.pieces[to]
                                self.pieces[to] = EMPTY
                                self.colors[from] = self.colors[to]
                                self.colors[to] = EMPTY
                                self.data.side = -1 * self.data.side
                                return false
                            end
                            --We want the KS rook
                            self.pieces[to - 1] = self.pieces[to + 1]
                            self.pieces[to + 1] = EMPTY
                            self.colors[to - 1] = self.colors[to + 1]
                            self.colors[to + 1] = EMPTY
                        else
                            --Make sure king didn't castle through check
                            if self:isAttacked(from - 1) or self:isAttacked(from) then
                                self.pieces[from] = self.pieces[to]
                                self.pieces[to] = EMPTY
                                self.colors[from] = self.colors[to]
                                self.colors[to] = EMPTY
                                self.data.side = -1 * self.data.side
                                return false
                            end
                            --We want the QS rook
                            self.pieces[to + 1] = self.pieces[to - 2]
                            self.pieces[to - 2] = EMPTY
                            self.colors[to + 1] = self.colors[to - 2]
                            self.colors[to - 2] = EMPTY
                        end
                    end

                    -- Removes castle flags
                    if pieceColor == BLACK then
                        newdata.castle.bq = false
                        newdata.castle.bk = false
                    else
                        newdata.castle.wq = false
                        newdata.castle.wk = false
                    end
                elseif pieceType == ROOK then
                    --Dismantling castle flags for rooks
                    if from == 22 then
                        newdata.castle.bq = false
                    elseif from == 29 then
                        newdata.castle.bk = false
                    elseif from == 92 then
                        newdata.castle.wq = false
                    elseif from == 99 then
                        newdata.castle.wk = false
                    end
                end

                --Removing castle flags if a rook is captured.
                if move.captured == ROOK then
                    if to == 22 then
                        newdata.castle.bq = false
                    elseif to == 29 then
                        newdata.castle.bk = false
                    elseif to == 92 then
                        newdata.castle.wq = false
                    elseif to == 99 then
                        newdata.castle.wk = false
                    end
                end


                --Update EP flags if the move is a double pawn push
                if pieceType == PAWN and math.abs(to - from) == 20 then
                    --Set the en passant flag to the targeted square
                    newdata.ep = to + 10 * pieceColor
                else
                    -- Reset the en passant flag
                    newdata.ep = -1
                end

                --Update 50 move counter
                if pieceType == PAWN or move.captured then
                    newdata.fiftyMoveCount = 0
                    --Add a new partition to the history list
                    self.hash[#self.hash + 1] = {}
                end

                -- If current side is white black just moved
                if self.data.side == WHITE then self.data.fullMoves = self.data.fullMoves + 1 end

                self.data.side = -1 * self.data.side

                table.insert(self.hist, self.data)

                table.insert(self.hash[#self.hash], get_hash(self))

                self.data = newdata
                --Wrapping the return in a do while so that lua doesn't scream
                do return true end
            end
        end

        -- Return false if the move isn't in the move list
        return false
    end,
    --[[
        Makes the listed move on the board
        If the move is illegal, it undoes whatever it did and returns false. Otherwise, it returns true.
    ]]
    makeLegalMove = function(self, move)
        -- Need this because of checking for checked squares
        if not self:makeMove(move) then return false end
        if self:inCheck() then
            self:takebackMove(move)
            return false
        end
        return true
    end,
    --[[
        Determines if the game is over, either by 50 move rule, checkmate, stalemate, or repetition
        Returns true if the game is over, and prints out information about the result
    ]]
    checkResult = function(self)
        local canMove = false

        for i, move in ipairs(self.moveList) do
            if self:makeLegalMove(move) then
                canMove = true
                self:takebackMove(move)
                break
            end
        end
        if not canMove then
            self.data.side = -1 * self.data.side
            if self:inCheck() then
                --Check for the side
                local winner = self.side == WHITE and "White" or "Black"
                print(winner .. " wins by checkmate.")
            else
                --Stalemate
                print("Draw by stalemate.")
            end
            self.data.side = -1 * self.data.side
            return true
        elseif self.data.fiftyMoveCount >= 100 then
            print("Draw by the fifty move rule.")
            return true
        elseif self:reps() >= 3 then
            print("Draw by threefold repetition.")
            return true
        end
        return false
    end,

    --Returns the number of times that the current position has been repeated
    reps = function(self)
        local curHash = self.hash[#self.hash][#self.hash[#self.hash]]
        local count = 0
        for i, hash in ipairs(self.hash[#self.hash]) do
            if hash == curHash then count = count + 1 end
        end
        return count
    end,

    -- Returns the FEN string representation of the board
    toFEN = function(self)
        local fen = ""

        --Pieces
        local numEmpty = 0
        local sq = 0
        for i, v in ipairs(self.pieces) do
            if v ~= INVALID then
                if v == EMPTY then
                    numEmpty = numEmpty + 1
                else
                    if numEmpty ~= 0 then
                        fen = fen .. numEmpty
                        numEmpty = 0
                    end
                    fen = fen .. pieceCharCodes[v * self.colors[i]]
                end
                sq = sq + 1
                if sq % 8 == 0 then
                    if numEmpty ~= 0 then
                        fen = fen .. numEmpty
                        numEmpty = 0
                    end
                    if sq ~= 64 then
                        fen = fen .. "/"
                    end
                end
            end
        end
        --Other information

        --Active color
        if self.data.side == WHITE then
            fen = fen .. " w"
        else
            fen = fen .. " b"
        end
        --Castle rights
        if self.data.castle.wk or self.data.castle.wq or self.data.castle.bk or self.data.castle.bq then
            fen = fen .. " "
        end

        if self.data.castle.wk then fen = fen .. "K" end
        if self.data.castle.wq then fen = fen .. "Q" end
        if self.data.castle.bk then fen = fen .. "k" end
        if self.data.castle.bq then fen = fen .. "q" end

        --En passant target
        if self.data.ep ~= -1 then
            fen = fen .. " " .. sqToCoords(self.data.ep) .. " "
        else
            fen = fen .. " - "
        end

        --Half Move Clock
        fen = fen .. self.data.fiftyMoveCount

        --Full Moves
        fen = fen .. " " .. self.data.fullMoves

        return fen
    end,
    --Sets board to the same state as the given fen string
    --TODO: Half Move Clock and Full Move Count
    fromFEN = function(self, fen)
        self.data.castle = { wk = false, wq = false, bk = false, bq = false }
        self.data.ep = -1
        self.data.fiftyMoveCount = 0

        local stage = 0
        local sqIndex = 22
        for c in fen:gmatch(".") do
            if c == " " then
                stage = stage + 1

                goto continue
            end

            if stage == 2 then
                --Since castling can be completely omitted, we need to check if there is castling, otherwise
                if not (c == "K" or c == "Q" or c == "q" or c == "k") then
                    stage = 3
                end
            end

            if stage == 0 then
                if tonumber(c) then
                    --Empty squares
                    for sq = sqIndex, sqIndex + tonumber(c) - 1 do
                        self.pieces[sq] = EMPTY
                        self.colors[sq] = EMPTY
                    end
                    sqIndex = sqIndex + tonumber(c)
                elseif c == "/" then
                    sqIndex = sqIndex + 2
                else
                    local piece = charCodesToPiece[c]
                    self.pieces[sqIndex] = math.abs(piece)
                    self.colors[sqIndex] = signum(piece)
                    sqIndex = sqIndex + 1
                end
            elseif stage == 1 then
                --Piece colors
                self.data.side = c == "w" and WHITE or BLACK
            elseif stage == 2 then
                --Castling
                if c == "K" then self.data.castle.wk = true end
                if c == "Q" then self.data.castle.wq = true end
                if c == "k" then self.data.castle.bk = true end
                if c == "q" then self.data.castle.bq = true end
            elseif stage == 3 then
                if c >= 'a' and c <= 'h' then
                    self.data.ep = self.data.ep + 1 + string.byte(c) - 96
                elseif c == '-' then
                    self.data.ep = -1
                else
                    self.data.ep = self.data.ep + 100 - 10 * tonumber(c)
                end
            end
            ::continue::
        end
    end,
    -- Prints out the board
    print = function(self)
        io.write('\n8  ')

        for i, v in ipairs(self.pieces) do
            if v ~= INVALID then
                io.write(' ', pieceCharCodes[v * self.colors[i]])
                if i % 10 == 9 and i ~= 99 then
                    io.write('\n', 10 - math.ceil(i / 10), '  ')
                end
            end
        end

        io.write('\n\n    a b c d e f g h\n')
    end,
    --

}

return Board
