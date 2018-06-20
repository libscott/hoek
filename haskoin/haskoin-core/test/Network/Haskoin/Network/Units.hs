{-# LANGUAGE OverloadedStrings #-}
module Network.Haskoin.Network.Units (tests) where

import           Data.ByteString                (ByteString)
import           Data.Maybe                     (fromJust)
import           Data.Serialize                 (encode)
import           Data.Word                      (Word32)
import           Network.Haskoin.Crypto
import           Network.Haskoin.Network
import           Network.Haskoin.Util
import           Test.Framework                 (Test, testGroup)
import           Test.Framework.Providers.HUnit (testCase)
import           Test.HUnit                     (Assertion, assertBool)

tests :: [Test]
tests =
    [ -- Test cases come from bitcoind /src/test/bloom_tests.cpp
      testGroup "Bloom Filters"
        [ testCase "Bloom Filter Vector 1" bloomFilter1
        , testCase "Bloom Filter Vector 2" bloomFilter2
        , testCase "Bloom Filter Vector 3" bloomFilter3
        ]
    ]

bloomFilter :: Word32 -> ByteString -> Assertion
bloomFilter n x = do
    assertBool "Bloom filter doesn't contain vector 1" $ bloomContains f1 v1
    assertBool "Bloom filter contains something it should not" $
        not $ bloomContains f1 v2
    assertBool "Bloom filter doesn't contain vector 3" $ bloomContains f3 v3
    assertBool "Bloom filter doesn't contain vector 4" $ bloomContains f4 v4
    assertBool "Bloom filter serialization is incorrect" $
        encode f4 == bs
  where
    f0 = bloomCreate 3 0.01 n BloomUpdateAll
    f1 = bloomInsert f0 v1
    f3 = bloomInsert f1 v3
    f4 = bloomInsert f3 v4
    v1 = fromJust $ decodeHex "99108ad8ed9bb6274d3980bab5a85c048f0950c8"
    v2 = fromJust $ decodeHex "19108ad8ed9bb6274d3980bab5a85c048f0950c8"
    v3 = fromJust $ decodeHex "b5a2c786d9ef4658287ced5914b37a1b4aa32eee"
    v4 = fromJust $ decodeHex "b9300670b4c5366e95b2699e8b18bc75e5f729c5"
    bs = fromJust $ decodeHex x

bloomFilter1 :: Assertion
bloomFilter1 = bloomFilter 0 "03614e9b050000000000000001"

bloomFilter2 :: Assertion
bloomFilter2 = bloomFilter 2147483649 "03ce4299050000000100008001"

bloomFilter3 :: Assertion
bloomFilter3 =
    assertBool "Bloom filter serialization is incorrect" $
        encode f2 == bs
  where
    f0 = bloomCreate 2 0.001 0 BloomUpdateAll
    f1 = bloomInsert f0 $ encode p
    f2 = bloomInsert f1 $ encode $ getAddrHash $ pubKeyAddr p
    k = fromJust $ fromWif "5Kg1gnAjaLfKiwhhPpGS3QfRg2m6awQvaj98JCZBZQ5SuS2F15C"
    p = derivePubKey k
    bs = fromJust $ decodeHex "038fc16b080000000000000001"
