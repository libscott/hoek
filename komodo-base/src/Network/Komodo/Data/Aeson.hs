{-# LANGUAGE OverloadedStrings #-}

module Network.Komodo.Data.Aeson
  ( module DA
  , module DAT 
  , StrictObject
  , withStrictObject
  , (.:-)
  , (.:-?)
  ) where


import Data.Aeson as DA
import Data.Aeson.Types as DAT
import Data.IORef
import Data.HashMap.Strict
import qualified Data.Set as Set
import Data.Text

import System.IO.Unsafe


data StrictObject = StrictObject Object (IORef (Set.Set Text))

instance Show StrictObject where
  show (StrictObject o r) = show (o, unsafePerformIO $ readIORef r)


(.:-) :: FromJSON v => StrictObject -> Text -> Parser v
(.:-) so key = addKeyLookup (.:) key so


(.:-?) :: FromJSON v => StrictObject -> Text -> Parser (Maybe v)
(.:-?) so key = addKeyLookup (.:?) key so


addKeyLookup :: (Object -> Text -> Parser v) -> Text -> StrictObject -> Parser v
addKeyLookup op key (StrictObject obj ref) =
  let p = unsafePerformIO $ modifyIORef' ref $ Set.insert key
  in seq p $ op obj key


withStrictObject :: String -> (StrictObject -> Parser a) -> Value -> Parser a
withStrictObject label act = withObject label $ \obj -> do
  let ref = unsafeDepend act $ newIORef Set.empty
  r <- act $ StrictObject obj ref
  let keysRead = unsafeDepend r $ readIORef ref :: Set.Set Text
      objKeys = Set.fromList $ keys obj
      extraKeys = Set.difference objKeys keysRead
  if extraKeys /= mempty
     then let shown = setToString extraKeys
          in fail (label ++ ": extra keys: " ++ shown)
     else pure r
  where
    -- Slightly dodgy function here. It's neccesary to manually add edges
    -- to sequence pure and impure computations in this case.
    unsafeDepend a = unsafePerformIO . seq a
    setToString = unpack . intercalate "," . Set.toList
