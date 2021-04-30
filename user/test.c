
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
void 
testall(){
  int i = 0;
  uint64 c = 17;
  uint64 pointers[c];
  printf("IN PARENT: BEFORE SBRK BEFORE FORK Number of free pages \n");
  for (i = 0 ; i < c ; i++){
        pointers[i] = (uint64)sbrk(4096);
        * (char *) pointers[i] = (char) ('a' + i);
        printf("%c\n",  * (char *) pointers[i]);
  }

  printf("IN PARENT:AFTER SBARK BEFORE FORK Number of free pages \n");
  int pid;
  if( (pid = fork()) ==0){
      printf("IN CHILD: Number of free pages \n");
      for (i = 0 ; i < c ; i++){
        printf("letter %c\n", i, *(char * )pointers[i]);
      }
      exit(0);
  }
  else{
    int status;
    wait(&status); 
  }
}
/*
void
testSecFIFO(){
  int i = 0;
  uint c = 14;
  uint pointers[c];
  //create all files
  for (i = 0 ; i < c ; i++){
        pointers[i] = (uint)sbrk(4096);
        * (char *) pointers[i] = (char) ('a' + i);
        printf(1, "%c\n", *(char * )pointers[i]);
  }
  //accsess only 
  for (i = 1 ; i < c/2 ; i++){
        printf(1, "sec %c\n", *(char * )pointers[i]);
  }
  printf(1, "third %c\n", *(char * )pointers[0]);

}
*/
int
main(void)
{
  printf( "--------- test  ---------\n");
  testall();
  //testSecFIFO();
  exit(0);
  return 0; 
}