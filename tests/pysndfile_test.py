from __future__ import print_function
import numpy as np
import os

from pysndfile_inst_dir.pysndfile import get_sndfile_version
from pysndfile_inst_dir.pysndfile import *
import pysndfile_inst_dir.pysndfile as pysndfile

mydir = os.path.dirname(__file__)

print("pysndfile version:",get_pysndfile_version())
print("libsndfile version:",get_sndfile_version())

majors = get_sndfile_formats()
print( "majors", majors)
for mm in majors:
    if mm in fileformat_name_to_id:
        print("format {0:x}".format(fileformat_name_to_id[mm]), "->", mm)
    else:
        print("format {0}".format(mm), "-> not supported by pysndfile")
        
print( get_sndfile_encodings('wav'))

try:
    a = PySndfile(os.path.join(mydir,'test1.wav'))
except IOError as e:
    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")
    print(e)
    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++")

a = PySndfile(os.path.join(mydir,'test.wav'))
for d in [np.float64, np.float32, np.int32, np.short]:
    print("d:",d)
    ff=a.read_frames(dtype=d)
    a.rewind()
    b = PySndfile(os.path.join(mydir,'test{0}.wav'.format(str(d).split("'")[1])), "w", a.format(), a.channels(), a.samplerate())
    print(b)
    b.write_frames(ff)
    del b

ff=a.read_frames(dtype=np.float64)
ff2 = np.concatenate(((ff,),(ff,))).T

print("ff2.shape    ",ff2.shape)
b = PySndfile(os.path.join(mydir,'test_2cC.wav'), "w", a.format(), 2, a.samplerate())
b.write_frames(np.require(ff2, requirements='C'))

b = PySndfile(os.path.join(mydir,'test_2cF.wav'), "w", a.format(), 2, a.samplerate())
b.write_frames(np.require(ff2, requirements='F'))
del b

b= PySndfile(os.path.join(mydir,'test_2cF.wav'))
bff=b.read_frames()
b= PySndfile(os.path.join(mydir,'test_2cC.wav'))
bfc=b.read_frames()

if np.any (ff2 != bff):
    print('error in test_2cF.wav')
    print("ff2", ff2)
    print("bff", bff)
elif np.any (ff2 != bfc):
    print('error in test_2cC.wav')
    print("ff2", ff2)
    print("bfc", bfc)
else:
    print("all seems ok")
