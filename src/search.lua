-- Negamax with alpha-beta pruning!
-- https://en.wikipedia.org/wiki/Negamax

function search(Board, alpha, beta, depth)
    if depth == 0 then return Board:eval() end

    local moveList = Board:genMoves()

    for i, move in ipairs(moveList) do
        if Board:makeLegalMove(move) then
            local score = -search(Board, -alpha, -beta, depth - 1)
            Board:takebackMove(move)

            if score >= beta then
                return beta
            end

            if score > alpha then
                alpha = score
            end
        end
    end
    
    return alpha
end