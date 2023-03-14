--Move datatype and functions for move checking

--[[
    Returns a move!
    from, to - Indexes of the square the piece is moving from to the square the piece is moving to
    flags encodes information about special kinds of moves: if a move is ep, castle, promotion
]]
function move(from, to, flags)
    return {from = from, to = to, flags = flags}
end

-- Returns true if two moves are the same!
function moveEqual(m1, m2)
    return m1.flags == m2.flags and m1.from == m2.from and m1.to == m2.to
end

--Parses a move in "from to noation" from the string to a move table
function parseMove(s)
    return move(tonumber(s:sub(1, 3)), tonumber(s:sub(3)), 0)

    --For Algebraic Notation
        --Find a piece code

        --Find the square that piece is on
        --Convert to index

        --See if there is a capture

        --Get the destination square
        --Convert to index




    --return -1
end