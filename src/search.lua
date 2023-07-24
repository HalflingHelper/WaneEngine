-- Negamax with alpha-beta pruning!
-- https://en.wikipedia.org/wiki/Negamax

--TODO: Quiescence instead of just calling the eval function

--[[ SearchRoot Function
    Searches the root node and returns the evaluation and the best move
    TODO: Iterative deepening
]]
function searchRoot(board, debug)
    local et = 0
    local start = os.clock()

    local alpha, best

    --for i = 1, 100 do
        alpha, best = negamax(board, -math.huge, math.huge, 5)
    local et = os.clock()
    print("Elapsed search time", et - start)
        --if os.clock() - start > 5 then
            return alpha, best
       -- end
   -- end
end


--[[
    Search Function
    Returns the evaluation of the position and the best move
    Returns the best move in the position. If there are no legal moves, returns nil
    If debug is true, then prints the line
]]
function negamax(board, alpha, beta, depth, debug)
    if depth == 0 then return board.data.side * board:eval() end

    local moveList = board:genMoves()
    local best = nil

    for i, move in ipairs(moveList) do
        if board:makeLegalMove(move) then
            local score = -negamax(board, -beta, -alpha, depth - 1, debug)
            board:takebackMove(move)

            if score >= beta then
                return beta
            end

            if score > alpha then
                alpha = score
                best = move
            end
            --Reset the move list to what it was before the move
            board.moveList = moveList
        end
    end

    if debug and best then printMove(best) end

    return alpha, best
end
