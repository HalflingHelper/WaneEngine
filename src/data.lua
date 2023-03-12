--Variable describing piece movement and shit

--Global variables to track piece type
EMPTY = 0
PAWN = 1
KNIGHT = 2
BISHOP = 3
ROOK = 4
QUEEN = 5
KING = 6
INVALID = 7

pieceCharCodes = {
    [EMPTY] = '.',
    [-PAWN] = 'p',
    [-KNIGHT] = 'n',
    [-BISHOP] = 'b',
    [-ROOK] = 'r',
    [-QUEEN] = 'q',
    [-KING] = 'k',
    [PAWN] = 'P',
    [KNIGHT] = 'N',
    [BISHOP] = 'B',
    [ROOK] = 'R',
    [QUEEN] = 'Q',
    [KING] = 'K',
}

slide = {false, false, true, true, true, false} --Do the pieces move multiple spaces or not
--TODO: Check these on a 10x12 board
offset = {
    {}, --PAWN - Nothing because it isn't special
    {-21, -19, -12, -8, 8, 12, 19, 21}, --KNIGHT 
    {-11, -9, 9, 11}, --BISHOP
    {-10, -1, 1, 10}, --ROOK
    {-11, -10, -9, -1, 1, 9, 10, 11}, --QUEEN
    {-11, -10, -9, -1, 1, 9, 10, 11}, --KING
}


--Data for the initial state of the board
--Negative indicates black piece
initBoardState = {
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, -ROOK, -KNIGHT, -BISHOP, -QUEEN, -KING, -BISHOP, -KNIGHT, -ROOK, INVALID,
    INVALID, -PAWN, -PAWN, -PAWN, -PAWN, -PAWN, -PAWN, -PAWN, -PAWN, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, INVALID,
    INVALID, ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK, INVALID,
}