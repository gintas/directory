% ----------------------------------------------------------------
% $Id: ReadPrec.lhs
%
% (c) The University of Glasgow, 1994-2000
%

\begin{code}
{-# OPTIONS -fno-implicit-prelude #-}

module Text.ParserCombinators.ReadPrec
  ( ReadPrec      -- :: * -> *; instance Functor, Monad, MonadPlus
  
  -- precedences
  , Prec          -- :: *; = Int
  , minPrec       -- :: Prec; = 0

  -- primitive operations
  , lift          -- :: ReadP a -> ReadPrec a
  , prec          -- :: Prec -> ReadPrec a -> ReadPrec a
  , step          -- :: ReadPrec a -> ReadPrec a
  , reset         -- :: ReadPrec a -> ReadPrec a

  -- other operations
  , get           -- :: ReadPrec Char
  , look          -- :: ReadPrec String
  , (+++)         -- :: ReadPrec a -> ReadPrec a -> ReadPrec a
  , pfail         -- :: ReadPrec a
  , choice        -- :: [ReadPrec a] -> ReadPrec a

  -- converters
  , readPrec_to_P -- :: ReadPrec a       -> (Int -> ReadP a)
  , readP_to_Prec -- :: (Int -> ReadP a) -> ReadPrec a
  , readPrec_to_S -- :: ReadPrec a       -> (Int -> ReadS a)
  , readS_to_Prec -- :: (Int -> ReadS a) -> ReadPrec a
  )
 where


import Text.ParserCombinators.ReadP
  ( ReadP
  , readP_to_S
  , readS_to_P
  )

import qualified Text.ParserCombinators.ReadP as ReadP
  ( get
  , look
  , (+++)
  , pfail
  , choice
  )

import Control.Monad( MonadPlus(..) )
import GHC.Num( Num(..) )
import GHC.Base
\end{code}


%*********************************************************
%*							*
\subsection{The readPrec type}
%*							*
%*********************************************************

\begin{code}
newtype ReadPrec a = P { unP :: Prec -> ReadP a }

-- Functor, Monad, MonadPlus

instance Functor ReadPrec where
  fmap h (P f) = P (\n -> fmap h (f n))

instance Monad ReadPrec where
  return x  = P (\_ -> return x)
  fail s    = P (\_ -> fail s)
  P f >>= k = P (\n -> do a <- f n; let P f' = k a in f' n)
  
instance MonadPlus ReadPrec where
  mzero = pfail
  mplus = (+++)

-- precedences
  
type Prec = Int

minPrec :: Prec
minPrec = 0
\end{code}


%*********************************************************
%*							*
\subsection{Operations over ReadPrec
%*							*
%*********************************************************

\begin{code}
lift :: ReadP a -> ReadPrec a
lift m = P (\_ -> m)

step :: ReadPrec a -> ReadPrec a
-- Increases the precedence context by one
step (P f) = P (\n -> f (n+1))

reset :: ReadPrec a -> ReadPrec a
-- Resets the precedence context to zero
reset (P f) = P (\n -> f minPrec)

prec :: Prec -> ReadPrec a -> ReadPrec a
-- (prec n p) checks that the precedence context is 
--			  less than or equal to n,
-- 	if not, fails
--	if so, parses p in context n
prec n (P f) = P (\c -> if c <= n then f n else ReadP.pfail)
\end{code}

%*********************************************************
%*							*
\subsection{Derived operations}
%*							*
%*********************************************************

\begin{code}
get :: ReadPrec Char
get = lift ReadP.get

look :: ReadPrec String
look = lift ReadP.look

(+++) :: ReadPrec a -> ReadPrec a -> ReadPrec a
P f1 +++ P f2 = P (\n -> f1 n ReadP.+++ f2 n)

pfail :: ReadPrec a
pfail = lift ReadP.pfail

choice :: [ReadPrec a] -> ReadPrec a
choice ps = foldr (+++) pfail ps
\end{code}


%*********************************************************
%*							*
\subsection{Converting between ReadPrec and ReadS
%*							*
%*********************************************************

\begin{code}
-- We define a local version of ReadS here,
-- because its "real" definition site is in GHC.Read
type ReadS a = String -> [(a,String)]

readPrec_to_P :: ReadPrec a -> (Int -> ReadP a)
readPrec_to_P (P f) = f

readP_to_Prec :: (Int -> ReadP a) -> ReadPrec a
readP_to_Prec f = P f

readPrec_to_S :: ReadPrec a -> (Int -> ReadS a)
readPrec_to_S (P f) n = readP_to_S (f n)

readS_to_Prec :: (Int -> ReadS a) -> ReadPrec a
readS_to_Prec f = P (\n -> readS_to_P (f n))
\end{code}