@echo off
REM
REM   	Script de génération de la DLL dll_core.dll et des programmee de test : "testdll_implicit.exe" (chargement implicite de la DLL),
REM 	"testdll_explicit.exe" (chargement explicite de la DLL), et enfin du script de test écrit en python.
REM		Ce fichier de commande est paramètrable avec deux paraamètres : 
REM			a) le premier paramètre permet de choisir la compilation et le linkage des programmes en une seule passe
REM 			soit la compilation et le linkage en deux passes successives : compilation séparée puis linkage,
REM 		b) le deuxième paramètre définit soit une compilation et un linkage en mode 32 bits, soit en mode 64 bits
REM 	 		pour les compilateurs qui le supportent.
REM     Le premier paramètre peut prendre les valeurs suivantes :
REM 		ONE ou TWO ou encore ALL (ou n'importe quelle valeur) pour les deux modes de générations
REM     Et le deuxième paramètre peut prendre les valeurs suivantes :
REM 		32, 64 ou  ALL si vous souhaitez lancer les deux générations, 32 bits et 64 bits.
REM 	Dans le cas du compilateur DMC, une seule génération possible : 32 bits, ce deuxième paramètre est donc ignoré.
REM
REM 	Author : 						Thierry DECHAIZE
REM		Date creation/modification : 	19/11/2023
REM 	Reason of modifications : 	n° 1 - Add new test of DLL with same call, but with load of DLL implicit (indirect call of DLL) 
REM 	 							n° 2 - After call in mode implicit of functions of DLL with préfix "_", add new definition file during genaration of DLL
REM 	 							n° 3 - Offer choice to generate DLL + test programs in one pass or two passes (compilation first, and then linkage after)
REM 								n° 4 - Change structure of multiple tests of first parameter to call internal functions in this script, and many others
REM 										change into source files (to align printf... for example) and into def file.  
REM 	Version number :				1.1.4            (version majeure . version mineure . patch level)

echo.  Lancement du batch de generation d'une DLL et deux tests de celle-ci avec Digital Mars Compiler C/C++ 32 bits version 8.57
REM     Affichage du nom du système d'exploitation Windows :              			Microsoft Windows 11 Famille (par exemple)
REM 	Affichage de la version du système Windows :              					10.0.22621 (par exemple)
REM 	Affichage de l'architecture du processeur supportant le système Windows :   64-bit (par exemple)    
echo.  *********  Quelques caracteristiques du systeme hebergeant l'environnement de developpement.   ***********
WMIC OS GET Name
WMIC OS GET Version
WMIC OS GET OSArchitecture

REM 	Save of initial PATH on PATHINIT variable
set PATHINIT=%PATH%
REM      Mandatory, add to PATH the binary directory of compiler Digital Mars (You can adapt this directory at your personal software environment)
set PATH=C:\dm\bin;%PATH%
REM set LIB=C:\dm\lib;".\"    Not used, because presence of library file on same directory than executable is suffisant for linker. 
REM 		Unless, use of option /SCANLIB set linker to search contents of environment variable LIB.
echo.  **********      Pour cette generation le premier parametre vaut "%1" et le deuxieme "%2"     *************

IF "%1" == "ONE" ( 
   call :complinkONE
) ELSE (
   IF "%1" == "TWO" (
      call :complinkTWO
   ) ELSE (
      call :complinkONE
	  call :complinkTWO
	)
)

goto FIN

:complinkONE
REM 	Format of command "dmc" (DMC is a one-step program to compile and link C++, C and ASM files)
REM 		DMC file... [flags...] [@respfile]  
REM 	Generation of the DLL in "one pass", with many options -Lxxxxxxxxx : xxxxxxxxx do complementaries instructions to linker
REM		-Ab 							-> enable bool			
REM 	-Bf								-> set message language French, option -Be to English
REM 	-mn 							-> set memory model to Windows 32s/95/98/NT/2000/ME/XP (mandatory)
REM 	-WD								-> set generation to Windows DLL (mandatory, in evidence !!!)   (-WA to generate GUI Windows Application)
REM 	-w-								-> set all warning of compiler
REM 	-ooutput_file					-> set name of output file
REM 	-L/IMPLIB:dll_core.lib 	 		-> advise linker to generate a library file, here dll_testing.lib
REM 	-L/IMPDEF:dll_core_2.def  		-> advise linker to generate a def file, here dll_testing_2.def
echo.  *********************************     Generation de la DLL en une passe       *******************************
dmc src\dll_core.c -Ab -Bf -mn -WD -w- -DBUILD_DLL -odll_core.dll -L/IMPDEF:dll_core_2.def /IMPLIB:dll_core.lib kernel32.lib user32.lib src\dll_core.def
REM 	WARNING BEHAVIOUR ERRATIC OF COMPILER DMC : If you place an definition file with the same name of source file (like dll_testing.def) 
REM 			on directory, dmc compiler read the information of this def file (implicit reading !!!) without warning or explicit advising !!!
REM 			An error is generated if src\dll_core.def is present ... and this content don't match the exported symbols.
REM 	See the result of generate def file by linker
type dll_core_2.def
REM     Use of "implib" utility" because bug with precedent command during linkage : library generate "dll_core.lib" seems in wrong format !!!
REM 	The message during next generation of main test program of DLL is : "dll_testing.lib : Error 30: Unexpected End of File"
implib /system dll_core.lib dll_core.dll
REM    Use of tool libunres to see publics names (here symbol of function exported by lib)
REM 		-p 				: option to see publics names
echo.  ***************** 	     Listage des symboles exportes de la librairie 32 bits			*****************
libunres -p dll_core.lib
REM 	Generation of the main test program of DLL in "one pass", with implicit load of DLL, no -W switch => Win32 console EXE application.
echo.  *************  Generation et lancement du premier programme de test de la DLL en mode implicite.   ************
dmc src\testdll_implicit.c -Ab -Bf -w- -otestdll_implicit.exe user32.lib kernel32.lib dll_core.lib
REM 	Run the main test program of DLL in "one pass", with implicit load of DLL :					All success.
testdll_implicit.exe
echo.  *************  Generation et lancement du deuxieme programme de test de la DLL en mode explicite.  *************
REM 	Generation of the main test program of DLL in "one pass", with explicit load of DLL, no -W switch => Win32 console EXE application.
dmc src\testdll_explicit.c -Ab -Bf -w- -otestdll_explicit.exe user32.lib kernel32.lib dll_core.lib
REM 	Run the main test program of DLL in "one pass", with explicit load of DLL:					All success.
testdll_explicit.exe
echo.  *************              Lancement du script python de test de la DLL                           *************
REM 	Run the script python to test DLL with arguments passed on "__cdecl" format (another script test exist with arguments passed on "__sdtcall" format)
%PYTHON32% testdll_cdecl.py dll_core.dll
exit /B 


:complinkTWO
echo.  ******************                Compilation de la DLL                   *******************
REM Options used with Digital Mars Compiler compiler 32 bits version 8.57 :
REM		-c 								-> compile only, not call of linker
REM		-Ab 							-> enable bool			
REM 	-Bf								-> set message language French, option -Be to English
REM 	-WD  							-> set generation to Windows DLL  (-WA to generate GUI Windows Application)
REM 	-w-								-> set all warning of compiler
REM 	-odll_core.obj					-> -oxxxxxxxxx, output filename, here an object file
REM 	-Dxxxxxx						-> define variable xxxxxx used by preprocessor of Digital Mars Compiler compiler 
REM 	-IC:\dm\include\win32			-> -Ixxxxxxxxx, set the "main" include directory (another include directory can be added with another option -I....)
REM 							Option not use : -Pz 						-> default to stdcall linkage
echo.  **************************       Generation de la DLL en deux passes    *************************
dmc src\dll_core.c -c -Ab -Bf -mn -WD -w- -odll_core.obj -DBUILD_DLL -D_WIN32 -DNDEBUG -IC:\dm\include\win32 -IC:\dm\stlport\stlport -IC:\dm\include
REM Options used with Digital Mars Compiler linker 32 bits :
REM Format general of Digital Mars link command : link [options] objfiles, exefile, mapfile, libfiles, deffile, resfiles     (comma separated list of flles used by linker)
REM 	/SUBSYSTEM:WINDOWS						-> set the subsystem to Windows application 
REM 	/NOLOGO  								-> don't see copyrigth and other informations about DMC
REM 	/EXETYPE:NT 							-> set the type of executable to Windows NT (NT system or superior, like Windows 7, 8, 10 or 11)
REM 	/IMPDEF:dll_core_2.def    				-> /IMPDEF:xxxxxxxx generate definition file designed after
REM 	/IMPLIB:dll_core.lib					-> /IMPLIB:xxxxxxxx generate library file designed after
REM 	Don't use    -> /ENTRY:DllMain							-> define entry name (or entry'point) of DLL to be : DllMain
echo.  *****************             Edition des liens (linkage) de la DLL             ***************
link /NOLOGO /SUBSYSTEM:WINDOWS /EXETYPE:NT /IMPDEF:dll_core_2.def /IMPLIB:dll_core.lib dll_core.obj, dll_core.dll, , kernel32 user32.lib, src\dll_core.def 
REM    (mandatory, because option /IMPLIB used by linker don't generate correct library file)
REM 	See the result of generate def file by linker
type dll_core_2.def
REM     Use of "implib" utility" because bug with precedent command during linkage : library generate "dll_core.lib" seems in wrong format !!!
REM 	The message during next generation of main test program of DLL is : "dll_core.lib : Error 30: Unexpected End of File"
implib /system dll_core.lib dll_core.dll
REM    Use of tool libunres to see publics names (here symbol of function exported by lib)
REM 		-p 				: option to see publics names
echo.  ***************** 	         Listage des symboles exportes de la librairie 32 bits	          *****************
libunres -p dll_core.lib
echo.  ************     Generation et lancement du premier programme de test de la DLL en mode implicite.      *************
dmc src\testdll_implicit.c -c -Ab -Bf -w- -otestdll_implicit.obj -D_WIN32 -DNDEBUG -IC:\dm\include\win32 -IC:\dm\stlport\stlport -IC:\dm\include
REM Options used with Digital Mars Compiler linker 32 bits :
REM 	/SUBSYSTEM:CONSOLE						-> set the subsystem to console application 
REM 	/NOLOGO  								-> don't see copyrigth and other informations about DMC
REM 	/EXETYPE:NT 							-> set the type of executable to Windows NT (NT system or superior, like Windows 7, 8, 10 or 11)
link /NOLOGO /SUBSYSTEM:CONSOLE /EXETYPE:NT  testdll_implicit.obj, testdll_implicit.exe, , kernel32 user32.lib dll_core.lib
REM 	Run the main test program of DLL in "two pass", with explicit load of DLL :	  All function of DLL execute normally, but DllMAin seems not call !!!!
testdll_implicit.exe
echo.  ************     Generation et lancement du deuxieme programme de test de la DLL en mode explicite.     ************
dmc src\testdll_explicit.c -c -Ab -Bf -w- -otestdll_explicit.obj -D_WIN32 -DNDEBUG -IC:\dm\include\win32 -IC:\dm\stlport\stlport -IC:\dm\include
REM Options used with Digital Mars Compiler linker 32 bits :
REM 	/SUBSYSTEM:CONSOLE						-> set the subsystem to console application 
REM 	/NOLOGO  								-> don't see copyrigth and other informations about DMC
REM 	/EXETYPE:NT 							-> set the type of executable to Windows NT (NT system or superior, like Windows 7, 8, 10 or 11)
link /NOLOGO /SUBSYSTEM:CONSOLE /EXETYPE:NT testdll_explicit.obj, testdll_explicit.exe, , kernel32 user32.lib dll_core.lib
REM 	Run the main test program of DLL in "two pass", with explicit load of DLL :					All success.
testdll_explicit.exe
REM 	Execution of python script (version 32 bits) to test DLL : 									All success.
echo.   *****************                  Lancement du script python de test de la DLL.                  ********************
%PYTHON32% testdll_cdecl.py dll_core.dll
exit /B 

:FIN
echo.        Fin de la generation de la DLL avec Digital Mars Compiler C/C++ 32 bits version 8.57   
REM 	Return in initial PATH
set PATH=%PATHINIT%