{-# LANGUAGE TemplateHaskell #-}
module Main where

import Control.Lens
import Control.Monad.State
import Data.Char
import Data.List as List
import Data.Monoid
import Data.Monoid.Lens
import Data.Map as Map
import Test.Framework.Providers.HUnit
import Test.Framework.TH
import Test.Framework
import Test.HUnit

-- The code attempts to enumerate common use cases rather than give an example
-- of each available lens function. The tests here merely scratch the surface
-- of what is possible using the lens package; there are a great many use cases
-- (and lens functions) that aren't covered.

data Point =
  Point
  { _x :: Int -- ^ X coordinate
  , _y :: Int -- ^ Y coordinate
  } deriving (Show, Eq, Ord)

makeLenses ''Point

data Box =
  Box
  { _low :: Point  -- ^ The lowest used coordinates.
  , _high :: Point -- ^ The highest used coordinates.
  } deriving (Show, Eq)

makeLenses ''Box

data Polygon =
  Polygon
  { _points :: [ Point ]
  , _labels :: Map Point String
  , _box :: Box
  } deriving (Show, Eq)

makeLenses ''Polygon

origin =
  Point { _x = 0, _y = 0 }

vectorFrom fromPoint toPoint =
  Point
  { _x = toPoint^.x - fromPoint^.x
  , _y = toPoint^.y - fromPoint^.y
  }

trig =
  Polygon
  { _points = [ Point { _x = 0, _y = 0 }
              , Point { _x = 4, _y = 7 }
              , Point { _x = 8, _y = 0 } ]
  , _labels = fromList [ (Point { _x = 0, _y = 0 }, "Origin")
                       , (Point { _x = 4, _y = 7 }, "Peak") ]
  , _box = Box { _low = Point { _x = 0, _y = 0 }
               , _high = Point { _x = 8, _y = 7 } }
  }

case_read_record_field =
  (trig^.box.high.y)
    @?= 7

case_read_state_record_field =
  runState test trig @?= (7, trig)
  where
    test = use $ box.high.y

case_read_record_field_and_apply_function =
  (trig^.points.to last.to (vectorFrom origin).x)
    @?= 8

case_read_state_record_field_and_apply_function =
  runState test trig @?= (8, trig)
  where test = use $ points.to last.to (vectorFrom origin).x

case_write_record_field =
  (trig & box.high.y .~ 6)
    @?= trig { _box = (trig & _box)
               { _high = (trig & _box & _high)
                         { _y = 6 } } }

case_write_state_record_field = do
  let trig' = trig { _box = (trig & _box)
                            { _high = (trig & _box & _high)
                                      { _y = 6 } } }
  runState test trig @?= ((), trig')
  where
    test = box.high.y .= 6

case_write_record_field_and_access_new_value =
  (trig & box.high.y <.~ 6)
    @?= (6, trig { _box = (trig & _box)
                          { _high = (trig & _box & _high)
                                    { _y = 6 } } })

case_write_state_record_field_and_access_new_value = do
  let trig' = trig { _box = (trig & _box)
                            { _high = (trig & _box & _high)
                                      { _y = 6 } } }
  runState test trig @?= (6, trig')
  where
    test = box.high.y <.= 6

case_write_record_field_and_access_old_value =
  (trig & box.high.y <<.~ 6)
    @?= (7, trig { _box = (trig & _box)
                          { _high = (trig & _box & _high)
                                    { _y = 6 } } })

case_write_state_record_field_and_access_old_value = do
  let trig' = trig { _box = (trig & _box)
                            { _high = (trig & _box & _high)
                                      { _y = 6 } } }
  runState test trig @?= (7, trig')
  where
    test = box.high.y <<.= 6

case_modify_record_field =
  (trig & box.low.y %~ (+ 2))
    @?= trig { _box = (trig & _box)
                      { _low = (trig & _box & _low)
                               { _y = ((trig & _box & _low & _y) + 2) } } }

case_modify_state_record_field = do
  let trig' = trig { _box = (trig & _box)
                            { _low = (trig & _box & _low)
                                     { _y = ((trig & _box & _low & _y) + 2) } } }
  runState test trig @?= ((), trig')
  where
    test = box.low.y %= (+ 2)

case_modify_record_field_and_access_new_value =
  (trig & box.low.y <%~ (+ 2))
    @?= (2, trig { _box = (trig & _box)
                          { _low = (trig & _box & _low)
                                   { _y = ((trig & _box & _low & _y) + 2) } } })

case_modify_state_record_field_and_access_new_value = do
  let trig' = trig { _box = (trig & _box)
                            { _low = (trig & _box & _low)
                                     { _y = ((trig & _box & _low & _y) + 2) } } }
  runState test trig @?= (2, trig')
  where
    test = box.low.y <%= (+ 2)

case_modify_record_field_and_access_old_value =
  (trig & box.low.y <<%~ (+ 2))
    @?= (0, trig { _box = (trig & _box)
                          { _low = (trig & _box & _low)
                                   { _y = ((trig & _box & _low & _y) + 2) } } })

case_modify_state_record_field_and_access_old_value = do
  let trig' = trig { _box = (trig & _box)
                            { _low = (trig & _box & _low)
                                     { _y = ((trig & _box & _low & _y) + 2) } } }
  runState test trig @?= (0, trig')
  where
    test = box.low.y <<%= (+ 2)

case_modify_record_field_and_access_side_result = do
  runState test trig @?= (8, trig')
  where
    test = box.high %%= modifyAndCompute
    modifyAndCompute point =
      (point ^. x, point & y +~ 2)
    trig' = trig { _box = (trig & _box)
                            { _high = (trig & _box & _high)
                                      { _y = ((trig & _box & _high & _y) + 2) } } }

case_increment_record_field =
  (trig & box.low.y +~ 1) -- And similarly for -~ *~ //~ ^~ ^^~ **~ ||~ &&~
    @?= trig { _box = (trig & _box)
                      { _low = (trig & _box & _low)
                               { _y = ((trig & _box & _low & _y) + 1) } } }

case_increment_state_record_field =
  runState test trig @?= ((), trig')
  where
    test = box.low.y += 1
    trig' = trig { _box = (trig & _box)
                   { _low = (trig & _box & _low)
                     { _y = ((trig & _box & _low & _y) + 1) } } }

case_append_to_record_field =
  (trig & points <>~ [ origin ])
    @?= trig { _points = (trig & _points) <> [ origin ] }

case_append_to_state_record_field = do
  runState test trig @?= ((), trig')
  where
    test = points <>= [ origin ]
    trig' = trig { _points = (trig & _points) <> [ origin ] }

case_append_to_record_field_and_access_new_value =
  (trig & points <<>~ [ origin ])
    @?= (_points trig <> [ origin ], trig { _points = (trig & _points) <> [ origin ] })

case_append_to_state_record_field_and_access_new_value = do
  runState test trig @?= (_points trig <> [ origin ], trig')
  where
    test = points <<>= [ origin ]
    trig' = trig { _points = (trig & _points) <> [ origin ] }

case_append_to_record_field_and_access_old_value =
  (trig & points <<%~ (<>[origin]))
    @?= (_points trig, trig { _points = (trig & _points) <> [ origin ] })

case_append_to_state_record_field_and_access_old_value = do
  runState test trig @?= (_points trig, trig')
  where
    test = points <<%= (<>[origin])
    trig' = trig { _points = (trig & _points) <> [ origin ] }

case_read_maybe_map_entry = trig^.labels.at origin @?= Just "Origin"

case_read_maybe_state_map_entry =
  runState test trig @?= (Just "Origin", trig)
  where test = use $ labels.at origin

case_read_map_entry = trig^.labels.traverseAt origin @?= "Origin"

case_read_state_map_entry = runState test trig @?= ("Origin", trig)
  where test = use $ labels.traverseAt origin

case_modify_map_entry =
  (trig & labels.traverseAt origin %~ List.map toUpper)
    @?= trig { _labels = fromList [ (Point { _x = 0, _y = 0 }, "ORIGIN")
                                  , (Point { _x = 4, _y = 7 }, "Peak") ] }

case_insert_maybe_map_entry =
  (trig & labels.at (Point { _x = 8, _y = 0 }) .~ Just "Right")
    @?= trig { _labels = fromList [ (Point { _x = 0, _y = 0 }, "Origin")
                                  , (Point { _x = 4, _y = 7 }, "Peak")
                                  , (Point { _x = 8, _y = 0 }, "Right") ] }

case_delete_maybe_map_entry =
  (trig & labels.at origin .~ Nothing)
    @?= trig { _labels = fromList [ (Point { _x = 4, _y = 7 }, "Peak") ] }

case_read_list_entry =
  (trig ^? points.element 0)
    @?= Just origin

case_write_list_entry =
  (trig & points.element 0 .~ Point { _x = 2, _y = 0 })
    @?= trig { _points = [ Point { _x = 2, _y = 0 }
                         , Point { _x = 4, _y = 7 }
                         , Point { _x = 8, _y = 0 } ] }

case_write_through_list_entry =
  (trig & points.element 0 . x .~ 2)
    @?= trig { _points = [ Point { _x = 2, _y = 0 }
                         , Point { _x = 4, _y = 7 }
                         , Point { _x = 8, _y = 0 } ] }

main :: IO ()
main = defaultMain [$testGroupGenerator]
