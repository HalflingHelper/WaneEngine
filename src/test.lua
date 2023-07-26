-- Contains test functions (perft) and a series of instructions for running tests

--[[
    A Perft function for testing purposes
    Taking back moves in this implementation is terribly inneficient
    Walks the move generation tree to depth depth, and counts the number of strictly legal moves

    Implementation : https://www.chessprogramming.org/Perft
    Expected output: https://www.chessprogramming.org/Perft_Results
]]
function perft(board, depth, printDepth)
    if depth == 0 then return 1 end

    local nodes = 0

    local moves = board:genMoves()

    for i, move in ipairs(moves) do
        if board:makeMove(move) then
            if not board:inCheck() then
                local add =  perft(board, depth - 1, printDepth)
                nodes = nodes + add
                if depth == printDepth then print(moveToLAN(move), add) end
            end
            -- undo the move
            board:takebackMove(move)
            --Reset the move list to what it was before the move
            board.moveList = moves
        end
    end

    return nodes
end

--Results:
--  Starting Position
    --Depth 4: Correct in ~1.5 sec
    --Depth 5: Correct in ~45 sec

-- Kiwipete
    --Depth 4: Correct in 42.67 sec.