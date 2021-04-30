
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
    80000068:	73c78793          	addi	a5,a5,1852 # 800067a0 <timervec>
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
    80000122:	a6e080e7          	jalr	-1426(ra) # 80002b8c <either_copyin>
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
    800001b6:	e58080e7          	jalr	-424(ra) # 8000200a <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	5ba080e7          	jalr	1466(ra) # 8000277c <sleep>
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
    80000202:	938080e7          	jalr	-1736(ra) # 80002b36 <either_copyout>
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
    800002e2:	904080e7          	jalr	-1788(ra) # 80002be2 <procdump>
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
    80000436:	4d6080e7          	jalr	1238(ra) # 80002908 <wakeup>
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
    80000882:	08a080e7          	jalr	138(ra) # 80002908 <wakeup>
    
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
    8000090e:	e72080e7          	jalr	-398(ra) # 8000277c <sleep>
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
    80000b70:	482080e7          	jalr	1154(ra) # 80001fee <mycpu>
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
    80000ba2:	450080e7          	jalr	1104(ra) # 80001fee <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	444080e7          	jalr	1092(ra) # 80001fee <mycpu>
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
    80000bc6:	42c080e7          	jalr	1068(ra) # 80001fee <mycpu>
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
    80000c06:	3ec080e7          	jalr	1004(ra) # 80001fee <mycpu>
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
    80000c32:	3c0080e7          	jalr	960(ra) # 80001fee <mycpu>
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
    80000e88:	15a080e7          	jalr	346(ra) # 80001fde <cpuid>
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
    80000ea4:	13e080e7          	jalr	318(ra) # 80001fde <cpuid>
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
    80000ec6:	e62080e7          	jalr	-414(ra) # 80002d24 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eca:	00006097          	auipc	ra,0x6
    80000ece:	916080e7          	jalr	-1770(ra) # 800067e0 <plicinithart>
  }

  scheduler();        
    80000ed2:	00001097          	auipc	ra,0x1
    80000ed6:	6f0080e7          	jalr	1776(ra) # 800025c2 <scheduler>
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
    80000f26:	2fa080e7          	jalr	762(ra) # 8000121c <kvminit>
    kvminithart();   // turn on paging
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	068080e7          	jalr	104(ra) # 80000f92 <kvminithart>
    procinit();      // process table
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	ffc080e7          	jalr	-4(ra) # 80001f2e <procinit>
    trapinit();      // trap vectors
    80000f3a:	00002097          	auipc	ra,0x2
    80000f3e:	dc2080e7          	jalr	-574(ra) # 80002cfc <trapinit>
    trapinithart();  // install kernel trap vector
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	de2080e7          	jalr	-542(ra) # 80002d24 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4a:	00006097          	auipc	ra,0x6
    80000f4e:	880080e7          	jalr	-1920(ra) # 800067ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f52:	00006097          	auipc	ra,0x6
    80000f56:	88e080e7          	jalr	-1906(ra) # 800067e0 <plicinithart>
    binit();         // buffer cache
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	528080e7          	jalr	1320(ra) # 80003482 <binit>
    iinit();         // inode cache
    80000f62:	00003097          	auipc	ra,0x3
    80000f66:	bba080e7          	jalr	-1094(ra) # 80003b1c <iinit>
    fileinit();      // file table
    80000f6a:	00004097          	auipc	ra,0x4
    80000f6e:	e7a080e7          	jalr	-390(ra) # 80004de4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	990080e7          	jalr	-1648(ra) # 80006902 <virtio_disk_init>
    userinit();      // first user process
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	368080e7          	jalr	872(ra) # 800022e2 <userinit>
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
    800010ea:	00007517          	auipc	a0,0x7
    800010ee:	ffe50513          	addi	a0,a0,-2 # 800080e8 <digits+0xa8>
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
    80001136:	00007517          	auipc	a0,0x7
    8000113a:	fba50513          	addi	a0,a0,-70 # 800080f0 <digits+0xb0>
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
    800011ac:	00007917          	auipc	s2,0x7
    800011b0:	e5490913          	addi	s2,s2,-428 # 80008000 <etext>
    800011b4:	4729                	li	a4,10
    800011b6:	80007697          	auipc	a3,0x80007
    800011ba:	e4a68693          	addi	a3,a3,-438 # 8000 <_entry-0x7fff8000>
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
    800011ea:	00006617          	auipc	a2,0x6
    800011ee:	e1660613          	addi	a2,a2,-490 # 80007000 <_trampoline>
    800011f2:	040005b7          	lui	a1,0x4000
    800011f6:	15fd                	addi	a1,a1,-1
    800011f8:	05b2                	slli	a1,a1,0xc
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f1a080e7          	jalr	-230(ra) # 80001116 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001204:	8526                	mv	a0,s1
    80001206:	00001097          	auipc	ra,0x1
    8000120a:	c92080e7          	jalr	-878(ra) # 80001e98 <proc_mapstacks>
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
    8000122c:	00008797          	auipc	a5,0x8
    80001230:	dea7ba23          	sd	a0,-524(a5) # 80009020 <kernel_pagetable>
}
    80001234:	60a2                	ld	ra,8(sp)
    80001236:	6402                	ld	s0,0(sp)
    80001238:	0141                	addi	sp,sp,16
    8000123a:	8082                	ret

000000008000123c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
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
    80001256:	e795                	bnez	a5,80001282 <uvmunmap+0x46>
    80001258:	8a2a                	mv	s4,a0
    8000125a:	892e                	mv	s2,a1
    8000125c:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000125e:	0632                	slli	a2,a2,0xc
    80001260:	00b609b3          	add	s3,a2,a1
  
    
     //assign3
    if((pte = walk(pagetable, a, 0)) != 0){
      if((*pte & PTE_V) != 0){
        if(PTE_FLAGS(*pte) == PTE_V)
    80001264:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001266:	6a85                	lui	s5,0x1
    80001268:	0535e263          	bltu	a1,s3,800012ac <uvmunmap+0x70>
        }
        *pte = 0;
    }
  }
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
    80001282:	00007517          	auipc	a0,0x7
    80001286:	e7650513          	addi	a0,a0,-394 # 800080f8 <digits+0xb8>
    8000128a:	fffff097          	auipc	ra,0xfffff
    8000128e:	2a0080e7          	jalr	672(ra) # 8000052a <panic>
          panic("uvmunmap: not a leaf");
    80001292:	00007517          	auipc	a0,0x7
    80001296:	e7e50513          	addi	a0,a0,-386 # 80008110 <digits+0xd0>
    8000129a:	fffff097          	auipc	ra,0xfffff
    8000129e:	290080e7          	jalr	656(ra) # 8000052a <panic>
        *pte = 0;
    800012a2:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a6:	9956                	add	s2,s2,s5
    800012a8:	fd3972e3          	bgeu	s2,s3,8000126c <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) != 0){
    800012ac:	4601                	li	a2,0
    800012ae:	85ca                	mv	a1,s2
    800012b0:	8552                	mv	a0,s4
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	d04080e7          	jalr	-764(ra) # 80000fb6 <walk>
    800012ba:	84aa                	mv	s1,a0
    800012bc:	d56d                	beqz	a0,800012a6 <uvmunmap+0x6a>
      if((*pte & PTE_V) != 0){
    800012be:	611c                	ld	a5,0(a0)
    800012c0:	0017f713          	andi	a4,a5,1
    800012c4:	d36d                	beqz	a4,800012a6 <uvmunmap+0x6a>
        if(PTE_FLAGS(*pte) == PTE_V)
    800012c6:	3ff7f713          	andi	a4,a5,1023
    800012ca:	fd7704e3          	beq	a4,s7,80001292 <uvmunmap+0x56>
        if(do_free){
    800012ce:	fc0b0ae3          	beqz	s6,800012a2 <uvmunmap+0x66>
          uint64 pa = PTE2PA(*pte);
    800012d2:	83a9                	srli	a5,a5,0xa
          kfree((void*)pa);
    800012d4:	00c79513          	slli	a0,a5,0xc
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	6fe080e7          	jalr	1790(ra) # 800009d6 <kfree>
    800012e0:	b7c9                	j	800012a2 <uvmunmap+0x66>

00000000800012e2 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800012e2:	1101                	addi	sp,sp,-32
    800012e4:	ec06                	sd	ra,24(sp)
    800012e6:	e822                	sd	s0,16(sp)
    800012e8:	e426                	sd	s1,8(sp)
    800012ea:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800012ec:	fffff097          	auipc	ra,0xfffff
    800012f0:	7f6080e7          	jalr	2038(ra) # 80000ae2 <kalloc>
    800012f4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800012f6:	c519                	beqz	a0,80001304 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800012f8:	6605                	lui	a2,0x1
    800012fa:	4581                	li	a1,0
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	9d2080e7          	jalr	-1582(ra) # 80000cce <memset>
  return pagetable;
}
    80001304:	8526                	mv	a0,s1
    80001306:	60e2                	ld	ra,24(sp)
    80001308:	6442                	ld	s0,16(sp)
    8000130a:	64a2                	ld	s1,8(sp)
    8000130c:	6105                	addi	sp,sp,32
    8000130e:	8082                	ret

0000000080001310 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001310:	7179                	addi	sp,sp,-48
    80001312:	f406                	sd	ra,40(sp)
    80001314:	f022                	sd	s0,32(sp)
    80001316:	ec26                	sd	s1,24(sp)
    80001318:	e84a                	sd	s2,16(sp)
    8000131a:	e44e                	sd	s3,8(sp)
    8000131c:	e052                	sd	s4,0(sp)
    8000131e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001320:	6785                	lui	a5,0x1
    80001322:	04f67863          	bgeu	a2,a5,80001372 <uvminit+0x62>
    80001326:	8a2a                	mv	s4,a0
    80001328:	89ae                	mv	s3,a1
    8000132a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	7b6080e7          	jalr	1974(ra) # 80000ae2 <kalloc>
    80001334:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001336:	6605                	lui	a2,0x1
    80001338:	4581                	li	a1,0
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	994080e7          	jalr	-1644(ra) # 80000cce <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001342:	4779                	li	a4,30
    80001344:	86ca                	mv	a3,s2
    80001346:	6605                	lui	a2,0x1
    80001348:	4581                	li	a1,0
    8000134a:	8552                	mv	a0,s4
    8000134c:	00000097          	auipc	ra,0x0
    80001350:	d3c080e7          	jalr	-708(ra) # 80001088 <mappages>
  memmove(mem, src, sz);
    80001354:	8626                	mv	a2,s1
    80001356:	85ce                	mv	a1,s3
    80001358:	854a                	mv	a0,s2
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	9d0080e7          	jalr	-1584(ra) # 80000d2a <memmove>
}
    80001362:	70a2                	ld	ra,40(sp)
    80001364:	7402                	ld	s0,32(sp)
    80001366:	64e2                	ld	s1,24(sp)
    80001368:	6942                	ld	s2,16(sp)
    8000136a:	69a2                	ld	s3,8(sp)
    8000136c:	6a02                	ld	s4,0(sp)
    8000136e:	6145                	addi	sp,sp,48
    80001370:	8082                	ret
    panic("inituvm: more than a page");
    80001372:	00007517          	auipc	a0,0x7
    80001376:	db650513          	addi	a0,a0,-586 # 80008128 <digits+0xe8>
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	1b0080e7          	jalr	432(ra) # 8000052a <panic>

0000000080001382 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001382:	1101                	addi	sp,sp,-32
    80001384:	ec06                	sd	ra,24(sp)
    80001386:	e822                	sd	s0,16(sp)
    80001388:	e426                	sd	s1,8(sp)
    8000138a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000138c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000138e:	00b67d63          	bgeu	a2,a1,800013a8 <uvmdealloc+0x26>
    80001392:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001394:	6785                	lui	a5,0x1
    80001396:	17fd                	addi	a5,a5,-1
    80001398:	00f60733          	add	a4,a2,a5
    8000139c:	767d                	lui	a2,0xfffff
    8000139e:	8f71                	and	a4,a4,a2
    800013a0:	97ae                	add	a5,a5,a1
    800013a2:	8ff1                	and	a5,a5,a2
    800013a4:	00f76863          	bltu	a4,a5,800013b4 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013a8:	8526                	mv	a0,s1
    800013aa:	60e2                	ld	ra,24(sp)
    800013ac:	6442                	ld	s0,16(sp)
    800013ae:	64a2                	ld	s1,8(sp)
    800013b0:	6105                	addi	sp,sp,32
    800013b2:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013b4:	8f99                	sub	a5,a5,a4
    800013b6:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013b8:	4685                	li	a3,1
    800013ba:	0007861b          	sext.w	a2,a5
    800013be:	85ba                	mv	a1,a4
    800013c0:	00000097          	auipc	ra,0x0
    800013c4:	e7c080e7          	jalr	-388(ra) # 8000123c <uvmunmap>
    800013c8:	b7c5                	j	800013a8 <uvmdealloc+0x26>

00000000800013ca <uvmalloc>:
  if(newsz < oldsz)
    800013ca:	0ab66163          	bltu	a2,a1,8000146c <uvmalloc+0xa2>
{
    800013ce:	7139                	addi	sp,sp,-64
    800013d0:	fc06                	sd	ra,56(sp)
    800013d2:	f822                	sd	s0,48(sp)
    800013d4:	f426                	sd	s1,40(sp)
    800013d6:	f04a                	sd	s2,32(sp)
    800013d8:	ec4e                	sd	s3,24(sp)
    800013da:	e852                	sd	s4,16(sp)
    800013dc:	e456                	sd	s5,8(sp)
    800013de:	0080                	addi	s0,sp,64
    800013e0:	8aaa                	mv	s5,a0
    800013e2:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800013e4:	6985                	lui	s3,0x1
    800013e6:	19fd                	addi	s3,s3,-1
    800013e8:	95ce                	add	a1,a1,s3
    800013ea:	79fd                	lui	s3,0xfffff
    800013ec:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800013f0:	08c9f063          	bgeu	s3,a2,80001470 <uvmalloc+0xa6>
    800013f4:	894e                	mv	s2,s3
      mem = kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	6ec080e7          	jalr	1772(ra) # 80000ae2 <kalloc>
    800013fe:	84aa                	mv	s1,a0
      if(mem == 0){
    80001400:	c51d                	beqz	a0,8000142e <uvmalloc+0x64>
      memset(mem, 0, PGSIZE);
    80001402:	6605                	lui	a2,0x1
    80001404:	4581                	li	a1,0
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	8c8080e7          	jalr	-1848(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000140e:	4779                	li	a4,30
    80001410:	86a6                	mv	a3,s1
    80001412:	6605                	lui	a2,0x1
    80001414:	85ca                	mv	a1,s2
    80001416:	8556                	mv	a0,s5
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	c70080e7          	jalr	-912(ra) # 80001088 <mappages>
    80001420:	e905                	bnez	a0,80001450 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001422:	6785                	lui	a5,0x1
    80001424:	993e                	add	s2,s2,a5
    80001426:	fd4968e3          	bltu	s2,s4,800013f6 <uvmalloc+0x2c>
  return newsz;
    8000142a:	8552                	mv	a0,s4
    8000142c:	a809                	j	8000143e <uvmalloc+0x74>
        uvmdealloc(pagetable, a, oldsz);
    8000142e:	864e                	mv	a2,s3
    80001430:	85ca                	mv	a1,s2
    80001432:	8556                	mv	a0,s5
    80001434:	00000097          	auipc	ra,0x0
    80001438:	f4e080e7          	jalr	-178(ra) # 80001382 <uvmdealloc>
        return 0;
    8000143c:	4501                	li	a0,0
}
    8000143e:	70e2                	ld	ra,56(sp)
    80001440:	7442                	ld	s0,48(sp)
    80001442:	74a2                	ld	s1,40(sp)
    80001444:	7902                	ld	s2,32(sp)
    80001446:	69e2                	ld	s3,24(sp)
    80001448:	6a42                	ld	s4,16(sp)
    8000144a:	6aa2                	ld	s5,8(sp)
    8000144c:	6121                	addi	sp,sp,64
    8000144e:	8082                	ret
        kfree(mem);
    80001450:	8526                	mv	a0,s1
    80001452:	fffff097          	auipc	ra,0xfffff
    80001456:	584080e7          	jalr	1412(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    8000145a:	864e                	mv	a2,s3
    8000145c:	85ca                	mv	a1,s2
    8000145e:	8556                	mv	a0,s5
    80001460:	00000097          	auipc	ra,0x0
    80001464:	f22080e7          	jalr	-222(ra) # 80001382 <uvmdealloc>
        return 0;
    80001468:	4501                	li	a0,0
    8000146a:	bfd1                	j	8000143e <uvmalloc+0x74>
    return oldsz;
    8000146c:	852e                	mv	a0,a1
}
    8000146e:	8082                	ret
  return newsz;
    80001470:	8532                	mv	a0,a2
    80001472:	b7f1                	j	8000143e <uvmalloc+0x74>

0000000080001474 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001474:	7179                	addi	sp,sp,-48
    80001476:	f406                	sd	ra,40(sp)
    80001478:	f022                	sd	s0,32(sp)
    8000147a:	ec26                	sd	s1,24(sp)
    8000147c:	e84a                	sd	s2,16(sp)
    8000147e:	e44e                	sd	s3,8(sp)
    80001480:	e052                	sd	s4,0(sp)
    80001482:	1800                	addi	s0,sp,48
    80001484:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001486:	84aa                	mv	s1,a0
    80001488:	6905                	lui	s2,0x1
    8000148a:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000148c:	4985                	li	s3,1
    8000148e:	a821                	j	800014a6 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001490:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001492:	0532                	slli	a0,a0,0xc
    80001494:	00000097          	auipc	ra,0x0
    80001498:	fe0080e7          	jalr	-32(ra) # 80001474 <freewalk>
      pagetable[i] = 0;
    8000149c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014a0:	04a1                	addi	s1,s1,8
    800014a2:	03248163          	beq	s1,s2,800014c4 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014a6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014a8:	00f57793          	andi	a5,a0,15
    800014ac:	ff3782e3          	beq	a5,s3,80001490 <freewalk+0x1c>
    } else if(pte & PTE_V){ 
    800014b0:	8905                	andi	a0,a0,1
    800014b2:	d57d                	beqz	a0,800014a0 <freewalk+0x2c>
        // uint64 pa = PTE2PA(pte);
          //kfree((void*)pa);
      panic("freewalk: leaf\n");
    800014b4:	00007517          	auipc	a0,0x7
    800014b8:	c9450513          	addi	a0,a0,-876 # 80008148 <digits+0x108>
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	06e080e7          	jalr	110(ra) # 8000052a <panic>
    }
  }
  kfree((void*)pagetable);
    800014c4:	8552                	mv	a0,s4
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	510080e7          	jalr	1296(ra) # 800009d6 <kfree>
}
    800014ce:	70a2                	ld	ra,40(sp)
    800014d0:	7402                	ld	s0,32(sp)
    800014d2:	64e2                	ld	s1,24(sp)
    800014d4:	6942                	ld	s2,16(sp)
    800014d6:	69a2                	ld	s3,8(sp)
    800014d8:	6a02                	ld	s4,0(sp)
    800014da:	6145                	addi	sp,sp,48
    800014dc:	8082                	ret

00000000800014de <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800014de:	1101                	addi	sp,sp,-32
    800014e0:	ec06                	sd	ra,24(sp)
    800014e2:	e822                	sd	s0,16(sp)
    800014e4:	e426                	sd	s1,8(sp)
    800014e6:	1000                	addi	s0,sp,32
    800014e8:	84aa                	mv	s1,a0
  if(sz > 0)
    800014ea:	e999                	bnez	a1,80001500 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800014ec:	8526                	mv	a0,s1
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	f86080e7          	jalr	-122(ra) # 80001474 <freewalk>
}
    800014f6:	60e2                	ld	ra,24(sp)
    800014f8:	6442                	ld	s0,16(sp)
    800014fa:	64a2                	ld	s1,8(sp)
    800014fc:	6105                	addi	sp,sp,32
    800014fe:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001500:	6605                	lui	a2,0x1
    80001502:	167d                	addi	a2,a2,-1
    80001504:	962e                	add	a2,a2,a1
    80001506:	4685                	li	a3,1
    80001508:	8231                	srli	a2,a2,0xc
    8000150a:	4581                	li	a1,0
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	d30080e7          	jalr	-720(ra) # 8000123c <uvmunmap>
    80001514:	bfe1                	j	800014ec <uvmfree+0xe>

0000000080001516 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001516:	ca4d                	beqz	a2,800015c8 <uvmcopy+0xb2>
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
    8000152c:	0880                	addi	s0,sp,80
    8000152e:	8aaa                	mv	s5,a0
    80001530:	8b2e                	mv	s6,a1
    80001532:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001534:	4481                	li	s1,0
    80001536:	a029                	j	80001540 <uvmcopy+0x2a>
    80001538:	6785                	lui	a5,0x1
    8000153a:	94be                	add	s1,s1,a5
    8000153c:	0744fa63          	bgeu	s1,s4,800015b0 <uvmcopy+0x9a>
      kfree(mem);
      goto err;
    }*/
    
    //assign3
    if((pte = walk(old, i, 0)) !=0 && (*pte & PTE_V) != 0){
    80001540:	4601                	li	a2,0
    80001542:	85a6                	mv	a1,s1
    80001544:	8556                	mv	a0,s5
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	a70080e7          	jalr	-1424(ra) # 80000fb6 <walk>
    8000154e:	d56d                	beqz	a0,80001538 <uvmcopy+0x22>
    80001550:	6118                	ld	a4,0(a0)
    80001552:	00177793          	andi	a5,a4,1
    80001556:	d3ed                	beqz	a5,80001538 <uvmcopy+0x22>
      pa = PTE2PA(*pte);
    80001558:	00a75593          	srli	a1,a4,0xa
    8000155c:	00c59b93          	slli	s7,a1,0xc
      flags = PTE_FLAGS(*pte);
    80001560:	3ff77913          	andi	s2,a4,1023
      if((mem = kalloc()) == 0)
    80001564:	fffff097          	auipc	ra,0xfffff
    80001568:	57e080e7          	jalr	1406(ra) # 80000ae2 <kalloc>
    8000156c:	89aa                	mv	s3,a0
    8000156e:	c515                	beqz	a0,8000159a <uvmcopy+0x84>
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    80001570:	6605                	lui	a2,0x1
    80001572:	85de                	mv	a1,s7
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	7b6080e7          	jalr	1974(ra) # 80000d2a <memmove>
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000157c:	874a                	mv	a4,s2
    8000157e:	86ce                	mv	a3,s3
    80001580:	6605                	lui	a2,0x1
    80001582:	85a6                	mv	a1,s1
    80001584:	855a                	mv	a0,s6
    80001586:	00000097          	auipc	ra,0x0
    8000158a:	b02080e7          	jalr	-1278(ra) # 80001088 <mappages>
    8000158e:	d54d                	beqz	a0,80001538 <uvmcopy+0x22>
        kfree(mem);
    80001590:	854e                	mv	a0,s3
    80001592:	fffff097          	auipc	ra,0xfffff
    80001596:	444080e7          	jalr	1092(ra) # 800009d6 <kfree>
    
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000159a:	4685                	li	a3,1
    8000159c:	00c4d613          	srli	a2,s1,0xc
    800015a0:	4581                	li	a1,0
    800015a2:	855a                	mv	a0,s6
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	c98080e7          	jalr	-872(ra) # 8000123c <uvmunmap>
  return -1;
    800015ac:	557d                	li	a0,-1
    800015ae:	a011                	j	800015b2 <uvmcopy+0x9c>
  return 0;
    800015b0:	4501                	li	a0,0
}
    800015b2:	60a6                	ld	ra,72(sp)
    800015b4:	6406                	ld	s0,64(sp)
    800015b6:	74e2                	ld	s1,56(sp)
    800015b8:	7942                	ld	s2,48(sp)
    800015ba:	79a2                	ld	s3,40(sp)
    800015bc:	7a02                	ld	s4,32(sp)
    800015be:	6ae2                	ld	s5,24(sp)
    800015c0:	6b42                	ld	s6,16(sp)
    800015c2:	6ba2                	ld	s7,8(sp)
    800015c4:	6161                	addi	sp,sp,80
    800015c6:	8082                	ret
  return 0;
    800015c8:	4501                	li	a0,0
}
    800015ca:	8082                	ret

00000000800015cc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800015cc:	1141                	addi	sp,sp,-16
    800015ce:	e406                	sd	ra,8(sp)
    800015d0:	e022                	sd	s0,0(sp)
    800015d2:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800015d4:	4601                	li	a2,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	9e0080e7          	jalr	-1568(ra) # 80000fb6 <walk>
  if(pte == 0)
    800015de:	c901                	beqz	a0,800015ee <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800015e0:	611c                	ld	a5,0(a0)
    800015e2:	9bbd                	andi	a5,a5,-17
    800015e4:	e11c                	sd	a5,0(a0)
}
    800015e6:	60a2                	ld	ra,8(sp)
    800015e8:	6402                	ld	s0,0(sp)
    800015ea:	0141                	addi	sp,sp,16
    800015ec:	8082                	ret
    panic("uvmclear");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	b6a50513          	addi	a0,a0,-1174 # 80008158 <digits+0x118>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f34080e7          	jalr	-204(ra) # 8000052a <panic>

00000000800015fe <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800015fe:	c6bd                	beqz	a3,8000166c <copyout+0x6e>
{
    80001600:	715d                	addi	sp,sp,-80
    80001602:	e486                	sd	ra,72(sp)
    80001604:	e0a2                	sd	s0,64(sp)
    80001606:	fc26                	sd	s1,56(sp)
    80001608:	f84a                	sd	s2,48(sp)
    8000160a:	f44e                	sd	s3,40(sp)
    8000160c:	f052                	sd	s4,32(sp)
    8000160e:	ec56                	sd	s5,24(sp)
    80001610:	e85a                	sd	s6,16(sp)
    80001612:	e45e                	sd	s7,8(sp)
    80001614:	e062                	sd	s8,0(sp)
    80001616:	0880                	addi	s0,sp,80
    80001618:	8b2a                	mv	s6,a0
    8000161a:	8c2e                	mv	s8,a1
    8000161c:	8a32                	mv	s4,a2
    8000161e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001620:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
   
    if(pa0 == 0){
      return -1;
    }
    n = PGSIZE - (dstva - va0);
    80001622:	6a85                	lui	s5,0x1
    80001624:	a015                	j	80001648 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001626:	9562                	add	a0,a0,s8
    80001628:	0004861b          	sext.w	a2,s1
    8000162c:	85d2                	mv	a1,s4
    8000162e:	41250533          	sub	a0,a0,s2
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	6f8080e7          	jalr	1784(ra) # 80000d2a <memmove>

    len -= n;
    8000163a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000163e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001640:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001644:	02098263          	beqz	s3,80001668 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001648:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000164c:	85ca                	mv	a1,s2
    8000164e:	855a                	mv	a0,s6
    80001650:	00000097          	auipc	ra,0x0
    80001654:	9f6080e7          	jalr	-1546(ra) # 80001046 <walkaddr>
    if(pa0 == 0){
    80001658:	cd01                	beqz	a0,80001670 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000165a:	418904b3          	sub	s1,s2,s8
    8000165e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001660:	fc99f3e3          	bgeu	s3,s1,80001626 <copyout+0x28>
    80001664:	84ce                	mv	s1,s3
    80001666:	b7c1                	j	80001626 <copyout+0x28>
  }
  return 0;
    80001668:	4501                	li	a0,0
    8000166a:	a021                	j	80001672 <copyout+0x74>
    8000166c:	4501                	li	a0,0
}
    8000166e:	8082                	ret
      return -1;
    80001670:	557d                	li	a0,-1
}
    80001672:	60a6                	ld	ra,72(sp)
    80001674:	6406                	ld	s0,64(sp)
    80001676:	74e2                	ld	s1,56(sp)
    80001678:	7942                	ld	s2,48(sp)
    8000167a:	79a2                	ld	s3,40(sp)
    8000167c:	7a02                	ld	s4,32(sp)
    8000167e:	6ae2                	ld	s5,24(sp)
    80001680:	6b42                	ld	s6,16(sp)
    80001682:	6ba2                	ld	s7,8(sp)
    80001684:	6c02                	ld	s8,0(sp)
    80001686:	6161                	addi	sp,sp,80
    80001688:	8082                	ret

000000008000168a <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000168a:	caa5                	beqz	a3,800016fa <copyin+0x70>
{
    8000168c:	715d                	addi	sp,sp,-80
    8000168e:	e486                	sd	ra,72(sp)
    80001690:	e0a2                	sd	s0,64(sp)
    80001692:	fc26                	sd	s1,56(sp)
    80001694:	f84a                	sd	s2,48(sp)
    80001696:	f44e                	sd	s3,40(sp)
    80001698:	f052                	sd	s4,32(sp)
    8000169a:	ec56                	sd	s5,24(sp)
    8000169c:	e85a                	sd	s6,16(sp)
    8000169e:	e45e                	sd	s7,8(sp)
    800016a0:	e062                	sd	s8,0(sp)
    800016a2:	0880                	addi	s0,sp,80
    800016a4:	8b2a                	mv	s6,a0
    800016a6:	8a2e                	mv	s4,a1
    800016a8:	8c32                	mv	s8,a2
    800016aa:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800016ac:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800016ae:	6a85                	lui	s5,0x1
    800016b0:	a01d                	j	800016d6 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016b2:	018505b3          	add	a1,a0,s8
    800016b6:	0004861b          	sext.w	a2,s1
    800016ba:	412585b3          	sub	a1,a1,s2
    800016be:	8552                	mv	a0,s4
    800016c0:	fffff097          	auipc	ra,0xfffff
    800016c4:	66a080e7          	jalr	1642(ra) # 80000d2a <memmove>

    len -= n;
    800016c8:	409989b3          	sub	s3,s3,s1
    dst += n;
    800016cc:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800016ce:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016d2:	02098263          	beqz	s3,800016f6 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800016d6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016da:	85ca                	mv	a1,s2
    800016dc:	855a                	mv	a0,s6
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	968080e7          	jalr	-1688(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    800016e6:	cd01                	beqz	a0,800016fe <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800016e8:	418904b3          	sub	s1,s2,s8
    800016ec:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ee:	fc99f2e3          	bgeu	s3,s1,800016b2 <copyin+0x28>
    800016f2:	84ce                	mv	s1,s3
    800016f4:	bf7d                	j	800016b2 <copyin+0x28>
  }
  return 0;
    800016f6:	4501                	li	a0,0
    800016f8:	a021                	j	80001700 <copyin+0x76>
    800016fa:	4501                	li	a0,0
}
    800016fc:	8082                	ret
      return -1;
    800016fe:	557d                	li	a0,-1
}
    80001700:	60a6                	ld	ra,72(sp)
    80001702:	6406                	ld	s0,64(sp)
    80001704:	74e2                	ld	s1,56(sp)
    80001706:	7942                	ld	s2,48(sp)
    80001708:	79a2                	ld	s3,40(sp)
    8000170a:	7a02                	ld	s4,32(sp)
    8000170c:	6ae2                	ld	s5,24(sp)
    8000170e:	6b42                	ld	s6,16(sp)
    80001710:	6ba2                	ld	s7,8(sp)
    80001712:	6c02                	ld	s8,0(sp)
    80001714:	6161                	addi	sp,sp,80
    80001716:	8082                	ret

0000000080001718 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001718:	c6c5                	beqz	a3,800017c0 <copyinstr+0xa8>
{
    8000171a:	715d                	addi	sp,sp,-80
    8000171c:	e486                	sd	ra,72(sp)
    8000171e:	e0a2                	sd	s0,64(sp)
    80001720:	fc26                	sd	s1,56(sp)
    80001722:	f84a                	sd	s2,48(sp)
    80001724:	f44e                	sd	s3,40(sp)
    80001726:	f052                	sd	s4,32(sp)
    80001728:	ec56                	sd	s5,24(sp)
    8000172a:	e85a                	sd	s6,16(sp)
    8000172c:	e45e                	sd	s7,8(sp)
    8000172e:	0880                	addi	s0,sp,80
    80001730:	8a2a                	mv	s4,a0
    80001732:	8b2e                	mv	s6,a1
    80001734:	8bb2                	mv	s7,a2
    80001736:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001738:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000173a:	6985                	lui	s3,0x1
    8000173c:	a035                	j	80001768 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000173e:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001742:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001744:	0017b793          	seqz	a5,a5
    80001748:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000174c:	60a6                	ld	ra,72(sp)
    8000174e:	6406                	ld	s0,64(sp)
    80001750:	74e2                	ld	s1,56(sp)
    80001752:	7942                	ld	s2,48(sp)
    80001754:	79a2                	ld	s3,40(sp)
    80001756:	7a02                	ld	s4,32(sp)
    80001758:	6ae2                	ld	s5,24(sp)
    8000175a:	6b42                	ld	s6,16(sp)
    8000175c:	6ba2                	ld	s7,8(sp)
    8000175e:	6161                	addi	sp,sp,80
    80001760:	8082                	ret
    srcva = va0 + PGSIZE;
    80001762:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001766:	c8a9                	beqz	s1,800017b8 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001768:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000176c:	85ca                	mv	a1,s2
    8000176e:	8552                	mv	a0,s4
    80001770:	00000097          	auipc	ra,0x0
    80001774:	8d6080e7          	jalr	-1834(ra) # 80001046 <walkaddr>
    if(pa0 == 0)
    80001778:	c131                	beqz	a0,800017bc <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000177a:	41790833          	sub	a6,s2,s7
    8000177e:	984e                	add	a6,a6,s3
    if(n > max)
    80001780:	0104f363          	bgeu	s1,a6,80001786 <copyinstr+0x6e>
    80001784:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001786:	955e                	add	a0,a0,s7
    80001788:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000178c:	fc080be3          	beqz	a6,80001762 <copyinstr+0x4a>
    80001790:	985a                	add	a6,a6,s6
    80001792:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001794:	41650633          	sub	a2,a0,s6
    80001798:	14fd                	addi	s1,s1,-1
    8000179a:	9b26                	add	s6,s6,s1
    8000179c:	00f60733          	add	a4,a2,a5
    800017a0:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd1000>
    800017a4:	df49                	beqz	a4,8000173e <copyinstr+0x26>
        *dst = *p;
    800017a6:	00e78023          	sb	a4,0(a5)
      --max;
    800017aa:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800017ae:	0785                	addi	a5,a5,1
    while(n > 0){
    800017b0:	ff0796e3          	bne	a5,a6,8000179c <copyinstr+0x84>
      dst++;
    800017b4:	8b42                	mv	s6,a6
    800017b6:	b775                	j	80001762 <copyinstr+0x4a>
    800017b8:	4781                	li	a5,0
    800017ba:	b769                	j	80001744 <copyinstr+0x2c>
      return -1;
    800017bc:	557d                	li	a0,-1
    800017be:	b779                	j	8000174c <copyinstr+0x34>
  int got_null = 0;
    800017c0:	4781                	li	a5,0
  if(got_null){
    800017c2:	0017b793          	seqz	a5,a5
    800017c6:	40f00533          	neg	a0,a5
}
    800017ca:	8082                	ret

00000000800017cc <swap_page_into_file>:


 

void swap_page_into_file(int offset){
    800017cc:	7179                	addi	sp,sp,-48
    800017ce:	f406                	sd	ra,40(sp)
    800017d0:	f022                	sd	s0,32(sp)
    800017d2:	ec26                	sd	s1,24(sp)
    800017d4:	e84a                	sd	s2,16(sp)
    800017d6:	e44e                	sd	s3,8(sp)
    800017d8:	e052                	sd	s4,0(sp)
    800017da:	1800                	addi	s0,sp,48
    800017dc:	8a2a                	mv	s4,a0
    struct proc * p = myproc();
    800017de:	00001097          	auipc	ra,0x1
    800017e2:	82c080e7          	jalr	-2004(ra) # 8000200a <myproc>
    800017e6:	892a                	mv	s2,a0
    int remove_file_indx = find_file_to_remove();
    uint64 removed_page_VA = remove_file_indx*PGSIZE;
    printf("chosen file %d \n", remove_file_indx);
    800017e8:	4581                	li	a1,0
    800017ea:	00007517          	auipc	a0,0x7
    800017ee:	97e50513          	addi	a0,a0,-1666 # 80008168 <digits+0x128>
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	d82080e7          	jalr	-638(ra) # 80000574 <printf>
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    800017fa:	4601                	li	a2,0
    800017fc:	4581                	li	a1,0
    800017fe:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	7b4080e7          	jalr	1972(ra) # 80000fb6 <walk>
    8000180a:	89aa                	mv	s3,a0
    //write the information from this file to memory
    uint64 physical_addr = PTE2PA(*out_page_entry);
    8000180c:	6104                	ld	s1,0(a0)
    8000180e:	80a9                	srli	s1,s1,0xa
    80001810:	04b2                	slli	s1,s1,0xc
    if(writeToSwapFile(p,(char*)physical_addr,offset,PGSIZE) ==  -1)
    80001812:	6685                	lui	a3,0x1
    80001814:	8652                	mv	a2,s4
    80001816:	85a6                	mv	a1,s1
    80001818:	854a                	mv	a0,s2
    8000181a:	00003097          	auipc	ra,0x3
    8000181e:	fb4080e7          	jalr	-76(ra) # 800047ce <writeToSwapFile>
    80001822:	57fd                	li	a5,-1
    80001824:	02f50b63          	beq	a0,a5,8000185a <swap_page_into_file+0x8e>
      panic("write to file failed");
    //free the RAM memmory of the swapped page
    kfree((void*)physical_addr);
    80001828:	8526                	mv	a0,s1
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	1ac080e7          	jalr	428(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    80001832:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
    80001836:	bfe7f793          	andi	a5,a5,-1026
    8000183a:	4007e793          	ori	a5,a5,1024
    8000183e:	00f9b023          	sd	a5,0(s3)
    p->paging_meta_data[remove_file_indx].offset = offset;
    80001842:	17492823          	sw	s4,368(s2)
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    80001846:	16092c23          	sw	zero,376(s2)
      
}
    8000184a:	70a2                	ld	ra,40(sp)
    8000184c:	7402                	ld	s0,32(sp)
    8000184e:	64e2                	ld	s1,24(sp)
    80001850:	6942                	ld	s2,16(sp)
    80001852:	69a2                	ld	s3,8(sp)
    80001854:	6a02                	ld	s4,0(sp)
    80001856:	6145                	addi	sp,sp,48
    80001858:	8082                	ret
      panic("write to file failed");
    8000185a:	00007517          	auipc	a0,0x7
    8000185e:	92650513          	addi	a0,a0,-1754 # 80008180 <digits+0x140>
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	cc8080e7          	jalr	-824(ra) # 8000052a <panic>

000000008000186a <get_num_of_pages_in_memory>:

int get_num_of_pages_in_memory(){
    8000186a:	7179                	addi	sp,sp,-48
    8000186c:	f406                	sd	ra,40(sp)
    8000186e:	f022                	sd	s0,32(sp)
    80001870:	ec26                	sd	s1,24(sp)
    80001872:	e84a                	sd	s2,16(sp)
    80001874:	e44e                	sd	s3,8(sp)
    80001876:	1800                	addi	s0,sp,48
  int counter = 0;
  for(int i=0; i<32; i++){
    80001878:	4481                	li	s1,0
  int counter = 0;
    8000187a:	4901                	li	s2,0
  for(int i=0; i<32; i++){
    8000187c:	02000993          	li	s3,32
    80001880:	a021                	j	80001888 <get_num_of_pages_in_memory+0x1e>
    80001882:	2485                	addiw	s1,s1,1
    80001884:	03348063          	beq	s1,s3,800018a4 <get_num_of_pages_in_memory+0x3a>
    if(myproc()->paging_meta_data[i].in_memory)
    80001888:	00000097          	auipc	ra,0x0
    8000188c:	782080e7          	jalr	1922(ra) # 8000200a <myproc>
    80001890:	00149793          	slli	a5,s1,0x1
    80001894:	97a6                	add	a5,a5,s1
    80001896:	078a                	slli	a5,a5,0x2
    80001898:	97aa                	add	a5,a5,a0
    8000189a:	1787a783          	lw	a5,376(a5)
    8000189e:	d3f5                	beqz	a5,80001882 <get_num_of_pages_in_memory+0x18>
      counter = counter+1;
    800018a0:	2905                	addiw	s2,s2,1
    800018a2:	b7c5                	j	80001882 <get_num_of_pages_in_memory+0x18>
  }
  return counter; 
}
    800018a4:	854a                	mv	a0,s2
    800018a6:	70a2                	ld	ra,40(sp)
    800018a8:	7402                	ld	s0,32(sp)
    800018aa:	64e2                	ld	s1,24(sp)
    800018ac:	6942                	ld	s2,16(sp)
    800018ae:	69a2                	ld	s3,8(sp)
    800018b0:	6145                	addi	sp,sp,48
    800018b2:	8082                	ret

00000000800018b4 <page_in>:


void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    800018b4:	7139                	addi	sp,sp,-64
    800018b6:	fc06                	sd	ra,56(sp)
    800018b8:	f822                	sd	s0,48(sp)
    800018ba:	f426                	sd	s1,40(sp)
    800018bc:	f04a                	sd	s2,32(sp)
    800018be:	ec4e                	sd	s3,24(sp)
    800018c0:	e852                	sd	s4,16(sp)
    800018c2:	e456                	sd	s5,8(sp)
    800018c4:	0080                	addi	s0,sp,64
    800018c6:	89ae                	mv	s3,a1
  //get the page number of the missing in ram page
  int current_page_index = PGROUNDDOWN(faulting_address)/PGSIZE;
    800018c8:	8131                	srli	a0,a0,0xc
    800018ca:	0005091b          	sext.w	s2,a0
  //get its offset in the saved file
  uint offset = myproc()->paging_meta_data[current_page_index].offset;
    800018ce:	00000097          	auipc	ra,0x0
    800018d2:	73c080e7          	jalr	1852(ra) # 8000200a <myproc>
    800018d6:	00191793          	slli	a5,s2,0x1
    800018da:	97ca                	add	a5,a5,s2
    800018dc:	078a                	slli	a5,a5,0x2
    800018de:	97aa                	add	a5,a5,a0
    800018e0:	1707aa83          	lw	s5,368(a5)
    800018e4:	000a8a1b          	sext.w	s4,s5
  if(offset == -1){
    800018e8:	57fd                	li	a5,-1
    800018ea:	08fa0f63          	beq	s4,a5,80001988 <page_in+0xd4>
    panic("offset is -1");
  }
  //allocate a buffer for the information from the file
  char* read_buffer;
  if((read_buffer = kalloc()) == 0)
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	1f4080e7          	jalr	500(ra) # 80000ae2 <kalloc>
    800018f6:	84aa                	mv	s1,a0
    800018f8:	c145                	beqz	a0,80001998 <page_in+0xe4>
    panic("not enough space to kalloc");
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	710080e7          	jalr	1808(ra) # 8000200a <myproc>
    80001902:	6685                	lui	a3,0x1
    80001904:	8652                	mv	a2,s4
    80001906:	85a6                	mv	a1,s1
    80001908:	00003097          	auipc	ra,0x3
    8000190c:	eea080e7          	jalr	-278(ra) # 800047f2 <readFromSwapFile>
    80001910:	57fd                	li	a5,-1
    80001912:	08f50b63          	beq	a0,a5,800019a8 <page_in+0xf4>
    panic("read from file failed");
  if(get_num_of_pages_in_memory() > MAX_PSYC_PAGES){
    80001916:	00000097          	auipc	ra,0x0
    8000191a:	f54080e7          	jalr	-172(ra) # 8000186a <get_num_of_pages_in_memory>
    8000191e:	47c1                	li	a5,16
    80001920:	08a7cc63          	blt	a5,a0,800019b8 <page_in+0x104>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
  }  
  else{
      *missing_pte_entry = PA2PTE((uint64)read_buffer) | PTE_V; 
    80001924:	80b1                	srli	s1,s1,0xc
    80001926:	04aa                	slli	s1,s1,0xa
    80001928:	0014e493          	ori	s1,s1,1
    8000192c:	0099b023          	sd	s1,0(s3)
  }
  //update offsets and aging of the files
  myproc()->paging_meta_data[current_page_index].aging = init_aging(current_page_index);
    80001930:	00000097          	auipc	ra,0x0
    80001934:	6da080e7          	jalr	1754(ra) # 8000200a <myproc>
    80001938:	00191493          	slli	s1,s2,0x1
    8000193c:	012487b3          	add	a5,s1,s2
    80001940:	078a                	slli	a5,a5,0x2
    80001942:	953e                	add	a0,a0,a5
    80001944:	16052a23          	sw	zero,372(a0)
  myproc()->paging_meta_data[current_page_index].offset = -1;
    80001948:	00000097          	auipc	ra,0x0
    8000194c:	6c2080e7          	jalr	1730(ra) # 8000200a <myproc>
    80001950:	012487b3          	add	a5,s1,s2
    80001954:	078a                	slli	a5,a5,0x2
    80001956:	953e                	add	a0,a0,a5
    80001958:	57fd                	li	a5,-1
    8000195a:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_index].in_memory = 1;
    8000195e:	00000097          	auipc	ra,0x0
    80001962:	6ac080e7          	jalr	1708(ra) # 8000200a <myproc>
    80001966:	94ca                	add	s1,s1,s2
    80001968:	048a                	slli	s1,s1,0x2
    8000196a:	94aa                	add	s1,s1,a0
    8000196c:	4785                	li	a5,1
    8000196e:	16f4ac23          	sw	a5,376(s1)
    80001972:	12000073          	sfence.vma
  sfence_vma(); //refresh TLB
}
    80001976:	70e2                	ld	ra,56(sp)
    80001978:	7442                	ld	s0,48(sp)
    8000197a:	74a2                	ld	s1,40(sp)
    8000197c:	7902                	ld	s2,32(sp)
    8000197e:	69e2                	ld	s3,24(sp)
    80001980:	6a42                	ld	s4,16(sp)
    80001982:	6aa2                	ld	s5,8(sp)
    80001984:	6121                	addi	sp,sp,64
    80001986:	8082                	ret
    panic("offset is -1");
    80001988:	00007517          	auipc	a0,0x7
    8000198c:	81050513          	addi	a0,a0,-2032 # 80008198 <digits+0x158>
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	b9a080e7          	jalr	-1126(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    80001998:	00007517          	auipc	a0,0x7
    8000199c:	81050513          	addi	a0,a0,-2032 # 800081a8 <digits+0x168>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	b8a080e7          	jalr	-1142(ra) # 8000052a <panic>
    panic("read from file failed");
    800019a8:	00007517          	auipc	a0,0x7
    800019ac:	82050513          	addi	a0,a0,-2016 # 800081c8 <digits+0x188>
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	b7a080e7          	jalr	-1158(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    800019b8:	8556                	mv	a0,s5
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	e12080e7          	jalr	-494(ra) # 800017cc <swap_page_into_file>
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    800019c2:	80b1                	srli	s1,s1,0xc
    800019c4:	04aa                	slli	s1,s1,0xa
    800019c6:	0009b783          	ld	a5,0(s3)
    800019ca:	3fe7f793          	andi	a5,a5,1022
    800019ce:	8cdd                	or	s1,s1,a5
    800019d0:	0014e493          	ori	s1,s1,1
    800019d4:	0099b023          	sd	s1,0(s3)
    800019d8:	bfa1                	j	80001930 <page_in+0x7c>

00000000800019da <lazy_memory_allocation>:

void lazy_memory_allocation(uint64 faulting_address){
    800019da:	1101                	addi	sp,sp,-32
    800019dc:	ec06                	sd	ra,24(sp)
    800019de:	e822                	sd	s0,16(sp)
    800019e0:	e426                	sd	s1,8(sp)
    800019e2:	1000                	addi	s0,sp,32
    800019e4:	84aa                	mv	s1,a0
  uvmalloc(myproc()->pagetable,PGROUNDDOWN(faulting_address), PGROUNDDOWN(faulting_address) + PGSIZE);
    800019e6:	00000097          	auipc	ra,0x0
    800019ea:	624080e7          	jalr	1572(ra) # 8000200a <myproc>
    800019ee:	75fd                	lui	a1,0xfffff
    800019f0:	8de5                	and	a1,a1,s1
    800019f2:	6605                	lui	a2,0x1
    800019f4:	962e                	add	a2,a2,a1
    800019f6:	6928                	ld	a0,80(a0)
    800019f8:	00000097          	auipc	ra,0x0
    800019fc:	9d2080e7          	jalr	-1582(ra) # 800013ca <uvmalloc>
      int page_num = PGROUNDDOWN(faulting_address)/PGSIZE;
      myproc()->paging_meta_data[page_num].in_memory = 1;
      myproc()->paging_meta_data[page_num].aging = init_aging(page_num);
    #endif
      
}
    80001a00:	60e2                	ld	ra,24(sp)
    80001a02:	6442                	ld	s0,16(sp)
    80001a04:	64a2                	ld	s1,8(sp)
    80001a06:	6105                	addi	sp,sp,32
    80001a08:	8082                	ret

0000000080001a0a <check_page_fault>:

void check_page_fault(){
    80001a0a:	1101                	addi	sp,sp,-32
    80001a0c:	ec06                	sd	ra,24(sp)
    80001a0e:	e822                	sd	s0,16(sp)
    80001a10:	e426                	sd	s1,8(sp)
    80001a12:	e04a                	sd	s2,0(sp)
    80001a14:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80001a16:	14302973          	csrr	s2,stval
  uint64 faulting_address = r_stval(); 
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80001a1a:	00000097          	auipc	ra,0x0
    80001a1e:	5f0080e7          	jalr	1520(ra) # 8000200a <myproc>
    80001a22:	4601                	li	a2,0
    80001a24:	75fd                	lui	a1,0xfffff
    80001a26:	00b975b3          	and	a1,s2,a1
    80001a2a:	6928                	ld	a0,80(a0)
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	58a080e7          	jalr	1418(ra) # 80000fb6 <walk>
  if(pte_entry !=0 &&(!(*pte_entry & PTE_V)  && *pte_entry & PTE_PG)){
    80001a34:	c909                	beqz	a0,80001a46 <check_page_fault+0x3c>
    80001a36:	84aa                	mv	s1,a0
    80001a38:	611c                	ld	a5,0(a0)
    80001a3a:	4017f793          	andi	a5,a5,1025
    80001a3e:	40000713          	li	a4,1024
    80001a42:	02e78463          	beq	a5,a4,80001a6a <check_page_fault+0x60>
    printf("Page Fault - Page was out of memory\n");
    page_in(faulting_address, pte_entry);
  }
  else if (faulting_address <= myproc()->sz){
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	5c4080e7          	jalr	1476(ra) # 8000200a <myproc>
    80001a4e:	653c                	ld	a5,72(a0)
    80001a50:	0327ec63          	bltu	a5,s2,80001a88 <check_page_fault+0x7e>
    //printf("Page Fault - Lazy allocation\n");
    lazy_memory_allocation(faulting_address);
    80001a54:	854a                	mv	a0,s2
    80001a56:	00000097          	auipc	ra,0x0
    80001a5a:	f84080e7          	jalr	-124(ra) # 800019da <lazy_memory_allocation>
  }
  else
    exit(-1);
}
    80001a5e:	60e2                	ld	ra,24(sp)
    80001a60:	6442                	ld	s0,16(sp)
    80001a62:	64a2                	ld	s1,8(sp)
    80001a64:	6902                	ld	s2,0(sp)
    80001a66:	6105                	addi	sp,sp,32
    80001a68:	8082                	ret
    printf("Page Fault - Page was out of memory\n");
    80001a6a:	00006517          	auipc	a0,0x6
    80001a6e:	77650513          	addi	a0,a0,1910 # 800081e0 <digits+0x1a0>
    80001a72:	fffff097          	auipc	ra,0xfffff
    80001a76:	b02080e7          	jalr	-1278(ra) # 80000574 <printf>
    page_in(faulting_address, pte_entry);
    80001a7a:	85a6                	mv	a1,s1
    80001a7c:	854a                	mv	a0,s2
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	e36080e7          	jalr	-458(ra) # 800018b4 <page_in>
    80001a86:	bfe1                	j	80001a5e <check_page_fault+0x54>
    exit(-1);
    80001a88:	557d                	li	a0,-1
    80001a8a:	00001097          	auipc	ra,0x1
    80001a8e:	f4e080e7          	jalr	-178(ra) # 800029d8 <exit>
}
    80001a92:	b7f1                	j	80001a5e <check_page_fault+0x54>

0000000080001a94 <minimum_counter_NFUA>:


int minimum_counter_NFUA(){
    80001a94:	1141                	addi	sp,sp,-16
    80001a96:	e406                	sd	ra,8(sp)
    80001a98:	e022                	sd	s0,0(sp)
    80001a9a:	0800                	addi	s0,sp,16
  struct proc * p = myproc();
    80001a9c:	00000097          	auipc	ra,0x0
    80001aa0:	56e080e7          	jalr	1390(ra) # 8000200a <myproc>
  uint min_age = -1;
  int index_page = -1;
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001aa4:	19850793          	addi	a5,a0,408
    80001aa8:	470d                	li	a4,3
  int index_page = -1;
    80001aaa:	557d                	li	a0,-1
  uint min_age = -1;
    80001aac:	55fd                	li	a1,-1
    if (p->paging_meta_data[i].in_memory ){
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    80001aae:	58fd                	li	a7,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001ab0:	02000813          	li	a6,32
    80001ab4:	a039                	j	80001ac2 <minimum_counter_NFUA+0x2e>
          min_age = p->paging_meta_data[i].aging;
    80001ab6:	420c                	lw	a1,0(a2)
    80001ab8:	853a                	mv	a0,a4
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    80001aba:	2705                	addiw	a4,a4,1
    80001abc:	07b1                	addi	a5,a5,12
    80001abe:	01070b63          	beq	a4,a6,80001ad4 <minimum_counter_NFUA+0x40>
    if (p->paging_meta_data[i].in_memory ){
    80001ac2:	863e                	mv	a2,a5
    80001ac4:	43d4                	lw	a3,4(a5)
    80001ac6:	daf5                	beqz	a3,80001aba <minimum_counter_NFUA+0x26>
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    80001ac8:	ff1587e3          	beq	a1,a7,80001ab6 <minimum_counter_NFUA+0x22>
    80001acc:	4394                	lw	a3,0(a5)
    80001ace:	feb6f6e3          	bgeu	a3,a1,80001aba <minimum_counter_NFUA+0x26>
    80001ad2:	b7d5                	j	80001ab6 <minimum_counter_NFUA+0x22>
          index_page = i;
        }
      }
  }
  if(min_age == -1)
    80001ad4:	57fd                	li	a5,-1
    80001ad6:	00f58663          	beq	a1,a5,80001ae2 <minimum_counter_NFUA+0x4e>
    panic("page replacment algorithem failed");
  return index_page;
}
    80001ada:	60a2                	ld	ra,8(sp)
    80001adc:	6402                	ld	s0,0(sp)
    80001ade:	0141                	addi	sp,sp,16
    80001ae0:	8082                	ret
    panic("page replacment algorithem failed");
    80001ae2:	00006517          	auipc	a0,0x6
    80001ae6:	72650513          	addi	a0,a0,1830 # 80008208 <digits+0x1c8>
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	a40080e7          	jalr	-1472(ra) # 8000052a <panic>

0000000080001af2 <count_one_bits>:

int count_one_bits(uint age){
    80001af2:	1141                	addi	sp,sp,-16
    80001af4:	e422                	sd	s0,8(sp)
    80001af6:	0800                	addi	s0,sp,16
  int count = 0;
  while(age) {
    80001af8:	cd01                	beqz	a0,80001b10 <count_one_bits+0x1e>
    80001afa:	87aa                	mv	a5,a0
  int count = 0;
    80001afc:	4501                	li	a0,0
      count += age & 1;
    80001afe:	0017f713          	andi	a4,a5,1
    80001b02:	9d39                	addw	a0,a0,a4
      age >>= 1;
    80001b04:	0017d79b          	srliw	a5,a5,0x1
  while(age) {
    80001b08:	fbfd                	bnez	a5,80001afe <count_one_bits+0xc>
  }
  return count;
}
    80001b0a:	6422                	ld	s0,8(sp)
    80001b0c:	0141                	addi	sp,sp,16
    80001b0e:	8082                	ret
  int count = 0;
    80001b10:	4501                	li	a0,0
    80001b12:	bfe5                	j	80001b0a <count_one_bits+0x18>

0000000080001b14 <minimum_ones>:

int minimum_ones(){
    80001b14:	715d                	addi	sp,sp,-80
    80001b16:	e486                	sd	ra,72(sp)
    80001b18:	e0a2                	sd	s0,64(sp)
    80001b1a:	fc26                	sd	s1,56(sp)
    80001b1c:	f84a                	sd	s2,48(sp)
    80001b1e:	f44e                	sd	s3,40(sp)
    80001b20:	f052                	sd	s4,32(sp)
    80001b22:	ec56                	sd	s5,24(sp)
    80001b24:	e85a                	sd	s6,16(sp)
    80001b26:	e45e                	sd	s7,8(sp)
    80001b28:	e062                	sd	s8,0(sp)
    80001b2a:	0880                	addi	s0,sp,80
  struct proc * p = myproc();
    80001b2c:	00000097          	auipc	ra,0x0
    80001b30:	4de080e7          	jalr	1246(ra) # 8000200a <myproc>
  int min_ones = -1;
  int min_age = -1;
  int index_page = -1;
  uint age;
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001b34:	19850493          	addi	s1,a0,408
    80001b38:	490d                	li	s2,3
  int index_page = -1;
    80001b3a:	5c7d                	li	s8,-1
  int min_age = -1;
    80001b3c:	5bfd                	li	s7,-1
  int min_ones = -1;
    80001b3e:	5a7d                	li	s4,-1
    if (p->paging_meta_data[i].in_memory ){
      age =  p->paging_meta_data[i].aging;
      int count_ones =  count_one_bits(age);
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    80001b40:	5b7d                	li	s6,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001b42:	02000993          	li	s3,32
    80001b46:	a809                	j	80001b58 <minimum_ones+0x44>
        min_ones = count_ones;
        min_age = age;
    80001b48:	000a8b9b          	sext.w	s7,s5
    80001b4c:	8c4a                	mv	s8,s2
        min_ones = count_ones;
    80001b4e:	8a2a                	mv	s4,a0
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001b50:	2905                	addiw	s2,s2,1
    80001b52:	04b1                	addi	s1,s1,12
    80001b54:	03390663          	beq	s2,s3,80001b80 <minimum_ones+0x6c>
    if (p->paging_meta_data[i].in_memory ){
    80001b58:	40dc                	lw	a5,4(s1)
    80001b5a:	dbfd                	beqz	a5,80001b50 <minimum_ones+0x3c>
      age =  p->paging_meta_data[i].aging;
    80001b5c:	0004aa83          	lw	s5,0(s1)
      int count_ones =  count_one_bits(age);
    80001b60:	8556                	mv	a0,s5
    80001b62:	00000097          	auipc	ra,0x0
    80001b66:	f90080e7          	jalr	-112(ra) # 80001af2 <count_one_bits>
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    80001b6a:	fd6a0fe3          	beq	s4,s6,80001b48 <minimum_ones+0x34>
    80001b6e:	fd454de3          	blt	a0,s4,80001b48 <minimum_ones+0x34>
    80001b72:	fd451fe3          	bne	a0,s4,80001b50 <minimum_ones+0x3c>
    80001b76:	000b879b          	sext.w	a5,s7
    80001b7a:	fcfafbe3          	bgeu	s5,a5,80001b50 <minimum_ones+0x3c>
    80001b7e:	b7e9                	j	80001b48 <minimum_ones+0x34>
        index_page = i;
      }
    }
  }
  if(min_ones == -1)
    80001b80:	57fd                	li	a5,-1
    80001b82:	00fa0f63          	beq	s4,a5,80001ba0 <minimum_ones+0x8c>
    panic("page replacment algorithem failed");
  return index_page;
}
    80001b86:	8562                	mv	a0,s8
    80001b88:	60a6                	ld	ra,72(sp)
    80001b8a:	6406                	ld	s0,64(sp)
    80001b8c:	74e2                	ld	s1,56(sp)
    80001b8e:	7942                	ld	s2,48(sp)
    80001b90:	79a2                	ld	s3,40(sp)
    80001b92:	7a02                	ld	s4,32(sp)
    80001b94:	6ae2                	ld	s5,24(sp)
    80001b96:	6b42                	ld	s6,16(sp)
    80001b98:	6ba2                	ld	s7,8(sp)
    80001b9a:	6c02                	ld	s8,0(sp)
    80001b9c:	6161                	addi	sp,sp,80
    80001b9e:	8082                	ret
    panic("page replacment algorithem failed");
    80001ba0:	00006517          	auipc	a0,0x6
    80001ba4:	66850513          	addi	a0,a0,1640 # 80008208 <digits+0x1c8>
    80001ba8:	fffff097          	auipc	ra,0xfffff
    80001bac:	982080e7          	jalr	-1662(ra) # 8000052a <panic>

0000000080001bb0 <remove_from_queue>:

void remove_from_queue(struct age_queue * q){
    80001bb0:	1141                	addi	sp,sp,-16
    80001bb2:	e422                	sd	s0,8(sp)
    80001bb4:	0800                	addi	s0,sp,16
  q->front = q->front+1;
    80001bb6:	08052783          	lw	a5,128(a0)
    80001bba:	2785                	addiw	a5,a5,1
    80001bbc:	0007869b          	sext.w	a3,a5
   if(q->front == 32) {
    80001bc0:	02000713          	li	a4,32
    80001bc4:	00e68c63          	beq	a3,a4,80001bdc <remove_from_queue+0x2c>
  q->front = q->front+1;
    80001bc8:	08f52023          	sw	a5,128(a0)
      q->front = 0;
   }
   q->page_counter = q->page_counter-1;
    80001bcc:	08852783          	lw	a5,136(a0)
    80001bd0:	37fd                	addiw	a5,a5,-1
    80001bd2:	08f52423          	sw	a5,136(a0)
   
}
    80001bd6:	6422                	ld	s0,8(sp)
    80001bd8:	0141                	addi	sp,sp,16
    80001bda:	8082                	ret
      q->front = 0;
    80001bdc:	08052023          	sw	zero,128(a0)
    80001be0:	b7f5                	j	80001bcc <remove_from_queue+0x1c>

0000000080001be2 <insert_to_queue>:
void insert_to_queue(int inserted_page){
    80001be2:	1101                	addi	sp,sp,-32
    80001be4:	ec06                	sd	ra,24(sp)
    80001be6:	e822                	sd	s0,16(sp)
    80001be8:	e426                	sd	s1,8(sp)
    80001bea:	1000                	addi	s0,sp,32
    80001bec:	84aa                	mv	s1,a0
  struct proc * process = myproc();
    80001bee:	00000097          	auipc	ra,0x0
    80001bf2:	41c080e7          	jalr	1052(ra) # 8000200a <myproc>
  struct age_queue * q = &process->queue;
  if(inserted_page >= 3){
    80001bf6:	4789                	li	a5,2
    80001bf8:	0297d763          	bge	a5,s1,80001c26 <insert_to_queue+0x44>
    if (q->last == 31)
    80001bfc:	37452703          	lw	a4,884(a0)
    80001c00:	47fd                	li	a5,31
    80001c02:	02f70763          	beq	a4,a5,80001c30 <insert_to_queue+0x4e>
      q->last = -1;
    q->last = q->last + 1;
    80001c06:	37452703          	lw	a4,884(a0)
    80001c0a:	2705                	addiw	a4,a4,1
    80001c0c:	0007079b          	sext.w	a5,a4
    80001c10:	36e52a23          	sw	a4,884(a0)
    q->pages[q->last] =inserted_page;
    80001c14:	078a                	slli	a5,a5,0x2
    80001c16:	97aa                	add	a5,a5,a0
    80001c18:	2e97a823          	sw	s1,752(a5)
    q->page_counter =  q->page_counter + 1;
    80001c1c:	37852783          	lw	a5,888(a0)
    80001c20:	2785                	addiw	a5,a5,1
    80001c22:	36f52c23          	sw	a5,888(a0)
  }
}
    80001c26:	60e2                	ld	ra,24(sp)
    80001c28:	6442                	ld	s0,16(sp)
    80001c2a:	64a2                	ld	s1,8(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret
      q->last = -1;
    80001c30:	57fd                	li	a5,-1
    80001c32:	36f52a23          	sw	a5,884(a0)
    80001c36:	bfc1                	j	80001c06 <insert_to_queue+0x24>

0000000080001c38 <second_fifo>:
int second_fifo(){
    80001c38:	7139                	addi	sp,sp,-64
    80001c3a:	fc06                	sd	ra,56(sp)
    80001c3c:	f822                	sd	s0,48(sp)
    80001c3e:	f426                	sd	s1,40(sp)
    80001c40:	f04a                	sd	s2,32(sp)
    80001c42:	ec4e                	sd	s3,24(sp)
    80001c44:	e852                	sd	s4,16(sp)
    80001c46:	e456                	sd	s5,8(sp)
    80001c48:	e05a                	sd	s6,0(sp)
    80001c4a:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001c4c:	00000097          	auipc	ra,0x0
    80001c50:	3be080e7          	jalr	958(ra) # 8000200a <myproc>
    80001c54:	84aa                	mv	s1,a0
  struct age_queue * q = &(p->queue);
    80001c56:	2f050993          	addi	s3,a0,752
  int current_page;
  int page_counter = q->page_counter;
    80001c5a:	37852a03          	lw	s4,888(a0)
  for (int i = 0; i<page_counter; i++){
    80001c5e:	05405f63          	blez	s4,80001cbc <second_fifo+0x84>
    80001c62:	4901                	li	s2,0
      remove_from_queue(q);
      return current_page; //the file will no longer be in the memory and will be removed next time
    }
    else{ //the page has been accsesed
      *pte = *pte & (~PTE_A); //make A bit off
      printf("removing accsesed bit from %d", current_page);
    80001c64:	00006a97          	auipc	s5,0x6
    80001c68:	5dca8a93          	addi	s5,s5,1500 # 80008240 <digits+0x200>
    current_page = q->pages[q->front];
    80001c6c:	3704a783          	lw	a5,880(s1)
    80001c70:	078a                	slli	a5,a5,0x2
    80001c72:	97a6                	add	a5,a5,s1
    80001c74:	2f07ab03          	lw	s6,752(a5)
    pte_t * pte = walk(p->pagetable, current_page*PGSIZE,0);
    80001c78:	4601                	li	a2,0
    80001c7a:	00cb159b          	slliw	a1,s6,0xc
    80001c7e:	68a8                	ld	a0,80(s1)
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	336080e7          	jalr	822(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001c88:	611c                	ld	a5,0(a0)
    if(!(pte_flags & PTE_A)){
    80001c8a:	0407f713          	andi	a4,a5,64
    80001c8e:	cf29                	beqz	a4,80001ce8 <second_fifo+0xb0>
      *pte = *pte & (~PTE_A); //make A bit off
    80001c90:	fbf7f793          	andi	a5,a5,-65
    80001c94:	e11c                	sd	a5,0(a0)
      printf("removing accsesed bit from %d", current_page);
    80001c96:	85da                	mv	a1,s6
    80001c98:	8556                	mv	a0,s5
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	8da080e7          	jalr	-1830(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001ca2:	854e                	mv	a0,s3
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f0c080e7          	jalr	-244(ra) # 80001bb0 <remove_from_queue>
      insert_to_queue(current_page);
    80001cac:	855a                	mv	a0,s6
    80001cae:	00000097          	auipc	ra,0x0
    80001cb2:	f34080e7          	jalr	-204(ra) # 80001be2 <insert_to_queue>
  for (int i = 0; i<page_counter; i++){
    80001cb6:	2905                	addiw	s2,s2,1
    80001cb8:	fb2a1ae3          	bne	s4,s2,80001c6c <second_fifo+0x34>
    }
  }
  current_page = q->pages[q->front];
    80001cbc:	3704a783          	lw	a5,880(s1)
    80001cc0:	078a                	slli	a5,a5,0x2
    80001cc2:	94be                	add	s1,s1,a5
    80001cc4:	2f04ab03          	lw	s6,752(s1)
  remove_from_queue(q);
    80001cc8:	854e                	mv	a0,s3
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	ee6080e7          	jalr	-282(ra) # 80001bb0 <remove_from_queue>
  return current_page;
}
    80001cd2:	855a                	mv	a0,s6
    80001cd4:	70e2                	ld	ra,56(sp)
    80001cd6:	7442                	ld	s0,48(sp)
    80001cd8:	74a2                	ld	s1,40(sp)
    80001cda:	7902                	ld	s2,32(sp)
    80001cdc:	69e2                	ld	s3,24(sp)
    80001cde:	6a42                	ld	s4,16(sp)
    80001ce0:	6aa2                	ld	s5,8(sp)
    80001ce2:	6b02                	ld	s6,0(sp)
    80001ce4:	6121                	addi	sp,sp,64
    80001ce6:	8082                	ret
      printf("not accsesed %d", current_page);
    80001ce8:	85da                	mv	a1,s6
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	54650513          	addi	a0,a0,1350 # 80008230 <digits+0x1f0>
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	882080e7          	jalr	-1918(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001cfa:	854e                	mv	a0,s3
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	eb4080e7          	jalr	-332(ra) # 80001bb0 <remove_from_queue>
      return current_page; //the file will no longer be in the memory and will be removed next time
    80001d04:	b7f9                	j	80001cd2 <second_fifo+0x9a>

0000000080001d06 <minimum_advanicing_queue>:

int minimum_advanicing_queue(){
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	1000                	addi	s0,sp,32
  struct proc * p = myproc();
    80001d10:	00000097          	auipc	ra,0x0
    80001d14:	2fa080e7          	jalr	762(ra) # 8000200a <myproc>
  struct age_queue * q = &(p->queue);
  int current_page = q->pages[q->front];
    80001d18:	37052783          	lw	a5,880(a0)
    80001d1c:	078a                	slli	a5,a5,0x2
    80001d1e:	97aa                	add	a5,a5,a0
    80001d20:	2f07a483          	lw	s1,752(a5)
  remove_from_queue(q);
    80001d24:	2f050513          	addi	a0,a0,752
    80001d28:	00000097          	auipc	ra,0x0
    80001d2c:	e88080e7          	jalr	-376(ra) # 80001bb0 <remove_from_queue>
  return current_page;
}
    80001d30:	8526                	mv	a0,s1
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret

0000000080001d3c <find_file_to_remove>:
int find_file_to_remove(){
    80001d3c:	1141                	addi	sp,sp,-16
    80001d3e:	e422                	sd	s0,8(sp)
    80001d40:	0800                	addi	s0,sp,16
  #endif
  #if SELECTION == AQ
    return minimum_advanicing_queue(); 
  #endif
  return 0;
}
    80001d42:	4501                	li	a0,0
    80001d44:	6422                	ld	s0,8(sp)
    80001d46:	0141                	addi	sp,sp,16
    80001d48:	8082                	ret

0000000080001d4a <shift_counter>:

void shift_counter(){
    80001d4a:	7139                	addi	sp,sp,-64
    80001d4c:	fc06                	sd	ra,56(sp)
    80001d4e:	f822                	sd	s0,48(sp)
    80001d50:	f426                	sd	s1,40(sp)
    80001d52:	f04a                	sd	s2,32(sp)
    80001d54:	ec4e                	sd	s3,24(sp)
    80001d56:	e852                	sd	s4,16(sp)
    80001d58:	e456                	sd	s5,8(sp)
    80001d5a:	0080                	addi	s0,sp,64
 struct proc * p = myproc();
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	2ae080e7          	jalr	686(ra) # 8000200a <myproc>
 pte_t * pte;
 for(int i=0; i<32; i++){
    80001d64:	17450913          	addi	s2,a0,372
 struct proc * p = myproc();
    80001d68:	4481                	li	s1,0
      uint page_virtual_address = i*PGSIZE;
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
      if(*pte & PTE_V){
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
        if(*pte & PTE_A){
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80001d6a:	80000ab7          	lui	s5,0x80000
 for(int i=0; i<32; i++){
    80001d6e:	6a05                	lui	s4,0x1
    80001d70:	000209b7          	lui	s3,0x20
    80001d74:	a029                	j	80001d7e <shift_counter+0x34>
    80001d76:	94d2                	add	s1,s1,s4
    80001d78:	0931                	addi	s2,s2,12
    80001d7a:	05348363          	beq	s1,s3,80001dc0 <shift_counter+0x76>
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	28c080e7          	jalr	652(ra) # 8000200a <myproc>
    80001d86:	4601                	li	a2,0
    80001d88:	85a6                	mv	a1,s1
    80001d8a:	6928                	ld	a0,80(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	22a080e7          	jalr	554(ra) # 80000fb6 <walk>
      if(*pte & PTE_V){
    80001d94:	611c                	ld	a5,0(a0)
    80001d96:	8b85                	andi	a5,a5,1
    80001d98:	dff9                	beqz	a5,80001d76 <shift_counter+0x2c>
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
    80001d9a:	00092783          	lw	a5,0(s2)
    80001d9e:	0017d79b          	srliw	a5,a5,0x1
    80001da2:	00f92023          	sw	a5,0(s2)
        if(*pte & PTE_A){
    80001da6:	6118                	ld	a4,0(a0)
    80001da8:	04077713          	andi	a4,a4,64
    80001dac:	d769                	beqz	a4,80001d76 <shift_counter+0x2c>
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    80001dae:	0157e7b3          	or	a5,a5,s5
    80001db2:	00f92023          	sw	a5,0(s2)
          *pte = *pte & (~PTE_A); //turn off
    80001db6:	611c                	ld	a5,0(a0)
    80001db8:	fbf7f793          	andi	a5,a5,-65
    80001dbc:	e11c                	sd	a5,0(a0)
    80001dbe:	bf65                	j	80001d76 <shift_counter+0x2c>
        }
      }
    }
}
    80001dc0:	70e2                	ld	ra,56(sp)
    80001dc2:	7442                	ld	s0,48(sp)
    80001dc4:	74a2                	ld	s1,40(sp)
    80001dc6:	7902                	ld	s2,32(sp)
    80001dc8:	69e2                	ld	s3,24(sp)
    80001dca:	6a42                	ld	s4,16(sp)
    80001dcc:	6aa2                	ld	s5,8(sp)
    80001dce:	6121                	addi	sp,sp,64
    80001dd0:	8082                	ret

0000000080001dd2 <shift_queue>:
void shift_queue(){
    80001dd2:	7139                	addi	sp,sp,-64
    80001dd4:	fc06                	sd	ra,56(sp)
    80001dd6:	f822                	sd	s0,48(sp)
    80001dd8:	f426                	sd	s1,40(sp)
    80001dda:	f04a                	sd	s2,32(sp)
    80001ddc:	ec4e                	sd	s3,24(sp)
    80001dde:	e852                	sd	s4,16(sp)
    80001de0:	e456                	sd	s5,8(sp)
    80001de2:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	226080e7          	jalr	550(ra) # 8000200a <myproc>
  struct age_queue * q = &(p->queue);
  int front = q->front;
    80001dec:	37052a03          	lw	s4,880(a0)
  int page_count = q->page_counter;
    80001df0:	37852903          	lw	s2,888(a0)
  for(int i = page_count-2; i >0; i--){ //front + i is the index of the one before last page in the queue
    80001df4:	4789                	li	a5,2
    80001df6:	0727db63          	bge	a5,s2,80001e6c <shift_queue+0x9a>
    80001dfa:	89aa                	mv	s3,a0
    80001dfc:	0149093b          	addw	s2,s2,s4
    80001e00:	397d                	addiw	s2,s2,-1
    80001e02:	2a05                	addiw	s4,s4,1
    80001e04:	a801                	j	80001e14 <shift_queue+0x42>
    uint pte_flags = PTE_FLAGS(*pte);
    if(pte_flags & PTE_A){
      q->pages[(front + i)%32] = q->pages[(front + i + 1)%32];
      q->pages[(front + 1 + i)%32] = temp;; 
    }
    *pte = *pte & (~PTE_A);
    80001e06:	611c                	ld	a5,0(a0)
    80001e08:	fbf7f793          	andi	a5,a5,-65
    80001e0c:	e11c                	sd	a5,0(a0)
  for(int i = page_count-2; i >0; i--){ //front + i is the index of the one before last page in the queue
    80001e0e:	397d                	addiw	s2,s2,-1
    80001e10:	05490e63          	beq	s2,s4,80001e6c <shift_queue+0x9a>
    int temp = q->pages[(front+ i)%32];
    80001e14:	fff9079b          	addiw	a5,s2,-1
    80001e18:	41f7d49b          	sraiw	s1,a5,0x1f
    80001e1c:	01b4d71b          	srliw	a4,s1,0x1b
    80001e20:	00e784bb          	addw	s1,a5,a4
    80001e24:	88fd                	andi	s1,s1,31
    80001e26:	9c99                	subw	s1,s1,a4
    80001e28:	048a                	slli	s1,s1,0x2
    80001e2a:	94ce                	add	s1,s1,s3
    80001e2c:	2f04aa83          	lw	s5,752(s1)
    pte_t * pte = walk(p->pagetable, temp*PGSIZE,0);
    80001e30:	4601                	li	a2,0
    80001e32:	00ca959b          	slliw	a1,s5,0xc
    80001e36:	0509b503          	ld	a0,80(s3) # 20050 <_entry-0x7ffdffb0>
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	17c080e7          	jalr	380(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001e42:	611c                	ld	a5,0(a0)
    if(pte_flags & PTE_A){
    80001e44:	0407f793          	andi	a5,a5,64
    80001e48:	dfdd                	beqz	a5,80001e06 <shift_queue+0x34>
      q->pages[(front + i)%32] = q->pages[(front + i + 1)%32];
    80001e4a:	41f9579b          	sraiw	a5,s2,0x1f
    80001e4e:	01b7d71b          	srliw	a4,a5,0x1b
    80001e52:	012707bb          	addw	a5,a4,s2
    80001e56:	8bfd                	andi	a5,a5,31
    80001e58:	9f99                	subw	a5,a5,a4
    80001e5a:	078a                	slli	a5,a5,0x2
    80001e5c:	97ce                	add	a5,a5,s3
    80001e5e:	2f07a703          	lw	a4,752(a5)
    80001e62:	2ee4a823          	sw	a4,752(s1)
      q->pages[(front + 1 + i)%32] = temp;; 
    80001e66:	2f57a823          	sw	s5,752(a5)
    80001e6a:	bf71                	j	80001e06 <shift_queue+0x34>
  }
}
    80001e6c:	70e2                	ld	ra,56(sp)
    80001e6e:	7442                	ld	s0,48(sp)
    80001e70:	74a2                	ld	s1,40(sp)
    80001e72:	7902                	ld	s2,32(sp)
    80001e74:	69e2                	ld	s3,24(sp)
    80001e76:	6a42                	ld	s4,16(sp)
    80001e78:	6aa2                	ld	s5,8(sp)
    80001e7a:	6121                	addi	sp,sp,64
    80001e7c:	8082                	ret

0000000080001e7e <update_aging_algorithms>:
//update aging algorithm when the process returns to the scheduler
void
update_aging_algorithms(void){
    80001e7e:	1141                	addi	sp,sp,-16
    80001e80:	e422                	sd	s0,8(sp)
    80001e82:	0800                	addi	s0,sp,16
  #endif
  #if SELECTION == AQ
    shift_queue();
  #endif
return;
}
    80001e84:	6422                	ld	s0,8(sp)
    80001e86:	0141                	addi	sp,sp,16
    80001e88:	8082                	ret

0000000080001e8a <init_aging>:

uint init_aging(int fifo_init_pages){
    80001e8a:	1141                	addi	sp,sp,-16
    80001e8c:	e422                	sd	s0,8(sp)
    80001e8e:	0800                	addi	s0,sp,16
  #endif
  #if SELECTION==SCFIFO
    return insert_to_queue(fifo_init_pages);
  #endif 
  return 0;
}
    80001e90:	4501                	li	a0,0
    80001e92:	6422                	ld	s0,8(sp)
    80001e94:	0141                	addi	sp,sp,16
    80001e96:	8082                	ret

0000000080001e98 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001e98:	7139                	addi	sp,sp,-64
    80001e9a:	fc06                	sd	ra,56(sp)
    80001e9c:	f822                	sd	s0,48(sp)
    80001e9e:	f426                	sd	s1,40(sp)
    80001ea0:	f04a                	sd	s2,32(sp)
    80001ea2:	ec4e                	sd	s3,24(sp)
    80001ea4:	e852                	sd	s4,16(sp)
    80001ea6:	e456                	sd	s5,8(sp)
    80001ea8:	e05a                	sd	s6,0(sp)
    80001eaa:	0080                	addi	s0,sp,64
    80001eac:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001eae:	00010497          	auipc	s1,0x10
    80001eb2:	82248493          	addi	s1,s1,-2014 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001eb6:	8b26                	mv	s6,s1
    80001eb8:	00006a97          	auipc	s5,0x6
    80001ebc:	148a8a93          	addi	s5,s5,328 # 80008000 <etext>
    80001ec0:	04000937          	lui	s2,0x4000
    80001ec4:	197d                	addi	s2,s2,-1
    80001ec6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ec8:	0001ea17          	auipc	s4,0x1e
    80001ecc:	808a0a13          	addi	s4,s4,-2040 # 8001f6d0 <tickslock>
    char *pa = kalloc();
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	c12080e7          	jalr	-1006(ra) # 80000ae2 <kalloc>
    80001ed8:	862a                	mv	a2,a0
    if(pa == 0)
    80001eda:	c131                	beqz	a0,80001f1e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001edc:	416485b3          	sub	a1,s1,s6
    80001ee0:	859d                	srai	a1,a1,0x7
    80001ee2:	000ab783          	ld	a5,0(s5)
    80001ee6:	02f585b3          	mul	a1,a1,a5
    80001eea:	2585                	addiw	a1,a1,1
    80001eec:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ef0:	4719                	li	a4,6
    80001ef2:	6685                	lui	a3,0x1
    80001ef4:	40b905b3          	sub	a1,s2,a1
    80001ef8:	854e                	mv	a0,s3
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	21c080e7          	jalr	540(ra) # 80001116 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f02:	38048493          	addi	s1,s1,896
    80001f06:	fd4495e3          	bne	s1,s4,80001ed0 <proc_mapstacks+0x38>
  }
}
    80001f0a:	70e2                	ld	ra,56(sp)
    80001f0c:	7442                	ld	s0,48(sp)
    80001f0e:	74a2                	ld	s1,40(sp)
    80001f10:	7902                	ld	s2,32(sp)
    80001f12:	69e2                	ld	s3,24(sp)
    80001f14:	6a42                	ld	s4,16(sp)
    80001f16:	6aa2                	ld	s5,8(sp)
    80001f18:	6b02                	ld	s6,0(sp)
    80001f1a:	6121                	addi	sp,sp,64
    80001f1c:	8082                	ret
      panic("kalloc");
    80001f1e:	00006517          	auipc	a0,0x6
    80001f22:	34250513          	addi	a0,a0,834 # 80008260 <digits+0x220>
    80001f26:	ffffe097          	auipc	ra,0xffffe
    80001f2a:	604080e7          	jalr	1540(ra) # 8000052a <panic>

0000000080001f2e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001f2e:	7139                	addi	sp,sp,-64
    80001f30:	fc06                	sd	ra,56(sp)
    80001f32:	f822                	sd	s0,48(sp)
    80001f34:	f426                	sd	s1,40(sp)
    80001f36:	f04a                	sd	s2,32(sp)
    80001f38:	ec4e                	sd	s3,24(sp)
    80001f3a:	e852                	sd	s4,16(sp)
    80001f3c:	e456                	sd	s5,8(sp)
    80001f3e:	e05a                	sd	s6,0(sp)
    80001f40:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001f42:	00006597          	auipc	a1,0x6
    80001f46:	32658593          	addi	a1,a1,806 # 80008268 <digits+0x228>
    80001f4a:	0000f517          	auipc	a0,0xf
    80001f4e:	35650513          	addi	a0,a0,854 # 800112a0 <pid_lock>
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	bf0080e7          	jalr	-1040(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001f5a:	00006597          	auipc	a1,0x6
    80001f5e:	31658593          	addi	a1,a1,790 # 80008270 <digits+0x230>
    80001f62:	0000f517          	auipc	a0,0xf
    80001f66:	35650513          	addi	a0,a0,854 # 800112b8 <wait_lock>
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	bd8080e7          	jalr	-1064(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f72:	0000f497          	auipc	s1,0xf
    80001f76:	75e48493          	addi	s1,s1,1886 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001f7a:	00006b17          	auipc	s6,0x6
    80001f7e:	306b0b13          	addi	s6,s6,774 # 80008280 <digits+0x240>
      p->kstack = KSTACK((int) (p - proc));
    80001f82:	8aa6                	mv	s5,s1
    80001f84:	00006a17          	auipc	s4,0x6
    80001f88:	07ca0a13          	addi	s4,s4,124 # 80008000 <etext>
    80001f8c:	04000937          	lui	s2,0x4000
    80001f90:	197d                	addi	s2,s2,-1
    80001f92:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f94:	0001d997          	auipc	s3,0x1d
    80001f98:	73c98993          	addi	s3,s3,1852 # 8001f6d0 <tickslock>
      initlock(&p->lock, "proc");
    80001f9c:	85da                	mv	a1,s6
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	ba2080e7          	jalr	-1118(ra) # 80000b42 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001fa8:	415487b3          	sub	a5,s1,s5
    80001fac:	879d                	srai	a5,a5,0x7
    80001fae:	000a3703          	ld	a4,0(s4)
    80001fb2:	02e787b3          	mul	a5,a5,a4
    80001fb6:	2785                	addiw	a5,a5,1
    80001fb8:	00d7979b          	slliw	a5,a5,0xd
    80001fbc:	40f907b3          	sub	a5,s2,a5
    80001fc0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fc2:	38048493          	addi	s1,s1,896
    80001fc6:	fd349be3          	bne	s1,s3,80001f9c <procinit+0x6e>
  }
}
    80001fca:	70e2                	ld	ra,56(sp)
    80001fcc:	7442                	ld	s0,48(sp)
    80001fce:	74a2                	ld	s1,40(sp)
    80001fd0:	7902                	ld	s2,32(sp)
    80001fd2:	69e2                	ld	s3,24(sp)
    80001fd4:	6a42                	ld	s4,16(sp)
    80001fd6:	6aa2                	ld	s5,8(sp)
    80001fd8:	6b02                	ld	s6,0(sp)
    80001fda:	6121                	addi	sp,sp,64
    80001fdc:	8082                	ret

0000000080001fde <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001fde:	1141                	addi	sp,sp,-16
    80001fe0:	e422                	sd	s0,8(sp)
    80001fe2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001fe6:	2501                	sext.w	a0,a0
    80001fe8:	6422                	ld	s0,8(sp)
    80001fea:	0141                	addi	sp,sp,16
    80001fec:	8082                	ret

0000000080001fee <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001fee:	1141                	addi	sp,sp,-16
    80001ff0:	e422                	sd	s0,8(sp)
    80001ff2:	0800                	addi	s0,sp,16
    80001ff4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ff6:	2781                	sext.w	a5,a5
    80001ff8:	079e                	slli	a5,a5,0x7
  return c;
}
    80001ffa:	0000f517          	auipc	a0,0xf
    80001ffe:	2d650513          	addi	a0,a0,726 # 800112d0 <cpus>
    80002002:	953e                	add	a0,a0,a5
    80002004:	6422                	ld	s0,8(sp)
    80002006:	0141                	addi	sp,sp,16
    80002008:	8082                	ret

000000008000200a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    8000200a:	1101                	addi	sp,sp,-32
    8000200c:	ec06                	sd	ra,24(sp)
    8000200e:	e822                	sd	s0,16(sp)
    80002010:	e426                	sd	s1,8(sp)
    80002012:	1000                	addi	s0,sp,32
  push_off();
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	b72080e7          	jalr	-1166(ra) # 80000b86 <push_off>
    8000201c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000201e:	2781                	sext.w	a5,a5
    80002020:	079e                	slli	a5,a5,0x7
    80002022:	0000f717          	auipc	a4,0xf
    80002026:	27e70713          	addi	a4,a4,638 # 800112a0 <pid_lock>
    8000202a:	97ba                	add	a5,a5,a4
    8000202c:	7b84                	ld	s1,48(a5)
  pop_off();
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	bf8080e7          	jalr	-1032(ra) # 80000c26 <pop_off>
  return p;
}
    80002036:	8526                	mv	a0,s1
    80002038:	60e2                	ld	ra,24(sp)
    8000203a:	6442                	ld	s0,16(sp)
    8000203c:	64a2                	ld	s1,8(sp)
    8000203e:	6105                	addi	sp,sp,32
    80002040:	8082                	ret

0000000080002042 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002042:	1141                	addi	sp,sp,-16
    80002044:	e406                	sd	ra,8(sp)
    80002046:	e022                	sd	s0,0(sp)
    80002048:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000204a:	00000097          	auipc	ra,0x0
    8000204e:	fc0080e7          	jalr	-64(ra) # 8000200a <myproc>
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	c34080e7          	jalr	-972(ra) # 80000c86 <release>

  if (first) {
    8000205a:	00007797          	auipc	a5,0x7
    8000205e:	8a67a783          	lw	a5,-1882(a5) # 80008900 <first.1>
    80002062:	eb89                	bnez	a5,80002074 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002064:	00001097          	auipc	ra,0x1
    80002068:	cd8080e7          	jalr	-808(ra) # 80002d3c <usertrapret>
}
    8000206c:	60a2                	ld	ra,8(sp)
    8000206e:	6402                	ld	s0,0(sp)
    80002070:	0141                	addi	sp,sp,16
    80002072:	8082                	ret
    first = 0;
    80002074:	00007797          	auipc	a5,0x7
    80002078:	8807a623          	sw	zero,-1908(a5) # 80008900 <first.1>
    fsinit(ROOTDEV);
    8000207c:	4505                	li	a0,1
    8000207e:	00002097          	auipc	ra,0x2
    80002082:	a1e080e7          	jalr	-1506(ra) # 80003a9c <fsinit>
    80002086:	bff9                	j	80002064 <forkret+0x22>

0000000080002088 <allocpid>:
allocpid() {
    80002088:	1101                	addi	sp,sp,-32
    8000208a:	ec06                	sd	ra,24(sp)
    8000208c:	e822                	sd	s0,16(sp)
    8000208e:	e426                	sd	s1,8(sp)
    80002090:	e04a                	sd	s2,0(sp)
    80002092:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80002094:	0000f917          	auipc	s2,0xf
    80002098:	20c90913          	addi	s2,s2,524 # 800112a0 <pid_lock>
    8000209c:	854a                	mv	a0,s2
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	b34080e7          	jalr	-1228(ra) # 80000bd2 <acquire>
  pid = nextpid;
    800020a6:	00007797          	auipc	a5,0x7
    800020aa:	85e78793          	addi	a5,a5,-1954 # 80008904 <nextpid>
    800020ae:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800020b0:	0014871b          	addiw	a4,s1,1
    800020b4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	bce080e7          	jalr	-1074(ra) # 80000c86 <release>
}
    800020c0:	8526                	mv	a0,s1
    800020c2:	60e2                	ld	ra,24(sp)
    800020c4:	6442                	ld	s0,16(sp)
    800020c6:	64a2                	ld	s1,8(sp)
    800020c8:	6902                	ld	s2,0(sp)
    800020ca:	6105                	addi	sp,sp,32
    800020cc:	8082                	ret

00000000800020ce <proc_pagetable>:
{
    800020ce:	1101                	addi	sp,sp,-32
    800020d0:	ec06                	sd	ra,24(sp)
    800020d2:	e822                	sd	s0,16(sp)
    800020d4:	e426                	sd	s1,8(sp)
    800020d6:	e04a                	sd	s2,0(sp)
    800020d8:	1000                	addi	s0,sp,32
    800020da:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	206080e7          	jalr	518(ra) # 800012e2 <uvmcreate>
    800020e4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800020e6:	c121                	beqz	a0,80002126 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800020e8:	4729                	li	a4,10
    800020ea:	00005697          	auipc	a3,0x5
    800020ee:	f1668693          	addi	a3,a3,-234 # 80007000 <_trampoline>
    800020f2:	6605                	lui	a2,0x1
    800020f4:	040005b7          	lui	a1,0x4000
    800020f8:	15fd                	addi	a1,a1,-1
    800020fa:	05b2                	slli	a1,a1,0xc
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	f8c080e7          	jalr	-116(ra) # 80001088 <mappages>
    80002104:	02054863          	bltz	a0,80002134 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80002108:	4719                	li	a4,6
    8000210a:	05893683          	ld	a3,88(s2)
    8000210e:	6605                	lui	a2,0x1
    80002110:	020005b7          	lui	a1,0x2000
    80002114:	15fd                	addi	a1,a1,-1
    80002116:	05b6                	slli	a1,a1,0xd
    80002118:	8526                	mv	a0,s1
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	f6e080e7          	jalr	-146(ra) # 80001088 <mappages>
    80002122:	02054163          	bltz	a0,80002144 <proc_pagetable+0x76>
}
    80002126:	8526                	mv	a0,s1
    80002128:	60e2                	ld	ra,24(sp)
    8000212a:	6442                	ld	s0,16(sp)
    8000212c:	64a2                	ld	s1,8(sp)
    8000212e:	6902                	ld	s2,0(sp)
    80002130:	6105                	addi	sp,sp,32
    80002132:	8082                	ret
    uvmfree(pagetable, 0);
    80002134:	4581                	li	a1,0
    80002136:	8526                	mv	a0,s1
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	3a6080e7          	jalr	934(ra) # 800014de <uvmfree>
    return 0;
    80002140:	4481                	li	s1,0
    80002142:	b7d5                	j	80002126 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002144:	4681                	li	a3,0
    80002146:	4605                	li	a2,1
    80002148:	040005b7          	lui	a1,0x4000
    8000214c:	15fd                	addi	a1,a1,-1
    8000214e:	05b2                	slli	a1,a1,0xc
    80002150:	8526                	mv	a0,s1
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	0ea080e7          	jalr	234(ra) # 8000123c <uvmunmap>
    uvmfree(pagetable, 0);
    8000215a:	4581                	li	a1,0
    8000215c:	8526                	mv	a0,s1
    8000215e:	fffff097          	auipc	ra,0xfffff
    80002162:	380080e7          	jalr	896(ra) # 800014de <uvmfree>
    return 0;
    80002166:	4481                	li	s1,0
    80002168:	bf7d                	j	80002126 <proc_pagetable+0x58>

000000008000216a <proc_freepagetable>:
{
    8000216a:	1101                	addi	sp,sp,-32
    8000216c:	ec06                	sd	ra,24(sp)
    8000216e:	e822                	sd	s0,16(sp)
    80002170:	e426                	sd	s1,8(sp)
    80002172:	e04a                	sd	s2,0(sp)
    80002174:	1000                	addi	s0,sp,32
    80002176:	84aa                	mv	s1,a0
    80002178:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000217a:	4681                	li	a3,0
    8000217c:	4605                	li	a2,1
    8000217e:	040005b7          	lui	a1,0x4000
    80002182:	15fd                	addi	a1,a1,-1
    80002184:	05b2                	slli	a1,a1,0xc
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	0b6080e7          	jalr	182(ra) # 8000123c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000218e:	4681                	li	a3,0
    80002190:	4605                	li	a2,1
    80002192:	020005b7          	lui	a1,0x2000
    80002196:	15fd                	addi	a1,a1,-1
    80002198:	05b6                	slli	a1,a1,0xd
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	0a0080e7          	jalr	160(ra) # 8000123c <uvmunmap>
  uvmfree(pagetable, sz);
    800021a4:	85ca                	mv	a1,s2
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	336080e7          	jalr	822(ra) # 800014de <uvmfree>
}
    800021b0:	60e2                	ld	ra,24(sp)
    800021b2:	6442                	ld	s0,16(sp)
    800021b4:	64a2                	ld	s1,8(sp)
    800021b6:	6902                	ld	s2,0(sp)
    800021b8:	6105                	addi	sp,sp,32
    800021ba:	8082                	ret

00000000800021bc <freeproc>:
{ 
    800021bc:	1101                	addi	sp,sp,-32
    800021be:	ec06                	sd	ra,24(sp)
    800021c0:	e822                	sd	s0,16(sp)
    800021c2:	e426                	sd	s1,8(sp)
    800021c4:	1000                	addi	s0,sp,32
    800021c6:	84aa                	mv	s1,a0
  if(p->trapframe)
    800021c8:	6d28                	ld	a0,88(a0)
    800021ca:	c509                	beqz	a0,800021d4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	80a080e7          	jalr	-2038(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    800021d4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800021d8:	68a8                	ld	a0,80(s1)
    800021da:	c511                	beqz	a0,800021e6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800021dc:	64ac                	ld	a1,72(s1)
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	f8c080e7          	jalr	-116(ra) # 8000216a <proc_freepagetable>
  p->pagetable = 0;
    800021e6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800021ea:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800021ee:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800021f2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800021f6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800021fa:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800021fe:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80002202:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002206:	0004ac23          	sw	zero,24(s1)
}
    8000220a:	60e2                	ld	ra,24(sp)
    8000220c:	6442                	ld	s0,16(sp)
    8000220e:	64a2                	ld	s1,8(sp)
    80002210:	6105                	addi	sp,sp,32
    80002212:	8082                	ret

0000000080002214 <allocproc>:
{
    80002214:	1101                	addi	sp,sp,-32
    80002216:	ec06                	sd	ra,24(sp)
    80002218:	e822                	sd	s0,16(sp)
    8000221a:	e426                	sd	s1,8(sp)
    8000221c:	e04a                	sd	s2,0(sp)
    8000221e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80002220:	0000f497          	auipc	s1,0xf
    80002224:	4b048493          	addi	s1,s1,1200 # 800116d0 <proc>
    80002228:	0001d917          	auipc	s2,0x1d
    8000222c:	4a890913          	addi	s2,s2,1192 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9a0080e7          	jalr	-1632(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    8000223a:	4c9c                	lw	a5,24(s1)
    8000223c:	cf81                	beqz	a5,80002254 <allocproc+0x40>
      release(&p->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	a46080e7          	jalr	-1466(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002248:	38048493          	addi	s1,s1,896
    8000224c:	ff2492e3          	bne	s1,s2,80002230 <allocproc+0x1c>
  return 0;
    80002250:	4481                	li	s1,0
    80002252:	a889                	j	800022a4 <allocproc+0x90>
  p->pid = allocpid();
    80002254:	00000097          	auipc	ra,0x0
    80002258:	e34080e7          	jalr	-460(ra) # 80002088 <allocpid>
    8000225c:	d888                	sw	a0,48(s1)
  p->state = USED;
    8000225e:	4785                	li	a5,1
    80002260:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	880080e7          	jalr	-1920(ra) # 80000ae2 <kalloc>
    8000226a:	892a                	mv	s2,a0
    8000226c:	eca8                	sd	a0,88(s1)
    8000226e:	c131                	beqz	a0,800022b2 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80002270:	8526                	mv	a0,s1
    80002272:	00000097          	auipc	ra,0x0
    80002276:	e5c080e7          	jalr	-420(ra) # 800020ce <proc_pagetable>
    8000227a:	892a                	mv	s2,a0
    8000227c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    8000227e:	c531                	beqz	a0,800022ca <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80002280:	07000613          	li	a2,112
    80002284:	4581                	li	a1,0
    80002286:	06048513          	addi	a0,s1,96
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	a44080e7          	jalr	-1468(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80002292:	00000797          	auipc	a5,0x0
    80002296:	db078793          	addi	a5,a5,-592 # 80002042 <forkret>
    8000229a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    8000229c:	60bc                	ld	a5,64(s1)
    8000229e:	6705                	lui	a4,0x1
    800022a0:	97ba                	add	a5,a5,a4
    800022a2:	f4bc                	sd	a5,104(s1)
}
    800022a4:	8526                	mv	a0,s1
    800022a6:	60e2                	ld	ra,24(sp)
    800022a8:	6442                	ld	s0,16(sp)
    800022aa:	64a2                	ld	s1,8(sp)
    800022ac:	6902                	ld	s2,0(sp)
    800022ae:	6105                	addi	sp,sp,32
    800022b0:	8082                	ret
    freeproc(p);
    800022b2:	8526                	mv	a0,s1
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	f08080e7          	jalr	-248(ra) # 800021bc <freeproc>
    release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9c8080e7          	jalr	-1592(ra) # 80000c86 <release>
    return 0;
    800022c6:	84ca                	mv	s1,s2
    800022c8:	bff1                	j	800022a4 <allocproc+0x90>
    freeproc(p);
    800022ca:	8526                	mv	a0,s1
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	ef0080e7          	jalr	-272(ra) # 800021bc <freeproc>
    release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9b0080e7          	jalr	-1616(ra) # 80000c86 <release>
    return 0;
    800022de:	84ca                	mv	s1,s2
    800022e0:	b7d1                	j	800022a4 <allocproc+0x90>

00000000800022e2 <userinit>:
{
    800022e2:	1101                	addi	sp,sp,-32
    800022e4:	ec06                	sd	ra,24(sp)
    800022e6:	e822                	sd	s0,16(sp)
    800022e8:	e426                	sd	s1,8(sp)
    800022ea:	1000                	addi	s0,sp,32
  p = allocproc();
    800022ec:	00000097          	auipc	ra,0x0
    800022f0:	f28080e7          	jalr	-216(ra) # 80002214 <allocproc>
    800022f4:	84aa                	mv	s1,a0
  initproc = p;
    800022f6:	00007797          	auipc	a5,0x7
    800022fa:	d2a7b923          	sd	a0,-718(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800022fe:	03400613          	li	a2,52
    80002302:	00006597          	auipc	a1,0x6
    80002306:	60e58593          	addi	a1,a1,1550 # 80008910 <initcode>
    8000230a:	6928                	ld	a0,80(a0)
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	004080e7          	jalr	4(ra) # 80001310 <uvminit>
  p->sz = PGSIZE;
    80002314:	6785                	lui	a5,0x1
    80002316:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002318:	6cb8                	ld	a4,88(s1)
    8000231a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000231e:	6cb8                	ld	a4,88(s1)
    80002320:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002322:	4641                	li	a2,16
    80002324:	00006597          	auipc	a1,0x6
    80002328:	f6458593          	addi	a1,a1,-156 # 80008288 <digits+0x248>
    8000232c:	15848513          	addi	a0,s1,344
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	af0080e7          	jalr	-1296(ra) # 80000e20 <safestrcpy>
  p->cwd = namei("/");
    80002338:	00006517          	auipc	a0,0x6
    8000233c:	f6050513          	addi	a0,a0,-160 # 80008298 <digits+0x258>
    80002340:	00002097          	auipc	ra,0x2
    80002344:	18a080e7          	jalr	394(ra) # 800044ca <namei>
    80002348:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000234c:	478d                	li	a5,3
    8000234e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	934080e7          	jalr	-1740(ra) # 80000c86 <release>
}
    8000235a:	60e2                	ld	ra,24(sp)
    8000235c:	6442                	ld	s0,16(sp)
    8000235e:	64a2                	ld	s1,8(sp)
    80002360:	6105                	addi	sp,sp,32
    80002362:	8082                	ret

0000000080002364 <growproc>:
{
    80002364:	1101                	addi	sp,sp,-32
    80002366:	ec06                	sd	ra,24(sp)
    80002368:	e822                	sd	s0,16(sp)
    8000236a:	e426                	sd	s1,8(sp)
    8000236c:	e04a                	sd	s2,0(sp)
    8000236e:	1000                	addi	s0,sp,32
    80002370:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	c98080e7          	jalr	-872(ra) # 8000200a <myproc>
    8000237a:	84aa                	mv	s1,a0
  if(n < 0){
    8000237c:	00094d63          	bltz	s2,80002396 <growproc+0x32>
  p->sz = p->sz + n;
    80002380:	64a8                	ld	a0,72(s1)
    80002382:	992a                	add	s2,s2,a0
    80002384:	0524b423          	sd	s2,72(s1)
}
    80002388:	4501                	li	a0,0
    8000238a:	60e2                	ld	ra,24(sp)
    8000238c:	6442                	ld	s0,16(sp)
    8000238e:	64a2                	ld	s1,8(sp)
    80002390:	6902                	ld	s2,0(sp)
    80002392:	6105                	addi	sp,sp,32
    80002394:	8082                	ret
  sz = p->sz;
    80002396:	652c                	ld	a1,72(a0)
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002398:	00b9063b          	addw	a2,s2,a1
    8000239c:	1602                	slli	a2,a2,0x20
    8000239e:	9201                	srli	a2,a2,0x20
    800023a0:	1582                	slli	a1,a1,0x20
    800023a2:	9181                	srli	a1,a1,0x20
    800023a4:	6928                	ld	a0,80(a0)
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	fdc080e7          	jalr	-36(ra) # 80001382 <uvmdealloc>
    800023ae:	bfc9                	j	80002380 <growproc+0x1c>

00000000800023b0 <copy_swap_file>:
copy_swap_file(struct proc* child){
    800023b0:	7139                	addi	sp,sp,-64
    800023b2:	fc06                	sd	ra,56(sp)
    800023b4:	f822                	sd	s0,48(sp)
    800023b6:	f426                	sd	s1,40(sp)
    800023b8:	f04a                	sd	s2,32(sp)
    800023ba:	ec4e                	sd	s3,24(sp)
    800023bc:	e852                	sd	s4,16(sp)
    800023be:	e456                	sd	s5,8(sp)
    800023c0:	e05a                	sd	s6,0(sp)
    800023c2:	0080                	addi	s0,sp,64
    800023c4:	8b2a                	mv	s6,a0
  struct proc * pParent = myproc();
    800023c6:	00000097          	auipc	ra,0x0
    800023ca:	c44080e7          	jalr	-956(ra) # 8000200a <myproc>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    800023ce:	653c                	ld	a5,72(a0)
    800023d0:	cfd9                	beqz	a5,8000246e <copy_swap_file+0xbe>
    800023d2:	8a2a                	mv	s4,a0
    800023d4:	4481                	li	s1,0
    if(offset != -1){
    800023d6:	5afd                	li	s5,-1
    800023d8:	a83d                	j	80002416 <copy_swap_file+0x66>
      panic("not enough space to kalloc");
    800023da:	00006517          	auipc	a0,0x6
    800023de:	dce50513          	addi	a0,a0,-562 # 800081a8 <digits+0x168>
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	148080e7          	jalr	328(ra) # 8000052a <panic>
          panic("read swap file failed\n");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	eb650513          	addi	a0,a0,-330 # 800082a0 <digits+0x260>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	138080e7          	jalr	312(ra) # 8000052a <panic>
          panic("write swap file failed\n");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	ebe50513          	addi	a0,a0,-322 # 800082b8 <digits+0x278>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	128080e7          	jalr	296(ra) # 8000052a <panic>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    8000240a:	6785                	lui	a5,0x1
    8000240c:	94be                	add	s1,s1,a5
    8000240e:	048a3783          	ld	a5,72(s4)
    80002412:	04f4fe63          	bgeu	s1,a5,8000246e <copy_swap_file+0xbe>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    80002416:	00c4d713          	srli	a4,s1,0xc
    8000241a:	00171793          	slli	a5,a4,0x1
    8000241e:	97ba                	add	a5,a5,a4
    80002420:	078a                	slli	a5,a5,0x2
    80002422:	97d2                	add	a5,a5,s4
    80002424:	1707a903          	lw	s2,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    80002428:	ff5901e3          	beq	s2,s5,8000240a <copy_swap_file+0x5a>
      if((buffer = kalloc()) == 0)
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	6b6080e7          	jalr	1718(ra) # 80000ae2 <kalloc>
    80002434:	89aa                	mv	s3,a0
    80002436:	d155                	beqz	a0,800023da <copy_swap_file+0x2a>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    80002438:	2901                	sext.w	s2,s2
    8000243a:	6685                	lui	a3,0x1
    8000243c:	864a                	mv	a2,s2
    8000243e:	85aa                	mv	a1,a0
    80002440:	8552                	mv	a0,s4
    80002442:	00002097          	auipc	ra,0x2
    80002446:	3b0080e7          	jalr	944(ra) # 800047f2 <readFromSwapFile>
    8000244a:	fb5500e3          	beq	a0,s5,800023ea <copy_swap_file+0x3a>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    8000244e:	6685                	lui	a3,0x1
    80002450:	864a                	mv	a2,s2
    80002452:	85ce                	mv	a1,s3
    80002454:	855a                	mv	a0,s6
    80002456:	00002097          	auipc	ra,0x2
    8000245a:	378080e7          	jalr	888(ra) # 800047ce <writeToSwapFile>
    8000245e:	f9550ee3          	beq	a0,s5,800023fa <copy_swap_file+0x4a>
      kfree(buffer);
    80002462:	854e                	mv	a0,s3
    80002464:	ffffe097          	auipc	ra,0xffffe
    80002468:	572080e7          	jalr	1394(ra) # 800009d6 <kfree>
    8000246c:	bf79                	j	8000240a <copy_swap_file+0x5a>
}
    8000246e:	70e2                	ld	ra,56(sp)
    80002470:	7442                	ld	s0,48(sp)
    80002472:	74a2                	ld	s1,40(sp)
    80002474:	7902                	ld	s2,32(sp)
    80002476:	69e2                	ld	s3,24(sp)
    80002478:	6a42                	ld	s4,16(sp)
    8000247a:	6aa2                	ld	s5,8(sp)
    8000247c:	6b02                	ld	s6,0(sp)
    8000247e:	6121                	addi	sp,sp,64
    80002480:	8082                	ret

0000000080002482 <fork>:
{
    80002482:	7139                	addi	sp,sp,-64
    80002484:	fc06                	sd	ra,56(sp)
    80002486:	f822                	sd	s0,48(sp)
    80002488:	f426                	sd	s1,40(sp)
    8000248a:	f04a                	sd	s2,32(sp)
    8000248c:	ec4e                	sd	s3,24(sp)
    8000248e:	e852                	sd	s4,16(sp)
    80002490:	e456                	sd	s5,8(sp)
    80002492:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002494:	00000097          	auipc	ra,0x0
    80002498:	b76080e7          	jalr	-1162(ra) # 8000200a <myproc>
    8000249c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    8000249e:	00000097          	auipc	ra,0x0
    800024a2:	d76080e7          	jalr	-650(ra) # 80002214 <allocproc>
    800024a6:	10050c63          	beqz	a0,800025be <fork+0x13c>
    800024aa:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800024ac:	048ab603          	ld	a2,72(s5)
    800024b0:	692c                	ld	a1,80(a0)
    800024b2:	050ab503          	ld	a0,80(s5)
    800024b6:	fffff097          	auipc	ra,0xfffff
    800024ba:	060080e7          	jalr	96(ra) # 80001516 <uvmcopy>
    800024be:	04054863          	bltz	a0,8000250e <fork+0x8c>
  np->sz = p->sz;
    800024c2:	048ab783          	ld	a5,72(s5)
    800024c6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    800024ca:	058ab683          	ld	a3,88(s5)
    800024ce:	87b6                	mv	a5,a3
    800024d0:	058a3703          	ld	a4,88(s4)
    800024d4:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800024d8:	0007b803          	ld	a6,0(a5)
    800024dc:	6788                	ld	a0,8(a5)
    800024de:	6b8c                	ld	a1,16(a5)
    800024e0:	6f90                	ld	a2,24(a5)
    800024e2:	01073023          	sd	a6,0(a4)
    800024e6:	e708                	sd	a0,8(a4)
    800024e8:	eb0c                	sd	a1,16(a4)
    800024ea:	ef10                	sd	a2,24(a4)
    800024ec:	02078793          	addi	a5,a5,32
    800024f0:	02070713          	addi	a4,a4,32
    800024f4:	fed792e3          	bne	a5,a3,800024d8 <fork+0x56>
  np->trapframe->a0 = 0;
    800024f8:	058a3783          	ld	a5,88(s4)
    800024fc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002500:	0d0a8493          	addi	s1,s5,208
    80002504:	0d0a0913          	addi	s2,s4,208
    80002508:	150a8993          	addi	s3,s5,336
    8000250c:	a00d                	j	8000252e <fork+0xac>
    freeproc(np);
    8000250e:	8552                	mv	a0,s4
    80002510:	00000097          	auipc	ra,0x0
    80002514:	cac080e7          	jalr	-852(ra) # 800021bc <freeproc>
    release(&np->lock);
    80002518:	8552                	mv	a0,s4
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	76c080e7          	jalr	1900(ra) # 80000c86 <release>
    return -1;
    80002522:	597d                	li	s2,-1
    80002524:	a059                	j	800025aa <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80002526:	04a1                	addi	s1,s1,8
    80002528:	0921                	addi	s2,s2,8
    8000252a:	01348b63          	beq	s1,s3,80002540 <fork+0xbe>
    if(p->ofile[i])
    8000252e:	6088                	ld	a0,0(s1)
    80002530:	d97d                	beqz	a0,80002526 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002532:	00003097          	auipc	ra,0x3
    80002536:	944080e7          	jalr	-1724(ra) # 80004e76 <filedup>
    8000253a:	00a93023          	sd	a0,0(s2)
    8000253e:	b7e5                	j	80002526 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80002540:	150ab503          	ld	a0,336(s5)
    80002544:	00001097          	auipc	ra,0x1
    80002548:	792080e7          	jalr	1938(ra) # 80003cd6 <idup>
    8000254c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002550:	4641                	li	a2,16
    80002552:	158a8593          	addi	a1,s5,344
    80002556:	158a0513          	addi	a0,s4,344
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	8c6080e7          	jalr	-1850(ra) # 80000e20 <safestrcpy>
  pid = np->pid;
    80002562:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80002566:	8552                	mv	a0,s4
    80002568:	ffffe097          	auipc	ra,0xffffe
    8000256c:	71e080e7          	jalr	1822(ra) # 80000c86 <release>
  acquire(&wait_lock);
    80002570:	0000f497          	auipc	s1,0xf
    80002574:	d4848493          	addi	s1,s1,-696 # 800112b8 <wait_lock>
    80002578:	8526                	mv	a0,s1
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	658080e7          	jalr	1624(ra) # 80000bd2 <acquire>
  np->parent = p;
    80002582:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002586:	8526                	mv	a0,s1
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	6fe080e7          	jalr	1790(ra) # 80000c86 <release>
  acquire(&np->lock);
    80002590:	8552                	mv	a0,s4
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	640080e7          	jalr	1600(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    8000259a:	478d                	li	a5,3
    8000259c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    800025a0:	8552                	mv	a0,s4
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	6e4080e7          	jalr	1764(ra) # 80000c86 <release>
}
    800025aa:	854a                	mv	a0,s2
    800025ac:	70e2                	ld	ra,56(sp)
    800025ae:	7442                	ld	s0,48(sp)
    800025b0:	74a2                	ld	s1,40(sp)
    800025b2:	7902                	ld	s2,32(sp)
    800025b4:	69e2                	ld	s3,24(sp)
    800025b6:	6a42                	ld	s4,16(sp)
    800025b8:	6aa2                	ld	s5,8(sp)
    800025ba:	6121                	addi	sp,sp,64
    800025bc:	8082                	ret
    return -1;
    800025be:	597d                	li	s2,-1
    800025c0:	b7ed                	j	800025aa <fork+0x128>

00000000800025c2 <scheduler>:
{
    800025c2:	7139                	addi	sp,sp,-64
    800025c4:	fc06                	sd	ra,56(sp)
    800025c6:	f822                	sd	s0,48(sp)
    800025c8:	f426                	sd	s1,40(sp)
    800025ca:	f04a                	sd	s2,32(sp)
    800025cc:	ec4e                	sd	s3,24(sp)
    800025ce:	e852                	sd	s4,16(sp)
    800025d0:	e456                	sd	s5,8(sp)
    800025d2:	e05a                	sd	s6,0(sp)
    800025d4:	0080                	addi	s0,sp,64
    800025d6:	8792                	mv	a5,tp
  int id = r_tp();
    800025d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800025da:	00779a93          	slli	s5,a5,0x7
    800025de:	0000f717          	auipc	a4,0xf
    800025e2:	cc270713          	addi	a4,a4,-830 # 800112a0 <pid_lock>
    800025e6:	9756                	add	a4,a4,s5
    800025e8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    800025ec:	0000f717          	auipc	a4,0xf
    800025f0:	cec70713          	addi	a4,a4,-788 # 800112d8 <cpus+0x8>
    800025f4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    800025f6:	498d                	li	s3,3
        p->state = RUNNING;
    800025f8:	4b11                	li	s6,4
        c->proc = p;
    800025fa:	079e                	slli	a5,a5,0x7
    800025fc:	0000fa17          	auipc	s4,0xf
    80002600:	ca4a0a13          	addi	s4,s4,-860 # 800112a0 <pid_lock>
    80002604:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002606:	0001d917          	auipc	s2,0x1d
    8000260a:	0ca90913          	addi	s2,s2,202 # 8001f6d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000260e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002612:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002616:	10079073          	csrw	sstatus,a5
    8000261a:	0000f497          	auipc	s1,0xf
    8000261e:	0b648493          	addi	s1,s1,182 # 800116d0 <proc>
    80002622:	a811                	j	80002636 <scheduler+0x74>
      release(&p->lock);
    80002624:	8526                	mv	a0,s1
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	660080e7          	jalr	1632(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000262e:	38048493          	addi	s1,s1,896
    80002632:	fd248ee3          	beq	s1,s2,8000260e <scheduler+0x4c>
      acquire(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	59a080e7          	jalr	1434(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80002640:	4c9c                	lw	a5,24(s1)
    80002642:	ff3791e3          	bne	a5,s3,80002624 <scheduler+0x62>
        p->state = RUNNING;
    80002646:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    8000264a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000264e:	06048593          	addi	a1,s1,96
    80002652:	8556                	mv	a0,s5
    80002654:	00000097          	auipc	ra,0x0
    80002658:	63e080e7          	jalr	1598(ra) # 80002c92 <swtch>
        update_aging_algorithms();
    8000265c:	00000097          	auipc	ra,0x0
    80002660:	822080e7          	jalr	-2014(ra) # 80001e7e <update_aging_algorithms>
        c->proc = 0;
    80002664:	020a3823          	sd	zero,48(s4)
    80002668:	bf75                	j	80002624 <scheduler+0x62>

000000008000266a <sched>:
{
    8000266a:	7179                	addi	sp,sp,-48
    8000266c:	f406                	sd	ra,40(sp)
    8000266e:	f022                	sd	s0,32(sp)
    80002670:	ec26                	sd	s1,24(sp)
    80002672:	e84a                	sd	s2,16(sp)
    80002674:	e44e                	sd	s3,8(sp)
    80002676:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002678:	00000097          	auipc	ra,0x0
    8000267c:	992080e7          	jalr	-1646(ra) # 8000200a <myproc>
    80002680:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002682:	ffffe097          	auipc	ra,0xffffe
    80002686:	4d6080e7          	jalr	1238(ra) # 80000b58 <holding>
    8000268a:	c93d                	beqz	a0,80002700 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000268c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000268e:	2781                	sext.w	a5,a5
    80002690:	079e                	slli	a5,a5,0x7
    80002692:	0000f717          	auipc	a4,0xf
    80002696:	c0e70713          	addi	a4,a4,-1010 # 800112a0 <pid_lock>
    8000269a:	97ba                	add	a5,a5,a4
    8000269c:	0a87a703          	lw	a4,168(a5)
    800026a0:	4785                	li	a5,1
    800026a2:	06f71763          	bne	a4,a5,80002710 <sched+0xa6>
  if(p->state == RUNNING)
    800026a6:	4c98                	lw	a4,24(s1)
    800026a8:	4791                	li	a5,4
    800026aa:	06f70b63          	beq	a4,a5,80002720 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ae:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800026b2:	8b89                	andi	a5,a5,2
  if(intr_get())
    800026b4:	efb5                	bnez	a5,80002730 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800026b6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800026b8:	0000f917          	auipc	s2,0xf
    800026bc:	be890913          	addi	s2,s2,-1048 # 800112a0 <pid_lock>
    800026c0:	2781                	sext.w	a5,a5
    800026c2:	079e                	slli	a5,a5,0x7
    800026c4:	97ca                	add	a5,a5,s2
    800026c6:	0ac7a983          	lw	s3,172(a5)
    800026ca:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800026cc:	2781                	sext.w	a5,a5
    800026ce:	079e                	slli	a5,a5,0x7
    800026d0:	0000f597          	auipc	a1,0xf
    800026d4:	c0858593          	addi	a1,a1,-1016 # 800112d8 <cpus+0x8>
    800026d8:	95be                	add	a1,a1,a5
    800026da:	06048513          	addi	a0,s1,96
    800026de:	00000097          	auipc	ra,0x0
    800026e2:	5b4080e7          	jalr	1460(ra) # 80002c92 <swtch>
    800026e6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800026e8:	2781                	sext.w	a5,a5
    800026ea:	079e                	slli	a5,a5,0x7
    800026ec:	97ca                	add	a5,a5,s2
    800026ee:	0b37a623          	sw	s3,172(a5)
}
    800026f2:	70a2                	ld	ra,40(sp)
    800026f4:	7402                	ld	s0,32(sp)
    800026f6:	64e2                	ld	s1,24(sp)
    800026f8:	6942                	ld	s2,16(sp)
    800026fa:	69a2                	ld	s3,8(sp)
    800026fc:	6145                	addi	sp,sp,48
    800026fe:	8082                	ret
    panic("sched p->lock");
    80002700:	00006517          	auipc	a0,0x6
    80002704:	bd050513          	addi	a0,a0,-1072 # 800082d0 <digits+0x290>
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	e22080e7          	jalr	-478(ra) # 8000052a <panic>
    panic("sched locks");
    80002710:	00006517          	auipc	a0,0x6
    80002714:	bd050513          	addi	a0,a0,-1072 # 800082e0 <digits+0x2a0>
    80002718:	ffffe097          	auipc	ra,0xffffe
    8000271c:	e12080e7          	jalr	-494(ra) # 8000052a <panic>
    panic("sched running");
    80002720:	00006517          	auipc	a0,0x6
    80002724:	bd050513          	addi	a0,a0,-1072 # 800082f0 <digits+0x2b0>
    80002728:	ffffe097          	auipc	ra,0xffffe
    8000272c:	e02080e7          	jalr	-510(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002730:	00006517          	auipc	a0,0x6
    80002734:	bd050513          	addi	a0,a0,-1072 # 80008300 <digits+0x2c0>
    80002738:	ffffe097          	auipc	ra,0xffffe
    8000273c:	df2080e7          	jalr	-526(ra) # 8000052a <panic>

0000000080002740 <yield>:
{
    80002740:	1101                	addi	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000274a:	00000097          	auipc	ra,0x0
    8000274e:	8c0080e7          	jalr	-1856(ra) # 8000200a <myproc>
    80002752:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	47e080e7          	jalr	1150(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    8000275c:	478d                	li	a5,3
    8000275e:	cc9c                	sw	a5,24(s1)
  sched();
    80002760:	00000097          	auipc	ra,0x0
    80002764:	f0a080e7          	jalr	-246(ra) # 8000266a <sched>
  release(&p->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	51c080e7          	jalr	1308(ra) # 80000c86 <release>
}
    80002772:	60e2                	ld	ra,24(sp)
    80002774:	6442                	ld	s0,16(sp)
    80002776:	64a2                	ld	s1,8(sp)
    80002778:	6105                	addi	sp,sp,32
    8000277a:	8082                	ret

000000008000277c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000277c:	7179                	addi	sp,sp,-48
    8000277e:	f406                	sd	ra,40(sp)
    80002780:	f022                	sd	s0,32(sp)
    80002782:	ec26                	sd	s1,24(sp)
    80002784:	e84a                	sd	s2,16(sp)
    80002786:	e44e                	sd	s3,8(sp)
    80002788:	1800                	addi	s0,sp,48
    8000278a:	89aa                	mv	s3,a0
    8000278c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000278e:	00000097          	auipc	ra,0x0
    80002792:	87c080e7          	jalr	-1924(ra) # 8000200a <myproc>
    80002796:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	43a080e7          	jalr	1082(ra) # 80000bd2 <acquire>
  release(lk);
    800027a0:	854a                	mv	a0,s2
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	4e4080e7          	jalr	1252(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    800027aa:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800027ae:	4789                	li	a5,2
    800027b0:	cc9c                	sw	a5,24(s1)

  sched();
    800027b2:	00000097          	auipc	ra,0x0
    800027b6:	eb8080e7          	jalr	-328(ra) # 8000266a <sched>

  // Tidy up.
  p->chan = 0;
    800027ba:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	4c6080e7          	jalr	1222(ra) # 80000c86 <release>
  acquire(lk);
    800027c8:	854a                	mv	a0,s2
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	408080e7          	jalr	1032(ra) # 80000bd2 <acquire>
}
    800027d2:	70a2                	ld	ra,40(sp)
    800027d4:	7402                	ld	s0,32(sp)
    800027d6:	64e2                	ld	s1,24(sp)
    800027d8:	6942                	ld	s2,16(sp)
    800027da:	69a2                	ld	s3,8(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret

00000000800027e0 <wait>:
{
    800027e0:	715d                	addi	sp,sp,-80
    800027e2:	e486                	sd	ra,72(sp)
    800027e4:	e0a2                	sd	s0,64(sp)
    800027e6:	fc26                	sd	s1,56(sp)
    800027e8:	f84a                	sd	s2,48(sp)
    800027ea:	f44e                	sd	s3,40(sp)
    800027ec:	f052                	sd	s4,32(sp)
    800027ee:	ec56                	sd	s5,24(sp)
    800027f0:	e85a                	sd	s6,16(sp)
    800027f2:	e45e                	sd	s7,8(sp)
    800027f4:	e062                	sd	s8,0(sp)
    800027f6:	0880                	addi	s0,sp,80
    800027f8:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027fa:	00000097          	auipc	ra,0x0
    800027fe:	810080e7          	jalr	-2032(ra) # 8000200a <myproc>
    80002802:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002804:	0000f517          	auipc	a0,0xf
    80002808:	ab450513          	addi	a0,a0,-1356 # 800112b8 <wait_lock>
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	3c6080e7          	jalr	966(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002814:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002816:	4a15                	li	s4,5
        havekids = 1;
    80002818:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    8000281a:	0001d997          	auipc	s3,0x1d
    8000281e:	eb698993          	addi	s3,s3,-330 # 8001f6d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002822:	0000fc17          	auipc	s8,0xf
    80002826:	a96c0c13          	addi	s8,s8,-1386 # 800112b8 <wait_lock>
    havekids = 0;
    8000282a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000282c:	0000f497          	auipc	s1,0xf
    80002830:	ea448493          	addi	s1,s1,-348 # 800116d0 <proc>
    80002834:	a0bd                	j	800028a2 <wait+0xc2>
          pid = np->pid;
    80002836:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000283a:	000b0e63          	beqz	s6,80002856 <wait+0x76>
    8000283e:	4691                	li	a3,4
    80002840:	02c48613          	addi	a2,s1,44
    80002844:	85da                	mv	a1,s6
    80002846:	05093503          	ld	a0,80(s2)
    8000284a:	fffff097          	auipc	ra,0xfffff
    8000284e:	db4080e7          	jalr	-588(ra) # 800015fe <copyout>
    80002852:	02054563          	bltz	a0,8000287c <wait+0x9c>
          freeproc(np);
    80002856:	8526                	mv	a0,s1
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	964080e7          	jalr	-1692(ra) # 800021bc <freeproc>
          release(&np->lock);
    80002860:	8526                	mv	a0,s1
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	424080e7          	jalr	1060(ra) # 80000c86 <release>
          release(&wait_lock);
    8000286a:	0000f517          	auipc	a0,0xf
    8000286e:	a4e50513          	addi	a0,a0,-1458 # 800112b8 <wait_lock>
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	414080e7          	jalr	1044(ra) # 80000c86 <release>
          return pid;
    8000287a:	a09d                	j	800028e0 <wait+0x100>
            release(&np->lock);
    8000287c:	8526                	mv	a0,s1
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	408080e7          	jalr	1032(ra) # 80000c86 <release>
            release(&wait_lock);
    80002886:	0000f517          	auipc	a0,0xf
    8000288a:	a3250513          	addi	a0,a0,-1486 # 800112b8 <wait_lock>
    8000288e:	ffffe097          	auipc	ra,0xffffe
    80002892:	3f8080e7          	jalr	1016(ra) # 80000c86 <release>
            return -1;
    80002896:	59fd                	li	s3,-1
    80002898:	a0a1                	j	800028e0 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000289a:	38048493          	addi	s1,s1,896
    8000289e:	03348463          	beq	s1,s3,800028c6 <wait+0xe6>
      if(np->parent == p){
    800028a2:	7c9c                	ld	a5,56(s1)
    800028a4:	ff279be3          	bne	a5,s2,8000289a <wait+0xba>
        acquire(&np->lock);
    800028a8:	8526                	mv	a0,s1
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	328080e7          	jalr	808(ra) # 80000bd2 <acquire>
        if(np->state == ZOMBIE){
    800028b2:	4c9c                	lw	a5,24(s1)
    800028b4:	f94781e3          	beq	a5,s4,80002836 <wait+0x56>
        release(&np->lock);
    800028b8:	8526                	mv	a0,s1
    800028ba:	ffffe097          	auipc	ra,0xffffe
    800028be:	3cc080e7          	jalr	972(ra) # 80000c86 <release>
        havekids = 1;
    800028c2:	8756                	mv	a4,s5
    800028c4:	bfd9                	j	8000289a <wait+0xba>
    if(!havekids || p->killed){
    800028c6:	c701                	beqz	a4,800028ce <wait+0xee>
    800028c8:	02892783          	lw	a5,40(s2)
    800028cc:	c79d                	beqz	a5,800028fa <wait+0x11a>
      release(&wait_lock);
    800028ce:	0000f517          	auipc	a0,0xf
    800028d2:	9ea50513          	addi	a0,a0,-1558 # 800112b8 <wait_lock>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	3b0080e7          	jalr	944(ra) # 80000c86 <release>
      return -1;
    800028de:	59fd                	li	s3,-1
}
    800028e0:	854e                	mv	a0,s3
    800028e2:	60a6                	ld	ra,72(sp)
    800028e4:	6406                	ld	s0,64(sp)
    800028e6:	74e2                	ld	s1,56(sp)
    800028e8:	7942                	ld	s2,48(sp)
    800028ea:	79a2                	ld	s3,40(sp)
    800028ec:	7a02                	ld	s4,32(sp)
    800028ee:	6ae2                	ld	s5,24(sp)
    800028f0:	6b42                	ld	s6,16(sp)
    800028f2:	6ba2                	ld	s7,8(sp)
    800028f4:	6c02                	ld	s8,0(sp)
    800028f6:	6161                	addi	sp,sp,80
    800028f8:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800028fa:	85e2                	mv	a1,s8
    800028fc:	854a                	mv	a0,s2
    800028fe:	00000097          	auipc	ra,0x0
    80002902:	e7e080e7          	jalr	-386(ra) # 8000277c <sleep>
    havekids = 0;
    80002906:	b715                	j	8000282a <wait+0x4a>

0000000080002908 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002908:	7139                	addi	sp,sp,-64
    8000290a:	fc06                	sd	ra,56(sp)
    8000290c:	f822                	sd	s0,48(sp)
    8000290e:	f426                	sd	s1,40(sp)
    80002910:	f04a                	sd	s2,32(sp)
    80002912:	ec4e                	sd	s3,24(sp)
    80002914:	e852                	sd	s4,16(sp)
    80002916:	e456                	sd	s5,8(sp)
    80002918:	0080                	addi	s0,sp,64
    8000291a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000291c:	0000f497          	auipc	s1,0xf
    80002920:	db448493          	addi	s1,s1,-588 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002924:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002926:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002928:	0001d917          	auipc	s2,0x1d
    8000292c:	da890913          	addi	s2,s2,-600 # 8001f6d0 <tickslock>
    80002930:	a811                	j	80002944 <wakeup+0x3c>
      }
      release(&p->lock);
    80002932:	8526                	mv	a0,s1
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	352080e7          	jalr	850(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000293c:	38048493          	addi	s1,s1,896
    80002940:	03248663          	beq	s1,s2,8000296c <wakeup+0x64>
    if(p != myproc()){
    80002944:	fffff097          	auipc	ra,0xfffff
    80002948:	6c6080e7          	jalr	1734(ra) # 8000200a <myproc>
    8000294c:	fea488e3          	beq	s1,a0,8000293c <wakeup+0x34>
      acquire(&p->lock);
    80002950:	8526                	mv	a0,s1
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	280080e7          	jalr	640(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000295a:	4c9c                	lw	a5,24(s1)
    8000295c:	fd379be3          	bne	a5,s3,80002932 <wakeup+0x2a>
    80002960:	709c                	ld	a5,32(s1)
    80002962:	fd4798e3          	bne	a5,s4,80002932 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002966:	0154ac23          	sw	s5,24(s1)
    8000296a:	b7e1                	j	80002932 <wakeup+0x2a>
    }
  }
}
    8000296c:	70e2                	ld	ra,56(sp)
    8000296e:	7442                	ld	s0,48(sp)
    80002970:	74a2                	ld	s1,40(sp)
    80002972:	7902                	ld	s2,32(sp)
    80002974:	69e2                	ld	s3,24(sp)
    80002976:	6a42                	ld	s4,16(sp)
    80002978:	6aa2                	ld	s5,8(sp)
    8000297a:	6121                	addi	sp,sp,64
    8000297c:	8082                	ret

000000008000297e <reparent>:
{
    8000297e:	7179                	addi	sp,sp,-48
    80002980:	f406                	sd	ra,40(sp)
    80002982:	f022                	sd	s0,32(sp)
    80002984:	ec26                	sd	s1,24(sp)
    80002986:	e84a                	sd	s2,16(sp)
    80002988:	e44e                	sd	s3,8(sp)
    8000298a:	e052                	sd	s4,0(sp)
    8000298c:	1800                	addi	s0,sp,48
    8000298e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002990:	0000f497          	auipc	s1,0xf
    80002994:	d4048493          	addi	s1,s1,-704 # 800116d0 <proc>
      pp->parent = initproc;
    80002998:	00006a17          	auipc	s4,0x6
    8000299c:	690a0a13          	addi	s4,s4,1680 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800029a0:	0001d997          	auipc	s3,0x1d
    800029a4:	d3098993          	addi	s3,s3,-720 # 8001f6d0 <tickslock>
    800029a8:	a029                	j	800029b2 <reparent+0x34>
    800029aa:	38048493          	addi	s1,s1,896
    800029ae:	01348d63          	beq	s1,s3,800029c8 <reparent+0x4a>
    if(pp->parent == p){
    800029b2:	7c9c                	ld	a5,56(s1)
    800029b4:	ff279be3          	bne	a5,s2,800029aa <reparent+0x2c>
      pp->parent = initproc;
    800029b8:	000a3503          	ld	a0,0(s4)
    800029bc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800029be:	00000097          	auipc	ra,0x0
    800029c2:	f4a080e7          	jalr	-182(ra) # 80002908 <wakeup>
    800029c6:	b7d5                	j	800029aa <reparent+0x2c>
}
    800029c8:	70a2                	ld	ra,40(sp)
    800029ca:	7402                	ld	s0,32(sp)
    800029cc:	64e2                	ld	s1,24(sp)
    800029ce:	6942                	ld	s2,16(sp)
    800029d0:	69a2                	ld	s3,8(sp)
    800029d2:	6a02                	ld	s4,0(sp)
    800029d4:	6145                	addi	sp,sp,48
    800029d6:	8082                	ret

00000000800029d8 <exit>:
{
    800029d8:	7179                	addi	sp,sp,-48
    800029da:	f406                	sd	ra,40(sp)
    800029dc:	f022                	sd	s0,32(sp)
    800029de:	ec26                	sd	s1,24(sp)
    800029e0:	e84a                	sd	s2,16(sp)
    800029e2:	e44e                	sd	s3,8(sp)
    800029e4:	e052                	sd	s4,0(sp)
    800029e6:	1800                	addi	s0,sp,48
    800029e8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	620080e7          	jalr	1568(ra) # 8000200a <myproc>
    800029f2:	89aa                	mv	s3,a0
  if(p == initproc)
    800029f4:	00006797          	auipc	a5,0x6
    800029f8:	6347b783          	ld	a5,1588(a5) # 80009028 <initproc>
    800029fc:	0d050493          	addi	s1,a0,208
    80002a00:	15050913          	addi	s2,a0,336
    80002a04:	02a79363          	bne	a5,a0,80002a2a <exit+0x52>
    panic("init exiting");
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	91050513          	addi	a0,a0,-1776 # 80008318 <digits+0x2d8>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b1a080e7          	jalr	-1254(ra) # 8000052a <panic>
      fileclose(f);
    80002a18:	00002097          	auipc	ra,0x2
    80002a1c:	4b0080e7          	jalr	1200(ra) # 80004ec8 <fileclose>
      p->ofile[fd] = 0;
    80002a20:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a24:	04a1                	addi	s1,s1,8
    80002a26:	01248563          	beq	s1,s2,80002a30 <exit+0x58>
    if(p->ofile[fd]){
    80002a2a:	6088                	ld	a0,0(s1)
    80002a2c:	f575                	bnez	a0,80002a18 <exit+0x40>
    80002a2e:	bfdd                	j	80002a24 <exit+0x4c>
  if(p->pid > 2)
    80002a30:	0309a703          	lw	a4,48(s3)
    80002a34:	4789                	li	a5,2
    80002a36:	08e7c163          	blt	a5,a4,80002ab8 <exit+0xe0>
  begin_op();
    80002a3a:	00002097          	auipc	ra,0x2
    80002a3e:	fc2080e7          	jalr	-62(ra) # 800049fc <begin_op>
  iput(p->cwd);
    80002a42:	1509b503          	ld	a0,336(s3)
    80002a46:	00001097          	auipc	ra,0x1
    80002a4a:	488080e7          	jalr	1160(ra) # 80003ece <iput>
  end_op();
    80002a4e:	00002097          	auipc	ra,0x2
    80002a52:	02e080e7          	jalr	46(ra) # 80004a7c <end_op>
  p->cwd = 0;
    80002a56:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002a5a:	0000f497          	auipc	s1,0xf
    80002a5e:	85e48493          	addi	s1,s1,-1954 # 800112b8 <wait_lock>
    80002a62:	8526                	mv	a0,s1
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	16e080e7          	jalr	366(ra) # 80000bd2 <acquire>
  reparent(p);
    80002a6c:	854e                	mv	a0,s3
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	f10080e7          	jalr	-240(ra) # 8000297e <reparent>
  wakeup(p->parent);
    80002a76:	0389b503          	ld	a0,56(s3)
    80002a7a:	00000097          	auipc	ra,0x0
    80002a7e:	e8e080e7          	jalr	-370(ra) # 80002908 <wakeup>
  acquire(&p->lock);
    80002a82:	854e                	mv	a0,s3
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	14e080e7          	jalr	334(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002a8c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002a90:	4795                	li	a5,5
    80002a92:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002a96:	8526                	mv	a0,s1
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	1ee080e7          	jalr	494(ra) # 80000c86 <release>
  sched();
    80002aa0:	00000097          	auipc	ra,0x0
    80002aa4:	bca080e7          	jalr	-1078(ra) # 8000266a <sched>
  panic("zombie exit");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	88050513          	addi	a0,a0,-1920 # 80008328 <digits+0x2e8>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a7a080e7          	jalr	-1414(ra) # 8000052a <panic>
    removeSwapFile(p);
    80002ab8:	854e                	mv	a0,s3
    80002aba:	00002097          	auipc	ra,0x2
    80002abe:	abc080e7          	jalr	-1348(ra) # 80004576 <removeSwapFile>
    80002ac2:	bfa5                	j	80002a3a <exit+0x62>

0000000080002ac4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002ac4:	7179                	addi	sp,sp,-48
    80002ac6:	f406                	sd	ra,40(sp)
    80002ac8:	f022                	sd	s0,32(sp)
    80002aca:	ec26                	sd	s1,24(sp)
    80002acc:	e84a                	sd	s2,16(sp)
    80002ace:	e44e                	sd	s3,8(sp)
    80002ad0:	1800                	addi	s0,sp,48
    80002ad2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002ad4:	0000f497          	auipc	s1,0xf
    80002ad8:	bfc48493          	addi	s1,s1,-1028 # 800116d0 <proc>
    80002adc:	0001d997          	auipc	s3,0x1d
    80002ae0:	bf498993          	addi	s3,s3,-1036 # 8001f6d0 <tickslock>
    acquire(&p->lock);
    80002ae4:	8526                	mv	a0,s1
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	0ec080e7          	jalr	236(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002aee:	589c                	lw	a5,48(s1)
    80002af0:	01278d63          	beq	a5,s2,80002b0a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002af4:	8526                	mv	a0,s1
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	190080e7          	jalr	400(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002afe:	38048493          	addi	s1,s1,896
    80002b02:	ff3491e3          	bne	s1,s3,80002ae4 <kill+0x20>
  }
  return -1;
    80002b06:	557d                	li	a0,-1
    80002b08:	a829                	j	80002b22 <kill+0x5e>
      p->killed = 1;
    80002b0a:	4785                	li	a5,1
    80002b0c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002b0e:	4c98                	lw	a4,24(s1)
    80002b10:	4789                	li	a5,2
    80002b12:	00f70f63          	beq	a4,a5,80002b30 <kill+0x6c>
      release(&p->lock);
    80002b16:	8526                	mv	a0,s1
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	16e080e7          	jalr	366(ra) # 80000c86 <release>
      return 0;
    80002b20:	4501                	li	a0,0
}
    80002b22:	70a2                	ld	ra,40(sp)
    80002b24:	7402                	ld	s0,32(sp)
    80002b26:	64e2                	ld	s1,24(sp)
    80002b28:	6942                	ld	s2,16(sp)
    80002b2a:	69a2                	ld	s3,8(sp)
    80002b2c:	6145                	addi	sp,sp,48
    80002b2e:	8082                	ret
        p->state = RUNNABLE;
    80002b30:	478d                	li	a5,3
    80002b32:	cc9c                	sw	a5,24(s1)
    80002b34:	b7cd                	j	80002b16 <kill+0x52>

0000000080002b36 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002b36:	7179                	addi	sp,sp,-48
    80002b38:	f406                	sd	ra,40(sp)
    80002b3a:	f022                	sd	s0,32(sp)
    80002b3c:	ec26                	sd	s1,24(sp)
    80002b3e:	e84a                	sd	s2,16(sp)
    80002b40:	e44e                	sd	s3,8(sp)
    80002b42:	e052                	sd	s4,0(sp)
    80002b44:	1800                	addi	s0,sp,48
    80002b46:	84aa                	mv	s1,a0
    80002b48:	892e                	mv	s2,a1
    80002b4a:	89b2                	mv	s3,a2
    80002b4c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	4bc080e7          	jalr	1212(ra) # 8000200a <myproc>
  if(user_dst){
    80002b56:	c08d                	beqz	s1,80002b78 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002b58:	86d2                	mv	a3,s4
    80002b5a:	864e                	mv	a2,s3
    80002b5c:	85ca                	mv	a1,s2
    80002b5e:	6928                	ld	a0,80(a0)
    80002b60:	fffff097          	auipc	ra,0xfffff
    80002b64:	a9e080e7          	jalr	-1378(ra) # 800015fe <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002b68:	70a2                	ld	ra,40(sp)
    80002b6a:	7402                	ld	s0,32(sp)
    80002b6c:	64e2                	ld	s1,24(sp)
    80002b6e:	6942                	ld	s2,16(sp)
    80002b70:	69a2                	ld	s3,8(sp)
    80002b72:	6a02                	ld	s4,0(sp)
    80002b74:	6145                	addi	sp,sp,48
    80002b76:	8082                	ret
    memmove((char *)dst, src, len);
    80002b78:	000a061b          	sext.w	a2,s4
    80002b7c:	85ce                	mv	a1,s3
    80002b7e:	854a                	mv	a0,s2
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	1aa080e7          	jalr	426(ra) # 80000d2a <memmove>
    return 0;
    80002b88:	8526                	mv	a0,s1
    80002b8a:	bff9                	j	80002b68 <either_copyout+0x32>

0000000080002b8c <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002b8c:	7179                	addi	sp,sp,-48
    80002b8e:	f406                	sd	ra,40(sp)
    80002b90:	f022                	sd	s0,32(sp)
    80002b92:	ec26                	sd	s1,24(sp)
    80002b94:	e84a                	sd	s2,16(sp)
    80002b96:	e44e                	sd	s3,8(sp)
    80002b98:	e052                	sd	s4,0(sp)
    80002b9a:	1800                	addi	s0,sp,48
    80002b9c:	892a                	mv	s2,a0
    80002b9e:	84ae                	mv	s1,a1
    80002ba0:	89b2                	mv	s3,a2
    80002ba2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	466080e7          	jalr	1126(ra) # 8000200a <myproc>
  if(user_src){
    80002bac:	c08d                	beqz	s1,80002bce <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002bae:	86d2                	mv	a3,s4
    80002bb0:	864e                	mv	a2,s3
    80002bb2:	85ca                	mv	a1,s2
    80002bb4:	6928                	ld	a0,80(a0)
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	ad4080e7          	jalr	-1324(ra) # 8000168a <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002bbe:	70a2                	ld	ra,40(sp)
    80002bc0:	7402                	ld	s0,32(sp)
    80002bc2:	64e2                	ld	s1,24(sp)
    80002bc4:	6942                	ld	s2,16(sp)
    80002bc6:	69a2                	ld	s3,8(sp)
    80002bc8:	6a02                	ld	s4,0(sp)
    80002bca:	6145                	addi	sp,sp,48
    80002bcc:	8082                	ret
    memmove(dst, (char*)src, len);
    80002bce:	000a061b          	sext.w	a2,s4
    80002bd2:	85ce                	mv	a1,s3
    80002bd4:	854a                	mv	a0,s2
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	154080e7          	jalr	340(ra) # 80000d2a <memmove>
    return 0;
    80002bde:	8526                	mv	a0,s1
    80002be0:	bff9                	j	80002bbe <either_copyin+0x32>

0000000080002be2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002be2:	715d                	addi	sp,sp,-80
    80002be4:	e486                	sd	ra,72(sp)
    80002be6:	e0a2                	sd	s0,64(sp)
    80002be8:	fc26                	sd	s1,56(sp)
    80002bea:	f84a                	sd	s2,48(sp)
    80002bec:	f44e                	sd	s3,40(sp)
    80002bee:	f052                	sd	s4,32(sp)
    80002bf0:	ec56                	sd	s5,24(sp)
    80002bf2:	e85a                	sd	s6,16(sp)
    80002bf4:	e45e                	sd	s7,8(sp)
    80002bf6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002bf8:	00005517          	auipc	a0,0x5
    80002bfc:	4e850513          	addi	a0,a0,1256 # 800080e0 <digits+0xa0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	974080e7          	jalr	-1676(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c08:	0000f497          	auipc	s1,0xf
    80002c0c:	c2048493          	addi	s1,s1,-992 # 80011828 <proc+0x158>
    80002c10:	0001d917          	auipc	s2,0x1d
    80002c14:	c1890913          	addi	s2,s2,-1000 # 8001f828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c18:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002c1a:	00005997          	auipc	s3,0x5
    80002c1e:	71e98993          	addi	s3,s3,1822 # 80008338 <digits+0x2f8>
    printf("%d %s %s", p->pid, state, p->name);
    80002c22:	00005a97          	auipc	s5,0x5
    80002c26:	71ea8a93          	addi	s5,s5,1822 # 80008340 <digits+0x300>
    printf("\n");
    80002c2a:	00005a17          	auipc	s4,0x5
    80002c2e:	4b6a0a13          	addi	s4,s4,1206 # 800080e0 <digits+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c32:	00005b97          	auipc	s7,0x5
    80002c36:	746b8b93          	addi	s7,s7,1862 # 80008378 <states.0>
    80002c3a:	a00d                	j	80002c5c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002c3c:	ed86a583          	lw	a1,-296(a3)
    80002c40:	8556                	mv	a0,s5
    80002c42:	ffffe097          	auipc	ra,0xffffe
    80002c46:	932080e7          	jalr	-1742(ra) # 80000574 <printf>
    printf("\n");
    80002c4a:	8552                	mv	a0,s4
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	928080e7          	jalr	-1752(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002c54:	38048493          	addi	s1,s1,896
    80002c58:	03248263          	beq	s1,s2,80002c7c <procdump+0x9a>
    if(p->state == UNUSED)
    80002c5c:	86a6                	mv	a3,s1
    80002c5e:	ec04a783          	lw	a5,-320(s1)
    80002c62:	dbed                	beqz	a5,80002c54 <procdump+0x72>
      state = "???";
    80002c64:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002c66:	fcfb6be3          	bltu	s6,a5,80002c3c <procdump+0x5a>
    80002c6a:	02079713          	slli	a4,a5,0x20
    80002c6e:	01d75793          	srli	a5,a4,0x1d
    80002c72:	97de                	add	a5,a5,s7
    80002c74:	6390                	ld	a2,0(a5)
    80002c76:	f279                	bnez	a2,80002c3c <procdump+0x5a>
      state = "???";
    80002c78:	864e                	mv	a2,s3
    80002c7a:	b7c9                	j	80002c3c <procdump+0x5a>
  }
}
    80002c7c:	60a6                	ld	ra,72(sp)
    80002c7e:	6406                	ld	s0,64(sp)
    80002c80:	74e2                	ld	s1,56(sp)
    80002c82:	7942                	ld	s2,48(sp)
    80002c84:	79a2                	ld	s3,40(sp)
    80002c86:	7a02                	ld	s4,32(sp)
    80002c88:	6ae2                	ld	s5,24(sp)
    80002c8a:	6b42                	ld	s6,16(sp)
    80002c8c:	6ba2                	ld	s7,8(sp)
    80002c8e:	6161                	addi	sp,sp,80
    80002c90:	8082                	ret

0000000080002c92 <swtch>:
    80002c92:	00153023          	sd	ra,0(a0)
    80002c96:	00253423          	sd	sp,8(a0)
    80002c9a:	e900                	sd	s0,16(a0)
    80002c9c:	ed04                	sd	s1,24(a0)
    80002c9e:	03253023          	sd	s2,32(a0)
    80002ca2:	03353423          	sd	s3,40(a0)
    80002ca6:	03453823          	sd	s4,48(a0)
    80002caa:	03553c23          	sd	s5,56(a0)
    80002cae:	05653023          	sd	s6,64(a0)
    80002cb2:	05753423          	sd	s7,72(a0)
    80002cb6:	05853823          	sd	s8,80(a0)
    80002cba:	05953c23          	sd	s9,88(a0)
    80002cbe:	07a53023          	sd	s10,96(a0)
    80002cc2:	07b53423          	sd	s11,104(a0)
    80002cc6:	0005b083          	ld	ra,0(a1)
    80002cca:	0085b103          	ld	sp,8(a1)
    80002cce:	6980                	ld	s0,16(a1)
    80002cd0:	6d84                	ld	s1,24(a1)
    80002cd2:	0205b903          	ld	s2,32(a1)
    80002cd6:	0285b983          	ld	s3,40(a1)
    80002cda:	0305ba03          	ld	s4,48(a1)
    80002cde:	0385ba83          	ld	s5,56(a1)
    80002ce2:	0405bb03          	ld	s6,64(a1)
    80002ce6:	0485bb83          	ld	s7,72(a1)
    80002cea:	0505bc03          	ld	s8,80(a1)
    80002cee:	0585bc83          	ld	s9,88(a1)
    80002cf2:	0605bd03          	ld	s10,96(a1)
    80002cf6:	0685bd83          	ld	s11,104(a1)
    80002cfa:	8082                	ret

0000000080002cfc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cfc:	1141                	addi	sp,sp,-16
    80002cfe:	e406                	sd	ra,8(sp)
    80002d00:	e022                	sd	s0,0(sp)
    80002d02:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d04:	00005597          	auipc	a1,0x5
    80002d08:	6a458593          	addi	a1,a1,1700 # 800083a8 <states.0+0x30>
    80002d0c:	0001d517          	auipc	a0,0x1d
    80002d10:	9c450513          	addi	a0,a0,-1596 # 8001f6d0 <tickslock>
    80002d14:	ffffe097          	auipc	ra,0xffffe
    80002d18:	e2e080e7          	jalr	-466(ra) # 80000b42 <initlock>
}
    80002d1c:	60a2                	ld	ra,8(sp)
    80002d1e:	6402                	ld	s0,0(sp)
    80002d20:	0141                	addi	sp,sp,16
    80002d22:	8082                	ret

0000000080002d24 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d24:	1141                	addi	sp,sp,-16
    80002d26:	e422                	sd	s0,8(sp)
    80002d28:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d2a:	00004797          	auipc	a5,0x4
    80002d2e:	9e678793          	addi	a5,a5,-1562 # 80006710 <kernelvec>
    80002d32:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d36:	6422                	ld	s0,8(sp)
    80002d38:	0141                	addi	sp,sp,16
    80002d3a:	8082                	ret

0000000080002d3c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d3c:	1141                	addi	sp,sp,-16
    80002d3e:	e406                	sd	ra,8(sp)
    80002d40:	e022                	sd	s0,0(sp)
    80002d42:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	2c6080e7          	jalr	710(ra) # 8000200a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d50:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d52:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d56:	00004617          	auipc	a2,0x4
    80002d5a:	2aa60613          	addi	a2,a2,682 # 80007000 <_trampoline>
    80002d5e:	00004697          	auipc	a3,0x4
    80002d62:	2a268693          	addi	a3,a3,674 # 80007000 <_trampoline>
    80002d66:	8e91                	sub	a3,a3,a2
    80002d68:	040007b7          	lui	a5,0x4000
    80002d6c:	17fd                	addi	a5,a5,-1
    80002d6e:	07b2                	slli	a5,a5,0xc
    80002d70:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d72:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d76:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d78:	180026f3          	csrr	a3,satp
    80002d7c:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d7e:	6d38                	ld	a4,88(a0)
    80002d80:	6134                	ld	a3,64(a0)
    80002d82:	6585                	lui	a1,0x1
    80002d84:	96ae                	add	a3,a3,a1
    80002d86:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d88:	6d38                	ld	a4,88(a0)
    80002d8a:	00000697          	auipc	a3,0x0
    80002d8e:	13868693          	addi	a3,a3,312 # 80002ec2 <usertrap>
    80002d92:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d94:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d96:	8692                	mv	a3,tp
    80002d98:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d9a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d9e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002da2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002da6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002daa:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dac:	6f18                	ld	a4,24(a4)
    80002dae:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002db2:	692c                	ld	a1,80(a0)
    80002db4:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002db6:	00004717          	auipc	a4,0x4
    80002dba:	2da70713          	addi	a4,a4,730 # 80007090 <userret>
    80002dbe:	8f11                	sub	a4,a4,a2
    80002dc0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dc2:	577d                	li	a4,-1
    80002dc4:	177e                	slli	a4,a4,0x3f
    80002dc6:	8dd9                	or	a1,a1,a4
    80002dc8:	02000537          	lui	a0,0x2000
    80002dcc:	157d                	addi	a0,a0,-1
    80002dce:	0536                	slli	a0,a0,0xd
    80002dd0:	9782                	jalr	a5
}
    80002dd2:	60a2                	ld	ra,8(sp)
    80002dd4:	6402                	ld	s0,0(sp)
    80002dd6:	0141                	addi	sp,sp,16
    80002dd8:	8082                	ret

0000000080002dda <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dda:	1101                	addi	sp,sp,-32
    80002ddc:	ec06                	sd	ra,24(sp)
    80002dde:	e822                	sd	s0,16(sp)
    80002de0:	e426                	sd	s1,8(sp)
    80002de2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002de4:	0001d497          	auipc	s1,0x1d
    80002de8:	8ec48493          	addi	s1,s1,-1812 # 8001f6d0 <tickslock>
    80002dec:	8526                	mv	a0,s1
    80002dee:	ffffe097          	auipc	ra,0xffffe
    80002df2:	de4080e7          	jalr	-540(ra) # 80000bd2 <acquire>
  ticks++;
    80002df6:	00006517          	auipc	a0,0x6
    80002dfa:	23a50513          	addi	a0,a0,570 # 80009030 <ticks>
    80002dfe:	411c                	lw	a5,0(a0)
    80002e00:	2785                	addiw	a5,a5,1
    80002e02:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	b04080e7          	jalr	-1276(ra) # 80002908 <wakeup>
  release(&tickslock);
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	e78080e7          	jalr	-392(ra) # 80000c86 <release>
}
    80002e16:	60e2                	ld	ra,24(sp)
    80002e18:	6442                	ld	s0,16(sp)
    80002e1a:	64a2                	ld	s1,8(sp)
    80002e1c:	6105                	addi	sp,sp,32
    80002e1e:	8082                	ret

0000000080002e20 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e2a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e2e:	00074d63          	bltz	a4,80002e48 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e32:	57fd                	li	a5,-1
    80002e34:	17fe                	slli	a5,a5,0x3f
    80002e36:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e38:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e3a:	06f70363          	beq	a4,a5,80002ea0 <devintr+0x80>
  }
}
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	64a2                	ld	s1,8(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret
     (scause & 0xff) == 9){
    80002e48:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e4c:	46a5                	li	a3,9
    80002e4e:	fed792e3          	bne	a5,a3,80002e32 <devintr+0x12>
    int irq = plic_claim();
    80002e52:	00004097          	auipc	ra,0x4
    80002e56:	9c6080e7          	jalr	-1594(ra) # 80006818 <plic_claim>
    80002e5a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e5c:	47a9                	li	a5,10
    80002e5e:	02f50763          	beq	a0,a5,80002e8c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e62:	4785                	li	a5,1
    80002e64:	02f50963          	beq	a0,a5,80002e96 <devintr+0x76>
    return 1;
    80002e68:	4505                	li	a0,1
    } else if(irq){
    80002e6a:	d8f1                	beqz	s1,80002e3e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e6c:	85a6                	mv	a1,s1
    80002e6e:	00005517          	auipc	a0,0x5
    80002e72:	54250513          	addi	a0,a0,1346 # 800083b0 <states.0+0x38>
    80002e76:	ffffd097          	auipc	ra,0xffffd
    80002e7a:	6fe080e7          	jalr	1790(ra) # 80000574 <printf>
      plic_complete(irq);
    80002e7e:	8526                	mv	a0,s1
    80002e80:	00004097          	auipc	ra,0x4
    80002e84:	9bc080e7          	jalr	-1604(ra) # 8000683c <plic_complete>
    return 1;
    80002e88:	4505                	li	a0,1
    80002e8a:	bf55                	j	80002e3e <devintr+0x1e>
      uartintr();
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	afa080e7          	jalr	-1286(ra) # 80000986 <uartintr>
    80002e94:	b7ed                	j	80002e7e <devintr+0x5e>
      virtio_disk_intr();
    80002e96:	00004097          	auipc	ra,0x4
    80002e9a:	e38080e7          	jalr	-456(ra) # 80006cce <virtio_disk_intr>
    80002e9e:	b7c5                	j	80002e7e <devintr+0x5e>
    if(cpuid() == 0){
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	13e080e7          	jalr	318(ra) # 80001fde <cpuid>
    80002ea8:	c901                	beqz	a0,80002eb8 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002eaa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002eae:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002eb0:	14479073          	csrw	sip,a5
    return 2;
    80002eb4:	4509                	li	a0,2
    80002eb6:	b761                	j	80002e3e <devintr+0x1e>
      clockintr();
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	f22080e7          	jalr	-222(ra) # 80002dda <clockintr>
    80002ec0:	b7ed                	j	80002eaa <devintr+0x8a>

0000000080002ec2 <usertrap>:
{
    80002ec2:	1101                	addi	sp,sp,-32
    80002ec4:	ec06                	sd	ra,24(sp)
    80002ec6:	e822                	sd	s0,16(sp)
    80002ec8:	e426                	sd	s1,8(sp)
    80002eca:	e04a                	sd	s2,0(sp)
    80002ecc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ece:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ed2:	1007f793          	andi	a5,a5,256
    80002ed6:	efb9                	bnez	a5,80002f34 <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ed8:	00004797          	auipc	a5,0x4
    80002edc:	83878793          	addi	a5,a5,-1992 # 80006710 <kernelvec>
    80002ee0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	126080e7          	jalr	294(ra) # 8000200a <myproc>
    80002eec:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002eee:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef0:	14102773          	csrr	a4,sepc
    80002ef4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002efa:	47a1                	li	a5,8
    80002efc:	04f70463          	beq	a4,a5,80002f44 <usertrap+0x82>
    80002f00:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    80002f04:	47b5                	li	a5,13
    80002f06:	00f70763          	beq	a4,a5,80002f14 <usertrap+0x52>
    80002f0a:	14202773          	csrr	a4,scause
    80002f0e:	47bd                	li	a5,15
    80002f10:	06f71163          	bne	a4,a5,80002f72 <usertrap+0xb0>
    check_page_fault();
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	af6080e7          	jalr	-1290(ra) # 80001a0a <check_page_fault>
  if(p->killed)
    80002f1c:	549c                	lw	a5,40(s1)
    80002f1e:	efc9                	bnez	a5,80002fb8 <usertrap+0xf6>
  usertrapret();
    80002f20:	00000097          	auipc	ra,0x0
    80002f24:	e1c080e7          	jalr	-484(ra) # 80002d3c <usertrapret>
}
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6902                	ld	s2,0(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret
    panic("usertrap: not from user mode");
    80002f34:	00005517          	auipc	a0,0x5
    80002f38:	49c50513          	addi	a0,a0,1180 # 800083d0 <states.0+0x58>
    80002f3c:	ffffd097          	auipc	ra,0xffffd
    80002f40:	5ee080e7          	jalr	1518(ra) # 8000052a <panic>
    if(p->killed)
    80002f44:	551c                	lw	a5,40(a0)
    80002f46:	e385                	bnez	a5,80002f66 <usertrap+0xa4>
    p->trapframe->epc += 4;
    80002f48:	6cb8                	ld	a4,88(s1)
    80002f4a:	6f1c                	ld	a5,24(a4)
    80002f4c:	0791                	addi	a5,a5,4
    80002f4e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f54:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f58:	10079073          	csrw	sstatus,a5
    syscall();
    80002f5c:	00000097          	auipc	ra,0x0
    80002f60:	2ba080e7          	jalr	698(ra) # 80003216 <syscall>
    80002f64:	bf65                	j	80002f1c <usertrap+0x5a>
      exit(-1);
    80002f66:	557d                	li	a0,-1
    80002f68:	00000097          	auipc	ra,0x0
    80002f6c:	a70080e7          	jalr	-1424(ra) # 800029d8 <exit>
    80002f70:	bfe1                	j	80002f48 <usertrap+0x86>
  else if((which_dev = devintr()) != 0){
    80002f72:	00000097          	auipc	ra,0x0
    80002f76:	eae080e7          	jalr	-338(ra) # 80002e20 <devintr>
    80002f7a:	892a                	mv	s2,a0
    80002f7c:	c501                	beqz	a0,80002f84 <usertrap+0xc2>
  if(p->killed)
    80002f7e:	549c                	lw	a5,40(s1)
    80002f80:	c3b1                	beqz	a5,80002fc4 <usertrap+0x102>
    80002f82:	a825                	j	80002fba <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f84:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f88:	5890                	lw	a2,48(s1)
    80002f8a:	00005517          	auipc	a0,0x5
    80002f8e:	46650513          	addi	a0,a0,1126 # 800083f0 <states.0+0x78>
    80002f92:	ffffd097          	auipc	ra,0xffffd
    80002f96:	5e2080e7          	jalr	1506(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f9a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f9e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fa2:	00005517          	auipc	a0,0x5
    80002fa6:	47e50513          	addi	a0,a0,1150 # 80008420 <states.0+0xa8>
    80002faa:	ffffd097          	auipc	ra,0xffffd
    80002fae:	5ca080e7          	jalr	1482(ra) # 80000574 <printf>
    p->killed = 1;
    80002fb2:	4785                	li	a5,1
    80002fb4:	d49c                	sw	a5,40(s1)
  if(p->killed)
    80002fb6:	a011                	j	80002fba <usertrap+0xf8>
    80002fb8:	4901                	li	s2,0
    exit(-1);
    80002fba:	557d                	li	a0,-1
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	a1c080e7          	jalr	-1508(ra) # 800029d8 <exit>
  if(which_dev == 2)
    80002fc4:	4789                	li	a5,2
    80002fc6:	f4f91de3          	bne	s2,a5,80002f20 <usertrap+0x5e>
    yield();
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	776080e7          	jalr	1910(ra) # 80002740 <yield>
    80002fd2:	b7b9                	j	80002f20 <usertrap+0x5e>

0000000080002fd4 <kerneltrap>:
{
    80002fd4:	7179                	addi	sp,sp,-48
    80002fd6:	f406                	sd	ra,40(sp)
    80002fd8:	f022                	sd	s0,32(sp)
    80002fda:	ec26                	sd	s1,24(sp)
    80002fdc:	e84a                	sd	s2,16(sp)
    80002fde:	e44e                	sd	s3,8(sp)
    80002fe0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fe2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fe6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fea:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fee:	1004f793          	andi	a5,s1,256
    80002ff2:	cb85                	beqz	a5,80003022 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ff4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ff8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ffa:	ef85                	bnez	a5,80003032 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ffc:	00000097          	auipc	ra,0x0
    80003000:	e24080e7          	jalr	-476(ra) # 80002e20 <devintr>
    80003004:	cd1d                	beqz	a0,80003042 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003006:	4789                	li	a5,2
    80003008:	06f50a63          	beq	a0,a5,8000307c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000300c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003010:	10049073          	csrw	sstatus,s1
}
    80003014:	70a2                	ld	ra,40(sp)
    80003016:	7402                	ld	s0,32(sp)
    80003018:	64e2                	ld	s1,24(sp)
    8000301a:	6942                	ld	s2,16(sp)
    8000301c:	69a2                	ld	s3,8(sp)
    8000301e:	6145                	addi	sp,sp,48
    80003020:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	41e50513          	addi	a0,a0,1054 # 80008440 <states.0+0xc8>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	500080e7          	jalr	1280(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	43650513          	addi	a0,a0,1078 # 80008468 <states.0+0xf0>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	4f0080e7          	jalr	1264(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003042:	85ce                	mv	a1,s3
    80003044:	00005517          	auipc	a0,0x5
    80003048:	44450513          	addi	a0,a0,1092 # 80008488 <states.0+0x110>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	528080e7          	jalr	1320(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003054:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003058:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	43c50513          	addi	a0,a0,1084 # 80008498 <states.0+0x120>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	510080e7          	jalr	1296(ra) # 80000574 <printf>
    panic("kerneltrap");
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	44450513          	addi	a0,a0,1092 # 800084b0 <states.0+0x138>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4b6080e7          	jalr	1206(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000307c:	fffff097          	auipc	ra,0xfffff
    80003080:	f8e080e7          	jalr	-114(ra) # 8000200a <myproc>
    80003084:	d541                	beqz	a0,8000300c <kerneltrap+0x38>
    80003086:	fffff097          	auipc	ra,0xfffff
    8000308a:	f84080e7          	jalr	-124(ra) # 8000200a <myproc>
    8000308e:	4d18                	lw	a4,24(a0)
    80003090:	4791                	li	a5,4
    80003092:	f6f71de3          	bne	a4,a5,8000300c <kerneltrap+0x38>
    yield();
    80003096:	fffff097          	auipc	ra,0xfffff
    8000309a:	6aa080e7          	jalr	1706(ra) # 80002740 <yield>
    8000309e:	b7bd                	j	8000300c <kerneltrap+0x38>

00000000800030a0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	f5e080e7          	jalr	-162(ra) # 8000200a <myproc>
  switch (n) {
    800030b4:	4795                	li	a5,5
    800030b6:	0497e163          	bltu	a5,s1,800030f8 <argraw+0x58>
    800030ba:	048a                	slli	s1,s1,0x2
    800030bc:	00005717          	auipc	a4,0x5
    800030c0:	42c70713          	addi	a4,a4,1068 # 800084e8 <states.0+0x170>
    800030c4:	94ba                	add	s1,s1,a4
    800030c6:	409c                	lw	a5,0(s1)
    800030c8:	97ba                	add	a5,a5,a4
    800030ca:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800030cc:	6d3c                	ld	a5,88(a0)
    800030ce:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800030d0:	60e2                	ld	ra,24(sp)
    800030d2:	6442                	ld	s0,16(sp)
    800030d4:	64a2                	ld	s1,8(sp)
    800030d6:	6105                	addi	sp,sp,32
    800030d8:	8082                	ret
    return p->trapframe->a1;
    800030da:	6d3c                	ld	a5,88(a0)
    800030dc:	7fa8                	ld	a0,120(a5)
    800030de:	bfcd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a2;
    800030e0:	6d3c                	ld	a5,88(a0)
    800030e2:	63c8                	ld	a0,128(a5)
    800030e4:	b7f5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a3;
    800030e6:	6d3c                	ld	a5,88(a0)
    800030e8:	67c8                	ld	a0,136(a5)
    800030ea:	b7dd                	j	800030d0 <argraw+0x30>
    return p->trapframe->a4;
    800030ec:	6d3c                	ld	a5,88(a0)
    800030ee:	6bc8                	ld	a0,144(a5)
    800030f0:	b7c5                	j	800030d0 <argraw+0x30>
    return p->trapframe->a5;
    800030f2:	6d3c                	ld	a5,88(a0)
    800030f4:	6fc8                	ld	a0,152(a5)
    800030f6:	bfe9                	j	800030d0 <argraw+0x30>
  panic("argraw");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	3c850513          	addi	a0,a0,968 # 800084c0 <states.0+0x148>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	42a080e7          	jalr	1066(ra) # 8000052a <panic>

0000000080003108 <fetchaddr>:
{
    80003108:	1101                	addi	sp,sp,-32
    8000310a:	ec06                	sd	ra,24(sp)
    8000310c:	e822                	sd	s0,16(sp)
    8000310e:	e426                	sd	s1,8(sp)
    80003110:	e04a                	sd	s2,0(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
    80003116:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	ef2080e7          	jalr	-270(ra) # 8000200a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003120:	653c                	ld	a5,72(a0)
    80003122:	02f4f863          	bgeu	s1,a5,80003152 <fetchaddr+0x4a>
    80003126:	00848713          	addi	a4,s1,8
    8000312a:	02e7e663          	bltu	a5,a4,80003156 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000312e:	46a1                	li	a3,8
    80003130:	8626                	mv	a2,s1
    80003132:	85ca                	mv	a1,s2
    80003134:	6928                	ld	a0,80(a0)
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	554080e7          	jalr	1364(ra) # 8000168a <copyin>
    8000313e:	00a03533          	snez	a0,a0
    80003142:	40a00533          	neg	a0,a0
}
    80003146:	60e2                	ld	ra,24(sp)
    80003148:	6442                	ld	s0,16(sp)
    8000314a:	64a2                	ld	s1,8(sp)
    8000314c:	6902                	ld	s2,0(sp)
    8000314e:	6105                	addi	sp,sp,32
    80003150:	8082                	ret
    return -1;
    80003152:	557d                	li	a0,-1
    80003154:	bfcd                	j	80003146 <fetchaddr+0x3e>
    80003156:	557d                	li	a0,-1
    80003158:	b7fd                	j	80003146 <fetchaddr+0x3e>

000000008000315a <fetchstr>:
{
    8000315a:	7179                	addi	sp,sp,-48
    8000315c:	f406                	sd	ra,40(sp)
    8000315e:	f022                	sd	s0,32(sp)
    80003160:	ec26                	sd	s1,24(sp)
    80003162:	e84a                	sd	s2,16(sp)
    80003164:	e44e                	sd	s3,8(sp)
    80003166:	1800                	addi	s0,sp,48
    80003168:	892a                	mv	s2,a0
    8000316a:	84ae                	mv	s1,a1
    8000316c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000316e:	fffff097          	auipc	ra,0xfffff
    80003172:	e9c080e7          	jalr	-356(ra) # 8000200a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003176:	86ce                	mv	a3,s3
    80003178:	864a                	mv	a2,s2
    8000317a:	85a6                	mv	a1,s1
    8000317c:	6928                	ld	a0,80(a0)
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	59a080e7          	jalr	1434(ra) # 80001718 <copyinstr>
  if(err < 0)
    80003186:	00054763          	bltz	a0,80003194 <fetchstr+0x3a>
  return strlen(buf);
    8000318a:	8526                	mv	a0,s1
    8000318c:	ffffe097          	auipc	ra,0xffffe
    80003190:	cc6080e7          	jalr	-826(ra) # 80000e52 <strlen>
}
    80003194:	70a2                	ld	ra,40(sp)
    80003196:	7402                	ld	s0,32(sp)
    80003198:	64e2                	ld	s1,24(sp)
    8000319a:	6942                	ld	s2,16(sp)
    8000319c:	69a2                	ld	s3,8(sp)
    8000319e:	6145                	addi	sp,sp,48
    800031a0:	8082                	ret

00000000800031a2 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800031a2:	1101                	addi	sp,sp,-32
    800031a4:	ec06                	sd	ra,24(sp)
    800031a6:	e822                	sd	s0,16(sp)
    800031a8:	e426                	sd	s1,8(sp)
    800031aa:	1000                	addi	s0,sp,32
    800031ac:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	ef2080e7          	jalr	-270(ra) # 800030a0 <argraw>
    800031b6:	c088                	sw	a0,0(s1)
  return 0;
}
    800031b8:	4501                	li	a0,0
    800031ba:	60e2                	ld	ra,24(sp)
    800031bc:	6442                	ld	s0,16(sp)
    800031be:	64a2                	ld	s1,8(sp)
    800031c0:	6105                	addi	sp,sp,32
    800031c2:	8082                	ret

00000000800031c4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800031c4:	1101                	addi	sp,sp,-32
    800031c6:	ec06                	sd	ra,24(sp)
    800031c8:	e822                	sd	s0,16(sp)
    800031ca:	e426                	sd	s1,8(sp)
    800031cc:	1000                	addi	s0,sp,32
    800031ce:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800031d0:	00000097          	auipc	ra,0x0
    800031d4:	ed0080e7          	jalr	-304(ra) # 800030a0 <argraw>
    800031d8:	e088                	sd	a0,0(s1)
  return 0;
}
    800031da:	4501                	li	a0,0
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	e04a                	sd	s2,0(sp)
    800031f0:	1000                	addi	s0,sp,32
    800031f2:	84ae                	mv	s1,a1
    800031f4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031f6:	00000097          	auipc	ra,0x0
    800031fa:	eaa080e7          	jalr	-342(ra) # 800030a0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031fe:	864a                	mv	a2,s2
    80003200:	85a6                	mv	a1,s1
    80003202:	00000097          	auipc	ra,0x0
    80003206:	f58080e7          	jalr	-168(ra) # 8000315a <fetchstr>
}
    8000320a:	60e2                	ld	ra,24(sp)
    8000320c:	6442                	ld	s0,16(sp)
    8000320e:	64a2                	ld	s1,8(sp)
    80003210:	6902                	ld	s2,0(sp)
    80003212:	6105                	addi	sp,sp,32
    80003214:	8082                	ret

0000000080003216 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80003216:	1101                	addi	sp,sp,-32
    80003218:	ec06                	sd	ra,24(sp)
    8000321a:	e822                	sd	s0,16(sp)
    8000321c:	e426                	sd	s1,8(sp)
    8000321e:	e04a                	sd	s2,0(sp)
    80003220:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003222:	fffff097          	auipc	ra,0xfffff
    80003226:	de8080e7          	jalr	-536(ra) # 8000200a <myproc>
    8000322a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000322c:	05853903          	ld	s2,88(a0)
    80003230:	0a893783          	ld	a5,168(s2)
    80003234:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003238:	37fd                	addiw	a5,a5,-1
    8000323a:	4751                	li	a4,20
    8000323c:	00f76f63          	bltu	a4,a5,8000325a <syscall+0x44>
    80003240:	00369713          	slli	a4,a3,0x3
    80003244:	00005797          	auipc	a5,0x5
    80003248:	2bc78793          	addi	a5,a5,700 # 80008500 <syscalls>
    8000324c:	97ba                	add	a5,a5,a4
    8000324e:	639c                	ld	a5,0(a5)
    80003250:	c789                	beqz	a5,8000325a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003252:	9782                	jalr	a5
    80003254:	06a93823          	sd	a0,112(s2)
    80003258:	a839                	j	80003276 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000325a:	15848613          	addi	a2,s1,344
    8000325e:	588c                	lw	a1,48(s1)
    80003260:	00005517          	auipc	a0,0x5
    80003264:	26850513          	addi	a0,a0,616 # 800084c8 <states.0+0x150>
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	30c080e7          	jalr	780(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003270:	6cbc                	ld	a5,88(s1)
    80003272:	577d                	li	a4,-1
    80003274:	fbb8                	sd	a4,112(a5)
  }
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6902                	ld	s2,0(sp)
    8000327e:	6105                	addi	sp,sp,32
    80003280:	8082                	ret

0000000080003282 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000328a:	fec40593          	addi	a1,s0,-20
    8000328e:	4501                	li	a0,0
    80003290:	00000097          	auipc	ra,0x0
    80003294:	f12080e7          	jalr	-238(ra) # 800031a2 <argint>
    return -1;
    80003298:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000329a:	00054963          	bltz	a0,800032ac <sys_exit+0x2a>
  exit(n);
    8000329e:	fec42503          	lw	a0,-20(s0)
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	736080e7          	jalr	1846(ra) # 800029d8 <exit>
  return 0;  // not reached
    800032aa:	4781                	li	a5,0
}
    800032ac:	853e                	mv	a0,a5
    800032ae:	60e2                	ld	ra,24(sp)
    800032b0:	6442                	ld	s0,16(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <sys_getpid>:

uint64
sys_getpid(void)
{
    800032b6:	1141                	addi	sp,sp,-16
    800032b8:	e406                	sd	ra,8(sp)
    800032ba:	e022                	sd	s0,0(sp)
    800032bc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800032be:	fffff097          	auipc	ra,0xfffff
    800032c2:	d4c080e7          	jalr	-692(ra) # 8000200a <myproc>
}
    800032c6:	5908                	lw	a0,48(a0)
    800032c8:	60a2                	ld	ra,8(sp)
    800032ca:	6402                	ld	s0,0(sp)
    800032cc:	0141                	addi	sp,sp,16
    800032ce:	8082                	ret

00000000800032d0 <sys_fork>:

uint64
sys_fork(void)
{
    800032d0:	1141                	addi	sp,sp,-16
    800032d2:	e406                	sd	ra,8(sp)
    800032d4:	e022                	sd	s0,0(sp)
    800032d6:	0800                	addi	s0,sp,16
  return fork();
    800032d8:	fffff097          	auipc	ra,0xfffff
    800032dc:	1aa080e7          	jalr	426(ra) # 80002482 <fork>
}
    800032e0:	60a2                	ld	ra,8(sp)
    800032e2:	6402                	ld	s0,0(sp)
    800032e4:	0141                	addi	sp,sp,16
    800032e6:	8082                	ret

00000000800032e8 <sys_wait>:

uint64
sys_wait(void)
{
    800032e8:	1101                	addi	sp,sp,-32
    800032ea:	ec06                	sd	ra,24(sp)
    800032ec:	e822                	sd	s0,16(sp)
    800032ee:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032f0:	fe840593          	addi	a1,s0,-24
    800032f4:	4501                	li	a0,0
    800032f6:	00000097          	auipc	ra,0x0
    800032fa:	ece080e7          	jalr	-306(ra) # 800031c4 <argaddr>
    800032fe:	87aa                	mv	a5,a0
    return -1;
    80003300:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003302:	0007c863          	bltz	a5,80003312 <sys_wait+0x2a>
  return wait(p);
    80003306:	fe843503          	ld	a0,-24(s0)
    8000330a:	fffff097          	auipc	ra,0xfffff
    8000330e:	4d6080e7          	jalr	1238(ra) # 800027e0 <wait>
}
    80003312:	60e2                	ld	ra,24(sp)
    80003314:	6442                	ld	s0,16(sp)
    80003316:	6105                	addi	sp,sp,32
    80003318:	8082                	ret

000000008000331a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000331a:	7179                	addi	sp,sp,-48
    8000331c:	f406                	sd	ra,40(sp)
    8000331e:	f022                	sd	s0,32(sp)
    80003320:	ec26                	sd	s1,24(sp)
    80003322:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003324:	fdc40593          	addi	a1,s0,-36
    80003328:	4501                	li	a0,0
    8000332a:	00000097          	auipc	ra,0x0
    8000332e:	e78080e7          	jalr	-392(ra) # 800031a2 <argint>
    return -1;
    80003332:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80003334:	00054f63          	bltz	a0,80003352 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003338:	fffff097          	auipc	ra,0xfffff
    8000333c:	cd2080e7          	jalr	-814(ra) # 8000200a <myproc>
    80003340:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003342:	fdc42503          	lw	a0,-36(s0)
    80003346:	fffff097          	auipc	ra,0xfffff
    8000334a:	01e080e7          	jalr	30(ra) # 80002364 <growproc>
    8000334e:	00054863          	bltz	a0,8000335e <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003352:	8526                	mv	a0,s1
    80003354:	70a2                	ld	ra,40(sp)
    80003356:	7402                	ld	s0,32(sp)
    80003358:	64e2                	ld	s1,24(sp)
    8000335a:	6145                	addi	sp,sp,48
    8000335c:	8082                	ret
    return -1;
    8000335e:	54fd                	li	s1,-1
    80003360:	bfcd                	j	80003352 <sys_sbrk+0x38>

0000000080003362 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003362:	7139                	addi	sp,sp,-64
    80003364:	fc06                	sd	ra,56(sp)
    80003366:	f822                	sd	s0,48(sp)
    80003368:	f426                	sd	s1,40(sp)
    8000336a:	f04a                	sd	s2,32(sp)
    8000336c:	ec4e                	sd	s3,24(sp)
    8000336e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003370:	fcc40593          	addi	a1,s0,-52
    80003374:	4501                	li	a0,0
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	e2c080e7          	jalr	-468(ra) # 800031a2 <argint>
    return -1;
    8000337e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003380:	06054563          	bltz	a0,800033ea <sys_sleep+0x88>
  acquire(&tickslock);
    80003384:	0001c517          	auipc	a0,0x1c
    80003388:	34c50513          	addi	a0,a0,844 # 8001f6d0 <tickslock>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	846080e7          	jalr	-1978(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    80003394:	00006917          	auipc	s2,0x6
    80003398:	c9c92903          	lw	s2,-868(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    8000339c:	fcc42783          	lw	a5,-52(s0)
    800033a0:	cf85                	beqz	a5,800033d8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800033a2:	0001c997          	auipc	s3,0x1c
    800033a6:	32e98993          	addi	s3,s3,814 # 8001f6d0 <tickslock>
    800033aa:	00006497          	auipc	s1,0x6
    800033ae:	c8648493          	addi	s1,s1,-890 # 80009030 <ticks>
    if(myproc()->killed){
    800033b2:	fffff097          	auipc	ra,0xfffff
    800033b6:	c58080e7          	jalr	-936(ra) # 8000200a <myproc>
    800033ba:	551c                	lw	a5,40(a0)
    800033bc:	ef9d                	bnez	a5,800033fa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800033be:	85ce                	mv	a1,s3
    800033c0:	8526                	mv	a0,s1
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	3ba080e7          	jalr	954(ra) # 8000277c <sleep>
  while(ticks - ticks0 < n){
    800033ca:	409c                	lw	a5,0(s1)
    800033cc:	412787bb          	subw	a5,a5,s2
    800033d0:	fcc42703          	lw	a4,-52(s0)
    800033d4:	fce7efe3          	bltu	a5,a4,800033b2 <sys_sleep+0x50>
  }
  release(&tickslock);
    800033d8:	0001c517          	auipc	a0,0x1c
    800033dc:	2f850513          	addi	a0,a0,760 # 8001f6d0 <tickslock>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8a6080e7          	jalr	-1882(ra) # 80000c86 <release>
  return 0;
    800033e8:	4781                	li	a5,0
}
    800033ea:	853e                	mv	a0,a5
    800033ec:	70e2                	ld	ra,56(sp)
    800033ee:	7442                	ld	s0,48(sp)
    800033f0:	74a2                	ld	s1,40(sp)
    800033f2:	7902                	ld	s2,32(sp)
    800033f4:	69e2                	ld	s3,24(sp)
    800033f6:	6121                	addi	sp,sp,64
    800033f8:	8082                	ret
      release(&tickslock);
    800033fa:	0001c517          	auipc	a0,0x1c
    800033fe:	2d650513          	addi	a0,a0,726 # 8001f6d0 <tickslock>
    80003402:	ffffe097          	auipc	ra,0xffffe
    80003406:	884080e7          	jalr	-1916(ra) # 80000c86 <release>
      return -1;
    8000340a:	57fd                	li	a5,-1
    8000340c:	bff9                	j	800033ea <sys_sleep+0x88>

000000008000340e <sys_kill>:

uint64
sys_kill(void)
{
    8000340e:	1101                	addi	sp,sp,-32
    80003410:	ec06                	sd	ra,24(sp)
    80003412:	e822                	sd	s0,16(sp)
    80003414:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003416:	fec40593          	addi	a1,s0,-20
    8000341a:	4501                	li	a0,0
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	d86080e7          	jalr	-634(ra) # 800031a2 <argint>
    80003424:	87aa                	mv	a5,a0
    return -1;
    80003426:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003428:	0007c863          	bltz	a5,80003438 <sys_kill+0x2a>
  return kill(pid);
    8000342c:	fec42503          	lw	a0,-20(s0)
    80003430:	fffff097          	auipc	ra,0xfffff
    80003434:	694080e7          	jalr	1684(ra) # 80002ac4 <kill>
}
    80003438:	60e2                	ld	ra,24(sp)
    8000343a:	6442                	ld	s0,16(sp)
    8000343c:	6105                	addi	sp,sp,32
    8000343e:	8082                	ret

0000000080003440 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	e426                	sd	s1,8(sp)
    80003448:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000344a:	0001c517          	auipc	a0,0x1c
    8000344e:	28650513          	addi	a0,a0,646 # 8001f6d0 <tickslock>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	780080e7          	jalr	1920(ra) # 80000bd2 <acquire>
  xticks = ticks;
    8000345a:	00006497          	auipc	s1,0x6
    8000345e:	bd64a483          	lw	s1,-1066(s1) # 80009030 <ticks>
  release(&tickslock);
    80003462:	0001c517          	auipc	a0,0x1c
    80003466:	26e50513          	addi	a0,a0,622 # 8001f6d0 <tickslock>
    8000346a:	ffffe097          	auipc	ra,0xffffe
    8000346e:	81c080e7          	jalr	-2020(ra) # 80000c86 <release>
  return xticks;
}
    80003472:	02049513          	slli	a0,s1,0x20
    80003476:	9101                	srli	a0,a0,0x20
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003482:	7179                	addi	sp,sp,-48
    80003484:	f406                	sd	ra,40(sp)
    80003486:	f022                	sd	s0,32(sp)
    80003488:	ec26                	sd	s1,24(sp)
    8000348a:	e84a                	sd	s2,16(sp)
    8000348c:	e44e                	sd	s3,8(sp)
    8000348e:	e052                	sd	s4,0(sp)
    80003490:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003492:	00005597          	auipc	a1,0x5
    80003496:	11e58593          	addi	a1,a1,286 # 800085b0 <syscalls+0xb0>
    8000349a:	0001c517          	auipc	a0,0x1c
    8000349e:	24e50513          	addi	a0,a0,590 # 8001f6e8 <bcache>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	6a0080e7          	jalr	1696(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034aa:	00024797          	auipc	a5,0x24
    800034ae:	23e78793          	addi	a5,a5,574 # 800276e8 <bcache+0x8000>
    800034b2:	00024717          	auipc	a4,0x24
    800034b6:	49e70713          	addi	a4,a4,1182 # 80027950 <bcache+0x8268>
    800034ba:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034be:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c2:	0001c497          	auipc	s1,0x1c
    800034c6:	23e48493          	addi	s1,s1,574 # 8001f700 <bcache+0x18>
    b->next = bcache.head.next;
    800034ca:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034cc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034ce:	00005a17          	auipc	s4,0x5
    800034d2:	0eaa0a13          	addi	s4,s4,234 # 800085b8 <syscalls+0xb8>
    b->next = bcache.head.next;
    800034d6:	2b893783          	ld	a5,696(s2)
    800034da:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034dc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034e0:	85d2                	mv	a1,s4
    800034e2:	01048513          	addi	a0,s1,16
    800034e6:	00001097          	auipc	ra,0x1
    800034ea:	7d4080e7          	jalr	2004(ra) # 80004cba <initsleeplock>
    bcache.head.next->prev = b;
    800034ee:	2b893783          	ld	a5,696(s2)
    800034f2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034f4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f8:	45848493          	addi	s1,s1,1112
    800034fc:	fd349de3          	bne	s1,s3,800034d6 <binit+0x54>
  }
}
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6a02                	ld	s4,0(sp)
    8000350c:	6145                	addi	sp,sp,48
    8000350e:	8082                	ret

0000000080003510 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003510:	7179                	addi	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	1800                	addi	s0,sp,48
    8000351e:	892a                	mv	s2,a0
    80003520:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003522:	0001c517          	auipc	a0,0x1c
    80003526:	1c650513          	addi	a0,a0,454 # 8001f6e8 <bcache>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	6a8080e7          	jalr	1704(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003532:	00024497          	auipc	s1,0x24
    80003536:	46e4b483          	ld	s1,1134(s1) # 800279a0 <bcache+0x82b8>
    8000353a:	00024797          	auipc	a5,0x24
    8000353e:	41678793          	addi	a5,a5,1046 # 80027950 <bcache+0x8268>
    80003542:	02f48f63          	beq	s1,a5,80003580 <bread+0x70>
    80003546:	873e                	mv	a4,a5
    80003548:	a021                	j	80003550 <bread+0x40>
    8000354a:	68a4                	ld	s1,80(s1)
    8000354c:	02e48a63          	beq	s1,a4,80003580 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003550:	449c                	lw	a5,8(s1)
    80003552:	ff279ce3          	bne	a5,s2,8000354a <bread+0x3a>
    80003556:	44dc                	lw	a5,12(s1)
    80003558:	ff3799e3          	bne	a5,s3,8000354a <bread+0x3a>
      b->refcnt++;
    8000355c:	40bc                	lw	a5,64(s1)
    8000355e:	2785                	addiw	a5,a5,1
    80003560:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003562:	0001c517          	auipc	a0,0x1c
    80003566:	18650513          	addi	a0,a0,390 # 8001f6e8 <bcache>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	71c080e7          	jalr	1820(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003572:	01048513          	addi	a0,s1,16
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	77e080e7          	jalr	1918(ra) # 80004cf4 <acquiresleep>
      return b;
    8000357e:	a8b9                	j	800035dc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003580:	00024497          	auipc	s1,0x24
    80003584:	4184b483          	ld	s1,1048(s1) # 80027998 <bcache+0x82b0>
    80003588:	00024797          	auipc	a5,0x24
    8000358c:	3c878793          	addi	a5,a5,968 # 80027950 <bcache+0x8268>
    80003590:	00f48863          	beq	s1,a5,800035a0 <bread+0x90>
    80003594:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003596:	40bc                	lw	a5,64(s1)
    80003598:	cf81                	beqz	a5,800035b0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000359a:	64a4                	ld	s1,72(s1)
    8000359c:	fee49de3          	bne	s1,a4,80003596 <bread+0x86>
  panic("bget: no buffers");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	02050513          	addi	a0,a0,32 # 800085c0 <syscalls+0xc0>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f82080e7          	jalr	-126(ra) # 8000052a <panic>
      b->dev = dev;
    800035b0:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800035b4:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800035b8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035bc:	4785                	li	a5,1
    800035be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035c0:	0001c517          	auipc	a0,0x1c
    800035c4:	12850513          	addi	a0,a0,296 # 8001f6e8 <bcache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	6be080e7          	jalr	1726(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    800035d0:	01048513          	addi	a0,s1,16
    800035d4:	00001097          	auipc	ra,0x1
    800035d8:	720080e7          	jalr	1824(ra) # 80004cf4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035dc:	409c                	lw	a5,0(s1)
    800035de:	cb89                	beqz	a5,800035f0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035e0:	8526                	mv	a0,s1
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6145                	addi	sp,sp,48
    800035ee:	8082                	ret
    virtio_disk_rw(b, 0);
    800035f0:	4581                	li	a1,0
    800035f2:	8526                	mv	a0,s1
    800035f4:	00003097          	auipc	ra,0x3
    800035f8:	452080e7          	jalr	1106(ra) # 80006a46 <virtio_disk_rw>
    b->valid = 1;
    800035fc:	4785                	li	a5,1
    800035fe:	c09c                	sw	a5,0(s1)
  return b;
    80003600:	b7c5                	j	800035e0 <bread+0xd0>

0000000080003602 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003602:	1101                	addi	sp,sp,-32
    80003604:	ec06                	sd	ra,24(sp)
    80003606:	e822                	sd	s0,16(sp)
    80003608:	e426                	sd	s1,8(sp)
    8000360a:	1000                	addi	s0,sp,32
    8000360c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000360e:	0541                	addi	a0,a0,16
    80003610:	00001097          	auipc	ra,0x1
    80003614:	77e080e7          	jalr	1918(ra) # 80004d8e <holdingsleep>
    80003618:	cd01                	beqz	a0,80003630 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000361a:	4585                	li	a1,1
    8000361c:	8526                	mv	a0,s1
    8000361e:	00003097          	auipc	ra,0x3
    80003622:	428080e7          	jalr	1064(ra) # 80006a46 <virtio_disk_rw>
}
    80003626:	60e2                	ld	ra,24(sp)
    80003628:	6442                	ld	s0,16(sp)
    8000362a:	64a2                	ld	s1,8(sp)
    8000362c:	6105                	addi	sp,sp,32
    8000362e:	8082                	ret
    panic("bwrite");
    80003630:	00005517          	auipc	a0,0x5
    80003634:	fa850513          	addi	a0,a0,-88 # 800085d8 <syscalls+0xd8>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	ef2080e7          	jalr	-270(ra) # 8000052a <panic>

0000000080003640 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003640:	1101                	addi	sp,sp,-32
    80003642:	ec06                	sd	ra,24(sp)
    80003644:	e822                	sd	s0,16(sp)
    80003646:	e426                	sd	s1,8(sp)
    80003648:	e04a                	sd	s2,0(sp)
    8000364a:	1000                	addi	s0,sp,32
    8000364c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000364e:	01050913          	addi	s2,a0,16
    80003652:	854a                	mv	a0,s2
    80003654:	00001097          	auipc	ra,0x1
    80003658:	73a080e7          	jalr	1850(ra) # 80004d8e <holdingsleep>
    8000365c:	c92d                	beqz	a0,800036ce <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000365e:	854a                	mv	a0,s2
    80003660:	00001097          	auipc	ra,0x1
    80003664:	6ea080e7          	jalr	1770(ra) # 80004d4a <releasesleep>

  acquire(&bcache.lock);
    80003668:	0001c517          	auipc	a0,0x1c
    8000366c:	08050513          	addi	a0,a0,128 # 8001f6e8 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	562080e7          	jalr	1378(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003678:	40bc                	lw	a5,64(s1)
    8000367a:	37fd                	addiw	a5,a5,-1
    8000367c:	0007871b          	sext.w	a4,a5
    80003680:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003682:	eb05                	bnez	a4,800036b2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003684:	68bc                	ld	a5,80(s1)
    80003686:	64b8                	ld	a4,72(s1)
    80003688:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000368a:	64bc                	ld	a5,72(s1)
    8000368c:	68b8                	ld	a4,80(s1)
    8000368e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003690:	00024797          	auipc	a5,0x24
    80003694:	05878793          	addi	a5,a5,88 # 800276e8 <bcache+0x8000>
    80003698:	2b87b703          	ld	a4,696(a5)
    8000369c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000369e:	00024717          	auipc	a4,0x24
    800036a2:	2b270713          	addi	a4,a4,690 # 80027950 <bcache+0x8268>
    800036a6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a8:	2b87b703          	ld	a4,696(a5)
    800036ac:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036ae:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036b2:	0001c517          	auipc	a0,0x1c
    800036b6:	03650513          	addi	a0,a0,54 # 8001f6e8 <bcache>
    800036ba:	ffffd097          	auipc	ra,0xffffd
    800036be:	5cc080e7          	jalr	1484(ra) # 80000c86 <release>
}
    800036c2:	60e2                	ld	ra,24(sp)
    800036c4:	6442                	ld	s0,16(sp)
    800036c6:	64a2                	ld	s1,8(sp)
    800036c8:	6902                	ld	s2,0(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret
    panic("brelse");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	f1250513          	addi	a0,a0,-238 # 800085e0 <syscalls+0xe0>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e54080e7          	jalr	-428(ra) # 8000052a <panic>

00000000800036de <bpin>:

void
bpin(struct buf *b) {
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	1000                	addi	s0,sp,32
    800036e8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036ea:	0001c517          	auipc	a0,0x1c
    800036ee:	ffe50513          	addi	a0,a0,-2 # 8001f6e8 <bcache>
    800036f2:	ffffd097          	auipc	ra,0xffffd
    800036f6:	4e0080e7          	jalr	1248(ra) # 80000bd2 <acquire>
  b->refcnt++;
    800036fa:	40bc                	lw	a5,64(s1)
    800036fc:	2785                	addiw	a5,a5,1
    800036fe:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003700:	0001c517          	auipc	a0,0x1c
    80003704:	fe850513          	addi	a0,a0,-24 # 8001f6e8 <bcache>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	57e080e7          	jalr	1406(ra) # 80000c86 <release>
}
    80003710:	60e2                	ld	ra,24(sp)
    80003712:	6442                	ld	s0,16(sp)
    80003714:	64a2                	ld	s1,8(sp)
    80003716:	6105                	addi	sp,sp,32
    80003718:	8082                	ret

000000008000371a <bunpin>:

void
bunpin(struct buf *b) {
    8000371a:	1101                	addi	sp,sp,-32
    8000371c:	ec06                	sd	ra,24(sp)
    8000371e:	e822                	sd	s0,16(sp)
    80003720:	e426                	sd	s1,8(sp)
    80003722:	1000                	addi	s0,sp,32
    80003724:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003726:	0001c517          	auipc	a0,0x1c
    8000372a:	fc250513          	addi	a0,a0,-62 # 8001f6e8 <bcache>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	4a4080e7          	jalr	1188(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003736:	40bc                	lw	a5,64(s1)
    80003738:	37fd                	addiw	a5,a5,-1
    8000373a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000373c:	0001c517          	auipc	a0,0x1c
    80003740:	fac50513          	addi	a0,a0,-84 # 8001f6e8 <bcache>
    80003744:	ffffd097          	auipc	ra,0xffffd
    80003748:	542080e7          	jalr	1346(ra) # 80000c86 <release>
}
    8000374c:	60e2                	ld	ra,24(sp)
    8000374e:	6442                	ld	s0,16(sp)
    80003750:	64a2                	ld	s1,8(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	e04a                	sd	s2,0(sp)
    80003760:	1000                	addi	s0,sp,32
    80003762:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003764:	00d5d59b          	srliw	a1,a1,0xd
    80003768:	00024797          	auipc	a5,0x24
    8000376c:	65c7a783          	lw	a5,1628(a5) # 80027dc4 <sb+0x1c>
    80003770:	9dbd                	addw	a1,a1,a5
    80003772:	00000097          	auipc	ra,0x0
    80003776:	d9e080e7          	jalr	-610(ra) # 80003510 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000377a:	0074f713          	andi	a4,s1,7
    8000377e:	4785                	li	a5,1
    80003780:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003784:	14ce                	slli	s1,s1,0x33
    80003786:	90d9                	srli	s1,s1,0x36
    80003788:	00950733          	add	a4,a0,s1
    8000378c:	05874703          	lbu	a4,88(a4)
    80003790:	00e7f6b3          	and	a3,a5,a4
    80003794:	c69d                	beqz	a3,800037c2 <bfree+0x6c>
    80003796:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003798:	94aa                	add	s1,s1,a0
    8000379a:	fff7c793          	not	a5,a5
    8000379e:	8ff9                	and	a5,a5,a4
    800037a0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037a4:	00001097          	auipc	ra,0x1
    800037a8:	430080e7          	jalr	1072(ra) # 80004bd4 <log_write>
  brelse(bp);
    800037ac:	854a                	mv	a0,s2
    800037ae:	00000097          	auipc	ra,0x0
    800037b2:	e92080e7          	jalr	-366(ra) # 80003640 <brelse>
}
    800037b6:	60e2                	ld	ra,24(sp)
    800037b8:	6442                	ld	s0,16(sp)
    800037ba:	64a2                	ld	s1,8(sp)
    800037bc:	6902                	ld	s2,0(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret
    panic("freeing free block");
    800037c2:	00005517          	auipc	a0,0x5
    800037c6:	e2650513          	addi	a0,a0,-474 # 800085e8 <syscalls+0xe8>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>

00000000800037d2 <balloc>:
{
    800037d2:	711d                	addi	sp,sp,-96
    800037d4:	ec86                	sd	ra,88(sp)
    800037d6:	e8a2                	sd	s0,80(sp)
    800037d8:	e4a6                	sd	s1,72(sp)
    800037da:	e0ca                	sd	s2,64(sp)
    800037dc:	fc4e                	sd	s3,56(sp)
    800037de:	f852                	sd	s4,48(sp)
    800037e0:	f456                	sd	s5,40(sp)
    800037e2:	f05a                	sd	s6,32(sp)
    800037e4:	ec5e                	sd	s7,24(sp)
    800037e6:	e862                	sd	s8,16(sp)
    800037e8:	e466                	sd	s9,8(sp)
    800037ea:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037ec:	00024797          	auipc	a5,0x24
    800037f0:	5c07a783          	lw	a5,1472(a5) # 80027dac <sb+0x4>
    800037f4:	cbd1                	beqz	a5,80003888 <balloc+0xb6>
    800037f6:	8baa                	mv	s7,a0
    800037f8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037fa:	00024b17          	auipc	s6,0x24
    800037fe:	5aeb0b13          	addi	s6,s6,1454 # 80027da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003802:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003804:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003806:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003808:	6c89                	lui	s9,0x2
    8000380a:	a831                	j	80003826 <balloc+0x54>
    brelse(bp);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	e32080e7          	jalr	-462(ra) # 80003640 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003816:	015c87bb          	addw	a5,s9,s5
    8000381a:	00078a9b          	sext.w	s5,a5
    8000381e:	004b2703          	lw	a4,4(s6)
    80003822:	06eaf363          	bgeu	s5,a4,80003888 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003826:	41fad79b          	sraiw	a5,s5,0x1f
    8000382a:	0137d79b          	srliw	a5,a5,0x13
    8000382e:	015787bb          	addw	a5,a5,s5
    80003832:	40d7d79b          	sraiw	a5,a5,0xd
    80003836:	01cb2583          	lw	a1,28(s6)
    8000383a:	9dbd                	addw	a1,a1,a5
    8000383c:	855e                	mv	a0,s7
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	cd2080e7          	jalr	-814(ra) # 80003510 <bread>
    80003846:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003848:	004b2503          	lw	a0,4(s6)
    8000384c:	000a849b          	sext.w	s1,s5
    80003850:	8662                	mv	a2,s8
    80003852:	faa4fde3          	bgeu	s1,a0,8000380c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003856:	41f6579b          	sraiw	a5,a2,0x1f
    8000385a:	01d7d69b          	srliw	a3,a5,0x1d
    8000385e:	00c6873b          	addw	a4,a3,a2
    80003862:	00777793          	andi	a5,a4,7
    80003866:	9f95                	subw	a5,a5,a3
    80003868:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000386c:	4037571b          	sraiw	a4,a4,0x3
    80003870:	00e906b3          	add	a3,s2,a4
    80003874:	0586c683          	lbu	a3,88(a3)
    80003878:	00d7f5b3          	and	a1,a5,a3
    8000387c:	cd91                	beqz	a1,80003898 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000387e:	2605                	addiw	a2,a2,1
    80003880:	2485                	addiw	s1,s1,1
    80003882:	fd4618e3          	bne	a2,s4,80003852 <balloc+0x80>
    80003886:	b759                	j	8000380c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003888:	00005517          	auipc	a0,0x5
    8000388c:	d7850513          	addi	a0,a0,-648 # 80008600 <syscalls+0x100>
    80003890:	ffffd097          	auipc	ra,0xffffd
    80003894:	c9a080e7          	jalr	-870(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003898:	974a                	add	a4,a4,s2
    8000389a:	8fd5                	or	a5,a5,a3
    8000389c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	332080e7          	jalr	818(ra) # 80004bd4 <log_write>
        brelse(bp);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	d94080e7          	jalr	-620(ra) # 80003640 <brelse>
  bp = bread(dev, bno);
    800038b4:	85a6                	mv	a1,s1
    800038b6:	855e                	mv	a0,s7
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	c58080e7          	jalr	-936(ra) # 80003510 <bread>
    800038c0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038c2:	40000613          	li	a2,1024
    800038c6:	4581                	li	a1,0
    800038c8:	05850513          	addi	a0,a0,88
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	402080e7          	jalr	1026(ra) # 80000cce <memset>
  log_write(bp);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	2fe080e7          	jalr	766(ra) # 80004bd4 <log_write>
  brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	d60080e7          	jalr	-672(ra) # 80003640 <brelse>
}
    800038e8:	8526                	mv	a0,s1
    800038ea:	60e6                	ld	ra,88(sp)
    800038ec:	6446                	ld	s0,80(sp)
    800038ee:	64a6                	ld	s1,72(sp)
    800038f0:	6906                	ld	s2,64(sp)
    800038f2:	79e2                	ld	s3,56(sp)
    800038f4:	7a42                	ld	s4,48(sp)
    800038f6:	7aa2                	ld	s5,40(sp)
    800038f8:	7b02                	ld	s6,32(sp)
    800038fa:	6be2                	ld	s7,24(sp)
    800038fc:	6c42                	ld	s8,16(sp)
    800038fe:	6ca2                	ld	s9,8(sp)
    80003900:	6125                	addi	sp,sp,96
    80003902:	8082                	ret

0000000080003904 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003904:	7179                	addi	sp,sp,-48
    80003906:	f406                	sd	ra,40(sp)
    80003908:	f022                	sd	s0,32(sp)
    8000390a:	ec26                	sd	s1,24(sp)
    8000390c:	e84a                	sd	s2,16(sp)
    8000390e:	e44e                	sd	s3,8(sp)
    80003910:	e052                	sd	s4,0(sp)
    80003912:	1800                	addi	s0,sp,48
    80003914:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003916:	47ad                	li	a5,11
    80003918:	04b7fe63          	bgeu	a5,a1,80003974 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000391c:	ff45849b          	addiw	s1,a1,-12
    80003920:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003924:	0ff00793          	li	a5,255
    80003928:	0ae7e463          	bltu	a5,a4,800039d0 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000392c:	08052583          	lw	a1,128(a0)
    80003930:	c5b5                	beqz	a1,8000399c <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003932:	00092503          	lw	a0,0(s2)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	bda080e7          	jalr	-1062(ra) # 80003510 <bread>
    8000393e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003940:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003944:	02049713          	slli	a4,s1,0x20
    80003948:	01e75593          	srli	a1,a4,0x1e
    8000394c:	00b784b3          	add	s1,a5,a1
    80003950:	0004a983          	lw	s3,0(s1)
    80003954:	04098e63          	beqz	s3,800039b0 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003958:	8552                	mv	a0,s4
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	ce6080e7          	jalr	-794(ra) # 80003640 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003962:	854e                	mv	a0,s3
    80003964:	70a2                	ld	ra,40(sp)
    80003966:	7402                	ld	s0,32(sp)
    80003968:	64e2                	ld	s1,24(sp)
    8000396a:	6942                	ld	s2,16(sp)
    8000396c:	69a2                	ld	s3,8(sp)
    8000396e:	6a02                	ld	s4,0(sp)
    80003970:	6145                	addi	sp,sp,48
    80003972:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003974:	02059793          	slli	a5,a1,0x20
    80003978:	01e7d593          	srli	a1,a5,0x1e
    8000397c:	00b504b3          	add	s1,a0,a1
    80003980:	0504a983          	lw	s3,80(s1)
    80003984:	fc099fe3          	bnez	s3,80003962 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003988:	4108                	lw	a0,0(a0)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	e48080e7          	jalr	-440(ra) # 800037d2 <balloc>
    80003992:	0005099b          	sext.w	s3,a0
    80003996:	0534a823          	sw	s3,80(s1)
    8000399a:	b7e1                	j	80003962 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000399c:	4108                	lw	a0,0(a0)
    8000399e:	00000097          	auipc	ra,0x0
    800039a2:	e34080e7          	jalr	-460(ra) # 800037d2 <balloc>
    800039a6:	0005059b          	sext.w	a1,a0
    800039aa:	08b92023          	sw	a1,128(s2)
    800039ae:	b751                	j	80003932 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039b0:	00092503          	lw	a0,0(s2)
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	e1e080e7          	jalr	-482(ra) # 800037d2 <balloc>
    800039bc:	0005099b          	sext.w	s3,a0
    800039c0:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039c4:	8552                	mv	a0,s4
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	20e080e7          	jalr	526(ra) # 80004bd4 <log_write>
    800039ce:	b769                	j	80003958 <bmap+0x54>
  panic("bmap: out of range");
    800039d0:	00005517          	auipc	a0,0x5
    800039d4:	c4850513          	addi	a0,a0,-952 # 80008618 <syscalls+0x118>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	b52080e7          	jalr	-1198(ra) # 8000052a <panic>

00000000800039e0 <iget>:
{
    800039e0:	7179                	addi	sp,sp,-48
    800039e2:	f406                	sd	ra,40(sp)
    800039e4:	f022                	sd	s0,32(sp)
    800039e6:	ec26                	sd	s1,24(sp)
    800039e8:	e84a                	sd	s2,16(sp)
    800039ea:	e44e                	sd	s3,8(sp)
    800039ec:	e052                	sd	s4,0(sp)
    800039ee:	1800                	addi	s0,sp,48
    800039f0:	89aa                	mv	s3,a0
    800039f2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039f4:	00024517          	auipc	a0,0x24
    800039f8:	3d450513          	addi	a0,a0,980 # 80027dc8 <itable>
    800039fc:	ffffd097          	auipc	ra,0xffffd
    80003a00:	1d6080e7          	jalr	470(ra) # 80000bd2 <acquire>
  empty = 0;
    80003a04:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a06:	00024497          	auipc	s1,0x24
    80003a0a:	3da48493          	addi	s1,s1,986 # 80027de0 <itable+0x18>
    80003a0e:	00026697          	auipc	a3,0x26
    80003a12:	e6268693          	addi	a3,a3,-414 # 80029870 <log>
    80003a16:	a039                	j	80003a24 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a18:	02090b63          	beqz	s2,80003a4e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a1c:	08848493          	addi	s1,s1,136
    80003a20:	02d48a63          	beq	s1,a3,80003a54 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a24:	449c                	lw	a5,8(s1)
    80003a26:	fef059e3          	blez	a5,80003a18 <iget+0x38>
    80003a2a:	4098                	lw	a4,0(s1)
    80003a2c:	ff3716e3          	bne	a4,s3,80003a18 <iget+0x38>
    80003a30:	40d8                	lw	a4,4(s1)
    80003a32:	ff4713e3          	bne	a4,s4,80003a18 <iget+0x38>
      ip->ref++;
    80003a36:	2785                	addiw	a5,a5,1
    80003a38:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a3a:	00024517          	auipc	a0,0x24
    80003a3e:	38e50513          	addi	a0,a0,910 # 80027dc8 <itable>
    80003a42:	ffffd097          	auipc	ra,0xffffd
    80003a46:	244080e7          	jalr	580(ra) # 80000c86 <release>
      return ip;
    80003a4a:	8926                	mv	s2,s1
    80003a4c:	a03d                	j	80003a7a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a4e:	f7f9                	bnez	a5,80003a1c <iget+0x3c>
    80003a50:	8926                	mv	s2,s1
    80003a52:	b7e9                	j	80003a1c <iget+0x3c>
  if(empty == 0)
    80003a54:	02090c63          	beqz	s2,80003a8c <iget+0xac>
  ip->dev = dev;
    80003a58:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a5c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a60:	4785                	li	a5,1
    80003a62:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a66:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a6a:	00024517          	auipc	a0,0x24
    80003a6e:	35e50513          	addi	a0,a0,862 # 80027dc8 <itable>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	214080e7          	jalr	532(ra) # 80000c86 <release>
}
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	70a2                	ld	ra,40(sp)
    80003a7e:	7402                	ld	s0,32(sp)
    80003a80:	64e2                	ld	s1,24(sp)
    80003a82:	6942                	ld	s2,16(sp)
    80003a84:	69a2                	ld	s3,8(sp)
    80003a86:	6a02                	ld	s4,0(sp)
    80003a88:	6145                	addi	sp,sp,48
    80003a8a:	8082                	ret
    panic("iget: no inodes");
    80003a8c:	00005517          	auipc	a0,0x5
    80003a90:	ba450513          	addi	a0,a0,-1116 # 80008630 <syscalls+0x130>
    80003a94:	ffffd097          	auipc	ra,0xffffd
    80003a98:	a96080e7          	jalr	-1386(ra) # 8000052a <panic>

0000000080003a9c <fsinit>:
fsinit(int dev) {
    80003a9c:	7179                	addi	sp,sp,-48
    80003a9e:	f406                	sd	ra,40(sp)
    80003aa0:	f022                	sd	s0,32(sp)
    80003aa2:	ec26                	sd	s1,24(sp)
    80003aa4:	e84a                	sd	s2,16(sp)
    80003aa6:	e44e                	sd	s3,8(sp)
    80003aa8:	1800                	addi	s0,sp,48
    80003aaa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aac:	4585                	li	a1,1
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	a62080e7          	jalr	-1438(ra) # 80003510 <bread>
    80003ab6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ab8:	00024997          	auipc	s3,0x24
    80003abc:	2f098993          	addi	s3,s3,752 # 80027da8 <sb>
    80003ac0:	02000613          	li	a2,32
    80003ac4:	05850593          	addi	a1,a0,88
    80003ac8:	854e                	mv	a0,s3
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	260080e7          	jalr	608(ra) # 80000d2a <memmove>
  brelse(bp);
    80003ad2:	8526                	mv	a0,s1
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	b6c080e7          	jalr	-1172(ra) # 80003640 <brelse>
  if(sb.magic != FSMAGIC)
    80003adc:	0009a703          	lw	a4,0(s3)
    80003ae0:	102037b7          	lui	a5,0x10203
    80003ae4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ae8:	02f71263          	bne	a4,a5,80003b0c <fsinit+0x70>
  initlog(dev, &sb);
    80003aec:	00024597          	auipc	a1,0x24
    80003af0:	2bc58593          	addi	a1,a1,700 # 80027da8 <sb>
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	e60080e7          	jalr	-416(ra) # 80004956 <initlog>
}
    80003afe:	70a2                	ld	ra,40(sp)
    80003b00:	7402                	ld	s0,32(sp)
    80003b02:	64e2                	ld	s1,24(sp)
    80003b04:	6942                	ld	s2,16(sp)
    80003b06:	69a2                	ld	s3,8(sp)
    80003b08:	6145                	addi	sp,sp,48
    80003b0a:	8082                	ret
    panic("invalid file system");
    80003b0c:	00005517          	auipc	a0,0x5
    80003b10:	b3450513          	addi	a0,a0,-1228 # 80008640 <syscalls+0x140>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	a16080e7          	jalr	-1514(ra) # 8000052a <panic>

0000000080003b1c <iinit>:
{
    80003b1c:	7179                	addi	sp,sp,-48
    80003b1e:	f406                	sd	ra,40(sp)
    80003b20:	f022                	sd	s0,32(sp)
    80003b22:	ec26                	sd	s1,24(sp)
    80003b24:	e84a                	sd	s2,16(sp)
    80003b26:	e44e                	sd	s3,8(sp)
    80003b28:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b2a:	00005597          	auipc	a1,0x5
    80003b2e:	b2e58593          	addi	a1,a1,-1234 # 80008658 <syscalls+0x158>
    80003b32:	00024517          	auipc	a0,0x24
    80003b36:	29650513          	addi	a0,a0,662 # 80027dc8 <itable>
    80003b3a:	ffffd097          	auipc	ra,0xffffd
    80003b3e:	008080e7          	jalr	8(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b42:	00024497          	auipc	s1,0x24
    80003b46:	2ae48493          	addi	s1,s1,686 # 80027df0 <itable+0x28>
    80003b4a:	00026997          	auipc	s3,0x26
    80003b4e:	d3698993          	addi	s3,s3,-714 # 80029880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b52:	00005917          	auipc	s2,0x5
    80003b56:	b0e90913          	addi	s2,s2,-1266 # 80008660 <syscalls+0x160>
    80003b5a:	85ca                	mv	a1,s2
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	00001097          	auipc	ra,0x1
    80003b62:	15c080e7          	jalr	348(ra) # 80004cba <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b66:	08848493          	addi	s1,s1,136
    80003b6a:	ff3498e3          	bne	s1,s3,80003b5a <iinit+0x3e>
}
    80003b6e:	70a2                	ld	ra,40(sp)
    80003b70:	7402                	ld	s0,32(sp)
    80003b72:	64e2                	ld	s1,24(sp)
    80003b74:	6942                	ld	s2,16(sp)
    80003b76:	69a2                	ld	s3,8(sp)
    80003b78:	6145                	addi	sp,sp,48
    80003b7a:	8082                	ret

0000000080003b7c <ialloc>:
{
    80003b7c:	715d                	addi	sp,sp,-80
    80003b7e:	e486                	sd	ra,72(sp)
    80003b80:	e0a2                	sd	s0,64(sp)
    80003b82:	fc26                	sd	s1,56(sp)
    80003b84:	f84a                	sd	s2,48(sp)
    80003b86:	f44e                	sd	s3,40(sp)
    80003b88:	f052                	sd	s4,32(sp)
    80003b8a:	ec56                	sd	s5,24(sp)
    80003b8c:	e85a                	sd	s6,16(sp)
    80003b8e:	e45e                	sd	s7,8(sp)
    80003b90:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b92:	00024717          	auipc	a4,0x24
    80003b96:	22272703          	lw	a4,546(a4) # 80027db4 <sb+0xc>
    80003b9a:	4785                	li	a5,1
    80003b9c:	04e7fa63          	bgeu	a5,a4,80003bf0 <ialloc+0x74>
    80003ba0:	8aaa                	mv	s5,a0
    80003ba2:	8bae                	mv	s7,a1
    80003ba4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003ba6:	00024a17          	auipc	s4,0x24
    80003baa:	202a0a13          	addi	s4,s4,514 # 80027da8 <sb>
    80003bae:	00048b1b          	sext.w	s6,s1
    80003bb2:	0044d793          	srli	a5,s1,0x4
    80003bb6:	018a2583          	lw	a1,24(s4)
    80003bba:	9dbd                	addw	a1,a1,a5
    80003bbc:	8556                	mv	a0,s5
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	952080e7          	jalr	-1710(ra) # 80003510 <bread>
    80003bc6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bc8:	05850993          	addi	s3,a0,88
    80003bcc:	00f4f793          	andi	a5,s1,15
    80003bd0:	079a                	slli	a5,a5,0x6
    80003bd2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bd4:	00099783          	lh	a5,0(s3)
    80003bd8:	c785                	beqz	a5,80003c00 <ialloc+0x84>
    brelse(bp);
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	a66080e7          	jalr	-1434(ra) # 80003640 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003be2:	0485                	addi	s1,s1,1
    80003be4:	00ca2703          	lw	a4,12(s4)
    80003be8:	0004879b          	sext.w	a5,s1
    80003bec:	fce7e1e3          	bltu	a5,a4,80003bae <ialloc+0x32>
  panic("ialloc: no inodes");
    80003bf0:	00005517          	auipc	a0,0x5
    80003bf4:	a7850513          	addi	a0,a0,-1416 # 80008668 <syscalls+0x168>
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	932080e7          	jalr	-1742(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003c00:	04000613          	li	a2,64
    80003c04:	4581                	li	a1,0
    80003c06:	854e                	mv	a0,s3
    80003c08:	ffffd097          	auipc	ra,0xffffd
    80003c0c:	0c6080e7          	jalr	198(ra) # 80000cce <memset>
      dip->type = type;
    80003c10:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c14:	854a                	mv	a0,s2
    80003c16:	00001097          	auipc	ra,0x1
    80003c1a:	fbe080e7          	jalr	-66(ra) # 80004bd4 <log_write>
      brelse(bp);
    80003c1e:	854a                	mv	a0,s2
    80003c20:	00000097          	auipc	ra,0x0
    80003c24:	a20080e7          	jalr	-1504(ra) # 80003640 <brelse>
      return iget(dev, inum);
    80003c28:	85da                	mv	a1,s6
    80003c2a:	8556                	mv	a0,s5
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	db4080e7          	jalr	-588(ra) # 800039e0 <iget>
}
    80003c34:	60a6                	ld	ra,72(sp)
    80003c36:	6406                	ld	s0,64(sp)
    80003c38:	74e2                	ld	s1,56(sp)
    80003c3a:	7942                	ld	s2,48(sp)
    80003c3c:	79a2                	ld	s3,40(sp)
    80003c3e:	7a02                	ld	s4,32(sp)
    80003c40:	6ae2                	ld	s5,24(sp)
    80003c42:	6b42                	ld	s6,16(sp)
    80003c44:	6ba2                	ld	s7,8(sp)
    80003c46:	6161                	addi	sp,sp,80
    80003c48:	8082                	ret

0000000080003c4a <iupdate>:
{
    80003c4a:	1101                	addi	sp,sp,-32
    80003c4c:	ec06                	sd	ra,24(sp)
    80003c4e:	e822                	sd	s0,16(sp)
    80003c50:	e426                	sd	s1,8(sp)
    80003c52:	e04a                	sd	s2,0(sp)
    80003c54:	1000                	addi	s0,sp,32
    80003c56:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c58:	415c                	lw	a5,4(a0)
    80003c5a:	0047d79b          	srliw	a5,a5,0x4
    80003c5e:	00024597          	auipc	a1,0x24
    80003c62:	1625a583          	lw	a1,354(a1) # 80027dc0 <sb+0x18>
    80003c66:	9dbd                	addw	a1,a1,a5
    80003c68:	4108                	lw	a0,0(a0)
    80003c6a:	00000097          	auipc	ra,0x0
    80003c6e:	8a6080e7          	jalr	-1882(ra) # 80003510 <bread>
    80003c72:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c74:	05850793          	addi	a5,a0,88
    80003c78:	40c8                	lw	a0,4(s1)
    80003c7a:	893d                	andi	a0,a0,15
    80003c7c:	051a                	slli	a0,a0,0x6
    80003c7e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c80:	04449703          	lh	a4,68(s1)
    80003c84:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c88:	04649703          	lh	a4,70(s1)
    80003c8c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c90:	04849703          	lh	a4,72(s1)
    80003c94:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c98:	04a49703          	lh	a4,74(s1)
    80003c9c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003ca0:	44f8                	lw	a4,76(s1)
    80003ca2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ca4:	03400613          	li	a2,52
    80003ca8:	05048593          	addi	a1,s1,80
    80003cac:	0531                	addi	a0,a0,12
    80003cae:	ffffd097          	auipc	ra,0xffffd
    80003cb2:	07c080e7          	jalr	124(ra) # 80000d2a <memmove>
  log_write(bp);
    80003cb6:	854a                	mv	a0,s2
    80003cb8:	00001097          	auipc	ra,0x1
    80003cbc:	f1c080e7          	jalr	-228(ra) # 80004bd4 <log_write>
  brelse(bp);
    80003cc0:	854a                	mv	a0,s2
    80003cc2:	00000097          	auipc	ra,0x0
    80003cc6:	97e080e7          	jalr	-1666(ra) # 80003640 <brelse>
}
    80003cca:	60e2                	ld	ra,24(sp)
    80003ccc:	6442                	ld	s0,16(sp)
    80003cce:	64a2                	ld	s1,8(sp)
    80003cd0:	6902                	ld	s2,0(sp)
    80003cd2:	6105                	addi	sp,sp,32
    80003cd4:	8082                	ret

0000000080003cd6 <idup>:
{
    80003cd6:	1101                	addi	sp,sp,-32
    80003cd8:	ec06                	sd	ra,24(sp)
    80003cda:	e822                	sd	s0,16(sp)
    80003cdc:	e426                	sd	s1,8(sp)
    80003cde:	1000                	addi	s0,sp,32
    80003ce0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ce2:	00024517          	auipc	a0,0x24
    80003ce6:	0e650513          	addi	a0,a0,230 # 80027dc8 <itable>
    80003cea:	ffffd097          	auipc	ra,0xffffd
    80003cee:	ee8080e7          	jalr	-280(ra) # 80000bd2 <acquire>
  ip->ref++;
    80003cf2:	449c                	lw	a5,8(s1)
    80003cf4:	2785                	addiw	a5,a5,1
    80003cf6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf8:	00024517          	auipc	a0,0x24
    80003cfc:	0d050513          	addi	a0,a0,208 # 80027dc8 <itable>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	f86080e7          	jalr	-122(ra) # 80000c86 <release>
}
    80003d08:	8526                	mv	a0,s1
    80003d0a:	60e2                	ld	ra,24(sp)
    80003d0c:	6442                	ld	s0,16(sp)
    80003d0e:	64a2                	ld	s1,8(sp)
    80003d10:	6105                	addi	sp,sp,32
    80003d12:	8082                	ret

0000000080003d14 <ilock>:
{
    80003d14:	1101                	addi	sp,sp,-32
    80003d16:	ec06                	sd	ra,24(sp)
    80003d18:	e822                	sd	s0,16(sp)
    80003d1a:	e426                	sd	s1,8(sp)
    80003d1c:	e04a                	sd	s2,0(sp)
    80003d1e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d20:	c115                	beqz	a0,80003d44 <ilock+0x30>
    80003d22:	84aa                	mv	s1,a0
    80003d24:	451c                	lw	a5,8(a0)
    80003d26:	00f05f63          	blez	a5,80003d44 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d2a:	0541                	addi	a0,a0,16
    80003d2c:	00001097          	auipc	ra,0x1
    80003d30:	fc8080e7          	jalr	-56(ra) # 80004cf4 <acquiresleep>
  if(ip->valid == 0){
    80003d34:	40bc                	lw	a5,64(s1)
    80003d36:	cf99                	beqz	a5,80003d54 <ilock+0x40>
}
    80003d38:	60e2                	ld	ra,24(sp)
    80003d3a:	6442                	ld	s0,16(sp)
    80003d3c:	64a2                	ld	s1,8(sp)
    80003d3e:	6902                	ld	s2,0(sp)
    80003d40:	6105                	addi	sp,sp,32
    80003d42:	8082                	ret
    panic("ilock");
    80003d44:	00005517          	auipc	a0,0x5
    80003d48:	93c50513          	addi	a0,a0,-1732 # 80008680 <syscalls+0x180>
    80003d4c:	ffffc097          	auipc	ra,0xffffc
    80003d50:	7de080e7          	jalr	2014(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d54:	40dc                	lw	a5,4(s1)
    80003d56:	0047d79b          	srliw	a5,a5,0x4
    80003d5a:	00024597          	auipc	a1,0x24
    80003d5e:	0665a583          	lw	a1,102(a1) # 80027dc0 <sb+0x18>
    80003d62:	9dbd                	addw	a1,a1,a5
    80003d64:	4088                	lw	a0,0(s1)
    80003d66:	fffff097          	auipc	ra,0xfffff
    80003d6a:	7aa080e7          	jalr	1962(ra) # 80003510 <bread>
    80003d6e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d70:	05850593          	addi	a1,a0,88
    80003d74:	40dc                	lw	a5,4(s1)
    80003d76:	8bbd                	andi	a5,a5,15
    80003d78:	079a                	slli	a5,a5,0x6
    80003d7a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d7c:	00059783          	lh	a5,0(a1)
    80003d80:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d84:	00259783          	lh	a5,2(a1)
    80003d88:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d8c:	00459783          	lh	a5,4(a1)
    80003d90:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d94:	00659783          	lh	a5,6(a1)
    80003d98:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d9c:	459c                	lw	a5,8(a1)
    80003d9e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003da0:	03400613          	li	a2,52
    80003da4:	05b1                	addi	a1,a1,12
    80003da6:	05048513          	addi	a0,s1,80
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	f80080e7          	jalr	-128(ra) # 80000d2a <memmove>
    brelse(bp);
    80003db2:	854a                	mv	a0,s2
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	88c080e7          	jalr	-1908(ra) # 80003640 <brelse>
    ip->valid = 1;
    80003dbc:	4785                	li	a5,1
    80003dbe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dc0:	04449783          	lh	a5,68(s1)
    80003dc4:	fbb5                	bnez	a5,80003d38 <ilock+0x24>
      panic("ilock: no type");
    80003dc6:	00005517          	auipc	a0,0x5
    80003dca:	8c250513          	addi	a0,a0,-1854 # 80008688 <syscalls+0x188>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	75c080e7          	jalr	1884(ra) # 8000052a <panic>

0000000080003dd6 <iunlock>:
{
    80003dd6:	1101                	addi	sp,sp,-32
    80003dd8:	ec06                	sd	ra,24(sp)
    80003dda:	e822                	sd	s0,16(sp)
    80003ddc:	e426                	sd	s1,8(sp)
    80003dde:	e04a                	sd	s2,0(sp)
    80003de0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003de2:	c905                	beqz	a0,80003e12 <iunlock+0x3c>
    80003de4:	84aa                	mv	s1,a0
    80003de6:	01050913          	addi	s2,a0,16
    80003dea:	854a                	mv	a0,s2
    80003dec:	00001097          	auipc	ra,0x1
    80003df0:	fa2080e7          	jalr	-94(ra) # 80004d8e <holdingsleep>
    80003df4:	cd19                	beqz	a0,80003e12 <iunlock+0x3c>
    80003df6:	449c                	lw	a5,8(s1)
    80003df8:	00f05d63          	blez	a5,80003e12 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	00001097          	auipc	ra,0x1
    80003e02:	f4c080e7          	jalr	-180(ra) # 80004d4a <releasesleep>
}
    80003e06:	60e2                	ld	ra,24(sp)
    80003e08:	6442                	ld	s0,16(sp)
    80003e0a:	64a2                	ld	s1,8(sp)
    80003e0c:	6902                	ld	s2,0(sp)
    80003e0e:	6105                	addi	sp,sp,32
    80003e10:	8082                	ret
    panic("iunlock");
    80003e12:	00005517          	auipc	a0,0x5
    80003e16:	88650513          	addi	a0,a0,-1914 # 80008698 <syscalls+0x198>
    80003e1a:	ffffc097          	auipc	ra,0xffffc
    80003e1e:	710080e7          	jalr	1808(ra) # 8000052a <panic>

0000000080003e22 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e22:	7179                	addi	sp,sp,-48
    80003e24:	f406                	sd	ra,40(sp)
    80003e26:	f022                	sd	s0,32(sp)
    80003e28:	ec26                	sd	s1,24(sp)
    80003e2a:	e84a                	sd	s2,16(sp)
    80003e2c:	e44e                	sd	s3,8(sp)
    80003e2e:	e052                	sd	s4,0(sp)
    80003e30:	1800                	addi	s0,sp,48
    80003e32:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e34:	05050493          	addi	s1,a0,80
    80003e38:	08050913          	addi	s2,a0,128
    80003e3c:	a021                	j	80003e44 <itrunc+0x22>
    80003e3e:	0491                	addi	s1,s1,4
    80003e40:	01248d63          	beq	s1,s2,80003e5a <itrunc+0x38>
    if(ip->addrs[i]){
    80003e44:	408c                	lw	a1,0(s1)
    80003e46:	dde5                	beqz	a1,80003e3e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e48:	0009a503          	lw	a0,0(s3)
    80003e4c:	00000097          	auipc	ra,0x0
    80003e50:	90a080e7          	jalr	-1782(ra) # 80003756 <bfree>
      ip->addrs[i] = 0;
    80003e54:	0004a023          	sw	zero,0(s1)
    80003e58:	b7dd                	j	80003e3e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e5a:	0809a583          	lw	a1,128(s3)
    80003e5e:	e185                	bnez	a1,80003e7e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e60:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	de4080e7          	jalr	-540(ra) # 80003c4a <iupdate>
}
    80003e6e:	70a2                	ld	ra,40(sp)
    80003e70:	7402                	ld	s0,32(sp)
    80003e72:	64e2                	ld	s1,24(sp)
    80003e74:	6942                	ld	s2,16(sp)
    80003e76:	69a2                	ld	s3,8(sp)
    80003e78:	6a02                	ld	s4,0(sp)
    80003e7a:	6145                	addi	sp,sp,48
    80003e7c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e7e:	0009a503          	lw	a0,0(s3)
    80003e82:	fffff097          	auipc	ra,0xfffff
    80003e86:	68e080e7          	jalr	1678(ra) # 80003510 <bread>
    80003e8a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e8c:	05850493          	addi	s1,a0,88
    80003e90:	45850913          	addi	s2,a0,1112
    80003e94:	a021                	j	80003e9c <itrunc+0x7a>
    80003e96:	0491                	addi	s1,s1,4
    80003e98:	01248b63          	beq	s1,s2,80003eae <itrunc+0x8c>
      if(a[j])
    80003e9c:	408c                	lw	a1,0(s1)
    80003e9e:	dde5                	beqz	a1,80003e96 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003ea0:	0009a503          	lw	a0,0(s3)
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	8b2080e7          	jalr	-1870(ra) # 80003756 <bfree>
    80003eac:	b7ed                	j	80003e96 <itrunc+0x74>
    brelse(bp);
    80003eae:	8552                	mv	a0,s4
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	790080e7          	jalr	1936(ra) # 80003640 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eb8:	0809a583          	lw	a1,128(s3)
    80003ebc:	0009a503          	lw	a0,0(s3)
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	896080e7          	jalr	-1898(ra) # 80003756 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ec8:	0809a023          	sw	zero,128(s3)
    80003ecc:	bf51                	j	80003e60 <itrunc+0x3e>

0000000080003ece <iput>:
{
    80003ece:	1101                	addi	sp,sp,-32
    80003ed0:	ec06                	sd	ra,24(sp)
    80003ed2:	e822                	sd	s0,16(sp)
    80003ed4:	e426                	sd	s1,8(sp)
    80003ed6:	e04a                	sd	s2,0(sp)
    80003ed8:	1000                	addi	s0,sp,32
    80003eda:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003edc:	00024517          	auipc	a0,0x24
    80003ee0:	eec50513          	addi	a0,a0,-276 # 80027dc8 <itable>
    80003ee4:	ffffd097          	auipc	ra,0xffffd
    80003ee8:	cee080e7          	jalr	-786(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eec:	4498                	lw	a4,8(s1)
    80003eee:	4785                	li	a5,1
    80003ef0:	02f70363          	beq	a4,a5,80003f16 <iput+0x48>
  ip->ref--;
    80003ef4:	449c                	lw	a5,8(s1)
    80003ef6:	37fd                	addiw	a5,a5,-1
    80003ef8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003efa:	00024517          	auipc	a0,0x24
    80003efe:	ece50513          	addi	a0,a0,-306 # 80027dc8 <itable>
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	d84080e7          	jalr	-636(ra) # 80000c86 <release>
}
    80003f0a:	60e2                	ld	ra,24(sp)
    80003f0c:	6442                	ld	s0,16(sp)
    80003f0e:	64a2                	ld	s1,8(sp)
    80003f10:	6902                	ld	s2,0(sp)
    80003f12:	6105                	addi	sp,sp,32
    80003f14:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f16:	40bc                	lw	a5,64(s1)
    80003f18:	dff1                	beqz	a5,80003ef4 <iput+0x26>
    80003f1a:	04a49783          	lh	a5,74(s1)
    80003f1e:	fbf9                	bnez	a5,80003ef4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f20:	01048913          	addi	s2,s1,16
    80003f24:	854a                	mv	a0,s2
    80003f26:	00001097          	auipc	ra,0x1
    80003f2a:	dce080e7          	jalr	-562(ra) # 80004cf4 <acquiresleep>
    release(&itable.lock);
    80003f2e:	00024517          	auipc	a0,0x24
    80003f32:	e9a50513          	addi	a0,a0,-358 # 80027dc8 <itable>
    80003f36:	ffffd097          	auipc	ra,0xffffd
    80003f3a:	d50080e7          	jalr	-688(ra) # 80000c86 <release>
    itrunc(ip);
    80003f3e:	8526                	mv	a0,s1
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	ee2080e7          	jalr	-286(ra) # 80003e22 <itrunc>
    ip->type = 0;
    80003f48:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f4c:	8526                	mv	a0,s1
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	cfc080e7          	jalr	-772(ra) # 80003c4a <iupdate>
    ip->valid = 0;
    80003f56:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f5a:	854a                	mv	a0,s2
    80003f5c:	00001097          	auipc	ra,0x1
    80003f60:	dee080e7          	jalr	-530(ra) # 80004d4a <releasesleep>
    acquire(&itable.lock);
    80003f64:	00024517          	auipc	a0,0x24
    80003f68:	e6450513          	addi	a0,a0,-412 # 80027dc8 <itable>
    80003f6c:	ffffd097          	auipc	ra,0xffffd
    80003f70:	c66080e7          	jalr	-922(ra) # 80000bd2 <acquire>
    80003f74:	b741                	j	80003ef4 <iput+0x26>

0000000080003f76 <iunlockput>:
{
    80003f76:	1101                	addi	sp,sp,-32
    80003f78:	ec06                	sd	ra,24(sp)
    80003f7a:	e822                	sd	s0,16(sp)
    80003f7c:	e426                	sd	s1,8(sp)
    80003f7e:	1000                	addi	s0,sp,32
    80003f80:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	e54080e7          	jalr	-428(ra) # 80003dd6 <iunlock>
  iput(ip);
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	00000097          	auipc	ra,0x0
    80003f90:	f42080e7          	jalr	-190(ra) # 80003ece <iput>
}
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	64a2                	ld	s1,8(sp)
    80003f9a:	6105                	addi	sp,sp,32
    80003f9c:	8082                	ret

0000000080003f9e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f9e:	1141                	addi	sp,sp,-16
    80003fa0:	e422                	sd	s0,8(sp)
    80003fa2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fa4:	411c                	lw	a5,0(a0)
    80003fa6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fa8:	415c                	lw	a5,4(a0)
    80003faa:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fac:	04451783          	lh	a5,68(a0)
    80003fb0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fb4:	04a51783          	lh	a5,74(a0)
    80003fb8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fbc:	04c56783          	lwu	a5,76(a0)
    80003fc0:	e99c                	sd	a5,16(a1)
}
    80003fc2:	6422                	ld	s0,8(sp)
    80003fc4:	0141                	addi	sp,sp,16
    80003fc6:	8082                	ret

0000000080003fc8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc8:	457c                	lw	a5,76(a0)
    80003fca:	0ed7e963          	bltu	a5,a3,800040bc <readi+0xf4>
{
    80003fce:	7159                	addi	sp,sp,-112
    80003fd0:	f486                	sd	ra,104(sp)
    80003fd2:	f0a2                	sd	s0,96(sp)
    80003fd4:	eca6                	sd	s1,88(sp)
    80003fd6:	e8ca                	sd	s2,80(sp)
    80003fd8:	e4ce                	sd	s3,72(sp)
    80003fda:	e0d2                	sd	s4,64(sp)
    80003fdc:	fc56                	sd	s5,56(sp)
    80003fde:	f85a                	sd	s6,48(sp)
    80003fe0:	f45e                	sd	s7,40(sp)
    80003fe2:	f062                	sd	s8,32(sp)
    80003fe4:	ec66                	sd	s9,24(sp)
    80003fe6:	e86a                	sd	s10,16(sp)
    80003fe8:	e46e                	sd	s11,8(sp)
    80003fea:	1880                	addi	s0,sp,112
    80003fec:	8baa                	mv	s7,a0
    80003fee:	8c2e                	mv	s8,a1
    80003ff0:	8ab2                	mv	s5,a2
    80003ff2:	84b6                	mv	s1,a3
    80003ff4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ff6:	9f35                	addw	a4,a4,a3
    return 0;
    80003ff8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ffa:	0ad76063          	bltu	a4,a3,8000409a <readi+0xd2>
  if(off + n > ip->size)
    80003ffe:	00e7f463          	bgeu	a5,a4,80004006 <readi+0x3e>
    n = ip->size - off;
    80004002:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004006:	0a0b0963          	beqz	s6,800040b8 <readi+0xf0>
    8000400a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000400c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004010:	5cfd                	li	s9,-1
    80004012:	a82d                	j	8000404c <readi+0x84>
    80004014:	020a1d93          	slli	s11,s4,0x20
    80004018:	020ddd93          	srli	s11,s11,0x20
    8000401c:	05890793          	addi	a5,s2,88
    80004020:	86ee                	mv	a3,s11
    80004022:	963e                	add	a2,a2,a5
    80004024:	85d6                	mv	a1,s5
    80004026:	8562                	mv	a0,s8
    80004028:	fffff097          	auipc	ra,0xfffff
    8000402c:	b0e080e7          	jalr	-1266(ra) # 80002b36 <either_copyout>
    80004030:	05950d63          	beq	a0,s9,8000408a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004034:	854a                	mv	a0,s2
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	60a080e7          	jalr	1546(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000403e:	013a09bb          	addw	s3,s4,s3
    80004042:	009a04bb          	addw	s1,s4,s1
    80004046:	9aee                	add	s5,s5,s11
    80004048:	0569f763          	bgeu	s3,s6,80004096 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000404c:	000ba903          	lw	s2,0(s7)
    80004050:	00a4d59b          	srliw	a1,s1,0xa
    80004054:	855e                	mv	a0,s7
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	8ae080e7          	jalr	-1874(ra) # 80003904 <bmap>
    8000405e:	0005059b          	sext.w	a1,a0
    80004062:	854a                	mv	a0,s2
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	4ac080e7          	jalr	1196(ra) # 80003510 <bread>
    8000406c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000406e:	3ff4f613          	andi	a2,s1,1023
    80004072:	40cd07bb          	subw	a5,s10,a2
    80004076:	413b073b          	subw	a4,s6,s3
    8000407a:	8a3e                	mv	s4,a5
    8000407c:	2781                	sext.w	a5,a5
    8000407e:	0007069b          	sext.w	a3,a4
    80004082:	f8f6f9e3          	bgeu	a3,a5,80004014 <readi+0x4c>
    80004086:	8a3a                	mv	s4,a4
    80004088:	b771                	j	80004014 <readi+0x4c>
      brelse(bp);
    8000408a:	854a                	mv	a0,s2
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	5b4080e7          	jalr	1460(ra) # 80003640 <brelse>
      tot = -1;
    80004094:	59fd                	li	s3,-1
  }
  return tot;
    80004096:	0009851b          	sext.w	a0,s3
}
    8000409a:	70a6                	ld	ra,104(sp)
    8000409c:	7406                	ld	s0,96(sp)
    8000409e:	64e6                	ld	s1,88(sp)
    800040a0:	6946                	ld	s2,80(sp)
    800040a2:	69a6                	ld	s3,72(sp)
    800040a4:	6a06                	ld	s4,64(sp)
    800040a6:	7ae2                	ld	s5,56(sp)
    800040a8:	7b42                	ld	s6,48(sp)
    800040aa:	7ba2                	ld	s7,40(sp)
    800040ac:	7c02                	ld	s8,32(sp)
    800040ae:	6ce2                	ld	s9,24(sp)
    800040b0:	6d42                	ld	s10,16(sp)
    800040b2:	6da2                	ld	s11,8(sp)
    800040b4:	6165                	addi	sp,sp,112
    800040b6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b8:	89da                	mv	s3,s6
    800040ba:	bff1                	j	80004096 <readi+0xce>
    return 0;
    800040bc:	4501                	li	a0,0
}
    800040be:	8082                	ret

00000000800040c0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040c0:	457c                	lw	a5,76(a0)
    800040c2:	10d7e863          	bltu	a5,a3,800041d2 <writei+0x112>
{
    800040c6:	7159                	addi	sp,sp,-112
    800040c8:	f486                	sd	ra,104(sp)
    800040ca:	f0a2                	sd	s0,96(sp)
    800040cc:	eca6                	sd	s1,88(sp)
    800040ce:	e8ca                	sd	s2,80(sp)
    800040d0:	e4ce                	sd	s3,72(sp)
    800040d2:	e0d2                	sd	s4,64(sp)
    800040d4:	fc56                	sd	s5,56(sp)
    800040d6:	f85a                	sd	s6,48(sp)
    800040d8:	f45e                	sd	s7,40(sp)
    800040da:	f062                	sd	s8,32(sp)
    800040dc:	ec66                	sd	s9,24(sp)
    800040de:	e86a                	sd	s10,16(sp)
    800040e0:	e46e                	sd	s11,8(sp)
    800040e2:	1880                	addi	s0,sp,112
    800040e4:	8b2a                	mv	s6,a0
    800040e6:	8c2e                	mv	s8,a1
    800040e8:	8ab2                	mv	s5,a2
    800040ea:	8936                	mv	s2,a3
    800040ec:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040ee:	00e687bb          	addw	a5,a3,a4
    800040f2:	0ed7e263          	bltu	a5,a3,800041d6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040f6:	00043737          	lui	a4,0x43
    800040fa:	0ef76063          	bltu	a4,a5,800041da <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040fe:	0c0b8863          	beqz	s7,800041ce <writei+0x10e>
    80004102:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004104:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004108:	5cfd                	li	s9,-1
    8000410a:	a091                	j	8000414e <writei+0x8e>
    8000410c:	02099d93          	slli	s11,s3,0x20
    80004110:	020ddd93          	srli	s11,s11,0x20
    80004114:	05848793          	addi	a5,s1,88
    80004118:	86ee                	mv	a3,s11
    8000411a:	8656                	mv	a2,s5
    8000411c:	85e2                	mv	a1,s8
    8000411e:	953e                	add	a0,a0,a5
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	a6c080e7          	jalr	-1428(ra) # 80002b8c <either_copyin>
    80004128:	07950263          	beq	a0,s9,8000418c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000412c:	8526                	mv	a0,s1
    8000412e:	00001097          	auipc	ra,0x1
    80004132:	aa6080e7          	jalr	-1370(ra) # 80004bd4 <log_write>
    brelse(bp);
    80004136:	8526                	mv	a0,s1
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	508080e7          	jalr	1288(ra) # 80003640 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004140:	01498a3b          	addw	s4,s3,s4
    80004144:	0129893b          	addw	s2,s3,s2
    80004148:	9aee                	add	s5,s5,s11
    8000414a:	057a7663          	bgeu	s4,s7,80004196 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000414e:	000b2483          	lw	s1,0(s6)
    80004152:	00a9559b          	srliw	a1,s2,0xa
    80004156:	855a                	mv	a0,s6
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	7ac080e7          	jalr	1964(ra) # 80003904 <bmap>
    80004160:	0005059b          	sext.w	a1,a0
    80004164:	8526                	mv	a0,s1
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	3aa080e7          	jalr	938(ra) # 80003510 <bread>
    8000416e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004170:	3ff97513          	andi	a0,s2,1023
    80004174:	40ad07bb          	subw	a5,s10,a0
    80004178:	414b873b          	subw	a4,s7,s4
    8000417c:	89be                	mv	s3,a5
    8000417e:	2781                	sext.w	a5,a5
    80004180:	0007069b          	sext.w	a3,a4
    80004184:	f8f6f4e3          	bgeu	a3,a5,8000410c <writei+0x4c>
    80004188:	89ba                	mv	s3,a4
    8000418a:	b749                	j	8000410c <writei+0x4c>
      brelse(bp);
    8000418c:	8526                	mv	a0,s1
    8000418e:	fffff097          	auipc	ra,0xfffff
    80004192:	4b2080e7          	jalr	1202(ra) # 80003640 <brelse>
  }

  if(off > ip->size)
    80004196:	04cb2783          	lw	a5,76(s6)
    8000419a:	0127f463          	bgeu	a5,s2,800041a2 <writei+0xe2>
    ip->size = off;
    8000419e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041a2:	855a                	mv	a0,s6
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	aa6080e7          	jalr	-1370(ra) # 80003c4a <iupdate>

  return tot;
    800041ac:	000a051b          	sext.w	a0,s4
}
    800041b0:	70a6                	ld	ra,104(sp)
    800041b2:	7406                	ld	s0,96(sp)
    800041b4:	64e6                	ld	s1,88(sp)
    800041b6:	6946                	ld	s2,80(sp)
    800041b8:	69a6                	ld	s3,72(sp)
    800041ba:	6a06                	ld	s4,64(sp)
    800041bc:	7ae2                	ld	s5,56(sp)
    800041be:	7b42                	ld	s6,48(sp)
    800041c0:	7ba2                	ld	s7,40(sp)
    800041c2:	7c02                	ld	s8,32(sp)
    800041c4:	6ce2                	ld	s9,24(sp)
    800041c6:	6d42                	ld	s10,16(sp)
    800041c8:	6da2                	ld	s11,8(sp)
    800041ca:	6165                	addi	sp,sp,112
    800041cc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ce:	8a5e                	mv	s4,s7
    800041d0:	bfc9                	j	800041a2 <writei+0xe2>
    return -1;
    800041d2:	557d                	li	a0,-1
}
    800041d4:	8082                	ret
    return -1;
    800041d6:	557d                	li	a0,-1
    800041d8:	bfe1                	j	800041b0 <writei+0xf0>
    return -1;
    800041da:	557d                	li	a0,-1
    800041dc:	bfd1                	j	800041b0 <writei+0xf0>

00000000800041de <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041de:	1141                	addi	sp,sp,-16
    800041e0:	e406                	sd	ra,8(sp)
    800041e2:	e022                	sd	s0,0(sp)
    800041e4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041e6:	4639                	li	a2,14
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	bbe080e7          	jalr	-1090(ra) # 80000da6 <strncmp>
}
    800041f0:	60a2                	ld	ra,8(sp)
    800041f2:	6402                	ld	s0,0(sp)
    800041f4:	0141                	addi	sp,sp,16
    800041f6:	8082                	ret

00000000800041f8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004208:	04451703          	lh	a4,68(a0)
    8000420c:	4785                	li	a5,1
    8000420e:	00f71a63          	bne	a4,a5,80004222 <dirlookup+0x2a>
    80004212:	892a                	mv	s2,a0
    80004214:	89ae                	mv	s3,a1
    80004216:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004218:	457c                	lw	a5,76(a0)
    8000421a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000421c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421e:	e79d                	bnez	a5,8000424c <dirlookup+0x54>
    80004220:	a8a5                	j	80004298 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004222:	00004517          	auipc	a0,0x4
    80004226:	47e50513          	addi	a0,a0,1150 # 800086a0 <syscalls+0x1a0>
    8000422a:	ffffc097          	auipc	ra,0xffffc
    8000422e:	300080e7          	jalr	768(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004232:	00004517          	auipc	a0,0x4
    80004236:	48650513          	addi	a0,a0,1158 # 800086b8 <syscalls+0x1b8>
    8000423a:	ffffc097          	auipc	ra,0xffffc
    8000423e:	2f0080e7          	jalr	752(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004242:	24c1                	addiw	s1,s1,16
    80004244:	04c92783          	lw	a5,76(s2)
    80004248:	04f4f763          	bgeu	s1,a5,80004296 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000424c:	4741                	li	a4,16
    8000424e:	86a6                	mv	a3,s1
    80004250:	fc040613          	addi	a2,s0,-64
    80004254:	4581                	li	a1,0
    80004256:	854a                	mv	a0,s2
    80004258:	00000097          	auipc	ra,0x0
    8000425c:	d70080e7          	jalr	-656(ra) # 80003fc8 <readi>
    80004260:	47c1                	li	a5,16
    80004262:	fcf518e3          	bne	a0,a5,80004232 <dirlookup+0x3a>
    if(de.inum == 0)
    80004266:	fc045783          	lhu	a5,-64(s0)
    8000426a:	dfe1                	beqz	a5,80004242 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000426c:	fc240593          	addi	a1,s0,-62
    80004270:	854e                	mv	a0,s3
    80004272:	00000097          	auipc	ra,0x0
    80004276:	f6c080e7          	jalr	-148(ra) # 800041de <namecmp>
    8000427a:	f561                	bnez	a0,80004242 <dirlookup+0x4a>
      if(poff)
    8000427c:	000a0463          	beqz	s4,80004284 <dirlookup+0x8c>
        *poff = off;
    80004280:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004284:	fc045583          	lhu	a1,-64(s0)
    80004288:	00092503          	lw	a0,0(s2)
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	754080e7          	jalr	1876(ra) # 800039e0 <iget>
    80004294:	a011                	j	80004298 <dirlookup+0xa0>
  return 0;
    80004296:	4501                	li	a0,0
}
    80004298:	70e2                	ld	ra,56(sp)
    8000429a:	7442                	ld	s0,48(sp)
    8000429c:	74a2                	ld	s1,40(sp)
    8000429e:	7902                	ld	s2,32(sp)
    800042a0:	69e2                	ld	s3,24(sp)
    800042a2:	6a42                	ld	s4,16(sp)
    800042a4:	6121                	addi	sp,sp,64
    800042a6:	8082                	ret

00000000800042a8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042a8:	711d                	addi	sp,sp,-96
    800042aa:	ec86                	sd	ra,88(sp)
    800042ac:	e8a2                	sd	s0,80(sp)
    800042ae:	e4a6                	sd	s1,72(sp)
    800042b0:	e0ca                	sd	s2,64(sp)
    800042b2:	fc4e                	sd	s3,56(sp)
    800042b4:	f852                	sd	s4,48(sp)
    800042b6:	f456                	sd	s5,40(sp)
    800042b8:	f05a                	sd	s6,32(sp)
    800042ba:	ec5e                	sd	s7,24(sp)
    800042bc:	e862                	sd	s8,16(sp)
    800042be:	e466                	sd	s9,8(sp)
    800042c0:	1080                	addi	s0,sp,96
    800042c2:	84aa                	mv	s1,a0
    800042c4:	8aae                	mv	s5,a1
    800042c6:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042c8:	00054703          	lbu	a4,0(a0)
    800042cc:	02f00793          	li	a5,47
    800042d0:	02f70363          	beq	a4,a5,800042f6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042d4:	ffffe097          	auipc	ra,0xffffe
    800042d8:	d36080e7          	jalr	-714(ra) # 8000200a <myproc>
    800042dc:	15053503          	ld	a0,336(a0)
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	9f6080e7          	jalr	-1546(ra) # 80003cd6 <idup>
    800042e8:	89aa                	mv	s3,a0
  while(*path == '/')
    800042ea:	02f00913          	li	s2,47
  len = path - s;
    800042ee:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    800042f0:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042f2:	4b85                	li	s7,1
    800042f4:	a865                	j	800043ac <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042f6:	4585                	li	a1,1
    800042f8:	4505                	li	a0,1
    800042fa:	fffff097          	auipc	ra,0xfffff
    800042fe:	6e6080e7          	jalr	1766(ra) # 800039e0 <iget>
    80004302:	89aa                	mv	s3,a0
    80004304:	b7dd                	j	800042ea <namex+0x42>
      iunlockput(ip);
    80004306:	854e                	mv	a0,s3
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	c6e080e7          	jalr	-914(ra) # 80003f76 <iunlockput>
      return 0;
    80004310:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004312:	854e                	mv	a0,s3
    80004314:	60e6                	ld	ra,88(sp)
    80004316:	6446                	ld	s0,80(sp)
    80004318:	64a6                	ld	s1,72(sp)
    8000431a:	6906                	ld	s2,64(sp)
    8000431c:	79e2                	ld	s3,56(sp)
    8000431e:	7a42                	ld	s4,48(sp)
    80004320:	7aa2                	ld	s5,40(sp)
    80004322:	7b02                	ld	s6,32(sp)
    80004324:	6be2                	ld	s7,24(sp)
    80004326:	6c42                	ld	s8,16(sp)
    80004328:	6ca2                	ld	s9,8(sp)
    8000432a:	6125                	addi	sp,sp,96
    8000432c:	8082                	ret
      iunlock(ip);
    8000432e:	854e                	mv	a0,s3
    80004330:	00000097          	auipc	ra,0x0
    80004334:	aa6080e7          	jalr	-1370(ra) # 80003dd6 <iunlock>
      return ip;
    80004338:	bfe9                	j	80004312 <namex+0x6a>
      iunlockput(ip);
    8000433a:	854e                	mv	a0,s3
    8000433c:	00000097          	auipc	ra,0x0
    80004340:	c3a080e7          	jalr	-966(ra) # 80003f76 <iunlockput>
      return 0;
    80004344:	89e6                	mv	s3,s9
    80004346:	b7f1                	j	80004312 <namex+0x6a>
  len = path - s;
    80004348:	40b48633          	sub	a2,s1,a1
    8000434c:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004350:	099c5463          	bge	s8,s9,800043d8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004354:	4639                	li	a2,14
    80004356:	8552                	mv	a0,s4
    80004358:	ffffd097          	auipc	ra,0xffffd
    8000435c:	9d2080e7          	jalr	-1582(ra) # 80000d2a <memmove>
  while(*path == '/')
    80004360:	0004c783          	lbu	a5,0(s1)
    80004364:	01279763          	bne	a5,s2,80004372 <namex+0xca>
    path++;
    80004368:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000436a:	0004c783          	lbu	a5,0(s1)
    8000436e:	ff278de3          	beq	a5,s2,80004368 <namex+0xc0>
    ilock(ip);
    80004372:	854e                	mv	a0,s3
    80004374:	00000097          	auipc	ra,0x0
    80004378:	9a0080e7          	jalr	-1632(ra) # 80003d14 <ilock>
    if(ip->type != T_DIR){
    8000437c:	04499783          	lh	a5,68(s3)
    80004380:	f97793e3          	bne	a5,s7,80004306 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004384:	000a8563          	beqz	s5,8000438e <namex+0xe6>
    80004388:	0004c783          	lbu	a5,0(s1)
    8000438c:	d3cd                	beqz	a5,8000432e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000438e:	865a                	mv	a2,s6
    80004390:	85d2                	mv	a1,s4
    80004392:	854e                	mv	a0,s3
    80004394:	00000097          	auipc	ra,0x0
    80004398:	e64080e7          	jalr	-412(ra) # 800041f8 <dirlookup>
    8000439c:	8caa                	mv	s9,a0
    8000439e:	dd51                	beqz	a0,8000433a <namex+0x92>
    iunlockput(ip);
    800043a0:	854e                	mv	a0,s3
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	bd4080e7          	jalr	-1068(ra) # 80003f76 <iunlockput>
    ip = next;
    800043aa:	89e6                	mv	s3,s9
  while(*path == '/')
    800043ac:	0004c783          	lbu	a5,0(s1)
    800043b0:	05279763          	bne	a5,s2,800043fe <namex+0x156>
    path++;
    800043b4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043b6:	0004c783          	lbu	a5,0(s1)
    800043ba:	ff278de3          	beq	a5,s2,800043b4 <namex+0x10c>
  if(*path == 0)
    800043be:	c79d                	beqz	a5,800043ec <namex+0x144>
    path++;
    800043c0:	85a6                	mv	a1,s1
  len = path - s;
    800043c2:	8cda                	mv	s9,s6
    800043c4:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800043c6:	01278963          	beq	a5,s2,800043d8 <namex+0x130>
    800043ca:	dfbd                	beqz	a5,80004348 <namex+0xa0>
    path++;
    800043cc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043ce:	0004c783          	lbu	a5,0(s1)
    800043d2:	ff279ce3          	bne	a5,s2,800043ca <namex+0x122>
    800043d6:	bf8d                	j	80004348 <namex+0xa0>
    memmove(name, s, len);
    800043d8:	2601                	sext.w	a2,a2
    800043da:	8552                	mv	a0,s4
    800043dc:	ffffd097          	auipc	ra,0xffffd
    800043e0:	94e080e7          	jalr	-1714(ra) # 80000d2a <memmove>
    name[len] = 0;
    800043e4:	9cd2                	add	s9,s9,s4
    800043e6:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043ea:	bf9d                	j	80004360 <namex+0xb8>
  if(nameiparent){
    800043ec:	f20a83e3          	beqz	s5,80004312 <namex+0x6a>
    iput(ip);
    800043f0:	854e                	mv	a0,s3
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	adc080e7          	jalr	-1316(ra) # 80003ece <iput>
    return 0;
    800043fa:	4981                	li	s3,0
    800043fc:	bf19                	j	80004312 <namex+0x6a>
  if(*path == 0)
    800043fe:	d7fd                	beqz	a5,800043ec <namex+0x144>
  while(*path != '/' && *path != 0)
    80004400:	0004c783          	lbu	a5,0(s1)
    80004404:	85a6                	mv	a1,s1
    80004406:	b7d1                	j	800043ca <namex+0x122>

0000000080004408 <dirlink>:
{
    80004408:	7139                	addi	sp,sp,-64
    8000440a:	fc06                	sd	ra,56(sp)
    8000440c:	f822                	sd	s0,48(sp)
    8000440e:	f426                	sd	s1,40(sp)
    80004410:	f04a                	sd	s2,32(sp)
    80004412:	ec4e                	sd	s3,24(sp)
    80004414:	e852                	sd	s4,16(sp)
    80004416:	0080                	addi	s0,sp,64
    80004418:	892a                	mv	s2,a0
    8000441a:	8a2e                	mv	s4,a1
    8000441c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000441e:	4601                	li	a2,0
    80004420:	00000097          	auipc	ra,0x0
    80004424:	dd8080e7          	jalr	-552(ra) # 800041f8 <dirlookup>
    80004428:	e93d                	bnez	a0,8000449e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442a:	04c92483          	lw	s1,76(s2)
    8000442e:	c49d                	beqz	s1,8000445c <dirlink+0x54>
    80004430:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004432:	4741                	li	a4,16
    80004434:	86a6                	mv	a3,s1
    80004436:	fc040613          	addi	a2,s0,-64
    8000443a:	4581                	li	a1,0
    8000443c:	854a                	mv	a0,s2
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	b8a080e7          	jalr	-1142(ra) # 80003fc8 <readi>
    80004446:	47c1                	li	a5,16
    80004448:	06f51163          	bne	a0,a5,800044aa <dirlink+0xa2>
    if(de.inum == 0)
    8000444c:	fc045783          	lhu	a5,-64(s0)
    80004450:	c791                	beqz	a5,8000445c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004452:	24c1                	addiw	s1,s1,16
    80004454:	04c92783          	lw	a5,76(s2)
    80004458:	fcf4ede3          	bltu	s1,a5,80004432 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000445c:	4639                	li	a2,14
    8000445e:	85d2                	mv	a1,s4
    80004460:	fc240513          	addi	a0,s0,-62
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	97e080e7          	jalr	-1666(ra) # 80000de2 <strncpy>
  de.inum = inum;
    8000446c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004470:	4741                	li	a4,16
    80004472:	86a6                	mv	a3,s1
    80004474:	fc040613          	addi	a2,s0,-64
    80004478:	4581                	li	a1,0
    8000447a:	854a                	mv	a0,s2
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	c44080e7          	jalr	-956(ra) # 800040c0 <writei>
    80004484:	872a                	mv	a4,a0
    80004486:	47c1                	li	a5,16
  return 0;
    80004488:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000448a:	02f71863          	bne	a4,a5,800044ba <dirlink+0xb2>
}
    8000448e:	70e2                	ld	ra,56(sp)
    80004490:	7442                	ld	s0,48(sp)
    80004492:	74a2                	ld	s1,40(sp)
    80004494:	7902                	ld	s2,32(sp)
    80004496:	69e2                	ld	s3,24(sp)
    80004498:	6a42                	ld	s4,16(sp)
    8000449a:	6121                	addi	sp,sp,64
    8000449c:	8082                	ret
    iput(ip);
    8000449e:	00000097          	auipc	ra,0x0
    800044a2:	a30080e7          	jalr	-1488(ra) # 80003ece <iput>
    return -1;
    800044a6:	557d                	li	a0,-1
    800044a8:	b7dd                	j	8000448e <dirlink+0x86>
      panic("dirlink read");
    800044aa:	00004517          	auipc	a0,0x4
    800044ae:	21e50513          	addi	a0,a0,542 # 800086c8 <syscalls+0x1c8>
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	078080e7          	jalr	120(ra) # 8000052a <panic>
    panic("dirlink");
    800044ba:	00004517          	auipc	a0,0x4
    800044be:	39650513          	addi	a0,a0,918 # 80008850 <syscalls+0x350>
    800044c2:	ffffc097          	auipc	ra,0xffffc
    800044c6:	068080e7          	jalr	104(ra) # 8000052a <panic>

00000000800044ca <namei>:

struct inode*
namei(char *path)
{
    800044ca:	1101                	addi	sp,sp,-32
    800044cc:	ec06                	sd	ra,24(sp)
    800044ce:	e822                	sd	s0,16(sp)
    800044d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044d2:	fe040613          	addi	a2,s0,-32
    800044d6:	4581                	li	a1,0
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	dd0080e7          	jalr	-560(ra) # 800042a8 <namex>
}
    800044e0:	60e2                	ld	ra,24(sp)
    800044e2:	6442                	ld	s0,16(sp)
    800044e4:	6105                	addi	sp,sp,32
    800044e6:	8082                	ret

00000000800044e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e8:	1141                	addi	sp,sp,-16
    800044ea:	e406                	sd	ra,8(sp)
    800044ec:	e022                	sd	s0,0(sp)
    800044ee:	0800                	addi	s0,sp,16
    800044f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044f2:	4585                	li	a1,1
    800044f4:	00000097          	auipc	ra,0x0
    800044f8:	db4080e7          	jalr	-588(ra) # 800042a8 <namex>
}
    800044fc:	60a2                	ld	ra,8(sp)
    800044fe:	6402                	ld	s0,0(sp)
    80004500:	0141                	addi	sp,sp,16
    80004502:	8082                	ret

0000000080004504 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004504:	1101                	addi	sp,sp,-32
    80004506:	ec22                	sd	s0,24(sp)
    80004508:	1000                	addi	s0,sp,32
    8000450a:	872a                	mv	a4,a0
    8000450c:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    8000450e:	00004797          	auipc	a5,0x4
    80004512:	1ca78793          	addi	a5,a5,458 # 800086d8 <syscalls+0x1d8>
    80004516:	6394                	ld	a3,0(a5)
    80004518:	fed43023          	sd	a3,-32(s0)
    8000451c:	0087d683          	lhu	a3,8(a5)
    80004520:	fed41423          	sh	a3,-24(s0)
    80004524:	00a7c783          	lbu	a5,10(a5)
    80004528:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    8000452c:	87ae                	mv	a5,a1
    if(i<0){
    8000452e:	02074b63          	bltz	a4,80004564 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    80004532:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004534:	4629                	li	a2,10
        ++p;
    80004536:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004538:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    8000453c:	feed                	bnez	a3,80004536 <itoa+0x32>
    *p = '\0';
    8000453e:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    80004542:	4629                	li	a2,10
    80004544:	17fd                	addi	a5,a5,-1
    80004546:	02c766bb          	remw	a3,a4,a2
    8000454a:	ff040593          	addi	a1,s0,-16
    8000454e:	96ae                	add	a3,a3,a1
    80004550:	ff06c683          	lbu	a3,-16(a3)
    80004554:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004558:	02c7473b          	divw	a4,a4,a2
    }while(i);
    8000455c:	f765                	bnez	a4,80004544 <itoa+0x40>
    return b;
}
    8000455e:	6462                	ld	s0,24(sp)
    80004560:	6105                	addi	sp,sp,32
    80004562:	8082                	ret
        *p++ = '-';
    80004564:	00158793          	addi	a5,a1,1
    80004568:	02d00693          	li	a3,45
    8000456c:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004570:	40e0073b          	negw	a4,a4
    80004574:	bf7d                	j	80004532 <itoa+0x2e>

0000000080004576 <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004576:	711d                	addi	sp,sp,-96
    80004578:	ec86                	sd	ra,88(sp)
    8000457a:	e8a2                	sd	s0,80(sp)
    8000457c:	e4a6                	sd	s1,72(sp)
    8000457e:	e0ca                	sd	s2,64(sp)
    80004580:	1080                	addi	s0,sp,96
    80004582:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004584:	4619                	li	a2,6
    80004586:	00004597          	auipc	a1,0x4
    8000458a:	16258593          	addi	a1,a1,354 # 800086e8 <syscalls+0x1e8>
    8000458e:	fd040513          	addi	a0,s0,-48
    80004592:	ffffc097          	auipc	ra,0xffffc
    80004596:	798080e7          	jalr	1944(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    8000459a:	fd640593          	addi	a1,s0,-42
    8000459e:	5888                	lw	a0,48(s1)
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	f64080e7          	jalr	-156(ra) # 80004504 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    800045a8:	1684b503          	ld	a0,360(s1)
    800045ac:	16050763          	beqz	a0,8000471a <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    800045b0:	00001097          	auipc	ra,0x1
    800045b4:	918080e7          	jalr	-1768(ra) # 80004ec8 <fileclose>

  begin_op();
    800045b8:	00000097          	auipc	ra,0x0
    800045bc:	444080e7          	jalr	1092(ra) # 800049fc <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800045c0:	fb040593          	addi	a1,s0,-80
    800045c4:	fd040513          	addi	a0,s0,-48
    800045c8:	00000097          	auipc	ra,0x0
    800045cc:	f20080e7          	jalr	-224(ra) # 800044e8 <nameiparent>
    800045d0:	892a                	mv	s2,a0
    800045d2:	cd69                	beqz	a0,800046ac <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    800045d4:	fffff097          	auipc	ra,0xfffff
    800045d8:	740080e7          	jalr	1856(ra) # 80003d14 <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800045dc:	00004597          	auipc	a1,0x4
    800045e0:	11458593          	addi	a1,a1,276 # 800086f0 <syscalls+0x1f0>
    800045e4:	fb040513          	addi	a0,s0,-80
    800045e8:	00000097          	auipc	ra,0x0
    800045ec:	bf6080e7          	jalr	-1034(ra) # 800041de <namecmp>
    800045f0:	c57d                	beqz	a0,800046de <removeSwapFile+0x168>
    800045f2:	00004597          	auipc	a1,0x4
    800045f6:	10658593          	addi	a1,a1,262 # 800086f8 <syscalls+0x1f8>
    800045fa:	fb040513          	addi	a0,s0,-80
    800045fe:	00000097          	auipc	ra,0x0
    80004602:	be0080e7          	jalr	-1056(ra) # 800041de <namecmp>
    80004606:	cd61                	beqz	a0,800046de <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004608:	fac40613          	addi	a2,s0,-84
    8000460c:	fb040593          	addi	a1,s0,-80
    80004610:	854a                	mv	a0,s2
    80004612:	00000097          	auipc	ra,0x0
    80004616:	be6080e7          	jalr	-1050(ra) # 800041f8 <dirlookup>
    8000461a:	84aa                	mv	s1,a0
    8000461c:	c169                	beqz	a0,800046de <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	6f6080e7          	jalr	1782(ra) # 80003d14 <ilock>

  if(ip->nlink < 1)
    80004626:	04a49783          	lh	a5,74(s1)
    8000462a:	08f05763          	blez	a5,800046b8 <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000462e:	04449703          	lh	a4,68(s1)
    80004632:	4785                	li	a5,1
    80004634:	08f70a63          	beq	a4,a5,800046c8 <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004638:	4641                	li	a2,16
    8000463a:	4581                	li	a1,0
    8000463c:	fc040513          	addi	a0,s0,-64
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	68e080e7          	jalr	1678(ra) # 80000cce <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004648:	4741                	li	a4,16
    8000464a:	fac42683          	lw	a3,-84(s0)
    8000464e:	fc040613          	addi	a2,s0,-64
    80004652:	4581                	li	a1,0
    80004654:	854a                	mv	a0,s2
    80004656:	00000097          	auipc	ra,0x0
    8000465a:	a6a080e7          	jalr	-1430(ra) # 800040c0 <writei>
    8000465e:	47c1                	li	a5,16
    80004660:	08f51a63          	bne	a0,a5,800046f4 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004664:	04449703          	lh	a4,68(s1)
    80004668:	4785                	li	a5,1
    8000466a:	08f70d63          	beq	a4,a5,80004704 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    8000466e:	854a                	mv	a0,s2
    80004670:	00000097          	auipc	ra,0x0
    80004674:	906080e7          	jalr	-1786(ra) # 80003f76 <iunlockput>

  ip->nlink--;
    80004678:	04a4d783          	lhu	a5,74(s1)
    8000467c:	37fd                	addiw	a5,a5,-1
    8000467e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004682:	8526                	mv	a0,s1
    80004684:	fffff097          	auipc	ra,0xfffff
    80004688:	5c6080e7          	jalr	1478(ra) # 80003c4a <iupdate>
  iunlockput(ip);
    8000468c:	8526                	mv	a0,s1
    8000468e:	00000097          	auipc	ra,0x0
    80004692:	8e8080e7          	jalr	-1816(ra) # 80003f76 <iunlockput>

  end_op();
    80004696:	00000097          	auipc	ra,0x0
    8000469a:	3e6080e7          	jalr	998(ra) # 80004a7c <end_op>

  return 0;
    8000469e:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    800046a0:	60e6                	ld	ra,88(sp)
    800046a2:	6446                	ld	s0,80(sp)
    800046a4:	64a6                	ld	s1,72(sp)
    800046a6:	6906                	ld	s2,64(sp)
    800046a8:	6125                	addi	sp,sp,96
    800046aa:	8082                	ret
    end_op();
    800046ac:	00000097          	auipc	ra,0x0
    800046b0:	3d0080e7          	jalr	976(ra) # 80004a7c <end_op>
    return -1;
    800046b4:	557d                	li	a0,-1
    800046b6:	b7ed                	j	800046a0 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    800046b8:	00004517          	auipc	a0,0x4
    800046bc:	04850513          	addi	a0,a0,72 # 80008700 <syscalls+0x200>
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	e6a080e7          	jalr	-406(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800046c8:	8526                	mv	a0,s1
    800046ca:	00001097          	auipc	ra,0x1
    800046ce:	798080e7          	jalr	1944(ra) # 80005e62 <isdirempty>
    800046d2:	f13d                	bnez	a0,80004638 <removeSwapFile+0xc2>
    iunlockput(ip);
    800046d4:	8526                	mv	a0,s1
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	8a0080e7          	jalr	-1888(ra) # 80003f76 <iunlockput>
    iunlockput(dp);
    800046de:	854a                	mv	a0,s2
    800046e0:	00000097          	auipc	ra,0x0
    800046e4:	896080e7          	jalr	-1898(ra) # 80003f76 <iunlockput>
    end_op();
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	394080e7          	jalr	916(ra) # 80004a7c <end_op>
    return -1;
    800046f0:	557d                	li	a0,-1
    800046f2:	b77d                	j	800046a0 <removeSwapFile+0x12a>
    panic("unlink: writei");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	02450513          	addi	a0,a0,36 # 80008718 <syscalls+0x218>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e2e080e7          	jalr	-466(ra) # 8000052a <panic>
    dp->nlink--;
    80004704:	04a95783          	lhu	a5,74(s2)
    80004708:	37fd                	addiw	a5,a5,-1
    8000470a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000470e:	854a                	mv	a0,s2
    80004710:	fffff097          	auipc	ra,0xfffff
    80004714:	53a080e7          	jalr	1338(ra) # 80003c4a <iupdate>
    80004718:	bf99                	j	8000466e <removeSwapFile+0xf8>
    return -1;
    8000471a:	557d                	li	a0,-1
    8000471c:	b751                	j	800046a0 <removeSwapFile+0x12a>

000000008000471e <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    8000471e:	7179                	addi	sp,sp,-48
    80004720:	f406                	sd	ra,40(sp)
    80004722:	f022                	sd	s0,32(sp)
    80004724:	ec26                	sd	s1,24(sp)
    80004726:	e84a                	sd	s2,16(sp)
    80004728:	1800                	addi	s0,sp,48
    8000472a:	84aa                	mv	s1,a0
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    8000472c:	4619                	li	a2,6
    8000472e:	00004597          	auipc	a1,0x4
    80004732:	fba58593          	addi	a1,a1,-70 # 800086e8 <syscalls+0x1e8>
    80004736:	fd040513          	addi	a0,s0,-48
    8000473a:	ffffc097          	auipc	ra,0xffffc
    8000473e:	5f0080e7          	jalr	1520(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004742:	fd640593          	addi	a1,s0,-42
    80004746:	5888                	lw	a0,48(s1)
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	dbc080e7          	jalr	-580(ra) # 80004504 <itoa>

  begin_op();
    80004750:	00000097          	auipc	ra,0x0
    80004754:	2ac080e7          	jalr	684(ra) # 800049fc <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004758:	4681                	li	a3,0
    8000475a:	4601                	li	a2,0
    8000475c:	4589                	li	a1,2
    8000475e:	fd040513          	addi	a0,s0,-48
    80004762:	00002097          	auipc	ra,0x2
    80004766:	8f4080e7          	jalr	-1804(ra) # 80006056 <create>
    8000476a:	892a                	mv	s2,a0
  iunlock(in);
    8000476c:	fffff097          	auipc	ra,0xfffff
    80004770:	66a080e7          	jalr	1642(ra) # 80003dd6 <iunlock>
  p->swapFile = filealloc();
    80004774:	00000097          	auipc	ra,0x0
    80004778:	698080e7          	jalr	1688(ra) # 80004e0c <filealloc>
    8000477c:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004780:	cd1d                	beqz	a0,800047be <createSwapFile+0xa0>
    panic("no slot for files on /store");
  p->swapFile->ip = in;
    80004782:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004786:	1684b703          	ld	a4,360(s1)
    8000478a:	4789                	li	a5,2
    8000478c:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    8000478e:	1684b703          	ld	a4,360(s1)
    80004792:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004796:	1684b703          	ld	a4,360(s1)
    8000479a:	4685                	li	a3,1
    8000479c:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    800047a0:	1684b703          	ld	a4,360(s1)
    800047a4:	00f704a3          	sb	a5,9(a4)
  end_op();
    800047a8:	00000097          	auipc	ra,0x0
    800047ac:	2d4080e7          	jalr	724(ra) # 80004a7c <end_op>
  return 0;
}
    800047b0:	4501                	li	a0,0
    800047b2:	70a2                	ld	ra,40(sp)
    800047b4:	7402                	ld	s0,32(sp)
    800047b6:	64e2                	ld	s1,24(sp)
    800047b8:	6942                	ld	s2,16(sp)
    800047ba:	6145                	addi	sp,sp,48
    800047bc:	8082                	ret
    panic("no slot for files on /store");
    800047be:	00004517          	auipc	a0,0x4
    800047c2:	f6a50513          	addi	a0,a0,-150 # 80008728 <syscalls+0x228>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	d64080e7          	jalr	-668(ra) # 8000052a <panic>

00000000800047ce <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800047ce:	1141                	addi	sp,sp,-16
    800047d0:	e406                	sd	ra,8(sp)
    800047d2:	e022                	sd	s0,0(sp)
    800047d4:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800047d6:	16853783          	ld	a5,360(a0)
    800047da:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    800047dc:	8636                	mv	a2,a3
    800047de:	16853503          	ld	a0,360(a0)
    800047e2:	00001097          	auipc	ra,0x1
    800047e6:	ad8080e7          	jalr	-1320(ra) # 800052ba <kfilewrite>
}
    800047ea:	60a2                	ld	ra,8(sp)
    800047ec:	6402                	ld	s0,0(sp)
    800047ee:	0141                	addi	sp,sp,16
    800047f0:	8082                	ret

00000000800047f2 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    800047f2:	1141                	addi	sp,sp,-16
    800047f4:	e406                	sd	ra,8(sp)
    800047f6:	e022                	sd	s0,0(sp)
    800047f8:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    800047fa:	16853783          	ld	a5,360(a0)
    800047fe:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004800:	8636                	mv	a2,a3
    80004802:	16853503          	ld	a0,360(a0)
    80004806:	00001097          	auipc	ra,0x1
    8000480a:	9f2080e7          	jalr	-1550(ra) # 800051f8 <kfileread>
    8000480e:	60a2                	ld	ra,8(sp)
    80004810:	6402                	ld	s0,0(sp)
    80004812:	0141                	addi	sp,sp,16
    80004814:	8082                	ret

0000000080004816 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004816:	1101                	addi	sp,sp,-32
    80004818:	ec06                	sd	ra,24(sp)
    8000481a:	e822                	sd	s0,16(sp)
    8000481c:	e426                	sd	s1,8(sp)
    8000481e:	e04a                	sd	s2,0(sp)
    80004820:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004822:	00025917          	auipc	s2,0x25
    80004826:	04e90913          	addi	s2,s2,78 # 80029870 <log>
    8000482a:	01892583          	lw	a1,24(s2)
    8000482e:	02892503          	lw	a0,40(s2)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	cde080e7          	jalr	-802(ra) # 80003510 <bread>
    8000483a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000483c:	02c92683          	lw	a3,44(s2)
    80004840:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004842:	02d05863          	blez	a3,80004872 <write_head+0x5c>
    80004846:	00025797          	auipc	a5,0x25
    8000484a:	05a78793          	addi	a5,a5,90 # 800298a0 <log+0x30>
    8000484e:	05c50713          	addi	a4,a0,92
    80004852:	36fd                	addiw	a3,a3,-1
    80004854:	02069613          	slli	a2,a3,0x20
    80004858:	01e65693          	srli	a3,a2,0x1e
    8000485c:	00025617          	auipc	a2,0x25
    80004860:	04860613          	addi	a2,a2,72 # 800298a4 <log+0x34>
    80004864:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004866:	4390                	lw	a2,0(a5)
    80004868:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000486a:	0791                	addi	a5,a5,4
    8000486c:	0711                	addi	a4,a4,4
    8000486e:	fed79ce3          	bne	a5,a3,80004866 <write_head+0x50>
  }
  bwrite(buf);
    80004872:	8526                	mv	a0,s1
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	d8e080e7          	jalr	-626(ra) # 80003602 <bwrite>
  brelse(buf);
    8000487c:	8526                	mv	a0,s1
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	dc2080e7          	jalr	-574(ra) # 80003640 <brelse>
}
    80004886:	60e2                	ld	ra,24(sp)
    80004888:	6442                	ld	s0,16(sp)
    8000488a:	64a2                	ld	s1,8(sp)
    8000488c:	6902                	ld	s2,0(sp)
    8000488e:	6105                	addi	sp,sp,32
    80004890:	8082                	ret

0000000080004892 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004892:	00025797          	auipc	a5,0x25
    80004896:	00a7a783          	lw	a5,10(a5) # 8002989c <log+0x2c>
    8000489a:	0af05d63          	blez	a5,80004954 <install_trans+0xc2>
{
    8000489e:	7139                	addi	sp,sp,-64
    800048a0:	fc06                	sd	ra,56(sp)
    800048a2:	f822                	sd	s0,48(sp)
    800048a4:	f426                	sd	s1,40(sp)
    800048a6:	f04a                	sd	s2,32(sp)
    800048a8:	ec4e                	sd	s3,24(sp)
    800048aa:	e852                	sd	s4,16(sp)
    800048ac:	e456                	sd	s5,8(sp)
    800048ae:	e05a                	sd	s6,0(sp)
    800048b0:	0080                	addi	s0,sp,64
    800048b2:	8b2a                	mv	s6,a0
    800048b4:	00025a97          	auipc	s5,0x25
    800048b8:	feca8a93          	addi	s5,s5,-20 # 800298a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048bc:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048be:	00025997          	auipc	s3,0x25
    800048c2:	fb298993          	addi	s3,s3,-78 # 80029870 <log>
    800048c6:	a00d                	j	800048e8 <install_trans+0x56>
    brelse(lbuf);
    800048c8:	854a                	mv	a0,s2
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	d76080e7          	jalr	-650(ra) # 80003640 <brelse>
    brelse(dbuf);
    800048d2:	8526                	mv	a0,s1
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	d6c080e7          	jalr	-660(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048dc:	2a05                	addiw	s4,s4,1
    800048de:	0a91                	addi	s5,s5,4
    800048e0:	02c9a783          	lw	a5,44(s3)
    800048e4:	04fa5e63          	bge	s4,a5,80004940 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800048e8:	0189a583          	lw	a1,24(s3)
    800048ec:	014585bb          	addw	a1,a1,s4
    800048f0:	2585                	addiw	a1,a1,1
    800048f2:	0289a503          	lw	a0,40(s3)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	c1a080e7          	jalr	-998(ra) # 80003510 <bread>
    800048fe:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004900:	000aa583          	lw	a1,0(s5)
    80004904:	0289a503          	lw	a0,40(s3)
    80004908:	fffff097          	auipc	ra,0xfffff
    8000490c:	c08080e7          	jalr	-1016(ra) # 80003510 <bread>
    80004910:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004912:	40000613          	li	a2,1024
    80004916:	05890593          	addi	a1,s2,88
    8000491a:	05850513          	addi	a0,a0,88
    8000491e:	ffffc097          	auipc	ra,0xffffc
    80004922:	40c080e7          	jalr	1036(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004926:	8526                	mv	a0,s1
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	cda080e7          	jalr	-806(ra) # 80003602 <bwrite>
    if(recovering == 0)
    80004930:	f80b1ce3          	bnez	s6,800048c8 <install_trans+0x36>
      bunpin(dbuf);
    80004934:	8526                	mv	a0,s1
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	de4080e7          	jalr	-540(ra) # 8000371a <bunpin>
    8000493e:	b769                	j	800048c8 <install_trans+0x36>
}
    80004940:	70e2                	ld	ra,56(sp)
    80004942:	7442                	ld	s0,48(sp)
    80004944:	74a2                	ld	s1,40(sp)
    80004946:	7902                	ld	s2,32(sp)
    80004948:	69e2                	ld	s3,24(sp)
    8000494a:	6a42                	ld	s4,16(sp)
    8000494c:	6aa2                	ld	s5,8(sp)
    8000494e:	6b02                	ld	s6,0(sp)
    80004950:	6121                	addi	sp,sp,64
    80004952:	8082                	ret
    80004954:	8082                	ret

0000000080004956 <initlog>:
{
    80004956:	7179                	addi	sp,sp,-48
    80004958:	f406                	sd	ra,40(sp)
    8000495a:	f022                	sd	s0,32(sp)
    8000495c:	ec26                	sd	s1,24(sp)
    8000495e:	e84a                	sd	s2,16(sp)
    80004960:	e44e                	sd	s3,8(sp)
    80004962:	1800                	addi	s0,sp,48
    80004964:	892a                	mv	s2,a0
    80004966:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004968:	00025497          	auipc	s1,0x25
    8000496c:	f0848493          	addi	s1,s1,-248 # 80029870 <log>
    80004970:	00004597          	auipc	a1,0x4
    80004974:	dd858593          	addi	a1,a1,-552 # 80008748 <syscalls+0x248>
    80004978:	8526                	mv	a0,s1
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	1c8080e7          	jalr	456(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004982:	0149a583          	lw	a1,20(s3)
    80004986:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004988:	0109a783          	lw	a5,16(s3)
    8000498c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000498e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004992:	854a                	mv	a0,s2
    80004994:	fffff097          	auipc	ra,0xfffff
    80004998:	b7c080e7          	jalr	-1156(ra) # 80003510 <bread>
  log.lh.n = lh->n;
    8000499c:	4d34                	lw	a3,88(a0)
    8000499e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800049a0:	02d05663          	blez	a3,800049cc <initlog+0x76>
    800049a4:	05c50793          	addi	a5,a0,92
    800049a8:	00025717          	auipc	a4,0x25
    800049ac:	ef870713          	addi	a4,a4,-264 # 800298a0 <log+0x30>
    800049b0:	36fd                	addiw	a3,a3,-1
    800049b2:	02069613          	slli	a2,a3,0x20
    800049b6:	01e65693          	srli	a3,a2,0x1e
    800049ba:	06050613          	addi	a2,a0,96
    800049be:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800049c0:	4390                	lw	a2,0(a5)
    800049c2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800049c4:	0791                	addi	a5,a5,4
    800049c6:	0711                	addi	a4,a4,4
    800049c8:	fed79ce3          	bne	a5,a3,800049c0 <initlog+0x6a>
  brelse(buf);
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	c74080e7          	jalr	-908(ra) # 80003640 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800049d4:	4505                	li	a0,1
    800049d6:	00000097          	auipc	ra,0x0
    800049da:	ebc080e7          	jalr	-324(ra) # 80004892 <install_trans>
  log.lh.n = 0;
    800049de:	00025797          	auipc	a5,0x25
    800049e2:	ea07af23          	sw	zero,-322(a5) # 8002989c <log+0x2c>
  write_head(); // clear the log
    800049e6:	00000097          	auipc	ra,0x0
    800049ea:	e30080e7          	jalr	-464(ra) # 80004816 <write_head>
}
    800049ee:	70a2                	ld	ra,40(sp)
    800049f0:	7402                	ld	s0,32(sp)
    800049f2:	64e2                	ld	s1,24(sp)
    800049f4:	6942                	ld	s2,16(sp)
    800049f6:	69a2                	ld	s3,8(sp)
    800049f8:	6145                	addi	sp,sp,48
    800049fa:	8082                	ret

00000000800049fc <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800049fc:	1101                	addi	sp,sp,-32
    800049fe:	ec06                	sd	ra,24(sp)
    80004a00:	e822                	sd	s0,16(sp)
    80004a02:	e426                	sd	s1,8(sp)
    80004a04:	e04a                	sd	s2,0(sp)
    80004a06:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004a08:	00025517          	auipc	a0,0x25
    80004a0c:	e6850513          	addi	a0,a0,-408 # 80029870 <log>
    80004a10:	ffffc097          	auipc	ra,0xffffc
    80004a14:	1c2080e7          	jalr	450(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004a18:	00025497          	auipc	s1,0x25
    80004a1c:	e5848493          	addi	s1,s1,-424 # 80029870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a20:	4979                	li	s2,30
    80004a22:	a039                	j	80004a30 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004a24:	85a6                	mv	a1,s1
    80004a26:	8526                	mv	a0,s1
    80004a28:	ffffe097          	auipc	ra,0xffffe
    80004a2c:	d54080e7          	jalr	-684(ra) # 8000277c <sleep>
    if(log.committing){
    80004a30:	50dc                	lw	a5,36(s1)
    80004a32:	fbed                	bnez	a5,80004a24 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004a34:	509c                	lw	a5,32(s1)
    80004a36:	0017871b          	addiw	a4,a5,1
    80004a3a:	0007069b          	sext.w	a3,a4
    80004a3e:	0027179b          	slliw	a5,a4,0x2
    80004a42:	9fb9                	addw	a5,a5,a4
    80004a44:	0017979b          	slliw	a5,a5,0x1
    80004a48:	54d8                	lw	a4,44(s1)
    80004a4a:	9fb9                	addw	a5,a5,a4
    80004a4c:	00f95963          	bge	s2,a5,80004a5e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004a50:	85a6                	mv	a1,s1
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	d28080e7          	jalr	-728(ra) # 8000277c <sleep>
    80004a5c:	bfd1                	j	80004a30 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004a5e:	00025517          	auipc	a0,0x25
    80004a62:	e1250513          	addi	a0,a0,-494 # 80029870 <log>
    80004a66:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	21e080e7          	jalr	542(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004a70:	60e2                	ld	ra,24(sp)
    80004a72:	6442                	ld	s0,16(sp)
    80004a74:	64a2                	ld	s1,8(sp)
    80004a76:	6902                	ld	s2,0(sp)
    80004a78:	6105                	addi	sp,sp,32
    80004a7a:	8082                	ret

0000000080004a7c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a7c:	7139                	addi	sp,sp,-64
    80004a7e:	fc06                	sd	ra,56(sp)
    80004a80:	f822                	sd	s0,48(sp)
    80004a82:	f426                	sd	s1,40(sp)
    80004a84:	f04a                	sd	s2,32(sp)
    80004a86:	ec4e                	sd	s3,24(sp)
    80004a88:	e852                	sd	s4,16(sp)
    80004a8a:	e456                	sd	s5,8(sp)
    80004a8c:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a8e:	00025497          	auipc	s1,0x25
    80004a92:	de248493          	addi	s1,s1,-542 # 80029870 <log>
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	13a080e7          	jalr	314(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004aa0:	509c                	lw	a5,32(s1)
    80004aa2:	37fd                	addiw	a5,a5,-1
    80004aa4:	0007891b          	sext.w	s2,a5
    80004aa8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004aaa:	50dc                	lw	a5,36(s1)
    80004aac:	e7b9                	bnez	a5,80004afa <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004aae:	04091e63          	bnez	s2,80004b0a <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004ab2:	00025497          	auipc	s1,0x25
    80004ab6:	dbe48493          	addi	s1,s1,-578 # 80029870 <log>
    80004aba:	4785                	li	a5,1
    80004abc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffc097          	auipc	ra,0xffffc
    80004ac4:	1c6080e7          	jalr	454(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004ac8:	54dc                	lw	a5,44(s1)
    80004aca:	06f04763          	bgtz	a5,80004b38 <end_op+0xbc>
    acquire(&log.lock);
    80004ace:	00025497          	auipc	s1,0x25
    80004ad2:	da248493          	addi	s1,s1,-606 # 80029870 <log>
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	0fa080e7          	jalr	250(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80004ae0:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004ae4:	8526                	mv	a0,s1
    80004ae6:	ffffe097          	auipc	ra,0xffffe
    80004aea:	e22080e7          	jalr	-478(ra) # 80002908 <wakeup>
    release(&log.lock);
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	196080e7          	jalr	406(ra) # 80000c86 <release>
}
    80004af8:	a03d                	j	80004b26 <end_op+0xaa>
    panic("log.committing");
    80004afa:	00004517          	auipc	a0,0x4
    80004afe:	c5650513          	addi	a0,a0,-938 # 80008750 <syscalls+0x250>
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	a28080e7          	jalr	-1496(ra) # 8000052a <panic>
    wakeup(&log);
    80004b0a:	00025497          	auipc	s1,0x25
    80004b0e:	d6648493          	addi	s1,s1,-666 # 80029870 <log>
    80004b12:	8526                	mv	a0,s1
    80004b14:	ffffe097          	auipc	ra,0xffffe
    80004b18:	df4080e7          	jalr	-524(ra) # 80002908 <wakeup>
  release(&log.lock);
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	ffffc097          	auipc	ra,0xffffc
    80004b22:	168080e7          	jalr	360(ra) # 80000c86 <release>
}
    80004b26:	70e2                	ld	ra,56(sp)
    80004b28:	7442                	ld	s0,48(sp)
    80004b2a:	74a2                	ld	s1,40(sp)
    80004b2c:	7902                	ld	s2,32(sp)
    80004b2e:	69e2                	ld	s3,24(sp)
    80004b30:	6a42                	ld	s4,16(sp)
    80004b32:	6aa2                	ld	s5,8(sp)
    80004b34:	6121                	addi	sp,sp,64
    80004b36:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b38:	00025a97          	auipc	s5,0x25
    80004b3c:	d68a8a93          	addi	s5,s5,-664 # 800298a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004b40:	00025a17          	auipc	s4,0x25
    80004b44:	d30a0a13          	addi	s4,s4,-720 # 80029870 <log>
    80004b48:	018a2583          	lw	a1,24(s4)
    80004b4c:	012585bb          	addw	a1,a1,s2
    80004b50:	2585                	addiw	a1,a1,1
    80004b52:	028a2503          	lw	a0,40(s4)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	9ba080e7          	jalr	-1606(ra) # 80003510 <bread>
    80004b5e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004b60:	000aa583          	lw	a1,0(s5)
    80004b64:	028a2503          	lw	a0,40(s4)
    80004b68:	fffff097          	auipc	ra,0xfffff
    80004b6c:	9a8080e7          	jalr	-1624(ra) # 80003510 <bread>
    80004b70:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b72:	40000613          	li	a2,1024
    80004b76:	05850593          	addi	a1,a0,88
    80004b7a:	05848513          	addi	a0,s1,88
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	1ac080e7          	jalr	428(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    80004b86:	8526                	mv	a0,s1
    80004b88:	fffff097          	auipc	ra,0xfffff
    80004b8c:	a7a080e7          	jalr	-1414(ra) # 80003602 <bwrite>
    brelse(from);
    80004b90:	854e                	mv	a0,s3
    80004b92:	fffff097          	auipc	ra,0xfffff
    80004b96:	aae080e7          	jalr	-1362(ra) # 80003640 <brelse>
    brelse(to);
    80004b9a:	8526                	mv	a0,s1
    80004b9c:	fffff097          	auipc	ra,0xfffff
    80004ba0:	aa4080e7          	jalr	-1372(ra) # 80003640 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ba4:	2905                	addiw	s2,s2,1
    80004ba6:	0a91                	addi	s5,s5,4
    80004ba8:	02ca2783          	lw	a5,44(s4)
    80004bac:	f8f94ee3          	blt	s2,a5,80004b48 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004bb0:	00000097          	auipc	ra,0x0
    80004bb4:	c66080e7          	jalr	-922(ra) # 80004816 <write_head>
    install_trans(0); // Now install writes to home locations
    80004bb8:	4501                	li	a0,0
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	cd8080e7          	jalr	-808(ra) # 80004892 <install_trans>
    log.lh.n = 0;
    80004bc2:	00025797          	auipc	a5,0x25
    80004bc6:	cc07ad23          	sw	zero,-806(a5) # 8002989c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004bca:	00000097          	auipc	ra,0x0
    80004bce:	c4c080e7          	jalr	-948(ra) # 80004816 <write_head>
    80004bd2:	bdf5                	j	80004ace <end_op+0x52>

0000000080004bd4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004bd4:	1101                	addi	sp,sp,-32
    80004bd6:	ec06                	sd	ra,24(sp)
    80004bd8:	e822                	sd	s0,16(sp)
    80004bda:	e426                	sd	s1,8(sp)
    80004bdc:	e04a                	sd	s2,0(sp)
    80004bde:	1000                	addi	s0,sp,32
    80004be0:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004be2:	00025917          	auipc	s2,0x25
    80004be6:	c8e90913          	addi	s2,s2,-882 # 80029870 <log>
    80004bea:	854a                	mv	a0,s2
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	fe6080e7          	jalr	-26(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004bf4:	02c92603          	lw	a2,44(s2)
    80004bf8:	47f5                	li	a5,29
    80004bfa:	06c7c563          	blt	a5,a2,80004c64 <log_write+0x90>
    80004bfe:	00025797          	auipc	a5,0x25
    80004c02:	c8e7a783          	lw	a5,-882(a5) # 8002988c <log+0x1c>
    80004c06:	37fd                	addiw	a5,a5,-1
    80004c08:	04f65e63          	bge	a2,a5,80004c64 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004c0c:	00025797          	auipc	a5,0x25
    80004c10:	c847a783          	lw	a5,-892(a5) # 80029890 <log+0x20>
    80004c14:	06f05063          	blez	a5,80004c74 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004c18:	4781                	li	a5,0
    80004c1a:	06c05563          	blez	a2,80004c84 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004c1e:	44cc                	lw	a1,12(s1)
    80004c20:	00025717          	auipc	a4,0x25
    80004c24:	c8070713          	addi	a4,a4,-896 # 800298a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004c28:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004c2a:	4314                	lw	a3,0(a4)
    80004c2c:	04b68c63          	beq	a3,a1,80004c84 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004c30:	2785                	addiw	a5,a5,1
    80004c32:	0711                	addi	a4,a4,4
    80004c34:	fef61be3          	bne	a2,a5,80004c2a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004c38:	0621                	addi	a2,a2,8
    80004c3a:	060a                	slli	a2,a2,0x2
    80004c3c:	00025797          	auipc	a5,0x25
    80004c40:	c3478793          	addi	a5,a5,-972 # 80029870 <log>
    80004c44:	963e                	add	a2,a2,a5
    80004c46:	44dc                	lw	a5,12(s1)
    80004c48:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	a92080e7          	jalr	-1390(ra) # 800036de <bpin>
    log.lh.n++;
    80004c54:	00025717          	auipc	a4,0x25
    80004c58:	c1c70713          	addi	a4,a4,-996 # 80029870 <log>
    80004c5c:	575c                	lw	a5,44(a4)
    80004c5e:	2785                	addiw	a5,a5,1
    80004c60:	d75c                	sw	a5,44(a4)
    80004c62:	a835                	j	80004c9e <log_write+0xca>
    panic("too big a transaction");
    80004c64:	00004517          	auipc	a0,0x4
    80004c68:	afc50513          	addi	a0,a0,-1284 # 80008760 <syscalls+0x260>
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	8be080e7          	jalr	-1858(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004c74:	00004517          	auipc	a0,0x4
    80004c78:	b0450513          	addi	a0,a0,-1276 # 80008778 <syscalls+0x278>
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	8ae080e7          	jalr	-1874(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004c84:	00878713          	addi	a4,a5,8
    80004c88:	00271693          	slli	a3,a4,0x2
    80004c8c:	00025717          	auipc	a4,0x25
    80004c90:	be470713          	addi	a4,a4,-1052 # 80029870 <log>
    80004c94:	9736                	add	a4,a4,a3
    80004c96:	44d4                	lw	a3,12(s1)
    80004c98:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c9a:	faf608e3          	beq	a2,a5,80004c4a <log_write+0x76>
  }
  release(&log.lock);
    80004c9e:	00025517          	auipc	a0,0x25
    80004ca2:	bd250513          	addi	a0,a0,-1070 # 80029870 <log>
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	fe0080e7          	jalr	-32(ra) # 80000c86 <release>
}
    80004cae:	60e2                	ld	ra,24(sp)
    80004cb0:	6442                	ld	s0,16(sp)
    80004cb2:	64a2                	ld	s1,8(sp)
    80004cb4:	6902                	ld	s2,0(sp)
    80004cb6:	6105                	addi	sp,sp,32
    80004cb8:	8082                	ret

0000000080004cba <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004cba:	1101                	addi	sp,sp,-32
    80004cbc:	ec06                	sd	ra,24(sp)
    80004cbe:	e822                	sd	s0,16(sp)
    80004cc0:	e426                	sd	s1,8(sp)
    80004cc2:	e04a                	sd	s2,0(sp)
    80004cc4:	1000                	addi	s0,sp,32
    80004cc6:	84aa                	mv	s1,a0
    80004cc8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004cca:	00004597          	auipc	a1,0x4
    80004cce:	ace58593          	addi	a1,a1,-1330 # 80008798 <syscalls+0x298>
    80004cd2:	0521                	addi	a0,a0,8
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	e6e080e7          	jalr	-402(ra) # 80000b42 <initlock>
  lk->name = name;
    80004cdc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004ce0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ce4:	0204a423          	sw	zero,40(s1)
}
    80004ce8:	60e2                	ld	ra,24(sp)
    80004cea:	6442                	ld	s0,16(sp)
    80004cec:	64a2                	ld	s1,8(sp)
    80004cee:	6902                	ld	s2,0(sp)
    80004cf0:	6105                	addi	sp,sp,32
    80004cf2:	8082                	ret

0000000080004cf4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004cf4:	1101                	addi	sp,sp,-32
    80004cf6:	ec06                	sd	ra,24(sp)
    80004cf8:	e822                	sd	s0,16(sp)
    80004cfa:	e426                	sd	s1,8(sp)
    80004cfc:	e04a                	sd	s2,0(sp)
    80004cfe:	1000                	addi	s0,sp,32
    80004d00:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d02:	00850913          	addi	s2,a0,8
    80004d06:	854a                	mv	a0,s2
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	eca080e7          	jalr	-310(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80004d10:	409c                	lw	a5,0(s1)
    80004d12:	cb89                	beqz	a5,80004d24 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004d14:	85ca                	mv	a1,s2
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffe097          	auipc	ra,0xffffe
    80004d1c:	a64080e7          	jalr	-1436(ra) # 8000277c <sleep>
  while (lk->locked) {
    80004d20:	409c                	lw	a5,0(s1)
    80004d22:	fbed                	bnez	a5,80004d14 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004d24:	4785                	li	a5,1
    80004d26:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004d28:	ffffd097          	auipc	ra,0xffffd
    80004d2c:	2e2080e7          	jalr	738(ra) # 8000200a <myproc>
    80004d30:	591c                	lw	a5,48(a0)
    80004d32:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004d34:	854a                	mv	a0,s2
    80004d36:	ffffc097          	auipc	ra,0xffffc
    80004d3a:	f50080e7          	jalr	-176(ra) # 80000c86 <release>
}
    80004d3e:	60e2                	ld	ra,24(sp)
    80004d40:	6442                	ld	s0,16(sp)
    80004d42:	64a2                	ld	s1,8(sp)
    80004d44:	6902                	ld	s2,0(sp)
    80004d46:	6105                	addi	sp,sp,32
    80004d48:	8082                	ret

0000000080004d4a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004d4a:	1101                	addi	sp,sp,-32
    80004d4c:	ec06                	sd	ra,24(sp)
    80004d4e:	e822                	sd	s0,16(sp)
    80004d50:	e426                	sd	s1,8(sp)
    80004d52:	e04a                	sd	s2,0(sp)
    80004d54:	1000                	addi	s0,sp,32
    80004d56:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004d58:	00850913          	addi	s2,a0,8
    80004d5c:	854a                	mv	a0,s2
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	e74080e7          	jalr	-396(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    80004d66:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d6a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d6e:	8526                	mv	a0,s1
    80004d70:	ffffe097          	auipc	ra,0xffffe
    80004d74:	b98080e7          	jalr	-1128(ra) # 80002908 <wakeup>
  release(&lk->lk);
    80004d78:	854a                	mv	a0,s2
    80004d7a:	ffffc097          	auipc	ra,0xffffc
    80004d7e:	f0c080e7          	jalr	-244(ra) # 80000c86 <release>
}
    80004d82:	60e2                	ld	ra,24(sp)
    80004d84:	6442                	ld	s0,16(sp)
    80004d86:	64a2                	ld	s1,8(sp)
    80004d88:	6902                	ld	s2,0(sp)
    80004d8a:	6105                	addi	sp,sp,32
    80004d8c:	8082                	ret

0000000080004d8e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d8e:	7179                	addi	sp,sp,-48
    80004d90:	f406                	sd	ra,40(sp)
    80004d92:	f022                	sd	s0,32(sp)
    80004d94:	ec26                	sd	s1,24(sp)
    80004d96:	e84a                	sd	s2,16(sp)
    80004d98:	e44e                	sd	s3,8(sp)
    80004d9a:	1800                	addi	s0,sp,48
    80004d9c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d9e:	00850913          	addi	s2,a0,8
    80004da2:	854a                	mv	a0,s2
    80004da4:	ffffc097          	auipc	ra,0xffffc
    80004da8:	e2e080e7          	jalr	-466(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dac:	409c                	lw	a5,0(s1)
    80004dae:	ef99                	bnez	a5,80004dcc <holdingsleep+0x3e>
    80004db0:	4481                	li	s1,0
  release(&lk->lk);
    80004db2:	854a                	mv	a0,s2
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	ed2080e7          	jalr	-302(ra) # 80000c86 <release>
  return r;
}
    80004dbc:	8526                	mv	a0,s1
    80004dbe:	70a2                	ld	ra,40(sp)
    80004dc0:	7402                	ld	s0,32(sp)
    80004dc2:	64e2                	ld	s1,24(sp)
    80004dc4:	6942                	ld	s2,16(sp)
    80004dc6:	69a2                	ld	s3,8(sp)
    80004dc8:	6145                	addi	sp,sp,48
    80004dca:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004dcc:	0284a983          	lw	s3,40(s1)
    80004dd0:	ffffd097          	auipc	ra,0xffffd
    80004dd4:	23a080e7          	jalr	570(ra) # 8000200a <myproc>
    80004dd8:	5904                	lw	s1,48(a0)
    80004dda:	413484b3          	sub	s1,s1,s3
    80004dde:	0014b493          	seqz	s1,s1
    80004de2:	bfc1                	j	80004db2 <holdingsleep+0x24>

0000000080004de4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004de4:	1141                	addi	sp,sp,-16
    80004de6:	e406                	sd	ra,8(sp)
    80004de8:	e022                	sd	s0,0(sp)
    80004dea:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004dec:	00004597          	auipc	a1,0x4
    80004df0:	9bc58593          	addi	a1,a1,-1604 # 800087a8 <syscalls+0x2a8>
    80004df4:	00025517          	auipc	a0,0x25
    80004df8:	bc450513          	addi	a0,a0,-1084 # 800299b8 <ftable>
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	d46080e7          	jalr	-698(ra) # 80000b42 <initlock>
}
    80004e04:	60a2                	ld	ra,8(sp)
    80004e06:	6402                	ld	s0,0(sp)
    80004e08:	0141                	addi	sp,sp,16
    80004e0a:	8082                	ret

0000000080004e0c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004e0c:	1101                	addi	sp,sp,-32
    80004e0e:	ec06                	sd	ra,24(sp)
    80004e10:	e822                	sd	s0,16(sp)
    80004e12:	e426                	sd	s1,8(sp)
    80004e14:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004e16:	00025517          	auipc	a0,0x25
    80004e1a:	ba250513          	addi	a0,a0,-1118 # 800299b8 <ftable>
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	db4080e7          	jalr	-588(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e26:	00025497          	auipc	s1,0x25
    80004e2a:	baa48493          	addi	s1,s1,-1110 # 800299d0 <ftable+0x18>
    80004e2e:	00026717          	auipc	a4,0x26
    80004e32:	b4270713          	addi	a4,a4,-1214 # 8002a970 <ftable+0xfb8>
    if(f->ref == 0){
    80004e36:	40dc                	lw	a5,4(s1)
    80004e38:	cf99                	beqz	a5,80004e56 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004e3a:	02848493          	addi	s1,s1,40
    80004e3e:	fee49ce3          	bne	s1,a4,80004e36 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004e42:	00025517          	auipc	a0,0x25
    80004e46:	b7650513          	addi	a0,a0,-1162 # 800299b8 <ftable>
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	e3c080e7          	jalr	-452(ra) # 80000c86 <release>
  return 0;
    80004e52:	4481                	li	s1,0
    80004e54:	a819                	j	80004e6a <filealloc+0x5e>
      f->ref = 1;
    80004e56:	4785                	li	a5,1
    80004e58:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004e5a:	00025517          	auipc	a0,0x25
    80004e5e:	b5e50513          	addi	a0,a0,-1186 # 800299b8 <ftable>
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	e24080e7          	jalr	-476(ra) # 80000c86 <release>
}
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	60e2                	ld	ra,24(sp)
    80004e6e:	6442                	ld	s0,16(sp)
    80004e70:	64a2                	ld	s1,8(sp)
    80004e72:	6105                	addi	sp,sp,32
    80004e74:	8082                	ret

0000000080004e76 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e76:	1101                	addi	sp,sp,-32
    80004e78:	ec06                	sd	ra,24(sp)
    80004e7a:	e822                	sd	s0,16(sp)
    80004e7c:	e426                	sd	s1,8(sp)
    80004e7e:	1000                	addi	s0,sp,32
    80004e80:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e82:	00025517          	auipc	a0,0x25
    80004e86:	b3650513          	addi	a0,a0,-1226 # 800299b8 <ftable>
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	d48080e7          	jalr	-696(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004e92:	40dc                	lw	a5,4(s1)
    80004e94:	02f05263          	blez	a5,80004eb8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e98:	2785                	addiw	a5,a5,1
    80004e9a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e9c:	00025517          	auipc	a0,0x25
    80004ea0:	b1c50513          	addi	a0,a0,-1252 # 800299b8 <ftable>
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	de2080e7          	jalr	-542(ra) # 80000c86 <release>
  return f;
}
    80004eac:	8526                	mv	a0,s1
    80004eae:	60e2                	ld	ra,24(sp)
    80004eb0:	6442                	ld	s0,16(sp)
    80004eb2:	64a2                	ld	s1,8(sp)
    80004eb4:	6105                	addi	sp,sp,32
    80004eb6:	8082                	ret
    panic("filedup");
    80004eb8:	00004517          	auipc	a0,0x4
    80004ebc:	8f850513          	addi	a0,a0,-1800 # 800087b0 <syscalls+0x2b0>
    80004ec0:	ffffb097          	auipc	ra,0xffffb
    80004ec4:	66a080e7          	jalr	1642(ra) # 8000052a <panic>

0000000080004ec8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ec8:	7139                	addi	sp,sp,-64
    80004eca:	fc06                	sd	ra,56(sp)
    80004ecc:	f822                	sd	s0,48(sp)
    80004ece:	f426                	sd	s1,40(sp)
    80004ed0:	f04a                	sd	s2,32(sp)
    80004ed2:	ec4e                	sd	s3,24(sp)
    80004ed4:	e852                	sd	s4,16(sp)
    80004ed6:	e456                	sd	s5,8(sp)
    80004ed8:	0080                	addi	s0,sp,64
    80004eda:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004edc:	00025517          	auipc	a0,0x25
    80004ee0:	adc50513          	addi	a0,a0,-1316 # 800299b8 <ftable>
    80004ee4:	ffffc097          	auipc	ra,0xffffc
    80004ee8:	cee080e7          	jalr	-786(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80004eec:	40dc                	lw	a5,4(s1)
    80004eee:	06f05163          	blez	a5,80004f50 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ef2:	37fd                	addiw	a5,a5,-1
    80004ef4:	0007871b          	sext.w	a4,a5
    80004ef8:	c0dc                	sw	a5,4(s1)
    80004efa:	06e04363          	bgtz	a4,80004f60 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004efe:	0004a903          	lw	s2,0(s1)
    80004f02:	0094ca83          	lbu	s5,9(s1)
    80004f06:	0104ba03          	ld	s4,16(s1)
    80004f0a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004f0e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004f12:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004f16:	00025517          	auipc	a0,0x25
    80004f1a:	aa250513          	addi	a0,a0,-1374 # 800299b8 <ftable>
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	d68080e7          	jalr	-664(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    80004f26:	4785                	li	a5,1
    80004f28:	04f90d63          	beq	s2,a5,80004f82 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004f2c:	3979                	addiw	s2,s2,-2
    80004f2e:	4785                	li	a5,1
    80004f30:	0527e063          	bltu	a5,s2,80004f70 <fileclose+0xa8>
    begin_op();
    80004f34:	00000097          	auipc	ra,0x0
    80004f38:	ac8080e7          	jalr	-1336(ra) # 800049fc <begin_op>
    iput(ff.ip);
    80004f3c:	854e                	mv	a0,s3
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	f90080e7          	jalr	-112(ra) # 80003ece <iput>
    end_op();
    80004f46:	00000097          	auipc	ra,0x0
    80004f4a:	b36080e7          	jalr	-1226(ra) # 80004a7c <end_op>
    80004f4e:	a00d                	j	80004f70 <fileclose+0xa8>
    panic("fileclose");
    80004f50:	00004517          	auipc	a0,0x4
    80004f54:	86850513          	addi	a0,a0,-1944 # 800087b8 <syscalls+0x2b8>
    80004f58:	ffffb097          	auipc	ra,0xffffb
    80004f5c:	5d2080e7          	jalr	1490(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004f60:	00025517          	auipc	a0,0x25
    80004f64:	a5850513          	addi	a0,a0,-1448 # 800299b8 <ftable>
    80004f68:	ffffc097          	auipc	ra,0xffffc
    80004f6c:	d1e080e7          	jalr	-738(ra) # 80000c86 <release>
  }
}
    80004f70:	70e2                	ld	ra,56(sp)
    80004f72:	7442                	ld	s0,48(sp)
    80004f74:	74a2                	ld	s1,40(sp)
    80004f76:	7902                	ld	s2,32(sp)
    80004f78:	69e2                	ld	s3,24(sp)
    80004f7a:	6a42                	ld	s4,16(sp)
    80004f7c:	6aa2                	ld	s5,8(sp)
    80004f7e:	6121                	addi	sp,sp,64
    80004f80:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f82:	85d6                	mv	a1,s5
    80004f84:	8552                	mv	a0,s4
    80004f86:	00000097          	auipc	ra,0x0
    80004f8a:	542080e7          	jalr	1346(ra) # 800054c8 <pipeclose>
    80004f8e:	b7cd                	j	80004f70 <fileclose+0xa8>

0000000080004f90 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f90:	715d                	addi	sp,sp,-80
    80004f92:	e486                	sd	ra,72(sp)
    80004f94:	e0a2                	sd	s0,64(sp)
    80004f96:	fc26                	sd	s1,56(sp)
    80004f98:	f84a                	sd	s2,48(sp)
    80004f9a:	f44e                	sd	s3,40(sp)
    80004f9c:	0880                	addi	s0,sp,80
    80004f9e:	84aa                	mv	s1,a0
    80004fa0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004fa2:	ffffd097          	auipc	ra,0xffffd
    80004fa6:	068080e7          	jalr	104(ra) # 8000200a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004faa:	409c                	lw	a5,0(s1)
    80004fac:	37f9                	addiw	a5,a5,-2
    80004fae:	4705                	li	a4,1
    80004fb0:	04f76763          	bltu	a4,a5,80004ffe <filestat+0x6e>
    80004fb4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004fb6:	6c88                	ld	a0,24(s1)
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	d5c080e7          	jalr	-676(ra) # 80003d14 <ilock>
    stati(f->ip, &st);
    80004fc0:	fb840593          	addi	a1,s0,-72
    80004fc4:	6c88                	ld	a0,24(s1)
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	fd8080e7          	jalr	-40(ra) # 80003f9e <stati>
    iunlock(f->ip);
    80004fce:	6c88                	ld	a0,24(s1)
    80004fd0:	fffff097          	auipc	ra,0xfffff
    80004fd4:	e06080e7          	jalr	-506(ra) # 80003dd6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004fd8:	46e1                	li	a3,24
    80004fda:	fb840613          	addi	a2,s0,-72
    80004fde:	85ce                	mv	a1,s3
    80004fe0:	05093503          	ld	a0,80(s2)
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	61a080e7          	jalr	1562(ra) # 800015fe <copyout>
    80004fec:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ff0:	60a6                	ld	ra,72(sp)
    80004ff2:	6406                	ld	s0,64(sp)
    80004ff4:	74e2                	ld	s1,56(sp)
    80004ff6:	7942                	ld	s2,48(sp)
    80004ff8:	79a2                	ld	s3,40(sp)
    80004ffa:	6161                	addi	sp,sp,80
    80004ffc:	8082                	ret
  return -1;
    80004ffe:	557d                	li	a0,-1
    80005000:	bfc5                	j	80004ff0 <filestat+0x60>

0000000080005002 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005002:	7179                	addi	sp,sp,-48
    80005004:	f406                	sd	ra,40(sp)
    80005006:	f022                	sd	s0,32(sp)
    80005008:	ec26                	sd	s1,24(sp)
    8000500a:	e84a                	sd	s2,16(sp)
    8000500c:	e44e                	sd	s3,8(sp)
    8000500e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005010:	00854783          	lbu	a5,8(a0)
    80005014:	c3d5                	beqz	a5,800050b8 <fileread+0xb6>
    80005016:	84aa                	mv	s1,a0
    80005018:	89ae                	mv	s3,a1
    8000501a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000501c:	411c                	lw	a5,0(a0)
    8000501e:	4705                	li	a4,1
    80005020:	04e78963          	beq	a5,a4,80005072 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005024:	470d                	li	a4,3
    80005026:	04e78d63          	beq	a5,a4,80005080 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000502a:	4709                	li	a4,2
    8000502c:	06e79e63          	bne	a5,a4,800050a8 <fileread+0xa6>
    ilock(f->ip);
    80005030:	6d08                	ld	a0,24(a0)
    80005032:	fffff097          	auipc	ra,0xfffff
    80005036:	ce2080e7          	jalr	-798(ra) # 80003d14 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000503a:	874a                	mv	a4,s2
    8000503c:	5094                	lw	a3,32(s1)
    8000503e:	864e                	mv	a2,s3
    80005040:	4585                	li	a1,1
    80005042:	6c88                	ld	a0,24(s1)
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	f84080e7          	jalr	-124(ra) # 80003fc8 <readi>
    8000504c:	892a                	mv	s2,a0
    8000504e:	00a05563          	blez	a0,80005058 <fileread+0x56>
      f->off += r;
    80005052:	509c                	lw	a5,32(s1)
    80005054:	9fa9                	addw	a5,a5,a0
    80005056:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005058:	6c88                	ld	a0,24(s1)
    8000505a:	fffff097          	auipc	ra,0xfffff
    8000505e:	d7c080e7          	jalr	-644(ra) # 80003dd6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005062:	854a                	mv	a0,s2
    80005064:	70a2                	ld	ra,40(sp)
    80005066:	7402                	ld	s0,32(sp)
    80005068:	64e2                	ld	s1,24(sp)
    8000506a:	6942                	ld	s2,16(sp)
    8000506c:	69a2                	ld	s3,8(sp)
    8000506e:	6145                	addi	sp,sp,48
    80005070:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005072:	6908                	ld	a0,16(a0)
    80005074:	00000097          	auipc	ra,0x0
    80005078:	5b6080e7          	jalr	1462(ra) # 8000562a <piperead>
    8000507c:	892a                	mv	s2,a0
    8000507e:	b7d5                	j	80005062 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005080:	02451783          	lh	a5,36(a0)
    80005084:	03079693          	slli	a3,a5,0x30
    80005088:	92c1                	srli	a3,a3,0x30
    8000508a:	4725                	li	a4,9
    8000508c:	02d76863          	bltu	a4,a3,800050bc <fileread+0xba>
    80005090:	0792                	slli	a5,a5,0x4
    80005092:	00025717          	auipc	a4,0x25
    80005096:	88670713          	addi	a4,a4,-1914 # 80029918 <devsw>
    8000509a:	97ba                	add	a5,a5,a4
    8000509c:	639c                	ld	a5,0(a5)
    8000509e:	c38d                	beqz	a5,800050c0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800050a0:	4505                	li	a0,1
    800050a2:	9782                	jalr	a5
    800050a4:	892a                	mv	s2,a0
    800050a6:	bf75                	j	80005062 <fileread+0x60>
    panic("fileread");
    800050a8:	00003517          	auipc	a0,0x3
    800050ac:	72050513          	addi	a0,a0,1824 # 800087c8 <syscalls+0x2c8>
    800050b0:	ffffb097          	auipc	ra,0xffffb
    800050b4:	47a080e7          	jalr	1146(ra) # 8000052a <panic>
    return -1;
    800050b8:	597d                	li	s2,-1
    800050ba:	b765                	j	80005062 <fileread+0x60>
      return -1;
    800050bc:	597d                	li	s2,-1
    800050be:	b755                	j	80005062 <fileread+0x60>
    800050c0:	597d                	li	s2,-1
    800050c2:	b745                	j	80005062 <fileread+0x60>

00000000800050c4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800050c4:	715d                	addi	sp,sp,-80
    800050c6:	e486                	sd	ra,72(sp)
    800050c8:	e0a2                	sd	s0,64(sp)
    800050ca:	fc26                	sd	s1,56(sp)
    800050cc:	f84a                	sd	s2,48(sp)
    800050ce:	f44e                	sd	s3,40(sp)
    800050d0:	f052                	sd	s4,32(sp)
    800050d2:	ec56                	sd	s5,24(sp)
    800050d4:	e85a                	sd	s6,16(sp)
    800050d6:	e45e                	sd	s7,8(sp)
    800050d8:	e062                	sd	s8,0(sp)
    800050da:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800050dc:	00954783          	lbu	a5,9(a0)
    800050e0:	10078663          	beqz	a5,800051ec <filewrite+0x128>
    800050e4:	892a                	mv	s2,a0
    800050e6:	8aae                	mv	s5,a1
    800050e8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800050ea:	411c                	lw	a5,0(a0)
    800050ec:	4705                	li	a4,1
    800050ee:	02e78263          	beq	a5,a4,80005112 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800050f2:	470d                	li	a4,3
    800050f4:	02e78663          	beq	a5,a4,80005120 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800050f8:	4709                	li	a4,2
    800050fa:	0ee79163          	bne	a5,a4,800051dc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800050fe:	0ac05d63          	blez	a2,800051b8 <filewrite+0xf4>
    int i = 0;
    80005102:	4981                	li	s3,0
    80005104:	6b05                	lui	s6,0x1
    80005106:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000510a:	6b85                	lui	s7,0x1
    8000510c:	c00b8b9b          	addiw	s7,s7,-1024
    80005110:	a861                	j	800051a8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005112:	6908                	ld	a0,16(a0)
    80005114:	00000097          	auipc	ra,0x0
    80005118:	424080e7          	jalr	1060(ra) # 80005538 <pipewrite>
    8000511c:	8a2a                	mv	s4,a0
    8000511e:	a045                	j	800051be <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005120:	02451783          	lh	a5,36(a0)
    80005124:	03079693          	slli	a3,a5,0x30
    80005128:	92c1                	srli	a3,a3,0x30
    8000512a:	4725                	li	a4,9
    8000512c:	0cd76263          	bltu	a4,a3,800051f0 <filewrite+0x12c>
    80005130:	0792                	slli	a5,a5,0x4
    80005132:	00024717          	auipc	a4,0x24
    80005136:	7e670713          	addi	a4,a4,2022 # 80029918 <devsw>
    8000513a:	97ba                	add	a5,a5,a4
    8000513c:	679c                	ld	a5,8(a5)
    8000513e:	cbdd                	beqz	a5,800051f4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005140:	4505                	li	a0,1
    80005142:	9782                	jalr	a5
    80005144:	8a2a                	mv	s4,a0
    80005146:	a8a5                	j	800051be <filewrite+0xfa>
    80005148:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000514c:	00000097          	auipc	ra,0x0
    80005150:	8b0080e7          	jalr	-1872(ra) # 800049fc <begin_op>
      ilock(f->ip);
    80005154:	01893503          	ld	a0,24(s2)
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	bbc080e7          	jalr	-1092(ra) # 80003d14 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005160:	8762                	mv	a4,s8
    80005162:	02092683          	lw	a3,32(s2)
    80005166:	01598633          	add	a2,s3,s5
    8000516a:	4585                	li	a1,1
    8000516c:	01893503          	ld	a0,24(s2)
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	f50080e7          	jalr	-176(ra) # 800040c0 <writei>
    80005178:	84aa                	mv	s1,a0
    8000517a:	00a05763          	blez	a0,80005188 <filewrite+0xc4>
        f->off += r;
    8000517e:	02092783          	lw	a5,32(s2)
    80005182:	9fa9                	addw	a5,a5,a0
    80005184:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005188:	01893503          	ld	a0,24(s2)
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	c4a080e7          	jalr	-950(ra) # 80003dd6 <iunlock>
      end_op();
    80005194:	00000097          	auipc	ra,0x0
    80005198:	8e8080e7          	jalr	-1816(ra) # 80004a7c <end_op>

      if(r != n1){
    8000519c:	009c1f63          	bne	s8,s1,800051ba <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800051a0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800051a4:	0149db63          	bge	s3,s4,800051ba <filewrite+0xf6>
      int n1 = n - i;
    800051a8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800051ac:	84be                	mv	s1,a5
    800051ae:	2781                	sext.w	a5,a5
    800051b0:	f8fb5ce3          	bge	s6,a5,80005148 <filewrite+0x84>
    800051b4:	84de                	mv	s1,s7
    800051b6:	bf49                	j	80005148 <filewrite+0x84>
    int i = 0;
    800051b8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800051ba:	013a1f63          	bne	s4,s3,800051d8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800051be:	8552                	mv	a0,s4
    800051c0:	60a6                	ld	ra,72(sp)
    800051c2:	6406                	ld	s0,64(sp)
    800051c4:	74e2                	ld	s1,56(sp)
    800051c6:	7942                	ld	s2,48(sp)
    800051c8:	79a2                	ld	s3,40(sp)
    800051ca:	7a02                	ld	s4,32(sp)
    800051cc:	6ae2                	ld	s5,24(sp)
    800051ce:	6b42                	ld	s6,16(sp)
    800051d0:	6ba2                	ld	s7,8(sp)
    800051d2:	6c02                	ld	s8,0(sp)
    800051d4:	6161                	addi	sp,sp,80
    800051d6:	8082                	ret
    ret = (i == n ? n : -1);
    800051d8:	5a7d                	li	s4,-1
    800051da:	b7d5                	j	800051be <filewrite+0xfa>
    panic("filewrite");
    800051dc:	00003517          	auipc	a0,0x3
    800051e0:	5fc50513          	addi	a0,a0,1532 # 800087d8 <syscalls+0x2d8>
    800051e4:	ffffb097          	auipc	ra,0xffffb
    800051e8:	346080e7          	jalr	838(ra) # 8000052a <panic>
    return -1;
    800051ec:	5a7d                	li	s4,-1
    800051ee:	bfc1                	j	800051be <filewrite+0xfa>
      return -1;
    800051f0:	5a7d                	li	s4,-1
    800051f2:	b7f1                	j	800051be <filewrite+0xfa>
    800051f4:	5a7d                	li	s4,-1
    800051f6:	b7e1                	j	800051be <filewrite+0xfa>

00000000800051f8 <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    800051f8:	7179                	addi	sp,sp,-48
    800051fa:	f406                	sd	ra,40(sp)
    800051fc:	f022                	sd	s0,32(sp)
    800051fe:	ec26                	sd	s1,24(sp)
    80005200:	e84a                	sd	s2,16(sp)
    80005202:	e44e                	sd	s3,8(sp)
    80005204:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005206:	00854783          	lbu	a5,8(a0)
    8000520a:	c3d5                	beqz	a5,800052ae <kfileread+0xb6>
    8000520c:	84aa                	mv	s1,a0
    8000520e:	89ae                	mv	s3,a1
    80005210:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005212:	411c                	lw	a5,0(a0)
    80005214:	4705                	li	a4,1
    80005216:	04e78963          	beq	a5,a4,80005268 <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000521a:	470d                	li	a4,3
    8000521c:	04e78d63          	beq	a5,a4,80005276 <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005220:	4709                	li	a4,2
    80005222:	06e79e63          	bne	a5,a4,8000529e <kfileread+0xa6>
    ilock(f->ip);
    80005226:	6d08                	ld	a0,24(a0)
    80005228:	fffff097          	auipc	ra,0xfffff
    8000522c:	aec080e7          	jalr	-1300(ra) # 80003d14 <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005230:	874a                	mv	a4,s2
    80005232:	5094                	lw	a3,32(s1)
    80005234:	864e                	mv	a2,s3
    80005236:	4581                	li	a1,0
    80005238:	6c88                	ld	a0,24(s1)
    8000523a:	fffff097          	auipc	ra,0xfffff
    8000523e:	d8e080e7          	jalr	-626(ra) # 80003fc8 <readi>
    80005242:	892a                	mv	s2,a0
    80005244:	00a05563          	blez	a0,8000524e <kfileread+0x56>
      f->off += r;
    80005248:	509c                	lw	a5,32(s1)
    8000524a:	9fa9                	addw	a5,a5,a0
    8000524c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000524e:	6c88                	ld	a0,24(s1)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	b86080e7          	jalr	-1146(ra) # 80003dd6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005258:	854a                	mv	a0,s2
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	64e2                	ld	s1,24(sp)
    80005260:	6942                	ld	s2,16(sp)
    80005262:	69a2                	ld	s3,8(sp)
    80005264:	6145                	addi	sp,sp,48
    80005266:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005268:	6908                	ld	a0,16(a0)
    8000526a:	00000097          	auipc	ra,0x0
    8000526e:	3c0080e7          	jalr	960(ra) # 8000562a <piperead>
    80005272:	892a                	mv	s2,a0
    80005274:	b7d5                	j	80005258 <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005276:	02451783          	lh	a5,36(a0)
    8000527a:	03079693          	slli	a3,a5,0x30
    8000527e:	92c1                	srli	a3,a3,0x30
    80005280:	4725                	li	a4,9
    80005282:	02d76863          	bltu	a4,a3,800052b2 <kfileread+0xba>
    80005286:	0792                	slli	a5,a5,0x4
    80005288:	00024717          	auipc	a4,0x24
    8000528c:	69070713          	addi	a4,a4,1680 # 80029918 <devsw>
    80005290:	97ba                	add	a5,a5,a4
    80005292:	639c                	ld	a5,0(a5)
    80005294:	c38d                	beqz	a5,800052b6 <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005296:	4505                	li	a0,1
    80005298:	9782                	jalr	a5
    8000529a:	892a                	mv	s2,a0
    8000529c:	bf75                	j	80005258 <kfileread+0x60>
    panic("fileread");
    8000529e:	00003517          	auipc	a0,0x3
    800052a2:	52a50513          	addi	a0,a0,1322 # 800087c8 <syscalls+0x2c8>
    800052a6:	ffffb097          	auipc	ra,0xffffb
    800052aa:	284080e7          	jalr	644(ra) # 8000052a <panic>
    return -1;
    800052ae:	597d                	li	s2,-1
    800052b0:	b765                	j	80005258 <kfileread+0x60>
      return -1;
    800052b2:	597d                	li	s2,-1
    800052b4:	b755                	j	80005258 <kfileread+0x60>
    800052b6:	597d                	li	s2,-1
    800052b8:	b745                	j	80005258 <kfileread+0x60>

00000000800052ba <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800052ba:	715d                	addi	sp,sp,-80
    800052bc:	e486                	sd	ra,72(sp)
    800052be:	e0a2                	sd	s0,64(sp)
    800052c0:	fc26                	sd	s1,56(sp)
    800052c2:	f84a                	sd	s2,48(sp)
    800052c4:	f44e                	sd	s3,40(sp)
    800052c6:	f052                	sd	s4,32(sp)
    800052c8:	ec56                	sd	s5,24(sp)
    800052ca:	e85a                	sd	s6,16(sp)
    800052cc:	e45e                	sd	s7,8(sp)
    800052ce:	e062                	sd	s8,0(sp)
    800052d0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    800052d2:	00954783          	lbu	a5,9(a0)
    800052d6:	10078663          	beqz	a5,800053e2 <kfilewrite+0x128>
    800052da:	892a                	mv	s2,a0
    800052dc:	8aae                	mv	s5,a1
    800052de:	8a32                	mv	s4,a2
    return -1;
  }

  if(f->type == FD_PIPE){
    800052e0:	411c                	lw	a5,0(a0)
    800052e2:	4705                	li	a4,1
    800052e4:	02e78263          	beq	a5,a4,80005308 <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800052e8:	470d                	li	a4,3
    800052ea:	02e78663          	beq	a5,a4,80005316 <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800052ee:	4709                	li	a4,2
    800052f0:	0ee79163          	bne	a5,a4,800053d2 <kfilewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800052f4:	0ac05d63          	blez	a2,800053ae <kfilewrite+0xf4>
    int i = 0;
    800052f8:	4981                	li	s3,0
    800052fa:	6b05                	lui	s6,0x1
    800052fc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005300:	6b85                	lui	s7,0x1
    80005302:	c00b8b9b          	addiw	s7,s7,-1024
    80005306:	a861                	j	8000539e <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005308:	6908                	ld	a0,16(a0)
    8000530a:	00000097          	auipc	ra,0x0
    8000530e:	22e080e7          	jalr	558(ra) # 80005538 <pipewrite>
    80005312:	8a2a                	mv	s4,a0
    80005314:	a045                	j	800053b4 <kfilewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    80005316:	02451783          	lh	a5,36(a0)
    8000531a:	03079693          	slli	a3,a5,0x30
    8000531e:	92c1                	srli	a3,a3,0x30
    80005320:	4725                	li	a4,9
    80005322:	0cd76263          	bltu	a4,a3,800053e6 <kfilewrite+0x12c>
    80005326:	0792                	slli	a5,a5,0x4
    80005328:	00024717          	auipc	a4,0x24
    8000532c:	5f070713          	addi	a4,a4,1520 # 80029918 <devsw>
    80005330:	97ba                	add	a5,a5,a4
    80005332:	679c                	ld	a5,8(a5)
    80005334:	cbdd                	beqz	a5,800053ea <kfilewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005336:	4505                	li	a0,1
    80005338:	9782                	jalr	a5
    8000533a:	8a2a                	mv	s4,a0
    8000533c:	a8a5                	j	800053b4 <kfilewrite+0xfa>
    8000533e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005342:	fffff097          	auipc	ra,0xfffff
    80005346:	6ba080e7          	jalr	1722(ra) # 800049fc <begin_op>
      ilock(f->ip);
    8000534a:	01893503          	ld	a0,24(s2)
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	9c6080e7          	jalr	-1594(ra) # 80003d14 <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80005356:	8762                	mv	a4,s8
    80005358:	02092683          	lw	a3,32(s2)
    8000535c:	01598633          	add	a2,s3,s5
    80005360:	4581                	li	a1,0
    80005362:	01893503          	ld	a0,24(s2)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	d5a080e7          	jalr	-678(ra) # 800040c0 <writei>
    8000536e:	84aa                	mv	s1,a0
    80005370:	00a05763          	blez	a0,8000537e <kfilewrite+0xc4>
        f->off += r;
    80005374:	02092783          	lw	a5,32(s2)
    80005378:	9fa9                	addw	a5,a5,a0
    8000537a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000537e:	01893503          	ld	a0,24(s2)
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	a54080e7          	jalr	-1452(ra) # 80003dd6 <iunlock>
      end_op();
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	6f2080e7          	jalr	1778(ra) # 80004a7c <end_op>

      if(r != n1){
    80005392:	009c1f63          	bne	s8,s1,800053b0 <kfilewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005396:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000539a:	0149db63          	bge	s3,s4,800053b0 <kfilewrite+0xf6>
      int n1 = n - i;
    8000539e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800053a2:	84be                	mv	s1,a5
    800053a4:	2781                	sext.w	a5,a5
    800053a6:	f8fb5ce3          	bge	s6,a5,8000533e <kfilewrite+0x84>
    800053aa:	84de                	mv	s1,s7
    800053ac:	bf49                	j	8000533e <kfilewrite+0x84>
    int i = 0;
    800053ae:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800053b0:	013a1f63          	bne	s4,s3,800053ce <kfilewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
    800053b4:	8552                	mv	a0,s4
    800053b6:	60a6                	ld	ra,72(sp)
    800053b8:	6406                	ld	s0,64(sp)
    800053ba:	74e2                	ld	s1,56(sp)
    800053bc:	7942                	ld	s2,48(sp)
    800053be:	79a2                	ld	s3,40(sp)
    800053c0:	7a02                	ld	s4,32(sp)
    800053c2:	6ae2                	ld	s5,24(sp)
    800053c4:	6b42                	ld	s6,16(sp)
    800053c6:	6ba2                	ld	s7,8(sp)
    800053c8:	6c02                	ld	s8,0(sp)
    800053ca:	6161                	addi	sp,sp,80
    800053cc:	8082                	ret
    ret = (i == n ? n : -1);
    800053ce:	5a7d                	li	s4,-1
    800053d0:	b7d5                	j	800053b4 <kfilewrite+0xfa>
    panic("filewrite");
    800053d2:	00003517          	auipc	a0,0x3
    800053d6:	40650513          	addi	a0,a0,1030 # 800087d8 <syscalls+0x2d8>
    800053da:	ffffb097          	auipc	ra,0xffffb
    800053de:	150080e7          	jalr	336(ra) # 8000052a <panic>
    return -1;
    800053e2:	5a7d                	li	s4,-1
    800053e4:	bfc1                	j	800053b4 <kfilewrite+0xfa>
      return -1;
    800053e6:	5a7d                	li	s4,-1
    800053e8:	b7f1                	j	800053b4 <kfilewrite+0xfa>
    800053ea:	5a7d                	li	s4,-1
    800053ec:	b7e1                	j	800053b4 <kfilewrite+0xfa>

00000000800053ee <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800053ee:	7179                	addi	sp,sp,-48
    800053f0:	f406                	sd	ra,40(sp)
    800053f2:	f022                	sd	s0,32(sp)
    800053f4:	ec26                	sd	s1,24(sp)
    800053f6:	e84a                	sd	s2,16(sp)
    800053f8:	e44e                	sd	s3,8(sp)
    800053fa:	e052                	sd	s4,0(sp)
    800053fc:	1800                	addi	s0,sp,48
    800053fe:	84aa                	mv	s1,a0
    80005400:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005402:	0005b023          	sd	zero,0(a1)
    80005406:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	a02080e7          	jalr	-1534(ra) # 80004e0c <filealloc>
    80005412:	e088                	sd	a0,0(s1)
    80005414:	c551                	beqz	a0,800054a0 <pipealloc+0xb2>
    80005416:	00000097          	auipc	ra,0x0
    8000541a:	9f6080e7          	jalr	-1546(ra) # 80004e0c <filealloc>
    8000541e:	00aa3023          	sd	a0,0(s4)
    80005422:	c92d                	beqz	a0,80005494 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005424:	ffffb097          	auipc	ra,0xffffb
    80005428:	6be080e7          	jalr	1726(ra) # 80000ae2 <kalloc>
    8000542c:	892a                	mv	s2,a0
    8000542e:	c125                	beqz	a0,8000548e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005430:	4985                	li	s3,1
    80005432:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005436:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000543a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000543e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005442:	00003597          	auipc	a1,0x3
    80005446:	3a658593          	addi	a1,a1,934 # 800087e8 <syscalls+0x2e8>
    8000544a:	ffffb097          	auipc	ra,0xffffb
    8000544e:	6f8080e7          	jalr	1784(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    80005452:	609c                	ld	a5,0(s1)
    80005454:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005458:	609c                	ld	a5,0(s1)
    8000545a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000545e:	609c                	ld	a5,0(s1)
    80005460:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005464:	609c                	ld	a5,0(s1)
    80005466:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000546a:	000a3783          	ld	a5,0(s4)
    8000546e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005472:	000a3783          	ld	a5,0(s4)
    80005476:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000547a:	000a3783          	ld	a5,0(s4)
    8000547e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005482:	000a3783          	ld	a5,0(s4)
    80005486:	0127b823          	sd	s2,16(a5)
  return 0;
    8000548a:	4501                	li	a0,0
    8000548c:	a025                	j	800054b4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000548e:	6088                	ld	a0,0(s1)
    80005490:	e501                	bnez	a0,80005498 <pipealloc+0xaa>
    80005492:	a039                	j	800054a0 <pipealloc+0xb2>
    80005494:	6088                	ld	a0,0(s1)
    80005496:	c51d                	beqz	a0,800054c4 <pipealloc+0xd6>
    fileclose(*f0);
    80005498:	00000097          	auipc	ra,0x0
    8000549c:	a30080e7          	jalr	-1488(ra) # 80004ec8 <fileclose>
  if(*f1)
    800054a0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800054a4:	557d                	li	a0,-1
  if(*f1)
    800054a6:	c799                	beqz	a5,800054b4 <pipealloc+0xc6>
    fileclose(*f1);
    800054a8:	853e                	mv	a0,a5
    800054aa:	00000097          	auipc	ra,0x0
    800054ae:	a1e080e7          	jalr	-1506(ra) # 80004ec8 <fileclose>
  return -1;
    800054b2:	557d                	li	a0,-1
}
    800054b4:	70a2                	ld	ra,40(sp)
    800054b6:	7402                	ld	s0,32(sp)
    800054b8:	64e2                	ld	s1,24(sp)
    800054ba:	6942                	ld	s2,16(sp)
    800054bc:	69a2                	ld	s3,8(sp)
    800054be:	6a02                	ld	s4,0(sp)
    800054c0:	6145                	addi	sp,sp,48
    800054c2:	8082                	ret
  return -1;
    800054c4:	557d                	li	a0,-1
    800054c6:	b7fd                	j	800054b4 <pipealloc+0xc6>

00000000800054c8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800054c8:	1101                	addi	sp,sp,-32
    800054ca:	ec06                	sd	ra,24(sp)
    800054cc:	e822                	sd	s0,16(sp)
    800054ce:	e426                	sd	s1,8(sp)
    800054d0:	e04a                	sd	s2,0(sp)
    800054d2:	1000                	addi	s0,sp,32
    800054d4:	84aa                	mv	s1,a0
    800054d6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800054d8:	ffffb097          	auipc	ra,0xffffb
    800054dc:	6fa080e7          	jalr	1786(ra) # 80000bd2 <acquire>
  if(writable){
    800054e0:	02090d63          	beqz	s2,8000551a <pipeclose+0x52>
    pi->writeopen = 0;
    800054e4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800054e8:	21848513          	addi	a0,s1,536
    800054ec:	ffffd097          	auipc	ra,0xffffd
    800054f0:	41c080e7          	jalr	1052(ra) # 80002908 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800054f4:	2204b783          	ld	a5,544(s1)
    800054f8:	eb95                	bnez	a5,8000552c <pipeclose+0x64>
    release(&pi->lock);
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffb097          	auipc	ra,0xffffb
    80005500:	78a080e7          	jalr	1930(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffb097          	auipc	ra,0xffffb
    8000550a:	4d0080e7          	jalr	1232(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    8000550e:	60e2                	ld	ra,24(sp)
    80005510:	6442                	ld	s0,16(sp)
    80005512:	64a2                	ld	s1,8(sp)
    80005514:	6902                	ld	s2,0(sp)
    80005516:	6105                	addi	sp,sp,32
    80005518:	8082                	ret
    pi->readopen = 0;
    8000551a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000551e:	21c48513          	addi	a0,s1,540
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	3e6080e7          	jalr	998(ra) # 80002908 <wakeup>
    8000552a:	b7e9                	j	800054f4 <pipeclose+0x2c>
    release(&pi->lock);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffb097          	auipc	ra,0xffffb
    80005532:	758080e7          	jalr	1880(ra) # 80000c86 <release>
}
    80005536:	bfe1                	j	8000550e <pipeclose+0x46>

0000000080005538 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005538:	711d                	addi	sp,sp,-96
    8000553a:	ec86                	sd	ra,88(sp)
    8000553c:	e8a2                	sd	s0,80(sp)
    8000553e:	e4a6                	sd	s1,72(sp)
    80005540:	e0ca                	sd	s2,64(sp)
    80005542:	fc4e                	sd	s3,56(sp)
    80005544:	f852                	sd	s4,48(sp)
    80005546:	f456                	sd	s5,40(sp)
    80005548:	f05a                	sd	s6,32(sp)
    8000554a:	ec5e                	sd	s7,24(sp)
    8000554c:	e862                	sd	s8,16(sp)
    8000554e:	1080                	addi	s0,sp,96
    80005550:	84aa                	mv	s1,a0
    80005552:	8aae                	mv	s5,a1
    80005554:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005556:	ffffd097          	auipc	ra,0xffffd
    8000555a:	ab4080e7          	jalr	-1356(ra) # 8000200a <myproc>
    8000555e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005560:	8526                	mv	a0,s1
    80005562:	ffffb097          	auipc	ra,0xffffb
    80005566:	670080e7          	jalr	1648(ra) # 80000bd2 <acquire>
  while(i < n){
    8000556a:	0b405363          	blez	s4,80005610 <pipewrite+0xd8>
  int i = 0;
    8000556e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005570:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005572:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005576:	21c48b93          	addi	s7,s1,540
    8000557a:	a089                	j	800055bc <pipewrite+0x84>
      release(&pi->lock);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffb097          	auipc	ra,0xffffb
    80005582:	708080e7          	jalr	1800(ra) # 80000c86 <release>
      return -1;
    80005586:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005588:	854a                	mv	a0,s2
    8000558a:	60e6                	ld	ra,88(sp)
    8000558c:	6446                	ld	s0,80(sp)
    8000558e:	64a6                	ld	s1,72(sp)
    80005590:	6906                	ld	s2,64(sp)
    80005592:	79e2                	ld	s3,56(sp)
    80005594:	7a42                	ld	s4,48(sp)
    80005596:	7aa2                	ld	s5,40(sp)
    80005598:	7b02                	ld	s6,32(sp)
    8000559a:	6be2                	ld	s7,24(sp)
    8000559c:	6c42                	ld	s8,16(sp)
    8000559e:	6125                	addi	sp,sp,96
    800055a0:	8082                	ret
      wakeup(&pi->nread);
    800055a2:	8562                	mv	a0,s8
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	364080e7          	jalr	868(ra) # 80002908 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800055ac:	85a6                	mv	a1,s1
    800055ae:	855e                	mv	a0,s7
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	1cc080e7          	jalr	460(ra) # 8000277c <sleep>
  while(i < n){
    800055b8:	05495d63          	bge	s2,s4,80005612 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    800055bc:	2204a783          	lw	a5,544(s1)
    800055c0:	dfd5                	beqz	a5,8000557c <pipewrite+0x44>
    800055c2:	0289a783          	lw	a5,40(s3)
    800055c6:	fbdd                	bnez	a5,8000557c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800055c8:	2184a783          	lw	a5,536(s1)
    800055cc:	21c4a703          	lw	a4,540(s1)
    800055d0:	2007879b          	addiw	a5,a5,512
    800055d4:	fcf707e3          	beq	a4,a5,800055a2 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800055d8:	4685                	li	a3,1
    800055da:	01590633          	add	a2,s2,s5
    800055de:	faf40593          	addi	a1,s0,-81
    800055e2:	0509b503          	ld	a0,80(s3)
    800055e6:	ffffc097          	auipc	ra,0xffffc
    800055ea:	0a4080e7          	jalr	164(ra) # 8000168a <copyin>
    800055ee:	03650263          	beq	a0,s6,80005612 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800055f2:	21c4a783          	lw	a5,540(s1)
    800055f6:	0017871b          	addiw	a4,a5,1
    800055fa:	20e4ae23          	sw	a4,540(s1)
    800055fe:	1ff7f793          	andi	a5,a5,511
    80005602:	97a6                	add	a5,a5,s1
    80005604:	faf44703          	lbu	a4,-81(s0)
    80005608:	00e78c23          	sb	a4,24(a5)
      i++;
    8000560c:	2905                	addiw	s2,s2,1
    8000560e:	b76d                	j	800055b8 <pipewrite+0x80>
  int i = 0;
    80005610:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005612:	21848513          	addi	a0,s1,536
    80005616:	ffffd097          	auipc	ra,0xffffd
    8000561a:	2f2080e7          	jalr	754(ra) # 80002908 <wakeup>
  release(&pi->lock);
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffb097          	auipc	ra,0xffffb
    80005624:	666080e7          	jalr	1638(ra) # 80000c86 <release>
  return i;
    80005628:	b785                	j	80005588 <pipewrite+0x50>

000000008000562a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000562a:	715d                	addi	sp,sp,-80
    8000562c:	e486                	sd	ra,72(sp)
    8000562e:	e0a2                	sd	s0,64(sp)
    80005630:	fc26                	sd	s1,56(sp)
    80005632:	f84a                	sd	s2,48(sp)
    80005634:	f44e                	sd	s3,40(sp)
    80005636:	f052                	sd	s4,32(sp)
    80005638:	ec56                	sd	s5,24(sp)
    8000563a:	e85a                	sd	s6,16(sp)
    8000563c:	0880                	addi	s0,sp,80
    8000563e:	84aa                	mv	s1,a0
    80005640:	892e                	mv	s2,a1
    80005642:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005644:	ffffd097          	auipc	ra,0xffffd
    80005648:	9c6080e7          	jalr	-1594(ra) # 8000200a <myproc>
    8000564c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	582080e7          	jalr	1410(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005658:	2184a703          	lw	a4,536(s1)
    8000565c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005660:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005664:	02f71463          	bne	a4,a5,8000568c <piperead+0x62>
    80005668:	2244a783          	lw	a5,548(s1)
    8000566c:	c385                	beqz	a5,8000568c <piperead+0x62>
    if(pr->killed){
    8000566e:	028a2783          	lw	a5,40(s4)
    80005672:	ebc1                	bnez	a5,80005702 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005674:	85a6                	mv	a1,s1
    80005676:	854e                	mv	a0,s3
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	104080e7          	jalr	260(ra) # 8000277c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005680:	2184a703          	lw	a4,536(s1)
    80005684:	21c4a783          	lw	a5,540(s1)
    80005688:	fef700e3          	beq	a4,a5,80005668 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000568c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000568e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005690:	05505363          	blez	s5,800056d6 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005694:	2184a783          	lw	a5,536(s1)
    80005698:	21c4a703          	lw	a4,540(s1)
    8000569c:	02f70d63          	beq	a4,a5,800056d6 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800056a0:	0017871b          	addiw	a4,a5,1
    800056a4:	20e4ac23          	sw	a4,536(s1)
    800056a8:	1ff7f793          	andi	a5,a5,511
    800056ac:	97a6                	add	a5,a5,s1
    800056ae:	0187c783          	lbu	a5,24(a5)
    800056b2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800056b6:	4685                	li	a3,1
    800056b8:	fbf40613          	addi	a2,s0,-65
    800056bc:	85ca                	mv	a1,s2
    800056be:	050a3503          	ld	a0,80(s4)
    800056c2:	ffffc097          	auipc	ra,0xffffc
    800056c6:	f3c080e7          	jalr	-196(ra) # 800015fe <copyout>
    800056ca:	01650663          	beq	a0,s6,800056d6 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800056ce:	2985                	addiw	s3,s3,1
    800056d0:	0905                	addi	s2,s2,1
    800056d2:	fd3a91e3          	bne	s5,s3,80005694 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800056d6:	21c48513          	addi	a0,s1,540
    800056da:	ffffd097          	auipc	ra,0xffffd
    800056de:	22e080e7          	jalr	558(ra) # 80002908 <wakeup>
  release(&pi->lock);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffb097          	auipc	ra,0xffffb
    800056e8:	5a2080e7          	jalr	1442(ra) # 80000c86 <release>
  return i;
}
    800056ec:	854e                	mv	a0,s3
    800056ee:	60a6                	ld	ra,72(sp)
    800056f0:	6406                	ld	s0,64(sp)
    800056f2:	74e2                	ld	s1,56(sp)
    800056f4:	7942                	ld	s2,48(sp)
    800056f6:	79a2                	ld	s3,40(sp)
    800056f8:	7a02                	ld	s4,32(sp)
    800056fa:	6ae2                	ld	s5,24(sp)
    800056fc:	6b42                	ld	s6,16(sp)
    800056fe:	6161                	addi	sp,sp,80
    80005700:	8082                	ret
      release(&pi->lock);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffb097          	auipc	ra,0xffffb
    80005708:	582080e7          	jalr	1410(ra) # 80000c86 <release>
      return -1;
    8000570c:	59fd                	li	s3,-1
    8000570e:	bff9                	j	800056ec <piperead+0xc2>

0000000080005710 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005710:	de010113          	addi	sp,sp,-544
    80005714:	20113c23          	sd	ra,536(sp)
    80005718:	20813823          	sd	s0,528(sp)
    8000571c:	20913423          	sd	s1,520(sp)
    80005720:	21213023          	sd	s2,512(sp)
    80005724:	ffce                	sd	s3,504(sp)
    80005726:	fbd2                	sd	s4,496(sp)
    80005728:	f7d6                	sd	s5,488(sp)
    8000572a:	f3da                	sd	s6,480(sp)
    8000572c:	efde                	sd	s7,472(sp)
    8000572e:	ebe2                	sd	s8,464(sp)
    80005730:	e7e6                	sd	s9,456(sp)
    80005732:	e3ea                	sd	s10,448(sp)
    80005734:	ff6e                	sd	s11,440(sp)
    80005736:	1400                	addi	s0,sp,544
    80005738:	892a                	mv	s2,a0
    8000573a:	dea43423          	sd	a0,-536(s0)
    8000573e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005742:	ffffd097          	auipc	ra,0xffffd
    80005746:	8c8080e7          	jalr	-1848(ra) # 8000200a <myproc>
    8000574a:	84aa                	mv	s1,a0

  begin_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	2b0080e7          	jalr	688(ra) # 800049fc <begin_op>

  if((ip = namei(path)) == 0){
    80005754:	854a                	mv	a0,s2
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	d74080e7          	jalr	-652(ra) # 800044ca <namei>
    8000575e:	c93d                	beqz	a0,800057d4 <exec+0xc4>
    80005760:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005762:	ffffe097          	auipc	ra,0xffffe
    80005766:	5b2080e7          	jalr	1458(ra) # 80003d14 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000576a:	04000713          	li	a4,64
    8000576e:	4681                	li	a3,0
    80005770:	e4840613          	addi	a2,s0,-440
    80005774:	4581                	li	a1,0
    80005776:	8556                	mv	a0,s5
    80005778:	fffff097          	auipc	ra,0xfffff
    8000577c:	850080e7          	jalr	-1968(ra) # 80003fc8 <readi>
    80005780:	04000793          	li	a5,64
    80005784:	00f51a63          	bne	a0,a5,80005798 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005788:	e4842703          	lw	a4,-440(s0)
    8000578c:	464c47b7          	lui	a5,0x464c4
    80005790:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005794:	04f70663          	beq	a4,a5,800057e0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005798:	8556                	mv	a0,s5
    8000579a:	ffffe097          	auipc	ra,0xffffe
    8000579e:	7dc080e7          	jalr	2012(ra) # 80003f76 <iunlockput>
    end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	2da080e7          	jalr	730(ra) # 80004a7c <end_op>
  }
  return -1;
    800057aa:	557d                	li	a0,-1
}
    800057ac:	21813083          	ld	ra,536(sp)
    800057b0:	21013403          	ld	s0,528(sp)
    800057b4:	20813483          	ld	s1,520(sp)
    800057b8:	20013903          	ld	s2,512(sp)
    800057bc:	79fe                	ld	s3,504(sp)
    800057be:	7a5e                	ld	s4,496(sp)
    800057c0:	7abe                	ld	s5,488(sp)
    800057c2:	7b1e                	ld	s6,480(sp)
    800057c4:	6bfe                	ld	s7,472(sp)
    800057c6:	6c5e                	ld	s8,464(sp)
    800057c8:	6cbe                	ld	s9,456(sp)
    800057ca:	6d1e                	ld	s10,448(sp)
    800057cc:	7dfa                	ld	s11,440(sp)
    800057ce:	22010113          	addi	sp,sp,544
    800057d2:	8082                	ret
    end_op();
    800057d4:	fffff097          	auipc	ra,0xfffff
    800057d8:	2a8080e7          	jalr	680(ra) # 80004a7c <end_op>
    return -1;
    800057dc:	557d                	li	a0,-1
    800057de:	b7f9                	j	800057ac <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800057e0:	8526                	mv	a0,s1
    800057e2:	ffffd097          	auipc	ra,0xffffd
    800057e6:	8ec080e7          	jalr	-1812(ra) # 800020ce <proc_pagetable>
    800057ea:	8b2a                	mv	s6,a0
    800057ec:	d555                	beqz	a0,80005798 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057ee:	e6842783          	lw	a5,-408(s0)
    800057f2:	e8045703          	lhu	a4,-384(s0)
    800057f6:	c735                	beqz	a4,80005862 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800057f8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057fa:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800057fe:	6a05                	lui	s4,0x1
    80005800:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005804:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005808:	6d85                	lui	s11,0x1
    8000580a:	7d7d                	lui	s10,0xfffff
    8000580c:	ac1d                	j	80005a42 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000580e:	00003517          	auipc	a0,0x3
    80005812:	fe250513          	addi	a0,a0,-30 # 800087f0 <syscalls+0x2f0>
    80005816:	ffffb097          	auipc	ra,0xffffb
    8000581a:	d14080e7          	jalr	-748(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000581e:	874a                	mv	a4,s2
    80005820:	009c86bb          	addw	a3,s9,s1
    80005824:	4581                	li	a1,0
    80005826:	8556                	mv	a0,s5
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	7a0080e7          	jalr	1952(ra) # 80003fc8 <readi>
    80005830:	2501                	sext.w	a0,a0
    80005832:	1aa91863          	bne	s2,a0,800059e2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005836:	009d84bb          	addw	s1,s11,s1
    8000583a:	013d09bb          	addw	s3,s10,s3
    8000583e:	1f74f263          	bgeu	s1,s7,80005a22 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005842:	02049593          	slli	a1,s1,0x20
    80005846:	9181                	srli	a1,a1,0x20
    80005848:	95e2                	add	a1,a1,s8
    8000584a:	855a                	mv	a0,s6
    8000584c:	ffffb097          	auipc	ra,0xffffb
    80005850:	7fa080e7          	jalr	2042(ra) # 80001046 <walkaddr>
    80005854:	862a                	mv	a2,a0
    if(pa == 0)
    80005856:	dd45                	beqz	a0,8000580e <exec+0xfe>
      n = PGSIZE;
    80005858:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000585a:	fd49f2e3          	bgeu	s3,s4,8000581e <exec+0x10e>
      n = sz - i;
    8000585e:	894e                	mv	s2,s3
    80005860:	bf7d                	j	8000581e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005862:	4481                	li	s1,0
  iunlockput(ip);
    80005864:	8556                	mv	a0,s5
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	710080e7          	jalr	1808(ra) # 80003f76 <iunlockput>
  end_op();
    8000586e:	fffff097          	auipc	ra,0xfffff
    80005872:	20e080e7          	jalr	526(ra) # 80004a7c <end_op>
  p = myproc();
    80005876:	ffffc097          	auipc	ra,0xffffc
    8000587a:	794080e7          	jalr	1940(ra) # 8000200a <myproc>
    8000587e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005880:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005884:	6785                	lui	a5,0x1
    80005886:	17fd                	addi	a5,a5,-1
    80005888:	94be                	add	s1,s1,a5
    8000588a:	77fd                	lui	a5,0xfffff
    8000588c:	8fe5                	and	a5,a5,s1
    8000588e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005892:	6609                	lui	a2,0x2
    80005894:	963e                	add	a2,a2,a5
    80005896:	85be                	mv	a1,a5
    80005898:	855a                	mv	a0,s6
    8000589a:	ffffc097          	auipc	ra,0xffffc
    8000589e:	b30080e7          	jalr	-1232(ra) # 800013ca <uvmalloc>
    800058a2:	8c2a                	mv	s8,a0
  ip = 0;
    800058a4:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800058a6:	12050e63          	beqz	a0,800059e2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    800058aa:	75f9                	lui	a1,0xffffe
    800058ac:	95aa                	add	a1,a1,a0
    800058ae:	855a                	mv	a0,s6
    800058b0:	ffffc097          	auipc	ra,0xffffc
    800058b4:	d1c080e7          	jalr	-740(ra) # 800015cc <uvmclear>
  stackbase = sp - PGSIZE;
    800058b8:	7afd                	lui	s5,0xfffff
    800058ba:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800058bc:	df043783          	ld	a5,-528(s0)
    800058c0:	6388                	ld	a0,0(a5)
    800058c2:	c925                	beqz	a0,80005932 <exec+0x222>
    800058c4:	e8840993          	addi	s3,s0,-376
    800058c8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800058cc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800058ce:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058d0:	ffffb097          	auipc	ra,0xffffb
    800058d4:	582080e7          	jalr	1410(ra) # 80000e52 <strlen>
    800058d8:	0015079b          	addiw	a5,a0,1
    800058dc:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058e0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800058e4:	13596363          	bltu	s2,s5,80005a0a <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058e8:	df043d83          	ld	s11,-528(s0)
    800058ec:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800058f0:	8552                	mv	a0,s4
    800058f2:	ffffb097          	auipc	ra,0xffffb
    800058f6:	560080e7          	jalr	1376(ra) # 80000e52 <strlen>
    800058fa:	0015069b          	addiw	a3,a0,1
    800058fe:	8652                	mv	a2,s4
    80005900:	85ca                	mv	a1,s2
    80005902:	855a                	mv	a0,s6
    80005904:	ffffc097          	auipc	ra,0xffffc
    80005908:	cfa080e7          	jalr	-774(ra) # 800015fe <copyout>
    8000590c:	10054363          	bltz	a0,80005a12 <exec+0x302>
    ustack[argc] = sp;
    80005910:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005914:	0485                	addi	s1,s1,1
    80005916:	008d8793          	addi	a5,s11,8
    8000591a:	def43823          	sd	a5,-528(s0)
    8000591e:	008db503          	ld	a0,8(s11)
    80005922:	c911                	beqz	a0,80005936 <exec+0x226>
    if(argc >= MAXARG)
    80005924:	09a1                	addi	s3,s3,8
    80005926:	fb3c95e3          	bne	s9,s3,800058d0 <exec+0x1c0>
  sz = sz1;
    8000592a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000592e:	4a81                	li	s5,0
    80005930:	a84d                	j	800059e2 <exec+0x2d2>
  sp = sz;
    80005932:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005934:	4481                	li	s1,0
  ustack[argc] = 0;
    80005936:	00349793          	slli	a5,s1,0x3
    8000593a:	f9040713          	addi	a4,s0,-112
    8000593e:	97ba                	add	a5,a5,a4
    80005940:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd0ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005944:	00148693          	addi	a3,s1,1
    80005948:	068e                	slli	a3,a3,0x3
    8000594a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000594e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005952:	01597663          	bgeu	s2,s5,8000595e <exec+0x24e>
  sz = sz1;
    80005956:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000595a:	4a81                	li	s5,0
    8000595c:	a059                	j	800059e2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000595e:	e8840613          	addi	a2,s0,-376
    80005962:	85ca                	mv	a1,s2
    80005964:	855a                	mv	a0,s6
    80005966:	ffffc097          	auipc	ra,0xffffc
    8000596a:	c98080e7          	jalr	-872(ra) # 800015fe <copyout>
    8000596e:	0a054663          	bltz	a0,80005a1a <exec+0x30a>
  p->trapframe->a1 = sp;
    80005972:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005976:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000597a:	de843783          	ld	a5,-536(s0)
    8000597e:	0007c703          	lbu	a4,0(a5)
    80005982:	cf11                	beqz	a4,8000599e <exec+0x28e>
    80005984:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005986:	02f00693          	li	a3,47
    8000598a:	a039                	j	80005998 <exec+0x288>
      last = s+1;
    8000598c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005990:	0785                	addi	a5,a5,1
    80005992:	fff7c703          	lbu	a4,-1(a5)
    80005996:	c701                	beqz	a4,8000599e <exec+0x28e>
    if(*s == '/')
    80005998:	fed71ce3          	bne	a4,a3,80005990 <exec+0x280>
    8000599c:	bfc5                	j	8000598c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000599e:	4641                	li	a2,16
    800059a0:	de843583          	ld	a1,-536(s0)
    800059a4:	158b8513          	addi	a0,s7,344
    800059a8:	ffffb097          	auipc	ra,0xffffb
    800059ac:	478080e7          	jalr	1144(ra) # 80000e20 <safestrcpy>
  oldpagetable = p->pagetable;
    800059b0:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800059b4:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800059b8:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800059bc:	058bb783          	ld	a5,88(s7)
    800059c0:	e6043703          	ld	a4,-416(s0)
    800059c4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800059c6:	058bb783          	ld	a5,88(s7)
    800059ca:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059ce:	85ea                	mv	a1,s10
    800059d0:	ffffc097          	auipc	ra,0xffffc
    800059d4:	79a080e7          	jalr	1946(ra) # 8000216a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059d8:	0004851b          	sext.w	a0,s1
    800059dc:	bbc1                	j	800057ac <exec+0x9c>
    800059de:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800059e2:	df843583          	ld	a1,-520(s0)
    800059e6:	855a                	mv	a0,s6
    800059e8:	ffffc097          	auipc	ra,0xffffc
    800059ec:	782080e7          	jalr	1922(ra) # 8000216a <proc_freepagetable>
  if(ip){
    800059f0:	da0a94e3          	bnez	s5,80005798 <exec+0x88>
  return -1;
    800059f4:	557d                	li	a0,-1
    800059f6:	bb5d                	j	800057ac <exec+0x9c>
    800059f8:	de943c23          	sd	s1,-520(s0)
    800059fc:	b7dd                	j	800059e2 <exec+0x2d2>
    800059fe:	de943c23          	sd	s1,-520(s0)
    80005a02:	b7c5                	j	800059e2 <exec+0x2d2>
    80005a04:	de943c23          	sd	s1,-520(s0)
    80005a08:	bfe9                	j	800059e2 <exec+0x2d2>
  sz = sz1;
    80005a0a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a0e:	4a81                	li	s5,0
    80005a10:	bfc9                	j	800059e2 <exec+0x2d2>
  sz = sz1;
    80005a12:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a16:	4a81                	li	s5,0
    80005a18:	b7e9                	j	800059e2 <exec+0x2d2>
  sz = sz1;
    80005a1a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005a1e:	4a81                	li	s5,0
    80005a20:	b7c9                	j	800059e2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a22:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005a26:	e0843783          	ld	a5,-504(s0)
    80005a2a:	0017869b          	addiw	a3,a5,1
    80005a2e:	e0d43423          	sd	a3,-504(s0)
    80005a32:	e0043783          	ld	a5,-512(s0)
    80005a36:	0387879b          	addiw	a5,a5,56
    80005a3a:	e8045703          	lhu	a4,-384(s0)
    80005a3e:	e2e6d3e3          	bge	a3,a4,80005864 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005a42:	2781                	sext.w	a5,a5
    80005a44:	e0f43023          	sd	a5,-512(s0)
    80005a48:	03800713          	li	a4,56
    80005a4c:	86be                	mv	a3,a5
    80005a4e:	e1040613          	addi	a2,s0,-496
    80005a52:	4581                	li	a1,0
    80005a54:	8556                	mv	a0,s5
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	572080e7          	jalr	1394(ra) # 80003fc8 <readi>
    80005a5e:	03800793          	li	a5,56
    80005a62:	f6f51ee3          	bne	a0,a5,800059de <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005a66:	e1042783          	lw	a5,-496(s0)
    80005a6a:	4705                	li	a4,1
    80005a6c:	fae79de3          	bne	a5,a4,80005a26 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005a70:	e3843603          	ld	a2,-456(s0)
    80005a74:	e3043783          	ld	a5,-464(s0)
    80005a78:	f8f660e3          	bltu	a2,a5,800059f8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005a7c:	e2043783          	ld	a5,-480(s0)
    80005a80:	963e                	add	a2,a2,a5
    80005a82:	f6f66ee3          	bltu	a2,a5,800059fe <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005a86:	85a6                	mv	a1,s1
    80005a88:	855a                	mv	a0,s6
    80005a8a:	ffffc097          	auipc	ra,0xffffc
    80005a8e:	940080e7          	jalr	-1728(ra) # 800013ca <uvmalloc>
    80005a92:	dea43c23          	sd	a0,-520(s0)
    80005a96:	d53d                	beqz	a0,80005a04 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005a98:	e2043c03          	ld	s8,-480(s0)
    80005a9c:	de043783          	ld	a5,-544(s0)
    80005aa0:	00fc77b3          	and	a5,s8,a5
    80005aa4:	ff9d                	bnez	a5,800059e2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005aa6:	e1842c83          	lw	s9,-488(s0)
    80005aaa:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005aae:	f60b8ae3          	beqz	s7,80005a22 <exec+0x312>
    80005ab2:	89de                	mv	s3,s7
    80005ab4:	4481                	li	s1,0
    80005ab6:	b371                	j	80005842 <exec+0x132>

0000000080005ab8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005ab8:	7179                	addi	sp,sp,-48
    80005aba:	f406                	sd	ra,40(sp)
    80005abc:	f022                	sd	s0,32(sp)
    80005abe:	ec26                	sd	s1,24(sp)
    80005ac0:	e84a                	sd	s2,16(sp)
    80005ac2:	1800                	addi	s0,sp,48
    80005ac4:	892e                	mv	s2,a1
    80005ac6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005ac8:	fdc40593          	addi	a1,s0,-36
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	6d6080e7          	jalr	1750(ra) # 800031a2 <argint>
    80005ad4:	04054063          	bltz	a0,80005b14 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005ad8:	fdc42703          	lw	a4,-36(s0)
    80005adc:	47bd                	li	a5,15
    80005ade:	02e7ed63          	bltu	a5,a4,80005b18 <argfd+0x60>
    80005ae2:	ffffc097          	auipc	ra,0xffffc
    80005ae6:	528080e7          	jalr	1320(ra) # 8000200a <myproc>
    80005aea:	fdc42703          	lw	a4,-36(s0)
    80005aee:	01a70793          	addi	a5,a4,26
    80005af2:	078e                	slli	a5,a5,0x3
    80005af4:	953e                	add	a0,a0,a5
    80005af6:	611c                	ld	a5,0(a0)
    80005af8:	c395                	beqz	a5,80005b1c <argfd+0x64>
    return -1;
  if(pfd)
    80005afa:	00090463          	beqz	s2,80005b02 <argfd+0x4a>
    *pfd = fd;
    80005afe:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005b02:	4501                	li	a0,0
  if(pf)
    80005b04:	c091                	beqz	s1,80005b08 <argfd+0x50>
    *pf = f;
    80005b06:	e09c                	sd	a5,0(s1)
}
    80005b08:	70a2                	ld	ra,40(sp)
    80005b0a:	7402                	ld	s0,32(sp)
    80005b0c:	64e2                	ld	s1,24(sp)
    80005b0e:	6942                	ld	s2,16(sp)
    80005b10:	6145                	addi	sp,sp,48
    80005b12:	8082                	ret
    return -1;
    80005b14:	557d                	li	a0,-1
    80005b16:	bfcd                	j	80005b08 <argfd+0x50>
    return -1;
    80005b18:	557d                	li	a0,-1
    80005b1a:	b7fd                	j	80005b08 <argfd+0x50>
    80005b1c:	557d                	li	a0,-1
    80005b1e:	b7ed                	j	80005b08 <argfd+0x50>

0000000080005b20 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005b20:	1101                	addi	sp,sp,-32
    80005b22:	ec06                	sd	ra,24(sp)
    80005b24:	e822                	sd	s0,16(sp)
    80005b26:	e426                	sd	s1,8(sp)
    80005b28:	1000                	addi	s0,sp,32
    80005b2a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005b2c:	ffffc097          	auipc	ra,0xffffc
    80005b30:	4de080e7          	jalr	1246(ra) # 8000200a <myproc>
    80005b34:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005b36:	0d050793          	addi	a5,a0,208
    80005b3a:	4501                	li	a0,0
    80005b3c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005b3e:	6398                	ld	a4,0(a5)
    80005b40:	cb19                	beqz	a4,80005b56 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005b42:	2505                	addiw	a0,a0,1
    80005b44:	07a1                	addi	a5,a5,8
    80005b46:	fed51ce3          	bne	a0,a3,80005b3e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005b4a:	557d                	li	a0,-1
}
    80005b4c:	60e2                	ld	ra,24(sp)
    80005b4e:	6442                	ld	s0,16(sp)
    80005b50:	64a2                	ld	s1,8(sp)
    80005b52:	6105                	addi	sp,sp,32
    80005b54:	8082                	ret
      p->ofile[fd] = f;
    80005b56:	01a50793          	addi	a5,a0,26
    80005b5a:	078e                	slli	a5,a5,0x3
    80005b5c:	963e                	add	a2,a2,a5
    80005b5e:	e204                	sd	s1,0(a2)
      return fd;
    80005b60:	b7f5                	j	80005b4c <fdalloc+0x2c>

0000000080005b62 <sys_dup>:

uint64
sys_dup(void)
{
    80005b62:	7179                	addi	sp,sp,-48
    80005b64:	f406                	sd	ra,40(sp)
    80005b66:	f022                	sd	s0,32(sp)
    80005b68:	ec26                	sd	s1,24(sp)
    80005b6a:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    80005b6c:	fd840613          	addi	a2,s0,-40
    80005b70:	4581                	li	a1,0
    80005b72:	4501                	li	a0,0
    80005b74:	00000097          	auipc	ra,0x0
    80005b78:	f44080e7          	jalr	-188(ra) # 80005ab8 <argfd>
    return -1;
    80005b7c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005b7e:	02054363          	bltz	a0,80005ba4 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005b82:	fd843503          	ld	a0,-40(s0)
    80005b86:	00000097          	auipc	ra,0x0
    80005b8a:	f9a080e7          	jalr	-102(ra) # 80005b20 <fdalloc>
    80005b8e:	84aa                	mv	s1,a0
    return -1;
    80005b90:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005b92:	00054963          	bltz	a0,80005ba4 <sys_dup+0x42>
  filedup(f);
    80005b96:	fd843503          	ld	a0,-40(s0)
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	2dc080e7          	jalr	732(ra) # 80004e76 <filedup>
  return fd;
    80005ba2:	87a6                	mv	a5,s1
}
    80005ba4:	853e                	mv	a0,a5
    80005ba6:	70a2                	ld	ra,40(sp)
    80005ba8:	7402                	ld	s0,32(sp)
    80005baa:	64e2                	ld	s1,24(sp)
    80005bac:	6145                	addi	sp,sp,48
    80005bae:	8082                	ret

0000000080005bb0 <sys_read>:

uint64
sys_read(void)
{
    80005bb0:	7179                	addi	sp,sp,-48
    80005bb2:	f406                	sd	ra,40(sp)
    80005bb4:	f022                	sd	s0,32(sp)
    80005bb6:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bb8:	fe840613          	addi	a2,s0,-24
    80005bbc:	4581                	li	a1,0
    80005bbe:	4501                	li	a0,0
    80005bc0:	00000097          	auipc	ra,0x0
    80005bc4:	ef8080e7          	jalr	-264(ra) # 80005ab8 <argfd>
    return -1;
    80005bc8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bca:	04054163          	bltz	a0,80005c0c <sys_read+0x5c>
    80005bce:	fe440593          	addi	a1,s0,-28
    80005bd2:	4509                	li	a0,2
    80005bd4:	ffffd097          	auipc	ra,0xffffd
    80005bd8:	5ce080e7          	jalr	1486(ra) # 800031a2 <argint>
    return -1;
    80005bdc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bde:	02054763          	bltz	a0,80005c0c <sys_read+0x5c>
    80005be2:	fd840593          	addi	a1,s0,-40
    80005be6:	4505                	li	a0,1
    80005be8:	ffffd097          	auipc	ra,0xffffd
    80005bec:	5dc080e7          	jalr	1500(ra) # 800031c4 <argaddr>
    return -1;
    80005bf0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005bf2:	00054d63          	bltz	a0,80005c0c <sys_read+0x5c>
  return fileread(f, p, n);
    80005bf6:	fe442603          	lw	a2,-28(s0)
    80005bfa:	fd843583          	ld	a1,-40(s0)
    80005bfe:	fe843503          	ld	a0,-24(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	400080e7          	jalr	1024(ra) # 80005002 <fileread>
    80005c0a:	87aa                	mv	a5,a0
}
    80005c0c:	853e                	mv	a0,a5
    80005c0e:	70a2                	ld	ra,40(sp)
    80005c10:	7402                	ld	s0,32(sp)
    80005c12:	6145                	addi	sp,sp,48
    80005c14:	8082                	ret

0000000080005c16 <sys_write>:

uint64
sys_write(void)
{
    80005c16:	7179                	addi	sp,sp,-48
    80005c18:	f406                	sd	ra,40(sp)
    80005c1a:	f022                	sd	s0,32(sp)
    80005c1c:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c1e:	fe840613          	addi	a2,s0,-24
    80005c22:	4581                	li	a1,0
    80005c24:	4501                	li	a0,0
    80005c26:	00000097          	auipc	ra,0x0
    80005c2a:	e92080e7          	jalr	-366(ra) # 80005ab8 <argfd>
    return -1;
    80005c2e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c30:	04054163          	bltz	a0,80005c72 <sys_write+0x5c>
    80005c34:	fe440593          	addi	a1,s0,-28
    80005c38:	4509                	li	a0,2
    80005c3a:	ffffd097          	auipc	ra,0xffffd
    80005c3e:	568080e7          	jalr	1384(ra) # 800031a2 <argint>
    return -1;
    80005c42:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c44:	02054763          	bltz	a0,80005c72 <sys_write+0x5c>
    80005c48:	fd840593          	addi	a1,s0,-40
    80005c4c:	4505                	li	a0,1
    80005c4e:	ffffd097          	auipc	ra,0xffffd
    80005c52:	576080e7          	jalr	1398(ra) # 800031c4 <argaddr>
    return -1;
    80005c56:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005c58:	00054d63          	bltz	a0,80005c72 <sys_write+0x5c>

  return filewrite(f, p, n);
    80005c5c:	fe442603          	lw	a2,-28(s0)
    80005c60:	fd843583          	ld	a1,-40(s0)
    80005c64:	fe843503          	ld	a0,-24(s0)
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	45c080e7          	jalr	1116(ra) # 800050c4 <filewrite>
    80005c70:	87aa                	mv	a5,a0
}
    80005c72:	853e                	mv	a0,a5
    80005c74:	70a2                	ld	ra,40(sp)
    80005c76:	7402                	ld	s0,32(sp)
    80005c78:	6145                	addi	sp,sp,48
    80005c7a:	8082                	ret

0000000080005c7c <sys_close>:

uint64
sys_close(void)
{
    80005c7c:	1101                	addi	sp,sp,-32
    80005c7e:	ec06                	sd	ra,24(sp)
    80005c80:	e822                	sd	s0,16(sp)
    80005c82:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    80005c84:	fe040613          	addi	a2,s0,-32
    80005c88:	fec40593          	addi	a1,s0,-20
    80005c8c:	4501                	li	a0,0
    80005c8e:	00000097          	auipc	ra,0x0
    80005c92:	e2a080e7          	jalr	-470(ra) # 80005ab8 <argfd>
    return -1;
    80005c96:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005c98:	02054463          	bltz	a0,80005cc0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	36e080e7          	jalr	878(ra) # 8000200a <myproc>
    80005ca4:	fec42783          	lw	a5,-20(s0)
    80005ca8:	07e9                	addi	a5,a5,26
    80005caa:	078e                	slli	a5,a5,0x3
    80005cac:	97aa                	add	a5,a5,a0
    80005cae:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005cb2:	fe043503          	ld	a0,-32(s0)
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	212080e7          	jalr	530(ra) # 80004ec8 <fileclose>
  return 0;
    80005cbe:	4781                	li	a5,0
}
    80005cc0:	853e                	mv	a0,a5
    80005cc2:	60e2                	ld	ra,24(sp)
    80005cc4:	6442                	ld	s0,16(sp)
    80005cc6:	6105                	addi	sp,sp,32
    80005cc8:	8082                	ret

0000000080005cca <sys_fstat>:

uint64
sys_fstat(void)
{
    80005cca:	1101                	addi	sp,sp,-32
    80005ccc:	ec06                	sd	ra,24(sp)
    80005cce:	e822                	sd	s0,16(sp)
    80005cd0:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cd2:	fe840613          	addi	a2,s0,-24
    80005cd6:	4581                	li	a1,0
    80005cd8:	4501                	li	a0,0
    80005cda:	00000097          	auipc	ra,0x0
    80005cde:	dde080e7          	jalr	-546(ra) # 80005ab8 <argfd>
    return -1;
    80005ce2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005ce4:	02054563          	bltz	a0,80005d0e <sys_fstat+0x44>
    80005ce8:	fe040593          	addi	a1,s0,-32
    80005cec:	4505                	li	a0,1
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	4d6080e7          	jalr	1238(ra) # 800031c4 <argaddr>
    return -1;
    80005cf6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005cf8:	00054b63          	bltz	a0,80005d0e <sys_fstat+0x44>
  return filestat(f, st);
    80005cfc:	fe043583          	ld	a1,-32(s0)
    80005d00:	fe843503          	ld	a0,-24(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	28c080e7          	jalr	652(ra) # 80004f90 <filestat>
    80005d0c:	87aa                	mv	a5,a0
}
    80005d0e:	853e                	mv	a0,a5
    80005d10:	60e2                	ld	ra,24(sp)
    80005d12:	6442                	ld	s0,16(sp)
    80005d14:	6105                	addi	sp,sp,32
    80005d16:	8082                	ret

0000000080005d18 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80005d18:	7169                	addi	sp,sp,-304
    80005d1a:	f606                	sd	ra,296(sp)
    80005d1c:	f222                	sd	s0,288(sp)
    80005d1e:	ee26                	sd	s1,280(sp)
    80005d20:	ea4a                	sd	s2,272(sp)
    80005d22:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d24:	08000613          	li	a2,128
    80005d28:	ed040593          	addi	a1,s0,-304
    80005d2c:	4501                	li	a0,0
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	4b8080e7          	jalr	1208(ra) # 800031e6 <argstr>
    return -1;
    80005d36:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d38:	10054e63          	bltz	a0,80005e54 <sys_link+0x13c>
    80005d3c:	08000613          	li	a2,128
    80005d40:	f5040593          	addi	a1,s0,-176
    80005d44:	4505                	li	a0,1
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	4a0080e7          	jalr	1184(ra) # 800031e6 <argstr>
    return -1;
    80005d4e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005d50:	10054263          	bltz	a0,80005e54 <sys_link+0x13c>

  begin_op();
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	ca8080e7          	jalr	-856(ra) # 800049fc <begin_op>
  if((ip = namei(old)) == 0){
    80005d5c:	ed040513          	addi	a0,s0,-304
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	76a080e7          	jalr	1898(ra) # 800044ca <namei>
    80005d68:	84aa                	mv	s1,a0
    80005d6a:	c551                	beqz	a0,80005df6 <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    80005d6c:	ffffe097          	auipc	ra,0xffffe
    80005d70:	fa8080e7          	jalr	-88(ra) # 80003d14 <ilock>
  if(ip->type == T_DIR){
    80005d74:	04449703          	lh	a4,68(s1)
    80005d78:	4785                	li	a5,1
    80005d7a:	08f70463          	beq	a4,a5,80005e02 <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    80005d7e:	04a4d783          	lhu	a5,74(s1)
    80005d82:	2785                	addiw	a5,a5,1
    80005d84:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d88:	8526                	mv	a0,s1
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	ec0080e7          	jalr	-320(ra) # 80003c4a <iupdate>
  iunlock(ip);
    80005d92:	8526                	mv	a0,s1
    80005d94:	ffffe097          	auipc	ra,0xffffe
    80005d98:	042080e7          	jalr	66(ra) # 80003dd6 <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    80005d9c:	fd040593          	addi	a1,s0,-48
    80005da0:	f5040513          	addi	a0,s0,-176
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	744080e7          	jalr	1860(ra) # 800044e8 <nameiparent>
    80005dac:	892a                	mv	s2,a0
    80005dae:	c935                	beqz	a0,80005e22 <sys_link+0x10a>
    goto bad;
  ilock(dp);
    80005db0:	ffffe097          	auipc	ra,0xffffe
    80005db4:	f64080e7          	jalr	-156(ra) # 80003d14 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005db8:	00092703          	lw	a4,0(s2)
    80005dbc:	409c                	lw	a5,0(s1)
    80005dbe:	04f71d63          	bne	a4,a5,80005e18 <sys_link+0x100>
    80005dc2:	40d0                	lw	a2,4(s1)
    80005dc4:	fd040593          	addi	a1,s0,-48
    80005dc8:	854a                	mv	a0,s2
    80005dca:	ffffe097          	auipc	ra,0xffffe
    80005dce:	63e080e7          	jalr	1598(ra) # 80004408 <dirlink>
    80005dd2:	04054363          	bltz	a0,80005e18 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    80005dd6:	854a                	mv	a0,s2
    80005dd8:	ffffe097          	auipc	ra,0xffffe
    80005ddc:	19e080e7          	jalr	414(ra) # 80003f76 <iunlockput>
  iput(ip);
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	0ec080e7          	jalr	236(ra) # 80003ece <iput>

  end_op();
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	c92080e7          	jalr	-878(ra) # 80004a7c <end_op>

  return 0;
    80005df2:	4781                	li	a5,0
    80005df4:	a085                	j	80005e54 <sys_link+0x13c>
    end_op();
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	c86080e7          	jalr	-890(ra) # 80004a7c <end_op>
    return -1;
    80005dfe:	57fd                	li	a5,-1
    80005e00:	a891                	j	80005e54 <sys_link+0x13c>
    iunlockput(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	172080e7          	jalr	370(ra) # 80003f76 <iunlockput>
    end_op();
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	c70080e7          	jalr	-912(ra) # 80004a7c <end_op>
    return -1;
    80005e14:	57fd                	li	a5,-1
    80005e16:	a83d                	j	80005e54 <sys_link+0x13c>
    iunlockput(dp);
    80005e18:	854a                	mv	a0,s2
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	15c080e7          	jalr	348(ra) # 80003f76 <iunlockput>

bad:
  ilock(ip);
    80005e22:	8526                	mv	a0,s1
    80005e24:	ffffe097          	auipc	ra,0xffffe
    80005e28:	ef0080e7          	jalr	-272(ra) # 80003d14 <ilock>
  ip->nlink--;
    80005e2c:	04a4d783          	lhu	a5,74(s1)
    80005e30:	37fd                	addiw	a5,a5,-1
    80005e32:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e36:	8526                	mv	a0,s1
    80005e38:	ffffe097          	auipc	ra,0xffffe
    80005e3c:	e12080e7          	jalr	-494(ra) # 80003c4a <iupdate>
  iunlockput(ip);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	134080e7          	jalr	308(ra) # 80003f76 <iunlockput>
  end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	c32080e7          	jalr	-974(ra) # 80004a7c <end_op>
  return -1;
    80005e52:	57fd                	li	a5,-1
}
    80005e54:	853e                	mv	a0,a5
    80005e56:	70b2                	ld	ra,296(sp)
    80005e58:	7412                	ld	s0,288(sp)
    80005e5a:	64f2                	ld	s1,280(sp)
    80005e5c:	6952                	ld	s2,272(sp)
    80005e5e:	6155                	addi	sp,sp,304
    80005e60:	8082                	ret

0000000080005e62 <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e62:	4578                	lw	a4,76(a0)
    80005e64:	02000793          	li	a5,32
    80005e68:	04e7fa63          	bgeu	a5,a4,80005ebc <isdirempty+0x5a>
{
    80005e6c:	7179                	addi	sp,sp,-48
    80005e6e:	f406                	sd	ra,40(sp)
    80005e70:	f022                	sd	s0,32(sp)
    80005e72:	ec26                	sd	s1,24(sp)
    80005e74:	e84a                	sd	s2,16(sp)
    80005e76:	1800                	addi	s0,sp,48
    80005e78:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e7a:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e7e:	4741                	li	a4,16
    80005e80:	86a6                	mv	a3,s1
    80005e82:	fd040613          	addi	a2,s0,-48
    80005e86:	4581                	li	a1,0
    80005e88:	854a                	mv	a0,s2
    80005e8a:	ffffe097          	auipc	ra,0xffffe
    80005e8e:	13e080e7          	jalr	318(ra) # 80003fc8 <readi>
    80005e92:	47c1                	li	a5,16
    80005e94:	00f51c63          	bne	a0,a5,80005eac <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    80005e98:	fd045783          	lhu	a5,-48(s0)
    80005e9c:	e395                	bnez	a5,80005ec0 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e9e:	24c1                	addiw	s1,s1,16
    80005ea0:	04c92783          	lw	a5,76(s2)
    80005ea4:	fcf4ede3          	bltu	s1,a5,80005e7e <isdirempty+0x1c>
      return 0;
  }
  return 1;
    80005ea8:	4505                	li	a0,1
    80005eaa:	a821                	j	80005ec2 <isdirempty+0x60>
      panic("isdirempty: readi");
    80005eac:	00003517          	auipc	a0,0x3
    80005eb0:	96450513          	addi	a0,a0,-1692 # 80008810 <syscalls+0x310>
    80005eb4:	ffffa097          	auipc	ra,0xffffa
    80005eb8:	676080e7          	jalr	1654(ra) # 8000052a <panic>
  return 1;
    80005ebc:	4505                	li	a0,1
}
    80005ebe:	8082                	ret
      return 0;
    80005ec0:	4501                	li	a0,0
}
    80005ec2:	70a2                	ld	ra,40(sp)
    80005ec4:	7402                	ld	s0,32(sp)
    80005ec6:	64e2                	ld	s1,24(sp)
    80005ec8:	6942                	ld	s2,16(sp)
    80005eca:	6145                	addi	sp,sp,48
    80005ecc:	8082                	ret

0000000080005ece <sys_unlink>:

uint64
sys_unlink(void)
{
    80005ece:	7155                	addi	sp,sp,-208
    80005ed0:	e586                	sd	ra,200(sp)
    80005ed2:	e1a2                	sd	s0,192(sp)
    80005ed4:	fd26                	sd	s1,184(sp)
    80005ed6:	f94a                	sd	s2,176(sp)
    80005ed8:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80005eda:	08000613          	li	a2,128
    80005ede:	f4040593          	addi	a1,s0,-192
    80005ee2:	4501                	li	a0,0
    80005ee4:	ffffd097          	auipc	ra,0xffffd
    80005ee8:	302080e7          	jalr	770(ra) # 800031e6 <argstr>
    80005eec:	16054363          	bltz	a0,80006052 <sys_unlink+0x184>
    return -1;

  begin_op();
    80005ef0:	fffff097          	auipc	ra,0xfffff
    80005ef4:	b0c080e7          	jalr	-1268(ra) # 800049fc <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ef8:	fc040593          	addi	a1,s0,-64
    80005efc:	f4040513          	addi	a0,s0,-192
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	5e8080e7          	jalr	1512(ra) # 800044e8 <nameiparent>
    80005f08:	84aa                	mv	s1,a0
    80005f0a:	c961                	beqz	a0,80005fda <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	e08080e7          	jalr	-504(ra) # 80003d14 <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005f14:	00002597          	auipc	a1,0x2
    80005f18:	7dc58593          	addi	a1,a1,2012 # 800086f0 <syscalls+0x1f0>
    80005f1c:	fc040513          	addi	a0,s0,-64
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	2be080e7          	jalr	702(ra) # 800041de <namecmp>
    80005f28:	c175                	beqz	a0,8000600c <sys_unlink+0x13e>
    80005f2a:	00002597          	auipc	a1,0x2
    80005f2e:	7ce58593          	addi	a1,a1,1998 # 800086f8 <syscalls+0x1f8>
    80005f32:	fc040513          	addi	a0,s0,-64
    80005f36:	ffffe097          	auipc	ra,0xffffe
    80005f3a:	2a8080e7          	jalr	680(ra) # 800041de <namecmp>
    80005f3e:	c579                	beqz	a0,8000600c <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80005f40:	f3c40613          	addi	a2,s0,-196
    80005f44:	fc040593          	addi	a1,s0,-64
    80005f48:	8526                	mv	a0,s1
    80005f4a:	ffffe097          	auipc	ra,0xffffe
    80005f4e:	2ae080e7          	jalr	686(ra) # 800041f8 <dirlookup>
    80005f52:	892a                	mv	s2,a0
    80005f54:	cd45                	beqz	a0,8000600c <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    80005f56:	ffffe097          	auipc	ra,0xffffe
    80005f5a:	dbe080e7          	jalr	-578(ra) # 80003d14 <ilock>

  if(ip->nlink < 1)
    80005f5e:	04a91783          	lh	a5,74(s2)
    80005f62:	08f05263          	blez	a5,80005fe6 <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005f66:	04491703          	lh	a4,68(s2)
    80005f6a:	4785                	li	a5,1
    80005f6c:	08f70563          	beq	a4,a5,80005ff6 <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80005f70:	4641                	li	a2,16
    80005f72:	4581                	li	a1,0
    80005f74:	fd040513          	addi	a0,s0,-48
    80005f78:	ffffb097          	auipc	ra,0xffffb
    80005f7c:	d56080e7          	jalr	-682(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005f80:	4741                	li	a4,16
    80005f82:	f3c42683          	lw	a3,-196(s0)
    80005f86:	fd040613          	addi	a2,s0,-48
    80005f8a:	4581                	li	a1,0
    80005f8c:	8526                	mv	a0,s1
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	132080e7          	jalr	306(ra) # 800040c0 <writei>
    80005f96:	47c1                	li	a5,16
    80005f98:	08f51a63          	bne	a0,a5,8000602c <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80005f9c:	04491703          	lh	a4,68(s2)
    80005fa0:	4785                	li	a5,1
    80005fa2:	08f70d63          	beq	a4,a5,8000603c <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80005fa6:	8526                	mv	a0,s1
    80005fa8:	ffffe097          	auipc	ra,0xffffe
    80005fac:	fce080e7          	jalr	-50(ra) # 80003f76 <iunlockput>

  ip->nlink--;
    80005fb0:	04a95783          	lhu	a5,74(s2)
    80005fb4:	37fd                	addiw	a5,a5,-1
    80005fb6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005fba:	854a                	mv	a0,s2
    80005fbc:	ffffe097          	auipc	ra,0xffffe
    80005fc0:	c8e080e7          	jalr	-882(ra) # 80003c4a <iupdate>
  iunlockput(ip);
    80005fc4:	854a                	mv	a0,s2
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	fb0080e7          	jalr	-80(ra) # 80003f76 <iunlockput>

  end_op();
    80005fce:	fffff097          	auipc	ra,0xfffff
    80005fd2:	aae080e7          	jalr	-1362(ra) # 80004a7c <end_op>

  return 0;
    80005fd6:	4501                	li	a0,0
    80005fd8:	a0a1                	j	80006020 <sys_unlink+0x152>
    end_op();
    80005fda:	fffff097          	auipc	ra,0xfffff
    80005fde:	aa2080e7          	jalr	-1374(ra) # 80004a7c <end_op>
    return -1;
    80005fe2:	557d                	li	a0,-1
    80005fe4:	a835                	j	80006020 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    80005fe6:	00002517          	auipc	a0,0x2
    80005fea:	71a50513          	addi	a0,a0,1818 # 80008700 <syscalls+0x200>
    80005fee:	ffffa097          	auipc	ra,0xffffa
    80005ff2:	53c080e7          	jalr	1340(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ff6:	854a                	mv	a0,s2
    80005ff8:	00000097          	auipc	ra,0x0
    80005ffc:	e6a080e7          	jalr	-406(ra) # 80005e62 <isdirempty>
    80006000:	f925                	bnez	a0,80005f70 <sys_unlink+0xa2>
    iunlockput(ip);
    80006002:	854a                	mv	a0,s2
    80006004:	ffffe097          	auipc	ra,0xffffe
    80006008:	f72080e7          	jalr	-142(ra) # 80003f76 <iunlockput>

bad:
  iunlockput(dp);
    8000600c:	8526                	mv	a0,s1
    8000600e:	ffffe097          	auipc	ra,0xffffe
    80006012:	f68080e7          	jalr	-152(ra) # 80003f76 <iunlockput>
  end_op();
    80006016:	fffff097          	auipc	ra,0xfffff
    8000601a:	a66080e7          	jalr	-1434(ra) # 80004a7c <end_op>
  return -1;
    8000601e:	557d                	li	a0,-1
}
    80006020:	60ae                	ld	ra,200(sp)
    80006022:	640e                	ld	s0,192(sp)
    80006024:	74ea                	ld	s1,184(sp)
    80006026:	794a                	ld	s2,176(sp)
    80006028:	6169                	addi	sp,sp,208
    8000602a:	8082                	ret
    panic("unlink: writei");
    8000602c:	00002517          	auipc	a0,0x2
    80006030:	6ec50513          	addi	a0,a0,1772 # 80008718 <syscalls+0x218>
    80006034:	ffffa097          	auipc	ra,0xffffa
    80006038:	4f6080e7          	jalr	1270(ra) # 8000052a <panic>
    dp->nlink--;
    8000603c:	04a4d783          	lhu	a5,74(s1)
    80006040:	37fd                	addiw	a5,a5,-1
    80006042:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006046:	8526                	mv	a0,s1
    80006048:	ffffe097          	auipc	ra,0xffffe
    8000604c:	c02080e7          	jalr	-1022(ra) # 80003c4a <iupdate>
    80006050:	bf99                	j	80005fa6 <sys_unlink+0xd8>
    return -1;
    80006052:	557d                	li	a0,-1
    80006054:	b7f1                	j	80006020 <sys_unlink+0x152>

0000000080006056 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    80006056:	715d                	addi	sp,sp,-80
    80006058:	e486                	sd	ra,72(sp)
    8000605a:	e0a2                	sd	s0,64(sp)
    8000605c:	fc26                	sd	s1,56(sp)
    8000605e:	f84a                	sd	s2,48(sp)
    80006060:	f44e                	sd	s3,40(sp)
    80006062:	f052                	sd	s4,32(sp)
    80006064:	ec56                	sd	s5,24(sp)
    80006066:	0880                	addi	s0,sp,80
    80006068:	89ae                	mv	s3,a1
    8000606a:	8ab2                	mv	s5,a2
    8000606c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000606e:	fb040593          	addi	a1,s0,-80
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	476080e7          	jalr	1142(ra) # 800044e8 <nameiparent>
    8000607a:	892a                	mv	s2,a0
    8000607c:	12050e63          	beqz	a0,800061b8 <create+0x162>
    return 0;

  ilock(dp);
    80006080:	ffffe097          	auipc	ra,0xffffe
    80006084:	c94080e7          	jalr	-876(ra) # 80003d14 <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    80006088:	4601                	li	a2,0
    8000608a:	fb040593          	addi	a1,s0,-80
    8000608e:	854a                	mv	a0,s2
    80006090:	ffffe097          	auipc	ra,0xffffe
    80006094:	168080e7          	jalr	360(ra) # 800041f8 <dirlookup>
    80006098:	84aa                	mv	s1,a0
    8000609a:	c921                	beqz	a0,800060ea <create+0x94>
    iunlockput(dp);
    8000609c:	854a                	mv	a0,s2
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	ed8080e7          	jalr	-296(ra) # 80003f76 <iunlockput>
    ilock(ip);
    800060a6:	8526                	mv	a0,s1
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	c6c080e7          	jalr	-916(ra) # 80003d14 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800060b0:	2981                	sext.w	s3,s3
    800060b2:	4789                	li	a5,2
    800060b4:	02f99463          	bne	s3,a5,800060dc <create+0x86>
    800060b8:	0444d783          	lhu	a5,68(s1)
    800060bc:	37f9                	addiw	a5,a5,-2
    800060be:	17c2                	slli	a5,a5,0x30
    800060c0:	93c1                	srli	a5,a5,0x30
    800060c2:	4705                	li	a4,1
    800060c4:	00f76c63          	bltu	a4,a5,800060dc <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800060c8:	8526                	mv	a0,s1
    800060ca:	60a6                	ld	ra,72(sp)
    800060cc:	6406                	ld	s0,64(sp)
    800060ce:	74e2                	ld	s1,56(sp)
    800060d0:	7942                	ld	s2,48(sp)
    800060d2:	79a2                	ld	s3,40(sp)
    800060d4:	7a02                	ld	s4,32(sp)
    800060d6:	6ae2                	ld	s5,24(sp)
    800060d8:	6161                	addi	sp,sp,80
    800060da:	8082                	ret
    iunlockput(ip);
    800060dc:	8526                	mv	a0,s1
    800060de:	ffffe097          	auipc	ra,0xffffe
    800060e2:	e98080e7          	jalr	-360(ra) # 80003f76 <iunlockput>
    return 0;
    800060e6:	4481                	li	s1,0
    800060e8:	b7c5                	j	800060c8 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800060ea:	85ce                	mv	a1,s3
    800060ec:	00092503          	lw	a0,0(s2)
    800060f0:	ffffe097          	auipc	ra,0xffffe
    800060f4:	a8c080e7          	jalr	-1396(ra) # 80003b7c <ialloc>
    800060f8:	84aa                	mv	s1,a0
    800060fa:	c521                	beqz	a0,80006142 <create+0xec>
  ilock(ip);
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	c18080e7          	jalr	-1000(ra) # 80003d14 <ilock>
  ip->major = major;
    80006104:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006108:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000610c:	4a05                	li	s4,1
    8000610e:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    80006112:	8526                	mv	a0,s1
    80006114:	ffffe097          	auipc	ra,0xffffe
    80006118:	b36080e7          	jalr	-1226(ra) # 80003c4a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000611c:	2981                	sext.w	s3,s3
    8000611e:	03498a63          	beq	s3,s4,80006152 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    80006122:	40d0                	lw	a2,4(s1)
    80006124:	fb040593          	addi	a1,s0,-80
    80006128:	854a                	mv	a0,s2
    8000612a:	ffffe097          	auipc	ra,0xffffe
    8000612e:	2de080e7          	jalr	734(ra) # 80004408 <dirlink>
    80006132:	06054b63          	bltz	a0,800061a8 <create+0x152>
  iunlockput(dp);
    80006136:	854a                	mv	a0,s2
    80006138:	ffffe097          	auipc	ra,0xffffe
    8000613c:	e3e080e7          	jalr	-450(ra) # 80003f76 <iunlockput>
  return ip;
    80006140:	b761                	j	800060c8 <create+0x72>
    panic("create: ialloc");
    80006142:	00002517          	auipc	a0,0x2
    80006146:	6e650513          	addi	a0,a0,1766 # 80008828 <syscalls+0x328>
    8000614a:	ffffa097          	auipc	ra,0xffffa
    8000614e:	3e0080e7          	jalr	992(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    80006152:	04a95783          	lhu	a5,74(s2)
    80006156:	2785                	addiw	a5,a5,1
    80006158:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000615c:	854a                	mv	a0,s2
    8000615e:	ffffe097          	auipc	ra,0xffffe
    80006162:	aec080e7          	jalr	-1300(ra) # 80003c4a <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006166:	40d0                	lw	a2,4(s1)
    80006168:	00002597          	auipc	a1,0x2
    8000616c:	58858593          	addi	a1,a1,1416 # 800086f0 <syscalls+0x1f0>
    80006170:	8526                	mv	a0,s1
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	296080e7          	jalr	662(ra) # 80004408 <dirlink>
    8000617a:	00054f63          	bltz	a0,80006198 <create+0x142>
    8000617e:	00492603          	lw	a2,4(s2)
    80006182:	00002597          	auipc	a1,0x2
    80006186:	57658593          	addi	a1,a1,1398 # 800086f8 <syscalls+0x1f8>
    8000618a:	8526                	mv	a0,s1
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	27c080e7          	jalr	636(ra) # 80004408 <dirlink>
    80006194:	f80557e3          	bgez	a0,80006122 <create+0xcc>
      panic("create dots");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	6a050513          	addi	a0,a0,1696 # 80008838 <syscalls+0x338>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	38a080e7          	jalr	906(ra) # 8000052a <panic>
    panic("create: dirlink");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	6a050513          	addi	a0,a0,1696 # 80008848 <syscalls+0x348>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	37a080e7          	jalr	890(ra) # 8000052a <panic>
    return 0;
    800061b8:	84aa                	mv	s1,a0
    800061ba:	b739                	j	800060c8 <create+0x72>

00000000800061bc <sys_open>:

uint64
sys_open(void)
{
    800061bc:	7131                	addi	sp,sp,-192
    800061be:	fd06                	sd	ra,184(sp)
    800061c0:	f922                	sd	s0,176(sp)
    800061c2:	f526                	sd	s1,168(sp)
    800061c4:	f14a                	sd	s2,160(sp)
    800061c6:	ed4e                	sd	s3,152(sp)
    800061c8:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061ca:	08000613          	li	a2,128
    800061ce:	f5040593          	addi	a1,s0,-176
    800061d2:	4501                	li	a0,0
    800061d4:	ffffd097          	auipc	ra,0xffffd
    800061d8:	012080e7          	jalr	18(ra) # 800031e6 <argstr>
    return -1;
    800061dc:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800061de:	0c054163          	bltz	a0,800062a0 <sys_open+0xe4>
    800061e2:	f4c40593          	addi	a1,s0,-180
    800061e6:	4505                	li	a0,1
    800061e8:	ffffd097          	auipc	ra,0xffffd
    800061ec:	fba080e7          	jalr	-70(ra) # 800031a2 <argint>
    800061f0:	0a054863          	bltz	a0,800062a0 <sys_open+0xe4>

  begin_op();
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	808080e7          	jalr	-2040(ra) # 800049fc <begin_op>

  if(omode & O_CREATE){
    800061fc:	f4c42783          	lw	a5,-180(s0)
    80006200:	2007f793          	andi	a5,a5,512
    80006204:	cbdd                	beqz	a5,800062ba <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006206:	4681                	li	a3,0
    80006208:	4601                	li	a2,0
    8000620a:	4589                	li	a1,2
    8000620c:	f5040513          	addi	a0,s0,-176
    80006210:	00000097          	auipc	ra,0x0
    80006214:	e46080e7          	jalr	-442(ra) # 80006056 <create>
    80006218:	892a                	mv	s2,a0
    if(ip == 0){
    8000621a:	c959                	beqz	a0,800062b0 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000621c:	04491703          	lh	a4,68(s2)
    80006220:	478d                	li	a5,3
    80006222:	00f71763          	bne	a4,a5,80006230 <sys_open+0x74>
    80006226:	04695703          	lhu	a4,70(s2)
    8000622a:	47a5                	li	a5,9
    8000622c:	0ce7ec63          	bltu	a5,a4,80006304 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	bdc080e7          	jalr	-1060(ra) # 80004e0c <filealloc>
    80006238:	89aa                	mv	s3,a0
    8000623a:	10050263          	beqz	a0,8000633e <sys_open+0x182>
    8000623e:	00000097          	auipc	ra,0x0
    80006242:	8e2080e7          	jalr	-1822(ra) # 80005b20 <fdalloc>
    80006246:	84aa                	mv	s1,a0
    80006248:	0e054663          	bltz	a0,80006334 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000624c:	04491703          	lh	a4,68(s2)
    80006250:	478d                	li	a5,3
    80006252:	0cf70463          	beq	a4,a5,8000631a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006256:	4789                	li	a5,2
    80006258:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000625c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006260:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006264:	f4c42783          	lw	a5,-180(s0)
    80006268:	0017c713          	xori	a4,a5,1
    8000626c:	8b05                	andi	a4,a4,1
    8000626e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006272:	0037f713          	andi	a4,a5,3
    80006276:	00e03733          	snez	a4,a4
    8000627a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000627e:	4007f793          	andi	a5,a5,1024
    80006282:	c791                	beqz	a5,8000628e <sys_open+0xd2>
    80006284:	04491703          	lh	a4,68(s2)
    80006288:	4789                	li	a5,2
    8000628a:	08f70f63          	beq	a4,a5,80006328 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000628e:	854a                	mv	a0,s2
    80006290:	ffffe097          	auipc	ra,0xffffe
    80006294:	b46080e7          	jalr	-1210(ra) # 80003dd6 <iunlock>
  end_op();
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	7e4080e7          	jalr	2020(ra) # 80004a7c <end_op>

  return fd;
}
    800062a0:	8526                	mv	a0,s1
    800062a2:	70ea                	ld	ra,184(sp)
    800062a4:	744a                	ld	s0,176(sp)
    800062a6:	74aa                	ld	s1,168(sp)
    800062a8:	790a                	ld	s2,160(sp)
    800062aa:	69ea                	ld	s3,152(sp)
    800062ac:	6129                	addi	sp,sp,192
    800062ae:	8082                	ret
      end_op();
    800062b0:	ffffe097          	auipc	ra,0xffffe
    800062b4:	7cc080e7          	jalr	1996(ra) # 80004a7c <end_op>
      return -1;
    800062b8:	b7e5                	j	800062a0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800062ba:	f5040513          	addi	a0,s0,-176
    800062be:	ffffe097          	auipc	ra,0xffffe
    800062c2:	20c080e7          	jalr	524(ra) # 800044ca <namei>
    800062c6:	892a                	mv	s2,a0
    800062c8:	c905                	beqz	a0,800062f8 <sys_open+0x13c>
    ilock(ip);
    800062ca:	ffffe097          	auipc	ra,0xffffe
    800062ce:	a4a080e7          	jalr	-1462(ra) # 80003d14 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800062d2:	04491703          	lh	a4,68(s2)
    800062d6:	4785                	li	a5,1
    800062d8:	f4f712e3          	bne	a4,a5,8000621c <sys_open+0x60>
    800062dc:	f4c42783          	lw	a5,-180(s0)
    800062e0:	dba1                	beqz	a5,80006230 <sys_open+0x74>
      iunlockput(ip);
    800062e2:	854a                	mv	a0,s2
    800062e4:	ffffe097          	auipc	ra,0xffffe
    800062e8:	c92080e7          	jalr	-878(ra) # 80003f76 <iunlockput>
      end_op();
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	790080e7          	jalr	1936(ra) # 80004a7c <end_op>
      return -1;
    800062f4:	54fd                	li	s1,-1
    800062f6:	b76d                	j	800062a0 <sys_open+0xe4>
      end_op();
    800062f8:	ffffe097          	auipc	ra,0xffffe
    800062fc:	784080e7          	jalr	1924(ra) # 80004a7c <end_op>
      return -1;
    80006300:	54fd                	li	s1,-1
    80006302:	bf79                	j	800062a0 <sys_open+0xe4>
    iunlockput(ip);
    80006304:	854a                	mv	a0,s2
    80006306:	ffffe097          	auipc	ra,0xffffe
    8000630a:	c70080e7          	jalr	-912(ra) # 80003f76 <iunlockput>
    end_op();
    8000630e:	ffffe097          	auipc	ra,0xffffe
    80006312:	76e080e7          	jalr	1902(ra) # 80004a7c <end_op>
    return -1;
    80006316:	54fd                	li	s1,-1
    80006318:	b761                	j	800062a0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000631a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000631e:	04691783          	lh	a5,70(s2)
    80006322:	02f99223          	sh	a5,36(s3)
    80006326:	bf2d                	j	80006260 <sys_open+0xa4>
    itrunc(ip);
    80006328:	854a                	mv	a0,s2
    8000632a:	ffffe097          	auipc	ra,0xffffe
    8000632e:	af8080e7          	jalr	-1288(ra) # 80003e22 <itrunc>
    80006332:	bfb1                	j	8000628e <sys_open+0xd2>
      fileclose(f);
    80006334:	854e                	mv	a0,s3
    80006336:	fffff097          	auipc	ra,0xfffff
    8000633a:	b92080e7          	jalr	-1134(ra) # 80004ec8 <fileclose>
    iunlockput(ip);
    8000633e:	854a                	mv	a0,s2
    80006340:	ffffe097          	auipc	ra,0xffffe
    80006344:	c36080e7          	jalr	-970(ra) # 80003f76 <iunlockput>
    end_op();
    80006348:	ffffe097          	auipc	ra,0xffffe
    8000634c:	734080e7          	jalr	1844(ra) # 80004a7c <end_op>
    return -1;
    80006350:	54fd                	li	s1,-1
    80006352:	b7b9                	j	800062a0 <sys_open+0xe4>

0000000080006354 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006354:	7175                	addi	sp,sp,-144
    80006356:	e506                	sd	ra,136(sp)
    80006358:	e122                	sd	s0,128(sp)
    8000635a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	6a0080e7          	jalr	1696(ra) # 800049fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006364:	08000613          	li	a2,128
    80006368:	f7040593          	addi	a1,s0,-144
    8000636c:	4501                	li	a0,0
    8000636e:	ffffd097          	auipc	ra,0xffffd
    80006372:	e78080e7          	jalr	-392(ra) # 800031e6 <argstr>
    80006376:	02054963          	bltz	a0,800063a8 <sys_mkdir+0x54>
    8000637a:	4681                	li	a3,0
    8000637c:	4601                	li	a2,0
    8000637e:	4585                	li	a1,1
    80006380:	f7040513          	addi	a0,s0,-144
    80006384:	00000097          	auipc	ra,0x0
    80006388:	cd2080e7          	jalr	-814(ra) # 80006056 <create>
    8000638c:	cd11                	beqz	a0,800063a8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000638e:	ffffe097          	auipc	ra,0xffffe
    80006392:	be8080e7          	jalr	-1048(ra) # 80003f76 <iunlockput>
  end_op();
    80006396:	ffffe097          	auipc	ra,0xffffe
    8000639a:	6e6080e7          	jalr	1766(ra) # 80004a7c <end_op>
  return 0;
    8000639e:	4501                	li	a0,0
}
    800063a0:	60aa                	ld	ra,136(sp)
    800063a2:	640a                	ld	s0,128(sp)
    800063a4:	6149                	addi	sp,sp,144
    800063a6:	8082                	ret
    end_op();
    800063a8:	ffffe097          	auipc	ra,0xffffe
    800063ac:	6d4080e7          	jalr	1748(ra) # 80004a7c <end_op>
    return -1;
    800063b0:	557d                	li	a0,-1
    800063b2:	b7fd                	j	800063a0 <sys_mkdir+0x4c>

00000000800063b4 <sys_mknod>:

uint64
sys_mknod(void)
{
    800063b4:	7135                	addi	sp,sp,-160
    800063b6:	ed06                	sd	ra,152(sp)
    800063b8:	e922                	sd	s0,144(sp)
    800063ba:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800063bc:	ffffe097          	auipc	ra,0xffffe
    800063c0:	640080e7          	jalr	1600(ra) # 800049fc <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063c4:	08000613          	li	a2,128
    800063c8:	f7040593          	addi	a1,s0,-144
    800063cc:	4501                	li	a0,0
    800063ce:	ffffd097          	auipc	ra,0xffffd
    800063d2:	e18080e7          	jalr	-488(ra) # 800031e6 <argstr>
    800063d6:	04054a63          	bltz	a0,8000642a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800063da:	f6c40593          	addi	a1,s0,-148
    800063de:	4505                	li	a0,1
    800063e0:	ffffd097          	auipc	ra,0xffffd
    800063e4:	dc2080e7          	jalr	-574(ra) # 800031a2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800063e8:	04054163          	bltz	a0,8000642a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800063ec:	f6840593          	addi	a1,s0,-152
    800063f0:	4509                	li	a0,2
    800063f2:	ffffd097          	auipc	ra,0xffffd
    800063f6:	db0080e7          	jalr	-592(ra) # 800031a2 <argint>
     argint(1, &major) < 0 ||
    800063fa:	02054863          	bltz	a0,8000642a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800063fe:	f6841683          	lh	a3,-152(s0)
    80006402:	f6c41603          	lh	a2,-148(s0)
    80006406:	458d                	li	a1,3
    80006408:	f7040513          	addi	a0,s0,-144
    8000640c:	00000097          	auipc	ra,0x0
    80006410:	c4a080e7          	jalr	-950(ra) # 80006056 <create>
     argint(2, &minor) < 0 ||
    80006414:	c919                	beqz	a0,8000642a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006416:	ffffe097          	auipc	ra,0xffffe
    8000641a:	b60080e7          	jalr	-1184(ra) # 80003f76 <iunlockput>
  end_op();
    8000641e:	ffffe097          	auipc	ra,0xffffe
    80006422:	65e080e7          	jalr	1630(ra) # 80004a7c <end_op>
  return 0;
    80006426:	4501                	li	a0,0
    80006428:	a031                	j	80006434 <sys_mknod+0x80>
    end_op();
    8000642a:	ffffe097          	auipc	ra,0xffffe
    8000642e:	652080e7          	jalr	1618(ra) # 80004a7c <end_op>
    return -1;
    80006432:	557d                	li	a0,-1
}
    80006434:	60ea                	ld	ra,152(sp)
    80006436:	644a                	ld	s0,144(sp)
    80006438:	610d                	addi	sp,sp,160
    8000643a:	8082                	ret

000000008000643c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000643c:	7135                	addi	sp,sp,-160
    8000643e:	ed06                	sd	ra,152(sp)
    80006440:	e922                	sd	s0,144(sp)
    80006442:	e526                	sd	s1,136(sp)
    80006444:	e14a                	sd	s2,128(sp)
    80006446:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006448:	ffffc097          	auipc	ra,0xffffc
    8000644c:	bc2080e7          	jalr	-1086(ra) # 8000200a <myproc>
    80006450:	892a                	mv	s2,a0
  
  begin_op();
    80006452:	ffffe097          	auipc	ra,0xffffe
    80006456:	5aa080e7          	jalr	1450(ra) # 800049fc <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    8000645a:	08000613          	li	a2,128
    8000645e:	f6040593          	addi	a1,s0,-160
    80006462:	4501                	li	a0,0
    80006464:	ffffd097          	auipc	ra,0xffffd
    80006468:	d82080e7          	jalr	-638(ra) # 800031e6 <argstr>
    8000646c:	04054b63          	bltz	a0,800064c2 <sys_chdir+0x86>
    80006470:	f6040513          	addi	a0,s0,-160
    80006474:	ffffe097          	auipc	ra,0xffffe
    80006478:	056080e7          	jalr	86(ra) # 800044ca <namei>
    8000647c:	84aa                	mv	s1,a0
    8000647e:	c131                	beqz	a0,800064c2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006480:	ffffe097          	auipc	ra,0xffffe
    80006484:	894080e7          	jalr	-1900(ra) # 80003d14 <ilock>
  if(ip->type != T_DIR){
    80006488:	04449703          	lh	a4,68(s1)
    8000648c:	4785                	li	a5,1
    8000648e:	04f71063          	bne	a4,a5,800064ce <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006492:	8526                	mv	a0,s1
    80006494:	ffffe097          	auipc	ra,0xffffe
    80006498:	942080e7          	jalr	-1726(ra) # 80003dd6 <iunlock>
  iput(p->cwd);
    8000649c:	15093503          	ld	a0,336(s2)
    800064a0:	ffffe097          	auipc	ra,0xffffe
    800064a4:	a2e080e7          	jalr	-1490(ra) # 80003ece <iput>
  end_op();
    800064a8:	ffffe097          	auipc	ra,0xffffe
    800064ac:	5d4080e7          	jalr	1492(ra) # 80004a7c <end_op>
  p->cwd = ip;
    800064b0:	14993823          	sd	s1,336(s2)
  return 0;
    800064b4:	4501                	li	a0,0
}
    800064b6:	60ea                	ld	ra,152(sp)
    800064b8:	644a                	ld	s0,144(sp)
    800064ba:	64aa                	ld	s1,136(sp)
    800064bc:	690a                	ld	s2,128(sp)
    800064be:	610d                	addi	sp,sp,160
    800064c0:	8082                	ret
    end_op();
    800064c2:	ffffe097          	auipc	ra,0xffffe
    800064c6:	5ba080e7          	jalr	1466(ra) # 80004a7c <end_op>
    return -1;
    800064ca:	557d                	li	a0,-1
    800064cc:	b7ed                	j	800064b6 <sys_chdir+0x7a>
    iunlockput(ip);
    800064ce:	8526                	mv	a0,s1
    800064d0:	ffffe097          	auipc	ra,0xffffe
    800064d4:	aa6080e7          	jalr	-1370(ra) # 80003f76 <iunlockput>
    end_op();
    800064d8:	ffffe097          	auipc	ra,0xffffe
    800064dc:	5a4080e7          	jalr	1444(ra) # 80004a7c <end_op>
    return -1;
    800064e0:	557d                	li	a0,-1
    800064e2:	bfd1                	j	800064b6 <sys_chdir+0x7a>

00000000800064e4 <sys_exec>:

uint64
sys_exec(void)
{
    800064e4:	7145                	addi	sp,sp,-464
    800064e6:	e786                	sd	ra,456(sp)
    800064e8:	e3a2                	sd	s0,448(sp)
    800064ea:	ff26                	sd	s1,440(sp)
    800064ec:	fb4a                	sd	s2,432(sp)
    800064ee:	f74e                	sd	s3,424(sp)
    800064f0:	f352                	sd	s4,416(sp)
    800064f2:	ef56                	sd	s5,408(sp)
    800064f4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800064f6:	08000613          	li	a2,128
    800064fa:	f4040593          	addi	a1,s0,-192
    800064fe:	4501                	li	a0,0
    80006500:	ffffd097          	auipc	ra,0xffffd
    80006504:	ce6080e7          	jalr	-794(ra) # 800031e6 <argstr>
    return -1;
    80006508:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000650a:	0c054a63          	bltz	a0,800065de <sys_exec+0xfa>
    8000650e:	e3840593          	addi	a1,s0,-456
    80006512:	4505                	li	a0,1
    80006514:	ffffd097          	auipc	ra,0xffffd
    80006518:	cb0080e7          	jalr	-848(ra) # 800031c4 <argaddr>
    8000651c:	0c054163          	bltz	a0,800065de <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006520:	10000613          	li	a2,256
    80006524:	4581                	li	a1,0
    80006526:	e4040513          	addi	a0,s0,-448
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	7a4080e7          	jalr	1956(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006532:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006536:	89a6                	mv	s3,s1
    80006538:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000653a:	02000a13          	li	s4,32
    8000653e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006542:	00391793          	slli	a5,s2,0x3
    80006546:	e3040593          	addi	a1,s0,-464
    8000654a:	e3843503          	ld	a0,-456(s0)
    8000654e:	953e                	add	a0,a0,a5
    80006550:	ffffd097          	auipc	ra,0xffffd
    80006554:	bb8080e7          	jalr	-1096(ra) # 80003108 <fetchaddr>
    80006558:	02054a63          	bltz	a0,8000658c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000655c:	e3043783          	ld	a5,-464(s0)
    80006560:	c3b9                	beqz	a5,800065a6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006562:	ffffa097          	auipc	ra,0xffffa
    80006566:	580080e7          	jalr	1408(ra) # 80000ae2 <kalloc>
    8000656a:	85aa                	mv	a1,a0
    8000656c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006570:	cd11                	beqz	a0,8000658c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006572:	6605                	lui	a2,0x1
    80006574:	e3043503          	ld	a0,-464(s0)
    80006578:	ffffd097          	auipc	ra,0xffffd
    8000657c:	be2080e7          	jalr	-1054(ra) # 8000315a <fetchstr>
    80006580:	00054663          	bltz	a0,8000658c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006584:	0905                	addi	s2,s2,1
    80006586:	09a1                	addi	s3,s3,8
    80006588:	fb491be3          	bne	s2,s4,8000653e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000658c:	10048913          	addi	s2,s1,256
    80006590:	6088                	ld	a0,0(s1)
    80006592:	c529                	beqz	a0,800065dc <sys_exec+0xf8>
    kfree(argv[i]);
    80006594:	ffffa097          	auipc	ra,0xffffa
    80006598:	442080e7          	jalr	1090(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000659c:	04a1                	addi	s1,s1,8
    8000659e:	ff2499e3          	bne	s1,s2,80006590 <sys_exec+0xac>
  return -1;
    800065a2:	597d                	li	s2,-1
    800065a4:	a82d                	j	800065de <sys_exec+0xfa>
      argv[i] = 0;
    800065a6:	0a8e                	slli	s5,s5,0x3
    800065a8:	fc040793          	addi	a5,s0,-64
    800065ac:	9abe                	add	s5,s5,a5
    800065ae:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd0e80>
  int ret = exec(path, argv);
    800065b2:	e4040593          	addi	a1,s0,-448
    800065b6:	f4040513          	addi	a0,s0,-192
    800065ba:	fffff097          	auipc	ra,0xfffff
    800065be:	156080e7          	jalr	342(ra) # 80005710 <exec>
    800065c2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065c4:	10048993          	addi	s3,s1,256
    800065c8:	6088                	ld	a0,0(s1)
    800065ca:	c911                	beqz	a0,800065de <sys_exec+0xfa>
    kfree(argv[i]);
    800065cc:	ffffa097          	auipc	ra,0xffffa
    800065d0:	40a080e7          	jalr	1034(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800065d4:	04a1                	addi	s1,s1,8
    800065d6:	ff3499e3          	bne	s1,s3,800065c8 <sys_exec+0xe4>
    800065da:	a011                	j	800065de <sys_exec+0xfa>
  return -1;
    800065dc:	597d                	li	s2,-1
}
    800065de:	854a                	mv	a0,s2
    800065e0:	60be                	ld	ra,456(sp)
    800065e2:	641e                	ld	s0,448(sp)
    800065e4:	74fa                	ld	s1,440(sp)
    800065e6:	795a                	ld	s2,432(sp)
    800065e8:	79ba                	ld	s3,424(sp)
    800065ea:	7a1a                	ld	s4,416(sp)
    800065ec:	6afa                	ld	s5,408(sp)
    800065ee:	6179                	addi	sp,sp,464
    800065f0:	8082                	ret

00000000800065f2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800065f2:	7139                	addi	sp,sp,-64
    800065f4:	fc06                	sd	ra,56(sp)
    800065f6:	f822                	sd	s0,48(sp)
    800065f8:	f426                	sd	s1,40(sp)
    800065fa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800065fc:	ffffc097          	auipc	ra,0xffffc
    80006600:	a0e080e7          	jalr	-1522(ra) # 8000200a <myproc>
    80006604:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006606:	fd840593          	addi	a1,s0,-40
    8000660a:	4501                	li	a0,0
    8000660c:	ffffd097          	auipc	ra,0xffffd
    80006610:	bb8080e7          	jalr	-1096(ra) # 800031c4 <argaddr>
    return -1;
    80006614:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006616:	0e054063          	bltz	a0,800066f6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    8000661a:	fc840593          	addi	a1,s0,-56
    8000661e:	fd040513          	addi	a0,s0,-48
    80006622:	fffff097          	auipc	ra,0xfffff
    80006626:	dcc080e7          	jalr	-564(ra) # 800053ee <pipealloc>
    return -1;
    8000662a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000662c:	0c054563          	bltz	a0,800066f6 <sys_pipe+0x104>
  fd0 = -1;
    80006630:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006634:	fd043503          	ld	a0,-48(s0)
    80006638:	fffff097          	auipc	ra,0xfffff
    8000663c:	4e8080e7          	jalr	1256(ra) # 80005b20 <fdalloc>
    80006640:	fca42223          	sw	a0,-60(s0)
    80006644:	08054c63          	bltz	a0,800066dc <sys_pipe+0xea>
    80006648:	fc843503          	ld	a0,-56(s0)
    8000664c:	fffff097          	auipc	ra,0xfffff
    80006650:	4d4080e7          	jalr	1236(ra) # 80005b20 <fdalloc>
    80006654:	fca42023          	sw	a0,-64(s0)
    80006658:	06054863          	bltz	a0,800066c8 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000665c:	4691                	li	a3,4
    8000665e:	fc440613          	addi	a2,s0,-60
    80006662:	fd843583          	ld	a1,-40(s0)
    80006666:	68a8                	ld	a0,80(s1)
    80006668:	ffffb097          	auipc	ra,0xffffb
    8000666c:	f96080e7          	jalr	-106(ra) # 800015fe <copyout>
    80006670:	02054063          	bltz	a0,80006690 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006674:	4691                	li	a3,4
    80006676:	fc040613          	addi	a2,s0,-64
    8000667a:	fd843583          	ld	a1,-40(s0)
    8000667e:	0591                	addi	a1,a1,4
    80006680:	68a8                	ld	a0,80(s1)
    80006682:	ffffb097          	auipc	ra,0xffffb
    80006686:	f7c080e7          	jalr	-132(ra) # 800015fe <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000668a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000668c:	06055563          	bgez	a0,800066f6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006690:	fc442783          	lw	a5,-60(s0)
    80006694:	07e9                	addi	a5,a5,26
    80006696:	078e                	slli	a5,a5,0x3
    80006698:	97a6                	add	a5,a5,s1
    8000669a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000669e:	fc042503          	lw	a0,-64(s0)
    800066a2:	0569                	addi	a0,a0,26
    800066a4:	050e                	slli	a0,a0,0x3
    800066a6:	9526                	add	a0,a0,s1
    800066a8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066ac:	fd043503          	ld	a0,-48(s0)
    800066b0:	fffff097          	auipc	ra,0xfffff
    800066b4:	818080e7          	jalr	-2024(ra) # 80004ec8 <fileclose>
    fileclose(wf);
    800066b8:	fc843503          	ld	a0,-56(s0)
    800066bc:	fffff097          	auipc	ra,0xfffff
    800066c0:	80c080e7          	jalr	-2036(ra) # 80004ec8 <fileclose>
    return -1;
    800066c4:	57fd                	li	a5,-1
    800066c6:	a805                	j	800066f6 <sys_pipe+0x104>
    if(fd0 >= 0)
    800066c8:	fc442783          	lw	a5,-60(s0)
    800066cc:	0007c863          	bltz	a5,800066dc <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800066d0:	01a78513          	addi	a0,a5,26
    800066d4:	050e                	slli	a0,a0,0x3
    800066d6:	9526                	add	a0,a0,s1
    800066d8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800066dc:	fd043503          	ld	a0,-48(s0)
    800066e0:	ffffe097          	auipc	ra,0xffffe
    800066e4:	7e8080e7          	jalr	2024(ra) # 80004ec8 <fileclose>
    fileclose(wf);
    800066e8:	fc843503          	ld	a0,-56(s0)
    800066ec:	ffffe097          	auipc	ra,0xffffe
    800066f0:	7dc080e7          	jalr	2012(ra) # 80004ec8 <fileclose>
    return -1;
    800066f4:	57fd                	li	a5,-1
}
    800066f6:	853e                	mv	a0,a5
    800066f8:	70e2                	ld	ra,56(sp)
    800066fa:	7442                	ld	s0,48(sp)
    800066fc:	74a2                	ld	s1,40(sp)
    800066fe:	6121                	addi	sp,sp,64
    80006700:	8082                	ret
	...

0000000080006710 <kernelvec>:
    80006710:	7111                	addi	sp,sp,-256
    80006712:	e006                	sd	ra,0(sp)
    80006714:	e40a                	sd	sp,8(sp)
    80006716:	e80e                	sd	gp,16(sp)
    80006718:	ec12                	sd	tp,24(sp)
    8000671a:	f016                	sd	t0,32(sp)
    8000671c:	f41a                	sd	t1,40(sp)
    8000671e:	f81e                	sd	t2,48(sp)
    80006720:	fc22                	sd	s0,56(sp)
    80006722:	e0a6                	sd	s1,64(sp)
    80006724:	e4aa                	sd	a0,72(sp)
    80006726:	e8ae                	sd	a1,80(sp)
    80006728:	ecb2                	sd	a2,88(sp)
    8000672a:	f0b6                	sd	a3,96(sp)
    8000672c:	f4ba                	sd	a4,104(sp)
    8000672e:	f8be                	sd	a5,112(sp)
    80006730:	fcc2                	sd	a6,120(sp)
    80006732:	e146                	sd	a7,128(sp)
    80006734:	e54a                	sd	s2,136(sp)
    80006736:	e94e                	sd	s3,144(sp)
    80006738:	ed52                	sd	s4,152(sp)
    8000673a:	f156                	sd	s5,160(sp)
    8000673c:	f55a                	sd	s6,168(sp)
    8000673e:	f95e                	sd	s7,176(sp)
    80006740:	fd62                	sd	s8,184(sp)
    80006742:	e1e6                	sd	s9,192(sp)
    80006744:	e5ea                	sd	s10,200(sp)
    80006746:	e9ee                	sd	s11,208(sp)
    80006748:	edf2                	sd	t3,216(sp)
    8000674a:	f1f6                	sd	t4,224(sp)
    8000674c:	f5fa                	sd	t5,232(sp)
    8000674e:	f9fe                	sd	t6,240(sp)
    80006750:	885fc0ef          	jal	ra,80002fd4 <kerneltrap>
    80006754:	6082                	ld	ra,0(sp)
    80006756:	6122                	ld	sp,8(sp)
    80006758:	61c2                	ld	gp,16(sp)
    8000675a:	7282                	ld	t0,32(sp)
    8000675c:	7322                	ld	t1,40(sp)
    8000675e:	73c2                	ld	t2,48(sp)
    80006760:	7462                	ld	s0,56(sp)
    80006762:	6486                	ld	s1,64(sp)
    80006764:	6526                	ld	a0,72(sp)
    80006766:	65c6                	ld	a1,80(sp)
    80006768:	6666                	ld	a2,88(sp)
    8000676a:	7686                	ld	a3,96(sp)
    8000676c:	7726                	ld	a4,104(sp)
    8000676e:	77c6                	ld	a5,112(sp)
    80006770:	7866                	ld	a6,120(sp)
    80006772:	688a                	ld	a7,128(sp)
    80006774:	692a                	ld	s2,136(sp)
    80006776:	69ca                	ld	s3,144(sp)
    80006778:	6a6a                	ld	s4,152(sp)
    8000677a:	7a8a                	ld	s5,160(sp)
    8000677c:	7b2a                	ld	s6,168(sp)
    8000677e:	7bca                	ld	s7,176(sp)
    80006780:	7c6a                	ld	s8,184(sp)
    80006782:	6c8e                	ld	s9,192(sp)
    80006784:	6d2e                	ld	s10,200(sp)
    80006786:	6dce                	ld	s11,208(sp)
    80006788:	6e6e                	ld	t3,216(sp)
    8000678a:	7e8e                	ld	t4,224(sp)
    8000678c:	7f2e                	ld	t5,232(sp)
    8000678e:	7fce                	ld	t6,240(sp)
    80006790:	6111                	addi	sp,sp,256
    80006792:	10200073          	sret
    80006796:	00000013          	nop
    8000679a:	00000013          	nop
    8000679e:	0001                	nop

00000000800067a0 <timervec>:
    800067a0:	34051573          	csrrw	a0,mscratch,a0
    800067a4:	e10c                	sd	a1,0(a0)
    800067a6:	e510                	sd	a2,8(a0)
    800067a8:	e914                	sd	a3,16(a0)
    800067aa:	6d0c                	ld	a1,24(a0)
    800067ac:	7110                	ld	a2,32(a0)
    800067ae:	6194                	ld	a3,0(a1)
    800067b0:	96b2                	add	a3,a3,a2
    800067b2:	e194                	sd	a3,0(a1)
    800067b4:	4589                	li	a1,2
    800067b6:	14459073          	csrw	sip,a1
    800067ba:	6914                	ld	a3,16(a0)
    800067bc:	6510                	ld	a2,8(a0)
    800067be:	610c                	ld	a1,0(a0)
    800067c0:	34051573          	csrrw	a0,mscratch,a0
    800067c4:	30200073          	mret
	...

00000000800067ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800067ca:	1141                	addi	sp,sp,-16
    800067cc:	e422                	sd	s0,8(sp)
    800067ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800067d0:	0c0007b7          	lui	a5,0xc000
    800067d4:	4705                	li	a4,1
    800067d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800067d8:	c3d8                	sw	a4,4(a5)
}
    800067da:	6422                	ld	s0,8(sp)
    800067dc:	0141                	addi	sp,sp,16
    800067de:	8082                	ret

00000000800067e0 <plicinithart>:

void
plicinithart(void)
{
    800067e0:	1141                	addi	sp,sp,-16
    800067e2:	e406                	sd	ra,8(sp)
    800067e4:	e022                	sd	s0,0(sp)
    800067e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067e8:	ffffb097          	auipc	ra,0xffffb
    800067ec:	7f6080e7          	jalr	2038(ra) # 80001fde <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800067f0:	0085171b          	slliw	a4,a0,0x8
    800067f4:	0c0027b7          	lui	a5,0xc002
    800067f8:	97ba                	add	a5,a5,a4
    800067fa:	40200713          	li	a4,1026
    800067fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006802:	00d5151b          	slliw	a0,a0,0xd
    80006806:	0c2017b7          	lui	a5,0xc201
    8000680a:	953e                	add	a0,a0,a5
    8000680c:	00052023          	sw	zero,0(a0)
}
    80006810:	60a2                	ld	ra,8(sp)
    80006812:	6402                	ld	s0,0(sp)
    80006814:	0141                	addi	sp,sp,16
    80006816:	8082                	ret

0000000080006818 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006818:	1141                	addi	sp,sp,-16
    8000681a:	e406                	sd	ra,8(sp)
    8000681c:	e022                	sd	s0,0(sp)
    8000681e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006820:	ffffb097          	auipc	ra,0xffffb
    80006824:	7be080e7          	jalr	1982(ra) # 80001fde <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006828:	00d5179b          	slliw	a5,a0,0xd
    8000682c:	0c201537          	lui	a0,0xc201
    80006830:	953e                	add	a0,a0,a5
  return irq;
}
    80006832:	4148                	lw	a0,4(a0)
    80006834:	60a2                	ld	ra,8(sp)
    80006836:	6402                	ld	s0,0(sp)
    80006838:	0141                	addi	sp,sp,16
    8000683a:	8082                	ret

000000008000683c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000683c:	1101                	addi	sp,sp,-32
    8000683e:	ec06                	sd	ra,24(sp)
    80006840:	e822                	sd	s0,16(sp)
    80006842:	e426                	sd	s1,8(sp)
    80006844:	1000                	addi	s0,sp,32
    80006846:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006848:	ffffb097          	auipc	ra,0xffffb
    8000684c:	796080e7          	jalr	1942(ra) # 80001fde <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006850:	00d5151b          	slliw	a0,a0,0xd
    80006854:	0c2017b7          	lui	a5,0xc201
    80006858:	97aa                	add	a5,a5,a0
    8000685a:	c3c4                	sw	s1,4(a5)
}
    8000685c:	60e2                	ld	ra,24(sp)
    8000685e:	6442                	ld	s0,16(sp)
    80006860:	64a2                	ld	s1,8(sp)
    80006862:	6105                	addi	sp,sp,32
    80006864:	8082                	ret

0000000080006866 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006866:	1141                	addi	sp,sp,-16
    80006868:	e406                	sd	ra,8(sp)
    8000686a:	e022                	sd	s0,0(sp)
    8000686c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000686e:	479d                	li	a5,7
    80006870:	06a7c963          	blt	a5,a0,800068e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006874:	00024797          	auipc	a5,0x24
    80006878:	78c78793          	addi	a5,a5,1932 # 8002b000 <disk>
    8000687c:	00a78733          	add	a4,a5,a0
    80006880:	6789                	lui	a5,0x2
    80006882:	97ba                	add	a5,a5,a4
    80006884:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006888:	e7ad                	bnez	a5,800068f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000688a:	00451793          	slli	a5,a0,0x4
    8000688e:	00026717          	auipc	a4,0x26
    80006892:	77270713          	addi	a4,a4,1906 # 8002d000 <disk+0x2000>
    80006896:	6314                	ld	a3,0(a4)
    80006898:	96be                	add	a3,a3,a5
    8000689a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000689e:	6314                	ld	a3,0(a4)
    800068a0:	96be                	add	a3,a3,a5
    800068a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800068a6:	6314                	ld	a3,0(a4)
    800068a8:	96be                	add	a3,a3,a5
    800068aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800068ae:	6318                	ld	a4,0(a4)
    800068b0:	97ba                	add	a5,a5,a4
    800068b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800068b6:	00024797          	auipc	a5,0x24
    800068ba:	74a78793          	addi	a5,a5,1866 # 8002b000 <disk>
    800068be:	97aa                	add	a5,a5,a0
    800068c0:	6509                	lui	a0,0x2
    800068c2:	953e                	add	a0,a0,a5
    800068c4:	4785                	li	a5,1
    800068c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800068ca:	00026517          	auipc	a0,0x26
    800068ce:	74e50513          	addi	a0,a0,1870 # 8002d018 <disk+0x2018>
    800068d2:	ffffc097          	auipc	ra,0xffffc
    800068d6:	036080e7          	jalr	54(ra) # 80002908 <wakeup>
}
    800068da:	60a2                	ld	ra,8(sp)
    800068dc:	6402                	ld	s0,0(sp)
    800068de:	0141                	addi	sp,sp,16
    800068e0:	8082                	ret
    panic("free_desc 1");
    800068e2:	00002517          	auipc	a0,0x2
    800068e6:	f7650513          	addi	a0,a0,-138 # 80008858 <syscalls+0x358>
    800068ea:	ffffa097          	auipc	ra,0xffffa
    800068ee:	c40080e7          	jalr	-960(ra) # 8000052a <panic>
    panic("free_desc 2");
    800068f2:	00002517          	auipc	a0,0x2
    800068f6:	f7650513          	addi	a0,a0,-138 # 80008868 <syscalls+0x368>
    800068fa:	ffffa097          	auipc	ra,0xffffa
    800068fe:	c30080e7          	jalr	-976(ra) # 8000052a <panic>

0000000080006902 <virtio_disk_init>:
{
    80006902:	1101                	addi	sp,sp,-32
    80006904:	ec06                	sd	ra,24(sp)
    80006906:	e822                	sd	s0,16(sp)
    80006908:	e426                	sd	s1,8(sp)
    8000690a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000690c:	00002597          	auipc	a1,0x2
    80006910:	f6c58593          	addi	a1,a1,-148 # 80008878 <syscalls+0x378>
    80006914:	00027517          	auipc	a0,0x27
    80006918:	81450513          	addi	a0,a0,-2028 # 8002d128 <disk+0x2128>
    8000691c:	ffffa097          	auipc	ra,0xffffa
    80006920:	226080e7          	jalr	550(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006924:	100017b7          	lui	a5,0x10001
    80006928:	4398                	lw	a4,0(a5)
    8000692a:	2701                	sext.w	a4,a4
    8000692c:	747277b7          	lui	a5,0x74727
    80006930:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006934:	0ef71163          	bne	a4,a5,80006a16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006938:	100017b7          	lui	a5,0x10001
    8000693c:	43dc                	lw	a5,4(a5)
    8000693e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006940:	4705                	li	a4,1
    80006942:	0ce79a63          	bne	a5,a4,80006a16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006946:	100017b7          	lui	a5,0x10001
    8000694a:	479c                	lw	a5,8(a5)
    8000694c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000694e:	4709                	li	a4,2
    80006950:	0ce79363          	bne	a5,a4,80006a16 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006954:	100017b7          	lui	a5,0x10001
    80006958:	47d8                	lw	a4,12(a5)
    8000695a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000695c:	554d47b7          	lui	a5,0x554d4
    80006960:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006964:	0af71963          	bne	a4,a5,80006a16 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006968:	100017b7          	lui	a5,0x10001
    8000696c:	4705                	li	a4,1
    8000696e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006970:	470d                	li	a4,3
    80006972:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006974:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006976:	c7ffe737          	lui	a4,0xc7ffe
    8000697a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd075f>
    8000697e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006980:	2701                	sext.w	a4,a4
    80006982:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006984:	472d                	li	a4,11
    80006986:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006988:	473d                	li	a4,15
    8000698a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000698c:	6705                	lui	a4,0x1
    8000698e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006990:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006994:	5bdc                	lw	a5,52(a5)
    80006996:	2781                	sext.w	a5,a5
  if(max == 0)
    80006998:	c7d9                	beqz	a5,80006a26 <virtio_disk_init+0x124>
  if(max < NUM)
    8000699a:	471d                	li	a4,7
    8000699c:	08f77d63          	bgeu	a4,a5,80006a36 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069a0:	100014b7          	lui	s1,0x10001
    800069a4:	47a1                	li	a5,8
    800069a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800069a8:	6609                	lui	a2,0x2
    800069aa:	4581                	li	a1,0
    800069ac:	00024517          	auipc	a0,0x24
    800069b0:	65450513          	addi	a0,a0,1620 # 8002b000 <disk>
    800069b4:	ffffa097          	auipc	ra,0xffffa
    800069b8:	31a080e7          	jalr	794(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800069bc:	00024717          	auipc	a4,0x24
    800069c0:	64470713          	addi	a4,a4,1604 # 8002b000 <disk>
    800069c4:	00c75793          	srli	a5,a4,0xc
    800069c8:	2781                	sext.w	a5,a5
    800069ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800069cc:	00026797          	auipc	a5,0x26
    800069d0:	63478793          	addi	a5,a5,1588 # 8002d000 <disk+0x2000>
    800069d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800069d6:	00024717          	auipc	a4,0x24
    800069da:	6aa70713          	addi	a4,a4,1706 # 8002b080 <disk+0x80>
    800069de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800069e0:	00025717          	auipc	a4,0x25
    800069e4:	62070713          	addi	a4,a4,1568 # 8002c000 <disk+0x1000>
    800069e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800069ea:	4705                	li	a4,1
    800069ec:	00e78c23          	sb	a4,24(a5)
    800069f0:	00e78ca3          	sb	a4,25(a5)
    800069f4:	00e78d23          	sb	a4,26(a5)
    800069f8:	00e78da3          	sb	a4,27(a5)
    800069fc:	00e78e23          	sb	a4,28(a5)
    80006a00:	00e78ea3          	sb	a4,29(a5)
    80006a04:	00e78f23          	sb	a4,30(a5)
    80006a08:	00e78fa3          	sb	a4,31(a5)
}
    80006a0c:	60e2                	ld	ra,24(sp)
    80006a0e:	6442                	ld	s0,16(sp)
    80006a10:	64a2                	ld	s1,8(sp)
    80006a12:	6105                	addi	sp,sp,32
    80006a14:	8082                	ret
    panic("could not find virtio disk");
    80006a16:	00002517          	auipc	a0,0x2
    80006a1a:	e7250513          	addi	a0,a0,-398 # 80008888 <syscalls+0x388>
    80006a1e:	ffffa097          	auipc	ra,0xffffa
    80006a22:	b0c080e7          	jalr	-1268(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006a26:	00002517          	auipc	a0,0x2
    80006a2a:	e8250513          	addi	a0,a0,-382 # 800088a8 <syscalls+0x3a8>
    80006a2e:	ffffa097          	auipc	ra,0xffffa
    80006a32:	afc080e7          	jalr	-1284(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006a36:	00002517          	auipc	a0,0x2
    80006a3a:	e9250513          	addi	a0,a0,-366 # 800088c8 <syscalls+0x3c8>
    80006a3e:	ffffa097          	auipc	ra,0xffffa
    80006a42:	aec080e7          	jalr	-1300(ra) # 8000052a <panic>

0000000080006a46 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a46:	7119                	addi	sp,sp,-128
    80006a48:	fc86                	sd	ra,120(sp)
    80006a4a:	f8a2                	sd	s0,112(sp)
    80006a4c:	f4a6                	sd	s1,104(sp)
    80006a4e:	f0ca                	sd	s2,96(sp)
    80006a50:	ecce                	sd	s3,88(sp)
    80006a52:	e8d2                	sd	s4,80(sp)
    80006a54:	e4d6                	sd	s5,72(sp)
    80006a56:	e0da                	sd	s6,64(sp)
    80006a58:	fc5e                	sd	s7,56(sp)
    80006a5a:	f862                	sd	s8,48(sp)
    80006a5c:	f466                	sd	s9,40(sp)
    80006a5e:	f06a                	sd	s10,32(sp)
    80006a60:	ec6e                	sd	s11,24(sp)
    80006a62:	0100                	addi	s0,sp,128
    80006a64:	8aaa                	mv	s5,a0
    80006a66:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006a68:	00c52c83          	lw	s9,12(a0)
    80006a6c:	001c9c9b          	slliw	s9,s9,0x1
    80006a70:	1c82                	slli	s9,s9,0x20
    80006a72:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006a76:	00026517          	auipc	a0,0x26
    80006a7a:	6b250513          	addi	a0,a0,1714 # 8002d128 <disk+0x2128>
    80006a7e:	ffffa097          	auipc	ra,0xffffa
    80006a82:	154080e7          	jalr	340(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006a86:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006a88:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006a8a:	00024c17          	auipc	s8,0x24
    80006a8e:	576c0c13          	addi	s8,s8,1398 # 8002b000 <disk>
    80006a92:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006a94:	4b0d                	li	s6,3
    80006a96:	a0ad                	j	80006b00 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006a98:	00fc0733          	add	a4,s8,a5
    80006a9c:	975e                	add	a4,a4,s7
    80006a9e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006aa2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006aa4:	0207c563          	bltz	a5,80006ace <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006aa8:	2905                	addiw	s2,s2,1
    80006aaa:	0611                	addi	a2,a2,4
    80006aac:	19690d63          	beq	s2,s6,80006c46 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006ab0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006ab2:	00026717          	auipc	a4,0x26
    80006ab6:	56670713          	addi	a4,a4,1382 # 8002d018 <disk+0x2018>
    80006aba:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006abc:	00074683          	lbu	a3,0(a4)
    80006ac0:	fee1                	bnez	a3,80006a98 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ac2:	2785                	addiw	a5,a5,1
    80006ac4:	0705                	addi	a4,a4,1
    80006ac6:	fe979be3          	bne	a5,s1,80006abc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006aca:	57fd                	li	a5,-1
    80006acc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006ace:	01205d63          	blez	s2,80006ae8 <virtio_disk_rw+0xa2>
    80006ad2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006ad4:	000a2503          	lw	a0,0(s4)
    80006ad8:	00000097          	auipc	ra,0x0
    80006adc:	d8e080e7          	jalr	-626(ra) # 80006866 <free_desc>
      for(int j = 0; j < i; j++)
    80006ae0:	2d85                	addiw	s11,s11,1
    80006ae2:	0a11                	addi	s4,s4,4
    80006ae4:	ffb918e3          	bne	s2,s11,80006ad4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ae8:	00026597          	auipc	a1,0x26
    80006aec:	64058593          	addi	a1,a1,1600 # 8002d128 <disk+0x2128>
    80006af0:	00026517          	auipc	a0,0x26
    80006af4:	52850513          	addi	a0,a0,1320 # 8002d018 <disk+0x2018>
    80006af8:	ffffc097          	auipc	ra,0xffffc
    80006afc:	c84080e7          	jalr	-892(ra) # 8000277c <sleep>
  for(int i = 0; i < 3; i++){
    80006b00:	f8040a13          	addi	s4,s0,-128
{
    80006b04:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006b06:	894e                	mv	s2,s3
    80006b08:	b765                	j	80006ab0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006b0a:	00026697          	auipc	a3,0x26
    80006b0e:	4f66b683          	ld	a3,1270(a3) # 8002d000 <disk+0x2000>
    80006b12:	96ba                	add	a3,a3,a4
    80006b14:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006b18:	00024817          	auipc	a6,0x24
    80006b1c:	4e880813          	addi	a6,a6,1256 # 8002b000 <disk>
    80006b20:	00026697          	auipc	a3,0x26
    80006b24:	4e068693          	addi	a3,a3,1248 # 8002d000 <disk+0x2000>
    80006b28:	6290                	ld	a2,0(a3)
    80006b2a:	963a                	add	a2,a2,a4
    80006b2c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006b30:	0015e593          	ori	a1,a1,1
    80006b34:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006b38:	f8842603          	lw	a2,-120(s0)
    80006b3c:	628c                	ld	a1,0(a3)
    80006b3e:	972e                	add	a4,a4,a1
    80006b40:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006b44:	20050593          	addi	a1,a0,512
    80006b48:	0592                	slli	a1,a1,0x4
    80006b4a:	95c2                	add	a1,a1,a6
    80006b4c:	577d                	li	a4,-1
    80006b4e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006b52:	00461713          	slli	a4,a2,0x4
    80006b56:	6290                	ld	a2,0(a3)
    80006b58:	963a                	add	a2,a2,a4
    80006b5a:	03078793          	addi	a5,a5,48
    80006b5e:	97c2                	add	a5,a5,a6
    80006b60:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006b62:	629c                	ld	a5,0(a3)
    80006b64:	97ba                	add	a5,a5,a4
    80006b66:	4605                	li	a2,1
    80006b68:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006b6a:	629c                	ld	a5,0(a3)
    80006b6c:	97ba                	add	a5,a5,a4
    80006b6e:	4809                	li	a6,2
    80006b70:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006b74:	629c                	ld	a5,0(a3)
    80006b76:	973e                	add	a4,a4,a5
    80006b78:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006b7c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006b80:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006b84:	6698                	ld	a4,8(a3)
    80006b86:	00275783          	lhu	a5,2(a4)
    80006b8a:	8b9d                	andi	a5,a5,7
    80006b8c:	0786                	slli	a5,a5,0x1
    80006b8e:	97ba                	add	a5,a5,a4
    80006b90:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006b94:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006b98:	6698                	ld	a4,8(a3)
    80006b9a:	00275783          	lhu	a5,2(a4)
    80006b9e:	2785                	addiw	a5,a5,1
    80006ba0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006ba4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006ba8:	100017b7          	lui	a5,0x10001
    80006bac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006bb0:	004aa783          	lw	a5,4(s5)
    80006bb4:	02c79163          	bne	a5,a2,80006bd6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006bb8:	00026917          	auipc	s2,0x26
    80006bbc:	57090913          	addi	s2,s2,1392 # 8002d128 <disk+0x2128>
  while(b->disk == 1) {
    80006bc0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006bc2:	85ca                	mv	a1,s2
    80006bc4:	8556                	mv	a0,s5
    80006bc6:	ffffc097          	auipc	ra,0xffffc
    80006bca:	bb6080e7          	jalr	-1098(ra) # 8000277c <sleep>
  while(b->disk == 1) {
    80006bce:	004aa783          	lw	a5,4(s5)
    80006bd2:	fe9788e3          	beq	a5,s1,80006bc2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006bd6:	f8042903          	lw	s2,-128(s0)
    80006bda:	20090793          	addi	a5,s2,512
    80006bde:	00479713          	slli	a4,a5,0x4
    80006be2:	00024797          	auipc	a5,0x24
    80006be6:	41e78793          	addi	a5,a5,1054 # 8002b000 <disk>
    80006bea:	97ba                	add	a5,a5,a4
    80006bec:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006bf0:	00026997          	auipc	s3,0x26
    80006bf4:	41098993          	addi	s3,s3,1040 # 8002d000 <disk+0x2000>
    80006bf8:	00491713          	slli	a4,s2,0x4
    80006bfc:	0009b783          	ld	a5,0(s3)
    80006c00:	97ba                	add	a5,a5,a4
    80006c02:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c06:	854a                	mv	a0,s2
    80006c08:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c0c:	00000097          	auipc	ra,0x0
    80006c10:	c5a080e7          	jalr	-934(ra) # 80006866 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c14:	8885                	andi	s1,s1,1
    80006c16:	f0ed                	bnez	s1,80006bf8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c18:	00026517          	auipc	a0,0x26
    80006c1c:	51050513          	addi	a0,a0,1296 # 8002d128 <disk+0x2128>
    80006c20:	ffffa097          	auipc	ra,0xffffa
    80006c24:	066080e7          	jalr	102(ra) # 80000c86 <release>
}
    80006c28:	70e6                	ld	ra,120(sp)
    80006c2a:	7446                	ld	s0,112(sp)
    80006c2c:	74a6                	ld	s1,104(sp)
    80006c2e:	7906                	ld	s2,96(sp)
    80006c30:	69e6                	ld	s3,88(sp)
    80006c32:	6a46                	ld	s4,80(sp)
    80006c34:	6aa6                	ld	s5,72(sp)
    80006c36:	6b06                	ld	s6,64(sp)
    80006c38:	7be2                	ld	s7,56(sp)
    80006c3a:	7c42                	ld	s8,48(sp)
    80006c3c:	7ca2                	ld	s9,40(sp)
    80006c3e:	7d02                	ld	s10,32(sp)
    80006c40:	6de2                	ld	s11,24(sp)
    80006c42:	6109                	addi	sp,sp,128
    80006c44:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c46:	f8042503          	lw	a0,-128(s0)
    80006c4a:	20050793          	addi	a5,a0,512
    80006c4e:	0792                	slli	a5,a5,0x4
  if(write)
    80006c50:	00024817          	auipc	a6,0x24
    80006c54:	3b080813          	addi	a6,a6,944 # 8002b000 <disk>
    80006c58:	00f80733          	add	a4,a6,a5
    80006c5c:	01a036b3          	snez	a3,s10
    80006c60:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006c64:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006c68:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c6c:	7679                	lui	a2,0xffffe
    80006c6e:	963e                	add	a2,a2,a5
    80006c70:	00026697          	auipc	a3,0x26
    80006c74:	39068693          	addi	a3,a3,912 # 8002d000 <disk+0x2000>
    80006c78:	6298                	ld	a4,0(a3)
    80006c7a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006c7c:	0a878593          	addi	a1,a5,168
    80006c80:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006c82:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006c84:	6298                	ld	a4,0(a3)
    80006c86:	9732                	add	a4,a4,a2
    80006c88:	45c1                	li	a1,16
    80006c8a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006c8c:	6298                	ld	a4,0(a3)
    80006c8e:	9732                	add	a4,a4,a2
    80006c90:	4585                	li	a1,1
    80006c92:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006c96:	f8442703          	lw	a4,-124(s0)
    80006c9a:	628c                	ld	a1,0(a3)
    80006c9c:	962e                	add	a2,a2,a1
    80006c9e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd000e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ca2:	0712                	slli	a4,a4,0x4
    80006ca4:	6290                	ld	a2,0(a3)
    80006ca6:	963a                	add	a2,a2,a4
    80006ca8:	058a8593          	addi	a1,s5,88
    80006cac:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006cae:	6294                	ld	a3,0(a3)
    80006cb0:	96ba                	add	a3,a3,a4
    80006cb2:	40000613          	li	a2,1024
    80006cb6:	c690                	sw	a2,8(a3)
  if(write)
    80006cb8:	e40d19e3          	bnez	s10,80006b0a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006cbc:	00026697          	auipc	a3,0x26
    80006cc0:	3446b683          	ld	a3,836(a3) # 8002d000 <disk+0x2000>
    80006cc4:	96ba                	add	a3,a3,a4
    80006cc6:	4609                	li	a2,2
    80006cc8:	00c69623          	sh	a2,12(a3)
    80006ccc:	b5b1                	j	80006b18 <virtio_disk_rw+0xd2>

0000000080006cce <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006cce:	1101                	addi	sp,sp,-32
    80006cd0:	ec06                	sd	ra,24(sp)
    80006cd2:	e822                	sd	s0,16(sp)
    80006cd4:	e426                	sd	s1,8(sp)
    80006cd6:	e04a                	sd	s2,0(sp)
    80006cd8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006cda:	00026517          	auipc	a0,0x26
    80006cde:	44e50513          	addi	a0,a0,1102 # 8002d128 <disk+0x2128>
    80006ce2:	ffffa097          	auipc	ra,0xffffa
    80006ce6:	ef0080e7          	jalr	-272(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006cea:	10001737          	lui	a4,0x10001
    80006cee:	533c                	lw	a5,96(a4)
    80006cf0:	8b8d                	andi	a5,a5,3
    80006cf2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006cf4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006cf8:	00026797          	auipc	a5,0x26
    80006cfc:	30878793          	addi	a5,a5,776 # 8002d000 <disk+0x2000>
    80006d00:	6b94                	ld	a3,16(a5)
    80006d02:	0207d703          	lhu	a4,32(a5)
    80006d06:	0026d783          	lhu	a5,2(a3)
    80006d0a:	06f70163          	beq	a4,a5,80006d6c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d0e:	00024917          	auipc	s2,0x24
    80006d12:	2f290913          	addi	s2,s2,754 # 8002b000 <disk>
    80006d16:	00026497          	auipc	s1,0x26
    80006d1a:	2ea48493          	addi	s1,s1,746 # 8002d000 <disk+0x2000>
    __sync_synchronize();
    80006d1e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d22:	6898                	ld	a4,16(s1)
    80006d24:	0204d783          	lhu	a5,32(s1)
    80006d28:	8b9d                	andi	a5,a5,7
    80006d2a:	078e                	slli	a5,a5,0x3
    80006d2c:	97ba                	add	a5,a5,a4
    80006d2e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d30:	20078713          	addi	a4,a5,512
    80006d34:	0712                	slli	a4,a4,0x4
    80006d36:	974a                	add	a4,a4,s2
    80006d38:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006d3c:	e731                	bnez	a4,80006d88 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d3e:	20078793          	addi	a5,a5,512
    80006d42:	0792                	slli	a5,a5,0x4
    80006d44:	97ca                	add	a5,a5,s2
    80006d46:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006d48:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d4c:	ffffc097          	auipc	ra,0xffffc
    80006d50:	bbc080e7          	jalr	-1092(ra) # 80002908 <wakeup>

    disk.used_idx += 1;
    80006d54:	0204d783          	lhu	a5,32(s1)
    80006d58:	2785                	addiw	a5,a5,1
    80006d5a:	17c2                	slli	a5,a5,0x30
    80006d5c:	93c1                	srli	a5,a5,0x30
    80006d5e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d62:	6898                	ld	a4,16(s1)
    80006d64:	00275703          	lhu	a4,2(a4)
    80006d68:	faf71be3          	bne	a4,a5,80006d1e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006d6c:	00026517          	auipc	a0,0x26
    80006d70:	3bc50513          	addi	a0,a0,956 # 8002d128 <disk+0x2128>
    80006d74:	ffffa097          	auipc	ra,0xffffa
    80006d78:	f12080e7          	jalr	-238(ra) # 80000c86 <release>
}
    80006d7c:	60e2                	ld	ra,24(sp)
    80006d7e:	6442                	ld	s0,16(sp)
    80006d80:	64a2                	ld	s1,8(sp)
    80006d82:	6902                	ld	s2,0(sp)
    80006d84:	6105                	addi	sp,sp,32
    80006d86:	8082                	ret
      panic("virtio_disk_intr status");
    80006d88:	00002517          	auipc	a0,0x2
    80006d8c:	b6050513          	addi	a0,a0,-1184 # 800088e8 <syscalls+0x3e8>
    80006d90:	ffff9097          	auipc	ra,0xffff9
    80006d94:	79a080e7          	jalr	1946(ra) # 8000052a <panic>
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
