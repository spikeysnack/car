#!/usr/bin/env make

# Makefile


#CC=gcc
CC=clang

CFLAGS= -fPIC -O2 
CFLAGS_DEBUG=-ggdb3 -O0 -fPIC 

all:	chunker

debug:	chunker.c
	$(CC) $(CFLAGS_DEBUG) -D DEBUG -o chunker chunker.c

chunker:	chunker.c
	$(CC) $(CFLAGS) -o chunker chunker.c


TESTDIR=test
TESTFILES= test1.txt test2.txt test3.txt test4.txt

mkcar:	mkcar.sh 
	cd $(TESTDIR); bash ../mkcar.sh test.car $(TESTFILES); mv test.car ..

readcar: readcar.pl
	perl readcar.pl test.car

uncar:	uncar.sh
	bash uncar.sh test.car out

view:	
	cd out; more $(TESTFILES);

test:	chunker mkcar readcar uncar view



clean:
	rm -f *~ *.o *.old core chunker *.car 
	rm -rf out

dist:	clean
	rm *.tgz *.car
	rm -rf out
	tar czvf car.tgz *

.PHONY:	clean mkcar readcar uncar test
