module Game (Tile, Board, Move(..), initial, set, randomDrop, move, locations, endGame, showBoard) where


import Data.Char (toUpper)
import Data.List (group, transpose, intercalate)
import Data.Maybe (isJust, isNothing)

import Numeric (showHex)

import System.Random (RandomGen, next)


type Tile = Maybe Int

-- TODO use fixed size array?
type Board = [[Tile]]

data Move = Left | Right | Up | Down deriving (Show)


initial :: Board
initial = rep 4 $ rep 4 Nothing
    where rep n e = take n $ repeat e


set :: Tile -> (Int, Int) -> Board -> Board
set nt (y, x) b =
    [
        if i /= y then r
        else [
            if j /= x then t
            else nt
            | (j, t) <- zip [0..] r
        ]
        | (i, r) <- zip [0..] b
    ]


-- TODO add a chance for a 4 to spawn
randomDrop :: (RandomGen g) => g -> Board -> (g, Board)
randomDrop g b = (g2, set (Just 1) c b)
    where
        ls = locations b
        (g2, c) = randomEmptyLocation g b


randomEmptyLocation :: (RandomGen g) => g -> Board -> (g, (Int, Int))
randomEmptyLocation g b = (g2, (fst . (!! idx)) els)
    where
        els = (filter (isNothing . snd) . locations) b
        (idx, g2) = let (i, g2) = (next g) in (i `mod` (length els), g2)


locations :: Board -> [((Int, Int), Tile)]
locations = concat . map (\(i, r) -> [((i, j), t) | (j, t) <- zip [0..] r]) . zip [0..]


move :: Move -> Board -> Board
move Game.Left =         -- slide and merge row by row
    map slideAndMerge
move Game.Right =        -- slide and merge row by row in the reversed order
    map (reverse . slideAndMerge . reverse)
move Game.Up =           -- slide and merge left after transposing
    transpose . move Game.Left . transpose
move Game.Down =         -- slide and merge right after transposing
    transpose . move Game.Right . transpose


-- always slides to the left
slideAndMerge :: [Tile] -> [Tile]
slideAndMerge ts = (pad n . concat . map merged . group . filter isJust) ts
    where
        pad :: Int -> [Tile] -> [Tile]
        pad n xs = xs <> (take (n - length xs) (repeat Nothing))

        merged :: [Tile] -> [Tile]
        merged [] = []
        merged (t : []) = [t]
        merged (t1 : t2 : tg) = [(+1) <$> t1] <> merged tg

        n = length ts


endGame :: Board -> Bool
endGame b = all (== b) $ map (\s -> move s b) [Game.Left, Game.Right, Game.Up, Game.Down]


showBoard :: Board -> String
showBoard b =
    intercalate "\n" (showRow <$> b)
    where
        showRow :: [Tile] -> String
        showRow r = intercalate " " (showTile <$> r)

        showTile :: Tile -> String
        showTile (Just n) = toUpper <$> (showHex n "")
        showTile Nothing  = "_"

