-- Contains test functions (perft) and a series of instructions for running tests

--[[
    A Perft function for testing purposes
    Walks the move generation tree to depth depth, and counts the number of strictly legal moves

    Implementation : https://www.chessprogramming.org/Perft
    Expected output: https://www.chessprogramming.org/Perft_Results
]]

function perft(depth)
    if depth == 0 then return 0 end

    local nodes = 0

    --moves = genLegalMoves()
    -- for every move in moves
        -- make the move
        -- nodes += perft(depth - 1)
        -- undo the move

    return nodes
end