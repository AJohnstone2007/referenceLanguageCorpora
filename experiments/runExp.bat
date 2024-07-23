@echo off
rem *******************************************************************************
rem *
rem * runExp.bat - July 2024
rem *
rem * Usage: runExp <tool> where <tool> is either gtb or art 
rem *
rem * Iterate over:
rem *   languages, corpora, tool versions, script stubs and grammar variants
rem *   run on each string and tok file COUNT times
rem *
rem *******************************************************************************

rem set COUNT to the number of iterations of each experiment
set COUNT=1
set TOOL=%1

set BIN=bin
set TRY=try
set LNG=..\languages
set LOG=log.csv

rem allow the !time! and !date! variable expansions so that we get current date and time, not the start time of this script
SetLocal EnableDelayedExpansion

if "%TOOL%" == "gtb" (
  echo "!!!"
) else (
  if "%TOOL%" == "art" (
    echo "%%%"
  ) else (
    echo Usage: runEXP <tool> where <tool> must be art or gtb (in lower case)
)
)

rem write header lines to log
echo %date%-%time%,script,#,language,grammar,string,length,algorithm,result,TLex,TLChoose,TParse,TPChoose,TSelect,TTerm,tweN,tweE,lexes,GSS SN,GSS EN,GGS E,SPPF Eps,SPPF T,SPPF NT,SPPF Inter,SPPF PN,SPPF Edge,Pool,H0,H1,H2,H3,H4,H5,H6+ > %log%

rem iterate over langage directories
FOR /D %%L IN (%LNG%\*) DO (
rem echo *1 %%L%

rem iterate over corpora directories
  FOR /D %%C IN (%%L%\corpus\*) DO (
rem echo *2 %%C%

rem iterate over tools
    FOR %%B IN (%BIN%\%TOOL%*) DO (
rem echo *3 %%B%

rem iterate over script stubs
      FOR %%T IN (%TRY%\*.%TOOL%) DO (
rem echo *4 %%T%

rem iterate over grammar variant directories
        FOR /D %%G IN (%%L%\grammar\*) DO (
rem echo *5 %%G%


rem Part A - iterate over TOKEN grammar variant versions
          FOR %%V IN (%%G%\tok\*.%TOOL%) DO (
 echo *6A %%V%


rem iterate over token strings 
            FOR %%S IN (%%C%\tok\*.*) DO (
 echo *7A %%S%
	      
rem construct script and test target 
              copy %%V+%%T test.%TOOL% > nul
              copy %%S test.str > nul

rem iterate COUNT times
              FOR /L %%N IN (1,1,%COUNT%) DO (
 echo *8A %%N%

                echo !date!-!time!,TOKEN,%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/tok/%%~nV,%%~nC/tok/%%~nS%%~xS
rem Comment out the line below if you just want to see which files will be processed without actually running the tool
                %%B -C%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/tok/%%~nV,%%~nC/tok/%%~nS%%~xS test.%TOOL% >> %LOG%
              )
            )
          )

rem Part B - iterate over STRING grammar variant versions
          FOR %%V IN (%%G%\str\*.%TOOL%) DO (
echo *6B %%V%


rem iterate over strings 
            FOR %%S IN (%%C%\str\*.*) DO (
echo *7B %%S%
	      
rem construct script and test target 
              copy %%V+%%T test.%TOOL% > nul
              copy %%S test.str > nul

rem iterate COUNT times
              FOR /L %%N IN (1,1,%COUNT%) DO (
echo *8B %%~nN%

                echo !date!-!time!,STRING,%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/str/%%~nV,%%~nC/str/%%~nS%%~xS
rem Comment out the line below if you just want to see which files will be processed without actually running GTB
	        %%B -C%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/str/%%~nV,%%~nC/str/%%~nS%%~xS test.%TOOL% >> %LOG%
              )
            )
          )
	)
      )
    )
  )
)

del/q test.*
