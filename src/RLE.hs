module RLE (compress, decompress) where

import System.FilePath (takeDirectory, takeFileName, (</>))


-- main :: IO()
-- main = do
--     -- compression
--     let file_name = "test_files/file2.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("compressed_" ++ fileName)

--     writeFile outputPath (compress content)


--     -- decompression
--     let file_name = "test_files/compressed_file2.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("decompressed_" ++ fileName)

--     writeFile outputPath (decompress content)


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


compressHelper :: String -> Char -> Int -> String
compressHelper [] c n
    | n > 2 = "(" ++ show n ++ ")" ++ escapeChar c
    | n == 2 = escapeChar c ++ escapeChar c
    | otherwise = escapeChar c
compressHelper (x:xs) c n
    | x == c = compressHelper xs c (n+1)
    | n > 2 = "(" ++ show n ++ ")" ++ escapeChar c ++ compressHelper xs x 1
    | n == 2 = escapeChar c ++ escapeChar c ++ compressHelper xs x 1
    | otherwise = escapeChar c ++ compressHelper xs x 1


compress :: String -> String
compress [] = []
compress (x:xs) = compressHelper xs x 1


decompress :: String -> String
decompress [] = []
decompress ('(':xs) =
    let (numStr, rest) = span (/= ')') xs
        count = read numStr :: Int
        (char, remaining) = unescapeChar (tail rest)  -- skip ')'
    in replicate count char ++ decompress remaining
decompress s =
    let (char, rest) = unescapeChar s
    in char : decompress rest