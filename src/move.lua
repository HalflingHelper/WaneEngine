--Move datatype and functions for move checking

--[[
    Returns a move!
    from, to - Indexes of the square the piece is moving from to the square the piece is moving to
    castle - the state of the castle flags before the move is made
    captured - the id of the captured piece
    epSq - the enPassant flag before the move is made
    promo - the value of piece promoted to
]]
function move(from, to, castle, captured, epSq, promo)
    local m = { from = from, to = to, captured = captured or EMPTY, epSq = epSq or -1, promo = promo or EMPTY}
    m.castle = {}
    if castle then
        for k, v in pairs(castle) do m.castle[k] = v end
    end
    return m
end

-- Returns true if two moves are the same!
-- Doesn't compare flags, only the squares that are being moved between
function moveEqual(m1, m2)
    return m1.from == m2.from and m1.to == m2.to and m1.promo == m2.promo
end

local function isValidRank(r)
    return r ~= nil and r >= 1 and r <= 8
end

local function isValidFile(f)
    return f >= 1 and f <= 8
end

-- Parses a move in Long Algebraic Notaion from the string to a move table
-- Expects two squares in algebraic notation
-- ex: e2e4
function parseMove(s)
    if #s < 4 then
        error("Please enter a move in the form '<from-square> <to-square>'", 0)
    end

    local fromFile = s:byte(1, 1) - 96
    local fromRank = tonumber(s:sub(2, 2))

    local toFile = s:byte(3, 3) - 96
    local toRank = tonumber(s:sub(4, 4))

    if not (isValidRank(fromRank) and isValidRank(toRank)) then
        error("Enter rank information as a number from 1 to 8", 0)
    end

    if not (isValidFile(fromFile) and isValidFile(toFile)) then
        error("Enter the file as a letter from 'a' to 'h'", 0)
    end

    local fromSquare = 120 - 19 - 10 * fromRank + fromFile
    local toSquare = 120 - 19 - 10 * toRank + toFile

    return move(fromSquare, toSquare)

    -- return move(tonumber(s:sub(1, 3)), tonumber(s:sub(3)), 0)
end

function moveToLAN(move)
    return sqToCoords(move.from) .. sqToCoords(move.to)
end

function printMove(move)
    print("from: " .. move.from .. ", to: " .. move.to)
end
