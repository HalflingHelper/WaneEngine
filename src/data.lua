--Variables describing piece movement and shit

--Global variables to track piece color and type
WHITE = 1
BLACK = -1

EMPTY = 0
PAWN = 1
KNIGHT = 2
BISHOP = 3
ROOK = 4
QUEEN = 5
KING = 6
INVALID = 7

--Move flags
CASTLE_FLAG = 1
CAPTURE_FLAG = 2
EP_FLAG = 3

-- Point values
pieceValue = {
    [PAWN] = 100,
    [KNIGHT] = 250,
    [BISHOP] = 350,
    [ROOK] = 500,
    [QUEEN] = 900,
    [KING] = 0, --King is ignored
}

-- Char codes used for drawing to the output display
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

--Literally just the reverse of the above array to make FEN conversion easier :/
charCodesToPiece = {
    ['.'] = EMPTY,
    ['p'] = -PAWN,
    ['n'] = -KNIGHT,
    ['b'] = -BISHOP,
    ['r'] = -ROOK,
    ['q'] = -QUEEN,
    ['k'] = -KING,
    ['P'] = PAWN,
    ['N'] = KNIGHT,
    ['B'] = BISHOP,
    ['R'] = ROOK,
    ['Q'] = QUEEN,
    ['K'] = KING,
}

slide = { false, false, true, true, true, false } --Do the pieces move multiple spaces or not

offset = {
    {},                                 --PAWN - Nothing because it is special
    { -21, -19, -12, -8, 8, 12, 19, 21 }, --KNIGHT
    { -11, -9,  9,   11 },              --BISHOP
    { -10, -1,  1,   10 },              --ROOK
    { -11, -10, -9,  -1, 1, 9,  10, 11 }, --QUEEN
    { -11, -10, -9,  -1, 1, 9,  10, 11 }, --KING
}


--Data for the initial state of the board
initPieces = {
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK, INVALID,
    INVALID, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, PAWN, INVALID,
    INVALID, ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
}

initColors = {
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, INVALID,
    INVALID, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, BLACK, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, INVALID,
    INVALID, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, INVALID,
    INVALID, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, WHITE, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
    INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID, INVALID,
}

initBoardData = {
    ep             = -1,    -- En Passant is set to the index of the potential targeted square
    castle         = { wq = true, wk = true, bq = true, bk = true },
    side           = WHITE, -- White goes first
    fiftyMoveCount = 0,
    fullMoves      = 1,
    hist           = {}     -- Table of tables for each section of the fifty move rule
}
