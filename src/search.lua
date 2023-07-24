-- Negamax with alpha-beta pruning!
-- https://en.wikipedia.org/wiki/Negamax

--TODO: Quiescence instead of just calling the eval function

-- Variables for tracking search timing
local start
local nodes
local MAX_SEARCH_TIME = 4
--[[ SearchRoot Function
    Searches the root node and returns the evaluation and the best move
    TODO: Iterative deepening
]]
function searchRoot(board, debug)
    start = os.clock()
    nodes = 0

    local alpha, best

    for i = 1, 100 do
        local val, b = negamax(board, -math.huge, math.huge, i)
        if val == 'a' then
            return alpha, best
        end
        alpha, best = val, b
   end

   return alpha, best
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
            local score = negamax(board, -beta, -alpha, depth - 1, debug)
            --Reset the move list to what it was before the move
            board:takebackMove(move)
            board.moveList = moveList
           
            if score == 'a' then return score, nil end
            score = -score


            if score >= beta then
                return beta
            end

            if score > alpha then
                alpha = score
                best = move
            end
        end
        nodes = (nodes + 1) % 1024
        if nodes == 0 and os.clock() - start > MAX_SEARCH_TIME then
            return 'a', nil
        end
    end

    if debug and best then printMove(best) end

    return alpha, best
end
