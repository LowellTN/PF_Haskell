module Huffman (encode, decode) where

import qualified Data.Map as Map
import System.FilePath (takeDirectory, takeFileName, (</>))


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


-- Crée un nouveau nœud avec un caractère et une fréquence de 1
newNode :: Char -> Node
newNode c = MkNode {
    left = Nothing,
    right =  Nothing,
    chars = [c],
    freq = 1
}


-- Ajoute un caractère à la liste de nœuds ou incrémente sa fréquence s'il existe déjà
addChar :: Char -> [Node] -> [Node]
addChar c [] = [newNode c]
addChar c (h:t) | h.chars == [c] = (h {freq = h.freq + 1}):t
                | otherwise = h:addChar c t


getBaseNodesRec :: String -> [Node] -> [Node]
getBaseNodesRec "" nodes = nodes
getBaseNodesRec (c:r) nodes = getBaseNodesRec r (addChar c nodes)


-- Construit la liste des nœuds de base avec les fréquences de chaque caractère
getBaseNodes :: String -> [Node]
getBaseNodes s = getBaseNodesRec s []


-- Fusionne deux nœuds en un nouveau nœud parent
mergeNodes :: Node -> Node -> Node
mergeNodes n1 n2 = MkNode (Just n1) (Just n2) (n1.chars ++ n2.chars) (n1.freq + n2.freq)


-- Trouve les deux nœuds avec les fréquences les plus basses et retourne le reste
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


-- Construit l'arbre de Huffman à partir d'une liste de nœuds
treeConstruct :: [Node] -> Node
treeConstruct [] = error "The node list is empty"
treeConstruct (h:[]) = h
treeConstruct (h:t) =
    let (n1, n2, nodes) = getTwoLowest (h:t)
    in treeConstruct (mergeNodes n1 n2 : nodes)


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


-- Convertit un arbre de Huffman en chaîne de caractères
treeToString :: Node -> String
treeToString node
    | isLeaf node = "L" ++ escapeChar (head (chars node))
    | otherwise = "I(" ++ treeToString (fromJust (left node)) ++ ")(" ++ treeToString (fromJust (right node)) ++ ")"
    where
        isLeaf (MkNode Nothing Nothing _ _) = True
        isLeaf _ = False
        fromJust (Just x) = x
        fromJust Nothing = error "Unexpected Nothing"


-- Parse une chaîne et reconstruit l'arbre de Huffman
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


-- Convertit une chaîne en arbre de Huffman
stringToTree :: String -> Node
stringToTree str = 
    let (tree, remaining) = parseTree str
    in if null remaining 
       then tree 
       else error ("Unexpected remaining characters: " ++ remaining)


-- Crée une table de correspondance entre caractères et codes binaires
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


-- Convertit une chaîne de caractères en chaîne de bits selon l'arbre de Huffman
getBitString :: String -> Node -> String
getBitString [] _ = []
getBitString content node = getBitStringRec content (getCharMap node "")


-- Décode une chaîne de bits en texte original à partir de l'arbre de Huffman
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


-- Encode une chaîne de caractères : retourne l'arbre sérialisé et la chaîne de bits
encode :: String -> (String, String)
encode content = 
    let tree = treeConstruct (getBaseNodes content) in
    (treeToString tree, getBitString content tree)


-- Décode une chaîne de bits à partir de l'arbre sérialisé
decode :: String -> String -> String
decode treeStr bitStr = getContentFromBitString bitStr (stringToTree treeStr)