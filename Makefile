PYTHON=python
python_version_full := $(wordlist 2,4,$(subst ., ,$(shell ${PYTHON} --version 2>&1)))
python_version_major := $(word 1,${python_version_full})
CYTHON=cython
PIP=pip 
vv=$(shell $(PYTHON) setup.py get_version )
all: build
build : cythonize Makefile setup.py
	$(PYTHON) setup.py build_ext 

cythonize : _pysndfile.cpp

# dont adapt language_level for the moment, it does not seem to make any difference anyway
# language_level is now hard-coded in the source
# $(CYTHON) -${python_version_major} --cplus $<
_pysndfile.cpp: _pysndfile.pyx pysndfile.hh sndfile_linux.pxi sndfile_win32.pxi
	$(CYTHON) --cplus $<

install:
	$(PIP) install .

install-user:
	$(PIP) install . --user

clean:
	$(PYTHON) setup.py clean -a
	rm -f _pysndfile.cpp
sdist:
	$(PYTHON) setup.py sdist
	@echo now do
	@echo twine upload -r test dist/pysndfile-${vv}.tar.gz
	@echo for testing and
	@echo twine upload -r pypi dist/pysndfile-${vv}.tar.gz
	@echo for final distribution
	@echo in case you want to try a clean install from test.pypi.org use
	@echo pip install --no-cache-dir --extra-index-url https://test.pypi.org/simple/  pysndfile==${vv} 

check: build
	pip install --no-build-isolation --no-deps --no-cache --upgrade --target tests/pysndfile_inst_dir .
	touch tests/pysndfile_inst_dir/__init__.py
	cd tests; $(PYTHON) pysndfile_test.py
