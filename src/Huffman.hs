module Huffman (compress, decompress) where

import qualified Data.Map as Map
import System.FilePath (takeDirectory, takeFileName, (</>))


-- main :: IO()
-- main = do
--     -- compression
--     let file_name = "test_files/file.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("compressed_" ++ fileName)
--     let (treeStr, bitStr) = compress content
--     writeFile outputPath (treeStr ++ "\n" ++ bitStr)


--     -- decompression
--     let file_name = "test_files/compressed_file.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("decompressed_" ++ fileName)

--     writeFile outputPath (decompress content)


data Node = MkNode {
    left :: Maybe Node,
    right :: Maybe Node,
    chars :: String,
    freq :: Int
}


instance Show Node where
    show node = "(" ++ "[" ++ node.chars ++ ", " ++ show node.freq ++ "], " ++ showMaybeNode (left node) ++ ", " ++ showMaybeNode (right node) ++ ")"
        where
            showMaybeNode Nothing = "()"
            showMaybeNode (Just n) = show n


newNode :: Char -> Node
newNode c = MkNode {
    left = Nothing,
    right =  Nothing,
    chars = [c],
    freq = 1
}


addChar :: Char -> [Node] -> [Node]
addChar c [] = [newNode c]
addChar c (h:t) | h.chars == [c] = (h {freq = h.freq + 1}):t
                | otherwise = h:addChar c t


getBaseNodesRec :: String -> [Node] -> [Node]
getBaseNodesRec "" nodes = nodes
getBaseNodesRec (c:r) nodes = getBaseNodesRec r (addChar c nodes)


getBaseNodes :: String -> [Node]
getBaseNodes s = getBaseNodesRec s []


mergeNodes :: Node -> Node -> Node
mergeNodes n1 n2 = MkNode (Just n1) (Just n2) (n1.chars ++ n2.chars) (n1.freq + n2.freq)


getTwoLowest :: [Node] -> (Node, Node, [Node])
getTwoLowest [] = error "Need at least 2 nodes (got 0)"
getTwoLowest [_] = error "Need at least 2 nodes (got 1)"
getTwoLowest (n1:n2:rest) 
    | freq n1 < freq n2 = findTwo n1 n2 [] rest
    | otherwise = findTwo n2 n1 [] rest
    where
        findTwo min1 min2 acc [] = (min1, min2, acc)
        findTwo min1 min2 acc (x:xs)
            | freq x < freq min1 = findTwo x min1 (min2:acc) xs
            | freq x < freq min2 = findTwo min1 x (min2:acc) xs
            | otherwise = findTwo min1 min2 (x:acc) xs


treeConstruct :: [Node] -> Node
treeConstruct [] = error "The node list is empty"
treeConstruct (h:[]) = h
treeConstruct (h:t) =
    let (n1, n2, nodes) = getTwoLowest (h:t)
    in treeConstruct (mergeNodes n1 n2 : nodes)


-- Tree serialization format:
-- Leaf nodes: L<char>
-- Internal nodes: I(<left>)(<right>)
-- Example: I(La)(Lb)


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


treeToString :: Node -> String
treeToString node
    | isLeaf node = "L" ++ escapeChar (head (chars node))
    | otherwise = "I(" ++ treeToString (fromJust (left node)) ++ ")(" ++ treeToString (fromJust (right node)) ++ ")"
    where
        isLeaf (MkNode Nothing Nothing _ _) = True
        isLeaf _ = False
        fromJust (Just x) = x
        fromJust Nothing = error "Unexpected Nothing"


-- Parse a tree from string representation
parseTree :: String -> (Node, String)
parseTree ('L':rest) = 
    let (c, remaining) = unescapeChar rest
    in (MkNode Nothing Nothing [c] 0, remaining)
parseTree ('I':'(':rest) =
    let (leftNode, rest1) = parseTree rest
        rest2 = case rest1 of
            (')':'(':r) -> r
            [] -> error "Expected ')(' after left subtree but reached end of string"
            (')':_) -> error "Expected '(' after ')' but found different character"
            _ -> error "Expected ')(' after left subtree"
        (rightNode, rest3) = parseTree rest2
        rest4 = case rest3 of
            (')':r) -> r
            [] -> error "Expected ')' after right subtree but reached end of string"
            _ -> error "Expected ')' after right subtree"
        chars_combined = chars leftNode ++ chars rightNode
    in (MkNode (Just leftNode) (Just rightNode) chars_combined 0, rest4)
parseTree [] = error "Empty string in parseTree"
parseTree s = error ("Unexpected format in parseTree: " ++ take 10 s)


stringToTree :: String -> Node
stringToTree str = 
    let (tree, remaining) = parseTree str
    in if null remaining 
       then tree 
       else error ("Unexpected remaining characters: " ++ remaining)


getCharMap :: Node -> String -> Map.Map Char String
getCharMap (MkNode Nothing Nothing [c] _) code = Map.singleton c code
getCharMap (MkNode (Just l) (Just r) _ _) code = Map.union (getCharMap l (code ++ "0")) (getCharMap r (code ++ "1"))
getCharMap _ _ = error "Bad tree"


getBitStringRec :: String -> Map.Map Char String -> String
getBitStringRec [] _ = []
getBitStringRec (c:r) map = 
    case Map.lookup c map of
        Just bits -> bits ++ getBitStringRec r map
        Nothing -> error ("Character not found in map: " ++ [c])


getBitString :: String -> Node -> String
getBitString [] _ = []
getBitString content node = getBitStringRec content (getCharMap node "")


getContentFromBitString :: String -> Node -> String
getContentFromBitString bitString tree = decode bitString tree tree
    where
        decode [] (MkNode Nothing Nothing [c] _) _ = [c]
        decode [] _ _ = []
        decode remaining currentNode originalTree =
            case currentNode of
                MkNode Nothing Nothing [c] _ -> c : decode remaining originalTree originalTree
                MkNode (Just l) (Just r) _ _ ->
                    case remaining of
                        ('0':rest) -> decode rest l originalTree
                        ('1':rest) -> decode rest r originalTree
                        _ -> error "Invalid bit in string or bit string ended before reaching a leaf"
                _ -> error "Invalid tree structure"


compress :: String -> (String, String)
compress content = 
    let tree = treeConstruct (getBaseNodes content) in
    (treeToString tree, getBitString content tree)


decompress :: String -> String -> String
decompress treeStr bitStr = getContentFromBitString bitStr (stringToTree treeStr)