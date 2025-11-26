{-# OPTIONS_GHC -Wno-unused-top-binds #-}

import Data.List (sort)
import Data.Char (isDigit)

main :: IO()
main = do
    let s = "ABEACADABEA"
        code = encodebwt s
        decode = decodebwt code
    print (s, code, decode, s == decode)

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
    let rot = generateRotations string
        matRot = sortRotations rot
        index = findIndex string matRot
        code = encode matRot 
    in show index ++ code

-- Partie decodebwt()

-- Séparation de l'indice et de la chaine encodée
popIndex :: String -> (Int, String)
popIndex s = 
    let (index, chain) = span isDigit s
    in (read index :: Int, chain)

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
    let
        (i, c) = popIndex code
        init = initDecode c
        matrix = iterateDecode c init
    in matrix !! (i-1)