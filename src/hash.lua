-- Storage for the random numberes used by get_hash()
local hashPiece = {}
local hashCastle = {nil, nil, nil, nil}
local hashSide    --Number that gets added if it is black to move
local hashEp = {} --Unique 

-- Initializes the random numbers used by get_hash()
-- Must be called before using get hash
function init_hash()
    math.random()
end

-- Additive zobrist hash for the given board index
-- https://www.chessprogramming.org/Zobrist_Hashing 
function get_hash(board)
    local hash = 0

    local hashIdx = 1
    -- Pieces
    for boardIdx = 22, 99 do
        if board.colors[boardIdx] ~= INVALID then
            

            hashIdx = hashIdx + 1
        end

    end 
    -- Side
    if board.data.side == BLACK then hash = hash + hashSide end
    -- EnPassant
    if board.data.ep ~= -1 then hash = hash + hashEp[board.data.ep] end
    -- Castling rights
    local castleIdx = 1
    for i, v in pairs(board.data.castle) do
        if v then hash = hash + hashCastle[i] end
        castleIdx = castleIdx + 1
    end

    return hash
end
