import XMonad
import XMonad.Actions.GridSelect
import XMonad.Actions.WindowBringer
import XMonad.Actions.SpawnOn
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.ManageHelpers
import XMonad.Hooks.UrgencyHook
import XMonad.Hooks.EwmhDesktops
import XMonad.Hooks.SetWMName
import XMonad.Util.Run
import XMonad.Util.EZConfig
import XMonad.Layout.NoBorders
import XMonad.Layout.Spiral
import XMonad.Layout.TrackFloating
import XMonad.Layout.MosaicAlt
import XMonad.Layout.PerWorkspace

import XMonad.Layout.Tabbed

import XMonad.Prompt
import XMonad.Prompt.Shell
import XMonad.Prompt.Window
import qualified Data.Map as M
import qualified XMonad.StackSet as W


import Data.List
import Data.Monoid

import System.IO
import System.Exit

import Text.EditDistance
import Text.Regex.Posix

main :: IO ()
main = do
  h <- spawnPipe "xmobar"
  xmonad $ fullscreenFix $ ewmh $ withUrgencyHook NoUrgencyHook $ defaultConfig
    { borderWidth = 1
    , normalBorderColor = "#202030"
    , focusedBorderColor = "#a0a0d0"
    , terminal    = "urxvtc"
    , modMask     = mod4Mask
    , workspaces  = myWorkspaces
    -- key bindings
    , keys = myKeys
    -- hooks, layouts
    , layoutHook = avoidStruts $ lessBorders Screen $ myLayout
    , manageHook = myManageHook
    , logHook    = dynamicLogWithPP $ xmobarPP { ppOutput = hPutStrLn h }
    , handleEventHook = handleEventHook defaultConfig <+> fullscreenEventHook <+> docksEventHook
    }

--myTheme = defaultTheme
--    { fontName = "xft:Fira Mono:pixelsize=12" }

myWorkspaces = ["sh", "www", "irc", "im", "media", "office", "blender", "img", "game", "email", "misc", "emacs"]

myManageHook :: Query (Endo WindowSet)
myManageHook = composeAll $ map
               (uncurry shiftClass) myClasses <+>
               map (uncurry shiftResource) myResources <+>
               map (uncurry shiftTitle) myTitles <+>
               map shiftGame myGames <+>
               allowFullFloatHook

myLayout = onWorkspace "game" (avoidStrutsOn [] . noBorders $ Full) $
           avoidStruts $
           tiled ||| Mirror tiled ||| Full ||| simpleTabbed  ||| spiral (1 / 1.618)
   where
-- default tiling algorithm partitions the screen into two panes
    tiled = Tall nmaster delta ratio
-- The default number of windows in the master pane
    nmaster = 1
-- Default proportion of screen occupied by master pane
    ratio = 1/2
-- Percent of screen to increment by when resizing panes
    delta = 3/100

allowFullFloatHook = [ isFullscreen --> doFullFloat
                     , isDialog --> doFloat
                     , className =? "Steam" --> doFloat
                     , className =? "Steam - Self Updater" --> doFloat
                     ] ++ map fullFloatGame myGames

myClasses :: [(String, String)]
myClasses = [ ("Firefox",     "www")
            , ("Midori",      "www")
            , ("Chromium",    "www")
            , ("Dwb",         "www")
            , ("Pidgin",      "im")
            , ("Vlc",         "media")
            , ("MPlayer",     "media")
            , ("mpv",         "media")
            , ("Pavucontrol", "media")
            , ("CodeBlocks",  "office")
            , ("QtCreator",   "office")
            , ("Eclipse",     "office")
            , ("libreoffice-startcenter", "office")
            , ("Gummi",       "office")
            , ("Blender",     "blender")
            , ("feh",         "img")
            , ("Gimp",        "img")
            , ("Inkscape",    "img")
            , ("Steam",       "game")
            , ("ThunderBird", "email")
            , ("FBReader",    "misc")
            , ("Emacs",       "emacs") ]

myResources :: [(String, String)]
myResources = [ ("weechat",      "irc")
              , ("ncmpcpp",      "media")]
              
myTitles :: [(String, String)]
myTitles = [ ("Steam - Self Updater",   "game") ]
           
myGames :: [String]
myGames = [ "hl2_linux"
          , "SuperMeatBoy"
          , "dota_linux"
          , "TWTM_linux"
          , "Surgeon Simulator 2013"
          , "Electronic Super Joy"
          , "XCOM: Enemy Unknown"
          , "teleglitch32"
          , "Crypt of the NecroDancer"
          , "Minetest"
          , "ufo"
          , "spring"
          , "mangclient" ]

fullFloatGame name = className =? name <||> title =? name --> doFullFloat

shiftGame :: String -> Query (Data.Monoid.Endo WindowSet)
shiftGame name = shiftCTR name "game"

shiftClass :: String -> WorkspaceId -> Query (Data.Monoid.Endo WindowSet)
shiftClass name workspace = className =? name --> doShift workspace

shiftResource :: String -> WorkspaceId -> Query (Data.Monoid.Endo WindowSet)
shiftResource name workspace = resource =? name --> doShift workspace

shiftTitle :: String -> WorkspaceId -> Query (Data.Monoid.Endo WindowSet)
shiftTitle name workspace = title =? name --> doShift workspace

