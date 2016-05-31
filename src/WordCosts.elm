module WordCosts where

import List
import String

import CompletionDict exposing (CompletionDict)
import Parser

costMultiplier : Float
costMultiplier = 1.5 / 25784.0

type alias Speller = CompletionDict String
type alias WordCosts = CompletionDict Float

type ParseError
  = InvalidTriplet String
  | NotSorted

parseErrorToString : ParseError -> String
parseErrorToString err =
  case err of
    InvalidTriplet t ->
      "\"" ++ t ++ "\" is not of the form \"phonemes\tspelling\tcost\""
    NotSorted -> "phoneme strings are not in sorted order"

parse : String -> Result ParseError (Speller, WordCosts)
parse fileContents =
  let
    triplets = parseTriplets fileContents
  in let
    tripletsResult =
      Result.andThen
        (parseTriplets fileContents) <|
        Result.fromMaybe NotSorted << CompletionDict.fromSortedPairs
  in let
    spellerResult = Result.map (CompletionDict.map fst) tripletsResult
    wordCostsResult = Result.map (CompletionDict.map snd) tripletsResult
  in
    Result.map2 (,) spellerResult wordCostsResult

parseTriplets : String -> Result ParseError (List (String, (String, Float)))
parseTriplets fileContents =
  Parser.foldResults <|
    List.map parseTriplet <| Parser.nonEmptyLines fileContents

parseTriplet : String -> Result ParseError (String, (String, Float))
parseTriplet text =
  Result.fromMaybe
    (InvalidTriplet text) <|
    case Parser.split3 "\t" text of
      Nothing -> Nothing
      Just ("", _, _) -> Nothing
      Just (_, _, "") -> Nothing
      Just (word, spelling, costString) ->
        Maybe.map
          ((,) word << (,) spelling << (*) costMultiplier) <|
          Result.toMaybe <| String.toFloat costString
