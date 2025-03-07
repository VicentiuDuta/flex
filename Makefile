# Duta_Vicentiu-Alecsandru_331CC

CXX = g++
LEX = flex

CXXFLAGS = -Wall -g

PROGRAM = main

LEX_SOURCE = main.l

LEX_CPP = lex.yy.cpp

all: $(PROGRAM)

$(PROGRAM): $(LEX_CPP)
	$(CXX) $(CXXFLAGS) -o $(PROGRAM) $(LEX_CPP)

$(LEX_CPP): $(LEX_SOURCE)
	$(LEX) -o $(LEX_CPP) $(LEX_SOURCE)

clean:
	rm -f $(PROGRAM) $(LEX_CPP)

.PHONY: all clean
