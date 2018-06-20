{-# OPTIONS_GHC -fno-cse -fno-full-laziness #-}
{-# LANGUAGE OverloadedStrings #-}
{-|
  Network specific constants
-}
module Network.Haskoin.Constants
( -- ** Data
  Network(..)
, prodnet
, testnet3
, regtest
  -- ** Functions
, setTestnet
, setRegtest
, setProdnet
, setKomodo
, setNetwork
, getNetwork
  -- ** Network parameters
, networkName
, addrPrefix
, scriptPrefix
, secretPrefix
, extPubKeyPrefix
, extSecretPrefix
, networkMagic
, genesisHeader
, maxBlockSize
, maxSatoshi
, haskoinUserAgent
, defaultPort
, allowMinDifficultyBlocks
, powNoRetargetting
, powLimit
, bip34Block
, bip65Height
, bip66Height
, targetTimespan
, targetSpacing
, checkpoints
, bip44Coin
, seeds
) where

import           Data.ByteString             (ByteString)
import qualified Data.ByteString.Char8       as C8 (concat, pack)
import           Data.IORef                  (IORef, newIORef, readIORef,
                                              writeIORef)
import           Data.Version                (showVersion)
import           Data.Word                   (Word32, Word64, Word8)
import           Network.Haskoin.Block.Types
import           Paths_haskoin_core          (version)
import           System.IO.Unsafe            (unsafePerformIO)

data Network = Network
    { getNetworkName              :: !String
    , getAddrPrefix               :: !Word8
    , getScriptPrefix             :: !Word8
    , getSecretPrefix             :: !Word8
    , getExtPubKeyPrefix          :: !Word32
    , getExtSecretPrefix          :: !Word32
    , getNetworkMagic             :: !Word32
    , getGenesisHeader            :: !BlockHeader
    , getMaxBlockSize             :: !Int
    , getMaxSatoshi               :: !Word64
    , getHaskoinUserAgent         :: !ByteString
    , getDefaultPort              :: !Int
    , getAllowMinDifficultyBlocks :: !Bool
    , getPowNoRetargetting        :: !Bool
    , getPowLimit                 :: !Integer
    , getBip34Block               :: !(BlockHeight, BlockHash)
    , getBip65Height              :: !BlockHeight
    , getBip66Height              :: !BlockHeight
    , getTargetTimespan           :: !Word32
    , getTargetSpacing            :: !Word32
    , getCheckpoints              :: ![(BlockHeight, BlockHash)]
    , getBip44Coin                :: !Word32
    , getSeeds                    :: [String]
    } deriving Eq

setRegtest :: IO ()
setRegtest = setNetwork regtest

setTestnet :: IO ()
setTestnet = setNetwork testnet3

setProdnet :: IO ()
setProdnet = setNetwork prodnet

setKomodo :: IO ()
setKomodo = setNetwork komodo

setNetwork :: Network -> IO ()
setNetwork net = writeIORef networkRef net >> writeIORef networkSetRef True

{-# NOINLINE networkRef #-}
networkRef :: IORef Network
networkRef = unsafePerformIO $ newIORef komodo

{-# NOINLINE networkSetRef #-}
networkSetRef :: IORef Bool
networkSetRef = unsafePerformIO $ newIORef True

{-# NOINLINE getNetwork #-}
getNetwork :: Network
getNetwork =
    let (net, set) = unsafePerformIO $
                     (,) <$> readIORef networkRef <*> readIORef networkSetRef
    in if set
       then net
       else error "Use Network.Haskoin.Constants.setNetwork"

networkName :: String
networkName = getNetworkName getNetwork

addrPrefix :: Word8
addrPrefix = getAddrPrefix getNetwork

scriptPrefix :: Word8
scriptPrefix = getScriptPrefix getNetwork

secretPrefix :: Word8
secretPrefix = getSecretPrefix getNetwork

extPubKeyPrefix :: Word32
extPubKeyPrefix = getExtPubKeyPrefix getNetwork

extSecretPrefix :: Word32
extSecretPrefix = getExtSecretPrefix getNetwork

networkMagic :: Word32
networkMagic = getNetworkMagic getNetwork

genesisHeader :: BlockHeader
genesisHeader = getGenesisHeader getNetwork

maxBlockSize :: Int
maxBlockSize = getMaxBlockSize getNetwork

maxSatoshi :: Word64
maxSatoshi = getMaxSatoshi getNetwork

haskoinUserAgent :: ByteString
haskoinUserAgent = getHaskoinUserAgent getNetwork

defaultPort :: Int
defaultPort = getDefaultPort getNetwork

allowMinDifficultyBlocks :: Bool
allowMinDifficultyBlocks = getAllowMinDifficultyBlocks getNetwork

powNoRetargetting :: Bool
powNoRetargetting = getPowNoRetargetting getNetwork

powLimit :: Integer
powLimit = getPowLimit getNetwork

-- | Version 2 blocks start here.
bip34Block :: (BlockHeight, BlockHash)
bip34Block = getBip34Block getNetwork

-- | Version 3 blocks start here.
bip65Height :: BlockHeight
bip65Height = getBip65Height getNetwork

-- | Version 4 blocks start here.
bip66Height :: BlockHeight
bip66Height = getBip66Height getNetwork

-- | Time between difficulty cycles (2 weeks on average).
targetTimespan :: Word32
targetTimespan = getTargetTimespan getNetwork

-- | Time between blocks (10 minutes per block).
targetSpacing :: Word32
targetSpacing = getTargetSpacing getNetwork

-- | Checkpoints to enfore.
checkpoints :: [(Word32, BlockHash)]
checkpoints = getCheckpoints getNetwork

-- | Bip44 coin derivation (m/44'/coin'/account'/internal/address/)
bip44Coin :: Word32
bip44Coin = getBip44Coin getNetwork

-- | DNS seeds.
seeds :: [String]
seeds = getSeeds getNetwork

komodo :: Network
komodo = Network
    { getNetworkName = "komodo"
    , getAddrPrefix = 60
    , getScriptPrefix = 85
    , getSecretPrefix = 188
    , getExtPubKeyPrefix = 0x0488b21e
    , getExtSecretPrefix = 0x0488ade4

    -- FROM HERE DOWN IS UNVERIFIED

    , getNetworkMagic = 0xf9beb4d9
    , getGenesisHeader =
        BlockHeader
            0x01
            "0000000000000000000000000000000000000000000000000000000000000000"
            "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"
            1231006505
            0x1d00ffff
            2083236893
            -- Hash 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
    , getMaxBlockSize = 1000000
    , getMaxSatoshi = 2100000000000000
    , getHaskoinUserAgent = C8.concat
        [ "/haskoin:"
        , C8.pack $ showVersion version
        , "/" ]
    , getDefaultPort = 8333
    , getAllowMinDifficultyBlocks = False
    , getPowNoRetargetting = False
    , getPowLimit =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    , getBip34Block =
        ( 227931
        , "000000000000024b89b42a942fe0d9fea3bb44ab7bd1b19115dd6a759c0808b8" )
    , getBip65Height = 388381
    , getBip66Height = 363725
    , getTargetTimespan = 14 * 24 * 60 * 60
    , getTargetSpacing = 10 * 60
    , getCheckpoints =
        [ ( 11111
          , "0000000069e244f73d78e8fd29ba2fd2ed618bd6fa2ee92559f542fdb26e7c1d" )
        , ( 33333
          , "000000002dd5588a74784eaa7ab0507a18ad16a236e7b1ce69f00d7ddfb5d0a6" )
        , ( 74000
          , "0000000000573993a3c9e41ce34471c079dcf5f52a0e824a81e7f953b8661a20" )
        , ( 105000
          , "00000000000291ce28027faea320c8d2b054b2e0fe44a773f3eefb151d6bdc97" )
        , ( 134444
          , "00000000000005b12ffd4cd315cd34ffd4a594f430ac814c91184a0d42d2b0fe" )
        , ( 168000
          , "000000000000099e61ea72015e79632f216fe6cb33d7899acb35b75c8303b763" )
        , ( 193000
          , "000000000000059f452a5f7340de6682a977387c17010ff6e6c3bd83ca8b1317" )
        , ( 210000
          , "000000000000048b95347e83192f69cf0366076336c639f9b7228e9ba171342e" )
        , ( 216116
          , "00000000000001b4f4b433e81ee46494af945cf96014816a4e2370f11b23df4e" )
        , ( 225430
          , "00000000000001c108384350f74090433e7fcf79a606b8e797f065b130575932" )
        , ( 250000
          , "000000000000003887df1f29024b06fc2200b55f8af8f35453d7be294df2d214" )
        , ( 279000
          , "0000000000000001ae8c72a0b0c301f67e3afca10e819efa9041e458e9bd7e40" )
        ]
    , getSeeds =
        [ "seed.mainnet.b-pay.net"        -- BitPay
        , "seed.ob1.io"                   -- OB1
        , "seed.blockchain.info"          -- Blockchain
        , "bitcoin.bloqseeds.net"         -- Bloq
        , "seed.bitcoin.sipa.be"          -- Pieter Wuille
        , "dnsseed.bluematt.me"           -- Matt Corallo
        , "dnsseed.bitcoin.dashjr.org"    -- Luke Dashjr
        , "seed.bitcoinstats.com"         -- Chris Decker
        , "seed.bitcoin.jonasschnelli.ch" -- Jonas Schnelli
        ]
    , getBip44Coin = 0
    }


prodnet :: Network
prodnet = Network
    { getNetworkName = "prodnet"
    , getAddrPrefix = 0
    , getScriptPrefix = 5
    , getSecretPrefix = 128
    , getExtPubKeyPrefix = 0x0488b21e
    , getExtSecretPrefix = 0x0488ade4
    , getNetworkMagic = 0xf9beb4d9
    , getGenesisHeader =
        BlockHeader
            0x01
            "0000000000000000000000000000000000000000000000000000000000000000"
            "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"
            1231006505
            0x1d00ffff
            2083236893
            -- Hash 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f
    , getMaxBlockSize = 1000000
    , getMaxSatoshi = 2100000000000000
    , getHaskoinUserAgent = C8.concat
        [ "/haskoin:"
        , C8.pack $ showVersion version
        , "/" ]
    , getDefaultPort = 8333
    , getAllowMinDifficultyBlocks = False
    , getPowNoRetargetting = False
    , getPowLimit =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    , getBip34Block =
        ( 227931
        , "000000000000024b89b42a942fe0d9fea3bb44ab7bd1b19115dd6a759c0808b8" )
    , getBip65Height = 388381
    , getBip66Height = 363725
    , getTargetTimespan = 14 * 24 * 60 * 60
    , getTargetSpacing = 10 * 60
    , getCheckpoints =
        [ ( 11111
          , "0000000069e244f73d78e8fd29ba2fd2ed618bd6fa2ee92559f542fdb26e7c1d" )
        , ( 33333
          , "000000002dd5588a74784eaa7ab0507a18ad16a236e7b1ce69f00d7ddfb5d0a6" )
        , ( 74000
          , "0000000000573993a3c9e41ce34471c079dcf5f52a0e824a81e7f953b8661a20" )
        , ( 105000
          , "00000000000291ce28027faea320c8d2b054b2e0fe44a773f3eefb151d6bdc97" )
        , ( 134444
          , "00000000000005b12ffd4cd315cd34ffd4a594f430ac814c91184a0d42d2b0fe" )
        , ( 168000
          , "000000000000099e61ea72015e79632f216fe6cb33d7899acb35b75c8303b763" )
        , ( 193000
          , "000000000000059f452a5f7340de6682a977387c17010ff6e6c3bd83ca8b1317" )
        , ( 210000
          , "000000000000048b95347e83192f69cf0366076336c639f9b7228e9ba171342e" )
        , ( 216116
          , "00000000000001b4f4b433e81ee46494af945cf96014816a4e2370f11b23df4e" )
        , ( 225430
          , "00000000000001c108384350f74090433e7fcf79a606b8e797f065b130575932" )
        , ( 250000
          , "000000000000003887df1f29024b06fc2200b55f8af8f35453d7be294df2d214" )
        , ( 279000
          , "0000000000000001ae8c72a0b0c301f67e3afca10e819efa9041e458e9bd7e40" )
        ]
    , getSeeds =
        [ "seed.mainnet.b-pay.net"        -- BitPay
        , "seed.ob1.io"                   -- OB1
        , "seed.blockchain.info"          -- Blockchain
        , "bitcoin.bloqseeds.net"         -- Bloq
        , "seed.bitcoin.sipa.be"          -- Pieter Wuille
        , "dnsseed.bluematt.me"           -- Matt Corallo
        , "dnsseed.bitcoin.dashjr.org"    -- Luke Dashjr
        , "seed.bitcoinstats.com"         -- Chris Decker
        , "seed.bitcoin.jonasschnelli.ch" -- Jonas Schnelli
        ]
    , getBip44Coin = 0
    }

testnet3 :: Network
testnet3 = Network
    { getNetworkName = "testnet3"
    , getAddrPrefix = 111
    , getScriptPrefix = 196
    , getSecretPrefix = 239
    , getExtPubKeyPrefix = 0x043587cf
    , getExtSecretPrefix = 0x04358394
    , getNetworkMagic = 0x0b110907
    , getGenesisHeader =
        BlockHeader
            0x01
            "0000000000000000000000000000000000000000000000000000000000000000"
            "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"
            1296688602
            486604799
            414098458
            -- Hash 000000000933ea01ad0ee984209779baaec3ced90fa3f408719526f8d77f4943
    , getMaxBlockSize = 1000000
    , getMaxSatoshi = 2100000000000000
    , getHaskoinUserAgent =
        C8.concat
            [ "/haskoin-testnet3:"
            , C8.pack $ showVersion version
            , "/"
            ]
    , getDefaultPort = 18333
    , getAllowMinDifficultyBlocks = True
    , getPowNoRetargetting = False
    , getPowLimit =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    , getBip34Block =
        ( 21111
        , "0000000023b3a96d3484e5abb3755c413e7d41500f8e2a5c3f0dd01299cd8ef8"
        )
    , getBip65Height = 581885
    , getBip66Height = 330776
    , getTargetTimespan = 14 * 24 * 60 * 60
    , getTargetSpacing = 10 * 60
    , getCheckpoints =
        [ ( 546
          , "000000002a936ca763904c3c35fce2f3556c559c0214345d31b1bcebf76acb70"
          )
        ]
    , getSeeds =
        [ "testnet-seed.bitcoin.jonasschnelli.ch"
        , "seed.tbtc.petertodd.org"
        , "testnet-seed.bluematt.me"
        , "testnet-seed.bitcoin.schildbach.de"
        ]
    , getBip44Coin = 1
    }

regtest :: Network
regtest = Network
    { getNetworkName = "regtest"
    , getAddrPrefix = 111
    , getScriptPrefix = 196
    , getSecretPrefix = 239
    , getExtPubKeyPrefix = 0x043587cf
    , getExtSecretPrefix = 0x04358394
    , getNetworkMagic = 0xfabfb5da
    , getGenesisHeader = BlockHeader
        -- 0f9188f13cb7b2c71f2a335e3a4fc328bf5beb436012afca590b1a11466e2206
        0x01
        "0000000000000000000000000000000000000000000000000000000000000000"
        "3ba3edfd7a7b12b27ac72c3e67768f617fc81bc3888a51323a9fb8aa4b1e5e4a"
        1296688602
        0x207fffff
        2
    , getMaxBlockSize = 1000000
    , getMaxSatoshi = 2100000000000000
    , getHaskoinUserAgent = C8.concat
        [ "/haskoin-regtest:"
        , C8.pack $ showVersion version
        , "/" ]
    , getDefaultPort = 18444
    , getAllowMinDifficultyBlocks = True
    , getPowNoRetargetting = True
    , getPowLimit =
        0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
    , getBip34Block =
        ( 100000000
        , "0000000000000000000000000000000000000000000000000000000000000000" )
    , getBip65Height = 1351
    , getBip66Height = 1251
    , getTargetTimespan = 14 * 24 * 60 * 60
    , getTargetSpacing = 10 * 60
    , getCheckpoints = []
    , getSeeds = [ "localhost" ]
    , getBip44Coin = 1
    }
