-- Contains test functions (perft) and a series of instructions for running tests

--[[
    A Perft function for testing purposes
    Walks the move generation tree to depth depth, and counts the number of strictly legal moves

    Implementation : https://www.chessprogramming.org/Perft
    Expected output: https://www.chessprogramming.org/Perft_Results
]]

function perft(board, depth)
    if depth == 0 then return 1 end

    local nodes = 0

    local moves = board:genMoves()

    for i, move in ipairs(board.moveList) do
        local preMove = board:toFEN()

        if board:makeMove(move) then
            nodes = nodes + perft(board, depth - 1)
            -- undo the move
            board:fromFEN(preMove)
        end
    end

    return nodes
end