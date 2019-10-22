module Test.PatternTest (patternTest) where

import GOOL.Drasil (
  ProgramSym(..), RenderSym(..), PermanenceSym(..),
  BodySym(..), BlockSym(..), ControlBlockSym(..), TypeSym(..), 
  StatementSym(..), ControlStatementSym(..), VariableSym(..), ValueSym(..),
  ValueExpression(..), FunctionSym(..), MethodSym(..), ModuleSym(..))
import Prelude hiding (return,print,log,exp,sin,cos,tan)
import Test.Observer (observer, x)

patternTest :: (ProgramSym repr) => repr (Program repr)
patternTest = prog "PatternTest" [fileDoc (buildModule "PatternTest" ["Observer"] [patternTestMainMethod] []), observer]

patternTestMainMethod :: (RenderSym repr) => repr (Method repr)
patternTestMainMethod = mainFunction (body [block [
  varDec $ var "n" int,
  initState "myFSM" "Off", 
  changeState "myFSM" "On",
  checkState "myFSM" 
    [(litString "Off", 
      oneLiner (printStrLn "Off")), 
      (litString "On", oneLiner (printStrLn "On"))] 
    (oneLiner (printStrLn "In"))],

  runStrategy "myStrat" 
    [("myStrat", oneLiner (printStrLn "myStrat")), 
      ("yourStrat", oneLiner (printStrLn "yourStrat"))]
    (Just (litInt 3)) (Just (var "n" int)),

  block [
    varDecDef (var "obs1" (obj "Observer")) (extNewObj "Observer" (obj "Observer") []), 
    varDecDef (var "obs2" (obj "Observer")) (extNewObj "Observer" (obj "Observer") [])],
  block [
    initObserverList (listType static_ (obj "Observer")) [valueOf $ var "obs1" (obj "Observer")], 
    addObserver (valueOf $ var "obs2" (obj "Observer")),
    notifyObservers (func "printNum" void []) (listType static_ (obj "Observer")),
    valState $ set (valueOf $ var "obs1" (obj "Observer")) x (litInt 10),
    print(get (valueOf $ var "obs1" (obj "Observer")) x)]])