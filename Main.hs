{-# LANGUAGE OverloadedStrings #-}
import           Control.Applicative
import           Control.Monad.IO.Class
import           Data.Int
import           Data.Text.Lazy                (Text)
import qualified Data.Text.Lazy                as T
import           Data.Text.Lazy.Encoding
import qualified Data.Text.Lazy.IO             as T
import           Network.HTTP.Types.Status
import           Network.Wai.Middleware.Static
import           System.Directory
import           System.Random
import           Web.Scotty
import           Paste.Views

main :: IO ()
main = do
    createDirectoryIfMissing True pastesDir
    scotty 8080 server


pastesDir :: FilePath
pastesDir = "pastes/"

pasteSizeLimit :: Int64
pasteSizeLimit = 512000

genPasteName :: StdGen -> String
genPasteName = take pasteLength
             . map (pasteNameChars !!)
             . randomRs (0, length pasteNameChars - 1)
    where pasteNameChars = "abcdefghjnprsuvwxyz23467"
          pasteLength = 15

readPaste :: String -> IO (Maybe Text)
readPaste x = do
    exists <- doesFileExist x
    if exists then
        Just <$> T.readFile x
    else
        return Nothing

writeNewPaste :: Text -> IO Text
writeNewPaste p = do
    name <- genPasteName <$> newStdGen
    let fname = pastesDir ++ name

    exists <- doesFileExist fname
    if exists then
        -- if we picked a name that's already in use, just try again 
        writeNewPaste p
    else do
        T.writeFile fname p
        return (T.pack name)

server :: ScottyM ()
server = do
    post "/paste" $ do
        paste <- decodeUtf8 <$> body
        let size = T.length paste
        if size > pasteSizeLimit then
            upErrTooLarge
        else do
            name <- liftIO $ writeNewPaste paste
            text name

    get "/" $ html (editPage "")

    get "/edit/:paste" $ do
        (_,paste) <- getPaste
        case paste of
            Just p  -> html (editPage p)
            Nothing -> html (editPage "")


    get "/raw/:paste" $ do
        (_,paste) <- getPaste
        case paste of
            Just p  -> text p
            Nothing -> do404

    get "/:paste" $ do
        (ftype,paste) <- getPaste
        case paste of
            Just p  -> html $ codePage ftype (T.unpack p)
            Nothing -> do404

    middleware $ staticPolicy (addBase "public/")

    notFound do404
    where do404 = do
            status notFound404
            html "<h1>Page not found :(</h1>\n"
          upErrTooLarge = do
            status requestEntityTooLarge413
            html $ "Paste size greater than " <> T.pack (show pasteSizeLimit) <> " bytes"
          getPaste = do
            pasteid <- param "paste"

            -- Split file extension from paste name, save extension for highlighting
            let parts = T.unpack <$> T.split (== '.') pasteid
                (fname, ftype) =
                    case parts of
                        -- No file extension
                        [fname] -> (fname, "")
                        -- File extension detected
                        _ -> (concat (init parts), last parts)

            contents <- liftIO $ readPaste (pastesDir ++ fname)
            return (ftype, contents)
