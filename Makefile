all: build
build : cythonize Makefile setup.py
	python setup.py build_ext 

cythonize : _pysndfile.cpp

_pysndfile.cpp: _pysndfile.pyx pysndfile.hh
	cython --cplus $<

install:
	pip install .

install-user:
	pip install . --user

clean:
	python setup.py clean -a

sdist:
	python setup.py sdist
        @echo twine upload -r test dist/pysndfile-1.3.0.tar.gz 
        @echo twine upload -r pypi dist/pysndfile-1.3.0.tar.gz 