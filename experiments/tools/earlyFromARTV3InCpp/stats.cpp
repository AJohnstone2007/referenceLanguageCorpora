/********************************************************************************
 *
 * stats.cpp - timing and statistics gathering support
 *
 *******************************************************************************/
#include <chrono>
#include <cstddef>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <vector>
 
using namespace std;
using namespace chrono;


bool artInadmissable; // set when, say, a BNF parser is called with an EBNF grammar
bool artIsInLanguage;

time_point<steady_clock> startTime;
time_point<steady_clock> setupTime;
time_point<steady_clock> lexTime;
time_point<steady_clock> lexChooseTime;
time_point<steady_clock> parseTime;
time_point<steady_clock> parseChooseTime;
time_point<steady_clock> derivationSelectTime;
time_point<steady_clock> termGenerateTime;
time_point<steady_clock> semanticsTime;

long artParseStartMemory;
long artParseEndMemory;
long artParseStartPool;
long artParseEndPool;
int inputStringLength;
int inputTokenLength;

void loadSetupTime() { setupTime = steady_clock::now(); }
void loadLexTime() { lexTime = steady_clock::now(); }
void loadLexChooseTime() { lexChooseTime = steady_clock::now(); }
void loadParseTime() { parseTime = steady_clock::now(); }
void loadParseChooseTime() { parseChooseTime = steady_clock::now(); }
void loadDerivationSelectTime() { derivationSelectTime = steady_clock::now(); }
void loadTermGenerateTime() { termGenerateTime = steady_clock::now(); }
void loadSemanticsTime() { semanticsTime = steady_clock::now(); }

void normaliseStats() {
  if (setupTime < startTime) setupTime = startTime;
  if (lexTime == startTime) lexTime = setupTime;
  if (lexChooseTime == startTime) lexChooseTime = lexTime;
  if (parseTime == startTime) parseTime = lexChooseTime;
  if (parseChooseTime == startTime) parseChooseTime = parseTime;
  if (derivationSelectTime == startTime) derivationSelectTime = parseChooseTime;
  if (termGenerateTime == startTime) termGenerateTime = derivationSelectTime;
  if (semanticsTime == startTime) semanticsTime = termGenerateTime;
}

long artMemoryUsed() { return 0;} 

void loadStartMemory() { artParseStartMemory = artMemoryUsed(); }
void loadEndMemory() { artParseEndMemory = artMemoryUsed(); }

void resetStats() {
  startTime = steady_clock::now();
  setupTime = lexTime = lexChooseTime = parseTime = parseChooseTime = derivationSelectTime = termGenerateTime = semanticsTime = startTime;
  artParseStartMemory = artParseEndMemory = artParseStartPool = artParseEndPool = 0;
}

double interval(time_point<steady_clock> start, time_point<steady_clock> end){
  return duration<double, milli> {end - start}.count();
}

void artLog() {
  normaliseStats();

    printf("%i,---,%s,OK,%7.3f,%7.3f,%7.3f,%7.3f,%7.3f,%7.3f,%7.3f,%7.3f,%i,%i,1\n",
            inputStringLength,
            (artIsInLanguage ? "accept" : "reject"),
            interval(startTime, setupTime),
            interval(setupTime, lexTime),
            interval(lexTime, lexChooseTime), 
            interval(lexChooseTime, parseTime),
            interval(parseTime, parseChooseTime),
            interval(parseChooseTime, derivationSelectTime),
            interval(derivationSelectTime, termGenerateTime),
            interval(termGenerateTime, semanticsTime),
            inputTokenLength,
            (inputTokenLength - 1));
  }