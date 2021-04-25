#include "param.h"
#include "types.h"
#include "memlayout.h"
#include "elf.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
//added
#include "spinlock.h"
#include "proc.h"
void lazy_memory_allocation(uint64 faulting_address);
int find_file_to_remove();
uint init_aging(int fifo_init_pages);
/*
 * the kernel's page table.
 */
pagetable_t kernel_pagetable;

extern char etext[];  // kernel.ld sets this to end of kernel code.

extern char trampoline[]; // trampoline.S

// Make a direct-map page table for the kernel.
pagetable_t
kvmmake(void)
{
  pagetable_t kpgtbl;

  kpgtbl = (pagetable_t) kalloc();
  memset(kpgtbl, 0, PGSIZE);

  // uart registers
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);

  // virtio mmio disk interface
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);

  // PLIC
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);

  // map kernel text executable and read-only.
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);

  // map kernel data and the physical RAM we'll make use of.
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);

  // map the trampoline for trap entry/exit to
  // the highest virtual address in the kernel.
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);

  // map kernel stacks
  proc_mapstacks(kpgtbl);
  
  return kpgtbl;
}

// Initialize the one kernel_pagetable
void
kvminit(void)
{
  kernel_pagetable = kvmmake();
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
  w_satp(MAKE_SATP(kernel_pagetable));
  sfence_vma();
}

// Return the address of the PTE in page table pagetable
// that corresponds to virtual address va.  If alloc!=0,
// create any required page-table pages.
//
// The risc-v Sv39 scheme has three levels of page-table
// pages. A page-table page contains 512 64-bit PTEs.
// A 64-bit virtual address is split into five fields:
//   39..63 -- must be zero.
//   30..38 -- 9 bits of level-2 index.
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
  if(va >= MAXVA)
    panic("walk");

  for(int level = 2; level > 0; level--) {
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
}

// Look up a virtual address, return the physical address,
// or 0 if not mapped.
// Can only be used to look up user pages.
uint64
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    return 0;

  pte = walk(pagetable, va, 0);
  if(pte == 0)
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}

// add a mapping to the kernel page table.
// only used when booting.
// does not flush TLB or enable paging.
void
kvmmap(pagetable_t kpgtbl, uint64 va, uint64 pa, uint64 sz, int perm)
{
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    panic("kvmmap");
}

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
  last = PGROUNDDOWN(va + size - 1);
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
      return -1;
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
}

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
      panic("uvmunmap: not a leaf");
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  
      /*
     //assign3
    pte = walk(pagetable, a, 0);
    if(pte != 0){
      if(PTE_FLAGS(*pte) == PTE_V)
        panic("uvmunmap: not a leaf");
       
      if( (*pte & PTE_V)!=0){  
      if(do_free){
        uint64 pa = PTE2PA(*pte);
        kfree((void*)pa);
      }
      *pte = 0;
    }
  }*/
  }
}


// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
  if(pagetable == 0)
    return 0;
  memset(pagetable, 0, PGSIZE);
  return pagetable;
}

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
  char *mem;

  if(sz >= PGSIZE)
    panic("inituvm: more than a page");
  mem = kalloc();
  memset(mem, 0, PGSIZE);
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
  memmove(mem, src, sz);
}

// Allocate PTEs and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
uint64
uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  char *mem;
  uint64 a;

  if(newsz < oldsz)
    return oldsz;

  oldsz = PGROUNDUP(oldsz);
  for(a = oldsz; a < newsz; a += PGSIZE){
    /*if(myproc()->pid > 2){
      walk(pagetable, a, 1);
    }
    else{*/
      mem = kalloc();
      if(mem == 0){
        uvmdealloc(pagetable, a, oldsz);
        return 0;
      }
      memset(mem, 0, PGSIZE);
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
        kfree(mem);
        uvmdealloc(pagetable, a, oldsz);
        return 0;
      }
   // }
  }
  return newsz;
}

// Deallocate user pages to bring the process size from oldsz to
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
  if(newsz >= oldsz)
    return oldsz;

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
      freewalk((pagetable_t)child);
      pagetable[i] = 0;
    } else if(pte & PTE_V){
      panic("freewalk: leaf");
    }
  }
  kfree((void*)pagetable);
}

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
  if(sz > 0)
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
}

