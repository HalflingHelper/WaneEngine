--The engine's core board representation, using a 10x12 board, and partially inspired by TSCP engine
require 'util'
require 'data'
require 'move'

-- The Main Board Class
local Board = {
    --Fields in Board
    board = {},
    data = {},
    moveList = {},
    --Sets the board and flags in their initial states
    init = function(self)
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
    --[[
        Returns true if square is a valid target for pawn captures
    ]] --
    checkPawnCaps = function(self, square)
        return self.board[square] ~= INVALID and self.board[square] ~= EMPTY and
            signum(self.board[square]) ~= self.data.side
            or self.data.ep == square
    end,
    --Generates all available pseudo legal moves in the position for the current color
    genMoves = function(self)
        local list = {}
        --Iterate over every square on the board
        for i, square in ipairs(self.board) do
            --If the piece is the correct color
            if (square == INVALID or square == EMPTY or signum(square) ~= self.data.side) then goto continue end

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
                            list[#list + 1] = move(i, to - pawnDist * self.data.side, 0)
                        end
                    end
                end

                -- Check Captures in both directions
                if self:checkPawnCaps(to + 1) then list[#list + 1] = move(i, to + 1, CAPTURE_FLAG) end
                if self:checkPawnCaps(to - 1) then list[#list + 1] = move(i, to - 1, CAPTURE_FLAG) end
            elseif pieceID == KING then
                -- Castling moves and king moves
                for j, dir in ipairs(offset[pieceID]) do
                    --Normal King moves
                    if self.board[i + dir] == EMPTY or (self.board[i + dir] ~= INVALID and signum(self.board[i + dir]) ~= self.data.side) then
                        list[#list + 1] = move(i, i + dir, 0)
                    end
                end

                local c = self.data.castle

                --Queenside castling
                if self.data.side == WHITE and c.wq or self.data.side == BLACK and c.bq then
                    -- Check and add QC move
                    if self.board[i - 3] == EMPTY and self.board[i - 2] == EMPTY and self.board[i - 1] == EMPTY then
                        list[#list + 1] = move(i, i - 2, CASTLE_FLAG)
                    end
                end

                --Kingside castling
                if self.data.side == WHITE and c.wk or self.data.side == BLACK and c.bk then
                    -- Check and add KC move
                    if self.board[i + 2] == EMPTY and self.board[i + 1] == EMPTY then
                        list[#list + 1] = move(i, i + 2, CASTLE_FLAG)
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
                                list[#list + 1] = move(i, to, 0)
                            elseif self.board[to] == INVALID or signum(self.board[to]) == self.data.side then
                                -- We run into an allied piece or the edge of the board
                                break
                            else
                                -- We're capturing a piece and there aren't any more moves
                                list[#list + 1] = move(i, to, CAPTURE_FLAG)
                                break
                            end
                        end
                    end
                else
                    --Horses
                    for j, dir in ipairs(offset[pieceID]) do
                        if self.board[i + dir] == EMPTY or (self.board[i + dir] ~= INVALID and signum(self.board[i + dir]) ~= self.data.side) then
                            local moveFlags = signum(self.board[i + dir]) == -1 * self.data.side and CAPTURE_FLAG or 0

                            list[#list + 1] = move(i, i + dir, moveFlags)
                        end
                    end
                end
            end

            ::continue::
        end

        self.moveList = list
    end,
    --[[
        TODO:
        Returns true if the square at said sqIndex is attacked by pieces of the opposite color
    ]]
    isAttacked = function(self, idx)
        --Look for knights
        for i, dir in ipairs(offset[KNIGHT]) do
            if math.abs(self.board[idx + dir]) == KNIGHT and signum(self.board[idx + dir]) ~= self.data.side then
                return true
            end
        end
        --Look for sliding pieces (rook, bishop, queen)
        for i, dir in ipairs(offset[BISHOP]) do
            for dist = 1, 8 do
                local to = idx + dist * dir
                if self.board[to] == INVALID or signum(self.board[to]) == self.data.side then
                    -- We run into an allied piece or the edge of the board
                    break
                end

                local pieceType = math.abs(self.board[to])
                if pieceType == BISHOP or pieceType == QUEEN or (dist == 1 and pieceType == KING) then
                    return true
                end
            end
        end

        for i, dir in ipairs(offset[ROOK]) do
            for dist = 1, 8 do
                local to = idx + dist * dir
                if self.board[to] == INVALID or signum(self.board[to]) == self.data.side then
                    -- We run into an allied piece or the edge of the board
                    break
                end

                local pieceType = math.abs(self.board[to])
                if pieceType == ROOK or pieceType == QUEEN or (dist == 1 and pieceType == KING) then
                    return true
                end
            end
        end
        -- Look for pawns, going in the opposite direct of self.side
        local candidate
        -- Pawns to the left
        candidate = self.board[idx - 11 * self.data.side]
        if signum(candidate) ~= self.data.side and math.abs(candidate) == PAWN then
            return true
        end
        -- Pawns to the right
        candidate = self.board[idx - 9 * self.data.side]
        if signum(candidate) ~= self.data.side and math.abs(candidate) == PAWN then
            return true
        end
        -- We didn't find anything
        return false
    end,
    --[[
        Scans the board to see if the current side's king is in check in the current position.
        Used for determining the legality of moves.
    ]]
    inCheck = function(self)
        -- Find the king
        for i, square in ipairs(self.board) do
            if math.abs(square) == KING and signum(square) == self.data.side then
                -- Returns true if the square the king is on is attacked
                return self:isAttacked(i)
            end
        end
        -- Unreachable
        return false
    end,
    --[[
        TODO: Add stuff for making sure a move isn't illegal because of checks
        Makes the listed move on the board
        If the move is illegal, it undoes whatever it did and returns false. Otherwise, it returns true.
    ]]
    makeMove = function(self, move)
        --Make sure that move exists in the move list
        for i, v in ipairs(self.moveList) do
            if not moveEqual(v, move) then goto continue end

            local pieceType = math.abs(self.board[move.from])
            local pieceColor = signum(self.board[move.from])

            -- Make the move on the board
            self.board[move.to] = self.board[move.from]
            self.board[move.from] = EMPTY

            --Check that the king isn't directly in check, otherwise undo the move and return false
            if self:inCheck() then
                self.board[move.from] = self.board[move.to]
                self.board[move.to] = EMPTY
                return false
            end

            self.data.side = -1 * self.data.side

            -- Castling checks
            if pieceType == KING and math.abs(move.from - move.to) >= 2 then
                --TODO: Check squares in between

                if move.to > move.from then
                    --We want the KS rook
                    self.board[move.to - 1] = self.board[move.to + 1]
                    self.board[move.to + 1] = EMPTY
                else
                    --We want the QS rook
                    self.board[move.to + 1] = self.board[move.to - 2]
                    self.board[move.to - 2] = EMPTY
                end
            end

            --Update castle flags
            --TODO: Need to be careful here
            if pieceType == KING then
                if pieceColor == BLACK then
                    self.data.castle.bq = false
                    self.data.castle.bk = false
                else
                    self.data.castle.wq = false
                    self.data.castle.wk = false
                end
            end

            if pieceType == ROOK then
                if move.from == 22 then
                    self.data.castle.bq = false
                elseif move.from == 29 then
                    self.data.castle.bk = false
                elseif move.from == 92 then
                    self.data.castle.wq = false
                elseif move.from == 99 then
                    self.data.castle.wk = false
                end
            end

            -- Remove the piece if the move was an EP capture'
            if pieceType == PAWN and move.to == self.data.ep then
                self.board[move.to + 10 * signum(move.from - move.to)] = EMPTY
            end

            -- En Passant Checks
            --Update EP flags if the move is a double pawn push
            if pieceType == PAWN and math.abs(move.to - move.from) == 20 then
                --Set the en passant flag to the targeted square
                self.data.ep = move.to + 10 * signum(move.from - move.to)
            else
                -- Reset the en passant flag
                self.data.ep = -1
            end

            --Update 50 move counter
            if pieceType == PAWN or move.flags == CAPTURE_FLAG then
                self.data.fiftyMoveRule = 0
            end

            self.data.fiftyMoveRule = self.data.fiftyMoveRule + 1
            -- If current side is white black just moved
            if self.data.side == WHITE then self.data.fullMoves = self.data.fullMoves + 1 end

            printMove(move)
            do return true end

            ::continue::
        end

        -- Return false if the move isn't in the move list
        return false
    end,
    -- Returns the FEN string representation of the board
    -- I am aware that this isn't the best way to do this sort of thing but oh well
    -- TODO: En Passant!
    toFEN = function(self)
        local fen = ""

        --Pieces
        local numEmpty = 0
        local sq = 0
        for i, v in ipairs(self.board) do
            if v ~= INVALID then
                if v == EMPTY then
                    numEmpty = numEmpty + 1
                else
                    if numEmpty ~= 0 then
                        fen = fen .. numEmpty
                        numEmpty = 0
                    end
                    fen = fen .. pieceCharCodes[v]
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
            fen = fen .. " w "
        else
            fen = fen .. " b "
        end
        --Castle rights
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
    fromFEN = function(self, fen)
        local stage = 0
        local sqIndex = 22
        for c in fen:gmatch(".") do
            if c == " " then
                stage = stage + 1
                goto continue
            end

            if stage == 0 then
                if tonumber(c) then
                    --Empty squares
                    for sq = sqIndex, sqIndex + tonumber(c) - 1 do
                        self.board[sq] = EMPTY
                    end
                    sqIndex = sqIndex + tonumber(c)
                elseif c == "/" then
                    sqIndex = sqIndex + 2
                else
                    self.board[sqIndex] = charCodesToPiece[c]
                    sqIndex = sqIndex + 1
                end

                
            elseif stage == 1 then
                --Piece colors
                self.data.side = c == "w" and WHITE or BLACK
            end
            ::continue::
        end
    end,

    print = function(self)
        io.write('\n8  ')

        for i, v in ipairs(self.board) do
            if v ~= INVALID then
                io.write(' ', pieceCharCodes[v])
                if i % 10 == 9 and i ~= 99 then
                    io.write('\n', 10 - math.ceil(i / 10), '  ')
                end
            end
        end

        io.write('\n\n    a b c d e f g h\n')
    end
}

return Board
