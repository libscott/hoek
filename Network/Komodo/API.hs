{-# LANGUAGE OverloadedStrings #-}

module Network.Komodo.API
  ( module API
  , methods
  , runJsonRpc
  , runMethod
  , wrapJson
  ) where

import           Data.Aeson.Types
import qualified Data.Map as Map

import           Lens.Micro

import           Network.Komodo.API.Utils as API
import           Network.Komodo.API.Tx as API
import           Network.Komodo.Crypto
import           Network.Komodo.Prelude


methods :: Map.Map String (JsonMethod, String)
methods = Map.fromList
  [ ("ed25519KeyPair", (generateKeyPair, "Generate an Ed25519 key pair"))
  , ("createTx",       (encodeTx, "Create a transaction"))
  , ("signTx",         (signTx, "Sign a transaction"))
  ]


runJsonRpc :: Value -> ExceptT Err IO Value
runJsonRpc val = do
  let res = parseEither parseRequest val
  (name, params) <- ExceptT $ pure $ over _Left invalidRequest res
  runMethod name params
  where
    invalidRequest = errStr InvalidProtocol
    parseRequest = withObject "request" $ \obj ->
      (,) <$> obj .: "method" <*> obj .: "params"


runMethod :: String -> Value -> ExceptT Err IO Value
runMethod name params = do
  let throw = throwE $ errStr InvalidMethod name
  (method,_) <- maybe throw pure $ Map.lookup name methods
  method params


wrapJson :: Either Err Value -> Value
wrapJson = either wrapJsonError wrapSuccess
  where
    wrapSuccess val = object ["result" .= val]
    wrapJsonError val = object ["error" .= val]


generateKeyPair :: JsonMethod
generateKeyPair _ = do
  (pk, sk) <- lift genKeyPair
  return $ object ["public_key" .= pk, "secret_key" .= sk]


showErrorClasses :: JsonMethod
showErrorClasses _ = return $ object ["errors" .= allErrorClasses]