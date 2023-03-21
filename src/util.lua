--Utility functions that aren't in lua libraries

function signum(n)
    return (n > 0 and 1) or (n == 0 and 0) or -1
end

function getRank(n)
    return 8 - math.floor((n - 21) / 10)
end

function getFile(n)
    return n % 10 - 1
end