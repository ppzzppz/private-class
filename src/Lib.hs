{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Lib
    ( someFunc
    ) where
import Happstack.Server (nullConf
                        ,simpleHTTP'
                        ,dir
                        ,ok
--                        ,ServerPart
                        ,toResponse
                        ,Response
                        ,port
                        ,logAccess
                        )
import qualified Happstack.Server as HS
-- import qualified Happstack.Server.Proxy as SP
-- import Text.RawString.QQ(r)
import Control.Monad(msum)
-- import Control.Monad.IO.Class(liftIO)
-- import qualified Text.Blaze.Html5 as H
import qualified Control.Monad.Trans.State.Lazy as SL
-- import qualified Text.Blaze.Html5.Attributes as A
import Control.Monad.Trans.Class(lift)
-- import Control.Applicative((<|>))
import qualified Data.IORef as Ref
-- happstack 中使用到的时间
import qualified Data.Time.Format as T

type MyRef = Ref.IORef (String,Int)
type MyResponse = HS.ServerPartT (SL.StateT MyRef IO) Response

someFunc :: IO ()
someFunc = do
  iomsg <- Ref.newIORef ("new",0)
  let config = nullConf {port=80,logAccess=Just logfn'}
  simpleHTTP' (unpackErrorT iomsg) config myapp
  where logfn' a0 a1 a2 a3 a4 a5 a6 a7 = putStrLn $ show $ (a0,a1,a2' a2,a3,a4,a5,a6,a7)
        a2' a2 =
          T.formatTime
            T.defaultTimeLocale
            (T.iso8601DateFormat $ Just "%H:%M:%S")
            a2

unpackErrorT :: MyRef -> SL.StateT MyRef IO b -> IO b
unpackErrorT ref unwebt = do
  SL.evalStateT unwebt ref


myapp :: MyResponse
myapp = do 
  HS.decodeBody (HS.defaultBodyPolicy "/tmp/" (10*10^(6::Int)) 1000 1000)
  msum [ dir "message" $ messageApp
       ,dir "myshar" $ HS.serveDirectory HS.EnableBrowsing [] "/shar001"
       ,my404
       ]

messageApp :: MyResponse
messageApp = msum[
  do HS.method HS.GET
     iomsg <- lift $ SL.get
     resp <- lift $ lift $ fmap fst $ Ref.readIORef $ iomsg
     ok $ toResponse $ resp
  ,
  do HS.method HS.POST
     iomsg <- lift $ SL.get
     text <-  HS.look "status-txt"
     lift $ lift $ Ref.modifyIORef iomsg $ \(_,b) -> (text,b)
     ok $ toResponse $ ("update ok"::String)
  ]

my404 :: MyResponse
my404 = HS.badRequest $ toResponse $ ("my404"::String)

{-
myapp :: MyResponse
myapp = do
  iomsg <- lift $ SL.get
  msg <- lift $ lift $ do
    txt <- fmap fst $ Ref.readIORef iomsg
    Ref.modifyIORef iomsg  $ \(str,i) -> (str ++ show i,i+1)
    return txt
  ok $ toResponse msg
-}
{-
myapp :: ServerPart Response
myapp = msum [intercept
             ,dir "myppt" $ dir "00" $ ok $ toResponse $ myppt
             ,dir "rproxy" $ SP.rproxyServe "www.vipfengxiao.com:80" []
             ,staticServer
             ,test1
             ,HS.badRequest $ toResponse $ ("404" :: String)
             ]
test1 :: ServerPart Response
test1 = do
  hello <- HS.look "hello"
  ok $ toResponse hello
intercept :: ServerPart Response
intercept = do
  req <- HS.askRq
  liftIO $ do
    putStrLn $ show req
  mempty

staticServer :: ServerPart Response
staticServer = HS.serveDirectory HS.EnableBrowsing ["index.html"] "."

myppt :: H.Html
myppt =  do
  H.html $ do
    H.head $ do
      H.title "Myppt"
    H.body $ do
      H.div "hello"
 -} 
