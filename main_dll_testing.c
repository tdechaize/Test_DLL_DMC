//*****************     File : main_dll_testing.c (test program of dll)    **************
#include <stdio.h>
#include <windows.h>

typedef int (*AddFunc)(int,int);

int main(int argc, char *argv[])
{
	int a = 42;
	int b = 7;
	int result=0;
	
	HINSTANCE hLib = LoadLibrary("dll_testing.dll");
	
	AddFunc af = (AddFunc)GetProcAddress(hLib, "Add");
	
	result = af(a, b);
	printf("La somme de %i et %i vaut %i. (from application with explicit load of DLL %s)\n", a,b,result,argv[0]);

	FreeLibrary(hLib);
}
//*********************           End file : main_dll_testing.c           **************