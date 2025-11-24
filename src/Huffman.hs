


main :: IO()
main = do
    content <- readFile "file.txt"
    putStrLn content