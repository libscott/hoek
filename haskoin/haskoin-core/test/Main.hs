module Main where

import           Network.Haskoin.Constants                 (setProdnet)
import           Test.Framework                            (defaultMain)

-- Util tests
import qualified Network.Haskoin.Util.Tests                (tests)

-- Crypto tests
import qualified Network.Haskoin.Crypto.Base58.Tests       (tests)
import qualified Network.Haskoin.Crypto.Base58.Units       (tests)
import qualified Network.Haskoin.Crypto.ECDSA.Tests        (tests)
import qualified Network.Haskoin.Crypto.ExtendedKeys.Tests (tests)
import qualified Network.Haskoin.Crypto.ExtendedKeys.Units (tests)
import qualified Network.Haskoin.Crypto.Hash.Tests         (tests)
import qualified Network.Haskoin.Crypto.Hash.Units         (tests)
import qualified Network.Haskoin.Crypto.Keys.Tests         (tests)
import qualified Network.Haskoin.Crypto.Mnemonic.Tests     (tests)
import qualified Network.Haskoin.Crypto.Mnemonic.Units     (tests)
import qualified Network.Haskoin.Crypto.Units              (tests)

-- Network tests
import qualified Network.Haskoin.Network.Units             (tests)

-- Script tests
import qualified Network.Haskoin.Script.Tests              (tests)
import qualified Network.Haskoin.Script.Units              (tests)

-- Transaction tests
import qualified Network.Haskoin.Transaction.Tests         (tests)
import qualified Network.Haskoin.Transaction.Units         (satoshiCoreTxTests,
                                                            tests)

-- Block tests
import qualified Network.Haskoin.Block.Tests               (tests)
import qualified Network.Haskoin.Block.Units               (tests)

-- Json tests
import qualified Network.Haskoin.Json.Tests                (tests)

-- Binary tests
import qualified Network.Haskoin.Cereal.Tests              (tests)

main :: IO ()
main = do
  setProdnet
  satoshiTxTests <- Network.Haskoin.Transaction.Units.satoshiCoreTxTests
  defaultMain
    (  Network.Haskoin.Json.Tests.tests
    ++ Network.Haskoin.Cereal.Tests.tests
    ++ Network.Haskoin.Util.Tests.tests
    ++ Network.Haskoin.Crypto.ECDSA.Tests.tests
    ++ Network.Haskoin.Crypto.Base58.Tests.tests
    ++ Network.Haskoin.Crypto.Base58.Units.tests
    ++ Network.Haskoin.Crypto.Hash.Tests.tests
    ++ Network.Haskoin.Crypto.Hash.Units.tests
    ++ Network.Haskoin.Crypto.Keys.Tests.tests
    ++ Network.Haskoin.Crypto.ExtendedKeys.Tests.tests
    ++ Network.Haskoin.Crypto.ExtendedKeys.Units.tests
    ++ Network.Haskoin.Crypto.Mnemonic.Tests.tests
    ++ Network.Haskoin.Crypto.Mnemonic.Units.tests
    ++ Network.Haskoin.Crypto.Units.tests
    ++ Network.Haskoin.Network.Units.tests
    ++ Network.Haskoin.Script.Tests.tests
    ++ Network.Haskoin.Script.Units.tests
    ++ Network.Haskoin.Transaction.Tests.tests
    ++ Network.Haskoin.Transaction.Units.tests
    ++ satoshiTxTests
    ++ Network.Haskoin.Block.Tests.tests
    ++ Network.Haskoin.Block.Units.tests
    )

