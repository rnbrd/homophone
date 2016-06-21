module BoundaryState exposing
  (BoundaryState, sameSpaceCost, sameWordCost, initial, update, cost)

import List

import Space exposing (Space)

-- starting your word on a word boundary of the input incurs sameSpaceCost.
-- ending your word on a word boundary of the input also incurs sameSpaceCost.
-- note that you can end your word on a boundary without starting the next
-- word on the same boundary. for example,
--   input = bus stop, output = bus top
-- if your word starts on a boundary and ends on a boundary, and there are no
-- boundaries in between, you get sameWordCost.

type alias BoundaryState =
  Maybe
    { startSpace : Bool
    , midSpace : Bool
    , endSpace : Bool
    }

sameSpaceCost : Float
sameSpaceCost = 2.0

sameWordCost : Float
sameWordCost = 10.0

initial : BoundaryState
initial = Nothing

update : Int -> Maybe (List Space) -> BoundaryState -> BoundaryState
update vLen spaces state =
  case spaces of
    Just ss ->
      Just <|
        case state of
          Just b ->
            { b
            | midSpace = b.midSpace || b.endSpace ||
                memberSatisfies (not << Space.endsWordAt (vLen - 1)) ss
            , endSpace = memberSatisfies (Space.endsWordAt (vLen - 1)) ss
            }
          Nothing ->
            { startSpace = memberSatisfies (Space.startsWordAt 0) ss
            , midSpace =
                memberSatisfies
                  ( neither
                      (Space.startsWordAt 0)
                      (Space.endsWordAt (vLen - 1))
                  )
                  ss
            , endSpace =
                memberSatisfies
                  ( firstOnly
                      (Space.endsWordAt (vLen - 1))
                      (Space.startsWordAt 0)
                  )
                  ss
            }
    Nothing -> state

cost : Int -> BoundaryState -> Float
cost wordLength state =
  case state of
    Just b ->
      (if b.startSpace then sameSpaceCost else 0.0) +
        (if b.endSpace then sameSpaceCost else 0.0) +
        ( if b.startSpace && b.endSpace && not b.midSpace then sameWordCost
          else 0.0
        )
    Nothing -> 0.0

memberSatisfies : (a -> Bool) -> List a -> Bool
memberSatisfies predicate l = List.filter predicate l /= []

neither : (a -> Bool) -> (a -> Bool) -> a -> Bool
neither predicate1 predicate2 x = not (predicate1 x || predicate2 x)

firstOnly : (a -> Bool) -> (a -> Bool) -> a -> Bool
firstOnly predicate1 predicate2 x = predicate1 x && not (predicate2 x)
