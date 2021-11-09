{- |
Copyright   : (c) Takayuki Muranushi, 2016
License     : BSD3
Maintainer  : whosekiteneverfly@gmail.com
Stability   : experimental


Provides a interactive printer for printing Unicode characters in ghci REPL. Our design goal is that 'uprint' produces String representations that are valid Haskell 'String' literals and uses as many Unicode printable characters as possible. Hence

@
read . ushow == id
@

see the tests of this package for detailed specifications.

__Example__

With 'print' :

@
$ __ghci__
...
> __["哈斯克尔7.6.1"]__
["\\21704\\26031\\20811\\23572\\&7.6.1"]
>
@

With 'uprint' :

@
$ __ghci -interactive-print=Text.Show.Unicode.uprint Text.Show.Unicode__
...
Ok, modules loaded: Text.Show.Unicode.
> __("Хорошо!",["哈斯克尔7.6.1的力量","感じる"])__
("Хорошо!",["哈斯克尔7.6.1的力量","感じる"])
> "改\\n行"
"改\\n行"
@

You can make 'uprint' the default interactive printer in several ways. One is to
@cabal install unicode-show@, and add the following lines to your @~/.ghci@ config file.

@
import qualified Text.Show.Unicode
:set -interactive-print=Text.Show.Unicode.uprint
@

-}

module Text.Show.Unicode (ushow, uprint, ushowWith, uprintWith) where

import           Control.Applicative          ((<|>))
import           Data.Char                    (isAscii, isPrint)
import           Text.ParserCombinators.ReadP
import           Text.Read.Lex                (lexChar)

-- Represents a replaced character using its literal form and its escaped form.
type Replacement = (String, String)

-- | Parse one Haskell character literal expression from a 'String' produced by 'show', and
--
--  * If the found char satisfies the predicate, replace the literal string with the character itself.
--  * Otherwise, leave the string as it was.
--  * Note that special delimiter sequence "\&" may appear in a string. c.f.  <https://www.haskell.org/onlinereport/haskell2010/haskellch2.html#x7-200002.6 Section 2.6 of the Haskell 2010 specification>.
recoverChar :: (Char -> Bool) -> ReadP Replacement
recoverChar p = represent <$> gather lexChar
  where
    represent :: (String, Char) -> Replacement
    represent (o,lc)
      | p lc      = (o, [lc])
      | otherwise = (o, o)

-- | Show the input, and then replace Haskell character literals
-- with the character it represents, for any Unicode printable characters except backslash, single and double quotation marks.
-- If something fails, fallback to standard 'show'.
ushow :: Show a => a -> String
ushow = ushowWith (\c -> isPrint c && not (isAscii c))

-- | A version of 'print' that uses 'ushow'.
uprint :: Show a => a -> IO ()
uprint = putStrLn . ushow

-- | Show the input, and then replace character literals
-- with the character itself, for characters that satisfy the given predicate.
ushowWith :: Show a => (Char -> Bool) -> a -> String
ushowWith p x = go ("", "") $ readP_to_S (many $ recoverChar p) (show x)
  where
    go :: Replacement -> [([Replacement], String)] -> String
    go _  []            = ""
    go _  (([],""):_)   = ""
    go _  ((rs,""):_)   = snd $ last rs
    go _  [(_,o)]       = o
    go pr (([],_):rest) = go pr rest
    go _  ((rs,_):rest) = let r = last rs in snd r ++ go r rest

-- | A version of 'print' that uses 'ushowWith'.
uprintWith :: Show a => (Char -> Bool) -> a -> IO ()
uprintWith p = putStrLn . ushowWith p
