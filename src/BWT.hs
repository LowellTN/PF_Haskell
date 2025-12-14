module BWT (encode, decode) where

import Data.List (sort)
import Data.Char (isDigit)
import System.FilePath (takeDirectory, takeFileName, (</>))

-- main :: IO()
-- main = do
--     -- compression
--     let file_name = "test_files/file10B.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("compressed_" ++ fileName)

--     let (i, c) = encode content
--     writeFile outputPath (show i ++ "\n" ++ c)


--     -- decompression
--     let file_name = "test_files/compressed_file10B.txt"
--     content <- readFile file_name

--     let dir = takeDirectory file_name
--     let fileName = takeFileName file_name
--     let outputPath = dir </> ("decompressed_" ++ fileName)

--     let contentLines = lines content
--     case contentLines of
--         idxStr:str:[] -> writeFile outputPath (decode (read idxStr :: Int) str)
--         _ -> error "misencoded BWT"

-- Escape special characters for tree serialization
escapeChar :: Char -> String
escapeChar '\n' = "\\n"
escapeChar '\\' = "\\\\"
escapeChar c = [c]


-- Unescape characters when parsing tree
unescapeChar :: String -> (Char, String)
unescapeChar ('\\':'n':rest) = ('\n', rest)
unescapeChar ('\\':'\\':rest) = ('\\', rest)
unescapeChar (c:rest) = (c, rest)
unescapeChar [] = error "Expected character but reached end"

-- Fonction pour déséchapper toute une chaîne
unescapeString :: String -> String
unescapeString [] = []
unescapeString s = 
    let (c, rest) = unescapeChar s
    in c : unescapeString rest

data Rotation = Rotation {
    index :: Int,
    chain :: String
}

instance Eq Rotation where
    r1 == r2 = chain r1 == chain r2

instance Ord Rotation where
    compare r1 r2 = compare (chain r1) (chain r2)

instance Show Rotation where
    show (Rotation i c) = "Rotation " ++ show i ++ " " ++ show c

-- Partie encodebwt()


-- Génère les rotation non ordonnées sous forme de tableau de string
generateRotations :: String -> [String]
generateRotations s = [rotate k s | k <- [0..length s - 1]]
    where
        rotate k str = drop k str ++ take k str


-- Ordonnement du tableau de string et passage de string à Rotation
sortRotations :: [String] -> [Rotation]
sortRotations matrix =
    let sorted = sort matrix
        indexed = zip [1..] sorted
    in map (uncurry Rotation) indexed


-- Permet de récupérer l'index de la première rotation cont la chaîne correspond au string d'entrée
findIndex :: String -> [Rotation] -> Int
findIndex s rotations = 
    case [index r | r <- rotations, chain r == s] of
        (i:_) -> i
        [] -> error "String non trouvé"

-- Récupération de la dernière lettre de chaque rotation pour encoder
findLastCharacters :: [Rotation] -> String
findLastCharacters rotations = [last (chain r) | r <- rotations]

-- Succession des fonctions précédentes pour appliquer la transformée
encode :: String -> (Int, String)
encode string = 
    let rot = generateRotations string
        matRot = sortRotations rot
        idx = findIndex string matRot
        code = findLastCharacters matRot 
    in (idx, concatMap escapeChar code)

-- Partie decodebwt()

-- Création d'un table au séparant chaque lettre de la chaîne
initDecode :: String -> [String]
initDecode s = [[c] | c <- s]

-- Boucle de l'algorithme pour créer la matrice finale
iterateDecode :: String -> [String] -> [String]
iterateDecode encoded split = 
    let add matrix = sort [c : s | (c, s) <- zip encoded (sort matrix)]
        iterations = iterate add split
    in iterations !! (length encoded - 1)

-- Decodage de la transformée
decode :: Int -> String -> String
decode i c =
    let un_c = unescapeString c
        init = initDecode un_c
        matrix = iterateDecode un_c init
        result = matrix !! (i - 1)
    in  result
