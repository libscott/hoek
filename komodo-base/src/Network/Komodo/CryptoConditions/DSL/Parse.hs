{-# LANGUAGE OverloadedStrings #-}

module Network.Komodo.CryptoConditions.DSL.Parse
  ( parseDSL
  ) where


import           Control.Applicative
import           Control.Monad.Trans.Except

import           Data.Attoparsec.Text
import           Data.Functor.Identity
import qualified Data.Text as T
import           Data.Monoid

import           Network.Komodo.Crypto
import           Network.Komodo.Crypto.B58Keys
import           Network.Komodo.CryptoConditions.Types


type CryptoCondition = Condition


parseDSL :: T.Text -> Except String CryptoCondition
parseDSL t = complete $ parse dslParser t
  where
    complete (Done _ r) = return r
    complete (Partial f) = complete $ f ""
    complete (Fail rest _ msg) =
      let offset = T.length t - T.length rest
          mmsg = msg <> " at char " <> show offset
       in throwE mmsg


dslParser :: Parser CryptoCondition
dslParser = cond <* (endOfInput <|> fail "Expected end")
  where
    ss = skipSpace
    ex s = string s <|> fail ("Expected \"" <> T.unpack s <> "\"")
    cond :: Parser CryptoCondition
    cond = ss *> 
      expect2 thresholdHead ed25519
              "Expected \"({num} of ...\" or ed25519 key"
    thresholdHead = "(" *> ss *> (thresholdRest <$> decimal) <* ss <* "of" <* ss
    thresholdRest 0 = fail "Illegal threshold: 0"
    thresholdRest t = do
      subs <- inner <* ss <* ex ")" <* ss
      if fromIntegral t > length subs
         then fail "Impossible threshold"
         else pure (Threshold t subs)
    subcondition = flip replicate <$> cond <*> weight
    inner = concat <$> sepBy1 subcondition (ss >> "," >> ss)
    weight = (ss *> "*" *> ss *> decimal) <|> pure 1
    -- TODO: This needs to return a better error for invalid PKs
    ed25519 = do
      (t, l) <- runScanner 0 (\l c -> if isBase58 c then Just (l+1) else Nothing)
      if (l::Int) == 43 || l == 44
         then do (PK k) <- exceptToFail (parseKey t)
                 pure $ pure $ Ed25519 k Nothing
         else fail "Not a public key"


exceptToFail :: Monad m => Except String a -> m a
exceptToFail = either fail pure . runIdentity . runExceptT


isBase58 :: Char -> Bool
isBase58 c = (c >= 'a' && c <= 'z' && c /= 'l')
          || (c <= '9' && c >= '1')
          || (c >= 'A' && c <= 'Z' && c /= 'I' && c /= 'O')


-- | Attoparsec backtracks on every failure, which makes it hard to track the
--   source of errors. The remedy to this is to identify a branch before
--   parsing all of it, otherwise alternate branches will eat the error message.
expect2 :: Parser (Parser a) -> Parser (Parser a) -> String -> Parser a
expect2 pred1 pred2 err = do
  res <- pred1 <|> pred2 <|> fail err
  res

