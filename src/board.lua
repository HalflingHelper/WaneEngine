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

        -- TODO: Just copy kv pairs from the thing in data.lua
        self.data.castle = { wq = true, wk = true, bq = true, bk = true }
        self.data.hash = { {} } --Initialzing hist with the first partition already
        -- Initialize the moveList as empty
        self.moveList = {}
    end,
    --[[
        Returns true if square is a valid target for pawn captures
        Valid squares either contain pieces of the opposing side or are targets for EnPassant
    ]]
    checkPawnCaps = function(self, square)
        return self.pieces[square] ~= INVALID and self.pieces[square] ~= EMPTY and
            self.colors[square] ~= self.data.side
            or self.data.ep == square
    end,
    --[[
        Generates all available pseudo-legal moves in the position for the current color
        Returns the board's moveList
    ]]
    genMoves = function(self)
        local list = {}
        --Iterate over every square on the board
        for i, piece in ipairs(self.pieces) do
            --If the piece is the correct color
            if self.colors[i] ~= self.data.side then goto continue end

            --TODO: Lots of repetition in generating pawn moves
            if piece == PAWN then
                -- Pawn Moves are specifies
                local pawnDist = 10
                local rank = getRank(i)
                local to = i - self.data.side * pawnDist

                local isPromo = (self.data.side == WHITE and rank == 7) or
                    (self.data.side == BLACK and rank == 2)

                -- Check pushes
                if self.pieces[to] == EMPTY then
                    -- Normal push
                    if isPromo then
                        for type = KNIGHT, QUEEN do
                            list[#list + 1] = move(i, to, self.data.castle, EMPTY, self.data.ep, type)
                        end
                    else
                        list[#list + 1] = move(i, to, self.data.castle, EMPTY, self.data.ep)
                    end
                    --Double push
                    if (self.data.side == WHITE and rank == 2) or (self.data.side == BLACK and rank == 7) then
                        if self.pieces[to - pawnDist * self.data.side] == EMPTY then
                            list[#list + 1] = move(i, to - pawnDist * self.data.side, self.data.castle, EMPTY,
                                self.data.ep)
                        end
                    end
                end

                -- Check Captures in both directions
                if self:checkPawnCaps(to + 1) then
                    if isPromo then
                        for type = KNIGHT, QUEEN do
                            list[#list + 1] = move(i, to + 1, self.data.castle, self.pieces[to + 1], self.data.ep,
                                type)
                        end
                    else
                        list[#list + 1] = move(i, to + 1, self.data.castle, self.pieces[to + 1], self.data.ep)
                    end
                end
                if self:checkPawnCaps(to - 1) then
                    if isPromo then
                        for type = KNIGHT, QUEEN do
                            list[#list + 1] = move(i, to - 1, self.data.castle, self.pieces[to - 1], self.data.ep,
                                type)
                        end
                    else
                        list[#list + 1] = move(i, to - 1, self.data.castle, self.pieces[to - 1], self.data.ep)
                    end
                end
            elseif piece == KING then
                -- Castling moves and king moves
                for j, dir in ipairs(offset[piece]) do
                    --Normal King moves
                    if self.pieces[i + dir] == EMPTY or (self.pieces[i + dir] ~= INVALID and self.colors[i + dir] ~= self.data.side) then
                        list[#list + 1] = move(i, i + dir, self.data.castle, self.pieces[i + dir], self.data.ep)
                    end
                end

                local c = self.data.castle

                --Queenside castling
                if self.data.side == WHITE and c.wq or self.data.side == BLACK and c.bq then
                    -- Check and add QC move
                    if self.pieces[i - 3] == EMPTY and self.pieces[i - 2] == EMPTY and self.pieces[i - 1] == EMPTY and self.pieces[i - 4] == ROOK then
                        list[#list + 1] = move(i, i - 2, self.data.castle, EMPTY, self.data.ep)
                    end
                end

                --Kingside castling
                if self.data.side == WHITE and c.wk or self.data.side == BLACK and c.bk then
                    -- Check and add KC move
                    if self.pieces[i + 2] == EMPTY and self.pieces[i + 1] == EMPTY and self.pieces[i + 3] == ROOK then
                        list[#list + 1] = move(i, i + 2, self.data.castle, EMPTY, self.data.ep)
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
                                list[#list + 1] = move(i, to, self.data.castle, EMPTY, self.data.ep)
                            elseif self.pieces[to] == INVALID or self.colors[to] == self.data.side then
                                -- We run into an allied piece or the edge of the board
                                break
                            else
                                -- We're capturing a piece and there aren't any more moves
                                list[#list + 1] = move(i, to, self.data.castle, self.pieces[to], self.data.ep)
                                break
                            end
                        end
                    end
                else
                    --Horses
                    for j, dir in ipairs(offset[piece]) do
                        if (self.pieces[i + dir] ~= INVALID and self.colors[i + dir] ~= self.data.side) then
                            list[#list + 1] = move(i, i + dir, self.data.castle, self.pieces[i + dir], self.data.ep)
                        end
                    end
                end
            end

            ::continue::
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
        self.data.side = self.data.side * -1

        local to, from = move.to, move.from

        for k, v in pairs(move.castle) do
            self.data.castle[k] = v
        end

        self.data.ep = move.epSq

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
        table.remove(self.data.hash[#self.data.hash])
        if #self.data.hash[#self.data.hash] == 0 and #self.data.hash > 1 then
            table.remove(self.data.hash)
        end
    end,
    --[[
        Makes the listed move on the board, doesn't check for legality
        If the move is illegal, it undoes whatever it did and returns false. Otherwise, it returns true.
        TODO: This only uses from to, and promo, maybe only add the extra information on the spot to save space until to move is actually made
            Add on the spot and add to a move history array?
    ]]
    makeMove = function(self, move)
        --Make sure that move exists in the move list
        for i, v in ipairs(self.moveList) do
            if not moveEqual(v, move) then goto continue end

            local to, from = move.to, move.from

            -- Noting some information about the move
            local pieceType = self.pieces[from]
            local pieceColor = self.colors[from]

            local isCapture = self.pieces[to] ~= EMPTY

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
                --Makes sure castling is valid
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
                    self.data.castle.bq = false
                    self.data.castle.bk = false
                else
                    self.data.castle.wq = false
                    self.data.castle.wk = false
                end
            elseif pieceType == ROOK then
                --Dismantling castle flags for rooks
                if from == 22 then
                    self.data.castle.bq = false
                elseif from == 29 then
                    self.data.castle.bk = false
                elseif from == 92 then
                    self.data.castle.wq = false
                elseif from == 99 then
                    self.data.castle.wk = false
                end
            end

            --Update EP flags if the move is a double pawn push
            if pieceType == PAWN and math.abs(to - from) == 20 then
                --Set the en passant flag to the targeted square
                self.data.ep = to + 10 * pieceColor
            else
                -- Reset the en passant flag
                self.data.ep = -1
            end

            --Update 50 move counter
            if pieceType == PAWN or isCapture then
                self.data.fiftyMoveCount = 0
                --Add a new partition to the history list
                self.data.hash[#self.data.hash + 1] = {}
            end

            self.data.fiftyMoveCount = self.data.fiftyMoveCount + 1

            -- If current side is white black just moved
            if self.data.side == WHITE then self.data.fullMoves = self.data.fullMoves + 1 end

            table.insert(self.data.hash[#self.data.hash], get_hash(self))

            --Wrapping the return in a do while so that lua doesn't scream
            do return true end

            ::continue::
        end

        -- Return false if the move isn't in the move list
        return false
    end,
    --[[
        Evaluates the position on the board. Currently Purely materialistic
    ]]
    eval = function(self)
        local e = 0
        for i, p in ipairs(self.pieces) do
            if p ~= EMPTY and p ~= INVALID then
                e = e + pieceValue[p] * self.colors[i]
            end
        end
        return e
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
        local curHash = self.data.hash[#self.data.hash][#self.data.hash[#self.data.hash]]
        local count = 0
        for i, hash in ipairs(self.data.hash[#self.data.hash]) do
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
    end
}

return Board
