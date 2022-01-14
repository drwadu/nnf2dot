module Main where

import Data.List (find)
import Data.Maybe (fromJust, mapMaybe)
import System.Environment (getArgs)
import Text.Read (readMaybe)

main :: IO ()
main = do
  (file : _) <- getArgs
  contents <- readFile file
  let nnf = lines contents
  let nc = readInt $ words (head nnf) !! 1
  let mappings = mapMaybe mapping nnf
  let body = dotBody nc mappings (filter (\x -> head (words x) /= "c") nnf)
  putStr "digraph nnftd  {"
  mapM_ putStr body
  putStrLn "\n}"

toNodes :: (Num b, Enum b) => [a] -> [(a, b)]
toNodes dag = reverse $ zip (reverse $ tail dag) [1 ..]

readInt :: String -> Integer
readInt = read :: String -> Integer

readMaybeInt :: String -> Maybe Integer
readMaybeInt = readMaybe :: String -> Maybe Integer

mapping :: String -> Maybe (Integer, String)
mapping xs =
  let ys = words xs
   in if head ys == "c"
        then Just (readInt $ last ys, head $ tail ys)
        else Nothing

label :: Integer -> [(Integer, String)] -> String
label i xs =
  let y = find (\x -> fst x == abs i) xs
   in if i > 0 then maybe (show i) snd y else maybe (show i) ("¬" ++ snd y)

dot :: Show a => Integer -> [(Integer, String)] -> ([Char], a) -> [[Char]]
dot nc xs (node, id)
  | head node == 'L' =
    [ "\n\tNode_"
        ++ show id
        ++ " [label="
        ++ label (readInt . last . words $ node) xs
        ++ "]"
    ]
  | head node `elem` ['A', 'O'] =
    reverse
      [ "\n\tNode_"
          ++ show id
          ++ " [label="
          ++ show (head . words $ node)
          ++ " shape=box]",
        edges nc node id
      ]
  | head node == '*' =
    reverse
      [ "\n\tNode_" ++ show id ++ " [label=\"* ↦ "
          ++ show (readInt . last . words $ node)
          ++ "\" shape=box]",
        edges nc node id
      ]
  | head node == '+' =
    reverse
      [ "\n\tNode_" ++ show id ++ " [label=\"+ ↦ "
          ++ show (readInt . last . words $ node)
          ++ "\" shape=box]",
        edges nc node id
      ]
  | otherwise =
    [ "\n\tNode_" ++ show id
        ++ " [label=\""
        ++ label (fromJust . readMaybeInt . head . words $ node) xs
        ++ " ↦ "
        ++ label (fromJust . readMaybeInt . last . words $ node) xs
        ++ "\"]"
    ]

edges :: Show a => Integer -> [Char] -> a -> [Char]
edges n node id
  | head node == 'A' =
    concatMap
      ((++) "\n" . ((++) (concat ["\tNode_", show id, " -> Node_"]) . show . abs . (-) n . readInt))
      (drop 2 $ words node)
  | head node == 'O' =
    concatMap
      ((++) "\n" . ((++) (concat ["\tNode_", show id, " -> Node_"]) . show . abs . (-) n . readInt))
      (drop 3 $ words node)
  | head node == '*' =
    concatMap
      ((++) "\n" . ((++) (concat ["\tNode_", show id, " -> Node_"]) . show . abs . (-) n . readInt))
      (drop 2 $ words node)
  | head node == '+' =
    concatMap
      ((++) "\n" . ((++) (concat ["\tNode_", show id, " -> Node_"]) . show . abs . (-) n . readInt))
      (drop 2 $ words node)
  | otherwise = error "invalid file."

dotBody :: Integer -> [(Integer, String)] -> [[Char]] -> [[Char]]
dotBody nc xs nnf = reverse $ concatMap (dot nc xs) $ toNodes nnf
