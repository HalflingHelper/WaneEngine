--Evaluates the position on a board
return function(board)
    local materialCount = 0
    local centerScore = 0
    local mobilityWhite, mobilityBlack
    local mobilityWt = 0.1

    for i, p in ipairs(board.pieces) do
        if p ~= EMPTY and p ~= INVALID then
            materialCount = materialCount + pieceValue[p] * board.colors[i]
        end
    end

        --Control over central squares, where pawns are weighted higher
        for i, v in ipairs({ 55, 56, 65, 66 }) do
            --Pawns in the center
            if board.pieces[v] == PAWN then
                centerScore = centerScore + board.colors[v] * 100
            end
        end

    if board.data.side == WHITE then
        mobilityWhite = #board:genMoves()
        board.data.side = -board.data.side
        mobilityBlack = #board:genMoves()
        board.data.side = -board.data.side
    else
        mobilityBlack = #board:genMoves()
        board.data.side = -board.data.side
        mobilityWhite = #board:genMoves()
        board.data.side = -board.data.side
    end

    return materialCount + centerScore + mobilityWt * (mobilityWhite - mobilityBlack)
end
