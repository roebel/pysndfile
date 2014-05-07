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
