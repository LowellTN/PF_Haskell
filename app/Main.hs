import System.FilePath (takeDirectory, takeFileName, (</>))

import qualified RLE
import qualified Huffman


main :: IO()
main = do
    -- test: Huffman puis RLE
    -- compression
    let file_name = "test_files/file50KB.txt"
    content <- readFile file_name

    let dir = takeDirectory file_name
    let fileName = takeFileName file_name
    let outputPath = dir </> ("compressed_" ++ fileName)

    let (treeStr, bitStr) = Huffman.compress content
    writeFile outputPath (treeStr ++ "\n" ++ RLE.compress bitStr)

    -- decompression
    let file_name = "test_files/compressed_file2.txt"
    content <- readFile file_name

    let dir = takeDirectory file_name
    let fileName = takeFileName file_name
    let outputPath = dir </> ("decompressed_" ++ fileName)

    let contentLines = lines content
    case contentLines of
        treeStr:rleBitStr:[] -> writeFile outputPath (Huffman.decompress treeStr (RLE.decompress rleBitStr))
        _ -> error "misencoded Huffman into RLE"