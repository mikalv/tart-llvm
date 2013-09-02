#
# Makefile for tart-llvm
#

LLC=   	llc-3.4

PROGS=	actor

all: $(PROGS)

test: all
	./actor

actor: actor.s
	gcc actor.s -o actor

actor.s:
	$(LLC) actor.ll

clean:
	rm -f actor actor.s