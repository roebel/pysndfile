#
# Copyright (C) 2014 IRCAM
#
# All rights reserved.
#
# This file is part of pysndfile.
#
# pysndfile is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# pysndfile is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with pysndfile.  If not, see <http://www.gnu.org/licenses/>.
#
import _pysndfile 
import numpy as np

def get_info(name) :
    """
    retrieve samplerate, encoding (str) and format informationfor sndfile name
    """
    sf  = _psysndfile.PySndfile(name)
    return sf.samplerate(), sf.encoding_str(), sf.major_format_str()

def write(name, vec, rate=44100, format="aiff", enc='pcm16') :
    """
    Write datavector to aiff file using amplerate and encoding as specified
    """
    nchans = len(vec.shape)
    if nchans != 1 :
        nchans = vec.shape[1]
    sf  = _psysndfile.PySndfile(name, "w", format=_psysndfile.construct_format(formt, enc),
                                          channels = nchans, samplerate = rate)
    
    nf = sf.write_frames(vec)

    if nf != vec.shape[0]:
        raise IOError("sndio.write::error::writing of samples failed")
    return nf

enc_norm_map = {
    "pcm8" : np.float64(2**7),
    "pcm16": np.float64(2**15),
    "pcm24": np.float64(2**23),
    "pcm32": np.float64(2**31),
    }
    
def read(name, last=None, start=0) :
    """read samples from arbitrary sound files.
    return data, samplerate and encoding string

    returns subset of samples as specified by start and end arguments (Def all samples)
    normalizes samples to [-1,1] is norm argument is true
    """
    sf  = _psysndfile.PySndfile(name)
    enc = sf.encoding_str()

    nf = sf.seek(start, 0)
    if not nf == start:
        raise IOError("sndio.read::error:: while seeking at starting position")
    
    if end == None:
        ff = sf.read_frames(dtype=np.float64)
    else:
        ff = sf.read_frames(end-start, dtype=np.float64)
        
    if norm and (enc not in ["float32" , "float64"]) :
        if enc in enc_norm_map :
            ff = ff / enc_norm_map[sf.encoding_str()]
        else :
            raise IOError("sndio.read::error::normalization of compressed pcm data is not supported")

    return ff, sf.samplerate(), enc
