
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	40c78793          	addi	a5,a5,1036 # 80006470 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd27ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dbe78793          	addi	a5,a5,-578 # 80000e6c <main>
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
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	75c080e7          	jalr	1884(ra) # 8000287a <either_copyin>
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
    80000188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
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
    800001b6:	a68080e7          	jalr	-1432(ra) # 80001c1a <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	2a8080e7          	jalr	680(ra) # 8000246a <sleep>
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
    800001fe:	00002097          	auipc	ra,0x2
    80000202:	626080e7          	jalr	1574(ra) # 80002824 <either_copyout>
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
    8000021e:	a5c080e7          	jalr	-1444(ra) # 80000c76 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	f5850513          	addi	a0,a0,-168 # 80011180 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	a46080e7          	jalr	-1466(ra) # 80000c76 <release>
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
    800002c4:	902080e7          	jalr	-1790(ra) # 80000bc2 <acquire>

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
    800002de:	00002097          	auipc	ra,0x2
    800002e2:	5f2080e7          	jalr	1522(ra) # 800028d0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00011517          	auipc	a0,0x11
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80011180 <cons>
    800002ee:	00001097          	auipc	ra,0x1
    800002f2:	988080e7          	jalr	-1656(ra) # 80000c76 <release>
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
    80000436:	1c4080e7          	jalr	452(ra) # 800025f6 <wakeup>
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
    80000458:	6de080e7          	jalr	1758(ra) # 80000b32 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	00027797          	auipc	a5,0x27
    80000468:	0b478793          	addi	a5,a5,180 # 80027518 <devsw>
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
    8000055c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
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
    800005f0:	5d6080e7          	jalr	1494(ra) # 80000bc2 <acquire>
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
    8000074e:	52c080e7          	jalr	1324(ra) # 80000c76 <release>
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
    80000774:	3c2080e7          	jalr	962(ra) # 80000b32 <initlock>
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
    800007ca:	36c080e7          	jalr	876(ra) # 80000b32 <initlock>
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
    800007e6:	394080e7          	jalr	916(ra) # 80000b76 <push_off>

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
    80000814:	406080e7          	jalr	1030(ra) # 80000c16 <pop_off>
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
    80000882:	d78080e7          	jalr	-648(ra) # 800025f6 <wakeup>
    
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
    800008c6:	300080e7          	jalr	768(ra) # 80000bc2 <acquire>
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
    8000090e:	b60080e7          	jalr	-1184(ra) # 8000246a <sleep>
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
    8000094a:	330080e7          	jalr	816(ra) # 80000c76 <release>
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
    800009b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  uartstart();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	e68080e7          	jalr	-408(ra) # 80000822 <uartstart>
  release(&uart_tx_lock);
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	2b2080e7          	jalr	690(ra) # 80000c76 <release>
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

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009e2:	03451793          	slli	a5,a0,0x34
    800009e6:	ebb9                	bnez	a5,80000a3c <kfree+0x66>
    800009e8:	84aa                	mv	s1,a0
    800009ea:	0002b797          	auipc	a5,0x2b
    800009ee:	61678793          	addi	a5,a5,1558 # 8002c000 <end>
    800009f2:	04f56563          	bltu	a0,a5,80000a3c <kfree+0x66>
    800009f6:	47c5                	li	a5,17
    800009f8:	07ee                	slli	a5,a5,0x1b
    800009fa:	04f57163          	bgeu	a0,a5,80000a3c <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    800009fe:	6605                	lui	a2,0x1
    80000a00:	4585                	li	a1,1
    80000a02:	00000097          	auipc	ra,0x0
    80000a06:	2bc080e7          	jalr	700(ra) # 80000cbe <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a0a:	00011917          	auipc	s2,0x11
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80011280 <kmem>
    80000a12:	854a                	mv	a0,s2
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	1ae080e7          	jalr	430(ra) # 80000bc2 <acquire>
  r->next = kmem.freelist;
    80000a1c:	01893783          	ld	a5,24(s2)
    80000a20:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a22:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	24e080e7          	jalr	590(ra) # 80000c76 <release>
}
    80000a30:	60e2                	ld	ra,24(sp)
    80000a32:	6442                	ld	s0,16(sp)
    80000a34:	64a2                	ld	s1,8(sp)
    80000a36:	6902                	ld	s2,0(sp)
    80000a38:	6105                	addi	sp,sp,32
    80000a3a:	8082                	ret
    panic("kfree");
    80000a3c:	00007517          	auipc	a0,0x7
    80000a40:	62450513          	addi	a0,a0,1572 # 80008060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>

0000000080000a4c <freerange>:
{
    80000a4c:	7179                	addi	sp,sp,-48
    80000a4e:	f406                	sd	ra,40(sp)
    80000a50:	f022                	sd	s0,32(sp)
    80000a52:	ec26                	sd	s1,24(sp)
    80000a54:	e84a                	sd	s2,16(sp)
    80000a56:	e44e                	sd	s3,8(sp)
    80000a58:	e052                	sd	s4,0(sp)
    80000a5a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a5c:	6785                	lui	a5,0x1
    80000a5e:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a62:	94aa                	add	s1,s1,a0
    80000a64:	757d                	lui	a0,0xfffff
    80000a66:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a68:	94be                	add	s1,s1,a5
    80000a6a:	0095ee63          	bltu	a1,s1,80000a86 <freerange+0x3a>
    80000a6e:	892e                	mv	s2,a1
    kfree(p);
    80000a70:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a72:	6985                	lui	s3,0x1
    kfree(p);
    80000a74:	01448533          	add	a0,s1,s4
    80000a78:	00000097          	auipc	ra,0x0
    80000a7c:	f5e080e7          	jalr	-162(ra) # 800009d6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a80:	94ce                	add	s1,s1,s3
    80000a82:	fe9979e3          	bgeu	s2,s1,80000a74 <freerange+0x28>
}
    80000a86:	70a2                	ld	ra,40(sp)
    80000a88:	7402                	ld	s0,32(sp)
    80000a8a:	64e2                	ld	s1,24(sp)
    80000a8c:	6942                	ld	s2,16(sp)
    80000a8e:	69a2                	ld	s3,8(sp)
    80000a90:	6a02                	ld	s4,0(sp)
    80000a92:	6145                	addi	sp,sp,48
    80000a94:	8082                	ret

0000000080000a96 <kinit>:
{
    80000a96:	1141                	addi	sp,sp,-16
    80000a98:	e406                	sd	ra,8(sp)
    80000a9a:	e022                	sd	s0,0(sp)
    80000a9c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000a9e:	00007597          	auipc	a1,0x7
    80000aa2:	5ca58593          	addi	a1,a1,1482 # 80008068 <digits+0x28>
    80000aa6:	00010517          	auipc	a0,0x10
    80000aaa:	7da50513          	addi	a0,a0,2010 # 80011280 <kmem>
    80000aae:	00000097          	auipc	ra,0x0
    80000ab2:	084080e7          	jalr	132(ra) # 80000b32 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ab6:	45c5                	li	a1,17
    80000ab8:	05ee                	slli	a1,a1,0x1b
    80000aba:	0002b517          	auipc	a0,0x2b
    80000abe:	54650513          	addi	a0,a0,1350 # 8002c000 <end>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	f8a080e7          	jalr	-118(ra) # 80000a4c <freerange>
}
    80000aca:	60a2                	ld	ra,8(sp)
    80000acc:	6402                	ld	s0,0(sp)
    80000ace:	0141                	addi	sp,sp,16
    80000ad0:	8082                	ret

0000000080000ad2 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ad2:	1101                	addi	sp,sp,-32
    80000ad4:	ec06                	sd	ra,24(sp)
    80000ad6:	e822                	sd	s0,16(sp)
    80000ad8:	e426                	sd	s1,8(sp)
    80000ada:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000adc:	00010497          	auipc	s1,0x10
    80000ae0:	7a448493          	addi	s1,s1,1956 # 80011280 <kmem>
    80000ae4:	8526                	mv	a0,s1
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	0dc080e7          	jalr	220(ra) # 80000bc2 <acquire>
  r = kmem.freelist;
    80000aee:	6c84                	ld	s1,24(s1)
  if(r)
    80000af0:	c885                	beqz	s1,80000b20 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000af2:	609c                	ld	a5,0(s1)
    80000af4:	00010517          	auipc	a0,0x10
    80000af8:	78c50513          	addi	a0,a0,1932 # 80011280 <kmem>
    80000afc:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	178080e7          	jalr	376(ra) # 80000c76 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b06:	6605                	lui	a2,0x1
    80000b08:	4595                	li	a1,5
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	00000097          	auipc	ra,0x0
    80000b10:	1b2080e7          	jalr	434(ra) # 80000cbe <memset>
  return (void*)r;
}
    80000b14:	8526                	mv	a0,s1
    80000b16:	60e2                	ld	ra,24(sp)
    80000b18:	6442                	ld	s0,16(sp)
    80000b1a:	64a2                	ld	s1,8(sp)
    80000b1c:	6105                	addi	sp,sp,32
    80000b1e:	8082                	ret
  release(&kmem.lock);
    80000b20:	00010517          	auipc	a0,0x10
    80000b24:	76050513          	addi	a0,a0,1888 # 80011280 <kmem>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	14e080e7          	jalr	334(ra) # 80000c76 <release>
  if(r)
    80000b30:	b7d5                	j	80000b14 <kalloc+0x42>

0000000080000b32 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b32:	1141                	addi	sp,sp,-16
    80000b34:	e422                	sd	s0,8(sp)
    80000b36:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b38:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b3a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b3e:	00053823          	sd	zero,16(a0)
}
    80000b42:	6422                	ld	s0,8(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b48:	411c                	lw	a5,0(a0)
    80000b4a:	e399                	bnez	a5,80000b50 <holding+0x8>
    80000b4c:	4501                	li	a0,0
  return r;
}
    80000b4e:	8082                	ret
{
    80000b50:	1101                	addi	sp,sp,-32
    80000b52:	ec06                	sd	ra,24(sp)
    80000b54:	e822                	sd	s0,16(sp)
    80000b56:	e426                	sd	s1,8(sp)
    80000b58:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b5a:	6904                	ld	s1,16(a0)
    80000b5c:	00001097          	auipc	ra,0x1
    80000b60:	0a2080e7          	jalr	162(ra) # 80001bfe <mycpu>
    80000b64:	40a48533          	sub	a0,s1,a0
    80000b68:	00153513          	seqz	a0,a0
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6105                	addi	sp,sp,32
    80000b74:	8082                	ret

0000000080000b76 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b76:	1101                	addi	sp,sp,-32
    80000b78:	ec06                	sd	ra,24(sp)
    80000b7a:	e822                	sd	s0,16(sp)
    80000b7c:	e426                	sd	s1,8(sp)
    80000b7e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b80:	100024f3          	csrr	s1,sstatus
    80000b84:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b8a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000b8e:	00001097          	auipc	ra,0x1
    80000b92:	070080e7          	jalr	112(ra) # 80001bfe <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	064080e7          	jalr	100(ra) # 80001bfe <mycpu>
    80000ba2:	5d3c                	lw	a5,120(a0)
    80000ba4:	2785                	addiw	a5,a5,1
    80000ba6:	dd3c                	sw	a5,120(a0)
}
    80000ba8:	60e2                	ld	ra,24(sp)
    80000baa:	6442                	ld	s0,16(sp)
    80000bac:	64a2                	ld	s1,8(sp)
    80000bae:	6105                	addi	sp,sp,32
    80000bb0:	8082                	ret
    mycpu()->intena = old;
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	04c080e7          	jalr	76(ra) # 80001bfe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bba:	8085                	srli	s1,s1,0x1
    80000bbc:	8885                	andi	s1,s1,1
    80000bbe:	dd64                	sw	s1,124(a0)
    80000bc0:	bfe9                	j	80000b9a <push_off+0x24>

0000000080000bc2 <acquire>:
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
    80000bcc:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	fa8080e7          	jalr	-88(ra) # 80000b76 <push_off>
  if(holding(lk))
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	f70080e7          	jalr	-144(ra) # 80000b48 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be0:	4705                	li	a4,1
  if(holding(lk))
    80000be2:	e115                	bnez	a0,80000c06 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	87ba                	mv	a5,a4
    80000be6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bea:	2781                	sext.w	a5,a5
    80000bec:	ffe5                	bnez	a5,80000be4 <acquire+0x22>
  __sync_synchronize();
    80000bee:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000bf2:	00001097          	auipc	ra,0x1
    80000bf6:	00c080e7          	jalr	12(ra) # 80001bfe <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00007517          	auipc	a0,0x7
    80000c0a:	46a50513          	addi	a0,a0,1130 # 80008070 <digits+0x30>
    80000c0e:	00000097          	auipc	ra,0x0
    80000c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>

0000000080000c16 <pop_off>:

void
pop_off(void)
{
    80000c16:	1141                	addi	sp,sp,-16
    80000c18:	e406                	sd	ra,8(sp)
    80000c1a:	e022                	sd	s0,0(sp)
    80000c1c:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	fe0080e7          	jalr	-32(ra) # 80001bfe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c26:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c2a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c2c:	e78d                	bnez	a5,80000c56 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c2e:	5d3c                	lw	a5,120(a0)
    80000c30:	02f05b63          	blez	a5,80000c66 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c34:	37fd                	addiw	a5,a5,-1
    80000c36:	0007871b          	sext.w	a4,a5
    80000c3a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c3c:	eb09                	bnez	a4,80000c4e <pop_off+0x38>
    80000c3e:	5d7c                	lw	a5,124(a0)
    80000c40:	c799                	beqz	a5,80000c4e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c46:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c4e:	60a2                	ld	ra,8(sp)
    80000c50:	6402                	ld	s0,0(sp)
    80000c52:	0141                	addi	sp,sp,16
    80000c54:	8082                	ret
    panic("pop_off - interruptible");
    80000c56:	00007517          	auipc	a0,0x7
    80000c5a:	42250513          	addi	a0,a0,1058 # 80008078 <digits+0x38>
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	8cc080e7          	jalr	-1844(ra) # 8000052a <panic>
    panic("pop_off");
    80000c66:	00007517          	auipc	a0,0x7
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80008090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>

0000000080000c76 <release>:
{
    80000c76:	1101                	addi	sp,sp,-32
    80000c78:	ec06                	sd	ra,24(sp)
    80000c7a:	e822                	sd	s0,16(sp)
    80000c7c:	e426                	sd	s1,8(sp)
    80000c7e:	1000                	addi	s0,sp,32
    80000c80:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	ec6080e7          	jalr	-314(ra) # 80000b48 <holding>
    80000c8a:	c115                	beqz	a0,80000cae <release+0x38>
  lk->cpu = 0;
    80000c8c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c90:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000c94:	0f50000f          	fence	iorw,ow
    80000c98:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000c9c:	00000097          	auipc	ra,0x0
    80000ca0:	f7a080e7          	jalr	-134(ra) # 80000c16 <pop_off>
}
    80000ca4:	60e2                	ld	ra,24(sp)
    80000ca6:	6442                	ld	s0,16(sp)
    80000ca8:	64a2                	ld	s1,8(sp)
    80000caa:	6105                	addi	sp,sp,32
    80000cac:	8082                	ret
    panic("release");
    80000cae:	00007517          	auipc	a0,0x7
    80000cb2:	3ea50513          	addi	a0,a0,1002 # 80008098 <digits+0x58>
    80000cb6:	00000097          	auipc	ra,0x0
    80000cba:	874080e7          	jalr	-1932(ra) # 8000052a <panic>

0000000080000cbe <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cbe:	1141                	addi	sp,sp,-16
    80000cc0:	e422                	sd	s0,8(sp)
    80000cc2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cc4:	ca19                	beqz	a2,80000cda <memset+0x1c>
    80000cc6:	87aa                	mv	a5,a0
    80000cc8:	1602                	slli	a2,a2,0x20
    80000cca:	9201                	srli	a2,a2,0x20
    80000ccc:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cd0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cd4:	0785                	addi	a5,a5,1
    80000cd6:	fee79de3          	bne	a5,a4,80000cd0 <memset+0x12>
  }
  return dst;
}
    80000cda:	6422                	ld	s0,8(sp)
    80000cdc:	0141                	addi	sp,sp,16
    80000cde:	8082                	ret

0000000080000ce0 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ce6:	ca05                	beqz	a2,80000d16 <memcmp+0x36>
    80000ce8:	fff6069b          	addiw	a3,a2,-1
    80000cec:	1682                	slli	a3,a3,0x20
    80000cee:	9281                	srli	a3,a3,0x20
    80000cf0:	0685                	addi	a3,a3,1
    80000cf2:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cf4:	00054783          	lbu	a5,0(a0)
    80000cf8:	0005c703          	lbu	a4,0(a1)
    80000cfc:	00e79863          	bne	a5,a4,80000d0c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d00:	0505                	addi	a0,a0,1
    80000d02:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d04:	fed518e3          	bne	a0,a3,80000cf4 <memcmp+0x14>
  }

  return 0;
    80000d08:	4501                	li	a0,0
    80000d0a:	a019                	j	80000d10 <memcmp+0x30>
      return *s1 - *s2;
    80000d0c:	40e7853b          	subw	a0,a5,a4
}
    80000d10:	6422                	ld	s0,8(sp)
    80000d12:	0141                	addi	sp,sp,16
    80000d14:	8082                	ret
  return 0;
    80000d16:	4501                	li	a0,0
    80000d18:	bfe5                	j	80000d10 <memcmp+0x30>

0000000080000d1a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d20:	02a5e563          	bltu	a1,a0,80000d4a <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d24:	fff6069b          	addiw	a3,a2,-1
    80000d28:	ce11                	beqz	a2,80000d44 <memmove+0x2a>
    80000d2a:	1682                	slli	a3,a3,0x20
    80000d2c:	9281                	srli	a3,a3,0x20
    80000d2e:	0685                	addi	a3,a3,1
    80000d30:	96ae                	add	a3,a3,a1
    80000d32:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d34:	0585                	addi	a1,a1,1
    80000d36:	0785                	addi	a5,a5,1
    80000d38:	fff5c703          	lbu	a4,-1(a1)
    80000d3c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d40:	fed59ae3          	bne	a1,a3,80000d34 <memmove+0x1a>

  return dst;
}
    80000d44:	6422                	ld	s0,8(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
  if(s < d && s + n > d){
    80000d4a:	02061713          	slli	a4,a2,0x20
    80000d4e:	9301                	srli	a4,a4,0x20
    80000d50:	00e587b3          	add	a5,a1,a4
    80000d54:	fcf578e3          	bgeu	a0,a5,80000d24 <memmove+0xa>
    d += n;
    80000d58:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d5a:	fff6069b          	addiw	a3,a2,-1
    80000d5e:	d27d                	beqz	a2,80000d44 <memmove+0x2a>
    80000d60:	02069613          	slli	a2,a3,0x20
    80000d64:	9201                	srli	a2,a2,0x20
    80000d66:	fff64613          	not	a2,a2
    80000d6a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d6c:	17fd                	addi	a5,a5,-1
    80000d6e:	177d                	addi	a4,a4,-1
    80000d70:	0007c683          	lbu	a3,0(a5)
    80000d74:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d78:	fef61ae3          	bne	a2,a5,80000d6c <memmove+0x52>
    80000d7c:	b7e1                	j	80000d44 <memmove+0x2a>

0000000080000d7e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d7e:	1141                	addi	sp,sp,-16
    80000d80:	e406                	sd	ra,8(sp)
    80000d82:	e022                	sd	s0,0(sp)
    80000d84:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d86:	00000097          	auipc	ra,0x0
    80000d8a:	f94080e7          	jalr	-108(ra) # 80000d1a <memmove>
}
    80000d8e:	60a2                	ld	ra,8(sp)
    80000d90:	6402                	ld	s0,0(sp)
    80000d92:	0141                	addi	sp,sp,16
    80000d94:	8082                	ret

0000000080000d96 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e422                	sd	s0,8(sp)
    80000d9a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d9c:	ce11                	beqz	a2,80000db8 <strncmp+0x22>
    80000d9e:	00054783          	lbu	a5,0(a0)
    80000da2:	cf89                	beqz	a5,80000dbc <strncmp+0x26>
    80000da4:	0005c703          	lbu	a4,0(a1)
    80000da8:	00f71a63          	bne	a4,a5,80000dbc <strncmp+0x26>
    n--, p++, q++;
    80000dac:	367d                	addiw	a2,a2,-1
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000db2:	f675                	bnez	a2,80000d9e <strncmp+0x8>
  if(n == 0)
    return 0;
    80000db4:	4501                	li	a0,0
    80000db6:	a809                	j	80000dc8 <strncmp+0x32>
    80000db8:	4501                	li	a0,0
    80000dba:	a039                	j	80000dc8 <strncmp+0x32>
  if(n == 0)
    80000dbc:	ca09                	beqz	a2,80000dce <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dbe:	00054503          	lbu	a0,0(a0)
    80000dc2:	0005c783          	lbu	a5,0(a1)
    80000dc6:	9d1d                	subw	a0,a0,a5
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	bfe5                	j	80000dc8 <strncmp+0x32>

0000000080000dd2 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dd8:	872a                	mv	a4,a0
    80000dda:	8832                	mv	a6,a2
    80000ddc:	367d                	addiw	a2,a2,-1
    80000dde:	01005963          	blez	a6,80000df0 <strncpy+0x1e>
    80000de2:	0705                	addi	a4,a4,1
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	fef70fa3          	sb	a5,-1(a4)
    80000dec:	0585                	addi	a1,a1,1
    80000dee:	f7f5                	bnez	a5,80000dda <strncpy+0x8>
    ;
  while(n-- > 0)
    80000df0:	86ba                	mv	a3,a4
    80000df2:	00c05c63          	blez	a2,80000e0a <strncpy+0x38>
    *s++ = 0;
    80000df6:	0685                	addi	a3,a3,1
    80000df8:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000dfc:	fff6c793          	not	a5,a3
    80000e00:	9fb9                	addw	a5,a5,a4
    80000e02:	010787bb          	addw	a5,a5,a6
    80000e06:	fef048e3          	bgtz	a5,80000df6 <strncpy+0x24>
  return os;
}
    80000e0a:	6422                	ld	s0,8(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret

0000000080000e10 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e16:	02c05363          	blez	a2,80000e3c <safestrcpy+0x2c>
    80000e1a:	fff6069b          	addiw	a3,a2,-1
    80000e1e:	1682                	slli	a3,a3,0x20
    80000e20:	9281                	srli	a3,a3,0x20
    80000e22:	96ae                	add	a3,a3,a1
    80000e24:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e26:	00d58963          	beq	a1,a3,80000e38 <safestrcpy+0x28>
    80000e2a:	0585                	addi	a1,a1,1
    80000e2c:	0785                	addi	a5,a5,1
    80000e2e:	fff5c703          	lbu	a4,-1(a1)
    80000e32:	fee78fa3          	sb	a4,-1(a5)
    80000e36:	fb65                	bnez	a4,80000e26 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e38:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e3c:	6422                	ld	s0,8(sp)
    80000e3e:	0141                	addi	sp,sp,16
    80000e40:	8082                	ret

0000000080000e42 <strlen>:

int
strlen(const char *s)
{
    80000e42:	1141                	addi	sp,sp,-16
    80000e44:	e422                	sd	s0,8(sp)
    80000e46:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e48:	00054783          	lbu	a5,0(a0)
    80000e4c:	cf91                	beqz	a5,80000e68 <strlen+0x26>
    80000e4e:	0505                	addi	a0,a0,1
    80000e50:	87aa                	mv	a5,a0
    80000e52:	4685                	li	a3,1
    80000e54:	9e89                	subw	a3,a3,a0
    80000e56:	00f6853b          	addw	a0,a3,a5
    80000e5a:	0785                	addi	a5,a5,1
    80000e5c:	fff7c703          	lbu	a4,-1(a5)
    80000e60:	fb7d                	bnez	a4,80000e56 <strlen+0x14>
    ;
  return n;
}
    80000e62:	6422                	ld	s0,8(sp)
    80000e64:	0141                	addi	sp,sp,16
    80000e66:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e68:	4501                	li	a0,0
    80000e6a:	bfe5                	j	80000e62 <strlen+0x20>

0000000080000e6c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e6c:	1141                	addi	sp,sp,-16
    80000e6e:	e406                	sd	ra,8(sp)
    80000e70:	e022                	sd	s0,0(sp)
    80000e72:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e74:	00001097          	auipc	ra,0x1
    80000e78:	d7a080e7          	jalr	-646(ra) # 80001bee <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e7c:	00008717          	auipc	a4,0x8
    80000e80:	19c70713          	addi	a4,a4,412 # 80009018 <started>
  if(cpuid() == 0){
    80000e84:	c139                	beqz	a0,80000eca <main+0x5e>
    while(started == 0)
    80000e86:	431c                	lw	a5,0(a4)
    80000e88:	2781                	sext.w	a5,a5
    80000e8a:	dff5                	beqz	a5,80000e86 <main+0x1a>
      ;
    __sync_synchronize();
    80000e8c:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e90:	00001097          	auipc	ra,0x1
    80000e94:	d5e080e7          	jalr	-674(ra) # 80001bee <cpuid>
    80000e98:	85aa                	mv	a1,a0
    80000e9a:	00007517          	auipc	a0,0x7
    80000e9e:	21e50513          	addi	a0,a0,542 # 800080b8 <digits+0x78>
    80000ea2:	fffff097          	auipc	ra,0xfffff
    80000ea6:	6d2080e7          	jalr	1746(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eaa:	00000097          	auipc	ra,0x0
    80000eae:	0d8080e7          	jalr	216(ra) # 80000f82 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eb2:	00002097          	auipc	ra,0x2
    80000eb6:	b60080e7          	jalr	-1184(ra) # 80002a12 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	5f6080e7          	jalr	1526(ra) # 800064b0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	3f6080e7          	jalr	1014(ra) # 800022b8 <scheduler>
    consoleinit();
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	572080e7          	jalr	1394(ra) # 8000043c <consoleinit>
    printfinit();
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	882080e7          	jalr	-1918(ra) # 80000754 <printfinit>
    printf("\n");
    80000eda:	00007517          	auipc	a0,0x7
    80000ede:	1ee50513          	addi	a0,a0,494 # 800080c8 <digits+0x88>
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	692080e7          	jalr	1682(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000eea:	00007517          	auipc	a0,0x7
    80000eee:	1b650513          	addi	a0,a0,438 # 800080a0 <digits+0x60>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("\n");
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ce50513          	addi	a0,a0,462 # 800080c8 <digits+0x88>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	b8c080e7          	jalr	-1140(ra) # 80000a96 <kinit>
    kvminit();       // create kernel page table
    80000f12:	00000097          	auipc	ra,0x0
    80000f16:	310080e7          	jalr	784(ra) # 80001222 <kvminit>
    kvminithart();   // turn on paging
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	068080e7          	jalr	104(ra) # 80000f82 <kvminithart>
    procinit();      // process table
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	c1c080e7          	jalr	-996(ra) # 80001b3e <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	ac0080e7          	jalr	-1344(ra) # 800029ea <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	ae0080e7          	jalr	-1312(ra) # 80002a12 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	560080e7          	jalr	1376(ra) # 8000649a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	56e080e7          	jalr	1390(ra) # 800064b0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	208080e7          	jalr	520(ra) # 80003152 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	89a080e7          	jalr	-1894(ra) # 800037ec <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	b5a080e7          	jalr	-1190(ra) # 80004ab4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	670080e7          	jalr	1648(ra) # 800065d2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	fa6080e7          	jalr	-90(ra) # 80001f10 <userinit>
    __sync_synchronize();
    80000f72:	0ff0000f          	fence
    started = 1;
    80000f76:	4785                	li	a5,1
    80000f78:	00008717          	auipc	a4,0x8
    80000f7c:	0af72023          	sw	a5,160(a4) # 80009018 <started>
    80000f80:	b789                	j	80000ec2 <main+0x56>

0000000080000f82 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f82:	1141                	addi	sp,sp,-16
    80000f84:	e422                	sd	s0,8(sp)
    80000f86:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000f88:	00008797          	auipc	a5,0x8
    80000f8c:	0987b783          	ld	a5,152(a5) # 80009020 <kernel_pagetable>
    80000f90:	83b1                	srli	a5,a5,0xc
    80000f92:	577d                	li	a4,-1
    80000f94:	177e                	slli	a4,a4,0x3f
    80000f96:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f98:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f9c:	12000073          	sfence.vma
  sfence_vma();
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret

0000000080000fa6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fa6:	7139                	addi	sp,sp,-64
    80000fa8:	fc06                	sd	ra,56(sp)
    80000faa:	f822                	sd	s0,48(sp)
    80000fac:	f426                	sd	s1,40(sp)
    80000fae:	f04a                	sd	s2,32(sp)
    80000fb0:	ec4e                	sd	s3,24(sp)
    80000fb2:	e852                	sd	s4,16(sp)
    80000fb4:	e456                	sd	s5,8(sp)
    80000fb6:	e05a                	sd	s6,0(sp)
    80000fb8:	0080                	addi	s0,sp,64
    80000fba:	84aa                	mv	s1,a0
    80000fbc:	89ae                	mv	s3,a1
    80000fbe:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fc0:	57fd                	li	a5,-1
    80000fc2:	83e9                	srli	a5,a5,0x1a
    80000fc4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fc6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fc8:	04b7f263          	bgeu	a5,a1,8000100c <walk+0x66>
    panic("walk");
    80000fcc:	00007517          	auipc	a0,0x7
    80000fd0:	10450513          	addi	a0,a0,260 # 800080d0 <digits+0x90>
    80000fd4:	fffff097          	auipc	ra,0xfffff
    80000fd8:	556080e7          	jalr	1366(ra) # 8000052a <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fdc:	060a8663          	beqz	s5,80001048 <walk+0xa2>
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	af2080e7          	jalr	-1294(ra) # 80000ad2 <kalloc>
    80000fe8:	84aa                	mv	s1,a0
    80000fea:	c529                	beqz	a0,80001034 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fec:	6605                	lui	a2,0x1
    80000fee:	4581                	li	a1,0
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	cce080e7          	jalr	-818(ra) # 80000cbe <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff8:	00c4d793          	srli	a5,s1,0xc
    80000ffc:	07aa                	slli	a5,a5,0xa
    80000ffe:	0017e793          	ori	a5,a5,1
    80001002:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001006:	3a5d                	addiw	s4,s4,-9
    80001008:	036a0063          	beq	s4,s6,80001028 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000100c:	0149d933          	srl	s2,s3,s4
    80001010:	1ff97913          	andi	s2,s2,511
    80001014:	090e                	slli	s2,s2,0x3
    80001016:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001018:	00093483          	ld	s1,0(s2)
    8000101c:	0014f793          	andi	a5,s1,1
    80001020:	dfd5                	beqz	a5,80000fdc <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001022:	80a9                	srli	s1,s1,0xa
    80001024:	04b2                	slli	s1,s1,0xc
    80001026:	b7c5                	j	80001006 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001028:	00c9d513          	srli	a0,s3,0xc
    8000102c:	1ff57513          	andi	a0,a0,511
    80001030:	050e                	slli	a0,a0,0x3
    80001032:	9526                	add	a0,a0,s1
}
    80001034:	70e2                	ld	ra,56(sp)
    80001036:	7442                	ld	s0,48(sp)
    80001038:	74a2                	ld	s1,40(sp)
    8000103a:	7902                	ld	s2,32(sp)
    8000103c:	69e2                	ld	s3,24(sp)
    8000103e:	6a42                	ld	s4,16(sp)
    80001040:	6aa2                	ld	s5,8(sp)
    80001042:	6b02                	ld	s6,0(sp)
    80001044:	6121                	addi	sp,sp,64
    80001046:	8082                	ret
        return 0;
    80001048:	4501                	li	a0,0
    8000104a:	b7ed                	j	80001034 <walk+0x8e>

000000008000104c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000104c:	57fd                	li	a5,-1
    8000104e:	83e9                	srli	a5,a5,0x1a
    80001050:	00b7f463          	bgeu	a5,a1,80001058 <walkaddr+0xc>
    return 0;
    80001054:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001056:	8082                	ret
{
    80001058:	1141                	addi	sp,sp,-16
    8000105a:	e406                	sd	ra,8(sp)
    8000105c:	e022                	sd	s0,0(sp)
    8000105e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001060:	4601                	li	a2,0
    80001062:	00000097          	auipc	ra,0x0
    80001066:	f44080e7          	jalr	-188(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000106a:	c105                	beqz	a0,8000108a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000106c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000106e:	0117f693          	andi	a3,a5,17
    80001072:	4745                	li	a4,17
    return 0;
    80001074:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001076:	00e68663          	beq	a3,a4,80001082 <walkaddr+0x36>
}
    8000107a:	60a2                	ld	ra,8(sp)
    8000107c:	6402                	ld	s0,0(sp)
    8000107e:	0141                	addi	sp,sp,16
    80001080:	8082                	ret
  pa = PTE2PA(*pte);
    80001082:	00a7d513          	srli	a0,a5,0xa
    80001086:	0532                	slli	a0,a0,0xc
  return pa;
    80001088:	bfcd                	j	8000107a <walkaddr+0x2e>
    return 0;
    8000108a:	4501                	li	a0,0
    8000108c:	b7fd                	j	8000107a <walkaddr+0x2e>

000000008000108e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000108e:	715d                	addi	sp,sp,-80
    80001090:	e486                	sd	ra,72(sp)
    80001092:	e0a2                	sd	s0,64(sp)
    80001094:	fc26                	sd	s1,56(sp)
    80001096:	f84a                	sd	s2,48(sp)
    80001098:	f44e                	sd	s3,40(sp)
    8000109a:	f052                	sd	s4,32(sp)
    8000109c:	ec56                	sd	s5,24(sp)
    8000109e:	e85a                	sd	s6,16(sp)
    800010a0:	e45e                	sd	s7,8(sp)
    800010a2:	0880                	addi	s0,sp,80
    800010a4:	8aaa                	mv	s5,a0
    800010a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a8:	777d                	lui	a4,0xfffff
    800010aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010ae:	167d                	addi	a2,a2,-1
    800010b0:	00b609b3          	add	s3,a2,a1
    800010b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b8:	893e                	mv	s2,a5
    800010ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010be:	6b85                	lui	s7,0x1
    800010c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010c4:	4605                	li	a2,1
    800010c6:	85ca                	mv	a1,s2
    800010c8:	8556                	mv	a0,s5
    800010ca:	00000097          	auipc	ra,0x0
    800010ce:	edc080e7          	jalr	-292(ra) # 80000fa6 <walk>
    800010d2:	c51d                	beqz	a0,80001100 <mappages+0x72>
    if(*pte & PTE_V)
    800010d4:	611c                	ld	a5,0(a0)
    800010d6:	8b85                	andi	a5,a5,1
    800010d8:	ef81                	bnez	a5,800010f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010da:	80b1                	srli	s1,s1,0xc
    800010dc:	04aa                	slli	s1,s1,0xa
    800010de:	0164e4b3          	or	s1,s1,s6
    800010e2:	0014e493          	ori	s1,s1,1
    800010e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e8:	03390863          	beq	s2,s3,80001118 <mappages+0x8a>
    a += PGSIZE;
    800010ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010ee:	bfc9                	j	800010c0 <mappages+0x32>
      panic("remap");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	432080e7          	jalr	1074(ra) # 8000052a <panic>
      return -1;
    80001100:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001102:	60a6                	ld	ra,72(sp)
    80001104:	6406                	ld	s0,64(sp)
    80001106:	74e2                	ld	s1,56(sp)
    80001108:	7942                	ld	s2,48(sp)
    8000110a:	79a2                	ld	s3,40(sp)
    8000110c:	7a02                	ld	s4,32(sp)
    8000110e:	6ae2                	ld	s5,24(sp)
    80001110:	6b42                	ld	s6,16(sp)
    80001112:	6ba2                	ld	s7,8(sp)
    80001114:	6161                	addi	sp,sp,80
    80001116:	8082                	ret
  return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7e5                	j	80001102 <mappages+0x74>

000000008000111c <kvmmap>:
{
    8000111c:	1141                	addi	sp,sp,-16
    8000111e:	e406                	sd	ra,8(sp)
    80001120:	e022                	sd	s0,0(sp)
    80001122:	0800                	addi	s0,sp,16
    80001124:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001126:	86b2                	mv	a3,a2
    80001128:	863e                	mv	a2,a5
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f64080e7          	jalr	-156(ra) # 8000108e <mappages>
    80001132:	e509                	bnez	a0,8000113c <kvmmap+0x20>
}
    80001134:	60a2                	ld	ra,8(sp)
    80001136:	6402                	ld	s0,0(sp)
    80001138:	0141                	addi	sp,sp,16
    8000113a:	8082                	ret
    panic("kvmmap");
    8000113c:	00007517          	auipc	a0,0x7
    80001140:	fa450513          	addi	a0,a0,-92 # 800080e0 <digits+0xa0>
    80001144:	fffff097          	auipc	ra,0xfffff
    80001148:	3e6080e7          	jalr	998(ra) # 8000052a <panic>

000000008000114c <kvmmake>:
{
    8000114c:	1101                	addi	sp,sp,-32
    8000114e:	ec06                	sd	ra,24(sp)
    80001150:	e822                	sd	s0,16(sp)
    80001152:	e426                	sd	s1,8(sp)
    80001154:	e04a                	sd	s2,0(sp)
    80001156:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	97a080e7          	jalr	-1670(ra) # 80000ad2 <kalloc>
    80001160:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001162:	6605                	lui	a2,0x1
    80001164:	4581                	li	a1,0
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	b58080e7          	jalr	-1192(ra) # 80000cbe <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000116e:	4719                	li	a4,6
    80001170:	6685                	lui	a3,0x1
    80001172:	10000637          	lui	a2,0x10000
    80001176:	100005b7          	lui	a1,0x10000
    8000117a:	8526                	mv	a0,s1
    8000117c:	00000097          	auipc	ra,0x0
    80001180:	fa0080e7          	jalr	-96(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001184:	4719                	li	a4,6
    80001186:	6685                	lui	a3,0x1
    80001188:	10001637          	lui	a2,0x10001
    8000118c:	100015b7          	lui	a1,0x10001
    80001190:	8526                	mv	a0,s1
    80001192:	00000097          	auipc	ra,0x0
    80001196:	f8a080e7          	jalr	-118(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000119a:	4719                	li	a4,6
    8000119c:	004006b7          	lui	a3,0x400
    800011a0:	0c000637          	lui	a2,0xc000
    800011a4:	0c0005b7          	lui	a1,0xc000
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f72080e7          	jalr	-142(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011b2:	00007917          	auipc	s2,0x7
    800011b6:	e4e90913          	addi	s2,s2,-434 # 80008000 <etext>
    800011ba:	4729                	li	a4,10
    800011bc:	80007697          	auipc	a3,0x80007
    800011c0:	e4468693          	addi	a3,a3,-444 # 8000 <_entry-0x7fff8000>
    800011c4:	4605                	li	a2,1
    800011c6:	067e                	slli	a2,a2,0x1f
    800011c8:	85b2                	mv	a1,a2
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f50080e7          	jalr	-176(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011d4:	4719                	li	a4,6
    800011d6:	46c5                	li	a3,17
    800011d8:	06ee                	slli	a3,a3,0x1b
    800011da:	412686b3          	sub	a3,a3,s2
    800011de:	864a                	mv	a2,s2
    800011e0:	85ca                	mv	a1,s2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f38080e7          	jalr	-200(ra) # 8000111c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011ec:	4729                	li	a4,10
    800011ee:	6685                	lui	a3,0x1
    800011f0:	00006617          	auipc	a2,0x6
    800011f4:	e1060613          	addi	a2,a2,-496 # 80007000 <_trampoline>
    800011f8:	040005b7          	lui	a1,0x4000
    800011fc:	15fd                	addi	a1,a1,-1
    800011fe:	05b2                	slli	a1,a1,0xc
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f1a080e7          	jalr	-230(ra) # 8000111c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000120a:	8526                	mv	a0,s1
    8000120c:	00001097          	auipc	ra,0x1
    80001210:	89c080e7          	jalr	-1892(ra) # 80001aa8 <proc_mapstacks>
}
    80001214:	8526                	mv	a0,s1
    80001216:	60e2                	ld	ra,24(sp)
    80001218:	6442                	ld	s0,16(sp)
    8000121a:	64a2                	ld	s1,8(sp)
    8000121c:	6902                	ld	s2,0(sp)
    8000121e:	6105                	addi	sp,sp,32
    80001220:	8082                	ret

0000000080001222 <kvminit>:
{
    80001222:	1141                	addi	sp,sp,-16
    80001224:	e406                	sd	ra,8(sp)
    80001226:	e022                	sd	s0,0(sp)
    80001228:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000122a:	00000097          	auipc	ra,0x0
    8000122e:	f22080e7          	jalr	-222(ra) # 8000114c <kvmmake>
    80001232:	00008797          	auipc	a5,0x8
    80001236:	dea7b723          	sd	a0,-530(a5) # 80009020 <kernel_pagetable>
}
    8000123a:	60a2                	ld	ra,8(sp)
    8000123c:	6402                	ld	s0,0(sp)
    8000123e:	0141                	addi	sp,sp,16
    80001240:	8082                	ret

0000000080001242 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001242:	715d                	addi	sp,sp,-80
    80001244:	e486                	sd	ra,72(sp)
    80001246:	e0a2                	sd	s0,64(sp)
    80001248:	fc26                	sd	s1,56(sp)
    8000124a:	f84a                	sd	s2,48(sp)
    8000124c:	f44e                	sd	s3,40(sp)
    8000124e:	f052                	sd	s4,32(sp)
    80001250:	ec56                	sd	s5,24(sp)
    80001252:	e85a                	sd	s6,16(sp)
    80001254:	e45e                	sd	s7,8(sp)
    80001256:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001258:	03459793          	slli	a5,a1,0x34
    8000125c:	e795                	bnez	a5,80001288 <uvmunmap+0x46>
    8000125e:	8a2a                	mv	s4,a0
    80001260:	892e                	mv	s2,a1
    80001262:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001264:	0632                	slli	a2,a2,0xc
    80001266:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000126a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000126c:	6b05                	lui	s6,0x1
    8000126e:	0735e263          	bltu	a1,s3,800012d2 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001272:	60a6                	ld	ra,72(sp)
    80001274:	6406                	ld	s0,64(sp)
    80001276:	74e2                	ld	s1,56(sp)
    80001278:	7942                	ld	s2,48(sp)
    8000127a:	79a2                	ld	s3,40(sp)
    8000127c:	7a02                	ld	s4,32(sp)
    8000127e:	6ae2                	ld	s5,24(sp)
    80001280:	6b42                	ld	s6,16(sp)
    80001282:	6ba2                	ld	s7,8(sp)
    80001284:	6161                	addi	sp,sp,80
    80001286:	8082                	ret
    panic("uvmunmap: not aligned");
    80001288:	00007517          	auipc	a0,0x7
    8000128c:	e6050513          	addi	a0,a0,-416 # 800080e8 <digits+0xa8>
    80001290:	fffff097          	auipc	ra,0xfffff
    80001294:	29a080e7          	jalr	666(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001298:	00007517          	auipc	a0,0x7
    8000129c:	e6850513          	addi	a0,a0,-408 # 80008100 <digits+0xc0>
    800012a0:	fffff097          	auipc	ra,0xfffff
    800012a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e6850513          	addi	a0,a0,-408 # 80008110 <digits+0xd0>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	27a080e7          	jalr	634(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xe8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
    *pte = 0;
    800012c8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012cc:	995a                	add	s2,s2,s6
    800012ce:	fb3972e3          	bgeu	s2,s3,80001272 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012d2:	4601                	li	a2,0
    800012d4:	85ca                	mv	a1,s2
    800012d6:	8552                	mv	a0,s4
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	cce080e7          	jalr	-818(ra) # 80000fa6 <walk>
    800012e0:	84aa                	mv	s1,a0
    800012e2:	d95d                	beqz	a0,80001298 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012e4:	6108                	ld	a0,0(a0)
    800012e6:	00157793          	andi	a5,a0,1
    800012ea:	dfdd                	beqz	a5,800012a8 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012ec:	3ff57793          	andi	a5,a0,1023
    800012f0:	fd7784e3          	beq	a5,s7,800012b8 <uvmunmap+0x76>
    if(do_free){
    800012f4:	fc0a8ae3          	beqz	s5,800012c8 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	6da080e7          	jalr	1754(ra) # 800009d6 <kfree>
    80001304:	b7d1                	j	800012c8 <uvmunmap+0x86>

0000000080001306 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001306:	1101                	addi	sp,sp,-32
    80001308:	ec06                	sd	ra,24(sp)
    8000130a:	e822                	sd	s0,16(sp)
    8000130c:	e426                	sd	s1,8(sp)
    8000130e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001310:	fffff097          	auipc	ra,0xfffff
    80001314:	7c2080e7          	jalr	1986(ra) # 80000ad2 <kalloc>
    80001318:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000131a:	c519                	beqz	a0,80001328 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000131c:	6605                	lui	a2,0x1
    8000131e:	4581                	li	a1,0
    80001320:	00000097          	auipc	ra,0x0
    80001324:	99e080e7          	jalr	-1634(ra) # 80000cbe <memset>
  return pagetable;
}
    80001328:	8526                	mv	a0,s1
    8000132a:	60e2                	ld	ra,24(sp)
    8000132c:	6442                	ld	s0,16(sp)
    8000132e:	64a2                	ld	s1,8(sp)
    80001330:	6105                	addi	sp,sp,32
    80001332:	8082                	ret

0000000080001334 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001334:	7179                	addi	sp,sp,-48
    80001336:	f406                	sd	ra,40(sp)
    80001338:	f022                	sd	s0,32(sp)
    8000133a:	ec26                	sd	s1,24(sp)
    8000133c:	e84a                	sd	s2,16(sp)
    8000133e:	e44e                	sd	s3,8(sp)
    80001340:	e052                	sd	s4,0(sp)
    80001342:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001344:	6785                	lui	a5,0x1
    80001346:	04f67863          	bgeu	a2,a5,80001396 <uvminit+0x62>
    8000134a:	8a2a                	mv	s4,a0
    8000134c:	89ae                	mv	s3,a1
    8000134e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	782080e7          	jalr	1922(ra) # 80000ad2 <kalloc>
    80001358:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	960080e7          	jalr	-1696(ra) # 80000cbe <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001366:	4779                	li	a4,30
    80001368:	86ca                	mv	a3,s2
    8000136a:	6605                	lui	a2,0x1
    8000136c:	4581                	li	a1,0
    8000136e:	8552                	mv	a0,s4
    80001370:	00000097          	auipc	ra,0x0
    80001374:	d1e080e7          	jalr	-738(ra) # 8000108e <mappages>
  memmove(mem, src, sz);
    80001378:	8626                	mv	a2,s1
    8000137a:	85ce                	mv	a1,s3
    8000137c:	854a                	mv	a0,s2
    8000137e:	00000097          	auipc	ra,0x0
    80001382:	99c080e7          	jalr	-1636(ra) # 80000d1a <memmove>
}
    80001386:	70a2                	ld	ra,40(sp)
    80001388:	7402                	ld	s0,32(sp)
    8000138a:	64e2                	ld	s1,24(sp)
    8000138c:	6942                	ld	s2,16(sp)
    8000138e:	69a2                	ld	s3,8(sp)
    80001390:	6a02                	ld	s4,0(sp)
    80001392:	6145                	addi	sp,sp,48
    80001394:	8082                	ret
    panic("inituvm: more than a page");
    80001396:	00007517          	auipc	a0,0x7
    8000139a:	daa50513          	addi	a0,a0,-598 # 80008140 <digits+0x100>
    8000139e:	fffff097          	auipc	ra,0xfffff
    800013a2:	18c080e7          	jalr	396(ra) # 8000052a <panic>

00000000800013a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013a6:	1101                	addi	sp,sp,-32
    800013a8:	ec06                	sd	ra,24(sp)
    800013aa:	e822                	sd	s0,16(sp)
    800013ac:	e426                	sd	s1,8(sp)
    800013ae:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013b0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013b2:	00b67d63          	bgeu	a2,a1,800013cc <uvmdealloc+0x26>
    800013b6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013b8:	6785                	lui	a5,0x1
    800013ba:	17fd                	addi	a5,a5,-1
    800013bc:	00f60733          	add	a4,a2,a5
    800013c0:	767d                	lui	a2,0xfffff
    800013c2:	8f71                	and	a4,a4,a2
    800013c4:	97ae                	add	a5,a5,a1
    800013c6:	8ff1                	and	a5,a5,a2
    800013c8:	00f76863          	bltu	a4,a5,800013d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013cc:	8526                	mv	a0,s1
    800013ce:	60e2                	ld	ra,24(sp)
    800013d0:	6442                	ld	s0,16(sp)
    800013d2:	64a2                	ld	s1,8(sp)
    800013d4:	6105                	addi	sp,sp,32
    800013d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013d8:	8f99                	sub	a5,a5,a4
    800013da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013dc:	4685                	li	a3,1
    800013de:	0007861b          	sext.w	a2,a5
    800013e2:	85ba                	mv	a1,a4
    800013e4:	00000097          	auipc	ra,0x0
    800013e8:	e5e080e7          	jalr	-418(ra) # 80001242 <uvmunmap>
    800013ec:	b7c5                	j	800013cc <uvmdealloc+0x26>

00000000800013ee <uvmalloc>:
  if(newsz < oldsz)
    800013ee:	0ab66163          	bltu	a2,a1,80001490 <uvmalloc+0xa2>
{
    800013f2:	7139                	addi	sp,sp,-64
    800013f4:	fc06                	sd	ra,56(sp)
    800013f6:	f822                	sd	s0,48(sp)
    800013f8:	f426                	sd	s1,40(sp)
    800013fa:	f04a                	sd	s2,32(sp)
    800013fc:	ec4e                	sd	s3,24(sp)
    800013fe:	e852                	sd	s4,16(sp)
    80001400:	e456                	sd	s5,8(sp)
    80001402:	0080                	addi	s0,sp,64
    80001404:	8aaa                	mv	s5,a0
    80001406:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001408:	6985                	lui	s3,0x1
    8000140a:	19fd                	addi	s3,s3,-1
    8000140c:	95ce                	add	a1,a1,s3
    8000140e:	79fd                	lui	s3,0xfffff
    80001410:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001414:	08c9f063          	bgeu	s3,a2,80001494 <uvmalloc+0xa6>
    80001418:	894e                	mv	s2,s3
    mem = kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	6b8080e7          	jalr	1720(ra) # 80000ad2 <kalloc>
    80001422:	84aa                	mv	s1,a0
    if(mem == 0){
    80001424:	c51d                	beqz	a0,80001452 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001426:	6605                	lui	a2,0x1
    80001428:	4581                	li	a1,0
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	894080e7          	jalr	-1900(ra) # 80000cbe <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001432:	4779                	li	a4,30
    80001434:	86a6                	mv	a3,s1
    80001436:	6605                	lui	a2,0x1
    80001438:	85ca                	mv	a1,s2
    8000143a:	8556                	mv	a0,s5
    8000143c:	00000097          	auipc	ra,0x0
    80001440:	c52080e7          	jalr	-942(ra) # 8000108e <mappages>
    80001444:	e905                	bnez	a0,80001474 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001446:	6785                	lui	a5,0x1
    80001448:	993e                	add	s2,s2,a5
    8000144a:	fd4968e3          	bltu	s2,s4,8000141a <uvmalloc+0x2c>
  return newsz;
    8000144e:	8552                	mv	a0,s4
    80001450:	a809                	j	80001462 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001452:	864e                	mv	a2,s3
    80001454:	85ca                	mv	a1,s2
    80001456:	8556                	mv	a0,s5
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	f4e080e7          	jalr	-178(ra) # 800013a6 <uvmdealloc>
      return 0;
    80001460:	4501                	li	a0,0
}
    80001462:	70e2                	ld	ra,56(sp)
    80001464:	7442                	ld	s0,48(sp)
    80001466:	74a2                	ld	s1,40(sp)
    80001468:	7902                	ld	s2,32(sp)
    8000146a:	69e2                	ld	s3,24(sp)
    8000146c:	6a42                	ld	s4,16(sp)
    8000146e:	6aa2                	ld	s5,8(sp)
    80001470:	6121                	addi	sp,sp,64
    80001472:	8082                	ret
      kfree(mem);
    80001474:	8526                	mv	a0,s1
    80001476:	fffff097          	auipc	ra,0xfffff
    8000147a:	560080e7          	jalr	1376(ra) # 800009d6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000147e:	864e                	mv	a2,s3
    80001480:	85ca                	mv	a1,s2
    80001482:	8556                	mv	a0,s5
    80001484:	00000097          	auipc	ra,0x0
    80001488:	f22080e7          	jalr	-222(ra) # 800013a6 <uvmdealloc>
      return 0;
    8000148c:	4501                	li	a0,0
    8000148e:	bfd1                	j	80001462 <uvmalloc+0x74>
    return oldsz;
    80001490:	852e                	mv	a0,a1
}
    80001492:	8082                	ret
  return newsz;
    80001494:	8532                	mv	a0,a2
    80001496:	b7f1                	j	80001462 <uvmalloc+0x74>

0000000080001498 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
    800014a8:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014aa:	84aa                	mv	s1,a0
    800014ac:	6905                	lui	s2,0x1
    800014ae:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014b0:	4985                	li	s3,1
    800014b2:	a821                	j	800014ca <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014b4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014b6:	0532                	slli	a0,a0,0xc
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	fe0080e7          	jalr	-32(ra) # 80001498 <freewalk>
      pagetable[i] = 0;
    800014c0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014c4:	04a1                	addi	s1,s1,8
    800014c6:	03248163          	beq	s1,s2,800014e8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014ca:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014cc:	00f57793          	andi	a5,a0,15
    800014d0:	ff3782e3          	beq	a5,s3,800014b4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014d4:	8905                	andi	a0,a0,1
    800014d6:	d57d                	beqz	a0,800014c4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c8850513          	addi	a0,a0,-888 # 80008160 <digits+0x120>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	04a080e7          	jalr	74(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014e8:	8552                	mv	a0,s4
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4ec080e7          	jalr	1260(ra) # 800009d6 <kfree>
}
    800014f2:	70a2                	ld	ra,40(sp)
    800014f4:	7402                	ld	s0,32(sp)
    800014f6:	64e2                	ld	s1,24(sp)
    800014f8:	6942                	ld	s2,16(sp)
    800014fa:	69a2                	ld	s3,8(sp)
    800014fc:	6a02                	ld	s4,0(sp)
    800014fe:	6145                	addi	sp,sp,48
    80001500:	8082                	ret

0000000080001502 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001502:	1101                	addi	sp,sp,-32
    80001504:	ec06                	sd	ra,24(sp)
    80001506:	e822                	sd	s0,16(sp)
    80001508:	e426                	sd	s1,8(sp)
    8000150a:	1000                	addi	s0,sp,32
    8000150c:	84aa                	mv	s1,a0
  if(sz > 0)
    8000150e:	e999                	bnez	a1,80001524 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001510:	8526                	mv	a0,s1
    80001512:	00000097          	auipc	ra,0x0
    80001516:	f86080e7          	jalr	-122(ra) # 80001498 <freewalk>
}
    8000151a:	60e2                	ld	ra,24(sp)
    8000151c:	6442                	ld	s0,16(sp)
    8000151e:	64a2                	ld	s1,8(sp)
    80001520:	6105                	addi	sp,sp,32
    80001522:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001524:	6605                	lui	a2,0x1
    80001526:	167d                	addi	a2,a2,-1
    80001528:	962e                	add	a2,a2,a1
    8000152a:	4685                	li	a3,1
    8000152c:	8231                	srli	a2,a2,0xc
    8000152e:	4581                	li	a1,0
    80001530:	00000097          	auipc	ra,0x0
    80001534:	d12080e7          	jalr	-750(ra) # 80001242 <uvmunmap>
    80001538:	bfe1                	j	80001510 <uvmfree+0xe>

000000008000153a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000153a:	c679                	beqz	a2,80001608 <uvmcopy+0xce>
{
    8000153c:	715d                	addi	sp,sp,-80
    8000153e:	e486                	sd	ra,72(sp)
    80001540:	e0a2                	sd	s0,64(sp)
    80001542:	fc26                	sd	s1,56(sp)
    80001544:	f84a                	sd	s2,48(sp)
    80001546:	f44e                	sd	s3,40(sp)
    80001548:	f052                	sd	s4,32(sp)
    8000154a:	ec56                	sd	s5,24(sp)
    8000154c:	e85a                	sd	s6,16(sp)
    8000154e:	e45e                	sd	s7,8(sp)
    80001550:	0880                	addi	s0,sp,80
    80001552:	8b2a                	mv	s6,a0
    80001554:	8aae                	mv	s5,a1
    80001556:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001558:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000155a:	4601                	li	a2,0
    8000155c:	85ce                	mv	a1,s3
    8000155e:	855a                	mv	a0,s6
    80001560:	00000097          	auipc	ra,0x0
    80001564:	a46080e7          	jalr	-1466(ra) # 80000fa6 <walk>
    80001568:	c531                	beqz	a0,800015b4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000156a:	6118                	ld	a4,0(a0)
    8000156c:	00177793          	andi	a5,a4,1
    80001570:	cbb1                	beqz	a5,800015c4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001572:	00a75593          	srli	a1,a4,0xa
    80001576:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000157a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	554080e7          	jalr	1364(ra) # 80000ad2 <kalloc>
    80001586:	892a                	mv	s2,a0
    80001588:	c939                	beqz	a0,800015de <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000158a:	6605                	lui	a2,0x1
    8000158c:	85de                	mv	a1,s7
    8000158e:	fffff097          	auipc	ra,0xfffff
    80001592:	78c080e7          	jalr	1932(ra) # 80000d1a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001596:	8726                	mv	a4,s1
    80001598:	86ca                	mv	a3,s2
    8000159a:	6605                	lui	a2,0x1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	aee080e7          	jalr	-1298(ra) # 8000108e <mappages>
    800015a8:	e515                	bnez	a0,800015d4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015aa:	6785                	lui	a5,0x1
    800015ac:	99be                	add	s3,s3,a5
    800015ae:	fb49e6e3          	bltu	s3,s4,8000155a <uvmcopy+0x20>
    800015b2:	a081                	j	800015f2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015b4:	00007517          	auipc	a0,0x7
    800015b8:	bbc50513          	addi	a0,a0,-1092 # 80008170 <digits+0x130>
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	f6e080e7          	jalr	-146(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    800015c4:	00007517          	auipc	a0,0x7
    800015c8:	bcc50513          	addi	a0,a0,-1076 # 80008190 <digits+0x150>
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	f5e080e7          	jalr	-162(ra) # 8000052a <panic>
      kfree(mem);
    800015d4:	854a                	mv	a0,s2
    800015d6:	fffff097          	auipc	ra,0xfffff
    800015da:	400080e7          	jalr	1024(ra) # 800009d6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015de:	4685                	li	a3,1
    800015e0:	00c9d613          	srli	a2,s3,0xc
    800015e4:	4581                	li	a1,0
    800015e6:	8556                	mv	a0,s5
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	c5a080e7          	jalr	-934(ra) # 80001242 <uvmunmap>
  return -1;
    800015f0:	557d                	li	a0,-1
}
    800015f2:	60a6                	ld	ra,72(sp)
    800015f4:	6406                	ld	s0,64(sp)
    800015f6:	74e2                	ld	s1,56(sp)
    800015f8:	7942                	ld	s2,48(sp)
    800015fa:	79a2                	ld	s3,40(sp)
    800015fc:	7a02                	ld	s4,32(sp)
    800015fe:	6ae2                	ld	s5,24(sp)
    80001600:	6b42                	ld	s6,16(sp)
    80001602:	6ba2                	ld	s7,8(sp)
    80001604:	6161                	addi	sp,sp,80
    80001606:	8082                	ret
  return 0;
    80001608:	4501                	li	a0,0
}
    8000160a:	8082                	ret

000000008000160c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000160c:	1141                	addi	sp,sp,-16
    8000160e:	e406                	sd	ra,8(sp)
    80001610:	e022                	sd	s0,0(sp)
    80001612:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001614:	4601                	li	a2,0
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	990080e7          	jalr	-1648(ra) # 80000fa6 <walk>
  if(pte == 0)
    8000161e:	c901                	beqz	a0,8000162e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001620:	611c                	ld	a5,0(a0)
    80001622:	9bbd                	andi	a5,a5,-17
    80001624:	e11c                	sd	a5,0(a0)
}
    80001626:	60a2                	ld	ra,8(sp)
    80001628:	6402                	ld	s0,0(sp)
    8000162a:	0141                	addi	sp,sp,16
    8000162c:	8082                	ret
    panic("uvmclear");
    8000162e:	00007517          	auipc	a0,0x7
    80001632:	b8250513          	addi	a0,a0,-1150 # 800081b0 <digits+0x170>
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	ef4080e7          	jalr	-268(ra) # 8000052a <panic>

000000008000163e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000163e:	c6bd                	beqz	a3,800016ac <copyout+0x6e>
{
    80001640:	715d                	addi	sp,sp,-80
    80001642:	e486                	sd	ra,72(sp)
    80001644:	e0a2                	sd	s0,64(sp)
    80001646:	fc26                	sd	s1,56(sp)
    80001648:	f84a                	sd	s2,48(sp)
    8000164a:	f44e                	sd	s3,40(sp)
    8000164c:	f052                	sd	s4,32(sp)
    8000164e:	ec56                	sd	s5,24(sp)
    80001650:	e85a                	sd	s6,16(sp)
    80001652:	e45e                	sd	s7,8(sp)
    80001654:	e062                	sd	s8,0(sp)
    80001656:	0880                	addi	s0,sp,80
    80001658:	8b2a                	mv	s6,a0
    8000165a:	8c2e                	mv	s8,a1
    8000165c:	8a32                	mv	s4,a2
    8000165e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001660:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001662:	6a85                	lui	s5,0x1
    80001664:	a015                	j	80001688 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001666:	9562                	add	a0,a0,s8
    80001668:	0004861b          	sext.w	a2,s1
    8000166c:	85d2                	mv	a1,s4
    8000166e:	41250533          	sub	a0,a0,s2
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	6a8080e7          	jalr	1704(ra) # 80000d1a <memmove>

    len -= n;
    8000167a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000167e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001680:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001684:	02098263          	beqz	s3,800016a8 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001688:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000168c:	85ca                	mv	a1,s2
    8000168e:	855a                	mv	a0,s6
    80001690:	00000097          	auipc	ra,0x0
    80001694:	9bc080e7          	jalr	-1604(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001698:	cd01                	beqz	a0,800016b0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000169a:	418904b3          	sub	s1,s2,s8
    8000169e:	94d6                	add	s1,s1,s5
    if(n > len)
    800016a0:	fc99f3e3          	bgeu	s3,s1,80001666 <copyout+0x28>
    800016a4:	84ce                	mv	s1,s3
    800016a6:	b7c1                	j	80001666 <copyout+0x28>
  }
  return 0;
    800016a8:	4501                	li	a0,0
    800016aa:	a021                	j	800016b2 <copyout+0x74>
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret
      return -1;
    800016b0:	557d                	li	a0,-1
}
    800016b2:	60a6                	ld	ra,72(sp)
    800016b4:	6406                	ld	s0,64(sp)
    800016b6:	74e2                	ld	s1,56(sp)
    800016b8:	7942                	ld	s2,48(sp)
    800016ba:	79a2                	ld	s3,40(sp)
    800016bc:	7a02                	ld	s4,32(sp)
    800016be:	6ae2                	ld	s5,24(sp)
    800016c0:	6b42                	ld	s6,16(sp)
    800016c2:	6ba2                	ld	s7,8(sp)
    800016c4:	6c02                	ld	s8,0(sp)
    800016c6:	6161                	addi	sp,sp,80
    800016c8:	8082                	ret

00000000800016ca <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016ca:	caa5                	beqz	a3,8000173a <copyin+0x70>
{
    800016cc:	715d                	addi	sp,sp,-80
    800016ce:	e486                	sd	ra,72(sp)
    800016d0:	e0a2                	sd	s0,64(sp)
    800016d2:	fc26                	sd	s1,56(sp)
    800016d4:	f84a                	sd	s2,48(sp)
    800016d6:	f44e                	sd	s3,40(sp)
    800016d8:	f052                	sd	s4,32(sp)
    800016da:	ec56                	sd	s5,24(sp)
    800016dc:	e85a                	sd	s6,16(sp)
    800016de:	e45e                	sd	s7,8(sp)
    800016e0:	e062                	sd	s8,0(sp)
    800016e2:	0880                	addi	s0,sp,80
    800016e4:	8b2a                	mv	s6,a0
    800016e6:	8a2e                	mv	s4,a1
    800016e8:	8c32                	mv	s8,a2
    800016ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ee:	6a85                	lui	s5,0x1
    800016f0:	a01d                	j	80001716 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016f2:	018505b3          	add	a1,a0,s8
    800016f6:	0004861b          	sext.w	a2,s1
    800016fa:	412585b3          	sub	a1,a1,s2
    800016fe:	8552                	mv	a0,s4
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	61a080e7          	jalr	1562(ra) # 80000d1a <memmove>

    len -= n;
    80001708:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000170c:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000170e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001712:	02098263          	beqz	s3,80001736 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001716:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000171a:	85ca                	mv	a1,s2
    8000171c:	855a                	mv	a0,s6
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	92e080e7          	jalr	-1746(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    80001726:	cd01                	beqz	a0,8000173e <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001728:	418904b3          	sub	s1,s2,s8
    8000172c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000172e:	fc99f2e3          	bgeu	s3,s1,800016f2 <copyin+0x28>
    80001732:	84ce                	mv	s1,s3
    80001734:	bf7d                	j	800016f2 <copyin+0x28>
  }
  return 0;
    80001736:	4501                	li	a0,0
    80001738:	a021                	j	80001740 <copyin+0x76>
    8000173a:	4501                	li	a0,0
}
    8000173c:	8082                	ret
      return -1;
    8000173e:	557d                	li	a0,-1
}
    80001740:	60a6                	ld	ra,72(sp)
    80001742:	6406                	ld	s0,64(sp)
    80001744:	74e2                	ld	s1,56(sp)
    80001746:	7942                	ld	s2,48(sp)
    80001748:	79a2                	ld	s3,40(sp)
    8000174a:	7a02                	ld	s4,32(sp)
    8000174c:	6ae2                	ld	s5,24(sp)
    8000174e:	6b42                	ld	s6,16(sp)
    80001750:	6ba2                	ld	s7,8(sp)
    80001752:	6c02                	ld	s8,0(sp)
    80001754:	6161                	addi	sp,sp,80
    80001756:	8082                	ret

0000000080001758 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001758:	c6c5                	beqz	a3,80001800 <copyinstr+0xa8>
{
    8000175a:	715d                	addi	sp,sp,-80
    8000175c:	e486                	sd	ra,72(sp)
    8000175e:	e0a2                	sd	s0,64(sp)
    80001760:	fc26                	sd	s1,56(sp)
    80001762:	f84a                	sd	s2,48(sp)
    80001764:	f44e                	sd	s3,40(sp)
    80001766:	f052                	sd	s4,32(sp)
    80001768:	ec56                	sd	s5,24(sp)
    8000176a:	e85a                	sd	s6,16(sp)
    8000176c:	e45e                	sd	s7,8(sp)
    8000176e:	0880                	addi	s0,sp,80
    80001770:	8a2a                	mv	s4,a0
    80001772:	8b2e                	mv	s6,a1
    80001774:	8bb2                	mv	s7,a2
    80001776:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001778:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000177a:	6985                	lui	s3,0x1
    8000177c:	a035                	j	800017a8 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000177e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001782:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001784:	0017b793          	seqz	a5,a5
    80001788:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
    srcva = va0 + PGSIZE;
    800017a2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017a6:	c8a9                	beqz	s1,800017f8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017a8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ac:	85ca                	mv	a1,s2
    800017ae:	8552                	mv	a0,s4
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	89c080e7          	jalr	-1892(ra) # 8000104c <walkaddr>
    if(pa0 == 0)
    800017b8:	c131                	beqz	a0,800017fc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ba:	41790833          	sub	a6,s2,s7
    800017be:	984e                	add	a6,a6,s3
    if(n > max)
    800017c0:	0104f363          	bgeu	s1,a6,800017c6 <copyinstr+0x6e>
    800017c4:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017c6:	955e                	add	a0,a0,s7
    800017c8:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017cc:	fc080be3          	beqz	a6,800017a2 <copyinstr+0x4a>
    800017d0:	985a                	add	a6,a6,s6
    800017d2:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017d4:	41650633          	sub	a2,a0,s6
    800017d8:	14fd                	addi	s1,s1,-1
    800017da:	9b26                	add	s6,s6,s1
    800017dc:	00f60733          	add	a4,a2,a5
    800017e0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd3000>
    800017e4:	df49                	beqz	a4,8000177e <copyinstr+0x26>
        *dst = *p;
    800017e6:	00e78023          	sb	a4,0(a5)
      --max;
    800017ea:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ee:	0785                	addi	a5,a5,1
    while(n > 0){
    800017f0:	ff0796e3          	bne	a5,a6,800017dc <copyinstr+0x84>
      dst++;
    800017f4:	8b42                	mv	s6,a6
    800017f6:	b775                	j	800017a2 <copyinstr+0x4a>
    800017f8:	4781                	li	a5,0
    800017fa:	b769                	j	80001784 <copyinstr+0x2c>
      return -1;
    800017fc:	557d                	li	a0,-1
    800017fe:	b779                	j	8000178c <copyinstr+0x34>
  int got_null = 0;
    80001800:	4781                	li	a5,0
  if(got_null){
    80001802:	0017b793          	seqz	a5,a5
    80001806:	40f00533          	neg	a0,a5
}
    8000180a:	8082                	ret

000000008000180c <find_file_to_remove>:

int find_file_to_remove(){
    8000180c:	1101                	addi	sp,sp,-32
    8000180e:	ec06                	sd	ra,24(sp)
    80001810:	e822                	sd	s0,16(sp)
    80001812:	e426                	sd	s1,8(sp)
    80001814:	e04a                	sd	s2,0(sp)
    80001816:	1000                	addi	s0,sp,32
  for(int i=0; i<32; i++){
    80001818:	4481                	li	s1,0
    8000181a:	02000913          	li	s2,32
    if(myproc()->paging_meta_data[i].in_memory){
    8000181e:	00000097          	auipc	ra,0x0
    80001822:	3fc080e7          	jalr	1020(ra) # 80001c1a <myproc>
    80001826:	00149793          	slli	a5,s1,0x1
    8000182a:	97a6                	add	a5,a5,s1
    8000182c:	078a                	slli	a5,a5,0x2
    8000182e:	97aa                	add	a5,a5,a0
    80001830:	1787a783          	lw	a5,376(a5)
    80001834:	e789                	bnez	a5,8000183e <find_file_to_remove+0x32>
  for(int i=0; i<32; i++){
    80001836:	2485                	addiw	s1,s1,1
    80001838:	ff2493e3          	bne	s1,s2,8000181e <find_file_to_remove+0x12>
      return i; 
    }
  }
  return 0;
    8000183c:	84be                	mv	s1,a5
}
    8000183e:	8526                	mv	a0,s1
    80001840:	60e2                	ld	ra,24(sp)
    80001842:	6442                	ld	s0,16(sp)
    80001844:	64a2                	ld	s1,8(sp)
    80001846:	6902                	ld	s2,0(sp)
    80001848:	6105                	addi	sp,sp,32
    8000184a:	8082                	ret

000000008000184c <swap_page_into_file>:

void swap_page_into_file(int offset){
    8000184c:	7139                	addi	sp,sp,-64
    8000184e:	fc06                	sd	ra,56(sp)
    80001850:	f822                	sd	s0,48(sp)
    80001852:	f426                	sd	s1,40(sp)
    80001854:	f04a                	sd	s2,32(sp)
    80001856:	ec4e                	sd	s3,24(sp)
    80001858:	e852                	sd	s4,16(sp)
    8000185a:	e456                	sd	s5,8(sp)
    8000185c:	0080                	addi	s0,sp,64
    8000185e:	8a2a                	mv	s4,a0
    struct proc * p = myproc();
    80001860:	00000097          	auipc	ra,0x0
    80001864:	3ba080e7          	jalr	954(ra) # 80001c1a <myproc>
    80001868:	84aa                	mv	s1,a0
    int remove_file_indx = find_file_to_remove();
    8000186a:	00000097          	auipc	ra,0x0
    8000186e:	fa2080e7          	jalr	-94(ra) # 8000180c <find_file_to_remove>
    80001872:	892a                	mv	s2,a0
    uint64 removed_page_VA = remove_file_indx*PGSIZE;
    printf("chosen file %d \n", remove_file_indx);
    80001874:	85aa                	mv	a1,a0
    80001876:	00007517          	auipc	a0,0x7
    8000187a:	94a50513          	addi	a0,a0,-1718 # 800081c0 <digits+0x180>
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	cf6080e7          	jalr	-778(ra) # 80000574 <printf>
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    80001886:	4601                	li	a2,0
    80001888:	00c9159b          	slliw	a1,s2,0xc
    8000188c:	68a8                	ld	a0,80(s1)
    8000188e:	fffff097          	auipc	ra,0xfffff
    80001892:	718080e7          	jalr	1816(ra) # 80000fa6 <walk>
    80001896:	89aa                	mv	s3,a0
    //write the information from this file to memory
    uint64 physical_addr = PTE2PA(*out_page_entry);
    if(writeToSwapFile(p,(char*)PA2PTE(physical_addr),offset,PGSIZE) ==  -1)
    80001898:	00053a83          	ld	s5,0(a0)
    8000189c:	77fd                	lui	a5,0xfffff
    8000189e:	8389                	srli	a5,a5,0x2
    800018a0:	00fafab3          	and	s5,s5,a5
    800018a4:	6685                	lui	a3,0x1
    800018a6:	8652                	mv	a2,s4
    800018a8:	85d6                	mv	a1,s5
    800018aa:	8526                	mv	a0,s1
    800018ac:	00003097          	auipc	ra,0x3
    800018b0:	bf2080e7          	jalr	-1038(ra) # 8000449e <writeToSwapFile>
    800018b4:	57fd                	li	a5,-1
    800018b6:	04f50263          	beq	a0,a5,800018fa <swap_page_into_file+0xae>
      panic("write to file failed");
    //free the RAM memmory of the swapped page
    kfree((void*)PA2PTE(physical_addr));
    800018ba:	8556                	mv	a0,s5
    800018bc:	fffff097          	auipc	ra,0xfffff
    800018c0:	11a080e7          	jalr	282(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    800018c4:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
    800018c8:	bfe7f793          	andi	a5,a5,-1026
    800018cc:	4007e793          	ori	a5,a5,1024
    800018d0:	00f9b023          	sd	a5,0(s3)
    p->paging_meta_data[remove_file_indx].offset = offset;
    800018d4:	00191793          	slli	a5,s2,0x1
    800018d8:	01278733          	add	a4,a5,s2
    800018dc:	070a                	slli	a4,a4,0x2
    800018de:	9726                	add	a4,a4,s1
    800018e0:	17472823          	sw	s4,368(a4)
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    800018e4:	16072c23          	sw	zero,376(a4)
      
}
    800018e8:	70e2                	ld	ra,56(sp)
    800018ea:	7442                	ld	s0,48(sp)
    800018ec:	74a2                	ld	s1,40(sp)
    800018ee:	7902                	ld	s2,32(sp)
    800018f0:	69e2                	ld	s3,24(sp)
    800018f2:	6a42                	ld	s4,16(sp)
    800018f4:	6aa2                	ld	s5,8(sp)
    800018f6:	6121                	addi	sp,sp,64
    800018f8:	8082                	ret
      panic("write to file failed");
    800018fa:	00007517          	auipc	a0,0x7
    800018fe:	8de50513          	addi	a0,a0,-1826 # 800081d8 <digits+0x198>
    80001902:	fffff097          	auipc	ra,0xfffff
    80001906:	c28080e7          	jalr	-984(ra) # 8000052a <panic>

000000008000190a <get_num_of_pages_in_memory>:

int get_num_of_pages_in_memory(){
    8000190a:	7179                	addi	sp,sp,-48
    8000190c:	f406                	sd	ra,40(sp)
    8000190e:	f022                	sd	s0,32(sp)
    80001910:	ec26                	sd	s1,24(sp)
    80001912:	e84a                	sd	s2,16(sp)
    80001914:	e44e                	sd	s3,8(sp)
    80001916:	1800                	addi	s0,sp,48
  int counter = 0;
  for(int i=0; i<32; i++){
    80001918:	4481                	li	s1,0
  int counter = 0;
    8000191a:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    8000191c:	02000993          	li	s3,32
    80001920:	a021                	j	80001928 <get_num_of_pages_in_memory+0x1e>
    80001922:	2485                	addiw	s1,s1,1
    80001924:	03348063          	beq	s1,s3,80001944 <get_num_of_pages_in_memory+0x3a>
    if(myproc()->paging_meta_data[i].in_memory)
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	2f2080e7          	jalr	754(ra) # 80001c1a <myproc>
    80001930:	00149793          	slli	a5,s1,0x1
    80001934:	97a6                	add	a5,a5,s1
    80001936:	078a                	slli	a5,a5,0x2
    80001938:	97aa                	add	a5,a5,a0
    8000193a:	1787a783          	lw	a5,376(a5) # fffffffffffff178 <end+0xffffffff7ffd3178>
    8000193e:	d3f5                	beqz	a5,80001922 <get_num_of_pages_in_memory+0x18>
      counter = counter+1;
    80001940:	2905                	addiw	s2,s2,1
    80001942:	b7c5                	j	80001922 <get_num_of_pages_in_memory+0x18>
  }
  return counter; 
}
    80001944:	854a                	mv	a0,s2
    80001946:	70a2                	ld	ra,40(sp)
    80001948:	7402                	ld	s0,32(sp)
    8000194a:	64e2                	ld	s1,24(sp)
    8000194c:	6942                	ld	s2,16(sp)
    8000194e:	69a2                	ld	s3,8(sp)
    80001950:	6145                	addi	sp,sp,48
    80001952:	8082                	ret

0000000080001954 <page_in>:

void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    80001954:	7139                	addi	sp,sp,-64
    80001956:	fc06                	sd	ra,56(sp)
    80001958:	f822                	sd	s0,48(sp)
    8000195a:	f426                	sd	s1,40(sp)
    8000195c:	f04a                	sd	s2,32(sp)
    8000195e:	ec4e                	sd	s3,24(sp)
    80001960:	e852                	sd	s4,16(sp)
    80001962:	e456                	sd	s5,8(sp)
    80001964:	0080                	addi	s0,sp,64
    80001966:	89ae                	mv	s3,a1
  //get the page number of the missing in ram page
  int current_page_number = PGROUNDDOWN(faulting_address)/PGSIZE;
    80001968:	8131                	srli	a0,a0,0xc
    8000196a:	0005091b          	sext.w	s2,a0
  //get its offset in the saved file
  uint offset = myproc()->paging_meta_data[current_page_number].offset;
    8000196e:	00000097          	auipc	ra,0x0
    80001972:	2ac080e7          	jalr	684(ra) # 80001c1a <myproc>
    80001976:	00191793          	slli	a5,s2,0x1
    8000197a:	97ca                	add	a5,a5,s2
    8000197c:	078a                	slli	a5,a5,0x2
    8000197e:	97aa                	add	a5,a5,a0
    80001980:	1707aa83          	lw	s5,368(a5)
    80001984:	000a8a1b          	sext.w	s4,s5
  if(offset == -1){
    80001988:	57fd                	li	a5,-1
    8000198a:	08fa0563          	beq	s4,a5,80001a14 <page_in+0xc0>
    panic("offset is -1");
  }
  //allocate a buffer for the information from the file
  char* read_buffer;
  if((read_buffer = kalloc()) == 0)
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	144080e7          	jalr	324(ra) # 80000ad2 <kalloc>
    80001996:	84aa                	mv	s1,a0
    80001998:	c551                	beqz	a0,80001a24 <page_in+0xd0>
    panic("not enough space to kalloc");
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    8000199a:	00000097          	auipc	ra,0x0
    8000199e:	280080e7          	jalr	640(ra) # 80001c1a <myproc>
    800019a2:	6685                	lui	a3,0x1
    800019a4:	8652                	mv	a2,s4
    800019a6:	85a6                	mv	a1,s1
    800019a8:	00003097          	auipc	ra,0x3
    800019ac:	b1a080e7          	jalr	-1254(ra) # 800044c2 <readFromSwapFile>
    800019b0:	57fd                	li	a5,-1
    800019b2:	08f50163          	beq	a0,a5,80001a34 <page_in+0xe0>
    panic("read from file failed");
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    800019b6:	00000097          	auipc	ra,0x0
    800019ba:	f54080e7          	jalr	-172(ra) # 8000190a <get_num_of_pages_in_memory>
    800019be:	47bd                	li	a5,15
    800019c0:	08a7c263          	blt	a5,a0,80001a44 <page_in+0xf0>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    *missing_pte_entry = PTE2PA((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
  }  

  else{
      *missing_pte_entry = PTE2PA((uint64)read_buffer) | PTE_V; 
    800019c4:	80a9                	srli	s1,s1,0xa
    800019c6:	04b2                	slli	s1,s1,0xc
    800019c8:	0014e493          	ori	s1,s1,1
    800019cc:	0099b023          	sd	s1,0(s3)
  }
  //update offsets and aging of the files
  //myproc()->paging_meta_data[current_num_pages].aging = init_aging(current_num_pages);
  myproc()->paging_meta_data[current_page_number].offset = -1;
    800019d0:	00000097          	auipc	ra,0x0
    800019d4:	24a080e7          	jalr	586(ra) # 80001c1a <myproc>
    800019d8:	00191493          	slli	s1,s2,0x1
    800019dc:	012487b3          	add	a5,s1,s2
    800019e0:	078a                	slli	a5,a5,0x2
    800019e2:	953e                	add	a0,a0,a5
    800019e4:	57fd                	li	a5,-1
    800019e6:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_number].in_memory = 1;
    800019ea:	00000097          	auipc	ra,0x0
    800019ee:	230080e7          	jalr	560(ra) # 80001c1a <myproc>
    800019f2:	94ca                	add	s1,s1,s2
    800019f4:	048a                	slli	s1,s1,0x2
    800019f6:	94aa                	add	s1,s1,a0
    800019f8:	4785                	li	a5,1
    800019fa:	16f4ac23          	sw	a5,376(s1)
    800019fe:	12000073          	sfence.vma
  sfence_vma(); //refresh TLB
}
    80001a02:	70e2                	ld	ra,56(sp)
    80001a04:	7442                	ld	s0,48(sp)
    80001a06:	74a2                	ld	s1,40(sp)
    80001a08:	7902                	ld	s2,32(sp)
    80001a0a:	69e2                	ld	s3,24(sp)
    80001a0c:	6a42                	ld	s4,16(sp)
    80001a0e:	6aa2                	ld	s5,8(sp)
    80001a10:	6121                	addi	sp,sp,64
    80001a12:	8082                	ret
    panic("offset is -1");
    80001a14:	00006517          	auipc	a0,0x6
    80001a18:	7dc50513          	addi	a0,a0,2012 # 800081f0 <digits+0x1b0>
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	b0e080e7          	jalr	-1266(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    80001a24:	00006517          	auipc	a0,0x6
    80001a28:	7dc50513          	addi	a0,a0,2012 # 80008200 <digits+0x1c0>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	afe080e7          	jalr	-1282(ra) # 8000052a <panic>
    panic("read from file failed");
    80001a34:	00006517          	auipc	a0,0x6
    80001a38:	7ec50513          	addi	a0,a0,2028 # 80008220 <digits+0x1e0>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	aee080e7          	jalr	-1298(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    80001a44:	8556                	mv	a0,s5
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	e06080e7          	jalr	-506(ra) # 8000184c <swap_page_into_file>
    *missing_pte_entry = PTE2PA((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    80001a4e:	80a9                	srli	s1,s1,0xa
    80001a50:	04b2                	slli	s1,s1,0xc
    80001a52:	0009b783          	ld	a5,0(s3)
    80001a56:	3fe7f793          	andi	a5,a5,1022
    80001a5a:	8cdd                	or	s1,s1,a5
    80001a5c:	0014e493          	ori	s1,s1,1
    80001a60:	0099b023          	sd	s1,0(s3)
    80001a64:	b7b5                	j	800019d0 <page_in+0x7c>

0000000080001a66 <check_page_fault>:

void check_page_fault(){
    80001a66:	1101                	addi	sp,sp,-32
    80001a68:	ec06                	sd	ra,24(sp)
    80001a6a:	e822                	sd	s0,16(sp)
    80001a6c:	e426                	sd	s1,8(sp)
    80001a6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001a70:	143024f3          	csrr	s1,stval
  uint64 faulting_address = r_stval(); 
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80001a74:	00000097          	auipc	ra,0x0
    80001a78:	1a6080e7          	jalr	422(ra) # 80001c1a <myproc>
    80001a7c:	4601                	li	a2,0
    80001a7e:	75fd                	lui	a1,0xfffff
    80001a80:	8de5                	and	a1,a1,s1
    80001a82:	6928                	ld	a0,80(a0)
    80001a84:	fffff097          	auipc	ra,0xfffff
    80001a88:	522080e7          	jalr	1314(ra) # 80000fa6 <walk>
  else if(!(*pte_entry & PTE_W)& (*pte_entry & PTE_COW)){
     cprintf("Page Fault- COPY ON WRITE\n");
     create_write_through(faulting_address, pte_entry);
  }*/
  else{
    printf("went to file without permissions!!! %d\n", faulting_address);
    80001a8c:	85a6                	mv	a1,s1
    80001a8e:	00006517          	auipc	a0,0x6
    80001a92:	7aa50513          	addi	a0,a0,1962 # 80008238 <digits+0x1f8>
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	ade080e7          	jalr	-1314(ra) # 80000574 <printf>
  }
}
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret

0000000080001aa8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001aa8:	7139                	addi	sp,sp,-64
    80001aaa:	fc06                	sd	ra,56(sp)
    80001aac:	f822                	sd	s0,48(sp)
    80001aae:	f426                	sd	s1,40(sp)
    80001ab0:	f04a                	sd	s2,32(sp)
    80001ab2:	ec4e                	sd	s3,24(sp)
    80001ab4:	e852                	sd	s4,16(sp)
    80001ab6:	e456                	sd	s5,8(sp)
    80001ab8:	e05a                	sd	s6,0(sp)
    80001aba:	0080                	addi	s0,sp,64
    80001abc:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001abe:	00010497          	auipc	s1,0x10
    80001ac2:	c1248493          	addi	s1,s1,-1006 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ac6:	8b26                	mv	s6,s1
    80001ac8:	00006a97          	auipc	s5,0x6
    80001acc:	538a8a93          	addi	s5,s5,1336 # 80008000 <etext>
    80001ad0:	04000937          	lui	s2,0x4000
    80001ad4:	197d                	addi	s2,s2,-1
    80001ad6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad8:	0001ba17          	auipc	s4,0x1b
    80001adc:	7f8a0a13          	addi	s4,s4,2040 # 8001d2d0 <tickslock>
    char *pa = kalloc();
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	ff2080e7          	jalr	-14(ra) # 80000ad2 <kalloc>
    80001ae8:	862a                	mv	a2,a0
    if(pa == 0)
    80001aea:	c131                	beqz	a0,80001b2e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001aec:	416485b3          	sub	a1,s1,s6
    80001af0:	8591                	srai	a1,a1,0x4
    80001af2:	000ab783          	ld	a5,0(s5)
    80001af6:	02f585b3          	mul	a1,a1,a5
    80001afa:	2585                	addiw	a1,a1,1
    80001afc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b00:	4719                	li	a4,6
    80001b02:	6685                	lui	a3,0x1
    80001b04:	40b905b3          	sub	a1,s2,a1
    80001b08:	854e                	mv	a0,s3
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	612080e7          	jalr	1554(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b12:	2f048493          	addi	s1,s1,752
    80001b16:	fd4495e3          	bne	s1,s4,80001ae0 <proc_mapstacks+0x38>
  }
}
    80001b1a:	70e2                	ld	ra,56(sp)
    80001b1c:	7442                	ld	s0,48(sp)
    80001b1e:	74a2                	ld	s1,40(sp)
    80001b20:	7902                	ld	s2,32(sp)
    80001b22:	69e2                	ld	s3,24(sp)
    80001b24:	6a42                	ld	s4,16(sp)
    80001b26:	6aa2                	ld	s5,8(sp)
    80001b28:	6b02                	ld	s6,0(sp)
    80001b2a:	6121                	addi	sp,sp,64
    80001b2c:	8082                	ret
      panic("kalloc");
    80001b2e:	00006517          	auipc	a0,0x6
    80001b32:	73250513          	addi	a0,a0,1842 # 80008260 <digits+0x220>
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	9f4080e7          	jalr	-1548(ra) # 8000052a <panic>

0000000080001b3e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b3e:	7139                	addi	sp,sp,-64
    80001b40:	fc06                	sd	ra,56(sp)
    80001b42:	f822                	sd	s0,48(sp)
    80001b44:	f426                	sd	s1,40(sp)
    80001b46:	f04a                	sd	s2,32(sp)
    80001b48:	ec4e                	sd	s3,24(sp)
    80001b4a:	e852                	sd	s4,16(sp)
    80001b4c:	e456                	sd	s5,8(sp)
    80001b4e:	e05a                	sd	s6,0(sp)
    80001b50:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001b52:	00006597          	auipc	a1,0x6
    80001b56:	71658593          	addi	a1,a1,1814 # 80008268 <digits+0x228>
    80001b5a:	0000f517          	auipc	a0,0xf
    80001b5e:	74650513          	addi	a0,a0,1862 # 800112a0 <pid_lock>
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	fd0080e7          	jalr	-48(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b6a:	00006597          	auipc	a1,0x6
    80001b6e:	70658593          	addi	a1,a1,1798 # 80008270 <digits+0x230>
    80001b72:	0000f517          	auipc	a0,0xf
    80001b76:	74650513          	addi	a0,a0,1862 # 800112b8 <wait_lock>
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	fb8080e7          	jalr	-72(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b82:	00010497          	auipc	s1,0x10
    80001b86:	b4e48493          	addi	s1,s1,-1202 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001b8a:	00006b17          	auipc	s6,0x6
    80001b8e:	6f6b0b13          	addi	s6,s6,1782 # 80008280 <digits+0x240>
      p->kstack = KSTACK((int) (p - proc));
    80001b92:	8aa6                	mv	s5,s1
    80001b94:	00006a17          	auipc	s4,0x6
    80001b98:	46ca0a13          	addi	s4,s4,1132 # 80008000 <etext>
    80001b9c:	04000937          	lui	s2,0x4000
    80001ba0:	197d                	addi	s2,s2,-1
    80001ba2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ba4:	0001b997          	auipc	s3,0x1b
    80001ba8:	72c98993          	addi	s3,s3,1836 # 8001d2d0 <tickslock>
      initlock(&p->lock, "proc");
    80001bac:	85da                	mv	a1,s6
    80001bae:	8526                	mv	a0,s1
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	f82080e7          	jalr	-126(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bb8:	415487b3          	sub	a5,s1,s5
    80001bbc:	8791                	srai	a5,a5,0x4
    80001bbe:	000a3703          	ld	a4,0(s4)
    80001bc2:	02e787b3          	mul	a5,a5,a4
    80001bc6:	2785                	addiw	a5,a5,1
    80001bc8:	00d7979b          	slliw	a5,a5,0xd
    80001bcc:	40f907b3          	sub	a5,s2,a5
    80001bd0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	2f048493          	addi	s1,s1,752
    80001bd6:	fd349be3          	bne	s1,s3,80001bac <procinit+0x6e>
  }
}
    80001bda:	70e2                	ld	ra,56(sp)
    80001bdc:	7442                	ld	s0,48(sp)
    80001bde:	74a2                	ld	s1,40(sp)
    80001be0:	7902                	ld	s2,32(sp)
    80001be2:	69e2                	ld	s3,24(sp)
    80001be4:	6a42                	ld	s4,16(sp)
    80001be6:	6aa2                	ld	s5,8(sp)
    80001be8:	6b02                	ld	s6,0(sp)
    80001bea:	6121                	addi	sp,sp,64
    80001bec:	8082                	ret

0000000080001bee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bee:	1141                	addi	sp,sp,-16
    80001bf0:	e422                	sd	s0,8(sp)
    80001bf2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bf4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bf6:	2501                	sext.w	a0,a0
    80001bf8:	6422                	ld	s0,8(sp)
    80001bfa:	0141                	addi	sp,sp,16
    80001bfc:	8082                	ret

0000000080001bfe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bfe:	1141                	addi	sp,sp,-16
    80001c00:	e422                	sd	s0,8(sp)
    80001c02:	0800                	addi	s0,sp,16
    80001c04:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c06:	2781                	sext.w	a5,a5
    80001c08:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c0a:	0000f517          	auipc	a0,0xf
    80001c0e:	6c650513          	addi	a0,a0,1734 # 800112d0 <cpus>
    80001c12:	953e                	add	a0,a0,a5
    80001c14:	6422                	ld	s0,8(sp)
    80001c16:	0141                	addi	sp,sp,16
    80001c18:	8082                	ret

0000000080001c1a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c1a:	1101                	addi	sp,sp,-32
    80001c1c:	ec06                	sd	ra,24(sp)
    80001c1e:	e822                	sd	s0,16(sp)
    80001c20:	e426                	sd	s1,8(sp)
    80001c22:	1000                	addi	s0,sp,32
  push_off();
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	f52080e7          	jalr	-174(ra) # 80000b76 <push_off>
    80001c2c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c2e:	2781                	sext.w	a5,a5
    80001c30:	079e                	slli	a5,a5,0x7
    80001c32:	0000f717          	auipc	a4,0xf
    80001c36:	66e70713          	addi	a4,a4,1646 # 800112a0 <pid_lock>
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	fd8080e7          	jalr	-40(ra) # 80000c16 <pop_off>
  return p;
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret

0000000080001c52 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c52:	1141                	addi	sp,sp,-16
    80001c54:	e406                	sd	ra,8(sp)
    80001c56:	e022                	sd	s0,0(sp)
    80001c58:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	fc0080e7          	jalr	-64(ra) # 80001c1a <myproc>
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	014080e7          	jalr	20(ra) # 80000c76 <release>

  if (first) {
    80001c6a:	00007797          	auipc	a5,0x7
    80001c6e:	ca67a783          	lw	a5,-858(a5) # 80008910 <first.1>
    80001c72:	eb89                	bnez	a5,80001c84 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c74:	00001097          	auipc	ra,0x1
    80001c78:	db6080e7          	jalr	-586(ra) # 80002a2a <usertrapret>
}
    80001c7c:	60a2                	ld	ra,8(sp)
    80001c7e:	6402                	ld	s0,0(sp)
    80001c80:	0141                	addi	sp,sp,16
    80001c82:	8082                	ret
    first = 0;
    80001c84:	00007797          	auipc	a5,0x7
    80001c88:	c807a623          	sw	zero,-884(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001c8c:	4505                	li	a0,1
    80001c8e:	00002097          	auipc	ra,0x2
    80001c92:	ade080e7          	jalr	-1314(ra) # 8000376c <fsinit>
    80001c96:	bff9                	j	80001c74 <forkret+0x22>

0000000080001c98 <allocpid>:
allocpid() {
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	e04a                	sd	s2,0(sp)
    80001ca2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ca4:	0000f917          	auipc	s2,0xf
    80001ca8:	5fc90913          	addi	s2,s2,1532 # 800112a0 <pid_lock>
    80001cac:	854a                	mv	a0,s2
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	f14080e7          	jalr	-236(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001cb6:	00007797          	auipc	a5,0x7
    80001cba:	c5e78793          	addi	a5,a5,-930 # 80008914 <nextpid>
    80001cbe:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cc0:	0014871b          	addiw	a4,s1,1
    80001cc4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cc6:	854a                	mv	a0,s2
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fae080e7          	jalr	-82(ra) # 80000c76 <release>
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <proc_pagetable>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	e04a                	sd	s2,0(sp)
    80001ce8:	1000                	addi	s0,sp,32
    80001cea:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	61a080e7          	jalr	1562(ra) # 80001306 <uvmcreate>
    80001cf4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cf6:	c121                	beqz	a0,80001d36 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cf8:	4729                	li	a4,10
    80001cfa:	00005697          	auipc	a3,0x5
    80001cfe:	30668693          	addi	a3,a3,774 # 80007000 <_trampoline>
    80001d02:	6605                	lui	a2,0x1
    80001d04:	040005b7          	lui	a1,0x4000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b2                	slli	a1,a1,0xc
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	382080e7          	jalr	898(ra) # 8000108e <mappages>
    80001d14:	02054863          	bltz	a0,80001d44 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d18:	4719                	li	a4,6
    80001d1a:	05893683          	ld	a3,88(s2)
    80001d1e:	6605                	lui	a2,0x1
    80001d20:	020005b7          	lui	a1,0x2000
    80001d24:	15fd                	addi	a1,a1,-1
    80001d26:	05b6                	slli	a1,a1,0xd
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	364080e7          	jalr	868(ra) # 8000108e <mappages>
    80001d32:	02054163          	bltz	a0,80001d54 <proc_pagetable+0x76>
}
    80001d36:	8526                	mv	a0,s1
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6902                	ld	s2,0(sp)
    80001d40:	6105                	addi	sp,sp,32
    80001d42:	8082                	ret
    uvmfree(pagetable, 0);
    80001d44:	4581                	li	a1,0
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	7ba080e7          	jalr	1978(ra) # 80001502 <uvmfree>
    return 0;
    80001d50:	4481                	li	s1,0
    80001d52:	b7d5                	j	80001d36 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d54:	4681                	li	a3,0
    80001d56:	4605                	li	a2,1
    80001d58:	040005b7          	lui	a1,0x4000
    80001d5c:	15fd                	addi	a1,a1,-1
    80001d5e:	05b2                	slli	a1,a1,0xc
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	4e0080e7          	jalr	1248(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d6a:	4581                	li	a1,0
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	fffff097          	auipc	ra,0xfffff
    80001d72:	794080e7          	jalr	1940(ra) # 80001502 <uvmfree>
    return 0;
    80001d76:	4481                	li	s1,0
    80001d78:	bf7d                	j	80001d36 <proc_pagetable+0x58>

0000000080001d7a <proc_freepagetable>:
{
    80001d7a:	1101                	addi	sp,sp,-32
    80001d7c:	ec06                	sd	ra,24(sp)
    80001d7e:	e822                	sd	s0,16(sp)
    80001d80:	e426                	sd	s1,8(sp)
    80001d82:	e04a                	sd	s2,0(sp)
    80001d84:	1000                	addi	s0,sp,32
    80001d86:	84aa                	mv	s1,a0
    80001d88:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d8a:	4681                	li	a3,0
    80001d8c:	4605                	li	a2,1
    80001d8e:	040005b7          	lui	a1,0x4000
    80001d92:	15fd                	addi	a1,a1,-1
    80001d94:	05b2                	slli	a1,a1,0xc
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	4ac080e7          	jalr	1196(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d9e:	4681                	li	a3,0
    80001da0:	4605                	li	a2,1
    80001da2:	020005b7          	lui	a1,0x2000
    80001da6:	15fd                	addi	a1,a1,-1
    80001da8:	05b6                	slli	a1,a1,0xd
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	496080e7          	jalr	1174(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001db4:	85ca                	mv	a1,s2
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	74a080e7          	jalr	1866(ra) # 80001502 <uvmfree>
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6902                	ld	s2,0(sp)
    80001dc8:	6105                	addi	sp,sp,32
    80001dca:	8082                	ret

0000000080001dcc <freeproc>:
{ 
    80001dcc:	1101                	addi	sp,sp,-32
    80001dce:	ec06                	sd	ra,24(sp)
    80001dd0:	e822                	sd	s0,16(sp)
    80001dd2:	e426                	sd	s1,8(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dd8:	6d28                	ld	a0,88(a0)
    80001dda:	c509                	beqz	a0,80001de4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	bfa080e7          	jalr	-1030(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001de4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001de8:	68a8                	ld	a0,80(s1)
    80001dea:	c511                	beqz	a0,80001df6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dec:	64ac                	ld	a1,72(s1)
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	f8c080e7          	jalr	-116(ra) # 80001d7a <proc_freepagetable>
  p->pagetable = 0;
    80001df6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001dfe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e16:	0004ac23          	sw	zero,24(s1)
}
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6105                	addi	sp,sp,32
    80001e22:	8082                	ret

0000000080001e24 <allocproc>:
{
    80001e24:	7179                	addi	sp,sp,-48
    80001e26:	f406                	sd	ra,40(sp)
    80001e28:	f022                	sd	s0,32(sp)
    80001e2a:	ec26                	sd	s1,24(sp)
    80001e2c:	e84a                	sd	s2,16(sp)
    80001e2e:	e44e                	sd	s3,8(sp)
    80001e30:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e32:	00010497          	auipc	s1,0x10
    80001e36:	89e48493          	addi	s1,s1,-1890 # 800116d0 <proc>
    80001e3a:	0001b997          	auipc	s3,0x1b
    80001e3e:	49698993          	addi	s3,s3,1174 # 8001d2d0 <tickslock>
    acquire(&p->lock);
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	d7e080e7          	jalr	-642(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001e4c:	4c9c                	lw	a5,24(s1)
    80001e4e:	cf81                	beqz	a5,80001e66 <allocproc+0x42>
      release(&p->lock);
    80001e50:	8526                	mv	a0,s1
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	e24080e7          	jalr	-476(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e5a:	2f048493          	addi	s1,s1,752
    80001e5e:	ff3492e3          	bne	s1,s3,80001e42 <allocproc+0x1e>
  return 0;
    80001e62:	4481                	li	s1,0
    80001e64:	a0b5                	j	80001ed0 <allocproc+0xac>
  p->pid = allocpid();
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	e32080e7          	jalr	-462(ra) # 80001c98 <allocpid>
    80001e6e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e70:	4785                	li	a5,1
    80001e72:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	c5e080e7          	jalr	-930(ra) # 80000ad2 <kalloc>
    80001e7c:	89aa                	mv	s3,a0
    80001e7e:	eca8                	sd	a0,88(s1)
    80001e80:	c125                	beqz	a0,80001ee0 <allocproc+0xbc>
  p->pagetable = proc_pagetable(p);
    80001e82:	8526                	mv	a0,s1
    80001e84:	00000097          	auipc	ra,0x0
    80001e88:	e5a080e7          	jalr	-422(ra) # 80001cde <proc_pagetable>
    80001e8c:	89aa                	mv	s3,a0
    80001e8e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e90:	c525                	beqz	a0,80001ef8 <allocproc+0xd4>
  memset(&p->context, 0, sizeof(p->context));
    80001e92:	07000613          	li	a2,112
    80001e96:	4581                	li	a1,0
    80001e98:	06048513          	addi	a0,s1,96
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	e22080e7          	jalr	-478(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001ea4:	00000797          	auipc	a5,0x0
    80001ea8:	dae78793          	addi	a5,a5,-594 # 80001c52 <forkret>
    80001eac:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eae:	60bc                	ld	a5,64(s1)
    80001eb0:	6705                	lui	a4,0x1
    80001eb2:	97ba                	add	a5,a5,a4
    80001eb4:	f4bc                	sd	a5,104(s1)
 for(int i=0;i<32;i++){
    80001eb6:	17048793          	addi	a5,s1,368
    80001eba:	2f048713          	addi	a4,s1,752
    p->paging_meta_data[i].offset = -1;
    80001ebe:	56fd                	li	a3,-1
    80001ec0:	c394                	sw	a3,0(a5)
    p->paging_meta_data[i].aging = 0;
    80001ec2:	0007a223          	sw	zero,4(a5)
    p->paging_meta_data[i].in_memory = 0;
    80001ec6:	0007a423          	sw	zero,8(a5)
 for(int i=0;i<32;i++){
    80001eca:	07b1                	addi	a5,a5,12
    80001ecc:	fee79ae3          	bne	a5,a4,80001ec0 <allocproc+0x9c>
}
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	70a2                	ld	ra,40(sp)
    80001ed4:	7402                	ld	s0,32(sp)
    80001ed6:	64e2                	ld	s1,24(sp)
    80001ed8:	6942                	ld	s2,16(sp)
    80001eda:	69a2                	ld	s3,8(sp)
    80001edc:	6145                	addi	sp,sp,48
    80001ede:	8082                	ret
    freeproc(p);
    80001ee0:	8526                	mv	a0,s1
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	eea080e7          	jalr	-278(ra) # 80001dcc <freeproc>
    release(&p->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	d8a080e7          	jalr	-630(ra) # 80000c76 <release>
    return 0;
    80001ef4:	84ce                	mv	s1,s3
    80001ef6:	bfe9                	j	80001ed0 <allocproc+0xac>
    freeproc(p);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	00000097          	auipc	ra,0x0
    80001efe:	ed2080e7          	jalr	-302(ra) # 80001dcc <freeproc>
    release(&p->lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	d72080e7          	jalr	-654(ra) # 80000c76 <release>
    return 0;
    80001f0c:	84ce                	mv	s1,s3
    80001f0e:	b7c9                	j	80001ed0 <allocproc+0xac>

0000000080001f10 <userinit>:
{
    80001f10:	1101                	addi	sp,sp,-32
    80001f12:	ec06                	sd	ra,24(sp)
    80001f14:	e822                	sd	s0,16(sp)
    80001f16:	e426                	sd	s1,8(sp)
    80001f18:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f1a:	00000097          	auipc	ra,0x0
    80001f1e:	f0a080e7          	jalr	-246(ra) # 80001e24 <allocproc>
    80001f22:	84aa                	mv	s1,a0
  initproc = p;
    80001f24:	00007797          	auipc	a5,0x7
    80001f28:	10a7b223          	sd	a0,260(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f2c:	03400613          	li	a2,52
    80001f30:	00007597          	auipc	a1,0x7
    80001f34:	9f058593          	addi	a1,a1,-1552 # 80008920 <initcode>
    80001f38:	6928                	ld	a0,80(a0)
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	3fa080e7          	jalr	1018(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001f42:	6785                	lui	a5,0x1
    80001f44:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f46:	6cb8                	ld	a4,88(s1)
    80001f48:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f4c:	6cb8                	ld	a4,88(s1)
    80001f4e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f50:	4641                	li	a2,16
    80001f52:	00006597          	auipc	a1,0x6
    80001f56:	33658593          	addi	a1,a1,822 # 80008288 <digits+0x248>
    80001f5a:	15848513          	addi	a0,s1,344
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	eb2080e7          	jalr	-334(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001f66:	00006517          	auipc	a0,0x6
    80001f6a:	33250513          	addi	a0,a0,818 # 80008298 <digits+0x258>
    80001f6e:	00002097          	auipc	ra,0x2
    80001f72:	22c080e7          	jalr	556(ra) # 8000419a <namei>
    80001f76:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f7a:	478d                	li	a5,3
    80001f7c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f7e:	8526                	mv	a0,s1
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	cf6080e7          	jalr	-778(ra) # 80000c76 <release>
}
    80001f88:	60e2                	ld	ra,24(sp)
    80001f8a:	6442                	ld	s0,16(sp)
    80001f8c:	64a2                	ld	s1,8(sp)
    80001f8e:	6105                	addi	sp,sp,32
    80001f90:	8082                	ret

0000000080001f92 <growproc>:
{
    80001f92:	1101                	addi	sp,sp,-32
    80001f94:	ec06                	sd	ra,24(sp)
    80001f96:	e822                	sd	s0,16(sp)
    80001f98:	e426                	sd	s1,8(sp)
    80001f9a:	e04a                	sd	s2,0(sp)
    80001f9c:	1000                	addi	s0,sp,32
    80001f9e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	c7a080e7          	jalr	-902(ra) # 80001c1a <myproc>
    80001fa8:	892a                	mv	s2,a0
  sz = p->sz;
    80001faa:	652c                	ld	a1,72(a0)
    80001fac:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fb0:	00904f63          	bgtz	s1,80001fce <growproc+0x3c>
  } else if(n < 0){
    80001fb4:	0204cc63          	bltz	s1,80001fec <growproc+0x5a>
  p->sz = sz;
    80001fb8:	1602                	slli	a2,a2,0x20
    80001fba:	9201                	srli	a2,a2,0x20
    80001fbc:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fc0:	4501                	li	a0,0
}
    80001fc2:	60e2                	ld	ra,24(sp)
    80001fc4:	6442                	ld	s0,16(sp)
    80001fc6:	64a2                	ld	s1,8(sp)
    80001fc8:	6902                	ld	s2,0(sp)
    80001fca:	6105                	addi	sp,sp,32
    80001fcc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fce:	9e25                	addw	a2,a2,s1
    80001fd0:	1602                	slli	a2,a2,0x20
    80001fd2:	9201                	srli	a2,a2,0x20
    80001fd4:	1582                	slli	a1,a1,0x20
    80001fd6:	9181                	srli	a1,a1,0x20
    80001fd8:	6928                	ld	a0,80(a0)
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	414080e7          	jalr	1044(ra) # 800013ee <uvmalloc>
    80001fe2:	0005061b          	sext.w	a2,a0
    80001fe6:	fa69                	bnez	a2,80001fb8 <growproc+0x26>
      return -1;
    80001fe8:	557d                	li	a0,-1
    80001fea:	bfe1                	j	80001fc2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fec:	9e25                	addw	a2,a2,s1
    80001fee:	1602                	slli	a2,a2,0x20
    80001ff0:	9201                	srli	a2,a2,0x20
    80001ff2:	1582                	slli	a1,a1,0x20
    80001ff4:	9181                	srli	a1,a1,0x20
    80001ff6:	6928                	ld	a0,80(a0)
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	3ae080e7          	jalr	942(ra) # 800013a6 <uvmdealloc>
    80002000:	0005061b          	sext.w	a2,a0
    80002004:	bf55                	j	80001fb8 <growproc+0x26>

0000000080002006 <copy_swap_file>:
copy_swap_file(struct proc* child){
    80002006:	7139                	addi	sp,sp,-64
    80002008:	fc06                	sd	ra,56(sp)
    8000200a:	f822                	sd	s0,48(sp)
    8000200c:	f426                	sd	s1,40(sp)
    8000200e:	f04a                	sd	s2,32(sp)
    80002010:	ec4e                	sd	s3,24(sp)
    80002012:	e852                	sd	s4,16(sp)
    80002014:	e456                	sd	s5,8(sp)
    80002016:	e05a                	sd	s6,0(sp)
    80002018:	0080                	addi	s0,sp,64
    8000201a:	8b2a                	mv	s6,a0
  struct proc * pParent = myproc();
    8000201c:	00000097          	auipc	ra,0x0
    80002020:	bfe080e7          	jalr	-1026(ra) # 80001c1a <myproc>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    80002024:	653c                	ld	a5,72(a0)
    80002026:	cfd9                	beqz	a5,800020c4 <copy_swap_file+0xbe>
    80002028:	8a2a                	mv	s4,a0
    8000202a:	4481                	li	s1,0
    if(offset != -1){
    8000202c:	5afd                	li	s5,-1
    8000202e:	a83d                	j	8000206c <copy_swap_file+0x66>
      panic("not enough space to kalloc");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	1d050513          	addi	a0,a0,464 # 80008200 <digits+0x1c0>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	4f2080e7          	jalr	1266(ra) # 8000052a <panic>
          panic("read failed\n");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	26050513          	addi	a0,a0,608 # 800082a0 <digits+0x260>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4e2080e7          	jalr	1250(ra) # 8000052a <panic>
          panic("write failed\n");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	26050513          	addi	a0,a0,608 # 800082b0 <digits+0x270>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4d2080e7          	jalr	1234(ra) # 8000052a <panic>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    80002060:	6785                	lui	a5,0x1
    80002062:	94be                	add	s1,s1,a5
    80002064:	048a3783          	ld	a5,72(s4)
    80002068:	04f4fe63          	bgeu	s1,a5,800020c4 <copy_swap_file+0xbe>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    8000206c:	00c4d713          	srli	a4,s1,0xc
    80002070:	00171793          	slli	a5,a4,0x1
    80002074:	97ba                	add	a5,a5,a4
    80002076:	078a                	slli	a5,a5,0x2
    80002078:	97d2                	add	a5,a5,s4
    8000207a:	1707a903          	lw	s2,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    8000207e:	ff5901e3          	beq	s2,s5,80002060 <copy_swap_file+0x5a>
      if((buffer = kalloc()) == 0)
    80002082:	fffff097          	auipc	ra,0xfffff
    80002086:	a50080e7          	jalr	-1456(ra) # 80000ad2 <kalloc>
    8000208a:	89aa                	mv	s3,a0
    8000208c:	d155                	beqz	a0,80002030 <copy_swap_file+0x2a>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    8000208e:	2901                	sext.w	s2,s2
    80002090:	6685                	lui	a3,0x1
    80002092:	864a                	mv	a2,s2
    80002094:	85aa                	mv	a1,a0
    80002096:	8552                	mv	a0,s4
    80002098:	00002097          	auipc	ra,0x2
    8000209c:	42a080e7          	jalr	1066(ra) # 800044c2 <readFromSwapFile>
    800020a0:	fb5500e3          	beq	a0,s5,80002040 <copy_swap_file+0x3a>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    800020a4:	6685                	lui	a3,0x1
    800020a6:	864a                	mv	a2,s2
    800020a8:	85ce                	mv	a1,s3
    800020aa:	855a                	mv	a0,s6
    800020ac:	00002097          	auipc	ra,0x2
    800020b0:	3f2080e7          	jalr	1010(ra) # 8000449e <writeToSwapFile>
    800020b4:	f9550ee3          	beq	a0,s5,80002050 <copy_swap_file+0x4a>
      kfree(buffer);
    800020b8:	854e                	mv	a0,s3
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	91c080e7          	jalr	-1764(ra) # 800009d6 <kfree>
    800020c2:	bf79                	j	80002060 <copy_swap_file+0x5a>
}
    800020c4:	70e2                	ld	ra,56(sp)
    800020c6:	7442                	ld	s0,48(sp)
    800020c8:	74a2                	ld	s1,40(sp)
    800020ca:	7902                	ld	s2,32(sp)
    800020cc:	69e2                	ld	s3,24(sp)
    800020ce:	6a42                	ld	s4,16(sp)
    800020d0:	6aa2                	ld	s5,8(sp)
    800020d2:	6b02                	ld	s6,0(sp)
    800020d4:	6121                	addi	sp,sp,64
    800020d6:	8082                	ret

00000000800020d8 <fork>:
{
    800020d8:	715d                	addi	sp,sp,-80
    800020da:	e486                	sd	ra,72(sp)
    800020dc:	e0a2                	sd	s0,64(sp)
    800020de:	fc26                	sd	s1,56(sp)
    800020e0:	f84a                	sd	s2,48(sp)
    800020e2:	f44e                	sd	s3,40(sp)
    800020e4:	f052                	sd	s4,32(sp)
    800020e6:	ec56                	sd	s5,24(sp)
    800020e8:	e85a                	sd	s6,16(sp)
    800020ea:	e45e                	sd	s7,8(sp)
    800020ec:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	b2c080e7          	jalr	-1236(ra) # 80001c1a <myproc>
    800020f6:	8b2a                	mv	s6,a0
  if((np = allocproc()) == 0){
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	d2c080e7          	jalr	-724(ra) # 80001e24 <allocproc>
    80002100:	1a050a63          	beqz	a0,800022b4 <fork+0x1dc>
    80002104:	8aaa                	mv	s5,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002106:	048b3603          	ld	a2,72(s6)
    8000210a:	692c                	ld	a1,80(a0)
    8000210c:	050b3503          	ld	a0,80(s6)
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	42a080e7          	jalr	1066(ra) # 8000153a <uvmcopy>
    80002118:	04054863          	bltz	a0,80002168 <fork+0x90>
  np->sz = p->sz;
    8000211c:	048b3783          	ld	a5,72(s6)
    80002120:	04fab423          	sd	a5,72(s5)
  *(np->trapframe) = *(p->trapframe);
    80002124:	058b3683          	ld	a3,88(s6)
    80002128:	87b6                	mv	a5,a3
    8000212a:	058ab703          	ld	a4,88(s5)
    8000212e:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002132:	0007b803          	ld	a6,0(a5)
    80002136:	6788                	ld	a0,8(a5)
    80002138:	6b8c                	ld	a1,16(a5)
    8000213a:	6f90                	ld	a2,24(a5)
    8000213c:	01073023          	sd	a6,0(a4)
    80002140:	e708                	sd	a0,8(a4)
    80002142:	eb0c                	sd	a1,16(a4)
    80002144:	ef10                	sd	a2,24(a4)
    80002146:	02078793          	addi	a5,a5,32
    8000214a:	02070713          	addi	a4,a4,32
    8000214e:	fed792e3          	bne	a5,a3,80002132 <fork+0x5a>
  np->trapframe->a0 = 0;
    80002152:	058ab783          	ld	a5,88(s5)
    80002156:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    8000215a:	0d0b0493          	addi	s1,s6,208
    8000215e:	0d0a8913          	addi	s2,s5,208
    80002162:	150b0993          	addi	s3,s6,336
    80002166:	a03d                	j	80002194 <fork+0xbc>
    freeproc(np);
    80002168:	8556                	mv	a0,s5
    8000216a:	00000097          	auipc	ra,0x0
    8000216e:	c62080e7          	jalr	-926(ra) # 80001dcc <freeproc>
    release(&np->lock);
    80002172:	8556                	mv	a0,s5
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b02080e7          	jalr	-1278(ra) # 80000c76 <release>
    return -1;
    8000217c:	5bfd                	li	s7,-1
    8000217e:	a8dd                	j	80002274 <fork+0x19c>
      np->ofile[i] = filedup(p->ofile[i]);
    80002180:	00003097          	auipc	ra,0x3
    80002184:	9c6080e7          	jalr	-1594(ra) # 80004b46 <filedup>
    80002188:	00a93023          	sd	a0,0(s2)
  for(i = 0; i < NOFILE; i++)
    8000218c:	04a1                	addi	s1,s1,8
    8000218e:	0921                	addi	s2,s2,8
    80002190:	01348563          	beq	s1,s3,8000219a <fork+0xc2>
    if(p->ofile[i])
    80002194:	6088                	ld	a0,0(s1)
    80002196:	f56d                	bnez	a0,80002180 <fork+0xa8>
    80002198:	bfd5                	j	8000218c <fork+0xb4>
  np->cwd = idup(p->cwd);
    8000219a:	150b3503          	ld	a0,336(s6)
    8000219e:	00002097          	auipc	ra,0x2
    800021a2:	808080e7          	jalr	-2040(ra) # 800039a6 <idup>
    800021a6:	14aab823          	sd	a0,336(s5)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021aa:	4641                	li	a2,16
    800021ac:	158b0593          	addi	a1,s6,344
    800021b0:	158a8513          	addi	a0,s5,344
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	c5c080e7          	jalr	-932(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    800021bc:	030aab83          	lw	s7,48(s5)
  release(&np->lock);
    800021c0:	8556                	mv	a0,s5
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	ab4080e7          	jalr	-1356(ra) # 80000c76 <release>
  if(np->pid >2){
    800021ca:	030aa703          	lw	a4,48(s5)
    800021ce:	4789                	li	a5,2
    800021d0:	0ae7ce63          	blt	a5,a4,8000228c <fork+0x1b4>
  if(p->pid > 2){ 
    800021d4:	030b2703          	lw	a4,48(s6)
    800021d8:	4789                	li	a5,2
    800021da:	0ce7c763          	blt	a5,a4,800022a8 <fork+0x1d0>
  for(int i=0; i<32; i++){
    800021de:	170a8993          	addi	s3,s5,368
{
    800021e2:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    800021e4:	02000a13          	li	s4,32
    np->paging_meta_data[i].offset = myproc()->paging_meta_data[i].offset;
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	a32080e7          	jalr	-1486(ra) # 80001c1a <myproc>
    800021f0:	00191493          	slli	s1,s2,0x1
    800021f4:	012487b3          	add	a5,s1,s2
    800021f8:	078a                	slli	a5,a5,0x2
    800021fa:	953e                	add	a0,a0,a5
    800021fc:	17052783          	lw	a5,368(a0)
    80002200:	00f9a023          	sw	a5,0(s3)
    np->paging_meta_data[i].aging = myproc()->paging_meta_data[i].aging;
    80002204:	00000097          	auipc	ra,0x0
    80002208:	a16080e7          	jalr	-1514(ra) # 80001c1a <myproc>
    8000220c:	012487b3          	add	a5,s1,s2
    80002210:	078a                	slli	a5,a5,0x2
    80002212:	953e                	add	a0,a0,a5
    80002214:	17452783          	lw	a5,372(a0)
    80002218:	00f9a223          	sw	a5,4(s3)
    np->paging_meta_data[i].in_memory = myproc()->paging_meta_data[i].in_memory;
    8000221c:	00000097          	auipc	ra,0x0
    80002220:	9fe080e7          	jalr	-1538(ra) # 80001c1a <myproc>
    80002224:	94ca                	add	s1,s1,s2
    80002226:	048a                	slli	s1,s1,0x2
    80002228:	94aa                	add	s1,s1,a0
    8000222a:	1784a783          	lw	a5,376(s1)
    8000222e:	00f9a423          	sw	a5,8(s3)
  for(int i=0; i<32; i++){
    80002232:	2905                	addiw	s2,s2,1
    80002234:	09b1                	addi	s3,s3,12
    80002236:	fb4919e3          	bne	s2,s4,800021e8 <fork+0x110>
  acquire(&wait_lock);
    8000223a:	0000f497          	auipc	s1,0xf
    8000223e:	07e48493          	addi	s1,s1,126 # 800112b8 <wait_lock>
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	97e080e7          	jalr	-1666(ra) # 80000bc2 <acquire>
  np->parent = p;
    8000224c:	036abc23          	sd	s6,56(s5)
  release(&wait_lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a24080e7          	jalr	-1500(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000225a:	8556                	mv	a0,s5
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	966080e7          	jalr	-1690(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002264:	478d                	li	a5,3
    80002266:	00faac23          	sw	a5,24(s5)
  release(&np->lock);
    8000226a:	8556                	mv	a0,s5
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	a0a080e7          	jalr	-1526(ra) # 80000c76 <release>
}
    80002274:	855e                	mv	a0,s7
    80002276:	60a6                	ld	ra,72(sp)
    80002278:	6406                	ld	s0,64(sp)
    8000227a:	74e2                	ld	s1,56(sp)
    8000227c:	7942                	ld	s2,48(sp)
    8000227e:	79a2                	ld	s3,40(sp)
    80002280:	7a02                	ld	s4,32(sp)
    80002282:	6ae2                	ld	s5,24(sp)
    80002284:	6b42                	ld	s6,16(sp)
    80002286:	6ba2                	ld	s7,8(sp)
    80002288:	6161                	addi	sp,sp,80
    8000228a:	8082                	ret
    if(createSwapFile(np) != 0){
    8000228c:	8556                	mv	a0,s5
    8000228e:	00002097          	auipc	ra,0x2
    80002292:	160080e7          	jalr	352(ra) # 800043ee <createSwapFile>
    80002296:	dd1d                	beqz	a0,800021d4 <fork+0xfc>
      panic("create swap file failed");
    80002298:	00006517          	auipc	a0,0x6
    8000229c:	02850513          	addi	a0,a0,40 # 800082c0 <digits+0x280>
    800022a0:	ffffe097          	auipc	ra,0xffffe
    800022a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
    copy_swap_file(np);
    800022a8:	8556                	mv	a0,s5
    800022aa:	00000097          	auipc	ra,0x0
    800022ae:	d5c080e7          	jalr	-676(ra) # 80002006 <copy_swap_file>
    800022b2:	b735                	j	800021de <fork+0x106>
    return -1;
    800022b4:	5bfd                	li	s7,-1
    800022b6:	bf7d                	j	80002274 <fork+0x19c>

00000000800022b8 <scheduler>:
{
    800022b8:	7139                	addi	sp,sp,-64
    800022ba:	fc06                	sd	ra,56(sp)
    800022bc:	f822                	sd	s0,48(sp)
    800022be:	f426                	sd	s1,40(sp)
    800022c0:	f04a                	sd	s2,32(sp)
    800022c2:	ec4e                	sd	s3,24(sp)
    800022c4:	e852                	sd	s4,16(sp)
    800022c6:	e456                	sd	s5,8(sp)
    800022c8:	e05a                	sd	s6,0(sp)
    800022ca:	0080                	addi	s0,sp,64
    800022cc:	8792                	mv	a5,tp
  int id = r_tp();
    800022ce:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022d0:	00779a93          	slli	s5,a5,0x7
    800022d4:	0000f717          	auipc	a4,0xf
    800022d8:	fcc70713          	addi	a4,a4,-52 # 800112a0 <pid_lock>
    800022dc:	9756                	add	a4,a4,s5
    800022de:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800022e2:	0000f717          	auipc	a4,0xf
    800022e6:	ff670713          	addi	a4,a4,-10 # 800112d8 <cpus+0x8>
    800022ea:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800022ec:	498d                	li	s3,3
        p->state = RUNNING;
    800022ee:	4b11                	li	s6,4
        c->proc = p;
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	0000fa17          	auipc	s4,0xf
    800022f6:	faea0a13          	addi	s4,s4,-82 # 800112a0 <pid_lock>
    800022fa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022fc:	0001b917          	auipc	s2,0x1b
    80002300:	fd490913          	addi	s2,s2,-44 # 8001d2d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002304:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002308:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000230c:	10079073          	csrw	sstatus,a5
    80002310:	0000f497          	auipc	s1,0xf
    80002314:	3c048493          	addi	s1,s1,960 # 800116d0 <proc>
    80002318:	a811                	j	8000232c <scheduler+0x74>
      release(&p->lock);
    8000231a:	8526                	mv	a0,s1
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	95a080e7          	jalr	-1702(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002324:	2f048493          	addi	s1,s1,752
    80002328:	fd248ee3          	beq	s1,s2,80002304 <scheduler+0x4c>
      acquire(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	894080e7          	jalr	-1900(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80002336:	4c9c                	lw	a5,24(s1)
    80002338:	ff3791e3          	bne	a5,s3,8000231a <scheduler+0x62>
        p->state = RUNNING;
    8000233c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002340:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002344:	06048593          	addi	a1,s1,96
    80002348:	8556                	mv	a0,s5
    8000234a:	00000097          	auipc	ra,0x0
    8000234e:	636080e7          	jalr	1590(ra) # 80002980 <swtch>
        c->proc = 0;
    80002352:	020a3823          	sd	zero,48(s4)
    80002356:	b7d1                	j	8000231a <scheduler+0x62>

0000000080002358 <sched>:
{
    80002358:	7179                	addi	sp,sp,-48
    8000235a:	f406                	sd	ra,40(sp)
    8000235c:	f022                	sd	s0,32(sp)
    8000235e:	ec26                	sd	s1,24(sp)
    80002360:	e84a                	sd	s2,16(sp)
    80002362:	e44e                	sd	s3,8(sp)
    80002364:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002366:	00000097          	auipc	ra,0x0
    8000236a:	8b4080e7          	jalr	-1868(ra) # 80001c1a <myproc>
    8000236e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	7d8080e7          	jalr	2008(ra) # 80000b48 <holding>
    80002378:	c93d                	beqz	a0,800023ee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000237a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000237c:	2781                	sext.w	a5,a5
    8000237e:	079e                	slli	a5,a5,0x7
    80002380:	0000f717          	auipc	a4,0xf
    80002384:	f2070713          	addi	a4,a4,-224 # 800112a0 <pid_lock>
    80002388:	97ba                	add	a5,a5,a4
    8000238a:	0a87a703          	lw	a4,168(a5)
    8000238e:	4785                	li	a5,1
    80002390:	06f71763          	bne	a4,a5,800023fe <sched+0xa6>
  if(p->state == RUNNING)
    80002394:	4c98                	lw	a4,24(s1)
    80002396:	4791                	li	a5,4
    80002398:	06f70b63          	beq	a4,a5,8000240e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000239c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023a0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023a2:	efb5                	bnez	a5,8000241e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023a4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023a6:	0000f917          	auipc	s2,0xf
    800023aa:	efa90913          	addi	s2,s2,-262 # 800112a0 <pid_lock>
    800023ae:	2781                	sext.w	a5,a5
    800023b0:	079e                	slli	a5,a5,0x7
    800023b2:	97ca                	add	a5,a5,s2
    800023b4:	0ac7a983          	lw	s3,172(a5)
    800023b8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023ba:	2781                	sext.w	a5,a5
    800023bc:	079e                	slli	a5,a5,0x7
    800023be:	0000f597          	auipc	a1,0xf
    800023c2:	f1a58593          	addi	a1,a1,-230 # 800112d8 <cpus+0x8>
    800023c6:	95be                	add	a1,a1,a5
    800023c8:	06048513          	addi	a0,s1,96
    800023cc:	00000097          	auipc	ra,0x0
    800023d0:	5b4080e7          	jalr	1460(ra) # 80002980 <swtch>
    800023d4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023d6:	2781                	sext.w	a5,a5
    800023d8:	079e                	slli	a5,a5,0x7
    800023da:	97ca                	add	a5,a5,s2
    800023dc:	0b37a623          	sw	s3,172(a5)
}
    800023e0:	70a2                	ld	ra,40(sp)
    800023e2:	7402                	ld	s0,32(sp)
    800023e4:	64e2                	ld	s1,24(sp)
    800023e6:	6942                	ld	s2,16(sp)
    800023e8:	69a2                	ld	s3,8(sp)
    800023ea:	6145                	addi	sp,sp,48
    800023ec:	8082                	ret
    panic("sched p->lock");
    800023ee:	00006517          	auipc	a0,0x6
    800023f2:	eea50513          	addi	a0,a0,-278 # 800082d8 <digits+0x298>
    800023f6:	ffffe097          	auipc	ra,0xffffe
    800023fa:	134080e7          	jalr	308(ra) # 8000052a <panic>
    panic("sched locks");
    800023fe:	00006517          	auipc	a0,0x6
    80002402:	eea50513          	addi	a0,a0,-278 # 800082e8 <digits+0x2a8>
    80002406:	ffffe097          	auipc	ra,0xffffe
    8000240a:	124080e7          	jalr	292(ra) # 8000052a <panic>
    panic("sched running");
    8000240e:	00006517          	auipc	a0,0x6
    80002412:	eea50513          	addi	a0,a0,-278 # 800082f8 <digits+0x2b8>
    80002416:	ffffe097          	auipc	ra,0xffffe
    8000241a:	114080e7          	jalr	276(ra) # 8000052a <panic>
    panic("sched interruptible");
    8000241e:	00006517          	auipc	a0,0x6
    80002422:	eea50513          	addi	a0,a0,-278 # 80008308 <digits+0x2c8>
    80002426:	ffffe097          	auipc	ra,0xffffe
    8000242a:	104080e7          	jalr	260(ra) # 8000052a <panic>

000000008000242e <yield>:
{
    8000242e:	1101                	addi	sp,sp,-32
    80002430:	ec06                	sd	ra,24(sp)
    80002432:	e822                	sd	s0,16(sp)
    80002434:	e426                	sd	s1,8(sp)
    80002436:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	7e2080e7          	jalr	2018(ra) # 80001c1a <myproc>
    80002440:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	780080e7          	jalr	1920(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000244a:	478d                	li	a5,3
    8000244c:	cc9c                	sw	a5,24(s1)
  sched();
    8000244e:	00000097          	auipc	ra,0x0
    80002452:	f0a080e7          	jalr	-246(ra) # 80002358 <sched>
  release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	81e080e7          	jalr	-2018(ra) # 80000c76 <release>
}
    80002460:	60e2                	ld	ra,24(sp)
    80002462:	6442                	ld	s0,16(sp)
    80002464:	64a2                	ld	s1,8(sp)
    80002466:	6105                	addi	sp,sp,32
    80002468:	8082                	ret

000000008000246a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000246a:	7179                	addi	sp,sp,-48
    8000246c:	f406                	sd	ra,40(sp)
    8000246e:	f022                	sd	s0,32(sp)
    80002470:	ec26                	sd	s1,24(sp)
    80002472:	e84a                	sd	s2,16(sp)
    80002474:	e44e                	sd	s3,8(sp)
    80002476:	1800                	addi	s0,sp,48
    80002478:	89aa                	mv	s3,a0
    8000247a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	79e080e7          	jalr	1950(ra) # 80001c1a <myproc>
    80002484:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	73c080e7          	jalr	1852(ra) # 80000bc2 <acquire>
  release(lk);
    8000248e:	854a                	mv	a0,s2
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	7e6080e7          	jalr	2022(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002498:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000249c:	4789                	li	a5,2
    8000249e:	cc9c                	sw	a5,24(s1)

  sched();
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	eb8080e7          	jalr	-328(ra) # 80002358 <sched>

  // Tidy up.
  p->chan = 0;
    800024a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	7c8080e7          	jalr	1992(ra) # 80000c76 <release>
  acquire(lk);
    800024b6:	854a                	mv	a0,s2
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	70a080e7          	jalr	1802(ra) # 80000bc2 <acquire>
}
    800024c0:	70a2                	ld	ra,40(sp)
    800024c2:	7402                	ld	s0,32(sp)
    800024c4:	64e2                	ld	s1,24(sp)
    800024c6:	6942                	ld	s2,16(sp)
    800024c8:	69a2                	ld	s3,8(sp)
    800024ca:	6145                	addi	sp,sp,48
    800024cc:	8082                	ret

00000000800024ce <wait>:
{
    800024ce:	715d                	addi	sp,sp,-80
    800024d0:	e486                	sd	ra,72(sp)
    800024d2:	e0a2                	sd	s0,64(sp)
    800024d4:	fc26                	sd	s1,56(sp)
    800024d6:	f84a                	sd	s2,48(sp)
    800024d8:	f44e                	sd	s3,40(sp)
    800024da:	f052                	sd	s4,32(sp)
    800024dc:	ec56                	sd	s5,24(sp)
    800024de:	e85a                	sd	s6,16(sp)
    800024e0:	e45e                	sd	s7,8(sp)
    800024e2:	e062                	sd	s8,0(sp)
    800024e4:	0880                	addi	s0,sp,80
    800024e6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	732080e7          	jalr	1842(ra) # 80001c1a <myproc>
    800024f0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024f2:	0000f517          	auipc	a0,0xf
    800024f6:	dc650513          	addi	a0,a0,-570 # 800112b8 <wait_lock>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	6c8080e7          	jalr	1736(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002502:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002504:	4a15                	li	s4,5
        havekids = 1;
    80002506:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002508:	0001b997          	auipc	s3,0x1b
    8000250c:	dc898993          	addi	s3,s3,-568 # 8001d2d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002510:	0000fc17          	auipc	s8,0xf
    80002514:	da8c0c13          	addi	s8,s8,-600 # 800112b8 <wait_lock>
    havekids = 0;
    80002518:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000251a:	0000f497          	auipc	s1,0xf
    8000251e:	1b648493          	addi	s1,s1,438 # 800116d0 <proc>
    80002522:	a0bd                	j	80002590 <wait+0xc2>
          pid = np->pid;
    80002524:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002528:	000b0e63          	beqz	s6,80002544 <wait+0x76>
    8000252c:	4691                	li	a3,4
    8000252e:	02c48613          	addi	a2,s1,44
    80002532:	85da                	mv	a1,s6
    80002534:	05093503          	ld	a0,80(s2)
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	106080e7          	jalr	262(ra) # 8000163e <copyout>
    80002540:	02054563          	bltz	a0,8000256a <wait+0x9c>
          freeproc(np);
    80002544:	8526                	mv	a0,s1
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	886080e7          	jalr	-1914(ra) # 80001dcc <freeproc>
          release(&np->lock);
    8000254e:	8526                	mv	a0,s1
    80002550:	ffffe097          	auipc	ra,0xffffe
    80002554:	726080e7          	jalr	1830(ra) # 80000c76 <release>
          release(&wait_lock);
    80002558:	0000f517          	auipc	a0,0xf
    8000255c:	d6050513          	addi	a0,a0,-672 # 800112b8 <wait_lock>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	716080e7          	jalr	1814(ra) # 80000c76 <release>
          return pid;
    80002568:	a09d                	j	800025ce <wait+0x100>
            release(&np->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	70a080e7          	jalr	1802(ra) # 80000c76 <release>
            release(&wait_lock);
    80002574:	0000f517          	auipc	a0,0xf
    80002578:	d4450513          	addi	a0,a0,-700 # 800112b8 <wait_lock>
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	6fa080e7          	jalr	1786(ra) # 80000c76 <release>
            return -1;
    80002584:	59fd                	li	s3,-1
    80002586:	a0a1                	j	800025ce <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002588:	2f048493          	addi	s1,s1,752
    8000258c:	03348463          	beq	s1,s3,800025b4 <wait+0xe6>
      if(np->parent == p){
    80002590:	7c9c                	ld	a5,56(s1)
    80002592:	ff279be3          	bne	a5,s2,80002588 <wait+0xba>
        acquire(&np->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	62a080e7          	jalr	1578(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    800025a0:	4c9c                	lw	a5,24(s1)
    800025a2:	f94781e3          	beq	a5,s4,80002524 <wait+0x56>
        release(&np->lock);
    800025a6:	8526                	mv	a0,s1
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6ce080e7          	jalr	1742(ra) # 80000c76 <release>
        havekids = 1;
    800025b0:	8756                	mv	a4,s5
    800025b2:	bfd9                	j	80002588 <wait+0xba>
    if(!havekids || p->killed){
    800025b4:	c701                	beqz	a4,800025bc <wait+0xee>
    800025b6:	02892783          	lw	a5,40(s2)
    800025ba:	c79d                	beqz	a5,800025e8 <wait+0x11a>
      release(&wait_lock);
    800025bc:	0000f517          	auipc	a0,0xf
    800025c0:	cfc50513          	addi	a0,a0,-772 # 800112b8 <wait_lock>
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6b2080e7          	jalr	1714(ra) # 80000c76 <release>
      return -1;
    800025cc:	59fd                	li	s3,-1
}
    800025ce:	854e                	mv	a0,s3
    800025d0:	60a6                	ld	ra,72(sp)
    800025d2:	6406                	ld	s0,64(sp)
    800025d4:	74e2                	ld	s1,56(sp)
    800025d6:	7942                	ld	s2,48(sp)
    800025d8:	79a2                	ld	s3,40(sp)
    800025da:	7a02                	ld	s4,32(sp)
    800025dc:	6ae2                	ld	s5,24(sp)
    800025de:	6b42                	ld	s6,16(sp)
    800025e0:	6ba2                	ld	s7,8(sp)
    800025e2:	6c02                	ld	s8,0(sp)
    800025e4:	6161                	addi	sp,sp,80
    800025e6:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025e8:	85e2                	mv	a1,s8
    800025ea:	854a                	mv	a0,s2
    800025ec:	00000097          	auipc	ra,0x0
    800025f0:	e7e080e7          	jalr	-386(ra) # 8000246a <sleep>
    havekids = 0;
    800025f4:	b715                	j	80002518 <wait+0x4a>

00000000800025f6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025f6:	7139                	addi	sp,sp,-64
    800025f8:	fc06                	sd	ra,56(sp)
    800025fa:	f822                	sd	s0,48(sp)
    800025fc:	f426                	sd	s1,40(sp)
    800025fe:	f04a                	sd	s2,32(sp)
    80002600:	ec4e                	sd	s3,24(sp)
    80002602:	e852                	sd	s4,16(sp)
    80002604:	e456                	sd	s5,8(sp)
    80002606:	0080                	addi	s0,sp,64
    80002608:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000260a:	0000f497          	auipc	s1,0xf
    8000260e:	0c648493          	addi	s1,s1,198 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002612:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002614:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002616:	0001b917          	auipc	s2,0x1b
    8000261a:	cba90913          	addi	s2,s2,-838 # 8001d2d0 <tickslock>
    8000261e:	a811                	j	80002632 <wakeup+0x3c>
      }
      release(&p->lock);
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	654080e7          	jalr	1620(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000262a:	2f048493          	addi	s1,s1,752
    8000262e:	03248663          	beq	s1,s2,8000265a <wakeup+0x64>
    if(p != myproc()){
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	5e8080e7          	jalr	1512(ra) # 80001c1a <myproc>
    8000263a:	fea488e3          	beq	s1,a0,8000262a <wakeup+0x34>
      acquire(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	582080e7          	jalr	1410(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002648:	4c9c                	lw	a5,24(s1)
    8000264a:	fd379be3          	bne	a5,s3,80002620 <wakeup+0x2a>
    8000264e:	709c                	ld	a5,32(s1)
    80002650:	fd4798e3          	bne	a5,s4,80002620 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002654:	0154ac23          	sw	s5,24(s1)
    80002658:	b7e1                	j	80002620 <wakeup+0x2a>
    }
  }
}
    8000265a:	70e2                	ld	ra,56(sp)
    8000265c:	7442                	ld	s0,48(sp)
    8000265e:	74a2                	ld	s1,40(sp)
    80002660:	7902                	ld	s2,32(sp)
    80002662:	69e2                	ld	s3,24(sp)
    80002664:	6a42                	ld	s4,16(sp)
    80002666:	6aa2                	ld	s5,8(sp)
    80002668:	6121                	addi	sp,sp,64
    8000266a:	8082                	ret

000000008000266c <reparent>:
{
    8000266c:	7179                	addi	sp,sp,-48
    8000266e:	f406                	sd	ra,40(sp)
    80002670:	f022                	sd	s0,32(sp)
    80002672:	ec26                	sd	s1,24(sp)
    80002674:	e84a                	sd	s2,16(sp)
    80002676:	e44e                	sd	s3,8(sp)
    80002678:	e052                	sd	s4,0(sp)
    8000267a:	1800                	addi	s0,sp,48
    8000267c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000267e:	0000f497          	auipc	s1,0xf
    80002682:	05248493          	addi	s1,s1,82 # 800116d0 <proc>
      pp->parent = initproc;
    80002686:	00007a17          	auipc	s4,0x7
    8000268a:	9a2a0a13          	addi	s4,s4,-1630 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000268e:	0001b997          	auipc	s3,0x1b
    80002692:	c4298993          	addi	s3,s3,-958 # 8001d2d0 <tickslock>
    80002696:	a029                	j	800026a0 <reparent+0x34>
    80002698:	2f048493          	addi	s1,s1,752
    8000269c:	01348d63          	beq	s1,s3,800026b6 <reparent+0x4a>
    if(pp->parent == p){
    800026a0:	7c9c                	ld	a5,56(s1)
    800026a2:	ff279be3          	bne	a5,s2,80002698 <reparent+0x2c>
      pp->parent = initproc;
    800026a6:	000a3503          	ld	a0,0(s4)
    800026aa:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026ac:	00000097          	auipc	ra,0x0
    800026b0:	f4a080e7          	jalr	-182(ra) # 800025f6 <wakeup>
    800026b4:	b7d5                	j	80002698 <reparent+0x2c>
}
    800026b6:	70a2                	ld	ra,40(sp)
    800026b8:	7402                	ld	s0,32(sp)
    800026ba:	64e2                	ld	s1,24(sp)
    800026bc:	6942                	ld	s2,16(sp)
    800026be:	69a2                	ld	s3,8(sp)
    800026c0:	6a02                	ld	s4,0(sp)
    800026c2:	6145                	addi	sp,sp,48
    800026c4:	8082                	ret

00000000800026c6 <exit>:
{
    800026c6:	7179                	addi	sp,sp,-48
    800026c8:	f406                	sd	ra,40(sp)
    800026ca:	f022                	sd	s0,32(sp)
    800026cc:	ec26                	sd	s1,24(sp)
    800026ce:	e84a                	sd	s2,16(sp)
    800026d0:	e44e                	sd	s3,8(sp)
    800026d2:	e052                	sd	s4,0(sp)
    800026d4:	1800                	addi	s0,sp,48
    800026d6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026d8:	fffff097          	auipc	ra,0xfffff
    800026dc:	542080e7          	jalr	1346(ra) # 80001c1a <myproc>
    800026e0:	89aa                	mv	s3,a0
  if(p == initproc)
    800026e2:	00007797          	auipc	a5,0x7
    800026e6:	9467b783          	ld	a5,-1722(a5) # 80009028 <initproc>
    800026ea:	0d050493          	addi	s1,a0,208
    800026ee:	15050913          	addi	s2,a0,336
    800026f2:	02a79363          	bne	a5,a0,80002718 <exit+0x52>
    panic("init exiting");
    800026f6:	00006517          	auipc	a0,0x6
    800026fa:	c2a50513          	addi	a0,a0,-982 # 80008320 <digits+0x2e0>
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	e2c080e7          	jalr	-468(ra) # 8000052a <panic>
      fileclose(f);
    80002706:	00002097          	auipc	ra,0x2
    8000270a:	492080e7          	jalr	1170(ra) # 80004b98 <fileclose>
      p->ofile[fd] = 0;
    8000270e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002712:	04a1                	addi	s1,s1,8
    80002714:	01248563          	beq	s1,s2,8000271e <exit+0x58>
    if(p->ofile[fd]){
    80002718:	6088                	ld	a0,0(s1)
    8000271a:	f575                	bnez	a0,80002706 <exit+0x40>
    8000271c:	bfdd                	j	80002712 <exit+0x4c>
  if(p->pid > 2)
    8000271e:	0309a703          	lw	a4,48(s3)
    80002722:	4789                	li	a5,2
    80002724:	08e7c163          	blt	a5,a4,800027a6 <exit+0xe0>
  begin_op();
    80002728:	00002097          	auipc	ra,0x2
    8000272c:	fa4080e7          	jalr	-92(ra) # 800046cc <begin_op>
  iput(p->cwd);
    80002730:	1509b503          	ld	a0,336(s3)
    80002734:	00001097          	auipc	ra,0x1
    80002738:	46a080e7          	jalr	1130(ra) # 80003b9e <iput>
  end_op();
    8000273c:	00002097          	auipc	ra,0x2
    80002740:	010080e7          	jalr	16(ra) # 8000474c <end_op>
  p->cwd = 0;
    80002744:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002748:	0000f497          	auipc	s1,0xf
    8000274c:	b7048493          	addi	s1,s1,-1168 # 800112b8 <wait_lock>
    80002750:	8526                	mv	a0,s1
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	470080e7          	jalr	1136(ra) # 80000bc2 <acquire>
  reparent(p);
    8000275a:	854e                	mv	a0,s3
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	f10080e7          	jalr	-240(ra) # 8000266c <reparent>
  wakeup(p->parent);
    80002764:	0389b503          	ld	a0,56(s3)
    80002768:	00000097          	auipc	ra,0x0
    8000276c:	e8e080e7          	jalr	-370(ra) # 800025f6 <wakeup>
  acquire(&p->lock);
    80002770:	854e                	mv	a0,s3
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	450080e7          	jalr	1104(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000277a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000277e:	4795                	li	a5,5
    80002780:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	4f0080e7          	jalr	1264(ra) # 80000c76 <release>
  sched();
    8000278e:	00000097          	auipc	ra,0x0
    80002792:	bca080e7          	jalr	-1078(ra) # 80002358 <sched>
  panic("zombie exit");
    80002796:	00006517          	auipc	a0,0x6
    8000279a:	b9a50513          	addi	a0,a0,-1126 # 80008330 <digits+0x2f0>
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	d8c080e7          	jalr	-628(ra) # 8000052a <panic>
    removeSwapFile(p);
    800027a6:	854e                	mv	a0,s3
    800027a8:	00002097          	auipc	ra,0x2
    800027ac:	a9e080e7          	jalr	-1378(ra) # 80004246 <removeSwapFile>
    800027b0:	bfa5                	j	80002728 <exit+0x62>

00000000800027b2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027b2:	7179                	addi	sp,sp,-48
    800027b4:	f406                	sd	ra,40(sp)
    800027b6:	f022                	sd	s0,32(sp)
    800027b8:	ec26                	sd	s1,24(sp)
    800027ba:	e84a                	sd	s2,16(sp)
    800027bc:	e44e                	sd	s3,8(sp)
    800027be:	1800                	addi	s0,sp,48
    800027c0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027c2:	0000f497          	auipc	s1,0xf
    800027c6:	f0e48493          	addi	s1,s1,-242 # 800116d0 <proc>
    800027ca:	0001b997          	auipc	s3,0x1b
    800027ce:	b0698993          	addi	s3,s3,-1274 # 8001d2d0 <tickslock>
    acquire(&p->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	3ee080e7          	jalr	1006(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800027dc:	589c                	lw	a5,48(s1)
    800027de:	01278d63          	beq	a5,s2,800027f8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	492080e7          	jalr	1170(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ec:	2f048493          	addi	s1,s1,752
    800027f0:	ff3491e3          	bne	s1,s3,800027d2 <kill+0x20>
  }
  return -1;
    800027f4:	557d                	li	a0,-1
    800027f6:	a829                	j	80002810 <kill+0x5e>
      p->killed = 1;
    800027f8:	4785                	li	a5,1
    800027fa:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027fc:	4c98                	lw	a4,24(s1)
    800027fe:	4789                	li	a5,2
    80002800:	00f70f63          	beq	a4,a5,8000281e <kill+0x6c>
      release(&p->lock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	470080e7          	jalr	1136(ra) # 80000c76 <release>
      return 0;
    8000280e:	4501                	li	a0,0
}
    80002810:	70a2                	ld	ra,40(sp)
    80002812:	7402                	ld	s0,32(sp)
    80002814:	64e2                	ld	s1,24(sp)
    80002816:	6942                	ld	s2,16(sp)
    80002818:	69a2                	ld	s3,8(sp)
    8000281a:	6145                	addi	sp,sp,48
    8000281c:	8082                	ret
        p->state = RUNNABLE;
    8000281e:	478d                	li	a5,3
    80002820:	cc9c                	sw	a5,24(s1)
    80002822:	b7cd                	j	80002804 <kill+0x52>

0000000080002824 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002824:	7179                	addi	sp,sp,-48
    80002826:	f406                	sd	ra,40(sp)
    80002828:	f022                	sd	s0,32(sp)
    8000282a:	ec26                	sd	s1,24(sp)
    8000282c:	e84a                	sd	s2,16(sp)
    8000282e:	e44e                	sd	s3,8(sp)
    80002830:	e052                	sd	s4,0(sp)
    80002832:	1800                	addi	s0,sp,48
    80002834:	84aa                	mv	s1,a0
    80002836:	892e                	mv	s2,a1
    80002838:	89b2                	mv	s3,a2
    8000283a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	3de080e7          	jalr	990(ra) # 80001c1a <myproc>
  if(user_dst){
    80002844:	c08d                	beqz	s1,80002866 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002846:	86d2                	mv	a3,s4
    80002848:	864e                	mv	a2,s3
    8000284a:	85ca                	mv	a1,s2
    8000284c:	6928                	ld	a0,80(a0)
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	df0080e7          	jalr	-528(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002856:	70a2                	ld	ra,40(sp)
    80002858:	7402                	ld	s0,32(sp)
    8000285a:	64e2                	ld	s1,24(sp)
    8000285c:	6942                	ld	s2,16(sp)
    8000285e:	69a2                	ld	s3,8(sp)
    80002860:	6a02                	ld	s4,0(sp)
    80002862:	6145                	addi	sp,sp,48
    80002864:	8082                	ret
    memmove((char *)dst, src, len);
    80002866:	000a061b          	sext.w	a2,s4
    8000286a:	85ce                	mv	a1,s3
    8000286c:	854a                	mv	a0,s2
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	4ac080e7          	jalr	1196(ra) # 80000d1a <memmove>
    return 0;
    80002876:	8526                	mv	a0,s1
    80002878:	bff9                	j	80002856 <either_copyout+0x32>

000000008000287a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000287a:	7179                	addi	sp,sp,-48
    8000287c:	f406                	sd	ra,40(sp)
    8000287e:	f022                	sd	s0,32(sp)
    80002880:	ec26                	sd	s1,24(sp)
    80002882:	e84a                	sd	s2,16(sp)
    80002884:	e44e                	sd	s3,8(sp)
    80002886:	e052                	sd	s4,0(sp)
    80002888:	1800                	addi	s0,sp,48
    8000288a:	892a                	mv	s2,a0
    8000288c:	84ae                	mv	s1,a1
    8000288e:	89b2                	mv	s3,a2
    80002890:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	388080e7          	jalr	904(ra) # 80001c1a <myproc>
  if(user_src){
    8000289a:	c08d                	beqz	s1,800028bc <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000289c:	86d2                	mv	a3,s4
    8000289e:	864e                	mv	a2,s3
    800028a0:	85ca                	mv	a1,s2
    800028a2:	6928                	ld	a0,80(a0)
    800028a4:	fffff097          	auipc	ra,0xfffff
    800028a8:	e26080e7          	jalr	-474(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028ac:	70a2                	ld	ra,40(sp)
    800028ae:	7402                	ld	s0,32(sp)
    800028b0:	64e2                	ld	s1,24(sp)
    800028b2:	6942                	ld	s2,16(sp)
    800028b4:	69a2                	ld	s3,8(sp)
    800028b6:	6a02                	ld	s4,0(sp)
    800028b8:	6145                	addi	sp,sp,48
    800028ba:	8082                	ret
    memmove(dst, (char*)src, len);
    800028bc:	000a061b          	sext.w	a2,s4
    800028c0:	85ce                	mv	a1,s3
    800028c2:	854a                	mv	a0,s2
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	456080e7          	jalr	1110(ra) # 80000d1a <memmove>
    return 0;
    800028cc:	8526                	mv	a0,s1
    800028ce:	bff9                	j	800028ac <either_copyin+0x32>

00000000800028d0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028d0:	715d                	addi	sp,sp,-80
    800028d2:	e486                	sd	ra,72(sp)
    800028d4:	e0a2                	sd	s0,64(sp)
    800028d6:	fc26                	sd	s1,56(sp)
    800028d8:	f84a                	sd	s2,48(sp)
    800028da:	f44e                	sd	s3,40(sp)
    800028dc:	f052                	sd	s4,32(sp)
    800028de:	ec56                	sd	s5,24(sp)
    800028e0:	e85a                	sd	s6,16(sp)
    800028e2:	e45e                	sd	s7,8(sp)
    800028e4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028e6:	00005517          	auipc	a0,0x5
    800028ea:	7e250513          	addi	a0,a0,2018 # 800080c8 <digits+0x88>
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	c86080e7          	jalr	-890(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028f6:	0000f497          	auipc	s1,0xf
    800028fa:	f3248493          	addi	s1,s1,-206 # 80011828 <proc+0x158>
    800028fe:	0001b917          	auipc	s2,0x1b
    80002902:	b2a90913          	addi	s2,s2,-1238 # 8001d428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002906:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002908:	00006997          	auipc	s3,0x6
    8000290c:	a3898993          	addi	s3,s3,-1480 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    80002910:	00006a97          	auipc	s5,0x6
    80002914:	a38a8a93          	addi	s5,s5,-1480 # 80008348 <digits+0x308>
    printf("\n");
    80002918:	00005a17          	auipc	s4,0x5
    8000291c:	7b0a0a13          	addi	s4,s4,1968 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002920:	00006b97          	auipc	s7,0x6
    80002924:	a60b8b93          	addi	s7,s7,-1440 # 80008380 <states.0>
    80002928:	a00d                	j	8000294a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000292a:	ed86a583          	lw	a1,-296(a3)
    8000292e:	8556                	mv	a0,s5
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c44080e7          	jalr	-956(ra) # 80000574 <printf>
    printf("\n");
    80002938:	8552                	mv	a0,s4
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	c3a080e7          	jalr	-966(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002942:	2f048493          	addi	s1,s1,752
    80002946:	03248263          	beq	s1,s2,8000296a <procdump+0x9a>
    if(p->state == UNUSED)
    8000294a:	86a6                	mv	a3,s1
    8000294c:	ec04a783          	lw	a5,-320(s1)
    80002950:	dbed                	beqz	a5,80002942 <procdump+0x72>
      state = "???";
    80002952:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002954:	fcfb6be3          	bltu	s6,a5,8000292a <procdump+0x5a>
    80002958:	02079713          	slli	a4,a5,0x20
    8000295c:	01d75793          	srli	a5,a4,0x1d
    80002960:	97de                	add	a5,a5,s7
    80002962:	6390                	ld	a2,0(a5)
    80002964:	f279                	bnez	a2,8000292a <procdump+0x5a>
      state = "???";
    80002966:	864e                	mv	a2,s3
    80002968:	b7c9                	j	8000292a <procdump+0x5a>
  }
}
    8000296a:	60a6                	ld	ra,72(sp)
    8000296c:	6406                	ld	s0,64(sp)
    8000296e:	74e2                	ld	s1,56(sp)
    80002970:	7942                	ld	s2,48(sp)
    80002972:	79a2                	ld	s3,40(sp)
    80002974:	7a02                	ld	s4,32(sp)
    80002976:	6ae2                	ld	s5,24(sp)
    80002978:	6b42                	ld	s6,16(sp)
    8000297a:	6ba2                	ld	s7,8(sp)
    8000297c:	6161                	addi	sp,sp,80
    8000297e:	8082                	ret

0000000080002980 <swtch>:
    80002980:	00153023          	sd	ra,0(a0)
    80002984:	00253423          	sd	sp,8(a0)
    80002988:	e900                	sd	s0,16(a0)
    8000298a:	ed04                	sd	s1,24(a0)
    8000298c:	03253023          	sd	s2,32(a0)
    80002990:	03353423          	sd	s3,40(a0)
    80002994:	03453823          	sd	s4,48(a0)
    80002998:	03553c23          	sd	s5,56(a0)
    8000299c:	05653023          	sd	s6,64(a0)
    800029a0:	05753423          	sd	s7,72(a0)
    800029a4:	05853823          	sd	s8,80(a0)
    800029a8:	05953c23          	sd	s9,88(a0)
    800029ac:	07a53023          	sd	s10,96(a0)
    800029b0:	07b53423          	sd	s11,104(a0)
    800029b4:	0005b083          	ld	ra,0(a1)
    800029b8:	0085b103          	ld	sp,8(a1)
    800029bc:	6980                	ld	s0,16(a1)
    800029be:	6d84                	ld	s1,24(a1)
    800029c0:	0205b903          	ld	s2,32(a1)
    800029c4:	0285b983          	ld	s3,40(a1)
    800029c8:	0305ba03          	ld	s4,48(a1)
    800029cc:	0385ba83          	ld	s5,56(a1)
    800029d0:	0405bb03          	ld	s6,64(a1)
    800029d4:	0485bb83          	ld	s7,72(a1)
    800029d8:	0505bc03          	ld	s8,80(a1)
    800029dc:	0585bc83          	ld	s9,88(a1)
    800029e0:	0605bd03          	ld	s10,96(a1)
    800029e4:	0685bd83          	ld	s11,104(a1)
    800029e8:	8082                	ret

00000000800029ea <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029ea:	1141                	addi	sp,sp,-16
    800029ec:	e406                	sd	ra,8(sp)
    800029ee:	e022                	sd	s0,0(sp)
    800029f0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029f2:	00006597          	auipc	a1,0x6
    800029f6:	9be58593          	addi	a1,a1,-1602 # 800083b0 <states.0+0x30>
    800029fa:	0001b517          	auipc	a0,0x1b
    800029fe:	8d650513          	addi	a0,a0,-1834 # 8001d2d0 <tickslock>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	130080e7          	jalr	304(ra) # 80000b32 <initlock>
}
    80002a0a:	60a2                	ld	ra,8(sp)
    80002a0c:	6402                	ld	s0,0(sp)
    80002a0e:	0141                	addi	sp,sp,16
    80002a10:	8082                	ret

0000000080002a12 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a12:	1141                	addi	sp,sp,-16
    80002a14:	e422                	sd	s0,8(sp)
    80002a16:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a18:	00004797          	auipc	a5,0x4
    80002a1c:	9c878793          	addi	a5,a5,-1592 # 800063e0 <kernelvec>
    80002a20:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a24:	6422                	ld	s0,8(sp)
    80002a26:	0141                	addi	sp,sp,16
    80002a28:	8082                	ret

0000000080002a2a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a2a:	1141                	addi	sp,sp,-16
    80002a2c:	e406                	sd	ra,8(sp)
    80002a2e:	e022                	sd	s0,0(sp)
    80002a30:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	1e8080e7          	jalr	488(ra) # 80001c1a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a3e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a40:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a44:	00004617          	auipc	a2,0x4
    80002a48:	5bc60613          	addi	a2,a2,1468 # 80007000 <_trampoline>
    80002a4c:	00004697          	auipc	a3,0x4
    80002a50:	5b468693          	addi	a3,a3,1460 # 80007000 <_trampoline>
    80002a54:	8e91                	sub	a3,a3,a2
    80002a56:	040007b7          	lui	a5,0x4000
    80002a5a:	17fd                	addi	a5,a5,-1
    80002a5c:	07b2                	slli	a5,a5,0xc
    80002a5e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a60:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a64:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a66:	180026f3          	csrr	a3,satp
    80002a6a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a6c:	6d38                	ld	a4,88(a0)
    80002a6e:	6134                	ld	a3,64(a0)
    80002a70:	6585                	lui	a1,0x1
    80002a72:	96ae                	add	a3,a3,a1
    80002a74:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a76:	6d38                	ld	a4,88(a0)
    80002a78:	00000697          	auipc	a3,0x0
    80002a7c:	13868693          	addi	a3,a3,312 # 80002bb0 <usertrap>
    80002a80:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a82:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a84:	8692                	mv	a3,tp
    80002a86:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a88:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a8c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a90:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a94:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a98:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a9a:	6f18                	ld	a4,24(a4)
    80002a9c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002aa0:	692c                	ld	a1,80(a0)
    80002aa2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002aa4:	00004717          	auipc	a4,0x4
    80002aa8:	5ec70713          	addi	a4,a4,1516 # 80007090 <userret>
    80002aac:	8f11                	sub	a4,a4,a2
    80002aae:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ab0:	577d                	li	a4,-1
    80002ab2:	177e                	slli	a4,a4,0x3f
    80002ab4:	8dd9                	or	a1,a1,a4
    80002ab6:	02000537          	lui	a0,0x2000
    80002aba:	157d                	addi	a0,a0,-1
    80002abc:	0536                	slli	a0,a0,0xd
    80002abe:	9782                	jalr	a5
}
    80002ac0:	60a2                	ld	ra,8(sp)
    80002ac2:	6402                	ld	s0,0(sp)
    80002ac4:	0141                	addi	sp,sp,16
    80002ac6:	8082                	ret

0000000080002ac8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ad2:	0001a497          	auipc	s1,0x1a
    80002ad6:	7fe48493          	addi	s1,s1,2046 # 8001d2d0 <tickslock>
    80002ada:	8526                	mv	a0,s1
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	0e6080e7          	jalr	230(ra) # 80000bc2 <acquire>
  ticks++;
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	54c50513          	addi	a0,a0,1356 # 80009030 <ticks>
    80002aec:	411c                	lw	a5,0(a0)
    80002aee:	2785                	addiw	a5,a5,1
    80002af0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	b04080e7          	jalr	-1276(ra) # 800025f6 <wakeup>
  release(&tickslock);
    80002afa:	8526                	mv	a0,s1
    80002afc:	ffffe097          	auipc	ra,0xffffe
    80002b00:	17a080e7          	jalr	378(ra) # 80000c76 <release>
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6105                	addi	sp,sp,32
    80002b0c:	8082                	ret

0000000080002b0e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b0e:	1101                	addi	sp,sp,-32
    80002b10:	ec06                	sd	ra,24(sp)
    80002b12:	e822                	sd	s0,16(sp)
    80002b14:	e426                	sd	s1,8(sp)
    80002b16:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b18:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b1c:	00074d63          	bltz	a4,80002b36 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b20:	57fd                	li	a5,-1
    80002b22:	17fe                	slli	a5,a5,0x3f
    80002b24:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b26:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b28:	06f70363          	beq	a4,a5,80002b8e <devintr+0x80>
  }
}
    80002b2c:	60e2                	ld	ra,24(sp)
    80002b2e:	6442                	ld	s0,16(sp)
    80002b30:	64a2                	ld	s1,8(sp)
    80002b32:	6105                	addi	sp,sp,32
    80002b34:	8082                	ret
     (scause & 0xff) == 9){
    80002b36:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b3a:	46a5                	li	a3,9
    80002b3c:	fed792e3          	bne	a5,a3,80002b20 <devintr+0x12>
    int irq = plic_claim();
    80002b40:	00004097          	auipc	ra,0x4
    80002b44:	9a8080e7          	jalr	-1624(ra) # 800064e8 <plic_claim>
    80002b48:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b4a:	47a9                	li	a5,10
    80002b4c:	02f50763          	beq	a0,a5,80002b7a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b50:	4785                	li	a5,1
    80002b52:	02f50963          	beq	a0,a5,80002b84 <devintr+0x76>
    return 1;
    80002b56:	4505                	li	a0,1
    } else if(irq){
    80002b58:	d8f1                	beqz	s1,80002b2c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	85c50513          	addi	a0,a0,-1956 # 800083b8 <states.0+0x38>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a10080e7          	jalr	-1520(ra) # 80000574 <printf>
      plic_complete(irq);
    80002b6c:	8526                	mv	a0,s1
    80002b6e:	00004097          	auipc	ra,0x4
    80002b72:	99e080e7          	jalr	-1634(ra) # 8000650c <plic_complete>
    return 1;
    80002b76:	4505                	li	a0,1
    80002b78:	bf55                	j	80002b2c <devintr+0x1e>
      uartintr();
    80002b7a:	ffffe097          	auipc	ra,0xffffe
    80002b7e:	e0c080e7          	jalr	-500(ra) # 80000986 <uartintr>
    80002b82:	b7ed                	j	80002b6c <devintr+0x5e>
      virtio_disk_intr();
    80002b84:	00004097          	auipc	ra,0x4
    80002b88:	e1a080e7          	jalr	-486(ra) # 8000699e <virtio_disk_intr>
    80002b8c:	b7c5                	j	80002b6c <devintr+0x5e>
    if(cpuid() == 0){
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	060080e7          	jalr	96(ra) # 80001bee <cpuid>
    80002b96:	c901                	beqz	a0,80002ba6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b98:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b9e:	14479073          	csrw	sip,a5
    return 2;
    80002ba2:	4509                	li	a0,2
    80002ba4:	b761                	j	80002b2c <devintr+0x1e>
      clockintr();
    80002ba6:	00000097          	auipc	ra,0x0
    80002baa:	f22080e7          	jalr	-222(ra) # 80002ac8 <clockintr>
    80002bae:	b7ed                	j	80002b98 <devintr+0x8a>

0000000080002bb0 <usertrap>:
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	e04a                	sd	s2,0(sp)
    80002bba:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bbc:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bc0:	1007f793          	andi	a5,a5,256
    80002bc4:	e3ad                	bnez	a5,80002c26 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bc6:	00004797          	auipc	a5,0x4
    80002bca:	81a78793          	addi	a5,a5,-2022 # 800063e0 <kernelvec>
    80002bce:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	048080e7          	jalr	72(ra) # 80001c1a <myproc>
    80002bda:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bdc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bde:	14102773          	csrr	a4,sepc
    80002be2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002be4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002be8:	47a1                	li	a5,8
    80002bea:	04f71c63          	bne	a4,a5,80002c42 <usertrap+0x92>
    if(p->killed)
    80002bee:	551c                	lw	a5,40(a0)
    80002bf0:	e3b9                	bnez	a5,80002c36 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bf2:	6cb8                	ld	a4,88(s1)
    80002bf4:	6f1c                	ld	a5,24(a4)
    80002bf6:	0791                	addi	a5,a5,4
    80002bf8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bfe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c02:	10079073          	csrw	sstatus,a5
    syscall();
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	2e0080e7          	jalr	736(ra) # 80002ee6 <syscall>
  if(p->killed)
    80002c0e:	549c                	lw	a5,40(s1)
    80002c10:	ebc1                	bnez	a5,80002ca0 <usertrap+0xf0>
  usertrapret();
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	e18080e7          	jalr	-488(ra) # 80002a2a <usertrapret>
}
    80002c1a:	60e2                	ld	ra,24(sp)
    80002c1c:	6442                	ld	s0,16(sp)
    80002c1e:	64a2                	ld	s1,8(sp)
    80002c20:	6902                	ld	s2,0(sp)
    80002c22:	6105                	addi	sp,sp,32
    80002c24:	8082                	ret
    panic("usertrap: not from user mode");
    80002c26:	00005517          	auipc	a0,0x5
    80002c2a:	7b250513          	addi	a0,a0,1970 # 800083d8 <states.0+0x58>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	8fc080e7          	jalr	-1796(ra) # 8000052a <panic>
      exit(-1);
    80002c36:	557d                	li	a0,-1
    80002c38:	00000097          	auipc	ra,0x0
    80002c3c:	a8e080e7          	jalr	-1394(ra) # 800026c6 <exit>
    80002c40:	bf4d                	j	80002bf2 <usertrap+0x42>
  else if((which_dev = devintr()) != 0){
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	ecc080e7          	jalr	-308(ra) # 80002b0e <devintr>
    80002c4a:	892a                	mv	s2,a0
    80002c4c:	c501                	beqz	a0,80002c54 <usertrap+0xa4>
  if(p->killed)
    80002c4e:	549c                	lw	a5,40(s1)
    80002c50:	c3a1                	beqz	a5,80002c90 <usertrap+0xe0>
    80002c52:	a815                	j	80002c86 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c54:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c58:	5890                	lw	a2,48(s1)
    80002c5a:	00005517          	auipc	a0,0x5
    80002c5e:	79e50513          	addi	a0,a0,1950 # 800083f8 <states.0+0x78>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	912080e7          	jalr	-1774(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c6a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c6e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c72:	00005517          	auipc	a0,0x5
    80002c76:	7b650513          	addi	a0,a0,1974 # 80008428 <states.0+0xa8>
    80002c7a:	ffffe097          	auipc	ra,0xffffe
    80002c7e:	8fa080e7          	jalr	-1798(ra) # 80000574 <printf>
    p->killed = 1;
    80002c82:	4785                	li	a5,1
    80002c84:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c86:	557d                	li	a0,-1
    80002c88:	00000097          	auipc	ra,0x0
    80002c8c:	a3e080e7          	jalr	-1474(ra) # 800026c6 <exit>
  if(which_dev == 2)
    80002c90:	4789                	li	a5,2
    80002c92:	f8f910e3          	bne	s2,a5,80002c12 <usertrap+0x62>
    yield();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	798080e7          	jalr	1944(ra) # 8000242e <yield>
    80002c9e:	bf95                	j	80002c12 <usertrap+0x62>
  int which_dev = 0;
    80002ca0:	4901                	li	s2,0
    80002ca2:	b7d5                	j	80002c86 <usertrap+0xd6>

0000000080002ca4 <kerneltrap>:
{
    80002ca4:	7179                	addi	sp,sp,-48
    80002ca6:	f406                	sd	ra,40(sp)
    80002ca8:	f022                	sd	s0,32(sp)
    80002caa:	ec26                	sd	s1,24(sp)
    80002cac:	e84a                	sd	s2,16(sp)
    80002cae:	e44e                	sd	s3,8(sp)
    80002cb0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cb2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cbe:	1004f793          	andi	a5,s1,256
    80002cc2:	cb85                	beqz	a5,80002cf2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cc8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cca:	ef85                	bnez	a5,80002d02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	e42080e7          	jalr	-446(ra) # 80002b0e <devintr>
    80002cd4:	cd1d                	beqz	a0,80002d12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cd6:	4789                	li	a5,2
    80002cd8:	06f50a63          	beq	a0,a5,80002d4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cdc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ce0:	10049073          	csrw	sstatus,s1
}
    80002ce4:	70a2                	ld	ra,40(sp)
    80002ce6:	7402                	ld	s0,32(sp)
    80002ce8:	64e2                	ld	s1,24(sp)
    80002cea:	6942                	ld	s2,16(sp)
    80002cec:	69a2                	ld	s3,8(sp)
    80002cee:	6145                	addi	sp,sp,48
    80002cf0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cf2:	00005517          	auipc	a0,0x5
    80002cf6:	75650513          	addi	a0,a0,1878 # 80008448 <states.0+0xc8>
    80002cfa:	ffffe097          	auipc	ra,0xffffe
    80002cfe:	830080e7          	jalr	-2000(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002d02:	00005517          	auipc	a0,0x5
    80002d06:	76e50513          	addi	a0,a0,1902 # 80008470 <states.0+0xf0>
    80002d0a:	ffffe097          	auipc	ra,0xffffe
    80002d0e:	820080e7          	jalr	-2016(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002d12:	85ce                	mv	a1,s3
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	77c50513          	addi	a0,a0,1916 # 80008490 <states.0+0x110>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	858080e7          	jalr	-1960(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d2c:	00005517          	auipc	a0,0x5
    80002d30:	77450513          	addi	a0,a0,1908 # 800084a0 <states.0+0x120>
    80002d34:	ffffe097          	auipc	ra,0xffffe
    80002d38:	840080e7          	jalr	-1984(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	77c50513          	addi	a0,a0,1916 # 800084b8 <states.0+0x138>
    80002d44:	ffffd097          	auipc	ra,0xffffd
    80002d48:	7e6080e7          	jalr	2022(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	ece080e7          	jalr	-306(ra) # 80001c1a <myproc>
    80002d54:	d541                	beqz	a0,80002cdc <kerneltrap+0x38>
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	ec4080e7          	jalr	-316(ra) # 80001c1a <myproc>
    80002d5e:	4d18                	lw	a4,24(a0)
    80002d60:	4791                	li	a5,4
    80002d62:	f6f71de3          	bne	a4,a5,80002cdc <kerneltrap+0x38>
    yield();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	6c8080e7          	jalr	1736(ra) # 8000242e <yield>
    80002d6e:	b7bd                	j	80002cdc <kerneltrap+0x38>

0000000080002d70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d70:	1101                	addi	sp,sp,-32
    80002d72:	ec06                	sd	ra,24(sp)
    80002d74:	e822                	sd	s0,16(sp)
    80002d76:	e426                	sd	s1,8(sp)
    80002d78:	1000                	addi	s0,sp,32
    80002d7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d7c:	fffff097          	auipc	ra,0xfffff
    80002d80:	e9e080e7          	jalr	-354(ra) # 80001c1a <myproc>
  switch (n) {
    80002d84:	4795                	li	a5,5
    80002d86:	0497e163          	bltu	a5,s1,80002dc8 <argraw+0x58>
    80002d8a:	048a                	slli	s1,s1,0x2
    80002d8c:	00005717          	auipc	a4,0x5
    80002d90:	76470713          	addi	a4,a4,1892 # 800084f0 <states.0+0x170>
    80002d94:	94ba                	add	s1,s1,a4
    80002d96:	409c                	lw	a5,0(s1)
    80002d98:	97ba                	add	a5,a5,a4
    80002d9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d9c:	6d3c                	ld	a5,88(a0)
    80002d9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002da0:	60e2                	ld	ra,24(sp)
    80002da2:	6442                	ld	s0,16(sp)
    80002da4:	64a2                	ld	s1,8(sp)
    80002da6:	6105                	addi	sp,sp,32
    80002da8:	8082                	ret
    return p->trapframe->a1;
    80002daa:	6d3c                	ld	a5,88(a0)
    80002dac:	7fa8                	ld	a0,120(a5)
    80002dae:	bfcd                	j	80002da0 <argraw+0x30>
    return p->trapframe->a2;
    80002db0:	6d3c                	ld	a5,88(a0)
    80002db2:	63c8                	ld	a0,128(a5)
    80002db4:	b7f5                	j	80002da0 <argraw+0x30>
    return p->trapframe->a3;
    80002db6:	6d3c                	ld	a5,88(a0)
    80002db8:	67c8                	ld	a0,136(a5)
    80002dba:	b7dd                	j	80002da0 <argraw+0x30>
    return p->trapframe->a4;
    80002dbc:	6d3c                	ld	a5,88(a0)
    80002dbe:	6bc8                	ld	a0,144(a5)
    80002dc0:	b7c5                	j	80002da0 <argraw+0x30>
    return p->trapframe->a5;
    80002dc2:	6d3c                	ld	a5,88(a0)
    80002dc4:	6fc8                	ld	a0,152(a5)
    80002dc6:	bfe9                	j	80002da0 <argraw+0x30>
  panic("argraw");
    80002dc8:	00005517          	auipc	a0,0x5
    80002dcc:	70050513          	addi	a0,a0,1792 # 800084c8 <states.0+0x148>
    80002dd0:	ffffd097          	auipc	ra,0xffffd
    80002dd4:	75a080e7          	jalr	1882(ra) # 8000052a <panic>

0000000080002dd8 <fetchaddr>:
{
    80002dd8:	1101                	addi	sp,sp,-32
    80002dda:	ec06                	sd	ra,24(sp)
    80002ddc:	e822                	sd	s0,16(sp)
    80002dde:	e426                	sd	s1,8(sp)
    80002de0:	e04a                	sd	s2,0(sp)
    80002de2:	1000                	addi	s0,sp,32
    80002de4:	84aa                	mv	s1,a0
    80002de6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	e32080e7          	jalr	-462(ra) # 80001c1a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002df0:	653c                	ld	a5,72(a0)
    80002df2:	02f4f863          	bgeu	s1,a5,80002e22 <fetchaddr+0x4a>
    80002df6:	00848713          	addi	a4,s1,8
    80002dfa:	02e7e663          	bltu	a5,a4,80002e26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dfe:	46a1                	li	a3,8
    80002e00:	8626                	mv	a2,s1
    80002e02:	85ca                	mv	a1,s2
    80002e04:	6928                	ld	a0,80(a0)
    80002e06:	fffff097          	auipc	ra,0xfffff
    80002e0a:	8c4080e7          	jalr	-1852(ra) # 800016ca <copyin>
    80002e0e:	00a03533          	snez	a0,a0
    80002e12:	40a00533          	neg	a0,a0
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6902                	ld	s2,0(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret
    return -1;
    80002e22:	557d                	li	a0,-1
    80002e24:	bfcd                	j	80002e16 <fetchaddr+0x3e>
    80002e26:	557d                	li	a0,-1
    80002e28:	b7fd                	j	80002e16 <fetchaddr+0x3e>

0000000080002e2a <fetchstr>:
{
    80002e2a:	7179                	addi	sp,sp,-48
    80002e2c:	f406                	sd	ra,40(sp)
    80002e2e:	f022                	sd	s0,32(sp)
    80002e30:	ec26                	sd	s1,24(sp)
    80002e32:	e84a                	sd	s2,16(sp)
    80002e34:	e44e                	sd	s3,8(sp)
    80002e36:	1800                	addi	s0,sp,48
    80002e38:	892a                	mv	s2,a0
    80002e3a:	84ae                	mv	s1,a1
    80002e3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e3e:	fffff097          	auipc	ra,0xfffff
    80002e42:	ddc080e7          	jalr	-548(ra) # 80001c1a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e46:	86ce                	mv	a3,s3
    80002e48:	864a                	mv	a2,s2
    80002e4a:	85a6                	mv	a1,s1
    80002e4c:	6928                	ld	a0,80(a0)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	90a080e7          	jalr	-1782(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002e56:	00054763          	bltz	a0,80002e64 <fetchstr+0x3a>
  return strlen(buf);
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	ffffe097          	auipc	ra,0xffffe
    80002e60:	fe6080e7          	jalr	-26(ra) # 80000e42 <strlen>
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6942                	ld	s2,16(sp)
    80002e6c:	69a2                	ld	s3,8(sp)
    80002e6e:	6145                	addi	sp,sp,48
    80002e70:	8082                	ret

0000000080002e72 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	e426                	sd	s1,8(sp)
    80002e7a:	1000                	addi	s0,sp,32
    80002e7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	ef2080e7          	jalr	-270(ra) # 80002d70 <argraw>
    80002e86:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e88:	4501                	li	a0,0
    80002e8a:	60e2                	ld	ra,24(sp)
    80002e8c:	6442                	ld	s0,16(sp)
    80002e8e:	64a2                	ld	s1,8(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
    80002e9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ea0:	00000097          	auipc	ra,0x0
    80002ea4:	ed0080e7          	jalr	-304(ra) # 80002d70 <argraw>
    80002ea8:	e088                	sd	a0,0(s1)
  return 0;
}
    80002eaa:	4501                	li	a0,0
    80002eac:	60e2                	ld	ra,24(sp)
    80002eae:	6442                	ld	s0,16(sp)
    80002eb0:	64a2                	ld	s1,8(sp)
    80002eb2:	6105                	addi	sp,sp,32
    80002eb4:	8082                	ret

0000000080002eb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	e426                	sd	s1,8(sp)
    80002ebe:	e04a                	sd	s2,0(sp)
    80002ec0:	1000                	addi	s0,sp,32
    80002ec2:	84ae                	mv	s1,a1
    80002ec4:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	eaa080e7          	jalr	-342(ra) # 80002d70 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ece:	864a                	mv	a2,s2
    80002ed0:	85a6                	mv	a1,s1
    80002ed2:	00000097          	auipc	ra,0x0
    80002ed6:	f58080e7          	jalr	-168(ra) # 80002e2a <fetchstr>
}
    80002eda:	60e2                	ld	ra,24(sp)
    80002edc:	6442                	ld	s0,16(sp)
    80002ede:	64a2                	ld	s1,8(sp)
    80002ee0:	6902                	ld	s2,0(sp)
    80002ee2:	6105                	addi	sp,sp,32
    80002ee4:	8082                	ret

0000000080002ee6 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002ee6:	1101                	addi	sp,sp,-32
    80002ee8:	ec06                	sd	ra,24(sp)
    80002eea:	e822                	sd	s0,16(sp)
    80002eec:	e426                	sd	s1,8(sp)
    80002eee:	e04a                	sd	s2,0(sp)
    80002ef0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ef2:	fffff097          	auipc	ra,0xfffff
    80002ef6:	d28080e7          	jalr	-728(ra) # 80001c1a <myproc>
    80002efa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002efc:	05853903          	ld	s2,88(a0)
    80002f00:	0a893783          	ld	a5,168(s2)
    80002f04:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002f08:	37fd                	addiw	a5,a5,-1
    80002f0a:	4751                	li	a4,20
    80002f0c:	00f76f63          	bltu	a4,a5,80002f2a <syscall+0x44>
    80002f10:	00369713          	slli	a4,a3,0x3
    80002f14:	00005797          	auipc	a5,0x5
    80002f18:	5f478793          	addi	a5,a5,1524 # 80008508 <syscalls>
    80002f1c:	97ba                	add	a5,a5,a4
    80002f1e:	639c                	ld	a5,0(a5)
    80002f20:	c789                	beqz	a5,80002f2a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f22:	9782                	jalr	a5
    80002f24:	06a93823          	sd	a0,112(s2)
    80002f28:	a839                	j	80002f46 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f2a:	15848613          	addi	a2,s1,344
    80002f2e:	588c                	lw	a1,48(s1)
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	5a050513          	addi	a0,a0,1440 # 800084d0 <states.0+0x150>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	63c080e7          	jalr	1596(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f40:	6cbc                	ld	a5,88(s1)
    80002f42:	577d                	li	a4,-1
    80002f44:	fbb8                	sd	a4,112(a5)
  }
}
    80002f46:	60e2                	ld	ra,24(sp)
    80002f48:	6442                	ld	s0,16(sp)
    80002f4a:	64a2                	ld	s1,8(sp)
    80002f4c:	6902                	ld	s2,0(sp)
    80002f4e:	6105                	addi	sp,sp,32
    80002f50:	8082                	ret

0000000080002f52 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f52:	1101                	addi	sp,sp,-32
    80002f54:	ec06                	sd	ra,24(sp)
    80002f56:	e822                	sd	s0,16(sp)
    80002f58:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f5a:	fec40593          	addi	a1,s0,-20
    80002f5e:	4501                	li	a0,0
    80002f60:	00000097          	auipc	ra,0x0
    80002f64:	f12080e7          	jalr	-238(ra) # 80002e72 <argint>
    return -1;
    80002f68:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f6a:	00054963          	bltz	a0,80002f7c <sys_exit+0x2a>
  exit(n);
    80002f6e:	fec42503          	lw	a0,-20(s0)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	754080e7          	jalr	1876(ra) # 800026c6 <exit>
  return 0;  // not reached
    80002f7a:	4781                	li	a5,0
}
    80002f7c:	853e                	mv	a0,a5
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret

0000000080002f86 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f86:	1141                	addi	sp,sp,-16
    80002f88:	e406                	sd	ra,8(sp)
    80002f8a:	e022                	sd	s0,0(sp)
    80002f8c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f8e:	fffff097          	auipc	ra,0xfffff
    80002f92:	c8c080e7          	jalr	-884(ra) # 80001c1a <myproc>
}
    80002f96:	5908                	lw	a0,48(a0)
    80002f98:	60a2                	ld	ra,8(sp)
    80002f9a:	6402                	ld	s0,0(sp)
    80002f9c:	0141                	addi	sp,sp,16
    80002f9e:	8082                	ret

0000000080002fa0 <sys_fork>:

uint64
sys_fork(void)
{
    80002fa0:	1141                	addi	sp,sp,-16
    80002fa2:	e406                	sd	ra,8(sp)
    80002fa4:	e022                	sd	s0,0(sp)
    80002fa6:	0800                	addi	s0,sp,16
  return fork();
    80002fa8:	fffff097          	auipc	ra,0xfffff
    80002fac:	130080e7          	jalr	304(ra) # 800020d8 <fork>
}
    80002fb0:	60a2                	ld	ra,8(sp)
    80002fb2:	6402                	ld	s0,0(sp)
    80002fb4:	0141                	addi	sp,sp,16
    80002fb6:	8082                	ret

0000000080002fb8 <sys_wait>:

uint64
sys_wait(void)
{
    80002fb8:	1101                	addi	sp,sp,-32
    80002fba:	ec06                	sd	ra,24(sp)
    80002fbc:	e822                	sd	s0,16(sp)
    80002fbe:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fc0:	fe840593          	addi	a1,s0,-24
    80002fc4:	4501                	li	a0,0
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	ece080e7          	jalr	-306(ra) # 80002e94 <argaddr>
    80002fce:	87aa                	mv	a5,a0
    return -1;
    80002fd0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fd2:	0007c863          	bltz	a5,80002fe2 <sys_wait+0x2a>
  return wait(p);
    80002fd6:	fe843503          	ld	a0,-24(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	4f4080e7          	jalr	1268(ra) # 800024ce <wait>
}
    80002fe2:	60e2                	ld	ra,24(sp)
    80002fe4:	6442                	ld	s0,16(sp)
    80002fe6:	6105                	addi	sp,sp,32
    80002fe8:	8082                	ret

0000000080002fea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fea:	7179                	addi	sp,sp,-48
    80002fec:	f406                	sd	ra,40(sp)
    80002fee:	f022                	sd	s0,32(sp)
    80002ff0:	ec26                	sd	s1,24(sp)
    80002ff2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ff4:	fdc40593          	addi	a1,s0,-36
    80002ff8:	4501                	li	a0,0
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	e78080e7          	jalr	-392(ra) # 80002e72 <argint>
    return -1;
    80003002:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003004:	00054f63          	bltz	a0,80003022 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003008:	fffff097          	auipc	ra,0xfffff
    8000300c:	c12080e7          	jalr	-1006(ra) # 80001c1a <myproc>
    80003010:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003012:	fdc42503          	lw	a0,-36(s0)
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	f7c080e7          	jalr	-132(ra) # 80001f92 <growproc>
    8000301e:	00054863          	bltz	a0,8000302e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003022:	8526                	mv	a0,s1
    80003024:	70a2                	ld	ra,40(sp)
    80003026:	7402                	ld	s0,32(sp)
    80003028:	64e2                	ld	s1,24(sp)
    8000302a:	6145                	addi	sp,sp,48
    8000302c:	8082                	ret
    return -1;
    8000302e:	54fd                	li	s1,-1
    80003030:	bfcd                	j	80003022 <sys_sbrk+0x38>

0000000080003032 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003032:	7139                	addi	sp,sp,-64
    80003034:	fc06                	sd	ra,56(sp)
    80003036:	f822                	sd	s0,48(sp)
    80003038:	f426                	sd	s1,40(sp)
    8000303a:	f04a                	sd	s2,32(sp)
    8000303c:	ec4e                	sd	s3,24(sp)
    8000303e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003040:	fcc40593          	addi	a1,s0,-52
    80003044:	4501                	li	a0,0
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	e2c080e7          	jalr	-468(ra) # 80002e72 <argint>
    return -1;
    8000304e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003050:	06054563          	bltz	a0,800030ba <sys_sleep+0x88>
  acquire(&tickslock);
    80003054:	0001a517          	auipc	a0,0x1a
    80003058:	27c50513          	addi	a0,a0,636 # 8001d2d0 <tickslock>
    8000305c:	ffffe097          	auipc	ra,0xffffe
    80003060:	b66080e7          	jalr	-1178(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003064:	00006917          	auipc	s2,0x6
    80003068:	fcc92903          	lw	s2,-52(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000306c:	fcc42783          	lw	a5,-52(s0)
    80003070:	cf85                	beqz	a5,800030a8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003072:	0001a997          	auipc	s3,0x1a
    80003076:	25e98993          	addi	s3,s3,606 # 8001d2d0 <tickslock>
    8000307a:	00006497          	auipc	s1,0x6
    8000307e:	fb648493          	addi	s1,s1,-74 # 80009030 <ticks>
    if(myproc()->killed){
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	b98080e7          	jalr	-1128(ra) # 80001c1a <myproc>
    8000308a:	551c                	lw	a5,40(a0)
    8000308c:	ef9d                	bnez	a5,800030ca <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000308e:	85ce                	mv	a1,s3
    80003090:	8526                	mv	a0,s1
    80003092:	fffff097          	auipc	ra,0xfffff
    80003096:	3d8080e7          	jalr	984(ra) # 8000246a <sleep>
  while(ticks - ticks0 < n){
    8000309a:	409c                	lw	a5,0(s1)
    8000309c:	412787bb          	subw	a5,a5,s2
    800030a0:	fcc42703          	lw	a4,-52(s0)
    800030a4:	fce7efe3          	bltu	a5,a4,80003082 <sys_sleep+0x50>
  }
  release(&tickslock);
    800030a8:	0001a517          	auipc	a0,0x1a
    800030ac:	22850513          	addi	a0,a0,552 # 8001d2d0 <tickslock>
    800030b0:	ffffe097          	auipc	ra,0xffffe
    800030b4:	bc6080e7          	jalr	-1082(ra) # 80000c76 <release>
  return 0;
    800030b8:	4781                	li	a5,0
}
    800030ba:	853e                	mv	a0,a5
    800030bc:	70e2                	ld	ra,56(sp)
    800030be:	7442                	ld	s0,48(sp)
    800030c0:	74a2                	ld	s1,40(sp)
    800030c2:	7902                	ld	s2,32(sp)
    800030c4:	69e2                	ld	s3,24(sp)
    800030c6:	6121                	addi	sp,sp,64
    800030c8:	8082                	ret
      release(&tickslock);
    800030ca:	0001a517          	auipc	a0,0x1a
    800030ce:	20650513          	addi	a0,a0,518 # 8001d2d0 <tickslock>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	ba4080e7          	jalr	-1116(ra) # 80000c76 <release>
      return -1;
    800030da:	57fd                	li	a5,-1
    800030dc:	bff9                	j	800030ba <sys_sleep+0x88>

00000000800030de <sys_kill>:

uint64
sys_kill(void)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030e6:	fec40593          	addi	a1,s0,-20
    800030ea:	4501                	li	a0,0
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	d86080e7          	jalr	-634(ra) # 80002e72 <argint>
    800030f4:	87aa                	mv	a5,a0
    return -1;
    800030f6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030f8:	0007c863          	bltz	a5,80003108 <sys_kill+0x2a>
  return kill(pid);
    800030fc:	fec42503          	lw	a0,-20(s0)
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	6b2080e7          	jalr	1714(ra) # 800027b2 <kill>
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	6105                	addi	sp,sp,32
    8000310e:	8082                	ret

0000000080003110 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003110:	1101                	addi	sp,sp,-32
    80003112:	ec06                	sd	ra,24(sp)
    80003114:	e822                	sd	s0,16(sp)
    80003116:	e426                	sd	s1,8(sp)
    80003118:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000311a:	0001a517          	auipc	a0,0x1a
    8000311e:	1b650513          	addi	a0,a0,438 # 8001d2d0 <tickslock>
    80003122:	ffffe097          	auipc	ra,0xffffe
    80003126:	aa0080e7          	jalr	-1376(ra) # 80000bc2 <acquire>
  xticks = ticks;
    8000312a:	00006497          	auipc	s1,0x6
    8000312e:	f064a483          	lw	s1,-250(s1) # 80009030 <ticks>
  release(&tickslock);
    80003132:	0001a517          	auipc	a0,0x1a
    80003136:	19e50513          	addi	a0,a0,414 # 8001d2d0 <tickslock>
    8000313a:	ffffe097          	auipc	ra,0xffffe
    8000313e:	b3c080e7          	jalr	-1220(ra) # 80000c76 <release>
  return xticks;
}
    80003142:	02049513          	slli	a0,s1,0x20
    80003146:	9101                	srli	a0,a0,0x20
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret

0000000080003152 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003152:	7179                	addi	sp,sp,-48
    80003154:	f406                	sd	ra,40(sp)
    80003156:	f022                	sd	s0,32(sp)
    80003158:	ec26                	sd	s1,24(sp)
    8000315a:	e84a                	sd	s2,16(sp)
    8000315c:	e44e                	sd	s3,8(sp)
    8000315e:	e052                	sd	s4,0(sp)
    80003160:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003162:	00005597          	auipc	a1,0x5
    80003166:	45658593          	addi	a1,a1,1110 # 800085b8 <syscalls+0xb0>
    8000316a:	0001a517          	auipc	a0,0x1a
    8000316e:	17e50513          	addi	a0,a0,382 # 8001d2e8 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	9c0080e7          	jalr	-1600(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000317a:	00022797          	auipc	a5,0x22
    8000317e:	16e78793          	addi	a5,a5,366 # 800252e8 <bcache+0x8000>
    80003182:	00022717          	auipc	a4,0x22
    80003186:	3ce70713          	addi	a4,a4,974 # 80025550 <bcache+0x8268>
    8000318a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000318e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003192:	0001a497          	auipc	s1,0x1a
    80003196:	16e48493          	addi	s1,s1,366 # 8001d300 <bcache+0x18>
    b->next = bcache.head.next;
    8000319a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000319c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000319e:	00005a17          	auipc	s4,0x5
    800031a2:	422a0a13          	addi	s4,s4,1058 # 800085c0 <syscalls+0xb8>
    b->next = bcache.head.next;
    800031a6:	2b893783          	ld	a5,696(s2)
    800031aa:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031ac:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031b0:	85d2                	mv	a1,s4
    800031b2:	01048513          	addi	a0,s1,16
    800031b6:	00001097          	auipc	ra,0x1
    800031ba:	7d4080e7          	jalr	2004(ra) # 8000498a <initsleeplock>
    bcache.head.next->prev = b;
    800031be:	2b893783          	ld	a5,696(s2)
    800031c2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031c4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031c8:	45848493          	addi	s1,s1,1112
    800031cc:	fd349de3          	bne	s1,s3,800031a6 <binit+0x54>
  }
}
    800031d0:	70a2                	ld	ra,40(sp)
    800031d2:	7402                	ld	s0,32(sp)
    800031d4:	64e2                	ld	s1,24(sp)
    800031d6:	6942                	ld	s2,16(sp)
    800031d8:	69a2                	ld	s3,8(sp)
    800031da:	6a02                	ld	s4,0(sp)
    800031dc:	6145                	addi	sp,sp,48
    800031de:	8082                	ret

00000000800031e0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031e0:	7179                	addi	sp,sp,-48
    800031e2:	f406                	sd	ra,40(sp)
    800031e4:	f022                	sd	s0,32(sp)
    800031e6:	ec26                	sd	s1,24(sp)
    800031e8:	e84a                	sd	s2,16(sp)
    800031ea:	e44e                	sd	s3,8(sp)
    800031ec:	1800                	addi	s0,sp,48
    800031ee:	892a                	mv	s2,a0
    800031f0:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031f2:	0001a517          	auipc	a0,0x1a
    800031f6:	0f650513          	addi	a0,a0,246 # 8001d2e8 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	9c8080e7          	jalr	-1592(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003202:	00022497          	auipc	s1,0x22
    80003206:	39e4b483          	ld	s1,926(s1) # 800255a0 <bcache+0x82b8>
    8000320a:	00022797          	auipc	a5,0x22
    8000320e:	34678793          	addi	a5,a5,838 # 80025550 <bcache+0x8268>
    80003212:	02f48f63          	beq	s1,a5,80003250 <bread+0x70>
    80003216:	873e                	mv	a4,a5
    80003218:	a021                	j	80003220 <bread+0x40>
    8000321a:	68a4                	ld	s1,80(s1)
    8000321c:	02e48a63          	beq	s1,a4,80003250 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003220:	449c                	lw	a5,8(s1)
    80003222:	ff279ce3          	bne	a5,s2,8000321a <bread+0x3a>
    80003226:	44dc                	lw	a5,12(s1)
    80003228:	ff3799e3          	bne	a5,s3,8000321a <bread+0x3a>
      b->refcnt++;
    8000322c:	40bc                	lw	a5,64(s1)
    8000322e:	2785                	addiw	a5,a5,1
    80003230:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003232:	0001a517          	auipc	a0,0x1a
    80003236:	0b650513          	addi	a0,a0,182 # 8001d2e8 <bcache>
    8000323a:	ffffe097          	auipc	ra,0xffffe
    8000323e:	a3c080e7          	jalr	-1476(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003242:	01048513          	addi	a0,s1,16
    80003246:	00001097          	auipc	ra,0x1
    8000324a:	77e080e7          	jalr	1918(ra) # 800049c4 <acquiresleep>
      return b;
    8000324e:	a8b9                	j	800032ac <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003250:	00022497          	auipc	s1,0x22
    80003254:	3484b483          	ld	s1,840(s1) # 80025598 <bcache+0x82b0>
    80003258:	00022797          	auipc	a5,0x22
    8000325c:	2f878793          	addi	a5,a5,760 # 80025550 <bcache+0x8268>
    80003260:	00f48863          	beq	s1,a5,80003270 <bread+0x90>
    80003264:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003266:	40bc                	lw	a5,64(s1)
    80003268:	cf81                	beqz	a5,80003280 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000326a:	64a4                	ld	s1,72(s1)
    8000326c:	fee49de3          	bne	s1,a4,80003266 <bread+0x86>
  panic("bget: no buffers");
    80003270:	00005517          	auipc	a0,0x5
    80003274:	35850513          	addi	a0,a0,856 # 800085c8 <syscalls+0xc0>
    80003278:	ffffd097          	auipc	ra,0xffffd
    8000327c:	2b2080e7          	jalr	690(ra) # 8000052a <panic>
      b->dev = dev;
    80003280:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003284:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003288:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000328c:	4785                	li	a5,1
    8000328e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003290:	0001a517          	auipc	a0,0x1a
    80003294:	05850513          	addi	a0,a0,88 # 8001d2e8 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	9de080e7          	jalr	-1570(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800032a0:	01048513          	addi	a0,s1,16
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	720080e7          	jalr	1824(ra) # 800049c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032ac:	409c                	lw	a5,0(s1)
    800032ae:	cb89                	beqz	a5,800032c0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032b0:	8526                	mv	a0,s1
    800032b2:	70a2                	ld	ra,40(sp)
    800032b4:	7402                	ld	s0,32(sp)
    800032b6:	64e2                	ld	s1,24(sp)
    800032b8:	6942                	ld	s2,16(sp)
    800032ba:	69a2                	ld	s3,8(sp)
    800032bc:	6145                	addi	sp,sp,48
    800032be:	8082                	ret
    virtio_disk_rw(b, 0);
    800032c0:	4581                	li	a1,0
    800032c2:	8526                	mv	a0,s1
    800032c4:	00003097          	auipc	ra,0x3
    800032c8:	452080e7          	jalr	1106(ra) # 80006716 <virtio_disk_rw>
    b->valid = 1;
    800032cc:	4785                	li	a5,1
    800032ce:	c09c                	sw	a5,0(s1)
  return b;
    800032d0:	b7c5                	j	800032b0 <bread+0xd0>

00000000800032d2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032d2:	1101                	addi	sp,sp,-32
    800032d4:	ec06                	sd	ra,24(sp)
    800032d6:	e822                	sd	s0,16(sp)
    800032d8:	e426                	sd	s1,8(sp)
    800032da:	1000                	addi	s0,sp,32
    800032dc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032de:	0541                	addi	a0,a0,16
    800032e0:	00001097          	auipc	ra,0x1
    800032e4:	77e080e7          	jalr	1918(ra) # 80004a5e <holdingsleep>
    800032e8:	cd01                	beqz	a0,80003300 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032ea:	4585                	li	a1,1
    800032ec:	8526                	mv	a0,s1
    800032ee:	00003097          	auipc	ra,0x3
    800032f2:	428080e7          	jalr	1064(ra) # 80006716 <virtio_disk_rw>
}
    800032f6:	60e2                	ld	ra,24(sp)
    800032f8:	6442                	ld	s0,16(sp)
    800032fa:	64a2                	ld	s1,8(sp)
    800032fc:	6105                	addi	sp,sp,32
    800032fe:	8082                	ret
    panic("bwrite");
    80003300:	00005517          	auipc	a0,0x5
    80003304:	2e050513          	addi	a0,a0,736 # 800085e0 <syscalls+0xd8>
    80003308:	ffffd097          	auipc	ra,0xffffd
    8000330c:	222080e7          	jalr	546(ra) # 8000052a <panic>

0000000080003310 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003310:	1101                	addi	sp,sp,-32
    80003312:	ec06                	sd	ra,24(sp)
    80003314:	e822                	sd	s0,16(sp)
    80003316:	e426                	sd	s1,8(sp)
    80003318:	e04a                	sd	s2,0(sp)
    8000331a:	1000                	addi	s0,sp,32
    8000331c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000331e:	01050913          	addi	s2,a0,16
    80003322:	854a                	mv	a0,s2
    80003324:	00001097          	auipc	ra,0x1
    80003328:	73a080e7          	jalr	1850(ra) # 80004a5e <holdingsleep>
    8000332c:	c92d                	beqz	a0,8000339e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000332e:	854a                	mv	a0,s2
    80003330:	00001097          	auipc	ra,0x1
    80003334:	6ea080e7          	jalr	1770(ra) # 80004a1a <releasesleep>

  acquire(&bcache.lock);
    80003338:	0001a517          	auipc	a0,0x1a
    8000333c:	fb050513          	addi	a0,a0,-80 # 8001d2e8 <bcache>
    80003340:	ffffe097          	auipc	ra,0xffffe
    80003344:	882080e7          	jalr	-1918(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003348:	40bc                	lw	a5,64(s1)
    8000334a:	37fd                	addiw	a5,a5,-1
    8000334c:	0007871b          	sext.w	a4,a5
    80003350:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003352:	eb05                	bnez	a4,80003382 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003354:	68bc                	ld	a5,80(s1)
    80003356:	64b8                	ld	a4,72(s1)
    80003358:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000335a:	64bc                	ld	a5,72(s1)
    8000335c:	68b8                	ld	a4,80(s1)
    8000335e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003360:	00022797          	auipc	a5,0x22
    80003364:	f8878793          	addi	a5,a5,-120 # 800252e8 <bcache+0x8000>
    80003368:	2b87b703          	ld	a4,696(a5)
    8000336c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000336e:	00022717          	auipc	a4,0x22
    80003372:	1e270713          	addi	a4,a4,482 # 80025550 <bcache+0x8268>
    80003376:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003378:	2b87b703          	ld	a4,696(a5)
    8000337c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000337e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003382:	0001a517          	auipc	a0,0x1a
    80003386:	f6650513          	addi	a0,a0,-154 # 8001d2e8 <bcache>
    8000338a:	ffffe097          	auipc	ra,0xffffe
    8000338e:	8ec080e7          	jalr	-1812(ra) # 80000c76 <release>
}
    80003392:	60e2                	ld	ra,24(sp)
    80003394:	6442                	ld	s0,16(sp)
    80003396:	64a2                	ld	s1,8(sp)
    80003398:	6902                	ld	s2,0(sp)
    8000339a:	6105                	addi	sp,sp,32
    8000339c:	8082                	ret
    panic("brelse");
    8000339e:	00005517          	auipc	a0,0x5
    800033a2:	24a50513          	addi	a0,a0,586 # 800085e8 <syscalls+0xe0>
    800033a6:	ffffd097          	auipc	ra,0xffffd
    800033aa:	184080e7          	jalr	388(ra) # 8000052a <panic>

00000000800033ae <bpin>:

void
bpin(struct buf *b) {
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	1000                	addi	s0,sp,32
    800033b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ba:	0001a517          	auipc	a0,0x1a
    800033be:	f2e50513          	addi	a0,a0,-210 # 8001d2e8 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	800080e7          	jalr	-2048(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	2785                	addiw	a5,a5,1
    800033ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d0:	0001a517          	auipc	a0,0x1a
    800033d4:	f1850513          	addi	a0,a0,-232 # 8001d2e8 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	89e080e7          	jalr	-1890(ra) # 80000c76 <release>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6105                	addi	sp,sp,32
    800033e8:	8082                	ret

00000000800033ea <bunpin>:

void
bunpin(struct buf *b) {
    800033ea:	1101                	addi	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	e426                	sd	s1,8(sp)
    800033f2:	1000                	addi	s0,sp,32
    800033f4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033f6:	0001a517          	auipc	a0,0x1a
    800033fa:	ef250513          	addi	a0,a0,-270 # 8001d2e8 <bcache>
    800033fe:	ffffd097          	auipc	ra,0xffffd
    80003402:	7c4080e7          	jalr	1988(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003406:	40bc                	lw	a5,64(s1)
    80003408:	37fd                	addiw	a5,a5,-1
    8000340a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000340c:	0001a517          	auipc	a0,0x1a
    80003410:	edc50513          	addi	a0,a0,-292 # 8001d2e8 <bcache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	862080e7          	jalr	-1950(ra) # 80000c76 <release>
}
    8000341c:	60e2                	ld	ra,24(sp)
    8000341e:	6442                	ld	s0,16(sp)
    80003420:	64a2                	ld	s1,8(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003426:	1101                	addi	sp,sp,-32
    80003428:	ec06                	sd	ra,24(sp)
    8000342a:	e822                	sd	s0,16(sp)
    8000342c:	e426                	sd	s1,8(sp)
    8000342e:	e04a                	sd	s2,0(sp)
    80003430:	1000                	addi	s0,sp,32
    80003432:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003434:	00d5d59b          	srliw	a1,a1,0xd
    80003438:	00022797          	auipc	a5,0x22
    8000343c:	58c7a783          	lw	a5,1420(a5) # 800259c4 <sb+0x1c>
    80003440:	9dbd                	addw	a1,a1,a5
    80003442:	00000097          	auipc	ra,0x0
    80003446:	d9e080e7          	jalr	-610(ra) # 800031e0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000344a:	0074f713          	andi	a4,s1,7
    8000344e:	4785                	li	a5,1
    80003450:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003454:	14ce                	slli	s1,s1,0x33
    80003456:	90d9                	srli	s1,s1,0x36
    80003458:	00950733          	add	a4,a0,s1
    8000345c:	05874703          	lbu	a4,88(a4)
    80003460:	00e7f6b3          	and	a3,a5,a4
    80003464:	c69d                	beqz	a3,80003492 <bfree+0x6c>
    80003466:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003468:	94aa                	add	s1,s1,a0
    8000346a:	fff7c793          	not	a5,a5
    8000346e:	8ff9                	and	a5,a5,a4
    80003470:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003474:	00001097          	auipc	ra,0x1
    80003478:	430080e7          	jalr	1072(ra) # 800048a4 <log_write>
  brelse(bp);
    8000347c:	854a                	mv	a0,s2
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e92080e7          	jalr	-366(ra) # 80003310 <brelse>
}
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6902                	ld	s2,0(sp)
    8000348e:	6105                	addi	sp,sp,32
    80003490:	8082                	ret
    panic("freeing free block");
    80003492:	00005517          	auipc	a0,0x5
    80003496:	15e50513          	addi	a0,a0,350 # 800085f0 <syscalls+0xe8>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	090080e7          	jalr	144(ra) # 8000052a <panic>

00000000800034a2 <balloc>:
{
    800034a2:	711d                	addi	sp,sp,-96
    800034a4:	ec86                	sd	ra,88(sp)
    800034a6:	e8a2                	sd	s0,80(sp)
    800034a8:	e4a6                	sd	s1,72(sp)
    800034aa:	e0ca                	sd	s2,64(sp)
    800034ac:	fc4e                	sd	s3,56(sp)
    800034ae:	f852                	sd	s4,48(sp)
    800034b0:	f456                	sd	s5,40(sp)
    800034b2:	f05a                	sd	s6,32(sp)
    800034b4:	ec5e                	sd	s7,24(sp)
    800034b6:	e862                	sd	s8,16(sp)
    800034b8:	e466                	sd	s9,8(sp)
    800034ba:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034bc:	00022797          	auipc	a5,0x22
    800034c0:	4f07a783          	lw	a5,1264(a5) # 800259ac <sb+0x4>
    800034c4:	cbd1                	beqz	a5,80003558 <balloc+0xb6>
    800034c6:	8baa                	mv	s7,a0
    800034c8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034ca:	00022b17          	auipc	s6,0x22
    800034ce:	4deb0b13          	addi	s6,s6,1246 # 800259a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034d4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034d6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034d8:	6c89                	lui	s9,0x2
    800034da:	a831                	j	800034f6 <balloc+0x54>
    brelse(bp);
    800034dc:	854a                	mv	a0,s2
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	e32080e7          	jalr	-462(ra) # 80003310 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034e6:	015c87bb          	addw	a5,s9,s5
    800034ea:	00078a9b          	sext.w	s5,a5
    800034ee:	004b2703          	lw	a4,4(s6)
    800034f2:	06eaf363          	bgeu	s5,a4,80003558 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034f6:	41fad79b          	sraiw	a5,s5,0x1f
    800034fa:	0137d79b          	srliw	a5,a5,0x13
    800034fe:	015787bb          	addw	a5,a5,s5
    80003502:	40d7d79b          	sraiw	a5,a5,0xd
    80003506:	01cb2583          	lw	a1,28(s6)
    8000350a:	9dbd                	addw	a1,a1,a5
    8000350c:	855e                	mv	a0,s7
    8000350e:	00000097          	auipc	ra,0x0
    80003512:	cd2080e7          	jalr	-814(ra) # 800031e0 <bread>
    80003516:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003518:	004b2503          	lw	a0,4(s6)
    8000351c:	000a849b          	sext.w	s1,s5
    80003520:	8662                	mv	a2,s8
    80003522:	faa4fde3          	bgeu	s1,a0,800034dc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003526:	41f6579b          	sraiw	a5,a2,0x1f
    8000352a:	01d7d69b          	srliw	a3,a5,0x1d
    8000352e:	00c6873b          	addw	a4,a3,a2
    80003532:	00777793          	andi	a5,a4,7
    80003536:	9f95                	subw	a5,a5,a3
    80003538:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000353c:	4037571b          	sraiw	a4,a4,0x3
    80003540:	00e906b3          	add	a3,s2,a4
    80003544:	0586c683          	lbu	a3,88(a3)
    80003548:	00d7f5b3          	and	a1,a5,a3
    8000354c:	cd91                	beqz	a1,80003568 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000354e:	2605                	addiw	a2,a2,1
    80003550:	2485                	addiw	s1,s1,1
    80003552:	fd4618e3          	bne	a2,s4,80003522 <balloc+0x80>
    80003556:	b759                	j	800034dc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003558:	00005517          	auipc	a0,0x5
    8000355c:	0b050513          	addi	a0,a0,176 # 80008608 <syscalls+0x100>
    80003560:	ffffd097          	auipc	ra,0xffffd
    80003564:	fca080e7          	jalr	-54(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003568:	974a                	add	a4,a4,s2
    8000356a:	8fd5                	or	a5,a5,a3
    8000356c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003570:	854a                	mv	a0,s2
    80003572:	00001097          	auipc	ra,0x1
    80003576:	332080e7          	jalr	818(ra) # 800048a4 <log_write>
        brelse(bp);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	d94080e7          	jalr	-620(ra) # 80003310 <brelse>
  bp = bread(dev, bno);
    80003584:	85a6                	mv	a1,s1
    80003586:	855e                	mv	a0,s7
    80003588:	00000097          	auipc	ra,0x0
    8000358c:	c58080e7          	jalr	-936(ra) # 800031e0 <bread>
    80003590:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003592:	40000613          	li	a2,1024
    80003596:	4581                	li	a1,0
    80003598:	05850513          	addi	a0,a0,88
    8000359c:	ffffd097          	auipc	ra,0xffffd
    800035a0:	722080e7          	jalr	1826(ra) # 80000cbe <memset>
  log_write(bp);
    800035a4:	854a                	mv	a0,s2
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	2fe080e7          	jalr	766(ra) # 800048a4 <log_write>
  brelse(bp);
    800035ae:	854a                	mv	a0,s2
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	d60080e7          	jalr	-672(ra) # 80003310 <brelse>
}
    800035b8:	8526                	mv	a0,s1
    800035ba:	60e6                	ld	ra,88(sp)
    800035bc:	6446                	ld	s0,80(sp)
    800035be:	64a6                	ld	s1,72(sp)
    800035c0:	6906                	ld	s2,64(sp)
    800035c2:	79e2                	ld	s3,56(sp)
    800035c4:	7a42                	ld	s4,48(sp)
    800035c6:	7aa2                	ld	s5,40(sp)
    800035c8:	7b02                	ld	s6,32(sp)
    800035ca:	6be2                	ld	s7,24(sp)
    800035cc:	6c42                	ld	s8,16(sp)
    800035ce:	6ca2                	ld	s9,8(sp)
    800035d0:	6125                	addi	sp,sp,96
    800035d2:	8082                	ret

00000000800035d4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035d4:	7179                	addi	sp,sp,-48
    800035d6:	f406                	sd	ra,40(sp)
    800035d8:	f022                	sd	s0,32(sp)
    800035da:	ec26                	sd	s1,24(sp)
    800035dc:	e84a                	sd	s2,16(sp)
    800035de:	e44e                	sd	s3,8(sp)
    800035e0:	e052                	sd	s4,0(sp)
    800035e2:	1800                	addi	s0,sp,48
    800035e4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035e6:	47ad                	li	a5,11
    800035e8:	04b7fe63          	bgeu	a5,a1,80003644 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035ec:	ff45849b          	addiw	s1,a1,-12
    800035f0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035f4:	0ff00793          	li	a5,255
    800035f8:	0ae7e463          	bltu	a5,a4,800036a0 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035fc:	08052583          	lw	a1,128(a0)
    80003600:	c5b5                	beqz	a1,8000366c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003602:	00092503          	lw	a0,0(s2)
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	bda080e7          	jalr	-1062(ra) # 800031e0 <bread>
    8000360e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003610:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003614:	02049713          	slli	a4,s1,0x20
    80003618:	01e75593          	srli	a1,a4,0x1e
    8000361c:	00b784b3          	add	s1,a5,a1
    80003620:	0004a983          	lw	s3,0(s1)
    80003624:	04098e63          	beqz	s3,80003680 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003628:	8552                	mv	a0,s4
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	ce6080e7          	jalr	-794(ra) # 80003310 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003632:	854e                	mv	a0,s3
    80003634:	70a2                	ld	ra,40(sp)
    80003636:	7402                	ld	s0,32(sp)
    80003638:	64e2                	ld	s1,24(sp)
    8000363a:	6942                	ld	s2,16(sp)
    8000363c:	69a2                	ld	s3,8(sp)
    8000363e:	6a02                	ld	s4,0(sp)
    80003640:	6145                	addi	sp,sp,48
    80003642:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003644:	02059793          	slli	a5,a1,0x20
    80003648:	01e7d593          	srli	a1,a5,0x1e
    8000364c:	00b504b3          	add	s1,a0,a1
    80003650:	0504a983          	lw	s3,80(s1)
    80003654:	fc099fe3          	bnez	s3,80003632 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003658:	4108                	lw	a0,0(a0)
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	e48080e7          	jalr	-440(ra) # 800034a2 <balloc>
    80003662:	0005099b          	sext.w	s3,a0
    80003666:	0534a823          	sw	s3,80(s1)
    8000366a:	b7e1                	j	80003632 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000366c:	4108                	lw	a0,0(a0)
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	e34080e7          	jalr	-460(ra) # 800034a2 <balloc>
    80003676:	0005059b          	sext.w	a1,a0
    8000367a:	08b92023          	sw	a1,128(s2)
    8000367e:	b751                	j	80003602 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003680:	00092503          	lw	a0,0(s2)
    80003684:	00000097          	auipc	ra,0x0
    80003688:	e1e080e7          	jalr	-482(ra) # 800034a2 <balloc>
    8000368c:	0005099b          	sext.w	s3,a0
    80003690:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003694:	8552                	mv	a0,s4
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	20e080e7          	jalr	526(ra) # 800048a4 <log_write>
    8000369e:	b769                	j	80003628 <bmap+0x54>
  panic("bmap: out of range");
    800036a0:	00005517          	auipc	a0,0x5
    800036a4:	f8050513          	addi	a0,a0,-128 # 80008620 <syscalls+0x118>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	e82080e7          	jalr	-382(ra) # 8000052a <panic>

00000000800036b0 <iget>:
{
    800036b0:	7179                	addi	sp,sp,-48
    800036b2:	f406                	sd	ra,40(sp)
    800036b4:	f022                	sd	s0,32(sp)
    800036b6:	ec26                	sd	s1,24(sp)
    800036b8:	e84a                	sd	s2,16(sp)
    800036ba:	e44e                	sd	s3,8(sp)
    800036bc:	e052                	sd	s4,0(sp)
    800036be:	1800                	addi	s0,sp,48
    800036c0:	89aa                	mv	s3,a0
    800036c2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036c4:	00022517          	auipc	a0,0x22
    800036c8:	30450513          	addi	a0,a0,772 # 800259c8 <itable>
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	4f6080e7          	jalr	1270(ra) # 80000bc2 <acquire>
  empty = 0;
    800036d4:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036d6:	00022497          	auipc	s1,0x22
    800036da:	30a48493          	addi	s1,s1,778 # 800259e0 <itable+0x18>
    800036de:	00024697          	auipc	a3,0x24
    800036e2:	d9268693          	addi	a3,a3,-622 # 80027470 <log>
    800036e6:	a039                	j	800036f4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e8:	02090b63          	beqz	s2,8000371e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ec:	08848493          	addi	s1,s1,136
    800036f0:	02d48a63          	beq	s1,a3,80003724 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036f4:	449c                	lw	a5,8(s1)
    800036f6:	fef059e3          	blez	a5,800036e8 <iget+0x38>
    800036fa:	4098                	lw	a4,0(s1)
    800036fc:	ff3716e3          	bne	a4,s3,800036e8 <iget+0x38>
    80003700:	40d8                	lw	a4,4(s1)
    80003702:	ff4713e3          	bne	a4,s4,800036e8 <iget+0x38>
      ip->ref++;
    80003706:	2785                	addiw	a5,a5,1
    80003708:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000370a:	00022517          	auipc	a0,0x22
    8000370e:	2be50513          	addi	a0,a0,702 # 800259c8 <itable>
    80003712:	ffffd097          	auipc	ra,0xffffd
    80003716:	564080e7          	jalr	1380(ra) # 80000c76 <release>
      return ip;
    8000371a:	8926                	mv	s2,s1
    8000371c:	a03d                	j	8000374a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000371e:	f7f9                	bnez	a5,800036ec <iget+0x3c>
    80003720:	8926                	mv	s2,s1
    80003722:	b7e9                	j	800036ec <iget+0x3c>
  if(empty == 0)
    80003724:	02090c63          	beqz	s2,8000375c <iget+0xac>
  ip->dev = dev;
    80003728:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000372c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003730:	4785                	li	a5,1
    80003732:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003736:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000373a:	00022517          	auipc	a0,0x22
    8000373e:	28e50513          	addi	a0,a0,654 # 800259c8 <itable>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	534080e7          	jalr	1332(ra) # 80000c76 <release>
}
    8000374a:	854a                	mv	a0,s2
    8000374c:	70a2                	ld	ra,40(sp)
    8000374e:	7402                	ld	s0,32(sp)
    80003750:	64e2                	ld	s1,24(sp)
    80003752:	6942                	ld	s2,16(sp)
    80003754:	69a2                	ld	s3,8(sp)
    80003756:	6a02                	ld	s4,0(sp)
    80003758:	6145                	addi	sp,sp,48
    8000375a:	8082                	ret
    panic("iget: no inodes");
    8000375c:	00005517          	auipc	a0,0x5
    80003760:	edc50513          	addi	a0,a0,-292 # 80008638 <syscalls+0x130>
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	dc6080e7          	jalr	-570(ra) # 8000052a <panic>

000000008000376c <fsinit>:
fsinit(int dev) {
    8000376c:	7179                	addi	sp,sp,-48
    8000376e:	f406                	sd	ra,40(sp)
    80003770:	f022                	sd	s0,32(sp)
    80003772:	ec26                	sd	s1,24(sp)
    80003774:	e84a                	sd	s2,16(sp)
    80003776:	e44e                	sd	s3,8(sp)
    80003778:	1800                	addi	s0,sp,48
    8000377a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000377c:	4585                	li	a1,1
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	a62080e7          	jalr	-1438(ra) # 800031e0 <bread>
    80003786:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003788:	00022997          	auipc	s3,0x22
    8000378c:	22098993          	addi	s3,s3,544 # 800259a8 <sb>
    80003790:	02000613          	li	a2,32
    80003794:	05850593          	addi	a1,a0,88
    80003798:	854e                	mv	a0,s3
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	580080e7          	jalr	1408(ra) # 80000d1a <memmove>
  brelse(bp);
    800037a2:	8526                	mv	a0,s1
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	b6c080e7          	jalr	-1172(ra) # 80003310 <brelse>
  if(sb.magic != FSMAGIC)
    800037ac:	0009a703          	lw	a4,0(s3)
    800037b0:	102037b7          	lui	a5,0x10203
    800037b4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037b8:	02f71263          	bne	a4,a5,800037dc <fsinit+0x70>
  initlog(dev, &sb);
    800037bc:	00022597          	auipc	a1,0x22
    800037c0:	1ec58593          	addi	a1,a1,492 # 800259a8 <sb>
    800037c4:	854a                	mv	a0,s2
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	e60080e7          	jalr	-416(ra) # 80004626 <initlog>
}
    800037ce:	70a2                	ld	ra,40(sp)
    800037d0:	7402                	ld	s0,32(sp)
    800037d2:	64e2                	ld	s1,24(sp)
    800037d4:	6942                	ld	s2,16(sp)
    800037d6:	69a2                	ld	s3,8(sp)
    800037d8:	6145                	addi	sp,sp,48
    800037da:	8082                	ret
    panic("invalid file system");
    800037dc:	00005517          	auipc	a0,0x5
    800037e0:	e6c50513          	addi	a0,a0,-404 # 80008648 <syscalls+0x140>
    800037e4:	ffffd097          	auipc	ra,0xffffd
    800037e8:	d46080e7          	jalr	-698(ra) # 8000052a <panic>

00000000800037ec <iinit>:
{
    800037ec:	7179                	addi	sp,sp,-48
    800037ee:	f406                	sd	ra,40(sp)
    800037f0:	f022                	sd	s0,32(sp)
    800037f2:	ec26                	sd	s1,24(sp)
    800037f4:	e84a                	sd	s2,16(sp)
    800037f6:	e44e                	sd	s3,8(sp)
    800037f8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037fa:	00005597          	auipc	a1,0x5
    800037fe:	e6658593          	addi	a1,a1,-410 # 80008660 <syscalls+0x158>
    80003802:	00022517          	auipc	a0,0x22
    80003806:	1c650513          	addi	a0,a0,454 # 800259c8 <itable>
    8000380a:	ffffd097          	auipc	ra,0xffffd
    8000380e:	328080e7          	jalr	808(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003812:	00022497          	auipc	s1,0x22
    80003816:	1de48493          	addi	s1,s1,478 # 800259f0 <itable+0x28>
    8000381a:	00024997          	auipc	s3,0x24
    8000381e:	c6698993          	addi	s3,s3,-922 # 80027480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003822:	00005917          	auipc	s2,0x5
    80003826:	e4690913          	addi	s2,s2,-442 # 80008668 <syscalls+0x160>
    8000382a:	85ca                	mv	a1,s2
    8000382c:	8526                	mv	a0,s1
    8000382e:	00001097          	auipc	ra,0x1
    80003832:	15c080e7          	jalr	348(ra) # 8000498a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003836:	08848493          	addi	s1,s1,136
    8000383a:	ff3498e3          	bne	s1,s3,8000382a <iinit+0x3e>
}
    8000383e:	70a2                	ld	ra,40(sp)
    80003840:	7402                	ld	s0,32(sp)
    80003842:	64e2                	ld	s1,24(sp)
    80003844:	6942                	ld	s2,16(sp)
    80003846:	69a2                	ld	s3,8(sp)
    80003848:	6145                	addi	sp,sp,48
    8000384a:	8082                	ret

000000008000384c <ialloc>:
{
    8000384c:	715d                	addi	sp,sp,-80
    8000384e:	e486                	sd	ra,72(sp)
    80003850:	e0a2                	sd	s0,64(sp)
    80003852:	fc26                	sd	s1,56(sp)
    80003854:	f84a                	sd	s2,48(sp)
    80003856:	f44e                	sd	s3,40(sp)
    80003858:	f052                	sd	s4,32(sp)
    8000385a:	ec56                	sd	s5,24(sp)
    8000385c:	e85a                	sd	s6,16(sp)
    8000385e:	e45e                	sd	s7,8(sp)
    80003860:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003862:	00022717          	auipc	a4,0x22
    80003866:	15272703          	lw	a4,338(a4) # 800259b4 <sb+0xc>
    8000386a:	4785                	li	a5,1
    8000386c:	04e7fa63          	bgeu	a5,a4,800038c0 <ialloc+0x74>
    80003870:	8aaa                	mv	s5,a0
    80003872:	8bae                	mv	s7,a1
    80003874:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003876:	00022a17          	auipc	s4,0x22
    8000387a:	132a0a13          	addi	s4,s4,306 # 800259a8 <sb>
    8000387e:	00048b1b          	sext.w	s6,s1
    80003882:	0044d793          	srli	a5,s1,0x4
    80003886:	018a2583          	lw	a1,24(s4)
    8000388a:	9dbd                	addw	a1,a1,a5
    8000388c:	8556                	mv	a0,s5
    8000388e:	00000097          	auipc	ra,0x0
    80003892:	952080e7          	jalr	-1710(ra) # 800031e0 <bread>
    80003896:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003898:	05850993          	addi	s3,a0,88
    8000389c:	00f4f793          	andi	a5,s1,15
    800038a0:	079a                	slli	a5,a5,0x6
    800038a2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038a4:	00099783          	lh	a5,0(s3)
    800038a8:	c785                	beqz	a5,800038d0 <ialloc+0x84>
    brelse(bp);
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	a66080e7          	jalr	-1434(ra) # 80003310 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b2:	0485                	addi	s1,s1,1
    800038b4:	00ca2703          	lw	a4,12(s4)
    800038b8:	0004879b          	sext.w	a5,s1
    800038bc:	fce7e1e3          	bltu	a5,a4,8000387e <ialloc+0x32>
  panic("ialloc: no inodes");
    800038c0:	00005517          	auipc	a0,0x5
    800038c4:	db050513          	addi	a0,a0,-592 # 80008670 <syscalls+0x168>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	c62080e7          	jalr	-926(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038d0:	04000613          	li	a2,64
    800038d4:	4581                	li	a1,0
    800038d6:	854e                	mv	a0,s3
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	3e6080e7          	jalr	998(ra) # 80000cbe <memset>
      dip->type = type;
    800038e0:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038e4:	854a                	mv	a0,s2
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	fbe080e7          	jalr	-66(ra) # 800048a4 <log_write>
      brelse(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	a20080e7          	jalr	-1504(ra) # 80003310 <brelse>
      return iget(dev, inum);
    800038f8:	85da                	mv	a1,s6
    800038fa:	8556                	mv	a0,s5
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	db4080e7          	jalr	-588(ra) # 800036b0 <iget>
}
    80003904:	60a6                	ld	ra,72(sp)
    80003906:	6406                	ld	s0,64(sp)
    80003908:	74e2                	ld	s1,56(sp)
    8000390a:	7942                	ld	s2,48(sp)
    8000390c:	79a2                	ld	s3,40(sp)
    8000390e:	7a02                	ld	s4,32(sp)
    80003910:	6ae2                	ld	s5,24(sp)
    80003912:	6b42                	ld	s6,16(sp)
    80003914:	6ba2                	ld	s7,8(sp)
    80003916:	6161                	addi	sp,sp,80
    80003918:	8082                	ret

000000008000391a <iupdate>:
{
    8000391a:	1101                	addi	sp,sp,-32
    8000391c:	ec06                	sd	ra,24(sp)
    8000391e:	e822                	sd	s0,16(sp)
    80003920:	e426                	sd	s1,8(sp)
    80003922:	e04a                	sd	s2,0(sp)
    80003924:	1000                	addi	s0,sp,32
    80003926:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003928:	415c                	lw	a5,4(a0)
    8000392a:	0047d79b          	srliw	a5,a5,0x4
    8000392e:	00022597          	auipc	a1,0x22
    80003932:	0925a583          	lw	a1,146(a1) # 800259c0 <sb+0x18>
    80003936:	9dbd                	addw	a1,a1,a5
    80003938:	4108                	lw	a0,0(a0)
    8000393a:	00000097          	auipc	ra,0x0
    8000393e:	8a6080e7          	jalr	-1882(ra) # 800031e0 <bread>
    80003942:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003944:	05850793          	addi	a5,a0,88
    80003948:	40c8                	lw	a0,4(s1)
    8000394a:	893d                	andi	a0,a0,15
    8000394c:	051a                	slli	a0,a0,0x6
    8000394e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003950:	04449703          	lh	a4,68(s1)
    80003954:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003958:	04649703          	lh	a4,70(s1)
    8000395c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003960:	04849703          	lh	a4,72(s1)
    80003964:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003968:	04a49703          	lh	a4,74(s1)
    8000396c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003970:	44f8                	lw	a4,76(s1)
    80003972:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003974:	03400613          	li	a2,52
    80003978:	05048593          	addi	a1,s1,80
    8000397c:	0531                	addi	a0,a0,12
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	39c080e7          	jalr	924(ra) # 80000d1a <memmove>
  log_write(bp);
    80003986:	854a                	mv	a0,s2
    80003988:	00001097          	auipc	ra,0x1
    8000398c:	f1c080e7          	jalr	-228(ra) # 800048a4 <log_write>
  brelse(bp);
    80003990:	854a                	mv	a0,s2
    80003992:	00000097          	auipc	ra,0x0
    80003996:	97e080e7          	jalr	-1666(ra) # 80003310 <brelse>
}
    8000399a:	60e2                	ld	ra,24(sp)
    8000399c:	6442                	ld	s0,16(sp)
    8000399e:	64a2                	ld	s1,8(sp)
    800039a0:	6902                	ld	s2,0(sp)
    800039a2:	6105                	addi	sp,sp,32
    800039a4:	8082                	ret

00000000800039a6 <idup>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	1000                	addi	s0,sp,32
    800039b0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039b2:	00022517          	auipc	a0,0x22
    800039b6:	01650513          	addi	a0,a0,22 # 800259c8 <itable>
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	208080e7          	jalr	520(ra) # 80000bc2 <acquire>
  ip->ref++;
    800039c2:	449c                	lw	a5,8(s1)
    800039c4:	2785                	addiw	a5,a5,1
    800039c6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039c8:	00022517          	auipc	a0,0x22
    800039cc:	00050513          	mv	a0,a0
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	2a6080e7          	jalr	678(ra) # 80000c76 <release>
}
    800039d8:	8526                	mv	a0,s1
    800039da:	60e2                	ld	ra,24(sp)
    800039dc:	6442                	ld	s0,16(sp)
    800039de:	64a2                	ld	s1,8(sp)
    800039e0:	6105                	addi	sp,sp,32
    800039e2:	8082                	ret

00000000800039e4 <ilock>:
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	e04a                	sd	s2,0(sp)
    800039ee:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039f0:	c115                	beqz	a0,80003a14 <ilock+0x30>
    800039f2:	84aa                	mv	s1,a0
    800039f4:	451c                	lw	a5,8(a0)
    800039f6:	00f05f63          	blez	a5,80003a14 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039fa:	0541                	addi	a0,a0,16
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	fc8080e7          	jalr	-56(ra) # 800049c4 <acquiresleep>
  if(ip->valid == 0){
    80003a04:	40bc                	lw	a5,64(s1)
    80003a06:	cf99                	beqz	a5,80003a24 <ilock+0x40>
}
    80003a08:	60e2                	ld	ra,24(sp)
    80003a0a:	6442                	ld	s0,16(sp)
    80003a0c:	64a2                	ld	s1,8(sp)
    80003a0e:	6902                	ld	s2,0(sp)
    80003a10:	6105                	addi	sp,sp,32
    80003a12:	8082                	ret
    panic("ilock");
    80003a14:	00005517          	auipc	a0,0x5
    80003a18:	c7450513          	addi	a0,a0,-908 # 80008688 <syscalls+0x180>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	b0e080e7          	jalr	-1266(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a24:	40dc                	lw	a5,4(s1)
    80003a26:	0047d79b          	srliw	a5,a5,0x4
    80003a2a:	00022597          	auipc	a1,0x22
    80003a2e:	f965a583          	lw	a1,-106(a1) # 800259c0 <sb+0x18>
    80003a32:	9dbd                	addw	a1,a1,a5
    80003a34:	4088                	lw	a0,0(s1)
    80003a36:	fffff097          	auipc	ra,0xfffff
    80003a3a:	7aa080e7          	jalr	1962(ra) # 800031e0 <bread>
    80003a3e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a40:	05850593          	addi	a1,a0,88
    80003a44:	40dc                	lw	a5,4(s1)
    80003a46:	8bbd                	andi	a5,a5,15
    80003a48:	079a                	slli	a5,a5,0x6
    80003a4a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a4c:	00059783          	lh	a5,0(a1)
    80003a50:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a54:	00259783          	lh	a5,2(a1)
    80003a58:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a5c:	00459783          	lh	a5,4(a1)
    80003a60:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a64:	00659783          	lh	a5,6(a1)
    80003a68:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a6c:	459c                	lw	a5,8(a1)
    80003a6e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a70:	03400613          	li	a2,52
    80003a74:	05b1                	addi	a1,a1,12
    80003a76:	05048513          	addi	a0,s1,80
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	2a0080e7          	jalr	672(ra) # 80000d1a <memmove>
    brelse(bp);
    80003a82:	854a                	mv	a0,s2
    80003a84:	00000097          	auipc	ra,0x0
    80003a88:	88c080e7          	jalr	-1908(ra) # 80003310 <brelse>
    ip->valid = 1;
    80003a8c:	4785                	li	a5,1
    80003a8e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a90:	04449783          	lh	a5,68(s1)
    80003a94:	fbb5                	bnez	a5,80003a08 <ilock+0x24>
      panic("ilock: no type");
    80003a96:	00005517          	auipc	a0,0x5
    80003a9a:	bfa50513          	addi	a0,a0,-1030 # 80008690 <syscalls+0x188>
    80003a9e:	ffffd097          	auipc	ra,0xffffd
    80003aa2:	a8c080e7          	jalr	-1396(ra) # 8000052a <panic>

0000000080003aa6 <iunlock>:
{
    80003aa6:	1101                	addi	sp,sp,-32
    80003aa8:	ec06                	sd	ra,24(sp)
    80003aaa:	e822                	sd	s0,16(sp)
    80003aac:	e426                	sd	s1,8(sp)
    80003aae:	e04a                	sd	s2,0(sp)
    80003ab0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ab2:	c905                	beqz	a0,80003ae2 <iunlock+0x3c>
    80003ab4:	84aa                	mv	s1,a0
    80003ab6:	01050913          	addi	s2,a0,16
    80003aba:	854a                	mv	a0,s2
    80003abc:	00001097          	auipc	ra,0x1
    80003ac0:	fa2080e7          	jalr	-94(ra) # 80004a5e <holdingsleep>
    80003ac4:	cd19                	beqz	a0,80003ae2 <iunlock+0x3c>
    80003ac6:	449c                	lw	a5,8(s1)
    80003ac8:	00f05d63          	blez	a5,80003ae2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003acc:	854a                	mv	a0,s2
    80003ace:	00001097          	auipc	ra,0x1
    80003ad2:	f4c080e7          	jalr	-180(ra) # 80004a1a <releasesleep>
}
    80003ad6:	60e2                	ld	ra,24(sp)
    80003ad8:	6442                	ld	s0,16(sp)
    80003ada:	64a2                	ld	s1,8(sp)
    80003adc:	6902                	ld	s2,0(sp)
    80003ade:	6105                	addi	sp,sp,32
    80003ae0:	8082                	ret
    panic("iunlock");
    80003ae2:	00005517          	auipc	a0,0x5
    80003ae6:	bbe50513          	addi	a0,a0,-1090 # 800086a0 <syscalls+0x198>
    80003aea:	ffffd097          	auipc	ra,0xffffd
    80003aee:	a40080e7          	jalr	-1472(ra) # 8000052a <panic>

0000000080003af2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003af2:	7179                	addi	sp,sp,-48
    80003af4:	f406                	sd	ra,40(sp)
    80003af6:	f022                	sd	s0,32(sp)
    80003af8:	ec26                	sd	s1,24(sp)
    80003afa:	e84a                	sd	s2,16(sp)
    80003afc:	e44e                	sd	s3,8(sp)
    80003afe:	e052                	sd	s4,0(sp)
    80003b00:	1800                	addi	s0,sp,48
    80003b02:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b04:	05050493          	addi	s1,a0,80
    80003b08:	08050913          	addi	s2,a0,128
    80003b0c:	a021                	j	80003b14 <itrunc+0x22>
    80003b0e:	0491                	addi	s1,s1,4
    80003b10:	01248d63          	beq	s1,s2,80003b2a <itrunc+0x38>
    if(ip->addrs[i]){
    80003b14:	408c                	lw	a1,0(s1)
    80003b16:	dde5                	beqz	a1,80003b0e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b18:	0009a503          	lw	a0,0(s3)
    80003b1c:	00000097          	auipc	ra,0x0
    80003b20:	90a080e7          	jalr	-1782(ra) # 80003426 <bfree>
      ip->addrs[i] = 0;
    80003b24:	0004a023          	sw	zero,0(s1)
    80003b28:	b7dd                	j	80003b0e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b2a:	0809a583          	lw	a1,128(s3)
    80003b2e:	e185                	bnez	a1,80003b4e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b30:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b34:	854e                	mv	a0,s3
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	de4080e7          	jalr	-540(ra) # 8000391a <iupdate>
}
    80003b3e:	70a2                	ld	ra,40(sp)
    80003b40:	7402                	ld	s0,32(sp)
    80003b42:	64e2                	ld	s1,24(sp)
    80003b44:	6942                	ld	s2,16(sp)
    80003b46:	69a2                	ld	s3,8(sp)
    80003b48:	6a02                	ld	s4,0(sp)
    80003b4a:	6145                	addi	sp,sp,48
    80003b4c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b4e:	0009a503          	lw	a0,0(s3)
    80003b52:	fffff097          	auipc	ra,0xfffff
    80003b56:	68e080e7          	jalr	1678(ra) # 800031e0 <bread>
    80003b5a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b5c:	05850493          	addi	s1,a0,88
    80003b60:	45850913          	addi	s2,a0,1112
    80003b64:	a021                	j	80003b6c <itrunc+0x7a>
    80003b66:	0491                	addi	s1,s1,4
    80003b68:	01248b63          	beq	s1,s2,80003b7e <itrunc+0x8c>
      if(a[j])
    80003b6c:	408c                	lw	a1,0(s1)
    80003b6e:	dde5                	beqz	a1,80003b66 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b70:	0009a503          	lw	a0,0(s3)
    80003b74:	00000097          	auipc	ra,0x0
    80003b78:	8b2080e7          	jalr	-1870(ra) # 80003426 <bfree>
    80003b7c:	b7ed                	j	80003b66 <itrunc+0x74>
    brelse(bp);
    80003b7e:	8552                	mv	a0,s4
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	790080e7          	jalr	1936(ra) # 80003310 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b88:	0809a583          	lw	a1,128(s3)
    80003b8c:	0009a503          	lw	a0,0(s3)
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	896080e7          	jalr	-1898(ra) # 80003426 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b98:	0809a023          	sw	zero,128(s3)
    80003b9c:	bf51                	j	80003b30 <itrunc+0x3e>

0000000080003b9e <iput>:
{
    80003b9e:	1101                	addi	sp,sp,-32
    80003ba0:	ec06                	sd	ra,24(sp)
    80003ba2:	e822                	sd	s0,16(sp)
    80003ba4:	e426                	sd	s1,8(sp)
    80003ba6:	e04a                	sd	s2,0(sp)
    80003ba8:	1000                	addi	s0,sp,32
    80003baa:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bac:	00022517          	auipc	a0,0x22
    80003bb0:	e1c50513          	addi	a0,a0,-484 # 800259c8 <itable>
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	00e080e7          	jalr	14(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bbc:	4498                	lw	a4,8(s1)
    80003bbe:	4785                	li	a5,1
    80003bc0:	02f70363          	beq	a4,a5,80003be6 <iput+0x48>
  ip->ref--;
    80003bc4:	449c                	lw	a5,8(s1)
    80003bc6:	37fd                	addiw	a5,a5,-1
    80003bc8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bca:	00022517          	auipc	a0,0x22
    80003bce:	dfe50513          	addi	a0,a0,-514 # 800259c8 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	0a4080e7          	jalr	164(ra) # 80000c76 <release>
}
    80003bda:	60e2                	ld	ra,24(sp)
    80003bdc:	6442                	ld	s0,16(sp)
    80003bde:	64a2                	ld	s1,8(sp)
    80003be0:	6902                	ld	s2,0(sp)
    80003be2:	6105                	addi	sp,sp,32
    80003be4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003be6:	40bc                	lw	a5,64(s1)
    80003be8:	dff1                	beqz	a5,80003bc4 <iput+0x26>
    80003bea:	04a49783          	lh	a5,74(s1)
    80003bee:	fbf9                	bnez	a5,80003bc4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bf0:	01048913          	addi	s2,s1,16
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	dce080e7          	jalr	-562(ra) # 800049c4 <acquiresleep>
    release(&itable.lock);
    80003bfe:	00022517          	auipc	a0,0x22
    80003c02:	dca50513          	addi	a0,a0,-566 # 800259c8 <itable>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	070080e7          	jalr	112(ra) # 80000c76 <release>
    itrunc(ip);
    80003c0e:	8526                	mv	a0,s1
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	ee2080e7          	jalr	-286(ra) # 80003af2 <itrunc>
    ip->type = 0;
    80003c18:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	cfc080e7          	jalr	-772(ra) # 8000391a <iupdate>
    ip->valid = 0;
    80003c26:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00001097          	auipc	ra,0x1
    80003c30:	dee080e7          	jalr	-530(ra) # 80004a1a <releasesleep>
    acquire(&itable.lock);
    80003c34:	00022517          	auipc	a0,0x22
    80003c38:	d9450513          	addi	a0,a0,-620 # 800259c8 <itable>
    80003c3c:	ffffd097          	auipc	ra,0xffffd
    80003c40:	f86080e7          	jalr	-122(ra) # 80000bc2 <acquire>
    80003c44:	b741                	j	80003bc4 <iput+0x26>

0000000080003c46 <iunlockput>:
{
    80003c46:	1101                	addi	sp,sp,-32
    80003c48:	ec06                	sd	ra,24(sp)
    80003c4a:	e822                	sd	s0,16(sp)
    80003c4c:	e426                	sd	s1,8(sp)
    80003c4e:	1000                	addi	s0,sp,32
    80003c50:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	e54080e7          	jalr	-428(ra) # 80003aa6 <iunlock>
  iput(ip);
    80003c5a:	8526                	mv	a0,s1
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	f42080e7          	jalr	-190(ra) # 80003b9e <iput>
}
    80003c64:	60e2                	ld	ra,24(sp)
    80003c66:	6442                	ld	s0,16(sp)
    80003c68:	64a2                	ld	s1,8(sp)
    80003c6a:	6105                	addi	sp,sp,32
    80003c6c:	8082                	ret

0000000080003c6e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c6e:	1141                	addi	sp,sp,-16
    80003c70:	e422                	sd	s0,8(sp)
    80003c72:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c74:	411c                	lw	a5,0(a0)
    80003c76:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c78:	415c                	lw	a5,4(a0)
    80003c7a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c7c:	04451783          	lh	a5,68(a0)
    80003c80:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c84:	04a51783          	lh	a5,74(a0)
    80003c88:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c8c:	04c56783          	lwu	a5,76(a0)
    80003c90:	e99c                	sd	a5,16(a1)
}
    80003c92:	6422                	ld	s0,8(sp)
    80003c94:	0141                	addi	sp,sp,16
    80003c96:	8082                	ret

0000000080003c98 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c98:	457c                	lw	a5,76(a0)
    80003c9a:	0ed7e963          	bltu	a5,a3,80003d8c <readi+0xf4>
{
    80003c9e:	7159                	addi	sp,sp,-112
    80003ca0:	f486                	sd	ra,104(sp)
    80003ca2:	f0a2                	sd	s0,96(sp)
    80003ca4:	eca6                	sd	s1,88(sp)
    80003ca6:	e8ca                	sd	s2,80(sp)
    80003ca8:	e4ce                	sd	s3,72(sp)
    80003caa:	e0d2                	sd	s4,64(sp)
    80003cac:	fc56                	sd	s5,56(sp)
    80003cae:	f85a                	sd	s6,48(sp)
    80003cb0:	f45e                	sd	s7,40(sp)
    80003cb2:	f062                	sd	s8,32(sp)
    80003cb4:	ec66                	sd	s9,24(sp)
    80003cb6:	e86a                	sd	s10,16(sp)
    80003cb8:	e46e                	sd	s11,8(sp)
    80003cba:	1880                	addi	s0,sp,112
    80003cbc:	8baa                	mv	s7,a0
    80003cbe:	8c2e                	mv	s8,a1
    80003cc0:	8ab2                	mv	s5,a2
    80003cc2:	84b6                	mv	s1,a3
    80003cc4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cc6:	9f35                	addw	a4,a4,a3
    return 0;
    80003cc8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cca:	0ad76063          	bltu	a4,a3,80003d6a <readi+0xd2>
  if(off + n > ip->size)
    80003cce:	00e7f463          	bgeu	a5,a4,80003cd6 <readi+0x3e>
    n = ip->size - off;
    80003cd2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd6:	0a0b0963          	beqz	s6,80003d88 <readi+0xf0>
    80003cda:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cdc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ce0:	5cfd                	li	s9,-1
    80003ce2:	a82d                	j	80003d1c <readi+0x84>
    80003ce4:	020a1d93          	slli	s11,s4,0x20
    80003ce8:	020ddd93          	srli	s11,s11,0x20
    80003cec:	05890793          	addi	a5,s2,88
    80003cf0:	86ee                	mv	a3,s11
    80003cf2:	963e                	add	a2,a2,a5
    80003cf4:	85d6                	mv	a1,s5
    80003cf6:	8562                	mv	a0,s8
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	b2c080e7          	jalr	-1236(ra) # 80002824 <either_copyout>
    80003d00:	05950d63          	beq	a0,s9,80003d5a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d04:	854a                	mv	a0,s2
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	60a080e7          	jalr	1546(ra) # 80003310 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0e:	013a09bb          	addw	s3,s4,s3
    80003d12:	009a04bb          	addw	s1,s4,s1
    80003d16:	9aee                	add	s5,s5,s11
    80003d18:	0569f763          	bgeu	s3,s6,80003d66 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d1c:	000ba903          	lw	s2,0(s7)
    80003d20:	00a4d59b          	srliw	a1,s1,0xa
    80003d24:	855e                	mv	a0,s7
    80003d26:	00000097          	auipc	ra,0x0
    80003d2a:	8ae080e7          	jalr	-1874(ra) # 800035d4 <bmap>
    80003d2e:	0005059b          	sext.w	a1,a0
    80003d32:	854a                	mv	a0,s2
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	4ac080e7          	jalr	1196(ra) # 800031e0 <bread>
    80003d3c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3e:	3ff4f613          	andi	a2,s1,1023
    80003d42:	40cd07bb          	subw	a5,s10,a2
    80003d46:	413b073b          	subw	a4,s6,s3
    80003d4a:	8a3e                	mv	s4,a5
    80003d4c:	2781                	sext.w	a5,a5
    80003d4e:	0007069b          	sext.w	a3,a4
    80003d52:	f8f6f9e3          	bgeu	a3,a5,80003ce4 <readi+0x4c>
    80003d56:	8a3a                	mv	s4,a4
    80003d58:	b771                	j	80003ce4 <readi+0x4c>
      brelse(bp);
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	5b4080e7          	jalr	1460(ra) # 80003310 <brelse>
      tot = -1;
    80003d64:	59fd                	li	s3,-1
  }
  return tot;
    80003d66:	0009851b          	sext.w	a0,s3
}
    80003d6a:	70a6                	ld	ra,104(sp)
    80003d6c:	7406                	ld	s0,96(sp)
    80003d6e:	64e6                	ld	s1,88(sp)
    80003d70:	6946                	ld	s2,80(sp)
    80003d72:	69a6                	ld	s3,72(sp)
    80003d74:	6a06                	ld	s4,64(sp)
    80003d76:	7ae2                	ld	s5,56(sp)
    80003d78:	7b42                	ld	s6,48(sp)
    80003d7a:	7ba2                	ld	s7,40(sp)
    80003d7c:	7c02                	ld	s8,32(sp)
    80003d7e:	6ce2                	ld	s9,24(sp)
    80003d80:	6d42                	ld	s10,16(sp)
    80003d82:	6da2                	ld	s11,8(sp)
    80003d84:	6165                	addi	sp,sp,112
    80003d86:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d88:	89da                	mv	s3,s6
    80003d8a:	bff1                	j	80003d66 <readi+0xce>
    return 0;
    80003d8c:	4501                	li	a0,0
}
    80003d8e:	8082                	ret

0000000080003d90 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d90:	457c                	lw	a5,76(a0)
    80003d92:	10d7e863          	bltu	a5,a3,80003ea2 <writei+0x112>
{
    80003d96:	7159                	addi	sp,sp,-112
    80003d98:	f486                	sd	ra,104(sp)
    80003d9a:	f0a2                	sd	s0,96(sp)
    80003d9c:	eca6                	sd	s1,88(sp)
    80003d9e:	e8ca                	sd	s2,80(sp)
    80003da0:	e4ce                	sd	s3,72(sp)
    80003da2:	e0d2                	sd	s4,64(sp)
    80003da4:	fc56                	sd	s5,56(sp)
    80003da6:	f85a                	sd	s6,48(sp)
    80003da8:	f45e                	sd	s7,40(sp)
    80003daa:	f062                	sd	s8,32(sp)
    80003dac:	ec66                	sd	s9,24(sp)
    80003dae:	e86a                	sd	s10,16(sp)
    80003db0:	e46e                	sd	s11,8(sp)
    80003db2:	1880                	addi	s0,sp,112
    80003db4:	8b2a                	mv	s6,a0
    80003db6:	8c2e                	mv	s8,a1
    80003db8:	8ab2                	mv	s5,a2
    80003dba:	8936                	mv	s2,a3
    80003dbc:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003dbe:	00e687bb          	addw	a5,a3,a4
    80003dc2:	0ed7e263          	bltu	a5,a3,80003ea6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dc6:	00043737          	lui	a4,0x43
    80003dca:	0ef76063          	bltu	a4,a5,80003eaa <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dce:	0c0b8863          	beqz	s7,80003e9e <writei+0x10e>
    80003dd2:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd4:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dd8:	5cfd                	li	s9,-1
    80003dda:	a091                	j	80003e1e <writei+0x8e>
    80003ddc:	02099d93          	slli	s11,s3,0x20
    80003de0:	020ddd93          	srli	s11,s11,0x20
    80003de4:	05848793          	addi	a5,s1,88
    80003de8:	86ee                	mv	a3,s11
    80003dea:	8656                	mv	a2,s5
    80003dec:	85e2                	mv	a1,s8
    80003dee:	953e                	add	a0,a0,a5
    80003df0:	fffff097          	auipc	ra,0xfffff
    80003df4:	a8a080e7          	jalr	-1398(ra) # 8000287a <either_copyin>
    80003df8:	07950263          	beq	a0,s9,80003e5c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dfc:	8526                	mv	a0,s1
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	aa6080e7          	jalr	-1370(ra) # 800048a4 <log_write>
    brelse(bp);
    80003e06:	8526                	mv	a0,s1
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	508080e7          	jalr	1288(ra) # 80003310 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e10:	01498a3b          	addw	s4,s3,s4
    80003e14:	0129893b          	addw	s2,s3,s2
    80003e18:	9aee                	add	s5,s5,s11
    80003e1a:	057a7663          	bgeu	s4,s7,80003e66 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e1e:	000b2483          	lw	s1,0(s6)
    80003e22:	00a9559b          	srliw	a1,s2,0xa
    80003e26:	855a                	mv	a0,s6
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	7ac080e7          	jalr	1964(ra) # 800035d4 <bmap>
    80003e30:	0005059b          	sext.w	a1,a0
    80003e34:	8526                	mv	a0,s1
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	3aa080e7          	jalr	938(ra) # 800031e0 <bread>
    80003e3e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e40:	3ff97513          	andi	a0,s2,1023
    80003e44:	40ad07bb          	subw	a5,s10,a0
    80003e48:	414b873b          	subw	a4,s7,s4
    80003e4c:	89be                	mv	s3,a5
    80003e4e:	2781                	sext.w	a5,a5
    80003e50:	0007069b          	sext.w	a3,a4
    80003e54:	f8f6f4e3          	bgeu	a3,a5,80003ddc <writei+0x4c>
    80003e58:	89ba                	mv	s3,a4
    80003e5a:	b749                	j	80003ddc <writei+0x4c>
      brelse(bp);
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	4b2080e7          	jalr	1202(ra) # 80003310 <brelse>
  }

  if(off > ip->size)
    80003e66:	04cb2783          	lw	a5,76(s6)
    80003e6a:	0127f463          	bgeu	a5,s2,80003e72 <writei+0xe2>
    ip->size = off;
    80003e6e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e72:	855a                	mv	a0,s6
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	aa6080e7          	jalr	-1370(ra) # 8000391a <iupdate>

  return tot;
    80003e7c:	000a051b          	sext.w	a0,s4
}
    80003e80:	70a6                	ld	ra,104(sp)
    80003e82:	7406                	ld	s0,96(sp)
    80003e84:	64e6                	ld	s1,88(sp)
    80003e86:	6946                	ld	s2,80(sp)
    80003e88:	69a6                	ld	s3,72(sp)
    80003e8a:	6a06                	ld	s4,64(sp)
    80003e8c:	7ae2                	ld	s5,56(sp)
    80003e8e:	7b42                	ld	s6,48(sp)
    80003e90:	7ba2                	ld	s7,40(sp)
    80003e92:	7c02                	ld	s8,32(sp)
    80003e94:	6ce2                	ld	s9,24(sp)
    80003e96:	6d42                	ld	s10,16(sp)
    80003e98:	6da2                	ld	s11,8(sp)
    80003e9a:	6165                	addi	sp,sp,112
    80003e9c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e9e:	8a5e                	mv	s4,s7
    80003ea0:	bfc9                	j	80003e72 <writei+0xe2>
    return -1;
    80003ea2:	557d                	li	a0,-1
}
    80003ea4:	8082                	ret
    return -1;
    80003ea6:	557d                	li	a0,-1
    80003ea8:	bfe1                	j	80003e80 <writei+0xf0>
    return -1;
    80003eaa:	557d                	li	a0,-1
    80003eac:	bfd1                	j	80003e80 <writei+0xf0>

0000000080003eae <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eae:	1141                	addi	sp,sp,-16
    80003eb0:	e406                	sd	ra,8(sp)
    80003eb2:	e022                	sd	s0,0(sp)
    80003eb4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003eb6:	4639                	li	a2,14
    80003eb8:	ffffd097          	auipc	ra,0xffffd
    80003ebc:	ede080e7          	jalr	-290(ra) # 80000d96 <strncmp>
}
    80003ec0:	60a2                	ld	ra,8(sp)
    80003ec2:	6402                	ld	s0,0(sp)
    80003ec4:	0141                	addi	sp,sp,16
    80003ec6:	8082                	ret

0000000080003ec8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ec8:	7139                	addi	sp,sp,-64
    80003eca:	fc06                	sd	ra,56(sp)
    80003ecc:	f822                	sd	s0,48(sp)
    80003ece:	f426                	sd	s1,40(sp)
    80003ed0:	f04a                	sd	s2,32(sp)
    80003ed2:	ec4e                	sd	s3,24(sp)
    80003ed4:	e852                	sd	s4,16(sp)
    80003ed6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ed8:	04451703          	lh	a4,68(a0)
    80003edc:	4785                	li	a5,1
    80003ede:	00f71a63          	bne	a4,a5,80003ef2 <dirlookup+0x2a>
    80003ee2:	892a                	mv	s2,a0
    80003ee4:	89ae                	mv	s3,a1
    80003ee6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee8:	457c                	lw	a5,76(a0)
    80003eea:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eec:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eee:	e79d                	bnez	a5,80003f1c <dirlookup+0x54>
    80003ef0:	a8a5                	j	80003f68 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ef2:	00004517          	auipc	a0,0x4
    80003ef6:	7b650513          	addi	a0,a0,1974 # 800086a8 <syscalls+0x1a0>
    80003efa:	ffffc097          	auipc	ra,0xffffc
    80003efe:	630080e7          	jalr	1584(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003f02:	00004517          	auipc	a0,0x4
    80003f06:	7be50513          	addi	a0,a0,1982 # 800086c0 <syscalls+0x1b8>
    80003f0a:	ffffc097          	auipc	ra,0xffffc
    80003f0e:	620080e7          	jalr	1568(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f12:	24c1                	addiw	s1,s1,16
    80003f14:	04c92783          	lw	a5,76(s2)
    80003f18:	04f4f763          	bgeu	s1,a5,80003f66 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1c:	4741                	li	a4,16
    80003f1e:	86a6                	mv	a3,s1
    80003f20:	fc040613          	addi	a2,s0,-64
    80003f24:	4581                	li	a1,0
    80003f26:	854a                	mv	a0,s2
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	d70080e7          	jalr	-656(ra) # 80003c98 <readi>
    80003f30:	47c1                	li	a5,16
    80003f32:	fcf518e3          	bne	a0,a5,80003f02 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f36:	fc045783          	lhu	a5,-64(s0)
    80003f3a:	dfe1                	beqz	a5,80003f12 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f3c:	fc240593          	addi	a1,s0,-62
    80003f40:	854e                	mv	a0,s3
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	f6c080e7          	jalr	-148(ra) # 80003eae <namecmp>
    80003f4a:	f561                	bnez	a0,80003f12 <dirlookup+0x4a>
      if(poff)
    80003f4c:	000a0463          	beqz	s4,80003f54 <dirlookup+0x8c>
        *poff = off;
    80003f50:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f54:	fc045583          	lhu	a1,-64(s0)
    80003f58:	00092503          	lw	a0,0(s2)
    80003f5c:	fffff097          	auipc	ra,0xfffff
    80003f60:	754080e7          	jalr	1876(ra) # 800036b0 <iget>
    80003f64:	a011                	j	80003f68 <dirlookup+0xa0>
  return 0;
    80003f66:	4501                	li	a0,0
}
    80003f68:	70e2                	ld	ra,56(sp)
    80003f6a:	7442                	ld	s0,48(sp)
    80003f6c:	74a2                	ld	s1,40(sp)
    80003f6e:	7902                	ld	s2,32(sp)
    80003f70:	69e2                	ld	s3,24(sp)
    80003f72:	6a42                	ld	s4,16(sp)
    80003f74:	6121                	addi	sp,sp,64
    80003f76:	8082                	ret

0000000080003f78 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f78:	711d                	addi	sp,sp,-96
    80003f7a:	ec86                	sd	ra,88(sp)
    80003f7c:	e8a2                	sd	s0,80(sp)
    80003f7e:	e4a6                	sd	s1,72(sp)
    80003f80:	e0ca                	sd	s2,64(sp)
    80003f82:	fc4e                	sd	s3,56(sp)
    80003f84:	f852                	sd	s4,48(sp)
    80003f86:	f456                	sd	s5,40(sp)
    80003f88:	f05a                	sd	s6,32(sp)
    80003f8a:	ec5e                	sd	s7,24(sp)
    80003f8c:	e862                	sd	s8,16(sp)
    80003f8e:	e466                	sd	s9,8(sp)
    80003f90:	1080                	addi	s0,sp,96
    80003f92:	84aa                	mv	s1,a0
    80003f94:	8aae                	mv	s5,a1
    80003f96:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f98:	00054703          	lbu	a4,0(a0)
    80003f9c:	02f00793          	li	a5,47
    80003fa0:	02f70363          	beq	a4,a5,80003fc6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fa4:	ffffe097          	auipc	ra,0xffffe
    80003fa8:	c76080e7          	jalr	-906(ra) # 80001c1a <myproc>
    80003fac:	15053503          	ld	a0,336(a0)
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	9f6080e7          	jalr	-1546(ra) # 800039a6 <idup>
    80003fb8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fba:	02f00913          	li	s2,47
  len = path - s;
    80003fbe:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fc0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fc2:	4b85                	li	s7,1
    80003fc4:	a865                	j	8000407c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fc6:	4585                	li	a1,1
    80003fc8:	4505                	li	a0,1
    80003fca:	fffff097          	auipc	ra,0xfffff
    80003fce:	6e6080e7          	jalr	1766(ra) # 800036b0 <iget>
    80003fd2:	89aa                	mv	s3,a0
    80003fd4:	b7dd                	j	80003fba <namex+0x42>
      iunlockput(ip);
    80003fd6:	854e                	mv	a0,s3
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	c6e080e7          	jalr	-914(ra) # 80003c46 <iunlockput>
      return 0;
    80003fe0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fe2:	854e                	mv	a0,s3
    80003fe4:	60e6                	ld	ra,88(sp)
    80003fe6:	6446                	ld	s0,80(sp)
    80003fe8:	64a6                	ld	s1,72(sp)
    80003fea:	6906                	ld	s2,64(sp)
    80003fec:	79e2                	ld	s3,56(sp)
    80003fee:	7a42                	ld	s4,48(sp)
    80003ff0:	7aa2                	ld	s5,40(sp)
    80003ff2:	7b02                	ld	s6,32(sp)
    80003ff4:	6be2                	ld	s7,24(sp)
    80003ff6:	6c42                	ld	s8,16(sp)
    80003ff8:	6ca2                	ld	s9,8(sp)
    80003ffa:	6125                	addi	sp,sp,96
    80003ffc:	8082                	ret
      iunlock(ip);
    80003ffe:	854e                	mv	a0,s3
    80004000:	00000097          	auipc	ra,0x0
    80004004:	aa6080e7          	jalr	-1370(ra) # 80003aa6 <iunlock>
      return ip;
    80004008:	bfe9                	j	80003fe2 <namex+0x6a>
      iunlockput(ip);
    8000400a:	854e                	mv	a0,s3
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	c3a080e7          	jalr	-966(ra) # 80003c46 <iunlockput>
      return 0;
    80004014:	89e6                	mv	s3,s9
    80004016:	b7f1                	j	80003fe2 <namex+0x6a>
  len = path - s;
    80004018:	40b48633          	sub	a2,s1,a1
    8000401c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004020:	099c5463          	bge	s8,s9,800040a8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004024:	4639                	li	a2,14
    80004026:	8552                	mv	a0,s4
    80004028:	ffffd097          	auipc	ra,0xffffd
    8000402c:	cf2080e7          	jalr	-782(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004030:	0004c783          	lbu	a5,0(s1)
    80004034:	01279763          	bne	a5,s2,80004042 <namex+0xca>
    path++;
    80004038:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000403a:	0004c783          	lbu	a5,0(s1)
    8000403e:	ff278de3          	beq	a5,s2,80004038 <namex+0xc0>
    ilock(ip);
    80004042:	854e                	mv	a0,s3
    80004044:	00000097          	auipc	ra,0x0
    80004048:	9a0080e7          	jalr	-1632(ra) # 800039e4 <ilock>
    if(ip->type != T_DIR){
    8000404c:	04499783          	lh	a5,68(s3)
    80004050:	f97793e3          	bne	a5,s7,80003fd6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004054:	000a8563          	beqz	s5,8000405e <namex+0xe6>
    80004058:	0004c783          	lbu	a5,0(s1)
    8000405c:	d3cd                	beqz	a5,80003ffe <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000405e:	865a                	mv	a2,s6
    80004060:	85d2                	mv	a1,s4
    80004062:	854e                	mv	a0,s3
    80004064:	00000097          	auipc	ra,0x0
    80004068:	e64080e7          	jalr	-412(ra) # 80003ec8 <dirlookup>
    8000406c:	8caa                	mv	s9,a0
    8000406e:	dd51                	beqz	a0,8000400a <namex+0x92>
    iunlockput(ip);
    80004070:	854e                	mv	a0,s3
    80004072:	00000097          	auipc	ra,0x0
    80004076:	bd4080e7          	jalr	-1068(ra) # 80003c46 <iunlockput>
    ip = next;
    8000407a:	89e6                	mv	s3,s9
  while(*path == '/')
    8000407c:	0004c783          	lbu	a5,0(s1)
    80004080:	05279763          	bne	a5,s2,800040ce <namex+0x156>
    path++;
    80004084:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004086:	0004c783          	lbu	a5,0(s1)
    8000408a:	ff278de3          	beq	a5,s2,80004084 <namex+0x10c>
  if(*path == 0)
    8000408e:	c79d                	beqz	a5,800040bc <namex+0x144>
    path++;
    80004090:	85a6                	mv	a1,s1
  len = path - s;
    80004092:	8cda                	mv	s9,s6
    80004094:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004096:	01278963          	beq	a5,s2,800040a8 <namex+0x130>
    8000409a:	dfbd                	beqz	a5,80004018 <namex+0xa0>
    path++;
    8000409c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000409e:	0004c783          	lbu	a5,0(s1)
    800040a2:	ff279ce3          	bne	a5,s2,8000409a <namex+0x122>
    800040a6:	bf8d                	j	80004018 <namex+0xa0>
    memmove(name, s, len);
    800040a8:	2601                	sext.w	a2,a2
    800040aa:	8552                	mv	a0,s4
    800040ac:	ffffd097          	auipc	ra,0xffffd
    800040b0:	c6e080e7          	jalr	-914(ra) # 80000d1a <memmove>
    name[len] = 0;
    800040b4:	9cd2                	add	s9,s9,s4
    800040b6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040ba:	bf9d                	j	80004030 <namex+0xb8>
  if(nameiparent){
    800040bc:	f20a83e3          	beqz	s5,80003fe2 <namex+0x6a>
    iput(ip);
    800040c0:	854e                	mv	a0,s3
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	adc080e7          	jalr	-1316(ra) # 80003b9e <iput>
    return 0;
    800040ca:	4981                	li	s3,0
    800040cc:	bf19                	j	80003fe2 <namex+0x6a>
  if(*path == 0)
    800040ce:	d7fd                	beqz	a5,800040bc <namex+0x144>
  while(*path != '/' && *path != 0)
    800040d0:	0004c783          	lbu	a5,0(s1)
    800040d4:	85a6                	mv	a1,s1
    800040d6:	b7d1                	j	8000409a <namex+0x122>

00000000800040d8 <dirlink>:
{
    800040d8:	7139                	addi	sp,sp,-64
    800040da:	fc06                	sd	ra,56(sp)
    800040dc:	f822                	sd	s0,48(sp)
    800040de:	f426                	sd	s1,40(sp)
    800040e0:	f04a                	sd	s2,32(sp)
    800040e2:	ec4e                	sd	s3,24(sp)
    800040e4:	e852                	sd	s4,16(sp)
    800040e6:	0080                	addi	s0,sp,64
    800040e8:	892a                	mv	s2,a0
    800040ea:	8a2e                	mv	s4,a1
    800040ec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040ee:	4601                	li	a2,0
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	dd8080e7          	jalr	-552(ra) # 80003ec8 <dirlookup>
    800040f8:	e93d                	bnez	a0,8000416e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fa:	04c92483          	lw	s1,76(s2)
    800040fe:	c49d                	beqz	s1,8000412c <dirlink+0x54>
    80004100:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004102:	4741                	li	a4,16
    80004104:	86a6                	mv	a3,s1
    80004106:	fc040613          	addi	a2,s0,-64
    8000410a:	4581                	li	a1,0
    8000410c:	854a                	mv	a0,s2
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	b8a080e7          	jalr	-1142(ra) # 80003c98 <readi>
    80004116:	47c1                	li	a5,16
    80004118:	06f51163          	bne	a0,a5,8000417a <dirlink+0xa2>
    if(de.inum == 0)
    8000411c:	fc045783          	lhu	a5,-64(s0)
    80004120:	c791                	beqz	a5,8000412c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004122:	24c1                	addiw	s1,s1,16
    80004124:	04c92783          	lw	a5,76(s2)
    80004128:	fcf4ede3          	bltu	s1,a5,80004102 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	85d2                	mv	a1,s4
    80004130:	fc240513          	addi	a0,s0,-62
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	c9e080e7          	jalr	-866(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    8000413c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004140:	4741                	li	a4,16
    80004142:	86a6                	mv	a3,s1
    80004144:	fc040613          	addi	a2,s0,-64
    80004148:	4581                	li	a1,0
    8000414a:	854a                	mv	a0,s2
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	c44080e7          	jalr	-956(ra) # 80003d90 <writei>
    80004154:	872a                	mv	a4,a0
    80004156:	47c1                	li	a5,16
  return 0;
    80004158:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000415a:	02f71863          	bne	a4,a5,8000418a <dirlink+0xb2>
}
    8000415e:	70e2                	ld	ra,56(sp)
    80004160:	7442                	ld	s0,48(sp)
    80004162:	74a2                	ld	s1,40(sp)
    80004164:	7902                	ld	s2,32(sp)
    80004166:	69e2                	ld	s3,24(sp)
    80004168:	6a42                	ld	s4,16(sp)
    8000416a:	6121                	addi	sp,sp,64
    8000416c:	8082                	ret
    iput(ip);
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	a30080e7          	jalr	-1488(ra) # 80003b9e <iput>
    return -1;
    80004176:	557d                	li	a0,-1
    80004178:	b7dd                	j	8000415e <dirlink+0x86>
      panic("dirlink read");
    8000417a:	00004517          	auipc	a0,0x4
    8000417e:	55650513          	addi	a0,a0,1366 # 800086d0 <syscalls+0x1c8>
    80004182:	ffffc097          	auipc	ra,0xffffc
    80004186:	3a8080e7          	jalr	936(ra) # 8000052a <panic>
    panic("dirlink");
    8000418a:	00004517          	auipc	a0,0x4
    8000418e:	6ce50513          	addi	a0,a0,1742 # 80008858 <syscalls+0x350>
    80004192:	ffffc097          	auipc	ra,0xffffc
    80004196:	398080e7          	jalr	920(ra) # 8000052a <panic>

000000008000419a <namei>:

struct inode*
namei(char *path)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041a2:	fe040613          	addi	a2,s0,-32
    800041a6:	4581                	li	a1,0
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	dd0080e7          	jalr	-560(ra) # 80003f78 <namex>
}
    800041b0:	60e2                	ld	ra,24(sp)
    800041b2:	6442                	ld	s0,16(sp)
    800041b4:	6105                	addi	sp,sp,32
    800041b6:	8082                	ret

00000000800041b8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041b8:	1141                	addi	sp,sp,-16
    800041ba:	e406                	sd	ra,8(sp)
    800041bc:	e022                	sd	s0,0(sp)
    800041be:	0800                	addi	s0,sp,16
    800041c0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041c2:	4585                	li	a1,1
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	db4080e7          	jalr	-588(ra) # 80003f78 <namex>
}
    800041cc:	60a2                	ld	ra,8(sp)
    800041ce:	6402                	ld	s0,0(sp)
    800041d0:	0141                	addi	sp,sp,16
    800041d2:	8082                	ret

00000000800041d4 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800041d4:	1101                	addi	sp,sp,-32
    800041d6:	ec22                	sd	s0,24(sp)
    800041d8:	1000                	addi	s0,sp,32
    800041da:	872a                	mv	a4,a0
    800041dc:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800041de:	00004797          	auipc	a5,0x4
    800041e2:	50278793          	addi	a5,a5,1282 # 800086e0 <syscalls+0x1d8>
    800041e6:	6394                	ld	a3,0(a5)
    800041e8:	fed43023          	sd	a3,-32(s0)
    800041ec:	0087d683          	lhu	a3,8(a5)
    800041f0:	fed41423          	sh	a3,-24(s0)
    800041f4:	00a7c783          	lbu	a5,10(a5)
    800041f8:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800041fc:	87ae                	mv	a5,a1
    if(i<0){
    800041fe:	02074b63          	bltz	a4,80004234 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    80004202:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004204:	4629                	li	a2,10
        ++p;
    80004206:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004208:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    8000420c:	feed                	bnez	a3,80004206 <itoa+0x32>
    *p = '\0';
    8000420e:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    80004212:	4629                	li	a2,10
    80004214:	17fd                	addi	a5,a5,-1
    80004216:	02c766bb          	remw	a3,a4,a2
    8000421a:	ff040593          	addi	a1,s0,-16
    8000421e:	96ae                	add	a3,a3,a1
    80004220:	ff06c683          	lbu	a3,-16(a3)
    80004224:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004228:	02c7473b          	divw	a4,a4,a2
    }while(i);
    8000422c:	f765                	bnez	a4,80004214 <itoa+0x40>
    return b;
}
    8000422e:	6462                	ld	s0,24(sp)
    80004230:	6105                	addi	sp,sp,32
    80004232:	8082                	ret
        *p++ = '-';
    80004234:	00158793          	addi	a5,a1,1
    80004238:	02d00693          	li	a3,45
    8000423c:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004240:	40e0073b          	negw	a4,a4
    80004244:	bf7d                	j	80004202 <itoa+0x2e>

0000000080004246 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004246:	711d                	addi	sp,sp,-96
    80004248:	ec86                	sd	ra,88(sp)
    8000424a:	e8a2                	sd	s0,80(sp)
    8000424c:	e4a6                	sd	s1,72(sp)
    8000424e:	e0ca                	sd	s2,64(sp)
    80004250:	1080                	addi	s0,sp,96
    80004252:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004254:	4619                	li	a2,6
    80004256:	00004597          	auipc	a1,0x4
    8000425a:	49a58593          	addi	a1,a1,1178 # 800086f0 <syscalls+0x1e8>
    8000425e:	fd040513          	addi	a0,s0,-48
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	ab8080e7          	jalr	-1352(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000426a:	fd640593          	addi	a1,s0,-42
    8000426e:	5888                	lw	a0,48(s1)
    80004270:	00000097          	auipc	ra,0x0
    80004274:	f64080e7          	jalr	-156(ra) # 800041d4 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004278:	1684b503          	ld	a0,360(s1)
    8000427c:	16050763          	beqz	a0,800043ea <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004280:	00001097          	auipc	ra,0x1
    80004284:	918080e7          	jalr	-1768(ra) # 80004b98 <fileclose>

  begin_op();
    80004288:	00000097          	auipc	ra,0x0
    8000428c:	444080e7          	jalr	1092(ra) # 800046cc <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004290:	fb040593          	addi	a1,s0,-80
    80004294:	fd040513          	addi	a0,s0,-48
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	f20080e7          	jalr	-224(ra) # 800041b8 <nameiparent>
    800042a0:	892a                	mv	s2,a0
    800042a2:	cd69                	beqz	a0,8000437c <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	740080e7          	jalr	1856(ra) # 800039e4 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800042ac:	00004597          	auipc	a1,0x4
    800042b0:	44c58593          	addi	a1,a1,1100 # 800086f8 <syscalls+0x1f0>
    800042b4:	fb040513          	addi	a0,s0,-80
    800042b8:	00000097          	auipc	ra,0x0
    800042bc:	bf6080e7          	jalr	-1034(ra) # 80003eae <namecmp>
    800042c0:	c57d                	beqz	a0,800043ae <removeSwapFile+0x168>
    800042c2:	00004597          	auipc	a1,0x4
    800042c6:	43e58593          	addi	a1,a1,1086 # 80008700 <syscalls+0x1f8>
    800042ca:	fb040513          	addi	a0,s0,-80
    800042ce:	00000097          	auipc	ra,0x0
    800042d2:	be0080e7          	jalr	-1056(ra) # 80003eae <namecmp>
    800042d6:	cd61                	beqz	a0,800043ae <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800042d8:	fac40613          	addi	a2,s0,-84
    800042dc:	fb040593          	addi	a1,s0,-80
    800042e0:	854a                	mv	a0,s2
    800042e2:	00000097          	auipc	ra,0x0
    800042e6:	be6080e7          	jalr	-1050(ra) # 80003ec8 <dirlookup>
    800042ea:	84aa                	mv	s1,a0
    800042ec:	c169                	beqz	a0,800043ae <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	6f6080e7          	jalr	1782(ra) # 800039e4 <ilock>

  if(ip->nlink < 1)
    800042f6:	04a49783          	lh	a5,74(s1)
    800042fa:	08f05763          	blez	a5,80004388 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800042fe:	04449703          	lh	a4,68(s1)
    80004302:	4785                	li	a5,1
    80004304:	08f70a63          	beq	a4,a5,80004398 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004308:	4641                	li	a2,16
    8000430a:	4581                	li	a1,0
    8000430c:	fc040513          	addi	a0,s0,-64
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	9ae080e7          	jalr	-1618(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004318:	4741                	li	a4,16
    8000431a:	fac42683          	lw	a3,-84(s0)
    8000431e:	fc040613          	addi	a2,s0,-64
    80004322:	4581                	li	a1,0
    80004324:	854a                	mv	a0,s2
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	a6a080e7          	jalr	-1430(ra) # 80003d90 <writei>
    8000432e:	47c1                	li	a5,16
    80004330:	08f51a63          	bne	a0,a5,800043c4 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004334:	04449703          	lh	a4,68(s1)
    80004338:	4785                	li	a5,1
    8000433a:	08f70d63          	beq	a4,a5,800043d4 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000433e:	854a                	mv	a0,s2
    80004340:	00000097          	auipc	ra,0x0
    80004344:	906080e7          	jalr	-1786(ra) # 80003c46 <iunlockput>

  ip->nlink--;
    80004348:	04a4d783          	lhu	a5,74(s1)
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004352:	8526                	mv	a0,s1
    80004354:	fffff097          	auipc	ra,0xfffff
    80004358:	5c6080e7          	jalr	1478(ra) # 8000391a <iupdate>
  iunlockput(ip);
    8000435c:	8526                	mv	a0,s1
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	8e8080e7          	jalr	-1816(ra) # 80003c46 <iunlockput>

  end_op();
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	3e6080e7          	jalr	998(ra) # 8000474c <end_op>

  return 0;
    8000436e:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004370:	60e6                	ld	ra,88(sp)
    80004372:	6446                	ld	s0,80(sp)
    80004374:	64a6                	ld	s1,72(sp)
    80004376:	6906                	ld	s2,64(sp)
    80004378:	6125                	addi	sp,sp,96
    8000437a:	8082                	ret
    end_op();
    8000437c:	00000097          	auipc	ra,0x0
    80004380:	3d0080e7          	jalr	976(ra) # 8000474c <end_op>
    return -1;
    80004384:	557d                	li	a0,-1
    80004386:	b7ed                	j	80004370 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004388:	00004517          	auipc	a0,0x4
    8000438c:	38050513          	addi	a0,a0,896 # 80008708 <syscalls+0x200>
    80004390:	ffffc097          	auipc	ra,0xffffc
    80004394:	19a080e7          	jalr	410(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004398:	8526                	mv	a0,s1
    8000439a:	00001097          	auipc	ra,0x1
    8000439e:	798080e7          	jalr	1944(ra) # 80005b32 <isdirempty>
    800043a2:	f13d                	bnez	a0,80004308 <removeSwapFile+0xc2>
    iunlockput(ip);
    800043a4:	8526                	mv	a0,s1
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	8a0080e7          	jalr	-1888(ra) # 80003c46 <iunlockput>
    iunlockput(dp);
    800043ae:	854a                	mv	a0,s2
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	896080e7          	jalr	-1898(ra) # 80003c46 <iunlockput>
    end_op();
    800043b8:	00000097          	auipc	ra,0x0
    800043bc:	394080e7          	jalr	916(ra) # 8000474c <end_op>
    return -1;
    800043c0:	557d                	li	a0,-1
    800043c2:	b77d                	j	80004370 <removeSwapFile+0x12a>
    panic("unlink: writei");
    800043c4:	00004517          	auipc	a0,0x4
    800043c8:	35c50513          	addi	a0,a0,860 # 80008720 <syscalls+0x218>
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	15e080e7          	jalr	350(ra) # 8000052a <panic>
    dp->nlink--;
    800043d4:	04a95783          	lhu	a5,74(s2)
    800043d8:	37fd                	addiw	a5,a5,-1
    800043da:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800043de:	854a                	mv	a0,s2
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	53a080e7          	jalr	1338(ra) # 8000391a <iupdate>
    800043e8:	bf99                	j	8000433e <removeSwapFile+0xf8>
    return -1;
    800043ea:	557d                	li	a0,-1
    800043ec:	b751                	j	80004370 <removeSwapFile+0x12a>

00000000800043ee <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800043ee:	7179                	addi	sp,sp,-48
    800043f0:	f406                	sd	ra,40(sp)
    800043f2:	f022                	sd	s0,32(sp)
    800043f4:	ec26                	sd	s1,24(sp)
    800043f6:	e84a                	sd	s2,16(sp)
    800043f8:	1800                	addi	s0,sp,48
    800043fa:	84aa                	mv	s1,a0
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800043fc:	4619                	li	a2,6
    800043fe:	00004597          	auipc	a1,0x4
    80004402:	2f258593          	addi	a1,a1,754 # 800086f0 <syscalls+0x1e8>
    80004406:	fd040513          	addi	a0,s0,-48
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	910080e7          	jalr	-1776(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    80004412:	fd640593          	addi	a1,s0,-42
    80004416:	5888                	lw	a0,48(s1)
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	dbc080e7          	jalr	-580(ra) # 800041d4 <itoa>

  begin_op();
    80004420:	00000097          	auipc	ra,0x0
    80004424:	2ac080e7          	jalr	684(ra) # 800046cc <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004428:	4681                	li	a3,0
    8000442a:	4601                	li	a2,0
    8000442c:	4589                	li	a1,2
    8000442e:	fd040513          	addi	a0,s0,-48
    80004432:	00002097          	auipc	ra,0x2
    80004436:	8f4080e7          	jalr	-1804(ra) # 80005d26 <create>
    8000443a:	892a                	mv	s2,a0
  iunlock(in);
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	66a080e7          	jalr	1642(ra) # 80003aa6 <iunlock>
  p->swapFile = filealloc();
    80004444:	00000097          	auipc	ra,0x0
    80004448:	698080e7          	jalr	1688(ra) # 80004adc <filealloc>
    8000444c:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004450:	cd1d                	beqz	a0,8000448e <createSwapFile+0xa0>
    panic("no slot for files on /store");
  p->swapFile->ip = in;
    80004452:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004456:	1684b703          	ld	a4,360(s1)
    8000445a:	4789                	li	a5,2
    8000445c:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    8000445e:	1684b703          	ld	a4,360(s1)
    80004462:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004466:	1684b703          	ld	a4,360(s1)
    8000446a:	4685                	li	a3,1
    8000446c:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004470:	1684b703          	ld	a4,360(s1)
    80004474:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	2d4080e7          	jalr	724(ra) # 8000474c <end_op>
  return 0;
}
    80004480:	4501                	li	a0,0
    80004482:	70a2                	ld	ra,40(sp)
    80004484:	7402                	ld	s0,32(sp)
    80004486:	64e2                	ld	s1,24(sp)
    80004488:	6942                	ld	s2,16(sp)
    8000448a:	6145                	addi	sp,sp,48
    8000448c:	8082                	ret
    panic("no slot for files on /store");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	2a250513          	addi	a0,a0,674 # 80008730 <syscalls+0x228>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	094080e7          	jalr	148(ra) # 8000052a <panic>

000000008000449e <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    8000449e:	1141                	addi	sp,sp,-16
    800044a0:	e406                	sd	ra,8(sp)
    800044a2:	e022                	sd	s0,0(sp)
    800044a4:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800044a6:	16853783          	ld	a5,360(a0)
    800044aa:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800044ac:	8636                	mv	a2,a3
    800044ae:	16853503          	ld	a0,360(a0)
    800044b2:	00001097          	auipc	ra,0x1
    800044b6:	ad8080e7          	jalr	-1320(ra) # 80004f8a <kfilewrite>
}
    800044ba:	60a2                	ld	ra,8(sp)
    800044bc:	6402                	ld	s0,0(sp)
    800044be:	0141                	addi	sp,sp,16
    800044c0:	8082                	ret

00000000800044c2 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800044c2:	1141                	addi	sp,sp,-16
    800044c4:	e406                	sd	ra,8(sp)
    800044c6:	e022                	sd	s0,0(sp)
    800044c8:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800044ca:	16853783          	ld	a5,360(a0)
    800044ce:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800044d0:	8636                	mv	a2,a3
    800044d2:	16853503          	ld	a0,360(a0)
    800044d6:	00001097          	auipc	ra,0x1
    800044da:	9f2080e7          	jalr	-1550(ra) # 80004ec8 <kfileread>
    800044de:	60a2                	ld	ra,8(sp)
    800044e0:	6402                	ld	s0,0(sp)
    800044e2:	0141                	addi	sp,sp,16
    800044e4:	8082                	ret

00000000800044e6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044e6:	1101                	addi	sp,sp,-32
    800044e8:	ec06                	sd	ra,24(sp)
    800044ea:	e822                	sd	s0,16(sp)
    800044ec:	e426                	sd	s1,8(sp)
    800044ee:	e04a                	sd	s2,0(sp)
    800044f0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044f2:	00023917          	auipc	s2,0x23
    800044f6:	f7e90913          	addi	s2,s2,-130 # 80027470 <log>
    800044fa:	01892583          	lw	a1,24(s2)
    800044fe:	02892503          	lw	a0,40(s2)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	cde080e7          	jalr	-802(ra) # 800031e0 <bread>
    8000450a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000450c:	02c92683          	lw	a3,44(s2)
    80004510:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004512:	02d05863          	blez	a3,80004542 <write_head+0x5c>
    80004516:	00023797          	auipc	a5,0x23
    8000451a:	f8a78793          	addi	a5,a5,-118 # 800274a0 <log+0x30>
    8000451e:	05c50713          	addi	a4,a0,92
    80004522:	36fd                	addiw	a3,a3,-1
    80004524:	02069613          	slli	a2,a3,0x20
    80004528:	01e65693          	srli	a3,a2,0x1e
    8000452c:	00023617          	auipc	a2,0x23
    80004530:	f7860613          	addi	a2,a2,-136 # 800274a4 <log+0x34>
    80004534:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004536:	4390                	lw	a2,0(a5)
    80004538:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000453a:	0791                	addi	a5,a5,4
    8000453c:	0711                	addi	a4,a4,4
    8000453e:	fed79ce3          	bne	a5,a3,80004536 <write_head+0x50>
  }
  bwrite(buf);
    80004542:	8526                	mv	a0,s1
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	d8e080e7          	jalr	-626(ra) # 800032d2 <bwrite>
  brelse(buf);
    8000454c:	8526                	mv	a0,s1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	dc2080e7          	jalr	-574(ra) # 80003310 <brelse>
}
    80004556:	60e2                	ld	ra,24(sp)
    80004558:	6442                	ld	s0,16(sp)
    8000455a:	64a2                	ld	s1,8(sp)
    8000455c:	6902                	ld	s2,0(sp)
    8000455e:	6105                	addi	sp,sp,32
    80004560:	8082                	ret

0000000080004562 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004562:	00023797          	auipc	a5,0x23
    80004566:	f3a7a783          	lw	a5,-198(a5) # 8002749c <log+0x2c>
    8000456a:	0af05d63          	blez	a5,80004624 <install_trans+0xc2>
{
    8000456e:	7139                	addi	sp,sp,-64
    80004570:	fc06                	sd	ra,56(sp)
    80004572:	f822                	sd	s0,48(sp)
    80004574:	f426                	sd	s1,40(sp)
    80004576:	f04a                	sd	s2,32(sp)
    80004578:	ec4e                	sd	s3,24(sp)
    8000457a:	e852                	sd	s4,16(sp)
    8000457c:	e456                	sd	s5,8(sp)
    8000457e:	e05a                	sd	s6,0(sp)
    80004580:	0080                	addi	s0,sp,64
    80004582:	8b2a                	mv	s6,a0
    80004584:	00023a97          	auipc	s5,0x23
    80004588:	f1ca8a93          	addi	s5,s5,-228 # 800274a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000458c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000458e:	00023997          	auipc	s3,0x23
    80004592:	ee298993          	addi	s3,s3,-286 # 80027470 <log>
    80004596:	a00d                	j	800045b8 <install_trans+0x56>
    brelse(lbuf);
    80004598:	854a                	mv	a0,s2
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	d76080e7          	jalr	-650(ra) # 80003310 <brelse>
    brelse(dbuf);
    800045a2:	8526                	mv	a0,s1
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	d6c080e7          	jalr	-660(ra) # 80003310 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ac:	2a05                	addiw	s4,s4,1
    800045ae:	0a91                	addi	s5,s5,4
    800045b0:	02c9a783          	lw	a5,44(s3)
    800045b4:	04fa5e63          	bge	s4,a5,80004610 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045b8:	0189a583          	lw	a1,24(s3)
    800045bc:	014585bb          	addw	a1,a1,s4
    800045c0:	2585                	addiw	a1,a1,1
    800045c2:	0289a503          	lw	a0,40(s3)
    800045c6:	fffff097          	auipc	ra,0xfffff
    800045ca:	c1a080e7          	jalr	-998(ra) # 800031e0 <bread>
    800045ce:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045d0:	000aa583          	lw	a1,0(s5)
    800045d4:	0289a503          	lw	a0,40(s3)
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	c08080e7          	jalr	-1016(ra) # 800031e0 <bread>
    800045e0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045e2:	40000613          	li	a2,1024
    800045e6:	05890593          	addi	a1,s2,88
    800045ea:	05850513          	addi	a0,a0,88
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	72c080e7          	jalr	1836(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800045f6:	8526                	mv	a0,s1
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	cda080e7          	jalr	-806(ra) # 800032d2 <bwrite>
    if(recovering == 0)
    80004600:	f80b1ce3          	bnez	s6,80004598 <install_trans+0x36>
      bunpin(dbuf);
    80004604:	8526                	mv	a0,s1
    80004606:	fffff097          	auipc	ra,0xfffff
    8000460a:	de4080e7          	jalr	-540(ra) # 800033ea <bunpin>
    8000460e:	b769                	j	80004598 <install_trans+0x36>
}
    80004610:	70e2                	ld	ra,56(sp)
    80004612:	7442                	ld	s0,48(sp)
    80004614:	74a2                	ld	s1,40(sp)
    80004616:	7902                	ld	s2,32(sp)
    80004618:	69e2                	ld	s3,24(sp)
    8000461a:	6a42                	ld	s4,16(sp)
    8000461c:	6aa2                	ld	s5,8(sp)
    8000461e:	6b02                	ld	s6,0(sp)
    80004620:	6121                	addi	sp,sp,64
    80004622:	8082                	ret
    80004624:	8082                	ret

0000000080004626 <initlog>:
{
    80004626:	7179                	addi	sp,sp,-48
    80004628:	f406                	sd	ra,40(sp)
    8000462a:	f022                	sd	s0,32(sp)
    8000462c:	ec26                	sd	s1,24(sp)
    8000462e:	e84a                	sd	s2,16(sp)
    80004630:	e44e                	sd	s3,8(sp)
    80004632:	1800                	addi	s0,sp,48
    80004634:	892a                	mv	s2,a0
    80004636:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004638:	00023497          	auipc	s1,0x23
    8000463c:	e3848493          	addi	s1,s1,-456 # 80027470 <log>
    80004640:	00004597          	auipc	a1,0x4
    80004644:	11058593          	addi	a1,a1,272 # 80008750 <syscalls+0x248>
    80004648:	8526                	mv	a0,s1
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	4e8080e7          	jalr	1256(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004652:	0149a583          	lw	a1,20(s3)
    80004656:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004658:	0109a783          	lw	a5,16(s3)
    8000465c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000465e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004662:	854a                	mv	a0,s2
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	b7c080e7          	jalr	-1156(ra) # 800031e0 <bread>
  log.lh.n = lh->n;
    8000466c:	4d34                	lw	a3,88(a0)
    8000466e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004670:	02d05663          	blez	a3,8000469c <initlog+0x76>
    80004674:	05c50793          	addi	a5,a0,92
    80004678:	00023717          	auipc	a4,0x23
    8000467c:	e2870713          	addi	a4,a4,-472 # 800274a0 <log+0x30>
    80004680:	36fd                	addiw	a3,a3,-1
    80004682:	02069613          	slli	a2,a3,0x20
    80004686:	01e65693          	srli	a3,a2,0x1e
    8000468a:	06050613          	addi	a2,a0,96
    8000468e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004690:	4390                	lw	a2,0(a5)
    80004692:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004694:	0791                	addi	a5,a5,4
    80004696:	0711                	addi	a4,a4,4
    80004698:	fed79ce3          	bne	a5,a3,80004690 <initlog+0x6a>
  brelse(buf);
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	c74080e7          	jalr	-908(ra) # 80003310 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046a4:	4505                	li	a0,1
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	ebc080e7          	jalr	-324(ra) # 80004562 <install_trans>
  log.lh.n = 0;
    800046ae:	00023797          	auipc	a5,0x23
    800046b2:	de07a723          	sw	zero,-530(a5) # 8002749c <log+0x2c>
  write_head(); // clear the log
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	e30080e7          	jalr	-464(ra) # 800044e6 <write_head>
}
    800046be:	70a2                	ld	ra,40(sp)
    800046c0:	7402                	ld	s0,32(sp)
    800046c2:	64e2                	ld	s1,24(sp)
    800046c4:	6942                	ld	s2,16(sp)
    800046c6:	69a2                	ld	s3,8(sp)
    800046c8:	6145                	addi	sp,sp,48
    800046ca:	8082                	ret

00000000800046cc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046cc:	1101                	addi	sp,sp,-32
    800046ce:	ec06                	sd	ra,24(sp)
    800046d0:	e822                	sd	s0,16(sp)
    800046d2:	e426                	sd	s1,8(sp)
    800046d4:	e04a                	sd	s2,0(sp)
    800046d6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046d8:	00023517          	auipc	a0,0x23
    800046dc:	d9850513          	addi	a0,a0,-616 # 80027470 <log>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	4e2080e7          	jalr	1250(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800046e8:	00023497          	auipc	s1,0x23
    800046ec:	d8848493          	addi	s1,s1,-632 # 80027470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046f0:	4979                	li	s2,30
    800046f2:	a039                	j	80004700 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046f4:	85a6                	mv	a1,s1
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffe097          	auipc	ra,0xffffe
    800046fc:	d72080e7          	jalr	-654(ra) # 8000246a <sleep>
    if(log.committing){
    80004700:	50dc                	lw	a5,36(s1)
    80004702:	fbed                	bnez	a5,800046f4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004704:	509c                	lw	a5,32(s1)
    80004706:	0017871b          	addiw	a4,a5,1
    8000470a:	0007069b          	sext.w	a3,a4
    8000470e:	0027179b          	slliw	a5,a4,0x2
    80004712:	9fb9                	addw	a5,a5,a4
    80004714:	0017979b          	slliw	a5,a5,0x1
    80004718:	54d8                	lw	a4,44(s1)
    8000471a:	9fb9                	addw	a5,a5,a4
    8000471c:	00f95963          	bge	s2,a5,8000472e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004720:	85a6                	mv	a1,s1
    80004722:	8526                	mv	a0,s1
    80004724:	ffffe097          	auipc	ra,0xffffe
    80004728:	d46080e7          	jalr	-698(ra) # 8000246a <sleep>
    8000472c:	bfd1                	j	80004700 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000472e:	00023517          	auipc	a0,0x23
    80004732:	d4250513          	addi	a0,a0,-702 # 80027470 <log>
    80004736:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	53e080e7          	jalr	1342(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004740:	60e2                	ld	ra,24(sp)
    80004742:	6442                	ld	s0,16(sp)
    80004744:	64a2                	ld	s1,8(sp)
    80004746:	6902                	ld	s2,0(sp)
    80004748:	6105                	addi	sp,sp,32
    8000474a:	8082                	ret

000000008000474c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000474c:	7139                	addi	sp,sp,-64
    8000474e:	fc06                	sd	ra,56(sp)
    80004750:	f822                	sd	s0,48(sp)
    80004752:	f426                	sd	s1,40(sp)
    80004754:	f04a                	sd	s2,32(sp)
    80004756:	ec4e                	sd	s3,24(sp)
    80004758:	e852                	sd	s4,16(sp)
    8000475a:	e456                	sd	s5,8(sp)
    8000475c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000475e:	00023497          	auipc	s1,0x23
    80004762:	d1248493          	addi	s1,s1,-750 # 80027470 <log>
    80004766:	8526                	mv	a0,s1
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	45a080e7          	jalr	1114(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004770:	509c                	lw	a5,32(s1)
    80004772:	37fd                	addiw	a5,a5,-1
    80004774:	0007891b          	sext.w	s2,a5
    80004778:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000477a:	50dc                	lw	a5,36(s1)
    8000477c:	e7b9                	bnez	a5,800047ca <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000477e:	04091e63          	bnez	s2,800047da <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004782:	00023497          	auipc	s1,0x23
    80004786:	cee48493          	addi	s1,s1,-786 # 80027470 <log>
    8000478a:	4785                	li	a5,1
    8000478c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	4e6080e7          	jalr	1254(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004798:	54dc                	lw	a5,44(s1)
    8000479a:	06f04763          	bgtz	a5,80004808 <end_op+0xbc>
    acquire(&log.lock);
    8000479e:	00023497          	auipc	s1,0x23
    800047a2:	cd248493          	addi	s1,s1,-814 # 80027470 <log>
    800047a6:	8526                	mv	a0,s1
    800047a8:	ffffc097          	auipc	ra,0xffffc
    800047ac:	41a080e7          	jalr	1050(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800047b0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047b4:	8526                	mv	a0,s1
    800047b6:	ffffe097          	auipc	ra,0xffffe
    800047ba:	e40080e7          	jalr	-448(ra) # 800025f6 <wakeup>
    release(&log.lock);
    800047be:	8526                	mv	a0,s1
    800047c0:	ffffc097          	auipc	ra,0xffffc
    800047c4:	4b6080e7          	jalr	1206(ra) # 80000c76 <release>
}
    800047c8:	a03d                	j	800047f6 <end_op+0xaa>
    panic("log.committing");
    800047ca:	00004517          	auipc	a0,0x4
    800047ce:	f8e50513          	addi	a0,a0,-114 # 80008758 <syscalls+0x250>
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	d58080e7          	jalr	-680(ra) # 8000052a <panic>
    wakeup(&log);
    800047da:	00023497          	auipc	s1,0x23
    800047de:	c9648493          	addi	s1,s1,-874 # 80027470 <log>
    800047e2:	8526                	mv	a0,s1
    800047e4:	ffffe097          	auipc	ra,0xffffe
    800047e8:	e12080e7          	jalr	-494(ra) # 800025f6 <wakeup>
  release(&log.lock);
    800047ec:	8526                	mv	a0,s1
    800047ee:	ffffc097          	auipc	ra,0xffffc
    800047f2:	488080e7          	jalr	1160(ra) # 80000c76 <release>
}
    800047f6:	70e2                	ld	ra,56(sp)
    800047f8:	7442                	ld	s0,48(sp)
    800047fa:	74a2                	ld	s1,40(sp)
    800047fc:	7902                	ld	s2,32(sp)
    800047fe:	69e2                	ld	s3,24(sp)
    80004800:	6a42                	ld	s4,16(sp)
    80004802:	6aa2                	ld	s5,8(sp)
    80004804:	6121                	addi	sp,sp,64
    80004806:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004808:	00023a97          	auipc	s5,0x23
    8000480c:	c98a8a93          	addi	s5,s5,-872 # 800274a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004810:	00023a17          	auipc	s4,0x23
    80004814:	c60a0a13          	addi	s4,s4,-928 # 80027470 <log>
    80004818:	018a2583          	lw	a1,24(s4)
    8000481c:	012585bb          	addw	a1,a1,s2
    80004820:	2585                	addiw	a1,a1,1
    80004822:	028a2503          	lw	a0,40(s4)
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	9ba080e7          	jalr	-1606(ra) # 800031e0 <bread>
    8000482e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004830:	000aa583          	lw	a1,0(s5)
    80004834:	028a2503          	lw	a0,40(s4)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	9a8080e7          	jalr	-1624(ra) # 800031e0 <bread>
    80004840:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004842:	40000613          	li	a2,1024
    80004846:	05850593          	addi	a1,a0,88
    8000484a:	05848513          	addi	a0,s1,88
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	4cc080e7          	jalr	1228(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004856:	8526                	mv	a0,s1
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	a7a080e7          	jalr	-1414(ra) # 800032d2 <bwrite>
    brelse(from);
    80004860:	854e                	mv	a0,s3
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	aae080e7          	jalr	-1362(ra) # 80003310 <brelse>
    brelse(to);
    8000486a:	8526                	mv	a0,s1
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	aa4080e7          	jalr	-1372(ra) # 80003310 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004874:	2905                	addiw	s2,s2,1
    80004876:	0a91                	addi	s5,s5,4
    80004878:	02ca2783          	lw	a5,44(s4)
    8000487c:	f8f94ee3          	blt	s2,a5,80004818 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004880:	00000097          	auipc	ra,0x0
    80004884:	c66080e7          	jalr	-922(ra) # 800044e6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004888:	4501                	li	a0,0
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	cd8080e7          	jalr	-808(ra) # 80004562 <install_trans>
    log.lh.n = 0;
    80004892:	00023797          	auipc	a5,0x23
    80004896:	c007a523          	sw	zero,-1014(a5) # 8002749c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000489a:	00000097          	auipc	ra,0x0
    8000489e:	c4c080e7          	jalr	-948(ra) # 800044e6 <write_head>
    800048a2:	bdf5                	j	8000479e <end_op+0x52>

00000000800048a4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048a4:	1101                	addi	sp,sp,-32
    800048a6:	ec06                	sd	ra,24(sp)
    800048a8:	e822                	sd	s0,16(sp)
    800048aa:	e426                	sd	s1,8(sp)
    800048ac:	e04a                	sd	s2,0(sp)
    800048ae:	1000                	addi	s0,sp,32
    800048b0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048b2:	00023917          	auipc	s2,0x23
    800048b6:	bbe90913          	addi	s2,s2,-1090 # 80027470 <log>
    800048ba:	854a                	mv	a0,s2
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	306080e7          	jalr	774(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048c4:	02c92603          	lw	a2,44(s2)
    800048c8:	47f5                	li	a5,29
    800048ca:	06c7c563          	blt	a5,a2,80004934 <log_write+0x90>
    800048ce:	00023797          	auipc	a5,0x23
    800048d2:	bbe7a783          	lw	a5,-1090(a5) # 8002748c <log+0x1c>
    800048d6:	37fd                	addiw	a5,a5,-1
    800048d8:	04f65e63          	bge	a2,a5,80004934 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048dc:	00023797          	auipc	a5,0x23
    800048e0:	bb47a783          	lw	a5,-1100(a5) # 80027490 <log+0x20>
    800048e4:	06f05063          	blez	a5,80004944 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048e8:	4781                	li	a5,0
    800048ea:	06c05563          	blez	a2,80004954 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048ee:	44cc                	lw	a1,12(s1)
    800048f0:	00023717          	auipc	a4,0x23
    800048f4:	bb070713          	addi	a4,a4,-1104 # 800274a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048f8:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048fa:	4314                	lw	a3,0(a4)
    800048fc:	04b68c63          	beq	a3,a1,80004954 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004900:	2785                	addiw	a5,a5,1
    80004902:	0711                	addi	a4,a4,4
    80004904:	fef61be3          	bne	a2,a5,800048fa <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004908:	0621                	addi	a2,a2,8
    8000490a:	060a                	slli	a2,a2,0x2
    8000490c:	00023797          	auipc	a5,0x23
    80004910:	b6478793          	addi	a5,a5,-1180 # 80027470 <log>
    80004914:	963e                	add	a2,a2,a5
    80004916:	44dc                	lw	a5,12(s1)
    80004918:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000491a:	8526                	mv	a0,s1
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	a92080e7          	jalr	-1390(ra) # 800033ae <bpin>
    log.lh.n++;
    80004924:	00023717          	auipc	a4,0x23
    80004928:	b4c70713          	addi	a4,a4,-1204 # 80027470 <log>
    8000492c:	575c                	lw	a5,44(a4)
    8000492e:	2785                	addiw	a5,a5,1
    80004930:	d75c                	sw	a5,44(a4)
    80004932:	a835                	j	8000496e <log_write+0xca>
    panic("too big a transaction");
    80004934:	00004517          	auipc	a0,0x4
    80004938:	e3450513          	addi	a0,a0,-460 # 80008768 <syscalls+0x260>
    8000493c:	ffffc097          	auipc	ra,0xffffc
    80004940:	bee080e7          	jalr	-1042(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	e3c50513          	addi	a0,a0,-452 # 80008780 <syscalls+0x278>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bde080e7          	jalr	-1058(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004954:	00878713          	addi	a4,a5,8
    80004958:	00271693          	slli	a3,a4,0x2
    8000495c:	00023717          	auipc	a4,0x23
    80004960:	b1470713          	addi	a4,a4,-1260 # 80027470 <log>
    80004964:	9736                	add	a4,a4,a3
    80004966:	44d4                	lw	a3,12(s1)
    80004968:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000496a:	faf608e3          	beq	a2,a5,8000491a <log_write+0x76>
  }
  release(&log.lock);
    8000496e:	00023517          	auipc	a0,0x23
    80004972:	b0250513          	addi	a0,a0,-1278 # 80027470 <log>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	300080e7          	jalr	768(ra) # 80000c76 <release>
}
    8000497e:	60e2                	ld	ra,24(sp)
    80004980:	6442                	ld	s0,16(sp)
    80004982:	64a2                	ld	s1,8(sp)
    80004984:	6902                	ld	s2,0(sp)
    80004986:	6105                	addi	sp,sp,32
    80004988:	8082                	ret

000000008000498a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000498a:	1101                	addi	sp,sp,-32
    8000498c:	ec06                	sd	ra,24(sp)
    8000498e:	e822                	sd	s0,16(sp)
    80004990:	e426                	sd	s1,8(sp)
    80004992:	e04a                	sd	s2,0(sp)
    80004994:	1000                	addi	s0,sp,32
    80004996:	84aa                	mv	s1,a0
    80004998:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000499a:	00004597          	auipc	a1,0x4
    8000499e:	e0658593          	addi	a1,a1,-506 # 800087a0 <syscalls+0x298>
    800049a2:	0521                	addi	a0,a0,8
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	18e080e7          	jalr	398(ra) # 80000b32 <initlock>
  lk->name = name;
    800049ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049b4:	0204a423          	sw	zero,40(s1)
}
    800049b8:	60e2                	ld	ra,24(sp)
    800049ba:	6442                	ld	s0,16(sp)
    800049bc:	64a2                	ld	s1,8(sp)
    800049be:	6902                	ld	s2,0(sp)
    800049c0:	6105                	addi	sp,sp,32
    800049c2:	8082                	ret

00000000800049c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049c4:	1101                	addi	sp,sp,-32
    800049c6:	ec06                	sd	ra,24(sp)
    800049c8:	e822                	sd	s0,16(sp)
    800049ca:	e426                	sd	s1,8(sp)
    800049cc:	e04a                	sd	s2,0(sp)
    800049ce:	1000                	addi	s0,sp,32
    800049d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049d2:	00850913          	addi	s2,a0,8
    800049d6:	854a                	mv	a0,s2
    800049d8:	ffffc097          	auipc	ra,0xffffc
    800049dc:	1ea080e7          	jalr	490(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800049e0:	409c                	lw	a5,0(s1)
    800049e2:	cb89                	beqz	a5,800049f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049e4:	85ca                	mv	a1,s2
    800049e6:	8526                	mv	a0,s1
    800049e8:	ffffe097          	auipc	ra,0xffffe
    800049ec:	a82080e7          	jalr	-1406(ra) # 8000246a <sleep>
  while (lk->locked) {
    800049f0:	409c                	lw	a5,0(s1)
    800049f2:	fbed                	bnez	a5,800049e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049f4:	4785                	li	a5,1
    800049f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049f8:	ffffd097          	auipc	ra,0xffffd
    800049fc:	222080e7          	jalr	546(ra) # 80001c1a <myproc>
    80004a00:	591c                	lw	a5,48(a0)
    80004a02:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a04:	854a                	mv	a0,s2
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	270080e7          	jalr	624(ra) # 80000c76 <release>
}
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6902                	ld	s2,0(sp)
    80004a16:	6105                	addi	sp,sp,32
    80004a18:	8082                	ret

0000000080004a1a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a1a:	1101                	addi	sp,sp,-32
    80004a1c:	ec06                	sd	ra,24(sp)
    80004a1e:	e822                	sd	s0,16(sp)
    80004a20:	e426                	sd	s1,8(sp)
    80004a22:	e04a                	sd	s2,0(sp)
    80004a24:	1000                	addi	s0,sp,32
    80004a26:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a28:	00850913          	addi	s2,a0,8
    80004a2c:	854a                	mv	a0,s2
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	194080e7          	jalr	404(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004a36:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a3a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a3e:	8526                	mv	a0,s1
    80004a40:	ffffe097          	auipc	ra,0xffffe
    80004a44:	bb6080e7          	jalr	-1098(ra) # 800025f6 <wakeup>
  release(&lk->lk);
    80004a48:	854a                	mv	a0,s2
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	22c080e7          	jalr	556(ra) # 80000c76 <release>
}
    80004a52:	60e2                	ld	ra,24(sp)
    80004a54:	6442                	ld	s0,16(sp)
    80004a56:	64a2                	ld	s1,8(sp)
    80004a58:	6902                	ld	s2,0(sp)
    80004a5a:	6105                	addi	sp,sp,32
    80004a5c:	8082                	ret

0000000080004a5e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a5e:	7179                	addi	sp,sp,-48
    80004a60:	f406                	sd	ra,40(sp)
    80004a62:	f022                	sd	s0,32(sp)
    80004a64:	ec26                	sd	s1,24(sp)
    80004a66:	e84a                	sd	s2,16(sp)
    80004a68:	e44e                	sd	s3,8(sp)
    80004a6a:	1800                	addi	s0,sp,48
    80004a6c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a6e:	00850913          	addi	s2,a0,8
    80004a72:	854a                	mv	a0,s2
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	14e080e7          	jalr	334(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a7c:	409c                	lw	a5,0(s1)
    80004a7e:	ef99                	bnez	a5,80004a9c <holdingsleep+0x3e>
    80004a80:	4481                	li	s1,0
  release(&lk->lk);
    80004a82:	854a                	mv	a0,s2
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	1f2080e7          	jalr	498(ra) # 80000c76 <release>
  return r;
}
    80004a8c:	8526                	mv	a0,s1
    80004a8e:	70a2                	ld	ra,40(sp)
    80004a90:	7402                	ld	s0,32(sp)
    80004a92:	64e2                	ld	s1,24(sp)
    80004a94:	6942                	ld	s2,16(sp)
    80004a96:	69a2                	ld	s3,8(sp)
    80004a98:	6145                	addi	sp,sp,48
    80004a9a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a9c:	0284a983          	lw	s3,40(s1)
    80004aa0:	ffffd097          	auipc	ra,0xffffd
    80004aa4:	17a080e7          	jalr	378(ra) # 80001c1a <myproc>
    80004aa8:	5904                	lw	s1,48(a0)
    80004aaa:	413484b3          	sub	s1,s1,s3
    80004aae:	0014b493          	seqz	s1,s1
    80004ab2:	bfc1                	j	80004a82 <holdingsleep+0x24>

0000000080004ab4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ab4:	1141                	addi	sp,sp,-16
    80004ab6:	e406                	sd	ra,8(sp)
    80004ab8:	e022                	sd	s0,0(sp)
    80004aba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004abc:	00004597          	auipc	a1,0x4
    80004ac0:	cf458593          	addi	a1,a1,-780 # 800087b0 <syscalls+0x2a8>
    80004ac4:	00023517          	auipc	a0,0x23
    80004ac8:	af450513          	addi	a0,a0,-1292 # 800275b8 <ftable>
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	066080e7          	jalr	102(ra) # 80000b32 <initlock>
}
    80004ad4:	60a2                	ld	ra,8(sp)
    80004ad6:	6402                	ld	s0,0(sp)
    80004ad8:	0141                	addi	sp,sp,16
    80004ada:	8082                	ret

0000000080004adc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004adc:	1101                	addi	sp,sp,-32
    80004ade:	ec06                	sd	ra,24(sp)
    80004ae0:	e822                	sd	s0,16(sp)
    80004ae2:	e426                	sd	s1,8(sp)
    80004ae4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ae6:	00023517          	auipc	a0,0x23
    80004aea:	ad250513          	addi	a0,a0,-1326 # 800275b8 <ftable>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	0d4080e7          	jalr	212(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004af6:	00023497          	auipc	s1,0x23
    80004afa:	ada48493          	addi	s1,s1,-1318 # 800275d0 <ftable+0x18>
    80004afe:	00024717          	auipc	a4,0x24
    80004b02:	a7270713          	addi	a4,a4,-1422 # 80028570 <ftable+0xfb8>
    if(f->ref == 0){
    80004b06:	40dc                	lw	a5,4(s1)
    80004b08:	cf99                	beqz	a5,80004b26 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b0a:	02848493          	addi	s1,s1,40
    80004b0e:	fee49ce3          	bne	s1,a4,80004b06 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b12:	00023517          	auipc	a0,0x23
    80004b16:	aa650513          	addi	a0,a0,-1370 # 800275b8 <ftable>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	15c080e7          	jalr	348(ra) # 80000c76 <release>
  return 0;
    80004b22:	4481                	li	s1,0
    80004b24:	a819                	j	80004b3a <filealloc+0x5e>
      f->ref = 1;
    80004b26:	4785                	li	a5,1
    80004b28:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b2a:	00023517          	auipc	a0,0x23
    80004b2e:	a8e50513          	addi	a0,a0,-1394 # 800275b8 <ftable>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	144080e7          	jalr	324(ra) # 80000c76 <release>
}
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	60e2                	ld	ra,24(sp)
    80004b3e:	6442                	ld	s0,16(sp)
    80004b40:	64a2                	ld	s1,8(sp)
    80004b42:	6105                	addi	sp,sp,32
    80004b44:	8082                	ret

0000000080004b46 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b46:	1101                	addi	sp,sp,-32
    80004b48:	ec06                	sd	ra,24(sp)
    80004b4a:	e822                	sd	s0,16(sp)
    80004b4c:	e426                	sd	s1,8(sp)
    80004b4e:	1000                	addi	s0,sp,32
    80004b50:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b52:	00023517          	auipc	a0,0x23
    80004b56:	a6650513          	addi	a0,a0,-1434 # 800275b8 <ftable>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	068080e7          	jalr	104(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004b62:	40dc                	lw	a5,4(s1)
    80004b64:	02f05263          	blez	a5,80004b88 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b68:	2785                	addiw	a5,a5,1
    80004b6a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b6c:	00023517          	auipc	a0,0x23
    80004b70:	a4c50513          	addi	a0,a0,-1460 # 800275b8 <ftable>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	102080e7          	jalr	258(ra) # 80000c76 <release>
  return f;
}
    80004b7c:	8526                	mv	a0,s1
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6105                	addi	sp,sp,32
    80004b86:	8082                	ret
    panic("filedup");
    80004b88:	00004517          	auipc	a0,0x4
    80004b8c:	c3050513          	addi	a0,a0,-976 # 800087b8 <syscalls+0x2b0>
    80004b90:	ffffc097          	auipc	ra,0xffffc
    80004b94:	99a080e7          	jalr	-1638(ra) # 8000052a <panic>

0000000080004b98 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b98:	7139                	addi	sp,sp,-64
    80004b9a:	fc06                	sd	ra,56(sp)
    80004b9c:	f822                	sd	s0,48(sp)
    80004b9e:	f426                	sd	s1,40(sp)
    80004ba0:	f04a                	sd	s2,32(sp)
    80004ba2:	ec4e                	sd	s3,24(sp)
    80004ba4:	e852                	sd	s4,16(sp)
    80004ba6:	e456                	sd	s5,8(sp)
    80004ba8:	0080                	addi	s0,sp,64
    80004baa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bac:	00023517          	auipc	a0,0x23
    80004bb0:	a0c50513          	addi	a0,a0,-1524 # 800275b8 <ftable>
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	00e080e7          	jalr	14(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004bbc:	40dc                	lw	a5,4(s1)
    80004bbe:	06f05163          	blez	a5,80004c20 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bc2:	37fd                	addiw	a5,a5,-1
    80004bc4:	0007871b          	sext.w	a4,a5
    80004bc8:	c0dc                	sw	a5,4(s1)
    80004bca:	06e04363          	bgtz	a4,80004c30 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004bce:	0004a903          	lw	s2,0(s1)
    80004bd2:	0094ca83          	lbu	s5,9(s1)
    80004bd6:	0104ba03          	ld	s4,16(s1)
    80004bda:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bde:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004be2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004be6:	00023517          	auipc	a0,0x23
    80004bea:	9d250513          	addi	a0,a0,-1582 # 800275b8 <ftable>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	088080e7          	jalr	136(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004bf6:	4785                	li	a5,1
    80004bf8:	04f90d63          	beq	s2,a5,80004c52 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bfc:	3979                	addiw	s2,s2,-2
    80004bfe:	4785                	li	a5,1
    80004c00:	0527e063          	bltu	a5,s2,80004c40 <fileclose+0xa8>
    begin_op();
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	ac8080e7          	jalr	-1336(ra) # 800046cc <begin_op>
    iput(ff.ip);
    80004c0c:	854e                	mv	a0,s3
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	f90080e7          	jalr	-112(ra) # 80003b9e <iput>
    end_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	b36080e7          	jalr	-1226(ra) # 8000474c <end_op>
    80004c1e:	a00d                	j	80004c40 <fileclose+0xa8>
    panic("fileclose");
    80004c20:	00004517          	auipc	a0,0x4
    80004c24:	ba050513          	addi	a0,a0,-1120 # 800087c0 <syscalls+0x2b8>
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	902080e7          	jalr	-1790(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004c30:	00023517          	auipc	a0,0x23
    80004c34:	98850513          	addi	a0,a0,-1656 # 800275b8 <ftable>
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	03e080e7          	jalr	62(ra) # 80000c76 <release>
  }
}
    80004c40:	70e2                	ld	ra,56(sp)
    80004c42:	7442                	ld	s0,48(sp)
    80004c44:	74a2                	ld	s1,40(sp)
    80004c46:	7902                	ld	s2,32(sp)
    80004c48:	69e2                	ld	s3,24(sp)
    80004c4a:	6a42                	ld	s4,16(sp)
    80004c4c:	6aa2                	ld	s5,8(sp)
    80004c4e:	6121                	addi	sp,sp,64
    80004c50:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c52:	85d6                	mv	a1,s5
    80004c54:	8552                	mv	a0,s4
    80004c56:	00000097          	auipc	ra,0x0
    80004c5a:	542080e7          	jalr	1346(ra) # 80005198 <pipeclose>
    80004c5e:	b7cd                	j	80004c40 <fileclose+0xa8>

0000000080004c60 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c60:	715d                	addi	sp,sp,-80
    80004c62:	e486                	sd	ra,72(sp)
    80004c64:	e0a2                	sd	s0,64(sp)
    80004c66:	fc26                	sd	s1,56(sp)
    80004c68:	f84a                	sd	s2,48(sp)
    80004c6a:	f44e                	sd	s3,40(sp)
    80004c6c:	0880                	addi	s0,sp,80
    80004c6e:	84aa                	mv	s1,a0
    80004c70:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	fa8080e7          	jalr	-88(ra) # 80001c1a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c7a:	409c                	lw	a5,0(s1)
    80004c7c:	37f9                	addiw	a5,a5,-2
    80004c7e:	4705                	li	a4,1
    80004c80:	04f76763          	bltu	a4,a5,80004cce <filestat+0x6e>
    80004c84:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c86:	6c88                	ld	a0,24(s1)
    80004c88:	fffff097          	auipc	ra,0xfffff
    80004c8c:	d5c080e7          	jalr	-676(ra) # 800039e4 <ilock>
    stati(f->ip, &st);
    80004c90:	fb840593          	addi	a1,s0,-72
    80004c94:	6c88                	ld	a0,24(s1)
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	fd8080e7          	jalr	-40(ra) # 80003c6e <stati>
    iunlock(f->ip);
    80004c9e:	6c88                	ld	a0,24(s1)
    80004ca0:	fffff097          	auipc	ra,0xfffff
    80004ca4:	e06080e7          	jalr	-506(ra) # 80003aa6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004ca8:	46e1                	li	a3,24
    80004caa:	fb840613          	addi	a2,s0,-72
    80004cae:	85ce                	mv	a1,s3
    80004cb0:	05093503          	ld	a0,80(s2)
    80004cb4:	ffffd097          	auipc	ra,0xffffd
    80004cb8:	98a080e7          	jalr	-1654(ra) # 8000163e <copyout>
    80004cbc:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cc0:	60a6                	ld	ra,72(sp)
    80004cc2:	6406                	ld	s0,64(sp)
    80004cc4:	74e2                	ld	s1,56(sp)
    80004cc6:	7942                	ld	s2,48(sp)
    80004cc8:	79a2                	ld	s3,40(sp)
    80004cca:	6161                	addi	sp,sp,80
    80004ccc:	8082                	ret
  return -1;
    80004cce:	557d                	li	a0,-1
    80004cd0:	bfc5                	j	80004cc0 <filestat+0x60>

0000000080004cd2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004cd2:	7179                	addi	sp,sp,-48
    80004cd4:	f406                	sd	ra,40(sp)
    80004cd6:	f022                	sd	s0,32(sp)
    80004cd8:	ec26                	sd	s1,24(sp)
    80004cda:	e84a                	sd	s2,16(sp)
    80004cdc:	e44e                	sd	s3,8(sp)
    80004cde:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ce0:	00854783          	lbu	a5,8(a0)
    80004ce4:	c3d5                	beqz	a5,80004d88 <fileread+0xb6>
    80004ce6:	84aa                	mv	s1,a0
    80004ce8:	89ae                	mv	s3,a1
    80004cea:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cec:	411c                	lw	a5,0(a0)
    80004cee:	4705                	li	a4,1
    80004cf0:	04e78963          	beq	a5,a4,80004d42 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cf4:	470d                	li	a4,3
    80004cf6:	04e78d63          	beq	a5,a4,80004d50 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cfa:	4709                	li	a4,2
    80004cfc:	06e79e63          	bne	a5,a4,80004d78 <fileread+0xa6>
    ilock(f->ip);
    80004d00:	6d08                	ld	a0,24(a0)
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	ce2080e7          	jalr	-798(ra) # 800039e4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d0a:	874a                	mv	a4,s2
    80004d0c:	5094                	lw	a3,32(s1)
    80004d0e:	864e                	mv	a2,s3
    80004d10:	4585                	li	a1,1
    80004d12:	6c88                	ld	a0,24(s1)
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	f84080e7          	jalr	-124(ra) # 80003c98 <readi>
    80004d1c:	892a                	mv	s2,a0
    80004d1e:	00a05563          	blez	a0,80004d28 <fileread+0x56>
      f->off += r;
    80004d22:	509c                	lw	a5,32(s1)
    80004d24:	9fa9                	addw	a5,a5,a0
    80004d26:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d28:	6c88                	ld	a0,24(s1)
    80004d2a:	fffff097          	auipc	ra,0xfffff
    80004d2e:	d7c080e7          	jalr	-644(ra) # 80003aa6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d32:	854a                	mv	a0,s2
    80004d34:	70a2                	ld	ra,40(sp)
    80004d36:	7402                	ld	s0,32(sp)
    80004d38:	64e2                	ld	s1,24(sp)
    80004d3a:	6942                	ld	s2,16(sp)
    80004d3c:	69a2                	ld	s3,8(sp)
    80004d3e:	6145                	addi	sp,sp,48
    80004d40:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d42:	6908                	ld	a0,16(a0)
    80004d44:	00000097          	auipc	ra,0x0
    80004d48:	5b6080e7          	jalr	1462(ra) # 800052fa <piperead>
    80004d4c:	892a                	mv	s2,a0
    80004d4e:	b7d5                	j	80004d32 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d50:	02451783          	lh	a5,36(a0)
    80004d54:	03079693          	slli	a3,a5,0x30
    80004d58:	92c1                	srli	a3,a3,0x30
    80004d5a:	4725                	li	a4,9
    80004d5c:	02d76863          	bltu	a4,a3,80004d8c <fileread+0xba>
    80004d60:	0792                	slli	a5,a5,0x4
    80004d62:	00022717          	auipc	a4,0x22
    80004d66:	7b670713          	addi	a4,a4,1974 # 80027518 <devsw>
    80004d6a:	97ba                	add	a5,a5,a4
    80004d6c:	639c                	ld	a5,0(a5)
    80004d6e:	c38d                	beqz	a5,80004d90 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d70:	4505                	li	a0,1
    80004d72:	9782                	jalr	a5
    80004d74:	892a                	mv	s2,a0
    80004d76:	bf75                	j	80004d32 <fileread+0x60>
    panic("fileread");
    80004d78:	00004517          	auipc	a0,0x4
    80004d7c:	a5850513          	addi	a0,a0,-1448 # 800087d0 <syscalls+0x2c8>
    80004d80:	ffffb097          	auipc	ra,0xffffb
    80004d84:	7aa080e7          	jalr	1962(ra) # 8000052a <panic>
    return -1;
    80004d88:	597d                	li	s2,-1
    80004d8a:	b765                	j	80004d32 <fileread+0x60>
      return -1;
    80004d8c:	597d                	li	s2,-1
    80004d8e:	b755                	j	80004d32 <fileread+0x60>
    80004d90:	597d                	li	s2,-1
    80004d92:	b745                	j	80004d32 <fileread+0x60>

0000000080004d94 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d94:	715d                	addi	sp,sp,-80
    80004d96:	e486                	sd	ra,72(sp)
    80004d98:	e0a2                	sd	s0,64(sp)
    80004d9a:	fc26                	sd	s1,56(sp)
    80004d9c:	f84a                	sd	s2,48(sp)
    80004d9e:	f44e                	sd	s3,40(sp)
    80004da0:	f052                	sd	s4,32(sp)
    80004da2:	ec56                	sd	s5,24(sp)
    80004da4:	e85a                	sd	s6,16(sp)
    80004da6:	e45e                	sd	s7,8(sp)
    80004da8:	e062                	sd	s8,0(sp)
    80004daa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dac:	00954783          	lbu	a5,9(a0)
    80004db0:	10078663          	beqz	a5,80004ebc <filewrite+0x128>
    80004db4:	892a                	mv	s2,a0
    80004db6:	8aae                	mv	s5,a1
    80004db8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dba:	411c                	lw	a5,0(a0)
    80004dbc:	4705                	li	a4,1
    80004dbe:	02e78263          	beq	a5,a4,80004de2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dc2:	470d                	li	a4,3
    80004dc4:	02e78663          	beq	a5,a4,80004df0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dc8:	4709                	li	a4,2
    80004dca:	0ee79163          	bne	a5,a4,80004eac <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004dce:	0ac05d63          	blez	a2,80004e88 <filewrite+0xf4>
    int i = 0;
    80004dd2:	4981                	li	s3,0
    80004dd4:	6b05                	lui	s6,0x1
    80004dd6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dda:	6b85                	lui	s7,0x1
    80004ddc:	c00b8b9b          	addiw	s7,s7,-1024
    80004de0:	a861                	j	80004e78 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004de2:	6908                	ld	a0,16(a0)
    80004de4:	00000097          	auipc	ra,0x0
    80004de8:	424080e7          	jalr	1060(ra) # 80005208 <pipewrite>
    80004dec:	8a2a                	mv	s4,a0
    80004dee:	a045                	j	80004e8e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004df0:	02451783          	lh	a5,36(a0)
    80004df4:	03079693          	slli	a3,a5,0x30
    80004df8:	92c1                	srli	a3,a3,0x30
    80004dfa:	4725                	li	a4,9
    80004dfc:	0cd76263          	bltu	a4,a3,80004ec0 <filewrite+0x12c>
    80004e00:	0792                	slli	a5,a5,0x4
    80004e02:	00022717          	auipc	a4,0x22
    80004e06:	71670713          	addi	a4,a4,1814 # 80027518 <devsw>
    80004e0a:	97ba                	add	a5,a5,a4
    80004e0c:	679c                	ld	a5,8(a5)
    80004e0e:	cbdd                	beqz	a5,80004ec4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e10:	4505                	li	a0,1
    80004e12:	9782                	jalr	a5
    80004e14:	8a2a                	mv	s4,a0
    80004e16:	a8a5                	j	80004e8e <filewrite+0xfa>
    80004e18:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e1c:	00000097          	auipc	ra,0x0
    80004e20:	8b0080e7          	jalr	-1872(ra) # 800046cc <begin_op>
      ilock(f->ip);
    80004e24:	01893503          	ld	a0,24(s2)
    80004e28:	fffff097          	auipc	ra,0xfffff
    80004e2c:	bbc080e7          	jalr	-1092(ra) # 800039e4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e30:	8762                	mv	a4,s8
    80004e32:	02092683          	lw	a3,32(s2)
    80004e36:	01598633          	add	a2,s3,s5
    80004e3a:	4585                	li	a1,1
    80004e3c:	01893503          	ld	a0,24(s2)
    80004e40:	fffff097          	auipc	ra,0xfffff
    80004e44:	f50080e7          	jalr	-176(ra) # 80003d90 <writei>
    80004e48:	84aa                	mv	s1,a0
    80004e4a:	00a05763          	blez	a0,80004e58 <filewrite+0xc4>
        f->off += r;
    80004e4e:	02092783          	lw	a5,32(s2)
    80004e52:	9fa9                	addw	a5,a5,a0
    80004e54:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e58:	01893503          	ld	a0,24(s2)
    80004e5c:	fffff097          	auipc	ra,0xfffff
    80004e60:	c4a080e7          	jalr	-950(ra) # 80003aa6 <iunlock>
      end_op();
    80004e64:	00000097          	auipc	ra,0x0
    80004e68:	8e8080e7          	jalr	-1816(ra) # 8000474c <end_op>

      if(r != n1){
    80004e6c:	009c1f63          	bne	s8,s1,80004e8a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e70:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e74:	0149db63          	bge	s3,s4,80004e8a <filewrite+0xf6>
      int n1 = n - i;
    80004e78:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e7c:	84be                	mv	s1,a5
    80004e7e:	2781                	sext.w	a5,a5
    80004e80:	f8fb5ce3          	bge	s6,a5,80004e18 <filewrite+0x84>
    80004e84:	84de                	mv	s1,s7
    80004e86:	bf49                	j	80004e18 <filewrite+0x84>
    int i = 0;
    80004e88:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e8a:	013a1f63          	bne	s4,s3,80004ea8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e8e:	8552                	mv	a0,s4
    80004e90:	60a6                	ld	ra,72(sp)
    80004e92:	6406                	ld	s0,64(sp)
    80004e94:	74e2                	ld	s1,56(sp)
    80004e96:	7942                	ld	s2,48(sp)
    80004e98:	79a2                	ld	s3,40(sp)
    80004e9a:	7a02                	ld	s4,32(sp)
    80004e9c:	6ae2                	ld	s5,24(sp)
    80004e9e:	6b42                	ld	s6,16(sp)
    80004ea0:	6ba2                	ld	s7,8(sp)
    80004ea2:	6c02                	ld	s8,0(sp)
    80004ea4:	6161                	addi	sp,sp,80
    80004ea6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ea8:	5a7d                	li	s4,-1
    80004eaa:	b7d5                	j	80004e8e <filewrite+0xfa>
    panic("filewrite");
    80004eac:	00004517          	auipc	a0,0x4
    80004eb0:	93450513          	addi	a0,a0,-1740 # 800087e0 <syscalls+0x2d8>
    80004eb4:	ffffb097          	auipc	ra,0xffffb
    80004eb8:	676080e7          	jalr	1654(ra) # 8000052a <panic>
    return -1;
    80004ebc:	5a7d                	li	s4,-1
    80004ebe:	bfc1                	j	80004e8e <filewrite+0xfa>
      return -1;
    80004ec0:	5a7d                	li	s4,-1
    80004ec2:	b7f1                	j	80004e8e <filewrite+0xfa>
    80004ec4:	5a7d                	li	s4,-1
    80004ec6:	b7e1                	j	80004e8e <filewrite+0xfa>

0000000080004ec8 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80004ec8:	7179                	addi	sp,sp,-48
    80004eca:	f406                	sd	ra,40(sp)
    80004ecc:	f022                	sd	s0,32(sp)
    80004ece:	ec26                	sd	s1,24(sp)
    80004ed0:	e84a                	sd	s2,16(sp)
    80004ed2:	e44e                	sd	s3,8(sp)
    80004ed4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ed6:	00854783          	lbu	a5,8(a0)
    80004eda:	c3d5                	beqz	a5,80004f7e <kfileread+0xb6>
    80004edc:	84aa                	mv	s1,a0
    80004ede:	89ae                	mv	s3,a1
    80004ee0:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ee2:	411c                	lw	a5,0(a0)
    80004ee4:	4705                	li	a4,1
    80004ee6:	04e78963          	beq	a5,a4,80004f38 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004eea:	470d                	li	a4,3
    80004eec:	04e78d63          	beq	a5,a4,80004f46 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ef0:	4709                	li	a4,2
    80004ef2:	06e79e63          	bne	a5,a4,80004f6e <kfileread+0xa6>
    ilock(f->ip);
    80004ef6:	6d08                	ld	a0,24(a0)
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	aec080e7          	jalr	-1300(ra) # 800039e4 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80004f00:	874a                	mv	a4,s2
    80004f02:	5094                	lw	a3,32(s1)
    80004f04:	864e                	mv	a2,s3
    80004f06:	4581                	li	a1,0
    80004f08:	6c88                	ld	a0,24(s1)
    80004f0a:	fffff097          	auipc	ra,0xfffff
    80004f0e:	d8e080e7          	jalr	-626(ra) # 80003c98 <readi>
    80004f12:	892a                	mv	s2,a0
    80004f14:	00a05563          	blez	a0,80004f1e <kfileread+0x56>
      f->off += r;
    80004f18:	509c                	lw	a5,32(s1)
    80004f1a:	9fa9                	addw	a5,a5,a0
    80004f1c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004f1e:	6c88                	ld	a0,24(s1)
    80004f20:	fffff097          	auipc	ra,0xfffff
    80004f24:	b86080e7          	jalr	-1146(ra) # 80003aa6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004f28:	854a                	mv	a0,s2
    80004f2a:	70a2                	ld	ra,40(sp)
    80004f2c:	7402                	ld	s0,32(sp)
    80004f2e:	64e2                	ld	s1,24(sp)
    80004f30:	6942                	ld	s2,16(sp)
    80004f32:	69a2                	ld	s3,8(sp)
    80004f34:	6145                	addi	sp,sp,48
    80004f36:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f38:	6908                	ld	a0,16(a0)
    80004f3a:	00000097          	auipc	ra,0x0
    80004f3e:	3c0080e7          	jalr	960(ra) # 800052fa <piperead>
    80004f42:	892a                	mv	s2,a0
    80004f44:	b7d5                	j	80004f28 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f46:	02451783          	lh	a5,36(a0)
    80004f4a:	03079693          	slli	a3,a5,0x30
    80004f4e:	92c1                	srli	a3,a3,0x30
    80004f50:	4725                	li	a4,9
    80004f52:	02d76863          	bltu	a4,a3,80004f82 <kfileread+0xba>
    80004f56:	0792                	slli	a5,a5,0x4
    80004f58:	00022717          	auipc	a4,0x22
    80004f5c:	5c070713          	addi	a4,a4,1472 # 80027518 <devsw>
    80004f60:	97ba                	add	a5,a5,a4
    80004f62:	639c                	ld	a5,0(a5)
    80004f64:	c38d                	beqz	a5,80004f86 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f66:	4505                	li	a0,1
    80004f68:	9782                	jalr	a5
    80004f6a:	892a                	mv	s2,a0
    80004f6c:	bf75                	j	80004f28 <kfileread+0x60>
    panic("fileread");
    80004f6e:	00004517          	auipc	a0,0x4
    80004f72:	86250513          	addi	a0,a0,-1950 # 800087d0 <syscalls+0x2c8>
    80004f76:	ffffb097          	auipc	ra,0xffffb
    80004f7a:	5b4080e7          	jalr	1460(ra) # 8000052a <panic>
    return -1;
    80004f7e:	597d                	li	s2,-1
    80004f80:	b765                	j	80004f28 <kfileread+0x60>
      return -1;
    80004f82:	597d                	li	s2,-1
    80004f84:	b755                	j	80004f28 <kfileread+0x60>
    80004f86:	597d                	li	s2,-1
    80004f88:	b745                	j	80004f28 <kfileread+0x60>

0000000080004f8a <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80004f8a:	715d                	addi	sp,sp,-80
    80004f8c:	e486                	sd	ra,72(sp)
    80004f8e:	e0a2                	sd	s0,64(sp)
    80004f90:	fc26                	sd	s1,56(sp)
    80004f92:	f84a                	sd	s2,48(sp)
    80004f94:	f44e                	sd	s3,40(sp)
    80004f96:	f052                	sd	s4,32(sp)
    80004f98:	ec56                	sd	s5,24(sp)
    80004f9a:	e85a                	sd	s6,16(sp)
    80004f9c:	e45e                	sd	s7,8(sp)
    80004f9e:	e062                	sd	s8,0(sp)
    80004fa0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004fa2:	00954783          	lbu	a5,9(a0)
    80004fa6:	10078663          	beqz	a5,800050b2 <kfilewrite+0x128>
    80004faa:	892a                	mv	s2,a0
    80004fac:	8aae                	mv	s5,a1
    80004fae:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fb0:	411c                	lw	a5,0(a0)
    80004fb2:	4705                	li	a4,1
    80004fb4:	02e78263          	beq	a5,a4,80004fd8 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fb8:	470d                	li	a4,3
    80004fba:	02e78663          	beq	a5,a4,80004fe6 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fbe:	4709                	li	a4,2
    80004fc0:	0ee79163          	bne	a5,a4,800050a2 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004fc4:	0ac05d63          	blez	a2,8000507e <kfilewrite+0xf4>
    int i = 0;
    80004fc8:	4981                	li	s3,0
    80004fca:	6b05                	lui	s6,0x1
    80004fcc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fd0:	6b85                	lui	s7,0x1
    80004fd2:	c00b8b9b          	addiw	s7,s7,-1024
    80004fd6:	a861                	j	8000506e <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fd8:	6908                	ld	a0,16(a0)
    80004fda:	00000097          	auipc	ra,0x0
    80004fde:	22e080e7          	jalr	558(ra) # 80005208 <pipewrite>
    80004fe2:	8a2a                	mv	s4,a0
    80004fe4:	a045                	j	80005084 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fe6:	02451783          	lh	a5,36(a0)
    80004fea:	03079693          	slli	a3,a5,0x30
    80004fee:	92c1                	srli	a3,a3,0x30
    80004ff0:	4725                	li	a4,9
    80004ff2:	0cd76263          	bltu	a4,a3,800050b6 <kfilewrite+0x12c>
    80004ff6:	0792                	slli	a5,a5,0x4
    80004ff8:	00022717          	auipc	a4,0x22
    80004ffc:	52070713          	addi	a4,a4,1312 # 80027518 <devsw>
    80005000:	97ba                	add	a5,a5,a4
    80005002:	679c                	ld	a5,8(a5)
    80005004:	cbdd                	beqz	a5,800050ba <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005006:	4505                	li	a0,1
    80005008:	9782                	jalr	a5
    8000500a:	8a2a                	mv	s4,a0
    8000500c:	a8a5                	j	80005084 <kfilewrite+0xfa>
    8000500e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005012:	fffff097          	auipc	ra,0xfffff
    80005016:	6ba080e7          	jalr	1722(ra) # 800046cc <begin_op>
      ilock(f->ip);
    8000501a:	01893503          	ld	a0,24(s2)
    8000501e:	fffff097          	auipc	ra,0xfffff
    80005022:	9c6080e7          	jalr	-1594(ra) # 800039e4 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005026:	8762                	mv	a4,s8
    80005028:	02092683          	lw	a3,32(s2)
    8000502c:	01598633          	add	a2,s3,s5
    80005030:	4581                	li	a1,0
    80005032:	01893503          	ld	a0,24(s2)
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	d5a080e7          	jalr	-678(ra) # 80003d90 <writei>
    8000503e:	84aa                	mv	s1,a0
    80005040:	00a05763          	blez	a0,8000504e <kfilewrite+0xc4>
        f->off += r;
    80005044:	02092783          	lw	a5,32(s2)
    80005048:	9fa9                	addw	a5,a5,a0
    8000504a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000504e:	01893503          	ld	a0,24(s2)
    80005052:	fffff097          	auipc	ra,0xfffff
    80005056:	a54080e7          	jalr	-1452(ra) # 80003aa6 <iunlock>
      end_op();
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	6f2080e7          	jalr	1778(ra) # 8000474c <end_op>

      if(r != n1){
    80005062:	009c1f63          	bne	s8,s1,80005080 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005066:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000506a:	0149db63          	bge	s3,s4,80005080 <kfilewrite+0xf6>
      int n1 = n - i;
    8000506e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005072:	84be                	mv	s1,a5
    80005074:	2781                	sext.w	a5,a5
    80005076:	f8fb5ce3          	bge	s6,a5,8000500e <kfilewrite+0x84>
    8000507a:	84de                	mv	s1,s7
    8000507c:	bf49                	j	8000500e <kfilewrite+0x84>
    int i = 0;
    8000507e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005080:	013a1f63          	bne	s4,s3,8000509e <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005084:	8552                	mv	a0,s4
    80005086:	60a6                	ld	ra,72(sp)
    80005088:	6406                	ld	s0,64(sp)
    8000508a:	74e2                	ld	s1,56(sp)
    8000508c:	7942                	ld	s2,48(sp)
    8000508e:	79a2                	ld	s3,40(sp)
    80005090:	7a02                	ld	s4,32(sp)
    80005092:	6ae2                	ld	s5,24(sp)
    80005094:	6b42                	ld	s6,16(sp)
    80005096:	6ba2                	ld	s7,8(sp)
    80005098:	6c02                	ld	s8,0(sp)
    8000509a:	6161                	addi	sp,sp,80
    8000509c:	8082                	ret
    ret = (i == n ? n : -1);
    8000509e:	5a7d                	li	s4,-1
    800050a0:	b7d5                	j	80005084 <kfilewrite+0xfa>
    panic("filewrite");
    800050a2:	00003517          	auipc	a0,0x3
    800050a6:	73e50513          	addi	a0,a0,1854 # 800087e0 <syscalls+0x2d8>
    800050aa:	ffffb097          	auipc	ra,0xffffb
    800050ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>
    return -1;
    800050b2:	5a7d                	li	s4,-1
    800050b4:	bfc1                	j	80005084 <kfilewrite+0xfa>
      return -1;
    800050b6:	5a7d                	li	s4,-1
    800050b8:	b7f1                	j	80005084 <kfilewrite+0xfa>
    800050ba:	5a7d                	li	s4,-1
    800050bc:	b7e1                	j	80005084 <kfilewrite+0xfa>

00000000800050be <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800050be:	7179                	addi	sp,sp,-48
    800050c0:	f406                	sd	ra,40(sp)
    800050c2:	f022                	sd	s0,32(sp)
    800050c4:	ec26                	sd	s1,24(sp)
    800050c6:	e84a                	sd	s2,16(sp)
    800050c8:	e44e                	sd	s3,8(sp)
    800050ca:	e052                	sd	s4,0(sp)
    800050cc:	1800                	addi	s0,sp,48
    800050ce:	84aa                	mv	s1,a0
    800050d0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050d2:	0005b023          	sd	zero,0(a1)
    800050d6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050da:	00000097          	auipc	ra,0x0
    800050de:	a02080e7          	jalr	-1534(ra) # 80004adc <filealloc>
    800050e2:	e088                	sd	a0,0(s1)
    800050e4:	c551                	beqz	a0,80005170 <pipealloc+0xb2>
    800050e6:	00000097          	auipc	ra,0x0
    800050ea:	9f6080e7          	jalr	-1546(ra) # 80004adc <filealloc>
    800050ee:	00aa3023          	sd	a0,0(s4)
    800050f2:	c92d                	beqz	a0,80005164 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	9de080e7          	jalr	-1570(ra) # 80000ad2 <kalloc>
    800050fc:	892a                	mv	s2,a0
    800050fe:	c125                	beqz	a0,8000515e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005100:	4985                	li	s3,1
    80005102:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005106:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000510a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000510e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005112:	00003597          	auipc	a1,0x3
    80005116:	6de58593          	addi	a1,a1,1758 # 800087f0 <syscalls+0x2e8>
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	a18080e7          	jalr	-1512(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80005122:	609c                	ld	a5,0(s1)
    80005124:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005128:	609c                	ld	a5,0(s1)
    8000512a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000512e:	609c                	ld	a5,0(s1)
    80005130:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005134:	609c                	ld	a5,0(s1)
    80005136:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000513a:	000a3783          	ld	a5,0(s4)
    8000513e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005142:	000a3783          	ld	a5,0(s4)
    80005146:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000514a:	000a3783          	ld	a5,0(s4)
    8000514e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005152:	000a3783          	ld	a5,0(s4)
    80005156:	0127b823          	sd	s2,16(a5)
  return 0;
    8000515a:	4501                	li	a0,0
    8000515c:	a025                	j	80005184 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000515e:	6088                	ld	a0,0(s1)
    80005160:	e501                	bnez	a0,80005168 <pipealloc+0xaa>
    80005162:	a039                	j	80005170 <pipealloc+0xb2>
    80005164:	6088                	ld	a0,0(s1)
    80005166:	c51d                	beqz	a0,80005194 <pipealloc+0xd6>
    fileclose(*f0);
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	a30080e7          	jalr	-1488(ra) # 80004b98 <fileclose>
  if(*f1)
    80005170:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005174:	557d                	li	a0,-1
  if(*f1)
    80005176:	c799                	beqz	a5,80005184 <pipealloc+0xc6>
    fileclose(*f1);
    80005178:	853e                	mv	a0,a5
    8000517a:	00000097          	auipc	ra,0x0
    8000517e:	a1e080e7          	jalr	-1506(ra) # 80004b98 <fileclose>
  return -1;
    80005182:	557d                	li	a0,-1
}
    80005184:	70a2                	ld	ra,40(sp)
    80005186:	7402                	ld	s0,32(sp)
    80005188:	64e2                	ld	s1,24(sp)
    8000518a:	6942                	ld	s2,16(sp)
    8000518c:	69a2                	ld	s3,8(sp)
    8000518e:	6a02                	ld	s4,0(sp)
    80005190:	6145                	addi	sp,sp,48
    80005192:	8082                	ret
  return -1;
    80005194:	557d                	li	a0,-1
    80005196:	b7fd                	j	80005184 <pipealloc+0xc6>

0000000080005198 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005198:	1101                	addi	sp,sp,-32
    8000519a:	ec06                	sd	ra,24(sp)
    8000519c:	e822                	sd	s0,16(sp)
    8000519e:	e426                	sd	s1,8(sp)
    800051a0:	e04a                	sd	s2,0(sp)
    800051a2:	1000                	addi	s0,sp,32
    800051a4:	84aa                	mv	s1,a0
    800051a6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	a1a080e7          	jalr	-1510(ra) # 80000bc2 <acquire>
  if(writable){
    800051b0:	02090d63          	beqz	s2,800051ea <pipeclose+0x52>
    pi->writeopen = 0;
    800051b4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800051b8:	21848513          	addi	a0,s1,536
    800051bc:	ffffd097          	auipc	ra,0xffffd
    800051c0:	43a080e7          	jalr	1082(ra) # 800025f6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800051c4:	2204b783          	ld	a5,544(s1)
    800051c8:	eb95                	bnez	a5,800051fc <pipeclose+0x64>
    release(&pi->lock);
    800051ca:	8526                	mv	a0,s1
    800051cc:	ffffc097          	auipc	ra,0xffffc
    800051d0:	aaa080e7          	jalr	-1366(ra) # 80000c76 <release>
    kfree((char*)pi);
    800051d4:	8526                	mv	a0,s1
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	800080e7          	jalr	-2048(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800051de:	60e2                	ld	ra,24(sp)
    800051e0:	6442                	ld	s0,16(sp)
    800051e2:	64a2                	ld	s1,8(sp)
    800051e4:	6902                	ld	s2,0(sp)
    800051e6:	6105                	addi	sp,sp,32
    800051e8:	8082                	ret
    pi->readopen = 0;
    800051ea:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051ee:	21c48513          	addi	a0,s1,540
    800051f2:	ffffd097          	auipc	ra,0xffffd
    800051f6:	404080e7          	jalr	1028(ra) # 800025f6 <wakeup>
    800051fa:	b7e9                	j	800051c4 <pipeclose+0x2c>
    release(&pi->lock);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	a78080e7          	jalr	-1416(ra) # 80000c76 <release>
}
    80005206:	bfe1                	j	800051de <pipeclose+0x46>

0000000080005208 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005208:	711d                	addi	sp,sp,-96
    8000520a:	ec86                	sd	ra,88(sp)
    8000520c:	e8a2                	sd	s0,80(sp)
    8000520e:	e4a6                	sd	s1,72(sp)
    80005210:	e0ca                	sd	s2,64(sp)
    80005212:	fc4e                	sd	s3,56(sp)
    80005214:	f852                	sd	s4,48(sp)
    80005216:	f456                	sd	s5,40(sp)
    80005218:	f05a                	sd	s6,32(sp)
    8000521a:	ec5e                	sd	s7,24(sp)
    8000521c:	e862                	sd	s8,16(sp)
    8000521e:	1080                	addi	s0,sp,96
    80005220:	84aa                	mv	s1,a0
    80005222:	8aae                	mv	s5,a1
    80005224:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005226:	ffffd097          	auipc	ra,0xffffd
    8000522a:	9f4080e7          	jalr	-1548(ra) # 80001c1a <myproc>
    8000522e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005230:	8526                	mv	a0,s1
    80005232:	ffffc097          	auipc	ra,0xffffc
    80005236:	990080e7          	jalr	-1648(ra) # 80000bc2 <acquire>
  while(i < n){
    8000523a:	0b405363          	blez	s4,800052e0 <pipewrite+0xd8>
  int i = 0;
    8000523e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005240:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005242:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005246:	21c48b93          	addi	s7,s1,540
    8000524a:	a089                	j	8000528c <pipewrite+0x84>
      release(&pi->lock);
    8000524c:	8526                	mv	a0,s1
    8000524e:	ffffc097          	auipc	ra,0xffffc
    80005252:	a28080e7          	jalr	-1496(ra) # 80000c76 <release>
      return -1;
    80005256:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005258:	854a                	mv	a0,s2
    8000525a:	60e6                	ld	ra,88(sp)
    8000525c:	6446                	ld	s0,80(sp)
    8000525e:	64a6                	ld	s1,72(sp)
    80005260:	6906                	ld	s2,64(sp)
    80005262:	79e2                	ld	s3,56(sp)
    80005264:	7a42                	ld	s4,48(sp)
    80005266:	7aa2                	ld	s5,40(sp)
    80005268:	7b02                	ld	s6,32(sp)
    8000526a:	6be2                	ld	s7,24(sp)
    8000526c:	6c42                	ld	s8,16(sp)
    8000526e:	6125                	addi	sp,sp,96
    80005270:	8082                	ret
      wakeup(&pi->nread);
    80005272:	8562                	mv	a0,s8
    80005274:	ffffd097          	auipc	ra,0xffffd
    80005278:	382080e7          	jalr	898(ra) # 800025f6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000527c:	85a6                	mv	a1,s1
    8000527e:	855e                	mv	a0,s7
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	1ea080e7          	jalr	490(ra) # 8000246a <sleep>
  while(i < n){
    80005288:	05495d63          	bge	s2,s4,800052e2 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    8000528c:	2204a783          	lw	a5,544(s1)
    80005290:	dfd5                	beqz	a5,8000524c <pipewrite+0x44>
    80005292:	0289a783          	lw	a5,40(s3)
    80005296:	fbdd                	bnez	a5,8000524c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005298:	2184a783          	lw	a5,536(s1)
    8000529c:	21c4a703          	lw	a4,540(s1)
    800052a0:	2007879b          	addiw	a5,a5,512
    800052a4:	fcf707e3          	beq	a4,a5,80005272 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800052a8:	4685                	li	a3,1
    800052aa:	01590633          	add	a2,s2,s5
    800052ae:	faf40593          	addi	a1,s0,-81
    800052b2:	0509b503          	ld	a0,80(s3)
    800052b6:	ffffc097          	auipc	ra,0xffffc
    800052ba:	414080e7          	jalr	1044(ra) # 800016ca <copyin>
    800052be:	03650263          	beq	a0,s6,800052e2 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800052c2:	21c4a783          	lw	a5,540(s1)
    800052c6:	0017871b          	addiw	a4,a5,1
    800052ca:	20e4ae23          	sw	a4,540(s1)
    800052ce:	1ff7f793          	andi	a5,a5,511
    800052d2:	97a6                	add	a5,a5,s1
    800052d4:	faf44703          	lbu	a4,-81(s0)
    800052d8:	00e78c23          	sb	a4,24(a5)
      i++;
    800052dc:	2905                	addiw	s2,s2,1
    800052de:	b76d                	j	80005288 <pipewrite+0x80>
  int i = 0;
    800052e0:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052e2:	21848513          	addi	a0,s1,536
    800052e6:	ffffd097          	auipc	ra,0xffffd
    800052ea:	310080e7          	jalr	784(ra) # 800025f6 <wakeup>
  release(&pi->lock);
    800052ee:	8526                	mv	a0,s1
    800052f0:	ffffc097          	auipc	ra,0xffffc
    800052f4:	986080e7          	jalr	-1658(ra) # 80000c76 <release>
  return i;
    800052f8:	b785                	j	80005258 <pipewrite+0x50>

00000000800052fa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052fa:	715d                	addi	sp,sp,-80
    800052fc:	e486                	sd	ra,72(sp)
    800052fe:	e0a2                	sd	s0,64(sp)
    80005300:	fc26                	sd	s1,56(sp)
    80005302:	f84a                	sd	s2,48(sp)
    80005304:	f44e                	sd	s3,40(sp)
    80005306:	f052                	sd	s4,32(sp)
    80005308:	ec56                	sd	s5,24(sp)
    8000530a:	e85a                	sd	s6,16(sp)
    8000530c:	0880                	addi	s0,sp,80
    8000530e:	84aa                	mv	s1,a0
    80005310:	892e                	mv	s2,a1
    80005312:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	906080e7          	jalr	-1786(ra) # 80001c1a <myproc>
    8000531c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000531e:	8526                	mv	a0,s1
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	8a2080e7          	jalr	-1886(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005328:	2184a703          	lw	a4,536(s1)
    8000532c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005330:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005334:	02f71463          	bne	a4,a5,8000535c <piperead+0x62>
    80005338:	2244a783          	lw	a5,548(s1)
    8000533c:	c385                	beqz	a5,8000535c <piperead+0x62>
    if(pr->killed){
    8000533e:	028a2783          	lw	a5,40(s4)
    80005342:	ebc1                	bnez	a5,800053d2 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005344:	85a6                	mv	a1,s1
    80005346:	854e                	mv	a0,s3
    80005348:	ffffd097          	auipc	ra,0xffffd
    8000534c:	122080e7          	jalr	290(ra) # 8000246a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005350:	2184a703          	lw	a4,536(s1)
    80005354:	21c4a783          	lw	a5,540(s1)
    80005358:	fef700e3          	beq	a4,a5,80005338 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000535c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000535e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005360:	05505363          	blez	s5,800053a6 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005364:	2184a783          	lw	a5,536(s1)
    80005368:	21c4a703          	lw	a4,540(s1)
    8000536c:	02f70d63          	beq	a4,a5,800053a6 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005370:	0017871b          	addiw	a4,a5,1
    80005374:	20e4ac23          	sw	a4,536(s1)
    80005378:	1ff7f793          	andi	a5,a5,511
    8000537c:	97a6                	add	a5,a5,s1
    8000537e:	0187c783          	lbu	a5,24(a5)
    80005382:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005386:	4685                	li	a3,1
    80005388:	fbf40613          	addi	a2,s0,-65
    8000538c:	85ca                	mv	a1,s2
    8000538e:	050a3503          	ld	a0,80(s4)
    80005392:	ffffc097          	auipc	ra,0xffffc
    80005396:	2ac080e7          	jalr	684(ra) # 8000163e <copyout>
    8000539a:	01650663          	beq	a0,s6,800053a6 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000539e:	2985                	addiw	s3,s3,1
    800053a0:	0905                	addi	s2,s2,1
    800053a2:	fd3a91e3          	bne	s5,s3,80005364 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800053a6:	21c48513          	addi	a0,s1,540
    800053aa:	ffffd097          	auipc	ra,0xffffd
    800053ae:	24c080e7          	jalr	588(ra) # 800025f6 <wakeup>
  release(&pi->lock);
    800053b2:	8526                	mv	a0,s1
    800053b4:	ffffc097          	auipc	ra,0xffffc
    800053b8:	8c2080e7          	jalr	-1854(ra) # 80000c76 <release>
  return i;
}
    800053bc:	854e                	mv	a0,s3
    800053be:	60a6                	ld	ra,72(sp)
    800053c0:	6406                	ld	s0,64(sp)
    800053c2:	74e2                	ld	s1,56(sp)
    800053c4:	7942                	ld	s2,48(sp)
    800053c6:	79a2                	ld	s3,40(sp)
    800053c8:	7a02                	ld	s4,32(sp)
    800053ca:	6ae2                	ld	s5,24(sp)
    800053cc:	6b42                	ld	s6,16(sp)
    800053ce:	6161                	addi	sp,sp,80
    800053d0:	8082                	ret
      release(&pi->lock);
    800053d2:	8526                	mv	a0,s1
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	8a2080e7          	jalr	-1886(ra) # 80000c76 <release>
      return -1;
    800053dc:	59fd                	li	s3,-1
    800053de:	bff9                	j	800053bc <piperead+0xc2>

00000000800053e0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053e0:	de010113          	addi	sp,sp,-544
    800053e4:	20113c23          	sd	ra,536(sp)
    800053e8:	20813823          	sd	s0,528(sp)
    800053ec:	20913423          	sd	s1,520(sp)
    800053f0:	21213023          	sd	s2,512(sp)
    800053f4:	ffce                	sd	s3,504(sp)
    800053f6:	fbd2                	sd	s4,496(sp)
    800053f8:	f7d6                	sd	s5,488(sp)
    800053fa:	f3da                	sd	s6,480(sp)
    800053fc:	efde                	sd	s7,472(sp)
    800053fe:	ebe2                	sd	s8,464(sp)
    80005400:	e7e6                	sd	s9,456(sp)
    80005402:	e3ea                	sd	s10,448(sp)
    80005404:	ff6e                	sd	s11,440(sp)
    80005406:	1400                	addi	s0,sp,544
    80005408:	892a                	mv	s2,a0
    8000540a:	dea43423          	sd	a0,-536(s0)
    8000540e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005412:	ffffd097          	auipc	ra,0xffffd
    80005416:	808080e7          	jalr	-2040(ra) # 80001c1a <myproc>
    8000541a:	84aa                	mv	s1,a0

  begin_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	2b0080e7          	jalr	688(ra) # 800046cc <begin_op>

  if((ip = namei(path)) == 0){
    80005424:	854a                	mv	a0,s2
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	d74080e7          	jalr	-652(ra) # 8000419a <namei>
    8000542e:	c93d                	beqz	a0,800054a4 <exec+0xc4>
    80005430:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	5b2080e7          	jalr	1458(ra) # 800039e4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000543a:	04000713          	li	a4,64
    8000543e:	4681                	li	a3,0
    80005440:	e4840613          	addi	a2,s0,-440
    80005444:	4581                	li	a1,0
    80005446:	8556                	mv	a0,s5
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	850080e7          	jalr	-1968(ra) # 80003c98 <readi>
    80005450:	04000793          	li	a5,64
    80005454:	00f51a63          	bne	a0,a5,80005468 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005458:	e4842703          	lw	a4,-440(s0)
    8000545c:	464c47b7          	lui	a5,0x464c4
    80005460:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005464:	04f70663          	beq	a4,a5,800054b0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005468:	8556                	mv	a0,s5
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	7dc080e7          	jalr	2012(ra) # 80003c46 <iunlockput>
    end_op();
    80005472:	fffff097          	auipc	ra,0xfffff
    80005476:	2da080e7          	jalr	730(ra) # 8000474c <end_op>
  }
  return -1;
    8000547a:	557d                	li	a0,-1
}
    8000547c:	21813083          	ld	ra,536(sp)
    80005480:	21013403          	ld	s0,528(sp)
    80005484:	20813483          	ld	s1,520(sp)
    80005488:	20013903          	ld	s2,512(sp)
    8000548c:	79fe                	ld	s3,504(sp)
    8000548e:	7a5e                	ld	s4,496(sp)
    80005490:	7abe                	ld	s5,488(sp)
    80005492:	7b1e                	ld	s6,480(sp)
    80005494:	6bfe                	ld	s7,472(sp)
    80005496:	6c5e                	ld	s8,464(sp)
    80005498:	6cbe                	ld	s9,456(sp)
    8000549a:	6d1e                	ld	s10,448(sp)
    8000549c:	7dfa                	ld	s11,440(sp)
    8000549e:	22010113          	addi	sp,sp,544
    800054a2:	8082                	ret
    end_op();
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	2a8080e7          	jalr	680(ra) # 8000474c <end_op>
    return -1;
    800054ac:	557d                	li	a0,-1
    800054ae:	b7f9                	j	8000547c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800054b0:	8526                	mv	a0,s1
    800054b2:	ffffd097          	auipc	ra,0xffffd
    800054b6:	82c080e7          	jalr	-2004(ra) # 80001cde <proc_pagetable>
    800054ba:	8b2a                	mv	s6,a0
    800054bc:	d555                	beqz	a0,80005468 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054be:	e6842783          	lw	a5,-408(s0)
    800054c2:	e8045703          	lhu	a4,-384(s0)
    800054c6:	c735                	beqz	a4,80005532 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800054c8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054ca:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054ce:	6a05                	lui	s4,0x1
    800054d0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054d4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800054d8:	6d85                	lui	s11,0x1
    800054da:	7d7d                	lui	s10,0xfffff
    800054dc:	ac1d                	j	80005712 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054de:	00003517          	auipc	a0,0x3
    800054e2:	31a50513          	addi	a0,a0,794 # 800087f8 <syscalls+0x2f0>
    800054e6:	ffffb097          	auipc	ra,0xffffb
    800054ea:	044080e7          	jalr	68(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054ee:	874a                	mv	a4,s2
    800054f0:	009c86bb          	addw	a3,s9,s1
    800054f4:	4581                	li	a1,0
    800054f6:	8556                	mv	a0,s5
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	7a0080e7          	jalr	1952(ra) # 80003c98 <readi>
    80005500:	2501                	sext.w	a0,a0
    80005502:	1aa91863          	bne	s2,a0,800056b2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005506:	009d84bb          	addw	s1,s11,s1
    8000550a:	013d09bb          	addw	s3,s10,s3
    8000550e:	1f74f263          	bgeu	s1,s7,800056f2 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005512:	02049593          	slli	a1,s1,0x20
    80005516:	9181                	srli	a1,a1,0x20
    80005518:	95e2                	add	a1,a1,s8
    8000551a:	855a                	mv	a0,s6
    8000551c:	ffffc097          	auipc	ra,0xffffc
    80005520:	b30080e7          	jalr	-1232(ra) # 8000104c <walkaddr>
    80005524:	862a                	mv	a2,a0
    if(pa == 0)
    80005526:	dd45                	beqz	a0,800054de <exec+0xfe>
      n = PGSIZE;
    80005528:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000552a:	fd49f2e3          	bgeu	s3,s4,800054ee <exec+0x10e>
      n = sz - i;
    8000552e:	894e                	mv	s2,s3
    80005530:	bf7d                	j	800054ee <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005532:	4481                	li	s1,0
  iunlockput(ip);
    80005534:	8556                	mv	a0,s5
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	710080e7          	jalr	1808(ra) # 80003c46 <iunlockput>
  end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	20e080e7          	jalr	526(ra) # 8000474c <end_op>
  p = myproc();
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	6d4080e7          	jalr	1748(ra) # 80001c1a <myproc>
    8000554e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005550:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005554:	6785                	lui	a5,0x1
    80005556:	17fd                	addi	a5,a5,-1
    80005558:	94be                	add	s1,s1,a5
    8000555a:	77fd                	lui	a5,0xfffff
    8000555c:	8fe5                	and	a5,a5,s1
    8000555e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005562:	6609                	lui	a2,0x2
    80005564:	963e                	add	a2,a2,a5
    80005566:	85be                	mv	a1,a5
    80005568:	855a                	mv	a0,s6
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	e84080e7          	jalr	-380(ra) # 800013ee <uvmalloc>
    80005572:	8c2a                	mv	s8,a0
  ip = 0;
    80005574:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005576:	12050e63          	beqz	a0,800056b2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000557a:	75f9                	lui	a1,0xffffe
    8000557c:	95aa                	add	a1,a1,a0
    8000557e:	855a                	mv	a0,s6
    80005580:	ffffc097          	auipc	ra,0xffffc
    80005584:	08c080e7          	jalr	140(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80005588:	7afd                	lui	s5,0xfffff
    8000558a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000558c:	df043783          	ld	a5,-528(s0)
    80005590:	6388                	ld	a0,0(a5)
    80005592:	c925                	beqz	a0,80005602 <exec+0x222>
    80005594:	e8840993          	addi	s3,s0,-376
    80005598:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    8000559c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000559e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	8a2080e7          	jalr	-1886(ra) # 80000e42 <strlen>
    800055a8:	0015079b          	addiw	a5,a0,1
    800055ac:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800055b0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800055b4:	13596363          	bltu	s2,s5,800056da <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800055b8:	df043d83          	ld	s11,-528(s0)
    800055bc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800055c0:	8552                	mv	a0,s4
    800055c2:	ffffc097          	auipc	ra,0xffffc
    800055c6:	880080e7          	jalr	-1920(ra) # 80000e42 <strlen>
    800055ca:	0015069b          	addiw	a3,a0,1
    800055ce:	8652                	mv	a2,s4
    800055d0:	85ca                	mv	a1,s2
    800055d2:	855a                	mv	a0,s6
    800055d4:	ffffc097          	auipc	ra,0xffffc
    800055d8:	06a080e7          	jalr	106(ra) # 8000163e <copyout>
    800055dc:	10054363          	bltz	a0,800056e2 <exec+0x302>
    ustack[argc] = sp;
    800055e0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055e4:	0485                	addi	s1,s1,1
    800055e6:	008d8793          	addi	a5,s11,8
    800055ea:	def43823          	sd	a5,-528(s0)
    800055ee:	008db503          	ld	a0,8(s11)
    800055f2:	c911                	beqz	a0,80005606 <exec+0x226>
    if(argc >= MAXARG)
    800055f4:	09a1                	addi	s3,s3,8
    800055f6:	fb3c95e3          	bne	s9,s3,800055a0 <exec+0x1c0>
  sz = sz1;
    800055fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055fe:	4a81                	li	s5,0
    80005600:	a84d                	j	800056b2 <exec+0x2d2>
  sp = sz;
    80005602:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005604:	4481                	li	s1,0
  ustack[argc] = 0;
    80005606:	00349793          	slli	a5,s1,0x3
    8000560a:	f9040713          	addi	a4,s0,-112
    8000560e:	97ba                	add	a5,a5,a4
    80005610:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005614:	00148693          	addi	a3,s1,1
    80005618:	068e                	slli	a3,a3,0x3
    8000561a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000561e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005622:	01597663          	bgeu	s2,s5,8000562e <exec+0x24e>
  sz = sz1;
    80005626:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000562a:	4a81                	li	s5,0
    8000562c:	a059                	j	800056b2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000562e:	e8840613          	addi	a2,s0,-376
    80005632:	85ca                	mv	a1,s2
    80005634:	855a                	mv	a0,s6
    80005636:	ffffc097          	auipc	ra,0xffffc
    8000563a:	008080e7          	jalr	8(ra) # 8000163e <copyout>
    8000563e:	0a054663          	bltz	a0,800056ea <exec+0x30a>
  p->trapframe->a1 = sp;
    80005642:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005646:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000564a:	de843783          	ld	a5,-536(s0)
    8000564e:	0007c703          	lbu	a4,0(a5)
    80005652:	cf11                	beqz	a4,8000566e <exec+0x28e>
    80005654:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005656:	02f00693          	li	a3,47
    8000565a:	a039                	j	80005668 <exec+0x288>
      last = s+1;
    8000565c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005660:	0785                	addi	a5,a5,1
    80005662:	fff7c703          	lbu	a4,-1(a5)
    80005666:	c701                	beqz	a4,8000566e <exec+0x28e>
    if(*s == '/')
    80005668:	fed71ce3          	bne	a4,a3,80005660 <exec+0x280>
    8000566c:	bfc5                	j	8000565c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000566e:	4641                	li	a2,16
    80005670:	de843583          	ld	a1,-536(s0)
    80005674:	158b8513          	addi	a0,s7,344
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	798080e7          	jalr	1944(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005680:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005684:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005688:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000568c:	058bb783          	ld	a5,88(s7)
    80005690:	e6043703          	ld	a4,-416(s0)
    80005694:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005696:	058bb783          	ld	a5,88(s7)
    8000569a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000569e:	85ea                	mv	a1,s10
    800056a0:	ffffc097          	auipc	ra,0xffffc
    800056a4:	6da080e7          	jalr	1754(ra) # 80001d7a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800056a8:	0004851b          	sext.w	a0,s1
    800056ac:	bbc1                	j	8000547c <exec+0x9c>
    800056ae:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800056b2:	df843583          	ld	a1,-520(s0)
    800056b6:	855a                	mv	a0,s6
    800056b8:	ffffc097          	auipc	ra,0xffffc
    800056bc:	6c2080e7          	jalr	1730(ra) # 80001d7a <proc_freepagetable>
  if(ip){
    800056c0:	da0a94e3          	bnez	s5,80005468 <exec+0x88>
  return -1;
    800056c4:	557d                	li	a0,-1
    800056c6:	bb5d                	j	8000547c <exec+0x9c>
    800056c8:	de943c23          	sd	s1,-520(s0)
    800056cc:	b7dd                	j	800056b2 <exec+0x2d2>
    800056ce:	de943c23          	sd	s1,-520(s0)
    800056d2:	b7c5                	j	800056b2 <exec+0x2d2>
    800056d4:	de943c23          	sd	s1,-520(s0)
    800056d8:	bfe9                	j	800056b2 <exec+0x2d2>
  sz = sz1;
    800056da:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056de:	4a81                	li	s5,0
    800056e0:	bfc9                	j	800056b2 <exec+0x2d2>
  sz = sz1;
    800056e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056e6:	4a81                	li	s5,0
    800056e8:	b7e9                	j	800056b2 <exec+0x2d2>
  sz = sz1;
    800056ea:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056ee:	4a81                	li	s5,0
    800056f0:	b7c9                	j	800056b2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056f2:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056f6:	e0843783          	ld	a5,-504(s0)
    800056fa:	0017869b          	addiw	a3,a5,1
    800056fe:	e0d43423          	sd	a3,-504(s0)
    80005702:	e0043783          	ld	a5,-512(s0)
    80005706:	0387879b          	addiw	a5,a5,56
    8000570a:	e8045703          	lhu	a4,-384(s0)
    8000570e:	e2e6d3e3          	bge	a3,a4,80005534 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005712:	2781                	sext.w	a5,a5
    80005714:	e0f43023          	sd	a5,-512(s0)
    80005718:	03800713          	li	a4,56
    8000571c:	86be                	mv	a3,a5
    8000571e:	e1040613          	addi	a2,s0,-496
    80005722:	4581                	li	a1,0
    80005724:	8556                	mv	a0,s5
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	572080e7          	jalr	1394(ra) # 80003c98 <readi>
    8000572e:	03800793          	li	a5,56
    80005732:	f6f51ee3          	bne	a0,a5,800056ae <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005736:	e1042783          	lw	a5,-496(s0)
    8000573a:	4705                	li	a4,1
    8000573c:	fae79de3          	bne	a5,a4,800056f6 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005740:	e3843603          	ld	a2,-456(s0)
    80005744:	e3043783          	ld	a5,-464(s0)
    80005748:	f8f660e3          	bltu	a2,a5,800056c8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000574c:	e2043783          	ld	a5,-480(s0)
    80005750:	963e                	add	a2,a2,a5
    80005752:	f6f66ee3          	bltu	a2,a5,800056ce <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005756:	85a6                	mv	a1,s1
    80005758:	855a                	mv	a0,s6
    8000575a:	ffffc097          	auipc	ra,0xffffc
    8000575e:	c94080e7          	jalr	-876(ra) # 800013ee <uvmalloc>
    80005762:	dea43c23          	sd	a0,-520(s0)
    80005766:	d53d                	beqz	a0,800056d4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005768:	e2043c03          	ld	s8,-480(s0)
    8000576c:	de043783          	ld	a5,-544(s0)
    80005770:	00fc77b3          	and	a5,s8,a5
    80005774:	ff9d                	bnez	a5,800056b2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005776:	e1842c83          	lw	s9,-488(s0)
    8000577a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000577e:	f60b8ae3          	beqz	s7,800056f2 <exec+0x312>
    80005782:	89de                	mv	s3,s7
    80005784:	4481                	li	s1,0
    80005786:	b371                	j	80005512 <exec+0x132>

0000000080005788 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005788:	7179                	addi	sp,sp,-48
    8000578a:	f406                	sd	ra,40(sp)
    8000578c:	f022                	sd	s0,32(sp)
    8000578e:	ec26                	sd	s1,24(sp)
    80005790:	e84a                	sd	s2,16(sp)
    80005792:	1800                	addi	s0,sp,48
    80005794:	892e                	mv	s2,a1
    80005796:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005798:	fdc40593          	addi	a1,s0,-36
    8000579c:	ffffd097          	auipc	ra,0xffffd
    800057a0:	6d6080e7          	jalr	1750(ra) # 80002e72 <argint>
    800057a4:	04054063          	bltz	a0,800057e4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800057a8:	fdc42703          	lw	a4,-36(s0)
    800057ac:	47bd                	li	a5,15
    800057ae:	02e7ed63          	bltu	a5,a4,800057e8 <argfd+0x60>
    800057b2:	ffffc097          	auipc	ra,0xffffc
    800057b6:	468080e7          	jalr	1128(ra) # 80001c1a <myproc>
    800057ba:	fdc42703          	lw	a4,-36(s0)
    800057be:	01a70793          	addi	a5,a4,26
    800057c2:	078e                	slli	a5,a5,0x3
    800057c4:	953e                	add	a0,a0,a5
    800057c6:	611c                	ld	a5,0(a0)
    800057c8:	c395                	beqz	a5,800057ec <argfd+0x64>
    return -1;
  if(pfd)
    800057ca:	00090463          	beqz	s2,800057d2 <argfd+0x4a>
    *pfd = fd;
    800057ce:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057d2:	4501                	li	a0,0
  if(pf)
    800057d4:	c091                	beqz	s1,800057d8 <argfd+0x50>
    *pf = f;
    800057d6:	e09c                	sd	a5,0(s1)
}
    800057d8:	70a2                	ld	ra,40(sp)
    800057da:	7402                	ld	s0,32(sp)
    800057dc:	64e2                	ld	s1,24(sp)
    800057de:	6942                	ld	s2,16(sp)
    800057e0:	6145                	addi	sp,sp,48
    800057e2:	8082                	ret
    return -1;
    800057e4:	557d                	li	a0,-1
    800057e6:	bfcd                	j	800057d8 <argfd+0x50>
    return -1;
    800057e8:	557d                	li	a0,-1
    800057ea:	b7fd                	j	800057d8 <argfd+0x50>
    800057ec:	557d                	li	a0,-1
    800057ee:	b7ed                	j	800057d8 <argfd+0x50>

00000000800057f0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057f0:	1101                	addi	sp,sp,-32
    800057f2:	ec06                	sd	ra,24(sp)
    800057f4:	e822                	sd	s0,16(sp)
    800057f6:	e426                	sd	s1,8(sp)
    800057f8:	1000                	addi	s0,sp,32
    800057fa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057fc:	ffffc097          	auipc	ra,0xffffc
    80005800:	41e080e7          	jalr	1054(ra) # 80001c1a <myproc>
    80005804:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005806:	0d050793          	addi	a5,a0,208
    8000580a:	4501                	li	a0,0
    8000580c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000580e:	6398                	ld	a4,0(a5)
    80005810:	cb19                	beqz	a4,80005826 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005812:	2505                	addiw	a0,a0,1
    80005814:	07a1                	addi	a5,a5,8
    80005816:	fed51ce3          	bne	a0,a3,8000580e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000581a:	557d                	li	a0,-1
}
    8000581c:	60e2                	ld	ra,24(sp)
    8000581e:	6442                	ld	s0,16(sp)
    80005820:	64a2                	ld	s1,8(sp)
    80005822:	6105                	addi	sp,sp,32
    80005824:	8082                	ret
      p->ofile[fd] = f;
    80005826:	01a50793          	addi	a5,a0,26
    8000582a:	078e                	slli	a5,a5,0x3
    8000582c:	963e                	add	a2,a2,a5
    8000582e:	e204                	sd	s1,0(a2)
      return fd;
    80005830:	b7f5                	j	8000581c <fdalloc+0x2c>

0000000080005832 <sys_dup>:

uint64
sys_dup(void)
{
    80005832:	7179                	addi	sp,sp,-48
    80005834:	f406                	sd	ra,40(sp)
    80005836:	f022                	sd	s0,32(sp)
    80005838:	ec26                	sd	s1,24(sp)
    8000583a:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    8000583c:	fd840613          	addi	a2,s0,-40
    80005840:	4581                	li	a1,0
    80005842:	4501                	li	a0,0
    80005844:	00000097          	auipc	ra,0x0
    80005848:	f44080e7          	jalr	-188(ra) # 80005788 <argfd>
    return -1;
    8000584c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000584e:	02054363          	bltz	a0,80005874 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005852:	fd843503          	ld	a0,-40(s0)
    80005856:	00000097          	auipc	ra,0x0
    8000585a:	f9a080e7          	jalr	-102(ra) # 800057f0 <fdalloc>
    8000585e:	84aa                	mv	s1,a0
    return -1;
    80005860:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005862:	00054963          	bltz	a0,80005874 <sys_dup+0x42>
  filedup(f);
    80005866:	fd843503          	ld	a0,-40(s0)
    8000586a:	fffff097          	auipc	ra,0xfffff
    8000586e:	2dc080e7          	jalr	732(ra) # 80004b46 <filedup>
  return fd;
    80005872:	87a6                	mv	a5,s1
}
    80005874:	853e                	mv	a0,a5
    80005876:	70a2                	ld	ra,40(sp)
    80005878:	7402                	ld	s0,32(sp)
    8000587a:	64e2                	ld	s1,24(sp)
    8000587c:	6145                	addi	sp,sp,48
    8000587e:	8082                	ret

0000000080005880 <sys_read>:

uint64
sys_read(void)
{
    80005880:	7179                	addi	sp,sp,-48
    80005882:	f406                	sd	ra,40(sp)
    80005884:	f022                	sd	s0,32(sp)
    80005886:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005888:	fe840613          	addi	a2,s0,-24
    8000588c:	4581                	li	a1,0
    8000588e:	4501                	li	a0,0
    80005890:	00000097          	auipc	ra,0x0
    80005894:	ef8080e7          	jalr	-264(ra) # 80005788 <argfd>
    return -1;
    80005898:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000589a:	04054163          	bltz	a0,800058dc <sys_read+0x5c>
    8000589e:	fe440593          	addi	a1,s0,-28
    800058a2:	4509                	li	a0,2
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	5ce080e7          	jalr	1486(ra) # 80002e72 <argint>
    return -1;
    800058ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ae:	02054763          	bltz	a0,800058dc <sys_read+0x5c>
    800058b2:	fd840593          	addi	a1,s0,-40
    800058b6:	4505                	li	a0,1
    800058b8:	ffffd097          	auipc	ra,0xffffd
    800058bc:	5dc080e7          	jalr	1500(ra) # 80002e94 <argaddr>
    return -1;
    800058c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c2:	00054d63          	bltz	a0,800058dc <sys_read+0x5c>
  return fileread(f, p, n);
    800058c6:	fe442603          	lw	a2,-28(s0)
    800058ca:	fd843583          	ld	a1,-40(s0)
    800058ce:	fe843503          	ld	a0,-24(s0)
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	400080e7          	jalr	1024(ra) # 80004cd2 <fileread>
    800058da:	87aa                	mv	a5,a0
}
    800058dc:	853e                	mv	a0,a5
    800058de:	70a2                	ld	ra,40(sp)
    800058e0:	7402                	ld	s0,32(sp)
    800058e2:	6145                	addi	sp,sp,48
    800058e4:	8082                	ret

00000000800058e6 <sys_write>:

uint64
sys_write(void)
{
    800058e6:	7179                	addi	sp,sp,-48
    800058e8:	f406                	sd	ra,40(sp)
    800058ea:	f022                	sd	s0,32(sp)
    800058ec:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ee:	fe840613          	addi	a2,s0,-24
    800058f2:	4581                	li	a1,0
    800058f4:	4501                	li	a0,0
    800058f6:	00000097          	auipc	ra,0x0
    800058fa:	e92080e7          	jalr	-366(ra) # 80005788 <argfd>
    return -1;
    800058fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005900:	04054163          	bltz	a0,80005942 <sys_write+0x5c>
    80005904:	fe440593          	addi	a1,s0,-28
    80005908:	4509                	li	a0,2
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	568080e7          	jalr	1384(ra) # 80002e72 <argint>
    return -1;
    80005912:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005914:	02054763          	bltz	a0,80005942 <sys_write+0x5c>
    80005918:	fd840593          	addi	a1,s0,-40
    8000591c:	4505                	li	a0,1
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	576080e7          	jalr	1398(ra) # 80002e94 <argaddr>
    return -1;
    80005926:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005928:	00054d63          	bltz	a0,80005942 <sys_write+0x5c>

  return filewrite(f, p, n);
    8000592c:	fe442603          	lw	a2,-28(s0)
    80005930:	fd843583          	ld	a1,-40(s0)
    80005934:	fe843503          	ld	a0,-24(s0)
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	45c080e7          	jalr	1116(ra) # 80004d94 <filewrite>
    80005940:	87aa                	mv	a5,a0
}
    80005942:	853e                	mv	a0,a5
    80005944:	70a2                	ld	ra,40(sp)
    80005946:	7402                	ld	s0,32(sp)
    80005948:	6145                	addi	sp,sp,48
    8000594a:	8082                	ret

000000008000594c <sys_close>:

uint64
sys_close(void)
{
    8000594c:	1101                	addi	sp,sp,-32
    8000594e:	ec06                	sd	ra,24(sp)
    80005950:	e822                	sd	s0,16(sp)
    80005952:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005954:	fe040613          	addi	a2,s0,-32
    80005958:	fec40593          	addi	a1,s0,-20
    8000595c:	4501                	li	a0,0
    8000595e:	00000097          	auipc	ra,0x0
    80005962:	e2a080e7          	jalr	-470(ra) # 80005788 <argfd>
    return -1;
    80005966:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005968:	02054463          	bltz	a0,80005990 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000596c:	ffffc097          	auipc	ra,0xffffc
    80005970:	2ae080e7          	jalr	686(ra) # 80001c1a <myproc>
    80005974:	fec42783          	lw	a5,-20(s0)
    80005978:	07e9                	addi	a5,a5,26
    8000597a:	078e                	slli	a5,a5,0x3
    8000597c:	97aa                	add	a5,a5,a0
    8000597e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005982:	fe043503          	ld	a0,-32(s0)
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	212080e7          	jalr	530(ra) # 80004b98 <fileclose>
  return 0;
    8000598e:	4781                	li	a5,0
}
    80005990:	853e                	mv	a0,a5
    80005992:	60e2                	ld	ra,24(sp)
    80005994:	6442                	ld	s0,16(sp)
    80005996:	6105                	addi	sp,sp,32
    80005998:	8082                	ret

000000008000599a <sys_fstat>:

uint64
sys_fstat(void)
{
    8000599a:	1101                	addi	sp,sp,-32
    8000599c:	ec06                	sd	ra,24(sp)
    8000599e:	e822                	sd	s0,16(sp)
    800059a0:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059a2:	fe840613          	addi	a2,s0,-24
    800059a6:	4581                	li	a1,0
    800059a8:	4501                	li	a0,0
    800059aa:	00000097          	auipc	ra,0x0
    800059ae:	dde080e7          	jalr	-546(ra) # 80005788 <argfd>
    return -1;
    800059b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059b4:	02054563          	bltz	a0,800059de <sys_fstat+0x44>
    800059b8:	fe040593          	addi	a1,s0,-32
    800059bc:	4505                	li	a0,1
    800059be:	ffffd097          	auipc	ra,0xffffd
    800059c2:	4d6080e7          	jalr	1238(ra) # 80002e94 <argaddr>
    return -1;
    800059c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800059c8:	00054b63          	bltz	a0,800059de <sys_fstat+0x44>
  return filestat(f, st);
    800059cc:	fe043583          	ld	a1,-32(s0)
    800059d0:	fe843503          	ld	a0,-24(s0)
    800059d4:	fffff097          	auipc	ra,0xfffff
    800059d8:	28c080e7          	jalr	652(ra) # 80004c60 <filestat>
    800059dc:	87aa                	mv	a5,a0
}
    800059de:	853e                	mv	a0,a5
    800059e0:	60e2                	ld	ra,24(sp)
    800059e2:	6442                	ld	s0,16(sp)
    800059e4:	6105                	addi	sp,sp,32
    800059e6:	8082                	ret

00000000800059e8 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    800059e8:	7169                	addi	sp,sp,-304
    800059ea:	f606                	sd	ra,296(sp)
    800059ec:	f222                	sd	s0,288(sp)
    800059ee:	ee26                	sd	s1,280(sp)
    800059f0:	ea4a                	sd	s2,272(sp)
    800059f2:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059f4:	08000613          	li	a2,128
    800059f8:	ed040593          	addi	a1,s0,-304
    800059fc:	4501                	li	a0,0
    800059fe:	ffffd097          	auipc	ra,0xffffd
    80005a02:	4b8080e7          	jalr	1208(ra) # 80002eb6 <argstr>
    return -1;
    80005a06:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a08:	10054e63          	bltz	a0,80005b24 <sys_link+0x13c>
    80005a0c:	08000613          	li	a2,128
    80005a10:	f5040593          	addi	a1,s0,-176
    80005a14:	4505                	li	a0,1
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	4a0080e7          	jalr	1184(ra) # 80002eb6 <argstr>
    return -1;
    80005a1e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a20:	10054263          	bltz	a0,80005b24 <sys_link+0x13c>

  begin_op();
    80005a24:	fffff097          	auipc	ra,0xfffff
    80005a28:	ca8080e7          	jalr	-856(ra) # 800046cc <begin_op>
  if((ip = namei(old)) == 0){
    80005a2c:	ed040513          	addi	a0,s0,-304
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	76a080e7          	jalr	1898(ra) # 8000419a <namei>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	c551                	beqz	a0,80005ac6 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	fa8080e7          	jalr	-88(ra) # 800039e4 <ilock>
  if(ip->type == T_DIR){
    80005a44:	04449703          	lh	a4,68(s1)
    80005a48:	4785                	li	a5,1
    80005a4a:	08f70463          	beq	a4,a5,80005ad2 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005a4e:	04a4d783          	lhu	a5,74(s1)
    80005a52:	2785                	addiw	a5,a5,1
    80005a54:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	ec0080e7          	jalr	-320(ra) # 8000391a <iupdate>
  iunlock(ip);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	042080e7          	jalr	66(ra) # 80003aa6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005a6c:	fd040593          	addi	a1,s0,-48
    80005a70:	f5040513          	addi	a0,s0,-176
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	744080e7          	jalr	1860(ra) # 800041b8 <nameiparent>
    80005a7c:	892a                	mv	s2,a0
    80005a7e:	c935                	beqz	a0,80005af2 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	f64080e7          	jalr	-156(ra) # 800039e4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a88:	00092703          	lw	a4,0(s2)
    80005a8c:	409c                	lw	a5,0(s1)
    80005a8e:	04f71d63          	bne	a4,a5,80005ae8 <sys_link+0x100>
    80005a92:	40d0                	lw	a2,4(s1)
    80005a94:	fd040593          	addi	a1,s0,-48
    80005a98:	854a                	mv	a0,s2
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	63e080e7          	jalr	1598(ra) # 800040d8 <dirlink>
    80005aa2:	04054363          	bltz	a0,80005ae8 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005aa6:	854a                	mv	a0,s2
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	19e080e7          	jalr	414(ra) # 80003c46 <iunlockput>
  iput(ip);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	0ec080e7          	jalr	236(ra) # 80003b9e <iput>

  end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	c92080e7          	jalr	-878(ra) # 8000474c <end_op>

  return 0;
    80005ac2:	4781                	li	a5,0
    80005ac4:	a085                	j	80005b24 <sys_link+0x13c>
    end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	c86080e7          	jalr	-890(ra) # 8000474c <end_op>
    return -1;
    80005ace:	57fd                	li	a5,-1
    80005ad0:	a891                	j	80005b24 <sys_link+0x13c>
    iunlockput(ip);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	172080e7          	jalr	370(ra) # 80003c46 <iunlockput>
    end_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	c70080e7          	jalr	-912(ra) # 8000474c <end_op>
    return -1;
    80005ae4:	57fd                	li	a5,-1
    80005ae6:	a83d                	j	80005b24 <sys_link+0x13c>
    iunlockput(dp);
    80005ae8:	854a                	mv	a0,s2
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	15c080e7          	jalr	348(ra) # 80003c46 <iunlockput>

bad:
  ilock(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	ef0080e7          	jalr	-272(ra) # 800039e4 <ilock>
  ip->nlink--;
    80005afc:	04a4d783          	lhu	a5,74(s1)
    80005b00:	37fd                	addiw	a5,a5,-1
    80005b02:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b06:	8526                	mv	a0,s1
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	e12080e7          	jalr	-494(ra) # 8000391a <iupdate>
  iunlockput(ip);
    80005b10:	8526                	mv	a0,s1
    80005b12:	ffffe097          	auipc	ra,0xffffe
    80005b16:	134080e7          	jalr	308(ra) # 80003c46 <iunlockput>
  end_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	c32080e7          	jalr	-974(ra) # 8000474c <end_op>
  return -1;
    80005b22:	57fd                	li	a5,-1
}
    80005b24:	853e                	mv	a0,a5
    80005b26:	70b2                	ld	ra,296(sp)
    80005b28:	7412                	ld	s0,288(sp)
    80005b2a:	64f2                	ld	s1,280(sp)
    80005b2c:	6952                	ld	s2,272(sp)
    80005b2e:	6155                	addi	sp,sp,304
    80005b30:	8082                	ret

0000000080005b32 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b32:	4578                	lw	a4,76(a0)
    80005b34:	02000793          	li	a5,32
    80005b38:	04e7fa63          	bgeu	a5,a4,80005b8c <isdirempty+0x5a>
{
    80005b3c:	7179                	addi	sp,sp,-48
    80005b3e:	f406                	sd	ra,40(sp)
    80005b40:	f022                	sd	s0,32(sp)
    80005b42:	ec26                	sd	s1,24(sp)
    80005b44:	e84a                	sd	s2,16(sp)
    80005b46:	1800                	addi	s0,sp,48
    80005b48:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b4a:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b4e:	4741                	li	a4,16
    80005b50:	86a6                	mv	a3,s1
    80005b52:	fd040613          	addi	a2,s0,-48
    80005b56:	4581                	li	a1,0
    80005b58:	854a                	mv	a0,s2
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	13e080e7          	jalr	318(ra) # 80003c98 <readi>
    80005b62:	47c1                	li	a5,16
    80005b64:	00f51c63          	bne	a0,a5,80005b7c <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005b68:	fd045783          	lhu	a5,-48(s0)
    80005b6c:	e395                	bnez	a5,80005b90 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b6e:	24c1                	addiw	s1,s1,16
    80005b70:	04c92783          	lw	a5,76(s2)
    80005b74:	fcf4ede3          	bltu	s1,a5,80005b4e <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005b78:	4505                	li	a0,1
    80005b7a:	a821                	j	80005b92 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005b7c:	00003517          	auipc	a0,0x3
    80005b80:	c9c50513          	addi	a0,a0,-868 # 80008818 <syscalls+0x310>
    80005b84:	ffffb097          	auipc	ra,0xffffb
    80005b88:	9a6080e7          	jalr	-1626(ra) # 8000052a <panic>
  return 1;
    80005b8c:	4505                	li	a0,1
}
    80005b8e:	8082                	ret
      return 0;
    80005b90:	4501                	li	a0,0
}
    80005b92:	70a2                	ld	ra,40(sp)
    80005b94:	7402                	ld	s0,32(sp)
    80005b96:	64e2                	ld	s1,24(sp)
    80005b98:	6942                	ld	s2,16(sp)
    80005b9a:	6145                	addi	sp,sp,48
    80005b9c:	8082                	ret

0000000080005b9e <sys_unlink>:

uint64
sys_unlink(void)
{
    80005b9e:	7155                	addi	sp,sp,-208
    80005ba0:	e586                	sd	ra,200(sp)
    80005ba2:	e1a2                	sd	s0,192(sp)
    80005ba4:	fd26                	sd	s1,184(sp)
    80005ba6:	f94a                	sd	s2,176(sp)
    80005ba8:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005baa:	08000613          	li	a2,128
    80005bae:	f4040593          	addi	a1,s0,-192
    80005bb2:	4501                	li	a0,0
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	302080e7          	jalr	770(ra) # 80002eb6 <argstr>
    80005bbc:	16054363          	bltz	a0,80005d22 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	b0c080e7          	jalr	-1268(ra) # 800046cc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bc8:	fc040593          	addi	a1,s0,-64
    80005bcc:	f4040513          	addi	a0,s0,-192
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	5e8080e7          	jalr	1512(ra) # 800041b8 <nameiparent>
    80005bd8:	84aa                	mv	s1,a0
    80005bda:	c961                	beqz	a0,80005caa <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	e08080e7          	jalr	-504(ra) # 800039e4 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005be4:	00003597          	auipc	a1,0x3
    80005be8:	b1458593          	addi	a1,a1,-1260 # 800086f8 <syscalls+0x1f0>
    80005bec:	fc040513          	addi	a0,s0,-64
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	2be080e7          	jalr	702(ra) # 80003eae <namecmp>
    80005bf8:	c175                	beqz	a0,80005cdc <sys_unlink+0x13e>
    80005bfa:	00003597          	auipc	a1,0x3
    80005bfe:	b0658593          	addi	a1,a1,-1274 # 80008700 <syscalls+0x1f8>
    80005c02:	fc040513          	addi	a0,s0,-64
    80005c06:	ffffe097          	auipc	ra,0xffffe
    80005c0a:	2a8080e7          	jalr	680(ra) # 80003eae <namecmp>
    80005c0e:	c579                	beqz	a0,80005cdc <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c10:	f3c40613          	addi	a2,s0,-196
    80005c14:	fc040593          	addi	a1,s0,-64
    80005c18:	8526                	mv	a0,s1
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	2ae080e7          	jalr	686(ra) # 80003ec8 <dirlookup>
    80005c22:	892a                	mv	s2,a0
    80005c24:	cd45                	beqz	a0,80005cdc <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005c26:	ffffe097          	auipc	ra,0xffffe
    80005c2a:	dbe080e7          	jalr	-578(ra) # 800039e4 <ilock>

  if(ip->nlink < 1)
    80005c2e:	04a91783          	lh	a5,74(s2)
    80005c32:	08f05263          	blez	a5,80005cb6 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c36:	04491703          	lh	a4,68(s2)
    80005c3a:	4785                	li	a5,1
    80005c3c:	08f70563          	beq	a4,a5,80005cc6 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005c40:	4641                	li	a2,16
    80005c42:	4581                	li	a1,0
    80005c44:	fd040513          	addi	a0,s0,-48
    80005c48:	ffffb097          	auipc	ra,0xffffb
    80005c4c:	076080e7          	jalr	118(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c50:	4741                	li	a4,16
    80005c52:	f3c42683          	lw	a3,-196(s0)
    80005c56:	fd040613          	addi	a2,s0,-48
    80005c5a:	4581                	li	a1,0
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	132080e7          	jalr	306(ra) # 80003d90 <writei>
    80005c66:	47c1                	li	a5,16
    80005c68:	08f51a63          	bne	a0,a5,80005cfc <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005c6c:	04491703          	lh	a4,68(s2)
    80005c70:	4785                	li	a5,1
    80005c72:	08f70d63          	beq	a4,a5,80005d0c <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	fce080e7          	jalr	-50(ra) # 80003c46 <iunlockput>

  ip->nlink--;
    80005c80:	04a95783          	lhu	a5,74(s2)
    80005c84:	37fd                	addiw	a5,a5,-1
    80005c86:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c8a:	854a                	mv	a0,s2
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	c8e080e7          	jalr	-882(ra) # 8000391a <iupdate>
  iunlockput(ip);
    80005c94:	854a                	mv	a0,s2
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	fb0080e7          	jalr	-80(ra) # 80003c46 <iunlockput>

  end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	aae080e7          	jalr	-1362(ra) # 8000474c <end_op>

  return 0;
    80005ca6:	4501                	li	a0,0
    80005ca8:	a0a1                	j	80005cf0 <sys_unlink+0x152>
    end_op();
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	aa2080e7          	jalr	-1374(ra) # 8000474c <end_op>
    return -1;
    80005cb2:	557d                	li	a0,-1
    80005cb4:	a835                	j	80005cf0 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005cb6:	00003517          	auipc	a0,0x3
    80005cba:	a5250513          	addi	a0,a0,-1454 # 80008708 <syscalls+0x200>
    80005cbe:	ffffb097          	auipc	ra,0xffffb
    80005cc2:	86c080e7          	jalr	-1940(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	00000097          	auipc	ra,0x0
    80005ccc:	e6a080e7          	jalr	-406(ra) # 80005b32 <isdirempty>
    80005cd0:	f925                	bnez	a0,80005c40 <sys_unlink+0xa2>
    iunlockput(ip);
    80005cd2:	854a                	mv	a0,s2
    80005cd4:	ffffe097          	auipc	ra,0xffffe
    80005cd8:	f72080e7          	jalr	-142(ra) # 80003c46 <iunlockput>

bad:
  iunlockput(dp);
    80005cdc:	8526                	mv	a0,s1
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	f68080e7          	jalr	-152(ra) # 80003c46 <iunlockput>
  end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	a66080e7          	jalr	-1434(ra) # 8000474c <end_op>
  return -1;
    80005cee:	557d                	li	a0,-1
}
    80005cf0:	60ae                	ld	ra,200(sp)
    80005cf2:	640e                	ld	s0,192(sp)
    80005cf4:	74ea                	ld	s1,184(sp)
    80005cf6:	794a                	ld	s2,176(sp)
    80005cf8:	6169                	addi	sp,sp,208
    80005cfa:	8082                	ret
    panic("unlink: writei");
    80005cfc:	00003517          	auipc	a0,0x3
    80005d00:	a2450513          	addi	a0,a0,-1500 # 80008720 <syscalls+0x218>
    80005d04:	ffffb097          	auipc	ra,0xffffb
    80005d08:	826080e7          	jalr	-2010(ra) # 8000052a <panic>
    dp->nlink--;
    80005d0c:	04a4d783          	lhu	a5,74(s1)
    80005d10:	37fd                	addiw	a5,a5,-1
    80005d12:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d16:	8526                	mv	a0,s1
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	c02080e7          	jalr	-1022(ra) # 8000391a <iupdate>
    80005d20:	bf99                	j	80005c76 <sys_unlink+0xd8>
    return -1;
    80005d22:	557d                	li	a0,-1
    80005d24:	b7f1                	j	80005cf0 <sys_unlink+0x152>

0000000080005d26 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005d26:	715d                	addi	sp,sp,-80
    80005d28:	e486                	sd	ra,72(sp)
    80005d2a:	e0a2                	sd	s0,64(sp)
    80005d2c:	fc26                	sd	s1,56(sp)
    80005d2e:	f84a                	sd	s2,48(sp)
    80005d30:	f44e                	sd	s3,40(sp)
    80005d32:	f052                	sd	s4,32(sp)
    80005d34:	ec56                	sd	s5,24(sp)
    80005d36:	0880                	addi	s0,sp,80
    80005d38:	89ae                	mv	s3,a1
    80005d3a:	8ab2                	mv	s5,a2
    80005d3c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d3e:	fb040593          	addi	a1,s0,-80
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	476080e7          	jalr	1142(ra) # 800041b8 <nameiparent>
    80005d4a:	892a                	mv	s2,a0
    80005d4c:	12050e63          	beqz	a0,80005e88 <create+0x162>
    return 0;

  ilock(dp);
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	c94080e7          	jalr	-876(ra) # 800039e4 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d58:	4601                	li	a2,0
    80005d5a:	fb040593          	addi	a1,s0,-80
    80005d5e:	854a                	mv	a0,s2
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	168080e7          	jalr	360(ra) # 80003ec8 <dirlookup>
    80005d68:	84aa                	mv	s1,a0
    80005d6a:	c921                	beqz	a0,80005dba <create+0x94>
    iunlockput(dp);
    80005d6c:	854a                	mv	a0,s2
    80005d6e:	ffffe097          	auipc	ra,0xffffe
    80005d72:	ed8080e7          	jalr	-296(ra) # 80003c46 <iunlockput>
    ilock(ip);
    80005d76:	8526                	mv	a0,s1
    80005d78:	ffffe097          	auipc	ra,0xffffe
    80005d7c:	c6c080e7          	jalr	-916(ra) # 800039e4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d80:	2981                	sext.w	s3,s3
    80005d82:	4789                	li	a5,2
    80005d84:	02f99463          	bne	s3,a5,80005dac <create+0x86>
    80005d88:	0444d783          	lhu	a5,68(s1)
    80005d8c:	37f9                	addiw	a5,a5,-2
    80005d8e:	17c2                	slli	a5,a5,0x30
    80005d90:	93c1                	srli	a5,a5,0x30
    80005d92:	4705                	li	a4,1
    80005d94:	00f76c63          	bltu	a4,a5,80005dac <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d98:	8526                	mv	a0,s1
    80005d9a:	60a6                	ld	ra,72(sp)
    80005d9c:	6406                	ld	s0,64(sp)
    80005d9e:	74e2                	ld	s1,56(sp)
    80005da0:	7942                	ld	s2,48(sp)
    80005da2:	79a2                	ld	s3,40(sp)
    80005da4:	7a02                	ld	s4,32(sp)
    80005da6:	6ae2                	ld	s5,24(sp)
    80005da8:	6161                	addi	sp,sp,80
    80005daa:	8082                	ret
    iunlockput(ip);
    80005dac:	8526                	mv	a0,s1
    80005dae:	ffffe097          	auipc	ra,0xffffe
    80005db2:	e98080e7          	jalr	-360(ra) # 80003c46 <iunlockput>
    return 0;
    80005db6:	4481                	li	s1,0
    80005db8:	b7c5                	j	80005d98 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005dba:	85ce                	mv	a1,s3
    80005dbc:	00092503          	lw	a0,0(s2)
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	a8c080e7          	jalr	-1396(ra) # 8000384c <ialloc>
    80005dc8:	84aa                	mv	s1,a0
    80005dca:	c521                	beqz	a0,80005e12 <create+0xec>
  ilock(ip);
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	c18080e7          	jalr	-1000(ra) # 800039e4 <ilock>
  ip->major = major;
    80005dd4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005dd8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005ddc:	4a05                	li	s4,1
    80005dde:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005de2:	8526                	mv	a0,s1
    80005de4:	ffffe097          	auipc	ra,0xffffe
    80005de8:	b36080e7          	jalr	-1226(ra) # 8000391a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005dec:	2981                	sext.w	s3,s3
    80005dee:	03498a63          	beq	s3,s4,80005e22 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005df2:	40d0                	lw	a2,4(s1)
    80005df4:	fb040593          	addi	a1,s0,-80
    80005df8:	854a                	mv	a0,s2
    80005dfa:	ffffe097          	auipc	ra,0xffffe
    80005dfe:	2de080e7          	jalr	734(ra) # 800040d8 <dirlink>
    80005e02:	06054b63          	bltz	a0,80005e78 <create+0x152>
  iunlockput(dp);
    80005e06:	854a                	mv	a0,s2
    80005e08:	ffffe097          	auipc	ra,0xffffe
    80005e0c:	e3e080e7          	jalr	-450(ra) # 80003c46 <iunlockput>
  return ip;
    80005e10:	b761                	j	80005d98 <create+0x72>
    panic("create: ialloc");
    80005e12:	00003517          	auipc	a0,0x3
    80005e16:	a1e50513          	addi	a0,a0,-1506 # 80008830 <syscalls+0x328>
    80005e1a:	ffffa097          	auipc	ra,0xffffa
    80005e1e:	710080e7          	jalr	1808(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005e22:	04a95783          	lhu	a5,74(s2)
    80005e26:	2785                	addiw	a5,a5,1
    80005e28:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005e2c:	854a                	mv	a0,s2
    80005e2e:	ffffe097          	auipc	ra,0xffffe
    80005e32:	aec080e7          	jalr	-1300(ra) # 8000391a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e36:	40d0                	lw	a2,4(s1)
    80005e38:	00003597          	auipc	a1,0x3
    80005e3c:	8c058593          	addi	a1,a1,-1856 # 800086f8 <syscalls+0x1f0>
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	296080e7          	jalr	662(ra) # 800040d8 <dirlink>
    80005e4a:	00054f63          	bltz	a0,80005e68 <create+0x142>
    80005e4e:	00492603          	lw	a2,4(s2)
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	8ae58593          	addi	a1,a1,-1874 # 80008700 <syscalls+0x1f8>
    80005e5a:	8526                	mv	a0,s1
    80005e5c:	ffffe097          	auipc	ra,0xffffe
    80005e60:	27c080e7          	jalr	636(ra) # 800040d8 <dirlink>
    80005e64:	f80557e3          	bgez	a0,80005df2 <create+0xcc>
      panic("create dots");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	9d850513          	addi	a0,a0,-1576 # 80008840 <syscalls+0x338>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6ba080e7          	jalr	1722(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	9d850513          	addi	a0,a0,-1576 # 80008850 <syscalls+0x348>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6aa080e7          	jalr	1706(ra) # 8000052a <panic>
    return 0;
    80005e88:	84aa                	mv	s1,a0
    80005e8a:	b739                	j	80005d98 <create+0x72>

0000000080005e8c <sys_open>:

uint64
sys_open(void)
{
    80005e8c:	7131                	addi	sp,sp,-192
    80005e8e:	fd06                	sd	ra,184(sp)
    80005e90:	f922                	sd	s0,176(sp)
    80005e92:	f526                	sd	s1,168(sp)
    80005e94:	f14a                	sd	s2,160(sp)
    80005e96:	ed4e                	sd	s3,152(sp)
    80005e98:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e9a:	08000613          	li	a2,128
    80005e9e:	f5040593          	addi	a1,s0,-176
    80005ea2:	4501                	li	a0,0
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	012080e7          	jalr	18(ra) # 80002eb6 <argstr>
    return -1;
    80005eac:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005eae:	0c054163          	bltz	a0,80005f70 <sys_open+0xe4>
    80005eb2:	f4c40593          	addi	a1,s0,-180
    80005eb6:	4505                	li	a0,1
    80005eb8:	ffffd097          	auipc	ra,0xffffd
    80005ebc:	fba080e7          	jalr	-70(ra) # 80002e72 <argint>
    80005ec0:	0a054863          	bltz	a0,80005f70 <sys_open+0xe4>

  begin_op();
    80005ec4:	fffff097          	auipc	ra,0xfffff
    80005ec8:	808080e7          	jalr	-2040(ra) # 800046cc <begin_op>

  if(omode & O_CREATE){
    80005ecc:	f4c42783          	lw	a5,-180(s0)
    80005ed0:	2007f793          	andi	a5,a5,512
    80005ed4:	cbdd                	beqz	a5,80005f8a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ed6:	4681                	li	a3,0
    80005ed8:	4601                	li	a2,0
    80005eda:	4589                	li	a1,2
    80005edc:	f5040513          	addi	a0,s0,-176
    80005ee0:	00000097          	auipc	ra,0x0
    80005ee4:	e46080e7          	jalr	-442(ra) # 80005d26 <create>
    80005ee8:	892a                	mv	s2,a0
    if(ip == 0){
    80005eea:	c959                	beqz	a0,80005f80 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005eec:	04491703          	lh	a4,68(s2)
    80005ef0:	478d                	li	a5,3
    80005ef2:	00f71763          	bne	a4,a5,80005f00 <sys_open+0x74>
    80005ef6:	04695703          	lhu	a4,70(s2)
    80005efa:	47a5                	li	a5,9
    80005efc:	0ce7ec63          	bltu	a5,a4,80005fd4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005f00:	fffff097          	auipc	ra,0xfffff
    80005f04:	bdc080e7          	jalr	-1060(ra) # 80004adc <filealloc>
    80005f08:	89aa                	mv	s3,a0
    80005f0a:	10050263          	beqz	a0,8000600e <sys_open+0x182>
    80005f0e:	00000097          	auipc	ra,0x0
    80005f12:	8e2080e7          	jalr	-1822(ra) # 800057f0 <fdalloc>
    80005f16:	84aa                	mv	s1,a0
    80005f18:	0e054663          	bltz	a0,80006004 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005f1c:	04491703          	lh	a4,68(s2)
    80005f20:	478d                	li	a5,3
    80005f22:	0cf70463          	beq	a4,a5,80005fea <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005f26:	4789                	li	a5,2
    80005f28:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f2c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f30:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f34:	f4c42783          	lw	a5,-180(s0)
    80005f38:	0017c713          	xori	a4,a5,1
    80005f3c:	8b05                	andi	a4,a4,1
    80005f3e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f42:	0037f713          	andi	a4,a5,3
    80005f46:	00e03733          	snez	a4,a4
    80005f4a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f4e:	4007f793          	andi	a5,a5,1024
    80005f52:	c791                	beqz	a5,80005f5e <sys_open+0xd2>
    80005f54:	04491703          	lh	a4,68(s2)
    80005f58:	4789                	li	a5,2
    80005f5a:	08f70f63          	beq	a4,a5,80005ff8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f5e:	854a                	mv	a0,s2
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	b46080e7          	jalr	-1210(ra) # 80003aa6 <iunlock>
  end_op();
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	7e4080e7          	jalr	2020(ra) # 8000474c <end_op>

  return fd;
}
    80005f70:	8526                	mv	a0,s1
    80005f72:	70ea                	ld	ra,184(sp)
    80005f74:	744a                	ld	s0,176(sp)
    80005f76:	74aa                	ld	s1,168(sp)
    80005f78:	790a                	ld	s2,160(sp)
    80005f7a:	69ea                	ld	s3,152(sp)
    80005f7c:	6129                	addi	sp,sp,192
    80005f7e:	8082                	ret
      end_op();
    80005f80:	ffffe097          	auipc	ra,0xffffe
    80005f84:	7cc080e7          	jalr	1996(ra) # 8000474c <end_op>
      return -1;
    80005f88:	b7e5                	j	80005f70 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f8a:	f5040513          	addi	a0,s0,-176
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	20c080e7          	jalr	524(ra) # 8000419a <namei>
    80005f96:	892a                	mv	s2,a0
    80005f98:	c905                	beqz	a0,80005fc8 <sys_open+0x13c>
    ilock(ip);
    80005f9a:	ffffe097          	auipc	ra,0xffffe
    80005f9e:	a4a080e7          	jalr	-1462(ra) # 800039e4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005fa2:	04491703          	lh	a4,68(s2)
    80005fa6:	4785                	li	a5,1
    80005fa8:	f4f712e3          	bne	a4,a5,80005eec <sys_open+0x60>
    80005fac:	f4c42783          	lw	a5,-180(s0)
    80005fb0:	dba1                	beqz	a5,80005f00 <sys_open+0x74>
      iunlockput(ip);
    80005fb2:	854a                	mv	a0,s2
    80005fb4:	ffffe097          	auipc	ra,0xffffe
    80005fb8:	c92080e7          	jalr	-878(ra) # 80003c46 <iunlockput>
      end_op();
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	790080e7          	jalr	1936(ra) # 8000474c <end_op>
      return -1;
    80005fc4:	54fd                	li	s1,-1
    80005fc6:	b76d                	j	80005f70 <sys_open+0xe4>
      end_op();
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	784080e7          	jalr	1924(ra) # 8000474c <end_op>
      return -1;
    80005fd0:	54fd                	li	s1,-1
    80005fd2:	bf79                	j	80005f70 <sys_open+0xe4>
    iunlockput(ip);
    80005fd4:	854a                	mv	a0,s2
    80005fd6:	ffffe097          	auipc	ra,0xffffe
    80005fda:	c70080e7          	jalr	-912(ra) # 80003c46 <iunlockput>
    end_op();
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	76e080e7          	jalr	1902(ra) # 8000474c <end_op>
    return -1;
    80005fe6:	54fd                	li	s1,-1
    80005fe8:	b761                	j	80005f70 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fea:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fee:	04691783          	lh	a5,70(s2)
    80005ff2:	02f99223          	sh	a5,36(s3)
    80005ff6:	bf2d                	j	80005f30 <sys_open+0xa4>
    itrunc(ip);
    80005ff8:	854a                	mv	a0,s2
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	af8080e7          	jalr	-1288(ra) # 80003af2 <itrunc>
    80006002:	bfb1                	j	80005f5e <sys_open+0xd2>
      fileclose(f);
    80006004:	854e                	mv	a0,s3
    80006006:	fffff097          	auipc	ra,0xfffff
    8000600a:	b92080e7          	jalr	-1134(ra) # 80004b98 <fileclose>
    iunlockput(ip);
    8000600e:	854a                	mv	a0,s2
    80006010:	ffffe097          	auipc	ra,0xffffe
    80006014:	c36080e7          	jalr	-970(ra) # 80003c46 <iunlockput>
    end_op();
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	734080e7          	jalr	1844(ra) # 8000474c <end_op>
    return -1;
    80006020:	54fd                	li	s1,-1
    80006022:	b7b9                	j	80005f70 <sys_open+0xe4>

0000000080006024 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006024:	7175                	addi	sp,sp,-144
    80006026:	e506                	sd	ra,136(sp)
    80006028:	e122                	sd	s0,128(sp)
    8000602a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	6a0080e7          	jalr	1696(ra) # 800046cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006034:	08000613          	li	a2,128
    80006038:	f7040593          	addi	a1,s0,-144
    8000603c:	4501                	li	a0,0
    8000603e:	ffffd097          	auipc	ra,0xffffd
    80006042:	e78080e7          	jalr	-392(ra) # 80002eb6 <argstr>
    80006046:	02054963          	bltz	a0,80006078 <sys_mkdir+0x54>
    8000604a:	4681                	li	a3,0
    8000604c:	4601                	li	a2,0
    8000604e:	4585                	li	a1,1
    80006050:	f7040513          	addi	a0,s0,-144
    80006054:	00000097          	auipc	ra,0x0
    80006058:	cd2080e7          	jalr	-814(ra) # 80005d26 <create>
    8000605c:	cd11                	beqz	a0,80006078 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000605e:	ffffe097          	auipc	ra,0xffffe
    80006062:	be8080e7          	jalr	-1048(ra) # 80003c46 <iunlockput>
  end_op();
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	6e6080e7          	jalr	1766(ra) # 8000474c <end_op>
  return 0;
    8000606e:	4501                	li	a0,0
}
    80006070:	60aa                	ld	ra,136(sp)
    80006072:	640a                	ld	s0,128(sp)
    80006074:	6149                	addi	sp,sp,144
    80006076:	8082                	ret
    end_op();
    80006078:	ffffe097          	auipc	ra,0xffffe
    8000607c:	6d4080e7          	jalr	1748(ra) # 8000474c <end_op>
    return -1;
    80006080:	557d                	li	a0,-1
    80006082:	b7fd                	j	80006070 <sys_mkdir+0x4c>

0000000080006084 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006084:	7135                	addi	sp,sp,-160
    80006086:	ed06                	sd	ra,152(sp)
    80006088:	e922                	sd	s0,144(sp)
    8000608a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000608c:	ffffe097          	auipc	ra,0xffffe
    80006090:	640080e7          	jalr	1600(ra) # 800046cc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006094:	08000613          	li	a2,128
    80006098:	f7040593          	addi	a1,s0,-144
    8000609c:	4501                	li	a0,0
    8000609e:	ffffd097          	auipc	ra,0xffffd
    800060a2:	e18080e7          	jalr	-488(ra) # 80002eb6 <argstr>
    800060a6:	04054a63          	bltz	a0,800060fa <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800060aa:	f6c40593          	addi	a1,s0,-148
    800060ae:	4505                	li	a0,1
    800060b0:	ffffd097          	auipc	ra,0xffffd
    800060b4:	dc2080e7          	jalr	-574(ra) # 80002e72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800060b8:	04054163          	bltz	a0,800060fa <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800060bc:	f6840593          	addi	a1,s0,-152
    800060c0:	4509                	li	a0,2
    800060c2:	ffffd097          	auipc	ra,0xffffd
    800060c6:	db0080e7          	jalr	-592(ra) # 80002e72 <argint>
     argint(1, &major) < 0 ||
    800060ca:	02054863          	bltz	a0,800060fa <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060ce:	f6841683          	lh	a3,-152(s0)
    800060d2:	f6c41603          	lh	a2,-148(s0)
    800060d6:	458d                	li	a1,3
    800060d8:	f7040513          	addi	a0,s0,-144
    800060dc:	00000097          	auipc	ra,0x0
    800060e0:	c4a080e7          	jalr	-950(ra) # 80005d26 <create>
     argint(2, &minor) < 0 ||
    800060e4:	c919                	beqz	a0,800060fa <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060e6:	ffffe097          	auipc	ra,0xffffe
    800060ea:	b60080e7          	jalr	-1184(ra) # 80003c46 <iunlockput>
  end_op();
    800060ee:	ffffe097          	auipc	ra,0xffffe
    800060f2:	65e080e7          	jalr	1630(ra) # 8000474c <end_op>
  return 0;
    800060f6:	4501                	li	a0,0
    800060f8:	a031                	j	80006104 <sys_mknod+0x80>
    end_op();
    800060fa:	ffffe097          	auipc	ra,0xffffe
    800060fe:	652080e7          	jalr	1618(ra) # 8000474c <end_op>
    return -1;
    80006102:	557d                	li	a0,-1
}
    80006104:	60ea                	ld	ra,152(sp)
    80006106:	644a                	ld	s0,144(sp)
    80006108:	610d                	addi	sp,sp,160
    8000610a:	8082                	ret

000000008000610c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000610c:	7135                	addi	sp,sp,-160
    8000610e:	ed06                	sd	ra,152(sp)
    80006110:	e922                	sd	s0,144(sp)
    80006112:	e526                	sd	s1,136(sp)
    80006114:	e14a                	sd	s2,128(sp)
    80006116:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006118:	ffffc097          	auipc	ra,0xffffc
    8000611c:	b02080e7          	jalr	-1278(ra) # 80001c1a <myproc>
    80006120:	892a                	mv	s2,a0
  
  begin_op();
    80006122:	ffffe097          	auipc	ra,0xffffe
    80006126:	5aa080e7          	jalr	1450(ra) # 800046cc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000612a:	08000613          	li	a2,128
    8000612e:	f6040593          	addi	a1,s0,-160
    80006132:	4501                	li	a0,0
    80006134:	ffffd097          	auipc	ra,0xffffd
    80006138:	d82080e7          	jalr	-638(ra) # 80002eb6 <argstr>
    8000613c:	04054b63          	bltz	a0,80006192 <sys_chdir+0x86>
    80006140:	f6040513          	addi	a0,s0,-160
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	056080e7          	jalr	86(ra) # 8000419a <namei>
    8000614c:	84aa                	mv	s1,a0
    8000614e:	c131                	beqz	a0,80006192 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006150:	ffffe097          	auipc	ra,0xffffe
    80006154:	894080e7          	jalr	-1900(ra) # 800039e4 <ilock>
  if(ip->type != T_DIR){
    80006158:	04449703          	lh	a4,68(s1)
    8000615c:	4785                	li	a5,1
    8000615e:	04f71063          	bne	a4,a5,8000619e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006162:	8526                	mv	a0,s1
    80006164:	ffffe097          	auipc	ra,0xffffe
    80006168:	942080e7          	jalr	-1726(ra) # 80003aa6 <iunlock>
  iput(p->cwd);
    8000616c:	15093503          	ld	a0,336(s2)
    80006170:	ffffe097          	auipc	ra,0xffffe
    80006174:	a2e080e7          	jalr	-1490(ra) # 80003b9e <iput>
  end_op();
    80006178:	ffffe097          	auipc	ra,0xffffe
    8000617c:	5d4080e7          	jalr	1492(ra) # 8000474c <end_op>
  p->cwd = ip;
    80006180:	14993823          	sd	s1,336(s2)
  return 0;
    80006184:	4501                	li	a0,0
}
    80006186:	60ea                	ld	ra,152(sp)
    80006188:	644a                	ld	s0,144(sp)
    8000618a:	64aa                	ld	s1,136(sp)
    8000618c:	690a                	ld	s2,128(sp)
    8000618e:	610d                	addi	sp,sp,160
    80006190:	8082                	ret
    end_op();
    80006192:	ffffe097          	auipc	ra,0xffffe
    80006196:	5ba080e7          	jalr	1466(ra) # 8000474c <end_op>
    return -1;
    8000619a:	557d                	li	a0,-1
    8000619c:	b7ed                	j	80006186 <sys_chdir+0x7a>
    iunlockput(ip);
    8000619e:	8526                	mv	a0,s1
    800061a0:	ffffe097          	auipc	ra,0xffffe
    800061a4:	aa6080e7          	jalr	-1370(ra) # 80003c46 <iunlockput>
    end_op();
    800061a8:	ffffe097          	auipc	ra,0xffffe
    800061ac:	5a4080e7          	jalr	1444(ra) # 8000474c <end_op>
    return -1;
    800061b0:	557d                	li	a0,-1
    800061b2:	bfd1                	j	80006186 <sys_chdir+0x7a>

00000000800061b4 <sys_exec>:

uint64
sys_exec(void)
{
    800061b4:	7145                	addi	sp,sp,-464
    800061b6:	e786                	sd	ra,456(sp)
    800061b8:	e3a2                	sd	s0,448(sp)
    800061ba:	ff26                	sd	s1,440(sp)
    800061bc:	fb4a                	sd	s2,432(sp)
    800061be:	f74e                	sd	s3,424(sp)
    800061c0:	f352                	sd	s4,416(sp)
    800061c2:	ef56                	sd	s5,408(sp)
    800061c4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061c6:	08000613          	li	a2,128
    800061ca:	f4040593          	addi	a1,s0,-192
    800061ce:	4501                	li	a0,0
    800061d0:	ffffd097          	auipc	ra,0xffffd
    800061d4:	ce6080e7          	jalr	-794(ra) # 80002eb6 <argstr>
    return -1;
    800061d8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061da:	0c054a63          	bltz	a0,800062ae <sys_exec+0xfa>
    800061de:	e3840593          	addi	a1,s0,-456
    800061e2:	4505                	li	a0,1
    800061e4:	ffffd097          	auipc	ra,0xffffd
    800061e8:	cb0080e7          	jalr	-848(ra) # 80002e94 <argaddr>
    800061ec:	0c054163          	bltz	a0,800062ae <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061f0:	10000613          	li	a2,256
    800061f4:	4581                	li	a1,0
    800061f6:	e4040513          	addi	a0,s0,-448
    800061fa:	ffffb097          	auipc	ra,0xffffb
    800061fe:	ac4080e7          	jalr	-1340(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006202:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006206:	89a6                	mv	s3,s1
    80006208:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000620a:	02000a13          	li	s4,32
    8000620e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006212:	00391793          	slli	a5,s2,0x3
    80006216:	e3040593          	addi	a1,s0,-464
    8000621a:	e3843503          	ld	a0,-456(s0)
    8000621e:	953e                	add	a0,a0,a5
    80006220:	ffffd097          	auipc	ra,0xffffd
    80006224:	bb8080e7          	jalr	-1096(ra) # 80002dd8 <fetchaddr>
    80006228:	02054a63          	bltz	a0,8000625c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000622c:	e3043783          	ld	a5,-464(s0)
    80006230:	c3b9                	beqz	a5,80006276 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006232:	ffffb097          	auipc	ra,0xffffb
    80006236:	8a0080e7          	jalr	-1888(ra) # 80000ad2 <kalloc>
    8000623a:	85aa                	mv	a1,a0
    8000623c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006240:	cd11                	beqz	a0,8000625c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006242:	6605                	lui	a2,0x1
    80006244:	e3043503          	ld	a0,-464(s0)
    80006248:	ffffd097          	auipc	ra,0xffffd
    8000624c:	be2080e7          	jalr	-1054(ra) # 80002e2a <fetchstr>
    80006250:	00054663          	bltz	a0,8000625c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006254:	0905                	addi	s2,s2,1
    80006256:	09a1                	addi	s3,s3,8
    80006258:	fb491be3          	bne	s2,s4,8000620e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000625c:	10048913          	addi	s2,s1,256
    80006260:	6088                	ld	a0,0(s1)
    80006262:	c529                	beqz	a0,800062ac <sys_exec+0xf8>
    kfree(argv[i]);
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	772080e7          	jalr	1906(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000626c:	04a1                	addi	s1,s1,8
    8000626e:	ff2499e3          	bne	s1,s2,80006260 <sys_exec+0xac>
  return -1;
    80006272:	597d                	li	s2,-1
    80006274:	a82d                	j	800062ae <sys_exec+0xfa>
      argv[i] = 0;
    80006276:	0a8e                	slli	s5,s5,0x3
    80006278:	fc040793          	addi	a5,s0,-64
    8000627c:	9abe                	add	s5,s5,a5
    8000627e:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd2e80>
  int ret = exec(path, argv);
    80006282:	e4040593          	addi	a1,s0,-448
    80006286:	f4040513          	addi	a0,s0,-192
    8000628a:	fffff097          	auipc	ra,0xfffff
    8000628e:	156080e7          	jalr	342(ra) # 800053e0 <exec>
    80006292:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006294:	10048993          	addi	s3,s1,256
    80006298:	6088                	ld	a0,0(s1)
    8000629a:	c911                	beqz	a0,800062ae <sys_exec+0xfa>
    kfree(argv[i]);
    8000629c:	ffffa097          	auipc	ra,0xffffa
    800062a0:	73a080e7          	jalr	1850(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800062a4:	04a1                	addi	s1,s1,8
    800062a6:	ff3499e3          	bne	s1,s3,80006298 <sys_exec+0xe4>
    800062aa:	a011                	j	800062ae <sys_exec+0xfa>
  return -1;
    800062ac:	597d                	li	s2,-1
}
    800062ae:	854a                	mv	a0,s2
    800062b0:	60be                	ld	ra,456(sp)
    800062b2:	641e                	ld	s0,448(sp)
    800062b4:	74fa                	ld	s1,440(sp)
    800062b6:	795a                	ld	s2,432(sp)
    800062b8:	79ba                	ld	s3,424(sp)
    800062ba:	7a1a                	ld	s4,416(sp)
    800062bc:	6afa                	ld	s5,408(sp)
    800062be:	6179                	addi	sp,sp,464
    800062c0:	8082                	ret

00000000800062c2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800062c2:	7139                	addi	sp,sp,-64
    800062c4:	fc06                	sd	ra,56(sp)
    800062c6:	f822                	sd	s0,48(sp)
    800062c8:	f426                	sd	s1,40(sp)
    800062ca:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062cc:	ffffc097          	auipc	ra,0xffffc
    800062d0:	94e080e7          	jalr	-1714(ra) # 80001c1a <myproc>
    800062d4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062d6:	fd840593          	addi	a1,s0,-40
    800062da:	4501                	li	a0,0
    800062dc:	ffffd097          	auipc	ra,0xffffd
    800062e0:	bb8080e7          	jalr	-1096(ra) # 80002e94 <argaddr>
    return -1;
    800062e4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062e6:	0e054063          	bltz	a0,800063c6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062ea:	fc840593          	addi	a1,s0,-56
    800062ee:	fd040513          	addi	a0,s0,-48
    800062f2:	fffff097          	auipc	ra,0xfffff
    800062f6:	dcc080e7          	jalr	-564(ra) # 800050be <pipealloc>
    return -1;
    800062fa:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062fc:	0c054563          	bltz	a0,800063c6 <sys_pipe+0x104>
  fd0 = -1;
    80006300:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006304:	fd043503          	ld	a0,-48(s0)
    80006308:	fffff097          	auipc	ra,0xfffff
    8000630c:	4e8080e7          	jalr	1256(ra) # 800057f0 <fdalloc>
    80006310:	fca42223          	sw	a0,-60(s0)
    80006314:	08054c63          	bltz	a0,800063ac <sys_pipe+0xea>
    80006318:	fc843503          	ld	a0,-56(s0)
    8000631c:	fffff097          	auipc	ra,0xfffff
    80006320:	4d4080e7          	jalr	1236(ra) # 800057f0 <fdalloc>
    80006324:	fca42023          	sw	a0,-64(s0)
    80006328:	06054863          	bltz	a0,80006398 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000632c:	4691                	li	a3,4
    8000632e:	fc440613          	addi	a2,s0,-60
    80006332:	fd843583          	ld	a1,-40(s0)
    80006336:	68a8                	ld	a0,80(s1)
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	306080e7          	jalr	774(ra) # 8000163e <copyout>
    80006340:	02054063          	bltz	a0,80006360 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006344:	4691                	li	a3,4
    80006346:	fc040613          	addi	a2,s0,-64
    8000634a:	fd843583          	ld	a1,-40(s0)
    8000634e:	0591                	addi	a1,a1,4
    80006350:	68a8                	ld	a0,80(s1)
    80006352:	ffffb097          	auipc	ra,0xffffb
    80006356:	2ec080e7          	jalr	748(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000635a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000635c:	06055563          	bgez	a0,800063c6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006360:	fc442783          	lw	a5,-60(s0)
    80006364:	07e9                	addi	a5,a5,26
    80006366:	078e                	slli	a5,a5,0x3
    80006368:	97a6                	add	a5,a5,s1
    8000636a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000636e:	fc042503          	lw	a0,-64(s0)
    80006372:	0569                	addi	a0,a0,26
    80006374:	050e                	slli	a0,a0,0x3
    80006376:	9526                	add	a0,a0,s1
    80006378:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000637c:	fd043503          	ld	a0,-48(s0)
    80006380:	fffff097          	auipc	ra,0xfffff
    80006384:	818080e7          	jalr	-2024(ra) # 80004b98 <fileclose>
    fileclose(wf);
    80006388:	fc843503          	ld	a0,-56(s0)
    8000638c:	fffff097          	auipc	ra,0xfffff
    80006390:	80c080e7          	jalr	-2036(ra) # 80004b98 <fileclose>
    return -1;
    80006394:	57fd                	li	a5,-1
    80006396:	a805                	j	800063c6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006398:	fc442783          	lw	a5,-60(s0)
    8000639c:	0007c863          	bltz	a5,800063ac <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800063a0:	01a78513          	addi	a0,a5,26
    800063a4:	050e                	slli	a0,a0,0x3
    800063a6:	9526                	add	a0,a0,s1
    800063a8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800063ac:	fd043503          	ld	a0,-48(s0)
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	7e8080e7          	jalr	2024(ra) # 80004b98 <fileclose>
    fileclose(wf);
    800063b8:	fc843503          	ld	a0,-56(s0)
    800063bc:	ffffe097          	auipc	ra,0xffffe
    800063c0:	7dc080e7          	jalr	2012(ra) # 80004b98 <fileclose>
    return -1;
    800063c4:	57fd                	li	a5,-1
}
    800063c6:	853e                	mv	a0,a5
    800063c8:	70e2                	ld	ra,56(sp)
    800063ca:	7442                	ld	s0,48(sp)
    800063cc:	74a2                	ld	s1,40(sp)
    800063ce:	6121                	addi	sp,sp,64
    800063d0:	8082                	ret
	...

00000000800063e0 <kernelvec>:
    800063e0:	7111                	addi	sp,sp,-256
    800063e2:	e006                	sd	ra,0(sp)
    800063e4:	e40a                	sd	sp,8(sp)
    800063e6:	e80e                	sd	gp,16(sp)
    800063e8:	ec12                	sd	tp,24(sp)
    800063ea:	f016                	sd	t0,32(sp)
    800063ec:	f41a                	sd	t1,40(sp)
    800063ee:	f81e                	sd	t2,48(sp)
    800063f0:	fc22                	sd	s0,56(sp)
    800063f2:	e0a6                	sd	s1,64(sp)
    800063f4:	e4aa                	sd	a0,72(sp)
    800063f6:	e8ae                	sd	a1,80(sp)
    800063f8:	ecb2                	sd	a2,88(sp)
    800063fa:	f0b6                	sd	a3,96(sp)
    800063fc:	f4ba                	sd	a4,104(sp)
    800063fe:	f8be                	sd	a5,112(sp)
    80006400:	fcc2                	sd	a6,120(sp)
    80006402:	e146                	sd	a7,128(sp)
    80006404:	e54a                	sd	s2,136(sp)
    80006406:	e94e                	sd	s3,144(sp)
    80006408:	ed52                	sd	s4,152(sp)
    8000640a:	f156                	sd	s5,160(sp)
    8000640c:	f55a                	sd	s6,168(sp)
    8000640e:	f95e                	sd	s7,176(sp)
    80006410:	fd62                	sd	s8,184(sp)
    80006412:	e1e6                	sd	s9,192(sp)
    80006414:	e5ea                	sd	s10,200(sp)
    80006416:	e9ee                	sd	s11,208(sp)
    80006418:	edf2                	sd	t3,216(sp)
    8000641a:	f1f6                	sd	t4,224(sp)
    8000641c:	f5fa                	sd	t5,232(sp)
    8000641e:	f9fe                	sd	t6,240(sp)
    80006420:	885fc0ef          	jal	ra,80002ca4 <kerneltrap>
    80006424:	6082                	ld	ra,0(sp)
    80006426:	6122                	ld	sp,8(sp)
    80006428:	61c2                	ld	gp,16(sp)
    8000642a:	7282                	ld	t0,32(sp)
    8000642c:	7322                	ld	t1,40(sp)
    8000642e:	73c2                	ld	t2,48(sp)
    80006430:	7462                	ld	s0,56(sp)
    80006432:	6486                	ld	s1,64(sp)
    80006434:	6526                	ld	a0,72(sp)
    80006436:	65c6                	ld	a1,80(sp)
    80006438:	6666                	ld	a2,88(sp)
    8000643a:	7686                	ld	a3,96(sp)
    8000643c:	7726                	ld	a4,104(sp)
    8000643e:	77c6                	ld	a5,112(sp)
    80006440:	7866                	ld	a6,120(sp)
    80006442:	688a                	ld	a7,128(sp)
    80006444:	692a                	ld	s2,136(sp)
    80006446:	69ca                	ld	s3,144(sp)
    80006448:	6a6a                	ld	s4,152(sp)
    8000644a:	7a8a                	ld	s5,160(sp)
    8000644c:	7b2a                	ld	s6,168(sp)
    8000644e:	7bca                	ld	s7,176(sp)
    80006450:	7c6a                	ld	s8,184(sp)
    80006452:	6c8e                	ld	s9,192(sp)
    80006454:	6d2e                	ld	s10,200(sp)
    80006456:	6dce                	ld	s11,208(sp)
    80006458:	6e6e                	ld	t3,216(sp)
    8000645a:	7e8e                	ld	t4,224(sp)
    8000645c:	7f2e                	ld	t5,232(sp)
    8000645e:	7fce                	ld	t6,240(sp)
    80006460:	6111                	addi	sp,sp,256
    80006462:	10200073          	sret
    80006466:	00000013          	nop
    8000646a:	00000013          	nop
    8000646e:	0001                	nop

0000000080006470 <timervec>:
    80006470:	34051573          	csrrw	a0,mscratch,a0
    80006474:	e10c                	sd	a1,0(a0)
    80006476:	e510                	sd	a2,8(a0)
    80006478:	e914                	sd	a3,16(a0)
    8000647a:	6d0c                	ld	a1,24(a0)
    8000647c:	7110                	ld	a2,32(a0)
    8000647e:	6194                	ld	a3,0(a1)
    80006480:	96b2                	add	a3,a3,a2
    80006482:	e194                	sd	a3,0(a1)
    80006484:	4589                	li	a1,2
    80006486:	14459073          	csrw	sip,a1
    8000648a:	6914                	ld	a3,16(a0)
    8000648c:	6510                	ld	a2,8(a0)
    8000648e:	610c                	ld	a1,0(a0)
    80006490:	34051573          	csrrw	a0,mscratch,a0
    80006494:	30200073          	mret
	...

000000008000649a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000649a:	1141                	addi	sp,sp,-16
    8000649c:	e422                	sd	s0,8(sp)
    8000649e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800064a0:	0c0007b7          	lui	a5,0xc000
    800064a4:	4705                	li	a4,1
    800064a6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800064a8:	c3d8                	sw	a4,4(a5)
}
    800064aa:	6422                	ld	s0,8(sp)
    800064ac:	0141                	addi	sp,sp,16
    800064ae:	8082                	ret

00000000800064b0 <plicinithart>:

void
plicinithart(void)
{
    800064b0:	1141                	addi	sp,sp,-16
    800064b2:	e406                	sd	ra,8(sp)
    800064b4:	e022                	sd	s0,0(sp)
    800064b6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064b8:	ffffb097          	auipc	ra,0xffffb
    800064bc:	736080e7          	jalr	1846(ra) # 80001bee <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800064c0:	0085171b          	slliw	a4,a0,0x8
    800064c4:	0c0027b7          	lui	a5,0xc002
    800064c8:	97ba                	add	a5,a5,a4
    800064ca:	40200713          	li	a4,1026
    800064ce:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064d2:	00d5151b          	slliw	a0,a0,0xd
    800064d6:	0c2017b7          	lui	a5,0xc201
    800064da:	953e                	add	a0,a0,a5
    800064dc:	00052023          	sw	zero,0(a0)
}
    800064e0:	60a2                	ld	ra,8(sp)
    800064e2:	6402                	ld	s0,0(sp)
    800064e4:	0141                	addi	sp,sp,16
    800064e6:	8082                	ret

00000000800064e8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064e8:	1141                	addi	sp,sp,-16
    800064ea:	e406                	sd	ra,8(sp)
    800064ec:	e022                	sd	s0,0(sp)
    800064ee:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064f0:	ffffb097          	auipc	ra,0xffffb
    800064f4:	6fe080e7          	jalr	1790(ra) # 80001bee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064f8:	00d5179b          	slliw	a5,a0,0xd
    800064fc:	0c201537          	lui	a0,0xc201
    80006500:	953e                	add	a0,a0,a5
  return irq;
}
    80006502:	4148                	lw	a0,4(a0)
    80006504:	60a2                	ld	ra,8(sp)
    80006506:	6402                	ld	s0,0(sp)
    80006508:	0141                	addi	sp,sp,16
    8000650a:	8082                	ret

000000008000650c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000650c:	1101                	addi	sp,sp,-32
    8000650e:	ec06                	sd	ra,24(sp)
    80006510:	e822                	sd	s0,16(sp)
    80006512:	e426                	sd	s1,8(sp)
    80006514:	1000                	addi	s0,sp,32
    80006516:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006518:	ffffb097          	auipc	ra,0xffffb
    8000651c:	6d6080e7          	jalr	1750(ra) # 80001bee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006520:	00d5151b          	slliw	a0,a0,0xd
    80006524:	0c2017b7          	lui	a5,0xc201
    80006528:	97aa                	add	a5,a5,a0
    8000652a:	c3c4                	sw	s1,4(a5)
}
    8000652c:	60e2                	ld	ra,24(sp)
    8000652e:	6442                	ld	s0,16(sp)
    80006530:	64a2                	ld	s1,8(sp)
    80006532:	6105                	addi	sp,sp,32
    80006534:	8082                	ret

0000000080006536 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006536:	1141                	addi	sp,sp,-16
    80006538:	e406                	sd	ra,8(sp)
    8000653a:	e022                	sd	s0,0(sp)
    8000653c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000653e:	479d                	li	a5,7
    80006540:	06a7c963          	blt	a5,a0,800065b2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006544:	00023797          	auipc	a5,0x23
    80006548:	abc78793          	addi	a5,a5,-1348 # 80029000 <disk>
    8000654c:	00a78733          	add	a4,a5,a0
    80006550:	6789                	lui	a5,0x2
    80006552:	97ba                	add	a5,a5,a4
    80006554:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006558:	e7ad                	bnez	a5,800065c2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000655a:	00451793          	slli	a5,a0,0x4
    8000655e:	00025717          	auipc	a4,0x25
    80006562:	aa270713          	addi	a4,a4,-1374 # 8002b000 <disk+0x2000>
    80006566:	6314                	ld	a3,0(a4)
    80006568:	96be                	add	a3,a3,a5
    8000656a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000656e:	6314                	ld	a3,0(a4)
    80006570:	96be                	add	a3,a3,a5
    80006572:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006576:	6314                	ld	a3,0(a4)
    80006578:	96be                	add	a3,a3,a5
    8000657a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000657e:	6318                	ld	a4,0(a4)
    80006580:	97ba                	add	a5,a5,a4
    80006582:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006586:	00023797          	auipc	a5,0x23
    8000658a:	a7a78793          	addi	a5,a5,-1414 # 80029000 <disk>
    8000658e:	97aa                	add	a5,a5,a0
    80006590:	6509                	lui	a0,0x2
    80006592:	953e                	add	a0,a0,a5
    80006594:	4785                	li	a5,1
    80006596:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000659a:	00025517          	auipc	a0,0x25
    8000659e:	a7e50513          	addi	a0,a0,-1410 # 8002b018 <disk+0x2018>
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	054080e7          	jalr	84(ra) # 800025f6 <wakeup>
}
    800065aa:	60a2                	ld	ra,8(sp)
    800065ac:	6402                	ld	s0,0(sp)
    800065ae:	0141                	addi	sp,sp,16
    800065b0:	8082                	ret
    panic("free_desc 1");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	2ae50513          	addi	a0,a0,686 # 80008860 <syscalls+0x358>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f70080e7          	jalr	-144(ra) # 8000052a <panic>
    panic("free_desc 2");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	2ae50513          	addi	a0,a0,686 # 80008870 <syscalls+0x368>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f60080e7          	jalr	-160(ra) # 8000052a <panic>

00000000800065d2 <virtio_disk_init>:
{
    800065d2:	1101                	addi	sp,sp,-32
    800065d4:	ec06                	sd	ra,24(sp)
    800065d6:	e822                	sd	s0,16(sp)
    800065d8:	e426                	sd	s1,8(sp)
    800065da:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065dc:	00002597          	auipc	a1,0x2
    800065e0:	2a458593          	addi	a1,a1,676 # 80008880 <syscalls+0x378>
    800065e4:	00025517          	auipc	a0,0x25
    800065e8:	b4450513          	addi	a0,a0,-1212 # 8002b128 <disk+0x2128>
    800065ec:	ffffa097          	auipc	ra,0xffffa
    800065f0:	546080e7          	jalr	1350(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065f4:	100017b7          	lui	a5,0x10001
    800065f8:	4398                	lw	a4,0(a5)
    800065fa:	2701                	sext.w	a4,a4
    800065fc:	747277b7          	lui	a5,0x74727
    80006600:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006604:	0ef71163          	bne	a4,a5,800066e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006608:	100017b7          	lui	a5,0x10001
    8000660c:	43dc                	lw	a5,4(a5)
    8000660e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006610:	4705                	li	a4,1
    80006612:	0ce79a63          	bne	a5,a4,800066e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006616:	100017b7          	lui	a5,0x10001
    8000661a:	479c                	lw	a5,8(a5)
    8000661c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000661e:	4709                	li	a4,2
    80006620:	0ce79363          	bne	a5,a4,800066e6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006624:	100017b7          	lui	a5,0x10001
    80006628:	47d8                	lw	a4,12(a5)
    8000662a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000662c:	554d47b7          	lui	a5,0x554d4
    80006630:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006634:	0af71963          	bne	a4,a5,800066e6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006638:	100017b7          	lui	a5,0x10001
    8000663c:	4705                	li	a4,1
    8000663e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006640:	470d                	li	a4,3
    80006642:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006644:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006646:	c7ffe737          	lui	a4,0xc7ffe
    8000664a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd275f>
    8000664e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006650:	2701                	sext.w	a4,a4
    80006652:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006654:	472d                	li	a4,11
    80006656:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006658:	473d                	li	a4,15
    8000665a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000665c:	6705                	lui	a4,0x1
    8000665e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006660:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006664:	5bdc                	lw	a5,52(a5)
    80006666:	2781                	sext.w	a5,a5
  if(max == 0)
    80006668:	c7d9                	beqz	a5,800066f6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000666a:	471d                	li	a4,7
    8000666c:	08f77d63          	bgeu	a4,a5,80006706 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006670:	100014b7          	lui	s1,0x10001
    80006674:	47a1                	li	a5,8
    80006676:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006678:	6609                	lui	a2,0x2
    8000667a:	4581                	li	a1,0
    8000667c:	00023517          	auipc	a0,0x23
    80006680:	98450513          	addi	a0,a0,-1660 # 80029000 <disk>
    80006684:	ffffa097          	auipc	ra,0xffffa
    80006688:	63a080e7          	jalr	1594(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000668c:	00023717          	auipc	a4,0x23
    80006690:	97470713          	addi	a4,a4,-1676 # 80029000 <disk>
    80006694:	00c75793          	srli	a5,a4,0xc
    80006698:	2781                	sext.w	a5,a5
    8000669a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000669c:	00025797          	auipc	a5,0x25
    800066a0:	96478793          	addi	a5,a5,-1692 # 8002b000 <disk+0x2000>
    800066a4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800066a6:	00023717          	auipc	a4,0x23
    800066aa:	9da70713          	addi	a4,a4,-1574 # 80029080 <disk+0x80>
    800066ae:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800066b0:	00024717          	auipc	a4,0x24
    800066b4:	95070713          	addi	a4,a4,-1712 # 8002a000 <disk+0x1000>
    800066b8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800066ba:	4705                	li	a4,1
    800066bc:	00e78c23          	sb	a4,24(a5)
    800066c0:	00e78ca3          	sb	a4,25(a5)
    800066c4:	00e78d23          	sb	a4,26(a5)
    800066c8:	00e78da3          	sb	a4,27(a5)
    800066cc:	00e78e23          	sb	a4,28(a5)
    800066d0:	00e78ea3          	sb	a4,29(a5)
    800066d4:	00e78f23          	sb	a4,30(a5)
    800066d8:	00e78fa3          	sb	a4,31(a5)
}
    800066dc:	60e2                	ld	ra,24(sp)
    800066de:	6442                	ld	s0,16(sp)
    800066e0:	64a2                	ld	s1,8(sp)
    800066e2:	6105                	addi	sp,sp,32
    800066e4:	8082                	ret
    panic("could not find virtio disk");
    800066e6:	00002517          	auipc	a0,0x2
    800066ea:	1aa50513          	addi	a0,a0,426 # 80008890 <syscalls+0x388>
    800066ee:	ffffa097          	auipc	ra,0xffffa
    800066f2:	e3c080e7          	jalr	-452(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800066f6:	00002517          	auipc	a0,0x2
    800066fa:	1ba50513          	addi	a0,a0,442 # 800088b0 <syscalls+0x3a8>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	e2c080e7          	jalr	-468(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006706:	00002517          	auipc	a0,0x2
    8000670a:	1ca50513          	addi	a0,a0,458 # 800088d0 <syscalls+0x3c8>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	e1c080e7          	jalr	-484(ra) # 8000052a <panic>

0000000080006716 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006716:	7119                	addi	sp,sp,-128
    80006718:	fc86                	sd	ra,120(sp)
    8000671a:	f8a2                	sd	s0,112(sp)
    8000671c:	f4a6                	sd	s1,104(sp)
    8000671e:	f0ca                	sd	s2,96(sp)
    80006720:	ecce                	sd	s3,88(sp)
    80006722:	e8d2                	sd	s4,80(sp)
    80006724:	e4d6                	sd	s5,72(sp)
    80006726:	e0da                	sd	s6,64(sp)
    80006728:	fc5e                	sd	s7,56(sp)
    8000672a:	f862                	sd	s8,48(sp)
    8000672c:	f466                	sd	s9,40(sp)
    8000672e:	f06a                	sd	s10,32(sp)
    80006730:	ec6e                	sd	s11,24(sp)
    80006732:	0100                	addi	s0,sp,128
    80006734:	8aaa                	mv	s5,a0
    80006736:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006738:	00c52c83          	lw	s9,12(a0)
    8000673c:	001c9c9b          	slliw	s9,s9,0x1
    80006740:	1c82                	slli	s9,s9,0x20
    80006742:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006746:	00025517          	auipc	a0,0x25
    8000674a:	9e250513          	addi	a0,a0,-1566 # 8002b128 <disk+0x2128>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	474080e7          	jalr	1140(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006756:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006758:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000675a:	00023c17          	auipc	s8,0x23
    8000675e:	8a6c0c13          	addi	s8,s8,-1882 # 80029000 <disk>
    80006762:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006764:	4b0d                	li	s6,3
    80006766:	a0ad                	j	800067d0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006768:	00fc0733          	add	a4,s8,a5
    8000676c:	975e                	add	a4,a4,s7
    8000676e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006772:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006774:	0207c563          	bltz	a5,8000679e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006778:	2905                	addiw	s2,s2,1
    8000677a:	0611                	addi	a2,a2,4
    8000677c:	19690d63          	beq	s2,s6,80006916 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006780:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006782:	00025717          	auipc	a4,0x25
    80006786:	89670713          	addi	a4,a4,-1898 # 8002b018 <disk+0x2018>
    8000678a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000678c:	00074683          	lbu	a3,0(a4)
    80006790:	fee1                	bnez	a3,80006768 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006792:	2785                	addiw	a5,a5,1
    80006794:	0705                	addi	a4,a4,1
    80006796:	fe979be3          	bne	a5,s1,8000678c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000679a:	57fd                	li	a5,-1
    8000679c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000679e:	01205d63          	blez	s2,800067b8 <virtio_disk_rw+0xa2>
    800067a2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800067a4:	000a2503          	lw	a0,0(s4)
    800067a8:	00000097          	auipc	ra,0x0
    800067ac:	d8e080e7          	jalr	-626(ra) # 80006536 <free_desc>
      for(int j = 0; j < i; j++)
    800067b0:	2d85                	addiw	s11,s11,1
    800067b2:	0a11                	addi	s4,s4,4
    800067b4:	ffb918e3          	bne	s2,s11,800067a4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800067b8:	00025597          	auipc	a1,0x25
    800067bc:	97058593          	addi	a1,a1,-1680 # 8002b128 <disk+0x2128>
    800067c0:	00025517          	auipc	a0,0x25
    800067c4:	85850513          	addi	a0,a0,-1960 # 8002b018 <disk+0x2018>
    800067c8:	ffffc097          	auipc	ra,0xffffc
    800067cc:	ca2080e7          	jalr	-862(ra) # 8000246a <sleep>
  for(int i = 0; i < 3; i++){
    800067d0:	f8040a13          	addi	s4,s0,-128
{
    800067d4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800067d6:	894e                	mv	s2,s3
    800067d8:	b765                	j	80006780 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067da:	00025697          	auipc	a3,0x25
    800067de:	8266b683          	ld	a3,-2010(a3) # 8002b000 <disk+0x2000>
    800067e2:	96ba                	add	a3,a3,a4
    800067e4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067e8:	00023817          	auipc	a6,0x23
    800067ec:	81880813          	addi	a6,a6,-2024 # 80029000 <disk>
    800067f0:	00025697          	auipc	a3,0x25
    800067f4:	81068693          	addi	a3,a3,-2032 # 8002b000 <disk+0x2000>
    800067f8:	6290                	ld	a2,0(a3)
    800067fa:	963a                	add	a2,a2,a4
    800067fc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006800:	0015e593          	ori	a1,a1,1
    80006804:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006808:	f8842603          	lw	a2,-120(s0)
    8000680c:	628c                	ld	a1,0(a3)
    8000680e:	972e                	add	a4,a4,a1
    80006810:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006814:	20050593          	addi	a1,a0,512
    80006818:	0592                	slli	a1,a1,0x4
    8000681a:	95c2                	add	a1,a1,a6
    8000681c:	577d                	li	a4,-1
    8000681e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006822:	00461713          	slli	a4,a2,0x4
    80006826:	6290                	ld	a2,0(a3)
    80006828:	963a                	add	a2,a2,a4
    8000682a:	03078793          	addi	a5,a5,48
    8000682e:	97c2                	add	a5,a5,a6
    80006830:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006832:	629c                	ld	a5,0(a3)
    80006834:	97ba                	add	a5,a5,a4
    80006836:	4605                	li	a2,1
    80006838:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000683a:	629c                	ld	a5,0(a3)
    8000683c:	97ba                	add	a5,a5,a4
    8000683e:	4809                	li	a6,2
    80006840:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006844:	629c                	ld	a5,0(a3)
    80006846:	973e                	add	a4,a4,a5
    80006848:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000684c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006850:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006854:	6698                	ld	a4,8(a3)
    80006856:	00275783          	lhu	a5,2(a4)
    8000685a:	8b9d                	andi	a5,a5,7
    8000685c:	0786                	slli	a5,a5,0x1
    8000685e:	97ba                	add	a5,a5,a4
    80006860:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006864:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006868:	6698                	ld	a4,8(a3)
    8000686a:	00275783          	lhu	a5,2(a4)
    8000686e:	2785                	addiw	a5,a5,1
    80006870:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006874:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006878:	100017b7          	lui	a5,0x10001
    8000687c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006880:	004aa783          	lw	a5,4(s5)
    80006884:	02c79163          	bne	a5,a2,800068a6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006888:	00025917          	auipc	s2,0x25
    8000688c:	8a090913          	addi	s2,s2,-1888 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    80006890:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006892:	85ca                	mv	a1,s2
    80006894:	8556                	mv	a0,s5
    80006896:	ffffc097          	auipc	ra,0xffffc
    8000689a:	bd4080e7          	jalr	-1068(ra) # 8000246a <sleep>
  while(b->disk == 1) {
    8000689e:	004aa783          	lw	a5,4(s5)
    800068a2:	fe9788e3          	beq	a5,s1,80006892 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800068a6:	f8042903          	lw	s2,-128(s0)
    800068aa:	20090793          	addi	a5,s2,512
    800068ae:	00479713          	slli	a4,a5,0x4
    800068b2:	00022797          	auipc	a5,0x22
    800068b6:	74e78793          	addi	a5,a5,1870 # 80029000 <disk>
    800068ba:	97ba                	add	a5,a5,a4
    800068bc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800068c0:	00024997          	auipc	s3,0x24
    800068c4:	74098993          	addi	s3,s3,1856 # 8002b000 <disk+0x2000>
    800068c8:	00491713          	slli	a4,s2,0x4
    800068cc:	0009b783          	ld	a5,0(s3)
    800068d0:	97ba                	add	a5,a5,a4
    800068d2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068d6:	854a                	mv	a0,s2
    800068d8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068dc:	00000097          	auipc	ra,0x0
    800068e0:	c5a080e7          	jalr	-934(ra) # 80006536 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068e4:	8885                	andi	s1,s1,1
    800068e6:	f0ed                	bnez	s1,800068c8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068e8:	00025517          	auipc	a0,0x25
    800068ec:	84050513          	addi	a0,a0,-1984 # 8002b128 <disk+0x2128>
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	386080e7          	jalr	902(ra) # 80000c76 <release>
}
    800068f8:	70e6                	ld	ra,120(sp)
    800068fa:	7446                	ld	s0,112(sp)
    800068fc:	74a6                	ld	s1,104(sp)
    800068fe:	7906                	ld	s2,96(sp)
    80006900:	69e6                	ld	s3,88(sp)
    80006902:	6a46                	ld	s4,80(sp)
    80006904:	6aa6                	ld	s5,72(sp)
    80006906:	6b06                	ld	s6,64(sp)
    80006908:	7be2                	ld	s7,56(sp)
    8000690a:	7c42                	ld	s8,48(sp)
    8000690c:	7ca2                	ld	s9,40(sp)
    8000690e:	7d02                	ld	s10,32(sp)
    80006910:	6de2                	ld	s11,24(sp)
    80006912:	6109                	addi	sp,sp,128
    80006914:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006916:	f8042503          	lw	a0,-128(s0)
    8000691a:	20050793          	addi	a5,a0,512
    8000691e:	0792                	slli	a5,a5,0x4
  if(write)
    80006920:	00022817          	auipc	a6,0x22
    80006924:	6e080813          	addi	a6,a6,1760 # 80029000 <disk>
    80006928:	00f80733          	add	a4,a6,a5
    8000692c:	01a036b3          	snez	a3,s10
    80006930:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006934:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006938:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000693c:	7679                	lui	a2,0xffffe
    8000693e:	963e                	add	a2,a2,a5
    80006940:	00024697          	auipc	a3,0x24
    80006944:	6c068693          	addi	a3,a3,1728 # 8002b000 <disk+0x2000>
    80006948:	6298                	ld	a4,0(a3)
    8000694a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000694c:	0a878593          	addi	a1,a5,168
    80006950:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006952:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006954:	6298                	ld	a4,0(a3)
    80006956:	9732                	add	a4,a4,a2
    80006958:	45c1                	li	a1,16
    8000695a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000695c:	6298                	ld	a4,0(a3)
    8000695e:	9732                	add	a4,a4,a2
    80006960:	4585                	li	a1,1
    80006962:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006966:	f8442703          	lw	a4,-124(s0)
    8000696a:	628c                	ld	a1,0(a3)
    8000696c:	962e                	add	a2,a2,a1
    8000696e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd200e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006972:	0712                	slli	a4,a4,0x4
    80006974:	6290                	ld	a2,0(a3)
    80006976:	963a                	add	a2,a2,a4
    80006978:	058a8593          	addi	a1,s5,88
    8000697c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000697e:	6294                	ld	a3,0(a3)
    80006980:	96ba                	add	a3,a3,a4
    80006982:	40000613          	li	a2,1024
    80006986:	c690                	sw	a2,8(a3)
  if(write)
    80006988:	e40d19e3          	bnez	s10,800067da <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000698c:	00024697          	auipc	a3,0x24
    80006990:	6746b683          	ld	a3,1652(a3) # 8002b000 <disk+0x2000>
    80006994:	96ba                	add	a3,a3,a4
    80006996:	4609                	li	a2,2
    80006998:	00c69623          	sh	a2,12(a3)
    8000699c:	b5b1                	j	800067e8 <virtio_disk_rw+0xd2>

000000008000699e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000699e:	1101                	addi	sp,sp,-32
    800069a0:	ec06                	sd	ra,24(sp)
    800069a2:	e822                	sd	s0,16(sp)
    800069a4:	e426                	sd	s1,8(sp)
    800069a6:	e04a                	sd	s2,0(sp)
    800069a8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800069aa:	00024517          	auipc	a0,0x24
    800069ae:	77e50513          	addi	a0,a0,1918 # 8002b128 <disk+0x2128>
    800069b2:	ffffa097          	auipc	ra,0xffffa
    800069b6:	210080e7          	jalr	528(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800069ba:	10001737          	lui	a4,0x10001
    800069be:	533c                	lw	a5,96(a4)
    800069c0:	8b8d                	andi	a5,a5,3
    800069c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800069c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800069c8:	00024797          	auipc	a5,0x24
    800069cc:	63878793          	addi	a5,a5,1592 # 8002b000 <disk+0x2000>
    800069d0:	6b94                	ld	a3,16(a5)
    800069d2:	0207d703          	lhu	a4,32(a5)
    800069d6:	0026d783          	lhu	a5,2(a3)
    800069da:	06f70163          	beq	a4,a5,80006a3c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069de:	00022917          	auipc	s2,0x22
    800069e2:	62290913          	addi	s2,s2,1570 # 80029000 <disk>
    800069e6:	00024497          	auipc	s1,0x24
    800069ea:	61a48493          	addi	s1,s1,1562 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    800069ee:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069f2:	6898                	ld	a4,16(s1)
    800069f4:	0204d783          	lhu	a5,32(s1)
    800069f8:	8b9d                	andi	a5,a5,7
    800069fa:	078e                	slli	a5,a5,0x3
    800069fc:	97ba                	add	a5,a5,a4
    800069fe:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006a00:	20078713          	addi	a4,a5,512
    80006a04:	0712                	slli	a4,a4,0x4
    80006a06:	974a                	add	a4,a4,s2
    80006a08:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006a0c:	e731                	bnez	a4,80006a58 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006a0e:	20078793          	addi	a5,a5,512
    80006a12:	0792                	slli	a5,a5,0x4
    80006a14:	97ca                	add	a5,a5,s2
    80006a16:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006a18:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006a1c:	ffffc097          	auipc	ra,0xffffc
    80006a20:	bda080e7          	jalr	-1062(ra) # 800025f6 <wakeup>

    disk.used_idx += 1;
    80006a24:	0204d783          	lhu	a5,32(s1)
    80006a28:	2785                	addiw	a5,a5,1
    80006a2a:	17c2                	slli	a5,a5,0x30
    80006a2c:	93c1                	srli	a5,a5,0x30
    80006a2e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a32:	6898                	ld	a4,16(s1)
    80006a34:	00275703          	lhu	a4,2(a4)
    80006a38:	faf71be3          	bne	a4,a5,800069ee <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a3c:	00024517          	auipc	a0,0x24
    80006a40:	6ec50513          	addi	a0,a0,1772 # 8002b128 <disk+0x2128>
    80006a44:	ffffa097          	auipc	ra,0xffffa
    80006a48:	232080e7          	jalr	562(ra) # 80000c76 <release>
}
    80006a4c:	60e2                	ld	ra,24(sp)
    80006a4e:	6442                	ld	s0,16(sp)
    80006a50:	64a2                	ld	s1,8(sp)
    80006a52:	6902                	ld	s2,0(sp)
    80006a54:	6105                	addi	sp,sp,32
    80006a56:	8082                	ret
      panic("virtio_disk_intr status");
    80006a58:	00002517          	auipc	a0,0x2
    80006a5c:	e9850513          	addi	a0,a0,-360 # 800088f0 <syscalls+0x3e8>
    80006a60:	ffffa097          	auipc	ra,0xffffa
    80006a64:	aca080e7          	jalr	-1334(ra) # 8000052a <panic>
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
