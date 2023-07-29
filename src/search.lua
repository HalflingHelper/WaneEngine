-- Negamax with alpha-beta pruning!
-- https://en.wikipedia.org/wiki/Negamax

--TODO: Quiescence instead of just calling the eval function

-- Variables for tracking search timing
local start
local nodes
local MAX_SEARCH_TIME = 4

-- Transposition table
-- Stuff is stored in the form [zobrist] = {alpha, depth}
local transposition = {}

--[[ SearchRoot Function
    Searches the root node and returns the evaluation and the best move
    TODO: Iterative deepening
]]
function searchRoot(board, debug)
    start = os.clock()
    nodes = 0

    local alpha, best

    for i = 1, 1000 do
        local val, b = negamax(board, -math.huge, math.huge, i)
        if val == 'a' then
            print("Search stopped at depth " .. i)
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

            --First check the transposition table
            local key = get_hash(board)
            local past = transposition[key]
            local score

            if past and past[2] >= depth then
                score = past[1]
            else
                score = negamax(board, -beta, -alpha, depth - 1, debug)
            end

            --Reset the move list to what it was before the move
            board:takebackMove(move)
            board.moveList = moveList
           
            if score == 'a' then return score, nil end

            transposition[key] = {score, depth}

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

--[[
    Runs the search function at the sepcified depth, disregarding timeouts and stuff like that.

    Results:

    Starting Position
        Depth 5: 1.33
        Depth 6: 10.44, 9.465, 5.889
    Kiwipete
        Depth 6: 6.071
]]
function testSearch(board, depth)
    nodes = 0
    start = math.huge --So the search never times out

    st = os.clock()
    negamax(board, -100000, 100000, depth)

    et = os.clock()
    print("Search benchmark for depth " .. depth .. ": " .. et - st)
end