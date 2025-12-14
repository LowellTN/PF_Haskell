module RLE (encode, decode) where

import System.FilePath (takeDirectory, takeFileName, (</>))


-- Escape special characters for tree serialization
escapeChar :: Char -> String
escapeChar '\n' = "\\n"
escapeChar '\\' = "\\\\"
escapeChar '(' = "\\("
escapeChar ')' = "\\)"
escapeChar c = [c]


-- Unescape characters when parsing tree
unescapeChar :: String -> (Char, String)
unescapeChar ('\\':'n':rest) = ('\n', rest)
unescapeChar ('\\':'\\':rest) = ('\\', rest)
unescapeChar ('\\':'(':rest) = ('(', rest)
unescapeChar ('\\':')':rest) = (')', rest)
unescapeChar (c:rest) = (c, rest)
unescapeChar [] = error "Expected character but reached end"


encodeHelper :: String -> Char -> Int -> String
encodeHelper [] c n
    | n > 4 = "(" ++ show n ++ ")" ++ escapeChar c
    | otherwise = concat (replicate n (escapeChar c))
encodeHelper (x:xs) c n
    | x == c = encodeHelper xs c (n+1)
    | n > 4 = "(" ++ show n ++ ")" ++ escapeChar c ++ encodeHelper xs x 1
    | otherwise = concat (replicate n (escapeChar c)) ++ encodeHelper xs x 1


encode :: String -> String
encode [] = []
encode (x:xs) = encodeHelper xs x 1


decode :: String -> String
decode [] = []
decode ('(':xs) =
    let (numStr, rest) = span (/= ')') xs
        count = read numStr :: Int
        (char, remaining) = unescapeChar (tail rest)  -- skip ')'
    in replicate count char ++ decode remaining
decode s =
    let (char, rest) = unescapeChar s
    in char : decode rest