from _pysndfile import get_sndfile_version
from _pysndfile import *
import _pysndfile

print get_sndfile_version()


majors = get_sndfile_formats()
print "majors", majors
for mm in majors:
    if mm in fileformat_id_to_name:
        print "format {0:x}".format(mm), "->", fileformat_id_to_name[mm]
    else:
        print "format {0:x}".format(mm), "-> not supported by pysndfile"
        
print get_sndfile_encodings('wav')

try:
    a = PySndfile('test1.wav')
except IOError, e:
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    print e
    print "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

a = PySndfile('test.wav')
for d in [np.float64, np.float32, np.int32, np.short]:
    print "d:",d
    ff=a.read_frames(dtype=d)
    a.rewind()
    b = PySndfile('test{0}.wav'.format(str(d).split("'")[1]), "w", a.format(), a.channels(), a.samplerate())
    print b
    b.write_frames(ff)
    del b

ff=a.read_frames(dtype=np.float64)
ff2 = np.concatenate(((ff,),(ff,))).T

print "ff2.shape    ",ff2.shape    
b = PySndfile('test_2cC.wav', "w", a.format(), 2, a.samplerate())
b.write_frames(np.require(ff2, requirements='C'))

b = PySndfile('test_2cF.wav', "w", a.format(), 2, a.samplerate())
b.write_frames(np.require(ff2, requirements='F')*2)
del b

b= PySndfile('test_2cF.wav')
bff=b.read_frames()
b= PySndfile('test_2cC.wav')
bfc=b.read_frames()

if np.any (ff2 != bff):
    print 'error in test_2cF.wav'
    print "ff2", ff2
    print "bff", bff
if np.any (ff2 != bfc):
    print 'error in test_2cC.wav'
    print "ff2", ff2
    print "bfc", bfc
