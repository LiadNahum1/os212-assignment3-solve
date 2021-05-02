
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
void 
testall(){
  int i = 0;
  uint64 c = 17;
  uint64 pointers[c];
  printf("IN PARENT\n");
  for (i = 0 ; i < c ; i++){
        pointers[i] = (uint64)sbrk(4096);
        * (char *) pointers[i] = (char) ('a' + i);
        printf("%c\n",  * (char *) pointers[i]);
  }

  int pid;
  if( (pid = fork()) ==0){
      printf("IN CHILD \n");
      for (i = 0 ; i < c ; i++){
        printf("letter %c\n", *(char * )pointers[i]);
      }
      exit(0);
  }
  else{
    int status;
    wait(&status); 
  }
}

int
main(void)
{
  printf( "--------- test  ---------\n");
  testall();
  exit(0);
  return 0; 
}