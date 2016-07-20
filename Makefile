CC=g++
CFLAGS=-g -O0 -std=c++11

SRCS=src/main.cpp src/supllib.cpp src/suvm.cpp

all: suplc suvm

depend: .depend

.depend: $(SRCS)
	rm -f ./.depend
	$(CC) $(CFLAGS) -MM $^ -MF  ./.depend;

include .depend

src/parser.cpp src/parser.hpp: src/parser.y
	bison --defines=src/parser.hpp --output=src/parser.cpp $<

src/lexer.cpp src/lexer.hpp: src/lexer.l src/parser.cpp src/parser.hpp
	flex --outfile=src/lexer.cpp --header-file=src/lexer.hpp $<

obj/%.o: src/%.cpp
	$(CC) $(CFLAGS) -c -o $@ $^

suplc: obj/lexer.o obj/parser.o obj/main.o obj/supllib.o
	$(CC) $(CFLAGS) -o $@ $^ -lfl

suvm: obj/suvm.o obj/supllib.o
	$(CC) $(CFLAGS) -o $@ $^ -lm

clean:
	rm src/parser.cpp src/parser.hpp
	rm src/lexer.cpp src/lexer.hpp
	rm obj/*.o
	rm suplc suvm
