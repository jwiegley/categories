{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TupleSections #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

{-# OPTIONS_GHC -Wall #-}
{-# OPTIONS_GHC -Wno-orphans #-}
{-# OPTIONS_GHC -Wno-type-defaults #-}

{-# OPTIONS_GHC -fplugin=ConCat.Plugin #-}
-- {-# OPTIONS_GHC -fplugin-opt=ConCat.Plugin:trace #-}
{-# OPTIONS_GHC -fsimpl-tick-factor=1000 #-}
{-# OPTIONS_GHC -fexpose-all-unfoldings #-}
{-# OPTIONS_GHC -funfolding-creation-threshold=450 #-}
{-# OPTIONS_GHC -funfolding-use-threshold=80 #-}

-- {-# OPTIONS_GHC -dverbose-core2core #-}
{-# OPTIONS_GHC -dsuppress-idinfo #-}
-- {-# OPTIONS_GHC -dsuppress-uniques #-}
{-# OPTIONS_GHC -dsuppress-module-prefixes #-}

{-# OPTIONS_GHC -Wno-name-shadowing #-}
{-# OPTIONS_GHC -Wno-unused-local-binds #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}

module Main where

import qualified Categorical.AST as AST
import           Categorical.Gather
import           Categorical.NonDet
import           Categorical.Program
import qualified Data.Set as S
-- import           ConCat.AltCat (ccc)
-- import           ConCat.Category
-- jww (2017-04-22): Switching to AltCat instances result in a plugin error
import           ConCat.AltCat
import           ConCat.Syntactic (render)
import           Control.Arrow (Kleisli(..))
import           Control.Monad.State
import           Control.Monad.Writer
import           Data.Functor.Identity
import           Data.Monoid
import           Data.Coerce
import           Functions
import           Prelude hiding ((.), id, curry, uncurry, const)
import           Z3.Category
import           Z3.Monad

default (Int)

program :: ((Int, Int), Int) -> Int
program ((x, y), z) =
    let v2    :: V 'V2 Int = load  x in
    let v1    :: V 'V1 Int = load  y in
    let v3    :: V 'V3 Int = load  z in
    let v2'   :: V 'V2 Int = curry add  (xfer v1)  v2 in
    let v1'   :: V 'V1 Int = load  2 in
    let v2''  :: V 'V2 Int = curry add  (xfer v1') v2' in
    let v2''' :: V 'V2 Int = curry add  (xfer v3)  v2'' in
    ret v2'''
{-# INLINE program #-}

main :: IO ()
main = do
    -- putStrLn "Hello, Haskell!"

    -- print $ ccc @(->) (uncurry (equation @Int)) (10, 20)

    -- print $ render (ccc (uncurry (equation @Int)))
    -- print $ gather (ccc (uncurry (equation @Int)))

    -- print $ ccc @AST.Cat (uncurry (equation @Int))
    -- print $ AST.eval (ccc @AST.Cat (uncurry (equation @Int))) (10, 20)

    -- putStrLn "Goodbye, Haskell!"

    putStrLn "Display program rendering..."
    print $ render (ccc program)

    putStrLn "Run the program directly..."
    print $ ccc program ((10, 20), 30)

    let (k :**: x) = ccc @((->) :**: Gather) program
    putStrLn $ "Solution bound: " ++ show (runGather x)
    putStrLn $ "Solution value: " ++ show (k ((10, 20), 30))

    -- jww (2017-04-22): Uncommenting this gets a residual error
    -- putStrLn "Solve for a trivially satisfied constraint..."
    -- Just (k :: ((Int, Int), Int) -> Int) <-
    --     case ccc @(NonDet ((->) :**: Gather)) program of
    --         NonDet g ->
    --             fmap (fmap ((\(p :**: _) -> p) . g))
    --                 $ runZ3 $ ccc @Z3Cat $ \(x :: p) ->
    --                     let _ :**: Gather s = g x in s < 100
    -- -- putStrLn $ "Solution bound: " ++ show (runGather x)
    -- putStrLn $ "Solution value: " ++ show (k ((10, 20), 30))

    -- jww (2017-04-22): Uncommenting this gets a residual error
    -- putStrLn "Solve for a trivially satisfied constraint..."
    -- Just (k :**: x) <-
    --     resolve (ccc @(NonDet ((->) :**: Gather)) program) $ \(_ :**: Gather s) ->
    --         s < 100
    -- putStrLn $ "Solution bound: " ++ show (runGather x)
    -- putStrLn $ "Solution value: " ++ show (k ((10, 20), 30))

    -- jww (2017-04-22): Uncommenting this causes a hang in GHC
    -- putStrLn "Solve for a latency bound..."
    -- Just k <- resolve (ccc @(NonDet (Kleisli (Writer (Sum Int)))) program) $ \p ->
    --     getSum (execWriter (runKleisli p (10, 20, 30))) < 50
    -- print $ runKleisli k (10, 20, 30)
