{-# LANGUAGE GeneralizedNewtypeDeriving #-}
module Network.Haskoin.Transaction.Types
( Tx
, createTx
, txVersion
, txIn
, txOut
, txLockTime
, txHash
, TxIn(..)
, TxOut(..)
, OutPoint(..)
, TxHash(..)
, hexToTxHash
, txHashToHex
, nosigTxHash
) where

import           Control.DeepSeq               (NFData, rnf)
import           Control.Monad                 (forM_, liftM2, mzero,
                                                replicateM, (<=<))
import           Data.Aeson                    (FromJSON, ToJSON,
                                                Value (String), parseJSON,
                                                toJSON, withText)
import           Data.ByteString               (ByteString)
import qualified Data.ByteString               as BS
import           Data.Hashable                 (Hashable)
import           Data.Maybe                    (fromMaybe, maybe)
import           Data.Serialize                (Serialize, decode, encode, get,
                                                put)
import           Data.Serialize.Get            (getByteString, getWord32le,
                                                getWord64le)
import           Data.Serialize.Put            (putByteString, putWord32le,
                                                putWord64le)
import           Data.String                   (IsString, fromString)
import           Data.String.Conversions       (cs)
import           Data.Word                     (Word32, Word64)
import           Network.Haskoin.Crypto.Hash
import           Network.Haskoin.Network.Types
import           Network.Haskoin.Util

newtype TxHash = TxHash { getTxHash :: Hash256 }
    deriving (Eq, Ord, NFData, Hashable, Serialize)

instance Show TxHash where
    show = cs . txHashToHex

instance IsString TxHash where
    fromString s =
        let e = error "Could not read transaction hash from hex string"
        in fromMaybe e $ hexToTxHash $ cs s

instance FromJSON TxHash where
    parseJSON = withText "Transaction id" $ \t ->
        maybe mzero return $ hexToTxHash $ cs t

instance ToJSON TxHash where
    toJSON = String . cs . txHashToHex

nosigTxHash :: Tx -> TxHash
nosigTxHash tx =
    TxHash $ doubleHash256 $ encode tx { txIn = map clearInput $ txIn tx }
  where
    clearInput ti = ti { scriptInput = BS.empty }

txHashToHex :: TxHash -> ByteString
txHashToHex (TxHash h) = encodeHex (BS.reverse (encode h))

hexToTxHash :: ByteString -> Maybe TxHash
hexToTxHash hex = do
    bs <- BS.reverse <$> decodeHex hex
    h <- either (const Nothing) Just (decode bs)
    return $ TxHash h

-- | Data type representing a bitcoin transaction
data Tx = Tx
    { -- | Transaction data format version
      txVersion  :: !Word32
      -- | List of transaction inputs
    , txIn       :: ![TxIn]
      -- | List of transaction outputs
    , txOut      :: ![TxOut]
      -- | The block number of timestamp at which this transaction is locked
    , txLockTime :: !Word32
    } deriving (Eq)

txHash :: Tx -> TxHash
txHash = TxHash . doubleHash256 . encode

createTx :: Word32 -> [TxIn] -> [TxOut] -> Word32 -> Tx
createTx v is os l =
    Tx { txVersion  = v
       , txIn       = is
       , txOut      = os
       , txLockTime = l
       }

instance Show Tx where
    show = show . encodeHex . encode

instance IsString Tx where
    fromString =
        fromMaybe e . (eitherToMaybe . decode <=< decodeHex) . cs
      where
        e = error "Could not read transaction from hex string"

instance NFData Tx where
    rnf (Tx v i o l) = rnf v `seq` rnf i `seq` rnf o `seq` rnf l

instance Serialize Tx where
    get = do
        v  <- getWord32le
        is <- replicateList =<< get
        os <- replicateList =<< get
        l  <- getWord32le
        return Tx { txVersion  = v
                  , txIn       = is
                  , txOut      = os
                  , txLockTime = l
                  }
      where
        replicateList (VarInt c) = replicateM (fromIntegral c) get

    put (Tx v is os l) = do
        putWord32le v
        put $ VarInt $ fromIntegral $ length is
        forM_ is put
        put $ VarInt $ fromIntegral $ length os
        forM_ os put
        putWord32le l

instance FromJSON Tx where
    parseJSON = withText "Tx" $
        maybe mzero return . (eitherToMaybe . decode <=< decodeHex) . cs

instance ToJSON Tx where
    toJSON = String . cs . encodeHex . encode

-- | Data type representing a transaction input.
data TxIn =
    TxIn {
           -- | Reference the previous transaction output (hash + position)
           prevOutput   :: !OutPoint
           -- | Script providing the requirements of the previous transaction
           -- output to spend those coins.
         , scriptInput  :: !ByteString
           -- | BIP-68:
           -- Relative lock-time using consensus-enforced sequence numbers
         , txInSequence :: !Word32
         } deriving (Eq, Show)

instance NFData TxIn where
    rnf (TxIn p i s) = rnf p `seq` rnf i `seq` rnf s

instance Serialize TxIn where
    get =
        TxIn <$> get <*> (readBS =<< get) <*> getWord32le
      where
        readBS (VarInt len) = getByteString $ fromIntegral len

    put (TxIn o s q) = do
        put o
        put $ VarInt $ fromIntegral $ BS.length s
        putByteString s
        putWord32le q

-- | Data type representing a transaction output.
data TxOut =
    TxOut {
            -- | Transaction output value.
            outValue     :: !Word64
            -- | Script specifying the conditions to spend this output.
          , scriptOutput :: !ByteString
          } deriving (Eq, Show, Read)

instance NFData TxOut where
    rnf (TxOut v o) = rnf v `seq` rnf o

instance Serialize TxOut where
    get = do
        val <- getWord64le
        (VarInt len) <- get
        TxOut val <$> getByteString (fromIntegral len)

    put (TxOut o s) = do
        putWord64le o
        put $ VarInt $ fromIntegral $ BS.length s
        putByteString s

-- | The OutPoint is used inside a transaction input to reference the previous
-- transaction output that it is spending.
data OutPoint = OutPoint
    { -- | The hash of the referenced transaction.
      outPointHash  :: !TxHash
      -- | The position of the specific output in the transaction.
      -- The first output position is 0.
    , outPointIndex :: !Word32
    } deriving (Show, Eq)

instance NFData OutPoint where
    rnf (OutPoint h i) = rnf h `seq` rnf i

instance FromJSON OutPoint where
    parseJSON = withText "OutPoint" $
        maybe mzero return . (eitherToMaybe . decode <=< decodeHex) . cs

instance ToJSON OutPoint where
    toJSON = String . cs . encodeHex . encode

instance Serialize OutPoint where
    get = do
        (h,i) <- liftM2 (,) get getWord32le
        return $ OutPoint h i
    put (OutPoint h i) = put h >> putWord32le i
