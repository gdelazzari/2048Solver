module Main where


import Data.Ord (comparing)
import Data.Maybe (isNothing, isJust, catMaybes)
import Data.List (maximum, maximumBy)
import Debug.Trace (traceShowId)
import System.Random (RandomGen, mkStdGen, getStdGen)


import qualified Game


score :: Int -> Game.Board -> Float
score depth b =
    if Game.endGame b then 0.0
    else if depth == 0 then
        let 
            sEmpty = length $ filter (isNothing . snd) $ Game.locations b
            sHighest = maximum $ catMaybes $ concat b
        in
        fromIntegral (sEmpty + sHighest * 4)
    else
        let
            ecs = map fst $ filter (isNothing . snd) $ Game.locations b
            p = 1 / (fromIntegral (length ecs) :: Float)
            moves = [Game.Left, Game.Right, Game.Up, Game.Down]
            withTileAt = Game.set (Just 1)
        in
        sum [p * snd (bestMove (depth - 1) (withTileAt ntc b)) | ntc <- ecs]


scoredMoves :: Int -> Game.Board -> [(Game.Move, Float)]
scoredMoves depth b =
    (map (\m -> (m, score depth (Game.move m b)))) moves
    where
        moves = [Game.Left, Game.Right, Game.Up, Game.Down]


bestMove :: Int -> Game.Board -> (Game.Move, Float)
bestMove depth b = maximumBy (comparing snd) $ scoredMoves depth b


debugBestMove :: Int -> Game.Board -> (Game.Move, Float)
debugBestMove depth b = maximumBy (comparing snd) $ traceShowId $ scoredMoves depth b


playRound :: (RandomGen g) => g -> Game.Board -> IO (g, Game.Board)
playRound g b = do
    putStrLn "Current state:"
    putStrLn $ Game.showBoard b
    let (move, _) = debugBestMove 3 b
    putStrLn $ "Moving " <> (show move)
    let b2 = Game.move move b
    let (g2, b3) = Game.randomDrop g b2
    return (g2, b3)


playGame :: (RandomGen g) => g -> Game.Board -> IO ()
playGame g b = do
    (g2, b2) <- playRound g b
    if Game.endGame b2 then
        return ()
    else
        playGame g2 b2


main :: IO ()
main = do
    -- let g = mkStdGen 0
    g <- getStdGen
    let (g2, b) = Game.randomDrop g Game.initial

    playGame g2 b

