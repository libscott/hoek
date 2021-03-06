{-# LANGUAGE OverloadedStrings #-}

module Main where

import qualified Data.ByteString.Lazy.Char8 as C8L

import           Data.Aeson
import           Data.Aeson.Encode.Pretty
import qualified Data.Map as Map

import           Options.Applicative

import qualified Network.Komodo.API as API
import           Network.Komodo.Prelude

import           System.Exit
import           System.IO


type Method = ExceptT Err IO Value


parseCmd :: Parser Method
parseCmd = subparser $
  foldl1 (<>) $ (\(c,(_,h)) -> apiMethod c h) <$> methods
  where
    methods = Map.toList API.methods
    apiMethod c h = command c $ info (parseMethod c) (progDesc h)
    parseMethod c = API.runMethod c <$> argument jsonArg (metavar "JSON")


jsonArg :: ReadM Value
jsonArg = eitherReader $ eitherDecode . C8L.pack


parseOpts :: ParserInfo (Bool, Method)
parseOpts = info (parser <**> helper) desc
  where
    parser = (,) <$> pretty <*> parseCmd
    pretty = switch (long "pretty" <> help "Pretty print output")
    desc = fullDesc <> progDesc "Komodo API"


main :: IO ()
main = do
  (pretty, act) <- execParser parseOpts
  res <- runExceptT act
  case res of
       Left err -> hPutStrLn stderr (show err) >> exitFailure
       Right val -> do
          let enc = if pretty then encodePretty' pconf else encode
          C8L.putStrLn $ enc val
  where
    pconf = defConfig { confCompare=compare, confIndent=Spaces 2 }
