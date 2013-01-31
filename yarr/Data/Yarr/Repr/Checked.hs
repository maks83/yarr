
module Data.Yarr.Repr.Checked where

import Prelude as P
import Text.Printf

import Data.Yarr.Base
import Data.Yarr.Shape
import Data.Yarr.Utils.FixedVector as V


data CHK r

instance URegular r sh a => URegular (CHK r) sh a where
    newtype UArray (CHK r) sh a = Checked { unchecked :: UArray r sh a }

    extent = extent . unchecked
    isReshaped = isReshaped . unchecked
    touch = touch . unchecked

    {-# INLINE extent #-}
    {-# INLINE isReshaped #-}
    {-# INLINE touch #-}

instance NFData (UArray r sh a) => NFData (UArray (CHK r) sh a) where
    rnf = rnf . unchecked
    {-# INLINE rnf #-}

instance UVecRegular r sh slr v e => UVecRegular (CHK r) sh (CHK slr) v e where
    elems = V.map Checked . elems . unchecked
    {-# INLINE elems #-}

instance USource r sh a => USource (CHK r) sh a where
    index (Checked arr) sh =
        let ext = extent arr
        in if not (insideBlock (zero, ext) sh)
            then error $ printf
                            "index %s is out of extent - %s"
                            (show sh) (show ext)
            else index arr sh

    linearIndex (Checked arr) i =
        let sz = size (extent arr)
        in if not (insideBlock (0, sz) i)
            then error $ printf "linear index %d is out of size - %d" i sz
            else linearIndex arr i


    rangeLoadP threads (Checked arr) = rangeLoadP threads arr
    linearLoadP threads (Checked arr) = linearLoadP threads arr
    rangeLoadS (Checked arr) = rangeLoadS arr
    linearLoadS (Checked arr) = linearLoadS arr

    {-# INLINE index #-}
    {-# INLINE linearIndex #-}
    {-# INLINE rangeLoadP #-}
    {-# INLINE linearLoadP #-}
    {-# INLINE rangeLoadS #-}
    {-# INLINE linearLoadS #-}

instance UVecSource r sh slr v e => UVecSource (CHK r) sh (CHK slr) v e where
    rangeLoadElemsP threads (Checked arr) = rangeLoadElemsP threads arr
    linearLoadElemsP threads (Checked arr) = linearLoadElemsP threads arr
    rangeLoadElemsS (Checked arr) = rangeLoadElemsS arr
    linearLoadElemsS (Checked arr) = linearLoadElemsS arr
    {-# INLINE rangeLoadElemsP #-}
    {-# INLINE linearLoadElemsP #-}
    {-# INLINE rangeLoadElemsS #-}
    {-# INLINE linearLoadElemsS #-}


instance Fusion r fr sh a b => Fusion (CHK r) (CHK fr) sh a b where
    fmapM f = Checked . fmapM f . unchecked
    fzipM fun arrs =
        let uncheckedArrs = V.map unchecked arrs
        in Checked (fzipM fun uncheckedArrs)
    {-# INLINE fmapM #-}
    {-# INLINE fzipM #-}

instance DefaultFusion r fr sh a b => DefaultFusion (CHK r) (CHK fr) sh a b


instance UTarget tr sh a => UTarget (CHK tr) sh a where
    write (Checked arr) sh =
        let ext = extent arr
        in if not (insideBlock (zero, ext) sh)
            then error $ printf
                            "Writing: index %s is out of extent - %s"
                            (show sh) (show ext)
            else write arr sh

    linearWrite (Checked arr) i =
        let sz = size (extent arr)
        in if not (insideBlock (0, sz) i)
            then error $ printf
                            "Writing: linear index %d is out of size - %d"
                            i sz
            else linearWrite arr i
    {-# INLINE write #-}
    {-# INLINE linearWrite #-}

instance Manifest mr sh a => Manifest (CHK mr) sh a where
    new sh = P.fmap Checked (new sh)
    {-# INLINE new #-}

instance UVecTarget tr sh tslr v e => UVecTarget (CHK tr) sh (CHK tslr) v e