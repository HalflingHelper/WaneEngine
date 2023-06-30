-- Negamax with alpha-beta pruning!
-- https://en.wikipedia.org/wiki/Negamax

--Maybe change from a negamax to just and ABMax and AB min function, with search as an entry point that just takes board, side, and debug as arguments.


--[[
    Search Function
    Returns the evaluation of the position and the best move
    Returns the best move in the position. If there are no legal moves, returns nil
    If debug is true, then prints the line
]]
function search(board, alpha, beta, depth, debug)
    if depth == 0 then return board:eval() end

    local moveList = board:genMoves()
    local best = nil

    for i, move in ipairs(moveList) do
        if board:makeMove(move) then
            local score = -search(board, -beta, -alpha, depth - 1, debug)
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
