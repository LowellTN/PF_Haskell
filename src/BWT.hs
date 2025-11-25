{-# OPTIONS_GHC -Wno-unused-top-binds #-}

import Data.List (sort)


main :: IO()
main = do
    let s = "ABEACADABEA"
        code = bwt s
    print code

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

generateRotations :: String -> [String]
generateRotations s = [rotate k s | k <- [0..length s - 1]]
  where
    rotate k str = drop k str ++ take k str

sortRotations :: [String] -> [Rotation]
sortRotations matrix =
    let sorted = sort matrix
        indexed = zip [1..] sorted
    in map (uncurry Rotation ) indexed

findIndex :: String -> [Rotation] -> Int
findIndex s rotations = 
    case [index r | r <- rotations, chain r == s] of
        (i:_) -> i
        [] -> error "String non trouvé"

newWord :: [Rotation] -> String
newWord rotations = [last (chain r) | r <- rotations]

bwt :: String -> String
bwt string = 
    let rot = generateRotations string
        matRot = sortRotations rot
        index = findIndex string matRot
        code = newWord matRot 
    in show index ++ code