//********************      File : dll_testing.c (main of dll)        ***************
#include <windows.h>
#include <stdio.h>

/* if used by C++ code, identify these functions as C items */
#ifdef __cplusplus
extern "C" {
#endif

__declspec(dllexport) BOOL APIENTRY DllMain(HANDLE hModule, 
											DWORD ul_reason_for_call,
											LPVOID lpReserved)
   {
    switch (ul_reason_for_call)
    {
    case DLL_PROCESS_ATTACH:
        printf( "DLL attaching to process...\n" );
        break;
    case DLL_PROCESS_DETACH:
        printf( "DLL detaching from process...\n" );
        break;
		// The attached process creates a new thread.
	case DLL_THREAD_ATTACH:
		printf("The attached process creating a new thread...\n");
		break;
		// The thread of the attached process terminates.
	case DLL_THREAD_DETACH:
		printf("The thread of the attached process terminates...\n");
		break;
	default:
		printf("Reason called not matched, error if any : %ld...\n", GetLastError());
		break;
    }
    return TRUE;
   }

__declspec(dllexport) int Add(int i1, int i2)
 {
	return i1 + i2;
 }

/* if used by C++ code, identify these functions as C items */
#ifdef __cplusplus
}
#endif
 
//********************            End file : dll_testing.c             ***************