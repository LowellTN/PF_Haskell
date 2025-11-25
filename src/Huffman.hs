


main :: IO()
main = do
    content <- readFile "file.txt"
    putStrLn ("File content: " ++ content)
    let nodes = getBaseNodes content
    putStrLn (show nodes)
    let tree = treeConstruct nodes
    putStrLn (show tree)


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