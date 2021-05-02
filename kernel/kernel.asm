
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	18010113          	addi	sp,sp,384 # 8000a180 <stack0>
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
    80000052:	0000a717          	auipc	a4,0xa
    80000056:	fee70713          	addi	a4,a4,-18 # 8000a040 <timer_scratch>
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
    80000068:	cdc78793          	addi	a5,a5,-804 # 80006d40 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcf7ff>
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
    80000122:	01a080e7          	jalr	26(ra) # 80003138 <either_copyin>
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
    8000017c:	00012517          	auipc	a0,0x12
    80000180:	00450513          	addi	a0,a0,4 # 80012180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	a4e080e7          	jalr	-1458(ra) # 80000bd2 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018c:	00012497          	auipc	s1,0x12
    80000190:	ff448493          	addi	s1,s1,-12 # 80012180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000194:	00012917          	auipc	s2,0x12
    80000198:	08490913          	addi	s2,s2,132 # 80012218 <cons+0x98>
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
    800001b6:	250080e7          	jalr	592(ra) # 80002402 <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00003097          	auipc	ra,0x3
    800001c6:	b66080e7          	jalr	-1178(ra) # 80002d28 <sleep>
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
    80000202:	ee4080e7          	jalr	-284(ra) # 800030e2 <either_copyout>
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
    80000212:	00012517          	auipc	a0,0x12
    80000216:	f6e50513          	addi	a0,a0,-146 # 80012180 <cons>
    8000021a:	00001097          	auipc	ra,0x1
    8000021e:	a6c080e7          	jalr	-1428(ra) # 80000c86 <release>

  return target - n;
    80000222:	413b053b          	subw	a0,s6,s3
    80000226:	a811                	j	8000023a <consoleread+0xe4>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	f5850513          	addi	a0,a0,-168 # 80012180 <cons>
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
    8000025e:	00012717          	auipc	a4,0x12
    80000262:	faf72d23          	sw	a5,-70(a4) # 80012218 <cons+0x98>
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
    800002b8:	00012517          	auipc	a0,0x12
    800002bc:	ec850513          	addi	a0,a0,-312 # 80012180 <cons>
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
    800002e2:	eb0080e7          	jalr	-336(ra) # 8000318e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002e6:	00012517          	auipc	a0,0x12
    800002ea:	e9a50513          	addi	a0,a0,-358 # 80012180 <cons>
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
    8000030a:	00012717          	auipc	a4,0x12
    8000030e:	e7670713          	addi	a4,a4,-394 # 80012180 <cons>
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
    80000334:	00012797          	auipc	a5,0x12
    80000338:	e4c78793          	addi	a5,a5,-436 # 80012180 <cons>
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
    80000362:	00012797          	auipc	a5,0x12
    80000366:	eb67a783          	lw	a5,-330(a5) # 80012218 <cons+0x98>
    8000036a:	0807879b          	addiw	a5,a5,128
    8000036e:	f6f61ce3          	bne	a2,a5,800002e6 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000372:	863e                	mv	a2,a5
    80000374:	a07d                	j	80000422 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000376:	00012717          	auipc	a4,0x12
    8000037a:	e0a70713          	addi	a4,a4,-502 # 80012180 <cons>
    8000037e:	0a072783          	lw	a5,160(a4)
    80000382:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000386:	00012497          	auipc	s1,0x12
    8000038a:	dfa48493          	addi	s1,s1,-518 # 80012180 <cons>
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
    800003c2:	00012717          	auipc	a4,0x12
    800003c6:	dbe70713          	addi	a4,a4,-578 # 80012180 <cons>
    800003ca:	0a072783          	lw	a5,160(a4)
    800003ce:	09c72703          	lw	a4,156(a4)
    800003d2:	f0f70ae3          	beq	a4,a5,800002e6 <consoleintr+0x3c>
      cons.e--;
    800003d6:	37fd                	addiw	a5,a5,-1
    800003d8:	00012717          	auipc	a4,0x12
    800003dc:	e4f72423          	sw	a5,-440(a4) # 80012220 <cons+0xa0>
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
    800003fe:	00012797          	auipc	a5,0x12
    80000402:	d8278793          	addi	a5,a5,-638 # 80012180 <cons>
    80000406:	0a07a703          	lw	a4,160(a5)
    8000040a:	0017069b          	addiw	a3,a4,1
    8000040e:	0006861b          	sext.w	a2,a3
    80000412:	0ad7a023          	sw	a3,160(a5)
    80000416:	07f77713          	andi	a4,a4,127
    8000041a:	97ba                	add	a5,a5,a4
    8000041c:	4729                	li	a4,10
    8000041e:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000422:	00012797          	auipc	a5,0x12
    80000426:	dec7ad23          	sw	a2,-518(a5) # 8001221c <cons+0x9c>
        wakeup(&cons.r);
    8000042a:	00012517          	auipc	a0,0x12
    8000042e:	dee50513          	addi	a0,a0,-530 # 80012218 <cons+0x98>
    80000432:	00003097          	auipc	ra,0x3
    80000436:	a82080e7          	jalr	-1406(ra) # 80002eb4 <wakeup>
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
    80000444:	00009597          	auipc	a1,0x9
    80000448:	bcc58593          	addi	a1,a1,-1076 # 80009010 <etext+0x10>
    8000044c:	00012517          	auipc	a0,0x12
    80000450:	d3450513          	addi	a0,a0,-716 # 80012180 <cons>
    80000454:	00000097          	auipc	ra,0x0
    80000458:	6ee080e7          	jalr	1774(ra) # 80000b42 <initlock>

  uartinit();
    8000045c:	00000097          	auipc	ra,0x0
    80000460:	32a080e7          	jalr	810(ra) # 80000786 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000464:	0002a797          	auipc	a5,0x2a
    80000468:	4b478793          	addi	a5,a5,1204 # 8002a918 <devsw>
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
    800004a6:	00009617          	auipc	a2,0x9
    800004aa:	b9a60613          	addi	a2,a2,-1126 # 80009040 <digits>
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
    80000536:	00012797          	auipc	a5,0x12
    8000053a:	d007a523          	sw	zero,-758(a5) # 80012240 <pr+0x18>
  printf("panic: ");
    8000053e:	00009517          	auipc	a0,0x9
    80000542:	ada50513          	addi	a0,a0,-1318 # 80009018 <etext+0x18>
    80000546:	00000097          	auipc	ra,0x0
    8000054a:	02e080e7          	jalr	46(ra) # 80000574 <printf>
  printf(s);
    8000054e:	8526                	mv	a0,s1
    80000550:	00000097          	auipc	ra,0x0
    80000554:	024080e7          	jalr	36(ra) # 80000574 <printf>
  printf("\n");
    80000558:	00009517          	auipc	a0,0x9
    8000055c:	e0850513          	addi	a0,a0,-504 # 80009360 <digits+0x320>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	014080e7          	jalr	20(ra) # 80000574 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000568:	4785                	li	a5,1
    8000056a:	0000a717          	auipc	a4,0xa
    8000056e:	a8f72b23          	sw	a5,-1386(a4) # 8000a000 <panicked>
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
    800005a6:	00012d97          	auipc	s11,0x12
    800005aa:	c9adad83          	lw	s11,-870(s11) # 80012240 <pr+0x18>
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
    800005d2:	00009b17          	auipc	s6,0x9
    800005d6:	a6eb0b13          	addi	s6,s6,-1426 # 80009040 <digits>
    switch(c){
    800005da:	07300c93          	li	s9,115
    800005de:	06400c13          	li	s8,100
    800005e2:	a82d                	j	8000061c <printf+0xa8>
    acquire(&pr.lock);
    800005e4:	00012517          	auipc	a0,0x12
    800005e8:	c4450513          	addi	a0,a0,-956 # 80012228 <pr>
    800005ec:	00000097          	auipc	ra,0x0
    800005f0:	5e6080e7          	jalr	1510(ra) # 80000bd2 <acquire>
    800005f4:	bf7d                	j	800005b2 <printf+0x3e>
    panic("null fmt");
    800005f6:	00009517          	auipc	a0,0x9
    800005fa:	a3250513          	addi	a0,a0,-1486 # 80009028 <etext+0x28>
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
    800006f0:	00009497          	auipc	s1,0x9
    800006f4:	93048493          	addi	s1,s1,-1744 # 80009020 <etext+0x20>
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
    80000742:	00012517          	auipc	a0,0x12
    80000746:	ae650513          	addi	a0,a0,-1306 # 80012228 <pr>
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
    8000075e:	00012497          	auipc	s1,0x12
    80000762:	aca48493          	addi	s1,s1,-1334 # 80012228 <pr>
    80000766:	00009597          	auipc	a1,0x9
    8000076a:	8d258593          	addi	a1,a1,-1838 # 80009038 <etext+0x38>
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
    800007b6:	00009597          	auipc	a1,0x9
    800007ba:	8a258593          	addi	a1,a1,-1886 # 80009058 <digits+0x18>
    800007be:	00012517          	auipc	a0,0x12
    800007c2:	a8a50513          	addi	a0,a0,-1398 # 80012248 <uart_tx_lock>
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
    800007ea:	0000a797          	auipc	a5,0xa
    800007ee:	8167a783          	lw	a5,-2026(a5) # 8000a000 <panicked>
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
    80000822:	00009797          	auipc	a5,0x9
    80000826:	7e67b783          	ld	a5,2022(a5) # 8000a008 <uart_tx_r>
    8000082a:	00009717          	auipc	a4,0x9
    8000082e:	7e673703          	ld	a4,2022(a4) # 8000a010 <uart_tx_w>
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
    8000084c:	00012a17          	auipc	s4,0x12
    80000850:	9fca0a13          	addi	s4,s4,-1540 # 80012248 <uart_tx_lock>
    uart_tx_r += 1;
    80000854:	00009497          	auipc	s1,0x9
    80000858:	7b448493          	addi	s1,s1,1972 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000085c:	00009997          	auipc	s3,0x9
    80000860:	7b498993          	addi	s3,s3,1972 # 8000a010 <uart_tx_w>
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
    80000882:	636080e7          	jalr	1590(ra) # 80002eb4 <wakeup>
    
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
    800008ba:	00012517          	auipc	a0,0x12
    800008be:	98e50513          	addi	a0,a0,-1650 # 80012248 <uart_tx_lock>
    800008c2:	00000097          	auipc	ra,0x0
    800008c6:	310080e7          	jalr	784(ra) # 80000bd2 <acquire>
  if(panicked){
    800008ca:	00009797          	auipc	a5,0x9
    800008ce:	7367a783          	lw	a5,1846(a5) # 8000a000 <panicked>
    800008d2:	c391                	beqz	a5,800008d6 <uartputc+0x2e>
    for(;;)
    800008d4:	a001                	j	800008d4 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008d6:	00009717          	auipc	a4,0x9
    800008da:	73a73703          	ld	a4,1850(a4) # 8000a010 <uart_tx_w>
    800008de:	00009797          	auipc	a5,0x9
    800008e2:	72a7b783          	ld	a5,1834(a5) # 8000a008 <uart_tx_r>
    800008e6:	02078793          	addi	a5,a5,32
    800008ea:	02e79b63          	bne	a5,a4,80000920 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    800008ee:	00012997          	auipc	s3,0x12
    800008f2:	95a98993          	addi	s3,s3,-1702 # 80012248 <uart_tx_lock>
    800008f6:	00009497          	auipc	s1,0x9
    800008fa:	71248493          	addi	s1,s1,1810 # 8000a008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fe:	00009917          	auipc	s2,0x9
    80000902:	71290913          	addi	s2,s2,1810 # 8000a010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000906:	85ce                	mv	a1,s3
    80000908:	8526                	mv	a0,s1
    8000090a:	00002097          	auipc	ra,0x2
    8000090e:	41e080e7          	jalr	1054(ra) # 80002d28 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00093703          	ld	a4,0(s2)
    80000916:	609c                	ld	a5,0(s1)
    80000918:	02078793          	addi	a5,a5,32
    8000091c:	fee785e3          	beq	a5,a4,80000906 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000920:	00012497          	auipc	s1,0x12
    80000924:	92848493          	addi	s1,s1,-1752 # 80012248 <uart_tx_lock>
    80000928:	01f77793          	andi	a5,a4,31
    8000092c:	97a6                	add	a5,a5,s1
    8000092e:	01478c23          	sb	s4,24(a5)
      uart_tx_w += 1;
    80000932:	0705                	addi	a4,a4,1
    80000934:	00009797          	auipc	a5,0x9
    80000938:	6ce7be23          	sd	a4,1756(a5) # 8000a010 <uart_tx_w>
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
    800009a8:	00012497          	auipc	s1,0x12
    800009ac:	8a048493          	addi	s1,s1,-1888 # 80012248 <uart_tx_lock>
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
    800009e2:	0002e797          	auipc	a5,0x2e
    800009e6:	61e78793          	addi	a5,a5,1566 # 8002f000 <end>
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
    80000a0a:	00012917          	auipc	s2,0x12
    80000a0e:	87690913          	addi	s2,s2,-1930 # 80012280 <kmem>
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
    80000a3c:	00008517          	auipc	a0,0x8
    80000a40:	62450513          	addi	a0,a0,1572 # 80009060 <digits+0x20>
    80000a44:	00000097          	auipc	ra,0x0
    80000a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>
    panic("kfree hello");
    80000a4c:	00008517          	auipc	a0,0x8
    80000a50:	62450513          	addi	a0,a0,1572 # 80009070 <digits+0x30>
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
    80000aae:	00008597          	auipc	a1,0x8
    80000ab2:	5d258593          	addi	a1,a1,1490 # 80009080 <digits+0x40>
    80000ab6:	00011517          	auipc	a0,0x11
    80000aba:	7ca50513          	addi	a0,a0,1994 # 80012280 <kmem>
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	084080e7          	jalr	132(ra) # 80000b42 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ac6:	45c5                	li	a1,17
    80000ac8:	05ee                	slli	a1,a1,0x1b
    80000aca:	0002e517          	auipc	a0,0x2e
    80000ace:	53650513          	addi	a0,a0,1334 # 8002f000 <end>
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
    80000aec:	00011497          	auipc	s1,0x11
    80000af0:	79448493          	addi	s1,s1,1940 # 80012280 <kmem>
    80000af4:	8526                	mv	a0,s1
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	0dc080e7          	jalr	220(ra) # 80000bd2 <acquire>
  r = kmem.freelist;
    80000afe:	6c84                	ld	s1,24(s1)
  if(r)
    80000b00:	c885                	beqz	s1,80000b30 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b02:	609c                	ld	a5,0(s1)
    80000b04:	00011517          	auipc	a0,0x11
    80000b08:	77c50513          	addi	a0,a0,1916 # 80012280 <kmem>
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
    80000b30:	00011517          	auipc	a0,0x11
    80000b34:	75050513          	addi	a0,a0,1872 # 80012280 <kmem>
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
    80000b6c:	00002097          	auipc	ra,0x2
    80000b70:	87a080e7          	jalr	-1926(ra) # 800023e6 <mycpu>
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
    80000b9e:	00002097          	auipc	ra,0x2
    80000ba2:	848080e7          	jalr	-1976(ra) # 800023e6 <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00002097          	auipc	ra,0x2
    80000bae:	83c080e7          	jalr	-1988(ra) # 800023e6 <mycpu>
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
    80000bc2:	00002097          	auipc	ra,0x2
    80000bc6:	824080e7          	jalr	-2012(ra) # 800023e6 <mycpu>
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
    80000c06:	7e4080e7          	jalr	2020(ra) # 800023e6 <mycpu>
    80000c0a:	e888                	sd	a0,16(s1)
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret
    panic("acquire");
    80000c16:	00008517          	auipc	a0,0x8
    80000c1a:	47250513          	addi	a0,a0,1138 # 80009088 <digits+0x48>
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
    80000c32:	7b8080e7          	jalr	1976(ra) # 800023e6 <mycpu>
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
    80000c66:	00008517          	auipc	a0,0x8
    80000c6a:	42a50513          	addi	a0,a0,1066 # 80009090 <digits+0x50>
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	8bc080e7          	jalr	-1860(ra) # 8000052a <panic>
    panic("pop_off");
    80000c76:	00008517          	auipc	a0,0x8
    80000c7a:	43250513          	addi	a0,a0,1074 # 800090a8 <digits+0x68>
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
    80000cbe:	00008517          	auipc	a0,0x8
    80000cc2:	3f250513          	addi	a0,a0,1010 # 800090b0 <digits+0x70>
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
    80000e88:	552080e7          	jalr	1362(ra) # 800023d6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e8c:	00009717          	auipc	a4,0x9
    80000e90:	18c70713          	addi	a4,a4,396 # 8000a018 <started>
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
    80000ea4:	536080e7          	jalr	1334(ra) # 800023d6 <cpuid>
    80000ea8:	85aa                	mv	a1,a0
    80000eaa:	00008517          	auipc	a0,0x8
    80000eae:	22650513          	addi	a0,a0,550 # 800090d0 <digits+0x90>
    80000eb2:	fffff097          	auipc	ra,0xfffff
    80000eb6:	6c2080e7          	jalr	1730(ra) # 80000574 <printf>
    kvminithart();    // turn on paging
    80000eba:	00000097          	auipc	ra,0x0
    80000ebe:	0d8080e7          	jalr	216(ra) # 80000f92 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ec2:	00002097          	auipc	ra,0x2
    80000ec6:	40e080e7          	jalr	1038(ra) # 800032d0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eca:	00006097          	auipc	ra,0x6
    80000ece:	eb6080e7          	jalr	-330(ra) # 80006d80 <plicinithart>
  }

  scheduler();        
    80000ed2:	00002097          	auipc	ra,0x2
    80000ed6:	c9c080e7          	jalr	-868(ra) # 80002b6e <scheduler>
    consoleinit();
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	562080e7          	jalr	1378(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	872080e7          	jalr	-1934(ra) # 80000754 <printfinit>
    printf("\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	47650513          	addi	a0,a0,1142 # 80009360 <digits+0x320>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	1be50513          	addi	a0,a0,446 # 800090b8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    printf("\n");
    80000f0a:	00008517          	auipc	a0,0x8
    80000f0e:	45650513          	addi	a0,a0,1110 # 80009360 <digits+0x320>
    80000f12:	fffff097          	auipc	ra,0xfffff
    80000f16:	662080e7          	jalr	1634(ra) # 80000574 <printf>
    kinit();         // physical page allocator
    80000f1a:	00000097          	auipc	ra,0x0
    80000f1e:	b8c080e7          	jalr	-1140(ra) # 80000aa6 <kinit>
    kvminit();       // create kernel page table
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	2fa080e7          	jalr	762(ra) # 8000121c <kvminit>
    kvminithart();   // turn on paging
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	068080e7          	jalr	104(ra) # 80000f92 <kvminithart>
    procinit();      // process table
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	3f4080e7          	jalr	1012(ra) # 80002326 <procinit>
    trapinit();      // trap vectors
    80000f3a:	00002097          	auipc	ra,0x2
    80000f3e:	36e080e7          	jalr	878(ra) # 800032a8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	38e080e7          	jalr	910(ra) # 800032d0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4a:	00006097          	auipc	ra,0x6
    80000f4e:	e20080e7          	jalr	-480(ra) # 80006d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f52:	00006097          	auipc	ra,0x6
    80000f56:	e2e080e7          	jalr	-466(ra) # 80006d80 <plicinithart>
    binit();         // buffer cache
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	ad4080e7          	jalr	-1324(ra) # 80003a2e <binit>
    iinit();         // inode cache
    80000f62:	00003097          	auipc	ra,0x3
    80000f66:	166080e7          	jalr	358(ra) # 800040c8 <iinit>
    fileinit();      // file table
    80000f6a:	00004097          	auipc	ra,0x4
    80000f6e:	426080e7          	jalr	1062(ra) # 80005390 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	f30080e7          	jalr	-208(ra) # 80006ea2 <virtio_disk_init>
    userinit();      // first user process
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	79c080e7          	jalr	1948(ra) # 80002716 <userinit>
    __sync_synchronize();
    80000f82:	0ff0000f          	fence
    started = 1;
    80000f86:	4785                	li	a5,1
    80000f88:	00009717          	auipc	a4,0x9
    80000f8c:	08f72823          	sw	a5,144(a4) # 8000a018 <started>
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
    80000f98:	00009797          	auipc	a5,0x9
    80000f9c:	0887b783          	ld	a5,136(a5) # 8000a020 <kernel_pagetable>
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
    80000fd0:	4a79                	li	s4,30
  //if(va >= MAXVA)
    //panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd2:	4b31                	li	s6,12
    80000fd4:	a80d                	j	80001006 <walk+0x50>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fd6:	060a8663          	beqz	s5,80001042 <walk+0x8c>
    80000fda:	00000097          	auipc	ra,0x0
    80000fde:	b08080e7          	jalr	-1272(ra) # 80000ae2 <kalloc>
    80000fe2:	84aa                	mv	s1,a0
    80000fe4:	c529                	beqz	a0,8000102e <walk+0x78>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000fe6:	6605                	lui	a2,0x1
    80000fe8:	4581                	li	a1,0
    80000fea:	00000097          	auipc	ra,0x0
    80000fee:	ce4080e7          	jalr	-796(ra) # 80000cce <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000ff2:	00c4d793          	srli	a5,s1,0xc
    80000ff6:	07aa                	slli	a5,a5,0xa
    80000ff8:	0017e793          	ori	a5,a5,1
    80000ffc:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001000:	3a5d                	addiw	s4,s4,-9
    80001002:	036a0063          	beq	s4,s6,80001022 <walk+0x6c>
    pte_t *pte = &pagetable[PX(level, va)];
    80001006:	0149d933          	srl	s2,s3,s4
    8000100a:	1ff97913          	andi	s2,s2,511
    8000100e:	090e                	slli	s2,s2,0x3
    80001010:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001012:	00093483          	ld	s1,0(s2)
    80001016:	0014f793          	andi	a5,s1,1
    8000101a:	dfd5                	beqz	a5,80000fd6 <walk+0x20>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000101c:	80a9                	srli	s1,s1,0xa
    8000101e:	04b2                	slli	s1,s1,0xc
    80001020:	b7c5                	j	80001000 <walk+0x4a>
    }
  }
  return &pagetable[PX(0, va)];
    80001022:	00c9d513          	srli	a0,s3,0xc
    80001026:	1ff57513          	andi	a0,a0,511
    8000102a:	050e                	slli	a0,a0,0x3
    8000102c:	9526                	add	a0,a0,s1
}
    8000102e:	70e2                	ld	ra,56(sp)
    80001030:	7442                	ld	s0,48(sp)
    80001032:	74a2                	ld	s1,40(sp)
    80001034:	7902                	ld	s2,32(sp)
    80001036:	69e2                	ld	s3,24(sp)
    80001038:	6a42                	ld	s4,16(sp)
    8000103a:	6aa2                	ld	s5,8(sp)
    8000103c:	6b02                	ld	s6,0(sp)
    8000103e:	6121                	addi	sp,sp,64
    80001040:	8082                	ret
        return 0;
    80001042:	4501                	li	a0,0
    80001044:	b7ed                	j	8000102e <walk+0x78>

0000000080001046 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001046:	57fd                	li	a5,-1
    80001048:	83e9                	srli	a5,a5,0x1a
    8000104a:	00b7f463          	bgeu	a5,a1,80001052 <walkaddr+0xc>
    return 0;
    8000104e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001050:	8082                	ret
{
    80001052:	1141                	addi	sp,sp,-16
    80001054:	e406                	sd	ra,8(sp)
    80001056:	e022                	sd	s0,0(sp)
    80001058:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000105a:	4601                	li	a2,0
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	f5a080e7          	jalr	-166(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001064:	c105                	beqz	a0,80001084 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001066:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001068:	0117f693          	andi	a3,a5,17
    8000106c:	4745                	li	a4,17
    return 0;
    8000106e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001070:	00e68663          	beq	a3,a4,8000107c <walkaddr+0x36>
}
    80001074:	60a2                	ld	ra,8(sp)
    80001076:	6402                	ld	s0,0(sp)
    80001078:	0141                	addi	sp,sp,16
    8000107a:	8082                	ret
  pa = PTE2PA(*pte);
    8000107c:	00a7d513          	srli	a0,a5,0xa
    80001080:	0532                	slli	a0,a0,0xc
  return pa;
    80001082:	bfcd                	j	80001074 <walkaddr+0x2e>
    return 0;
    80001084:	4501                	li	a0,0
    80001086:	b7fd                	j	80001074 <walkaddr+0x2e>

0000000080001088 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001088:	715d                	addi	sp,sp,-80
    8000108a:	e486                	sd	ra,72(sp)
    8000108c:	e0a2                	sd	s0,64(sp)
    8000108e:	fc26                	sd	s1,56(sp)
    80001090:	f84a                	sd	s2,48(sp)
    80001092:	f44e                	sd	s3,40(sp)
    80001094:	f052                	sd	s4,32(sp)
    80001096:	ec56                	sd	s5,24(sp)
    80001098:	e85a                	sd	s6,16(sp)
    8000109a:	e45e                	sd	s7,8(sp)
    8000109c:	0880                	addi	s0,sp,80
    8000109e:	8aaa                	mv	s5,a0
    800010a0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010a2:	777d                	lui	a4,0xfffff
    800010a4:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010a8:	167d                	addi	a2,a2,-1
    800010aa:	00b609b3          	add	s3,a2,a1
    800010ae:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010b2:	893e                	mv	s2,a5
    800010b4:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010b8:	6b85                	lui	s7,0x1
    800010ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010be:	4605                	li	a2,1
    800010c0:	85ca                	mv	a1,s2
    800010c2:	8556                	mv	a0,s5
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	ef2080e7          	jalr	-270(ra) # 80000fb6 <walk>
    800010cc:	c51d                	beqz	a0,800010fa <mappages+0x72>
    if(*pte & PTE_V)
    800010ce:	611c                	ld	a5,0(a0)
    800010d0:	8b85                	andi	a5,a5,1
    800010d2:	ef81                	bnez	a5,800010ea <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010d4:	80b1                	srli	s1,s1,0xc
    800010d6:	04aa                	slli	s1,s1,0xa
    800010d8:	0164e4b3          	or	s1,s1,s6
    800010dc:	0014e493          	ori	s1,s1,1
    800010e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800010e2:	03390863          	beq	s2,s3,80001112 <mappages+0x8a>
    a += PGSIZE;
    800010e6:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800010e8:	bfc9                	j	800010ba <mappages+0x32>
      panic("remap");
    800010ea:	00008517          	auipc	a0,0x8
    800010ee:	ffe50513          	addi	a0,a0,-2 # 800090e8 <digits+0xa8>
    800010f2:	fffff097          	auipc	ra,0xfffff
    800010f6:	438080e7          	jalr	1080(ra) # 8000052a <panic>
      return -1;
    800010fa:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010fc:	60a6                	ld	ra,72(sp)
    800010fe:	6406                	ld	s0,64(sp)
    80001100:	74e2                	ld	s1,56(sp)
    80001102:	7942                	ld	s2,48(sp)
    80001104:	79a2                	ld	s3,40(sp)
    80001106:	7a02                	ld	s4,32(sp)
    80001108:	6ae2                	ld	s5,24(sp)
    8000110a:	6b42                	ld	s6,16(sp)
    8000110c:	6ba2                	ld	s7,8(sp)
    8000110e:	6161                	addi	sp,sp,80
    80001110:	8082                	ret
  return 0;
    80001112:	4501                	li	a0,0
    80001114:	b7e5                	j	800010fc <mappages+0x74>

0000000080001116 <kvmmap>:
{
    80001116:	1141                	addi	sp,sp,-16
    80001118:	e406                	sd	ra,8(sp)
    8000111a:	e022                	sd	s0,0(sp)
    8000111c:	0800                	addi	s0,sp,16
    8000111e:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001120:	86b2                	mv	a3,a2
    80001122:	863e                	mv	a2,a5
    80001124:	00000097          	auipc	ra,0x0
    80001128:	f64080e7          	jalr	-156(ra) # 80001088 <mappages>
    8000112c:	e509                	bnez	a0,80001136 <kvmmap+0x20>
}
    8000112e:	60a2                	ld	ra,8(sp)
    80001130:	6402                	ld	s0,0(sp)
    80001132:	0141                	addi	sp,sp,16
    80001134:	8082                	ret
    panic("kvmmap");
    80001136:	00008517          	auipc	a0,0x8
    8000113a:	fba50513          	addi	a0,a0,-70 # 800090f0 <digits+0xb0>
    8000113e:	fffff097          	auipc	ra,0xfffff
    80001142:	3ec080e7          	jalr	1004(ra) # 8000052a <panic>

0000000080001146 <kvmmake>:
{
    80001146:	1101                	addi	sp,sp,-32
    80001148:	ec06                	sd	ra,24(sp)
    8000114a:	e822                	sd	s0,16(sp)
    8000114c:	e426                	sd	s1,8(sp)
    8000114e:	e04a                	sd	s2,0(sp)
    80001150:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001152:	00000097          	auipc	ra,0x0
    80001156:	990080e7          	jalr	-1648(ra) # 80000ae2 <kalloc>
    8000115a:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000115c:	6605                	lui	a2,0x1
    8000115e:	4581                	li	a1,0
    80001160:	00000097          	auipc	ra,0x0
    80001164:	b6e080e7          	jalr	-1170(ra) # 80000cce <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001168:	4719                	li	a4,6
    8000116a:	6685                	lui	a3,0x1
    8000116c:	10000637          	lui	a2,0x10000
    80001170:	100005b7          	lui	a1,0x10000
    80001174:	8526                	mv	a0,s1
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	fa0080e7          	jalr	-96(ra) # 80001116 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000117e:	4719                	li	a4,6
    80001180:	6685                	lui	a3,0x1
    80001182:	10001637          	lui	a2,0x10001
    80001186:	100015b7          	lui	a1,0x10001
    8000118a:	8526                	mv	a0,s1
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	f8a080e7          	jalr	-118(ra) # 80001116 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001194:	4719                	li	a4,6
    80001196:	004006b7          	lui	a3,0x400
    8000119a:	0c000637          	lui	a2,0xc000
    8000119e:	0c0005b7          	lui	a1,0xc000
    800011a2:	8526                	mv	a0,s1
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	f72080e7          	jalr	-142(ra) # 80001116 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ac:	00008917          	auipc	s2,0x8
    800011b0:	e5490913          	addi	s2,s2,-428 # 80009000 <etext>
    800011b4:	4729                	li	a4,10
    800011b6:	80008697          	auipc	a3,0x80008
    800011ba:	e4a68693          	addi	a3,a3,-438 # 9000 <_entry-0x7fff7000>
    800011be:	4605                	li	a2,1
    800011c0:	067e                	slli	a2,a2,0x1f
    800011c2:	85b2                	mv	a1,a2
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f50080e7          	jalr	-176(ra) # 80001116 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	46c5                	li	a3,17
    800011d2:	06ee                	slli	a3,a3,0x1b
    800011d4:	412686b3          	sub	a3,a3,s2
    800011d8:	864a                	mv	a2,s2
    800011da:	85ca                	mv	a1,s2
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f38080e7          	jalr	-200(ra) # 80001116 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800011e6:	4729                	li	a4,10
    800011e8:	6685                	lui	a3,0x1
    800011ea:	00007617          	auipc	a2,0x7
    800011ee:	e1660613          	addi	a2,a2,-490 # 80008000 <_trampoline>
    800011f2:	040005b7          	lui	a1,0x4000
    800011f6:	15fd                	addi	a1,a1,-1
    800011f8:	05b2                	slli	a1,a1,0xc
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f1a080e7          	jalr	-230(ra) # 80001116 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001204:	8526                	mv	a0,s1
    80001206:	00001097          	auipc	ra,0x1
    8000120a:	08a080e7          	jalr	138(ra) # 80002290 <proc_mapstacks>
}
    8000120e:	8526                	mv	a0,s1
    80001210:	60e2                	ld	ra,24(sp)
    80001212:	6442                	ld	s0,16(sp)
    80001214:	64a2                	ld	s1,8(sp)
    80001216:	6902                	ld	s2,0(sp)
    80001218:	6105                	addi	sp,sp,32
    8000121a:	8082                	ret

000000008000121c <kvminit>:
{
    8000121c:	1141                	addi	sp,sp,-16
    8000121e:	e406                	sd	ra,8(sp)
    80001220:	e022                	sd	s0,0(sp)
    80001222:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f22080e7          	jalr	-222(ra) # 80001146 <kvmmake>
    8000122c:	00009797          	auipc	a5,0x9
    80001230:	dea7ba23          	sd	a0,-524(a5) # 8000a020 <kernel_pagetable>
}
    80001234:	60a2                	ld	ra,8(sp)
    80001236:	6402                	ld	s0,0(sp)
    80001238:	0141                	addi	sp,sp,16
    8000123a:	8082                	ret

000000008000123c <origin_uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void origin_uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free){
    8000123c:	715d                	addi	sp,sp,-80
    8000123e:	e486                	sd	ra,72(sp)
    80001240:	e0a2                	sd	s0,64(sp)
    80001242:	fc26                	sd	s1,56(sp)
    80001244:	f84a                	sd	s2,48(sp)
    80001246:	f44e                	sd	s3,40(sp)
    80001248:	f052                	sd	s4,32(sp)
    8000124a:	ec56                	sd	s5,24(sp)
    8000124c:	e85a                	sd	s6,16(sp)
    8000124e:	e45e                	sd	s7,8(sp)
    80001250:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001252:	03459793          	slli	a5,a1,0x34
    80001256:	e795                	bnez	a5,80001282 <origin_uvmunmap+0x46>
    80001258:	8a2a                	mv	s4,a0
    8000125a:	892e                	mv	s2,a1
    8000125c:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000125e:	0632                	slli	a2,a2,0xc
    80001260:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001264:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001266:	6b05                	lui	s6,0x1
    80001268:	0735e263          	bltu	a1,s3,800012cc <origin_uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    }
}
    8000126c:	60a6                	ld	ra,72(sp)
    8000126e:	6406                	ld	s0,64(sp)
    80001270:	74e2                	ld	s1,56(sp)
    80001272:	7942                	ld	s2,48(sp)
    80001274:	79a2                	ld	s3,40(sp)
    80001276:	7a02                	ld	s4,32(sp)
    80001278:	6ae2                	ld	s5,24(sp)
    8000127a:	6b42                	ld	s6,16(sp)
    8000127c:	6ba2                	ld	s7,8(sp)
    8000127e:	6161                	addi	sp,sp,80
    80001280:	8082                	ret
    panic("uvmunmap: not aligned");
    80001282:	00008517          	auipc	a0,0x8
    80001286:	e7650513          	addi	a0,a0,-394 # 800090f8 <digits+0xb8>
    8000128a:	fffff097          	auipc	ra,0xfffff
    8000128e:	2a0080e7          	jalr	672(ra) # 8000052a <panic>
      panic("uvmunmap: walk");
    80001292:	00008517          	auipc	a0,0x8
    80001296:	e7e50513          	addi	a0,a0,-386 # 80009110 <digits+0xd0>
    8000129a:	fffff097          	auipc	ra,0xfffff
    8000129e:	290080e7          	jalr	656(ra) # 8000052a <panic>
      panic("uvmunmap: not mapped");
    800012a2:	00008517          	auipc	a0,0x8
    800012a6:	e7e50513          	addi	a0,a0,-386 # 80009120 <digits+0xe0>
    800012aa:	fffff097          	auipc	ra,0xfffff
    800012ae:	280080e7          	jalr	640(ra) # 8000052a <panic>
      panic("uvmunmap: not a leaf");
    800012b2:	00008517          	auipc	a0,0x8
    800012b6:	e8650513          	addi	a0,a0,-378 # 80009138 <digits+0xf8>
    800012ba:	fffff097          	auipc	ra,0xfffff
    800012be:	270080e7          	jalr	624(ra) # 8000052a <panic>
    *pte = 0;
    800012c2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012c6:	995a                	add	s2,s2,s6
    800012c8:	fb3972e3          	bgeu	s2,s3,8000126c <origin_uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012cc:	4601                	li	a2,0
    800012ce:	85ca                	mv	a1,s2
    800012d0:	8552                	mv	a0,s4
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	ce4080e7          	jalr	-796(ra) # 80000fb6 <walk>
    800012da:	84aa                	mv	s1,a0
    800012dc:	d95d                	beqz	a0,80001292 <origin_uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800012de:	6108                	ld	a0,0(a0)
    800012e0:	00157793          	andi	a5,a0,1
    800012e4:	dfdd                	beqz	a5,800012a2 <origin_uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e6:	3ff57793          	andi	a5,a0,1023
    800012ea:	fd7784e3          	beq	a5,s7,800012b2 <origin_uvmunmap+0x76>
    if(do_free){
    800012ee:	fc0a8ae3          	beqz	s5,800012c2 <origin_uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800012f2:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012f4:	0532                	slli	a0,a0,0xc
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	6e0080e7          	jalr	1760(ra) # 800009d6 <kfree>
    800012fe:	b7d1                	j	800012c2 <origin_uvmunmap+0x86>

0000000080001300 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001300:	1101                	addi	sp,sp,-32
    80001302:	ec06                	sd	ra,24(sp)
    80001304:	e822                	sd	s0,16(sp)
    80001306:	e426                	sd	s1,8(sp)
    80001308:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	7d8080e7          	jalr	2008(ra) # 80000ae2 <kalloc>
    80001312:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001314:	c519                	beqz	a0,80001322 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001316:	6605                	lui	a2,0x1
    80001318:	4581                	li	a1,0
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	9b4080e7          	jalr	-1612(ra) # 80000cce <memset>
  return pagetable;
}
    80001322:	8526                	mv	a0,s1
    80001324:	60e2                	ld	ra,24(sp)
    80001326:	6442                	ld	s0,16(sp)
    80001328:	64a2                	ld	s1,8(sp)
    8000132a:	6105                	addi	sp,sp,32
    8000132c:	8082                	ret

000000008000132e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000133e:	6785                	lui	a5,0x1
    80001340:	04f67863          	bgeu	a2,a5,80001390 <uvminit+0x62>
    80001344:	8a2a                	mv	s4,a0
    80001346:	89ae                	mv	s3,a1
    80001348:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000134a:	fffff097          	auipc	ra,0xfffff
    8000134e:	798080e7          	jalr	1944(ra) # 80000ae2 <kalloc>
    80001352:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001354:	6605                	lui	a2,0x1
    80001356:	4581                	li	a1,0
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	976080e7          	jalr	-1674(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001360:	4779                	li	a4,30
    80001362:	86ca                	mv	a3,s2
    80001364:	6605                	lui	a2,0x1
    80001366:	4581                	li	a1,0
    80001368:	8552                	mv	a0,s4
    8000136a:	00000097          	auipc	ra,0x0
    8000136e:	d1e080e7          	jalr	-738(ra) # 80001088 <mappages>
  memmove(mem, src, sz);
    80001372:	8626                	mv	a2,s1
    80001374:	85ce                	mv	a1,s3
    80001376:	854a                	mv	a0,s2
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	9b2080e7          	jalr	-1614(ra) # 80000d2a <memmove>
}
    80001380:	70a2                	ld	ra,40(sp)
    80001382:	7402                	ld	s0,32(sp)
    80001384:	64e2                	ld	s1,24(sp)
    80001386:	6942                	ld	s2,16(sp)
    80001388:	69a2                	ld	s3,8(sp)
    8000138a:	6a02                	ld	s4,0(sp)
    8000138c:	6145                	addi	sp,sp,48
    8000138e:	8082                	ret
    panic("inituvm: more than a page");
    80001390:	00008517          	auipc	a0,0x8
    80001394:	dc050513          	addi	a0,a0,-576 # 80009150 <digits+0x110>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	192080e7          	jalr	402(ra) # 8000052a <panic>

00000000800013a0 <find_min_empty_offset>:

//find min empty offset to write into swap file
uint
find_min_empty_offset(){
    800013a0:	1141                	addi	sp,sp,-16
    800013a2:	e406                	sd	ra,8(sp)
    800013a4:	e022                	sd	s0,0(sp)
    800013a6:	0800                	addi	s0,sp,16
  struct proc * process = myproc();
    800013a8:	00001097          	auipc	ra,0x1
    800013ac:	05a080e7          	jalr	90(ra) # 80002402 <myproc>
  uint min_empty_offset= 0;
  int already_in_use = 0;
  for(int i=0; i<process->sz; i = i+PGSIZE){
    800013b0:	04853803          	ld	a6,72(a0)
    800013b4:	4581                	li	a1,0
    800013b6:	2f050613          	addi	a2,a0,752
    800013ba:	6885                	lui	a7,0x1
    800013bc:	00081763          	bnez	a6,800013ca <find_min_empty_offset+0x2a>
  uint min_empty_offset= 0;
    800013c0:	4501                	li	a0,0
    800013c2:	a005                	j	800013e2 <find_min_empty_offset+0x42>
  for(int i=0; i<process->sz; i = i+PGSIZE){
    800013c4:	95c6                	add	a1,a1,a7
    800013c6:	0305f263          	bgeu	a1,a6,800013ea <find_min_empty_offset+0x4a>
    already_in_use = 0;
      for(int j=0; j<32; j++){
    800013ca:	17050793          	addi	a5,a0,368
        if(process->paging_meta_data[j].offset == i){
    800013ce:	0005869b          	sext.w	a3,a1
    800013d2:	4398                	lw	a4,0(a5)
    800013d4:	fed708e3          	beq	a4,a3,800013c4 <find_min_empty_offset+0x24>
      for(int j=0; j<32; j++){
    800013d8:	07b1                	addi	a5,a5,12
    800013da:	fec79ce3          	bne	a5,a2,800013d2 <find_min_empty_offset+0x32>
          already_in_use =1; 
          break;
        }
      }
    if(already_in_use == 0){
      min_empty_offset = i;
    800013de:	0005851b          	sext.w	a0,a1
      break; 
    }
  }
  return min_empty_offset;

}
    800013e2:	60a2                	ld	ra,8(sp)
    800013e4:	6402                	ld	s0,0(sp)
    800013e6:	0141                	addi	sp,sp,16
    800013e8:	8082                	ret
  uint min_empty_offset= 0;
    800013ea:	4501                	li	a0,0
    800013ec:	bfdd                	j	800013e2 <find_min_empty_offset+0x42>

00000000800013ee <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800013ee:	7179                	addi	sp,sp,-48
    800013f0:	f406                	sd	ra,40(sp)
    800013f2:	f022                	sd	s0,32(sp)
    800013f4:	ec26                	sd	s1,24(sp)
    800013f6:	e84a                	sd	s2,16(sp)
    800013f8:	e44e                	sd	s3,8(sp)
    800013fa:	e052                	sd	s4,0(sp)
    800013fc:	1800                	addi	s0,sp,48
    800013fe:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001400:	84aa                	mv	s1,a0
    80001402:	6905                	lui	s2,0x1
    80001404:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001406:	4985                	li	s3,1
    80001408:	a821                	j	80001420 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000140a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000140c:	0532                	slli	a0,a0,0xc
    8000140e:	00000097          	auipc	ra,0x0
    80001412:	fe0080e7          	jalr	-32(ra) # 800013ee <freewalk>
      pagetable[i] = 0;
    80001416:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000141a:	04a1                	addi	s1,s1,8
    8000141c:	03248163          	beq	s1,s2,8000143e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001420:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001422:	00f57793          	andi	a5,a0,15
    80001426:	ff3782e3          	beq	a5,s3,8000140a <freewalk+0x1c>
    } else if(pte & PTE_V){ 
    8000142a:	8905                	andi	a0,a0,1
    8000142c:	d57d                	beqz	a0,8000141a <freewalk+0x2c>
      panic("freewalk: leaf\n");
    8000142e:	00008517          	auipc	a0,0x8
    80001432:	d4250513          	addi	a0,a0,-702 # 80009170 <digits+0x130>
    80001436:	fffff097          	auipc	ra,0xfffff
    8000143a:	0f4080e7          	jalr	244(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    8000143e:	8552                	mv	a0,s4
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	596080e7          	jalr	1430(ra) # 800009d6 <kfree>
}
    80001448:	70a2                	ld	ra,40(sp)
    8000144a:	7402                	ld	s0,32(sp)
    8000144c:	64e2                	ld	s1,24(sp)
    8000144e:	6942                	ld	s2,16(sp)
    80001450:	69a2                	ld	s3,8(sp)
    80001452:	6a02                	ld	s4,0(sp)
    80001454:	6145                	addi	sp,sp,48
    80001456:	8082                	ret

0000000080001458 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001458:	1141                	addi	sp,sp,-16
    8000145a:	e406                	sd	ra,8(sp)
    8000145c:	e022                	sd	s0,0(sp)
    8000145e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001460:	4601                	li	a2,0
    80001462:	00000097          	auipc	ra,0x0
    80001466:	b54080e7          	jalr	-1196(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000146a:	c901                	beqz	a0,8000147a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146c:	611c                	ld	a5,0(a0)
    8000146e:	9bbd                	andi	a5,a5,-17
    80001470:	e11c                	sd	a5,0(a0)
}
    80001472:	60a2                	ld	ra,8(sp)
    80001474:	6402                	ld	s0,0(sp)
    80001476:	0141                	addi	sp,sp,16
    80001478:	8082                	ret
    panic("uvmclear");
    8000147a:	00008517          	auipc	a0,0x8
    8000147e:	d0650513          	addi	a0,a0,-762 # 80009180 <digits+0x140>
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	0a8080e7          	jalr	168(ra) # 8000052a <panic>

000000008000148a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000148a:	c6bd                	beqz	a3,800014f8 <copyout+0x6e>
{
    8000148c:	715d                	addi	sp,sp,-80
    8000148e:	e486                	sd	ra,72(sp)
    80001490:	e0a2                	sd	s0,64(sp)
    80001492:	fc26                	sd	s1,56(sp)
    80001494:	f84a                	sd	s2,48(sp)
    80001496:	f44e                	sd	s3,40(sp)
    80001498:	f052                	sd	s4,32(sp)
    8000149a:	ec56                	sd	s5,24(sp)
    8000149c:	e85a                	sd	s6,16(sp)
    8000149e:	e45e                	sd	s7,8(sp)
    800014a0:	e062                	sd	s8,0(sp)
    800014a2:	0880                	addi	s0,sp,80
    800014a4:	8b2a                	mv	s6,a0
    800014a6:	8c2e                	mv	s8,a1
    800014a8:	8a32                	mv	s4,a2
    800014aa:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800014ac:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
   
    if(pa0 == 0){
      return -1;
    }
    n = PGSIZE - (dstva - va0);
    800014ae:	6a85                	lui	s5,0x1
    800014b0:	a015                	j	800014d4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800014b2:	9562                	add	a0,a0,s8
    800014b4:	0004861b          	sext.w	a2,s1
    800014b8:	85d2                	mv	a1,s4
    800014ba:	41250533          	sub	a0,a0,s2
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	86c080e7          	jalr	-1940(ra) # 80000d2a <memmove>

    len -= n;
    800014c6:	409989b3          	sub	s3,s3,s1
    src += n;
    800014ca:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800014cc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800014d0:	02098263          	beqz	s3,800014f4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800014d4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800014d8:	85ca                	mv	a1,s2
    800014da:	855a                	mv	a0,s6
    800014dc:	00000097          	auipc	ra,0x0
    800014e0:	b6a080e7          	jalr	-1174(ra) # 80001046 <walkaddr>
    if(pa0 == 0){
    800014e4:	cd01                	beqz	a0,800014fc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800014e6:	418904b3          	sub	s1,s2,s8
    800014ea:	94d6                	add	s1,s1,s5
    if(n > len)
    800014ec:	fc99f3e3          	bgeu	s3,s1,800014b2 <copyout+0x28>
    800014f0:	84ce                	mv	s1,s3
    800014f2:	b7c1                	j	800014b2 <copyout+0x28>
  }
  return 0;
    800014f4:	4501                	li	a0,0
    800014f6:	a021                	j	800014fe <copyout+0x74>
    800014f8:	4501                	li	a0,0
}
    800014fa:	8082                	ret
      return -1;
    800014fc:	557d                	li	a0,-1
}
    800014fe:	60a6                	ld	ra,72(sp)
    80001500:	6406                	ld	s0,64(sp)
    80001502:	74e2                	ld	s1,56(sp)
    80001504:	7942                	ld	s2,48(sp)
    80001506:	79a2                	ld	s3,40(sp)
    80001508:	7a02                	ld	s4,32(sp)
    8000150a:	6ae2                	ld	s5,24(sp)
    8000150c:	6b42                	ld	s6,16(sp)
    8000150e:	6ba2                	ld	s7,8(sp)
    80001510:	6c02                	ld	s8,0(sp)
    80001512:	6161                	addi	sp,sp,80
    80001514:	8082                	ret

0000000080001516 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001516:	caa5                	beqz	a3,80001586 <copyin+0x70>
{
    80001518:	715d                	addi	sp,sp,-80
    8000151a:	e486                	sd	ra,72(sp)
    8000151c:	e0a2                	sd	s0,64(sp)
    8000151e:	fc26                	sd	s1,56(sp)
    80001520:	f84a                	sd	s2,48(sp)
    80001522:	f44e                	sd	s3,40(sp)
    80001524:	f052                	sd	s4,32(sp)
    80001526:	ec56                	sd	s5,24(sp)
    80001528:	e85a                	sd	s6,16(sp)
    8000152a:	e45e                	sd	s7,8(sp)
    8000152c:	e062                	sd	s8,0(sp)
    8000152e:	0880                	addi	s0,sp,80
    80001530:	8b2a                	mv	s6,a0
    80001532:	8a2e                	mv	s4,a1
    80001534:	8c32                	mv	s8,a2
    80001536:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001538:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000153a:	6a85                	lui	s5,0x1
    8000153c:	a01d                	j	80001562 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000153e:	018505b3          	add	a1,a0,s8
    80001542:	0004861b          	sext.w	a2,s1
    80001546:	412585b3          	sub	a1,a1,s2
    8000154a:	8552                	mv	a0,s4
    8000154c:	fffff097          	auipc	ra,0xfffff
    80001550:	7de080e7          	jalr	2014(ra) # 80000d2a <memmove>

    len -= n;
    80001554:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001558:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000155a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000155e:	02098263          	beqz	s3,80001582 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001562:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001566:	85ca                	mv	a1,s2
    80001568:	855a                	mv	a0,s6
    8000156a:	00000097          	auipc	ra,0x0
    8000156e:	adc080e7          	jalr	-1316(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    80001572:	cd01                	beqz	a0,8000158a <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001574:	418904b3          	sub	s1,s2,s8
    80001578:	94d6                	add	s1,s1,s5
    if(n > len)
    8000157a:	fc99f2e3          	bgeu	s3,s1,8000153e <copyin+0x28>
    8000157e:	84ce                	mv	s1,s3
    80001580:	bf7d                	j	8000153e <copyin+0x28>
  }
  return 0;
    80001582:	4501                	li	a0,0
    80001584:	a021                	j	8000158c <copyin+0x76>
    80001586:	4501                	li	a0,0
}
    80001588:	8082                	ret
      return -1;
    8000158a:	557d                	li	a0,-1
}
    8000158c:	60a6                	ld	ra,72(sp)
    8000158e:	6406                	ld	s0,64(sp)
    80001590:	74e2                	ld	s1,56(sp)
    80001592:	7942                	ld	s2,48(sp)
    80001594:	79a2                	ld	s3,40(sp)
    80001596:	7a02                	ld	s4,32(sp)
    80001598:	6ae2                	ld	s5,24(sp)
    8000159a:	6b42                	ld	s6,16(sp)
    8000159c:	6ba2                	ld	s7,8(sp)
    8000159e:	6c02                	ld	s8,0(sp)
    800015a0:	6161                	addi	sp,sp,80
    800015a2:	8082                	ret

00000000800015a4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800015a4:	c6c5                	beqz	a3,8000164c <copyinstr+0xa8>
{
    800015a6:	715d                	addi	sp,sp,-80
    800015a8:	e486                	sd	ra,72(sp)
    800015aa:	e0a2                	sd	s0,64(sp)
    800015ac:	fc26                	sd	s1,56(sp)
    800015ae:	f84a                	sd	s2,48(sp)
    800015b0:	f44e                	sd	s3,40(sp)
    800015b2:	f052                	sd	s4,32(sp)
    800015b4:	ec56                	sd	s5,24(sp)
    800015b6:	e85a                	sd	s6,16(sp)
    800015b8:	e45e                	sd	s7,8(sp)
    800015ba:	0880                	addi	s0,sp,80
    800015bc:	8a2a                	mv	s4,a0
    800015be:	8b2e                	mv	s6,a1
    800015c0:	8bb2                	mv	s7,a2
    800015c2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800015c4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800015c6:	6985                	lui	s3,0x1
    800015c8:	a035                	j	800015f4 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800015ca:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800015ce:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800015d0:	0017b793          	seqz	a5,a5
    800015d4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800015d8:	60a6                	ld	ra,72(sp)
    800015da:	6406                	ld	s0,64(sp)
    800015dc:	74e2                	ld	s1,56(sp)
    800015de:	7942                	ld	s2,48(sp)
    800015e0:	79a2                	ld	s3,40(sp)
    800015e2:	7a02                	ld	s4,32(sp)
    800015e4:	6ae2                	ld	s5,24(sp)
    800015e6:	6b42                	ld	s6,16(sp)
    800015e8:	6ba2                	ld	s7,8(sp)
    800015ea:	6161                	addi	sp,sp,80
    800015ec:	8082                	ret
    srcva = va0 + PGSIZE;
    800015ee:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800015f2:	c8a9                	beqz	s1,80001644 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800015f4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800015f8:	85ca                	mv	a1,s2
    800015fa:	8552                	mv	a0,s4
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	a4a080e7          	jalr	-1462(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    80001604:	c131                	beqz	a0,80001648 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001606:	41790833          	sub	a6,s2,s7
    8000160a:	984e                	add	a6,a6,s3
    if(n > max)
    8000160c:	0104f363          	bgeu	s1,a6,80001612 <copyinstr+0x6e>
    80001610:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001612:	955e                	add	a0,a0,s7
    80001614:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001618:	fc080be3          	beqz	a6,800015ee <copyinstr+0x4a>
    8000161c:	985a                	add	a6,a6,s6
    8000161e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001620:	41650633          	sub	a2,a0,s6
    80001624:	14fd                	addi	s1,s1,-1
    80001626:	9b26                	add	s6,s6,s1
    80001628:	00f60733          	add	a4,a2,a5
    8000162c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0000>
    80001630:	df49                	beqz	a4,800015ca <copyinstr+0x26>
        *dst = *p;
    80001632:	00e78023          	sb	a4,0(a5)
      --max;
    80001636:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000163a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000163c:	ff0796e3          	bne	a5,a6,80001628 <copyinstr+0x84>
      dst++;
    80001640:	8b42                	mv	s6,a6
    80001642:	b775                	j	800015ee <copyinstr+0x4a>
    80001644:	4781                	li	a5,0
    80001646:	b769                	j	800015d0 <copyinstr+0x2c>
      return -1;
    80001648:	557d                	li	a0,-1
    8000164a:	b779                	j	800015d8 <copyinstr+0x34>
  int got_null = 0;
    8000164c:	4781                	li	a5,0
  if(got_null){
    8000164e:	0017b793          	seqz	a5,a5
    80001652:	40f00533          	neg	a0,a5
}
    80001656:	8082                	ret

0000000080001658 <get_num_of_pages_in_memory>:
    p->paging_meta_data[remove_file_indx].offset = offset;
    p->paging_meta_data[remove_file_indx].in_memory = 0;
      
}

int get_num_of_pages_in_memory(){
    80001658:	7139                	addi	sp,sp,-64
    8000165a:	fc06                	sd	ra,56(sp)
    8000165c:	f822                	sd	s0,48(sp)
    8000165e:	f426                	sd	s1,40(sp)
    80001660:	f04a                	sd	s2,32(sp)
    80001662:	ec4e                	sd	s3,24(sp)
    80001664:	e852                	sd	s4,16(sp)
    80001666:	e456                	sd	s5,8(sp)
    80001668:	0080                	addi	s0,sp,64
  int counter = 0;
  for(int i=0; i<32; i++){
    8000166a:	4481                	li	s1,0
  int counter = 0;
    8000166c:	4981                	li	s3,0
    if(myproc()->paging_meta_data[i].in_memory){
      printf("pid %d , %d in memory, aging %d\n", myproc()->pid, i, myproc()->paging_meta_data[i].aging);
    8000166e:	00008a17          	auipc	s4,0x8
    80001672:	b22a0a13          	addi	s4,s4,-1246 # 80009190 <digits+0x150>
  for(int i=0; i<32; i++){
    80001676:	02000913          	li	s2,32
    8000167a:	a021                	j	80001682 <get_num_of_pages_in_memory+0x2a>
    8000167c:	2485                	addiw	s1,s1,1
    8000167e:	05248863          	beq	s1,s2,800016ce <get_num_of_pages_in_memory+0x76>
    if(myproc()->paging_meta_data[i].in_memory){
    80001682:	00001097          	auipc	ra,0x1
    80001686:	d80080e7          	jalr	-640(ra) # 80002402 <myproc>
    8000168a:	00149793          	slli	a5,s1,0x1
    8000168e:	97a6                	add	a5,a5,s1
    80001690:	078a                	slli	a5,a5,0x2
    80001692:	97aa                	add	a5,a5,a0
    80001694:	1787a783          	lw	a5,376(a5)
    80001698:	d3f5                	beqz	a5,8000167c <get_num_of_pages_in_memory+0x24>
      printf("pid %d , %d in memory, aging %d\n", myproc()->pid, i, myproc()->paging_meta_data[i].aging);
    8000169a:	00001097          	auipc	ra,0x1
    8000169e:	d68080e7          	jalr	-664(ra) # 80002402 <myproc>
    800016a2:	03052a83          	lw	s5,48(a0)
    800016a6:	00001097          	auipc	ra,0x1
    800016aa:	d5c080e7          	jalr	-676(ra) # 80002402 <myproc>
    800016ae:	00149793          	slli	a5,s1,0x1
    800016b2:	97a6                	add	a5,a5,s1
    800016b4:	078a                	slli	a5,a5,0x2
    800016b6:	97aa                	add	a5,a5,a0
    800016b8:	1747a683          	lw	a3,372(a5)
    800016bc:	8626                	mv	a2,s1
    800016be:	85d6                	mv	a1,s5
    800016c0:	8552                	mv	a0,s4
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	eb2080e7          	jalr	-334(ra) # 80000574 <printf>
      counter = counter+1;
    800016ca:	2985                	addiw	s3,s3,1
    800016cc:	bf45                	j	8000167c <get_num_of_pages_in_memory+0x24>
    }
  }
  return counter; 
}
    800016ce:	854e                	mv	a0,s3
    800016d0:	70e2                	ld	ra,56(sp)
    800016d2:	7442                	ld	s0,48(sp)
    800016d4:	74a2                	ld	s1,40(sp)
    800016d6:	7902                	ld	s2,32(sp)
    800016d8:	69e2                	ld	s3,24(sp)
    800016da:	6a42                	ld	s4,16(sp)
    800016dc:	6aa2                	ld	s5,8(sp)
    800016de:	6121                	addi	sp,sp,64
    800016e0:	8082                	ret

00000000800016e2 <minimum_counter_NFUA>:
  else
    exit(-1);
}


int minimum_counter_NFUA(){
    800016e2:	1141                	addi	sp,sp,-16
    800016e4:	e406                	sd	ra,8(sp)
    800016e6:	e022                	sd	s0,0(sp)
    800016e8:	0800                	addi	s0,sp,16
  struct proc * p = myproc();
    800016ea:	00001097          	auipc	ra,0x1
    800016ee:	d18080e7          	jalr	-744(ra) # 80002402 <myproc>
  uint min_age = -1;
  int index_page = -1;
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    800016f2:	19850793          	addi	a5,a0,408
    800016f6:	470d                	li	a4,3
  int index_page = -1;
    800016f8:	557d                	li	a0,-1
  uint min_age = -1;
    800016fa:	55fd                	li	a1,-1
    if (p->paging_meta_data[i].in_memory ){
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    800016fc:	58fd                	li	a7,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    800016fe:	02000813          	li	a6,32
    80001702:	a039                	j	80001710 <minimum_counter_NFUA+0x2e>
          min_age = p->paging_meta_data[i].aging;
    80001704:	420c                	lw	a1,0(a2)
    80001706:	853a                	mv	a0,a4
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001708:	2705                	addiw	a4,a4,1
    8000170a:	07b1                	addi	a5,a5,12
    8000170c:	01070b63          	beq	a4,a6,80001722 <minimum_counter_NFUA+0x40>
    if (p->paging_meta_data[i].in_memory ){
    80001710:	863e                	mv	a2,a5
    80001712:	43d4                	lw	a3,4(a5)
    80001714:	daf5                	beqz	a3,80001708 <minimum_counter_NFUA+0x26>
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    80001716:	ff1587e3          	beq	a1,a7,80001704 <minimum_counter_NFUA+0x22>
    8000171a:	4394                	lw	a3,0(a5)
    8000171c:	feb6f6e3          	bgeu	a3,a1,80001708 <minimum_counter_NFUA+0x26>
    80001720:	b7d5                	j	80001704 <minimum_counter_NFUA+0x22>
          index_page = i;
        }
      }
  }
  if(min_age == -1)
    80001722:	57fd                	li	a5,-1
    80001724:	00f58663          	beq	a1,a5,80001730 <minimum_counter_NFUA+0x4e>
    panic("page replacment algorithem failed");
  return index_page;
}
    80001728:	60a2                	ld	ra,8(sp)
    8000172a:	6402                	ld	s0,0(sp)
    8000172c:	0141                	addi	sp,sp,16
    8000172e:	8082                	ret
    panic("page replacment algorithem failed");
    80001730:	00008517          	auipc	a0,0x8
    80001734:	a8850513          	addi	a0,a0,-1400 # 800091b8 <digits+0x178>
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>

0000000080001740 <count_one_bits>:

int count_one_bits(uint age){
    80001740:	1141                	addi	sp,sp,-16
    80001742:	e422                	sd	s0,8(sp)
    80001744:	0800                	addi	s0,sp,16
  int count = 0;
  while(age) {
    80001746:	cd01                	beqz	a0,8000175e <count_one_bits+0x1e>
    80001748:	87aa                	mv	a5,a0
  int count = 0;
    8000174a:	4501                	li	a0,0
      count += age & 1;
    8000174c:	0017f713          	andi	a4,a5,1
    80001750:	9d39                	addw	a0,a0,a4
      age >>= 1;
    80001752:	0017d79b          	srliw	a5,a5,0x1
  while(age) {
    80001756:	fbfd                	bnez	a5,8000174c <count_one_bits+0xc>
  }
  return count;
}
    80001758:	6422                	ld	s0,8(sp)
    8000175a:	0141                	addi	sp,sp,16
    8000175c:	8082                	ret
  int count = 0;
    8000175e:	4501                	li	a0,0
    80001760:	bfe5                	j	80001758 <count_one_bits+0x18>

0000000080001762 <minimum_ones>:

int minimum_ones(){
    80001762:	715d                	addi	sp,sp,-80
    80001764:	e486                	sd	ra,72(sp)
    80001766:	e0a2                	sd	s0,64(sp)
    80001768:	fc26                	sd	s1,56(sp)
    8000176a:	f84a                	sd	s2,48(sp)
    8000176c:	f44e                	sd	s3,40(sp)
    8000176e:	f052                	sd	s4,32(sp)
    80001770:	ec56                	sd	s5,24(sp)
    80001772:	e85a                	sd	s6,16(sp)
    80001774:	e45e                	sd	s7,8(sp)
    80001776:	e062                	sd	s8,0(sp)
    80001778:	0880                	addi	s0,sp,80
  struct proc * p = myproc();
    8000177a:	00001097          	auipc	ra,0x1
    8000177e:	c88080e7          	jalr	-888(ra) # 80002402 <myproc>
  int min_ones = -1;
  int min_age = -1;
  int index_page = -1;
  uint age;
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001782:	19850493          	addi	s1,a0,408
    80001786:	490d                	li	s2,3
  int index_page = -1;
    80001788:	5c7d                	li	s8,-1
  int min_age = -1;
    8000178a:	5bfd                	li	s7,-1
  int min_ones = -1;
    8000178c:	5a7d                	li	s4,-1
    if (p->paging_meta_data[i].in_memory ){
      age =  p->paging_meta_data[i].aging;
      int count_ones =  count_one_bits(age);
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    8000178e:	5b7d                	li	s6,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001790:	02000993          	li	s3,32
    80001794:	a809                	j	800017a6 <minimum_ones+0x44>
        min_ones = count_ones;
        min_age = age;
    80001796:	000a8b9b          	sext.w	s7,s5
    8000179a:	8c4a                	mv	s8,s2
        min_ones = count_ones;
    8000179c:	8a2a                	mv	s4,a0
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    8000179e:	2905                	addiw	s2,s2,1
    800017a0:	04b1                	addi	s1,s1,12
    800017a2:	03390663          	beq	s2,s3,800017ce <minimum_ones+0x6c>
    if (p->paging_meta_data[i].in_memory ){
    800017a6:	40dc                	lw	a5,4(s1)
    800017a8:	dbfd                	beqz	a5,8000179e <minimum_ones+0x3c>
      age =  p->paging_meta_data[i].aging;
    800017aa:	0004aa83          	lw	s5,0(s1)
      int count_ones =  count_one_bits(age);
    800017ae:	8556                	mv	a0,s5
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	f90080e7          	jalr	-112(ra) # 80001740 <count_one_bits>
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    800017b8:	fd6a0fe3          	beq	s4,s6,80001796 <minimum_ones+0x34>
    800017bc:	fd454de3          	blt	a0,s4,80001796 <minimum_ones+0x34>
    800017c0:	fd451fe3          	bne	a0,s4,8000179e <minimum_ones+0x3c>
    800017c4:	000b879b          	sext.w	a5,s7
    800017c8:	fcfafbe3          	bgeu	s5,a5,8000179e <minimum_ones+0x3c>
    800017cc:	b7e9                	j	80001796 <minimum_ones+0x34>
        index_page = i;
      }
    }
  }
  if(min_ones == -1)
    800017ce:	57fd                	li	a5,-1
    800017d0:	00fa0f63          	beq	s4,a5,800017ee <minimum_ones+0x8c>
    panic("page replacment algorithem failed");
  return index_page;
}
    800017d4:	8562                	mv	a0,s8
    800017d6:	60a6                	ld	ra,72(sp)
    800017d8:	6406                	ld	s0,64(sp)
    800017da:	74e2                	ld	s1,56(sp)
    800017dc:	7942                	ld	s2,48(sp)
    800017de:	79a2                	ld	s3,40(sp)
    800017e0:	7a02                	ld	s4,32(sp)
    800017e2:	6ae2                	ld	s5,24(sp)
    800017e4:	6b42                	ld	s6,16(sp)
    800017e6:	6ba2                	ld	s7,8(sp)
    800017e8:	6c02                	ld	s8,0(sp)
    800017ea:	6161                	addi	sp,sp,80
    800017ec:	8082                	ret
    panic("page replacment algorithem failed");
    800017ee:	00008517          	auipc	a0,0x8
    800017f2:	9ca50513          	addi	a0,a0,-1590 # 800091b8 <digits+0x178>
    800017f6:	fffff097          	auipc	ra,0xfffff
    800017fa:	d34080e7          	jalr	-716(ra) # 8000052a <panic>

00000000800017fe <insert_to_queue>:
uint64 insert_to_queue(int inserted_page){
    800017fe:	1101                	addi	sp,sp,-32
    80001800:	ec06                	sd	ra,24(sp)
    80001802:	e822                	sd	s0,16(sp)
    80001804:	e426                	sd	s1,8(sp)
    80001806:	1000                	addi	s0,sp,32
    80001808:	84aa                	mv	s1,a0
  struct proc * process = myproc();
    8000180a:	00001097          	auipc	ra,0x1
    8000180e:	bf8080e7          	jalr	-1032(ra) # 80002402 <myproc>
  struct age_queue * q = &process->queue;
  //if(inserted_page >= 3){
    if (q->last == 31)
    80001812:	37452703          	lw	a4,884(a0)
    80001816:	47fd                	li	a5,31
    80001818:	02f70863          	beq	a4,a5,80001848 <insert_to_queue+0x4a>
      q->last = -1;
    q->last = q->last + 1;
    8000181c:	37452703          	lw	a4,884(a0)
    80001820:	2705                	addiw	a4,a4,1
    80001822:	0007079b          	sext.w	a5,a4
    80001826:	36e52a23          	sw	a4,884(a0)
    q->pages[q->last] =inserted_page;
    8000182a:	078a                	slli	a5,a5,0x2
    8000182c:	97aa                	add	a5,a5,a0
    8000182e:	2e97a823          	sw	s1,752(a5)
    q->page_counter =  q->page_counter + 1;
    80001832:	37852783          	lw	a5,888(a0)
    80001836:	2785                	addiw	a5,a5,1
    80001838:	36f52c23          	sw	a5,888(a0)
 // }
  return 0;
}
    8000183c:	4501                	li	a0,0
    8000183e:	60e2                	ld	ra,24(sp)
    80001840:	6442                	ld	s0,16(sp)
    80001842:	64a2                	ld	s1,8(sp)
    80001844:	6105                	addi	sp,sp,32
    80001846:	8082                	ret
      q->last = -1;
    80001848:	57fd                	li	a5,-1
    8000184a:	36f52a23          	sw	a5,884(a0)
    8000184e:	b7f9                	j	8000181c <insert_to_queue+0x1e>

0000000080001850 <remove_from_queue>:

void remove_from_queue(struct age_queue * q){
    80001850:	1141                	addi	sp,sp,-16
    80001852:	e422                	sd	s0,8(sp)
    80001854:	0800                	addi	s0,sp,16
  q->front = q->front+1;
    80001856:	08052783          	lw	a5,128(a0)
    8000185a:	2785                	addiw	a5,a5,1
    8000185c:	0007869b          	sext.w	a3,a5
   if(q->front == 32) {
    80001860:	02000713          	li	a4,32
    80001864:	00e68c63          	beq	a3,a4,8000187c <remove_from_queue+0x2c>
  q->front = q->front+1;
    80001868:	08f52023          	sw	a5,128(a0)
      q->front = 0;
   }
   q->page_counter = q->page_counter-1;
    8000186c:	08852783          	lw	a5,136(a0)
    80001870:	37fd                	addiw	a5,a5,-1
    80001872:	08f52423          	sw	a5,136(a0)
   
}
    80001876:	6422                	ld	s0,8(sp)
    80001878:	0141                	addi	sp,sp,16
    8000187a:	8082                	ret
      q->front = 0;
    8000187c:	08052023          	sw	zero,128(a0)
    80001880:	b7f5                	j	8000186c <remove_from_queue+0x1c>

0000000080001882 <remove_from_queue_not_in_memory>:
void
remove_from_queue_not_in_memory(int page_num_removed){
    80001882:	7139                	addi	sp,sp,-64
    80001884:	fc06                	sd	ra,56(sp)
    80001886:	f822                	sd	s0,48(sp)
    80001888:	f426                	sd	s1,40(sp)
    8000188a:	f04a                	sd	s2,32(sp)
    8000188c:	ec4e                	sd	s3,24(sp)
    8000188e:	e852                	sd	s4,16(sp)
    80001890:	e456                	sd	s5,8(sp)
    80001892:	e05a                	sd	s6,0(sp)
    80001894:	0080                	addi	s0,sp,64
    80001896:	8a2a                	mv	s4,a0
  struct proc * p = myproc();
    80001898:	00001097          	auipc	ra,0x1
    8000189c:	b6a080e7          	jalr	-1174(ra) # 80002402 <myproc>
  struct age_queue * q = &(p->queue);
  int cur_page;
  int page_count = q->page_counter;
    800018a0:	37852a83          	lw	s5,888(a0)
  for(int i = 0; i<page_count; i++){
    800018a4:	03505d63          	blez	s5,800018de <remove_from_queue_not_in_memory+0x5c>
    800018a8:	892a                	mv	s2,a0
    800018aa:	2f050b13          	addi	s6,a0,752
    800018ae:	4481                	li	s1,0
    800018b0:	a021                	j	800018b8 <remove_from_queue_not_in_memory+0x36>
    800018b2:	2485                	addiw	s1,s1,1
    800018b4:	029a8563          	beq	s5,s1,800018de <remove_from_queue_not_in_memory+0x5c>
    cur_page = q->pages[q->front];
    800018b8:	37092783          	lw	a5,880(s2) # 1370 <_entry-0x7fffec90>
    800018bc:	078a                	slli	a5,a5,0x2
    800018be:	97ca                	add	a5,a5,s2
    800018c0:	2f07a983          	lw	s3,752(a5)
     remove_from_queue(q);
    800018c4:	855a                	mv	a0,s6
    800018c6:	00000097          	auipc	ra,0x0
    800018ca:	f8a080e7          	jalr	-118(ra) # 80001850 <remove_from_queue>
    if (!(page_num_removed == cur_page)){
    800018ce:	ff4982e3          	beq	s3,s4,800018b2 <remove_from_queue_not_in_memory+0x30>
     insert_to_queue(cur_page);
    800018d2:	854e                	mv	a0,s3
    800018d4:	00000097          	auipc	ra,0x0
    800018d8:	f2a080e7          	jalr	-214(ra) # 800017fe <insert_to_queue>
    800018dc:	bfd9                	j	800018b2 <remove_from_queue_not_in_memory+0x30>
    }
  }
}
    800018de:	70e2                	ld	ra,56(sp)
    800018e0:	7442                	ld	s0,48(sp)
    800018e2:	74a2                	ld	s1,40(sp)
    800018e4:	7902                	ld	s2,32(sp)
    800018e6:	69e2                	ld	s3,24(sp)
    800018e8:	6a42                	ld	s4,16(sp)
    800018ea:	6aa2                	ld	s5,8(sp)
    800018ec:	6b02                	ld	s6,0(sp)
    800018ee:	6121                	addi	sp,sp,64
    800018f0:	8082                	ret

00000000800018f2 <uvmunmap>:
{
    800018f2:	7159                	addi	sp,sp,-112
    800018f4:	f486                	sd	ra,104(sp)
    800018f6:	f0a2                	sd	s0,96(sp)
    800018f8:	eca6                	sd	s1,88(sp)
    800018fa:	e8ca                	sd	s2,80(sp)
    800018fc:	e4ce                	sd	s3,72(sp)
    800018fe:	e0d2                	sd	s4,64(sp)
    80001900:	fc56                	sd	s5,56(sp)
    80001902:	f85a                	sd	s6,48(sp)
    80001904:	f45e                	sd	s7,40(sp)
    80001906:	f062                	sd	s8,32(sp)
    80001908:	ec66                	sd	s9,24(sp)
    8000190a:	e86a                	sd	s10,16(sp)
    8000190c:	e46e                	sd	s11,8(sp)
    8000190e:	1880                	addi	s0,sp,112
  if((va % PGSIZE) != 0)
    80001910:	03459793          	slli	a5,a1,0x34
    80001914:	ef99                	bnez	a5,80001932 <uvmunmap+0x40>
    80001916:	8a2a                	mv	s4,a0
    80001918:	892e                	mv	s2,a1
    8000191a:	8b36                	mv	s6,a3
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    8000191c:	0632                	slli	a2,a2,0xc
    8000191e:	00b609b3          	add	s3,a2,a1
    80001922:	0d35f763          	bgeu	a1,s3,800019f0 <uvmunmap+0xfe>
            if(a/PGSIZE < 32){
    80001926:	00020bb7          	lui	s7,0x20
                myproc()->paging_meta_data[a/PGSIZE].offset = -1;
    8000192a:	5cfd                	li	s9,-1
        if(PTE_FLAGS(*pte) == PTE_V)
    8000192c:	4c05                	li	s8,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    8000192e:	6a85                	lui	s5,0x1
    80001930:	a805                	j	80001960 <uvmunmap+0x6e>
    panic("uvmunmap: not aligned");
    80001932:	00007517          	auipc	a0,0x7
    80001936:	7c650513          	addi	a0,a0,1990 # 800090f8 <digits+0xb8>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	bf0080e7          	jalr	-1040(ra) # 8000052a <panic>
          panic("uvmunmap: not a leaf");
    80001942:	00007517          	auipc	a0,0x7
    80001946:	7f650513          	addi	a0,a0,2038 # 80009138 <digits+0xf8>
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	be0080e7          	jalr	-1056(ra) # 8000052a <panic>
            if(a/PGSIZE < 32){
    80001952:	09796163          	bltu	s2,s7,800019d4 <uvmunmap+0xe2>
       *pte = 0; //even if not in memory we want to earase itf flag so won't even be PAGED_OUT
    80001956:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    8000195a:	9956                	add	s2,s2,s5
    8000195c:	09397a63          	bgeu	s2,s3,800019f0 <uvmunmap+0xfe>
    if((pte = walk(pagetable, a, 0)) != 0){
    80001960:	4601                	li	a2,0
    80001962:	85ca                	mv	a1,s2
    80001964:	8552                	mv	a0,s4
    80001966:	fffff097          	auipc	ra,0xfffff
    8000196a:	650080e7          	jalr	1616(ra) # 80000fb6 <walk>
    8000196e:	84aa                	mv	s1,a0
    80001970:	d56d                	beqz	a0,8000195a <uvmunmap+0x68>
      if((*pte & PTE_V) != 0){
    80001972:	611c                	ld	a5,0(a0)
    80001974:	0017f713          	andi	a4,a5,1
    80001978:	df69                	beqz	a4,80001952 <uvmunmap+0x60>
        if(PTE_FLAGS(*pte) == PTE_V)
    8000197a:	3ff7f713          	andi	a4,a5,1023
    8000197e:	fd8702e3          	beq	a4,s8,80001942 <uvmunmap+0x50>
        if(do_free){
    80001982:	fc0b0ae3          	beqz	s6,80001956 <uvmunmap+0x64>
          uint64 pa = PTE2PA(*pte);
    80001986:	83a9                	srli	a5,a5,0xa
          kfree((void*)pa);
    80001988:	00c79513          	slli	a0,a5,0xc
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	04a080e7          	jalr	74(ra) # 800009d6 <kfree>
            if(a/PGSIZE < 32){
    80001994:	fd7971e3          	bgeu	s2,s7,80001956 <uvmunmap+0x64>
              myproc()->paging_meta_data[a/PGSIZE].in_memory = 0;
    80001998:	00001097          	auipc	ra,0x1
    8000199c:	a6a080e7          	jalr	-1430(ra) # 80002402 <myproc>
    800019a0:	00c95d93          	srli	s11,s2,0xc
    800019a4:	001d9d13          	slli	s10,s11,0x1
    800019a8:	01bd07b3          	add	a5,s10,s11
    800019ac:	078a                	slli	a5,a5,0x2
    800019ae:	953e                	add	a0,a0,a5
    800019b0:	16052c23          	sw	zero,376(a0)
              myproc()->paging_meta_data[a/PGSIZE].offset = -1;
    800019b4:	00001097          	auipc	ra,0x1
    800019b8:	a4e080e7          	jalr	-1458(ra) # 80002402 <myproc>
    800019bc:	9d6e                	add	s10,s10,s11
    800019be:	0d0a                	slli	s10,s10,0x2
    800019c0:	9d2a                	add	s10,s10,a0
    800019c2:	179d2823          	sw	s9,368(s10)
              remove_from_queue_not_in_memory(a/PGSIZE);
    800019c6:	000d851b          	sext.w	a0,s11
    800019ca:	00000097          	auipc	ra,0x0
    800019ce:	eb8080e7          	jalr	-328(ra) # 80001882 <remove_from_queue_not_in_memory>
    800019d2:	b751                	j	80001956 <uvmunmap+0x64>
                myproc()->paging_meta_data[a/PGSIZE].offset = -1;
    800019d4:	00001097          	auipc	ra,0x1
    800019d8:	a2e080e7          	jalr	-1490(ra) # 80002402 <myproc>
    800019dc:	00c95713          	srli	a4,s2,0xc
    800019e0:	00171793          	slli	a5,a4,0x1
    800019e4:	97ba                	add	a5,a5,a4
    800019e6:	078a                	slli	a5,a5,0x2
    800019e8:	97aa                	add	a5,a5,a0
    800019ea:	1797a823          	sw	s9,368(a5)
    800019ee:	b7a5                	j	80001956 <uvmunmap+0x64>
}
    800019f0:	70a6                	ld	ra,104(sp)
    800019f2:	7406                	ld	s0,96(sp)
    800019f4:	64e6                	ld	s1,88(sp)
    800019f6:	6946                	ld	s2,80(sp)
    800019f8:	69a6                	ld	s3,72(sp)
    800019fa:	6a06                	ld	s4,64(sp)
    800019fc:	7ae2                	ld	s5,56(sp)
    800019fe:	7b42                	ld	s6,48(sp)
    80001a00:	7ba2                	ld	s7,40(sp)
    80001a02:	7c02                	ld	s8,32(sp)
    80001a04:	6ce2                	ld	s9,24(sp)
    80001a06:	6d42                	ld	s10,16(sp)
    80001a08:	6da2                	ld	s11,8(sp)
    80001a0a:	6165                	addi	sp,sp,112
    80001a0c:	8082                	ret

0000000080001a0e <uvmdealloc>:
{
    80001a0e:	1101                	addi	sp,sp,-32
    80001a10:	ec06                	sd	ra,24(sp)
    80001a12:	e822                	sd	s0,16(sp)
    80001a14:	e426                	sd	s1,8(sp)
    80001a16:	1000                	addi	s0,sp,32
    return oldsz;
    80001a18:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001a1a:	00b67d63          	bgeu	a2,a1,80001a34 <uvmdealloc+0x26>
    80001a1e:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001a20:	6785                	lui	a5,0x1
    80001a22:	17fd                	addi	a5,a5,-1
    80001a24:	00f60733          	add	a4,a2,a5
    80001a28:	767d                	lui	a2,0xfffff
    80001a2a:	8f71                	and	a4,a4,a2
    80001a2c:	97ae                	add	a5,a5,a1
    80001a2e:	8ff1                	and	a5,a5,a2
    80001a30:	00f76863          	bltu	a4,a5,80001a40 <uvmdealloc+0x32>
}
    80001a34:	8526                	mv	a0,s1
    80001a36:	60e2                	ld	ra,24(sp)
    80001a38:	6442                	ld	s0,16(sp)
    80001a3a:	64a2                	ld	s1,8(sp)
    80001a3c:	6105                	addi	sp,sp,32
    80001a3e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001a40:	8f99                	sub	a5,a5,a4
    80001a42:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001a44:	4685                	li	a3,1
    80001a46:	0007861b          	sext.w	a2,a5
    80001a4a:	85ba                	mv	a1,a4
    80001a4c:	00000097          	auipc	ra,0x0
    80001a50:	ea6080e7          	jalr	-346(ra) # 800018f2 <uvmunmap>
    80001a54:	b7c5                	j	80001a34 <uvmdealloc+0x26>

0000000080001a56 <origin_uvmalloc>:
  if(newsz < oldsz)
    80001a56:	0ab66163          	bltu	a2,a1,80001af8 <origin_uvmalloc+0xa2>
origin_uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz){
    80001a5a:	7139                	addi	sp,sp,-64
    80001a5c:	fc06                	sd	ra,56(sp)
    80001a5e:	f822                	sd	s0,48(sp)
    80001a60:	f426                	sd	s1,40(sp)
    80001a62:	f04a                	sd	s2,32(sp)
    80001a64:	ec4e                	sd	s3,24(sp)
    80001a66:	e852                	sd	s4,16(sp)
    80001a68:	e456                	sd	s5,8(sp)
    80001a6a:	0080                	addi	s0,sp,64
    80001a6c:	8aaa                	mv	s5,a0
    80001a6e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001a70:	6985                	lui	s3,0x1
    80001a72:	19fd                	addi	s3,s3,-1
    80001a74:	95ce                	add	a1,a1,s3
    80001a76:	79fd                	lui	s3,0xfffff
    80001a78:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001a7c:	08c9f063          	bgeu	s3,a2,80001afc <origin_uvmalloc+0xa6>
    80001a80:	894e                	mv	s2,s3
      mem = kalloc();
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	060080e7          	jalr	96(ra) # 80000ae2 <kalloc>
    80001a8a:	84aa                	mv	s1,a0
      if(mem == 0){
    80001a8c:	c51d                	beqz	a0,80001aba <origin_uvmalloc+0x64>
      memset(mem, 0, PGSIZE);
    80001a8e:	6605                	lui	a2,0x1
    80001a90:	4581                	li	a1,0
    80001a92:	fffff097          	auipc	ra,0xfffff
    80001a96:	23c080e7          	jalr	572(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001a9a:	4779                	li	a4,30
    80001a9c:	86a6                	mv	a3,s1
    80001a9e:	6605                	lui	a2,0x1
    80001aa0:	85ca                	mv	a1,s2
    80001aa2:	8556                	mv	a0,s5
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	5e4080e7          	jalr	1508(ra) # 80001088 <mappages>
    80001aac:	e905                	bnez	a0,80001adc <origin_uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001aae:	6785                	lui	a5,0x1
    80001ab0:	993e                	add	s2,s2,a5
    80001ab2:	fd4968e3          	bltu	s2,s4,80001a82 <origin_uvmalloc+0x2c>
  return newsz;
    80001ab6:	8552                	mv	a0,s4
    80001ab8:	a809                	j	80001aca <origin_uvmalloc+0x74>
        uvmdealloc(pagetable, a, oldsz);
    80001aba:	864e                	mv	a2,s3
    80001abc:	85ca                	mv	a1,s2
    80001abe:	8556                	mv	a0,s5
    80001ac0:	00000097          	auipc	ra,0x0
    80001ac4:	f4e080e7          	jalr	-178(ra) # 80001a0e <uvmdealloc>
        return 0;
    80001ac8:	4501                	li	a0,0
}
    80001aca:	70e2                	ld	ra,56(sp)
    80001acc:	7442                	ld	s0,48(sp)
    80001ace:	74a2                	ld	s1,40(sp)
    80001ad0:	7902                	ld	s2,32(sp)
    80001ad2:	69e2                	ld	s3,24(sp)
    80001ad4:	6a42                	ld	s4,16(sp)
    80001ad6:	6aa2                	ld	s5,8(sp)
    80001ad8:	6121                	addi	sp,sp,64
    80001ada:	8082                	ret
        kfree(mem);
    80001adc:	8526                	mv	a0,s1
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	ef8080e7          	jalr	-264(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    80001ae6:	864e                	mv	a2,s3
    80001ae8:	85ca                	mv	a1,s2
    80001aea:	8556                	mv	a0,s5
    80001aec:	00000097          	auipc	ra,0x0
    80001af0:	f22080e7          	jalr	-222(ra) # 80001a0e <uvmdealloc>
        return 0;
    80001af4:	4501                	li	a0,0
    80001af6:	bfd1                	j	80001aca <origin_uvmalloc+0x74>
    return oldsz;
    80001af8:	852e                	mv	a0,a1
}
    80001afa:	8082                	ret
  return newsz;
    80001afc:	8532                	mv	a0,a2
    80001afe:	b7f1                	j	80001aca <origin_uvmalloc+0x74>

0000000080001b00 <uvmalloc>:
  if(newsz < oldsz)
    80001b00:	18b66563          	bltu	a2,a1,80001c8a <uvmalloc+0x18a>
{
    80001b04:	711d                	addi	sp,sp,-96
    80001b06:	ec86                	sd	ra,88(sp)
    80001b08:	e8a2                	sd	s0,80(sp)
    80001b0a:	e4a6                	sd	s1,72(sp)
    80001b0c:	e0ca                	sd	s2,64(sp)
    80001b0e:	fc4e                	sd	s3,56(sp)
    80001b10:	f852                	sd	s4,48(sp)
    80001b12:	f456                	sd	s5,40(sp)
    80001b14:	f05a                	sd	s6,32(sp)
    80001b16:	ec5e                	sd	s7,24(sp)
    80001b18:	e862                	sd	s8,16(sp)
    80001b1a:	e466                	sd	s9,8(sp)
    80001b1c:	e06a                	sd	s10,0(sp)
    80001b1e:	1080                	addi	s0,sp,96
    80001b20:	89aa                	mv	s3,a0
    80001b22:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001b24:	6b85                	lui	s7,0x1
    80001b26:	1bfd                	addi	s7,s7,-1
    80001b28:	95de                	add	a1,a1,s7
    80001b2a:	7bfd                	lui	s7,0xfffff
    80001b2c:	0175fbb3          	and	s7,a1,s7
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b30:	14cbff63          	bgeu	s7,a2,80001c8e <uvmalloc+0x18e>
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b34:	000217b7          	lui	a5,0x21
    80001b38:	00fbf863          	bgeu	s7,a5,80001b48 <uvmalloc+0x48>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b3c:	84de                	mv	s1,s7
     if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80001b3e:	4abd                	li	s5,15
      myproc()->paging_meta_data[a/PGSIZE].in_memory = 1;
    80001b40:	4c05                	li	s8,1
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b42:	00021b37          	lui	s6,0x21
    80001b46:	a8a1                	j	80001b9e <uvmalloc+0x9e>
      panic("more than 32 pages");
    80001b48:	00007517          	auipc	a0,0x7
    80001b4c:	69850513          	addi	a0,a0,1688 # 800091e0 <digits+0x1a0>
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	9da080e7          	jalr	-1574(ra) # 8000052a <panic>
      pte = walk(pagetable, a, 0);
    80001b58:	4601                	li	a2,0
    80001b5a:	85a6                	mv	a1,s1
    80001b5c:	854e                	mv	a0,s3
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	458080e7          	jalr	1112(ra) # 80000fb6 <walk>
      *pte = *pte & (~PTE_V);
    80001b66:	611c                	ld	a5,0(a0)
    80001b68:	9bf9                	andi	a5,a5,-2
    80001b6a:	e11c                	sd	a5,0(a0)
      int offset = find_min_empty_offset();
    80001b6c:	00000097          	auipc	ra,0x0
    80001b70:	834080e7          	jalr	-1996(ra) # 800013a0 <find_min_empty_offset>
    80001b74:	0005091b          	sext.w	s2,a0
      myproc()->paging_meta_data[a/PGSIZE].offset = offset;
    80001b78:	00001097          	auipc	ra,0x1
    80001b7c:	88a080e7          	jalr	-1910(ra) # 80002402 <myproc>
    80001b80:	00c4d713          	srli	a4,s1,0xc
    80001b84:	00171793          	slli	a5,a4,0x1
    80001b88:	97ba                	add	a5,a5,a4
    80001b8a:	078a                	slli	a5,a5,0x2
    80001b8c:	97aa                	add	a5,a5,a0
    80001b8e:	1727a823          	sw	s2,368(a5) # 21170 <_entry-0x7ffdee90>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b92:	6785                	lui	a5,0x1
    80001b94:	94be                	add	s1,s1,a5
    80001b96:	0d44fb63          	bgeu	s1,s4,80001c6c <uvmalloc+0x16c>
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b9a:	fb64f7e3          	bgeu	s1,s6,80001b48 <uvmalloc+0x48>
     if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80001b9e:	00000097          	auipc	ra,0x0
    80001ba2:	aba080e7          	jalr	-1350(ra) # 80001658 <get_num_of_pages_in_memory>
    80001ba6:	02aad763          	bge	s5,a0,80001bd4 <uvmalloc+0xd4>
       if(mappages(pagetable, a, PGSIZE, 0, PTE_W|PTE_R|PTE_X|PTE_U|PTE_PG) < 0) {
    80001baa:	41e00713          	li	a4,1054
    80001bae:	4681                	li	a3,0
    80001bb0:	6605                	lui	a2,0x1
    80001bb2:	85a6                	mv	a1,s1
    80001bb4:	854e                	mv	a0,s3
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	4d2080e7          	jalr	1234(ra) # 80001088 <mappages>
    80001bbe:	f8055de3          	bgez	a0,80001b58 <uvmalloc+0x58>
         uvmdealloc(pagetable, newsz, oldsz);
    80001bc2:	865e                	mv	a2,s7
    80001bc4:	85d2                	mv	a1,s4
    80001bc6:	854e                	mv	a0,s3
    80001bc8:	00000097          	auipc	ra,0x0
    80001bcc:	e46080e7          	jalr	-442(ra) # 80001a0e <uvmdealloc>
         return 0;
    80001bd0:	4501                	li	a0,0
    80001bd2:	a871                	j	80001c6e <uvmalloc+0x16e>
      mem = kalloc();
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	f0e080e7          	jalr	-242(ra) # 80000ae2 <kalloc>
    80001bdc:	892a                	mv	s2,a0
      if(mem == 0){
    80001bde:	c125                	beqz	a0,80001c3e <uvmalloc+0x13e>
      memset(mem, 0, PGSIZE);
    80001be0:	6605                	lui	a2,0x1
    80001be2:	4581                	li	a1,0
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	0ea080e7          	jalr	234(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001bec:	4779                	li	a4,30
    80001bee:	86ca                	mv	a3,s2
    80001bf0:	6605                	lui	a2,0x1
    80001bf2:	85a6                	mv	a1,s1
    80001bf4:	854e                	mv	a0,s3
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	492080e7          	jalr	1170(ra) # 80001088 <mappages>
    80001bfe:	e929                	bnez	a0,80001c50 <uvmalloc+0x150>
      myproc()->paging_meta_data[a/PGSIZE].in_memory = 1;
    80001c00:	00001097          	auipc	ra,0x1
    80001c04:	802080e7          	jalr	-2046(ra) # 80002402 <myproc>
    80001c08:	00c4dd13          	srli	s10,s1,0xc
    80001c0c:	001d1913          	slli	s2,s10,0x1
    80001c10:	01a907b3          	add	a5,s2,s10
    80001c14:	078a                	slli	a5,a5,0x2
    80001c16:	953e                	add	a0,a0,a5
    80001c18:	17852c23          	sw	s8,376(a0)
      myproc()->paging_meta_data[a/PGSIZE].aging = init_aging(a/PGSIZE);
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	7e6080e7          	jalr	2022(ra) # 80002402 <myproc>
    80001c24:	8caa                	mv	s9,a0
  #endif
  #if SELECTION == LAPA
    return LAPA_AGE;
  #endif
  #if SELECTION==SCFIFO
    return insert_to_queue(fifo_init_pages);
    80001c26:	000d051b          	sext.w	a0,s10
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	bd4080e7          	jalr	-1068(ra) # 800017fe <insert_to_queue>
      myproc()->paging_meta_data[a/PGSIZE].aging = init_aging(a/PGSIZE);
    80001c32:	996a                	add	s2,s2,s10
    80001c34:	090a                	slli	s2,s2,0x2
    80001c36:	9966                	add	s2,s2,s9
    return insert_to_queue(fifo_init_pages);
    80001c38:	16a92a23          	sw	a0,372(s2)
    80001c3c:	bf99                	j	80001b92 <uvmalloc+0x92>
        uvmdealloc(pagetable, a, oldsz);
    80001c3e:	865e                	mv	a2,s7
    80001c40:	85a6                	mv	a1,s1
    80001c42:	854e                	mv	a0,s3
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	dca080e7          	jalr	-566(ra) # 80001a0e <uvmdealloc>
        return 0;
    80001c4c:	4501                	li	a0,0
    80001c4e:	a005                	j	80001c6e <uvmalloc+0x16e>
        kfree(mem);
    80001c50:	854a                	mv	a0,s2
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	d84080e7          	jalr	-636(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    80001c5a:	865e                	mv	a2,s7
    80001c5c:	85a6                	mv	a1,s1
    80001c5e:	854e                	mv	a0,s3
    80001c60:	00000097          	auipc	ra,0x0
    80001c64:	dae080e7          	jalr	-594(ra) # 80001a0e <uvmdealloc>
        return 0;
    80001c68:	4501                	li	a0,0
    80001c6a:	a011                	j	80001c6e <uvmalloc+0x16e>
  return newsz;
    80001c6c:	8552                	mv	a0,s4
}
    80001c6e:	60e6                	ld	ra,88(sp)
    80001c70:	6446                	ld	s0,80(sp)
    80001c72:	64a6                	ld	s1,72(sp)
    80001c74:	6906                	ld	s2,64(sp)
    80001c76:	79e2                	ld	s3,56(sp)
    80001c78:	7a42                	ld	s4,48(sp)
    80001c7a:	7aa2                	ld	s5,40(sp)
    80001c7c:	7b02                	ld	s6,32(sp)
    80001c7e:	6be2                	ld	s7,24(sp)
    80001c80:	6c42                	ld	s8,16(sp)
    80001c82:	6ca2                	ld	s9,8(sp)
    80001c84:	6d02                	ld	s10,0(sp)
    80001c86:	6125                	addi	sp,sp,96
    80001c88:	8082                	ret
    return oldsz;
    80001c8a:	852e                	mv	a0,a1
}
    80001c8c:	8082                	ret
  return newsz;
    80001c8e:	8532                	mv	a0,a2
    80001c90:	bff9                	j	80001c6e <uvmalloc+0x16e>

0000000080001c92 <lazy_memory_allocation>:
void lazy_memory_allocation(uint64 faulting_address){
    80001c92:	1101                	addi	sp,sp,-32
    80001c94:	ec06                	sd	ra,24(sp)
    80001c96:	e822                	sd	s0,16(sp)
    80001c98:	e426                	sd	s1,8(sp)
    80001c9a:	1000                	addi	s0,sp,32
    80001c9c:	84aa                	mv	s1,a0
  uvmalloc(myproc()->pagetable,PGROUNDDOWN(faulting_address), PGROUNDDOWN(faulting_address) + PGSIZE);     
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	764080e7          	jalr	1892(ra) # 80002402 <myproc>
    80001ca6:	75fd                	lui	a1,0xfffff
    80001ca8:	8de5                	and	a1,a1,s1
    80001caa:	6605                	lui	a2,0x1
    80001cac:	962e                	add	a2,a2,a1
    80001cae:	6928                	ld	a0,80(a0)
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	e50080e7          	jalr	-432(ra) # 80001b00 <uvmalloc>
}
    80001cb8:	60e2                	ld	ra,24(sp)
    80001cba:	6442                	ld	s0,16(sp)
    80001cbc:	64a2                	ld	s1,8(sp)
    80001cbe:	6105                	addi	sp,sp,32
    80001cc0:	8082                	ret

0000000080001cc2 <uvmfree>:
{
    80001cc2:	1101                	addi	sp,sp,-32
    80001cc4:	ec06                	sd	ra,24(sp)
    80001cc6:	e822                	sd	s0,16(sp)
    80001cc8:	e426                	sd	s1,8(sp)
    80001cca:	1000                	addi	s0,sp,32
    80001ccc:	84aa                	mv	s1,a0
  if(sz > 0)
    80001cce:	e999                	bnez	a1,80001ce4 <uvmfree+0x22>
  freewalk(pagetable);
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	71c080e7          	jalr	1820(ra) # 800013ee <freewalk>
}
    80001cda:	60e2                	ld	ra,24(sp)
    80001cdc:	6442                	ld	s0,16(sp)
    80001cde:	64a2                	ld	s1,8(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001ce4:	6605                	lui	a2,0x1
    80001ce6:	167d                	addi	a2,a2,-1
    80001ce8:	962e                	add	a2,a2,a1
    80001cea:	4685                	li	a3,1
    80001cec:	8231                	srli	a2,a2,0xc
    80001cee:	4581                	li	a1,0
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	c02080e7          	jalr	-1022(ra) # 800018f2 <uvmunmap>
    80001cf8:	bfe1                	j	80001cd0 <uvmfree+0xe>

0000000080001cfa <origin_uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){
    80001cfa:	c679                	beqz	a2,80001dc8 <origin_uvmcopy+0xce>
int origin_uvmcopy(pagetable_t old, pagetable_t new, uint64 sz){
    80001cfc:	715d                	addi	sp,sp,-80
    80001cfe:	e486                	sd	ra,72(sp)
    80001d00:	e0a2                	sd	s0,64(sp)
    80001d02:	fc26                	sd	s1,56(sp)
    80001d04:	f84a                	sd	s2,48(sp)
    80001d06:	f44e                	sd	s3,40(sp)
    80001d08:	f052                	sd	s4,32(sp)
    80001d0a:	ec56                	sd	s5,24(sp)
    80001d0c:	e85a                	sd	s6,16(sp)
    80001d0e:	e45e                	sd	s7,8(sp)
    80001d10:	0880                	addi	s0,sp,80
    80001d12:	8b2a                	mv	s6,a0
    80001d14:	8aae                	mv	s5,a1
    80001d16:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001d18:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001d1a:	4601                	li	a2,0
    80001d1c:	85ce                	mv	a1,s3
    80001d1e:	855a                	mv	a0,s6
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	296080e7          	jalr	662(ra) # 80000fb6 <walk>
    80001d28:	c531                	beqz	a0,80001d74 <origin_uvmcopy+0x7a>
    if((*pte & PTE_V) == 0)
    80001d2a:	6118                	ld	a4,0(a0)
    80001d2c:	00177793          	andi	a5,a4,1
    80001d30:	cbb1                	beqz	a5,80001d84 <origin_uvmcopy+0x8a>
    pa = PTE2PA(*pte);
    80001d32:	00a75593          	srli	a1,a4,0xa
    80001d36:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001d3a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	da4080e7          	jalr	-604(ra) # 80000ae2 <kalloc>
    80001d46:	892a                	mv	s2,a0
    80001d48:	c939                	beqz	a0,80001d9e <origin_uvmcopy+0xa4>
    memmove(mem, (char*)pa, PGSIZE);
    80001d4a:	6605                	lui	a2,0x1
    80001d4c:	85de                	mv	a1,s7
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	fdc080e7          	jalr	-36(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001d56:	8726                	mv	a4,s1
    80001d58:	86ca                	mv	a3,s2
    80001d5a:	6605                	lui	a2,0x1
    80001d5c:	85ce                	mv	a1,s3
    80001d5e:	8556                	mv	a0,s5
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	328080e7          	jalr	808(ra) # 80001088 <mappages>
    80001d68:	e515                	bnez	a0,80001d94 <origin_uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001d6a:	6785                	lui	a5,0x1
    80001d6c:	99be                	add	s3,s3,a5
    80001d6e:	fb49e6e3          	bltu	s3,s4,80001d1a <origin_uvmcopy+0x20>
    80001d72:	a081                	j	80001db2 <origin_uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001d74:	00007517          	auipc	a0,0x7
    80001d78:	48450513          	addi	a0,a0,1156 # 800091f8 <digits+0x1b8>
    80001d7c:	ffffe097          	auipc	ra,0xffffe
    80001d80:	7ae080e7          	jalr	1966(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001d84:	00007517          	auipc	a0,0x7
    80001d88:	49450513          	addi	a0,a0,1172 # 80009218 <digits+0x1d8>
    80001d8c:	ffffe097          	auipc	ra,0xffffe
    80001d90:	79e080e7          	jalr	1950(ra) # 8000052a <panic>
      kfree(mem);
    80001d94:	854a                	mv	a0,s2
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	c40080e7          	jalr	-960(ra) # 800009d6 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001d9e:	4685                	li	a3,1
    80001da0:	00c9d613          	srli	a2,s3,0xc
    80001da4:	4581                	li	a1,0
    80001da6:	8556                	mv	a0,s5
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	b4a080e7          	jalr	-1206(ra) # 800018f2 <uvmunmap>
  return -1;
    80001db0:	557d                	li	a0,-1
}
    80001db2:	60a6                	ld	ra,72(sp)
    80001db4:	6406                	ld	s0,64(sp)
    80001db6:	74e2                	ld	s1,56(sp)
    80001db8:	7942                	ld	s2,48(sp)
    80001dba:	79a2                	ld	s3,40(sp)
    80001dbc:	7a02                	ld	s4,32(sp)
    80001dbe:	6ae2                	ld	s5,24(sp)
    80001dc0:	6b42                	ld	s6,16(sp)
    80001dc2:	6ba2                	ld	s7,8(sp)
    80001dc4:	6161                	addi	sp,sp,80
    80001dc6:	8082                	ret
  return 0;
    80001dc8:	4501                	li	a0,0
}
    80001dca:	8082                	ret

0000000080001dcc <uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){    
    80001dcc:	ca4d                	beqz	a2,80001e7e <uvmcopy+0xb2>
{
    80001dce:	715d                	addi	sp,sp,-80
    80001dd0:	e486                	sd	ra,72(sp)
    80001dd2:	e0a2                	sd	s0,64(sp)
    80001dd4:	fc26                	sd	s1,56(sp)
    80001dd6:	f84a                	sd	s2,48(sp)
    80001dd8:	f44e                	sd	s3,40(sp)
    80001dda:	f052                	sd	s4,32(sp)
    80001ddc:	ec56                	sd	s5,24(sp)
    80001dde:	e85a                	sd	s6,16(sp)
    80001de0:	e45e                	sd	s7,8(sp)
    80001de2:	0880                	addi	s0,sp,80
    80001de4:	8aaa                	mv	s5,a0
    80001de6:	8b2e                	mv	s6,a1
    80001de8:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){    
    80001dea:	4481                	li	s1,0
    80001dec:	a029                	j	80001df6 <uvmcopy+0x2a>
    80001dee:	6785                	lui	a5,0x1
    80001df0:	94be                	add	s1,s1,a5
    80001df2:	0744fa63          	bgeu	s1,s4,80001e66 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) !=0 && (*pte & PTE_V) != 0){
    80001df6:	4601                	li	a2,0
    80001df8:	85a6                	mv	a1,s1
    80001dfa:	8556                	mv	a0,s5
    80001dfc:	fffff097          	auipc	ra,0xfffff
    80001e00:	1ba080e7          	jalr	442(ra) # 80000fb6 <walk>
    80001e04:	d56d                	beqz	a0,80001dee <uvmcopy+0x22>
    80001e06:	6118                	ld	a4,0(a0)
    80001e08:	00177793          	andi	a5,a4,1
    80001e0c:	d3ed                	beqz	a5,80001dee <uvmcopy+0x22>
      pa = PTE2PA(*pte);
    80001e0e:	00a75593          	srli	a1,a4,0xa
    80001e12:	00c59b93          	slli	s7,a1,0xc
      flags = PTE_FLAGS(*pte);
    80001e16:	3ff77913          	andi	s2,a4,1023
      if((mem = kalloc()) == 0)
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	cc8080e7          	jalr	-824(ra) # 80000ae2 <kalloc>
    80001e22:	89aa                	mv	s3,a0
    80001e24:	c515                	beqz	a0,80001e50 <uvmcopy+0x84>
      memmove(mem, (char*)pa, PGSIZE);
    80001e26:	6605                	lui	a2,0x1
    80001e28:	85de                	mv	a1,s7
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	f00080e7          	jalr	-256(ra) # 80000d2a <memmove>
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001e32:	874a                	mv	a4,s2
    80001e34:	86ce                	mv	a3,s3
    80001e36:	6605                	lui	a2,0x1
    80001e38:	85a6                	mv	a1,s1
    80001e3a:	855a                	mv	a0,s6
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	24c080e7          	jalr	588(ra) # 80001088 <mappages>
    80001e44:	d54d                	beqz	a0,80001dee <uvmcopy+0x22>
        kfree(mem);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	b8e080e7          	jalr	-1138(ra) # 800009d6 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001e50:	4685                	li	a3,1
    80001e52:	00c4d613          	srli	a2,s1,0xc
    80001e56:	4581                	li	a1,0
    80001e58:	855a                	mv	a0,s6
    80001e5a:	00000097          	auipc	ra,0x0
    80001e5e:	a98080e7          	jalr	-1384(ra) # 800018f2 <uvmunmap>
  return -1;
    80001e62:	557d                	li	a0,-1
    80001e64:	a011                	j	80001e68 <uvmcopy+0x9c>
  return 0;
    80001e66:	4501                	li	a0,0
}
    80001e68:	60a6                	ld	ra,72(sp)
    80001e6a:	6406                	ld	s0,64(sp)
    80001e6c:	74e2                	ld	s1,56(sp)
    80001e6e:	7942                	ld	s2,48(sp)
    80001e70:	79a2                	ld	s3,40(sp)
    80001e72:	7a02                	ld	s4,32(sp)
    80001e74:	6ae2                	ld	s5,24(sp)
    80001e76:	6b42                	ld	s6,16(sp)
    80001e78:	6ba2                	ld	s7,8(sp)
    80001e7a:	6161                	addi	sp,sp,80
    80001e7c:	8082                	ret
  return 0;
    80001e7e:	4501                	li	a0,0
}
    80001e80:	8082                	ret

0000000080001e82 <second_fifo>:
int second_fifo(){
    80001e82:	7139                	addi	sp,sp,-64
    80001e84:	fc06                	sd	ra,56(sp)
    80001e86:	f822                	sd	s0,48(sp)
    80001e88:	f426                	sd	s1,40(sp)
    80001e8a:	f04a                	sd	s2,32(sp)
    80001e8c:	ec4e                	sd	s3,24(sp)
    80001e8e:	e852                	sd	s4,16(sp)
    80001e90:	e456                	sd	s5,8(sp)
    80001e92:	e05a                	sd	s6,0(sp)
    80001e94:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001e96:	00000097          	auipc	ra,0x0
    80001e9a:	56c080e7          	jalr	1388(ra) # 80002402 <myproc>
    80001e9e:	84aa                	mv	s1,a0
  struct age_queue * q = &(p->queue);
    80001ea0:	2f050993          	addi	s3,a0,752
  int page_counter = q->page_counter;
    80001ea4:	37852a03          	lw	s4,888(a0)
  for (int i = 0; i<page_counter; i++){
    80001ea8:	05405f63          	blez	s4,80001f06 <second_fifo+0x84>
    80001eac:	4901                	li	s2,0
      printf("removing accsesed bit from %d\n", current_page);
    80001eae:	00007a97          	auipc	s5,0x7
    80001eb2:	3a2a8a93          	addi	s5,s5,930 # 80009250 <digits+0x210>
    current_page = q->pages[q->front];
    80001eb6:	3704a783          	lw	a5,880(s1)
    80001eba:	078a                	slli	a5,a5,0x2
    80001ebc:	97a6                	add	a5,a5,s1
    80001ebe:	2f07ab03          	lw	s6,752(a5) # 12f0 <_entry-0x7fffed10>
    pte_t * pte = walk(p->pagetable, current_page*PGSIZE,0);
    80001ec2:	4601                	li	a2,0
    80001ec4:	00cb159b          	slliw	a1,s6,0xc
    80001ec8:	68a8                	ld	a0,80(s1)
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	0ec080e7          	jalr	236(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001ed2:	611c                	ld	a5,0(a0)
    if(!(pte_flags & PTE_A)){
    80001ed4:	0407f713          	andi	a4,a5,64
    80001ed8:	cf29                	beqz	a4,80001f32 <second_fifo+0xb0>
      *pte = *pte & (~PTE_A); //make A bit off
    80001eda:	fbf7f793          	andi	a5,a5,-65
    80001ede:	e11c                	sd	a5,0(a0)
      printf("removing accsesed bit from %d\n", current_page);
    80001ee0:	85da                	mv	a1,s6
    80001ee2:	8556                	mv	a0,s5
    80001ee4:	ffffe097          	auipc	ra,0xffffe
    80001ee8:	690080e7          	jalr	1680(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001eec:	854e                	mv	a0,s3
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	962080e7          	jalr	-1694(ra) # 80001850 <remove_from_queue>
      insert_to_queue(current_page);
    80001ef6:	855a                	mv	a0,s6
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	906080e7          	jalr	-1786(ra) # 800017fe <insert_to_queue>
  for (int i = 0; i<page_counter; i++){
    80001f00:	2905                	addiw	s2,s2,1
    80001f02:	fb2a1ae3          	bne	s4,s2,80001eb6 <second_fifo+0x34>
  current_page = q->pages[q->front];
    80001f06:	3704a783          	lw	a5,880(s1)
    80001f0a:	078a                	slli	a5,a5,0x2
    80001f0c:	94be                	add	s1,s1,a5
    80001f0e:	2f04ab03          	lw	s6,752(s1)
  remove_from_queue(q);
    80001f12:	854e                	mv	a0,s3
    80001f14:	00000097          	auipc	ra,0x0
    80001f18:	93c080e7          	jalr	-1732(ra) # 80001850 <remove_from_queue>
}
    80001f1c:	855a                	mv	a0,s6
    80001f1e:	70e2                	ld	ra,56(sp)
    80001f20:	7442                	ld	s0,48(sp)
    80001f22:	74a2                	ld	s1,40(sp)
    80001f24:	7902                	ld	s2,32(sp)
    80001f26:	69e2                	ld	s3,24(sp)
    80001f28:	6a42                	ld	s4,16(sp)
    80001f2a:	6aa2                	ld	s5,8(sp)
    80001f2c:	6b02                	ld	s6,0(sp)
    80001f2e:	6121                	addi	sp,sp,64
    80001f30:	8082                	ret
      printf("not accsesed %d \n", current_page);
    80001f32:	85da                	mv	a1,s6
    80001f34:	00007517          	auipc	a0,0x7
    80001f38:	30450513          	addi	a0,a0,772 # 80009238 <digits+0x1f8>
    80001f3c:	ffffe097          	auipc	ra,0xffffe
    80001f40:	638080e7          	jalr	1592(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001f44:	854e                	mv	a0,s3
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	90a080e7          	jalr	-1782(ra) # 80001850 <remove_from_queue>
      return current_page; //the file will no longer be in the memory and will be removed next time
    80001f4e:	b7f9                	j	80001f1c <second_fifo+0x9a>

0000000080001f50 <swap_page_into_file>:
void swap_page_into_file(int offset){
    80001f50:	7139                	addi	sp,sp,-64
    80001f52:	fc06                	sd	ra,56(sp)
    80001f54:	f822                	sd	s0,48(sp)
    80001f56:	f426                	sd	s1,40(sp)
    80001f58:	f04a                	sd	s2,32(sp)
    80001f5a:	ec4e                	sd	s3,24(sp)
    80001f5c:	e852                	sd	s4,16(sp)
    80001f5e:	e456                	sd	s5,8(sp)
    80001f60:	0080                	addi	s0,sp,64
    80001f62:	8aaa                	mv	s5,a0
    struct proc * p = myproc();
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	49e080e7          	jalr	1182(ra) # 80002402 <myproc>
    80001f6c:	84aa                	mv	s1,a0
    return second_fifo(); 
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	f14080e7          	jalr	-236(ra) # 80001e82 <second_fifo>
    80001f76:	89aa                	mv	s3,a0
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    80001f78:	4601                	li	a2,0
    80001f7a:	00c5159b          	slliw	a1,a0,0xc
    80001f7e:	68a8                	ld	a0,80(s1)
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	036080e7          	jalr	54(ra) # 80000fb6 <walk>
    80001f88:	8a2a                	mv	s4,a0
    uint64 physical_addr = PTE2PA(*out_page_entry);
    80001f8a:	00053903          	ld	s2,0(a0)
    80001f8e:	00a95913          	srli	s2,s2,0xa
    80001f92:	0932                	slli	s2,s2,0xc
    printf("Chosen page %d. Data in chosen page is %s\n", remove_file_indx, physical_addr);
    80001f94:	864a                	mv	a2,s2
    80001f96:	85ce                	mv	a1,s3
    80001f98:	00007517          	auipc	a0,0x7
    80001f9c:	2d850513          	addi	a0,a0,728 # 80009270 <digits+0x230>
    80001fa0:	ffffe097          	auipc	ra,0xffffe
    80001fa4:	5d4080e7          	jalr	1492(ra) # 80000574 <printf>
    if(writeToSwapFile(p,(char*)physical_addr,offset,PGSIZE) ==  -1)
    80001fa8:	6685                	lui	a3,0x1
    80001faa:	8656                	mv	a2,s5
    80001fac:	85ca                	mv	a1,s2
    80001fae:	8526                	mv	a0,s1
    80001fb0:	00003097          	auipc	ra,0x3
    80001fb4:	dca080e7          	jalr	-566(ra) # 80004d7a <writeToSwapFile>
    80001fb8:	57fd                	li	a5,-1
    80001fba:	04f50263          	beq	a0,a5,80001ffe <swap_page_into_file+0xae>
    kfree((void*)physical_addr);
    80001fbe:	854a                	mv	a0,s2
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	a16080e7          	jalr	-1514(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    80001fc8:	000a3783          	ld	a5,0(s4)
    80001fcc:	bfe7f793          	andi	a5,a5,-1026
    80001fd0:	4007e793          	ori	a5,a5,1024
    80001fd4:	00fa3023          	sd	a5,0(s4)
    p->paging_meta_data[remove_file_indx].offset = offset;
    80001fd8:	00199793          	slli	a5,s3,0x1
    80001fdc:	01378733          	add	a4,a5,s3
    80001fe0:	070a                	slli	a4,a4,0x2
    80001fe2:	9726                	add	a4,a4,s1
    80001fe4:	17572823          	sw	s5,368(a4)
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    80001fe8:	16072c23          	sw	zero,376(a4)
}
    80001fec:	70e2                	ld	ra,56(sp)
    80001fee:	7442                	ld	s0,48(sp)
    80001ff0:	74a2                	ld	s1,40(sp)
    80001ff2:	7902                	ld	s2,32(sp)
    80001ff4:	69e2                	ld	s3,24(sp)
    80001ff6:	6a42                	ld	s4,16(sp)
    80001ff8:	6aa2                	ld	s5,8(sp)
    80001ffa:	6121                	addi	sp,sp,64
    80001ffc:	8082                	ret
      panic("write to file failed");
    80001ffe:	00007517          	auipc	a0,0x7
    80002002:	2a250513          	addi	a0,a0,674 # 800092a0 <digits+0x260>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	524080e7          	jalr	1316(ra) # 8000052a <panic>

000000008000200e <page_in>:
void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    8000200e:	7139                	addi	sp,sp,-64
    80002010:	fc06                	sd	ra,56(sp)
    80002012:	f822                	sd	s0,48(sp)
    80002014:	f426                	sd	s1,40(sp)
    80002016:	f04a                	sd	s2,32(sp)
    80002018:	ec4e                	sd	s3,24(sp)
    8000201a:	e852                	sd	s4,16(sp)
    8000201c:	e456                	sd	s5,8(sp)
    8000201e:	0080                	addi	s0,sp,64
    80002020:	89ae                	mv	s3,a1
  int current_page_index = PGROUNDDOWN(faulting_address)/PGSIZE;
    80002022:	8131                	srli	a0,a0,0xc
    80002024:	0005091b          	sext.w	s2,a0
  uint offset = myproc()->paging_meta_data[current_page_index].offset;
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	3da080e7          	jalr	986(ra) # 80002402 <myproc>
    80002030:	00191793          	slli	a5,s2,0x1
    80002034:	97ca                	add	a5,a5,s2
    80002036:	078a                	slli	a5,a5,0x2
    80002038:	97aa                	add	a5,a5,a0
    8000203a:	1707aa83          	lw	s5,368(a5)
    8000203e:	000a8a1b          	sext.w	s4,s5
  if(offset == -1){
    80002042:	57fd                	li	a5,-1
    80002044:	0afa0563          	beq	s4,a5,800020ee <page_in+0xe0>
  if((read_buffer = kalloc()) == 0)
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	a9a080e7          	jalr	-1382(ra) # 80000ae2 <kalloc>
    80002050:	84aa                	mv	s1,a0
    80002052:	c555                	beqz	a0,800020fe <page_in+0xf0>
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    80002054:	00000097          	auipc	ra,0x0
    80002058:	3ae080e7          	jalr	942(ra) # 80002402 <myproc>
    8000205c:	6685                	lui	a3,0x1
    8000205e:	8652                	mv	a2,s4
    80002060:	85a6                	mv	a1,s1
    80002062:	00003097          	auipc	ra,0x3
    80002066:	d3c080e7          	jalr	-708(ra) # 80004d9e <readFromSwapFile>
    8000206a:	57fd                	li	a5,-1
    8000206c:	0af50163          	beq	a0,a5,8000210e <page_in+0x100>
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	5e8080e7          	jalr	1512(ra) # 80001658 <get_num_of_pages_in_memory>
    80002078:	47bd                	li	a5,15
    8000207a:	0aa7c263          	blt	a5,a0,8000211e <page_in+0x110>
      *missing_pte_entry = PA2PTE((uint64)read_buffer) | PTE_V; 
    8000207e:	80b1                	srli	s1,s1,0xc
    80002080:	04aa                	slli	s1,s1,0xa
    80002082:	0014e493          	ori	s1,s1,1
    80002086:	0099b023          	sd	s1,0(s3) # fffffffffffff000 <end+0xffffffff7ffd0000>
  myproc()->paging_meta_data[current_page_index].aging = init_aging(current_page_index);
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	378080e7          	jalr	888(ra) # 80002402 <myproc>
    80002092:	89aa                	mv	s3,a0
    return insert_to_queue(fifo_init_pages);
    80002094:	854a                	mv	a0,s2
    80002096:	fffff097          	auipc	ra,0xfffff
    8000209a:	768080e7          	jalr	1896(ra) # 800017fe <insert_to_queue>
  myproc()->paging_meta_data[current_page_index].aging = init_aging(current_page_index);
    8000209e:	00191493          	slli	s1,s2,0x1
    800020a2:	012487b3          	add	a5,s1,s2
    800020a6:	078a                	slli	a5,a5,0x2
    800020a8:	99be                	add	s3,s3,a5
    return insert_to_queue(fifo_init_pages);
    800020aa:	16a9aa23          	sw	a0,372(s3)
  myproc()->paging_meta_data[current_page_index].offset = -1;
    800020ae:	00000097          	auipc	ra,0x0
    800020b2:	354080e7          	jalr	852(ra) # 80002402 <myproc>
    800020b6:	012487b3          	add	a5,s1,s2
    800020ba:	078a                	slli	a5,a5,0x2
    800020bc:	953e                	add	a0,a0,a5
    800020be:	57fd                	li	a5,-1
    800020c0:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_index].in_memory = 1;
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	33e080e7          	jalr	830(ra) # 80002402 <myproc>
    800020cc:	94ca                	add	s1,s1,s2
    800020ce:	048a                	slli	s1,s1,0x2
    800020d0:	94aa                	add	s1,s1,a0
    800020d2:	4785                	li	a5,1
    800020d4:	16f4ac23          	sw	a5,376(s1)
    800020d8:	12000073          	sfence.vma
}
    800020dc:	70e2                	ld	ra,56(sp)
    800020de:	7442                	ld	s0,48(sp)
    800020e0:	74a2                	ld	s1,40(sp)
    800020e2:	7902                	ld	s2,32(sp)
    800020e4:	69e2                	ld	s3,24(sp)
    800020e6:	6a42                	ld	s4,16(sp)
    800020e8:	6aa2                	ld	s5,8(sp)
    800020ea:	6121                	addi	sp,sp,64
    800020ec:	8082                	ret
    panic("offset is -1");
    800020ee:	00007517          	auipc	a0,0x7
    800020f2:	1ca50513          	addi	a0,a0,458 # 800092b8 <digits+0x278>
    800020f6:	ffffe097          	auipc	ra,0xffffe
    800020fa:	434080e7          	jalr	1076(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    800020fe:	00007517          	auipc	a0,0x7
    80002102:	1ca50513          	addi	a0,a0,458 # 800092c8 <digits+0x288>
    80002106:	ffffe097          	auipc	ra,0xffffe
    8000210a:	424080e7          	jalr	1060(ra) # 8000052a <panic>
    panic("read from file failed");
    8000210e:	00007517          	auipc	a0,0x7
    80002112:	1da50513          	addi	a0,a0,474 # 800092e8 <digits+0x2a8>
    80002116:	ffffe097          	auipc	ra,0xffffe
    8000211a:	414080e7          	jalr	1044(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    8000211e:	8556                	mv	a0,s5
    80002120:	00000097          	auipc	ra,0x0
    80002124:	e30080e7          	jalr	-464(ra) # 80001f50 <swap_page_into_file>
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    80002128:	80b1                	srli	s1,s1,0xc
    8000212a:	04aa                	slli	s1,s1,0xa
    8000212c:	0009b783          	ld	a5,0(s3)
    80002130:	3fe7f793          	andi	a5,a5,1022
    80002134:	8cdd                	or	s1,s1,a5
    80002136:	0014e493          	ori	s1,s1,1
    8000213a:	0099b023          	sd	s1,0(s3)
    8000213e:	b7b1                	j	8000208a <page_in+0x7c>

0000000080002140 <check_page_fault>:
void check_page_fault(){
    80002140:	1101                	addi	sp,sp,-32
    80002142:	ec06                	sd	ra,24(sp)
    80002144:	e822                	sd	s0,16(sp)
    80002146:	e426                	sd	s1,8(sp)
    80002148:	e04a                	sd	s2,0(sp)
    8000214a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000214c:	14302973          	csrr	s2,stval
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80002150:	00000097          	auipc	ra,0x0
    80002154:	2b2080e7          	jalr	690(ra) # 80002402 <myproc>
    80002158:	4601                	li	a2,0
    8000215a:	75fd                	lui	a1,0xfffff
    8000215c:	00b975b3          	and	a1,s2,a1
    80002160:	6928                	ld	a0,80(a0)
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	e54080e7          	jalr	-428(ra) # 80000fb6 <walk>
  if(pte_entry !=0 &&(!(*pte_entry & PTE_V)  && *pte_entry & PTE_PG)){
    8000216a:	c909                	beqz	a0,8000217c <check_page_fault+0x3c>
    8000216c:	84aa                	mv	s1,a0
    8000216e:	611c                	ld	a5,0(a0)
    80002170:	4017f793          	andi	a5,a5,1025
    80002174:	40000713          	li	a4,1024
    80002178:	02e78463          	beq	a5,a4,800021a0 <check_page_fault+0x60>
  else if (faulting_address <= myproc()->sz){
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	286080e7          	jalr	646(ra) # 80002402 <myproc>
    80002184:	653c                	ld	a5,72(a0)
    80002186:	0327ec63          	bltu	a5,s2,800021be <check_page_fault+0x7e>
    lazy_memory_allocation(faulting_address);
    8000218a:	854a                	mv	a0,s2
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	b06080e7          	jalr	-1274(ra) # 80001c92 <lazy_memory_allocation>
}
    80002194:	60e2                	ld	ra,24(sp)
    80002196:	6442                	ld	s0,16(sp)
    80002198:	64a2                	ld	s1,8(sp)
    8000219a:	6902                	ld	s2,0(sp)
    8000219c:	6105                	addi	sp,sp,32
    8000219e:	8082                	ret
    printf("Page Fault - Page was out of memory\n");
    800021a0:	00007517          	auipc	a0,0x7
    800021a4:	16050513          	addi	a0,a0,352 # 80009300 <digits+0x2c0>
    800021a8:	ffffe097          	auipc	ra,0xffffe
    800021ac:	3cc080e7          	jalr	972(ra) # 80000574 <printf>
    page_in(faulting_address, pte_entry);
    800021b0:	85a6                	mv	a1,s1
    800021b2:	854a                	mv	a0,s2
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	e5a080e7          	jalr	-422(ra) # 8000200e <page_in>
    800021bc:	bfe1                	j	80002194 <check_page_fault+0x54>
    exit(-1);
    800021be:	557d                	li	a0,-1
    800021c0:	00001097          	auipc	ra,0x1
    800021c4:	dc4080e7          	jalr	-572(ra) # 80002f84 <exit>
}
    800021c8:	b7f1                	j	80002194 <check_page_fault+0x54>

00000000800021ca <find_file_to_remove>:
int find_file_to_remove(){
    800021ca:	1141                	addi	sp,sp,-16
    800021cc:	e406                	sd	ra,8(sp)
    800021ce:	e022                	sd	s0,0(sp)
    800021d0:	0800                	addi	s0,sp,16
    return second_fifo(); 
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	cb0080e7          	jalr	-848(ra) # 80001e82 <second_fifo>
}
    800021da:	60a2                	ld	ra,8(sp)
    800021dc:	6402                	ld	s0,0(sp)
    800021de:	0141                	addi	sp,sp,16
    800021e0:	8082                	ret

00000000800021e2 <shift_counter>:
void shift_counter(){
    800021e2:	7139                	addi	sp,sp,-64
    800021e4:	fc06                	sd	ra,56(sp)
    800021e6:	f822                	sd	s0,48(sp)
    800021e8:	f426                	sd	s1,40(sp)
    800021ea:	f04a                	sd	s2,32(sp)
    800021ec:	ec4e                	sd	s3,24(sp)
    800021ee:	e852                	sd	s4,16(sp)
    800021f0:	e456                	sd	s5,8(sp)
    800021f2:	0080                	addi	s0,sp,64
 struct proc * p = myproc();
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	20e080e7          	jalr	526(ra) # 80002402 <myproc>
 for(int i=0; i<32; i++){
    800021fc:	17450913          	addi	s2,a0,372
 struct proc * p = myproc();
    80002200:	4481                	li	s1,0
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80002202:	80000ab7          	lui	s5,0x80000
 for(int i=0; i<32; i++){
    80002206:	6a05                	lui	s4,0x1
    80002208:	000209b7          	lui	s3,0x20
    8000220c:	a029                	j	80002216 <shift_counter+0x34>
    8000220e:	94d2                	add	s1,s1,s4
    80002210:	0931                	addi	s2,s2,12
    80002212:	05348363          	beq	s1,s3,80002258 <shift_counter+0x76>
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	1ec080e7          	jalr	492(ra) # 80002402 <myproc>
    8000221e:	4601                	li	a2,0
    80002220:	85a6                	mv	a1,s1
    80002222:	6928                	ld	a0,80(a0)
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	d92080e7          	jalr	-622(ra) # 80000fb6 <walk>
      if(*pte & PTE_V){
    8000222c:	611c                	ld	a5,0(a0)
    8000222e:	8b85                	andi	a5,a5,1
    80002230:	dff9                	beqz	a5,8000220e <shift_counter+0x2c>
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
    80002232:	00092783          	lw	a5,0(s2)
    80002236:	0017d79b          	srliw	a5,a5,0x1
    8000223a:	00f92023          	sw	a5,0(s2)
        if(*pte & PTE_A){
    8000223e:	6118                	ld	a4,0(a0)
    80002240:	04077713          	andi	a4,a4,64
    80002244:	d769                	beqz	a4,8000220e <shift_counter+0x2c>
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80002246:	0157e7b3          	or	a5,a5,s5
    8000224a:	00f92023          	sw	a5,0(s2)
          *pte = *pte & (~PTE_A); //turn off
    8000224e:	611c                	ld	a5,0(a0)
    80002250:	fbf7f793          	andi	a5,a5,-65
    80002254:	e11c                	sd	a5,0(a0)
    80002256:	bf65                	j	8000220e <shift_counter+0x2c>
}
    80002258:	70e2                	ld	ra,56(sp)
    8000225a:	7442                	ld	s0,48(sp)
    8000225c:	74a2                	ld	s1,40(sp)
    8000225e:	7902                	ld	s2,32(sp)
    80002260:	69e2                	ld	s3,24(sp)
    80002262:	6a42                	ld	s4,16(sp)
    80002264:	6aa2                	ld	s5,8(sp)
    80002266:	6121                	addi	sp,sp,64
    80002268:	8082                	ret

000000008000226a <update_aging_algorithms>:
update_aging_algorithms(void){
    8000226a:	1141                	addi	sp,sp,-16
    8000226c:	e422                	sd	s0,8(sp)
    8000226e:	0800                	addi	s0,sp,16
}
    80002270:	6422                	ld	s0,8(sp)
    80002272:	0141                	addi	sp,sp,16
    80002274:	8082                	ret

0000000080002276 <init_aging>:
uint init_aging(int fifo_init_pages){
    80002276:	1141                	addi	sp,sp,-16
    80002278:	e406                	sd	ra,8(sp)
    8000227a:	e022                	sd	s0,0(sp)
    8000227c:	0800                	addi	s0,sp,16
    return insert_to_queue(fifo_init_pages);
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	580080e7          	jalr	1408(ra) # 800017fe <insert_to_queue>
  #endif 
  return 0;
}
    80002286:	2501                	sext.w	a0,a0
    80002288:	60a2                	ld	ra,8(sp)
    8000228a:	6402                	ld	s0,0(sp)
    8000228c:	0141                	addi	sp,sp,16
    8000228e:	8082                	ret

0000000080002290 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80002290:	7139                	addi	sp,sp,-64
    80002292:	fc06                	sd	ra,56(sp)
    80002294:	f822                	sd	s0,48(sp)
    80002296:	f426                	sd	s1,40(sp)
    80002298:	f04a                	sd	s2,32(sp)
    8000229a:	ec4e                	sd	s3,24(sp)
    8000229c:	e852                	sd	s4,16(sp)
    8000229e:	e456                	sd	s5,8(sp)
    800022a0:	e05a                	sd	s6,0(sp)
    800022a2:	0080                	addi	s0,sp,64
    800022a4:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    800022a6:	00010497          	auipc	s1,0x10
    800022aa:	42a48493          	addi	s1,s1,1066 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    800022ae:	8b26                	mv	s6,s1
    800022b0:	00007a97          	auipc	s5,0x7
    800022b4:	d50a8a93          	addi	s5,s5,-688 # 80009000 <etext>
    800022b8:	04000937          	lui	s2,0x4000
    800022bc:	197d                	addi	s2,s2,-1
    800022be:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800022c0:	0001ea17          	auipc	s4,0x1e
    800022c4:	410a0a13          	addi	s4,s4,1040 # 800206d0 <tickslock>
    char *pa = kalloc();
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	81a080e7          	jalr	-2022(ra) # 80000ae2 <kalloc>
    800022d0:	862a                	mv	a2,a0
    if(pa == 0)
    800022d2:	c131                	beqz	a0,80002316 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800022d4:	416485b3          	sub	a1,s1,s6
    800022d8:	859d                	srai	a1,a1,0x7
    800022da:	000ab783          	ld	a5,0(s5)
    800022de:	02f585b3          	mul	a1,a1,a5
    800022e2:	2585                	addiw	a1,a1,1
    800022e4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800022e8:	4719                	li	a4,6
    800022ea:	6685                	lui	a3,0x1
    800022ec:	40b905b3          	sub	a1,s2,a1
    800022f0:	854e                	mv	a0,s3
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	e24080e7          	jalr	-476(ra) # 80001116 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022fa:	38048493          	addi	s1,s1,896
    800022fe:	fd4495e3          	bne	s1,s4,800022c8 <proc_mapstacks+0x38>
  }
}
    80002302:	70e2                	ld	ra,56(sp)
    80002304:	7442                	ld	s0,48(sp)
    80002306:	74a2                	ld	s1,40(sp)
    80002308:	7902                	ld	s2,32(sp)
    8000230a:	69e2                	ld	s3,24(sp)
    8000230c:	6a42                	ld	s4,16(sp)
    8000230e:	6aa2                	ld	s5,8(sp)
    80002310:	6b02                	ld	s6,0(sp)
    80002312:	6121                	addi	sp,sp,64
    80002314:	8082                	ret
      panic("kalloc");
    80002316:	00007517          	auipc	a0,0x7
    8000231a:	01250513          	addi	a0,a0,18 # 80009328 <digits+0x2e8>
    8000231e:	ffffe097          	auipc	ra,0xffffe
    80002322:	20c080e7          	jalr	524(ra) # 8000052a <panic>

0000000080002326 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80002326:	7139                	addi	sp,sp,-64
    80002328:	fc06                	sd	ra,56(sp)
    8000232a:	f822                	sd	s0,48(sp)
    8000232c:	f426                	sd	s1,40(sp)
    8000232e:	f04a                	sd	s2,32(sp)
    80002330:	ec4e                	sd	s3,24(sp)
    80002332:	e852                	sd	s4,16(sp)
    80002334:	e456                	sd	s5,8(sp)
    80002336:	e05a                	sd	s6,0(sp)
    80002338:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000233a:	00007597          	auipc	a1,0x7
    8000233e:	ff658593          	addi	a1,a1,-10 # 80009330 <digits+0x2f0>
    80002342:	00010517          	auipc	a0,0x10
    80002346:	f5e50513          	addi	a0,a0,-162 # 800122a0 <pid_lock>
    8000234a:	ffffe097          	auipc	ra,0xffffe
    8000234e:	7f8080e7          	jalr	2040(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80002352:	00007597          	auipc	a1,0x7
    80002356:	fe658593          	addi	a1,a1,-26 # 80009338 <digits+0x2f8>
    8000235a:	00010517          	auipc	a0,0x10
    8000235e:	f5e50513          	addi	a0,a0,-162 # 800122b8 <wait_lock>
    80002362:	ffffe097          	auipc	ra,0xffffe
    80002366:	7e0080e7          	jalr	2016(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000236a:	00010497          	auipc	s1,0x10
    8000236e:	36648493          	addi	s1,s1,870 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    80002372:	00007b17          	auipc	s6,0x7
    80002376:	fd6b0b13          	addi	s6,s6,-42 # 80009348 <digits+0x308>
      p->kstack = KSTACK((int) (p - proc));
    8000237a:	8aa6                	mv	s5,s1
    8000237c:	00007a17          	auipc	s4,0x7
    80002380:	c84a0a13          	addi	s4,s4,-892 # 80009000 <etext>
    80002384:	04000937          	lui	s2,0x4000
    80002388:	197d                	addi	s2,s2,-1
    8000238a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000238c:	0001e997          	auipc	s3,0x1e
    80002390:	34498993          	addi	s3,s3,836 # 800206d0 <tickslock>
      initlock(&p->lock, "proc");
    80002394:	85da                	mv	a1,s6
    80002396:	8526                	mv	a0,s1
    80002398:	ffffe097          	auipc	ra,0xffffe
    8000239c:	7aa080e7          	jalr	1962(ra) # 80000b42 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800023a0:	415487b3          	sub	a5,s1,s5
    800023a4:	879d                	srai	a5,a5,0x7
    800023a6:	000a3703          	ld	a4,0(s4)
    800023aa:	02e787b3          	mul	a5,a5,a4
    800023ae:	2785                	addiw	a5,a5,1
    800023b0:	00d7979b          	slliw	a5,a5,0xd
    800023b4:	40f907b3          	sub	a5,s2,a5
    800023b8:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ba:	38048493          	addi	s1,s1,896
    800023be:	fd349be3          	bne	s1,s3,80002394 <procinit+0x6e>
  }
}
    800023c2:	70e2                	ld	ra,56(sp)
    800023c4:	7442                	ld	s0,48(sp)
    800023c6:	74a2                	ld	s1,40(sp)
    800023c8:	7902                	ld	s2,32(sp)
    800023ca:	69e2                	ld	s3,24(sp)
    800023cc:	6a42                	ld	s4,16(sp)
    800023ce:	6aa2                	ld	s5,8(sp)
    800023d0:	6b02                	ld	s6,0(sp)
    800023d2:	6121                	addi	sp,sp,64
    800023d4:	8082                	ret

00000000800023d6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800023d6:	1141                	addi	sp,sp,-16
    800023d8:	e422                	sd	s0,8(sp)
    800023da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800023dc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800023de:	2501                	sext.w	a0,a0
    800023e0:	6422                	ld	s0,8(sp)
    800023e2:	0141                	addi	sp,sp,16
    800023e4:	8082                	ret

00000000800023e6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800023e6:	1141                	addi	sp,sp,-16
    800023e8:	e422                	sd	s0,8(sp)
    800023ea:	0800                	addi	s0,sp,16
    800023ec:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800023ee:	2781                	sext.w	a5,a5
    800023f0:	079e                	slli	a5,a5,0x7
  return c;
}
    800023f2:	00010517          	auipc	a0,0x10
    800023f6:	ede50513          	addi	a0,a0,-290 # 800122d0 <cpus>
    800023fa:	953e                	add	a0,a0,a5
    800023fc:	6422                	ld	s0,8(sp)
    800023fe:	0141                	addi	sp,sp,16
    80002400:	8082                	ret

0000000080002402 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80002402:	1101                	addi	sp,sp,-32
    80002404:	ec06                	sd	ra,24(sp)
    80002406:	e822                	sd	s0,16(sp)
    80002408:	e426                	sd	s1,8(sp)
    8000240a:	1000                	addi	s0,sp,32
  push_off();
    8000240c:	ffffe097          	auipc	ra,0xffffe
    80002410:	77a080e7          	jalr	1914(ra) # 80000b86 <push_off>
    80002414:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80002416:	2781                	sext.w	a5,a5
    80002418:	079e                	slli	a5,a5,0x7
    8000241a:	00010717          	auipc	a4,0x10
    8000241e:	e8670713          	addi	a4,a4,-378 # 800122a0 <pid_lock>
    80002422:	97ba                	add	a5,a5,a4
    80002424:	7b84                	ld	s1,48(a5)
  pop_off();
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	800080e7          	jalr	-2048(ra) # 80000c26 <pop_off>
  return p;
}
    8000242e:	8526                	mv	a0,s1
    80002430:	60e2                	ld	ra,24(sp)
    80002432:	6442                	ld	s0,16(sp)
    80002434:	64a2                	ld	s1,8(sp)
    80002436:	6105                	addi	sp,sp,32
    80002438:	8082                	ret

000000008000243a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000243a:	1141                	addi	sp,sp,-16
    8000243c:	e406                	sd	ra,8(sp)
    8000243e:	e022                	sd	s0,0(sp)
    80002440:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80002442:	00000097          	auipc	ra,0x0
    80002446:	fc0080e7          	jalr	-64(ra) # 80002402 <myproc>
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	83c080e7          	jalr	-1988(ra) # 80000c86 <release>

  if (first) {
    80002452:	00007797          	auipc	a5,0x7
    80002456:	5ae7a783          	lw	a5,1454(a5) # 80009a00 <first.1>
    8000245a:	eb89                	bnez	a5,8000246c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    8000245c:	00001097          	auipc	ra,0x1
    80002460:	e8c080e7          	jalr	-372(ra) # 800032e8 <usertrapret>
}
    80002464:	60a2                	ld	ra,8(sp)
    80002466:	6402                	ld	s0,0(sp)
    80002468:	0141                	addi	sp,sp,16
    8000246a:	8082                	ret
    first = 0;
    8000246c:	00007797          	auipc	a5,0x7
    80002470:	5807aa23          	sw	zero,1428(a5) # 80009a00 <first.1>
    fsinit(ROOTDEV);
    80002474:	4505                	li	a0,1
    80002476:	00002097          	auipc	ra,0x2
    8000247a:	bd2080e7          	jalr	-1070(ra) # 80004048 <fsinit>
    8000247e:	bff9                	j	8000245c <forkret+0x22>

0000000080002480 <allocpid>:
allocpid() {
    80002480:	1101                	addi	sp,sp,-32
    80002482:	ec06                	sd	ra,24(sp)
    80002484:	e822                	sd	s0,16(sp)
    80002486:	e426                	sd	s1,8(sp)
    80002488:	e04a                	sd	s2,0(sp)
    8000248a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    8000248c:	00010917          	auipc	s2,0x10
    80002490:	e1490913          	addi	s2,s2,-492 # 800122a0 <pid_lock>
    80002494:	854a                	mv	a0,s2
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	73c080e7          	jalr	1852(ra) # 80000bd2 <acquire>
  pid = nextpid;
    8000249e:	00007797          	auipc	a5,0x7
    800024a2:	56678793          	addi	a5,a5,1382 # 80009a04 <nextpid>
    800024a6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800024a8:	0014871b          	addiw	a4,s1,1
    800024ac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800024ae:	854a                	mv	a0,s2
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7d6080e7          	jalr	2006(ra) # 80000c86 <release>
}
    800024b8:	8526                	mv	a0,s1
    800024ba:	60e2                	ld	ra,24(sp)
    800024bc:	6442                	ld	s0,16(sp)
    800024be:	64a2                	ld	s1,8(sp)
    800024c0:	6902                	ld	s2,0(sp)
    800024c2:	6105                	addi	sp,sp,32
    800024c4:	8082                	ret

00000000800024c6 <proc_pagetable>:
{
    800024c6:	1101                	addi	sp,sp,-32
    800024c8:	ec06                	sd	ra,24(sp)
    800024ca:	e822                	sd	s0,16(sp)
    800024cc:	e426                	sd	s1,8(sp)
    800024ce:	e04a                	sd	s2,0(sp)
    800024d0:	1000                	addi	s0,sp,32
    800024d2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	e2c080e7          	jalr	-468(ra) # 80001300 <uvmcreate>
    800024dc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800024de:	c121                	beqz	a0,8000251e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800024e0:	4729                	li	a4,10
    800024e2:	00006697          	auipc	a3,0x6
    800024e6:	b1e68693          	addi	a3,a3,-1250 # 80008000 <_trampoline>
    800024ea:	6605                	lui	a2,0x1
    800024ec:	040005b7          	lui	a1,0x4000
    800024f0:	15fd                	addi	a1,a1,-1
    800024f2:	05b2                	slli	a1,a1,0xc
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	b94080e7          	jalr	-1132(ra) # 80001088 <mappages>
    800024fc:	02054863          	bltz	a0,8000252c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002500:	4719                	li	a4,6
    80002502:	05893683          	ld	a3,88(s2)
    80002506:	6605                	lui	a2,0x1
    80002508:	020005b7          	lui	a1,0x2000
    8000250c:	15fd                	addi	a1,a1,-1
    8000250e:	05b6                	slli	a1,a1,0xd
    80002510:	8526                	mv	a0,s1
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	b76080e7          	jalr	-1162(ra) # 80001088 <mappages>
    8000251a:	02054163          	bltz	a0,8000253c <proc_pagetable+0x76>
}
    8000251e:	8526                	mv	a0,s1
    80002520:	60e2                	ld	ra,24(sp)
    80002522:	6442                	ld	s0,16(sp)
    80002524:	64a2                	ld	s1,8(sp)
    80002526:	6902                	ld	s2,0(sp)
    80002528:	6105                	addi	sp,sp,32
    8000252a:	8082                	ret
    uvmfree(pagetable, 0);
    8000252c:	4581                	li	a1,0
    8000252e:	8526                	mv	a0,s1
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	792080e7          	jalr	1938(ra) # 80001cc2 <uvmfree>
    return 0;
    80002538:	4481                	li	s1,0
    8000253a:	b7d5                	j	8000251e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000253c:	4681                	li	a3,0
    8000253e:	4605                	li	a2,1
    80002540:	040005b7          	lui	a1,0x4000
    80002544:	15fd                	addi	a1,a1,-1
    80002546:	05b2                	slli	a1,a1,0xc
    80002548:	8526                	mv	a0,s1
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	3a8080e7          	jalr	936(ra) # 800018f2 <uvmunmap>
    uvmfree(pagetable, 0);
    80002552:	4581                	li	a1,0
    80002554:	8526                	mv	a0,s1
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	76c080e7          	jalr	1900(ra) # 80001cc2 <uvmfree>
    return 0;
    8000255e:	4481                	li	s1,0
    80002560:	bf7d                	j	8000251e <proc_pagetable+0x58>

0000000080002562 <proc_freepagetable>:
{
    80002562:	1101                	addi	sp,sp,-32
    80002564:	ec06                	sd	ra,24(sp)
    80002566:	e822                	sd	s0,16(sp)
    80002568:	e426                	sd	s1,8(sp)
    8000256a:	e04a                	sd	s2,0(sp)
    8000256c:	1000                	addi	s0,sp,32
    8000256e:	84aa                	mv	s1,a0
    80002570:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002572:	4681                	li	a3,0
    80002574:	4605                	li	a2,1
    80002576:	040005b7          	lui	a1,0x4000
    8000257a:	15fd                	addi	a1,a1,-1
    8000257c:	05b2                	slli	a1,a1,0xc
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	374080e7          	jalr	884(ra) # 800018f2 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80002586:	4681                	li	a3,0
    80002588:	4605                	li	a2,1
    8000258a:	020005b7          	lui	a1,0x2000
    8000258e:	15fd                	addi	a1,a1,-1
    80002590:	05b6                	slli	a1,a1,0xd
    80002592:	8526                	mv	a0,s1
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	35e080e7          	jalr	862(ra) # 800018f2 <uvmunmap>
  uvmfree(pagetable, sz);
    8000259c:	85ca                	mv	a1,s2
    8000259e:	8526                	mv	a0,s1
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	722080e7          	jalr	1826(ra) # 80001cc2 <uvmfree>
}
    800025a8:	60e2                	ld	ra,24(sp)
    800025aa:	6442                	ld	s0,16(sp)
    800025ac:	64a2                	ld	s1,8(sp)
    800025ae:	6902                	ld	s2,0(sp)
    800025b0:	6105                	addi	sp,sp,32
    800025b2:	8082                	ret

00000000800025b4 <freeproc>:
{ 
    800025b4:	1101                	addi	sp,sp,-32
    800025b6:	ec06                	sd	ra,24(sp)
    800025b8:	e822                	sd	s0,16(sp)
    800025ba:	e426                	sd	s1,8(sp)
    800025bc:	1000                	addi	s0,sp,32
    800025be:	84aa                	mv	s1,a0
  if(p->trapframe)
    800025c0:	6d28                	ld	a0,88(a0)
    800025c2:	c509                	beqz	a0,800025cc <freeproc+0x18>
    kfree((void*)p->trapframe);
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	412080e7          	jalr	1042(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    800025cc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800025d0:	68a8                	ld	a0,80(s1)
    800025d2:	c511                	beqz	a0,800025de <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800025d4:	64ac                	ld	a1,72(s1)
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	f8c080e7          	jalr	-116(ra) # 80002562 <proc_freepagetable>
  p->pagetable = 0;
    800025de:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800025e2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800025e6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800025ea:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800025ee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800025f2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800025f6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800025fa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    800025fe:	0004ac23          	sw	zero,24(s1)
}
    80002602:	60e2                	ld	ra,24(sp)
    80002604:	6442                	ld	s0,16(sp)
    80002606:	64a2                	ld	s1,8(sp)
    80002608:	6105                	addi	sp,sp,32
    8000260a:	8082                	ret

000000008000260c <allocproc>:
{
    8000260c:	7179                	addi	sp,sp,-48
    8000260e:	f406                	sd	ra,40(sp)
    80002610:	f022                	sd	s0,32(sp)
    80002612:	ec26                	sd	s1,24(sp)
    80002614:	e84a                	sd	s2,16(sp)
    80002616:	e44e                	sd	s3,8(sp)
    80002618:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    8000261a:	00010497          	auipc	s1,0x10
    8000261e:	0b648493          	addi	s1,s1,182 # 800126d0 <proc>
    80002622:	0001e997          	auipc	s3,0x1e
    80002626:	0ae98993          	addi	s3,s3,174 # 800206d0 <tickslock>
    acquire(&p->lock);
    8000262a:	8926                	mv	s2,s1
    8000262c:	8526                	mv	a0,s1
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	5a4080e7          	jalr	1444(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    80002636:	4c9c                	lw	a5,24(s1)
    80002638:	cf81                	beqz	a5,80002650 <allocproc+0x44>
      release(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	64a080e7          	jalr	1610(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002644:	38048493          	addi	s1,s1,896
    80002648:	ff3491e3          	bne	s1,s3,8000262a <allocproc+0x1e>
  return 0;
    8000264c:	4481                	li	s1,0
    8000264e:	a061                	j	800026d6 <allocproc+0xca>
  p->pid = allocpid();
    80002650:	00000097          	auipc	ra,0x0
    80002654:	e30080e7          	jalr	-464(ra) # 80002480 <allocpid>
    80002658:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000265a:	4785                	li	a5,1
    8000265c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	484080e7          	jalr	1156(ra) # 80000ae2 <kalloc>
    80002666:	89aa                	mv	s3,a0
    80002668:	eca8                	sd	a0,88(s1)
    8000266a:	cd35                	beqz	a0,800026e6 <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    8000266c:	8526                	mv	a0,s1
    8000266e:	00000097          	auipc	ra,0x0
    80002672:	e58080e7          	jalr	-424(ra) # 800024c6 <proc_pagetable>
    80002676:	89aa                	mv	s3,a0
    80002678:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    8000267a:	c151                	beqz	a0,800026fe <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    8000267c:	07000613          	li	a2,112
    80002680:	4581                	li	a1,0
    80002682:	06048513          	addi	a0,s1,96
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	648080e7          	jalr	1608(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    8000268e:	00000797          	auipc	a5,0x0
    80002692:	dac78793          	addi	a5,a5,-596 # 8000243a <forkret>
    80002696:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002698:	60bc                	ld	a5,64(s1)
    8000269a:	6705                	lui	a4,0x1
    8000269c:	97ba                	add	a5,a5,a4
    8000269e:	f4bc                	sd	a5,104(s1)
  for(int i=0;i<32;i++){
    800026a0:	17048793          	addi	a5,s1,368
    800026a4:	2f048693          	addi	a3,s1,752
    p->paging_meta_data[i].offset = -1;
    800026a8:	577d                	li	a4,-1
    800026aa:	c398                	sw	a4,0(a5)
    p->paging_meta_data[i].aging = 0;
    800026ac:	0007a223          	sw	zero,4(a5)
    p->paging_meta_data[i].in_memory = 0;
    800026b0:	0007a423          	sw	zero,8(a5)
  for(int i=0;i<32;i++){
    800026b4:	07b1                	addi	a5,a5,12
    800026b6:	fed79ae3          	bne	a5,a3,800026aa <allocproc+0x9e>
  p->queue.front = 0;
    800026ba:	3604a823          	sw	zero,880(s1)
  p->queue.last = -1;
    800026be:	57fd                	li	a5,-1
    800026c0:	36f4aa23          	sw	a5,884(s1)
  for(int i=0; i<32; i++){
    800026c4:	2f048793          	addi	a5,s1,752
    800026c8:	37090713          	addi	a4,s2,880
    p->queue.pages[i] = -1;
    800026cc:	56fd                	li	a3,-1
    800026ce:	c394                	sw	a3,0(a5)
  for(int i=0; i<32; i++){
    800026d0:	0791                	addi	a5,a5,4
    800026d2:	fee79ee3          	bne	a5,a4,800026ce <allocproc+0xc2>
}
    800026d6:	8526                	mv	a0,s1
    800026d8:	70a2                	ld	ra,40(sp)
    800026da:	7402                	ld	s0,32(sp)
    800026dc:	64e2                	ld	s1,24(sp)
    800026de:	6942                	ld	s2,16(sp)
    800026e0:	69a2                	ld	s3,8(sp)
    800026e2:	6145                	addi	sp,sp,48
    800026e4:	8082                	ret
    freeproc(p);
    800026e6:	8526                	mv	a0,s1
    800026e8:	00000097          	auipc	ra,0x0
    800026ec:	ecc080e7          	jalr	-308(ra) # 800025b4 <freeproc>
    release(&p->lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	594080e7          	jalr	1428(ra) # 80000c86 <release>
    return 0;
    800026fa:	84ce                	mv	s1,s3
    800026fc:	bfe9                	j	800026d6 <allocproc+0xca>
    freeproc(p);
    800026fe:	8526                	mv	a0,s1
    80002700:	00000097          	auipc	ra,0x0
    80002704:	eb4080e7          	jalr	-332(ra) # 800025b4 <freeproc>
    release(&p->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	57c080e7          	jalr	1404(ra) # 80000c86 <release>
    return 0;
    80002712:	84ce                	mv	s1,s3
    80002714:	b7c9                	j	800026d6 <allocproc+0xca>

0000000080002716 <userinit>:
{
    80002716:	1101                	addi	sp,sp,-32
    80002718:	ec06                	sd	ra,24(sp)
    8000271a:	e822                	sd	s0,16(sp)
    8000271c:	e426                	sd	s1,8(sp)
    8000271e:	1000                	addi	s0,sp,32
  printf("SELECTION IS %d \n", SELECTION);
    80002720:	458d                	li	a1,3
    80002722:	00007517          	auipc	a0,0x7
    80002726:	c2e50513          	addi	a0,a0,-978 # 80009350 <digits+0x310>
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	e4a080e7          	jalr	-438(ra) # 80000574 <printf>
  p = allocproc();
    80002732:	00000097          	auipc	ra,0x0
    80002736:	eda080e7          	jalr	-294(ra) # 8000260c <allocproc>
    8000273a:	84aa                	mv	s1,a0
  initproc = p;
    8000273c:	00008797          	auipc	a5,0x8
    80002740:	8ea7b623          	sd	a0,-1812(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80002744:	03400613          	li	a2,52
    80002748:	00007597          	auipc	a1,0x7
    8000274c:	2c858593          	addi	a1,a1,712 # 80009a10 <initcode>
    80002750:	6928                	ld	a0,80(a0)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	bdc080e7          	jalr	-1060(ra) # 8000132e <uvminit>
  p->sz = PGSIZE;
    8000275a:	6785                	lui	a5,0x1
    8000275c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    8000275e:	6cb8                	ld	a4,88(s1)
    80002760:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80002764:	6cb8                	ld	a4,88(s1)
    80002766:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002768:	4641                	li	a2,16
    8000276a:	00007597          	auipc	a1,0x7
    8000276e:	bfe58593          	addi	a1,a1,-1026 # 80009368 <digits+0x328>
    80002772:	15848513          	addi	a0,s1,344
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	6aa080e7          	jalr	1706(ra) # 80000e20 <safestrcpy>
  p->cwd = namei("/");
    8000277e:	00007517          	auipc	a0,0x7
    80002782:	bfa50513          	addi	a0,a0,-1030 # 80009378 <digits+0x338>
    80002786:	00002097          	auipc	ra,0x2
    8000278a:	2f0080e7          	jalr	752(ra) # 80004a76 <namei>
    8000278e:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002792:	478d                	li	a5,3
    80002794:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	4ee080e7          	jalr	1262(ra) # 80000c86 <release>
}
    800027a0:	60e2                	ld	ra,24(sp)
    800027a2:	6442                	ld	s0,16(sp)
    800027a4:	64a2                	ld	s1,8(sp)
    800027a6:	6105                	addi	sp,sp,32
    800027a8:	8082                	ret

00000000800027aa <origin_growproc>:
int origin_growproc(int n){
    800027aa:	1101                	addi	sp,sp,-32
    800027ac:	ec06                	sd	ra,24(sp)
    800027ae:	e822                	sd	s0,16(sp)
    800027b0:	e426                	sd	s1,8(sp)
    800027b2:	e04a                	sd	s2,0(sp)
    800027b4:	1000                	addi	s0,sp,32
    800027b6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800027b8:	00000097          	auipc	ra,0x0
    800027bc:	c4a080e7          	jalr	-950(ra) # 80002402 <myproc>
    800027c0:	892a                	mv	s2,a0
  sz = p->sz;
    800027c2:	652c                	ld	a1,72(a0)
    800027c4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    800027c8:	00904f63          	bgtz	s1,800027e6 <origin_growproc+0x3c>
  } else if(n < 0){
    800027cc:	0204cc63          	bltz	s1,80002804 <origin_growproc+0x5a>
  p->sz = sz;
    800027d0:	1602                	slli	a2,a2,0x20
    800027d2:	9201                	srli	a2,a2,0x20
    800027d4:	04c93423          	sd	a2,72(s2)
  return 0;
    800027d8:	4501                	li	a0,0
}
    800027da:	60e2                	ld	ra,24(sp)
    800027dc:	6442                	ld	s0,16(sp)
    800027de:	64a2                	ld	s1,8(sp)
    800027e0:	6902                	ld	s2,0(sp)
    800027e2:	6105                	addi	sp,sp,32
    800027e4:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    800027e6:	9e25                	addw	a2,a2,s1
    800027e8:	1602                	slli	a2,a2,0x20
    800027ea:	9201                	srli	a2,a2,0x20
    800027ec:	1582                	slli	a1,a1,0x20
    800027ee:	9181                	srli	a1,a1,0x20
    800027f0:	6928                	ld	a0,80(a0)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	30e080e7          	jalr	782(ra) # 80001b00 <uvmalloc>
    800027fa:	0005061b          	sext.w	a2,a0
    800027fe:	fa69                	bnez	a2,800027d0 <origin_growproc+0x26>
      return -1;
    80002800:	557d                	li	a0,-1
    80002802:	bfe1                	j	800027da <origin_growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002804:	9e25                	addw	a2,a2,s1
    80002806:	1602                	slli	a2,a2,0x20
    80002808:	9201                	srli	a2,a2,0x20
    8000280a:	1582                	slli	a1,a1,0x20
    8000280c:	9181                	srli	a1,a1,0x20
    8000280e:	6928                	ld	a0,80(a0)
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	1fe080e7          	jalr	510(ra) # 80001a0e <uvmdealloc>
    80002818:	0005061b          	sext.w	a2,a0
    8000281c:	bf55                	j	800027d0 <origin_growproc+0x26>

000000008000281e <growproc>:
{
    8000281e:	1101                	addi	sp,sp,-32
    80002820:	ec06                	sd	ra,24(sp)
    80002822:	e822                	sd	s0,16(sp)
    80002824:	e426                	sd	s1,8(sp)
    80002826:	e04a                	sd	s2,0(sp)
    80002828:	1000                	addi	s0,sp,32
    8000282a:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000282c:	00000097          	auipc	ra,0x0
    80002830:	bd6080e7          	jalr	-1066(ra) # 80002402 <myproc>
    80002834:	84aa                	mv	s1,a0
  if(n < 0){
    80002836:	00094d63          	bltz	s2,80002850 <growproc+0x32>
  p->sz = p->sz + n;
    8000283a:	64a8                	ld	a0,72(s1)
    8000283c:	992a                	add	s2,s2,a0
    8000283e:	0524b423          	sd	s2,72(s1)
}
    80002842:	4501                	li	a0,0
    80002844:	60e2                	ld	ra,24(sp)
    80002846:	6442                	ld	s0,16(sp)
    80002848:	64a2                	ld	s1,8(sp)
    8000284a:	6902                	ld	s2,0(sp)
    8000284c:	6105                	addi	sp,sp,32
    8000284e:	8082                	ret
  sz = p->sz;
    80002850:	652c                	ld	a1,72(a0)
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002852:	00b9063b          	addw	a2,s2,a1
    80002856:	1602                	slli	a2,a2,0x20
    80002858:	9201                	srli	a2,a2,0x20
    8000285a:	1582                	slli	a1,a1,0x20
    8000285c:	9181                	srli	a1,a1,0x20
    8000285e:	6928                	ld	a0,80(a0)
    80002860:	fffff097          	auipc	ra,0xfffff
    80002864:	1ae080e7          	jalr	430(ra) # 80001a0e <uvmdealloc>
    80002868:	bfc9                	j	8000283a <growproc+0x1c>

000000008000286a <copy_swap_file>:
copy_swap_file(struct proc* child){
    8000286a:	7139                	addi	sp,sp,-64
    8000286c:	fc06                	sd	ra,56(sp)
    8000286e:	f822                	sd	s0,48(sp)
    80002870:	f426                	sd	s1,40(sp)
    80002872:	f04a                	sd	s2,32(sp)
    80002874:	ec4e                	sd	s3,24(sp)
    80002876:	e852                	sd	s4,16(sp)
    80002878:	e456                	sd	s5,8(sp)
    8000287a:	e05a                	sd	s6,0(sp)
    8000287c:	0080                	addi	s0,sp,64
    8000287e:	8b2a                	mv	s6,a0
  struct proc * pParent = myproc();
    80002880:	00000097          	auipc	ra,0x0
    80002884:	b82080e7          	jalr	-1150(ra) # 80002402 <myproc>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    80002888:	653c                	ld	a5,72(a0)
    8000288a:	cfd9                	beqz	a5,80002928 <copy_swap_file+0xbe>
    8000288c:	8a2a                	mv	s4,a0
    8000288e:	4481                	li	s1,0
    if(offset != -1){
    80002890:	5afd                	li	s5,-1
    80002892:	a83d                	j	800028d0 <copy_swap_file+0x66>
      panic("not enough space to kalloc");
    80002894:	00007517          	auipc	a0,0x7
    80002898:	a3450513          	addi	a0,a0,-1484 # 800092c8 <digits+0x288>
    8000289c:	ffffe097          	auipc	ra,0xffffe
    800028a0:	c8e080e7          	jalr	-882(ra) # 8000052a <panic>
          panic("read swap file failed\n");
    800028a4:	00007517          	auipc	a0,0x7
    800028a8:	adc50513          	addi	a0,a0,-1316 # 80009380 <digits+0x340>
    800028ac:	ffffe097          	auipc	ra,0xffffe
    800028b0:	c7e080e7          	jalr	-898(ra) # 8000052a <panic>
          panic("write swap file failed\n");
    800028b4:	00007517          	auipc	a0,0x7
    800028b8:	ae450513          	addi	a0,a0,-1308 # 80009398 <digits+0x358>
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	c6e080e7          	jalr	-914(ra) # 8000052a <panic>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    800028c4:	6785                	lui	a5,0x1
    800028c6:	94be                	add	s1,s1,a5
    800028c8:	048a3783          	ld	a5,72(s4)
    800028cc:	04f4fe63          	bgeu	s1,a5,80002928 <copy_swap_file+0xbe>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    800028d0:	00c4d713          	srli	a4,s1,0xc
    800028d4:	00171793          	slli	a5,a4,0x1
    800028d8:	97ba                	add	a5,a5,a4
    800028da:	078a                	slli	a5,a5,0x2
    800028dc:	97d2                	add	a5,a5,s4
    800028de:	1707a903          	lw	s2,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    800028e2:	ff5901e3          	beq	s2,s5,800028c4 <copy_swap_file+0x5a>
      if((buffer = kalloc()) == 0)
    800028e6:	ffffe097          	auipc	ra,0xffffe
    800028ea:	1fc080e7          	jalr	508(ra) # 80000ae2 <kalloc>
    800028ee:	89aa                	mv	s3,a0
    800028f0:	d155                	beqz	a0,80002894 <copy_swap_file+0x2a>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    800028f2:	2901                	sext.w	s2,s2
    800028f4:	6685                	lui	a3,0x1
    800028f6:	864a                	mv	a2,s2
    800028f8:	85aa                	mv	a1,a0
    800028fa:	8552                	mv	a0,s4
    800028fc:	00002097          	auipc	ra,0x2
    80002900:	4a2080e7          	jalr	1186(ra) # 80004d9e <readFromSwapFile>
    80002904:	fb5500e3          	beq	a0,s5,800028a4 <copy_swap_file+0x3a>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    80002908:	6685                	lui	a3,0x1
    8000290a:	864a                	mv	a2,s2
    8000290c:	85ce                	mv	a1,s3
    8000290e:	855a                	mv	a0,s6
    80002910:	00002097          	auipc	ra,0x2
    80002914:	46a080e7          	jalr	1130(ra) # 80004d7a <writeToSwapFile>
    80002918:	f9550ee3          	beq	a0,s5,800028b4 <copy_swap_file+0x4a>
      kfree(buffer);
    8000291c:	854e                	mv	a0,s3
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	0b8080e7          	jalr	184(ra) # 800009d6 <kfree>
    80002926:	bf79                	j	800028c4 <copy_swap_file+0x5a>
}
    80002928:	70e2                	ld	ra,56(sp)
    8000292a:	7442                	ld	s0,48(sp)
    8000292c:	74a2                	ld	s1,40(sp)
    8000292e:	7902                	ld	s2,32(sp)
    80002930:	69e2                	ld	s3,24(sp)
    80002932:	6a42                	ld	s4,16(sp)
    80002934:	6aa2                	ld	s5,8(sp)
    80002936:	6b02                	ld	s6,0(sp)
    80002938:	6121                	addi	sp,sp,64
    8000293a:	8082                	ret

000000008000293c <fork>:
{
    8000293c:	715d                	addi	sp,sp,-80
    8000293e:	e486                	sd	ra,72(sp)
    80002940:	e0a2                	sd	s0,64(sp)
    80002942:	fc26                	sd	s1,56(sp)
    80002944:	f84a                	sd	s2,48(sp)
    80002946:	f44e                	sd	s3,40(sp)
    80002948:	f052                	sd	s4,32(sp)
    8000294a:	ec56                	sd	s5,24(sp)
    8000294c:	e85a                	sd	s6,16(sp)
    8000294e:	e45e                	sd	s7,8(sp)
    80002950:	e062                	sd	s8,0(sp)
    80002952:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80002954:	00000097          	auipc	ra,0x0
    80002958:	aae080e7          	jalr	-1362(ra) # 80002402 <myproc>
    8000295c:	8b2a                	mv	s6,a0
  if((np = allocproc()) == 0){
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	cae080e7          	jalr	-850(ra) # 8000260c <allocproc>
    80002966:	20050263          	beqz	a0,80002b6a <fork+0x22e>
    8000296a:	8aaa                	mv	s5,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000296c:	048b3603          	ld	a2,72(s6)
    80002970:	692c                	ld	a1,80(a0)
    80002972:	050b3503          	ld	a0,80(s6)
    80002976:	fffff097          	auipc	ra,0xfffff
    8000297a:	456080e7          	jalr	1110(ra) # 80001dcc <uvmcopy>
    8000297e:	04054863          	bltz	a0,800029ce <fork+0x92>
  np->sz = p->sz;
    80002982:	048b3783          	ld	a5,72(s6)
    80002986:	04fab423          	sd	a5,72(s5)
  *(np->trapframe) = *(p->trapframe);
    8000298a:	058b3683          	ld	a3,88(s6)
    8000298e:	87b6                	mv	a5,a3
    80002990:	058ab703          	ld	a4,88(s5)
    80002994:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    80002998:	0007b803          	ld	a6,0(a5)
    8000299c:	6788                	ld	a0,8(a5)
    8000299e:	6b8c                	ld	a1,16(a5)
    800029a0:	6f90                	ld	a2,24(a5)
    800029a2:	01073023          	sd	a6,0(a4)
    800029a6:	e708                	sd	a0,8(a4)
    800029a8:	eb0c                	sd	a1,16(a4)
    800029aa:	ef10                	sd	a2,24(a4)
    800029ac:	02078793          	addi	a5,a5,32
    800029b0:	02070713          	addi	a4,a4,32
    800029b4:	fed792e3          	bne	a5,a3,80002998 <fork+0x5c>
  np->trapframe->a0 = 0;
    800029b8:	058ab783          	ld	a5,88(s5)
    800029bc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    800029c0:	0d0b0493          	addi	s1,s6,208
    800029c4:	0d0a8913          	addi	s2,s5,208
    800029c8:	150b0993          	addi	s3,s6,336
    800029cc:	a03d                	j	800029fa <fork+0xbe>
    freeproc(np);
    800029ce:	8556                	mv	a0,s5
    800029d0:	00000097          	auipc	ra,0x0
    800029d4:	be4080e7          	jalr	-1052(ra) # 800025b4 <freeproc>
    release(&np->lock);
    800029d8:	8556                	mv	a0,s5
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	2ac080e7          	jalr	684(ra) # 80000c86 <release>
    return -1;
    800029e2:	5bfd                	li	s7,-1
    800029e4:	aa81                	j	80002b34 <fork+0x1f8>
      np->ofile[i] = filedup(p->ofile[i]);
    800029e6:	00003097          	auipc	ra,0x3
    800029ea:	a3c080e7          	jalr	-1476(ra) # 80005422 <filedup>
    800029ee:	00a93023          	sd	a0,0(s2)
  for(i = 0; i < NOFILE; i++)
    800029f2:	04a1                	addi	s1,s1,8
    800029f4:	0921                	addi	s2,s2,8
    800029f6:	01348563          	beq	s1,s3,80002a00 <fork+0xc4>
    if(p->ofile[i])
    800029fa:	6088                	ld	a0,0(s1)
    800029fc:	f56d                	bnez	a0,800029e6 <fork+0xaa>
    800029fe:	bfd5                	j	800029f2 <fork+0xb6>
  np->cwd = idup(p->cwd);
    80002a00:	150b3503          	ld	a0,336(s6)
    80002a04:	00002097          	auipc	ra,0x2
    80002a08:	87e080e7          	jalr	-1922(ra) # 80004282 <idup>
    80002a0c:	14aab823          	sd	a0,336(s5)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002a10:	4641                	li	a2,16
    80002a12:	158b0593          	addi	a1,s6,344
    80002a16:	158a8513          	addi	a0,s5,344
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	406080e7          	jalr	1030(ra) # 80000e20 <safestrcpy>
  pid = np->pid;
    80002a22:	030aab83          	lw	s7,48(s5)
  release(&np->lock);
    80002a26:	8556                	mv	a0,s5
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	25e080e7          	jalr	606(ra) # 80000c86 <release>
      if(createSwapFile(np) != 0){
    80002a30:	8556                	mv	a0,s5
    80002a32:	00002097          	auipc	ra,0x2
    80002a36:	298080e7          	jalr	664(ra) # 80004cca <createSwapFile>
    80002a3a:	8a2a                	mv	s4,a0
    80002a3c:	10051963          	bnez	a0,80002b4e <fork+0x212>
    if(p->pid > 1){ 
    80002a40:	030b2703          	lw	a4,48(s6)
    80002a44:	4785                	li	a5,1
    80002a46:	10e7cc63          	blt	a5,a4,80002b5e <fork+0x222>
  for(int i=0; i<32; i++){
    80002a4a:	170a8993          	addi	s3,s5,368
{
    80002a4e:	8952                	mv	s2,s4
  for(int i=0; i<32; i++){
    80002a50:	02000c13          	li	s8,32
    np->paging_meta_data[i].offset = myproc()->paging_meta_data[i].offset;
    80002a54:	00000097          	auipc	ra,0x0
    80002a58:	9ae080e7          	jalr	-1618(ra) # 80002402 <myproc>
    80002a5c:	00191493          	slli	s1,s2,0x1
    80002a60:	012487b3          	add	a5,s1,s2
    80002a64:	078a                	slli	a5,a5,0x2
    80002a66:	953e                	add	a0,a0,a5
    80002a68:	17052783          	lw	a5,368(a0)
    80002a6c:	00f9a023          	sw	a5,0(s3)
    np->paging_meta_data[i].aging = myproc()->paging_meta_data[i].aging;
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	992080e7          	jalr	-1646(ra) # 80002402 <myproc>
    80002a78:	012487b3          	add	a5,s1,s2
    80002a7c:	078a                	slli	a5,a5,0x2
    80002a7e:	953e                	add	a0,a0,a5
    80002a80:	17452783          	lw	a5,372(a0)
    80002a84:	00f9a223          	sw	a5,4(s3)
    np->paging_meta_data[i].in_memory = myproc()->paging_meta_data[i].in_memory;
    80002a88:	00000097          	auipc	ra,0x0
    80002a8c:	97a080e7          	jalr	-1670(ra) # 80002402 <myproc>
    80002a90:	94ca                	add	s1,s1,s2
    80002a92:	048a                	slli	s1,s1,0x2
    80002a94:	94aa                	add	s1,s1,a0
    80002a96:	1784a783          	lw	a5,376(s1)
    80002a9a:	00f9a423          	sw	a5,8(s3)
  for(int i=0; i<32; i++){
    80002a9e:	2905                	addiw	s2,s2,1
    80002aa0:	09b1                	addi	s3,s3,12
    80002aa2:	fb8919e3          	bne	s2,s8,80002a54 <fork+0x118>
  np->queue.front = myproc()->queue.front;
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	95c080e7          	jalr	-1700(ra) # 80002402 <myproc>
    80002aae:	37052783          	lw	a5,880(a0)
    80002ab2:	36faa823          	sw	a5,880(s5)
  np->queue.last = myproc()->queue.last;
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	94c080e7          	jalr	-1716(ra) # 80002402 <myproc>
    80002abe:	37452783          	lw	a5,884(a0)
    80002ac2:	36faaa23          	sw	a5,884(s5)
  np->queue.page_counter = myproc()->queue.page_counter;
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	93c080e7          	jalr	-1732(ra) # 80002402 <myproc>
    80002ace:	37852783          	lw	a5,888(a0)
    80002ad2:	36faac23          	sw	a5,888(s5)
  for(int i=0; i<32; i++){
    80002ad6:	2f0a8493          	addi	s1,s5,752
    80002ada:	02000913          	li	s2,32
    np->queue.pages[i] = myproc()->queue.pages[i];
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	924080e7          	jalr	-1756(ra) # 80002402 <myproc>
    80002ae6:	0bca0793          	addi	a5,s4,188
    80002aea:	078a                	slli	a5,a5,0x2
    80002aec:	953e                	add	a0,a0,a5
    80002aee:	411c                	lw	a5,0(a0)
    80002af0:	c09c                	sw	a5,0(s1)
  for(int i=0; i<32; i++){
    80002af2:	2a05                	addiw	s4,s4,1
    80002af4:	0491                	addi	s1,s1,4
    80002af6:	ff2a14e3          	bne	s4,s2,80002ade <fork+0x1a2>
  acquire(&wait_lock);
    80002afa:	0000f497          	auipc	s1,0xf
    80002afe:	7be48493          	addi	s1,s1,1982 # 800122b8 <wait_lock>
    80002b02:	8526                	mv	a0,s1
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	0ce080e7          	jalr	206(ra) # 80000bd2 <acquire>
  np->parent = p;
    80002b0c:	036abc23          	sd	s6,56(s5)
  release(&wait_lock);
    80002b10:	8526                	mv	a0,s1
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	174080e7          	jalr	372(ra) # 80000c86 <release>
  acquire(&np->lock);
    80002b1a:	8556                	mv	a0,s5
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	0b6080e7          	jalr	182(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80002b24:	478d                	li	a5,3
    80002b26:	00faac23          	sw	a5,24(s5)
  release(&np->lock);
    80002b2a:	8556                	mv	a0,s5
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	15a080e7          	jalr	346(ra) # 80000c86 <release>
}
    80002b34:	855e                	mv	a0,s7
    80002b36:	60a6                	ld	ra,72(sp)
    80002b38:	6406                	ld	s0,64(sp)
    80002b3a:	74e2                	ld	s1,56(sp)
    80002b3c:	7942                	ld	s2,48(sp)
    80002b3e:	79a2                	ld	s3,40(sp)
    80002b40:	7a02                	ld	s4,32(sp)
    80002b42:	6ae2                	ld	s5,24(sp)
    80002b44:	6b42                	ld	s6,16(sp)
    80002b46:	6ba2                	ld	s7,8(sp)
    80002b48:	6c02                	ld	s8,0(sp)
    80002b4a:	6161                	addi	sp,sp,80
    80002b4c:	8082                	ret
        panic("create swap file failed");
    80002b4e:	00007517          	auipc	a0,0x7
    80002b52:	86250513          	addi	a0,a0,-1950 # 800093b0 <digits+0x370>
    80002b56:	ffffe097          	auipc	ra,0xffffe
    80002b5a:	9d4080e7          	jalr	-1580(ra) # 8000052a <panic>
        copy_swap_file(np);
    80002b5e:	8556                	mv	a0,s5
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	d0a080e7          	jalr	-758(ra) # 8000286a <copy_swap_file>
    80002b68:	b5cd                	j	80002a4a <fork+0x10e>
    return -1;
    80002b6a:	5bfd                	li	s7,-1
    80002b6c:	b7e1                	j	80002b34 <fork+0x1f8>

0000000080002b6e <scheduler>:
{
    80002b6e:	7139                	addi	sp,sp,-64
    80002b70:	fc06                	sd	ra,56(sp)
    80002b72:	f822                	sd	s0,48(sp)
    80002b74:	f426                	sd	s1,40(sp)
    80002b76:	f04a                	sd	s2,32(sp)
    80002b78:	ec4e                	sd	s3,24(sp)
    80002b7a:	e852                	sd	s4,16(sp)
    80002b7c:	e456                	sd	s5,8(sp)
    80002b7e:	e05a                	sd	s6,0(sp)
    80002b80:	0080                	addi	s0,sp,64
    80002b82:	8792                	mv	a5,tp
  int id = r_tp();
    80002b84:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002b86:	00779a93          	slli	s5,a5,0x7
    80002b8a:	0000f717          	auipc	a4,0xf
    80002b8e:	71670713          	addi	a4,a4,1814 # 800122a0 <pid_lock>
    80002b92:	9756                	add	a4,a4,s5
    80002b94:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002b98:	0000f717          	auipc	a4,0xf
    80002b9c:	74070713          	addi	a4,a4,1856 # 800122d8 <cpus+0x8>
    80002ba0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002ba2:	498d                	li	s3,3
        p->state = RUNNING;
    80002ba4:	4b11                	li	s6,4
        c->proc = p;
    80002ba6:	079e                	slli	a5,a5,0x7
    80002ba8:	0000fa17          	auipc	s4,0xf
    80002bac:	6f8a0a13          	addi	s4,s4,1784 # 800122a0 <pid_lock>
    80002bb0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002bb2:	0001e917          	auipc	s2,0x1e
    80002bb6:	b1e90913          	addi	s2,s2,-1250 # 800206d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bbe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc2:	10079073          	csrw	sstatus,a5
    80002bc6:	00010497          	auipc	s1,0x10
    80002bca:	b0a48493          	addi	s1,s1,-1270 # 800126d0 <proc>
    80002bce:	a811                	j	80002be2 <scheduler+0x74>
      release(&p->lock);
    80002bd0:	8526                	mv	a0,s1
    80002bd2:	ffffe097          	auipc	ra,0xffffe
    80002bd6:	0b4080e7          	jalr	180(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002bda:	38048493          	addi	s1,s1,896
    80002bde:	fd248ee3          	beq	s1,s2,80002bba <scheduler+0x4c>
      acquire(&p->lock);
    80002be2:	8526                	mv	a0,s1
    80002be4:	ffffe097          	auipc	ra,0xffffe
    80002be8:	fee080e7          	jalr	-18(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80002bec:	4c9c                	lw	a5,24(s1)
    80002bee:	ff3791e3          	bne	a5,s3,80002bd0 <scheduler+0x62>
        p->state = RUNNING;
    80002bf2:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002bf6:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002bfa:	06048593          	addi	a1,s1,96
    80002bfe:	8556                	mv	a0,s5
    80002c00:	00000097          	auipc	ra,0x0
    80002c04:	63e080e7          	jalr	1598(ra) # 8000323e <swtch>
        update_aging_algorithms();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	662080e7          	jalr	1634(ra) # 8000226a <update_aging_algorithms>
        c->proc = 0;
    80002c10:	020a3823          	sd	zero,48(s4)
    80002c14:	bf75                	j	80002bd0 <scheduler+0x62>

0000000080002c16 <sched>:
{
    80002c16:	7179                	addi	sp,sp,-48
    80002c18:	f406                	sd	ra,40(sp)
    80002c1a:	f022                	sd	s0,32(sp)
    80002c1c:	ec26                	sd	s1,24(sp)
    80002c1e:	e84a                	sd	s2,16(sp)
    80002c20:	e44e                	sd	s3,8(sp)
    80002c22:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	7de080e7          	jalr	2014(ra) # 80002402 <myproc>
    80002c2c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	f2a080e7          	jalr	-214(ra) # 80000b58 <holding>
    80002c36:	c93d                	beqz	a0,80002cac <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c38:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002c3a:	2781                	sext.w	a5,a5
    80002c3c:	079e                	slli	a5,a5,0x7
    80002c3e:	0000f717          	auipc	a4,0xf
    80002c42:	66270713          	addi	a4,a4,1634 # 800122a0 <pid_lock>
    80002c46:	97ba                	add	a5,a5,a4
    80002c48:	0a87a703          	lw	a4,168(a5)
    80002c4c:	4785                	li	a5,1
    80002c4e:	06f71763          	bne	a4,a5,80002cbc <sched+0xa6>
  if(p->state == RUNNING)
    80002c52:	4c98                	lw	a4,24(s1)
    80002c54:	4791                	li	a5,4
    80002c56:	06f70b63          	beq	a4,a5,80002ccc <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c5e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002c60:	efb5                	bnez	a5,80002cdc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c62:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002c64:	0000f917          	auipc	s2,0xf
    80002c68:	63c90913          	addi	s2,s2,1596 # 800122a0 <pid_lock>
    80002c6c:	2781                	sext.w	a5,a5
    80002c6e:	079e                	slli	a5,a5,0x7
    80002c70:	97ca                	add	a5,a5,s2
    80002c72:	0ac7a983          	lw	s3,172(a5)
    80002c76:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002c78:	2781                	sext.w	a5,a5
    80002c7a:	079e                	slli	a5,a5,0x7
    80002c7c:	0000f597          	auipc	a1,0xf
    80002c80:	65c58593          	addi	a1,a1,1628 # 800122d8 <cpus+0x8>
    80002c84:	95be                	add	a1,a1,a5
    80002c86:	06048513          	addi	a0,s1,96
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	5b4080e7          	jalr	1460(ra) # 8000323e <swtch>
    80002c92:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002c94:	2781                	sext.w	a5,a5
    80002c96:	079e                	slli	a5,a5,0x7
    80002c98:	97ca                	add	a5,a5,s2
    80002c9a:	0b37a623          	sw	s3,172(a5)
}
    80002c9e:	70a2                	ld	ra,40(sp)
    80002ca0:	7402                	ld	s0,32(sp)
    80002ca2:	64e2                	ld	s1,24(sp)
    80002ca4:	6942                	ld	s2,16(sp)
    80002ca6:	69a2                	ld	s3,8(sp)
    80002ca8:	6145                	addi	sp,sp,48
    80002caa:	8082                	ret
    panic("sched p->lock");
    80002cac:	00006517          	auipc	a0,0x6
    80002cb0:	71c50513          	addi	a0,a0,1820 # 800093c8 <digits+0x388>
    80002cb4:	ffffe097          	auipc	ra,0xffffe
    80002cb8:	876080e7          	jalr	-1930(ra) # 8000052a <panic>
    panic("sched locks");
    80002cbc:	00006517          	auipc	a0,0x6
    80002cc0:	71c50513          	addi	a0,a0,1820 # 800093d8 <digits+0x398>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	866080e7          	jalr	-1946(ra) # 8000052a <panic>
    panic("sched running");
    80002ccc:	00006517          	auipc	a0,0x6
    80002cd0:	71c50513          	addi	a0,a0,1820 # 800093e8 <digits+0x3a8>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	856080e7          	jalr	-1962(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002cdc:	00006517          	auipc	a0,0x6
    80002ce0:	71c50513          	addi	a0,a0,1820 # 800093f8 <digits+0x3b8>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	846080e7          	jalr	-1978(ra) # 8000052a <panic>

0000000080002cec <yield>:
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	e426                	sd	s1,8(sp)
    80002cf4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002cf6:	fffff097          	auipc	ra,0xfffff
    80002cfa:	70c080e7          	jalr	1804(ra) # 80002402 <myproc>
    80002cfe:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	ed2080e7          	jalr	-302(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002d08:	478d                	li	a5,3
    80002d0a:	cc9c                	sw	a5,24(s1)
  sched();
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	f0a080e7          	jalr	-246(ra) # 80002c16 <sched>
  release(&p->lock);
    80002d14:	8526                	mv	a0,s1
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	f70080e7          	jalr	-144(ra) # 80000c86 <release>
}
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	e84a                	sd	s2,16(sp)
    80002d32:	e44e                	sd	s3,8(sp)
    80002d34:	1800                	addi	s0,sp,48
    80002d36:	89aa                	mv	s3,a0
    80002d38:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	6c8080e7          	jalr	1736(ra) # 80002402 <myproc>
    80002d42:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	e8e080e7          	jalr	-370(ra) # 80000bd2 <acquire>
  release(lk);
    80002d4c:	854a                	mv	a0,s2
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	f38080e7          	jalr	-200(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002d56:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002d5a:	4789                	li	a5,2
    80002d5c:	cc9c                	sw	a5,24(s1)

  sched();
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	eb8080e7          	jalr	-328(ra) # 80002c16 <sched>

  // Tidy up.
  p->chan = 0;
    80002d66:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002d6a:	8526                	mv	a0,s1
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	f1a080e7          	jalr	-230(ra) # 80000c86 <release>
  acquire(lk);
    80002d74:	854a                	mv	a0,s2
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	e5c080e7          	jalr	-420(ra) # 80000bd2 <acquire>
}
    80002d7e:	70a2                	ld	ra,40(sp)
    80002d80:	7402                	ld	s0,32(sp)
    80002d82:	64e2                	ld	s1,24(sp)
    80002d84:	6942                	ld	s2,16(sp)
    80002d86:	69a2                	ld	s3,8(sp)
    80002d88:	6145                	addi	sp,sp,48
    80002d8a:	8082                	ret

0000000080002d8c <wait>:
{
    80002d8c:	715d                	addi	sp,sp,-80
    80002d8e:	e486                	sd	ra,72(sp)
    80002d90:	e0a2                	sd	s0,64(sp)
    80002d92:	fc26                	sd	s1,56(sp)
    80002d94:	f84a                	sd	s2,48(sp)
    80002d96:	f44e                	sd	s3,40(sp)
    80002d98:	f052                	sd	s4,32(sp)
    80002d9a:	ec56                	sd	s5,24(sp)
    80002d9c:	e85a                	sd	s6,16(sp)
    80002d9e:	e45e                	sd	s7,8(sp)
    80002da0:	e062                	sd	s8,0(sp)
    80002da2:	0880                	addi	s0,sp,80
    80002da4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	65c080e7          	jalr	1628(ra) # 80002402 <myproc>
    80002dae:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002db0:	0000f517          	auipc	a0,0xf
    80002db4:	50850513          	addi	a0,a0,1288 # 800122b8 <wait_lock>
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	e1a080e7          	jalr	-486(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002dc0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002dc2:	4a15                	li	s4,5
        havekids = 1;
    80002dc4:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002dc6:	0001e997          	auipc	s3,0x1e
    80002dca:	90a98993          	addi	s3,s3,-1782 # 800206d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002dce:	0000fc17          	auipc	s8,0xf
    80002dd2:	4eac0c13          	addi	s8,s8,1258 # 800122b8 <wait_lock>
    havekids = 0;
    80002dd6:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002dd8:	00010497          	auipc	s1,0x10
    80002ddc:	8f848493          	addi	s1,s1,-1800 # 800126d0 <proc>
    80002de0:	a0bd                	j	80002e4e <wait+0xc2>
          pid = np->pid;
    80002de2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002de6:	000b0e63          	beqz	s6,80002e02 <wait+0x76>
    80002dea:	4691                	li	a3,4
    80002dec:	02c48613          	addi	a2,s1,44
    80002df0:	85da                	mv	a1,s6
    80002df2:	05093503          	ld	a0,80(s2)
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	694080e7          	jalr	1684(ra) # 8000148a <copyout>
    80002dfe:	02054563          	bltz	a0,80002e28 <wait+0x9c>
          freeproc(np);
    80002e02:	8526                	mv	a0,s1
    80002e04:	fffff097          	auipc	ra,0xfffff
    80002e08:	7b0080e7          	jalr	1968(ra) # 800025b4 <freeproc>
          release(&np->lock);
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e78080e7          	jalr	-392(ra) # 80000c86 <release>
          release(&wait_lock);
    80002e16:	0000f517          	auipc	a0,0xf
    80002e1a:	4a250513          	addi	a0,a0,1186 # 800122b8 <wait_lock>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	e68080e7          	jalr	-408(ra) # 80000c86 <release>
          return pid;
    80002e26:	a09d                	j	80002e8c <wait+0x100>
            release(&np->lock);
    80002e28:	8526                	mv	a0,s1
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	e5c080e7          	jalr	-420(ra) # 80000c86 <release>
            release(&wait_lock);
    80002e32:	0000f517          	auipc	a0,0xf
    80002e36:	48650513          	addi	a0,a0,1158 # 800122b8 <wait_lock>
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	e4c080e7          	jalr	-436(ra) # 80000c86 <release>
            return -1;
    80002e42:	59fd                	li	s3,-1
    80002e44:	a0a1                	j	80002e8c <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002e46:	38048493          	addi	s1,s1,896
    80002e4a:	03348463          	beq	s1,s3,80002e72 <wait+0xe6>
      if(np->parent == p){
    80002e4e:	7c9c                	ld	a5,56(s1)
    80002e50:	ff279be3          	bne	a5,s2,80002e46 <wait+0xba>
        acquire(&np->lock);
    80002e54:	8526                	mv	a0,s1
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	d7c080e7          	jalr	-644(ra) # 80000bd2 <acquire>
        if(np->state == ZOMBIE){
    80002e5e:	4c9c                	lw	a5,24(s1)
    80002e60:	f94781e3          	beq	a5,s4,80002de2 <wait+0x56>
        release(&np->lock);
    80002e64:	8526                	mv	a0,s1
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	e20080e7          	jalr	-480(ra) # 80000c86 <release>
        havekids = 1;
    80002e6e:	8756                	mv	a4,s5
    80002e70:	bfd9                	j	80002e46 <wait+0xba>
    if(!havekids || p->killed){
    80002e72:	c701                	beqz	a4,80002e7a <wait+0xee>
    80002e74:	02892783          	lw	a5,40(s2)
    80002e78:	c79d                	beqz	a5,80002ea6 <wait+0x11a>
      release(&wait_lock);
    80002e7a:	0000f517          	auipc	a0,0xf
    80002e7e:	43e50513          	addi	a0,a0,1086 # 800122b8 <wait_lock>
    80002e82:	ffffe097          	auipc	ra,0xffffe
    80002e86:	e04080e7          	jalr	-508(ra) # 80000c86 <release>
      return -1;
    80002e8a:	59fd                	li	s3,-1
}
    80002e8c:	854e                	mv	a0,s3
    80002e8e:	60a6                	ld	ra,72(sp)
    80002e90:	6406                	ld	s0,64(sp)
    80002e92:	74e2                	ld	s1,56(sp)
    80002e94:	7942                	ld	s2,48(sp)
    80002e96:	79a2                	ld	s3,40(sp)
    80002e98:	7a02                	ld	s4,32(sp)
    80002e9a:	6ae2                	ld	s5,24(sp)
    80002e9c:	6b42                	ld	s6,16(sp)
    80002e9e:	6ba2                	ld	s7,8(sp)
    80002ea0:	6c02                	ld	s8,0(sp)
    80002ea2:	6161                	addi	sp,sp,80
    80002ea4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002ea6:	85e2                	mv	a1,s8
    80002ea8:	854a                	mv	a0,s2
    80002eaa:	00000097          	auipc	ra,0x0
    80002eae:	e7e080e7          	jalr	-386(ra) # 80002d28 <sleep>
    havekids = 0;
    80002eb2:	b715                	j	80002dd6 <wait+0x4a>

0000000080002eb4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002eb4:	7139                	addi	sp,sp,-64
    80002eb6:	fc06                	sd	ra,56(sp)
    80002eb8:	f822                	sd	s0,48(sp)
    80002eba:	f426                	sd	s1,40(sp)
    80002ebc:	f04a                	sd	s2,32(sp)
    80002ebe:	ec4e                	sd	s3,24(sp)
    80002ec0:	e852                	sd	s4,16(sp)
    80002ec2:	e456                	sd	s5,8(sp)
    80002ec4:	0080                	addi	s0,sp,64
    80002ec6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002ec8:	00010497          	auipc	s1,0x10
    80002ecc:	80848493          	addi	s1,s1,-2040 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002ed0:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002ed2:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002ed4:	0001d917          	auipc	s2,0x1d
    80002ed8:	7fc90913          	addi	s2,s2,2044 # 800206d0 <tickslock>
    80002edc:	a811                	j	80002ef0 <wakeup+0x3c>
      }
      release(&p->lock);
    80002ede:	8526                	mv	a0,s1
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	da6080e7          	jalr	-602(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002ee8:	38048493          	addi	s1,s1,896
    80002eec:	03248663          	beq	s1,s2,80002f18 <wakeup+0x64>
    if(p != myproc()){
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	512080e7          	jalr	1298(ra) # 80002402 <myproc>
    80002ef8:	fea488e3          	beq	s1,a0,80002ee8 <wakeup+0x34>
      acquire(&p->lock);
    80002efc:	8526                	mv	a0,s1
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	cd4080e7          	jalr	-812(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002f06:	4c9c                	lw	a5,24(s1)
    80002f08:	fd379be3          	bne	a5,s3,80002ede <wakeup+0x2a>
    80002f0c:	709c                	ld	a5,32(s1)
    80002f0e:	fd4798e3          	bne	a5,s4,80002ede <wakeup+0x2a>
        p->state = RUNNABLE;
    80002f12:	0154ac23          	sw	s5,24(s1)
    80002f16:	b7e1                	j	80002ede <wakeup+0x2a>
    }
  }
}
    80002f18:	70e2                	ld	ra,56(sp)
    80002f1a:	7442                	ld	s0,48(sp)
    80002f1c:	74a2                	ld	s1,40(sp)
    80002f1e:	7902                	ld	s2,32(sp)
    80002f20:	69e2                	ld	s3,24(sp)
    80002f22:	6a42                	ld	s4,16(sp)
    80002f24:	6aa2                	ld	s5,8(sp)
    80002f26:	6121                	addi	sp,sp,64
    80002f28:	8082                	ret

0000000080002f2a <reparent>:
{
    80002f2a:	7179                	addi	sp,sp,-48
    80002f2c:	f406                	sd	ra,40(sp)
    80002f2e:	f022                	sd	s0,32(sp)
    80002f30:	ec26                	sd	s1,24(sp)
    80002f32:	e84a                	sd	s2,16(sp)
    80002f34:	e44e                	sd	s3,8(sp)
    80002f36:	e052                	sd	s4,0(sp)
    80002f38:	1800                	addi	s0,sp,48
    80002f3a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002f3c:	0000f497          	auipc	s1,0xf
    80002f40:	79448493          	addi	s1,s1,1940 # 800126d0 <proc>
      pp->parent = initproc;
    80002f44:	00007a17          	auipc	s4,0x7
    80002f48:	0e4a0a13          	addi	s4,s4,228 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002f4c:	0001d997          	auipc	s3,0x1d
    80002f50:	78498993          	addi	s3,s3,1924 # 800206d0 <tickslock>
    80002f54:	a029                	j	80002f5e <reparent+0x34>
    80002f56:	38048493          	addi	s1,s1,896
    80002f5a:	01348d63          	beq	s1,s3,80002f74 <reparent+0x4a>
    if(pp->parent == p){
    80002f5e:	7c9c                	ld	a5,56(s1)
    80002f60:	ff279be3          	bne	a5,s2,80002f56 <reparent+0x2c>
      pp->parent = initproc;
    80002f64:	000a3503          	ld	a0,0(s4)
    80002f68:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	f4a080e7          	jalr	-182(ra) # 80002eb4 <wakeup>
    80002f72:	b7d5                	j	80002f56 <reparent+0x2c>
}
    80002f74:	70a2                	ld	ra,40(sp)
    80002f76:	7402                	ld	s0,32(sp)
    80002f78:	64e2                	ld	s1,24(sp)
    80002f7a:	6942                	ld	s2,16(sp)
    80002f7c:	69a2                	ld	s3,8(sp)
    80002f7e:	6a02                	ld	s4,0(sp)
    80002f80:	6145                	addi	sp,sp,48
    80002f82:	8082                	ret

0000000080002f84 <exit>:
{
    80002f84:	7179                	addi	sp,sp,-48
    80002f86:	f406                	sd	ra,40(sp)
    80002f88:	f022                	sd	s0,32(sp)
    80002f8a:	ec26                	sd	s1,24(sp)
    80002f8c:	e84a                	sd	s2,16(sp)
    80002f8e:	e44e                	sd	s3,8(sp)
    80002f90:	e052                	sd	s4,0(sp)
    80002f92:	1800                	addi	s0,sp,48
    80002f94:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	46c080e7          	jalr	1132(ra) # 80002402 <myproc>
    80002f9e:	89aa                	mv	s3,a0
  if(p == initproc)
    80002fa0:	00007797          	auipc	a5,0x7
    80002fa4:	0887b783          	ld	a5,136(a5) # 8000a028 <initproc>
    80002fa8:	0d050493          	addi	s1,a0,208
    80002fac:	15050913          	addi	s2,a0,336
    80002fb0:	02a79363          	bne	a5,a0,80002fd6 <exit+0x52>
    panic("init exiting");
    80002fb4:	00006517          	auipc	a0,0x6
    80002fb8:	45c50513          	addi	a0,a0,1116 # 80009410 <digits+0x3d0>
    80002fbc:	ffffd097          	auipc	ra,0xffffd
    80002fc0:	56e080e7          	jalr	1390(ra) # 8000052a <panic>
      fileclose(f);
    80002fc4:	00002097          	auipc	ra,0x2
    80002fc8:	4b0080e7          	jalr	1200(ra) # 80005474 <fileclose>
      p->ofile[fd] = 0;
    80002fcc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002fd0:	04a1                	addi	s1,s1,8
    80002fd2:	01248563          	beq	s1,s2,80002fdc <exit+0x58>
    if(p->ofile[fd]){
    80002fd6:	6088                	ld	a0,0(s1)
    80002fd8:	f575                	bnez	a0,80002fc4 <exit+0x40>
    80002fda:	bfdd                	j	80002fd0 <exit+0x4c>
  if(p->pid > 1)
    80002fdc:	0309a703          	lw	a4,48(s3)
    80002fe0:	4785                	li	a5,1
    80002fe2:	08e7c163          	blt	a5,a4,80003064 <exit+0xe0>
  begin_op();
    80002fe6:	00002097          	auipc	ra,0x2
    80002fea:	fc2080e7          	jalr	-62(ra) # 80004fa8 <begin_op>
  iput(p->cwd);
    80002fee:	1509b503          	ld	a0,336(s3)
    80002ff2:	00001097          	auipc	ra,0x1
    80002ff6:	488080e7          	jalr	1160(ra) # 8000447a <iput>
  end_op();
    80002ffa:	00002097          	auipc	ra,0x2
    80002ffe:	02e080e7          	jalr	46(ra) # 80005028 <end_op>
  p->cwd = 0;
    80003002:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80003006:	0000f497          	auipc	s1,0xf
    8000300a:	2b248493          	addi	s1,s1,690 # 800122b8 <wait_lock>
    8000300e:	8526                	mv	a0,s1
    80003010:	ffffe097          	auipc	ra,0xffffe
    80003014:	bc2080e7          	jalr	-1086(ra) # 80000bd2 <acquire>
  reparent(p);
    80003018:	854e                	mv	a0,s3
    8000301a:	00000097          	auipc	ra,0x0
    8000301e:	f10080e7          	jalr	-240(ra) # 80002f2a <reparent>
  wakeup(p->parent);
    80003022:	0389b503          	ld	a0,56(s3)
    80003026:	00000097          	auipc	ra,0x0
    8000302a:	e8e080e7          	jalr	-370(ra) # 80002eb4 <wakeup>
  acquire(&p->lock);
    8000302e:	854e                	mv	a0,s3
    80003030:	ffffe097          	auipc	ra,0xffffe
    80003034:	ba2080e7          	jalr	-1118(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80003038:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000303c:	4795                	li	a5,5
    8000303e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80003042:	8526                	mv	a0,s1
    80003044:	ffffe097          	auipc	ra,0xffffe
    80003048:	c42080e7          	jalr	-958(ra) # 80000c86 <release>
  sched();
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	bca080e7          	jalr	-1078(ra) # 80002c16 <sched>
  panic("zombie exit");
    80003054:	00006517          	auipc	a0,0x6
    80003058:	3cc50513          	addi	a0,a0,972 # 80009420 <digits+0x3e0>
    8000305c:	ffffd097          	auipc	ra,0xffffd
    80003060:	4ce080e7          	jalr	1230(ra) # 8000052a <panic>
    removeSwapFile(p);
    80003064:	854e                	mv	a0,s3
    80003066:	00002097          	auipc	ra,0x2
    8000306a:	abc080e7          	jalr	-1348(ra) # 80004b22 <removeSwapFile>
    8000306e:	bfa5                	j	80002fe6 <exit+0x62>

0000000080003070 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80003070:	7179                	addi	sp,sp,-48
    80003072:	f406                	sd	ra,40(sp)
    80003074:	f022                	sd	s0,32(sp)
    80003076:	ec26                	sd	s1,24(sp)
    80003078:	e84a                	sd	s2,16(sp)
    8000307a:	e44e                	sd	s3,8(sp)
    8000307c:	1800                	addi	s0,sp,48
    8000307e:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80003080:	0000f497          	auipc	s1,0xf
    80003084:	65048493          	addi	s1,s1,1616 # 800126d0 <proc>
    80003088:	0001d997          	auipc	s3,0x1d
    8000308c:	64898993          	addi	s3,s3,1608 # 800206d0 <tickslock>
    acquire(&p->lock);
    80003090:	8526                	mv	a0,s1
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	b40080e7          	jalr	-1216(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    8000309a:	589c                	lw	a5,48(s1)
    8000309c:	01278d63          	beq	a5,s2,800030b6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800030a0:	8526                	mv	a0,s1
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	be4080e7          	jalr	-1052(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800030aa:	38048493          	addi	s1,s1,896
    800030ae:	ff3491e3          	bne	s1,s3,80003090 <kill+0x20>
  }
  return -1;
    800030b2:	557d                	li	a0,-1
    800030b4:	a829                	j	800030ce <kill+0x5e>
      p->killed = 1;
    800030b6:	4785                	li	a5,1
    800030b8:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800030ba:	4c98                	lw	a4,24(s1)
    800030bc:	4789                	li	a5,2
    800030be:	00f70f63          	beq	a4,a5,800030dc <kill+0x6c>
      release(&p->lock);
    800030c2:	8526                	mv	a0,s1
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	bc2080e7          	jalr	-1086(ra) # 80000c86 <release>
      return 0;
    800030cc:	4501                	li	a0,0
}
    800030ce:	70a2                	ld	ra,40(sp)
    800030d0:	7402                	ld	s0,32(sp)
    800030d2:	64e2                	ld	s1,24(sp)
    800030d4:	6942                	ld	s2,16(sp)
    800030d6:	69a2                	ld	s3,8(sp)
    800030d8:	6145                	addi	sp,sp,48
    800030da:	8082                	ret
        p->state = RUNNABLE;
    800030dc:	478d                	li	a5,3
    800030de:	cc9c                	sw	a5,24(s1)
    800030e0:	b7cd                	j	800030c2 <kill+0x52>

00000000800030e2 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800030e2:	7179                	addi	sp,sp,-48
    800030e4:	f406                	sd	ra,40(sp)
    800030e6:	f022                	sd	s0,32(sp)
    800030e8:	ec26                	sd	s1,24(sp)
    800030ea:	e84a                	sd	s2,16(sp)
    800030ec:	e44e                	sd	s3,8(sp)
    800030ee:	e052                	sd	s4,0(sp)
    800030f0:	1800                	addi	s0,sp,48
    800030f2:	84aa                	mv	s1,a0
    800030f4:	892e                	mv	s2,a1
    800030f6:	89b2                	mv	s3,a2
    800030f8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030fa:	fffff097          	auipc	ra,0xfffff
    800030fe:	308080e7          	jalr	776(ra) # 80002402 <myproc>
  if(user_dst){
    80003102:	c08d                	beqz	s1,80003124 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80003104:	86d2                	mv	a3,s4
    80003106:	864e                	mv	a2,s3
    80003108:	85ca                	mv	a1,s2
    8000310a:	6928                	ld	a0,80(a0)
    8000310c:	ffffe097          	auipc	ra,0xffffe
    80003110:	37e080e7          	jalr	894(ra) # 8000148a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80003114:	70a2                	ld	ra,40(sp)
    80003116:	7402                	ld	s0,32(sp)
    80003118:	64e2                	ld	s1,24(sp)
    8000311a:	6942                	ld	s2,16(sp)
    8000311c:	69a2                	ld	s3,8(sp)
    8000311e:	6a02                	ld	s4,0(sp)
    80003120:	6145                	addi	sp,sp,48
    80003122:	8082                	ret
    memmove((char *)dst, src, len);
    80003124:	000a061b          	sext.w	a2,s4
    80003128:	85ce                	mv	a1,s3
    8000312a:	854a                	mv	a0,s2
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	bfe080e7          	jalr	-1026(ra) # 80000d2a <memmove>
    return 0;
    80003134:	8526                	mv	a0,s1
    80003136:	bff9                	j	80003114 <either_copyout+0x32>

0000000080003138 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003138:	7179                	addi	sp,sp,-48
    8000313a:	f406                	sd	ra,40(sp)
    8000313c:	f022                	sd	s0,32(sp)
    8000313e:	ec26                	sd	s1,24(sp)
    80003140:	e84a                	sd	s2,16(sp)
    80003142:	e44e                	sd	s3,8(sp)
    80003144:	e052                	sd	s4,0(sp)
    80003146:	1800                	addi	s0,sp,48
    80003148:	892a                	mv	s2,a0
    8000314a:	84ae                	mv	s1,a1
    8000314c:	89b2                	mv	s3,a2
    8000314e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003150:	fffff097          	auipc	ra,0xfffff
    80003154:	2b2080e7          	jalr	690(ra) # 80002402 <myproc>
  if(user_src){
    80003158:	c08d                	beqz	s1,8000317a <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000315a:	86d2                	mv	a3,s4
    8000315c:	864e                	mv	a2,s3
    8000315e:	85ca                	mv	a1,s2
    80003160:	6928                	ld	a0,80(a0)
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	3b4080e7          	jalr	948(ra) # 80001516 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000316a:	70a2                	ld	ra,40(sp)
    8000316c:	7402                	ld	s0,32(sp)
    8000316e:	64e2                	ld	s1,24(sp)
    80003170:	6942                	ld	s2,16(sp)
    80003172:	69a2                	ld	s3,8(sp)
    80003174:	6a02                	ld	s4,0(sp)
    80003176:	6145                	addi	sp,sp,48
    80003178:	8082                	ret
    memmove(dst, (char*)src, len);
    8000317a:	000a061b          	sext.w	a2,s4
    8000317e:	85ce                	mv	a1,s3
    80003180:	854a                	mv	a0,s2
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	ba8080e7          	jalr	-1112(ra) # 80000d2a <memmove>
    return 0;
    8000318a:	8526                	mv	a0,s1
    8000318c:	bff9                	j	8000316a <either_copyin+0x32>

000000008000318e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000318e:	715d                	addi	sp,sp,-80
    80003190:	e486                	sd	ra,72(sp)
    80003192:	e0a2                	sd	s0,64(sp)
    80003194:	fc26                	sd	s1,56(sp)
    80003196:	f84a                	sd	s2,48(sp)
    80003198:	f44e                	sd	s3,40(sp)
    8000319a:	f052                	sd	s4,32(sp)
    8000319c:	ec56                	sd	s5,24(sp)
    8000319e:	e85a                	sd	s6,16(sp)
    800031a0:	e45e                	sd	s7,8(sp)
    800031a2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800031a4:	00006517          	auipc	a0,0x6
    800031a8:	1bc50513          	addi	a0,a0,444 # 80009360 <digits+0x320>
    800031ac:	ffffd097          	auipc	ra,0xffffd
    800031b0:	3c8080e7          	jalr	968(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800031b4:	0000f497          	auipc	s1,0xf
    800031b8:	67448493          	addi	s1,s1,1652 # 80012828 <proc+0x158>
    800031bc:	0001d917          	auipc	s2,0x1d
    800031c0:	66c90913          	addi	s2,s2,1644 # 80020828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031c4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800031c6:	00006997          	auipc	s3,0x6
    800031ca:	26a98993          	addi	s3,s3,618 # 80009430 <digits+0x3f0>
    printf("%d %s %s", p->pid, state, p->name);
    800031ce:	00006a97          	auipc	s5,0x6
    800031d2:	26aa8a93          	addi	s5,s5,618 # 80009438 <digits+0x3f8>
    printf("\n");
    800031d6:	00006a17          	auipc	s4,0x6
    800031da:	18aa0a13          	addi	s4,s4,394 # 80009360 <digits+0x320>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031de:	00006b97          	auipc	s7,0x6
    800031e2:	292b8b93          	addi	s7,s7,658 # 80009470 <states.0>
    800031e6:	a00d                	j	80003208 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800031e8:	ed86a583          	lw	a1,-296(a3)
    800031ec:	8556                	mv	a0,s5
    800031ee:	ffffd097          	auipc	ra,0xffffd
    800031f2:	386080e7          	jalr	902(ra) # 80000574 <printf>
    printf("\n");
    800031f6:	8552                	mv	a0,s4
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	37c080e7          	jalr	892(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80003200:	38048493          	addi	s1,s1,896
    80003204:	03248263          	beq	s1,s2,80003228 <procdump+0x9a>
    if(p->state == UNUSED)
    80003208:	86a6                	mv	a3,s1
    8000320a:	ec04a783          	lw	a5,-320(s1)
    8000320e:	dbed                	beqz	a5,80003200 <procdump+0x72>
      state = "???";
    80003210:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003212:	fcfb6be3          	bltu	s6,a5,800031e8 <procdump+0x5a>
    80003216:	02079713          	slli	a4,a5,0x20
    8000321a:	01d75793          	srli	a5,a4,0x1d
    8000321e:	97de                	add	a5,a5,s7
    80003220:	6390                	ld	a2,0(a5)
    80003222:	f279                	bnez	a2,800031e8 <procdump+0x5a>
      state = "???";
    80003224:	864e                	mv	a2,s3
    80003226:	b7c9                	j	800031e8 <procdump+0x5a>
  }
}
    80003228:	60a6                	ld	ra,72(sp)
    8000322a:	6406                	ld	s0,64(sp)
    8000322c:	74e2                	ld	s1,56(sp)
    8000322e:	7942                	ld	s2,48(sp)
    80003230:	79a2                	ld	s3,40(sp)
    80003232:	7a02                	ld	s4,32(sp)
    80003234:	6ae2                	ld	s5,24(sp)
    80003236:	6b42                	ld	s6,16(sp)
    80003238:	6ba2                	ld	s7,8(sp)
    8000323a:	6161                	addi	sp,sp,80
    8000323c:	8082                	ret

000000008000323e <swtch>:
    8000323e:	00153023          	sd	ra,0(a0)
    80003242:	00253423          	sd	sp,8(a0)
    80003246:	e900                	sd	s0,16(a0)
    80003248:	ed04                	sd	s1,24(a0)
    8000324a:	03253023          	sd	s2,32(a0)
    8000324e:	03353423          	sd	s3,40(a0)
    80003252:	03453823          	sd	s4,48(a0)
    80003256:	03553c23          	sd	s5,56(a0)
    8000325a:	05653023          	sd	s6,64(a0)
    8000325e:	05753423          	sd	s7,72(a0)
    80003262:	05853823          	sd	s8,80(a0)
    80003266:	05953c23          	sd	s9,88(a0)
    8000326a:	07a53023          	sd	s10,96(a0)
    8000326e:	07b53423          	sd	s11,104(a0)
    80003272:	0005b083          	ld	ra,0(a1)
    80003276:	0085b103          	ld	sp,8(a1)
    8000327a:	6980                	ld	s0,16(a1)
    8000327c:	6d84                	ld	s1,24(a1)
    8000327e:	0205b903          	ld	s2,32(a1)
    80003282:	0285b983          	ld	s3,40(a1)
    80003286:	0305ba03          	ld	s4,48(a1)
    8000328a:	0385ba83          	ld	s5,56(a1)
    8000328e:	0405bb03          	ld	s6,64(a1)
    80003292:	0485bb83          	ld	s7,72(a1)
    80003296:	0505bc03          	ld	s8,80(a1)
    8000329a:	0585bc83          	ld	s9,88(a1)
    8000329e:	0605bd03          	ld	s10,96(a1)
    800032a2:	0685bd83          	ld	s11,104(a1)
    800032a6:	8082                	ret

00000000800032a8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800032a8:	1141                	addi	sp,sp,-16
    800032aa:	e406                	sd	ra,8(sp)
    800032ac:	e022                	sd	s0,0(sp)
    800032ae:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800032b0:	00006597          	auipc	a1,0x6
    800032b4:	1f058593          	addi	a1,a1,496 # 800094a0 <states.0+0x30>
    800032b8:	0001d517          	auipc	a0,0x1d
    800032bc:	41850513          	addi	a0,a0,1048 # 800206d0 <tickslock>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	882080e7          	jalr	-1918(ra) # 80000b42 <initlock>
}
    800032c8:	60a2                	ld	ra,8(sp)
    800032ca:	6402                	ld	s0,0(sp)
    800032cc:	0141                	addi	sp,sp,16
    800032ce:	8082                	ret

00000000800032d0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800032d0:	1141                	addi	sp,sp,-16
    800032d2:	e422                	sd	s0,8(sp)
    800032d4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800032d6:	00004797          	auipc	a5,0x4
    800032da:	9da78793          	addi	a5,a5,-1574 # 80006cb0 <kernelvec>
    800032de:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800032e2:	6422                	ld	s0,8(sp)
    800032e4:	0141                	addi	sp,sp,16
    800032e6:	8082                	ret

00000000800032e8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800032e8:	1141                	addi	sp,sp,-16
    800032ea:	e406                	sd	ra,8(sp)
    800032ec:	e022                	sd	s0,0(sp)
    800032ee:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800032f0:	fffff097          	auipc	ra,0xfffff
    800032f4:	112080e7          	jalr	274(ra) # 80002402 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800032fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032fe:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80003302:	00005617          	auipc	a2,0x5
    80003306:	cfe60613          	addi	a2,a2,-770 # 80008000 <_trampoline>
    8000330a:	00005697          	auipc	a3,0x5
    8000330e:	cf668693          	addi	a3,a3,-778 # 80008000 <_trampoline>
    80003312:	8e91                	sub	a3,a3,a2
    80003314:	040007b7          	lui	a5,0x4000
    80003318:	17fd                	addi	a5,a5,-1
    8000331a:	07b2                	slli	a5,a5,0xc
    8000331c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000331e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003322:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003324:	180026f3          	csrr	a3,satp
    80003328:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000332a:	6d38                	ld	a4,88(a0)
    8000332c:	6134                	ld	a3,64(a0)
    8000332e:	6585                	lui	a1,0x1
    80003330:	96ae                	add	a3,a3,a1
    80003332:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003334:	6d38                	ld	a4,88(a0)
    80003336:	00000697          	auipc	a3,0x0
    8000333a:	13868693          	addi	a3,a3,312 # 8000346e <usertrap>
    8000333e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80003340:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003342:	8692                	mv	a3,tp
    80003344:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003346:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000334a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000334e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003352:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80003356:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003358:	6f18                	ld	a4,24(a4)
    8000335a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000335e:	692c                	ld	a1,80(a0)
    80003360:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003362:	00005717          	auipc	a4,0x5
    80003366:	d2e70713          	addi	a4,a4,-722 # 80008090 <userret>
    8000336a:	8f11                	sub	a4,a4,a2
    8000336c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000336e:	577d                	li	a4,-1
    80003370:	177e                	slli	a4,a4,0x3f
    80003372:	8dd9                	or	a1,a1,a4
    80003374:	02000537          	lui	a0,0x2000
    80003378:	157d                	addi	a0,a0,-1
    8000337a:	0536                	slli	a0,a0,0xd
    8000337c:	9782                	jalr	a5
}
    8000337e:	60a2                	ld	ra,8(sp)
    80003380:	6402                	ld	s0,0(sp)
    80003382:	0141                	addi	sp,sp,16
    80003384:	8082                	ret

0000000080003386 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80003386:	1101                	addi	sp,sp,-32
    80003388:	ec06                	sd	ra,24(sp)
    8000338a:	e822                	sd	s0,16(sp)
    8000338c:	e426                	sd	s1,8(sp)
    8000338e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003390:	0001d497          	auipc	s1,0x1d
    80003394:	34048493          	addi	s1,s1,832 # 800206d0 <tickslock>
    80003398:	8526                	mv	a0,s1
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	838080e7          	jalr	-1992(ra) # 80000bd2 <acquire>
  ticks++;
    800033a2:	00007517          	auipc	a0,0x7
    800033a6:	c8e50513          	addi	a0,a0,-882 # 8000a030 <ticks>
    800033aa:	411c                	lw	a5,0(a0)
    800033ac:	2785                	addiw	a5,a5,1
    800033ae:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	b04080e7          	jalr	-1276(ra) # 80002eb4 <wakeup>
  release(&tickslock);
    800033b8:	8526                	mv	a0,s1
    800033ba:	ffffe097          	auipc	ra,0xffffe
    800033be:	8cc080e7          	jalr	-1844(ra) # 80000c86 <release>
}
    800033c2:	60e2                	ld	ra,24(sp)
    800033c4:	6442                	ld	s0,16(sp)
    800033c6:	64a2                	ld	s1,8(sp)
    800033c8:	6105                	addi	sp,sp,32
    800033ca:	8082                	ret

00000000800033cc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800033cc:	1101                	addi	sp,sp,-32
    800033ce:	ec06                	sd	ra,24(sp)
    800033d0:	e822                	sd	s0,16(sp)
    800033d2:	e426                	sd	s1,8(sp)
    800033d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800033da:	00074d63          	bltz	a4,800033f4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800033de:	57fd                	li	a5,-1
    800033e0:	17fe                	slli	a5,a5,0x3f
    800033e2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800033e4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800033e6:	06f70363          	beq	a4,a5,8000344c <devintr+0x80>
  }
}
    800033ea:	60e2                	ld	ra,24(sp)
    800033ec:	6442                	ld	s0,16(sp)
    800033ee:	64a2                	ld	s1,8(sp)
    800033f0:	6105                	addi	sp,sp,32
    800033f2:	8082                	ret
     (scause & 0xff) == 9){
    800033f4:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800033f8:	46a5                	li	a3,9
    800033fa:	fed792e3          	bne	a5,a3,800033de <devintr+0x12>
    int irq = plic_claim();
    800033fe:	00004097          	auipc	ra,0x4
    80003402:	9ba080e7          	jalr	-1606(ra) # 80006db8 <plic_claim>
    80003406:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003408:	47a9                	li	a5,10
    8000340a:	02f50763          	beq	a0,a5,80003438 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000340e:	4785                	li	a5,1
    80003410:	02f50963          	beq	a0,a5,80003442 <devintr+0x76>
    return 1;
    80003414:	4505                	li	a0,1
    } else if(irq){
    80003416:	d8f1                	beqz	s1,800033ea <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003418:	85a6                	mv	a1,s1
    8000341a:	00006517          	auipc	a0,0x6
    8000341e:	08e50513          	addi	a0,a0,142 # 800094a8 <states.0+0x38>
    80003422:	ffffd097          	auipc	ra,0xffffd
    80003426:	152080e7          	jalr	338(ra) # 80000574 <printf>
      plic_complete(irq);
    8000342a:	8526                	mv	a0,s1
    8000342c:	00004097          	auipc	ra,0x4
    80003430:	9b0080e7          	jalr	-1616(ra) # 80006ddc <plic_complete>
    return 1;
    80003434:	4505                	li	a0,1
    80003436:	bf55                	j	800033ea <devintr+0x1e>
      uartintr();
    80003438:	ffffd097          	auipc	ra,0xffffd
    8000343c:	54e080e7          	jalr	1358(ra) # 80000986 <uartintr>
    80003440:	b7ed                	j	8000342a <devintr+0x5e>
      virtio_disk_intr();
    80003442:	00004097          	auipc	ra,0x4
    80003446:	e2c080e7          	jalr	-468(ra) # 8000726e <virtio_disk_intr>
    8000344a:	b7c5                	j	8000342a <devintr+0x5e>
    if(cpuid() == 0){
    8000344c:	fffff097          	auipc	ra,0xfffff
    80003450:	f8a080e7          	jalr	-118(ra) # 800023d6 <cpuid>
    80003454:	c901                	beqz	a0,80003464 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003456:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000345a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000345c:	14479073          	csrw	sip,a5
    return 2;
    80003460:	4509                	li	a0,2
    80003462:	b761                	j	800033ea <devintr+0x1e>
      clockintr();
    80003464:	00000097          	auipc	ra,0x0
    80003468:	f22080e7          	jalr	-222(ra) # 80003386 <clockintr>
    8000346c:	b7ed                	j	80003456 <devintr+0x8a>

000000008000346e <usertrap>:
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	e426                	sd	s1,8(sp)
    80003476:	e04a                	sd	s2,0(sp)
    80003478:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000347a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000347e:	1007f793          	andi	a5,a5,256
    80003482:	efb9                	bnez	a5,800034e0 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003484:	00004797          	auipc	a5,0x4
    80003488:	82c78793          	addi	a5,a5,-2004 # 80006cb0 <kernelvec>
    8000348c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003490:	fffff097          	auipc	ra,0xfffff
    80003494:	f72080e7          	jalr	-142(ra) # 80002402 <myproc>
    80003498:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000349a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000349c:	14102773          	csrr	a4,sepc
    800034a0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034a2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800034a6:	47a1                	li	a5,8
    800034a8:	04f70463          	beq	a4,a5,800034f0 <usertrap+0x82>
    800034ac:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    800034b0:	47b5                	li	a5,13
    800034b2:	00f70763          	beq	a4,a5,800034c0 <usertrap+0x52>
    800034b6:	14202773          	csrr	a4,scause
    800034ba:	47bd                	li	a5,15
    800034bc:	06f71163          	bne	a4,a5,8000351e <usertrap+0xb0>
    check_page_fault();
    800034c0:	fffff097          	auipc	ra,0xfffff
    800034c4:	c80080e7          	jalr	-896(ra) # 80002140 <check_page_fault>
  if(p->killed)
    800034c8:	549c                	lw	a5,40(s1)
    800034ca:	efc9                	bnez	a5,80003564 <usertrap+0xf6>
  usertrapret();
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	e1c080e7          	jalr	-484(ra) # 800032e8 <usertrapret>
}
    800034d4:	60e2                	ld	ra,24(sp)
    800034d6:	6442                	ld	s0,16(sp)
    800034d8:	64a2                	ld	s1,8(sp)
    800034da:	6902                	ld	s2,0(sp)
    800034dc:	6105                	addi	sp,sp,32
    800034de:	8082                	ret
    panic("usertrap: not from user mode");
    800034e0:	00006517          	auipc	a0,0x6
    800034e4:	fe850513          	addi	a0,a0,-24 # 800094c8 <states.0+0x58>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	042080e7          	jalr	66(ra) # 8000052a <panic>
    if(p->killed)
    800034f0:	551c                	lw	a5,40(a0)
    800034f2:	e385                	bnez	a5,80003512 <usertrap+0xa4>
    p->trapframe->epc += 4;
    800034f4:	6cb8                	ld	a4,88(s1)
    800034f6:	6f1c                	ld	a5,24(a4)
    800034f8:	0791                	addi	a5,a5,4
    800034fa:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034fc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003500:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003504:	10079073          	csrw	sstatus,a5
    syscall();
    80003508:	00000097          	auipc	ra,0x0
    8000350c:	2ba080e7          	jalr	698(ra) # 800037c2 <syscall>
    80003510:	bf65                	j	800034c8 <usertrap+0x5a>
      exit(-1);
    80003512:	557d                	li	a0,-1
    80003514:	00000097          	auipc	ra,0x0
    80003518:	a70080e7          	jalr	-1424(ra) # 80002f84 <exit>
    8000351c:	bfe1                	j	800034f4 <usertrap+0x86>
  else if((which_dev = devintr()) != 0){
    8000351e:	00000097          	auipc	ra,0x0
    80003522:	eae080e7          	jalr	-338(ra) # 800033cc <devintr>
    80003526:	892a                	mv	s2,a0
    80003528:	c501                	beqz	a0,80003530 <usertrap+0xc2>
  if(p->killed)
    8000352a:	549c                	lw	a5,40(s1)
    8000352c:	c3b1                	beqz	a5,80003570 <usertrap+0x102>
    8000352e:	a825                	j	80003566 <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003530:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003534:	5890                	lw	a2,48(s1)
    80003536:	00006517          	auipc	a0,0x6
    8000353a:	fb250513          	addi	a0,a0,-78 # 800094e8 <states.0+0x78>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	036080e7          	jalr	54(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003546:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000354a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000354e:	00006517          	auipc	a0,0x6
    80003552:	fca50513          	addi	a0,a0,-54 # 80009518 <states.0+0xa8>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	01e080e7          	jalr	30(ra) # 80000574 <printf>
    p->killed = 1;
    8000355e:	4785                	li	a5,1
    80003560:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80003562:	a011                	j	80003566 <usertrap+0xf8>
    80003564:	4901                	li	s2,0
    exit(-1);
    80003566:	557d                	li	a0,-1
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	a1c080e7          	jalr	-1508(ra) # 80002f84 <exit>
  if(which_dev == 2)
    80003570:	4789                	li	a5,2
    80003572:	f4f91de3          	bne	s2,a5,800034cc <usertrap+0x5e>
    yield();
    80003576:	fffff097          	auipc	ra,0xfffff
    8000357a:	776080e7          	jalr	1910(ra) # 80002cec <yield>
    8000357e:	b7b9                	j	800034cc <usertrap+0x5e>

0000000080003580 <kerneltrap>:
{
    80003580:	7179                	addi	sp,sp,-48
    80003582:	f406                	sd	ra,40(sp)
    80003584:	f022                	sd	s0,32(sp)
    80003586:	ec26                	sd	s1,24(sp)
    80003588:	e84a                	sd	s2,16(sp)
    8000358a:	e44e                	sd	s3,8(sp)
    8000358c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000358e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003592:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003596:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000359a:	1004f793          	andi	a5,s1,256
    8000359e:	cb85                	beqz	a5,800035ce <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035a0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800035a4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800035a6:	ef85                	bnez	a5,800035de <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800035a8:	00000097          	auipc	ra,0x0
    800035ac:	e24080e7          	jalr	-476(ra) # 800033cc <devintr>
    800035b0:	cd1d                	beqz	a0,800035ee <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800035b2:	4789                	li	a5,2
    800035b4:	06f50a63          	beq	a0,a5,80003628 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800035b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800035bc:	10049073          	csrw	sstatus,s1
}
    800035c0:	70a2                	ld	ra,40(sp)
    800035c2:	7402                	ld	s0,32(sp)
    800035c4:	64e2                	ld	s1,24(sp)
    800035c6:	6942                	ld	s2,16(sp)
    800035c8:	69a2                	ld	s3,8(sp)
    800035ca:	6145                	addi	sp,sp,48
    800035cc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800035ce:	00006517          	auipc	a0,0x6
    800035d2:	f6a50513          	addi	a0,a0,-150 # 80009538 <states.0+0xc8>
    800035d6:	ffffd097          	auipc	ra,0xffffd
    800035da:	f54080e7          	jalr	-172(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    800035de:	00006517          	auipc	a0,0x6
    800035e2:	f8250513          	addi	a0,a0,-126 # 80009560 <states.0+0xf0>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	f44080e7          	jalr	-188(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    800035ee:	85ce                	mv	a1,s3
    800035f0:	00006517          	auipc	a0,0x6
    800035f4:	f9050513          	addi	a0,a0,-112 # 80009580 <states.0+0x110>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	f7c080e7          	jalr	-132(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003600:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003604:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003608:	00006517          	auipc	a0,0x6
    8000360c:	f8850513          	addi	a0,a0,-120 # 80009590 <states.0+0x120>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	f64080e7          	jalr	-156(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003618:	00006517          	auipc	a0,0x6
    8000361c:	f9050513          	addi	a0,a0,-112 # 800095a8 <states.0+0x138>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	f0a080e7          	jalr	-246(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003628:	fffff097          	auipc	ra,0xfffff
    8000362c:	dda080e7          	jalr	-550(ra) # 80002402 <myproc>
    80003630:	d541                	beqz	a0,800035b8 <kerneltrap+0x38>
    80003632:	fffff097          	auipc	ra,0xfffff
    80003636:	dd0080e7          	jalr	-560(ra) # 80002402 <myproc>
    8000363a:	4d18                	lw	a4,24(a0)
    8000363c:	4791                	li	a5,4
    8000363e:	f6f71de3          	bne	a4,a5,800035b8 <kerneltrap+0x38>
    yield();
    80003642:	fffff097          	auipc	ra,0xfffff
    80003646:	6aa080e7          	jalr	1706(ra) # 80002cec <yield>
    8000364a:	b7bd                	j	800035b8 <kerneltrap+0x38>

000000008000364c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000364c:	1101                	addi	sp,sp,-32
    8000364e:	ec06                	sd	ra,24(sp)
    80003650:	e822                	sd	s0,16(sp)
    80003652:	e426                	sd	s1,8(sp)
    80003654:	1000                	addi	s0,sp,32
    80003656:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003658:	fffff097          	auipc	ra,0xfffff
    8000365c:	daa080e7          	jalr	-598(ra) # 80002402 <myproc>
  switch (n) {
    80003660:	4795                	li	a5,5
    80003662:	0497e163          	bltu	a5,s1,800036a4 <argraw+0x58>
    80003666:	048a                	slli	s1,s1,0x2
    80003668:	00006717          	auipc	a4,0x6
    8000366c:	f7870713          	addi	a4,a4,-136 # 800095e0 <states.0+0x170>
    80003670:	94ba                	add	s1,s1,a4
    80003672:	409c                	lw	a5,0(s1)
    80003674:	97ba                	add	a5,a5,a4
    80003676:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003678:	6d3c                	ld	a5,88(a0)
    8000367a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000367c:	60e2                	ld	ra,24(sp)
    8000367e:	6442                	ld	s0,16(sp)
    80003680:	64a2                	ld	s1,8(sp)
    80003682:	6105                	addi	sp,sp,32
    80003684:	8082                	ret
    return p->trapframe->a1;
    80003686:	6d3c                	ld	a5,88(a0)
    80003688:	7fa8                	ld	a0,120(a5)
    8000368a:	bfcd                	j	8000367c <argraw+0x30>
    return p->trapframe->a2;
    8000368c:	6d3c                	ld	a5,88(a0)
    8000368e:	63c8                	ld	a0,128(a5)
    80003690:	b7f5                	j	8000367c <argraw+0x30>
    return p->trapframe->a3;
    80003692:	6d3c                	ld	a5,88(a0)
    80003694:	67c8                	ld	a0,136(a5)
    80003696:	b7dd                	j	8000367c <argraw+0x30>
    return p->trapframe->a4;
    80003698:	6d3c                	ld	a5,88(a0)
    8000369a:	6bc8                	ld	a0,144(a5)
    8000369c:	b7c5                	j	8000367c <argraw+0x30>
    return p->trapframe->a5;
    8000369e:	6d3c                	ld	a5,88(a0)
    800036a0:	6fc8                	ld	a0,152(a5)
    800036a2:	bfe9                	j	8000367c <argraw+0x30>
  panic("argraw");
    800036a4:	00006517          	auipc	a0,0x6
    800036a8:	f1450513          	addi	a0,a0,-236 # 800095b8 <states.0+0x148>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	e7e080e7          	jalr	-386(ra) # 8000052a <panic>

00000000800036b4 <fetchaddr>:
{
    800036b4:	1101                	addi	sp,sp,-32
    800036b6:	ec06                	sd	ra,24(sp)
    800036b8:	e822                	sd	s0,16(sp)
    800036ba:	e426                	sd	s1,8(sp)
    800036bc:	e04a                	sd	s2,0(sp)
    800036be:	1000                	addi	s0,sp,32
    800036c0:	84aa                	mv	s1,a0
    800036c2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800036c4:	fffff097          	auipc	ra,0xfffff
    800036c8:	d3e080e7          	jalr	-706(ra) # 80002402 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800036cc:	653c                	ld	a5,72(a0)
    800036ce:	02f4f863          	bgeu	s1,a5,800036fe <fetchaddr+0x4a>
    800036d2:	00848713          	addi	a4,s1,8
    800036d6:	02e7e663          	bltu	a5,a4,80003702 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800036da:	46a1                	li	a3,8
    800036dc:	8626                	mv	a2,s1
    800036de:	85ca                	mv	a1,s2
    800036e0:	6928                	ld	a0,80(a0)
    800036e2:	ffffe097          	auipc	ra,0xffffe
    800036e6:	e34080e7          	jalr	-460(ra) # 80001516 <copyin>
    800036ea:	00a03533          	snez	a0,a0
    800036ee:	40a00533          	neg	a0,a0
}
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6902                	ld	s2,0(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret
    return -1;
    800036fe:	557d                	li	a0,-1
    80003700:	bfcd                	j	800036f2 <fetchaddr+0x3e>
    80003702:	557d                	li	a0,-1
    80003704:	b7fd                	j	800036f2 <fetchaddr+0x3e>

0000000080003706 <fetchstr>:
{
    80003706:	7179                	addi	sp,sp,-48
    80003708:	f406                	sd	ra,40(sp)
    8000370a:	f022                	sd	s0,32(sp)
    8000370c:	ec26                	sd	s1,24(sp)
    8000370e:	e84a                	sd	s2,16(sp)
    80003710:	e44e                	sd	s3,8(sp)
    80003712:	1800                	addi	s0,sp,48
    80003714:	892a                	mv	s2,a0
    80003716:	84ae                	mv	s1,a1
    80003718:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000371a:	fffff097          	auipc	ra,0xfffff
    8000371e:	ce8080e7          	jalr	-792(ra) # 80002402 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003722:	86ce                	mv	a3,s3
    80003724:	864a                	mv	a2,s2
    80003726:	85a6                	mv	a1,s1
    80003728:	6928                	ld	a0,80(a0)
    8000372a:	ffffe097          	auipc	ra,0xffffe
    8000372e:	e7a080e7          	jalr	-390(ra) # 800015a4 <copyinstr>
  if(err < 0)
    80003732:	00054763          	bltz	a0,80003740 <fetchstr+0x3a>
  return strlen(buf);
    80003736:	8526                	mv	a0,s1
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	71a080e7          	jalr	1818(ra) # 80000e52 <strlen>
}
    80003740:	70a2                	ld	ra,40(sp)
    80003742:	7402                	ld	s0,32(sp)
    80003744:	64e2                	ld	s1,24(sp)
    80003746:	6942                	ld	s2,16(sp)
    80003748:	69a2                	ld	s3,8(sp)
    8000374a:	6145                	addi	sp,sp,48
    8000374c:	8082                	ret

000000008000374e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	e426                	sd	s1,8(sp)
    80003756:	1000                	addi	s0,sp,32
    80003758:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	ef2080e7          	jalr	-270(ra) # 8000364c <argraw>
    80003762:	c088                	sw	a0,0(s1)
  return 0;
}
    80003764:	4501                	li	a0,0
    80003766:	60e2                	ld	ra,24(sp)
    80003768:	6442                	ld	s0,16(sp)
    8000376a:	64a2                	ld	s1,8(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret

0000000080003770 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	1000                	addi	s0,sp,32
    8000377a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000377c:	00000097          	auipc	ra,0x0
    80003780:	ed0080e7          	jalr	-304(ra) # 8000364c <argraw>
    80003784:	e088                	sd	a0,0(s1)
  return 0;
}
    80003786:	4501                	li	a0,0
    80003788:	60e2                	ld	ra,24(sp)
    8000378a:	6442                	ld	s0,16(sp)
    8000378c:	64a2                	ld	s1,8(sp)
    8000378e:	6105                	addi	sp,sp,32
    80003790:	8082                	ret

0000000080003792 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003792:	1101                	addi	sp,sp,-32
    80003794:	ec06                	sd	ra,24(sp)
    80003796:	e822                	sd	s0,16(sp)
    80003798:	e426                	sd	s1,8(sp)
    8000379a:	e04a                	sd	s2,0(sp)
    8000379c:	1000                	addi	s0,sp,32
    8000379e:	84ae                	mv	s1,a1
    800037a0:	8932                	mv	s2,a2
  *ip = argraw(n);
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	eaa080e7          	jalr	-342(ra) # 8000364c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800037aa:	864a                	mv	a2,s2
    800037ac:	85a6                	mv	a1,s1
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	f58080e7          	jalr	-168(ra) # 80003706 <fetchstr>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret

00000000800037c2 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    800037c2:	1101                	addi	sp,sp,-32
    800037c4:	ec06                	sd	ra,24(sp)
    800037c6:	e822                	sd	s0,16(sp)
    800037c8:	e426                	sd	s1,8(sp)
    800037ca:	e04a                	sd	s2,0(sp)
    800037cc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	c34080e7          	jalr	-972(ra) # 80002402 <myproc>
    800037d6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800037d8:	05853903          	ld	s2,88(a0)
    800037dc:	0a893783          	ld	a5,168(s2)
    800037e0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800037e4:	37fd                	addiw	a5,a5,-1
    800037e6:	4751                	li	a4,20
    800037e8:	00f76f63          	bltu	a4,a5,80003806 <syscall+0x44>
    800037ec:	00369713          	slli	a4,a3,0x3
    800037f0:	00006797          	auipc	a5,0x6
    800037f4:	e0878793          	addi	a5,a5,-504 # 800095f8 <syscalls>
    800037f8:	97ba                	add	a5,a5,a4
    800037fa:	639c                	ld	a5,0(a5)
    800037fc:	c789                	beqz	a5,80003806 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800037fe:	9782                	jalr	a5
    80003800:	06a93823          	sd	a0,112(s2)
    80003804:	a839                	j	80003822 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003806:	15848613          	addi	a2,s1,344
    8000380a:	588c                	lw	a1,48(s1)
    8000380c:	00006517          	auipc	a0,0x6
    80003810:	db450513          	addi	a0,a0,-588 # 800095c0 <states.0+0x150>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	d60080e7          	jalr	-672(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000381c:	6cbc                	ld	a5,88(s1)
    8000381e:	577d                	li	a4,-1
    80003820:	fbb8                	sd	a4,112(a5)
  }
}
    80003822:	60e2                	ld	ra,24(sp)
    80003824:	6442                	ld	s0,16(sp)
    80003826:	64a2                	ld	s1,8(sp)
    80003828:	6902                	ld	s2,0(sp)
    8000382a:	6105                	addi	sp,sp,32
    8000382c:	8082                	ret

000000008000382e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000382e:	1101                	addi	sp,sp,-32
    80003830:	ec06                	sd	ra,24(sp)
    80003832:	e822                	sd	s0,16(sp)
    80003834:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003836:	fec40593          	addi	a1,s0,-20
    8000383a:	4501                	li	a0,0
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	f12080e7          	jalr	-238(ra) # 8000374e <argint>
    return -1;
    80003844:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003846:	00054963          	bltz	a0,80003858 <sys_exit+0x2a>
  exit(n);
    8000384a:	fec42503          	lw	a0,-20(s0)
    8000384e:	fffff097          	auipc	ra,0xfffff
    80003852:	736080e7          	jalr	1846(ra) # 80002f84 <exit>
  return 0;  // not reached
    80003856:	4781                	li	a5,0
}
    80003858:	853e                	mv	a0,a5
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	6105                	addi	sp,sp,32
    80003860:	8082                	ret

0000000080003862 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003862:	1141                	addi	sp,sp,-16
    80003864:	e406                	sd	ra,8(sp)
    80003866:	e022                	sd	s0,0(sp)
    80003868:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000386a:	fffff097          	auipc	ra,0xfffff
    8000386e:	b98080e7          	jalr	-1128(ra) # 80002402 <myproc>
}
    80003872:	5908                	lw	a0,48(a0)
    80003874:	60a2                	ld	ra,8(sp)
    80003876:	6402                	ld	s0,0(sp)
    80003878:	0141                	addi	sp,sp,16
    8000387a:	8082                	ret

000000008000387c <sys_fork>:

uint64
sys_fork(void)
{
    8000387c:	1141                	addi	sp,sp,-16
    8000387e:	e406                	sd	ra,8(sp)
    80003880:	e022                	sd	s0,0(sp)
    80003882:	0800                	addi	s0,sp,16
  return fork();
    80003884:	fffff097          	auipc	ra,0xfffff
    80003888:	0b8080e7          	jalr	184(ra) # 8000293c <fork>
}
    8000388c:	60a2                	ld	ra,8(sp)
    8000388e:	6402                	ld	s0,0(sp)
    80003890:	0141                	addi	sp,sp,16
    80003892:	8082                	ret

0000000080003894 <sys_wait>:

uint64
sys_wait(void)
{
    80003894:	1101                	addi	sp,sp,-32
    80003896:	ec06                	sd	ra,24(sp)
    80003898:	e822                	sd	s0,16(sp)
    8000389a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000389c:	fe840593          	addi	a1,s0,-24
    800038a0:	4501                	li	a0,0
    800038a2:	00000097          	auipc	ra,0x0
    800038a6:	ece080e7          	jalr	-306(ra) # 80003770 <argaddr>
    800038aa:	87aa                	mv	a5,a0
    return -1;
    800038ac:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800038ae:	0007c863          	bltz	a5,800038be <sys_wait+0x2a>
  return wait(p);
    800038b2:	fe843503          	ld	a0,-24(s0)
    800038b6:	fffff097          	auipc	ra,0xfffff
    800038ba:	4d6080e7          	jalr	1238(ra) # 80002d8c <wait>
}
    800038be:	60e2                	ld	ra,24(sp)
    800038c0:	6442                	ld	s0,16(sp)
    800038c2:	6105                	addi	sp,sp,32
    800038c4:	8082                	ret

00000000800038c6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800038c6:	7179                	addi	sp,sp,-48
    800038c8:	f406                	sd	ra,40(sp)
    800038ca:	f022                	sd	s0,32(sp)
    800038cc:	ec26                	sd	s1,24(sp)
    800038ce:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800038d0:	fdc40593          	addi	a1,s0,-36
    800038d4:	4501                	li	a0,0
    800038d6:	00000097          	auipc	ra,0x0
    800038da:	e78080e7          	jalr	-392(ra) # 8000374e <argint>
    return -1;
    800038de:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    800038e0:	00054f63          	bltz	a0,800038fe <sys_sbrk+0x38>
  addr = myproc()->sz;
    800038e4:	fffff097          	auipc	ra,0xfffff
    800038e8:	b1e080e7          	jalr	-1250(ra) # 80002402 <myproc>
    800038ec:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800038ee:	fdc42503          	lw	a0,-36(s0)
    800038f2:	fffff097          	auipc	ra,0xfffff
    800038f6:	f2c080e7          	jalr	-212(ra) # 8000281e <growproc>
    800038fa:	00054863          	bltz	a0,8000390a <sys_sbrk+0x44>
    return -1;
  return addr;
}
    800038fe:	8526                	mv	a0,s1
    80003900:	70a2                	ld	ra,40(sp)
    80003902:	7402                	ld	s0,32(sp)
    80003904:	64e2                	ld	s1,24(sp)
    80003906:	6145                	addi	sp,sp,48
    80003908:	8082                	ret
    return -1;
    8000390a:	54fd                	li	s1,-1
    8000390c:	bfcd                	j	800038fe <sys_sbrk+0x38>

000000008000390e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000390e:	7139                	addi	sp,sp,-64
    80003910:	fc06                	sd	ra,56(sp)
    80003912:	f822                	sd	s0,48(sp)
    80003914:	f426                	sd	s1,40(sp)
    80003916:	f04a                	sd	s2,32(sp)
    80003918:	ec4e                	sd	s3,24(sp)
    8000391a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000391c:	fcc40593          	addi	a1,s0,-52
    80003920:	4501                	li	a0,0
    80003922:	00000097          	auipc	ra,0x0
    80003926:	e2c080e7          	jalr	-468(ra) # 8000374e <argint>
    return -1;
    8000392a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000392c:	06054563          	bltz	a0,80003996 <sys_sleep+0x88>
  acquire(&tickslock);
    80003930:	0001d517          	auipc	a0,0x1d
    80003934:	da050513          	addi	a0,a0,-608 # 800206d0 <tickslock>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	29a080e7          	jalr	666(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003940:	00006917          	auipc	s2,0x6
    80003944:	6f092903          	lw	s2,1776(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    80003948:	fcc42783          	lw	a5,-52(s0)
    8000394c:	cf85                	beqz	a5,80003984 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000394e:	0001d997          	auipc	s3,0x1d
    80003952:	d8298993          	addi	s3,s3,-638 # 800206d0 <tickslock>
    80003956:	00006497          	auipc	s1,0x6
    8000395a:	6da48493          	addi	s1,s1,1754 # 8000a030 <ticks>
    if(myproc()->killed){
    8000395e:	fffff097          	auipc	ra,0xfffff
    80003962:	aa4080e7          	jalr	-1372(ra) # 80002402 <myproc>
    80003966:	551c                	lw	a5,40(a0)
    80003968:	ef9d                	bnez	a5,800039a6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000396a:	85ce                	mv	a1,s3
    8000396c:	8526                	mv	a0,s1
    8000396e:	fffff097          	auipc	ra,0xfffff
    80003972:	3ba080e7          	jalr	954(ra) # 80002d28 <sleep>
  while(ticks - ticks0 < n){
    80003976:	409c                	lw	a5,0(s1)
    80003978:	412787bb          	subw	a5,a5,s2
    8000397c:	fcc42703          	lw	a4,-52(s0)
    80003980:	fce7efe3          	bltu	a5,a4,8000395e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003984:	0001d517          	auipc	a0,0x1d
    80003988:	d4c50513          	addi	a0,a0,-692 # 800206d0 <tickslock>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	2fa080e7          	jalr	762(ra) # 80000c86 <release>
  return 0;
    80003994:	4781                	li	a5,0
}
    80003996:	853e                	mv	a0,a5
    80003998:	70e2                	ld	ra,56(sp)
    8000399a:	7442                	ld	s0,48(sp)
    8000399c:	74a2                	ld	s1,40(sp)
    8000399e:	7902                	ld	s2,32(sp)
    800039a0:	69e2                	ld	s3,24(sp)
    800039a2:	6121                	addi	sp,sp,64
    800039a4:	8082                	ret
      release(&tickslock);
    800039a6:	0001d517          	auipc	a0,0x1d
    800039aa:	d2a50513          	addi	a0,a0,-726 # 800206d0 <tickslock>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	2d8080e7          	jalr	728(ra) # 80000c86 <release>
      return -1;
    800039b6:	57fd                	li	a5,-1
    800039b8:	bff9                	j	80003996 <sys_sleep+0x88>

00000000800039ba <sys_kill>:

uint64
sys_kill(void)
{
    800039ba:	1101                	addi	sp,sp,-32
    800039bc:	ec06                	sd	ra,24(sp)
    800039be:	e822                	sd	s0,16(sp)
    800039c0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800039c2:	fec40593          	addi	a1,s0,-20
    800039c6:	4501                	li	a0,0
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	d86080e7          	jalr	-634(ra) # 8000374e <argint>
    800039d0:	87aa                	mv	a5,a0
    return -1;
    800039d2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800039d4:	0007c863          	bltz	a5,800039e4 <sys_kill+0x2a>
  return kill(pid);
    800039d8:	fec42503          	lw	a0,-20(s0)
    800039dc:	fffff097          	auipc	ra,0xfffff
    800039e0:	694080e7          	jalr	1684(ra) # 80003070 <kill>
}
    800039e4:	60e2                	ld	ra,24(sp)
    800039e6:	6442                	ld	s0,16(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret

00000000800039ec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800039ec:	1101                	addi	sp,sp,-32
    800039ee:	ec06                	sd	ra,24(sp)
    800039f0:	e822                	sd	s0,16(sp)
    800039f2:	e426                	sd	s1,8(sp)
    800039f4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800039f6:	0001d517          	auipc	a0,0x1d
    800039fa:	cda50513          	addi	a0,a0,-806 # 800206d0 <tickslock>
    800039fe:	ffffd097          	auipc	ra,0xffffd
    80003a02:	1d4080e7          	jalr	468(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003a06:	00006497          	auipc	s1,0x6
    80003a0a:	62a4a483          	lw	s1,1578(s1) # 8000a030 <ticks>
  release(&tickslock);
    80003a0e:	0001d517          	auipc	a0,0x1d
    80003a12:	cc250513          	addi	a0,a0,-830 # 800206d0 <tickslock>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	270080e7          	jalr	624(ra) # 80000c86 <release>
  return xticks;
}
    80003a1e:	02049513          	slli	a0,s1,0x20
    80003a22:	9101                	srli	a0,a0,0x20
    80003a24:	60e2                	ld	ra,24(sp)
    80003a26:	6442                	ld	s0,16(sp)
    80003a28:	64a2                	ld	s1,8(sp)
    80003a2a:	6105                	addi	sp,sp,32
    80003a2c:	8082                	ret

0000000080003a2e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a2e:	7179                	addi	sp,sp,-48
    80003a30:	f406                	sd	ra,40(sp)
    80003a32:	f022                	sd	s0,32(sp)
    80003a34:	ec26                	sd	s1,24(sp)
    80003a36:	e84a                	sd	s2,16(sp)
    80003a38:	e44e                	sd	s3,8(sp)
    80003a3a:	e052                	sd	s4,0(sp)
    80003a3c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a3e:	00006597          	auipc	a1,0x6
    80003a42:	c6a58593          	addi	a1,a1,-918 # 800096a8 <syscalls+0xb0>
    80003a46:	0001d517          	auipc	a0,0x1d
    80003a4a:	ca250513          	addi	a0,a0,-862 # 800206e8 <bcache>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	0f4080e7          	jalr	244(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003a56:	00025797          	auipc	a5,0x25
    80003a5a:	c9278793          	addi	a5,a5,-878 # 800286e8 <bcache+0x8000>
    80003a5e:	00025717          	auipc	a4,0x25
    80003a62:	ef270713          	addi	a4,a4,-270 # 80028950 <bcache+0x8268>
    80003a66:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003a6a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003a6e:	0001d497          	auipc	s1,0x1d
    80003a72:	c9248493          	addi	s1,s1,-878 # 80020700 <bcache+0x18>
    b->next = bcache.head.next;
    80003a76:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003a78:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003a7a:	00006a17          	auipc	s4,0x6
    80003a7e:	c36a0a13          	addi	s4,s4,-970 # 800096b0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003a82:	2b893783          	ld	a5,696(s2)
    80003a86:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003a88:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003a8c:	85d2                	mv	a1,s4
    80003a8e:	01048513          	addi	a0,s1,16
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	7d4080e7          	jalr	2004(ra) # 80005266 <initsleeplock>
    bcache.head.next->prev = b;
    80003a9a:	2b893783          	ld	a5,696(s2)
    80003a9e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003aa0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003aa4:	45848493          	addi	s1,s1,1112
    80003aa8:	fd349de3          	bne	s1,s3,80003a82 <binit+0x54>
  }
}
    80003aac:	70a2                	ld	ra,40(sp)
    80003aae:	7402                	ld	s0,32(sp)
    80003ab0:	64e2                	ld	s1,24(sp)
    80003ab2:	6942                	ld	s2,16(sp)
    80003ab4:	69a2                	ld	s3,8(sp)
    80003ab6:	6a02                	ld	s4,0(sp)
    80003ab8:	6145                	addi	sp,sp,48
    80003aba:	8082                	ret

0000000080003abc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003abc:	7179                	addi	sp,sp,-48
    80003abe:	f406                	sd	ra,40(sp)
    80003ac0:	f022                	sd	s0,32(sp)
    80003ac2:	ec26                	sd	s1,24(sp)
    80003ac4:	e84a                	sd	s2,16(sp)
    80003ac6:	e44e                	sd	s3,8(sp)
    80003ac8:	1800                	addi	s0,sp,48
    80003aca:	892a                	mv	s2,a0
    80003acc:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003ace:	0001d517          	auipc	a0,0x1d
    80003ad2:	c1a50513          	addi	a0,a0,-998 # 800206e8 <bcache>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	0fc080e7          	jalr	252(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003ade:	00025497          	auipc	s1,0x25
    80003ae2:	ec24b483          	ld	s1,-318(s1) # 800289a0 <bcache+0x82b8>
    80003ae6:	00025797          	auipc	a5,0x25
    80003aea:	e6a78793          	addi	a5,a5,-406 # 80028950 <bcache+0x8268>
    80003aee:	02f48f63          	beq	s1,a5,80003b2c <bread+0x70>
    80003af2:	873e                	mv	a4,a5
    80003af4:	a021                	j	80003afc <bread+0x40>
    80003af6:	68a4                	ld	s1,80(s1)
    80003af8:	02e48a63          	beq	s1,a4,80003b2c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003afc:	449c                	lw	a5,8(s1)
    80003afe:	ff279ce3          	bne	a5,s2,80003af6 <bread+0x3a>
    80003b02:	44dc                	lw	a5,12(s1)
    80003b04:	ff3799e3          	bne	a5,s3,80003af6 <bread+0x3a>
      b->refcnt++;
    80003b08:	40bc                	lw	a5,64(s1)
    80003b0a:	2785                	addiw	a5,a5,1
    80003b0c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b0e:	0001d517          	auipc	a0,0x1d
    80003b12:	bda50513          	addi	a0,a0,-1062 # 800206e8 <bcache>
    80003b16:	ffffd097          	auipc	ra,0xffffd
    80003b1a:	170080e7          	jalr	368(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003b1e:	01048513          	addi	a0,s1,16
    80003b22:	00001097          	auipc	ra,0x1
    80003b26:	77e080e7          	jalr	1918(ra) # 800052a0 <acquiresleep>
      return b;
    80003b2a:	a8b9                	j	80003b88 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b2c:	00025497          	auipc	s1,0x25
    80003b30:	e6c4b483          	ld	s1,-404(s1) # 80028998 <bcache+0x82b0>
    80003b34:	00025797          	auipc	a5,0x25
    80003b38:	e1c78793          	addi	a5,a5,-484 # 80028950 <bcache+0x8268>
    80003b3c:	00f48863          	beq	s1,a5,80003b4c <bread+0x90>
    80003b40:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b42:	40bc                	lw	a5,64(s1)
    80003b44:	cf81                	beqz	a5,80003b5c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b46:	64a4                	ld	s1,72(s1)
    80003b48:	fee49de3          	bne	s1,a4,80003b42 <bread+0x86>
  panic("bget: no buffers");
    80003b4c:	00006517          	auipc	a0,0x6
    80003b50:	b6c50513          	addi	a0,a0,-1172 # 800096b8 <syscalls+0xc0>
    80003b54:	ffffd097          	auipc	ra,0xffffd
    80003b58:	9d6080e7          	jalr	-1578(ra) # 8000052a <panic>
      b->dev = dev;
    80003b5c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003b60:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003b64:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003b68:	4785                	li	a5,1
    80003b6a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b6c:	0001d517          	auipc	a0,0x1d
    80003b70:	b7c50513          	addi	a0,a0,-1156 # 800206e8 <bcache>
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	112080e7          	jalr	274(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003b7c:	01048513          	addi	a0,s1,16
    80003b80:	00001097          	auipc	ra,0x1
    80003b84:	720080e7          	jalr	1824(ra) # 800052a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003b88:	409c                	lw	a5,0(s1)
    80003b8a:	cb89                	beqz	a5,80003b9c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	70a2                	ld	ra,40(sp)
    80003b90:	7402                	ld	s0,32(sp)
    80003b92:	64e2                	ld	s1,24(sp)
    80003b94:	6942                	ld	s2,16(sp)
    80003b96:	69a2                	ld	s3,8(sp)
    80003b98:	6145                	addi	sp,sp,48
    80003b9a:	8082                	ret
    virtio_disk_rw(b, 0);
    80003b9c:	4581                	li	a1,0
    80003b9e:	8526                	mv	a0,s1
    80003ba0:	00003097          	auipc	ra,0x3
    80003ba4:	446080e7          	jalr	1094(ra) # 80006fe6 <virtio_disk_rw>
    b->valid = 1;
    80003ba8:	4785                	li	a5,1
    80003baa:	c09c                	sw	a5,0(s1)
  return b;
    80003bac:	b7c5                	j	80003b8c <bread+0xd0>

0000000080003bae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003bae:	1101                	addi	sp,sp,-32
    80003bb0:	ec06                	sd	ra,24(sp)
    80003bb2:	e822                	sd	s0,16(sp)
    80003bb4:	e426                	sd	s1,8(sp)
    80003bb6:	1000                	addi	s0,sp,32
    80003bb8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bba:	0541                	addi	a0,a0,16
    80003bbc:	00001097          	auipc	ra,0x1
    80003bc0:	77e080e7          	jalr	1918(ra) # 8000533a <holdingsleep>
    80003bc4:	cd01                	beqz	a0,80003bdc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003bc6:	4585                	li	a1,1
    80003bc8:	8526                	mv	a0,s1
    80003bca:	00003097          	auipc	ra,0x3
    80003bce:	41c080e7          	jalr	1052(ra) # 80006fe6 <virtio_disk_rw>
}
    80003bd2:	60e2                	ld	ra,24(sp)
    80003bd4:	6442                	ld	s0,16(sp)
    80003bd6:	64a2                	ld	s1,8(sp)
    80003bd8:	6105                	addi	sp,sp,32
    80003bda:	8082                	ret
    panic("bwrite");
    80003bdc:	00006517          	auipc	a0,0x6
    80003be0:	af450513          	addi	a0,a0,-1292 # 800096d0 <syscalls+0xd8>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	946080e7          	jalr	-1722(ra) # 8000052a <panic>

0000000080003bec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	e04a                	sd	s2,0(sp)
    80003bf6:	1000                	addi	s0,sp,32
    80003bf8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003bfa:	01050913          	addi	s2,a0,16
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00001097          	auipc	ra,0x1
    80003c04:	73a080e7          	jalr	1850(ra) # 8000533a <holdingsleep>
    80003c08:	c92d                	beqz	a0,80003c7a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00001097          	auipc	ra,0x1
    80003c10:	6ea080e7          	jalr	1770(ra) # 800052f6 <releasesleep>

  acquire(&bcache.lock);
    80003c14:	0001d517          	auipc	a0,0x1d
    80003c18:	ad450513          	addi	a0,a0,-1324 # 800206e8 <bcache>
    80003c1c:	ffffd097          	auipc	ra,0xffffd
    80003c20:	fb6080e7          	jalr	-74(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003c24:	40bc                	lw	a5,64(s1)
    80003c26:	37fd                	addiw	a5,a5,-1
    80003c28:	0007871b          	sext.w	a4,a5
    80003c2c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c2e:	eb05                	bnez	a4,80003c5e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c30:	68bc                	ld	a5,80(s1)
    80003c32:	64b8                	ld	a4,72(s1)
    80003c34:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c36:	64bc                	ld	a5,72(s1)
    80003c38:	68b8                	ld	a4,80(s1)
    80003c3a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c3c:	00025797          	auipc	a5,0x25
    80003c40:	aac78793          	addi	a5,a5,-1364 # 800286e8 <bcache+0x8000>
    80003c44:	2b87b703          	ld	a4,696(a5)
    80003c48:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003c4a:	00025717          	auipc	a4,0x25
    80003c4e:	d0670713          	addi	a4,a4,-762 # 80028950 <bcache+0x8268>
    80003c52:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003c54:	2b87b703          	ld	a4,696(a5)
    80003c58:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003c5a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003c5e:	0001d517          	auipc	a0,0x1d
    80003c62:	a8a50513          	addi	a0,a0,-1398 # 800206e8 <bcache>
    80003c66:	ffffd097          	auipc	ra,0xffffd
    80003c6a:	020080e7          	jalr	32(ra) # 80000c86 <release>
}
    80003c6e:	60e2                	ld	ra,24(sp)
    80003c70:	6442                	ld	s0,16(sp)
    80003c72:	64a2                	ld	s1,8(sp)
    80003c74:	6902                	ld	s2,0(sp)
    80003c76:	6105                	addi	sp,sp,32
    80003c78:	8082                	ret
    panic("brelse");
    80003c7a:	00006517          	auipc	a0,0x6
    80003c7e:	a5e50513          	addi	a0,a0,-1442 # 800096d8 <syscalls+0xe0>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8a8080e7          	jalr	-1880(ra) # 8000052a <panic>

0000000080003c8a <bpin>:

void
bpin(struct buf *b) {
    80003c8a:	1101                	addi	sp,sp,-32
    80003c8c:	ec06                	sd	ra,24(sp)
    80003c8e:	e822                	sd	s0,16(sp)
    80003c90:	e426                	sd	s1,8(sp)
    80003c92:	1000                	addi	s0,sp,32
    80003c94:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c96:	0001d517          	auipc	a0,0x1d
    80003c9a:	a5250513          	addi	a0,a0,-1454 # 800206e8 <bcache>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	f34080e7          	jalr	-204(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003ca6:	40bc                	lw	a5,64(s1)
    80003ca8:	2785                	addiw	a5,a5,1
    80003caa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003cac:	0001d517          	auipc	a0,0x1d
    80003cb0:	a3c50513          	addi	a0,a0,-1476 # 800206e8 <bcache>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	fd2080e7          	jalr	-46(ra) # 80000c86 <release>
}
    80003cbc:	60e2                	ld	ra,24(sp)
    80003cbe:	6442                	ld	s0,16(sp)
    80003cc0:	64a2                	ld	s1,8(sp)
    80003cc2:	6105                	addi	sp,sp,32
    80003cc4:	8082                	ret

0000000080003cc6 <bunpin>:

void
bunpin(struct buf *b) {
    80003cc6:	1101                	addi	sp,sp,-32
    80003cc8:	ec06                	sd	ra,24(sp)
    80003cca:	e822                	sd	s0,16(sp)
    80003ccc:	e426                	sd	s1,8(sp)
    80003cce:	1000                	addi	s0,sp,32
    80003cd0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cd2:	0001d517          	auipc	a0,0x1d
    80003cd6:	a1650513          	addi	a0,a0,-1514 # 800206e8 <bcache>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	ef8080e7          	jalr	-264(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003ce2:	40bc                	lw	a5,64(s1)
    80003ce4:	37fd                	addiw	a5,a5,-1
    80003ce6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ce8:	0001d517          	auipc	a0,0x1d
    80003cec:	a0050513          	addi	a0,a0,-1536 # 800206e8 <bcache>
    80003cf0:	ffffd097          	auipc	ra,0xffffd
    80003cf4:	f96080e7          	jalr	-106(ra) # 80000c86 <release>
}
    80003cf8:	60e2                	ld	ra,24(sp)
    80003cfa:	6442                	ld	s0,16(sp)
    80003cfc:	64a2                	ld	s1,8(sp)
    80003cfe:	6105                	addi	sp,sp,32
    80003d00:	8082                	ret

0000000080003d02 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d02:	1101                	addi	sp,sp,-32
    80003d04:	ec06                	sd	ra,24(sp)
    80003d06:	e822                	sd	s0,16(sp)
    80003d08:	e426                	sd	s1,8(sp)
    80003d0a:	e04a                	sd	s2,0(sp)
    80003d0c:	1000                	addi	s0,sp,32
    80003d0e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d10:	00d5d59b          	srliw	a1,a1,0xd
    80003d14:	00025797          	auipc	a5,0x25
    80003d18:	0b07a783          	lw	a5,176(a5) # 80028dc4 <sb+0x1c>
    80003d1c:	9dbd                	addw	a1,a1,a5
    80003d1e:	00000097          	auipc	ra,0x0
    80003d22:	d9e080e7          	jalr	-610(ra) # 80003abc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d26:	0074f713          	andi	a4,s1,7
    80003d2a:	4785                	li	a5,1
    80003d2c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d30:	14ce                	slli	s1,s1,0x33
    80003d32:	90d9                	srli	s1,s1,0x36
    80003d34:	00950733          	add	a4,a0,s1
    80003d38:	05874703          	lbu	a4,88(a4)
    80003d3c:	00e7f6b3          	and	a3,a5,a4
    80003d40:	c69d                	beqz	a3,80003d6e <bfree+0x6c>
    80003d42:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d44:	94aa                	add	s1,s1,a0
    80003d46:	fff7c793          	not	a5,a5
    80003d4a:	8ff9                	and	a5,a5,a4
    80003d4c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003d50:	00001097          	auipc	ra,0x1
    80003d54:	430080e7          	jalr	1072(ra) # 80005180 <log_write>
  brelse(bp);
    80003d58:	854a                	mv	a0,s2
    80003d5a:	00000097          	auipc	ra,0x0
    80003d5e:	e92080e7          	jalr	-366(ra) # 80003bec <brelse>
}
    80003d62:	60e2                	ld	ra,24(sp)
    80003d64:	6442                	ld	s0,16(sp)
    80003d66:	64a2                	ld	s1,8(sp)
    80003d68:	6902                	ld	s2,0(sp)
    80003d6a:	6105                	addi	sp,sp,32
    80003d6c:	8082                	ret
    panic("freeing free block");
    80003d6e:	00006517          	auipc	a0,0x6
    80003d72:	97250513          	addi	a0,a0,-1678 # 800096e0 <syscalls+0xe8>
    80003d76:	ffffc097          	auipc	ra,0xffffc
    80003d7a:	7b4080e7          	jalr	1972(ra) # 8000052a <panic>

0000000080003d7e <balloc>:
{
    80003d7e:	711d                	addi	sp,sp,-96
    80003d80:	ec86                	sd	ra,88(sp)
    80003d82:	e8a2                	sd	s0,80(sp)
    80003d84:	e4a6                	sd	s1,72(sp)
    80003d86:	e0ca                	sd	s2,64(sp)
    80003d88:	fc4e                	sd	s3,56(sp)
    80003d8a:	f852                	sd	s4,48(sp)
    80003d8c:	f456                	sd	s5,40(sp)
    80003d8e:	f05a                	sd	s6,32(sp)
    80003d90:	ec5e                	sd	s7,24(sp)
    80003d92:	e862                	sd	s8,16(sp)
    80003d94:	e466                	sd	s9,8(sp)
    80003d96:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003d98:	00025797          	auipc	a5,0x25
    80003d9c:	0147a783          	lw	a5,20(a5) # 80028dac <sb+0x4>
    80003da0:	cbd1                	beqz	a5,80003e34 <balloc+0xb6>
    80003da2:	8baa                	mv	s7,a0
    80003da4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003da6:	00025b17          	auipc	s6,0x25
    80003daa:	002b0b13          	addi	s6,s6,2 # 80028da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003dae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003db0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003db2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003db4:	6c89                	lui	s9,0x2
    80003db6:	a831                	j	80003dd2 <balloc+0x54>
    brelse(bp);
    80003db8:	854a                	mv	a0,s2
    80003dba:	00000097          	auipc	ra,0x0
    80003dbe:	e32080e7          	jalr	-462(ra) # 80003bec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003dc2:	015c87bb          	addw	a5,s9,s5
    80003dc6:	00078a9b          	sext.w	s5,a5
    80003dca:	004b2703          	lw	a4,4(s6)
    80003dce:	06eaf363          	bgeu	s5,a4,80003e34 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003dd2:	41fad79b          	sraiw	a5,s5,0x1f
    80003dd6:	0137d79b          	srliw	a5,a5,0x13
    80003dda:	015787bb          	addw	a5,a5,s5
    80003dde:	40d7d79b          	sraiw	a5,a5,0xd
    80003de2:	01cb2583          	lw	a1,28(s6)
    80003de6:	9dbd                	addw	a1,a1,a5
    80003de8:	855e                	mv	a0,s7
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	cd2080e7          	jalr	-814(ra) # 80003abc <bread>
    80003df2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003df4:	004b2503          	lw	a0,4(s6)
    80003df8:	000a849b          	sext.w	s1,s5
    80003dfc:	8662                	mv	a2,s8
    80003dfe:	faa4fde3          	bgeu	s1,a0,80003db8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003e02:	41f6579b          	sraiw	a5,a2,0x1f
    80003e06:	01d7d69b          	srliw	a3,a5,0x1d
    80003e0a:	00c6873b          	addw	a4,a3,a2
    80003e0e:	00777793          	andi	a5,a4,7
    80003e12:	9f95                	subw	a5,a5,a3
    80003e14:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003e18:	4037571b          	sraiw	a4,a4,0x3
    80003e1c:	00e906b3          	add	a3,s2,a4
    80003e20:	0586c683          	lbu	a3,88(a3)
    80003e24:	00d7f5b3          	and	a1,a5,a3
    80003e28:	cd91                	beqz	a1,80003e44 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e2a:	2605                	addiw	a2,a2,1
    80003e2c:	2485                	addiw	s1,s1,1
    80003e2e:	fd4618e3          	bne	a2,s4,80003dfe <balloc+0x80>
    80003e32:	b759                	j	80003db8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003e34:	00006517          	auipc	a0,0x6
    80003e38:	8c450513          	addi	a0,a0,-1852 # 800096f8 <syscalls+0x100>
    80003e3c:	ffffc097          	auipc	ra,0xffffc
    80003e40:	6ee080e7          	jalr	1774(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e44:	974a                	add	a4,a4,s2
    80003e46:	8fd5                	or	a5,a5,a3
    80003e48:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00001097          	auipc	ra,0x1
    80003e52:	332080e7          	jalr	818(ra) # 80005180 <log_write>
        brelse(bp);
    80003e56:	854a                	mv	a0,s2
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	d94080e7          	jalr	-620(ra) # 80003bec <brelse>
  bp = bread(dev, bno);
    80003e60:	85a6                	mv	a1,s1
    80003e62:	855e                	mv	a0,s7
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	c58080e7          	jalr	-936(ra) # 80003abc <bread>
    80003e6c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e6e:	40000613          	li	a2,1024
    80003e72:	4581                	li	a1,0
    80003e74:	05850513          	addi	a0,a0,88
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	e56080e7          	jalr	-426(ra) # 80000cce <memset>
  log_write(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	00001097          	auipc	ra,0x1
    80003e86:	2fe080e7          	jalr	766(ra) # 80005180 <log_write>
  brelse(bp);
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	d60080e7          	jalr	-672(ra) # 80003bec <brelse>
}
    80003e94:	8526                	mv	a0,s1
    80003e96:	60e6                	ld	ra,88(sp)
    80003e98:	6446                	ld	s0,80(sp)
    80003e9a:	64a6                	ld	s1,72(sp)
    80003e9c:	6906                	ld	s2,64(sp)
    80003e9e:	79e2                	ld	s3,56(sp)
    80003ea0:	7a42                	ld	s4,48(sp)
    80003ea2:	7aa2                	ld	s5,40(sp)
    80003ea4:	7b02                	ld	s6,32(sp)
    80003ea6:	6be2                	ld	s7,24(sp)
    80003ea8:	6c42                	ld	s8,16(sp)
    80003eaa:	6ca2                	ld	s9,8(sp)
    80003eac:	6125                	addi	sp,sp,96
    80003eae:	8082                	ret

0000000080003eb0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003eb0:	7179                	addi	sp,sp,-48
    80003eb2:	f406                	sd	ra,40(sp)
    80003eb4:	f022                	sd	s0,32(sp)
    80003eb6:	ec26                	sd	s1,24(sp)
    80003eb8:	e84a                	sd	s2,16(sp)
    80003eba:	e44e                	sd	s3,8(sp)
    80003ebc:	e052                	sd	s4,0(sp)
    80003ebe:	1800                	addi	s0,sp,48
    80003ec0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003ec2:	47ad                	li	a5,11
    80003ec4:	04b7fe63          	bgeu	a5,a1,80003f20 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003ec8:	ff45849b          	addiw	s1,a1,-12
    80003ecc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003ed0:	0ff00793          	li	a5,255
    80003ed4:	0ae7e463          	bltu	a5,a4,80003f7c <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003ed8:	08052583          	lw	a1,128(a0)
    80003edc:	c5b5                	beqz	a1,80003f48 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003ede:	00092503          	lw	a0,0(s2)
    80003ee2:	00000097          	auipc	ra,0x0
    80003ee6:	bda080e7          	jalr	-1062(ra) # 80003abc <bread>
    80003eea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003eec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003ef0:	02049713          	slli	a4,s1,0x20
    80003ef4:	01e75593          	srli	a1,a4,0x1e
    80003ef8:	00b784b3          	add	s1,a5,a1
    80003efc:	0004a983          	lw	s3,0(s1)
    80003f00:	04098e63          	beqz	s3,80003f5c <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003f04:	8552                	mv	a0,s4
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	ce6080e7          	jalr	-794(ra) # 80003bec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003f0e:	854e                	mv	a0,s3
    80003f10:	70a2                	ld	ra,40(sp)
    80003f12:	7402                	ld	s0,32(sp)
    80003f14:	64e2                	ld	s1,24(sp)
    80003f16:	6942                	ld	s2,16(sp)
    80003f18:	69a2                	ld	s3,8(sp)
    80003f1a:	6a02                	ld	s4,0(sp)
    80003f1c:	6145                	addi	sp,sp,48
    80003f1e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003f20:	02059793          	slli	a5,a1,0x20
    80003f24:	01e7d593          	srli	a1,a5,0x1e
    80003f28:	00b504b3          	add	s1,a0,a1
    80003f2c:	0504a983          	lw	s3,80(s1)
    80003f30:	fc099fe3          	bnez	s3,80003f0e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003f34:	4108                	lw	a0,0(a0)
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	e48080e7          	jalr	-440(ra) # 80003d7e <balloc>
    80003f3e:	0005099b          	sext.w	s3,a0
    80003f42:	0534a823          	sw	s3,80(s1)
    80003f46:	b7e1                	j	80003f0e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003f48:	4108                	lw	a0,0(a0)
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	e34080e7          	jalr	-460(ra) # 80003d7e <balloc>
    80003f52:	0005059b          	sext.w	a1,a0
    80003f56:	08b92023          	sw	a1,128(s2)
    80003f5a:	b751                	j	80003ede <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003f5c:	00092503          	lw	a0,0(s2)
    80003f60:	00000097          	auipc	ra,0x0
    80003f64:	e1e080e7          	jalr	-482(ra) # 80003d7e <balloc>
    80003f68:	0005099b          	sext.w	s3,a0
    80003f6c:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003f70:	8552                	mv	a0,s4
    80003f72:	00001097          	auipc	ra,0x1
    80003f76:	20e080e7          	jalr	526(ra) # 80005180 <log_write>
    80003f7a:	b769                	j	80003f04 <bmap+0x54>
  panic("bmap: out of range");
    80003f7c:	00005517          	auipc	a0,0x5
    80003f80:	79450513          	addi	a0,a0,1940 # 80009710 <syscalls+0x118>
    80003f84:	ffffc097          	auipc	ra,0xffffc
    80003f88:	5a6080e7          	jalr	1446(ra) # 8000052a <panic>

0000000080003f8c <iget>:
{
    80003f8c:	7179                	addi	sp,sp,-48
    80003f8e:	f406                	sd	ra,40(sp)
    80003f90:	f022                	sd	s0,32(sp)
    80003f92:	ec26                	sd	s1,24(sp)
    80003f94:	e84a                	sd	s2,16(sp)
    80003f96:	e44e                	sd	s3,8(sp)
    80003f98:	e052                	sd	s4,0(sp)
    80003f9a:	1800                	addi	s0,sp,48
    80003f9c:	89aa                	mv	s3,a0
    80003f9e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003fa0:	00025517          	auipc	a0,0x25
    80003fa4:	e2850513          	addi	a0,a0,-472 # 80028dc8 <itable>
    80003fa8:	ffffd097          	auipc	ra,0xffffd
    80003fac:	c2a080e7          	jalr	-982(ra) # 80000bd2 <acquire>
  empty = 0;
    80003fb0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fb2:	00025497          	auipc	s1,0x25
    80003fb6:	e2e48493          	addi	s1,s1,-466 # 80028de0 <itable+0x18>
    80003fba:	00027697          	auipc	a3,0x27
    80003fbe:	8b668693          	addi	a3,a3,-1866 # 8002a870 <log>
    80003fc2:	a039                	j	80003fd0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003fc4:	02090b63          	beqz	s2,80003ffa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003fc8:	08848493          	addi	s1,s1,136
    80003fcc:	02d48a63          	beq	s1,a3,80004000 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003fd0:	449c                	lw	a5,8(s1)
    80003fd2:	fef059e3          	blez	a5,80003fc4 <iget+0x38>
    80003fd6:	4098                	lw	a4,0(s1)
    80003fd8:	ff3716e3          	bne	a4,s3,80003fc4 <iget+0x38>
    80003fdc:	40d8                	lw	a4,4(s1)
    80003fde:	ff4713e3          	bne	a4,s4,80003fc4 <iget+0x38>
      ip->ref++;
    80003fe2:	2785                	addiw	a5,a5,1
    80003fe4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003fe6:	00025517          	auipc	a0,0x25
    80003fea:	de250513          	addi	a0,a0,-542 # 80028dc8 <itable>
    80003fee:	ffffd097          	auipc	ra,0xffffd
    80003ff2:	c98080e7          	jalr	-872(ra) # 80000c86 <release>
      return ip;
    80003ff6:	8926                	mv	s2,s1
    80003ff8:	a03d                	j	80004026 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ffa:	f7f9                	bnez	a5,80003fc8 <iget+0x3c>
    80003ffc:	8926                	mv	s2,s1
    80003ffe:	b7e9                	j	80003fc8 <iget+0x3c>
  if(empty == 0)
    80004000:	02090c63          	beqz	s2,80004038 <iget+0xac>
  ip->dev = dev;
    80004004:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004008:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000400c:	4785                	li	a5,1
    8000400e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004012:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004016:	00025517          	auipc	a0,0x25
    8000401a:	db250513          	addi	a0,a0,-590 # 80028dc8 <itable>
    8000401e:	ffffd097          	auipc	ra,0xffffd
    80004022:	c68080e7          	jalr	-920(ra) # 80000c86 <release>
}
    80004026:	854a                	mv	a0,s2
    80004028:	70a2                	ld	ra,40(sp)
    8000402a:	7402                	ld	s0,32(sp)
    8000402c:	64e2                	ld	s1,24(sp)
    8000402e:	6942                	ld	s2,16(sp)
    80004030:	69a2                	ld	s3,8(sp)
    80004032:	6a02                	ld	s4,0(sp)
    80004034:	6145                	addi	sp,sp,48
    80004036:	8082                	ret
    panic("iget: no inodes");
    80004038:	00005517          	auipc	a0,0x5
    8000403c:	6f050513          	addi	a0,a0,1776 # 80009728 <syscalls+0x130>
    80004040:	ffffc097          	auipc	ra,0xffffc
    80004044:	4ea080e7          	jalr	1258(ra) # 8000052a <panic>

0000000080004048 <fsinit>:
fsinit(int dev) {
    80004048:	7179                	addi	sp,sp,-48
    8000404a:	f406                	sd	ra,40(sp)
    8000404c:	f022                	sd	s0,32(sp)
    8000404e:	ec26                	sd	s1,24(sp)
    80004050:	e84a                	sd	s2,16(sp)
    80004052:	e44e                	sd	s3,8(sp)
    80004054:	1800                	addi	s0,sp,48
    80004056:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80004058:	4585                	li	a1,1
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	a62080e7          	jalr	-1438(ra) # 80003abc <bread>
    80004062:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80004064:	00025997          	auipc	s3,0x25
    80004068:	d4498993          	addi	s3,s3,-700 # 80028da8 <sb>
    8000406c:	02000613          	li	a2,32
    80004070:	05850593          	addi	a1,a0,88
    80004074:	854e                	mv	a0,s3
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	cb4080e7          	jalr	-844(ra) # 80000d2a <memmove>
  brelse(bp);
    8000407e:	8526                	mv	a0,s1
    80004080:	00000097          	auipc	ra,0x0
    80004084:	b6c080e7          	jalr	-1172(ra) # 80003bec <brelse>
  if(sb.magic != FSMAGIC)
    80004088:	0009a703          	lw	a4,0(s3)
    8000408c:	102037b7          	lui	a5,0x10203
    80004090:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004094:	02f71263          	bne	a4,a5,800040b8 <fsinit+0x70>
  initlog(dev, &sb);
    80004098:	00025597          	auipc	a1,0x25
    8000409c:	d1058593          	addi	a1,a1,-752 # 80028da8 <sb>
    800040a0:	854a                	mv	a0,s2
    800040a2:	00001097          	auipc	ra,0x1
    800040a6:	e60080e7          	jalr	-416(ra) # 80004f02 <initlog>
}
    800040aa:	70a2                	ld	ra,40(sp)
    800040ac:	7402                	ld	s0,32(sp)
    800040ae:	64e2                	ld	s1,24(sp)
    800040b0:	6942                	ld	s2,16(sp)
    800040b2:	69a2                	ld	s3,8(sp)
    800040b4:	6145                	addi	sp,sp,48
    800040b6:	8082                	ret
    panic("invalid file system");
    800040b8:	00005517          	auipc	a0,0x5
    800040bc:	68050513          	addi	a0,a0,1664 # 80009738 <syscalls+0x140>
    800040c0:	ffffc097          	auipc	ra,0xffffc
    800040c4:	46a080e7          	jalr	1130(ra) # 8000052a <panic>

00000000800040c8 <iinit>:
{
    800040c8:	7179                	addi	sp,sp,-48
    800040ca:	f406                	sd	ra,40(sp)
    800040cc:	f022                	sd	s0,32(sp)
    800040ce:	ec26                	sd	s1,24(sp)
    800040d0:	e84a                	sd	s2,16(sp)
    800040d2:	e44e                	sd	s3,8(sp)
    800040d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800040d6:	00005597          	auipc	a1,0x5
    800040da:	67a58593          	addi	a1,a1,1658 # 80009750 <syscalls+0x158>
    800040de:	00025517          	auipc	a0,0x25
    800040e2:	cea50513          	addi	a0,a0,-790 # 80028dc8 <itable>
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	a5c080e7          	jalr	-1444(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    800040ee:	00025497          	auipc	s1,0x25
    800040f2:	d0248493          	addi	s1,s1,-766 # 80028df0 <itable+0x28>
    800040f6:	00026997          	auipc	s3,0x26
    800040fa:	78a98993          	addi	s3,s3,1930 # 8002a880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800040fe:	00005917          	auipc	s2,0x5
    80004102:	65a90913          	addi	s2,s2,1626 # 80009758 <syscalls+0x160>
    80004106:	85ca                	mv	a1,s2
    80004108:	8526                	mv	a0,s1
    8000410a:	00001097          	auipc	ra,0x1
    8000410e:	15c080e7          	jalr	348(ra) # 80005266 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004112:	08848493          	addi	s1,s1,136
    80004116:	ff3498e3          	bne	s1,s3,80004106 <iinit+0x3e>
}
    8000411a:	70a2                	ld	ra,40(sp)
    8000411c:	7402                	ld	s0,32(sp)
    8000411e:	64e2                	ld	s1,24(sp)
    80004120:	6942                	ld	s2,16(sp)
    80004122:	69a2                	ld	s3,8(sp)
    80004124:	6145                	addi	sp,sp,48
    80004126:	8082                	ret

0000000080004128 <ialloc>:
{
    80004128:	715d                	addi	sp,sp,-80
    8000412a:	e486                	sd	ra,72(sp)
    8000412c:	e0a2                	sd	s0,64(sp)
    8000412e:	fc26                	sd	s1,56(sp)
    80004130:	f84a                	sd	s2,48(sp)
    80004132:	f44e                	sd	s3,40(sp)
    80004134:	f052                	sd	s4,32(sp)
    80004136:	ec56                	sd	s5,24(sp)
    80004138:	e85a                	sd	s6,16(sp)
    8000413a:	e45e                	sd	s7,8(sp)
    8000413c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000413e:	00025717          	auipc	a4,0x25
    80004142:	c7672703          	lw	a4,-906(a4) # 80028db4 <sb+0xc>
    80004146:	4785                	li	a5,1
    80004148:	04e7fa63          	bgeu	a5,a4,8000419c <ialloc+0x74>
    8000414c:	8aaa                	mv	s5,a0
    8000414e:	8bae                	mv	s7,a1
    80004150:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80004152:	00025a17          	auipc	s4,0x25
    80004156:	c56a0a13          	addi	s4,s4,-938 # 80028da8 <sb>
    8000415a:	00048b1b          	sext.w	s6,s1
    8000415e:	0044d793          	srli	a5,s1,0x4
    80004162:	018a2583          	lw	a1,24(s4)
    80004166:	9dbd                	addw	a1,a1,a5
    80004168:	8556                	mv	a0,s5
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	952080e7          	jalr	-1710(ra) # 80003abc <bread>
    80004172:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80004174:	05850993          	addi	s3,a0,88
    80004178:	00f4f793          	andi	a5,s1,15
    8000417c:	079a                	slli	a5,a5,0x6
    8000417e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80004180:	00099783          	lh	a5,0(s3)
    80004184:	c785                	beqz	a5,800041ac <ialloc+0x84>
    brelse(bp);
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	a66080e7          	jalr	-1434(ra) # 80003bec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000418e:	0485                	addi	s1,s1,1
    80004190:	00ca2703          	lw	a4,12(s4)
    80004194:	0004879b          	sext.w	a5,s1
    80004198:	fce7e1e3          	bltu	a5,a4,8000415a <ialloc+0x32>
  panic("ialloc: no inodes");
    8000419c:	00005517          	auipc	a0,0x5
    800041a0:	5c450513          	addi	a0,a0,1476 # 80009760 <syscalls+0x168>
    800041a4:	ffffc097          	auipc	ra,0xffffc
    800041a8:	386080e7          	jalr	902(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800041ac:	04000613          	li	a2,64
    800041b0:	4581                	li	a1,0
    800041b2:	854e                	mv	a0,s3
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b1a080e7          	jalr	-1254(ra) # 80000cce <memset>
      dip->type = type;
    800041bc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800041c0:	854a                	mv	a0,s2
    800041c2:	00001097          	auipc	ra,0x1
    800041c6:	fbe080e7          	jalr	-66(ra) # 80005180 <log_write>
      brelse(bp);
    800041ca:	854a                	mv	a0,s2
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	a20080e7          	jalr	-1504(ra) # 80003bec <brelse>
      return iget(dev, inum);
    800041d4:	85da                	mv	a1,s6
    800041d6:	8556                	mv	a0,s5
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	db4080e7          	jalr	-588(ra) # 80003f8c <iget>
}
    800041e0:	60a6                	ld	ra,72(sp)
    800041e2:	6406                	ld	s0,64(sp)
    800041e4:	74e2                	ld	s1,56(sp)
    800041e6:	7942                	ld	s2,48(sp)
    800041e8:	79a2                	ld	s3,40(sp)
    800041ea:	7a02                	ld	s4,32(sp)
    800041ec:	6ae2                	ld	s5,24(sp)
    800041ee:	6b42                	ld	s6,16(sp)
    800041f0:	6ba2                	ld	s7,8(sp)
    800041f2:	6161                	addi	sp,sp,80
    800041f4:	8082                	ret

00000000800041f6 <iupdate>:
{
    800041f6:	1101                	addi	sp,sp,-32
    800041f8:	ec06                	sd	ra,24(sp)
    800041fa:	e822                	sd	s0,16(sp)
    800041fc:	e426                	sd	s1,8(sp)
    800041fe:	e04a                	sd	s2,0(sp)
    80004200:	1000                	addi	s0,sp,32
    80004202:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004204:	415c                	lw	a5,4(a0)
    80004206:	0047d79b          	srliw	a5,a5,0x4
    8000420a:	00025597          	auipc	a1,0x25
    8000420e:	bb65a583          	lw	a1,-1098(a1) # 80028dc0 <sb+0x18>
    80004212:	9dbd                	addw	a1,a1,a5
    80004214:	4108                	lw	a0,0(a0)
    80004216:	00000097          	auipc	ra,0x0
    8000421a:	8a6080e7          	jalr	-1882(ra) # 80003abc <bread>
    8000421e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004220:	05850793          	addi	a5,a0,88
    80004224:	40c8                	lw	a0,4(s1)
    80004226:	893d                	andi	a0,a0,15
    80004228:	051a                	slli	a0,a0,0x6
    8000422a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000422c:	04449703          	lh	a4,68(s1)
    80004230:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80004234:	04649703          	lh	a4,70(s1)
    80004238:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000423c:	04849703          	lh	a4,72(s1)
    80004240:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80004244:	04a49703          	lh	a4,74(s1)
    80004248:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000424c:	44f8                	lw	a4,76(s1)
    8000424e:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80004250:	03400613          	li	a2,52
    80004254:	05048593          	addi	a1,s1,80
    80004258:	0531                	addi	a0,a0,12
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	ad0080e7          	jalr	-1328(ra) # 80000d2a <memmove>
  log_write(bp);
    80004262:	854a                	mv	a0,s2
    80004264:	00001097          	auipc	ra,0x1
    80004268:	f1c080e7          	jalr	-228(ra) # 80005180 <log_write>
  brelse(bp);
    8000426c:	854a                	mv	a0,s2
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	97e080e7          	jalr	-1666(ra) # 80003bec <brelse>
}
    80004276:	60e2                	ld	ra,24(sp)
    80004278:	6442                	ld	s0,16(sp)
    8000427a:	64a2                	ld	s1,8(sp)
    8000427c:	6902                	ld	s2,0(sp)
    8000427e:	6105                	addi	sp,sp,32
    80004280:	8082                	ret

0000000080004282 <idup>:
{
    80004282:	1101                	addi	sp,sp,-32
    80004284:	ec06                	sd	ra,24(sp)
    80004286:	e822                	sd	s0,16(sp)
    80004288:	e426                	sd	s1,8(sp)
    8000428a:	1000                	addi	s0,sp,32
    8000428c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000428e:	00025517          	auipc	a0,0x25
    80004292:	b3a50513          	addi	a0,a0,-1222 # 80028dc8 <itable>
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	93c080e7          	jalr	-1732(ra) # 80000bd2 <acquire>
  ip->ref++;
    8000429e:	449c                	lw	a5,8(s1)
    800042a0:	2785                	addiw	a5,a5,1
    800042a2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042a4:	00025517          	auipc	a0,0x25
    800042a8:	b2450513          	addi	a0,a0,-1244 # 80028dc8 <itable>
    800042ac:	ffffd097          	auipc	ra,0xffffd
    800042b0:	9da080e7          	jalr	-1574(ra) # 80000c86 <release>
}
    800042b4:	8526                	mv	a0,s1
    800042b6:	60e2                	ld	ra,24(sp)
    800042b8:	6442                	ld	s0,16(sp)
    800042ba:	64a2                	ld	s1,8(sp)
    800042bc:	6105                	addi	sp,sp,32
    800042be:	8082                	ret

00000000800042c0 <ilock>:
{
    800042c0:	1101                	addi	sp,sp,-32
    800042c2:	ec06                	sd	ra,24(sp)
    800042c4:	e822                	sd	s0,16(sp)
    800042c6:	e426                	sd	s1,8(sp)
    800042c8:	e04a                	sd	s2,0(sp)
    800042ca:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800042cc:	c115                	beqz	a0,800042f0 <ilock+0x30>
    800042ce:	84aa                	mv	s1,a0
    800042d0:	451c                	lw	a5,8(a0)
    800042d2:	00f05f63          	blez	a5,800042f0 <ilock+0x30>
  acquiresleep(&ip->lock);
    800042d6:	0541                	addi	a0,a0,16
    800042d8:	00001097          	auipc	ra,0x1
    800042dc:	fc8080e7          	jalr	-56(ra) # 800052a0 <acquiresleep>
  if(ip->valid == 0){
    800042e0:	40bc                	lw	a5,64(s1)
    800042e2:	cf99                	beqz	a5,80004300 <ilock+0x40>
}
    800042e4:	60e2                	ld	ra,24(sp)
    800042e6:	6442                	ld	s0,16(sp)
    800042e8:	64a2                	ld	s1,8(sp)
    800042ea:	6902                	ld	s2,0(sp)
    800042ec:	6105                	addi	sp,sp,32
    800042ee:	8082                	ret
    panic("ilock");
    800042f0:	00005517          	auipc	a0,0x5
    800042f4:	48850513          	addi	a0,a0,1160 # 80009778 <syscalls+0x180>
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	232080e7          	jalr	562(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004300:	40dc                	lw	a5,4(s1)
    80004302:	0047d79b          	srliw	a5,a5,0x4
    80004306:	00025597          	auipc	a1,0x25
    8000430a:	aba5a583          	lw	a1,-1350(a1) # 80028dc0 <sb+0x18>
    8000430e:	9dbd                	addw	a1,a1,a5
    80004310:	4088                	lw	a0,0(s1)
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	7aa080e7          	jalr	1962(ra) # 80003abc <bread>
    8000431a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000431c:	05850593          	addi	a1,a0,88
    80004320:	40dc                	lw	a5,4(s1)
    80004322:	8bbd                	andi	a5,a5,15
    80004324:	079a                	slli	a5,a5,0x6
    80004326:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004328:	00059783          	lh	a5,0(a1)
    8000432c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80004330:	00259783          	lh	a5,2(a1)
    80004334:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004338:	00459783          	lh	a5,4(a1)
    8000433c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80004340:	00659783          	lh	a5,6(a1)
    80004344:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004348:	459c                	lw	a5,8(a1)
    8000434a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000434c:	03400613          	li	a2,52
    80004350:	05b1                	addi	a1,a1,12
    80004352:	05048513          	addi	a0,s1,80
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	9d4080e7          	jalr	-1580(ra) # 80000d2a <memmove>
    brelse(bp);
    8000435e:	854a                	mv	a0,s2
    80004360:	00000097          	auipc	ra,0x0
    80004364:	88c080e7          	jalr	-1908(ra) # 80003bec <brelse>
    ip->valid = 1;
    80004368:	4785                	li	a5,1
    8000436a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000436c:	04449783          	lh	a5,68(s1)
    80004370:	fbb5                	bnez	a5,800042e4 <ilock+0x24>
      panic("ilock: no type");
    80004372:	00005517          	auipc	a0,0x5
    80004376:	40e50513          	addi	a0,a0,1038 # 80009780 <syscalls+0x188>
    8000437a:	ffffc097          	auipc	ra,0xffffc
    8000437e:	1b0080e7          	jalr	432(ra) # 8000052a <panic>

0000000080004382 <iunlock>:
{
    80004382:	1101                	addi	sp,sp,-32
    80004384:	ec06                	sd	ra,24(sp)
    80004386:	e822                	sd	s0,16(sp)
    80004388:	e426                	sd	s1,8(sp)
    8000438a:	e04a                	sd	s2,0(sp)
    8000438c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000438e:	c905                	beqz	a0,800043be <iunlock+0x3c>
    80004390:	84aa                	mv	s1,a0
    80004392:	01050913          	addi	s2,a0,16
    80004396:	854a                	mv	a0,s2
    80004398:	00001097          	auipc	ra,0x1
    8000439c:	fa2080e7          	jalr	-94(ra) # 8000533a <holdingsleep>
    800043a0:	cd19                	beqz	a0,800043be <iunlock+0x3c>
    800043a2:	449c                	lw	a5,8(s1)
    800043a4:	00f05d63          	blez	a5,800043be <iunlock+0x3c>
  releasesleep(&ip->lock);
    800043a8:	854a                	mv	a0,s2
    800043aa:	00001097          	auipc	ra,0x1
    800043ae:	f4c080e7          	jalr	-180(ra) # 800052f6 <releasesleep>
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret
    panic("iunlock");
    800043be:	00005517          	auipc	a0,0x5
    800043c2:	3d250513          	addi	a0,a0,978 # 80009790 <syscalls+0x198>
    800043c6:	ffffc097          	auipc	ra,0xffffc
    800043ca:	164080e7          	jalr	356(ra) # 8000052a <panic>

00000000800043ce <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800043ce:	7179                	addi	sp,sp,-48
    800043d0:	f406                	sd	ra,40(sp)
    800043d2:	f022                	sd	s0,32(sp)
    800043d4:	ec26                	sd	s1,24(sp)
    800043d6:	e84a                	sd	s2,16(sp)
    800043d8:	e44e                	sd	s3,8(sp)
    800043da:	e052                	sd	s4,0(sp)
    800043dc:	1800                	addi	s0,sp,48
    800043de:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800043e0:	05050493          	addi	s1,a0,80
    800043e4:	08050913          	addi	s2,a0,128
    800043e8:	a021                	j	800043f0 <itrunc+0x22>
    800043ea:	0491                	addi	s1,s1,4
    800043ec:	01248d63          	beq	s1,s2,80004406 <itrunc+0x38>
    if(ip->addrs[i]){
    800043f0:	408c                	lw	a1,0(s1)
    800043f2:	dde5                	beqz	a1,800043ea <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800043f4:	0009a503          	lw	a0,0(s3)
    800043f8:	00000097          	auipc	ra,0x0
    800043fc:	90a080e7          	jalr	-1782(ra) # 80003d02 <bfree>
      ip->addrs[i] = 0;
    80004400:	0004a023          	sw	zero,0(s1)
    80004404:	b7dd                	j	800043ea <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004406:	0809a583          	lw	a1,128(s3)
    8000440a:	e185                	bnez	a1,8000442a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000440c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004410:	854e                	mv	a0,s3
    80004412:	00000097          	auipc	ra,0x0
    80004416:	de4080e7          	jalr	-540(ra) # 800041f6 <iupdate>
}
    8000441a:	70a2                	ld	ra,40(sp)
    8000441c:	7402                	ld	s0,32(sp)
    8000441e:	64e2                	ld	s1,24(sp)
    80004420:	6942                	ld	s2,16(sp)
    80004422:	69a2                	ld	s3,8(sp)
    80004424:	6a02                	ld	s4,0(sp)
    80004426:	6145                	addi	sp,sp,48
    80004428:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000442a:	0009a503          	lw	a0,0(s3)
    8000442e:	fffff097          	auipc	ra,0xfffff
    80004432:	68e080e7          	jalr	1678(ra) # 80003abc <bread>
    80004436:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004438:	05850493          	addi	s1,a0,88
    8000443c:	45850913          	addi	s2,a0,1112
    80004440:	a021                	j	80004448 <itrunc+0x7a>
    80004442:	0491                	addi	s1,s1,4
    80004444:	01248b63          	beq	s1,s2,8000445a <itrunc+0x8c>
      if(a[j])
    80004448:	408c                	lw	a1,0(s1)
    8000444a:	dde5                	beqz	a1,80004442 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000444c:	0009a503          	lw	a0,0(s3)
    80004450:	00000097          	auipc	ra,0x0
    80004454:	8b2080e7          	jalr	-1870(ra) # 80003d02 <bfree>
    80004458:	b7ed                	j	80004442 <itrunc+0x74>
    brelse(bp);
    8000445a:	8552                	mv	a0,s4
    8000445c:	fffff097          	auipc	ra,0xfffff
    80004460:	790080e7          	jalr	1936(ra) # 80003bec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004464:	0809a583          	lw	a1,128(s3)
    80004468:	0009a503          	lw	a0,0(s3)
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	896080e7          	jalr	-1898(ra) # 80003d02 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004474:	0809a023          	sw	zero,128(s3)
    80004478:	bf51                	j	8000440c <itrunc+0x3e>

000000008000447a <iput>:
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004488:	00025517          	auipc	a0,0x25
    8000448c:	94050513          	addi	a0,a0,-1728 # 80028dc8 <itable>
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	742080e7          	jalr	1858(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004498:	4498                	lw	a4,8(s1)
    8000449a:	4785                	li	a5,1
    8000449c:	02f70363          	beq	a4,a5,800044c2 <iput+0x48>
  ip->ref--;
    800044a0:	449c                	lw	a5,8(s1)
    800044a2:	37fd                	addiw	a5,a5,-1
    800044a4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800044a6:	00025517          	auipc	a0,0x25
    800044aa:	92250513          	addi	a0,a0,-1758 # 80028dc8 <itable>
    800044ae:	ffffc097          	auipc	ra,0xffffc
    800044b2:	7d8080e7          	jalr	2008(ra) # 80000c86 <release>
}
    800044b6:	60e2                	ld	ra,24(sp)
    800044b8:	6442                	ld	s0,16(sp)
    800044ba:	64a2                	ld	s1,8(sp)
    800044bc:	6902                	ld	s2,0(sp)
    800044be:	6105                	addi	sp,sp,32
    800044c0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800044c2:	40bc                	lw	a5,64(s1)
    800044c4:	dff1                	beqz	a5,800044a0 <iput+0x26>
    800044c6:	04a49783          	lh	a5,74(s1)
    800044ca:	fbf9                	bnez	a5,800044a0 <iput+0x26>
    acquiresleep(&ip->lock);
    800044cc:	01048913          	addi	s2,s1,16
    800044d0:	854a                	mv	a0,s2
    800044d2:	00001097          	auipc	ra,0x1
    800044d6:	dce080e7          	jalr	-562(ra) # 800052a0 <acquiresleep>
    release(&itable.lock);
    800044da:	00025517          	auipc	a0,0x25
    800044de:	8ee50513          	addi	a0,a0,-1810 # 80028dc8 <itable>
    800044e2:	ffffc097          	auipc	ra,0xffffc
    800044e6:	7a4080e7          	jalr	1956(ra) # 80000c86 <release>
    itrunc(ip);
    800044ea:	8526                	mv	a0,s1
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	ee2080e7          	jalr	-286(ra) # 800043ce <itrunc>
    ip->type = 0;
    800044f4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800044f8:	8526                	mv	a0,s1
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	cfc080e7          	jalr	-772(ra) # 800041f6 <iupdate>
    ip->valid = 0;
    80004502:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004506:	854a                	mv	a0,s2
    80004508:	00001097          	auipc	ra,0x1
    8000450c:	dee080e7          	jalr	-530(ra) # 800052f6 <releasesleep>
    acquire(&itable.lock);
    80004510:	00025517          	auipc	a0,0x25
    80004514:	8b850513          	addi	a0,a0,-1864 # 80028dc8 <itable>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	6ba080e7          	jalr	1722(ra) # 80000bd2 <acquire>
    80004520:	b741                	j	800044a0 <iput+0x26>

0000000080004522 <iunlockput>:
{
    80004522:	1101                	addi	sp,sp,-32
    80004524:	ec06                	sd	ra,24(sp)
    80004526:	e822                	sd	s0,16(sp)
    80004528:	e426                	sd	s1,8(sp)
    8000452a:	1000                	addi	s0,sp,32
    8000452c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000452e:	00000097          	auipc	ra,0x0
    80004532:	e54080e7          	jalr	-428(ra) # 80004382 <iunlock>
  iput(ip);
    80004536:	8526                	mv	a0,s1
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	f42080e7          	jalr	-190(ra) # 8000447a <iput>
}
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6105                	addi	sp,sp,32
    80004548:	8082                	ret

000000008000454a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000454a:	1141                	addi	sp,sp,-16
    8000454c:	e422                	sd	s0,8(sp)
    8000454e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004550:	411c                	lw	a5,0(a0)
    80004552:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004554:	415c                	lw	a5,4(a0)
    80004556:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004558:	04451783          	lh	a5,68(a0)
    8000455c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004560:	04a51783          	lh	a5,74(a0)
    80004564:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004568:	04c56783          	lwu	a5,76(a0)
    8000456c:	e99c                	sd	a5,16(a1)
}
    8000456e:	6422                	ld	s0,8(sp)
    80004570:	0141                	addi	sp,sp,16
    80004572:	8082                	ret

0000000080004574 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004574:	457c                	lw	a5,76(a0)
    80004576:	0ed7e963          	bltu	a5,a3,80004668 <readi+0xf4>
{
    8000457a:	7159                	addi	sp,sp,-112
    8000457c:	f486                	sd	ra,104(sp)
    8000457e:	f0a2                	sd	s0,96(sp)
    80004580:	eca6                	sd	s1,88(sp)
    80004582:	e8ca                	sd	s2,80(sp)
    80004584:	e4ce                	sd	s3,72(sp)
    80004586:	e0d2                	sd	s4,64(sp)
    80004588:	fc56                	sd	s5,56(sp)
    8000458a:	f85a                	sd	s6,48(sp)
    8000458c:	f45e                	sd	s7,40(sp)
    8000458e:	f062                	sd	s8,32(sp)
    80004590:	ec66                	sd	s9,24(sp)
    80004592:	e86a                	sd	s10,16(sp)
    80004594:	e46e                	sd	s11,8(sp)
    80004596:	1880                	addi	s0,sp,112
    80004598:	8baa                	mv	s7,a0
    8000459a:	8c2e                	mv	s8,a1
    8000459c:	8ab2                	mv	s5,a2
    8000459e:	84b6                	mv	s1,a3
    800045a0:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800045a2:	9f35                	addw	a4,a4,a3
    return 0;
    800045a4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800045a6:	0ad76063          	bltu	a4,a3,80004646 <readi+0xd2>
  if(off + n > ip->size)
    800045aa:	00e7f463          	bgeu	a5,a4,800045b2 <readi+0x3e>
    n = ip->size - off;
    800045ae:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045b2:	0a0b0963          	beqz	s6,80004664 <readi+0xf0>
    800045b6:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800045b8:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800045bc:	5cfd                	li	s9,-1
    800045be:	a82d                	j	800045f8 <readi+0x84>
    800045c0:	020a1d93          	slli	s11,s4,0x20
    800045c4:	020ddd93          	srli	s11,s11,0x20
    800045c8:	05890793          	addi	a5,s2,88
    800045cc:	86ee                	mv	a3,s11
    800045ce:	963e                	add	a2,a2,a5
    800045d0:	85d6                	mv	a1,s5
    800045d2:	8562                	mv	a0,s8
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	b0e080e7          	jalr	-1266(ra) # 800030e2 <either_copyout>
    800045dc:	05950d63          	beq	a0,s9,80004636 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800045e0:	854a                	mv	a0,s2
    800045e2:	fffff097          	auipc	ra,0xfffff
    800045e6:	60a080e7          	jalr	1546(ra) # 80003bec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045ea:	013a09bb          	addw	s3,s4,s3
    800045ee:	009a04bb          	addw	s1,s4,s1
    800045f2:	9aee                	add	s5,s5,s11
    800045f4:	0569f763          	bgeu	s3,s6,80004642 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800045f8:	000ba903          	lw	s2,0(s7)
    800045fc:	00a4d59b          	srliw	a1,s1,0xa
    80004600:	855e                	mv	a0,s7
    80004602:	00000097          	auipc	ra,0x0
    80004606:	8ae080e7          	jalr	-1874(ra) # 80003eb0 <bmap>
    8000460a:	0005059b          	sext.w	a1,a0
    8000460e:	854a                	mv	a0,s2
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	4ac080e7          	jalr	1196(ra) # 80003abc <bread>
    80004618:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000461a:	3ff4f613          	andi	a2,s1,1023
    8000461e:	40cd07bb          	subw	a5,s10,a2
    80004622:	413b073b          	subw	a4,s6,s3
    80004626:	8a3e                	mv	s4,a5
    80004628:	2781                	sext.w	a5,a5
    8000462a:	0007069b          	sext.w	a3,a4
    8000462e:	f8f6f9e3          	bgeu	a3,a5,800045c0 <readi+0x4c>
    80004632:	8a3a                	mv	s4,a4
    80004634:	b771                	j	800045c0 <readi+0x4c>
      brelse(bp);
    80004636:	854a                	mv	a0,s2
    80004638:	fffff097          	auipc	ra,0xfffff
    8000463c:	5b4080e7          	jalr	1460(ra) # 80003bec <brelse>
      tot = -1;
    80004640:	59fd                	li	s3,-1
  }
  return tot;
    80004642:	0009851b          	sext.w	a0,s3
}
    80004646:	70a6                	ld	ra,104(sp)
    80004648:	7406                	ld	s0,96(sp)
    8000464a:	64e6                	ld	s1,88(sp)
    8000464c:	6946                	ld	s2,80(sp)
    8000464e:	69a6                	ld	s3,72(sp)
    80004650:	6a06                	ld	s4,64(sp)
    80004652:	7ae2                	ld	s5,56(sp)
    80004654:	7b42                	ld	s6,48(sp)
    80004656:	7ba2                	ld	s7,40(sp)
    80004658:	7c02                	ld	s8,32(sp)
    8000465a:	6ce2                	ld	s9,24(sp)
    8000465c:	6d42                	ld	s10,16(sp)
    8000465e:	6da2                	ld	s11,8(sp)
    80004660:	6165                	addi	sp,sp,112
    80004662:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004664:	89da                	mv	s3,s6
    80004666:	bff1                	j	80004642 <readi+0xce>
    return 0;
    80004668:	4501                	li	a0,0
}
    8000466a:	8082                	ret

000000008000466c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off){
    8000466c:	457c                	lw	a5,76(a0)
    8000466e:	10d7e863          	bltu	a5,a3,8000477e <writei+0x112>
{
    80004672:	7159                	addi	sp,sp,-112
    80004674:	f486                	sd	ra,104(sp)
    80004676:	f0a2                	sd	s0,96(sp)
    80004678:	eca6                	sd	s1,88(sp)
    8000467a:	e8ca                	sd	s2,80(sp)
    8000467c:	e4ce                	sd	s3,72(sp)
    8000467e:	e0d2                	sd	s4,64(sp)
    80004680:	fc56                	sd	s5,56(sp)
    80004682:	f85a                	sd	s6,48(sp)
    80004684:	f45e                	sd	s7,40(sp)
    80004686:	f062                	sd	s8,32(sp)
    80004688:	ec66                	sd	s9,24(sp)
    8000468a:	e86a                	sd	s10,16(sp)
    8000468c:	e46e                	sd	s11,8(sp)
    8000468e:	1880                	addi	s0,sp,112
    80004690:	8b2a                	mv	s6,a0
    80004692:	8c2e                	mv	s8,a1
    80004694:	8ab2                	mv	s5,a2
    80004696:	8936                	mv	s2,a3
    80004698:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off){
    8000469a:	00e687bb          	addw	a5,a3,a4
    8000469e:	0ed7e263          	bltu	a5,a3,80004782 <writei+0x116>
    return -1;
  }
  if(off + n > MAXFILE*BSIZE){
    800046a2:	00043737          	lui	a4,0x43
    800046a6:	0ef76063          	bltu	a4,a5,80004786 <writei+0x11a>
    return -1;
  }

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046aa:	0c0b8863          	beqz	s7,8000477a <writei+0x10e>
    800046ae:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800046b0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800046b4:	5cfd                	li	s9,-1
    800046b6:	a091                	j	800046fa <writei+0x8e>
    800046b8:	02099d93          	slli	s11,s3,0x20
    800046bc:	020ddd93          	srli	s11,s11,0x20
    800046c0:	05848793          	addi	a5,s1,88
    800046c4:	86ee                	mv	a3,s11
    800046c6:	8656                	mv	a2,s5
    800046c8:	85e2                	mv	a1,s8
    800046ca:	953e                	add	a0,a0,a5
    800046cc:	fffff097          	auipc	ra,0xfffff
    800046d0:	a6c080e7          	jalr	-1428(ra) # 80003138 <either_copyin>
    800046d4:	07950263          	beq	a0,s9,80004738 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800046d8:	8526                	mv	a0,s1
    800046da:	00001097          	auipc	ra,0x1
    800046de:	aa6080e7          	jalr	-1370(ra) # 80005180 <log_write>
    brelse(bp);
    800046e2:	8526                	mv	a0,s1
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	508080e7          	jalr	1288(ra) # 80003bec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800046ec:	01498a3b          	addw	s4,s3,s4
    800046f0:	0129893b          	addw	s2,s3,s2
    800046f4:	9aee                	add	s5,s5,s11
    800046f6:	057a7663          	bgeu	s4,s7,80004742 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800046fa:	000b2483          	lw	s1,0(s6)
    800046fe:	00a9559b          	srliw	a1,s2,0xa
    80004702:	855a                	mv	a0,s6
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	7ac080e7          	jalr	1964(ra) # 80003eb0 <bmap>
    8000470c:	0005059b          	sext.w	a1,a0
    80004710:	8526                	mv	a0,s1
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	3aa080e7          	jalr	938(ra) # 80003abc <bread>
    8000471a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000471c:	3ff97513          	andi	a0,s2,1023
    80004720:	40ad07bb          	subw	a5,s10,a0
    80004724:	414b873b          	subw	a4,s7,s4
    80004728:	89be                	mv	s3,a5
    8000472a:	2781                	sext.w	a5,a5
    8000472c:	0007069b          	sext.w	a3,a4
    80004730:	f8f6f4e3          	bgeu	a3,a5,800046b8 <writei+0x4c>
    80004734:	89ba                	mv	s3,a4
    80004736:	b749                	j	800046b8 <writei+0x4c>
      brelse(bp);
    80004738:	8526                	mv	a0,s1
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	4b2080e7          	jalr	1202(ra) # 80003bec <brelse>
  }

  if(off > ip->size)
    80004742:	04cb2783          	lw	a5,76(s6)
    80004746:	0127f463          	bgeu	a5,s2,8000474e <writei+0xe2>
    ip->size = off;
    8000474a:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000474e:	855a                	mv	a0,s6
    80004750:	00000097          	auipc	ra,0x0
    80004754:	aa6080e7          	jalr	-1370(ra) # 800041f6 <iupdate>

  return tot;
    80004758:	000a051b          	sext.w	a0,s4
}
    8000475c:	70a6                	ld	ra,104(sp)
    8000475e:	7406                	ld	s0,96(sp)
    80004760:	64e6                	ld	s1,88(sp)
    80004762:	6946                	ld	s2,80(sp)
    80004764:	69a6                	ld	s3,72(sp)
    80004766:	6a06                	ld	s4,64(sp)
    80004768:	7ae2                	ld	s5,56(sp)
    8000476a:	7b42                	ld	s6,48(sp)
    8000476c:	7ba2                	ld	s7,40(sp)
    8000476e:	7c02                	ld	s8,32(sp)
    80004770:	6ce2                	ld	s9,24(sp)
    80004772:	6d42                	ld	s10,16(sp)
    80004774:	6da2                	ld	s11,8(sp)
    80004776:	6165                	addi	sp,sp,112
    80004778:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000477a:	8a5e                	mv	s4,s7
    8000477c:	bfc9                	j	8000474e <writei+0xe2>
    return -1;
    8000477e:	557d                	li	a0,-1
}
    80004780:	8082                	ret
    return -1;
    80004782:	557d                	li	a0,-1
    80004784:	bfe1                	j	8000475c <writei+0xf0>
    return -1;
    80004786:	557d                	li	a0,-1
    80004788:	bfd1                	j	8000475c <writei+0xf0>

000000008000478a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000478a:	1141                	addi	sp,sp,-16
    8000478c:	e406                	sd	ra,8(sp)
    8000478e:	e022                	sd	s0,0(sp)
    80004790:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004792:	4639                	li	a2,14
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	612080e7          	jalr	1554(ra) # 80000da6 <strncmp>
}
    8000479c:	60a2                	ld	ra,8(sp)
    8000479e:	6402                	ld	s0,0(sp)
    800047a0:	0141                	addi	sp,sp,16
    800047a2:	8082                	ret

00000000800047a4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800047a4:	7139                	addi	sp,sp,-64
    800047a6:	fc06                	sd	ra,56(sp)
    800047a8:	f822                	sd	s0,48(sp)
    800047aa:	f426                	sd	s1,40(sp)
    800047ac:	f04a                	sd	s2,32(sp)
    800047ae:	ec4e                	sd	s3,24(sp)
    800047b0:	e852                	sd	s4,16(sp)
    800047b2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800047b4:	04451703          	lh	a4,68(a0)
    800047b8:	4785                	li	a5,1
    800047ba:	00f71a63          	bne	a4,a5,800047ce <dirlookup+0x2a>
    800047be:	892a                	mv	s2,a0
    800047c0:	89ae                	mv	s3,a1
    800047c2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800047c4:	457c                	lw	a5,76(a0)
    800047c6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800047c8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ca:	e79d                	bnez	a5,800047f8 <dirlookup+0x54>
    800047cc:	a8a5                	j	80004844 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800047ce:	00005517          	auipc	a0,0x5
    800047d2:	fca50513          	addi	a0,a0,-54 # 80009798 <syscalls+0x1a0>
    800047d6:	ffffc097          	auipc	ra,0xffffc
    800047da:	d54080e7          	jalr	-684(ra) # 8000052a <panic>
      panic("dirlookup read");
    800047de:	00005517          	auipc	a0,0x5
    800047e2:	fd250513          	addi	a0,a0,-46 # 800097b0 <syscalls+0x1b8>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	d44080e7          	jalr	-700(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800047ee:	24c1                	addiw	s1,s1,16
    800047f0:	04c92783          	lw	a5,76(s2)
    800047f4:	04f4f763          	bgeu	s1,a5,80004842 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800047f8:	4741                	li	a4,16
    800047fa:	86a6                	mv	a3,s1
    800047fc:	fc040613          	addi	a2,s0,-64
    80004800:	4581                	li	a1,0
    80004802:	854a                	mv	a0,s2
    80004804:	00000097          	auipc	ra,0x0
    80004808:	d70080e7          	jalr	-656(ra) # 80004574 <readi>
    8000480c:	47c1                	li	a5,16
    8000480e:	fcf518e3          	bne	a0,a5,800047de <dirlookup+0x3a>
    if(de.inum == 0)
    80004812:	fc045783          	lhu	a5,-64(s0)
    80004816:	dfe1                	beqz	a5,800047ee <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004818:	fc240593          	addi	a1,s0,-62
    8000481c:	854e                	mv	a0,s3
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	f6c080e7          	jalr	-148(ra) # 8000478a <namecmp>
    80004826:	f561                	bnez	a0,800047ee <dirlookup+0x4a>
      if(poff)
    80004828:	000a0463          	beqz	s4,80004830 <dirlookup+0x8c>
        *poff = off;
    8000482c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004830:	fc045583          	lhu	a1,-64(s0)
    80004834:	00092503          	lw	a0,0(s2)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	754080e7          	jalr	1876(ra) # 80003f8c <iget>
    80004840:	a011                	j	80004844 <dirlookup+0xa0>
  return 0;
    80004842:	4501                	li	a0,0
}
    80004844:	70e2                	ld	ra,56(sp)
    80004846:	7442                	ld	s0,48(sp)
    80004848:	74a2                	ld	s1,40(sp)
    8000484a:	7902                	ld	s2,32(sp)
    8000484c:	69e2                	ld	s3,24(sp)
    8000484e:	6a42                	ld	s4,16(sp)
    80004850:	6121                	addi	sp,sp,64
    80004852:	8082                	ret

0000000080004854 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004854:	711d                	addi	sp,sp,-96
    80004856:	ec86                	sd	ra,88(sp)
    80004858:	e8a2                	sd	s0,80(sp)
    8000485a:	e4a6                	sd	s1,72(sp)
    8000485c:	e0ca                	sd	s2,64(sp)
    8000485e:	fc4e                	sd	s3,56(sp)
    80004860:	f852                	sd	s4,48(sp)
    80004862:	f456                	sd	s5,40(sp)
    80004864:	f05a                	sd	s6,32(sp)
    80004866:	ec5e                	sd	s7,24(sp)
    80004868:	e862                	sd	s8,16(sp)
    8000486a:	e466                	sd	s9,8(sp)
    8000486c:	1080                	addi	s0,sp,96
    8000486e:	84aa                	mv	s1,a0
    80004870:	8aae                	mv	s5,a1
    80004872:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004874:	00054703          	lbu	a4,0(a0)
    80004878:	02f00793          	li	a5,47
    8000487c:	02f70363          	beq	a4,a5,800048a2 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004880:	ffffe097          	auipc	ra,0xffffe
    80004884:	b82080e7          	jalr	-1150(ra) # 80002402 <myproc>
    80004888:	15053503          	ld	a0,336(a0)
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	9f6080e7          	jalr	-1546(ra) # 80004282 <idup>
    80004894:	89aa                	mv	s3,a0
  while(*path == '/')
    80004896:	02f00913          	li	s2,47
  len = path - s;
    8000489a:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    8000489c:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000489e:	4b85                	li	s7,1
    800048a0:	a865                	j	80004958 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800048a2:	4585                	li	a1,1
    800048a4:	4505                	li	a0,1
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	6e6080e7          	jalr	1766(ra) # 80003f8c <iget>
    800048ae:	89aa                	mv	s3,a0
    800048b0:	b7dd                	j	80004896 <namex+0x42>
      iunlockput(ip);
    800048b2:	854e                	mv	a0,s3
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	c6e080e7          	jalr	-914(ra) # 80004522 <iunlockput>
      return 0;
    800048bc:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800048be:	854e                	mv	a0,s3
    800048c0:	60e6                	ld	ra,88(sp)
    800048c2:	6446                	ld	s0,80(sp)
    800048c4:	64a6                	ld	s1,72(sp)
    800048c6:	6906                	ld	s2,64(sp)
    800048c8:	79e2                	ld	s3,56(sp)
    800048ca:	7a42                	ld	s4,48(sp)
    800048cc:	7aa2                	ld	s5,40(sp)
    800048ce:	7b02                	ld	s6,32(sp)
    800048d0:	6be2                	ld	s7,24(sp)
    800048d2:	6c42                	ld	s8,16(sp)
    800048d4:	6ca2                	ld	s9,8(sp)
    800048d6:	6125                	addi	sp,sp,96
    800048d8:	8082                	ret
      iunlock(ip);
    800048da:	854e                	mv	a0,s3
    800048dc:	00000097          	auipc	ra,0x0
    800048e0:	aa6080e7          	jalr	-1370(ra) # 80004382 <iunlock>
      return ip;
    800048e4:	bfe9                	j	800048be <namex+0x6a>
      iunlockput(ip);
    800048e6:	854e                	mv	a0,s3
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	c3a080e7          	jalr	-966(ra) # 80004522 <iunlockput>
      return 0;
    800048f0:	89e6                	mv	s3,s9
    800048f2:	b7f1                	j	800048be <namex+0x6a>
  len = path - s;
    800048f4:	40b48633          	sub	a2,s1,a1
    800048f8:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800048fc:	099c5463          	bge	s8,s9,80004984 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004900:	4639                	li	a2,14
    80004902:	8552                	mv	a0,s4
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	426080e7          	jalr	1062(ra) # 80000d2a <memmove>
  while(*path == '/')
    8000490c:	0004c783          	lbu	a5,0(s1)
    80004910:	01279763          	bne	a5,s2,8000491e <namex+0xca>
    path++;
    80004914:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004916:	0004c783          	lbu	a5,0(s1)
    8000491a:	ff278de3          	beq	a5,s2,80004914 <namex+0xc0>
    ilock(ip);
    8000491e:	854e                	mv	a0,s3
    80004920:	00000097          	auipc	ra,0x0
    80004924:	9a0080e7          	jalr	-1632(ra) # 800042c0 <ilock>
    if(ip->type != T_DIR){
    80004928:	04499783          	lh	a5,68(s3)
    8000492c:	f97793e3          	bne	a5,s7,800048b2 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004930:	000a8563          	beqz	s5,8000493a <namex+0xe6>
    80004934:	0004c783          	lbu	a5,0(s1)
    80004938:	d3cd                	beqz	a5,800048da <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000493a:	865a                	mv	a2,s6
    8000493c:	85d2                	mv	a1,s4
    8000493e:	854e                	mv	a0,s3
    80004940:	00000097          	auipc	ra,0x0
    80004944:	e64080e7          	jalr	-412(ra) # 800047a4 <dirlookup>
    80004948:	8caa                	mv	s9,a0
    8000494a:	dd51                	beqz	a0,800048e6 <namex+0x92>
    iunlockput(ip);
    8000494c:	854e                	mv	a0,s3
    8000494e:	00000097          	auipc	ra,0x0
    80004952:	bd4080e7          	jalr	-1068(ra) # 80004522 <iunlockput>
    ip = next;
    80004956:	89e6                	mv	s3,s9
  while(*path == '/')
    80004958:	0004c783          	lbu	a5,0(s1)
    8000495c:	05279763          	bne	a5,s2,800049aa <namex+0x156>
    path++;
    80004960:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004962:	0004c783          	lbu	a5,0(s1)
    80004966:	ff278de3          	beq	a5,s2,80004960 <namex+0x10c>
  if(*path == 0)
    8000496a:	c79d                	beqz	a5,80004998 <namex+0x144>
    path++;
    8000496c:	85a6                	mv	a1,s1
  len = path - s;
    8000496e:	8cda                	mv	s9,s6
    80004970:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004972:	01278963          	beq	a5,s2,80004984 <namex+0x130>
    80004976:	dfbd                	beqz	a5,800048f4 <namex+0xa0>
    path++;
    80004978:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000497a:	0004c783          	lbu	a5,0(s1)
    8000497e:	ff279ce3          	bne	a5,s2,80004976 <namex+0x122>
    80004982:	bf8d                	j	800048f4 <namex+0xa0>
    memmove(name, s, len);
    80004984:	2601                	sext.w	a2,a2
    80004986:	8552                	mv	a0,s4
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	3a2080e7          	jalr	930(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004990:	9cd2                	add	s9,s9,s4
    80004992:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004996:	bf9d                	j	8000490c <namex+0xb8>
  if(nameiparent){
    80004998:	f20a83e3          	beqz	s5,800048be <namex+0x6a>
    iput(ip);
    8000499c:	854e                	mv	a0,s3
    8000499e:	00000097          	auipc	ra,0x0
    800049a2:	adc080e7          	jalr	-1316(ra) # 8000447a <iput>
    return 0;
    800049a6:	4981                	li	s3,0
    800049a8:	bf19                	j	800048be <namex+0x6a>
  if(*path == 0)
    800049aa:	d7fd                	beqz	a5,80004998 <namex+0x144>
  while(*path != '/' && *path != 0)
    800049ac:	0004c783          	lbu	a5,0(s1)
    800049b0:	85a6                	mv	a1,s1
    800049b2:	b7d1                	j	80004976 <namex+0x122>

00000000800049b4 <dirlink>:
{
    800049b4:	7139                	addi	sp,sp,-64
    800049b6:	fc06                	sd	ra,56(sp)
    800049b8:	f822                	sd	s0,48(sp)
    800049ba:	f426                	sd	s1,40(sp)
    800049bc:	f04a                	sd	s2,32(sp)
    800049be:	ec4e                	sd	s3,24(sp)
    800049c0:	e852                	sd	s4,16(sp)
    800049c2:	0080                	addi	s0,sp,64
    800049c4:	892a                	mv	s2,a0
    800049c6:	8a2e                	mv	s4,a1
    800049c8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800049ca:	4601                	li	a2,0
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	dd8080e7          	jalr	-552(ra) # 800047a4 <dirlookup>
    800049d4:	e93d                	bnez	a0,80004a4a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049d6:	04c92483          	lw	s1,76(s2)
    800049da:	c49d                	beqz	s1,80004a08 <dirlink+0x54>
    800049dc:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049de:	4741                	li	a4,16
    800049e0:	86a6                	mv	a3,s1
    800049e2:	fc040613          	addi	a2,s0,-64
    800049e6:	4581                	li	a1,0
    800049e8:	854a                	mv	a0,s2
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	b8a080e7          	jalr	-1142(ra) # 80004574 <readi>
    800049f2:	47c1                	li	a5,16
    800049f4:	06f51163          	bne	a0,a5,80004a56 <dirlink+0xa2>
    if(de.inum == 0)
    800049f8:	fc045783          	lhu	a5,-64(s0)
    800049fc:	c791                	beqz	a5,80004a08 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800049fe:	24c1                	addiw	s1,s1,16
    80004a00:	04c92783          	lw	a5,76(s2)
    80004a04:	fcf4ede3          	bltu	s1,a5,800049de <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a08:	4639                	li	a2,14
    80004a0a:	85d2                	mv	a1,s4
    80004a0c:	fc240513          	addi	a0,s0,-62
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	3d2080e7          	jalr	978(ra) # 80000de2 <strncpy>
  de.inum = inum;
    80004a18:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a1c:	4741                	li	a4,16
    80004a1e:	86a6                	mv	a3,s1
    80004a20:	fc040613          	addi	a2,s0,-64
    80004a24:	4581                	li	a1,0
    80004a26:	854a                	mv	a0,s2
    80004a28:	00000097          	auipc	ra,0x0
    80004a2c:	c44080e7          	jalr	-956(ra) # 8000466c <writei>
    80004a30:	872a                	mv	a4,a0
    80004a32:	47c1                	li	a5,16
  return 0;
    80004a34:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a36:	02f71863          	bne	a4,a5,80004a66 <dirlink+0xb2>
}
    80004a3a:	70e2                	ld	ra,56(sp)
    80004a3c:	7442                	ld	s0,48(sp)
    80004a3e:	74a2                	ld	s1,40(sp)
    80004a40:	7902                	ld	s2,32(sp)
    80004a42:	69e2                	ld	s3,24(sp)
    80004a44:	6a42                	ld	s4,16(sp)
    80004a46:	6121                	addi	sp,sp,64
    80004a48:	8082                	ret
    iput(ip);
    80004a4a:	00000097          	auipc	ra,0x0
    80004a4e:	a30080e7          	jalr	-1488(ra) # 8000447a <iput>
    return -1;
    80004a52:	557d                	li	a0,-1
    80004a54:	b7dd                	j	80004a3a <dirlink+0x86>
      panic("dirlink read");
    80004a56:	00005517          	auipc	a0,0x5
    80004a5a:	d6a50513          	addi	a0,a0,-662 # 800097c0 <syscalls+0x1c8>
    80004a5e:	ffffc097          	auipc	ra,0xffffc
    80004a62:	acc080e7          	jalr	-1332(ra) # 8000052a <panic>
    panic("dirlink");
    80004a66:	00005517          	auipc	a0,0x5
    80004a6a:	ee250513          	addi	a0,a0,-286 # 80009948 <syscalls+0x350>
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	abc080e7          	jalr	-1348(ra) # 8000052a <panic>

0000000080004a76 <namei>:

struct inode*
namei(char *path)
{
    80004a76:	1101                	addi	sp,sp,-32
    80004a78:	ec06                	sd	ra,24(sp)
    80004a7a:	e822                	sd	s0,16(sp)
    80004a7c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004a7e:	fe040613          	addi	a2,s0,-32
    80004a82:	4581                	li	a1,0
    80004a84:	00000097          	auipc	ra,0x0
    80004a88:	dd0080e7          	jalr	-560(ra) # 80004854 <namex>
}
    80004a8c:	60e2                	ld	ra,24(sp)
    80004a8e:	6442                	ld	s0,16(sp)
    80004a90:	6105                	addi	sp,sp,32
    80004a92:	8082                	ret

0000000080004a94 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a94:	1141                	addi	sp,sp,-16
    80004a96:	e406                	sd	ra,8(sp)
    80004a98:	e022                	sd	s0,0(sp)
    80004a9a:	0800                	addi	s0,sp,16
    80004a9c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a9e:	4585                	li	a1,1
    80004aa0:	00000097          	auipc	ra,0x0
    80004aa4:	db4080e7          	jalr	-588(ra) # 80004854 <namex>
}
    80004aa8:	60a2                	ld	ra,8(sp)
    80004aaa:	6402                	ld	s0,0(sp)
    80004aac:	0141                	addi	sp,sp,16
    80004aae:	8082                	ret

0000000080004ab0 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004ab0:	1101                	addi	sp,sp,-32
    80004ab2:	ec22                	sd	s0,24(sp)
    80004ab4:	1000                	addi	s0,sp,32
    80004ab6:	872a                	mv	a4,a0
    80004ab8:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    80004aba:	00005797          	auipc	a5,0x5
    80004abe:	d1678793          	addi	a5,a5,-746 # 800097d0 <syscalls+0x1d8>
    80004ac2:	6394                	ld	a3,0(a5)
    80004ac4:	fed43023          	sd	a3,-32(s0)
    80004ac8:	0087d683          	lhu	a3,8(a5)
    80004acc:	fed41423          	sh	a3,-24(s0)
    80004ad0:	00a7c783          	lbu	a5,10(a5)
    80004ad4:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004ad8:	87ae                	mv	a5,a1
    if(i<0){
    80004ada:	02074b63          	bltz	a4,80004b10 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    80004ade:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004ae0:	4629                	li	a2,10
        ++p;
    80004ae2:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004ae4:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004ae8:	feed                	bnez	a3,80004ae2 <itoa+0x32>
    *p = '\0';
    80004aea:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    80004aee:	4629                	li	a2,10
    80004af0:	17fd                	addi	a5,a5,-1
    80004af2:	02c766bb          	remw	a3,a4,a2
    80004af6:	ff040593          	addi	a1,s0,-16
    80004afa:	96ae                	add	a3,a3,a1
    80004afc:	ff06c683          	lbu	a3,-16(a3)
    80004b00:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004b04:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004b08:	f765                	bnez	a4,80004af0 <itoa+0x40>
    return b;
}
    80004b0a:	6462                	ld	s0,24(sp)
    80004b0c:	6105                	addi	sp,sp,32
    80004b0e:	8082                	ret
        *p++ = '-';
    80004b10:	00158793          	addi	a5,a1,1
    80004b14:	02d00693          	li	a3,45
    80004b18:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004b1c:	40e0073b          	negw	a4,a4
    80004b20:	bf7d                	j	80004ade <itoa+0x2e>

0000000080004b22 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004b22:	711d                	addi	sp,sp,-96
    80004b24:	ec86                	sd	ra,88(sp)
    80004b26:	e8a2                	sd	s0,80(sp)
    80004b28:	e4a6                	sd	s1,72(sp)
    80004b2a:	e0ca                	sd	s2,64(sp)
    80004b2c:	1080                	addi	s0,sp,96
    80004b2e:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004b30:	4619                	li	a2,6
    80004b32:	00005597          	auipc	a1,0x5
    80004b36:	cae58593          	addi	a1,a1,-850 # 800097e0 <syscalls+0x1e8>
    80004b3a:	fd040513          	addi	a0,s0,-48
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	1ec080e7          	jalr	492(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004b46:	fd640593          	addi	a1,s0,-42
    80004b4a:	5888                	lw	a0,48(s1)
    80004b4c:	00000097          	auipc	ra,0x0
    80004b50:	f64080e7          	jalr	-156(ra) # 80004ab0 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004b54:	1684b503          	ld	a0,360(s1)
    80004b58:	16050763          	beqz	a0,80004cc6 <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004b5c:	00001097          	auipc	ra,0x1
    80004b60:	918080e7          	jalr	-1768(ra) # 80005474 <fileclose>

  begin_op();
    80004b64:	00000097          	auipc	ra,0x0
    80004b68:	444080e7          	jalr	1092(ra) # 80004fa8 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004b6c:	fb040593          	addi	a1,s0,-80
    80004b70:	fd040513          	addi	a0,s0,-48
    80004b74:	00000097          	auipc	ra,0x0
    80004b78:	f20080e7          	jalr	-224(ra) # 80004a94 <nameiparent>
    80004b7c:	892a                	mv	s2,a0
    80004b7e:	cd69                	beqz	a0,80004c58 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004b80:	fffff097          	auipc	ra,0xfffff
    80004b84:	740080e7          	jalr	1856(ra) # 800042c0 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004b88:	00005597          	auipc	a1,0x5
    80004b8c:	c6058593          	addi	a1,a1,-928 # 800097e8 <syscalls+0x1f0>
    80004b90:	fb040513          	addi	a0,s0,-80
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	bf6080e7          	jalr	-1034(ra) # 8000478a <namecmp>
    80004b9c:	c57d                	beqz	a0,80004c8a <removeSwapFile+0x168>
    80004b9e:	00005597          	auipc	a1,0x5
    80004ba2:	c5258593          	addi	a1,a1,-942 # 800097f0 <syscalls+0x1f8>
    80004ba6:	fb040513          	addi	a0,s0,-80
    80004baa:	00000097          	auipc	ra,0x0
    80004bae:	be0080e7          	jalr	-1056(ra) # 8000478a <namecmp>
    80004bb2:	cd61                	beqz	a0,80004c8a <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004bb4:	fac40613          	addi	a2,s0,-84
    80004bb8:	fb040593          	addi	a1,s0,-80
    80004bbc:	854a                	mv	a0,s2
    80004bbe:	00000097          	auipc	ra,0x0
    80004bc2:	be6080e7          	jalr	-1050(ra) # 800047a4 <dirlookup>
    80004bc6:	84aa                	mv	s1,a0
    80004bc8:	c169                	beqz	a0,80004c8a <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004bca:	fffff097          	auipc	ra,0xfffff
    80004bce:	6f6080e7          	jalr	1782(ra) # 800042c0 <ilock>

  if(ip->nlink < 1)
    80004bd2:	04a49783          	lh	a5,74(s1)
    80004bd6:	08f05763          	blez	a5,80004c64 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004bda:	04449703          	lh	a4,68(s1)
    80004bde:	4785                	li	a5,1
    80004be0:	08f70a63          	beq	a4,a5,80004c74 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004be4:	4641                	li	a2,16
    80004be6:	4581                	li	a1,0
    80004be8:	fc040513          	addi	a0,s0,-64
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	0e2080e7          	jalr	226(ra) # 80000cce <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004bf4:	4741                	li	a4,16
    80004bf6:	fac42683          	lw	a3,-84(s0)
    80004bfa:	fc040613          	addi	a2,s0,-64
    80004bfe:	4581                	li	a1,0
    80004c00:	854a                	mv	a0,s2
    80004c02:	00000097          	auipc	ra,0x0
    80004c06:	a6a080e7          	jalr	-1430(ra) # 8000466c <writei>
    80004c0a:	47c1                	li	a5,16
    80004c0c:	08f51a63          	bne	a0,a5,80004ca0 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004c10:	04449703          	lh	a4,68(s1)
    80004c14:	4785                	li	a5,1
    80004c16:	08f70d63          	beq	a4,a5,80004cb0 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004c1a:	854a                	mv	a0,s2
    80004c1c:	00000097          	auipc	ra,0x0
    80004c20:	906080e7          	jalr	-1786(ra) # 80004522 <iunlockput>

  ip->nlink--;
    80004c24:	04a4d783          	lhu	a5,74(s1)
    80004c28:	37fd                	addiw	a5,a5,-1
    80004c2a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	5c6080e7          	jalr	1478(ra) # 800041f6 <iupdate>
  iunlockput(ip);
    80004c38:	8526                	mv	a0,s1
    80004c3a:	00000097          	auipc	ra,0x0
    80004c3e:	8e8080e7          	jalr	-1816(ra) # 80004522 <iunlockput>

  end_op();
    80004c42:	00000097          	auipc	ra,0x0
    80004c46:	3e6080e7          	jalr	998(ra) # 80005028 <end_op>

  return 0;
    80004c4a:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004c4c:	60e6                	ld	ra,88(sp)
    80004c4e:	6446                	ld	s0,80(sp)
    80004c50:	64a6                	ld	s1,72(sp)
    80004c52:	6906                	ld	s2,64(sp)
    80004c54:	6125                	addi	sp,sp,96
    80004c56:	8082                	ret
    end_op();
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	3d0080e7          	jalr	976(ra) # 80005028 <end_op>
    return -1;
    80004c60:	557d                	li	a0,-1
    80004c62:	b7ed                	j	80004c4c <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004c64:	00005517          	auipc	a0,0x5
    80004c68:	b9450513          	addi	a0,a0,-1132 # 800097f8 <syscalls+0x200>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	8be080e7          	jalr	-1858(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004c74:	8526                	mv	a0,s1
    80004c76:	00001097          	auipc	ra,0x1
    80004c7a:	798080e7          	jalr	1944(ra) # 8000640e <isdirempty>
    80004c7e:	f13d                	bnez	a0,80004be4 <removeSwapFile+0xc2>
    iunlockput(ip);
    80004c80:	8526                	mv	a0,s1
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	8a0080e7          	jalr	-1888(ra) # 80004522 <iunlockput>
    iunlockput(dp);
    80004c8a:	854a                	mv	a0,s2
    80004c8c:	00000097          	auipc	ra,0x0
    80004c90:	896080e7          	jalr	-1898(ra) # 80004522 <iunlockput>
    end_op();
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	394080e7          	jalr	916(ra) # 80005028 <end_op>
    return -1;
    80004c9c:	557d                	li	a0,-1
    80004c9e:	b77d                	j	80004c4c <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004ca0:	00005517          	auipc	a0,0x5
    80004ca4:	b7050513          	addi	a0,a0,-1168 # 80009810 <syscalls+0x218>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	882080e7          	jalr	-1918(ra) # 8000052a <panic>
    dp->nlink--;
    80004cb0:	04a95783          	lhu	a5,74(s2)
    80004cb4:	37fd                	addiw	a5,a5,-1
    80004cb6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004cba:	854a                	mv	a0,s2
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	53a080e7          	jalr	1338(ra) # 800041f6 <iupdate>
    80004cc4:	bf99                	j	80004c1a <removeSwapFile+0xf8>
    return -1;
    80004cc6:	557d                	li	a0,-1
    80004cc8:	b751                	j	80004c4c <removeSwapFile+0x12a>

0000000080004cca <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004cca:	7179                	addi	sp,sp,-48
    80004ccc:	f406                	sd	ra,40(sp)
    80004cce:	f022                	sd	s0,32(sp)
    80004cd0:	ec26                	sd	s1,24(sp)
    80004cd2:	e84a                	sd	s2,16(sp)
    80004cd4:	1800                	addi	s0,sp,48
    80004cd6:	84aa                	mv	s1,a0
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004cd8:	4619                	li	a2,6
    80004cda:	00005597          	auipc	a1,0x5
    80004cde:	b0658593          	addi	a1,a1,-1274 # 800097e0 <syscalls+0x1e8>
    80004ce2:	fd040513          	addi	a0,s0,-48
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	044080e7          	jalr	68(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004cee:	fd640593          	addi	a1,s0,-42
    80004cf2:	5888                	lw	a0,48(s1)
    80004cf4:	00000097          	auipc	ra,0x0
    80004cf8:	dbc080e7          	jalr	-580(ra) # 80004ab0 <itoa>

  begin_op();
    80004cfc:	00000097          	auipc	ra,0x0
    80004d00:	2ac080e7          	jalr	684(ra) # 80004fa8 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004d04:	4681                	li	a3,0
    80004d06:	4601                	li	a2,0
    80004d08:	4589                	li	a1,2
    80004d0a:	fd040513          	addi	a0,s0,-48
    80004d0e:	00002097          	auipc	ra,0x2
    80004d12:	8f4080e7          	jalr	-1804(ra) # 80006602 <create>
    80004d16:	892a                	mv	s2,a0
  iunlock(in);
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	66a080e7          	jalr	1642(ra) # 80004382 <iunlock>
  p->swapFile = filealloc();
    80004d20:	00000097          	auipc	ra,0x0
    80004d24:	698080e7          	jalr	1688(ra) # 800053b8 <filealloc>
    80004d28:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004d2c:	cd1d                	beqz	a0,80004d6a <createSwapFile+0xa0>
    panic("no slot for files on /store");
  p->swapFile->ip = in;
    80004d2e:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004d32:	1684b703          	ld	a4,360(s1)
    80004d36:	4789                	li	a5,2
    80004d38:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004d3a:	1684b703          	ld	a4,360(s1)
    80004d3e:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004d42:	1684b703          	ld	a4,360(s1)
    80004d46:	4685                	li	a3,1
    80004d48:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004d4c:	1684b703          	ld	a4,360(s1)
    80004d50:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004d54:	00000097          	auipc	ra,0x0
    80004d58:	2d4080e7          	jalr	724(ra) # 80005028 <end_op>
  return 0;
}
    80004d5c:	4501                	li	a0,0
    80004d5e:	70a2                	ld	ra,40(sp)
    80004d60:	7402                	ld	s0,32(sp)
    80004d62:	64e2                	ld	s1,24(sp)
    80004d64:	6942                	ld	s2,16(sp)
    80004d66:	6145                	addi	sp,sp,48
    80004d68:	8082                	ret
    panic("no slot for files on /store");
    80004d6a:	00005517          	auipc	a0,0x5
    80004d6e:	ab650513          	addi	a0,a0,-1354 # 80009820 <syscalls+0x228>
    80004d72:	ffffb097          	auipc	ra,0xffffb
    80004d76:	7b8080e7          	jalr	1976(ra) # 8000052a <panic>

0000000080004d7a <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004d7a:	1141                	addi	sp,sp,-16
    80004d7c:	e406                	sd	ra,8(sp)
    80004d7e:	e022                	sd	s0,0(sp)
    80004d80:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004d82:	16853783          	ld	a5,360(a0)
    80004d86:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004d88:	8636                	mv	a2,a3
    80004d8a:	16853503          	ld	a0,360(a0)
    80004d8e:	00001097          	auipc	ra,0x1
    80004d92:	ad8080e7          	jalr	-1320(ra) # 80005866 <kfilewrite>
}
    80004d96:	60a2                	ld	ra,8(sp)
    80004d98:	6402                	ld	s0,0(sp)
    80004d9a:	0141                	addi	sp,sp,16
    80004d9c:	8082                	ret

0000000080004d9e <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004d9e:	1141                	addi	sp,sp,-16
    80004da0:	e406                	sd	ra,8(sp)
    80004da2:	e022                	sd	s0,0(sp)
    80004da4:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004da6:	16853783          	ld	a5,360(a0)
    80004daa:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004dac:	8636                	mv	a2,a3
    80004dae:	16853503          	ld	a0,360(a0)
    80004db2:	00001097          	auipc	ra,0x1
    80004db6:	9f2080e7          	jalr	-1550(ra) # 800057a4 <kfileread>
    80004dba:	60a2                	ld	ra,8(sp)
    80004dbc:	6402                	ld	s0,0(sp)
    80004dbe:	0141                	addi	sp,sp,16
    80004dc0:	8082                	ret

0000000080004dc2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004dc2:	1101                	addi	sp,sp,-32
    80004dc4:	ec06                	sd	ra,24(sp)
    80004dc6:	e822                	sd	s0,16(sp)
    80004dc8:	e426                	sd	s1,8(sp)
    80004dca:	e04a                	sd	s2,0(sp)
    80004dcc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004dce:	00026917          	auipc	s2,0x26
    80004dd2:	aa290913          	addi	s2,s2,-1374 # 8002a870 <log>
    80004dd6:	01892583          	lw	a1,24(s2)
    80004dda:	02892503          	lw	a0,40(s2)
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	cde080e7          	jalr	-802(ra) # 80003abc <bread>
    80004de6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004de8:	02c92683          	lw	a3,44(s2)
    80004dec:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004dee:	02d05863          	blez	a3,80004e1e <write_head+0x5c>
    80004df2:	00026797          	auipc	a5,0x26
    80004df6:	aae78793          	addi	a5,a5,-1362 # 8002a8a0 <log+0x30>
    80004dfa:	05c50713          	addi	a4,a0,92
    80004dfe:	36fd                	addiw	a3,a3,-1
    80004e00:	02069613          	slli	a2,a3,0x20
    80004e04:	01e65693          	srli	a3,a2,0x1e
    80004e08:	00026617          	auipc	a2,0x26
    80004e0c:	a9c60613          	addi	a2,a2,-1380 # 8002a8a4 <log+0x34>
    80004e10:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004e12:	4390                	lw	a2,0(a5)
    80004e14:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004e16:	0791                	addi	a5,a5,4
    80004e18:	0711                	addi	a4,a4,4
    80004e1a:	fed79ce3          	bne	a5,a3,80004e12 <write_head+0x50>
  }
  bwrite(buf);
    80004e1e:	8526                	mv	a0,s1
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	d8e080e7          	jalr	-626(ra) # 80003bae <bwrite>
  brelse(buf);
    80004e28:	8526                	mv	a0,s1
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	dc2080e7          	jalr	-574(ra) # 80003bec <brelse>
}
    80004e32:	60e2                	ld	ra,24(sp)
    80004e34:	6442                	ld	s0,16(sp)
    80004e36:	64a2                	ld	s1,8(sp)
    80004e38:	6902                	ld	s2,0(sp)
    80004e3a:	6105                	addi	sp,sp,32
    80004e3c:	8082                	ret

0000000080004e3e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e3e:	00026797          	auipc	a5,0x26
    80004e42:	a5e7a783          	lw	a5,-1442(a5) # 8002a89c <log+0x2c>
    80004e46:	0af05d63          	blez	a5,80004f00 <install_trans+0xc2>
{
    80004e4a:	7139                	addi	sp,sp,-64
    80004e4c:	fc06                	sd	ra,56(sp)
    80004e4e:	f822                	sd	s0,48(sp)
    80004e50:	f426                	sd	s1,40(sp)
    80004e52:	f04a                	sd	s2,32(sp)
    80004e54:	ec4e                	sd	s3,24(sp)
    80004e56:	e852                	sd	s4,16(sp)
    80004e58:	e456                	sd	s5,8(sp)
    80004e5a:	e05a                	sd	s6,0(sp)
    80004e5c:	0080                	addi	s0,sp,64
    80004e5e:	8b2a                	mv	s6,a0
    80004e60:	00026a97          	auipc	s5,0x26
    80004e64:	a40a8a93          	addi	s5,s5,-1472 # 8002a8a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e68:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004e6a:	00026997          	auipc	s3,0x26
    80004e6e:	a0698993          	addi	s3,s3,-1530 # 8002a870 <log>
    80004e72:	a00d                	j	80004e94 <install_trans+0x56>
    brelse(lbuf);
    80004e74:	854a                	mv	a0,s2
    80004e76:	fffff097          	auipc	ra,0xfffff
    80004e7a:	d76080e7          	jalr	-650(ra) # 80003bec <brelse>
    brelse(dbuf);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	fffff097          	auipc	ra,0xfffff
    80004e84:	d6c080e7          	jalr	-660(ra) # 80003bec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e88:	2a05                	addiw	s4,s4,1
    80004e8a:	0a91                	addi	s5,s5,4
    80004e8c:	02c9a783          	lw	a5,44(s3)
    80004e90:	04fa5e63          	bge	s4,a5,80004eec <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004e94:	0189a583          	lw	a1,24(s3)
    80004e98:	014585bb          	addw	a1,a1,s4
    80004e9c:	2585                	addiw	a1,a1,1
    80004e9e:	0289a503          	lw	a0,40(s3)
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	c1a080e7          	jalr	-998(ra) # 80003abc <bread>
    80004eaa:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004eac:	000aa583          	lw	a1,0(s5)
    80004eb0:	0289a503          	lw	a0,40(s3)
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	c08080e7          	jalr	-1016(ra) # 80003abc <bread>
    80004ebc:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004ebe:	40000613          	li	a2,1024
    80004ec2:	05890593          	addi	a1,s2,88
    80004ec6:	05850513          	addi	a0,a0,88
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	e60080e7          	jalr	-416(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	cda080e7          	jalr	-806(ra) # 80003bae <bwrite>
    if(recovering == 0)
    80004edc:	f80b1ce3          	bnez	s6,80004e74 <install_trans+0x36>
      bunpin(dbuf);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	fffff097          	auipc	ra,0xfffff
    80004ee6:	de4080e7          	jalr	-540(ra) # 80003cc6 <bunpin>
    80004eea:	b769                	j	80004e74 <install_trans+0x36>
}
    80004eec:	70e2                	ld	ra,56(sp)
    80004eee:	7442                	ld	s0,48(sp)
    80004ef0:	74a2                	ld	s1,40(sp)
    80004ef2:	7902                	ld	s2,32(sp)
    80004ef4:	69e2                	ld	s3,24(sp)
    80004ef6:	6a42                	ld	s4,16(sp)
    80004ef8:	6aa2                	ld	s5,8(sp)
    80004efa:	6b02                	ld	s6,0(sp)
    80004efc:	6121                	addi	sp,sp,64
    80004efe:	8082                	ret
    80004f00:	8082                	ret

0000000080004f02 <initlog>:
{
    80004f02:	7179                	addi	sp,sp,-48
    80004f04:	f406                	sd	ra,40(sp)
    80004f06:	f022                	sd	s0,32(sp)
    80004f08:	ec26                	sd	s1,24(sp)
    80004f0a:	e84a                	sd	s2,16(sp)
    80004f0c:	e44e                	sd	s3,8(sp)
    80004f0e:	1800                	addi	s0,sp,48
    80004f10:	892a                	mv	s2,a0
    80004f12:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004f14:	00026497          	auipc	s1,0x26
    80004f18:	95c48493          	addi	s1,s1,-1700 # 8002a870 <log>
    80004f1c:	00005597          	auipc	a1,0x5
    80004f20:	92458593          	addi	a1,a1,-1756 # 80009840 <syscalls+0x248>
    80004f24:	8526                	mv	a0,s1
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	c1c080e7          	jalr	-996(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004f2e:	0149a583          	lw	a1,20(s3)
    80004f32:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004f34:	0109a783          	lw	a5,16(s3)
    80004f38:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004f3a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004f3e:	854a                	mv	a0,s2
    80004f40:	fffff097          	auipc	ra,0xfffff
    80004f44:	b7c080e7          	jalr	-1156(ra) # 80003abc <bread>
  log.lh.n = lh->n;
    80004f48:	4d34                	lw	a3,88(a0)
    80004f4a:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004f4c:	02d05663          	blez	a3,80004f78 <initlog+0x76>
    80004f50:	05c50793          	addi	a5,a0,92
    80004f54:	00026717          	auipc	a4,0x26
    80004f58:	94c70713          	addi	a4,a4,-1716 # 8002a8a0 <log+0x30>
    80004f5c:	36fd                	addiw	a3,a3,-1
    80004f5e:	02069613          	slli	a2,a3,0x20
    80004f62:	01e65693          	srli	a3,a2,0x1e
    80004f66:	06050613          	addi	a2,a0,96
    80004f6a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004f6c:	4390                	lw	a2,0(a5)
    80004f6e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004f70:	0791                	addi	a5,a5,4
    80004f72:	0711                	addi	a4,a4,4
    80004f74:	fed79ce3          	bne	a5,a3,80004f6c <initlog+0x6a>
  brelse(buf);
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	c74080e7          	jalr	-908(ra) # 80003bec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004f80:	4505                	li	a0,1
    80004f82:	00000097          	auipc	ra,0x0
    80004f86:	ebc080e7          	jalr	-324(ra) # 80004e3e <install_trans>
  log.lh.n = 0;
    80004f8a:	00026797          	auipc	a5,0x26
    80004f8e:	9007a923          	sw	zero,-1774(a5) # 8002a89c <log+0x2c>
  write_head(); // clear the log
    80004f92:	00000097          	auipc	ra,0x0
    80004f96:	e30080e7          	jalr	-464(ra) # 80004dc2 <write_head>
}
    80004f9a:	70a2                	ld	ra,40(sp)
    80004f9c:	7402                	ld	s0,32(sp)
    80004f9e:	64e2                	ld	s1,24(sp)
    80004fa0:	6942                	ld	s2,16(sp)
    80004fa2:	69a2                	ld	s3,8(sp)
    80004fa4:	6145                	addi	sp,sp,48
    80004fa6:	8082                	ret

0000000080004fa8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004fa8:	1101                	addi	sp,sp,-32
    80004faa:	ec06                	sd	ra,24(sp)
    80004fac:	e822                	sd	s0,16(sp)
    80004fae:	e426                	sd	s1,8(sp)
    80004fb0:	e04a                	sd	s2,0(sp)
    80004fb2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004fb4:	00026517          	auipc	a0,0x26
    80004fb8:	8bc50513          	addi	a0,a0,-1860 # 8002a870 <log>
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	c16080e7          	jalr	-1002(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004fc4:	00026497          	auipc	s1,0x26
    80004fc8:	8ac48493          	addi	s1,s1,-1876 # 8002a870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004fcc:	4979                	li	s2,30
    80004fce:	a039                	j	80004fdc <begin_op+0x34>
      sleep(&log, &log.lock);
    80004fd0:	85a6                	mv	a1,s1
    80004fd2:	8526                	mv	a0,s1
    80004fd4:	ffffe097          	auipc	ra,0xffffe
    80004fd8:	d54080e7          	jalr	-684(ra) # 80002d28 <sleep>
    if(log.committing){
    80004fdc:	50dc                	lw	a5,36(s1)
    80004fde:	fbed                	bnez	a5,80004fd0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004fe0:	509c                	lw	a5,32(s1)
    80004fe2:	0017871b          	addiw	a4,a5,1
    80004fe6:	0007069b          	sext.w	a3,a4
    80004fea:	0027179b          	slliw	a5,a4,0x2
    80004fee:	9fb9                	addw	a5,a5,a4
    80004ff0:	0017979b          	slliw	a5,a5,0x1
    80004ff4:	54d8                	lw	a4,44(s1)
    80004ff6:	9fb9                	addw	a5,a5,a4
    80004ff8:	00f95963          	bge	s2,a5,8000500a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004ffc:	85a6                	mv	a1,s1
    80004ffe:	8526                	mv	a0,s1
    80005000:	ffffe097          	auipc	ra,0xffffe
    80005004:	d28080e7          	jalr	-728(ra) # 80002d28 <sleep>
    80005008:	bfd1                	j	80004fdc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000500a:	00026517          	auipc	a0,0x26
    8000500e:	86650513          	addi	a0,a0,-1946 # 8002a870 <log>
    80005012:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	c72080e7          	jalr	-910(ra) # 80000c86 <release>
      break;
    }
  }
}
    8000501c:	60e2                	ld	ra,24(sp)
    8000501e:	6442                	ld	s0,16(sp)
    80005020:	64a2                	ld	s1,8(sp)
    80005022:	6902                	ld	s2,0(sp)
    80005024:	6105                	addi	sp,sp,32
    80005026:	8082                	ret

0000000080005028 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005028:	7139                	addi	sp,sp,-64
    8000502a:	fc06                	sd	ra,56(sp)
    8000502c:	f822                	sd	s0,48(sp)
    8000502e:	f426                	sd	s1,40(sp)
    80005030:	f04a                	sd	s2,32(sp)
    80005032:	ec4e                	sd	s3,24(sp)
    80005034:	e852                	sd	s4,16(sp)
    80005036:	e456                	sd	s5,8(sp)
    80005038:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000503a:	00026497          	auipc	s1,0x26
    8000503e:	83648493          	addi	s1,s1,-1994 # 8002a870 <log>
    80005042:	8526                	mv	a0,s1
    80005044:	ffffc097          	auipc	ra,0xffffc
    80005048:	b8e080e7          	jalr	-1138(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    8000504c:	509c                	lw	a5,32(s1)
    8000504e:	37fd                	addiw	a5,a5,-1
    80005050:	0007891b          	sext.w	s2,a5
    80005054:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80005056:	50dc                	lw	a5,36(s1)
    80005058:	e7b9                	bnez	a5,800050a6 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000505a:	04091e63          	bnez	s2,800050b6 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000505e:	00026497          	auipc	s1,0x26
    80005062:	81248493          	addi	s1,s1,-2030 # 8002a870 <log>
    80005066:	4785                	li	a5,1
    80005068:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000506a:	8526                	mv	a0,s1
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c1a080e7          	jalr	-998(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80005074:	54dc                	lw	a5,44(s1)
    80005076:	06f04763          	bgtz	a5,800050e4 <end_op+0xbc>
    acquire(&log.lock);
    8000507a:	00025497          	auipc	s1,0x25
    8000507e:	7f648493          	addi	s1,s1,2038 # 8002a870 <log>
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	b4e080e7          	jalr	-1202(ra) # 80000bd2 <acquire>
    log.committing = 0;
    8000508c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005090:	8526                	mv	a0,s1
    80005092:	ffffe097          	auipc	ra,0xffffe
    80005096:	e22080e7          	jalr	-478(ra) # 80002eb4 <wakeup>
    release(&log.lock);
    8000509a:	8526                	mv	a0,s1
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	bea080e7          	jalr	-1046(ra) # 80000c86 <release>
}
    800050a4:	a03d                	j	800050d2 <end_op+0xaa>
    panic("log.committing");
    800050a6:	00004517          	auipc	a0,0x4
    800050aa:	7a250513          	addi	a0,a0,1954 # 80009848 <syscalls+0x250>
    800050ae:	ffffb097          	auipc	ra,0xffffb
    800050b2:	47c080e7          	jalr	1148(ra) # 8000052a <panic>
    wakeup(&log);
    800050b6:	00025497          	auipc	s1,0x25
    800050ba:	7ba48493          	addi	s1,s1,1978 # 8002a870 <log>
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffe097          	auipc	ra,0xffffe
    800050c4:	df4080e7          	jalr	-524(ra) # 80002eb4 <wakeup>
  release(&log.lock);
    800050c8:	8526                	mv	a0,s1
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	bbc080e7          	jalr	-1092(ra) # 80000c86 <release>
}
    800050d2:	70e2                	ld	ra,56(sp)
    800050d4:	7442                	ld	s0,48(sp)
    800050d6:	74a2                	ld	s1,40(sp)
    800050d8:	7902                	ld	s2,32(sp)
    800050da:	69e2                	ld	s3,24(sp)
    800050dc:	6a42                	ld	s4,16(sp)
    800050de:	6aa2                	ld	s5,8(sp)
    800050e0:	6121                	addi	sp,sp,64
    800050e2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800050e4:	00025a97          	auipc	s5,0x25
    800050e8:	7bca8a93          	addi	s5,s5,1980 # 8002a8a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800050ec:	00025a17          	auipc	s4,0x25
    800050f0:	784a0a13          	addi	s4,s4,1924 # 8002a870 <log>
    800050f4:	018a2583          	lw	a1,24(s4)
    800050f8:	012585bb          	addw	a1,a1,s2
    800050fc:	2585                	addiw	a1,a1,1
    800050fe:	028a2503          	lw	a0,40(s4)
    80005102:	fffff097          	auipc	ra,0xfffff
    80005106:	9ba080e7          	jalr	-1606(ra) # 80003abc <bread>
    8000510a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000510c:	000aa583          	lw	a1,0(s5)
    80005110:	028a2503          	lw	a0,40(s4)
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	9a8080e7          	jalr	-1624(ra) # 80003abc <bread>
    8000511c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000511e:	40000613          	li	a2,1024
    80005122:	05850593          	addi	a1,a0,88
    80005126:	05848513          	addi	a0,s1,88
    8000512a:	ffffc097          	auipc	ra,0xffffc
    8000512e:	c00080e7          	jalr	-1024(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80005132:	8526                	mv	a0,s1
    80005134:	fffff097          	auipc	ra,0xfffff
    80005138:	a7a080e7          	jalr	-1414(ra) # 80003bae <bwrite>
    brelse(from);
    8000513c:	854e                	mv	a0,s3
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	aae080e7          	jalr	-1362(ra) # 80003bec <brelse>
    brelse(to);
    80005146:	8526                	mv	a0,s1
    80005148:	fffff097          	auipc	ra,0xfffff
    8000514c:	aa4080e7          	jalr	-1372(ra) # 80003bec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80005150:	2905                	addiw	s2,s2,1
    80005152:	0a91                	addi	s5,s5,4
    80005154:	02ca2783          	lw	a5,44(s4)
    80005158:	f8f94ee3          	blt	s2,a5,800050f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000515c:	00000097          	auipc	ra,0x0
    80005160:	c66080e7          	jalr	-922(ra) # 80004dc2 <write_head>
    install_trans(0); // Now install writes to home locations
    80005164:	4501                	li	a0,0
    80005166:	00000097          	auipc	ra,0x0
    8000516a:	cd8080e7          	jalr	-808(ra) # 80004e3e <install_trans>
    log.lh.n = 0;
    8000516e:	00025797          	auipc	a5,0x25
    80005172:	7207a723          	sw	zero,1838(a5) # 8002a89c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80005176:	00000097          	auipc	ra,0x0
    8000517a:	c4c080e7          	jalr	-948(ra) # 80004dc2 <write_head>
    8000517e:	bdf5                	j	8000507a <end_op+0x52>

0000000080005180 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80005180:	1101                	addi	sp,sp,-32
    80005182:	ec06                	sd	ra,24(sp)
    80005184:	e822                	sd	s0,16(sp)
    80005186:	e426                	sd	s1,8(sp)
    80005188:	e04a                	sd	s2,0(sp)
    8000518a:	1000                	addi	s0,sp,32
    8000518c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000518e:	00025917          	auipc	s2,0x25
    80005192:	6e290913          	addi	s2,s2,1762 # 8002a870 <log>
    80005196:	854a                	mv	a0,s2
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	a3a080e7          	jalr	-1478(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800051a0:	02c92603          	lw	a2,44(s2)
    800051a4:	47f5                	li	a5,29
    800051a6:	06c7c563          	blt	a5,a2,80005210 <log_write+0x90>
    800051aa:	00025797          	auipc	a5,0x25
    800051ae:	6e27a783          	lw	a5,1762(a5) # 8002a88c <log+0x1c>
    800051b2:	37fd                	addiw	a5,a5,-1
    800051b4:	04f65e63          	bge	a2,a5,80005210 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800051b8:	00025797          	auipc	a5,0x25
    800051bc:	6d87a783          	lw	a5,1752(a5) # 8002a890 <log+0x20>
    800051c0:	06f05063          	blez	a5,80005220 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800051c4:	4781                	li	a5,0
    800051c6:	06c05563          	blez	a2,80005230 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800051ca:	44cc                	lw	a1,12(s1)
    800051cc:	00025717          	auipc	a4,0x25
    800051d0:	6d470713          	addi	a4,a4,1748 # 8002a8a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800051d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800051d6:	4314                	lw	a3,0(a4)
    800051d8:	04b68c63          	beq	a3,a1,80005230 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800051dc:	2785                	addiw	a5,a5,1
    800051de:	0711                	addi	a4,a4,4
    800051e0:	fef61be3          	bne	a2,a5,800051d6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800051e4:	0621                	addi	a2,a2,8
    800051e6:	060a                	slli	a2,a2,0x2
    800051e8:	00025797          	auipc	a5,0x25
    800051ec:	68878793          	addi	a5,a5,1672 # 8002a870 <log>
    800051f0:	963e                	add	a2,a2,a5
    800051f2:	44dc                	lw	a5,12(s1)
    800051f4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800051f6:	8526                	mv	a0,s1
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	a92080e7          	jalr	-1390(ra) # 80003c8a <bpin>
    log.lh.n++;
    80005200:	00025717          	auipc	a4,0x25
    80005204:	67070713          	addi	a4,a4,1648 # 8002a870 <log>
    80005208:	575c                	lw	a5,44(a4)
    8000520a:	2785                	addiw	a5,a5,1
    8000520c:	d75c                	sw	a5,44(a4)
    8000520e:	a835                	j	8000524a <log_write+0xca>
    panic("too big a transaction");
    80005210:	00004517          	auipc	a0,0x4
    80005214:	64850513          	addi	a0,a0,1608 # 80009858 <syscalls+0x260>
    80005218:	ffffb097          	auipc	ra,0xffffb
    8000521c:	312080e7          	jalr	786(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80005220:	00004517          	auipc	a0,0x4
    80005224:	65050513          	addi	a0,a0,1616 # 80009870 <syscalls+0x278>
    80005228:	ffffb097          	auipc	ra,0xffffb
    8000522c:	302080e7          	jalr	770(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80005230:	00878713          	addi	a4,a5,8
    80005234:	00271693          	slli	a3,a4,0x2
    80005238:	00025717          	auipc	a4,0x25
    8000523c:	63870713          	addi	a4,a4,1592 # 8002a870 <log>
    80005240:	9736                	add	a4,a4,a3
    80005242:	44d4                	lw	a3,12(s1)
    80005244:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80005246:	faf608e3          	beq	a2,a5,800051f6 <log_write+0x76>
  }
  release(&log.lock);
    8000524a:	00025517          	auipc	a0,0x25
    8000524e:	62650513          	addi	a0,a0,1574 # 8002a870 <log>
    80005252:	ffffc097          	auipc	ra,0xffffc
    80005256:	a34080e7          	jalr	-1484(ra) # 80000c86 <release>
}
    8000525a:	60e2                	ld	ra,24(sp)
    8000525c:	6442                	ld	s0,16(sp)
    8000525e:	64a2                	ld	s1,8(sp)
    80005260:	6902                	ld	s2,0(sp)
    80005262:	6105                	addi	sp,sp,32
    80005264:	8082                	ret

0000000080005266 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80005266:	1101                	addi	sp,sp,-32
    80005268:	ec06                	sd	ra,24(sp)
    8000526a:	e822                	sd	s0,16(sp)
    8000526c:	e426                	sd	s1,8(sp)
    8000526e:	e04a                	sd	s2,0(sp)
    80005270:	1000                	addi	s0,sp,32
    80005272:	84aa                	mv	s1,a0
    80005274:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80005276:	00004597          	auipc	a1,0x4
    8000527a:	61a58593          	addi	a1,a1,1562 # 80009890 <syscalls+0x298>
    8000527e:	0521                	addi	a0,a0,8
    80005280:	ffffc097          	auipc	ra,0xffffc
    80005284:	8c2080e7          	jalr	-1854(ra) # 80000b42 <initlock>
  lk->name = name;
    80005288:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000528c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005290:	0204a423          	sw	zero,40(s1)
}
    80005294:	60e2                	ld	ra,24(sp)
    80005296:	6442                	ld	s0,16(sp)
    80005298:	64a2                	ld	s1,8(sp)
    8000529a:	6902                	ld	s2,0(sp)
    8000529c:	6105                	addi	sp,sp,32
    8000529e:	8082                	ret

00000000800052a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800052a0:	1101                	addi	sp,sp,-32
    800052a2:	ec06                	sd	ra,24(sp)
    800052a4:	e822                	sd	s0,16(sp)
    800052a6:	e426                	sd	s1,8(sp)
    800052a8:	e04a                	sd	s2,0(sp)
    800052aa:	1000                	addi	s0,sp,32
    800052ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800052ae:	00850913          	addi	s2,a0,8
    800052b2:	854a                	mv	a0,s2
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	91e080e7          	jalr	-1762(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    800052bc:	409c                	lw	a5,0(s1)
    800052be:	cb89                	beqz	a5,800052d0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800052c0:	85ca                	mv	a1,s2
    800052c2:	8526                	mv	a0,s1
    800052c4:	ffffe097          	auipc	ra,0xffffe
    800052c8:	a64080e7          	jalr	-1436(ra) # 80002d28 <sleep>
  while (lk->locked) {
    800052cc:	409c                	lw	a5,0(s1)
    800052ce:	fbed                	bnez	a5,800052c0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800052d0:	4785                	li	a5,1
    800052d2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800052d4:	ffffd097          	auipc	ra,0xffffd
    800052d8:	12e080e7          	jalr	302(ra) # 80002402 <myproc>
    800052dc:	591c                	lw	a5,48(a0)
    800052de:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800052e0:	854a                	mv	a0,s2
    800052e2:	ffffc097          	auipc	ra,0xffffc
    800052e6:	9a4080e7          	jalr	-1628(ra) # 80000c86 <release>
}
    800052ea:	60e2                	ld	ra,24(sp)
    800052ec:	6442                	ld	s0,16(sp)
    800052ee:	64a2                	ld	s1,8(sp)
    800052f0:	6902                	ld	s2,0(sp)
    800052f2:	6105                	addi	sp,sp,32
    800052f4:	8082                	ret

00000000800052f6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800052f6:	1101                	addi	sp,sp,-32
    800052f8:	ec06                	sd	ra,24(sp)
    800052fa:	e822                	sd	s0,16(sp)
    800052fc:	e426                	sd	s1,8(sp)
    800052fe:	e04a                	sd	s2,0(sp)
    80005300:	1000                	addi	s0,sp,32
    80005302:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005304:	00850913          	addi	s2,a0,8
    80005308:	854a                	mv	a0,s2
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	8c8080e7          	jalr	-1848(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80005312:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005316:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffe097          	auipc	ra,0xffffe
    80005320:	b98080e7          	jalr	-1128(ra) # 80002eb4 <wakeup>
  release(&lk->lk);
    80005324:	854a                	mv	a0,s2
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	960080e7          	jalr	-1696(ra) # 80000c86 <release>
}
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	64a2                	ld	s1,8(sp)
    80005334:	6902                	ld	s2,0(sp)
    80005336:	6105                	addi	sp,sp,32
    80005338:	8082                	ret

000000008000533a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000533a:	7179                	addi	sp,sp,-48
    8000533c:	f406                	sd	ra,40(sp)
    8000533e:	f022                	sd	s0,32(sp)
    80005340:	ec26                	sd	s1,24(sp)
    80005342:	e84a                	sd	s2,16(sp)
    80005344:	e44e                	sd	s3,8(sp)
    80005346:	1800                	addi	s0,sp,48
    80005348:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000534a:	00850913          	addi	s2,a0,8
    8000534e:	854a                	mv	a0,s2
    80005350:	ffffc097          	auipc	ra,0xffffc
    80005354:	882080e7          	jalr	-1918(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80005358:	409c                	lw	a5,0(s1)
    8000535a:	ef99                	bnez	a5,80005378 <holdingsleep+0x3e>
    8000535c:	4481                	li	s1,0
  release(&lk->lk);
    8000535e:	854a                	mv	a0,s2
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	926080e7          	jalr	-1754(ra) # 80000c86 <release>
  return r;
}
    80005368:	8526                	mv	a0,s1
    8000536a:	70a2                	ld	ra,40(sp)
    8000536c:	7402                	ld	s0,32(sp)
    8000536e:	64e2                	ld	s1,24(sp)
    80005370:	6942                	ld	s2,16(sp)
    80005372:	69a2                	ld	s3,8(sp)
    80005374:	6145                	addi	sp,sp,48
    80005376:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80005378:	0284a983          	lw	s3,40(s1)
    8000537c:	ffffd097          	auipc	ra,0xffffd
    80005380:	086080e7          	jalr	134(ra) # 80002402 <myproc>
    80005384:	5904                	lw	s1,48(a0)
    80005386:	413484b3          	sub	s1,s1,s3
    8000538a:	0014b493          	seqz	s1,s1
    8000538e:	bfc1                	j	8000535e <holdingsleep+0x24>

0000000080005390 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005390:	1141                	addi	sp,sp,-16
    80005392:	e406                	sd	ra,8(sp)
    80005394:	e022                	sd	s0,0(sp)
    80005396:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005398:	00004597          	auipc	a1,0x4
    8000539c:	50858593          	addi	a1,a1,1288 # 800098a0 <syscalls+0x2a8>
    800053a0:	00025517          	auipc	a0,0x25
    800053a4:	61850513          	addi	a0,a0,1560 # 8002a9b8 <ftable>
    800053a8:	ffffb097          	auipc	ra,0xffffb
    800053ac:	79a080e7          	jalr	1946(ra) # 80000b42 <initlock>
}
    800053b0:	60a2                	ld	ra,8(sp)
    800053b2:	6402                	ld	s0,0(sp)
    800053b4:	0141                	addi	sp,sp,16
    800053b6:	8082                	ret

00000000800053b8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800053b8:	1101                	addi	sp,sp,-32
    800053ba:	ec06                	sd	ra,24(sp)
    800053bc:	e822                	sd	s0,16(sp)
    800053be:	e426                	sd	s1,8(sp)
    800053c0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800053c2:	00025517          	auipc	a0,0x25
    800053c6:	5f650513          	addi	a0,a0,1526 # 8002a9b8 <ftable>
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	808080e7          	jalr	-2040(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800053d2:	00025497          	auipc	s1,0x25
    800053d6:	5fe48493          	addi	s1,s1,1534 # 8002a9d0 <ftable+0x18>
    800053da:	00026717          	auipc	a4,0x26
    800053de:	59670713          	addi	a4,a4,1430 # 8002b970 <ftable+0xfb8>
    if(f->ref == 0){
    800053e2:	40dc                	lw	a5,4(s1)
    800053e4:	cf99                	beqz	a5,80005402 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800053e6:	02848493          	addi	s1,s1,40
    800053ea:	fee49ce3          	bne	s1,a4,800053e2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800053ee:	00025517          	auipc	a0,0x25
    800053f2:	5ca50513          	addi	a0,a0,1482 # 8002a9b8 <ftable>
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	890080e7          	jalr	-1904(ra) # 80000c86 <release>
  return 0;
    800053fe:	4481                	li	s1,0
    80005400:	a819                	j	80005416 <filealloc+0x5e>
      f->ref = 1;
    80005402:	4785                	li	a5,1
    80005404:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005406:	00025517          	auipc	a0,0x25
    8000540a:	5b250513          	addi	a0,a0,1458 # 8002a9b8 <ftable>
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	878080e7          	jalr	-1928(ra) # 80000c86 <release>
}
    80005416:	8526                	mv	a0,s1
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	64a2                	ld	s1,8(sp)
    8000541e:	6105                	addi	sp,sp,32
    80005420:	8082                	ret

0000000080005422 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005422:	1101                	addi	sp,sp,-32
    80005424:	ec06                	sd	ra,24(sp)
    80005426:	e822                	sd	s0,16(sp)
    80005428:	e426                	sd	s1,8(sp)
    8000542a:	1000                	addi	s0,sp,32
    8000542c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000542e:	00025517          	auipc	a0,0x25
    80005432:	58a50513          	addi	a0,a0,1418 # 8002a9b8 <ftable>
    80005436:	ffffb097          	auipc	ra,0xffffb
    8000543a:	79c080e7          	jalr	1948(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    8000543e:	40dc                	lw	a5,4(s1)
    80005440:	02f05263          	blez	a5,80005464 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80005444:	2785                	addiw	a5,a5,1
    80005446:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005448:	00025517          	auipc	a0,0x25
    8000544c:	57050513          	addi	a0,a0,1392 # 8002a9b8 <ftable>
    80005450:	ffffc097          	auipc	ra,0xffffc
    80005454:	836080e7          	jalr	-1994(ra) # 80000c86 <release>
  return f;
}
    80005458:	8526                	mv	a0,s1
    8000545a:	60e2                	ld	ra,24(sp)
    8000545c:	6442                	ld	s0,16(sp)
    8000545e:	64a2                	ld	s1,8(sp)
    80005460:	6105                	addi	sp,sp,32
    80005462:	8082                	ret
    panic("filedup");
    80005464:	00004517          	auipc	a0,0x4
    80005468:	44450513          	addi	a0,a0,1092 # 800098a8 <syscalls+0x2b0>
    8000546c:	ffffb097          	auipc	ra,0xffffb
    80005470:	0be080e7          	jalr	190(ra) # 8000052a <panic>

0000000080005474 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80005474:	7139                	addi	sp,sp,-64
    80005476:	fc06                	sd	ra,56(sp)
    80005478:	f822                	sd	s0,48(sp)
    8000547a:	f426                	sd	s1,40(sp)
    8000547c:	f04a                	sd	s2,32(sp)
    8000547e:	ec4e                	sd	s3,24(sp)
    80005480:	e852                	sd	s4,16(sp)
    80005482:	e456                	sd	s5,8(sp)
    80005484:	0080                	addi	s0,sp,64
    80005486:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005488:	00025517          	auipc	a0,0x25
    8000548c:	53050513          	addi	a0,a0,1328 # 8002a9b8 <ftable>
    80005490:	ffffb097          	auipc	ra,0xffffb
    80005494:	742080e7          	jalr	1858(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80005498:	40dc                	lw	a5,4(s1)
    8000549a:	06f05163          	blez	a5,800054fc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000549e:	37fd                	addiw	a5,a5,-1
    800054a0:	0007871b          	sext.w	a4,a5
    800054a4:	c0dc                	sw	a5,4(s1)
    800054a6:	06e04363          	bgtz	a4,8000550c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800054aa:	0004a903          	lw	s2,0(s1)
    800054ae:	0094ca83          	lbu	s5,9(s1)
    800054b2:	0104ba03          	ld	s4,16(s1)
    800054b6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800054ba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800054be:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800054c2:	00025517          	auipc	a0,0x25
    800054c6:	4f650513          	addi	a0,a0,1270 # 8002a9b8 <ftable>
    800054ca:	ffffb097          	auipc	ra,0xffffb
    800054ce:	7bc080e7          	jalr	1980(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    800054d2:	4785                	li	a5,1
    800054d4:	04f90d63          	beq	s2,a5,8000552e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800054d8:	3979                	addiw	s2,s2,-2
    800054da:	4785                	li	a5,1
    800054dc:	0527e063          	bltu	a5,s2,8000551c <fileclose+0xa8>
    begin_op();
    800054e0:	00000097          	auipc	ra,0x0
    800054e4:	ac8080e7          	jalr	-1336(ra) # 80004fa8 <begin_op>
    iput(ff.ip);
    800054e8:	854e                	mv	a0,s3
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	f90080e7          	jalr	-112(ra) # 8000447a <iput>
    end_op();
    800054f2:	00000097          	auipc	ra,0x0
    800054f6:	b36080e7          	jalr	-1226(ra) # 80005028 <end_op>
    800054fa:	a00d                	j	8000551c <fileclose+0xa8>
    panic("fileclose");
    800054fc:	00004517          	auipc	a0,0x4
    80005500:	3b450513          	addi	a0,a0,948 # 800098b0 <syscalls+0x2b8>
    80005504:	ffffb097          	auipc	ra,0xffffb
    80005508:	026080e7          	jalr	38(ra) # 8000052a <panic>
    release(&ftable.lock);
    8000550c:	00025517          	auipc	a0,0x25
    80005510:	4ac50513          	addi	a0,a0,1196 # 8002a9b8 <ftable>
    80005514:	ffffb097          	auipc	ra,0xffffb
    80005518:	772080e7          	jalr	1906(ra) # 80000c86 <release>
  }
}
    8000551c:	70e2                	ld	ra,56(sp)
    8000551e:	7442                	ld	s0,48(sp)
    80005520:	74a2                	ld	s1,40(sp)
    80005522:	7902                	ld	s2,32(sp)
    80005524:	69e2                	ld	s3,24(sp)
    80005526:	6a42                	ld	s4,16(sp)
    80005528:	6aa2                	ld	s5,8(sp)
    8000552a:	6121                	addi	sp,sp,64
    8000552c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000552e:	85d6                	mv	a1,s5
    80005530:	8552                	mv	a0,s4
    80005532:	00000097          	auipc	ra,0x0
    80005536:	542080e7          	jalr	1346(ra) # 80005a74 <pipeclose>
    8000553a:	b7cd                	j	8000551c <fileclose+0xa8>

000000008000553c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000553c:	715d                	addi	sp,sp,-80
    8000553e:	e486                	sd	ra,72(sp)
    80005540:	e0a2                	sd	s0,64(sp)
    80005542:	fc26                	sd	s1,56(sp)
    80005544:	f84a                	sd	s2,48(sp)
    80005546:	f44e                	sd	s3,40(sp)
    80005548:	0880                	addi	s0,sp,80
    8000554a:	84aa                	mv	s1,a0
    8000554c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000554e:	ffffd097          	auipc	ra,0xffffd
    80005552:	eb4080e7          	jalr	-332(ra) # 80002402 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80005556:	409c                	lw	a5,0(s1)
    80005558:	37f9                	addiw	a5,a5,-2
    8000555a:	4705                	li	a4,1
    8000555c:	04f76763          	bltu	a4,a5,800055aa <filestat+0x6e>
    80005560:	892a                	mv	s2,a0
    ilock(f->ip);
    80005562:	6c88                	ld	a0,24(s1)
    80005564:	fffff097          	auipc	ra,0xfffff
    80005568:	d5c080e7          	jalr	-676(ra) # 800042c0 <ilock>
    stati(f->ip, &st);
    8000556c:	fb840593          	addi	a1,s0,-72
    80005570:	6c88                	ld	a0,24(s1)
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	fd8080e7          	jalr	-40(ra) # 8000454a <stati>
    iunlock(f->ip);
    8000557a:	6c88                	ld	a0,24(s1)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	e06080e7          	jalr	-506(ra) # 80004382 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80005584:	46e1                	li	a3,24
    80005586:	fb840613          	addi	a2,s0,-72
    8000558a:	85ce                	mv	a1,s3
    8000558c:	05093503          	ld	a0,80(s2)
    80005590:	ffffc097          	auipc	ra,0xffffc
    80005594:	efa080e7          	jalr	-262(ra) # 8000148a <copyout>
    80005598:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000559c:	60a6                	ld	ra,72(sp)
    8000559e:	6406                	ld	s0,64(sp)
    800055a0:	74e2                	ld	s1,56(sp)
    800055a2:	7942                	ld	s2,48(sp)
    800055a4:	79a2                	ld	s3,40(sp)
    800055a6:	6161                	addi	sp,sp,80
    800055a8:	8082                	ret
  return -1;
    800055aa:	557d                	li	a0,-1
    800055ac:	bfc5                	j	8000559c <filestat+0x60>

00000000800055ae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800055ae:	7179                	addi	sp,sp,-48
    800055b0:	f406                	sd	ra,40(sp)
    800055b2:	f022                	sd	s0,32(sp)
    800055b4:	ec26                	sd	s1,24(sp)
    800055b6:	e84a                	sd	s2,16(sp)
    800055b8:	e44e                	sd	s3,8(sp)
    800055ba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800055bc:	00854783          	lbu	a5,8(a0)
    800055c0:	c3d5                	beqz	a5,80005664 <fileread+0xb6>
    800055c2:	84aa                	mv	s1,a0
    800055c4:	89ae                	mv	s3,a1
    800055c6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800055c8:	411c                	lw	a5,0(a0)
    800055ca:	4705                	li	a4,1
    800055cc:	04e78963          	beq	a5,a4,8000561e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800055d0:	470d                	li	a4,3
    800055d2:	04e78d63          	beq	a5,a4,8000562c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800055d6:	4709                	li	a4,2
    800055d8:	06e79e63          	bne	a5,a4,80005654 <fileread+0xa6>
    ilock(f->ip);
    800055dc:	6d08                	ld	a0,24(a0)
    800055de:	fffff097          	auipc	ra,0xfffff
    800055e2:	ce2080e7          	jalr	-798(ra) # 800042c0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800055e6:	874a                	mv	a4,s2
    800055e8:	5094                	lw	a3,32(s1)
    800055ea:	864e                	mv	a2,s3
    800055ec:	4585                	li	a1,1
    800055ee:	6c88                	ld	a0,24(s1)
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	f84080e7          	jalr	-124(ra) # 80004574 <readi>
    800055f8:	892a                	mv	s2,a0
    800055fa:	00a05563          	blez	a0,80005604 <fileread+0x56>
      f->off += r;
    800055fe:	509c                	lw	a5,32(s1)
    80005600:	9fa9                	addw	a5,a5,a0
    80005602:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005604:	6c88                	ld	a0,24(s1)
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	d7c080e7          	jalr	-644(ra) # 80004382 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000560e:	854a                	mv	a0,s2
    80005610:	70a2                	ld	ra,40(sp)
    80005612:	7402                	ld	s0,32(sp)
    80005614:	64e2                	ld	s1,24(sp)
    80005616:	6942                	ld	s2,16(sp)
    80005618:	69a2                	ld	s3,8(sp)
    8000561a:	6145                	addi	sp,sp,48
    8000561c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000561e:	6908                	ld	a0,16(a0)
    80005620:	00000097          	auipc	ra,0x0
    80005624:	5b6080e7          	jalr	1462(ra) # 80005bd6 <piperead>
    80005628:	892a                	mv	s2,a0
    8000562a:	b7d5                	j	8000560e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000562c:	02451783          	lh	a5,36(a0)
    80005630:	03079693          	slli	a3,a5,0x30
    80005634:	92c1                	srli	a3,a3,0x30
    80005636:	4725                	li	a4,9
    80005638:	02d76863          	bltu	a4,a3,80005668 <fileread+0xba>
    8000563c:	0792                	slli	a5,a5,0x4
    8000563e:	00025717          	auipc	a4,0x25
    80005642:	2da70713          	addi	a4,a4,730 # 8002a918 <devsw>
    80005646:	97ba                	add	a5,a5,a4
    80005648:	639c                	ld	a5,0(a5)
    8000564a:	c38d                	beqz	a5,8000566c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000564c:	4505                	li	a0,1
    8000564e:	9782                	jalr	a5
    80005650:	892a                	mv	s2,a0
    80005652:	bf75                	j	8000560e <fileread+0x60>
    panic("fileread");
    80005654:	00004517          	auipc	a0,0x4
    80005658:	26c50513          	addi	a0,a0,620 # 800098c0 <syscalls+0x2c8>
    8000565c:	ffffb097          	auipc	ra,0xffffb
    80005660:	ece080e7          	jalr	-306(ra) # 8000052a <panic>
    return -1;
    80005664:	597d                	li	s2,-1
    80005666:	b765                	j	8000560e <fileread+0x60>
      return -1;
    80005668:	597d                	li	s2,-1
    8000566a:	b755                	j	8000560e <fileread+0x60>
    8000566c:	597d                	li	s2,-1
    8000566e:	b745                	j	8000560e <fileread+0x60>

0000000080005670 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005670:	715d                	addi	sp,sp,-80
    80005672:	e486                	sd	ra,72(sp)
    80005674:	e0a2                	sd	s0,64(sp)
    80005676:	fc26                	sd	s1,56(sp)
    80005678:	f84a                	sd	s2,48(sp)
    8000567a:	f44e                	sd	s3,40(sp)
    8000567c:	f052                	sd	s4,32(sp)
    8000567e:	ec56                	sd	s5,24(sp)
    80005680:	e85a                	sd	s6,16(sp)
    80005682:	e45e                	sd	s7,8(sp)
    80005684:	e062                	sd	s8,0(sp)
    80005686:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005688:	00954783          	lbu	a5,9(a0)
    8000568c:	10078663          	beqz	a5,80005798 <filewrite+0x128>
    80005690:	892a                	mv	s2,a0
    80005692:	8aae                	mv	s5,a1
    80005694:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005696:	411c                	lw	a5,0(a0)
    80005698:	4705                	li	a4,1
    8000569a:	02e78263          	beq	a5,a4,800056be <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000569e:	470d                	li	a4,3
    800056a0:	02e78663          	beq	a5,a4,800056cc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800056a4:	4709                	li	a4,2
    800056a6:	0ee79163          	bne	a5,a4,80005788 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800056aa:	0ac05d63          	blez	a2,80005764 <filewrite+0xf4>
    int i = 0;
    800056ae:	4981                	li	s3,0
    800056b0:	6b05                	lui	s6,0x1
    800056b2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800056b6:	6b85                	lui	s7,0x1
    800056b8:	c00b8b9b          	addiw	s7,s7,-1024
    800056bc:	a861                	j	80005754 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800056be:	6908                	ld	a0,16(a0)
    800056c0:	00000097          	auipc	ra,0x0
    800056c4:	424080e7          	jalr	1060(ra) # 80005ae4 <pipewrite>
    800056c8:	8a2a                	mv	s4,a0
    800056ca:	a045                	j	8000576a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800056cc:	02451783          	lh	a5,36(a0)
    800056d0:	03079693          	slli	a3,a5,0x30
    800056d4:	92c1                	srli	a3,a3,0x30
    800056d6:	4725                	li	a4,9
    800056d8:	0cd76263          	bltu	a4,a3,8000579c <filewrite+0x12c>
    800056dc:	0792                	slli	a5,a5,0x4
    800056de:	00025717          	auipc	a4,0x25
    800056e2:	23a70713          	addi	a4,a4,570 # 8002a918 <devsw>
    800056e6:	97ba                	add	a5,a5,a4
    800056e8:	679c                	ld	a5,8(a5)
    800056ea:	cbdd                	beqz	a5,800057a0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800056ec:	4505                	li	a0,1
    800056ee:	9782                	jalr	a5
    800056f0:	8a2a                	mv	s4,a0
    800056f2:	a8a5                	j	8000576a <filewrite+0xfa>
    800056f4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800056f8:	00000097          	auipc	ra,0x0
    800056fc:	8b0080e7          	jalr	-1872(ra) # 80004fa8 <begin_op>
      ilock(f->ip);
    80005700:	01893503          	ld	a0,24(s2)
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	bbc080e7          	jalr	-1092(ra) # 800042c0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000570c:	8762                	mv	a4,s8
    8000570e:	02092683          	lw	a3,32(s2)
    80005712:	01598633          	add	a2,s3,s5
    80005716:	4585                	li	a1,1
    80005718:	01893503          	ld	a0,24(s2)
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	f50080e7          	jalr	-176(ra) # 8000466c <writei>
    80005724:	84aa                	mv	s1,a0
    80005726:	00a05763          	blez	a0,80005734 <filewrite+0xc4>
        f->off += r;
    8000572a:	02092783          	lw	a5,32(s2)
    8000572e:	9fa9                	addw	a5,a5,a0
    80005730:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005734:	01893503          	ld	a0,24(s2)
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	c4a080e7          	jalr	-950(ra) # 80004382 <iunlock>
      end_op();
    80005740:	00000097          	auipc	ra,0x0
    80005744:	8e8080e7          	jalr	-1816(ra) # 80005028 <end_op>

      if(r != n1){
    80005748:	009c1f63          	bne	s8,s1,80005766 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000574c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005750:	0149db63          	bge	s3,s4,80005766 <filewrite+0xf6>
      int n1 = n - i;
    80005754:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005758:	84be                	mv	s1,a5
    8000575a:	2781                	sext.w	a5,a5
    8000575c:	f8fb5ce3          	bge	s6,a5,800056f4 <filewrite+0x84>
    80005760:	84de                	mv	s1,s7
    80005762:	bf49                	j	800056f4 <filewrite+0x84>
    int i = 0;
    80005764:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005766:	013a1f63          	bne	s4,s3,80005784 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000576a:	8552                	mv	a0,s4
    8000576c:	60a6                	ld	ra,72(sp)
    8000576e:	6406                	ld	s0,64(sp)
    80005770:	74e2                	ld	s1,56(sp)
    80005772:	7942                	ld	s2,48(sp)
    80005774:	79a2                	ld	s3,40(sp)
    80005776:	7a02                	ld	s4,32(sp)
    80005778:	6ae2                	ld	s5,24(sp)
    8000577a:	6b42                	ld	s6,16(sp)
    8000577c:	6ba2                	ld	s7,8(sp)
    8000577e:	6c02                	ld	s8,0(sp)
    80005780:	6161                	addi	sp,sp,80
    80005782:	8082                	ret
    ret = (i == n ? n : -1);
    80005784:	5a7d                	li	s4,-1
    80005786:	b7d5                	j	8000576a <filewrite+0xfa>
    panic("filewrite");
    80005788:	00004517          	auipc	a0,0x4
    8000578c:	14850513          	addi	a0,a0,328 # 800098d0 <syscalls+0x2d8>
    80005790:	ffffb097          	auipc	ra,0xffffb
    80005794:	d9a080e7          	jalr	-614(ra) # 8000052a <panic>
    return -1;
    80005798:	5a7d                	li	s4,-1
    8000579a:	bfc1                	j	8000576a <filewrite+0xfa>
      return -1;
    8000579c:	5a7d                	li	s4,-1
    8000579e:	b7f1                	j	8000576a <filewrite+0xfa>
    800057a0:	5a7d                	li	s4,-1
    800057a2:	b7e1                	j	8000576a <filewrite+0xfa>

00000000800057a4 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800057a4:	7179                	addi	sp,sp,-48
    800057a6:	f406                	sd	ra,40(sp)
    800057a8:	f022                	sd	s0,32(sp)
    800057aa:	ec26                	sd	s1,24(sp)
    800057ac:	e84a                	sd	s2,16(sp)
    800057ae:	e44e                	sd	s3,8(sp)
    800057b0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800057b2:	00854783          	lbu	a5,8(a0)
    800057b6:	c3d5                	beqz	a5,8000585a <kfileread+0xb6>
    800057b8:	84aa                	mv	s1,a0
    800057ba:	89ae                	mv	s3,a1
    800057bc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800057be:	411c                	lw	a5,0(a0)
    800057c0:	4705                	li	a4,1
    800057c2:	04e78963          	beq	a5,a4,80005814 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800057c6:	470d                	li	a4,3
    800057c8:	04e78d63          	beq	a5,a4,80005822 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800057cc:	4709                	li	a4,2
    800057ce:	06e79e63          	bne	a5,a4,8000584a <kfileread+0xa6>
    ilock(f->ip);
    800057d2:	6d08                	ld	a0,24(a0)
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	aec080e7          	jalr	-1300(ra) # 800042c0 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    800057dc:	874a                	mv	a4,s2
    800057de:	5094                	lw	a3,32(s1)
    800057e0:	864e                	mv	a2,s3
    800057e2:	4581                	li	a1,0
    800057e4:	6c88                	ld	a0,24(s1)
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	d8e080e7          	jalr	-626(ra) # 80004574 <readi>
    800057ee:	892a                	mv	s2,a0
    800057f0:	00a05563          	blez	a0,800057fa <kfileread+0x56>
      f->off += r;
    800057f4:	509c                	lw	a5,32(s1)
    800057f6:	9fa9                	addw	a5,a5,a0
    800057f8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800057fa:	6c88                	ld	a0,24(s1)
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	b86080e7          	jalr	-1146(ra) # 80004382 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005804:	854a                	mv	a0,s2
    80005806:	70a2                	ld	ra,40(sp)
    80005808:	7402                	ld	s0,32(sp)
    8000580a:	64e2                	ld	s1,24(sp)
    8000580c:	6942                	ld	s2,16(sp)
    8000580e:	69a2                	ld	s3,8(sp)
    80005810:	6145                	addi	sp,sp,48
    80005812:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005814:	6908                	ld	a0,16(a0)
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	3c0080e7          	jalr	960(ra) # 80005bd6 <piperead>
    8000581e:	892a                	mv	s2,a0
    80005820:	b7d5                	j	80005804 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005822:	02451783          	lh	a5,36(a0)
    80005826:	03079693          	slli	a3,a5,0x30
    8000582a:	92c1                	srli	a3,a3,0x30
    8000582c:	4725                	li	a4,9
    8000582e:	02d76863          	bltu	a4,a3,8000585e <kfileread+0xba>
    80005832:	0792                	slli	a5,a5,0x4
    80005834:	00025717          	auipc	a4,0x25
    80005838:	0e470713          	addi	a4,a4,228 # 8002a918 <devsw>
    8000583c:	97ba                	add	a5,a5,a4
    8000583e:	639c                	ld	a5,0(a5)
    80005840:	c38d                	beqz	a5,80005862 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005842:	4505                	li	a0,1
    80005844:	9782                	jalr	a5
    80005846:	892a                	mv	s2,a0
    80005848:	bf75                	j	80005804 <kfileread+0x60>
    panic("fileread");
    8000584a:	00004517          	auipc	a0,0x4
    8000584e:	07650513          	addi	a0,a0,118 # 800098c0 <syscalls+0x2c8>
    80005852:	ffffb097          	auipc	ra,0xffffb
    80005856:	cd8080e7          	jalr	-808(ra) # 8000052a <panic>
    return -1;
    8000585a:	597d                	li	s2,-1
    8000585c:	b765                	j	80005804 <kfileread+0x60>
      return -1;
    8000585e:	597d                	li	s2,-1
    80005860:	b755                	j	80005804 <kfileread+0x60>
    80005862:	597d                	li	s2,-1
    80005864:	b745                	j	80005804 <kfileread+0x60>

0000000080005866 <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80005866:	715d                	addi	sp,sp,-80
    80005868:	e486                	sd	ra,72(sp)
    8000586a:	e0a2                	sd	s0,64(sp)
    8000586c:	fc26                	sd	s1,56(sp)
    8000586e:	f84a                	sd	s2,48(sp)
    80005870:	f44e                	sd	s3,40(sp)
    80005872:	f052                	sd	s4,32(sp)
    80005874:	ec56                	sd	s5,24(sp)
    80005876:	e85a                	sd	s6,16(sp)
    80005878:	e45e                	sd	s7,8(sp)
    8000587a:	e062                	sd	s8,0(sp)
    8000587c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    8000587e:	00954783          	lbu	a5,9(a0)
    80005882:	10078663          	beqz	a5,8000598e <kfilewrite+0x128>
    80005886:	892a                	mv	s2,a0
    80005888:	8aae                	mv	s5,a1
    8000588a:	8a32                	mv	s4,a2
    return -1;
  }

  if(f->type == FD_PIPE){
    8000588c:	411c                	lw	a5,0(a0)
    8000588e:	4705                	li	a4,1
    80005890:	02e78263          	beq	a5,a4,800058b4 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005894:	470d                	li	a4,3
    80005896:	02e78663          	beq	a5,a4,800058c2 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000589a:	4709                	li	a4,2
    8000589c:	0ee79163          	bne	a5,a4,8000597e <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800058a0:	0ac05d63          	blez	a2,8000595a <kfilewrite+0xf4>
    int i = 0;
    800058a4:	4981                	li	s3,0
    800058a6:	6b05                	lui	s6,0x1
    800058a8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800058ac:	6b85                	lui	s7,0x1
    800058ae:	c00b8b9b          	addiw	s7,s7,-1024
    800058b2:	a861                	j	8000594a <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800058b4:	6908                	ld	a0,16(a0)
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	22e080e7          	jalr	558(ra) # 80005ae4 <pipewrite>
    800058be:	8a2a                	mv	s4,a0
    800058c0:	a045                	j	80005960 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    800058c2:	02451783          	lh	a5,36(a0)
    800058c6:	03079693          	slli	a3,a5,0x30
    800058ca:	92c1                	srli	a3,a3,0x30
    800058cc:	4725                	li	a4,9
    800058ce:	0cd76263          	bltu	a4,a3,80005992 <kfilewrite+0x12c>
    800058d2:	0792                	slli	a5,a5,0x4
    800058d4:	00025717          	auipc	a4,0x25
    800058d8:	04470713          	addi	a4,a4,68 # 8002a918 <devsw>
    800058dc:	97ba                	add	a5,a5,a4
    800058de:	679c                	ld	a5,8(a5)
    800058e0:	cbdd                	beqz	a5,80005996 <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800058e2:	4505                	li	a0,1
    800058e4:	9782                	jalr	a5
    800058e6:	8a2a                	mv	s4,a0
    800058e8:	a8a5                	j	80005960 <kfilewrite+0xfa>
    800058ea:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	6ba080e7          	jalr	1722(ra) # 80004fa8 <begin_op>
      ilock(f->ip);
    800058f6:	01893503          	ld	a0,24(s2)
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	9c6080e7          	jalr	-1594(ra) # 800042c0 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005902:	8762                	mv	a4,s8
    80005904:	02092683          	lw	a3,32(s2)
    80005908:	01598633          	add	a2,s3,s5
    8000590c:	4581                	li	a1,0
    8000590e:	01893503          	ld	a0,24(s2)
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	d5a080e7          	jalr	-678(ra) # 8000466c <writei>
    8000591a:	84aa                	mv	s1,a0
    8000591c:	00a05763          	blez	a0,8000592a <kfilewrite+0xc4>
        f->off += r;
    80005920:	02092783          	lw	a5,32(s2)
    80005924:	9fa9                	addw	a5,a5,a0
    80005926:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000592a:	01893503          	ld	a0,24(s2)
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	a54080e7          	jalr	-1452(ra) # 80004382 <iunlock>
      end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	6f2080e7          	jalr	1778(ra) # 80005028 <end_op>

      if(r != n1){
    8000593e:	009c1f63          	bne	s8,s1,8000595c <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005942:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005946:	0149db63          	bge	s3,s4,8000595c <kfilewrite+0xf6>
      int n1 = n - i;
    8000594a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000594e:	84be                	mv	s1,a5
    80005950:	2781                	sext.w	a5,a5
    80005952:	f8fb5ce3          	bge	s6,a5,800058ea <kfilewrite+0x84>
    80005956:	84de                	mv	s1,s7
    80005958:	bf49                	j	800058ea <kfilewrite+0x84>
    int i = 0;
    8000595a:	4981                	li	s3,0
    }

    ret = (i == n ? n : -1);
    8000595c:	013a1f63          	bne	s4,s3,8000597a <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    80005960:	8552                	mv	a0,s4
    80005962:	60a6                	ld	ra,72(sp)
    80005964:	6406                	ld	s0,64(sp)
    80005966:	74e2                	ld	s1,56(sp)
    80005968:	7942                	ld	s2,48(sp)
    8000596a:	79a2                	ld	s3,40(sp)
    8000596c:	7a02                	ld	s4,32(sp)
    8000596e:	6ae2                	ld	s5,24(sp)
    80005970:	6b42                	ld	s6,16(sp)
    80005972:	6ba2                	ld	s7,8(sp)
    80005974:	6c02                	ld	s8,0(sp)
    80005976:	6161                	addi	sp,sp,80
    80005978:	8082                	ret
    ret = (i == n ? n : -1);
    8000597a:	5a7d                	li	s4,-1
    8000597c:	b7d5                	j	80005960 <kfilewrite+0xfa>
    panic("filewrite");
    8000597e:	00004517          	auipc	a0,0x4
    80005982:	f5250513          	addi	a0,a0,-174 # 800098d0 <syscalls+0x2d8>
    80005986:	ffffb097          	auipc	ra,0xffffb
    8000598a:	ba4080e7          	jalr	-1116(ra) # 8000052a <panic>
    return -1;
    8000598e:	5a7d                	li	s4,-1
    80005990:	bfc1                	j	80005960 <kfilewrite+0xfa>
      return -1;
    80005992:	5a7d                	li	s4,-1
    80005994:	b7f1                	j	80005960 <kfilewrite+0xfa>
    80005996:	5a7d                	li	s4,-1
    80005998:	b7e1                	j	80005960 <kfilewrite+0xfa>

000000008000599a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000599a:	7179                	addi	sp,sp,-48
    8000599c:	f406                	sd	ra,40(sp)
    8000599e:	f022                	sd	s0,32(sp)
    800059a0:	ec26                	sd	s1,24(sp)
    800059a2:	e84a                	sd	s2,16(sp)
    800059a4:	e44e                	sd	s3,8(sp)
    800059a6:	e052                	sd	s4,0(sp)
    800059a8:	1800                	addi	s0,sp,48
    800059aa:	84aa                	mv	s1,a0
    800059ac:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800059ae:	0005b023          	sd	zero,0(a1)
    800059b2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800059b6:	00000097          	auipc	ra,0x0
    800059ba:	a02080e7          	jalr	-1534(ra) # 800053b8 <filealloc>
    800059be:	e088                	sd	a0,0(s1)
    800059c0:	c551                	beqz	a0,80005a4c <pipealloc+0xb2>
    800059c2:	00000097          	auipc	ra,0x0
    800059c6:	9f6080e7          	jalr	-1546(ra) # 800053b8 <filealloc>
    800059ca:	00aa3023          	sd	a0,0(s4)
    800059ce:	c92d                	beqz	a0,80005a40 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	112080e7          	jalr	274(ra) # 80000ae2 <kalloc>
    800059d8:	892a                	mv	s2,a0
    800059da:	c125                	beqz	a0,80005a3a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800059dc:	4985                	li	s3,1
    800059de:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800059e2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800059e6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800059ea:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800059ee:	00004597          	auipc	a1,0x4
    800059f2:	ef258593          	addi	a1,a1,-270 # 800098e0 <syscalls+0x2e8>
    800059f6:	ffffb097          	auipc	ra,0xffffb
    800059fa:	14c080e7          	jalr	332(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    800059fe:	609c                	ld	a5,0(s1)
    80005a00:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005a04:	609c                	ld	a5,0(s1)
    80005a06:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005a0a:	609c                	ld	a5,0(s1)
    80005a0c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005a10:	609c                	ld	a5,0(s1)
    80005a12:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005a16:	000a3783          	ld	a5,0(s4)
    80005a1a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005a1e:	000a3783          	ld	a5,0(s4)
    80005a22:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005a26:	000a3783          	ld	a5,0(s4)
    80005a2a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005a2e:	000a3783          	ld	a5,0(s4)
    80005a32:	0127b823          	sd	s2,16(a5)
  return 0;
    80005a36:	4501                	li	a0,0
    80005a38:	a025                	j	80005a60 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005a3a:	6088                	ld	a0,0(s1)
    80005a3c:	e501                	bnez	a0,80005a44 <pipealloc+0xaa>
    80005a3e:	a039                	j	80005a4c <pipealloc+0xb2>
    80005a40:	6088                	ld	a0,0(s1)
    80005a42:	c51d                	beqz	a0,80005a70 <pipealloc+0xd6>
    fileclose(*f0);
    80005a44:	00000097          	auipc	ra,0x0
    80005a48:	a30080e7          	jalr	-1488(ra) # 80005474 <fileclose>
  if(*f1)
    80005a4c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005a50:	557d                	li	a0,-1
  if(*f1)
    80005a52:	c799                	beqz	a5,80005a60 <pipealloc+0xc6>
    fileclose(*f1);
    80005a54:	853e                	mv	a0,a5
    80005a56:	00000097          	auipc	ra,0x0
    80005a5a:	a1e080e7          	jalr	-1506(ra) # 80005474 <fileclose>
  return -1;
    80005a5e:	557d                	li	a0,-1
}
    80005a60:	70a2                	ld	ra,40(sp)
    80005a62:	7402                	ld	s0,32(sp)
    80005a64:	64e2                	ld	s1,24(sp)
    80005a66:	6942                	ld	s2,16(sp)
    80005a68:	69a2                	ld	s3,8(sp)
    80005a6a:	6a02                	ld	s4,0(sp)
    80005a6c:	6145                	addi	sp,sp,48
    80005a6e:	8082                	ret
  return -1;
    80005a70:	557d                	li	a0,-1
    80005a72:	b7fd                	j	80005a60 <pipealloc+0xc6>

0000000080005a74 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005a74:	1101                	addi	sp,sp,-32
    80005a76:	ec06                	sd	ra,24(sp)
    80005a78:	e822                	sd	s0,16(sp)
    80005a7a:	e426                	sd	s1,8(sp)
    80005a7c:	e04a                	sd	s2,0(sp)
    80005a7e:	1000                	addi	s0,sp,32
    80005a80:	84aa                	mv	s1,a0
    80005a82:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005a84:	ffffb097          	auipc	ra,0xffffb
    80005a88:	14e080e7          	jalr	334(ra) # 80000bd2 <acquire>
  if(writable){
    80005a8c:	02090d63          	beqz	s2,80005ac6 <pipeclose+0x52>
    pi->writeopen = 0;
    80005a90:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005a94:	21848513          	addi	a0,s1,536
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	41c080e7          	jalr	1052(ra) # 80002eb4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005aa0:	2204b783          	ld	a5,544(s1)
    80005aa4:	eb95                	bnez	a5,80005ad8 <pipeclose+0x64>
    release(&pi->lock);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffb097          	auipc	ra,0xffffb
    80005aac:	1de080e7          	jalr	478(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005ab0:	8526                	mv	a0,s1
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	f24080e7          	jalr	-220(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005aba:	60e2                	ld	ra,24(sp)
    80005abc:	6442                	ld	s0,16(sp)
    80005abe:	64a2                	ld	s1,8(sp)
    80005ac0:	6902                	ld	s2,0(sp)
    80005ac2:	6105                	addi	sp,sp,32
    80005ac4:	8082                	ret
    pi->readopen = 0;
    80005ac6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005aca:	21c48513          	addi	a0,s1,540
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	3e6080e7          	jalr	998(ra) # 80002eb4 <wakeup>
    80005ad6:	b7e9                	j	80005aa0 <pipeclose+0x2c>
    release(&pi->lock);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffb097          	auipc	ra,0xffffb
    80005ade:	1ac080e7          	jalr	428(ra) # 80000c86 <release>
}
    80005ae2:	bfe1                	j	80005aba <pipeclose+0x46>

0000000080005ae4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005ae4:	711d                	addi	sp,sp,-96
    80005ae6:	ec86                	sd	ra,88(sp)
    80005ae8:	e8a2                	sd	s0,80(sp)
    80005aea:	e4a6                	sd	s1,72(sp)
    80005aec:	e0ca                	sd	s2,64(sp)
    80005aee:	fc4e                	sd	s3,56(sp)
    80005af0:	f852                	sd	s4,48(sp)
    80005af2:	f456                	sd	s5,40(sp)
    80005af4:	f05a                	sd	s6,32(sp)
    80005af6:	ec5e                	sd	s7,24(sp)
    80005af8:	e862                	sd	s8,16(sp)
    80005afa:	1080                	addi	s0,sp,96
    80005afc:	84aa                	mv	s1,a0
    80005afe:	8aae                	mv	s5,a1
    80005b00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	900080e7          	jalr	-1792(ra) # 80002402 <myproc>
    80005b0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	0c4080e7          	jalr	196(ra) # 80000bd2 <acquire>
  while(i < n){
    80005b16:	0b405363          	blez	s4,80005bbc <pipewrite+0xd8>
  int i = 0;
    80005b1a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005b1c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005b1e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005b22:	21c48b93          	addi	s7,s1,540
    80005b26:	a089                	j	80005b68 <pipewrite+0x84>
      release(&pi->lock);
    80005b28:	8526                	mv	a0,s1
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	15c080e7          	jalr	348(ra) # 80000c86 <release>
      return -1;
    80005b32:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005b34:	854a                	mv	a0,s2
    80005b36:	60e6                	ld	ra,88(sp)
    80005b38:	6446                	ld	s0,80(sp)
    80005b3a:	64a6                	ld	s1,72(sp)
    80005b3c:	6906                	ld	s2,64(sp)
    80005b3e:	79e2                	ld	s3,56(sp)
    80005b40:	7a42                	ld	s4,48(sp)
    80005b42:	7aa2                	ld	s5,40(sp)
    80005b44:	7b02                	ld	s6,32(sp)
    80005b46:	6be2                	ld	s7,24(sp)
    80005b48:	6c42                	ld	s8,16(sp)
    80005b4a:	6125                	addi	sp,sp,96
    80005b4c:	8082                	ret
      wakeup(&pi->nread);
    80005b4e:	8562                	mv	a0,s8
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	364080e7          	jalr	868(ra) # 80002eb4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005b58:	85a6                	mv	a1,s1
    80005b5a:	855e                	mv	a0,s7
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	1cc080e7          	jalr	460(ra) # 80002d28 <sleep>
  while(i < n){
    80005b64:	05495d63          	bge	s2,s4,80005bbe <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005b68:	2204a783          	lw	a5,544(s1)
    80005b6c:	dfd5                	beqz	a5,80005b28 <pipewrite+0x44>
    80005b6e:	0289a783          	lw	a5,40(s3)
    80005b72:	fbdd                	bnez	a5,80005b28 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005b74:	2184a783          	lw	a5,536(s1)
    80005b78:	21c4a703          	lw	a4,540(s1)
    80005b7c:	2007879b          	addiw	a5,a5,512
    80005b80:	fcf707e3          	beq	a4,a5,80005b4e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005b84:	4685                	li	a3,1
    80005b86:	01590633          	add	a2,s2,s5
    80005b8a:	faf40593          	addi	a1,s0,-81
    80005b8e:	0509b503          	ld	a0,80(s3)
    80005b92:	ffffc097          	auipc	ra,0xffffc
    80005b96:	984080e7          	jalr	-1660(ra) # 80001516 <copyin>
    80005b9a:	03650263          	beq	a0,s6,80005bbe <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005b9e:	21c4a783          	lw	a5,540(s1)
    80005ba2:	0017871b          	addiw	a4,a5,1
    80005ba6:	20e4ae23          	sw	a4,540(s1)
    80005baa:	1ff7f793          	andi	a5,a5,511
    80005bae:	97a6                	add	a5,a5,s1
    80005bb0:	faf44703          	lbu	a4,-81(s0)
    80005bb4:	00e78c23          	sb	a4,24(a5)
      i++;
    80005bb8:	2905                	addiw	s2,s2,1
    80005bba:	b76d                	j	80005b64 <pipewrite+0x80>
  int i = 0;
    80005bbc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005bbe:	21848513          	addi	a0,s1,536
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	2f2080e7          	jalr	754(ra) # 80002eb4 <wakeup>
  release(&pi->lock);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffb097          	auipc	ra,0xffffb
    80005bd0:	0ba080e7          	jalr	186(ra) # 80000c86 <release>
  return i;
    80005bd4:	b785                	j	80005b34 <pipewrite+0x50>

0000000080005bd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005bd6:	715d                	addi	sp,sp,-80
    80005bd8:	e486                	sd	ra,72(sp)
    80005bda:	e0a2                	sd	s0,64(sp)
    80005bdc:	fc26                	sd	s1,56(sp)
    80005bde:	f84a                	sd	s2,48(sp)
    80005be0:	f44e                	sd	s3,40(sp)
    80005be2:	f052                	sd	s4,32(sp)
    80005be4:	ec56                	sd	s5,24(sp)
    80005be6:	e85a                	sd	s6,16(sp)
    80005be8:	0880                	addi	s0,sp,80
    80005bea:	84aa                	mv	s1,a0
    80005bec:	892e                	mv	s2,a1
    80005bee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005bf0:	ffffd097          	auipc	ra,0xffffd
    80005bf4:	812080e7          	jalr	-2030(ra) # 80002402 <myproc>
    80005bf8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005bfa:	8526                	mv	a0,s1
    80005bfc:	ffffb097          	auipc	ra,0xffffb
    80005c00:	fd6080e7          	jalr	-42(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005c04:	2184a703          	lw	a4,536(s1)
    80005c08:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005c0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005c10:	02f71463          	bne	a4,a5,80005c38 <piperead+0x62>
    80005c14:	2244a783          	lw	a5,548(s1)
    80005c18:	c385                	beqz	a5,80005c38 <piperead+0x62>
    if(pr->killed){
    80005c1a:	028a2783          	lw	a5,40(s4)
    80005c1e:	ebc1                	bnez	a5,80005cae <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005c20:	85a6                	mv	a1,s1
    80005c22:	854e                	mv	a0,s3
    80005c24:	ffffd097          	auipc	ra,0xffffd
    80005c28:	104080e7          	jalr	260(ra) # 80002d28 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005c2c:	2184a703          	lw	a4,536(s1)
    80005c30:	21c4a783          	lw	a5,540(s1)
    80005c34:	fef700e3          	beq	a4,a5,80005c14 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c38:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005c3a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c3c:	05505363          	blez	s5,80005c82 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005c40:	2184a783          	lw	a5,536(s1)
    80005c44:	21c4a703          	lw	a4,540(s1)
    80005c48:	02f70d63          	beq	a4,a5,80005c82 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005c4c:	0017871b          	addiw	a4,a5,1
    80005c50:	20e4ac23          	sw	a4,536(s1)
    80005c54:	1ff7f793          	andi	a5,a5,511
    80005c58:	97a6                	add	a5,a5,s1
    80005c5a:	0187c783          	lbu	a5,24(a5)
    80005c5e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005c62:	4685                	li	a3,1
    80005c64:	fbf40613          	addi	a2,s0,-65
    80005c68:	85ca                	mv	a1,s2
    80005c6a:	050a3503          	ld	a0,80(s4)
    80005c6e:	ffffc097          	auipc	ra,0xffffc
    80005c72:	81c080e7          	jalr	-2020(ra) # 8000148a <copyout>
    80005c76:	01650663          	beq	a0,s6,80005c82 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c7a:	2985                	addiw	s3,s3,1
    80005c7c:	0905                	addi	s2,s2,1
    80005c7e:	fd3a91e3          	bne	s5,s3,80005c40 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005c82:	21c48513          	addi	a0,s1,540
    80005c86:	ffffd097          	auipc	ra,0xffffd
    80005c8a:	22e080e7          	jalr	558(ra) # 80002eb4 <wakeup>
  release(&pi->lock);
    80005c8e:	8526                	mv	a0,s1
    80005c90:	ffffb097          	auipc	ra,0xffffb
    80005c94:	ff6080e7          	jalr	-10(ra) # 80000c86 <release>
  return i;
}
    80005c98:	854e                	mv	a0,s3
    80005c9a:	60a6                	ld	ra,72(sp)
    80005c9c:	6406                	ld	s0,64(sp)
    80005c9e:	74e2                	ld	s1,56(sp)
    80005ca0:	7942                	ld	s2,48(sp)
    80005ca2:	79a2                	ld	s3,40(sp)
    80005ca4:	7a02                	ld	s4,32(sp)
    80005ca6:	6ae2                	ld	s5,24(sp)
    80005ca8:	6b42                	ld	s6,16(sp)
    80005caa:	6161                	addi	sp,sp,80
    80005cac:	8082                	ret
      release(&pi->lock);
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffb097          	auipc	ra,0xffffb
    80005cb4:	fd6080e7          	jalr	-42(ra) # 80000c86 <release>
      return -1;
    80005cb8:	59fd                	li	s3,-1
    80005cba:	bff9                	j	80005c98 <piperead+0xc2>

0000000080005cbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005cbc:	de010113          	addi	sp,sp,-544
    80005cc0:	20113c23          	sd	ra,536(sp)
    80005cc4:	20813823          	sd	s0,528(sp)
    80005cc8:	20913423          	sd	s1,520(sp)
    80005ccc:	21213023          	sd	s2,512(sp)
    80005cd0:	ffce                	sd	s3,504(sp)
    80005cd2:	fbd2                	sd	s4,496(sp)
    80005cd4:	f7d6                	sd	s5,488(sp)
    80005cd6:	f3da                	sd	s6,480(sp)
    80005cd8:	efde                	sd	s7,472(sp)
    80005cda:	ebe2                	sd	s8,464(sp)
    80005cdc:	e7e6                	sd	s9,456(sp)
    80005cde:	e3ea                	sd	s10,448(sp)
    80005ce0:	ff6e                	sd	s11,440(sp)
    80005ce2:	1400                	addi	s0,sp,544
    80005ce4:	892a                	mv	s2,a0
    80005ce6:	dea43423          	sd	a0,-536(s0)
    80005cea:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005cee:	ffffc097          	auipc	ra,0xffffc
    80005cf2:	714080e7          	jalr	1812(ra) # 80002402 <myproc>
    80005cf6:	84aa                	mv	s1,a0

  begin_op();
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	2b0080e7          	jalr	688(ra) # 80004fa8 <begin_op>

  if((ip = namei(path)) == 0){
    80005d00:	854a                	mv	a0,s2
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	d74080e7          	jalr	-652(ra) # 80004a76 <namei>
    80005d0a:	c93d                	beqz	a0,80005d80 <exec+0xc4>
    80005d0c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	5b2080e7          	jalr	1458(ra) # 800042c0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005d16:	04000713          	li	a4,64
    80005d1a:	4681                	li	a3,0
    80005d1c:	e4840613          	addi	a2,s0,-440
    80005d20:	4581                	li	a1,0
    80005d22:	8556                	mv	a0,s5
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	850080e7          	jalr	-1968(ra) # 80004574 <readi>
    80005d2c:	04000793          	li	a5,64
    80005d30:	00f51a63          	bne	a0,a5,80005d44 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005d34:	e4842703          	lw	a4,-440(s0)
    80005d38:	464c47b7          	lui	a5,0x464c4
    80005d3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005d40:	04f70663          	beq	a4,a5,80005d8c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005d44:	8556                	mv	a0,s5
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	7dc080e7          	jalr	2012(ra) # 80004522 <iunlockput>
    end_op();
    80005d4e:	fffff097          	auipc	ra,0xfffff
    80005d52:	2da080e7          	jalr	730(ra) # 80005028 <end_op>
  }
  return -1;
    80005d56:	557d                	li	a0,-1
}
    80005d58:	21813083          	ld	ra,536(sp)
    80005d5c:	21013403          	ld	s0,528(sp)
    80005d60:	20813483          	ld	s1,520(sp)
    80005d64:	20013903          	ld	s2,512(sp)
    80005d68:	79fe                	ld	s3,504(sp)
    80005d6a:	7a5e                	ld	s4,496(sp)
    80005d6c:	7abe                	ld	s5,488(sp)
    80005d6e:	7b1e                	ld	s6,480(sp)
    80005d70:	6bfe                	ld	s7,472(sp)
    80005d72:	6c5e                	ld	s8,464(sp)
    80005d74:	6cbe                	ld	s9,456(sp)
    80005d76:	6d1e                	ld	s10,448(sp)
    80005d78:	7dfa                	ld	s11,440(sp)
    80005d7a:	22010113          	addi	sp,sp,544
    80005d7e:	8082                	ret
    end_op();
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	2a8080e7          	jalr	680(ra) # 80005028 <end_op>
    return -1;
    80005d88:	557d                	li	a0,-1
    80005d8a:	b7f9                	j	80005d58 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005d8c:	8526                	mv	a0,s1
    80005d8e:	ffffc097          	auipc	ra,0xffffc
    80005d92:	738080e7          	jalr	1848(ra) # 800024c6 <proc_pagetable>
    80005d96:	8b2a                	mv	s6,a0
    80005d98:	d555                	beqz	a0,80005d44 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d9a:	e6842783          	lw	a5,-408(s0)
    80005d9e:	e8045703          	lhu	a4,-384(s0)
    80005da2:	c735                	beqz	a4,80005e0e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005da4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005da6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005daa:	6a05                	lui	s4,0x1
    80005dac:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005db0:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005db4:	6d85                	lui	s11,0x1
    80005db6:	7d7d                	lui	s10,0xfffff
    80005db8:	ac1d                	j	80005fee <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005dba:	00004517          	auipc	a0,0x4
    80005dbe:	b2e50513          	addi	a0,a0,-1234 # 800098e8 <syscalls+0x2f0>
    80005dc2:	ffffa097          	auipc	ra,0xffffa
    80005dc6:	768080e7          	jalr	1896(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005dca:	874a                	mv	a4,s2
    80005dcc:	009c86bb          	addw	a3,s9,s1
    80005dd0:	4581                	li	a1,0
    80005dd2:	8556                	mv	a0,s5
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	7a0080e7          	jalr	1952(ra) # 80004574 <readi>
    80005ddc:	2501                	sext.w	a0,a0
    80005dde:	1aa91863          	bne	s2,a0,80005f8e <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005de2:	009d84bb          	addw	s1,s11,s1
    80005de6:	013d09bb          	addw	s3,s10,s3
    80005dea:	1f74f263          	bgeu	s1,s7,80005fce <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005dee:	02049593          	slli	a1,s1,0x20
    80005df2:	9181                	srli	a1,a1,0x20
    80005df4:	95e2                	add	a1,a1,s8
    80005df6:	855a                	mv	a0,s6
    80005df8:	ffffb097          	auipc	ra,0xffffb
    80005dfc:	24e080e7          	jalr	590(ra) # 80001046 <walkaddr>
    80005e00:	862a                	mv	a2,a0
    if(pa == 0)
    80005e02:	dd45                	beqz	a0,80005dba <exec+0xfe>
      n = PGSIZE;
    80005e04:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005e06:	fd49f2e3          	bgeu	s3,s4,80005dca <exec+0x10e>
      n = sz - i;
    80005e0a:	894e                	mv	s2,s3
    80005e0c:	bf7d                	j	80005dca <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005e0e:	4481                	li	s1,0
  iunlockput(ip);
    80005e10:	8556                	mv	a0,s5
    80005e12:	ffffe097          	auipc	ra,0xffffe
    80005e16:	710080e7          	jalr	1808(ra) # 80004522 <iunlockput>
  end_op();
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	20e080e7          	jalr	526(ra) # 80005028 <end_op>
  p = myproc();
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	5e0080e7          	jalr	1504(ra) # 80002402 <myproc>
    80005e2a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005e2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005e30:	6785                	lui	a5,0x1
    80005e32:	17fd                	addi	a5,a5,-1
    80005e34:	94be                	add	s1,s1,a5
    80005e36:	77fd                	lui	a5,0xfffff
    80005e38:	8fe5                	and	a5,a5,s1
    80005e3a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005e3e:	6609                	lui	a2,0x2
    80005e40:	963e                	add	a2,a2,a5
    80005e42:	85be                	mv	a1,a5
    80005e44:	855a                	mv	a0,s6
    80005e46:	ffffc097          	auipc	ra,0xffffc
    80005e4a:	cba080e7          	jalr	-838(ra) # 80001b00 <uvmalloc>
    80005e4e:	8c2a                	mv	s8,a0
  ip = 0;
    80005e50:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005e52:	12050e63          	beqz	a0,80005f8e <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005e56:	75f9                	lui	a1,0xffffe
    80005e58:	95aa                	add	a1,a1,a0
    80005e5a:	855a                	mv	a0,s6
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	5fc080e7          	jalr	1532(ra) # 80001458 <uvmclear>
  stackbase = sp - PGSIZE;
    80005e64:	7afd                	lui	s5,0xfffff
    80005e66:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005e68:	df043783          	ld	a5,-528(s0)
    80005e6c:	6388                	ld	a0,0(a5)
    80005e6e:	c925                	beqz	a0,80005ede <exec+0x222>
    80005e70:	e8840993          	addi	s3,s0,-376
    80005e74:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005e78:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005e7a:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005e7c:	ffffb097          	auipc	ra,0xffffb
    80005e80:	fd6080e7          	jalr	-42(ra) # 80000e52 <strlen>
    80005e84:	0015079b          	addiw	a5,a0,1
    80005e88:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005e8c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005e90:	13596363          	bltu	s2,s5,80005fb6 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005e94:	df043d83          	ld	s11,-528(s0)
    80005e98:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005e9c:	8552                	mv	a0,s4
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	fb4080e7          	jalr	-76(ra) # 80000e52 <strlen>
    80005ea6:	0015069b          	addiw	a3,a0,1
    80005eaa:	8652                	mv	a2,s4
    80005eac:	85ca                	mv	a1,s2
    80005eae:	855a                	mv	a0,s6
    80005eb0:	ffffb097          	auipc	ra,0xffffb
    80005eb4:	5da080e7          	jalr	1498(ra) # 8000148a <copyout>
    80005eb8:	10054363          	bltz	a0,80005fbe <exec+0x302>
    ustack[argc] = sp;
    80005ebc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005ec0:	0485                	addi	s1,s1,1
    80005ec2:	008d8793          	addi	a5,s11,8
    80005ec6:	def43823          	sd	a5,-528(s0)
    80005eca:	008db503          	ld	a0,8(s11)
    80005ece:	c911                	beqz	a0,80005ee2 <exec+0x226>
    if(argc >= MAXARG)
    80005ed0:	09a1                	addi	s3,s3,8
    80005ed2:	fb3c95e3          	bne	s9,s3,80005e7c <exec+0x1c0>
  sz = sz1;
    80005ed6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005eda:	4a81                	li	s5,0
    80005edc:	a84d                	j	80005f8e <exec+0x2d2>
  sp = sz;
    80005ede:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005ee0:	4481                	li	s1,0
  ustack[argc] = 0;
    80005ee2:	00349793          	slli	a5,s1,0x3
    80005ee6:	f9040713          	addi	a4,s0,-112
    80005eea:	97ba                	add	a5,a5,a4
    80005eec:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005ef0:	00148693          	addi	a3,s1,1
    80005ef4:	068e                	slli	a3,a3,0x3
    80005ef6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005efa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005efe:	01597663          	bgeu	s2,s5,80005f0a <exec+0x24e>
  sz = sz1;
    80005f02:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005f06:	4a81                	li	s5,0
    80005f08:	a059                	j	80005f8e <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005f0a:	e8840613          	addi	a2,s0,-376
    80005f0e:	85ca                	mv	a1,s2
    80005f10:	855a                	mv	a0,s6
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	578080e7          	jalr	1400(ra) # 8000148a <copyout>
    80005f1a:	0a054663          	bltz	a0,80005fc6 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005f1e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005f22:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005f26:	de843783          	ld	a5,-536(s0)
    80005f2a:	0007c703          	lbu	a4,0(a5)
    80005f2e:	cf11                	beqz	a4,80005f4a <exec+0x28e>
    80005f30:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005f32:	02f00693          	li	a3,47
    80005f36:	a039                	j	80005f44 <exec+0x288>
      last = s+1;
    80005f38:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005f3c:	0785                	addi	a5,a5,1
    80005f3e:	fff7c703          	lbu	a4,-1(a5)
    80005f42:	c701                	beqz	a4,80005f4a <exec+0x28e>
    if(*s == '/')
    80005f44:	fed71ce3          	bne	a4,a3,80005f3c <exec+0x280>
    80005f48:	bfc5                	j	80005f38 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005f4a:	4641                	li	a2,16
    80005f4c:	de843583          	ld	a1,-536(s0)
    80005f50:	158b8513          	addi	a0,s7,344
    80005f54:	ffffb097          	auipc	ra,0xffffb
    80005f58:	ecc080e7          	jalr	-308(ra) # 80000e20 <safestrcpy>
  oldpagetable = p->pagetable;
    80005f5c:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005f60:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005f64:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005f68:	058bb783          	ld	a5,88(s7)
    80005f6c:	e6043703          	ld	a4,-416(s0)
    80005f70:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005f72:	058bb783          	ld	a5,88(s7)
    80005f76:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005f7a:	85ea                	mv	a1,s10
    80005f7c:	ffffc097          	auipc	ra,0xffffc
    80005f80:	5e6080e7          	jalr	1510(ra) # 80002562 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005f84:	0004851b          	sext.w	a0,s1
    80005f88:	bbc1                	j	80005d58 <exec+0x9c>
    80005f8a:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005f8e:	df843583          	ld	a1,-520(s0)
    80005f92:	855a                	mv	a0,s6
    80005f94:	ffffc097          	auipc	ra,0xffffc
    80005f98:	5ce080e7          	jalr	1486(ra) # 80002562 <proc_freepagetable>
  if(ip){
    80005f9c:	da0a94e3          	bnez	s5,80005d44 <exec+0x88>
  return -1;
    80005fa0:	557d                	li	a0,-1
    80005fa2:	bb5d                	j	80005d58 <exec+0x9c>
    80005fa4:	de943c23          	sd	s1,-520(s0)
    80005fa8:	b7dd                	j	80005f8e <exec+0x2d2>
    80005faa:	de943c23          	sd	s1,-520(s0)
    80005fae:	b7c5                	j	80005f8e <exec+0x2d2>
    80005fb0:	de943c23          	sd	s1,-520(s0)
    80005fb4:	bfe9                	j	80005f8e <exec+0x2d2>
  sz = sz1;
    80005fb6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005fba:	4a81                	li	s5,0
    80005fbc:	bfc9                	j	80005f8e <exec+0x2d2>
  sz = sz1;
    80005fbe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005fc2:	4a81                	li	s5,0
    80005fc4:	b7e9                	j	80005f8e <exec+0x2d2>
  sz = sz1;
    80005fc6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005fca:	4a81                	li	s5,0
    80005fcc:	b7c9                	j	80005f8e <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005fce:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005fd2:	e0843783          	ld	a5,-504(s0)
    80005fd6:	0017869b          	addiw	a3,a5,1
    80005fda:	e0d43423          	sd	a3,-504(s0)
    80005fde:	e0043783          	ld	a5,-512(s0)
    80005fe2:	0387879b          	addiw	a5,a5,56
    80005fe6:	e8045703          	lhu	a4,-384(s0)
    80005fea:	e2e6d3e3          	bge	a3,a4,80005e10 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005fee:	2781                	sext.w	a5,a5
    80005ff0:	e0f43023          	sd	a5,-512(s0)
    80005ff4:	03800713          	li	a4,56
    80005ff8:	86be                	mv	a3,a5
    80005ffa:	e1040613          	addi	a2,s0,-496
    80005ffe:	4581                	li	a1,0
    80006000:	8556                	mv	a0,s5
    80006002:	ffffe097          	auipc	ra,0xffffe
    80006006:	572080e7          	jalr	1394(ra) # 80004574 <readi>
    8000600a:	03800793          	li	a5,56
    8000600e:	f6f51ee3          	bne	a0,a5,80005f8a <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80006012:	e1042783          	lw	a5,-496(s0)
    80006016:	4705                	li	a4,1
    80006018:	fae79de3          	bne	a5,a4,80005fd2 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000601c:	e3843603          	ld	a2,-456(s0)
    80006020:	e3043783          	ld	a5,-464(s0)
    80006024:	f8f660e3          	bltu	a2,a5,80005fa4 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80006028:	e2043783          	ld	a5,-480(s0)
    8000602c:	963e                	add	a2,a2,a5
    8000602e:	f6f66ee3          	bltu	a2,a5,80005faa <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80006032:	85a6                	mv	a1,s1
    80006034:	855a                	mv	a0,s6
    80006036:	ffffc097          	auipc	ra,0xffffc
    8000603a:	aca080e7          	jalr	-1334(ra) # 80001b00 <uvmalloc>
    8000603e:	dea43c23          	sd	a0,-520(s0)
    80006042:	d53d                	beqz	a0,80005fb0 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80006044:	e2043c03          	ld	s8,-480(s0)
    80006048:	de043783          	ld	a5,-544(s0)
    8000604c:	00fc77b3          	and	a5,s8,a5
    80006050:	ff9d                	bnez	a5,80005f8e <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80006052:	e1842c83          	lw	s9,-488(s0)
    80006056:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000605a:	f60b8ae3          	beqz	s7,80005fce <exec+0x312>
    8000605e:	89de                	mv	s3,s7
    80006060:	4481                	li	s1,0
    80006062:	b371                	j	80005dee <exec+0x132>

0000000080006064 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80006064:	7179                	addi	sp,sp,-48
    80006066:	f406                	sd	ra,40(sp)
    80006068:	f022                	sd	s0,32(sp)
    8000606a:	ec26                	sd	s1,24(sp)
    8000606c:	e84a                	sd	s2,16(sp)
    8000606e:	1800                	addi	s0,sp,48
    80006070:	892e                	mv	s2,a1
    80006072:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80006074:	fdc40593          	addi	a1,s0,-36
    80006078:	ffffd097          	auipc	ra,0xffffd
    8000607c:	6d6080e7          	jalr	1750(ra) # 8000374e <argint>
    80006080:	04054063          	bltz	a0,800060c0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006084:	fdc42703          	lw	a4,-36(s0)
    80006088:	47bd                	li	a5,15
    8000608a:	02e7ed63          	bltu	a5,a4,800060c4 <argfd+0x60>
    8000608e:	ffffc097          	auipc	ra,0xffffc
    80006092:	374080e7          	jalr	884(ra) # 80002402 <myproc>
    80006096:	fdc42703          	lw	a4,-36(s0)
    8000609a:	01a70793          	addi	a5,a4,26
    8000609e:	078e                	slli	a5,a5,0x3
    800060a0:	953e                	add	a0,a0,a5
    800060a2:	611c                	ld	a5,0(a0)
    800060a4:	c395                	beqz	a5,800060c8 <argfd+0x64>
    return -1;
  if(pfd)
    800060a6:	00090463          	beqz	s2,800060ae <argfd+0x4a>
    *pfd = fd;
    800060aa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800060ae:	4501                	li	a0,0
  if(pf)
    800060b0:	c091                	beqz	s1,800060b4 <argfd+0x50>
    *pf = f;
    800060b2:	e09c                	sd	a5,0(s1)
}
    800060b4:	70a2                	ld	ra,40(sp)
    800060b6:	7402                	ld	s0,32(sp)
    800060b8:	64e2                	ld	s1,24(sp)
    800060ba:	6942                	ld	s2,16(sp)
    800060bc:	6145                	addi	sp,sp,48
    800060be:	8082                	ret
    return -1;
    800060c0:	557d                	li	a0,-1
    800060c2:	bfcd                	j	800060b4 <argfd+0x50>
    return -1;
    800060c4:	557d                	li	a0,-1
    800060c6:	b7fd                	j	800060b4 <argfd+0x50>
    800060c8:	557d                	li	a0,-1
    800060ca:	b7ed                	j	800060b4 <argfd+0x50>

00000000800060cc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800060cc:	1101                	addi	sp,sp,-32
    800060ce:	ec06                	sd	ra,24(sp)
    800060d0:	e822                	sd	s0,16(sp)
    800060d2:	e426                	sd	s1,8(sp)
    800060d4:	1000                	addi	s0,sp,32
    800060d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	32a080e7          	jalr	810(ra) # 80002402 <myproc>
    800060e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800060e2:	0d050793          	addi	a5,a0,208
    800060e6:	4501                	li	a0,0
    800060e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800060ea:	6398                	ld	a4,0(a5)
    800060ec:	cb19                	beqz	a4,80006102 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800060ee:	2505                	addiw	a0,a0,1
    800060f0:	07a1                	addi	a5,a5,8
    800060f2:	fed51ce3          	bne	a0,a3,800060ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800060f6:	557d                	li	a0,-1
}
    800060f8:	60e2                	ld	ra,24(sp)
    800060fa:	6442                	ld	s0,16(sp)
    800060fc:	64a2                	ld	s1,8(sp)
    800060fe:	6105                	addi	sp,sp,32
    80006100:	8082                	ret
      p->ofile[fd] = f;
    80006102:	01a50793          	addi	a5,a0,26
    80006106:	078e                	slli	a5,a5,0x3
    80006108:	963e                	add	a2,a2,a5
    8000610a:	e204                	sd	s1,0(a2)
      return fd;
    8000610c:	b7f5                	j	800060f8 <fdalloc+0x2c>

000000008000610e <sys_dup>:

uint64
sys_dup(void)
{
    8000610e:	7179                	addi	sp,sp,-48
    80006110:	f406                	sd	ra,40(sp)
    80006112:	f022                	sd	s0,32(sp)
    80006114:	ec26                	sd	s1,24(sp)
    80006116:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80006118:	fd840613          	addi	a2,s0,-40
    8000611c:	4581                	li	a1,0
    8000611e:	4501                	li	a0,0
    80006120:	00000097          	auipc	ra,0x0
    80006124:	f44080e7          	jalr	-188(ra) # 80006064 <argfd>
    return -1;
    80006128:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000612a:	02054363          	bltz	a0,80006150 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000612e:	fd843503          	ld	a0,-40(s0)
    80006132:	00000097          	auipc	ra,0x0
    80006136:	f9a080e7          	jalr	-102(ra) # 800060cc <fdalloc>
    8000613a:	84aa                	mv	s1,a0
    return -1;
    8000613c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000613e:	00054963          	bltz	a0,80006150 <sys_dup+0x42>
  filedup(f);
    80006142:	fd843503          	ld	a0,-40(s0)
    80006146:	fffff097          	auipc	ra,0xfffff
    8000614a:	2dc080e7          	jalr	732(ra) # 80005422 <filedup>
  return fd;
    8000614e:	87a6                	mv	a5,s1
}
    80006150:	853e                	mv	a0,a5
    80006152:	70a2                	ld	ra,40(sp)
    80006154:	7402                	ld	s0,32(sp)
    80006156:	64e2                	ld	s1,24(sp)
    80006158:	6145                	addi	sp,sp,48
    8000615a:	8082                	ret

000000008000615c <sys_read>:

uint64
sys_read(void)
{
    8000615c:	7179                	addi	sp,sp,-48
    8000615e:	f406                	sd	ra,40(sp)
    80006160:	f022                	sd	s0,32(sp)
    80006162:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006164:	fe840613          	addi	a2,s0,-24
    80006168:	4581                	li	a1,0
    8000616a:	4501                	li	a0,0
    8000616c:	00000097          	auipc	ra,0x0
    80006170:	ef8080e7          	jalr	-264(ra) # 80006064 <argfd>
    return -1;
    80006174:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006176:	04054163          	bltz	a0,800061b8 <sys_read+0x5c>
    8000617a:	fe440593          	addi	a1,s0,-28
    8000617e:	4509                	li	a0,2
    80006180:	ffffd097          	auipc	ra,0xffffd
    80006184:	5ce080e7          	jalr	1486(ra) # 8000374e <argint>
    return -1;
    80006188:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000618a:	02054763          	bltz	a0,800061b8 <sys_read+0x5c>
    8000618e:	fd840593          	addi	a1,s0,-40
    80006192:	4505                	li	a0,1
    80006194:	ffffd097          	auipc	ra,0xffffd
    80006198:	5dc080e7          	jalr	1500(ra) # 80003770 <argaddr>
    return -1;
    8000619c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000619e:	00054d63          	bltz	a0,800061b8 <sys_read+0x5c>
  return fileread(f, p, n);
    800061a2:	fe442603          	lw	a2,-28(s0)
    800061a6:	fd843583          	ld	a1,-40(s0)
    800061aa:	fe843503          	ld	a0,-24(s0)
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	400080e7          	jalr	1024(ra) # 800055ae <fileread>
    800061b6:	87aa                	mv	a5,a0
}
    800061b8:	853e                	mv	a0,a5
    800061ba:	70a2                	ld	ra,40(sp)
    800061bc:	7402                	ld	s0,32(sp)
    800061be:	6145                	addi	sp,sp,48
    800061c0:	8082                	ret

00000000800061c2 <sys_write>:

uint64
sys_write(void)
{
    800061c2:	7179                	addi	sp,sp,-48
    800061c4:	f406                	sd	ra,40(sp)
    800061c6:	f022                	sd	s0,32(sp)
    800061c8:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800061ca:	fe840613          	addi	a2,s0,-24
    800061ce:	4581                	li	a1,0
    800061d0:	4501                	li	a0,0
    800061d2:	00000097          	auipc	ra,0x0
    800061d6:	e92080e7          	jalr	-366(ra) # 80006064 <argfd>
    return -1;
    800061da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800061dc:	04054163          	bltz	a0,8000621e <sys_write+0x5c>
    800061e0:	fe440593          	addi	a1,s0,-28
    800061e4:	4509                	li	a0,2
    800061e6:	ffffd097          	auipc	ra,0xffffd
    800061ea:	568080e7          	jalr	1384(ra) # 8000374e <argint>
    return -1;
    800061ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800061f0:	02054763          	bltz	a0,8000621e <sys_write+0x5c>
    800061f4:	fd840593          	addi	a1,s0,-40
    800061f8:	4505                	li	a0,1
    800061fa:	ffffd097          	auipc	ra,0xffffd
    800061fe:	576080e7          	jalr	1398(ra) # 80003770 <argaddr>
    return -1;
    80006202:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006204:	00054d63          	bltz	a0,8000621e <sys_write+0x5c>

  return filewrite(f, p, n);
    80006208:	fe442603          	lw	a2,-28(s0)
    8000620c:	fd843583          	ld	a1,-40(s0)
    80006210:	fe843503          	ld	a0,-24(s0)
    80006214:	fffff097          	auipc	ra,0xfffff
    80006218:	45c080e7          	jalr	1116(ra) # 80005670 <filewrite>
    8000621c:	87aa                	mv	a5,a0
}
    8000621e:	853e                	mv	a0,a5
    80006220:	70a2                	ld	ra,40(sp)
    80006222:	7402                	ld	s0,32(sp)
    80006224:	6145                	addi	sp,sp,48
    80006226:	8082                	ret

0000000080006228 <sys_close>:

uint64
sys_close(void)
{
    80006228:	1101                	addi	sp,sp,-32
    8000622a:	ec06                	sd	ra,24(sp)
    8000622c:	e822                	sd	s0,16(sp)
    8000622e:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80006230:	fe040613          	addi	a2,s0,-32
    80006234:	fec40593          	addi	a1,s0,-20
    80006238:	4501                	li	a0,0
    8000623a:	00000097          	auipc	ra,0x0
    8000623e:	e2a080e7          	jalr	-470(ra) # 80006064 <argfd>
    return -1;
    80006242:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80006244:	02054463          	bltz	a0,8000626c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80006248:	ffffc097          	auipc	ra,0xffffc
    8000624c:	1ba080e7          	jalr	442(ra) # 80002402 <myproc>
    80006250:	fec42783          	lw	a5,-20(s0)
    80006254:	07e9                	addi	a5,a5,26
    80006256:	078e                	slli	a5,a5,0x3
    80006258:	97aa                	add	a5,a5,a0
    8000625a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000625e:	fe043503          	ld	a0,-32(s0)
    80006262:	fffff097          	auipc	ra,0xfffff
    80006266:	212080e7          	jalr	530(ra) # 80005474 <fileclose>
  return 0;
    8000626a:	4781                	li	a5,0
}
    8000626c:	853e                	mv	a0,a5
    8000626e:	60e2                	ld	ra,24(sp)
    80006270:	6442                	ld	s0,16(sp)
    80006272:	6105                	addi	sp,sp,32
    80006274:	8082                	ret

0000000080006276 <sys_fstat>:

uint64
sys_fstat(void)
{
    80006276:	1101                	addi	sp,sp,-32
    80006278:	ec06                	sd	ra,24(sp)
    8000627a:	e822                	sd	s0,16(sp)
    8000627c:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000627e:	fe840613          	addi	a2,s0,-24
    80006282:	4581                	li	a1,0
    80006284:	4501                	li	a0,0
    80006286:	00000097          	auipc	ra,0x0
    8000628a:	dde080e7          	jalr	-546(ra) # 80006064 <argfd>
    return -1;
    8000628e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006290:	02054563          	bltz	a0,800062ba <sys_fstat+0x44>
    80006294:	fe040593          	addi	a1,s0,-32
    80006298:	4505                	li	a0,1
    8000629a:	ffffd097          	auipc	ra,0xffffd
    8000629e:	4d6080e7          	jalr	1238(ra) # 80003770 <argaddr>
    return -1;
    800062a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800062a4:	00054b63          	bltz	a0,800062ba <sys_fstat+0x44>
  return filestat(f, st);
    800062a8:	fe043583          	ld	a1,-32(s0)
    800062ac:	fe843503          	ld	a0,-24(s0)
    800062b0:	fffff097          	auipc	ra,0xfffff
    800062b4:	28c080e7          	jalr	652(ra) # 8000553c <filestat>
    800062b8:	87aa                	mv	a5,a0
}
    800062ba:	853e                	mv	a0,a5
    800062bc:	60e2                	ld	ra,24(sp)
    800062be:	6442                	ld	s0,16(sp)
    800062c0:	6105                	addi	sp,sp,32
    800062c2:	8082                	ret

00000000800062c4 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    800062c4:	7169                	addi	sp,sp,-304
    800062c6:	f606                	sd	ra,296(sp)
    800062c8:	f222                	sd	s0,288(sp)
    800062ca:	ee26                	sd	s1,280(sp)
    800062cc:	ea4a                	sd	s2,272(sp)
    800062ce:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800062d0:	08000613          	li	a2,128
    800062d4:	ed040593          	addi	a1,s0,-304
    800062d8:	4501                	li	a0,0
    800062da:	ffffd097          	auipc	ra,0xffffd
    800062de:	4b8080e7          	jalr	1208(ra) # 80003792 <argstr>
    return -1;
    800062e2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800062e4:	10054e63          	bltz	a0,80006400 <sys_link+0x13c>
    800062e8:	08000613          	li	a2,128
    800062ec:	f5040593          	addi	a1,s0,-176
    800062f0:	4505                	li	a0,1
    800062f2:	ffffd097          	auipc	ra,0xffffd
    800062f6:	4a0080e7          	jalr	1184(ra) # 80003792 <argstr>
    return -1;
    800062fa:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800062fc:	10054263          	bltz	a0,80006400 <sys_link+0x13c>

  begin_op();
    80006300:	fffff097          	auipc	ra,0xfffff
    80006304:	ca8080e7          	jalr	-856(ra) # 80004fa8 <begin_op>
  if((ip = namei(old)) == 0){
    80006308:	ed040513          	addi	a0,s0,-304
    8000630c:	ffffe097          	auipc	ra,0xffffe
    80006310:	76a080e7          	jalr	1898(ra) # 80004a76 <namei>
    80006314:	84aa                	mv	s1,a0
    80006316:	c551                	beqz	a0,800063a2 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80006318:	ffffe097          	auipc	ra,0xffffe
    8000631c:	fa8080e7          	jalr	-88(ra) # 800042c0 <ilock>
  if(ip->type == T_DIR){
    80006320:	04449703          	lh	a4,68(s1)
    80006324:	4785                	li	a5,1
    80006326:	08f70463          	beq	a4,a5,800063ae <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    8000632a:	04a4d783          	lhu	a5,74(s1)
    8000632e:	2785                	addiw	a5,a5,1
    80006330:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006334:	8526                	mv	a0,s1
    80006336:	ffffe097          	auipc	ra,0xffffe
    8000633a:	ec0080e7          	jalr	-320(ra) # 800041f6 <iupdate>
  iunlock(ip);
    8000633e:	8526                	mv	a0,s1
    80006340:	ffffe097          	auipc	ra,0xffffe
    80006344:	042080e7          	jalr	66(ra) # 80004382 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80006348:	fd040593          	addi	a1,s0,-48
    8000634c:	f5040513          	addi	a0,s0,-176
    80006350:	ffffe097          	auipc	ra,0xffffe
    80006354:	744080e7          	jalr	1860(ra) # 80004a94 <nameiparent>
    80006358:	892a                	mv	s2,a0
    8000635a:	c935                	beqz	a0,800063ce <sys_link+0x10a>
    goto bad;
  ilock(dp);
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	f64080e7          	jalr	-156(ra) # 800042c0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006364:	00092703          	lw	a4,0(s2)
    80006368:	409c                	lw	a5,0(s1)
    8000636a:	04f71d63          	bne	a4,a5,800063c4 <sys_link+0x100>
    8000636e:	40d0                	lw	a2,4(s1)
    80006370:	fd040593          	addi	a1,s0,-48
    80006374:	854a                	mv	a0,s2
    80006376:	ffffe097          	auipc	ra,0xffffe
    8000637a:	63e080e7          	jalr	1598(ra) # 800049b4 <dirlink>
    8000637e:	04054363          	bltz	a0,800063c4 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80006382:	854a                	mv	a0,s2
    80006384:	ffffe097          	auipc	ra,0xffffe
    80006388:	19e080e7          	jalr	414(ra) # 80004522 <iunlockput>
  iput(ip);
    8000638c:	8526                	mv	a0,s1
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	0ec080e7          	jalr	236(ra) # 8000447a <iput>

  end_op();
    80006396:	fffff097          	auipc	ra,0xfffff
    8000639a:	c92080e7          	jalr	-878(ra) # 80005028 <end_op>

  return 0;
    8000639e:	4781                	li	a5,0
    800063a0:	a085                	j	80006400 <sys_link+0x13c>
    end_op();
    800063a2:	fffff097          	auipc	ra,0xfffff
    800063a6:	c86080e7          	jalr	-890(ra) # 80005028 <end_op>
    return -1;
    800063aa:	57fd                	li	a5,-1
    800063ac:	a891                	j	80006400 <sys_link+0x13c>
    iunlockput(ip);
    800063ae:	8526                	mv	a0,s1
    800063b0:	ffffe097          	auipc	ra,0xffffe
    800063b4:	172080e7          	jalr	370(ra) # 80004522 <iunlockput>
    end_op();
    800063b8:	fffff097          	auipc	ra,0xfffff
    800063bc:	c70080e7          	jalr	-912(ra) # 80005028 <end_op>
    return -1;
    800063c0:	57fd                	li	a5,-1
    800063c2:	a83d                	j	80006400 <sys_link+0x13c>
    iunlockput(dp);
    800063c4:	854a                	mv	a0,s2
    800063c6:	ffffe097          	auipc	ra,0xffffe
    800063ca:	15c080e7          	jalr	348(ra) # 80004522 <iunlockput>

bad:
  ilock(ip);
    800063ce:	8526                	mv	a0,s1
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	ef0080e7          	jalr	-272(ra) # 800042c0 <ilock>
  ip->nlink--;
    800063d8:	04a4d783          	lhu	a5,74(s1)
    800063dc:	37fd                	addiw	a5,a5,-1
    800063de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800063e2:	8526                	mv	a0,s1
    800063e4:	ffffe097          	auipc	ra,0xffffe
    800063e8:	e12080e7          	jalr	-494(ra) # 800041f6 <iupdate>
  iunlockput(ip);
    800063ec:	8526                	mv	a0,s1
    800063ee:	ffffe097          	auipc	ra,0xffffe
    800063f2:	134080e7          	jalr	308(ra) # 80004522 <iunlockput>
  end_op();
    800063f6:	fffff097          	auipc	ra,0xfffff
    800063fa:	c32080e7          	jalr	-974(ra) # 80005028 <end_op>
  return -1;
    800063fe:	57fd                	li	a5,-1
}
    80006400:	853e                	mv	a0,a5
    80006402:	70b2                	ld	ra,296(sp)
    80006404:	7412                	ld	s0,288(sp)
    80006406:	64f2                	ld	s1,280(sp)
    80006408:	6952                	ld	s2,272(sp)
    8000640a:	6155                	addi	sp,sp,304
    8000640c:	8082                	ret

000000008000640e <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000640e:	4578                	lw	a4,76(a0)
    80006410:	02000793          	li	a5,32
    80006414:	04e7fa63          	bgeu	a5,a4,80006468 <isdirempty+0x5a>
{
    80006418:	7179                	addi	sp,sp,-48
    8000641a:	f406                	sd	ra,40(sp)
    8000641c:	f022                	sd	s0,32(sp)
    8000641e:	ec26                	sd	s1,24(sp)
    80006420:	e84a                	sd	s2,16(sp)
    80006422:	1800                	addi	s0,sp,48
    80006424:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006426:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000642a:	4741                	li	a4,16
    8000642c:	86a6                	mv	a3,s1
    8000642e:	fd040613          	addi	a2,s0,-48
    80006432:	4581                	li	a1,0
    80006434:	854a                	mv	a0,s2
    80006436:	ffffe097          	auipc	ra,0xffffe
    8000643a:	13e080e7          	jalr	318(ra) # 80004574 <readi>
    8000643e:	47c1                	li	a5,16
    80006440:	00f51c63          	bne	a0,a5,80006458 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80006444:	fd045783          	lhu	a5,-48(s0)
    80006448:	e395                	bnez	a5,8000646c <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000644a:	24c1                	addiw	s1,s1,16
    8000644c:	04c92783          	lw	a5,76(s2)
    80006450:	fcf4ede3          	bltu	s1,a5,8000642a <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80006454:	4505                	li	a0,1
    80006456:	a821                	j	8000646e <isdirempty+0x60>
      panic("isdirempty: readi");
    80006458:	00003517          	auipc	a0,0x3
    8000645c:	4b050513          	addi	a0,a0,1200 # 80009908 <syscalls+0x310>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	0ca080e7          	jalr	202(ra) # 8000052a <panic>
  return 1;
    80006468:	4505                	li	a0,1
}
    8000646a:	8082                	ret
      return 0;
    8000646c:	4501                	li	a0,0
}
    8000646e:	70a2                	ld	ra,40(sp)
    80006470:	7402                	ld	s0,32(sp)
    80006472:	64e2                	ld	s1,24(sp)
    80006474:	6942                	ld	s2,16(sp)
    80006476:	6145                	addi	sp,sp,48
    80006478:	8082                	ret

000000008000647a <sys_unlink>:

uint64
sys_unlink(void)
{
    8000647a:	7155                	addi	sp,sp,-208
    8000647c:	e586                	sd	ra,200(sp)
    8000647e:	e1a2                	sd	s0,192(sp)
    80006480:	fd26                	sd	s1,184(sp)
    80006482:	f94a                	sd	s2,176(sp)
    80006484:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006486:	08000613          	li	a2,128
    8000648a:	f4040593          	addi	a1,s0,-192
    8000648e:	4501                	li	a0,0
    80006490:	ffffd097          	auipc	ra,0xffffd
    80006494:	302080e7          	jalr	770(ra) # 80003792 <argstr>
    80006498:	16054363          	bltz	a0,800065fe <sys_unlink+0x184>
    return -1;

  begin_op();
    8000649c:	fffff097          	auipc	ra,0xfffff
    800064a0:	b0c080e7          	jalr	-1268(ra) # 80004fa8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800064a4:	fc040593          	addi	a1,s0,-64
    800064a8:	f4040513          	addi	a0,s0,-192
    800064ac:	ffffe097          	auipc	ra,0xffffe
    800064b0:	5e8080e7          	jalr	1512(ra) # 80004a94 <nameiparent>
    800064b4:	84aa                	mv	s1,a0
    800064b6:	c961                	beqz	a0,80006586 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    800064b8:	ffffe097          	auipc	ra,0xffffe
    800064bc:	e08080e7          	jalr	-504(ra) # 800042c0 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800064c0:	00003597          	auipc	a1,0x3
    800064c4:	32858593          	addi	a1,a1,808 # 800097e8 <syscalls+0x1f0>
    800064c8:	fc040513          	addi	a0,s0,-64
    800064cc:	ffffe097          	auipc	ra,0xffffe
    800064d0:	2be080e7          	jalr	702(ra) # 8000478a <namecmp>
    800064d4:	c175                	beqz	a0,800065b8 <sys_unlink+0x13e>
    800064d6:	00003597          	auipc	a1,0x3
    800064da:	31a58593          	addi	a1,a1,794 # 800097f0 <syscalls+0x1f8>
    800064de:	fc040513          	addi	a0,s0,-64
    800064e2:	ffffe097          	auipc	ra,0xffffe
    800064e6:	2a8080e7          	jalr	680(ra) # 8000478a <namecmp>
    800064ea:	c579                	beqz	a0,800065b8 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    800064ec:	f3c40613          	addi	a2,s0,-196
    800064f0:	fc040593          	addi	a1,s0,-64
    800064f4:	8526                	mv	a0,s1
    800064f6:	ffffe097          	auipc	ra,0xffffe
    800064fa:	2ae080e7          	jalr	686(ra) # 800047a4 <dirlookup>
    800064fe:	892a                	mv	s2,a0
    80006500:	cd45                	beqz	a0,800065b8 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80006502:	ffffe097          	auipc	ra,0xffffe
    80006506:	dbe080e7          	jalr	-578(ra) # 800042c0 <ilock>

  if(ip->nlink < 1)
    8000650a:	04a91783          	lh	a5,74(s2)
    8000650e:	08f05263          	blez	a5,80006592 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006512:	04491703          	lh	a4,68(s2)
    80006516:	4785                	li	a5,1
    80006518:	08f70563          	beq	a4,a5,800065a2 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    8000651c:	4641                	li	a2,16
    8000651e:	4581                	li	a1,0
    80006520:	fd040513          	addi	a0,s0,-48
    80006524:	ffffa097          	auipc	ra,0xffffa
    80006528:	7aa080e7          	jalr	1962(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000652c:	4741                	li	a4,16
    8000652e:	f3c42683          	lw	a3,-196(s0)
    80006532:	fd040613          	addi	a2,s0,-48
    80006536:	4581                	li	a1,0
    80006538:	8526                	mv	a0,s1
    8000653a:	ffffe097          	auipc	ra,0xffffe
    8000653e:	132080e7          	jalr	306(ra) # 8000466c <writei>
    80006542:	47c1                	li	a5,16
    80006544:	08f51a63          	bne	a0,a5,800065d8 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80006548:	04491703          	lh	a4,68(s2)
    8000654c:	4785                	li	a5,1
    8000654e:	08f70d63          	beq	a4,a5,800065e8 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80006552:	8526                	mv	a0,s1
    80006554:	ffffe097          	auipc	ra,0xffffe
    80006558:	fce080e7          	jalr	-50(ra) # 80004522 <iunlockput>

  ip->nlink--;
    8000655c:	04a95783          	lhu	a5,74(s2)
    80006560:	37fd                	addiw	a5,a5,-1
    80006562:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006566:	854a                	mv	a0,s2
    80006568:	ffffe097          	auipc	ra,0xffffe
    8000656c:	c8e080e7          	jalr	-882(ra) # 800041f6 <iupdate>
  iunlockput(ip);
    80006570:	854a                	mv	a0,s2
    80006572:	ffffe097          	auipc	ra,0xffffe
    80006576:	fb0080e7          	jalr	-80(ra) # 80004522 <iunlockput>

  end_op();
    8000657a:	fffff097          	auipc	ra,0xfffff
    8000657e:	aae080e7          	jalr	-1362(ra) # 80005028 <end_op>

  return 0;
    80006582:	4501                	li	a0,0
    80006584:	a0a1                	j	800065cc <sys_unlink+0x152>
    end_op();
    80006586:	fffff097          	auipc	ra,0xfffff
    8000658a:	aa2080e7          	jalr	-1374(ra) # 80005028 <end_op>
    return -1;
    8000658e:	557d                	li	a0,-1
    80006590:	a835                	j	800065cc <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80006592:	00003517          	auipc	a0,0x3
    80006596:	26650513          	addi	a0,a0,614 # 800097f8 <syscalls+0x200>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	f90080e7          	jalr	-112(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800065a2:	854a                	mv	a0,s2
    800065a4:	00000097          	auipc	ra,0x0
    800065a8:	e6a080e7          	jalr	-406(ra) # 8000640e <isdirempty>
    800065ac:	f925                	bnez	a0,8000651c <sys_unlink+0xa2>
    iunlockput(ip);
    800065ae:	854a                	mv	a0,s2
    800065b0:	ffffe097          	auipc	ra,0xffffe
    800065b4:	f72080e7          	jalr	-142(ra) # 80004522 <iunlockput>

bad:
  iunlockput(dp);
    800065b8:	8526                	mv	a0,s1
    800065ba:	ffffe097          	auipc	ra,0xffffe
    800065be:	f68080e7          	jalr	-152(ra) # 80004522 <iunlockput>
  end_op();
    800065c2:	fffff097          	auipc	ra,0xfffff
    800065c6:	a66080e7          	jalr	-1434(ra) # 80005028 <end_op>
  return -1;
    800065ca:	557d                	li	a0,-1
}
    800065cc:	60ae                	ld	ra,200(sp)
    800065ce:	640e                	ld	s0,192(sp)
    800065d0:	74ea                	ld	s1,184(sp)
    800065d2:	794a                	ld	s2,176(sp)
    800065d4:	6169                	addi	sp,sp,208
    800065d6:	8082                	ret
    panic("unlink: writei");
    800065d8:	00003517          	auipc	a0,0x3
    800065dc:	23850513          	addi	a0,a0,568 # 80009810 <syscalls+0x218>
    800065e0:	ffffa097          	auipc	ra,0xffffa
    800065e4:	f4a080e7          	jalr	-182(ra) # 8000052a <panic>
    dp->nlink--;
    800065e8:	04a4d783          	lhu	a5,74(s1)
    800065ec:	37fd                	addiw	a5,a5,-1
    800065ee:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800065f2:	8526                	mv	a0,s1
    800065f4:	ffffe097          	auipc	ra,0xffffe
    800065f8:	c02080e7          	jalr	-1022(ra) # 800041f6 <iupdate>
    800065fc:	bf99                	j	80006552 <sys_unlink+0xd8>
    return -1;
    800065fe:	557d                	li	a0,-1
    80006600:	b7f1                	j	800065cc <sys_unlink+0x152>

0000000080006602 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006602:	715d                	addi	sp,sp,-80
    80006604:	e486                	sd	ra,72(sp)
    80006606:	e0a2                	sd	s0,64(sp)
    80006608:	fc26                	sd	s1,56(sp)
    8000660a:	f84a                	sd	s2,48(sp)
    8000660c:	f44e                	sd	s3,40(sp)
    8000660e:	f052                	sd	s4,32(sp)
    80006610:	ec56                	sd	s5,24(sp)
    80006612:	0880                	addi	s0,sp,80
    80006614:	89ae                	mv	s3,a1
    80006616:	8ab2                	mv	s5,a2
    80006618:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000661a:	fb040593          	addi	a1,s0,-80
    8000661e:	ffffe097          	auipc	ra,0xffffe
    80006622:	476080e7          	jalr	1142(ra) # 80004a94 <nameiparent>
    80006626:	892a                	mv	s2,a0
    80006628:	12050e63          	beqz	a0,80006764 <create+0x162>
    return 0;

  ilock(dp);
    8000662c:	ffffe097          	auipc	ra,0xffffe
    80006630:	c94080e7          	jalr	-876(ra) # 800042c0 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006634:	4601                	li	a2,0
    80006636:	fb040593          	addi	a1,s0,-80
    8000663a:	854a                	mv	a0,s2
    8000663c:	ffffe097          	auipc	ra,0xffffe
    80006640:	168080e7          	jalr	360(ra) # 800047a4 <dirlookup>
    80006644:	84aa                	mv	s1,a0
    80006646:	c921                	beqz	a0,80006696 <create+0x94>
    iunlockput(dp);
    80006648:	854a                	mv	a0,s2
    8000664a:	ffffe097          	auipc	ra,0xffffe
    8000664e:	ed8080e7          	jalr	-296(ra) # 80004522 <iunlockput>
    ilock(ip);
    80006652:	8526                	mv	a0,s1
    80006654:	ffffe097          	auipc	ra,0xffffe
    80006658:	c6c080e7          	jalr	-916(ra) # 800042c0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000665c:	2981                	sext.w	s3,s3
    8000665e:	4789                	li	a5,2
    80006660:	02f99463          	bne	s3,a5,80006688 <create+0x86>
    80006664:	0444d783          	lhu	a5,68(s1)
    80006668:	37f9                	addiw	a5,a5,-2
    8000666a:	17c2                	slli	a5,a5,0x30
    8000666c:	93c1                	srli	a5,a5,0x30
    8000666e:	4705                	li	a4,1
    80006670:	00f76c63          	bltu	a4,a5,80006688 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006674:	8526                	mv	a0,s1
    80006676:	60a6                	ld	ra,72(sp)
    80006678:	6406                	ld	s0,64(sp)
    8000667a:	74e2                	ld	s1,56(sp)
    8000667c:	7942                	ld	s2,48(sp)
    8000667e:	79a2                	ld	s3,40(sp)
    80006680:	7a02                	ld	s4,32(sp)
    80006682:	6ae2                	ld	s5,24(sp)
    80006684:	6161                	addi	sp,sp,80
    80006686:	8082                	ret
    iunlockput(ip);
    80006688:	8526                	mv	a0,s1
    8000668a:	ffffe097          	auipc	ra,0xffffe
    8000668e:	e98080e7          	jalr	-360(ra) # 80004522 <iunlockput>
    return 0;
    80006692:	4481                	li	s1,0
    80006694:	b7c5                	j	80006674 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006696:	85ce                	mv	a1,s3
    80006698:	00092503          	lw	a0,0(s2)
    8000669c:	ffffe097          	auipc	ra,0xffffe
    800066a0:	a8c080e7          	jalr	-1396(ra) # 80004128 <ialloc>
    800066a4:	84aa                	mv	s1,a0
    800066a6:	c521                	beqz	a0,800066ee <create+0xec>
  ilock(ip);
    800066a8:	ffffe097          	auipc	ra,0xffffe
    800066ac:	c18080e7          	jalr	-1000(ra) # 800042c0 <ilock>
  ip->major = major;
    800066b0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800066b4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800066b8:	4a05                	li	s4,1
    800066ba:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    800066be:	8526                	mv	a0,s1
    800066c0:	ffffe097          	auipc	ra,0xffffe
    800066c4:	b36080e7          	jalr	-1226(ra) # 800041f6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800066c8:	2981                	sext.w	s3,s3
    800066ca:	03498a63          	beq	s3,s4,800066fe <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800066ce:	40d0                	lw	a2,4(s1)
    800066d0:	fb040593          	addi	a1,s0,-80
    800066d4:	854a                	mv	a0,s2
    800066d6:	ffffe097          	auipc	ra,0xffffe
    800066da:	2de080e7          	jalr	734(ra) # 800049b4 <dirlink>
    800066de:	06054b63          	bltz	a0,80006754 <create+0x152>
  iunlockput(dp);
    800066e2:	854a                	mv	a0,s2
    800066e4:	ffffe097          	auipc	ra,0xffffe
    800066e8:	e3e080e7          	jalr	-450(ra) # 80004522 <iunlockput>
  return ip;
    800066ec:	b761                	j	80006674 <create+0x72>
    panic("create: ialloc");
    800066ee:	00003517          	auipc	a0,0x3
    800066f2:	23250513          	addi	a0,a0,562 # 80009920 <syscalls+0x328>
    800066f6:	ffffa097          	auipc	ra,0xffffa
    800066fa:	e34080e7          	jalr	-460(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    800066fe:	04a95783          	lhu	a5,74(s2)
    80006702:	2785                	addiw	a5,a5,1
    80006704:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006708:	854a                	mv	a0,s2
    8000670a:	ffffe097          	auipc	ra,0xffffe
    8000670e:	aec080e7          	jalr	-1300(ra) # 800041f6 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006712:	40d0                	lw	a2,4(s1)
    80006714:	00003597          	auipc	a1,0x3
    80006718:	0d458593          	addi	a1,a1,212 # 800097e8 <syscalls+0x1f0>
    8000671c:	8526                	mv	a0,s1
    8000671e:	ffffe097          	auipc	ra,0xffffe
    80006722:	296080e7          	jalr	662(ra) # 800049b4 <dirlink>
    80006726:	00054f63          	bltz	a0,80006744 <create+0x142>
    8000672a:	00492603          	lw	a2,4(s2)
    8000672e:	00003597          	auipc	a1,0x3
    80006732:	0c258593          	addi	a1,a1,194 # 800097f0 <syscalls+0x1f8>
    80006736:	8526                	mv	a0,s1
    80006738:	ffffe097          	auipc	ra,0xffffe
    8000673c:	27c080e7          	jalr	636(ra) # 800049b4 <dirlink>
    80006740:	f80557e3          	bgez	a0,800066ce <create+0xcc>
      panic("create dots");
    80006744:	00003517          	auipc	a0,0x3
    80006748:	1ec50513          	addi	a0,a0,492 # 80009930 <syscalls+0x338>
    8000674c:	ffffa097          	auipc	ra,0xffffa
    80006750:	dde080e7          	jalr	-546(ra) # 8000052a <panic>
    panic("create: dirlink");
    80006754:	00003517          	auipc	a0,0x3
    80006758:	1ec50513          	addi	a0,a0,492 # 80009940 <syscalls+0x348>
    8000675c:	ffffa097          	auipc	ra,0xffffa
    80006760:	dce080e7          	jalr	-562(ra) # 8000052a <panic>
    return 0;
    80006764:	84aa                	mv	s1,a0
    80006766:	b739                	j	80006674 <create+0x72>

0000000080006768 <sys_open>:

uint64
sys_open(void)
{
    80006768:	7131                	addi	sp,sp,-192
    8000676a:	fd06                	sd	ra,184(sp)
    8000676c:	f922                	sd	s0,176(sp)
    8000676e:	f526                	sd	s1,168(sp)
    80006770:	f14a                	sd	s2,160(sp)
    80006772:	ed4e                	sd	s3,152(sp)
    80006774:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006776:	08000613          	li	a2,128
    8000677a:	f5040593          	addi	a1,s0,-176
    8000677e:	4501                	li	a0,0
    80006780:	ffffd097          	auipc	ra,0xffffd
    80006784:	012080e7          	jalr	18(ra) # 80003792 <argstr>
    return -1;
    80006788:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000678a:	0c054163          	bltz	a0,8000684c <sys_open+0xe4>
    8000678e:	f4c40593          	addi	a1,s0,-180
    80006792:	4505                	li	a0,1
    80006794:	ffffd097          	auipc	ra,0xffffd
    80006798:	fba080e7          	jalr	-70(ra) # 8000374e <argint>
    8000679c:	0a054863          	bltz	a0,8000684c <sys_open+0xe4>

  begin_op();
    800067a0:	fffff097          	auipc	ra,0xfffff
    800067a4:	808080e7          	jalr	-2040(ra) # 80004fa8 <begin_op>

  if(omode & O_CREATE){
    800067a8:	f4c42783          	lw	a5,-180(s0)
    800067ac:	2007f793          	andi	a5,a5,512
    800067b0:	cbdd                	beqz	a5,80006866 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800067b2:	4681                	li	a3,0
    800067b4:	4601                	li	a2,0
    800067b6:	4589                	li	a1,2
    800067b8:	f5040513          	addi	a0,s0,-176
    800067bc:	00000097          	auipc	ra,0x0
    800067c0:	e46080e7          	jalr	-442(ra) # 80006602 <create>
    800067c4:	892a                	mv	s2,a0
    if(ip == 0){
    800067c6:	c959                	beqz	a0,8000685c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800067c8:	04491703          	lh	a4,68(s2)
    800067cc:	478d                	li	a5,3
    800067ce:	00f71763          	bne	a4,a5,800067dc <sys_open+0x74>
    800067d2:	04695703          	lhu	a4,70(s2)
    800067d6:	47a5                	li	a5,9
    800067d8:	0ce7ec63          	bltu	a5,a4,800068b0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800067dc:	fffff097          	auipc	ra,0xfffff
    800067e0:	bdc080e7          	jalr	-1060(ra) # 800053b8 <filealloc>
    800067e4:	89aa                	mv	s3,a0
    800067e6:	10050263          	beqz	a0,800068ea <sys_open+0x182>
    800067ea:	00000097          	auipc	ra,0x0
    800067ee:	8e2080e7          	jalr	-1822(ra) # 800060cc <fdalloc>
    800067f2:	84aa                	mv	s1,a0
    800067f4:	0e054663          	bltz	a0,800068e0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800067f8:	04491703          	lh	a4,68(s2)
    800067fc:	478d                	li	a5,3
    800067fe:	0cf70463          	beq	a4,a5,800068c6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006802:	4789                	li	a5,2
    80006804:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006808:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000680c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006810:	f4c42783          	lw	a5,-180(s0)
    80006814:	0017c713          	xori	a4,a5,1
    80006818:	8b05                	andi	a4,a4,1
    8000681a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000681e:	0037f713          	andi	a4,a5,3
    80006822:	00e03733          	snez	a4,a4
    80006826:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000682a:	4007f793          	andi	a5,a5,1024
    8000682e:	c791                	beqz	a5,8000683a <sys_open+0xd2>
    80006830:	04491703          	lh	a4,68(s2)
    80006834:	4789                	li	a5,2
    80006836:	08f70f63          	beq	a4,a5,800068d4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000683a:	854a                	mv	a0,s2
    8000683c:	ffffe097          	auipc	ra,0xffffe
    80006840:	b46080e7          	jalr	-1210(ra) # 80004382 <iunlock>
  end_op();
    80006844:	ffffe097          	auipc	ra,0xffffe
    80006848:	7e4080e7          	jalr	2020(ra) # 80005028 <end_op>

  return fd;
}
    8000684c:	8526                	mv	a0,s1
    8000684e:	70ea                	ld	ra,184(sp)
    80006850:	744a                	ld	s0,176(sp)
    80006852:	74aa                	ld	s1,168(sp)
    80006854:	790a                	ld	s2,160(sp)
    80006856:	69ea                	ld	s3,152(sp)
    80006858:	6129                	addi	sp,sp,192
    8000685a:	8082                	ret
      end_op();
    8000685c:	ffffe097          	auipc	ra,0xffffe
    80006860:	7cc080e7          	jalr	1996(ra) # 80005028 <end_op>
      return -1;
    80006864:	b7e5                	j	8000684c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006866:	f5040513          	addi	a0,s0,-176
    8000686a:	ffffe097          	auipc	ra,0xffffe
    8000686e:	20c080e7          	jalr	524(ra) # 80004a76 <namei>
    80006872:	892a                	mv	s2,a0
    80006874:	c905                	beqz	a0,800068a4 <sys_open+0x13c>
    ilock(ip);
    80006876:	ffffe097          	auipc	ra,0xffffe
    8000687a:	a4a080e7          	jalr	-1462(ra) # 800042c0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000687e:	04491703          	lh	a4,68(s2)
    80006882:	4785                	li	a5,1
    80006884:	f4f712e3          	bne	a4,a5,800067c8 <sys_open+0x60>
    80006888:	f4c42783          	lw	a5,-180(s0)
    8000688c:	dba1                	beqz	a5,800067dc <sys_open+0x74>
      iunlockput(ip);
    8000688e:	854a                	mv	a0,s2
    80006890:	ffffe097          	auipc	ra,0xffffe
    80006894:	c92080e7          	jalr	-878(ra) # 80004522 <iunlockput>
      end_op();
    80006898:	ffffe097          	auipc	ra,0xffffe
    8000689c:	790080e7          	jalr	1936(ra) # 80005028 <end_op>
      return -1;
    800068a0:	54fd                	li	s1,-1
    800068a2:	b76d                	j	8000684c <sys_open+0xe4>
      end_op();
    800068a4:	ffffe097          	auipc	ra,0xffffe
    800068a8:	784080e7          	jalr	1924(ra) # 80005028 <end_op>
      return -1;
    800068ac:	54fd                	li	s1,-1
    800068ae:	bf79                	j	8000684c <sys_open+0xe4>
    iunlockput(ip);
    800068b0:	854a                	mv	a0,s2
    800068b2:	ffffe097          	auipc	ra,0xffffe
    800068b6:	c70080e7          	jalr	-912(ra) # 80004522 <iunlockput>
    end_op();
    800068ba:	ffffe097          	auipc	ra,0xffffe
    800068be:	76e080e7          	jalr	1902(ra) # 80005028 <end_op>
    return -1;
    800068c2:	54fd                	li	s1,-1
    800068c4:	b761                	j	8000684c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800068c6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800068ca:	04691783          	lh	a5,70(s2)
    800068ce:	02f99223          	sh	a5,36(s3)
    800068d2:	bf2d                	j	8000680c <sys_open+0xa4>
    itrunc(ip);
    800068d4:	854a                	mv	a0,s2
    800068d6:	ffffe097          	auipc	ra,0xffffe
    800068da:	af8080e7          	jalr	-1288(ra) # 800043ce <itrunc>
    800068de:	bfb1                	j	8000683a <sys_open+0xd2>
      fileclose(f);
    800068e0:	854e                	mv	a0,s3
    800068e2:	fffff097          	auipc	ra,0xfffff
    800068e6:	b92080e7          	jalr	-1134(ra) # 80005474 <fileclose>
    iunlockput(ip);
    800068ea:	854a                	mv	a0,s2
    800068ec:	ffffe097          	auipc	ra,0xffffe
    800068f0:	c36080e7          	jalr	-970(ra) # 80004522 <iunlockput>
    end_op();
    800068f4:	ffffe097          	auipc	ra,0xffffe
    800068f8:	734080e7          	jalr	1844(ra) # 80005028 <end_op>
    return -1;
    800068fc:	54fd                	li	s1,-1
    800068fe:	b7b9                	j	8000684c <sys_open+0xe4>

0000000080006900 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006900:	7175                	addi	sp,sp,-144
    80006902:	e506                	sd	ra,136(sp)
    80006904:	e122                	sd	s0,128(sp)
    80006906:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006908:	ffffe097          	auipc	ra,0xffffe
    8000690c:	6a0080e7          	jalr	1696(ra) # 80004fa8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006910:	08000613          	li	a2,128
    80006914:	f7040593          	addi	a1,s0,-144
    80006918:	4501                	li	a0,0
    8000691a:	ffffd097          	auipc	ra,0xffffd
    8000691e:	e78080e7          	jalr	-392(ra) # 80003792 <argstr>
    80006922:	02054963          	bltz	a0,80006954 <sys_mkdir+0x54>
    80006926:	4681                	li	a3,0
    80006928:	4601                	li	a2,0
    8000692a:	4585                	li	a1,1
    8000692c:	f7040513          	addi	a0,s0,-144
    80006930:	00000097          	auipc	ra,0x0
    80006934:	cd2080e7          	jalr	-814(ra) # 80006602 <create>
    80006938:	cd11                	beqz	a0,80006954 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000693a:	ffffe097          	auipc	ra,0xffffe
    8000693e:	be8080e7          	jalr	-1048(ra) # 80004522 <iunlockput>
  end_op();
    80006942:	ffffe097          	auipc	ra,0xffffe
    80006946:	6e6080e7          	jalr	1766(ra) # 80005028 <end_op>
  return 0;
    8000694a:	4501                	li	a0,0
}
    8000694c:	60aa                	ld	ra,136(sp)
    8000694e:	640a                	ld	s0,128(sp)
    80006950:	6149                	addi	sp,sp,144
    80006952:	8082                	ret
    end_op();
    80006954:	ffffe097          	auipc	ra,0xffffe
    80006958:	6d4080e7          	jalr	1748(ra) # 80005028 <end_op>
    return -1;
    8000695c:	557d                	li	a0,-1
    8000695e:	b7fd                	j	8000694c <sys_mkdir+0x4c>

0000000080006960 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006960:	7135                	addi	sp,sp,-160
    80006962:	ed06                	sd	ra,152(sp)
    80006964:	e922                	sd	s0,144(sp)
    80006966:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006968:	ffffe097          	auipc	ra,0xffffe
    8000696c:	640080e7          	jalr	1600(ra) # 80004fa8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006970:	08000613          	li	a2,128
    80006974:	f7040593          	addi	a1,s0,-144
    80006978:	4501                	li	a0,0
    8000697a:	ffffd097          	auipc	ra,0xffffd
    8000697e:	e18080e7          	jalr	-488(ra) # 80003792 <argstr>
    80006982:	04054a63          	bltz	a0,800069d6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006986:	f6c40593          	addi	a1,s0,-148
    8000698a:	4505                	li	a0,1
    8000698c:	ffffd097          	auipc	ra,0xffffd
    80006990:	dc2080e7          	jalr	-574(ra) # 8000374e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006994:	04054163          	bltz	a0,800069d6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006998:	f6840593          	addi	a1,s0,-152
    8000699c:	4509                	li	a0,2
    8000699e:	ffffd097          	auipc	ra,0xffffd
    800069a2:	db0080e7          	jalr	-592(ra) # 8000374e <argint>
     argint(1, &major) < 0 ||
    800069a6:	02054863          	bltz	a0,800069d6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800069aa:	f6841683          	lh	a3,-152(s0)
    800069ae:	f6c41603          	lh	a2,-148(s0)
    800069b2:	458d                	li	a1,3
    800069b4:	f7040513          	addi	a0,s0,-144
    800069b8:	00000097          	auipc	ra,0x0
    800069bc:	c4a080e7          	jalr	-950(ra) # 80006602 <create>
     argint(2, &minor) < 0 ||
    800069c0:	c919                	beqz	a0,800069d6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800069c2:	ffffe097          	auipc	ra,0xffffe
    800069c6:	b60080e7          	jalr	-1184(ra) # 80004522 <iunlockput>
  end_op();
    800069ca:	ffffe097          	auipc	ra,0xffffe
    800069ce:	65e080e7          	jalr	1630(ra) # 80005028 <end_op>
  return 0;
    800069d2:	4501                	li	a0,0
    800069d4:	a031                	j	800069e0 <sys_mknod+0x80>
    end_op();
    800069d6:	ffffe097          	auipc	ra,0xffffe
    800069da:	652080e7          	jalr	1618(ra) # 80005028 <end_op>
    return -1;
    800069de:	557d                	li	a0,-1
}
    800069e0:	60ea                	ld	ra,152(sp)
    800069e2:	644a                	ld	s0,144(sp)
    800069e4:	610d                	addi	sp,sp,160
    800069e6:	8082                	ret

00000000800069e8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800069e8:	7135                	addi	sp,sp,-160
    800069ea:	ed06                	sd	ra,152(sp)
    800069ec:	e922                	sd	s0,144(sp)
    800069ee:	e526                	sd	s1,136(sp)
    800069f0:	e14a                	sd	s2,128(sp)
    800069f2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800069f4:	ffffc097          	auipc	ra,0xffffc
    800069f8:	a0e080e7          	jalr	-1522(ra) # 80002402 <myproc>
    800069fc:	892a                	mv	s2,a0
  
  begin_op();
    800069fe:	ffffe097          	auipc	ra,0xffffe
    80006a02:	5aa080e7          	jalr	1450(ra) # 80004fa8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006a06:	08000613          	li	a2,128
    80006a0a:	f6040593          	addi	a1,s0,-160
    80006a0e:	4501                	li	a0,0
    80006a10:	ffffd097          	auipc	ra,0xffffd
    80006a14:	d82080e7          	jalr	-638(ra) # 80003792 <argstr>
    80006a18:	04054b63          	bltz	a0,80006a6e <sys_chdir+0x86>
    80006a1c:	f6040513          	addi	a0,s0,-160
    80006a20:	ffffe097          	auipc	ra,0xffffe
    80006a24:	056080e7          	jalr	86(ra) # 80004a76 <namei>
    80006a28:	84aa                	mv	s1,a0
    80006a2a:	c131                	beqz	a0,80006a6e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006a2c:	ffffe097          	auipc	ra,0xffffe
    80006a30:	894080e7          	jalr	-1900(ra) # 800042c0 <ilock>
  if(ip->type != T_DIR){
    80006a34:	04449703          	lh	a4,68(s1)
    80006a38:	4785                	li	a5,1
    80006a3a:	04f71063          	bne	a4,a5,80006a7a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006a3e:	8526                	mv	a0,s1
    80006a40:	ffffe097          	auipc	ra,0xffffe
    80006a44:	942080e7          	jalr	-1726(ra) # 80004382 <iunlock>
  iput(p->cwd);
    80006a48:	15093503          	ld	a0,336(s2)
    80006a4c:	ffffe097          	auipc	ra,0xffffe
    80006a50:	a2e080e7          	jalr	-1490(ra) # 8000447a <iput>
  end_op();
    80006a54:	ffffe097          	auipc	ra,0xffffe
    80006a58:	5d4080e7          	jalr	1492(ra) # 80005028 <end_op>
  p->cwd = ip;
    80006a5c:	14993823          	sd	s1,336(s2)
  return 0;
    80006a60:	4501                	li	a0,0
}
    80006a62:	60ea                	ld	ra,152(sp)
    80006a64:	644a                	ld	s0,144(sp)
    80006a66:	64aa                	ld	s1,136(sp)
    80006a68:	690a                	ld	s2,128(sp)
    80006a6a:	610d                	addi	sp,sp,160
    80006a6c:	8082                	ret
    end_op();
    80006a6e:	ffffe097          	auipc	ra,0xffffe
    80006a72:	5ba080e7          	jalr	1466(ra) # 80005028 <end_op>
    return -1;
    80006a76:	557d                	li	a0,-1
    80006a78:	b7ed                	j	80006a62 <sys_chdir+0x7a>
    iunlockput(ip);
    80006a7a:	8526                	mv	a0,s1
    80006a7c:	ffffe097          	auipc	ra,0xffffe
    80006a80:	aa6080e7          	jalr	-1370(ra) # 80004522 <iunlockput>
    end_op();
    80006a84:	ffffe097          	auipc	ra,0xffffe
    80006a88:	5a4080e7          	jalr	1444(ra) # 80005028 <end_op>
    return -1;
    80006a8c:	557d                	li	a0,-1
    80006a8e:	bfd1                	j	80006a62 <sys_chdir+0x7a>

0000000080006a90 <sys_exec>:

uint64
sys_exec(void)
{
    80006a90:	7145                	addi	sp,sp,-464
    80006a92:	e786                	sd	ra,456(sp)
    80006a94:	e3a2                	sd	s0,448(sp)
    80006a96:	ff26                	sd	s1,440(sp)
    80006a98:	fb4a                	sd	s2,432(sp)
    80006a9a:	f74e                	sd	s3,424(sp)
    80006a9c:	f352                	sd	s4,416(sp)
    80006a9e:	ef56                	sd	s5,408(sp)
    80006aa0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006aa2:	08000613          	li	a2,128
    80006aa6:	f4040593          	addi	a1,s0,-192
    80006aaa:	4501                	li	a0,0
    80006aac:	ffffd097          	auipc	ra,0xffffd
    80006ab0:	ce6080e7          	jalr	-794(ra) # 80003792 <argstr>
    return -1;
    80006ab4:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006ab6:	0c054a63          	bltz	a0,80006b8a <sys_exec+0xfa>
    80006aba:	e3840593          	addi	a1,s0,-456
    80006abe:	4505                	li	a0,1
    80006ac0:	ffffd097          	auipc	ra,0xffffd
    80006ac4:	cb0080e7          	jalr	-848(ra) # 80003770 <argaddr>
    80006ac8:	0c054163          	bltz	a0,80006b8a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006acc:	10000613          	li	a2,256
    80006ad0:	4581                	li	a1,0
    80006ad2:	e4040513          	addi	a0,s0,-448
    80006ad6:	ffffa097          	auipc	ra,0xffffa
    80006ada:	1f8080e7          	jalr	504(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006ade:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006ae2:	89a6                	mv	s3,s1
    80006ae4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006ae6:	02000a13          	li	s4,32
    80006aea:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006aee:	00391793          	slli	a5,s2,0x3
    80006af2:	e3040593          	addi	a1,s0,-464
    80006af6:	e3843503          	ld	a0,-456(s0)
    80006afa:	953e                	add	a0,a0,a5
    80006afc:	ffffd097          	auipc	ra,0xffffd
    80006b00:	bb8080e7          	jalr	-1096(ra) # 800036b4 <fetchaddr>
    80006b04:	02054a63          	bltz	a0,80006b38 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006b08:	e3043783          	ld	a5,-464(s0)
    80006b0c:	c3b9                	beqz	a5,80006b52 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006b0e:	ffffa097          	auipc	ra,0xffffa
    80006b12:	fd4080e7          	jalr	-44(ra) # 80000ae2 <kalloc>
    80006b16:	85aa                	mv	a1,a0
    80006b18:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006b1c:	cd11                	beqz	a0,80006b38 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006b1e:	6605                	lui	a2,0x1
    80006b20:	e3043503          	ld	a0,-464(s0)
    80006b24:	ffffd097          	auipc	ra,0xffffd
    80006b28:	be2080e7          	jalr	-1054(ra) # 80003706 <fetchstr>
    80006b2c:	00054663          	bltz	a0,80006b38 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006b30:	0905                	addi	s2,s2,1
    80006b32:	09a1                	addi	s3,s3,8
    80006b34:	fb491be3          	bne	s2,s4,80006aea <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b38:	10048913          	addi	s2,s1,256
    80006b3c:	6088                	ld	a0,0(s1)
    80006b3e:	c529                	beqz	a0,80006b88 <sys_exec+0xf8>
    kfree(argv[i]);
    80006b40:	ffffa097          	auipc	ra,0xffffa
    80006b44:	e96080e7          	jalr	-362(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b48:	04a1                	addi	s1,s1,8
    80006b4a:	ff2499e3          	bne	s1,s2,80006b3c <sys_exec+0xac>
  return -1;
    80006b4e:	597d                	li	s2,-1
    80006b50:	a82d                	j	80006b8a <sys_exec+0xfa>
      argv[i] = 0;
    80006b52:	0a8e                	slli	s5,s5,0x3
    80006b54:	fc040793          	addi	a5,s0,-64
    80006b58:	9abe                	add	s5,s5,a5
    80006b5a:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffcfe80>
  int ret = exec(path, argv);
    80006b5e:	e4040593          	addi	a1,s0,-448
    80006b62:	f4040513          	addi	a0,s0,-192
    80006b66:	fffff097          	auipc	ra,0xfffff
    80006b6a:	156080e7          	jalr	342(ra) # 80005cbc <exec>
    80006b6e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b70:	10048993          	addi	s3,s1,256
    80006b74:	6088                	ld	a0,0(s1)
    80006b76:	c911                	beqz	a0,80006b8a <sys_exec+0xfa>
    kfree(argv[i]);
    80006b78:	ffffa097          	auipc	ra,0xffffa
    80006b7c:	e5e080e7          	jalr	-418(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b80:	04a1                	addi	s1,s1,8
    80006b82:	ff3499e3          	bne	s1,s3,80006b74 <sys_exec+0xe4>
    80006b86:	a011                	j	80006b8a <sys_exec+0xfa>
  return -1;
    80006b88:	597d                	li	s2,-1
}
    80006b8a:	854a                	mv	a0,s2
    80006b8c:	60be                	ld	ra,456(sp)
    80006b8e:	641e                	ld	s0,448(sp)
    80006b90:	74fa                	ld	s1,440(sp)
    80006b92:	795a                	ld	s2,432(sp)
    80006b94:	79ba                	ld	s3,424(sp)
    80006b96:	7a1a                	ld	s4,416(sp)
    80006b98:	6afa                	ld	s5,408(sp)
    80006b9a:	6179                	addi	sp,sp,464
    80006b9c:	8082                	ret

0000000080006b9e <sys_pipe>:

uint64
sys_pipe(void)
{
    80006b9e:	7139                	addi	sp,sp,-64
    80006ba0:	fc06                	sd	ra,56(sp)
    80006ba2:	f822                	sd	s0,48(sp)
    80006ba4:	f426                	sd	s1,40(sp)
    80006ba6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006ba8:	ffffc097          	auipc	ra,0xffffc
    80006bac:	85a080e7          	jalr	-1958(ra) # 80002402 <myproc>
    80006bb0:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006bb2:	fd840593          	addi	a1,s0,-40
    80006bb6:	4501                	li	a0,0
    80006bb8:	ffffd097          	auipc	ra,0xffffd
    80006bbc:	bb8080e7          	jalr	-1096(ra) # 80003770 <argaddr>
    return -1;
    80006bc0:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006bc2:	0e054063          	bltz	a0,80006ca2 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006bc6:	fc840593          	addi	a1,s0,-56
    80006bca:	fd040513          	addi	a0,s0,-48
    80006bce:	fffff097          	auipc	ra,0xfffff
    80006bd2:	dcc080e7          	jalr	-564(ra) # 8000599a <pipealloc>
    return -1;
    80006bd6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006bd8:	0c054563          	bltz	a0,80006ca2 <sys_pipe+0x104>
  fd0 = -1;
    80006bdc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006be0:	fd043503          	ld	a0,-48(s0)
    80006be4:	fffff097          	auipc	ra,0xfffff
    80006be8:	4e8080e7          	jalr	1256(ra) # 800060cc <fdalloc>
    80006bec:	fca42223          	sw	a0,-60(s0)
    80006bf0:	08054c63          	bltz	a0,80006c88 <sys_pipe+0xea>
    80006bf4:	fc843503          	ld	a0,-56(s0)
    80006bf8:	fffff097          	auipc	ra,0xfffff
    80006bfc:	4d4080e7          	jalr	1236(ra) # 800060cc <fdalloc>
    80006c00:	fca42023          	sw	a0,-64(s0)
    80006c04:	06054863          	bltz	a0,80006c74 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006c08:	4691                	li	a3,4
    80006c0a:	fc440613          	addi	a2,s0,-60
    80006c0e:	fd843583          	ld	a1,-40(s0)
    80006c12:	68a8                	ld	a0,80(s1)
    80006c14:	ffffb097          	auipc	ra,0xffffb
    80006c18:	876080e7          	jalr	-1930(ra) # 8000148a <copyout>
    80006c1c:	02054063          	bltz	a0,80006c3c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006c20:	4691                	li	a3,4
    80006c22:	fc040613          	addi	a2,s0,-64
    80006c26:	fd843583          	ld	a1,-40(s0)
    80006c2a:	0591                	addi	a1,a1,4
    80006c2c:	68a8                	ld	a0,80(s1)
    80006c2e:	ffffb097          	auipc	ra,0xffffb
    80006c32:	85c080e7          	jalr	-1956(ra) # 8000148a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006c36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006c38:	06055563          	bgez	a0,80006ca2 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006c3c:	fc442783          	lw	a5,-60(s0)
    80006c40:	07e9                	addi	a5,a5,26
    80006c42:	078e                	slli	a5,a5,0x3
    80006c44:	97a6                	add	a5,a5,s1
    80006c46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006c4a:	fc042503          	lw	a0,-64(s0)
    80006c4e:	0569                	addi	a0,a0,26
    80006c50:	050e                	slli	a0,a0,0x3
    80006c52:	9526                	add	a0,a0,s1
    80006c54:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006c58:	fd043503          	ld	a0,-48(s0)
    80006c5c:	fffff097          	auipc	ra,0xfffff
    80006c60:	818080e7          	jalr	-2024(ra) # 80005474 <fileclose>
    fileclose(wf);
    80006c64:	fc843503          	ld	a0,-56(s0)
    80006c68:	fffff097          	auipc	ra,0xfffff
    80006c6c:	80c080e7          	jalr	-2036(ra) # 80005474 <fileclose>
    return -1;
    80006c70:	57fd                	li	a5,-1
    80006c72:	a805                	j	80006ca2 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006c74:	fc442783          	lw	a5,-60(s0)
    80006c78:	0007c863          	bltz	a5,80006c88 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006c7c:	01a78513          	addi	a0,a5,26
    80006c80:	050e                	slli	a0,a0,0x3
    80006c82:	9526                	add	a0,a0,s1
    80006c84:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006c88:	fd043503          	ld	a0,-48(s0)
    80006c8c:	ffffe097          	auipc	ra,0xffffe
    80006c90:	7e8080e7          	jalr	2024(ra) # 80005474 <fileclose>
    fileclose(wf);
    80006c94:	fc843503          	ld	a0,-56(s0)
    80006c98:	ffffe097          	auipc	ra,0xffffe
    80006c9c:	7dc080e7          	jalr	2012(ra) # 80005474 <fileclose>
    return -1;
    80006ca0:	57fd                	li	a5,-1
}
    80006ca2:	853e                	mv	a0,a5
    80006ca4:	70e2                	ld	ra,56(sp)
    80006ca6:	7442                	ld	s0,48(sp)
    80006ca8:	74a2                	ld	s1,40(sp)
    80006caa:	6121                	addi	sp,sp,64
    80006cac:	8082                	ret
	...

0000000080006cb0 <kernelvec>:
    80006cb0:	7111                	addi	sp,sp,-256
    80006cb2:	e006                	sd	ra,0(sp)
    80006cb4:	e40a                	sd	sp,8(sp)
    80006cb6:	e80e                	sd	gp,16(sp)
    80006cb8:	ec12                	sd	tp,24(sp)
    80006cba:	f016                	sd	t0,32(sp)
    80006cbc:	f41a                	sd	t1,40(sp)
    80006cbe:	f81e                	sd	t2,48(sp)
    80006cc0:	fc22                	sd	s0,56(sp)
    80006cc2:	e0a6                	sd	s1,64(sp)
    80006cc4:	e4aa                	sd	a0,72(sp)
    80006cc6:	e8ae                	sd	a1,80(sp)
    80006cc8:	ecb2                	sd	a2,88(sp)
    80006cca:	f0b6                	sd	a3,96(sp)
    80006ccc:	f4ba                	sd	a4,104(sp)
    80006cce:	f8be                	sd	a5,112(sp)
    80006cd0:	fcc2                	sd	a6,120(sp)
    80006cd2:	e146                	sd	a7,128(sp)
    80006cd4:	e54a                	sd	s2,136(sp)
    80006cd6:	e94e                	sd	s3,144(sp)
    80006cd8:	ed52                	sd	s4,152(sp)
    80006cda:	f156                	sd	s5,160(sp)
    80006cdc:	f55a                	sd	s6,168(sp)
    80006cde:	f95e                	sd	s7,176(sp)
    80006ce0:	fd62                	sd	s8,184(sp)
    80006ce2:	e1e6                	sd	s9,192(sp)
    80006ce4:	e5ea                	sd	s10,200(sp)
    80006ce6:	e9ee                	sd	s11,208(sp)
    80006ce8:	edf2                	sd	t3,216(sp)
    80006cea:	f1f6                	sd	t4,224(sp)
    80006cec:	f5fa                	sd	t5,232(sp)
    80006cee:	f9fe                	sd	t6,240(sp)
    80006cf0:	891fc0ef          	jal	ra,80003580 <kerneltrap>
    80006cf4:	6082                	ld	ra,0(sp)
    80006cf6:	6122                	ld	sp,8(sp)
    80006cf8:	61c2                	ld	gp,16(sp)
    80006cfa:	7282                	ld	t0,32(sp)
    80006cfc:	7322                	ld	t1,40(sp)
    80006cfe:	73c2                	ld	t2,48(sp)
    80006d00:	7462                	ld	s0,56(sp)
    80006d02:	6486                	ld	s1,64(sp)
    80006d04:	6526                	ld	a0,72(sp)
    80006d06:	65c6                	ld	a1,80(sp)
    80006d08:	6666                	ld	a2,88(sp)
    80006d0a:	7686                	ld	a3,96(sp)
    80006d0c:	7726                	ld	a4,104(sp)
    80006d0e:	77c6                	ld	a5,112(sp)
    80006d10:	7866                	ld	a6,120(sp)
    80006d12:	688a                	ld	a7,128(sp)
    80006d14:	692a                	ld	s2,136(sp)
    80006d16:	69ca                	ld	s3,144(sp)
    80006d18:	6a6a                	ld	s4,152(sp)
    80006d1a:	7a8a                	ld	s5,160(sp)
    80006d1c:	7b2a                	ld	s6,168(sp)
    80006d1e:	7bca                	ld	s7,176(sp)
    80006d20:	7c6a                	ld	s8,184(sp)
    80006d22:	6c8e                	ld	s9,192(sp)
    80006d24:	6d2e                	ld	s10,200(sp)
    80006d26:	6dce                	ld	s11,208(sp)
    80006d28:	6e6e                	ld	t3,216(sp)
    80006d2a:	7e8e                	ld	t4,224(sp)
    80006d2c:	7f2e                	ld	t5,232(sp)
    80006d2e:	7fce                	ld	t6,240(sp)
    80006d30:	6111                	addi	sp,sp,256
    80006d32:	10200073          	sret
    80006d36:	00000013          	nop
    80006d3a:	00000013          	nop
    80006d3e:	0001                	nop

0000000080006d40 <timervec>:
    80006d40:	34051573          	csrrw	a0,mscratch,a0
    80006d44:	e10c                	sd	a1,0(a0)
    80006d46:	e510                	sd	a2,8(a0)
    80006d48:	e914                	sd	a3,16(a0)
    80006d4a:	6d0c                	ld	a1,24(a0)
    80006d4c:	7110                	ld	a2,32(a0)
    80006d4e:	6194                	ld	a3,0(a1)
    80006d50:	96b2                	add	a3,a3,a2
    80006d52:	e194                	sd	a3,0(a1)
    80006d54:	4589                	li	a1,2
    80006d56:	14459073          	csrw	sip,a1
    80006d5a:	6914                	ld	a3,16(a0)
    80006d5c:	6510                	ld	a2,8(a0)
    80006d5e:	610c                	ld	a1,0(a0)
    80006d60:	34051573          	csrrw	a0,mscratch,a0
    80006d64:	30200073          	mret
	...

0000000080006d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006d6a:	1141                	addi	sp,sp,-16
    80006d6c:	e422                	sd	s0,8(sp)
    80006d6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006d70:	0c0007b7          	lui	a5,0xc000
    80006d74:	4705                	li	a4,1
    80006d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006d78:	c3d8                	sw	a4,4(a5)
}
    80006d7a:	6422                	ld	s0,8(sp)
    80006d7c:	0141                	addi	sp,sp,16
    80006d7e:	8082                	ret

0000000080006d80 <plicinithart>:

void
plicinithart(void)
{
    80006d80:	1141                	addi	sp,sp,-16
    80006d82:	e406                	sd	ra,8(sp)
    80006d84:	e022                	sd	s0,0(sp)
    80006d86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d88:	ffffb097          	auipc	ra,0xffffb
    80006d8c:	64e080e7          	jalr	1614(ra) # 800023d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006d90:	0085171b          	slliw	a4,a0,0x8
    80006d94:	0c0027b7          	lui	a5,0xc002
    80006d98:	97ba                	add	a5,a5,a4
    80006d9a:	40200713          	li	a4,1026
    80006d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006da2:	00d5151b          	slliw	a0,a0,0xd
    80006da6:	0c2017b7          	lui	a5,0xc201
    80006daa:	953e                	add	a0,a0,a5
    80006dac:	00052023          	sw	zero,0(a0)
}
    80006db0:	60a2                	ld	ra,8(sp)
    80006db2:	6402                	ld	s0,0(sp)
    80006db4:	0141                	addi	sp,sp,16
    80006db6:	8082                	ret

0000000080006db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006db8:	1141                	addi	sp,sp,-16
    80006dba:	e406                	sd	ra,8(sp)
    80006dbc:	e022                	sd	s0,0(sp)
    80006dbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006dc0:	ffffb097          	auipc	ra,0xffffb
    80006dc4:	616080e7          	jalr	1558(ra) # 800023d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006dc8:	00d5179b          	slliw	a5,a0,0xd
    80006dcc:	0c201537          	lui	a0,0xc201
    80006dd0:	953e                	add	a0,a0,a5
  return irq;
}
    80006dd2:	4148                	lw	a0,4(a0)
    80006dd4:	60a2                	ld	ra,8(sp)
    80006dd6:	6402                	ld	s0,0(sp)
    80006dd8:	0141                	addi	sp,sp,16
    80006dda:	8082                	ret

0000000080006ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006ddc:	1101                	addi	sp,sp,-32
    80006dde:	ec06                	sd	ra,24(sp)
    80006de0:	e822                	sd	s0,16(sp)
    80006de2:	e426                	sd	s1,8(sp)
    80006de4:	1000                	addi	s0,sp,32
    80006de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006de8:	ffffb097          	auipc	ra,0xffffb
    80006dec:	5ee080e7          	jalr	1518(ra) # 800023d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006df0:	00d5151b          	slliw	a0,a0,0xd
    80006df4:	0c2017b7          	lui	a5,0xc201
    80006df8:	97aa                	add	a5,a5,a0
    80006dfa:	c3c4                	sw	s1,4(a5)
}
    80006dfc:	60e2                	ld	ra,24(sp)
    80006dfe:	6442                	ld	s0,16(sp)
    80006e00:	64a2                	ld	s1,8(sp)
    80006e02:	6105                	addi	sp,sp,32
    80006e04:	8082                	ret

0000000080006e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006e06:	1141                	addi	sp,sp,-16
    80006e08:	e406                	sd	ra,8(sp)
    80006e0a:	e022                	sd	s0,0(sp)
    80006e0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006e0e:	479d                	li	a5,7
    80006e10:	06a7c963          	blt	a5,a0,80006e82 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006e14:	00025797          	auipc	a5,0x25
    80006e18:	1ec78793          	addi	a5,a5,492 # 8002c000 <disk>
    80006e1c:	00a78733          	add	a4,a5,a0
    80006e20:	6789                	lui	a5,0x2
    80006e22:	97ba                	add	a5,a5,a4
    80006e24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006e28:	e7ad                	bnez	a5,80006e92 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006e2a:	00451793          	slli	a5,a0,0x4
    80006e2e:	00027717          	auipc	a4,0x27
    80006e32:	1d270713          	addi	a4,a4,466 # 8002e000 <disk+0x2000>
    80006e36:	6314                	ld	a3,0(a4)
    80006e38:	96be                	add	a3,a3,a5
    80006e3a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006e3e:	6314                	ld	a3,0(a4)
    80006e40:	96be                	add	a3,a3,a5
    80006e42:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006e46:	6314                	ld	a3,0(a4)
    80006e48:	96be                	add	a3,a3,a5
    80006e4a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006e4e:	6318                	ld	a4,0(a4)
    80006e50:	97ba                	add	a5,a5,a4
    80006e52:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006e56:	00025797          	auipc	a5,0x25
    80006e5a:	1aa78793          	addi	a5,a5,426 # 8002c000 <disk>
    80006e5e:	97aa                	add	a5,a5,a0
    80006e60:	6509                	lui	a0,0x2
    80006e62:	953e                	add	a0,a0,a5
    80006e64:	4785                	li	a5,1
    80006e66:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006e6a:	00027517          	auipc	a0,0x27
    80006e6e:	1ae50513          	addi	a0,a0,430 # 8002e018 <disk+0x2018>
    80006e72:	ffffc097          	auipc	ra,0xffffc
    80006e76:	042080e7          	jalr	66(ra) # 80002eb4 <wakeup>
}
    80006e7a:	60a2                	ld	ra,8(sp)
    80006e7c:	6402                	ld	s0,0(sp)
    80006e7e:	0141                	addi	sp,sp,16
    80006e80:	8082                	ret
    panic("free_desc 1");
    80006e82:	00003517          	auipc	a0,0x3
    80006e86:	ace50513          	addi	a0,a0,-1330 # 80009950 <syscalls+0x358>
    80006e8a:	ffff9097          	auipc	ra,0xffff9
    80006e8e:	6a0080e7          	jalr	1696(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006e92:	00003517          	auipc	a0,0x3
    80006e96:	ace50513          	addi	a0,a0,-1330 # 80009960 <syscalls+0x368>
    80006e9a:	ffff9097          	auipc	ra,0xffff9
    80006e9e:	690080e7          	jalr	1680(ra) # 8000052a <panic>

0000000080006ea2 <virtio_disk_init>:
{
    80006ea2:	1101                	addi	sp,sp,-32
    80006ea4:	ec06                	sd	ra,24(sp)
    80006ea6:	e822                	sd	s0,16(sp)
    80006ea8:	e426                	sd	s1,8(sp)
    80006eaa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006eac:	00003597          	auipc	a1,0x3
    80006eb0:	ac458593          	addi	a1,a1,-1340 # 80009970 <syscalls+0x378>
    80006eb4:	00027517          	auipc	a0,0x27
    80006eb8:	27450513          	addi	a0,a0,628 # 8002e128 <disk+0x2128>
    80006ebc:	ffffa097          	auipc	ra,0xffffa
    80006ec0:	c86080e7          	jalr	-890(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ec4:	100017b7          	lui	a5,0x10001
    80006ec8:	4398                	lw	a4,0(a5)
    80006eca:	2701                	sext.w	a4,a4
    80006ecc:	747277b7          	lui	a5,0x74727
    80006ed0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006ed4:	0ef71163          	bne	a4,a5,80006fb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006ed8:	100017b7          	lui	a5,0x10001
    80006edc:	43dc                	lw	a5,4(a5)
    80006ede:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006ee0:	4705                	li	a4,1
    80006ee2:	0ce79a63          	bne	a5,a4,80006fb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006ee6:	100017b7          	lui	a5,0x10001
    80006eea:	479c                	lw	a5,8(a5)
    80006eec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006eee:	4709                	li	a4,2
    80006ef0:	0ce79363          	bne	a5,a4,80006fb6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006ef4:	100017b7          	lui	a5,0x10001
    80006ef8:	47d8                	lw	a4,12(a5)
    80006efa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006efc:	554d47b7          	lui	a5,0x554d4
    80006f00:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006f04:	0af71963          	bne	a4,a5,80006fb6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f08:	100017b7          	lui	a5,0x10001
    80006f0c:	4705                	li	a4,1
    80006f0e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f10:	470d                	li	a4,3
    80006f12:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006f14:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006f16:	c7ffe737          	lui	a4,0xc7ffe
    80006f1a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006f1e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006f20:	2701                	sext.w	a4,a4
    80006f22:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f24:	472d                	li	a4,11
    80006f26:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006f28:	473d                	li	a4,15
    80006f2a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006f2c:	6705                	lui	a4,0x1
    80006f2e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006f30:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006f34:	5bdc                	lw	a5,52(a5)
    80006f36:	2781                	sext.w	a5,a5
  if(max == 0)
    80006f38:	c7d9                	beqz	a5,80006fc6 <virtio_disk_init+0x124>
  if(max < NUM)
    80006f3a:	471d                	li	a4,7
    80006f3c:	08f77d63          	bgeu	a4,a5,80006fd6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006f40:	100014b7          	lui	s1,0x10001
    80006f44:	47a1                	li	a5,8
    80006f46:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006f48:	6609                	lui	a2,0x2
    80006f4a:	4581                	li	a1,0
    80006f4c:	00025517          	auipc	a0,0x25
    80006f50:	0b450513          	addi	a0,a0,180 # 8002c000 <disk>
    80006f54:	ffffa097          	auipc	ra,0xffffa
    80006f58:	d7a080e7          	jalr	-646(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006f5c:	00025717          	auipc	a4,0x25
    80006f60:	0a470713          	addi	a4,a4,164 # 8002c000 <disk>
    80006f64:	00c75793          	srli	a5,a4,0xc
    80006f68:	2781                	sext.w	a5,a5
    80006f6a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006f6c:	00027797          	auipc	a5,0x27
    80006f70:	09478793          	addi	a5,a5,148 # 8002e000 <disk+0x2000>
    80006f74:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006f76:	00025717          	auipc	a4,0x25
    80006f7a:	10a70713          	addi	a4,a4,266 # 8002c080 <disk+0x80>
    80006f7e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006f80:	00026717          	auipc	a4,0x26
    80006f84:	08070713          	addi	a4,a4,128 # 8002d000 <disk+0x1000>
    80006f88:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006f8a:	4705                	li	a4,1
    80006f8c:	00e78c23          	sb	a4,24(a5)
    80006f90:	00e78ca3          	sb	a4,25(a5)
    80006f94:	00e78d23          	sb	a4,26(a5)
    80006f98:	00e78da3          	sb	a4,27(a5)
    80006f9c:	00e78e23          	sb	a4,28(a5)
    80006fa0:	00e78ea3          	sb	a4,29(a5)
    80006fa4:	00e78f23          	sb	a4,30(a5)
    80006fa8:	00e78fa3          	sb	a4,31(a5)
}
    80006fac:	60e2                	ld	ra,24(sp)
    80006fae:	6442                	ld	s0,16(sp)
    80006fb0:	64a2                	ld	s1,8(sp)
    80006fb2:	6105                	addi	sp,sp,32
    80006fb4:	8082                	ret
    panic("could not find virtio disk");
    80006fb6:	00003517          	auipc	a0,0x3
    80006fba:	9ca50513          	addi	a0,a0,-1590 # 80009980 <syscalls+0x388>
    80006fbe:	ffff9097          	auipc	ra,0xffff9
    80006fc2:	56c080e7          	jalr	1388(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006fc6:	00003517          	auipc	a0,0x3
    80006fca:	9da50513          	addi	a0,a0,-1574 # 800099a0 <syscalls+0x3a8>
    80006fce:	ffff9097          	auipc	ra,0xffff9
    80006fd2:	55c080e7          	jalr	1372(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006fd6:	00003517          	auipc	a0,0x3
    80006fda:	9ea50513          	addi	a0,a0,-1558 # 800099c0 <syscalls+0x3c8>
    80006fde:	ffff9097          	auipc	ra,0xffff9
    80006fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>

0000000080006fe6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006fe6:	7119                	addi	sp,sp,-128
    80006fe8:	fc86                	sd	ra,120(sp)
    80006fea:	f8a2                	sd	s0,112(sp)
    80006fec:	f4a6                	sd	s1,104(sp)
    80006fee:	f0ca                	sd	s2,96(sp)
    80006ff0:	ecce                	sd	s3,88(sp)
    80006ff2:	e8d2                	sd	s4,80(sp)
    80006ff4:	e4d6                	sd	s5,72(sp)
    80006ff6:	e0da                	sd	s6,64(sp)
    80006ff8:	fc5e                	sd	s7,56(sp)
    80006ffa:	f862                	sd	s8,48(sp)
    80006ffc:	f466                	sd	s9,40(sp)
    80006ffe:	f06a                	sd	s10,32(sp)
    80007000:	ec6e                	sd	s11,24(sp)
    80007002:	0100                	addi	s0,sp,128
    80007004:	8aaa                	mv	s5,a0
    80007006:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80007008:	00c52c83          	lw	s9,12(a0)
    8000700c:	001c9c9b          	slliw	s9,s9,0x1
    80007010:	1c82                	slli	s9,s9,0x20
    80007012:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80007016:	00027517          	auipc	a0,0x27
    8000701a:	11250513          	addi	a0,a0,274 # 8002e128 <disk+0x2128>
    8000701e:	ffffa097          	auipc	ra,0xffffa
    80007022:	bb4080e7          	jalr	-1100(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80007026:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80007028:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000702a:	00025c17          	auipc	s8,0x25
    8000702e:	fd6c0c13          	addi	s8,s8,-42 # 8002c000 <disk>
    80007032:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80007034:	4b0d                	li	s6,3
    80007036:	a0ad                	j	800070a0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80007038:	00fc0733          	add	a4,s8,a5
    8000703c:	975e                	add	a4,a4,s7
    8000703e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80007042:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80007044:	0207c563          	bltz	a5,8000706e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80007048:	2905                	addiw	s2,s2,1
    8000704a:	0611                	addi	a2,a2,4
    8000704c:	19690d63          	beq	s2,s6,800071e6 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80007050:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80007052:	00027717          	auipc	a4,0x27
    80007056:	fc670713          	addi	a4,a4,-58 # 8002e018 <disk+0x2018>
    8000705a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000705c:	00074683          	lbu	a3,0(a4)
    80007060:	fee1                	bnez	a3,80007038 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80007062:	2785                	addiw	a5,a5,1
    80007064:	0705                	addi	a4,a4,1
    80007066:	fe979be3          	bne	a5,s1,8000705c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000706a:	57fd                	li	a5,-1
    8000706c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000706e:	01205d63          	blez	s2,80007088 <virtio_disk_rw+0xa2>
    80007072:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80007074:	000a2503          	lw	a0,0(s4)
    80007078:	00000097          	auipc	ra,0x0
    8000707c:	d8e080e7          	jalr	-626(ra) # 80006e06 <free_desc>
      for(int j = 0; j < i; j++)
    80007080:	2d85                	addiw	s11,s11,1
    80007082:	0a11                	addi	s4,s4,4
    80007084:	ffb918e3          	bne	s2,s11,80007074 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007088:	00027597          	auipc	a1,0x27
    8000708c:	0a058593          	addi	a1,a1,160 # 8002e128 <disk+0x2128>
    80007090:	00027517          	auipc	a0,0x27
    80007094:	f8850513          	addi	a0,a0,-120 # 8002e018 <disk+0x2018>
    80007098:	ffffc097          	auipc	ra,0xffffc
    8000709c:	c90080e7          	jalr	-880(ra) # 80002d28 <sleep>
  for(int i = 0; i < 3; i++){
    800070a0:	f8040a13          	addi	s4,s0,-128
{
    800070a4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800070a6:	894e                	mv	s2,s3
    800070a8:	b765                	j	80007050 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800070aa:	00027697          	auipc	a3,0x27
    800070ae:	f566b683          	ld	a3,-170(a3) # 8002e000 <disk+0x2000>
    800070b2:	96ba                	add	a3,a3,a4
    800070b4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800070b8:	00025817          	auipc	a6,0x25
    800070bc:	f4880813          	addi	a6,a6,-184 # 8002c000 <disk>
    800070c0:	00027697          	auipc	a3,0x27
    800070c4:	f4068693          	addi	a3,a3,-192 # 8002e000 <disk+0x2000>
    800070c8:	6290                	ld	a2,0(a3)
    800070ca:	963a                	add	a2,a2,a4
    800070cc:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800070d0:	0015e593          	ori	a1,a1,1
    800070d4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800070d8:	f8842603          	lw	a2,-120(s0)
    800070dc:	628c                	ld	a1,0(a3)
    800070de:	972e                	add	a4,a4,a1
    800070e0:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800070e4:	20050593          	addi	a1,a0,512
    800070e8:	0592                	slli	a1,a1,0x4
    800070ea:	95c2                	add	a1,a1,a6
    800070ec:	577d                	li	a4,-1
    800070ee:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800070f2:	00461713          	slli	a4,a2,0x4
    800070f6:	6290                	ld	a2,0(a3)
    800070f8:	963a                	add	a2,a2,a4
    800070fa:	03078793          	addi	a5,a5,48
    800070fe:	97c2                	add	a5,a5,a6
    80007100:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80007102:	629c                	ld	a5,0(a3)
    80007104:	97ba                	add	a5,a5,a4
    80007106:	4605                	li	a2,1
    80007108:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000710a:	629c                	ld	a5,0(a3)
    8000710c:	97ba                	add	a5,a5,a4
    8000710e:	4809                	li	a6,2
    80007110:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80007114:	629c                	ld	a5,0(a3)
    80007116:	973e                	add	a4,a4,a5
    80007118:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000711c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80007120:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80007124:	6698                	ld	a4,8(a3)
    80007126:	00275783          	lhu	a5,2(a4)
    8000712a:	8b9d                	andi	a5,a5,7
    8000712c:	0786                	slli	a5,a5,0x1
    8000712e:	97ba                	add	a5,a5,a4
    80007130:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80007134:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80007138:	6698                	ld	a4,8(a3)
    8000713a:	00275783          	lhu	a5,2(a4)
    8000713e:	2785                	addiw	a5,a5,1
    80007140:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80007144:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80007148:	100017b7          	lui	a5,0x10001
    8000714c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80007150:	004aa783          	lw	a5,4(s5)
    80007154:	02c79163          	bne	a5,a2,80007176 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80007158:	00027917          	auipc	s2,0x27
    8000715c:	fd090913          	addi	s2,s2,-48 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    80007160:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80007162:	85ca                	mv	a1,s2
    80007164:	8556                	mv	a0,s5
    80007166:	ffffc097          	auipc	ra,0xffffc
    8000716a:	bc2080e7          	jalr	-1086(ra) # 80002d28 <sleep>
  while(b->disk == 1) {
    8000716e:	004aa783          	lw	a5,4(s5)
    80007172:	fe9788e3          	beq	a5,s1,80007162 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80007176:	f8042903          	lw	s2,-128(s0)
    8000717a:	20090793          	addi	a5,s2,512
    8000717e:	00479713          	slli	a4,a5,0x4
    80007182:	00025797          	auipc	a5,0x25
    80007186:	e7e78793          	addi	a5,a5,-386 # 8002c000 <disk>
    8000718a:	97ba                	add	a5,a5,a4
    8000718c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007190:	00027997          	auipc	s3,0x27
    80007194:	e7098993          	addi	s3,s3,-400 # 8002e000 <disk+0x2000>
    80007198:	00491713          	slli	a4,s2,0x4
    8000719c:	0009b783          	ld	a5,0(s3)
    800071a0:	97ba                	add	a5,a5,a4
    800071a2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800071a6:	854a                	mv	a0,s2
    800071a8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800071ac:	00000097          	auipc	ra,0x0
    800071b0:	c5a080e7          	jalr	-934(ra) # 80006e06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800071b4:	8885                	andi	s1,s1,1
    800071b6:	f0ed                	bnez	s1,80007198 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800071b8:	00027517          	auipc	a0,0x27
    800071bc:	f7050513          	addi	a0,a0,-144 # 8002e128 <disk+0x2128>
    800071c0:	ffffa097          	auipc	ra,0xffffa
    800071c4:	ac6080e7          	jalr	-1338(ra) # 80000c86 <release>
}
    800071c8:	70e6                	ld	ra,120(sp)
    800071ca:	7446                	ld	s0,112(sp)
    800071cc:	74a6                	ld	s1,104(sp)
    800071ce:	7906                	ld	s2,96(sp)
    800071d0:	69e6                	ld	s3,88(sp)
    800071d2:	6a46                	ld	s4,80(sp)
    800071d4:	6aa6                	ld	s5,72(sp)
    800071d6:	6b06                	ld	s6,64(sp)
    800071d8:	7be2                	ld	s7,56(sp)
    800071da:	7c42                	ld	s8,48(sp)
    800071dc:	7ca2                	ld	s9,40(sp)
    800071de:	7d02                	ld	s10,32(sp)
    800071e0:	6de2                	ld	s11,24(sp)
    800071e2:	6109                	addi	sp,sp,128
    800071e4:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800071e6:	f8042503          	lw	a0,-128(s0)
    800071ea:	20050793          	addi	a5,a0,512
    800071ee:	0792                	slli	a5,a5,0x4
  if(write)
    800071f0:	00025817          	auipc	a6,0x25
    800071f4:	e1080813          	addi	a6,a6,-496 # 8002c000 <disk>
    800071f8:	00f80733          	add	a4,a6,a5
    800071fc:	01a036b3          	snez	a3,s10
    80007200:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80007204:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007208:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000720c:	7679                	lui	a2,0xffffe
    8000720e:	963e                	add	a2,a2,a5
    80007210:	00027697          	auipc	a3,0x27
    80007214:	df068693          	addi	a3,a3,-528 # 8002e000 <disk+0x2000>
    80007218:	6298                	ld	a4,0(a3)
    8000721a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000721c:	0a878593          	addi	a1,a5,168
    80007220:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80007222:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80007224:	6298                	ld	a4,0(a3)
    80007226:	9732                	add	a4,a4,a2
    80007228:	45c1                	li	a1,16
    8000722a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000722c:	6298                	ld	a4,0(a3)
    8000722e:	9732                	add	a4,a4,a2
    80007230:	4585                	li	a1,1
    80007232:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80007236:	f8442703          	lw	a4,-124(s0)
    8000723a:	628c                	ld	a1,0(a3)
    8000723c:	962e                	add	a2,a2,a1
    8000723e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80007242:	0712                	slli	a4,a4,0x4
    80007244:	6290                	ld	a2,0(a3)
    80007246:	963a                	add	a2,a2,a4
    80007248:	058a8593          	addi	a1,s5,88
    8000724c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000724e:	6294                	ld	a3,0(a3)
    80007250:	96ba                	add	a3,a3,a4
    80007252:	40000613          	li	a2,1024
    80007256:	c690                	sw	a2,8(a3)
  if(write)
    80007258:	e40d19e3          	bnez	s10,800070aa <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000725c:	00027697          	auipc	a3,0x27
    80007260:	da46b683          	ld	a3,-604(a3) # 8002e000 <disk+0x2000>
    80007264:	96ba                	add	a3,a3,a4
    80007266:	4609                	li	a2,2
    80007268:	00c69623          	sh	a2,12(a3)
    8000726c:	b5b1                	j	800070b8 <virtio_disk_rw+0xd2>

000000008000726e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000726e:	1101                	addi	sp,sp,-32
    80007270:	ec06                	sd	ra,24(sp)
    80007272:	e822                	sd	s0,16(sp)
    80007274:	e426                	sd	s1,8(sp)
    80007276:	e04a                	sd	s2,0(sp)
    80007278:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000727a:	00027517          	auipc	a0,0x27
    8000727e:	eae50513          	addi	a0,a0,-338 # 8002e128 <disk+0x2128>
    80007282:	ffffa097          	auipc	ra,0xffffa
    80007286:	950080e7          	jalr	-1712(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000728a:	10001737          	lui	a4,0x10001
    8000728e:	533c                	lw	a5,96(a4)
    80007290:	8b8d                	andi	a5,a5,3
    80007292:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007294:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007298:	00027797          	auipc	a5,0x27
    8000729c:	d6878793          	addi	a5,a5,-664 # 8002e000 <disk+0x2000>
    800072a0:	6b94                	ld	a3,16(a5)
    800072a2:	0207d703          	lhu	a4,32(a5)
    800072a6:	0026d783          	lhu	a5,2(a3)
    800072aa:	06f70163          	beq	a4,a5,8000730c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800072ae:	00025917          	auipc	s2,0x25
    800072b2:	d5290913          	addi	s2,s2,-686 # 8002c000 <disk>
    800072b6:	00027497          	auipc	s1,0x27
    800072ba:	d4a48493          	addi	s1,s1,-694 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    800072be:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800072c2:	6898                	ld	a4,16(s1)
    800072c4:	0204d783          	lhu	a5,32(s1)
    800072c8:	8b9d                	andi	a5,a5,7
    800072ca:	078e                	slli	a5,a5,0x3
    800072cc:	97ba                	add	a5,a5,a4
    800072ce:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800072d0:	20078713          	addi	a4,a5,512
    800072d4:	0712                	slli	a4,a4,0x4
    800072d6:	974a                	add	a4,a4,s2
    800072d8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800072dc:	e731                	bnez	a4,80007328 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800072de:	20078793          	addi	a5,a5,512
    800072e2:	0792                	slli	a5,a5,0x4
    800072e4:	97ca                	add	a5,a5,s2
    800072e6:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800072e8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800072ec:	ffffc097          	auipc	ra,0xffffc
    800072f0:	bc8080e7          	jalr	-1080(ra) # 80002eb4 <wakeup>

    disk.used_idx += 1;
    800072f4:	0204d783          	lhu	a5,32(s1)
    800072f8:	2785                	addiw	a5,a5,1
    800072fa:	17c2                	slli	a5,a5,0x30
    800072fc:	93c1                	srli	a5,a5,0x30
    800072fe:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007302:	6898                	ld	a4,16(s1)
    80007304:	00275703          	lhu	a4,2(a4)
    80007308:	faf71be3          	bne	a4,a5,800072be <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000730c:	00027517          	auipc	a0,0x27
    80007310:	e1c50513          	addi	a0,a0,-484 # 8002e128 <disk+0x2128>
    80007314:	ffffa097          	auipc	ra,0xffffa
    80007318:	972080e7          	jalr	-1678(ra) # 80000c86 <release>
}
    8000731c:	60e2                	ld	ra,24(sp)
    8000731e:	6442                	ld	s0,16(sp)
    80007320:	64a2                	ld	s1,8(sp)
    80007322:	6902                	ld	s2,0(sp)
    80007324:	6105                	addi	sp,sp,32
    80007326:	8082                	ret
      panic("virtio_disk_intr status");
    80007328:	00002517          	auipc	a0,0x2
    8000732c:	6b850513          	addi	a0,a0,1720 # 800099e0 <syscalls+0x3e8>
    80007330:	ffff9097          	auipc	ra,0xffff9
    80007334:	1fa080e7          	jalr	506(ra) # 8000052a <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051573          	csrrw	a0,sscratch,a0
    80008004:	02153423          	sd	ra,40(a0)
    80008008:	02253823          	sd	sp,48(a0)
    8000800c:	02353c23          	sd	gp,56(a0)
    80008010:	04453023          	sd	tp,64(a0)
    80008014:	04553423          	sd	t0,72(a0)
    80008018:	04653823          	sd	t1,80(a0)
    8000801c:	04753c23          	sd	t2,88(a0)
    80008020:	f120                	sd	s0,96(a0)
    80008022:	f524                	sd	s1,104(a0)
    80008024:	fd2c                	sd	a1,120(a0)
    80008026:	e150                	sd	a2,128(a0)
    80008028:	e554                	sd	a3,136(a0)
    8000802a:	e958                	sd	a4,144(a0)
    8000802c:	ed5c                	sd	a5,152(a0)
    8000802e:	0b053023          	sd	a6,160(a0)
    80008032:	0b153423          	sd	a7,168(a0)
    80008036:	0b253823          	sd	s2,176(a0)
    8000803a:	0b353c23          	sd	s3,184(a0)
    8000803e:	0d453023          	sd	s4,192(a0)
    80008042:	0d553423          	sd	s5,200(a0)
    80008046:	0d653823          	sd	s6,208(a0)
    8000804a:	0d753c23          	sd	s7,216(a0)
    8000804e:	0f853023          	sd	s8,224(a0)
    80008052:	0f953423          	sd	s9,232(a0)
    80008056:	0fa53823          	sd	s10,240(a0)
    8000805a:	0fb53c23          	sd	s11,248(a0)
    8000805e:	11c53023          	sd	t3,256(a0)
    80008062:	11d53423          	sd	t4,264(a0)
    80008066:	11e53823          	sd	t5,272(a0)
    8000806a:	11f53c23          	sd	t6,280(a0)
    8000806e:	140022f3          	csrr	t0,sscratch
    80008072:	06553823          	sd	t0,112(a0)
    80008076:	00853103          	ld	sp,8(a0)
    8000807a:	02053203          	ld	tp,32(a0)
    8000807e:	01053283          	ld	t0,16(a0)
    80008082:	00053303          	ld	t1,0(a0)
    80008086:	18031073          	csrw	satp,t1
    8000808a:	12000073          	sfence.vma
    8000808e:	8282                	jr	t0

0000000080008090 <userret>:
    80008090:	18059073          	csrw	satp,a1
    80008094:	12000073          	sfence.vma
    80008098:	07053283          	ld	t0,112(a0)
    8000809c:	14029073          	csrw	sscratch,t0
    800080a0:	02853083          	ld	ra,40(a0)
    800080a4:	03053103          	ld	sp,48(a0)
    800080a8:	03853183          	ld	gp,56(a0)
    800080ac:	04053203          	ld	tp,64(a0)
    800080b0:	04853283          	ld	t0,72(a0)
    800080b4:	05053303          	ld	t1,80(a0)
    800080b8:	05853383          	ld	t2,88(a0)
    800080bc:	7120                	ld	s0,96(a0)
    800080be:	7524                	ld	s1,104(a0)
    800080c0:	7d2c                	ld	a1,120(a0)
    800080c2:	6150                	ld	a2,128(a0)
    800080c4:	6554                	ld	a3,136(a0)
    800080c6:	6958                	ld	a4,144(a0)
    800080c8:	6d5c                	ld	a5,152(a0)
    800080ca:	0a053803          	ld	a6,160(a0)
    800080ce:	0a853883          	ld	a7,168(a0)
    800080d2:	0b053903          	ld	s2,176(a0)
    800080d6:	0b853983          	ld	s3,184(a0)
    800080da:	0c053a03          	ld	s4,192(a0)
    800080de:	0c853a83          	ld	s5,200(a0)
    800080e2:	0d053b03          	ld	s6,208(a0)
    800080e6:	0d853b83          	ld	s7,216(a0)
    800080ea:	0e053c03          	ld	s8,224(a0)
    800080ee:	0e853c83          	ld	s9,232(a0)
    800080f2:	0f053d03          	ld	s10,240(a0)
    800080f6:	0f853d83          	ld	s11,248(a0)
    800080fa:	10053e03          	ld	t3,256(a0)
    800080fe:	10853e83          	ld	t4,264(a0)
    80008102:	11053f03          	ld	t5,272(a0)
    80008106:	11853f83          	ld	t6,280(a0)
    8000810a:	14051573          	csrrw	a0,sscratch,a0
    8000810e:	10200073          	sret
	...
