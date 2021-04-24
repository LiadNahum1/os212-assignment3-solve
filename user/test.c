
#include "types.h"
#include "stat.h"
#include "user.h"

void 
testall(){
  int i = 0;
  uint c = 16;
  uint pointers[c];
  printf(1, "IN PARENT: BEFORE SBRK BEFORE FORK Number of free pages %d\n" ,getNumberOfFreePages());
  for (i = 0 ; i < c ; i++){
        pointers[i] = (uint)sbrk(4096);
        * (char *) pointers[i] = (char) ('a' + i);
  }

  printf(1, "IN PARENT:AFTER SBARK BEFORE FORK Number of free pages %d\n" ,getNumberOfFreePages());
  int pid;
  if( (pid = fork()) ==0){
      printf(1, "IN CHILD: Number of free pages %d\n" ,getNumberOfFreePages());
      for (i = 0 ; i < c ; i++){
        printf(1, "%c\n", *(char * )pointers[i]);
      }
      printf(1, "IN CHILD: change content of first page from a to b\n");
      * (char *) pointers[10] = (char) ('b');
      * (char *) pointers[11] = (char) ('c');
      printf(1,"IN CHILD pointers[10] %c\n", *(char * )pointers[10]);
      printf(1,"IN CHILD pointers[11] %c\n", *(char * )pointers[11]);
      printf(1, "IN CHILD: Number of free pages  %d\n" ,getNumberOfFreePages());
      exit();
  }
  else{
    wait();
    printf(1,"IN PARENT pointers[10] %c\n", *(char * )pointers[10]);
    printf(1,"IN PARENT pointers[11] %c\n", *(char * )pointers[11]);
    printf(1, "IN PARENT: Number of free pages  %d\n" ,getNumberOfFreePages());
 
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
  printf(1, "--------- test  ---------\n");
  testall();
  //testSecFIFO();
  exit();
}