PYTHON=python
python_version_full := $(wordlist 2,4,$(subst ., ,$(shell ${PYTHON} --version 2>&1)))
python_version_major := $(word 1,${python_version_full})
CYTHON=cython
PIP=pip 

all: build
build : cythonize Makefile setup.py
	$(PYTHON) setup.py build_ext 

cythonize : _pysndfile.cpp

_pysndfile.cpp: _pysndfile.pyx pysndfile.hh
	$(CYTHON) -${python_version_major} --cplus $<

install:
	$(PIP) install .

install-user:
	$(PIP) install . --user

clean:
	$(PYTHON) setup.py clean -a

sdist:
	$(PYTHON) setup.py sdist
	@echo now do
	@echo twine upload -r test dist/pysndfile-1.3.2.tar.gz
	@echo for testing and
	@echo twine upload -r pypi dist/pysndfile-1.3.2.tar.gz
	@echo for final distribution