// Given a parent process's page table, copy
// its memory into a child's page table.
// Copies both the page table and the
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
      kfree(mem);
      goto err;
    }
    /*
    //assign3
    if((pte = walk(old, i, 0)) !=0 && ((*pte & PTE_V) != 0)){
      pa = PTE2PA(*pte);
      flags = PTE_FLAGS(*pte);
      if((mem = kalloc()) == 0)
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
        kfree(mem);
        goto err;
      }
    }*/
    
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
  return -1;
}

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
  if(pte == 0)
    panic("uvmclear");
  *pte &= ~PTE_U;
}

// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(dstva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);

    len -= n;
    src += n;
    dstva = va0 + PGSIZE;
  }
  return 0;
}

// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);

    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;
}

// Copy a null-terminated string from user to kernel.
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
        got_null = 1;
        break;
      } else {
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    return 0;
  } else {
    return -1;
  }
}


 

void swap_page_into_file(int offset){
    struct proc * p = myproc();
    int remove_file_indx = find_file_to_remove();
    uint64 removed_page_VA = remove_file_indx*PGSIZE;
    printf("chosen file %d \n", remove_file_indx);
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    //write the information from this file to memory
    uint64 physical_addr = PTE2PA(*out_page_entry);
    if(writeToSwapFile(p,(char*)physical_addr,offset,PGSIZE) ==  -1)
      panic("write to file failed");
    //free the RAM memmory of the swapped page
    kfree((void*)physical_addr);
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    p->paging_meta_data[remove_file_indx].offset = offset;
    p->paging_meta_data[remove_file_indx].in_memory = 0;
      
}

int get_num_of_pages_in_memory(){
  int counter = 0;
  for(int i=0; i<32; i++){
    if(myproc()->paging_meta_data[i].in_memory)
      counter = counter+1;
  }
  return counter; 
}

void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
  //get the page number of the missing in ram page
  int current_page_number = PGROUNDDOWN(faulting_address)/PGSIZE;
  //get its offset in the saved file
  uint offset = myproc()->paging_meta_data[current_page_number].offset;
  if(offset == -1){
    panic("offset is -1");
  }
  //allocate a buffer for the information from the file
  char* read_buffer;
  if((read_buffer = kalloc()) == 0)
    panic("not enough space to kalloc");
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    panic("read from file failed");
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
  }  
  else{
      *missing_pte_entry = PA2PTE((uint64)read_buffer) | PTE_V; 
  }
  //update offsets and aging of the files
  myproc()->paging_meta_data[current_page_number].aging = init_aging(current_page_number);
  myproc()->paging_meta_data[current_page_number].offset = -1;
  myproc()->paging_meta_data[current_page_number].in_memory = 1;
  sfence_vma(); //refresh TLB
}

void lazy_memory_allocation(uint64 faulting_address){
    char * mem = kalloc();
    if(mem == 0){
      panic("not enough space to kalloc");
    }
    memset(mem, 0, PGSIZE);
    if(mappages(myproc()->pagetable, PGROUNDDOWN(faulting_address), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
      kfree(mem);
      panic("mappages failed");
    }
}

void check_page_fault(){
  uint64 faulting_address = r_stval(); 
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
  if(pte_entry !=0 && ((!(PTE_FLAGS(*pte_entry) & PTE_V) ) & (PTE_FLAGS(*pte_entry) & PTE_PG))){
    printf("Page Fault - Page was out of memory\n");
    page_in(faulting_address, pte_entry);
  }
  else{
    printf("Page Fault - Lazy allocation\n");
    printf("%d\n", faulting_address);
    lazy_memory_allocation(faulting_address);
  }
}


int minimum_counter_NFUA(){
  struct proc * p = myproc();
  uint min_age = -1;
  int index_page = -1;
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    if (p->paging_meta_data[i].in_memory ){
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
          min_age = p->paging_meta_data[i].aging;
          index_page = i;
        }
      }
  }
  if(min_age == -1)
    panic("page replacment algorithem failed");
  return index_page;
}

int count_one_bits(uint age){
  int count = 0;
  while(age) {
      count += age & 1;
      age >>= 1;
  }
  return count;
}

