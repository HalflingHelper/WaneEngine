-- Storage for the random numberes used by get_hash()
local hashPiece = {}
local hashCastle = { nil, nil, nil, nil }
local hashSide    --Number that gets added if it is black to move
local hashEp = {} --Unique

local HASH_MAX = 2 ^ 60

-- TODO: Write my ownn RNG?

local function boardTo64(n)
    return (math.floor(n / 10) - 2) * 8 + n % 10 - 1
end

-- Initializes the random numbers used by get_hash()
-- Must be called before using get hash
function init_hash()
    for i = 1, 64 do
        hashPiece[i] = {}
        hashEp[i] = math.random(HASH_MAX)
        for j = 1, 6 do
            hashPiece[i][j] = {}
            for k = 1, 2 do
                hashPiece[i][j][k] = math.random(HASH_MAX)
            end
        end
    end

    for i = 1, 4 do
        hashCastle[i] = math.random(HASH_MAX)
    end

    hashSide = math.random(HASH_MAX)
end

-- zobrist hash for the given board index
-- https://www.chessprogramming.org/Zobrist_Hashing
function get_hash(board)
    local hash = 0

    local hashIdx = 1
    -- Pieces
    for boardIdx = 22, 99 do
        if board.colors[boardIdx] ~= INVALID then
            if board.colors[boardIdx] ~= EMPTY then
                local colorIdx = math.floor(board.colors[boardIdx] / 2 + 1.5)
                hash = hash ~ hashPiece[hashIdx][board.pieces[boardIdx]][colorIdx]
            end
            hashIdx = hashIdx + 1
        end
    end
    -- Side
    if board.data.side == BLACK then hash = hash ~ hashSide end
    -- EnPassant

    if board.data.ep ~= -1 then
        hash = hash ~ hashEp[boardTo64(board.data.ep)]
    end
    -- Castling rights
    local castleIdx = 1
    for i, v in pairs(board.data.castle) do
        if v then hash = hash + hashCastle[castleIdx] end
        castleIdx = castleIdx + 1
    end

    return hash
end
