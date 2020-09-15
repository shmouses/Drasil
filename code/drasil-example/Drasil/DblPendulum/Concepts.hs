module Drasil.DblPendulum.Concepts where

import Language.Drasil
import Utils.Drasil

import Data.Drasil.IdeaDicts (physics)

--import Data.Drasil.Concepts.Math (angle)
import Data.Drasil.Concepts.Physics (gravity)

{-concepts :: [IdeaDict]
concepts = map nw [landingPos, launch, launchAngle, launchSpeed, offset, targetPos]
  ++ map nw defs
-}
-- defs :: [ConceptChunk]
-- defs = [pendulum]

pendulumTitle :: CI
pendulumTitle = commonIdeaWithDict "pendulumTitle" (pn "Pendulum") "Pendulum" [physics]

-- duration, flightDur, landingPos, launch, launchAngle, launchSpeed, offset, targetPos :: NamedChunk
-- duration   = nc "duration" (nounPhraseSP "duration")
-- launch     = nc "launch"   (nounPhraseSP "launch") -- FIXME: Used as adjective
-- offset     = nc "offset"   (nounPhraseSent $ S "distance between the" +:+ phrase targetPos `andThe` phrase landingPos)

-- flightDur   = compoundNC (nc "flight"  (nounPhraseSP "flight" )) duration
-- landingPos  = compoundNC (nc "landing" (nounPhraseSP "landing")) position
-- launchAngle = compoundNC launch angle
-- launchSpeed = compoundNC launch speed
-- targetPos   = compoundNC target position-}


-- pendulum :: ConceptChunk
-- pendulum = dcc "pendulum" (nounPhraseSP "pendulum")  "body suspended from a fixed support so that it swings
--                 freely back and forth under the influence of gravity"