shiftCTR :: String -> WorkspaceId -> Query (Data.Monoid.Endo WindowSet)
shiftCTR name workspace = className =? name <||> title =? name --> doShift workspace

myKeys c = mkKeymap c $
           -- xmonad hotkeys
           [ ("M-<Return>"     , spawn $ terminal c)
           , ("M-r" , shellPrompt defaultXPConfig {position = Top})
           , ("M-c"            , kill)
           , ("M-<Space>"      , sendMessage NextLayout)
           , ("M1-<Tab>"       , windows W.focusDown)
           , ("M1-<Backspace>" , windows W.focusUp)
           , ("M-<Down>"       , windows W.swapDown)
           , ("M-<Up>"         , windows W.swapUp)
           , ("M-<Left>"       , sendMessage Shrink)
           , ("M-<Right>"      , sendMessage Expand)
           , ("M-,"            , sendMessage (IncMasterN (1)))
           , ("M-."            , sendMessage (IncMasterN (-1)))
           , ("M-t"            , withFocused $ windows . W.sink)
           , ("M-q"            , spawn "xmonad --recompile; xmonad --restart")
           , ("M-b"            , sendMessage ToggleStruts)
             -- system volume hotkeys
           , ("<XF86AudioRaiseVolume>", spawn "amixer -c0 -- sset Master Playback 2dB+")
           , ("<XF86AudioLowerVolume>", spawn "amixer -c0 -- sset Master Playback 2dB-")
             -- mpd hotkeys
           , ("<XF86AudioMute>" , spawn "~/bin/pc mute")
           , ("<XF86AudioPlay>", spawn "mpc toggle")
           , ("<XF86AudioPrev>", spawn "mpc prev")
           , ("<XF86AudioNext>", spawn "mpc next")
           , ("<XF86AudioStop>", spawn "mpc stop")
           , ("M-<Home>"       , spawn "mpc volume -1")
           , ("M-<End>"        , spawn "mpc volume +1")
           , ("M1-*"           , spawn "~/bin/addfavorite")
           , ("M1-#"           , spawn "~/bin/showcurrentsong")
             -- other hotkeys
           , ("<Print>"        , spawn "scrot -e 'mv $f ~/images/screenshots/'")
           , ("<XF86TouchpadToggle>", spawn "~/bin/toggleTouchpad")
           , ("C-M1-<Pause>"   , spawn "~/bin/toggleLayout")
           , ("C-S-<Pause>"    , spawn "~/bin/toggleLayout")
           , ("C-M1-<Return>"  , spawnOn "misc" "urxvtc -e ~/bin/recordnecrodancer")
           ] ++
           [(m ++ k, windows $ f w)
           | (w, k) <- zip (workspaces c) workspaceKeys
           , (m, f) <- [("M1-", W.greedyView), ("M-", W.shift)]] ++
           [(m ++ k, screenWorkspace s >>= flip whenJust (windows . f))
           | (s, k) <- zip [0..] ["v", "m"]
           , (m, f) <- [("M1-", W.view), ("M-", W.shift)]]
  where workspaceKeys = map (\x -> "<F" ++ show x ++ ">") ([1..12] :: [Int])


fullscreenFix :: XConfig a -> XConfig a
fullscreenFix c = c {
  startupHook = startupHook c <+> setSupportedWithFullscreen
  }
                  
setSupportedWithFullscreen :: X ()
setSupportedWithFullscreen = withDisplay $ \dpy -> do
  r <- asks theRoot
  a <- getAtom "_NET_SUPPORTED"
  c <- getAtom "ATOM"
  supp <- mapM getAtom ["_NET_WM_STATE_HIDDEN"
                       ,"_NET_WM_STATE_FULLSCREEN"
                       ,"_NET_NUMBER_OF_DESKTOPS"
                       ,"_NET_CLIENT_LIST"
                       ,"_NET_CLIENT_LIST_STACKING"
                       ,"_NET_CURRENT_DESKTOP"
                       ,"_NET_DESKTOP_NAMES"
                       ,"_NET_ACTIVE_WINDOW"
                       ,"_NET_WM_DESKTOP"
                       ,"_NET_WM_STRUT"
                       ]
  io $ changeProperty32 dpy r a c propModeReplace (fmap fromIntegral supp)
  setWMName "xmonad"



data FuzzySpawn = FuzzySpawn deriving (Read, Show)
instance XPrompt FuzzySpawn where
  showXPrompt _ = "Find window: "


winAction a m = flip whenJust (windows . a) . flip M.lookup m
gotoAction = winAction W.focusWindow
fuzzySpawn = do
  wm <- windowMap
  a <- fmap gotoAction windowMap
  mkXPrompt FuzzySpawn defaultXPConfig {position = Top, alwaysHighlight = True, promptKeymap = emacsLikeXPKeymap} (compList wm) a
  where
    weight s c = levenshteinDistance defaultEditCosts { deletionCosts = ConstantCost 1000,
                                                        substitutionCosts = ConstantCost 1000 } s c
    regex s = foldr (\a b -> a:'.':'*':b) [] s
    compList m s = return . map snd . sort . map (\c -> (weight s c, c))
                   . filter (\a -> a =~ regex s) . map fst . M.toList $ m

