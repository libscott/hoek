module Network.Haskoin.Transaction.Tests (tests) where

import qualified Data.ByteString                      as BS
import           Data.Either                          (fromRight, isRight)
import           Data.Serialize                       (encode)
import           Data.String                          (fromString)
import           Data.String.Conversions              (cs)
import           Data.Word                            (Word64)
import           Network.Haskoin.Crypto
import           Network.Haskoin.Script
import           Network.Haskoin.Test
import           Network.Haskoin.Transaction
import           Test.Framework
import           Test.Framework.Providers.QuickCheck2
import           Test.QuickCheck

tests :: [Test]
tests =
    [ testGroup
          "Transaction tests"
          [ testProperty "decode . encode Txid" $
            forAll arbitraryTxHash $ \h -> hexToTxHash (txHashToHex h) == Just h
          , testProperty "From string transaction id" $
            forAll arbitraryTxHash $ \h -> fromString (cs $ txHashToHex h) == h
          ]
    , testGroup
          "Building Transactions"
          [ testProperty "building address tx" $
            forAll arbitraryAddress $ forAll arbitrarySatoshi . testBuildAddrTx
          , testProperty "testing guessTxSize function" $
            forAll arbitraryAddrOnlyTx testGuessSize
          , testProperty "testing chooseCoins function" $
            forAll (listOf arbitrarySatoshi) testChooseCoins
          , testProperty "testing chooseMSCoins function" $
            forAll arbitraryMSParam $
            forAll (listOf arbitrarySatoshi) . testChooseMSCoins
          ]
    , testGroup
          "Signing Transactions"
          [ testProperty "Sign and validate transactions" $
            forAll arbitrarySigningData testDetSignTx
          , testProperty "Merge partially signed transactions" $
            forAll arbitraryPartialTxs testMergeTx
          ]
    ]

{- Building Transactions -}

testBuildAddrTx :: Address -> TestCoin -> Bool
testBuildAddrTx a (TestCoin v) =
    case a of
        PubKeyAddress h -> Right (PayPKHash h) == out
        ScriptAddress h -> Right (PayScriptHash h) == out
  where
    tx = buildAddrTx [] [(addrToBase58 a, v)]
    out =
        decodeOutputBS $
        scriptOutput $
        head $ txOut (fromRight (error "Could not build transaction") tx)

testGuessSize :: Tx -> Bool
testGuessSize tx
    -- We compute an upper bound but it should be close enough to the real size
    -- We give 2 bytes of slack on every signature (1 on r and 1 on s)
 = guess >= len && guess <= len + 2 * delta
  where
    delta = pki + sum (map fst msi)
    guess = guessTxSize pki msi pkout msout
    len = BS.length $ encode tx
    ins = map f $ txIn tx
    f i =
        fromRight (error "Could not decode input") $
        decodeInputBS $ scriptInput i
    pki = length $ filter isSpendPKHash ins
    msi = concatMap shData ins
    shData (ScriptHashInput _ (PayMulSig keys r)) = [(r, length keys)]
    shData _                                      = []
    out =
        map
            (fromRight (error "Could not decode transaction output") .
             decodeOutputBS . scriptOutput) $
        txOut tx
    pkout = length $ filter isPayPKHash out
    msout = length $ filter isPayScriptHash out

testChooseCoins :: [TestCoin] -> Word64 -> Word64 -> Int -> Property
testChooseCoins coins target byteFee nOut = nOut >= 0 ==>
    case chooseCoins target byteFee nOut True coins of
        Right (chosen, change) ->
            let outSum = sum $ map coinValue chosen
                fee    = guessTxFee byteFee nOut (length chosen)
            in outSum == target + change + fee
        Left _ ->
            let fee = guessTxFee byteFee nOut (length coins)
            in target == 0 || s < target + fee
  where
    s  = sum $ map coinValue coins

testChooseMSCoins :: (Int, Int) -> [TestCoin]
                  -> Word64 -> Word64 -> Int -> Property
testChooseMSCoins (m, n) coins target byteFee nOut = nOut >= 0 ==>
    case chooseMSCoins target byteFee (m,n) nOut True coins of
        Right (chosen,change) ->
            let outSum = sum $ map coinValue chosen
                fee    = guessMSTxFee byteFee (m,n) nOut (length chosen)
            in outSum == target + change + fee
        Left _ ->
            let fee = guessMSTxFee byteFee (m,n) nOut (length coins)
            in target == 0 || s < target + fee
  where
    s = sum $ map coinValue coins

{- Signing Transactions -}

testDetSignTx :: (Tx, [SigInput], [PrvKey]) -> Bool
testDetSignTx (tx, sigis, prv) =
    not (verifyStdTx tx verData) &&
    not (verifyStdTx txSigP verData) && verifyStdTx txSigC verData
  where
    txSigP =
        fromRight (error "Could not decode transaction") $
        signTx tx sigis (tail prv)
    txSigC =
        fromRight (error "Could not decode transaction") $
        signTx txSigP sigis [head prv]
    verData = map (\(SigInput s o _ _) -> (s, o)) sigis

testMergeTx :: ([Tx], [(ScriptOutput, OutPoint, Int, Int)]) -> Bool
testMergeTx (txs, os) = and
    [ isRight mergeRes
    , length (txIn mergedTx) == length os
    , if enoughSigs then isValid else not isValid
    -- Signature count == min (length txs) (sum required signatures)
    , sum (map snd sigMap) == min (length txs) (sum (map fst sigMap))
    ]
  where
    outs = map (\(so, op, _, _) -> (so, op)) os
    mergeRes = mergeTxs txs outs
    mergedTx = fromRight (error "Could not merge") mergeRes
    isValid = verifyStdTx mergedTx outs
    enoughSigs = all (\(m,c) -> c >= m) sigMap
    sigMap = map (\((_,_,m,_), inp) -> (m, sigCnt inp)) $ zip os $ txIn mergedTx
    sigCnt inp = case decodeInputBS $ scriptInput inp of
        Right (RegularInput (SpendMulSig sigs)) -> length sigs
        Right (ScriptHashInput (SpendMulSig sigs) _) -> length sigs
        _ -> error "Invalid input script type"

