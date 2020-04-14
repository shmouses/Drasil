{-# LANGUAGE TypeFamilies, Rank2Types #-}

-- Performs code analysis on the GOOL code
module GOOL.Drasil.CodeInfo (CodeInfo(..)) where

import GOOL.Drasil.ClassInterface (MSBody, VSType, SValue, MSStatement, 
  SMethod, ProgramSym(..), FileSym(..), PermanenceSym(..), BodySym(..), 
  BlockSym(..), ControlBlock(..), InternalControlBlock(..), TypeSym(..), 
  VariableSym(..), ValueSym(..), NumericExpression(..), BooleanExpression(..), 
  ValueExpression(..), Selector(..), InternalValueExp(..), FunctionSym(..), 
  SelectorFunction(..), StatementSym(..), AssignStatement(..), 
  DeclStatement(..), IOStatement(..), StringStatement(..), FuncAppStatement(..), MiscStatement(..), 
  ControlStatement(..), ScopeSym(..), ParameterSym(..), MethodSym(..), 
  StateVarSym(..), ClassSym(..), ModuleSym(..))
import GOOL.Drasil.CodeType (CodeType(Void))
import GOOL.Drasil.AST (ScopeTag(..))
import GOOL.Drasil.CodeAnalysis (Exception(..), exception, stdExc)
import GOOL.Drasil.Helpers (toCode, toState)
import GOOL.Drasil.State (GOOLState, VS, lensGStoFS, lensFStoCS, lensFStoMS,
  lensCStoMS, lensMStoFS, lensMStoVS, lensVStoFS, modifyReturn, setClassName, 
  setModuleName, getModuleName, addClass, updateClassMap, addException, 
  updateMethodExcMap, updateCallMap, addCall, callMapTransClosure, 
  updateMEMWithCalls)

import Control.Monad.State (State, modify)
import qualified Control.Monad.State as S (get)
import Control.Lens.Zoom (zoom)
import Data.Maybe (fromMaybe)

newtype CodeInfo a = CI {unCI :: a} deriving Eq

instance Functor CodeInfo where
  fmap f (CI x) = CI (f x)

instance Applicative CodeInfo where
  pure = CI
  (CI f) <*> (CI x) = CI (f x)

instance Monad CodeInfo where
  return = CI
  CI x >>= f = f x

instance ProgramSym CodeInfo where
  type Program CodeInfo = GOOLState
  prog _ fs = do
    mapM_ (zoom lensGStoFS) fs
    modify (updateMEMWithCalls . callMapTransClosure)
    s <- S.get
    toState $ toCode s

instance FileSym CodeInfo where
  type RenderFile CodeInfo = ()
  fileDoc = execute1
  
  docMod _ _ _ = execute1

instance PermanenceSym CodeInfo where
  type Permanence CodeInfo = ()
  static = toCode ()
  dynamic = toCode ()

instance BodySym CodeInfo where
  type Body CodeInfo = ()
  body = executeList

  addComments _ _ = noInfo

instance BlockSym CodeInfo where
  type Block CodeInfo = ()
  block = executeList

instance TypeSym CodeInfo where
  type Type CodeInfo = String
  bool = noInfoType
  int = noInfoType
  float = noInfoType
  double = noInfoType
  char = noInfoType
  string = noInfoType
  infile = noInfoType
  outfile = noInfoType
  listType _ = noInfoType
  arrayType _ = noInfoType
  listInnerType _ = noInfoType
  obj = toState . toCode
  -- enumType _ = noInfoType
  funcType _ _ = noInfoType
  iterator _ = noInfoType
  void = noInfoType

  getType _ = Void
  getTypeString = unCI

instance ControlBlock CodeInfo where
  runStrategy _ ss vl _ = do
    mapM_ snd ss
    _ <- zoom lensMStoVS $ fromMaybe noInfo vl
    noInfo

  solveODE _ _ = noInfo

instance InternalControlBlock CodeInfo where
  listSlice' b e s _ vl = zoom lensMStoVS $ do
    mapM_ (fromMaybe noInfo) [b,e,s]
    _ <- vl
    noInfo

instance VariableSym CodeInfo where
  type Variable CodeInfo = ()
  var _ _ = noInfo
  staticVar _ _ = noInfo
  const _ _ = noInfo
  extVar _ _ _ = noInfo
  self = noInfo
  -- enumVar _ _ = noInfo
  classVar _ _ = noInfo
  extClassVar _ _ = noInfo
  objVar _ _ = noInfo
  objVarSelf _ = noInfo
  listVar _ _ = noInfo
  arrayElem _ _ = noInfo
  iterVar _ _ = noInfo
  
  variableName _ = ""
  variableType _ = toCode ""

instance ValueSym CodeInfo where
  type Value CodeInfo = ()
  litTrue = noInfo
  litFalse = noInfo
  litChar _ = noInfo
  litDouble _ = noInfo
  litFloat _ = noInfo
  litInt _ = noInfo
  litString _ = noInfo
  litArray _ = executeList
  litList _ = executeList

  pi = noInfo

  -- ($:) _ _ = noInfo

  valueOf _ = noInfo
  arg _ = noInfo
  -- enumElement _ _ = noInfo
  
  argsList = noInfo

  valueType _ = toCode ""

instance NumericExpression CodeInfo where
  (#~) = execute1
  (#/^) = execute1
  (#|) = execute1
  (#+) = execute2
  (#-) = execute2
  (#*) = execute2
  (#/) = execute2
  (#%) = execute2
  (#^) = execute2

  log = execute1
  ln = execute1
  exp = execute1
  sin = execute1
  cos = execute1
  tan = execute1
  csc = execute1
  sec = execute1
  cot = execute1
  arcsin = execute1
  arccos = execute1
  arctan = execute1
  floor = execute1
  ceil = execute1

instance BooleanExpression CodeInfo where
  (?!) = execute1
  (?&&) = execute2
  (?||) = execute2

  (?<) = execute2
  (?<=) = execute2
  (?>) = execute2
  (?>=) = execute2
  (?==) = execute2
  (?!=) = execute2
    
instance ValueExpression CodeInfo where
  inlineIf = execute3
  funcAppMixedArgs n _ = currModCall n
  selfFuncAppMixedArgs = funcAppMixedArgs
  extFuncAppMixedArgs l n _ vs ns = do
    sequence_ vs
    executePairList ns
    addExternalCall l n  
  libFuncAppMixedArgs = extFuncAppMixedArgs
  newObjMixedArgs ot vs ns = do
    sequence_ vs
    executePairList ns
    addCurrModConstructorCall ot
  extNewObjMixedArgs l ot vs ns = do
    sequence_ vs
    executePairList ns
    addExternalConstructorCall l ot
  libNewObjMixedArgs = extNewObjMixedArgs

  lambda _ = execute1

  notNull = execute1

instance Selector CodeInfo where
  objAccess = execute2
  
  argExists _ = noInfo
  
  indexOf = execute2
  
instance InternalValueExp CodeInfo where
  objMethodCallMixedArgs' n _ v vs ns = do
    _ <- v
    currModCall n vs ns
  objMethodCallNoParams' n _ v = do
    _ <- v
    addCurrModCall n

instance FunctionSym CodeInfo where
  type Function CodeInfo = ()
  func _ _ = executeList
  
  get v _ = execute1 v
  set v _ = execute2 v

  listSize = execute1
  listAdd = execute3
  listAppend = execute2

  iterBegin = execute1
  iterEnd = execute1

instance SelectorFunction CodeInfo where
  listAccess = execute2
  listSet = execute3

instance StatementSym CodeInfo where
  type Statement CodeInfo = ()

instance AssignStatement CodeInfo where
  assign _ = zoom lensMStoVS . execute1
  (&-=) _ = zoom lensMStoVS . execute1
  (&+=) _ = zoom lensMStoVS . execute1
  (&++) _ = noInfo
  (&--) _ = noInfo

instance DeclStatement CodeInfo where
  varDec _ = noInfo
  varDecDef _ = zoom lensMStoVS . execute1
  listDec _ _ = noInfo
  listDecDef _ = zoom lensMStoVS . executeList
  arrayDec _ _ = noInfo
  arrayDecDef _ = zoom lensMStoVS . executeList
  objDecDef _ = zoom lensMStoVS . execute1
  objDecNew _ = zoom lensMStoVS . executeList
  extObjDecNew _ _ = zoom lensMStoVS . executeList
  objDecNewNoParams _ = noInfo
  extObjDecNewNoParams _ _ = noInfo
  constDecDef _ = zoom lensMStoVS . execute1
  funcDecDef _ _ = zoom lensMStoVS . execute1

instance IOStatement CodeInfo where
  print = zoom lensMStoVS . execute1
  printLn = zoom lensMStoVS . execute1
  printStr _ = noInfo
  printStrLn _ = noInfo

  printFile v = zoom lensMStoVS . execute2 v
  printFileLn v = zoom lensMStoVS . execute2 v
  printFileStr v _ = zoom lensMStoVS $ execute1 v
  printFileStrLn v _ = zoom lensMStoVS $ execute1 v

  getInput _ = noInfo
  discardInput = noInfo
  getFileInput v _ = zoom lensMStoVS $ execute1 v
  discardFileInput = zoom lensMStoVS . execute1

  openFileR _ v = modify (addException fnfExc) >> execute1 (zoom lensMStoVS v)
  openFileW _ v = modify (addException ioExc) >> execute1 (zoom lensMStoVS v)
  openFileA _ v = modify (addException ioExc) >> execute1 (zoom lensMStoVS v)
  closeFile = zoom lensMStoVS . execute1

  getFileInputLine v _ = zoom lensMStoVS $ execute1 v
  discardFileLine = zoom lensMStoVS . execute1
  getFileInputAll v _ = execute1 (zoom lensMStoVS v)

instance StringStatement CodeInfo where
  stringSplit _ _ = zoom lensMStoVS . execute1

  stringListVals _ = zoom lensMStoVS . execute1
  stringListLists _ = zoom lensMStoVS . execute1

instance FuncAppStatement CodeInfo where
  inOutCall n vs _ _ = zoom lensMStoVS $ do
    sequence_ vs
    addCurrModCall n
  selfInOutCall n vs _ _ = zoom lensMStoVS $ do
    sequence_ vs
    addCurrModCall n
  extInOutCall l n vs _ _ = zoom lensMStoVS $ do
    sequence_ vs
    addExternalCall l n

instance MiscStatement CodeInfo where
  valState = zoom lensMStoVS . execute1

  comment _ = noInfo

  multi = executeList

instance ControlStatement CodeInfo where
  break = noInfo
  continue = noInfo

  returnState = zoom lensMStoVS . execute1

  throw _ = modifyReturn (addException genericExc) (toCode ())

  ifCond = evalConds
  switch v cs b = do
    _ <- zoom lensMStoVS v
    evalConds cs b

  ifExists v = execute3 (zoom lensMStoVS v)

  for dec v = execute4 dec (zoom lensMStoVS v)
  forRange _ b e s = execute4 (zoom lensMStoVS b) (zoom lensMStoVS e) 
    (zoom lensMStoVS s)
  forEach _ v = execute2 (zoom lensMStoVS v)
  while v = execute2 (zoom lensMStoVS v)

  tryCatch _ cb = do
    _ <- cb
    noInfo

  checkState _ = evalConds

  notifyObservers f _ = execute1 (zoom lensMStoVS f)

instance ScopeSym CodeInfo where
  type Scope CodeInfo = ScopeTag
  private = toCode Priv
  public = toCode Pub

instance ParameterSym CodeInfo where
  type Parameter CodeInfo = ()
  param _ = noInfo
  pointerParam _ = noInfo

instance MethodSym CodeInfo where
  type Method CodeInfo = ()
  method n _ _ _ _ = updateMEMandCM n
  getMethod _ = noInfo
  setMethod _ = noInfo
  constructor _ il b = do
    mapM_ (zoom lensMStoVS . snd) il
    _ <- b
    mn <- zoom lensMStoFS getModuleName
    modify (updateCallMap mn . updateMethodExcMap mn)
    noInfo

  docMain = updateMEMandCM "main"

  function n _ _ _ _ = updateMEMandCM n
  mainFunction = updateMEMandCM "main"

  docFunc _ _ _ f = do
    _ <- f
    noInfo

  inOutMethod n _ _ _ _ _ = updateMEMandCM n

  docInOutMethod n _ _ _ _ _ _ = updateMEMandCM n

  inOutFunc n _ _ _ _ _ = updateMEMandCM n

  docInOutFunc n _ _ _ _ _ _ = updateMEMandCM n

instance StateVarSym CodeInfo where
  type StateVar CodeInfo = ()
  stateVar _ _ _ = noInfo
  stateVarDef _ _ _ _ _ = noInfo
  constVar _ _ _ _ = noInfo

instance ClassSym CodeInfo where
  type Class CodeInfo = ()
  buildClass n _ _ ms = do
    modify (addClass n . setClassName n)
    mapM_ (zoom lensCStoMS) ms
    noInfo
  -- enum n _ s = if unCI s == Pub then modifyReturn (addClass n) (toCode ()) else 
  --   noInfo 
  extraClass n _ _ ms = do
    modify (setClassName n)
    mapM_ (zoom lensCStoMS) ms
    noInfo
  implementingClass n _ _ = buildClass n Nothing [] 

  docClass _ c = do
    _ <- c
    noInfo

instance ModuleSym CodeInfo where
  type Module CodeInfo = ()
  buildModule n _ fs cs = do
    modify (setModuleName n)
    mapM_ (zoom lensFStoCS) cs 
    mapM_ (zoom lensFStoMS) fs
    modifyReturn (updateClassMap n) (toCode ())

-- Helpers

noInfo :: State s (CodeInfo ())
noInfo = toState $ toCode ()

noInfoType :: State s (CodeInfo String)
noInfoType = toState $ toCode ""

fnfExc, ioExc, genericExc :: Exception
fnfExc = exception "java.io" "FileNotFoundException"
ioExc = exception "java.io" "IOException"
genericExc = stdExc "Exception"

updateMEMandCM :: String -> MSBody CodeInfo -> SMethod CodeInfo
updateMEMandCM n b = do
  _ <- b
  modify (updateCallMap n . updateMethodExcMap n)
  noInfo

evalConds :: [(SValue CodeInfo, MSBody CodeInfo)] -> MSBody CodeInfo -> 
  MSStatement CodeInfo
evalConds cs def = do
  mapM_ (zoom lensMStoVS . fst) cs
  mapM_ snd cs
  _ <- def
  noInfo

addCurrModCall :: String -> SValue CodeInfo
addCurrModCall n = do
  mn <- zoom lensVStoFS getModuleName 
  modify (addCall (mn ++ "." ++ n)) 
  noInfo

addCurrModConstructorCall :: VSType CodeInfo -> SValue CodeInfo
addCurrModConstructorCall ot = do
  t <- ot
  let tp = getTypeString t
  addCurrModCall tp

addExternalCall :: String -> String -> SValue CodeInfo
addExternalCall l n = modify (addCall (l ++ "." ++ n)) >> noInfo

addExternalConstructorCall :: String -> VSType CodeInfo -> SValue CodeInfo
addExternalConstructorCall l ot = do
  t <- ot
  let tp = getTypeString t
  addExternalCall l tp

execute1 :: State a (CodeInfo ()) -> State a (CodeInfo ())
execute1 s = do
  _ <- s
  noInfo

executeList :: [State a (CodeInfo ())] -> State a (CodeInfo ())
executeList l = do
  sequence_ l
  noInfo

executePairList :: [(State a (CodeInfo ()), State a (CodeInfo ()))] -> 
  State a (CodeInfo ())
executePairList ps = do
  mapM_ fst ps
  mapM_ snd ps
  noInfo

execute2 :: State a (CodeInfo ()) -> State a (CodeInfo ()) -> 
  State a (CodeInfo ())
execute2 s1 s2 = do
  _ <- s1
  execute1 s2

execute3 :: State a (CodeInfo ()) -> State a (CodeInfo ()) -> 
  State a (CodeInfo ()) -> State a (CodeInfo ())
execute3 s1 s2 s3 = do
  _ <- s1
  execute2 s2 s3

execute4 :: State a (CodeInfo ()) -> State a (CodeInfo ()) -> 
  State a (CodeInfo ()) -> State a (CodeInfo ()) -> State a (CodeInfo ())
execute4 s1 s2 s3 s4 = do
  _ <- s1
  execute3 s2 s3 s4

currModCall :: String -> [VS (CodeInfo ())] -> 
  [(VS (CodeInfo ()), VS (CodeInfo ()))] -> VS (CodeInfo ())
currModCall n ps ns = do
  sequence_ ps
  executePairList ns
  addCurrModCall n
