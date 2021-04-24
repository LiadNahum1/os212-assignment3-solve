
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
    80000068:	3dc78793          	addi	a5,a5,988 # 80006440 <timervec>
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
    80000122:	730080e7          	jalr	1840(ra) # 8000284e <either_copyin>
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
    800001b6:	a62080e7          	jalr	-1438(ra) # 80001c14 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	292080e7          	jalr	658(ra) # 80002454 <sleep>
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
    80000202:	5fa080e7          	jalr	1530(ra) # 800027f8 <either_copyout>
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
    800002e2:	5c6080e7          	jalr	1478(ra) # 800028a4 <procdump>
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
    80000436:	1ae080e7          	jalr	430(ra) # 800025e0 <wakeup>
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
    80000882:	d62080e7          	jalr	-670(ra) # 800025e0 <wakeup>
    
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
    8000090e:	b4a080e7          	jalr	-1206(ra) # 80002454 <sleep>
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
    80000b60:	09c080e7          	jalr	156(ra) # 80001bf8 <mycpu>
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
    80000b92:	06a080e7          	jalr	106(ra) # 80001bf8 <mycpu>
    80000b96:	5d3c                	lw	a5,120(a0)
    80000b98:	cf89                	beqz	a5,80000bb2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000b9a:	00001097          	auipc	ra,0x1
    80000b9e:	05e080e7          	jalr	94(ra) # 80001bf8 <mycpu>
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
    80000bb6:	046080e7          	jalr	70(ra) # 80001bf8 <mycpu>
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
    80000bf6:	006080e7          	jalr	6(ra) # 80001bf8 <mycpu>
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
    80000c22:	fda080e7          	jalr	-38(ra) # 80001bf8 <mycpu>
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
    80000e78:	d74080e7          	jalr	-652(ra) # 80001be8 <cpuid>
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
    80000e94:	d58080e7          	jalr	-680(ra) # 80001be8 <cpuid>
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
    80000eb6:	b34080e7          	jalr	-1228(ra) # 800029e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	5c6080e7          	jalr	1478(ra) # 80006480 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	3e0080e7          	jalr	992(ra) # 800022a2 <scheduler>
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
    80000f26:	c16080e7          	jalr	-1002(ra) # 80001b38 <procinit>
    trapinit();      // trap vectors
    80000f2a:	00002097          	auipc	ra,0x2
    80000f2e:	a94080e7          	jalr	-1388(ra) # 800029be <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	ab4080e7          	jalr	-1356(ra) # 800029e6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	530080e7          	jalr	1328(ra) # 8000646a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	53e080e7          	jalr	1342(ra) # 80006480 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	1dc080e7          	jalr	476(ra) # 80003126 <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	86e080e7          	jalr	-1938(ra) # 800037c0 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	b2e080e7          	jalr	-1234(ra) # 80004a88 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	640080e7          	jalr	1600(ra) # 800065a2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	fc6080e7          	jalr	-58(ra) # 80001f30 <userinit>
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
    80001210:	896080e7          	jalr	-1898(ra) # 80001aa2 <proc_mapstacks>
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
    80001822:	3f6080e7          	jalr	1014(ra) # 80001c14 <myproc>
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
    8000185e:	89aa                	mv	s3,a0
    struct proc * p = myproc();
    80001860:	00000097          	auipc	ra,0x0
    80001864:	3b4080e7          	jalr	948(ra) # 80001c14 <myproc>
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
    80001896:	8a2a                	mv	s4,a0
    //write the information from this file to memory
    uint64 physical_addr = PTE2PA(*out_page_entry);
    if(writeToSwapFile(p,(char*)PA2PTE(physical_addr),offset,PGSIZE) ==  -1)
    80001898:	00053a83          	ld	s5,0(a0)
    8000189c:	77fd                	lui	a5,0xfffff
    8000189e:	8389                	srli	a5,a5,0x2
    800018a0:	00fafab3          	and	s5,s5,a5
    800018a4:	2981                	sext.w	s3,s3
    800018a6:	6685                	lui	a3,0x1
    800018a8:	864e                	mv	a2,s3
    800018aa:	85d6                	mv	a1,s5
    800018ac:	8526                	mv	a0,s1
    800018ae:	00003097          	auipc	ra,0x3
    800018b2:	bc4080e7          	jalr	-1084(ra) # 80004472 <writeToSwapFile>
    800018b6:	57fd                	li	a5,-1
    800018b8:	04f50263          	beq	a0,a5,800018fc <swap_page_into_file+0xb0>
      panic("write to file failed");
    //free the RAM memmory of the swapped page
    kfree((void*)PA2PTE(physical_addr));
    800018bc:	8556                	mv	a0,s5
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	118080e7          	jalr	280(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    800018c6:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0xffffffff7ffd3000>
    800018ca:	bfe7f793          	andi	a5,a5,-1026
    800018ce:	4007e793          	ori	a5,a5,1024
    800018d2:	00fa3023          	sd	a5,0(s4)
    p->paging_meta_data[remove_file_indx].offset = offset;
    800018d6:	00191513          	slli	a0,s2,0x1
    800018da:	012507b3          	add	a5,a0,s2
    800018de:	078a                	slli	a5,a5,0x2
    800018e0:	97a6                	add	a5,a5,s1
    800018e2:	1737a823          	sw	s3,368(a5) # fffffffffffff170 <end+0xffffffff7ffd3170>
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    800018e6:	1607ac23          	sw	zero,376(a5)
      
}
    800018ea:	70e2                	ld	ra,56(sp)
    800018ec:	7442                	ld	s0,48(sp)
    800018ee:	74a2                	ld	s1,40(sp)
    800018f0:	7902                	ld	s2,32(sp)
    800018f2:	69e2                	ld	s3,24(sp)
    800018f4:	6a42                	ld	s4,16(sp)
    800018f6:	6aa2                	ld	s5,8(sp)
    800018f8:	6121                	addi	sp,sp,64
    800018fa:	8082                	ret
      panic("write to file failed");
    800018fc:	00007517          	auipc	a0,0x7
    80001900:	8dc50513          	addi	a0,a0,-1828 # 800081d8 <digits+0x198>
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	c26080e7          	jalr	-986(ra) # 8000052a <panic>

000000008000190c <get_num_of_pages_in_memory>:

int get_num_of_pages_in_memory(){
    8000190c:	7179                	addi	sp,sp,-48
    8000190e:	f406                	sd	ra,40(sp)
    80001910:	f022                	sd	s0,32(sp)
    80001912:	ec26                	sd	s1,24(sp)
    80001914:	e84a                	sd	s2,16(sp)
    80001916:	e44e                	sd	s3,8(sp)
    80001918:	1800                	addi	s0,sp,48
  int counter = 0;
  for(int i=0; i<32; i++){
    8000191a:	4481                	li	s1,0
  int counter = 0;
    8000191c:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    8000191e:	02000993          	li	s3,32
    80001922:	a021                	j	8000192a <get_num_of_pages_in_memory+0x1e>
    80001924:	2485                	addiw	s1,s1,1
    80001926:	03348063          	beq	s1,s3,80001946 <get_num_of_pages_in_memory+0x3a>
    if(myproc()->paging_meta_data[i].in_memory)
    8000192a:	00000097          	auipc	ra,0x0
    8000192e:	2ea080e7          	jalr	746(ra) # 80001c14 <myproc>
    80001932:	00149793          	slli	a5,s1,0x1
    80001936:	97a6                	add	a5,a5,s1
    80001938:	078a                	slli	a5,a5,0x2
    8000193a:	97aa                	add	a5,a5,a0
    8000193c:	1787a783          	lw	a5,376(a5)
    80001940:	d3f5                	beqz	a5,80001924 <get_num_of_pages_in_memory+0x18>
      counter = counter+1;
    80001942:	2905                	addiw	s2,s2,1
    80001944:	b7c5                	j	80001924 <get_num_of_pages_in_memory+0x18>
  }
  return counter; 
}
    80001946:	854a                	mv	a0,s2
    80001948:	70a2                	ld	ra,40(sp)
    8000194a:	7402                	ld	s0,32(sp)
    8000194c:	64e2                	ld	s1,24(sp)
    8000194e:	6942                	ld	s2,16(sp)
    80001950:	69a2                	ld	s3,8(sp)
    80001952:	6145                	addi	sp,sp,48
    80001954:	8082                	ret

0000000080001956 <page_in>:

void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    80001956:	7179                	addi	sp,sp,-48
    80001958:	f406                	sd	ra,40(sp)
    8000195a:	f022                	sd	s0,32(sp)
    8000195c:	ec26                	sd	s1,24(sp)
    8000195e:	e84a                	sd	s2,16(sp)
    80001960:	e44e                	sd	s3,8(sp)
    80001962:	e052                	sd	s4,0(sp)
    80001964:	1800                	addi	s0,sp,48
    80001966:	89ae                	mv	s3,a1
  //get the page number of the missing in ram page
  int current_page_number = PGROUNDDOWN(faulting_address)/PGSIZE;
    80001968:	8131                	srli	a0,a0,0xc
    8000196a:	0005091b          	sext.w	s2,a0
  //get its offset in the saved file
  uint offset = myproc()->paging_meta_data[current_page_number].offset;
    8000196e:	00000097          	auipc	ra,0x0
    80001972:	2a6080e7          	jalr	678(ra) # 80001c14 <myproc>
    80001976:	00191793          	slli	a5,s2,0x1
    8000197a:	97ca                	add	a5,a5,s2
    8000197c:	078a                	slli	a5,a5,0x2
    8000197e:	97aa                	add	a5,a5,a0
    80001980:	1707aa03          	lw	s4,368(a5)
  if(offset == -1){
    80001984:	57fd                	li	a5,-1
    80001986:	08fa0463          	beq	s4,a5,80001a0e <page_in+0xb8>
    panic("offset is -1");
  }
  //allocate a buffer for the information from the file
  char* read_buffer;
  if((read_buffer = kalloc()) == 0)
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	148080e7          	jalr	328(ra) # 80000ad2 <kalloc>
    80001992:	84aa                	mv	s1,a0
    80001994:	c549                	beqz	a0,80001a1e <page_in+0xc8>
    panic("not enough space to kalloc");
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    80001996:	00000097          	auipc	ra,0x0
    8000199a:	27e080e7          	jalr	638(ra) # 80001c14 <myproc>
    8000199e:	6685                	lui	a3,0x1
    800019a0:	8652                	mv	a2,s4
    800019a2:	85a6                	mv	a1,s1
    800019a4:	00003097          	auipc	ra,0x3
    800019a8:	af2080e7          	jalr	-1294(ra) # 80004496 <readFromSwapFile>
    800019ac:	57fd                	li	a5,-1
    800019ae:	08f50063          	beq	a0,a5,80001a2e <page_in+0xd8>
    panic("read from file failed");
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    800019b2:	00000097          	auipc	ra,0x0
    800019b6:	f5a080e7          	jalr	-166(ra) # 8000190c <get_num_of_pages_in_memory>
    800019ba:	47bd                	li	a5,15
    800019bc:	08a7c163          	blt	a5,a0,80001a3e <page_in+0xe8>
    swap_page_into_file(offset); //maybe adding it in the end of the swap file?
    *missing_pte_entry = PTE2PA((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
  }  
  else{
      *missing_pte_entry = PTE2PA((uint64)read_buffer) | PTE_V; 
    800019c0:	80a9                	srli	s1,s1,0xa
    800019c2:	04b2                	slli	s1,s1,0xc
    800019c4:	0014e493          	ori	s1,s1,1
    800019c8:	0099b023          	sd	s1,0(s3) # 1000 <_entry-0x7ffff000>
  }
  //update offsets and aging of the files
  //myproc()->paging_meta_data[current_num_pages].aging = init_aging(current_num_pages);
  myproc()->paging_meta_data[current_page_number].offset = -1;
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	248080e7          	jalr	584(ra) # 80001c14 <myproc>
    800019d4:	00191493          	slli	s1,s2,0x1
    800019d8:	012487b3          	add	a5,s1,s2
    800019dc:	078a                	slli	a5,a5,0x2
    800019de:	953e                	add	a0,a0,a5
    800019e0:	57fd                	li	a5,-1
    800019e2:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_number].in_memory = 1;
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	22e080e7          	jalr	558(ra) # 80001c14 <myproc>
    800019ee:	94ca                	add	s1,s1,s2
    800019f0:	048a                	slli	s1,s1,0x2
    800019f2:	94aa                	add	s1,s1,a0
    800019f4:	4785                	li	a5,1
    800019f6:	16f4ac23          	sw	a5,376(s1)
    800019fa:	12000073          	sfence.vma
  sfence_vma(); //refresh TLB
}
    800019fe:	70a2                	ld	ra,40(sp)
    80001a00:	7402                	ld	s0,32(sp)
    80001a02:	64e2                	ld	s1,24(sp)
    80001a04:	6942                	ld	s2,16(sp)
    80001a06:	69a2                	ld	s3,8(sp)
    80001a08:	6a02                	ld	s4,0(sp)
    80001a0a:	6145                	addi	sp,sp,48
    80001a0c:	8082                	ret
    panic("offset is -1");
    80001a0e:	00006517          	auipc	a0,0x6
    80001a12:	7e250513          	addi	a0,a0,2018 # 800081f0 <digits+0x1b0>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	b14080e7          	jalr	-1260(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    80001a1e:	00006517          	auipc	a0,0x6
    80001a22:	7e250513          	addi	a0,a0,2018 # 80008200 <digits+0x1c0>
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	b04080e7          	jalr	-1276(ra) # 8000052a <panic>
    panic("read from file failed");
    80001a2e:	00006517          	auipc	a0,0x6
    80001a32:	7f250513          	addi	a0,a0,2034 # 80008220 <digits+0x1e0>
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	af4080e7          	jalr	-1292(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap file?
    80001a3e:	8552                	mv	a0,s4
    80001a40:	00000097          	auipc	ra,0x0
    80001a44:	e0c080e7          	jalr	-500(ra) # 8000184c <swap_page_into_file>
    *missing_pte_entry = PTE2PA((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    80001a48:	80a9                	srli	s1,s1,0xa
    80001a4a:	04b2                	slli	s1,s1,0xc
    80001a4c:	0009b783          	ld	a5,0(s3)
    80001a50:	3fe7f793          	andi	a5,a5,1022
    80001a54:	8cdd                	or	s1,s1,a5
    80001a56:	0014e493          	ori	s1,s1,1
    80001a5a:	0099b023          	sd	s1,0(s3)
    80001a5e:	b7bd                	j	800019cc <page_in+0x76>

0000000080001a60 <check_page_fault>:

void check_page_fault(){
    80001a60:	1101                	addi	sp,sp,-32
    80001a62:	ec06                	sd	ra,24(sp)
    80001a64:	e822                	sd	s0,16(sp)
    80001a66:	e426                	sd	s1,8(sp)
    80001a68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001a6a:	143024f3          	csrr	s1,stval
  uint64 faulting_address = r_stval(); 
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80001a6e:	00000097          	auipc	ra,0x0
    80001a72:	1a6080e7          	jalr	422(ra) # 80001c14 <myproc>
    80001a76:	4601                	li	a2,0
    80001a78:	75fd                	lui	a1,0xfffff
    80001a7a:	8de5                	and	a1,a1,s1
    80001a7c:	6928                	ld	a0,80(a0)
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	528080e7          	jalr	1320(ra) # 80000fa6 <walk>
  else if(!(*pte_entry & PTE_W)& (*pte_entry & PTE_COW)){
     cprintf("Page Fault- COPY ON WRITE\n");
     create_write_through(faulting_address, pte_entry);
  }*/
  else{
    printf("went to file without permissions!!! %d\n", faulting_address);
    80001a86:	85a6                	mv	a1,s1
    80001a88:	00006517          	auipc	a0,0x6
    80001a8c:	7b050513          	addi	a0,a0,1968 # 80008238 <digits+0x1f8>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	ae4080e7          	jalr	-1308(ra) # 80000574 <printf>
  }
}
    80001a98:	60e2                	ld	ra,24(sp)
    80001a9a:	6442                	ld	s0,16(sp)
    80001a9c:	64a2                	ld	s1,8(sp)
    80001a9e:	6105                	addi	sp,sp,32
    80001aa0:	8082                	ret

0000000080001aa2 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001aa2:	7139                	addi	sp,sp,-64
    80001aa4:	fc06                	sd	ra,56(sp)
    80001aa6:	f822                	sd	s0,48(sp)
    80001aa8:	f426                	sd	s1,40(sp)
    80001aaa:	f04a                	sd	s2,32(sp)
    80001aac:	ec4e                	sd	s3,24(sp)
    80001aae:	e852                	sd	s4,16(sp)
    80001ab0:	e456                	sd	s5,8(sp)
    80001ab2:	e05a                	sd	s6,0(sp)
    80001ab4:	0080                	addi	s0,sp,64
    80001ab6:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab8:	00010497          	auipc	s1,0x10
    80001abc:	c1848493          	addi	s1,s1,-1000 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ac0:	8b26                	mv	s6,s1
    80001ac2:	00006a97          	auipc	s5,0x6
    80001ac6:	53ea8a93          	addi	s5,s5,1342 # 80008000 <etext>
    80001aca:	04000937          	lui	s2,0x4000
    80001ace:	197d                	addi	s2,s2,-1
    80001ad0:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad2:	0001ba17          	auipc	s4,0x1b
    80001ad6:	7fea0a13          	addi	s4,s4,2046 # 8001d2d0 <tickslock>
    char *pa = kalloc();
    80001ada:	fffff097          	auipc	ra,0xfffff
    80001ade:	ff8080e7          	jalr	-8(ra) # 80000ad2 <kalloc>
    80001ae2:	862a                	mv	a2,a0
    if(pa == 0)
    80001ae4:	c131                	beqz	a0,80001b28 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001ae6:	416485b3          	sub	a1,s1,s6
    80001aea:	8591                	srai	a1,a1,0x4
    80001aec:	000ab783          	ld	a5,0(s5)
    80001af0:	02f585b3          	mul	a1,a1,a5
    80001af4:	2585                	addiw	a1,a1,1
    80001af6:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001afa:	4719                	li	a4,6
    80001afc:	6685                	lui	a3,0x1
    80001afe:	40b905b3          	sub	a1,s2,a1
    80001b02:	854e                	mv	a0,s3
    80001b04:	fffff097          	auipc	ra,0xfffff
    80001b08:	618080e7          	jalr	1560(ra) # 8000111c <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b0c:	2f048493          	addi	s1,s1,752
    80001b10:	fd4495e3          	bne	s1,s4,80001ada <proc_mapstacks+0x38>
  }
}
    80001b14:	70e2                	ld	ra,56(sp)
    80001b16:	7442                	ld	s0,48(sp)
    80001b18:	74a2                	ld	s1,40(sp)
    80001b1a:	7902                	ld	s2,32(sp)
    80001b1c:	69e2                	ld	s3,24(sp)
    80001b1e:	6a42                	ld	s4,16(sp)
    80001b20:	6aa2                	ld	s5,8(sp)
    80001b22:	6b02                	ld	s6,0(sp)
    80001b24:	6121                	addi	sp,sp,64
    80001b26:	8082                	ret
      panic("kalloc");
    80001b28:	00006517          	auipc	a0,0x6
    80001b2c:	73850513          	addi	a0,a0,1848 # 80008260 <digits+0x220>
    80001b30:	fffff097          	auipc	ra,0xfffff
    80001b34:	9fa080e7          	jalr	-1542(ra) # 8000052a <panic>

0000000080001b38 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b38:	7139                	addi	sp,sp,-64
    80001b3a:	fc06                	sd	ra,56(sp)
    80001b3c:	f822                	sd	s0,48(sp)
    80001b3e:	f426                	sd	s1,40(sp)
    80001b40:	f04a                	sd	s2,32(sp)
    80001b42:	ec4e                	sd	s3,24(sp)
    80001b44:	e852                	sd	s4,16(sp)
    80001b46:	e456                	sd	s5,8(sp)
    80001b48:	e05a                	sd	s6,0(sp)
    80001b4a:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001b4c:	00006597          	auipc	a1,0x6
    80001b50:	71c58593          	addi	a1,a1,1820 # 80008268 <digits+0x228>
    80001b54:	0000f517          	auipc	a0,0xf
    80001b58:	74c50513          	addi	a0,a0,1868 # 800112a0 <pid_lock>
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	fd6080e7          	jalr	-42(ra) # 80000b32 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b64:	00006597          	auipc	a1,0x6
    80001b68:	70c58593          	addi	a1,a1,1804 # 80008270 <digits+0x230>
    80001b6c:	0000f517          	auipc	a0,0xf
    80001b70:	74c50513          	addi	a0,a0,1868 # 800112b8 <wait_lock>
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	fbe080e7          	jalr	-66(ra) # 80000b32 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b7c:	00010497          	auipc	s1,0x10
    80001b80:	b5448493          	addi	s1,s1,-1196 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001b84:	00006b17          	auipc	s6,0x6
    80001b88:	6fcb0b13          	addi	s6,s6,1788 # 80008280 <digits+0x240>
      p->kstack = KSTACK((int) (p - proc));
    80001b8c:	8aa6                	mv	s5,s1
    80001b8e:	00006a17          	auipc	s4,0x6
    80001b92:	472a0a13          	addi	s4,s4,1138 # 80008000 <etext>
    80001b96:	04000937          	lui	s2,0x4000
    80001b9a:	197d                	addi	s2,s2,-1
    80001b9c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b9e:	0001b997          	auipc	s3,0x1b
    80001ba2:	73298993          	addi	s3,s3,1842 # 8001d2d0 <tickslock>
      initlock(&p->lock, "proc");
    80001ba6:	85da                	mv	a1,s6
    80001ba8:	8526                	mv	a0,s1
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	f88080e7          	jalr	-120(ra) # 80000b32 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bb2:	415487b3          	sub	a5,s1,s5
    80001bb6:	8791                	srai	a5,a5,0x4
    80001bb8:	000a3703          	ld	a4,0(s4)
    80001bbc:	02e787b3          	mul	a5,a5,a4
    80001bc0:	2785                	addiw	a5,a5,1
    80001bc2:	00d7979b          	slliw	a5,a5,0xd
    80001bc6:	40f907b3          	sub	a5,s2,a5
    80001bca:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bcc:	2f048493          	addi	s1,s1,752
    80001bd0:	fd349be3          	bne	s1,s3,80001ba6 <procinit+0x6e>
  }
}
    80001bd4:	70e2                	ld	ra,56(sp)
    80001bd6:	7442                	ld	s0,48(sp)
    80001bd8:	74a2                	ld	s1,40(sp)
    80001bda:	7902                	ld	s2,32(sp)
    80001bdc:	69e2                	ld	s3,24(sp)
    80001bde:	6a42                	ld	s4,16(sp)
    80001be0:	6aa2                	ld	s5,8(sp)
    80001be2:	6b02                	ld	s6,0(sp)
    80001be4:	6121                	addi	sp,sp,64
    80001be6:	8082                	ret

0000000080001be8 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001be8:	1141                	addi	sp,sp,-16
    80001bea:	e422                	sd	s0,8(sp)
    80001bec:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bee:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bf0:	2501                	sext.w	a0,a0
    80001bf2:	6422                	ld	s0,8(sp)
    80001bf4:	0141                	addi	sp,sp,16
    80001bf6:	8082                	ret

0000000080001bf8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bf8:	1141                	addi	sp,sp,-16
    80001bfa:	e422                	sd	s0,8(sp)
    80001bfc:	0800                	addi	s0,sp,16
    80001bfe:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c00:	2781                	sext.w	a5,a5
    80001c02:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c04:	0000f517          	auipc	a0,0xf
    80001c08:	6cc50513          	addi	a0,a0,1740 # 800112d0 <cpus>
    80001c0c:	953e                	add	a0,a0,a5
    80001c0e:	6422                	ld	s0,8(sp)
    80001c10:	0141                	addi	sp,sp,16
    80001c12:	8082                	ret

0000000080001c14 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c14:	1101                	addi	sp,sp,-32
    80001c16:	ec06                	sd	ra,24(sp)
    80001c18:	e822                	sd	s0,16(sp)
    80001c1a:	e426                	sd	s1,8(sp)
    80001c1c:	1000                	addi	s0,sp,32
  push_off();
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	f58080e7          	jalr	-168(ra) # 80000b76 <push_off>
    80001c26:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c28:	2781                	sext.w	a5,a5
    80001c2a:	079e                	slli	a5,a5,0x7
    80001c2c:	0000f717          	auipc	a4,0xf
    80001c30:	67470713          	addi	a4,a4,1652 # 800112a0 <pid_lock>
    80001c34:	97ba                	add	a5,a5,a4
    80001c36:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	fde080e7          	jalr	-34(ra) # 80000c16 <pop_off>
  return p;
}
    80001c40:	8526                	mv	a0,s1
    80001c42:	60e2                	ld	ra,24(sp)
    80001c44:	6442                	ld	s0,16(sp)
    80001c46:	64a2                	ld	s1,8(sp)
    80001c48:	6105                	addi	sp,sp,32
    80001c4a:	8082                	ret

0000000080001c4c <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c4c:	1141                	addi	sp,sp,-16
    80001c4e:	e406                	sd	ra,8(sp)
    80001c50:	e022                	sd	s0,0(sp)
    80001c52:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c54:	00000097          	auipc	ra,0x0
    80001c58:	fc0080e7          	jalr	-64(ra) # 80001c14 <myproc>
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	01a080e7          	jalr	26(ra) # 80000c76 <release>

  if (first) {
    80001c64:	00007797          	auipc	a5,0x7
    80001c68:	cac7a783          	lw	a5,-852(a5) # 80008910 <first.1>
    80001c6c:	eb89                	bnez	a5,80001c7e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c6e:	00001097          	auipc	ra,0x1
    80001c72:	d90080e7          	jalr	-624(ra) # 800029fe <usertrapret>
}
    80001c76:	60a2                	ld	ra,8(sp)
    80001c78:	6402                	ld	s0,0(sp)
    80001c7a:	0141                	addi	sp,sp,16
    80001c7c:	8082                	ret
    first = 0;
    80001c7e:	00007797          	auipc	a5,0x7
    80001c82:	c807a923          	sw	zero,-878(a5) # 80008910 <first.1>
    fsinit(ROOTDEV);
    80001c86:	4505                	li	a0,1
    80001c88:	00002097          	auipc	ra,0x2
    80001c8c:	ab8080e7          	jalr	-1352(ra) # 80003740 <fsinit>
    80001c90:	bff9                	j	80001c6e <forkret+0x22>

0000000080001c92 <allocpid>:
allocpid() {
    80001c92:	1101                	addi	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	e04a                	sd	s2,0(sp)
    80001c9c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c9e:	0000f917          	auipc	s2,0xf
    80001ca2:	60290913          	addi	s2,s2,1538 # 800112a0 <pid_lock>
    80001ca6:	854a                	mv	a0,s2
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	f1a080e7          	jalr	-230(ra) # 80000bc2 <acquire>
  pid = nextpid;
    80001cb0:	00007797          	auipc	a5,0x7
    80001cb4:	c6478793          	addi	a5,a5,-924 # 80008914 <nextpid>
    80001cb8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cba:	0014871b          	addiw	a4,s1,1
    80001cbe:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cc0:	854a                	mv	a0,s2
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fb4080e7          	jalr	-76(ra) # 80000c76 <release>
}
    80001cca:	8526                	mv	a0,s1
    80001ccc:	60e2                	ld	ra,24(sp)
    80001cce:	6442                	ld	s0,16(sp)
    80001cd0:	64a2                	ld	s1,8(sp)
    80001cd2:	6902                	ld	s2,0(sp)
    80001cd4:	6105                	addi	sp,sp,32
    80001cd6:	8082                	ret

0000000080001cd8 <proc_pagetable>:
{
    80001cd8:	1101                	addi	sp,sp,-32
    80001cda:	ec06                	sd	ra,24(sp)
    80001cdc:	e822                	sd	s0,16(sp)
    80001cde:	e426                	sd	s1,8(sp)
    80001ce0:	e04a                	sd	s2,0(sp)
    80001ce2:	1000                	addi	s0,sp,32
    80001ce4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	620080e7          	jalr	1568(ra) # 80001306 <uvmcreate>
    80001cee:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cf0:	c121                	beqz	a0,80001d30 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cf2:	4729                	li	a4,10
    80001cf4:	00005697          	auipc	a3,0x5
    80001cf8:	30c68693          	addi	a3,a3,780 # 80007000 <_trampoline>
    80001cfc:	6605                	lui	a2,0x1
    80001cfe:	040005b7          	lui	a1,0x4000
    80001d02:	15fd                	addi	a1,a1,-1
    80001d04:	05b2                	slli	a1,a1,0xc
    80001d06:	fffff097          	auipc	ra,0xfffff
    80001d0a:	388080e7          	jalr	904(ra) # 8000108e <mappages>
    80001d0e:	02054863          	bltz	a0,80001d3e <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d12:	4719                	li	a4,6
    80001d14:	05893683          	ld	a3,88(s2)
    80001d18:	6605                	lui	a2,0x1
    80001d1a:	020005b7          	lui	a1,0x2000
    80001d1e:	15fd                	addi	a1,a1,-1
    80001d20:	05b6                	slli	a1,a1,0xd
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	36a080e7          	jalr	874(ra) # 8000108e <mappages>
    80001d2c:	02054163          	bltz	a0,80001d4e <proc_pagetable+0x76>
}
    80001d30:	8526                	mv	a0,s1
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6902                	ld	s2,0(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret
    uvmfree(pagetable, 0);
    80001d3e:	4581                	li	a1,0
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	7c0080e7          	jalr	1984(ra) # 80001502 <uvmfree>
    return 0;
    80001d4a:	4481                	li	s1,0
    80001d4c:	b7d5                	j	80001d30 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d4e:	4681                	li	a3,0
    80001d50:	4605                	li	a2,1
    80001d52:	040005b7          	lui	a1,0x4000
    80001d56:	15fd                	addi	a1,a1,-1
    80001d58:	05b2                	slli	a1,a1,0xc
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	4e6080e7          	jalr	1254(ra) # 80001242 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d64:	4581                	li	a1,0
    80001d66:	8526                	mv	a0,s1
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	79a080e7          	jalr	1946(ra) # 80001502 <uvmfree>
    return 0;
    80001d70:	4481                	li	s1,0
    80001d72:	bf7d                	j	80001d30 <proc_pagetable+0x58>

0000000080001d74 <proc_freepagetable>:
{
    80001d74:	1101                	addi	sp,sp,-32
    80001d76:	ec06                	sd	ra,24(sp)
    80001d78:	e822                	sd	s0,16(sp)
    80001d7a:	e426                	sd	s1,8(sp)
    80001d7c:	e04a                	sd	s2,0(sp)
    80001d7e:	1000                	addi	s0,sp,32
    80001d80:	84aa                	mv	s1,a0
    80001d82:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d84:	4681                	li	a3,0
    80001d86:	4605                	li	a2,1
    80001d88:	040005b7          	lui	a1,0x4000
    80001d8c:	15fd                	addi	a1,a1,-1
    80001d8e:	05b2                	slli	a1,a1,0xc
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	4b2080e7          	jalr	1202(ra) # 80001242 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d98:	4681                	li	a3,0
    80001d9a:	4605                	li	a2,1
    80001d9c:	020005b7          	lui	a1,0x2000
    80001da0:	15fd                	addi	a1,a1,-1
    80001da2:	05b6                	slli	a1,a1,0xd
    80001da4:	8526                	mv	a0,s1
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	49c080e7          	jalr	1180(ra) # 80001242 <uvmunmap>
  uvmfree(pagetable, sz);
    80001dae:	85ca                	mv	a1,s2
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	750080e7          	jalr	1872(ra) # 80001502 <uvmfree>
}
    80001dba:	60e2                	ld	ra,24(sp)
    80001dbc:	6442                	ld	s0,16(sp)
    80001dbe:	64a2                	ld	s1,8(sp)
    80001dc0:	6902                	ld	s2,0(sp)
    80001dc2:	6105                	addi	sp,sp,32
    80001dc4:	8082                	ret

0000000080001dc6 <freeproc>:
{
    80001dc6:	1101                	addi	sp,sp,-32
    80001dc8:	ec06                	sd	ra,24(sp)
    80001dca:	e822                	sd	s0,16(sp)
    80001dcc:	e426                	sd	s1,8(sp)
    80001dce:	1000                	addi	s0,sp,32
    80001dd0:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dd2:	6d28                	ld	a0,88(a0)
    80001dd4:	c509                	beqz	a0,80001dde <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	c00080e7          	jalr	-1024(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001dde:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001de2:	68a8                	ld	a0,80(s1)
    80001de4:	c511                	beqz	a0,80001df0 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001de6:	64ac                	ld	a1,72(s1)
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	f8c080e7          	jalr	-116(ra) # 80001d74 <proc_freepagetable>
  p->pagetable = 0;
    80001df0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001df4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001df8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001dfc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e00:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e04:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e08:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e0c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e10:	0004ac23          	sw	zero,24(s1)
}
    80001e14:	60e2                	ld	ra,24(sp)
    80001e16:	6442                	ld	s0,16(sp)
    80001e18:	64a2                	ld	s1,8(sp)
    80001e1a:	6105                	addi	sp,sp,32
    80001e1c:	8082                	ret

0000000080001e1e <allocproc>:
{
    80001e1e:	7179                	addi	sp,sp,-48
    80001e20:	f406                	sd	ra,40(sp)
    80001e22:	f022                	sd	s0,32(sp)
    80001e24:	ec26                	sd	s1,24(sp)
    80001e26:	e84a                	sd	s2,16(sp)
    80001e28:	e44e                	sd	s3,8(sp)
    80001e2a:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e2c:	00010497          	auipc	s1,0x10
    80001e30:	8a448493          	addi	s1,s1,-1884 # 800116d0 <proc>
    80001e34:	0001b997          	auipc	s3,0x1b
    80001e38:	49c98993          	addi	s3,s3,1180 # 8001d2d0 <tickslock>
    acquire(&p->lock);
    80001e3c:	8926                	mv	s2,s1
    80001e3e:	8526                	mv	a0,s1
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	d82080e7          	jalr	-638(ra) # 80000bc2 <acquire>
    if(p->state == UNUSED) {
    80001e48:	4c9c                	lw	a5,24(s1)
    80001e4a:	cf81                	beqz	a5,80001e62 <allocproc+0x44>
      release(&p->lock);
    80001e4c:	8526                	mv	a0,s1
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	e28080e7          	jalr	-472(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e56:	2f048493          	addi	s1,s1,752
    80001e5a:	ff3491e3          	bne	s1,s3,80001e3c <allocproc+0x1e>
  return 0;
    80001e5e:	4481                	li	s1,0
    80001e60:	a895                	j	80001ed4 <allocproc+0xb6>
  p->pid = allocpid();
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	e30080e7          	jalr	-464(ra) # 80001c92 <allocpid>
    80001e6a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e6c:	4785                	li	a5,1
    80001e6e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	c62080e7          	jalr	-926(ra) # 80000ad2 <kalloc>
    80001e78:	89aa                	mv	s3,a0
    80001e7a:	eca8                	sd	a0,88(s1)
    80001e7c:	c525                	beqz	a0,80001ee4 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	00000097          	auipc	ra,0x0
    80001e84:	e58080e7          	jalr	-424(ra) # 80001cd8 <proc_pagetable>
    80001e88:	89aa                	mv	s3,a0
    80001e8a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e8c:	c925                	beqz	a0,80001efc <allocproc+0xde>
  memset(&p->context, 0, sizeof(p->context));
    80001e8e:	07000613          	li	a2,112
    80001e92:	4581                	li	a1,0
    80001e94:	06048513          	addi	a0,s1,96
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	e26080e7          	jalr	-474(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001ea0:	00000797          	auipc	a5,0x0
    80001ea4:	dac78793          	addi	a5,a5,-596 # 80001c4c <forkret>
    80001ea8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eaa:	60bc                	ld	a5,64(s1)
    80001eac:	6705                	lui	a4,0x1
    80001eae:	97ba                	add	a5,a5,a4
    80001eb0:	f4bc                	sd	a5,104(s1)
  if(p->pid > 2){
    80001eb2:	5898                	lw	a4,48(s1)
    80001eb4:	4789                	li	a5,2
    80001eb6:	04e7cf63          	blt	a5,a4,80001f14 <allocproc+0xf6>
 for(int i=0;i<32;i++){
    80001eba:	17048793          	addi	a5,s1,368
    80001ebe:	2f090713          	addi	a4,s2,752
    p->paging_meta_data[i].offset = -1;
    80001ec2:	56fd                	li	a3,-1
    80001ec4:	c394                	sw	a3,0(a5)
    p->paging_meta_data[i].aging = 0;
    80001ec6:	0007a223          	sw	zero,4(a5)
    p->paging_meta_data[i].in_memory = 0;
    80001eca:	0007a423          	sw	zero,8(a5)
 for(int i=0;i<32;i++){
    80001ece:	07b1                	addi	a5,a5,12
    80001ed0:	fee79ae3          	bne	a5,a4,80001ec4 <allocproc+0xa6>
}
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	70a2                	ld	ra,40(sp)
    80001ed8:	7402                	ld	s0,32(sp)
    80001eda:	64e2                	ld	s1,24(sp)
    80001edc:	6942                	ld	s2,16(sp)
    80001ede:	69a2                	ld	s3,8(sp)
    80001ee0:	6145                	addi	sp,sp,48
    80001ee2:	8082                	ret
    freeproc(p);
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	ee0080e7          	jalr	-288(ra) # 80001dc6 <freeproc>
    release(&p->lock);
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	d86080e7          	jalr	-634(ra) # 80000c76 <release>
    return 0;
    80001ef8:	84ce                	mv	s1,s3
    80001efa:	bfe9                	j	80001ed4 <allocproc+0xb6>
    freeproc(p);
    80001efc:	8526                	mv	a0,s1
    80001efe:	00000097          	auipc	ra,0x0
    80001f02:	ec8080e7          	jalr	-312(ra) # 80001dc6 <freeproc>
    release(&p->lock);
    80001f06:	8526                	mv	a0,s1
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d6e080e7          	jalr	-658(ra) # 80000c76 <release>
    return 0;
    80001f10:	84ce                	mv	s1,s3
    80001f12:	b7c9                	j	80001ed4 <allocproc+0xb6>
    if(createSwapFile(p) != 0){
    80001f14:	8526                	mv	a0,s1
    80001f16:	00002097          	auipc	ra,0x2
    80001f1a:	4ac080e7          	jalr	1196(ra) # 800043c2 <createSwapFile>
    80001f1e:	dd51                	beqz	a0,80001eba <allocproc+0x9c>
      panic("create swap file failed");
    80001f20:	00006517          	auipc	a0,0x6
    80001f24:	36850513          	addi	a0,a0,872 # 80008288 <digits+0x248>
    80001f28:	ffffe097          	auipc	ra,0xffffe
    80001f2c:	602080e7          	jalr	1538(ra) # 8000052a <panic>

0000000080001f30 <userinit>:
{
    80001f30:	1101                	addi	sp,sp,-32
    80001f32:	ec06                	sd	ra,24(sp)
    80001f34:	e822                	sd	s0,16(sp)
    80001f36:	e426                	sd	s1,8(sp)
    80001f38:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f3a:	00000097          	auipc	ra,0x0
    80001f3e:	ee4080e7          	jalr	-284(ra) # 80001e1e <allocproc>
    80001f42:	84aa                	mv	s1,a0
  initproc = p;
    80001f44:	00007797          	auipc	a5,0x7
    80001f48:	0ea7b223          	sd	a0,228(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f4c:	03400613          	li	a2,52
    80001f50:	00007597          	auipc	a1,0x7
    80001f54:	9d058593          	addi	a1,a1,-1584 # 80008920 <initcode>
    80001f58:	6928                	ld	a0,80(a0)
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	3da080e7          	jalr	986(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001f62:	6785                	lui	a5,0x1
    80001f64:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f66:	6cb8                	ld	a4,88(s1)
    80001f68:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f6c:	6cb8                	ld	a4,88(s1)
    80001f6e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f70:	4641                	li	a2,16
    80001f72:	00006597          	auipc	a1,0x6
    80001f76:	32e58593          	addi	a1,a1,814 # 800082a0 <digits+0x260>
    80001f7a:	15848513          	addi	a0,s1,344
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	e92080e7          	jalr	-366(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001f86:	00006517          	auipc	a0,0x6
    80001f8a:	32a50513          	addi	a0,a0,810 # 800082b0 <digits+0x270>
    80001f8e:	00002097          	auipc	ra,0x2
    80001f92:	1e0080e7          	jalr	480(ra) # 8000416e <namei>
    80001f96:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001f9a:	478d                	li	a5,3
    80001f9c:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	cd6080e7          	jalr	-810(ra) # 80000c76 <release>
}
    80001fa8:	60e2                	ld	ra,24(sp)
    80001faa:	6442                	ld	s0,16(sp)
    80001fac:	64a2                	ld	s1,8(sp)
    80001fae:	6105                	addi	sp,sp,32
    80001fb0:	8082                	ret

0000000080001fb2 <growproc>:
{
    80001fb2:	1101                	addi	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	e04a                	sd	s2,0(sp)
    80001fbc:	1000                	addi	s0,sp,32
    80001fbe:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	c54080e7          	jalr	-940(ra) # 80001c14 <myproc>
    80001fc8:	892a                	mv	s2,a0
  sz = p->sz;
    80001fca:	652c                	ld	a1,72(a0)
    80001fcc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001fd0:	00904f63          	bgtz	s1,80001fee <growproc+0x3c>
  } else if(n < 0){
    80001fd4:	0204cc63          	bltz	s1,8000200c <growproc+0x5a>
  p->sz = sz;
    80001fd8:	1602                	slli	a2,a2,0x20
    80001fda:	9201                	srli	a2,a2,0x20
    80001fdc:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fe0:	4501                	li	a0,0
}
    80001fe2:	60e2                	ld	ra,24(sp)
    80001fe4:	6442                	ld	s0,16(sp)
    80001fe6:	64a2                	ld	s1,8(sp)
    80001fe8:	6902                	ld	s2,0(sp)
    80001fea:	6105                	addi	sp,sp,32
    80001fec:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fee:	9e25                	addw	a2,a2,s1
    80001ff0:	1602                	slli	a2,a2,0x20
    80001ff2:	9201                	srli	a2,a2,0x20
    80001ff4:	1582                	slli	a1,a1,0x20
    80001ff6:	9181                	srli	a1,a1,0x20
    80001ff8:	6928                	ld	a0,80(a0)
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	3f4080e7          	jalr	1012(ra) # 800013ee <uvmalloc>
    80002002:	0005061b          	sext.w	a2,a0
    80002006:	fa69                	bnez	a2,80001fd8 <growproc+0x26>
      return -1;
    80002008:	557d                	li	a0,-1
    8000200a:	bfe1                	j	80001fe2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000200c:	9e25                	addw	a2,a2,s1
    8000200e:	1602                	slli	a2,a2,0x20
    80002010:	9201                	srli	a2,a2,0x20
    80002012:	1582                	slli	a1,a1,0x20
    80002014:	9181                	srli	a1,a1,0x20
    80002016:	6928                	ld	a0,80(a0)
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	38e080e7          	jalr	910(ra) # 800013a6 <uvmdealloc>
    80002020:	0005061b          	sext.w	a2,a0
    80002024:	bf55                	j	80001fd8 <growproc+0x26>

0000000080002026 <copy_swap_file>:
copy_swap_file(struct proc* child){
    80002026:	715d                	addi	sp,sp,-80
    80002028:	e486                	sd	ra,72(sp)
    8000202a:	e0a2                	sd	s0,64(sp)
    8000202c:	fc26                	sd	s1,56(sp)
    8000202e:	f84a                	sd	s2,48(sp)
    80002030:	f44e                	sd	s3,40(sp)
    80002032:	f052                	sd	s4,32(sp)
    80002034:	ec56                	sd	s5,24(sp)
    80002036:	e85a                	sd	s6,16(sp)
    80002038:	0880                	addi	s0,sp,80
    8000203a:	737d                	lui	t1,0xfffff
    8000203c:	0341                	addi	t1,t1,16
    8000203e:	911a                	add	sp,sp,t1
    80002040:	8aaa                	mv	s5,a0
  struct proc * pParent = myproc();
    80002042:	00000097          	auipc	ra,0x0
    80002046:	bd2080e7          	jalr	-1070(ra) # 80001c14 <myproc>
  for(int i = 0; i < pParent->sz; i += PGSIZE){
    8000204a:	653c                	ld	a5,72(a0)
    8000204c:	c3d9                	beqz	a5,800020d2 <copy_swap_file+0xac>
    8000204e:	892a                	mv	s2,a0
    80002050:	4481                	li	s1,0
    if(offset != -1){
    80002052:	59fd                	li	s3,-1
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    80002054:	7a7d                	lui	s4,0xfffff
    80002056:	fc040793          	addi	a5,s0,-64
    8000205a:	9a3e                	add	s4,s4,a5
    8000205c:	a839                	j	8000207a <copy_swap_file+0x54>
          panic("read failed\n");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	25a50513          	addi	a0,a0,602 # 800082b8 <digits+0x278>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4c4080e7          	jalr	1220(ra) # 8000052a <panic>
  for(int i = 0; i < pParent->sz; i += PGSIZE){
    8000206e:	6785                	lui	a5,0x1
    80002070:	94be                	add	s1,s1,a5
    80002072:	04893783          	ld	a5,72(s2)
    80002076:	04f4fe63          	bgeu	s1,a5,800020d2 <copy_swap_file+0xac>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    8000207a:	41f4d79b          	sraiw	a5,s1,0x1f
    8000207e:	0147d79b          	srliw	a5,a5,0x14
    80002082:	9fa5                	addw	a5,a5,s1
    80002084:	40c7d79b          	sraiw	a5,a5,0xc
    80002088:	00179713          	slli	a4,a5,0x1
    8000208c:	97ba                	add	a5,a5,a4
    8000208e:	078a                	slli	a5,a5,0x2
    80002090:	97ca                	add	a5,a5,s2
    80002092:	1707ab03          	lw	s6,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    80002096:	fd3b0ce3          	beq	s6,s3,8000206e <copy_swap_file+0x48>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    8000209a:	6685                	lui	a3,0x1
    8000209c:	865a                	mv	a2,s6
    8000209e:	85d2                	mv	a1,s4
    800020a0:	854a                	mv	a0,s2
    800020a2:	00002097          	auipc	ra,0x2
    800020a6:	3f4080e7          	jalr	1012(ra) # 80004496 <readFromSwapFile>
    800020aa:	fb350ae3          	beq	a0,s3,8000205e <copy_swap_file+0x38>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    800020ae:	6685                	lui	a3,0x1
    800020b0:	865a                	mv	a2,s6
    800020b2:	85d2                	mv	a1,s4
    800020b4:	8556                	mv	a0,s5
    800020b6:	00002097          	auipc	ra,0x2
    800020ba:	3bc080e7          	jalr	956(ra) # 80004472 <writeToSwapFile>
    800020be:	fb3518e3          	bne	a0,s3,8000206e <copy_swap_file+0x48>
          panic("write failed\n");
    800020c2:	00006517          	auipc	a0,0x6
    800020c6:	20650513          	addi	a0,a0,518 # 800082c8 <digits+0x288>
    800020ca:	ffffe097          	auipc	ra,0xffffe
    800020ce:	460080e7          	jalr	1120(ra) # 8000052a <panic>
}
    800020d2:	6305                	lui	t1,0x1
    800020d4:	1341                	addi	t1,t1,-16
    800020d6:	911a                	add	sp,sp,t1
    800020d8:	60a6                	ld	ra,72(sp)
    800020da:	6406                	ld	s0,64(sp)
    800020dc:	74e2                	ld	s1,56(sp)
    800020de:	7942                	ld	s2,48(sp)
    800020e0:	79a2                	ld	s3,40(sp)
    800020e2:	7a02                	ld	s4,32(sp)
    800020e4:	6ae2                	ld	s5,24(sp)
    800020e6:	6b42                	ld	s6,16(sp)
    800020e8:	6161                	addi	sp,sp,80
    800020ea:	8082                	ret

00000000800020ec <fork>:
{
    800020ec:	7139                	addi	sp,sp,-64
    800020ee:	fc06                	sd	ra,56(sp)
    800020f0:	f822                	sd	s0,48(sp)
    800020f2:	f426                	sd	s1,40(sp)
    800020f4:	f04a                	sd	s2,32(sp)
    800020f6:	ec4e                	sd	s3,24(sp)
    800020f8:	e852                	sd	s4,16(sp)
    800020fa:	e456                	sd	s5,8(sp)
    800020fc:	e05a                	sd	s6,0(sp)
    800020fe:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002100:	00000097          	auipc	ra,0x0
    80002104:	b14080e7          	jalr	-1260(ra) # 80001c14 <myproc>
    80002108:	8b2a                	mv	s6,a0
  if((np = allocproc()) == 0){
    8000210a:	00000097          	auipc	ra,0x0
    8000210e:	d14080e7          	jalr	-748(ra) # 80001e1e <allocproc>
    80002112:	18050663          	beqz	a0,8000229e <fork+0x1b2>
    80002116:	8aaa                	mv	s5,a0
  if(p->pid > 2){ 
    80002118:	030b2703          	lw	a4,48(s6)
    8000211c:	4789                	li	a5,2
    8000211e:	0ce7c263          	blt	a5,a4,800021e2 <fork+0xf6>
  for(int i=0; i<32; i++){
    80002122:	170a8993          	addi	s3,s5,368
{
    80002126:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    80002128:	02000a13          	li	s4,32
    np->paging_meta_data[i].offset = myproc()->paging_meta_data[i].offset;
    8000212c:	00000097          	auipc	ra,0x0
    80002130:	ae8080e7          	jalr	-1304(ra) # 80001c14 <myproc>
    80002134:	00191493          	slli	s1,s2,0x1
    80002138:	012487b3          	add	a5,s1,s2
    8000213c:	078a                	slli	a5,a5,0x2
    8000213e:	953e                	add	a0,a0,a5
    80002140:	17052783          	lw	a5,368(a0)
    80002144:	00f9a023          	sw	a5,0(s3)
    np->paging_meta_data[i].aging = myproc()->paging_meta_data[i].aging;
    80002148:	00000097          	auipc	ra,0x0
    8000214c:	acc080e7          	jalr	-1332(ra) # 80001c14 <myproc>
    80002150:	012487b3          	add	a5,s1,s2
    80002154:	078a                	slli	a5,a5,0x2
    80002156:	953e                	add	a0,a0,a5
    80002158:	17452783          	lw	a5,372(a0)
    8000215c:	00f9a223          	sw	a5,4(s3)
    np->paging_meta_data[i].in_memory = myproc()->paging_meta_data[i].in_memory;
    80002160:	00000097          	auipc	ra,0x0
    80002164:	ab4080e7          	jalr	-1356(ra) # 80001c14 <myproc>
    80002168:	94ca                	add	s1,s1,s2
    8000216a:	048a                	slli	s1,s1,0x2
    8000216c:	94aa                	add	s1,s1,a0
    8000216e:	1784a783          	lw	a5,376(s1)
    80002172:	00f9a423          	sw	a5,8(s3)
  for(int i=0; i<32; i++){
    80002176:	2905                	addiw	s2,s2,1
    80002178:	09b1                	addi	s3,s3,12
    8000217a:	fb4919e3          	bne	s2,s4,8000212c <fork+0x40>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000217e:	048b3603          	ld	a2,72(s6)
    80002182:	050ab583          	ld	a1,80(s5)
    80002186:	050b3503          	ld	a0,80(s6)
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	3b0080e7          	jalr	944(ra) # 8000153a <uvmcopy>
    80002192:	04054d63          	bltz	a0,800021ec <fork+0x100>
  np->sz = p->sz;
    80002196:	048b3783          	ld	a5,72(s6)
    8000219a:	04fab423          	sd	a5,72(s5)
  *(np->trapframe) = *(p->trapframe);
    8000219e:	058b3683          	ld	a3,88(s6)
    800021a2:	87b6                	mv	a5,a3
    800021a4:	058ab703          	ld	a4,88(s5)
    800021a8:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800021ac:	0007b803          	ld	a6,0(a5)
    800021b0:	6788                	ld	a0,8(a5)
    800021b2:	6b8c                	ld	a1,16(a5)
    800021b4:	6f90                	ld	a2,24(a5)
    800021b6:	01073023          	sd	a6,0(a4)
    800021ba:	e708                	sd	a0,8(a4)
    800021bc:	eb0c                	sd	a1,16(a4)
    800021be:	ef10                	sd	a2,24(a4)
    800021c0:	02078793          	addi	a5,a5,32
    800021c4:	02070713          	addi	a4,a4,32
    800021c8:	fed792e3          	bne	a5,a3,800021ac <fork+0xc0>
  np->trapframe->a0 = 0;
    800021cc:	058ab783          	ld	a5,88(s5)
    800021d0:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800021d4:	0d0b0493          	addi	s1,s6,208
    800021d8:	0d0a8913          	addi	s2,s5,208
    800021dc:	150b0993          	addi	s3,s6,336
    800021e0:	a035                	j	8000220c <fork+0x120>
    copy_swap_file(np);
    800021e2:	00000097          	auipc	ra,0x0
    800021e6:	e44080e7          	jalr	-444(ra) # 80002026 <copy_swap_file>
    800021ea:	bf25                	j	80002122 <fork+0x36>
    freeproc(np);
    800021ec:	8556                	mv	a0,s5
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	bd8080e7          	jalr	-1064(ra) # 80001dc6 <freeproc>
    release(&np->lock);
    800021f6:	8556                	mv	a0,s5
    800021f8:	fffff097          	auipc	ra,0xfffff
    800021fc:	a7e080e7          	jalr	-1410(ra) # 80000c76 <release>
    return -1;
    80002200:	597d                	li	s2,-1
    80002202:	a059                	j	80002288 <fork+0x19c>
  for(i = 0; i < NOFILE; i++)
    80002204:	04a1                	addi	s1,s1,8
    80002206:	0921                	addi	s2,s2,8
    80002208:	01348b63          	beq	s1,s3,8000221e <fork+0x132>
    if(p->ofile[i])
    8000220c:	6088                	ld	a0,0(s1)
    8000220e:	d97d                	beqz	a0,80002204 <fork+0x118>
      np->ofile[i] = filedup(p->ofile[i]);
    80002210:	00003097          	auipc	ra,0x3
    80002214:	90a080e7          	jalr	-1782(ra) # 80004b1a <filedup>
    80002218:	00a93023          	sd	a0,0(s2)
    8000221c:	b7e5                	j	80002204 <fork+0x118>
  np->cwd = idup(p->cwd);
    8000221e:	150b3503          	ld	a0,336(s6)
    80002222:	00001097          	auipc	ra,0x1
    80002226:	758080e7          	jalr	1880(ra) # 8000397a <idup>
    8000222a:	14aab823          	sd	a0,336(s5)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000222e:	4641                	li	a2,16
    80002230:	158b0593          	addi	a1,s6,344
    80002234:	158a8513          	addi	a0,s5,344
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	bd8080e7          	jalr	-1064(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80002240:	030aa903          	lw	s2,48(s5)
  release(&np->lock);
    80002244:	8556                	mv	a0,s5
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a30080e7          	jalr	-1488(ra) # 80000c76 <release>
  acquire(&wait_lock);
    8000224e:	0000f497          	auipc	s1,0xf
    80002252:	06a48493          	addi	s1,s1,106 # 800112b8 <wait_lock>
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	96a080e7          	jalr	-1686(ra) # 80000bc2 <acquire>
  np->parent = p;
    80002260:	036abc23          	sd	s6,56(s5)
  release(&wait_lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a10080e7          	jalr	-1520(ra) # 80000c76 <release>
  acquire(&np->lock);
    8000226e:	8556                	mv	a0,s5
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	952080e7          	jalr	-1710(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80002278:	478d                	li	a5,3
    8000227a:	00faac23          	sw	a5,24(s5)
  release(&np->lock);
    8000227e:	8556                	mv	a0,s5
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	9f6080e7          	jalr	-1546(ra) # 80000c76 <release>
}
    80002288:	854a                	mv	a0,s2
    8000228a:	70e2                	ld	ra,56(sp)
    8000228c:	7442                	ld	s0,48(sp)
    8000228e:	74a2                	ld	s1,40(sp)
    80002290:	7902                	ld	s2,32(sp)
    80002292:	69e2                	ld	s3,24(sp)
    80002294:	6a42                	ld	s4,16(sp)
    80002296:	6aa2                	ld	s5,8(sp)
    80002298:	6b02                	ld	s6,0(sp)
    8000229a:	6121                	addi	sp,sp,64
    8000229c:	8082                	ret
    return -1;
    8000229e:	597d                	li	s2,-1
    800022a0:	b7e5                	j	80002288 <fork+0x19c>

00000000800022a2 <scheduler>:
{
    800022a2:	7139                	addi	sp,sp,-64
    800022a4:	fc06                	sd	ra,56(sp)
    800022a6:	f822                	sd	s0,48(sp)
    800022a8:	f426                	sd	s1,40(sp)
    800022aa:	f04a                	sd	s2,32(sp)
    800022ac:	ec4e                	sd	s3,24(sp)
    800022ae:	e852                	sd	s4,16(sp)
    800022b0:	e456                	sd	s5,8(sp)
    800022b2:	e05a                	sd	s6,0(sp)
    800022b4:	0080                	addi	s0,sp,64
    800022b6:	8792                	mv	a5,tp
  int id = r_tp();
    800022b8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022ba:	00779a93          	slli	s5,a5,0x7
    800022be:	0000f717          	auipc	a4,0xf
    800022c2:	fe270713          	addi	a4,a4,-30 # 800112a0 <pid_lock>
    800022c6:	9756                	add	a4,a4,s5
    800022c8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800022cc:	0000f717          	auipc	a4,0xf
    800022d0:	00c70713          	addi	a4,a4,12 # 800112d8 <cpus+0x8>
    800022d4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800022d6:	498d                	li	s3,3
        p->state = RUNNING;
    800022d8:	4b11                	li	s6,4
        c->proc = p;
    800022da:	079e                	slli	a5,a5,0x7
    800022dc:	0000fa17          	auipc	s4,0xf
    800022e0:	fc4a0a13          	addi	s4,s4,-60 # 800112a0 <pid_lock>
    800022e4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800022e6:	0001b917          	auipc	s2,0x1b
    800022ea:	fea90913          	addi	s2,s2,-22 # 8001d2d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022f2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022f6:	10079073          	csrw	sstatus,a5
    800022fa:	0000f497          	auipc	s1,0xf
    800022fe:	3d648493          	addi	s1,s1,982 # 800116d0 <proc>
    80002302:	a811                	j	80002316 <scheduler+0x74>
      release(&p->lock);
    80002304:	8526                	mv	a0,s1
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	970080e7          	jalr	-1680(ra) # 80000c76 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000230e:	2f048493          	addi	s1,s1,752
    80002312:	fd248ee3          	beq	s1,s2,800022ee <scheduler+0x4c>
      acquire(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8aa080e7          	jalr	-1878(ra) # 80000bc2 <acquire>
      if(p->state == RUNNABLE) {
    80002320:	4c9c                	lw	a5,24(s1)
    80002322:	ff3791e3          	bne	a5,s3,80002304 <scheduler+0x62>
        p->state = RUNNING;
    80002326:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000232a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000232e:	06048593          	addi	a1,s1,96
    80002332:	8556                	mv	a0,s5
    80002334:	00000097          	auipc	ra,0x0
    80002338:	620080e7          	jalr	1568(ra) # 80002954 <swtch>
        c->proc = 0;
    8000233c:	020a3823          	sd	zero,48(s4)
    80002340:	b7d1                	j	80002304 <scheduler+0x62>

0000000080002342 <sched>:
{
    80002342:	7179                	addi	sp,sp,-48
    80002344:	f406                	sd	ra,40(sp)
    80002346:	f022                	sd	s0,32(sp)
    80002348:	ec26                	sd	s1,24(sp)
    8000234a:	e84a                	sd	s2,16(sp)
    8000234c:	e44e                	sd	s3,8(sp)
    8000234e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002350:	00000097          	auipc	ra,0x0
    80002354:	8c4080e7          	jalr	-1852(ra) # 80001c14 <myproc>
    80002358:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000235a:	ffffe097          	auipc	ra,0xffffe
    8000235e:	7ee080e7          	jalr	2030(ra) # 80000b48 <holding>
    80002362:	c93d                	beqz	a0,800023d8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002364:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002366:	2781                	sext.w	a5,a5
    80002368:	079e                	slli	a5,a5,0x7
    8000236a:	0000f717          	auipc	a4,0xf
    8000236e:	f3670713          	addi	a4,a4,-202 # 800112a0 <pid_lock>
    80002372:	97ba                	add	a5,a5,a4
    80002374:	0a87a703          	lw	a4,168(a5)
    80002378:	4785                	li	a5,1
    8000237a:	06f71763          	bne	a4,a5,800023e8 <sched+0xa6>
  if(p->state == RUNNING)
    8000237e:	4c98                	lw	a4,24(s1)
    80002380:	4791                	li	a5,4
    80002382:	06f70b63          	beq	a4,a5,800023f8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002386:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000238a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000238c:	efb5                	bnez	a5,80002408 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000238e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002390:	0000f917          	auipc	s2,0xf
    80002394:	f1090913          	addi	s2,s2,-240 # 800112a0 <pid_lock>
    80002398:	2781                	sext.w	a5,a5
    8000239a:	079e                	slli	a5,a5,0x7
    8000239c:	97ca                	add	a5,a5,s2
    8000239e:	0ac7a983          	lw	s3,172(a5)
    800023a2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023a4:	2781                	sext.w	a5,a5
    800023a6:	079e                	slli	a5,a5,0x7
    800023a8:	0000f597          	auipc	a1,0xf
    800023ac:	f3058593          	addi	a1,a1,-208 # 800112d8 <cpus+0x8>
    800023b0:	95be                	add	a1,a1,a5
    800023b2:	06048513          	addi	a0,s1,96
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	59e080e7          	jalr	1438(ra) # 80002954 <swtch>
    800023be:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023c0:	2781                	sext.w	a5,a5
    800023c2:	079e                	slli	a5,a5,0x7
    800023c4:	97ca                	add	a5,a5,s2
    800023c6:	0b37a623          	sw	s3,172(a5)
}
    800023ca:	70a2                	ld	ra,40(sp)
    800023cc:	7402                	ld	s0,32(sp)
    800023ce:	64e2                	ld	s1,24(sp)
    800023d0:	6942                	ld	s2,16(sp)
    800023d2:	69a2                	ld	s3,8(sp)
    800023d4:	6145                	addi	sp,sp,48
    800023d6:	8082                	ret
    panic("sched p->lock");
    800023d8:	00006517          	auipc	a0,0x6
    800023dc:	f0050513          	addi	a0,a0,-256 # 800082d8 <digits+0x298>
    800023e0:	ffffe097          	auipc	ra,0xffffe
    800023e4:	14a080e7          	jalr	330(ra) # 8000052a <panic>
    panic("sched locks");
    800023e8:	00006517          	auipc	a0,0x6
    800023ec:	f0050513          	addi	a0,a0,-256 # 800082e8 <digits+0x2a8>
    800023f0:	ffffe097          	auipc	ra,0xffffe
    800023f4:	13a080e7          	jalr	314(ra) # 8000052a <panic>
    panic("sched running");
    800023f8:	00006517          	auipc	a0,0x6
    800023fc:	f0050513          	addi	a0,a0,-256 # 800082f8 <digits+0x2b8>
    80002400:	ffffe097          	auipc	ra,0xffffe
    80002404:	12a080e7          	jalr	298(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002408:	00006517          	auipc	a0,0x6
    8000240c:	f0050513          	addi	a0,a0,-256 # 80008308 <digits+0x2c8>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	11a080e7          	jalr	282(ra) # 8000052a <panic>

0000000080002418 <yield>:
{
    80002418:	1101                	addi	sp,sp,-32
    8000241a:	ec06                	sd	ra,24(sp)
    8000241c:	e822                	sd	s0,16(sp)
    8000241e:	e426                	sd	s1,8(sp)
    80002420:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	7f2080e7          	jalr	2034(ra) # 80001c14 <myproc>
    8000242a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	796080e7          	jalr	1942(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    80002434:	478d                	li	a5,3
    80002436:	cc9c                	sw	a5,24(s1)
  sched();
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	f0a080e7          	jalr	-246(ra) # 80002342 <sched>
  release(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	834080e7          	jalr	-1996(ra) # 80000c76 <release>
}
    8000244a:	60e2                	ld	ra,24(sp)
    8000244c:	6442                	ld	s0,16(sp)
    8000244e:	64a2                	ld	s1,8(sp)
    80002450:	6105                	addi	sp,sp,32
    80002452:	8082                	ret

0000000080002454 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002454:	7179                	addi	sp,sp,-48
    80002456:	f406                	sd	ra,40(sp)
    80002458:	f022                	sd	s0,32(sp)
    8000245a:	ec26                	sd	s1,24(sp)
    8000245c:	e84a                	sd	s2,16(sp)
    8000245e:	e44e                	sd	s3,8(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	89aa                	mv	s3,a0
    80002464:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	7ae080e7          	jalr	1966(ra) # 80001c14 <myproc>
    8000246e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	752080e7          	jalr	1874(ra) # 80000bc2 <acquire>
  release(lk);
    80002478:	854a                	mv	a0,s2
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	7fc080e7          	jalr	2044(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    80002482:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002486:	4789                	li	a5,2
    80002488:	cc9c                	sw	a5,24(s1)

  sched();
    8000248a:	00000097          	auipc	ra,0x0
    8000248e:	eb8080e7          	jalr	-328(ra) # 80002342 <sched>

  // Tidy up.
  p->chan = 0;
    80002492:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	7de080e7          	jalr	2014(ra) # 80000c76 <release>
  acquire(lk);
    800024a0:	854a                	mv	a0,s2
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	720080e7          	jalr	1824(ra) # 80000bc2 <acquire>
}
    800024aa:	70a2                	ld	ra,40(sp)
    800024ac:	7402                	ld	s0,32(sp)
    800024ae:	64e2                	ld	s1,24(sp)
    800024b0:	6942                	ld	s2,16(sp)
    800024b2:	69a2                	ld	s3,8(sp)
    800024b4:	6145                	addi	sp,sp,48
    800024b6:	8082                	ret

00000000800024b8 <wait>:
{
    800024b8:	715d                	addi	sp,sp,-80
    800024ba:	e486                	sd	ra,72(sp)
    800024bc:	e0a2                	sd	s0,64(sp)
    800024be:	fc26                	sd	s1,56(sp)
    800024c0:	f84a                	sd	s2,48(sp)
    800024c2:	f44e                	sd	s3,40(sp)
    800024c4:	f052                	sd	s4,32(sp)
    800024c6:	ec56                	sd	s5,24(sp)
    800024c8:	e85a                	sd	s6,16(sp)
    800024ca:	e45e                	sd	s7,8(sp)
    800024cc:	e062                	sd	s8,0(sp)
    800024ce:	0880                	addi	s0,sp,80
    800024d0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	742080e7          	jalr	1858(ra) # 80001c14 <myproc>
    800024da:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024dc:	0000f517          	auipc	a0,0xf
    800024e0:	ddc50513          	addi	a0,a0,-548 # 800112b8 <wait_lock>
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	6de080e7          	jalr	1758(ra) # 80000bc2 <acquire>
    havekids = 0;
    800024ec:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024ee:	4a15                	li	s4,5
        havekids = 1;
    800024f0:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    800024f2:	0001b997          	auipc	s3,0x1b
    800024f6:	dde98993          	addi	s3,s3,-546 # 8001d2d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024fa:	0000fc17          	auipc	s8,0xf
    800024fe:	dbec0c13          	addi	s8,s8,-578 # 800112b8 <wait_lock>
    havekids = 0;
    80002502:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002504:	0000f497          	auipc	s1,0xf
    80002508:	1cc48493          	addi	s1,s1,460 # 800116d0 <proc>
    8000250c:	a0bd                	j	8000257a <wait+0xc2>
          pid = np->pid;
    8000250e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002512:	000b0e63          	beqz	s6,8000252e <wait+0x76>
    80002516:	4691                	li	a3,4
    80002518:	02c48613          	addi	a2,s1,44
    8000251c:	85da                	mv	a1,s6
    8000251e:	05093503          	ld	a0,80(s2)
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	11c080e7          	jalr	284(ra) # 8000163e <copyout>
    8000252a:	02054563          	bltz	a0,80002554 <wait+0x9c>
          freeproc(np);
    8000252e:	8526                	mv	a0,s1
    80002530:	00000097          	auipc	ra,0x0
    80002534:	896080e7          	jalr	-1898(ra) # 80001dc6 <freeproc>
          release(&np->lock);
    80002538:	8526                	mv	a0,s1
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	73c080e7          	jalr	1852(ra) # 80000c76 <release>
          release(&wait_lock);
    80002542:	0000f517          	auipc	a0,0xf
    80002546:	d7650513          	addi	a0,a0,-650 # 800112b8 <wait_lock>
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	72c080e7          	jalr	1836(ra) # 80000c76 <release>
          return pid;
    80002552:	a09d                	j	800025b8 <wait+0x100>
            release(&np->lock);
    80002554:	8526                	mv	a0,s1
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	720080e7          	jalr	1824(ra) # 80000c76 <release>
            release(&wait_lock);
    8000255e:	0000f517          	auipc	a0,0xf
    80002562:	d5a50513          	addi	a0,a0,-678 # 800112b8 <wait_lock>
    80002566:	ffffe097          	auipc	ra,0xffffe
    8000256a:	710080e7          	jalr	1808(ra) # 80000c76 <release>
            return -1;
    8000256e:	59fd                	li	s3,-1
    80002570:	a0a1                	j	800025b8 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002572:	2f048493          	addi	s1,s1,752
    80002576:	03348463          	beq	s1,s3,8000259e <wait+0xe6>
      if(np->parent == p){
    8000257a:	7c9c                	ld	a5,56(s1)
    8000257c:	ff279be3          	bne	a5,s2,80002572 <wait+0xba>
        acquire(&np->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	640080e7          	jalr	1600(ra) # 80000bc2 <acquire>
        if(np->state == ZOMBIE){
    8000258a:	4c9c                	lw	a5,24(s1)
    8000258c:	f94781e3          	beq	a5,s4,8000250e <wait+0x56>
        release(&np->lock);
    80002590:	8526                	mv	a0,s1
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	6e4080e7          	jalr	1764(ra) # 80000c76 <release>
        havekids = 1;
    8000259a:	8756                	mv	a4,s5
    8000259c:	bfd9                	j	80002572 <wait+0xba>
    if(!havekids || p->killed){
    8000259e:	c701                	beqz	a4,800025a6 <wait+0xee>
    800025a0:	02892783          	lw	a5,40(s2)
    800025a4:	c79d                	beqz	a5,800025d2 <wait+0x11a>
      release(&wait_lock);
    800025a6:	0000f517          	auipc	a0,0xf
    800025aa:	d1250513          	addi	a0,a0,-750 # 800112b8 <wait_lock>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6c8080e7          	jalr	1736(ra) # 80000c76 <release>
      return -1;
    800025b6:	59fd                	li	s3,-1
}
    800025b8:	854e                	mv	a0,s3
    800025ba:	60a6                	ld	ra,72(sp)
    800025bc:	6406                	ld	s0,64(sp)
    800025be:	74e2                	ld	s1,56(sp)
    800025c0:	7942                	ld	s2,48(sp)
    800025c2:	79a2                	ld	s3,40(sp)
    800025c4:	7a02                	ld	s4,32(sp)
    800025c6:	6ae2                	ld	s5,24(sp)
    800025c8:	6b42                	ld	s6,16(sp)
    800025ca:	6ba2                	ld	s7,8(sp)
    800025cc:	6c02                	ld	s8,0(sp)
    800025ce:	6161                	addi	sp,sp,80
    800025d0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800025d2:	85e2                	mv	a1,s8
    800025d4:	854a                	mv	a0,s2
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	e7e080e7          	jalr	-386(ra) # 80002454 <sleep>
    havekids = 0;
    800025de:	b715                	j	80002502 <wait+0x4a>

00000000800025e0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800025e0:	7139                	addi	sp,sp,-64
    800025e2:	fc06                	sd	ra,56(sp)
    800025e4:	f822                	sd	s0,48(sp)
    800025e6:	f426                	sd	s1,40(sp)
    800025e8:	f04a                	sd	s2,32(sp)
    800025ea:	ec4e                	sd	s3,24(sp)
    800025ec:	e852                	sd	s4,16(sp)
    800025ee:	e456                	sd	s5,8(sp)
    800025f0:	0080                	addi	s0,sp,64
    800025f2:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	0dc48493          	addi	s1,s1,220 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800025fc:	4989                	li	s3,2
        p->state = RUNNABLE;
    800025fe:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002600:	0001b917          	auipc	s2,0x1b
    80002604:	cd090913          	addi	s2,s2,-816 # 8001d2d0 <tickslock>
    80002608:	a811                	j	8000261c <wakeup+0x3c>
      }
      release(&p->lock);
    8000260a:	8526                	mv	a0,s1
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	66a080e7          	jalr	1642(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002614:	2f048493          	addi	s1,s1,752
    80002618:	03248663          	beq	s1,s2,80002644 <wakeup+0x64>
    if(p != myproc()){
    8000261c:	fffff097          	auipc	ra,0xfffff
    80002620:	5f8080e7          	jalr	1528(ra) # 80001c14 <myproc>
    80002624:	fea488e3          	beq	s1,a0,80002614 <wakeup+0x34>
      acquire(&p->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	598080e7          	jalr	1432(ra) # 80000bc2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002632:	4c9c                	lw	a5,24(s1)
    80002634:	fd379be3          	bne	a5,s3,8000260a <wakeup+0x2a>
    80002638:	709c                	ld	a5,32(s1)
    8000263a:	fd4798e3          	bne	a5,s4,8000260a <wakeup+0x2a>
        p->state = RUNNABLE;
    8000263e:	0154ac23          	sw	s5,24(s1)
    80002642:	b7e1                	j	8000260a <wakeup+0x2a>
    }
  }
}
    80002644:	70e2                	ld	ra,56(sp)
    80002646:	7442                	ld	s0,48(sp)
    80002648:	74a2                	ld	s1,40(sp)
    8000264a:	7902                	ld	s2,32(sp)
    8000264c:	69e2                	ld	s3,24(sp)
    8000264e:	6a42                	ld	s4,16(sp)
    80002650:	6aa2                	ld	s5,8(sp)
    80002652:	6121                	addi	sp,sp,64
    80002654:	8082                	ret

0000000080002656 <reparent>:
{
    80002656:	7179                	addi	sp,sp,-48
    80002658:	f406                	sd	ra,40(sp)
    8000265a:	f022                	sd	s0,32(sp)
    8000265c:	ec26                	sd	s1,24(sp)
    8000265e:	e84a                	sd	s2,16(sp)
    80002660:	e44e                	sd	s3,8(sp)
    80002662:	e052                	sd	s4,0(sp)
    80002664:	1800                	addi	s0,sp,48
    80002666:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002668:	0000f497          	auipc	s1,0xf
    8000266c:	06848493          	addi	s1,s1,104 # 800116d0 <proc>
      pp->parent = initproc;
    80002670:	00007a17          	auipc	s4,0x7
    80002674:	9b8a0a13          	addi	s4,s4,-1608 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002678:	0001b997          	auipc	s3,0x1b
    8000267c:	c5898993          	addi	s3,s3,-936 # 8001d2d0 <tickslock>
    80002680:	a029                	j	8000268a <reparent+0x34>
    80002682:	2f048493          	addi	s1,s1,752
    80002686:	01348d63          	beq	s1,s3,800026a0 <reparent+0x4a>
    if(pp->parent == p){
    8000268a:	7c9c                	ld	a5,56(s1)
    8000268c:	ff279be3          	bne	a5,s2,80002682 <reparent+0x2c>
      pp->parent = initproc;
    80002690:	000a3503          	ld	a0,0(s4)
    80002694:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002696:	00000097          	auipc	ra,0x0
    8000269a:	f4a080e7          	jalr	-182(ra) # 800025e0 <wakeup>
    8000269e:	b7d5                	j	80002682 <reparent+0x2c>
}
    800026a0:	70a2                	ld	ra,40(sp)
    800026a2:	7402                	ld	s0,32(sp)
    800026a4:	64e2                	ld	s1,24(sp)
    800026a6:	6942                	ld	s2,16(sp)
    800026a8:	69a2                	ld	s3,8(sp)
    800026aa:	6a02                	ld	s4,0(sp)
    800026ac:	6145                	addi	sp,sp,48
    800026ae:	8082                	ret

00000000800026b0 <exit>:
{
    800026b0:	7179                	addi	sp,sp,-48
    800026b2:	f406                	sd	ra,40(sp)
    800026b4:	f022                	sd	s0,32(sp)
    800026b6:	ec26                	sd	s1,24(sp)
    800026b8:	e84a                	sd	s2,16(sp)
    800026ba:	e44e                	sd	s3,8(sp)
    800026bc:	e052                	sd	s4,0(sp)
    800026be:	1800                	addi	s0,sp,48
    800026c0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026c2:	fffff097          	auipc	ra,0xfffff
    800026c6:	552080e7          	jalr	1362(ra) # 80001c14 <myproc>
    800026ca:	89aa                	mv	s3,a0
  if(p == initproc)
    800026cc:	00007797          	auipc	a5,0x7
    800026d0:	95c7b783          	ld	a5,-1700(a5) # 80009028 <initproc>
    800026d4:	0d050493          	addi	s1,a0,208
    800026d8:	15050913          	addi	s2,a0,336
    800026dc:	02a79363          	bne	a5,a0,80002702 <exit+0x52>
    panic("init exiting");
    800026e0:	00006517          	auipc	a0,0x6
    800026e4:	c4050513          	addi	a0,a0,-960 # 80008320 <digits+0x2e0>
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	e42080e7          	jalr	-446(ra) # 8000052a <panic>
      fileclose(f);
    800026f0:	00002097          	auipc	ra,0x2
    800026f4:	47c080e7          	jalr	1148(ra) # 80004b6c <fileclose>
      p->ofile[fd] = 0;
    800026f8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800026fc:	04a1                	addi	s1,s1,8
    800026fe:	01248563          	beq	s1,s2,80002708 <exit+0x58>
    if(p->ofile[fd]){
    80002702:	6088                	ld	a0,0(s1)
    80002704:	f575                	bnez	a0,800026f0 <exit+0x40>
    80002706:	bfdd                	j	800026fc <exit+0x4c>
  begin_op();
    80002708:	00002097          	auipc	ra,0x2
    8000270c:	f98080e7          	jalr	-104(ra) # 800046a0 <begin_op>
  iput(p->cwd);
    80002710:	1509b503          	ld	a0,336(s3)
    80002714:	00001097          	auipc	ra,0x1
    80002718:	45e080e7          	jalr	1118(ra) # 80003b72 <iput>
  end_op();
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	004080e7          	jalr	4(ra) # 80004720 <end_op>
  p->cwd = 0;
    80002724:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002728:	0000f497          	auipc	s1,0xf
    8000272c:	b9048493          	addi	s1,s1,-1136 # 800112b8 <wait_lock>
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	490080e7          	jalr	1168(ra) # 80000bc2 <acquire>
  reparent(p);
    8000273a:	854e                	mv	a0,s3
    8000273c:	00000097          	auipc	ra,0x0
    80002740:	f1a080e7          	jalr	-230(ra) # 80002656 <reparent>
  wakeup(p->parent);
    80002744:	0389b503          	ld	a0,56(s3)
    80002748:	00000097          	auipc	ra,0x0
    8000274c:	e98080e7          	jalr	-360(ra) # 800025e0 <wakeup>
  acquire(&p->lock);
    80002750:	854e                	mv	a0,s3
    80002752:	ffffe097          	auipc	ra,0xffffe
    80002756:	470080e7          	jalr	1136(ra) # 80000bc2 <acquire>
  p->xstate = status;
    8000275a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000275e:	4795                	li	a5,5
    80002760:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	510080e7          	jalr	1296(ra) # 80000c76 <release>
  sched();
    8000276e:	00000097          	auipc	ra,0x0
    80002772:	bd4080e7          	jalr	-1068(ra) # 80002342 <sched>
  panic("zombie exit");
    80002776:	00006517          	auipc	a0,0x6
    8000277a:	bba50513          	addi	a0,a0,-1094 # 80008330 <digits+0x2f0>
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	dac080e7          	jalr	-596(ra) # 8000052a <panic>

0000000080002786 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002786:	7179                	addi	sp,sp,-48
    80002788:	f406                	sd	ra,40(sp)
    8000278a:	f022                	sd	s0,32(sp)
    8000278c:	ec26                	sd	s1,24(sp)
    8000278e:	e84a                	sd	s2,16(sp)
    80002790:	e44e                	sd	s3,8(sp)
    80002792:	1800                	addi	s0,sp,48
    80002794:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002796:	0000f497          	auipc	s1,0xf
    8000279a:	f3a48493          	addi	s1,s1,-198 # 800116d0 <proc>
    8000279e:	0001b997          	auipc	s3,0x1b
    800027a2:	b3298993          	addi	s3,s3,-1230 # 8001d2d0 <tickslock>
    acquire(&p->lock);
    800027a6:	8526                	mv	a0,s1
    800027a8:	ffffe097          	auipc	ra,0xffffe
    800027ac:	41a080e7          	jalr	1050(ra) # 80000bc2 <acquire>
    if(p->pid == pid){
    800027b0:	589c                	lw	a5,48(s1)
    800027b2:	01278d63          	beq	a5,s2,800027cc <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	4be080e7          	jalr	1214(ra) # 80000c76 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c0:	2f048493          	addi	s1,s1,752
    800027c4:	ff3491e3          	bne	s1,s3,800027a6 <kill+0x20>
  }
  return -1;
    800027c8:	557d                	li	a0,-1
    800027ca:	a829                	j	800027e4 <kill+0x5e>
      p->killed = 1;
    800027cc:	4785                	li	a5,1
    800027ce:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027d0:	4c98                	lw	a4,24(s1)
    800027d2:	4789                	li	a5,2
    800027d4:	00f70f63          	beq	a4,a5,800027f2 <kill+0x6c>
      release(&p->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	49c080e7          	jalr	1180(ra) # 80000c76 <release>
      return 0;
    800027e2:	4501                	li	a0,0
}
    800027e4:	70a2                	ld	ra,40(sp)
    800027e6:	7402                	ld	s0,32(sp)
    800027e8:	64e2                	ld	s1,24(sp)
    800027ea:	6942                	ld	s2,16(sp)
    800027ec:	69a2                	ld	s3,8(sp)
    800027ee:	6145                	addi	sp,sp,48
    800027f0:	8082                	ret
        p->state = RUNNABLE;
    800027f2:	478d                	li	a5,3
    800027f4:	cc9c                	sw	a5,24(s1)
    800027f6:	b7cd                	j	800027d8 <kill+0x52>

00000000800027f8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027f8:	7179                	addi	sp,sp,-48
    800027fa:	f406                	sd	ra,40(sp)
    800027fc:	f022                	sd	s0,32(sp)
    800027fe:	ec26                	sd	s1,24(sp)
    80002800:	e84a                	sd	s2,16(sp)
    80002802:	e44e                	sd	s3,8(sp)
    80002804:	e052                	sd	s4,0(sp)
    80002806:	1800                	addi	s0,sp,48
    80002808:	84aa                	mv	s1,a0
    8000280a:	892e                	mv	s2,a1
    8000280c:	89b2                	mv	s3,a2
    8000280e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	404080e7          	jalr	1028(ra) # 80001c14 <myproc>
  if(user_dst){
    80002818:	c08d                	beqz	s1,8000283a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000281a:	86d2                	mv	a3,s4
    8000281c:	864e                	mv	a2,s3
    8000281e:	85ca                	mv	a1,s2
    80002820:	6928                	ld	a0,80(a0)
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	e1c080e7          	jalr	-484(ra) # 8000163e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000282a:	70a2                	ld	ra,40(sp)
    8000282c:	7402                	ld	s0,32(sp)
    8000282e:	64e2                	ld	s1,24(sp)
    80002830:	6942                	ld	s2,16(sp)
    80002832:	69a2                	ld	s3,8(sp)
    80002834:	6a02                	ld	s4,0(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret
    memmove((char *)dst, src, len);
    8000283a:	000a061b          	sext.w	a2,s4
    8000283e:	85ce                	mv	a1,s3
    80002840:	854a                	mv	a0,s2
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	4d8080e7          	jalr	1240(ra) # 80000d1a <memmove>
    return 0;
    8000284a:	8526                	mv	a0,s1
    8000284c:	bff9                	j	8000282a <either_copyout+0x32>

000000008000284e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000284e:	7179                	addi	sp,sp,-48
    80002850:	f406                	sd	ra,40(sp)
    80002852:	f022                	sd	s0,32(sp)
    80002854:	ec26                	sd	s1,24(sp)
    80002856:	e84a                	sd	s2,16(sp)
    80002858:	e44e                	sd	s3,8(sp)
    8000285a:	e052                	sd	s4,0(sp)
    8000285c:	1800                	addi	s0,sp,48
    8000285e:	892a                	mv	s2,a0
    80002860:	84ae                	mv	s1,a1
    80002862:	89b2                	mv	s3,a2
    80002864:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	3ae080e7          	jalr	942(ra) # 80001c14 <myproc>
  if(user_src){
    8000286e:	c08d                	beqz	s1,80002890 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002870:	86d2                	mv	a3,s4
    80002872:	864e                	mv	a2,s3
    80002874:	85ca                	mv	a1,s2
    80002876:	6928                	ld	a0,80(a0)
    80002878:	fffff097          	auipc	ra,0xfffff
    8000287c:	e52080e7          	jalr	-430(ra) # 800016ca <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002880:	70a2                	ld	ra,40(sp)
    80002882:	7402                	ld	s0,32(sp)
    80002884:	64e2                	ld	s1,24(sp)
    80002886:	6942                	ld	s2,16(sp)
    80002888:	69a2                	ld	s3,8(sp)
    8000288a:	6a02                	ld	s4,0(sp)
    8000288c:	6145                	addi	sp,sp,48
    8000288e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002890:	000a061b          	sext.w	a2,s4
    80002894:	85ce                	mv	a1,s3
    80002896:	854a                	mv	a0,s2
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	482080e7          	jalr	1154(ra) # 80000d1a <memmove>
    return 0;
    800028a0:	8526                	mv	a0,s1
    800028a2:	bff9                	j	80002880 <either_copyin+0x32>

00000000800028a4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028a4:	715d                	addi	sp,sp,-80
    800028a6:	e486                	sd	ra,72(sp)
    800028a8:	e0a2                	sd	s0,64(sp)
    800028aa:	fc26                	sd	s1,56(sp)
    800028ac:	f84a                	sd	s2,48(sp)
    800028ae:	f44e                	sd	s3,40(sp)
    800028b0:	f052                	sd	s4,32(sp)
    800028b2:	ec56                	sd	s5,24(sp)
    800028b4:	e85a                	sd	s6,16(sp)
    800028b6:	e45e                	sd	s7,8(sp)
    800028b8:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028ba:	00006517          	auipc	a0,0x6
    800028be:	80e50513          	addi	a0,a0,-2034 # 800080c8 <digits+0x88>
    800028c2:	ffffe097          	auipc	ra,0xffffe
    800028c6:	cb2080e7          	jalr	-846(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ca:	0000f497          	auipc	s1,0xf
    800028ce:	f5e48493          	addi	s1,s1,-162 # 80011828 <proc+0x158>
    800028d2:	0001b917          	auipc	s2,0x1b
    800028d6:	b5690913          	addi	s2,s2,-1194 # 8001d428 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028da:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028dc:	00006997          	auipc	s3,0x6
    800028e0:	a6498993          	addi	s3,s3,-1436 # 80008340 <digits+0x300>
    printf("%d %s %s", p->pid, state, p->name);
    800028e4:	00006a97          	auipc	s5,0x6
    800028e8:	a64a8a93          	addi	s5,s5,-1436 # 80008348 <digits+0x308>
    printf("\n");
    800028ec:	00005a17          	auipc	s4,0x5
    800028f0:	7dca0a13          	addi	s4,s4,2012 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f4:	00006b97          	auipc	s7,0x6
    800028f8:	a8cb8b93          	addi	s7,s7,-1396 # 80008380 <states.0>
    800028fc:	a00d                	j	8000291e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028fe:	ed86a583          	lw	a1,-296(a3)
    80002902:	8556                	mv	a0,s5
    80002904:	ffffe097          	auipc	ra,0xffffe
    80002908:	c70080e7          	jalr	-912(ra) # 80000574 <printf>
    printf("\n");
    8000290c:	8552                	mv	a0,s4
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	c66080e7          	jalr	-922(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002916:	2f048493          	addi	s1,s1,752
    8000291a:	03248263          	beq	s1,s2,8000293e <procdump+0x9a>
    if(p->state == UNUSED)
    8000291e:	86a6                	mv	a3,s1
    80002920:	ec04a783          	lw	a5,-320(s1)
    80002924:	dbed                	beqz	a5,80002916 <procdump+0x72>
      state = "???";
    80002926:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002928:	fcfb6be3          	bltu	s6,a5,800028fe <procdump+0x5a>
    8000292c:	02079713          	slli	a4,a5,0x20
    80002930:	01d75793          	srli	a5,a4,0x1d
    80002934:	97de                	add	a5,a5,s7
    80002936:	6390                	ld	a2,0(a5)
    80002938:	f279                	bnez	a2,800028fe <procdump+0x5a>
      state = "???";
    8000293a:	864e                	mv	a2,s3
    8000293c:	b7c9                	j	800028fe <procdump+0x5a>
  }
}
    8000293e:	60a6                	ld	ra,72(sp)
    80002940:	6406                	ld	s0,64(sp)
    80002942:	74e2                	ld	s1,56(sp)
    80002944:	7942                	ld	s2,48(sp)
    80002946:	79a2                	ld	s3,40(sp)
    80002948:	7a02                	ld	s4,32(sp)
    8000294a:	6ae2                	ld	s5,24(sp)
    8000294c:	6b42                	ld	s6,16(sp)
    8000294e:	6ba2                	ld	s7,8(sp)
    80002950:	6161                	addi	sp,sp,80
    80002952:	8082                	ret

0000000080002954 <swtch>:
    80002954:	00153023          	sd	ra,0(a0)
    80002958:	00253423          	sd	sp,8(a0)
    8000295c:	e900                	sd	s0,16(a0)
    8000295e:	ed04                	sd	s1,24(a0)
    80002960:	03253023          	sd	s2,32(a0)
    80002964:	03353423          	sd	s3,40(a0)
    80002968:	03453823          	sd	s4,48(a0)
    8000296c:	03553c23          	sd	s5,56(a0)
    80002970:	05653023          	sd	s6,64(a0)
    80002974:	05753423          	sd	s7,72(a0)
    80002978:	05853823          	sd	s8,80(a0)
    8000297c:	05953c23          	sd	s9,88(a0)
    80002980:	07a53023          	sd	s10,96(a0)
    80002984:	07b53423          	sd	s11,104(a0)
    80002988:	0005b083          	ld	ra,0(a1)
    8000298c:	0085b103          	ld	sp,8(a1)
    80002990:	6980                	ld	s0,16(a1)
    80002992:	6d84                	ld	s1,24(a1)
    80002994:	0205b903          	ld	s2,32(a1)
    80002998:	0285b983          	ld	s3,40(a1)
    8000299c:	0305ba03          	ld	s4,48(a1)
    800029a0:	0385ba83          	ld	s5,56(a1)
    800029a4:	0405bb03          	ld	s6,64(a1)
    800029a8:	0485bb83          	ld	s7,72(a1)
    800029ac:	0505bc03          	ld	s8,80(a1)
    800029b0:	0585bc83          	ld	s9,88(a1)
    800029b4:	0605bd03          	ld	s10,96(a1)
    800029b8:	0685bd83          	ld	s11,104(a1)
    800029bc:	8082                	ret

00000000800029be <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029c6:	00006597          	auipc	a1,0x6
    800029ca:	9ea58593          	addi	a1,a1,-1558 # 800083b0 <states.0+0x30>
    800029ce:	0001b517          	auipc	a0,0x1b
    800029d2:	90250513          	addi	a0,a0,-1790 # 8001d2d0 <tickslock>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	15c080e7          	jalr	348(ra) # 80000b32 <initlock>
}
    800029de:	60a2                	ld	ra,8(sp)
    800029e0:	6402                	ld	s0,0(sp)
    800029e2:	0141                	addi	sp,sp,16
    800029e4:	8082                	ret

00000000800029e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029e6:	1141                	addi	sp,sp,-16
    800029e8:	e422                	sd	s0,8(sp)
    800029ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	00004797          	auipc	a5,0x4
    800029f0:	9c478793          	addi	a5,a5,-1596 # 800063b0 <kernelvec>
    800029f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029f8:	6422                	ld	s0,8(sp)
    800029fa:	0141                	addi	sp,sp,16
    800029fc:	8082                	ret

00000000800029fe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029fe:	1141                	addi	sp,sp,-16
    80002a00:	e406                	sd	ra,8(sp)
    80002a02:	e022                	sd	s0,0(sp)
    80002a04:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	20e080e7          	jalr	526(ra) # 80001c14 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a14:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a18:	00004617          	auipc	a2,0x4
    80002a1c:	5e860613          	addi	a2,a2,1512 # 80007000 <_trampoline>
    80002a20:	00004697          	auipc	a3,0x4
    80002a24:	5e068693          	addi	a3,a3,1504 # 80007000 <_trampoline>
    80002a28:	8e91                	sub	a3,a3,a2
    80002a2a:	040007b7          	lui	a5,0x4000
    80002a2e:	17fd                	addi	a5,a5,-1
    80002a30:	07b2                	slli	a5,a5,0xc
    80002a32:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a34:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a38:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a3a:	180026f3          	csrr	a3,satp
    80002a3e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a40:	6d38                	ld	a4,88(a0)
    80002a42:	6134                	ld	a3,64(a0)
    80002a44:	6585                	lui	a1,0x1
    80002a46:	96ae                	add	a3,a3,a1
    80002a48:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a4a:	6d38                	ld	a4,88(a0)
    80002a4c:	00000697          	auipc	a3,0x0
    80002a50:	13868693          	addi	a3,a3,312 # 80002b84 <usertrap>
    80002a54:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a56:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a58:	8692                	mv	a3,tp
    80002a5a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a60:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a64:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a68:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a6c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a6e:	6f18                	ld	a4,24(a4)
    80002a70:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a74:	692c                	ld	a1,80(a0)
    80002a76:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a78:	00004717          	auipc	a4,0x4
    80002a7c:	61870713          	addi	a4,a4,1560 # 80007090 <userret>
    80002a80:	8f11                	sub	a4,a4,a2
    80002a82:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a84:	577d                	li	a4,-1
    80002a86:	177e                	slli	a4,a4,0x3f
    80002a88:	8dd9                	or	a1,a1,a4
    80002a8a:	02000537          	lui	a0,0x2000
    80002a8e:	157d                	addi	a0,a0,-1
    80002a90:	0536                	slli	a0,a0,0xd
    80002a92:	9782                	jalr	a5
}
    80002a94:	60a2                	ld	ra,8(sp)
    80002a96:	6402                	ld	s0,0(sp)
    80002a98:	0141                	addi	sp,sp,16
    80002a9a:	8082                	ret

0000000080002a9c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	e426                	sd	s1,8(sp)
    80002aa4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002aa6:	0001b497          	auipc	s1,0x1b
    80002aaa:	82a48493          	addi	s1,s1,-2006 # 8001d2d0 <tickslock>
    80002aae:	8526                	mv	a0,s1
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	112080e7          	jalr	274(ra) # 80000bc2 <acquire>
  ticks++;
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	57850513          	addi	a0,a0,1400 # 80009030 <ticks>
    80002ac0:	411c                	lw	a5,0(a0)
    80002ac2:	2785                	addiw	a5,a5,1
    80002ac4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	b1a080e7          	jalr	-1254(ra) # 800025e0 <wakeup>
  release(&tickslock);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	1a6080e7          	jalr	422(ra) # 80000c76 <release>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret

0000000080002ae2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002af0:	00074d63          	bltz	a4,80002b0a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002af4:	57fd                	li	a5,-1
    80002af6:	17fe                	slli	a5,a5,0x3f
    80002af8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002afa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002afc:	06f70363          	beq	a4,a5,80002b62 <devintr+0x80>
  }
}
    80002b00:	60e2                	ld	ra,24(sp)
    80002b02:	6442                	ld	s0,16(sp)
    80002b04:	64a2                	ld	s1,8(sp)
    80002b06:	6105                	addi	sp,sp,32
    80002b08:	8082                	ret
     (scause & 0xff) == 9){
    80002b0a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b0e:	46a5                	li	a3,9
    80002b10:	fed792e3          	bne	a5,a3,80002af4 <devintr+0x12>
    int irq = plic_claim();
    80002b14:	00004097          	auipc	ra,0x4
    80002b18:	9a4080e7          	jalr	-1628(ra) # 800064b8 <plic_claim>
    80002b1c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b1e:	47a9                	li	a5,10
    80002b20:	02f50763          	beq	a0,a5,80002b4e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b24:	4785                	li	a5,1
    80002b26:	02f50963          	beq	a0,a5,80002b58 <devintr+0x76>
    return 1;
    80002b2a:	4505                	li	a0,1
    } else if(irq){
    80002b2c:	d8f1                	beqz	s1,80002b00 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b2e:	85a6                	mv	a1,s1
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	88850513          	addi	a0,a0,-1912 # 800083b8 <states.0+0x38>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a3c080e7          	jalr	-1476(ra) # 80000574 <printf>
      plic_complete(irq);
    80002b40:	8526                	mv	a0,s1
    80002b42:	00004097          	auipc	ra,0x4
    80002b46:	99a080e7          	jalr	-1638(ra) # 800064dc <plic_complete>
    return 1;
    80002b4a:	4505                	li	a0,1
    80002b4c:	bf55                	j	80002b00 <devintr+0x1e>
      uartintr();
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	e38080e7          	jalr	-456(ra) # 80000986 <uartintr>
    80002b56:	b7ed                	j	80002b40 <devintr+0x5e>
      virtio_disk_intr();
    80002b58:	00004097          	auipc	ra,0x4
    80002b5c:	e16080e7          	jalr	-490(ra) # 8000696e <virtio_disk_intr>
    80002b60:	b7c5                	j	80002b40 <devintr+0x5e>
    if(cpuid() == 0){
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	086080e7          	jalr	134(ra) # 80001be8 <cpuid>
    80002b6a:	c901                	beqz	a0,80002b7a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b6c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b72:	14479073          	csrw	sip,a5
    return 2;
    80002b76:	4509                	li	a0,2
    80002b78:	b761                	j	80002b00 <devintr+0x1e>
      clockintr();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	f22080e7          	jalr	-222(ra) # 80002a9c <clockintr>
    80002b82:	b7ed                	j	80002b6c <devintr+0x8a>

0000000080002b84 <usertrap>:
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	e04a                	sd	s2,0(sp)
    80002b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b90:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b94:	1007f793          	andi	a5,a5,256
    80002b98:	e3ad                	bnez	a5,80002bfa <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b9a:	00004797          	auipc	a5,0x4
    80002b9e:	81678793          	addi	a5,a5,-2026 # 800063b0 <kernelvec>
    80002ba2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	06e080e7          	jalr	110(ra) # 80001c14 <myproc>
    80002bae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bb0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb2:	14102773          	csrr	a4,sepc
    80002bb6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bbc:	47a1                	li	a5,8
    80002bbe:	04f71c63          	bne	a4,a5,80002c16 <usertrap+0x92>
    if(p->killed)
    80002bc2:	551c                	lw	a5,40(a0)
    80002bc4:	e3b9                	bnez	a5,80002c0a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bc6:	6cb8                	ld	a4,88(s1)
    80002bc8:	6f1c                	ld	a5,24(a4)
    80002bca:	0791                	addi	a5,a5,4
    80002bcc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bd2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	2e0080e7          	jalr	736(ra) # 80002eba <syscall>
  if(p->killed)
    80002be2:	549c                	lw	a5,40(s1)
    80002be4:	ebc1                	bnez	a5,80002c74 <usertrap+0xf0>
  usertrapret();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	e18080e7          	jalr	-488(ra) # 800029fe <usertrapret>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
    panic("usertrap: not from user mode");
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	7de50513          	addi	a0,a0,2014 # 800083d8 <states.0+0x58>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	928080e7          	jalr	-1752(ra) # 8000052a <panic>
      exit(-1);
    80002c0a:	557d                	li	a0,-1
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	aa4080e7          	jalr	-1372(ra) # 800026b0 <exit>
    80002c14:	bf4d                	j	80002bc6 <usertrap+0x42>
  else if((which_dev = devintr()) != 0){
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	ecc080e7          	jalr	-308(ra) # 80002ae2 <devintr>
    80002c1e:	892a                	mv	s2,a0
    80002c20:	c501                	beqz	a0,80002c28 <usertrap+0xa4>
  if(p->killed)
    80002c22:	549c                	lw	a5,40(s1)
    80002c24:	c3a1                	beqz	a5,80002c64 <usertrap+0xe0>
    80002c26:	a815                	j	80002c5a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c28:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c2c:	5890                	lw	a2,48(s1)
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	7ca50513          	addi	a0,a0,1994 # 800083f8 <states.0+0x78>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	93e080e7          	jalr	-1730(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c42:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c46:	00005517          	auipc	a0,0x5
    80002c4a:	7e250513          	addi	a0,a0,2018 # 80008428 <states.0+0xa8>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	926080e7          	jalr	-1754(ra) # 80000574 <printf>
    p->killed = 1;
    80002c56:	4785                	li	a5,1
    80002c58:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002c5a:	557d                	li	a0,-1
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	a54080e7          	jalr	-1452(ra) # 800026b0 <exit>
  if(which_dev == 2)
    80002c64:	4789                	li	a5,2
    80002c66:	f8f910e3          	bne	s2,a5,80002be6 <usertrap+0x62>
    yield();
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	7ae080e7          	jalr	1966(ra) # 80002418 <yield>
    80002c72:	bf95                	j	80002be6 <usertrap+0x62>
  int which_dev = 0;
    80002c74:	4901                	li	s2,0
    80002c76:	b7d5                	j	80002c5a <usertrap+0xd6>

0000000080002c78 <kerneltrap>:
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c86:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c8a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c8e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c92:	1004f793          	andi	a5,s1,256
    80002c96:	cb85                	beqz	a5,80002cc6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c9c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c9e:	ef85                	bnez	a5,80002cd6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	e42080e7          	jalr	-446(ra) # 80002ae2 <devintr>
    80002ca8:	cd1d                	beqz	a0,80002ce6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002caa:	4789                	li	a5,2
    80002cac:	06f50a63          	beq	a0,a5,80002d20 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cb4:	10049073          	csrw	sstatus,s1
}
    80002cb8:	70a2                	ld	ra,40(sp)
    80002cba:	7402                	ld	s0,32(sp)
    80002cbc:	64e2                	ld	s1,24(sp)
    80002cbe:	6942                	ld	s2,16(sp)
    80002cc0:	69a2                	ld	s3,8(sp)
    80002cc2:	6145                	addi	sp,sp,48
    80002cc4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	78250513          	addi	a0,a0,1922 # 80008448 <states.0+0xc8>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	85c080e7          	jalr	-1956(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	79a50513          	addi	a0,a0,1946 # 80008470 <states.0+0xf0>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	84c080e7          	jalr	-1972(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002ce6:	85ce                	mv	a1,s3
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	7a850513          	addi	a0,a0,1960 # 80008490 <states.0+0x110>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	884080e7          	jalr	-1916(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cf8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	7a050513          	addi	a0,a0,1952 # 800084a0 <states.0+0x120>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	86c080e7          	jalr	-1940(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	7a850513          	addi	a0,a0,1960 # 800084b8 <states.0+0x138>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	812080e7          	jalr	-2030(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	ef4080e7          	jalr	-268(ra) # 80001c14 <myproc>
    80002d28:	d541                	beqz	a0,80002cb0 <kerneltrap+0x38>
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	eea080e7          	jalr	-278(ra) # 80001c14 <myproc>
    80002d32:	4d18                	lw	a4,24(a0)
    80002d34:	4791                	li	a5,4
    80002d36:	f6f71de3          	bne	a4,a5,80002cb0 <kerneltrap+0x38>
    yield();
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	6de080e7          	jalr	1758(ra) # 80002418 <yield>
    80002d42:	b7bd                	j	80002cb0 <kerneltrap+0x38>

0000000080002d44 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
    80002d4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	ec4080e7          	jalr	-316(ra) # 80001c14 <myproc>
  switch (n) {
    80002d58:	4795                	li	a5,5
    80002d5a:	0497e163          	bltu	a5,s1,80002d9c <argraw+0x58>
    80002d5e:	048a                	slli	s1,s1,0x2
    80002d60:	00005717          	auipc	a4,0x5
    80002d64:	79070713          	addi	a4,a4,1936 # 800084f0 <states.0+0x170>
    80002d68:	94ba                	add	s1,s1,a4
    80002d6a:	409c                	lw	a5,0(s1)
    80002d6c:	97ba                	add	a5,a5,a4
    80002d6e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d70:	6d3c                	ld	a5,88(a0)
    80002d72:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret
    return p->trapframe->a1;
    80002d7e:	6d3c                	ld	a5,88(a0)
    80002d80:	7fa8                	ld	a0,120(a5)
    80002d82:	bfcd                	j	80002d74 <argraw+0x30>
    return p->trapframe->a2;
    80002d84:	6d3c                	ld	a5,88(a0)
    80002d86:	63c8                	ld	a0,128(a5)
    80002d88:	b7f5                	j	80002d74 <argraw+0x30>
    return p->trapframe->a3;
    80002d8a:	6d3c                	ld	a5,88(a0)
    80002d8c:	67c8                	ld	a0,136(a5)
    80002d8e:	b7dd                	j	80002d74 <argraw+0x30>
    return p->trapframe->a4;
    80002d90:	6d3c                	ld	a5,88(a0)
    80002d92:	6bc8                	ld	a0,144(a5)
    80002d94:	b7c5                	j	80002d74 <argraw+0x30>
    return p->trapframe->a5;
    80002d96:	6d3c                	ld	a5,88(a0)
    80002d98:	6fc8                	ld	a0,152(a5)
    80002d9a:	bfe9                	j	80002d74 <argraw+0x30>
  panic("argraw");
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	72c50513          	addi	a0,a0,1836 # 800084c8 <states.0+0x148>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	786080e7          	jalr	1926(ra) # 8000052a <panic>

0000000080002dac <fetchaddr>:
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	e04a                	sd	s2,0(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84aa                	mv	s1,a0
    80002dba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	e58080e7          	jalr	-424(ra) # 80001c14 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002dc4:	653c                	ld	a5,72(a0)
    80002dc6:	02f4f863          	bgeu	s1,a5,80002df6 <fetchaddr+0x4a>
    80002dca:	00848713          	addi	a4,s1,8
    80002dce:	02e7e663          	bltu	a5,a4,80002dfa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dd2:	46a1                	li	a3,8
    80002dd4:	8626                	mv	a2,s1
    80002dd6:	85ca                	mv	a1,s2
    80002dd8:	6928                	ld	a0,80(a0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	8f0080e7          	jalr	-1808(ra) # 800016ca <copyin>
    80002de2:	00a03533          	snez	a0,a0
    80002de6:	40a00533          	neg	a0,a0
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	64a2                	ld	s1,8(sp)
    80002df0:	6902                	ld	s2,0(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret
    return -1;
    80002df6:	557d                	li	a0,-1
    80002df8:	bfcd                	j	80002dea <fetchaddr+0x3e>
    80002dfa:	557d                	li	a0,-1
    80002dfc:	b7fd                	j	80002dea <fetchaddr+0x3e>

0000000080002dfe <fetchstr>:
{
    80002dfe:	7179                	addi	sp,sp,-48
    80002e00:	f406                	sd	ra,40(sp)
    80002e02:	f022                	sd	s0,32(sp)
    80002e04:	ec26                	sd	s1,24(sp)
    80002e06:	e84a                	sd	s2,16(sp)
    80002e08:	e44e                	sd	s3,8(sp)
    80002e0a:	1800                	addi	s0,sp,48
    80002e0c:	892a                	mv	s2,a0
    80002e0e:	84ae                	mv	s1,a1
    80002e10:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	e02080e7          	jalr	-510(ra) # 80001c14 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e1a:	86ce                	mv	a3,s3
    80002e1c:	864a                	mv	a2,s2
    80002e1e:	85a6                	mv	a1,s1
    80002e20:	6928                	ld	a0,80(a0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	936080e7          	jalr	-1738(ra) # 80001758 <copyinstr>
  if(err < 0)
    80002e2a:	00054763          	bltz	a0,80002e38 <fetchstr+0x3a>
  return strlen(buf);
    80002e2e:	8526                	mv	a0,s1
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	012080e7          	jalr	18(ra) # 80000e42 <strlen>
}
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6942                	ld	s2,16(sp)
    80002e40:	69a2                	ld	s3,8(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret

0000000080002e46 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	e426                	sd	s1,8(sp)
    80002e4e:	1000                	addi	s0,sp,32
    80002e50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	ef2080e7          	jalr	-270(ra) # 80002d44 <argraw>
    80002e5a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e5c:	4501                	li	a0,0
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	e426                	sd	s1,8(sp)
    80002e70:	1000                	addi	s0,sp,32
    80002e72:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	ed0080e7          	jalr	-304(ra) # 80002d44 <argraw>
    80002e7c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e7e:	4501                	li	a0,0
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret

0000000080002e8a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e8a:	1101                	addi	sp,sp,-32
    80002e8c:	ec06                	sd	ra,24(sp)
    80002e8e:	e822                	sd	s0,16(sp)
    80002e90:	e426                	sd	s1,8(sp)
    80002e92:	e04a                	sd	s2,0(sp)
    80002e94:	1000                	addi	s0,sp,32
    80002e96:	84ae                	mv	s1,a1
    80002e98:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	eaa080e7          	jalr	-342(ra) # 80002d44 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ea2:	864a                	mv	a2,s2
    80002ea4:	85a6                	mv	a1,s1
    80002ea6:	00000097          	auipc	ra,0x0
    80002eaa:	f58080e7          	jalr	-168(ra) # 80002dfe <fetchstr>
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6902                	ld	s2,0(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	e426                	sd	s1,8(sp)
    80002ec2:	e04a                	sd	s2,0(sp)
    80002ec4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	d4e080e7          	jalr	-690(ra) # 80001c14 <myproc>
    80002ece:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ed0:	05853903          	ld	s2,88(a0)
    80002ed4:	0a893783          	ld	a5,168(s2)
    80002ed8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002edc:	37fd                	addiw	a5,a5,-1
    80002ede:	4751                	li	a4,20
    80002ee0:	00f76f63          	bltu	a4,a5,80002efe <syscall+0x44>
    80002ee4:	00369713          	slli	a4,a3,0x3
    80002ee8:	00005797          	auipc	a5,0x5
    80002eec:	62078793          	addi	a5,a5,1568 # 80008508 <syscalls>
    80002ef0:	97ba                	add	a5,a5,a4
    80002ef2:	639c                	ld	a5,0(a5)
    80002ef4:	c789                	beqz	a5,80002efe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ef6:	9782                	jalr	a5
    80002ef8:	06a93823          	sd	a0,112(s2)
    80002efc:	a839                	j	80002f1a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002efe:	15848613          	addi	a2,s1,344
    80002f02:	588c                	lw	a1,48(s1)
    80002f04:	00005517          	auipc	a0,0x5
    80002f08:	5cc50513          	addi	a0,a0,1484 # 800084d0 <states.0+0x150>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	668080e7          	jalr	1640(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f14:	6cbc                	ld	a5,88(s1)
    80002f16:	577d                	li	a4,-1
    80002f18:	fbb8                	sd	a4,112(a5)
  }
}
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6902                	ld	s2,0(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f2e:	fec40593          	addi	a1,s0,-20
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	f12080e7          	jalr	-238(ra) # 80002e46 <argint>
    return -1;
    80002f3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f3e:	00054963          	bltz	a0,80002f50 <sys_exit+0x2a>
  exit(n);
    80002f42:	fec42503          	lw	a0,-20(s0)
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	76a080e7          	jalr	1898(ra) # 800026b0 <exit>
  return 0;  // not reached
    80002f4e:	4781                	li	a5,0
}
    80002f50:	853e                	mv	a0,a5
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret

0000000080002f5a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f5a:	1141                	addi	sp,sp,-16
    80002f5c:	e406                	sd	ra,8(sp)
    80002f5e:	e022                	sd	s0,0(sp)
    80002f60:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	cb2080e7          	jalr	-846(ra) # 80001c14 <myproc>
}
    80002f6a:	5908                	lw	a0,48(a0)
    80002f6c:	60a2                	ld	ra,8(sp)
    80002f6e:	6402                	ld	s0,0(sp)
    80002f70:	0141                	addi	sp,sp,16
    80002f72:	8082                	ret

0000000080002f74 <sys_fork>:

uint64
sys_fork(void)
{
    80002f74:	1141                	addi	sp,sp,-16
    80002f76:	e406                	sd	ra,8(sp)
    80002f78:	e022                	sd	s0,0(sp)
    80002f7a:	0800                	addi	s0,sp,16
  return fork();
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	170080e7          	jalr	368(ra) # 800020ec <fork>
}
    80002f84:	60a2                	ld	ra,8(sp)
    80002f86:	6402                	ld	s0,0(sp)
    80002f88:	0141                	addi	sp,sp,16
    80002f8a:	8082                	ret

0000000080002f8c <sys_wait>:

uint64
sys_wait(void)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f94:	fe840593          	addi	a1,s0,-24
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	ece080e7          	jalr	-306(ra) # 80002e68 <argaddr>
    80002fa2:	87aa                	mv	a5,a0
    return -1;
    80002fa4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fa6:	0007c863          	bltz	a5,80002fb6 <sys_wait+0x2a>
  return wait(p);
    80002faa:	fe843503          	ld	a0,-24(s0)
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	50a080e7          	jalr	1290(ra) # 800024b8 <wait>
}
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fc8:	fdc40593          	addi	a1,s0,-36
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	e78080e7          	jalr	-392(ra) # 80002e46 <argint>
    return -1;
    80002fd6:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fd8:	00054f63          	bltz	a0,80002ff6 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fdc:	fffff097          	auipc	ra,0xfffff
    80002fe0:	c38080e7          	jalr	-968(ra) # 80001c14 <myproc>
    80002fe4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fe6:	fdc42503          	lw	a0,-36(s0)
    80002fea:	fffff097          	auipc	ra,0xfffff
    80002fee:	fc8080e7          	jalr	-56(ra) # 80001fb2 <growproc>
    80002ff2:	00054863          	bltz	a0,80003002 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002ff6:	8526                	mv	a0,s1
    80002ff8:	70a2                	ld	ra,40(sp)
    80002ffa:	7402                	ld	s0,32(sp)
    80002ffc:	64e2                	ld	s1,24(sp)
    80002ffe:	6145                	addi	sp,sp,48
    80003000:	8082                	ret
    return -1;
    80003002:	54fd                	li	s1,-1
    80003004:	bfcd                	j	80002ff6 <sys_sbrk+0x38>

0000000080003006 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003006:	7139                	addi	sp,sp,-64
    80003008:	fc06                	sd	ra,56(sp)
    8000300a:	f822                	sd	s0,48(sp)
    8000300c:	f426                	sd	s1,40(sp)
    8000300e:	f04a                	sd	s2,32(sp)
    80003010:	ec4e                	sd	s3,24(sp)
    80003012:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003014:	fcc40593          	addi	a1,s0,-52
    80003018:	4501                	li	a0,0
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	e2c080e7          	jalr	-468(ra) # 80002e46 <argint>
    return -1;
    80003022:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003024:	06054563          	bltz	a0,8000308e <sys_sleep+0x88>
  acquire(&tickslock);
    80003028:	0001a517          	auipc	a0,0x1a
    8000302c:	2a850513          	addi	a0,a0,680 # 8001d2d0 <tickslock>
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	b92080e7          	jalr	-1134(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80003038:	00006917          	auipc	s2,0x6
    8000303c:	ff892903          	lw	s2,-8(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003040:	fcc42783          	lw	a5,-52(s0)
    80003044:	cf85                	beqz	a5,8000307c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003046:	0001a997          	auipc	s3,0x1a
    8000304a:	28a98993          	addi	s3,s3,650 # 8001d2d0 <tickslock>
    8000304e:	00006497          	auipc	s1,0x6
    80003052:	fe248493          	addi	s1,s1,-30 # 80009030 <ticks>
    if(myproc()->killed){
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	bbe080e7          	jalr	-1090(ra) # 80001c14 <myproc>
    8000305e:	551c                	lw	a5,40(a0)
    80003060:	ef9d                	bnez	a5,8000309e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003062:	85ce                	mv	a1,s3
    80003064:	8526                	mv	a0,s1
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	3ee080e7          	jalr	1006(ra) # 80002454 <sleep>
  while(ticks - ticks0 < n){
    8000306e:	409c                	lw	a5,0(s1)
    80003070:	412787bb          	subw	a5,a5,s2
    80003074:	fcc42703          	lw	a4,-52(s0)
    80003078:	fce7efe3          	bltu	a5,a4,80003056 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000307c:	0001a517          	auipc	a0,0x1a
    80003080:	25450513          	addi	a0,a0,596 # 8001d2d0 <tickslock>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	bf2080e7          	jalr	-1038(ra) # 80000c76 <release>
  return 0;
    8000308c:	4781                	li	a5,0
}
    8000308e:	853e                	mv	a0,a5
    80003090:	70e2                	ld	ra,56(sp)
    80003092:	7442                	ld	s0,48(sp)
    80003094:	74a2                	ld	s1,40(sp)
    80003096:	7902                	ld	s2,32(sp)
    80003098:	69e2                	ld	s3,24(sp)
    8000309a:	6121                	addi	sp,sp,64
    8000309c:	8082                	ret
      release(&tickslock);
    8000309e:	0001a517          	auipc	a0,0x1a
    800030a2:	23250513          	addi	a0,a0,562 # 8001d2d0 <tickslock>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	bd0080e7          	jalr	-1072(ra) # 80000c76 <release>
      return -1;
    800030ae:	57fd                	li	a5,-1
    800030b0:	bff9                	j	8000308e <sys_sleep+0x88>

00000000800030b2 <sys_kill>:

uint64
sys_kill(void)
{
    800030b2:	1101                	addi	sp,sp,-32
    800030b4:	ec06                	sd	ra,24(sp)
    800030b6:	e822                	sd	s0,16(sp)
    800030b8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030ba:	fec40593          	addi	a1,s0,-20
    800030be:	4501                	li	a0,0
    800030c0:	00000097          	auipc	ra,0x0
    800030c4:	d86080e7          	jalr	-634(ra) # 80002e46 <argint>
    800030c8:	87aa                	mv	a5,a0
    return -1;
    800030ca:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030cc:	0007c863          	bltz	a5,800030dc <sys_kill+0x2a>
  return kill(pid);
    800030d0:	fec42503          	lw	a0,-20(s0)
    800030d4:	fffff097          	auipc	ra,0xfffff
    800030d8:	6b2080e7          	jalr	1714(ra) # 80002786 <kill>
}
    800030dc:	60e2                	ld	ra,24(sp)
    800030de:	6442                	ld	s0,16(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret

00000000800030e4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030e4:	1101                	addi	sp,sp,-32
    800030e6:	ec06                	sd	ra,24(sp)
    800030e8:	e822                	sd	s0,16(sp)
    800030ea:	e426                	sd	s1,8(sp)
    800030ec:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030ee:	0001a517          	auipc	a0,0x1a
    800030f2:	1e250513          	addi	a0,a0,482 # 8001d2d0 <tickslock>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	acc080e7          	jalr	-1332(ra) # 80000bc2 <acquire>
  xticks = ticks;
    800030fe:	00006497          	auipc	s1,0x6
    80003102:	f324a483          	lw	s1,-206(s1) # 80009030 <ticks>
  release(&tickslock);
    80003106:	0001a517          	auipc	a0,0x1a
    8000310a:	1ca50513          	addi	a0,a0,458 # 8001d2d0 <tickslock>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	b68080e7          	jalr	-1176(ra) # 80000c76 <release>
  return xticks;
}
    80003116:	02049513          	slli	a0,s1,0x20
    8000311a:	9101                	srli	a0,a0,0x20
    8000311c:	60e2                	ld	ra,24(sp)
    8000311e:	6442                	ld	s0,16(sp)
    80003120:	64a2                	ld	s1,8(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret

0000000080003126 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003126:	7179                	addi	sp,sp,-48
    80003128:	f406                	sd	ra,40(sp)
    8000312a:	f022                	sd	s0,32(sp)
    8000312c:	ec26                	sd	s1,24(sp)
    8000312e:	e84a                	sd	s2,16(sp)
    80003130:	e44e                	sd	s3,8(sp)
    80003132:	e052                	sd	s4,0(sp)
    80003134:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003136:	00005597          	auipc	a1,0x5
    8000313a:	48258593          	addi	a1,a1,1154 # 800085b8 <syscalls+0xb0>
    8000313e:	0001a517          	auipc	a0,0x1a
    80003142:	1aa50513          	addi	a0,a0,426 # 8001d2e8 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	9ec080e7          	jalr	-1556(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000314e:	00022797          	auipc	a5,0x22
    80003152:	19a78793          	addi	a5,a5,410 # 800252e8 <bcache+0x8000>
    80003156:	00022717          	auipc	a4,0x22
    8000315a:	3fa70713          	addi	a4,a4,1018 # 80025550 <bcache+0x8268>
    8000315e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003162:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003166:	0001a497          	auipc	s1,0x1a
    8000316a:	19a48493          	addi	s1,s1,410 # 8001d300 <bcache+0x18>
    b->next = bcache.head.next;
    8000316e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003170:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003172:	00005a17          	auipc	s4,0x5
    80003176:	44ea0a13          	addi	s4,s4,1102 # 800085c0 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000317a:	2b893783          	ld	a5,696(s2)
    8000317e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003180:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003184:	85d2                	mv	a1,s4
    80003186:	01048513          	addi	a0,s1,16
    8000318a:	00001097          	auipc	ra,0x1
    8000318e:	7d4080e7          	jalr	2004(ra) # 8000495e <initsleeplock>
    bcache.head.next->prev = b;
    80003192:	2b893783          	ld	a5,696(s2)
    80003196:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003198:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000319c:	45848493          	addi	s1,s1,1112
    800031a0:	fd349de3          	bne	s1,s3,8000317a <binit+0x54>
  }
}
    800031a4:	70a2                	ld	ra,40(sp)
    800031a6:	7402                	ld	s0,32(sp)
    800031a8:	64e2                	ld	s1,24(sp)
    800031aa:	6942                	ld	s2,16(sp)
    800031ac:	69a2                	ld	s3,8(sp)
    800031ae:	6a02                	ld	s4,0(sp)
    800031b0:	6145                	addi	sp,sp,48
    800031b2:	8082                	ret

00000000800031b4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031b4:	7179                	addi	sp,sp,-48
    800031b6:	f406                	sd	ra,40(sp)
    800031b8:	f022                	sd	s0,32(sp)
    800031ba:	ec26                	sd	s1,24(sp)
    800031bc:	e84a                	sd	s2,16(sp)
    800031be:	e44e                	sd	s3,8(sp)
    800031c0:	1800                	addi	s0,sp,48
    800031c2:	892a                	mv	s2,a0
    800031c4:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800031c6:	0001a517          	auipc	a0,0x1a
    800031ca:	12250513          	addi	a0,a0,290 # 8001d2e8 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	9f4080e7          	jalr	-1548(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031d6:	00022497          	auipc	s1,0x22
    800031da:	3ca4b483          	ld	s1,970(s1) # 800255a0 <bcache+0x82b8>
    800031de:	00022797          	auipc	a5,0x22
    800031e2:	37278793          	addi	a5,a5,882 # 80025550 <bcache+0x8268>
    800031e6:	02f48f63          	beq	s1,a5,80003224 <bread+0x70>
    800031ea:	873e                	mv	a4,a5
    800031ec:	a021                	j	800031f4 <bread+0x40>
    800031ee:	68a4                	ld	s1,80(s1)
    800031f0:	02e48a63          	beq	s1,a4,80003224 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031f4:	449c                	lw	a5,8(s1)
    800031f6:	ff279ce3          	bne	a5,s2,800031ee <bread+0x3a>
    800031fa:	44dc                	lw	a5,12(s1)
    800031fc:	ff3799e3          	bne	a5,s3,800031ee <bread+0x3a>
      b->refcnt++;
    80003200:	40bc                	lw	a5,64(s1)
    80003202:	2785                	addiw	a5,a5,1
    80003204:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003206:	0001a517          	auipc	a0,0x1a
    8000320a:	0e250513          	addi	a0,a0,226 # 8001d2e8 <bcache>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a68080e7          	jalr	-1432(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003216:	01048513          	addi	a0,s1,16
    8000321a:	00001097          	auipc	ra,0x1
    8000321e:	77e080e7          	jalr	1918(ra) # 80004998 <acquiresleep>
      return b;
    80003222:	a8b9                	j	80003280 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003224:	00022497          	auipc	s1,0x22
    80003228:	3744b483          	ld	s1,884(s1) # 80025598 <bcache+0x82b0>
    8000322c:	00022797          	auipc	a5,0x22
    80003230:	32478793          	addi	a5,a5,804 # 80025550 <bcache+0x8268>
    80003234:	00f48863          	beq	s1,a5,80003244 <bread+0x90>
    80003238:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000323a:	40bc                	lw	a5,64(s1)
    8000323c:	cf81                	beqz	a5,80003254 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000323e:	64a4                	ld	s1,72(s1)
    80003240:	fee49de3          	bne	s1,a4,8000323a <bread+0x86>
  panic("bget: no buffers");
    80003244:	00005517          	auipc	a0,0x5
    80003248:	38450513          	addi	a0,a0,900 # 800085c8 <syscalls+0xc0>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	2de080e7          	jalr	734(ra) # 8000052a <panic>
      b->dev = dev;
    80003254:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003258:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000325c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003260:	4785                	li	a5,1
    80003262:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003264:	0001a517          	auipc	a0,0x1a
    80003268:	08450513          	addi	a0,a0,132 # 8001d2e8 <bcache>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	a0a080e7          	jalr	-1526(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003274:	01048513          	addi	a0,s1,16
    80003278:	00001097          	auipc	ra,0x1
    8000327c:	720080e7          	jalr	1824(ra) # 80004998 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003280:	409c                	lw	a5,0(s1)
    80003282:	cb89                	beqz	a5,80003294 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003284:	8526                	mv	a0,s1
    80003286:	70a2                	ld	ra,40(sp)
    80003288:	7402                	ld	s0,32(sp)
    8000328a:	64e2                	ld	s1,24(sp)
    8000328c:	6942                	ld	s2,16(sp)
    8000328e:	69a2                	ld	s3,8(sp)
    80003290:	6145                	addi	sp,sp,48
    80003292:	8082                	ret
    virtio_disk_rw(b, 0);
    80003294:	4581                	li	a1,0
    80003296:	8526                	mv	a0,s1
    80003298:	00003097          	auipc	ra,0x3
    8000329c:	44e080e7          	jalr	1102(ra) # 800066e6 <virtio_disk_rw>
    b->valid = 1;
    800032a0:	4785                	li	a5,1
    800032a2:	c09c                	sw	a5,0(s1)
  return b;
    800032a4:	b7c5                	j	80003284 <bread+0xd0>

00000000800032a6 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032a6:	1101                	addi	sp,sp,-32
    800032a8:	ec06                	sd	ra,24(sp)
    800032aa:	e822                	sd	s0,16(sp)
    800032ac:	e426                	sd	s1,8(sp)
    800032ae:	1000                	addi	s0,sp,32
    800032b0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b2:	0541                	addi	a0,a0,16
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	77e080e7          	jalr	1918(ra) # 80004a32 <holdingsleep>
    800032bc:	cd01                	beqz	a0,800032d4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032be:	4585                	li	a1,1
    800032c0:	8526                	mv	a0,s1
    800032c2:	00003097          	auipc	ra,0x3
    800032c6:	424080e7          	jalr	1060(ra) # 800066e6 <virtio_disk_rw>
}
    800032ca:	60e2                	ld	ra,24(sp)
    800032cc:	6442                	ld	s0,16(sp)
    800032ce:	64a2                	ld	s1,8(sp)
    800032d0:	6105                	addi	sp,sp,32
    800032d2:	8082                	ret
    panic("bwrite");
    800032d4:	00005517          	auipc	a0,0x5
    800032d8:	30c50513          	addi	a0,a0,780 # 800085e0 <syscalls+0xd8>
    800032dc:	ffffd097          	auipc	ra,0xffffd
    800032e0:	24e080e7          	jalr	590(ra) # 8000052a <panic>

00000000800032e4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	e426                	sd	s1,8(sp)
    800032ec:	e04a                	sd	s2,0(sp)
    800032ee:	1000                	addi	s0,sp,32
    800032f0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032f2:	01050913          	addi	s2,a0,16
    800032f6:	854a                	mv	a0,s2
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	73a080e7          	jalr	1850(ra) # 80004a32 <holdingsleep>
    80003300:	c92d                	beqz	a0,80003372 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003302:	854a                	mv	a0,s2
    80003304:	00001097          	auipc	ra,0x1
    80003308:	6ea080e7          	jalr	1770(ra) # 800049ee <releasesleep>

  acquire(&bcache.lock);
    8000330c:	0001a517          	auipc	a0,0x1a
    80003310:	fdc50513          	addi	a0,a0,-36 # 8001d2e8 <bcache>
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	8ae080e7          	jalr	-1874(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000331c:	40bc                	lw	a5,64(s1)
    8000331e:	37fd                	addiw	a5,a5,-1
    80003320:	0007871b          	sext.w	a4,a5
    80003324:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003326:	eb05                	bnez	a4,80003356 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003328:	68bc                	ld	a5,80(s1)
    8000332a:	64b8                	ld	a4,72(s1)
    8000332c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000332e:	64bc                	ld	a5,72(s1)
    80003330:	68b8                	ld	a4,80(s1)
    80003332:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003334:	00022797          	auipc	a5,0x22
    80003338:	fb478793          	addi	a5,a5,-76 # 800252e8 <bcache+0x8000>
    8000333c:	2b87b703          	ld	a4,696(a5)
    80003340:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003342:	00022717          	auipc	a4,0x22
    80003346:	20e70713          	addi	a4,a4,526 # 80025550 <bcache+0x8268>
    8000334a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000334c:	2b87b703          	ld	a4,696(a5)
    80003350:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003352:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003356:	0001a517          	auipc	a0,0x1a
    8000335a:	f9250513          	addi	a0,a0,-110 # 8001d2e8 <bcache>
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	918080e7          	jalr	-1768(ra) # 80000c76 <release>
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6902                	ld	s2,0(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret
    panic("brelse");
    80003372:	00005517          	auipc	a0,0x5
    80003376:	27650513          	addi	a0,a0,630 # 800085e8 <syscalls+0xe0>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	1b0080e7          	jalr	432(ra) # 8000052a <panic>

0000000080003382 <bpin>:

void
bpin(struct buf *b) {
    80003382:	1101                	addi	sp,sp,-32
    80003384:	ec06                	sd	ra,24(sp)
    80003386:	e822                	sd	s0,16(sp)
    80003388:	e426                	sd	s1,8(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000338e:	0001a517          	auipc	a0,0x1a
    80003392:	f5a50513          	addi	a0,a0,-166 # 8001d2e8 <bcache>
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	82c080e7          	jalr	-2004(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000339e:	40bc                	lw	a5,64(s1)
    800033a0:	2785                	addiw	a5,a5,1
    800033a2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a4:	0001a517          	auipc	a0,0x1a
    800033a8:	f4450513          	addi	a0,a0,-188 # 8001d2e8 <bcache>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	8ca080e7          	jalr	-1846(ra) # 80000c76 <release>
}
    800033b4:	60e2                	ld	ra,24(sp)
    800033b6:	6442                	ld	s0,16(sp)
    800033b8:	64a2                	ld	s1,8(sp)
    800033ba:	6105                	addi	sp,sp,32
    800033bc:	8082                	ret

00000000800033be <bunpin>:

void
bunpin(struct buf *b) {
    800033be:	1101                	addi	sp,sp,-32
    800033c0:	ec06                	sd	ra,24(sp)
    800033c2:	e822                	sd	s0,16(sp)
    800033c4:	e426                	sd	s1,8(sp)
    800033c6:	1000                	addi	s0,sp,32
    800033c8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ca:	0001a517          	auipc	a0,0x1a
    800033ce:	f1e50513          	addi	a0,a0,-226 # 8001d2e8 <bcache>
    800033d2:	ffffd097          	auipc	ra,0xffffd
    800033d6:	7f0080e7          	jalr	2032(ra) # 80000bc2 <acquire>
  b->refcnt--;
    800033da:	40bc                	lw	a5,64(s1)
    800033dc:	37fd                	addiw	a5,a5,-1
    800033de:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033e0:	0001a517          	auipc	a0,0x1a
    800033e4:	f0850513          	addi	a0,a0,-248 # 8001d2e8 <bcache>
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	88e080e7          	jalr	-1906(ra) # 80000c76 <release>
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret

00000000800033fa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033fa:	1101                	addi	sp,sp,-32
    800033fc:	ec06                	sd	ra,24(sp)
    800033fe:	e822                	sd	s0,16(sp)
    80003400:	e426                	sd	s1,8(sp)
    80003402:	e04a                	sd	s2,0(sp)
    80003404:	1000                	addi	s0,sp,32
    80003406:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003408:	00d5d59b          	srliw	a1,a1,0xd
    8000340c:	00022797          	auipc	a5,0x22
    80003410:	5b87a783          	lw	a5,1464(a5) # 800259c4 <sb+0x1c>
    80003414:	9dbd                	addw	a1,a1,a5
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	d9e080e7          	jalr	-610(ra) # 800031b4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000341e:	0074f713          	andi	a4,s1,7
    80003422:	4785                	li	a5,1
    80003424:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003428:	14ce                	slli	s1,s1,0x33
    8000342a:	90d9                	srli	s1,s1,0x36
    8000342c:	00950733          	add	a4,a0,s1
    80003430:	05874703          	lbu	a4,88(a4)
    80003434:	00e7f6b3          	and	a3,a5,a4
    80003438:	c69d                	beqz	a3,80003466 <bfree+0x6c>
    8000343a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000343c:	94aa                	add	s1,s1,a0
    8000343e:	fff7c793          	not	a5,a5
    80003442:	8ff9                	and	a5,a5,a4
    80003444:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	430080e7          	jalr	1072(ra) # 80004878 <log_write>
  brelse(bp);
    80003450:	854a                	mv	a0,s2
    80003452:	00000097          	auipc	ra,0x0
    80003456:	e92080e7          	jalr	-366(ra) # 800032e4 <brelse>
}
    8000345a:	60e2                	ld	ra,24(sp)
    8000345c:	6442                	ld	s0,16(sp)
    8000345e:	64a2                	ld	s1,8(sp)
    80003460:	6902                	ld	s2,0(sp)
    80003462:	6105                	addi	sp,sp,32
    80003464:	8082                	ret
    panic("freeing free block");
    80003466:	00005517          	auipc	a0,0x5
    8000346a:	18a50513          	addi	a0,a0,394 # 800085f0 <syscalls+0xe8>
    8000346e:	ffffd097          	auipc	ra,0xffffd
    80003472:	0bc080e7          	jalr	188(ra) # 8000052a <panic>

0000000080003476 <balloc>:
{
    80003476:	711d                	addi	sp,sp,-96
    80003478:	ec86                	sd	ra,88(sp)
    8000347a:	e8a2                	sd	s0,80(sp)
    8000347c:	e4a6                	sd	s1,72(sp)
    8000347e:	e0ca                	sd	s2,64(sp)
    80003480:	fc4e                	sd	s3,56(sp)
    80003482:	f852                	sd	s4,48(sp)
    80003484:	f456                	sd	s5,40(sp)
    80003486:	f05a                	sd	s6,32(sp)
    80003488:	ec5e                	sd	s7,24(sp)
    8000348a:	e862                	sd	s8,16(sp)
    8000348c:	e466                	sd	s9,8(sp)
    8000348e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003490:	00022797          	auipc	a5,0x22
    80003494:	51c7a783          	lw	a5,1308(a5) # 800259ac <sb+0x4>
    80003498:	cbd1                	beqz	a5,8000352c <balloc+0xb6>
    8000349a:	8baa                	mv	s7,a0
    8000349c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000349e:	00022b17          	auipc	s6,0x22
    800034a2:	50ab0b13          	addi	s6,s6,1290 # 800259a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034a8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034aa:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ac:	6c89                	lui	s9,0x2
    800034ae:	a831                	j	800034ca <balloc+0x54>
    brelse(bp);
    800034b0:	854a                	mv	a0,s2
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	e32080e7          	jalr	-462(ra) # 800032e4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034ba:	015c87bb          	addw	a5,s9,s5
    800034be:	00078a9b          	sext.w	s5,a5
    800034c2:	004b2703          	lw	a4,4(s6)
    800034c6:	06eaf363          	bgeu	s5,a4,8000352c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034ca:	41fad79b          	sraiw	a5,s5,0x1f
    800034ce:	0137d79b          	srliw	a5,a5,0x13
    800034d2:	015787bb          	addw	a5,a5,s5
    800034d6:	40d7d79b          	sraiw	a5,a5,0xd
    800034da:	01cb2583          	lw	a1,28(s6)
    800034de:	9dbd                	addw	a1,a1,a5
    800034e0:	855e                	mv	a0,s7
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	cd2080e7          	jalr	-814(ra) # 800031b4 <bread>
    800034ea:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ec:	004b2503          	lw	a0,4(s6)
    800034f0:	000a849b          	sext.w	s1,s5
    800034f4:	8662                	mv	a2,s8
    800034f6:	faa4fde3          	bgeu	s1,a0,800034b0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034fa:	41f6579b          	sraiw	a5,a2,0x1f
    800034fe:	01d7d69b          	srliw	a3,a5,0x1d
    80003502:	00c6873b          	addw	a4,a3,a2
    80003506:	00777793          	andi	a5,a4,7
    8000350a:	9f95                	subw	a5,a5,a3
    8000350c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003510:	4037571b          	sraiw	a4,a4,0x3
    80003514:	00e906b3          	add	a3,s2,a4
    80003518:	0586c683          	lbu	a3,88(a3)
    8000351c:	00d7f5b3          	and	a1,a5,a3
    80003520:	cd91                	beqz	a1,8000353c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003522:	2605                	addiw	a2,a2,1
    80003524:	2485                	addiw	s1,s1,1
    80003526:	fd4618e3          	bne	a2,s4,800034f6 <balloc+0x80>
    8000352a:	b759                	j	800034b0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000352c:	00005517          	auipc	a0,0x5
    80003530:	0dc50513          	addi	a0,a0,220 # 80008608 <syscalls+0x100>
    80003534:	ffffd097          	auipc	ra,0xffffd
    80003538:	ff6080e7          	jalr	-10(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000353c:	974a                	add	a4,a4,s2
    8000353e:	8fd5                	or	a5,a5,a3
    80003540:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003544:	854a                	mv	a0,s2
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	332080e7          	jalr	818(ra) # 80004878 <log_write>
        brelse(bp);
    8000354e:	854a                	mv	a0,s2
    80003550:	00000097          	auipc	ra,0x0
    80003554:	d94080e7          	jalr	-620(ra) # 800032e4 <brelse>
  bp = bread(dev, bno);
    80003558:	85a6                	mv	a1,s1
    8000355a:	855e                	mv	a0,s7
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	c58080e7          	jalr	-936(ra) # 800031b4 <bread>
    80003564:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003566:	40000613          	li	a2,1024
    8000356a:	4581                	li	a1,0
    8000356c:	05850513          	addi	a0,a0,88
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	74e080e7          	jalr	1870(ra) # 80000cbe <memset>
  log_write(bp);
    80003578:	854a                	mv	a0,s2
    8000357a:	00001097          	auipc	ra,0x1
    8000357e:	2fe080e7          	jalr	766(ra) # 80004878 <log_write>
  brelse(bp);
    80003582:	854a                	mv	a0,s2
    80003584:	00000097          	auipc	ra,0x0
    80003588:	d60080e7          	jalr	-672(ra) # 800032e4 <brelse>
}
    8000358c:	8526                	mv	a0,s1
    8000358e:	60e6                	ld	ra,88(sp)
    80003590:	6446                	ld	s0,80(sp)
    80003592:	64a6                	ld	s1,72(sp)
    80003594:	6906                	ld	s2,64(sp)
    80003596:	79e2                	ld	s3,56(sp)
    80003598:	7a42                	ld	s4,48(sp)
    8000359a:	7aa2                	ld	s5,40(sp)
    8000359c:	7b02                	ld	s6,32(sp)
    8000359e:	6be2                	ld	s7,24(sp)
    800035a0:	6c42                	ld	s8,16(sp)
    800035a2:	6ca2                	ld	s9,8(sp)
    800035a4:	6125                	addi	sp,sp,96
    800035a6:	8082                	ret

00000000800035a8 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035a8:	7179                	addi	sp,sp,-48
    800035aa:	f406                	sd	ra,40(sp)
    800035ac:	f022                	sd	s0,32(sp)
    800035ae:	ec26                	sd	s1,24(sp)
    800035b0:	e84a                	sd	s2,16(sp)
    800035b2:	e44e                	sd	s3,8(sp)
    800035b4:	e052                	sd	s4,0(sp)
    800035b6:	1800                	addi	s0,sp,48
    800035b8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035ba:	47ad                	li	a5,11
    800035bc:	04b7fe63          	bgeu	a5,a1,80003618 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035c0:	ff45849b          	addiw	s1,a1,-12
    800035c4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035c8:	0ff00793          	li	a5,255
    800035cc:	0ae7e463          	bltu	a5,a4,80003674 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035d0:	08052583          	lw	a1,128(a0)
    800035d4:	c5b5                	beqz	a1,80003640 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035d6:	00092503          	lw	a0,0(s2)
    800035da:	00000097          	auipc	ra,0x0
    800035de:	bda080e7          	jalr	-1062(ra) # 800031b4 <bread>
    800035e2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035e4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035e8:	02049713          	slli	a4,s1,0x20
    800035ec:	01e75593          	srli	a1,a4,0x1e
    800035f0:	00b784b3          	add	s1,a5,a1
    800035f4:	0004a983          	lw	s3,0(s1)
    800035f8:	04098e63          	beqz	s3,80003654 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035fc:	8552                	mv	a0,s4
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	ce6080e7          	jalr	-794(ra) # 800032e4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003606:	854e                	mv	a0,s3
    80003608:	70a2                	ld	ra,40(sp)
    8000360a:	7402                	ld	s0,32(sp)
    8000360c:	64e2                	ld	s1,24(sp)
    8000360e:	6942                	ld	s2,16(sp)
    80003610:	69a2                	ld	s3,8(sp)
    80003612:	6a02                	ld	s4,0(sp)
    80003614:	6145                	addi	sp,sp,48
    80003616:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003618:	02059793          	slli	a5,a1,0x20
    8000361c:	01e7d593          	srli	a1,a5,0x1e
    80003620:	00b504b3          	add	s1,a0,a1
    80003624:	0504a983          	lw	s3,80(s1)
    80003628:	fc099fe3          	bnez	s3,80003606 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000362c:	4108                	lw	a0,0(a0)
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	e48080e7          	jalr	-440(ra) # 80003476 <balloc>
    80003636:	0005099b          	sext.w	s3,a0
    8000363a:	0534a823          	sw	s3,80(s1)
    8000363e:	b7e1                	j	80003606 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003640:	4108                	lw	a0,0(a0)
    80003642:	00000097          	auipc	ra,0x0
    80003646:	e34080e7          	jalr	-460(ra) # 80003476 <balloc>
    8000364a:	0005059b          	sext.w	a1,a0
    8000364e:	08b92023          	sw	a1,128(s2)
    80003652:	b751                	j	800035d6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003654:	00092503          	lw	a0,0(s2)
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	e1e080e7          	jalr	-482(ra) # 80003476 <balloc>
    80003660:	0005099b          	sext.w	s3,a0
    80003664:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003668:	8552                	mv	a0,s4
    8000366a:	00001097          	auipc	ra,0x1
    8000366e:	20e080e7          	jalr	526(ra) # 80004878 <log_write>
    80003672:	b769                	j	800035fc <bmap+0x54>
  panic("bmap: out of range");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	fac50513          	addi	a0,a0,-84 # 80008620 <syscalls+0x118>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	eae080e7          	jalr	-338(ra) # 8000052a <panic>

0000000080003684 <iget>:
{
    80003684:	7179                	addi	sp,sp,-48
    80003686:	f406                	sd	ra,40(sp)
    80003688:	f022                	sd	s0,32(sp)
    8000368a:	ec26                	sd	s1,24(sp)
    8000368c:	e84a                	sd	s2,16(sp)
    8000368e:	e44e                	sd	s3,8(sp)
    80003690:	e052                	sd	s4,0(sp)
    80003692:	1800                	addi	s0,sp,48
    80003694:	89aa                	mv	s3,a0
    80003696:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003698:	00022517          	auipc	a0,0x22
    8000369c:	33050513          	addi	a0,a0,816 # 800259c8 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	522080e7          	jalr	1314(ra) # 80000bc2 <acquire>
  empty = 0;
    800036a8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036aa:	00022497          	auipc	s1,0x22
    800036ae:	33648493          	addi	s1,s1,822 # 800259e0 <itable+0x18>
    800036b2:	00024697          	auipc	a3,0x24
    800036b6:	dbe68693          	addi	a3,a3,-578 # 80027470 <log>
    800036ba:	a039                	j	800036c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036bc:	02090b63          	beqz	s2,800036f2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c0:	08848493          	addi	s1,s1,136
    800036c4:	02d48a63          	beq	s1,a3,800036f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036c8:	449c                	lw	a5,8(s1)
    800036ca:	fef059e3          	blez	a5,800036bc <iget+0x38>
    800036ce:	4098                	lw	a4,0(s1)
    800036d0:	ff3716e3          	bne	a4,s3,800036bc <iget+0x38>
    800036d4:	40d8                	lw	a4,4(s1)
    800036d6:	ff4713e3          	bne	a4,s4,800036bc <iget+0x38>
      ip->ref++;
    800036da:	2785                	addiw	a5,a5,1
    800036dc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036de:	00022517          	auipc	a0,0x22
    800036e2:	2ea50513          	addi	a0,a0,746 # 800259c8 <itable>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	590080e7          	jalr	1424(ra) # 80000c76 <release>
      return ip;
    800036ee:	8926                	mv	s2,s1
    800036f0:	a03d                	j	8000371e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036f2:	f7f9                	bnez	a5,800036c0 <iget+0x3c>
    800036f4:	8926                	mv	s2,s1
    800036f6:	b7e9                	j	800036c0 <iget+0x3c>
  if(empty == 0)
    800036f8:	02090c63          	beqz	s2,80003730 <iget+0xac>
  ip->dev = dev;
    800036fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003700:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003704:	4785                	li	a5,1
    80003706:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000370a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000370e:	00022517          	auipc	a0,0x22
    80003712:	2ba50513          	addi	a0,a0,698 # 800259c8 <itable>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	560080e7          	jalr	1376(ra) # 80000c76 <release>
}
    8000371e:	854a                	mv	a0,s2
    80003720:	70a2                	ld	ra,40(sp)
    80003722:	7402                	ld	s0,32(sp)
    80003724:	64e2                	ld	s1,24(sp)
    80003726:	6942                	ld	s2,16(sp)
    80003728:	69a2                	ld	s3,8(sp)
    8000372a:	6a02                	ld	s4,0(sp)
    8000372c:	6145                	addi	sp,sp,48
    8000372e:	8082                	ret
    panic("iget: no inodes");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	f0850513          	addi	a0,a0,-248 # 80008638 <syscalls+0x130>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>

0000000080003740 <fsinit>:
fsinit(int dev) {
    80003740:	7179                	addi	sp,sp,-48
    80003742:	f406                	sd	ra,40(sp)
    80003744:	f022                	sd	s0,32(sp)
    80003746:	ec26                	sd	s1,24(sp)
    80003748:	e84a                	sd	s2,16(sp)
    8000374a:	e44e                	sd	s3,8(sp)
    8000374c:	1800                	addi	s0,sp,48
    8000374e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003750:	4585                	li	a1,1
    80003752:	00000097          	auipc	ra,0x0
    80003756:	a62080e7          	jalr	-1438(ra) # 800031b4 <bread>
    8000375a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000375c:	00022997          	auipc	s3,0x22
    80003760:	24c98993          	addi	s3,s3,588 # 800259a8 <sb>
    80003764:	02000613          	li	a2,32
    80003768:	05850593          	addi	a1,a0,88
    8000376c:	854e                	mv	a0,s3
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	5ac080e7          	jalr	1452(ra) # 80000d1a <memmove>
  brelse(bp);
    80003776:	8526                	mv	a0,s1
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	b6c080e7          	jalr	-1172(ra) # 800032e4 <brelse>
  if(sb.magic != FSMAGIC)
    80003780:	0009a703          	lw	a4,0(s3)
    80003784:	102037b7          	lui	a5,0x10203
    80003788:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000378c:	02f71263          	bne	a4,a5,800037b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003790:	00022597          	auipc	a1,0x22
    80003794:	21858593          	addi	a1,a1,536 # 800259a8 <sb>
    80003798:	854a                	mv	a0,s2
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	e60080e7          	jalr	-416(ra) # 800045fa <initlog>
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
    panic("invalid file system");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	e9850513          	addi	a0,a0,-360 # 80008648 <syscalls+0x140>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d72080e7          	jalr	-654(ra) # 8000052a <panic>

00000000800037c0 <iinit>:
{
    800037c0:	7179                	addi	sp,sp,-48
    800037c2:	f406                	sd	ra,40(sp)
    800037c4:	f022                	sd	s0,32(sp)
    800037c6:	ec26                	sd	s1,24(sp)
    800037c8:	e84a                	sd	s2,16(sp)
    800037ca:	e44e                	sd	s3,8(sp)
    800037cc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037ce:	00005597          	auipc	a1,0x5
    800037d2:	e9258593          	addi	a1,a1,-366 # 80008660 <syscalls+0x158>
    800037d6:	00022517          	auipc	a0,0x22
    800037da:	1f250513          	addi	a0,a0,498 # 800259c8 <itable>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	354080e7          	jalr	852(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037e6:	00022497          	auipc	s1,0x22
    800037ea:	20a48493          	addi	s1,s1,522 # 800259f0 <itable+0x28>
    800037ee:	00024997          	auipc	s3,0x24
    800037f2:	c9298993          	addi	s3,s3,-878 # 80027480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037f6:	00005917          	auipc	s2,0x5
    800037fa:	e7290913          	addi	s2,s2,-398 # 80008668 <syscalls+0x160>
    800037fe:	85ca                	mv	a1,s2
    80003800:	8526                	mv	a0,s1
    80003802:	00001097          	auipc	ra,0x1
    80003806:	15c080e7          	jalr	348(ra) # 8000495e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000380a:	08848493          	addi	s1,s1,136
    8000380e:	ff3498e3          	bne	s1,s3,800037fe <iinit+0x3e>
}
    80003812:	70a2                	ld	ra,40(sp)
    80003814:	7402                	ld	s0,32(sp)
    80003816:	64e2                	ld	s1,24(sp)
    80003818:	6942                	ld	s2,16(sp)
    8000381a:	69a2                	ld	s3,8(sp)
    8000381c:	6145                	addi	sp,sp,48
    8000381e:	8082                	ret

0000000080003820 <ialloc>:
{
    80003820:	715d                	addi	sp,sp,-80
    80003822:	e486                	sd	ra,72(sp)
    80003824:	e0a2                	sd	s0,64(sp)
    80003826:	fc26                	sd	s1,56(sp)
    80003828:	f84a                	sd	s2,48(sp)
    8000382a:	f44e                	sd	s3,40(sp)
    8000382c:	f052                	sd	s4,32(sp)
    8000382e:	ec56                	sd	s5,24(sp)
    80003830:	e85a                	sd	s6,16(sp)
    80003832:	e45e                	sd	s7,8(sp)
    80003834:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003836:	00022717          	auipc	a4,0x22
    8000383a:	17e72703          	lw	a4,382(a4) # 800259b4 <sb+0xc>
    8000383e:	4785                	li	a5,1
    80003840:	04e7fa63          	bgeu	a5,a4,80003894 <ialloc+0x74>
    80003844:	8aaa                	mv	s5,a0
    80003846:	8bae                	mv	s7,a1
    80003848:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000384a:	00022a17          	auipc	s4,0x22
    8000384e:	15ea0a13          	addi	s4,s4,350 # 800259a8 <sb>
    80003852:	00048b1b          	sext.w	s6,s1
    80003856:	0044d793          	srli	a5,s1,0x4
    8000385a:	018a2583          	lw	a1,24(s4)
    8000385e:	9dbd                	addw	a1,a1,a5
    80003860:	8556                	mv	a0,s5
    80003862:	00000097          	auipc	ra,0x0
    80003866:	952080e7          	jalr	-1710(ra) # 800031b4 <bread>
    8000386a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000386c:	05850993          	addi	s3,a0,88
    80003870:	00f4f793          	andi	a5,s1,15
    80003874:	079a                	slli	a5,a5,0x6
    80003876:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003878:	00099783          	lh	a5,0(s3)
    8000387c:	c785                	beqz	a5,800038a4 <ialloc+0x84>
    brelse(bp);
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	a66080e7          	jalr	-1434(ra) # 800032e4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003886:	0485                	addi	s1,s1,1
    80003888:	00ca2703          	lw	a4,12(s4)
    8000388c:	0004879b          	sext.w	a5,s1
    80003890:	fce7e1e3          	bltu	a5,a4,80003852 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	ddc50513          	addi	a0,a0,-548 # 80008670 <syscalls+0x168>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	c8e080e7          	jalr	-882(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038a4:	04000613          	li	a2,64
    800038a8:	4581                	li	a1,0
    800038aa:	854e                	mv	a0,s3
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	412080e7          	jalr	1042(ra) # 80000cbe <memset>
      dip->type = type;
    800038b4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	fbe080e7          	jalr	-66(ra) # 80004878 <log_write>
      brelse(bp);
    800038c2:	854a                	mv	a0,s2
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	a20080e7          	jalr	-1504(ra) # 800032e4 <brelse>
      return iget(dev, inum);
    800038cc:	85da                	mv	a1,s6
    800038ce:	8556                	mv	a0,s5
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	db4080e7          	jalr	-588(ra) # 80003684 <iget>
}
    800038d8:	60a6                	ld	ra,72(sp)
    800038da:	6406                	ld	s0,64(sp)
    800038dc:	74e2                	ld	s1,56(sp)
    800038de:	7942                	ld	s2,48(sp)
    800038e0:	79a2                	ld	s3,40(sp)
    800038e2:	7a02                	ld	s4,32(sp)
    800038e4:	6ae2                	ld	s5,24(sp)
    800038e6:	6b42                	ld	s6,16(sp)
    800038e8:	6ba2                	ld	s7,8(sp)
    800038ea:	6161                	addi	sp,sp,80
    800038ec:	8082                	ret

00000000800038ee <iupdate>:
{
    800038ee:	1101                	addi	sp,sp,-32
    800038f0:	ec06                	sd	ra,24(sp)
    800038f2:	e822                	sd	s0,16(sp)
    800038f4:	e426                	sd	s1,8(sp)
    800038f6:	e04a                	sd	s2,0(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038fc:	415c                	lw	a5,4(a0)
    800038fe:	0047d79b          	srliw	a5,a5,0x4
    80003902:	00022597          	auipc	a1,0x22
    80003906:	0be5a583          	lw	a1,190(a1) # 800259c0 <sb+0x18>
    8000390a:	9dbd                	addw	a1,a1,a5
    8000390c:	4108                	lw	a0,0(a0)
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	8a6080e7          	jalr	-1882(ra) # 800031b4 <bread>
    80003916:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003918:	05850793          	addi	a5,a0,88
    8000391c:	40c8                	lw	a0,4(s1)
    8000391e:	893d                	andi	a0,a0,15
    80003920:	051a                	slli	a0,a0,0x6
    80003922:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003924:	04449703          	lh	a4,68(s1)
    80003928:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000392c:	04649703          	lh	a4,70(s1)
    80003930:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003934:	04849703          	lh	a4,72(s1)
    80003938:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000393c:	04a49703          	lh	a4,74(s1)
    80003940:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003944:	44f8                	lw	a4,76(s1)
    80003946:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003948:	03400613          	li	a2,52
    8000394c:	05048593          	addi	a1,s1,80
    80003950:	0531                	addi	a0,a0,12
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	3c8080e7          	jalr	968(ra) # 80000d1a <memmove>
  log_write(bp);
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	f1c080e7          	jalr	-228(ra) # 80004878 <log_write>
  brelse(bp);
    80003964:	854a                	mv	a0,s2
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	97e080e7          	jalr	-1666(ra) # 800032e4 <brelse>
}
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6902                	ld	s2,0(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret

000000008000397a <idup>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	1000                	addi	s0,sp,32
    80003984:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003986:	00022517          	auipc	a0,0x22
    8000398a:	04250513          	addi	a0,a0,66 # 800259c8 <itable>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	234080e7          	jalr	564(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003996:	449c                	lw	a5,8(s1)
    80003998:	2785                	addiw	a5,a5,1
    8000399a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000399c:	00022517          	auipc	a0,0x22
    800039a0:	02c50513          	addi	a0,a0,44 # 800259c8 <itable>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	2d2080e7          	jalr	722(ra) # 80000c76 <release>
}
    800039ac:	8526                	mv	a0,s1
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <ilock>:
{
    800039b8:	1101                	addi	sp,sp,-32
    800039ba:	ec06                	sd	ra,24(sp)
    800039bc:	e822                	sd	s0,16(sp)
    800039be:	e426                	sd	s1,8(sp)
    800039c0:	e04a                	sd	s2,0(sp)
    800039c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039c4:	c115                	beqz	a0,800039e8 <ilock+0x30>
    800039c6:	84aa                	mv	s1,a0
    800039c8:	451c                	lw	a5,8(a0)
    800039ca:	00f05f63          	blez	a5,800039e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039ce:	0541                	addi	a0,a0,16
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	fc8080e7          	jalr	-56(ra) # 80004998 <acquiresleep>
  if(ip->valid == 0){
    800039d8:	40bc                	lw	a5,64(s1)
    800039da:	cf99                	beqz	a5,800039f8 <ilock+0x40>
}
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6902                	ld	s2,0(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret
    panic("ilock");
    800039e8:	00005517          	auipc	a0,0x5
    800039ec:	ca050513          	addi	a0,a0,-864 # 80008688 <syscalls+0x180>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	b3a080e7          	jalr	-1222(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039f8:	40dc                	lw	a5,4(s1)
    800039fa:	0047d79b          	srliw	a5,a5,0x4
    800039fe:	00022597          	auipc	a1,0x22
    80003a02:	fc25a583          	lw	a1,-62(a1) # 800259c0 <sb+0x18>
    80003a06:	9dbd                	addw	a1,a1,a5
    80003a08:	4088                	lw	a0,0(s1)
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	7aa080e7          	jalr	1962(ra) # 800031b4 <bread>
    80003a12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a14:	05850593          	addi	a1,a0,88
    80003a18:	40dc                	lw	a5,4(s1)
    80003a1a:	8bbd                	andi	a5,a5,15
    80003a1c:	079a                	slli	a5,a5,0x6
    80003a1e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a20:	00059783          	lh	a5,0(a1)
    80003a24:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a28:	00259783          	lh	a5,2(a1)
    80003a2c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a30:	00459783          	lh	a5,4(a1)
    80003a34:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a38:	00659783          	lh	a5,6(a1)
    80003a3c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a40:	459c                	lw	a5,8(a1)
    80003a42:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a44:	03400613          	li	a2,52
    80003a48:	05b1                	addi	a1,a1,12
    80003a4a:	05048513          	addi	a0,s1,80
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	2cc080e7          	jalr	716(ra) # 80000d1a <memmove>
    brelse(bp);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	88c080e7          	jalr	-1908(ra) # 800032e4 <brelse>
    ip->valid = 1;
    80003a60:	4785                	li	a5,1
    80003a62:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a64:	04449783          	lh	a5,68(s1)
    80003a68:	fbb5                	bnez	a5,800039dc <ilock+0x24>
      panic("ilock: no type");
    80003a6a:	00005517          	auipc	a0,0x5
    80003a6e:	c2650513          	addi	a0,a0,-986 # 80008690 <syscalls+0x188>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	ab8080e7          	jalr	-1352(ra) # 8000052a <panic>

0000000080003a7a <iunlock>:
{
    80003a7a:	1101                	addi	sp,sp,-32
    80003a7c:	ec06                	sd	ra,24(sp)
    80003a7e:	e822                	sd	s0,16(sp)
    80003a80:	e426                	sd	s1,8(sp)
    80003a82:	e04a                	sd	s2,0(sp)
    80003a84:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a86:	c905                	beqz	a0,80003ab6 <iunlock+0x3c>
    80003a88:	84aa                	mv	s1,a0
    80003a8a:	01050913          	addi	s2,a0,16
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	fa2080e7          	jalr	-94(ra) # 80004a32 <holdingsleep>
    80003a98:	cd19                	beqz	a0,80003ab6 <iunlock+0x3c>
    80003a9a:	449c                	lw	a5,8(s1)
    80003a9c:	00f05d63          	blez	a5,80003ab6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	00001097          	auipc	ra,0x1
    80003aa6:	f4c080e7          	jalr	-180(ra) # 800049ee <releasesleep>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6902                	ld	s2,0(sp)
    80003ab2:	6105                	addi	sp,sp,32
    80003ab4:	8082                	ret
    panic("iunlock");
    80003ab6:	00005517          	auipc	a0,0x5
    80003aba:	bea50513          	addi	a0,a0,-1046 # 800086a0 <syscalls+0x198>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	a6c080e7          	jalr	-1428(ra) # 8000052a <panic>

0000000080003ac6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ac6:	7179                	addi	sp,sp,-48
    80003ac8:	f406                	sd	ra,40(sp)
    80003aca:	f022                	sd	s0,32(sp)
    80003acc:	ec26                	sd	s1,24(sp)
    80003ace:	e84a                	sd	s2,16(sp)
    80003ad0:	e44e                	sd	s3,8(sp)
    80003ad2:	e052                	sd	s4,0(sp)
    80003ad4:	1800                	addi	s0,sp,48
    80003ad6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ad8:	05050493          	addi	s1,a0,80
    80003adc:	08050913          	addi	s2,a0,128
    80003ae0:	a021                	j	80003ae8 <itrunc+0x22>
    80003ae2:	0491                	addi	s1,s1,4
    80003ae4:	01248d63          	beq	s1,s2,80003afe <itrunc+0x38>
    if(ip->addrs[i]){
    80003ae8:	408c                	lw	a1,0(s1)
    80003aea:	dde5                	beqz	a1,80003ae2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aec:	0009a503          	lw	a0,0(s3)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	90a080e7          	jalr	-1782(ra) # 800033fa <bfree>
      ip->addrs[i] = 0;
    80003af8:	0004a023          	sw	zero,0(s1)
    80003afc:	b7dd                	j	80003ae2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003afe:	0809a583          	lw	a1,128(s3)
    80003b02:	e185                	bnez	a1,80003b22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b08:	854e                	mv	a0,s3
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	de4080e7          	jalr	-540(ra) # 800038ee <iupdate>
}
    80003b12:	70a2                	ld	ra,40(sp)
    80003b14:	7402                	ld	s0,32(sp)
    80003b16:	64e2                	ld	s1,24(sp)
    80003b18:	6942                	ld	s2,16(sp)
    80003b1a:	69a2                	ld	s3,8(sp)
    80003b1c:	6a02                	ld	s4,0(sp)
    80003b1e:	6145                	addi	sp,sp,48
    80003b20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b22:	0009a503          	lw	a0,0(s3)
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	68e080e7          	jalr	1678(ra) # 800031b4 <bread>
    80003b2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b30:	05850493          	addi	s1,a0,88
    80003b34:	45850913          	addi	s2,a0,1112
    80003b38:	a021                	j	80003b40 <itrunc+0x7a>
    80003b3a:	0491                	addi	s1,s1,4
    80003b3c:	01248b63          	beq	s1,s2,80003b52 <itrunc+0x8c>
      if(a[j])
    80003b40:	408c                	lw	a1,0(s1)
    80003b42:	dde5                	beqz	a1,80003b3a <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b44:	0009a503          	lw	a0,0(s3)
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	8b2080e7          	jalr	-1870(ra) # 800033fa <bfree>
    80003b50:	b7ed                	j	80003b3a <itrunc+0x74>
    brelse(bp);
    80003b52:	8552                	mv	a0,s4
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	790080e7          	jalr	1936(ra) # 800032e4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b5c:	0809a583          	lw	a1,128(s3)
    80003b60:	0009a503          	lw	a0,0(s3)
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	896080e7          	jalr	-1898(ra) # 800033fa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b6c:	0809a023          	sw	zero,128(s3)
    80003b70:	bf51                	j	80003b04 <itrunc+0x3e>

0000000080003b72 <iput>:
{
    80003b72:	1101                	addi	sp,sp,-32
    80003b74:	ec06                	sd	ra,24(sp)
    80003b76:	e822                	sd	s0,16(sp)
    80003b78:	e426                	sd	s1,8(sp)
    80003b7a:	e04a                	sd	s2,0(sp)
    80003b7c:	1000                	addi	s0,sp,32
    80003b7e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b80:	00022517          	auipc	a0,0x22
    80003b84:	e4850513          	addi	a0,a0,-440 # 800259c8 <itable>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	03a080e7          	jalr	58(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b90:	4498                	lw	a4,8(s1)
    80003b92:	4785                	li	a5,1
    80003b94:	02f70363          	beq	a4,a5,80003bba <iput+0x48>
  ip->ref--;
    80003b98:	449c                	lw	a5,8(s1)
    80003b9a:	37fd                	addiw	a5,a5,-1
    80003b9c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b9e:	00022517          	auipc	a0,0x22
    80003ba2:	e2a50513          	addi	a0,a0,-470 # 800259c8 <itable>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	0d0080e7          	jalr	208(ra) # 80000c76 <release>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6902                	ld	s2,0(sp)
    80003bb6:	6105                	addi	sp,sp,32
    80003bb8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bba:	40bc                	lw	a5,64(s1)
    80003bbc:	dff1                	beqz	a5,80003b98 <iput+0x26>
    80003bbe:	04a49783          	lh	a5,74(s1)
    80003bc2:	fbf9                	bnez	a5,80003b98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bc4:	01048913          	addi	s2,s1,16
    80003bc8:	854a                	mv	a0,s2
    80003bca:	00001097          	auipc	ra,0x1
    80003bce:	dce080e7          	jalr	-562(ra) # 80004998 <acquiresleep>
    release(&itable.lock);
    80003bd2:	00022517          	auipc	a0,0x22
    80003bd6:	df650513          	addi	a0,a0,-522 # 800259c8 <itable>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	09c080e7          	jalr	156(ra) # 80000c76 <release>
    itrunc(ip);
    80003be2:	8526                	mv	a0,s1
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	ee2080e7          	jalr	-286(ra) # 80003ac6 <itrunc>
    ip->type = 0;
    80003bec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	cfc080e7          	jalr	-772(ra) # 800038ee <iupdate>
    ip->valid = 0;
    80003bfa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00001097          	auipc	ra,0x1
    80003c04:	dee080e7          	jalr	-530(ra) # 800049ee <releasesleep>
    acquire(&itable.lock);
    80003c08:	00022517          	auipc	a0,0x22
    80003c0c:	dc050513          	addi	a0,a0,-576 # 800259c8 <itable>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	fb2080e7          	jalr	-78(ra) # 80000bc2 <acquire>
    80003c18:	b741                	j	80003b98 <iput+0x26>

0000000080003c1a <iunlockput>:
{
    80003c1a:	1101                	addi	sp,sp,-32
    80003c1c:	ec06                	sd	ra,24(sp)
    80003c1e:	e822                	sd	s0,16(sp)
    80003c20:	e426                	sd	s1,8(sp)
    80003c22:	1000                	addi	s0,sp,32
    80003c24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	e54080e7          	jalr	-428(ra) # 80003a7a <iunlock>
  iput(ip);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	f42080e7          	jalr	-190(ra) # 80003b72 <iput>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6105                	addi	sp,sp,32
    80003c40:	8082                	ret

0000000080003c42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c42:	1141                	addi	sp,sp,-16
    80003c44:	e422                	sd	s0,8(sp)
    80003c46:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c48:	411c                	lw	a5,0(a0)
    80003c4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c4c:	415c                	lw	a5,4(a0)
    80003c4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c50:	04451783          	lh	a5,68(a0)
    80003c54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c58:	04a51783          	lh	a5,74(a0)
    80003c5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c60:	04c56783          	lwu	a5,76(a0)
    80003c64:	e99c                	sd	a5,16(a1)
}
    80003c66:	6422                	ld	s0,8(sp)
    80003c68:	0141                	addi	sp,sp,16
    80003c6a:	8082                	ret

0000000080003c6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6c:	457c                	lw	a5,76(a0)
    80003c6e:	0ed7e963          	bltu	a5,a3,80003d60 <readi+0xf4>
{
    80003c72:	7159                	addi	sp,sp,-112
    80003c74:	f486                	sd	ra,104(sp)
    80003c76:	f0a2                	sd	s0,96(sp)
    80003c78:	eca6                	sd	s1,88(sp)
    80003c7a:	e8ca                	sd	s2,80(sp)
    80003c7c:	e4ce                	sd	s3,72(sp)
    80003c7e:	e0d2                	sd	s4,64(sp)
    80003c80:	fc56                	sd	s5,56(sp)
    80003c82:	f85a                	sd	s6,48(sp)
    80003c84:	f45e                	sd	s7,40(sp)
    80003c86:	f062                	sd	s8,32(sp)
    80003c88:	ec66                	sd	s9,24(sp)
    80003c8a:	e86a                	sd	s10,16(sp)
    80003c8c:	e46e                	sd	s11,8(sp)
    80003c8e:	1880                	addi	s0,sp,112
    80003c90:	8baa                	mv	s7,a0
    80003c92:	8c2e                	mv	s8,a1
    80003c94:	8ab2                	mv	s5,a2
    80003c96:	84b6                	mv	s1,a3
    80003c98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c9e:	0ad76063          	bltu	a4,a3,80003d3e <readi+0xd2>
  if(off + n > ip->size)
    80003ca2:	00e7f463          	bgeu	a5,a4,80003caa <readi+0x3e>
    n = ip->size - off;
    80003ca6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003caa:	0a0b0963          	beqz	s6,80003d5c <readi+0xf0>
    80003cae:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cb4:	5cfd                	li	s9,-1
    80003cb6:	a82d                	j	80003cf0 <readi+0x84>
    80003cb8:	020a1d93          	slli	s11,s4,0x20
    80003cbc:	020ddd93          	srli	s11,s11,0x20
    80003cc0:	05890793          	addi	a5,s2,88
    80003cc4:	86ee                	mv	a3,s11
    80003cc6:	963e                	add	a2,a2,a5
    80003cc8:	85d6                	mv	a1,s5
    80003cca:	8562                	mv	a0,s8
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	b2c080e7          	jalr	-1236(ra) # 800027f8 <either_copyout>
    80003cd4:	05950d63          	beq	a0,s9,80003d2e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cd8:	854a                	mv	a0,s2
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	60a080e7          	jalr	1546(ra) # 800032e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce2:	013a09bb          	addw	s3,s4,s3
    80003ce6:	009a04bb          	addw	s1,s4,s1
    80003cea:	9aee                	add	s5,s5,s11
    80003cec:	0569f763          	bgeu	s3,s6,80003d3a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cf0:	000ba903          	lw	s2,0(s7)
    80003cf4:	00a4d59b          	srliw	a1,s1,0xa
    80003cf8:	855e                	mv	a0,s7
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	8ae080e7          	jalr	-1874(ra) # 800035a8 <bmap>
    80003d02:	0005059b          	sext.w	a1,a0
    80003d06:	854a                	mv	a0,s2
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	4ac080e7          	jalr	1196(ra) # 800031b4 <bread>
    80003d10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d12:	3ff4f613          	andi	a2,s1,1023
    80003d16:	40cd07bb          	subw	a5,s10,a2
    80003d1a:	413b073b          	subw	a4,s6,s3
    80003d1e:	8a3e                	mv	s4,a5
    80003d20:	2781                	sext.w	a5,a5
    80003d22:	0007069b          	sext.w	a3,a4
    80003d26:	f8f6f9e3          	bgeu	a3,a5,80003cb8 <readi+0x4c>
    80003d2a:	8a3a                	mv	s4,a4
    80003d2c:	b771                	j	80003cb8 <readi+0x4c>
      brelse(bp);
    80003d2e:	854a                	mv	a0,s2
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	5b4080e7          	jalr	1460(ra) # 800032e4 <brelse>
      tot = -1;
    80003d38:	59fd                	li	s3,-1
  }
  return tot;
    80003d3a:	0009851b          	sext.w	a0,s3
}
    80003d3e:	70a6                	ld	ra,104(sp)
    80003d40:	7406                	ld	s0,96(sp)
    80003d42:	64e6                	ld	s1,88(sp)
    80003d44:	6946                	ld	s2,80(sp)
    80003d46:	69a6                	ld	s3,72(sp)
    80003d48:	6a06                	ld	s4,64(sp)
    80003d4a:	7ae2                	ld	s5,56(sp)
    80003d4c:	7b42                	ld	s6,48(sp)
    80003d4e:	7ba2                	ld	s7,40(sp)
    80003d50:	7c02                	ld	s8,32(sp)
    80003d52:	6ce2                	ld	s9,24(sp)
    80003d54:	6d42                	ld	s10,16(sp)
    80003d56:	6da2                	ld	s11,8(sp)
    80003d58:	6165                	addi	sp,sp,112
    80003d5a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d5c:	89da                	mv	s3,s6
    80003d5e:	bff1                	j	80003d3a <readi+0xce>
    return 0;
    80003d60:	4501                	li	a0,0
}
    80003d62:	8082                	ret

0000000080003d64 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d64:	457c                	lw	a5,76(a0)
    80003d66:	10d7e863          	bltu	a5,a3,80003e76 <writei+0x112>
{
    80003d6a:	7159                	addi	sp,sp,-112
    80003d6c:	f486                	sd	ra,104(sp)
    80003d6e:	f0a2                	sd	s0,96(sp)
    80003d70:	eca6                	sd	s1,88(sp)
    80003d72:	e8ca                	sd	s2,80(sp)
    80003d74:	e4ce                	sd	s3,72(sp)
    80003d76:	e0d2                	sd	s4,64(sp)
    80003d78:	fc56                	sd	s5,56(sp)
    80003d7a:	f85a                	sd	s6,48(sp)
    80003d7c:	f45e                	sd	s7,40(sp)
    80003d7e:	f062                	sd	s8,32(sp)
    80003d80:	ec66                	sd	s9,24(sp)
    80003d82:	e86a                	sd	s10,16(sp)
    80003d84:	e46e                	sd	s11,8(sp)
    80003d86:	1880                	addi	s0,sp,112
    80003d88:	8b2a                	mv	s6,a0
    80003d8a:	8c2e                	mv	s8,a1
    80003d8c:	8ab2                	mv	s5,a2
    80003d8e:	8936                	mv	s2,a3
    80003d90:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d92:	00e687bb          	addw	a5,a3,a4
    80003d96:	0ed7e263          	bltu	a5,a3,80003e7a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d9a:	00043737          	lui	a4,0x43
    80003d9e:	0ef76063          	bltu	a4,a5,80003e7e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da2:	0c0b8863          	beqz	s7,80003e72 <writei+0x10e>
    80003da6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dac:	5cfd                	li	s9,-1
    80003dae:	a091                	j	80003df2 <writei+0x8e>
    80003db0:	02099d93          	slli	s11,s3,0x20
    80003db4:	020ddd93          	srli	s11,s11,0x20
    80003db8:	05848793          	addi	a5,s1,88
    80003dbc:	86ee                	mv	a3,s11
    80003dbe:	8656                	mv	a2,s5
    80003dc0:	85e2                	mv	a1,s8
    80003dc2:	953e                	add	a0,a0,a5
    80003dc4:	fffff097          	auipc	ra,0xfffff
    80003dc8:	a8a080e7          	jalr	-1398(ra) # 8000284e <either_copyin>
    80003dcc:	07950263          	beq	a0,s9,80003e30 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dd0:	8526                	mv	a0,s1
    80003dd2:	00001097          	auipc	ra,0x1
    80003dd6:	aa6080e7          	jalr	-1370(ra) # 80004878 <log_write>
    brelse(bp);
    80003dda:	8526                	mv	a0,s1
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	508080e7          	jalr	1288(ra) # 800032e4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de4:	01498a3b          	addw	s4,s3,s4
    80003de8:	0129893b          	addw	s2,s3,s2
    80003dec:	9aee                	add	s5,s5,s11
    80003dee:	057a7663          	bgeu	s4,s7,80003e3a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003df2:	000b2483          	lw	s1,0(s6)
    80003df6:	00a9559b          	srliw	a1,s2,0xa
    80003dfa:	855a                	mv	a0,s6
    80003dfc:	fffff097          	auipc	ra,0xfffff
    80003e00:	7ac080e7          	jalr	1964(ra) # 800035a8 <bmap>
    80003e04:	0005059b          	sext.w	a1,a0
    80003e08:	8526                	mv	a0,s1
    80003e0a:	fffff097          	auipc	ra,0xfffff
    80003e0e:	3aa080e7          	jalr	938(ra) # 800031b4 <bread>
    80003e12:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e14:	3ff97513          	andi	a0,s2,1023
    80003e18:	40ad07bb          	subw	a5,s10,a0
    80003e1c:	414b873b          	subw	a4,s7,s4
    80003e20:	89be                	mv	s3,a5
    80003e22:	2781                	sext.w	a5,a5
    80003e24:	0007069b          	sext.w	a3,a4
    80003e28:	f8f6f4e3          	bgeu	a3,a5,80003db0 <writei+0x4c>
    80003e2c:	89ba                	mv	s3,a4
    80003e2e:	b749                	j	80003db0 <writei+0x4c>
      brelse(bp);
    80003e30:	8526                	mv	a0,s1
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	4b2080e7          	jalr	1202(ra) # 800032e4 <brelse>
  }

  if(off > ip->size)
    80003e3a:	04cb2783          	lw	a5,76(s6)
    80003e3e:	0127f463          	bgeu	a5,s2,80003e46 <writei+0xe2>
    ip->size = off;
    80003e42:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e46:	855a                	mv	a0,s6
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	aa6080e7          	jalr	-1370(ra) # 800038ee <iupdate>

  return tot;
    80003e50:	000a051b          	sext.w	a0,s4
}
    80003e54:	70a6                	ld	ra,104(sp)
    80003e56:	7406                	ld	s0,96(sp)
    80003e58:	64e6                	ld	s1,88(sp)
    80003e5a:	6946                	ld	s2,80(sp)
    80003e5c:	69a6                	ld	s3,72(sp)
    80003e5e:	6a06                	ld	s4,64(sp)
    80003e60:	7ae2                	ld	s5,56(sp)
    80003e62:	7b42                	ld	s6,48(sp)
    80003e64:	7ba2                	ld	s7,40(sp)
    80003e66:	7c02                	ld	s8,32(sp)
    80003e68:	6ce2                	ld	s9,24(sp)
    80003e6a:	6d42                	ld	s10,16(sp)
    80003e6c:	6da2                	ld	s11,8(sp)
    80003e6e:	6165                	addi	sp,sp,112
    80003e70:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e72:	8a5e                	mv	s4,s7
    80003e74:	bfc9                	j	80003e46 <writei+0xe2>
    return -1;
    80003e76:	557d                	li	a0,-1
}
    80003e78:	8082                	ret
    return -1;
    80003e7a:	557d                	li	a0,-1
    80003e7c:	bfe1                	j	80003e54 <writei+0xf0>
    return -1;
    80003e7e:	557d                	li	a0,-1
    80003e80:	bfd1                	j	80003e54 <writei+0xf0>

0000000080003e82 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e82:	1141                	addi	sp,sp,-16
    80003e84:	e406                	sd	ra,8(sp)
    80003e86:	e022                	sd	s0,0(sp)
    80003e88:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e8a:	4639                	li	a2,14
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	f0a080e7          	jalr	-246(ra) # 80000d96 <strncmp>
}
    80003e94:	60a2                	ld	ra,8(sp)
    80003e96:	6402                	ld	s0,0(sp)
    80003e98:	0141                	addi	sp,sp,16
    80003e9a:	8082                	ret

0000000080003e9c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e9c:	7139                	addi	sp,sp,-64
    80003e9e:	fc06                	sd	ra,56(sp)
    80003ea0:	f822                	sd	s0,48(sp)
    80003ea2:	f426                	sd	s1,40(sp)
    80003ea4:	f04a                	sd	s2,32(sp)
    80003ea6:	ec4e                	sd	s3,24(sp)
    80003ea8:	e852                	sd	s4,16(sp)
    80003eaa:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003eac:	04451703          	lh	a4,68(a0)
    80003eb0:	4785                	li	a5,1
    80003eb2:	00f71a63          	bne	a4,a5,80003ec6 <dirlookup+0x2a>
    80003eb6:	892a                	mv	s2,a0
    80003eb8:	89ae                	mv	s3,a1
    80003eba:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebc:	457c                	lw	a5,76(a0)
    80003ebe:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ec0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec2:	e79d                	bnez	a5,80003ef0 <dirlookup+0x54>
    80003ec4:	a8a5                	j	80003f3c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ec6:	00004517          	auipc	a0,0x4
    80003eca:	7e250513          	addi	a0,a0,2018 # 800086a8 <syscalls+0x1a0>
    80003ece:	ffffc097          	auipc	ra,0xffffc
    80003ed2:	65c080e7          	jalr	1628(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003ed6:	00004517          	auipc	a0,0x4
    80003eda:	7ea50513          	addi	a0,a0,2026 # 800086c0 <syscalls+0x1b8>
    80003ede:	ffffc097          	auipc	ra,0xffffc
    80003ee2:	64c080e7          	jalr	1612(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	24c1                	addiw	s1,s1,16
    80003ee8:	04c92783          	lw	a5,76(s2)
    80003eec:	04f4f763          	bgeu	s1,a5,80003f3a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef0:	4741                	li	a4,16
    80003ef2:	86a6                	mv	a3,s1
    80003ef4:	fc040613          	addi	a2,s0,-64
    80003ef8:	4581                	li	a1,0
    80003efa:	854a                	mv	a0,s2
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	d70080e7          	jalr	-656(ra) # 80003c6c <readi>
    80003f04:	47c1                	li	a5,16
    80003f06:	fcf518e3          	bne	a0,a5,80003ed6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f0a:	fc045783          	lhu	a5,-64(s0)
    80003f0e:	dfe1                	beqz	a5,80003ee6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f10:	fc240593          	addi	a1,s0,-62
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	f6c080e7          	jalr	-148(ra) # 80003e82 <namecmp>
    80003f1e:	f561                	bnez	a0,80003ee6 <dirlookup+0x4a>
      if(poff)
    80003f20:	000a0463          	beqz	s4,80003f28 <dirlookup+0x8c>
        *poff = off;
    80003f24:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f28:	fc045583          	lhu	a1,-64(s0)
    80003f2c:	00092503          	lw	a0,0(s2)
    80003f30:	fffff097          	auipc	ra,0xfffff
    80003f34:	754080e7          	jalr	1876(ra) # 80003684 <iget>
    80003f38:	a011                	j	80003f3c <dirlookup+0xa0>
  return 0;
    80003f3a:	4501                	li	a0,0
}
    80003f3c:	70e2                	ld	ra,56(sp)
    80003f3e:	7442                	ld	s0,48(sp)
    80003f40:	74a2                	ld	s1,40(sp)
    80003f42:	7902                	ld	s2,32(sp)
    80003f44:	69e2                	ld	s3,24(sp)
    80003f46:	6a42                	ld	s4,16(sp)
    80003f48:	6121                	addi	sp,sp,64
    80003f4a:	8082                	ret

0000000080003f4c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f4c:	711d                	addi	sp,sp,-96
    80003f4e:	ec86                	sd	ra,88(sp)
    80003f50:	e8a2                	sd	s0,80(sp)
    80003f52:	e4a6                	sd	s1,72(sp)
    80003f54:	e0ca                	sd	s2,64(sp)
    80003f56:	fc4e                	sd	s3,56(sp)
    80003f58:	f852                	sd	s4,48(sp)
    80003f5a:	f456                	sd	s5,40(sp)
    80003f5c:	f05a                	sd	s6,32(sp)
    80003f5e:	ec5e                	sd	s7,24(sp)
    80003f60:	e862                	sd	s8,16(sp)
    80003f62:	e466                	sd	s9,8(sp)
    80003f64:	1080                	addi	s0,sp,96
    80003f66:	84aa                	mv	s1,a0
    80003f68:	8aae                	mv	s5,a1
    80003f6a:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f6c:	00054703          	lbu	a4,0(a0)
    80003f70:	02f00793          	li	a5,47
    80003f74:	02f70363          	beq	a4,a5,80003f9a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f78:	ffffe097          	auipc	ra,0xffffe
    80003f7c:	c9c080e7          	jalr	-868(ra) # 80001c14 <myproc>
    80003f80:	15053503          	ld	a0,336(a0)
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	9f6080e7          	jalr	-1546(ra) # 8000397a <idup>
    80003f8c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f8e:	02f00913          	li	s2,47
  len = path - s;
    80003f92:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f94:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f96:	4b85                	li	s7,1
    80003f98:	a865                	j	80004050 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f9a:	4585                	li	a1,1
    80003f9c:	4505                	li	a0,1
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	6e6080e7          	jalr	1766(ra) # 80003684 <iget>
    80003fa6:	89aa                	mv	s3,a0
    80003fa8:	b7dd                	j	80003f8e <namex+0x42>
      iunlockput(ip);
    80003faa:	854e                	mv	a0,s3
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	c6e080e7          	jalr	-914(ra) # 80003c1a <iunlockput>
      return 0;
    80003fb4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fb6:	854e                	mv	a0,s3
    80003fb8:	60e6                	ld	ra,88(sp)
    80003fba:	6446                	ld	s0,80(sp)
    80003fbc:	64a6                	ld	s1,72(sp)
    80003fbe:	6906                	ld	s2,64(sp)
    80003fc0:	79e2                	ld	s3,56(sp)
    80003fc2:	7a42                	ld	s4,48(sp)
    80003fc4:	7aa2                	ld	s5,40(sp)
    80003fc6:	7b02                	ld	s6,32(sp)
    80003fc8:	6be2                	ld	s7,24(sp)
    80003fca:	6c42                	ld	s8,16(sp)
    80003fcc:	6ca2                	ld	s9,8(sp)
    80003fce:	6125                	addi	sp,sp,96
    80003fd0:	8082                	ret
      iunlock(ip);
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	aa6080e7          	jalr	-1370(ra) # 80003a7a <iunlock>
      return ip;
    80003fdc:	bfe9                	j	80003fb6 <namex+0x6a>
      iunlockput(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	c3a080e7          	jalr	-966(ra) # 80003c1a <iunlockput>
      return 0;
    80003fe8:	89e6                	mv	s3,s9
    80003fea:	b7f1                	j	80003fb6 <namex+0x6a>
  len = path - s;
    80003fec:	40b48633          	sub	a2,s1,a1
    80003ff0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003ff4:	099c5463          	bge	s8,s9,8000407c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ff8:	4639                	li	a2,14
    80003ffa:	8552                	mv	a0,s4
    80003ffc:	ffffd097          	auipc	ra,0xffffd
    80004000:	d1e080e7          	jalr	-738(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	01279763          	bne	a5,s2,80004016 <namex+0xca>
    path++;
    8000400c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	ff278de3          	beq	a5,s2,8000400c <namex+0xc0>
    ilock(ip);
    80004016:	854e                	mv	a0,s3
    80004018:	00000097          	auipc	ra,0x0
    8000401c:	9a0080e7          	jalr	-1632(ra) # 800039b8 <ilock>
    if(ip->type != T_DIR){
    80004020:	04499783          	lh	a5,68(s3)
    80004024:	f97793e3          	bne	a5,s7,80003faa <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004028:	000a8563          	beqz	s5,80004032 <namex+0xe6>
    8000402c:	0004c783          	lbu	a5,0(s1)
    80004030:	d3cd                	beqz	a5,80003fd2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004032:	865a                	mv	a2,s6
    80004034:	85d2                	mv	a1,s4
    80004036:	854e                	mv	a0,s3
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	e64080e7          	jalr	-412(ra) # 80003e9c <dirlookup>
    80004040:	8caa                	mv	s9,a0
    80004042:	dd51                	beqz	a0,80003fde <namex+0x92>
    iunlockput(ip);
    80004044:	854e                	mv	a0,s3
    80004046:	00000097          	auipc	ra,0x0
    8000404a:	bd4080e7          	jalr	-1068(ra) # 80003c1a <iunlockput>
    ip = next;
    8000404e:	89e6                	mv	s3,s9
  while(*path == '/')
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	05279763          	bne	a5,s2,800040a2 <namex+0x156>
    path++;
    80004058:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000405a:	0004c783          	lbu	a5,0(s1)
    8000405e:	ff278de3          	beq	a5,s2,80004058 <namex+0x10c>
  if(*path == 0)
    80004062:	c79d                	beqz	a5,80004090 <namex+0x144>
    path++;
    80004064:	85a6                	mv	a1,s1
  len = path - s;
    80004066:	8cda                	mv	s9,s6
    80004068:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000406a:	01278963          	beq	a5,s2,8000407c <namex+0x130>
    8000406e:	dfbd                	beqz	a5,80003fec <namex+0xa0>
    path++;
    80004070:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004072:	0004c783          	lbu	a5,0(s1)
    80004076:	ff279ce3          	bne	a5,s2,8000406e <namex+0x122>
    8000407a:	bf8d                	j	80003fec <namex+0xa0>
    memmove(name, s, len);
    8000407c:	2601                	sext.w	a2,a2
    8000407e:	8552                	mv	a0,s4
    80004080:	ffffd097          	auipc	ra,0xffffd
    80004084:	c9a080e7          	jalr	-870(ra) # 80000d1a <memmove>
    name[len] = 0;
    80004088:	9cd2                	add	s9,s9,s4
    8000408a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000408e:	bf9d                	j	80004004 <namex+0xb8>
  if(nameiparent){
    80004090:	f20a83e3          	beqz	s5,80003fb6 <namex+0x6a>
    iput(ip);
    80004094:	854e                	mv	a0,s3
    80004096:	00000097          	auipc	ra,0x0
    8000409a:	adc080e7          	jalr	-1316(ra) # 80003b72 <iput>
    return 0;
    8000409e:	4981                	li	s3,0
    800040a0:	bf19                	j	80003fb6 <namex+0x6a>
  if(*path == 0)
    800040a2:	d7fd                	beqz	a5,80004090 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040a4:	0004c783          	lbu	a5,0(s1)
    800040a8:	85a6                	mv	a1,s1
    800040aa:	b7d1                	j	8000406e <namex+0x122>

00000000800040ac <dirlink>:
{
    800040ac:	7139                	addi	sp,sp,-64
    800040ae:	fc06                	sd	ra,56(sp)
    800040b0:	f822                	sd	s0,48(sp)
    800040b2:	f426                	sd	s1,40(sp)
    800040b4:	f04a                	sd	s2,32(sp)
    800040b6:	ec4e                	sd	s3,24(sp)
    800040b8:	e852                	sd	s4,16(sp)
    800040ba:	0080                	addi	s0,sp,64
    800040bc:	892a                	mv	s2,a0
    800040be:	8a2e                	mv	s4,a1
    800040c0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040c2:	4601                	li	a2,0
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	dd8080e7          	jalr	-552(ra) # 80003e9c <dirlookup>
    800040cc:	e93d                	bnez	a0,80004142 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ce:	04c92483          	lw	s1,76(s2)
    800040d2:	c49d                	beqz	s1,80004100 <dirlink+0x54>
    800040d4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d6:	4741                	li	a4,16
    800040d8:	86a6                	mv	a3,s1
    800040da:	fc040613          	addi	a2,s0,-64
    800040de:	4581                	li	a1,0
    800040e0:	854a                	mv	a0,s2
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	b8a080e7          	jalr	-1142(ra) # 80003c6c <readi>
    800040ea:	47c1                	li	a5,16
    800040ec:	06f51163          	bne	a0,a5,8000414e <dirlink+0xa2>
    if(de.inum == 0)
    800040f0:	fc045783          	lhu	a5,-64(s0)
    800040f4:	c791                	beqz	a5,80004100 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f6:	24c1                	addiw	s1,s1,16
    800040f8:	04c92783          	lw	a5,76(s2)
    800040fc:	fcf4ede3          	bltu	s1,a5,800040d6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004100:	4639                	li	a2,14
    80004102:	85d2                	mv	a1,s4
    80004104:	fc240513          	addi	a0,s0,-62
    80004108:	ffffd097          	auipc	ra,0xffffd
    8000410c:	cca080e7          	jalr	-822(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004110:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004114:	4741                	li	a4,16
    80004116:	86a6                	mv	a3,s1
    80004118:	fc040613          	addi	a2,s0,-64
    8000411c:	4581                	li	a1,0
    8000411e:	854a                	mv	a0,s2
    80004120:	00000097          	auipc	ra,0x0
    80004124:	c44080e7          	jalr	-956(ra) # 80003d64 <writei>
    80004128:	872a                	mv	a4,a0
    8000412a:	47c1                	li	a5,16
  return 0;
    8000412c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412e:	02f71863          	bne	a4,a5,8000415e <dirlink+0xb2>
}
    80004132:	70e2                	ld	ra,56(sp)
    80004134:	7442                	ld	s0,48(sp)
    80004136:	74a2                	ld	s1,40(sp)
    80004138:	7902                	ld	s2,32(sp)
    8000413a:	69e2                	ld	s3,24(sp)
    8000413c:	6a42                	ld	s4,16(sp)
    8000413e:	6121                	addi	sp,sp,64
    80004140:	8082                	ret
    iput(ip);
    80004142:	00000097          	auipc	ra,0x0
    80004146:	a30080e7          	jalr	-1488(ra) # 80003b72 <iput>
    return -1;
    8000414a:	557d                	li	a0,-1
    8000414c:	b7dd                	j	80004132 <dirlink+0x86>
      panic("dirlink read");
    8000414e:	00004517          	auipc	a0,0x4
    80004152:	58250513          	addi	a0,a0,1410 # 800086d0 <syscalls+0x1c8>
    80004156:	ffffc097          	auipc	ra,0xffffc
    8000415a:	3d4080e7          	jalr	980(ra) # 8000052a <panic>
    panic("dirlink");
    8000415e:	00004517          	auipc	a0,0x4
    80004162:	6fa50513          	addi	a0,a0,1786 # 80008858 <syscalls+0x350>
    80004166:	ffffc097          	auipc	ra,0xffffc
    8000416a:	3c4080e7          	jalr	964(ra) # 8000052a <panic>

000000008000416e <namei>:

struct inode*
namei(char *path)
{
    8000416e:	1101                	addi	sp,sp,-32
    80004170:	ec06                	sd	ra,24(sp)
    80004172:	e822                	sd	s0,16(sp)
    80004174:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004176:	fe040613          	addi	a2,s0,-32
    8000417a:	4581                	li	a1,0
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	dd0080e7          	jalr	-560(ra) # 80003f4c <namex>
}
    80004184:	60e2                	ld	ra,24(sp)
    80004186:	6442                	ld	s0,16(sp)
    80004188:	6105                	addi	sp,sp,32
    8000418a:	8082                	ret

000000008000418c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000418c:	1141                	addi	sp,sp,-16
    8000418e:	e406                	sd	ra,8(sp)
    80004190:	e022                	sd	s0,0(sp)
    80004192:	0800                	addi	s0,sp,16
    80004194:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004196:	4585                	li	a1,1
    80004198:	00000097          	auipc	ra,0x0
    8000419c:	db4080e7          	jalr	-588(ra) # 80003f4c <namex>
}
    800041a0:	60a2                	ld	ra,8(sp)
    800041a2:	6402                	ld	s0,0(sp)
    800041a4:	0141                	addi	sp,sp,16
    800041a6:	8082                	ret

00000000800041a8 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    800041a8:	1101                	addi	sp,sp,-32
    800041aa:	ec22                	sd	s0,24(sp)
    800041ac:	1000                	addi	s0,sp,32
    800041ae:	872a                	mv	a4,a0
    800041b0:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    800041b2:	00004797          	auipc	a5,0x4
    800041b6:	52e78793          	addi	a5,a5,1326 # 800086e0 <syscalls+0x1d8>
    800041ba:	6394                	ld	a3,0(a5)
    800041bc:	fed43023          	sd	a3,-32(s0)
    800041c0:	0087d683          	lhu	a3,8(a5)
    800041c4:	fed41423          	sh	a3,-24(s0)
    800041c8:	00a7c783          	lbu	a5,10(a5)
    800041cc:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    800041d0:	87ae                	mv	a5,a1
    if(i<0){
    800041d2:	02074b63          	bltz	a4,80004208 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    800041d6:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    800041d8:	4629                	li	a2,10
        ++p;
    800041da:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    800041dc:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    800041e0:	feed                	bnez	a3,800041da <itoa+0x32>
    *p = '\0';
    800041e2:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    800041e6:	4629                	li	a2,10
    800041e8:	17fd                	addi	a5,a5,-1
    800041ea:	02c766bb          	remw	a3,a4,a2
    800041ee:	ff040593          	addi	a1,s0,-16
    800041f2:	96ae                	add	a3,a3,a1
    800041f4:	ff06c683          	lbu	a3,-16(a3)
    800041f8:	00d78023          	sb	a3,0(a5)
        i = i/10;
    800041fc:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004200:	f765                	bnez	a4,800041e8 <itoa+0x40>
    return b;
}
    80004202:	6462                	ld	s0,24(sp)
    80004204:	6105                	addi	sp,sp,32
    80004206:	8082                	ret
        *p++ = '-';
    80004208:	00158793          	addi	a5,a1,1
    8000420c:	02d00693          	li	a3,45
    80004210:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004214:	40e0073b          	negw	a4,a4
    80004218:	bf7d                	j	800041d6 <itoa+0x2e>

000000008000421a <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    8000421a:	711d                	addi	sp,sp,-96
    8000421c:	ec86                	sd	ra,88(sp)
    8000421e:	e8a2                	sd	s0,80(sp)
    80004220:	e4a6                	sd	s1,72(sp)
    80004222:	e0ca                	sd	s2,64(sp)
    80004224:	1080                	addi	s0,sp,96
    80004226:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004228:	4619                	li	a2,6
    8000422a:	00004597          	auipc	a1,0x4
    8000422e:	4c658593          	addi	a1,a1,1222 # 800086f0 <syscalls+0x1e8>
    80004232:	fd040513          	addi	a0,s0,-48
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	ae4080e7          	jalr	-1308(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    8000423e:	fd640593          	addi	a1,s0,-42
    80004242:	5888                	lw	a0,48(s1)
    80004244:	00000097          	auipc	ra,0x0
    80004248:	f64080e7          	jalr	-156(ra) # 800041a8 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    8000424c:	1684b503          	ld	a0,360(s1)
    80004250:	16050763          	beqz	a0,800043be <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004254:	00001097          	auipc	ra,0x1
    80004258:	918080e7          	jalr	-1768(ra) # 80004b6c <fileclose>

  begin_op();
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	444080e7          	jalr	1092(ra) # 800046a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004264:	fb040593          	addi	a1,s0,-80
    80004268:	fd040513          	addi	a0,s0,-48
    8000426c:	00000097          	auipc	ra,0x0
    80004270:	f20080e7          	jalr	-224(ra) # 8000418c <nameiparent>
    80004274:	892a                	mv	s2,a0
    80004276:	cd69                	beqz	a0,80004350 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	740080e7          	jalr	1856(ra) # 800039b8 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004280:	00004597          	auipc	a1,0x4
    80004284:	47858593          	addi	a1,a1,1144 # 800086f8 <syscalls+0x1f0>
    80004288:	fb040513          	addi	a0,s0,-80
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	bf6080e7          	jalr	-1034(ra) # 80003e82 <namecmp>
    80004294:	c57d                	beqz	a0,80004382 <removeSwapFile+0x168>
    80004296:	00004597          	auipc	a1,0x4
    8000429a:	46a58593          	addi	a1,a1,1130 # 80008700 <syscalls+0x1f8>
    8000429e:	fb040513          	addi	a0,s0,-80
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	be0080e7          	jalr	-1056(ra) # 80003e82 <namecmp>
    800042aa:	cd61                	beqz	a0,80004382 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800042ac:	fac40613          	addi	a2,s0,-84
    800042b0:	fb040593          	addi	a1,s0,-80
    800042b4:	854a                	mv	a0,s2
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	be6080e7          	jalr	-1050(ra) # 80003e9c <dirlookup>
    800042be:	84aa                	mv	s1,a0
    800042c0:	c169                	beqz	a0,80004382 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    800042c2:	fffff097          	auipc	ra,0xfffff
    800042c6:	6f6080e7          	jalr	1782(ra) # 800039b8 <ilock>

  if(ip->nlink < 1)
    800042ca:	04a49783          	lh	a5,74(s1)
    800042ce:	08f05763          	blez	a5,8000435c <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    800042d2:	04449703          	lh	a4,68(s1)
    800042d6:	4785                	li	a5,1
    800042d8:	08f70a63          	beq	a4,a5,8000436c <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800042dc:	4641                	li	a2,16
    800042de:	4581                	li	a1,0
    800042e0:	fc040513          	addi	a0,s0,-64
    800042e4:	ffffd097          	auipc	ra,0xffffd
    800042e8:	9da080e7          	jalr	-1574(ra) # 80000cbe <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ec:	4741                	li	a4,16
    800042ee:	fac42683          	lw	a3,-84(s0)
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	a6a080e7          	jalr	-1430(ra) # 80003d64 <writei>
    80004302:	47c1                	li	a5,16
    80004304:	08f51a63          	bne	a0,a5,80004398 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004308:	04449703          	lh	a4,68(s1)
    8000430c:	4785                	li	a5,1
    8000430e:	08f70d63          	beq	a4,a5,800043a8 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004312:	854a                	mv	a0,s2
    80004314:	00000097          	auipc	ra,0x0
    80004318:	906080e7          	jalr	-1786(ra) # 80003c1a <iunlockput>

  ip->nlink--;
    8000431c:	04a4d783          	lhu	a5,74(s1)
    80004320:	37fd                	addiw	a5,a5,-1
    80004322:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004326:	8526                	mv	a0,s1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	5c6080e7          	jalr	1478(ra) # 800038ee <iupdate>
  iunlockput(ip);
    80004330:	8526                	mv	a0,s1
    80004332:	00000097          	auipc	ra,0x0
    80004336:	8e8080e7          	jalr	-1816(ra) # 80003c1a <iunlockput>

  end_op();
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	3e6080e7          	jalr	998(ra) # 80004720 <end_op>

  return 0;
    80004342:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004344:	60e6                	ld	ra,88(sp)
    80004346:	6446                	ld	s0,80(sp)
    80004348:	64a6                	ld	s1,72(sp)
    8000434a:	6906                	ld	s2,64(sp)
    8000434c:	6125                	addi	sp,sp,96
    8000434e:	8082                	ret
    end_op();
    80004350:	00000097          	auipc	ra,0x0
    80004354:	3d0080e7          	jalr	976(ra) # 80004720 <end_op>
    return -1;
    80004358:	557d                	li	a0,-1
    8000435a:	b7ed                	j	80004344 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    8000435c:	00004517          	auipc	a0,0x4
    80004360:	3ac50513          	addi	a0,a0,940 # 80008708 <syscalls+0x200>
    80004364:	ffffc097          	auipc	ra,0xffffc
    80004368:	1c6080e7          	jalr	454(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000436c:	8526                	mv	a0,s1
    8000436e:	00001097          	auipc	ra,0x1
    80004372:	798080e7          	jalr	1944(ra) # 80005b06 <isdirempty>
    80004376:	f13d                	bnez	a0,800042dc <removeSwapFile+0xc2>
    iunlockput(ip);
    80004378:	8526                	mv	a0,s1
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	8a0080e7          	jalr	-1888(ra) # 80003c1a <iunlockput>
    iunlockput(dp);
    80004382:	854a                	mv	a0,s2
    80004384:	00000097          	auipc	ra,0x0
    80004388:	896080e7          	jalr	-1898(ra) # 80003c1a <iunlockput>
    end_op();
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	394080e7          	jalr	916(ra) # 80004720 <end_op>
    return -1;
    80004394:	557d                	li	a0,-1
    80004396:	b77d                	j	80004344 <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004398:	00004517          	auipc	a0,0x4
    8000439c:	38850513          	addi	a0,a0,904 # 80008720 <syscalls+0x218>
    800043a0:	ffffc097          	auipc	ra,0xffffc
    800043a4:	18a080e7          	jalr	394(ra) # 8000052a <panic>
    dp->nlink--;
    800043a8:	04a95783          	lhu	a5,74(s2)
    800043ac:	37fd                	addiw	a5,a5,-1
    800043ae:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800043b2:	854a                	mv	a0,s2
    800043b4:	fffff097          	auipc	ra,0xfffff
    800043b8:	53a080e7          	jalr	1338(ra) # 800038ee <iupdate>
    800043bc:	bf99                	j	80004312 <removeSwapFile+0xf8>
    return -1;
    800043be:	557d                	li	a0,-1
    800043c0:	b751                	j	80004344 <removeSwapFile+0x12a>

00000000800043c2 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    800043c2:	7179                	addi	sp,sp,-48
    800043c4:	f406                	sd	ra,40(sp)
    800043c6:	f022                	sd	s0,32(sp)
    800043c8:	ec26                	sd	s1,24(sp)
    800043ca:	e84a                	sd	s2,16(sp)
    800043cc:	1800                	addi	s0,sp,48
    800043ce:	84aa                	mv	s1,a0

  char path[DIGITS];
  memmove(path,"/.swap", 6);
    800043d0:	4619                	li	a2,6
    800043d2:	00004597          	auipc	a1,0x4
    800043d6:	31e58593          	addi	a1,a1,798 # 800086f0 <syscalls+0x1e8>
    800043da:	fd040513          	addi	a0,s0,-48
    800043de:	ffffd097          	auipc	ra,0xffffd
    800043e2:	93c080e7          	jalr	-1732(ra) # 80000d1a <memmove>
  itoa(p->pid, path+ 6);
    800043e6:	fd640593          	addi	a1,s0,-42
    800043ea:	5888                	lw	a0,48(s1)
    800043ec:	00000097          	auipc	ra,0x0
    800043f0:	dbc080e7          	jalr	-580(ra) # 800041a8 <itoa>

  begin_op();
    800043f4:	00000097          	auipc	ra,0x0
    800043f8:	2ac080e7          	jalr	684(ra) # 800046a0 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    800043fc:	4681                	li	a3,0
    800043fe:	4601                	li	a2,0
    80004400:	4589                	li	a1,2
    80004402:	fd040513          	addi	a0,s0,-48
    80004406:	00002097          	auipc	ra,0x2
    8000440a:	8f4080e7          	jalr	-1804(ra) # 80005cfa <create>
    8000440e:	892a                	mv	s2,a0
  iunlock(in);
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	66a080e7          	jalr	1642(ra) # 80003a7a <iunlock>
  p->swapFile = filealloc();
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	698080e7          	jalr	1688(ra) # 80004ab0 <filealloc>
    80004420:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004424:	cd1d                	beqz	a0,80004462 <createSwapFile+0xa0>
    panic("no slot for files on /store");

  p->swapFile->ip = in;
    80004426:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    8000442a:	1684b703          	ld	a4,360(s1)
    8000442e:	4789                	li	a5,2
    80004430:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004432:	1684b703          	ld	a4,360(s1)
    80004436:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    8000443a:	1684b703          	ld	a4,360(s1)
    8000443e:	4685                	li	a3,1
    80004440:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004444:	1684b703          	ld	a4,360(s1)
    80004448:	00f704a3          	sb	a5,9(a4)
    end_op();
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	2d4080e7          	jalr	724(ra) # 80004720 <end_op>

    return 0;
}
    80004454:	4501                	li	a0,0
    80004456:	70a2                	ld	ra,40(sp)
    80004458:	7402                	ld	s0,32(sp)
    8000445a:	64e2                	ld	s1,24(sp)
    8000445c:	6942                	ld	s2,16(sp)
    8000445e:	6145                	addi	sp,sp,48
    80004460:	8082                	ret
    panic("no slot for files on /store");
    80004462:	00004517          	auipc	a0,0x4
    80004466:	2ce50513          	addi	a0,a0,718 # 80008730 <syscalls+0x228>
    8000446a:	ffffc097          	auipc	ra,0xffffc
    8000446e:	0c0080e7          	jalr	192(ra) # 8000052a <panic>

0000000080004472 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004472:	1141                	addi	sp,sp,-16
    80004474:	e406                	sd	ra,8(sp)
    80004476:	e022                	sd	s0,0(sp)
    80004478:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000447a:	16853783          	ld	a5,360(a0)
    8000447e:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004480:	8636                	mv	a2,a3
    80004482:	16853503          	ld	a0,360(a0)
    80004486:	00001097          	auipc	ra,0x1
    8000448a:	ad8080e7          	jalr	-1320(ra) # 80004f5e <kfilewrite>
}
    8000448e:	60a2                	ld	ra,8(sp)
    80004490:	6402                	ld	s0,0(sp)
    80004492:	0141                	addi	sp,sp,16
    80004494:	8082                	ret

0000000080004496 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004496:	1141                	addi	sp,sp,-16
    80004498:	e406                	sd	ra,8(sp)
    8000449a:	e022                	sd	s0,0(sp)
    8000449c:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    8000449e:	16853783          	ld	a5,360(a0)
    800044a2:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    800044a4:	8636                	mv	a2,a3
    800044a6:	16853503          	ld	a0,360(a0)
    800044aa:	00001097          	auipc	ra,0x1
    800044ae:	9f2080e7          	jalr	-1550(ra) # 80004e9c <kfileread>
    800044b2:	60a2                	ld	ra,8(sp)
    800044b4:	6402                	ld	s0,0(sp)
    800044b6:	0141                	addi	sp,sp,16
    800044b8:	8082                	ret

00000000800044ba <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044ba:	1101                	addi	sp,sp,-32
    800044bc:	ec06                	sd	ra,24(sp)
    800044be:	e822                	sd	s0,16(sp)
    800044c0:	e426                	sd	s1,8(sp)
    800044c2:	e04a                	sd	s2,0(sp)
    800044c4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044c6:	00023917          	auipc	s2,0x23
    800044ca:	faa90913          	addi	s2,s2,-86 # 80027470 <log>
    800044ce:	01892583          	lw	a1,24(s2)
    800044d2:	02892503          	lw	a0,40(s2)
    800044d6:	fffff097          	auipc	ra,0xfffff
    800044da:	cde080e7          	jalr	-802(ra) # 800031b4 <bread>
    800044de:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044e0:	02c92683          	lw	a3,44(s2)
    800044e4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044e6:	02d05863          	blez	a3,80004516 <write_head+0x5c>
    800044ea:	00023797          	auipc	a5,0x23
    800044ee:	fb678793          	addi	a5,a5,-74 # 800274a0 <log+0x30>
    800044f2:	05c50713          	addi	a4,a0,92
    800044f6:	36fd                	addiw	a3,a3,-1
    800044f8:	02069613          	slli	a2,a3,0x20
    800044fc:	01e65693          	srli	a3,a2,0x1e
    80004500:	00023617          	auipc	a2,0x23
    80004504:	fa460613          	addi	a2,a2,-92 # 800274a4 <log+0x34>
    80004508:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000450a:	4390                	lw	a2,0(a5)
    8000450c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000450e:	0791                	addi	a5,a5,4
    80004510:	0711                	addi	a4,a4,4
    80004512:	fed79ce3          	bne	a5,a3,8000450a <write_head+0x50>
  }
  bwrite(buf);
    80004516:	8526                	mv	a0,s1
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	d8e080e7          	jalr	-626(ra) # 800032a6 <bwrite>
  brelse(buf);
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	dc2080e7          	jalr	-574(ra) # 800032e4 <brelse>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004536:	00023797          	auipc	a5,0x23
    8000453a:	f667a783          	lw	a5,-154(a5) # 8002749c <log+0x2c>
    8000453e:	0af05d63          	blez	a5,800045f8 <install_trans+0xc2>
{
    80004542:	7139                	addi	sp,sp,-64
    80004544:	fc06                	sd	ra,56(sp)
    80004546:	f822                	sd	s0,48(sp)
    80004548:	f426                	sd	s1,40(sp)
    8000454a:	f04a                	sd	s2,32(sp)
    8000454c:	ec4e                	sd	s3,24(sp)
    8000454e:	e852                	sd	s4,16(sp)
    80004550:	e456                	sd	s5,8(sp)
    80004552:	e05a                	sd	s6,0(sp)
    80004554:	0080                	addi	s0,sp,64
    80004556:	8b2a                	mv	s6,a0
    80004558:	00023a97          	auipc	s5,0x23
    8000455c:	f48a8a93          	addi	s5,s5,-184 # 800274a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004560:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004562:	00023997          	auipc	s3,0x23
    80004566:	f0e98993          	addi	s3,s3,-242 # 80027470 <log>
    8000456a:	a00d                	j	8000458c <install_trans+0x56>
    brelse(lbuf);
    8000456c:	854a                	mv	a0,s2
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	d76080e7          	jalr	-650(ra) # 800032e4 <brelse>
    brelse(dbuf);
    80004576:	8526                	mv	a0,s1
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	d6c080e7          	jalr	-660(ra) # 800032e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004580:	2a05                	addiw	s4,s4,1
    80004582:	0a91                	addi	s5,s5,4
    80004584:	02c9a783          	lw	a5,44(s3)
    80004588:	04fa5e63          	bge	s4,a5,800045e4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000458c:	0189a583          	lw	a1,24(s3)
    80004590:	014585bb          	addw	a1,a1,s4
    80004594:	2585                	addiw	a1,a1,1
    80004596:	0289a503          	lw	a0,40(s3)
    8000459a:	fffff097          	auipc	ra,0xfffff
    8000459e:	c1a080e7          	jalr	-998(ra) # 800031b4 <bread>
    800045a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045a4:	000aa583          	lw	a1,0(s5)
    800045a8:	0289a503          	lw	a0,40(s3)
    800045ac:	fffff097          	auipc	ra,0xfffff
    800045b0:	c08080e7          	jalr	-1016(ra) # 800031b4 <bread>
    800045b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045b6:	40000613          	li	a2,1024
    800045ba:	05890593          	addi	a1,s2,88
    800045be:	05850513          	addi	a0,a0,88
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	758080e7          	jalr	1880(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    800045ca:	8526                	mv	a0,s1
    800045cc:	fffff097          	auipc	ra,0xfffff
    800045d0:	cda080e7          	jalr	-806(ra) # 800032a6 <bwrite>
    if(recovering == 0)
    800045d4:	f80b1ce3          	bnez	s6,8000456c <install_trans+0x36>
      bunpin(dbuf);
    800045d8:	8526                	mv	a0,s1
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	de4080e7          	jalr	-540(ra) # 800033be <bunpin>
    800045e2:	b769                	j	8000456c <install_trans+0x36>
}
    800045e4:	70e2                	ld	ra,56(sp)
    800045e6:	7442                	ld	s0,48(sp)
    800045e8:	74a2                	ld	s1,40(sp)
    800045ea:	7902                	ld	s2,32(sp)
    800045ec:	69e2                	ld	s3,24(sp)
    800045ee:	6a42                	ld	s4,16(sp)
    800045f0:	6aa2                	ld	s5,8(sp)
    800045f2:	6b02                	ld	s6,0(sp)
    800045f4:	6121                	addi	sp,sp,64
    800045f6:	8082                	ret
    800045f8:	8082                	ret

00000000800045fa <initlog>:
{
    800045fa:	7179                	addi	sp,sp,-48
    800045fc:	f406                	sd	ra,40(sp)
    800045fe:	f022                	sd	s0,32(sp)
    80004600:	ec26                	sd	s1,24(sp)
    80004602:	e84a                	sd	s2,16(sp)
    80004604:	e44e                	sd	s3,8(sp)
    80004606:	1800                	addi	s0,sp,48
    80004608:	892a                	mv	s2,a0
    8000460a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000460c:	00023497          	auipc	s1,0x23
    80004610:	e6448493          	addi	s1,s1,-412 # 80027470 <log>
    80004614:	00004597          	auipc	a1,0x4
    80004618:	13c58593          	addi	a1,a1,316 # 80008750 <syscalls+0x248>
    8000461c:	8526                	mv	a0,s1
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	514080e7          	jalr	1300(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004626:	0149a583          	lw	a1,20(s3)
    8000462a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000462c:	0109a783          	lw	a5,16(s3)
    80004630:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004632:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004636:	854a                	mv	a0,s2
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	b7c080e7          	jalr	-1156(ra) # 800031b4 <bread>
  log.lh.n = lh->n;
    80004640:	4d34                	lw	a3,88(a0)
    80004642:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004644:	02d05663          	blez	a3,80004670 <initlog+0x76>
    80004648:	05c50793          	addi	a5,a0,92
    8000464c:	00023717          	auipc	a4,0x23
    80004650:	e5470713          	addi	a4,a4,-428 # 800274a0 <log+0x30>
    80004654:	36fd                	addiw	a3,a3,-1
    80004656:	02069613          	slli	a2,a3,0x20
    8000465a:	01e65693          	srli	a3,a2,0x1e
    8000465e:	06050613          	addi	a2,a0,96
    80004662:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004664:	4390                	lw	a2,0(a5)
    80004666:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004668:	0791                	addi	a5,a5,4
    8000466a:	0711                	addi	a4,a4,4
    8000466c:	fed79ce3          	bne	a5,a3,80004664 <initlog+0x6a>
  brelse(buf);
    80004670:	fffff097          	auipc	ra,0xfffff
    80004674:	c74080e7          	jalr	-908(ra) # 800032e4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004678:	4505                	li	a0,1
    8000467a:	00000097          	auipc	ra,0x0
    8000467e:	ebc080e7          	jalr	-324(ra) # 80004536 <install_trans>
  log.lh.n = 0;
    80004682:	00023797          	auipc	a5,0x23
    80004686:	e007ad23          	sw	zero,-486(a5) # 8002749c <log+0x2c>
  write_head(); // clear the log
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	e30080e7          	jalr	-464(ra) # 800044ba <write_head>
}
    80004692:	70a2                	ld	ra,40(sp)
    80004694:	7402                	ld	s0,32(sp)
    80004696:	64e2                	ld	s1,24(sp)
    80004698:	6942                	ld	s2,16(sp)
    8000469a:	69a2                	ld	s3,8(sp)
    8000469c:	6145                	addi	sp,sp,48
    8000469e:	8082                	ret

00000000800046a0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046ac:	00023517          	auipc	a0,0x23
    800046b0:	dc450513          	addi	a0,a0,-572 # 80027470 <log>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	50e080e7          	jalr	1294(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800046bc:	00023497          	auipc	s1,0x23
    800046c0:	db448493          	addi	s1,s1,-588 # 80027470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046c4:	4979                	li	s2,30
    800046c6:	a039                	j	800046d4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046c8:	85a6                	mv	a1,s1
    800046ca:	8526                	mv	a0,s1
    800046cc:	ffffe097          	auipc	ra,0xffffe
    800046d0:	d88080e7          	jalr	-632(ra) # 80002454 <sleep>
    if(log.committing){
    800046d4:	50dc                	lw	a5,36(s1)
    800046d6:	fbed                	bnez	a5,800046c8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046d8:	509c                	lw	a5,32(s1)
    800046da:	0017871b          	addiw	a4,a5,1
    800046de:	0007069b          	sext.w	a3,a4
    800046e2:	0027179b          	slliw	a5,a4,0x2
    800046e6:	9fb9                	addw	a5,a5,a4
    800046e8:	0017979b          	slliw	a5,a5,0x1
    800046ec:	54d8                	lw	a4,44(s1)
    800046ee:	9fb9                	addw	a5,a5,a4
    800046f0:	00f95963          	bge	s2,a5,80004702 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046f4:	85a6                	mv	a1,s1
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffe097          	auipc	ra,0xffffe
    800046fc:	d5c080e7          	jalr	-676(ra) # 80002454 <sleep>
    80004700:	bfd1                	j	800046d4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004702:	00023517          	auipc	a0,0x23
    80004706:	d6e50513          	addi	a0,a0,-658 # 80027470 <log>
    8000470a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	56a080e7          	jalr	1386(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004714:	60e2                	ld	ra,24(sp)
    80004716:	6442                	ld	s0,16(sp)
    80004718:	64a2                	ld	s1,8(sp)
    8000471a:	6902                	ld	s2,0(sp)
    8000471c:	6105                	addi	sp,sp,32
    8000471e:	8082                	ret

0000000080004720 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004720:	7139                	addi	sp,sp,-64
    80004722:	fc06                	sd	ra,56(sp)
    80004724:	f822                	sd	s0,48(sp)
    80004726:	f426                	sd	s1,40(sp)
    80004728:	f04a                	sd	s2,32(sp)
    8000472a:	ec4e                	sd	s3,24(sp)
    8000472c:	e852                	sd	s4,16(sp)
    8000472e:	e456                	sd	s5,8(sp)
    80004730:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004732:	00023497          	auipc	s1,0x23
    80004736:	d3e48493          	addi	s1,s1,-706 # 80027470 <log>
    8000473a:	8526                	mv	a0,s1
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	486080e7          	jalr	1158(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004744:	509c                	lw	a5,32(s1)
    80004746:	37fd                	addiw	a5,a5,-1
    80004748:	0007891b          	sext.w	s2,a5
    8000474c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000474e:	50dc                	lw	a5,36(s1)
    80004750:	e7b9                	bnez	a5,8000479e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004752:	04091e63          	bnez	s2,800047ae <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004756:	00023497          	auipc	s1,0x23
    8000475a:	d1a48493          	addi	s1,s1,-742 # 80027470 <log>
    8000475e:	4785                	li	a5,1
    80004760:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004762:	8526                	mv	a0,s1
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	512080e7          	jalr	1298(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000476c:	54dc                	lw	a5,44(s1)
    8000476e:	06f04763          	bgtz	a5,800047dc <end_op+0xbc>
    acquire(&log.lock);
    80004772:	00023497          	auipc	s1,0x23
    80004776:	cfe48493          	addi	s1,s1,-770 # 80027470 <log>
    8000477a:	8526                	mv	a0,s1
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	446080e7          	jalr	1094(ra) # 80000bc2 <acquire>
    log.committing = 0;
    80004784:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004788:	8526                	mv	a0,s1
    8000478a:	ffffe097          	auipc	ra,0xffffe
    8000478e:	e56080e7          	jalr	-426(ra) # 800025e0 <wakeup>
    release(&log.lock);
    80004792:	8526                	mv	a0,s1
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	4e2080e7          	jalr	1250(ra) # 80000c76 <release>
}
    8000479c:	a03d                	j	800047ca <end_op+0xaa>
    panic("log.committing");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	fba50513          	addi	a0,a0,-70 # 80008758 <syscalls+0x250>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	d84080e7          	jalr	-636(ra) # 8000052a <panic>
    wakeup(&log);
    800047ae:	00023497          	auipc	s1,0x23
    800047b2:	cc248493          	addi	s1,s1,-830 # 80027470 <log>
    800047b6:	8526                	mv	a0,s1
    800047b8:	ffffe097          	auipc	ra,0xffffe
    800047bc:	e28080e7          	jalr	-472(ra) # 800025e0 <wakeup>
  release(&log.lock);
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffc097          	auipc	ra,0xffffc
    800047c6:	4b4080e7          	jalr	1204(ra) # 80000c76 <release>
}
    800047ca:	70e2                	ld	ra,56(sp)
    800047cc:	7442                	ld	s0,48(sp)
    800047ce:	74a2                	ld	s1,40(sp)
    800047d0:	7902                	ld	s2,32(sp)
    800047d2:	69e2                	ld	s3,24(sp)
    800047d4:	6a42                	ld	s4,16(sp)
    800047d6:	6aa2                	ld	s5,8(sp)
    800047d8:	6121                	addi	sp,sp,64
    800047da:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047dc:	00023a97          	auipc	s5,0x23
    800047e0:	cc4a8a93          	addi	s5,s5,-828 # 800274a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047e4:	00023a17          	auipc	s4,0x23
    800047e8:	c8ca0a13          	addi	s4,s4,-884 # 80027470 <log>
    800047ec:	018a2583          	lw	a1,24(s4)
    800047f0:	012585bb          	addw	a1,a1,s2
    800047f4:	2585                	addiw	a1,a1,1
    800047f6:	028a2503          	lw	a0,40(s4)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	9ba080e7          	jalr	-1606(ra) # 800031b4 <bread>
    80004802:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004804:	000aa583          	lw	a1,0(s5)
    80004808:	028a2503          	lw	a0,40(s4)
    8000480c:	fffff097          	auipc	ra,0xfffff
    80004810:	9a8080e7          	jalr	-1624(ra) # 800031b4 <bread>
    80004814:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004816:	40000613          	li	a2,1024
    8000481a:	05850593          	addi	a1,a0,88
    8000481e:	05848513          	addi	a0,s1,88
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	4f8080e7          	jalr	1272(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000482a:	8526                	mv	a0,s1
    8000482c:	fffff097          	auipc	ra,0xfffff
    80004830:	a7a080e7          	jalr	-1414(ra) # 800032a6 <bwrite>
    brelse(from);
    80004834:	854e                	mv	a0,s3
    80004836:	fffff097          	auipc	ra,0xfffff
    8000483a:	aae080e7          	jalr	-1362(ra) # 800032e4 <brelse>
    brelse(to);
    8000483e:	8526                	mv	a0,s1
    80004840:	fffff097          	auipc	ra,0xfffff
    80004844:	aa4080e7          	jalr	-1372(ra) # 800032e4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004848:	2905                	addiw	s2,s2,1
    8000484a:	0a91                	addi	s5,s5,4
    8000484c:	02ca2783          	lw	a5,44(s4)
    80004850:	f8f94ee3          	blt	s2,a5,800047ec <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004854:	00000097          	auipc	ra,0x0
    80004858:	c66080e7          	jalr	-922(ra) # 800044ba <write_head>
    install_trans(0); // Now install writes to home locations
    8000485c:	4501                	li	a0,0
    8000485e:	00000097          	auipc	ra,0x0
    80004862:	cd8080e7          	jalr	-808(ra) # 80004536 <install_trans>
    log.lh.n = 0;
    80004866:	00023797          	auipc	a5,0x23
    8000486a:	c207ab23          	sw	zero,-970(a5) # 8002749c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000486e:	00000097          	auipc	ra,0x0
    80004872:	c4c080e7          	jalr	-948(ra) # 800044ba <write_head>
    80004876:	bdf5                	j	80004772 <end_op+0x52>

0000000080004878 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004878:	1101                	addi	sp,sp,-32
    8000487a:	ec06                	sd	ra,24(sp)
    8000487c:	e822                	sd	s0,16(sp)
    8000487e:	e426                	sd	s1,8(sp)
    80004880:	e04a                	sd	s2,0(sp)
    80004882:	1000                	addi	s0,sp,32
    80004884:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004886:	00023917          	auipc	s2,0x23
    8000488a:	bea90913          	addi	s2,s2,-1046 # 80027470 <log>
    8000488e:	854a                	mv	a0,s2
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	332080e7          	jalr	818(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004898:	02c92603          	lw	a2,44(s2)
    8000489c:	47f5                	li	a5,29
    8000489e:	06c7c563          	blt	a5,a2,80004908 <log_write+0x90>
    800048a2:	00023797          	auipc	a5,0x23
    800048a6:	bea7a783          	lw	a5,-1046(a5) # 8002748c <log+0x1c>
    800048aa:	37fd                	addiw	a5,a5,-1
    800048ac:	04f65e63          	bge	a2,a5,80004908 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048b0:	00023797          	auipc	a5,0x23
    800048b4:	be07a783          	lw	a5,-1056(a5) # 80027490 <log+0x20>
    800048b8:	06f05063          	blez	a5,80004918 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048bc:	4781                	li	a5,0
    800048be:	06c05563          	blez	a2,80004928 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048c2:	44cc                	lw	a1,12(s1)
    800048c4:	00023717          	auipc	a4,0x23
    800048c8:	bdc70713          	addi	a4,a4,-1060 # 800274a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048cc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800048ce:	4314                	lw	a3,0(a4)
    800048d0:	04b68c63          	beq	a3,a1,80004928 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048d4:	2785                	addiw	a5,a5,1
    800048d6:	0711                	addi	a4,a4,4
    800048d8:	fef61be3          	bne	a2,a5,800048ce <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048dc:	0621                	addi	a2,a2,8
    800048de:	060a                	slli	a2,a2,0x2
    800048e0:	00023797          	auipc	a5,0x23
    800048e4:	b9078793          	addi	a5,a5,-1136 # 80027470 <log>
    800048e8:	963e                	add	a2,a2,a5
    800048ea:	44dc                	lw	a5,12(s1)
    800048ec:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048ee:	8526                	mv	a0,s1
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	a92080e7          	jalr	-1390(ra) # 80003382 <bpin>
    log.lh.n++;
    800048f8:	00023717          	auipc	a4,0x23
    800048fc:	b7870713          	addi	a4,a4,-1160 # 80027470 <log>
    80004900:	575c                	lw	a5,44(a4)
    80004902:	2785                	addiw	a5,a5,1
    80004904:	d75c                	sw	a5,44(a4)
    80004906:	a835                	j	80004942 <log_write+0xca>
    panic("too big a transaction");
    80004908:	00004517          	auipc	a0,0x4
    8000490c:	e6050513          	addi	a0,a0,-416 # 80008768 <syscalls+0x260>
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	c1a080e7          	jalr	-998(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004918:	00004517          	auipc	a0,0x4
    8000491c:	e6850513          	addi	a0,a0,-408 # 80008780 <syscalls+0x278>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	c0a080e7          	jalr	-1014(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004928:	00878713          	addi	a4,a5,8
    8000492c:	00271693          	slli	a3,a4,0x2
    80004930:	00023717          	auipc	a4,0x23
    80004934:	b4070713          	addi	a4,a4,-1216 # 80027470 <log>
    80004938:	9736                	add	a4,a4,a3
    8000493a:	44d4                	lw	a3,12(s1)
    8000493c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000493e:	faf608e3          	beq	a2,a5,800048ee <log_write+0x76>
  }
  release(&log.lock);
    80004942:	00023517          	auipc	a0,0x23
    80004946:	b2e50513          	addi	a0,a0,-1234 # 80027470 <log>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	32c080e7          	jalr	812(ra) # 80000c76 <release>
}
    80004952:	60e2                	ld	ra,24(sp)
    80004954:	6442                	ld	s0,16(sp)
    80004956:	64a2                	ld	s1,8(sp)
    80004958:	6902                	ld	s2,0(sp)
    8000495a:	6105                	addi	sp,sp,32
    8000495c:	8082                	ret

000000008000495e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000495e:	1101                	addi	sp,sp,-32
    80004960:	ec06                	sd	ra,24(sp)
    80004962:	e822                	sd	s0,16(sp)
    80004964:	e426                	sd	s1,8(sp)
    80004966:	e04a                	sd	s2,0(sp)
    80004968:	1000                	addi	s0,sp,32
    8000496a:	84aa                	mv	s1,a0
    8000496c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000496e:	00004597          	auipc	a1,0x4
    80004972:	e3258593          	addi	a1,a1,-462 # 800087a0 <syscalls+0x298>
    80004976:	0521                	addi	a0,a0,8
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	1ba080e7          	jalr	442(ra) # 80000b32 <initlock>
  lk->name = name;
    80004980:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004984:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004988:	0204a423          	sw	zero,40(s1)
}
    8000498c:	60e2                	ld	ra,24(sp)
    8000498e:	6442                	ld	s0,16(sp)
    80004990:	64a2                	ld	s1,8(sp)
    80004992:	6902                	ld	s2,0(sp)
    80004994:	6105                	addi	sp,sp,32
    80004996:	8082                	ret

0000000080004998 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004998:	1101                	addi	sp,sp,-32
    8000499a:	ec06                	sd	ra,24(sp)
    8000499c:	e822                	sd	s0,16(sp)
    8000499e:	e426                	sd	s1,8(sp)
    800049a0:	e04a                	sd	s2,0(sp)
    800049a2:	1000                	addi	s0,sp,32
    800049a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049a6:	00850913          	addi	s2,a0,8
    800049aa:	854a                	mv	a0,s2
    800049ac:	ffffc097          	auipc	ra,0xffffc
    800049b0:	216080e7          	jalr	534(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800049b4:	409c                	lw	a5,0(s1)
    800049b6:	cb89                	beqz	a5,800049c8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049b8:	85ca                	mv	a1,s2
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffe097          	auipc	ra,0xffffe
    800049c0:	a98080e7          	jalr	-1384(ra) # 80002454 <sleep>
  while (lk->locked) {
    800049c4:	409c                	lw	a5,0(s1)
    800049c6:	fbed                	bnez	a5,800049b8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049c8:	4785                	li	a5,1
    800049ca:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049cc:	ffffd097          	auipc	ra,0xffffd
    800049d0:	248080e7          	jalr	584(ra) # 80001c14 <myproc>
    800049d4:	591c                	lw	a5,48(a0)
    800049d6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049d8:	854a                	mv	a0,s2
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	29c080e7          	jalr	668(ra) # 80000c76 <release>
}
    800049e2:	60e2                	ld	ra,24(sp)
    800049e4:	6442                	ld	s0,16(sp)
    800049e6:	64a2                	ld	s1,8(sp)
    800049e8:	6902                	ld	s2,0(sp)
    800049ea:	6105                	addi	sp,sp,32
    800049ec:	8082                	ret

00000000800049ee <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049ee:	1101                	addi	sp,sp,-32
    800049f0:	ec06                	sd	ra,24(sp)
    800049f2:	e822                	sd	s0,16(sp)
    800049f4:	e426                	sd	s1,8(sp)
    800049f6:	e04a                	sd	s2,0(sp)
    800049f8:	1000                	addi	s0,sp,32
    800049fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049fc:	00850913          	addi	s2,a0,8
    80004a00:	854a                	mv	a0,s2
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	1c0080e7          	jalr	448(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004a0a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a0e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a12:	8526                	mv	a0,s1
    80004a14:	ffffe097          	auipc	ra,0xffffe
    80004a18:	bcc080e7          	jalr	-1076(ra) # 800025e0 <wakeup>
  release(&lk->lk);
    80004a1c:	854a                	mv	a0,s2
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	258080e7          	jalr	600(ra) # 80000c76 <release>
}
    80004a26:	60e2                	ld	ra,24(sp)
    80004a28:	6442                	ld	s0,16(sp)
    80004a2a:	64a2                	ld	s1,8(sp)
    80004a2c:	6902                	ld	s2,0(sp)
    80004a2e:	6105                	addi	sp,sp,32
    80004a30:	8082                	ret

0000000080004a32 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a32:	7179                	addi	sp,sp,-48
    80004a34:	f406                	sd	ra,40(sp)
    80004a36:	f022                	sd	s0,32(sp)
    80004a38:	ec26                	sd	s1,24(sp)
    80004a3a:	e84a                	sd	s2,16(sp)
    80004a3c:	e44e                	sd	s3,8(sp)
    80004a3e:	1800                	addi	s0,sp,48
    80004a40:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a42:	00850913          	addi	s2,a0,8
    80004a46:	854a                	mv	a0,s2
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	17a080e7          	jalr	378(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a50:	409c                	lw	a5,0(s1)
    80004a52:	ef99                	bnez	a5,80004a70 <holdingsleep+0x3e>
    80004a54:	4481                	li	s1,0
  release(&lk->lk);
    80004a56:	854a                	mv	a0,s2
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	21e080e7          	jalr	542(ra) # 80000c76 <release>
  return r;
}
    80004a60:	8526                	mv	a0,s1
    80004a62:	70a2                	ld	ra,40(sp)
    80004a64:	7402                	ld	s0,32(sp)
    80004a66:	64e2                	ld	s1,24(sp)
    80004a68:	6942                	ld	s2,16(sp)
    80004a6a:	69a2                	ld	s3,8(sp)
    80004a6c:	6145                	addi	sp,sp,48
    80004a6e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a70:	0284a983          	lw	s3,40(s1)
    80004a74:	ffffd097          	auipc	ra,0xffffd
    80004a78:	1a0080e7          	jalr	416(ra) # 80001c14 <myproc>
    80004a7c:	5904                	lw	s1,48(a0)
    80004a7e:	413484b3          	sub	s1,s1,s3
    80004a82:	0014b493          	seqz	s1,s1
    80004a86:	bfc1                	j	80004a56 <holdingsleep+0x24>

0000000080004a88 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a88:	1141                	addi	sp,sp,-16
    80004a8a:	e406                	sd	ra,8(sp)
    80004a8c:	e022                	sd	s0,0(sp)
    80004a8e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a90:	00004597          	auipc	a1,0x4
    80004a94:	d2058593          	addi	a1,a1,-736 # 800087b0 <syscalls+0x2a8>
    80004a98:	00023517          	auipc	a0,0x23
    80004a9c:	b2050513          	addi	a0,a0,-1248 # 800275b8 <ftable>
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	092080e7          	jalr	146(ra) # 80000b32 <initlock>
}
    80004aa8:	60a2                	ld	ra,8(sp)
    80004aaa:	6402                	ld	s0,0(sp)
    80004aac:	0141                	addi	sp,sp,16
    80004aae:	8082                	ret

0000000080004ab0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec06                	sd	ra,24(sp)
    80004ab4:	e822                	sd	s0,16(sp)
    80004ab6:	e426                	sd	s1,8(sp)
    80004ab8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004aba:	00023517          	auipc	a0,0x23
    80004abe:	afe50513          	addi	a0,a0,-1282 # 800275b8 <ftable>
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	100080e7          	jalr	256(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aca:	00023497          	auipc	s1,0x23
    80004ace:	b0648493          	addi	s1,s1,-1274 # 800275d0 <ftable+0x18>
    80004ad2:	00024717          	auipc	a4,0x24
    80004ad6:	a9e70713          	addi	a4,a4,-1378 # 80028570 <ftable+0xfb8>
    if(f->ref == 0){
    80004ada:	40dc                	lw	a5,4(s1)
    80004adc:	cf99                	beqz	a5,80004afa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ade:	02848493          	addi	s1,s1,40
    80004ae2:	fee49ce3          	bne	s1,a4,80004ada <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ae6:	00023517          	auipc	a0,0x23
    80004aea:	ad250513          	addi	a0,a0,-1326 # 800275b8 <ftable>
    80004aee:	ffffc097          	auipc	ra,0xffffc
    80004af2:	188080e7          	jalr	392(ra) # 80000c76 <release>
  return 0;
    80004af6:	4481                	li	s1,0
    80004af8:	a819                	j	80004b0e <filealloc+0x5e>
      f->ref = 1;
    80004afa:	4785                	li	a5,1
    80004afc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004afe:	00023517          	auipc	a0,0x23
    80004b02:	aba50513          	addi	a0,a0,-1350 # 800275b8 <ftable>
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	170080e7          	jalr	368(ra) # 80000c76 <release>
}
    80004b0e:	8526                	mv	a0,s1
    80004b10:	60e2                	ld	ra,24(sp)
    80004b12:	6442                	ld	s0,16(sp)
    80004b14:	64a2                	ld	s1,8(sp)
    80004b16:	6105                	addi	sp,sp,32
    80004b18:	8082                	ret

0000000080004b1a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b1a:	1101                	addi	sp,sp,-32
    80004b1c:	ec06                	sd	ra,24(sp)
    80004b1e:	e822                	sd	s0,16(sp)
    80004b20:	e426                	sd	s1,8(sp)
    80004b22:	1000                	addi	s0,sp,32
    80004b24:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b26:	00023517          	auipc	a0,0x23
    80004b2a:	a9250513          	addi	a0,a0,-1390 # 800275b8 <ftable>
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	094080e7          	jalr	148(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004b36:	40dc                	lw	a5,4(s1)
    80004b38:	02f05263          	blez	a5,80004b5c <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b3c:	2785                	addiw	a5,a5,1
    80004b3e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b40:	00023517          	auipc	a0,0x23
    80004b44:	a7850513          	addi	a0,a0,-1416 # 800275b8 <ftable>
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	12e080e7          	jalr	302(ra) # 80000c76 <release>
  return f;
}
    80004b50:	8526                	mv	a0,s1
    80004b52:	60e2                	ld	ra,24(sp)
    80004b54:	6442                	ld	s0,16(sp)
    80004b56:	64a2                	ld	s1,8(sp)
    80004b58:	6105                	addi	sp,sp,32
    80004b5a:	8082                	ret
    panic("filedup");
    80004b5c:	00004517          	auipc	a0,0x4
    80004b60:	c5c50513          	addi	a0,a0,-932 # 800087b8 <syscalls+0x2b0>
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	9c6080e7          	jalr	-1594(ra) # 8000052a <panic>

0000000080004b6c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b6c:	7139                	addi	sp,sp,-64
    80004b6e:	fc06                	sd	ra,56(sp)
    80004b70:	f822                	sd	s0,48(sp)
    80004b72:	f426                	sd	s1,40(sp)
    80004b74:	f04a                	sd	s2,32(sp)
    80004b76:	ec4e                	sd	s3,24(sp)
    80004b78:	e852                	sd	s4,16(sp)
    80004b7a:	e456                	sd	s5,8(sp)
    80004b7c:	0080                	addi	s0,sp,64
    80004b7e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b80:	00023517          	auipc	a0,0x23
    80004b84:	a3850513          	addi	a0,a0,-1480 # 800275b8 <ftable>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	03a080e7          	jalr	58(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004b90:	40dc                	lw	a5,4(s1)
    80004b92:	06f05163          	blez	a5,80004bf4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b96:	37fd                	addiw	a5,a5,-1
    80004b98:	0007871b          	sext.w	a4,a5
    80004b9c:	c0dc                	sw	a5,4(s1)
    80004b9e:	06e04363          	bgtz	a4,80004c04 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ba2:	0004a903          	lw	s2,0(s1)
    80004ba6:	0094ca83          	lbu	s5,9(s1)
    80004baa:	0104ba03          	ld	s4,16(s1)
    80004bae:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bb2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bb6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bba:	00023517          	auipc	a0,0x23
    80004bbe:	9fe50513          	addi	a0,a0,-1538 # 800275b8 <ftable>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0b4080e7          	jalr	180(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004bca:	4785                	li	a5,1
    80004bcc:	04f90d63          	beq	s2,a5,80004c26 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bd0:	3979                	addiw	s2,s2,-2
    80004bd2:	4785                	li	a5,1
    80004bd4:	0527e063          	bltu	a5,s2,80004c14 <fileclose+0xa8>
    begin_op();
    80004bd8:	00000097          	auipc	ra,0x0
    80004bdc:	ac8080e7          	jalr	-1336(ra) # 800046a0 <begin_op>
    iput(ff.ip);
    80004be0:	854e                	mv	a0,s3
    80004be2:	fffff097          	auipc	ra,0xfffff
    80004be6:	f90080e7          	jalr	-112(ra) # 80003b72 <iput>
    end_op();
    80004bea:	00000097          	auipc	ra,0x0
    80004bee:	b36080e7          	jalr	-1226(ra) # 80004720 <end_op>
    80004bf2:	a00d                	j	80004c14 <fileclose+0xa8>
    panic("fileclose");
    80004bf4:	00004517          	auipc	a0,0x4
    80004bf8:	bcc50513          	addi	a0,a0,-1076 # 800087c0 <syscalls+0x2b8>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	92e080e7          	jalr	-1746(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004c04:	00023517          	auipc	a0,0x23
    80004c08:	9b450513          	addi	a0,a0,-1612 # 800275b8 <ftable>
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	06a080e7          	jalr	106(ra) # 80000c76 <release>
  }
}
    80004c14:	70e2                	ld	ra,56(sp)
    80004c16:	7442                	ld	s0,48(sp)
    80004c18:	74a2                	ld	s1,40(sp)
    80004c1a:	7902                	ld	s2,32(sp)
    80004c1c:	69e2                	ld	s3,24(sp)
    80004c1e:	6a42                	ld	s4,16(sp)
    80004c20:	6aa2                	ld	s5,8(sp)
    80004c22:	6121                	addi	sp,sp,64
    80004c24:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c26:	85d6                	mv	a1,s5
    80004c28:	8552                	mv	a0,s4
    80004c2a:	00000097          	auipc	ra,0x0
    80004c2e:	542080e7          	jalr	1346(ra) # 8000516c <pipeclose>
    80004c32:	b7cd                	j	80004c14 <fileclose+0xa8>

0000000080004c34 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c34:	715d                	addi	sp,sp,-80
    80004c36:	e486                	sd	ra,72(sp)
    80004c38:	e0a2                	sd	s0,64(sp)
    80004c3a:	fc26                	sd	s1,56(sp)
    80004c3c:	f84a                	sd	s2,48(sp)
    80004c3e:	f44e                	sd	s3,40(sp)
    80004c40:	0880                	addi	s0,sp,80
    80004c42:	84aa                	mv	s1,a0
    80004c44:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	fce080e7          	jalr	-50(ra) # 80001c14 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c4e:	409c                	lw	a5,0(s1)
    80004c50:	37f9                	addiw	a5,a5,-2
    80004c52:	4705                	li	a4,1
    80004c54:	04f76763          	bltu	a4,a5,80004ca2 <filestat+0x6e>
    80004c58:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c5a:	6c88                	ld	a0,24(s1)
    80004c5c:	fffff097          	auipc	ra,0xfffff
    80004c60:	d5c080e7          	jalr	-676(ra) # 800039b8 <ilock>
    stati(f->ip, &st);
    80004c64:	fb840593          	addi	a1,s0,-72
    80004c68:	6c88                	ld	a0,24(s1)
    80004c6a:	fffff097          	auipc	ra,0xfffff
    80004c6e:	fd8080e7          	jalr	-40(ra) # 80003c42 <stati>
    iunlock(f->ip);
    80004c72:	6c88                	ld	a0,24(s1)
    80004c74:	fffff097          	auipc	ra,0xfffff
    80004c78:	e06080e7          	jalr	-506(ra) # 80003a7a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c7c:	46e1                	li	a3,24
    80004c7e:	fb840613          	addi	a2,s0,-72
    80004c82:	85ce                	mv	a1,s3
    80004c84:	05093503          	ld	a0,80(s2)
    80004c88:	ffffd097          	auipc	ra,0xffffd
    80004c8c:	9b6080e7          	jalr	-1610(ra) # 8000163e <copyout>
    80004c90:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c94:	60a6                	ld	ra,72(sp)
    80004c96:	6406                	ld	s0,64(sp)
    80004c98:	74e2                	ld	s1,56(sp)
    80004c9a:	7942                	ld	s2,48(sp)
    80004c9c:	79a2                	ld	s3,40(sp)
    80004c9e:	6161                	addi	sp,sp,80
    80004ca0:	8082                	ret
  return -1;
    80004ca2:	557d                	li	a0,-1
    80004ca4:	bfc5                	j	80004c94 <filestat+0x60>

0000000080004ca6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ca6:	7179                	addi	sp,sp,-48
    80004ca8:	f406                	sd	ra,40(sp)
    80004caa:	f022                	sd	s0,32(sp)
    80004cac:	ec26                	sd	s1,24(sp)
    80004cae:	e84a                	sd	s2,16(sp)
    80004cb0:	e44e                	sd	s3,8(sp)
    80004cb2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cb4:	00854783          	lbu	a5,8(a0)
    80004cb8:	c3d5                	beqz	a5,80004d5c <fileread+0xb6>
    80004cba:	84aa                	mv	s1,a0
    80004cbc:	89ae                	mv	s3,a1
    80004cbe:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cc0:	411c                	lw	a5,0(a0)
    80004cc2:	4705                	li	a4,1
    80004cc4:	04e78963          	beq	a5,a4,80004d16 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cc8:	470d                	li	a4,3
    80004cca:	04e78d63          	beq	a5,a4,80004d24 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cce:	4709                	li	a4,2
    80004cd0:	06e79e63          	bne	a5,a4,80004d4c <fileread+0xa6>
    ilock(f->ip);
    80004cd4:	6d08                	ld	a0,24(a0)
    80004cd6:	fffff097          	auipc	ra,0xfffff
    80004cda:	ce2080e7          	jalr	-798(ra) # 800039b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cde:	874a                	mv	a4,s2
    80004ce0:	5094                	lw	a3,32(s1)
    80004ce2:	864e                	mv	a2,s3
    80004ce4:	4585                	li	a1,1
    80004ce6:	6c88                	ld	a0,24(s1)
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	f84080e7          	jalr	-124(ra) # 80003c6c <readi>
    80004cf0:	892a                	mv	s2,a0
    80004cf2:	00a05563          	blez	a0,80004cfc <fileread+0x56>
      f->off += r;
    80004cf6:	509c                	lw	a5,32(s1)
    80004cf8:	9fa9                	addw	a5,a5,a0
    80004cfa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cfc:	6c88                	ld	a0,24(s1)
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	d7c080e7          	jalr	-644(ra) # 80003a7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d06:	854a                	mv	a0,s2
    80004d08:	70a2                	ld	ra,40(sp)
    80004d0a:	7402                	ld	s0,32(sp)
    80004d0c:	64e2                	ld	s1,24(sp)
    80004d0e:	6942                	ld	s2,16(sp)
    80004d10:	69a2                	ld	s3,8(sp)
    80004d12:	6145                	addi	sp,sp,48
    80004d14:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d16:	6908                	ld	a0,16(a0)
    80004d18:	00000097          	auipc	ra,0x0
    80004d1c:	5b6080e7          	jalr	1462(ra) # 800052ce <piperead>
    80004d20:	892a                	mv	s2,a0
    80004d22:	b7d5                	j	80004d06 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d24:	02451783          	lh	a5,36(a0)
    80004d28:	03079693          	slli	a3,a5,0x30
    80004d2c:	92c1                	srli	a3,a3,0x30
    80004d2e:	4725                	li	a4,9
    80004d30:	02d76863          	bltu	a4,a3,80004d60 <fileread+0xba>
    80004d34:	0792                	slli	a5,a5,0x4
    80004d36:	00022717          	auipc	a4,0x22
    80004d3a:	7e270713          	addi	a4,a4,2018 # 80027518 <devsw>
    80004d3e:	97ba                	add	a5,a5,a4
    80004d40:	639c                	ld	a5,0(a5)
    80004d42:	c38d                	beqz	a5,80004d64 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d44:	4505                	li	a0,1
    80004d46:	9782                	jalr	a5
    80004d48:	892a                	mv	s2,a0
    80004d4a:	bf75                	j	80004d06 <fileread+0x60>
    panic("fileread");
    80004d4c:	00004517          	auipc	a0,0x4
    80004d50:	a8450513          	addi	a0,a0,-1404 # 800087d0 <syscalls+0x2c8>
    80004d54:	ffffb097          	auipc	ra,0xffffb
    80004d58:	7d6080e7          	jalr	2006(ra) # 8000052a <panic>
    return -1;
    80004d5c:	597d                	li	s2,-1
    80004d5e:	b765                	j	80004d06 <fileread+0x60>
      return -1;
    80004d60:	597d                	li	s2,-1
    80004d62:	b755                	j	80004d06 <fileread+0x60>
    80004d64:	597d                	li	s2,-1
    80004d66:	b745                	j	80004d06 <fileread+0x60>

0000000080004d68 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d68:	715d                	addi	sp,sp,-80
    80004d6a:	e486                	sd	ra,72(sp)
    80004d6c:	e0a2                	sd	s0,64(sp)
    80004d6e:	fc26                	sd	s1,56(sp)
    80004d70:	f84a                	sd	s2,48(sp)
    80004d72:	f44e                	sd	s3,40(sp)
    80004d74:	f052                	sd	s4,32(sp)
    80004d76:	ec56                	sd	s5,24(sp)
    80004d78:	e85a                	sd	s6,16(sp)
    80004d7a:	e45e                	sd	s7,8(sp)
    80004d7c:	e062                	sd	s8,0(sp)
    80004d7e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d80:	00954783          	lbu	a5,9(a0)
    80004d84:	10078663          	beqz	a5,80004e90 <filewrite+0x128>
    80004d88:	892a                	mv	s2,a0
    80004d8a:	8aae                	mv	s5,a1
    80004d8c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d8e:	411c                	lw	a5,0(a0)
    80004d90:	4705                	li	a4,1
    80004d92:	02e78263          	beq	a5,a4,80004db6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d96:	470d                	li	a4,3
    80004d98:	02e78663          	beq	a5,a4,80004dc4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d9c:	4709                	li	a4,2
    80004d9e:	0ee79163          	bne	a5,a4,80004e80 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004da2:	0ac05d63          	blez	a2,80004e5c <filewrite+0xf4>
    int i = 0;
    80004da6:	4981                	li	s3,0
    80004da8:	6b05                	lui	s6,0x1
    80004daa:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dae:	6b85                	lui	s7,0x1
    80004db0:	c00b8b9b          	addiw	s7,s7,-1024
    80004db4:	a861                	j	80004e4c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004db6:	6908                	ld	a0,16(a0)
    80004db8:	00000097          	auipc	ra,0x0
    80004dbc:	424080e7          	jalr	1060(ra) # 800051dc <pipewrite>
    80004dc0:	8a2a                	mv	s4,a0
    80004dc2:	a045                	j	80004e62 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dc4:	02451783          	lh	a5,36(a0)
    80004dc8:	03079693          	slli	a3,a5,0x30
    80004dcc:	92c1                	srli	a3,a3,0x30
    80004dce:	4725                	li	a4,9
    80004dd0:	0cd76263          	bltu	a4,a3,80004e94 <filewrite+0x12c>
    80004dd4:	0792                	slli	a5,a5,0x4
    80004dd6:	00022717          	auipc	a4,0x22
    80004dda:	74270713          	addi	a4,a4,1858 # 80027518 <devsw>
    80004dde:	97ba                	add	a5,a5,a4
    80004de0:	679c                	ld	a5,8(a5)
    80004de2:	cbdd                	beqz	a5,80004e98 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004de4:	4505                	li	a0,1
    80004de6:	9782                	jalr	a5
    80004de8:	8a2a                	mv	s4,a0
    80004dea:	a8a5                	j	80004e62 <filewrite+0xfa>
    80004dec:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	8b0080e7          	jalr	-1872(ra) # 800046a0 <begin_op>
      ilock(f->ip);
    80004df8:	01893503          	ld	a0,24(s2)
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	bbc080e7          	jalr	-1092(ra) # 800039b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e04:	8762                	mv	a4,s8
    80004e06:	02092683          	lw	a3,32(s2)
    80004e0a:	01598633          	add	a2,s3,s5
    80004e0e:	4585                	li	a1,1
    80004e10:	01893503          	ld	a0,24(s2)
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	f50080e7          	jalr	-176(ra) # 80003d64 <writei>
    80004e1c:	84aa                	mv	s1,a0
    80004e1e:	00a05763          	blez	a0,80004e2c <filewrite+0xc4>
        f->off += r;
    80004e22:	02092783          	lw	a5,32(s2)
    80004e26:	9fa9                	addw	a5,a5,a0
    80004e28:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e2c:	01893503          	ld	a0,24(s2)
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	c4a080e7          	jalr	-950(ra) # 80003a7a <iunlock>
      end_op();
    80004e38:	00000097          	auipc	ra,0x0
    80004e3c:	8e8080e7          	jalr	-1816(ra) # 80004720 <end_op>

      if(r != n1){
    80004e40:	009c1f63          	bne	s8,s1,80004e5e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e44:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e48:	0149db63          	bge	s3,s4,80004e5e <filewrite+0xf6>
      int n1 = n - i;
    80004e4c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e50:	84be                	mv	s1,a5
    80004e52:	2781                	sext.w	a5,a5
    80004e54:	f8fb5ce3          	bge	s6,a5,80004dec <filewrite+0x84>
    80004e58:	84de                	mv	s1,s7
    80004e5a:	bf49                	j	80004dec <filewrite+0x84>
    int i = 0;
    80004e5c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e5e:	013a1f63          	bne	s4,s3,80004e7c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e62:	8552                	mv	a0,s4
    80004e64:	60a6                	ld	ra,72(sp)
    80004e66:	6406                	ld	s0,64(sp)
    80004e68:	74e2                	ld	s1,56(sp)
    80004e6a:	7942                	ld	s2,48(sp)
    80004e6c:	79a2                	ld	s3,40(sp)
    80004e6e:	7a02                	ld	s4,32(sp)
    80004e70:	6ae2                	ld	s5,24(sp)
    80004e72:	6b42                	ld	s6,16(sp)
    80004e74:	6ba2                	ld	s7,8(sp)
    80004e76:	6c02                	ld	s8,0(sp)
    80004e78:	6161                	addi	sp,sp,80
    80004e7a:	8082                	ret
    ret = (i == n ? n : -1);
    80004e7c:	5a7d                	li	s4,-1
    80004e7e:	b7d5                	j	80004e62 <filewrite+0xfa>
    panic("filewrite");
    80004e80:	00004517          	auipc	a0,0x4
    80004e84:	96050513          	addi	a0,a0,-1696 # 800087e0 <syscalls+0x2d8>
    80004e88:	ffffb097          	auipc	ra,0xffffb
    80004e8c:	6a2080e7          	jalr	1698(ra) # 8000052a <panic>
    return -1;
    80004e90:	5a7d                	li	s4,-1
    80004e92:	bfc1                	j	80004e62 <filewrite+0xfa>
      return -1;
    80004e94:	5a7d                	li	s4,-1
    80004e96:	b7f1                	j	80004e62 <filewrite+0xfa>
    80004e98:	5a7d                	li	s4,-1
    80004e9a:	b7e1                	j	80004e62 <filewrite+0xfa>

0000000080004e9c <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    80004e9c:	7179                	addi	sp,sp,-48
    80004e9e:	f406                	sd	ra,40(sp)
    80004ea0:	f022                	sd	s0,32(sp)
    80004ea2:	ec26                	sd	s1,24(sp)
    80004ea4:	e84a                	sd	s2,16(sp)
    80004ea6:	e44e                	sd	s3,8(sp)
    80004ea8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004eaa:	00854783          	lbu	a5,8(a0)
    80004eae:	c3d5                	beqz	a5,80004f52 <kfileread+0xb6>
    80004eb0:	84aa                	mv	s1,a0
    80004eb2:	89ae                	mv	s3,a1
    80004eb4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004eb6:	411c                	lw	a5,0(a0)
    80004eb8:	4705                	li	a4,1
    80004eba:	04e78963          	beq	a5,a4,80004f0c <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ebe:	470d                	li	a4,3
    80004ec0:	04e78d63          	beq	a5,a4,80004f1a <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ec4:	4709                	li	a4,2
    80004ec6:	06e79e63          	bne	a5,a4,80004f42 <kfileread+0xa6>
    ilock(f->ip);
    80004eca:	6d08                	ld	a0,24(a0)
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	aec080e7          	jalr	-1300(ra) # 800039b8 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80004ed4:	874a                	mv	a4,s2
    80004ed6:	5094                	lw	a3,32(s1)
    80004ed8:	864e                	mv	a2,s3
    80004eda:	4581                	li	a1,0
    80004edc:	6c88                	ld	a0,24(s1)
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	d8e080e7          	jalr	-626(ra) # 80003c6c <readi>
    80004ee6:	892a                	mv	s2,a0
    80004ee8:	00a05563          	blez	a0,80004ef2 <kfileread+0x56>
      f->off += r;
    80004eec:	509c                	lw	a5,32(s1)
    80004eee:	9fa9                	addw	a5,a5,a0
    80004ef0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ef2:	6c88                	ld	a0,24(s1)
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	b86080e7          	jalr	-1146(ra) # 80003a7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004efc:	854a                	mv	a0,s2
    80004efe:	70a2                	ld	ra,40(sp)
    80004f00:	7402                	ld	s0,32(sp)
    80004f02:	64e2                	ld	s1,24(sp)
    80004f04:	6942                	ld	s2,16(sp)
    80004f06:	69a2                	ld	s3,8(sp)
    80004f08:	6145                	addi	sp,sp,48
    80004f0a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004f0c:	6908                	ld	a0,16(a0)
    80004f0e:	00000097          	auipc	ra,0x0
    80004f12:	3c0080e7          	jalr	960(ra) # 800052ce <piperead>
    80004f16:	892a                	mv	s2,a0
    80004f18:	b7d5                	j	80004efc <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004f1a:	02451783          	lh	a5,36(a0)
    80004f1e:	03079693          	slli	a3,a5,0x30
    80004f22:	92c1                	srli	a3,a3,0x30
    80004f24:	4725                	li	a4,9
    80004f26:	02d76863          	bltu	a4,a3,80004f56 <kfileread+0xba>
    80004f2a:	0792                	slli	a5,a5,0x4
    80004f2c:	00022717          	auipc	a4,0x22
    80004f30:	5ec70713          	addi	a4,a4,1516 # 80027518 <devsw>
    80004f34:	97ba                	add	a5,a5,a4
    80004f36:	639c                	ld	a5,0(a5)
    80004f38:	c38d                	beqz	a5,80004f5a <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004f3a:	4505                	li	a0,1
    80004f3c:	9782                	jalr	a5
    80004f3e:	892a                	mv	s2,a0
    80004f40:	bf75                	j	80004efc <kfileread+0x60>
    panic("fileread");
    80004f42:	00004517          	auipc	a0,0x4
    80004f46:	88e50513          	addi	a0,a0,-1906 # 800087d0 <syscalls+0x2c8>
    80004f4a:	ffffb097          	auipc	ra,0xffffb
    80004f4e:	5e0080e7          	jalr	1504(ra) # 8000052a <panic>
    return -1;
    80004f52:	597d                	li	s2,-1
    80004f54:	b765                	j	80004efc <kfileread+0x60>
      return -1;
    80004f56:	597d                	li	s2,-1
    80004f58:	b755                	j	80004efc <kfileread+0x60>
    80004f5a:	597d                	li	s2,-1
    80004f5c:	b745                	j	80004efc <kfileread+0x60>

0000000080004f5e <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80004f5e:	715d                	addi	sp,sp,-80
    80004f60:	e486                	sd	ra,72(sp)
    80004f62:	e0a2                	sd	s0,64(sp)
    80004f64:	fc26                	sd	s1,56(sp)
    80004f66:	f84a                	sd	s2,48(sp)
    80004f68:	f44e                	sd	s3,40(sp)
    80004f6a:	f052                	sd	s4,32(sp)
    80004f6c:	ec56                	sd	s5,24(sp)
    80004f6e:	e85a                	sd	s6,16(sp)
    80004f70:	e45e                	sd	s7,8(sp)
    80004f72:	e062                	sd	s8,0(sp)
    80004f74:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004f76:	00954783          	lbu	a5,9(a0)
    80004f7a:	10078663          	beqz	a5,80005086 <kfilewrite+0x128>
    80004f7e:	892a                	mv	s2,a0
    80004f80:	8aae                	mv	s5,a1
    80004f82:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f84:	411c                	lw	a5,0(a0)
    80004f86:	4705                	li	a4,1
    80004f88:	02e78263          	beq	a5,a4,80004fac <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f8c:	470d                	li	a4,3
    80004f8e:	02e78663          	beq	a5,a4,80004fba <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f92:	4709                	li	a4,2
    80004f94:	0ee79163          	bne	a5,a4,80005076 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f98:	0ac05d63          	blez	a2,80005052 <kfilewrite+0xf4>
    int i = 0;
    80004f9c:	4981                	li	s3,0
    80004f9e:	6b05                	lui	s6,0x1
    80004fa0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004fa4:	6b85                	lui	s7,0x1
    80004fa6:	c00b8b9b          	addiw	s7,s7,-1024
    80004faa:	a861                	j	80005042 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004fac:	6908                	ld	a0,16(a0)
    80004fae:	00000097          	auipc	ra,0x0
    80004fb2:	22e080e7          	jalr	558(ra) # 800051dc <pipewrite>
    80004fb6:	8a2a                	mv	s4,a0
    80004fb8:	a045                	j	80005058 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004fba:	02451783          	lh	a5,36(a0)
    80004fbe:	03079693          	slli	a3,a5,0x30
    80004fc2:	92c1                	srli	a3,a3,0x30
    80004fc4:	4725                	li	a4,9
    80004fc6:	0cd76263          	bltu	a4,a3,8000508a <kfilewrite+0x12c>
    80004fca:	0792                	slli	a5,a5,0x4
    80004fcc:	00022717          	auipc	a4,0x22
    80004fd0:	54c70713          	addi	a4,a4,1356 # 80027518 <devsw>
    80004fd4:	97ba                	add	a5,a5,a4
    80004fd6:	679c                	ld	a5,8(a5)
    80004fd8:	cbdd                	beqz	a5,8000508e <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004fda:	4505                	li	a0,1
    80004fdc:	9782                	jalr	a5
    80004fde:	8a2a                	mv	s4,a0
    80004fe0:	a8a5                	j	80005058 <kfilewrite+0xfa>
    80004fe2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004fe6:	fffff097          	auipc	ra,0xfffff
    80004fea:	6ba080e7          	jalr	1722(ra) # 800046a0 <begin_op>
      ilock(f->ip);
    80004fee:	01893503          	ld	a0,24(s2)
    80004ff2:	fffff097          	auipc	ra,0xfffff
    80004ff6:	9c6080e7          	jalr	-1594(ra) # 800039b8 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80004ffa:	8762                	mv	a4,s8
    80004ffc:	02092683          	lw	a3,32(s2)
    80005000:	01598633          	add	a2,s3,s5
    80005004:	4581                	li	a1,0
    80005006:	01893503          	ld	a0,24(s2)
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	d5a080e7          	jalr	-678(ra) # 80003d64 <writei>
    80005012:	84aa                	mv	s1,a0
    80005014:	00a05763          	blez	a0,80005022 <kfilewrite+0xc4>
        f->off += r;
    80005018:	02092783          	lw	a5,32(s2)
    8000501c:	9fa9                	addw	a5,a5,a0
    8000501e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005022:	01893503          	ld	a0,24(s2)
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	a54080e7          	jalr	-1452(ra) # 80003a7a <iunlock>
      end_op();
    8000502e:	fffff097          	auipc	ra,0xfffff
    80005032:	6f2080e7          	jalr	1778(ra) # 80004720 <end_op>

      if(r != n1){
    80005036:	009c1f63          	bne	s8,s1,80005054 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000503a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000503e:	0149db63          	bge	s3,s4,80005054 <kfilewrite+0xf6>
      int n1 = n - i;
    80005042:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005046:	84be                	mv	s1,a5
    80005048:	2781                	sext.w	a5,a5
    8000504a:	f8fb5ce3          	bge	s6,a5,80004fe2 <kfilewrite+0x84>
    8000504e:	84de                	mv	s1,s7
    80005050:	bf49                	j	80004fe2 <kfilewrite+0x84>
    int i = 0;
    80005052:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005054:	013a1f63          	bne	s4,s3,80005072 <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005058:	8552                	mv	a0,s4
    8000505a:	60a6                	ld	ra,72(sp)
    8000505c:	6406                	ld	s0,64(sp)
    8000505e:	74e2                	ld	s1,56(sp)
    80005060:	7942                	ld	s2,48(sp)
    80005062:	79a2                	ld	s3,40(sp)
    80005064:	7a02                	ld	s4,32(sp)
    80005066:	6ae2                	ld	s5,24(sp)
    80005068:	6b42                	ld	s6,16(sp)
    8000506a:	6ba2                	ld	s7,8(sp)
    8000506c:	6c02                	ld	s8,0(sp)
    8000506e:	6161                	addi	sp,sp,80
    80005070:	8082                	ret
    ret = (i == n ? n : -1);
    80005072:	5a7d                	li	s4,-1
    80005074:	b7d5                	j	80005058 <kfilewrite+0xfa>
    panic("filewrite");
    80005076:	00003517          	auipc	a0,0x3
    8000507a:	76a50513          	addi	a0,a0,1898 # 800087e0 <syscalls+0x2d8>
    8000507e:	ffffb097          	auipc	ra,0xffffb
    80005082:	4ac080e7          	jalr	1196(ra) # 8000052a <panic>
    return -1;
    80005086:	5a7d                	li	s4,-1
    80005088:	bfc1                	j	80005058 <kfilewrite+0xfa>
      return -1;
    8000508a:	5a7d                	li	s4,-1
    8000508c:	b7f1                	j	80005058 <kfilewrite+0xfa>
    8000508e:	5a7d                	li	s4,-1
    80005090:	b7e1                	j	80005058 <kfilewrite+0xfa>

0000000080005092 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005092:	7179                	addi	sp,sp,-48
    80005094:	f406                	sd	ra,40(sp)
    80005096:	f022                	sd	s0,32(sp)
    80005098:	ec26                	sd	s1,24(sp)
    8000509a:	e84a                	sd	s2,16(sp)
    8000509c:	e44e                	sd	s3,8(sp)
    8000509e:	e052                	sd	s4,0(sp)
    800050a0:	1800                	addi	s0,sp,48
    800050a2:	84aa                	mv	s1,a0
    800050a4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800050a6:	0005b023          	sd	zero,0(a1)
    800050aa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800050ae:	00000097          	auipc	ra,0x0
    800050b2:	a02080e7          	jalr	-1534(ra) # 80004ab0 <filealloc>
    800050b6:	e088                	sd	a0,0(s1)
    800050b8:	c551                	beqz	a0,80005144 <pipealloc+0xb2>
    800050ba:	00000097          	auipc	ra,0x0
    800050be:	9f6080e7          	jalr	-1546(ra) # 80004ab0 <filealloc>
    800050c2:	00aa3023          	sd	a0,0(s4)
    800050c6:	c92d                	beqz	a0,80005138 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	a0a080e7          	jalr	-1526(ra) # 80000ad2 <kalloc>
    800050d0:	892a                	mv	s2,a0
    800050d2:	c125                	beqz	a0,80005132 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800050d4:	4985                	li	s3,1
    800050d6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800050da:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800050de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800050e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800050e6:	00003597          	auipc	a1,0x3
    800050ea:	70a58593          	addi	a1,a1,1802 # 800087f0 <syscalls+0x2e8>
    800050ee:	ffffc097          	auipc	ra,0xffffc
    800050f2:	a44080e7          	jalr	-1468(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    800050f6:	609c                	ld	a5,0(s1)
    800050f8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800050fc:	609c                	ld	a5,0(s1)
    800050fe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005102:	609c                	ld	a5,0(s1)
    80005104:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005108:	609c                	ld	a5,0(s1)
    8000510a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000510e:	000a3783          	ld	a5,0(s4)
    80005112:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005116:	000a3783          	ld	a5,0(s4)
    8000511a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000511e:	000a3783          	ld	a5,0(s4)
    80005122:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005126:	000a3783          	ld	a5,0(s4)
    8000512a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000512e:	4501                	li	a0,0
    80005130:	a025                	j	80005158 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005132:	6088                	ld	a0,0(s1)
    80005134:	e501                	bnez	a0,8000513c <pipealloc+0xaa>
    80005136:	a039                	j	80005144 <pipealloc+0xb2>
    80005138:	6088                	ld	a0,0(s1)
    8000513a:	c51d                	beqz	a0,80005168 <pipealloc+0xd6>
    fileclose(*f0);
    8000513c:	00000097          	auipc	ra,0x0
    80005140:	a30080e7          	jalr	-1488(ra) # 80004b6c <fileclose>
  if(*f1)
    80005144:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005148:	557d                	li	a0,-1
  if(*f1)
    8000514a:	c799                	beqz	a5,80005158 <pipealloc+0xc6>
    fileclose(*f1);
    8000514c:	853e                	mv	a0,a5
    8000514e:	00000097          	auipc	ra,0x0
    80005152:	a1e080e7          	jalr	-1506(ra) # 80004b6c <fileclose>
  return -1;
    80005156:	557d                	li	a0,-1
}
    80005158:	70a2                	ld	ra,40(sp)
    8000515a:	7402                	ld	s0,32(sp)
    8000515c:	64e2                	ld	s1,24(sp)
    8000515e:	6942                	ld	s2,16(sp)
    80005160:	69a2                	ld	s3,8(sp)
    80005162:	6a02                	ld	s4,0(sp)
    80005164:	6145                	addi	sp,sp,48
    80005166:	8082                	ret
  return -1;
    80005168:	557d                	li	a0,-1
    8000516a:	b7fd                	j	80005158 <pipealloc+0xc6>

000000008000516c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000516c:	1101                	addi	sp,sp,-32
    8000516e:	ec06                	sd	ra,24(sp)
    80005170:	e822                	sd	s0,16(sp)
    80005172:	e426                	sd	s1,8(sp)
    80005174:	e04a                	sd	s2,0(sp)
    80005176:	1000                	addi	s0,sp,32
    80005178:	84aa                	mv	s1,a0
    8000517a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	a46080e7          	jalr	-1466(ra) # 80000bc2 <acquire>
  if(writable){
    80005184:	02090d63          	beqz	s2,800051be <pipeclose+0x52>
    pi->writeopen = 0;
    80005188:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000518c:	21848513          	addi	a0,s1,536
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	450080e7          	jalr	1104(ra) # 800025e0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005198:	2204b783          	ld	a5,544(s1)
    8000519c:	eb95                	bnez	a5,800051d0 <pipeclose+0x64>
    release(&pi->lock);
    8000519e:	8526                	mv	a0,s1
    800051a0:	ffffc097          	auipc	ra,0xffffc
    800051a4:	ad6080e7          	jalr	-1322(ra) # 80000c76 <release>
    kfree((char*)pi);
    800051a8:	8526                	mv	a0,s1
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	82c080e7          	jalr	-2004(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    800051b2:	60e2                	ld	ra,24(sp)
    800051b4:	6442                	ld	s0,16(sp)
    800051b6:	64a2                	ld	s1,8(sp)
    800051b8:	6902                	ld	s2,0(sp)
    800051ba:	6105                	addi	sp,sp,32
    800051bc:	8082                	ret
    pi->readopen = 0;
    800051be:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800051c2:	21c48513          	addi	a0,s1,540
    800051c6:	ffffd097          	auipc	ra,0xffffd
    800051ca:	41a080e7          	jalr	1050(ra) # 800025e0 <wakeup>
    800051ce:	b7e9                	j	80005198 <pipeclose+0x2c>
    release(&pi->lock);
    800051d0:	8526                	mv	a0,s1
    800051d2:	ffffc097          	auipc	ra,0xffffc
    800051d6:	aa4080e7          	jalr	-1372(ra) # 80000c76 <release>
}
    800051da:	bfe1                	j	800051b2 <pipeclose+0x46>

00000000800051dc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800051dc:	711d                	addi	sp,sp,-96
    800051de:	ec86                	sd	ra,88(sp)
    800051e0:	e8a2                	sd	s0,80(sp)
    800051e2:	e4a6                	sd	s1,72(sp)
    800051e4:	e0ca                	sd	s2,64(sp)
    800051e6:	fc4e                	sd	s3,56(sp)
    800051e8:	f852                	sd	s4,48(sp)
    800051ea:	f456                	sd	s5,40(sp)
    800051ec:	f05a                	sd	s6,32(sp)
    800051ee:	ec5e                	sd	s7,24(sp)
    800051f0:	e862                	sd	s8,16(sp)
    800051f2:	1080                	addi	s0,sp,96
    800051f4:	84aa                	mv	s1,a0
    800051f6:	8aae                	mv	s5,a1
    800051f8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800051fa:	ffffd097          	auipc	ra,0xffffd
    800051fe:	a1a080e7          	jalr	-1510(ra) # 80001c14 <myproc>
    80005202:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005204:	8526                	mv	a0,s1
    80005206:	ffffc097          	auipc	ra,0xffffc
    8000520a:	9bc080e7          	jalr	-1604(ra) # 80000bc2 <acquire>
  while(i < n){
    8000520e:	0b405363          	blez	s4,800052b4 <pipewrite+0xd8>
  int i = 0;
    80005212:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005214:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005216:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000521a:	21c48b93          	addi	s7,s1,540
    8000521e:	a089                	j	80005260 <pipewrite+0x84>
      release(&pi->lock);
    80005220:	8526                	mv	a0,s1
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	a54080e7          	jalr	-1452(ra) # 80000c76 <release>
      return -1;
    8000522a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000522c:	854a                	mv	a0,s2
    8000522e:	60e6                	ld	ra,88(sp)
    80005230:	6446                	ld	s0,80(sp)
    80005232:	64a6                	ld	s1,72(sp)
    80005234:	6906                	ld	s2,64(sp)
    80005236:	79e2                	ld	s3,56(sp)
    80005238:	7a42                	ld	s4,48(sp)
    8000523a:	7aa2                	ld	s5,40(sp)
    8000523c:	7b02                	ld	s6,32(sp)
    8000523e:	6be2                	ld	s7,24(sp)
    80005240:	6c42                	ld	s8,16(sp)
    80005242:	6125                	addi	sp,sp,96
    80005244:	8082                	ret
      wakeup(&pi->nread);
    80005246:	8562                	mv	a0,s8
    80005248:	ffffd097          	auipc	ra,0xffffd
    8000524c:	398080e7          	jalr	920(ra) # 800025e0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005250:	85a6                	mv	a1,s1
    80005252:	855e                	mv	a0,s7
    80005254:	ffffd097          	auipc	ra,0xffffd
    80005258:	200080e7          	jalr	512(ra) # 80002454 <sleep>
  while(i < n){
    8000525c:	05495d63          	bge	s2,s4,800052b6 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005260:	2204a783          	lw	a5,544(s1)
    80005264:	dfd5                	beqz	a5,80005220 <pipewrite+0x44>
    80005266:	0289a783          	lw	a5,40(s3)
    8000526a:	fbdd                	bnez	a5,80005220 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000526c:	2184a783          	lw	a5,536(s1)
    80005270:	21c4a703          	lw	a4,540(s1)
    80005274:	2007879b          	addiw	a5,a5,512
    80005278:	fcf707e3          	beq	a4,a5,80005246 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000527c:	4685                	li	a3,1
    8000527e:	01590633          	add	a2,s2,s5
    80005282:	faf40593          	addi	a1,s0,-81
    80005286:	0509b503          	ld	a0,80(s3)
    8000528a:	ffffc097          	auipc	ra,0xffffc
    8000528e:	440080e7          	jalr	1088(ra) # 800016ca <copyin>
    80005292:	03650263          	beq	a0,s6,800052b6 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005296:	21c4a783          	lw	a5,540(s1)
    8000529a:	0017871b          	addiw	a4,a5,1
    8000529e:	20e4ae23          	sw	a4,540(s1)
    800052a2:	1ff7f793          	andi	a5,a5,511
    800052a6:	97a6                	add	a5,a5,s1
    800052a8:	faf44703          	lbu	a4,-81(s0)
    800052ac:	00e78c23          	sb	a4,24(a5)
      i++;
    800052b0:	2905                	addiw	s2,s2,1
    800052b2:	b76d                	j	8000525c <pipewrite+0x80>
  int i = 0;
    800052b4:	4901                	li	s2,0
  wakeup(&pi->nread);
    800052b6:	21848513          	addi	a0,s1,536
    800052ba:	ffffd097          	auipc	ra,0xffffd
    800052be:	326080e7          	jalr	806(ra) # 800025e0 <wakeup>
  release(&pi->lock);
    800052c2:	8526                	mv	a0,s1
    800052c4:	ffffc097          	auipc	ra,0xffffc
    800052c8:	9b2080e7          	jalr	-1614(ra) # 80000c76 <release>
  return i;
    800052cc:	b785                	j	8000522c <pipewrite+0x50>

00000000800052ce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800052ce:	715d                	addi	sp,sp,-80
    800052d0:	e486                	sd	ra,72(sp)
    800052d2:	e0a2                	sd	s0,64(sp)
    800052d4:	fc26                	sd	s1,56(sp)
    800052d6:	f84a                	sd	s2,48(sp)
    800052d8:	f44e                	sd	s3,40(sp)
    800052da:	f052                	sd	s4,32(sp)
    800052dc:	ec56                	sd	s5,24(sp)
    800052de:	e85a                	sd	s6,16(sp)
    800052e0:	0880                	addi	s0,sp,80
    800052e2:	84aa                	mv	s1,a0
    800052e4:	892e                	mv	s2,a1
    800052e6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800052e8:	ffffd097          	auipc	ra,0xffffd
    800052ec:	92c080e7          	jalr	-1748(ra) # 80001c14 <myproc>
    800052f0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800052f2:	8526                	mv	a0,s1
    800052f4:	ffffc097          	auipc	ra,0xffffc
    800052f8:	8ce080e7          	jalr	-1842(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052fc:	2184a703          	lw	a4,536(s1)
    80005300:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005304:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005308:	02f71463          	bne	a4,a5,80005330 <piperead+0x62>
    8000530c:	2244a783          	lw	a5,548(s1)
    80005310:	c385                	beqz	a5,80005330 <piperead+0x62>
    if(pr->killed){
    80005312:	028a2783          	lw	a5,40(s4)
    80005316:	ebc1                	bnez	a5,800053a6 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005318:	85a6                	mv	a1,s1
    8000531a:	854e                	mv	a0,s3
    8000531c:	ffffd097          	auipc	ra,0xffffd
    80005320:	138080e7          	jalr	312(ra) # 80002454 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005324:	2184a703          	lw	a4,536(s1)
    80005328:	21c4a783          	lw	a5,540(s1)
    8000532c:	fef700e3          	beq	a4,a5,8000530c <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005330:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005332:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005334:	05505363          	blez	s5,8000537a <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005338:	2184a783          	lw	a5,536(s1)
    8000533c:	21c4a703          	lw	a4,540(s1)
    80005340:	02f70d63          	beq	a4,a5,8000537a <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005344:	0017871b          	addiw	a4,a5,1
    80005348:	20e4ac23          	sw	a4,536(s1)
    8000534c:	1ff7f793          	andi	a5,a5,511
    80005350:	97a6                	add	a5,a5,s1
    80005352:	0187c783          	lbu	a5,24(a5)
    80005356:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000535a:	4685                	li	a3,1
    8000535c:	fbf40613          	addi	a2,s0,-65
    80005360:	85ca                	mv	a1,s2
    80005362:	050a3503          	ld	a0,80(s4)
    80005366:	ffffc097          	auipc	ra,0xffffc
    8000536a:	2d8080e7          	jalr	728(ra) # 8000163e <copyout>
    8000536e:	01650663          	beq	a0,s6,8000537a <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005372:	2985                	addiw	s3,s3,1
    80005374:	0905                	addi	s2,s2,1
    80005376:	fd3a91e3          	bne	s5,s3,80005338 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000537a:	21c48513          	addi	a0,s1,540
    8000537e:	ffffd097          	auipc	ra,0xffffd
    80005382:	262080e7          	jalr	610(ra) # 800025e0 <wakeup>
  release(&pi->lock);
    80005386:	8526                	mv	a0,s1
    80005388:	ffffc097          	auipc	ra,0xffffc
    8000538c:	8ee080e7          	jalr	-1810(ra) # 80000c76 <release>
  return i;
}
    80005390:	854e                	mv	a0,s3
    80005392:	60a6                	ld	ra,72(sp)
    80005394:	6406                	ld	s0,64(sp)
    80005396:	74e2                	ld	s1,56(sp)
    80005398:	7942                	ld	s2,48(sp)
    8000539a:	79a2                	ld	s3,40(sp)
    8000539c:	7a02                	ld	s4,32(sp)
    8000539e:	6ae2                	ld	s5,24(sp)
    800053a0:	6b42                	ld	s6,16(sp)
    800053a2:	6161                	addi	sp,sp,80
    800053a4:	8082                	ret
      release(&pi->lock);
    800053a6:	8526                	mv	a0,s1
    800053a8:	ffffc097          	auipc	ra,0xffffc
    800053ac:	8ce080e7          	jalr	-1842(ra) # 80000c76 <release>
      return -1;
    800053b0:	59fd                	li	s3,-1
    800053b2:	bff9                	j	80005390 <piperead+0xc2>

00000000800053b4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800053b4:	de010113          	addi	sp,sp,-544
    800053b8:	20113c23          	sd	ra,536(sp)
    800053bc:	20813823          	sd	s0,528(sp)
    800053c0:	20913423          	sd	s1,520(sp)
    800053c4:	21213023          	sd	s2,512(sp)
    800053c8:	ffce                	sd	s3,504(sp)
    800053ca:	fbd2                	sd	s4,496(sp)
    800053cc:	f7d6                	sd	s5,488(sp)
    800053ce:	f3da                	sd	s6,480(sp)
    800053d0:	efde                	sd	s7,472(sp)
    800053d2:	ebe2                	sd	s8,464(sp)
    800053d4:	e7e6                	sd	s9,456(sp)
    800053d6:	e3ea                	sd	s10,448(sp)
    800053d8:	ff6e                	sd	s11,440(sp)
    800053da:	1400                	addi	s0,sp,544
    800053dc:	892a                	mv	s2,a0
    800053de:	dea43423          	sd	a0,-536(s0)
    800053e2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800053e6:	ffffd097          	auipc	ra,0xffffd
    800053ea:	82e080e7          	jalr	-2002(ra) # 80001c14 <myproc>
    800053ee:	84aa                	mv	s1,a0

  begin_op();
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	2b0080e7          	jalr	688(ra) # 800046a0 <begin_op>

  if((ip = namei(path)) == 0){
    800053f8:	854a                	mv	a0,s2
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	d74080e7          	jalr	-652(ra) # 8000416e <namei>
    80005402:	c93d                	beqz	a0,80005478 <exec+0xc4>
    80005404:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	5b2080e7          	jalr	1458(ra) # 800039b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000540e:	04000713          	li	a4,64
    80005412:	4681                	li	a3,0
    80005414:	e4840613          	addi	a2,s0,-440
    80005418:	4581                	li	a1,0
    8000541a:	8556                	mv	a0,s5
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	850080e7          	jalr	-1968(ra) # 80003c6c <readi>
    80005424:	04000793          	li	a5,64
    80005428:	00f51a63          	bne	a0,a5,8000543c <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000542c:	e4842703          	lw	a4,-440(s0)
    80005430:	464c47b7          	lui	a5,0x464c4
    80005434:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005438:	04f70663          	beq	a4,a5,80005484 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000543c:	8556                	mv	a0,s5
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	7dc080e7          	jalr	2012(ra) # 80003c1a <iunlockput>
    end_op();
    80005446:	fffff097          	auipc	ra,0xfffff
    8000544a:	2da080e7          	jalr	730(ra) # 80004720 <end_op>
  }
  return -1;
    8000544e:	557d                	li	a0,-1
}
    80005450:	21813083          	ld	ra,536(sp)
    80005454:	21013403          	ld	s0,528(sp)
    80005458:	20813483          	ld	s1,520(sp)
    8000545c:	20013903          	ld	s2,512(sp)
    80005460:	79fe                	ld	s3,504(sp)
    80005462:	7a5e                	ld	s4,496(sp)
    80005464:	7abe                	ld	s5,488(sp)
    80005466:	7b1e                	ld	s6,480(sp)
    80005468:	6bfe                	ld	s7,472(sp)
    8000546a:	6c5e                	ld	s8,464(sp)
    8000546c:	6cbe                	ld	s9,456(sp)
    8000546e:	6d1e                	ld	s10,448(sp)
    80005470:	7dfa                	ld	s11,440(sp)
    80005472:	22010113          	addi	sp,sp,544
    80005476:	8082                	ret
    end_op();
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	2a8080e7          	jalr	680(ra) # 80004720 <end_op>
    return -1;
    80005480:	557d                	li	a0,-1
    80005482:	b7f9                	j	80005450 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005484:	8526                	mv	a0,s1
    80005486:	ffffd097          	auipc	ra,0xffffd
    8000548a:	852080e7          	jalr	-1966(ra) # 80001cd8 <proc_pagetable>
    8000548e:	8b2a                	mv	s6,a0
    80005490:	d555                	beqz	a0,8000543c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005492:	e6842783          	lw	a5,-408(s0)
    80005496:	e8045703          	lhu	a4,-384(s0)
    8000549a:	c735                	beqz	a4,80005506 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000549c:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000549e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800054a2:	6a05                	lui	s4,0x1
    800054a4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800054a8:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    800054ac:	6d85                	lui	s11,0x1
    800054ae:	7d7d                	lui	s10,0xfffff
    800054b0:	ac1d                	j	800056e6 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800054b2:	00003517          	auipc	a0,0x3
    800054b6:	34650513          	addi	a0,a0,838 # 800087f8 <syscalls+0x2f0>
    800054ba:	ffffb097          	auipc	ra,0xffffb
    800054be:	070080e7          	jalr	112(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800054c2:	874a                	mv	a4,s2
    800054c4:	009c86bb          	addw	a3,s9,s1
    800054c8:	4581                	li	a1,0
    800054ca:	8556                	mv	a0,s5
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	7a0080e7          	jalr	1952(ra) # 80003c6c <readi>
    800054d4:	2501                	sext.w	a0,a0
    800054d6:	1aa91863          	bne	s2,a0,80005686 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    800054da:	009d84bb          	addw	s1,s11,s1
    800054de:	013d09bb          	addw	s3,s10,s3
    800054e2:	1f74f263          	bgeu	s1,s7,800056c6 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    800054e6:	02049593          	slli	a1,s1,0x20
    800054ea:	9181                	srli	a1,a1,0x20
    800054ec:	95e2                	add	a1,a1,s8
    800054ee:	855a                	mv	a0,s6
    800054f0:	ffffc097          	auipc	ra,0xffffc
    800054f4:	b5c080e7          	jalr	-1188(ra) # 8000104c <walkaddr>
    800054f8:	862a                	mv	a2,a0
    if(pa == 0)
    800054fa:	dd45                	beqz	a0,800054b2 <exec+0xfe>
      n = PGSIZE;
    800054fc:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    800054fe:	fd49f2e3          	bgeu	s3,s4,800054c2 <exec+0x10e>
      n = sz - i;
    80005502:	894e                	mv	s2,s3
    80005504:	bf7d                	j	800054c2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005506:	4481                	li	s1,0
  iunlockput(ip);
    80005508:	8556                	mv	a0,s5
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	710080e7          	jalr	1808(ra) # 80003c1a <iunlockput>
  end_op();
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	20e080e7          	jalr	526(ra) # 80004720 <end_op>
  p = myproc();
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	6fa080e7          	jalr	1786(ra) # 80001c14 <myproc>
    80005522:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005524:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005528:	6785                	lui	a5,0x1
    8000552a:	17fd                	addi	a5,a5,-1
    8000552c:	94be                	add	s1,s1,a5
    8000552e:	77fd                	lui	a5,0xfffff
    80005530:	8fe5                	and	a5,a5,s1
    80005532:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005536:	6609                	lui	a2,0x2
    80005538:	963e                	add	a2,a2,a5
    8000553a:	85be                	mv	a1,a5
    8000553c:	855a                	mv	a0,s6
    8000553e:	ffffc097          	auipc	ra,0xffffc
    80005542:	eb0080e7          	jalr	-336(ra) # 800013ee <uvmalloc>
    80005546:	8c2a                	mv	s8,a0
  ip = 0;
    80005548:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000554a:	12050e63          	beqz	a0,80005686 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000554e:	75f9                	lui	a1,0xffffe
    80005550:	95aa                	add	a1,a1,a0
    80005552:	855a                	mv	a0,s6
    80005554:	ffffc097          	auipc	ra,0xffffc
    80005558:	0b8080e7          	jalr	184(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    8000555c:	7afd                	lui	s5,0xfffff
    8000555e:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005560:	df043783          	ld	a5,-528(s0)
    80005564:	6388                	ld	a0,0(a5)
    80005566:	c925                	beqz	a0,800055d6 <exec+0x222>
    80005568:	e8840993          	addi	s3,s0,-376
    8000556c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005570:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005572:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005574:	ffffc097          	auipc	ra,0xffffc
    80005578:	8ce080e7          	jalr	-1842(ra) # 80000e42 <strlen>
    8000557c:	0015079b          	addiw	a5,a0,1
    80005580:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005584:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005588:	13596363          	bltu	s2,s5,800056ae <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000558c:	df043d83          	ld	s11,-528(s0)
    80005590:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005594:	8552                	mv	a0,s4
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	8ac080e7          	jalr	-1876(ra) # 80000e42 <strlen>
    8000559e:	0015069b          	addiw	a3,a0,1
    800055a2:	8652                	mv	a2,s4
    800055a4:	85ca                	mv	a1,s2
    800055a6:	855a                	mv	a0,s6
    800055a8:	ffffc097          	auipc	ra,0xffffc
    800055ac:	096080e7          	jalr	150(ra) # 8000163e <copyout>
    800055b0:	10054363          	bltz	a0,800056b6 <exec+0x302>
    ustack[argc] = sp;
    800055b4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800055b8:	0485                	addi	s1,s1,1
    800055ba:	008d8793          	addi	a5,s11,8
    800055be:	def43823          	sd	a5,-528(s0)
    800055c2:	008db503          	ld	a0,8(s11)
    800055c6:	c911                	beqz	a0,800055da <exec+0x226>
    if(argc >= MAXARG)
    800055c8:	09a1                	addi	s3,s3,8
    800055ca:	fb3c95e3          	bne	s9,s3,80005574 <exec+0x1c0>
  sz = sz1;
    800055ce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055d2:	4a81                	li	s5,0
    800055d4:	a84d                	j	80005686 <exec+0x2d2>
  sp = sz;
    800055d6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800055d8:	4481                	li	s1,0
  ustack[argc] = 0;
    800055da:	00349793          	slli	a5,s1,0x3
    800055de:	f9040713          	addi	a4,s0,-112
    800055e2:	97ba                	add	a5,a5,a4
    800055e4:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd2ef8>
  sp -= (argc+1) * sizeof(uint64);
    800055e8:	00148693          	addi	a3,s1,1
    800055ec:	068e                	slli	a3,a3,0x3
    800055ee:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055f2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800055f6:	01597663          	bgeu	s2,s5,80005602 <exec+0x24e>
  sz = sz1;
    800055fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055fe:	4a81                	li	s5,0
    80005600:	a059                	j	80005686 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005602:	e8840613          	addi	a2,s0,-376
    80005606:	85ca                	mv	a1,s2
    80005608:	855a                	mv	a0,s6
    8000560a:	ffffc097          	auipc	ra,0xffffc
    8000560e:	034080e7          	jalr	52(ra) # 8000163e <copyout>
    80005612:	0a054663          	bltz	a0,800056be <exec+0x30a>
  p->trapframe->a1 = sp;
    80005616:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000561a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000561e:	de843783          	ld	a5,-536(s0)
    80005622:	0007c703          	lbu	a4,0(a5)
    80005626:	cf11                	beqz	a4,80005642 <exec+0x28e>
    80005628:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000562a:	02f00693          	li	a3,47
    8000562e:	a039                	j	8000563c <exec+0x288>
      last = s+1;
    80005630:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005634:	0785                	addi	a5,a5,1
    80005636:	fff7c703          	lbu	a4,-1(a5)
    8000563a:	c701                	beqz	a4,80005642 <exec+0x28e>
    if(*s == '/')
    8000563c:	fed71ce3          	bne	a4,a3,80005634 <exec+0x280>
    80005640:	bfc5                	j	80005630 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005642:	4641                	li	a2,16
    80005644:	de843583          	ld	a1,-536(s0)
    80005648:	158b8513          	addi	a0,s7,344
    8000564c:	ffffb097          	auipc	ra,0xffffb
    80005650:	7c4080e7          	jalr	1988(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80005654:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005658:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000565c:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005660:	058bb783          	ld	a5,88(s7)
    80005664:	e6043703          	ld	a4,-416(s0)
    80005668:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000566a:	058bb783          	ld	a5,88(s7)
    8000566e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005672:	85ea                	mv	a1,s10
    80005674:	ffffc097          	auipc	ra,0xffffc
    80005678:	700080e7          	jalr	1792(ra) # 80001d74 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000567c:	0004851b          	sext.w	a0,s1
    80005680:	bbc1                	j	80005450 <exec+0x9c>
    80005682:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005686:	df843583          	ld	a1,-520(s0)
    8000568a:	855a                	mv	a0,s6
    8000568c:	ffffc097          	auipc	ra,0xffffc
    80005690:	6e8080e7          	jalr	1768(ra) # 80001d74 <proc_freepagetable>
  if(ip){
    80005694:	da0a94e3          	bnez	s5,8000543c <exec+0x88>
  return -1;
    80005698:	557d                	li	a0,-1
    8000569a:	bb5d                	j	80005450 <exec+0x9c>
    8000569c:	de943c23          	sd	s1,-520(s0)
    800056a0:	b7dd                	j	80005686 <exec+0x2d2>
    800056a2:	de943c23          	sd	s1,-520(s0)
    800056a6:	b7c5                	j	80005686 <exec+0x2d2>
    800056a8:	de943c23          	sd	s1,-520(s0)
    800056ac:	bfe9                	j	80005686 <exec+0x2d2>
  sz = sz1;
    800056ae:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056b2:	4a81                	li	s5,0
    800056b4:	bfc9                	j	80005686 <exec+0x2d2>
  sz = sz1;
    800056b6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056ba:	4a81                	li	s5,0
    800056bc:	b7e9                	j	80005686 <exec+0x2d2>
  sz = sz1;
    800056be:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800056c2:	4a81                	li	s5,0
    800056c4:	b7c9                	j	80005686 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056c6:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800056ca:	e0843783          	ld	a5,-504(s0)
    800056ce:	0017869b          	addiw	a3,a5,1
    800056d2:	e0d43423          	sd	a3,-504(s0)
    800056d6:	e0043783          	ld	a5,-512(s0)
    800056da:	0387879b          	addiw	a5,a5,56
    800056de:	e8045703          	lhu	a4,-384(s0)
    800056e2:	e2e6d3e3          	bge	a3,a4,80005508 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800056e6:	2781                	sext.w	a5,a5
    800056e8:	e0f43023          	sd	a5,-512(s0)
    800056ec:	03800713          	li	a4,56
    800056f0:	86be                	mv	a3,a5
    800056f2:	e1040613          	addi	a2,s0,-496
    800056f6:	4581                	li	a1,0
    800056f8:	8556                	mv	a0,s5
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	572080e7          	jalr	1394(ra) # 80003c6c <readi>
    80005702:	03800793          	li	a5,56
    80005706:	f6f51ee3          	bne	a0,a5,80005682 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    8000570a:	e1042783          	lw	a5,-496(s0)
    8000570e:	4705                	li	a4,1
    80005710:	fae79de3          	bne	a5,a4,800056ca <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005714:	e3843603          	ld	a2,-456(s0)
    80005718:	e3043783          	ld	a5,-464(s0)
    8000571c:	f8f660e3          	bltu	a2,a5,8000569c <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005720:	e2043783          	ld	a5,-480(s0)
    80005724:	963e                	add	a2,a2,a5
    80005726:	f6f66ee3          	bltu	a2,a5,800056a2 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000572a:	85a6                	mv	a1,s1
    8000572c:	855a                	mv	a0,s6
    8000572e:	ffffc097          	auipc	ra,0xffffc
    80005732:	cc0080e7          	jalr	-832(ra) # 800013ee <uvmalloc>
    80005736:	dea43c23          	sd	a0,-520(s0)
    8000573a:	d53d                	beqz	a0,800056a8 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    8000573c:	e2043c03          	ld	s8,-480(s0)
    80005740:	de043783          	ld	a5,-544(s0)
    80005744:	00fc77b3          	and	a5,s8,a5
    80005748:	ff9d                	bnez	a5,80005686 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000574a:	e1842c83          	lw	s9,-488(s0)
    8000574e:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005752:	f60b8ae3          	beqz	s7,800056c6 <exec+0x312>
    80005756:	89de                	mv	s3,s7
    80005758:	4481                	li	s1,0
    8000575a:	b371                	j	800054e6 <exec+0x132>

000000008000575c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000575c:	7179                	addi	sp,sp,-48
    8000575e:	f406                	sd	ra,40(sp)
    80005760:	f022                	sd	s0,32(sp)
    80005762:	ec26                	sd	s1,24(sp)
    80005764:	e84a                	sd	s2,16(sp)
    80005766:	1800                	addi	s0,sp,48
    80005768:	892e                	mv	s2,a1
    8000576a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000576c:	fdc40593          	addi	a1,s0,-36
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	6d6080e7          	jalr	1750(ra) # 80002e46 <argint>
    80005778:	04054063          	bltz	a0,800057b8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000577c:	fdc42703          	lw	a4,-36(s0)
    80005780:	47bd                	li	a5,15
    80005782:	02e7ed63          	bltu	a5,a4,800057bc <argfd+0x60>
    80005786:	ffffc097          	auipc	ra,0xffffc
    8000578a:	48e080e7          	jalr	1166(ra) # 80001c14 <myproc>
    8000578e:	fdc42703          	lw	a4,-36(s0)
    80005792:	01a70793          	addi	a5,a4,26
    80005796:	078e                	slli	a5,a5,0x3
    80005798:	953e                	add	a0,a0,a5
    8000579a:	611c                	ld	a5,0(a0)
    8000579c:	c395                	beqz	a5,800057c0 <argfd+0x64>
    return -1;
  if(pfd)
    8000579e:	00090463          	beqz	s2,800057a6 <argfd+0x4a>
    *pfd = fd;
    800057a2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800057a6:	4501                	li	a0,0
  if(pf)
    800057a8:	c091                	beqz	s1,800057ac <argfd+0x50>
    *pf = f;
    800057aa:	e09c                	sd	a5,0(s1)
}
    800057ac:	70a2                	ld	ra,40(sp)
    800057ae:	7402                	ld	s0,32(sp)
    800057b0:	64e2                	ld	s1,24(sp)
    800057b2:	6942                	ld	s2,16(sp)
    800057b4:	6145                	addi	sp,sp,48
    800057b6:	8082                	ret
    return -1;
    800057b8:	557d                	li	a0,-1
    800057ba:	bfcd                	j	800057ac <argfd+0x50>
    return -1;
    800057bc:	557d                	li	a0,-1
    800057be:	b7fd                	j	800057ac <argfd+0x50>
    800057c0:	557d                	li	a0,-1
    800057c2:	b7ed                	j	800057ac <argfd+0x50>

00000000800057c4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800057c4:	1101                	addi	sp,sp,-32
    800057c6:	ec06                	sd	ra,24(sp)
    800057c8:	e822                	sd	s0,16(sp)
    800057ca:	e426                	sd	s1,8(sp)
    800057cc:	1000                	addi	s0,sp,32
    800057ce:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800057d0:	ffffc097          	auipc	ra,0xffffc
    800057d4:	444080e7          	jalr	1092(ra) # 80001c14 <myproc>
    800057d8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800057da:	0d050793          	addi	a5,a0,208
    800057de:	4501                	li	a0,0
    800057e0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800057e2:	6398                	ld	a4,0(a5)
    800057e4:	cb19                	beqz	a4,800057fa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800057e6:	2505                	addiw	a0,a0,1
    800057e8:	07a1                	addi	a5,a5,8
    800057ea:	fed51ce3          	bne	a0,a3,800057e2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800057ee:	557d                	li	a0,-1
}
    800057f0:	60e2                	ld	ra,24(sp)
    800057f2:	6442                	ld	s0,16(sp)
    800057f4:	64a2                	ld	s1,8(sp)
    800057f6:	6105                	addi	sp,sp,32
    800057f8:	8082                	ret
      p->ofile[fd] = f;
    800057fa:	01a50793          	addi	a5,a0,26
    800057fe:	078e                	slli	a5,a5,0x3
    80005800:	963e                	add	a2,a2,a5
    80005802:	e204                	sd	s1,0(a2)
      return fd;
    80005804:	b7f5                	j	800057f0 <fdalloc+0x2c>

0000000080005806 <sys_dup>:

uint64
sys_dup(void)
{
    80005806:	7179                	addi	sp,sp,-48
    80005808:	f406                	sd	ra,40(sp)
    8000580a:	f022                	sd	s0,32(sp)
    8000580c:	ec26                	sd	s1,24(sp)
    8000580e:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005810:	fd840613          	addi	a2,s0,-40
    80005814:	4581                	li	a1,0
    80005816:	4501                	li	a0,0
    80005818:	00000097          	auipc	ra,0x0
    8000581c:	f44080e7          	jalr	-188(ra) # 8000575c <argfd>
    return -1;
    80005820:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005822:	02054363          	bltz	a0,80005848 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005826:	fd843503          	ld	a0,-40(s0)
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	f9a080e7          	jalr	-102(ra) # 800057c4 <fdalloc>
    80005832:	84aa                	mv	s1,a0
    return -1;
    80005834:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005836:	00054963          	bltz	a0,80005848 <sys_dup+0x42>
  filedup(f);
    8000583a:	fd843503          	ld	a0,-40(s0)
    8000583e:	fffff097          	auipc	ra,0xfffff
    80005842:	2dc080e7          	jalr	732(ra) # 80004b1a <filedup>
  return fd;
    80005846:	87a6                	mv	a5,s1
}
    80005848:	853e                	mv	a0,a5
    8000584a:	70a2                	ld	ra,40(sp)
    8000584c:	7402                	ld	s0,32(sp)
    8000584e:	64e2                	ld	s1,24(sp)
    80005850:	6145                	addi	sp,sp,48
    80005852:	8082                	ret

0000000080005854 <sys_read>:

uint64
sys_read(void)
{
    80005854:	7179                	addi	sp,sp,-48
    80005856:	f406                	sd	ra,40(sp)
    80005858:	f022                	sd	s0,32(sp)
    8000585a:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585c:	fe840613          	addi	a2,s0,-24
    80005860:	4581                	li	a1,0
    80005862:	4501                	li	a0,0
    80005864:	00000097          	auipc	ra,0x0
    80005868:	ef8080e7          	jalr	-264(ra) # 8000575c <argfd>
    return -1;
    8000586c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000586e:	04054163          	bltz	a0,800058b0 <sys_read+0x5c>
    80005872:	fe440593          	addi	a1,s0,-28
    80005876:	4509                	li	a0,2
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	5ce080e7          	jalr	1486(ra) # 80002e46 <argint>
    return -1;
    80005880:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005882:	02054763          	bltz	a0,800058b0 <sys_read+0x5c>
    80005886:	fd840593          	addi	a1,s0,-40
    8000588a:	4505                	li	a0,1
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	5dc080e7          	jalr	1500(ra) # 80002e68 <argaddr>
    return -1;
    80005894:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005896:	00054d63          	bltz	a0,800058b0 <sys_read+0x5c>
  return fileread(f, p, n);
    8000589a:	fe442603          	lw	a2,-28(s0)
    8000589e:	fd843583          	ld	a1,-40(s0)
    800058a2:	fe843503          	ld	a0,-24(s0)
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	400080e7          	jalr	1024(ra) # 80004ca6 <fileread>
    800058ae:	87aa                	mv	a5,a0
}
    800058b0:	853e                	mv	a0,a5
    800058b2:	70a2                	ld	ra,40(sp)
    800058b4:	7402                	ld	s0,32(sp)
    800058b6:	6145                	addi	sp,sp,48
    800058b8:	8082                	ret

00000000800058ba <sys_write>:

uint64
sys_write(void)
{
    800058ba:	7179                	addi	sp,sp,-48
    800058bc:	f406                	sd	ra,40(sp)
    800058be:	f022                	sd	s0,32(sp)
    800058c0:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c2:	fe840613          	addi	a2,s0,-24
    800058c6:	4581                	li	a1,0
    800058c8:	4501                	li	a0,0
    800058ca:	00000097          	auipc	ra,0x0
    800058ce:	e92080e7          	jalr	-366(ra) # 8000575c <argfd>
    return -1;
    800058d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d4:	04054163          	bltz	a0,80005916 <sys_write+0x5c>
    800058d8:	fe440593          	addi	a1,s0,-28
    800058dc:	4509                	li	a0,2
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	568080e7          	jalr	1384(ra) # 80002e46 <argint>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058e8:	02054763          	bltz	a0,80005916 <sys_write+0x5c>
    800058ec:	fd840593          	addi	a1,s0,-40
    800058f0:	4505                	li	a0,1
    800058f2:	ffffd097          	auipc	ra,0xffffd
    800058f6:	576080e7          	jalr	1398(ra) # 80002e68 <argaddr>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058fc:	00054d63          	bltz	a0,80005916 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005900:	fe442603          	lw	a2,-28(s0)
    80005904:	fd843583          	ld	a1,-40(s0)
    80005908:	fe843503          	ld	a0,-24(s0)
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	45c080e7          	jalr	1116(ra) # 80004d68 <filewrite>
    80005914:	87aa                	mv	a5,a0
}
    80005916:	853e                	mv	a0,a5
    80005918:	70a2                	ld	ra,40(sp)
    8000591a:	7402                	ld	s0,32(sp)
    8000591c:	6145                	addi	sp,sp,48
    8000591e:	8082                	ret

0000000080005920 <sys_close>:

uint64
sys_close(void)
{
    80005920:	1101                	addi	sp,sp,-32
    80005922:	ec06                	sd	ra,24(sp)
    80005924:	e822                	sd	s0,16(sp)
    80005926:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005928:	fe040613          	addi	a2,s0,-32
    8000592c:	fec40593          	addi	a1,s0,-20
    80005930:	4501                	li	a0,0
    80005932:	00000097          	auipc	ra,0x0
    80005936:	e2a080e7          	jalr	-470(ra) # 8000575c <argfd>
    return -1;
    8000593a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000593c:	02054463          	bltz	a0,80005964 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005940:	ffffc097          	auipc	ra,0xffffc
    80005944:	2d4080e7          	jalr	724(ra) # 80001c14 <myproc>
    80005948:	fec42783          	lw	a5,-20(s0)
    8000594c:	07e9                	addi	a5,a5,26
    8000594e:	078e                	slli	a5,a5,0x3
    80005950:	97aa                	add	a5,a5,a0
    80005952:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005956:	fe043503          	ld	a0,-32(s0)
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	212080e7          	jalr	530(ra) # 80004b6c <fileclose>
  return 0;
    80005962:	4781                	li	a5,0
}
    80005964:	853e                	mv	a0,a5
    80005966:	60e2                	ld	ra,24(sp)
    80005968:	6442                	ld	s0,16(sp)
    8000596a:	6105                	addi	sp,sp,32
    8000596c:	8082                	ret

000000008000596e <sys_fstat>:

uint64
sys_fstat(void)
{
    8000596e:	1101                	addi	sp,sp,-32
    80005970:	ec06                	sd	ra,24(sp)
    80005972:	e822                	sd	s0,16(sp)
    80005974:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005976:	fe840613          	addi	a2,s0,-24
    8000597a:	4581                	li	a1,0
    8000597c:	4501                	li	a0,0
    8000597e:	00000097          	auipc	ra,0x0
    80005982:	dde080e7          	jalr	-546(ra) # 8000575c <argfd>
    return -1;
    80005986:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005988:	02054563          	bltz	a0,800059b2 <sys_fstat+0x44>
    8000598c:	fe040593          	addi	a1,s0,-32
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	4d6080e7          	jalr	1238(ra) # 80002e68 <argaddr>
    return -1;
    8000599a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000599c:	00054b63          	bltz	a0,800059b2 <sys_fstat+0x44>
  return filestat(f, st);
    800059a0:	fe043583          	ld	a1,-32(s0)
    800059a4:	fe843503          	ld	a0,-24(s0)
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	28c080e7          	jalr	652(ra) # 80004c34 <filestat>
    800059b0:	87aa                	mv	a5,a0
}
    800059b2:	853e                	mv	a0,a5
    800059b4:	60e2                	ld	ra,24(sp)
    800059b6:	6442                	ld	s0,16(sp)
    800059b8:	6105                	addi	sp,sp,32
    800059ba:	8082                	ret

00000000800059bc <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    800059bc:	7169                	addi	sp,sp,-304
    800059be:	f606                	sd	ra,296(sp)
    800059c0:	f222                	sd	s0,288(sp)
    800059c2:	ee26                	sd	s1,280(sp)
    800059c4:	ea4a                	sd	s2,272(sp)
    800059c6:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059c8:	08000613          	li	a2,128
    800059cc:	ed040593          	addi	a1,s0,-304
    800059d0:	4501                	li	a0,0
    800059d2:	ffffd097          	auipc	ra,0xffffd
    800059d6:	4b8080e7          	jalr	1208(ra) # 80002e8a <argstr>
    return -1;
    800059da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059dc:	10054e63          	bltz	a0,80005af8 <sys_link+0x13c>
    800059e0:	08000613          	li	a2,128
    800059e4:	f5040593          	addi	a1,s0,-176
    800059e8:	4505                	li	a0,1
    800059ea:	ffffd097          	auipc	ra,0xffffd
    800059ee:	4a0080e7          	jalr	1184(ra) # 80002e8a <argstr>
    return -1;
    800059f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059f4:	10054263          	bltz	a0,80005af8 <sys_link+0x13c>

  begin_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	ca8080e7          	jalr	-856(ra) # 800046a0 <begin_op>
  if((ip = namei(old)) == 0){
    80005a00:	ed040513          	addi	a0,s0,-304
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	76a080e7          	jalr	1898(ra) # 8000416e <namei>
    80005a0c:	84aa                	mv	s1,a0
    80005a0e:	c551                	beqz	a0,80005a9a <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	fa8080e7          	jalr	-88(ra) # 800039b8 <ilock>
  if(ip->type == T_DIR){
    80005a18:	04449703          	lh	a4,68(s1)
    80005a1c:	4785                	li	a5,1
    80005a1e:	08f70463          	beq	a4,a5,80005aa6 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005a22:	04a4d783          	lhu	a5,74(s1)
    80005a26:	2785                	addiw	a5,a5,1
    80005a28:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a2c:	8526                	mv	a0,s1
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	ec0080e7          	jalr	-320(ra) # 800038ee <iupdate>
  iunlock(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	042080e7          	jalr	66(ra) # 80003a7a <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005a40:	fd040593          	addi	a1,s0,-48
    80005a44:	f5040513          	addi	a0,s0,-176
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	744080e7          	jalr	1860(ra) # 8000418c <nameiparent>
    80005a50:	892a                	mv	s2,a0
    80005a52:	c935                	beqz	a0,80005ac6 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	f64080e7          	jalr	-156(ra) # 800039b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a5c:	00092703          	lw	a4,0(s2)
    80005a60:	409c                	lw	a5,0(s1)
    80005a62:	04f71d63          	bne	a4,a5,80005abc <sys_link+0x100>
    80005a66:	40d0                	lw	a2,4(s1)
    80005a68:	fd040593          	addi	a1,s0,-48
    80005a6c:	854a                	mv	a0,s2
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	63e080e7          	jalr	1598(ra) # 800040ac <dirlink>
    80005a76:	04054363          	bltz	a0,80005abc <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005a7a:	854a                	mv	a0,s2
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	19e080e7          	jalr	414(ra) # 80003c1a <iunlockput>
  iput(ip);
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	0ec080e7          	jalr	236(ra) # 80003b72 <iput>

  end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	c92080e7          	jalr	-878(ra) # 80004720 <end_op>

  return 0;
    80005a96:	4781                	li	a5,0
    80005a98:	a085                	j	80005af8 <sys_link+0x13c>
    end_op();
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	c86080e7          	jalr	-890(ra) # 80004720 <end_op>
    return -1;
    80005aa2:	57fd                	li	a5,-1
    80005aa4:	a891                	j	80005af8 <sys_link+0x13c>
    iunlockput(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	172080e7          	jalr	370(ra) # 80003c1a <iunlockput>
    end_op();
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	c70080e7          	jalr	-912(ra) # 80004720 <end_op>
    return -1;
    80005ab8:	57fd                	li	a5,-1
    80005aba:	a83d                	j	80005af8 <sys_link+0x13c>
    iunlockput(dp);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	15c080e7          	jalr	348(ra) # 80003c1a <iunlockput>

bad:
  ilock(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	ef0080e7          	jalr	-272(ra) # 800039b8 <ilock>
  ip->nlink--;
    80005ad0:	04a4d783          	lhu	a5,74(s1)
    80005ad4:	37fd                	addiw	a5,a5,-1
    80005ad6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ada:	8526                	mv	a0,s1
    80005adc:	ffffe097          	auipc	ra,0xffffe
    80005ae0:	e12080e7          	jalr	-494(ra) # 800038ee <iupdate>
  iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	134080e7          	jalr	308(ra) # 80003c1a <iunlockput>
  end_op();
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	c32080e7          	jalr	-974(ra) # 80004720 <end_op>
  return -1;
    80005af6:	57fd                	li	a5,-1
}
    80005af8:	853e                	mv	a0,a5
    80005afa:	70b2                	ld	ra,296(sp)
    80005afc:	7412                	ld	s0,288(sp)
    80005afe:	64f2                	ld	s1,280(sp)
    80005b00:	6952                	ld	s2,272(sp)
    80005b02:	6155                	addi	sp,sp,304
    80005b04:	8082                	ret

0000000080005b06 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b06:	4578                	lw	a4,76(a0)
    80005b08:	02000793          	li	a5,32
    80005b0c:	04e7fa63          	bgeu	a5,a4,80005b60 <isdirempty+0x5a>
{
    80005b10:	7179                	addi	sp,sp,-48
    80005b12:	f406                	sd	ra,40(sp)
    80005b14:	f022                	sd	s0,32(sp)
    80005b16:	ec26                	sd	s1,24(sp)
    80005b18:	e84a                	sd	s2,16(sp)
    80005b1a:	1800                	addi	s0,sp,48
    80005b1c:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b1e:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b22:	4741                	li	a4,16
    80005b24:	86a6                	mv	a3,s1
    80005b26:	fd040613          	addi	a2,s0,-48
    80005b2a:	4581                	li	a1,0
    80005b2c:	854a                	mv	a0,s2
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	13e080e7          	jalr	318(ra) # 80003c6c <readi>
    80005b36:	47c1                	li	a5,16
    80005b38:	00f51c63          	bne	a0,a5,80005b50 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005b3c:	fd045783          	lhu	a5,-48(s0)
    80005b40:	e395                	bnez	a5,80005b64 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b42:	24c1                	addiw	s1,s1,16
    80005b44:	04c92783          	lw	a5,76(s2)
    80005b48:	fcf4ede3          	bltu	s1,a5,80005b22 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005b4c:	4505                	li	a0,1
    80005b4e:	a821                	j	80005b66 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005b50:	00003517          	auipc	a0,0x3
    80005b54:	cc850513          	addi	a0,a0,-824 # 80008818 <syscalls+0x310>
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	9d2080e7          	jalr	-1582(ra) # 8000052a <panic>
  return 1;
    80005b60:	4505                	li	a0,1
}
    80005b62:	8082                	ret
      return 0;
    80005b64:	4501                	li	a0,0
}
    80005b66:	70a2                	ld	ra,40(sp)
    80005b68:	7402                	ld	s0,32(sp)
    80005b6a:	64e2                	ld	s1,24(sp)
    80005b6c:	6942                	ld	s2,16(sp)
    80005b6e:	6145                	addi	sp,sp,48
    80005b70:	8082                	ret

0000000080005b72 <sys_unlink>:

uint64
sys_unlink(void)
{
    80005b72:	7155                	addi	sp,sp,-208
    80005b74:	e586                	sd	ra,200(sp)
    80005b76:	e1a2                	sd	s0,192(sp)
    80005b78:	fd26                	sd	s1,184(sp)
    80005b7a:	f94a                	sd	s2,176(sp)
    80005b7c:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005b7e:	08000613          	li	a2,128
    80005b82:	f4040593          	addi	a1,s0,-192
    80005b86:	4501                	li	a0,0
    80005b88:	ffffd097          	auipc	ra,0xffffd
    80005b8c:	302080e7          	jalr	770(ra) # 80002e8a <argstr>
    80005b90:	16054363          	bltz	a0,80005cf6 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005b94:	fffff097          	auipc	ra,0xfffff
    80005b98:	b0c080e7          	jalr	-1268(ra) # 800046a0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b9c:	fc040593          	addi	a1,s0,-64
    80005ba0:	f4040513          	addi	a0,s0,-192
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	5e8080e7          	jalr	1512(ra) # 8000418c <nameiparent>
    80005bac:	84aa                	mv	s1,a0
    80005bae:	c961                	beqz	a0,80005c7e <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	e08080e7          	jalr	-504(ra) # 800039b8 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bb8:	00003597          	auipc	a1,0x3
    80005bbc:	b4058593          	addi	a1,a1,-1216 # 800086f8 <syscalls+0x1f0>
    80005bc0:	fc040513          	addi	a0,s0,-64
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	2be080e7          	jalr	702(ra) # 80003e82 <namecmp>
    80005bcc:	c175                	beqz	a0,80005cb0 <sys_unlink+0x13e>
    80005bce:	00003597          	auipc	a1,0x3
    80005bd2:	b3258593          	addi	a1,a1,-1230 # 80008700 <syscalls+0x1f8>
    80005bd6:	fc040513          	addi	a0,s0,-64
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	2a8080e7          	jalr	680(ra) # 80003e82 <namecmp>
    80005be2:	c579                	beqz	a0,80005cb0 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005be4:	f3c40613          	addi	a2,s0,-196
    80005be8:	fc040593          	addi	a1,s0,-64
    80005bec:	8526                	mv	a0,s1
    80005bee:	ffffe097          	auipc	ra,0xffffe
    80005bf2:	2ae080e7          	jalr	686(ra) # 80003e9c <dirlookup>
    80005bf6:	892a                	mv	s2,a0
    80005bf8:	cd45                	beqz	a0,80005cb0 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	dbe080e7          	jalr	-578(ra) # 800039b8 <ilock>

  if(ip->nlink < 1)
    80005c02:	04a91783          	lh	a5,74(s2)
    80005c06:	08f05263          	blez	a5,80005c8a <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c0a:	04491703          	lh	a4,68(s2)
    80005c0e:	4785                	li	a5,1
    80005c10:	08f70563          	beq	a4,a5,80005c9a <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005c14:	4641                	li	a2,16
    80005c16:	4581                	li	a1,0
    80005c18:	fd040513          	addi	a0,s0,-48
    80005c1c:	ffffb097          	auipc	ra,0xffffb
    80005c20:	0a2080e7          	jalr	162(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c24:	4741                	li	a4,16
    80005c26:	f3c42683          	lw	a3,-196(s0)
    80005c2a:	fd040613          	addi	a2,s0,-48
    80005c2e:	4581                	li	a1,0
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	132080e7          	jalr	306(ra) # 80003d64 <writei>
    80005c3a:	47c1                	li	a5,16
    80005c3c:	08f51a63          	bne	a0,a5,80005cd0 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005c40:	04491703          	lh	a4,68(s2)
    80005c44:	4785                	li	a5,1
    80005c46:	08f70d63          	beq	a4,a5,80005ce0 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005c4a:	8526                	mv	a0,s1
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	fce080e7          	jalr	-50(ra) # 80003c1a <iunlockput>

  ip->nlink--;
    80005c54:	04a95783          	lhu	a5,74(s2)
    80005c58:	37fd                	addiw	a5,a5,-1
    80005c5a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c5e:	854a                	mv	a0,s2
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	c8e080e7          	jalr	-882(ra) # 800038ee <iupdate>
  iunlockput(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	fb0080e7          	jalr	-80(ra) # 80003c1a <iunlockput>

  end_op();
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	aae080e7          	jalr	-1362(ra) # 80004720 <end_op>

  return 0;
    80005c7a:	4501                	li	a0,0
    80005c7c:	a0a1                	j	80005cc4 <sys_unlink+0x152>
    end_op();
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	aa2080e7          	jalr	-1374(ra) # 80004720 <end_op>
    return -1;
    80005c86:	557d                	li	a0,-1
    80005c88:	a835                	j	80005cc4 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005c8a:	00003517          	auipc	a0,0x3
    80005c8e:	a7e50513          	addi	a0,a0,-1410 # 80008708 <syscalls+0x200>
    80005c92:	ffffb097          	auipc	ra,0xffffb
    80005c96:	898080e7          	jalr	-1896(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c9a:	854a                	mv	a0,s2
    80005c9c:	00000097          	auipc	ra,0x0
    80005ca0:	e6a080e7          	jalr	-406(ra) # 80005b06 <isdirempty>
    80005ca4:	f925                	bnez	a0,80005c14 <sys_unlink+0xa2>
    iunlockput(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	f72080e7          	jalr	-142(ra) # 80003c1a <iunlockput>

bad:
  iunlockput(dp);
    80005cb0:	8526                	mv	a0,s1
    80005cb2:	ffffe097          	auipc	ra,0xffffe
    80005cb6:	f68080e7          	jalr	-152(ra) # 80003c1a <iunlockput>
  end_op();
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	a66080e7          	jalr	-1434(ra) # 80004720 <end_op>
  return -1;
    80005cc2:	557d                	li	a0,-1
}
    80005cc4:	60ae                	ld	ra,200(sp)
    80005cc6:	640e                	ld	s0,192(sp)
    80005cc8:	74ea                	ld	s1,184(sp)
    80005cca:	794a                	ld	s2,176(sp)
    80005ccc:	6169                	addi	sp,sp,208
    80005cce:	8082                	ret
    panic("unlink: writei");
    80005cd0:	00003517          	auipc	a0,0x3
    80005cd4:	a5050513          	addi	a0,a0,-1456 # 80008720 <syscalls+0x218>
    80005cd8:	ffffb097          	auipc	ra,0xffffb
    80005cdc:	852080e7          	jalr	-1966(ra) # 8000052a <panic>
    dp->nlink--;
    80005ce0:	04a4d783          	lhu	a5,74(s1)
    80005ce4:	37fd                	addiw	a5,a5,-1
    80005ce6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cea:	8526                	mv	a0,s1
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	c02080e7          	jalr	-1022(ra) # 800038ee <iupdate>
    80005cf4:	bf99                	j	80005c4a <sys_unlink+0xd8>
    return -1;
    80005cf6:	557d                	li	a0,-1
    80005cf8:	b7f1                	j	80005cc4 <sys_unlink+0x152>

0000000080005cfa <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80005cfa:	715d                	addi	sp,sp,-80
    80005cfc:	e486                	sd	ra,72(sp)
    80005cfe:	e0a2                	sd	s0,64(sp)
    80005d00:	fc26                	sd	s1,56(sp)
    80005d02:	f84a                	sd	s2,48(sp)
    80005d04:	f44e                	sd	s3,40(sp)
    80005d06:	f052                	sd	s4,32(sp)
    80005d08:	ec56                	sd	s5,24(sp)
    80005d0a:	0880                	addi	s0,sp,80
    80005d0c:	89ae                	mv	s3,a1
    80005d0e:	8ab2                	mv	s5,a2
    80005d10:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005d12:	fb040593          	addi	a1,s0,-80
    80005d16:	ffffe097          	auipc	ra,0xffffe
    80005d1a:	476080e7          	jalr	1142(ra) # 8000418c <nameiparent>
    80005d1e:	892a                	mv	s2,a0
    80005d20:	12050e63          	beqz	a0,80005e5c <create+0x162>
    return 0;

  ilock(dp);
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	c94080e7          	jalr	-876(ra) # 800039b8 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80005d2c:	4601                	li	a2,0
    80005d2e:	fb040593          	addi	a1,s0,-80
    80005d32:	854a                	mv	a0,s2
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	168080e7          	jalr	360(ra) # 80003e9c <dirlookup>
    80005d3c:	84aa                	mv	s1,a0
    80005d3e:	c921                	beqz	a0,80005d8e <create+0x94>
    iunlockput(dp);
    80005d40:	854a                	mv	a0,s2
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	ed8080e7          	jalr	-296(ra) # 80003c1a <iunlockput>
    ilock(ip);
    80005d4a:	8526                	mv	a0,s1
    80005d4c:	ffffe097          	auipc	ra,0xffffe
    80005d50:	c6c080e7          	jalr	-916(ra) # 800039b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005d54:	2981                	sext.w	s3,s3
    80005d56:	4789                	li	a5,2
    80005d58:	02f99463          	bne	s3,a5,80005d80 <create+0x86>
    80005d5c:	0444d783          	lhu	a5,68(s1)
    80005d60:	37f9                	addiw	a5,a5,-2
    80005d62:	17c2                	slli	a5,a5,0x30
    80005d64:	93c1                	srli	a5,a5,0x30
    80005d66:	4705                	li	a4,1
    80005d68:	00f76c63          	bltu	a4,a5,80005d80 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005d6c:	8526                	mv	a0,s1
    80005d6e:	60a6                	ld	ra,72(sp)
    80005d70:	6406                	ld	s0,64(sp)
    80005d72:	74e2                	ld	s1,56(sp)
    80005d74:	7942                	ld	s2,48(sp)
    80005d76:	79a2                	ld	s3,40(sp)
    80005d78:	7a02                	ld	s4,32(sp)
    80005d7a:	6ae2                	ld	s5,24(sp)
    80005d7c:	6161                	addi	sp,sp,80
    80005d7e:	8082                	ret
    iunlockput(ip);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	e98080e7          	jalr	-360(ra) # 80003c1a <iunlockput>
    return 0;
    80005d8a:	4481                	li	s1,0
    80005d8c:	b7c5                	j	80005d6c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005d8e:	85ce                	mv	a1,s3
    80005d90:	00092503          	lw	a0,0(s2)
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	a8c080e7          	jalr	-1396(ra) # 80003820 <ialloc>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c521                	beqz	a0,80005de6 <create+0xec>
  ilock(ip);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	c18080e7          	jalr	-1000(ra) # 800039b8 <ilock>
  ip->major = major;
    80005da8:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005dac:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005db0:	4a05                	li	s4,1
    80005db2:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80005db6:	8526                	mv	a0,s1
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	b36080e7          	jalr	-1226(ra) # 800038ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005dc0:	2981                	sext.w	s3,s3
    80005dc2:	03498a63          	beq	s3,s4,80005df6 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dc6:	40d0                	lw	a2,4(s1)
    80005dc8:	fb040593          	addi	a1,s0,-80
    80005dcc:	854a                	mv	a0,s2
    80005dce:	ffffe097          	auipc	ra,0xffffe
    80005dd2:	2de080e7          	jalr	734(ra) # 800040ac <dirlink>
    80005dd6:	06054b63          	bltz	a0,80005e4c <create+0x152>
  iunlockput(dp);
    80005dda:	854a                	mv	a0,s2
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	e3e080e7          	jalr	-450(ra) # 80003c1a <iunlockput>
  return ip;
    80005de4:	b761                	j	80005d6c <create+0x72>
    panic("create: ialloc");
    80005de6:	00003517          	auipc	a0,0x3
    80005dea:	a4a50513          	addi	a0,a0,-1462 # 80008830 <syscalls+0x328>
    80005dee:	ffffa097          	auipc	ra,0xffffa
    80005df2:	73c080e7          	jalr	1852(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80005df6:	04a95783          	lhu	a5,74(s2)
    80005dfa:	2785                	addiw	a5,a5,1
    80005dfc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005e00:	854a                	mv	a0,s2
    80005e02:	ffffe097          	auipc	ra,0xffffe
    80005e06:	aec080e7          	jalr	-1300(ra) # 800038ee <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005e0a:	40d0                	lw	a2,4(s1)
    80005e0c:	00003597          	auipc	a1,0x3
    80005e10:	8ec58593          	addi	a1,a1,-1812 # 800086f8 <syscalls+0x1f0>
    80005e14:	8526                	mv	a0,s1
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	296080e7          	jalr	662(ra) # 800040ac <dirlink>
    80005e1e:	00054f63          	bltz	a0,80005e3c <create+0x142>
    80005e22:	00492603          	lw	a2,4(s2)
    80005e26:	00003597          	auipc	a1,0x3
    80005e2a:	8da58593          	addi	a1,a1,-1830 # 80008700 <syscalls+0x1f8>
    80005e2e:	8526                	mv	a0,s1
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	27c080e7          	jalr	636(ra) # 800040ac <dirlink>
    80005e38:	f80557e3          	bgez	a0,80005dc6 <create+0xcc>
      panic("create dots");
    80005e3c:	00003517          	auipc	a0,0x3
    80005e40:	a0450513          	addi	a0,a0,-1532 # 80008840 <syscalls+0x338>
    80005e44:	ffffa097          	auipc	ra,0xffffa
    80005e48:	6e6080e7          	jalr	1766(ra) # 8000052a <panic>
    panic("create: dirlink");
    80005e4c:	00003517          	auipc	a0,0x3
    80005e50:	a0450513          	addi	a0,a0,-1532 # 80008850 <syscalls+0x348>
    80005e54:	ffffa097          	auipc	ra,0xffffa
    80005e58:	6d6080e7          	jalr	1750(ra) # 8000052a <panic>
    return 0;
    80005e5c:	84aa                	mv	s1,a0
    80005e5e:	b739                	j	80005d6c <create+0x72>

0000000080005e60 <sys_open>:

uint64
sys_open(void)
{
    80005e60:	7131                	addi	sp,sp,-192
    80005e62:	fd06                	sd	ra,184(sp)
    80005e64:	f922                	sd	s0,176(sp)
    80005e66:	f526                	sd	s1,168(sp)
    80005e68:	f14a                	sd	s2,160(sp)
    80005e6a:	ed4e                	sd	s3,152(sp)
    80005e6c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e6e:	08000613          	li	a2,128
    80005e72:	f5040593          	addi	a1,s0,-176
    80005e76:	4501                	li	a0,0
    80005e78:	ffffd097          	auipc	ra,0xffffd
    80005e7c:	012080e7          	jalr	18(ra) # 80002e8a <argstr>
    return -1;
    80005e80:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005e82:	0c054163          	bltz	a0,80005f44 <sys_open+0xe4>
    80005e86:	f4c40593          	addi	a1,s0,-180
    80005e8a:	4505                	li	a0,1
    80005e8c:	ffffd097          	auipc	ra,0xffffd
    80005e90:	fba080e7          	jalr	-70(ra) # 80002e46 <argint>
    80005e94:	0a054863          	bltz	a0,80005f44 <sys_open+0xe4>

  begin_op();
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	808080e7          	jalr	-2040(ra) # 800046a0 <begin_op>

  if(omode & O_CREATE){
    80005ea0:	f4c42783          	lw	a5,-180(s0)
    80005ea4:	2007f793          	andi	a5,a5,512
    80005ea8:	cbdd                	beqz	a5,80005f5e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005eaa:	4681                	li	a3,0
    80005eac:	4601                	li	a2,0
    80005eae:	4589                	li	a1,2
    80005eb0:	f5040513          	addi	a0,s0,-176
    80005eb4:	00000097          	auipc	ra,0x0
    80005eb8:	e46080e7          	jalr	-442(ra) # 80005cfa <create>
    80005ebc:	892a                	mv	s2,a0
    if(ip == 0){
    80005ebe:	c959                	beqz	a0,80005f54 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ec0:	04491703          	lh	a4,68(s2)
    80005ec4:	478d                	li	a5,3
    80005ec6:	00f71763          	bne	a4,a5,80005ed4 <sys_open+0x74>
    80005eca:	04695703          	lhu	a4,70(s2)
    80005ece:	47a5                	li	a5,9
    80005ed0:	0ce7ec63          	bltu	a5,a4,80005fa8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ed4:	fffff097          	auipc	ra,0xfffff
    80005ed8:	bdc080e7          	jalr	-1060(ra) # 80004ab0 <filealloc>
    80005edc:	89aa                	mv	s3,a0
    80005ede:	10050263          	beqz	a0,80005fe2 <sys_open+0x182>
    80005ee2:	00000097          	auipc	ra,0x0
    80005ee6:	8e2080e7          	jalr	-1822(ra) # 800057c4 <fdalloc>
    80005eea:	84aa                	mv	s1,a0
    80005eec:	0e054663          	bltz	a0,80005fd8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005ef0:	04491703          	lh	a4,68(s2)
    80005ef4:	478d                	li	a5,3
    80005ef6:	0cf70463          	beq	a4,a5,80005fbe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005efa:	4789                	li	a5,2
    80005efc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005f00:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005f04:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005f08:	f4c42783          	lw	a5,-180(s0)
    80005f0c:	0017c713          	xori	a4,a5,1
    80005f10:	8b05                	andi	a4,a4,1
    80005f12:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005f16:	0037f713          	andi	a4,a5,3
    80005f1a:	00e03733          	snez	a4,a4
    80005f1e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005f22:	4007f793          	andi	a5,a5,1024
    80005f26:	c791                	beqz	a5,80005f32 <sys_open+0xd2>
    80005f28:	04491703          	lh	a4,68(s2)
    80005f2c:	4789                	li	a5,2
    80005f2e:	08f70f63          	beq	a4,a5,80005fcc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005f32:	854a                	mv	a0,s2
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	b46080e7          	jalr	-1210(ra) # 80003a7a <iunlock>
  end_op();
    80005f3c:	ffffe097          	auipc	ra,0xffffe
    80005f40:	7e4080e7          	jalr	2020(ra) # 80004720 <end_op>

  return fd;
}
    80005f44:	8526                	mv	a0,s1
    80005f46:	70ea                	ld	ra,184(sp)
    80005f48:	744a                	ld	s0,176(sp)
    80005f4a:	74aa                	ld	s1,168(sp)
    80005f4c:	790a                	ld	s2,160(sp)
    80005f4e:	69ea                	ld	s3,152(sp)
    80005f50:	6129                	addi	sp,sp,192
    80005f52:	8082                	ret
      end_op();
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7cc080e7          	jalr	1996(ra) # 80004720 <end_op>
      return -1;
    80005f5c:	b7e5                	j	80005f44 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005f5e:	f5040513          	addi	a0,s0,-176
    80005f62:	ffffe097          	auipc	ra,0xffffe
    80005f66:	20c080e7          	jalr	524(ra) # 8000416e <namei>
    80005f6a:	892a                	mv	s2,a0
    80005f6c:	c905                	beqz	a0,80005f9c <sys_open+0x13c>
    ilock(ip);
    80005f6e:	ffffe097          	auipc	ra,0xffffe
    80005f72:	a4a080e7          	jalr	-1462(ra) # 800039b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005f76:	04491703          	lh	a4,68(s2)
    80005f7a:	4785                	li	a5,1
    80005f7c:	f4f712e3          	bne	a4,a5,80005ec0 <sys_open+0x60>
    80005f80:	f4c42783          	lw	a5,-180(s0)
    80005f84:	dba1                	beqz	a5,80005ed4 <sys_open+0x74>
      iunlockput(ip);
    80005f86:	854a                	mv	a0,s2
    80005f88:	ffffe097          	auipc	ra,0xffffe
    80005f8c:	c92080e7          	jalr	-878(ra) # 80003c1a <iunlockput>
      end_op();
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	790080e7          	jalr	1936(ra) # 80004720 <end_op>
      return -1;
    80005f98:	54fd                	li	s1,-1
    80005f9a:	b76d                	j	80005f44 <sys_open+0xe4>
      end_op();
    80005f9c:	ffffe097          	auipc	ra,0xffffe
    80005fa0:	784080e7          	jalr	1924(ra) # 80004720 <end_op>
      return -1;
    80005fa4:	54fd                	li	s1,-1
    80005fa6:	bf79                	j	80005f44 <sys_open+0xe4>
    iunlockput(ip);
    80005fa8:	854a                	mv	a0,s2
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	c70080e7          	jalr	-912(ra) # 80003c1a <iunlockput>
    end_op();
    80005fb2:	ffffe097          	auipc	ra,0xffffe
    80005fb6:	76e080e7          	jalr	1902(ra) # 80004720 <end_op>
    return -1;
    80005fba:	54fd                	li	s1,-1
    80005fbc:	b761                	j	80005f44 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005fbe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005fc2:	04691783          	lh	a5,70(s2)
    80005fc6:	02f99223          	sh	a5,36(s3)
    80005fca:	bf2d                	j	80005f04 <sys_open+0xa4>
    itrunc(ip);
    80005fcc:	854a                	mv	a0,s2
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	af8080e7          	jalr	-1288(ra) # 80003ac6 <itrunc>
    80005fd6:	bfb1                	j	80005f32 <sys_open+0xd2>
      fileclose(f);
    80005fd8:	854e                	mv	a0,s3
    80005fda:	fffff097          	auipc	ra,0xfffff
    80005fde:	b92080e7          	jalr	-1134(ra) # 80004b6c <fileclose>
    iunlockput(ip);
    80005fe2:	854a                	mv	a0,s2
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	c36080e7          	jalr	-970(ra) # 80003c1a <iunlockput>
    end_op();
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	734080e7          	jalr	1844(ra) # 80004720 <end_op>
    return -1;
    80005ff4:	54fd                	li	s1,-1
    80005ff6:	b7b9                	j	80005f44 <sys_open+0xe4>

0000000080005ff8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ff8:	7175                	addi	sp,sp,-144
    80005ffa:	e506                	sd	ra,136(sp)
    80005ffc:	e122                	sd	s0,128(sp)
    80005ffe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	6a0080e7          	jalr	1696(ra) # 800046a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006008:	08000613          	li	a2,128
    8000600c:	f7040593          	addi	a1,s0,-144
    80006010:	4501                	li	a0,0
    80006012:	ffffd097          	auipc	ra,0xffffd
    80006016:	e78080e7          	jalr	-392(ra) # 80002e8a <argstr>
    8000601a:	02054963          	bltz	a0,8000604c <sys_mkdir+0x54>
    8000601e:	4681                	li	a3,0
    80006020:	4601                	li	a2,0
    80006022:	4585                	li	a1,1
    80006024:	f7040513          	addi	a0,s0,-144
    80006028:	00000097          	auipc	ra,0x0
    8000602c:	cd2080e7          	jalr	-814(ra) # 80005cfa <create>
    80006030:	cd11                	beqz	a0,8000604c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006032:	ffffe097          	auipc	ra,0xffffe
    80006036:	be8080e7          	jalr	-1048(ra) # 80003c1a <iunlockput>
  end_op();
    8000603a:	ffffe097          	auipc	ra,0xffffe
    8000603e:	6e6080e7          	jalr	1766(ra) # 80004720 <end_op>
  return 0;
    80006042:	4501                	li	a0,0
}
    80006044:	60aa                	ld	ra,136(sp)
    80006046:	640a                	ld	s0,128(sp)
    80006048:	6149                	addi	sp,sp,144
    8000604a:	8082                	ret
    end_op();
    8000604c:	ffffe097          	auipc	ra,0xffffe
    80006050:	6d4080e7          	jalr	1748(ra) # 80004720 <end_op>
    return -1;
    80006054:	557d                	li	a0,-1
    80006056:	b7fd                	j	80006044 <sys_mkdir+0x4c>

0000000080006058 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006058:	7135                	addi	sp,sp,-160
    8000605a:	ed06                	sd	ra,152(sp)
    8000605c:	e922                	sd	s0,144(sp)
    8000605e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006060:	ffffe097          	auipc	ra,0xffffe
    80006064:	640080e7          	jalr	1600(ra) # 800046a0 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006068:	08000613          	li	a2,128
    8000606c:	f7040593          	addi	a1,s0,-144
    80006070:	4501                	li	a0,0
    80006072:	ffffd097          	auipc	ra,0xffffd
    80006076:	e18080e7          	jalr	-488(ra) # 80002e8a <argstr>
    8000607a:	04054a63          	bltz	a0,800060ce <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000607e:	f6c40593          	addi	a1,s0,-148
    80006082:	4505                	li	a0,1
    80006084:	ffffd097          	auipc	ra,0xffffd
    80006088:	dc2080e7          	jalr	-574(ra) # 80002e46 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000608c:	04054163          	bltz	a0,800060ce <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006090:	f6840593          	addi	a1,s0,-152
    80006094:	4509                	li	a0,2
    80006096:	ffffd097          	auipc	ra,0xffffd
    8000609a:	db0080e7          	jalr	-592(ra) # 80002e46 <argint>
     argint(1, &major) < 0 ||
    8000609e:	02054863          	bltz	a0,800060ce <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800060a2:	f6841683          	lh	a3,-152(s0)
    800060a6:	f6c41603          	lh	a2,-148(s0)
    800060aa:	458d                	li	a1,3
    800060ac:	f7040513          	addi	a0,s0,-144
    800060b0:	00000097          	auipc	ra,0x0
    800060b4:	c4a080e7          	jalr	-950(ra) # 80005cfa <create>
     argint(2, &minor) < 0 ||
    800060b8:	c919                	beqz	a0,800060ce <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800060ba:	ffffe097          	auipc	ra,0xffffe
    800060be:	b60080e7          	jalr	-1184(ra) # 80003c1a <iunlockput>
  end_op();
    800060c2:	ffffe097          	auipc	ra,0xffffe
    800060c6:	65e080e7          	jalr	1630(ra) # 80004720 <end_op>
  return 0;
    800060ca:	4501                	li	a0,0
    800060cc:	a031                	j	800060d8 <sys_mknod+0x80>
    end_op();
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	652080e7          	jalr	1618(ra) # 80004720 <end_op>
    return -1;
    800060d6:	557d                	li	a0,-1
}
    800060d8:	60ea                	ld	ra,152(sp)
    800060da:	644a                	ld	s0,144(sp)
    800060dc:	610d                	addi	sp,sp,160
    800060de:	8082                	ret

00000000800060e0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800060e0:	7135                	addi	sp,sp,-160
    800060e2:	ed06                	sd	ra,152(sp)
    800060e4:	e922                	sd	s0,144(sp)
    800060e6:	e526                	sd	s1,136(sp)
    800060e8:	e14a                	sd	s2,128(sp)
    800060ea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800060ec:	ffffc097          	auipc	ra,0xffffc
    800060f0:	b28080e7          	jalr	-1240(ra) # 80001c14 <myproc>
    800060f4:	892a                	mv	s2,a0
  
  begin_op();
    800060f6:	ffffe097          	auipc	ra,0xffffe
    800060fa:	5aa080e7          	jalr	1450(ra) # 800046a0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800060fe:	08000613          	li	a2,128
    80006102:	f6040593          	addi	a1,s0,-160
    80006106:	4501                	li	a0,0
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	d82080e7          	jalr	-638(ra) # 80002e8a <argstr>
    80006110:	04054b63          	bltz	a0,80006166 <sys_chdir+0x86>
    80006114:	f6040513          	addi	a0,s0,-160
    80006118:	ffffe097          	auipc	ra,0xffffe
    8000611c:	056080e7          	jalr	86(ra) # 8000416e <namei>
    80006120:	84aa                	mv	s1,a0
    80006122:	c131                	beqz	a0,80006166 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006124:	ffffe097          	auipc	ra,0xffffe
    80006128:	894080e7          	jalr	-1900(ra) # 800039b8 <ilock>
  if(ip->type != T_DIR){
    8000612c:	04449703          	lh	a4,68(s1)
    80006130:	4785                	li	a5,1
    80006132:	04f71063          	bne	a4,a5,80006172 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006136:	8526                	mv	a0,s1
    80006138:	ffffe097          	auipc	ra,0xffffe
    8000613c:	942080e7          	jalr	-1726(ra) # 80003a7a <iunlock>
  iput(p->cwd);
    80006140:	15093503          	ld	a0,336(s2)
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	a2e080e7          	jalr	-1490(ra) # 80003b72 <iput>
  end_op();
    8000614c:	ffffe097          	auipc	ra,0xffffe
    80006150:	5d4080e7          	jalr	1492(ra) # 80004720 <end_op>
  p->cwd = ip;
    80006154:	14993823          	sd	s1,336(s2)
  return 0;
    80006158:	4501                	li	a0,0
}
    8000615a:	60ea                	ld	ra,152(sp)
    8000615c:	644a                	ld	s0,144(sp)
    8000615e:	64aa                	ld	s1,136(sp)
    80006160:	690a                	ld	s2,128(sp)
    80006162:	610d                	addi	sp,sp,160
    80006164:	8082                	ret
    end_op();
    80006166:	ffffe097          	auipc	ra,0xffffe
    8000616a:	5ba080e7          	jalr	1466(ra) # 80004720 <end_op>
    return -1;
    8000616e:	557d                	li	a0,-1
    80006170:	b7ed                	j	8000615a <sys_chdir+0x7a>
    iunlockput(ip);
    80006172:	8526                	mv	a0,s1
    80006174:	ffffe097          	auipc	ra,0xffffe
    80006178:	aa6080e7          	jalr	-1370(ra) # 80003c1a <iunlockput>
    end_op();
    8000617c:	ffffe097          	auipc	ra,0xffffe
    80006180:	5a4080e7          	jalr	1444(ra) # 80004720 <end_op>
    return -1;
    80006184:	557d                	li	a0,-1
    80006186:	bfd1                	j	8000615a <sys_chdir+0x7a>

0000000080006188 <sys_exec>:

uint64
sys_exec(void)
{
    80006188:	7145                	addi	sp,sp,-464
    8000618a:	e786                	sd	ra,456(sp)
    8000618c:	e3a2                	sd	s0,448(sp)
    8000618e:	ff26                	sd	s1,440(sp)
    80006190:	fb4a                	sd	s2,432(sp)
    80006192:	f74e                	sd	s3,424(sp)
    80006194:	f352                	sd	s4,416(sp)
    80006196:	ef56                	sd	s5,408(sp)
    80006198:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000619a:	08000613          	li	a2,128
    8000619e:	f4040593          	addi	a1,s0,-192
    800061a2:	4501                	li	a0,0
    800061a4:	ffffd097          	auipc	ra,0xffffd
    800061a8:	ce6080e7          	jalr	-794(ra) # 80002e8a <argstr>
    return -1;
    800061ac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800061ae:	0c054a63          	bltz	a0,80006282 <sys_exec+0xfa>
    800061b2:	e3840593          	addi	a1,s0,-456
    800061b6:	4505                	li	a0,1
    800061b8:	ffffd097          	auipc	ra,0xffffd
    800061bc:	cb0080e7          	jalr	-848(ra) # 80002e68 <argaddr>
    800061c0:	0c054163          	bltz	a0,80006282 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800061c4:	10000613          	li	a2,256
    800061c8:	4581                	li	a1,0
    800061ca:	e4040513          	addi	a0,s0,-448
    800061ce:	ffffb097          	auipc	ra,0xffffb
    800061d2:	af0080e7          	jalr	-1296(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800061d6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800061da:	89a6                	mv	s3,s1
    800061dc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800061de:	02000a13          	li	s4,32
    800061e2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800061e6:	00391793          	slli	a5,s2,0x3
    800061ea:	e3040593          	addi	a1,s0,-464
    800061ee:	e3843503          	ld	a0,-456(s0)
    800061f2:	953e                	add	a0,a0,a5
    800061f4:	ffffd097          	auipc	ra,0xffffd
    800061f8:	bb8080e7          	jalr	-1096(ra) # 80002dac <fetchaddr>
    800061fc:	02054a63          	bltz	a0,80006230 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006200:	e3043783          	ld	a5,-464(s0)
    80006204:	c3b9                	beqz	a5,8000624a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006206:	ffffb097          	auipc	ra,0xffffb
    8000620a:	8cc080e7          	jalr	-1844(ra) # 80000ad2 <kalloc>
    8000620e:	85aa                	mv	a1,a0
    80006210:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006214:	cd11                	beqz	a0,80006230 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006216:	6605                	lui	a2,0x1
    80006218:	e3043503          	ld	a0,-464(s0)
    8000621c:	ffffd097          	auipc	ra,0xffffd
    80006220:	be2080e7          	jalr	-1054(ra) # 80002dfe <fetchstr>
    80006224:	00054663          	bltz	a0,80006230 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006228:	0905                	addi	s2,s2,1
    8000622a:	09a1                	addi	s3,s3,8
    8000622c:	fb491be3          	bne	s2,s4,800061e2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006230:	10048913          	addi	s2,s1,256
    80006234:	6088                	ld	a0,0(s1)
    80006236:	c529                	beqz	a0,80006280 <sys_exec+0xf8>
    kfree(argv[i]);
    80006238:	ffffa097          	auipc	ra,0xffffa
    8000623c:	79e080e7          	jalr	1950(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006240:	04a1                	addi	s1,s1,8
    80006242:	ff2499e3          	bne	s1,s2,80006234 <sys_exec+0xac>
  return -1;
    80006246:	597d                	li	s2,-1
    80006248:	a82d                	j	80006282 <sys_exec+0xfa>
      argv[i] = 0;
    8000624a:	0a8e                	slli	s5,s5,0x3
    8000624c:	fc040793          	addi	a5,s0,-64
    80006250:	9abe                	add	s5,s5,a5
    80006252:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd2e80>
  int ret = exec(path, argv);
    80006256:	e4040593          	addi	a1,s0,-448
    8000625a:	f4040513          	addi	a0,s0,-192
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	156080e7          	jalr	342(ra) # 800053b4 <exec>
    80006266:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006268:	10048993          	addi	s3,s1,256
    8000626c:	6088                	ld	a0,0(s1)
    8000626e:	c911                	beqz	a0,80006282 <sys_exec+0xfa>
    kfree(argv[i]);
    80006270:	ffffa097          	auipc	ra,0xffffa
    80006274:	766080e7          	jalr	1894(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006278:	04a1                	addi	s1,s1,8
    8000627a:	ff3499e3          	bne	s1,s3,8000626c <sys_exec+0xe4>
    8000627e:	a011                	j	80006282 <sys_exec+0xfa>
  return -1;
    80006280:	597d                	li	s2,-1
}
    80006282:	854a                	mv	a0,s2
    80006284:	60be                	ld	ra,456(sp)
    80006286:	641e                	ld	s0,448(sp)
    80006288:	74fa                	ld	s1,440(sp)
    8000628a:	795a                	ld	s2,432(sp)
    8000628c:	79ba                	ld	s3,424(sp)
    8000628e:	7a1a                	ld	s4,416(sp)
    80006290:	6afa                	ld	s5,408(sp)
    80006292:	6179                	addi	sp,sp,464
    80006294:	8082                	ret

0000000080006296 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006296:	7139                	addi	sp,sp,-64
    80006298:	fc06                	sd	ra,56(sp)
    8000629a:	f822                	sd	s0,48(sp)
    8000629c:	f426                	sd	s1,40(sp)
    8000629e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800062a0:	ffffc097          	auipc	ra,0xffffc
    800062a4:	974080e7          	jalr	-1676(ra) # 80001c14 <myproc>
    800062a8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800062aa:	fd840593          	addi	a1,s0,-40
    800062ae:	4501                	li	a0,0
    800062b0:	ffffd097          	auipc	ra,0xffffd
    800062b4:	bb8080e7          	jalr	-1096(ra) # 80002e68 <argaddr>
    return -1;
    800062b8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800062ba:	0e054063          	bltz	a0,8000639a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800062be:	fc840593          	addi	a1,s0,-56
    800062c2:	fd040513          	addi	a0,s0,-48
    800062c6:	fffff097          	auipc	ra,0xfffff
    800062ca:	dcc080e7          	jalr	-564(ra) # 80005092 <pipealloc>
    return -1;
    800062ce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800062d0:	0c054563          	bltz	a0,8000639a <sys_pipe+0x104>
  fd0 = -1;
    800062d4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800062d8:	fd043503          	ld	a0,-48(s0)
    800062dc:	fffff097          	auipc	ra,0xfffff
    800062e0:	4e8080e7          	jalr	1256(ra) # 800057c4 <fdalloc>
    800062e4:	fca42223          	sw	a0,-60(s0)
    800062e8:	08054c63          	bltz	a0,80006380 <sys_pipe+0xea>
    800062ec:	fc843503          	ld	a0,-56(s0)
    800062f0:	fffff097          	auipc	ra,0xfffff
    800062f4:	4d4080e7          	jalr	1236(ra) # 800057c4 <fdalloc>
    800062f8:	fca42023          	sw	a0,-64(s0)
    800062fc:	06054863          	bltz	a0,8000636c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006300:	4691                	li	a3,4
    80006302:	fc440613          	addi	a2,s0,-60
    80006306:	fd843583          	ld	a1,-40(s0)
    8000630a:	68a8                	ld	a0,80(s1)
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	332080e7          	jalr	818(ra) # 8000163e <copyout>
    80006314:	02054063          	bltz	a0,80006334 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006318:	4691                	li	a3,4
    8000631a:	fc040613          	addi	a2,s0,-64
    8000631e:	fd843583          	ld	a1,-40(s0)
    80006322:	0591                	addi	a1,a1,4
    80006324:	68a8                	ld	a0,80(s1)
    80006326:	ffffb097          	auipc	ra,0xffffb
    8000632a:	318080e7          	jalr	792(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000632e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006330:	06055563          	bgez	a0,8000639a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006334:	fc442783          	lw	a5,-60(s0)
    80006338:	07e9                	addi	a5,a5,26
    8000633a:	078e                	slli	a5,a5,0x3
    8000633c:	97a6                	add	a5,a5,s1
    8000633e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006342:	fc042503          	lw	a0,-64(s0)
    80006346:	0569                	addi	a0,a0,26
    80006348:	050e                	slli	a0,a0,0x3
    8000634a:	9526                	add	a0,a0,s1
    8000634c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006350:	fd043503          	ld	a0,-48(s0)
    80006354:	fffff097          	auipc	ra,0xfffff
    80006358:	818080e7          	jalr	-2024(ra) # 80004b6c <fileclose>
    fileclose(wf);
    8000635c:	fc843503          	ld	a0,-56(s0)
    80006360:	fffff097          	auipc	ra,0xfffff
    80006364:	80c080e7          	jalr	-2036(ra) # 80004b6c <fileclose>
    return -1;
    80006368:	57fd                	li	a5,-1
    8000636a:	a805                	j	8000639a <sys_pipe+0x104>
    if(fd0 >= 0)
    8000636c:	fc442783          	lw	a5,-60(s0)
    80006370:	0007c863          	bltz	a5,80006380 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006374:	01a78513          	addi	a0,a5,26
    80006378:	050e                	slli	a0,a0,0x3
    8000637a:	9526                	add	a0,a0,s1
    8000637c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006380:	fd043503          	ld	a0,-48(s0)
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	7e8080e7          	jalr	2024(ra) # 80004b6c <fileclose>
    fileclose(wf);
    8000638c:	fc843503          	ld	a0,-56(s0)
    80006390:	ffffe097          	auipc	ra,0xffffe
    80006394:	7dc080e7          	jalr	2012(ra) # 80004b6c <fileclose>
    return -1;
    80006398:	57fd                	li	a5,-1
}
    8000639a:	853e                	mv	a0,a5
    8000639c:	70e2                	ld	ra,56(sp)
    8000639e:	7442                	ld	s0,48(sp)
    800063a0:	74a2                	ld	s1,40(sp)
    800063a2:	6121                	addi	sp,sp,64
    800063a4:	8082                	ret
	...

00000000800063b0 <kernelvec>:
    800063b0:	7111                	addi	sp,sp,-256
    800063b2:	e006                	sd	ra,0(sp)
    800063b4:	e40a                	sd	sp,8(sp)
    800063b6:	e80e                	sd	gp,16(sp)
    800063b8:	ec12                	sd	tp,24(sp)
    800063ba:	f016                	sd	t0,32(sp)
    800063bc:	f41a                	sd	t1,40(sp)
    800063be:	f81e                	sd	t2,48(sp)
    800063c0:	fc22                	sd	s0,56(sp)
    800063c2:	e0a6                	sd	s1,64(sp)
    800063c4:	e4aa                	sd	a0,72(sp)
    800063c6:	e8ae                	sd	a1,80(sp)
    800063c8:	ecb2                	sd	a2,88(sp)
    800063ca:	f0b6                	sd	a3,96(sp)
    800063cc:	f4ba                	sd	a4,104(sp)
    800063ce:	f8be                	sd	a5,112(sp)
    800063d0:	fcc2                	sd	a6,120(sp)
    800063d2:	e146                	sd	a7,128(sp)
    800063d4:	e54a                	sd	s2,136(sp)
    800063d6:	e94e                	sd	s3,144(sp)
    800063d8:	ed52                	sd	s4,152(sp)
    800063da:	f156                	sd	s5,160(sp)
    800063dc:	f55a                	sd	s6,168(sp)
    800063de:	f95e                	sd	s7,176(sp)
    800063e0:	fd62                	sd	s8,184(sp)
    800063e2:	e1e6                	sd	s9,192(sp)
    800063e4:	e5ea                	sd	s10,200(sp)
    800063e6:	e9ee                	sd	s11,208(sp)
    800063e8:	edf2                	sd	t3,216(sp)
    800063ea:	f1f6                	sd	t4,224(sp)
    800063ec:	f5fa                	sd	t5,232(sp)
    800063ee:	f9fe                	sd	t6,240(sp)
    800063f0:	889fc0ef          	jal	ra,80002c78 <kerneltrap>
    800063f4:	6082                	ld	ra,0(sp)
    800063f6:	6122                	ld	sp,8(sp)
    800063f8:	61c2                	ld	gp,16(sp)
    800063fa:	7282                	ld	t0,32(sp)
    800063fc:	7322                	ld	t1,40(sp)
    800063fe:	73c2                	ld	t2,48(sp)
    80006400:	7462                	ld	s0,56(sp)
    80006402:	6486                	ld	s1,64(sp)
    80006404:	6526                	ld	a0,72(sp)
    80006406:	65c6                	ld	a1,80(sp)
    80006408:	6666                	ld	a2,88(sp)
    8000640a:	7686                	ld	a3,96(sp)
    8000640c:	7726                	ld	a4,104(sp)
    8000640e:	77c6                	ld	a5,112(sp)
    80006410:	7866                	ld	a6,120(sp)
    80006412:	688a                	ld	a7,128(sp)
    80006414:	692a                	ld	s2,136(sp)
    80006416:	69ca                	ld	s3,144(sp)
    80006418:	6a6a                	ld	s4,152(sp)
    8000641a:	7a8a                	ld	s5,160(sp)
    8000641c:	7b2a                	ld	s6,168(sp)
    8000641e:	7bca                	ld	s7,176(sp)
    80006420:	7c6a                	ld	s8,184(sp)
    80006422:	6c8e                	ld	s9,192(sp)
    80006424:	6d2e                	ld	s10,200(sp)
    80006426:	6dce                	ld	s11,208(sp)
    80006428:	6e6e                	ld	t3,216(sp)
    8000642a:	7e8e                	ld	t4,224(sp)
    8000642c:	7f2e                	ld	t5,232(sp)
    8000642e:	7fce                	ld	t6,240(sp)
    80006430:	6111                	addi	sp,sp,256
    80006432:	10200073          	sret
    80006436:	00000013          	nop
    8000643a:	00000013          	nop
    8000643e:	0001                	nop

0000000080006440 <timervec>:
    80006440:	34051573          	csrrw	a0,mscratch,a0
    80006444:	e10c                	sd	a1,0(a0)
    80006446:	e510                	sd	a2,8(a0)
    80006448:	e914                	sd	a3,16(a0)
    8000644a:	6d0c                	ld	a1,24(a0)
    8000644c:	7110                	ld	a2,32(a0)
    8000644e:	6194                	ld	a3,0(a1)
    80006450:	96b2                	add	a3,a3,a2
    80006452:	e194                	sd	a3,0(a1)
    80006454:	4589                	li	a1,2
    80006456:	14459073          	csrw	sip,a1
    8000645a:	6914                	ld	a3,16(a0)
    8000645c:	6510                	ld	a2,8(a0)
    8000645e:	610c                	ld	a1,0(a0)
    80006460:	34051573          	csrrw	a0,mscratch,a0
    80006464:	30200073          	mret
	...

000000008000646a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000646a:	1141                	addi	sp,sp,-16
    8000646c:	e422                	sd	s0,8(sp)
    8000646e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006470:	0c0007b7          	lui	a5,0xc000
    80006474:	4705                	li	a4,1
    80006476:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006478:	c3d8                	sw	a4,4(a5)
}
    8000647a:	6422                	ld	s0,8(sp)
    8000647c:	0141                	addi	sp,sp,16
    8000647e:	8082                	ret

0000000080006480 <plicinithart>:

void
plicinithart(void)
{
    80006480:	1141                	addi	sp,sp,-16
    80006482:	e406                	sd	ra,8(sp)
    80006484:	e022                	sd	s0,0(sp)
    80006486:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006488:	ffffb097          	auipc	ra,0xffffb
    8000648c:	760080e7          	jalr	1888(ra) # 80001be8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006490:	0085171b          	slliw	a4,a0,0x8
    80006494:	0c0027b7          	lui	a5,0xc002
    80006498:	97ba                	add	a5,a5,a4
    8000649a:	40200713          	li	a4,1026
    8000649e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800064a2:	00d5151b          	slliw	a0,a0,0xd
    800064a6:	0c2017b7          	lui	a5,0xc201
    800064aa:	953e                	add	a0,a0,a5
    800064ac:	00052023          	sw	zero,0(a0)
}
    800064b0:	60a2                	ld	ra,8(sp)
    800064b2:	6402                	ld	s0,0(sp)
    800064b4:	0141                	addi	sp,sp,16
    800064b6:	8082                	ret

00000000800064b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800064b8:	1141                	addi	sp,sp,-16
    800064ba:	e406                	sd	ra,8(sp)
    800064bc:	e022                	sd	s0,0(sp)
    800064be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800064c0:	ffffb097          	auipc	ra,0xffffb
    800064c4:	728080e7          	jalr	1832(ra) # 80001be8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800064c8:	00d5179b          	slliw	a5,a0,0xd
    800064cc:	0c201537          	lui	a0,0xc201
    800064d0:	953e                	add	a0,a0,a5
  return irq;
}
    800064d2:	4148                	lw	a0,4(a0)
    800064d4:	60a2                	ld	ra,8(sp)
    800064d6:	6402                	ld	s0,0(sp)
    800064d8:	0141                	addi	sp,sp,16
    800064da:	8082                	ret

00000000800064dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800064dc:	1101                	addi	sp,sp,-32
    800064de:	ec06                	sd	ra,24(sp)
    800064e0:	e822                	sd	s0,16(sp)
    800064e2:	e426                	sd	s1,8(sp)
    800064e4:	1000                	addi	s0,sp,32
    800064e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800064e8:	ffffb097          	auipc	ra,0xffffb
    800064ec:	700080e7          	jalr	1792(ra) # 80001be8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800064f0:	00d5151b          	slliw	a0,a0,0xd
    800064f4:	0c2017b7          	lui	a5,0xc201
    800064f8:	97aa                	add	a5,a5,a0
    800064fa:	c3c4                	sw	s1,4(a5)
}
    800064fc:	60e2                	ld	ra,24(sp)
    800064fe:	6442                	ld	s0,16(sp)
    80006500:	64a2                	ld	s1,8(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret

0000000080006506 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006506:	1141                	addi	sp,sp,-16
    80006508:	e406                	sd	ra,8(sp)
    8000650a:	e022                	sd	s0,0(sp)
    8000650c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000650e:	479d                	li	a5,7
    80006510:	06a7c963          	blt	a5,a0,80006582 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006514:	00023797          	auipc	a5,0x23
    80006518:	aec78793          	addi	a5,a5,-1300 # 80029000 <disk>
    8000651c:	00a78733          	add	a4,a5,a0
    80006520:	6789                	lui	a5,0x2
    80006522:	97ba                	add	a5,a5,a4
    80006524:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006528:	e7ad                	bnez	a5,80006592 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000652a:	00451793          	slli	a5,a0,0x4
    8000652e:	00025717          	auipc	a4,0x25
    80006532:	ad270713          	addi	a4,a4,-1326 # 8002b000 <disk+0x2000>
    80006536:	6314                	ld	a3,0(a4)
    80006538:	96be                	add	a3,a3,a5
    8000653a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000653e:	6314                	ld	a3,0(a4)
    80006540:	96be                	add	a3,a3,a5
    80006542:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006546:	6314                	ld	a3,0(a4)
    80006548:	96be                	add	a3,a3,a5
    8000654a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000654e:	6318                	ld	a4,0(a4)
    80006550:	97ba                	add	a5,a5,a4
    80006552:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006556:	00023797          	auipc	a5,0x23
    8000655a:	aaa78793          	addi	a5,a5,-1366 # 80029000 <disk>
    8000655e:	97aa                	add	a5,a5,a0
    80006560:	6509                	lui	a0,0x2
    80006562:	953e                	add	a0,a0,a5
    80006564:	4785                	li	a5,1
    80006566:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000656a:	00025517          	auipc	a0,0x25
    8000656e:	aae50513          	addi	a0,a0,-1362 # 8002b018 <disk+0x2018>
    80006572:	ffffc097          	auipc	ra,0xffffc
    80006576:	06e080e7          	jalr	110(ra) # 800025e0 <wakeup>
}
    8000657a:	60a2                	ld	ra,8(sp)
    8000657c:	6402                	ld	s0,0(sp)
    8000657e:	0141                	addi	sp,sp,16
    80006580:	8082                	ret
    panic("free_desc 1");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	2de50513          	addi	a0,a0,734 # 80008860 <syscalls+0x358>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	fa0080e7          	jalr	-96(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006592:	00002517          	auipc	a0,0x2
    80006596:	2de50513          	addi	a0,a0,734 # 80008870 <syscalls+0x368>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	f90080e7          	jalr	-112(ra) # 8000052a <panic>

00000000800065a2 <virtio_disk_init>:
{
    800065a2:	1101                	addi	sp,sp,-32
    800065a4:	ec06                	sd	ra,24(sp)
    800065a6:	e822                	sd	s0,16(sp)
    800065a8:	e426                	sd	s1,8(sp)
    800065aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800065ac:	00002597          	auipc	a1,0x2
    800065b0:	2d458593          	addi	a1,a1,724 # 80008880 <syscalls+0x378>
    800065b4:	00025517          	auipc	a0,0x25
    800065b8:	b7450513          	addi	a0,a0,-1164 # 8002b128 <disk+0x2128>
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	576080e7          	jalr	1398(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065c4:	100017b7          	lui	a5,0x10001
    800065c8:	4398                	lw	a4,0(a5)
    800065ca:	2701                	sext.w	a4,a4
    800065cc:	747277b7          	lui	a5,0x74727
    800065d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800065d4:	0ef71163          	bne	a4,a5,800066b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065d8:	100017b7          	lui	a5,0x10001
    800065dc:	43dc                	lw	a5,4(a5)
    800065de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800065e0:	4705                	li	a4,1
    800065e2:	0ce79a63          	bne	a5,a4,800066b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065e6:	100017b7          	lui	a5,0x10001
    800065ea:	479c                	lw	a5,8(a5)
    800065ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800065ee:	4709                	li	a4,2
    800065f0:	0ce79363          	bne	a5,a4,800066b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800065f4:	100017b7          	lui	a5,0x10001
    800065f8:	47d8                	lw	a4,12(a5)
    800065fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800065fc:	554d47b7          	lui	a5,0x554d4
    80006600:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006604:	0af71963          	bne	a4,a5,800066b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006608:	100017b7          	lui	a5,0x10001
    8000660c:	4705                	li	a4,1
    8000660e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006610:	470d                	li	a4,3
    80006612:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006614:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006616:	c7ffe737          	lui	a4,0xc7ffe
    8000661a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd275f>
    8000661e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006620:	2701                	sext.w	a4,a4
    80006622:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006624:	472d                	li	a4,11
    80006626:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006628:	473d                	li	a4,15
    8000662a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000662c:	6705                	lui	a4,0x1
    8000662e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006630:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006634:	5bdc                	lw	a5,52(a5)
    80006636:	2781                	sext.w	a5,a5
  if(max == 0)
    80006638:	c7d9                	beqz	a5,800066c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000663a:	471d                	li	a4,7
    8000663c:	08f77d63          	bgeu	a4,a5,800066d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006640:	100014b7          	lui	s1,0x10001
    80006644:	47a1                	li	a5,8
    80006646:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006648:	6609                	lui	a2,0x2
    8000664a:	4581                	li	a1,0
    8000664c:	00023517          	auipc	a0,0x23
    80006650:	9b450513          	addi	a0,a0,-1612 # 80029000 <disk>
    80006654:	ffffa097          	auipc	ra,0xffffa
    80006658:	66a080e7          	jalr	1642(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000665c:	00023717          	auipc	a4,0x23
    80006660:	9a470713          	addi	a4,a4,-1628 # 80029000 <disk>
    80006664:	00c75793          	srli	a5,a4,0xc
    80006668:	2781                	sext.w	a5,a5
    8000666a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000666c:	00025797          	auipc	a5,0x25
    80006670:	99478793          	addi	a5,a5,-1644 # 8002b000 <disk+0x2000>
    80006674:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006676:	00023717          	auipc	a4,0x23
    8000667a:	a0a70713          	addi	a4,a4,-1526 # 80029080 <disk+0x80>
    8000667e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006680:	00024717          	auipc	a4,0x24
    80006684:	98070713          	addi	a4,a4,-1664 # 8002a000 <disk+0x1000>
    80006688:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000668a:	4705                	li	a4,1
    8000668c:	00e78c23          	sb	a4,24(a5)
    80006690:	00e78ca3          	sb	a4,25(a5)
    80006694:	00e78d23          	sb	a4,26(a5)
    80006698:	00e78da3          	sb	a4,27(a5)
    8000669c:	00e78e23          	sb	a4,28(a5)
    800066a0:	00e78ea3          	sb	a4,29(a5)
    800066a4:	00e78f23          	sb	a4,30(a5)
    800066a8:	00e78fa3          	sb	a4,31(a5)
}
    800066ac:	60e2                	ld	ra,24(sp)
    800066ae:	6442                	ld	s0,16(sp)
    800066b0:	64a2                	ld	s1,8(sp)
    800066b2:	6105                	addi	sp,sp,32
    800066b4:	8082                	ret
    panic("could not find virtio disk");
    800066b6:	00002517          	auipc	a0,0x2
    800066ba:	1da50513          	addi	a0,a0,474 # 80008890 <syscalls+0x388>
    800066be:	ffffa097          	auipc	ra,0xffffa
    800066c2:	e6c080e7          	jalr	-404(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800066c6:	00002517          	auipc	a0,0x2
    800066ca:	1ea50513          	addi	a0,a0,490 # 800088b0 <syscalls+0x3a8>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	e5c080e7          	jalr	-420(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	1fa50513          	addi	a0,a0,506 # 800088d0 <syscalls+0x3c8>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e4c080e7          	jalr	-436(ra) # 8000052a <panic>

00000000800066e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800066e6:	7119                	addi	sp,sp,-128
    800066e8:	fc86                	sd	ra,120(sp)
    800066ea:	f8a2                	sd	s0,112(sp)
    800066ec:	f4a6                	sd	s1,104(sp)
    800066ee:	f0ca                	sd	s2,96(sp)
    800066f0:	ecce                	sd	s3,88(sp)
    800066f2:	e8d2                	sd	s4,80(sp)
    800066f4:	e4d6                	sd	s5,72(sp)
    800066f6:	e0da                	sd	s6,64(sp)
    800066f8:	fc5e                	sd	s7,56(sp)
    800066fa:	f862                	sd	s8,48(sp)
    800066fc:	f466                	sd	s9,40(sp)
    800066fe:	f06a                	sd	s10,32(sp)
    80006700:	ec6e                	sd	s11,24(sp)
    80006702:	0100                	addi	s0,sp,128
    80006704:	8aaa                	mv	s5,a0
    80006706:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006708:	00c52c83          	lw	s9,12(a0)
    8000670c:	001c9c9b          	slliw	s9,s9,0x1
    80006710:	1c82                	slli	s9,s9,0x20
    80006712:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006716:	00025517          	auipc	a0,0x25
    8000671a:	a1250513          	addi	a0,a0,-1518 # 8002b128 <disk+0x2128>
    8000671e:	ffffa097          	auipc	ra,0xffffa
    80006722:	4a4080e7          	jalr	1188(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006726:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006728:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000672a:	00023c17          	auipc	s8,0x23
    8000672e:	8d6c0c13          	addi	s8,s8,-1834 # 80029000 <disk>
    80006732:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006734:	4b0d                	li	s6,3
    80006736:	a0ad                	j	800067a0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006738:	00fc0733          	add	a4,s8,a5
    8000673c:	975e                	add	a4,a4,s7
    8000673e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006742:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006744:	0207c563          	bltz	a5,8000676e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006748:	2905                	addiw	s2,s2,1
    8000674a:	0611                	addi	a2,a2,4
    8000674c:	19690d63          	beq	s2,s6,800068e6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006750:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006752:	00025717          	auipc	a4,0x25
    80006756:	8c670713          	addi	a4,a4,-1850 # 8002b018 <disk+0x2018>
    8000675a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000675c:	00074683          	lbu	a3,0(a4)
    80006760:	fee1                	bnez	a3,80006738 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006762:	2785                	addiw	a5,a5,1
    80006764:	0705                	addi	a4,a4,1
    80006766:	fe979be3          	bne	a5,s1,8000675c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000676a:	57fd                	li	a5,-1
    8000676c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000676e:	01205d63          	blez	s2,80006788 <virtio_disk_rw+0xa2>
    80006772:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006774:	000a2503          	lw	a0,0(s4)
    80006778:	00000097          	auipc	ra,0x0
    8000677c:	d8e080e7          	jalr	-626(ra) # 80006506 <free_desc>
      for(int j = 0; j < i; j++)
    80006780:	2d85                	addiw	s11,s11,1
    80006782:	0a11                	addi	s4,s4,4
    80006784:	ffb918e3          	bne	s2,s11,80006774 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006788:	00025597          	auipc	a1,0x25
    8000678c:	9a058593          	addi	a1,a1,-1632 # 8002b128 <disk+0x2128>
    80006790:	00025517          	auipc	a0,0x25
    80006794:	88850513          	addi	a0,a0,-1912 # 8002b018 <disk+0x2018>
    80006798:	ffffc097          	auipc	ra,0xffffc
    8000679c:	cbc080e7          	jalr	-836(ra) # 80002454 <sleep>
  for(int i = 0; i < 3; i++){
    800067a0:	f8040a13          	addi	s4,s0,-128
{
    800067a4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800067a6:	894e                	mv	s2,s3
    800067a8:	b765                	j	80006750 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800067aa:	00025697          	auipc	a3,0x25
    800067ae:	8566b683          	ld	a3,-1962(a3) # 8002b000 <disk+0x2000>
    800067b2:	96ba                	add	a3,a3,a4
    800067b4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800067b8:	00023817          	auipc	a6,0x23
    800067bc:	84880813          	addi	a6,a6,-1976 # 80029000 <disk>
    800067c0:	00025697          	auipc	a3,0x25
    800067c4:	84068693          	addi	a3,a3,-1984 # 8002b000 <disk+0x2000>
    800067c8:	6290                	ld	a2,0(a3)
    800067ca:	963a                	add	a2,a2,a4
    800067cc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800067d0:	0015e593          	ori	a1,a1,1
    800067d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800067d8:	f8842603          	lw	a2,-120(s0)
    800067dc:	628c                	ld	a1,0(a3)
    800067de:	972e                	add	a4,a4,a1
    800067e0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067e4:	20050593          	addi	a1,a0,512
    800067e8:	0592                	slli	a1,a1,0x4
    800067ea:	95c2                	add	a1,a1,a6
    800067ec:	577d                	li	a4,-1
    800067ee:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067f2:	00461713          	slli	a4,a2,0x4
    800067f6:	6290                	ld	a2,0(a3)
    800067f8:	963a                	add	a2,a2,a4
    800067fa:	03078793          	addi	a5,a5,48
    800067fe:	97c2                	add	a5,a5,a6
    80006800:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006802:	629c                	ld	a5,0(a3)
    80006804:	97ba                	add	a5,a5,a4
    80006806:	4605                	li	a2,1
    80006808:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000680a:	629c                	ld	a5,0(a3)
    8000680c:	97ba                	add	a5,a5,a4
    8000680e:	4809                	li	a6,2
    80006810:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006814:	629c                	ld	a5,0(a3)
    80006816:	973e                	add	a4,a4,a5
    80006818:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000681c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006820:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006824:	6698                	ld	a4,8(a3)
    80006826:	00275783          	lhu	a5,2(a4)
    8000682a:	8b9d                	andi	a5,a5,7
    8000682c:	0786                	slli	a5,a5,0x1
    8000682e:	97ba                	add	a5,a5,a4
    80006830:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006834:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006838:	6698                	ld	a4,8(a3)
    8000683a:	00275783          	lhu	a5,2(a4)
    8000683e:	2785                	addiw	a5,a5,1
    80006840:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006844:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006848:	100017b7          	lui	a5,0x10001
    8000684c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006850:	004aa783          	lw	a5,4(s5)
    80006854:	02c79163          	bne	a5,a2,80006876 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006858:	00025917          	auipc	s2,0x25
    8000685c:	8d090913          	addi	s2,s2,-1840 # 8002b128 <disk+0x2128>
  while(b->disk == 1) {
    80006860:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006862:	85ca                	mv	a1,s2
    80006864:	8556                	mv	a0,s5
    80006866:	ffffc097          	auipc	ra,0xffffc
    8000686a:	bee080e7          	jalr	-1042(ra) # 80002454 <sleep>
  while(b->disk == 1) {
    8000686e:	004aa783          	lw	a5,4(s5)
    80006872:	fe9788e3          	beq	a5,s1,80006862 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006876:	f8042903          	lw	s2,-128(s0)
    8000687a:	20090793          	addi	a5,s2,512
    8000687e:	00479713          	slli	a4,a5,0x4
    80006882:	00022797          	auipc	a5,0x22
    80006886:	77e78793          	addi	a5,a5,1918 # 80029000 <disk>
    8000688a:	97ba                	add	a5,a5,a4
    8000688c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006890:	00024997          	auipc	s3,0x24
    80006894:	77098993          	addi	s3,s3,1904 # 8002b000 <disk+0x2000>
    80006898:	00491713          	slli	a4,s2,0x4
    8000689c:	0009b783          	ld	a5,0(s3)
    800068a0:	97ba                	add	a5,a5,a4
    800068a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800068a6:	854a                	mv	a0,s2
    800068a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800068ac:	00000097          	auipc	ra,0x0
    800068b0:	c5a080e7          	jalr	-934(ra) # 80006506 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800068b4:	8885                	andi	s1,s1,1
    800068b6:	f0ed                	bnez	s1,80006898 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800068b8:	00025517          	auipc	a0,0x25
    800068bc:	87050513          	addi	a0,a0,-1936 # 8002b128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	3b6080e7          	jalr	950(ra) # 80000c76 <release>
}
    800068c8:	70e6                	ld	ra,120(sp)
    800068ca:	7446                	ld	s0,112(sp)
    800068cc:	74a6                	ld	s1,104(sp)
    800068ce:	7906                	ld	s2,96(sp)
    800068d0:	69e6                	ld	s3,88(sp)
    800068d2:	6a46                	ld	s4,80(sp)
    800068d4:	6aa6                	ld	s5,72(sp)
    800068d6:	6b06                	ld	s6,64(sp)
    800068d8:	7be2                	ld	s7,56(sp)
    800068da:	7c42                	ld	s8,48(sp)
    800068dc:	7ca2                	ld	s9,40(sp)
    800068de:	7d02                	ld	s10,32(sp)
    800068e0:	6de2                	ld	s11,24(sp)
    800068e2:	6109                	addi	sp,sp,128
    800068e4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068e6:	f8042503          	lw	a0,-128(s0)
    800068ea:	20050793          	addi	a5,a0,512
    800068ee:	0792                	slli	a5,a5,0x4
  if(write)
    800068f0:	00022817          	auipc	a6,0x22
    800068f4:	71080813          	addi	a6,a6,1808 # 80029000 <disk>
    800068f8:	00f80733          	add	a4,a6,a5
    800068fc:	01a036b3          	snez	a3,s10
    80006900:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006904:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006908:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000690c:	7679                	lui	a2,0xffffe
    8000690e:	963e                	add	a2,a2,a5
    80006910:	00024697          	auipc	a3,0x24
    80006914:	6f068693          	addi	a3,a3,1776 # 8002b000 <disk+0x2000>
    80006918:	6298                	ld	a4,0(a3)
    8000691a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000691c:	0a878593          	addi	a1,a5,168
    80006920:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006922:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006924:	6298                	ld	a4,0(a3)
    80006926:	9732                	add	a4,a4,a2
    80006928:	45c1                	li	a1,16
    8000692a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000692c:	6298                	ld	a4,0(a3)
    8000692e:	9732                	add	a4,a4,a2
    80006930:	4585                	li	a1,1
    80006932:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006936:	f8442703          	lw	a4,-124(s0)
    8000693a:	628c                	ld	a1,0(a3)
    8000693c:	962e                	add	a2,a2,a1
    8000693e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd200e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006942:	0712                	slli	a4,a4,0x4
    80006944:	6290                	ld	a2,0(a3)
    80006946:	963a                	add	a2,a2,a4
    80006948:	058a8593          	addi	a1,s5,88
    8000694c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000694e:	6294                	ld	a3,0(a3)
    80006950:	96ba                	add	a3,a3,a4
    80006952:	40000613          	li	a2,1024
    80006956:	c690                	sw	a2,8(a3)
  if(write)
    80006958:	e40d19e3          	bnez	s10,800067aa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000695c:	00024697          	auipc	a3,0x24
    80006960:	6a46b683          	ld	a3,1700(a3) # 8002b000 <disk+0x2000>
    80006964:	96ba                	add	a3,a3,a4
    80006966:	4609                	li	a2,2
    80006968:	00c69623          	sh	a2,12(a3)
    8000696c:	b5b1                	j	800067b8 <virtio_disk_rw+0xd2>

000000008000696e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000696e:	1101                	addi	sp,sp,-32
    80006970:	ec06                	sd	ra,24(sp)
    80006972:	e822                	sd	s0,16(sp)
    80006974:	e426                	sd	s1,8(sp)
    80006976:	e04a                	sd	s2,0(sp)
    80006978:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000697a:	00024517          	auipc	a0,0x24
    8000697e:	7ae50513          	addi	a0,a0,1966 # 8002b128 <disk+0x2128>
    80006982:	ffffa097          	auipc	ra,0xffffa
    80006986:	240080e7          	jalr	576(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000698a:	10001737          	lui	a4,0x10001
    8000698e:	533c                	lw	a5,96(a4)
    80006990:	8b8d                	andi	a5,a5,3
    80006992:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006994:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006998:	00024797          	auipc	a5,0x24
    8000699c:	66878793          	addi	a5,a5,1640 # 8002b000 <disk+0x2000>
    800069a0:	6b94                	ld	a3,16(a5)
    800069a2:	0207d703          	lhu	a4,32(a5)
    800069a6:	0026d783          	lhu	a5,2(a3)
    800069aa:	06f70163          	beq	a4,a5,80006a0c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069ae:	00022917          	auipc	s2,0x22
    800069b2:	65290913          	addi	s2,s2,1618 # 80029000 <disk>
    800069b6:	00024497          	auipc	s1,0x24
    800069ba:	64a48493          	addi	s1,s1,1610 # 8002b000 <disk+0x2000>
    __sync_synchronize();
    800069be:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800069c2:	6898                	ld	a4,16(s1)
    800069c4:	0204d783          	lhu	a5,32(s1)
    800069c8:	8b9d                	andi	a5,a5,7
    800069ca:	078e                	slli	a5,a5,0x3
    800069cc:	97ba                	add	a5,a5,a4
    800069ce:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800069d0:	20078713          	addi	a4,a5,512
    800069d4:	0712                	slli	a4,a4,0x4
    800069d6:	974a                	add	a4,a4,s2
    800069d8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800069dc:	e731                	bnez	a4,80006a28 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800069de:	20078793          	addi	a5,a5,512
    800069e2:	0792                	slli	a5,a5,0x4
    800069e4:	97ca                	add	a5,a5,s2
    800069e6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800069e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800069ec:	ffffc097          	auipc	ra,0xffffc
    800069f0:	bf4080e7          	jalr	-1036(ra) # 800025e0 <wakeup>

    disk.used_idx += 1;
    800069f4:	0204d783          	lhu	a5,32(s1)
    800069f8:	2785                	addiw	a5,a5,1
    800069fa:	17c2                	slli	a5,a5,0x30
    800069fc:	93c1                	srli	a5,a5,0x30
    800069fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006a02:	6898                	ld	a4,16(s1)
    80006a04:	00275703          	lhu	a4,2(a4)
    80006a08:	faf71be3          	bne	a4,a5,800069be <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006a0c:	00024517          	auipc	a0,0x24
    80006a10:	71c50513          	addi	a0,a0,1820 # 8002b128 <disk+0x2128>
    80006a14:	ffffa097          	auipc	ra,0xffffa
    80006a18:	262080e7          	jalr	610(ra) # 80000c76 <release>
}
    80006a1c:	60e2                	ld	ra,24(sp)
    80006a1e:	6442                	ld	s0,16(sp)
    80006a20:	64a2                	ld	s1,8(sp)
    80006a22:	6902                	ld	s2,0(sp)
    80006a24:	6105                	addi	sp,sp,32
    80006a26:	8082                	ret
      panic("virtio_disk_intr status");
    80006a28:	00002517          	auipc	a0,0x2
    80006a2c:	ec850513          	addi	a0,a0,-312 # 800088f0 <syscalls+0x3e8>
    80006a30:	ffffa097          	auipc	ra,0xffffa
    80006a34:	afa080e7          	jalr	-1286(ra) # 8000052a <panic>
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
