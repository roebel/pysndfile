import sndio 
import numpy as np

def write(name, vec, rate=44100, enc='pcm16') :
    """
    Write datavector to aiff file using amplerate and encoding as specified
    """
    return sndio.write(name, vec, rate=44100, enc='pcm16', format="aiff")

def read(name, start=0, end=None, norm=False) :
    """
    Read samples from aiff file 
    return data, samplerate and encoding string

    returns subset of samples as specified by start and end arguments (Def all samples)
    normalizes samples to [-1,1] is norm argument is true
    """
    return sndio.read(name, start, end, norm)
