from __future__ import print_function
import os
import sys
import numpy as np

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
    b.close()
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
with PySndfile(os.path.join(mydir,'test_2cC.wav')) as b:
    bfc=b.read_frames()

read_error= False
write_error =False
if np.any (ff2 != bff):
    print('error in test_2cF.wav')
    print("ff2", ff2)
    print("bff", bff)
    write_error = True
elif np.any (ff2 != bfc):
    print('error in test_2cC.wav')
    print("ff2", ff2)
    print("bfc", bfc)
    write_error = True
else:
    print("no erors detected for io with difernt sample encodings")

# check reading part of file
ss,_,_ =  pysndfile.sndio.read(os.path.join(mydir,'test.wav'), force_2d=True)
ssstart,_,_ =  pysndfile.sndio.read(os.path.join(mydir,'test.wav'), end=100, force_2d=True)
ssend,_,_ =  pysndfile.sndio.read(os.path.join(mydir,'test.wav'), start=100, force_2d=True)

if np.any(ss != np.concatenate((ssstart, ssend), axis=0)):
    read_error = True
    print("error reading file segments")

# check writing flac
if "flac" in majors:
    print('test writing flac')
    ss, sr, enc = pysndfile.sndio.read(os.path.join(mydir,'test.wav'), force_2d=True)
    flac_file = PySndfile(os.path.join(mydir,'test.flac'), "w", construct_format("flac", "pcm16"), ss.shape[1], sr)
    flac_file.command("SFC_SET_COMPRESSION_LEVEL", 1.)
    flac_file.write_frames(ss)
    flac_file.close()

    ss_flac, sr_flac, enc_flac = pysndfile.sndio.read(os.path.join(mydir,'test.flac'), force_2d=True)
    if sr != sr_flac:
        print('error::flac writing sample rate')
        write_error = True
    if enc != enc_flac:
        print('error::flac writing enc')
        write_error = True
    if np.any (ss != ss_flac):
        print('error in test_2cF.wav')
        write_error = True
else:
    print('your libsndfile version does not support flac format, skip flac writing test')

if write_error or read_error:
    if write_error:
        print("write errors encountered")
    if read_error:
        print("read errors encountered")
    sys.exit(1)
else:
    print("all seems ok")
    sys.exit(0)
