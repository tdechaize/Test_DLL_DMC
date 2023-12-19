@echo off
REM    ************************************************************************************************************
REM
REM   	Script de génération de la DLL add.dll et du programme de test addtest.exe ou de test avec un script python
REM		Ce fichier de commande est paramètrable avec un seul paramètre : soit une compilation et un linkage en mode 32 bits 
REM 	soit en mode 64 bits pour les compilateurs qui le supportent.
REM     En conséquence, ce paramètre peut prendre les valeurs suivantes :
REM 		32, 64 ou  ALL si vous souhaitez lancer les deux générations, 32 bits et 64 bits.
REM 	Dans le cas du compilateur DMC, une seule génération possible : 32 bits, ce paramètre est testé mais ignoré.
REM
REM 	Author : 						Thierry DECHAIZE
REM		Date creation/modification : 	13/10/2023
REM 	Reason of modifications : 		n° 1 - Blah blah blah ...
REM 	Reason of modifications : 		n° 2 - Blah blah blah ... 
REM 	Version number :				1.1.0             (version majeure . version mineure . patch level)

REM     Affichage du nom du système d'exploitation Windows :              	Microsoft Windows 11 Famille
REM 	Affichage de la version du système Windows :              			10.0.22621
WMIC OS GET Name
WMIC OS GET Version

REM 	Save of initial PATH on PATHINIT variable
set PATHINIT=%PATH%
REM      Mandatory, add to PATH the binary directory of compiler Digital Mars (You can adapt this directory at your personal
REM 		software environment)
set PATH=C:\dm\bin;%PATH%
REM 	Format of command "dmc" (DMC is a one-step program to compile and link C++, C and ASM files)
REM 		DMC file... [flags...] [@respfile]  
REM 	Generation of the DLL in "one pass", with many options -Lxxxxxxxxx : xxxxxxxxx do complementaries instructions to linker
REM 			-mn 					-> set memory model to Windows 32s/95/98/NT/2000/ME/XP (mandatory)
REM 			-WD						-> set generation to Windows DLL (mandatory, in evidence !!!)
REM 			-o output_file			-> set name of output file
REM 			-L/implib:dll_testing.lib 	 -> advise linker to generate a library file, here dll_testing.lib
REM 			-L/impdef:dll_testing_2.def  -> advise linker to generate a def file, here dll_testing_2.def
dmc dll_testing.c -mn -WD -o dll_testing.dll -L/implib:dll_testing.lib -L/impdef:dll_testing_2.def user32.lib kernel32.lib 
REM 	WARNING COMPORTEMENT ERRATIC OF COMPILER DMC : If you place an definition file with the same name of source file (like dll_testing.def) 
REM 			on directory, dmc compiler read the information of this def file (implicit reading !!!) without warning or explicit advising !!!
REM 	Error generated if "dll_testing.def" is present, because his content doesn't match with exported symbols of dll : 
REM 			link dll_testing,dll_testing.dll,,user32+kernel32,dll_testing/noi;
REM 			OPTLINK (R) for Win32  Release 8.00.16
REM 			Copyright (C) Digital Mars 1989-2013  All rights reserved.
REM 			http://www.digitalmars.com/ctg/optlink.html
REM 			OPTLINK : Error 180: No Match Found for Export/ENTRY -  : DllMain
REM 			OPTLINK : Error 180: No Match Found for Export/ENTRY -  : Add
REM 			OPTLINK : Error 180: No Match Found for Export/ENTRY -  : Hello
REM 			OPTLINK : Error 180: No Match Found for Export/ENTRY -  : Substract
REM 			OPTLINK : Error 180: No Match Found for Export/ENTRY -  : Multiply
REM 			OPTLINK : Warning 148: USE16/USE32 Mismatch : DGROUP
REM 			C:\dm\bin\..\lib\SNN.lib(dllstart)
REM 			 Error 83: Illegal frame on start address
REM 			OPTLINK : Warning 174: 32-bit Segments Inappropriate for 16-bit Segmented output
REM 			OPTLINK : Error 81: Cannot EXPORT : DllMain
REM 			OPTLINK : Error 81: Cannot EXPORT : Add
REM 			OPTLINK : Error 81: Cannot EXPORT : Hello
REM 			OPTLINK : Error 81: Cannot EXPORT : Substract
REM 			OPTLINK : Error 81: Cannot EXPORT : Multiply
REM 			dll_testing.obj(dll_testing)
REM 				.....................
REM 			--- errorlevel 12
REM  dll_testing.def
REM 	See the result of generate def file by linker
type dll_testing_2.def
REM     Use of "implib" utility" because bug with precedent command during linkage : library generate "dll_testing.lib" seems in wrong format !!!
implib dll_testing.lib dll_testing.dll
REM 	Generation of the main test program of DLL in "one pass", with explicit load of DLL : a console application.
dmc main_dll_testing.c -o main_dll_testing.exe user32.lib kernel32.lib dll_testing.lib
REM 	Run the main test program of DLL, with explicit load of DLL
main_dll_testing.exe
REM 	Run the script python to test DLL with arguments passed on "__cdecl" format (another script test with arguments passed on "__sdtcall" format)
%PYTHON32% test_add_cdecl.py dll_testing.dll
REM 	Return in initial PATH
set PATH=%PATHINIT%
REM    ************************************************************************************************************