
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	8ec78793          	addi	a5,a5,-1812 # 80006950 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd07ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dce78793          	addi	a5,a5,-562 # 80000e7c <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	c28080e7          	jalr	-984(ra) # 80002d46 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	77a080e7          	jalr	1914(ra) # 800008a8 <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7159                	addi	sp,sp,-112
    80000158:	f486                	sd	ra,104(sp)
    8000015a:	f0a2                	sd	s0,96(sp)
    8000015c:	eca6                	sd	s1,88(sp)
    8000015e:	e8ca                	sd	s2,80(sp)
    80000160:	e4ce                	sd	s3,72(sp)
    80000162:	e0d2                	sd	s4,64(sp)
    80000164:	fc56                	sd	s5,56(sp)
    80000166:	f85a                	sd	s6,48(sp)
    80000168:	f45e                	sd	s7,40(sp)
    8000016a:	f062                	sd	s8,32(sp)
    8000016c:	ec66                	sd	s9,24(sp)
    8000016e:	e86a                	sd	s10,16(sp)
    80000170:	1880                	addi	s0,sp,112
    80000172:	8aaa                	mv	s5,a0
    80000174:	8a2e                	mv	s4,a1
    80000176:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a4e080e7          	jalr	-1458(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00011497          	auipc	s1,0x11
    80000190:	ff448493          	addi	s1,s1,-12 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00011917          	auipc	s2,0x11
    80000198:	08490913          	addi	s2,s2,132 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    8000019c:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000019e:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a0:	4ca9                	li	s9,10
  while(n > 0){
    800001a2:	07305863          	blez	s3,80000212 <consoleread+0xbc>
    while(cons.r == cons.w){
    800001a6:	0984a783          	lw	a5,152(s1)
    800001aa:	09c4a703          	lw	a4,156(s1)
    800001ae:	02f71463          	bne	a4,a5,800001d6 <consoleread+0x80>
      if(myproc()->killed){
    800001b2:	00002097          	auipc	ra,0x2
    800001b6:	ec6080e7          	jalr	-314(ra) # 80002078 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	774080e7          	jalr	1908(ra) # 80002936 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef700e3          	beq	a4,a5,800001b2 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d6:	0017871b          	addiw	a4,a5,1
    800001da:	08e4ac23          	sw	a4,152(s1)
    800001de:	07f7f713          	andi	a4,a5,127
    800001e2:	9726                	add	a4,a4,s1
    800001e4:	01874703          	lbu	a4,24(a4)
    800001e8:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    800001ec:	077d0563          	beq	s10,s7,80000256 <consoleread+0x100>
    cbuf = c;
    800001f0:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f4:	4685                	li	a3,1
    800001f6:	f9f40613          	addi	a2,s0,-97
    800001fa:	85d2                	mv	a1,s4
    800001fc:	8556                	mv	a0,s5
    800001fe:	00003097          	auipc	ra,0x3
    80000202:	af2080e7          	jalr	-1294(ra) # 80002cf0 <either_copyout>
    80000206:	01850663          	beq	a0,s8,80000212 <consoleread+0xbc>
    dst++;
    8000020a:	0a05                	addi	s4,s4,1
    --n;
    8000020c:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    8000020e:	f99d1ae3          	bne	s10,s9,800001a2 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000212:	00011517          	auipc	a0,0x11
    80000216:	f6e50513          	addi	a0,a0,-146 # 80011180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a6c080e7          	jalr	-1428(ra) # 80000c86 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a56080e7          	jalr	-1450(ra) # 80000c86 <release>
        return -1;
    80000238:	557d                	li	a0,-1
}
    8000023a:	70a6                	ld	ra,104(sp)
    8000023c:	7406                	ld	s0,96(sp)
    8000023e:	64e6                	ld	s1,88(sp)
    80000240:	6946                	ld	s2,80(sp)
    80000242:	69a6                	ld	s3,72(sp)
    80000244:	6a06                	ld	s4,64(sp)
    80000246:	7ae2                	ld	s5,56(sp)
    80000248:	7b42                	ld	s6,48(sp)
    8000024a:	7ba2                	ld	s7,40(sp)
    8000024c:	7c02                	ld	s8,32(sp)
    8000024e:	6ce2                	ld	s9,24(sp)
    80000250:	6d42                	ld	s10,16(sp)
    80000252:	6165                	addi	sp,sp,112
    80000254:	8082                	ret
      if(n < target){
    80000256:	0009871b          	sext.w	a4,s3
    8000025a:	fb677ce3          	bgeu	a4,s6,80000212 <consoleread+0xbc>
        cons.r--;
    8000025e:	00011717          	auipc	a4,0x11
    80000262:	faf72d23          	sw	a5,-70(a4) # 80011218 <cons+0x98>
    80000266:	b775                	j	80000212 <consoleread+0xbc>

0000000080000268 <consputc>:
{
    80000268:	1141                	addi	sp,sp,-16
    8000026a:	e406                	sd	ra,8(sp)
    8000026c:	e022                	sd	s0,0(sp)
    8000026e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000270:	10000793          	li	a5,256
    80000274:	00f50a63          	beq	a0,a5,80000288 <consputc+0x20>
    uartputc_sync(c);
    80000278:	00000097          	auipc	ra,0x0
    8000027c:	55e080e7          	jalr	1374(ra) # 800007d6 <uartputc_sync>
}
    80000280:	60a2                	ld	ra,8(sp)
    80000282:	6402                	ld	s0,0(sp)
    80000284:	0141                	addi	sp,sp,16
    80000286:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000288:	4521                	li	a0,8
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	54c080e7          	jalr	1356(ra) # 800007d6 <uartputc_sync>
    80000292:	02000513          	li	a0,32
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	540080e7          	jalr	1344(ra) # 800007d6 <uartputc_sync>
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	536080e7          	jalr	1334(ra) # 800007d6 <uartputc_sync>
    800002a8:	bfe1                	j	80000280 <consputc+0x18>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	e04a                	sd	s2,0(sp)
    800002b4:	1000                	addi	s0,sp,32
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00011517          	auipc	a0,0x11
    800002bc:	ec850513          	addi	a0,a0,-312 # 80011180 <cons>
    800002c0:	00001097          	auipc	ra,0x1
    800002c4:	912080e7          	jalr	-1774(ra) # 80000bd2 <acquire>

  switch(c){
    800002c8:	47d5                	li	a5,21
    800002ca:	0af48663          	beq	s1,a5,80000376 <consoleintr+0xcc>
    800002ce:	0297ca63          	blt	a5,s1,80000302 <consoleintr+0x58>
    800002d2:	47a1                	li	a5,8
    800002d4:	0ef48763          	beq	s1,a5,800003c2 <consoleintr+0x118>
    800002d8:	47c1                	li	a5,16
    800002da:	10f49a63          	bne	s1,a5,800003ee <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002de:	00003097          	auipc	ra,0x3
    800002e2:	abe080e7          	jalr	-1346(ra) # 80002d9c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	998080e7          	jalr	-1640(ra) # 80000c86 <release>
}
    800002f6:	60e2                	ld	ra,24(sp)
    800002f8:	6442                	ld	s0,16(sp)
    800002fa:	64a2                	ld	s1,8(sp)
    800002fc:	6902                	ld	s2,0(sp)
    800002fe:	6105                	addi	sp,sp,32
    80000300:	8082                	ret
  switch(c){
    80000302:	07f00793          	li	a5,127
    80000306:	0af48e63          	beq	s1,a5,800003c2 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000030a:	00011717          	auipc	a4,0x11
    8000030e:	e7670713          	addi	a4,a4,-394 # 80011180 <cons>
    80000312:	0a072783          	lw	a5,160(a4)
    80000316:	09872703          	lw	a4,152(a4)
    8000031a:	9f99                	subw	a5,a5,a4
    8000031c:	07f00713          	li	a4,127
    80000320:	fcf763e3          	bltu	a4,a5,800002e6 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000324:	47b5                	li	a5,13
    80000326:	0cf48763          	beq	s1,a5,800003f4 <consoleintr+0x14a>
      consputc(c);
    8000032a:	8526                	mv	a0,s1
    8000032c:	00000097          	auipc	ra,0x0
    80000330:	f3c080e7          	jalr	-196(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000334:	00011797          	auipc	a5,0x11
    80000338:	e4c78793          	addi	a5,a5,-436 # 80011180 <cons>
    8000033c:	0a07a703          	lw	a4,160(a5)
    80000340:	0017069b          	addiw	a3,a4,1
    80000344:	0006861b          	sext.w	a2,a3
    80000348:	0ad7a023          	sw	a3,160(a5)
    8000034c:	07f77713          	andi	a4,a4,127
    80000350:	97ba                	add	a5,a5,a4
    80000352:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000356:	47a9                	li	a5,10
    80000358:	0cf48563          	beq	s1,a5,80000422 <consoleintr+0x178>
    8000035c:	4791                	li	a5,4
    8000035e:	0cf48263          	beq	s1,a5,80000422 <consoleintr+0x178>
    80000362:	00011797          	auipc	a5,0x11
    80000366:	eb67a783          	lw	a5,-330(a5) # 80011218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00011717          	auipc	a4,0x11
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80011180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00011497          	auipc	s1,0x11
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80011180 <cons>
    while(cons.e != cons.w &&
    8000038e:	4929                	li	s2,10
    80000390:	f4f70be3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000394:	37fd                	addiw	a5,a5,-1
    80000396:	07f7f713          	andi	a4,a5,127
    8000039a:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000039c:	01874703          	lbu	a4,24(a4)
    800003a0:	f52703e3          	beq	a4,s2,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003a4:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003a8:	10000513          	li	a0,256
    800003ac:	00000097          	auipc	ra,0x0
    800003b0:	ebc080e7          	jalr	-324(ra) # 80000268 <consputc>
    while(cons.e != cons.w &&
    800003b4:	0a04a783          	lw	a5,160(s1)
    800003b8:	09c4a703          	lw	a4,156(s1)
    800003bc:	fcf71ce3          	bne	a4,a5,80000394 <consoleintr+0xea>
    800003c0:	b71d                	j	800002e6 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c2:	00011717          	auipc	a4,0x11
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80011180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e0:	10000513          	li	a0,256
    800003e4:	00000097          	auipc	ra,0x0
    800003e8:	e84080e7          	jalr	-380(ra) # 80000268 <consputc>
    800003ec:	bded                	j	800002e6 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003ee:	ee048ce3          	beqz	s1,800002e6 <consoleintr+0x3c>
    800003f2:	bf21                	j	8000030a <consoleintr+0x60>
      consputc(c);
    800003f4:	4529                	li	a0,10
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e72080e7          	jalr	-398(ra) # 80000268 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003fe:	00011797          	auipc	a5,0x11
    80000402:	d8278793          	addi	a5,a5,-638 # 80011180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00011797          	auipc	a5,0x11
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00011517          	auipc	a0,0x11
    8000042e:	dee50513          	addi	a0,a0,-530 # 80011218 <cons+0x98>
    80000432:	00002097          	auipc	ra,0x2
    80000436:	690080e7          	jalr	1680(ra) # 80002ac2 <wakeup>
    8000043a:	b575                	j	800002e6 <consoleintr+0x3c>

000000008000043c <consoleinit>:

void
consoleinit(void)
{
    8000043c:	1141                	addi	sp,sp,-16
    8000043e:	e406                	sd	ra,8(sp)
    80000440:	e022                	sd	s0,0(sp)
    80000442:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000444:	00008597          	auipc	a1,0x8
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80008010 <etext+0x10>
    8000044c:	00011517          	auipc	a0,0x11
    80000450:	d3450513          	addi	a0,a0,-716 # 80011180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6ee080e7          	jalr	1774(ra) # 80000b42 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00029797          	auipc	a5,0x29
    80000468:	4b478793          	addi	a5,a5,1204 # 80029918 <devsw>
    8000046c:	00000717          	auipc	a4,0x0
    80000470:	cea70713          	addi	a4,a4,-790 # 80000156 <consoleread>
    80000474:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000476:	00000717          	auipc	a4,0x0
    8000047a:	c7e70713          	addi	a4,a4,-898 # 800000f4 <consolewrite>
    8000047e:	ef98                	sd	a4,24(a5)
}
    80000480:	60a2                	ld	ra,8(sp)
    80000482:	6402                	ld	s0,0(sp)
    80000484:	0141                	addi	sp,sp,16
    80000486:	8082                	ret

0000000080000488 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000488:	7179                	addi	sp,sp,-48
    8000048a:	f406                	sd	ra,40(sp)
    8000048c:	f022                	sd	s0,32(sp)
    8000048e:	ec26                	sd	s1,24(sp)
    80000490:	e84a                	sd	s2,16(sp)
    80000492:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    80000494:	c219                	beqz	a2,8000049a <printint+0x12>
    80000496:	08054663          	bltz	a0,80000522 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    8000049a:	2501                	sext.w	a0,a0
    8000049c:	4881                	li	a7,0
    8000049e:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004a4:	2581                	sext.w	a1,a1
    800004a6:	00008617          	auipc	a2,0x8
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80008040 <digits>
    800004ae:	883a                	mv	a6,a4
    800004b0:	2705                	addiw	a4,a4,1
    800004b2:	02b577bb          	remuw	a5,a0,a1
    800004b6:	1782                	slli	a5,a5,0x20
    800004b8:	9381                	srli	a5,a5,0x20
    800004ba:	97b2                	add	a5,a5,a2
    800004bc:	0007c783          	lbu	a5,0(a5)
    800004c0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004c4:	0005079b          	sext.w	a5,a0
    800004c8:	02b5553b          	divuw	a0,a0,a1
    800004cc:	0685                	addi	a3,a3,1
    800004ce:	feb7f0e3          	bgeu	a5,a1,800004ae <printint+0x26>

  if(sign)
    800004d2:	00088b63          	beqz	a7,800004e8 <printint+0x60>
    buf[i++] = '-';
    800004d6:	fe040793          	addi	a5,s0,-32
    800004da:	973e                	add	a4,a4,a5
    800004dc:	02d00793          	li	a5,45
    800004e0:	fef70823          	sb	a5,-16(a4)
    800004e4:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004e8:	02e05763          	blez	a4,80000516 <printint+0x8e>
    800004ec:	fd040793          	addi	a5,s0,-48
    800004f0:	00e784b3          	add	s1,a5,a4
    800004f4:	fff78913          	addi	s2,a5,-1
    800004f8:	993a                	add	s2,s2,a4
    800004fa:	377d                	addiw	a4,a4,-1
    800004fc:	1702                	slli	a4,a4,0x20
    800004fe:	9301                	srli	a4,a4,0x20
    80000500:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000504:	fff4c503          	lbu	a0,-1(s1)
    80000508:	00000097          	auipc	ra,0x0
    8000050c:	d60080e7          	jalr	-672(ra) # 80000268 <consputc>
  while(--i >= 0)
    80000510:	14fd                	addi	s1,s1,-1
    80000512:	ff2499e3          	bne	s1,s2,80000504 <printint+0x7c>
}
    80000516:	70a2                	ld	ra,40(sp)
    80000518:	7402                	ld	s0,32(sp)
    8000051a:	64e2                	ld	s1,24(sp)
    8000051c:	6942                	ld	s2,16(sp)
    8000051e:	6145                	addi	sp,sp,48
    80000520:	8082                	ret
    x = -xx;
    80000522:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000526:	4885                	li	a7,1
    x = -xx;
    80000528:	bf9d                	j	8000049e <printint+0x16>

000000008000052a <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000052a:	1101                	addi	sp,sp,-32
    8000052c:	ec06                	sd	ra,24(sp)
    8000052e:	e822                	sd	s0,16(sp)
    80000530:	e426                	sd	s1,8(sp)
    80000532:	1000                	addi	s0,sp,32
    80000534:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000536:	00011797          	auipc	a5,0x11
    8000053a:	d007a523          	sw	zero,-758(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000053e:	00008517          	auipc	a0,0x8
    80000542:	ada50513          	addi	a0,a0,-1318 # 80008018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	b8850513          	addi	a0,a0,-1144 # 800080e0 <digits+0xa0>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	00009717          	auipc	a4,0x9
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 80009000 <panicked>
  for(;;)
    80000572:	a001                	j	80000572 <panic+0x48>

0000000080000574 <printf>:
{
    80000574:	7131                	addi	sp,sp,-192
    80000576:	fc86                	sd	ra,120(sp)
    80000578:	f8a2                	sd	s0,112(sp)
    8000057a:	f4a6                	sd	s1,104(sp)
    8000057c:	f0ca                	sd	s2,96(sp)
    8000057e:	ecce                	sd	s3,88(sp)
    80000580:	e8d2                	sd	s4,80(sp)
    80000582:	e4d6                	sd	s5,72(sp)
    80000584:	e0da                	sd	s6,64(sp)
    80000586:	fc5e                	sd	s7,56(sp)
    80000588:	f862                	sd	s8,48(sp)
    8000058a:	f466                	sd	s9,40(sp)
    8000058c:	f06a                	sd	s10,32(sp)
    8000058e:	ec6e                	sd	s11,24(sp)
    80000590:	0100                	addi	s0,sp,128
    80000592:	8a2a                	mv	s4,a0
    80000594:	e40c                	sd	a1,8(s0)
    80000596:	e810                	sd	a2,16(s0)
    80000598:	ec14                	sd	a3,24(s0)
    8000059a:	f018                	sd	a4,32(s0)
    8000059c:	f41c                	sd	a5,40(s0)
    8000059e:	03043823          	sd	a6,48(s0)
    800005a2:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005a6:	00011d97          	auipc	s11,0x11
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80011240 <pr+0x18>
  if(locking)
    800005ae:	020d9b63          	bnez	s11,800005e4 <printf+0x70>
  if (fmt == 0)
    800005b2:	040a0263          	beqz	s4,800005f6 <printf+0x82>
  va_start(ap, fmt);
    800005b6:	00840793          	addi	a5,s0,8
    800005ba:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005be:	000a4503          	lbu	a0,0(s4)
    800005c2:	14050f63          	beqz	a0,80000720 <printf+0x1ac>
    800005c6:	4981                	li	s3,0
    if(c != '%'){
    800005c8:	02500a93          	li	s5,37
    switch(c){
    800005cc:	07000b93          	li	s7,112
  consputc('x');
    800005d0:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d2:	00008b17          	auipc	s6,0x8
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80008040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00011517          	auipc	a0,0x11
    800005e8:	c4450513          	addi	a0,a0,-956 # 80011228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5e6080e7          	jalr	1510(ra) # 80000bd2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00008517          	auipc	a0,0x8
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80008028 <etext+0x28>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	f2c080e7          	jalr	-212(ra) # 8000052a <panic>
      consputc(c);
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	c62080e7          	jalr	-926(ra) # 80000268 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060e:	2985                	addiw	s3,s3,1
    80000610:	013a07b3          	add	a5,s4,s3
    80000614:	0007c503          	lbu	a0,0(a5)
    80000618:	10050463          	beqz	a0,80000720 <printf+0x1ac>
    if(c != '%'){
    8000061c:	ff5515e3          	bne	a0,s5,80000606 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000620:	2985                	addiw	s3,s3,1
    80000622:	013a07b3          	add	a5,s4,s3
    80000626:	0007c783          	lbu	a5,0(a5)
    8000062a:	0007849b          	sext.w	s1,a5
    if(c == 0)
    8000062e:	cbed                	beqz	a5,80000720 <printf+0x1ac>
    switch(c){
    80000630:	05778a63          	beq	a5,s7,80000684 <printf+0x110>
    80000634:	02fbf663          	bgeu	s7,a5,80000660 <printf+0xec>
    80000638:	09978863          	beq	a5,s9,800006c8 <printf+0x154>
    8000063c:	07800713          	li	a4,120
    80000640:	0ce79563          	bne	a5,a4,8000070a <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4605                	li	a2,1
    80000652:	85ea                	mv	a1,s10
    80000654:	4388                	lw	a0,0(a5)
    80000656:	00000097          	auipc	ra,0x0
    8000065a:	e32080e7          	jalr	-462(ra) # 80000488 <printint>
      break;
    8000065e:	bf45                	j	8000060e <printf+0x9a>
    switch(c){
    80000660:	09578f63          	beq	a5,s5,800006fe <printf+0x18a>
    80000664:	0b879363          	bne	a5,s8,8000070a <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	45a9                	li	a1,10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e0e080e7          	jalr	-498(ra) # 80000488 <printint>
      break;
    80000682:	b771                	j	8000060e <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000684:	f8843783          	ld	a5,-120(s0)
    80000688:	00878713          	addi	a4,a5,8
    8000068c:	f8e43423          	sd	a4,-120(s0)
    80000690:	0007b903          	ld	s2,0(a5)
  consputc('0');
    80000694:	03000513          	li	a0,48
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	bd0080e7          	jalr	-1072(ra) # 80000268 <consputc>
  consputc('x');
    800006a0:	07800513          	li	a0,120
    800006a4:	00000097          	auipc	ra,0x0
    800006a8:	bc4080e7          	jalr	-1084(ra) # 80000268 <consputc>
    800006ac:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006ae:	03c95793          	srli	a5,s2,0x3c
    800006b2:	97da                	add	a5,a5,s6
    800006b4:	0007c503          	lbu	a0,0(a5)
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bb0080e7          	jalr	-1104(ra) # 80000268 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c0:	0912                	slli	s2,s2,0x4
    800006c2:	34fd                	addiw	s1,s1,-1
    800006c4:	f4ed                	bnez	s1,800006ae <printf+0x13a>
    800006c6:	b7a1                	j	8000060e <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006c8:	f8843783          	ld	a5,-120(s0)
    800006cc:	00878713          	addi	a4,a5,8
    800006d0:	f8e43423          	sd	a4,-120(s0)
    800006d4:	6384                	ld	s1,0(a5)
    800006d6:	cc89                	beqz	s1,800006f0 <printf+0x17c>
      for(; *s; s++)
    800006d8:	0004c503          	lbu	a0,0(s1)
    800006dc:	d90d                	beqz	a0,8000060e <printf+0x9a>
        consputc(*s);
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	b8a080e7          	jalr	-1142(ra) # 80000268 <consputc>
      for(; *s; s++)
    800006e6:	0485                	addi	s1,s1,1
    800006e8:	0004c503          	lbu	a0,0(s1)
    800006ec:	f96d                	bnez	a0,800006de <printf+0x16a>
    800006ee:	b705                	j	8000060e <printf+0x9a>
        s = "(null)";
    800006f0:	00008497          	auipc	s1,0x8
    800006f4:	93048493          	addi	s1,s1,-1744 # 80008020 <etext+0x20>
      for(; *s; s++)
    800006f8:	02800513          	li	a0,40
    800006fc:	b7cd                	j	800006de <printf+0x16a>
      consputc('%');
    800006fe:	8556                	mv	a0,s5
    80000700:	00000097          	auipc	ra,0x0
    80000704:	b68080e7          	jalr	-1176(ra) # 80000268 <consputc>
      break;
    80000708:	b719                	j	8000060e <printf+0x9a>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b5c080e7          	jalr	-1188(ra) # 80000268 <consputc>
      consputc(c);
    80000714:	8526                	mv	a0,s1
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b52080e7          	jalr	-1198(ra) # 80000268 <consputc>
      break;
    8000071e:	bdc5                	j	8000060e <printf+0x9a>
  if(locking)
    80000720:	020d9163          	bnez	s11,80000742 <printf+0x1ce>
}
    80000724:	70e6                	ld	ra,120(sp)
    80000726:	7446                	ld	s0,112(sp)
    80000728:	74a6                	ld	s1,104(sp)
    8000072a:	7906                	ld	s2,96(sp)
    8000072c:	69e6                	ld	s3,88(sp)
    8000072e:	6a46                	ld	s4,80(sp)
    80000730:	6aa6                	ld	s5,72(sp)
    80000732:	6b06                	ld	s6,64(sp)
    80000734:	7be2                	ld	s7,56(sp)
    80000736:	7c42                	ld	s8,48(sp)
    80000738:	7ca2                	ld	s9,40(sp)
    8000073a:	7d02                	ld	s10,32(sp)
    8000073c:	6de2                	ld	s11,24(sp)
    8000073e:	6129                	addi	sp,sp,192
    80000740:	8082                	ret
    release(&pr.lock);
    80000742:	00011517          	auipc	a0,0x11
    80000746:	ae650513          	addi	a0,a0,-1306 # 80011228 <pr>
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	53c080e7          	jalr	1340(ra) # 80000c86 <release>
}
    80000752:	bfc9                	j	80000724 <printf+0x1b0>

0000000080000754 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000754:	1101                	addi	sp,sp,-32
    80000756:	ec06                	sd	ra,24(sp)
    80000758:	e822                	sd	s0,16(sp)
    8000075a:	e426                	sd	s1,8(sp)
    8000075c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000075e:	00011497          	auipc	s1,0x11
    80000762:	aca48493          	addi	s1,s1,-1334 # 80011228 <pr>
    80000766:	00008597          	auipc	a1,0x8
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80008038 <etext+0x38>
    8000076e:	8526                	mv	a0,s1
    80000770:	00000097          	auipc	ra,0x0
    80000774:	3d2080e7          	jalr	978(ra) # 80000b42 <initlock>
  pr.locking = 1;
    80000778:	4785                	li	a5,1
    8000077a:	cc9c                	sw	a5,24(s1)
}
    8000077c:	60e2                	ld	ra,24(sp)
    8000077e:	6442                	ld	s0,16(sp)
    80000780:	64a2                	ld	s1,8(sp)
    80000782:	6105                	addi	sp,sp,32
    80000784:	8082                	ret

0000000080000786 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000786:	1141                	addi	sp,sp,-16
    80000788:	e406                	sd	ra,8(sp)
    8000078a:	e022                	sd	s0,0(sp)
    8000078c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000078e:	100007b7          	lui	a5,0x10000
    80000792:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000796:	f8000713          	li	a4,-128
    8000079a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000079e:	470d                	li	a4,3
    800007a0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007a4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007a8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007ac:	469d                	li	a3,7
    800007ae:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007b2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80008058 <digits+0x18>
    800007be:	00011517          	auipc	a0,0x11
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80011248 <uart_tx_lock>
    800007c6:	00000097          	auipc	ra,0x0
    800007ca:	37c080e7          	jalr	892(ra) # 80000b42 <initlock>
}
    800007ce:	60a2                	ld	ra,8(sp)
    800007d0:	6402                	ld	s0,0(sp)
    800007d2:	0141                	addi	sp,sp,16
    800007d4:	8082                	ret

00000000800007d6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007d6:	1101                	addi	sp,sp,-32
    800007d8:	ec06                	sd	ra,24(sp)
    800007da:	e822                	sd	s0,16(sp)
    800007dc:	e426                	sd	s1,8(sp)
    800007de:	1000                	addi	s0,sp,32
    800007e0:	84aa                	mv	s1,a0
  push_off();
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	3a4080e7          	jalr	932(ra) # 80000b86 <push_off>

  if(panicked){
    800007ea:	00009797          	auipc	a5,0x9
    800007ee:	8167a783          	lw	a5,-2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007f2:	10000737          	lui	a4,0x10000
  if(panicked){
    800007f6:	c391                	beqz	a5,800007fa <uartputc_sync+0x24>
    for(;;)
    800007f8:	a001                	j	800007f8 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fa:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800007fe:	0207f793          	andi	a5,a5,32
    80000802:	dfe5                	beqz	a5,800007fa <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000804:	0ff4f513          	andi	a0,s1,255
    80000808:	100007b7          	lui	a5,0x10000
    8000080c:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000810:	00000097          	auipc	ra,0x0
    80000814:	416080e7          	jalr	1046(ra) # 80000c26 <pop_off>
}
    80000818:	60e2                	ld	ra,24(sp)
    8000081a:	6442                	ld	s0,16(sp)
    8000081c:	64a2                	ld	s1,8(sp)
    8000081e:	6105                	addi	sp,sp,32
    80000820:	8082                	ret

0000000080000822 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000822:	00008797          	auipc	a5,0x8
    80000826:	7e67b783          	ld	a5,2022(a5) # 80009008 <uart_tx_r>
    8000082a:	00008717          	auipc	a4,0x8
    8000082e:	7e673703          	ld	a4,2022(a4) # 80009010 <uart_tx_w>
    80000832:	06f70a63          	beq	a4,a5,800008a6 <uartstart+0x84>
{
    80000836:	7139                	addi	sp,sp,-64
    80000838:	fc06                	sd	ra,56(sp)
    8000083a:	f822                	sd	s0,48(sp)
    8000083c:	f426                	sd	s1,40(sp)
    8000083e:	f04a                	sd	s2,32(sp)
    80000840:	ec4e                	sd	s3,24(sp)
    80000842:	e852                	sd	s4,16(sp)
    80000844:	e456                	sd	s5,8(sp)
    80000846:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000848:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000084c:	00011a17          	auipc	s4,0x11
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00008497          	auipc	s1,0x8
    80000858:	7b448493          	addi	s1,s1,1972 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00008997          	auipc	s3,0x8
    80000860:	7b498993          	addi	s3,s3,1972 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000864:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000868:	02077713          	andi	a4,a4,32
    8000086c:	c705                	beqz	a4,80000894 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086e:	01f7f713          	andi	a4,a5,31
    80000872:	9752                	add	a4,a4,s4
    80000874:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    80000878:	0785                	addi	a5,a5,1
    8000087a:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000087c:	8526                	mv	a0,s1
    8000087e:	00002097          	auipc	ra,0x2
    80000882:	244080e7          	jalr	580(ra) # 80002ac2 <wakeup>
    
    WriteReg(THR, c);
    80000886:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000088a:	609c                	ld	a5,0(s1)
    8000088c:	0009b703          	ld	a4,0(s3)
    80000890:	fcf71ae3          	bne	a4,a5,80000864 <uartstart+0x42>
  }
}
    80000894:	70e2                	ld	ra,56(sp)
    80000896:	7442                	ld	s0,48(sp)
    80000898:	74a2                	ld	s1,40(sp)
    8000089a:	7902                	ld	s2,32(sp)
    8000089c:	69e2                	ld	s3,24(sp)
    8000089e:	6a42                	ld	s4,16(sp)
    800008a0:	6aa2                	ld	s5,8(sp)
    800008a2:	6121                	addi	sp,sp,64
    800008a4:	8082                	ret
    800008a6:	8082                	ret

00000000800008a8 <uartputc>:
{
    800008a8:	7179                	addi	sp,sp,-48
    800008aa:	f406                	sd	ra,40(sp)
    800008ac:	f022                	sd	s0,32(sp)
    800008ae:	ec26                	sd	s1,24(sp)
    800008b0:	e84a                	sd	s2,16(sp)
    800008b2:	e44e                	sd	s3,8(sp)
    800008b4:	e052                	sd	s4,0(sp)
    800008b6:	1800                	addi	s0,sp,48
    800008b8:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ba:	00011517          	auipc	a0,0x11
    800008be:	98e50513          	addi	a0,a0,-1650 # 80011248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	310080e7          	jalr	784(ra) # 80000bd2 <acquire>
  if(panicked){
    800008ca:	00008797          	auipc	a5,0x8
    800008ce:	7367a783          	lw	a5,1846(a5) # 80009000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00008717          	auipc	a4,0x8
    800008da:	73a73703          	ld	a4,1850(a4) # 80009010 <uart_tx_w>
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	72a7b783          	ld	a5,1834(a5) # 80009008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00011997          	auipc	s3,0x11
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80011248 <uart_tx_lock>
    800008f6:	00008497          	auipc	s1,0x8
    800008fa:	71248493          	addi	s1,s1,1810 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00008917          	auipc	s2,0x8
    80000902:	71290913          	addi	s2,s2,1810 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	02c080e7          	jalr	44(ra) # 80002936 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00011497          	auipc	s1,0x11
    80000924:	92848493          	addi	s1,s1,-1752 # 80011248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00008797          	auipc	a5,0x8
    80000938:	6ce7be23          	sd	a4,1756(a5) # 80009010 <uart_tx_w>
      uartstart();
    8000093c:	00000097          	auipc	ra,0x0
    80000940:	ee6080e7          	jalr	-282(ra) # 80000822 <uartstart>
      release(&uart_tx_lock);
    80000944:	8526                	mv	a0,s1
    80000946:	00000097          	auipc	ra,0x0
    8000094a:	340080e7          	jalr	832(ra) # 80000c86 <release>
}
    8000094e:	70a2                	ld	ra,40(sp)
    80000950:	7402                	ld	s0,32(sp)
    80000952:	64e2                	ld	s1,24(sp)
    80000954:	6942                	ld	s2,16(sp)
    80000956:	69a2                	ld	s3,8(sp)
    80000958:	6a02                	ld	s4,0(sp)
    8000095a:	6145                	addi	sp,sp,48
    8000095c:	8082                	ret

000000008000095e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000095e:	1141                	addi	sp,sp,-16
    80000960:	e422                	sd	s0,8(sp)
    80000962:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000964:	100007b7          	lui	a5,0x10000
    80000968:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000096c:	8b85                	andi	a5,a5,1
    8000096e:	cb91                	beqz	a5,80000982 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000970:	100007b7          	lui	a5,0x10000
    80000974:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000978:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000097c:	6422                	ld	s0,8(sp)
    8000097e:	0141                	addi	sp,sp,16
    80000980:	8082                	ret
    return -1;
    80000982:	557d                	li	a0,-1
    80000984:	bfe5                	j	8000097c <uartgetc+0x1e>

0000000080000986 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000986:	1101                	addi	sp,sp,-32
    80000988:	ec06                	sd	ra,24(sp)
    8000098a:	e822                	sd	s0,16(sp)
    8000098c:	e426                	sd	s1,8(sp)
    8000098e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000990:	54fd                	li	s1,-1
    80000992:	a029                	j	8000099c <uartintr+0x16>
      break;
    consoleintr(c);
    80000994:	00000097          	auipc	ra,0x0
    80000998:	916080e7          	jalr	-1770(ra) # 800002aa <consoleintr>
    int c = uartgetc();
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	fc2080e7          	jalr	-62(ra) # 8000095e <uartgetc>
    if(c == -1)
    800009a4:	fe9518e3          	bne	a0,s1,80000994 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009a8:	00011497          	auipc	s1,0x11
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80011248 <uart_tx_lock>
    800009b0:	8526                	mv	a0,s1
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	220080e7          	jalr	544(ra) # 80000bd2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2c2080e7          	jalr	706(ra) # 80000c86 <release>
}
    800009cc:	60e2                	ld	ra,24(sp)
    800009ce:	6442                	ld	s0,16(sp)
    800009d0:	64a2                	ld	s1,8(sp)
    800009d2:	6105                	addi	sp,sp,32
    800009d4:	8082                	ret

00000000800009d6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009d6:	1101                	addi	sp,sp,-32
    800009d8:	ec06                	sd	ra,24(sp)
    800009da:	e822                	sd	s0,16(sp)
    800009dc:	e426                	sd	s1,8(sp)
    800009de:	e04a                	sd	s2,0(sp)
    800009e0:	1000                	addi	s0,sp,32
  struct run *r;

  if((char*)pa < end)
    800009e2:	0002d797          	auipc	a5,0x2d
    800009e6:	61e78793          	addi	a5,a5,1566 # 8002e000 <end>
    800009ea:	04f56963          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009ee:	84aa                	mv	s1,a0
    panic("kfree here");
  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f0:	03451793          	slli	a5,a0,0x34
    800009f4:	efa1                	bnez	a5,80000a4c <kfree+0x76>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57963          	bgeu	a0,a5,80000a4c <kfree+0x76>
    panic("kfree hello");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2cc080e7          	jalr	716(ra) # 80000cce <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1be080e7          	jalr	446(ra) # 80000bd2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	25e080e7          	jalr	606(ra) # 80000c86 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree here");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>
    panic("kfree hello");
    80000a4c:	00007517          	auipc	a0,0x7
    80000a50:	62450513          	addi	a0,a0,1572 # 80008070 <digits+0x30>
    80000a54:	00000097          	auipc	ra,0x0
    80000a58:	ad6080e7          	jalr	-1322(ra) # 8000052a <panic>

0000000080000a5c <freerange>:
{
    80000a5c:	7179                	addi	sp,sp,-48
    80000a5e:	f406                	sd	ra,40(sp)
    80000a60:	f022                	sd	s0,32(sp)
    80000a62:	ec26                	sd	s1,24(sp)
    80000a64:	e84a                	sd	s2,16(sp)
    80000a66:	e44e                	sd	s3,8(sp)
    80000a68:	e052                	sd	s4,0(sp)
    80000a6a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6c:	6785                	lui	a5,0x1
    80000a6e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a72:	94aa                	add	s1,s1,a0
    80000a74:	757d                	lui	a0,0xfffff
    80000a76:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a78:	94be                	add	s1,s1,a5
    80000a7a:	0095ee63          	bltu	a1,s1,80000a96 <freerange+0x3a>
    80000a7e:	892e                	mv	s2,a1
    kfree(p);
    80000a80:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a82:	6985                	lui	s3,0x1
    kfree(p);
    80000a84:	01448533          	add	a0,s1,s4
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	f4e080e7          	jalr	-178(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94ce                	add	s1,s1,s3
    80000a92:	fe9979e3          	bgeu	s2,s1,80000a84 <freerange+0x28>
}
    80000a96:	70a2                	ld	ra,40(sp)
    80000a98:	7402                	ld	s0,32(sp)
    80000a9a:	64e2                	ld	s1,24(sp)
    80000a9c:	6942                	ld	s2,16(sp)
    80000a9e:	69a2                	ld	s3,8(sp)
    80000aa0:	6a02                	ld	s4,0(sp)
    80000aa2:	6145                	addi	sp,sp,48
    80000aa4:	8082                	ret

0000000080000aa6 <kinit>:
{
    80000aa6:	1141                	addi	sp,sp,-16
    80000aa8:	e406                	sd	ra,8(sp)
    80000aaa:	e022                	sd	s0,0(sp)
    80000aac:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aae:	00007597          	auipc	a1,0x7
    80000ab2:	5d258593          	addi	a1,a1,1490 # 80008080 <digits+0x40>
    80000ab6:	00010517          	auipc	a0,0x10
    80000aba:	7ca50513          	addi	a0,a0,1994 # 80011280 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	0002d517          	auipc	a0,0x2d
    80000ace:	53650513          	addi	a0,a0,1334 # 8002e000 <end>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	f8a080e7          	jalr	-118(ra) # 80000a5c <freerange>
}
    80000ada:	60a2                	ld	ra,8(sp)
    80000adc:	6402                	ld	s0,0(sp)
    80000ade:	0141                	addi	sp,sp,16
    80000ae0:	8082                	ret

0000000080000ae2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae2:	1101                	addi	sp,sp,-32
    80000ae4:	ec06                	sd	ra,24(sp)
    80000ae6:	e822                	sd	s0,16(sp)
    80000ae8:	e426                	sd	s1,8(sp)
    80000aea:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000aec:	00010497          	auipc	s1,0x10
    80000af0:	79448493          	addi	s1,s1,1940 # 80011280 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	77c50513          	addi	a0,a0,1916 # 80011280 <kmem>
    80000b0c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	178080e7          	jalr	376(ra) # 80000c86 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b16:	6605                	lui	a2,0x1
    80000b18:	4595                	li	a1,5
    80000b1a:	8526                	mv	a0,s1
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	1b2080e7          	jalr	434(ra) # 80000cce <memset>
  return (void*)r;
}
    80000b24:	8526                	mv	a0,s1
    80000b26:	60e2                	ld	ra,24(sp)
    80000b28:	6442                	ld	s0,16(sp)
    80000b2a:	64a2                	ld	s1,8(sp)
    80000b2c:	6105                	addi	sp,sp,32
    80000b2e:	8082                	ret
  release(&kmem.lock);
    80000b30:	00010517          	auipc	a0,0x10
    80000b34:	75050513          	addi	a0,a0,1872 # 80011280 <kmem>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	14e080e7          	jalr	334(ra) # 80000c86 <release>
  if(r)
    80000b40:	b7d5                	j	80000b24 <kalloc+0x42>

0000000080000b42 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b42:	1141                	addi	sp,sp,-16
    80000b44:	e422                	sd	s0,8(sp)
    80000b46:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b48:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b4e:	00053823          	sd	zero,16(a0)
}
    80000b52:	6422                	ld	s0,8(sp)
    80000b54:	0141                	addi	sp,sp,16
    80000b56:	8082                	ret

0000000080000b58 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b58:	411c                	lw	a5,0(a0)
    80000b5a:	e399                	bnez	a5,80000b60 <holding+0x8>
    80000b5c:	4501                	li	a0,0
  return r;
}
    80000b5e:	8082                	ret
{
    80000b60:	1101                	addi	sp,sp,-32
    80000b62:	ec06                	sd	ra,24(sp)
    80000b64:	e822                	sd	s0,16(sp)
    80000b66:	e426                	sd	s1,8(sp)
    80000b68:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	6904                	ld	s1,16(a0)
    80000b6c:	00001097          	auipc	ra,0x1
    80000b70:	4f0080e7          	jalr	1264(ra) # 8000205c <mycpu>
    80000b74:	40a48533          	sub	a0,s1,a0
    80000b78:	00153513          	seqz	a0,a0
}
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret

0000000080000b86 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b86:	1101                	addi	sp,sp,-32
    80000b88:	ec06                	sd	ra,24(sp)
    80000b8a:	e822                	sd	s0,16(sp)
    80000b8c:	e426                	sd	s1,8(sp)
    80000b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b90:	100024f3          	csrr	s1,sstatus
    80000b94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b98:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b9e:	00001097          	auipc	ra,0x1
    80000ba2:	4be080e7          	jalr	1214(ra) # 8000205c <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	4b2080e7          	jalr	1202(ra) # 8000205c <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	49a080e7          	jalr	1178(ra) # 8000205c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bca:	8085                	srli	s1,s1,0x1
    80000bcc:	8885                	andi	s1,s1,1
    80000bce:	dd64                	sw	s1,124(a0)
    80000bd0:	bfe9                	j	80000baa <push_off+0x24>

0000000080000bd2 <acquire>:
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
    80000bdc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bde:	00000097          	auipc	ra,0x0
    80000be2:	fa8080e7          	jalr	-88(ra) # 80000b86 <push_off>
  if(holding(lk))
    80000be6:	8526                	mv	a0,s1
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f70080e7          	jalr	-144(ra) # 80000b58 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf0:	4705                	li	a4,1
  if(holding(lk))
    80000bf2:	e115                	bnez	a0,80000c16 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	87ba                	mv	a5,a4
    80000bf6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfa:	2781                	sext.w	a5,a5
    80000bfc:	ffe5                	bnez	a5,80000bf4 <acquire+0x22>
  __sync_synchronize();
    80000bfe:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c02:	00001097          	auipc	ra,0x1
    80000c06:	45a080e7          	jalr	1114(ra) # 8000205c <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00007517          	auipc	a0,0x7
    80000c1a:	47250513          	addi	a0,a0,1138 # 80008088 <digits+0x48>
    80000c1e:	00000097          	auipc	ra,0x0
    80000c22:	90c080e7          	jalr	-1780(ra) # 8000052a <panic>

0000000080000c26 <pop_off>:

void
pop_off(void)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e406                	sd	ra,8(sp)
    80000c2a:	e022                	sd	s0,0(sp)
    80000c2c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	42e080e7          	jalr	1070(ra) # 8000205c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c36:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c3c:	e78d                	bnez	a5,80000c66 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c3e:	5d3c                	lw	a5,120(a0)
    80000c40:	02f05b63          	blez	a5,80000c76 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c44:	37fd                	addiw	a5,a5,-1
    80000c46:	0007871b          	sext.w	a4,a5
    80000c4a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c4c:	eb09                	bnez	a4,80000c5e <pop_off+0x38>
    80000c4e:	5d7c                	lw	a5,124(a0)
    80000c50:	c799                	beqz	a5,80000c5e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c52:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c56:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c5e:	60a2                	ld	ra,8(sp)
    80000c60:	6402                	ld	s0,0(sp)
    80000c62:	0141                	addi	sp,sp,16
    80000c64:	8082                	ret
    panic("pop_off - interruptible");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>
    panic("pop_off");
    80000c76:	00007517          	auipc	a0,0x7
    80000c7a:	43250513          	addi	a0,a0,1074 # 800080a8 <digits+0x68>
    80000c7e:	00000097          	auipc	ra,0x0
    80000c82:	8ac080e7          	jalr	-1876(ra) # 8000052a <panic>

0000000080000c86 <release>:
{
    80000c86:	1101                	addi	sp,sp,-32
    80000c88:	ec06                	sd	ra,24(sp)
    80000c8a:	e822                	sd	s0,16(sp)
    80000c8c:	e426                	sd	s1,8(sp)
    80000c8e:	1000                	addi	s0,sp,32
    80000c90:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	ec6080e7          	jalr	-314(ra) # 80000b58 <holding>
    80000c9a:	c115                	beqz	a0,80000cbe <release+0x38>
  lk->cpu = 0;
    80000c9c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca0:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca4:	0f50000f          	fence	iorw,ow
    80000ca8:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	f7a080e7          	jalr	-134(ra) # 80000c26 <pop_off>
}
    80000cb4:	60e2                	ld	ra,24(sp)
    80000cb6:	6442                	ld	s0,16(sp)
    80000cb8:	64a2                	ld	s1,8(sp)
    80000cba:	6105                	addi	sp,sp,32
    80000cbc:	8082                	ret
    panic("release");
    80000cbe:	00007517          	auipc	a0,0x7
    80000cc2:	3f250513          	addi	a0,a0,1010 # 800080b0 <digits+0x70>
    80000cc6:	00000097          	auipc	ra,0x0
    80000cca:	864080e7          	jalr	-1948(ra) # 8000052a <panic>

0000000080000cce <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cce:	1141                	addi	sp,sp,-16
    80000cd0:	e422                	sd	s0,8(sp)
    80000cd2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd4:	ca19                	beqz	a2,80000cea <memset+0x1c>
    80000cd6:	87aa                	mv	a5,a0
    80000cd8:	1602                	slli	a2,a2,0x20
    80000cda:	9201                	srli	a2,a2,0x20
    80000cdc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce4:	0785                	addi	a5,a5,1
    80000ce6:	fee79de3          	bne	a5,a4,80000ce0 <memset+0x12>
  }
  return dst;
}
    80000cea:	6422                	ld	s0,8(sp)
    80000cec:	0141                	addi	sp,sp,16
    80000cee:	8082                	ret

0000000080000cf0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cf6:	ca05                	beqz	a2,80000d26 <memcmp+0x36>
    80000cf8:	fff6069b          	addiw	a3,a2,-1
    80000cfc:	1682                	slli	a3,a3,0x20
    80000cfe:	9281                	srli	a3,a3,0x20
    80000d00:	0685                	addi	a3,a3,1
    80000d02:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d04:	00054783          	lbu	a5,0(a0)
    80000d08:	0005c703          	lbu	a4,0(a1)
    80000d0c:	00e79863          	bne	a5,a4,80000d1c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d10:	0505                	addi	a0,a0,1
    80000d12:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d14:	fed518e3          	bne	a0,a3,80000d04 <memcmp+0x14>
  }

  return 0;
    80000d18:	4501                	li	a0,0
    80000d1a:	a019                	j	80000d20 <memcmp+0x30>
      return *s1 - *s2;
    80000d1c:	40e7853b          	subw	a0,a5,a4
}
    80000d20:	6422                	ld	s0,8(sp)
    80000d22:	0141                	addi	sp,sp,16
    80000d24:	8082                	ret
  return 0;
    80000d26:	4501                	li	a0,0
    80000d28:	bfe5                	j	80000d20 <memcmp+0x30>

0000000080000d2a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e422                	sd	s0,8(sp)
    80000d2e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d30:	02a5e563          	bltu	a1,a0,80000d5a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d34:	fff6069b          	addiw	a3,a2,-1
    80000d38:	ce11                	beqz	a2,80000d54 <memmove+0x2a>
    80000d3a:	1682                	slli	a3,a3,0x20
    80000d3c:	9281                	srli	a3,a3,0x20
    80000d3e:	0685                	addi	a3,a3,1
    80000d40:	96ae                	add	a3,a3,a1
    80000d42:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0785                	addi	a5,a5,1
    80000d48:	fff5c703          	lbu	a4,-1(a1)
    80000d4c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d50:	fed59ae3          	bne	a1,a3,80000d44 <memmove+0x1a>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061713          	slli	a4,a2,0x20
    80000d5e:	9301                	srli	a4,a4,0x20
    80000d60:	00e587b3          	add	a5,a1,a4
    80000d64:	fcf578e3          	bgeu	a0,a5,80000d34 <memmove+0xa>
    d += n;
    80000d68:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d6a:	fff6069b          	addiw	a3,a2,-1
    80000d6e:	d27d                	beqz	a2,80000d54 <memmove+0x2a>
    80000d70:	02069613          	slli	a2,a3,0x20
    80000d74:	9201                	srli	a2,a2,0x20
    80000d76:	fff64613          	not	a2,a2
    80000d7a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d7c:	17fd                	addi	a5,a5,-1
    80000d7e:	177d                	addi	a4,a4,-1
    80000d80:	0007c683          	lbu	a3,0(a5)
    80000d84:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d88:	fef61ae3          	bne	a2,a5,80000d7c <memmove+0x52>
    80000d8c:	b7e1                	j	80000d54 <memmove+0x2a>

0000000080000d8e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8e:	1141                	addi	sp,sp,-16
    80000d90:	e406                	sd	ra,8(sp)
    80000d92:	e022                	sd	s0,0(sp)
    80000d94:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d96:	00000097          	auipc	ra,0x0
    80000d9a:	f94080e7          	jalr	-108(ra) # 80000d2a <memmove>
}
    80000d9e:	60a2                	ld	ra,8(sp)
    80000da0:	6402                	ld	s0,0(sp)
    80000da2:	0141                	addi	sp,sp,16
    80000da4:	8082                	ret

0000000080000da6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e422                	sd	s0,8(sp)
    80000daa:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dac:	ce11                	beqz	a2,80000dc8 <strncmp+0x22>
    80000dae:	00054783          	lbu	a5,0(a0)
    80000db2:	cf89                	beqz	a5,80000dcc <strncmp+0x26>
    80000db4:	0005c703          	lbu	a4,0(a1)
    80000db8:	00f71a63          	bne	a4,a5,80000dcc <strncmp+0x26>
    n--, p++, q++;
    80000dbc:	367d                	addiw	a2,a2,-1
    80000dbe:	0505                	addi	a0,a0,1
    80000dc0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dc2:	f675                	bnez	a2,80000dae <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc4:	4501                	li	a0,0
    80000dc6:	a809                	j	80000dd8 <strncmp+0x32>
    80000dc8:	4501                	li	a0,0
    80000dca:	a039                	j	80000dd8 <strncmp+0x32>
  if(n == 0)
    80000dcc:	ca09                	beqz	a2,80000dde <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dce:	00054503          	lbu	a0,0(a0)
    80000dd2:	0005c783          	lbu	a5,0(a1)
    80000dd6:	9d1d                	subw	a0,a0,a5
}
    80000dd8:	6422                	ld	s0,8(sp)
    80000dda:	0141                	addi	sp,sp,16
    80000ddc:	8082                	ret
    return 0;
    80000dde:	4501                	li	a0,0
    80000de0:	bfe5                	j	80000dd8 <strncmp+0x32>

0000000080000de2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000de2:	1141                	addi	sp,sp,-16
    80000de4:	e422                	sd	s0,8(sp)
    80000de6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de8:	872a                	mv	a4,a0
    80000dea:	8832                	mv	a6,a2
    80000dec:	367d                	addiw	a2,a2,-1
    80000dee:	01005963          	blez	a6,80000e00 <strncpy+0x1e>
    80000df2:	0705                	addi	a4,a4,1
    80000df4:	0005c783          	lbu	a5,0(a1)
    80000df8:	fef70fa3          	sb	a5,-1(a4)
    80000dfc:	0585                	addi	a1,a1,1
    80000dfe:	f7f5                	bnez	a5,80000dea <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e00:	86ba                	mv	a3,a4
    80000e02:	00c05c63          	blez	a2,80000e1a <strncpy+0x38>
    *s++ = 0;
    80000e06:	0685                	addi	a3,a3,1
    80000e08:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e0c:	fff6c793          	not	a5,a3
    80000e10:	9fb9                	addw	a5,a5,a4
    80000e12:	010787bb          	addw	a5,a5,a6
    80000e16:	fef048e3          	bgtz	a5,80000e06 <strncpy+0x24>
  return os;
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret

0000000080000e20 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e20:	1141                	addi	sp,sp,-16
    80000e22:	e422                	sd	s0,8(sp)
    80000e24:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e26:	02c05363          	blez	a2,80000e4c <safestrcpy+0x2c>
    80000e2a:	fff6069b          	addiw	a3,a2,-1
    80000e2e:	1682                	slli	a3,a3,0x20
    80000e30:	9281                	srli	a3,a3,0x20
    80000e32:	96ae                	add	a3,a3,a1
    80000e34:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e36:	00d58963          	beq	a1,a3,80000e48 <safestrcpy+0x28>
    80000e3a:	0585                	addi	a1,a1,1
    80000e3c:	0785                	addi	a5,a5,1
    80000e3e:	fff5c703          	lbu	a4,-1(a1)
    80000e42:	fee78fa3          	sb	a4,-1(a5)
    80000e46:	fb65                	bnez	a4,80000e36 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e48:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e4c:	6422                	ld	s0,8(sp)
    80000e4e:	0141                	addi	sp,sp,16
    80000e50:	8082                	ret

0000000080000e52 <strlen>:

int
strlen(const char *s)
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e422                	sd	s0,8(sp)
    80000e56:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e58:	00054783          	lbu	a5,0(a0)
    80000e5c:	cf91                	beqz	a5,80000e78 <strlen+0x26>
    80000e5e:	0505                	addi	a0,a0,1
    80000e60:	87aa                	mv	a5,a0
    80000e62:	4685                	li	a3,1
    80000e64:	9e89                	subw	a3,a3,a0
    80000e66:	00f6853b          	addw	a0,a3,a5
    80000e6a:	0785                	addi	a5,a5,1
    80000e6c:	fff7c703          	lbu	a4,-1(a5)
    80000e70:	fb7d                	bnez	a4,80000e66 <strlen+0x14>
    ;
  return n;
}
    80000e72:	6422                	ld	s0,8(sp)
    80000e74:	0141                	addi	sp,sp,16
    80000e76:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e78:	4501                	li	a0,0
    80000e7a:	bfe5                	j	80000e72 <strlen+0x20>

0000000080000e7c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e7c:	1141                	addi	sp,sp,-16
    80000e7e:	e406                	sd	ra,8(sp)
    80000e80:	e022                	sd	s0,0(sp)
    80000e82:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e84:	00001097          	auipc	ra,0x1
    80000e88:	1c8080e7          	jalr	456(ra) # 8000204c <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e8c:	00008717          	auipc	a4,0x8
    80000e90:	18c70713          	addi	a4,a4,396 # 80009018 <started>
  if(cpuid() == 0){
    80000e94:	c139                	beqz	a0,80000eda <main+0x5e>
    while(started == 0)
    80000e96:	431c                	lw	a5,0(a4)
    80000e98:	2781                	sext.w	a5,a5
    80000e9a:	dff5                	beqz	a5,80000e96 <main+0x1a>
      ;
    __sync_synchronize();
    80000e9c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea0:	00001097          	auipc	ra,0x1
    80000ea4:	1ac080e7          	jalr	428(ra) # 8000204c <cpuid>
    80000ea8:	85aa                	mv	a1,a0
    80000eaa:	00007517          	auipc	a0,0x7
    80000eae:	22650513          	addi	a0,a0,550 # 800080d0 <digits+0x90>
    80000eb2:	fffff097          	auipc	ra,0xfffff
    80000eb6:	6c2080e7          	jalr	1730(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eba:	00000097          	auipc	ra,0x0
    80000ebe:	0d8080e7          	jalr	216(ra) # 80000f92 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ec2:	00002097          	auipc	ra,0x2
    80000ec6:	01c080e7          	jalr	28(ra) # 80002ede <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eca:	00006097          	auipc	ra,0x6
    80000ece:	ac6080e7          	jalr	-1338(ra) # 80006990 <plicinithart>
  }

  scheduler();        
    80000ed2:	00002097          	auipc	ra,0x2
    80000ed6:	8aa080e7          	jalr	-1878(ra) # 8000277c <scheduler>
    consoleinit();
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	562080e7          	jalr	1378(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	872080e7          	jalr	-1934(ra) # 80000754 <printfinit>
    printf("\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1f650513          	addi	a0,a0,502 # 800080e0 <digits+0xa0>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1be50513          	addi	a0,a0,446 # 800080b8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    printf("\n");
    80000f0a:	00007517          	auipc	a0,0x7
    80000f0e:	1d650513          	addi	a0,a0,470 # 800080e0 <digits+0xa0>
    80000f12:	fffff097          	auipc	ra,0xfffff
    80000f16:	662080e7          	jalr	1634(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	b8c080e7          	jalr	-1140(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	310080e7          	jalr	784(ra) # 80001232 <kvminit>
    kvminithart();   // turn on paging
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	068080e7          	jalr	104(ra) # 80000f92 <kvminithart>
    procinit();      // process table
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	06a080e7          	jalr	106(ra) # 80001f9c <procinit>
    trapinit();      // trap vectors
    80000f3a:	00002097          	auipc	ra,0x2
    80000f3e:	f7c080e7          	jalr	-132(ra) # 80002eb6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	f9c080e7          	jalr	-100(ra) # 80002ede <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4a:	00006097          	auipc	ra,0x6
    80000f4e:	a30080e7          	jalr	-1488(ra) # 8000697a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f52:	00006097          	auipc	ra,0x6
    80000f56:	a3e080e7          	jalr	-1474(ra) # 80006990 <plicinithart>
    binit();         // buffer cache
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	6e2080e7          	jalr	1762(ra) # 8000363c <binit>
    iinit();         // inode cache
    80000f62:	00003097          	auipc	ra,0x3
    80000f66:	d74080e7          	jalr	-652(ra) # 80003cd6 <iinit>
    fileinit();      // file table
    80000f6a:	00004097          	auipc	ra,0x4
    80000f6e:	034080e7          	jalr	52(ra) # 80004f9e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	b40080e7          	jalr	-1216(ra) # 80006ab2 <virtio_disk_init>
    userinit();      // first user process
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	416080e7          	jalr	1046(ra) # 80002390 <userinit>
    __sync_synchronize();
    80000f82:	0ff0000f          	fence
    started = 1;
    80000f86:	4785                	li	a5,1
    80000f88:	00008717          	auipc	a4,0x8
    80000f8c:	08f72823          	sw	a5,144(a4) # 80009018 <started>
    80000f90:	b789                	j	80000ed2 <main+0x56>

0000000080000f92 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f92:	1141                	addi	sp,sp,-16
    80000f94:	e422                	sd	s0,8(sp)
    80000f96:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	0887b783          	ld	a5,136(a5) # 80009020 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	10c50513          	addi	a0,a0,268 # 800080e8 <digits+0xa8>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	546080e7          	jalr	1350(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af2080e7          	jalr	-1294(ra) # 80000ae2 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cce080e7          	jalr	-818(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
    800010b4:	8aaa                	mv	s5,a0
    800010b6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010b8:	777d                	lui	a4,0xfffff
    800010ba:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010be:	167d                	addi	a2,a2,-1
    800010c0:	00b609b3          	add	s3,a2,a1
    800010c4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010c8:	893e                	mv	s2,a5
    800010ca:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ce:	6b85                	lui	s7,0x1
    800010d0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d4:	4605                	li	a2,1
    800010d6:	85ca                	mv	a1,s2
    800010d8:	8556                	mv	a0,s5
    800010da:	00000097          	auipc	ra,0x0
    800010de:	edc080e7          	jalr	-292(ra) # 80000fb6 <walk>
    800010e2:	c51d                	beqz	a0,80001110 <mappages+0x72>
    if(*pte & PTE_V)
    800010e4:	611c                	ld	a5,0(a0)
    800010e6:	8b85                	andi	a5,a5,1
    800010e8:	ef81                	bnez	a5,80001100 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ea:	80b1                	srli	s1,s1,0xc
    800010ec:	04aa                	slli	s1,s1,0xa
    800010ee:	0164e4b3          	or	s1,s1,s6
    800010f2:	0014e493          	ori	s1,s1,1
    800010f6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010f8:	03390863          	beq	s2,s3,80001128 <mappages+0x8a>
    a += PGSIZE;
    800010fc:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010fe:	bfc9                	j	800010d0 <mappages+0x32>
      panic("remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	ff050513          	addi	a0,a0,-16 # 800080f0 <digits+0xb0>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	422080e7          	jalr	1058(ra) # 8000052a <panic>
      return -1;
    80001110:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001112:	60a6                	ld	ra,72(sp)
    80001114:	6406                	ld	s0,64(sp)
    80001116:	74e2                	ld	s1,56(sp)
    80001118:	7942                	ld	s2,48(sp)
    8000111a:	79a2                	ld	s3,40(sp)
    8000111c:	7a02                	ld	s4,32(sp)
    8000111e:	6ae2                	ld	s5,24(sp)
    80001120:	6b42                	ld	s6,16(sp)
    80001122:	6ba2                	ld	s7,8(sp)
    80001124:	6161                	addi	sp,sp,80
    80001126:	8082                	ret
  return 0;
    80001128:	4501                	li	a0,0
    8000112a:	b7e5                	j	80001112 <mappages+0x74>

000000008000112c <kvmmap>:
{
    8000112c:	1141                	addi	sp,sp,-16
    8000112e:	e406                	sd	ra,8(sp)
    80001130:	e022                	sd	s0,0(sp)
    80001132:	0800                	addi	s0,sp,16
    80001134:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001136:	86b2                	mv	a3,a2
    80001138:	863e                	mv	a2,a5
    8000113a:	00000097          	auipc	ra,0x0
    8000113e:	f64080e7          	jalr	-156(ra) # 8000109e <mappages>
    80001142:	e509                	bnez	a0,8000114c <kvmmap+0x20>
}
    80001144:	60a2                	ld	ra,8(sp)
    80001146:	6402                	ld	s0,0(sp)
    80001148:	0141                	addi	sp,sp,16
    8000114a:	8082                	ret
    panic("kvmmap");
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	fac50513          	addi	a0,a0,-84 # 800080f8 <digits+0xb8>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3d6080e7          	jalr	982(ra) # 8000052a <panic>

000000008000115c <kvmmake>:
{
    8000115c:	1101                	addi	sp,sp,-32
    8000115e:	ec06                	sd	ra,24(sp)
    80001160:	e822                	sd	s0,16(sp)
    80001162:	e426                	sd	s1,8(sp)
    80001164:	e04a                	sd	s2,0(sp)
    80001166:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	97a080e7          	jalr	-1670(ra) # 80000ae2 <kalloc>
    80001170:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001172:	6605                	lui	a2,0x1
    80001174:	4581                	li	a1,0
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	b58080e7          	jalr	-1192(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000117e:	4719                	li	a4,6
    80001180:	6685                	lui	a3,0x1
    80001182:	10000637          	lui	a2,0x10000
    80001186:	100005b7          	lui	a1,0x10000
    8000118a:	8526                	mv	a0,s1
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	fa0080e7          	jalr	-96(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001194:	4719                	li	a4,6
    80001196:	6685                	lui	a3,0x1
    80001198:	10001637          	lui	a2,0x10001
    8000119c:	100015b7          	lui	a1,0x10001
    800011a0:	8526                	mv	a0,s1
    800011a2:	00000097          	auipc	ra,0x0
    800011a6:	f8a080e7          	jalr	-118(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011aa:	4719                	li	a4,6
    800011ac:	004006b7          	lui	a3,0x400
    800011b0:	0c000637          	lui	a2,0xc000
    800011b4:	0c0005b7          	lui	a1,0xc000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	f72080e7          	jalr	-142(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011c2:	00007917          	auipc	s2,0x7
    800011c6:	e3e90913          	addi	s2,s2,-450 # 80008000 <etext>
    800011ca:	4729                	li	a4,10
    800011cc:	80007697          	auipc	a3,0x80007
    800011d0:	e3468693          	addi	a3,a3,-460 # 8000 <_entry-0x7fff8000>
    800011d4:	4605                	li	a2,1
    800011d6:	067e                	slli	a2,a2,0x1f
    800011d8:	85b2                	mv	a1,a2
    800011da:	8526                	mv	a0,s1
    800011dc:	00000097          	auipc	ra,0x0
    800011e0:	f50080e7          	jalr	-176(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011e4:	4719                	li	a4,6
    800011e6:	46c5                	li	a3,17
    800011e8:	06ee                	slli	a3,a3,0x1b
    800011ea:	412686b3          	sub	a3,a3,s2
    800011ee:	864a                	mv	a2,s2
    800011f0:	85ca                	mv	a1,s2
    800011f2:	8526                	mv	a0,s1
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	f38080e7          	jalr	-200(ra) # 8000112c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011fc:	4729                	li	a4,10
    800011fe:	6685                	lui	a3,0x1
    80001200:	00006617          	auipc	a2,0x6
    80001204:	e0060613          	addi	a2,a2,-512 # 80007000 <_trampoline>
    80001208:	040005b7          	lui	a1,0x4000
    8000120c:	15fd                	addi	a1,a1,-1
    8000120e:	05b2                	slli	a1,a1,0xc
    80001210:	8526                	mv	a0,s1
    80001212:	00000097          	auipc	ra,0x0
    80001216:	f1a080e7          	jalr	-230(ra) # 8000112c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000121a:	8526                	mv	a0,s1
    8000121c:	00001097          	auipc	ra,0x1
    80001220:	cea080e7          	jalr	-790(ra) # 80001f06 <proc_mapstacks>
}
    80001224:	8526                	mv	a0,s1
    80001226:	60e2                	ld	ra,24(sp)
    80001228:	6442                	ld	s0,16(sp)
    8000122a:	64a2                	ld	s1,8(sp)
    8000122c:	6902                	ld	s2,0(sp)
    8000122e:	6105                	addi	sp,sp,32
    80001230:	8082                	ret

0000000080001232 <kvminit>:
{
    80001232:	1141                	addi	sp,sp,-16
    80001234:	e406                	sd	ra,8(sp)
    80001236:	e022                	sd	s0,0(sp)
    80001238:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000123a:	00000097          	auipc	ra,0x0
    8000123e:	f22080e7          	jalr	-222(ra) # 8000115c <kvmmake>
    80001242:	00008797          	auipc	a5,0x8
    80001246:	dca7bf23          	sd	a0,-546(a5) # 80009020 <kernel_pagetable>
}
    8000124a:	60a2                	ld	ra,8(sp)
    8000124c:	6402                	ld	s0,0(sp)
    8000124e:	0141                	addi	sp,sp,16
    80001250:	8082                	ret

0000000080001252 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001252:	715d                	addi	sp,sp,-80
    80001254:	e486                	sd	ra,72(sp)
    80001256:	e0a2                	sd	s0,64(sp)
    80001258:	fc26                	sd	s1,56(sp)
    8000125a:	f84a                	sd	s2,48(sp)
    8000125c:	f44e                	sd	s3,40(sp)
    8000125e:	f052                	sd	s4,32(sp)
    80001260:	ec56                	sd	s5,24(sp)
    80001262:	e85a                	sd	s6,16(sp)
    80001264:	e45e                	sd	s7,8(sp)
    80001266:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001268:	03459793          	slli	a5,a1,0x34
    8000126c:	e795                	bnez	a5,80001298 <uvmunmap+0x46>
    8000126e:	8a2a                	mv	s4,a0
    80001270:	892e                	mv	s2,a1
    80001272:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001274:	0632                	slli	a2,a2,0xc
    80001276:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000127a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	6b05                	lui	s6,0x1
    8000127e:	0735e263          	bltu	a1,s3,800012e2 <uvmunmap+0x90>
      }
      *pte = 0;
    }
  }*/
  }
}
    80001282:	60a6                	ld	ra,72(sp)
    80001284:	6406                	ld	s0,64(sp)
    80001286:	74e2                	ld	s1,56(sp)
    80001288:	7942                	ld	s2,48(sp)
    8000128a:	79a2                	ld	s3,40(sp)
    8000128c:	7a02                	ld	s4,32(sp)
    8000128e:	6ae2                	ld	s5,24(sp)
    80001290:	6b42                	ld	s6,16(sp)
    80001292:	6ba2                	ld	s7,8(sp)
    80001294:	6161                	addi	sp,sp,80
    80001296:	8082                	ret
    panic("uvmunmap: not aligned");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e7050513          	addi	a0,a0,-400 # 80008118 <digits+0xd8>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012c8:	00007517          	auipc	a0,0x7
    800012cc:	e7850513          	addi	a0,a0,-392 # 80008140 <digits+0x100>
    800012d0:	fffff097          	auipc	ra,0xfffff
    800012d4:	25a080e7          	jalr	602(ra) # 8000052a <panic>
    *pte = 0;
    800012d8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012dc:	995a                	add	s2,s2,s6
    800012de:	fb3972e3          	bgeu	s2,s3,80001282 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012e2:	4601                	li	a2,0
    800012e4:	85ca                	mv	a1,s2
    800012e6:	8552                	mv	a0,s4
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	cce080e7          	jalr	-818(ra) # 80000fb6 <walk>
    800012f0:	84aa                	mv	s1,a0
    800012f2:	d95d                	beqz	a0,800012a8 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012f4:	6108                	ld	a0,0(a0)
    800012f6:	00157793          	andi	a5,a0,1
    800012fa:	dfdd                	beqz	a5,800012b8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fc:	3ff57793          	andi	a5,a0,1023
    80001300:	fd7784e3          	beq	a5,s7,800012c8 <uvmunmap+0x76>
    if(do_free){
    80001304:	fc0a8ae3          	beqz	s5,800012d8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001308:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000130a:	0532                	slli	a0,a0,0xc
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	6ca080e7          	jalr	1738(ra) # 800009d6 <kfree>
    80001314:	b7d1                	j	800012d8 <uvmunmap+0x86>

0000000080001316 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001316:	1101                	addi	sp,sp,-32
    80001318:	ec06                	sd	ra,24(sp)
    8000131a:	e822                	sd	s0,16(sp)
    8000131c:	e426                	sd	s1,8(sp)
    8000131e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001320:	fffff097          	auipc	ra,0xfffff
    80001324:	7c2080e7          	jalr	1986(ra) # 80000ae2 <kalloc>
    80001328:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000132a:	c519                	beqz	a0,80001338 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000132c:	6605                	lui	a2,0x1
    8000132e:	4581                	li	a1,0
    80001330:	00000097          	auipc	ra,0x0
    80001334:	99e080e7          	jalr	-1634(ra) # 80000cce <memset>
  return pagetable;
}
    80001338:	8526                	mv	a0,s1
    8000133a:	60e2                	ld	ra,24(sp)
    8000133c:	6442                	ld	s0,16(sp)
    8000133e:	64a2                	ld	s1,8(sp)
    80001340:	6105                	addi	sp,sp,32
    80001342:	8082                	ret

0000000080001344 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001344:	7179                	addi	sp,sp,-48
    80001346:	f406                	sd	ra,40(sp)
    80001348:	f022                	sd	s0,32(sp)
    8000134a:	ec26                	sd	s1,24(sp)
    8000134c:	e84a                	sd	s2,16(sp)
    8000134e:	e44e                	sd	s3,8(sp)
    80001350:	e052                	sd	s4,0(sp)
    80001352:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001354:	6785                	lui	a5,0x1
    80001356:	04f67863          	bgeu	a2,a5,800013a6 <uvminit+0x62>
    8000135a:	8a2a                	mv	s4,a0
    8000135c:	89ae                	mv	s3,a1
    8000135e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	782080e7          	jalr	1922(ra) # 80000ae2 <kalloc>
    80001368:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	960080e7          	jalr	-1696(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001376:	4779                	li	a4,30
    80001378:	86ca                	mv	a3,s2
    8000137a:	6605                	lui	a2,0x1
    8000137c:	4581                	li	a1,0
    8000137e:	8552                	mv	a0,s4
    80001380:	00000097          	auipc	ra,0x0
    80001384:	d1e080e7          	jalr	-738(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    80001388:	8626                	mv	a2,s1
    8000138a:	85ce                	mv	a1,s3
    8000138c:	854a                	mv	a0,s2
    8000138e:	00000097          	auipc	ra,0x0
    80001392:	99c080e7          	jalr	-1636(ra) # 80000d2a <memmove>
}
    80001396:	70a2                	ld	ra,40(sp)
    80001398:	7402                	ld	s0,32(sp)
    8000139a:	64e2                	ld	s1,24(sp)
    8000139c:	6942                	ld	s2,16(sp)
    8000139e:	69a2                	ld	s3,8(sp)
    800013a0:	6a02                	ld	s4,0(sp)
    800013a2:	6145                	addi	sp,sp,48
    800013a4:	8082                	ret
    panic("inituvm: more than a page");
    800013a6:	00007517          	auipc	a0,0x7
    800013aa:	db250513          	addi	a0,a0,-590 # 80008158 <digits+0x118>
    800013ae:	fffff097          	auipc	ra,0xfffff
    800013b2:	17c080e7          	jalr	380(ra) # 8000052a <panic>

00000000800013b6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013b6:	1101                	addi	sp,sp,-32
    800013b8:	ec06                	sd	ra,24(sp)
    800013ba:	e822                	sd	s0,16(sp)
    800013bc:	e426                	sd	s1,8(sp)
    800013be:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013c2:	00b67d63          	bgeu	a2,a1,800013dc <uvmdealloc+0x26>
    800013c6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013c8:	6785                	lui	a5,0x1
    800013ca:	17fd                	addi	a5,a5,-1
    800013cc:	00f60733          	add	a4,a2,a5
    800013d0:	767d                	lui	a2,0xfffff
    800013d2:	8f71                	and	a4,a4,a2
    800013d4:	97ae                	add	a5,a5,a1
    800013d6:	8ff1                	and	a5,a5,a2
    800013d8:	00f76863          	bltu	a4,a5,800013e8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013dc:	8526                	mv	a0,s1
    800013de:	60e2                	ld	ra,24(sp)
    800013e0:	6442                	ld	s0,16(sp)
    800013e2:	64a2                	ld	s1,8(sp)
    800013e4:	6105                	addi	sp,sp,32
    800013e6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013e8:	8f99                	sub	a5,a5,a4
    800013ea:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013ec:	4685                	li	a3,1
    800013ee:	0007861b          	sext.w	a2,a5
    800013f2:	85ba                	mv	a1,a4
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	e5e080e7          	jalr	-418(ra) # 80001252 <uvmunmap>
    800013fc:	b7c5                	j	800013dc <uvmdealloc+0x26>

00000000800013fe <uvmalloc>:
  if(newsz < oldsz)
    800013fe:	0ab66163          	bltu	a2,a1,800014a0 <uvmalloc+0xa2>
{
    80001402:	7139                	addi	sp,sp,-64
    80001404:	fc06                	sd	ra,56(sp)
    80001406:	f822                	sd	s0,48(sp)
    80001408:	f426                	sd	s1,40(sp)
    8000140a:	f04a                	sd	s2,32(sp)
    8000140c:	ec4e                	sd	s3,24(sp)
    8000140e:	e852                	sd	s4,16(sp)
    80001410:	e456                	sd	s5,8(sp)
    80001412:	0080                	addi	s0,sp,64
    80001414:	8aaa                	mv	s5,a0
    80001416:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001418:	6985                	lui	s3,0x1
    8000141a:	19fd                	addi	s3,s3,-1
    8000141c:	95ce                	add	a1,a1,s3
    8000141e:	79fd                	lui	s3,0xfffff
    80001420:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001424:	08c9f063          	bgeu	s3,a2,800014a4 <uvmalloc+0xa6>
    80001428:	894e                	mv	s2,s3
      mem = kalloc();
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	6b8080e7          	jalr	1720(ra) # 80000ae2 <kalloc>
    80001432:	84aa                	mv	s1,a0
      if(mem == 0){
    80001434:	c51d                	beqz	a0,80001462 <uvmalloc+0x64>
      memset(mem, 0, PGSIZE);
    80001436:	6605                	lui	a2,0x1
    80001438:	4581                	li	a1,0
    8000143a:	00000097          	auipc	ra,0x0
    8000143e:	894080e7          	jalr	-1900(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001442:	4779                	li	a4,30
    80001444:	86a6                	mv	a3,s1
    80001446:	6605                	lui	a2,0x1
    80001448:	85ca                	mv	a1,s2
    8000144a:	8556                	mv	a0,s5
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	c52080e7          	jalr	-942(ra) # 8000109e <mappages>
    80001454:	e905                	bnez	a0,80001484 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001456:	6785                	lui	a5,0x1
    80001458:	993e                	add	s2,s2,a5
    8000145a:	fd4968e3          	bltu	s2,s4,8000142a <uvmalloc+0x2c>
  return newsz;
    8000145e:	8552                	mv	a0,s4
    80001460:	a809                	j	80001472 <uvmalloc+0x74>
        uvmdealloc(pagetable, a, oldsz);
    80001462:	864e                	mv	a2,s3
    80001464:	85ca                	mv	a1,s2
    80001466:	8556                	mv	a0,s5
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	f4e080e7          	jalr	-178(ra) # 800013b6 <uvmdealloc>
        return 0;
    80001470:	4501                	li	a0,0
}
    80001472:	70e2                	ld	ra,56(sp)
    80001474:	7442                	ld	s0,48(sp)
    80001476:	74a2                	ld	s1,40(sp)
    80001478:	7902                	ld	s2,32(sp)
    8000147a:	69e2                	ld	s3,24(sp)
    8000147c:	6a42                	ld	s4,16(sp)
    8000147e:	6aa2                	ld	s5,8(sp)
    80001480:	6121                	addi	sp,sp,64
    80001482:	8082                	ret
        kfree(mem);
    80001484:	8526                	mv	a0,s1
    80001486:	fffff097          	auipc	ra,0xfffff
    8000148a:	550080e7          	jalr	1360(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    8000148e:	864e                	mv	a2,s3
    80001490:	85ca                	mv	a1,s2
    80001492:	8556                	mv	a0,s5
    80001494:	00000097          	auipc	ra,0x0
    80001498:	f22080e7          	jalr	-222(ra) # 800013b6 <uvmdealloc>
        return 0;
    8000149c:	4501                	li	a0,0
    8000149e:	bfd1                	j	80001472 <uvmalloc+0x74>
    return oldsz;
    800014a0:	852e                	mv	a0,a1
}
    800014a2:	8082                	ret
  return newsz;
    800014a4:	8532                	mv	a0,a2
    800014a6:	b7f1                	j	80001472 <uvmalloc+0x74>

00000000800014a8 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014a8:	7179                	addi	sp,sp,-48
    800014aa:	f406                	sd	ra,40(sp)
    800014ac:	f022                	sd	s0,32(sp)
    800014ae:	ec26                	sd	s1,24(sp)
    800014b0:	e84a                	sd	s2,16(sp)
    800014b2:	e44e                	sd	s3,8(sp)
    800014b4:	e052                	sd	s4,0(sp)
    800014b6:	1800                	addi	s0,sp,48
    800014b8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014ba:	84aa                	mv	s1,a0
    800014bc:	6905                	lui	s2,0x1
    800014be:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c0:	4985                	li	s3,1
    800014c2:	a821                	j	800014da <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014c4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014c6:	0532                	slli	a0,a0,0xc
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	fe0080e7          	jalr	-32(ra) # 800014a8 <freewalk>
      pagetable[i] = 0;
    800014d0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014d4:	04a1                	addi	s1,s1,8
    800014d6:	03248163          	beq	s1,s2,800014f8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014da:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014dc:	00f57793          	andi	a5,a0,15
    800014e0:	ff3782e3          	beq	a5,s3,800014c4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014e4:	8905                	andi	a0,a0,1
    800014e6:	d57d                	beqz	a0,800014d4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014e8:	00007517          	auipc	a0,0x7
    800014ec:	c9050513          	addi	a0,a0,-880 # 80008178 <digits+0x138>
    800014f0:	fffff097          	auipc	ra,0xfffff
    800014f4:	03a080e7          	jalr	58(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014f8:	8552                	mv	a0,s4
    800014fa:	fffff097          	auipc	ra,0xfffff
    800014fe:	4dc080e7          	jalr	1244(ra) # 800009d6 <kfree>
}
    80001502:	70a2                	ld	ra,40(sp)
    80001504:	7402                	ld	s0,32(sp)
    80001506:	64e2                	ld	s1,24(sp)
    80001508:	6942                	ld	s2,16(sp)
    8000150a:	69a2                	ld	s3,8(sp)
    8000150c:	6a02                	ld	s4,0(sp)
    8000150e:	6145                	addi	sp,sp,48
    80001510:	8082                	ret

0000000080001512 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001512:	1101                	addi	sp,sp,-32
    80001514:	ec06                	sd	ra,24(sp)
    80001516:	e822                	sd	s0,16(sp)
    80001518:	e426                	sd	s1,8(sp)
    8000151a:	1000                	addi	s0,sp,32
    8000151c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000151e:	e999                	bnez	a1,80001534 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001520:	8526                	mv	a0,s1
    80001522:	00000097          	auipc	ra,0x0
    80001526:	f86080e7          	jalr	-122(ra) # 800014a8 <freewalk>
}
    8000152a:	60e2                	ld	ra,24(sp)
    8000152c:	6442                	ld	s0,16(sp)
    8000152e:	64a2                	ld	s1,8(sp)
    80001530:	6105                	addi	sp,sp,32
    80001532:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001534:	6605                	lui	a2,0x1
    80001536:	167d                	addi	a2,a2,-1
    80001538:	962e                	add	a2,a2,a1
    8000153a:	4685                	li	a3,1
    8000153c:	8231                	srli	a2,a2,0xc
    8000153e:	4581                	li	a1,0
    80001540:	00000097          	auipc	ra,0x0
    80001544:	d12080e7          	jalr	-750(ra) # 80001252 <uvmunmap>
    80001548:	bfe1                	j	80001520 <uvmfree+0xe>

000000008000154a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000154a:	c679                	beqz	a2,80001618 <uvmcopy+0xce>
{
    8000154c:	715d                	addi	sp,sp,-80
    8000154e:	e486                	sd	ra,72(sp)
    80001550:	e0a2                	sd	s0,64(sp)
    80001552:	fc26                	sd	s1,56(sp)
    80001554:	f84a                	sd	s2,48(sp)
    80001556:	f44e                	sd	s3,40(sp)
    80001558:	f052                	sd	s4,32(sp)
    8000155a:	ec56                	sd	s5,24(sp)
    8000155c:	e85a                	sd	s6,16(sp)
    8000155e:	e45e                	sd	s7,8(sp)
    80001560:	0880                	addi	s0,sp,80
    80001562:	8b2a                	mv	s6,a0
    80001564:	8aae                	mv	s5,a1
    80001566:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001568:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000156a:	4601                	li	a2,0
    8000156c:	85ce                	mv	a1,s3
    8000156e:	855a                	mv	a0,s6
    80001570:	00000097          	auipc	ra,0x0
    80001574:	a46080e7          	jalr	-1466(ra) # 80000fb6 <walk>
    80001578:	c531                	beqz	a0,800015c4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000157a:	6118                	ld	a4,0(a0)
    8000157c:	00177793          	andi	a5,a4,1
    80001580:	cbb1                	beqz	a5,800015d4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001582:	00a75593          	srli	a1,a4,0xa
    80001586:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000158a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	554080e7          	jalr	1364(ra) # 80000ae2 <kalloc>
    80001596:	892a                	mv	s2,a0
    80001598:	c939                	beqz	a0,800015ee <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85de                	mv	a1,s7
    8000159e:	fffff097          	auipc	ra,0xfffff
    800015a2:	78c080e7          	jalr	1932(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015a6:	8726                	mv	a4,s1
    800015a8:	86ca                	mv	a3,s2
    800015aa:	6605                	lui	a2,0x1
    800015ac:	85ce                	mv	a1,s3
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	aee080e7          	jalr	-1298(ra) # 8000109e <mappages>
    800015b8:	e515                	bnez	a0,800015e4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015ba:	6785                	lui	a5,0x1
    800015bc:	99be                	add	s3,s3,a5
    800015be:	fb49e6e3          	bltu	s3,s4,8000156a <uvmcopy+0x20>
    800015c2:	a081                	j	80001602 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bc450513          	addi	a0,a0,-1084 # 80008188 <digits+0x148>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015d4:	00007517          	auipc	a0,0x7
    800015d8:	bd450513          	addi	a0,a0,-1068 # 800081a8 <digits+0x168>
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	f4e080e7          	jalr	-178(ra) # 8000052a <panic>
      kfree(mem);
    800015e4:	854a                	mv	a0,s2
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	3f0080e7          	jalr	1008(ra) # 800009d6 <kfree>
    
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015ee:	4685                	li	a3,1
    800015f0:	00c9d613          	srli	a2,s3,0xc
    800015f4:	4581                	li	a1,0
    800015f6:	8556                	mv	a0,s5
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	c5a080e7          	jalr	-934(ra) # 80001252 <uvmunmap>
  return -1;
    80001600:	557d                	li	a0,-1
}
    80001602:	60a6                	ld	ra,72(sp)
    80001604:	6406                	ld	s0,64(sp)
    80001606:	74e2                	ld	s1,56(sp)
    80001608:	7942                	ld	s2,48(sp)
    8000160a:	79a2                	ld	s3,40(sp)
    8000160c:	7a02                	ld	s4,32(sp)
    8000160e:	6ae2                	ld	s5,24(sp)
    80001610:	6b42                	ld	s6,16(sp)
    80001612:	6ba2                	ld	s7,8(sp)
    80001614:	6161                	addi	sp,sp,80
    80001616:	8082                	ret
  return 0;
    80001618:	4501                	li	a0,0
}
    8000161a:	8082                	ret

000000008000161c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000161c:	1141                	addi	sp,sp,-16
    8000161e:	e406                	sd	ra,8(sp)
    80001620:	e022                	sd	s0,0(sp)
    80001622:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001624:	4601                	li	a2,0
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	990080e7          	jalr	-1648(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000162e:	c901                	beqz	a0,8000163e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001630:	611c                	ld	a5,0(a0)
    80001632:	9bbd                	andi	a5,a5,-17
    80001634:	e11c                	sd	a5,0(a0)
}
    80001636:	60a2                	ld	ra,8(sp)
    80001638:	6402                	ld	s0,0(sp)
    8000163a:	0141                	addi	sp,sp,16
    8000163c:	8082                	ret
    panic("uvmclear");
    8000163e:	00007517          	auipc	a0,0x7
    80001642:	b8a50513          	addi	a0,a0,-1142 # 800081c8 <digits+0x188>
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	ee4080e7          	jalr	-284(ra) # 8000052a <panic>

000000008000164e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000164e:	c6bd                	beqz	a3,800016bc <copyout+0x6e>
{
    80001650:	715d                	addi	sp,sp,-80
    80001652:	e486                	sd	ra,72(sp)
    80001654:	e0a2                	sd	s0,64(sp)
    80001656:	fc26                	sd	s1,56(sp)
    80001658:	f84a                	sd	s2,48(sp)
    8000165a:	f44e                	sd	s3,40(sp)
    8000165c:	f052                	sd	s4,32(sp)
    8000165e:	ec56                	sd	s5,24(sp)
    80001660:	e85a                	sd	s6,16(sp)
    80001662:	e45e                	sd	s7,8(sp)
    80001664:	e062                	sd	s8,0(sp)
    80001666:	0880                	addi	s0,sp,80
    80001668:	8b2a                	mv	s6,a0
    8000166a:	8c2e                	mv	s8,a1
    8000166c:	8a32                	mv	s4,a2
    8000166e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001670:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001672:	6a85                	lui	s5,0x1
    80001674:	a015                	j	80001698 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001676:	9562                	add	a0,a0,s8
    80001678:	0004861b          	sext.w	a2,s1
    8000167c:	85d2                	mv	a1,s4
    8000167e:	41250533          	sub	a0,a0,s2
    80001682:	fffff097          	auipc	ra,0xfffff
    80001686:	6a8080e7          	jalr	1704(ra) # 80000d2a <memmove>

    len -= n;
    8000168a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000168e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001690:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001694:	02098263          	beqz	s3,800016b8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001698:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000169c:	85ca                	mv	a1,s2
    8000169e:	855a                	mv	a0,s6
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	9bc080e7          	jalr	-1604(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016a8:	cd01                	beqz	a0,800016c0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016aa:	418904b3          	sub	s1,s2,s8
    800016ae:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b0:	fc99f3e3          	bgeu	s3,s1,80001676 <copyout+0x28>
    800016b4:	84ce                	mv	s1,s3
    800016b6:	b7c1                	j	80001676 <copyout+0x28>
  }
  return 0;
    800016b8:	4501                	li	a0,0
    800016ba:	a021                	j	800016c2 <copyout+0x74>
    800016bc:	4501                	li	a0,0
}
    800016be:	8082                	ret
      return -1;
    800016c0:	557d                	li	a0,-1
}
    800016c2:	60a6                	ld	ra,72(sp)
    800016c4:	6406                	ld	s0,64(sp)
    800016c6:	74e2                	ld	s1,56(sp)
    800016c8:	7942                	ld	s2,48(sp)
    800016ca:	79a2                	ld	s3,40(sp)
    800016cc:	7a02                	ld	s4,32(sp)
    800016ce:	6ae2                	ld	s5,24(sp)
    800016d0:	6b42                	ld	s6,16(sp)
    800016d2:	6ba2                	ld	s7,8(sp)
    800016d4:	6c02                	ld	s8,0(sp)
    800016d6:	6161                	addi	sp,sp,80
    800016d8:	8082                	ret

00000000800016da <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016da:	caa5                	beqz	a3,8000174a <copyin+0x70>
{
    800016dc:	715d                	addi	sp,sp,-80
    800016de:	e486                	sd	ra,72(sp)
    800016e0:	e0a2                	sd	s0,64(sp)
    800016e2:	fc26                	sd	s1,56(sp)
    800016e4:	f84a                	sd	s2,48(sp)
    800016e6:	f44e                	sd	s3,40(sp)
    800016e8:	f052                	sd	s4,32(sp)
    800016ea:	ec56                	sd	s5,24(sp)
    800016ec:	e85a                	sd	s6,16(sp)
    800016ee:	e45e                	sd	s7,8(sp)
    800016f0:	e062                	sd	s8,0(sp)
    800016f2:	0880                	addi	s0,sp,80
    800016f4:	8b2a                	mv	s6,a0
    800016f6:	8a2e                	mv	s4,a1
    800016f8:	8c32                	mv	s8,a2
    800016fa:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016fc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016fe:	6a85                	lui	s5,0x1
    80001700:	a01d                	j	80001726 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001702:	018505b3          	add	a1,a0,s8
    80001706:	0004861b          	sext.w	a2,s1
    8000170a:	412585b3          	sub	a1,a1,s2
    8000170e:	8552                	mv	a0,s4
    80001710:	fffff097          	auipc	ra,0xfffff
    80001714:	61a080e7          	jalr	1562(ra) # 80000d2a <memmove>

    len -= n;
    80001718:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000171c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000171e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001722:	02098263          	beqz	s3,80001746 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001726:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000172a:	85ca                	mv	a1,s2
    8000172c:	855a                	mv	a0,s6
    8000172e:	00000097          	auipc	ra,0x0
    80001732:	92e080e7          	jalr	-1746(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001736:	cd01                	beqz	a0,8000174e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001738:	418904b3          	sub	s1,s2,s8
    8000173c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000173e:	fc99f2e3          	bgeu	s3,s1,80001702 <copyin+0x28>
    80001742:	84ce                	mv	s1,s3
    80001744:	bf7d                	j	80001702 <copyin+0x28>
  }
  return 0;
    80001746:	4501                	li	a0,0
    80001748:	a021                	j	80001750 <copyin+0x76>
    8000174a:	4501                	li	a0,0
}
    8000174c:	8082                	ret
      return -1;
    8000174e:	557d                	li	a0,-1
}
    80001750:	60a6                	ld	ra,72(sp)
    80001752:	6406                	ld	s0,64(sp)
    80001754:	74e2                	ld	s1,56(sp)
    80001756:	7942                	ld	s2,48(sp)
    80001758:	79a2                	ld	s3,40(sp)
    8000175a:	7a02                	ld	s4,32(sp)
    8000175c:	6ae2                	ld	s5,24(sp)
    8000175e:	6b42                	ld	s6,16(sp)
    80001760:	6ba2                	ld	s7,8(sp)
    80001762:	6c02                	ld	s8,0(sp)
    80001764:	6161                	addi	sp,sp,80
    80001766:	8082                	ret

0000000080001768 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001768:	c6c5                	beqz	a3,80001810 <copyinstr+0xa8>
{
    8000176a:	715d                	addi	sp,sp,-80
    8000176c:	e486                	sd	ra,72(sp)
    8000176e:	e0a2                	sd	s0,64(sp)
    80001770:	fc26                	sd	s1,56(sp)
    80001772:	f84a                	sd	s2,48(sp)
    80001774:	f44e                	sd	s3,40(sp)
    80001776:	f052                	sd	s4,32(sp)
    80001778:	ec56                	sd	s5,24(sp)
    8000177a:	e85a                	sd	s6,16(sp)
    8000177c:	e45e                	sd	s7,8(sp)
    8000177e:	0880                	addi	s0,sp,80
    80001780:	8a2a                	mv	s4,a0
    80001782:	8b2e                	mv	s6,a1
    80001784:	8bb2                	mv	s7,a2
    80001786:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001788:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000178a:	6985                	lui	s3,0x1
    8000178c:	a035                	j	800017b8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000178e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001792:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001794:	0017b793          	seqz	a5,a5
    80001798:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000179c:	60a6                	ld	ra,72(sp)
    8000179e:	6406                	ld	s0,64(sp)
    800017a0:	74e2                	ld	s1,56(sp)
    800017a2:	7942                	ld	s2,48(sp)
    800017a4:	79a2                	ld	s3,40(sp)
    800017a6:	7a02                	ld	s4,32(sp)
    800017a8:	6ae2                	ld	s5,24(sp)
    800017aa:	6b42                	ld	s6,16(sp)
    800017ac:	6ba2                	ld	s7,8(sp)
    800017ae:	6161                	addi	sp,sp,80
    800017b0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017b6:	c8a9                	beqz	s1,80001808 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017b8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017bc:	85ca                	mv	a1,s2
    800017be:	8552                	mv	a0,s4
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	89c080e7          	jalr	-1892(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017c8:	c131                	beqz	a0,8000180c <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ca:	41790833          	sub	a6,s2,s7
    800017ce:	984e                	add	a6,a6,s3
    if(n > max)
    800017d0:	0104f363          	bgeu	s1,a6,800017d6 <copyinstr+0x6e>
    800017d4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017d6:	955e                	add	a0,a0,s7
    800017d8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017dc:	fc080be3          	beqz	a6,800017b2 <copyinstr+0x4a>
    800017e0:	985a                	add	a6,a6,s6
    800017e2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017e4:	41650633          	sub	a2,a0,s6
    800017e8:	14fd                	addi	s1,s1,-1
    800017ea:	9b26                	add	s6,s6,s1
    800017ec:	00f60733          	add	a4,a2,a5
    800017f0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
    800017f4:	df49                	beqz	a4,8000178e <copyinstr+0x26>
        *dst = *p;
    800017f6:	00e78023          	sb	a4,0(a5)
      --max;
    800017fa:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017fe:	0785                	addi	a5,a5,1
    while(n > 0){
    80001800:	ff0796e3          	bne	a5,a6,800017ec <copyinstr+0x84>
      dst++;
    80001804:	8b42                	mv	s6,a6
    80001806:	b775                	j	800017b2 <copyinstr+0x4a>
    80001808:	4781                	li	a5,0
    8000180a:	b769                	j	80001794 <copyinstr+0x2c>
      return -1;
    8000180c:	557d                	li	a0,-1
    8000180e:	b779                	j	8000179c <copyinstr+0x34>
  int got_null = 0;
    80001810:	4781                	li	a5,0
  if(got_null){
    80001812:	0017b793          	seqz	a5,a5
    80001816:	40f00533          	neg	a0,a5
}
    8000181a:	8082                	ret

000000008000181c <swap_page_into_file>:


 

void swap_page_into_file(int offset){
    8000181c:	7179                	addi	sp,sp,-48
    8000181e:	f406                	sd	ra,40(sp)
    80001820:	f022                	sd	s0,32(sp)
    80001822:	ec26                	sd	s1,24(sp)
    80001824:	e84a                	sd	s2,16(sp)
    80001826:	e44e                	sd	s3,8(sp)
    80001828:	e052                	sd	s4,0(sp)
    8000182a:	1800                	addi	s0,sp,48
    8000182c:	8a2a                	mv	s4,a0
    struct proc * p = myproc();
    8000182e:	00001097          	auipc	ra,0x1
    80001832:	84a080e7          	jalr	-1974(ra) # 80002078 <myproc>
    80001836:	892a                	mv	s2,a0
    int remove_file_indx = find_file_to_remove();
    uint64 removed_page_VA = remove_file_indx*PGSIZE;
    printf("chosen file %d \n", remove_file_indx);
    80001838:	4581                	li	a1,0
    8000183a:	00007517          	auipc	a0,0x7
    8000183e:	99e50513          	addi	a0,a0,-1634 # 800081d8 <digits+0x198>
    80001842:	fffff097          	auipc	ra,0xfffff
    80001846:	d32080e7          	jalr	-718(ra) # 80000574 <printf>
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    8000184a:	4601                	li	a2,0
    8000184c:	4581                	li	a1,0
    8000184e:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80001852:	fffff097          	auipc	ra,0xfffff
    80001856:	764080e7          	jalr	1892(ra) # 80000fb6 <walk>
    8000185a:	89aa                	mv	s3,a0
    //write the information from this file to memory
    uint64 physical_addr = PTE2PA(*out_page_entry);
    8000185c:	6104                	ld	s1,0(a0)
    8000185e:	80a9                	srli	s1,s1,0xa
    80001860:	04b2                	slli	s1,s1,0xc
    if(writeToSwapFile(p,(char*)physical_addr,offset,PGSIZE) ==  -1)
    80001862:	6685                	lui	a3,0x1
    80001864:	8652                	mv	a2,s4
    80001866:	85a6                	mv	a1,s1
    80001868:	854a                	mv	a0,s2
    8000186a:	00003097          	auipc	ra,0x3
    8000186e:	11e080e7          	jalr	286(ra) # 80004988 <writeToSwapFile>
    80001872:	57fd                	li	a5,-1
    80001874:	02f50b63          	beq	a0,a5,800018aa <swap_page_into_file+0x8e>
      panic("write to file failed");
    //free the RAM memmory of the swapped page
    kfree((void*)physical_addr);
    80001878:	8526                	mv	a0,s1
    8000187a:	fffff097          	auipc	ra,0xfffff
    8000187e:	15c080e7          	jalr	348(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    80001882:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
    80001886:	bfe7f793          	andi	a5,a5,-1026
    8000188a:	4007e793          	ori	a5,a5,1024
    8000188e:	00f9b023          	sd	a5,0(s3)
    p->paging_meta_data[remove_file_indx].offset = offset;
    80001892:	17492823          	sw	s4,368(s2)
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    80001896:	16092c23          	sw	zero,376(s2)
      
}
    8000189a:	70a2                	ld	ra,40(sp)
    8000189c:	7402                	ld	s0,32(sp)
    8000189e:	64e2                	ld	s1,24(sp)
    800018a0:	6942                	ld	s2,16(sp)
    800018a2:	69a2                	ld	s3,8(sp)
    800018a4:	6a02                	ld	s4,0(sp)
    800018a6:	6145                	addi	sp,sp,48
    800018a8:	8082                	ret
      panic("write to file failed");
    800018aa:	00007517          	auipc	a0,0x7
    800018ae:	94650513          	addi	a0,a0,-1722 # 800081f0 <digits+0x1b0>
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	c78080e7          	jalr	-904(ra) # 8000052a <panic>

00000000800018ba <get_num_of_pages_in_memory>:

int get_num_of_pages_in_memory(){
    800018ba:	7179                	addi	sp,sp,-48
    800018bc:	f406                	sd	ra,40(sp)
    800018be:	f022                	sd	s0,32(sp)
    800018c0:	ec26                	sd	s1,24(sp)
    800018c2:	e84a                	sd	s2,16(sp)
    800018c4:	e44e                	sd	s3,8(sp)
    800018c6:	1800                	addi	s0,sp,48
  int counter = 0;
  for(int i=0; i<32; i++){
    800018c8:	4481                	li	s1,0
  int counter = 0;
    800018ca:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    800018cc:	02000993          	li	s3,32
    800018d0:	a021                	j	800018d8 <get_num_of_pages_in_memory+0x1e>
    800018d2:	2485                	addiw	s1,s1,1
    800018d4:	03348063          	beq	s1,s3,800018f4 <get_num_of_pages_in_memory+0x3a>
    if(myproc()->paging_meta_data[i].in_memory)
    800018d8:	00000097          	auipc	ra,0x0
    800018dc:	7a0080e7          	jalr	1952(ra) # 80002078 <myproc>
    800018e0:	00149793          	slli	a5,s1,0x1
    800018e4:	97a6                	add	a5,a5,s1
    800018e6:	078a                	slli	a5,a5,0x2
    800018e8:	97aa                	add	a5,a5,a0
    800018ea:	1787a783          	lw	a5,376(a5)
    800018ee:	d3f5                	beqz	a5,800018d2 <get_num_of_pages_in_memory+0x18>
      counter = counter+1;
    800018f0:	2905                	addiw	s2,s2,1
    800018f2:	b7c5                	j	800018d2 <get_num_of_pages_in_memory+0x18>
  }
  return counter; 
}
    800018f4:	854a                	mv	a0,s2
    800018f6:	70a2                	ld	ra,40(sp)
    800018f8:	7402                	ld	s0,32(sp)
    800018fa:	64e2                	ld	s1,24(sp)
    800018fc:	6942                	ld	s2,16(sp)
    800018fe:	69a2                	ld	s3,8(sp)
    80001900:	6145                	addi	sp,sp,48
    80001902:	8082                	ret

0000000080001904 <page_in>:

void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    80001904:	7139                	addi	sp,sp,-64
    80001906:	fc06                	sd	ra,56(sp)
    80001908:	f822                	sd	s0,48(sp)
    8000190a:	f426                	sd	s1,40(sp)
    8000190c:	f04a                	sd	s2,32(sp)
    8000190e:	ec4e                	sd	s3,24(sp)
    80001910:	e852                	sd	s4,16(sp)
    80001912:	e456                	sd	s5,8(sp)
    80001914:	0080                	addi	s0,sp,64
    80001916:	89ae                	mv	s3,a1
  //get the page number of the missing in ram page
  int current_page_number = PGROUNDDOWN(faulting_address)/PGSIZE;
    80001918:	8131                	srli	a0,a0,0xc
    8000191a:	0005091b          	sext.w	s2,a0
  //get its offset in the saved file
  uint offset = myproc()->paging_meta_data[current_page_number].offset;
    8000191e:	00000097          	auipc	ra,0x0
    80001922:	75a080e7          	jalr	1882(ra) # 80002078 <myproc>
    80001926:	00191793          	slli	a5,s2,0x1
    8000192a:	97ca                	add	a5,a5,s2
    8000192c:	078a                	slli	a5,a5,0x2
    8000192e:	97aa                	add	a5,a5,a0
    80001930:	1707aa83          	lw	s5,368(a5)
    80001934:	000a8a1b          	sext.w	s4,s5
  if(offset == -1){
    80001938:	57fd                	li	a5,-1
    8000193a:	08fa0f63          	beq	s4,a5,800019d8 <page_in+0xd4>
    panic("offset is -1");
  }
  //allocate a buffer for the information from the file
  char* read_buffer;
  if((read_buffer = kalloc()) == 0)
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	1a4080e7          	jalr	420(ra) # 80000ae2 <kalloc>
    80001946:	84aa                	mv	s1,a0
    80001948:	c145                	beqz	a0,800019e8 <page_in+0xe4>
    panic("not enough space to kalloc");
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	72e080e7          	jalr	1838(ra) # 80002078 <myproc>
    80001952:	6685                	lui	a3,0x1
    80001954:	8652                	mv	a2,s4
    80001956:	85a6                	mv	a1,s1
    80001958:	00003097          	auipc	ra,0x3
    8000195c:	054080e7          	jalr	84(ra) # 800049ac <readFromSwapFile>
    80001960:	57fd                	li	a5,-1
    80001962:	08f50b63          	beq	a0,a5,800019f8 <page_in+0xf4>
    panic("read from file failed");
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80001966:	00000097          	auipc	ra,0x0
    8000196a:	f54080e7          	jalr	-172(ra) # 800018ba <get_num_of_pages_in_memory>
    8000196e:	47bd                	li	a5,15
    80001970:	08a7cc63          	blt	a5,a0,80001a08 <page_in+0x104>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
  }  
  else{
      *missing_pte_entry = PA2PTE((uint64)read_buffer) | PTE_V; 
    80001974:	80b1                	srli	s1,s1,0xc
    80001976:	04aa                	slli	s1,s1,0xa
    80001978:	0014e493          	ori	s1,s1,1
    8000197c:	0099b023          	sd	s1,0(s3)
  }
  //update offsets and aging of the files
  myproc()->paging_meta_data[current_page_number].aging = init_aging(current_page_number);
    80001980:	00000097          	auipc	ra,0x0
    80001984:	6f8080e7          	jalr	1784(ra) # 80002078 <myproc>
    80001988:	00191493          	slli	s1,s2,0x1
    8000198c:	012487b3          	add	a5,s1,s2
    80001990:	078a                	slli	a5,a5,0x2
    80001992:	953e                	add	a0,a0,a5
    80001994:	16052a23          	sw	zero,372(a0)
  myproc()->paging_meta_data[current_page_number].offset = -1;
    80001998:	00000097          	auipc	ra,0x0
    8000199c:	6e0080e7          	jalr	1760(ra) # 80002078 <myproc>
    800019a0:	012487b3          	add	a5,s1,s2
    800019a4:	078a                	slli	a5,a5,0x2
    800019a6:	953e                	add	a0,a0,a5
    800019a8:	57fd                	li	a5,-1
    800019aa:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_number].in_memory = 1;
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	6ca080e7          	jalr	1738(ra) # 80002078 <myproc>
    800019b6:	94ca                	add	s1,s1,s2
    800019b8:	048a                	slli	s1,s1,0x2
    800019ba:	94aa                	add	s1,s1,a0
    800019bc:	4785                	li	a5,1
    800019be:	16f4ac23          	sw	a5,376(s1)
    800019c2:	12000073          	sfence.vma
  sfence_vma(); //refresh TLB
}
    800019c6:	70e2                	ld	ra,56(sp)
    800019c8:	7442                	ld	s0,48(sp)
    800019ca:	74a2                	ld	s1,40(sp)
    800019cc:	7902                	ld	s2,32(sp)
    800019ce:	69e2                	ld	s3,24(sp)
    800019d0:	6a42                	ld	s4,16(sp)
    800019d2:	6aa2                	ld	s5,8(sp)
    800019d4:	6121                	addi	sp,sp,64
    800019d6:	8082                	ret
    panic("offset is -1");
    800019d8:	00007517          	auipc	a0,0x7
    800019dc:	83050513          	addi	a0,a0,-2000 # 80008208 <digits+0x1c8>
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	b4a080e7          	jalr	-1206(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    800019e8:	00007517          	auipc	a0,0x7
    800019ec:	83050513          	addi	a0,a0,-2000 # 80008218 <digits+0x1d8>
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	b3a080e7          	jalr	-1222(ra) # 8000052a <panic>
    panic("read from file failed");
    800019f8:	00007517          	auipc	a0,0x7
    800019fc:	84050513          	addi	a0,a0,-1984 # 80008238 <digits+0x1f8>
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	b2a080e7          	jalr	-1238(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    80001a08:	8556                	mv	a0,s5
    80001a0a:	00000097          	auipc	ra,0x0
    80001a0e:	e12080e7          	jalr	-494(ra) # 8000181c <swap_page_into_file>
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    80001a12:	80b1                	srli	s1,s1,0xc
    80001a14:	04aa                	slli	s1,s1,0xa
    80001a16:	0009b783          	ld	a5,0(s3)
    80001a1a:	3fe7f793          	andi	a5,a5,1022
    80001a1e:	8cdd                	or	s1,s1,a5
    80001a20:	0014e493          	ori	s1,s1,1
    80001a24:	0099b023          	sd	s1,0(s3)
    80001a28:	bfa1                	j	80001980 <page_in+0x7c>

0000000080001a2a <lazy_memory_allocation>:

void lazy_memory_allocation(uint64 faulting_address){
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
    80001a36:	892a                	mv	s2,a0
    char * mem = kalloc();
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	0aa080e7          	jalr	170(ra) # 80000ae2 <kalloc>
    if(mem == 0){
    80001a40:	cd15                	beqz	a0,80001a7c <lazy_memory_allocation+0x52>
    80001a42:	84aa                	mv	s1,a0
      panic("not enough space to kalloc");
    }
    memset(mem, 0, PGSIZE);
    80001a44:	6605                	lui	a2,0x1
    80001a46:	4581                	li	a1,0
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	286080e7          	jalr	646(ra) # 80000cce <memset>
    if(mappages(myproc()->pagetable, PGROUNDDOWN(faulting_address), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001a50:	00000097          	auipc	ra,0x0
    80001a54:	628080e7          	jalr	1576(ra) # 80002078 <myproc>
    80001a58:	4779                	li	a4,30
    80001a5a:	86a6                	mv	a3,s1
    80001a5c:	6605                	lui	a2,0x1
    80001a5e:	75fd                	lui	a1,0xfffff
    80001a60:	00b975b3          	and	a1,s2,a1
    80001a64:	6928                	ld	a0,80(a0)
    80001a66:	fffff097          	auipc	ra,0xfffff
    80001a6a:	638080e7          	jalr	1592(ra) # 8000109e <mappages>
    80001a6e:	ed19                	bnez	a0,80001a8c <lazy_memory_allocation+0x62>
      kfree(mem);
      panic("mappages failed");
    }
}
    80001a70:	60e2                	ld	ra,24(sp)
    80001a72:	6442                	ld	s0,16(sp)
    80001a74:	64a2                	ld	s1,8(sp)
    80001a76:	6902                	ld	s2,0(sp)
    80001a78:	6105                	addi	sp,sp,32
    80001a7a:	8082                	ret
      panic("not enough space to kalloc");
    80001a7c:	00006517          	auipc	a0,0x6
    80001a80:	79c50513          	addi	a0,a0,1948 # 80008218 <digits+0x1d8>
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	aa6080e7          	jalr	-1370(ra) # 8000052a <panic>
      kfree(mem);
    80001a8c:	8526                	mv	a0,s1
    80001a8e:	fffff097          	auipc	ra,0xfffff
    80001a92:	f48080e7          	jalr	-184(ra) # 800009d6 <kfree>
      panic("mappages failed");
    80001a96:	00006517          	auipc	a0,0x6
    80001a9a:	7ba50513          	addi	a0,a0,1978 # 80008250 <digits+0x210>
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	a8c080e7          	jalr	-1396(ra) # 8000052a <panic>

0000000080001aa6 <check_page_fault>:

void check_page_fault(){
    80001aa6:	1101                	addi	sp,sp,-32
    80001aa8:	ec06                	sd	ra,24(sp)
    80001aaa:	e822                	sd	s0,16(sp)
    80001aac:	e426                	sd	s1,8(sp)
    80001aae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001ab0:	143024f3          	csrr	s1,stval
  uint64 faulting_address = r_stval(); 
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80001ab4:	00000097          	auipc	ra,0x0
    80001ab8:	5c4080e7          	jalr	1476(ra) # 80002078 <myproc>
    80001abc:	4601                	li	a2,0
    80001abe:	75fd                	lui	a1,0xfffff
    80001ac0:	8de5                	and	a1,a1,s1
    80001ac2:	6928                	ld	a0,80(a0)
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	4f2080e7          	jalr	1266(ra) # 80000fb6 <walk>
  if(pte_entry !=0 && ((!(PTE_FLAGS(*pte_entry) & PTE_V) ) & (PTE_FLAGS(*pte_entry) & PTE_PG))){
    printf("Page Fault - Page was out of memory\n");
    page_in(faulting_address, pte_entry);
  }
  else{
    printf("Page Fault - Lazy allocation\n");
    80001acc:	00006517          	auipc	a0,0x6
    80001ad0:	79450513          	addi	a0,a0,1940 # 80008260 <digits+0x220>
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	aa0080e7          	jalr	-1376(ra) # 80000574 <printf>
    printf("%d\n", faulting_address);
    80001adc:	85a6                	mv	a1,s1
    80001ade:	00007517          	auipc	a0,0x7
    80001ae2:	a9250513          	addi	a0,a0,-1390 # 80008570 <states.0+0x168>
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	a8e080e7          	jalr	-1394(ra) # 80000574 <printf>
    lazy_memory_allocation(faulting_address);
    80001aee:	8526                	mv	a0,s1
    80001af0:	00000097          	auipc	ra,0x0
    80001af4:	f3a080e7          	jalr	-198(ra) # 80001a2a <lazy_memory_allocation>
  }
}
    80001af8:	60e2                	ld	ra,24(sp)
    80001afa:	6442                	ld	s0,16(sp)
    80001afc:	64a2                	ld	s1,8(sp)
    80001afe:	6105                	addi	sp,sp,32
    80001b00:	8082                	ret

0000000080001b02 <minimum_counter_NFUA>:


int minimum_counter_NFUA(){
    80001b02:	1141                	addi	sp,sp,-16
    80001b04:	e406                	sd	ra,8(sp)
    80001b06:	e022                	sd	s0,0(sp)
    80001b08:	0800                	addi	s0,sp,16
  struct proc * p = myproc();
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	56e080e7          	jalr	1390(ra) # 80002078 <myproc>
  uint min_age = -1;
  int index_page = -1;
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001b12:	19850793          	addi	a5,a0,408
    80001b16:	470d                	li	a4,3
  int index_page = -1;
    80001b18:	557d                	li	a0,-1
  uint min_age = -1;
    80001b1a:	55fd                	li	a1,-1
    if (p->paging_meta_data[i].in_memory ){
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    80001b1c:	58fd                	li	a7,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001b1e:	02000813          	li	a6,32
    80001b22:	a039                	j	80001b30 <minimum_counter_NFUA+0x2e>
          min_age = p->paging_meta_data[i].aging;
    80001b24:	420c                	lw	a1,0(a2)
    80001b26:	853a                	mv	a0,a4
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001b28:	2705                	addiw	a4,a4,1
    80001b2a:	07b1                	addi	a5,a5,12
    80001b2c:	01070b63          	beq	a4,a6,80001b42 <minimum_counter_NFUA+0x40>
    if (p->paging_meta_data[i].in_memory ){
    80001b30:	863e                	mv	a2,a5
    80001b32:	43d4                	lw	a3,4(a5)
    80001b34:	daf5                	beqz	a3,80001b28 <minimum_counter_NFUA+0x26>
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    80001b36:	ff1587e3          	beq	a1,a7,80001b24 <minimum_counter_NFUA+0x22>
    80001b3a:	4394                	lw	a3,0(a5)
    80001b3c:	feb6f6e3          	bgeu	a3,a1,80001b28 <minimum_counter_NFUA+0x26>
    80001b40:	b7d5                	j	80001b24 <minimum_counter_NFUA+0x22>
          index_page = i;
        }
      }
  }
  if(min_age == -1)
    80001b42:	57fd                	li	a5,-1
    80001b44:	00f58663          	beq	a1,a5,80001b50 <minimum_counter_NFUA+0x4e>
    panic("page replacment algorithem failed");
  return index_page;
}
    80001b48:	60a2                	ld	ra,8(sp)
    80001b4a:	6402                	ld	s0,0(sp)
    80001b4c:	0141                	addi	sp,sp,16
    80001b4e:	8082                	ret
    panic("page replacment algorithem failed");
    80001b50:	00006517          	auipc	a0,0x6
    80001b54:	73050513          	addi	a0,a0,1840 # 80008280 <digits+0x240>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	9d2080e7          	jalr	-1582(ra) # 8000052a <panic>

0000000080001b60 <count_one_bits>:

int count_one_bits(uint age){
    80001b60:	1141                	addi	sp,sp,-16
    80001b62:	e422                	sd	s0,8(sp)
    80001b64:	0800                	addi	s0,sp,16
  int count = 0;
  while(age) {
    80001b66:	cd01                	beqz	a0,80001b7e <count_one_bits+0x1e>
    80001b68:	87aa                	mv	a5,a0
  int count = 0;
    80001b6a:	4501                	li	a0,0
      count += age & 1;
    80001b6c:	0017f713          	andi	a4,a5,1
    80001b70:	9d39                	addw	a0,a0,a4
      age >>= 1;
    80001b72:	0017d79b          	srliw	a5,a5,0x1
  while(age) {
    80001b76:	fbfd                	bnez	a5,80001b6c <count_one_bits+0xc>
  }
  return count;
}
    80001b78:	6422                	ld	s0,8(sp)
    80001b7a:	0141                	addi	sp,sp,16
    80001b7c:	8082                	ret
  int count = 0;
    80001b7e:	4501                	li	a0,0
    80001b80:	bfe5                	j	80001b78 <count_one_bits+0x18>

0000000080001b82 <minimum_ones>:

int minimum_ones(){
    80001b82:	715d                	addi	sp,sp,-80
    80001b84:	e486                	sd	ra,72(sp)
    80001b86:	e0a2                	sd	s0,64(sp)
    80001b88:	fc26                	sd	s1,56(sp)
    80001b8a:	f84a                	sd	s2,48(sp)
    80001b8c:	f44e                	sd	s3,40(sp)
    80001b8e:	f052                	sd	s4,32(sp)
    80001b90:	ec56                	sd	s5,24(sp)
    80001b92:	e85a                	sd	s6,16(sp)
    80001b94:	e45e                	sd	s7,8(sp)
    80001b96:	e062                	sd	s8,0(sp)
    80001b98:	0880                	addi	s0,sp,80
  struct proc * p = myproc();
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	4de080e7          	jalr	1246(ra) # 80002078 <myproc>
  int min_ones = -1;
  int min_age = -1;
  int index_page = -1;
  uint age;
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001ba2:	19850493          	addi	s1,a0,408
    80001ba6:	490d                	li	s2,3
  int index_page = -1;
    80001ba8:	5c7d                	li	s8,-1
  int min_age = -1;
    80001baa:	5bfd                	li	s7,-1
  int min_ones = -1;
    80001bac:	5a7d                	li	s4,-1
    if (p->paging_meta_data[i].in_memory ){
      age =  p->paging_meta_data[i].aging;
      int count_ones =  count_one_bits(age);
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    80001bae:	5b7d                	li	s6,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001bb0:	02000993          	li	s3,32
    80001bb4:	a809                	j	80001bc6 <minimum_ones+0x44>
        min_ones = count_ones;
        min_age = age;
    80001bb6:	000a8b9b          	sext.w	s7,s5
    80001bba:	8c4a                	mv	s8,s2
        min_ones = count_ones;
    80001bbc:	8a2a                	mv	s4,a0
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001bbe:	2905                	addiw	s2,s2,1
    80001bc0:	04b1                	addi	s1,s1,12
    80001bc2:	03390663          	beq	s2,s3,80001bee <minimum_ones+0x6c>
    if (p->paging_meta_data[i].in_memory ){
    80001bc6:	40dc                	lw	a5,4(s1)
    80001bc8:	dbfd                	beqz	a5,80001bbe <minimum_ones+0x3c>
      age =  p->paging_meta_data[i].aging;
    80001bca:	0004aa83          	lw	s5,0(s1)
      int count_ones =  count_one_bits(age);
    80001bce:	8556                	mv	a0,s5
    80001bd0:	00000097          	auipc	ra,0x0
    80001bd4:	f90080e7          	jalr	-112(ra) # 80001b60 <count_one_bits>
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    80001bd8:	fd6a0fe3          	beq	s4,s6,80001bb6 <minimum_ones+0x34>
    80001bdc:	fd454de3          	blt	a0,s4,80001bb6 <minimum_ones+0x34>
    80001be0:	fd451fe3          	bne	a0,s4,80001bbe <minimum_ones+0x3c>
    80001be4:	000b879b          	sext.w	a5,s7
    80001be8:	fcfafbe3          	bgeu	s5,a5,80001bbe <minimum_ones+0x3c>
    80001bec:	b7e9                	j	80001bb6 <minimum_ones+0x34>
        index_page = i;
      }
    }
  }
  if(min_ones == -1)
    80001bee:	57fd                	li	a5,-1
    80001bf0:	00fa0f63          	beq	s4,a5,80001c0e <minimum_ones+0x8c>
    panic("page replacment algorithem failed");
  return index_page;
}
    80001bf4:	8562                	mv	a0,s8
    80001bf6:	60a6                	ld	ra,72(sp)
    80001bf8:	6406                	ld	s0,64(sp)
    80001bfa:	74e2                	ld	s1,56(sp)
    80001bfc:	7942                	ld	s2,48(sp)
    80001bfe:	79a2                	ld	s3,40(sp)
    80001c00:	7a02                	ld	s4,32(sp)
    80001c02:	6ae2                	ld	s5,24(sp)
    80001c04:	6b42                	ld	s6,16(sp)
    80001c06:	6ba2                	ld	s7,8(sp)
    80001c08:	6c02                	ld	s8,0(sp)
    80001c0a:	6161                	addi	sp,sp,80
    80001c0c:	8082                	ret
    panic("page replacment algorithem failed");
    80001c0e:	00006517          	auipc	a0,0x6
    80001c12:	67250513          	addi	a0,a0,1650 # 80008280 <digits+0x240>
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	914080e7          	jalr	-1772(ra) # 8000052a <panic>

0000000080001c1e <remove_from_queue>:

void remove_from_queue(struct age_queue * q){
    80001c1e:	1141                	addi	sp,sp,-16
    80001c20:	e422                	sd	s0,8(sp)
    80001c22:	0800                	addi	s0,sp,16
  q->front = q->front+1;
    80001c24:	08052783          	lw	a5,128(a0)
    80001c28:	2785                	addiw	a5,a5,1
    80001c2a:	0007869b          	sext.w	a3,a5
   if(q->front == 32) {
    80001c2e:	02000713          	li	a4,32
    80001c32:	00e68c63          	beq	a3,a4,80001c4a <remove_from_queue+0x2c>
  q->front = q->front+1;
    80001c36:	08f52023          	sw	a5,128(a0)
      q->front = 0;
   }
   q->page_counter = q->page_counter-1;
    80001c3a:	08852783          	lw	a5,136(a0)
    80001c3e:	37fd                	addiw	a5,a5,-1
    80001c40:	08f52423          	sw	a5,136(a0)
   
}
    80001c44:	6422                	ld	s0,8(sp)
    80001c46:	0141                	addi	sp,sp,16
    80001c48:	8082                	ret
      q->front = 0;
    80001c4a:	08052023          	sw	zero,128(a0)
    80001c4e:	b7f5                	j	80001c3a <remove_from_queue+0x1c>

0000000080001c50 <insert_to_queue>:
void insert_to_queue(int inserted_page){
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	1000                	addi	s0,sp,32
    80001c5a:	84aa                	mv	s1,a0
  struct proc * process = myproc();
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	41c080e7          	jalr	1052(ra) # 80002078 <myproc>
  struct age_queue * q = &process->queue;
  if(inserted_page >= 3){
    80001c64:	4789                	li	a5,2
    80001c66:	0297d763          	bge	a5,s1,80001c94 <insert_to_queue+0x44>
    if (q->last == 31)
    80001c6a:	37452703          	lw	a4,884(a0)
    80001c6e:	47fd                	li	a5,31
    80001c70:	02f70763          	beq	a4,a5,80001c9e <insert_to_queue+0x4e>
      q->last = -1;
    q->last = q->last + 1;
    80001c74:	37452703          	lw	a4,884(a0)
    80001c78:	2705                	addiw	a4,a4,1
    80001c7a:	0007079b          	sext.w	a5,a4
    80001c7e:	36e52a23          	sw	a4,884(a0)
    q->pages[q->last] =inserted_page;
    80001c82:	078a                	slli	a5,a5,0x2
    80001c84:	97aa                	add	a5,a5,a0
    80001c86:	2e97a823          	sw	s1,752(a5)
    q->page_counter =  q->page_counter + 1;
    80001c8a:	37852783          	lw	a5,888(a0)
    80001c8e:	2785                	addiw	a5,a5,1
    80001c90:	36f52c23          	sw	a5,888(a0)
  }
}
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret
      q->last = -1;
    80001c9e:	57fd                	li	a5,-1
    80001ca0:	36f52a23          	sw	a5,884(a0)
    80001ca4:	bfc1                	j	80001c74 <insert_to_queue+0x24>

0000000080001ca6 <second_fifo>:
int second_fifo(){
    80001ca6:	7139                	addi	sp,sp,-64
    80001ca8:	fc06                	sd	ra,56(sp)
    80001caa:	f822                	sd	s0,48(sp)
    80001cac:	f426                	sd	s1,40(sp)
    80001cae:	f04a                	sd	s2,32(sp)
    80001cb0:	ec4e                	sd	s3,24(sp)
    80001cb2:	e852                	sd	s4,16(sp)
    80001cb4:	e456                	sd	s5,8(sp)
    80001cb6:	e05a                	sd	s6,0(sp)
    80001cb8:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	3be080e7          	jalr	958(ra) # 80002078 <myproc>
    80001cc2:	84aa                	mv	s1,a0
  struct age_queue * q = &(p->queue);
    80001cc4:	2f050993          	addi	s3,a0,752
  int current_page;
  int page_counter = q->page_counter;
    80001cc8:	37852a03          	lw	s4,888(a0)
  for (int i = 0; i<page_counter; i++){
    80001ccc:	05405f63          	blez	s4,80001d2a <second_fifo+0x84>
    80001cd0:	4901                	li	s2,0
      remove_from_queue(q);
      return current_page; //the file will no longer be in the memory and will be removed next time
    }
    else{ //the page has been accsesed
      *pte = *pte & (~PTE_A); //make A bit off
      printf("removing accsesed bit from %d", current_page);
    80001cd2:	00006a97          	auipc	s5,0x6
    80001cd6:	5e6a8a93          	addi	s5,s5,1510 # 800082b8 <digits+0x278>
    current_page = q->pages[q->front];
    80001cda:	3704a783          	lw	a5,880(s1)
    80001cde:	078a                	slli	a5,a5,0x2
    80001ce0:	97a6                	add	a5,a5,s1
    80001ce2:	2f07ab03          	lw	s6,752(a5)
    pte_t * pte = walk(p->pagetable, current_page*PGSIZE,0);
    80001ce6:	4601                	li	a2,0
    80001ce8:	00cb159b          	slliw	a1,s6,0xc
    80001cec:	68a8                	ld	a0,80(s1)
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	2c8080e7          	jalr	712(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001cf6:	611c                	ld	a5,0(a0)
    if(!(pte_flags & PTE_A)){
    80001cf8:	0407f713          	andi	a4,a5,64
    80001cfc:	cf29                	beqz	a4,80001d56 <second_fifo+0xb0>
      *pte = *pte & (~PTE_A); //make A bit off
    80001cfe:	fbf7f793          	andi	a5,a5,-65
    80001d02:	e11c                	sd	a5,0(a0)
      printf("removing accsesed bit from %d", current_page);
    80001d04:	85da                	mv	a1,s6
    80001d06:	8556                	mv	a0,s5
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	86c080e7          	jalr	-1940(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001d10:	854e                	mv	a0,s3
    80001d12:	00000097          	auipc	ra,0x0
    80001d16:	f0c080e7          	jalr	-244(ra) # 80001c1e <remove_from_queue>
      insert_to_queue(current_page);
    80001d1a:	855a                	mv	a0,s6
    80001d1c:	00000097          	auipc	ra,0x0
    80001d20:	f34080e7          	jalr	-204(ra) # 80001c50 <insert_to_queue>
  for (int i = 0; i<page_counter; i++){
    80001d24:	2905                	addiw	s2,s2,1
    80001d26:	fb2a1ae3          	bne	s4,s2,80001cda <second_fifo+0x34>
    }
  }
  current_page = q->pages[q->front];
    80001d2a:	3704a783          	lw	a5,880(s1)
    80001d2e:	078a                	slli	a5,a5,0x2
    80001d30:	94be                	add	s1,s1,a5
    80001d32:	2f04ab03          	lw	s6,752(s1)
  remove_from_queue(q);
    80001d36:	854e                	mv	a0,s3
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	ee6080e7          	jalr	-282(ra) # 80001c1e <remove_from_queue>
  return current_page;
}
    80001d40:	855a                	mv	a0,s6
    80001d42:	70e2                	ld	ra,56(sp)
    80001d44:	7442                	ld	s0,48(sp)
    80001d46:	74a2                	ld	s1,40(sp)
    80001d48:	7902                	ld	s2,32(sp)
    80001d4a:	69e2                	ld	s3,24(sp)
    80001d4c:	6a42                	ld	s4,16(sp)
    80001d4e:	6aa2                	ld	s5,8(sp)
    80001d50:	6b02                	ld	s6,0(sp)
    80001d52:	6121                	addi	sp,sp,64
    80001d54:	8082                	ret
      printf("not accsesed %d", current_page);
    80001d56:	85da                	mv	a1,s6
    80001d58:	00006517          	auipc	a0,0x6
    80001d5c:	55050513          	addi	a0,a0,1360 # 800082a8 <digits+0x268>
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	814080e7          	jalr	-2028(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001d68:	854e                	mv	a0,s3
    80001d6a:	00000097          	auipc	ra,0x0
    80001d6e:	eb4080e7          	jalr	-332(ra) # 80001c1e <remove_from_queue>
      return current_page; //the file will no longer be in the memory and will be removed next time
    80001d72:	b7f9                	j	80001d40 <second_fifo+0x9a>

0000000080001d74 <minimum_advanicing_queue>:

int minimum_advanicing_queue(){
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	1000                	addi	s0,sp,32
  struct proc * p = myproc();
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	2fa080e7          	jalr	762(ra) # 80002078 <myproc>
  struct age_queue * q = &(p->queue);
  int current_page = q->pages[q->front];
    80001d86:	37052783          	lw	a5,880(a0)
    80001d8a:	078a                	slli	a5,a5,0x2
    80001d8c:	97aa                	add	a5,a5,a0
    80001d8e:	2f07a483          	lw	s1,752(a5)
  remove_from_queue(q);
    80001d92:	2f050513          	addi	a0,a0,752
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e88080e7          	jalr	-376(ra) # 80001c1e <remove_from_queue>
  return current_page;
}
    80001d9e:	8526                	mv	a0,s1
    80001da0:	60e2                	ld	ra,24(sp)
    80001da2:	6442                	ld	s0,16(sp)
    80001da4:	64a2                	ld	s1,8(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret

0000000080001daa <find_file_to_remove>:
int find_file_to_remove(){
    80001daa:	1141                	addi	sp,sp,-16
    80001dac:	e422                	sd	s0,8(sp)
    80001dae:	0800                	addi	s0,sp,16
  #endif
  #if SELECTION == AQ
    return minimum_advanicing_queue(); 
  #endif
  return 0;
}
    80001db0:	4501                	li	a0,0
    80001db2:	6422                	ld	s0,8(sp)
    80001db4:	0141                	addi	sp,sp,16
    80001db6:	8082                	ret

0000000080001db8 <shift_counter>:

void shift_counter(){
    80001db8:	7139                	addi	sp,sp,-64
    80001dba:	fc06                	sd	ra,56(sp)
    80001dbc:	f822                	sd	s0,48(sp)
    80001dbe:	f426                	sd	s1,40(sp)
    80001dc0:	f04a                	sd	s2,32(sp)
    80001dc2:	ec4e                	sd	s3,24(sp)
    80001dc4:	e852                	sd	s4,16(sp)
    80001dc6:	e456                	sd	s5,8(sp)
    80001dc8:	0080                	addi	s0,sp,64
 struct proc * p = myproc();
    80001dca:	00000097          	auipc	ra,0x0
    80001dce:	2ae080e7          	jalr	686(ra) # 80002078 <myproc>
 pte_t * pte;
 for(int i=0; i<32; i++){
    80001dd2:	17450913          	addi	s2,a0,372
 struct proc * p = myproc();
    80001dd6:	4481                	li	s1,0
      uint page_virtual_address = i*PGSIZE;
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
      if(*pte & PTE_V){
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
        if(*pte & PTE_A){
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80001dd8:	80000ab7          	lui	s5,0x80000
 for(int i=0; i<32; i++){
    80001ddc:	6a05                	lui	s4,0x1
    80001dde:	000209b7          	lui	s3,0x20
    80001de2:	a029                	j	80001dec <shift_counter+0x34>
    80001de4:	94d2                	add	s1,s1,s4
    80001de6:	0931                	addi	s2,s2,12
    80001de8:	05348363          	beq	s1,s3,80001e2e <shift_counter+0x76>
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	28c080e7          	jalr	652(ra) # 80002078 <myproc>
    80001df4:	4601                	li	a2,0
    80001df6:	85a6                	mv	a1,s1
    80001df8:	6928                	ld	a0,80(a0)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	1bc080e7          	jalr	444(ra) # 80000fb6 <walk>
      if(*pte & PTE_V){
    80001e02:	611c                	ld	a5,0(a0)
    80001e04:	8b85                	andi	a5,a5,1
    80001e06:	dff9                	beqz	a5,80001de4 <shift_counter+0x2c>
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
    80001e08:	00092783          	lw	a5,0(s2)
    80001e0c:	0017d79b          	srliw	a5,a5,0x1
    80001e10:	00f92023          	sw	a5,0(s2)
        if(*pte & PTE_A){
    80001e14:	6118                	ld	a4,0(a0)
    80001e16:	04077713          	andi	a4,a4,64
    80001e1a:	d769                	beqz	a4,80001de4 <shift_counter+0x2c>
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80001e1c:	0157e7b3          	or	a5,a5,s5
    80001e20:	00f92023          	sw	a5,0(s2)
          *pte = *pte & (~PTE_A); //turn off
    80001e24:	611c                	ld	a5,0(a0)
    80001e26:	fbf7f793          	andi	a5,a5,-65
    80001e2a:	e11c                	sd	a5,0(a0)
    80001e2c:	bf65                	j	80001de4 <shift_counter+0x2c>
        }
      }
    }
}
    80001e2e:	70e2                	ld	ra,56(sp)
    80001e30:	7442                	ld	s0,48(sp)
    80001e32:	74a2                	ld	s1,40(sp)
    80001e34:	7902                	ld	s2,32(sp)
    80001e36:	69e2                	ld	s3,24(sp)
    80001e38:	6a42                	ld	s4,16(sp)
    80001e3a:	6aa2                	ld	s5,8(sp)
    80001e3c:	6121                	addi	sp,sp,64
    80001e3e:	8082                	ret

0000000080001e40 <shift_queue>:
void shift_queue(){
    80001e40:	7139                	addi	sp,sp,-64
    80001e42:	fc06                	sd	ra,56(sp)
    80001e44:	f822                	sd	s0,48(sp)
    80001e46:	f426                	sd	s1,40(sp)
    80001e48:	f04a                	sd	s2,32(sp)
    80001e4a:	ec4e                	sd	s3,24(sp)
    80001e4c:	e852                	sd	s4,16(sp)
    80001e4e:	e456                	sd	s5,8(sp)
    80001e50:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	226080e7          	jalr	550(ra) # 80002078 <myproc>
  struct age_queue * q = &(p->queue);
  int front = q->front;
    80001e5a:	37052a03          	lw	s4,880(a0)
  int page_count = q->page_counter;
    80001e5e:	37852903          	lw	s2,888(a0)
  for(int i = page_count-2; i >0; i--){ //front + i is the index of the one before last page in the queue
    80001e62:	4789                	li	a5,2
    80001e64:	0727db63          	bge	a5,s2,80001eda <shift_queue+0x9a>
    80001e68:	89aa                	mv	s3,a0
    80001e6a:	0149093b          	addw	s2,s2,s4
    80001e6e:	397d                	addiw	s2,s2,-1
    80001e70:	2a05                	addiw	s4,s4,1
    80001e72:	a801                	j	80001e82 <shift_queue+0x42>
    uint pte_flags = PTE_FLAGS(*pte);
    if(pte_flags & PTE_A){
      q->pages[(front + i)%32] = q->pages[(front + i + 1)%32];
      q->pages[(front + 1 + i)%32] = temp;; 
    }
    *pte = *pte & (~PTE_A);
    80001e74:	611c                	ld	a5,0(a0)
    80001e76:	fbf7f793          	andi	a5,a5,-65
    80001e7a:	e11c                	sd	a5,0(a0)
  for(int i = page_count-2; i >0; i--){ //front + i is the index of the one before last page in the queue
    80001e7c:	397d                	addiw	s2,s2,-1
    80001e7e:	05490e63          	beq	s2,s4,80001eda <shift_queue+0x9a>
    int temp = q->pages[(front+ i)%32];
    80001e82:	fff9079b          	addiw	a5,s2,-1
    80001e86:	41f7d49b          	sraiw	s1,a5,0x1f
    80001e8a:	01b4d71b          	srliw	a4,s1,0x1b
    80001e8e:	00e784bb          	addw	s1,a5,a4
    80001e92:	88fd                	andi	s1,s1,31
    80001e94:	9c99                	subw	s1,s1,a4
    80001e96:	048a                	slli	s1,s1,0x2
    80001e98:	94ce                	add	s1,s1,s3
    80001e9a:	2f04aa83          	lw	s5,752(s1)
    pte_t * pte = walk(p->pagetable, temp*PGSIZE,0);
    80001e9e:	4601                	li	a2,0
    80001ea0:	00ca959b          	slliw	a1,s5,0xc
    80001ea4:	0509b503          	ld	a0,80(s3) # 20050 <_entry-0x7ffdffb0>
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	10e080e7          	jalr	270(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001eb0:	611c                	ld	a5,0(a0)
    if(pte_flags & PTE_A){
    80001eb2:	0407f793          	andi	a5,a5,64
    80001eb6:	dfdd                	beqz	a5,80001e74 <shift_queue+0x34>
      q->pages[(front + i)%32] = q->pages[(front + i + 1)%32];
    80001eb8:	41f9579b          	sraiw	a5,s2,0x1f
    80001ebc:	01b7d71b          	srliw	a4,a5,0x1b
    80001ec0:	012707bb          	addw	a5,a4,s2
    80001ec4:	8bfd                	andi	a5,a5,31
    80001ec6:	9f99                	subw	a5,a5,a4
    80001ec8:	078a                	slli	a5,a5,0x2
    80001eca:	97ce                	add	a5,a5,s3
    80001ecc:	2f07a703          	lw	a4,752(a5)
    80001ed0:	2ee4a823          	sw	a4,752(s1)
      q->pages[(front + 1 + i)%32] = temp;; 
    80001ed4:	2f57a823          	sw	s5,752(a5)
    80001ed8:	bf71                	j	80001e74 <shift_queue+0x34>
  }
}
    80001eda:	70e2                	ld	ra,56(sp)
    80001edc:	7442                	ld	s0,48(sp)
    80001ede:	74a2                	ld	s1,40(sp)
    80001ee0:	7902                	ld	s2,32(sp)
    80001ee2:	69e2                	ld	s3,24(sp)
    80001ee4:	6a42                	ld	s4,16(sp)
    80001ee6:	6aa2                	ld	s5,8(sp)
    80001ee8:	6121                	addi	sp,sp,64
    80001eea:	8082                	ret

0000000080001eec <update_aging_algorithms>:
//update aging algorithm when the process returns to the scheduler
void
update_aging_algorithms(void){
    80001eec:	1141                	addi	sp,sp,-16
    80001eee:	e422                	sd	s0,8(sp)
    80001ef0:	0800                	addi	s0,sp,16
  #if SELECTION == AQ
    shift_queue();
  #endif
return;

}
    80001ef2:	6422                	ld	s0,8(sp)
    80001ef4:	0141                	addi	sp,sp,16
    80001ef6:	8082                	ret

0000000080001ef8 <init_aging>:

uint init_aging(int fifo_init_pages){
    80001ef8:	1141                	addi	sp,sp,-16
    80001efa:	e422                	sd	s0,8(sp)
    80001efc:	0800                	addi	s0,sp,16
  #endif
  #if SELECTION==SCFIFO
    return insert_to_queue(fifo_init_pages);
  #endif 
  return 0;
}
    80001efe:	4501                	li	a0,0
    80001f00:	6422                	ld	s0,8(sp)
    80001f02:	0141                	addi	sp,sp,16
    80001f04:	8082                	ret

0000000080001f06 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001f06:	7139                	addi	sp,sp,-64
    80001f08:	fc06                	sd	ra,56(sp)
    80001f0a:	f822                	sd	s0,48(sp)
    80001f0c:	f426                	sd	s1,40(sp)
    80001f0e:	f04a                	sd	s2,32(sp)
    80001f10:	ec4e                	sd	s3,24(sp)
    80001f12:	e852                	sd	s4,16(sp)
    80001f14:	e456                	sd	s5,8(sp)
    80001f16:	e05a                	sd	s6,0(sp)
    80001f18:	0080                	addi	s0,sp,64
    80001f1a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f1c:	0000f497          	auipc	s1,0xf
    80001f20:	7b448493          	addi	s1,s1,1972 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001f24:	8b26                	mv	s6,s1
    80001f26:	00006a97          	auipc	s5,0x6
    80001f2a:	0daa8a93          	addi	s5,s5,218 # 80008000 <etext>
    80001f2e:	04000937          	lui	s2,0x4000
    80001f32:	197d                	addi	s2,s2,-1
    80001f34:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f36:	0001da17          	auipc	s4,0x1d
    80001f3a:	79aa0a13          	addi	s4,s4,1946 # 8001f6d0 <tickslock>
    char *pa = kalloc();
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	ba4080e7          	jalr	-1116(ra) # 80000ae2 <kalloc>
    80001f46:	862a                	mv	a2,a0
    if(pa == 0)
    80001f48:	c131                	beqz	a0,80001f8c <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001f4a:	416485b3          	sub	a1,s1,s6
    80001f4e:	859d                	srai	a1,a1,0x7
    80001f50:	000ab783          	ld	a5,0(s5)
    80001f54:	02f585b3          	mul	a1,a1,a5
    80001f58:	2585                	addiw	a1,a1,1
    80001f5a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001f5e:	4719                	li	a4,6
    80001f60:	6685                	lui	a3,0x1
    80001f62:	40b905b3          	sub	a1,s2,a1
    80001f66:	854e                	mv	a0,s3
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	1c4080e7          	jalr	452(ra) # 8000112c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f70:	38048493          	addi	s1,s1,896
    80001f74:	fd4495e3          	bne	s1,s4,80001f3e <proc_mapstacks+0x38>
  }
}
    80001f78:	70e2                	ld	ra,56(sp)
    80001f7a:	7442                	ld	s0,48(sp)
    80001f7c:	74a2                	ld	s1,40(sp)
    80001f7e:	7902                	ld	s2,32(sp)
    80001f80:	69e2                	ld	s3,24(sp)
    80001f82:	6a42                	ld	s4,16(sp)
    80001f84:	6aa2                	ld	s5,8(sp)
    80001f86:	6b02                	ld	s6,0(sp)
    80001f88:	6121                	addi	sp,sp,64
    80001f8a:	8082                	ret
      panic("kalloc");
    80001f8c:	00006517          	auipc	a0,0x6
    80001f90:	34c50513          	addi	a0,a0,844 # 800082d8 <digits+0x298>
    80001f94:	ffffe097          	auipc	ra,0xffffe
    80001f98:	596080e7          	jalr	1430(ra) # 8000052a <panic>

0000000080001f9c <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001f9c:	7139                	addi	sp,sp,-64
    80001f9e:	fc06                	sd	ra,56(sp)
    80001fa0:	f822                	sd	s0,48(sp)
    80001fa2:	f426                	sd	s1,40(sp)
    80001fa4:	f04a                	sd	s2,32(sp)
    80001fa6:	ec4e                	sd	s3,24(sp)
    80001fa8:	e852                	sd	s4,16(sp)
    80001faa:	e456                	sd	s5,8(sp)
    80001fac:	e05a                	sd	s6,0(sp)
    80001fae:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001fb0:	00006597          	auipc	a1,0x6
    80001fb4:	33058593          	addi	a1,a1,816 # 800082e0 <digits+0x2a0>
    80001fb8:	0000f517          	auipc	a0,0xf
    80001fbc:	2e850513          	addi	a0,a0,744 # 800112a0 <pid_lock>
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	b82080e7          	jalr	-1150(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001fc8:	00006597          	auipc	a1,0x6
    80001fcc:	32058593          	addi	a1,a1,800 # 800082e8 <digits+0x2a8>
    80001fd0:	0000f517          	auipc	a0,0xf
    80001fd4:	2e850513          	addi	a0,a0,744 # 800112b8 <wait_lock>
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	b6a080e7          	jalr	-1174(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	0000f497          	auipc	s1,0xf
    80001fe4:	6f048493          	addi	s1,s1,1776 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001fe8:	00006b17          	auipc	s6,0x6
    80001fec:	310b0b13          	addi	s6,s6,784 # 800082f8 <digits+0x2b8>
      p->kstack = KSTACK((int) (p - proc));
    80001ff0:	8aa6                	mv	s5,s1
    80001ff2:	00006a17          	auipc	s4,0x6
    80001ff6:	00ea0a13          	addi	s4,s4,14 # 80008000 <etext>
    80001ffa:	04000937          	lui	s2,0x4000
    80001ffe:	197d                	addi	s2,s2,-1
    80002000:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002002:	0001d997          	auipc	s3,0x1d
    80002006:	6ce98993          	addi	s3,s3,1742 # 8001f6d0 <tickslock>
      initlock(&p->lock, "proc");
    8000200a:	85da                	mv	a1,s6
    8000200c:	8526                	mv	a0,s1
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	b34080e7          	jalr	-1228(ra) # 80000b42 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002016:	415487b3          	sub	a5,s1,s5
    8000201a:	879d                	srai	a5,a5,0x7
    8000201c:	000a3703          	ld	a4,0(s4)
    80002020:	02e787b3          	mul	a5,a5,a4
    80002024:	2785                	addiw	a5,a5,1
    80002026:	00d7979b          	slliw	a5,a5,0xd
    8000202a:	40f907b3          	sub	a5,s2,a5
    8000202e:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80002030:	38048493          	addi	s1,s1,896
    80002034:	fd349be3          	bne	s1,s3,8000200a <procinit+0x6e>
  }
}
    80002038:	70e2                	ld	ra,56(sp)
    8000203a:	7442                	ld	s0,48(sp)
    8000203c:	74a2                	ld	s1,40(sp)
    8000203e:	7902                	ld	s2,32(sp)
    80002040:	69e2                	ld	s3,24(sp)
    80002042:	6a42                	ld	s4,16(sp)
    80002044:	6aa2                	ld	s5,8(sp)
    80002046:	6b02                	ld	s6,0(sp)
    80002048:	6121                	addi	sp,sp,64
    8000204a:	8082                	ret

000000008000204c <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000204c:	1141                	addi	sp,sp,-16
    8000204e:	e422                	sd	s0,8(sp)
    80002050:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80002052:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80002054:	2501                	sext.w	a0,a0
    80002056:	6422                	ld	s0,8(sp)
    80002058:	0141                	addi	sp,sp,16
    8000205a:	8082                	ret

000000008000205c <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    8000205c:	1141                	addi	sp,sp,-16
    8000205e:	e422                	sd	s0,8(sp)
    80002060:	0800                	addi	s0,sp,16
    80002062:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
  return c;
}
    80002068:	0000f517          	auipc	a0,0xf
    8000206c:	26850513          	addi	a0,a0,616 # 800112d0 <cpus>
    80002070:	953e                	add	a0,a0,a5
    80002072:	6422                	ld	s0,8(sp)
    80002074:	0141                	addi	sp,sp,16
    80002076:	8082                	ret

0000000080002078 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80002078:	1101                	addi	sp,sp,-32
    8000207a:	ec06                	sd	ra,24(sp)
    8000207c:	e822                	sd	s0,16(sp)
    8000207e:	e426                	sd	s1,8(sp)
    80002080:	1000                	addi	s0,sp,32
  push_off();
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	b04080e7          	jalr	-1276(ra) # 80000b86 <push_off>
    8000208a:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000208c:	2781                	sext.w	a5,a5
    8000208e:	079e                	slli	a5,a5,0x7
    80002090:	0000f717          	auipc	a4,0xf
    80002094:	21070713          	addi	a4,a4,528 # 800112a0 <pid_lock>
    80002098:	97ba                	add	a5,a5,a4
    8000209a:	7b84                	ld	s1,48(a5)
  pop_off();
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b8a080e7          	jalr	-1142(ra) # 80000c26 <pop_off>
  return p;
}
    800020a4:	8526                	mv	a0,s1
    800020a6:	60e2                	ld	ra,24(sp)
    800020a8:	6442                	ld	s0,16(sp)
    800020aa:	64a2                	ld	s1,8(sp)
    800020ac:	6105                	addi	sp,sp,32
    800020ae:	8082                	ret

00000000800020b0 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800020b0:	1141                	addi	sp,sp,-16
    800020b2:	e406                	sd	ra,8(sp)
    800020b4:	e022                	sd	s0,0(sp)
    800020b6:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800020b8:	00000097          	auipc	ra,0x0
    800020bc:	fc0080e7          	jalr	-64(ra) # 80002078 <myproc>
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	bc6080e7          	jalr	-1082(ra) # 80000c86 <release>

  if (first) {
    800020c8:	00007797          	auipc	a5,0x7
    800020cc:	8c87a783          	lw	a5,-1848(a5) # 80008990 <first.1>
    800020d0:	eb89                	bnez	a5,800020e2 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800020d2:	00001097          	auipc	ra,0x1
    800020d6:	e24080e7          	jalr	-476(ra) # 80002ef6 <usertrapret>
}
    800020da:	60a2                	ld	ra,8(sp)
    800020dc:	6402                	ld	s0,0(sp)
    800020de:	0141                	addi	sp,sp,16
    800020e0:	8082                	ret
    first = 0;
    800020e2:	00007797          	auipc	a5,0x7
    800020e6:	8a07a723          	sw	zero,-1874(a5) # 80008990 <first.1>
    fsinit(ROOTDEV);
    800020ea:	4505                	li	a0,1
    800020ec:	00002097          	auipc	ra,0x2
    800020f0:	b6a080e7          	jalr	-1174(ra) # 80003c56 <fsinit>
    800020f4:	bff9                	j	800020d2 <forkret+0x22>

00000000800020f6 <allocpid>:
allocpid() {
    800020f6:	1101                	addi	sp,sp,-32
    800020f8:	ec06                	sd	ra,24(sp)
    800020fa:	e822                	sd	s0,16(sp)
    800020fc:	e426                	sd	s1,8(sp)
    800020fe:	e04a                	sd	s2,0(sp)
    80002100:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80002102:	0000f917          	auipc	s2,0xf
    80002106:	19e90913          	addi	s2,s2,414 # 800112a0 <pid_lock>
    8000210a:	854a                	mv	a0,s2
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	ac6080e7          	jalr	-1338(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80002114:	00007797          	auipc	a5,0x7
    80002118:	88078793          	addi	a5,a5,-1920 # 80008994 <nextpid>
    8000211c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000211e:	0014871b          	addiw	a4,s1,1
    80002122:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80002124:	854a                	mv	a0,s2
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	b60080e7          	jalr	-1184(ra) # 80000c86 <release>
}
    8000212e:	8526                	mv	a0,s1
    80002130:	60e2                	ld	ra,24(sp)
    80002132:	6442                	ld	s0,16(sp)
    80002134:	64a2                	ld	s1,8(sp)
    80002136:	6902                	ld	s2,0(sp)
    80002138:	6105                	addi	sp,sp,32
    8000213a:	8082                	ret

000000008000213c <proc_pagetable>:
{
    8000213c:	1101                	addi	sp,sp,-32
    8000213e:	ec06                	sd	ra,24(sp)
    80002140:	e822                	sd	s0,16(sp)
    80002142:	e426                	sd	s1,8(sp)
    80002144:	e04a                	sd	s2,0(sp)
    80002146:	1000                	addi	s0,sp,32
    80002148:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	1cc080e7          	jalr	460(ra) # 80001316 <uvmcreate>
    80002152:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80002154:	c121                	beqz	a0,80002194 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80002156:	4729                	li	a4,10
    80002158:	00005697          	auipc	a3,0x5
    8000215c:	ea868693          	addi	a3,a3,-344 # 80007000 <_trampoline>
    80002160:	6605                	lui	a2,0x1
    80002162:	040005b7          	lui	a1,0x4000
    80002166:	15fd                	addi	a1,a1,-1
    80002168:	05b2                	slli	a1,a1,0xc
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	f34080e7          	jalr	-204(ra) # 8000109e <mappages>
    80002172:	02054863          	bltz	a0,800021a2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002176:	4719                	li	a4,6
    80002178:	05893683          	ld	a3,88(s2)
    8000217c:	6605                	lui	a2,0x1
    8000217e:	020005b7          	lui	a1,0x2000
    80002182:	15fd                	addi	a1,a1,-1
    80002184:	05b6                	slli	a1,a1,0xd
    80002186:	8526                	mv	a0,s1
    80002188:	fffff097          	auipc	ra,0xfffff
    8000218c:	f16080e7          	jalr	-234(ra) # 8000109e <mappages>
    80002190:	02054163          	bltz	a0,800021b2 <proc_pagetable+0x76>
}
    80002194:	8526                	mv	a0,s1
    80002196:	60e2                	ld	ra,24(sp)
    80002198:	6442                	ld	s0,16(sp)
    8000219a:	64a2                	ld	s1,8(sp)
    8000219c:	6902                	ld	s2,0(sp)
    8000219e:	6105                	addi	sp,sp,32
    800021a0:	8082                	ret
    uvmfree(pagetable, 0);
    800021a2:	4581                	li	a1,0
    800021a4:	8526                	mv	a0,s1
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	36c080e7          	jalr	876(ra) # 80001512 <uvmfree>
    return 0;
    800021ae:	4481                	li	s1,0
    800021b0:	b7d5                	j	80002194 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800021b2:	4681                	li	a3,0
    800021b4:	4605                	li	a2,1
    800021b6:	040005b7          	lui	a1,0x4000
    800021ba:	15fd                	addi	a1,a1,-1
    800021bc:	05b2                	slli	a1,a1,0xc
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	092080e7          	jalr	146(ra) # 80001252 <uvmunmap>
    uvmfree(pagetable, 0);
    800021c8:	4581                	li	a1,0
    800021ca:	8526                	mv	a0,s1
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	346080e7          	jalr	838(ra) # 80001512 <uvmfree>
    return 0;
    800021d4:	4481                	li	s1,0
    800021d6:	bf7d                	j	80002194 <proc_pagetable+0x58>

00000000800021d8 <proc_freepagetable>:
{
    800021d8:	1101                	addi	sp,sp,-32
    800021da:	ec06                	sd	ra,24(sp)
    800021dc:	e822                	sd	s0,16(sp)
    800021de:	e426                	sd	s1,8(sp)
    800021e0:	e04a                	sd	s2,0(sp)
    800021e2:	1000                	addi	s0,sp,32
    800021e4:	84aa                	mv	s1,a0
    800021e6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    800021e8:	4681                	li	a3,0
    800021ea:	4605                	li	a2,1
    800021ec:	040005b7          	lui	a1,0x4000
    800021f0:	15fd                	addi	a1,a1,-1
    800021f2:	05b2                	slli	a1,a1,0xc
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	05e080e7          	jalr	94(ra) # 80001252 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    800021fc:	4681                	li	a3,0
    800021fe:	4605                	li	a2,1
    80002200:	020005b7          	lui	a1,0x2000
    80002204:	15fd                	addi	a1,a1,-1
    80002206:	05b6                	slli	a1,a1,0xd
    80002208:	8526                	mv	a0,s1
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	048080e7          	jalr	72(ra) # 80001252 <uvmunmap>
  uvmfree(pagetable, sz);
    80002212:	85ca                	mv	a1,s2
    80002214:	8526                	mv	a0,s1
    80002216:	fffff097          	auipc	ra,0xfffff
    8000221a:	2fc080e7          	jalr	764(ra) # 80001512 <uvmfree>
}
    8000221e:	60e2                	ld	ra,24(sp)
    80002220:	6442                	ld	s0,16(sp)
    80002222:	64a2                	ld	s1,8(sp)
    80002224:	6902                	ld	s2,0(sp)
    80002226:	6105                	addi	sp,sp,32
    80002228:	8082                	ret

000000008000222a <freeproc>:
{ 
    8000222a:	1101                	addi	sp,sp,-32
    8000222c:	ec06                	sd	ra,24(sp)
    8000222e:	e822                	sd	s0,16(sp)
    80002230:	e426                	sd	s1,8(sp)
    80002232:	1000                	addi	s0,sp,32
    80002234:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002236:	6d28                	ld	a0,88(a0)
    80002238:	c509                	beqz	a0,80002242 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000223a:	ffffe097          	auipc	ra,0xffffe
    8000223e:	79c080e7          	jalr	1948(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80002242:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80002246:	68a8                	ld	a0,80(s1)
    80002248:	c511                	beqz	a0,80002254 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    8000224a:	64ac                	ld	a1,72(s1)
    8000224c:	00000097          	auipc	ra,0x0
    80002250:	f8c080e7          	jalr	-116(ra) # 800021d8 <proc_freepagetable>
  p->pagetable = 0;
    80002254:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80002258:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000225c:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80002260:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80002264:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80002268:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    8000226c:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002270:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002274:	0004ac23          	sw	zero,24(s1)
}
    80002278:	60e2                	ld	ra,24(sp)
    8000227a:	6442                	ld	s0,16(sp)
    8000227c:	64a2                	ld	s1,8(sp)
    8000227e:	6105                	addi	sp,sp,32
    80002280:	8082                	ret

0000000080002282 <allocproc>:
{
    80002282:	7179                	addi	sp,sp,-48
    80002284:	f406                	sd	ra,40(sp)
    80002286:	f022                	sd	s0,32(sp)
    80002288:	ec26                	sd	s1,24(sp)
    8000228a:	e84a                	sd	s2,16(sp)
    8000228c:	e44e                	sd	s3,8(sp)
    8000228e:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80002290:	0000f497          	auipc	s1,0xf
    80002294:	44048493          	addi	s1,s1,1088 # 800116d0 <proc>
    80002298:	0001d997          	auipc	s3,0x1d
    8000229c:	43898993          	addi	s3,s3,1080 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    800022a0:	8926                	mv	s2,s1
    800022a2:	8526                	mv	a0,s1
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	92e080e7          	jalr	-1746(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    800022ac:	4c9c                	lw	a5,24(s1)
    800022ae:	cf81                	beqz	a5,800022c6 <allocproc+0x44>
      release(&p->lock);
    800022b0:	8526                	mv	a0,s1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9d4080e7          	jalr	-1580(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022ba:	38048493          	addi	s1,s1,896
    800022be:	ff3491e3          	bne	s1,s3,800022a0 <allocproc+0x1e>
  return 0;
    800022c2:	4481                	li	s1,0
    800022c4:	a071                	j	80002350 <allocproc+0xce>
  p->pid = allocpid();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	e30080e7          	jalr	-464(ra) # 800020f6 <allocpid>
    800022ce:	d888                	sw	a0,48(s1)
  p->state = USED;
    800022d0:	4785                	li	a5,1
    800022d2:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	80e080e7          	jalr	-2034(ra) # 80000ae2 <kalloc>
    800022dc:	89aa                	mv	s3,a0
    800022de:	eca8                	sd	a0,88(s1)
    800022e0:	c141                	beqz	a0,80002360 <allocproc+0xde>
  p->pagetable = proc_pagetable(p);
    800022e2:	8526                	mv	a0,s1
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	e58080e7          	jalr	-424(ra) # 8000213c <proc_pagetable>
    800022ec:	89aa                	mv	s3,a0
    800022ee:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800022f0:	c541                	beqz	a0,80002378 <allocproc+0xf6>
  memset(&p->context, 0, sizeof(p->context));
    800022f2:	07000613          	li	a2,112
    800022f6:	4581                	li	a1,0
    800022f8:	06048513          	addi	a0,s1,96
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	9d2080e7          	jalr	-1582(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80002304:	00000797          	auipc	a5,0x0
    80002308:	dac78793          	addi	a5,a5,-596 # 800020b0 <forkret>
    8000230c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000230e:	60bc                	ld	a5,64(s1)
    80002310:	6705                	lui	a4,0x1
    80002312:	97ba                	add	a5,a5,a4
    80002314:	f4bc                	sd	a5,104(s1)
 for(int i=0;i<32;i++){
    80002316:	17048793          	addi	a5,s1,368
    8000231a:	2f048693          	addi	a3,s1,752
    p->paging_meta_data[i].offset = -1;
    8000231e:	577d                	li	a4,-1
    80002320:	c398                	sw	a4,0(a5)
    p->paging_meta_data[i].aging = 0;
    80002322:	0007a223          	sw	zero,4(a5)
    p->paging_meta_data[i].in_memory = 0;
    80002326:	0007a423          	sw	zero,8(a5)
 for(int i=0;i<32;i++){
    8000232a:	07b1                	addi	a5,a5,12
    8000232c:	fed79ae3          	bne	a5,a3,80002320 <allocproc+0x9e>
  p->queue.front = 0;
    80002330:	3604a823          	sw	zero,880(s1)
  p->queue.last = -1;
    80002334:	57fd                	li	a5,-1
    80002336:	36f4aa23          	sw	a5,884(s1)
  p->queue.page_counter = 0;
    8000233a:	3604ac23          	sw	zero,888(s1)
  for(int i=0; i<32; i++){
    8000233e:	2f048793          	addi	a5,s1,752
    80002342:	37090713          	addi	a4,s2,880
    p->queue.pages[i] = -1;
    80002346:	56fd                	li	a3,-1
    80002348:	c394                	sw	a3,0(a5)
  for(int i=0; i<32; i++){
    8000234a:	0791                	addi	a5,a5,4
    8000234c:	fee79ee3          	bne	a5,a4,80002348 <allocproc+0xc6>
}
    80002350:	8526                	mv	a0,s1
    80002352:	70a2                	ld	ra,40(sp)
    80002354:	7402                	ld	s0,32(sp)
    80002356:	64e2                	ld	s1,24(sp)
    80002358:	6942                	ld	s2,16(sp)
    8000235a:	69a2                	ld	s3,8(sp)
    8000235c:	6145                	addi	sp,sp,48
    8000235e:	8082                	ret
    freeproc(p);
    80002360:	8526                	mv	a0,s1
    80002362:	00000097          	auipc	ra,0x0
    80002366:	ec8080e7          	jalr	-312(ra) # 8000222a <freeproc>
    release(&p->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91a080e7          	jalr	-1766(ra) # 80000c86 <release>
    return 0;
    80002374:	84ce                	mv	s1,s3
    80002376:	bfe9                	j	80002350 <allocproc+0xce>
    freeproc(p);
    80002378:	8526                	mv	a0,s1
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	eb0080e7          	jalr	-336(ra) # 8000222a <freeproc>
    release(&p->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	902080e7          	jalr	-1790(ra) # 80000c86 <release>
    return 0;
    8000238c:	84ce                	mv	s1,s3
    8000238e:	b7c9                	j	80002350 <allocproc+0xce>

0000000080002390 <userinit>:
{
    80002390:	1101                	addi	sp,sp,-32
    80002392:	ec06                	sd	ra,24(sp)
    80002394:	e822                	sd	s0,16(sp)
    80002396:	e426                	sd	s1,8(sp)
    80002398:	1000                	addi	s0,sp,32
  p = allocproc();
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	ee8080e7          	jalr	-280(ra) # 80002282 <allocproc>
    800023a2:	84aa                	mv	s1,a0
  initproc = p;
    800023a4:	00007797          	auipc	a5,0x7
    800023a8:	c8a7b223          	sd	a0,-892(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800023ac:	03400613          	li	a2,52
    800023b0:	00006597          	auipc	a1,0x6
    800023b4:	5f058593          	addi	a1,a1,1520 # 800089a0 <initcode>
    800023b8:	6928                	ld	a0,80(a0)
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	f8a080e7          	jalr	-118(ra) # 80001344 <uvminit>
  p->sz = PGSIZE;
    800023c2:	6785                	lui	a5,0x1
    800023c4:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800023c6:	6cb8                	ld	a4,88(s1)
    800023c8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800023cc:	6cb8                	ld	a4,88(s1)
    800023ce:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800023d0:	4641                	li	a2,16
    800023d2:	00006597          	auipc	a1,0x6
    800023d6:	f2e58593          	addi	a1,a1,-210 # 80008300 <digits+0x2c0>
    800023da:	15848513          	addi	a0,s1,344
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	a42080e7          	jalr	-1470(ra) # 80000e20 <safestrcpy>
  p->cwd = namei("/");
    800023e6:	00006517          	auipc	a0,0x6
    800023ea:	f2a50513          	addi	a0,a0,-214 # 80008310 <digits+0x2d0>
    800023ee:	00002097          	auipc	ra,0x2
    800023f2:	296080e7          	jalr	662(ra) # 80004684 <namei>
    800023f6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800023fa:	478d                	li	a5,3
    800023fc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	886080e7          	jalr	-1914(ra) # 80000c86 <release>
}
    80002408:	60e2                	ld	ra,24(sp)
    8000240a:	6442                	ld	s0,16(sp)
    8000240c:	64a2                	ld	s1,8(sp)
    8000240e:	6105                	addi	sp,sp,32
    80002410:	8082                	ret

0000000080002412 <growproc>:
{
    80002412:	1101                	addi	sp,sp,-32
    80002414:	ec06                	sd	ra,24(sp)
    80002416:	e822                	sd	s0,16(sp)
    80002418:	e426                	sd	s1,8(sp)
    8000241a:	e04a                	sd	s2,0(sp)
    8000241c:	1000                	addi	s0,sp,32
    8000241e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002420:	00000097          	auipc	ra,0x0
    80002424:	c58080e7          	jalr	-936(ra) # 80002078 <myproc>
    80002428:	892a                	mv	s2,a0
  sz = p->sz;
    8000242a:	652c                	ld	a1,72(a0)
    8000242c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002430:	00904f63          	bgtz	s1,8000244e <growproc+0x3c>
  } else if(n < 0){
    80002434:	0204cc63          	bltz	s1,8000246c <growproc+0x5a>
  p->sz = sz;
    80002438:	1602                	slli	a2,a2,0x20
    8000243a:	9201                	srli	a2,a2,0x20
    8000243c:	04c93423          	sd	a2,72(s2)
  return 0;
    80002440:	4501                	li	a0,0
}
    80002442:	60e2                	ld	ra,24(sp)
    80002444:	6442                	ld	s0,16(sp)
    80002446:	64a2                	ld	s1,8(sp)
    80002448:	6902                	ld	s2,0(sp)
    8000244a:	6105                	addi	sp,sp,32
    8000244c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    8000244e:	9e25                	addw	a2,a2,s1
    80002450:	1602                	slli	a2,a2,0x20
    80002452:	9201                	srli	a2,a2,0x20
    80002454:	1582                	slli	a1,a1,0x20
    80002456:	9181                	srli	a1,a1,0x20
    80002458:	6928                	ld	a0,80(a0)
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	fa4080e7          	jalr	-92(ra) # 800013fe <uvmalloc>
    80002462:	0005061b          	sext.w	a2,a0
    80002466:	fa69                	bnez	a2,80002438 <growproc+0x26>
      return -1;
    80002468:	557d                	li	a0,-1
    8000246a:	bfe1                	j	80002442 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000246c:	9e25                	addw	a2,a2,s1
    8000246e:	1602                	slli	a2,a2,0x20
    80002470:	9201                	srli	a2,a2,0x20
    80002472:	1582                	slli	a1,a1,0x20
    80002474:	9181                	srli	a1,a1,0x20
    80002476:	6928                	ld	a0,80(a0)
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	f3e080e7          	jalr	-194(ra) # 800013b6 <uvmdealloc>
    80002480:	0005061b          	sext.w	a2,a0
    80002484:	bf55                	j	80002438 <growproc+0x26>

0000000080002486 <copy_swap_file>:
copy_swap_file(struct proc* child){
    80002486:	7139                	addi	sp,sp,-64
    80002488:	fc06                	sd	ra,56(sp)
    8000248a:	f822                	sd	s0,48(sp)
    8000248c:	f426                	sd	s1,40(sp)
    8000248e:	f04a                	sd	s2,32(sp)
    80002490:	ec4e                	sd	s3,24(sp)
    80002492:	e852                	sd	s4,16(sp)
    80002494:	e456                	sd	s5,8(sp)
    80002496:	e05a                	sd	s6,0(sp)
    80002498:	0080                	addi	s0,sp,64
    8000249a:	8b2a                	mv	s6,a0
  struct proc * pParent = myproc();
    8000249c:	00000097          	auipc	ra,0x0
    800024a0:	bdc080e7          	jalr	-1060(ra) # 80002078 <myproc>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    800024a4:	653c                	ld	a5,72(a0)
    800024a6:	cfd9                	beqz	a5,80002544 <copy_swap_file+0xbe>
    800024a8:	8a2a                	mv	s4,a0
    800024aa:	4481                	li	s1,0
    if(offset != -1){
    800024ac:	5afd                	li	s5,-1
    800024ae:	a83d                	j	800024ec <copy_swap_file+0x66>
      panic("not enough space to kalloc");
    800024b0:	00006517          	auipc	a0,0x6
    800024b4:	d6850513          	addi	a0,a0,-664 # 80008218 <digits+0x1d8>
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	072080e7          	jalr	114(ra) # 8000052a <panic>
          panic("read swap file failed\n");
    800024c0:	00006517          	auipc	a0,0x6
    800024c4:	e5850513          	addi	a0,a0,-424 # 80008318 <digits+0x2d8>
    800024c8:	ffffe097          	auipc	ra,0xffffe
    800024cc:	062080e7          	jalr	98(ra) # 8000052a <panic>
          panic("write swap file failed\n");
    800024d0:	00006517          	auipc	a0,0x6
    800024d4:	e6050513          	addi	a0,a0,-416 # 80008330 <digits+0x2f0>
    800024d8:	ffffe097          	auipc	ra,0xffffe
    800024dc:	052080e7          	jalr	82(ra) # 8000052a <panic>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    800024e0:	6785                	lui	a5,0x1
    800024e2:	94be                	add	s1,s1,a5
    800024e4:	048a3783          	ld	a5,72(s4)
    800024e8:	04f4fe63          	bgeu	s1,a5,80002544 <copy_swap_file+0xbe>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    800024ec:	00c4d713          	srli	a4,s1,0xc
    800024f0:	00171793          	slli	a5,a4,0x1
    800024f4:	97ba                	add	a5,a5,a4
    800024f6:	078a                	slli	a5,a5,0x2
    800024f8:	97d2                	add	a5,a5,s4
    800024fa:	1707a903          	lw	s2,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    800024fe:	ff5901e3          	beq	s2,s5,800024e0 <copy_swap_file+0x5a>
      if((buffer = kalloc()) == 0)
    80002502:	ffffe097          	auipc	ra,0xffffe
    80002506:	5e0080e7          	jalr	1504(ra) # 80000ae2 <kalloc>
    8000250a:	89aa                	mv	s3,a0
    8000250c:	d155                	beqz	a0,800024b0 <copy_swap_file+0x2a>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    8000250e:	2901                	sext.w	s2,s2
    80002510:	6685                	lui	a3,0x1
    80002512:	864a                	mv	a2,s2
    80002514:	85aa                	mv	a1,a0
    80002516:	8552                	mv	a0,s4
    80002518:	00002097          	auipc	ra,0x2
    8000251c:	494080e7          	jalr	1172(ra) # 800049ac <readFromSwapFile>
    80002520:	fb5500e3          	beq	a0,s5,800024c0 <copy_swap_file+0x3a>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    80002524:	6685                	lui	a3,0x1
    80002526:	864a                	mv	a2,s2
    80002528:	85ce                	mv	a1,s3
    8000252a:	855a                	mv	a0,s6
    8000252c:	00002097          	auipc	ra,0x2
    80002530:	45c080e7          	jalr	1116(ra) # 80004988 <writeToSwapFile>
    80002534:	f9550ee3          	beq	a0,s5,800024d0 <copy_swap_file+0x4a>
      kfree(buffer);
    80002538:	854e                	mv	a0,s3
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	49c080e7          	jalr	1180(ra) # 800009d6 <kfree>
    80002542:	bf79                	j	800024e0 <copy_swap_file+0x5a>
}
    80002544:	70e2                	ld	ra,56(sp)
    80002546:	7442                	ld	s0,48(sp)
    80002548:	74a2                	ld	s1,40(sp)
    8000254a:	7902                	ld	s2,32(sp)
    8000254c:	69e2                	ld	s3,24(sp)
    8000254e:	6a42                	ld	s4,16(sp)
    80002550:	6aa2                	ld	s5,8(sp)
    80002552:	6b02                	ld	s6,0(sp)
    80002554:	6121                	addi	sp,sp,64
    80002556:	8082                	ret

0000000080002558 <fork>:
{
    80002558:	715d                	addi	sp,sp,-80
    8000255a:	e486                	sd	ra,72(sp)
    8000255c:	e0a2                	sd	s0,64(sp)
    8000255e:	fc26                	sd	s1,56(sp)
    80002560:	f84a                	sd	s2,48(sp)
    80002562:	f44e                	sd	s3,40(sp)
    80002564:	f052                	sd	s4,32(sp)
    80002566:	ec56                	sd	s5,24(sp)
    80002568:	e85a                	sd	s6,16(sp)
    8000256a:	e45e                	sd	s7,8(sp)
    8000256c:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    8000256e:	00000097          	auipc	ra,0x0
    80002572:	b0a080e7          	jalr	-1270(ra) # 80002078 <myproc>
    80002576:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80002578:	00000097          	auipc	ra,0x0
    8000257c:	d0a080e7          	jalr	-758(ra) # 80002282 <allocproc>
    80002580:	1e050c63          	beqz	a0,80002778 <fork+0x220>
    80002584:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002586:	048ab603          	ld	a2,72(s5)
    8000258a:	692c                	ld	a1,80(a0)
    8000258c:	050ab503          	ld	a0,80(s5)
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	fba080e7          	jalr	-70(ra) # 8000154a <uvmcopy>
    80002598:	04054863          	bltz	a0,800025e8 <fork+0x90>
  np->sz = p->sz;
    8000259c:	048ab783          	ld	a5,72(s5)
    800025a0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    800025a4:	058ab683          	ld	a3,88(s5)
    800025a8:	87b6                	mv	a5,a3
    800025aa:	058a3703          	ld	a4,88(s4)
    800025ae:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800025b2:	0007b803          	ld	a6,0(a5)
    800025b6:	6788                	ld	a0,8(a5)
    800025b8:	6b8c                	ld	a1,16(a5)
    800025ba:	6f90                	ld	a2,24(a5)
    800025bc:	01073023          	sd	a6,0(a4)
    800025c0:	e708                	sd	a0,8(a4)
    800025c2:	eb0c                	sd	a1,16(a4)
    800025c4:	ef10                	sd	a2,24(a4)
    800025c6:	02078793          	addi	a5,a5,32
    800025ca:	02070713          	addi	a4,a4,32
    800025ce:	fed792e3          	bne	a5,a3,800025b2 <fork+0x5a>
  np->trapframe->a0 = 0;
    800025d2:	058a3783          	ld	a5,88(s4)
    800025d6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800025da:	0d0a8493          	addi	s1,s5,208
    800025de:	0d0a0913          	addi	s2,s4,208
    800025e2:	150a8993          	addi	s3,s5,336
    800025e6:	a03d                	j	80002614 <fork+0xbc>
    freeproc(np);
    800025e8:	8552                	mv	a0,s4
    800025ea:	00000097          	auipc	ra,0x0
    800025ee:	c40080e7          	jalr	-960(ra) # 8000222a <freeproc>
    release(&np->lock);
    800025f2:	8552                	mv	a0,s4
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	692080e7          	jalr	1682(ra) # 80000c86 <release>
    return -1;
    800025fc:	5b7d                	li	s6,-1
    800025fe:	a291                	j	80002742 <fork+0x1ea>
      np->ofile[i] = filedup(p->ofile[i]);
    80002600:	00003097          	auipc	ra,0x3
    80002604:	a30080e7          	jalr	-1488(ra) # 80005030 <filedup>
    80002608:	00a93023          	sd	a0,0(s2)
  for(i = 0; i < NOFILE; i++)
    8000260c:	04a1                	addi	s1,s1,8
    8000260e:	0921                	addi	s2,s2,8
    80002610:	01348563          	beq	s1,s3,8000261a <fork+0xc2>
    if(p->ofile[i])
    80002614:	6088                	ld	a0,0(s1)
    80002616:	f56d                	bnez	a0,80002600 <fork+0xa8>
    80002618:	bfd5                	j	8000260c <fork+0xb4>
  np->cwd = idup(p->cwd);
    8000261a:	150ab503          	ld	a0,336(s5)
    8000261e:	00002097          	auipc	ra,0x2
    80002622:	872080e7          	jalr	-1934(ra) # 80003e90 <idup>
    80002626:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000262a:	4641                	li	a2,16
    8000262c:	158a8593          	addi	a1,s5,344
    80002630:	158a0513          	addi	a0,s4,344
    80002634:	ffffe097          	auipc	ra,0xffffe
    80002638:	7ec080e7          	jalr	2028(ra) # 80000e20 <safestrcpy>
  pid = np->pid;
    8000263c:	030a2b03          	lw	s6,48(s4)
  release(&np->lock);
    80002640:	8552                	mv	a0,s4
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	644080e7          	jalr	1604(ra) # 80000c86 <release>
  if(np->pid >2){
    8000264a:	030a2703          	lw	a4,48(s4)
    8000264e:	4789                	li	a5,2
    80002650:	10e7c563          	blt	a5,a4,8000275a <fork+0x202>
  for(int i=0; i<32; i++){
    80002654:	170a0993          	addi	s3,s4,368
{
    80002658:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    8000265a:	02000b93          	li	s7,32
    np->paging_meta_data[i].offset = myproc()->paging_meta_data[i].offset;
    8000265e:	00000097          	auipc	ra,0x0
    80002662:	a1a080e7          	jalr	-1510(ra) # 80002078 <myproc>
    80002666:	00191493          	slli	s1,s2,0x1
    8000266a:	012487b3          	add	a5,s1,s2
    8000266e:	078a                	slli	a5,a5,0x2
    80002670:	953e                	add	a0,a0,a5
    80002672:	17052783          	lw	a5,368(a0)
    80002676:	00f9a023          	sw	a5,0(s3)
    np->paging_meta_data[i].aging = myproc()->paging_meta_data[i].aging;
    8000267a:	00000097          	auipc	ra,0x0
    8000267e:	9fe080e7          	jalr	-1538(ra) # 80002078 <myproc>
    80002682:	012487b3          	add	a5,s1,s2
    80002686:	078a                	slli	a5,a5,0x2
    80002688:	953e                	add	a0,a0,a5
    8000268a:	17452783          	lw	a5,372(a0)
    8000268e:	00f9a223          	sw	a5,4(s3)
    np->paging_meta_data[i].in_memory = myproc()->paging_meta_data[i].in_memory;
    80002692:	00000097          	auipc	ra,0x0
    80002696:	9e6080e7          	jalr	-1562(ra) # 80002078 <myproc>
    8000269a:	94ca                	add	s1,s1,s2
    8000269c:	048a                	slli	s1,s1,0x2
    8000269e:	94aa                	add	s1,s1,a0
    800026a0:	1784a783          	lw	a5,376(s1)
    800026a4:	00f9a423          	sw	a5,8(s3)
  for(int i=0; i<32; i++){
    800026a8:	2905                	addiw	s2,s2,1
    800026aa:	09b1                	addi	s3,s3,12
    800026ac:	fb7919e3          	bne	s2,s7,8000265e <fork+0x106>
  np->queue.front = myproc()->queue.front;
    800026b0:	00000097          	auipc	ra,0x0
    800026b4:	9c8080e7          	jalr	-1592(ra) # 80002078 <myproc>
    800026b8:	37052783          	lw	a5,880(a0)
    800026bc:	36fa2823          	sw	a5,880(s4)
  np->queue.last = myproc()->queue.last;
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	9b8080e7          	jalr	-1608(ra) # 80002078 <myproc>
    800026c8:	37452783          	lw	a5,884(a0)
    800026cc:	36fa2a23          	sw	a5,884(s4)
  np->queue.page_counter = myproc()->queue.page_counter;
    800026d0:	00000097          	auipc	ra,0x0
    800026d4:	9a8080e7          	jalr	-1624(ra) # 80002078 <myproc>
    800026d8:	37852783          	lw	a5,888(a0)
    800026dc:	36fa2c23          	sw	a5,888(s4)
  for(int i=0; i<32; i++){
    800026e0:	2f0a0913          	addi	s2,s4,752
    800026e4:	4481                	li	s1,0
    800026e6:	02000993          	li	s3,32
    np->queue.pages[i] = myproc()->queue.pages[i];
    800026ea:	00000097          	auipc	ra,0x0
    800026ee:	98e080e7          	jalr	-1650(ra) # 80002078 <myproc>
    800026f2:	0bc48793          	addi	a5,s1,188
    800026f6:	078a                	slli	a5,a5,0x2
    800026f8:	953e                	add	a0,a0,a5
    800026fa:	411c                	lw	a5,0(a0)
    800026fc:	00f92023          	sw	a5,0(s2)
  for(int i=0; i<32; i++){
    80002700:	2485                	addiw	s1,s1,1
    80002702:	0911                	addi	s2,s2,4
    80002704:	ff3493e3          	bne	s1,s3,800026ea <fork+0x192>
  acquire(&wait_lock);
    80002708:	0000f497          	auipc	s1,0xf
    8000270c:	bb048493          	addi	s1,s1,-1104 # 800112b8 <wait_lock>
    80002710:	8526                	mv	a0,s1
    80002712:	ffffe097          	auipc	ra,0xffffe
    80002716:	4c0080e7          	jalr	1216(ra) # 80000bd2 <acquire>
  np->parent = p;
    8000271a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	566080e7          	jalr	1382(ra) # 80000c86 <release>
  acquire(&np->lock);
    80002728:	8552                	mv	a0,s4
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	4a8080e7          	jalr	1192(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80002732:	478d                	li	a5,3
    80002734:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002738:	8552                	mv	a0,s4
    8000273a:	ffffe097          	auipc	ra,0xffffe
    8000273e:	54c080e7          	jalr	1356(ra) # 80000c86 <release>
}
    80002742:	855a                	mv	a0,s6
    80002744:	60a6                	ld	ra,72(sp)
    80002746:	6406                	ld	s0,64(sp)
    80002748:	74e2                	ld	s1,56(sp)
    8000274a:	7942                	ld	s2,48(sp)
    8000274c:	79a2                	ld	s3,40(sp)
    8000274e:	7a02                	ld	s4,32(sp)
    80002750:	6ae2                	ld	s5,24(sp)
    80002752:	6b42                	ld	s6,16(sp)
    80002754:	6ba2                	ld	s7,8(sp)
    80002756:	6161                	addi	sp,sp,80
    80002758:	8082                	ret
    if(createSwapFile(np) != 0){
    8000275a:	8552                	mv	a0,s4
    8000275c:	00002097          	auipc	ra,0x2
    80002760:	17c080e7          	jalr	380(ra) # 800048d8 <createSwapFile>
    80002764:	ee0508e3          	beqz	a0,80002654 <fork+0xfc>
      panic("create swap file failed");
    80002768:	00006517          	auipc	a0,0x6
    8000276c:	be050513          	addi	a0,a0,-1056 # 80008348 <digits+0x308>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	dba080e7          	jalr	-582(ra) # 8000052a <panic>
    return -1;
    80002778:	5b7d                	li	s6,-1
    8000277a:	b7e1                	j	80002742 <fork+0x1ea>

000000008000277c <scheduler>:
{
    8000277c:	7139                	addi	sp,sp,-64
    8000277e:	fc06                	sd	ra,56(sp)
    80002780:	f822                	sd	s0,48(sp)
    80002782:	f426                	sd	s1,40(sp)
    80002784:	f04a                	sd	s2,32(sp)
    80002786:	ec4e                	sd	s3,24(sp)
    80002788:	e852                	sd	s4,16(sp)
    8000278a:	e456                	sd	s5,8(sp)
    8000278c:	e05a                	sd	s6,0(sp)
    8000278e:	0080                	addi	s0,sp,64
    80002790:	8792                	mv	a5,tp
  int id = r_tp();
    80002792:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002794:	00779a93          	slli	s5,a5,0x7
    80002798:	0000f717          	auipc	a4,0xf
    8000279c:	b0870713          	addi	a4,a4,-1272 # 800112a0 <pid_lock>
    800027a0:	9756                	add	a4,a4,s5
    800027a2:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800027a6:	0000f717          	auipc	a4,0xf
    800027aa:	b3270713          	addi	a4,a4,-1230 # 800112d8 <cpus+0x8>
    800027ae:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800027b0:	498d                	li	s3,3
        p->state = RUNNING;
    800027b2:	4b11                	li	s6,4
        c->proc = p;
    800027b4:	079e                	slli	a5,a5,0x7
    800027b6:	0000fa17          	auipc	s4,0xf
    800027ba:	aeaa0a13          	addi	s4,s4,-1302 # 800112a0 <pid_lock>
    800027be:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800027c0:	0001d917          	auipc	s2,0x1d
    800027c4:	f1090913          	addi	s2,s2,-240 # 8001f6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800027cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027d0:	10079073          	csrw	sstatus,a5
    800027d4:	0000f497          	auipc	s1,0xf
    800027d8:	efc48493          	addi	s1,s1,-260 # 800116d0 <proc>
    800027dc:	a811                	j	800027f0 <scheduler+0x74>
      release(&p->lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4a6080e7          	jalr	1190(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800027e8:	38048493          	addi	s1,s1,896
    800027ec:	fd248ee3          	beq	s1,s2,800027c8 <scheduler+0x4c>
      acquire(&p->lock);
    800027f0:	8526                	mv	a0,s1
    800027f2:	ffffe097          	auipc	ra,0xffffe
    800027f6:	3e0080e7          	jalr	992(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    800027fa:	4c9c                	lw	a5,24(s1)
    800027fc:	ff3791e3          	bne	a5,s3,800027de <scheduler+0x62>
        p->state = RUNNING;
    80002800:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002804:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002808:	06048593          	addi	a1,s1,96
    8000280c:	8556                	mv	a0,s5
    8000280e:	00000097          	auipc	ra,0x0
    80002812:	63e080e7          	jalr	1598(ra) # 80002e4c <swtch>
        update_aging_algorithms();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	6d6080e7          	jalr	1750(ra) # 80001eec <update_aging_algorithms>
        c->proc = 0;
    8000281e:	020a3823          	sd	zero,48(s4)
    80002822:	bf75                	j	800027de <scheduler+0x62>

0000000080002824 <sched>:
{
    80002824:	7179                	addi	sp,sp,-48
    80002826:	f406                	sd	ra,40(sp)
    80002828:	f022                	sd	s0,32(sp)
    8000282a:	ec26                	sd	s1,24(sp)
    8000282c:	e84a                	sd	s2,16(sp)
    8000282e:	e44e                	sd	s3,8(sp)
    80002830:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002832:	00000097          	auipc	ra,0x0
    80002836:	846080e7          	jalr	-1978(ra) # 80002078 <myproc>
    8000283a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	31c080e7          	jalr	796(ra) # 80000b58 <holding>
    80002844:	c93d                	beqz	a0,800028ba <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002846:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002848:	2781                	sext.w	a5,a5
    8000284a:	079e                	slli	a5,a5,0x7
    8000284c:	0000f717          	auipc	a4,0xf
    80002850:	a5470713          	addi	a4,a4,-1452 # 800112a0 <pid_lock>
    80002854:	97ba                	add	a5,a5,a4
    80002856:	0a87a703          	lw	a4,168(a5)
    8000285a:	4785                	li	a5,1
    8000285c:	06f71763          	bne	a4,a5,800028ca <sched+0xa6>
  if(p->state == RUNNING)
    80002860:	4c98                	lw	a4,24(s1)
    80002862:	4791                	li	a5,4
    80002864:	06f70b63          	beq	a4,a5,800028da <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002868:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000286c:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000286e:	efb5                	bnez	a5,800028ea <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002870:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002872:	0000f917          	auipc	s2,0xf
    80002876:	a2e90913          	addi	s2,s2,-1490 # 800112a0 <pid_lock>
    8000287a:	2781                	sext.w	a5,a5
    8000287c:	079e                	slli	a5,a5,0x7
    8000287e:	97ca                	add	a5,a5,s2
    80002880:	0ac7a983          	lw	s3,172(a5)
    80002884:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002886:	2781                	sext.w	a5,a5
    80002888:	079e                	slli	a5,a5,0x7
    8000288a:	0000f597          	auipc	a1,0xf
    8000288e:	a4e58593          	addi	a1,a1,-1458 # 800112d8 <cpus+0x8>
    80002892:	95be                	add	a1,a1,a5
    80002894:	06048513          	addi	a0,s1,96
    80002898:	00000097          	auipc	ra,0x0
    8000289c:	5b4080e7          	jalr	1460(ra) # 80002e4c <swtch>
    800028a0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800028a2:	2781                	sext.w	a5,a5
    800028a4:	079e                	slli	a5,a5,0x7
    800028a6:	97ca                	add	a5,a5,s2
    800028a8:	0b37a623          	sw	s3,172(a5)
}
    800028ac:	70a2                	ld	ra,40(sp)
    800028ae:	7402                	ld	s0,32(sp)
    800028b0:	64e2                	ld	s1,24(sp)
    800028b2:	6942                	ld	s2,16(sp)
    800028b4:	69a2                	ld	s3,8(sp)
    800028b6:	6145                	addi	sp,sp,48
    800028b8:	8082                	ret
    panic("sched p->lock");
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	aa650513          	addi	a0,a0,-1370 # 80008360 <digits+0x320>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	c68080e7          	jalr	-920(ra) # 8000052a <panic>
    panic("sched locks");
    800028ca:	00006517          	auipc	a0,0x6
    800028ce:	aa650513          	addi	a0,a0,-1370 # 80008370 <digits+0x330>
    800028d2:	ffffe097          	auipc	ra,0xffffe
    800028d6:	c58080e7          	jalr	-936(ra) # 8000052a <panic>
    panic("sched running");
    800028da:	00006517          	auipc	a0,0x6
    800028de:	aa650513          	addi	a0,a0,-1370 # 80008380 <digits+0x340>
    800028e2:	ffffe097          	auipc	ra,0xffffe
    800028e6:	c48080e7          	jalr	-952(ra) # 8000052a <panic>
    panic("sched interruptible");
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	aa650513          	addi	a0,a0,-1370 # 80008390 <digits+0x350>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c38080e7          	jalr	-968(ra) # 8000052a <panic>

00000000800028fa <yield>:
{
    800028fa:	1101                	addi	sp,sp,-32
    800028fc:	ec06                	sd	ra,24(sp)
    800028fe:	e822                	sd	s0,16(sp)
    80002900:	e426                	sd	s1,8(sp)
    80002902:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002904:	fffff097          	auipc	ra,0xfffff
    80002908:	774080e7          	jalr	1908(ra) # 80002078 <myproc>
    8000290c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	2c4080e7          	jalr	708(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002916:	478d                	li	a5,3
    80002918:	cc9c                	sw	a5,24(s1)
  sched();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	f0a080e7          	jalr	-246(ra) # 80002824 <sched>
  release(&p->lock);
    80002922:	8526                	mv	a0,s1
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	362080e7          	jalr	866(ra) # 80000c86 <release>
}
    8000292c:	60e2                	ld	ra,24(sp)
    8000292e:	6442                	ld	s0,16(sp)
    80002930:	64a2                	ld	s1,8(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret

0000000080002936 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002936:	7179                	addi	sp,sp,-48
    80002938:	f406                	sd	ra,40(sp)
    8000293a:	f022                	sd	s0,32(sp)
    8000293c:	ec26                	sd	s1,24(sp)
    8000293e:	e84a                	sd	s2,16(sp)
    80002940:	e44e                	sd	s3,8(sp)
    80002942:	1800                	addi	s0,sp,48
    80002944:	89aa                	mv	s3,a0
    80002946:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	730080e7          	jalr	1840(ra) # 80002078 <myproc>
    80002950:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	280080e7          	jalr	640(ra) # 80000bd2 <acquire>
  release(lk);
    8000295a:	854a                	mv	a0,s2
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	32a080e7          	jalr	810(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002964:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002968:	4789                	li	a5,2
    8000296a:	cc9c                	sw	a5,24(s1)

  sched();
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	eb8080e7          	jalr	-328(ra) # 80002824 <sched>

  // Tidy up.
  p->chan = 0;
    80002974:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002978:	8526                	mv	a0,s1
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	30c080e7          	jalr	780(ra) # 80000c86 <release>
  acquire(lk);
    80002982:	854a                	mv	a0,s2
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	24e080e7          	jalr	590(ra) # 80000bd2 <acquire>
}
    8000298c:	70a2                	ld	ra,40(sp)
    8000298e:	7402                	ld	s0,32(sp)
    80002990:	64e2                	ld	s1,24(sp)
    80002992:	6942                	ld	s2,16(sp)
    80002994:	69a2                	ld	s3,8(sp)
    80002996:	6145                	addi	sp,sp,48
    80002998:	8082                	ret

000000008000299a <wait>:
{
    8000299a:	715d                	addi	sp,sp,-80
    8000299c:	e486                	sd	ra,72(sp)
    8000299e:	e0a2                	sd	s0,64(sp)
    800029a0:	fc26                	sd	s1,56(sp)
    800029a2:	f84a                	sd	s2,48(sp)
    800029a4:	f44e                	sd	s3,40(sp)
    800029a6:	f052                	sd	s4,32(sp)
    800029a8:	ec56                	sd	s5,24(sp)
    800029aa:	e85a                	sd	s6,16(sp)
    800029ac:	e45e                	sd	s7,8(sp)
    800029ae:	e062                	sd	s8,0(sp)
    800029b0:	0880                	addi	s0,sp,80
    800029b2:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800029b4:	fffff097          	auipc	ra,0xfffff
    800029b8:	6c4080e7          	jalr	1732(ra) # 80002078 <myproc>
    800029bc:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800029be:	0000f517          	auipc	a0,0xf
    800029c2:	8fa50513          	addi	a0,a0,-1798 # 800112b8 <wait_lock>
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	20c080e7          	jalr	524(ra) # 80000bd2 <acquire>
    havekids = 0;
    800029ce:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800029d0:	4a15                	li	s4,5
        havekids = 1;
    800029d2:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800029d4:	0001d997          	auipc	s3,0x1d
    800029d8:	cfc98993          	addi	s3,s3,-772 # 8001f6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800029dc:	0000fc17          	auipc	s8,0xf
    800029e0:	8dcc0c13          	addi	s8,s8,-1828 # 800112b8 <wait_lock>
    havekids = 0;
    800029e4:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800029e6:	0000f497          	auipc	s1,0xf
    800029ea:	cea48493          	addi	s1,s1,-790 # 800116d0 <proc>
    800029ee:	a0bd                	j	80002a5c <wait+0xc2>
          pid = np->pid;
    800029f0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029f4:	000b0e63          	beqz	s6,80002a10 <wait+0x76>
    800029f8:	4691                	li	a3,4
    800029fa:	02c48613          	addi	a2,s1,44
    800029fe:	85da                	mv	a1,s6
    80002a00:	05093503          	ld	a0,80(s2)
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	c4a080e7          	jalr	-950(ra) # 8000164e <copyout>
    80002a0c:	02054563          	bltz	a0,80002a36 <wait+0x9c>
          freeproc(np);
    80002a10:	8526                	mv	a0,s1
    80002a12:	00000097          	auipc	ra,0x0
    80002a16:	818080e7          	jalr	-2024(ra) # 8000222a <freeproc>
          release(&np->lock);
    80002a1a:	8526                	mv	a0,s1
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	26a080e7          	jalr	618(ra) # 80000c86 <release>
          release(&wait_lock);
    80002a24:	0000f517          	auipc	a0,0xf
    80002a28:	89450513          	addi	a0,a0,-1900 # 800112b8 <wait_lock>
    80002a2c:	ffffe097          	auipc	ra,0xffffe
    80002a30:	25a080e7          	jalr	602(ra) # 80000c86 <release>
          return pid;
    80002a34:	a09d                	j	80002a9a <wait+0x100>
            release(&np->lock);
    80002a36:	8526                	mv	a0,s1
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	24e080e7          	jalr	590(ra) # 80000c86 <release>
            release(&wait_lock);
    80002a40:	0000f517          	auipc	a0,0xf
    80002a44:	87850513          	addi	a0,a0,-1928 # 800112b8 <wait_lock>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	23e080e7          	jalr	574(ra) # 80000c86 <release>
            return -1;
    80002a50:	59fd                	li	s3,-1
    80002a52:	a0a1                	j	80002a9a <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002a54:	38048493          	addi	s1,s1,896
    80002a58:	03348463          	beq	s1,s3,80002a80 <wait+0xe6>
      if(np->parent == p){
    80002a5c:	7c9c                	ld	a5,56(s1)
    80002a5e:	ff279be3          	bne	a5,s2,80002a54 <wait+0xba>
        acquire(&np->lock);
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
        if(np->state == ZOMBIE){
    80002a6c:	4c9c                	lw	a5,24(s1)
    80002a6e:	f94781e3          	beq	a5,s4,800029f0 <wait+0x56>
        release(&np->lock);
    80002a72:	8526                	mv	a0,s1
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	212080e7          	jalr	530(ra) # 80000c86 <release>
        havekids = 1;
    80002a7c:	8756                	mv	a4,s5
    80002a7e:	bfd9                	j	80002a54 <wait+0xba>
    if(!havekids || p->killed){
    80002a80:	c701                	beqz	a4,80002a88 <wait+0xee>
    80002a82:	02892783          	lw	a5,40(s2)
    80002a86:	c79d                	beqz	a5,80002ab4 <wait+0x11a>
      release(&wait_lock);
    80002a88:	0000f517          	auipc	a0,0xf
    80002a8c:	83050513          	addi	a0,a0,-2000 # 800112b8 <wait_lock>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	1f6080e7          	jalr	502(ra) # 80000c86 <release>
      return -1;
    80002a98:	59fd                	li	s3,-1
}
    80002a9a:	854e                	mv	a0,s3
    80002a9c:	60a6                	ld	ra,72(sp)
    80002a9e:	6406                	ld	s0,64(sp)
    80002aa0:	74e2                	ld	s1,56(sp)
    80002aa2:	7942                	ld	s2,48(sp)
    80002aa4:	79a2                	ld	s3,40(sp)
    80002aa6:	7a02                	ld	s4,32(sp)
    80002aa8:	6ae2                	ld	s5,24(sp)
    80002aaa:	6b42                	ld	s6,16(sp)
    80002aac:	6ba2                	ld	s7,8(sp)
    80002aae:	6c02                	ld	s8,0(sp)
    80002ab0:	6161                	addi	sp,sp,80
    80002ab2:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ab4:	85e2                	mv	a1,s8
    80002ab6:	854a                	mv	a0,s2
    80002ab8:	00000097          	auipc	ra,0x0
    80002abc:	e7e080e7          	jalr	-386(ra) # 80002936 <sleep>
    havekids = 0;
    80002ac0:	b715                	j	800029e4 <wait+0x4a>

0000000080002ac2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002ac2:	7139                	addi	sp,sp,-64
    80002ac4:	fc06                	sd	ra,56(sp)
    80002ac6:	f822                	sd	s0,48(sp)
    80002ac8:	f426                	sd	s1,40(sp)
    80002aca:	f04a                	sd	s2,32(sp)
    80002acc:	ec4e                	sd	s3,24(sp)
    80002ace:	e852                	sd	s4,16(sp)
    80002ad0:	e456                	sd	s5,8(sp)
    80002ad2:	0080                	addi	s0,sp,64
    80002ad4:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002ad6:	0000f497          	auipc	s1,0xf
    80002ada:	bfa48493          	addi	s1,s1,-1030 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002ade:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002ae0:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002ae2:	0001d917          	auipc	s2,0x1d
    80002ae6:	bee90913          	addi	s2,s2,-1042 # 8001f6d0 <tickslock>
    80002aea:	a811                	j	80002afe <wakeup+0x3c>
      }
      release(&p->lock);
    80002aec:	8526                	mv	a0,s1
    80002aee:	ffffe097          	auipc	ra,0xffffe
    80002af2:	198080e7          	jalr	408(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002af6:	38048493          	addi	s1,s1,896
    80002afa:	03248663          	beq	s1,s2,80002b26 <wakeup+0x64>
    if(p != myproc()){
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	57a080e7          	jalr	1402(ra) # 80002078 <myproc>
    80002b06:	fea488e3          	beq	s1,a0,80002af6 <wakeup+0x34>
      acquire(&p->lock);
    80002b0a:	8526                	mv	a0,s1
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	0c6080e7          	jalr	198(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002b14:	4c9c                	lw	a5,24(s1)
    80002b16:	fd379be3          	bne	a5,s3,80002aec <wakeup+0x2a>
    80002b1a:	709c                	ld	a5,32(s1)
    80002b1c:	fd4798e3          	bne	a5,s4,80002aec <wakeup+0x2a>
        p->state = RUNNABLE;
    80002b20:	0154ac23          	sw	s5,24(s1)
    80002b24:	b7e1                	j	80002aec <wakeup+0x2a>
    }
  }
}
    80002b26:	70e2                	ld	ra,56(sp)
    80002b28:	7442                	ld	s0,48(sp)
    80002b2a:	74a2                	ld	s1,40(sp)
    80002b2c:	7902                	ld	s2,32(sp)
    80002b2e:	69e2                	ld	s3,24(sp)
    80002b30:	6a42                	ld	s4,16(sp)
    80002b32:	6aa2                	ld	s5,8(sp)
    80002b34:	6121                	addi	sp,sp,64
    80002b36:	8082                	ret

0000000080002b38 <reparent>:
{
    80002b38:	7179                	addi	sp,sp,-48
    80002b3a:	f406                	sd	ra,40(sp)
    80002b3c:	f022                	sd	s0,32(sp)
    80002b3e:	ec26                	sd	s1,24(sp)
    80002b40:	e84a                	sd	s2,16(sp)
    80002b42:	e44e                	sd	s3,8(sp)
    80002b44:	e052                	sd	s4,0(sp)
    80002b46:	1800                	addi	s0,sp,48
    80002b48:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b4a:	0000f497          	auipc	s1,0xf
    80002b4e:	b8648493          	addi	s1,s1,-1146 # 800116d0 <proc>
      pp->parent = initproc;
    80002b52:	00006a17          	auipc	s4,0x6
    80002b56:	4d6a0a13          	addi	s4,s4,1238 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002b5a:	0001d997          	auipc	s3,0x1d
    80002b5e:	b7698993          	addi	s3,s3,-1162 # 8001f6d0 <tickslock>
    80002b62:	a029                	j	80002b6c <reparent+0x34>
    80002b64:	38048493          	addi	s1,s1,896
    80002b68:	01348d63          	beq	s1,s3,80002b82 <reparent+0x4a>
    if(pp->parent == p){
    80002b6c:	7c9c                	ld	a5,56(s1)
    80002b6e:	ff279be3          	bne	a5,s2,80002b64 <reparent+0x2c>
      pp->parent = initproc;
    80002b72:	000a3503          	ld	a0,0(s4)
    80002b76:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002b78:	00000097          	auipc	ra,0x0
    80002b7c:	f4a080e7          	jalr	-182(ra) # 80002ac2 <wakeup>
    80002b80:	b7d5                	j	80002b64 <reparent+0x2c>
}
    80002b82:	70a2                	ld	ra,40(sp)
    80002b84:	7402                	ld	s0,32(sp)
    80002b86:	64e2                	ld	s1,24(sp)
    80002b88:	6942                	ld	s2,16(sp)
    80002b8a:	69a2                	ld	s3,8(sp)
    80002b8c:	6a02                	ld	s4,0(sp)
    80002b8e:	6145                	addi	sp,sp,48
    80002b90:	8082                	ret

0000000080002b92 <exit>:
{
    80002b92:	7179                	addi	sp,sp,-48
    80002b94:	f406                	sd	ra,40(sp)
    80002b96:	f022                	sd	s0,32(sp)
    80002b98:	ec26                	sd	s1,24(sp)
    80002b9a:	e84a                	sd	s2,16(sp)
    80002b9c:	e44e                	sd	s3,8(sp)
    80002b9e:	e052                	sd	s4,0(sp)
    80002ba0:	1800                	addi	s0,sp,48
    80002ba2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	4d4080e7          	jalr	1236(ra) # 80002078 <myproc>
    80002bac:	89aa                	mv	s3,a0
  if(p == initproc)
    80002bae:	00006797          	auipc	a5,0x6
    80002bb2:	47a7b783          	ld	a5,1146(a5) # 80009028 <initproc>
    80002bb6:	0d050493          	addi	s1,a0,208
    80002bba:	15050913          	addi	s2,a0,336
    80002bbe:	02a79363          	bne	a5,a0,80002be4 <exit+0x52>
    panic("init exiting");
    80002bc2:	00005517          	auipc	a0,0x5
    80002bc6:	7e650513          	addi	a0,a0,2022 # 800083a8 <digits+0x368>
    80002bca:	ffffe097          	auipc	ra,0xffffe
    80002bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
      fileclose(f);
    80002bd2:	00002097          	auipc	ra,0x2
    80002bd6:	4b0080e7          	jalr	1200(ra) # 80005082 <fileclose>
      p->ofile[fd] = 0;
    80002bda:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002bde:	04a1                	addi	s1,s1,8
    80002be0:	01248563          	beq	s1,s2,80002bea <exit+0x58>
    if(p->ofile[fd]){
    80002be4:	6088                	ld	a0,0(s1)
    80002be6:	f575                	bnez	a0,80002bd2 <exit+0x40>
    80002be8:	bfdd                	j	80002bde <exit+0x4c>
  if(p->pid > 2)
    80002bea:	0309a703          	lw	a4,48(s3)
    80002bee:	4789                	li	a5,2
    80002bf0:	08e7c163          	blt	a5,a4,80002c72 <exit+0xe0>
  begin_op();
    80002bf4:	00002097          	auipc	ra,0x2
    80002bf8:	fc2080e7          	jalr	-62(ra) # 80004bb6 <begin_op>
  iput(p->cwd);
    80002bfc:	1509b503          	ld	a0,336(s3)
    80002c00:	00001097          	auipc	ra,0x1
    80002c04:	488080e7          	jalr	1160(ra) # 80004088 <iput>
  end_op();
    80002c08:	00002097          	auipc	ra,0x2
    80002c0c:	02e080e7          	jalr	46(ra) # 80004c36 <end_op>
  p->cwd = 0;
    80002c10:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002c14:	0000e497          	auipc	s1,0xe
    80002c18:	6a448493          	addi	s1,s1,1700 # 800112b8 <wait_lock>
    80002c1c:	8526                	mv	a0,s1
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	fb4080e7          	jalr	-76(ra) # 80000bd2 <acquire>
  reparent(p);
    80002c26:	854e                	mv	a0,s3
    80002c28:	00000097          	auipc	ra,0x0
    80002c2c:	f10080e7          	jalr	-240(ra) # 80002b38 <reparent>
  wakeup(p->parent);
    80002c30:	0389b503          	ld	a0,56(s3)
    80002c34:	00000097          	auipc	ra,0x0
    80002c38:	e8e080e7          	jalr	-370(ra) # 80002ac2 <wakeup>
  acquire(&p->lock);
    80002c3c:	854e                	mv	a0,s3
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	f94080e7          	jalr	-108(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002c46:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002c4a:	4795                	li	a5,5
    80002c4c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002c50:	8526                	mv	a0,s1
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	034080e7          	jalr	52(ra) # 80000c86 <release>
  sched();
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	bca080e7          	jalr	-1078(ra) # 80002824 <sched>
  panic("zombie exit");
    80002c62:	00005517          	auipc	a0,0x5
    80002c66:	75650513          	addi	a0,a0,1878 # 800083b8 <digits+0x378>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	8c0080e7          	jalr	-1856(ra) # 8000052a <panic>
    removeSwapFile(p);
    80002c72:	854e                	mv	a0,s3
    80002c74:	00002097          	auipc	ra,0x2
    80002c78:	abc080e7          	jalr	-1348(ra) # 80004730 <removeSwapFile>
    80002c7c:	bfa5                	j	80002bf4 <exit+0x62>

0000000080002c7e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002c7e:	7179                	addi	sp,sp,-48
    80002c80:	f406                	sd	ra,40(sp)
    80002c82:	f022                	sd	s0,32(sp)
    80002c84:	ec26                	sd	s1,24(sp)
    80002c86:	e84a                	sd	s2,16(sp)
    80002c88:	e44e                	sd	s3,8(sp)
    80002c8a:	1800                	addi	s0,sp,48
    80002c8c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002c8e:	0000f497          	auipc	s1,0xf
    80002c92:	a4248493          	addi	s1,s1,-1470 # 800116d0 <proc>
    80002c96:	0001d997          	auipc	s3,0x1d
    80002c9a:	a3a98993          	addi	s3,s3,-1478 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	f32080e7          	jalr	-206(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002ca8:	589c                	lw	a5,48(s1)
    80002caa:	01278d63          	beq	a5,s2,80002cc4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002cae:	8526                	mv	a0,s1
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	fd6080e7          	jalr	-42(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002cb8:	38048493          	addi	s1,s1,896
    80002cbc:	ff3491e3          	bne	s1,s3,80002c9e <kill+0x20>
  }
  return -1;
    80002cc0:	557d                	li	a0,-1
    80002cc2:	a829                	j	80002cdc <kill+0x5e>
      p->killed = 1;
    80002cc4:	4785                	li	a5,1
    80002cc6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002cc8:	4c98                	lw	a4,24(s1)
    80002cca:	4789                	li	a5,2
    80002ccc:	00f70f63          	beq	a4,a5,80002cea <kill+0x6c>
      release(&p->lock);
    80002cd0:	8526                	mv	a0,s1
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	fb4080e7          	jalr	-76(ra) # 80000c86 <release>
      return 0;
    80002cda:	4501                	li	a0,0
}
    80002cdc:	70a2                	ld	ra,40(sp)
    80002cde:	7402                	ld	s0,32(sp)
    80002ce0:	64e2                	ld	s1,24(sp)
    80002ce2:	6942                	ld	s2,16(sp)
    80002ce4:	69a2                	ld	s3,8(sp)
    80002ce6:	6145                	addi	sp,sp,48
    80002ce8:	8082                	ret
        p->state = RUNNABLE;
    80002cea:	478d                	li	a5,3
    80002cec:	cc9c                	sw	a5,24(s1)
    80002cee:	b7cd                	j	80002cd0 <kill+0x52>

0000000080002cf0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002cf0:	7179                	addi	sp,sp,-48
    80002cf2:	f406                	sd	ra,40(sp)
    80002cf4:	f022                	sd	s0,32(sp)
    80002cf6:	ec26                	sd	s1,24(sp)
    80002cf8:	e84a                	sd	s2,16(sp)
    80002cfa:	e44e                	sd	s3,8(sp)
    80002cfc:	e052                	sd	s4,0(sp)
    80002cfe:	1800                	addi	s0,sp,48
    80002d00:	84aa                	mv	s1,a0
    80002d02:	892e                	mv	s2,a1
    80002d04:	89b2                	mv	s3,a2
    80002d06:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	370080e7          	jalr	880(ra) # 80002078 <myproc>
  if(user_dst){
    80002d10:	c08d                	beqz	s1,80002d32 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002d12:	86d2                	mv	a3,s4
    80002d14:	864e                	mv	a2,s3
    80002d16:	85ca                	mv	a1,s2
    80002d18:	6928                	ld	a0,80(a0)
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	934080e7          	jalr	-1740(ra) # 8000164e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002d22:	70a2                	ld	ra,40(sp)
    80002d24:	7402                	ld	s0,32(sp)
    80002d26:	64e2                	ld	s1,24(sp)
    80002d28:	6942                	ld	s2,16(sp)
    80002d2a:	69a2                	ld	s3,8(sp)
    80002d2c:	6a02                	ld	s4,0(sp)
    80002d2e:	6145                	addi	sp,sp,48
    80002d30:	8082                	ret
    memmove((char *)dst, src, len);
    80002d32:	000a061b          	sext.w	a2,s4
    80002d36:	85ce                	mv	a1,s3
    80002d38:	854a                	mv	a0,s2
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	ff0080e7          	jalr	-16(ra) # 80000d2a <memmove>
    return 0;
    80002d42:	8526                	mv	a0,s1
    80002d44:	bff9                	j	80002d22 <either_copyout+0x32>

0000000080002d46 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002d46:	7179                	addi	sp,sp,-48
    80002d48:	f406                	sd	ra,40(sp)
    80002d4a:	f022                	sd	s0,32(sp)
    80002d4c:	ec26                	sd	s1,24(sp)
    80002d4e:	e84a                	sd	s2,16(sp)
    80002d50:	e44e                	sd	s3,8(sp)
    80002d52:	e052                	sd	s4,0(sp)
    80002d54:	1800                	addi	s0,sp,48
    80002d56:	892a                	mv	s2,a0
    80002d58:	84ae                	mv	s1,a1
    80002d5a:	89b2                	mv	s3,a2
    80002d5c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	31a080e7          	jalr	794(ra) # 80002078 <myproc>
  if(user_src){
    80002d66:	c08d                	beqz	s1,80002d88 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002d68:	86d2                	mv	a3,s4
    80002d6a:	864e                	mv	a2,s3
    80002d6c:	85ca                	mv	a1,s2
    80002d6e:	6928                	ld	a0,80(a0)
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	96a080e7          	jalr	-1686(ra) # 800016da <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002d78:	70a2                	ld	ra,40(sp)
    80002d7a:	7402                	ld	s0,32(sp)
    80002d7c:	64e2                	ld	s1,24(sp)
    80002d7e:	6942                	ld	s2,16(sp)
    80002d80:	69a2                	ld	s3,8(sp)
    80002d82:	6a02                	ld	s4,0(sp)
    80002d84:	6145                	addi	sp,sp,48
    80002d86:	8082                	ret
    memmove(dst, (char*)src, len);
    80002d88:	000a061b          	sext.w	a2,s4
    80002d8c:	85ce                	mv	a1,s3
    80002d8e:	854a                	mv	a0,s2
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	f9a080e7          	jalr	-102(ra) # 80000d2a <memmove>
    return 0;
    80002d98:	8526                	mv	a0,s1
    80002d9a:	bff9                	j	80002d78 <either_copyin+0x32>

0000000080002d9c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002d9c:	715d                	addi	sp,sp,-80
    80002d9e:	e486                	sd	ra,72(sp)
    80002da0:	e0a2                	sd	s0,64(sp)
    80002da2:	fc26                	sd	s1,56(sp)
    80002da4:	f84a                	sd	s2,48(sp)
    80002da6:	f44e                	sd	s3,40(sp)
    80002da8:	f052                	sd	s4,32(sp)
    80002daa:	ec56                	sd	s5,24(sp)
    80002dac:	e85a                	sd	s6,16(sp)
    80002dae:	e45e                	sd	s7,8(sp)
    80002db0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002db2:	00005517          	auipc	a0,0x5
    80002db6:	32e50513          	addi	a0,a0,814 # 800080e0 <digits+0xa0>
    80002dba:	ffffd097          	auipc	ra,0xffffd
    80002dbe:	7ba080e7          	jalr	1978(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002dc2:	0000f497          	auipc	s1,0xf
    80002dc6:	a6648493          	addi	s1,s1,-1434 # 80011828 <proc+0x158>
    80002dca:	0001d917          	auipc	s2,0x1d
    80002dce:	a5e90913          	addi	s2,s2,-1442 # 8001f828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002dd2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002dd4:	00005997          	auipc	s3,0x5
    80002dd8:	5f498993          	addi	s3,s3,1524 # 800083c8 <digits+0x388>
    printf("%d %s %s", p->pid, state, p->name);
    80002ddc:	00005a97          	auipc	s5,0x5
    80002de0:	5f4a8a93          	addi	s5,s5,1524 # 800083d0 <digits+0x390>
    printf("\n");
    80002de4:	00005a17          	auipc	s4,0x5
    80002de8:	2fca0a13          	addi	s4,s4,764 # 800080e0 <digits+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002dec:	00005b97          	auipc	s7,0x5
    80002df0:	61cb8b93          	addi	s7,s7,1564 # 80008408 <states.0>
    80002df4:	a00d                	j	80002e16 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002df6:	ed86a583          	lw	a1,-296(a3)
    80002dfa:	8556                	mv	a0,s5
    80002dfc:	ffffd097          	auipc	ra,0xffffd
    80002e00:	778080e7          	jalr	1912(ra) # 80000574 <printf>
    printf("\n");
    80002e04:	8552                	mv	a0,s4
    80002e06:	ffffd097          	auipc	ra,0xffffd
    80002e0a:	76e080e7          	jalr	1902(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e0e:	38048493          	addi	s1,s1,896
    80002e12:	03248263          	beq	s1,s2,80002e36 <procdump+0x9a>
    if(p->state == UNUSED)
    80002e16:	86a6                	mv	a3,s1
    80002e18:	ec04a783          	lw	a5,-320(s1)
    80002e1c:	dbed                	beqz	a5,80002e0e <procdump+0x72>
      state = "???";
    80002e1e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e20:	fcfb6be3          	bltu	s6,a5,80002df6 <procdump+0x5a>
    80002e24:	02079713          	slli	a4,a5,0x20
    80002e28:	01d75793          	srli	a5,a4,0x1d
    80002e2c:	97de                	add	a5,a5,s7
    80002e2e:	6390                	ld	a2,0(a5)
    80002e30:	f279                	bnez	a2,80002df6 <procdump+0x5a>
      state = "???";
    80002e32:	864e                	mv	a2,s3
    80002e34:	b7c9                	j	80002df6 <procdump+0x5a>
  }
}
    80002e36:	60a6                	ld	ra,72(sp)
    80002e38:	6406                	ld	s0,64(sp)
    80002e3a:	74e2                	ld	s1,56(sp)
    80002e3c:	7942                	ld	s2,48(sp)
    80002e3e:	79a2                	ld	s3,40(sp)
    80002e40:	7a02                	ld	s4,32(sp)
    80002e42:	6ae2                	ld	s5,24(sp)
    80002e44:	6b42                	ld	s6,16(sp)
    80002e46:	6ba2                	ld	s7,8(sp)
    80002e48:	6161                	addi	sp,sp,80
    80002e4a:	8082                	ret

0000000080002e4c <swtch>:
    80002e4c:	00153023          	sd	ra,0(a0)
    80002e50:	00253423          	sd	sp,8(a0)
    80002e54:	e900                	sd	s0,16(a0)
    80002e56:	ed04                	sd	s1,24(a0)
    80002e58:	03253023          	sd	s2,32(a0)
    80002e5c:	03353423          	sd	s3,40(a0)
    80002e60:	03453823          	sd	s4,48(a0)
    80002e64:	03553c23          	sd	s5,56(a0)
    80002e68:	05653023          	sd	s6,64(a0)
    80002e6c:	05753423          	sd	s7,72(a0)
    80002e70:	05853823          	sd	s8,80(a0)
    80002e74:	05953c23          	sd	s9,88(a0)
    80002e78:	07a53023          	sd	s10,96(a0)
    80002e7c:	07b53423          	sd	s11,104(a0)
    80002e80:	0005b083          	ld	ra,0(a1)
    80002e84:	0085b103          	ld	sp,8(a1)
    80002e88:	6980                	ld	s0,16(a1)
    80002e8a:	6d84                	ld	s1,24(a1)
    80002e8c:	0205b903          	ld	s2,32(a1)
    80002e90:	0285b983          	ld	s3,40(a1)
    80002e94:	0305ba03          	ld	s4,48(a1)
    80002e98:	0385ba83          	ld	s5,56(a1)
    80002e9c:	0405bb03          	ld	s6,64(a1)
    80002ea0:	0485bb83          	ld	s7,72(a1)
    80002ea4:	0505bc03          	ld	s8,80(a1)
    80002ea8:	0585bc83          	ld	s9,88(a1)
    80002eac:	0605bd03          	ld	s10,96(a1)
    80002eb0:	0685bd83          	ld	s11,104(a1)
    80002eb4:	8082                	ret

0000000080002eb6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002eb6:	1141                	addi	sp,sp,-16
    80002eb8:	e406                	sd	ra,8(sp)
    80002eba:	e022                	sd	s0,0(sp)
    80002ebc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ebe:	00005597          	auipc	a1,0x5
    80002ec2:	57a58593          	addi	a1,a1,1402 # 80008438 <states.0+0x30>
    80002ec6:	0001d517          	auipc	a0,0x1d
    80002eca:	80a50513          	addi	a0,a0,-2038 # 8001f6d0 <tickslock>
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	c74080e7          	jalr	-908(ra) # 80000b42 <initlock>
}
    80002ed6:	60a2                	ld	ra,8(sp)
    80002ed8:	6402                	ld	s0,0(sp)
    80002eda:	0141                	addi	sp,sp,16
    80002edc:	8082                	ret

0000000080002ede <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ede:	1141                	addi	sp,sp,-16
    80002ee0:	e422                	sd	s0,8(sp)
    80002ee2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ee4:	00004797          	auipc	a5,0x4
    80002ee8:	9dc78793          	addi	a5,a5,-1572 # 800068c0 <kernelvec>
    80002eec:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002ef0:	6422                	ld	s0,8(sp)
    80002ef2:	0141                	addi	sp,sp,16
    80002ef4:	8082                	ret

0000000080002ef6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002ef6:	1141                	addi	sp,sp,-16
    80002ef8:	e406                	sd	ra,8(sp)
    80002efa:	e022                	sd	s0,0(sp)
    80002efc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	17a080e7          	jalr	378(ra) # 80002078 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f06:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002f0a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f0c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002f10:	00004617          	auipc	a2,0x4
    80002f14:	0f060613          	addi	a2,a2,240 # 80007000 <_trampoline>
    80002f18:	00004697          	auipc	a3,0x4
    80002f1c:	0e868693          	addi	a3,a3,232 # 80007000 <_trampoline>
    80002f20:	8e91                	sub	a3,a3,a2
    80002f22:	040007b7          	lui	a5,0x4000
    80002f26:	17fd                	addi	a5,a5,-1
    80002f28:	07b2                	slli	a5,a5,0xc
    80002f2a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f2c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002f30:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002f32:	180026f3          	csrr	a3,satp
    80002f36:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002f38:	6d38                	ld	a4,88(a0)
    80002f3a:	6134                	ld	a3,64(a0)
    80002f3c:	6585                	lui	a1,0x1
    80002f3e:	96ae                	add	a3,a3,a1
    80002f40:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002f42:	6d38                	ld	a4,88(a0)
    80002f44:	00000697          	auipc	a3,0x0
    80002f48:	13868693          	addi	a3,a3,312 # 8000307c <usertrap>
    80002f4c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002f4e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002f50:	8692                	mv	a3,tp
    80002f52:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f54:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002f58:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002f5c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f60:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002f64:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f66:	6f18                	ld	a4,24(a4)
    80002f68:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f6c:	692c                	ld	a1,80(a0)
    80002f6e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002f70:	00004717          	auipc	a4,0x4
    80002f74:	12070713          	addi	a4,a4,288 # 80007090 <userret>
    80002f78:	8f11                	sub	a4,a4,a2
    80002f7a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002f7c:	577d                	li	a4,-1
    80002f7e:	177e                	slli	a4,a4,0x3f
    80002f80:	8dd9                	or	a1,a1,a4
    80002f82:	02000537          	lui	a0,0x2000
    80002f86:	157d                	addi	a0,a0,-1
    80002f88:	0536                	slli	a0,a0,0xd
    80002f8a:	9782                	jalr	a5
}
    80002f8c:	60a2                	ld	ra,8(sp)
    80002f8e:	6402                	ld	s0,0(sp)
    80002f90:	0141                	addi	sp,sp,16
    80002f92:	8082                	ret

0000000080002f94 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	e426                	sd	s1,8(sp)
    80002f9c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f9e:	0001c497          	auipc	s1,0x1c
    80002fa2:	73248493          	addi	s1,s1,1842 # 8001f6d0 <tickslock>
    80002fa6:	8526                	mv	a0,s1
    80002fa8:	ffffe097          	auipc	ra,0xffffe
    80002fac:	c2a080e7          	jalr	-982(ra) # 80000bd2 <acquire>
  ticks++;
    80002fb0:	00006517          	auipc	a0,0x6
    80002fb4:	08050513          	addi	a0,a0,128 # 80009030 <ticks>
    80002fb8:	411c                	lw	a5,0(a0)
    80002fba:	2785                	addiw	a5,a5,1
    80002fbc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002fbe:	00000097          	auipc	ra,0x0
    80002fc2:	b04080e7          	jalr	-1276(ra) # 80002ac2 <wakeup>
  release(&tickslock);
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	cbe080e7          	jalr	-834(ra) # 80000c86 <release>
}
    80002fd0:	60e2                	ld	ra,24(sp)
    80002fd2:	6442                	ld	s0,16(sp)
    80002fd4:	64a2                	ld	s1,8(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002fda:	1101                	addi	sp,sp,-32
    80002fdc:	ec06                	sd	ra,24(sp)
    80002fde:	e822                	sd	s0,16(sp)
    80002fe0:	e426                	sd	s1,8(sp)
    80002fe2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fe4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002fe8:	00074d63          	bltz	a4,80003002 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002fec:	57fd                	li	a5,-1
    80002fee:	17fe                	slli	a5,a5,0x3f
    80002ff0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ff2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ff4:	06f70363          	beq	a4,a5,8000305a <devintr+0x80>
  }
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	64a2                	ld	s1,8(sp)
    80002ffe:	6105                	addi	sp,sp,32
    80003000:	8082                	ret
     (scause & 0xff) == 9){
    80003002:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003006:	46a5                	li	a3,9
    80003008:	fed792e3          	bne	a5,a3,80002fec <devintr+0x12>
    int irq = plic_claim();
    8000300c:	00004097          	auipc	ra,0x4
    80003010:	9bc080e7          	jalr	-1604(ra) # 800069c8 <plic_claim>
    80003014:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003016:	47a9                	li	a5,10
    80003018:	02f50763          	beq	a0,a5,80003046 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000301c:	4785                	li	a5,1
    8000301e:	02f50963          	beq	a0,a5,80003050 <devintr+0x76>
    return 1;
    80003022:	4505                	li	a0,1
    } else if(irq){
    80003024:	d8f1                	beqz	s1,80002ff8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003026:	85a6                	mv	a1,s1
    80003028:	00005517          	auipc	a0,0x5
    8000302c:	41850513          	addi	a0,a0,1048 # 80008440 <states.0+0x38>
    80003030:	ffffd097          	auipc	ra,0xffffd
    80003034:	544080e7          	jalr	1348(ra) # 80000574 <printf>
      plic_complete(irq);
    80003038:	8526                	mv	a0,s1
    8000303a:	00004097          	auipc	ra,0x4
    8000303e:	9b2080e7          	jalr	-1614(ra) # 800069ec <plic_complete>
    return 1;
    80003042:	4505                	li	a0,1
    80003044:	bf55                	j	80002ff8 <devintr+0x1e>
      uartintr();
    80003046:	ffffe097          	auipc	ra,0xffffe
    8000304a:	940080e7          	jalr	-1728(ra) # 80000986 <uartintr>
    8000304e:	b7ed                	j	80003038 <devintr+0x5e>
      virtio_disk_intr();
    80003050:	00004097          	auipc	ra,0x4
    80003054:	e2e080e7          	jalr	-466(ra) # 80006e7e <virtio_disk_intr>
    80003058:	b7c5                	j	80003038 <devintr+0x5e>
    if(cpuid() == 0){
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	ff2080e7          	jalr	-14(ra) # 8000204c <cpuid>
    80003062:	c901                	beqz	a0,80003072 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003064:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003068:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000306a:	14479073          	csrw	sip,a5
    return 2;
    8000306e:	4509                	li	a0,2
    80003070:	b761                	j	80002ff8 <devintr+0x1e>
      clockintr();
    80003072:	00000097          	auipc	ra,0x0
    80003076:	f22080e7          	jalr	-222(ra) # 80002f94 <clockintr>
    8000307a:	b7ed                	j	80003064 <devintr+0x8a>

000000008000307c <usertrap>:
{
    8000307c:	1101                	addi	sp,sp,-32
    8000307e:	ec06                	sd	ra,24(sp)
    80003080:	e822                	sd	s0,16(sp)
    80003082:	e426                	sd	s1,8(sp)
    80003084:	e04a                	sd	s2,0(sp)
    80003086:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003088:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000308c:	1007f793          	andi	a5,a5,256
    80003090:	efb9                	bnez	a5,800030ee <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003092:	00004797          	auipc	a5,0x4
    80003096:	82e78793          	addi	a5,a5,-2002 # 800068c0 <kernelvec>
    8000309a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000309e:	fffff097          	auipc	ra,0xfffff
    800030a2:	fda080e7          	jalr	-38(ra) # 80002078 <myproc>
    800030a6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800030a8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030aa:	14102773          	csrr	a4,sepc
    800030ae:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030b0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800030b4:	47a1                	li	a5,8
    800030b6:	04f70463          	beq	a4,a5,800030fe <usertrap+0x82>
    800030ba:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    800030be:	47b5                	li	a5,13
    800030c0:	00f70763          	beq	a4,a5,800030ce <usertrap+0x52>
    800030c4:	14202773          	csrr	a4,scause
    800030c8:	47bd                	li	a5,15
    800030ca:	06f71163          	bne	a4,a5,8000312c <usertrap+0xb0>
    check_page_fault();
    800030ce:	fffff097          	auipc	ra,0xfffff
    800030d2:	9d8080e7          	jalr	-1576(ra) # 80001aa6 <check_page_fault>
  if(p->killed)
    800030d6:	549c                	lw	a5,40(s1)
    800030d8:	efc9                	bnez	a5,80003172 <usertrap+0xf6>
  usertrapret();
    800030da:	00000097          	auipc	ra,0x0
    800030de:	e1c080e7          	jalr	-484(ra) # 80002ef6 <usertrapret>
}
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6902                	ld	s2,0(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret
    panic("usertrap: not from user mode");
    800030ee:	00005517          	auipc	a0,0x5
    800030f2:	37250513          	addi	a0,a0,882 # 80008460 <states.0+0x58>
    800030f6:	ffffd097          	auipc	ra,0xffffd
    800030fa:	434080e7          	jalr	1076(ra) # 8000052a <panic>
    if(p->killed)
    800030fe:	551c                	lw	a5,40(a0)
    80003100:	e385                	bnez	a5,80003120 <usertrap+0xa4>
    p->trapframe->epc += 4;
    80003102:	6cb8                	ld	a4,88(s1)
    80003104:	6f1c                	ld	a5,24(a4)
    80003106:	0791                	addi	a5,a5,4
    80003108:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000310a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000310e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003112:	10079073          	csrw	sstatus,a5
    syscall();
    80003116:	00000097          	auipc	ra,0x0
    8000311a:	2ba080e7          	jalr	698(ra) # 800033d0 <syscall>
    8000311e:	bf65                	j	800030d6 <usertrap+0x5a>
      exit(-1);
    80003120:	557d                	li	a0,-1
    80003122:	00000097          	auipc	ra,0x0
    80003126:	a70080e7          	jalr	-1424(ra) # 80002b92 <exit>
    8000312a:	bfe1                	j	80003102 <usertrap+0x86>
  else if((which_dev = devintr()) != 0){
    8000312c:	00000097          	auipc	ra,0x0
    80003130:	eae080e7          	jalr	-338(ra) # 80002fda <devintr>
    80003134:	892a                	mv	s2,a0
    80003136:	c501                	beqz	a0,8000313e <usertrap+0xc2>
  if(p->killed)
    80003138:	549c                	lw	a5,40(s1)
    8000313a:	c3b1                	beqz	a5,8000317e <usertrap+0x102>
    8000313c:	a825                	j	80003174 <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000313e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003142:	5890                	lw	a2,48(s1)
    80003144:	00005517          	auipc	a0,0x5
    80003148:	33c50513          	addi	a0,a0,828 # 80008480 <states.0+0x78>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	428080e7          	jalr	1064(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003154:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003158:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	35450513          	addi	a0,a0,852 # 800084b0 <states.0+0xa8>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	410080e7          	jalr	1040(ra) # 80000574 <printf>
    p->killed = 1;
    8000316c:	4785                	li	a5,1
    8000316e:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003170:	a011                	j	80003174 <usertrap+0xf8>
    80003172:	4901                	li	s2,0
    exit(-1);
    80003174:	557d                	li	a0,-1
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	a1c080e7          	jalr	-1508(ra) # 80002b92 <exit>
  if(which_dev == 2)
    8000317e:	4789                	li	a5,2
    80003180:	f4f91de3          	bne	s2,a5,800030da <usertrap+0x5e>
    yield();
    80003184:	fffff097          	auipc	ra,0xfffff
    80003188:	776080e7          	jalr	1910(ra) # 800028fa <yield>
    8000318c:	b7b9                	j	800030da <usertrap+0x5e>

000000008000318e <kerneltrap>:
{
    8000318e:	7179                	addi	sp,sp,-48
    80003190:	f406                	sd	ra,40(sp)
    80003192:	f022                	sd	s0,32(sp)
    80003194:	ec26                	sd	s1,24(sp)
    80003196:	e84a                	sd	s2,16(sp)
    80003198:	e44e                	sd	s3,8(sp)
    8000319a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000319c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031a0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031a4:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800031a8:	1004f793          	andi	a5,s1,256
    800031ac:	cb85                	beqz	a5,800031dc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031b2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800031b4:	ef85                	bnez	a5,800031ec <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800031b6:	00000097          	auipc	ra,0x0
    800031ba:	e24080e7          	jalr	-476(ra) # 80002fda <devintr>
    800031be:	cd1d                	beqz	a0,800031fc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031c0:	4789                	li	a5,2
    800031c2:	06f50a63          	beq	a0,a5,80003236 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031c6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031ca:	10049073          	csrw	sstatus,s1
}
    800031ce:	70a2                	ld	ra,40(sp)
    800031d0:	7402                	ld	s0,32(sp)
    800031d2:	64e2                	ld	s1,24(sp)
    800031d4:	6942                	ld	s2,16(sp)
    800031d6:	69a2                	ld	s3,8(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031dc:	00005517          	auipc	a0,0x5
    800031e0:	2f450513          	addi	a0,a0,756 # 800084d0 <states.0+0xc8>
    800031e4:	ffffd097          	auipc	ra,0xffffd
    800031e8:	346080e7          	jalr	838(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	30c50513          	addi	a0,a0,780 # 800084f8 <states.0+0xf0>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	336080e7          	jalr	822(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800031fc:	85ce                	mv	a1,s3
    800031fe:	00005517          	auipc	a0,0x5
    80003202:	31a50513          	addi	a0,a0,794 # 80008518 <states.0+0x110>
    80003206:	ffffd097          	auipc	ra,0xffffd
    8000320a:	36e080e7          	jalr	878(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000320e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003212:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003216:	00005517          	auipc	a0,0x5
    8000321a:	31250513          	addi	a0,a0,786 # 80008528 <states.0+0x120>
    8000321e:	ffffd097          	auipc	ra,0xffffd
    80003222:	356080e7          	jalr	854(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	31a50513          	addi	a0,a0,794 # 80008540 <states.0+0x138>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	2fc080e7          	jalr	764(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	e42080e7          	jalr	-446(ra) # 80002078 <myproc>
    8000323e:	d541                	beqz	a0,800031c6 <kerneltrap+0x38>
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	e38080e7          	jalr	-456(ra) # 80002078 <myproc>
    80003248:	4d18                	lw	a4,24(a0)
    8000324a:	4791                	li	a5,4
    8000324c:	f6f71de3          	bne	a4,a5,800031c6 <kerneltrap+0x38>
    yield();
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	6aa080e7          	jalr	1706(ra) # 800028fa <yield>
    80003258:	b7bd                	j	800031c6 <kerneltrap+0x38>

000000008000325a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000325a:	1101                	addi	sp,sp,-32
    8000325c:	ec06                	sd	ra,24(sp)
    8000325e:	e822                	sd	s0,16(sp)
    80003260:	e426                	sd	s1,8(sp)
    80003262:	1000                	addi	s0,sp,32
    80003264:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003266:	fffff097          	auipc	ra,0xfffff
    8000326a:	e12080e7          	jalr	-494(ra) # 80002078 <myproc>
  switch (n) {
    8000326e:	4795                	li	a5,5
    80003270:	0497e163          	bltu	a5,s1,800032b2 <argraw+0x58>
    80003274:	048a                	slli	s1,s1,0x2
    80003276:	00005717          	auipc	a4,0x5
    8000327a:	30270713          	addi	a4,a4,770 # 80008578 <states.0+0x170>
    8000327e:	94ba                	add	s1,s1,a4
    80003280:	409c                	lw	a5,0(s1)
    80003282:	97ba                	add	a5,a5,a4
    80003284:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003286:	6d3c                	ld	a5,88(a0)
    80003288:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000328a:	60e2                	ld	ra,24(sp)
    8000328c:	6442                	ld	s0,16(sp)
    8000328e:	64a2                	ld	s1,8(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret
    return p->trapframe->a1;
    80003294:	6d3c                	ld	a5,88(a0)
    80003296:	7fa8                	ld	a0,120(a5)
    80003298:	bfcd                	j	8000328a <argraw+0x30>
    return p->trapframe->a2;
    8000329a:	6d3c                	ld	a5,88(a0)
    8000329c:	63c8                	ld	a0,128(a5)
    8000329e:	b7f5                	j	8000328a <argraw+0x30>
    return p->trapframe->a3;
    800032a0:	6d3c                	ld	a5,88(a0)
    800032a2:	67c8                	ld	a0,136(a5)
    800032a4:	b7dd                	j	8000328a <argraw+0x30>
    return p->trapframe->a4;
    800032a6:	6d3c                	ld	a5,88(a0)
    800032a8:	6bc8                	ld	a0,144(a5)
    800032aa:	b7c5                	j	8000328a <argraw+0x30>
    return p->trapframe->a5;
    800032ac:	6d3c                	ld	a5,88(a0)
    800032ae:	6fc8                	ld	a0,152(a5)
    800032b0:	bfe9                	j	8000328a <argraw+0x30>
  panic("argraw");
    800032b2:	00005517          	auipc	a0,0x5
    800032b6:	29e50513          	addi	a0,a0,670 # 80008550 <states.0+0x148>
    800032ba:	ffffd097          	auipc	ra,0xffffd
    800032be:	270080e7          	jalr	624(ra) # 8000052a <panic>

00000000800032c2 <fetchaddr>:
{
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	e04a                	sd	s2,0(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
    800032d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	da6080e7          	jalr	-602(ra) # 80002078 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800032da:	653c                	ld	a5,72(a0)
    800032dc:	02f4f863          	bgeu	s1,a5,8000330c <fetchaddr+0x4a>
    800032e0:	00848713          	addi	a4,s1,8
    800032e4:	02e7e663          	bltu	a5,a4,80003310 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800032e8:	46a1                	li	a3,8
    800032ea:	8626                	mv	a2,s1
    800032ec:	85ca                	mv	a1,s2
    800032ee:	6928                	ld	a0,80(a0)
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	3ea080e7          	jalr	1002(ra) # 800016da <copyin>
    800032f8:	00a03533          	snez	a0,a0
    800032fc:	40a00533          	neg	a0,a0
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6902                	ld	s2,0(sp)
    80003308:	6105                	addi	sp,sp,32
    8000330a:	8082                	ret
    return -1;
    8000330c:	557d                	li	a0,-1
    8000330e:	bfcd                	j	80003300 <fetchaddr+0x3e>
    80003310:	557d                	li	a0,-1
    80003312:	b7fd                	j	80003300 <fetchaddr+0x3e>

0000000080003314 <fetchstr>:
{
    80003314:	7179                	addi	sp,sp,-48
    80003316:	f406                	sd	ra,40(sp)
    80003318:	f022                	sd	s0,32(sp)
    8000331a:	ec26                	sd	s1,24(sp)
    8000331c:	e84a                	sd	s2,16(sp)
    8000331e:	e44e                	sd	s3,8(sp)
    80003320:	1800                	addi	s0,sp,48
    80003322:	892a                	mv	s2,a0
    80003324:	84ae                	mv	s1,a1
    80003326:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003328:	fffff097          	auipc	ra,0xfffff
    8000332c:	d50080e7          	jalr	-688(ra) # 80002078 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003330:	86ce                	mv	a3,s3
    80003332:	864a                	mv	a2,s2
    80003334:	85a6                	mv	a1,s1
    80003336:	6928                	ld	a0,80(a0)
    80003338:	ffffe097          	auipc	ra,0xffffe
    8000333c:	430080e7          	jalr	1072(ra) # 80001768 <copyinstr>
  if(err < 0)
    80003340:	00054763          	bltz	a0,8000334e <fetchstr+0x3a>
  return strlen(buf);
    80003344:	8526                	mv	a0,s1
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	b0c080e7          	jalr	-1268(ra) # 80000e52 <strlen>
}
    8000334e:	70a2                	ld	ra,40(sp)
    80003350:	7402                	ld	s0,32(sp)
    80003352:	64e2                	ld	s1,24(sp)
    80003354:	6942                	ld	s2,16(sp)
    80003356:	69a2                	ld	s3,8(sp)
    80003358:	6145                	addi	sp,sp,48
    8000335a:	8082                	ret

000000008000335c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	ef2080e7          	jalr	-270(ra) # 8000325a <argraw>
    80003370:	c088                	sw	a0,0(s1)
  return 0;
}
    80003372:	4501                	li	a0,0
    80003374:	60e2                	ld	ra,24(sp)
    80003376:	6442                	ld	s0,16(sp)
    80003378:	64a2                	ld	s1,8(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret

000000008000337e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000337e:	1101                	addi	sp,sp,-32
    80003380:	ec06                	sd	ra,24(sp)
    80003382:	e822                	sd	s0,16(sp)
    80003384:	e426                	sd	s1,8(sp)
    80003386:	1000                	addi	s0,sp,32
    80003388:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	ed0080e7          	jalr	-304(ra) # 8000325a <argraw>
    80003392:	e088                	sd	a0,0(s1)
  return 0;
}
    80003394:	4501                	li	a0,0
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	e04a                	sd	s2,0(sp)
    800033aa:	1000                	addi	s0,sp,32
    800033ac:	84ae                	mv	s1,a1
    800033ae:	8932                	mv	s2,a2
  *ip = argraw(n);
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	eaa080e7          	jalr	-342(ra) # 8000325a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800033b8:	864a                	mv	a2,s2
    800033ba:	85a6                	mv	a1,s1
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	f58080e7          	jalr	-168(ra) # 80003314 <fetchstr>
}
    800033c4:	60e2                	ld	ra,24(sp)
    800033c6:	6442                	ld	s0,16(sp)
    800033c8:	64a2                	ld	s1,8(sp)
    800033ca:	6902                	ld	s2,0(sp)
    800033cc:	6105                	addi	sp,sp,32
    800033ce:	8082                	ret

00000000800033d0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800033d0:	1101                	addi	sp,sp,-32
    800033d2:	ec06                	sd	ra,24(sp)
    800033d4:	e822                	sd	s0,16(sp)
    800033d6:	e426                	sd	s1,8(sp)
    800033d8:	e04a                	sd	s2,0(sp)
    800033da:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800033dc:	fffff097          	auipc	ra,0xfffff
    800033e0:	c9c080e7          	jalr	-868(ra) # 80002078 <myproc>
    800033e4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800033e6:	05853903          	ld	s2,88(a0)
    800033ea:	0a893783          	ld	a5,168(s2)
    800033ee:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800033f2:	37fd                	addiw	a5,a5,-1
    800033f4:	4751                	li	a4,20
    800033f6:	00f76f63          	bltu	a4,a5,80003414 <syscall+0x44>
    800033fa:	00369713          	slli	a4,a3,0x3
    800033fe:	00005797          	auipc	a5,0x5
    80003402:	19278793          	addi	a5,a5,402 # 80008590 <syscalls>
    80003406:	97ba                	add	a5,a5,a4
    80003408:	639c                	ld	a5,0(a5)
    8000340a:	c789                	beqz	a5,80003414 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000340c:	9782                	jalr	a5
    8000340e:	06a93823          	sd	a0,112(s2)
    80003412:	a839                	j	80003430 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003414:	15848613          	addi	a2,s1,344
    80003418:	588c                	lw	a1,48(s1)
    8000341a:	00005517          	auipc	a0,0x5
    8000341e:	13e50513          	addi	a0,a0,318 # 80008558 <states.0+0x150>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	152080e7          	jalr	338(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000342a:	6cbc                	ld	a5,88(s1)
    8000342c:	577d                	li	a4,-1
    8000342e:	fbb8                	sd	a4,112(a5)
  }
}
    80003430:	60e2                	ld	ra,24(sp)
    80003432:	6442                	ld	s0,16(sp)
    80003434:	64a2                	ld	s1,8(sp)
    80003436:	6902                	ld	s2,0(sp)
    80003438:	6105                	addi	sp,sp,32
    8000343a:	8082                	ret

000000008000343c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000343c:	1101                	addi	sp,sp,-32
    8000343e:	ec06                	sd	ra,24(sp)
    80003440:	e822                	sd	s0,16(sp)
    80003442:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003444:	fec40593          	addi	a1,s0,-20
    80003448:	4501                	li	a0,0
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	f12080e7          	jalr	-238(ra) # 8000335c <argint>
    return -1;
    80003452:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003454:	00054963          	bltz	a0,80003466 <sys_exit+0x2a>
  exit(n);
    80003458:	fec42503          	lw	a0,-20(s0)
    8000345c:	fffff097          	auipc	ra,0xfffff
    80003460:	736080e7          	jalr	1846(ra) # 80002b92 <exit>
  return 0;  // not reached
    80003464:	4781                	li	a5,0
}
    80003466:	853e                	mv	a0,a5
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	6105                	addi	sp,sp,32
    8000346e:	8082                	ret

0000000080003470 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003470:	1141                	addi	sp,sp,-16
    80003472:	e406                	sd	ra,8(sp)
    80003474:	e022                	sd	s0,0(sp)
    80003476:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003478:	fffff097          	auipc	ra,0xfffff
    8000347c:	c00080e7          	jalr	-1024(ra) # 80002078 <myproc>
}
    80003480:	5908                	lw	a0,48(a0)
    80003482:	60a2                	ld	ra,8(sp)
    80003484:	6402                	ld	s0,0(sp)
    80003486:	0141                	addi	sp,sp,16
    80003488:	8082                	ret

000000008000348a <sys_fork>:

uint64
sys_fork(void)
{
    8000348a:	1141                	addi	sp,sp,-16
    8000348c:	e406                	sd	ra,8(sp)
    8000348e:	e022                	sd	s0,0(sp)
    80003490:	0800                	addi	s0,sp,16
  return fork();
    80003492:	fffff097          	auipc	ra,0xfffff
    80003496:	0c6080e7          	jalr	198(ra) # 80002558 <fork>
}
    8000349a:	60a2                	ld	ra,8(sp)
    8000349c:	6402                	ld	s0,0(sp)
    8000349e:	0141                	addi	sp,sp,16
    800034a0:	8082                	ret

00000000800034a2 <sys_wait>:

uint64
sys_wait(void)
{
    800034a2:	1101                	addi	sp,sp,-32
    800034a4:	ec06                	sd	ra,24(sp)
    800034a6:	e822                	sd	s0,16(sp)
    800034a8:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800034aa:	fe840593          	addi	a1,s0,-24
    800034ae:	4501                	li	a0,0
    800034b0:	00000097          	auipc	ra,0x0
    800034b4:	ece080e7          	jalr	-306(ra) # 8000337e <argaddr>
    800034b8:	87aa                	mv	a5,a0
    return -1;
    800034ba:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800034bc:	0007c863          	bltz	a5,800034cc <sys_wait+0x2a>
  return wait(p);
    800034c0:	fe843503          	ld	a0,-24(s0)
    800034c4:	fffff097          	auipc	ra,0xfffff
    800034c8:	4d6080e7          	jalr	1238(ra) # 8000299a <wait>
}
    800034cc:	60e2                	ld	ra,24(sp)
    800034ce:	6442                	ld	s0,16(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800034d4:	7179                	addi	sp,sp,-48
    800034d6:	f406                	sd	ra,40(sp)
    800034d8:	f022                	sd	s0,32(sp)
    800034da:	ec26                	sd	s1,24(sp)
    800034dc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800034de:	fdc40593          	addi	a1,s0,-36
    800034e2:	4501                	li	a0,0
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	e78080e7          	jalr	-392(ra) # 8000335c <argint>
    return -1;
    800034ec:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800034ee:	00054f63          	bltz	a0,8000350c <sys_sbrk+0x38>
  addr = myproc()->sz;
    800034f2:	fffff097          	auipc	ra,0xfffff
    800034f6:	b86080e7          	jalr	-1146(ra) # 80002078 <myproc>
    800034fa:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800034fc:	fdc42503          	lw	a0,-36(s0)
    80003500:	fffff097          	auipc	ra,0xfffff
    80003504:	f12080e7          	jalr	-238(ra) # 80002412 <growproc>
    80003508:	00054863          	bltz	a0,80003518 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000350c:	8526                	mv	a0,s1
    8000350e:	70a2                	ld	ra,40(sp)
    80003510:	7402                	ld	s0,32(sp)
    80003512:	64e2                	ld	s1,24(sp)
    80003514:	6145                	addi	sp,sp,48
    80003516:	8082                	ret
    return -1;
    80003518:	54fd                	li	s1,-1
    8000351a:	bfcd                	j	8000350c <sys_sbrk+0x38>

000000008000351c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000351c:	7139                	addi	sp,sp,-64
    8000351e:	fc06                	sd	ra,56(sp)
    80003520:	f822                	sd	s0,48(sp)
    80003522:	f426                	sd	s1,40(sp)
    80003524:	f04a                	sd	s2,32(sp)
    80003526:	ec4e                	sd	s3,24(sp)
    80003528:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000352a:	fcc40593          	addi	a1,s0,-52
    8000352e:	4501                	li	a0,0
    80003530:	00000097          	auipc	ra,0x0
    80003534:	e2c080e7          	jalr	-468(ra) # 8000335c <argint>
    return -1;
    80003538:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000353a:	06054563          	bltz	a0,800035a4 <sys_sleep+0x88>
  acquire(&tickslock);
    8000353e:	0001c517          	auipc	a0,0x1c
    80003542:	19250513          	addi	a0,a0,402 # 8001f6d0 <tickslock>
    80003546:	ffffd097          	auipc	ra,0xffffd
    8000354a:	68c080e7          	jalr	1676(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000354e:	00006917          	auipc	s2,0x6
    80003552:	ae292903          	lw	s2,-1310(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003556:	fcc42783          	lw	a5,-52(s0)
    8000355a:	cf85                	beqz	a5,80003592 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000355c:	0001c997          	auipc	s3,0x1c
    80003560:	17498993          	addi	s3,s3,372 # 8001f6d0 <tickslock>
    80003564:	00006497          	auipc	s1,0x6
    80003568:	acc48493          	addi	s1,s1,-1332 # 80009030 <ticks>
    if(myproc()->killed){
    8000356c:	fffff097          	auipc	ra,0xfffff
    80003570:	b0c080e7          	jalr	-1268(ra) # 80002078 <myproc>
    80003574:	551c                	lw	a5,40(a0)
    80003576:	ef9d                	bnez	a5,800035b4 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003578:	85ce                	mv	a1,s3
    8000357a:	8526                	mv	a0,s1
    8000357c:	fffff097          	auipc	ra,0xfffff
    80003580:	3ba080e7          	jalr	954(ra) # 80002936 <sleep>
  while(ticks - ticks0 < n){
    80003584:	409c                	lw	a5,0(s1)
    80003586:	412787bb          	subw	a5,a5,s2
    8000358a:	fcc42703          	lw	a4,-52(s0)
    8000358e:	fce7efe3          	bltu	a5,a4,8000356c <sys_sleep+0x50>
  }
  release(&tickslock);
    80003592:	0001c517          	auipc	a0,0x1c
    80003596:	13e50513          	addi	a0,a0,318 # 8001f6d0 <tickslock>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	6ec080e7          	jalr	1772(ra) # 80000c86 <release>
  return 0;
    800035a2:	4781                	li	a5,0
}
    800035a4:	853e                	mv	a0,a5
    800035a6:	70e2                	ld	ra,56(sp)
    800035a8:	7442                	ld	s0,48(sp)
    800035aa:	74a2                	ld	s1,40(sp)
    800035ac:	7902                	ld	s2,32(sp)
    800035ae:	69e2                	ld	s3,24(sp)
    800035b0:	6121                	addi	sp,sp,64
    800035b2:	8082                	ret
      release(&tickslock);
    800035b4:	0001c517          	auipc	a0,0x1c
    800035b8:	11c50513          	addi	a0,a0,284 # 8001f6d0 <tickslock>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	6ca080e7          	jalr	1738(ra) # 80000c86 <release>
      return -1;
    800035c4:	57fd                	li	a5,-1
    800035c6:	bff9                	j	800035a4 <sys_sleep+0x88>

00000000800035c8 <sys_kill>:

uint64
sys_kill(void)
{
    800035c8:	1101                	addi	sp,sp,-32
    800035ca:	ec06                	sd	ra,24(sp)
    800035cc:	e822                	sd	s0,16(sp)
    800035ce:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800035d0:	fec40593          	addi	a1,s0,-20
    800035d4:	4501                	li	a0,0
    800035d6:	00000097          	auipc	ra,0x0
    800035da:	d86080e7          	jalr	-634(ra) # 8000335c <argint>
    800035de:	87aa                	mv	a5,a0
    return -1;
    800035e0:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800035e2:	0007c863          	bltz	a5,800035f2 <sys_kill+0x2a>
  return kill(pid);
    800035e6:	fec42503          	lw	a0,-20(s0)
    800035ea:	fffff097          	auipc	ra,0xfffff
    800035ee:	694080e7          	jalr	1684(ra) # 80002c7e <kill>
}
    800035f2:	60e2                	ld	ra,24(sp)
    800035f4:	6442                	ld	s0,16(sp)
    800035f6:	6105                	addi	sp,sp,32
    800035f8:	8082                	ret

00000000800035fa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800035fa:	1101                	addi	sp,sp,-32
    800035fc:	ec06                	sd	ra,24(sp)
    800035fe:	e822                	sd	s0,16(sp)
    80003600:	e426                	sd	s1,8(sp)
    80003602:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003604:	0001c517          	auipc	a0,0x1c
    80003608:	0cc50513          	addi	a0,a0,204 # 8001f6d0 <tickslock>
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	5c6080e7          	jalr	1478(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003614:	00006497          	auipc	s1,0x6
    80003618:	a1c4a483          	lw	s1,-1508(s1) # 80009030 <ticks>
  release(&tickslock);
    8000361c:	0001c517          	auipc	a0,0x1c
    80003620:	0b450513          	addi	a0,a0,180 # 8001f6d0 <tickslock>
    80003624:	ffffd097          	auipc	ra,0xffffd
    80003628:	662080e7          	jalr	1634(ra) # 80000c86 <release>
  return xticks;
}
    8000362c:	02049513          	slli	a0,s1,0x20
    80003630:	9101                	srli	a0,a0,0x20
    80003632:	60e2                	ld	ra,24(sp)
    80003634:	6442                	ld	s0,16(sp)
    80003636:	64a2                	ld	s1,8(sp)
    80003638:	6105                	addi	sp,sp,32
    8000363a:	8082                	ret

000000008000363c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000363c:	7179                	addi	sp,sp,-48
    8000363e:	f406                	sd	ra,40(sp)
    80003640:	f022                	sd	s0,32(sp)
    80003642:	ec26                	sd	s1,24(sp)
    80003644:	e84a                	sd	s2,16(sp)
    80003646:	e44e                	sd	s3,8(sp)
    80003648:	e052                	sd	s4,0(sp)
    8000364a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000364c:	00005597          	auipc	a1,0x5
    80003650:	ff458593          	addi	a1,a1,-12 # 80008640 <syscalls+0xb0>
    80003654:	0001c517          	auipc	a0,0x1c
    80003658:	09450513          	addi	a0,a0,148 # 8001f6e8 <bcache>
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	4e6080e7          	jalr	1254(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003664:	00024797          	auipc	a5,0x24
    80003668:	08478793          	addi	a5,a5,132 # 800276e8 <bcache+0x8000>
    8000366c:	00024717          	auipc	a4,0x24
    80003670:	2e470713          	addi	a4,a4,740 # 80027950 <bcache+0x8268>
    80003674:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003678:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000367c:	0001c497          	auipc	s1,0x1c
    80003680:	08448493          	addi	s1,s1,132 # 8001f700 <bcache+0x18>
    b->next = bcache.head.next;
    80003684:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003686:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003688:	00005a17          	auipc	s4,0x5
    8000368c:	fc0a0a13          	addi	s4,s4,-64 # 80008648 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003690:	2b893783          	ld	a5,696(s2)
    80003694:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003696:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000369a:	85d2                	mv	a1,s4
    8000369c:	01048513          	addi	a0,s1,16
    800036a0:	00001097          	auipc	ra,0x1
    800036a4:	7d4080e7          	jalr	2004(ra) # 80004e74 <initsleeplock>
    bcache.head.next->prev = b;
    800036a8:	2b893783          	ld	a5,696(s2)
    800036ac:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800036ae:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800036b2:	45848493          	addi	s1,s1,1112
    800036b6:	fd349de3          	bne	s1,s3,80003690 <binit+0x54>
  }
}
    800036ba:	70a2                	ld	ra,40(sp)
    800036bc:	7402                	ld	s0,32(sp)
    800036be:	64e2                	ld	s1,24(sp)
    800036c0:	6942                	ld	s2,16(sp)
    800036c2:	69a2                	ld	s3,8(sp)
    800036c4:	6a02                	ld	s4,0(sp)
    800036c6:	6145                	addi	sp,sp,48
    800036c8:	8082                	ret

00000000800036ca <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800036ca:	7179                	addi	sp,sp,-48
    800036cc:	f406                	sd	ra,40(sp)
    800036ce:	f022                	sd	s0,32(sp)
    800036d0:	ec26                	sd	s1,24(sp)
    800036d2:	e84a                	sd	s2,16(sp)
    800036d4:	e44e                	sd	s3,8(sp)
    800036d6:	1800                	addi	s0,sp,48
    800036d8:	892a                	mv	s2,a0
    800036da:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800036dc:	0001c517          	auipc	a0,0x1c
    800036e0:	00c50513          	addi	a0,a0,12 # 8001f6e8 <bcache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	4ee080e7          	jalr	1262(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800036ec:	00024497          	auipc	s1,0x24
    800036f0:	2b44b483          	ld	s1,692(s1) # 800279a0 <bcache+0x82b8>
    800036f4:	00024797          	auipc	a5,0x24
    800036f8:	25c78793          	addi	a5,a5,604 # 80027950 <bcache+0x8268>
    800036fc:	02f48f63          	beq	s1,a5,8000373a <bread+0x70>
    80003700:	873e                	mv	a4,a5
    80003702:	a021                	j	8000370a <bread+0x40>
    80003704:	68a4                	ld	s1,80(s1)
    80003706:	02e48a63          	beq	s1,a4,8000373a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000370a:	449c                	lw	a5,8(s1)
    8000370c:	ff279ce3          	bne	a5,s2,80003704 <bread+0x3a>
    80003710:	44dc                	lw	a5,12(s1)
    80003712:	ff3799e3          	bne	a5,s3,80003704 <bread+0x3a>
      b->refcnt++;
    80003716:	40bc                	lw	a5,64(s1)
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000371c:	0001c517          	auipc	a0,0x1c
    80003720:	fcc50513          	addi	a0,a0,-52 # 8001f6e8 <bcache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	562080e7          	jalr	1378(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000372c:	01048513          	addi	a0,s1,16
    80003730:	00001097          	auipc	ra,0x1
    80003734:	77e080e7          	jalr	1918(ra) # 80004eae <acquiresleep>
      return b;
    80003738:	a8b9                	j	80003796 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000373a:	00024497          	auipc	s1,0x24
    8000373e:	25e4b483          	ld	s1,606(s1) # 80027998 <bcache+0x82b0>
    80003742:	00024797          	auipc	a5,0x24
    80003746:	20e78793          	addi	a5,a5,526 # 80027950 <bcache+0x8268>
    8000374a:	00f48863          	beq	s1,a5,8000375a <bread+0x90>
    8000374e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003750:	40bc                	lw	a5,64(s1)
    80003752:	cf81                	beqz	a5,8000376a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003754:	64a4                	ld	s1,72(s1)
    80003756:	fee49de3          	bne	s1,a4,80003750 <bread+0x86>
  panic("bget: no buffers");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	ef650513          	addi	a0,a0,-266 # 80008650 <syscalls+0xc0>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	dc8080e7          	jalr	-568(ra) # 8000052a <panic>
      b->dev = dev;
    8000376a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000376e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003772:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003776:	4785                	li	a5,1
    80003778:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000377a:	0001c517          	auipc	a0,0x1c
    8000377e:	f6e50513          	addi	a0,a0,-146 # 8001f6e8 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	504080e7          	jalr	1284(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    8000378a:	01048513          	addi	a0,s1,16
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	720080e7          	jalr	1824(ra) # 80004eae <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003796:	409c                	lw	a5,0(s1)
    80003798:	cb89                	beqz	a5,800037aa <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000379a:	8526                	mv	a0,s1
    8000379c:	70a2                	ld	ra,40(sp)
    8000379e:	7402                	ld	s0,32(sp)
    800037a0:	64e2                	ld	s1,24(sp)
    800037a2:	6942                	ld	s2,16(sp)
    800037a4:	69a2                	ld	s3,8(sp)
    800037a6:	6145                	addi	sp,sp,48
    800037a8:	8082                	ret
    virtio_disk_rw(b, 0);
    800037aa:	4581                	li	a1,0
    800037ac:	8526                	mv	a0,s1
    800037ae:	00003097          	auipc	ra,0x3
    800037b2:	448080e7          	jalr	1096(ra) # 80006bf6 <virtio_disk_rw>
    b->valid = 1;
    800037b6:	4785                	li	a5,1
    800037b8:	c09c                	sw	a5,0(s1)
  return b;
    800037ba:	b7c5                	j	8000379a <bread+0xd0>

00000000800037bc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800037bc:	1101                	addi	sp,sp,-32
    800037be:	ec06                	sd	ra,24(sp)
    800037c0:	e822                	sd	s0,16(sp)
    800037c2:	e426                	sd	s1,8(sp)
    800037c4:	1000                	addi	s0,sp,32
    800037c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800037c8:	0541                	addi	a0,a0,16
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	77e080e7          	jalr	1918(ra) # 80004f48 <holdingsleep>
    800037d2:	cd01                	beqz	a0,800037ea <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800037d4:	4585                	li	a1,1
    800037d6:	8526                	mv	a0,s1
    800037d8:	00003097          	auipc	ra,0x3
    800037dc:	41e080e7          	jalr	1054(ra) # 80006bf6 <virtio_disk_rw>
}
    800037e0:	60e2                	ld	ra,24(sp)
    800037e2:	6442                	ld	s0,16(sp)
    800037e4:	64a2                	ld	s1,8(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret
    panic("bwrite");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	e7e50513          	addi	a0,a0,-386 # 80008668 <syscalls+0xd8>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d38080e7          	jalr	-712(ra) # 8000052a <panic>

00000000800037fa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
    80003806:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003808:	01050913          	addi	s2,a0,16
    8000380c:	854a                	mv	a0,s2
    8000380e:	00001097          	auipc	ra,0x1
    80003812:	73a080e7          	jalr	1850(ra) # 80004f48 <holdingsleep>
    80003816:	c92d                	beqz	a0,80003888 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003818:	854a                	mv	a0,s2
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	6ea080e7          	jalr	1770(ra) # 80004f04 <releasesleep>

  acquire(&bcache.lock);
    80003822:	0001c517          	auipc	a0,0x1c
    80003826:	ec650513          	addi	a0,a0,-314 # 8001f6e8 <bcache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	3a8080e7          	jalr	936(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003832:	40bc                	lw	a5,64(s1)
    80003834:	37fd                	addiw	a5,a5,-1
    80003836:	0007871b          	sext.w	a4,a5
    8000383a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000383c:	eb05                	bnez	a4,8000386c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000383e:	68bc                	ld	a5,80(s1)
    80003840:	64b8                	ld	a4,72(s1)
    80003842:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003844:	64bc                	ld	a5,72(s1)
    80003846:	68b8                	ld	a4,80(s1)
    80003848:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000384a:	00024797          	auipc	a5,0x24
    8000384e:	e9e78793          	addi	a5,a5,-354 # 800276e8 <bcache+0x8000>
    80003852:	2b87b703          	ld	a4,696(a5)
    80003856:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003858:	00024717          	auipc	a4,0x24
    8000385c:	0f870713          	addi	a4,a4,248 # 80027950 <bcache+0x8268>
    80003860:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003862:	2b87b703          	ld	a4,696(a5)
    80003866:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003868:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000386c:	0001c517          	auipc	a0,0x1c
    80003870:	e7c50513          	addi	a0,a0,-388 # 8001f6e8 <bcache>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	412080e7          	jalr	1042(ra) # 80000c86 <release>
}
    8000387c:	60e2                	ld	ra,24(sp)
    8000387e:	6442                	ld	s0,16(sp)
    80003880:	64a2                	ld	s1,8(sp)
    80003882:	6902                	ld	s2,0(sp)
    80003884:	6105                	addi	sp,sp,32
    80003886:	8082                	ret
    panic("brelse");
    80003888:	00005517          	auipc	a0,0x5
    8000388c:	de850513          	addi	a0,a0,-536 # 80008670 <syscalls+0xe0>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	c9a080e7          	jalr	-870(ra) # 8000052a <panic>

0000000080003898 <bpin>:

void
bpin(struct buf *b) {
    80003898:	1101                	addi	sp,sp,-32
    8000389a:	ec06                	sd	ra,24(sp)
    8000389c:	e822                	sd	s0,16(sp)
    8000389e:	e426                	sd	s1,8(sp)
    800038a0:	1000                	addi	s0,sp,32
    800038a2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038a4:	0001c517          	auipc	a0,0x1c
    800038a8:	e4450513          	addi	a0,a0,-444 # 8001f6e8 <bcache>
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	326080e7          	jalr	806(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800038b4:	40bc                	lw	a5,64(s1)
    800038b6:	2785                	addiw	a5,a5,1
    800038b8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038ba:	0001c517          	auipc	a0,0x1c
    800038be:	e2e50513          	addi	a0,a0,-466 # 8001f6e8 <bcache>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	3c4080e7          	jalr	964(ra) # 80000c86 <release>
}
    800038ca:	60e2                	ld	ra,24(sp)
    800038cc:	6442                	ld	s0,16(sp)
    800038ce:	64a2                	ld	s1,8(sp)
    800038d0:	6105                	addi	sp,sp,32
    800038d2:	8082                	ret

00000000800038d4 <bunpin>:

void
bunpin(struct buf *b) {
    800038d4:	1101                	addi	sp,sp,-32
    800038d6:	ec06                	sd	ra,24(sp)
    800038d8:	e822                	sd	s0,16(sp)
    800038da:	e426                	sd	s1,8(sp)
    800038dc:	1000                	addi	s0,sp,32
    800038de:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800038e0:	0001c517          	auipc	a0,0x1c
    800038e4:	e0850513          	addi	a0,a0,-504 # 8001f6e8 <bcache>
    800038e8:	ffffd097          	auipc	ra,0xffffd
    800038ec:	2ea080e7          	jalr	746(ra) # 80000bd2 <acquire>
  b->refcnt--;
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	37fd                	addiw	a5,a5,-1
    800038f4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800038f6:	0001c517          	auipc	a0,0x1c
    800038fa:	df250513          	addi	a0,a0,-526 # 8001f6e8 <bcache>
    800038fe:	ffffd097          	auipc	ra,0xffffd
    80003902:	388080e7          	jalr	904(ra) # 80000c86 <release>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6105                	addi	sp,sp,32
    8000390e:	8082                	ret

0000000080003910 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003910:	1101                	addi	sp,sp,-32
    80003912:	ec06                	sd	ra,24(sp)
    80003914:	e822                	sd	s0,16(sp)
    80003916:	e426                	sd	s1,8(sp)
    80003918:	e04a                	sd	s2,0(sp)
    8000391a:	1000                	addi	s0,sp,32
    8000391c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000391e:	00d5d59b          	srliw	a1,a1,0xd
    80003922:	00024797          	auipc	a5,0x24
    80003926:	4a27a783          	lw	a5,1186(a5) # 80027dc4 <sb+0x1c>
    8000392a:	9dbd                	addw	a1,a1,a5
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	d9e080e7          	jalr	-610(ra) # 800036ca <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003934:	0074f713          	andi	a4,s1,7
    80003938:	4785                	li	a5,1
    8000393a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000393e:	14ce                	slli	s1,s1,0x33
    80003940:	90d9                	srli	s1,s1,0x36
    80003942:	00950733          	add	a4,a0,s1
    80003946:	05874703          	lbu	a4,88(a4)
    8000394a:	00e7f6b3          	and	a3,a5,a4
    8000394e:	c69d                	beqz	a3,8000397c <bfree+0x6c>
    80003950:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003952:	94aa                	add	s1,s1,a0
    80003954:	fff7c793          	not	a5,a5
    80003958:	8ff9                	and	a5,a5,a4
    8000395a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000395e:	00001097          	auipc	ra,0x1
    80003962:	430080e7          	jalr	1072(ra) # 80004d8e <log_write>
  brelse(bp);
    80003966:	854a                	mv	a0,s2
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	e92080e7          	jalr	-366(ra) # 800037fa <brelse>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6902                	ld	s2,0(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret
    panic("freeing free block");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	cfc50513          	addi	a0,a0,-772 # 80008678 <syscalls+0xe8>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	ba6080e7          	jalr	-1114(ra) # 8000052a <panic>

000000008000398c <balloc>:
{
    8000398c:	711d                	addi	sp,sp,-96
    8000398e:	ec86                	sd	ra,88(sp)
    80003990:	e8a2                	sd	s0,80(sp)
    80003992:	e4a6                	sd	s1,72(sp)
    80003994:	e0ca                	sd	s2,64(sp)
    80003996:	fc4e                	sd	s3,56(sp)
    80003998:	f852                	sd	s4,48(sp)
    8000399a:	f456                	sd	s5,40(sp)
    8000399c:	f05a                	sd	s6,32(sp)
    8000399e:	ec5e                	sd	s7,24(sp)
    800039a0:	e862                	sd	s8,16(sp)
    800039a2:	e466                	sd	s9,8(sp)
    800039a4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800039a6:	00024797          	auipc	a5,0x24
    800039aa:	4067a783          	lw	a5,1030(a5) # 80027dac <sb+0x4>
    800039ae:	cbd1                	beqz	a5,80003a42 <balloc+0xb6>
    800039b0:	8baa                	mv	s7,a0
    800039b2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800039b4:	00024b17          	auipc	s6,0x24
    800039b8:	3f4b0b13          	addi	s6,s6,1012 # 80027da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039bc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800039be:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039c0:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800039c2:	6c89                	lui	s9,0x2
    800039c4:	a831                	j	800039e0 <balloc+0x54>
    brelse(bp);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	e32080e7          	jalr	-462(ra) # 800037fa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800039d0:	015c87bb          	addw	a5,s9,s5
    800039d4:	00078a9b          	sext.w	s5,a5
    800039d8:	004b2703          	lw	a4,4(s6)
    800039dc:	06eaf363          	bgeu	s5,a4,80003a42 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800039e0:	41fad79b          	sraiw	a5,s5,0x1f
    800039e4:	0137d79b          	srliw	a5,a5,0x13
    800039e8:	015787bb          	addw	a5,a5,s5
    800039ec:	40d7d79b          	sraiw	a5,a5,0xd
    800039f0:	01cb2583          	lw	a1,28(s6)
    800039f4:	9dbd                	addw	a1,a1,a5
    800039f6:	855e                	mv	a0,s7
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	cd2080e7          	jalr	-814(ra) # 800036ca <bread>
    80003a00:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a02:	004b2503          	lw	a0,4(s6)
    80003a06:	000a849b          	sext.w	s1,s5
    80003a0a:	8662                	mv	a2,s8
    80003a0c:	faa4fde3          	bgeu	s1,a0,800039c6 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003a10:	41f6579b          	sraiw	a5,a2,0x1f
    80003a14:	01d7d69b          	srliw	a3,a5,0x1d
    80003a18:	00c6873b          	addw	a4,a3,a2
    80003a1c:	00777793          	andi	a5,a4,7
    80003a20:	9f95                	subw	a5,a5,a3
    80003a22:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003a26:	4037571b          	sraiw	a4,a4,0x3
    80003a2a:	00e906b3          	add	a3,s2,a4
    80003a2e:	0586c683          	lbu	a3,88(a3)
    80003a32:	00d7f5b3          	and	a1,a5,a3
    80003a36:	cd91                	beqz	a1,80003a52 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003a38:	2605                	addiw	a2,a2,1
    80003a3a:	2485                	addiw	s1,s1,1
    80003a3c:	fd4618e3          	bne	a2,s4,80003a0c <balloc+0x80>
    80003a40:	b759                	j	800039c6 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003a42:	00005517          	auipc	a0,0x5
    80003a46:	c4e50513          	addi	a0,a0,-946 # 80008690 <syscalls+0x100>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	ae0080e7          	jalr	-1312(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003a52:	974a                	add	a4,a4,s2
    80003a54:	8fd5                	or	a5,a5,a3
    80003a56:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003a5a:	854a                	mv	a0,s2
    80003a5c:	00001097          	auipc	ra,0x1
    80003a60:	332080e7          	jalr	818(ra) # 80004d8e <log_write>
        brelse(bp);
    80003a64:	854a                	mv	a0,s2
    80003a66:	00000097          	auipc	ra,0x0
    80003a6a:	d94080e7          	jalr	-620(ra) # 800037fa <brelse>
  bp = bread(dev, bno);
    80003a6e:	85a6                	mv	a1,s1
    80003a70:	855e                	mv	a0,s7
    80003a72:	00000097          	auipc	ra,0x0
    80003a76:	c58080e7          	jalr	-936(ra) # 800036ca <bread>
    80003a7a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003a7c:	40000613          	li	a2,1024
    80003a80:	4581                	li	a1,0
    80003a82:	05850513          	addi	a0,a0,88
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	248080e7          	jalr	584(ra) # 80000cce <memset>
  log_write(bp);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	2fe080e7          	jalr	766(ra) # 80004d8e <log_write>
  brelse(bp);
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	d60080e7          	jalr	-672(ra) # 800037fa <brelse>
}
    80003aa2:	8526                	mv	a0,s1
    80003aa4:	60e6                	ld	ra,88(sp)
    80003aa6:	6446                	ld	s0,80(sp)
    80003aa8:	64a6                	ld	s1,72(sp)
    80003aaa:	6906                	ld	s2,64(sp)
    80003aac:	79e2                	ld	s3,56(sp)
    80003aae:	7a42                	ld	s4,48(sp)
    80003ab0:	7aa2                	ld	s5,40(sp)
    80003ab2:	7b02                	ld	s6,32(sp)
    80003ab4:	6be2                	ld	s7,24(sp)
    80003ab6:	6c42                	ld	s8,16(sp)
    80003ab8:	6ca2                	ld	s9,8(sp)
    80003aba:	6125                	addi	sp,sp,96
    80003abc:	8082                	ret

0000000080003abe <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003abe:	7179                	addi	sp,sp,-48
    80003ac0:	f406                	sd	ra,40(sp)
    80003ac2:	f022                	sd	s0,32(sp)
    80003ac4:	ec26                	sd	s1,24(sp)
    80003ac6:	e84a                	sd	s2,16(sp)
    80003ac8:	e44e                	sd	s3,8(sp)
    80003aca:	e052                	sd	s4,0(sp)
    80003acc:	1800                	addi	s0,sp,48
    80003ace:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ad0:	47ad                	li	a5,11
    80003ad2:	04b7fe63          	bgeu	a5,a1,80003b2e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ad6:	ff45849b          	addiw	s1,a1,-12
    80003ada:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ade:	0ff00793          	li	a5,255
    80003ae2:	0ae7e463          	bltu	a5,a4,80003b8a <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ae6:	08052583          	lw	a1,128(a0)
    80003aea:	c5b5                	beqz	a1,80003b56 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003aec:	00092503          	lw	a0,0(s2)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	bda080e7          	jalr	-1062(ra) # 800036ca <bread>
    80003af8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003afa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003afe:	02049713          	slli	a4,s1,0x20
    80003b02:	01e75593          	srli	a1,a4,0x1e
    80003b06:	00b784b3          	add	s1,a5,a1
    80003b0a:	0004a983          	lw	s3,0(s1)
    80003b0e:	04098e63          	beqz	s3,80003b6a <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003b12:	8552                	mv	a0,s4
    80003b14:	00000097          	auipc	ra,0x0
    80003b18:	ce6080e7          	jalr	-794(ra) # 800037fa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003b1c:	854e                	mv	a0,s3
    80003b1e:	70a2                	ld	ra,40(sp)
    80003b20:	7402                	ld	s0,32(sp)
    80003b22:	64e2                	ld	s1,24(sp)
    80003b24:	6942                	ld	s2,16(sp)
    80003b26:	69a2                	ld	s3,8(sp)
    80003b28:	6a02                	ld	s4,0(sp)
    80003b2a:	6145                	addi	sp,sp,48
    80003b2c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003b2e:	02059793          	slli	a5,a1,0x20
    80003b32:	01e7d593          	srli	a1,a5,0x1e
    80003b36:	00b504b3          	add	s1,a0,a1
    80003b3a:	0504a983          	lw	s3,80(s1)
    80003b3e:	fc099fe3          	bnez	s3,80003b1c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003b42:	4108                	lw	a0,0(a0)
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	e48080e7          	jalr	-440(ra) # 8000398c <balloc>
    80003b4c:	0005099b          	sext.w	s3,a0
    80003b50:	0534a823          	sw	s3,80(s1)
    80003b54:	b7e1                	j	80003b1c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003b56:	4108                	lw	a0,0(a0)
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	e34080e7          	jalr	-460(ra) # 8000398c <balloc>
    80003b60:	0005059b          	sext.w	a1,a0
    80003b64:	08b92023          	sw	a1,128(s2)
    80003b68:	b751                	j	80003aec <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003b6a:	00092503          	lw	a0,0(s2)
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	e1e080e7          	jalr	-482(ra) # 8000398c <balloc>
    80003b76:	0005099b          	sext.w	s3,a0
    80003b7a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003b7e:	8552                	mv	a0,s4
    80003b80:	00001097          	auipc	ra,0x1
    80003b84:	20e080e7          	jalr	526(ra) # 80004d8e <log_write>
    80003b88:	b769                	j	80003b12 <bmap+0x54>
  panic("bmap: out of range");
    80003b8a:	00005517          	auipc	a0,0x5
    80003b8e:	b1e50513          	addi	a0,a0,-1250 # 800086a8 <syscalls+0x118>
    80003b92:	ffffd097          	auipc	ra,0xffffd
    80003b96:	998080e7          	jalr	-1640(ra) # 8000052a <panic>

0000000080003b9a <iget>:
{
    80003b9a:	7179                	addi	sp,sp,-48
    80003b9c:	f406                	sd	ra,40(sp)
    80003b9e:	f022                	sd	s0,32(sp)
    80003ba0:	ec26                	sd	s1,24(sp)
    80003ba2:	e84a                	sd	s2,16(sp)
    80003ba4:	e44e                	sd	s3,8(sp)
    80003ba6:	e052                	sd	s4,0(sp)
    80003ba8:	1800                	addi	s0,sp,48
    80003baa:	89aa                	mv	s3,a0
    80003bac:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003bae:	00024517          	auipc	a0,0x24
    80003bb2:	21a50513          	addi	a0,a0,538 # 80027dc8 <itable>
    80003bb6:	ffffd097          	auipc	ra,0xffffd
    80003bba:	01c080e7          	jalr	28(ra) # 80000bd2 <acquire>
  empty = 0;
    80003bbe:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bc0:	00024497          	auipc	s1,0x24
    80003bc4:	22048493          	addi	s1,s1,544 # 80027de0 <itable+0x18>
    80003bc8:	00026697          	auipc	a3,0x26
    80003bcc:	ca868693          	addi	a3,a3,-856 # 80029870 <log>
    80003bd0:	a039                	j	80003bde <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003bd2:	02090b63          	beqz	s2,80003c08 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003bd6:	08848493          	addi	s1,s1,136
    80003bda:	02d48a63          	beq	s1,a3,80003c0e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003bde:	449c                	lw	a5,8(s1)
    80003be0:	fef059e3          	blez	a5,80003bd2 <iget+0x38>
    80003be4:	4098                	lw	a4,0(s1)
    80003be6:	ff3716e3          	bne	a4,s3,80003bd2 <iget+0x38>
    80003bea:	40d8                	lw	a4,4(s1)
    80003bec:	ff4713e3          	bne	a4,s4,80003bd2 <iget+0x38>
      ip->ref++;
    80003bf0:	2785                	addiw	a5,a5,1
    80003bf2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003bf4:	00024517          	auipc	a0,0x24
    80003bf8:	1d450513          	addi	a0,a0,468 # 80027dc8 <itable>
    80003bfc:	ffffd097          	auipc	ra,0xffffd
    80003c00:	08a080e7          	jalr	138(ra) # 80000c86 <release>
      return ip;
    80003c04:	8926                	mv	s2,s1
    80003c06:	a03d                	j	80003c34 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003c08:	f7f9                	bnez	a5,80003bd6 <iget+0x3c>
    80003c0a:	8926                	mv	s2,s1
    80003c0c:	b7e9                	j	80003bd6 <iget+0x3c>
  if(empty == 0)
    80003c0e:	02090c63          	beqz	s2,80003c46 <iget+0xac>
  ip->dev = dev;
    80003c12:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003c16:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003c1a:	4785                	li	a5,1
    80003c1c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003c20:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003c24:	00024517          	auipc	a0,0x24
    80003c28:	1a450513          	addi	a0,a0,420 # 80027dc8 <itable>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	05a080e7          	jalr	90(ra) # 80000c86 <release>
}
    80003c34:	854a                	mv	a0,s2
    80003c36:	70a2                	ld	ra,40(sp)
    80003c38:	7402                	ld	s0,32(sp)
    80003c3a:	64e2                	ld	s1,24(sp)
    80003c3c:	6942                	ld	s2,16(sp)
    80003c3e:	69a2                	ld	s3,8(sp)
    80003c40:	6a02                	ld	s4,0(sp)
    80003c42:	6145                	addi	sp,sp,48
    80003c44:	8082                	ret
    panic("iget: no inodes");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	a7a50513          	addi	a0,a0,-1414 # 800086c0 <syscalls+0x130>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8dc080e7          	jalr	-1828(ra) # 8000052a <panic>

0000000080003c56 <fsinit>:
fsinit(int dev) {
    80003c56:	7179                	addi	sp,sp,-48
    80003c58:	f406                	sd	ra,40(sp)
    80003c5a:	f022                	sd	s0,32(sp)
    80003c5c:	ec26                	sd	s1,24(sp)
    80003c5e:	e84a                	sd	s2,16(sp)
    80003c60:	e44e                	sd	s3,8(sp)
    80003c62:	1800                	addi	s0,sp,48
    80003c64:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003c66:	4585                	li	a1,1
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	a62080e7          	jalr	-1438(ra) # 800036ca <bread>
    80003c70:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003c72:	00024997          	auipc	s3,0x24
    80003c76:	13698993          	addi	s3,s3,310 # 80027da8 <sb>
    80003c7a:	02000613          	li	a2,32
    80003c7e:	05850593          	addi	a1,a0,88
    80003c82:	854e                	mv	a0,s3
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	0a6080e7          	jalr	166(ra) # 80000d2a <memmove>
  brelse(bp);
    80003c8c:	8526                	mv	a0,s1
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	b6c080e7          	jalr	-1172(ra) # 800037fa <brelse>
  if(sb.magic != FSMAGIC)
    80003c96:	0009a703          	lw	a4,0(s3)
    80003c9a:	102037b7          	lui	a5,0x10203
    80003c9e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ca2:	02f71263          	bne	a4,a5,80003cc6 <fsinit+0x70>
  initlog(dev, &sb);
    80003ca6:	00024597          	auipc	a1,0x24
    80003caa:	10258593          	addi	a1,a1,258 # 80027da8 <sb>
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	e60080e7          	jalr	-416(ra) # 80004b10 <initlog>
}
    80003cb8:	70a2                	ld	ra,40(sp)
    80003cba:	7402                	ld	s0,32(sp)
    80003cbc:	64e2                	ld	s1,24(sp)
    80003cbe:	6942                	ld	s2,16(sp)
    80003cc0:	69a2                	ld	s3,8(sp)
    80003cc2:	6145                	addi	sp,sp,48
    80003cc4:	8082                	ret
    panic("invalid file system");
    80003cc6:	00005517          	auipc	a0,0x5
    80003cca:	a0a50513          	addi	a0,a0,-1526 # 800086d0 <syscalls+0x140>
    80003cce:	ffffd097          	auipc	ra,0xffffd
    80003cd2:	85c080e7          	jalr	-1956(ra) # 8000052a <panic>

0000000080003cd6 <iinit>:
{
    80003cd6:	7179                	addi	sp,sp,-48
    80003cd8:	f406                	sd	ra,40(sp)
    80003cda:	f022                	sd	s0,32(sp)
    80003cdc:	ec26                	sd	s1,24(sp)
    80003cde:	e84a                	sd	s2,16(sp)
    80003ce0:	e44e                	sd	s3,8(sp)
    80003ce2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ce4:	00005597          	auipc	a1,0x5
    80003ce8:	a0458593          	addi	a1,a1,-1532 # 800086e8 <syscalls+0x158>
    80003cec:	00024517          	auipc	a0,0x24
    80003cf0:	0dc50513          	addi	a0,a0,220 # 80027dc8 <itable>
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	e4e080e7          	jalr	-434(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003cfc:	00024497          	auipc	s1,0x24
    80003d00:	0f448493          	addi	s1,s1,244 # 80027df0 <itable+0x28>
    80003d04:	00026997          	auipc	s3,0x26
    80003d08:	b7c98993          	addi	s3,s3,-1156 # 80029880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003d0c:	00005917          	auipc	s2,0x5
    80003d10:	9e490913          	addi	s2,s2,-1564 # 800086f0 <syscalls+0x160>
    80003d14:	85ca                	mv	a1,s2
    80003d16:	8526                	mv	a0,s1
    80003d18:	00001097          	auipc	ra,0x1
    80003d1c:	15c080e7          	jalr	348(ra) # 80004e74 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003d20:	08848493          	addi	s1,s1,136
    80003d24:	ff3498e3          	bne	s1,s3,80003d14 <iinit+0x3e>
}
    80003d28:	70a2                	ld	ra,40(sp)
    80003d2a:	7402                	ld	s0,32(sp)
    80003d2c:	64e2                	ld	s1,24(sp)
    80003d2e:	6942                	ld	s2,16(sp)
    80003d30:	69a2                	ld	s3,8(sp)
    80003d32:	6145                	addi	sp,sp,48
    80003d34:	8082                	ret

0000000080003d36 <ialloc>:
{
    80003d36:	715d                	addi	sp,sp,-80
    80003d38:	e486                	sd	ra,72(sp)
    80003d3a:	e0a2                	sd	s0,64(sp)
    80003d3c:	fc26                	sd	s1,56(sp)
    80003d3e:	f84a                	sd	s2,48(sp)
    80003d40:	f44e                	sd	s3,40(sp)
    80003d42:	f052                	sd	s4,32(sp)
    80003d44:	ec56                	sd	s5,24(sp)
    80003d46:	e85a                	sd	s6,16(sp)
    80003d48:	e45e                	sd	s7,8(sp)
    80003d4a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d4c:	00024717          	auipc	a4,0x24
    80003d50:	06872703          	lw	a4,104(a4) # 80027db4 <sb+0xc>
    80003d54:	4785                	li	a5,1
    80003d56:	04e7fa63          	bgeu	a5,a4,80003daa <ialloc+0x74>
    80003d5a:	8aaa                	mv	s5,a0
    80003d5c:	8bae                	mv	s7,a1
    80003d5e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003d60:	00024a17          	auipc	s4,0x24
    80003d64:	048a0a13          	addi	s4,s4,72 # 80027da8 <sb>
    80003d68:	00048b1b          	sext.w	s6,s1
    80003d6c:	0044d793          	srli	a5,s1,0x4
    80003d70:	018a2583          	lw	a1,24(s4)
    80003d74:	9dbd                	addw	a1,a1,a5
    80003d76:	8556                	mv	a0,s5
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	952080e7          	jalr	-1710(ra) # 800036ca <bread>
    80003d80:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003d82:	05850993          	addi	s3,a0,88
    80003d86:	00f4f793          	andi	a5,s1,15
    80003d8a:	079a                	slli	a5,a5,0x6
    80003d8c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d8e:	00099783          	lh	a5,0(s3)
    80003d92:	c785                	beqz	a5,80003dba <ialloc+0x84>
    brelse(bp);
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	a66080e7          	jalr	-1434(ra) # 800037fa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d9c:	0485                	addi	s1,s1,1
    80003d9e:	00ca2703          	lw	a4,12(s4)
    80003da2:	0004879b          	sext.w	a5,s1
    80003da6:	fce7e1e3          	bltu	a5,a4,80003d68 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003daa:	00005517          	auipc	a0,0x5
    80003dae:	94e50513          	addi	a0,a0,-1714 # 800086f8 <syscalls+0x168>
    80003db2:	ffffc097          	auipc	ra,0xffffc
    80003db6:	778080e7          	jalr	1912(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003dba:	04000613          	li	a2,64
    80003dbe:	4581                	li	a1,0
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	ffffd097          	auipc	ra,0xffffd
    80003dc6:	f0c080e7          	jalr	-244(ra) # 80000cce <memset>
      dip->type = type;
    80003dca:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003dce:	854a                	mv	a0,s2
    80003dd0:	00001097          	auipc	ra,0x1
    80003dd4:	fbe080e7          	jalr	-66(ra) # 80004d8e <log_write>
      brelse(bp);
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	a20080e7          	jalr	-1504(ra) # 800037fa <brelse>
      return iget(dev, inum);
    80003de2:	85da                	mv	a1,s6
    80003de4:	8556                	mv	a0,s5
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	db4080e7          	jalr	-588(ra) # 80003b9a <iget>
}
    80003dee:	60a6                	ld	ra,72(sp)
    80003df0:	6406                	ld	s0,64(sp)
    80003df2:	74e2                	ld	s1,56(sp)
    80003df4:	7942                	ld	s2,48(sp)
    80003df6:	79a2                	ld	s3,40(sp)
    80003df8:	7a02                	ld	s4,32(sp)
    80003dfa:	6ae2                	ld	s5,24(sp)
    80003dfc:	6b42                	ld	s6,16(sp)
    80003dfe:	6ba2                	ld	s7,8(sp)
    80003e00:	6161                	addi	sp,sp,80
    80003e02:	8082                	ret

0000000080003e04 <iupdate>:
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	e426                	sd	s1,8(sp)
    80003e0c:	e04a                	sd	s2,0(sp)
    80003e0e:	1000                	addi	s0,sp,32
    80003e10:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e12:	415c                	lw	a5,4(a0)
    80003e14:	0047d79b          	srliw	a5,a5,0x4
    80003e18:	00024597          	auipc	a1,0x24
    80003e1c:	fa85a583          	lw	a1,-88(a1) # 80027dc0 <sb+0x18>
    80003e20:	9dbd                	addw	a1,a1,a5
    80003e22:	4108                	lw	a0,0(a0)
    80003e24:	00000097          	auipc	ra,0x0
    80003e28:	8a6080e7          	jalr	-1882(ra) # 800036ca <bread>
    80003e2c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e2e:	05850793          	addi	a5,a0,88
    80003e32:	40c8                	lw	a0,4(s1)
    80003e34:	893d                	andi	a0,a0,15
    80003e36:	051a                	slli	a0,a0,0x6
    80003e38:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003e3a:	04449703          	lh	a4,68(s1)
    80003e3e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003e42:	04649703          	lh	a4,70(s1)
    80003e46:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003e4a:	04849703          	lh	a4,72(s1)
    80003e4e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003e52:	04a49703          	lh	a4,74(s1)
    80003e56:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003e5a:	44f8                	lw	a4,76(s1)
    80003e5c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003e5e:	03400613          	li	a2,52
    80003e62:	05048593          	addi	a1,s1,80
    80003e66:	0531                	addi	a0,a0,12
    80003e68:	ffffd097          	auipc	ra,0xffffd
    80003e6c:	ec2080e7          	jalr	-318(ra) # 80000d2a <memmove>
  log_write(bp);
    80003e70:	854a                	mv	a0,s2
    80003e72:	00001097          	auipc	ra,0x1
    80003e76:	f1c080e7          	jalr	-228(ra) # 80004d8e <log_write>
  brelse(bp);
    80003e7a:	854a                	mv	a0,s2
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	97e080e7          	jalr	-1666(ra) # 800037fa <brelse>
}
    80003e84:	60e2                	ld	ra,24(sp)
    80003e86:	6442                	ld	s0,16(sp)
    80003e88:	64a2                	ld	s1,8(sp)
    80003e8a:	6902                	ld	s2,0(sp)
    80003e8c:	6105                	addi	sp,sp,32
    80003e8e:	8082                	ret

0000000080003e90 <idup>:
{
    80003e90:	1101                	addi	sp,sp,-32
    80003e92:	ec06                	sd	ra,24(sp)
    80003e94:	e822                	sd	s0,16(sp)
    80003e96:	e426                	sd	s1,8(sp)
    80003e98:	1000                	addi	s0,sp,32
    80003e9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e9c:	00024517          	auipc	a0,0x24
    80003ea0:	f2c50513          	addi	a0,a0,-212 # 80027dc8 <itable>
    80003ea4:	ffffd097          	auipc	ra,0xffffd
    80003ea8:	d2e080e7          	jalr	-722(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003eac:	449c                	lw	a5,8(s1)
    80003eae:	2785                	addiw	a5,a5,1
    80003eb0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eb2:	00024517          	auipc	a0,0x24
    80003eb6:	f1650513          	addi	a0,a0,-234 # 80027dc8 <itable>
    80003eba:	ffffd097          	auipc	ra,0xffffd
    80003ebe:	dcc080e7          	jalr	-564(ra) # 80000c86 <release>
}
    80003ec2:	8526                	mv	a0,s1
    80003ec4:	60e2                	ld	ra,24(sp)
    80003ec6:	6442                	ld	s0,16(sp)
    80003ec8:	64a2                	ld	s1,8(sp)
    80003eca:	6105                	addi	sp,sp,32
    80003ecc:	8082                	ret

0000000080003ece <ilock>:
{
    80003ece:	1101                	addi	sp,sp,-32
    80003ed0:	ec06                	sd	ra,24(sp)
    80003ed2:	e822                	sd	s0,16(sp)
    80003ed4:	e426                	sd	s1,8(sp)
    80003ed6:	e04a                	sd	s2,0(sp)
    80003ed8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003eda:	c115                	beqz	a0,80003efe <ilock+0x30>
    80003edc:	84aa                	mv	s1,a0
    80003ede:	451c                	lw	a5,8(a0)
    80003ee0:	00f05f63          	blez	a5,80003efe <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ee4:	0541                	addi	a0,a0,16
    80003ee6:	00001097          	auipc	ra,0x1
    80003eea:	fc8080e7          	jalr	-56(ra) # 80004eae <acquiresleep>
  if(ip->valid == 0){
    80003eee:	40bc                	lw	a5,64(s1)
    80003ef0:	cf99                	beqz	a5,80003f0e <ilock+0x40>
}
    80003ef2:	60e2                	ld	ra,24(sp)
    80003ef4:	6442                	ld	s0,16(sp)
    80003ef6:	64a2                	ld	s1,8(sp)
    80003ef8:	6902                	ld	s2,0(sp)
    80003efa:	6105                	addi	sp,sp,32
    80003efc:	8082                	ret
    panic("ilock");
    80003efe:	00005517          	auipc	a0,0x5
    80003f02:	81250513          	addi	a0,a0,-2030 # 80008710 <syscalls+0x180>
    80003f06:	ffffc097          	auipc	ra,0xffffc
    80003f0a:	624080e7          	jalr	1572(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f0e:	40dc                	lw	a5,4(s1)
    80003f10:	0047d79b          	srliw	a5,a5,0x4
    80003f14:	00024597          	auipc	a1,0x24
    80003f18:	eac5a583          	lw	a1,-340(a1) # 80027dc0 <sb+0x18>
    80003f1c:	9dbd                	addw	a1,a1,a5
    80003f1e:	4088                	lw	a0,0(s1)
    80003f20:	fffff097          	auipc	ra,0xfffff
    80003f24:	7aa080e7          	jalr	1962(ra) # 800036ca <bread>
    80003f28:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f2a:	05850593          	addi	a1,a0,88
    80003f2e:	40dc                	lw	a5,4(s1)
    80003f30:	8bbd                	andi	a5,a5,15
    80003f32:	079a                	slli	a5,a5,0x6
    80003f34:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003f36:	00059783          	lh	a5,0(a1)
    80003f3a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003f3e:	00259783          	lh	a5,2(a1)
    80003f42:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003f46:	00459783          	lh	a5,4(a1)
    80003f4a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003f4e:	00659783          	lh	a5,6(a1)
    80003f52:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003f56:	459c                	lw	a5,8(a1)
    80003f58:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003f5a:	03400613          	li	a2,52
    80003f5e:	05b1                	addi	a1,a1,12
    80003f60:	05048513          	addi	a0,s1,80
    80003f64:	ffffd097          	auipc	ra,0xffffd
    80003f68:	dc6080e7          	jalr	-570(ra) # 80000d2a <memmove>
    brelse(bp);
    80003f6c:	854a                	mv	a0,s2
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	88c080e7          	jalr	-1908(ra) # 800037fa <brelse>
    ip->valid = 1;
    80003f76:	4785                	li	a5,1
    80003f78:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003f7a:	04449783          	lh	a5,68(s1)
    80003f7e:	fbb5                	bnez	a5,80003ef2 <ilock+0x24>
      panic("ilock: no type");
    80003f80:	00004517          	auipc	a0,0x4
    80003f84:	79850513          	addi	a0,a0,1944 # 80008718 <syscalls+0x188>
    80003f88:	ffffc097          	auipc	ra,0xffffc
    80003f8c:	5a2080e7          	jalr	1442(ra) # 8000052a <panic>

0000000080003f90 <iunlock>:
{
    80003f90:	1101                	addi	sp,sp,-32
    80003f92:	ec06                	sd	ra,24(sp)
    80003f94:	e822                	sd	s0,16(sp)
    80003f96:	e426                	sd	s1,8(sp)
    80003f98:	e04a                	sd	s2,0(sp)
    80003f9a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f9c:	c905                	beqz	a0,80003fcc <iunlock+0x3c>
    80003f9e:	84aa                	mv	s1,a0
    80003fa0:	01050913          	addi	s2,a0,16
    80003fa4:	854a                	mv	a0,s2
    80003fa6:	00001097          	auipc	ra,0x1
    80003faa:	fa2080e7          	jalr	-94(ra) # 80004f48 <holdingsleep>
    80003fae:	cd19                	beqz	a0,80003fcc <iunlock+0x3c>
    80003fb0:	449c                	lw	a5,8(s1)
    80003fb2:	00f05d63          	blez	a5,80003fcc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003fb6:	854a                	mv	a0,s2
    80003fb8:	00001097          	auipc	ra,0x1
    80003fbc:	f4c080e7          	jalr	-180(ra) # 80004f04 <releasesleep>
}
    80003fc0:	60e2                	ld	ra,24(sp)
    80003fc2:	6442                	ld	s0,16(sp)
    80003fc4:	64a2                	ld	s1,8(sp)
    80003fc6:	6902                	ld	s2,0(sp)
    80003fc8:	6105                	addi	sp,sp,32
    80003fca:	8082                	ret
    panic("iunlock");
    80003fcc:	00004517          	auipc	a0,0x4
    80003fd0:	75c50513          	addi	a0,a0,1884 # 80008728 <syscalls+0x198>
    80003fd4:	ffffc097          	auipc	ra,0xffffc
    80003fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>

0000000080003fdc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003fdc:	7179                	addi	sp,sp,-48
    80003fde:	f406                	sd	ra,40(sp)
    80003fe0:	f022                	sd	s0,32(sp)
    80003fe2:	ec26                	sd	s1,24(sp)
    80003fe4:	e84a                	sd	s2,16(sp)
    80003fe6:	e44e                	sd	s3,8(sp)
    80003fe8:	e052                	sd	s4,0(sp)
    80003fea:	1800                	addi	s0,sp,48
    80003fec:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003fee:	05050493          	addi	s1,a0,80
    80003ff2:	08050913          	addi	s2,a0,128
    80003ff6:	a021                	j	80003ffe <itrunc+0x22>
    80003ff8:	0491                	addi	s1,s1,4
    80003ffa:	01248d63          	beq	s1,s2,80004014 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ffe:	408c                	lw	a1,0(s1)
    80004000:	dde5                	beqz	a1,80003ff8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004002:	0009a503          	lw	a0,0(s3)
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	90a080e7          	jalr	-1782(ra) # 80003910 <bfree>
      ip->addrs[i] = 0;
    8000400e:	0004a023          	sw	zero,0(s1)
    80004012:	b7dd                	j	80003ff8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004014:	0809a583          	lw	a1,128(s3)
    80004018:	e185                	bnez	a1,80004038 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000401a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000401e:	854e                	mv	a0,s3
    80004020:	00000097          	auipc	ra,0x0
    80004024:	de4080e7          	jalr	-540(ra) # 80003e04 <iupdate>
}
    80004028:	70a2                	ld	ra,40(sp)
    8000402a:	7402                	ld	s0,32(sp)
    8000402c:	64e2                	ld	s1,24(sp)
    8000402e:	6942                	ld	s2,16(sp)
    80004030:	69a2                	ld	s3,8(sp)
    80004032:	6a02                	ld	s4,0(sp)
    80004034:	6145                	addi	sp,sp,48
    80004036:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004038:	0009a503          	lw	a0,0(s3)
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	68e080e7          	jalr	1678(ra) # 800036ca <bread>
    80004044:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004046:	05850493          	addi	s1,a0,88
    8000404a:	45850913          	addi	s2,a0,1112
    8000404e:	a021                	j	80004056 <itrunc+0x7a>
    80004050:	0491                	addi	s1,s1,4
    80004052:	01248b63          	beq	s1,s2,80004068 <itrunc+0x8c>
      if(a[j])
    80004056:	408c                	lw	a1,0(s1)
    80004058:	dde5                	beqz	a1,80004050 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000405a:	0009a503          	lw	a0,0(s3)
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	8b2080e7          	jalr	-1870(ra) # 80003910 <bfree>
    80004066:	b7ed                	j	80004050 <itrunc+0x74>
    brelse(bp);
    80004068:	8552                	mv	a0,s4
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	790080e7          	jalr	1936(ra) # 800037fa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004072:	0809a583          	lw	a1,128(s3)
    80004076:	0009a503          	lw	a0,0(s3)
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	896080e7          	jalr	-1898(ra) # 80003910 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004082:	0809a023          	sw	zero,128(s3)
    80004086:	bf51                	j	8000401a <itrunc+0x3e>

0000000080004088 <iput>:
{
    80004088:	1101                	addi	sp,sp,-32
    8000408a:	ec06                	sd	ra,24(sp)
    8000408c:	e822                	sd	s0,16(sp)
    8000408e:	e426                	sd	s1,8(sp)
    80004090:	e04a                	sd	s2,0(sp)
    80004092:	1000                	addi	s0,sp,32
    80004094:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004096:	00024517          	auipc	a0,0x24
    8000409a:	d3250513          	addi	a0,a0,-718 # 80027dc8 <itable>
    8000409e:	ffffd097          	auipc	ra,0xffffd
    800040a2:	b34080e7          	jalr	-1228(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040a6:	4498                	lw	a4,8(s1)
    800040a8:	4785                	li	a5,1
    800040aa:	02f70363          	beq	a4,a5,800040d0 <iput+0x48>
  ip->ref--;
    800040ae:	449c                	lw	a5,8(s1)
    800040b0:	37fd                	addiw	a5,a5,-1
    800040b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040b4:	00024517          	auipc	a0,0x24
    800040b8:	d1450513          	addi	a0,a0,-748 # 80027dc8 <itable>
    800040bc:	ffffd097          	auipc	ra,0xffffd
    800040c0:	bca080e7          	jalr	-1078(ra) # 80000c86 <release>
}
    800040c4:	60e2                	ld	ra,24(sp)
    800040c6:	6442                	ld	s0,16(sp)
    800040c8:	64a2                	ld	s1,8(sp)
    800040ca:	6902                	ld	s2,0(sp)
    800040cc:	6105                	addi	sp,sp,32
    800040ce:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800040d0:	40bc                	lw	a5,64(s1)
    800040d2:	dff1                	beqz	a5,800040ae <iput+0x26>
    800040d4:	04a49783          	lh	a5,74(s1)
    800040d8:	fbf9                	bnez	a5,800040ae <iput+0x26>
    acquiresleep(&ip->lock);
    800040da:	01048913          	addi	s2,s1,16
    800040de:	854a                	mv	a0,s2
    800040e0:	00001097          	auipc	ra,0x1
    800040e4:	dce080e7          	jalr	-562(ra) # 80004eae <acquiresleep>
    release(&itable.lock);
    800040e8:	00024517          	auipc	a0,0x24
    800040ec:	ce050513          	addi	a0,a0,-800 # 80027dc8 <itable>
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	b96080e7          	jalr	-1130(ra) # 80000c86 <release>
    itrunc(ip);
    800040f8:	8526                	mv	a0,s1
    800040fa:	00000097          	auipc	ra,0x0
    800040fe:	ee2080e7          	jalr	-286(ra) # 80003fdc <itrunc>
    ip->type = 0;
    80004102:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004106:	8526                	mv	a0,s1
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	cfc080e7          	jalr	-772(ra) # 80003e04 <iupdate>
    ip->valid = 0;
    80004110:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004114:	854a                	mv	a0,s2
    80004116:	00001097          	auipc	ra,0x1
    8000411a:	dee080e7          	jalr	-530(ra) # 80004f04 <releasesleep>
    acquire(&itable.lock);
    8000411e:	00024517          	auipc	a0,0x24
    80004122:	caa50513          	addi	a0,a0,-854 # 80027dc8 <itable>
    80004126:	ffffd097          	auipc	ra,0xffffd
    8000412a:	aac080e7          	jalr	-1364(ra) # 80000bd2 <acquire>
    8000412e:	b741                	j	800040ae <iput+0x26>

0000000080004130 <iunlockput>:
{
    80004130:	1101                	addi	sp,sp,-32
    80004132:	ec06                	sd	ra,24(sp)
    80004134:	e822                	sd	s0,16(sp)
    80004136:	e426                	sd	s1,8(sp)
    80004138:	1000                	addi	s0,sp,32
    8000413a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	e54080e7          	jalr	-428(ra) # 80003f90 <iunlock>
  iput(ip);
    80004144:	8526                	mv	a0,s1
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	f42080e7          	jalr	-190(ra) # 80004088 <iput>
}
    8000414e:	60e2                	ld	ra,24(sp)
    80004150:	6442                	ld	s0,16(sp)
    80004152:	64a2                	ld	s1,8(sp)
    80004154:	6105                	addi	sp,sp,32
    80004156:	8082                	ret

0000000080004158 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004158:	1141                	addi	sp,sp,-16
    8000415a:	e422                	sd	s0,8(sp)
    8000415c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000415e:	411c                	lw	a5,0(a0)
    80004160:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004162:	415c                	lw	a5,4(a0)
    80004164:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004166:	04451783          	lh	a5,68(a0)
    8000416a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000416e:	04a51783          	lh	a5,74(a0)
    80004172:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004176:	04c56783          	lwu	a5,76(a0)
    8000417a:	e99c                	sd	a5,16(a1)
}
    8000417c:	6422                	ld	s0,8(sp)
    8000417e:	0141                	addi	sp,sp,16
    80004180:	8082                	ret

0000000080004182 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004182:	457c                	lw	a5,76(a0)
    80004184:	0ed7e963          	bltu	a5,a3,80004276 <readi+0xf4>
{
    80004188:	7159                	addi	sp,sp,-112
    8000418a:	f486                	sd	ra,104(sp)
    8000418c:	f0a2                	sd	s0,96(sp)
    8000418e:	eca6                	sd	s1,88(sp)
    80004190:	e8ca                	sd	s2,80(sp)
    80004192:	e4ce                	sd	s3,72(sp)
    80004194:	e0d2                	sd	s4,64(sp)
    80004196:	fc56                	sd	s5,56(sp)
    80004198:	f85a                	sd	s6,48(sp)
    8000419a:	f45e                	sd	s7,40(sp)
    8000419c:	f062                	sd	s8,32(sp)
    8000419e:	ec66                	sd	s9,24(sp)
    800041a0:	e86a                	sd	s10,16(sp)
    800041a2:	e46e                	sd	s11,8(sp)
    800041a4:	1880                	addi	s0,sp,112
    800041a6:	8baa                	mv	s7,a0
    800041a8:	8c2e                	mv	s8,a1
    800041aa:	8ab2                	mv	s5,a2
    800041ac:	84b6                	mv	s1,a3
    800041ae:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041b0:	9f35                	addw	a4,a4,a3
    return 0;
    800041b2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800041b4:	0ad76063          	bltu	a4,a3,80004254 <readi+0xd2>
  if(off + n > ip->size)
    800041b8:	00e7f463          	bgeu	a5,a4,800041c0 <readi+0x3e>
    n = ip->size - off;
    800041bc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041c0:	0a0b0963          	beqz	s6,80004272 <readi+0xf0>
    800041c4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800041c6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800041ca:	5cfd                	li	s9,-1
    800041cc:	a82d                	j	80004206 <readi+0x84>
    800041ce:	020a1d93          	slli	s11,s4,0x20
    800041d2:	020ddd93          	srli	s11,s11,0x20
    800041d6:	05890793          	addi	a5,s2,88
    800041da:	86ee                	mv	a3,s11
    800041dc:	963e                	add	a2,a2,a5
    800041de:	85d6                	mv	a1,s5
    800041e0:	8562                	mv	a0,s8
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	b0e080e7          	jalr	-1266(ra) # 80002cf0 <either_copyout>
    800041ea:	05950d63          	beq	a0,s9,80004244 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800041ee:	854a                	mv	a0,s2
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	60a080e7          	jalr	1546(ra) # 800037fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041f8:	013a09bb          	addw	s3,s4,s3
    800041fc:	009a04bb          	addw	s1,s4,s1
    80004200:	9aee                	add	s5,s5,s11
    80004202:	0569f763          	bgeu	s3,s6,80004250 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004206:	000ba903          	lw	s2,0(s7)
    8000420a:	00a4d59b          	srliw	a1,s1,0xa
    8000420e:	855e                	mv	a0,s7
    80004210:	00000097          	auipc	ra,0x0
    80004214:	8ae080e7          	jalr	-1874(ra) # 80003abe <bmap>
    80004218:	0005059b          	sext.w	a1,a0
    8000421c:	854a                	mv	a0,s2
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	4ac080e7          	jalr	1196(ra) # 800036ca <bread>
    80004226:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004228:	3ff4f613          	andi	a2,s1,1023
    8000422c:	40cd07bb          	subw	a5,s10,a2
    80004230:	413b073b          	subw	a4,s6,s3
    80004234:	8a3e                	mv	s4,a5
    80004236:	2781                	sext.w	a5,a5
    80004238:	0007069b          	sext.w	a3,a4
    8000423c:	f8f6f9e3          	bgeu	a3,a5,800041ce <readi+0x4c>
    80004240:	8a3a                	mv	s4,a4
    80004242:	b771                	j	800041ce <readi+0x4c>
      brelse(bp);
    80004244:	854a                	mv	a0,s2
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	5b4080e7          	jalr	1460(ra) # 800037fa <brelse>
      tot = -1;
    8000424e:	59fd                	li	s3,-1
  }
  return tot;
    80004250:	0009851b          	sext.w	a0,s3
}
    80004254:	70a6                	ld	ra,104(sp)
    80004256:	7406                	ld	s0,96(sp)
    80004258:	64e6                	ld	s1,88(sp)
    8000425a:	6946                	ld	s2,80(sp)
    8000425c:	69a6                	ld	s3,72(sp)
    8000425e:	6a06                	ld	s4,64(sp)
    80004260:	7ae2                	ld	s5,56(sp)
    80004262:	7b42                	ld	s6,48(sp)
    80004264:	7ba2                	ld	s7,40(sp)
    80004266:	7c02                	ld	s8,32(sp)
    80004268:	6ce2                	ld	s9,24(sp)
    8000426a:	6d42                	ld	s10,16(sp)
    8000426c:	6da2                	ld	s11,8(sp)
    8000426e:	6165                	addi	sp,sp,112
    80004270:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004272:	89da                	mv	s3,s6
    80004274:	bff1                	j	80004250 <readi+0xce>
    return 0;
    80004276:	4501                	li	a0,0
}
    80004278:	8082                	ret

000000008000427a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000427a:	457c                	lw	a5,76(a0)
    8000427c:	10d7e863          	bltu	a5,a3,8000438c <writei+0x112>
{
    80004280:	7159                	addi	sp,sp,-112
    80004282:	f486                	sd	ra,104(sp)
    80004284:	f0a2                	sd	s0,96(sp)
    80004286:	eca6                	sd	s1,88(sp)
    80004288:	e8ca                	sd	s2,80(sp)
    8000428a:	e4ce                	sd	s3,72(sp)
    8000428c:	e0d2                	sd	s4,64(sp)
    8000428e:	fc56                	sd	s5,56(sp)
    80004290:	f85a                	sd	s6,48(sp)
    80004292:	f45e                	sd	s7,40(sp)
    80004294:	f062                	sd	s8,32(sp)
    80004296:	ec66                	sd	s9,24(sp)
    80004298:	e86a                	sd	s10,16(sp)
    8000429a:	e46e                	sd	s11,8(sp)
    8000429c:	1880                	addi	s0,sp,112
    8000429e:	8b2a                	mv	s6,a0
    800042a0:	8c2e                	mv	s8,a1
    800042a2:	8ab2                	mv	s5,a2
    800042a4:	8936                	mv	s2,a3
    800042a6:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800042a8:	00e687bb          	addw	a5,a3,a4
    800042ac:	0ed7e263          	bltu	a5,a3,80004390 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800042b0:	00043737          	lui	a4,0x43
    800042b4:	0ef76063          	bltu	a4,a5,80004394 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042b8:	0c0b8863          	beqz	s7,80004388 <writei+0x10e>
    800042bc:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042be:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800042c2:	5cfd                	li	s9,-1
    800042c4:	a091                	j	80004308 <writei+0x8e>
    800042c6:	02099d93          	slli	s11,s3,0x20
    800042ca:	020ddd93          	srli	s11,s11,0x20
    800042ce:	05848793          	addi	a5,s1,88
    800042d2:	86ee                	mv	a3,s11
    800042d4:	8656                	mv	a2,s5
    800042d6:	85e2                	mv	a1,s8
    800042d8:	953e                	add	a0,a0,a5
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	a6c080e7          	jalr	-1428(ra) # 80002d46 <either_copyin>
    800042e2:	07950263          	beq	a0,s9,80004346 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800042e6:	8526                	mv	a0,s1
    800042e8:	00001097          	auipc	ra,0x1
    800042ec:	aa6080e7          	jalr	-1370(ra) # 80004d8e <log_write>
    brelse(bp);
    800042f0:	8526                	mv	a0,s1
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	508080e7          	jalr	1288(ra) # 800037fa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042fa:	01498a3b          	addw	s4,s3,s4
    800042fe:	0129893b          	addw	s2,s3,s2
    80004302:	9aee                	add	s5,s5,s11
    80004304:	057a7663          	bgeu	s4,s7,80004350 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004308:	000b2483          	lw	s1,0(s6)
    8000430c:	00a9559b          	srliw	a1,s2,0xa
    80004310:	855a                	mv	a0,s6
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	7ac080e7          	jalr	1964(ra) # 80003abe <bmap>
    8000431a:	0005059b          	sext.w	a1,a0
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	3aa080e7          	jalr	938(ra) # 800036ca <bread>
    80004328:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000432a:	3ff97513          	andi	a0,s2,1023
    8000432e:	40ad07bb          	subw	a5,s10,a0
    80004332:	414b873b          	subw	a4,s7,s4
    80004336:	89be                	mv	s3,a5
    80004338:	2781                	sext.w	a5,a5
    8000433a:	0007069b          	sext.w	a3,a4
    8000433e:	f8f6f4e3          	bgeu	a3,a5,800042c6 <writei+0x4c>
    80004342:	89ba                	mv	s3,a4
    80004344:	b749                	j	800042c6 <writei+0x4c>
      brelse(bp);
    80004346:	8526                	mv	a0,s1
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	4b2080e7          	jalr	1202(ra) # 800037fa <brelse>
  }

  if(off > ip->size)
    80004350:	04cb2783          	lw	a5,76(s6)
    80004354:	0127f463          	bgeu	a5,s2,8000435c <writei+0xe2>
    ip->size = off;
    80004358:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000435c:	855a                	mv	a0,s6
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	aa6080e7          	jalr	-1370(ra) # 80003e04 <iupdate>

  return tot;
    80004366:	000a051b          	sext.w	a0,s4
}
    8000436a:	70a6                	ld	ra,104(sp)
    8000436c:	7406                	ld	s0,96(sp)
    8000436e:	64e6                	ld	s1,88(sp)
    80004370:	6946                	ld	s2,80(sp)
    80004372:	69a6                	ld	s3,72(sp)
    80004374:	6a06                	ld	s4,64(sp)
    80004376:	7ae2                	ld	s5,56(sp)
    80004378:	7b42                	ld	s6,48(sp)
    8000437a:	7ba2                	ld	s7,40(sp)
    8000437c:	7c02                	ld	s8,32(sp)
    8000437e:	6ce2                	ld	s9,24(sp)
    80004380:	6d42                	ld	s10,16(sp)
    80004382:	6da2                	ld	s11,8(sp)
    80004384:	6165                	addi	sp,sp,112
    80004386:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004388:	8a5e                	mv	s4,s7
    8000438a:	bfc9                	j	8000435c <writei+0xe2>
    return -1;
    8000438c:	557d                	li	a0,-1
}
    8000438e:	8082                	ret
    return -1;
    80004390:	557d                	li	a0,-1
    80004392:	bfe1                	j	8000436a <writei+0xf0>
    return -1;
    80004394:	557d                	li	a0,-1
    80004396:	bfd1                	j	8000436a <writei+0xf0>

0000000080004398 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004398:	1141                	addi	sp,sp,-16
    8000439a:	e406                	sd	ra,8(sp)
    8000439c:	e022                	sd	s0,0(sp)
    8000439e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800043a0:	4639                	li	a2,14
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	a04080e7          	jalr	-1532(ra) # 80000da6 <strncmp>
}
    800043aa:	60a2                	ld	ra,8(sp)
    800043ac:	6402                	ld	s0,0(sp)
    800043ae:	0141                	addi	sp,sp,16
    800043b0:	8082                	ret

00000000800043b2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800043b2:	7139                	addi	sp,sp,-64
    800043b4:	fc06                	sd	ra,56(sp)
    800043b6:	f822                	sd	s0,48(sp)
    800043b8:	f426                	sd	s1,40(sp)
    800043ba:	f04a                	sd	s2,32(sp)
    800043bc:	ec4e                	sd	s3,24(sp)
    800043be:	e852                	sd	s4,16(sp)
    800043c0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800043c2:	04451703          	lh	a4,68(a0)
    800043c6:	4785                	li	a5,1
    800043c8:	00f71a63          	bne	a4,a5,800043dc <dirlookup+0x2a>
    800043cc:	892a                	mv	s2,a0
    800043ce:	89ae                	mv	s3,a1
    800043d0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d2:	457c                	lw	a5,76(a0)
    800043d4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800043d6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d8:	e79d                	bnez	a5,80004406 <dirlookup+0x54>
    800043da:	a8a5                	j	80004452 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800043dc:	00004517          	auipc	a0,0x4
    800043e0:	35450513          	addi	a0,a0,852 # 80008730 <syscalls+0x1a0>
    800043e4:	ffffc097          	auipc	ra,0xffffc
    800043e8:	146080e7          	jalr	326(ra) # 8000052a <panic>
      panic("dirlookup read");
    800043ec:	00004517          	auipc	a0,0x4
    800043f0:	35c50513          	addi	a0,a0,860 # 80008748 <syscalls+0x1b8>
    800043f4:	ffffc097          	auipc	ra,0xffffc
    800043f8:	136080e7          	jalr	310(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043fc:	24c1                	addiw	s1,s1,16
    800043fe:	04c92783          	lw	a5,76(s2)
    80004402:	04f4f763          	bgeu	s1,a5,80004450 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004406:	4741                	li	a4,16
    80004408:	86a6                	mv	a3,s1
    8000440a:	fc040613          	addi	a2,s0,-64
    8000440e:	4581                	li	a1,0
    80004410:	854a                	mv	a0,s2
    80004412:	00000097          	auipc	ra,0x0
    80004416:	d70080e7          	jalr	-656(ra) # 80004182 <readi>
    8000441a:	47c1                	li	a5,16
    8000441c:	fcf518e3          	bne	a0,a5,800043ec <dirlookup+0x3a>
    if(de.inum == 0)
    80004420:	fc045783          	lhu	a5,-64(s0)
    80004424:	dfe1                	beqz	a5,800043fc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004426:	fc240593          	addi	a1,s0,-62
    8000442a:	854e                	mv	a0,s3
    8000442c:	00000097          	auipc	ra,0x0
    80004430:	f6c080e7          	jalr	-148(ra) # 80004398 <namecmp>
    80004434:	f561                	bnez	a0,800043fc <dirlookup+0x4a>
      if(poff)
    80004436:	000a0463          	beqz	s4,8000443e <dirlookup+0x8c>
        *poff = off;
    8000443a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000443e:	fc045583          	lhu	a1,-64(s0)
    80004442:	00092503          	lw	a0,0(s2)
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	754080e7          	jalr	1876(ra) # 80003b9a <iget>
    8000444e:	a011                	j	80004452 <dirlookup+0xa0>
  return 0;
    80004450:	4501                	li	a0,0
}
    80004452:	70e2                	ld	ra,56(sp)
    80004454:	7442                	ld	s0,48(sp)
    80004456:	74a2                	ld	s1,40(sp)
    80004458:	7902                	ld	s2,32(sp)
    8000445a:	69e2                	ld	s3,24(sp)
    8000445c:	6a42                	ld	s4,16(sp)
    8000445e:	6121                	addi	sp,sp,64
    80004460:	8082                	ret

0000000080004462 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004462:	711d                	addi	sp,sp,-96
    80004464:	ec86                	sd	ra,88(sp)
    80004466:	e8a2                	sd	s0,80(sp)
    80004468:	e4a6                	sd	s1,72(sp)
    8000446a:	e0ca                	sd	s2,64(sp)
    8000446c:	fc4e                	sd	s3,56(sp)
    8000446e:	f852                	sd	s4,48(sp)
    80004470:	f456                	sd	s5,40(sp)
    80004472:	f05a                	sd	s6,32(sp)
    80004474:	ec5e                	sd	s7,24(sp)
    80004476:	e862                	sd	s8,16(sp)
    80004478:	e466                	sd	s9,8(sp)
    8000447a:	1080                	addi	s0,sp,96
    8000447c:	84aa                	mv	s1,a0
    8000447e:	8aae                	mv	s5,a1
    80004480:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004482:	00054703          	lbu	a4,0(a0)
    80004486:	02f00793          	li	a5,47
    8000448a:	02f70363          	beq	a4,a5,800044b0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000448e:	ffffe097          	auipc	ra,0xffffe
    80004492:	bea080e7          	jalr	-1046(ra) # 80002078 <myproc>
    80004496:	15053503          	ld	a0,336(a0)
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	9f6080e7          	jalr	-1546(ra) # 80003e90 <idup>
    800044a2:	89aa                	mv	s3,a0
  while(*path == '/')
    800044a4:	02f00913          	li	s2,47
  len = path - s;
    800044a8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800044aa:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800044ac:	4b85                	li	s7,1
    800044ae:	a865                	j	80004566 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800044b0:	4585                	li	a1,1
    800044b2:	4505                	li	a0,1
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	6e6080e7          	jalr	1766(ra) # 80003b9a <iget>
    800044bc:	89aa                	mv	s3,a0
    800044be:	b7dd                	j	800044a4 <namex+0x42>
      iunlockput(ip);
    800044c0:	854e                	mv	a0,s3
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	c6e080e7          	jalr	-914(ra) # 80004130 <iunlockput>
      return 0;
    800044ca:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800044cc:	854e                	mv	a0,s3
    800044ce:	60e6                	ld	ra,88(sp)
    800044d0:	6446                	ld	s0,80(sp)
    800044d2:	64a6                	ld	s1,72(sp)
    800044d4:	6906                	ld	s2,64(sp)
    800044d6:	79e2                	ld	s3,56(sp)
    800044d8:	7a42                	ld	s4,48(sp)
    800044da:	7aa2                	ld	s5,40(sp)
    800044dc:	7b02                	ld	s6,32(sp)
    800044de:	6be2                	ld	s7,24(sp)
    800044e0:	6c42                	ld	s8,16(sp)
    800044e2:	6ca2                	ld	s9,8(sp)
    800044e4:	6125                	addi	sp,sp,96
    800044e6:	8082                	ret
      iunlock(ip);
    800044e8:	854e                	mv	a0,s3
    800044ea:	00000097          	auipc	ra,0x0
    800044ee:	aa6080e7          	jalr	-1370(ra) # 80003f90 <iunlock>
      return ip;
    800044f2:	bfe9                	j	800044cc <namex+0x6a>
      iunlockput(ip);
    800044f4:	854e                	mv	a0,s3
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	c3a080e7          	jalr	-966(ra) # 80004130 <iunlockput>
      return 0;
    800044fe:	89e6                	mv	s3,s9
    80004500:	b7f1                	j	800044cc <namex+0x6a>
  len = path - s;
    80004502:	40b48633          	sub	a2,s1,a1
    80004506:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000450a:	099c5463          	bge	s8,s9,80004592 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000450e:	4639                	li	a2,14
    80004510:	8552                	mv	a0,s4
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	818080e7          	jalr	-2024(ra) # 80000d2a <memmove>
  while(*path == '/')
    8000451a:	0004c783          	lbu	a5,0(s1)
    8000451e:	01279763          	bne	a5,s2,8000452c <namex+0xca>
    path++;
    80004522:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004524:	0004c783          	lbu	a5,0(s1)
    80004528:	ff278de3          	beq	a5,s2,80004522 <namex+0xc0>
    ilock(ip);
    8000452c:	854e                	mv	a0,s3
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	9a0080e7          	jalr	-1632(ra) # 80003ece <ilock>
    if(ip->type != T_DIR){
    80004536:	04499783          	lh	a5,68(s3)
    8000453a:	f97793e3          	bne	a5,s7,800044c0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000453e:	000a8563          	beqz	s5,80004548 <namex+0xe6>
    80004542:	0004c783          	lbu	a5,0(s1)
    80004546:	d3cd                	beqz	a5,800044e8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004548:	865a                	mv	a2,s6
    8000454a:	85d2                	mv	a1,s4
    8000454c:	854e                	mv	a0,s3
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	e64080e7          	jalr	-412(ra) # 800043b2 <dirlookup>
    80004556:	8caa                	mv	s9,a0
    80004558:	dd51                	beqz	a0,800044f4 <namex+0x92>
    iunlockput(ip);
    8000455a:	854e                	mv	a0,s3
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	bd4080e7          	jalr	-1068(ra) # 80004130 <iunlockput>
    ip = next;
    80004564:	89e6                	mv	s3,s9
  while(*path == '/')
    80004566:	0004c783          	lbu	a5,0(s1)
    8000456a:	05279763          	bne	a5,s2,800045b8 <namex+0x156>
    path++;
    8000456e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004570:	0004c783          	lbu	a5,0(s1)
    80004574:	ff278de3          	beq	a5,s2,8000456e <namex+0x10c>
  if(*path == 0)
    80004578:	c79d                	beqz	a5,800045a6 <namex+0x144>
    path++;
    8000457a:	85a6                	mv	a1,s1
  len = path - s;
    8000457c:	8cda                	mv	s9,s6
    8000457e:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004580:	01278963          	beq	a5,s2,80004592 <namex+0x130>
    80004584:	dfbd                	beqz	a5,80004502 <namex+0xa0>
    path++;
    80004586:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004588:	0004c783          	lbu	a5,0(s1)
    8000458c:	ff279ce3          	bne	a5,s2,80004584 <namex+0x122>
    80004590:	bf8d                	j	80004502 <namex+0xa0>
    memmove(name, s, len);
    80004592:	2601                	sext.w	a2,a2
    80004594:	8552                	mv	a0,s4
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	794080e7          	jalr	1940(ra) # 80000d2a <memmove>
    name[len] = 0;
    8000459e:	9cd2                	add	s9,s9,s4
    800045a0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800045a4:	bf9d                	j	8000451a <namex+0xb8>
  if(nameiparent){
    800045a6:	f20a83e3          	beqz	s5,800044cc <namex+0x6a>
    iput(ip);
    800045aa:	854e                	mv	a0,s3
    800045ac:	00000097          	auipc	ra,0x0
    800045b0:	adc080e7          	jalr	-1316(ra) # 80004088 <iput>
    return 0;
    800045b4:	4981                	li	s3,0
    800045b6:	bf19                	j	800044cc <namex+0x6a>
  if(*path == 0)
    800045b8:	d7fd                	beqz	a5,800045a6 <namex+0x144>
  while(*path != '/' && *path != 0)
    800045ba:	0004c783          	lbu	a5,0(s1)
    800045be:	85a6                	mv	a1,s1
    800045c0:	b7d1                	j	80004584 <namex+0x122>

00000000800045c2 <dirlink>:
{
    800045c2:	7139                	addi	sp,sp,-64
    800045c4:	fc06                	sd	ra,56(sp)
    800045c6:	f822                	sd	s0,48(sp)
    800045c8:	f426                	sd	s1,40(sp)
    800045ca:	f04a                	sd	s2,32(sp)
    800045cc:	ec4e                	sd	s3,24(sp)
    800045ce:	e852                	sd	s4,16(sp)
    800045d0:	0080                	addi	s0,sp,64
    800045d2:	892a                	mv	s2,a0
    800045d4:	8a2e                	mv	s4,a1
    800045d6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800045d8:	4601                	li	a2,0
    800045da:	00000097          	auipc	ra,0x0
    800045de:	dd8080e7          	jalr	-552(ra) # 800043b2 <dirlookup>
    800045e2:	e93d                	bnez	a0,80004658 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800045e4:	04c92483          	lw	s1,76(s2)
    800045e8:	c49d                	beqz	s1,80004616 <dirlink+0x54>
    800045ea:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045ec:	4741                	li	a4,16
    800045ee:	86a6                	mv	a3,s1
    800045f0:	fc040613          	addi	a2,s0,-64
    800045f4:	4581                	li	a1,0
    800045f6:	854a                	mv	a0,s2
    800045f8:	00000097          	auipc	ra,0x0
    800045fc:	b8a080e7          	jalr	-1142(ra) # 80004182 <readi>
    80004600:	47c1                	li	a5,16
    80004602:	06f51163          	bne	a0,a5,80004664 <dirlink+0xa2>
    if(de.inum == 0)
    80004606:	fc045783          	lhu	a5,-64(s0)
    8000460a:	c791                	beqz	a5,80004616 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000460c:	24c1                	addiw	s1,s1,16
    8000460e:	04c92783          	lw	a5,76(s2)
    80004612:	fcf4ede3          	bltu	s1,a5,800045ec <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004616:	4639                	li	a2,14
    80004618:	85d2                	mv	a1,s4
    8000461a:	fc240513          	addi	a0,s0,-62
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	7c4080e7          	jalr	1988(ra) # 80000de2 <strncpy>
  de.inum = inum;
    80004626:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000462a:	4741                	li	a4,16
    8000462c:	86a6                	mv	a3,s1
    8000462e:	fc040613          	addi	a2,s0,-64
    80004632:	4581                	li	a1,0
    80004634:	854a                	mv	a0,s2
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	c44080e7          	jalr	-956(ra) # 8000427a <writei>
    8000463e:	872a                	mv	a4,a0
    80004640:	47c1                	li	a5,16
  return 0;
    80004642:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004644:	02f71863          	bne	a4,a5,80004674 <dirlink+0xb2>
}
    80004648:	70e2                	ld	ra,56(sp)
    8000464a:	7442                	ld	s0,48(sp)
    8000464c:	74a2                	ld	s1,40(sp)
    8000464e:	7902                	ld	s2,32(sp)
    80004650:	69e2                	ld	s3,24(sp)
    80004652:	6a42                	ld	s4,16(sp)
    80004654:	6121                	addi	sp,sp,64
    80004656:	8082                	ret
    iput(ip);
    80004658:	00000097          	auipc	ra,0x0
    8000465c:	a30080e7          	jalr	-1488(ra) # 80004088 <iput>
    return -1;
    80004660:	557d                	li	a0,-1
    80004662:	b7dd                	j	80004648 <dirlink+0x86>
      panic("dirlink read");
    80004664:	00004517          	auipc	a0,0x4
    80004668:	0f450513          	addi	a0,a0,244 # 80008758 <syscalls+0x1c8>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	ebe080e7          	jalr	-322(ra) # 8000052a <panic>
    panic("dirlink");
    80004674:	00004517          	auipc	a0,0x4
    80004678:	26c50513          	addi	a0,a0,620 # 800088e0 <syscalls+0x350>
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	eae080e7          	jalr	-338(ra) # 8000052a <panic>

0000000080004684 <namei>:

struct inode*
namei(char *path)
{
    80004684:	1101                	addi	sp,sp,-32
    80004686:	ec06                	sd	ra,24(sp)
    80004688:	e822                	sd	s0,16(sp)
    8000468a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000468c:	fe040613          	addi	a2,s0,-32
    80004690:	4581                	li	a1,0
    80004692:	00000097          	auipc	ra,0x0
    80004696:	dd0080e7          	jalr	-560(ra) # 80004462 <namex>
}
    8000469a:	60e2                	ld	ra,24(sp)
    8000469c:	6442                	ld	s0,16(sp)
    8000469e:	6105                	addi	sp,sp,32
    800046a0:	8082                	ret

00000000800046a2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800046a2:	1141                	addi	sp,sp,-16
    800046a4:	e406                	sd	ra,8(sp)
    800046a6:	e022                	sd	s0,0(sp)
    800046a8:	0800                	addi	s0,sp,16
    800046aa:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800046ac:	4585                	li	a1,1
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	db4080e7          	jalr	-588(ra) # 80004462 <namex>
}
    800046b6:	60a2                	ld	ra,8(sp)
    800046b8:	6402                	ld	s0,0(sp)
    800046ba:	0141                	addi	sp,sp,16
    800046bc:	8082                	ret

00000000800046be <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800046be:	1101                	addi	sp,sp,-32
    800046c0:	ec22                	sd	s0,24(sp)
    800046c2:	1000                	addi	s0,sp,32
    800046c4:	872a                	mv	a4,a0
    800046c6:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800046c8:	00004797          	auipc	a5,0x4
    800046cc:	0a078793          	addi	a5,a5,160 # 80008768 <syscalls+0x1d8>
    800046d0:	6394                	ld	a3,0(a5)
    800046d2:	fed43023          	sd	a3,-32(s0)
    800046d6:	0087d683          	lhu	a3,8(a5)
    800046da:	fed41423          	sh	a3,-24(s0)
    800046de:	00a7c783          	lbu	a5,10(a5)
    800046e2:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800046e6:	87ae                	mv	a5,a1
    if(i<0){
    800046e8:	02074b63          	bltz	a4,8000471e <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800046ec:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800046ee:	4629                	li	a2,10
        ++p;
    800046f0:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800046f2:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800046f6:	feed                	bnez	a3,800046f0 <itoa+0x32>
    *p = '\0';
    800046f8:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800046fc:	4629                	li	a2,10
    800046fe:	17fd                	addi	a5,a5,-1
    80004700:	02c766bb          	remw	a3,a4,a2
    80004704:	ff040593          	addi	a1,s0,-16
    80004708:	96ae                	add	a3,a3,a1
    8000470a:	ff06c683          	lbu	a3,-16(a3)
    8000470e:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004712:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004716:	f765                	bnez	a4,800046fe <itoa+0x40>
    return b;
}
    80004718:	6462                	ld	s0,24(sp)
    8000471a:	6105                	addi	sp,sp,32
    8000471c:	8082                	ret
        *p++ = '-';
    8000471e:	00158793          	addi	a5,a1,1
    80004722:	02d00693          	li	a3,45
    80004726:	00d58023          	sb	a3,0(a1)
        i *= -1;
    8000472a:	40e0073b          	negw	a4,a4
    8000472e:	bf7d                	j	800046ec <itoa+0x2e>

0000000080004730 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004730:	711d                	addi	sp,sp,-96
    80004732:	ec86                	sd	ra,88(sp)
    80004734:	e8a2                	sd	s0,80(sp)
    80004736:	e4a6                	sd	s1,72(sp)
    80004738:	e0ca                	sd	s2,64(sp)
    8000473a:	1080                	addi	s0,sp,96
    8000473c:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000473e:	4619                	li	a2,6
    80004740:	00004597          	auipc	a1,0x4
    80004744:	03858593          	addi	a1,a1,56 # 80008778 <syscalls+0x1e8>
    80004748:	fd040513          	addi	a0,s0,-48
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	5de080e7          	jalr	1502(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004754:	fd640593          	addi	a1,s0,-42
    80004758:	5888                	lw	a0,48(s1)
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	f64080e7          	jalr	-156(ra) # 800046be <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004762:	1684b503          	ld	a0,360(s1)
    80004766:	16050763          	beqz	a0,800048d4 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    8000476a:	00001097          	auipc	ra,0x1
    8000476e:	918080e7          	jalr	-1768(ra) # 80005082 <fileclose>

  begin_op();
    80004772:	00000097          	auipc	ra,0x0
    80004776:	444080e7          	jalr	1092(ra) # 80004bb6 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000477a:	fb040593          	addi	a1,s0,-80
    8000477e:	fd040513          	addi	a0,s0,-48
    80004782:	00000097          	auipc	ra,0x0
    80004786:	f20080e7          	jalr	-224(ra) # 800046a2 <nameiparent>
    8000478a:	892a                	mv	s2,a0
    8000478c:	cd69                	beqz	a0,80004866 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    8000478e:	fffff097          	auipc	ra,0xfffff
    80004792:	740080e7          	jalr	1856(ra) # 80003ece <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004796:	00004597          	auipc	a1,0x4
    8000479a:	fea58593          	addi	a1,a1,-22 # 80008780 <syscalls+0x1f0>
    8000479e:	fb040513          	addi	a0,s0,-80
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	bf6080e7          	jalr	-1034(ra) # 80004398 <namecmp>
    800047aa:	c57d                	beqz	a0,80004898 <removeSwapFile+0x168>
    800047ac:	00004597          	auipc	a1,0x4
    800047b0:	fdc58593          	addi	a1,a1,-36 # 80008788 <syscalls+0x1f8>
    800047b4:	fb040513          	addi	a0,s0,-80
    800047b8:	00000097          	auipc	ra,0x0
    800047bc:	be0080e7          	jalr	-1056(ra) # 80004398 <namecmp>
    800047c0:	cd61                	beqz	a0,80004898 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800047c2:	fac40613          	addi	a2,s0,-84
    800047c6:	fb040593          	addi	a1,s0,-80
    800047ca:	854a                	mv	a0,s2
    800047cc:	00000097          	auipc	ra,0x0
    800047d0:	be6080e7          	jalr	-1050(ra) # 800043b2 <dirlookup>
    800047d4:	84aa                	mv	s1,a0
    800047d6:	c169                	beqz	a0,80004898 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800047d8:	fffff097          	auipc	ra,0xfffff
    800047dc:	6f6080e7          	jalr	1782(ra) # 80003ece <ilock>

  if(ip->nlink < 1)
    800047e0:	04a49783          	lh	a5,74(s1)
    800047e4:	08f05763          	blez	a5,80004872 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800047e8:	04449703          	lh	a4,68(s1)
    800047ec:	4785                	li	a5,1
    800047ee:	08f70a63          	beq	a4,a5,80004882 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800047f2:	4641                	li	a2,16
    800047f4:	4581                	li	a1,0
    800047f6:	fc040513          	addi	a0,s0,-64
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	4d4080e7          	jalr	1236(ra) # 80000cce <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004802:	4741                	li	a4,16
    80004804:	fac42683          	lw	a3,-84(s0)
    80004808:	fc040613          	addi	a2,s0,-64
    8000480c:	4581                	li	a1,0
    8000480e:	854a                	mv	a0,s2
    80004810:	00000097          	auipc	ra,0x0
    80004814:	a6a080e7          	jalr	-1430(ra) # 8000427a <writei>
    80004818:	47c1                	li	a5,16
    8000481a:	08f51a63          	bne	a0,a5,800048ae <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    8000481e:	04449703          	lh	a4,68(s1)
    80004822:	4785                	li	a5,1
    80004824:	08f70d63          	beq	a4,a5,800048be <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004828:	854a                	mv	a0,s2
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	906080e7          	jalr	-1786(ra) # 80004130 <iunlockput>

  ip->nlink--;
    80004832:	04a4d783          	lhu	a5,74(s1)
    80004836:	37fd                	addiw	a5,a5,-1
    80004838:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000483c:	8526                	mv	a0,s1
    8000483e:	fffff097          	auipc	ra,0xfffff
    80004842:	5c6080e7          	jalr	1478(ra) # 80003e04 <iupdate>
  iunlockput(ip);
    80004846:	8526                	mv	a0,s1
    80004848:	00000097          	auipc	ra,0x0
    8000484c:	8e8080e7          	jalr	-1816(ra) # 80004130 <iunlockput>

  end_op();
    80004850:	00000097          	auipc	ra,0x0
    80004854:	3e6080e7          	jalr	998(ra) # 80004c36 <end_op>

  return 0;
    80004858:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    8000485a:	60e6                	ld	ra,88(sp)
    8000485c:	6446                	ld	s0,80(sp)
    8000485e:	64a6                	ld	s1,72(sp)
    80004860:	6906                	ld	s2,64(sp)
    80004862:	6125                	addi	sp,sp,96
    80004864:	8082                	ret
    end_op();
    80004866:	00000097          	auipc	ra,0x0
    8000486a:	3d0080e7          	jalr	976(ra) # 80004c36 <end_op>
    return -1;
    8000486e:	557d                	li	a0,-1
    80004870:	b7ed                	j	8000485a <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004872:	00004517          	auipc	a0,0x4
    80004876:	f1e50513          	addi	a0,a0,-226 # 80008790 <syscalls+0x200>
    8000487a:	ffffc097          	auipc	ra,0xffffc
    8000487e:	cb0080e7          	jalr	-848(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004882:	8526                	mv	a0,s1
    80004884:	00001097          	auipc	ra,0x1
    80004888:	798080e7          	jalr	1944(ra) # 8000601c <isdirempty>
    8000488c:	f13d                	bnez	a0,800047f2 <removeSwapFile+0xc2>
    iunlockput(ip);
    8000488e:	8526                	mv	a0,s1
    80004890:	00000097          	auipc	ra,0x0
    80004894:	8a0080e7          	jalr	-1888(ra) # 80004130 <iunlockput>
    iunlockput(dp);
    80004898:	854a                	mv	a0,s2
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	896080e7          	jalr	-1898(ra) # 80004130 <iunlockput>
    end_op();
    800048a2:	00000097          	auipc	ra,0x0
    800048a6:	394080e7          	jalr	916(ra) # 80004c36 <end_op>
    return -1;
    800048aa:	557d                	li	a0,-1
    800048ac:	b77d                	j	8000485a <removeSwapFile+0x12a>
    panic("unlink: writei");
    800048ae:	00004517          	auipc	a0,0x4
    800048b2:	efa50513          	addi	a0,a0,-262 # 800087a8 <syscalls+0x218>
    800048b6:	ffffc097          	auipc	ra,0xffffc
    800048ba:	c74080e7          	jalr	-908(ra) # 8000052a <panic>
    dp->nlink--;
    800048be:	04a95783          	lhu	a5,74(s2)
    800048c2:	37fd                	addiw	a5,a5,-1
    800048c4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800048c8:	854a                	mv	a0,s2
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	53a080e7          	jalr	1338(ra) # 80003e04 <iupdate>
    800048d2:	bf99                	j	80004828 <removeSwapFile+0xf8>
    return -1;
    800048d4:	557d                	li	a0,-1
    800048d6:	b751                	j	8000485a <removeSwapFile+0x12a>

00000000800048d8 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800048d8:	7179                	addi	sp,sp,-48
    800048da:	f406                	sd	ra,40(sp)
    800048dc:	f022                	sd	s0,32(sp)
    800048de:	ec26                	sd	s1,24(sp)
    800048e0:	e84a                	sd	s2,16(sp)
    800048e2:	1800                	addi	s0,sp,48
    800048e4:	84aa                	mv	s1,a0
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800048e6:	4619                	li	a2,6
    800048e8:	00004597          	auipc	a1,0x4
    800048ec:	e9058593          	addi	a1,a1,-368 # 80008778 <syscalls+0x1e8>
    800048f0:	fd040513          	addi	a0,s0,-48
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	436080e7          	jalr	1078(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    800048fc:	fd640593          	addi	a1,s0,-42
    80004900:	5888                	lw	a0,48(s1)
    80004902:	00000097          	auipc	ra,0x0
    80004906:	dbc080e7          	jalr	-580(ra) # 800046be <itoa>

  begin_op();
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	2ac080e7          	jalr	684(ra) # 80004bb6 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004912:	4681                	li	a3,0
    80004914:	4601                	li	a2,0
    80004916:	4589                	li	a1,2
    80004918:	fd040513          	addi	a0,s0,-48
    8000491c:	00002097          	auipc	ra,0x2
    80004920:	8f4080e7          	jalr	-1804(ra) # 80006210 <create>
    80004924:	892a                	mv	s2,a0
  iunlock(in);
    80004926:	fffff097          	auipc	ra,0xfffff
    8000492a:	66a080e7          	jalr	1642(ra) # 80003f90 <iunlock>
  p->swapFile = filealloc();
    8000492e:	00000097          	auipc	ra,0x0
    80004932:	698080e7          	jalr	1688(ra) # 80004fc6 <filealloc>
    80004936:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    8000493a:	cd1d                	beqz	a0,80004978 <createSwapFile+0xa0>
    panic("no slot for files on /store");
  p->swapFile->ip = in;
    8000493c:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004940:	1684b703          	ld	a4,360(s1)
    80004944:	4789                	li	a5,2
    80004946:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004948:	1684b703          	ld	a4,360(s1)
    8000494c:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004950:	1684b703          	ld	a4,360(s1)
    80004954:	4685                	li	a3,1
    80004956:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    8000495a:	1684b703          	ld	a4,360(s1)
    8000495e:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004962:	00000097          	auipc	ra,0x0
    80004966:	2d4080e7          	jalr	724(ra) # 80004c36 <end_op>
  return 0;
}
    8000496a:	4501                	li	a0,0
    8000496c:	70a2                	ld	ra,40(sp)
    8000496e:	7402                	ld	s0,32(sp)
    80004970:	64e2                	ld	s1,24(sp)
    80004972:	6942                	ld	s2,16(sp)
    80004974:	6145                	addi	sp,sp,48
    80004976:	8082                	ret
    panic("no slot for files on /store");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	e4050513          	addi	a0,a0,-448 # 800087b8 <syscalls+0x228>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	baa080e7          	jalr	-1110(ra) # 8000052a <panic>

0000000080004988 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004988:	1141                	addi	sp,sp,-16
    8000498a:	e406                	sd	ra,8(sp)
    8000498c:	e022                	sd	s0,0(sp)
    8000498e:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004990:	16853783          	ld	a5,360(a0)
    80004994:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004996:	8636                	mv	a2,a3
    80004998:	16853503          	ld	a0,360(a0)
    8000499c:	00001097          	auipc	ra,0x1
    800049a0:	ad8080e7          	jalr	-1320(ra) # 80005474 <kfilewrite>
}
    800049a4:	60a2                	ld	ra,8(sp)
    800049a6:	6402                	ld	s0,0(sp)
    800049a8:	0141                	addi	sp,sp,16
    800049aa:	8082                	ret

00000000800049ac <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800049ac:	1141                	addi	sp,sp,-16
    800049ae:	e406                	sd	ra,8(sp)
    800049b0:	e022                	sd	s0,0(sp)
    800049b2:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800049b4:	16853783          	ld	a5,360(a0)
    800049b8:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800049ba:	8636                	mv	a2,a3
    800049bc:	16853503          	ld	a0,360(a0)
    800049c0:	00001097          	auipc	ra,0x1
    800049c4:	9f2080e7          	jalr	-1550(ra) # 800053b2 <kfileread>
    800049c8:	60a2                	ld	ra,8(sp)
    800049ca:	6402                	ld	s0,0(sp)
    800049cc:	0141                	addi	sp,sp,16
    800049ce:	8082                	ret

00000000800049d0 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800049d0:	1101                	addi	sp,sp,-32
    800049d2:	ec06                	sd	ra,24(sp)
    800049d4:	e822                	sd	s0,16(sp)
    800049d6:	e426                	sd	s1,8(sp)
    800049d8:	e04a                	sd	s2,0(sp)
    800049da:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800049dc:	00025917          	auipc	s2,0x25
    800049e0:	e9490913          	addi	s2,s2,-364 # 80029870 <log>
    800049e4:	01892583          	lw	a1,24(s2)
    800049e8:	02892503          	lw	a0,40(s2)
    800049ec:	fffff097          	auipc	ra,0xfffff
    800049f0:	cde080e7          	jalr	-802(ra) # 800036ca <bread>
    800049f4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800049f6:	02c92683          	lw	a3,44(s2)
    800049fa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800049fc:	02d05863          	blez	a3,80004a2c <write_head+0x5c>
    80004a00:	00025797          	auipc	a5,0x25
    80004a04:	ea078793          	addi	a5,a5,-352 # 800298a0 <log+0x30>
    80004a08:	05c50713          	addi	a4,a0,92
    80004a0c:	36fd                	addiw	a3,a3,-1
    80004a0e:	02069613          	slli	a2,a3,0x20
    80004a12:	01e65693          	srli	a3,a2,0x1e
    80004a16:	00025617          	auipc	a2,0x25
    80004a1a:	e8e60613          	addi	a2,a2,-370 # 800298a4 <log+0x34>
    80004a1e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004a20:	4390                	lw	a2,0(a5)
    80004a22:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a24:	0791                	addi	a5,a5,4
    80004a26:	0711                	addi	a4,a4,4
    80004a28:	fed79ce3          	bne	a5,a3,80004a20 <write_head+0x50>
  }
  bwrite(buf);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	fffff097          	auipc	ra,0xfffff
    80004a32:	d8e080e7          	jalr	-626(ra) # 800037bc <bwrite>
  brelse(buf);
    80004a36:	8526                	mv	a0,s1
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	dc2080e7          	jalr	-574(ra) # 800037fa <brelse>
}
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	64a2                	ld	s1,8(sp)
    80004a46:	6902                	ld	s2,0(sp)
    80004a48:	6105                	addi	sp,sp,32
    80004a4a:	8082                	ret

0000000080004a4c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a4c:	00025797          	auipc	a5,0x25
    80004a50:	e507a783          	lw	a5,-432(a5) # 8002989c <log+0x2c>
    80004a54:	0af05d63          	blez	a5,80004b0e <install_trans+0xc2>
{
    80004a58:	7139                	addi	sp,sp,-64
    80004a5a:	fc06                	sd	ra,56(sp)
    80004a5c:	f822                	sd	s0,48(sp)
    80004a5e:	f426                	sd	s1,40(sp)
    80004a60:	f04a                	sd	s2,32(sp)
    80004a62:	ec4e                	sd	s3,24(sp)
    80004a64:	e852                	sd	s4,16(sp)
    80004a66:	e456                	sd	s5,8(sp)
    80004a68:	e05a                	sd	s6,0(sp)
    80004a6a:	0080                	addi	s0,sp,64
    80004a6c:	8b2a                	mv	s6,a0
    80004a6e:	00025a97          	auipc	s5,0x25
    80004a72:	e32a8a93          	addi	s5,s5,-462 # 800298a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a76:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004a78:	00025997          	auipc	s3,0x25
    80004a7c:	df898993          	addi	s3,s3,-520 # 80029870 <log>
    80004a80:	a00d                	j	80004aa2 <install_trans+0x56>
    brelse(lbuf);
    80004a82:	854a                	mv	a0,s2
    80004a84:	fffff097          	auipc	ra,0xfffff
    80004a88:	d76080e7          	jalr	-650(ra) # 800037fa <brelse>
    brelse(dbuf);
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	d6c080e7          	jalr	-660(ra) # 800037fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004a96:	2a05                	addiw	s4,s4,1
    80004a98:	0a91                	addi	s5,s5,4
    80004a9a:	02c9a783          	lw	a5,44(s3)
    80004a9e:	04fa5e63          	bge	s4,a5,80004afa <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004aa2:	0189a583          	lw	a1,24(s3)
    80004aa6:	014585bb          	addw	a1,a1,s4
    80004aaa:	2585                	addiw	a1,a1,1
    80004aac:	0289a503          	lw	a0,40(s3)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	c1a080e7          	jalr	-998(ra) # 800036ca <bread>
    80004ab8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004aba:	000aa583          	lw	a1,0(s5)
    80004abe:	0289a503          	lw	a0,40(s3)
    80004ac2:	fffff097          	auipc	ra,0xfffff
    80004ac6:	c08080e7          	jalr	-1016(ra) # 800036ca <bread>
    80004aca:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004acc:	40000613          	li	a2,1024
    80004ad0:	05890593          	addi	a1,s2,88
    80004ad4:	05850513          	addi	a0,a0,88
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	252080e7          	jalr	594(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ae0:	8526                	mv	a0,s1
    80004ae2:	fffff097          	auipc	ra,0xfffff
    80004ae6:	cda080e7          	jalr	-806(ra) # 800037bc <bwrite>
    if(recovering == 0)
    80004aea:	f80b1ce3          	bnez	s6,80004a82 <install_trans+0x36>
      bunpin(dbuf);
    80004aee:	8526                	mv	a0,s1
    80004af0:	fffff097          	auipc	ra,0xfffff
    80004af4:	de4080e7          	jalr	-540(ra) # 800038d4 <bunpin>
    80004af8:	b769                	j	80004a82 <install_trans+0x36>
}
    80004afa:	70e2                	ld	ra,56(sp)
    80004afc:	7442                	ld	s0,48(sp)
    80004afe:	74a2                	ld	s1,40(sp)
    80004b00:	7902                	ld	s2,32(sp)
    80004b02:	69e2                	ld	s3,24(sp)
    80004b04:	6a42                	ld	s4,16(sp)
    80004b06:	6aa2                	ld	s5,8(sp)
    80004b08:	6b02                	ld	s6,0(sp)
    80004b0a:	6121                	addi	sp,sp,64
    80004b0c:	8082                	ret
    80004b0e:	8082                	ret

0000000080004b10 <initlog>:
{
    80004b10:	7179                	addi	sp,sp,-48
    80004b12:	f406                	sd	ra,40(sp)
    80004b14:	f022                	sd	s0,32(sp)
    80004b16:	ec26                	sd	s1,24(sp)
    80004b18:	e84a                	sd	s2,16(sp)
    80004b1a:	e44e                	sd	s3,8(sp)
    80004b1c:	1800                	addi	s0,sp,48
    80004b1e:	892a                	mv	s2,a0
    80004b20:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004b22:	00025497          	auipc	s1,0x25
    80004b26:	d4e48493          	addi	s1,s1,-690 # 80029870 <log>
    80004b2a:	00004597          	auipc	a1,0x4
    80004b2e:	cae58593          	addi	a1,a1,-850 # 800087d8 <syscalls+0x248>
    80004b32:	8526                	mv	a0,s1
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	00e080e7          	jalr	14(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004b3c:	0149a583          	lw	a1,20(s3)
    80004b40:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004b42:	0109a783          	lw	a5,16(s3)
    80004b46:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004b48:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004b4c:	854a                	mv	a0,s2
    80004b4e:	fffff097          	auipc	ra,0xfffff
    80004b52:	b7c080e7          	jalr	-1156(ra) # 800036ca <bread>
  log.lh.n = lh->n;
    80004b56:	4d34                	lw	a3,88(a0)
    80004b58:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004b5a:	02d05663          	blez	a3,80004b86 <initlog+0x76>
    80004b5e:	05c50793          	addi	a5,a0,92
    80004b62:	00025717          	auipc	a4,0x25
    80004b66:	d3e70713          	addi	a4,a4,-706 # 800298a0 <log+0x30>
    80004b6a:	36fd                	addiw	a3,a3,-1
    80004b6c:	02069613          	slli	a2,a3,0x20
    80004b70:	01e65693          	srli	a3,a2,0x1e
    80004b74:	06050613          	addi	a2,a0,96
    80004b78:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004b7a:	4390                	lw	a2,0(a5)
    80004b7c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b7e:	0791                	addi	a5,a5,4
    80004b80:	0711                	addi	a4,a4,4
    80004b82:	fed79ce3          	bne	a5,a3,80004b7a <initlog+0x6a>
  brelse(buf);
    80004b86:	fffff097          	auipc	ra,0xfffff
    80004b8a:	c74080e7          	jalr	-908(ra) # 800037fa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004b8e:	4505                	li	a0,1
    80004b90:	00000097          	auipc	ra,0x0
    80004b94:	ebc080e7          	jalr	-324(ra) # 80004a4c <install_trans>
  log.lh.n = 0;
    80004b98:	00025797          	auipc	a5,0x25
    80004b9c:	d007a223          	sw	zero,-764(a5) # 8002989c <log+0x2c>
  write_head(); // clear the log
    80004ba0:	00000097          	auipc	ra,0x0
    80004ba4:	e30080e7          	jalr	-464(ra) # 800049d0 <write_head>
}
    80004ba8:	70a2                	ld	ra,40(sp)
    80004baa:	7402                	ld	s0,32(sp)
    80004bac:	64e2                	ld	s1,24(sp)
    80004bae:	6942                	ld	s2,16(sp)
    80004bb0:	69a2                	ld	s3,8(sp)
    80004bb2:	6145                	addi	sp,sp,48
    80004bb4:	8082                	ret

0000000080004bb6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004bb6:	1101                	addi	sp,sp,-32
    80004bb8:	ec06                	sd	ra,24(sp)
    80004bba:	e822                	sd	s0,16(sp)
    80004bbc:	e426                	sd	s1,8(sp)
    80004bbe:	e04a                	sd	s2,0(sp)
    80004bc0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004bc2:	00025517          	auipc	a0,0x25
    80004bc6:	cae50513          	addi	a0,a0,-850 # 80029870 <log>
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	008080e7          	jalr	8(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004bd2:	00025497          	auipc	s1,0x25
    80004bd6:	c9e48493          	addi	s1,s1,-866 # 80029870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bda:	4979                	li	s2,30
    80004bdc:	a039                	j	80004bea <begin_op+0x34>
      sleep(&log, &log.lock);
    80004bde:	85a6                	mv	a1,s1
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffe097          	auipc	ra,0xffffe
    80004be6:	d54080e7          	jalr	-684(ra) # 80002936 <sleep>
    if(log.committing){
    80004bea:	50dc                	lw	a5,36(s1)
    80004bec:	fbed                	bnez	a5,80004bde <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004bee:	509c                	lw	a5,32(s1)
    80004bf0:	0017871b          	addiw	a4,a5,1
    80004bf4:	0007069b          	sext.w	a3,a4
    80004bf8:	0027179b          	slliw	a5,a4,0x2
    80004bfc:	9fb9                	addw	a5,a5,a4
    80004bfe:	0017979b          	slliw	a5,a5,0x1
    80004c02:	54d8                	lw	a4,44(s1)
    80004c04:	9fb9                	addw	a5,a5,a4
    80004c06:	00f95963          	bge	s2,a5,80004c18 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004c0a:	85a6                	mv	a1,s1
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	ffffe097          	auipc	ra,0xffffe
    80004c12:	d28080e7          	jalr	-728(ra) # 80002936 <sleep>
    80004c16:	bfd1                	j	80004bea <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004c18:	00025517          	auipc	a0,0x25
    80004c1c:	c5850513          	addi	a0,a0,-936 # 80029870 <log>
    80004c20:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	064080e7          	jalr	100(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004c2a:	60e2                	ld	ra,24(sp)
    80004c2c:	6442                	ld	s0,16(sp)
    80004c2e:	64a2                	ld	s1,8(sp)
    80004c30:	6902                	ld	s2,0(sp)
    80004c32:	6105                	addi	sp,sp,32
    80004c34:	8082                	ret

0000000080004c36 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004c36:	7139                	addi	sp,sp,-64
    80004c38:	fc06                	sd	ra,56(sp)
    80004c3a:	f822                	sd	s0,48(sp)
    80004c3c:	f426                	sd	s1,40(sp)
    80004c3e:	f04a                	sd	s2,32(sp)
    80004c40:	ec4e                	sd	s3,24(sp)
    80004c42:	e852                	sd	s4,16(sp)
    80004c44:	e456                	sd	s5,8(sp)
    80004c46:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004c48:	00025497          	auipc	s1,0x25
    80004c4c:	c2848493          	addi	s1,s1,-984 # 80029870 <log>
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	f80080e7          	jalr	-128(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004c5a:	509c                	lw	a5,32(s1)
    80004c5c:	37fd                	addiw	a5,a5,-1
    80004c5e:	0007891b          	sext.w	s2,a5
    80004c62:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004c64:	50dc                	lw	a5,36(s1)
    80004c66:	e7b9                	bnez	a5,80004cb4 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004c68:	04091e63          	bnez	s2,80004cc4 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004c6c:	00025497          	auipc	s1,0x25
    80004c70:	c0448493          	addi	s1,s1,-1020 # 80029870 <log>
    80004c74:	4785                	li	a5,1
    80004c76:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004c78:	8526                	mv	a0,s1
    80004c7a:	ffffc097          	auipc	ra,0xffffc
    80004c7e:	00c080e7          	jalr	12(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004c82:	54dc                	lw	a5,44(s1)
    80004c84:	06f04763          	bgtz	a5,80004cf2 <end_op+0xbc>
    acquire(&log.lock);
    80004c88:	00025497          	auipc	s1,0x25
    80004c8c:	be848493          	addi	s1,s1,-1048 # 80029870 <log>
    80004c90:	8526                	mv	a0,s1
    80004c92:	ffffc097          	auipc	ra,0xffffc
    80004c96:	f40080e7          	jalr	-192(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004c9a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffe097          	auipc	ra,0xffffe
    80004ca4:	e22080e7          	jalr	-478(ra) # 80002ac2 <wakeup>
    release(&log.lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	fdc080e7          	jalr	-36(ra) # 80000c86 <release>
}
    80004cb2:	a03d                	j	80004ce0 <end_op+0xaa>
    panic("log.committing");
    80004cb4:	00004517          	auipc	a0,0x4
    80004cb8:	b2c50513          	addi	a0,a0,-1236 # 800087e0 <syscalls+0x250>
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	86e080e7          	jalr	-1938(ra) # 8000052a <panic>
    wakeup(&log);
    80004cc4:	00025497          	auipc	s1,0x25
    80004cc8:	bac48493          	addi	s1,s1,-1108 # 80029870 <log>
    80004ccc:	8526                	mv	a0,s1
    80004cce:	ffffe097          	auipc	ra,0xffffe
    80004cd2:	df4080e7          	jalr	-524(ra) # 80002ac2 <wakeup>
  release(&log.lock);
    80004cd6:	8526                	mv	a0,s1
    80004cd8:	ffffc097          	auipc	ra,0xffffc
    80004cdc:	fae080e7          	jalr	-82(ra) # 80000c86 <release>
}
    80004ce0:	70e2                	ld	ra,56(sp)
    80004ce2:	7442                	ld	s0,48(sp)
    80004ce4:	74a2                	ld	s1,40(sp)
    80004ce6:	7902                	ld	s2,32(sp)
    80004ce8:	69e2                	ld	s3,24(sp)
    80004cea:	6a42                	ld	s4,16(sp)
    80004cec:	6aa2                	ld	s5,8(sp)
    80004cee:	6121                	addi	sp,sp,64
    80004cf0:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004cf2:	00025a97          	auipc	s5,0x25
    80004cf6:	baea8a93          	addi	s5,s5,-1106 # 800298a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004cfa:	00025a17          	auipc	s4,0x25
    80004cfe:	b76a0a13          	addi	s4,s4,-1162 # 80029870 <log>
    80004d02:	018a2583          	lw	a1,24(s4)
    80004d06:	012585bb          	addw	a1,a1,s2
    80004d0a:	2585                	addiw	a1,a1,1
    80004d0c:	028a2503          	lw	a0,40(s4)
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	9ba080e7          	jalr	-1606(ra) # 800036ca <bread>
    80004d18:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004d1a:	000aa583          	lw	a1,0(s5)
    80004d1e:	028a2503          	lw	a0,40(s4)
    80004d22:	fffff097          	auipc	ra,0xfffff
    80004d26:	9a8080e7          	jalr	-1624(ra) # 800036ca <bread>
    80004d2a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004d2c:	40000613          	li	a2,1024
    80004d30:	05850593          	addi	a1,a0,88
    80004d34:	05848513          	addi	a0,s1,88
    80004d38:	ffffc097          	auipc	ra,0xffffc
    80004d3c:	ff2080e7          	jalr	-14(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	a7a080e7          	jalr	-1414(ra) # 800037bc <bwrite>
    brelse(from);
    80004d4a:	854e                	mv	a0,s3
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	aae080e7          	jalr	-1362(ra) # 800037fa <brelse>
    brelse(to);
    80004d54:	8526                	mv	a0,s1
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	aa4080e7          	jalr	-1372(ra) # 800037fa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004d5e:	2905                	addiw	s2,s2,1
    80004d60:	0a91                	addi	s5,s5,4
    80004d62:	02ca2783          	lw	a5,44(s4)
    80004d66:	f8f94ee3          	blt	s2,a5,80004d02 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004d6a:	00000097          	auipc	ra,0x0
    80004d6e:	c66080e7          	jalr	-922(ra) # 800049d0 <write_head>
    install_trans(0); // Now install writes to home locations
    80004d72:	4501                	li	a0,0
    80004d74:	00000097          	auipc	ra,0x0
    80004d78:	cd8080e7          	jalr	-808(ra) # 80004a4c <install_trans>
    log.lh.n = 0;
    80004d7c:	00025797          	auipc	a5,0x25
    80004d80:	b207a023          	sw	zero,-1248(a5) # 8002989c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	c4c080e7          	jalr	-948(ra) # 800049d0 <write_head>
    80004d8c:	bdf5                	j	80004c88 <end_op+0x52>

0000000080004d8e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004d8e:	1101                	addi	sp,sp,-32
    80004d90:	ec06                	sd	ra,24(sp)
    80004d92:	e822                	sd	s0,16(sp)
    80004d94:	e426                	sd	s1,8(sp)
    80004d96:	e04a                	sd	s2,0(sp)
    80004d98:	1000                	addi	s0,sp,32
    80004d9a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004d9c:	00025917          	auipc	s2,0x25
    80004da0:	ad490913          	addi	s2,s2,-1324 # 80029870 <log>
    80004da4:	854a                	mv	a0,s2
    80004da6:	ffffc097          	auipc	ra,0xffffc
    80004daa:	e2c080e7          	jalr	-468(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004dae:	02c92603          	lw	a2,44(s2)
    80004db2:	47f5                	li	a5,29
    80004db4:	06c7c563          	blt	a5,a2,80004e1e <log_write+0x90>
    80004db8:	00025797          	auipc	a5,0x25
    80004dbc:	ad47a783          	lw	a5,-1324(a5) # 8002988c <log+0x1c>
    80004dc0:	37fd                	addiw	a5,a5,-1
    80004dc2:	04f65e63          	bge	a2,a5,80004e1e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004dc6:	00025797          	auipc	a5,0x25
    80004dca:	aca7a783          	lw	a5,-1334(a5) # 80029890 <log+0x20>
    80004dce:	06f05063          	blez	a5,80004e2e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004dd2:	4781                	li	a5,0
    80004dd4:	06c05563          	blez	a2,80004e3e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004dd8:	44cc                	lw	a1,12(s1)
    80004dda:	00025717          	auipc	a4,0x25
    80004dde:	ac670713          	addi	a4,a4,-1338 # 800298a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004de2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004de4:	4314                	lw	a3,0(a4)
    80004de6:	04b68c63          	beq	a3,a1,80004e3e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004dea:	2785                	addiw	a5,a5,1
    80004dec:	0711                	addi	a4,a4,4
    80004dee:	fef61be3          	bne	a2,a5,80004de4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004df2:	0621                	addi	a2,a2,8
    80004df4:	060a                	slli	a2,a2,0x2
    80004df6:	00025797          	auipc	a5,0x25
    80004dfa:	a7a78793          	addi	a5,a5,-1414 # 80029870 <log>
    80004dfe:	963e                	add	a2,a2,a5
    80004e00:	44dc                	lw	a5,12(s1)
    80004e02:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004e04:	8526                	mv	a0,s1
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	a92080e7          	jalr	-1390(ra) # 80003898 <bpin>
    log.lh.n++;
    80004e0e:	00025717          	auipc	a4,0x25
    80004e12:	a6270713          	addi	a4,a4,-1438 # 80029870 <log>
    80004e16:	575c                	lw	a5,44(a4)
    80004e18:	2785                	addiw	a5,a5,1
    80004e1a:	d75c                	sw	a5,44(a4)
    80004e1c:	a835                	j	80004e58 <log_write+0xca>
    panic("too big a transaction");
    80004e1e:	00004517          	auipc	a0,0x4
    80004e22:	9d250513          	addi	a0,a0,-1582 # 800087f0 <syscalls+0x260>
    80004e26:	ffffb097          	auipc	ra,0xffffb
    80004e2a:	704080e7          	jalr	1796(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004e2e:	00004517          	auipc	a0,0x4
    80004e32:	9da50513          	addi	a0,a0,-1574 # 80008808 <syscalls+0x278>
    80004e36:	ffffb097          	auipc	ra,0xffffb
    80004e3a:	6f4080e7          	jalr	1780(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004e3e:	00878713          	addi	a4,a5,8
    80004e42:	00271693          	slli	a3,a4,0x2
    80004e46:	00025717          	auipc	a4,0x25
    80004e4a:	a2a70713          	addi	a4,a4,-1494 # 80029870 <log>
    80004e4e:	9736                	add	a4,a4,a3
    80004e50:	44d4                	lw	a3,12(s1)
    80004e52:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004e54:	faf608e3          	beq	a2,a5,80004e04 <log_write+0x76>
  }
  release(&log.lock);
    80004e58:	00025517          	auipc	a0,0x25
    80004e5c:	a1850513          	addi	a0,a0,-1512 # 80029870 <log>
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	e26080e7          	jalr	-474(ra) # 80000c86 <release>
}
    80004e68:	60e2                	ld	ra,24(sp)
    80004e6a:	6442                	ld	s0,16(sp)
    80004e6c:	64a2                	ld	s1,8(sp)
    80004e6e:	6902                	ld	s2,0(sp)
    80004e70:	6105                	addi	sp,sp,32
    80004e72:	8082                	ret

0000000080004e74 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004e74:	1101                	addi	sp,sp,-32
    80004e76:	ec06                	sd	ra,24(sp)
    80004e78:	e822                	sd	s0,16(sp)
    80004e7a:	e426                	sd	s1,8(sp)
    80004e7c:	e04a                	sd	s2,0(sp)
    80004e7e:	1000                	addi	s0,sp,32
    80004e80:	84aa                	mv	s1,a0
    80004e82:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004e84:	00004597          	auipc	a1,0x4
    80004e88:	9a458593          	addi	a1,a1,-1628 # 80008828 <syscalls+0x298>
    80004e8c:	0521                	addi	a0,a0,8
    80004e8e:	ffffc097          	auipc	ra,0xffffc
    80004e92:	cb4080e7          	jalr	-844(ra) # 80000b42 <initlock>
  lk->name = name;
    80004e96:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004e9a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e9e:	0204a423          	sw	zero,40(s1)
}
    80004ea2:	60e2                	ld	ra,24(sp)
    80004ea4:	6442                	ld	s0,16(sp)
    80004ea6:	64a2                	ld	s1,8(sp)
    80004ea8:	6902                	ld	s2,0(sp)
    80004eaa:	6105                	addi	sp,sp,32
    80004eac:	8082                	ret

0000000080004eae <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004eae:	1101                	addi	sp,sp,-32
    80004eb0:	ec06                	sd	ra,24(sp)
    80004eb2:	e822                	sd	s0,16(sp)
    80004eb4:	e426                	sd	s1,8(sp)
    80004eb6:	e04a                	sd	s2,0(sp)
    80004eb8:	1000                	addi	s0,sp,32
    80004eba:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ebc:	00850913          	addi	s2,a0,8
    80004ec0:	854a                	mv	a0,s2
    80004ec2:	ffffc097          	auipc	ra,0xffffc
    80004ec6:	d10080e7          	jalr	-752(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004eca:	409c                	lw	a5,0(s1)
    80004ecc:	cb89                	beqz	a5,80004ede <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004ece:	85ca                	mv	a1,s2
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	ffffe097          	auipc	ra,0xffffe
    80004ed6:	a64080e7          	jalr	-1436(ra) # 80002936 <sleep>
  while (lk->locked) {
    80004eda:	409c                	lw	a5,0(s1)
    80004edc:	fbed                	bnez	a5,80004ece <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ede:	4785                	li	a5,1
    80004ee0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ee2:	ffffd097          	auipc	ra,0xffffd
    80004ee6:	196080e7          	jalr	406(ra) # 80002078 <myproc>
    80004eea:	591c                	lw	a5,48(a0)
    80004eec:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004eee:	854a                	mv	a0,s2
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	d96080e7          	jalr	-618(ra) # 80000c86 <release>
}
    80004ef8:	60e2                	ld	ra,24(sp)
    80004efa:	6442                	ld	s0,16(sp)
    80004efc:	64a2                	ld	s1,8(sp)
    80004efe:	6902                	ld	s2,0(sp)
    80004f00:	6105                	addi	sp,sp,32
    80004f02:	8082                	ret

0000000080004f04 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004f04:	1101                	addi	sp,sp,-32
    80004f06:	ec06                	sd	ra,24(sp)
    80004f08:	e822                	sd	s0,16(sp)
    80004f0a:	e426                	sd	s1,8(sp)
    80004f0c:	e04a                	sd	s2,0(sp)
    80004f0e:	1000                	addi	s0,sp,32
    80004f10:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004f12:	00850913          	addi	s2,a0,8
    80004f16:	854a                	mv	a0,s2
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	cba080e7          	jalr	-838(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004f20:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004f24:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004f28:	8526                	mv	a0,s1
    80004f2a:	ffffe097          	auipc	ra,0xffffe
    80004f2e:	b98080e7          	jalr	-1128(ra) # 80002ac2 <wakeup>
  release(&lk->lk);
    80004f32:	854a                	mv	a0,s2
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	d52080e7          	jalr	-686(ra) # 80000c86 <release>
}
    80004f3c:	60e2                	ld	ra,24(sp)
    80004f3e:	6442                	ld	s0,16(sp)
    80004f40:	64a2                	ld	s1,8(sp)
    80004f42:	6902                	ld	s2,0(sp)
    80004f44:	6105                	addi	sp,sp,32
    80004f46:	8082                	ret

0000000080004f48 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004f48:	7179                	addi	sp,sp,-48
    80004f4a:	f406                	sd	ra,40(sp)
    80004f4c:	f022                	sd	s0,32(sp)
    80004f4e:	ec26                	sd	s1,24(sp)
    80004f50:	e84a                	sd	s2,16(sp)
    80004f52:	e44e                	sd	s3,8(sp)
    80004f54:	1800                	addi	s0,sp,48
    80004f56:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004f58:	00850913          	addi	s2,a0,8
    80004f5c:	854a                	mv	a0,s2
    80004f5e:	ffffc097          	auipc	ra,0xffffc
    80004f62:	c74080e7          	jalr	-908(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f66:	409c                	lw	a5,0(s1)
    80004f68:	ef99                	bnez	a5,80004f86 <holdingsleep+0x3e>
    80004f6a:	4481                	li	s1,0
  release(&lk->lk);
    80004f6c:	854a                	mv	a0,s2
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	d18080e7          	jalr	-744(ra) # 80000c86 <release>
  return r;
}
    80004f76:	8526                	mv	a0,s1
    80004f78:	70a2                	ld	ra,40(sp)
    80004f7a:	7402                	ld	s0,32(sp)
    80004f7c:	64e2                	ld	s1,24(sp)
    80004f7e:	6942                	ld	s2,16(sp)
    80004f80:	69a2                	ld	s3,8(sp)
    80004f82:	6145                	addi	sp,sp,48
    80004f84:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004f86:	0284a983          	lw	s3,40(s1)
    80004f8a:	ffffd097          	auipc	ra,0xffffd
    80004f8e:	0ee080e7          	jalr	238(ra) # 80002078 <myproc>
    80004f92:	5904                	lw	s1,48(a0)
    80004f94:	413484b3          	sub	s1,s1,s3
    80004f98:	0014b493          	seqz	s1,s1
    80004f9c:	bfc1                	j	80004f6c <holdingsleep+0x24>

0000000080004f9e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004f9e:	1141                	addi	sp,sp,-16
    80004fa0:	e406                	sd	ra,8(sp)
    80004fa2:	e022                	sd	s0,0(sp)
    80004fa4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004fa6:	00004597          	auipc	a1,0x4
    80004faa:	89258593          	addi	a1,a1,-1902 # 80008838 <syscalls+0x2a8>
    80004fae:	00025517          	auipc	a0,0x25
    80004fb2:	a0a50513          	addi	a0,a0,-1526 # 800299b8 <ftable>
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	b8c080e7          	jalr	-1140(ra) # 80000b42 <initlock>
}
    80004fbe:	60a2                	ld	ra,8(sp)
    80004fc0:	6402                	ld	s0,0(sp)
    80004fc2:	0141                	addi	sp,sp,16
    80004fc4:	8082                	ret

0000000080004fc6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004fc6:	1101                	addi	sp,sp,-32
    80004fc8:	ec06                	sd	ra,24(sp)
    80004fca:	e822                	sd	s0,16(sp)
    80004fcc:	e426                	sd	s1,8(sp)
    80004fce:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004fd0:	00025517          	auipc	a0,0x25
    80004fd4:	9e850513          	addi	a0,a0,-1560 # 800299b8 <ftable>
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	bfa080e7          	jalr	-1030(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004fe0:	00025497          	auipc	s1,0x25
    80004fe4:	9f048493          	addi	s1,s1,-1552 # 800299d0 <ftable+0x18>
    80004fe8:	00026717          	auipc	a4,0x26
    80004fec:	98870713          	addi	a4,a4,-1656 # 8002a970 <ftable+0xfb8>
    if(f->ref == 0){
    80004ff0:	40dc                	lw	a5,4(s1)
    80004ff2:	cf99                	beqz	a5,80005010 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ff4:	02848493          	addi	s1,s1,40
    80004ff8:	fee49ce3          	bne	s1,a4,80004ff0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ffc:	00025517          	auipc	a0,0x25
    80005000:	9bc50513          	addi	a0,a0,-1604 # 800299b8 <ftable>
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	c82080e7          	jalr	-894(ra) # 80000c86 <release>
  return 0;
    8000500c:	4481                	li	s1,0
    8000500e:	a819                	j	80005024 <filealloc+0x5e>
      f->ref = 1;
    80005010:	4785                	li	a5,1
    80005012:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005014:	00025517          	auipc	a0,0x25
    80005018:	9a450513          	addi	a0,a0,-1628 # 800299b8 <ftable>
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	c6a080e7          	jalr	-918(ra) # 80000c86 <release>
}
    80005024:	8526                	mv	a0,s1
    80005026:	60e2                	ld	ra,24(sp)
    80005028:	6442                	ld	s0,16(sp)
    8000502a:	64a2                	ld	s1,8(sp)
    8000502c:	6105                	addi	sp,sp,32
    8000502e:	8082                	ret

0000000080005030 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005030:	1101                	addi	sp,sp,-32
    80005032:	ec06                	sd	ra,24(sp)
    80005034:	e822                	sd	s0,16(sp)
    80005036:	e426                	sd	s1,8(sp)
    80005038:	1000                	addi	s0,sp,32
    8000503a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000503c:	00025517          	auipc	a0,0x25
    80005040:	97c50513          	addi	a0,a0,-1668 # 800299b8 <ftable>
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	b8e080e7          	jalr	-1138(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000504c:	40dc                	lw	a5,4(s1)
    8000504e:	02f05263          	blez	a5,80005072 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005052:	2785                	addiw	a5,a5,1
    80005054:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005056:	00025517          	auipc	a0,0x25
    8000505a:	96250513          	addi	a0,a0,-1694 # 800299b8 <ftable>
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	c28080e7          	jalr	-984(ra) # 80000c86 <release>
  return f;
}
    80005066:	8526                	mv	a0,s1
    80005068:	60e2                	ld	ra,24(sp)
    8000506a:	6442                	ld	s0,16(sp)
    8000506c:	64a2                	ld	s1,8(sp)
    8000506e:	6105                	addi	sp,sp,32
    80005070:	8082                	ret
    panic("filedup");
    80005072:	00003517          	auipc	a0,0x3
    80005076:	7ce50513          	addi	a0,a0,1998 # 80008840 <syscalls+0x2b0>
    8000507a:	ffffb097          	auipc	ra,0xffffb
    8000507e:	4b0080e7          	jalr	1200(ra) # 8000052a <panic>

0000000080005082 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005082:	7139                	addi	sp,sp,-64
    80005084:	fc06                	sd	ra,56(sp)
    80005086:	f822                	sd	s0,48(sp)
    80005088:	f426                	sd	s1,40(sp)
    8000508a:	f04a                	sd	s2,32(sp)
    8000508c:	ec4e                	sd	s3,24(sp)
    8000508e:	e852                	sd	s4,16(sp)
    80005090:	e456                	sd	s5,8(sp)
    80005092:	0080                	addi	s0,sp,64
    80005094:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005096:	00025517          	auipc	a0,0x25
    8000509a:	92250513          	addi	a0,a0,-1758 # 800299b8 <ftable>
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	b34080e7          	jalr	-1228(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800050a6:	40dc                	lw	a5,4(s1)
    800050a8:	06f05163          	blez	a5,8000510a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800050ac:	37fd                	addiw	a5,a5,-1
    800050ae:	0007871b          	sext.w	a4,a5
    800050b2:	c0dc                	sw	a5,4(s1)
    800050b4:	06e04363          	bgtz	a4,8000511a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800050b8:	0004a903          	lw	s2,0(s1)
    800050bc:	0094ca83          	lbu	s5,9(s1)
    800050c0:	0104ba03          	ld	s4,16(s1)
    800050c4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800050c8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800050cc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800050d0:	00025517          	auipc	a0,0x25
    800050d4:	8e850513          	addi	a0,a0,-1816 # 800299b8 <ftable>
    800050d8:	ffffc097          	auipc	ra,0xffffc
    800050dc:	bae080e7          	jalr	-1106(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800050e0:	4785                	li	a5,1
    800050e2:	04f90d63          	beq	s2,a5,8000513c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800050e6:	3979                	addiw	s2,s2,-2
    800050e8:	4785                	li	a5,1
    800050ea:	0527e063          	bltu	a5,s2,8000512a <fileclose+0xa8>
    begin_op();
    800050ee:	00000097          	auipc	ra,0x0
    800050f2:	ac8080e7          	jalr	-1336(ra) # 80004bb6 <begin_op>
    iput(ff.ip);
    800050f6:	854e                	mv	a0,s3
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	f90080e7          	jalr	-112(ra) # 80004088 <iput>
    end_op();
    80005100:	00000097          	auipc	ra,0x0
    80005104:	b36080e7          	jalr	-1226(ra) # 80004c36 <end_op>
    80005108:	a00d                	j	8000512a <fileclose+0xa8>
    panic("fileclose");
    8000510a:	00003517          	auipc	a0,0x3
    8000510e:	73e50513          	addi	a0,a0,1854 # 80008848 <syscalls+0x2b8>
    80005112:	ffffb097          	auipc	ra,0xffffb
    80005116:	418080e7          	jalr	1048(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000511a:	00025517          	auipc	a0,0x25
    8000511e:	89e50513          	addi	a0,a0,-1890 # 800299b8 <ftable>
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	b64080e7          	jalr	-1180(ra) # 80000c86 <release>
  }
}
    8000512a:	70e2                	ld	ra,56(sp)
    8000512c:	7442                	ld	s0,48(sp)
    8000512e:	74a2                	ld	s1,40(sp)
    80005130:	7902                	ld	s2,32(sp)
    80005132:	69e2                	ld	s3,24(sp)
    80005134:	6a42                	ld	s4,16(sp)
    80005136:	6aa2                	ld	s5,8(sp)
    80005138:	6121                	addi	sp,sp,64
    8000513a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000513c:	85d6                	mv	a1,s5
    8000513e:	8552                	mv	a0,s4
    80005140:	00000097          	auipc	ra,0x0
    80005144:	542080e7          	jalr	1346(ra) # 80005682 <pipeclose>
    80005148:	b7cd                	j	8000512a <fileclose+0xa8>

000000008000514a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000514a:	715d                	addi	sp,sp,-80
    8000514c:	e486                	sd	ra,72(sp)
    8000514e:	e0a2                	sd	s0,64(sp)
    80005150:	fc26                	sd	s1,56(sp)
    80005152:	f84a                	sd	s2,48(sp)
    80005154:	f44e                	sd	s3,40(sp)
    80005156:	0880                	addi	s0,sp,80
    80005158:	84aa                	mv	s1,a0
    8000515a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000515c:	ffffd097          	auipc	ra,0xffffd
    80005160:	f1c080e7          	jalr	-228(ra) # 80002078 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005164:	409c                	lw	a5,0(s1)
    80005166:	37f9                	addiw	a5,a5,-2
    80005168:	4705                	li	a4,1
    8000516a:	04f76763          	bltu	a4,a5,800051b8 <filestat+0x6e>
    8000516e:	892a                	mv	s2,a0
    ilock(f->ip);
    80005170:	6c88                	ld	a0,24(s1)
    80005172:	fffff097          	auipc	ra,0xfffff
    80005176:	d5c080e7          	jalr	-676(ra) # 80003ece <ilock>
    stati(f->ip, &st);
    8000517a:	fb840593          	addi	a1,s0,-72
    8000517e:	6c88                	ld	a0,24(s1)
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	fd8080e7          	jalr	-40(ra) # 80004158 <stati>
    iunlock(f->ip);
    80005188:	6c88                	ld	a0,24(s1)
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	e06080e7          	jalr	-506(ra) # 80003f90 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005192:	46e1                	li	a3,24
    80005194:	fb840613          	addi	a2,s0,-72
    80005198:	85ce                	mv	a1,s3
    8000519a:	05093503          	ld	a0,80(s2)
    8000519e:	ffffc097          	auipc	ra,0xffffc
    800051a2:	4b0080e7          	jalr	1200(ra) # 8000164e <copyout>
    800051a6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800051aa:	60a6                	ld	ra,72(sp)
    800051ac:	6406                	ld	s0,64(sp)
    800051ae:	74e2                	ld	s1,56(sp)
    800051b0:	7942                	ld	s2,48(sp)
    800051b2:	79a2                	ld	s3,40(sp)
    800051b4:	6161                	addi	sp,sp,80
    800051b6:	8082                	ret
  return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	bfc5                	j	800051aa <filestat+0x60>

00000000800051bc <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800051bc:	7179                	addi	sp,sp,-48
    800051be:	f406                	sd	ra,40(sp)
    800051c0:	f022                	sd	s0,32(sp)
    800051c2:	ec26                	sd	s1,24(sp)
    800051c4:	e84a                	sd	s2,16(sp)
    800051c6:	e44e                	sd	s3,8(sp)
    800051c8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800051ca:	00854783          	lbu	a5,8(a0)
    800051ce:	c3d5                	beqz	a5,80005272 <fileread+0xb6>
    800051d0:	84aa                	mv	s1,a0
    800051d2:	89ae                	mv	s3,a1
    800051d4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800051d6:	411c                	lw	a5,0(a0)
    800051d8:	4705                	li	a4,1
    800051da:	04e78963          	beq	a5,a4,8000522c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051de:	470d                	li	a4,3
    800051e0:	04e78d63          	beq	a5,a4,8000523a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800051e4:	4709                	li	a4,2
    800051e6:	06e79e63          	bne	a5,a4,80005262 <fileread+0xa6>
    ilock(f->ip);
    800051ea:	6d08                	ld	a0,24(a0)
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	ce2080e7          	jalr	-798(ra) # 80003ece <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800051f4:	874a                	mv	a4,s2
    800051f6:	5094                	lw	a3,32(s1)
    800051f8:	864e                	mv	a2,s3
    800051fa:	4585                	li	a1,1
    800051fc:	6c88                	ld	a0,24(s1)
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	f84080e7          	jalr	-124(ra) # 80004182 <readi>
    80005206:	892a                	mv	s2,a0
    80005208:	00a05563          	blez	a0,80005212 <fileread+0x56>
      f->off += r;
    8000520c:	509c                	lw	a5,32(s1)
    8000520e:	9fa9                	addw	a5,a5,a0
    80005210:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005212:	6c88                	ld	a0,24(s1)
    80005214:	fffff097          	auipc	ra,0xfffff
    80005218:	d7c080e7          	jalr	-644(ra) # 80003f90 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000521c:	854a                	mv	a0,s2
    8000521e:	70a2                	ld	ra,40(sp)
    80005220:	7402                	ld	s0,32(sp)
    80005222:	64e2                	ld	s1,24(sp)
    80005224:	6942                	ld	s2,16(sp)
    80005226:	69a2                	ld	s3,8(sp)
    80005228:	6145                	addi	sp,sp,48
    8000522a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000522c:	6908                	ld	a0,16(a0)
    8000522e:	00000097          	auipc	ra,0x0
    80005232:	5b6080e7          	jalr	1462(ra) # 800057e4 <piperead>
    80005236:	892a                	mv	s2,a0
    80005238:	b7d5                	j	8000521c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000523a:	02451783          	lh	a5,36(a0)
    8000523e:	03079693          	slli	a3,a5,0x30
    80005242:	92c1                	srli	a3,a3,0x30
    80005244:	4725                	li	a4,9
    80005246:	02d76863          	bltu	a4,a3,80005276 <fileread+0xba>
    8000524a:	0792                	slli	a5,a5,0x4
    8000524c:	00024717          	auipc	a4,0x24
    80005250:	6cc70713          	addi	a4,a4,1740 # 80029918 <devsw>
    80005254:	97ba                	add	a5,a5,a4
    80005256:	639c                	ld	a5,0(a5)
    80005258:	c38d                	beqz	a5,8000527a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000525a:	4505                	li	a0,1
    8000525c:	9782                	jalr	a5
    8000525e:	892a                	mv	s2,a0
    80005260:	bf75                	j	8000521c <fileread+0x60>
    panic("fileread");
    80005262:	00003517          	auipc	a0,0x3
    80005266:	5f650513          	addi	a0,a0,1526 # 80008858 <syscalls+0x2c8>
    8000526a:	ffffb097          	auipc	ra,0xffffb
    8000526e:	2c0080e7          	jalr	704(ra) # 8000052a <panic>
    return -1;
    80005272:	597d                	li	s2,-1
    80005274:	b765                	j	8000521c <fileread+0x60>
      return -1;
    80005276:	597d                	li	s2,-1
    80005278:	b755                	j	8000521c <fileread+0x60>
    8000527a:	597d                	li	s2,-1
    8000527c:	b745                	j	8000521c <fileread+0x60>

000000008000527e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000527e:	715d                	addi	sp,sp,-80
    80005280:	e486                	sd	ra,72(sp)
    80005282:	e0a2                	sd	s0,64(sp)
    80005284:	fc26                	sd	s1,56(sp)
    80005286:	f84a                	sd	s2,48(sp)
    80005288:	f44e                	sd	s3,40(sp)
    8000528a:	f052                	sd	s4,32(sp)
    8000528c:	ec56                	sd	s5,24(sp)
    8000528e:	e85a                	sd	s6,16(sp)
    80005290:	e45e                	sd	s7,8(sp)
    80005292:	e062                	sd	s8,0(sp)
    80005294:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005296:	00954783          	lbu	a5,9(a0)
    8000529a:	10078663          	beqz	a5,800053a6 <filewrite+0x128>
    8000529e:	892a                	mv	s2,a0
    800052a0:	8aae                	mv	s5,a1
    800052a2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800052a4:	411c                	lw	a5,0(a0)
    800052a6:	4705                	li	a4,1
    800052a8:	02e78263          	beq	a5,a4,800052cc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052ac:	470d                	li	a4,3
    800052ae:	02e78663          	beq	a5,a4,800052da <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800052b2:	4709                	li	a4,2
    800052b4:	0ee79163          	bne	a5,a4,80005396 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800052b8:	0ac05d63          	blez	a2,80005372 <filewrite+0xf4>
    int i = 0;
    800052bc:	4981                	li	s3,0
    800052be:	6b05                	lui	s6,0x1
    800052c0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800052c4:	6b85                	lui	s7,0x1
    800052c6:	c00b8b9b          	addiw	s7,s7,-1024
    800052ca:	a861                	j	80005362 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800052cc:	6908                	ld	a0,16(a0)
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	424080e7          	jalr	1060(ra) # 800056f2 <pipewrite>
    800052d6:	8a2a                	mv	s4,a0
    800052d8:	a045                	j	80005378 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800052da:	02451783          	lh	a5,36(a0)
    800052de:	03079693          	slli	a3,a5,0x30
    800052e2:	92c1                	srli	a3,a3,0x30
    800052e4:	4725                	li	a4,9
    800052e6:	0cd76263          	bltu	a4,a3,800053aa <filewrite+0x12c>
    800052ea:	0792                	slli	a5,a5,0x4
    800052ec:	00024717          	auipc	a4,0x24
    800052f0:	62c70713          	addi	a4,a4,1580 # 80029918 <devsw>
    800052f4:	97ba                	add	a5,a5,a4
    800052f6:	679c                	ld	a5,8(a5)
    800052f8:	cbdd                	beqz	a5,800053ae <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800052fa:	4505                	li	a0,1
    800052fc:	9782                	jalr	a5
    800052fe:	8a2a                	mv	s4,a0
    80005300:	a8a5                	j	80005378 <filewrite+0xfa>
    80005302:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005306:	00000097          	auipc	ra,0x0
    8000530a:	8b0080e7          	jalr	-1872(ra) # 80004bb6 <begin_op>
      ilock(f->ip);
    8000530e:	01893503          	ld	a0,24(s2)
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	bbc080e7          	jalr	-1092(ra) # 80003ece <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000531a:	8762                	mv	a4,s8
    8000531c:	02092683          	lw	a3,32(s2)
    80005320:	01598633          	add	a2,s3,s5
    80005324:	4585                	li	a1,1
    80005326:	01893503          	ld	a0,24(s2)
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	f50080e7          	jalr	-176(ra) # 8000427a <writei>
    80005332:	84aa                	mv	s1,a0
    80005334:	00a05763          	blez	a0,80005342 <filewrite+0xc4>
        f->off += r;
    80005338:	02092783          	lw	a5,32(s2)
    8000533c:	9fa9                	addw	a5,a5,a0
    8000533e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005342:	01893503          	ld	a0,24(s2)
    80005346:	fffff097          	auipc	ra,0xfffff
    8000534a:	c4a080e7          	jalr	-950(ra) # 80003f90 <iunlock>
      end_op();
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	8e8080e7          	jalr	-1816(ra) # 80004c36 <end_op>

      if(r != n1){
    80005356:	009c1f63          	bne	s8,s1,80005374 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000535a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000535e:	0149db63          	bge	s3,s4,80005374 <filewrite+0xf6>
      int n1 = n - i;
    80005362:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005366:	84be                	mv	s1,a5
    80005368:	2781                	sext.w	a5,a5
    8000536a:	f8fb5ce3          	bge	s6,a5,80005302 <filewrite+0x84>
    8000536e:	84de                	mv	s1,s7
    80005370:	bf49                	j	80005302 <filewrite+0x84>
    int i = 0;
    80005372:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005374:	013a1f63          	bne	s4,s3,80005392 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80005378:	8552                	mv	a0,s4
    8000537a:	60a6                	ld	ra,72(sp)
    8000537c:	6406                	ld	s0,64(sp)
    8000537e:	74e2                	ld	s1,56(sp)
    80005380:	7942                	ld	s2,48(sp)
    80005382:	79a2                	ld	s3,40(sp)
    80005384:	7a02                	ld	s4,32(sp)
    80005386:	6ae2                	ld	s5,24(sp)
    80005388:	6b42                	ld	s6,16(sp)
    8000538a:	6ba2                	ld	s7,8(sp)
    8000538c:	6c02                	ld	s8,0(sp)
    8000538e:	6161                	addi	sp,sp,80
    80005390:	8082                	ret
    ret = (i == n ? n : -1);
    80005392:	5a7d                	li	s4,-1
    80005394:	b7d5                	j	80005378 <filewrite+0xfa>
    panic("filewrite");
    80005396:	00003517          	auipc	a0,0x3
    8000539a:	4d250513          	addi	a0,a0,1234 # 80008868 <syscalls+0x2d8>
    8000539e:	ffffb097          	auipc	ra,0xffffb
    800053a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>
    return -1;
    800053a6:	5a7d                	li	s4,-1
    800053a8:	bfc1                	j	80005378 <filewrite+0xfa>
      return -1;
    800053aa:	5a7d                	li	s4,-1
    800053ac:	b7f1                	j	80005378 <filewrite+0xfa>
    800053ae:	5a7d                	li	s4,-1
    800053b0:	b7e1                	j	80005378 <filewrite+0xfa>

00000000800053b2 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800053b2:	7179                	addi	sp,sp,-48
    800053b4:	f406                	sd	ra,40(sp)
    800053b6:	f022                	sd	s0,32(sp)
    800053b8:	ec26                	sd	s1,24(sp)
    800053ba:	e84a                	sd	s2,16(sp)
    800053bc:	e44e                	sd	s3,8(sp)
    800053be:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800053c0:	00854783          	lbu	a5,8(a0)
    800053c4:	c3d5                	beqz	a5,80005468 <kfileread+0xb6>
    800053c6:	84aa                	mv	s1,a0
    800053c8:	89ae                	mv	s3,a1
    800053ca:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800053cc:	411c                	lw	a5,0(a0)
    800053ce:	4705                	li	a4,1
    800053d0:	04e78963          	beq	a5,a4,80005422 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053d4:	470d                	li	a4,3
    800053d6:	04e78d63          	beq	a5,a4,80005430 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800053da:	4709                	li	a4,2
    800053dc:	06e79e63          	bne	a5,a4,80005458 <kfileread+0xa6>
    ilock(f->ip);
    800053e0:	6d08                	ld	a0,24(a0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	aec080e7          	jalr	-1300(ra) # 80003ece <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800053ea:	874a                	mv	a4,s2
    800053ec:	5094                	lw	a3,32(s1)
    800053ee:	864e                	mv	a2,s3
    800053f0:	4581                	li	a1,0
    800053f2:	6c88                	ld	a0,24(s1)
    800053f4:	fffff097          	auipc	ra,0xfffff
    800053f8:	d8e080e7          	jalr	-626(ra) # 80004182 <readi>
    800053fc:	892a                	mv	s2,a0
    800053fe:	00a05563          	blez	a0,80005408 <kfileread+0x56>
      f->off += r;
    80005402:	509c                	lw	a5,32(s1)
    80005404:	9fa9                	addw	a5,a5,a0
    80005406:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005408:	6c88                	ld	a0,24(s1)
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	b86080e7          	jalr	-1146(ra) # 80003f90 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005412:	854a                	mv	a0,s2
    80005414:	70a2                	ld	ra,40(sp)
    80005416:	7402                	ld	s0,32(sp)
    80005418:	64e2                	ld	s1,24(sp)
    8000541a:	6942                	ld	s2,16(sp)
    8000541c:	69a2                	ld	s3,8(sp)
    8000541e:	6145                	addi	sp,sp,48
    80005420:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005422:	6908                	ld	a0,16(a0)
    80005424:	00000097          	auipc	ra,0x0
    80005428:	3c0080e7          	jalr	960(ra) # 800057e4 <piperead>
    8000542c:	892a                	mv	s2,a0
    8000542e:	b7d5                	j	80005412 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005430:	02451783          	lh	a5,36(a0)
    80005434:	03079693          	slli	a3,a5,0x30
    80005438:	92c1                	srli	a3,a3,0x30
    8000543a:	4725                	li	a4,9
    8000543c:	02d76863          	bltu	a4,a3,8000546c <kfileread+0xba>
    80005440:	0792                	slli	a5,a5,0x4
    80005442:	00024717          	auipc	a4,0x24
    80005446:	4d670713          	addi	a4,a4,1238 # 80029918 <devsw>
    8000544a:	97ba                	add	a5,a5,a4
    8000544c:	639c                	ld	a5,0(a5)
    8000544e:	c38d                	beqz	a5,80005470 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005450:	4505                	li	a0,1
    80005452:	9782                	jalr	a5
    80005454:	892a                	mv	s2,a0
    80005456:	bf75                	j	80005412 <kfileread+0x60>
    panic("fileread");
    80005458:	00003517          	auipc	a0,0x3
    8000545c:	40050513          	addi	a0,a0,1024 # 80008858 <syscalls+0x2c8>
    80005460:	ffffb097          	auipc	ra,0xffffb
    80005464:	0ca080e7          	jalr	202(ra) # 8000052a <panic>
    return -1;
    80005468:	597d                	li	s2,-1
    8000546a:	b765                	j	80005412 <kfileread+0x60>
      return -1;
    8000546c:	597d                	li	s2,-1
    8000546e:	b755                	j	80005412 <kfileread+0x60>
    80005470:	597d                	li	s2,-1
    80005472:	b745                	j	80005412 <kfileread+0x60>

0000000080005474 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005474:	715d                	addi	sp,sp,-80
    80005476:	e486                	sd	ra,72(sp)
    80005478:	e0a2                	sd	s0,64(sp)
    8000547a:	fc26                	sd	s1,56(sp)
    8000547c:	f84a                	sd	s2,48(sp)
    8000547e:	f44e                	sd	s3,40(sp)
    80005480:	f052                	sd	s4,32(sp)
    80005482:	ec56                	sd	s5,24(sp)
    80005484:	e85a                	sd	s6,16(sp)
    80005486:	e45e                	sd	s7,8(sp)
    80005488:	e062                	sd	s8,0(sp)
    8000548a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000548c:	00954783          	lbu	a5,9(a0)
    80005490:	10078663          	beqz	a5,8000559c <kfilewrite+0x128>
    80005494:	892a                	mv	s2,a0
    80005496:	8aae                	mv	s5,a1
    80005498:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000549a:	411c                	lw	a5,0(a0)
    8000549c:	4705                	li	a4,1
    8000549e:	02e78263          	beq	a5,a4,800054c2 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800054a2:	470d                	li	a4,3
    800054a4:	02e78663          	beq	a5,a4,800054d0 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800054a8:	4709                	li	a4,2
    800054aa:	0ee79163          	bne	a5,a4,8000558c <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800054ae:	0ac05d63          	blez	a2,80005568 <kfilewrite+0xf4>
    int i = 0;
    800054b2:	4981                	li	s3,0
    800054b4:	6b05                	lui	s6,0x1
    800054b6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800054ba:	6b85                	lui	s7,0x1
    800054bc:	c00b8b9b          	addiw	s7,s7,-1024
    800054c0:	a861                	j	80005558 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800054c2:	6908                	ld	a0,16(a0)
    800054c4:	00000097          	auipc	ra,0x0
    800054c8:	22e080e7          	jalr	558(ra) # 800056f2 <pipewrite>
    800054cc:	8a2a                	mv	s4,a0
    800054ce:	a045                	j	8000556e <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800054d0:	02451783          	lh	a5,36(a0)
    800054d4:	03079693          	slli	a3,a5,0x30
    800054d8:	92c1                	srli	a3,a3,0x30
    800054da:	4725                	li	a4,9
    800054dc:	0cd76263          	bltu	a4,a3,800055a0 <kfilewrite+0x12c>
    800054e0:	0792                	slli	a5,a5,0x4
    800054e2:	00024717          	auipc	a4,0x24
    800054e6:	43670713          	addi	a4,a4,1078 # 80029918 <devsw>
    800054ea:	97ba                	add	a5,a5,a4
    800054ec:	679c                	ld	a5,8(a5)
    800054ee:	cbdd                	beqz	a5,800055a4 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800054f0:	4505                	li	a0,1
    800054f2:	9782                	jalr	a5
    800054f4:	8a2a                	mv	s4,a0
    800054f6:	a8a5                	j	8000556e <kfilewrite+0xfa>
    800054f8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	6ba080e7          	jalr	1722(ra) # 80004bb6 <begin_op>
      ilock(f->ip);
    80005504:	01893503          	ld	a0,24(s2)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	9c6080e7          	jalr	-1594(ra) # 80003ece <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005510:	8762                	mv	a4,s8
    80005512:	02092683          	lw	a3,32(s2)
    80005516:	01598633          	add	a2,s3,s5
    8000551a:	4581                	li	a1,0
    8000551c:	01893503          	ld	a0,24(s2)
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	d5a080e7          	jalr	-678(ra) # 8000427a <writei>
    80005528:	84aa                	mv	s1,a0
    8000552a:	00a05763          	blez	a0,80005538 <kfilewrite+0xc4>
        f->off += r;
    8000552e:	02092783          	lw	a5,32(s2)
    80005532:	9fa9                	addw	a5,a5,a0
    80005534:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005538:	01893503          	ld	a0,24(s2)
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	a54080e7          	jalr	-1452(ra) # 80003f90 <iunlock>
      end_op();
    80005544:	fffff097          	auipc	ra,0xfffff
    80005548:	6f2080e7          	jalr	1778(ra) # 80004c36 <end_op>

      if(r != n1){
    8000554c:	009c1f63          	bne	s8,s1,8000556a <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005550:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005554:	0149db63          	bge	s3,s4,8000556a <kfilewrite+0xf6>
      int n1 = n - i;
    80005558:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000555c:	84be                	mv	s1,a5
    8000555e:	2781                	sext.w	a5,a5
    80005560:	f8fb5ce3          	bge	s6,a5,800054f8 <kfilewrite+0x84>
    80005564:	84de                	mv	s1,s7
    80005566:	bf49                	j	800054f8 <kfilewrite+0x84>
    int i = 0;
    80005568:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000556a:	013a1f63          	bne	s4,s3,80005588 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    8000556e:	8552                	mv	a0,s4
    80005570:	60a6                	ld	ra,72(sp)
    80005572:	6406                	ld	s0,64(sp)
    80005574:	74e2                	ld	s1,56(sp)
    80005576:	7942                	ld	s2,48(sp)
    80005578:	79a2                	ld	s3,40(sp)
    8000557a:	7a02                	ld	s4,32(sp)
    8000557c:	6ae2                	ld	s5,24(sp)
    8000557e:	6b42                	ld	s6,16(sp)
    80005580:	6ba2                	ld	s7,8(sp)
    80005582:	6c02                	ld	s8,0(sp)
    80005584:	6161                	addi	sp,sp,80
    80005586:	8082                	ret
    ret = (i == n ? n : -1);
    80005588:	5a7d                	li	s4,-1
    8000558a:	b7d5                	j	8000556e <kfilewrite+0xfa>
    panic("filewrite");
    8000558c:	00003517          	auipc	a0,0x3
    80005590:	2dc50513          	addi	a0,a0,732 # 80008868 <syscalls+0x2d8>
    80005594:	ffffb097          	auipc	ra,0xffffb
    80005598:	f96080e7          	jalr	-106(ra) # 8000052a <panic>
    return -1;
    8000559c:	5a7d                	li	s4,-1
    8000559e:	bfc1                	j	8000556e <kfilewrite+0xfa>
      return -1;
    800055a0:	5a7d                	li	s4,-1
    800055a2:	b7f1                	j	8000556e <kfilewrite+0xfa>
    800055a4:	5a7d                	li	s4,-1
    800055a6:	b7e1                	j	8000556e <kfilewrite+0xfa>

00000000800055a8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800055a8:	7179                	addi	sp,sp,-48
    800055aa:	f406                	sd	ra,40(sp)
    800055ac:	f022                	sd	s0,32(sp)
    800055ae:	ec26                	sd	s1,24(sp)
    800055b0:	e84a                	sd	s2,16(sp)
    800055b2:	e44e                	sd	s3,8(sp)
    800055b4:	e052                	sd	s4,0(sp)
    800055b6:	1800                	addi	s0,sp,48
    800055b8:	84aa                	mv	s1,a0
    800055ba:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800055bc:	0005b023          	sd	zero,0(a1)
    800055c0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800055c4:	00000097          	auipc	ra,0x0
    800055c8:	a02080e7          	jalr	-1534(ra) # 80004fc6 <filealloc>
    800055cc:	e088                	sd	a0,0(s1)
    800055ce:	c551                	beqz	a0,8000565a <pipealloc+0xb2>
    800055d0:	00000097          	auipc	ra,0x0
    800055d4:	9f6080e7          	jalr	-1546(ra) # 80004fc6 <filealloc>
    800055d8:	00aa3023          	sd	a0,0(s4)
    800055dc:	c92d                	beqz	a0,8000564e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800055de:	ffffb097          	auipc	ra,0xffffb
    800055e2:	504080e7          	jalr	1284(ra) # 80000ae2 <kalloc>
    800055e6:	892a                	mv	s2,a0
    800055e8:	c125                	beqz	a0,80005648 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800055ea:	4985                	li	s3,1
    800055ec:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800055f0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800055f4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800055f8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	27c58593          	addi	a1,a1,636 # 80008878 <syscalls+0x2e8>
    80005604:	ffffb097          	auipc	ra,0xffffb
    80005608:	53e080e7          	jalr	1342(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    8000560c:	609c                	ld	a5,0(s1)
    8000560e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005612:	609c                	ld	a5,0(s1)
    80005614:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005618:	609c                	ld	a5,0(s1)
    8000561a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000561e:	609c                	ld	a5,0(s1)
    80005620:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005624:	000a3783          	ld	a5,0(s4)
    80005628:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000562c:	000a3783          	ld	a5,0(s4)
    80005630:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005634:	000a3783          	ld	a5,0(s4)
    80005638:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000563c:	000a3783          	ld	a5,0(s4)
    80005640:	0127b823          	sd	s2,16(a5)
  return 0;
    80005644:	4501                	li	a0,0
    80005646:	a025                	j	8000566e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005648:	6088                	ld	a0,0(s1)
    8000564a:	e501                	bnez	a0,80005652 <pipealloc+0xaa>
    8000564c:	a039                	j	8000565a <pipealloc+0xb2>
    8000564e:	6088                	ld	a0,0(s1)
    80005650:	c51d                	beqz	a0,8000567e <pipealloc+0xd6>
    fileclose(*f0);
    80005652:	00000097          	auipc	ra,0x0
    80005656:	a30080e7          	jalr	-1488(ra) # 80005082 <fileclose>
  if(*f1)
    8000565a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000565e:	557d                	li	a0,-1
  if(*f1)
    80005660:	c799                	beqz	a5,8000566e <pipealloc+0xc6>
    fileclose(*f1);
    80005662:	853e                	mv	a0,a5
    80005664:	00000097          	auipc	ra,0x0
    80005668:	a1e080e7          	jalr	-1506(ra) # 80005082 <fileclose>
  return -1;
    8000566c:	557d                	li	a0,-1
}
    8000566e:	70a2                	ld	ra,40(sp)
    80005670:	7402                	ld	s0,32(sp)
    80005672:	64e2                	ld	s1,24(sp)
    80005674:	6942                	ld	s2,16(sp)
    80005676:	69a2                	ld	s3,8(sp)
    80005678:	6a02                	ld	s4,0(sp)
    8000567a:	6145                	addi	sp,sp,48
    8000567c:	8082                	ret
  return -1;
    8000567e:	557d                	li	a0,-1
    80005680:	b7fd                	j	8000566e <pipealloc+0xc6>

0000000080005682 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005682:	1101                	addi	sp,sp,-32
    80005684:	ec06                	sd	ra,24(sp)
    80005686:	e822                	sd	s0,16(sp)
    80005688:	e426                	sd	s1,8(sp)
    8000568a:	e04a                	sd	s2,0(sp)
    8000568c:	1000                	addi	s0,sp,32
    8000568e:	84aa                	mv	s1,a0
    80005690:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005692:	ffffb097          	auipc	ra,0xffffb
    80005696:	540080e7          	jalr	1344(ra) # 80000bd2 <acquire>
  if(writable){
    8000569a:	02090d63          	beqz	s2,800056d4 <pipeclose+0x52>
    pi->writeopen = 0;
    8000569e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800056a2:	21848513          	addi	a0,s1,536
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	41c080e7          	jalr	1052(ra) # 80002ac2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800056ae:	2204b783          	ld	a5,544(s1)
    800056b2:	eb95                	bnez	a5,800056e6 <pipeclose+0x64>
    release(&pi->lock);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffb097          	auipc	ra,0xffffb
    800056ba:	5d0080e7          	jalr	1488(ra) # 80000c86 <release>
    kfree((char*)pi);
    800056be:	8526                	mv	a0,s1
    800056c0:	ffffb097          	auipc	ra,0xffffb
    800056c4:	316080e7          	jalr	790(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800056c8:	60e2                	ld	ra,24(sp)
    800056ca:	6442                	ld	s0,16(sp)
    800056cc:	64a2                	ld	s1,8(sp)
    800056ce:	6902                	ld	s2,0(sp)
    800056d0:	6105                	addi	sp,sp,32
    800056d2:	8082                	ret
    pi->readopen = 0;
    800056d4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800056d8:	21c48513          	addi	a0,s1,540
    800056dc:	ffffd097          	auipc	ra,0xffffd
    800056e0:	3e6080e7          	jalr	998(ra) # 80002ac2 <wakeup>
    800056e4:	b7e9                	j	800056ae <pipeclose+0x2c>
    release(&pi->lock);
    800056e6:	8526                	mv	a0,s1
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	59e080e7          	jalr	1438(ra) # 80000c86 <release>
}
    800056f0:	bfe1                	j	800056c8 <pipeclose+0x46>

00000000800056f2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800056f2:	711d                	addi	sp,sp,-96
    800056f4:	ec86                	sd	ra,88(sp)
    800056f6:	e8a2                	sd	s0,80(sp)
    800056f8:	e4a6                	sd	s1,72(sp)
    800056fa:	e0ca                	sd	s2,64(sp)
    800056fc:	fc4e                	sd	s3,56(sp)
    800056fe:	f852                	sd	s4,48(sp)
    80005700:	f456                	sd	s5,40(sp)
    80005702:	f05a                	sd	s6,32(sp)
    80005704:	ec5e                	sd	s7,24(sp)
    80005706:	e862                	sd	s8,16(sp)
    80005708:	1080                	addi	s0,sp,96
    8000570a:	84aa                	mv	s1,a0
    8000570c:	8aae                	mv	s5,a1
    8000570e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005710:	ffffd097          	auipc	ra,0xffffd
    80005714:	968080e7          	jalr	-1688(ra) # 80002078 <myproc>
    80005718:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffb097          	auipc	ra,0xffffb
    80005720:	4b6080e7          	jalr	1206(ra) # 80000bd2 <acquire>
  while(i < n){
    80005724:	0b405363          	blez	s4,800057ca <pipewrite+0xd8>
  int i = 0;
    80005728:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000572a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000572c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005730:	21c48b93          	addi	s7,s1,540
    80005734:	a089                	j	80005776 <pipewrite+0x84>
      release(&pi->lock);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	54e080e7          	jalr	1358(ra) # 80000c86 <release>
      return -1;
    80005740:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005742:	854a                	mv	a0,s2
    80005744:	60e6                	ld	ra,88(sp)
    80005746:	6446                	ld	s0,80(sp)
    80005748:	64a6                	ld	s1,72(sp)
    8000574a:	6906                	ld	s2,64(sp)
    8000574c:	79e2                	ld	s3,56(sp)
    8000574e:	7a42                	ld	s4,48(sp)
    80005750:	7aa2                	ld	s5,40(sp)
    80005752:	7b02                	ld	s6,32(sp)
    80005754:	6be2                	ld	s7,24(sp)
    80005756:	6c42                	ld	s8,16(sp)
    80005758:	6125                	addi	sp,sp,96
    8000575a:	8082                	ret
      wakeup(&pi->nread);
    8000575c:	8562                	mv	a0,s8
    8000575e:	ffffd097          	auipc	ra,0xffffd
    80005762:	364080e7          	jalr	868(ra) # 80002ac2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005766:	85a6                	mv	a1,s1
    80005768:	855e                	mv	a0,s7
    8000576a:	ffffd097          	auipc	ra,0xffffd
    8000576e:	1cc080e7          	jalr	460(ra) # 80002936 <sleep>
  while(i < n){
    80005772:	05495d63          	bge	s2,s4,800057cc <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005776:	2204a783          	lw	a5,544(s1)
    8000577a:	dfd5                	beqz	a5,80005736 <pipewrite+0x44>
    8000577c:	0289a783          	lw	a5,40(s3)
    80005780:	fbdd                	bnez	a5,80005736 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005782:	2184a783          	lw	a5,536(s1)
    80005786:	21c4a703          	lw	a4,540(s1)
    8000578a:	2007879b          	addiw	a5,a5,512
    8000578e:	fcf707e3          	beq	a4,a5,8000575c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005792:	4685                	li	a3,1
    80005794:	01590633          	add	a2,s2,s5
    80005798:	faf40593          	addi	a1,s0,-81
    8000579c:	0509b503          	ld	a0,80(s3)
    800057a0:	ffffc097          	auipc	ra,0xffffc
    800057a4:	f3a080e7          	jalr	-198(ra) # 800016da <copyin>
    800057a8:	03650263          	beq	a0,s6,800057cc <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800057ac:	21c4a783          	lw	a5,540(s1)
    800057b0:	0017871b          	addiw	a4,a5,1
    800057b4:	20e4ae23          	sw	a4,540(s1)
    800057b8:	1ff7f793          	andi	a5,a5,511
    800057bc:	97a6                	add	a5,a5,s1
    800057be:	faf44703          	lbu	a4,-81(s0)
    800057c2:	00e78c23          	sb	a4,24(a5)
      i++;
    800057c6:	2905                	addiw	s2,s2,1
    800057c8:	b76d                	j	80005772 <pipewrite+0x80>
  int i = 0;
    800057ca:	4901                	li	s2,0
  wakeup(&pi->nread);
    800057cc:	21848513          	addi	a0,s1,536
    800057d0:	ffffd097          	auipc	ra,0xffffd
    800057d4:	2f2080e7          	jalr	754(ra) # 80002ac2 <wakeup>
  release(&pi->lock);
    800057d8:	8526                	mv	a0,s1
    800057da:	ffffb097          	auipc	ra,0xffffb
    800057de:	4ac080e7          	jalr	1196(ra) # 80000c86 <release>
  return i;
    800057e2:	b785                	j	80005742 <pipewrite+0x50>

00000000800057e4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800057e4:	715d                	addi	sp,sp,-80
    800057e6:	e486                	sd	ra,72(sp)
    800057e8:	e0a2                	sd	s0,64(sp)
    800057ea:	fc26                	sd	s1,56(sp)
    800057ec:	f84a                	sd	s2,48(sp)
    800057ee:	f44e                	sd	s3,40(sp)
    800057f0:	f052                	sd	s4,32(sp)
    800057f2:	ec56                	sd	s5,24(sp)
    800057f4:	e85a                	sd	s6,16(sp)
    800057f6:	0880                	addi	s0,sp,80
    800057f8:	84aa                	mv	s1,a0
    800057fa:	892e                	mv	s2,a1
    800057fc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	87a080e7          	jalr	-1926(ra) # 80002078 <myproc>
    80005806:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffb097          	auipc	ra,0xffffb
    8000580e:	3c8080e7          	jalr	968(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005812:	2184a703          	lw	a4,536(s1)
    80005816:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000581a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000581e:	02f71463          	bne	a4,a5,80005846 <piperead+0x62>
    80005822:	2244a783          	lw	a5,548(s1)
    80005826:	c385                	beqz	a5,80005846 <piperead+0x62>
    if(pr->killed){
    80005828:	028a2783          	lw	a5,40(s4)
    8000582c:	ebc1                	bnez	a5,800058bc <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000582e:	85a6                	mv	a1,s1
    80005830:	854e                	mv	a0,s3
    80005832:	ffffd097          	auipc	ra,0xffffd
    80005836:	104080e7          	jalr	260(ra) # 80002936 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000583a:	2184a703          	lw	a4,536(s1)
    8000583e:	21c4a783          	lw	a5,540(s1)
    80005842:	fef700e3          	beq	a4,a5,80005822 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005846:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005848:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000584a:	05505363          	blez	s5,80005890 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    8000584e:	2184a783          	lw	a5,536(s1)
    80005852:	21c4a703          	lw	a4,540(s1)
    80005856:	02f70d63          	beq	a4,a5,80005890 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000585a:	0017871b          	addiw	a4,a5,1
    8000585e:	20e4ac23          	sw	a4,536(s1)
    80005862:	1ff7f793          	andi	a5,a5,511
    80005866:	97a6                	add	a5,a5,s1
    80005868:	0187c783          	lbu	a5,24(a5)
    8000586c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005870:	4685                	li	a3,1
    80005872:	fbf40613          	addi	a2,s0,-65
    80005876:	85ca                	mv	a1,s2
    80005878:	050a3503          	ld	a0,80(s4)
    8000587c:	ffffc097          	auipc	ra,0xffffc
    80005880:	dd2080e7          	jalr	-558(ra) # 8000164e <copyout>
    80005884:	01650663          	beq	a0,s6,80005890 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005888:	2985                	addiw	s3,s3,1
    8000588a:	0905                	addi	s2,s2,1
    8000588c:	fd3a91e3          	bne	s5,s3,8000584e <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005890:	21c48513          	addi	a0,s1,540
    80005894:	ffffd097          	auipc	ra,0xffffd
    80005898:	22e080e7          	jalr	558(ra) # 80002ac2 <wakeup>
  release(&pi->lock);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffb097          	auipc	ra,0xffffb
    800058a2:	3e8080e7          	jalr	1000(ra) # 80000c86 <release>
  return i;
}
    800058a6:	854e                	mv	a0,s3
    800058a8:	60a6                	ld	ra,72(sp)
    800058aa:	6406                	ld	s0,64(sp)
    800058ac:	74e2                	ld	s1,56(sp)
    800058ae:	7942                	ld	s2,48(sp)
    800058b0:	79a2                	ld	s3,40(sp)
    800058b2:	7a02                	ld	s4,32(sp)
    800058b4:	6ae2                	ld	s5,24(sp)
    800058b6:	6b42                	ld	s6,16(sp)
    800058b8:	6161                	addi	sp,sp,80
    800058ba:	8082                	ret
      release(&pi->lock);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	3c8080e7          	jalr	968(ra) # 80000c86 <release>
      return -1;
    800058c6:	59fd                	li	s3,-1
    800058c8:	bff9                	j	800058a6 <piperead+0xc2>

00000000800058ca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800058ca:	de010113          	addi	sp,sp,-544
    800058ce:	20113c23          	sd	ra,536(sp)
    800058d2:	20813823          	sd	s0,528(sp)
    800058d6:	20913423          	sd	s1,520(sp)
    800058da:	21213023          	sd	s2,512(sp)
    800058de:	ffce                	sd	s3,504(sp)
    800058e0:	fbd2                	sd	s4,496(sp)
    800058e2:	f7d6                	sd	s5,488(sp)
    800058e4:	f3da                	sd	s6,480(sp)
    800058e6:	efde                	sd	s7,472(sp)
    800058e8:	ebe2                	sd	s8,464(sp)
    800058ea:	e7e6                	sd	s9,456(sp)
    800058ec:	e3ea                	sd	s10,448(sp)
    800058ee:	ff6e                	sd	s11,440(sp)
    800058f0:	1400                	addi	s0,sp,544
    800058f2:	892a                	mv	s2,a0
    800058f4:	dea43423          	sd	a0,-536(s0)
    800058f8:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800058fc:	ffffc097          	auipc	ra,0xffffc
    80005900:	77c080e7          	jalr	1916(ra) # 80002078 <myproc>
    80005904:	84aa                	mv	s1,a0

  begin_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	2b0080e7          	jalr	688(ra) # 80004bb6 <begin_op>

  if((ip = namei(path)) == 0){
    8000590e:	854a                	mv	a0,s2
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	d74080e7          	jalr	-652(ra) # 80004684 <namei>
    80005918:	c93d                	beqz	a0,8000598e <exec+0xc4>
    8000591a:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	5b2080e7          	jalr	1458(ra) # 80003ece <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005924:	04000713          	li	a4,64
    80005928:	4681                	li	a3,0
    8000592a:	e4840613          	addi	a2,s0,-440
    8000592e:	4581                	li	a1,0
    80005930:	8556                	mv	a0,s5
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	850080e7          	jalr	-1968(ra) # 80004182 <readi>
    8000593a:	04000793          	li	a5,64
    8000593e:	00f51a63          	bne	a0,a5,80005952 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005942:	e4842703          	lw	a4,-440(s0)
    80005946:	464c47b7          	lui	a5,0x464c4
    8000594a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000594e:	04f70663          	beq	a4,a5,8000599a <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005952:	8556                	mv	a0,s5
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	7dc080e7          	jalr	2012(ra) # 80004130 <iunlockput>
    end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	2da080e7          	jalr	730(ra) # 80004c36 <end_op>
  }
  return -1;
    80005964:	557d                	li	a0,-1
}
    80005966:	21813083          	ld	ra,536(sp)
    8000596a:	21013403          	ld	s0,528(sp)
    8000596e:	20813483          	ld	s1,520(sp)
    80005972:	20013903          	ld	s2,512(sp)
    80005976:	79fe                	ld	s3,504(sp)
    80005978:	7a5e                	ld	s4,496(sp)
    8000597a:	7abe                	ld	s5,488(sp)
    8000597c:	7b1e                	ld	s6,480(sp)
    8000597e:	6bfe                	ld	s7,472(sp)
    80005980:	6c5e                	ld	s8,464(sp)
    80005982:	6cbe                	ld	s9,456(sp)
    80005984:	6d1e                	ld	s10,448(sp)
    80005986:	7dfa                	ld	s11,440(sp)
    80005988:	22010113          	addi	sp,sp,544
    8000598c:	8082                	ret
    end_op();
    8000598e:	fffff097          	auipc	ra,0xfffff
    80005992:	2a8080e7          	jalr	680(ra) # 80004c36 <end_op>
    return -1;
    80005996:	557d                	li	a0,-1
    80005998:	b7f9                	j	80005966 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000599a:	8526                	mv	a0,s1
    8000599c:	ffffc097          	auipc	ra,0xffffc
    800059a0:	7a0080e7          	jalr	1952(ra) # 8000213c <proc_pagetable>
    800059a4:	8b2a                	mv	s6,a0
    800059a6:	d555                	beqz	a0,80005952 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059a8:	e6842783          	lw	a5,-408(s0)
    800059ac:	e8045703          	lhu	a4,-384(s0)
    800059b0:	c735                	beqz	a4,80005a1c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800059b2:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800059b4:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800059b8:	6a05                	lui	s4,0x1
    800059ba:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800059be:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800059c2:	6d85                	lui	s11,0x1
    800059c4:	7d7d                	lui	s10,0xfffff
    800059c6:	ac1d                	j	80005bfc <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800059c8:	00003517          	auipc	a0,0x3
    800059cc:	eb850513          	addi	a0,a0,-328 # 80008880 <syscalls+0x2f0>
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	b5a080e7          	jalr	-1190(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800059d8:	874a                	mv	a4,s2
    800059da:	009c86bb          	addw	a3,s9,s1
    800059de:	4581                	li	a1,0
    800059e0:	8556                	mv	a0,s5
    800059e2:	ffffe097          	auipc	ra,0xffffe
    800059e6:	7a0080e7          	jalr	1952(ra) # 80004182 <readi>
    800059ea:	2501                	sext.w	a0,a0
    800059ec:	1aa91863          	bne	s2,a0,80005b9c <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800059f0:	009d84bb          	addw	s1,s11,s1
    800059f4:	013d09bb          	addw	s3,s10,s3
    800059f8:	1f74f263          	bgeu	s1,s7,80005bdc <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800059fc:	02049593          	slli	a1,s1,0x20
    80005a00:	9181                	srli	a1,a1,0x20
    80005a02:	95e2                	add	a1,a1,s8
    80005a04:	855a                	mv	a0,s6
    80005a06:	ffffb097          	auipc	ra,0xffffb
    80005a0a:	656080e7          	jalr	1622(ra) # 8000105c <walkaddr>
    80005a0e:	862a                	mv	a2,a0
    if(pa == 0)
    80005a10:	dd45                	beqz	a0,800059c8 <exec+0xfe>
      n = PGSIZE;
    80005a12:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005a14:	fd49f2e3          	bgeu	s3,s4,800059d8 <exec+0x10e>
      n = sz - i;
    80005a18:	894e                	mv	s2,s3
    80005a1a:	bf7d                	j	800059d8 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005a1c:	4481                	li	s1,0
  iunlockput(ip);
    80005a1e:	8556                	mv	a0,s5
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	710080e7          	jalr	1808(ra) # 80004130 <iunlockput>
  end_op();
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	20e080e7          	jalr	526(ra) # 80004c36 <end_op>
  p = myproc();
    80005a30:	ffffc097          	auipc	ra,0xffffc
    80005a34:	648080e7          	jalr	1608(ra) # 80002078 <myproc>
    80005a38:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005a3a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005a3e:	6785                	lui	a5,0x1
    80005a40:	17fd                	addi	a5,a5,-1
    80005a42:	94be                	add	s1,s1,a5
    80005a44:	77fd                	lui	a5,0xfffff
    80005a46:	8fe5                	and	a5,a5,s1
    80005a48:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a4c:	6609                	lui	a2,0x2
    80005a4e:	963e                	add	a2,a2,a5
    80005a50:	85be                	mv	a1,a5
    80005a52:	855a                	mv	a0,s6
    80005a54:	ffffc097          	auipc	ra,0xffffc
    80005a58:	9aa080e7          	jalr	-1622(ra) # 800013fe <uvmalloc>
    80005a5c:	8c2a                	mv	s8,a0
  ip = 0;
    80005a5e:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005a60:	12050e63          	beqz	a0,80005b9c <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005a64:	75f9                	lui	a1,0xffffe
    80005a66:	95aa                	add	a1,a1,a0
    80005a68:	855a                	mv	a0,s6
    80005a6a:	ffffc097          	auipc	ra,0xffffc
    80005a6e:	bb2080e7          	jalr	-1102(ra) # 8000161c <uvmclear>
  stackbase = sp - PGSIZE;
    80005a72:	7afd                	lui	s5,0xfffff
    80005a74:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005a76:	df043783          	ld	a5,-528(s0)
    80005a7a:	6388                	ld	a0,0(a5)
    80005a7c:	c925                	beqz	a0,80005aec <exec+0x222>
    80005a7e:	e8840993          	addi	s3,s0,-376
    80005a82:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005a86:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005a88:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005a8a:	ffffb097          	auipc	ra,0xffffb
    80005a8e:	3c8080e7          	jalr	968(ra) # 80000e52 <strlen>
    80005a92:	0015079b          	addiw	a5,a0,1
    80005a96:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a9a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a9e:	13596363          	bltu	s2,s5,80005bc4 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005aa2:	df043d83          	ld	s11,-528(s0)
    80005aa6:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005aaa:	8552                	mv	a0,s4
    80005aac:	ffffb097          	auipc	ra,0xffffb
    80005ab0:	3a6080e7          	jalr	934(ra) # 80000e52 <strlen>
    80005ab4:	0015069b          	addiw	a3,a0,1
    80005ab8:	8652                	mv	a2,s4
    80005aba:	85ca                	mv	a1,s2
    80005abc:	855a                	mv	a0,s6
    80005abe:	ffffc097          	auipc	ra,0xffffc
    80005ac2:	b90080e7          	jalr	-1136(ra) # 8000164e <copyout>
    80005ac6:	10054363          	bltz	a0,80005bcc <exec+0x302>
    ustack[argc] = sp;
    80005aca:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005ace:	0485                	addi	s1,s1,1
    80005ad0:	008d8793          	addi	a5,s11,8
    80005ad4:	def43823          	sd	a5,-528(s0)
    80005ad8:	008db503          	ld	a0,8(s11)
    80005adc:	c911                	beqz	a0,80005af0 <exec+0x226>
    if(argc >= MAXARG)
    80005ade:	09a1                	addi	s3,s3,8
    80005ae0:	fb3c95e3          	bne	s9,s3,80005a8a <exec+0x1c0>
  sz = sz1;
    80005ae4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005ae8:	4a81                	li	s5,0
    80005aea:	a84d                	j	80005b9c <exec+0x2d2>
  sp = sz;
    80005aec:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005aee:	4481                	li	s1,0
  ustack[argc] = 0;
    80005af0:	00349793          	slli	a5,s1,0x3
    80005af4:	f9040713          	addi	a4,s0,-112
    80005af8:	97ba                	add	a5,a5,a4
    80005afa:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd0ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005afe:	00148693          	addi	a3,s1,1
    80005b02:	068e                	slli	a3,a3,0x3
    80005b04:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005b08:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005b0c:	01597663          	bgeu	s2,s5,80005b18 <exec+0x24e>
  sz = sz1;
    80005b10:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005b14:	4a81                	li	s5,0
    80005b16:	a059                	j	80005b9c <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005b18:	e8840613          	addi	a2,s0,-376
    80005b1c:	85ca                	mv	a1,s2
    80005b1e:	855a                	mv	a0,s6
    80005b20:	ffffc097          	auipc	ra,0xffffc
    80005b24:	b2e080e7          	jalr	-1234(ra) # 8000164e <copyout>
    80005b28:	0a054663          	bltz	a0,80005bd4 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005b2c:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005b30:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005b34:	de843783          	ld	a5,-536(s0)
    80005b38:	0007c703          	lbu	a4,0(a5)
    80005b3c:	cf11                	beqz	a4,80005b58 <exec+0x28e>
    80005b3e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005b40:	02f00693          	li	a3,47
    80005b44:	a039                	j	80005b52 <exec+0x288>
      last = s+1;
    80005b46:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005b4a:	0785                	addi	a5,a5,1
    80005b4c:	fff7c703          	lbu	a4,-1(a5)
    80005b50:	c701                	beqz	a4,80005b58 <exec+0x28e>
    if(*s == '/')
    80005b52:	fed71ce3          	bne	a4,a3,80005b4a <exec+0x280>
    80005b56:	bfc5                	j	80005b46 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005b58:	4641                	li	a2,16
    80005b5a:	de843583          	ld	a1,-536(s0)
    80005b5e:	158b8513          	addi	a0,s7,344
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	2be080e7          	jalr	702(ra) # 80000e20 <safestrcpy>
  oldpagetable = p->pagetable;
    80005b6a:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005b6e:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005b72:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005b76:	058bb783          	ld	a5,88(s7)
    80005b7a:	e6043703          	ld	a4,-416(s0)
    80005b7e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005b80:	058bb783          	ld	a5,88(s7)
    80005b84:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005b88:	85ea                	mv	a1,s10
    80005b8a:	ffffc097          	auipc	ra,0xffffc
    80005b8e:	64e080e7          	jalr	1614(ra) # 800021d8 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b92:	0004851b          	sext.w	a0,s1
    80005b96:	bbc1                	j	80005966 <exec+0x9c>
    80005b98:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005b9c:	df843583          	ld	a1,-520(s0)
    80005ba0:	855a                	mv	a0,s6
    80005ba2:	ffffc097          	auipc	ra,0xffffc
    80005ba6:	636080e7          	jalr	1590(ra) # 800021d8 <proc_freepagetable>
  if(ip){
    80005baa:	da0a94e3          	bnez	s5,80005952 <exec+0x88>
  return -1;
    80005bae:	557d                	li	a0,-1
    80005bb0:	bb5d                	j	80005966 <exec+0x9c>
    80005bb2:	de943c23          	sd	s1,-520(s0)
    80005bb6:	b7dd                	j	80005b9c <exec+0x2d2>
    80005bb8:	de943c23          	sd	s1,-520(s0)
    80005bbc:	b7c5                	j	80005b9c <exec+0x2d2>
    80005bbe:	de943c23          	sd	s1,-520(s0)
    80005bc2:	bfe9                	j	80005b9c <exec+0x2d2>
  sz = sz1;
    80005bc4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005bc8:	4a81                	li	s5,0
    80005bca:	bfc9                	j	80005b9c <exec+0x2d2>
  sz = sz1;
    80005bcc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005bd0:	4a81                	li	s5,0
    80005bd2:	b7e9                	j	80005b9c <exec+0x2d2>
  sz = sz1;
    80005bd4:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005bd8:	4a81                	li	s5,0
    80005bda:	b7c9                	j	80005b9c <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005bdc:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005be0:	e0843783          	ld	a5,-504(s0)
    80005be4:	0017869b          	addiw	a3,a5,1
    80005be8:	e0d43423          	sd	a3,-504(s0)
    80005bec:	e0043783          	ld	a5,-512(s0)
    80005bf0:	0387879b          	addiw	a5,a5,56
    80005bf4:	e8045703          	lhu	a4,-384(s0)
    80005bf8:	e2e6d3e3          	bge	a3,a4,80005a1e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005bfc:	2781                	sext.w	a5,a5
    80005bfe:	e0f43023          	sd	a5,-512(s0)
    80005c02:	03800713          	li	a4,56
    80005c06:	86be                	mv	a3,a5
    80005c08:	e1040613          	addi	a2,s0,-496
    80005c0c:	4581                	li	a1,0
    80005c0e:	8556                	mv	a0,s5
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	572080e7          	jalr	1394(ra) # 80004182 <readi>
    80005c18:	03800793          	li	a5,56
    80005c1c:	f6f51ee3          	bne	a0,a5,80005b98 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005c20:	e1042783          	lw	a5,-496(s0)
    80005c24:	4705                	li	a4,1
    80005c26:	fae79de3          	bne	a5,a4,80005be0 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005c2a:	e3843603          	ld	a2,-456(s0)
    80005c2e:	e3043783          	ld	a5,-464(s0)
    80005c32:	f8f660e3          	bltu	a2,a5,80005bb2 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005c36:	e2043783          	ld	a5,-480(s0)
    80005c3a:	963e                	add	a2,a2,a5
    80005c3c:	f6f66ee3          	bltu	a2,a5,80005bb8 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005c40:	85a6                	mv	a1,s1
    80005c42:	855a                	mv	a0,s6
    80005c44:	ffffb097          	auipc	ra,0xffffb
    80005c48:	7ba080e7          	jalr	1978(ra) # 800013fe <uvmalloc>
    80005c4c:	dea43c23          	sd	a0,-520(s0)
    80005c50:	d53d                	beqz	a0,80005bbe <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005c52:	e2043c03          	ld	s8,-480(s0)
    80005c56:	de043783          	ld	a5,-544(s0)
    80005c5a:	00fc77b3          	and	a5,s8,a5
    80005c5e:	ff9d                	bnez	a5,80005b9c <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005c60:	e1842c83          	lw	s9,-488(s0)
    80005c64:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005c68:	f60b8ae3          	beqz	s7,80005bdc <exec+0x312>
    80005c6c:	89de                	mv	s3,s7
    80005c6e:	4481                	li	s1,0
    80005c70:	b371                	j	800059fc <exec+0x132>

0000000080005c72 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005c72:	7179                	addi	sp,sp,-48
    80005c74:	f406                	sd	ra,40(sp)
    80005c76:	f022                	sd	s0,32(sp)
    80005c78:	ec26                	sd	s1,24(sp)
    80005c7a:	e84a                	sd	s2,16(sp)
    80005c7c:	1800                	addi	s0,sp,48
    80005c7e:	892e                	mv	s2,a1
    80005c80:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005c82:	fdc40593          	addi	a1,s0,-36
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	6d6080e7          	jalr	1750(ra) # 8000335c <argint>
    80005c8e:	04054063          	bltz	a0,80005cce <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c92:	fdc42703          	lw	a4,-36(s0)
    80005c96:	47bd                	li	a5,15
    80005c98:	02e7ed63          	bltu	a5,a4,80005cd2 <argfd+0x60>
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	3dc080e7          	jalr	988(ra) # 80002078 <myproc>
    80005ca4:	fdc42703          	lw	a4,-36(s0)
    80005ca8:	01a70793          	addi	a5,a4,26
    80005cac:	078e                	slli	a5,a5,0x3
    80005cae:	953e                	add	a0,a0,a5
    80005cb0:	611c                	ld	a5,0(a0)
    80005cb2:	c395                	beqz	a5,80005cd6 <argfd+0x64>
    return -1;
  if(pfd)
    80005cb4:	00090463          	beqz	s2,80005cbc <argfd+0x4a>
    *pfd = fd;
    80005cb8:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005cbc:	4501                	li	a0,0
  if(pf)
    80005cbe:	c091                	beqz	s1,80005cc2 <argfd+0x50>
    *pf = f;
    80005cc0:	e09c                	sd	a5,0(s1)
}
    80005cc2:	70a2                	ld	ra,40(sp)
    80005cc4:	7402                	ld	s0,32(sp)
    80005cc6:	64e2                	ld	s1,24(sp)
    80005cc8:	6942                	ld	s2,16(sp)
    80005cca:	6145                	addi	sp,sp,48
    80005ccc:	8082                	ret
    return -1;
    80005cce:	557d                	li	a0,-1
    80005cd0:	bfcd                	j	80005cc2 <argfd+0x50>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	b7fd                	j	80005cc2 <argfd+0x50>
    80005cd6:	557d                	li	a0,-1
    80005cd8:	b7ed                	j	80005cc2 <argfd+0x50>

0000000080005cda <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005cda:	1101                	addi	sp,sp,-32
    80005cdc:	ec06                	sd	ra,24(sp)
    80005cde:	e822                	sd	s0,16(sp)
    80005ce0:	e426                	sd	s1,8(sp)
    80005ce2:	1000                	addi	s0,sp,32
    80005ce4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ce6:	ffffc097          	auipc	ra,0xffffc
    80005cea:	392080e7          	jalr	914(ra) # 80002078 <myproc>
    80005cee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005cf0:	0d050793          	addi	a5,a0,208
    80005cf4:	4501                	li	a0,0
    80005cf6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005cf8:	6398                	ld	a4,0(a5)
    80005cfa:	cb19                	beqz	a4,80005d10 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005cfc:	2505                	addiw	a0,a0,1
    80005cfe:	07a1                	addi	a5,a5,8
    80005d00:	fed51ce3          	bne	a0,a3,80005cf8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005d04:	557d                	li	a0,-1
}
    80005d06:	60e2                	ld	ra,24(sp)
    80005d08:	6442                	ld	s0,16(sp)
    80005d0a:	64a2                	ld	s1,8(sp)
    80005d0c:	6105                	addi	sp,sp,32
    80005d0e:	8082                	ret
      p->ofile[fd] = f;
    80005d10:	01a50793          	addi	a5,a0,26
    80005d14:	078e                	slli	a5,a5,0x3
    80005d16:	963e                	add	a2,a2,a5
    80005d18:	e204                	sd	s1,0(a2)
      return fd;
    80005d1a:	b7f5                	j	80005d06 <fdalloc+0x2c>

0000000080005d1c <sys_dup>:

uint64
sys_dup(void)
{
    80005d1c:	7179                	addi	sp,sp,-48
    80005d1e:	f406                	sd	ra,40(sp)
    80005d20:	f022                	sd	s0,32(sp)
    80005d22:	ec26                	sd	s1,24(sp)
    80005d24:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005d26:	fd840613          	addi	a2,s0,-40
    80005d2a:	4581                	li	a1,0
    80005d2c:	4501                	li	a0,0
    80005d2e:	00000097          	auipc	ra,0x0
    80005d32:	f44080e7          	jalr	-188(ra) # 80005c72 <argfd>
    return -1;
    80005d36:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005d38:	02054363          	bltz	a0,80005d5e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005d3c:	fd843503          	ld	a0,-40(s0)
    80005d40:	00000097          	auipc	ra,0x0
    80005d44:	f9a080e7          	jalr	-102(ra) # 80005cda <fdalloc>
    80005d48:	84aa                	mv	s1,a0
    return -1;
    80005d4a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005d4c:	00054963          	bltz	a0,80005d5e <sys_dup+0x42>
  filedup(f);
    80005d50:	fd843503          	ld	a0,-40(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	2dc080e7          	jalr	732(ra) # 80005030 <filedup>
  return fd;
    80005d5c:	87a6                	mv	a5,s1
}
    80005d5e:	853e                	mv	a0,a5
    80005d60:	70a2                	ld	ra,40(sp)
    80005d62:	7402                	ld	s0,32(sp)
    80005d64:	64e2                	ld	s1,24(sp)
    80005d66:	6145                	addi	sp,sp,48
    80005d68:	8082                	ret

0000000080005d6a <sys_read>:

uint64
sys_read(void)
{
    80005d6a:	7179                	addi	sp,sp,-48
    80005d6c:	f406                	sd	ra,40(sp)
    80005d6e:	f022                	sd	s0,32(sp)
    80005d70:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d72:	fe840613          	addi	a2,s0,-24
    80005d76:	4581                	li	a1,0
    80005d78:	4501                	li	a0,0
    80005d7a:	00000097          	auipc	ra,0x0
    80005d7e:	ef8080e7          	jalr	-264(ra) # 80005c72 <argfd>
    return -1;
    80005d82:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d84:	04054163          	bltz	a0,80005dc6 <sys_read+0x5c>
    80005d88:	fe440593          	addi	a1,s0,-28
    80005d8c:	4509                	li	a0,2
    80005d8e:	ffffd097          	auipc	ra,0xffffd
    80005d92:	5ce080e7          	jalr	1486(ra) # 8000335c <argint>
    return -1;
    80005d96:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005d98:	02054763          	bltz	a0,80005dc6 <sys_read+0x5c>
    80005d9c:	fd840593          	addi	a1,s0,-40
    80005da0:	4505                	li	a0,1
    80005da2:	ffffd097          	auipc	ra,0xffffd
    80005da6:	5dc080e7          	jalr	1500(ra) # 8000337e <argaddr>
    return -1;
    80005daa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dac:	00054d63          	bltz	a0,80005dc6 <sys_read+0x5c>
  return fileread(f, p, n);
    80005db0:	fe442603          	lw	a2,-28(s0)
    80005db4:	fd843583          	ld	a1,-40(s0)
    80005db8:	fe843503          	ld	a0,-24(s0)
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	400080e7          	jalr	1024(ra) # 800051bc <fileread>
    80005dc4:	87aa                	mv	a5,a0
}
    80005dc6:	853e                	mv	a0,a5
    80005dc8:	70a2                	ld	ra,40(sp)
    80005dca:	7402                	ld	s0,32(sp)
    80005dcc:	6145                	addi	sp,sp,48
    80005dce:	8082                	ret

0000000080005dd0 <sys_write>:

uint64
sys_write(void)
{
    80005dd0:	7179                	addi	sp,sp,-48
    80005dd2:	f406                	sd	ra,40(sp)
    80005dd4:	f022                	sd	s0,32(sp)
    80005dd6:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dd8:	fe840613          	addi	a2,s0,-24
    80005ddc:	4581                	li	a1,0
    80005dde:	4501                	li	a0,0
    80005de0:	00000097          	auipc	ra,0x0
    80005de4:	e92080e7          	jalr	-366(ra) # 80005c72 <argfd>
    return -1;
    80005de8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dea:	04054163          	bltz	a0,80005e2c <sys_write+0x5c>
    80005dee:	fe440593          	addi	a1,s0,-28
    80005df2:	4509                	li	a0,2
    80005df4:	ffffd097          	auipc	ra,0xffffd
    80005df8:	568080e7          	jalr	1384(ra) # 8000335c <argint>
    return -1;
    80005dfc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005dfe:	02054763          	bltz	a0,80005e2c <sys_write+0x5c>
    80005e02:	fd840593          	addi	a1,s0,-40
    80005e06:	4505                	li	a0,1
    80005e08:	ffffd097          	auipc	ra,0xffffd
    80005e0c:	576080e7          	jalr	1398(ra) # 8000337e <argaddr>
    return -1;
    80005e10:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005e12:	00054d63          	bltz	a0,80005e2c <sys_write+0x5c>

  return filewrite(f, p, n);
    80005e16:	fe442603          	lw	a2,-28(s0)
    80005e1a:	fd843583          	ld	a1,-40(s0)
    80005e1e:	fe843503          	ld	a0,-24(s0)
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	45c080e7          	jalr	1116(ra) # 8000527e <filewrite>
    80005e2a:	87aa                	mv	a5,a0
}
    80005e2c:	853e                	mv	a0,a5
    80005e2e:	70a2                	ld	ra,40(sp)
    80005e30:	7402                	ld	s0,32(sp)
    80005e32:	6145                	addi	sp,sp,48
    80005e34:	8082                	ret

0000000080005e36 <sys_close>:

uint64
sys_close(void)
{
    80005e36:	1101                	addi	sp,sp,-32
    80005e38:	ec06                	sd	ra,24(sp)
    80005e3a:	e822                	sd	s0,16(sp)
    80005e3c:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005e3e:	fe040613          	addi	a2,s0,-32
    80005e42:	fec40593          	addi	a1,s0,-20
    80005e46:	4501                	li	a0,0
    80005e48:	00000097          	auipc	ra,0x0
    80005e4c:	e2a080e7          	jalr	-470(ra) # 80005c72 <argfd>
    return -1;
    80005e50:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005e52:	02054463          	bltz	a0,80005e7a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005e56:	ffffc097          	auipc	ra,0xffffc
    80005e5a:	222080e7          	jalr	546(ra) # 80002078 <myproc>
    80005e5e:	fec42783          	lw	a5,-20(s0)
    80005e62:	07e9                	addi	a5,a5,26
    80005e64:	078e                	slli	a5,a5,0x3
    80005e66:	97aa                	add	a5,a5,a0
    80005e68:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005e6c:	fe043503          	ld	a0,-32(s0)
    80005e70:	fffff097          	auipc	ra,0xfffff
    80005e74:	212080e7          	jalr	530(ra) # 80005082 <fileclose>
  return 0;
    80005e78:	4781                	li	a5,0
}
    80005e7a:	853e                	mv	a0,a5
    80005e7c:	60e2                	ld	ra,24(sp)
    80005e7e:	6442                	ld	s0,16(sp)
    80005e80:	6105                	addi	sp,sp,32
    80005e82:	8082                	ret

0000000080005e84 <sys_fstat>:

uint64
sys_fstat(void)
{
    80005e84:	1101                	addi	sp,sp,-32
    80005e86:	ec06                	sd	ra,24(sp)
    80005e88:	e822                	sd	s0,16(sp)
    80005e8a:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e8c:	fe840613          	addi	a2,s0,-24
    80005e90:	4581                	li	a1,0
    80005e92:	4501                	li	a0,0
    80005e94:	00000097          	auipc	ra,0x0
    80005e98:	dde080e7          	jalr	-546(ra) # 80005c72 <argfd>
    return -1;
    80005e9c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005e9e:	02054563          	bltz	a0,80005ec8 <sys_fstat+0x44>
    80005ea2:	fe040593          	addi	a1,s0,-32
    80005ea6:	4505                	li	a0,1
    80005ea8:	ffffd097          	auipc	ra,0xffffd
    80005eac:	4d6080e7          	jalr	1238(ra) # 8000337e <argaddr>
    return -1;
    80005eb0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005eb2:	00054b63          	bltz	a0,80005ec8 <sys_fstat+0x44>
  return filestat(f, st);
    80005eb6:	fe043583          	ld	a1,-32(s0)
    80005eba:	fe843503          	ld	a0,-24(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	28c080e7          	jalr	652(ra) # 8000514a <filestat>
    80005ec6:	87aa                	mv	a5,a0
}
    80005ec8:	853e                	mv	a0,a5
    80005eca:	60e2                	ld	ra,24(sp)
    80005ecc:	6442                	ld	s0,16(sp)
    80005ece:	6105                	addi	sp,sp,32
    80005ed0:	8082                	ret

0000000080005ed2 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005ed2:	7169                	addi	sp,sp,-304
    80005ed4:	f606                	sd	ra,296(sp)
    80005ed6:	f222                	sd	s0,288(sp)
    80005ed8:	ee26                	sd	s1,280(sp)
    80005eda:	ea4a                	sd	s2,272(sp)
    80005edc:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ede:	08000613          	li	a2,128
    80005ee2:	ed040593          	addi	a1,s0,-304
    80005ee6:	4501                	li	a0,0
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	4b8080e7          	jalr	1208(ra) # 800033a0 <argstr>
    return -1;
    80005ef0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ef2:	10054e63          	bltz	a0,8000600e <sys_link+0x13c>
    80005ef6:	08000613          	li	a2,128
    80005efa:	f5040593          	addi	a1,s0,-176
    80005efe:	4505                	li	a0,1
    80005f00:	ffffd097          	auipc	ra,0xffffd
    80005f04:	4a0080e7          	jalr	1184(ra) # 800033a0 <argstr>
    return -1;
    80005f08:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005f0a:	10054263          	bltz	a0,8000600e <sys_link+0x13c>

  begin_op();
    80005f0e:	fffff097          	auipc	ra,0xfffff
    80005f12:	ca8080e7          	jalr	-856(ra) # 80004bb6 <begin_op>
  if((ip = namei(old)) == 0){
    80005f16:	ed040513          	addi	a0,s0,-304
    80005f1a:	ffffe097          	auipc	ra,0xffffe
    80005f1e:	76a080e7          	jalr	1898(ra) # 80004684 <namei>
    80005f22:	84aa                	mv	s1,a0
    80005f24:	c551                	beqz	a0,80005fb0 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005f26:	ffffe097          	auipc	ra,0xffffe
    80005f2a:	fa8080e7          	jalr	-88(ra) # 80003ece <ilock>
  if(ip->type == T_DIR){
    80005f2e:	04449703          	lh	a4,68(s1)
    80005f32:	4785                	li	a5,1
    80005f34:	08f70463          	beq	a4,a5,80005fbc <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005f38:	04a4d783          	lhu	a5,74(s1)
    80005f3c:	2785                	addiw	a5,a5,1
    80005f3e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f42:	8526                	mv	a0,s1
    80005f44:	ffffe097          	auipc	ra,0xffffe
    80005f48:	ec0080e7          	jalr	-320(ra) # 80003e04 <iupdate>
  iunlock(ip);
    80005f4c:	8526                	mv	a0,s1
    80005f4e:	ffffe097          	auipc	ra,0xffffe
    80005f52:	042080e7          	jalr	66(ra) # 80003f90 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005f56:	fd040593          	addi	a1,s0,-48
    80005f5a:	f5040513          	addi	a0,s0,-176
    80005f5e:	ffffe097          	auipc	ra,0xffffe
    80005f62:	744080e7          	jalr	1860(ra) # 800046a2 <nameiparent>
    80005f66:	892a                	mv	s2,a0
    80005f68:	c935                	beqz	a0,80005fdc <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	f64080e7          	jalr	-156(ra) # 80003ece <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005f72:	00092703          	lw	a4,0(s2)
    80005f76:	409c                	lw	a5,0(s1)
    80005f78:	04f71d63          	bne	a4,a5,80005fd2 <sys_link+0x100>
    80005f7c:	40d0                	lw	a2,4(s1)
    80005f7e:	fd040593          	addi	a1,s0,-48
    80005f82:	854a                	mv	a0,s2
    80005f84:	ffffe097          	auipc	ra,0xffffe
    80005f88:	63e080e7          	jalr	1598(ra) # 800045c2 <dirlink>
    80005f8c:	04054363          	bltz	a0,80005fd2 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005f90:	854a                	mv	a0,s2
    80005f92:	ffffe097          	auipc	ra,0xffffe
    80005f96:	19e080e7          	jalr	414(ra) # 80004130 <iunlockput>
  iput(ip);
    80005f9a:	8526                	mv	a0,s1
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	0ec080e7          	jalr	236(ra) # 80004088 <iput>

  end_op();
    80005fa4:	fffff097          	auipc	ra,0xfffff
    80005fa8:	c92080e7          	jalr	-878(ra) # 80004c36 <end_op>

  return 0;
    80005fac:	4781                	li	a5,0
    80005fae:	a085                	j	8000600e <sys_link+0x13c>
    end_op();
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	c86080e7          	jalr	-890(ra) # 80004c36 <end_op>
    return -1;
    80005fb8:	57fd                	li	a5,-1
    80005fba:	a891                	j	8000600e <sys_link+0x13c>
    iunlockput(ip);
    80005fbc:	8526                	mv	a0,s1
    80005fbe:	ffffe097          	auipc	ra,0xffffe
    80005fc2:	172080e7          	jalr	370(ra) # 80004130 <iunlockput>
    end_op();
    80005fc6:	fffff097          	auipc	ra,0xfffff
    80005fca:	c70080e7          	jalr	-912(ra) # 80004c36 <end_op>
    return -1;
    80005fce:	57fd                	li	a5,-1
    80005fd0:	a83d                	j	8000600e <sys_link+0x13c>
    iunlockput(dp);
    80005fd2:	854a                	mv	a0,s2
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	15c080e7          	jalr	348(ra) # 80004130 <iunlockput>

bad:
  ilock(ip);
    80005fdc:	8526                	mv	a0,s1
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	ef0080e7          	jalr	-272(ra) # 80003ece <ilock>
  ip->nlink--;
    80005fe6:	04a4d783          	lhu	a5,74(s1)
    80005fea:	37fd                	addiw	a5,a5,-1
    80005fec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ff0:	8526                	mv	a0,s1
    80005ff2:	ffffe097          	auipc	ra,0xffffe
    80005ff6:	e12080e7          	jalr	-494(ra) # 80003e04 <iupdate>
  iunlockput(ip);
    80005ffa:	8526                	mv	a0,s1
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	134080e7          	jalr	308(ra) # 80004130 <iunlockput>
  end_op();
    80006004:	fffff097          	auipc	ra,0xfffff
    80006008:	c32080e7          	jalr	-974(ra) # 80004c36 <end_op>
  return -1;
    8000600c:	57fd                	li	a5,-1
}
    8000600e:	853e                	mv	a0,a5
    80006010:	70b2                	ld	ra,296(sp)
    80006012:	7412                	ld	s0,288(sp)
    80006014:	64f2                	ld	s1,280(sp)
    80006016:	6952                	ld	s2,272(sp)
    80006018:	6155                	addi	sp,sp,304
    8000601a:	8082                	ret

000000008000601c <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000601c:	4578                	lw	a4,76(a0)
    8000601e:	02000793          	li	a5,32
    80006022:	04e7fa63          	bgeu	a5,a4,80006076 <isdirempty+0x5a>
{
    80006026:	7179                	addi	sp,sp,-48
    80006028:	f406                	sd	ra,40(sp)
    8000602a:	f022                	sd	s0,32(sp)
    8000602c:	ec26                	sd	s1,24(sp)
    8000602e:	e84a                	sd	s2,16(sp)
    80006030:	1800                	addi	s0,sp,48
    80006032:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006034:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006038:	4741                	li	a4,16
    8000603a:	86a6                	mv	a3,s1
    8000603c:	fd040613          	addi	a2,s0,-48
    80006040:	4581                	li	a1,0
    80006042:	854a                	mv	a0,s2
    80006044:	ffffe097          	auipc	ra,0xffffe
    80006048:	13e080e7          	jalr	318(ra) # 80004182 <readi>
    8000604c:	47c1                	li	a5,16
    8000604e:	00f51c63          	bne	a0,a5,80006066 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80006052:	fd045783          	lhu	a5,-48(s0)
    80006056:	e395                	bnez	a5,8000607a <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006058:	24c1                	addiw	s1,s1,16
    8000605a:	04c92783          	lw	a5,76(s2)
    8000605e:	fcf4ede3          	bltu	s1,a5,80006038 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006062:	4505                	li	a0,1
    80006064:	a821                	j	8000607c <isdirempty+0x60>
      panic("isdirempty: readi");
    80006066:	00003517          	auipc	a0,0x3
    8000606a:	83a50513          	addi	a0,a0,-1990 # 800088a0 <syscalls+0x310>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4bc080e7          	jalr	1212(ra) # 8000052a <panic>
  return 1;
    80006076:	4505                	li	a0,1
}
    80006078:	8082                	ret
      return 0;
    8000607a:	4501                	li	a0,0
}
    8000607c:	70a2                	ld	ra,40(sp)
    8000607e:	7402                	ld	s0,32(sp)
    80006080:	64e2                	ld	s1,24(sp)
    80006082:	6942                	ld	s2,16(sp)
    80006084:	6145                	addi	sp,sp,48
    80006086:	8082                	ret

0000000080006088 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006088:	7155                	addi	sp,sp,-208
    8000608a:	e586                	sd	ra,200(sp)
    8000608c:	e1a2                	sd	s0,192(sp)
    8000608e:	fd26                	sd	s1,184(sp)
    80006090:	f94a                	sd	s2,176(sp)
    80006092:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006094:	08000613          	li	a2,128
    80006098:	f4040593          	addi	a1,s0,-192
    8000609c:	4501                	li	a0,0
    8000609e:	ffffd097          	auipc	ra,0xffffd
    800060a2:	302080e7          	jalr	770(ra) # 800033a0 <argstr>
    800060a6:	16054363          	bltz	a0,8000620c <sys_unlink+0x184>
    return -1;

  begin_op();
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	b0c080e7          	jalr	-1268(ra) # 80004bb6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800060b2:	fc040593          	addi	a1,s0,-64
    800060b6:	f4040513          	addi	a0,s0,-192
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	5e8080e7          	jalr	1512(ra) # 800046a2 <nameiparent>
    800060c2:	84aa                	mv	s1,a0
    800060c4:	c961                	beqz	a0,80006194 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	e08080e7          	jalr	-504(ra) # 80003ece <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800060ce:	00002597          	auipc	a1,0x2
    800060d2:	6b258593          	addi	a1,a1,1714 # 80008780 <syscalls+0x1f0>
    800060d6:	fc040513          	addi	a0,s0,-64
    800060da:	ffffe097          	auipc	ra,0xffffe
    800060de:	2be080e7          	jalr	702(ra) # 80004398 <namecmp>
    800060e2:	c175                	beqz	a0,800061c6 <sys_unlink+0x13e>
    800060e4:	00002597          	auipc	a1,0x2
    800060e8:	6a458593          	addi	a1,a1,1700 # 80008788 <syscalls+0x1f8>
    800060ec:	fc040513          	addi	a0,s0,-64
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	2a8080e7          	jalr	680(ra) # 80004398 <namecmp>
    800060f8:	c579                	beqz	a0,800061c6 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800060fa:	f3c40613          	addi	a2,s0,-196
    800060fe:	fc040593          	addi	a1,s0,-64
    80006102:	8526                	mv	a0,s1
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	2ae080e7          	jalr	686(ra) # 800043b2 <dirlookup>
    8000610c:	892a                	mv	s2,a0
    8000610e:	cd45                	beqz	a0,800061c6 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	dbe080e7          	jalr	-578(ra) # 80003ece <ilock>

  if(ip->nlink < 1)
    80006118:	04a91783          	lh	a5,74(s2)
    8000611c:	08f05263          	blez	a5,800061a0 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006120:	04491703          	lh	a4,68(s2)
    80006124:	4785                	li	a5,1
    80006126:	08f70563          	beq	a4,a5,800061b0 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    8000612a:	4641                	li	a2,16
    8000612c:	4581                	li	a1,0
    8000612e:	fd040513          	addi	a0,s0,-48
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	b9c080e7          	jalr	-1124(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000613a:	4741                	li	a4,16
    8000613c:	f3c42683          	lw	a3,-196(s0)
    80006140:	fd040613          	addi	a2,s0,-48
    80006144:	4581                	li	a1,0
    80006146:	8526                	mv	a0,s1
    80006148:	ffffe097          	auipc	ra,0xffffe
    8000614c:	132080e7          	jalr	306(ra) # 8000427a <writei>
    80006150:	47c1                	li	a5,16
    80006152:	08f51a63          	bne	a0,a5,800061e6 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006156:	04491703          	lh	a4,68(s2)
    8000615a:	4785                	li	a5,1
    8000615c:	08f70d63          	beq	a4,a5,800061f6 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80006160:	8526                	mv	a0,s1
    80006162:	ffffe097          	auipc	ra,0xffffe
    80006166:	fce080e7          	jalr	-50(ra) # 80004130 <iunlockput>

  ip->nlink--;
    8000616a:	04a95783          	lhu	a5,74(s2)
    8000616e:	37fd                	addiw	a5,a5,-1
    80006170:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006174:	854a                	mv	a0,s2
    80006176:	ffffe097          	auipc	ra,0xffffe
    8000617a:	c8e080e7          	jalr	-882(ra) # 80003e04 <iupdate>
  iunlockput(ip);
    8000617e:	854a                	mv	a0,s2
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	fb0080e7          	jalr	-80(ra) # 80004130 <iunlockput>

  end_op();
    80006188:	fffff097          	auipc	ra,0xfffff
    8000618c:	aae080e7          	jalr	-1362(ra) # 80004c36 <end_op>

  return 0;
    80006190:	4501                	li	a0,0
    80006192:	a0a1                	j	800061da <sys_unlink+0x152>
    end_op();
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	aa2080e7          	jalr	-1374(ra) # 80004c36 <end_op>
    return -1;
    8000619c:	557d                	li	a0,-1
    8000619e:	a835                	j	800061da <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    800061a0:	00002517          	auipc	a0,0x2
    800061a4:	5f050513          	addi	a0,a0,1520 # 80008790 <syscalls+0x200>
    800061a8:	ffffa097          	auipc	ra,0xffffa
    800061ac:	382080e7          	jalr	898(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800061b0:	854a                	mv	a0,s2
    800061b2:	00000097          	auipc	ra,0x0
    800061b6:	e6a080e7          	jalr	-406(ra) # 8000601c <isdirempty>
    800061ba:	f925                	bnez	a0,8000612a <sys_unlink+0xa2>
    iunlockput(ip);
    800061bc:	854a                	mv	a0,s2
    800061be:	ffffe097          	auipc	ra,0xffffe
    800061c2:	f72080e7          	jalr	-142(ra) # 80004130 <iunlockput>

bad:
  iunlockput(dp);
    800061c6:	8526                	mv	a0,s1
    800061c8:	ffffe097          	auipc	ra,0xffffe
    800061cc:	f68080e7          	jalr	-152(ra) # 80004130 <iunlockput>
  end_op();
    800061d0:	fffff097          	auipc	ra,0xfffff
    800061d4:	a66080e7          	jalr	-1434(ra) # 80004c36 <end_op>
  return -1;
    800061d8:	557d                	li	a0,-1
}
    800061da:	60ae                	ld	ra,200(sp)
    800061dc:	640e                	ld	s0,192(sp)
    800061de:	74ea                	ld	s1,184(sp)
    800061e0:	794a                	ld	s2,176(sp)
    800061e2:	6169                	addi	sp,sp,208
    800061e4:	8082                	ret
    panic("unlink: writei");
    800061e6:	00002517          	auipc	a0,0x2
    800061ea:	5c250513          	addi	a0,a0,1474 # 800087a8 <syscalls+0x218>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	33c080e7          	jalr	828(ra) # 8000052a <panic>
    dp->nlink--;
    800061f6:	04a4d783          	lhu	a5,74(s1)
    800061fa:	37fd                	addiw	a5,a5,-1
    800061fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006200:	8526                	mv	a0,s1
    80006202:	ffffe097          	auipc	ra,0xffffe
    80006206:	c02080e7          	jalr	-1022(ra) # 80003e04 <iupdate>
    8000620a:	bf99                	j	80006160 <sys_unlink+0xd8>
    return -1;
    8000620c:	557d                	li	a0,-1
    8000620e:	b7f1                	j	800061da <sys_unlink+0x152>

0000000080006210 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006210:	715d                	addi	sp,sp,-80
    80006212:	e486                	sd	ra,72(sp)
    80006214:	e0a2                	sd	s0,64(sp)
    80006216:	fc26                	sd	s1,56(sp)
    80006218:	f84a                	sd	s2,48(sp)
    8000621a:	f44e                	sd	s3,40(sp)
    8000621c:	f052                	sd	s4,32(sp)
    8000621e:	ec56                	sd	s5,24(sp)
    80006220:	0880                	addi	s0,sp,80
    80006222:	89ae                	mv	s3,a1
    80006224:	8ab2                	mv	s5,a2
    80006226:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006228:	fb040593          	addi	a1,s0,-80
    8000622c:	ffffe097          	auipc	ra,0xffffe
    80006230:	476080e7          	jalr	1142(ra) # 800046a2 <nameiparent>
    80006234:	892a                	mv	s2,a0
    80006236:	12050e63          	beqz	a0,80006372 <create+0x162>
    return 0;

  ilock(dp);
    8000623a:	ffffe097          	auipc	ra,0xffffe
    8000623e:	c94080e7          	jalr	-876(ra) # 80003ece <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006242:	4601                	li	a2,0
    80006244:	fb040593          	addi	a1,s0,-80
    80006248:	854a                	mv	a0,s2
    8000624a:	ffffe097          	auipc	ra,0xffffe
    8000624e:	168080e7          	jalr	360(ra) # 800043b2 <dirlookup>
    80006252:	84aa                	mv	s1,a0
    80006254:	c921                	beqz	a0,800062a4 <create+0x94>
    iunlockput(dp);
    80006256:	854a                	mv	a0,s2
    80006258:	ffffe097          	auipc	ra,0xffffe
    8000625c:	ed8080e7          	jalr	-296(ra) # 80004130 <iunlockput>
    ilock(ip);
    80006260:	8526                	mv	a0,s1
    80006262:	ffffe097          	auipc	ra,0xffffe
    80006266:	c6c080e7          	jalr	-916(ra) # 80003ece <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000626a:	2981                	sext.w	s3,s3
    8000626c:	4789                	li	a5,2
    8000626e:	02f99463          	bne	s3,a5,80006296 <create+0x86>
    80006272:	0444d783          	lhu	a5,68(s1)
    80006276:	37f9                	addiw	a5,a5,-2
    80006278:	17c2                	slli	a5,a5,0x30
    8000627a:	93c1                	srli	a5,a5,0x30
    8000627c:	4705                	li	a4,1
    8000627e:	00f76c63          	bltu	a4,a5,80006296 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006282:	8526                	mv	a0,s1
    80006284:	60a6                	ld	ra,72(sp)
    80006286:	6406                	ld	s0,64(sp)
    80006288:	74e2                	ld	s1,56(sp)
    8000628a:	7942                	ld	s2,48(sp)
    8000628c:	79a2                	ld	s3,40(sp)
    8000628e:	7a02                	ld	s4,32(sp)
    80006290:	6ae2                	ld	s5,24(sp)
    80006292:	6161                	addi	sp,sp,80
    80006294:	8082                	ret
    iunlockput(ip);
    80006296:	8526                	mv	a0,s1
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	e98080e7          	jalr	-360(ra) # 80004130 <iunlockput>
    return 0;
    800062a0:	4481                	li	s1,0
    800062a2:	b7c5                	j	80006282 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800062a4:	85ce                	mv	a1,s3
    800062a6:	00092503          	lw	a0,0(s2)
    800062aa:	ffffe097          	auipc	ra,0xffffe
    800062ae:	a8c080e7          	jalr	-1396(ra) # 80003d36 <ialloc>
    800062b2:	84aa                	mv	s1,a0
    800062b4:	c521                	beqz	a0,800062fc <create+0xec>
  ilock(ip);
    800062b6:	ffffe097          	auipc	ra,0xffffe
    800062ba:	c18080e7          	jalr	-1000(ra) # 80003ece <ilock>
  ip->major = major;
    800062be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800062c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800062c6:	4a05                	li	s4,1
    800062c8:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800062cc:	8526                	mv	a0,s1
    800062ce:	ffffe097          	auipc	ra,0xffffe
    800062d2:	b36080e7          	jalr	-1226(ra) # 80003e04 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800062d6:	2981                	sext.w	s3,s3
    800062d8:	03498a63          	beq	s3,s4,8000630c <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800062dc:	40d0                	lw	a2,4(s1)
    800062de:	fb040593          	addi	a1,s0,-80
    800062e2:	854a                	mv	a0,s2
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	2de080e7          	jalr	734(ra) # 800045c2 <dirlink>
    800062ec:	06054b63          	bltz	a0,80006362 <create+0x152>
  iunlockput(dp);
    800062f0:	854a                	mv	a0,s2
    800062f2:	ffffe097          	auipc	ra,0xffffe
    800062f6:	e3e080e7          	jalr	-450(ra) # 80004130 <iunlockput>
  return ip;
    800062fa:	b761                	j	80006282 <create+0x72>
    panic("create: ialloc");
    800062fc:	00002517          	auipc	a0,0x2
    80006300:	5bc50513          	addi	a0,a0,1468 # 800088b8 <syscalls+0x328>
    80006304:	ffffa097          	auipc	ra,0xffffa
    80006308:	226080e7          	jalr	550(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000630c:	04a95783          	lhu	a5,74(s2)
    80006310:	2785                	addiw	a5,a5,1
    80006312:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006316:	854a                	mv	a0,s2
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	aec080e7          	jalr	-1300(ra) # 80003e04 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006320:	40d0                	lw	a2,4(s1)
    80006322:	00002597          	auipc	a1,0x2
    80006326:	45e58593          	addi	a1,a1,1118 # 80008780 <syscalls+0x1f0>
    8000632a:	8526                	mv	a0,s1
    8000632c:	ffffe097          	auipc	ra,0xffffe
    80006330:	296080e7          	jalr	662(ra) # 800045c2 <dirlink>
    80006334:	00054f63          	bltz	a0,80006352 <create+0x142>
    80006338:	00492603          	lw	a2,4(s2)
    8000633c:	00002597          	auipc	a1,0x2
    80006340:	44c58593          	addi	a1,a1,1100 # 80008788 <syscalls+0x1f8>
    80006344:	8526                	mv	a0,s1
    80006346:	ffffe097          	auipc	ra,0xffffe
    8000634a:	27c080e7          	jalr	636(ra) # 800045c2 <dirlink>
    8000634e:	f80557e3          	bgez	a0,800062dc <create+0xcc>
      panic("create dots");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	57650513          	addi	a0,a0,1398 # 800088c8 <syscalls+0x338>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1d0080e7          	jalr	464(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	57650513          	addi	a0,a0,1398 # 800088d8 <syscalls+0x348>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1c0080e7          	jalr	448(ra) # 8000052a <panic>
    return 0;
    80006372:	84aa                	mv	s1,a0
    80006374:	b739                	j	80006282 <create+0x72>

0000000080006376 <sys_open>:

uint64
sys_open(void)
{
    80006376:	7131                	addi	sp,sp,-192
    80006378:	fd06                	sd	ra,184(sp)
    8000637a:	f922                	sd	s0,176(sp)
    8000637c:	f526                	sd	s1,168(sp)
    8000637e:	f14a                	sd	s2,160(sp)
    80006380:	ed4e                	sd	s3,152(sp)
    80006382:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006384:	08000613          	li	a2,128
    80006388:	f5040593          	addi	a1,s0,-176
    8000638c:	4501                	li	a0,0
    8000638e:	ffffd097          	auipc	ra,0xffffd
    80006392:	012080e7          	jalr	18(ra) # 800033a0 <argstr>
    return -1;
    80006396:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006398:	0c054163          	bltz	a0,8000645a <sys_open+0xe4>
    8000639c:	f4c40593          	addi	a1,s0,-180
    800063a0:	4505                	li	a0,1
    800063a2:	ffffd097          	auipc	ra,0xffffd
    800063a6:	fba080e7          	jalr	-70(ra) # 8000335c <argint>
    800063aa:	0a054863          	bltz	a0,8000645a <sys_open+0xe4>

  begin_op();
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	808080e7          	jalr	-2040(ra) # 80004bb6 <begin_op>

  if(omode & O_CREATE){
    800063b6:	f4c42783          	lw	a5,-180(s0)
    800063ba:	2007f793          	andi	a5,a5,512
    800063be:	cbdd                	beqz	a5,80006474 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800063c0:	4681                	li	a3,0
    800063c2:	4601                	li	a2,0
    800063c4:	4589                	li	a1,2
    800063c6:	f5040513          	addi	a0,s0,-176
    800063ca:	00000097          	auipc	ra,0x0
    800063ce:	e46080e7          	jalr	-442(ra) # 80006210 <create>
    800063d2:	892a                	mv	s2,a0
    if(ip == 0){
    800063d4:	c959                	beqz	a0,8000646a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800063d6:	04491703          	lh	a4,68(s2)
    800063da:	478d                	li	a5,3
    800063dc:	00f71763          	bne	a4,a5,800063ea <sys_open+0x74>
    800063e0:	04695703          	lhu	a4,70(s2)
    800063e4:	47a5                	li	a5,9
    800063e6:	0ce7ec63          	bltu	a5,a4,800064be <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800063ea:	fffff097          	auipc	ra,0xfffff
    800063ee:	bdc080e7          	jalr	-1060(ra) # 80004fc6 <filealloc>
    800063f2:	89aa                	mv	s3,a0
    800063f4:	10050263          	beqz	a0,800064f8 <sys_open+0x182>
    800063f8:	00000097          	auipc	ra,0x0
    800063fc:	8e2080e7          	jalr	-1822(ra) # 80005cda <fdalloc>
    80006400:	84aa                	mv	s1,a0
    80006402:	0e054663          	bltz	a0,800064ee <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006406:	04491703          	lh	a4,68(s2)
    8000640a:	478d                	li	a5,3
    8000640c:	0cf70463          	beq	a4,a5,800064d4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006410:	4789                	li	a5,2
    80006412:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006416:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000641a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000641e:	f4c42783          	lw	a5,-180(s0)
    80006422:	0017c713          	xori	a4,a5,1
    80006426:	8b05                	andi	a4,a4,1
    80006428:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000642c:	0037f713          	andi	a4,a5,3
    80006430:	00e03733          	snez	a4,a4
    80006434:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006438:	4007f793          	andi	a5,a5,1024
    8000643c:	c791                	beqz	a5,80006448 <sys_open+0xd2>
    8000643e:	04491703          	lh	a4,68(s2)
    80006442:	4789                	li	a5,2
    80006444:	08f70f63          	beq	a4,a5,800064e2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006448:	854a                	mv	a0,s2
    8000644a:	ffffe097          	auipc	ra,0xffffe
    8000644e:	b46080e7          	jalr	-1210(ra) # 80003f90 <iunlock>
  end_op();
    80006452:	ffffe097          	auipc	ra,0xffffe
    80006456:	7e4080e7          	jalr	2020(ra) # 80004c36 <end_op>

  return fd;
}
    8000645a:	8526                	mv	a0,s1
    8000645c:	70ea                	ld	ra,184(sp)
    8000645e:	744a                	ld	s0,176(sp)
    80006460:	74aa                	ld	s1,168(sp)
    80006462:	790a                	ld	s2,160(sp)
    80006464:	69ea                	ld	s3,152(sp)
    80006466:	6129                	addi	sp,sp,192
    80006468:	8082                	ret
      end_op();
    8000646a:	ffffe097          	auipc	ra,0xffffe
    8000646e:	7cc080e7          	jalr	1996(ra) # 80004c36 <end_op>
      return -1;
    80006472:	b7e5                	j	8000645a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006474:	f5040513          	addi	a0,s0,-176
    80006478:	ffffe097          	auipc	ra,0xffffe
    8000647c:	20c080e7          	jalr	524(ra) # 80004684 <namei>
    80006480:	892a                	mv	s2,a0
    80006482:	c905                	beqz	a0,800064b2 <sys_open+0x13c>
    ilock(ip);
    80006484:	ffffe097          	auipc	ra,0xffffe
    80006488:	a4a080e7          	jalr	-1462(ra) # 80003ece <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000648c:	04491703          	lh	a4,68(s2)
    80006490:	4785                	li	a5,1
    80006492:	f4f712e3          	bne	a4,a5,800063d6 <sys_open+0x60>
    80006496:	f4c42783          	lw	a5,-180(s0)
    8000649a:	dba1                	beqz	a5,800063ea <sys_open+0x74>
      iunlockput(ip);
    8000649c:	854a                	mv	a0,s2
    8000649e:	ffffe097          	auipc	ra,0xffffe
    800064a2:	c92080e7          	jalr	-878(ra) # 80004130 <iunlockput>
      end_op();
    800064a6:	ffffe097          	auipc	ra,0xffffe
    800064aa:	790080e7          	jalr	1936(ra) # 80004c36 <end_op>
      return -1;
    800064ae:	54fd                	li	s1,-1
    800064b0:	b76d                	j	8000645a <sys_open+0xe4>
      end_op();
    800064b2:	ffffe097          	auipc	ra,0xffffe
    800064b6:	784080e7          	jalr	1924(ra) # 80004c36 <end_op>
      return -1;
    800064ba:	54fd                	li	s1,-1
    800064bc:	bf79                	j	8000645a <sys_open+0xe4>
    iunlockput(ip);
    800064be:	854a                	mv	a0,s2
    800064c0:	ffffe097          	auipc	ra,0xffffe
    800064c4:	c70080e7          	jalr	-912(ra) # 80004130 <iunlockput>
    end_op();
    800064c8:	ffffe097          	auipc	ra,0xffffe
    800064cc:	76e080e7          	jalr	1902(ra) # 80004c36 <end_op>
    return -1;
    800064d0:	54fd                	li	s1,-1
    800064d2:	b761                	j	8000645a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800064d4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800064d8:	04691783          	lh	a5,70(s2)
    800064dc:	02f99223          	sh	a5,36(s3)
    800064e0:	bf2d                	j	8000641a <sys_open+0xa4>
    itrunc(ip);
    800064e2:	854a                	mv	a0,s2
    800064e4:	ffffe097          	auipc	ra,0xffffe
    800064e8:	af8080e7          	jalr	-1288(ra) # 80003fdc <itrunc>
    800064ec:	bfb1                	j	80006448 <sys_open+0xd2>
      fileclose(f);
    800064ee:	854e                	mv	a0,s3
    800064f0:	fffff097          	auipc	ra,0xfffff
    800064f4:	b92080e7          	jalr	-1134(ra) # 80005082 <fileclose>
    iunlockput(ip);
    800064f8:	854a                	mv	a0,s2
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	c36080e7          	jalr	-970(ra) # 80004130 <iunlockput>
    end_op();
    80006502:	ffffe097          	auipc	ra,0xffffe
    80006506:	734080e7          	jalr	1844(ra) # 80004c36 <end_op>
    return -1;
    8000650a:	54fd                	li	s1,-1
    8000650c:	b7b9                	j	8000645a <sys_open+0xe4>

000000008000650e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000650e:	7175                	addi	sp,sp,-144
    80006510:	e506                	sd	ra,136(sp)
    80006512:	e122                	sd	s0,128(sp)
    80006514:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006516:	ffffe097          	auipc	ra,0xffffe
    8000651a:	6a0080e7          	jalr	1696(ra) # 80004bb6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000651e:	08000613          	li	a2,128
    80006522:	f7040593          	addi	a1,s0,-144
    80006526:	4501                	li	a0,0
    80006528:	ffffd097          	auipc	ra,0xffffd
    8000652c:	e78080e7          	jalr	-392(ra) # 800033a0 <argstr>
    80006530:	02054963          	bltz	a0,80006562 <sys_mkdir+0x54>
    80006534:	4681                	li	a3,0
    80006536:	4601                	li	a2,0
    80006538:	4585                	li	a1,1
    8000653a:	f7040513          	addi	a0,s0,-144
    8000653e:	00000097          	auipc	ra,0x0
    80006542:	cd2080e7          	jalr	-814(ra) # 80006210 <create>
    80006546:	cd11                	beqz	a0,80006562 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006548:	ffffe097          	auipc	ra,0xffffe
    8000654c:	be8080e7          	jalr	-1048(ra) # 80004130 <iunlockput>
  end_op();
    80006550:	ffffe097          	auipc	ra,0xffffe
    80006554:	6e6080e7          	jalr	1766(ra) # 80004c36 <end_op>
  return 0;
    80006558:	4501                	li	a0,0
}
    8000655a:	60aa                	ld	ra,136(sp)
    8000655c:	640a                	ld	s0,128(sp)
    8000655e:	6149                	addi	sp,sp,144
    80006560:	8082                	ret
    end_op();
    80006562:	ffffe097          	auipc	ra,0xffffe
    80006566:	6d4080e7          	jalr	1748(ra) # 80004c36 <end_op>
    return -1;
    8000656a:	557d                	li	a0,-1
    8000656c:	b7fd                	j	8000655a <sys_mkdir+0x4c>

000000008000656e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000656e:	7135                	addi	sp,sp,-160
    80006570:	ed06                	sd	ra,152(sp)
    80006572:	e922                	sd	s0,144(sp)
    80006574:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006576:	ffffe097          	auipc	ra,0xffffe
    8000657a:	640080e7          	jalr	1600(ra) # 80004bb6 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000657e:	08000613          	li	a2,128
    80006582:	f7040593          	addi	a1,s0,-144
    80006586:	4501                	li	a0,0
    80006588:	ffffd097          	auipc	ra,0xffffd
    8000658c:	e18080e7          	jalr	-488(ra) # 800033a0 <argstr>
    80006590:	04054a63          	bltz	a0,800065e4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006594:	f6c40593          	addi	a1,s0,-148
    80006598:	4505                	li	a0,1
    8000659a:	ffffd097          	auipc	ra,0xffffd
    8000659e:	dc2080e7          	jalr	-574(ra) # 8000335c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800065a2:	04054163          	bltz	a0,800065e4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800065a6:	f6840593          	addi	a1,s0,-152
    800065aa:	4509                	li	a0,2
    800065ac:	ffffd097          	auipc	ra,0xffffd
    800065b0:	db0080e7          	jalr	-592(ra) # 8000335c <argint>
     argint(1, &major) < 0 ||
    800065b4:	02054863          	bltz	a0,800065e4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800065b8:	f6841683          	lh	a3,-152(s0)
    800065bc:	f6c41603          	lh	a2,-148(s0)
    800065c0:	458d                	li	a1,3
    800065c2:	f7040513          	addi	a0,s0,-144
    800065c6:	00000097          	auipc	ra,0x0
    800065ca:	c4a080e7          	jalr	-950(ra) # 80006210 <create>
     argint(2, &minor) < 0 ||
    800065ce:	c919                	beqz	a0,800065e4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800065d0:	ffffe097          	auipc	ra,0xffffe
    800065d4:	b60080e7          	jalr	-1184(ra) # 80004130 <iunlockput>
  end_op();
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	65e080e7          	jalr	1630(ra) # 80004c36 <end_op>
  return 0;
    800065e0:	4501                	li	a0,0
    800065e2:	a031                	j	800065ee <sys_mknod+0x80>
    end_op();
    800065e4:	ffffe097          	auipc	ra,0xffffe
    800065e8:	652080e7          	jalr	1618(ra) # 80004c36 <end_op>
    return -1;
    800065ec:	557d                	li	a0,-1
}
    800065ee:	60ea                	ld	ra,152(sp)
    800065f0:	644a                	ld	s0,144(sp)
    800065f2:	610d                	addi	sp,sp,160
    800065f4:	8082                	ret

00000000800065f6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800065f6:	7135                	addi	sp,sp,-160
    800065f8:	ed06                	sd	ra,152(sp)
    800065fa:	e922                	sd	s0,144(sp)
    800065fc:	e526                	sd	s1,136(sp)
    800065fe:	e14a                	sd	s2,128(sp)
    80006600:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006602:	ffffc097          	auipc	ra,0xffffc
    80006606:	a76080e7          	jalr	-1418(ra) # 80002078 <myproc>
    8000660a:	892a                	mv	s2,a0
  
  begin_op();
    8000660c:	ffffe097          	auipc	ra,0xffffe
    80006610:	5aa080e7          	jalr	1450(ra) # 80004bb6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006614:	08000613          	li	a2,128
    80006618:	f6040593          	addi	a1,s0,-160
    8000661c:	4501                	li	a0,0
    8000661e:	ffffd097          	auipc	ra,0xffffd
    80006622:	d82080e7          	jalr	-638(ra) # 800033a0 <argstr>
    80006626:	04054b63          	bltz	a0,8000667c <sys_chdir+0x86>
    8000662a:	f6040513          	addi	a0,s0,-160
    8000662e:	ffffe097          	auipc	ra,0xffffe
    80006632:	056080e7          	jalr	86(ra) # 80004684 <namei>
    80006636:	84aa                	mv	s1,a0
    80006638:	c131                	beqz	a0,8000667c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000663a:	ffffe097          	auipc	ra,0xffffe
    8000663e:	894080e7          	jalr	-1900(ra) # 80003ece <ilock>
  if(ip->type != T_DIR){
    80006642:	04449703          	lh	a4,68(s1)
    80006646:	4785                	li	a5,1
    80006648:	04f71063          	bne	a4,a5,80006688 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000664c:	8526                	mv	a0,s1
    8000664e:	ffffe097          	auipc	ra,0xffffe
    80006652:	942080e7          	jalr	-1726(ra) # 80003f90 <iunlock>
  iput(p->cwd);
    80006656:	15093503          	ld	a0,336(s2)
    8000665a:	ffffe097          	auipc	ra,0xffffe
    8000665e:	a2e080e7          	jalr	-1490(ra) # 80004088 <iput>
  end_op();
    80006662:	ffffe097          	auipc	ra,0xffffe
    80006666:	5d4080e7          	jalr	1492(ra) # 80004c36 <end_op>
  p->cwd = ip;
    8000666a:	14993823          	sd	s1,336(s2)
  return 0;
    8000666e:	4501                	li	a0,0
}
    80006670:	60ea                	ld	ra,152(sp)
    80006672:	644a                	ld	s0,144(sp)
    80006674:	64aa                	ld	s1,136(sp)
    80006676:	690a                	ld	s2,128(sp)
    80006678:	610d                	addi	sp,sp,160
    8000667a:	8082                	ret
    end_op();
    8000667c:	ffffe097          	auipc	ra,0xffffe
    80006680:	5ba080e7          	jalr	1466(ra) # 80004c36 <end_op>
    return -1;
    80006684:	557d                	li	a0,-1
    80006686:	b7ed                	j	80006670 <sys_chdir+0x7a>
    iunlockput(ip);
    80006688:	8526                	mv	a0,s1
    8000668a:	ffffe097          	auipc	ra,0xffffe
    8000668e:	aa6080e7          	jalr	-1370(ra) # 80004130 <iunlockput>
    end_op();
    80006692:	ffffe097          	auipc	ra,0xffffe
    80006696:	5a4080e7          	jalr	1444(ra) # 80004c36 <end_op>
    return -1;
    8000669a:	557d                	li	a0,-1
    8000669c:	bfd1                	j	80006670 <sys_chdir+0x7a>

000000008000669e <sys_exec>:

uint64
sys_exec(void)
{
    8000669e:	7145                	addi	sp,sp,-464
    800066a0:	e786                	sd	ra,456(sp)
    800066a2:	e3a2                	sd	s0,448(sp)
    800066a4:	ff26                	sd	s1,440(sp)
    800066a6:	fb4a                	sd	s2,432(sp)
    800066a8:	f74e                	sd	s3,424(sp)
    800066aa:	f352                	sd	s4,416(sp)
    800066ac:	ef56                	sd	s5,408(sp)
    800066ae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800066b0:	08000613          	li	a2,128
    800066b4:	f4040593          	addi	a1,s0,-192
    800066b8:	4501                	li	a0,0
    800066ba:	ffffd097          	auipc	ra,0xffffd
    800066be:	ce6080e7          	jalr	-794(ra) # 800033a0 <argstr>
    return -1;
    800066c2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800066c4:	0c054a63          	bltz	a0,80006798 <sys_exec+0xfa>
    800066c8:	e3840593          	addi	a1,s0,-456
    800066cc:	4505                	li	a0,1
    800066ce:	ffffd097          	auipc	ra,0xffffd
    800066d2:	cb0080e7          	jalr	-848(ra) # 8000337e <argaddr>
    800066d6:	0c054163          	bltz	a0,80006798 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800066da:	10000613          	li	a2,256
    800066de:	4581                	li	a1,0
    800066e0:	e4040513          	addi	a0,s0,-448
    800066e4:	ffffa097          	auipc	ra,0xffffa
    800066e8:	5ea080e7          	jalr	1514(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800066ec:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800066f0:	89a6                	mv	s3,s1
    800066f2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800066f4:	02000a13          	li	s4,32
    800066f8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800066fc:	00391793          	slli	a5,s2,0x3
    80006700:	e3040593          	addi	a1,s0,-464
    80006704:	e3843503          	ld	a0,-456(s0)
    80006708:	953e                	add	a0,a0,a5
    8000670a:	ffffd097          	auipc	ra,0xffffd
    8000670e:	bb8080e7          	jalr	-1096(ra) # 800032c2 <fetchaddr>
    80006712:	02054a63          	bltz	a0,80006746 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006716:	e3043783          	ld	a5,-464(s0)
    8000671a:	c3b9                	beqz	a5,80006760 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000671c:	ffffa097          	auipc	ra,0xffffa
    80006720:	3c6080e7          	jalr	966(ra) # 80000ae2 <kalloc>
    80006724:	85aa                	mv	a1,a0
    80006726:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000672a:	cd11                	beqz	a0,80006746 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000672c:	6605                	lui	a2,0x1
    8000672e:	e3043503          	ld	a0,-464(s0)
    80006732:	ffffd097          	auipc	ra,0xffffd
    80006736:	be2080e7          	jalr	-1054(ra) # 80003314 <fetchstr>
    8000673a:	00054663          	bltz	a0,80006746 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000673e:	0905                	addi	s2,s2,1
    80006740:	09a1                	addi	s3,s3,8
    80006742:	fb491be3          	bne	s2,s4,800066f8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006746:	10048913          	addi	s2,s1,256
    8000674a:	6088                	ld	a0,0(s1)
    8000674c:	c529                	beqz	a0,80006796 <sys_exec+0xf8>
    kfree(argv[i]);
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	288080e7          	jalr	648(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006756:	04a1                	addi	s1,s1,8
    80006758:	ff2499e3          	bne	s1,s2,8000674a <sys_exec+0xac>
  return -1;
    8000675c:	597d                	li	s2,-1
    8000675e:	a82d                	j	80006798 <sys_exec+0xfa>
      argv[i] = 0;
    80006760:	0a8e                	slli	s5,s5,0x3
    80006762:	fc040793          	addi	a5,s0,-64
    80006766:	9abe                	add	s5,s5,a5
    80006768:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd0e80>
  int ret = exec(path, argv);
    8000676c:	e4040593          	addi	a1,s0,-448
    80006770:	f4040513          	addi	a0,s0,-192
    80006774:	fffff097          	auipc	ra,0xfffff
    80006778:	156080e7          	jalr	342(ra) # 800058ca <exec>
    8000677c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000677e:	10048993          	addi	s3,s1,256
    80006782:	6088                	ld	a0,0(s1)
    80006784:	c911                	beqz	a0,80006798 <sys_exec+0xfa>
    kfree(argv[i]);
    80006786:	ffffa097          	auipc	ra,0xffffa
    8000678a:	250080e7          	jalr	592(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000678e:	04a1                	addi	s1,s1,8
    80006790:	ff3499e3          	bne	s1,s3,80006782 <sys_exec+0xe4>
    80006794:	a011                	j	80006798 <sys_exec+0xfa>
  return -1;
    80006796:	597d                	li	s2,-1
}
    80006798:	854a                	mv	a0,s2
    8000679a:	60be                	ld	ra,456(sp)
    8000679c:	641e                	ld	s0,448(sp)
    8000679e:	74fa                	ld	s1,440(sp)
    800067a0:	795a                	ld	s2,432(sp)
    800067a2:	79ba                	ld	s3,424(sp)
    800067a4:	7a1a                	ld	s4,416(sp)
    800067a6:	6afa                	ld	s5,408(sp)
    800067a8:	6179                	addi	sp,sp,464
    800067aa:	8082                	ret

00000000800067ac <sys_pipe>:

uint64
sys_pipe(void)
{
    800067ac:	7139                	addi	sp,sp,-64
    800067ae:	fc06                	sd	ra,56(sp)
    800067b0:	f822                	sd	s0,48(sp)
    800067b2:	f426                	sd	s1,40(sp)
    800067b4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800067b6:	ffffc097          	auipc	ra,0xffffc
    800067ba:	8c2080e7          	jalr	-1854(ra) # 80002078 <myproc>
    800067be:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800067c0:	fd840593          	addi	a1,s0,-40
    800067c4:	4501                	li	a0,0
    800067c6:	ffffd097          	auipc	ra,0xffffd
    800067ca:	bb8080e7          	jalr	-1096(ra) # 8000337e <argaddr>
    return -1;
    800067ce:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800067d0:	0e054063          	bltz	a0,800068b0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800067d4:	fc840593          	addi	a1,s0,-56
    800067d8:	fd040513          	addi	a0,s0,-48
    800067dc:	fffff097          	auipc	ra,0xfffff
    800067e0:	dcc080e7          	jalr	-564(ra) # 800055a8 <pipealloc>
    return -1;
    800067e4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800067e6:	0c054563          	bltz	a0,800068b0 <sys_pipe+0x104>
  fd0 = -1;
    800067ea:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800067ee:	fd043503          	ld	a0,-48(s0)
    800067f2:	fffff097          	auipc	ra,0xfffff
    800067f6:	4e8080e7          	jalr	1256(ra) # 80005cda <fdalloc>
    800067fa:	fca42223          	sw	a0,-60(s0)
    800067fe:	08054c63          	bltz	a0,80006896 <sys_pipe+0xea>
    80006802:	fc843503          	ld	a0,-56(s0)
    80006806:	fffff097          	auipc	ra,0xfffff
    8000680a:	4d4080e7          	jalr	1236(ra) # 80005cda <fdalloc>
    8000680e:	fca42023          	sw	a0,-64(s0)
    80006812:	06054863          	bltz	a0,80006882 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006816:	4691                	li	a3,4
    80006818:	fc440613          	addi	a2,s0,-60
    8000681c:	fd843583          	ld	a1,-40(s0)
    80006820:	68a8                	ld	a0,80(s1)
    80006822:	ffffb097          	auipc	ra,0xffffb
    80006826:	e2c080e7          	jalr	-468(ra) # 8000164e <copyout>
    8000682a:	02054063          	bltz	a0,8000684a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000682e:	4691                	li	a3,4
    80006830:	fc040613          	addi	a2,s0,-64
    80006834:	fd843583          	ld	a1,-40(s0)
    80006838:	0591                	addi	a1,a1,4
    8000683a:	68a8                	ld	a0,80(s1)
    8000683c:	ffffb097          	auipc	ra,0xffffb
    80006840:	e12080e7          	jalr	-494(ra) # 8000164e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006844:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006846:	06055563          	bgez	a0,800068b0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000684a:	fc442783          	lw	a5,-60(s0)
    8000684e:	07e9                	addi	a5,a5,26
    80006850:	078e                	slli	a5,a5,0x3
    80006852:	97a6                	add	a5,a5,s1
    80006854:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006858:	fc042503          	lw	a0,-64(s0)
    8000685c:	0569                	addi	a0,a0,26
    8000685e:	050e                	slli	a0,a0,0x3
    80006860:	9526                	add	a0,a0,s1
    80006862:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006866:	fd043503          	ld	a0,-48(s0)
    8000686a:	fffff097          	auipc	ra,0xfffff
    8000686e:	818080e7          	jalr	-2024(ra) # 80005082 <fileclose>
    fileclose(wf);
    80006872:	fc843503          	ld	a0,-56(s0)
    80006876:	fffff097          	auipc	ra,0xfffff
    8000687a:	80c080e7          	jalr	-2036(ra) # 80005082 <fileclose>
    return -1;
    8000687e:	57fd                	li	a5,-1
    80006880:	a805                	j	800068b0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006882:	fc442783          	lw	a5,-60(s0)
    80006886:	0007c863          	bltz	a5,80006896 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000688a:	01a78513          	addi	a0,a5,26
    8000688e:	050e                	slli	a0,a0,0x3
    80006890:	9526                	add	a0,a0,s1
    80006892:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006896:	fd043503          	ld	a0,-48(s0)
    8000689a:	ffffe097          	auipc	ra,0xffffe
    8000689e:	7e8080e7          	jalr	2024(ra) # 80005082 <fileclose>
    fileclose(wf);
    800068a2:	fc843503          	ld	a0,-56(s0)
    800068a6:	ffffe097          	auipc	ra,0xffffe
    800068aa:	7dc080e7          	jalr	2012(ra) # 80005082 <fileclose>
    return -1;
    800068ae:	57fd                	li	a5,-1
}
    800068b0:	853e                	mv	a0,a5
    800068b2:	70e2                	ld	ra,56(sp)
    800068b4:	7442                	ld	s0,48(sp)
    800068b6:	74a2                	ld	s1,40(sp)
    800068b8:	6121                	addi	sp,sp,64
    800068ba:	8082                	ret
    800068bc:	0000                	unimp
	...

00000000800068c0 <kernelvec>:
    800068c0:	7111                	addi	sp,sp,-256
    800068c2:	e006                	sd	ra,0(sp)
    800068c4:	e40a                	sd	sp,8(sp)
    800068c6:	e80e                	sd	gp,16(sp)
    800068c8:	ec12                	sd	tp,24(sp)
    800068ca:	f016                	sd	t0,32(sp)
    800068cc:	f41a                	sd	t1,40(sp)
    800068ce:	f81e                	sd	t2,48(sp)
    800068d0:	fc22                	sd	s0,56(sp)
    800068d2:	e0a6                	sd	s1,64(sp)
    800068d4:	e4aa                	sd	a0,72(sp)
    800068d6:	e8ae                	sd	a1,80(sp)
    800068d8:	ecb2                	sd	a2,88(sp)
    800068da:	f0b6                	sd	a3,96(sp)
    800068dc:	f4ba                	sd	a4,104(sp)
    800068de:	f8be                	sd	a5,112(sp)
    800068e0:	fcc2                	sd	a6,120(sp)
    800068e2:	e146                	sd	a7,128(sp)
    800068e4:	e54a                	sd	s2,136(sp)
    800068e6:	e94e                	sd	s3,144(sp)
    800068e8:	ed52                	sd	s4,152(sp)
    800068ea:	f156                	sd	s5,160(sp)
    800068ec:	f55a                	sd	s6,168(sp)
    800068ee:	f95e                	sd	s7,176(sp)
    800068f0:	fd62                	sd	s8,184(sp)
    800068f2:	e1e6                	sd	s9,192(sp)
    800068f4:	e5ea                	sd	s10,200(sp)
    800068f6:	e9ee                	sd	s11,208(sp)
    800068f8:	edf2                	sd	t3,216(sp)
    800068fa:	f1f6                	sd	t4,224(sp)
    800068fc:	f5fa                	sd	t5,232(sp)
    800068fe:	f9fe                	sd	t6,240(sp)
    80006900:	88ffc0ef          	jal	ra,8000318e <kerneltrap>
    80006904:	6082                	ld	ra,0(sp)
    80006906:	6122                	ld	sp,8(sp)
    80006908:	61c2                	ld	gp,16(sp)
    8000690a:	7282                	ld	t0,32(sp)
    8000690c:	7322                	ld	t1,40(sp)
    8000690e:	73c2                	ld	t2,48(sp)
    80006910:	7462                	ld	s0,56(sp)
    80006912:	6486                	ld	s1,64(sp)
    80006914:	6526                	ld	a0,72(sp)
    80006916:	65c6                	ld	a1,80(sp)
    80006918:	6666                	ld	a2,88(sp)
    8000691a:	7686                	ld	a3,96(sp)
    8000691c:	7726                	ld	a4,104(sp)
    8000691e:	77c6                	ld	a5,112(sp)
    80006920:	7866                	ld	a6,120(sp)
    80006922:	688a                	ld	a7,128(sp)
    80006924:	692a                	ld	s2,136(sp)
    80006926:	69ca                	ld	s3,144(sp)
    80006928:	6a6a                	ld	s4,152(sp)
    8000692a:	7a8a                	ld	s5,160(sp)
    8000692c:	7b2a                	ld	s6,168(sp)
    8000692e:	7bca                	ld	s7,176(sp)
    80006930:	7c6a                	ld	s8,184(sp)
    80006932:	6c8e                	ld	s9,192(sp)
    80006934:	6d2e                	ld	s10,200(sp)
    80006936:	6dce                	ld	s11,208(sp)
    80006938:	6e6e                	ld	t3,216(sp)
    8000693a:	7e8e                	ld	t4,224(sp)
    8000693c:	7f2e                	ld	t5,232(sp)
    8000693e:	7fce                	ld	t6,240(sp)
    80006940:	6111                	addi	sp,sp,256
    80006942:	10200073          	sret
    80006946:	00000013          	nop
    8000694a:	00000013          	nop
    8000694e:	0001                	nop

0000000080006950 <timervec>:
    80006950:	34051573          	csrrw	a0,mscratch,a0
    80006954:	e10c                	sd	a1,0(a0)
    80006956:	e510                	sd	a2,8(a0)
    80006958:	e914                	sd	a3,16(a0)
    8000695a:	6d0c                	ld	a1,24(a0)
    8000695c:	7110                	ld	a2,32(a0)
    8000695e:	6194                	ld	a3,0(a1)
    80006960:	96b2                	add	a3,a3,a2
    80006962:	e194                	sd	a3,0(a1)
    80006964:	4589                	li	a1,2
    80006966:	14459073          	csrw	sip,a1
    8000696a:	6914                	ld	a3,16(a0)
    8000696c:	6510                	ld	a2,8(a0)
    8000696e:	610c                	ld	a1,0(a0)
    80006970:	34051573          	csrrw	a0,mscratch,a0
    80006974:	30200073          	mret
	...

000000008000697a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000697a:	1141                	addi	sp,sp,-16
    8000697c:	e422                	sd	s0,8(sp)
    8000697e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006980:	0c0007b7          	lui	a5,0xc000
    80006984:	4705                	li	a4,1
    80006986:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006988:	c3d8                	sw	a4,4(a5)
}
    8000698a:	6422                	ld	s0,8(sp)
    8000698c:	0141                	addi	sp,sp,16
    8000698e:	8082                	ret

0000000080006990 <plicinithart>:

void
plicinithart(void)
{
    80006990:	1141                	addi	sp,sp,-16
    80006992:	e406                	sd	ra,8(sp)
    80006994:	e022                	sd	s0,0(sp)
    80006996:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006998:	ffffb097          	auipc	ra,0xffffb
    8000699c:	6b4080e7          	jalr	1716(ra) # 8000204c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800069a0:	0085171b          	slliw	a4,a0,0x8
    800069a4:	0c0027b7          	lui	a5,0xc002
    800069a8:	97ba                	add	a5,a5,a4
    800069aa:	40200713          	li	a4,1026
    800069ae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800069b2:	00d5151b          	slliw	a0,a0,0xd
    800069b6:	0c2017b7          	lui	a5,0xc201
    800069ba:	953e                	add	a0,a0,a5
    800069bc:	00052023          	sw	zero,0(a0)
}
    800069c0:	60a2                	ld	ra,8(sp)
    800069c2:	6402                	ld	s0,0(sp)
    800069c4:	0141                	addi	sp,sp,16
    800069c6:	8082                	ret

00000000800069c8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800069c8:	1141                	addi	sp,sp,-16
    800069ca:	e406                	sd	ra,8(sp)
    800069cc:	e022                	sd	s0,0(sp)
    800069ce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800069d0:	ffffb097          	auipc	ra,0xffffb
    800069d4:	67c080e7          	jalr	1660(ra) # 8000204c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800069d8:	00d5179b          	slliw	a5,a0,0xd
    800069dc:	0c201537          	lui	a0,0xc201
    800069e0:	953e                	add	a0,a0,a5
  return irq;
}
    800069e2:	4148                	lw	a0,4(a0)
    800069e4:	60a2                	ld	ra,8(sp)
    800069e6:	6402                	ld	s0,0(sp)
    800069e8:	0141                	addi	sp,sp,16
    800069ea:	8082                	ret

00000000800069ec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800069ec:	1101                	addi	sp,sp,-32
    800069ee:	ec06                	sd	ra,24(sp)
    800069f0:	e822                	sd	s0,16(sp)
    800069f2:	e426                	sd	s1,8(sp)
    800069f4:	1000                	addi	s0,sp,32
    800069f6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800069f8:	ffffb097          	auipc	ra,0xffffb
    800069fc:	654080e7          	jalr	1620(ra) # 8000204c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006a00:	00d5151b          	slliw	a0,a0,0xd
    80006a04:	0c2017b7          	lui	a5,0xc201
    80006a08:	97aa                	add	a5,a5,a0
    80006a0a:	c3c4                	sw	s1,4(a5)
}
    80006a0c:	60e2                	ld	ra,24(sp)
    80006a0e:	6442                	ld	s0,16(sp)
    80006a10:	64a2                	ld	s1,8(sp)
    80006a12:	6105                	addi	sp,sp,32
    80006a14:	8082                	ret

0000000080006a16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006a16:	1141                	addi	sp,sp,-16
    80006a18:	e406                	sd	ra,8(sp)
    80006a1a:	e022                	sd	s0,0(sp)
    80006a1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006a1e:	479d                	li	a5,7
    80006a20:	06a7c963          	blt	a5,a0,80006a92 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006a24:	00024797          	auipc	a5,0x24
    80006a28:	5dc78793          	addi	a5,a5,1500 # 8002b000 <disk>
    80006a2c:	00a78733          	add	a4,a5,a0
    80006a30:	6789                	lui	a5,0x2
    80006a32:	97ba                	add	a5,a5,a4
    80006a34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006a38:	e7ad                	bnez	a5,80006aa2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006a3a:	00451793          	slli	a5,a0,0x4
    80006a3e:	00026717          	auipc	a4,0x26
    80006a42:	5c270713          	addi	a4,a4,1474 # 8002d000 <disk+0x2000>
    80006a46:	6314                	ld	a3,0(a4)
    80006a48:	96be                	add	a3,a3,a5
    80006a4a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006a4e:	6314                	ld	a3,0(a4)
    80006a50:	96be                	add	a3,a3,a5
    80006a52:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006a56:	6314                	ld	a3,0(a4)
    80006a58:	96be                	add	a3,a3,a5
    80006a5a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006a5e:	6318                	ld	a4,0(a4)
    80006a60:	97ba                	add	a5,a5,a4
    80006a62:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006a66:	00024797          	auipc	a5,0x24
    80006a6a:	59a78793          	addi	a5,a5,1434 # 8002b000 <disk>
    80006a6e:	97aa                	add	a5,a5,a0
    80006a70:	6509                	lui	a0,0x2
    80006a72:	953e                	add	a0,a0,a5
    80006a74:	4785                	li	a5,1
    80006a76:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006a7a:	00026517          	auipc	a0,0x26
    80006a7e:	59e50513          	addi	a0,a0,1438 # 8002d018 <disk+0x2018>
    80006a82:	ffffc097          	auipc	ra,0xffffc
    80006a86:	040080e7          	jalr	64(ra) # 80002ac2 <wakeup>
}
    80006a8a:	60a2                	ld	ra,8(sp)
    80006a8c:	6402                	ld	s0,0(sp)
    80006a8e:	0141                	addi	sp,sp,16
    80006a90:	8082                	ret
    panic("free_desc 1");
    80006a92:	00002517          	auipc	a0,0x2
    80006a96:	e5650513          	addi	a0,a0,-426 # 800088e8 <syscalls+0x358>
    80006a9a:	ffffa097          	auipc	ra,0xffffa
    80006a9e:	a90080e7          	jalr	-1392(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006aa2:	00002517          	auipc	a0,0x2
    80006aa6:	e5650513          	addi	a0,a0,-426 # 800088f8 <syscalls+0x368>
    80006aaa:	ffffa097          	auipc	ra,0xffffa
    80006aae:	a80080e7          	jalr	-1408(ra) # 8000052a <panic>

0000000080006ab2 <virtio_disk_init>:
{
    80006ab2:	1101                	addi	sp,sp,-32
    80006ab4:	ec06                	sd	ra,24(sp)
    80006ab6:	e822                	sd	s0,16(sp)
    80006ab8:	e426                	sd	s1,8(sp)
    80006aba:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006abc:	00002597          	auipc	a1,0x2
    80006ac0:	e4c58593          	addi	a1,a1,-436 # 80008908 <syscalls+0x378>
    80006ac4:	00026517          	auipc	a0,0x26
    80006ac8:	66450513          	addi	a0,a0,1636 # 8002d128 <disk+0x2128>
    80006acc:	ffffa097          	auipc	ra,0xffffa
    80006ad0:	076080e7          	jalr	118(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ad4:	100017b7          	lui	a5,0x10001
    80006ad8:	4398                	lw	a4,0(a5)
    80006ada:	2701                	sext.w	a4,a4
    80006adc:	747277b7          	lui	a5,0x74727
    80006ae0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006ae4:	0ef71163          	bne	a4,a5,80006bc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ae8:	100017b7          	lui	a5,0x10001
    80006aec:	43dc                	lw	a5,4(a5)
    80006aee:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006af0:	4705                	li	a4,1
    80006af2:	0ce79a63          	bne	a5,a4,80006bc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006af6:	100017b7          	lui	a5,0x10001
    80006afa:	479c                	lw	a5,8(a5)
    80006afc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006afe:	4709                	li	a4,2
    80006b00:	0ce79363          	bne	a5,a4,80006bc6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006b04:	100017b7          	lui	a5,0x10001
    80006b08:	47d8                	lw	a4,12(a5)
    80006b0a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006b0c:	554d47b7          	lui	a5,0x554d4
    80006b10:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006b14:	0af71963          	bne	a4,a5,80006bc6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b18:	100017b7          	lui	a5,0x10001
    80006b1c:	4705                	li	a4,1
    80006b1e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b20:	470d                	li	a4,3
    80006b22:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006b24:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006b26:	c7ffe737          	lui	a4,0xc7ffe
    80006b2a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    80006b2e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006b30:	2701                	sext.w	a4,a4
    80006b32:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b34:	472d                	li	a4,11
    80006b36:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b38:	473d                	li	a4,15
    80006b3a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006b3c:	6705                	lui	a4,0x1
    80006b3e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006b40:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006b44:	5bdc                	lw	a5,52(a5)
    80006b46:	2781                	sext.w	a5,a5
  if(max == 0)
    80006b48:	c7d9                	beqz	a5,80006bd6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006b4a:	471d                	li	a4,7
    80006b4c:	08f77d63          	bgeu	a4,a5,80006be6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006b50:	100014b7          	lui	s1,0x10001
    80006b54:	47a1                	li	a5,8
    80006b56:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006b58:	6609                	lui	a2,0x2
    80006b5a:	4581                	li	a1,0
    80006b5c:	00024517          	auipc	a0,0x24
    80006b60:	4a450513          	addi	a0,a0,1188 # 8002b000 <disk>
    80006b64:	ffffa097          	auipc	ra,0xffffa
    80006b68:	16a080e7          	jalr	362(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006b6c:	00024717          	auipc	a4,0x24
    80006b70:	49470713          	addi	a4,a4,1172 # 8002b000 <disk>
    80006b74:	00c75793          	srli	a5,a4,0xc
    80006b78:	2781                	sext.w	a5,a5
    80006b7a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006b7c:	00026797          	auipc	a5,0x26
    80006b80:	48478793          	addi	a5,a5,1156 # 8002d000 <disk+0x2000>
    80006b84:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006b86:	00024717          	auipc	a4,0x24
    80006b8a:	4fa70713          	addi	a4,a4,1274 # 8002b080 <disk+0x80>
    80006b8e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006b90:	00025717          	auipc	a4,0x25
    80006b94:	47070713          	addi	a4,a4,1136 # 8002c000 <disk+0x1000>
    80006b98:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006b9a:	4705                	li	a4,1
    80006b9c:	00e78c23          	sb	a4,24(a5)
    80006ba0:	00e78ca3          	sb	a4,25(a5)
    80006ba4:	00e78d23          	sb	a4,26(a5)
    80006ba8:	00e78da3          	sb	a4,27(a5)
    80006bac:	00e78e23          	sb	a4,28(a5)
    80006bb0:	00e78ea3          	sb	a4,29(a5)
    80006bb4:	00e78f23          	sb	a4,30(a5)
    80006bb8:	00e78fa3          	sb	a4,31(a5)
}
    80006bbc:	60e2                	ld	ra,24(sp)
    80006bbe:	6442                	ld	s0,16(sp)
    80006bc0:	64a2                	ld	s1,8(sp)
    80006bc2:	6105                	addi	sp,sp,32
    80006bc4:	8082                	ret
    panic("could not find virtio disk");
    80006bc6:	00002517          	auipc	a0,0x2
    80006bca:	d5250513          	addi	a0,a0,-686 # 80008918 <syscalls+0x388>
    80006bce:	ffffa097          	auipc	ra,0xffffa
    80006bd2:	95c080e7          	jalr	-1700(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006bd6:	00002517          	auipc	a0,0x2
    80006bda:	d6250513          	addi	a0,a0,-670 # 80008938 <syscalls+0x3a8>
    80006bde:	ffffa097          	auipc	ra,0xffffa
    80006be2:	94c080e7          	jalr	-1716(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006be6:	00002517          	auipc	a0,0x2
    80006bea:	d7250513          	addi	a0,a0,-654 # 80008958 <syscalls+0x3c8>
    80006bee:	ffffa097          	auipc	ra,0xffffa
    80006bf2:	93c080e7          	jalr	-1732(ra) # 8000052a <panic>

0000000080006bf6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bf6:	7119                	addi	sp,sp,-128
    80006bf8:	fc86                	sd	ra,120(sp)
    80006bfa:	f8a2                	sd	s0,112(sp)
    80006bfc:	f4a6                	sd	s1,104(sp)
    80006bfe:	f0ca                	sd	s2,96(sp)
    80006c00:	ecce                	sd	s3,88(sp)
    80006c02:	e8d2                	sd	s4,80(sp)
    80006c04:	e4d6                	sd	s5,72(sp)
    80006c06:	e0da                	sd	s6,64(sp)
    80006c08:	fc5e                	sd	s7,56(sp)
    80006c0a:	f862                	sd	s8,48(sp)
    80006c0c:	f466                	sd	s9,40(sp)
    80006c0e:	f06a                	sd	s10,32(sp)
    80006c10:	ec6e                	sd	s11,24(sp)
    80006c12:	0100                	addi	s0,sp,128
    80006c14:	8aaa                	mv	s5,a0
    80006c16:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006c18:	00c52c83          	lw	s9,12(a0)
    80006c1c:	001c9c9b          	slliw	s9,s9,0x1
    80006c20:	1c82                	slli	s9,s9,0x20
    80006c22:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006c26:	00026517          	auipc	a0,0x26
    80006c2a:	50250513          	addi	a0,a0,1282 # 8002d128 <disk+0x2128>
    80006c2e:	ffffa097          	auipc	ra,0xffffa
    80006c32:	fa4080e7          	jalr	-92(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006c36:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c38:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006c3a:	00024c17          	auipc	s8,0x24
    80006c3e:	3c6c0c13          	addi	s8,s8,966 # 8002b000 <disk>
    80006c42:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006c44:	4b0d                	li	s6,3
    80006c46:	a0ad                	j	80006cb0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006c48:	00fc0733          	add	a4,s8,a5
    80006c4c:	975e                	add	a4,a4,s7
    80006c4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006c52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006c54:	0207c563          	bltz	a5,80006c7e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006c58:	2905                	addiw	s2,s2,1
    80006c5a:	0611                	addi	a2,a2,4
    80006c5c:	19690d63          	beq	s2,s6,80006df6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006c60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006c62:	00026717          	auipc	a4,0x26
    80006c66:	3b670713          	addi	a4,a4,950 # 8002d018 <disk+0x2018>
    80006c6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006c6c:	00074683          	lbu	a3,0(a4)
    80006c70:	fee1                	bnez	a3,80006c48 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006c72:	2785                	addiw	a5,a5,1
    80006c74:	0705                	addi	a4,a4,1
    80006c76:	fe979be3          	bne	a5,s1,80006c6c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006c7a:	57fd                	li	a5,-1
    80006c7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006c7e:	01205d63          	blez	s2,80006c98 <virtio_disk_rw+0xa2>
    80006c82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006c84:	000a2503          	lw	a0,0(s4)
    80006c88:	00000097          	auipc	ra,0x0
    80006c8c:	d8e080e7          	jalr	-626(ra) # 80006a16 <free_desc>
      for(int j = 0; j < i; j++)
    80006c90:	2d85                	addiw	s11,s11,1
    80006c92:	0a11                	addi	s4,s4,4
    80006c94:	ffb918e3          	bne	s2,s11,80006c84 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c98:	00026597          	auipc	a1,0x26
    80006c9c:	49058593          	addi	a1,a1,1168 # 8002d128 <disk+0x2128>
    80006ca0:	00026517          	auipc	a0,0x26
    80006ca4:	37850513          	addi	a0,a0,888 # 8002d018 <disk+0x2018>
    80006ca8:	ffffc097          	auipc	ra,0xffffc
    80006cac:	c8e080e7          	jalr	-882(ra) # 80002936 <sleep>
  for(int i = 0; i < 3; i++){
    80006cb0:	f8040a13          	addi	s4,s0,-128
{
    80006cb4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006cb6:	894e                	mv	s2,s3
    80006cb8:	b765                	j	80006c60 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006cba:	00026697          	auipc	a3,0x26
    80006cbe:	3466b683          	ld	a3,838(a3) # 8002d000 <disk+0x2000>
    80006cc2:	96ba                	add	a3,a3,a4
    80006cc4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006cc8:	00024817          	auipc	a6,0x24
    80006ccc:	33880813          	addi	a6,a6,824 # 8002b000 <disk>
    80006cd0:	00026697          	auipc	a3,0x26
    80006cd4:	33068693          	addi	a3,a3,816 # 8002d000 <disk+0x2000>
    80006cd8:	6290                	ld	a2,0(a3)
    80006cda:	963a                	add	a2,a2,a4
    80006cdc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006ce0:	0015e593          	ori	a1,a1,1
    80006ce4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006ce8:	f8842603          	lw	a2,-120(s0)
    80006cec:	628c                	ld	a1,0(a3)
    80006cee:	972e                	add	a4,a4,a1
    80006cf0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006cf4:	20050593          	addi	a1,a0,512
    80006cf8:	0592                	slli	a1,a1,0x4
    80006cfa:	95c2                	add	a1,a1,a6
    80006cfc:	577d                	li	a4,-1
    80006cfe:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d02:	00461713          	slli	a4,a2,0x4
    80006d06:	6290                	ld	a2,0(a3)
    80006d08:	963a                	add	a2,a2,a4
    80006d0a:	03078793          	addi	a5,a5,48
    80006d0e:	97c2                	add	a5,a5,a6
    80006d10:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006d12:	629c                	ld	a5,0(a3)
    80006d14:	97ba                	add	a5,a5,a4
    80006d16:	4605                	li	a2,1
    80006d18:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d1a:	629c                	ld	a5,0(a3)
    80006d1c:	97ba                	add	a5,a5,a4
    80006d1e:	4809                	li	a6,2
    80006d20:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006d24:	629c                	ld	a5,0(a3)
    80006d26:	973e                	add	a4,a4,a5
    80006d28:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d2c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006d30:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d34:	6698                	ld	a4,8(a3)
    80006d36:	00275783          	lhu	a5,2(a4)
    80006d3a:	8b9d                	andi	a5,a5,7
    80006d3c:	0786                	slli	a5,a5,0x1
    80006d3e:	97ba                	add	a5,a5,a4
    80006d40:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006d44:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d48:	6698                	ld	a4,8(a3)
    80006d4a:	00275783          	lhu	a5,2(a4)
    80006d4e:	2785                	addiw	a5,a5,1
    80006d50:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d54:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d58:	100017b7          	lui	a5,0x10001
    80006d5c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d60:	004aa783          	lw	a5,4(s5)
    80006d64:	02c79163          	bne	a5,a2,80006d86 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006d68:	00026917          	auipc	s2,0x26
    80006d6c:	3c090913          	addi	s2,s2,960 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    80006d70:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d72:	85ca                	mv	a1,s2
    80006d74:	8556                	mv	a0,s5
    80006d76:	ffffc097          	auipc	ra,0xffffc
    80006d7a:	bc0080e7          	jalr	-1088(ra) # 80002936 <sleep>
  while(b->disk == 1) {
    80006d7e:	004aa783          	lw	a5,4(s5)
    80006d82:	fe9788e3          	beq	a5,s1,80006d72 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006d86:	f8042903          	lw	s2,-128(s0)
    80006d8a:	20090793          	addi	a5,s2,512
    80006d8e:	00479713          	slli	a4,a5,0x4
    80006d92:	00024797          	auipc	a5,0x24
    80006d96:	26e78793          	addi	a5,a5,622 # 8002b000 <disk>
    80006d9a:	97ba                	add	a5,a5,a4
    80006d9c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006da0:	00026997          	auipc	s3,0x26
    80006da4:	26098993          	addi	s3,s3,608 # 8002d000 <disk+0x2000>
    80006da8:	00491713          	slli	a4,s2,0x4
    80006dac:	0009b783          	ld	a5,0(s3)
    80006db0:	97ba                	add	a5,a5,a4
    80006db2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006db6:	854a                	mv	a0,s2
    80006db8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006dbc:	00000097          	auipc	ra,0x0
    80006dc0:	c5a080e7          	jalr	-934(ra) # 80006a16 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006dc4:	8885                	andi	s1,s1,1
    80006dc6:	f0ed                	bnez	s1,80006da8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006dc8:	00026517          	auipc	a0,0x26
    80006dcc:	36050513          	addi	a0,a0,864 # 8002d128 <disk+0x2128>
    80006dd0:	ffffa097          	auipc	ra,0xffffa
    80006dd4:	eb6080e7          	jalr	-330(ra) # 80000c86 <release>
}
    80006dd8:	70e6                	ld	ra,120(sp)
    80006dda:	7446                	ld	s0,112(sp)
    80006ddc:	74a6                	ld	s1,104(sp)
    80006dde:	7906                	ld	s2,96(sp)
    80006de0:	69e6                	ld	s3,88(sp)
    80006de2:	6a46                	ld	s4,80(sp)
    80006de4:	6aa6                	ld	s5,72(sp)
    80006de6:	6b06                	ld	s6,64(sp)
    80006de8:	7be2                	ld	s7,56(sp)
    80006dea:	7c42                	ld	s8,48(sp)
    80006dec:	7ca2                	ld	s9,40(sp)
    80006dee:	7d02                	ld	s10,32(sp)
    80006df0:	6de2                	ld	s11,24(sp)
    80006df2:	6109                	addi	sp,sp,128
    80006df4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006df6:	f8042503          	lw	a0,-128(s0)
    80006dfa:	20050793          	addi	a5,a0,512
    80006dfe:	0792                	slli	a5,a5,0x4
  if(write)
    80006e00:	00024817          	auipc	a6,0x24
    80006e04:	20080813          	addi	a6,a6,512 # 8002b000 <disk>
    80006e08:	00f80733          	add	a4,a6,a5
    80006e0c:	01a036b3          	snez	a3,s10
    80006e10:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006e14:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006e18:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006e1c:	7679                	lui	a2,0xffffe
    80006e1e:	963e                	add	a2,a2,a5
    80006e20:	00026697          	auipc	a3,0x26
    80006e24:	1e068693          	addi	a3,a3,480 # 8002d000 <disk+0x2000>
    80006e28:	6298                	ld	a4,0(a3)
    80006e2a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e2c:	0a878593          	addi	a1,a5,168
    80006e30:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006e32:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006e34:	6298                	ld	a4,0(a3)
    80006e36:	9732                	add	a4,a4,a2
    80006e38:	45c1                	li	a1,16
    80006e3a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006e3c:	6298                	ld	a4,0(a3)
    80006e3e:	9732                	add	a4,a4,a2
    80006e40:	4585                	li	a1,1
    80006e42:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006e46:	f8442703          	lw	a4,-124(s0)
    80006e4a:	628c                	ld	a1,0(a3)
    80006e4c:	962e                	add	a2,a2,a1
    80006e4e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006e52:	0712                	slli	a4,a4,0x4
    80006e54:	6290                	ld	a2,0(a3)
    80006e56:	963a                	add	a2,a2,a4
    80006e58:	058a8593          	addi	a1,s5,88
    80006e5c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006e5e:	6294                	ld	a3,0(a3)
    80006e60:	96ba                	add	a3,a3,a4
    80006e62:	40000613          	li	a2,1024
    80006e66:	c690                	sw	a2,8(a3)
  if(write)
    80006e68:	e40d19e3          	bnez	s10,80006cba <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e6c:	00026697          	auipc	a3,0x26
    80006e70:	1946b683          	ld	a3,404(a3) # 8002d000 <disk+0x2000>
    80006e74:	96ba                	add	a3,a3,a4
    80006e76:	4609                	li	a2,2
    80006e78:	00c69623          	sh	a2,12(a3)
    80006e7c:	b5b1                	j	80006cc8 <virtio_disk_rw+0xd2>

0000000080006e7e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e7e:	1101                	addi	sp,sp,-32
    80006e80:	ec06                	sd	ra,24(sp)
    80006e82:	e822                	sd	s0,16(sp)
    80006e84:	e426                	sd	s1,8(sp)
    80006e86:	e04a                	sd	s2,0(sp)
    80006e88:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e8a:	00026517          	auipc	a0,0x26
    80006e8e:	29e50513          	addi	a0,a0,670 # 8002d128 <disk+0x2128>
    80006e92:	ffffa097          	auipc	ra,0xffffa
    80006e96:	d40080e7          	jalr	-704(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e9a:	10001737          	lui	a4,0x10001
    80006e9e:	533c                	lw	a5,96(a4)
    80006ea0:	8b8d                	andi	a5,a5,3
    80006ea2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ea4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ea8:	00026797          	auipc	a5,0x26
    80006eac:	15878793          	addi	a5,a5,344 # 8002d000 <disk+0x2000>
    80006eb0:	6b94                	ld	a3,16(a5)
    80006eb2:	0207d703          	lhu	a4,32(a5)
    80006eb6:	0026d783          	lhu	a5,2(a3)
    80006eba:	06f70163          	beq	a4,a5,80006f1c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ebe:	00024917          	auipc	s2,0x24
    80006ec2:	14290913          	addi	s2,s2,322 # 8002b000 <disk>
    80006ec6:	00026497          	auipc	s1,0x26
    80006eca:	13a48493          	addi	s1,s1,314 # 8002d000 <disk+0x2000>
    __sync_synchronize();
    80006ece:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ed2:	6898                	ld	a4,16(s1)
    80006ed4:	0204d783          	lhu	a5,32(s1)
    80006ed8:	8b9d                	andi	a5,a5,7
    80006eda:	078e                	slli	a5,a5,0x3
    80006edc:	97ba                	add	a5,a5,a4
    80006ede:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ee0:	20078713          	addi	a4,a5,512
    80006ee4:	0712                	slli	a4,a4,0x4
    80006ee6:	974a                	add	a4,a4,s2
    80006ee8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006eec:	e731                	bnez	a4,80006f38 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006eee:	20078793          	addi	a5,a5,512
    80006ef2:	0792                	slli	a5,a5,0x4
    80006ef4:	97ca                	add	a5,a5,s2
    80006ef6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006ef8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006efc:	ffffc097          	auipc	ra,0xffffc
    80006f00:	bc6080e7          	jalr	-1082(ra) # 80002ac2 <wakeup>

    disk.used_idx += 1;
    80006f04:	0204d783          	lhu	a5,32(s1)
    80006f08:	2785                	addiw	a5,a5,1
    80006f0a:	17c2                	slli	a5,a5,0x30
    80006f0c:	93c1                	srli	a5,a5,0x30
    80006f0e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006f12:	6898                	ld	a4,16(s1)
    80006f14:	00275703          	lhu	a4,2(a4)
    80006f18:	faf71be3          	bne	a4,a5,80006ece <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006f1c:	00026517          	auipc	a0,0x26
    80006f20:	20c50513          	addi	a0,a0,524 # 8002d128 <disk+0x2128>
    80006f24:	ffffa097          	auipc	ra,0xffffa
    80006f28:	d62080e7          	jalr	-670(ra) # 80000c86 <release>
}
    80006f2c:	60e2                	ld	ra,24(sp)
    80006f2e:	6442                	ld	s0,16(sp)
    80006f30:	64a2                	ld	s1,8(sp)
    80006f32:	6902                	ld	s2,0(sp)
    80006f34:	6105                	addi	sp,sp,32
    80006f36:	8082                	ret
      panic("virtio_disk_intr status");
    80006f38:	00002517          	auipc	a0,0x2
    80006f3c:	a4050513          	addi	a0,a0,-1472 # 80008978 <syscalls+0x3e8>
    80006f40:	ffff9097          	auipc	ra,0xffff9
    80006f44:	5ea080e7          	jalr	1514(ra) # 8000052a <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
