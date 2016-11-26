#!/usr/bin/env make

# Makefile


#CC=gcc
CC=clang 

TEE=2>&1 | tee -a log

CFLAGS= -fPIC -O2 
CFLAGS_DEBUG=-ggdb3 -O0 -fPIC 

help:	
	@echo "to build:  make"
	@echo "to test:   make test"
	@echo "to debug:  make debug; make test"
	@echo 
	@echo "make options:   all help debug chunker"
	@echo "                mkcar readcar uncar"
	@echo "                view test clean dist"

all:	chunker mkcar readcar
	@touch log

debug:	chunker.c
	$(CC) $(CFLAGS_DEBUG) -D DEBUG -o chunker chunker.c $(TEE)

chunker:	chunker.c
	$(CC) $(CFLAGS) -o chunker chunker.c $(TEE)


TESTDIR= test
TESTFILES= test1.txt test2.txt test3.txt test4.txt

test.car:	mkcar


mkcar:	mkcar.sh chunker
	cd $(TESTDIR) ; bash ../mkcar.sh test.car $(TESTFILES) $(TEE); mv test.car ..
	cat $(TESTDIR)/log >> log ; rm $(TESTDIR)/log


readcar: readcar.pl mkcar
	perl readcar.pl test.car  $(TEE)

uncar:	chunker uncar.sh mkcar
	bash uncar.sh test.car out $(TEE)

view:	
	cd out; more $(TESTFILES); 
	more log;

test:	chunker mkcar readcar uncar view


clean:
	rm -f *~ *.o *.old core chunker *.car 
	rm -rf out

dist:	clean
	rm -f *.tgz *.car log
	rm -rf out
	cd .. ; tar czvf car.tgz chunk/ 
	cd .. ; mv car.tgz chunk/


.PHONY:	clean test dist view
