module RLE (encode, decode) where

import System.FilePath (takeDirectory, takeFileName, (</>))


-- Échappe les caractères spéciaux pour la sérialisation
escapeChar :: Char -> String
escapeChar '\n' = "\\n"
escapeChar '\\' = "\\\\"
escapeChar '(' = "\\("
escapeChar ')' = "\\)"
escapeChar c = [c]


-- Déséchappe les caractères lors du parsing
unescapeChar :: String -> (Char, String)
unescapeChar ('\\':'n':rest) = ('\n', rest)
unescapeChar ('\\':'\\':rest) = ('\\', rest)
unescapeChar ('\\':'(':rest) = ('(', rest)
unescapeChar ('\\':')':rest) = (')', rest)
unescapeChar (c:rest) = (c, rest)
unescapeChar [] = error "Expected character but reached end"


-- Fonction auxiliaire récursive pour l'encodage RLE
-- Compte les répétitions et encode en (n)char si n > 4, sinon répète le char
encodeHelper :: String -> Char -> Int -> String
encodeHelper [] c n
    | n > 4 = "(" ++ show n ++ ")" ++ escapeChar c
    | otherwise = concat (replicate n (escapeChar c))
encodeHelper (x:xs) c n
    | x == c = encodeHelper xs c (n+1)
    | n > 4 = "(" ++ show n ++ ")" ++ escapeChar c ++ encodeHelper xs x 1
    | otherwise = concat (replicate n (escapeChar c)) ++ encodeHelper xs x 1


-- Encode une chaîne avec l'algorithme RLE (Run-Length Encoding)
encode :: String -> String
encode [] = []
encode (x:xs) = encodeHelper xs x 1


-- Décode une chaîne encodée en RLE
-- Lit les nombres entre parenthèses et répète les caractères
decode :: String -> String
decode [] = []
decode ('(':xs) =
    let (numStr, rest) = span (/= ')') xs
        count = read numStr :: Int
        (char, remaining) = unescapeChar (tail rest)
    in replicate count char ++ decode remaining
decode s =
    let (char, rest) = unescapeChar s
    in char : decode rest