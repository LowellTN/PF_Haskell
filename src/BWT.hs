{-# OPTIONS_GHC -Wno-unused-top-binds #-}

import Data.List (sort)
import Data.Char (isDigit)
import System.FilePath (takeDirectory, takeFileName, (</>))

main :: IO()
main = do
    -- compression
    let file_name = "test_files/file.txt"
    content <- readFile file_name

    let dir = takeDirectory file_name
    let fileName = takeFileName file_name
    let outputPath = dir </> ("compressed_" ++ fileName)

    writeFile outputPath (encodebwt content)


    -- decompression
    let file_name = "test_files/compressed_file.txt"
    content <- readFile file_name

    let dir = takeDirectory file_name
    let fileName = takeFileName file_name
    let outputPath = dir </> ("decompressed_" ++ fileName)

    writeFile outputPath (decodebwt content)

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
    in map (uncurry Rotation ) indexed


-- Permet de récupérer l'index de la première rotation cont la chaîne correspond au string d'entrée
findIndex :: String -> [Rotation] -> Int
findIndex s rotations = 
    case [index r | r <- rotations, chain r == s] of
        (i:_) -> i
        [] -> error "String non trouvé"

-- Récupération de la dernière lettre de chaque rotation pour encoder
encode :: [Rotation] -> String
encode rotations = [last (chain r) | r <- rotations]

-- Succession des fonctions précédentes pour appliquer la transformée
encodebwt :: String -> String
encodebwt string = 
    let escapedString = concatMap escapeChar string  -- Échappe tous les caractères spéciaux pour endoder sur deux lignes
        rot = generateRotations escapedString
        matRot = sortRotations rot
        idx = findIndex escapedString matRot
        code = encode matRot 
    in show idx ++ "\n" ++ code

-- Partie decodebwt()

-- Séparation de l'indice et de la chaine encodée
popIndex :: String -> (Int, String)
popIndex s = 
    let split = lines s
        indexLine = head split
        chainLine = split !! 1
    in (read indexLine :: Int, chainLine)

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
decodebwt :: String -> String
decodebwt code =
    let (i, c) = popIndex code
        init = initDecode c
        matrix = iterateDecode c init
        escapedResult = matrix !! (i - 1)
    in unescapeString escapedResult

-- Fonction pour déséchapper toute une chaîne
unescapeString :: String -> String
unescapeString [] = []
unescapeString s = 
    let (c, rest) = unescapeChar s
    in c : unescapeString rest
