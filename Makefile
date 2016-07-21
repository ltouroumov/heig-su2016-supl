CC=g++
CFLAGS=-g -O0 -std=c++11

SRCS=src/main.cpp src/utils.cpp src/supllib.cpp src/suvm.cpp

all: suplc suvm

obj:
	mkdir obj

src/parser.cpp src/parser.hpp: src/parser.y
	bison --report=all --defines=src/parser.hpp --output=src/parser.cpp $<

src/lexer.cpp src/lexer.hpp: src/lexer.l src/parser.cpp src/parser.hpp
	flex --outfile=src/lexer.cpp --header-file=src/lexer.hpp $<

obj/%.o: src/%.cpp | obj
	$(CC) $(CFLAGS) -c -o $@ $^

suplc: obj/lexer.o obj/parser.o obj/main.o obj/utils.o obj/supllib.o
	$(CC) $(CFLAGS) -o $@ $^ -lfl

suvm: obj/suvm.o obj/supllib.o
	$(CC) $(CFLAGS) -o $@ $^ -lm

clean:
	rm src/parser.cpp src/parser.hpp
	rm src/lexer.cpp src/lexer.hpp
	rm -r obj
	rm suplc suvm
