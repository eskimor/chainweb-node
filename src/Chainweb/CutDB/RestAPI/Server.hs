{-# LANGUAGE DataKinds #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeApplications #-}

-- |
-- Module: Chainweb.CutDB.RestAPI.Server
-- Copyright: Copyright © 2018 Kadena LLC.
-- License: MIT
-- Maintainer: Lars Kuhtz <lars@kadena.io>
-- Stability: experimental
--
-- TODO
--
module Chainweb.CutDB.RestAPI.Server
(
-- * Handlers
  cutGetHandler
, cutPutHandler

-- * Cut Server
, cutServer

-- * Some Cut Server
, someCutServer

-- * Run server
, serveCutOnPort
) where

import Control.Monad.IO.Class
import Control.Monad.STM

import Data.Proxy

import Network.Wai.Handler.Warp hiding (Port)

import Servant.API
import Servant.Server

-- internal modules

import Chainweb.CutDB
import Chainweb.CutDB.RestAPI
import Chainweb.HostAddress
import Chainweb.RestAPI.Utils
import Chainweb.Utils
import Chainweb.Version

-- -------------------------------------------------------------------------- --
-- Handlers

-- | FIXME: include own peer info
--
cutGetHandler
    :: CutDb
    -> Handler CutHashes
cutGetHandler db = liftIO $ cutToCutHashes Nothing <$> _cut db

cutPutHandler
    :: CutDb
    -> CutHashes
    -> Handler NoContent
cutPutHandler db c = NoContent <$ liftIO (atomically (addCutHashes db c))

-- -------------------------------------------------------------------------- --
-- Cut API Server

cutServer
    :: forall (v :: ChainwebVersionT)
    . CutDbT v
    -> Server (CutApi v)
cutServer (CutDbT db) = cutGetHandler db :<|> cutPutHandler db

-- -------------------------------------------------------------------------- --
-- Some Cut Server

someCutServerT :: SomeCutDb -> SomeServer
someCutServerT (SomeCutDb (db :: CutDbT v)) =
    SomeServer (Proxy @(CutApi v)) (cutServer db)

someCutServer :: ChainwebVersion -> CutDb -> SomeServer
someCutServer v = someCutServerT . someCutDbVal v

-- -------------------------------------------------------------------------- --
-- Run Server

serveCutOnPort
    :: Port
    -> ChainwebVersion
    -> CutDb
    -> IO ()
serveCutOnPort p v = run (int p) . someServerApplication . someCutServer v

