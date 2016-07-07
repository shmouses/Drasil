{-# OPTIONS -Wall #-} 
{-# LANGUAGE GADTs #-}
module Language.Drasil.Expr where

import GHC.Real (Ratio(..)) -- why not Data.Ratio?

import Language.Drasil.Chunk (Quantity)

type Relation = Expr

infixr 8 :^
infixl 7 :*
infixl 7 :/
infixl 6 :+
infixl 6 :-
infixr 4 :=
data Expr where
  V        :: Variable -> Expr
  Dbl      :: Double -> Expr
  Int      :: Integer -> Expr
  (:^)     :: Expr -> Expr -> Expr
  (:*)     :: Expr -> Expr -> Expr
  (:/)     :: Expr -> Expr -> Expr
  (:+)     :: Expr -> Expr -> Expr
  (:-)     :: Expr -> Expr -> Expr
  (:.)     :: Expr -> Expr -> Expr
  Neg      :: Expr -> Expr
  Deriv    :: Expr -> Expr -> Expr
  C        :: Quantity c => c -> Expr
  FCall    :: Expr -> [Expr] -> Expr --F(x) is (FCall F [x]) or similar
                                  --FCall accepts a list of params
                                  --F(x,y) would be (FCall F [x,y]) or sim.
  Case     :: [(Expr,Relation)] -> Expr -- For multi-case expressions, 
                                     -- each pair represents one case
  UnaryOp  :: UFunc  ->  Expr  -> Expr
  Grouping :: Expr -> Expr
  -- BinaryOp :: BiFunc ->  Expr  -> Expr -> Expr
  -- Operator :: Func   -> [Expr] -> Expr
  (:=) :: Expr -> Expr -> Expr
  (:<) :: Expr -> Expr -> Expr
  (:>) :: Expr -> Expr -> Expr
 
type Variable = String

instance Num Expr where
  a + b = a :+ b
  a * b = a :* b
  a - b = a :- b
  fromInteger a = Int a

  -- these are Num warts
  signum _ = error "should not use signum in expressions"
  abs _    = error "should not use abs in expressions"

instance Fractional Expr where
  a / b = a :/ b
  fromRational (a :% b) = (fromInteger a :/ fromInteger b)
  
--Known math functions. 
-- TODO: Move to its own file, not sure what to name it.
--       Should be in Data.Drasil.???

data UFunc = Log
           | Summation (Maybe Expr,Maybe Expr) --Sum (low,high) Bounds
           | Abs
           | Integral (Maybe Expr, Maybe Expr) --Integral (low,high) Bounds
           | Sin
           | Cos
           | Tan
           | Sec
           | Csc
           | Cot