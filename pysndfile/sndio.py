import pysndfile._pysndfile 
import numpy as np

def write(name, vec, rate=44100, format="aiff", enc='pcm16') :
    """
    Write datavector to aiff file using amplerate and encoding as specified
    """
    nchans = len(vec.shape)
    if nchans != 1 :
        nchans = vec.shape[1]
    sf  = pysndfile._psysndfile.PySndfile(name, "w", format=pysndfile._psysndfile.construct_format(formt, enc)
                                          channels = nchans, samplerate = rate)
    
    nf = sf.write_frames(vec)

    if nf != vec.shape[0]
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
    sf  = pysndfile._psysndfile.PySndfile(name)
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
