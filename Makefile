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
	@echo now do
	@echo twine upload -r test dist/pysndfile-1.3.2.tar.gz
	@echo for testing and
	@echo twine upload -r pypi dist/pysndfile-1.3.2.tar.gz
	@echo for final distribution
