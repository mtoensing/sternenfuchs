#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>
static const char* names[]={"STARFOX_TEST_ENDING","STARFOX_TEST_NUCLEUS_DEFEAT","STARFOX_TEST_PREROLL_TICKS","STARFOX_TEST_REVIVAL","STARFOX_TEST_REVIVAL_FRAME","STARFOX_TEST_MESSAGE","STARFOX_TEST_UPGRADE_FLASH","STARFOX_TEST_SCRAMBLE_WIPE","STARFOX_TEST_EX_CROSSHAIR","STARFOX_TEST_TITANIA_END","STARFOX_TEST_CLEAR","STARFOX_TEST_UNPACED"};
static unsigned counts[12];
char*getenv(const char*name){static char*(*real)(const char*);if(!real)real=dlsym(RTLD_NEXT,"getenv");for(unsigned i=0;i<12;i++)if(!strcmp(name,names[i])){counts[i]++;return NULL;}return real(name);}
__attribute__((destructor)) static void report(void){for(unsigned i=0;i<12;i++)if(counts[i])fprintf(stderr,"qa-query %s count=%u\n",names[i],counts[i]);}
