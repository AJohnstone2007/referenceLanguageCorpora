@echo off
rem *******************************************************************************
rem *
rem * runGTB.bat - July 2024
rem *
rem * Iterate over:
rem *   languages, corpora, GTB executables, GTB script stubs and grammar variants
rem *   run on each string and tok file COUNT times
rem *
rem *******************************************************************************

rem set GTB to the location of your GTB binaries
set GTB=\csle\dev\art\old\gtb\bin

rem set COUNT to the number of iterations of each experiment
set COUNT=1

set TRY=try
set LNG=..\languages
set LOG=log.csv

rem allow the !time! and !date! variable expansions so that we get current date and time, not the start time of this script
SetLocal EnableDelayedExpansion

rem write header line to log
echo time stamp,tool,script,#,language,grammar,string,length,algorithm,result,TLex,TLChoose,TParse,TPChoose,TSelect,TTerm,tweN,tweE,lexes,GSS SN,GSS EN,GGS E,SPPF Eps,SPPF T,SPPF NT,SPPF Inter,SPPF PN,SPPF Edge,Pool,H0,H1,H2,H3,H4,H5,H6+ > %log%

rem iterate over langage directories
FOR /D %%L IN (%LNG%\*) DO (
rem      echo *1 %%~nL%

rem iterate over corpora directories
  FOR /D %%C IN (%%L%\corpus\*) DO (
rem   echo *2 %%~nC%

rem iterate over GTB executables
    FOR %%B IN (%GTB%\*.exe) DO (
rem    echo *3 %%~nB%

rem iterate over GTB script stubs
      FOR %%T IN (%TRY%\*.gtb) DO (
rem      echo *4 %%~nT%


rem iterate over grammar variant directories
        FOR /D %%G IN (%%L%\grammar\*) DO (
rem         echo *5 %%~nG%

rem iterate over token grammar variant versions
          FOR %%V IN (%%G%\tok\*.gtb) DO (
rem            echo *6 %%~nV%


rem iterate over token strings 
            FOR %%S IN (%%C%\tok\*.*) DO (
rem              echo *7 %%~nS%
	      
rem iterate COUNT times
              FOR /L %%N IN (1,1,%COUNT%) DO (
rem                echo *8 %%~nN%

                copy %%V+%%T test.gtb > nul
                copy %%S test.str > nul
                echo !date!-!time!,%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/%%~nV,%%~nC/%%~nS%%~xS

rem Comment out the line below if you just want to see which files will be processed without actually running GTB
                %%B -C!date!-!time!,%%~nB,%%~nT%%~xT,%%N,%%~nL,%%~nG/%%~nV,%%~nC/%%~nS%%~xS test.gtb >> %LOG%
              )
            )
          )
	)
      )
    )
  )
)

EXIT/B

:RUN

GOTO :EOF