int minimum_ones(){
  struct proc * p = myproc();
  int min_ones = -1;
  int min_age = -1;
  int index_page = -1;
  uint age;
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    if (p->paging_meta_data[i].in_memory ){
      age =  p->paging_meta_data[i].aging;
      int count_ones =  count_one_bits(age);
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
        min_ones = count_ones;
        min_age = age;
        index_page = i;
      }
    }
  }
  if(min_ones == -1)
    panic("page replacment algorithem failed");
  return index_page;
}

void remove_from_queue(struct age_queue * q){
  q->front = q->front+1;
   if(q->front == 32) {
      q->front = 0;
   }
   q->page_counter = q->page_counter-1;
   
}
void insert_to_queue(int inserted_page){
  struct proc * process = myproc();
  struct age_queue * q = &process->queue;
  if(inserted_page >= 3){
    if (q->last == 31)
      q->last = -1;
    q->last = q->last + 1;
    q->pages[q->last] =inserted_page;
    q->page_counter =  q->page_counter + 1;
  }
}
int second_fifo(){
  struct proc * p = myproc();
  struct age_queue * q = &(p->queue);
  int current_page;
  int page_counter = q->page_counter;
  for (int i = 0; i<page_counter; i++){
    current_page = q->pages[q->front];
    pte_t * pte = walk(p->pagetable, current_page*PGSIZE,0);
    uint pte_flags = PTE_FLAGS(*pte);
    if(!(pte_flags & PTE_A)){
      printf("not accsesed %d", current_page);
      remove_from_queue(q);
      return current_page; //the file will no longer be in the memory and will be removed next time
    }
    else{ //the page has been accsesed
      *pte = *pte & (~PTE_A); //make A bit off
      printf("removing accsesed bit from %d", current_page);
      remove_from_queue(q);
      insert_to_queue(current_page);
    }
  }
  current_page = q->pages[q->front];
  remove_from_queue(q);
  return current_page;
}

int minimum_advanicing_queue(){
  struct proc * p = myproc();
  struct age_queue * q = &(p->queue);
  int current_page = q->pages[q->front];
  remove_from_queue(q);
  return current_page;
}
int find_file_to_remove(){
  #if SELECTION==NFUA
    return minimum_counter_NFUA();
  #endif
  #if SELECTION == LAPA
    return minimum_ones();
  #endif
  #if SELECTION==SCFIFO
    return second_fifo(); 
  #endif
  #if SELECTION == AQ
    return minimum_advanicing_queue(); 
  #endif
  return 0;
}

void shift_counter(){
 struct proc * p = myproc();
 pte_t * pte;
 for(int i=0; i<32; i++){
      uint page_virtual_address = i*PGSIZE;
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
      if(*pte & PTE_V){
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
        if(*pte & PTE_A){
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
          *pte = *pte & (~PTE_A); //turn off
        }
      }
    }
}
void shift_queue(){
  struct proc * p = myproc();
  struct age_queue * q = &(p->queue);
  int front = q->front;
  int page_count = q->page_counter;
  for(int i = page_count-2; i >0; i--){ //front + i is the index of the one before last page in the queue
    int temp = q->pages[(front+ i)%32];
    pte_t * pte = walk(p->pagetable, temp*PGSIZE,0);
    uint pte_flags = PTE_FLAGS(*pte);
    if(pte_flags & PTE_A){
      q->pages[(front + i)%32] = q->pages[(front + i + 1)%32];
      q->pages[(front + 1 + i)%32] = temp;; 
    }
    *pte = *pte & (~PTE_A);
  }
}
//update aging algorithm when the process returns to the scheduler
void
update_aging_algorithms(void){
  #if SELECTION == NFUA
      shift_counter();
  #endif
  #if SELECTION == LAPA
      shift_counter();
  #endif
  #if SELECTION==SCFIFO
  return;
  #endif
  #if SELECTION == AQ
    shift_queue();
  #endif
return;
}

uint init_aging(int fifo_init_pages){
  #if SELECTION == NFUA
    return 0;
  #endif
  #if SELECTION == LAPA
    return LAPA_AGE;
  #endif
  #if SELECTION == AQ
    return insert_to_queue(fifo_init_pages);
  #endif
  #if SELECTION==SCFIFO
    return insert_to_queue(fifo_init_pages);
  #endif 
  return 0;
}
