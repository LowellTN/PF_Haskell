import System.FilePath (takeDirectory, takeFileName, (</>))
import System.Environment (getArgs)
import Data.List.Split (splitOn)
import Data.List (intercalate)

import qualified RLE
import qualified Huffman
import qualified BWT


main :: IO()
main = do
    args <- getArgs
    case args of
        ["-c", filePath, algoString] -> compress filePath (parseAlgorithms algoString)
        ["-d", filePath] -> decompressFromFile filePath
        _ -> putStrLn "Usage:\n  Compress: cabal run Main.hs -- -c <filepath> <algorithms>\n  Decompress: cabal run Main.hs -- -d <filepath>\nExample: cabal run Main.hs -- -c test_files/file10B.txt huffman-bwt-rle-huffman"


parseAlgorithms :: String -> [String]
parseAlgorithms = splitOn "-"

-- Count how many metadata lines each algorithm needs
countMetadataLines :: String -> Int
countMetadataLines "huffman" = 1
countMetadataLines "bwt" = 1
countMetadataLines "rle" = 0
countMetadataLines algo = error $ "Unknown algorithm: " ++ algo


compress :: FilePath -> [String] -> IO ()
compress filePath algos = do
    content <- readFile filePath
    let dir = takeDirectory filePath
    let fileName = takeFileName filePath
    let outputPath = dir </> ("compressed_" ++ fileName)
    
    (metadata, compressed) <- applyAlgorithms algos content
    let algoChain = intercalate "-" algos
    writeFile outputPath (algoChain ++ "\n" ++ metadata ++ compressed)
    putStrLn $ "Compressed " ++ filePath ++ " -> " ++ outputPath ++ " using: " ++ algoChain


decompressFromFile :: FilePath -> IO ()
decompressFromFile filePath = do
    content <- readFile filePath
    let contentLines = lines content
    case contentLines of
        (algoChain:rest) -> do
            let algos = parseAlgorithms algoChain
            
            let dir = takeDirectory filePath
            let fileName = takeFileName filePath
            let outputPath = dir </> ("decompressed_" ++ fileName)
            
            -- Extract metadata and content
            let totalMetadataLines = sum (map countMetadataLines algos)
            let metadata = take totalMetadataLines rest
            let contentLine = rest !! totalMetadataLines
            
            decompressed <- applyDecompression (reverse algos) metadata contentLine
            writeFile outputPath decompressed
            putStrLn $ "Decompressed " ++ filePath ++ " -> " ++ outputPath ++ " using: " ++ algoChain
        _ -> error "Invalid compressed file format: missing algorithm chain"


-- Returns (metadata, content) where metadata is stored but not passed to next algorithm
applyAlgorithms :: [String] -> String -> IO (String, String)
applyAlgorithms [] content = return ("", content)
applyAlgorithms ("huffman":rest) content = do
    let (treeStr, bitStr) = Huffman.encode content
    (restMeta, restContent) <- applyAlgorithms rest bitStr
    return (treeStr ++ "\n" ++ restMeta, restContent)
applyAlgorithms ("rle":rest) content = do
    let encoded = RLE.encode content
    applyAlgorithms rest encoded
applyAlgorithms ("bwt":rest) content = do
    let (idx, encoded) = BWT.encode content
    (restMeta, restContent) <- applyAlgorithms rest encoded
    return (show idx ++ "\n" ++ restMeta, restContent)
applyAlgorithms (algo:_) _ = error $ "Unknown algorithm: " ++ algo


-- Takes metadata lines and the final content line
-- Metadata is consumed from the back (reverse order of algorithms)
applyDecompression :: [String] -> [String] -> String -> IO String
applyDecompression [] [] content = return content
applyDecompression [] (_:_) content = return content  -- Extra metadata, just ignore and return content
applyDecompression ("huffman":rest) metadata content = do
    case reverse metadata of
        (treeStr:restMeta) -> do
            let decoded = Huffman.decode treeStr content
            applyDecompression rest (reverse restMeta) decoded
        _ -> error "Invalid Huffman encoded content: missing tree"

applyDecompression ("rle":rest) metadata content = do
    let decoded = RLE.decode content
    applyDecompression rest metadata decoded

applyDecompression ("bwt":rest) metadata content = do
    case reverse metadata of
        (idxStr:restMeta) -> do
            let decoded = BWT.decode (read idxStr :: Int) content
            applyDecompression rest (reverse restMeta) decoded
        _ -> error "Invalid BWT encoded content: missing index"

applyDecompression (algo:_) _ _ = error $ "Unknown algorithm: " ++ algo