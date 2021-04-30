
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
    80000068:	c6c78793          	addi	a5,a5,-916 # 80006cd0 <timervec>
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
    80000122:	f74080e7          	jalr	-140(ra) # 80003092 <either_copyin>
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
    800001b6:	228080e7          	jalr	552(ra) # 800023da <myproc>
    800001ba:	551c                	lw	a5,40(a0)
    800001bc:	e7b5                	bnez	a5,80000228 <consoleread+0xd2>
      sleep(&cons.r, &cons.lock);
    800001be:	85a6                	mv	a1,s1
    800001c0:	854a                	mv	a0,s2
    800001c2:	00003097          	auipc	ra,0x3
    800001c6:	ac0080e7          	jalr	-1344(ra) # 80002c82 <sleep>
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
    80000202:	e3e080e7          	jalr	-450(ra) # 8000303c <either_copyout>
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
    800002e2:	e0a080e7          	jalr	-502(ra) # 800030e8 <procdump>
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
    80000436:	9dc080e7          	jalr	-1572(ra) # 80002e0e <wakeup>
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
    8000055c:	ce050513          	addi	a0,a0,-800 # 80009238 <digits+0x1f8>
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
    80000882:	590080e7          	jalr	1424(ra) # 80002e0e <wakeup>
    
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
    8000090e:	378080e7          	jalr	888(ra) # 80002c82 <sleep>
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
    80000b70:	852080e7          	jalr	-1966(ra) # 800023be <mycpu>
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
    80000ba2:	820080e7          	jalr	-2016(ra) # 800023be <mycpu>
    80000ba6:	5d3c                	lw	a5,120(a0)
    80000ba8:	cf89                	beqz	a5,80000bc2 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000baa:	00002097          	auipc	ra,0x2
    80000bae:	814080e7          	jalr	-2028(ra) # 800023be <mycpu>
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
    80000bc6:	7fc080e7          	jalr	2044(ra) # 800023be <mycpu>
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
    80000c06:	7bc080e7          	jalr	1980(ra) # 800023be <mycpu>
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
    80000c32:	790080e7          	jalr	1936(ra) # 800023be <mycpu>
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
    80000e88:	52a080e7          	jalr	1322(ra) # 800023ae <cpuid>
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
    80000ea4:	50e080e7          	jalr	1294(ra) # 800023ae <cpuid>
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
    80000ec6:	368080e7          	jalr	872(ra) # 8000322a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eca:	00006097          	auipc	ra,0x6
    80000ece:	e46080e7          	jalr	-442(ra) # 80006d10 <plicinithart>
  }

  scheduler();        
    80000ed2:	00002097          	auipc	ra,0x2
    80000ed6:	bf6080e7          	jalr	-1034(ra) # 80002ac8 <scheduler>
    consoleinit();
    80000eda:	fffff097          	auipc	ra,0xfffff
    80000ede:	562080e7          	jalr	1378(ra) # 8000043c <consoleinit>
    printfinit();
    80000ee2:	00000097          	auipc	ra,0x0
    80000ee6:	872080e7          	jalr	-1934(ra) # 80000754 <printfinit>
    printf("\n");
    80000eea:	00008517          	auipc	a0,0x8
    80000eee:	34e50513          	addi	a0,a0,846 # 80009238 <digits+0x1f8>
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	682080e7          	jalr	1666(ra) # 80000574 <printf>
    printf("xv6 kernel is booting\n");
    80000efa:	00008517          	auipc	a0,0x8
    80000efe:	1be50513          	addi	a0,a0,446 # 800090b8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	672080e7          	jalr	1650(ra) # 80000574 <printf>
    printf("\n");
    80000f0a:	00008517          	auipc	a0,0x8
    80000f0e:	32e50513          	addi	a0,a0,814 # 80009238 <digits+0x1f8>
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
    80000f36:	3cc080e7          	jalr	972(ra) # 800022fe <procinit>
    trapinit();      // trap vectors
    80000f3a:	00002097          	auipc	ra,0x2
    80000f3e:	2c8080e7          	jalr	712(ra) # 80003202 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	2e8080e7          	jalr	744(ra) # 8000322a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f4a:	00006097          	auipc	ra,0x6
    80000f4e:	db0080e7          	jalr	-592(ra) # 80006cfa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f52:	00006097          	auipc	ra,0x6
    80000f56:	dbe080e7          	jalr	-578(ra) # 80006d10 <plicinithart>
    binit();         // buffer cache
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	a2e080e7          	jalr	-1490(ra) # 80003988 <binit>
    iinit();         // inode cache
    80000f62:	00003097          	auipc	ra,0x3
    80000f66:	0c0080e7          	jalr	192(ra) # 80004022 <iinit>
    fileinit();      // file table
    80000f6a:	00004097          	auipc	ra,0x4
    80000f6e:	39e080e7          	jalr	926(ra) # 80005308 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f72:	00006097          	auipc	ra,0x6
    80000f76:	ec0080e7          	jalr	-320(ra) # 80006e32 <virtio_disk_init>
    userinit();      // first user process
    80000f7a:	00001097          	auipc	ra,0x1
    80000f7e:	774080e7          	jalr	1908(ra) # 800026ee <userinit>
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
    8000120a:	062080e7          	jalr	98(ra) # 80002268 <proc_mapstacks>
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
    800013ac:	032080e7          	jalr	50(ra) # 800023da <myproc>
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
    80001658:	7179                	addi	sp,sp,-48
    8000165a:	f406                	sd	ra,40(sp)
    8000165c:	f022                	sd	s0,32(sp)
    8000165e:	ec26                	sd	s1,24(sp)
    80001660:	e84a                	sd	s2,16(sp)
    80001662:	e44e                	sd	s3,8(sp)
    80001664:	e052                	sd	s4,0(sp)
    80001666:	1800                	addi	s0,sp,48
  int counter = 0;
  for(int i=0; i<32; i++){
    80001668:	4481                	li	s1,0
  int counter = 0;
    8000166a:	4981                	li	s3,0
    if(myproc()->paging_meta_data[i].in_memory){
      printf("pid %d , %d in memory\n", myproc()->pid, i);
    8000166c:	00008a17          	auipc	s4,0x8
    80001670:	b24a0a13          	addi	s4,s4,-1244 # 80009190 <digits+0x150>
  for(int i=0; i<32; i++){
    80001674:	02000913          	li	s2,32
    80001678:	a021                	j	80001680 <get_num_of_pages_in_memory+0x28>
    8000167a:	2485                	addiw	s1,s1,1
    8000167c:	03248b63          	beq	s1,s2,800016b2 <get_num_of_pages_in_memory+0x5a>
    if(myproc()->paging_meta_data[i].in_memory){
    80001680:	00001097          	auipc	ra,0x1
    80001684:	d5a080e7          	jalr	-678(ra) # 800023da <myproc>
    80001688:	00149793          	slli	a5,s1,0x1
    8000168c:	97a6                	add	a5,a5,s1
    8000168e:	078a                	slli	a5,a5,0x2
    80001690:	97aa                	add	a5,a5,a0
    80001692:	1787a783          	lw	a5,376(a5)
    80001696:	d3f5                	beqz	a5,8000167a <get_num_of_pages_in_memory+0x22>
      printf("pid %d , %d in memory\n", myproc()->pid, i);
    80001698:	00001097          	auipc	ra,0x1
    8000169c:	d42080e7          	jalr	-702(ra) # 800023da <myproc>
    800016a0:	8626                	mv	a2,s1
    800016a2:	590c                	lw	a1,48(a0)
    800016a4:	8552                	mv	a0,s4
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	ece080e7          	jalr	-306(ra) # 80000574 <printf>
      counter = counter+1;
    800016ae:	2985                	addiw	s3,s3,1
    800016b0:	b7e9                	j	8000167a <get_num_of_pages_in_memory+0x22>
    }
  }
  return counter; 
}
    800016b2:	854e                	mv	a0,s3
    800016b4:	70a2                	ld	ra,40(sp)
    800016b6:	7402                	ld	s0,32(sp)
    800016b8:	64e2                	ld	s1,24(sp)
    800016ba:	6942                	ld	s2,16(sp)
    800016bc:	69a2                	ld	s3,8(sp)
    800016be:	6a02                	ld	s4,0(sp)
    800016c0:	6145                	addi	sp,sp,48
    800016c2:	8082                	ret

00000000800016c4 <minimum_counter_NFUA>:
  else
    exit(-1);
}


int minimum_counter_NFUA(){
    800016c4:	1141                	addi	sp,sp,-16
    800016c6:	e406                	sd	ra,8(sp)
    800016c8:	e022                	sd	s0,0(sp)
    800016ca:	0800                	addi	s0,sp,16
  struct proc * p = myproc();
    800016cc:	00001097          	auipc	ra,0x1
    800016d0:	d0e080e7          	jalr	-754(ra) # 800023da <myproc>
  uint min_age = -1;
  int index_page = -1;
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    800016d4:	19850793          	addi	a5,a0,408
    800016d8:	470d                	li	a4,3
  int index_page = -1;
    800016da:	557d                	li	a0,-1
  uint min_age = -1;
    800016dc:	55fd                	li	a1,-1
    if (p->paging_meta_data[i].in_memory ){
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    800016de:	58fd                	li	a7,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    800016e0:	02000813          	li	a6,32
    800016e4:	a039                	j	800016f2 <minimum_counter_NFUA+0x2e>
          min_age = p->paging_meta_data[i].aging;
    800016e6:	420c                	lw	a1,0(a2)
    800016e8:	853a                	mv	a0,a4
  for (int i = USER_MEMORY_INDEX; i <32; i++){ 
    800016ea:	2705                	addiw	a4,a4,1
    800016ec:	07b1                	addi	a5,a5,12
    800016ee:	01070b63          	beq	a4,a6,80001704 <minimum_counter_NFUA+0x40>
    if (p->paging_meta_data[i].in_memory ){
    800016f2:	863e                	mv	a2,a5
    800016f4:	43d4                	lw	a3,4(a5)
    800016f6:	daf5                	beqz	a3,800016ea <minimum_counter_NFUA+0x26>
        if (min_age == -1 || (uint)p->paging_meta_data[i].aging < min_age){
    800016f8:	ff1587e3          	beq	a1,a7,800016e6 <minimum_counter_NFUA+0x22>
    800016fc:	4394                	lw	a3,0(a5)
    800016fe:	feb6f6e3          	bgeu	a3,a1,800016ea <minimum_counter_NFUA+0x26>
    80001702:	b7d5                	j	800016e6 <minimum_counter_NFUA+0x22>
          index_page = i;
        }
      }
  }
  if(min_age == -1)
    80001704:	57fd                	li	a5,-1
    80001706:	00f58663          	beq	a1,a5,80001712 <minimum_counter_NFUA+0x4e>
    panic("page replacment algorithem failed");
  return index_page;
}
    8000170a:	60a2                	ld	ra,8(sp)
    8000170c:	6402                	ld	s0,0(sp)
    8000170e:	0141                	addi	sp,sp,16
    80001710:	8082                	ret
    panic("page replacment algorithem failed");
    80001712:	00008517          	auipc	a0,0x8
    80001716:	a9650513          	addi	a0,a0,-1386 # 800091a8 <digits+0x168>
    8000171a:	fffff097          	auipc	ra,0xfffff
    8000171e:	e10080e7          	jalr	-496(ra) # 8000052a <panic>

0000000080001722 <count_one_bits>:

int count_one_bits(uint age){
    80001722:	1141                	addi	sp,sp,-16
    80001724:	e422                	sd	s0,8(sp)
    80001726:	0800                	addi	s0,sp,16
  int count = 0;
  while(age) {
    80001728:	cd01                	beqz	a0,80001740 <count_one_bits+0x1e>
    8000172a:	87aa                	mv	a5,a0
  int count = 0;
    8000172c:	4501                	li	a0,0
      count += age & 1;
    8000172e:	0017f713          	andi	a4,a5,1
    80001732:	9d39                	addw	a0,a0,a4
      age >>= 1;
    80001734:	0017d79b          	srliw	a5,a5,0x1
  while(age) {
    80001738:	fbfd                	bnez	a5,8000172e <count_one_bits+0xc>
  }
  return count;
}
    8000173a:	6422                	ld	s0,8(sp)
    8000173c:	0141                	addi	sp,sp,16
    8000173e:	8082                	ret
  int count = 0;
    80001740:	4501                	li	a0,0
    80001742:	bfe5                	j	8000173a <count_one_bits+0x18>

0000000080001744 <minimum_ones>:

int minimum_ones(){
    80001744:	715d                	addi	sp,sp,-80
    80001746:	e486                	sd	ra,72(sp)
    80001748:	e0a2                	sd	s0,64(sp)
    8000174a:	fc26                	sd	s1,56(sp)
    8000174c:	f84a                	sd	s2,48(sp)
    8000174e:	f44e                	sd	s3,40(sp)
    80001750:	f052                	sd	s4,32(sp)
    80001752:	ec56                	sd	s5,24(sp)
    80001754:	e85a                	sd	s6,16(sp)
    80001756:	e45e                	sd	s7,8(sp)
    80001758:	e062                	sd	s8,0(sp)
    8000175a:	0880                	addi	s0,sp,80
  struct proc * p = myproc();
    8000175c:	00001097          	auipc	ra,0x1
    80001760:	c7e080e7          	jalr	-898(ra) # 800023da <myproc>
  int min_ones = -1;
  int min_age = -1;
  int index_page = -1;
  uint age;
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001764:	19850493          	addi	s1,a0,408
    80001768:	490d                	li	s2,3
  int index_page = -1;
    8000176a:	5c7d                	li	s8,-1
  int min_age = -1;
    8000176c:	5bfd                	li	s7,-1
  int min_ones = -1;
    8000176e:	5a7d                	li	s4,-1
    if (p->paging_meta_data[i].in_memory ){
      age =  p->paging_meta_data[i].aging;
      int count_ones =  count_one_bits(age);
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    80001770:	5b7d                	li	s6,-1
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001772:	02000993          	li	s3,32
    80001776:	a809                	j	80001788 <minimum_ones+0x44>
        min_ones = count_ones;
        min_age = age;
    80001778:	000a8b9b          	sext.w	s7,s5
    8000177c:	8c4a                	mv	s8,s2
        min_ones = count_ones;
    8000177e:	8a2a                	mv	s4,a0
  for (int i = USER_MEMORY_INDEX; i <32; i++){
    80001780:	2905                	addiw	s2,s2,1
    80001782:	04b1                	addi	s1,s1,12
    80001784:	03390663          	beq	s2,s3,800017b0 <minimum_ones+0x6c>
    if (p->paging_meta_data[i].in_memory ){
    80001788:	40dc                	lw	a5,4(s1)
    8000178a:	dbfd                	beqz	a5,80001780 <minimum_ones+0x3c>
      age =  p->paging_meta_data[i].aging;
    8000178c:	0004aa83          	lw	s5,0(s1)
      int count_ones =  count_one_bits(age);
    80001790:	8556                	mv	a0,s5
    80001792:	00000097          	auipc	ra,0x0
    80001796:	f90080e7          	jalr	-112(ra) # 80001722 <count_one_bits>
      if (min_ones == -1 || count_ones < min_ones || (count_ones == min_ones && age < min_age)){
    8000179a:	fd6a0fe3          	beq	s4,s6,80001778 <minimum_ones+0x34>
    8000179e:	fd454de3          	blt	a0,s4,80001778 <minimum_ones+0x34>
    800017a2:	fd451fe3          	bne	a0,s4,80001780 <minimum_ones+0x3c>
    800017a6:	000b879b          	sext.w	a5,s7
    800017aa:	fcfafbe3          	bgeu	s5,a5,80001780 <minimum_ones+0x3c>
    800017ae:	b7e9                	j	80001778 <minimum_ones+0x34>
        index_page = i;
      }
    }
  }
  if(min_ones == -1)
    800017b0:	57fd                	li	a5,-1
    800017b2:	00fa0f63          	beq	s4,a5,800017d0 <minimum_ones+0x8c>
    panic("page replacment algorithem failed");
  return index_page;
}
    800017b6:	8562                	mv	a0,s8
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6c02                	ld	s8,0(sp)
    800017cc:	6161                	addi	sp,sp,80
    800017ce:	8082                	ret
    panic("page replacment algorithem failed");
    800017d0:	00008517          	auipc	a0,0x8
    800017d4:	9d850513          	addi	a0,a0,-1576 # 800091a8 <digits+0x168>
    800017d8:	fffff097          	auipc	ra,0xfffff
    800017dc:	d52080e7          	jalr	-686(ra) # 8000052a <panic>

00000000800017e0 <insert_to_queue>:
uint64 insert_to_queue(int inserted_page){
    800017e0:	1101                	addi	sp,sp,-32
    800017e2:	ec06                	sd	ra,24(sp)
    800017e4:	e822                	sd	s0,16(sp)
    800017e6:	e426                	sd	s1,8(sp)
    800017e8:	1000                	addi	s0,sp,32
    800017ea:	84aa                	mv	s1,a0
  struct proc * process = myproc();
    800017ec:	00001097          	auipc	ra,0x1
    800017f0:	bee080e7          	jalr	-1042(ra) # 800023da <myproc>
  struct age_queue * q = &process->queue;
  if(inserted_page >= 3){
    800017f4:	4789                	li	a5,2
    800017f6:	0297d763          	bge	a5,s1,80001824 <insert_to_queue+0x44>
    if (q->last == 31)
    800017fa:	37452703          	lw	a4,884(a0)
    800017fe:	47fd                	li	a5,31
    80001800:	02f70863          	beq	a4,a5,80001830 <insert_to_queue+0x50>
      q->last = -1;
    q->last = q->last + 1;
    80001804:	37452703          	lw	a4,884(a0)
    80001808:	2705                	addiw	a4,a4,1
    8000180a:	0007079b          	sext.w	a5,a4
    8000180e:	36e52a23          	sw	a4,884(a0)
    q->pages[q->last] =inserted_page;
    80001812:	078a                	slli	a5,a5,0x2
    80001814:	97aa                	add	a5,a5,a0
    80001816:	2e97a823          	sw	s1,752(a5)
    q->page_counter =  q->page_counter + 1;
    8000181a:	37852783          	lw	a5,888(a0)
    8000181e:	2785                	addiw	a5,a5,1
    80001820:	36f52c23          	sw	a5,888(a0)
  }
  return 0;
}
    80001824:	4501                	li	a0,0
    80001826:	60e2                	ld	ra,24(sp)
    80001828:	6442                	ld	s0,16(sp)
    8000182a:	64a2                	ld	s1,8(sp)
    8000182c:	6105                	addi	sp,sp,32
    8000182e:	8082                	ret
      q->last = -1;
    80001830:	57fd                	li	a5,-1
    80001832:	36f52a23          	sw	a5,884(a0)
    80001836:	b7f9                	j	80001804 <insert_to_queue+0x24>

0000000080001838 <remove_from_queue>:

void remove_from_queue(struct age_queue * q){
    80001838:	1141                	addi	sp,sp,-16
    8000183a:	e422                	sd	s0,8(sp)
    8000183c:	0800                	addi	s0,sp,16
  q->front = q->front+1;
    8000183e:	08052783          	lw	a5,128(a0)
    80001842:	2785                	addiw	a5,a5,1
    80001844:	0007869b          	sext.w	a3,a5
   if(q->front == 32) {
    80001848:	02000713          	li	a4,32
    8000184c:	00e68c63          	beq	a3,a4,80001864 <remove_from_queue+0x2c>
  q->front = q->front+1;
    80001850:	08f52023          	sw	a5,128(a0)
      q->front = 0;
   }
   q->page_counter = q->page_counter-1;
    80001854:	08852783          	lw	a5,136(a0)
    80001858:	37fd                	addiw	a5,a5,-1
    8000185a:	08f52423          	sw	a5,136(a0)
   
}
    8000185e:	6422                	ld	s0,8(sp)
    80001860:	0141                	addi	sp,sp,16
    80001862:	8082                	ret
      q->front = 0;
    80001864:	08052023          	sw	zero,128(a0)
    80001868:	b7f5                	j	80001854 <remove_from_queue+0x1c>

000000008000186a <remove_from_queue_not_in_memory>:
void
remove_from_queue_not_in_memory(int page_num_removed){
    8000186a:	7139                	addi	sp,sp,-64
    8000186c:	fc06                	sd	ra,56(sp)
    8000186e:	f822                	sd	s0,48(sp)
    80001870:	f426                	sd	s1,40(sp)
    80001872:	f04a                	sd	s2,32(sp)
    80001874:	ec4e                	sd	s3,24(sp)
    80001876:	e852                	sd	s4,16(sp)
    80001878:	e456                	sd	s5,8(sp)
    8000187a:	e05a                	sd	s6,0(sp)
    8000187c:	0080                	addi	s0,sp,64
    8000187e:	8a2a                	mv	s4,a0
  struct proc * p = myproc();
    80001880:	00001097          	auipc	ra,0x1
    80001884:	b5a080e7          	jalr	-1190(ra) # 800023da <myproc>
  struct age_queue * q = &(p->queue);
  int cur_page;
  int page_count = q->page_counter;
    80001888:	37852a83          	lw	s5,888(a0)
  for(int i = 0; i<page_count; i++){
    8000188c:	03505d63          	blez	s5,800018c6 <remove_from_queue_not_in_memory+0x5c>
    80001890:	892a                	mv	s2,a0
    80001892:	2f050b13          	addi	s6,a0,752
    80001896:	4481                	li	s1,0
    80001898:	a021                	j	800018a0 <remove_from_queue_not_in_memory+0x36>
    8000189a:	2485                	addiw	s1,s1,1
    8000189c:	029a8563          	beq	s5,s1,800018c6 <remove_from_queue_not_in_memory+0x5c>
    cur_page = q->pages[q->front];
    800018a0:	37092783          	lw	a5,880(s2) # 1370 <_entry-0x7fffec90>
    800018a4:	078a                	slli	a5,a5,0x2
    800018a6:	97ca                	add	a5,a5,s2
    800018a8:	2f07a983          	lw	s3,752(a5)
     remove_from_queue(q);
    800018ac:	855a                	mv	a0,s6
    800018ae:	00000097          	auipc	ra,0x0
    800018b2:	f8a080e7          	jalr	-118(ra) # 80001838 <remove_from_queue>
    if (!(page_num_removed == cur_page)){
    800018b6:	ff4982e3          	beq	s3,s4,8000189a <remove_from_queue_not_in_memory+0x30>
     insert_to_queue(cur_page);
    800018ba:	854e                	mv	a0,s3
    800018bc:	00000097          	auipc	ra,0x0
    800018c0:	f24080e7          	jalr	-220(ra) # 800017e0 <insert_to_queue>
    800018c4:	bfd9                	j	8000189a <remove_from_queue_not_in_memory+0x30>
    }
  }
}
    800018c6:	70e2                	ld	ra,56(sp)
    800018c8:	7442                	ld	s0,48(sp)
    800018ca:	74a2                	ld	s1,40(sp)
    800018cc:	7902                	ld	s2,32(sp)
    800018ce:	69e2                	ld	s3,24(sp)
    800018d0:	6a42                	ld	s4,16(sp)
    800018d2:	6aa2                	ld	s5,8(sp)
    800018d4:	6b02                	ld	s6,0(sp)
    800018d6:	6121                	addi	sp,sp,64
    800018d8:	8082                	ret

00000000800018da <uvmunmap>:
{
    800018da:	711d                	addi	sp,sp,-96
    800018dc:	ec86                	sd	ra,88(sp)
    800018de:	e8a2                	sd	s0,80(sp)
    800018e0:	e4a6                	sd	s1,72(sp)
    800018e2:	e0ca                	sd	s2,64(sp)
    800018e4:	fc4e                	sd	s3,56(sp)
    800018e6:	f852                	sd	s4,48(sp)
    800018e8:	f456                	sd	s5,40(sp)
    800018ea:	f05a                	sd	s6,32(sp)
    800018ec:	ec5e                	sd	s7,24(sp)
    800018ee:	e862                	sd	s8,16(sp)
    800018f0:	e466                	sd	s9,8(sp)
    800018f2:	e06a                	sd	s10,0(sp)
    800018f4:	1080                	addi	s0,sp,96
  if((va % PGSIZE) != 0)
    800018f6:	03459793          	slli	a5,a1,0x34
    800018fa:	eb95                	bnez	a5,8000192e <uvmunmap+0x54>
    800018fc:	8a2a                	mv	s4,a0
    800018fe:	892e                	mv	s2,a1
    80001900:	8b36                	mv	s6,a3
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    80001902:	0632                	slli	a2,a2,0xc
    80001904:	00b609b3          	add	s3,a2,a1
            myproc()->paging_meta_data[ a/PGSIZE].offset = -1;
    80001908:	5c7d                	li	s8,-1
        if(PTE_FLAGS(*pte) == PTE_V)
    8000190a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    8000190c:	6a85                	lui	s5,0x1
    8000190e:	0535e563          	bltu	a1,s3,80001958 <uvmunmap+0x7e>
}
    80001912:	60e6                	ld	ra,88(sp)
    80001914:	6446                	ld	s0,80(sp)
    80001916:	64a6                	ld	s1,72(sp)
    80001918:	6906                	ld	s2,64(sp)
    8000191a:	79e2                	ld	s3,56(sp)
    8000191c:	7a42                	ld	s4,48(sp)
    8000191e:	7aa2                	ld	s5,40(sp)
    80001920:	7b02                	ld	s6,32(sp)
    80001922:	6be2                	ld	s7,24(sp)
    80001924:	6c42                	ld	s8,16(sp)
    80001926:	6ca2                	ld	s9,8(sp)
    80001928:	6d02                	ld	s10,0(sp)
    8000192a:	6125                	addi	sp,sp,96
    8000192c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000192e:	00007517          	auipc	a0,0x7
    80001932:	7ca50513          	addi	a0,a0,1994 # 800090f8 <digits+0xb8>
    80001936:	fffff097          	auipc	ra,0xfffff
    8000193a:	bf4080e7          	jalr	-1036(ra) # 8000052a <panic>
          panic("uvmunmap: not a leaf");
    8000193e:	00007517          	auipc	a0,0x7
    80001942:	7fa50513          	addi	a0,a0,2042 # 80009138 <digits+0xf8>
    80001946:	fffff097          	auipc	ra,0xfffff
    8000194a:	be4080e7          	jalr	-1052(ra) # 8000052a <panic>
        *pte = 0;
    8000194e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){    
    80001952:	9956                	add	s2,s2,s5
    80001954:	fb397fe3          	bgeu	s2,s3,80001912 <uvmunmap+0x38>
    if((pte = walk(pagetable, a, 0)) != 0){
    80001958:	4601                	li	a2,0
    8000195a:	85ca                	mv	a1,s2
    8000195c:	8552                	mv	a0,s4
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	658080e7          	jalr	1624(ra) # 80000fb6 <walk>
    80001966:	84aa                	mv	s1,a0
    80001968:	d56d                	beqz	a0,80001952 <uvmunmap+0x78>
      if((*pte & PTE_V) != 0){
    8000196a:	611c                	ld	a5,0(a0)
    8000196c:	0017f713          	andi	a4,a5,1
    80001970:	cf21                	beqz	a4,800019c8 <uvmunmap+0xee>
        if(PTE_FLAGS(*pte) == PTE_V)
    80001972:	3ff7f713          	andi	a4,a5,1023
    80001976:	fd7704e3          	beq	a4,s7,8000193e <uvmunmap+0x64>
        if(do_free){
    8000197a:	fc0b0ae3          	beqz	s6,8000194e <uvmunmap+0x74>
          uint64 pa = PTE2PA(*pte);
    8000197e:	83a9                	srli	a5,a5,0xa
          kfree((void*)pa);
    80001980:	00c79513          	slli	a0,a5,0xc
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	052080e7          	jalr	82(ra) # 800009d6 <kfree>
            myproc()->paging_meta_data[a/PGSIZE].in_memory = 0;
    8000198c:	00001097          	auipc	ra,0x1
    80001990:	a4e080e7          	jalr	-1458(ra) # 800023da <myproc>
    80001994:	00c95d13          	srli	s10,s2,0xc
    80001998:	001d1c93          	slli	s9,s10,0x1
    8000199c:	01ac87b3          	add	a5,s9,s10
    800019a0:	078a                	slli	a5,a5,0x2
    800019a2:	953e                	add	a0,a0,a5
    800019a4:	16052c23          	sw	zero,376(a0)
            myproc()->paging_meta_data[a/PGSIZE].offset = -1;
    800019a8:	00001097          	auipc	ra,0x1
    800019ac:	a32080e7          	jalr	-1486(ra) # 800023da <myproc>
    800019b0:	9cea                	add	s9,s9,s10
    800019b2:	0c8a                	slli	s9,s9,0x2
    800019b4:	9caa                	add	s9,s9,a0
    800019b6:	178ca823          	sw	s8,368(s9)
            remove_from_queue_not_in_memory(a/PGSIZE);
    800019ba:	000d051b          	sext.w	a0,s10
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	eac080e7          	jalr	-340(ra) # 8000186a <remove_from_queue_not_in_memory>
    800019c6:	b761                	j	8000194e <uvmunmap+0x74>
      else if(do_free){
    800019c8:	f80b05e3          	beqz	s6,80001952 <uvmunmap+0x78>
            myproc()->paging_meta_data[ a/PGSIZE].offset = -1;
    800019cc:	00001097          	auipc	ra,0x1
    800019d0:	a0e080e7          	jalr	-1522(ra) # 800023da <myproc>
    800019d4:	00c95713          	srli	a4,s2,0xc
    800019d8:	00171793          	slli	a5,a4,0x1
    800019dc:	97ba                	add	a5,a5,a4
    800019de:	078a                	slli	a5,a5,0x2
    800019e0:	97aa                	add	a5,a5,a0
    800019e2:	1787a823          	sw	s8,368(a5)
    800019e6:	b7b5                	j	80001952 <uvmunmap+0x78>

00000000800019e8 <uvmdealloc>:
{
    800019e8:	1101                	addi	sp,sp,-32
    800019ea:	ec06                	sd	ra,24(sp)
    800019ec:	e822                	sd	s0,16(sp)
    800019ee:	e426                	sd	s1,8(sp)
    800019f0:	1000                	addi	s0,sp,32
    return oldsz;
    800019f2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800019f4:	00b67d63          	bgeu	a2,a1,80001a0e <uvmdealloc+0x26>
    800019f8:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800019fa:	6785                	lui	a5,0x1
    800019fc:	17fd                	addi	a5,a5,-1
    800019fe:	00f60733          	add	a4,a2,a5
    80001a02:	767d                	lui	a2,0xfffff
    80001a04:	8f71                	and	a4,a4,a2
    80001a06:	97ae                	add	a5,a5,a1
    80001a08:	8ff1                	and	a5,a5,a2
    80001a0a:	00f76863          	bltu	a4,a5,80001a1a <uvmdealloc+0x32>
}
    80001a0e:	8526                	mv	a0,s1
    80001a10:	60e2                	ld	ra,24(sp)
    80001a12:	6442                	ld	s0,16(sp)
    80001a14:	64a2                	ld	s1,8(sp)
    80001a16:	6105                	addi	sp,sp,32
    80001a18:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001a1a:	8f99                	sub	a5,a5,a4
    80001a1c:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001a1e:	4685                	li	a3,1
    80001a20:	0007861b          	sext.w	a2,a5
    80001a24:	85ba                	mv	a1,a4
    80001a26:	00000097          	auipc	ra,0x0
    80001a2a:	eb4080e7          	jalr	-332(ra) # 800018da <uvmunmap>
    80001a2e:	b7c5                	j	80001a0e <uvmdealloc+0x26>

0000000080001a30 <origin_uvmalloc>:
  if(newsz < oldsz)
    80001a30:	0ab66163          	bltu	a2,a1,80001ad2 <origin_uvmalloc+0xa2>
origin_uvmalloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz){
    80001a34:	7139                	addi	sp,sp,-64
    80001a36:	fc06                	sd	ra,56(sp)
    80001a38:	f822                	sd	s0,48(sp)
    80001a3a:	f426                	sd	s1,40(sp)
    80001a3c:	f04a                	sd	s2,32(sp)
    80001a3e:	ec4e                	sd	s3,24(sp)
    80001a40:	e852                	sd	s4,16(sp)
    80001a42:	e456                	sd	s5,8(sp)
    80001a44:	0080                	addi	s0,sp,64
    80001a46:	8aaa                	mv	s5,a0
    80001a48:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001a4a:	6985                	lui	s3,0x1
    80001a4c:	19fd                	addi	s3,s3,-1
    80001a4e:	95ce                	add	a1,a1,s3
    80001a50:	79fd                	lui	s3,0xfffff
    80001a52:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001a56:	08c9f063          	bgeu	s3,a2,80001ad6 <origin_uvmalloc+0xa6>
    80001a5a:	894e                	mv	s2,s3
      mem = kalloc();
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	086080e7          	jalr	134(ra) # 80000ae2 <kalloc>
    80001a64:	84aa                	mv	s1,a0
      if(mem == 0){
    80001a66:	c51d                	beqz	a0,80001a94 <origin_uvmalloc+0x64>
      memset(mem, 0, PGSIZE);
    80001a68:	6605                	lui	a2,0x1
    80001a6a:	4581                	li	a1,0
    80001a6c:	fffff097          	auipc	ra,0xfffff
    80001a70:	262080e7          	jalr	610(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001a74:	4779                	li	a4,30
    80001a76:	86a6                	mv	a3,s1
    80001a78:	6605                	lui	a2,0x1
    80001a7a:	85ca                	mv	a1,s2
    80001a7c:	8556                	mv	a0,s5
    80001a7e:	fffff097          	auipc	ra,0xfffff
    80001a82:	60a080e7          	jalr	1546(ra) # 80001088 <mappages>
    80001a86:	e905                	bnez	a0,80001ab6 <origin_uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001a88:	6785                	lui	a5,0x1
    80001a8a:	993e                	add	s2,s2,a5
    80001a8c:	fd4968e3          	bltu	s2,s4,80001a5c <origin_uvmalloc+0x2c>
  return newsz;
    80001a90:	8552                	mv	a0,s4
    80001a92:	a809                	j	80001aa4 <origin_uvmalloc+0x74>
        uvmdealloc(pagetable, a, oldsz);
    80001a94:	864e                	mv	a2,s3
    80001a96:	85ca                	mv	a1,s2
    80001a98:	8556                	mv	a0,s5
    80001a9a:	00000097          	auipc	ra,0x0
    80001a9e:	f4e080e7          	jalr	-178(ra) # 800019e8 <uvmdealloc>
        return 0;
    80001aa2:	4501                	li	a0,0
}
    80001aa4:	70e2                	ld	ra,56(sp)
    80001aa6:	7442                	ld	s0,48(sp)
    80001aa8:	74a2                	ld	s1,40(sp)
    80001aaa:	7902                	ld	s2,32(sp)
    80001aac:	69e2                	ld	s3,24(sp)
    80001aae:	6a42                	ld	s4,16(sp)
    80001ab0:	6aa2                	ld	s5,8(sp)
    80001ab2:	6121                	addi	sp,sp,64
    80001ab4:	8082                	ret
        kfree(mem);
    80001ab6:	8526                	mv	a0,s1
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	f1e080e7          	jalr	-226(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    80001ac0:	864e                	mv	a2,s3
    80001ac2:	85ca                	mv	a1,s2
    80001ac4:	8556                	mv	a0,s5
    80001ac6:	00000097          	auipc	ra,0x0
    80001aca:	f22080e7          	jalr	-222(ra) # 800019e8 <uvmdealloc>
        return 0;
    80001ace:	4501                	li	a0,0
    80001ad0:	bfd1                	j	80001aa4 <origin_uvmalloc+0x74>
    return oldsz;
    80001ad2:	852e                	mv	a0,a1
}
    80001ad4:	8082                	ret
  return newsz;
    80001ad6:	8532                	mv	a0,a2
    80001ad8:	b7f1                	j	80001aa4 <origin_uvmalloc+0x74>

0000000080001ada <uvmalloc>:
  if(newsz < oldsz)
    80001ada:	18b66563          	bltu	a2,a1,80001c64 <uvmalloc+0x18a>
{
    80001ade:	711d                	addi	sp,sp,-96
    80001ae0:	ec86                	sd	ra,88(sp)
    80001ae2:	e8a2                	sd	s0,80(sp)
    80001ae4:	e4a6                	sd	s1,72(sp)
    80001ae6:	e0ca                	sd	s2,64(sp)
    80001ae8:	fc4e                	sd	s3,56(sp)
    80001aea:	f852                	sd	s4,48(sp)
    80001aec:	f456                	sd	s5,40(sp)
    80001aee:	f05a                	sd	s6,32(sp)
    80001af0:	ec5e                	sd	s7,24(sp)
    80001af2:	e862                	sd	s8,16(sp)
    80001af4:	e466                	sd	s9,8(sp)
    80001af6:	e06a                	sd	s10,0(sp)
    80001af8:	1080                	addi	s0,sp,96
    80001afa:	89aa                	mv	s3,a0
    80001afc:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001afe:	6b85                	lui	s7,0x1
    80001b00:	1bfd                	addi	s7,s7,-1
    80001b02:	95de                	add	a1,a1,s7
    80001b04:	7bfd                	lui	s7,0xfffff
    80001b06:	0175fbb3          	and	s7,a1,s7
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b0a:	14cbff63          	bgeu	s7,a2,80001c68 <uvmalloc+0x18e>
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b0e:	000217b7          	lui	a5,0x21
    80001b12:	00fbf863          	bgeu	s7,a5,80001b22 <uvmalloc+0x48>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b16:	84de                	mv	s1,s7
     if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80001b18:	4abd                	li	s5,15
      myproc()->paging_meta_data[a/PGSIZE].in_memory = 1;
    80001b1a:	4c05                	li	s8,1
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b1c:	00021b37          	lui	s6,0x21
    80001b20:	a8a1                	j	80001b78 <uvmalloc+0x9e>
      panic("more than 32 pages");
    80001b22:	00007517          	auipc	a0,0x7
    80001b26:	6ae50513          	addi	a0,a0,1710 # 800091d0 <digits+0x190>
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	a00080e7          	jalr	-1536(ra) # 8000052a <panic>
      pte = walk(pagetable, a, 0);
    80001b32:	4601                	li	a2,0
    80001b34:	85a6                	mv	a1,s1
    80001b36:	854e                	mv	a0,s3
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	47e080e7          	jalr	1150(ra) # 80000fb6 <walk>
      *pte = *pte & (~PTE_V);
    80001b40:	611c                	ld	a5,0(a0)
    80001b42:	9bf9                	andi	a5,a5,-2
    80001b44:	e11c                	sd	a5,0(a0)
      int offset = find_min_empty_offset();
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	85a080e7          	jalr	-1958(ra) # 800013a0 <find_min_empty_offset>
    80001b4e:	0005091b          	sext.w	s2,a0
      myproc()->paging_meta_data[a/PGSIZE].offset = offset;
    80001b52:	00001097          	auipc	ra,0x1
    80001b56:	888080e7          	jalr	-1912(ra) # 800023da <myproc>
    80001b5a:	00c4d713          	srli	a4,s1,0xc
    80001b5e:	00171793          	slli	a5,a4,0x1
    80001b62:	97ba                	add	a5,a5,a4
    80001b64:	078a                	slli	a5,a5,0x2
    80001b66:	97aa                	add	a5,a5,a0
    80001b68:	1727a823          	sw	s2,368(a5) # 21170 <_entry-0x7ffdee90>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001b6c:	6785                	lui	a5,0x1
    80001b6e:	94be                	add	s1,s1,a5
    80001b70:	0d44fb63          	bgeu	s1,s4,80001c46 <uvmalloc+0x16c>
     if(a/PGSIZE > MAX_TOTAL_PAGES){
    80001b74:	fb64f7e3          	bgeu	s1,s6,80001b22 <uvmalloc+0x48>
     if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80001b78:	00000097          	auipc	ra,0x0
    80001b7c:	ae0080e7          	jalr	-1312(ra) # 80001658 <get_num_of_pages_in_memory>
    80001b80:	02aad763          	bge	s5,a0,80001bae <uvmalloc+0xd4>
       if(mappages(pagetable, a, PGSIZE, 0, PTE_W|PTE_R|PTE_X|PTE_U|PTE_PG) < 0) {
    80001b84:	41e00713          	li	a4,1054
    80001b88:	4681                	li	a3,0
    80001b8a:	6605                	lui	a2,0x1
    80001b8c:	85a6                	mv	a1,s1
    80001b8e:	854e                	mv	a0,s3
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	4f8080e7          	jalr	1272(ra) # 80001088 <mappages>
    80001b98:	f8055de3          	bgez	a0,80001b32 <uvmalloc+0x58>
         uvmdealloc(pagetable, newsz, oldsz);
    80001b9c:	865e                	mv	a2,s7
    80001b9e:	85d2                	mv	a1,s4
    80001ba0:	854e                	mv	a0,s3
    80001ba2:	00000097          	auipc	ra,0x0
    80001ba6:	e46080e7          	jalr	-442(ra) # 800019e8 <uvmdealloc>
         return 0;
    80001baa:	4501                	li	a0,0
    80001bac:	a871                	j	80001c48 <uvmalloc+0x16e>
      mem = kalloc();
    80001bae:	fffff097          	auipc	ra,0xfffff
    80001bb2:	f34080e7          	jalr	-204(ra) # 80000ae2 <kalloc>
    80001bb6:	892a                	mv	s2,a0
      if(mem == 0){
    80001bb8:	c125                	beqz	a0,80001c18 <uvmalloc+0x13e>
      memset(mem, 0, PGSIZE);
    80001bba:	6605                	lui	a2,0x1
    80001bbc:	4581                	li	a1,0
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	110080e7          	jalr	272(ra) # 80000cce <memset>
      if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001bc6:	4779                	li	a4,30
    80001bc8:	86ca                	mv	a3,s2
    80001bca:	6605                	lui	a2,0x1
    80001bcc:	85a6                	mv	a1,s1
    80001bce:	854e                	mv	a0,s3
    80001bd0:	fffff097          	auipc	ra,0xfffff
    80001bd4:	4b8080e7          	jalr	1208(ra) # 80001088 <mappages>
    80001bd8:	e929                	bnez	a0,80001c2a <uvmalloc+0x150>
      myproc()->paging_meta_data[a/PGSIZE].in_memory = 1;
    80001bda:	00001097          	auipc	ra,0x1
    80001bde:	800080e7          	jalr	-2048(ra) # 800023da <myproc>
    80001be2:	00c4dd13          	srli	s10,s1,0xc
    80001be6:	001d1913          	slli	s2,s10,0x1
    80001bea:	01a907b3          	add	a5,s2,s10
    80001bee:	078a                	slli	a5,a5,0x2
    80001bf0:	953e                	add	a0,a0,a5
    80001bf2:	17852c23          	sw	s8,376(a0)
      myproc()->paging_meta_data[a/PGSIZE].aging = init_aging(a/PGSIZE);
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	7e4080e7          	jalr	2020(ra) # 800023da <myproc>
    80001bfe:	8caa                	mv	s9,a0
  #endif
  #if SELECTION == LAPA
    return LAPA_AGE;
  #endif
  #if SELECTION==SCFIFO
    return insert_to_queue(fifo_init_pages);
    80001c00:	000d051b          	sext.w	a0,s10
    80001c04:	00000097          	auipc	ra,0x0
    80001c08:	bdc080e7          	jalr	-1060(ra) # 800017e0 <insert_to_queue>
      myproc()->paging_meta_data[a/PGSIZE].aging = init_aging(a/PGSIZE);
    80001c0c:	996a                	add	s2,s2,s10
    80001c0e:	090a                	slli	s2,s2,0x2
    80001c10:	9966                	add	s2,s2,s9
    return insert_to_queue(fifo_init_pages);
    80001c12:	16a92a23          	sw	a0,372(s2)
    80001c16:	bf99                	j	80001b6c <uvmalloc+0x92>
        uvmdealloc(pagetable, a, oldsz);
    80001c18:	865e                	mv	a2,s7
    80001c1a:	85a6                	mv	a1,s1
    80001c1c:	854e                	mv	a0,s3
    80001c1e:	00000097          	auipc	ra,0x0
    80001c22:	dca080e7          	jalr	-566(ra) # 800019e8 <uvmdealloc>
        return 0;
    80001c26:	4501                	li	a0,0
    80001c28:	a005                	j	80001c48 <uvmalloc+0x16e>
        kfree(mem);
    80001c2a:	854a                	mv	a0,s2
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	daa080e7          	jalr	-598(ra) # 800009d6 <kfree>
        uvmdealloc(pagetable, a, oldsz);
    80001c34:	865e                	mv	a2,s7
    80001c36:	85a6                	mv	a1,s1
    80001c38:	854e                	mv	a0,s3
    80001c3a:	00000097          	auipc	ra,0x0
    80001c3e:	dae080e7          	jalr	-594(ra) # 800019e8 <uvmdealloc>
        return 0;
    80001c42:	4501                	li	a0,0
    80001c44:	a011                	j	80001c48 <uvmalloc+0x16e>
  return newsz;
    80001c46:	8552                	mv	a0,s4
}
    80001c48:	60e6                	ld	ra,88(sp)
    80001c4a:	6446                	ld	s0,80(sp)
    80001c4c:	64a6                	ld	s1,72(sp)
    80001c4e:	6906                	ld	s2,64(sp)
    80001c50:	79e2                	ld	s3,56(sp)
    80001c52:	7a42                	ld	s4,48(sp)
    80001c54:	7aa2                	ld	s5,40(sp)
    80001c56:	7b02                	ld	s6,32(sp)
    80001c58:	6be2                	ld	s7,24(sp)
    80001c5a:	6c42                	ld	s8,16(sp)
    80001c5c:	6ca2                	ld	s9,8(sp)
    80001c5e:	6d02                	ld	s10,0(sp)
    80001c60:	6125                	addi	sp,sp,96
    80001c62:	8082                	ret
    return oldsz;
    80001c64:	852e                	mv	a0,a1
}
    80001c66:	8082                	ret
  return newsz;
    80001c68:	8532                	mv	a0,a2
    80001c6a:	bff9                	j	80001c48 <uvmalloc+0x16e>

0000000080001c6c <lazy_memory_allocation>:
void lazy_memory_allocation(uint64 faulting_address){
    80001c6c:	1101                	addi	sp,sp,-32
    80001c6e:	ec06                	sd	ra,24(sp)
    80001c70:	e822                	sd	s0,16(sp)
    80001c72:	e426                	sd	s1,8(sp)
    80001c74:	1000                	addi	s0,sp,32
    80001c76:	84aa                	mv	s1,a0
  uvmalloc(myproc()->pagetable,PGROUNDDOWN(faulting_address), PGROUNDDOWN(faulting_address) + PGSIZE);     
    80001c78:	00000097          	auipc	ra,0x0
    80001c7c:	762080e7          	jalr	1890(ra) # 800023da <myproc>
    80001c80:	75fd                	lui	a1,0xfffff
    80001c82:	8de5                	and	a1,a1,s1
    80001c84:	6605                	lui	a2,0x1
    80001c86:	962e                	add	a2,a2,a1
    80001c88:	6928                	ld	a0,80(a0)
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e50080e7          	jalr	-432(ra) # 80001ada <uvmalloc>
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <uvmfree>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	1000                	addi	s0,sp,32
    80001ca6:	84aa                	mv	s1,a0
  if(sz > 0)
    80001ca8:	e999                	bnez	a1,80001cbe <uvmfree+0x22>
  freewalk(pagetable);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	742080e7          	jalr	1858(ra) # 800013ee <freewalk>
}
    80001cb4:	60e2                	ld	ra,24(sp)
    80001cb6:	6442                	ld	s0,16(sp)
    80001cb8:	64a2                	ld	s1,8(sp)
    80001cba:	6105                	addi	sp,sp,32
    80001cbc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001cbe:	6605                	lui	a2,0x1
    80001cc0:	167d                	addi	a2,a2,-1
    80001cc2:	962e                	add	a2,a2,a1
    80001cc4:	4685                	li	a3,1
    80001cc6:	8231                	srli	a2,a2,0xc
    80001cc8:	4581                	li	a1,0
    80001cca:	00000097          	auipc	ra,0x0
    80001cce:	c10080e7          	jalr	-1008(ra) # 800018da <uvmunmap>
    80001cd2:	bfe1                	j	80001caa <uvmfree+0xe>

0000000080001cd4 <origin_uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){
    80001cd4:	c679                	beqz	a2,80001da2 <origin_uvmcopy+0xce>
int origin_uvmcopy(pagetable_t old, pagetable_t new, uint64 sz){
    80001cd6:	715d                	addi	sp,sp,-80
    80001cd8:	e486                	sd	ra,72(sp)
    80001cda:	e0a2                	sd	s0,64(sp)
    80001cdc:	fc26                	sd	s1,56(sp)
    80001cde:	f84a                	sd	s2,48(sp)
    80001ce0:	f44e                	sd	s3,40(sp)
    80001ce2:	f052                	sd	s4,32(sp)
    80001ce4:	ec56                	sd	s5,24(sp)
    80001ce6:	e85a                	sd	s6,16(sp)
    80001ce8:	e45e                	sd	s7,8(sp)
    80001cea:	0880                	addi	s0,sp,80
    80001cec:	8b2a                	mv	s6,a0
    80001cee:	8aae                	mv	s5,a1
    80001cf0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001cf2:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001cf4:	4601                	li	a2,0
    80001cf6:	85ce                	mv	a1,s3
    80001cf8:	855a                	mv	a0,s6
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	2bc080e7          	jalr	700(ra) # 80000fb6 <walk>
    80001d02:	c531                	beqz	a0,80001d4e <origin_uvmcopy+0x7a>
    if((*pte & PTE_V) == 0)
    80001d04:	6118                	ld	a4,0(a0)
    80001d06:	00177793          	andi	a5,a4,1
    80001d0a:	cbb1                	beqz	a5,80001d5e <origin_uvmcopy+0x8a>
    pa = PTE2PA(*pte);
    80001d0c:	00a75593          	srli	a1,a4,0xa
    80001d10:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001d14:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001d18:	fffff097          	auipc	ra,0xfffff
    80001d1c:	dca080e7          	jalr	-566(ra) # 80000ae2 <kalloc>
    80001d20:	892a                	mv	s2,a0
    80001d22:	c939                	beqz	a0,80001d78 <origin_uvmcopy+0xa4>
    memmove(mem, (char*)pa, PGSIZE);
    80001d24:	6605                	lui	a2,0x1
    80001d26:	85de                	mv	a1,s7
    80001d28:	fffff097          	auipc	ra,0xfffff
    80001d2c:	002080e7          	jalr	2(ra) # 80000d2a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001d30:	8726                	mv	a4,s1
    80001d32:	86ca                	mv	a3,s2
    80001d34:	6605                	lui	a2,0x1
    80001d36:	85ce                	mv	a1,s3
    80001d38:	8556                	mv	a0,s5
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	34e080e7          	jalr	846(ra) # 80001088 <mappages>
    80001d42:	e515                	bnez	a0,80001d6e <origin_uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001d44:	6785                	lui	a5,0x1
    80001d46:	99be                	add	s3,s3,a5
    80001d48:	fb49e6e3          	bltu	s3,s4,80001cf4 <origin_uvmcopy+0x20>
    80001d4c:	a081                	j	80001d8c <origin_uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001d4e:	00007517          	auipc	a0,0x7
    80001d52:	49a50513          	addi	a0,a0,1178 # 800091e8 <digits+0x1a8>
    80001d56:	ffffe097          	auipc	ra,0xffffe
    80001d5a:	7d4080e7          	jalr	2004(ra) # 8000052a <panic>
      panic("uvmcopy: page not present");
    80001d5e:	00007517          	auipc	a0,0x7
    80001d62:	4aa50513          	addi	a0,a0,1194 # 80009208 <digits+0x1c8>
    80001d66:	ffffe097          	auipc	ra,0xffffe
    80001d6a:	7c4080e7          	jalr	1988(ra) # 8000052a <panic>
      kfree(mem);
    80001d6e:	854a                	mv	a0,s2
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	c66080e7          	jalr	-922(ra) # 800009d6 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001d78:	4685                	li	a3,1
    80001d7a:	00c9d613          	srli	a2,s3,0xc
    80001d7e:	4581                	li	a1,0
    80001d80:	8556                	mv	a0,s5
    80001d82:	00000097          	auipc	ra,0x0
    80001d86:	b58080e7          	jalr	-1192(ra) # 800018da <uvmunmap>
  return -1;
    80001d8a:	557d                	li	a0,-1
}
    80001d8c:	60a6                	ld	ra,72(sp)
    80001d8e:	6406                	ld	s0,64(sp)
    80001d90:	74e2                	ld	s1,56(sp)
    80001d92:	7942                	ld	s2,48(sp)
    80001d94:	79a2                	ld	s3,40(sp)
    80001d96:	7a02                	ld	s4,32(sp)
    80001d98:	6ae2                	ld	s5,24(sp)
    80001d9a:	6b42                	ld	s6,16(sp)
    80001d9c:	6ba2                	ld	s7,8(sp)
    80001d9e:	6161                	addi	sp,sp,80
    80001da0:	8082                	ret
  return 0;
    80001da2:	4501                	li	a0,0
}
    80001da4:	8082                	ret

0000000080001da6 <uvmcopy>:
  for(i = 0; i < sz; i += PGSIZE){    
    80001da6:	ca4d                	beqz	a2,80001e58 <uvmcopy+0xb2>
{
    80001da8:	715d                	addi	sp,sp,-80
    80001daa:	e486                	sd	ra,72(sp)
    80001dac:	e0a2                	sd	s0,64(sp)
    80001dae:	fc26                	sd	s1,56(sp)
    80001db0:	f84a                	sd	s2,48(sp)
    80001db2:	f44e                	sd	s3,40(sp)
    80001db4:	f052                	sd	s4,32(sp)
    80001db6:	ec56                	sd	s5,24(sp)
    80001db8:	e85a                	sd	s6,16(sp)
    80001dba:	e45e                	sd	s7,8(sp)
    80001dbc:	0880                	addi	s0,sp,80
    80001dbe:	8aaa                	mv	s5,a0
    80001dc0:	8b2e                	mv	s6,a1
    80001dc2:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){    
    80001dc4:	4481                	li	s1,0
    80001dc6:	a029                	j	80001dd0 <uvmcopy+0x2a>
    80001dc8:	6785                	lui	a5,0x1
    80001dca:	94be                	add	s1,s1,a5
    80001dcc:	0744fa63          	bgeu	s1,s4,80001e40 <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) !=0 && (*pte & PTE_V) != 0){
    80001dd0:	4601                	li	a2,0
    80001dd2:	85a6                	mv	a1,s1
    80001dd4:	8556                	mv	a0,s5
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	1e0080e7          	jalr	480(ra) # 80000fb6 <walk>
    80001dde:	d56d                	beqz	a0,80001dc8 <uvmcopy+0x22>
    80001de0:	6118                	ld	a4,0(a0)
    80001de2:	00177793          	andi	a5,a4,1
    80001de6:	d3ed                	beqz	a5,80001dc8 <uvmcopy+0x22>
      pa = PTE2PA(*pte);
    80001de8:	00a75593          	srli	a1,a4,0xa
    80001dec:	00c59b93          	slli	s7,a1,0xc
      flags = PTE_FLAGS(*pte);
    80001df0:	3ff77913          	andi	s2,a4,1023
      if((mem = kalloc()) == 0)
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	cee080e7          	jalr	-786(ra) # 80000ae2 <kalloc>
    80001dfc:	89aa                	mv	s3,a0
    80001dfe:	c515                	beqz	a0,80001e2a <uvmcopy+0x84>
      memmove(mem, (char*)pa, PGSIZE);
    80001e00:	6605                	lui	a2,0x1
    80001e02:	85de                	mv	a1,s7
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	f26080e7          	jalr	-218(ra) # 80000d2a <memmove>
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001e0c:	874a                	mv	a4,s2
    80001e0e:	86ce                	mv	a3,s3
    80001e10:	6605                	lui	a2,0x1
    80001e12:	85a6                	mv	a1,s1
    80001e14:	855a                	mv	a0,s6
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	272080e7          	jalr	626(ra) # 80001088 <mappages>
    80001e1e:	d54d                	beqz	a0,80001dc8 <uvmcopy+0x22>
        kfree(mem);
    80001e20:	854e                	mv	a0,s3
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	bb4080e7          	jalr	-1100(ra) # 800009d6 <kfree>
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001e2a:	4685                	li	a3,1
    80001e2c:	00c4d613          	srli	a2,s1,0xc
    80001e30:	4581                	li	a1,0
    80001e32:	855a                	mv	a0,s6
    80001e34:	00000097          	auipc	ra,0x0
    80001e38:	aa6080e7          	jalr	-1370(ra) # 800018da <uvmunmap>
  return -1;
    80001e3c:	557d                	li	a0,-1
    80001e3e:	a011                	j	80001e42 <uvmcopy+0x9c>
  return 0;
    80001e40:	4501                	li	a0,0
}
    80001e42:	60a6                	ld	ra,72(sp)
    80001e44:	6406                	ld	s0,64(sp)
    80001e46:	74e2                	ld	s1,56(sp)
    80001e48:	7942                	ld	s2,48(sp)
    80001e4a:	79a2                	ld	s3,40(sp)
    80001e4c:	7a02                	ld	s4,32(sp)
    80001e4e:	6ae2                	ld	s5,24(sp)
    80001e50:	6b42                	ld	s6,16(sp)
    80001e52:	6ba2                	ld	s7,8(sp)
    80001e54:	6161                	addi	sp,sp,80
    80001e56:	8082                	ret
  return 0;
    80001e58:	4501                	li	a0,0
}
    80001e5a:	8082                	ret

0000000080001e5c <second_fifo>:
int second_fifo(){
    80001e5c:	7139                	addi	sp,sp,-64
    80001e5e:	fc06                	sd	ra,56(sp)
    80001e60:	f822                	sd	s0,48(sp)
    80001e62:	f426                	sd	s1,40(sp)
    80001e64:	f04a                	sd	s2,32(sp)
    80001e66:	ec4e                	sd	s3,24(sp)
    80001e68:	e852                	sd	s4,16(sp)
    80001e6a:	e456                	sd	s5,8(sp)
    80001e6c:	e05a                	sd	s6,0(sp)
    80001e6e:	0080                	addi	s0,sp,64
  struct proc * p = myproc();
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	56a080e7          	jalr	1386(ra) # 800023da <myproc>
    80001e78:	84aa                	mv	s1,a0
  struct age_queue * q = &(p->queue);
    80001e7a:	2f050993          	addi	s3,a0,752
  int page_counter = q->page_counter;
    80001e7e:	37852a03          	lw	s4,888(a0)
  for (int i = 0; i<page_counter; i++){
    80001e82:	05405f63          	blez	s4,80001ee0 <second_fifo+0x84>
    80001e86:	4901                	li	s2,0
      printf("removing accsesed bit from %d", current_page);
    80001e88:	00007a97          	auipc	s5,0x7
    80001e8c:	3b8a8a93          	addi	s5,s5,952 # 80009240 <digits+0x200>
    current_page = q->pages[q->front];
    80001e90:	3704a783          	lw	a5,880(s1)
    80001e94:	078a                	slli	a5,a5,0x2
    80001e96:	97a6                	add	a5,a5,s1
    80001e98:	2f07ab03          	lw	s6,752(a5) # 12f0 <_entry-0x7fffed10>
    pte_t * pte = walk(p->pagetable, current_page*PGSIZE,0);
    80001e9c:	4601                	li	a2,0
    80001e9e:	00cb159b          	slliw	a1,s6,0xc
    80001ea2:	68a8                	ld	a0,80(s1)
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	112080e7          	jalr	274(ra) # 80000fb6 <walk>
    uint pte_flags = PTE_FLAGS(*pte);
    80001eac:	611c                	ld	a5,0(a0)
    if(!(pte_flags & PTE_A)){
    80001eae:	0407f713          	andi	a4,a5,64
    80001eb2:	cf29                	beqz	a4,80001f0c <second_fifo+0xb0>
      *pte = *pte & (~PTE_A); //make A bit off
    80001eb4:	fbf7f793          	andi	a5,a5,-65
    80001eb8:	e11c                	sd	a5,0(a0)
      printf("removing accsesed bit from %d", current_page);
    80001eba:	85da                	mv	a1,s6
    80001ebc:	8556                	mv	a0,s5
    80001ebe:	ffffe097          	auipc	ra,0xffffe
    80001ec2:	6b6080e7          	jalr	1718(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	970080e7          	jalr	-1680(ra) # 80001838 <remove_from_queue>
      insert_to_queue(current_page);
    80001ed0:	855a                	mv	a0,s6
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	90e080e7          	jalr	-1778(ra) # 800017e0 <insert_to_queue>
  for (int i = 0; i<page_counter; i++){
    80001eda:	2905                	addiw	s2,s2,1
    80001edc:	fb2a1ae3          	bne	s4,s2,80001e90 <second_fifo+0x34>
  current_page = q->pages[q->front];
    80001ee0:	3704a783          	lw	a5,880(s1)
    80001ee4:	078a                	slli	a5,a5,0x2
    80001ee6:	94be                	add	s1,s1,a5
    80001ee8:	2f04ab03          	lw	s6,752(s1)
  remove_from_queue(q);
    80001eec:	854e                	mv	a0,s3
    80001eee:	00000097          	auipc	ra,0x0
    80001ef2:	94a080e7          	jalr	-1718(ra) # 80001838 <remove_from_queue>
}
    80001ef6:	855a                	mv	a0,s6
    80001ef8:	70e2                	ld	ra,56(sp)
    80001efa:	7442                	ld	s0,48(sp)
    80001efc:	74a2                	ld	s1,40(sp)
    80001efe:	7902                	ld	s2,32(sp)
    80001f00:	69e2                	ld	s3,24(sp)
    80001f02:	6a42                	ld	s4,16(sp)
    80001f04:	6aa2                	ld	s5,8(sp)
    80001f06:	6b02                	ld	s6,0(sp)
    80001f08:	6121                	addi	sp,sp,64
    80001f0a:	8082                	ret
      printf("not accsesed %d \n", current_page);
    80001f0c:	85da                	mv	a1,s6
    80001f0e:	00007517          	auipc	a0,0x7
    80001f12:	31a50513          	addi	a0,a0,794 # 80009228 <digits+0x1e8>
    80001f16:	ffffe097          	auipc	ra,0xffffe
    80001f1a:	65e080e7          	jalr	1630(ra) # 80000574 <printf>
      remove_from_queue(q);
    80001f1e:	854e                	mv	a0,s3
    80001f20:	00000097          	auipc	ra,0x0
    80001f24:	918080e7          	jalr	-1768(ra) # 80001838 <remove_from_queue>
      return current_page; //the file will no longer be in the memory and will be removed next time
    80001f28:	b7f9                	j	80001ef6 <second_fifo+0x9a>

0000000080001f2a <swap_page_into_file>:
void swap_page_into_file(int offset){
    80001f2a:	7139                	addi	sp,sp,-64
    80001f2c:	fc06                	sd	ra,56(sp)
    80001f2e:	f822                	sd	s0,48(sp)
    80001f30:	f426                	sd	s1,40(sp)
    80001f32:	f04a                	sd	s2,32(sp)
    80001f34:	ec4e                	sd	s3,24(sp)
    80001f36:	e852                	sd	s4,16(sp)
    80001f38:	e456                	sd	s5,8(sp)
    80001f3a:	0080                	addi	s0,sp,64
    80001f3c:	8aaa                	mv	s5,a0
    struct proc * p = myproc();
    80001f3e:	00000097          	auipc	ra,0x0
    80001f42:	49c080e7          	jalr	1180(ra) # 800023da <myproc>
    80001f46:	84aa                	mv	s1,a0
    return second_fifo(); 
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	f14080e7          	jalr	-236(ra) # 80001e5c <second_fifo>
    80001f50:	892a                	mv	s2,a0
    printf("chosen page %d \n", remove_file_indx);
    80001f52:	85aa                	mv	a1,a0
    80001f54:	00007517          	auipc	a0,0x7
    80001f58:	30c50513          	addi	a0,a0,780 # 80009260 <digits+0x220>
    80001f5c:	ffffe097          	auipc	ra,0xffffe
    80001f60:	618080e7          	jalr	1560(ra) # 80000574 <printf>
    pte_t *out_page_entry =  walk(p->pagetable, removed_page_VA, 0); 
    80001f64:	4601                	li	a2,0
    80001f66:	00c9159b          	slliw	a1,s2,0xc
    80001f6a:	68a8                	ld	a0,80(s1)
    80001f6c:	fffff097          	auipc	ra,0xfffff
    80001f70:	04a080e7          	jalr	74(ra) # 80000fb6 <walk>
    80001f74:	8a2a                	mv	s4,a0
    uint64 physical_addr = PTE2PA(*out_page_entry);
    80001f76:	00053983          	ld	s3,0(a0)
    80001f7a:	00a9d993          	srli	s3,s3,0xa
    80001f7e:	09b2                	slli	s3,s3,0xc
    if(writeToSwapFile(p,(char*)physical_addr,offset,PGSIZE) ==  -1)
    80001f80:	6685                	lui	a3,0x1
    80001f82:	8656                	mv	a2,s5
    80001f84:	85ce                	mv	a1,s3
    80001f86:	8526                	mv	a0,s1
    80001f88:	00003097          	auipc	ra,0x3
    80001f8c:	d6a080e7          	jalr	-662(ra) # 80004cf2 <writeToSwapFile>
    80001f90:	57fd                	li	a5,-1
    80001f92:	04f50263          	beq	a0,a5,80001fd6 <swap_page_into_file+0xac>
    kfree((void*)physical_addr);
    80001f96:	854e                	mv	a0,s3
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	a3e080e7          	jalr	-1474(ra) # 800009d6 <kfree>
    *out_page_entry = (*out_page_entry & (~PTE_V)) | PTE_PG;
    80001fa0:	000a3783          	ld	a5,0(s4)
    80001fa4:	bfe7f793          	andi	a5,a5,-1026
    80001fa8:	4007e793          	ori	a5,a5,1024
    80001fac:	00fa3023          	sd	a5,0(s4)
    p->paging_meta_data[remove_file_indx].offset = offset;
    80001fb0:	00191793          	slli	a5,s2,0x1
    80001fb4:	01278733          	add	a4,a5,s2
    80001fb8:	070a                	slli	a4,a4,0x2
    80001fba:	9726                	add	a4,a4,s1
    80001fbc:	17572823          	sw	s5,368(a4)
    p->paging_meta_data[remove_file_indx].in_memory = 0;
    80001fc0:	16072c23          	sw	zero,376(a4)
}
    80001fc4:	70e2                	ld	ra,56(sp)
    80001fc6:	7442                	ld	s0,48(sp)
    80001fc8:	74a2                	ld	s1,40(sp)
    80001fca:	7902                	ld	s2,32(sp)
    80001fcc:	69e2                	ld	s3,24(sp)
    80001fce:	6a42                	ld	s4,16(sp)
    80001fd0:	6aa2                	ld	s5,8(sp)
    80001fd2:	6121                	addi	sp,sp,64
    80001fd4:	8082                	ret
      panic("write to file failed");
    80001fd6:	00007517          	auipc	a0,0x7
    80001fda:	2a250513          	addi	a0,a0,674 # 80009278 <digits+0x238>
    80001fde:	ffffe097          	auipc	ra,0xffffe
    80001fe2:	54c080e7          	jalr	1356(ra) # 8000052a <panic>

0000000080001fe6 <page_in>:
void page_in(uint64 faulting_address, pte_t * missing_pte_entry){
    80001fe6:	7139                	addi	sp,sp,-64
    80001fe8:	fc06                	sd	ra,56(sp)
    80001fea:	f822                	sd	s0,48(sp)
    80001fec:	f426                	sd	s1,40(sp)
    80001fee:	f04a                	sd	s2,32(sp)
    80001ff0:	ec4e                	sd	s3,24(sp)
    80001ff2:	e852                	sd	s4,16(sp)
    80001ff4:	e456                	sd	s5,8(sp)
    80001ff6:	0080                	addi	s0,sp,64
    80001ff8:	89ae                	mv	s3,a1
  int current_page_index = PGROUNDDOWN(faulting_address)/PGSIZE;
    80001ffa:	8131                	srli	a0,a0,0xc
    80001ffc:	0005091b          	sext.w	s2,a0
  uint offset = myproc()->paging_meta_data[current_page_index].offset;
    80002000:	00000097          	auipc	ra,0x0
    80002004:	3da080e7          	jalr	986(ra) # 800023da <myproc>
    80002008:	00191793          	slli	a5,s2,0x1
    8000200c:	97ca                	add	a5,a5,s2
    8000200e:	078a                	slli	a5,a5,0x2
    80002010:	97aa                	add	a5,a5,a0
    80002012:	1707aa83          	lw	s5,368(a5)
    80002016:	000a8a1b          	sext.w	s4,s5
  if(offset == -1){
    8000201a:	57fd                	li	a5,-1
    8000201c:	0afa0563          	beq	s4,a5,800020c6 <page_in+0xe0>
  if((read_buffer = kalloc()) == 0)
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	ac2080e7          	jalr	-1342(ra) # 80000ae2 <kalloc>
    80002028:	84aa                	mv	s1,a0
    8000202a:	c555                	beqz	a0,800020d6 <page_in+0xf0>
  if (readFromSwapFile(myproc(),read_buffer ,offset,PGSIZE) == -1)
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	3ae080e7          	jalr	942(ra) # 800023da <myproc>
    80002034:	6685                	lui	a3,0x1
    80002036:	8652                	mv	a2,s4
    80002038:	85a6                	mv	a1,s1
    8000203a:	00003097          	auipc	ra,0x3
    8000203e:	cdc080e7          	jalr	-804(ra) # 80004d16 <readFromSwapFile>
    80002042:	57fd                	li	a5,-1
    80002044:	0af50163          	beq	a0,a5,800020e6 <page_in+0x100>
  if(get_num_of_pages_in_memory() >= MAX_PSYC_PAGES){
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	610080e7          	jalr	1552(ra) # 80001658 <get_num_of_pages_in_memory>
    80002050:	47bd                	li	a5,15
    80002052:	0aa7c263          	blt	a5,a0,800020f6 <page_in+0x110>
      *missing_pte_entry = PA2PTE((uint64)read_buffer) | PTE_V; 
    80002056:	80b1                	srli	s1,s1,0xc
    80002058:	04aa                	slli	s1,s1,0xa
    8000205a:	0014e493          	ori	s1,s1,1
    8000205e:	0099b023          	sd	s1,0(s3) # fffffffffffff000 <end+0xffffffff7ffd0000>
  myproc()->paging_meta_data[current_page_index].aging = init_aging(current_page_index);
    80002062:	00000097          	auipc	ra,0x0
    80002066:	378080e7          	jalr	888(ra) # 800023da <myproc>
    8000206a:	89aa                	mv	s3,a0
    return insert_to_queue(fifo_init_pages);
    8000206c:	854a                	mv	a0,s2
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	772080e7          	jalr	1906(ra) # 800017e0 <insert_to_queue>
  myproc()->paging_meta_data[current_page_index].aging = init_aging(current_page_index);
    80002076:	00191493          	slli	s1,s2,0x1
    8000207a:	012487b3          	add	a5,s1,s2
    8000207e:	078a                	slli	a5,a5,0x2
    80002080:	99be                	add	s3,s3,a5
    return insert_to_queue(fifo_init_pages);
    80002082:	16a9aa23          	sw	a0,372(s3)
  myproc()->paging_meta_data[current_page_index].offset = -1;
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	354080e7          	jalr	852(ra) # 800023da <myproc>
    8000208e:	012487b3          	add	a5,s1,s2
    80002092:	078a                	slli	a5,a5,0x2
    80002094:	953e                	add	a0,a0,a5
    80002096:	57fd                	li	a5,-1
    80002098:	16f52823          	sw	a5,368(a0)
  myproc()->paging_meta_data[current_page_index].in_memory = 1;
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	33e080e7          	jalr	830(ra) # 800023da <myproc>
    800020a4:	94ca                	add	s1,s1,s2
    800020a6:	048a                	slli	s1,s1,0x2
    800020a8:	94aa                	add	s1,s1,a0
    800020aa:	4785                	li	a5,1
    800020ac:	16f4ac23          	sw	a5,376(s1)
    800020b0:	12000073          	sfence.vma
}
    800020b4:	70e2                	ld	ra,56(sp)
    800020b6:	7442                	ld	s0,48(sp)
    800020b8:	74a2                	ld	s1,40(sp)
    800020ba:	7902                	ld	s2,32(sp)
    800020bc:	69e2                	ld	s3,24(sp)
    800020be:	6a42                	ld	s4,16(sp)
    800020c0:	6aa2                	ld	s5,8(sp)
    800020c2:	6121                	addi	sp,sp,64
    800020c4:	8082                	ret
    panic("offset is -1");
    800020c6:	00007517          	auipc	a0,0x7
    800020ca:	1ca50513          	addi	a0,a0,458 # 80009290 <digits+0x250>
    800020ce:	ffffe097          	auipc	ra,0xffffe
    800020d2:	45c080e7          	jalr	1116(ra) # 8000052a <panic>
    panic("not enough space to kalloc");
    800020d6:	00007517          	auipc	a0,0x7
    800020da:	1ca50513          	addi	a0,a0,458 # 800092a0 <digits+0x260>
    800020de:	ffffe097          	auipc	ra,0xffffe
    800020e2:	44c080e7          	jalr	1100(ra) # 8000052a <panic>
    panic("read from file failed");
    800020e6:	00007517          	auipc	a0,0x7
    800020ea:	1da50513          	addi	a0,a0,474 # 800092c0 <digits+0x280>
    800020ee:	ffffe097          	auipc	ra,0xffffe
    800020f2:	43c080e7          	jalr	1084(ra) # 8000052a <panic>
    swap_page_into_file(offset); //maybe adding it in the end of the swap
    800020f6:	8556                	mv	a0,s5
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	e32080e7          	jalr	-462(ra) # 80001f2a <swap_page_into_file>
    *missing_pte_entry = PA2PTE((uint64)read_buffer) | ((PTE_FLAGS(*missing_pte_entry)& ~PTE_PG) | PTE_V);
    80002100:	80b1                	srli	s1,s1,0xc
    80002102:	04aa                	slli	s1,s1,0xa
    80002104:	0009b783          	ld	a5,0(s3)
    80002108:	3fe7f793          	andi	a5,a5,1022
    8000210c:	8cdd                	or	s1,s1,a5
    8000210e:	0014e493          	ori	s1,s1,1
    80002112:	0099b023          	sd	s1,0(s3)
    80002116:	b7b1                	j	80002062 <page_in+0x7c>

0000000080002118 <check_page_fault>:
void check_page_fault(){
    80002118:	1101                	addi	sp,sp,-32
    8000211a:	ec06                	sd	ra,24(sp)
    8000211c:	e822                	sd	s0,16(sp)
    8000211e:	e426                	sd	s1,8(sp)
    80002120:	e04a                	sd	s2,0(sp)
    80002122:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002124:	14302973          	csrr	s2,stval
  pte_t * pte_entry = walk(myproc()->pagetable, PGROUNDDOWN(faulting_address), 0); //maybe doesn't have to pagedown 
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	2b2080e7          	jalr	690(ra) # 800023da <myproc>
    80002130:	4601                	li	a2,0
    80002132:	75fd                	lui	a1,0xfffff
    80002134:	00b975b3          	and	a1,s2,a1
    80002138:	6928                	ld	a0,80(a0)
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	e7c080e7          	jalr	-388(ra) # 80000fb6 <walk>
  if(pte_entry !=0 &&(!(*pte_entry & PTE_V)  && *pte_entry & PTE_PG)){
    80002142:	c909                	beqz	a0,80002154 <check_page_fault+0x3c>
    80002144:	84aa                	mv	s1,a0
    80002146:	611c                	ld	a5,0(a0)
    80002148:	4017f793          	andi	a5,a5,1025
    8000214c:	40000713          	li	a4,1024
    80002150:	02e78463          	beq	a5,a4,80002178 <check_page_fault+0x60>
  else if (faulting_address <= myproc()->sz){
    80002154:	00000097          	auipc	ra,0x0
    80002158:	286080e7          	jalr	646(ra) # 800023da <myproc>
    8000215c:	653c                	ld	a5,72(a0)
    8000215e:	0327ec63          	bltu	a5,s2,80002196 <check_page_fault+0x7e>
    lazy_memory_allocation(faulting_address);
    80002162:	854a                	mv	a0,s2
    80002164:	00000097          	auipc	ra,0x0
    80002168:	b08080e7          	jalr	-1272(ra) # 80001c6c <lazy_memory_allocation>
}
    8000216c:	60e2                	ld	ra,24(sp)
    8000216e:	6442                	ld	s0,16(sp)
    80002170:	64a2                	ld	s1,8(sp)
    80002172:	6902                	ld	s2,0(sp)
    80002174:	6105                	addi	sp,sp,32
    80002176:	8082                	ret
    printf("Page Fault - Page was out of memory\n");
    80002178:	00007517          	auipc	a0,0x7
    8000217c:	16050513          	addi	a0,a0,352 # 800092d8 <digits+0x298>
    80002180:	ffffe097          	auipc	ra,0xffffe
    80002184:	3f4080e7          	jalr	1012(ra) # 80000574 <printf>
    page_in(faulting_address, pte_entry);
    80002188:	85a6                	mv	a1,s1
    8000218a:	854a                	mv	a0,s2
    8000218c:	00000097          	auipc	ra,0x0
    80002190:	e5a080e7          	jalr	-422(ra) # 80001fe6 <page_in>
    80002194:	bfe1                	j	8000216c <check_page_fault+0x54>
    exit(-1);
    80002196:	557d                	li	a0,-1
    80002198:	00001097          	auipc	ra,0x1
    8000219c:	d46080e7          	jalr	-698(ra) # 80002ede <exit>
}
    800021a0:	b7f1                	j	8000216c <check_page_fault+0x54>

00000000800021a2 <find_file_to_remove>:
int find_file_to_remove(){
    800021a2:	1141                	addi	sp,sp,-16
    800021a4:	e406                	sd	ra,8(sp)
    800021a6:	e022                	sd	s0,0(sp)
    800021a8:	0800                	addi	s0,sp,16
    return second_fifo(); 
    800021aa:	00000097          	auipc	ra,0x0
    800021ae:	cb2080e7          	jalr	-846(ra) # 80001e5c <second_fifo>
}
    800021b2:	60a2                	ld	ra,8(sp)
    800021b4:	6402                	ld	s0,0(sp)
    800021b6:	0141                	addi	sp,sp,16
    800021b8:	8082                	ret

00000000800021ba <shift_counter>:
void shift_counter(){
    800021ba:	7139                	addi	sp,sp,-64
    800021bc:	fc06                	sd	ra,56(sp)
    800021be:	f822                	sd	s0,48(sp)
    800021c0:	f426                	sd	s1,40(sp)
    800021c2:	f04a                	sd	s2,32(sp)
    800021c4:	ec4e                	sd	s3,24(sp)
    800021c6:	e852                	sd	s4,16(sp)
    800021c8:	e456                	sd	s5,8(sp)
    800021ca:	0080                	addi	s0,sp,64
 struct proc * p = myproc();
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	20e080e7          	jalr	526(ra) # 800023da <myproc>
 for(int i=0; i<32; i++){
    800021d4:	17450913          	addi	s2,a0,372
 struct proc * p = myproc();
    800021d8:	4481                	li	s1,0
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    800021da:	80000ab7          	lui	s5,0x80000
 for(int i=0; i<32; i++){
    800021de:	6a05                	lui	s4,0x1
    800021e0:	000209b7          	lui	s3,0x20
    800021e4:	a029                	j	800021ee <shift_counter+0x34>
    800021e6:	94d2                	add	s1,s1,s4
    800021e8:	0931                	addi	s2,s2,12
    800021ea:	05348363          	beq	s1,s3,80002230 <shift_counter+0x76>
      pte = walk(myproc()->pagetable, page_virtual_address, 0);
    800021ee:	00000097          	auipc	ra,0x0
    800021f2:	1ec080e7          	jalr	492(ra) # 800023da <myproc>
    800021f6:	4601                	li	a2,0
    800021f8:	85a6                	mv	a1,s1
    800021fa:	6928                	ld	a0,80(a0)
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	dba080e7          	jalr	-582(ra) # 80000fb6 <walk>
      if(*pte & PTE_V){
    80002204:	611c                	ld	a5,0(a0)
    80002206:	8b85                	andi	a5,a5,1
    80002208:	dff9                	beqz	a5,800021e6 <shift_counter+0x2c>
        p->paging_meta_data[i].aging = p->paging_meta_data[i].aging>>1;
    8000220a:	00092783          	lw	a5,0(s2)
    8000220e:	0017d79b          	srliw	a5,a5,0x1
    80002212:	00f92023          	sw	a5,0(s2)
        if(*pte & PTE_A){
    80002216:	6118                	ld	a4,0(a0)
    80002218:	04077713          	andi	a4,a4,64
    8000221c:	d769                	beqz	a4,800021e6 <shift_counter+0x2c>
          p->paging_meta_data[i].aging = p->paging_meta_data[i].aging | SHIFT_ON;
    8000221e:	0157e7b3          	or	a5,a5,s5
    80002222:	00f92023          	sw	a5,0(s2)
          *pte = *pte & (~PTE_A); //turn off
    80002226:	611c                	ld	a5,0(a0)
    80002228:	fbf7f793          	andi	a5,a5,-65
    8000222c:	e11c                	sd	a5,0(a0)
    8000222e:	bf65                	j	800021e6 <shift_counter+0x2c>
}
    80002230:	70e2                	ld	ra,56(sp)
    80002232:	7442                	ld	s0,48(sp)
    80002234:	74a2                	ld	s1,40(sp)
    80002236:	7902                	ld	s2,32(sp)
    80002238:	69e2                	ld	s3,24(sp)
    8000223a:	6a42                	ld	s4,16(sp)
    8000223c:	6aa2                	ld	s5,8(sp)
    8000223e:	6121                	addi	sp,sp,64
    80002240:	8082                	ret

0000000080002242 <update_aging_algorithms>:
update_aging_algorithms(void){
    80002242:	1141                	addi	sp,sp,-16
    80002244:	e422                	sd	s0,8(sp)
    80002246:	0800                	addi	s0,sp,16
}
    80002248:	6422                	ld	s0,8(sp)
    8000224a:	0141                	addi	sp,sp,16
    8000224c:	8082                	ret

000000008000224e <init_aging>:
uint init_aging(int fifo_init_pages){
    8000224e:	1141                	addi	sp,sp,-16
    80002250:	e406                	sd	ra,8(sp)
    80002252:	e022                	sd	s0,0(sp)
    80002254:	0800                	addi	s0,sp,16
    return insert_to_queue(fifo_init_pages);
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	58a080e7          	jalr	1418(ra) # 800017e0 <insert_to_queue>
  #endif 
  return 0;
}
    8000225e:	2501                	sext.w	a0,a0
    80002260:	60a2                	ld	ra,8(sp)
    80002262:	6402                	ld	s0,0(sp)
    80002264:	0141                	addi	sp,sp,16
    80002266:	8082                	ret

0000000080002268 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80002268:	7139                	addi	sp,sp,-64
    8000226a:	fc06                	sd	ra,56(sp)
    8000226c:	f822                	sd	s0,48(sp)
    8000226e:	f426                	sd	s1,40(sp)
    80002270:	f04a                	sd	s2,32(sp)
    80002272:	ec4e                	sd	s3,24(sp)
    80002274:	e852                	sd	s4,16(sp)
    80002276:	e456                	sd	s5,8(sp)
    80002278:	e05a                	sd	s6,0(sp)
    8000227a:	0080                	addi	s0,sp,64
    8000227c:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000227e:	00010497          	auipc	s1,0x10
    80002282:	45248493          	addi	s1,s1,1106 # 800126d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80002286:	8b26                	mv	s6,s1
    80002288:	00007a97          	auipc	s5,0x7
    8000228c:	d78a8a93          	addi	s5,s5,-648 # 80009000 <etext>
    80002290:	04000937          	lui	s2,0x4000
    80002294:	197d                	addi	s2,s2,-1
    80002296:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002298:	0001ea17          	auipc	s4,0x1e
    8000229c:	438a0a13          	addi	s4,s4,1080 # 800206d0 <tickslock>
    char *pa = kalloc();
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	842080e7          	jalr	-1982(ra) # 80000ae2 <kalloc>
    800022a8:	862a                	mv	a2,a0
    if(pa == 0)
    800022aa:	c131                	beqz	a0,800022ee <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800022ac:	416485b3          	sub	a1,s1,s6
    800022b0:	859d                	srai	a1,a1,0x7
    800022b2:	000ab783          	ld	a5,0(s5)
    800022b6:	02f585b3          	mul	a1,a1,a5
    800022ba:	2585                	addiw	a1,a1,1
    800022bc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800022c0:	4719                	li	a4,6
    800022c2:	6685                	lui	a3,0x1
    800022c4:	40b905b3          	sub	a1,s2,a1
    800022c8:	854e                	mv	a0,s3
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	e4c080e7          	jalr	-436(ra) # 80001116 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800022d2:	38048493          	addi	s1,s1,896
    800022d6:	fd4495e3          	bne	s1,s4,800022a0 <proc_mapstacks+0x38>
  }
}
    800022da:	70e2                	ld	ra,56(sp)
    800022dc:	7442                	ld	s0,48(sp)
    800022de:	74a2                	ld	s1,40(sp)
    800022e0:	7902                	ld	s2,32(sp)
    800022e2:	69e2                	ld	s3,24(sp)
    800022e4:	6a42                	ld	s4,16(sp)
    800022e6:	6aa2                	ld	s5,8(sp)
    800022e8:	6b02                	ld	s6,0(sp)
    800022ea:	6121                	addi	sp,sp,64
    800022ec:	8082                	ret
      panic("kalloc");
    800022ee:	00007517          	auipc	a0,0x7
    800022f2:	01250513          	addi	a0,a0,18 # 80009300 <digits+0x2c0>
    800022f6:	ffffe097          	auipc	ra,0xffffe
    800022fa:	234080e7          	jalr	564(ra) # 8000052a <panic>

00000000800022fe <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800022fe:	7139                	addi	sp,sp,-64
    80002300:	fc06                	sd	ra,56(sp)
    80002302:	f822                	sd	s0,48(sp)
    80002304:	f426                	sd	s1,40(sp)
    80002306:	f04a                	sd	s2,32(sp)
    80002308:	ec4e                	sd	s3,24(sp)
    8000230a:	e852                	sd	s4,16(sp)
    8000230c:	e456                	sd	s5,8(sp)
    8000230e:	e05a                	sd	s6,0(sp)
    80002310:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80002312:	00007597          	auipc	a1,0x7
    80002316:	ff658593          	addi	a1,a1,-10 # 80009308 <digits+0x2c8>
    8000231a:	00010517          	auipc	a0,0x10
    8000231e:	f8650513          	addi	a0,a0,-122 # 800122a0 <pid_lock>
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	820080e7          	jalr	-2016(ra) # 80000b42 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000232a:	00007597          	auipc	a1,0x7
    8000232e:	fe658593          	addi	a1,a1,-26 # 80009310 <digits+0x2d0>
    80002332:	00010517          	auipc	a0,0x10
    80002336:	f8650513          	addi	a0,a0,-122 # 800122b8 <wait_lock>
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	808080e7          	jalr	-2040(ra) # 80000b42 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002342:	00010497          	auipc	s1,0x10
    80002346:	38e48493          	addi	s1,s1,910 # 800126d0 <proc>
      initlock(&p->lock, "proc");
    8000234a:	00007b17          	auipc	s6,0x7
    8000234e:	fd6b0b13          	addi	s6,s6,-42 # 80009320 <digits+0x2e0>
      p->kstack = KSTACK((int) (p - proc));
    80002352:	8aa6                	mv	s5,s1
    80002354:	00007a17          	auipc	s4,0x7
    80002358:	caca0a13          	addi	s4,s4,-852 # 80009000 <etext>
    8000235c:	04000937          	lui	s2,0x4000
    80002360:	197d                	addi	s2,s2,-1
    80002362:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002364:	0001e997          	auipc	s3,0x1e
    80002368:	36c98993          	addi	s3,s3,876 # 800206d0 <tickslock>
      initlock(&p->lock, "proc");
    8000236c:	85da                	mv	a1,s6
    8000236e:	8526                	mv	a0,s1
    80002370:	ffffe097          	auipc	ra,0xffffe
    80002374:	7d2080e7          	jalr	2002(ra) # 80000b42 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002378:	415487b3          	sub	a5,s1,s5
    8000237c:	879d                	srai	a5,a5,0x7
    8000237e:	000a3703          	ld	a4,0(s4)
    80002382:	02e787b3          	mul	a5,a5,a4
    80002386:	2785                	addiw	a5,a5,1
    80002388:	00d7979b          	slliw	a5,a5,0xd
    8000238c:	40f907b3          	sub	a5,s2,a5
    80002390:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80002392:	38048493          	addi	s1,s1,896
    80002396:	fd349be3          	bne	s1,s3,8000236c <procinit+0x6e>
  }
}
    8000239a:	70e2                	ld	ra,56(sp)
    8000239c:	7442                	ld	s0,48(sp)
    8000239e:	74a2                	ld	s1,40(sp)
    800023a0:	7902                	ld	s2,32(sp)
    800023a2:	69e2                	ld	s3,24(sp)
    800023a4:	6a42                	ld	s4,16(sp)
    800023a6:	6aa2                	ld	s5,8(sp)
    800023a8:	6b02                	ld	s6,0(sp)
    800023aa:	6121                	addi	sp,sp,64
    800023ac:	8082                	ret

00000000800023ae <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800023ae:	1141                	addi	sp,sp,-16
    800023b0:	e422                	sd	s0,8(sp)
    800023b2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800023b4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800023b6:	2501                	sext.w	a0,a0
    800023b8:	6422                	ld	s0,8(sp)
    800023ba:	0141                	addi	sp,sp,16
    800023bc:	8082                	ret

00000000800023be <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800023be:	1141                	addi	sp,sp,-16
    800023c0:	e422                	sd	s0,8(sp)
    800023c2:	0800                	addi	s0,sp,16
    800023c4:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800023c6:	2781                	sext.w	a5,a5
    800023c8:	079e                	slli	a5,a5,0x7
  return c;
}
    800023ca:	00010517          	auipc	a0,0x10
    800023ce:	f0650513          	addi	a0,a0,-250 # 800122d0 <cpus>
    800023d2:	953e                	add	a0,a0,a5
    800023d4:	6422                	ld	s0,8(sp)
    800023d6:	0141                	addi	sp,sp,16
    800023d8:	8082                	ret

00000000800023da <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800023da:	1101                	addi	sp,sp,-32
    800023dc:	ec06                	sd	ra,24(sp)
    800023de:	e822                	sd	s0,16(sp)
    800023e0:	e426                	sd	s1,8(sp)
    800023e2:	1000                	addi	s0,sp,32
  push_off();
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	7a2080e7          	jalr	1954(ra) # 80000b86 <push_off>
    800023ec:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800023ee:	2781                	sext.w	a5,a5
    800023f0:	079e                	slli	a5,a5,0x7
    800023f2:	00010717          	auipc	a4,0x10
    800023f6:	eae70713          	addi	a4,a4,-338 # 800122a0 <pid_lock>
    800023fa:	97ba                	add	a5,a5,a4
    800023fc:	7b84                	ld	s1,48(a5)
  pop_off();
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	828080e7          	jalr	-2008(ra) # 80000c26 <pop_off>
  return p;
}
    80002406:	8526                	mv	a0,s1
    80002408:	60e2                	ld	ra,24(sp)
    8000240a:	6442                	ld	s0,16(sp)
    8000240c:	64a2                	ld	s1,8(sp)
    8000240e:	6105                	addi	sp,sp,32
    80002410:	8082                	ret

0000000080002412 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80002412:	1141                	addi	sp,sp,-16
    80002414:	e406                	sd	ra,8(sp)
    80002416:	e022                	sd	s0,0(sp)
    80002418:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    8000241a:	00000097          	auipc	ra,0x0
    8000241e:	fc0080e7          	jalr	-64(ra) # 800023da <myproc>
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	864080e7          	jalr	-1948(ra) # 80000c86 <release>

  if (first) {
    8000242a:	00007797          	auipc	a5,0x7
    8000242e:	5b67a783          	lw	a5,1462(a5) # 800099e0 <first.1>
    80002432:	eb89                	bnez	a5,80002444 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80002434:	00001097          	auipc	ra,0x1
    80002438:	e0e080e7          	jalr	-498(ra) # 80003242 <usertrapret>
}
    8000243c:	60a2                	ld	ra,8(sp)
    8000243e:	6402                	ld	s0,0(sp)
    80002440:	0141                	addi	sp,sp,16
    80002442:	8082                	ret
    first = 0;
    80002444:	00007797          	auipc	a5,0x7
    80002448:	5807ae23          	sw	zero,1436(a5) # 800099e0 <first.1>
    fsinit(ROOTDEV);
    8000244c:	4505                	li	a0,1
    8000244e:	00002097          	auipc	ra,0x2
    80002452:	b54080e7          	jalr	-1196(ra) # 80003fa2 <fsinit>
    80002456:	bff9                	j	80002434 <forkret+0x22>

0000000080002458 <allocpid>:
allocpid() {
    80002458:	1101                	addi	sp,sp,-32
    8000245a:	ec06                	sd	ra,24(sp)
    8000245c:	e822                	sd	s0,16(sp)
    8000245e:	e426                	sd	s1,8(sp)
    80002460:	e04a                	sd	s2,0(sp)
    80002462:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80002464:	00010917          	auipc	s2,0x10
    80002468:	e3c90913          	addi	s2,s2,-452 # 800122a0 <pid_lock>
    8000246c:	854a                	mv	a0,s2
    8000246e:	ffffe097          	auipc	ra,0xffffe
    80002472:	764080e7          	jalr	1892(ra) # 80000bd2 <acquire>
  pid = nextpid;
    80002476:	00007797          	auipc	a5,0x7
    8000247a:	56e78793          	addi	a5,a5,1390 # 800099e4 <nextpid>
    8000247e:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80002480:	0014871b          	addiw	a4,s1,1
    80002484:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80002486:	854a                	mv	a0,s2
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	7fe080e7          	jalr	2046(ra) # 80000c86 <release>
}
    80002490:	8526                	mv	a0,s1
    80002492:	60e2                	ld	ra,24(sp)
    80002494:	6442                	ld	s0,16(sp)
    80002496:	64a2                	ld	s1,8(sp)
    80002498:	6902                	ld	s2,0(sp)
    8000249a:	6105                	addi	sp,sp,32
    8000249c:	8082                	ret

000000008000249e <proc_pagetable>:
{
    8000249e:	1101                	addi	sp,sp,-32
    800024a0:	ec06                	sd	ra,24(sp)
    800024a2:	e822                	sd	s0,16(sp)
    800024a4:	e426                	sd	s1,8(sp)
    800024a6:	e04a                	sd	s2,0(sp)
    800024a8:	1000                	addi	s0,sp,32
    800024aa:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	e54080e7          	jalr	-428(ra) # 80001300 <uvmcreate>
    800024b4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800024b6:	c121                	beqz	a0,800024f6 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800024b8:	4729                	li	a4,10
    800024ba:	00006697          	auipc	a3,0x6
    800024be:	b4668693          	addi	a3,a3,-1210 # 80008000 <_trampoline>
    800024c2:	6605                	lui	a2,0x1
    800024c4:	040005b7          	lui	a1,0x4000
    800024c8:	15fd                	addi	a1,a1,-1
    800024ca:	05b2                	slli	a1,a1,0xc
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	bbc080e7          	jalr	-1092(ra) # 80001088 <mappages>
    800024d4:	02054863          	bltz	a0,80002504 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800024d8:	4719                	li	a4,6
    800024da:	05893683          	ld	a3,88(s2)
    800024de:	6605                	lui	a2,0x1
    800024e0:	020005b7          	lui	a1,0x2000
    800024e4:	15fd                	addi	a1,a1,-1
    800024e6:	05b6                	slli	a1,a1,0xd
    800024e8:	8526                	mv	a0,s1
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	b9e080e7          	jalr	-1122(ra) # 80001088 <mappages>
    800024f2:	02054163          	bltz	a0,80002514 <proc_pagetable+0x76>
}
    800024f6:	8526                	mv	a0,s1
    800024f8:	60e2                	ld	ra,24(sp)
    800024fa:	6442                	ld	s0,16(sp)
    800024fc:	64a2                	ld	s1,8(sp)
    800024fe:	6902                	ld	s2,0(sp)
    80002500:	6105                	addi	sp,sp,32
    80002502:	8082                	ret
    uvmfree(pagetable, 0);
    80002504:	4581                	li	a1,0
    80002506:	8526                	mv	a0,s1
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	794080e7          	jalr	1940(ra) # 80001c9c <uvmfree>
    return 0;
    80002510:	4481                	li	s1,0
    80002512:	b7d5                	j	800024f6 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002514:	4681                	li	a3,0
    80002516:	4605                	li	a2,1
    80002518:	040005b7          	lui	a1,0x4000
    8000251c:	15fd                	addi	a1,a1,-1
    8000251e:	05b2                	slli	a1,a1,0xc
    80002520:	8526                	mv	a0,s1
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	3b8080e7          	jalr	952(ra) # 800018da <uvmunmap>
    uvmfree(pagetable, 0);
    8000252a:	4581                	li	a1,0
    8000252c:	8526                	mv	a0,s1
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	76e080e7          	jalr	1902(ra) # 80001c9c <uvmfree>
    return 0;
    80002536:	4481                	li	s1,0
    80002538:	bf7d                	j	800024f6 <proc_pagetable+0x58>

000000008000253a <proc_freepagetable>:
{
    8000253a:	1101                	addi	sp,sp,-32
    8000253c:	ec06                	sd	ra,24(sp)
    8000253e:	e822                	sd	s0,16(sp)
    80002540:	e426                	sd	s1,8(sp)
    80002542:	e04a                	sd	s2,0(sp)
    80002544:	1000                	addi	s0,sp,32
    80002546:	84aa                	mv	s1,a0
    80002548:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    8000254a:	4681                	li	a3,0
    8000254c:	4605                	li	a2,1
    8000254e:	040005b7          	lui	a1,0x4000
    80002552:	15fd                	addi	a1,a1,-1
    80002554:	05b2                	slli	a1,a1,0xc
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	384080e7          	jalr	900(ra) # 800018da <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000255e:	4681                	li	a3,0
    80002560:	4605                	li	a2,1
    80002562:	020005b7          	lui	a1,0x2000
    80002566:	15fd                	addi	a1,a1,-1
    80002568:	05b6                	slli	a1,a1,0xd
    8000256a:	8526                	mv	a0,s1
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	36e080e7          	jalr	878(ra) # 800018da <uvmunmap>
  uvmfree(pagetable, sz);
    80002574:	85ca                	mv	a1,s2
    80002576:	8526                	mv	a0,s1
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	724080e7          	jalr	1828(ra) # 80001c9c <uvmfree>
}
    80002580:	60e2                	ld	ra,24(sp)
    80002582:	6442                	ld	s0,16(sp)
    80002584:	64a2                	ld	s1,8(sp)
    80002586:	6902                	ld	s2,0(sp)
    80002588:	6105                	addi	sp,sp,32
    8000258a:	8082                	ret

000000008000258c <freeproc>:
{ 
    8000258c:	1101                	addi	sp,sp,-32
    8000258e:	ec06                	sd	ra,24(sp)
    80002590:	e822                	sd	s0,16(sp)
    80002592:	e426                	sd	s1,8(sp)
    80002594:	1000                	addi	s0,sp,32
    80002596:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002598:	6d28                	ld	a0,88(a0)
    8000259a:	c509                	beqz	a0,800025a4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    8000259c:	ffffe097          	auipc	ra,0xffffe
    800025a0:	43a080e7          	jalr	1082(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    800025a4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800025a8:	68a8                	ld	a0,80(s1)
    800025aa:	c511                	beqz	a0,800025b6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800025ac:	64ac                	ld	a1,72(s1)
    800025ae:	00000097          	auipc	ra,0x0
    800025b2:	f8c080e7          	jalr	-116(ra) # 8000253a <proc_freepagetable>
  p->pagetable = 0;
    800025b6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800025ba:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800025be:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    800025c2:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    800025c6:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800025ca:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    800025ce:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    800025d2:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    800025d6:	0004ac23          	sw	zero,24(s1)
}
    800025da:	60e2                	ld	ra,24(sp)
    800025dc:	6442                	ld	s0,16(sp)
    800025de:	64a2                	ld	s1,8(sp)
    800025e0:	6105                	addi	sp,sp,32
    800025e2:	8082                	ret

00000000800025e4 <allocproc>:
{
    800025e4:	7179                	addi	sp,sp,-48
    800025e6:	f406                	sd	ra,40(sp)
    800025e8:	f022                	sd	s0,32(sp)
    800025ea:	ec26                	sd	s1,24(sp)
    800025ec:	e84a                	sd	s2,16(sp)
    800025ee:	e44e                	sd	s3,8(sp)
    800025f0:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    800025f2:	00010497          	auipc	s1,0x10
    800025f6:	0de48493          	addi	s1,s1,222 # 800126d0 <proc>
    800025fa:	0001e997          	auipc	s3,0x1e
    800025fe:	0d698993          	addi	s3,s3,214 # 800206d0 <tickslock>
    acquire(&p->lock);
    80002602:	8926                	mv	s2,s1
    80002604:	8526                	mv	a0,s1
    80002606:	ffffe097          	auipc	ra,0xffffe
    8000260a:	5cc080e7          	jalr	1484(ra) # 80000bd2 <acquire>
    if(p->state == UNUSED) {
    8000260e:	4c9c                	lw	a5,24(s1)
    80002610:	cf81                	beqz	a5,80002628 <allocproc+0x44>
      release(&p->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	672080e7          	jalr	1650(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000261c:	38048493          	addi	s1,s1,896
    80002620:	ff3491e3          	bne	s1,s3,80002602 <allocproc+0x1e>
  return 0;
    80002624:	4481                	li	s1,0
    80002626:	a061                	j	800026ae <allocproc+0xca>
  p->pid = allocpid();
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	e30080e7          	jalr	-464(ra) # 80002458 <allocpid>
    80002630:	d888                	sw	a0,48(s1)
  p->state = USED;
    80002632:	4785                	li	a5,1
    80002634:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80002636:	ffffe097          	auipc	ra,0xffffe
    8000263a:	4ac080e7          	jalr	1196(ra) # 80000ae2 <kalloc>
    8000263e:	89aa                	mv	s3,a0
    80002640:	eca8                	sd	a0,88(s1)
    80002642:	cd35                	beqz	a0,800026be <allocproc+0xda>
  p->pagetable = proc_pagetable(p);
    80002644:	8526                	mv	a0,s1
    80002646:	00000097          	auipc	ra,0x0
    8000264a:	e58080e7          	jalr	-424(ra) # 8000249e <proc_pagetable>
    8000264e:	89aa                	mv	s3,a0
    80002650:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002652:	c151                	beqz	a0,800026d6 <allocproc+0xf2>
  memset(&p->context, 0, sizeof(p->context));
    80002654:	07000613          	li	a2,112
    80002658:	4581                	li	a1,0
    8000265a:	06048513          	addi	a0,s1,96
    8000265e:	ffffe097          	auipc	ra,0xffffe
    80002662:	670080e7          	jalr	1648(ra) # 80000cce <memset>
  p->context.ra = (uint64)forkret;
    80002666:	00000797          	auipc	a5,0x0
    8000266a:	dac78793          	addi	a5,a5,-596 # 80002412 <forkret>
    8000266e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002670:	60bc                	ld	a5,64(s1)
    80002672:	6705                	lui	a4,0x1
    80002674:	97ba                	add	a5,a5,a4
    80002676:	f4bc                	sd	a5,104(s1)
  for(int i=0;i<32;i++){
    80002678:	17048793          	addi	a5,s1,368
    8000267c:	2f048693          	addi	a3,s1,752
    p->paging_meta_data[i].offset = -1;
    80002680:	577d                	li	a4,-1
    80002682:	c398                	sw	a4,0(a5)
    p->paging_meta_data[i].aging = 0;
    80002684:	0007a223          	sw	zero,4(a5)
    p->paging_meta_data[i].in_memory = 0;
    80002688:	0007a423          	sw	zero,8(a5)
  for(int i=0;i<32;i++){
    8000268c:	07b1                	addi	a5,a5,12
    8000268e:	fed79ae3          	bne	a5,a3,80002682 <allocproc+0x9e>
  p->queue.front = 0;
    80002692:	3604a823          	sw	zero,880(s1)
  p->queue.last = -1;
    80002696:	57fd                	li	a5,-1
    80002698:	36f4aa23          	sw	a5,884(s1)
  for(int i=0; i<32; i++){
    8000269c:	2f048793          	addi	a5,s1,752
    800026a0:	37090713          	addi	a4,s2,880
    p->queue.pages[i] = -1;
    800026a4:	56fd                	li	a3,-1
    800026a6:	c394                	sw	a3,0(a5)
  for(int i=0; i<32; i++){
    800026a8:	0791                	addi	a5,a5,4
    800026aa:	fee79ee3          	bne	a5,a4,800026a6 <allocproc+0xc2>
}
    800026ae:	8526                	mv	a0,s1
    800026b0:	70a2                	ld	ra,40(sp)
    800026b2:	7402                	ld	s0,32(sp)
    800026b4:	64e2                	ld	s1,24(sp)
    800026b6:	6942                	ld	s2,16(sp)
    800026b8:	69a2                	ld	s3,8(sp)
    800026ba:	6145                	addi	sp,sp,48
    800026bc:	8082                	ret
    freeproc(p);
    800026be:	8526                	mv	a0,s1
    800026c0:	00000097          	auipc	ra,0x0
    800026c4:	ecc080e7          	jalr	-308(ra) # 8000258c <freeproc>
    release(&p->lock);
    800026c8:	8526                	mv	a0,s1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5bc080e7          	jalr	1468(ra) # 80000c86 <release>
    return 0;
    800026d2:	84ce                	mv	s1,s3
    800026d4:	bfe9                	j	800026ae <allocproc+0xca>
    freeproc(p);
    800026d6:	8526                	mv	a0,s1
    800026d8:	00000097          	auipc	ra,0x0
    800026dc:	eb4080e7          	jalr	-332(ra) # 8000258c <freeproc>
    release(&p->lock);
    800026e0:	8526                	mv	a0,s1
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	5a4080e7          	jalr	1444(ra) # 80000c86 <release>
    return 0;
    800026ea:	84ce                	mv	s1,s3
    800026ec:	b7c9                	j	800026ae <allocproc+0xca>

00000000800026ee <userinit>:
{
    800026ee:	1101                	addi	sp,sp,-32
    800026f0:	ec06                	sd	ra,24(sp)
    800026f2:	e822                	sd	s0,16(sp)
    800026f4:	e426                	sd	s1,8(sp)
    800026f6:	1000                	addi	s0,sp,32
  p = allocproc();
    800026f8:	00000097          	auipc	ra,0x0
    800026fc:	eec080e7          	jalr	-276(ra) # 800025e4 <allocproc>
    80002700:	84aa                	mv	s1,a0
  initproc = p;
    80002702:	00008797          	auipc	a5,0x8
    80002706:	92a7b323          	sd	a0,-1754(a5) # 8000a028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000270a:	03400613          	li	a2,52
    8000270e:	00007597          	auipc	a1,0x7
    80002712:	2e258593          	addi	a1,a1,738 # 800099f0 <initcode>
    80002716:	6928                	ld	a0,80(a0)
    80002718:	fffff097          	auipc	ra,0xfffff
    8000271c:	c16080e7          	jalr	-1002(ra) # 8000132e <uvminit>
  p->sz = PGSIZE;
    80002720:	6785                	lui	a5,0x1
    80002722:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80002724:	6cb8                	ld	a4,88(s1)
    80002726:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000272a:	6cb8                	ld	a4,88(s1)
    8000272c:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000272e:	4641                	li	a2,16
    80002730:	00007597          	auipc	a1,0x7
    80002734:	bf858593          	addi	a1,a1,-1032 # 80009328 <digits+0x2e8>
    80002738:	15848513          	addi	a0,s1,344
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	6e4080e7          	jalr	1764(ra) # 80000e20 <safestrcpy>
  p->cwd = namei("/");
    80002744:	00007517          	auipc	a0,0x7
    80002748:	bf450513          	addi	a0,a0,-1036 # 80009338 <digits+0x2f8>
    8000274c:	00002097          	auipc	ra,0x2
    80002750:	2a2080e7          	jalr	674(ra) # 800049ee <namei>
    80002754:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002758:	478d                	li	a5,3
    8000275a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	528080e7          	jalr	1320(ra) # 80000c86 <release>
}
    80002766:	60e2                	ld	ra,24(sp)
    80002768:	6442                	ld	s0,16(sp)
    8000276a:	64a2                	ld	s1,8(sp)
    8000276c:	6105                	addi	sp,sp,32
    8000276e:	8082                	ret

0000000080002770 <growproc>:
{
    80002770:	1101                	addi	sp,sp,-32
    80002772:	ec06                	sd	ra,24(sp)
    80002774:	e822                	sd	s0,16(sp)
    80002776:	e426                	sd	s1,8(sp)
    80002778:	e04a                	sd	s2,0(sp)
    8000277a:	1000                	addi	s0,sp,32
    8000277c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    8000277e:	00000097          	auipc	ra,0x0
    80002782:	c5c080e7          	jalr	-932(ra) # 800023da <myproc>
    80002786:	84aa                	mv	s1,a0
  if(n < 0){
    80002788:	00094d63          	bltz	s2,800027a2 <growproc+0x32>
  p->sz = p->sz + n;
    8000278c:	64a8                	ld	a0,72(s1)
    8000278e:	992a                	add	s2,s2,a0
    80002790:	0524b423          	sd	s2,72(s1)
}
    80002794:	4501                	li	a0,0
    80002796:	60e2                	ld	ra,24(sp)
    80002798:	6442                	ld	s0,16(sp)
    8000279a:	64a2                	ld	s1,8(sp)
    8000279c:	6902                	ld	s2,0(sp)
    8000279e:	6105                	addi	sp,sp,32
    800027a0:	8082                	ret
  sz = p->sz;
    800027a2:	652c                	ld	a1,72(a0)
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800027a4:	00b9063b          	addw	a2,s2,a1
    800027a8:	1602                	slli	a2,a2,0x20
    800027aa:	9201                	srli	a2,a2,0x20
    800027ac:	1582                	slli	a1,a1,0x20
    800027ae:	9181                	srli	a1,a1,0x20
    800027b0:	6928                	ld	a0,80(a0)
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	236080e7          	jalr	566(ra) # 800019e8 <uvmdealloc>
    800027ba:	bfc9                	j	8000278c <growproc+0x1c>

00000000800027bc <copy_swap_file>:
copy_swap_file(struct proc* child){
    800027bc:	7139                	addi	sp,sp,-64
    800027be:	fc06                	sd	ra,56(sp)
    800027c0:	f822                	sd	s0,48(sp)
    800027c2:	f426                	sd	s1,40(sp)
    800027c4:	f04a                	sd	s2,32(sp)
    800027c6:	ec4e                	sd	s3,24(sp)
    800027c8:	e852                	sd	s4,16(sp)
    800027ca:	e456                	sd	s5,8(sp)
    800027cc:	e05a                	sd	s6,0(sp)
    800027ce:	0080                	addi	s0,sp,64
    800027d0:	8b2a                	mv	s6,a0
  struct proc * pParent = myproc();
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	c08080e7          	jalr	-1016(ra) # 800023da <myproc>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    800027da:	653c                	ld	a5,72(a0)
    800027dc:	cfd9                	beqz	a5,8000287a <copy_swap_file+0xbe>
    800027de:	8a2a                	mv	s4,a0
    800027e0:	4481                	li	s1,0
    if(offset != -1){
    800027e2:	5afd                	li	s5,-1
    800027e4:	a83d                	j	80002822 <copy_swap_file+0x66>
      panic("not enough space to kalloc");
    800027e6:	00007517          	auipc	a0,0x7
    800027ea:	aba50513          	addi	a0,a0,-1350 # 800092a0 <digits+0x260>
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	d3c080e7          	jalr	-708(ra) # 8000052a <panic>
          panic("read swap file failed\n");
    800027f6:	00007517          	auipc	a0,0x7
    800027fa:	b4a50513          	addi	a0,a0,-1206 # 80009340 <digits+0x300>
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	d2c080e7          	jalr	-724(ra) # 8000052a <panic>
          panic("write swap file failed\n");
    80002806:	00007517          	auipc	a0,0x7
    8000280a:	b5250513          	addi	a0,a0,-1198 # 80009358 <digits+0x318>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d1c080e7          	jalr	-740(ra) # 8000052a <panic>
  for(uint64 i = 0; i < pParent->sz; i += PGSIZE){
    80002816:	6785                	lui	a5,0x1
    80002818:	94be                	add	s1,s1,a5
    8000281a:	048a3783          	ld	a5,72(s4)
    8000281e:	04f4fe63          	bgeu	s1,a5,8000287a <copy_swap_file+0xbe>
    offset = pParent->paging_meta_data[i/PGSIZE].offset;
    80002822:	00c4d713          	srli	a4,s1,0xc
    80002826:	00171793          	slli	a5,a4,0x1
    8000282a:	97ba                	add	a5,a5,a4
    8000282c:	078a                	slli	a5,a5,0x2
    8000282e:	97d2                	add	a5,a5,s4
    80002830:	1707a903          	lw	s2,368(a5) # 1170 <_entry-0x7fffee90>
    if(offset != -1){
    80002834:	ff5901e3          	beq	s2,s5,80002816 <copy_swap_file+0x5a>
      if((buffer = kalloc()) == 0)
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	2aa080e7          	jalr	682(ra) # 80000ae2 <kalloc>
    80002840:	89aa                	mv	s3,a0
    80002842:	d155                	beqz	a0,800027e6 <copy_swap_file+0x2a>
      if(readFromSwapFile(pParent, buffer, offset, PGSIZE) == -1)
    80002844:	2901                	sext.w	s2,s2
    80002846:	6685                	lui	a3,0x1
    80002848:	864a                	mv	a2,s2
    8000284a:	85aa                	mv	a1,a0
    8000284c:	8552                	mv	a0,s4
    8000284e:	00002097          	auipc	ra,0x2
    80002852:	4c8080e7          	jalr	1224(ra) # 80004d16 <readFromSwapFile>
    80002856:	fb5500e3          	beq	a0,s5,800027f6 <copy_swap_file+0x3a>
      if(writeToSwapFile(child, buffer, offset, PGSIZE ) == -1)
    8000285a:	6685                	lui	a3,0x1
    8000285c:	864a                	mv	a2,s2
    8000285e:	85ce                	mv	a1,s3
    80002860:	855a                	mv	a0,s6
    80002862:	00002097          	auipc	ra,0x2
    80002866:	490080e7          	jalr	1168(ra) # 80004cf2 <writeToSwapFile>
    8000286a:	f9550ee3          	beq	a0,s5,80002806 <copy_swap_file+0x4a>
      kfree(buffer);
    8000286e:	854e                	mv	a0,s3
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	166080e7          	jalr	358(ra) # 800009d6 <kfree>
    80002878:	bf79                	j	80002816 <copy_swap_file+0x5a>
}
    8000287a:	70e2                	ld	ra,56(sp)
    8000287c:	7442                	ld	s0,48(sp)
    8000287e:	74a2                	ld	s1,40(sp)
    80002880:	7902                	ld	s2,32(sp)
    80002882:	69e2                	ld	s3,24(sp)
    80002884:	6a42                	ld	s4,16(sp)
    80002886:	6aa2                	ld	s5,8(sp)
    80002888:	6b02                	ld	s6,0(sp)
    8000288a:	6121                	addi	sp,sp,64
    8000288c:	8082                	ret

000000008000288e <fork>:
{
    8000288e:	715d                	addi	sp,sp,-80
    80002890:	e486                	sd	ra,72(sp)
    80002892:	e0a2                	sd	s0,64(sp)
    80002894:	fc26                	sd	s1,56(sp)
    80002896:	f84a                	sd	s2,48(sp)
    80002898:	f44e                	sd	s3,40(sp)
    8000289a:	f052                	sd	s4,32(sp)
    8000289c:	ec56                	sd	s5,24(sp)
    8000289e:	e85a                	sd	s6,16(sp)
    800028a0:	e45e                	sd	s7,8(sp)
    800028a2:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	b36080e7          	jalr	-1226(ra) # 800023da <myproc>
    800028ac:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    800028ae:	00000097          	auipc	ra,0x0
    800028b2:	d36080e7          	jalr	-714(ra) # 800025e4 <allocproc>
    800028b6:	20050763          	beqz	a0,80002ac4 <fork+0x236>
    800028ba:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800028bc:	048ab603          	ld	a2,72(s5)
    800028c0:	692c                	ld	a1,80(a0)
    800028c2:	050ab503          	ld	a0,80(s5)
    800028c6:	fffff097          	auipc	ra,0xfffff
    800028ca:	4e0080e7          	jalr	1248(ra) # 80001da6 <uvmcopy>
    800028ce:	04054863          	bltz	a0,8000291e <fork+0x90>
  np->sz = p->sz;
    800028d2:	048ab783          	ld	a5,72(s5)
    800028d6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    800028da:	058ab683          	ld	a3,88(s5)
    800028de:	87b6                	mv	a5,a3
    800028e0:	058a3703          	ld	a4,88(s4)
    800028e4:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800028e8:	0007b803          	ld	a6,0(a5)
    800028ec:	6788                	ld	a0,8(a5)
    800028ee:	6b8c                	ld	a1,16(a5)
    800028f0:	6f90                	ld	a2,24(a5)
    800028f2:	01073023          	sd	a6,0(a4)
    800028f6:	e708                	sd	a0,8(a4)
    800028f8:	eb0c                	sd	a1,16(a4)
    800028fa:	ef10                	sd	a2,24(a4)
    800028fc:	02078793          	addi	a5,a5,32
    80002900:	02070713          	addi	a4,a4,32
    80002904:	fed792e3          	bne	a5,a3,800028e8 <fork+0x5a>
  np->trapframe->a0 = 0;
    80002908:	058a3783          	ld	a5,88(s4)
    8000290c:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80002910:	0d0a8493          	addi	s1,s5,208
    80002914:	0d0a0913          	addi	s2,s4,208
    80002918:	150a8993          	addi	s3,s5,336
    8000291c:	a03d                	j	8000294a <fork+0xbc>
    freeproc(np);
    8000291e:	8552                	mv	a0,s4
    80002920:	00000097          	auipc	ra,0x0
    80002924:	c6c080e7          	jalr	-916(ra) # 8000258c <freeproc>
    release(&np->lock);
    80002928:	8552                	mv	a0,s4
    8000292a:	ffffe097          	auipc	ra,0xffffe
    8000292e:	35c080e7          	jalr	860(ra) # 80000c86 <release>
    return -1;
    80002932:	5b7d                	li	s6,-1
    80002934:	a2b9                	j	80002a82 <fork+0x1f4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002936:	00003097          	auipc	ra,0x3
    8000293a:	a64080e7          	jalr	-1436(ra) # 8000539a <filedup>
    8000293e:	00a93023          	sd	a0,0(s2)
  for(i = 0; i < NOFILE; i++)
    80002942:	04a1                	addi	s1,s1,8
    80002944:	0921                	addi	s2,s2,8
    80002946:	01348563          	beq	s1,s3,80002950 <fork+0xc2>
    if(p->ofile[i])
    8000294a:	6088                	ld	a0,0(s1)
    8000294c:	f56d                	bnez	a0,80002936 <fork+0xa8>
    8000294e:	bfd5                	j	80002942 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002950:	150ab503          	ld	a0,336(s5)
    80002954:	00002097          	auipc	ra,0x2
    80002958:	888080e7          	jalr	-1912(ra) # 800041dc <idup>
    8000295c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002960:	4641                	li	a2,16
    80002962:	158a8593          	addi	a1,s5,344
    80002966:	158a0513          	addi	a0,s4,344
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	4b6080e7          	jalr	1206(ra) # 80000e20 <safestrcpy>
  pid = np->pid;
    80002972:	030a2b03          	lw	s6,48(s4)
  release(&np->lock);
    80002976:	8552                	mv	a0,s4
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	30e080e7          	jalr	782(ra) # 80000c86 <release>
    if(np->pid >2){
    80002980:	030a2703          	lw	a4,48(s4)
    80002984:	4789                	li	a5,2
    80002986:	10e7ca63          	blt	a5,a4,80002a9a <fork+0x20c>
    if(p->pid > 2){ 
    8000298a:	030aa703          	lw	a4,48(s5)
    8000298e:	4789                	li	a5,2
    80002990:	12e7c463          	blt	a5,a4,80002ab8 <fork+0x22a>
    for(int i=0; i<32; i++){
    80002994:	170a0993          	addi	s3,s4,368
{
    80002998:	4901                	li	s2,0
    for(int i=0; i<32; i++){
    8000299a:	02000b93          	li	s7,32
      np->paging_meta_data[i].offset = myproc()->paging_meta_data[i].offset;
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	a3c080e7          	jalr	-1476(ra) # 800023da <myproc>
    800029a6:	00191493          	slli	s1,s2,0x1
    800029aa:	012487b3          	add	a5,s1,s2
    800029ae:	078a                	slli	a5,a5,0x2
    800029b0:	953e                	add	a0,a0,a5
    800029b2:	17052783          	lw	a5,368(a0)
    800029b6:	00f9a023          	sw	a5,0(s3)
      np->paging_meta_data[i].aging = myproc()->paging_meta_data[i].aging;
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	a20080e7          	jalr	-1504(ra) # 800023da <myproc>
    800029c2:	012487b3          	add	a5,s1,s2
    800029c6:	078a                	slli	a5,a5,0x2
    800029c8:	953e                	add	a0,a0,a5
    800029ca:	17452783          	lw	a5,372(a0)
    800029ce:	00f9a223          	sw	a5,4(s3)
      np->paging_meta_data[i].in_memory = myproc()->paging_meta_data[i].in_memory;
    800029d2:	00000097          	auipc	ra,0x0
    800029d6:	a08080e7          	jalr	-1528(ra) # 800023da <myproc>
    800029da:	94ca                	add	s1,s1,s2
    800029dc:	048a                	slli	s1,s1,0x2
    800029de:	94aa                	add	s1,s1,a0
    800029e0:	1784a783          	lw	a5,376(s1)
    800029e4:	00f9a423          	sw	a5,8(s3)
    for(int i=0; i<32; i++){
    800029e8:	2905                	addiw	s2,s2,1
    800029ea:	09b1                	addi	s3,s3,12
    800029ec:	fb7919e3          	bne	s2,s7,8000299e <fork+0x110>
    np->queue.front = myproc()->queue.front;
    800029f0:	00000097          	auipc	ra,0x0
    800029f4:	9ea080e7          	jalr	-1558(ra) # 800023da <myproc>
    800029f8:	37052783          	lw	a5,880(a0)
    800029fc:	36fa2823          	sw	a5,880(s4)
    np->queue.last = myproc()->queue.last;
    80002a00:	00000097          	auipc	ra,0x0
    80002a04:	9da080e7          	jalr	-1574(ra) # 800023da <myproc>
    80002a08:	37452783          	lw	a5,884(a0)
    80002a0c:	36fa2a23          	sw	a5,884(s4)
    np->queue.page_counter = myproc()->queue.page_counter;
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	9ca080e7          	jalr	-1590(ra) # 800023da <myproc>
    80002a18:	37852783          	lw	a5,888(a0)
    80002a1c:	36fa2c23          	sw	a5,888(s4)
    for(int i=0; i<32; i++){
    80002a20:	2f0a0913          	addi	s2,s4,752
    80002a24:	4481                	li	s1,0
    80002a26:	02000993          	li	s3,32
      np->queue.pages[i] = myproc()->queue.pages[i];
    80002a2a:	00000097          	auipc	ra,0x0
    80002a2e:	9b0080e7          	jalr	-1616(ra) # 800023da <myproc>
    80002a32:	0bc48793          	addi	a5,s1,188
    80002a36:	078a                	slli	a5,a5,0x2
    80002a38:	953e                	add	a0,a0,a5
    80002a3a:	411c                	lw	a5,0(a0)
    80002a3c:	00f92023          	sw	a5,0(s2)
    for(int i=0; i<32; i++){
    80002a40:	2485                	addiw	s1,s1,1
    80002a42:	0911                	addi	s2,s2,4
    80002a44:	ff3493e3          	bne	s1,s3,80002a2a <fork+0x19c>
  acquire(&wait_lock);
    80002a48:	00010497          	auipc	s1,0x10
    80002a4c:	87048493          	addi	s1,s1,-1936 # 800122b8 <wait_lock>
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	180080e7          	jalr	384(ra) # 80000bd2 <acquire>
  np->parent = p;
    80002a5a:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80002a5e:	8526                	mv	a0,s1
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	226080e7          	jalr	550(ra) # 80000c86 <release>
  acquire(&np->lock);
    80002a68:	8552                	mv	a0,s4
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	168080e7          	jalr	360(ra) # 80000bd2 <acquire>
  np->state = RUNNABLE;
    80002a72:	478d                	li	a5,3
    80002a74:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002a78:	8552                	mv	a0,s4
    80002a7a:	ffffe097          	auipc	ra,0xffffe
    80002a7e:	20c080e7          	jalr	524(ra) # 80000c86 <release>
}
    80002a82:	855a                	mv	a0,s6
    80002a84:	60a6                	ld	ra,72(sp)
    80002a86:	6406                	ld	s0,64(sp)
    80002a88:	74e2                	ld	s1,56(sp)
    80002a8a:	7942                	ld	s2,48(sp)
    80002a8c:	79a2                	ld	s3,40(sp)
    80002a8e:	7a02                	ld	s4,32(sp)
    80002a90:	6ae2                	ld	s5,24(sp)
    80002a92:	6b42                	ld	s6,16(sp)
    80002a94:	6ba2                	ld	s7,8(sp)
    80002a96:	6161                	addi	sp,sp,80
    80002a98:	8082                	ret
      if(createSwapFile(np) != 0){
    80002a9a:	8552                	mv	a0,s4
    80002a9c:	00002097          	auipc	ra,0x2
    80002aa0:	1a6080e7          	jalr	422(ra) # 80004c42 <createSwapFile>
    80002aa4:	ee0503e3          	beqz	a0,8000298a <fork+0xfc>
        panic("create swap file failed");
    80002aa8:	00007517          	auipc	a0,0x7
    80002aac:	8c850513          	addi	a0,a0,-1848 # 80009370 <digits+0x330>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a7a080e7          	jalr	-1414(ra) # 8000052a <panic>
        copy_swap_file(np);
    80002ab8:	8552                	mv	a0,s4
    80002aba:	00000097          	auipc	ra,0x0
    80002abe:	d02080e7          	jalr	-766(ra) # 800027bc <copy_swap_file>
    80002ac2:	bdc9                	j	80002994 <fork+0x106>
    return -1;
    80002ac4:	5b7d                	li	s6,-1
    80002ac6:	bf75                	j	80002a82 <fork+0x1f4>

0000000080002ac8 <scheduler>:
{
    80002ac8:	7139                	addi	sp,sp,-64
    80002aca:	fc06                	sd	ra,56(sp)
    80002acc:	f822                	sd	s0,48(sp)
    80002ace:	f426                	sd	s1,40(sp)
    80002ad0:	f04a                	sd	s2,32(sp)
    80002ad2:	ec4e                	sd	s3,24(sp)
    80002ad4:	e852                	sd	s4,16(sp)
    80002ad6:	e456                	sd	s5,8(sp)
    80002ad8:	e05a                	sd	s6,0(sp)
    80002ada:	0080                	addi	s0,sp,64
    80002adc:	8792                	mv	a5,tp
  int id = r_tp();
    80002ade:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002ae0:	00779a93          	slli	s5,a5,0x7
    80002ae4:	0000f717          	auipc	a4,0xf
    80002ae8:	7bc70713          	addi	a4,a4,1980 # 800122a0 <pid_lock>
    80002aec:	9756                	add	a4,a4,s5
    80002aee:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80002af2:	0000f717          	auipc	a4,0xf
    80002af6:	7e670713          	addi	a4,a4,2022 # 800122d8 <cpus+0x8>
    80002afa:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002afc:	498d                	li	s3,3
        p->state = RUNNING;
    80002afe:	4b11                	li	s6,4
        c->proc = p;
    80002b00:	079e                	slli	a5,a5,0x7
    80002b02:	0000fa17          	auipc	s4,0xf
    80002b06:	79ea0a13          	addi	s4,s4,1950 # 800122a0 <pid_lock>
    80002b0a:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002b0c:	0001e917          	auipc	s2,0x1e
    80002b10:	bc490913          	addi	s2,s2,-1084 # 800206d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b18:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1c:	10079073          	csrw	sstatus,a5
    80002b20:	00010497          	auipc	s1,0x10
    80002b24:	bb048493          	addi	s1,s1,-1104 # 800126d0 <proc>
    80002b28:	a811                	j	80002b3c <scheduler+0x74>
      release(&p->lock);
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	ffffe097          	auipc	ra,0xffffe
    80002b30:	15a080e7          	jalr	346(ra) # 80000c86 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002b34:	38048493          	addi	s1,s1,896
    80002b38:	fd248ee3          	beq	s1,s2,80002b14 <scheduler+0x4c>
      acquire(&p->lock);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	094080e7          	jalr	148(ra) # 80000bd2 <acquire>
      if(p->state == RUNNABLE) {
    80002b46:	4c9c                	lw	a5,24(s1)
    80002b48:	ff3791e3          	bne	a5,s3,80002b2a <scheduler+0x62>
        p->state = RUNNING;
    80002b4c:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002b50:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002b54:	06048593          	addi	a1,s1,96
    80002b58:	8556                	mv	a0,s5
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	63e080e7          	jalr	1598(ra) # 80003198 <swtch>
        update_aging_algorithms();
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	6e0080e7          	jalr	1760(ra) # 80002242 <update_aging_algorithms>
        c->proc = 0;
    80002b6a:	020a3823          	sd	zero,48(s4)
    80002b6e:	bf75                	j	80002b2a <scheduler+0x62>

0000000080002b70 <sched>:
{
    80002b70:	7179                	addi	sp,sp,-48
    80002b72:	f406                	sd	ra,40(sp)
    80002b74:	f022                	sd	s0,32(sp)
    80002b76:	ec26                	sd	s1,24(sp)
    80002b78:	e84a                	sd	s2,16(sp)
    80002b7a:	e44e                	sd	s3,8(sp)
    80002b7c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	85c080e7          	jalr	-1956(ra) # 800023da <myproc>
    80002b86:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	fd0080e7          	jalr	-48(ra) # 80000b58 <holding>
    80002b90:	c93d                	beqz	a0,80002c06 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b92:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002b94:	2781                	sext.w	a5,a5
    80002b96:	079e                	slli	a5,a5,0x7
    80002b98:	0000f717          	auipc	a4,0xf
    80002b9c:	70870713          	addi	a4,a4,1800 # 800122a0 <pid_lock>
    80002ba0:	97ba                	add	a5,a5,a4
    80002ba2:	0a87a703          	lw	a4,168(a5)
    80002ba6:	4785                	li	a5,1
    80002ba8:	06f71763          	bne	a4,a5,80002c16 <sched+0xa6>
  if(p->state == RUNNING)
    80002bac:	4c98                	lw	a4,24(s1)
    80002bae:	4791                	li	a5,4
    80002bb0:	06f70b63          	beq	a4,a5,80002c26 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bb8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002bba:	efb5                	bnez	a5,80002c36 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bbc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002bbe:	0000f917          	auipc	s2,0xf
    80002bc2:	6e290913          	addi	s2,s2,1762 # 800122a0 <pid_lock>
    80002bc6:	2781                	sext.w	a5,a5
    80002bc8:	079e                	slli	a5,a5,0x7
    80002bca:	97ca                	add	a5,a5,s2
    80002bcc:	0ac7a983          	lw	s3,172(a5)
    80002bd0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002bd2:	2781                	sext.w	a5,a5
    80002bd4:	079e                	slli	a5,a5,0x7
    80002bd6:	0000f597          	auipc	a1,0xf
    80002bda:	70258593          	addi	a1,a1,1794 # 800122d8 <cpus+0x8>
    80002bde:	95be                	add	a1,a1,a5
    80002be0:	06048513          	addi	a0,s1,96
    80002be4:	00000097          	auipc	ra,0x0
    80002be8:	5b4080e7          	jalr	1460(ra) # 80003198 <swtch>
    80002bec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002bee:	2781                	sext.w	a5,a5
    80002bf0:	079e                	slli	a5,a5,0x7
    80002bf2:	97ca                	add	a5,a5,s2
    80002bf4:	0b37a623          	sw	s3,172(a5)
}
    80002bf8:	70a2                	ld	ra,40(sp)
    80002bfa:	7402                	ld	s0,32(sp)
    80002bfc:	64e2                	ld	s1,24(sp)
    80002bfe:	6942                	ld	s2,16(sp)
    80002c00:	69a2                	ld	s3,8(sp)
    80002c02:	6145                	addi	sp,sp,48
    80002c04:	8082                	ret
    panic("sched p->lock");
    80002c06:	00006517          	auipc	a0,0x6
    80002c0a:	78250513          	addi	a0,a0,1922 # 80009388 <digits+0x348>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	91c080e7          	jalr	-1764(ra) # 8000052a <panic>
    panic("sched locks");
    80002c16:	00006517          	auipc	a0,0x6
    80002c1a:	78250513          	addi	a0,a0,1922 # 80009398 <digits+0x358>
    80002c1e:	ffffe097          	auipc	ra,0xffffe
    80002c22:	90c080e7          	jalr	-1780(ra) # 8000052a <panic>
    panic("sched running");
    80002c26:	00006517          	auipc	a0,0x6
    80002c2a:	78250513          	addi	a0,a0,1922 # 800093a8 <digits+0x368>
    80002c2e:	ffffe097          	auipc	ra,0xffffe
    80002c32:	8fc080e7          	jalr	-1796(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002c36:	00006517          	auipc	a0,0x6
    80002c3a:	78250513          	addi	a0,a0,1922 # 800093b8 <digits+0x378>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	8ec080e7          	jalr	-1812(ra) # 8000052a <panic>

0000000080002c46 <yield>:
{
    80002c46:	1101                	addi	sp,sp,-32
    80002c48:	ec06                	sd	ra,24(sp)
    80002c4a:	e822                	sd	s0,16(sp)
    80002c4c:	e426                	sd	s1,8(sp)
    80002c4e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	78a080e7          	jalr	1930(ra) # 800023da <myproc>
    80002c58:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	f78080e7          	jalr	-136(ra) # 80000bd2 <acquire>
  p->state = RUNNABLE;
    80002c62:	478d                	li	a5,3
    80002c64:	cc9c                	sw	a5,24(s1)
  sched();
    80002c66:	00000097          	auipc	ra,0x0
    80002c6a:	f0a080e7          	jalr	-246(ra) # 80002b70 <sched>
  release(&p->lock);
    80002c6e:	8526                	mv	a0,s1
    80002c70:	ffffe097          	auipc	ra,0xffffe
    80002c74:	016080e7          	jalr	22(ra) # 80000c86 <release>
}
    80002c78:	60e2                	ld	ra,24(sp)
    80002c7a:	6442                	ld	s0,16(sp)
    80002c7c:	64a2                	ld	s1,8(sp)
    80002c7e:	6105                	addi	sp,sp,32
    80002c80:	8082                	ret

0000000080002c82 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002c82:	7179                	addi	sp,sp,-48
    80002c84:	f406                	sd	ra,40(sp)
    80002c86:	f022                	sd	s0,32(sp)
    80002c88:	ec26                	sd	s1,24(sp)
    80002c8a:	e84a                	sd	s2,16(sp)
    80002c8c:	e44e                	sd	s3,8(sp)
    80002c8e:	1800                	addi	s0,sp,48
    80002c90:	89aa                	mv	s3,a0
    80002c92:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c94:	fffff097          	auipc	ra,0xfffff
    80002c98:	746080e7          	jalr	1862(ra) # 800023da <myproc>
    80002c9c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	f34080e7          	jalr	-204(ra) # 80000bd2 <acquire>
  release(lk);
    80002ca6:	854a                	mv	a0,s2
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	fde080e7          	jalr	-34(ra) # 80000c86 <release>

  // Go to sleep.
  p->chan = chan;
    80002cb0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002cb4:	4789                	li	a5,2
    80002cb6:	cc9c                	sw	a5,24(s1)

  sched();
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	eb8080e7          	jalr	-328(ra) # 80002b70 <sched>

  // Tidy up.
  p->chan = 0;
    80002cc0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	fc0080e7          	jalr	-64(ra) # 80000c86 <release>
  acquire(lk);
    80002cce:	854a                	mv	a0,s2
    80002cd0:	ffffe097          	auipc	ra,0xffffe
    80002cd4:	f02080e7          	jalr	-254(ra) # 80000bd2 <acquire>
}
    80002cd8:	70a2                	ld	ra,40(sp)
    80002cda:	7402                	ld	s0,32(sp)
    80002cdc:	64e2                	ld	s1,24(sp)
    80002cde:	6942                	ld	s2,16(sp)
    80002ce0:	69a2                	ld	s3,8(sp)
    80002ce2:	6145                	addi	sp,sp,48
    80002ce4:	8082                	ret

0000000080002ce6 <wait>:
{
    80002ce6:	715d                	addi	sp,sp,-80
    80002ce8:	e486                	sd	ra,72(sp)
    80002cea:	e0a2                	sd	s0,64(sp)
    80002cec:	fc26                	sd	s1,56(sp)
    80002cee:	f84a                	sd	s2,48(sp)
    80002cf0:	f44e                	sd	s3,40(sp)
    80002cf2:	f052                	sd	s4,32(sp)
    80002cf4:	ec56                	sd	s5,24(sp)
    80002cf6:	e85a                	sd	s6,16(sp)
    80002cf8:	e45e                	sd	s7,8(sp)
    80002cfa:	e062                	sd	s8,0(sp)
    80002cfc:	0880                	addi	s0,sp,80
    80002cfe:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	6da080e7          	jalr	1754(ra) # 800023da <myproc>
    80002d08:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002d0a:	0000f517          	auipc	a0,0xf
    80002d0e:	5ae50513          	addi	a0,a0,1454 # 800122b8 <wait_lock>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	ec0080e7          	jalr	-320(ra) # 80000bd2 <acquire>
    havekids = 0;
    80002d1a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002d1c:	4a15                	li	s4,5
        havekids = 1;
    80002d1e:	4a85                	li	s5,1
    for(np = proc; np < &proc[NPROC]; np++){
    80002d20:	0001e997          	auipc	s3,0x1e
    80002d24:	9b098993          	addi	s3,s3,-1616 # 800206d0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002d28:	0000fc17          	auipc	s8,0xf
    80002d2c:	590c0c13          	addi	s8,s8,1424 # 800122b8 <wait_lock>
    havekids = 0;
    80002d30:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002d32:	00010497          	auipc	s1,0x10
    80002d36:	99e48493          	addi	s1,s1,-1634 # 800126d0 <proc>
    80002d3a:	a0bd                	j	80002da8 <wait+0xc2>
          pid = np->pid;
    80002d3c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002d40:	000b0e63          	beqz	s6,80002d5c <wait+0x76>
    80002d44:	4691                	li	a3,4
    80002d46:	02c48613          	addi	a2,s1,44
    80002d4a:	85da                	mv	a1,s6
    80002d4c:	05093503          	ld	a0,80(s2)
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	73a080e7          	jalr	1850(ra) # 8000148a <copyout>
    80002d58:	02054563          	bltz	a0,80002d82 <wait+0x9c>
          freeproc(np);
    80002d5c:	8526                	mv	a0,s1
    80002d5e:	00000097          	auipc	ra,0x0
    80002d62:	82e080e7          	jalr	-2002(ra) # 8000258c <freeproc>
          release(&np->lock);
    80002d66:	8526                	mv	a0,s1
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	f1e080e7          	jalr	-226(ra) # 80000c86 <release>
          release(&wait_lock);
    80002d70:	0000f517          	auipc	a0,0xf
    80002d74:	54850513          	addi	a0,a0,1352 # 800122b8 <wait_lock>
    80002d78:	ffffe097          	auipc	ra,0xffffe
    80002d7c:	f0e080e7          	jalr	-242(ra) # 80000c86 <release>
          return pid;
    80002d80:	a09d                	j	80002de6 <wait+0x100>
            release(&np->lock);
    80002d82:	8526                	mv	a0,s1
    80002d84:	ffffe097          	auipc	ra,0xffffe
    80002d88:	f02080e7          	jalr	-254(ra) # 80000c86 <release>
            release(&wait_lock);
    80002d8c:	0000f517          	auipc	a0,0xf
    80002d90:	52c50513          	addi	a0,a0,1324 # 800122b8 <wait_lock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	ef2080e7          	jalr	-270(ra) # 80000c86 <release>
            return -1;
    80002d9c:	59fd                	li	s3,-1
    80002d9e:	a0a1                	j	80002de6 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002da0:	38048493          	addi	s1,s1,896
    80002da4:	03348463          	beq	s1,s3,80002dcc <wait+0xe6>
      if(np->parent == p){
    80002da8:	7c9c                	ld	a5,56(s1)
    80002daa:	ff279be3          	bne	a5,s2,80002da0 <wait+0xba>
        acquire(&np->lock);
    80002dae:	8526                	mv	a0,s1
    80002db0:	ffffe097          	auipc	ra,0xffffe
    80002db4:	e22080e7          	jalr	-478(ra) # 80000bd2 <acquire>
        if(np->state == ZOMBIE){
    80002db8:	4c9c                	lw	a5,24(s1)
    80002dba:	f94781e3          	beq	a5,s4,80002d3c <wait+0x56>
        release(&np->lock);
    80002dbe:	8526                	mv	a0,s1
    80002dc0:	ffffe097          	auipc	ra,0xffffe
    80002dc4:	ec6080e7          	jalr	-314(ra) # 80000c86 <release>
        havekids = 1;
    80002dc8:	8756                	mv	a4,s5
    80002dca:	bfd9                	j	80002da0 <wait+0xba>
    if(!havekids || p->killed){
    80002dcc:	c701                	beqz	a4,80002dd4 <wait+0xee>
    80002dce:	02892783          	lw	a5,40(s2)
    80002dd2:	c79d                	beqz	a5,80002e00 <wait+0x11a>
      release(&wait_lock);
    80002dd4:	0000f517          	auipc	a0,0xf
    80002dd8:	4e450513          	addi	a0,a0,1252 # 800122b8 <wait_lock>
    80002ddc:	ffffe097          	auipc	ra,0xffffe
    80002de0:	eaa080e7          	jalr	-342(ra) # 80000c86 <release>
      return -1;
    80002de4:	59fd                	li	s3,-1
}
    80002de6:	854e                	mv	a0,s3
    80002de8:	60a6                	ld	ra,72(sp)
    80002dea:	6406                	ld	s0,64(sp)
    80002dec:	74e2                	ld	s1,56(sp)
    80002dee:	7942                	ld	s2,48(sp)
    80002df0:	79a2                	ld	s3,40(sp)
    80002df2:	7a02                	ld	s4,32(sp)
    80002df4:	6ae2                	ld	s5,24(sp)
    80002df6:	6b42                	ld	s6,16(sp)
    80002df8:	6ba2                	ld	s7,8(sp)
    80002dfa:	6c02                	ld	s8,0(sp)
    80002dfc:	6161                	addi	sp,sp,80
    80002dfe:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002e00:	85e2                	mv	a1,s8
    80002e02:	854a                	mv	a0,s2
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	e7e080e7          	jalr	-386(ra) # 80002c82 <sleep>
    havekids = 0;
    80002e0c:	b715                	j	80002d30 <wait+0x4a>

0000000080002e0e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002e0e:	7139                	addi	sp,sp,-64
    80002e10:	fc06                	sd	ra,56(sp)
    80002e12:	f822                	sd	s0,48(sp)
    80002e14:	f426                	sd	s1,40(sp)
    80002e16:	f04a                	sd	s2,32(sp)
    80002e18:	ec4e                	sd	s3,24(sp)
    80002e1a:	e852                	sd	s4,16(sp)
    80002e1c:	e456                	sd	s5,8(sp)
    80002e1e:	0080                	addi	s0,sp,64
    80002e20:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002e22:	00010497          	auipc	s1,0x10
    80002e26:	8ae48493          	addi	s1,s1,-1874 # 800126d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002e2a:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002e2c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002e2e:	0001e917          	auipc	s2,0x1e
    80002e32:	8a290913          	addi	s2,s2,-1886 # 800206d0 <tickslock>
    80002e36:	a811                	j	80002e4a <wakeup+0x3c>
      }
      release(&p->lock);
    80002e38:	8526                	mv	a0,s1
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	e4c080e7          	jalr	-436(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002e42:	38048493          	addi	s1,s1,896
    80002e46:	03248663          	beq	s1,s2,80002e72 <wakeup+0x64>
    if(p != myproc()){
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	590080e7          	jalr	1424(ra) # 800023da <myproc>
    80002e52:	fea488e3          	beq	s1,a0,80002e42 <wakeup+0x34>
      acquire(&p->lock);
    80002e56:	8526                	mv	a0,s1
    80002e58:	ffffe097          	auipc	ra,0xffffe
    80002e5c:	d7a080e7          	jalr	-646(ra) # 80000bd2 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002e60:	4c9c                	lw	a5,24(s1)
    80002e62:	fd379be3          	bne	a5,s3,80002e38 <wakeup+0x2a>
    80002e66:	709c                	ld	a5,32(s1)
    80002e68:	fd4798e3          	bne	a5,s4,80002e38 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002e6c:	0154ac23          	sw	s5,24(s1)
    80002e70:	b7e1                	j	80002e38 <wakeup+0x2a>
    }
  }
}
    80002e72:	70e2                	ld	ra,56(sp)
    80002e74:	7442                	ld	s0,48(sp)
    80002e76:	74a2                	ld	s1,40(sp)
    80002e78:	7902                	ld	s2,32(sp)
    80002e7a:	69e2                	ld	s3,24(sp)
    80002e7c:	6a42                	ld	s4,16(sp)
    80002e7e:	6aa2                	ld	s5,8(sp)
    80002e80:	6121                	addi	sp,sp,64
    80002e82:	8082                	ret

0000000080002e84 <reparent>:
{
    80002e84:	7179                	addi	sp,sp,-48
    80002e86:	f406                	sd	ra,40(sp)
    80002e88:	f022                	sd	s0,32(sp)
    80002e8a:	ec26                	sd	s1,24(sp)
    80002e8c:	e84a                	sd	s2,16(sp)
    80002e8e:	e44e                	sd	s3,8(sp)
    80002e90:	e052                	sd	s4,0(sp)
    80002e92:	1800                	addi	s0,sp,48
    80002e94:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002e96:	00010497          	auipc	s1,0x10
    80002e9a:	83a48493          	addi	s1,s1,-1990 # 800126d0 <proc>
      pp->parent = initproc;
    80002e9e:	00007a17          	auipc	s4,0x7
    80002ea2:	18aa0a13          	addi	s4,s4,394 # 8000a028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002ea6:	0001e997          	auipc	s3,0x1e
    80002eaa:	82a98993          	addi	s3,s3,-2006 # 800206d0 <tickslock>
    80002eae:	a029                	j	80002eb8 <reparent+0x34>
    80002eb0:	38048493          	addi	s1,s1,896
    80002eb4:	01348d63          	beq	s1,s3,80002ece <reparent+0x4a>
    if(pp->parent == p){
    80002eb8:	7c9c                	ld	a5,56(s1)
    80002eba:	ff279be3          	bne	a5,s2,80002eb0 <reparent+0x2c>
      pp->parent = initproc;
    80002ebe:	000a3503          	ld	a0,0(s4)
    80002ec2:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	f4a080e7          	jalr	-182(ra) # 80002e0e <wakeup>
    80002ecc:	b7d5                	j	80002eb0 <reparent+0x2c>
}
    80002ece:	70a2                	ld	ra,40(sp)
    80002ed0:	7402                	ld	s0,32(sp)
    80002ed2:	64e2                	ld	s1,24(sp)
    80002ed4:	6942                	ld	s2,16(sp)
    80002ed6:	69a2                	ld	s3,8(sp)
    80002ed8:	6a02                	ld	s4,0(sp)
    80002eda:	6145                	addi	sp,sp,48
    80002edc:	8082                	ret

0000000080002ede <exit>:
{
    80002ede:	7179                	addi	sp,sp,-48
    80002ee0:	f406                	sd	ra,40(sp)
    80002ee2:	f022                	sd	s0,32(sp)
    80002ee4:	ec26                	sd	s1,24(sp)
    80002ee6:	e84a                	sd	s2,16(sp)
    80002ee8:	e44e                	sd	s3,8(sp)
    80002eea:	e052                	sd	s4,0(sp)
    80002eec:	1800                	addi	s0,sp,48
    80002eee:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	4ea080e7          	jalr	1258(ra) # 800023da <myproc>
    80002ef8:	89aa                	mv	s3,a0
  if(p == initproc)
    80002efa:	00007797          	auipc	a5,0x7
    80002efe:	12e7b783          	ld	a5,302(a5) # 8000a028 <initproc>
    80002f02:	0d050493          	addi	s1,a0,208
    80002f06:	15050913          	addi	s2,a0,336
    80002f0a:	02a79363          	bne	a5,a0,80002f30 <exit+0x52>
    panic("init exiting");
    80002f0e:	00006517          	auipc	a0,0x6
    80002f12:	4c250513          	addi	a0,a0,1218 # 800093d0 <digits+0x390>
    80002f16:	ffffd097          	auipc	ra,0xffffd
    80002f1a:	614080e7          	jalr	1556(ra) # 8000052a <panic>
      fileclose(f);
    80002f1e:	00002097          	auipc	ra,0x2
    80002f22:	4ce080e7          	jalr	1230(ra) # 800053ec <fileclose>
      p->ofile[fd] = 0;
    80002f26:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002f2a:	04a1                	addi	s1,s1,8
    80002f2c:	01248563          	beq	s1,s2,80002f36 <exit+0x58>
    if(p->ofile[fd]){
    80002f30:	6088                	ld	a0,0(s1)
    80002f32:	f575                	bnez	a0,80002f1e <exit+0x40>
    80002f34:	bfdd                	j	80002f2a <exit+0x4c>
  if(p->pid > 2)
    80002f36:	0309a703          	lw	a4,48(s3)
    80002f3a:	4789                	li	a5,2
    80002f3c:	08e7c163          	blt	a5,a4,80002fbe <exit+0xe0>
  begin_op();
    80002f40:	00002097          	auipc	ra,0x2
    80002f44:	fe0080e7          	jalr	-32(ra) # 80004f20 <begin_op>
  iput(p->cwd);
    80002f48:	1509b503          	ld	a0,336(s3)
    80002f4c:	00001097          	auipc	ra,0x1
    80002f50:	488080e7          	jalr	1160(ra) # 800043d4 <iput>
  end_op();
    80002f54:	00002097          	auipc	ra,0x2
    80002f58:	04c080e7          	jalr	76(ra) # 80004fa0 <end_op>
  p->cwd = 0;
    80002f5c:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002f60:	0000f497          	auipc	s1,0xf
    80002f64:	35848493          	addi	s1,s1,856 # 800122b8 <wait_lock>
    80002f68:	8526                	mv	a0,s1
    80002f6a:	ffffe097          	auipc	ra,0xffffe
    80002f6e:	c68080e7          	jalr	-920(ra) # 80000bd2 <acquire>
  reparent(p);
    80002f72:	854e                	mv	a0,s3
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	f10080e7          	jalr	-240(ra) # 80002e84 <reparent>
  wakeup(p->parent);
    80002f7c:	0389b503          	ld	a0,56(s3)
    80002f80:	00000097          	auipc	ra,0x0
    80002f84:	e8e080e7          	jalr	-370(ra) # 80002e0e <wakeup>
  acquire(&p->lock);
    80002f88:	854e                	mv	a0,s3
    80002f8a:	ffffe097          	auipc	ra,0xffffe
    80002f8e:	c48080e7          	jalr	-952(ra) # 80000bd2 <acquire>
  p->xstate = status;
    80002f92:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002f96:	4795                	li	a5,5
    80002f98:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002f9c:	8526                	mv	a0,s1
    80002f9e:	ffffe097          	auipc	ra,0xffffe
    80002fa2:	ce8080e7          	jalr	-792(ra) # 80000c86 <release>
  sched();
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	bca080e7          	jalr	-1078(ra) # 80002b70 <sched>
  panic("zombie exit");
    80002fae:	00006517          	auipc	a0,0x6
    80002fb2:	43250513          	addi	a0,a0,1074 # 800093e0 <digits+0x3a0>
    80002fb6:	ffffd097          	auipc	ra,0xffffd
    80002fba:	574080e7          	jalr	1396(ra) # 8000052a <panic>
    removeSwapFile(p);
    80002fbe:	854e                	mv	a0,s3
    80002fc0:	00002097          	auipc	ra,0x2
    80002fc4:	ada080e7          	jalr	-1318(ra) # 80004a9a <removeSwapFile>
    80002fc8:	bfa5                	j	80002f40 <exit+0x62>

0000000080002fca <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002fca:	7179                	addi	sp,sp,-48
    80002fcc:	f406                	sd	ra,40(sp)
    80002fce:	f022                	sd	s0,32(sp)
    80002fd0:	ec26                	sd	s1,24(sp)
    80002fd2:	e84a                	sd	s2,16(sp)
    80002fd4:	e44e                	sd	s3,8(sp)
    80002fd6:	1800                	addi	s0,sp,48
    80002fd8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002fda:	0000f497          	auipc	s1,0xf
    80002fde:	6f648493          	addi	s1,s1,1782 # 800126d0 <proc>
    80002fe2:	0001d997          	auipc	s3,0x1d
    80002fe6:	6ee98993          	addi	s3,s3,1774 # 800206d0 <tickslock>
    acquire(&p->lock);
    80002fea:	8526                	mv	a0,s1
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	be6080e7          	jalr	-1050(ra) # 80000bd2 <acquire>
    if(p->pid == pid){
    80002ff4:	589c                	lw	a5,48(s1)
    80002ff6:	01278d63          	beq	a5,s2,80003010 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002ffa:	8526                	mv	a0,s1
    80002ffc:	ffffe097          	auipc	ra,0xffffe
    80003000:	c8a080e7          	jalr	-886(ra) # 80000c86 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80003004:	38048493          	addi	s1,s1,896
    80003008:	ff3491e3          	bne	s1,s3,80002fea <kill+0x20>
  }
  return -1;
    8000300c:	557d                	li	a0,-1
    8000300e:	a829                	j	80003028 <kill+0x5e>
      p->killed = 1;
    80003010:	4785                	li	a5,1
    80003012:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80003014:	4c98                	lw	a4,24(s1)
    80003016:	4789                	li	a5,2
    80003018:	00f70f63          	beq	a4,a5,80003036 <kill+0x6c>
      release(&p->lock);
    8000301c:	8526                	mv	a0,s1
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	c68080e7          	jalr	-920(ra) # 80000c86 <release>
      return 0;
    80003026:	4501                	li	a0,0
}
    80003028:	70a2                	ld	ra,40(sp)
    8000302a:	7402                	ld	s0,32(sp)
    8000302c:	64e2                	ld	s1,24(sp)
    8000302e:	6942                	ld	s2,16(sp)
    80003030:	69a2                	ld	s3,8(sp)
    80003032:	6145                	addi	sp,sp,48
    80003034:	8082                	ret
        p->state = RUNNABLE;
    80003036:	478d                	li	a5,3
    80003038:	cc9c                	sw	a5,24(s1)
    8000303a:	b7cd                	j	8000301c <kill+0x52>

000000008000303c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000303c:	7179                	addi	sp,sp,-48
    8000303e:	f406                	sd	ra,40(sp)
    80003040:	f022                	sd	s0,32(sp)
    80003042:	ec26                	sd	s1,24(sp)
    80003044:	e84a                	sd	s2,16(sp)
    80003046:	e44e                	sd	s3,8(sp)
    80003048:	e052                	sd	s4,0(sp)
    8000304a:	1800                	addi	s0,sp,48
    8000304c:	84aa                	mv	s1,a0
    8000304e:	892e                	mv	s2,a1
    80003050:	89b2                	mv	s3,a2
    80003052:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80003054:	fffff097          	auipc	ra,0xfffff
    80003058:	386080e7          	jalr	902(ra) # 800023da <myproc>
  if(user_dst){
    8000305c:	c08d                	beqz	s1,8000307e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000305e:	86d2                	mv	a3,s4
    80003060:	864e                	mv	a2,s3
    80003062:	85ca                	mv	a1,s2
    80003064:	6928                	ld	a0,80(a0)
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	424080e7          	jalr	1060(ra) # 8000148a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000306e:	70a2                	ld	ra,40(sp)
    80003070:	7402                	ld	s0,32(sp)
    80003072:	64e2                	ld	s1,24(sp)
    80003074:	6942                	ld	s2,16(sp)
    80003076:	69a2                	ld	s3,8(sp)
    80003078:	6a02                	ld	s4,0(sp)
    8000307a:	6145                	addi	sp,sp,48
    8000307c:	8082                	ret
    memmove((char *)dst, src, len);
    8000307e:	000a061b          	sext.w	a2,s4
    80003082:	85ce                	mv	a1,s3
    80003084:	854a                	mv	a0,s2
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	ca4080e7          	jalr	-860(ra) # 80000d2a <memmove>
    return 0;
    8000308e:	8526                	mv	a0,s1
    80003090:	bff9                	j	8000306e <either_copyout+0x32>

0000000080003092 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80003092:	7179                	addi	sp,sp,-48
    80003094:	f406                	sd	ra,40(sp)
    80003096:	f022                	sd	s0,32(sp)
    80003098:	ec26                	sd	s1,24(sp)
    8000309a:	e84a                	sd	s2,16(sp)
    8000309c:	e44e                	sd	s3,8(sp)
    8000309e:	e052                	sd	s4,0(sp)
    800030a0:	1800                	addi	s0,sp,48
    800030a2:	892a                	mv	s2,a0
    800030a4:	84ae                	mv	s1,a1
    800030a6:	89b2                	mv	s3,a2
    800030a8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	330080e7          	jalr	816(ra) # 800023da <myproc>
  if(user_src){
    800030b2:	c08d                	beqz	s1,800030d4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800030b4:	86d2                	mv	a3,s4
    800030b6:	864e                	mv	a2,s3
    800030b8:	85ca                	mv	a1,s2
    800030ba:	6928                	ld	a0,80(a0)
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	45a080e7          	jalr	1114(ra) # 80001516 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800030c4:	70a2                	ld	ra,40(sp)
    800030c6:	7402                	ld	s0,32(sp)
    800030c8:	64e2                	ld	s1,24(sp)
    800030ca:	6942                	ld	s2,16(sp)
    800030cc:	69a2                	ld	s3,8(sp)
    800030ce:	6a02                	ld	s4,0(sp)
    800030d0:	6145                	addi	sp,sp,48
    800030d2:	8082                	ret
    memmove(dst, (char*)src, len);
    800030d4:	000a061b          	sext.w	a2,s4
    800030d8:	85ce                	mv	a1,s3
    800030da:	854a                	mv	a0,s2
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	c4e080e7          	jalr	-946(ra) # 80000d2a <memmove>
    return 0;
    800030e4:	8526                	mv	a0,s1
    800030e6:	bff9                	j	800030c4 <either_copyin+0x32>

00000000800030e8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800030e8:	715d                	addi	sp,sp,-80
    800030ea:	e486                	sd	ra,72(sp)
    800030ec:	e0a2                	sd	s0,64(sp)
    800030ee:	fc26                	sd	s1,56(sp)
    800030f0:	f84a                	sd	s2,48(sp)
    800030f2:	f44e                	sd	s3,40(sp)
    800030f4:	f052                	sd	s4,32(sp)
    800030f6:	ec56                	sd	s5,24(sp)
    800030f8:	e85a                	sd	s6,16(sp)
    800030fa:	e45e                	sd	s7,8(sp)
    800030fc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800030fe:	00006517          	auipc	a0,0x6
    80003102:	13a50513          	addi	a0,a0,314 # 80009238 <digits+0x1f8>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	46e080e7          	jalr	1134(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000310e:	0000f497          	auipc	s1,0xf
    80003112:	71a48493          	addi	s1,s1,1818 # 80012828 <proc+0x158>
    80003116:	0001d917          	auipc	s2,0x1d
    8000311a:	71290913          	addi	s2,s2,1810 # 80020828 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000311e:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80003120:	00006997          	auipc	s3,0x6
    80003124:	2d098993          	addi	s3,s3,720 # 800093f0 <digits+0x3b0>
    printf("%d %s %s", p->pid, state, p->name);
    80003128:	00006a97          	auipc	s5,0x6
    8000312c:	2d0a8a93          	addi	s5,s5,720 # 800093f8 <digits+0x3b8>
    printf("\n");
    80003130:	00006a17          	auipc	s4,0x6
    80003134:	108a0a13          	addi	s4,s4,264 # 80009238 <digits+0x1f8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003138:	00006b97          	auipc	s7,0x6
    8000313c:	2f8b8b93          	addi	s7,s7,760 # 80009430 <states.0>
    80003140:	a00d                	j	80003162 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003142:	ed86a583          	lw	a1,-296(a3)
    80003146:	8556                	mv	a0,s5
    80003148:	ffffd097          	auipc	ra,0xffffd
    8000314c:	42c080e7          	jalr	1068(ra) # 80000574 <printf>
    printf("\n");
    80003150:	8552                	mv	a0,s4
    80003152:	ffffd097          	auipc	ra,0xffffd
    80003156:	422080e7          	jalr	1058(ra) # 80000574 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000315a:	38048493          	addi	s1,s1,896
    8000315e:	03248263          	beq	s1,s2,80003182 <procdump+0x9a>
    if(p->state == UNUSED)
    80003162:	86a6                	mv	a3,s1
    80003164:	ec04a783          	lw	a5,-320(s1)
    80003168:	dbed                	beqz	a5,8000315a <procdump+0x72>
      state = "???";
    8000316a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000316c:	fcfb6be3          	bltu	s6,a5,80003142 <procdump+0x5a>
    80003170:	02079713          	slli	a4,a5,0x20
    80003174:	01d75793          	srli	a5,a4,0x1d
    80003178:	97de                	add	a5,a5,s7
    8000317a:	6390                	ld	a2,0(a5)
    8000317c:	f279                	bnez	a2,80003142 <procdump+0x5a>
      state = "???";
    8000317e:	864e                	mv	a2,s3
    80003180:	b7c9                	j	80003142 <procdump+0x5a>
  }
}
    80003182:	60a6                	ld	ra,72(sp)
    80003184:	6406                	ld	s0,64(sp)
    80003186:	74e2                	ld	s1,56(sp)
    80003188:	7942                	ld	s2,48(sp)
    8000318a:	79a2                	ld	s3,40(sp)
    8000318c:	7a02                	ld	s4,32(sp)
    8000318e:	6ae2                	ld	s5,24(sp)
    80003190:	6b42                	ld	s6,16(sp)
    80003192:	6ba2                	ld	s7,8(sp)
    80003194:	6161                	addi	sp,sp,80
    80003196:	8082                	ret

0000000080003198 <swtch>:
    80003198:	00153023          	sd	ra,0(a0)
    8000319c:	00253423          	sd	sp,8(a0)
    800031a0:	e900                	sd	s0,16(a0)
    800031a2:	ed04                	sd	s1,24(a0)
    800031a4:	03253023          	sd	s2,32(a0)
    800031a8:	03353423          	sd	s3,40(a0)
    800031ac:	03453823          	sd	s4,48(a0)
    800031b0:	03553c23          	sd	s5,56(a0)
    800031b4:	05653023          	sd	s6,64(a0)
    800031b8:	05753423          	sd	s7,72(a0)
    800031bc:	05853823          	sd	s8,80(a0)
    800031c0:	05953c23          	sd	s9,88(a0)
    800031c4:	07a53023          	sd	s10,96(a0)
    800031c8:	07b53423          	sd	s11,104(a0)
    800031cc:	0005b083          	ld	ra,0(a1)
    800031d0:	0085b103          	ld	sp,8(a1)
    800031d4:	6980                	ld	s0,16(a1)
    800031d6:	6d84                	ld	s1,24(a1)
    800031d8:	0205b903          	ld	s2,32(a1)
    800031dc:	0285b983          	ld	s3,40(a1)
    800031e0:	0305ba03          	ld	s4,48(a1)
    800031e4:	0385ba83          	ld	s5,56(a1)
    800031e8:	0405bb03          	ld	s6,64(a1)
    800031ec:	0485bb83          	ld	s7,72(a1)
    800031f0:	0505bc03          	ld	s8,80(a1)
    800031f4:	0585bc83          	ld	s9,88(a1)
    800031f8:	0605bd03          	ld	s10,96(a1)
    800031fc:	0685bd83          	ld	s11,104(a1)
    80003200:	8082                	ret

0000000080003202 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80003202:	1141                	addi	sp,sp,-16
    80003204:	e406                	sd	ra,8(sp)
    80003206:	e022                	sd	s0,0(sp)
    80003208:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000320a:	00006597          	auipc	a1,0x6
    8000320e:	25658593          	addi	a1,a1,598 # 80009460 <states.0+0x30>
    80003212:	0001d517          	auipc	a0,0x1d
    80003216:	4be50513          	addi	a0,a0,1214 # 800206d0 <tickslock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	928080e7          	jalr	-1752(ra) # 80000b42 <initlock>
}
    80003222:	60a2                	ld	ra,8(sp)
    80003224:	6402                	ld	s0,0(sp)
    80003226:	0141                	addi	sp,sp,16
    80003228:	8082                	ret

000000008000322a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000322a:	1141                	addi	sp,sp,-16
    8000322c:	e422                	sd	s0,8(sp)
    8000322e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003230:	00004797          	auipc	a5,0x4
    80003234:	a1078793          	addi	a5,a5,-1520 # 80006c40 <kernelvec>
    80003238:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000323c:	6422                	ld	s0,8(sp)
    8000323e:	0141                	addi	sp,sp,16
    80003240:	8082                	ret

0000000080003242 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80003242:	1141                	addi	sp,sp,-16
    80003244:	e406                	sd	ra,8(sp)
    80003246:	e022                	sd	s0,0(sp)
    80003248:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000324a:	fffff097          	auipc	ra,0xfffff
    8000324e:	190080e7          	jalr	400(ra) # 800023da <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003252:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80003256:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003258:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000325c:	00005617          	auipc	a2,0x5
    80003260:	da460613          	addi	a2,a2,-604 # 80008000 <_trampoline>
    80003264:	00005697          	auipc	a3,0x5
    80003268:	d9c68693          	addi	a3,a3,-612 # 80008000 <_trampoline>
    8000326c:	8e91                	sub	a3,a3,a2
    8000326e:	040007b7          	lui	a5,0x4000
    80003272:	17fd                	addi	a5,a5,-1
    80003274:	07b2                	slli	a5,a5,0xc
    80003276:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003278:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000327c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000327e:	180026f3          	csrr	a3,satp
    80003282:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80003284:	6d38                	ld	a4,88(a0)
    80003286:	6134                	ld	a3,64(a0)
    80003288:	6585                	lui	a1,0x1
    8000328a:	96ae                	add	a3,a3,a1
    8000328c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000328e:	6d38                	ld	a4,88(a0)
    80003290:	00000697          	auipc	a3,0x0
    80003294:	13868693          	addi	a3,a3,312 # 800033c8 <usertrap>
    80003298:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000329a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000329c:	8692                	mv	a3,tp
    8000329e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800032a0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800032a4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800032a8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032ac:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800032b0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032b2:	6f18                	ld	a4,24(a4)
    800032b4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800032b8:	692c                	ld	a1,80(a0)
    800032ba:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800032bc:	00005717          	auipc	a4,0x5
    800032c0:	dd470713          	addi	a4,a4,-556 # 80008090 <userret>
    800032c4:	8f11                	sub	a4,a4,a2
    800032c6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800032c8:	577d                	li	a4,-1
    800032ca:	177e                	slli	a4,a4,0x3f
    800032cc:	8dd9                	or	a1,a1,a4
    800032ce:	02000537          	lui	a0,0x2000
    800032d2:	157d                	addi	a0,a0,-1
    800032d4:	0536                	slli	a0,a0,0xd
    800032d6:	9782                	jalr	a5
}
    800032d8:	60a2                	ld	ra,8(sp)
    800032da:	6402                	ld	s0,0(sp)
    800032dc:	0141                	addi	sp,sp,16
    800032de:	8082                	ret

00000000800032e0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800032e0:	1101                	addi	sp,sp,-32
    800032e2:	ec06                	sd	ra,24(sp)
    800032e4:	e822                	sd	s0,16(sp)
    800032e6:	e426                	sd	s1,8(sp)
    800032e8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800032ea:	0001d497          	auipc	s1,0x1d
    800032ee:	3e648493          	addi	s1,s1,998 # 800206d0 <tickslock>
    800032f2:	8526                	mv	a0,s1
    800032f4:	ffffe097          	auipc	ra,0xffffe
    800032f8:	8de080e7          	jalr	-1826(ra) # 80000bd2 <acquire>
  ticks++;
    800032fc:	00007517          	auipc	a0,0x7
    80003300:	d3450513          	addi	a0,a0,-716 # 8000a030 <ticks>
    80003304:	411c                	lw	a5,0(a0)
    80003306:	2785                	addiw	a5,a5,1
    80003308:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	b04080e7          	jalr	-1276(ra) # 80002e0e <wakeup>
  release(&tickslock);
    80003312:	8526                	mv	a0,s1
    80003314:	ffffe097          	auipc	ra,0xffffe
    80003318:	972080e7          	jalr	-1678(ra) # 80000c86 <release>
}
    8000331c:	60e2                	ld	ra,24(sp)
    8000331e:	6442                	ld	s0,16(sp)
    80003320:	64a2                	ld	s1,8(sp)
    80003322:	6105                	addi	sp,sp,32
    80003324:	8082                	ret

0000000080003326 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003326:	1101                	addi	sp,sp,-32
    80003328:	ec06                	sd	ra,24(sp)
    8000332a:	e822                	sd	s0,16(sp)
    8000332c:	e426                	sd	s1,8(sp)
    8000332e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003330:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003334:	00074d63          	bltz	a4,8000334e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003338:	57fd                	li	a5,-1
    8000333a:	17fe                	slli	a5,a5,0x3f
    8000333c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000333e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80003340:	06f70363          	beq	a4,a5,800033a6 <devintr+0x80>
  }
}
    80003344:	60e2                	ld	ra,24(sp)
    80003346:	6442                	ld	s0,16(sp)
    80003348:	64a2                	ld	s1,8(sp)
    8000334a:	6105                	addi	sp,sp,32
    8000334c:	8082                	ret
     (scause & 0xff) == 9){
    8000334e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80003352:	46a5                	li	a3,9
    80003354:	fed792e3          	bne	a5,a3,80003338 <devintr+0x12>
    int irq = plic_claim();
    80003358:	00004097          	auipc	ra,0x4
    8000335c:	9f0080e7          	jalr	-1552(ra) # 80006d48 <plic_claim>
    80003360:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80003362:	47a9                	li	a5,10
    80003364:	02f50763          	beq	a0,a5,80003392 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80003368:	4785                	li	a5,1
    8000336a:	02f50963          	beq	a0,a5,8000339c <devintr+0x76>
    return 1;
    8000336e:	4505                	li	a0,1
    } else if(irq){
    80003370:	d8f1                	beqz	s1,80003344 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003372:	85a6                	mv	a1,s1
    80003374:	00006517          	auipc	a0,0x6
    80003378:	0f450513          	addi	a0,a0,244 # 80009468 <states.0+0x38>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1f8080e7          	jalr	504(ra) # 80000574 <printf>
      plic_complete(irq);
    80003384:	8526                	mv	a0,s1
    80003386:	00004097          	auipc	ra,0x4
    8000338a:	9e6080e7          	jalr	-1562(ra) # 80006d6c <plic_complete>
    return 1;
    8000338e:	4505                	li	a0,1
    80003390:	bf55                	j	80003344 <devintr+0x1e>
      uartintr();
    80003392:	ffffd097          	auipc	ra,0xffffd
    80003396:	5f4080e7          	jalr	1524(ra) # 80000986 <uartintr>
    8000339a:	b7ed                	j	80003384 <devintr+0x5e>
      virtio_disk_intr();
    8000339c:	00004097          	auipc	ra,0x4
    800033a0:	e62080e7          	jalr	-414(ra) # 800071fe <virtio_disk_intr>
    800033a4:	b7c5                	j	80003384 <devintr+0x5e>
    if(cpuid() == 0){
    800033a6:	fffff097          	auipc	ra,0xfffff
    800033aa:	008080e7          	jalr	8(ra) # 800023ae <cpuid>
    800033ae:	c901                	beqz	a0,800033be <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800033b0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800033b4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800033b6:	14479073          	csrw	sip,a5
    return 2;
    800033ba:	4509                	li	a0,2
    800033bc:	b761                	j	80003344 <devintr+0x1e>
      clockintr();
    800033be:	00000097          	auipc	ra,0x0
    800033c2:	f22080e7          	jalr	-222(ra) # 800032e0 <clockintr>
    800033c6:	b7ed                	j	800033b0 <devintr+0x8a>

00000000800033c8 <usertrap>:
{
    800033c8:	1101                	addi	sp,sp,-32
    800033ca:	ec06                	sd	ra,24(sp)
    800033cc:	e822                	sd	s0,16(sp)
    800033ce:	e426                	sd	s1,8(sp)
    800033d0:	e04a                	sd	s2,0(sp)
    800033d2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800033d4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800033d8:	1007f793          	andi	a5,a5,256
    800033dc:	efb9                	bnez	a5,8000343a <usertrap+0x72>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800033de:	00004797          	auipc	a5,0x4
    800033e2:	86278793          	addi	a5,a5,-1950 # 80006c40 <kernelvec>
    800033e6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800033ea:	fffff097          	auipc	ra,0xfffff
    800033ee:	ff0080e7          	jalr	-16(ra) # 800023da <myproc>
    800033f2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800033f4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800033f6:	14102773          	csrr	a4,sepc
    800033fa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800033fc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80003400:	47a1                	li	a5,8
    80003402:	04f70463          	beq	a4,a5,8000344a <usertrap+0x82>
    80003406:	14202773          	csrr	a4,scause
  else if(r_scause() == 13 || r_scause() == 15){
    8000340a:	47b5                	li	a5,13
    8000340c:	00f70763          	beq	a4,a5,8000341a <usertrap+0x52>
    80003410:	14202773          	csrr	a4,scause
    80003414:	47bd                	li	a5,15
    80003416:	06f71163          	bne	a4,a5,80003478 <usertrap+0xb0>
    check_page_fault();
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	cfe080e7          	jalr	-770(ra) # 80002118 <check_page_fault>
  if(p->killed)
    80003422:	549c                	lw	a5,40(s1)
    80003424:	efc9                	bnez	a5,800034be <usertrap+0xf6>
  usertrapret();
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	e1c080e7          	jalr	-484(ra) # 80003242 <usertrapret>
}
    8000342e:	60e2                	ld	ra,24(sp)
    80003430:	6442                	ld	s0,16(sp)
    80003432:	64a2                	ld	s1,8(sp)
    80003434:	6902                	ld	s2,0(sp)
    80003436:	6105                	addi	sp,sp,32
    80003438:	8082                	ret
    panic("usertrap: not from user mode");
    8000343a:	00006517          	auipc	a0,0x6
    8000343e:	04e50513          	addi	a0,a0,78 # 80009488 <states.0+0x58>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	0e8080e7          	jalr	232(ra) # 8000052a <panic>
    if(p->killed)
    8000344a:	551c                	lw	a5,40(a0)
    8000344c:	e385                	bnez	a5,8000346c <usertrap+0xa4>
    p->trapframe->epc += 4;
    8000344e:	6cb8                	ld	a4,88(s1)
    80003450:	6f1c                	ld	a5,24(a4)
    80003452:	0791                	addi	a5,a5,4
    80003454:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003456:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000345a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000345e:	10079073          	csrw	sstatus,a5
    syscall();
    80003462:	00000097          	auipc	ra,0x0
    80003466:	2ba080e7          	jalr	698(ra) # 8000371c <syscall>
    8000346a:	bf65                	j	80003422 <usertrap+0x5a>
      exit(-1);
    8000346c:	557d                	li	a0,-1
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	a70080e7          	jalr	-1424(ra) # 80002ede <exit>
    80003476:	bfe1                	j	8000344e <usertrap+0x86>
  else if((which_dev = devintr()) != 0){
    80003478:	00000097          	auipc	ra,0x0
    8000347c:	eae080e7          	jalr	-338(ra) # 80003326 <devintr>
    80003480:	892a                	mv	s2,a0
    80003482:	c501                	beqz	a0,8000348a <usertrap+0xc2>
  if(p->killed)
    80003484:	549c                	lw	a5,40(s1)
    80003486:	c3b1                	beqz	a5,800034ca <usertrap+0x102>
    80003488:	a825                	j	800034c0 <usertrap+0xf8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000348a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000348e:	5890                	lw	a2,48(s1)
    80003490:	00006517          	auipc	a0,0x6
    80003494:	01850513          	addi	a0,a0,24 # 800094a8 <states.0+0x78>
    80003498:	ffffd097          	auipc	ra,0xffffd
    8000349c:	0dc080e7          	jalr	220(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034a0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800034a4:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800034a8:	00006517          	auipc	a0,0x6
    800034ac:	03050513          	addi	a0,a0,48 # 800094d8 <states.0+0xa8>
    800034b0:	ffffd097          	auipc	ra,0xffffd
    800034b4:	0c4080e7          	jalr	196(ra) # 80000574 <printf>
    p->killed = 1;
    800034b8:	4785                	li	a5,1
    800034ba:	d49c                	sw	a5,40(s1)
  if(p->killed)
    800034bc:	a011                	j	800034c0 <usertrap+0xf8>
    800034be:	4901                	li	s2,0
    exit(-1);
    800034c0:	557d                	li	a0,-1
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	a1c080e7          	jalr	-1508(ra) # 80002ede <exit>
  if(which_dev == 2)
    800034ca:	4789                	li	a5,2
    800034cc:	f4f91de3          	bne	s2,a5,80003426 <usertrap+0x5e>
    yield();
    800034d0:	fffff097          	auipc	ra,0xfffff
    800034d4:	776080e7          	jalr	1910(ra) # 80002c46 <yield>
    800034d8:	b7b9                	j	80003426 <usertrap+0x5e>

00000000800034da <kerneltrap>:
{
    800034da:	7179                	addi	sp,sp,-48
    800034dc:	f406                	sd	ra,40(sp)
    800034de:	f022                	sd	s0,32(sp)
    800034e0:	ec26                	sd	s1,24(sp)
    800034e2:	e84a                	sd	s2,16(sp)
    800034e4:	e44e                	sd	s3,8(sp)
    800034e6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800034e8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034ec:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800034f0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800034f4:	1004f793          	andi	a5,s1,256
    800034f8:	cb85                	beqz	a5,80003528 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800034fa:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800034fe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80003500:	ef85                	bnez	a5,80003538 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80003502:	00000097          	auipc	ra,0x0
    80003506:	e24080e7          	jalr	-476(ra) # 80003326 <devintr>
    8000350a:	cd1d                	beqz	a0,80003548 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000350c:	4789                	li	a5,2
    8000350e:	06f50a63          	beq	a0,a5,80003582 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80003512:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003516:	10049073          	csrw	sstatus,s1
}
    8000351a:	70a2                	ld	ra,40(sp)
    8000351c:	7402                	ld	s0,32(sp)
    8000351e:	64e2                	ld	s1,24(sp)
    80003520:	6942                	ld	s2,16(sp)
    80003522:	69a2                	ld	s3,8(sp)
    80003524:	6145                	addi	sp,sp,48
    80003526:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003528:	00006517          	auipc	a0,0x6
    8000352c:	fd050513          	addi	a0,a0,-48 # 800094f8 <states.0+0xc8>
    80003530:	ffffd097          	auipc	ra,0xffffd
    80003534:	ffa080e7          	jalr	-6(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80003538:	00006517          	auipc	a0,0x6
    8000353c:	fe850513          	addi	a0,a0,-24 # 80009520 <states.0+0xf0>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	fea080e7          	jalr	-22(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80003548:	85ce                	mv	a1,s3
    8000354a:	00006517          	auipc	a0,0x6
    8000354e:	ff650513          	addi	a0,a0,-10 # 80009540 <states.0+0x110>
    80003552:	ffffd097          	auipc	ra,0xffffd
    80003556:	022080e7          	jalr	34(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000355a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000355e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003562:	00006517          	auipc	a0,0x6
    80003566:	fee50513          	addi	a0,a0,-18 # 80009550 <states.0+0x120>
    8000356a:	ffffd097          	auipc	ra,0xffffd
    8000356e:	00a080e7          	jalr	10(ra) # 80000574 <printf>
    panic("kerneltrap");
    80003572:	00006517          	auipc	a0,0x6
    80003576:	ff650513          	addi	a0,a0,-10 # 80009568 <states.0+0x138>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fb0080e7          	jalr	-80(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003582:	fffff097          	auipc	ra,0xfffff
    80003586:	e58080e7          	jalr	-424(ra) # 800023da <myproc>
    8000358a:	d541                	beqz	a0,80003512 <kerneltrap+0x38>
    8000358c:	fffff097          	auipc	ra,0xfffff
    80003590:	e4e080e7          	jalr	-434(ra) # 800023da <myproc>
    80003594:	4d18                	lw	a4,24(a0)
    80003596:	4791                	li	a5,4
    80003598:	f6f71de3          	bne	a4,a5,80003512 <kerneltrap+0x38>
    yield();
    8000359c:	fffff097          	auipc	ra,0xfffff
    800035a0:	6aa080e7          	jalr	1706(ra) # 80002c46 <yield>
    800035a4:	b7bd                	j	80003512 <kerneltrap+0x38>

00000000800035a6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800035a6:	1101                	addi	sp,sp,-32
    800035a8:	ec06                	sd	ra,24(sp)
    800035aa:	e822                	sd	s0,16(sp)
    800035ac:	e426                	sd	s1,8(sp)
    800035ae:	1000                	addi	s0,sp,32
    800035b0:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800035b2:	fffff097          	auipc	ra,0xfffff
    800035b6:	e28080e7          	jalr	-472(ra) # 800023da <myproc>
  switch (n) {
    800035ba:	4795                	li	a5,5
    800035bc:	0497e163          	bltu	a5,s1,800035fe <argraw+0x58>
    800035c0:	048a                	slli	s1,s1,0x2
    800035c2:	00006717          	auipc	a4,0x6
    800035c6:	fde70713          	addi	a4,a4,-34 # 800095a0 <states.0+0x170>
    800035ca:	94ba                	add	s1,s1,a4
    800035cc:	409c                	lw	a5,0(s1)
    800035ce:	97ba                	add	a5,a5,a4
    800035d0:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800035d2:	6d3c                	ld	a5,88(a0)
    800035d4:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800035d6:	60e2                	ld	ra,24(sp)
    800035d8:	6442                	ld	s0,16(sp)
    800035da:	64a2                	ld	s1,8(sp)
    800035dc:	6105                	addi	sp,sp,32
    800035de:	8082                	ret
    return p->trapframe->a1;
    800035e0:	6d3c                	ld	a5,88(a0)
    800035e2:	7fa8                	ld	a0,120(a5)
    800035e4:	bfcd                	j	800035d6 <argraw+0x30>
    return p->trapframe->a2;
    800035e6:	6d3c                	ld	a5,88(a0)
    800035e8:	63c8                	ld	a0,128(a5)
    800035ea:	b7f5                	j	800035d6 <argraw+0x30>
    return p->trapframe->a3;
    800035ec:	6d3c                	ld	a5,88(a0)
    800035ee:	67c8                	ld	a0,136(a5)
    800035f0:	b7dd                	j	800035d6 <argraw+0x30>
    return p->trapframe->a4;
    800035f2:	6d3c                	ld	a5,88(a0)
    800035f4:	6bc8                	ld	a0,144(a5)
    800035f6:	b7c5                	j	800035d6 <argraw+0x30>
    return p->trapframe->a5;
    800035f8:	6d3c                	ld	a5,88(a0)
    800035fa:	6fc8                	ld	a0,152(a5)
    800035fc:	bfe9                	j	800035d6 <argraw+0x30>
  panic("argraw");
    800035fe:	00006517          	auipc	a0,0x6
    80003602:	f7a50513          	addi	a0,a0,-134 # 80009578 <states.0+0x148>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f24080e7          	jalr	-220(ra) # 8000052a <panic>

000000008000360e <fetchaddr>:
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	e04a                	sd	s2,0(sp)
    80003618:	1000                	addi	s0,sp,32
    8000361a:	84aa                	mv	s1,a0
    8000361c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000361e:	fffff097          	auipc	ra,0xfffff
    80003622:	dbc080e7          	jalr	-580(ra) # 800023da <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80003626:	653c                	ld	a5,72(a0)
    80003628:	02f4f863          	bgeu	s1,a5,80003658 <fetchaddr+0x4a>
    8000362c:	00848713          	addi	a4,s1,8
    80003630:	02e7e663          	bltu	a5,a4,8000365c <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003634:	46a1                	li	a3,8
    80003636:	8626                	mv	a2,s1
    80003638:	85ca                	mv	a1,s2
    8000363a:	6928                	ld	a0,80(a0)
    8000363c:	ffffe097          	auipc	ra,0xffffe
    80003640:	eda080e7          	jalr	-294(ra) # 80001516 <copyin>
    80003644:	00a03533          	snez	a0,a0
    80003648:	40a00533          	neg	a0,a0
}
    8000364c:	60e2                	ld	ra,24(sp)
    8000364e:	6442                	ld	s0,16(sp)
    80003650:	64a2                	ld	s1,8(sp)
    80003652:	6902                	ld	s2,0(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret
    return -1;
    80003658:	557d                	li	a0,-1
    8000365a:	bfcd                	j	8000364c <fetchaddr+0x3e>
    8000365c:	557d                	li	a0,-1
    8000365e:	b7fd                	j	8000364c <fetchaddr+0x3e>

0000000080003660 <fetchstr>:
{
    80003660:	7179                	addi	sp,sp,-48
    80003662:	f406                	sd	ra,40(sp)
    80003664:	f022                	sd	s0,32(sp)
    80003666:	ec26                	sd	s1,24(sp)
    80003668:	e84a                	sd	s2,16(sp)
    8000366a:	e44e                	sd	s3,8(sp)
    8000366c:	1800                	addi	s0,sp,48
    8000366e:	892a                	mv	s2,a0
    80003670:	84ae                	mv	s1,a1
    80003672:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003674:	fffff097          	auipc	ra,0xfffff
    80003678:	d66080e7          	jalr	-666(ra) # 800023da <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000367c:	86ce                	mv	a3,s3
    8000367e:	864a                	mv	a2,s2
    80003680:	85a6                	mv	a1,s1
    80003682:	6928                	ld	a0,80(a0)
    80003684:	ffffe097          	auipc	ra,0xffffe
    80003688:	f20080e7          	jalr	-224(ra) # 800015a4 <copyinstr>
  if(err < 0)
    8000368c:	00054763          	bltz	a0,8000369a <fetchstr+0x3a>
  return strlen(buf);
    80003690:	8526                	mv	a0,s1
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	7c0080e7          	jalr	1984(ra) # 80000e52 <strlen>
}
    8000369a:	70a2                	ld	ra,40(sp)
    8000369c:	7402                	ld	s0,32(sp)
    8000369e:	64e2                	ld	s1,24(sp)
    800036a0:	6942                	ld	s2,16(sp)
    800036a2:	69a2                	ld	s3,8(sp)
    800036a4:	6145                	addi	sp,sp,48
    800036a6:	8082                	ret

00000000800036a8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800036a8:	1101                	addi	sp,sp,-32
    800036aa:	ec06                	sd	ra,24(sp)
    800036ac:	e822                	sd	s0,16(sp)
    800036ae:	e426                	sd	s1,8(sp)
    800036b0:	1000                	addi	s0,sp,32
    800036b2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036b4:	00000097          	auipc	ra,0x0
    800036b8:	ef2080e7          	jalr	-270(ra) # 800035a6 <argraw>
    800036bc:	c088                	sw	a0,0(s1)
  return 0;
}
    800036be:	4501                	li	a0,0
    800036c0:	60e2                	ld	ra,24(sp)
    800036c2:	6442                	ld	s0,16(sp)
    800036c4:	64a2                	ld	s1,8(sp)
    800036c6:	6105                	addi	sp,sp,32
    800036c8:	8082                	ret

00000000800036ca <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	1000                	addi	s0,sp,32
    800036d4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	ed0080e7          	jalr	-304(ra) # 800035a6 <argraw>
    800036de:	e088                	sd	a0,0(s1)
  return 0;
}
    800036e0:	4501                	li	a0,0
    800036e2:	60e2                	ld	ra,24(sp)
    800036e4:	6442                	ld	s0,16(sp)
    800036e6:	64a2                	ld	s1,8(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret

00000000800036ec <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	e04a                	sd	s2,0(sp)
    800036f6:	1000                	addi	s0,sp,32
    800036f8:	84ae                	mv	s1,a1
    800036fa:	8932                	mv	s2,a2
  *ip = argraw(n);
    800036fc:	00000097          	auipc	ra,0x0
    80003700:	eaa080e7          	jalr	-342(ra) # 800035a6 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003704:	864a                	mv	a2,s2
    80003706:	85a6                	mv	a1,s1
    80003708:	00000097          	auipc	ra,0x0
    8000370c:	f58080e7          	jalr	-168(ra) # 80003660 <fetchstr>
}
    80003710:	60e2                	ld	ra,24(sp)
    80003712:	6442                	ld	s0,16(sp)
    80003714:	64a2                	ld	s1,8(sp)
    80003716:	6902                	ld	s2,0(sp)
    80003718:	6105                	addi	sp,sp,32
    8000371a:	8082                	ret

000000008000371c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    8000371c:	1101                	addi	sp,sp,-32
    8000371e:	ec06                	sd	ra,24(sp)
    80003720:	e822                	sd	s0,16(sp)
    80003722:	e426                	sd	s1,8(sp)
    80003724:	e04a                	sd	s2,0(sp)
    80003726:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003728:	fffff097          	auipc	ra,0xfffff
    8000372c:	cb2080e7          	jalr	-846(ra) # 800023da <myproc>
    80003730:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80003732:	05853903          	ld	s2,88(a0)
    80003736:	0a893783          	ld	a5,168(s2)
    8000373a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000373e:	37fd                	addiw	a5,a5,-1
    80003740:	4751                	li	a4,20
    80003742:	00f76f63          	bltu	a4,a5,80003760 <syscall+0x44>
    80003746:	00369713          	slli	a4,a3,0x3
    8000374a:	00006797          	auipc	a5,0x6
    8000374e:	e6e78793          	addi	a5,a5,-402 # 800095b8 <syscalls>
    80003752:	97ba                	add	a5,a5,a4
    80003754:	639c                	ld	a5,0(a5)
    80003756:	c789                	beqz	a5,80003760 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003758:	9782                	jalr	a5
    8000375a:	06a93823          	sd	a0,112(s2)
    8000375e:	a839                	j	8000377c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003760:	15848613          	addi	a2,s1,344
    80003764:	588c                	lw	a1,48(s1)
    80003766:	00006517          	auipc	a0,0x6
    8000376a:	e1a50513          	addi	a0,a0,-486 # 80009580 <states.0+0x150>
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	e06080e7          	jalr	-506(ra) # 80000574 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003776:	6cbc                	ld	a5,88(s1)
    80003778:	577d                	li	a4,-1
    8000377a:	fbb8                	sd	a4,112(a5)
  }
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6902                	ld	s2,0(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret

0000000080003788 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003790:	fec40593          	addi	a1,s0,-20
    80003794:	4501                	li	a0,0
    80003796:	00000097          	auipc	ra,0x0
    8000379a:	f12080e7          	jalr	-238(ra) # 800036a8 <argint>
    return -1;
    8000379e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800037a0:	00054963          	bltz	a0,800037b2 <sys_exit+0x2a>
  exit(n);
    800037a4:	fec42503          	lw	a0,-20(s0)
    800037a8:	fffff097          	auipc	ra,0xfffff
    800037ac:	736080e7          	jalr	1846(ra) # 80002ede <exit>
  return 0;  // not reached
    800037b0:	4781                	li	a5,0
}
    800037b2:	853e                	mv	a0,a5
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret

00000000800037bc <sys_getpid>:

uint64
sys_getpid(void)
{
    800037bc:	1141                	addi	sp,sp,-16
    800037be:	e406                	sd	ra,8(sp)
    800037c0:	e022                	sd	s0,0(sp)
    800037c2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800037c4:	fffff097          	auipc	ra,0xfffff
    800037c8:	c16080e7          	jalr	-1002(ra) # 800023da <myproc>
}
    800037cc:	5908                	lw	a0,48(a0)
    800037ce:	60a2                	ld	ra,8(sp)
    800037d0:	6402                	ld	s0,0(sp)
    800037d2:	0141                	addi	sp,sp,16
    800037d4:	8082                	ret

00000000800037d6 <sys_fork>:

uint64
sys_fork(void)
{
    800037d6:	1141                	addi	sp,sp,-16
    800037d8:	e406                	sd	ra,8(sp)
    800037da:	e022                	sd	s0,0(sp)
    800037dc:	0800                	addi	s0,sp,16
  return fork();
    800037de:	fffff097          	auipc	ra,0xfffff
    800037e2:	0b0080e7          	jalr	176(ra) # 8000288e <fork>
}
    800037e6:	60a2                	ld	ra,8(sp)
    800037e8:	6402                	ld	s0,0(sp)
    800037ea:	0141                	addi	sp,sp,16
    800037ec:	8082                	ret

00000000800037ee <sys_wait>:

uint64
sys_wait(void)
{
    800037ee:	1101                	addi	sp,sp,-32
    800037f0:	ec06                	sd	ra,24(sp)
    800037f2:	e822                	sd	s0,16(sp)
    800037f4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800037f6:	fe840593          	addi	a1,s0,-24
    800037fa:	4501                	li	a0,0
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	ece080e7          	jalr	-306(ra) # 800036ca <argaddr>
    80003804:	87aa                	mv	a5,a0
    return -1;
    80003806:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003808:	0007c863          	bltz	a5,80003818 <sys_wait+0x2a>
  return wait(p);
    8000380c:	fe843503          	ld	a0,-24(s0)
    80003810:	fffff097          	auipc	ra,0xfffff
    80003814:	4d6080e7          	jalr	1238(ra) # 80002ce6 <wait>
}
    80003818:	60e2                	ld	ra,24(sp)
    8000381a:	6442                	ld	s0,16(sp)
    8000381c:	6105                	addi	sp,sp,32
    8000381e:	8082                	ret

0000000080003820 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003820:	7179                	addi	sp,sp,-48
    80003822:	f406                	sd	ra,40(sp)
    80003824:	f022                	sd	s0,32(sp)
    80003826:	ec26                	sd	s1,24(sp)
    80003828:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000382a:	fdc40593          	addi	a1,s0,-36
    8000382e:	4501                	li	a0,0
    80003830:	00000097          	auipc	ra,0x0
    80003834:	e78080e7          	jalr	-392(ra) # 800036a8 <argint>
    return -1;
    80003838:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000383a:	00054f63          	bltz	a0,80003858 <sys_sbrk+0x38>
  addr = myproc()->sz;
    8000383e:	fffff097          	auipc	ra,0xfffff
    80003842:	b9c080e7          	jalr	-1124(ra) # 800023da <myproc>
    80003846:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003848:	fdc42503          	lw	a0,-36(s0)
    8000384c:	fffff097          	auipc	ra,0xfffff
    80003850:	f24080e7          	jalr	-220(ra) # 80002770 <growproc>
    80003854:	00054863          	bltz	a0,80003864 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80003858:	8526                	mv	a0,s1
    8000385a:	70a2                	ld	ra,40(sp)
    8000385c:	7402                	ld	s0,32(sp)
    8000385e:	64e2                	ld	s1,24(sp)
    80003860:	6145                	addi	sp,sp,48
    80003862:	8082                	ret
    return -1;
    80003864:	54fd                	li	s1,-1
    80003866:	bfcd                	j	80003858 <sys_sbrk+0x38>

0000000080003868 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003868:	7139                	addi	sp,sp,-64
    8000386a:	fc06                	sd	ra,56(sp)
    8000386c:	f822                	sd	s0,48(sp)
    8000386e:	f426                	sd	s1,40(sp)
    80003870:	f04a                	sd	s2,32(sp)
    80003872:	ec4e                	sd	s3,24(sp)
    80003874:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003876:	fcc40593          	addi	a1,s0,-52
    8000387a:	4501                	li	a0,0
    8000387c:	00000097          	auipc	ra,0x0
    80003880:	e2c080e7          	jalr	-468(ra) # 800036a8 <argint>
    return -1;
    80003884:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003886:	06054563          	bltz	a0,800038f0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000388a:	0001d517          	auipc	a0,0x1d
    8000388e:	e4650513          	addi	a0,a0,-442 # 800206d0 <tickslock>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	340080e7          	jalr	832(ra) # 80000bd2 <acquire>
  ticks0 = ticks;
    8000389a:	00006917          	auipc	s2,0x6
    8000389e:	79692903          	lw	s2,1942(s2) # 8000a030 <ticks>
  while(ticks - ticks0 < n){
    800038a2:	fcc42783          	lw	a5,-52(s0)
    800038a6:	cf85                	beqz	a5,800038de <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800038a8:	0001d997          	auipc	s3,0x1d
    800038ac:	e2898993          	addi	s3,s3,-472 # 800206d0 <tickslock>
    800038b0:	00006497          	auipc	s1,0x6
    800038b4:	78048493          	addi	s1,s1,1920 # 8000a030 <ticks>
    if(myproc()->killed){
    800038b8:	fffff097          	auipc	ra,0xfffff
    800038bc:	b22080e7          	jalr	-1246(ra) # 800023da <myproc>
    800038c0:	551c                	lw	a5,40(a0)
    800038c2:	ef9d                	bnez	a5,80003900 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800038c4:	85ce                	mv	a1,s3
    800038c6:	8526                	mv	a0,s1
    800038c8:	fffff097          	auipc	ra,0xfffff
    800038cc:	3ba080e7          	jalr	954(ra) # 80002c82 <sleep>
  while(ticks - ticks0 < n){
    800038d0:	409c                	lw	a5,0(s1)
    800038d2:	412787bb          	subw	a5,a5,s2
    800038d6:	fcc42703          	lw	a4,-52(s0)
    800038da:	fce7efe3          	bltu	a5,a4,800038b8 <sys_sleep+0x50>
  }
  release(&tickslock);
    800038de:	0001d517          	auipc	a0,0x1d
    800038e2:	df250513          	addi	a0,a0,-526 # 800206d0 <tickslock>
    800038e6:	ffffd097          	auipc	ra,0xffffd
    800038ea:	3a0080e7          	jalr	928(ra) # 80000c86 <release>
  return 0;
    800038ee:	4781                	li	a5,0
}
    800038f0:	853e                	mv	a0,a5
    800038f2:	70e2                	ld	ra,56(sp)
    800038f4:	7442                	ld	s0,48(sp)
    800038f6:	74a2                	ld	s1,40(sp)
    800038f8:	7902                	ld	s2,32(sp)
    800038fa:	69e2                	ld	s3,24(sp)
    800038fc:	6121                	addi	sp,sp,64
    800038fe:	8082                	ret
      release(&tickslock);
    80003900:	0001d517          	auipc	a0,0x1d
    80003904:	dd050513          	addi	a0,a0,-560 # 800206d0 <tickslock>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	37e080e7          	jalr	894(ra) # 80000c86 <release>
      return -1;
    80003910:	57fd                	li	a5,-1
    80003912:	bff9                	j	800038f0 <sys_sleep+0x88>

0000000080003914 <sys_kill>:

uint64
sys_kill(void)
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000391c:	fec40593          	addi	a1,s0,-20
    80003920:	4501                	li	a0,0
    80003922:	00000097          	auipc	ra,0x0
    80003926:	d86080e7          	jalr	-634(ra) # 800036a8 <argint>
    8000392a:	87aa                	mv	a5,a0
    return -1;
    8000392c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000392e:	0007c863          	bltz	a5,8000393e <sys_kill+0x2a>
  return kill(pid);
    80003932:	fec42503          	lw	a0,-20(s0)
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	694080e7          	jalr	1684(ra) # 80002fca <kill>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	6105                	addi	sp,sp,32
    80003944:	8082                	ret

0000000080003946 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003946:	1101                	addi	sp,sp,-32
    80003948:	ec06                	sd	ra,24(sp)
    8000394a:	e822                	sd	s0,16(sp)
    8000394c:	e426                	sd	s1,8(sp)
    8000394e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003950:	0001d517          	auipc	a0,0x1d
    80003954:	d8050513          	addi	a0,a0,-640 # 800206d0 <tickslock>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	27a080e7          	jalr	634(ra) # 80000bd2 <acquire>
  xticks = ticks;
    80003960:	00006497          	auipc	s1,0x6
    80003964:	6d04a483          	lw	s1,1744(s1) # 8000a030 <ticks>
  release(&tickslock);
    80003968:	0001d517          	auipc	a0,0x1d
    8000396c:	d6850513          	addi	a0,a0,-664 # 800206d0 <tickslock>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	316080e7          	jalr	790(ra) # 80000c86 <release>
  return xticks;
}
    80003978:	02049513          	slli	a0,s1,0x20
    8000397c:	9101                	srli	a0,a0,0x20
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003988:	7179                	addi	sp,sp,-48
    8000398a:	f406                	sd	ra,40(sp)
    8000398c:	f022                	sd	s0,32(sp)
    8000398e:	ec26                	sd	s1,24(sp)
    80003990:	e84a                	sd	s2,16(sp)
    80003992:	e44e                	sd	s3,8(sp)
    80003994:	e052                	sd	s4,0(sp)
    80003996:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003998:	00006597          	auipc	a1,0x6
    8000399c:	cd058593          	addi	a1,a1,-816 # 80009668 <syscalls+0xb0>
    800039a0:	0001d517          	auipc	a0,0x1d
    800039a4:	d4850513          	addi	a0,a0,-696 # 800206e8 <bcache>
    800039a8:	ffffd097          	auipc	ra,0xffffd
    800039ac:	19a080e7          	jalr	410(ra) # 80000b42 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800039b0:	00025797          	auipc	a5,0x25
    800039b4:	d3878793          	addi	a5,a5,-712 # 800286e8 <bcache+0x8000>
    800039b8:	00025717          	auipc	a4,0x25
    800039bc:	f9870713          	addi	a4,a4,-104 # 80028950 <bcache+0x8268>
    800039c0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800039c4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800039c8:	0001d497          	auipc	s1,0x1d
    800039cc:	d3848493          	addi	s1,s1,-712 # 80020700 <bcache+0x18>
    b->next = bcache.head.next;
    800039d0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800039d2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800039d4:	00006a17          	auipc	s4,0x6
    800039d8:	c9ca0a13          	addi	s4,s4,-868 # 80009670 <syscalls+0xb8>
    b->next = bcache.head.next;
    800039dc:	2b893783          	ld	a5,696(s2)
    800039e0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800039e2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800039e6:	85d2                	mv	a1,s4
    800039e8:	01048513          	addi	a0,s1,16
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	7f2080e7          	jalr	2034(ra) # 800051de <initsleeplock>
    bcache.head.next->prev = b;
    800039f4:	2b893783          	ld	a5,696(s2)
    800039f8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800039fa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800039fe:	45848493          	addi	s1,s1,1112
    80003a02:	fd349de3          	bne	s1,s3,800039dc <binit+0x54>
  }
}
    80003a06:	70a2                	ld	ra,40(sp)
    80003a08:	7402                	ld	s0,32(sp)
    80003a0a:	64e2                	ld	s1,24(sp)
    80003a0c:	6942                	ld	s2,16(sp)
    80003a0e:	69a2                	ld	s3,8(sp)
    80003a10:	6a02                	ld	s4,0(sp)
    80003a12:	6145                	addi	sp,sp,48
    80003a14:	8082                	ret

0000000080003a16 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003a16:	7179                	addi	sp,sp,-48
    80003a18:	f406                	sd	ra,40(sp)
    80003a1a:	f022                	sd	s0,32(sp)
    80003a1c:	ec26                	sd	s1,24(sp)
    80003a1e:	e84a                	sd	s2,16(sp)
    80003a20:	e44e                	sd	s3,8(sp)
    80003a22:	1800                	addi	s0,sp,48
    80003a24:	892a                	mv	s2,a0
    80003a26:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003a28:	0001d517          	auipc	a0,0x1d
    80003a2c:	cc050513          	addi	a0,a0,-832 # 800206e8 <bcache>
    80003a30:	ffffd097          	auipc	ra,0xffffd
    80003a34:	1a2080e7          	jalr	418(ra) # 80000bd2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003a38:	00025497          	auipc	s1,0x25
    80003a3c:	f684b483          	ld	s1,-152(s1) # 800289a0 <bcache+0x82b8>
    80003a40:	00025797          	auipc	a5,0x25
    80003a44:	f1078793          	addi	a5,a5,-240 # 80028950 <bcache+0x8268>
    80003a48:	02f48f63          	beq	s1,a5,80003a86 <bread+0x70>
    80003a4c:	873e                	mv	a4,a5
    80003a4e:	a021                	j	80003a56 <bread+0x40>
    80003a50:	68a4                	ld	s1,80(s1)
    80003a52:	02e48a63          	beq	s1,a4,80003a86 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003a56:	449c                	lw	a5,8(s1)
    80003a58:	ff279ce3          	bne	a5,s2,80003a50 <bread+0x3a>
    80003a5c:	44dc                	lw	a5,12(s1)
    80003a5e:	ff3799e3          	bne	a5,s3,80003a50 <bread+0x3a>
      b->refcnt++;
    80003a62:	40bc                	lw	a5,64(s1)
    80003a64:	2785                	addiw	a5,a5,1
    80003a66:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003a68:	0001d517          	auipc	a0,0x1d
    80003a6c:	c8050513          	addi	a0,a0,-896 # 800206e8 <bcache>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	216080e7          	jalr	534(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003a78:	01048513          	addi	a0,s1,16
    80003a7c:	00001097          	auipc	ra,0x1
    80003a80:	79c080e7          	jalr	1948(ra) # 80005218 <acquiresleep>
      return b;
    80003a84:	a8b9                	j	80003ae2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003a86:	00025497          	auipc	s1,0x25
    80003a8a:	f124b483          	ld	s1,-238(s1) # 80028998 <bcache+0x82b0>
    80003a8e:	00025797          	auipc	a5,0x25
    80003a92:	ec278793          	addi	a5,a5,-318 # 80028950 <bcache+0x8268>
    80003a96:	00f48863          	beq	s1,a5,80003aa6 <bread+0x90>
    80003a9a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003a9c:	40bc                	lw	a5,64(s1)
    80003a9e:	cf81                	beqz	a5,80003ab6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003aa0:	64a4                	ld	s1,72(s1)
    80003aa2:	fee49de3          	bne	s1,a4,80003a9c <bread+0x86>
  panic("bget: no buffers");
    80003aa6:	00006517          	auipc	a0,0x6
    80003aaa:	bd250513          	addi	a0,a0,-1070 # 80009678 <syscalls+0xc0>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a7c080e7          	jalr	-1412(ra) # 8000052a <panic>
      b->dev = dev;
    80003ab6:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003aba:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003abe:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003ac2:	4785                	li	a5,1
    80003ac4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003ac6:	0001d517          	auipc	a0,0x1d
    80003aca:	c2250513          	addi	a0,a0,-990 # 800206e8 <bcache>
    80003ace:	ffffd097          	auipc	ra,0xffffd
    80003ad2:	1b8080e7          	jalr	440(ra) # 80000c86 <release>
      acquiresleep(&b->lock);
    80003ad6:	01048513          	addi	a0,s1,16
    80003ada:	00001097          	auipc	ra,0x1
    80003ade:	73e080e7          	jalr	1854(ra) # 80005218 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003ae2:	409c                	lw	a5,0(s1)
    80003ae4:	cb89                	beqz	a5,80003af6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003ae6:	8526                	mv	a0,s1
    80003ae8:	70a2                	ld	ra,40(sp)
    80003aea:	7402                	ld	s0,32(sp)
    80003aec:	64e2                	ld	s1,24(sp)
    80003aee:	6942                	ld	s2,16(sp)
    80003af0:	69a2                	ld	s3,8(sp)
    80003af2:	6145                	addi	sp,sp,48
    80003af4:	8082                	ret
    virtio_disk_rw(b, 0);
    80003af6:	4581                	li	a1,0
    80003af8:	8526                	mv	a0,s1
    80003afa:	00003097          	auipc	ra,0x3
    80003afe:	47c080e7          	jalr	1148(ra) # 80006f76 <virtio_disk_rw>
    b->valid = 1;
    80003b02:	4785                	li	a5,1
    80003b04:	c09c                	sw	a5,0(s1)
  return b;
    80003b06:	b7c5                	j	80003ae6 <bread+0xd0>

0000000080003b08 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003b08:	1101                	addi	sp,sp,-32
    80003b0a:	ec06                	sd	ra,24(sp)
    80003b0c:	e822                	sd	s0,16(sp)
    80003b0e:	e426                	sd	s1,8(sp)
    80003b10:	1000                	addi	s0,sp,32
    80003b12:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b14:	0541                	addi	a0,a0,16
    80003b16:	00001097          	auipc	ra,0x1
    80003b1a:	79c080e7          	jalr	1948(ra) # 800052b2 <holdingsleep>
    80003b1e:	cd01                	beqz	a0,80003b36 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003b20:	4585                	li	a1,1
    80003b22:	8526                	mv	a0,s1
    80003b24:	00003097          	auipc	ra,0x3
    80003b28:	452080e7          	jalr	1106(ra) # 80006f76 <virtio_disk_rw>
}
    80003b2c:	60e2                	ld	ra,24(sp)
    80003b2e:	6442                	ld	s0,16(sp)
    80003b30:	64a2                	ld	s1,8(sp)
    80003b32:	6105                	addi	sp,sp,32
    80003b34:	8082                	ret
    panic("bwrite");
    80003b36:	00006517          	auipc	a0,0x6
    80003b3a:	b5a50513          	addi	a0,a0,-1190 # 80009690 <syscalls+0xd8>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	9ec080e7          	jalr	-1556(ra) # 8000052a <panic>

0000000080003b46 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003b46:	1101                	addi	sp,sp,-32
    80003b48:	ec06                	sd	ra,24(sp)
    80003b4a:	e822                	sd	s0,16(sp)
    80003b4c:	e426                	sd	s1,8(sp)
    80003b4e:	e04a                	sd	s2,0(sp)
    80003b50:	1000                	addi	s0,sp,32
    80003b52:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003b54:	01050913          	addi	s2,a0,16
    80003b58:	854a                	mv	a0,s2
    80003b5a:	00001097          	auipc	ra,0x1
    80003b5e:	758080e7          	jalr	1880(ra) # 800052b2 <holdingsleep>
    80003b62:	c92d                	beqz	a0,80003bd4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	708080e7          	jalr	1800(ra) # 8000526e <releasesleep>

  acquire(&bcache.lock);
    80003b6e:	0001d517          	auipc	a0,0x1d
    80003b72:	b7a50513          	addi	a0,a0,-1158 # 800206e8 <bcache>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	05c080e7          	jalr	92(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003b7e:	40bc                	lw	a5,64(s1)
    80003b80:	37fd                	addiw	a5,a5,-1
    80003b82:	0007871b          	sext.w	a4,a5
    80003b86:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003b88:	eb05                	bnez	a4,80003bb8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003b8a:	68bc                	ld	a5,80(s1)
    80003b8c:	64b8                	ld	a4,72(s1)
    80003b8e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003b90:	64bc                	ld	a5,72(s1)
    80003b92:	68b8                	ld	a4,80(s1)
    80003b94:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003b96:	00025797          	auipc	a5,0x25
    80003b9a:	b5278793          	addi	a5,a5,-1198 # 800286e8 <bcache+0x8000>
    80003b9e:	2b87b703          	ld	a4,696(a5)
    80003ba2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003ba4:	00025717          	auipc	a4,0x25
    80003ba8:	dac70713          	addi	a4,a4,-596 # 80028950 <bcache+0x8268>
    80003bac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003bae:	2b87b703          	ld	a4,696(a5)
    80003bb2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003bb4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003bb8:	0001d517          	auipc	a0,0x1d
    80003bbc:	b3050513          	addi	a0,a0,-1232 # 800206e8 <bcache>
    80003bc0:	ffffd097          	auipc	ra,0xffffd
    80003bc4:	0c6080e7          	jalr	198(ra) # 80000c86 <release>
}
    80003bc8:	60e2                	ld	ra,24(sp)
    80003bca:	6442                	ld	s0,16(sp)
    80003bcc:	64a2                	ld	s1,8(sp)
    80003bce:	6902                	ld	s2,0(sp)
    80003bd0:	6105                	addi	sp,sp,32
    80003bd2:	8082                	ret
    panic("brelse");
    80003bd4:	00006517          	auipc	a0,0x6
    80003bd8:	ac450513          	addi	a0,a0,-1340 # 80009698 <syscalls+0xe0>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	94e080e7          	jalr	-1714(ra) # 8000052a <panic>

0000000080003be4 <bpin>:

void
bpin(struct buf *b) {
    80003be4:	1101                	addi	sp,sp,-32
    80003be6:	ec06                	sd	ra,24(sp)
    80003be8:	e822                	sd	s0,16(sp)
    80003bea:	e426                	sd	s1,8(sp)
    80003bec:	1000                	addi	s0,sp,32
    80003bee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003bf0:	0001d517          	auipc	a0,0x1d
    80003bf4:	af850513          	addi	a0,a0,-1288 # 800206e8 <bcache>
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	fda080e7          	jalr	-38(ra) # 80000bd2 <acquire>
  b->refcnt++;
    80003c00:	40bc                	lw	a5,64(s1)
    80003c02:	2785                	addiw	a5,a5,1
    80003c04:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c06:	0001d517          	auipc	a0,0x1d
    80003c0a:	ae250513          	addi	a0,a0,-1310 # 800206e8 <bcache>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	078080e7          	jalr	120(ra) # 80000c86 <release>
}
    80003c16:	60e2                	ld	ra,24(sp)
    80003c18:	6442                	ld	s0,16(sp)
    80003c1a:	64a2                	ld	s1,8(sp)
    80003c1c:	6105                	addi	sp,sp,32
    80003c1e:	8082                	ret

0000000080003c20 <bunpin>:

void
bunpin(struct buf *b) {
    80003c20:	1101                	addi	sp,sp,-32
    80003c22:	ec06                	sd	ra,24(sp)
    80003c24:	e822                	sd	s0,16(sp)
    80003c26:	e426                	sd	s1,8(sp)
    80003c28:	1000                	addi	s0,sp,32
    80003c2a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003c2c:	0001d517          	auipc	a0,0x1d
    80003c30:	abc50513          	addi	a0,a0,-1348 # 800206e8 <bcache>
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	f9e080e7          	jalr	-98(ra) # 80000bd2 <acquire>
  b->refcnt--;
    80003c3c:	40bc                	lw	a5,64(s1)
    80003c3e:	37fd                	addiw	a5,a5,-1
    80003c40:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003c42:	0001d517          	auipc	a0,0x1d
    80003c46:	aa650513          	addi	a0,a0,-1370 # 800206e8 <bcache>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	03c080e7          	jalr	60(ra) # 80000c86 <release>
}
    80003c52:	60e2                	ld	ra,24(sp)
    80003c54:	6442                	ld	s0,16(sp)
    80003c56:	64a2                	ld	s1,8(sp)
    80003c58:	6105                	addi	sp,sp,32
    80003c5a:	8082                	ret

0000000080003c5c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003c5c:	1101                	addi	sp,sp,-32
    80003c5e:	ec06                	sd	ra,24(sp)
    80003c60:	e822                	sd	s0,16(sp)
    80003c62:	e426                	sd	s1,8(sp)
    80003c64:	e04a                	sd	s2,0(sp)
    80003c66:	1000                	addi	s0,sp,32
    80003c68:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003c6a:	00d5d59b          	srliw	a1,a1,0xd
    80003c6e:	00025797          	auipc	a5,0x25
    80003c72:	1567a783          	lw	a5,342(a5) # 80028dc4 <sb+0x1c>
    80003c76:	9dbd                	addw	a1,a1,a5
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	d9e080e7          	jalr	-610(ra) # 80003a16 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003c80:	0074f713          	andi	a4,s1,7
    80003c84:	4785                	li	a5,1
    80003c86:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003c8a:	14ce                	slli	s1,s1,0x33
    80003c8c:	90d9                	srli	s1,s1,0x36
    80003c8e:	00950733          	add	a4,a0,s1
    80003c92:	05874703          	lbu	a4,88(a4)
    80003c96:	00e7f6b3          	and	a3,a5,a4
    80003c9a:	c69d                	beqz	a3,80003cc8 <bfree+0x6c>
    80003c9c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003c9e:	94aa                	add	s1,s1,a0
    80003ca0:	fff7c793          	not	a5,a5
    80003ca4:	8ff9                	and	a5,a5,a4
    80003ca6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003caa:	00001097          	auipc	ra,0x1
    80003cae:	44e080e7          	jalr	1102(ra) # 800050f8 <log_write>
  brelse(bp);
    80003cb2:	854a                	mv	a0,s2
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	e92080e7          	jalr	-366(ra) # 80003b46 <brelse>
}
    80003cbc:	60e2                	ld	ra,24(sp)
    80003cbe:	6442                	ld	s0,16(sp)
    80003cc0:	64a2                	ld	s1,8(sp)
    80003cc2:	6902                	ld	s2,0(sp)
    80003cc4:	6105                	addi	sp,sp,32
    80003cc6:	8082                	ret
    panic("freeing free block");
    80003cc8:	00006517          	auipc	a0,0x6
    80003ccc:	9d850513          	addi	a0,a0,-1576 # 800096a0 <syscalls+0xe8>
    80003cd0:	ffffd097          	auipc	ra,0xffffd
    80003cd4:	85a080e7          	jalr	-1958(ra) # 8000052a <panic>

0000000080003cd8 <balloc>:
{
    80003cd8:	711d                	addi	sp,sp,-96
    80003cda:	ec86                	sd	ra,88(sp)
    80003cdc:	e8a2                	sd	s0,80(sp)
    80003cde:	e4a6                	sd	s1,72(sp)
    80003ce0:	e0ca                	sd	s2,64(sp)
    80003ce2:	fc4e                	sd	s3,56(sp)
    80003ce4:	f852                	sd	s4,48(sp)
    80003ce6:	f456                	sd	s5,40(sp)
    80003ce8:	f05a                	sd	s6,32(sp)
    80003cea:	ec5e                	sd	s7,24(sp)
    80003cec:	e862                	sd	s8,16(sp)
    80003cee:	e466                	sd	s9,8(sp)
    80003cf0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003cf2:	00025797          	auipc	a5,0x25
    80003cf6:	0ba7a783          	lw	a5,186(a5) # 80028dac <sb+0x4>
    80003cfa:	cbd1                	beqz	a5,80003d8e <balloc+0xb6>
    80003cfc:	8baa                	mv	s7,a0
    80003cfe:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003d00:	00025b17          	auipc	s6,0x25
    80003d04:	0a8b0b13          	addi	s6,s6,168 # 80028da8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d08:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003d0a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d0c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003d0e:	6c89                	lui	s9,0x2
    80003d10:	a831                	j	80003d2c <balloc+0x54>
    brelse(bp);
    80003d12:	854a                	mv	a0,s2
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	e32080e7          	jalr	-462(ra) # 80003b46 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003d1c:	015c87bb          	addw	a5,s9,s5
    80003d20:	00078a9b          	sext.w	s5,a5
    80003d24:	004b2703          	lw	a4,4(s6)
    80003d28:	06eaf363          	bgeu	s5,a4,80003d8e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003d2c:	41fad79b          	sraiw	a5,s5,0x1f
    80003d30:	0137d79b          	srliw	a5,a5,0x13
    80003d34:	015787bb          	addw	a5,a5,s5
    80003d38:	40d7d79b          	sraiw	a5,a5,0xd
    80003d3c:	01cb2583          	lw	a1,28(s6)
    80003d40:	9dbd                	addw	a1,a1,a5
    80003d42:	855e                	mv	a0,s7
    80003d44:	00000097          	auipc	ra,0x0
    80003d48:	cd2080e7          	jalr	-814(ra) # 80003a16 <bread>
    80003d4c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d4e:	004b2503          	lw	a0,4(s6)
    80003d52:	000a849b          	sext.w	s1,s5
    80003d56:	8662                	mv	a2,s8
    80003d58:	faa4fde3          	bgeu	s1,a0,80003d12 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003d5c:	41f6579b          	sraiw	a5,a2,0x1f
    80003d60:	01d7d69b          	srliw	a3,a5,0x1d
    80003d64:	00c6873b          	addw	a4,a3,a2
    80003d68:	00777793          	andi	a5,a4,7
    80003d6c:	9f95                	subw	a5,a5,a3
    80003d6e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003d72:	4037571b          	sraiw	a4,a4,0x3
    80003d76:	00e906b3          	add	a3,s2,a4
    80003d7a:	0586c683          	lbu	a3,88(a3)
    80003d7e:	00d7f5b3          	and	a1,a5,a3
    80003d82:	cd91                	beqz	a1,80003d9e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003d84:	2605                	addiw	a2,a2,1
    80003d86:	2485                	addiw	s1,s1,1
    80003d88:	fd4618e3          	bne	a2,s4,80003d58 <balloc+0x80>
    80003d8c:	b759                	j	80003d12 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003d8e:	00006517          	auipc	a0,0x6
    80003d92:	92a50513          	addi	a0,a0,-1750 # 800096b8 <syscalls+0x100>
    80003d96:	ffffc097          	auipc	ra,0xffffc
    80003d9a:	794080e7          	jalr	1940(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003d9e:	974a                	add	a4,a4,s2
    80003da0:	8fd5                	or	a5,a5,a3
    80003da2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003da6:	854a                	mv	a0,s2
    80003da8:	00001097          	auipc	ra,0x1
    80003dac:	350080e7          	jalr	848(ra) # 800050f8 <log_write>
        brelse(bp);
    80003db0:	854a                	mv	a0,s2
    80003db2:	00000097          	auipc	ra,0x0
    80003db6:	d94080e7          	jalr	-620(ra) # 80003b46 <brelse>
  bp = bread(dev, bno);
    80003dba:	85a6                	mv	a1,s1
    80003dbc:	855e                	mv	a0,s7
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	c58080e7          	jalr	-936(ra) # 80003a16 <bread>
    80003dc6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003dc8:	40000613          	li	a2,1024
    80003dcc:	4581                	li	a1,0
    80003dce:	05850513          	addi	a0,a0,88
    80003dd2:	ffffd097          	auipc	ra,0xffffd
    80003dd6:	efc080e7          	jalr	-260(ra) # 80000cce <memset>
  log_write(bp);
    80003dda:	854a                	mv	a0,s2
    80003ddc:	00001097          	auipc	ra,0x1
    80003de0:	31c080e7          	jalr	796(ra) # 800050f8 <log_write>
  brelse(bp);
    80003de4:	854a                	mv	a0,s2
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	d60080e7          	jalr	-672(ra) # 80003b46 <brelse>
}
    80003dee:	8526                	mv	a0,s1
    80003df0:	60e6                	ld	ra,88(sp)
    80003df2:	6446                	ld	s0,80(sp)
    80003df4:	64a6                	ld	s1,72(sp)
    80003df6:	6906                	ld	s2,64(sp)
    80003df8:	79e2                	ld	s3,56(sp)
    80003dfa:	7a42                	ld	s4,48(sp)
    80003dfc:	7aa2                	ld	s5,40(sp)
    80003dfe:	7b02                	ld	s6,32(sp)
    80003e00:	6be2                	ld	s7,24(sp)
    80003e02:	6c42                	ld	s8,16(sp)
    80003e04:	6ca2                	ld	s9,8(sp)
    80003e06:	6125                	addi	sp,sp,96
    80003e08:	8082                	ret

0000000080003e0a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003e0a:	7179                	addi	sp,sp,-48
    80003e0c:	f406                	sd	ra,40(sp)
    80003e0e:	f022                	sd	s0,32(sp)
    80003e10:	ec26                	sd	s1,24(sp)
    80003e12:	e84a                	sd	s2,16(sp)
    80003e14:	e44e                	sd	s3,8(sp)
    80003e16:	e052                	sd	s4,0(sp)
    80003e18:	1800                	addi	s0,sp,48
    80003e1a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003e1c:	47ad                	li	a5,11
    80003e1e:	04b7fe63          	bgeu	a5,a1,80003e7a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003e22:	ff45849b          	addiw	s1,a1,-12
    80003e26:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003e2a:	0ff00793          	li	a5,255
    80003e2e:	0ae7e463          	bltu	a5,a4,80003ed6 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003e32:	08052583          	lw	a1,128(a0)
    80003e36:	c5b5                	beqz	a1,80003ea2 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003e38:	00092503          	lw	a0,0(s2)
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	bda080e7          	jalr	-1062(ra) # 80003a16 <bread>
    80003e44:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003e46:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003e4a:	02049713          	slli	a4,s1,0x20
    80003e4e:	01e75593          	srli	a1,a4,0x1e
    80003e52:	00b784b3          	add	s1,a5,a1
    80003e56:	0004a983          	lw	s3,0(s1)
    80003e5a:	04098e63          	beqz	s3,80003eb6 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003e5e:	8552                	mv	a0,s4
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	ce6080e7          	jalr	-794(ra) # 80003b46 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003e68:	854e                	mv	a0,s3
    80003e6a:	70a2                	ld	ra,40(sp)
    80003e6c:	7402                	ld	s0,32(sp)
    80003e6e:	64e2                	ld	s1,24(sp)
    80003e70:	6942                	ld	s2,16(sp)
    80003e72:	69a2                	ld	s3,8(sp)
    80003e74:	6a02                	ld	s4,0(sp)
    80003e76:	6145                	addi	sp,sp,48
    80003e78:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003e7a:	02059793          	slli	a5,a1,0x20
    80003e7e:	01e7d593          	srli	a1,a5,0x1e
    80003e82:	00b504b3          	add	s1,a0,a1
    80003e86:	0504a983          	lw	s3,80(s1)
    80003e8a:	fc099fe3          	bnez	s3,80003e68 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003e8e:	4108                	lw	a0,0(a0)
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	e48080e7          	jalr	-440(ra) # 80003cd8 <balloc>
    80003e98:	0005099b          	sext.w	s3,a0
    80003e9c:	0534a823          	sw	s3,80(s1)
    80003ea0:	b7e1                	j	80003e68 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ea2:	4108                	lw	a0,0(a0)
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	e34080e7          	jalr	-460(ra) # 80003cd8 <balloc>
    80003eac:	0005059b          	sext.w	a1,a0
    80003eb0:	08b92023          	sw	a1,128(s2)
    80003eb4:	b751                	j	80003e38 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003eb6:	00092503          	lw	a0,0(s2)
    80003eba:	00000097          	auipc	ra,0x0
    80003ebe:	e1e080e7          	jalr	-482(ra) # 80003cd8 <balloc>
    80003ec2:	0005099b          	sext.w	s3,a0
    80003ec6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003eca:	8552                	mv	a0,s4
    80003ecc:	00001097          	auipc	ra,0x1
    80003ed0:	22c080e7          	jalr	556(ra) # 800050f8 <log_write>
    80003ed4:	b769                	j	80003e5e <bmap+0x54>
  panic("bmap: out of range");
    80003ed6:	00005517          	auipc	a0,0x5
    80003eda:	7fa50513          	addi	a0,a0,2042 # 800096d0 <syscalls+0x118>
    80003ede:	ffffc097          	auipc	ra,0xffffc
    80003ee2:	64c080e7          	jalr	1612(ra) # 8000052a <panic>

0000000080003ee6 <iget>:
{
    80003ee6:	7179                	addi	sp,sp,-48
    80003ee8:	f406                	sd	ra,40(sp)
    80003eea:	f022                	sd	s0,32(sp)
    80003eec:	ec26                	sd	s1,24(sp)
    80003eee:	e84a                	sd	s2,16(sp)
    80003ef0:	e44e                	sd	s3,8(sp)
    80003ef2:	e052                	sd	s4,0(sp)
    80003ef4:	1800                	addi	s0,sp,48
    80003ef6:	89aa                	mv	s3,a0
    80003ef8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003efa:	00025517          	auipc	a0,0x25
    80003efe:	ece50513          	addi	a0,a0,-306 # 80028dc8 <itable>
    80003f02:	ffffd097          	auipc	ra,0xffffd
    80003f06:	cd0080e7          	jalr	-816(ra) # 80000bd2 <acquire>
  empty = 0;
    80003f0a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f0c:	00025497          	auipc	s1,0x25
    80003f10:	ed448493          	addi	s1,s1,-300 # 80028de0 <itable+0x18>
    80003f14:	00027697          	auipc	a3,0x27
    80003f18:	95c68693          	addi	a3,a3,-1700 # 8002a870 <log>
    80003f1c:	a039                	j	80003f2a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f1e:	02090b63          	beqz	s2,80003f54 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003f22:	08848493          	addi	s1,s1,136
    80003f26:	02d48a63          	beq	s1,a3,80003f5a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003f2a:	449c                	lw	a5,8(s1)
    80003f2c:	fef059e3          	blez	a5,80003f1e <iget+0x38>
    80003f30:	4098                	lw	a4,0(s1)
    80003f32:	ff3716e3          	bne	a4,s3,80003f1e <iget+0x38>
    80003f36:	40d8                	lw	a4,4(s1)
    80003f38:	ff4713e3          	bne	a4,s4,80003f1e <iget+0x38>
      ip->ref++;
    80003f3c:	2785                	addiw	a5,a5,1
    80003f3e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003f40:	00025517          	auipc	a0,0x25
    80003f44:	e8850513          	addi	a0,a0,-376 # 80028dc8 <itable>
    80003f48:	ffffd097          	auipc	ra,0xffffd
    80003f4c:	d3e080e7          	jalr	-706(ra) # 80000c86 <release>
      return ip;
    80003f50:	8926                	mv	s2,s1
    80003f52:	a03d                	j	80003f80 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003f54:	f7f9                	bnez	a5,80003f22 <iget+0x3c>
    80003f56:	8926                	mv	s2,s1
    80003f58:	b7e9                	j	80003f22 <iget+0x3c>
  if(empty == 0)
    80003f5a:	02090c63          	beqz	s2,80003f92 <iget+0xac>
  ip->dev = dev;
    80003f5e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003f62:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003f66:	4785                	li	a5,1
    80003f68:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003f6c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003f70:	00025517          	auipc	a0,0x25
    80003f74:	e5850513          	addi	a0,a0,-424 # 80028dc8 <itable>
    80003f78:	ffffd097          	auipc	ra,0xffffd
    80003f7c:	d0e080e7          	jalr	-754(ra) # 80000c86 <release>
}
    80003f80:	854a                	mv	a0,s2
    80003f82:	70a2                	ld	ra,40(sp)
    80003f84:	7402                	ld	s0,32(sp)
    80003f86:	64e2                	ld	s1,24(sp)
    80003f88:	6942                	ld	s2,16(sp)
    80003f8a:	69a2                	ld	s3,8(sp)
    80003f8c:	6a02                	ld	s4,0(sp)
    80003f8e:	6145                	addi	sp,sp,48
    80003f90:	8082                	ret
    panic("iget: no inodes");
    80003f92:	00005517          	auipc	a0,0x5
    80003f96:	75650513          	addi	a0,a0,1878 # 800096e8 <syscalls+0x130>
    80003f9a:	ffffc097          	auipc	ra,0xffffc
    80003f9e:	590080e7          	jalr	1424(ra) # 8000052a <panic>

0000000080003fa2 <fsinit>:
fsinit(int dev) {
    80003fa2:	7179                	addi	sp,sp,-48
    80003fa4:	f406                	sd	ra,40(sp)
    80003fa6:	f022                	sd	s0,32(sp)
    80003fa8:	ec26                	sd	s1,24(sp)
    80003faa:	e84a                	sd	s2,16(sp)
    80003fac:	e44e                	sd	s3,8(sp)
    80003fae:	1800                	addi	s0,sp,48
    80003fb0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003fb2:	4585                	li	a1,1
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	a62080e7          	jalr	-1438(ra) # 80003a16 <bread>
    80003fbc:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003fbe:	00025997          	auipc	s3,0x25
    80003fc2:	dea98993          	addi	s3,s3,-534 # 80028da8 <sb>
    80003fc6:	02000613          	li	a2,32
    80003fca:	05850593          	addi	a1,a0,88
    80003fce:	854e                	mv	a0,s3
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	d5a080e7          	jalr	-678(ra) # 80000d2a <memmove>
  brelse(bp);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	b6c080e7          	jalr	-1172(ra) # 80003b46 <brelse>
  if(sb.magic != FSMAGIC)
    80003fe2:	0009a703          	lw	a4,0(s3)
    80003fe6:	102037b7          	lui	a5,0x10203
    80003fea:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003fee:	02f71263          	bne	a4,a5,80004012 <fsinit+0x70>
  initlog(dev, &sb);
    80003ff2:	00025597          	auipc	a1,0x25
    80003ff6:	db658593          	addi	a1,a1,-586 # 80028da8 <sb>
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00001097          	auipc	ra,0x1
    80004000:	e7e080e7          	jalr	-386(ra) # 80004e7a <initlog>
}
    80004004:	70a2                	ld	ra,40(sp)
    80004006:	7402                	ld	s0,32(sp)
    80004008:	64e2                	ld	s1,24(sp)
    8000400a:	6942                	ld	s2,16(sp)
    8000400c:	69a2                	ld	s3,8(sp)
    8000400e:	6145                	addi	sp,sp,48
    80004010:	8082                	ret
    panic("invalid file system");
    80004012:	00005517          	auipc	a0,0x5
    80004016:	6e650513          	addi	a0,a0,1766 # 800096f8 <syscalls+0x140>
    8000401a:	ffffc097          	auipc	ra,0xffffc
    8000401e:	510080e7          	jalr	1296(ra) # 8000052a <panic>

0000000080004022 <iinit>:
{
    80004022:	7179                	addi	sp,sp,-48
    80004024:	f406                	sd	ra,40(sp)
    80004026:	f022                	sd	s0,32(sp)
    80004028:	ec26                	sd	s1,24(sp)
    8000402a:	e84a                	sd	s2,16(sp)
    8000402c:	e44e                	sd	s3,8(sp)
    8000402e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004030:	00005597          	auipc	a1,0x5
    80004034:	6e058593          	addi	a1,a1,1760 # 80009710 <syscalls+0x158>
    80004038:	00025517          	auipc	a0,0x25
    8000403c:	d9050513          	addi	a0,a0,-624 # 80028dc8 <itable>
    80004040:	ffffd097          	auipc	ra,0xffffd
    80004044:	b02080e7          	jalr	-1278(ra) # 80000b42 <initlock>
  for(i = 0; i < NINODE; i++) {
    80004048:	00025497          	auipc	s1,0x25
    8000404c:	da848493          	addi	s1,s1,-600 # 80028df0 <itable+0x28>
    80004050:	00027997          	auipc	s3,0x27
    80004054:	83098993          	addi	s3,s3,-2000 # 8002a880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80004058:	00005917          	auipc	s2,0x5
    8000405c:	6c090913          	addi	s2,s2,1728 # 80009718 <syscalls+0x160>
    80004060:	85ca                	mv	a1,s2
    80004062:	8526                	mv	a0,s1
    80004064:	00001097          	auipc	ra,0x1
    80004068:	17a080e7          	jalr	378(ra) # 800051de <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000406c:	08848493          	addi	s1,s1,136
    80004070:	ff3498e3          	bne	s1,s3,80004060 <iinit+0x3e>
}
    80004074:	70a2                	ld	ra,40(sp)
    80004076:	7402                	ld	s0,32(sp)
    80004078:	64e2                	ld	s1,24(sp)
    8000407a:	6942                	ld	s2,16(sp)
    8000407c:	69a2                	ld	s3,8(sp)
    8000407e:	6145                	addi	sp,sp,48
    80004080:	8082                	ret

0000000080004082 <ialloc>:
{
    80004082:	715d                	addi	sp,sp,-80
    80004084:	e486                	sd	ra,72(sp)
    80004086:	e0a2                	sd	s0,64(sp)
    80004088:	fc26                	sd	s1,56(sp)
    8000408a:	f84a                	sd	s2,48(sp)
    8000408c:	f44e                	sd	s3,40(sp)
    8000408e:	f052                	sd	s4,32(sp)
    80004090:	ec56                	sd	s5,24(sp)
    80004092:	e85a                	sd	s6,16(sp)
    80004094:	e45e                	sd	s7,8(sp)
    80004096:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80004098:	00025717          	auipc	a4,0x25
    8000409c:	d1c72703          	lw	a4,-740(a4) # 80028db4 <sb+0xc>
    800040a0:	4785                	li	a5,1
    800040a2:	04e7fa63          	bgeu	a5,a4,800040f6 <ialloc+0x74>
    800040a6:	8aaa                	mv	s5,a0
    800040a8:	8bae                	mv	s7,a1
    800040aa:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800040ac:	00025a17          	auipc	s4,0x25
    800040b0:	cfca0a13          	addi	s4,s4,-772 # 80028da8 <sb>
    800040b4:	00048b1b          	sext.w	s6,s1
    800040b8:	0044d793          	srli	a5,s1,0x4
    800040bc:	018a2583          	lw	a1,24(s4)
    800040c0:	9dbd                	addw	a1,a1,a5
    800040c2:	8556                	mv	a0,s5
    800040c4:	00000097          	auipc	ra,0x0
    800040c8:	952080e7          	jalr	-1710(ra) # 80003a16 <bread>
    800040cc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800040ce:	05850993          	addi	s3,a0,88
    800040d2:	00f4f793          	andi	a5,s1,15
    800040d6:	079a                	slli	a5,a5,0x6
    800040d8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800040da:	00099783          	lh	a5,0(s3)
    800040de:	c785                	beqz	a5,80004106 <ialloc+0x84>
    brelse(bp);
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	a66080e7          	jalr	-1434(ra) # 80003b46 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800040e8:	0485                	addi	s1,s1,1
    800040ea:	00ca2703          	lw	a4,12(s4)
    800040ee:	0004879b          	sext.w	a5,s1
    800040f2:	fce7e1e3          	bltu	a5,a4,800040b4 <ialloc+0x32>
  panic("ialloc: no inodes");
    800040f6:	00005517          	auipc	a0,0x5
    800040fa:	62a50513          	addi	a0,a0,1578 # 80009720 <syscalls+0x168>
    800040fe:	ffffc097          	auipc	ra,0xffffc
    80004102:	42c080e7          	jalr	1068(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80004106:	04000613          	li	a2,64
    8000410a:	4581                	li	a1,0
    8000410c:	854e                	mv	a0,s3
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	bc0080e7          	jalr	-1088(ra) # 80000cce <memset>
      dip->type = type;
    80004116:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000411a:	854a                	mv	a0,s2
    8000411c:	00001097          	auipc	ra,0x1
    80004120:	fdc080e7          	jalr	-36(ra) # 800050f8 <log_write>
      brelse(bp);
    80004124:	854a                	mv	a0,s2
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	a20080e7          	jalr	-1504(ra) # 80003b46 <brelse>
      return iget(dev, inum);
    8000412e:	85da                	mv	a1,s6
    80004130:	8556                	mv	a0,s5
    80004132:	00000097          	auipc	ra,0x0
    80004136:	db4080e7          	jalr	-588(ra) # 80003ee6 <iget>
}
    8000413a:	60a6                	ld	ra,72(sp)
    8000413c:	6406                	ld	s0,64(sp)
    8000413e:	74e2                	ld	s1,56(sp)
    80004140:	7942                	ld	s2,48(sp)
    80004142:	79a2                	ld	s3,40(sp)
    80004144:	7a02                	ld	s4,32(sp)
    80004146:	6ae2                	ld	s5,24(sp)
    80004148:	6b42                	ld	s6,16(sp)
    8000414a:	6ba2                	ld	s7,8(sp)
    8000414c:	6161                	addi	sp,sp,80
    8000414e:	8082                	ret

0000000080004150 <iupdate>:
{
    80004150:	1101                	addi	sp,sp,-32
    80004152:	ec06                	sd	ra,24(sp)
    80004154:	e822                	sd	s0,16(sp)
    80004156:	e426                	sd	s1,8(sp)
    80004158:	e04a                	sd	s2,0(sp)
    8000415a:	1000                	addi	s0,sp,32
    8000415c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000415e:	415c                	lw	a5,4(a0)
    80004160:	0047d79b          	srliw	a5,a5,0x4
    80004164:	00025597          	auipc	a1,0x25
    80004168:	c5c5a583          	lw	a1,-932(a1) # 80028dc0 <sb+0x18>
    8000416c:	9dbd                	addw	a1,a1,a5
    8000416e:	4108                	lw	a0,0(a0)
    80004170:	00000097          	auipc	ra,0x0
    80004174:	8a6080e7          	jalr	-1882(ra) # 80003a16 <bread>
    80004178:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000417a:	05850793          	addi	a5,a0,88
    8000417e:	40c8                	lw	a0,4(s1)
    80004180:	893d                	andi	a0,a0,15
    80004182:	051a                	slli	a0,a0,0x6
    80004184:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80004186:	04449703          	lh	a4,68(s1)
    8000418a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000418e:	04649703          	lh	a4,70(s1)
    80004192:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80004196:	04849703          	lh	a4,72(s1)
    8000419a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000419e:	04a49703          	lh	a4,74(s1)
    800041a2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800041a6:	44f8                	lw	a4,76(s1)
    800041a8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800041aa:	03400613          	li	a2,52
    800041ae:	05048593          	addi	a1,s1,80
    800041b2:	0531                	addi	a0,a0,12
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b76080e7          	jalr	-1162(ra) # 80000d2a <memmove>
  log_write(bp);
    800041bc:	854a                	mv	a0,s2
    800041be:	00001097          	auipc	ra,0x1
    800041c2:	f3a080e7          	jalr	-198(ra) # 800050f8 <log_write>
  brelse(bp);
    800041c6:	854a                	mv	a0,s2
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	97e080e7          	jalr	-1666(ra) # 80003b46 <brelse>
}
    800041d0:	60e2                	ld	ra,24(sp)
    800041d2:	6442                	ld	s0,16(sp)
    800041d4:	64a2                	ld	s1,8(sp)
    800041d6:	6902                	ld	s2,0(sp)
    800041d8:	6105                	addi	sp,sp,32
    800041da:	8082                	ret

00000000800041dc <idup>:
{
    800041dc:	1101                	addi	sp,sp,-32
    800041de:	ec06                	sd	ra,24(sp)
    800041e0:	e822                	sd	s0,16(sp)
    800041e2:	e426                	sd	s1,8(sp)
    800041e4:	1000                	addi	s0,sp,32
    800041e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800041e8:	00025517          	auipc	a0,0x25
    800041ec:	be050513          	addi	a0,a0,-1056 # 80028dc8 <itable>
    800041f0:	ffffd097          	auipc	ra,0xffffd
    800041f4:	9e2080e7          	jalr	-1566(ra) # 80000bd2 <acquire>
  ip->ref++;
    800041f8:	449c                	lw	a5,8(s1)
    800041fa:	2785                	addiw	a5,a5,1
    800041fc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800041fe:	00025517          	auipc	a0,0x25
    80004202:	bca50513          	addi	a0,a0,-1078 # 80028dc8 <itable>
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	a80080e7          	jalr	-1408(ra) # 80000c86 <release>
}
    8000420e:	8526                	mv	a0,s1
    80004210:	60e2                	ld	ra,24(sp)
    80004212:	6442                	ld	s0,16(sp)
    80004214:	64a2                	ld	s1,8(sp)
    80004216:	6105                	addi	sp,sp,32
    80004218:	8082                	ret

000000008000421a <ilock>:
{
    8000421a:	1101                	addi	sp,sp,-32
    8000421c:	ec06                	sd	ra,24(sp)
    8000421e:	e822                	sd	s0,16(sp)
    80004220:	e426                	sd	s1,8(sp)
    80004222:	e04a                	sd	s2,0(sp)
    80004224:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004226:	c115                	beqz	a0,8000424a <ilock+0x30>
    80004228:	84aa                	mv	s1,a0
    8000422a:	451c                	lw	a5,8(a0)
    8000422c:	00f05f63          	blez	a5,8000424a <ilock+0x30>
  acquiresleep(&ip->lock);
    80004230:	0541                	addi	a0,a0,16
    80004232:	00001097          	auipc	ra,0x1
    80004236:	fe6080e7          	jalr	-26(ra) # 80005218 <acquiresleep>
  if(ip->valid == 0){
    8000423a:	40bc                	lw	a5,64(s1)
    8000423c:	cf99                	beqz	a5,8000425a <ilock+0x40>
}
    8000423e:	60e2                	ld	ra,24(sp)
    80004240:	6442                	ld	s0,16(sp)
    80004242:	64a2                	ld	s1,8(sp)
    80004244:	6902                	ld	s2,0(sp)
    80004246:	6105                	addi	sp,sp,32
    80004248:	8082                	ret
    panic("ilock");
    8000424a:	00005517          	auipc	a0,0x5
    8000424e:	4ee50513          	addi	a0,a0,1262 # 80009738 <syscalls+0x180>
    80004252:	ffffc097          	auipc	ra,0xffffc
    80004256:	2d8080e7          	jalr	728(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000425a:	40dc                	lw	a5,4(s1)
    8000425c:	0047d79b          	srliw	a5,a5,0x4
    80004260:	00025597          	auipc	a1,0x25
    80004264:	b605a583          	lw	a1,-1184(a1) # 80028dc0 <sb+0x18>
    80004268:	9dbd                	addw	a1,a1,a5
    8000426a:	4088                	lw	a0,0(s1)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	7aa080e7          	jalr	1962(ra) # 80003a16 <bread>
    80004274:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004276:	05850593          	addi	a1,a0,88
    8000427a:	40dc                	lw	a5,4(s1)
    8000427c:	8bbd                	andi	a5,a5,15
    8000427e:	079a                	slli	a5,a5,0x6
    80004280:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004282:	00059783          	lh	a5,0(a1)
    80004286:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000428a:	00259783          	lh	a5,2(a1)
    8000428e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004292:	00459783          	lh	a5,4(a1)
    80004296:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000429a:	00659783          	lh	a5,6(a1)
    8000429e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800042a2:	459c                	lw	a5,8(a1)
    800042a4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800042a6:	03400613          	li	a2,52
    800042aa:	05b1                	addi	a1,a1,12
    800042ac:	05048513          	addi	a0,s1,80
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	a7a080e7          	jalr	-1414(ra) # 80000d2a <memmove>
    brelse(bp);
    800042b8:	854a                	mv	a0,s2
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	88c080e7          	jalr	-1908(ra) # 80003b46 <brelse>
    ip->valid = 1;
    800042c2:	4785                	li	a5,1
    800042c4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800042c6:	04449783          	lh	a5,68(s1)
    800042ca:	fbb5                	bnez	a5,8000423e <ilock+0x24>
      panic("ilock: no type");
    800042cc:	00005517          	auipc	a0,0x5
    800042d0:	47450513          	addi	a0,a0,1140 # 80009740 <syscalls+0x188>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	256080e7          	jalr	598(ra) # 8000052a <panic>

00000000800042dc <iunlock>:
{
    800042dc:	1101                	addi	sp,sp,-32
    800042de:	ec06                	sd	ra,24(sp)
    800042e0:	e822                	sd	s0,16(sp)
    800042e2:	e426                	sd	s1,8(sp)
    800042e4:	e04a                	sd	s2,0(sp)
    800042e6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800042e8:	c905                	beqz	a0,80004318 <iunlock+0x3c>
    800042ea:	84aa                	mv	s1,a0
    800042ec:	01050913          	addi	s2,a0,16
    800042f0:	854a                	mv	a0,s2
    800042f2:	00001097          	auipc	ra,0x1
    800042f6:	fc0080e7          	jalr	-64(ra) # 800052b2 <holdingsleep>
    800042fa:	cd19                	beqz	a0,80004318 <iunlock+0x3c>
    800042fc:	449c                	lw	a5,8(s1)
    800042fe:	00f05d63          	blez	a5,80004318 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004302:	854a                	mv	a0,s2
    80004304:	00001097          	auipc	ra,0x1
    80004308:	f6a080e7          	jalr	-150(ra) # 8000526e <releasesleep>
}
    8000430c:	60e2                	ld	ra,24(sp)
    8000430e:	6442                	ld	s0,16(sp)
    80004310:	64a2                	ld	s1,8(sp)
    80004312:	6902                	ld	s2,0(sp)
    80004314:	6105                	addi	sp,sp,32
    80004316:	8082                	ret
    panic("iunlock");
    80004318:	00005517          	auipc	a0,0x5
    8000431c:	43850513          	addi	a0,a0,1080 # 80009750 <syscalls+0x198>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	20a080e7          	jalr	522(ra) # 8000052a <panic>

0000000080004328 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004328:	7179                	addi	sp,sp,-48
    8000432a:	f406                	sd	ra,40(sp)
    8000432c:	f022                	sd	s0,32(sp)
    8000432e:	ec26                	sd	s1,24(sp)
    80004330:	e84a                	sd	s2,16(sp)
    80004332:	e44e                	sd	s3,8(sp)
    80004334:	e052                	sd	s4,0(sp)
    80004336:	1800                	addi	s0,sp,48
    80004338:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000433a:	05050493          	addi	s1,a0,80
    8000433e:	08050913          	addi	s2,a0,128
    80004342:	a021                	j	8000434a <itrunc+0x22>
    80004344:	0491                	addi	s1,s1,4
    80004346:	01248d63          	beq	s1,s2,80004360 <itrunc+0x38>
    if(ip->addrs[i]){
    8000434a:	408c                	lw	a1,0(s1)
    8000434c:	dde5                	beqz	a1,80004344 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000434e:	0009a503          	lw	a0,0(s3)
    80004352:	00000097          	auipc	ra,0x0
    80004356:	90a080e7          	jalr	-1782(ra) # 80003c5c <bfree>
      ip->addrs[i] = 0;
    8000435a:	0004a023          	sw	zero,0(s1)
    8000435e:	b7dd                	j	80004344 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004360:	0809a583          	lw	a1,128(s3)
    80004364:	e185                	bnez	a1,80004384 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004366:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000436a:	854e                	mv	a0,s3
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	de4080e7          	jalr	-540(ra) # 80004150 <iupdate>
}
    80004374:	70a2                	ld	ra,40(sp)
    80004376:	7402                	ld	s0,32(sp)
    80004378:	64e2                	ld	s1,24(sp)
    8000437a:	6942                	ld	s2,16(sp)
    8000437c:	69a2                	ld	s3,8(sp)
    8000437e:	6a02                	ld	s4,0(sp)
    80004380:	6145                	addi	sp,sp,48
    80004382:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004384:	0009a503          	lw	a0,0(s3)
    80004388:	fffff097          	auipc	ra,0xfffff
    8000438c:	68e080e7          	jalr	1678(ra) # 80003a16 <bread>
    80004390:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004392:	05850493          	addi	s1,a0,88
    80004396:	45850913          	addi	s2,a0,1112
    8000439a:	a021                	j	800043a2 <itrunc+0x7a>
    8000439c:	0491                	addi	s1,s1,4
    8000439e:	01248b63          	beq	s1,s2,800043b4 <itrunc+0x8c>
      if(a[j])
    800043a2:	408c                	lw	a1,0(s1)
    800043a4:	dde5                	beqz	a1,8000439c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800043a6:	0009a503          	lw	a0,0(s3)
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	8b2080e7          	jalr	-1870(ra) # 80003c5c <bfree>
    800043b2:	b7ed                	j	8000439c <itrunc+0x74>
    brelse(bp);
    800043b4:	8552                	mv	a0,s4
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	790080e7          	jalr	1936(ra) # 80003b46 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800043be:	0809a583          	lw	a1,128(s3)
    800043c2:	0009a503          	lw	a0,0(s3)
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	896080e7          	jalr	-1898(ra) # 80003c5c <bfree>
    ip->addrs[NDIRECT] = 0;
    800043ce:	0809a023          	sw	zero,128(s3)
    800043d2:	bf51                	j	80004366 <itrunc+0x3e>

00000000800043d4 <iput>:
{
    800043d4:	1101                	addi	sp,sp,-32
    800043d6:	ec06                	sd	ra,24(sp)
    800043d8:	e822                	sd	s0,16(sp)
    800043da:	e426                	sd	s1,8(sp)
    800043dc:	e04a                	sd	s2,0(sp)
    800043de:	1000                	addi	s0,sp,32
    800043e0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800043e2:	00025517          	auipc	a0,0x25
    800043e6:	9e650513          	addi	a0,a0,-1562 # 80028dc8 <itable>
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	7e8080e7          	jalr	2024(ra) # 80000bd2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800043f2:	4498                	lw	a4,8(s1)
    800043f4:	4785                	li	a5,1
    800043f6:	02f70363          	beq	a4,a5,8000441c <iput+0x48>
  ip->ref--;
    800043fa:	449c                	lw	a5,8(s1)
    800043fc:	37fd                	addiw	a5,a5,-1
    800043fe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004400:	00025517          	auipc	a0,0x25
    80004404:	9c850513          	addi	a0,a0,-1592 # 80028dc8 <itable>
    80004408:	ffffd097          	auipc	ra,0xffffd
    8000440c:	87e080e7          	jalr	-1922(ra) # 80000c86 <release>
}
    80004410:	60e2                	ld	ra,24(sp)
    80004412:	6442                	ld	s0,16(sp)
    80004414:	64a2                	ld	s1,8(sp)
    80004416:	6902                	ld	s2,0(sp)
    80004418:	6105                	addi	sp,sp,32
    8000441a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000441c:	40bc                	lw	a5,64(s1)
    8000441e:	dff1                	beqz	a5,800043fa <iput+0x26>
    80004420:	04a49783          	lh	a5,74(s1)
    80004424:	fbf9                	bnez	a5,800043fa <iput+0x26>
    acquiresleep(&ip->lock);
    80004426:	01048913          	addi	s2,s1,16
    8000442a:	854a                	mv	a0,s2
    8000442c:	00001097          	auipc	ra,0x1
    80004430:	dec080e7          	jalr	-532(ra) # 80005218 <acquiresleep>
    release(&itable.lock);
    80004434:	00025517          	auipc	a0,0x25
    80004438:	99450513          	addi	a0,a0,-1644 # 80028dc8 <itable>
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	84a080e7          	jalr	-1974(ra) # 80000c86 <release>
    itrunc(ip);
    80004444:	8526                	mv	a0,s1
    80004446:	00000097          	auipc	ra,0x0
    8000444a:	ee2080e7          	jalr	-286(ra) # 80004328 <itrunc>
    ip->type = 0;
    8000444e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004452:	8526                	mv	a0,s1
    80004454:	00000097          	auipc	ra,0x0
    80004458:	cfc080e7          	jalr	-772(ra) # 80004150 <iupdate>
    ip->valid = 0;
    8000445c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004460:	854a                	mv	a0,s2
    80004462:	00001097          	auipc	ra,0x1
    80004466:	e0c080e7          	jalr	-500(ra) # 8000526e <releasesleep>
    acquire(&itable.lock);
    8000446a:	00025517          	auipc	a0,0x25
    8000446e:	95e50513          	addi	a0,a0,-1698 # 80028dc8 <itable>
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	760080e7          	jalr	1888(ra) # 80000bd2 <acquire>
    8000447a:	b741                	j	800043fa <iput+0x26>

000000008000447c <iunlockput>:
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	1000                	addi	s0,sp,32
    80004486:	84aa                	mv	s1,a0
  iunlock(ip);
    80004488:	00000097          	auipc	ra,0x0
    8000448c:	e54080e7          	jalr	-428(ra) # 800042dc <iunlock>
  iput(ip);
    80004490:	8526                	mv	a0,s1
    80004492:	00000097          	auipc	ra,0x0
    80004496:	f42080e7          	jalr	-190(ra) # 800043d4 <iput>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6105                	addi	sp,sp,32
    800044a2:	8082                	ret

00000000800044a4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800044a4:	1141                	addi	sp,sp,-16
    800044a6:	e422                	sd	s0,8(sp)
    800044a8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800044aa:	411c                	lw	a5,0(a0)
    800044ac:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800044ae:	415c                	lw	a5,4(a0)
    800044b0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800044b2:	04451783          	lh	a5,68(a0)
    800044b6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800044ba:	04a51783          	lh	a5,74(a0)
    800044be:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800044c2:	04c56783          	lwu	a5,76(a0)
    800044c6:	e99c                	sd	a5,16(a1)
}
    800044c8:	6422                	ld	s0,8(sp)
    800044ca:	0141                	addi	sp,sp,16
    800044cc:	8082                	ret

00000000800044ce <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800044ce:	457c                	lw	a5,76(a0)
    800044d0:	0ed7e963          	bltu	a5,a3,800045c2 <readi+0xf4>
{
    800044d4:	7159                	addi	sp,sp,-112
    800044d6:	f486                	sd	ra,104(sp)
    800044d8:	f0a2                	sd	s0,96(sp)
    800044da:	eca6                	sd	s1,88(sp)
    800044dc:	e8ca                	sd	s2,80(sp)
    800044de:	e4ce                	sd	s3,72(sp)
    800044e0:	e0d2                	sd	s4,64(sp)
    800044e2:	fc56                	sd	s5,56(sp)
    800044e4:	f85a                	sd	s6,48(sp)
    800044e6:	f45e                	sd	s7,40(sp)
    800044e8:	f062                	sd	s8,32(sp)
    800044ea:	ec66                	sd	s9,24(sp)
    800044ec:	e86a                	sd	s10,16(sp)
    800044ee:	e46e                	sd	s11,8(sp)
    800044f0:	1880                	addi	s0,sp,112
    800044f2:	8baa                	mv	s7,a0
    800044f4:	8c2e                	mv	s8,a1
    800044f6:	8ab2                	mv	s5,a2
    800044f8:	84b6                	mv	s1,a3
    800044fa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800044fc:	9f35                	addw	a4,a4,a3
    return 0;
    800044fe:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004500:	0ad76063          	bltu	a4,a3,800045a0 <readi+0xd2>
  if(off + n > ip->size)
    80004504:	00e7f463          	bgeu	a5,a4,8000450c <readi+0x3e>
    n = ip->size - off;
    80004508:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000450c:	0a0b0963          	beqz	s6,800045be <readi+0xf0>
    80004510:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004512:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004516:	5cfd                	li	s9,-1
    80004518:	a82d                	j	80004552 <readi+0x84>
    8000451a:	020a1d93          	slli	s11,s4,0x20
    8000451e:	020ddd93          	srli	s11,s11,0x20
    80004522:	05890793          	addi	a5,s2,88
    80004526:	86ee                	mv	a3,s11
    80004528:	963e                	add	a2,a2,a5
    8000452a:	85d6                	mv	a1,s5
    8000452c:	8562                	mv	a0,s8
    8000452e:	fffff097          	auipc	ra,0xfffff
    80004532:	b0e080e7          	jalr	-1266(ra) # 8000303c <either_copyout>
    80004536:	05950d63          	beq	a0,s9,80004590 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000453a:	854a                	mv	a0,s2
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	60a080e7          	jalr	1546(ra) # 80003b46 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004544:	013a09bb          	addw	s3,s4,s3
    80004548:	009a04bb          	addw	s1,s4,s1
    8000454c:	9aee                	add	s5,s5,s11
    8000454e:	0569f763          	bgeu	s3,s6,8000459c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004552:	000ba903          	lw	s2,0(s7)
    80004556:	00a4d59b          	srliw	a1,s1,0xa
    8000455a:	855e                	mv	a0,s7
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	8ae080e7          	jalr	-1874(ra) # 80003e0a <bmap>
    80004564:	0005059b          	sext.w	a1,a0
    80004568:	854a                	mv	a0,s2
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	4ac080e7          	jalr	1196(ra) # 80003a16 <bread>
    80004572:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004574:	3ff4f613          	andi	a2,s1,1023
    80004578:	40cd07bb          	subw	a5,s10,a2
    8000457c:	413b073b          	subw	a4,s6,s3
    80004580:	8a3e                	mv	s4,a5
    80004582:	2781                	sext.w	a5,a5
    80004584:	0007069b          	sext.w	a3,a4
    80004588:	f8f6f9e3          	bgeu	a3,a5,8000451a <readi+0x4c>
    8000458c:	8a3a                	mv	s4,a4
    8000458e:	b771                	j	8000451a <readi+0x4c>
      brelse(bp);
    80004590:	854a                	mv	a0,s2
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	5b4080e7          	jalr	1460(ra) # 80003b46 <brelse>
      tot = -1;
    8000459a:	59fd                	li	s3,-1
  }
  return tot;
    8000459c:	0009851b          	sext.w	a0,s3
}
    800045a0:	70a6                	ld	ra,104(sp)
    800045a2:	7406                	ld	s0,96(sp)
    800045a4:	64e6                	ld	s1,88(sp)
    800045a6:	6946                	ld	s2,80(sp)
    800045a8:	69a6                	ld	s3,72(sp)
    800045aa:	6a06                	ld	s4,64(sp)
    800045ac:	7ae2                	ld	s5,56(sp)
    800045ae:	7b42                	ld	s6,48(sp)
    800045b0:	7ba2                	ld	s7,40(sp)
    800045b2:	7c02                	ld	s8,32(sp)
    800045b4:	6ce2                	ld	s9,24(sp)
    800045b6:	6d42                	ld	s10,16(sp)
    800045b8:	6da2                	ld	s11,8(sp)
    800045ba:	6165                	addi	sp,sp,112
    800045bc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800045be:	89da                	mv	s3,s6
    800045c0:	bff1                	j	8000459c <readi+0xce>
    return 0;
    800045c2:	4501                	li	a0,0
}
    800045c4:	8082                	ret

00000000800045c6 <writei>:
// Returns the number of bytes successfully written.
// If the return value is less than the requested n,
// there was an error of some kind.
int
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
    800045c6:	7159                	addi	sp,sp,-112
    800045c8:	f486                	sd	ra,104(sp)
    800045ca:	f0a2                	sd	s0,96(sp)
    800045cc:	eca6                	sd	s1,88(sp)
    800045ce:	e8ca                	sd	s2,80(sp)
    800045d0:	e4ce                	sd	s3,72(sp)
    800045d2:	e0d2                	sd	s4,64(sp)
    800045d4:	fc56                	sd	s5,56(sp)
    800045d6:	f85a                	sd	s6,48(sp)
    800045d8:	f45e                	sd	s7,40(sp)
    800045da:	f062                	sd	s8,32(sp)
    800045dc:	ec66                	sd	s9,24(sp)
    800045de:	e86a                	sd	s10,16(sp)
    800045e0:	e46e                	sd	s11,8(sp)
    800045e2:	1880                	addi	s0,sp,112
    800045e4:	8936                	mv	s2,a3
    800045e6:	8bba                	mv	s7,a4
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off){
    800045e8:	4574                	lw	a3,76(a0)
    800045ea:	0326e563          	bltu	a3,s2,80004614 <writei+0x4e>
    800045ee:	8b2a                	mv	s6,a0
    800045f0:	8c2e                	mv	s8,a1
    800045f2:	8ab2                	mv	s5,a2
    800045f4:	00e907bb          	addw	a5,s2,a4
    800045f8:	0127ee63          	bltu	a5,s2,80004614 <writei+0x4e>
    printf("if 1 %d %d %d\n", off, n, ip->size);
    return -1;
  }
  if(off + n > MAXFILE*BSIZE){
    800045fc:	00043737          	lui	a4,0x43
    80004600:	02f76663          	bltu	a4,a5,8000462c <writei+0x66>
        printf("if 2\n");
    return -1;
  }

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004604:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004606:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000460a:	5cfd                	li	s9,-1
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000460c:	060b9b63          	bnez	s7,80004682 <writei+0xbc>
    80004610:	8a5e                	mv	s4,s7
    80004612:	a0d1                	j	800046d6 <writei+0x110>
    printf("if 1 %d %d %d\n", off, n, ip->size);
    80004614:	865e                	mv	a2,s7
    80004616:	85ca                	mv	a1,s2
    80004618:	00005517          	auipc	a0,0x5
    8000461c:	14050513          	addi	a0,a0,320 # 80009758 <syscalls+0x1a0>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	f54080e7          	jalr	-172(ra) # 80000574 <printf>
    return -1;
    80004628:	557d                	li	a0,-1
    8000462a:	a86d                	j	800046e4 <writei+0x11e>
        printf("if 2\n");
    8000462c:	00005517          	auipc	a0,0x5
    80004630:	13c50513          	addi	a0,a0,316 # 80009768 <syscalls+0x1b0>
    80004634:	ffffc097          	auipc	ra,0xffffc
    80004638:	f40080e7          	jalr	-192(ra) # 80000574 <printf>
    return -1;
    8000463c:	557d                	li	a0,-1
    8000463e:	a05d                	j	800046e4 <writei+0x11e>
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004640:	02099d93          	slli	s11,s3,0x20
    80004644:	020ddd93          	srli	s11,s11,0x20
    80004648:	05848793          	addi	a5,s1,88
    8000464c:	86ee                	mv	a3,s11
    8000464e:	8656                	mv	a2,s5
    80004650:	85e2                	mv	a1,s8
    80004652:	953e                	add	a0,a0,a5
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	a3e080e7          	jalr	-1474(ra) # 80003092 <either_copyin>
    8000465c:	07950263          	beq	a0,s9,800046c0 <writei+0xfa>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004660:	8526                	mv	a0,s1
    80004662:	00001097          	auipc	ra,0x1
    80004666:	a96080e7          	jalr	-1386(ra) # 800050f8 <log_write>
    brelse(bp);
    8000466a:	8526                	mv	a0,s1
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	4da080e7          	jalr	1242(ra) # 80003b46 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004674:	01498a3b          	addw	s4,s3,s4
    80004678:	0129893b          	addw	s2,s3,s2
    8000467c:	9aee                	add	s5,s5,s11
    8000467e:	057a7663          	bgeu	s4,s7,800046ca <writei+0x104>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004682:	000b2483          	lw	s1,0(s6)
    80004686:	00a9559b          	srliw	a1,s2,0xa
    8000468a:	855a                	mv	a0,s6
    8000468c:	fffff097          	auipc	ra,0xfffff
    80004690:	77e080e7          	jalr	1918(ra) # 80003e0a <bmap>
    80004694:	0005059b          	sext.w	a1,a0
    80004698:	8526                	mv	a0,s1
    8000469a:	fffff097          	auipc	ra,0xfffff
    8000469e:	37c080e7          	jalr	892(ra) # 80003a16 <bread>
    800046a2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800046a4:	3ff97513          	andi	a0,s2,1023
    800046a8:	40ad07bb          	subw	a5,s10,a0
    800046ac:	414b873b          	subw	a4,s7,s4
    800046b0:	89be                	mv	s3,a5
    800046b2:	2781                	sext.w	a5,a5
    800046b4:	0007069b          	sext.w	a3,a4
    800046b8:	f8f6f4e3          	bgeu	a3,a5,80004640 <writei+0x7a>
    800046bc:	89ba                	mv	s3,a4
    800046be:	b749                	j	80004640 <writei+0x7a>
      brelse(bp);
    800046c0:	8526                	mv	a0,s1
    800046c2:	fffff097          	auipc	ra,0xfffff
    800046c6:	484080e7          	jalr	1156(ra) # 80003b46 <brelse>
  }

  if(off > ip->size)
    800046ca:	04cb2783          	lw	a5,76(s6)
    800046ce:	0127f463          	bgeu	a5,s2,800046d6 <writei+0x110>
    ip->size = off;
    800046d2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800046d6:	855a                	mv	a0,s6
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	a78080e7          	jalr	-1416(ra) # 80004150 <iupdate>

  return tot;
    800046e0:	000a051b          	sext.w	a0,s4
}
    800046e4:	70a6                	ld	ra,104(sp)
    800046e6:	7406                	ld	s0,96(sp)
    800046e8:	64e6                	ld	s1,88(sp)
    800046ea:	6946                	ld	s2,80(sp)
    800046ec:	69a6                	ld	s3,72(sp)
    800046ee:	6a06                	ld	s4,64(sp)
    800046f0:	7ae2                	ld	s5,56(sp)
    800046f2:	7b42                	ld	s6,48(sp)
    800046f4:	7ba2                	ld	s7,40(sp)
    800046f6:	7c02                	ld	s8,32(sp)
    800046f8:	6ce2                	ld	s9,24(sp)
    800046fa:	6d42                	ld	s10,16(sp)
    800046fc:	6da2                	ld	s11,8(sp)
    800046fe:	6165                	addi	sp,sp,112
    80004700:	8082                	ret

0000000080004702 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004702:	1141                	addi	sp,sp,-16
    80004704:	e406                	sd	ra,8(sp)
    80004706:	e022                	sd	s0,0(sp)
    80004708:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000470a:	4639                	li	a2,14
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	69a080e7          	jalr	1690(ra) # 80000da6 <strncmp>
}
    80004714:	60a2                	ld	ra,8(sp)
    80004716:	6402                	ld	s0,0(sp)
    80004718:	0141                	addi	sp,sp,16
    8000471a:	8082                	ret

000000008000471c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000471c:	7139                	addi	sp,sp,-64
    8000471e:	fc06                	sd	ra,56(sp)
    80004720:	f822                	sd	s0,48(sp)
    80004722:	f426                	sd	s1,40(sp)
    80004724:	f04a                	sd	s2,32(sp)
    80004726:	ec4e                	sd	s3,24(sp)
    80004728:	e852                	sd	s4,16(sp)
    8000472a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000472c:	04451703          	lh	a4,68(a0)
    80004730:	4785                	li	a5,1
    80004732:	00f71a63          	bne	a4,a5,80004746 <dirlookup+0x2a>
    80004736:	892a                	mv	s2,a0
    80004738:	89ae                	mv	s3,a1
    8000473a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000473c:	457c                	lw	a5,76(a0)
    8000473e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004740:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004742:	e79d                	bnez	a5,80004770 <dirlookup+0x54>
    80004744:	a8a5                	j	800047bc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004746:	00005517          	auipc	a0,0x5
    8000474a:	02a50513          	addi	a0,a0,42 # 80009770 <syscalls+0x1b8>
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	ddc080e7          	jalr	-548(ra) # 8000052a <panic>
      panic("dirlookup read");
    80004756:	00005517          	auipc	a0,0x5
    8000475a:	03250513          	addi	a0,a0,50 # 80009788 <syscalls+0x1d0>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	dcc080e7          	jalr	-564(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004766:	24c1                	addiw	s1,s1,16
    80004768:	04c92783          	lw	a5,76(s2)
    8000476c:	04f4f763          	bgeu	s1,a5,800047ba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004770:	4741                	li	a4,16
    80004772:	86a6                	mv	a3,s1
    80004774:	fc040613          	addi	a2,s0,-64
    80004778:	4581                	li	a1,0
    8000477a:	854a                	mv	a0,s2
    8000477c:	00000097          	auipc	ra,0x0
    80004780:	d52080e7          	jalr	-686(ra) # 800044ce <readi>
    80004784:	47c1                	li	a5,16
    80004786:	fcf518e3          	bne	a0,a5,80004756 <dirlookup+0x3a>
    if(de.inum == 0)
    8000478a:	fc045783          	lhu	a5,-64(s0)
    8000478e:	dfe1                	beqz	a5,80004766 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004790:	fc240593          	addi	a1,s0,-62
    80004794:	854e                	mv	a0,s3
    80004796:	00000097          	auipc	ra,0x0
    8000479a:	f6c080e7          	jalr	-148(ra) # 80004702 <namecmp>
    8000479e:	f561                	bnez	a0,80004766 <dirlookup+0x4a>
      if(poff)
    800047a0:	000a0463          	beqz	s4,800047a8 <dirlookup+0x8c>
        *poff = off;
    800047a4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800047a8:	fc045583          	lhu	a1,-64(s0)
    800047ac:	00092503          	lw	a0,0(s2)
    800047b0:	fffff097          	auipc	ra,0xfffff
    800047b4:	736080e7          	jalr	1846(ra) # 80003ee6 <iget>
    800047b8:	a011                	j	800047bc <dirlookup+0xa0>
  return 0;
    800047ba:	4501                	li	a0,0
}
    800047bc:	70e2                	ld	ra,56(sp)
    800047be:	7442                	ld	s0,48(sp)
    800047c0:	74a2                	ld	s1,40(sp)
    800047c2:	7902                	ld	s2,32(sp)
    800047c4:	69e2                	ld	s3,24(sp)
    800047c6:	6a42                	ld	s4,16(sp)
    800047c8:	6121                	addi	sp,sp,64
    800047ca:	8082                	ret

00000000800047cc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800047cc:	711d                	addi	sp,sp,-96
    800047ce:	ec86                	sd	ra,88(sp)
    800047d0:	e8a2                	sd	s0,80(sp)
    800047d2:	e4a6                	sd	s1,72(sp)
    800047d4:	e0ca                	sd	s2,64(sp)
    800047d6:	fc4e                	sd	s3,56(sp)
    800047d8:	f852                	sd	s4,48(sp)
    800047da:	f456                	sd	s5,40(sp)
    800047dc:	f05a                	sd	s6,32(sp)
    800047de:	ec5e                	sd	s7,24(sp)
    800047e0:	e862                	sd	s8,16(sp)
    800047e2:	e466                	sd	s9,8(sp)
    800047e4:	1080                	addi	s0,sp,96
    800047e6:	84aa                	mv	s1,a0
    800047e8:	8aae                	mv	s5,a1
    800047ea:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    800047ec:	00054703          	lbu	a4,0(a0)
    800047f0:	02f00793          	li	a5,47
    800047f4:	02f70363          	beq	a4,a5,8000481a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800047f8:	ffffe097          	auipc	ra,0xffffe
    800047fc:	be2080e7          	jalr	-1054(ra) # 800023da <myproc>
    80004800:	15053503          	ld	a0,336(a0)
    80004804:	00000097          	auipc	ra,0x0
    80004808:	9d8080e7          	jalr	-1576(ra) # 800041dc <idup>
    8000480c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000480e:	02f00913          	li	s2,47
  len = path - s;
    80004812:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004814:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004816:	4b85                	li	s7,1
    80004818:	a865                	j	800048d0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000481a:	4585                	li	a1,1
    8000481c:	4505                	li	a0,1
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	6c8080e7          	jalr	1736(ra) # 80003ee6 <iget>
    80004826:	89aa                	mv	s3,a0
    80004828:	b7dd                	j	8000480e <namex+0x42>
      iunlockput(ip);
    8000482a:	854e                	mv	a0,s3
    8000482c:	00000097          	auipc	ra,0x0
    80004830:	c50080e7          	jalr	-944(ra) # 8000447c <iunlockput>
      return 0;
    80004834:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004836:	854e                	mv	a0,s3
    80004838:	60e6                	ld	ra,88(sp)
    8000483a:	6446                	ld	s0,80(sp)
    8000483c:	64a6                	ld	s1,72(sp)
    8000483e:	6906                	ld	s2,64(sp)
    80004840:	79e2                	ld	s3,56(sp)
    80004842:	7a42                	ld	s4,48(sp)
    80004844:	7aa2                	ld	s5,40(sp)
    80004846:	7b02                	ld	s6,32(sp)
    80004848:	6be2                	ld	s7,24(sp)
    8000484a:	6c42                	ld	s8,16(sp)
    8000484c:	6ca2                	ld	s9,8(sp)
    8000484e:	6125                	addi	sp,sp,96
    80004850:	8082                	ret
      iunlock(ip);
    80004852:	854e                	mv	a0,s3
    80004854:	00000097          	auipc	ra,0x0
    80004858:	a88080e7          	jalr	-1400(ra) # 800042dc <iunlock>
      return ip;
    8000485c:	bfe9                	j	80004836 <namex+0x6a>
      iunlockput(ip);
    8000485e:	854e                	mv	a0,s3
    80004860:	00000097          	auipc	ra,0x0
    80004864:	c1c080e7          	jalr	-996(ra) # 8000447c <iunlockput>
      return 0;
    80004868:	89e6                	mv	s3,s9
    8000486a:	b7f1                	j	80004836 <namex+0x6a>
  len = path - s;
    8000486c:	40b48633          	sub	a2,s1,a1
    80004870:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004874:	099c5463          	bge	s8,s9,800048fc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004878:	4639                	li	a2,14
    8000487a:	8552                	mv	a0,s4
    8000487c:	ffffc097          	auipc	ra,0xffffc
    80004880:	4ae080e7          	jalr	1198(ra) # 80000d2a <memmove>
  while(*path == '/')
    80004884:	0004c783          	lbu	a5,0(s1)
    80004888:	01279763          	bne	a5,s2,80004896 <namex+0xca>
    path++;
    8000488c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000488e:	0004c783          	lbu	a5,0(s1)
    80004892:	ff278de3          	beq	a5,s2,8000488c <namex+0xc0>
    ilock(ip);
    80004896:	854e                	mv	a0,s3
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	982080e7          	jalr	-1662(ra) # 8000421a <ilock>
    if(ip->type != T_DIR){
    800048a0:	04499783          	lh	a5,68(s3)
    800048a4:	f97793e3          	bne	a5,s7,8000482a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800048a8:	000a8563          	beqz	s5,800048b2 <namex+0xe6>
    800048ac:	0004c783          	lbu	a5,0(s1)
    800048b0:	d3cd                	beqz	a5,80004852 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800048b2:	865a                	mv	a2,s6
    800048b4:	85d2                	mv	a1,s4
    800048b6:	854e                	mv	a0,s3
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	e64080e7          	jalr	-412(ra) # 8000471c <dirlookup>
    800048c0:	8caa                	mv	s9,a0
    800048c2:	dd51                	beqz	a0,8000485e <namex+0x92>
    iunlockput(ip);
    800048c4:	854e                	mv	a0,s3
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	bb6080e7          	jalr	-1098(ra) # 8000447c <iunlockput>
    ip = next;
    800048ce:	89e6                	mv	s3,s9
  while(*path == '/')
    800048d0:	0004c783          	lbu	a5,0(s1)
    800048d4:	05279763          	bne	a5,s2,80004922 <namex+0x156>
    path++;
    800048d8:	0485                	addi	s1,s1,1
  while(*path == '/')
    800048da:	0004c783          	lbu	a5,0(s1)
    800048de:	ff278de3          	beq	a5,s2,800048d8 <namex+0x10c>
  if(*path == 0)
    800048e2:	c79d                	beqz	a5,80004910 <namex+0x144>
    path++;
    800048e4:	85a6                	mv	a1,s1
  len = path - s;
    800048e6:	8cda                	mv	s9,s6
    800048e8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800048ea:	01278963          	beq	a5,s2,800048fc <namex+0x130>
    800048ee:	dfbd                	beqz	a5,8000486c <namex+0xa0>
    path++;
    800048f0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800048f2:	0004c783          	lbu	a5,0(s1)
    800048f6:	ff279ce3          	bne	a5,s2,800048ee <namex+0x122>
    800048fa:	bf8d                	j	8000486c <namex+0xa0>
    memmove(name, s, len);
    800048fc:	2601                	sext.w	a2,a2
    800048fe:	8552                	mv	a0,s4
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	42a080e7          	jalr	1066(ra) # 80000d2a <memmove>
    name[len] = 0;
    80004908:	9cd2                	add	s9,s9,s4
    8000490a:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000490e:	bf9d                	j	80004884 <namex+0xb8>
  if(nameiparent){
    80004910:	f20a83e3          	beqz	s5,80004836 <namex+0x6a>
    iput(ip);
    80004914:	854e                	mv	a0,s3
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	abe080e7          	jalr	-1346(ra) # 800043d4 <iput>
    return 0;
    8000491e:	4981                	li	s3,0
    80004920:	bf19                	j	80004836 <namex+0x6a>
  if(*path == 0)
    80004922:	d7fd                	beqz	a5,80004910 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004924:	0004c783          	lbu	a5,0(s1)
    80004928:	85a6                	mv	a1,s1
    8000492a:	b7d1                	j	800048ee <namex+0x122>

000000008000492c <dirlink>:
{
    8000492c:	7139                	addi	sp,sp,-64
    8000492e:	fc06                	sd	ra,56(sp)
    80004930:	f822                	sd	s0,48(sp)
    80004932:	f426                	sd	s1,40(sp)
    80004934:	f04a                	sd	s2,32(sp)
    80004936:	ec4e                	sd	s3,24(sp)
    80004938:	e852                	sd	s4,16(sp)
    8000493a:	0080                	addi	s0,sp,64
    8000493c:	892a                	mv	s2,a0
    8000493e:	8a2e                	mv	s4,a1
    80004940:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004942:	4601                	li	a2,0
    80004944:	00000097          	auipc	ra,0x0
    80004948:	dd8080e7          	jalr	-552(ra) # 8000471c <dirlookup>
    8000494c:	e93d                	bnez	a0,800049c2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000494e:	04c92483          	lw	s1,76(s2)
    80004952:	c49d                	beqz	s1,80004980 <dirlink+0x54>
    80004954:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004956:	4741                	li	a4,16
    80004958:	86a6                	mv	a3,s1
    8000495a:	fc040613          	addi	a2,s0,-64
    8000495e:	4581                	li	a1,0
    80004960:	854a                	mv	a0,s2
    80004962:	00000097          	auipc	ra,0x0
    80004966:	b6c080e7          	jalr	-1172(ra) # 800044ce <readi>
    8000496a:	47c1                	li	a5,16
    8000496c:	06f51163          	bne	a0,a5,800049ce <dirlink+0xa2>
    if(de.inum == 0)
    80004970:	fc045783          	lhu	a5,-64(s0)
    80004974:	c791                	beqz	a5,80004980 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004976:	24c1                	addiw	s1,s1,16
    80004978:	04c92783          	lw	a5,76(s2)
    8000497c:	fcf4ede3          	bltu	s1,a5,80004956 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004980:	4639                	li	a2,14
    80004982:	85d2                	mv	a1,s4
    80004984:	fc240513          	addi	a0,s0,-62
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	45a080e7          	jalr	1114(ra) # 80000de2 <strncpy>
  de.inum = inum;
    80004990:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004994:	4741                	li	a4,16
    80004996:	86a6                	mv	a3,s1
    80004998:	fc040613          	addi	a2,s0,-64
    8000499c:	4581                	li	a1,0
    8000499e:	854a                	mv	a0,s2
    800049a0:	00000097          	auipc	ra,0x0
    800049a4:	c26080e7          	jalr	-986(ra) # 800045c6 <writei>
    800049a8:	872a                	mv	a4,a0
    800049aa:	47c1                	li	a5,16
  return 0;
    800049ac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800049ae:	02f71863          	bne	a4,a5,800049de <dirlink+0xb2>
}
    800049b2:	70e2                	ld	ra,56(sp)
    800049b4:	7442                	ld	s0,48(sp)
    800049b6:	74a2                	ld	s1,40(sp)
    800049b8:	7902                	ld	s2,32(sp)
    800049ba:	69e2                	ld	s3,24(sp)
    800049bc:	6a42                	ld	s4,16(sp)
    800049be:	6121                	addi	sp,sp,64
    800049c0:	8082                	ret
    iput(ip);
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	a12080e7          	jalr	-1518(ra) # 800043d4 <iput>
    return -1;
    800049ca:	557d                	li	a0,-1
    800049cc:	b7dd                	j	800049b2 <dirlink+0x86>
      panic("dirlink read");
    800049ce:	00005517          	auipc	a0,0x5
    800049d2:	dca50513          	addi	a0,a0,-566 # 80009798 <syscalls+0x1e0>
    800049d6:	ffffc097          	auipc	ra,0xffffc
    800049da:	b54080e7          	jalr	-1196(ra) # 8000052a <panic>
    panic("dirlink");
    800049de:	00005517          	auipc	a0,0x5
    800049e2:	f5250513          	addi	a0,a0,-174 # 80009930 <syscalls+0x378>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	b44080e7          	jalr	-1212(ra) # 8000052a <panic>

00000000800049ee <namei>:

struct inode*
namei(char *path)
{
    800049ee:	1101                	addi	sp,sp,-32
    800049f0:	ec06                	sd	ra,24(sp)
    800049f2:	e822                	sd	s0,16(sp)
    800049f4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800049f6:	fe040613          	addi	a2,s0,-32
    800049fa:	4581                	li	a1,0
    800049fc:	00000097          	auipc	ra,0x0
    80004a00:	dd0080e7          	jalr	-560(ra) # 800047cc <namex>
}
    80004a04:	60e2                	ld	ra,24(sp)
    80004a06:	6442                	ld	s0,16(sp)
    80004a08:	6105                	addi	sp,sp,32
    80004a0a:	8082                	ret

0000000080004a0c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004a0c:	1141                	addi	sp,sp,-16
    80004a0e:	e406                	sd	ra,8(sp)
    80004a10:	e022                	sd	s0,0(sp)
    80004a12:	0800                	addi	s0,sp,16
    80004a14:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004a16:	4585                	li	a1,1
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	db4080e7          	jalr	-588(ra) # 800047cc <namex>
}
    80004a20:	60a2                	ld	ra,8(sp)
    80004a22:	6402                	ld	s0,0(sp)
    80004a24:	0141                	addi	sp,sp,16
    80004a26:	8082                	ret

0000000080004a28 <itoa>:


#include "fcntl.h"
#define DIGITS 14

char* itoa(int i, char b[]){
    80004a28:	1101                	addi	sp,sp,-32
    80004a2a:	ec22                	sd	s0,24(sp)
    80004a2c:	1000                	addi	s0,sp,32
    80004a2e:	872a                	mv	a4,a0
    80004a30:	852e                	mv	a0,a1
    char const digit[] = "0123456789";
    80004a32:	00005797          	auipc	a5,0x5
    80004a36:	d7678793          	addi	a5,a5,-650 # 800097a8 <syscalls+0x1f0>
    80004a3a:	6394                	ld	a3,0(a5)
    80004a3c:	fed43023          	sd	a3,-32(s0)
    80004a40:	0087d683          	lhu	a3,8(a5)
    80004a44:	fed41423          	sh	a3,-24(s0)
    80004a48:	00a7c783          	lbu	a5,10(a5)
    80004a4c:	fef40523          	sb	a5,-22(s0)
    char* p = b;
    80004a50:	87ae                	mv	a5,a1
    if(i<0){
    80004a52:	02074b63          	bltz	a4,80004a88 <itoa+0x60>
        *p++ = '-';
        i *= -1;
    }
    int shifter = i;
    80004a56:	86ba                	mv	a3,a4
    do{ //Move to where representation ends
        ++p;
        shifter = shifter/10;
    80004a58:	4629                	li	a2,10
        ++p;
    80004a5a:	0785                	addi	a5,a5,1
        shifter = shifter/10;
    80004a5c:	02c6c6bb          	divw	a3,a3,a2
    }while(shifter);
    80004a60:	feed                	bnez	a3,80004a5a <itoa+0x32>
    *p = '\0';
    80004a62:	00078023          	sb	zero,0(a5)
    do{ //Move back, inserting digits as u go
        *--p = digit[i%10];
    80004a66:	4629                	li	a2,10
    80004a68:	17fd                	addi	a5,a5,-1
    80004a6a:	02c766bb          	remw	a3,a4,a2
    80004a6e:	ff040593          	addi	a1,s0,-16
    80004a72:	96ae                	add	a3,a3,a1
    80004a74:	ff06c683          	lbu	a3,-16(a3)
    80004a78:	00d78023          	sb	a3,0(a5)
        i = i/10;
    80004a7c:	02c7473b          	divw	a4,a4,a2
    }while(i);
    80004a80:	f765                	bnez	a4,80004a68 <itoa+0x40>
    return b;
}
    80004a82:	6462                	ld	s0,24(sp)
    80004a84:	6105                	addi	sp,sp,32
    80004a86:	8082                	ret
        *p++ = '-';
    80004a88:	00158793          	addi	a5,a1,1
    80004a8c:	02d00693          	li	a3,45
    80004a90:	00d58023          	sb	a3,0(a1)
        i *= -1;
    80004a94:	40e0073b          	negw	a4,a4
    80004a98:	bf7d                	j	80004a56 <itoa+0x2e>

0000000080004a9a <removeSwapFile>:
//remove swap file of proc p;
int
removeSwapFile(struct proc* p)
{
    80004a9a:	711d                	addi	sp,sp,-96
    80004a9c:	ec86                	sd	ra,88(sp)
    80004a9e:	e8a2                	sd	s0,80(sp)
    80004aa0:	e4a6                	sd	s1,72(sp)
    80004aa2:	e0ca                	sd	s2,64(sp)
    80004aa4:	1080                	addi	s0,sp,96
    80004aa6:	84aa                	mv	s1,a0
  //path of proccess
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004aa8:	4619                	li	a2,6
    80004aaa:	00005597          	auipc	a1,0x5
    80004aae:	d0e58593          	addi	a1,a1,-754 # 800097b8 <syscalls+0x200>
    80004ab2:	fd040513          	addi	a0,s0,-48
    80004ab6:	ffffc097          	auipc	ra,0xffffc
    80004aba:	274080e7          	jalr	628(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004abe:	fd640593          	addi	a1,s0,-42
    80004ac2:	5888                	lw	a0,48(s1)
    80004ac4:	00000097          	auipc	ra,0x0
    80004ac8:	f64080e7          	jalr	-156(ra) # 80004a28 <itoa>
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ];
  uint off;

  if(0 == p->swapFile)
    80004acc:	1684b503          	ld	a0,360(s1)
    80004ad0:	16050763          	beqz	a0,80004c3e <removeSwapFile+0x1a4>
  {
    return -1;
  }
  fileclose(p->swapFile);
    80004ad4:	00001097          	auipc	ra,0x1
    80004ad8:	918080e7          	jalr	-1768(ra) # 800053ec <fileclose>

  begin_op();
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	444080e7          	jalr	1092(ra) # 80004f20 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    80004ae4:	fb040593          	addi	a1,s0,-80
    80004ae8:	fd040513          	addi	a0,s0,-48
    80004aec:	00000097          	auipc	ra,0x0
    80004af0:	f20080e7          	jalr	-224(ra) # 80004a0c <nameiparent>
    80004af4:	892a                	mv	s2,a0
    80004af6:	cd69                	beqz	a0,80004bd0 <removeSwapFile+0x136>
  {
    end_op();
    return -1;
  }

  ilock(dp);
    80004af8:	fffff097          	auipc	ra,0xfffff
    80004afc:	722080e7          	jalr	1826(ra) # 8000421a <ilock>

    // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004b00:	00005597          	auipc	a1,0x5
    80004b04:	cc058593          	addi	a1,a1,-832 # 800097c0 <syscalls+0x208>
    80004b08:	fb040513          	addi	a0,s0,-80
    80004b0c:	00000097          	auipc	ra,0x0
    80004b10:	bf6080e7          	jalr	-1034(ra) # 80004702 <namecmp>
    80004b14:	c57d                	beqz	a0,80004c02 <removeSwapFile+0x168>
    80004b16:	00005597          	auipc	a1,0x5
    80004b1a:	cb258593          	addi	a1,a1,-846 # 800097c8 <syscalls+0x210>
    80004b1e:	fb040513          	addi	a0,s0,-80
    80004b22:	00000097          	auipc	ra,0x0
    80004b26:	be0080e7          	jalr	-1056(ra) # 80004702 <namecmp>
    80004b2a:	cd61                	beqz	a0,80004c02 <removeSwapFile+0x168>
     goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80004b2c:	fac40613          	addi	a2,s0,-84
    80004b30:	fb040593          	addi	a1,s0,-80
    80004b34:	854a                	mv	a0,s2
    80004b36:	00000097          	auipc	ra,0x0
    80004b3a:	be6080e7          	jalr	-1050(ra) # 8000471c <dirlookup>
    80004b3e:	84aa                	mv	s1,a0
    80004b40:	c169                	beqz	a0,80004c02 <removeSwapFile+0x168>
    goto bad;
  ilock(ip);
    80004b42:	fffff097          	auipc	ra,0xfffff
    80004b46:	6d8080e7          	jalr	1752(ra) # 8000421a <ilock>

  if(ip->nlink < 1)
    80004b4a:	04a49783          	lh	a5,74(s1)
    80004b4e:	08f05763          	blez	a5,80004bdc <removeSwapFile+0x142>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004b52:	04449703          	lh	a4,68(s1)
    80004b56:	4785                	li	a5,1
    80004b58:	08f70a63          	beq	a4,a5,80004bec <removeSwapFile+0x152>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    80004b5c:	4641                	li	a2,16
    80004b5e:	4581                	li	a1,0
    80004b60:	fc040513          	addi	a0,s0,-64
    80004b64:	ffffc097          	auipc	ra,0xffffc
    80004b68:	16a080e7          	jalr	362(ra) # 80000cce <memset>
  if(writei(dp,0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b6c:	4741                	li	a4,16
    80004b6e:	fac42683          	lw	a3,-84(s0)
    80004b72:	fc040613          	addi	a2,s0,-64
    80004b76:	4581                	li	a1,0
    80004b78:	854a                	mv	a0,s2
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	a4c080e7          	jalr	-1460(ra) # 800045c6 <writei>
    80004b82:	47c1                	li	a5,16
    80004b84:	08f51a63          	bne	a0,a5,80004c18 <removeSwapFile+0x17e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    80004b88:	04449703          	lh	a4,68(s1)
    80004b8c:	4785                	li	a5,1
    80004b8e:	08f70d63          	beq	a4,a5,80004c28 <removeSwapFile+0x18e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    80004b92:	854a                	mv	a0,s2
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	8e8080e7          	jalr	-1816(ra) # 8000447c <iunlockput>

  ip->nlink--;
    80004b9c:	04a4d783          	lhu	a5,74(s1)
    80004ba0:	37fd                	addiw	a5,a5,-1
    80004ba2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	fffff097          	auipc	ra,0xfffff
    80004bac:	5a8080e7          	jalr	1448(ra) # 80004150 <iupdate>
  iunlockput(ip);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	00000097          	auipc	ra,0x0
    80004bb6:	8ca080e7          	jalr	-1846(ra) # 8000447c <iunlockput>

  end_op();
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	3e6080e7          	jalr	998(ra) # 80004fa0 <end_op>

  return 0;
    80004bc2:	4501                	li	a0,0
  bad:
    iunlockput(dp);
    end_op();
    return -1;

}
    80004bc4:	60e6                	ld	ra,88(sp)
    80004bc6:	6446                	ld	s0,80(sp)
    80004bc8:	64a6                	ld	s1,72(sp)
    80004bca:	6906                	ld	s2,64(sp)
    80004bcc:	6125                	addi	sp,sp,96
    80004bce:	8082                	ret
    end_op();
    80004bd0:	00000097          	auipc	ra,0x0
    80004bd4:	3d0080e7          	jalr	976(ra) # 80004fa0 <end_op>
    return -1;
    80004bd8:	557d                	li	a0,-1
    80004bda:	b7ed                	j	80004bc4 <removeSwapFile+0x12a>
    panic("unlink: nlink < 1");
    80004bdc:	00005517          	auipc	a0,0x5
    80004be0:	bf450513          	addi	a0,a0,-1036 # 800097d0 <syscalls+0x218>
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	946080e7          	jalr	-1722(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004bec:	8526                	mv	a0,s1
    80004bee:	00001097          	auipc	ra,0x1
    80004bf2:	7ac080e7          	jalr	1964(ra) # 8000639a <isdirempty>
    80004bf6:	f13d                	bnez	a0,80004b5c <removeSwapFile+0xc2>
    iunlockput(ip);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	882080e7          	jalr	-1918(ra) # 8000447c <iunlockput>
    iunlockput(dp);
    80004c02:	854a                	mv	a0,s2
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	878080e7          	jalr	-1928(ra) # 8000447c <iunlockput>
    end_op();
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	394080e7          	jalr	916(ra) # 80004fa0 <end_op>
    return -1;
    80004c14:	557d                	li	a0,-1
    80004c16:	b77d                	j	80004bc4 <removeSwapFile+0x12a>
    panic("unlink: writei");
    80004c18:	00005517          	auipc	a0,0x5
    80004c1c:	bd050513          	addi	a0,a0,-1072 # 800097e8 <syscalls+0x230>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	90a080e7          	jalr	-1782(ra) # 8000052a <panic>
    dp->nlink--;
    80004c28:	04a95783          	lhu	a5,74(s2)
    80004c2c:	37fd                	addiw	a5,a5,-1
    80004c2e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80004c32:	854a                	mv	a0,s2
    80004c34:	fffff097          	auipc	ra,0xfffff
    80004c38:	51c080e7          	jalr	1308(ra) # 80004150 <iupdate>
    80004c3c:	bf99                	j	80004b92 <removeSwapFile+0xf8>
    return -1;
    80004c3e:	557d                	li	a0,-1
    80004c40:	b751                	j	80004bc4 <removeSwapFile+0x12a>

0000000080004c42 <createSwapFile>:


//return 0 on success
int
createSwapFile(struct proc* p)
{
    80004c42:	7179                	addi	sp,sp,-48
    80004c44:	f406                	sd	ra,40(sp)
    80004c46:	f022                	sd	s0,32(sp)
    80004c48:	ec26                	sd	s1,24(sp)
    80004c4a:	e84a                	sd	s2,16(sp)
    80004c4c:	1800                	addi	s0,sp,48
    80004c4e:	84aa                	mv	s1,a0
  char path[DIGITS];
  memmove(path,"/.swap", 6);
    80004c50:	4619                	li	a2,6
    80004c52:	00005597          	auipc	a1,0x5
    80004c56:	b6658593          	addi	a1,a1,-1178 # 800097b8 <syscalls+0x200>
    80004c5a:	fd040513          	addi	a0,s0,-48
    80004c5e:	ffffc097          	auipc	ra,0xffffc
    80004c62:	0cc080e7          	jalr	204(ra) # 80000d2a <memmove>
  itoa(p->pid, path+ 6);
    80004c66:	fd640593          	addi	a1,s0,-42
    80004c6a:	5888                	lw	a0,48(s1)
    80004c6c:	00000097          	auipc	ra,0x0
    80004c70:	dbc080e7          	jalr	-580(ra) # 80004a28 <itoa>

  begin_op();
    80004c74:	00000097          	auipc	ra,0x0
    80004c78:	2ac080e7          	jalr	684(ra) # 80004f20 <begin_op>
  
  struct inode * in = create(path, T_FILE, 0, 0);
    80004c7c:	4681                	li	a3,0
    80004c7e:	4601                	li	a2,0
    80004c80:	4589                	li	a1,2
    80004c82:	fd040513          	addi	a0,s0,-48
    80004c86:	00002097          	auipc	ra,0x2
    80004c8a:	908080e7          	jalr	-1784(ra) # 8000658e <create>
    80004c8e:	892a                	mv	s2,a0
  iunlock(in);
    80004c90:	fffff097          	auipc	ra,0xfffff
    80004c94:	64c080e7          	jalr	1612(ra) # 800042dc <iunlock>
  p->swapFile = filealloc();
    80004c98:	00000097          	auipc	ra,0x0
    80004c9c:	698080e7          	jalr	1688(ra) # 80005330 <filealloc>
    80004ca0:	16a4b423          	sd	a0,360(s1)
  if (p->swapFile == 0)
    80004ca4:	cd1d                	beqz	a0,80004ce2 <createSwapFile+0xa0>
    panic("no slot for files on /store");
  p->swapFile->ip = in;
    80004ca6:	01253c23          	sd	s2,24(a0)
  p->swapFile->type = FD_INODE;
    80004caa:	1684b703          	ld	a4,360(s1)
    80004cae:	4789                	li	a5,2
    80004cb0:	c31c                	sw	a5,0(a4)
  p->swapFile->off = 0;
    80004cb2:	1684b703          	ld	a4,360(s1)
    80004cb6:	02072023          	sw	zero,32(a4) # 43020 <_entry-0x7ffbcfe0>
  p->swapFile->readable = O_WRONLY;
    80004cba:	1684b703          	ld	a4,360(s1)
    80004cbe:	4685                	li	a3,1
    80004cc0:	00d70423          	sb	a3,8(a4)
  p->swapFile->writable = O_RDWR;
    80004cc4:	1684b703          	ld	a4,360(s1)
    80004cc8:	00f704a3          	sb	a5,9(a4)
  end_op();
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	2d4080e7          	jalr	724(ra) # 80004fa0 <end_op>
  return 0;
}
    80004cd4:	4501                	li	a0,0
    80004cd6:	70a2                	ld	ra,40(sp)
    80004cd8:	7402                	ld	s0,32(sp)
    80004cda:	64e2                	ld	s1,24(sp)
    80004cdc:	6942                	ld	s2,16(sp)
    80004cde:	6145                	addi	sp,sp,48
    80004ce0:	8082                	ret
    panic("no slot for files on /store");
    80004ce2:	00005517          	auipc	a0,0x5
    80004ce6:	b1650513          	addi	a0,a0,-1258 # 800097f8 <syscalls+0x240>
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	840080e7          	jalr	-1984(ra) # 8000052a <panic>

0000000080004cf2 <writeToSwapFile>:

//return as sys_write (-1 when error)
int
writeToSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004cf2:	1141                	addi	sp,sp,-16
    80004cf4:	e406                	sd	ra,8(sp)
    80004cf6:	e022                	sd	s0,0(sp)
    80004cf8:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004cfa:	16853783          	ld	a5,360(a0)
    80004cfe:	d390                	sw	a2,32(a5)
  return kfilewrite(p->swapFile, (uint64)buffer, size);
    80004d00:	8636                	mv	a2,a3
    80004d02:	16853503          	ld	a0,360(a0)
    80004d06:	00001097          	auipc	ra,0x1
    80004d0a:	ad8080e7          	jalr	-1320(ra) # 800057de <kfilewrite>
}
    80004d0e:	60a2                	ld	ra,8(sp)
    80004d10:	6402                	ld	s0,0(sp)
    80004d12:	0141                	addi	sp,sp,16
    80004d14:	8082                	ret

0000000080004d16 <readFromSwapFile>:

//return as sys_read (-1 when error)
int
readFromSwapFile(struct proc * p, char* buffer, uint placeOnFile, uint size)
{
    80004d16:	1141                	addi	sp,sp,-16
    80004d18:	e406                	sd	ra,8(sp)
    80004d1a:	e022                	sd	s0,0(sp)
    80004d1c:	0800                	addi	s0,sp,16
  p->swapFile->off = placeOnFile;
    80004d1e:	16853783          	ld	a5,360(a0)
    80004d22:	d390                	sw	a2,32(a5)
  return kfileread(p->swapFile, (uint64)buffer,  size);
    80004d24:	8636                	mv	a2,a3
    80004d26:	16853503          	ld	a0,360(a0)
    80004d2a:	00001097          	auipc	ra,0x1
    80004d2e:	9f2080e7          	jalr	-1550(ra) # 8000571c <kfileread>
    80004d32:	60a2                	ld	ra,8(sp)
    80004d34:	6402                	ld	s0,0(sp)
    80004d36:	0141                	addi	sp,sp,16
    80004d38:	8082                	ret

0000000080004d3a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004d3a:	1101                	addi	sp,sp,-32
    80004d3c:	ec06                	sd	ra,24(sp)
    80004d3e:	e822                	sd	s0,16(sp)
    80004d40:	e426                	sd	s1,8(sp)
    80004d42:	e04a                	sd	s2,0(sp)
    80004d44:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004d46:	00026917          	auipc	s2,0x26
    80004d4a:	b2a90913          	addi	s2,s2,-1238 # 8002a870 <log>
    80004d4e:	01892583          	lw	a1,24(s2)
    80004d52:	02892503          	lw	a0,40(s2)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	cc0080e7          	jalr	-832(ra) # 80003a16 <bread>
    80004d5e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004d60:	02c92683          	lw	a3,44(s2)
    80004d64:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004d66:	02d05863          	blez	a3,80004d96 <write_head+0x5c>
    80004d6a:	00026797          	auipc	a5,0x26
    80004d6e:	b3678793          	addi	a5,a5,-1226 # 8002a8a0 <log+0x30>
    80004d72:	05c50713          	addi	a4,a0,92
    80004d76:	36fd                	addiw	a3,a3,-1
    80004d78:	02069613          	slli	a2,a3,0x20
    80004d7c:	01e65693          	srli	a3,a2,0x1e
    80004d80:	00026617          	auipc	a2,0x26
    80004d84:	b2460613          	addi	a2,a2,-1244 # 8002a8a4 <log+0x34>
    80004d88:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004d8a:	4390                	lw	a2,0(a5)
    80004d8c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004d8e:	0791                	addi	a5,a5,4
    80004d90:	0711                	addi	a4,a4,4
    80004d92:	fed79ce3          	bne	a5,a3,80004d8a <write_head+0x50>
  }
  bwrite(buf);
    80004d96:	8526                	mv	a0,s1
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	d70080e7          	jalr	-656(ra) # 80003b08 <bwrite>
  brelse(buf);
    80004da0:	8526                	mv	a0,s1
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	da4080e7          	jalr	-604(ra) # 80003b46 <brelse>
}
    80004daa:	60e2                	ld	ra,24(sp)
    80004dac:	6442                	ld	s0,16(sp)
    80004dae:	64a2                	ld	s1,8(sp)
    80004db0:	6902                	ld	s2,0(sp)
    80004db2:	6105                	addi	sp,sp,32
    80004db4:	8082                	ret

0000000080004db6 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004db6:	00026797          	auipc	a5,0x26
    80004dba:	ae67a783          	lw	a5,-1306(a5) # 8002a89c <log+0x2c>
    80004dbe:	0af05d63          	blez	a5,80004e78 <install_trans+0xc2>
{
    80004dc2:	7139                	addi	sp,sp,-64
    80004dc4:	fc06                	sd	ra,56(sp)
    80004dc6:	f822                	sd	s0,48(sp)
    80004dc8:	f426                	sd	s1,40(sp)
    80004dca:	f04a                	sd	s2,32(sp)
    80004dcc:	ec4e                	sd	s3,24(sp)
    80004dce:	e852                	sd	s4,16(sp)
    80004dd0:	e456                	sd	s5,8(sp)
    80004dd2:	e05a                	sd	s6,0(sp)
    80004dd4:	0080                	addi	s0,sp,64
    80004dd6:	8b2a                	mv	s6,a0
    80004dd8:	00026a97          	auipc	s5,0x26
    80004ddc:	ac8a8a93          	addi	s5,s5,-1336 # 8002a8a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004de0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004de2:	00026997          	auipc	s3,0x26
    80004de6:	a8e98993          	addi	s3,s3,-1394 # 8002a870 <log>
    80004dea:	a00d                	j	80004e0c <install_trans+0x56>
    brelse(lbuf);
    80004dec:	854a                	mv	a0,s2
    80004dee:	fffff097          	auipc	ra,0xfffff
    80004df2:	d58080e7          	jalr	-680(ra) # 80003b46 <brelse>
    brelse(dbuf);
    80004df6:	8526                	mv	a0,s1
    80004df8:	fffff097          	auipc	ra,0xfffff
    80004dfc:	d4e080e7          	jalr	-690(ra) # 80003b46 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e00:	2a05                	addiw	s4,s4,1
    80004e02:	0a91                	addi	s5,s5,4
    80004e04:	02c9a783          	lw	a5,44(s3)
    80004e08:	04fa5e63          	bge	s4,a5,80004e64 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004e0c:	0189a583          	lw	a1,24(s3)
    80004e10:	014585bb          	addw	a1,a1,s4
    80004e14:	2585                	addiw	a1,a1,1
    80004e16:	0289a503          	lw	a0,40(s3)
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	bfc080e7          	jalr	-1028(ra) # 80003a16 <bread>
    80004e22:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004e24:	000aa583          	lw	a1,0(s5)
    80004e28:	0289a503          	lw	a0,40(s3)
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	bea080e7          	jalr	-1046(ra) # 80003a16 <bread>
    80004e34:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004e36:	40000613          	li	a2,1024
    80004e3a:	05890593          	addi	a1,s2,88
    80004e3e:	05850513          	addi	a0,a0,88
    80004e42:	ffffc097          	auipc	ra,0xffffc
    80004e46:	ee8080e7          	jalr	-280(ra) # 80000d2a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	cbc080e7          	jalr	-836(ra) # 80003b08 <bwrite>
    if(recovering == 0)
    80004e54:	f80b1ce3          	bnez	s6,80004dec <install_trans+0x36>
      bunpin(dbuf);
    80004e58:	8526                	mv	a0,s1
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	dc6080e7          	jalr	-570(ra) # 80003c20 <bunpin>
    80004e62:	b769                	j	80004dec <install_trans+0x36>
}
    80004e64:	70e2                	ld	ra,56(sp)
    80004e66:	7442                	ld	s0,48(sp)
    80004e68:	74a2                	ld	s1,40(sp)
    80004e6a:	7902                	ld	s2,32(sp)
    80004e6c:	69e2                	ld	s3,24(sp)
    80004e6e:	6a42                	ld	s4,16(sp)
    80004e70:	6aa2                	ld	s5,8(sp)
    80004e72:	6b02                	ld	s6,0(sp)
    80004e74:	6121                	addi	sp,sp,64
    80004e76:	8082                	ret
    80004e78:	8082                	ret

0000000080004e7a <initlog>:
{
    80004e7a:	7179                	addi	sp,sp,-48
    80004e7c:	f406                	sd	ra,40(sp)
    80004e7e:	f022                	sd	s0,32(sp)
    80004e80:	ec26                	sd	s1,24(sp)
    80004e82:	e84a                	sd	s2,16(sp)
    80004e84:	e44e                	sd	s3,8(sp)
    80004e86:	1800                	addi	s0,sp,48
    80004e88:	892a                	mv	s2,a0
    80004e8a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004e8c:	00026497          	auipc	s1,0x26
    80004e90:	9e448493          	addi	s1,s1,-1564 # 8002a870 <log>
    80004e94:	00005597          	auipc	a1,0x5
    80004e98:	98458593          	addi	a1,a1,-1660 # 80009818 <syscalls+0x260>
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	ca4080e7          	jalr	-860(ra) # 80000b42 <initlock>
  log.start = sb->logstart;
    80004ea6:	0149a583          	lw	a1,20(s3)
    80004eaa:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004eac:	0109a783          	lw	a5,16(s3)
    80004eb0:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004eb2:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004eb6:	854a                	mv	a0,s2
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	b5e080e7          	jalr	-1186(ra) # 80003a16 <bread>
  log.lh.n = lh->n;
    80004ec0:	4d34                	lw	a3,88(a0)
    80004ec2:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004ec4:	02d05663          	blez	a3,80004ef0 <initlog+0x76>
    80004ec8:	05c50793          	addi	a5,a0,92
    80004ecc:	00026717          	auipc	a4,0x26
    80004ed0:	9d470713          	addi	a4,a4,-1580 # 8002a8a0 <log+0x30>
    80004ed4:	36fd                	addiw	a3,a3,-1
    80004ed6:	02069613          	slli	a2,a3,0x20
    80004eda:	01e65693          	srli	a3,a2,0x1e
    80004ede:	06050613          	addi	a2,a0,96
    80004ee2:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004ee4:	4390                	lw	a2,0(a5)
    80004ee6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004ee8:	0791                	addi	a5,a5,4
    80004eea:	0711                	addi	a4,a4,4
    80004eec:	fed79ce3          	bne	a5,a3,80004ee4 <initlog+0x6a>
  brelse(buf);
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	c56080e7          	jalr	-938(ra) # 80003b46 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004ef8:	4505                	li	a0,1
    80004efa:	00000097          	auipc	ra,0x0
    80004efe:	ebc080e7          	jalr	-324(ra) # 80004db6 <install_trans>
  log.lh.n = 0;
    80004f02:	00026797          	auipc	a5,0x26
    80004f06:	9807ad23          	sw	zero,-1638(a5) # 8002a89c <log+0x2c>
  write_head(); // clear the log
    80004f0a:	00000097          	auipc	ra,0x0
    80004f0e:	e30080e7          	jalr	-464(ra) # 80004d3a <write_head>
}
    80004f12:	70a2                	ld	ra,40(sp)
    80004f14:	7402                	ld	s0,32(sp)
    80004f16:	64e2                	ld	s1,24(sp)
    80004f18:	6942                	ld	s2,16(sp)
    80004f1a:	69a2                	ld	s3,8(sp)
    80004f1c:	6145                	addi	sp,sp,48
    80004f1e:	8082                	ret

0000000080004f20 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004f20:	1101                	addi	sp,sp,-32
    80004f22:	ec06                	sd	ra,24(sp)
    80004f24:	e822                	sd	s0,16(sp)
    80004f26:	e426                	sd	s1,8(sp)
    80004f28:	e04a                	sd	s2,0(sp)
    80004f2a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004f2c:	00026517          	auipc	a0,0x26
    80004f30:	94450513          	addi	a0,a0,-1724 # 8002a870 <log>
    80004f34:	ffffc097          	auipc	ra,0xffffc
    80004f38:	c9e080e7          	jalr	-866(ra) # 80000bd2 <acquire>
  while(1){
    if(log.committing){
    80004f3c:	00026497          	auipc	s1,0x26
    80004f40:	93448493          	addi	s1,s1,-1740 # 8002a870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004f44:	4979                	li	s2,30
    80004f46:	a039                	j	80004f54 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004f48:	85a6                	mv	a1,s1
    80004f4a:	8526                	mv	a0,s1
    80004f4c:	ffffe097          	auipc	ra,0xffffe
    80004f50:	d36080e7          	jalr	-714(ra) # 80002c82 <sleep>
    if(log.committing){
    80004f54:	50dc                	lw	a5,36(s1)
    80004f56:	fbed                	bnez	a5,80004f48 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004f58:	509c                	lw	a5,32(s1)
    80004f5a:	0017871b          	addiw	a4,a5,1
    80004f5e:	0007069b          	sext.w	a3,a4
    80004f62:	0027179b          	slliw	a5,a4,0x2
    80004f66:	9fb9                	addw	a5,a5,a4
    80004f68:	0017979b          	slliw	a5,a5,0x1
    80004f6c:	54d8                	lw	a4,44(s1)
    80004f6e:	9fb9                	addw	a5,a5,a4
    80004f70:	00f95963          	bge	s2,a5,80004f82 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004f74:	85a6                	mv	a1,s1
    80004f76:	8526                	mv	a0,s1
    80004f78:	ffffe097          	auipc	ra,0xffffe
    80004f7c:	d0a080e7          	jalr	-758(ra) # 80002c82 <sleep>
    80004f80:	bfd1                	j	80004f54 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004f82:	00026517          	auipc	a0,0x26
    80004f86:	8ee50513          	addi	a0,a0,-1810 # 8002a870 <log>
    80004f8a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	cfa080e7          	jalr	-774(ra) # 80000c86 <release>
      break;
    }
  }
}
    80004f94:	60e2                	ld	ra,24(sp)
    80004f96:	6442                	ld	s0,16(sp)
    80004f98:	64a2                	ld	s1,8(sp)
    80004f9a:	6902                	ld	s2,0(sp)
    80004f9c:	6105                	addi	sp,sp,32
    80004f9e:	8082                	ret

0000000080004fa0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004fa0:	7139                	addi	sp,sp,-64
    80004fa2:	fc06                	sd	ra,56(sp)
    80004fa4:	f822                	sd	s0,48(sp)
    80004fa6:	f426                	sd	s1,40(sp)
    80004fa8:	f04a                	sd	s2,32(sp)
    80004faa:	ec4e                	sd	s3,24(sp)
    80004fac:	e852                	sd	s4,16(sp)
    80004fae:	e456                	sd	s5,8(sp)
    80004fb0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004fb2:	00026497          	auipc	s1,0x26
    80004fb6:	8be48493          	addi	s1,s1,-1858 # 8002a870 <log>
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	c16080e7          	jalr	-1002(ra) # 80000bd2 <acquire>
  log.outstanding -= 1;
    80004fc4:	509c                	lw	a5,32(s1)
    80004fc6:	37fd                	addiw	a5,a5,-1
    80004fc8:	0007891b          	sext.w	s2,a5
    80004fcc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004fce:	50dc                	lw	a5,36(s1)
    80004fd0:	e7b9                	bnez	a5,8000501e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004fd2:	04091e63          	bnez	s2,8000502e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004fd6:	00026497          	auipc	s1,0x26
    80004fda:	89a48493          	addi	s1,s1,-1894 # 8002a870 <log>
    80004fde:	4785                	li	a5,1
    80004fe0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004fe2:	8526                	mv	a0,s1
    80004fe4:	ffffc097          	auipc	ra,0xffffc
    80004fe8:	ca2080e7          	jalr	-862(ra) # 80000c86 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004fec:	54dc                	lw	a5,44(s1)
    80004fee:	06f04763          	bgtz	a5,8000505c <end_op+0xbc>
    acquire(&log.lock);
    80004ff2:	00026497          	auipc	s1,0x26
    80004ff6:	87e48493          	addi	s1,s1,-1922 # 8002a870 <log>
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	ffffc097          	auipc	ra,0xffffc
    80005000:	bd6080e7          	jalr	-1066(ra) # 80000bd2 <acquire>
    log.committing = 0;
    80005004:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80005008:	8526                	mv	a0,s1
    8000500a:	ffffe097          	auipc	ra,0xffffe
    8000500e:	e04080e7          	jalr	-508(ra) # 80002e0e <wakeup>
    release(&log.lock);
    80005012:	8526                	mv	a0,s1
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	c72080e7          	jalr	-910(ra) # 80000c86 <release>
}
    8000501c:	a03d                	j	8000504a <end_op+0xaa>
    panic("log.committing");
    8000501e:	00005517          	auipc	a0,0x5
    80005022:	80250513          	addi	a0,a0,-2046 # 80009820 <syscalls+0x268>
    80005026:	ffffb097          	auipc	ra,0xffffb
    8000502a:	504080e7          	jalr	1284(ra) # 8000052a <panic>
    wakeup(&log);
    8000502e:	00026497          	auipc	s1,0x26
    80005032:	84248493          	addi	s1,s1,-1982 # 8002a870 <log>
    80005036:	8526                	mv	a0,s1
    80005038:	ffffe097          	auipc	ra,0xffffe
    8000503c:	dd6080e7          	jalr	-554(ra) # 80002e0e <wakeup>
  release(&log.lock);
    80005040:	8526                	mv	a0,s1
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	c44080e7          	jalr	-956(ra) # 80000c86 <release>
}
    8000504a:	70e2                	ld	ra,56(sp)
    8000504c:	7442                	ld	s0,48(sp)
    8000504e:	74a2                	ld	s1,40(sp)
    80005050:	7902                	ld	s2,32(sp)
    80005052:	69e2                	ld	s3,24(sp)
    80005054:	6a42                	ld	s4,16(sp)
    80005056:	6aa2                	ld	s5,8(sp)
    80005058:	6121                	addi	sp,sp,64
    8000505a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000505c:	00026a97          	auipc	s5,0x26
    80005060:	844a8a93          	addi	s5,s5,-1980 # 8002a8a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005064:	00026a17          	auipc	s4,0x26
    80005068:	80ca0a13          	addi	s4,s4,-2036 # 8002a870 <log>
    8000506c:	018a2583          	lw	a1,24(s4)
    80005070:	012585bb          	addw	a1,a1,s2
    80005074:	2585                	addiw	a1,a1,1
    80005076:	028a2503          	lw	a0,40(s4)
    8000507a:	fffff097          	auipc	ra,0xfffff
    8000507e:	99c080e7          	jalr	-1636(ra) # 80003a16 <bread>
    80005082:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005084:	000aa583          	lw	a1,0(s5)
    80005088:	028a2503          	lw	a0,40(s4)
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	98a080e7          	jalr	-1654(ra) # 80003a16 <bread>
    80005094:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005096:	40000613          	li	a2,1024
    8000509a:	05850593          	addi	a1,a0,88
    8000509e:	05848513          	addi	a0,s1,88
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	c88080e7          	jalr	-888(ra) # 80000d2a <memmove>
    bwrite(to);  // write the log
    800050aa:	8526                	mv	a0,s1
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	a5c080e7          	jalr	-1444(ra) # 80003b08 <bwrite>
    brelse(from);
    800050b4:	854e                	mv	a0,s3
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	a90080e7          	jalr	-1392(ra) # 80003b46 <brelse>
    brelse(to);
    800050be:	8526                	mv	a0,s1
    800050c0:	fffff097          	auipc	ra,0xfffff
    800050c4:	a86080e7          	jalr	-1402(ra) # 80003b46 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800050c8:	2905                	addiw	s2,s2,1
    800050ca:	0a91                	addi	s5,s5,4
    800050cc:	02ca2783          	lw	a5,44(s4)
    800050d0:	f8f94ee3          	blt	s2,a5,8000506c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	c66080e7          	jalr	-922(ra) # 80004d3a <write_head>
    install_trans(0); // Now install writes to home locations
    800050dc:	4501                	li	a0,0
    800050de:	00000097          	auipc	ra,0x0
    800050e2:	cd8080e7          	jalr	-808(ra) # 80004db6 <install_trans>
    log.lh.n = 0;
    800050e6:	00025797          	auipc	a5,0x25
    800050ea:	7a07ab23          	sw	zero,1974(a5) # 8002a89c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800050ee:	00000097          	auipc	ra,0x0
    800050f2:	c4c080e7          	jalr	-948(ra) # 80004d3a <write_head>
    800050f6:	bdf5                	j	80004ff2 <end_op+0x52>

00000000800050f8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800050f8:	1101                	addi	sp,sp,-32
    800050fa:	ec06                	sd	ra,24(sp)
    800050fc:	e822                	sd	s0,16(sp)
    800050fe:	e426                	sd	s1,8(sp)
    80005100:	e04a                	sd	s2,0(sp)
    80005102:	1000                	addi	s0,sp,32
    80005104:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80005106:	00025917          	auipc	s2,0x25
    8000510a:	76a90913          	addi	s2,s2,1898 # 8002a870 <log>
    8000510e:	854a                	mv	a0,s2
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	ac2080e7          	jalr	-1342(ra) # 80000bd2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80005118:	02c92603          	lw	a2,44(s2)
    8000511c:	47f5                	li	a5,29
    8000511e:	06c7c563          	blt	a5,a2,80005188 <log_write+0x90>
    80005122:	00025797          	auipc	a5,0x25
    80005126:	76a7a783          	lw	a5,1898(a5) # 8002a88c <log+0x1c>
    8000512a:	37fd                	addiw	a5,a5,-1
    8000512c:	04f65e63          	bge	a2,a5,80005188 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005130:	00025797          	auipc	a5,0x25
    80005134:	7607a783          	lw	a5,1888(a5) # 8002a890 <log+0x20>
    80005138:	06f05063          	blez	a5,80005198 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000513c:	4781                	li	a5,0
    8000513e:	06c05563          	blez	a2,800051a8 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80005142:	44cc                	lw	a1,12(s1)
    80005144:	00025717          	auipc	a4,0x25
    80005148:	75c70713          	addi	a4,a4,1884 # 8002a8a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000514c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000514e:	4314                	lw	a3,0(a4)
    80005150:	04b68c63          	beq	a3,a1,800051a8 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005154:	2785                	addiw	a5,a5,1
    80005156:	0711                	addi	a4,a4,4
    80005158:	fef61be3          	bne	a2,a5,8000514e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000515c:	0621                	addi	a2,a2,8
    8000515e:	060a                	slli	a2,a2,0x2
    80005160:	00025797          	auipc	a5,0x25
    80005164:	71078793          	addi	a5,a5,1808 # 8002a870 <log>
    80005168:	963e                	add	a2,a2,a5
    8000516a:	44dc                	lw	a5,12(s1)
    8000516c:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	a74080e7          	jalr	-1420(ra) # 80003be4 <bpin>
    log.lh.n++;
    80005178:	00025717          	auipc	a4,0x25
    8000517c:	6f870713          	addi	a4,a4,1784 # 8002a870 <log>
    80005180:	575c                	lw	a5,44(a4)
    80005182:	2785                	addiw	a5,a5,1
    80005184:	d75c                	sw	a5,44(a4)
    80005186:	a835                	j	800051c2 <log_write+0xca>
    panic("too big a transaction");
    80005188:	00004517          	auipc	a0,0x4
    8000518c:	6a850513          	addi	a0,a0,1704 # 80009830 <syscalls+0x278>
    80005190:	ffffb097          	auipc	ra,0xffffb
    80005194:	39a080e7          	jalr	922(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80005198:	00004517          	auipc	a0,0x4
    8000519c:	6b050513          	addi	a0,a0,1712 # 80009848 <syscalls+0x290>
    800051a0:	ffffb097          	auipc	ra,0xffffb
    800051a4:	38a080e7          	jalr	906(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    800051a8:	00878713          	addi	a4,a5,8
    800051ac:	00271693          	slli	a3,a4,0x2
    800051b0:	00025717          	auipc	a4,0x25
    800051b4:	6c070713          	addi	a4,a4,1728 # 8002a870 <log>
    800051b8:	9736                	add	a4,a4,a3
    800051ba:	44d4                	lw	a3,12(s1)
    800051bc:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800051be:	faf608e3          	beq	a2,a5,8000516e <log_write+0x76>
  }
  release(&log.lock);
    800051c2:	00025517          	auipc	a0,0x25
    800051c6:	6ae50513          	addi	a0,a0,1710 # 8002a870 <log>
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	abc080e7          	jalr	-1348(ra) # 80000c86 <release>
}
    800051d2:	60e2                	ld	ra,24(sp)
    800051d4:	6442                	ld	s0,16(sp)
    800051d6:	64a2                	ld	s1,8(sp)
    800051d8:	6902                	ld	s2,0(sp)
    800051da:	6105                	addi	sp,sp,32
    800051dc:	8082                	ret

00000000800051de <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800051de:	1101                	addi	sp,sp,-32
    800051e0:	ec06                	sd	ra,24(sp)
    800051e2:	e822                	sd	s0,16(sp)
    800051e4:	e426                	sd	s1,8(sp)
    800051e6:	e04a                	sd	s2,0(sp)
    800051e8:	1000                	addi	s0,sp,32
    800051ea:	84aa                	mv	s1,a0
    800051ec:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800051ee:	00004597          	auipc	a1,0x4
    800051f2:	67a58593          	addi	a1,a1,1658 # 80009868 <syscalls+0x2b0>
    800051f6:	0521                	addi	a0,a0,8
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	94a080e7          	jalr	-1718(ra) # 80000b42 <initlock>
  lk->name = name;
    80005200:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80005204:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005208:	0204a423          	sw	zero,40(s1)
}
    8000520c:	60e2                	ld	ra,24(sp)
    8000520e:	6442                	ld	s0,16(sp)
    80005210:	64a2                	ld	s1,8(sp)
    80005212:	6902                	ld	s2,0(sp)
    80005214:	6105                	addi	sp,sp,32
    80005216:	8082                	ret

0000000080005218 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80005218:	1101                	addi	sp,sp,-32
    8000521a:	ec06                	sd	ra,24(sp)
    8000521c:	e822                	sd	s0,16(sp)
    8000521e:	e426                	sd	s1,8(sp)
    80005220:	e04a                	sd	s2,0(sp)
    80005222:	1000                	addi	s0,sp,32
    80005224:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005226:	00850913          	addi	s2,a0,8
    8000522a:	854a                	mv	a0,s2
    8000522c:	ffffc097          	auipc	ra,0xffffc
    80005230:	9a6080e7          	jalr	-1626(ra) # 80000bd2 <acquire>
  while (lk->locked) {
    80005234:	409c                	lw	a5,0(s1)
    80005236:	cb89                	beqz	a5,80005248 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005238:	85ca                	mv	a1,s2
    8000523a:	8526                	mv	a0,s1
    8000523c:	ffffe097          	auipc	ra,0xffffe
    80005240:	a46080e7          	jalr	-1466(ra) # 80002c82 <sleep>
  while (lk->locked) {
    80005244:	409c                	lw	a5,0(s1)
    80005246:	fbed                	bnez	a5,80005238 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005248:	4785                	li	a5,1
    8000524a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000524c:	ffffd097          	auipc	ra,0xffffd
    80005250:	18e080e7          	jalr	398(ra) # 800023da <myproc>
    80005254:	591c                	lw	a5,48(a0)
    80005256:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005258:	854a                	mv	a0,s2
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	a2c080e7          	jalr	-1492(ra) # 80000c86 <release>
}
    80005262:	60e2                	ld	ra,24(sp)
    80005264:	6442                	ld	s0,16(sp)
    80005266:	64a2                	ld	s1,8(sp)
    80005268:	6902                	ld	s2,0(sp)
    8000526a:	6105                	addi	sp,sp,32
    8000526c:	8082                	ret

000000008000526e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000526e:	1101                	addi	sp,sp,-32
    80005270:	ec06                	sd	ra,24(sp)
    80005272:	e822                	sd	s0,16(sp)
    80005274:	e426                	sd	s1,8(sp)
    80005276:	e04a                	sd	s2,0(sp)
    80005278:	1000                	addi	s0,sp,32
    8000527a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000527c:	00850913          	addi	s2,a0,8
    80005280:	854a                	mv	a0,s2
    80005282:	ffffc097          	auipc	ra,0xffffc
    80005286:	950080e7          	jalr	-1712(ra) # 80000bd2 <acquire>
  lk->locked = 0;
    8000528a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000528e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005292:	8526                	mv	a0,s1
    80005294:	ffffe097          	auipc	ra,0xffffe
    80005298:	b7a080e7          	jalr	-1158(ra) # 80002e0e <wakeup>
  release(&lk->lk);
    8000529c:	854a                	mv	a0,s2
    8000529e:	ffffc097          	auipc	ra,0xffffc
    800052a2:	9e8080e7          	jalr	-1560(ra) # 80000c86 <release>
}
    800052a6:	60e2                	ld	ra,24(sp)
    800052a8:	6442                	ld	s0,16(sp)
    800052aa:	64a2                	ld	s1,8(sp)
    800052ac:	6902                	ld	s2,0(sp)
    800052ae:	6105                	addi	sp,sp,32
    800052b0:	8082                	ret

00000000800052b2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800052b2:	7179                	addi	sp,sp,-48
    800052b4:	f406                	sd	ra,40(sp)
    800052b6:	f022                	sd	s0,32(sp)
    800052b8:	ec26                	sd	s1,24(sp)
    800052ba:	e84a                	sd	s2,16(sp)
    800052bc:	e44e                	sd	s3,8(sp)
    800052be:	1800                	addi	s0,sp,48
    800052c0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800052c2:	00850913          	addi	s2,a0,8
    800052c6:	854a                	mv	a0,s2
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	90a080e7          	jalr	-1782(ra) # 80000bd2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800052d0:	409c                	lw	a5,0(s1)
    800052d2:	ef99                	bnez	a5,800052f0 <holdingsleep+0x3e>
    800052d4:	4481                	li	s1,0
  release(&lk->lk);
    800052d6:	854a                	mv	a0,s2
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	9ae080e7          	jalr	-1618(ra) # 80000c86 <release>
  return r;
}
    800052e0:	8526                	mv	a0,s1
    800052e2:	70a2                	ld	ra,40(sp)
    800052e4:	7402                	ld	s0,32(sp)
    800052e6:	64e2                	ld	s1,24(sp)
    800052e8:	6942                	ld	s2,16(sp)
    800052ea:	69a2                	ld	s3,8(sp)
    800052ec:	6145                	addi	sp,sp,48
    800052ee:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800052f0:	0284a983          	lw	s3,40(s1)
    800052f4:	ffffd097          	auipc	ra,0xffffd
    800052f8:	0e6080e7          	jalr	230(ra) # 800023da <myproc>
    800052fc:	5904                	lw	s1,48(a0)
    800052fe:	413484b3          	sub	s1,s1,s3
    80005302:	0014b493          	seqz	s1,s1
    80005306:	bfc1                	j	800052d6 <holdingsleep+0x24>

0000000080005308 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80005308:	1141                	addi	sp,sp,-16
    8000530a:	e406                	sd	ra,8(sp)
    8000530c:	e022                	sd	s0,0(sp)
    8000530e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80005310:	00004597          	auipc	a1,0x4
    80005314:	56858593          	addi	a1,a1,1384 # 80009878 <syscalls+0x2c0>
    80005318:	00025517          	auipc	a0,0x25
    8000531c:	6a050513          	addi	a0,a0,1696 # 8002a9b8 <ftable>
    80005320:	ffffc097          	auipc	ra,0xffffc
    80005324:	822080e7          	jalr	-2014(ra) # 80000b42 <initlock>
}
    80005328:	60a2                	ld	ra,8(sp)
    8000532a:	6402                	ld	s0,0(sp)
    8000532c:	0141                	addi	sp,sp,16
    8000532e:	8082                	ret

0000000080005330 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005330:	1101                	addi	sp,sp,-32
    80005332:	ec06                	sd	ra,24(sp)
    80005334:	e822                	sd	s0,16(sp)
    80005336:	e426                	sd	s1,8(sp)
    80005338:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000533a:	00025517          	auipc	a0,0x25
    8000533e:	67e50513          	addi	a0,a0,1662 # 8002a9b8 <ftable>
    80005342:	ffffc097          	auipc	ra,0xffffc
    80005346:	890080e7          	jalr	-1904(ra) # 80000bd2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000534a:	00025497          	auipc	s1,0x25
    8000534e:	68648493          	addi	s1,s1,1670 # 8002a9d0 <ftable+0x18>
    80005352:	00026717          	auipc	a4,0x26
    80005356:	61e70713          	addi	a4,a4,1566 # 8002b970 <ftable+0xfb8>
    if(f->ref == 0){
    8000535a:	40dc                	lw	a5,4(s1)
    8000535c:	cf99                	beqz	a5,8000537a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000535e:	02848493          	addi	s1,s1,40
    80005362:	fee49ce3          	bne	s1,a4,8000535a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005366:	00025517          	auipc	a0,0x25
    8000536a:	65250513          	addi	a0,a0,1618 # 8002a9b8 <ftable>
    8000536e:	ffffc097          	auipc	ra,0xffffc
    80005372:	918080e7          	jalr	-1768(ra) # 80000c86 <release>
  return 0;
    80005376:	4481                	li	s1,0
    80005378:	a819                	j	8000538e <filealloc+0x5e>
      f->ref = 1;
    8000537a:	4785                	li	a5,1
    8000537c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000537e:	00025517          	auipc	a0,0x25
    80005382:	63a50513          	addi	a0,a0,1594 # 8002a9b8 <ftable>
    80005386:	ffffc097          	auipc	ra,0xffffc
    8000538a:	900080e7          	jalr	-1792(ra) # 80000c86 <release>
}
    8000538e:	8526                	mv	a0,s1
    80005390:	60e2                	ld	ra,24(sp)
    80005392:	6442                	ld	s0,16(sp)
    80005394:	64a2                	ld	s1,8(sp)
    80005396:	6105                	addi	sp,sp,32
    80005398:	8082                	ret

000000008000539a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000539a:	1101                	addi	sp,sp,-32
    8000539c:	ec06                	sd	ra,24(sp)
    8000539e:	e822                	sd	s0,16(sp)
    800053a0:	e426                	sd	s1,8(sp)
    800053a2:	1000                	addi	s0,sp,32
    800053a4:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800053a6:	00025517          	auipc	a0,0x25
    800053aa:	61250513          	addi	a0,a0,1554 # 8002a9b8 <ftable>
    800053ae:	ffffc097          	auipc	ra,0xffffc
    800053b2:	824080e7          	jalr	-2012(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    800053b6:	40dc                	lw	a5,4(s1)
    800053b8:	02f05263          	blez	a5,800053dc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800053bc:	2785                	addiw	a5,a5,1
    800053be:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800053c0:	00025517          	auipc	a0,0x25
    800053c4:	5f850513          	addi	a0,a0,1528 # 8002a9b8 <ftable>
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	8be080e7          	jalr	-1858(ra) # 80000c86 <release>
  return f;
}
    800053d0:	8526                	mv	a0,s1
    800053d2:	60e2                	ld	ra,24(sp)
    800053d4:	6442                	ld	s0,16(sp)
    800053d6:	64a2                	ld	s1,8(sp)
    800053d8:	6105                	addi	sp,sp,32
    800053da:	8082                	ret
    panic("filedup");
    800053dc:	00004517          	auipc	a0,0x4
    800053e0:	4a450513          	addi	a0,a0,1188 # 80009880 <syscalls+0x2c8>
    800053e4:	ffffb097          	auipc	ra,0xffffb
    800053e8:	146080e7          	jalr	326(ra) # 8000052a <panic>

00000000800053ec <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800053ec:	7139                	addi	sp,sp,-64
    800053ee:	fc06                	sd	ra,56(sp)
    800053f0:	f822                	sd	s0,48(sp)
    800053f2:	f426                	sd	s1,40(sp)
    800053f4:	f04a                	sd	s2,32(sp)
    800053f6:	ec4e                	sd	s3,24(sp)
    800053f8:	e852                	sd	s4,16(sp)
    800053fa:	e456                	sd	s5,8(sp)
    800053fc:	0080                	addi	s0,sp,64
    800053fe:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80005400:	00025517          	auipc	a0,0x25
    80005404:	5b850513          	addi	a0,a0,1464 # 8002a9b8 <ftable>
    80005408:	ffffb097          	auipc	ra,0xffffb
    8000540c:	7ca080e7          	jalr	1994(ra) # 80000bd2 <acquire>
  if(f->ref < 1)
    80005410:	40dc                	lw	a5,4(s1)
    80005412:	06f05163          	blez	a5,80005474 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80005416:	37fd                	addiw	a5,a5,-1
    80005418:	0007871b          	sext.w	a4,a5
    8000541c:	c0dc                	sw	a5,4(s1)
    8000541e:	06e04363          	bgtz	a4,80005484 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005422:	0004a903          	lw	s2,0(s1)
    80005426:	0094ca83          	lbu	s5,9(s1)
    8000542a:	0104ba03          	ld	s4,16(s1)
    8000542e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005432:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005436:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000543a:	00025517          	auipc	a0,0x25
    8000543e:	57e50513          	addi	a0,a0,1406 # 8002a9b8 <ftable>
    80005442:	ffffc097          	auipc	ra,0xffffc
    80005446:	844080e7          	jalr	-1980(ra) # 80000c86 <release>

  if(ff.type == FD_PIPE){
    8000544a:	4785                	li	a5,1
    8000544c:	04f90d63          	beq	s2,a5,800054a6 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005450:	3979                	addiw	s2,s2,-2
    80005452:	4785                	li	a5,1
    80005454:	0527e063          	bltu	a5,s2,80005494 <fileclose+0xa8>
    begin_op();
    80005458:	00000097          	auipc	ra,0x0
    8000545c:	ac8080e7          	jalr	-1336(ra) # 80004f20 <begin_op>
    iput(ff.ip);
    80005460:	854e                	mv	a0,s3
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	f72080e7          	jalr	-142(ra) # 800043d4 <iput>
    end_op();
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	b36080e7          	jalr	-1226(ra) # 80004fa0 <end_op>
    80005472:	a00d                	j	80005494 <fileclose+0xa8>
    panic("fileclose");
    80005474:	00004517          	auipc	a0,0x4
    80005478:	41450513          	addi	a0,a0,1044 # 80009888 <syscalls+0x2d0>
    8000547c:	ffffb097          	auipc	ra,0xffffb
    80005480:	0ae080e7          	jalr	174(ra) # 8000052a <panic>
    release(&ftable.lock);
    80005484:	00025517          	auipc	a0,0x25
    80005488:	53450513          	addi	a0,a0,1332 # 8002a9b8 <ftable>
    8000548c:	ffffb097          	auipc	ra,0xffffb
    80005490:	7fa080e7          	jalr	2042(ra) # 80000c86 <release>
  }
}
    80005494:	70e2                	ld	ra,56(sp)
    80005496:	7442                	ld	s0,48(sp)
    80005498:	74a2                	ld	s1,40(sp)
    8000549a:	7902                	ld	s2,32(sp)
    8000549c:	69e2                	ld	s3,24(sp)
    8000549e:	6a42                	ld	s4,16(sp)
    800054a0:	6aa2                	ld	s5,8(sp)
    800054a2:	6121                	addi	sp,sp,64
    800054a4:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800054a6:	85d6                	mv	a1,s5
    800054a8:	8552                	mv	a0,s4
    800054aa:	00000097          	auipc	ra,0x0
    800054ae:	556080e7          	jalr	1366(ra) # 80005a00 <pipeclose>
    800054b2:	b7cd                	j	80005494 <fileclose+0xa8>

00000000800054b4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800054b4:	715d                	addi	sp,sp,-80
    800054b6:	e486                	sd	ra,72(sp)
    800054b8:	e0a2                	sd	s0,64(sp)
    800054ba:	fc26                	sd	s1,56(sp)
    800054bc:	f84a                	sd	s2,48(sp)
    800054be:	f44e                	sd	s3,40(sp)
    800054c0:	0880                	addi	s0,sp,80
    800054c2:	84aa                	mv	s1,a0
    800054c4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	f14080e7          	jalr	-236(ra) # 800023da <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800054ce:	409c                	lw	a5,0(s1)
    800054d0:	37f9                	addiw	a5,a5,-2
    800054d2:	4705                	li	a4,1
    800054d4:	04f76763          	bltu	a4,a5,80005522 <filestat+0x6e>
    800054d8:	892a                	mv	s2,a0
    ilock(f->ip);
    800054da:	6c88                	ld	a0,24(s1)
    800054dc:	fffff097          	auipc	ra,0xfffff
    800054e0:	d3e080e7          	jalr	-706(ra) # 8000421a <ilock>
    stati(f->ip, &st);
    800054e4:	fb840593          	addi	a1,s0,-72
    800054e8:	6c88                	ld	a0,24(s1)
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	fba080e7          	jalr	-70(ra) # 800044a4 <stati>
    iunlock(f->ip);
    800054f2:	6c88                	ld	a0,24(s1)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	de8080e7          	jalr	-536(ra) # 800042dc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800054fc:	46e1                	li	a3,24
    800054fe:	fb840613          	addi	a2,s0,-72
    80005502:	85ce                	mv	a1,s3
    80005504:	05093503          	ld	a0,80(s2)
    80005508:	ffffc097          	auipc	ra,0xffffc
    8000550c:	f82080e7          	jalr	-126(ra) # 8000148a <copyout>
    80005510:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80005514:	60a6                	ld	ra,72(sp)
    80005516:	6406                	ld	s0,64(sp)
    80005518:	74e2                	ld	s1,56(sp)
    8000551a:	7942                	ld	s2,48(sp)
    8000551c:	79a2                	ld	s3,40(sp)
    8000551e:	6161                	addi	sp,sp,80
    80005520:	8082                	ret
  return -1;
    80005522:	557d                	li	a0,-1
    80005524:	bfc5                	j	80005514 <filestat+0x60>

0000000080005526 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005526:	7179                	addi	sp,sp,-48
    80005528:	f406                	sd	ra,40(sp)
    8000552a:	f022                	sd	s0,32(sp)
    8000552c:	ec26                	sd	s1,24(sp)
    8000552e:	e84a                	sd	s2,16(sp)
    80005530:	e44e                	sd	s3,8(sp)
    80005532:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005534:	00854783          	lbu	a5,8(a0)
    80005538:	c3d5                	beqz	a5,800055dc <fileread+0xb6>
    8000553a:	84aa                	mv	s1,a0
    8000553c:	89ae                	mv	s3,a1
    8000553e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005540:	411c                	lw	a5,0(a0)
    80005542:	4705                	li	a4,1
    80005544:	04e78963          	beq	a5,a4,80005596 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005548:	470d                	li	a4,3
    8000554a:	04e78d63          	beq	a5,a4,800055a4 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000554e:	4709                	li	a4,2
    80005550:	06e79e63          	bne	a5,a4,800055cc <fileread+0xa6>
    ilock(f->ip);
    80005554:	6d08                	ld	a0,24(a0)
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	cc4080e7          	jalr	-828(ra) # 8000421a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000555e:	874a                	mv	a4,s2
    80005560:	5094                	lw	a3,32(s1)
    80005562:	864e                	mv	a2,s3
    80005564:	4585                	li	a1,1
    80005566:	6c88                	ld	a0,24(s1)
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	f66080e7          	jalr	-154(ra) # 800044ce <readi>
    80005570:	892a                	mv	s2,a0
    80005572:	00a05563          	blez	a0,8000557c <fileread+0x56>
      f->off += r;
    80005576:	509c                	lw	a5,32(s1)
    80005578:	9fa9                	addw	a5,a5,a0
    8000557a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000557c:	6c88                	ld	a0,24(s1)
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	d5e080e7          	jalr	-674(ra) # 800042dc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005586:	854a                	mv	a0,s2
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	64e2                	ld	s1,24(sp)
    8000558e:	6942                	ld	s2,16(sp)
    80005590:	69a2                	ld	s3,8(sp)
    80005592:	6145                	addi	sp,sp,48
    80005594:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005596:	6908                	ld	a0,16(a0)
    80005598:	00000097          	auipc	ra,0x0
    8000559c:	5ca080e7          	jalr	1482(ra) # 80005b62 <piperead>
    800055a0:	892a                	mv	s2,a0
    800055a2:	b7d5                	j	80005586 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800055a4:	02451783          	lh	a5,36(a0)
    800055a8:	03079693          	slli	a3,a5,0x30
    800055ac:	92c1                	srli	a3,a3,0x30
    800055ae:	4725                	li	a4,9
    800055b0:	02d76863          	bltu	a4,a3,800055e0 <fileread+0xba>
    800055b4:	0792                	slli	a5,a5,0x4
    800055b6:	00025717          	auipc	a4,0x25
    800055ba:	36270713          	addi	a4,a4,866 # 8002a918 <devsw>
    800055be:	97ba                	add	a5,a5,a4
    800055c0:	639c                	ld	a5,0(a5)
    800055c2:	c38d                	beqz	a5,800055e4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800055c4:	4505                	li	a0,1
    800055c6:	9782                	jalr	a5
    800055c8:	892a                	mv	s2,a0
    800055ca:	bf75                	j	80005586 <fileread+0x60>
    panic("fileread");
    800055cc:	00004517          	auipc	a0,0x4
    800055d0:	2cc50513          	addi	a0,a0,716 # 80009898 <syscalls+0x2e0>
    800055d4:	ffffb097          	auipc	ra,0xffffb
    800055d8:	f56080e7          	jalr	-170(ra) # 8000052a <panic>
    return -1;
    800055dc:	597d                	li	s2,-1
    800055de:	b765                	j	80005586 <fileread+0x60>
      return -1;
    800055e0:	597d                	li	s2,-1
    800055e2:	b755                	j	80005586 <fileread+0x60>
    800055e4:	597d                	li	s2,-1
    800055e6:	b745                	j	80005586 <fileread+0x60>

00000000800055e8 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800055e8:	715d                	addi	sp,sp,-80
    800055ea:	e486                	sd	ra,72(sp)
    800055ec:	e0a2                	sd	s0,64(sp)
    800055ee:	fc26                	sd	s1,56(sp)
    800055f0:	f84a                	sd	s2,48(sp)
    800055f2:	f44e                	sd	s3,40(sp)
    800055f4:	f052                	sd	s4,32(sp)
    800055f6:	ec56                	sd	s5,24(sp)
    800055f8:	e85a                	sd	s6,16(sp)
    800055fa:	e45e                	sd	s7,8(sp)
    800055fc:	e062                	sd	s8,0(sp)
    800055fe:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005600:	00954783          	lbu	a5,9(a0)
    80005604:	10078663          	beqz	a5,80005710 <filewrite+0x128>
    80005608:	892a                	mv	s2,a0
    8000560a:	8aae                	mv	s5,a1
    8000560c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000560e:	411c                	lw	a5,0(a0)
    80005610:	4705                	li	a4,1
    80005612:	02e78263          	beq	a5,a4,80005636 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005616:	470d                	li	a4,3
    80005618:	02e78663          	beq	a5,a4,80005644 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000561c:	4709                	li	a4,2
    8000561e:	0ee79163          	bne	a5,a4,80005700 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005622:	0ac05d63          	blez	a2,800056dc <filewrite+0xf4>
    int i = 0;
    80005626:	4981                	li	s3,0
    80005628:	6b05                	lui	s6,0x1
    8000562a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000562e:	6b85                	lui	s7,0x1
    80005630:	c00b8b9b          	addiw	s7,s7,-1024
    80005634:	a861                	j	800056cc <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005636:	6908                	ld	a0,16(a0)
    80005638:	00000097          	auipc	ra,0x0
    8000563c:	438080e7          	jalr	1080(ra) # 80005a70 <pipewrite>
    80005640:	8a2a                	mv	s4,a0
    80005642:	a045                	j	800056e2 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005644:	02451783          	lh	a5,36(a0)
    80005648:	03079693          	slli	a3,a5,0x30
    8000564c:	92c1                	srli	a3,a3,0x30
    8000564e:	4725                	li	a4,9
    80005650:	0cd76263          	bltu	a4,a3,80005714 <filewrite+0x12c>
    80005654:	0792                	slli	a5,a5,0x4
    80005656:	00025717          	auipc	a4,0x25
    8000565a:	2c270713          	addi	a4,a4,706 # 8002a918 <devsw>
    8000565e:	97ba                	add	a5,a5,a4
    80005660:	679c                	ld	a5,8(a5)
    80005662:	cbdd                	beqz	a5,80005718 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005664:	4505                	li	a0,1
    80005666:	9782                	jalr	a5
    80005668:	8a2a                	mv	s4,a0
    8000566a:	a8a5                	j	800056e2 <filewrite+0xfa>
    8000566c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005670:	00000097          	auipc	ra,0x0
    80005674:	8b0080e7          	jalr	-1872(ra) # 80004f20 <begin_op>
      ilock(f->ip);
    80005678:	01893503          	ld	a0,24(s2)
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	b9e080e7          	jalr	-1122(ra) # 8000421a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005684:	8762                	mv	a4,s8
    80005686:	02092683          	lw	a3,32(s2)
    8000568a:	01598633          	add	a2,s3,s5
    8000568e:	4585                	li	a1,1
    80005690:	01893503          	ld	a0,24(s2)
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	f32080e7          	jalr	-206(ra) # 800045c6 <writei>
    8000569c:	84aa                	mv	s1,a0
    8000569e:	00a05763          	blez	a0,800056ac <filewrite+0xc4>
        f->off += r;
    800056a2:	02092783          	lw	a5,32(s2)
    800056a6:	9fa9                	addw	a5,a5,a0
    800056a8:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800056ac:	01893503          	ld	a0,24(s2)
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	c2c080e7          	jalr	-980(ra) # 800042dc <iunlock>
      end_op();
    800056b8:	00000097          	auipc	ra,0x0
    800056bc:	8e8080e7          	jalr	-1816(ra) # 80004fa0 <end_op>

      if(r != n1){
    800056c0:	009c1f63          	bne	s8,s1,800056de <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800056c4:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800056c8:	0149db63          	bge	s3,s4,800056de <filewrite+0xf6>
      int n1 = n - i;
    800056cc:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800056d0:	84be                	mv	s1,a5
    800056d2:	2781                	sext.w	a5,a5
    800056d4:	f8fb5ce3          	bge	s6,a5,8000566c <filewrite+0x84>
    800056d8:	84de                	mv	s1,s7
    800056da:	bf49                	j	8000566c <filewrite+0x84>
    int i = 0;
    800056dc:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800056de:	013a1f63          	bne	s4,s3,800056fc <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800056e2:	8552                	mv	a0,s4
    800056e4:	60a6                	ld	ra,72(sp)
    800056e6:	6406                	ld	s0,64(sp)
    800056e8:	74e2                	ld	s1,56(sp)
    800056ea:	7942                	ld	s2,48(sp)
    800056ec:	79a2                	ld	s3,40(sp)
    800056ee:	7a02                	ld	s4,32(sp)
    800056f0:	6ae2                	ld	s5,24(sp)
    800056f2:	6b42                	ld	s6,16(sp)
    800056f4:	6ba2                	ld	s7,8(sp)
    800056f6:	6c02                	ld	s8,0(sp)
    800056f8:	6161                	addi	sp,sp,80
    800056fa:	8082                	ret
    ret = (i == n ? n : -1);
    800056fc:	5a7d                	li	s4,-1
    800056fe:	b7d5                	j	800056e2 <filewrite+0xfa>
    panic("filewrite");
    80005700:	00004517          	auipc	a0,0x4
    80005704:	1a850513          	addi	a0,a0,424 # 800098a8 <syscalls+0x2f0>
    80005708:	ffffb097          	auipc	ra,0xffffb
    8000570c:	e22080e7          	jalr	-478(ra) # 8000052a <panic>
    return -1;
    80005710:	5a7d                	li	s4,-1
    80005712:	bfc1                	j	800056e2 <filewrite+0xfa>
      return -1;
    80005714:	5a7d                	li	s4,-1
    80005716:	b7f1                	j	800056e2 <filewrite+0xfa>
    80005718:	5a7d                	li	s4,-1
    8000571a:	b7e1                	j	800056e2 <filewrite+0xfa>

000000008000571c <kfileread>:

// Read from file f.
// addr is a kernel virtual address.
int
kfileread(struct file *f, uint64 addr, int n)
{
    8000571c:	7179                	addi	sp,sp,-48
    8000571e:	f406                	sd	ra,40(sp)
    80005720:	f022                	sd	s0,32(sp)
    80005722:	ec26                	sd	s1,24(sp)
    80005724:	e84a                	sd	s2,16(sp)
    80005726:	e44e                	sd	s3,8(sp)
    80005728:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000572a:	00854783          	lbu	a5,8(a0)
    8000572e:	c3d5                	beqz	a5,800057d2 <kfileread+0xb6>
    80005730:	84aa                	mv	s1,a0
    80005732:	89ae                	mv	s3,a1
    80005734:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005736:	411c                	lw	a5,0(a0)
    80005738:	4705                	li	a4,1
    8000573a:	04e78963          	beq	a5,a4,8000578c <kfileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000573e:	470d                	li	a4,3
    80005740:	04e78d63          	beq	a5,a4,8000579a <kfileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005744:	4709                	li	a4,2
    80005746:	06e79e63          	bne	a5,a4,800057c2 <kfileread+0xa6>
    ilock(f->ip);
    8000574a:	6d08                	ld	a0,24(a0)
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	ace080e7          	jalr	-1330(ra) # 8000421a <ilock>
    if((r = readi(f->ip, 0, addr, f->off, n)) > 0)
    80005754:	874a                	mv	a4,s2
    80005756:	5094                	lw	a3,32(s1)
    80005758:	864e                	mv	a2,s3
    8000575a:	4581                	li	a1,0
    8000575c:	6c88                	ld	a0,24(s1)
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	d70080e7          	jalr	-656(ra) # 800044ce <readi>
    80005766:	892a                	mv	s2,a0
    80005768:	00a05563          	blez	a0,80005772 <kfileread+0x56>
      f->off += r;
    8000576c:	509c                	lw	a5,32(s1)
    8000576e:	9fa9                	addw	a5,a5,a0
    80005770:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80005772:	6c88                	ld	a0,24(s1)
    80005774:	fffff097          	auipc	ra,0xfffff
    80005778:	b68080e7          	jalr	-1176(ra) # 800042dc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000577c:	854a                	mv	a0,s2
    8000577e:	70a2                	ld	ra,40(sp)
    80005780:	7402                	ld	s0,32(sp)
    80005782:	64e2                	ld	s1,24(sp)
    80005784:	6942                	ld	s2,16(sp)
    80005786:	69a2                	ld	s3,8(sp)
    80005788:	6145                	addi	sp,sp,48
    8000578a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000578c:	6908                	ld	a0,16(a0)
    8000578e:	00000097          	auipc	ra,0x0
    80005792:	3d4080e7          	jalr	980(ra) # 80005b62 <piperead>
    80005796:	892a                	mv	s2,a0
    80005798:	b7d5                	j	8000577c <kfileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000579a:	02451783          	lh	a5,36(a0)
    8000579e:	03079693          	slli	a3,a5,0x30
    800057a2:	92c1                	srli	a3,a3,0x30
    800057a4:	4725                	li	a4,9
    800057a6:	02d76863          	bltu	a4,a3,800057d6 <kfileread+0xba>
    800057aa:	0792                	slli	a5,a5,0x4
    800057ac:	00025717          	auipc	a4,0x25
    800057b0:	16c70713          	addi	a4,a4,364 # 8002a918 <devsw>
    800057b4:	97ba                	add	a5,a5,a4
    800057b6:	639c                	ld	a5,0(a5)
    800057b8:	c38d                	beqz	a5,800057da <kfileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800057ba:	4505                	li	a0,1
    800057bc:	9782                	jalr	a5
    800057be:	892a                	mv	s2,a0
    800057c0:	bf75                	j	8000577c <kfileread+0x60>
    panic("fileread");
    800057c2:	00004517          	auipc	a0,0x4
    800057c6:	0d650513          	addi	a0,a0,214 # 80009898 <syscalls+0x2e0>
    800057ca:	ffffb097          	auipc	ra,0xffffb
    800057ce:	d60080e7          	jalr	-672(ra) # 8000052a <panic>
    return -1;
    800057d2:	597d                	li	s2,-1
    800057d4:	b765                	j	8000577c <kfileread+0x60>
      return -1;
    800057d6:	597d                	li	s2,-1
    800057d8:	b755                	j	8000577c <kfileread+0x60>
    800057da:	597d                	li	s2,-1
    800057dc:	b745                	j	8000577c <kfileread+0x60>

00000000800057de <kfilewrite>:

// Write to file f.
// addr is a kernel virtual address.
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    800057de:	715d                	addi	sp,sp,-80
    800057e0:	e486                	sd	ra,72(sp)
    800057e2:	e0a2                	sd	s0,64(sp)
    800057e4:	fc26                	sd	s1,56(sp)
    800057e6:	f84a                	sd	s2,48(sp)
    800057e8:	f44e                	sd	s3,40(sp)
    800057ea:	f052                	sd	s4,32(sp)
    800057ec:	ec56                	sd	s5,24(sp)
    800057ee:	e85a                	sd	s6,16(sp)
    800057f0:	e45e                	sd	s7,8(sp)
    800057f2:	e062                	sd	s8,0(sp)
    800057f4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    800057f6:	00954783          	lbu	a5,9(a0)
    800057fa:	12078063          	beqz	a5,8000591a <kfilewrite+0x13c>
    800057fe:	892a                	mv	s2,a0
    80005800:	8aae                	mv	s5,a1
    80005802:	8a32                	mv	s4,a2
    return -1;
  }

  if(f->type == FD_PIPE){
    80005804:	411c                	lw	a5,0(a0)
    80005806:	4705                	li	a4,1
    80005808:	02e78263          	beq	a5,a4,8000582c <kfilewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000580c:	470d                	li	a4,3
    8000580e:	02e78663          	beq	a5,a4,8000583a <kfilewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005812:	4709                	li	a4,2
    80005814:	0ee79b63          	bne	a5,a4,8000590a <kfilewrite+0x12c>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005818:	0ec05563          	blez	a2,80005902 <kfilewrite+0x124>
    int i = 0;
    8000581c:	4981                	li	s3,0
    8000581e:	6b05                	lui	s6,0x1
    80005820:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005824:	6b85                	lui	s7,0x1
    80005826:	c00b8b9b          	addiw	s7,s7,-1024
    8000582a:	a861                	j	800058c2 <kfilewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000582c:	6908                	ld	a0,16(a0)
    8000582e:	00000097          	auipc	ra,0x0
    80005832:	242080e7          	jalr	578(ra) # 80005a70 <pipewrite>
    80005836:	8a2a                	mv	s4,a0
    80005838:	a845                	j	800058e8 <kfilewrite+0x10a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    8000583a:	02451783          	lh	a5,36(a0)
    8000583e:	03079693          	slli	a3,a5,0x30
    80005842:	92c1                	srli	a3,a3,0x30
    80005844:	4725                	li	a4,9
    80005846:	0cd76c63          	bltu	a4,a3,8000591e <kfilewrite+0x140>
    8000584a:	0792                	slli	a5,a5,0x4
    8000584c:	00025717          	auipc	a4,0x25
    80005850:	0cc70713          	addi	a4,a4,204 # 8002a918 <devsw>
    80005854:	97ba                	add	a5,a5,a4
    80005856:	679c                	ld	a5,8(a5)
    80005858:	c7e9                	beqz	a5,80005922 <kfilewrite+0x144>
    ret = devsw[f->major].write(1, addr, n);
    8000585a:	4505                	li	a0,1
    8000585c:	9782                	jalr	a5
    8000585e:	8a2a                	mv	s4,a0
    80005860:	a061                	j	800058e8 <kfilewrite+0x10a>
    80005862:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	6ba080e7          	jalr	1722(ra) # 80004f20 <begin_op>
      ilock(f->ip);
    8000586e:	01893503          	ld	a0,24(s2)
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	9a8080e7          	jalr	-1624(ra) # 8000421a <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    8000587a:	8762                	mv	a4,s8
    8000587c:	02092683          	lw	a3,32(s2)
    80005880:	01598633          	add	a2,s3,s5
    80005884:	4581                	li	a1,0
    80005886:	01893503          	ld	a0,24(s2)
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	d3c080e7          	jalr	-708(ra) # 800045c6 <writei>
    80005892:	84aa                	mv	s1,a0
    80005894:	00a05763          	blez	a0,800058a2 <kfilewrite+0xc4>
        f->off += r;
    80005898:	02092783          	lw	a5,32(s2)
    8000589c:	9fa9                	addw	a5,a5,a0
    8000589e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800058a2:	01893503          	ld	a0,24(s2)
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	a36080e7          	jalr	-1482(ra) # 800042dc <iunlock>
      end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	6f2080e7          	jalr	1778(ra) # 80004fa0 <end_op>

      if(r != n1){
    800058b6:	009c1e63          	bne	s8,s1,800058d2 <kfilewrite+0xf4>
            printf("here??? %d", r);
        // error from writei
        break;
      }
      i += r;
    800058ba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800058be:	0349d363          	bge	s3,s4,800058e4 <kfilewrite+0x106>
      int n1 = n - i;
    800058c2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800058c6:	84be                	mv	s1,a5
    800058c8:	2781                	sext.w	a5,a5
    800058ca:	f8fb5ce3          	bge	s6,a5,80005862 <kfilewrite+0x84>
    800058ce:	84de                	mv	s1,s7
    800058d0:	bf49                	j	80005862 <kfilewrite+0x84>
            printf("here??? %d", r);
    800058d2:	85a6                	mv	a1,s1
    800058d4:	00004517          	auipc	a0,0x4
    800058d8:	fe450513          	addi	a0,a0,-28 # 800098b8 <syscalls+0x300>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	c98080e7          	jalr	-872(ra) # 80000574 <printf>
    }

    ret = (i == n ? n : -1);
    800058e4:	033a1163          	bne	s4,s3,80005906 <kfilewrite+0x128>
  } else {
    panic("filewrite");
  }

  return ret;
    800058e8:	8552                	mv	a0,s4
    800058ea:	60a6                	ld	ra,72(sp)
    800058ec:	6406                	ld	s0,64(sp)
    800058ee:	74e2                	ld	s1,56(sp)
    800058f0:	7942                	ld	s2,48(sp)
    800058f2:	79a2                	ld	s3,40(sp)
    800058f4:	7a02                	ld	s4,32(sp)
    800058f6:	6ae2                	ld	s5,24(sp)
    800058f8:	6b42                	ld	s6,16(sp)
    800058fa:	6ba2                	ld	s7,8(sp)
    800058fc:	6c02                	ld	s8,0(sp)
    800058fe:	6161                	addi	sp,sp,80
    80005900:	8082                	ret
    int i = 0;
    80005902:	4981                	li	s3,0
    80005904:	b7c5                	j	800058e4 <kfilewrite+0x106>
    ret = (i == n ? n : -1);
    80005906:	5a7d                	li	s4,-1
    80005908:	b7c5                	j	800058e8 <kfilewrite+0x10a>
    panic("filewrite");
    8000590a:	00004517          	auipc	a0,0x4
    8000590e:	f9e50513          	addi	a0,a0,-98 # 800098a8 <syscalls+0x2f0>
    80005912:	ffffb097          	auipc	ra,0xffffb
    80005916:	c18080e7          	jalr	-1000(ra) # 8000052a <panic>
    return -1;
    8000591a:	5a7d                	li	s4,-1
    8000591c:	b7f1                	j	800058e8 <kfilewrite+0x10a>
      return -1;
    8000591e:	5a7d                	li	s4,-1
    80005920:	b7e1                	j	800058e8 <kfilewrite+0x10a>
    80005922:	5a7d                	li	s4,-1
    80005924:	b7d1                	j	800058e8 <kfilewrite+0x10a>

0000000080005926 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005926:	7179                	addi	sp,sp,-48
    80005928:	f406                	sd	ra,40(sp)
    8000592a:	f022                	sd	s0,32(sp)
    8000592c:	ec26                	sd	s1,24(sp)
    8000592e:	e84a                	sd	s2,16(sp)
    80005930:	e44e                	sd	s3,8(sp)
    80005932:	e052                	sd	s4,0(sp)
    80005934:	1800                	addi	s0,sp,48
    80005936:	84aa                	mv	s1,a0
    80005938:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000593a:	0005b023          	sd	zero,0(a1)
    8000593e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005942:	00000097          	auipc	ra,0x0
    80005946:	9ee080e7          	jalr	-1554(ra) # 80005330 <filealloc>
    8000594a:	e088                	sd	a0,0(s1)
    8000594c:	c551                	beqz	a0,800059d8 <pipealloc+0xb2>
    8000594e:	00000097          	auipc	ra,0x0
    80005952:	9e2080e7          	jalr	-1566(ra) # 80005330 <filealloc>
    80005956:	00aa3023          	sd	a0,0(s4)
    8000595a:	c92d                	beqz	a0,800059cc <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000595c:	ffffb097          	auipc	ra,0xffffb
    80005960:	186080e7          	jalr	390(ra) # 80000ae2 <kalloc>
    80005964:	892a                	mv	s2,a0
    80005966:	c125                	beqz	a0,800059c6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005968:	4985                	li	s3,1
    8000596a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000596e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005972:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005976:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000597a:	00004597          	auipc	a1,0x4
    8000597e:	f4e58593          	addi	a1,a1,-178 # 800098c8 <syscalls+0x310>
    80005982:	ffffb097          	auipc	ra,0xffffb
    80005986:	1c0080e7          	jalr	448(ra) # 80000b42 <initlock>
  (*f0)->type = FD_PIPE;
    8000598a:	609c                	ld	a5,0(s1)
    8000598c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005990:	609c                	ld	a5,0(s1)
    80005992:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005996:	609c                	ld	a5,0(s1)
    80005998:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000599c:	609c                	ld	a5,0(s1)
    8000599e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800059a2:	000a3783          	ld	a5,0(s4)
    800059a6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800059aa:	000a3783          	ld	a5,0(s4)
    800059ae:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800059b2:	000a3783          	ld	a5,0(s4)
    800059b6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800059ba:	000a3783          	ld	a5,0(s4)
    800059be:	0127b823          	sd	s2,16(a5)
  return 0;
    800059c2:	4501                	li	a0,0
    800059c4:	a025                	j	800059ec <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800059c6:	6088                	ld	a0,0(s1)
    800059c8:	e501                	bnez	a0,800059d0 <pipealloc+0xaa>
    800059ca:	a039                	j	800059d8 <pipealloc+0xb2>
    800059cc:	6088                	ld	a0,0(s1)
    800059ce:	c51d                	beqz	a0,800059fc <pipealloc+0xd6>
    fileclose(*f0);
    800059d0:	00000097          	auipc	ra,0x0
    800059d4:	a1c080e7          	jalr	-1508(ra) # 800053ec <fileclose>
  if(*f1)
    800059d8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800059dc:	557d                	li	a0,-1
  if(*f1)
    800059de:	c799                	beqz	a5,800059ec <pipealloc+0xc6>
    fileclose(*f1);
    800059e0:	853e                	mv	a0,a5
    800059e2:	00000097          	auipc	ra,0x0
    800059e6:	a0a080e7          	jalr	-1526(ra) # 800053ec <fileclose>
  return -1;
    800059ea:	557d                	li	a0,-1
}
    800059ec:	70a2                	ld	ra,40(sp)
    800059ee:	7402                	ld	s0,32(sp)
    800059f0:	64e2                	ld	s1,24(sp)
    800059f2:	6942                	ld	s2,16(sp)
    800059f4:	69a2                	ld	s3,8(sp)
    800059f6:	6a02                	ld	s4,0(sp)
    800059f8:	6145                	addi	sp,sp,48
    800059fa:	8082                	ret
  return -1;
    800059fc:	557d                	li	a0,-1
    800059fe:	b7fd                	j	800059ec <pipealloc+0xc6>

0000000080005a00 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80005a00:	1101                	addi	sp,sp,-32
    80005a02:	ec06                	sd	ra,24(sp)
    80005a04:	e822                	sd	s0,16(sp)
    80005a06:	e426                	sd	s1,8(sp)
    80005a08:	e04a                	sd	s2,0(sp)
    80005a0a:	1000                	addi	s0,sp,32
    80005a0c:	84aa                	mv	s1,a0
    80005a0e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005a10:	ffffb097          	auipc	ra,0xffffb
    80005a14:	1c2080e7          	jalr	450(ra) # 80000bd2 <acquire>
  if(writable){
    80005a18:	02090d63          	beqz	s2,80005a52 <pipeclose+0x52>
    pi->writeopen = 0;
    80005a1c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005a20:	21848513          	addi	a0,s1,536
    80005a24:	ffffd097          	auipc	ra,0xffffd
    80005a28:	3ea080e7          	jalr	1002(ra) # 80002e0e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005a2c:	2204b783          	ld	a5,544(s1)
    80005a30:	eb95                	bnez	a5,80005a64 <pipeclose+0x64>
    release(&pi->lock);
    80005a32:	8526                	mv	a0,s1
    80005a34:	ffffb097          	auipc	ra,0xffffb
    80005a38:	252080e7          	jalr	594(ra) # 80000c86 <release>
    kfree((char*)pi);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	f98080e7          	jalr	-104(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80005a46:	60e2                	ld	ra,24(sp)
    80005a48:	6442                	ld	s0,16(sp)
    80005a4a:	64a2                	ld	s1,8(sp)
    80005a4c:	6902                	ld	s2,0(sp)
    80005a4e:	6105                	addi	sp,sp,32
    80005a50:	8082                	ret
    pi->readopen = 0;
    80005a52:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005a56:	21c48513          	addi	a0,s1,540
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	3b4080e7          	jalr	948(ra) # 80002e0e <wakeup>
    80005a62:	b7e9                	j	80005a2c <pipeclose+0x2c>
    release(&pi->lock);
    80005a64:	8526                	mv	a0,s1
    80005a66:	ffffb097          	auipc	ra,0xffffb
    80005a6a:	220080e7          	jalr	544(ra) # 80000c86 <release>
}
    80005a6e:	bfe1                	j	80005a46 <pipeclose+0x46>

0000000080005a70 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005a70:	711d                	addi	sp,sp,-96
    80005a72:	ec86                	sd	ra,88(sp)
    80005a74:	e8a2                	sd	s0,80(sp)
    80005a76:	e4a6                	sd	s1,72(sp)
    80005a78:	e0ca                	sd	s2,64(sp)
    80005a7a:	fc4e                	sd	s3,56(sp)
    80005a7c:	f852                	sd	s4,48(sp)
    80005a7e:	f456                	sd	s5,40(sp)
    80005a80:	f05a                	sd	s6,32(sp)
    80005a82:	ec5e                	sd	s7,24(sp)
    80005a84:	e862                	sd	s8,16(sp)
    80005a86:	1080                	addi	s0,sp,96
    80005a88:	84aa                	mv	s1,a0
    80005a8a:	8aae                	mv	s5,a1
    80005a8c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	94c080e7          	jalr	-1716(ra) # 800023da <myproc>
    80005a96:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005a98:	8526                	mv	a0,s1
    80005a9a:	ffffb097          	auipc	ra,0xffffb
    80005a9e:	138080e7          	jalr	312(ra) # 80000bd2 <acquire>
  while(i < n){
    80005aa2:	0b405363          	blez	s4,80005b48 <pipewrite+0xd8>
  int i = 0;
    80005aa6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005aa8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005aaa:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005aae:	21c48b93          	addi	s7,s1,540
    80005ab2:	a089                	j	80005af4 <pipewrite+0x84>
      release(&pi->lock);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	1d0080e7          	jalr	464(ra) # 80000c86 <release>
      return -1;
    80005abe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005ac0:	854a                	mv	a0,s2
    80005ac2:	60e6                	ld	ra,88(sp)
    80005ac4:	6446                	ld	s0,80(sp)
    80005ac6:	64a6                	ld	s1,72(sp)
    80005ac8:	6906                	ld	s2,64(sp)
    80005aca:	79e2                	ld	s3,56(sp)
    80005acc:	7a42                	ld	s4,48(sp)
    80005ace:	7aa2                	ld	s5,40(sp)
    80005ad0:	7b02                	ld	s6,32(sp)
    80005ad2:	6be2                	ld	s7,24(sp)
    80005ad4:	6c42                	ld	s8,16(sp)
    80005ad6:	6125                	addi	sp,sp,96
    80005ad8:	8082                	ret
      wakeup(&pi->nread);
    80005ada:	8562                	mv	a0,s8
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	332080e7          	jalr	818(ra) # 80002e0e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005ae4:	85a6                	mv	a1,s1
    80005ae6:	855e                	mv	a0,s7
    80005ae8:	ffffd097          	auipc	ra,0xffffd
    80005aec:	19a080e7          	jalr	410(ra) # 80002c82 <sleep>
  while(i < n){
    80005af0:	05495d63          	bge	s2,s4,80005b4a <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80005af4:	2204a783          	lw	a5,544(s1)
    80005af8:	dfd5                	beqz	a5,80005ab4 <pipewrite+0x44>
    80005afa:	0289a783          	lw	a5,40(s3)
    80005afe:	fbdd                	bnez	a5,80005ab4 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005b00:	2184a783          	lw	a5,536(s1)
    80005b04:	21c4a703          	lw	a4,540(s1)
    80005b08:	2007879b          	addiw	a5,a5,512
    80005b0c:	fcf707e3          	beq	a4,a5,80005ada <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005b10:	4685                	li	a3,1
    80005b12:	01590633          	add	a2,s2,s5
    80005b16:	faf40593          	addi	a1,s0,-81
    80005b1a:	0509b503          	ld	a0,80(s3)
    80005b1e:	ffffc097          	auipc	ra,0xffffc
    80005b22:	9f8080e7          	jalr	-1544(ra) # 80001516 <copyin>
    80005b26:	03650263          	beq	a0,s6,80005b4a <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005b2a:	21c4a783          	lw	a5,540(s1)
    80005b2e:	0017871b          	addiw	a4,a5,1
    80005b32:	20e4ae23          	sw	a4,540(s1)
    80005b36:	1ff7f793          	andi	a5,a5,511
    80005b3a:	97a6                	add	a5,a5,s1
    80005b3c:	faf44703          	lbu	a4,-81(s0)
    80005b40:	00e78c23          	sb	a4,24(a5)
      i++;
    80005b44:	2905                	addiw	s2,s2,1
    80005b46:	b76d                	j	80005af0 <pipewrite+0x80>
  int i = 0;
    80005b48:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005b4a:	21848513          	addi	a0,s1,536
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	2c0080e7          	jalr	704(ra) # 80002e0e <wakeup>
  release(&pi->lock);
    80005b56:	8526                	mv	a0,s1
    80005b58:	ffffb097          	auipc	ra,0xffffb
    80005b5c:	12e080e7          	jalr	302(ra) # 80000c86 <release>
  return i;
    80005b60:	b785                	j	80005ac0 <pipewrite+0x50>

0000000080005b62 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005b62:	715d                	addi	sp,sp,-80
    80005b64:	e486                	sd	ra,72(sp)
    80005b66:	e0a2                	sd	s0,64(sp)
    80005b68:	fc26                	sd	s1,56(sp)
    80005b6a:	f84a                	sd	s2,48(sp)
    80005b6c:	f44e                	sd	s3,40(sp)
    80005b6e:	f052                	sd	s4,32(sp)
    80005b70:	ec56                	sd	s5,24(sp)
    80005b72:	e85a                	sd	s6,16(sp)
    80005b74:	0880                	addi	s0,sp,80
    80005b76:	84aa                	mv	s1,a0
    80005b78:	892e                	mv	s2,a1
    80005b7a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005b7c:	ffffd097          	auipc	ra,0xffffd
    80005b80:	85e080e7          	jalr	-1954(ra) # 800023da <myproc>
    80005b84:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005b86:	8526                	mv	a0,s1
    80005b88:	ffffb097          	auipc	ra,0xffffb
    80005b8c:	04a080e7          	jalr	74(ra) # 80000bd2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b90:	2184a703          	lw	a4,536(s1)
    80005b94:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005b98:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005b9c:	02f71463          	bne	a4,a5,80005bc4 <piperead+0x62>
    80005ba0:	2244a783          	lw	a5,548(s1)
    80005ba4:	c385                	beqz	a5,80005bc4 <piperead+0x62>
    if(pr->killed){
    80005ba6:	028a2783          	lw	a5,40(s4)
    80005baa:	ebc1                	bnez	a5,80005c3a <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005bac:	85a6                	mv	a1,s1
    80005bae:	854e                	mv	a0,s3
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	0d2080e7          	jalr	210(ra) # 80002c82 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005bb8:	2184a703          	lw	a4,536(s1)
    80005bbc:	21c4a783          	lw	a5,540(s1)
    80005bc0:	fef700e3          	beq	a4,a5,80005ba0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bc4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bc6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005bc8:	05505363          	blez	s5,80005c0e <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80005bcc:	2184a783          	lw	a5,536(s1)
    80005bd0:	21c4a703          	lw	a4,540(s1)
    80005bd4:	02f70d63          	beq	a4,a5,80005c0e <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005bd8:	0017871b          	addiw	a4,a5,1
    80005bdc:	20e4ac23          	sw	a4,536(s1)
    80005be0:	1ff7f793          	andi	a5,a5,511
    80005be4:	97a6                	add	a5,a5,s1
    80005be6:	0187c783          	lbu	a5,24(a5)
    80005bea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005bee:	4685                	li	a3,1
    80005bf0:	fbf40613          	addi	a2,s0,-65
    80005bf4:	85ca                	mv	a1,s2
    80005bf6:	050a3503          	ld	a0,80(s4)
    80005bfa:	ffffc097          	auipc	ra,0xffffc
    80005bfe:	890080e7          	jalr	-1904(ra) # 8000148a <copyout>
    80005c02:	01650663          	beq	a0,s6,80005c0e <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005c06:	2985                	addiw	s3,s3,1
    80005c08:	0905                	addi	s2,s2,1
    80005c0a:	fd3a91e3          	bne	s5,s3,80005bcc <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005c0e:	21c48513          	addi	a0,s1,540
    80005c12:	ffffd097          	auipc	ra,0xffffd
    80005c16:	1fc080e7          	jalr	508(ra) # 80002e0e <wakeup>
  release(&pi->lock);
    80005c1a:	8526                	mv	a0,s1
    80005c1c:	ffffb097          	auipc	ra,0xffffb
    80005c20:	06a080e7          	jalr	106(ra) # 80000c86 <release>
  return i;
}
    80005c24:	854e                	mv	a0,s3
    80005c26:	60a6                	ld	ra,72(sp)
    80005c28:	6406                	ld	s0,64(sp)
    80005c2a:	74e2                	ld	s1,56(sp)
    80005c2c:	7942                	ld	s2,48(sp)
    80005c2e:	79a2                	ld	s3,40(sp)
    80005c30:	7a02                	ld	s4,32(sp)
    80005c32:	6ae2                	ld	s5,24(sp)
    80005c34:	6b42                	ld	s6,16(sp)
    80005c36:	6161                	addi	sp,sp,80
    80005c38:	8082                	ret
      release(&pi->lock);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffb097          	auipc	ra,0xffffb
    80005c40:	04a080e7          	jalr	74(ra) # 80000c86 <release>
      return -1;
    80005c44:	59fd                	li	s3,-1
    80005c46:	bff9                	j	80005c24 <piperead+0xc2>

0000000080005c48 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005c48:	de010113          	addi	sp,sp,-544
    80005c4c:	20113c23          	sd	ra,536(sp)
    80005c50:	20813823          	sd	s0,528(sp)
    80005c54:	20913423          	sd	s1,520(sp)
    80005c58:	21213023          	sd	s2,512(sp)
    80005c5c:	ffce                	sd	s3,504(sp)
    80005c5e:	fbd2                	sd	s4,496(sp)
    80005c60:	f7d6                	sd	s5,488(sp)
    80005c62:	f3da                	sd	s6,480(sp)
    80005c64:	efde                	sd	s7,472(sp)
    80005c66:	ebe2                	sd	s8,464(sp)
    80005c68:	e7e6                	sd	s9,456(sp)
    80005c6a:	e3ea                	sd	s10,448(sp)
    80005c6c:	ff6e                	sd	s11,440(sp)
    80005c6e:	1400                	addi	s0,sp,544
    80005c70:	892a                	mv	s2,a0
    80005c72:	dea43423          	sd	a0,-536(s0)
    80005c76:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005c7a:	ffffc097          	auipc	ra,0xffffc
    80005c7e:	760080e7          	jalr	1888(ra) # 800023da <myproc>
    80005c82:	84aa                	mv	s1,a0

  begin_op();
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	29c080e7          	jalr	668(ra) # 80004f20 <begin_op>

  if((ip = namei(path)) == 0){
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	d60080e7          	jalr	-672(ra) # 800049ee <namei>
    80005c96:	c93d                	beqz	a0,80005d0c <exec+0xc4>
    80005c98:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	580080e7          	jalr	1408(ra) # 8000421a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005ca2:	04000713          	li	a4,64
    80005ca6:	4681                	li	a3,0
    80005ca8:	e4840613          	addi	a2,s0,-440
    80005cac:	4581                	li	a1,0
    80005cae:	8556                	mv	a0,s5
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	81e080e7          	jalr	-2018(ra) # 800044ce <readi>
    80005cb8:	04000793          	li	a5,64
    80005cbc:	00f51a63          	bne	a0,a5,80005cd0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005cc0:	e4842703          	lw	a4,-440(s0)
    80005cc4:	464c47b7          	lui	a5,0x464c4
    80005cc8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005ccc:	04f70663          	beq	a4,a5,80005d18 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005cd0:	8556                	mv	a0,s5
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	7aa080e7          	jalr	1962(ra) # 8000447c <iunlockput>
    end_op();
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	2c6080e7          	jalr	710(ra) # 80004fa0 <end_op>
  }
  return -1;
    80005ce2:	557d                	li	a0,-1
}
    80005ce4:	21813083          	ld	ra,536(sp)
    80005ce8:	21013403          	ld	s0,528(sp)
    80005cec:	20813483          	ld	s1,520(sp)
    80005cf0:	20013903          	ld	s2,512(sp)
    80005cf4:	79fe                	ld	s3,504(sp)
    80005cf6:	7a5e                	ld	s4,496(sp)
    80005cf8:	7abe                	ld	s5,488(sp)
    80005cfa:	7b1e                	ld	s6,480(sp)
    80005cfc:	6bfe                	ld	s7,472(sp)
    80005cfe:	6c5e                	ld	s8,464(sp)
    80005d00:	6cbe                	ld	s9,456(sp)
    80005d02:	6d1e                	ld	s10,448(sp)
    80005d04:	7dfa                	ld	s11,440(sp)
    80005d06:	22010113          	addi	sp,sp,544
    80005d0a:	8082                	ret
    end_op();
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	294080e7          	jalr	660(ra) # 80004fa0 <end_op>
    return -1;
    80005d14:	557d                	li	a0,-1
    80005d16:	b7f9                	j	80005ce4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005d18:	8526                	mv	a0,s1
    80005d1a:	ffffc097          	auipc	ra,0xffffc
    80005d1e:	784080e7          	jalr	1924(ra) # 8000249e <proc_pagetable>
    80005d22:	8b2a                	mv	s6,a0
    80005d24:	d555                	beqz	a0,80005cd0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d26:	e6842783          	lw	a5,-408(s0)
    80005d2a:	e8045703          	lhu	a4,-384(s0)
    80005d2e:	c735                	beqz	a4,80005d9a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005d30:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005d32:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005d36:	6a05                	lui	s4,0x1
    80005d38:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005d3c:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80005d40:	6d85                	lui	s11,0x1
    80005d42:	7d7d                	lui	s10,0xfffff
    80005d44:	ac1d                	j	80005f7a <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005d46:	00004517          	auipc	a0,0x4
    80005d4a:	b8a50513          	addi	a0,a0,-1142 # 800098d0 <syscalls+0x318>
    80005d4e:	ffffa097          	auipc	ra,0xffffa
    80005d52:	7dc080e7          	jalr	2012(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005d56:	874a                	mv	a4,s2
    80005d58:	009c86bb          	addw	a3,s9,s1
    80005d5c:	4581                	li	a1,0
    80005d5e:	8556                	mv	a0,s5
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	76e080e7          	jalr	1902(ra) # 800044ce <readi>
    80005d68:	2501                	sext.w	a0,a0
    80005d6a:	1aa91863          	bne	s2,a0,80005f1a <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005d6e:	009d84bb          	addw	s1,s11,s1
    80005d72:	013d09bb          	addw	s3,s10,s3
    80005d76:	1f74f263          	bgeu	s1,s7,80005f5a <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005d7a:	02049593          	slli	a1,s1,0x20
    80005d7e:	9181                	srli	a1,a1,0x20
    80005d80:	95e2                	add	a1,a1,s8
    80005d82:	855a                	mv	a0,s6
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	2c2080e7          	jalr	706(ra) # 80001046 <walkaddr>
    80005d8c:	862a                	mv	a2,a0
    if(pa == 0)
    80005d8e:	dd45                	beqz	a0,80005d46 <exec+0xfe>
      n = PGSIZE;
    80005d90:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005d92:	fd49f2e3          	bgeu	s3,s4,80005d56 <exec+0x10e>
      n = sz - i;
    80005d96:	894e                	mv	s2,s3
    80005d98:	bf7d                	j	80005d56 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005d9a:	4481                	li	s1,0
  iunlockput(ip);
    80005d9c:	8556                	mv	a0,s5
    80005d9e:	ffffe097          	auipc	ra,0xffffe
    80005da2:	6de080e7          	jalr	1758(ra) # 8000447c <iunlockput>
  end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	1fa080e7          	jalr	506(ra) # 80004fa0 <end_op>
  p = myproc();
    80005dae:	ffffc097          	auipc	ra,0xffffc
    80005db2:	62c080e7          	jalr	1580(ra) # 800023da <myproc>
    80005db6:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005db8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005dbc:	6785                	lui	a5,0x1
    80005dbe:	17fd                	addi	a5,a5,-1
    80005dc0:	94be                	add	s1,s1,a5
    80005dc2:	77fd                	lui	a5,0xfffff
    80005dc4:	8fe5                	and	a5,a5,s1
    80005dc6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005dca:	6609                	lui	a2,0x2
    80005dcc:	963e                	add	a2,a2,a5
    80005dce:	85be                	mv	a1,a5
    80005dd0:	855a                	mv	a0,s6
    80005dd2:	ffffc097          	auipc	ra,0xffffc
    80005dd6:	d08080e7          	jalr	-760(ra) # 80001ada <uvmalloc>
    80005dda:	8c2a                	mv	s8,a0
  ip = 0;
    80005ddc:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005dde:	12050e63          	beqz	a0,80005f1a <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005de2:	75f9                	lui	a1,0xffffe
    80005de4:	95aa                	add	a1,a1,a0
    80005de6:	855a                	mv	a0,s6
    80005de8:	ffffb097          	auipc	ra,0xffffb
    80005dec:	670080e7          	jalr	1648(ra) # 80001458 <uvmclear>
  stackbase = sp - PGSIZE;
    80005df0:	7afd                	lui	s5,0xfffff
    80005df2:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005df4:	df043783          	ld	a5,-528(s0)
    80005df8:	6388                	ld	a0,0(a5)
    80005dfa:	c925                	beqz	a0,80005e6a <exec+0x222>
    80005dfc:	e8840993          	addi	s3,s0,-376
    80005e00:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005e04:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005e06:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005e08:	ffffb097          	auipc	ra,0xffffb
    80005e0c:	04a080e7          	jalr	74(ra) # 80000e52 <strlen>
    80005e10:	0015079b          	addiw	a5,a0,1
    80005e14:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005e18:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005e1c:	13596363          	bltu	s2,s5,80005f42 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005e20:	df043d83          	ld	s11,-528(s0)
    80005e24:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005e28:	8552                	mv	a0,s4
    80005e2a:	ffffb097          	auipc	ra,0xffffb
    80005e2e:	028080e7          	jalr	40(ra) # 80000e52 <strlen>
    80005e32:	0015069b          	addiw	a3,a0,1
    80005e36:	8652                	mv	a2,s4
    80005e38:	85ca                	mv	a1,s2
    80005e3a:	855a                	mv	a0,s6
    80005e3c:	ffffb097          	auipc	ra,0xffffb
    80005e40:	64e080e7          	jalr	1614(ra) # 8000148a <copyout>
    80005e44:	10054363          	bltz	a0,80005f4a <exec+0x302>
    ustack[argc] = sp;
    80005e48:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005e4c:	0485                	addi	s1,s1,1
    80005e4e:	008d8793          	addi	a5,s11,8
    80005e52:	def43823          	sd	a5,-528(s0)
    80005e56:	008db503          	ld	a0,8(s11)
    80005e5a:	c911                	beqz	a0,80005e6e <exec+0x226>
    if(argc >= MAXARG)
    80005e5c:	09a1                	addi	s3,s3,8
    80005e5e:	fb3c95e3          	bne	s9,s3,80005e08 <exec+0x1c0>
  sz = sz1;
    80005e62:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005e66:	4a81                	li	s5,0
    80005e68:	a84d                	j	80005f1a <exec+0x2d2>
  sp = sz;
    80005e6a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005e6c:	4481                	li	s1,0
  ustack[argc] = 0;
    80005e6e:	00349793          	slli	a5,s1,0x3
    80005e72:	f9040713          	addi	a4,s0,-112
    80005e76:	97ba                	add	a5,a5,a4
    80005e78:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffcfef8>
  sp -= (argc+1) * sizeof(uint64);
    80005e7c:	00148693          	addi	a3,s1,1
    80005e80:	068e                	slli	a3,a3,0x3
    80005e82:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005e86:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005e8a:	01597663          	bgeu	s2,s5,80005e96 <exec+0x24e>
  sz = sz1;
    80005e8e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005e92:	4a81                	li	s5,0
    80005e94:	a059                	j	80005f1a <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005e96:	e8840613          	addi	a2,s0,-376
    80005e9a:	85ca                	mv	a1,s2
    80005e9c:	855a                	mv	a0,s6
    80005e9e:	ffffb097          	auipc	ra,0xffffb
    80005ea2:	5ec080e7          	jalr	1516(ra) # 8000148a <copyout>
    80005ea6:	0a054663          	bltz	a0,80005f52 <exec+0x30a>
  p->trapframe->a1 = sp;
    80005eaa:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005eae:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005eb2:	de843783          	ld	a5,-536(s0)
    80005eb6:	0007c703          	lbu	a4,0(a5)
    80005eba:	cf11                	beqz	a4,80005ed6 <exec+0x28e>
    80005ebc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ebe:	02f00693          	li	a3,47
    80005ec2:	a039                	j	80005ed0 <exec+0x288>
      last = s+1;
    80005ec4:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005ec8:	0785                	addi	a5,a5,1
    80005eca:	fff7c703          	lbu	a4,-1(a5)
    80005ece:	c701                	beqz	a4,80005ed6 <exec+0x28e>
    if(*s == '/')
    80005ed0:	fed71ce3          	bne	a4,a3,80005ec8 <exec+0x280>
    80005ed4:	bfc5                	j	80005ec4 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80005ed6:	4641                	li	a2,16
    80005ed8:	de843583          	ld	a1,-536(s0)
    80005edc:	158b8513          	addi	a0,s7,344
    80005ee0:	ffffb097          	auipc	ra,0xffffb
    80005ee4:	f40080e7          	jalr	-192(ra) # 80000e20 <safestrcpy>
  oldpagetable = p->pagetable;
    80005ee8:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005eec:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005ef0:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005ef4:	058bb783          	ld	a5,88(s7)
    80005ef8:	e6043703          	ld	a4,-416(s0)
    80005efc:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005efe:	058bb783          	ld	a5,88(s7)
    80005f02:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005f06:	85ea                	mv	a1,s10
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	632080e7          	jalr	1586(ra) # 8000253a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005f10:	0004851b          	sext.w	a0,s1
    80005f14:	bbc1                	j	80005ce4 <exec+0x9c>
    80005f16:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005f1a:	df843583          	ld	a1,-520(s0)
    80005f1e:	855a                	mv	a0,s6
    80005f20:	ffffc097          	auipc	ra,0xffffc
    80005f24:	61a080e7          	jalr	1562(ra) # 8000253a <proc_freepagetable>
  if(ip){
    80005f28:	da0a94e3          	bnez	s5,80005cd0 <exec+0x88>
  return -1;
    80005f2c:	557d                	li	a0,-1
    80005f2e:	bb5d                	j	80005ce4 <exec+0x9c>
    80005f30:	de943c23          	sd	s1,-520(s0)
    80005f34:	b7dd                	j	80005f1a <exec+0x2d2>
    80005f36:	de943c23          	sd	s1,-520(s0)
    80005f3a:	b7c5                	j	80005f1a <exec+0x2d2>
    80005f3c:	de943c23          	sd	s1,-520(s0)
    80005f40:	bfe9                	j	80005f1a <exec+0x2d2>
  sz = sz1;
    80005f42:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005f46:	4a81                	li	s5,0
    80005f48:	bfc9                	j	80005f1a <exec+0x2d2>
  sz = sz1;
    80005f4a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005f4e:	4a81                	li	s5,0
    80005f50:	b7e9                	j	80005f1a <exec+0x2d2>
  sz = sz1;
    80005f52:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005f56:	4a81                	li	s5,0
    80005f58:	b7c9                	j	80005f1a <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005f5a:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005f5e:	e0843783          	ld	a5,-504(s0)
    80005f62:	0017869b          	addiw	a3,a5,1
    80005f66:	e0d43423          	sd	a3,-504(s0)
    80005f6a:	e0043783          	ld	a5,-512(s0)
    80005f6e:	0387879b          	addiw	a5,a5,56
    80005f72:	e8045703          	lhu	a4,-384(s0)
    80005f76:	e2e6d3e3          	bge	a3,a4,80005d9c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005f7a:	2781                	sext.w	a5,a5
    80005f7c:	e0f43023          	sd	a5,-512(s0)
    80005f80:	03800713          	li	a4,56
    80005f84:	86be                	mv	a3,a5
    80005f86:	e1040613          	addi	a2,s0,-496
    80005f8a:	4581                	li	a1,0
    80005f8c:	8556                	mv	a0,s5
    80005f8e:	ffffe097          	auipc	ra,0xffffe
    80005f92:	540080e7          	jalr	1344(ra) # 800044ce <readi>
    80005f96:	03800793          	li	a5,56
    80005f9a:	f6f51ee3          	bne	a0,a5,80005f16 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005f9e:	e1042783          	lw	a5,-496(s0)
    80005fa2:	4705                	li	a4,1
    80005fa4:	fae79de3          	bne	a5,a4,80005f5e <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005fa8:	e3843603          	ld	a2,-456(s0)
    80005fac:	e3043783          	ld	a5,-464(s0)
    80005fb0:	f8f660e3          	bltu	a2,a5,80005f30 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005fb4:	e2043783          	ld	a5,-480(s0)
    80005fb8:	963e                	add	a2,a2,a5
    80005fba:	f6f66ee3          	bltu	a2,a5,80005f36 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005fbe:	85a6                	mv	a1,s1
    80005fc0:	855a                	mv	a0,s6
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	b18080e7          	jalr	-1256(ra) # 80001ada <uvmalloc>
    80005fca:	dea43c23          	sd	a0,-520(s0)
    80005fce:	d53d                	beqz	a0,80005f3c <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005fd0:	e2043c03          	ld	s8,-480(s0)
    80005fd4:	de043783          	ld	a5,-544(s0)
    80005fd8:	00fc77b3          	and	a5,s8,a5
    80005fdc:	ff9d                	bnez	a5,80005f1a <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005fde:	e1842c83          	lw	s9,-488(s0)
    80005fe2:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005fe6:	f60b8ae3          	beqz	s7,80005f5a <exec+0x312>
    80005fea:	89de                	mv	s3,s7
    80005fec:	4481                	li	s1,0
    80005fee:	b371                	j	80005d7a <exec+0x132>

0000000080005ff0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005ff0:	7179                	addi	sp,sp,-48
    80005ff2:	f406                	sd	ra,40(sp)
    80005ff4:	f022                	sd	s0,32(sp)
    80005ff6:	ec26                	sd	s1,24(sp)
    80005ff8:	e84a                	sd	s2,16(sp)
    80005ffa:	1800                	addi	s0,sp,48
    80005ffc:	892e                	mv	s2,a1
    80005ffe:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80006000:	fdc40593          	addi	a1,s0,-36
    80006004:	ffffd097          	auipc	ra,0xffffd
    80006008:	6a4080e7          	jalr	1700(ra) # 800036a8 <argint>
    8000600c:	04054063          	bltz	a0,8000604c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80006010:	fdc42703          	lw	a4,-36(s0)
    80006014:	47bd                	li	a5,15
    80006016:	02e7ed63          	bltu	a5,a4,80006050 <argfd+0x60>
    8000601a:	ffffc097          	auipc	ra,0xffffc
    8000601e:	3c0080e7          	jalr	960(ra) # 800023da <myproc>
    80006022:	fdc42703          	lw	a4,-36(s0)
    80006026:	01a70793          	addi	a5,a4,26
    8000602a:	078e                	slli	a5,a5,0x3
    8000602c:	953e                	add	a0,a0,a5
    8000602e:	611c                	ld	a5,0(a0)
    80006030:	c395                	beqz	a5,80006054 <argfd+0x64>
    return -1;
  if(pfd)
    80006032:	00090463          	beqz	s2,8000603a <argfd+0x4a>
    *pfd = fd;
    80006036:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000603a:	4501                	li	a0,0
  if(pf)
    8000603c:	c091                	beqz	s1,80006040 <argfd+0x50>
    *pf = f;
    8000603e:	e09c                	sd	a5,0(s1)
}
    80006040:	70a2                	ld	ra,40(sp)
    80006042:	7402                	ld	s0,32(sp)
    80006044:	64e2                	ld	s1,24(sp)
    80006046:	6942                	ld	s2,16(sp)
    80006048:	6145                	addi	sp,sp,48
    8000604a:	8082                	ret
    return -1;
    8000604c:	557d                	li	a0,-1
    8000604e:	bfcd                	j	80006040 <argfd+0x50>
    return -1;
    80006050:	557d                	li	a0,-1
    80006052:	b7fd                	j	80006040 <argfd+0x50>
    80006054:	557d                	li	a0,-1
    80006056:	b7ed                	j	80006040 <argfd+0x50>

0000000080006058 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80006058:	1101                	addi	sp,sp,-32
    8000605a:	ec06                	sd	ra,24(sp)
    8000605c:	e822                	sd	s0,16(sp)
    8000605e:	e426                	sd	s1,8(sp)
    80006060:	1000                	addi	s0,sp,32
    80006062:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80006064:	ffffc097          	auipc	ra,0xffffc
    80006068:	376080e7          	jalr	886(ra) # 800023da <myproc>
    8000606c:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000606e:	0d050793          	addi	a5,a0,208
    80006072:	4501                	li	a0,0
    80006074:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80006076:	6398                	ld	a4,0(a5)
    80006078:	cb19                	beqz	a4,8000608e <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000607a:	2505                	addiw	a0,a0,1
    8000607c:	07a1                	addi	a5,a5,8
    8000607e:	fed51ce3          	bne	a0,a3,80006076 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006082:	557d                	li	a0,-1
}
    80006084:	60e2                	ld	ra,24(sp)
    80006086:	6442                	ld	s0,16(sp)
    80006088:	64a2                	ld	s1,8(sp)
    8000608a:	6105                	addi	sp,sp,32
    8000608c:	8082                	ret
      p->ofile[fd] = f;
    8000608e:	01a50793          	addi	a5,a0,26
    80006092:	078e                	slli	a5,a5,0x3
    80006094:	963e                	add	a2,a2,a5
    80006096:	e204                	sd	s1,0(a2)
      return fd;
    80006098:	b7f5                	j	80006084 <fdalloc+0x2c>

000000008000609a <sys_dup>:

uint64
sys_dup(void)
{
    8000609a:	7179                	addi	sp,sp,-48
    8000609c:	f406                	sd	ra,40(sp)
    8000609e:	f022                	sd	s0,32(sp)
    800060a0:	ec26                	sd	s1,24(sp)
    800060a2:	1800                	addi	s0,sp,48
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
    800060a4:	fd840613          	addi	a2,s0,-40
    800060a8:	4581                	li	a1,0
    800060aa:	4501                	li	a0,0
    800060ac:	00000097          	auipc	ra,0x0
    800060b0:	f44080e7          	jalr	-188(ra) # 80005ff0 <argfd>
    return -1;
    800060b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800060b6:	02054363          	bltz	a0,800060dc <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800060ba:	fd843503          	ld	a0,-40(s0)
    800060be:	00000097          	auipc	ra,0x0
    800060c2:	f9a080e7          	jalr	-102(ra) # 80006058 <fdalloc>
    800060c6:	84aa                	mv	s1,a0
    return -1;
    800060c8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800060ca:	00054963          	bltz	a0,800060dc <sys_dup+0x42>
  filedup(f);
    800060ce:	fd843503          	ld	a0,-40(s0)
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	2c8080e7          	jalr	712(ra) # 8000539a <filedup>
  return fd;
    800060da:	87a6                	mv	a5,s1
}
    800060dc:	853e                	mv	a0,a5
    800060de:	70a2                	ld	ra,40(sp)
    800060e0:	7402                	ld	s0,32(sp)
    800060e2:	64e2                	ld	s1,24(sp)
    800060e4:	6145                	addi	sp,sp,48
    800060e6:	8082                	ret

00000000800060e8 <sys_read>:

uint64
sys_read(void)
{
    800060e8:	7179                	addi	sp,sp,-48
    800060ea:	f406                	sd	ra,40(sp)
    800060ec:	f022                	sd	s0,32(sp)
    800060ee:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800060f0:	fe840613          	addi	a2,s0,-24
    800060f4:	4581                	li	a1,0
    800060f6:	4501                	li	a0,0
    800060f8:	00000097          	auipc	ra,0x0
    800060fc:	ef8080e7          	jalr	-264(ra) # 80005ff0 <argfd>
    return -1;
    80006100:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006102:	04054163          	bltz	a0,80006144 <sys_read+0x5c>
    80006106:	fe440593          	addi	a1,s0,-28
    8000610a:	4509                	li	a0,2
    8000610c:	ffffd097          	auipc	ra,0xffffd
    80006110:	59c080e7          	jalr	1436(ra) # 800036a8 <argint>
    return -1;
    80006114:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006116:	02054763          	bltz	a0,80006144 <sys_read+0x5c>
    8000611a:	fd840593          	addi	a1,s0,-40
    8000611e:	4505                	li	a0,1
    80006120:	ffffd097          	auipc	ra,0xffffd
    80006124:	5aa080e7          	jalr	1450(ra) # 800036ca <argaddr>
    return -1;
    80006128:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000612a:	00054d63          	bltz	a0,80006144 <sys_read+0x5c>
  return fileread(f, p, n);
    8000612e:	fe442603          	lw	a2,-28(s0)
    80006132:	fd843583          	ld	a1,-40(s0)
    80006136:	fe843503          	ld	a0,-24(s0)
    8000613a:	fffff097          	auipc	ra,0xfffff
    8000613e:	3ec080e7          	jalr	1004(ra) # 80005526 <fileread>
    80006142:	87aa                	mv	a5,a0
}
    80006144:	853e                	mv	a0,a5
    80006146:	70a2                	ld	ra,40(sp)
    80006148:	7402                	ld	s0,32(sp)
    8000614a:	6145                	addi	sp,sp,48
    8000614c:	8082                	ret

000000008000614e <sys_write>:

uint64
sys_write(void)
{
    8000614e:	7179                	addi	sp,sp,-48
    80006150:	f406                	sd	ra,40(sp)
    80006152:	f022                	sd	s0,32(sp)
    80006154:	1800                	addi	s0,sp,48
  struct file *f;
  int n;
  uint64 p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006156:	fe840613          	addi	a2,s0,-24
    8000615a:	4581                	li	a1,0
    8000615c:	4501                	li	a0,0
    8000615e:	00000097          	auipc	ra,0x0
    80006162:	e92080e7          	jalr	-366(ra) # 80005ff0 <argfd>
    return -1;
    80006166:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006168:	04054163          	bltz	a0,800061aa <sys_write+0x5c>
    8000616c:	fe440593          	addi	a1,s0,-28
    80006170:	4509                	li	a0,2
    80006172:	ffffd097          	auipc	ra,0xffffd
    80006176:	536080e7          	jalr	1334(ra) # 800036a8 <argint>
    return -1;
    8000617a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000617c:	02054763          	bltz	a0,800061aa <sys_write+0x5c>
    80006180:	fd840593          	addi	a1,s0,-40
    80006184:	4505                	li	a0,1
    80006186:	ffffd097          	auipc	ra,0xffffd
    8000618a:	544080e7          	jalr	1348(ra) # 800036ca <argaddr>
    return -1;
    8000618e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80006190:	00054d63          	bltz	a0,800061aa <sys_write+0x5c>

  return filewrite(f, p, n);
    80006194:	fe442603          	lw	a2,-28(s0)
    80006198:	fd843583          	ld	a1,-40(s0)
    8000619c:	fe843503          	ld	a0,-24(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	448080e7          	jalr	1096(ra) # 800055e8 <filewrite>
    800061a8:	87aa                	mv	a5,a0
}
    800061aa:	853e                	mv	a0,a5
    800061ac:	70a2                	ld	ra,40(sp)
    800061ae:	7402                	ld	s0,32(sp)
    800061b0:	6145                	addi	sp,sp,48
    800061b2:	8082                	ret

00000000800061b4 <sys_close>:

uint64
sys_close(void)
{
    800061b4:	1101                	addi	sp,sp,-32
    800061b6:	ec06                	sd	ra,24(sp)
    800061b8:	e822                	sd	s0,16(sp)
    800061ba:	1000                	addi	s0,sp,32
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
    800061bc:	fe040613          	addi	a2,s0,-32
    800061c0:	fec40593          	addi	a1,s0,-20
    800061c4:	4501                	li	a0,0
    800061c6:	00000097          	auipc	ra,0x0
    800061ca:	e2a080e7          	jalr	-470(ra) # 80005ff0 <argfd>
    return -1;
    800061ce:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800061d0:	02054463          	bltz	a0,800061f8 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800061d4:	ffffc097          	auipc	ra,0xffffc
    800061d8:	206080e7          	jalr	518(ra) # 800023da <myproc>
    800061dc:	fec42783          	lw	a5,-20(s0)
    800061e0:	07e9                	addi	a5,a5,26
    800061e2:	078e                	slli	a5,a5,0x3
    800061e4:	97aa                	add	a5,a5,a0
    800061e6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800061ea:	fe043503          	ld	a0,-32(s0)
    800061ee:	fffff097          	auipc	ra,0xfffff
    800061f2:	1fe080e7          	jalr	510(ra) # 800053ec <fileclose>
  return 0;
    800061f6:	4781                	li	a5,0
}
    800061f8:	853e                	mv	a0,a5
    800061fa:	60e2                	ld	ra,24(sp)
    800061fc:	6442                	ld	s0,16(sp)
    800061fe:	6105                	addi	sp,sp,32
    80006200:	8082                	ret

0000000080006202 <sys_fstat>:

uint64
sys_fstat(void)
{
    80006202:	1101                	addi	sp,sp,-32
    80006204:	ec06                	sd	ra,24(sp)
    80006206:	e822                	sd	s0,16(sp)
    80006208:	1000                	addi	s0,sp,32
  struct file *f;
  uint64 st; // user pointer to struct stat

  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000620a:	fe840613          	addi	a2,s0,-24
    8000620e:	4581                	li	a1,0
    80006210:	4501                	li	a0,0
    80006212:	00000097          	auipc	ra,0x0
    80006216:	dde080e7          	jalr	-546(ra) # 80005ff0 <argfd>
    return -1;
    8000621a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000621c:	02054563          	bltz	a0,80006246 <sys_fstat+0x44>
    80006220:	fe040593          	addi	a1,s0,-32
    80006224:	4505                	li	a0,1
    80006226:	ffffd097          	auipc	ra,0xffffd
    8000622a:	4a4080e7          	jalr	1188(ra) # 800036ca <argaddr>
    return -1;
    8000622e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80006230:	00054b63          	bltz	a0,80006246 <sys_fstat+0x44>
  return filestat(f, st);
    80006234:	fe043583          	ld	a1,-32(s0)
    80006238:	fe843503          	ld	a0,-24(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	278080e7          	jalr	632(ra) # 800054b4 <filestat>
    80006244:	87aa                	mv	a5,a0
}
    80006246:	853e                	mv	a0,a5
    80006248:	60e2                	ld	ra,24(sp)
    8000624a:	6442                	ld	s0,16(sp)
    8000624c:	6105                	addi	sp,sp,32
    8000624e:	8082                	ret

0000000080006250 <sys_link>:

// Create the path new as a link to the same inode as old.
uint64
sys_link(void)
{
    80006250:	7169                	addi	sp,sp,-304
    80006252:	f606                	sd	ra,296(sp)
    80006254:	f222                	sd	s0,288(sp)
    80006256:	ee26                	sd	s1,280(sp)
    80006258:	ea4a                	sd	s2,272(sp)
    8000625a:	1a00                	addi	s0,sp,304
  char name[DIRSIZ], new[MAXPATH], old[MAXPATH];
  struct inode *dp, *ip;

  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000625c:	08000613          	li	a2,128
    80006260:	ed040593          	addi	a1,s0,-304
    80006264:	4501                	li	a0,0
    80006266:	ffffd097          	auipc	ra,0xffffd
    8000626a:	486080e7          	jalr	1158(ra) # 800036ec <argstr>
    return -1;
    8000626e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006270:	10054e63          	bltz	a0,8000638c <sys_link+0x13c>
    80006274:	08000613          	li	a2,128
    80006278:	f5040593          	addi	a1,s0,-176
    8000627c:	4505                	li	a0,1
    8000627e:	ffffd097          	auipc	ra,0xffffd
    80006282:	46e080e7          	jalr	1134(ra) # 800036ec <argstr>
    return -1;
    80006286:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80006288:	10054263          	bltz	a0,8000638c <sys_link+0x13c>

  begin_op();
    8000628c:	fffff097          	auipc	ra,0xfffff
    80006290:	c94080e7          	jalr	-876(ra) # 80004f20 <begin_op>
  if((ip = namei(old)) == 0){
    80006294:	ed040513          	addi	a0,s0,-304
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	756080e7          	jalr	1878(ra) # 800049ee <namei>
    800062a0:	84aa                	mv	s1,a0
    800062a2:	c551                	beqz	a0,8000632e <sys_link+0xde>
    end_op();
    return -1;
  }

  ilock(ip);
    800062a4:	ffffe097          	auipc	ra,0xffffe
    800062a8:	f76080e7          	jalr	-138(ra) # 8000421a <ilock>
  if(ip->type == T_DIR){
    800062ac:	04449703          	lh	a4,68(s1)
    800062b0:	4785                	li	a5,1
    800062b2:	08f70463          	beq	a4,a5,8000633a <sys_link+0xea>
    iunlockput(ip);
    end_op();
    return -1;
  }

  ip->nlink++;
    800062b6:	04a4d783          	lhu	a5,74(s1)
    800062ba:	2785                	addiw	a5,a5,1
    800062bc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800062c0:	8526                	mv	a0,s1
    800062c2:	ffffe097          	auipc	ra,0xffffe
    800062c6:	e8e080e7          	jalr	-370(ra) # 80004150 <iupdate>
  iunlock(ip);
    800062ca:	8526                	mv	a0,s1
    800062cc:	ffffe097          	auipc	ra,0xffffe
    800062d0:	010080e7          	jalr	16(ra) # 800042dc <iunlock>

  if((dp = nameiparent(new, name)) == 0)
    800062d4:	fd040593          	addi	a1,s0,-48
    800062d8:	f5040513          	addi	a0,s0,-176
    800062dc:	ffffe097          	auipc	ra,0xffffe
    800062e0:	730080e7          	jalr	1840(ra) # 80004a0c <nameiparent>
    800062e4:	892a                	mv	s2,a0
    800062e6:	c935                	beqz	a0,8000635a <sys_link+0x10a>
    goto bad;
  ilock(dp);
    800062e8:	ffffe097          	auipc	ra,0xffffe
    800062ec:	f32080e7          	jalr	-206(ra) # 8000421a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800062f0:	00092703          	lw	a4,0(s2)
    800062f4:	409c                	lw	a5,0(s1)
    800062f6:	04f71d63          	bne	a4,a5,80006350 <sys_link+0x100>
    800062fa:	40d0                	lw	a2,4(s1)
    800062fc:	fd040593          	addi	a1,s0,-48
    80006300:	854a                	mv	a0,s2
    80006302:	ffffe097          	auipc	ra,0xffffe
    80006306:	62a080e7          	jalr	1578(ra) # 8000492c <dirlink>
    8000630a:	04054363          	bltz	a0,80006350 <sys_link+0x100>
    iunlockput(dp);
    goto bad;
  }
  iunlockput(dp);
    8000630e:	854a                	mv	a0,s2
    80006310:	ffffe097          	auipc	ra,0xffffe
    80006314:	16c080e7          	jalr	364(ra) # 8000447c <iunlockput>
  iput(ip);
    80006318:	8526                	mv	a0,s1
    8000631a:	ffffe097          	auipc	ra,0xffffe
    8000631e:	0ba080e7          	jalr	186(ra) # 800043d4 <iput>

  end_op();
    80006322:	fffff097          	auipc	ra,0xfffff
    80006326:	c7e080e7          	jalr	-898(ra) # 80004fa0 <end_op>

  return 0;
    8000632a:	4781                	li	a5,0
    8000632c:	a085                	j	8000638c <sys_link+0x13c>
    end_op();
    8000632e:	fffff097          	auipc	ra,0xfffff
    80006332:	c72080e7          	jalr	-910(ra) # 80004fa0 <end_op>
    return -1;
    80006336:	57fd                	li	a5,-1
    80006338:	a891                	j	8000638c <sys_link+0x13c>
    iunlockput(ip);
    8000633a:	8526                	mv	a0,s1
    8000633c:	ffffe097          	auipc	ra,0xffffe
    80006340:	140080e7          	jalr	320(ra) # 8000447c <iunlockput>
    end_op();
    80006344:	fffff097          	auipc	ra,0xfffff
    80006348:	c5c080e7          	jalr	-932(ra) # 80004fa0 <end_op>
    return -1;
    8000634c:	57fd                	li	a5,-1
    8000634e:	a83d                	j	8000638c <sys_link+0x13c>
    iunlockput(dp);
    80006350:	854a                	mv	a0,s2
    80006352:	ffffe097          	auipc	ra,0xffffe
    80006356:	12a080e7          	jalr	298(ra) # 8000447c <iunlockput>

bad:
  ilock(ip);
    8000635a:	8526                	mv	a0,s1
    8000635c:	ffffe097          	auipc	ra,0xffffe
    80006360:	ebe080e7          	jalr	-322(ra) # 8000421a <ilock>
  ip->nlink--;
    80006364:	04a4d783          	lhu	a5,74(s1)
    80006368:	37fd                	addiw	a5,a5,-1
    8000636a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000636e:	8526                	mv	a0,s1
    80006370:	ffffe097          	auipc	ra,0xffffe
    80006374:	de0080e7          	jalr	-544(ra) # 80004150 <iupdate>
  iunlockput(ip);
    80006378:	8526                	mv	a0,s1
    8000637a:	ffffe097          	auipc	ra,0xffffe
    8000637e:	102080e7          	jalr	258(ra) # 8000447c <iunlockput>
  end_op();
    80006382:	fffff097          	auipc	ra,0xfffff
    80006386:	c1e080e7          	jalr	-994(ra) # 80004fa0 <end_op>
  return -1;
    8000638a:	57fd                	li	a5,-1
}
    8000638c:	853e                	mv	a0,a5
    8000638e:	70b2                	ld	ra,296(sp)
    80006390:	7412                	ld	s0,288(sp)
    80006392:	64f2                	ld	s1,280(sp)
    80006394:	6952                	ld	s2,272(sp)
    80006396:	6155                	addi	sp,sp,304
    80006398:	8082                	ret

000000008000639a <isdirempty>:
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000639a:	4578                	lw	a4,76(a0)
    8000639c:	02000793          	li	a5,32
    800063a0:	04e7fa63          	bgeu	a5,a4,800063f4 <isdirempty+0x5a>
{
    800063a4:	7179                	addi	sp,sp,-48
    800063a6:	f406                	sd	ra,40(sp)
    800063a8:	f022                	sd	s0,32(sp)
    800063aa:	ec26                	sd	s1,24(sp)
    800063ac:	e84a                	sd	s2,16(sp)
    800063ae:	1800                	addi	s0,sp,48
    800063b0:	892a                	mv	s2,a0
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063b2:	02000493          	li	s1,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800063b6:	4741                	li	a4,16
    800063b8:	86a6                	mv	a3,s1
    800063ba:	fd040613          	addi	a2,s0,-48
    800063be:	4581                	li	a1,0
    800063c0:	854a                	mv	a0,s2
    800063c2:	ffffe097          	auipc	ra,0xffffe
    800063c6:	10c080e7          	jalr	268(ra) # 800044ce <readi>
    800063ca:	47c1                	li	a5,16
    800063cc:	00f51c63          	bne	a0,a5,800063e4 <isdirempty+0x4a>
      panic("isdirempty: readi");
    if(de.inum != 0)
    800063d0:	fd045783          	lhu	a5,-48(s0)
    800063d4:	e395                	bnez	a5,800063f8 <isdirempty+0x5e>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800063d6:	24c1                	addiw	s1,s1,16
    800063d8:	04c92783          	lw	a5,76(s2)
    800063dc:	fcf4ede3          	bltu	s1,a5,800063b6 <isdirempty+0x1c>
      return 0;
  }
  return 1;
    800063e0:	4505                	li	a0,1
    800063e2:	a821                	j	800063fa <isdirempty+0x60>
      panic("isdirempty: readi");
    800063e4:	00003517          	auipc	a0,0x3
    800063e8:	50c50513          	addi	a0,a0,1292 # 800098f0 <syscalls+0x338>
    800063ec:	ffffa097          	auipc	ra,0xffffa
    800063f0:	13e080e7          	jalr	318(ra) # 8000052a <panic>
  return 1;
    800063f4:	4505                	li	a0,1
}
    800063f6:	8082                	ret
      return 0;
    800063f8:	4501                	li	a0,0
}
    800063fa:	70a2                	ld	ra,40(sp)
    800063fc:	7402                	ld	s0,32(sp)
    800063fe:	64e2                	ld	s1,24(sp)
    80006400:	6942                	ld	s2,16(sp)
    80006402:	6145                	addi	sp,sp,48
    80006404:	8082                	ret

0000000080006406 <sys_unlink>:

uint64
sys_unlink(void)
{
    80006406:	7155                	addi	sp,sp,-208
    80006408:	e586                	sd	ra,200(sp)
    8000640a:	e1a2                	sd	s0,192(sp)
    8000640c:	fd26                	sd	s1,184(sp)
    8000640e:	f94a                	sd	s2,176(sp)
    80006410:	0980                	addi	s0,sp,208
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], path[MAXPATH];
  uint off;

  if(argstr(0, path, MAXPATH) < 0)
    80006412:	08000613          	li	a2,128
    80006416:	f4040593          	addi	a1,s0,-192
    8000641a:	4501                	li	a0,0
    8000641c:	ffffd097          	auipc	ra,0xffffd
    80006420:	2d0080e7          	jalr	720(ra) # 800036ec <argstr>
    80006424:	16054363          	bltz	a0,8000658a <sys_unlink+0x184>
    return -1;

  begin_op();
    80006428:	fffff097          	auipc	ra,0xfffff
    8000642c:	af8080e7          	jalr	-1288(ra) # 80004f20 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006430:	fc040593          	addi	a1,s0,-64
    80006434:	f4040513          	addi	a0,s0,-192
    80006438:	ffffe097          	auipc	ra,0xffffe
    8000643c:	5d4080e7          	jalr	1492(ra) # 80004a0c <nameiparent>
    80006440:	84aa                	mv	s1,a0
    80006442:	c961                	beqz	a0,80006512 <sys_unlink+0x10c>
    end_op();
    return -1;
  }

  ilock(dp);
    80006444:	ffffe097          	auipc	ra,0xffffe
    80006448:	dd6080e7          	jalr	-554(ra) # 8000421a <ilock>

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000644c:	00003597          	auipc	a1,0x3
    80006450:	37458593          	addi	a1,a1,884 # 800097c0 <syscalls+0x208>
    80006454:	fc040513          	addi	a0,s0,-64
    80006458:	ffffe097          	auipc	ra,0xffffe
    8000645c:	2aa080e7          	jalr	682(ra) # 80004702 <namecmp>
    80006460:	c175                	beqz	a0,80006544 <sys_unlink+0x13e>
    80006462:	00003597          	auipc	a1,0x3
    80006466:	36658593          	addi	a1,a1,870 # 800097c8 <syscalls+0x210>
    8000646a:	fc040513          	addi	a0,s0,-64
    8000646e:	ffffe097          	auipc	ra,0xffffe
    80006472:	294080e7          	jalr	660(ra) # 80004702 <namecmp>
    80006476:	c579                	beqz	a0,80006544 <sys_unlink+0x13e>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    80006478:	f3c40613          	addi	a2,s0,-196
    8000647c:	fc040593          	addi	a1,s0,-64
    80006480:	8526                	mv	a0,s1
    80006482:	ffffe097          	auipc	ra,0xffffe
    80006486:	29a080e7          	jalr	666(ra) # 8000471c <dirlookup>
    8000648a:	892a                	mv	s2,a0
    8000648c:	cd45                	beqz	a0,80006544 <sys_unlink+0x13e>
    goto bad;
  ilock(ip);
    8000648e:	ffffe097          	auipc	ra,0xffffe
    80006492:	d8c080e7          	jalr	-628(ra) # 8000421a <ilock>

  if(ip->nlink < 1)
    80006496:	04a91783          	lh	a5,74(s2)
    8000649a:	08f05263          	blez	a5,8000651e <sys_unlink+0x118>
    panic("unlink: nlink < 1");
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000649e:	04491703          	lh	a4,68(s2)
    800064a2:	4785                	li	a5,1
    800064a4:	08f70563          	beq	a4,a5,8000652e <sys_unlink+0x128>
    iunlockput(ip);
    goto bad;
  }

  memset(&de, 0, sizeof(de));
    800064a8:	4641                	li	a2,16
    800064aa:	4581                	li	a1,0
    800064ac:	fd040513          	addi	a0,s0,-48
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	81e080e7          	jalr	-2018(ra) # 80000cce <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800064b8:	4741                	li	a4,16
    800064ba:	f3c42683          	lw	a3,-196(s0)
    800064be:	fd040613          	addi	a2,s0,-48
    800064c2:	4581                	li	a1,0
    800064c4:	8526                	mv	a0,s1
    800064c6:	ffffe097          	auipc	ra,0xffffe
    800064ca:	100080e7          	jalr	256(ra) # 800045c6 <writei>
    800064ce:	47c1                	li	a5,16
    800064d0:	08f51a63          	bne	a0,a5,80006564 <sys_unlink+0x15e>
    panic("unlink: writei");
  if(ip->type == T_DIR){
    800064d4:	04491703          	lh	a4,68(s2)
    800064d8:	4785                	li	a5,1
    800064da:	08f70d63          	beq	a4,a5,80006574 <sys_unlink+0x16e>
    dp->nlink--;
    iupdate(dp);
  }
  iunlockput(dp);
    800064de:	8526                	mv	a0,s1
    800064e0:	ffffe097          	auipc	ra,0xffffe
    800064e4:	f9c080e7          	jalr	-100(ra) # 8000447c <iunlockput>

  ip->nlink--;
    800064e8:	04a95783          	lhu	a5,74(s2)
    800064ec:	37fd                	addiw	a5,a5,-1
    800064ee:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800064f2:	854a                	mv	a0,s2
    800064f4:	ffffe097          	auipc	ra,0xffffe
    800064f8:	c5c080e7          	jalr	-932(ra) # 80004150 <iupdate>
  iunlockput(ip);
    800064fc:	854a                	mv	a0,s2
    800064fe:	ffffe097          	auipc	ra,0xffffe
    80006502:	f7e080e7          	jalr	-130(ra) # 8000447c <iunlockput>

  end_op();
    80006506:	fffff097          	auipc	ra,0xfffff
    8000650a:	a9a080e7          	jalr	-1382(ra) # 80004fa0 <end_op>

  return 0;
    8000650e:	4501                	li	a0,0
    80006510:	a0a1                	j	80006558 <sys_unlink+0x152>
    end_op();
    80006512:	fffff097          	auipc	ra,0xfffff
    80006516:	a8e080e7          	jalr	-1394(ra) # 80004fa0 <end_op>
    return -1;
    8000651a:	557d                	li	a0,-1
    8000651c:	a835                	j	80006558 <sys_unlink+0x152>
    panic("unlink: nlink < 1");
    8000651e:	00003517          	auipc	a0,0x3
    80006522:	2b250513          	addi	a0,a0,690 # 800097d0 <syscalls+0x218>
    80006526:	ffffa097          	auipc	ra,0xffffa
    8000652a:	004080e7          	jalr	4(ra) # 8000052a <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000652e:	854a                	mv	a0,s2
    80006530:	00000097          	auipc	ra,0x0
    80006534:	e6a080e7          	jalr	-406(ra) # 8000639a <isdirempty>
    80006538:	f925                	bnez	a0,800064a8 <sys_unlink+0xa2>
    iunlockput(ip);
    8000653a:	854a                	mv	a0,s2
    8000653c:	ffffe097          	auipc	ra,0xffffe
    80006540:	f40080e7          	jalr	-192(ra) # 8000447c <iunlockput>

bad:
  iunlockput(dp);
    80006544:	8526                	mv	a0,s1
    80006546:	ffffe097          	auipc	ra,0xffffe
    8000654a:	f36080e7          	jalr	-202(ra) # 8000447c <iunlockput>
  end_op();
    8000654e:	fffff097          	auipc	ra,0xfffff
    80006552:	a52080e7          	jalr	-1454(ra) # 80004fa0 <end_op>
  return -1;
    80006556:	557d                	li	a0,-1
}
    80006558:	60ae                	ld	ra,200(sp)
    8000655a:	640e                	ld	s0,192(sp)
    8000655c:	74ea                	ld	s1,184(sp)
    8000655e:	794a                	ld	s2,176(sp)
    80006560:	6169                	addi	sp,sp,208
    80006562:	8082                	ret
    panic("unlink: writei");
    80006564:	00003517          	auipc	a0,0x3
    80006568:	28450513          	addi	a0,a0,644 # 800097e8 <syscalls+0x230>
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	fbe080e7          	jalr	-66(ra) # 8000052a <panic>
    dp->nlink--;
    80006574:	04a4d783          	lhu	a5,74(s1)
    80006578:	37fd                	addiw	a5,a5,-1
    8000657a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000657e:	8526                	mv	a0,s1
    80006580:	ffffe097          	auipc	ra,0xffffe
    80006584:	bd0080e7          	jalr	-1072(ra) # 80004150 <iupdate>
    80006588:	bf99                	j	800064de <sys_unlink+0xd8>
    return -1;
    8000658a:	557d                	li	a0,-1
    8000658c:	b7f1                	j	80006558 <sys_unlink+0x152>

000000008000658e <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000658e:	715d                	addi	sp,sp,-80
    80006590:	e486                	sd	ra,72(sp)
    80006592:	e0a2                	sd	s0,64(sp)
    80006594:	fc26                	sd	s1,56(sp)
    80006596:	f84a                	sd	s2,48(sp)
    80006598:	f44e                	sd	s3,40(sp)
    8000659a:	f052                	sd	s4,32(sp)
    8000659c:	ec56                	sd	s5,24(sp)
    8000659e:	0880                	addi	s0,sp,80
    800065a0:	89ae                	mv	s3,a1
    800065a2:	8ab2                	mv	s5,a2
    800065a4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800065a6:	fb040593          	addi	a1,s0,-80
    800065aa:	ffffe097          	auipc	ra,0xffffe
    800065ae:	462080e7          	jalr	1122(ra) # 80004a0c <nameiparent>
    800065b2:	892a                	mv	s2,a0
    800065b4:	12050e63          	beqz	a0,800066f0 <create+0x162>
    return 0;

  ilock(dp);
    800065b8:	ffffe097          	auipc	ra,0xffffe
    800065bc:	c62080e7          	jalr	-926(ra) # 8000421a <ilock>
  
  if((ip = dirlookup(dp, name, 0)) != 0){
    800065c0:	4601                	li	a2,0
    800065c2:	fb040593          	addi	a1,s0,-80
    800065c6:	854a                	mv	a0,s2
    800065c8:	ffffe097          	auipc	ra,0xffffe
    800065cc:	154080e7          	jalr	340(ra) # 8000471c <dirlookup>
    800065d0:	84aa                	mv	s1,a0
    800065d2:	c921                	beqz	a0,80006622 <create+0x94>
    iunlockput(dp);
    800065d4:	854a                	mv	a0,s2
    800065d6:	ffffe097          	auipc	ra,0xffffe
    800065da:	ea6080e7          	jalr	-346(ra) # 8000447c <iunlockput>
    ilock(ip);
    800065de:	8526                	mv	a0,s1
    800065e0:	ffffe097          	auipc	ra,0xffffe
    800065e4:	c3a080e7          	jalr	-966(ra) # 8000421a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800065e8:	2981                	sext.w	s3,s3
    800065ea:	4789                	li	a5,2
    800065ec:	02f99463          	bne	s3,a5,80006614 <create+0x86>
    800065f0:	0444d783          	lhu	a5,68(s1)
    800065f4:	37f9                	addiw	a5,a5,-2
    800065f6:	17c2                	slli	a5,a5,0x30
    800065f8:	93c1                	srli	a5,a5,0x30
    800065fa:	4705                	li	a4,1
    800065fc:	00f76c63          	bltu	a4,a5,80006614 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80006600:	8526                	mv	a0,s1
    80006602:	60a6                	ld	ra,72(sp)
    80006604:	6406                	ld	s0,64(sp)
    80006606:	74e2                	ld	s1,56(sp)
    80006608:	7942                	ld	s2,48(sp)
    8000660a:	79a2                	ld	s3,40(sp)
    8000660c:	7a02                	ld	s4,32(sp)
    8000660e:	6ae2                	ld	s5,24(sp)
    80006610:	6161                	addi	sp,sp,80
    80006612:	8082                	ret
    iunlockput(ip);
    80006614:	8526                	mv	a0,s1
    80006616:	ffffe097          	auipc	ra,0xffffe
    8000661a:	e66080e7          	jalr	-410(ra) # 8000447c <iunlockput>
    return 0;
    8000661e:	4481                	li	s1,0
    80006620:	b7c5                	j	80006600 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80006622:	85ce                	mv	a1,s3
    80006624:	00092503          	lw	a0,0(s2)
    80006628:	ffffe097          	auipc	ra,0xffffe
    8000662c:	a5a080e7          	jalr	-1446(ra) # 80004082 <ialloc>
    80006630:	84aa                	mv	s1,a0
    80006632:	c521                	beqz	a0,8000667a <create+0xec>
  ilock(ip);
    80006634:	ffffe097          	auipc	ra,0xffffe
    80006638:	be6080e7          	jalr	-1050(ra) # 8000421a <ilock>
  ip->major = major;
    8000663c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80006640:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80006644:	4a05                	li	s4,1
    80006646:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000664a:	8526                	mv	a0,s1
    8000664c:	ffffe097          	auipc	ra,0xffffe
    80006650:	b04080e7          	jalr	-1276(ra) # 80004150 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80006654:	2981                	sext.w	s3,s3
    80006656:	03498a63          	beq	s3,s4,8000668a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000665a:	40d0                	lw	a2,4(s1)
    8000665c:	fb040593          	addi	a1,s0,-80
    80006660:	854a                	mv	a0,s2
    80006662:	ffffe097          	auipc	ra,0xffffe
    80006666:	2ca080e7          	jalr	714(ra) # 8000492c <dirlink>
    8000666a:	06054b63          	bltz	a0,800066e0 <create+0x152>
  iunlockput(dp);
    8000666e:	854a                	mv	a0,s2
    80006670:	ffffe097          	auipc	ra,0xffffe
    80006674:	e0c080e7          	jalr	-500(ra) # 8000447c <iunlockput>
  return ip;
    80006678:	b761                	j	80006600 <create+0x72>
    panic("create: ialloc");
    8000667a:	00003517          	auipc	a0,0x3
    8000667e:	28e50513          	addi	a0,a0,654 # 80009908 <syscalls+0x350>
    80006682:	ffffa097          	auipc	ra,0xffffa
    80006686:	ea8080e7          	jalr	-344(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000668a:	04a95783          	lhu	a5,74(s2)
    8000668e:	2785                	addiw	a5,a5,1
    80006690:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80006694:	854a                	mv	a0,s2
    80006696:	ffffe097          	auipc	ra,0xffffe
    8000669a:	aba080e7          	jalr	-1350(ra) # 80004150 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000669e:	40d0                	lw	a2,4(s1)
    800066a0:	00003597          	auipc	a1,0x3
    800066a4:	12058593          	addi	a1,a1,288 # 800097c0 <syscalls+0x208>
    800066a8:	8526                	mv	a0,s1
    800066aa:	ffffe097          	auipc	ra,0xffffe
    800066ae:	282080e7          	jalr	642(ra) # 8000492c <dirlink>
    800066b2:	00054f63          	bltz	a0,800066d0 <create+0x142>
    800066b6:	00492603          	lw	a2,4(s2)
    800066ba:	00003597          	auipc	a1,0x3
    800066be:	10e58593          	addi	a1,a1,270 # 800097c8 <syscalls+0x210>
    800066c2:	8526                	mv	a0,s1
    800066c4:	ffffe097          	auipc	ra,0xffffe
    800066c8:	268080e7          	jalr	616(ra) # 8000492c <dirlink>
    800066cc:	f80557e3          	bgez	a0,8000665a <create+0xcc>
      panic("create dots");
    800066d0:	00003517          	auipc	a0,0x3
    800066d4:	24850513          	addi	a0,a0,584 # 80009918 <syscalls+0x360>
    800066d8:	ffffa097          	auipc	ra,0xffffa
    800066dc:	e52080e7          	jalr	-430(ra) # 8000052a <panic>
    panic("create: dirlink");
    800066e0:	00003517          	auipc	a0,0x3
    800066e4:	24850513          	addi	a0,a0,584 # 80009928 <syscalls+0x370>
    800066e8:	ffffa097          	auipc	ra,0xffffa
    800066ec:	e42080e7          	jalr	-446(ra) # 8000052a <panic>
    return 0;
    800066f0:	84aa                	mv	s1,a0
    800066f2:	b739                	j	80006600 <create+0x72>

00000000800066f4 <sys_open>:

uint64
sys_open(void)
{
    800066f4:	7131                	addi	sp,sp,-192
    800066f6:	fd06                	sd	ra,184(sp)
    800066f8:	f922                	sd	s0,176(sp)
    800066fa:	f526                	sd	s1,168(sp)
    800066fc:	f14a                	sd	s2,160(sp)
    800066fe:	ed4e                	sd	s3,152(sp)
    80006700:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006702:	08000613          	li	a2,128
    80006706:	f5040593          	addi	a1,s0,-176
    8000670a:	4501                	li	a0,0
    8000670c:	ffffd097          	auipc	ra,0xffffd
    80006710:	fe0080e7          	jalr	-32(ra) # 800036ec <argstr>
    return -1;
    80006714:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80006716:	0c054163          	bltz	a0,800067d8 <sys_open+0xe4>
    8000671a:	f4c40593          	addi	a1,s0,-180
    8000671e:	4505                	li	a0,1
    80006720:	ffffd097          	auipc	ra,0xffffd
    80006724:	f88080e7          	jalr	-120(ra) # 800036a8 <argint>
    80006728:	0a054863          	bltz	a0,800067d8 <sys_open+0xe4>

  begin_op();
    8000672c:	ffffe097          	auipc	ra,0xffffe
    80006730:	7f4080e7          	jalr	2036(ra) # 80004f20 <begin_op>

  if(omode & O_CREATE){
    80006734:	f4c42783          	lw	a5,-180(s0)
    80006738:	2007f793          	andi	a5,a5,512
    8000673c:	cbdd                	beqz	a5,800067f2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000673e:	4681                	li	a3,0
    80006740:	4601                	li	a2,0
    80006742:	4589                	li	a1,2
    80006744:	f5040513          	addi	a0,s0,-176
    80006748:	00000097          	auipc	ra,0x0
    8000674c:	e46080e7          	jalr	-442(ra) # 8000658e <create>
    80006750:	892a                	mv	s2,a0
    if(ip == 0){
    80006752:	c959                	beqz	a0,800067e8 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006754:	04491703          	lh	a4,68(s2)
    80006758:	478d                	li	a5,3
    8000675a:	00f71763          	bne	a4,a5,80006768 <sys_open+0x74>
    8000675e:	04695703          	lhu	a4,70(s2)
    80006762:	47a5                	li	a5,9
    80006764:	0ce7ec63          	bltu	a5,a4,8000683c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006768:	fffff097          	auipc	ra,0xfffff
    8000676c:	bc8080e7          	jalr	-1080(ra) # 80005330 <filealloc>
    80006770:	89aa                	mv	s3,a0
    80006772:	10050263          	beqz	a0,80006876 <sys_open+0x182>
    80006776:	00000097          	auipc	ra,0x0
    8000677a:	8e2080e7          	jalr	-1822(ra) # 80006058 <fdalloc>
    8000677e:	84aa                	mv	s1,a0
    80006780:	0e054663          	bltz	a0,8000686c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006784:	04491703          	lh	a4,68(s2)
    80006788:	478d                	li	a5,3
    8000678a:	0cf70463          	beq	a4,a5,80006852 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000678e:	4789                	li	a5,2
    80006790:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006794:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006798:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000679c:	f4c42783          	lw	a5,-180(s0)
    800067a0:	0017c713          	xori	a4,a5,1
    800067a4:	8b05                	andi	a4,a4,1
    800067a6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800067aa:	0037f713          	andi	a4,a5,3
    800067ae:	00e03733          	snez	a4,a4
    800067b2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800067b6:	4007f793          	andi	a5,a5,1024
    800067ba:	c791                	beqz	a5,800067c6 <sys_open+0xd2>
    800067bc:	04491703          	lh	a4,68(s2)
    800067c0:	4789                	li	a5,2
    800067c2:	08f70f63          	beq	a4,a5,80006860 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800067c6:	854a                	mv	a0,s2
    800067c8:	ffffe097          	auipc	ra,0xffffe
    800067cc:	b14080e7          	jalr	-1260(ra) # 800042dc <iunlock>
  end_op();
    800067d0:	ffffe097          	auipc	ra,0xffffe
    800067d4:	7d0080e7          	jalr	2000(ra) # 80004fa0 <end_op>

  return fd;
}
    800067d8:	8526                	mv	a0,s1
    800067da:	70ea                	ld	ra,184(sp)
    800067dc:	744a                	ld	s0,176(sp)
    800067de:	74aa                	ld	s1,168(sp)
    800067e0:	790a                	ld	s2,160(sp)
    800067e2:	69ea                	ld	s3,152(sp)
    800067e4:	6129                	addi	sp,sp,192
    800067e6:	8082                	ret
      end_op();
    800067e8:	ffffe097          	auipc	ra,0xffffe
    800067ec:	7b8080e7          	jalr	1976(ra) # 80004fa0 <end_op>
      return -1;
    800067f0:	b7e5                	j	800067d8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800067f2:	f5040513          	addi	a0,s0,-176
    800067f6:	ffffe097          	auipc	ra,0xffffe
    800067fa:	1f8080e7          	jalr	504(ra) # 800049ee <namei>
    800067fe:	892a                	mv	s2,a0
    80006800:	c905                	beqz	a0,80006830 <sys_open+0x13c>
    ilock(ip);
    80006802:	ffffe097          	auipc	ra,0xffffe
    80006806:	a18080e7          	jalr	-1512(ra) # 8000421a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000680a:	04491703          	lh	a4,68(s2)
    8000680e:	4785                	li	a5,1
    80006810:	f4f712e3          	bne	a4,a5,80006754 <sys_open+0x60>
    80006814:	f4c42783          	lw	a5,-180(s0)
    80006818:	dba1                	beqz	a5,80006768 <sys_open+0x74>
      iunlockput(ip);
    8000681a:	854a                	mv	a0,s2
    8000681c:	ffffe097          	auipc	ra,0xffffe
    80006820:	c60080e7          	jalr	-928(ra) # 8000447c <iunlockput>
      end_op();
    80006824:	ffffe097          	auipc	ra,0xffffe
    80006828:	77c080e7          	jalr	1916(ra) # 80004fa0 <end_op>
      return -1;
    8000682c:	54fd                	li	s1,-1
    8000682e:	b76d                	j	800067d8 <sys_open+0xe4>
      end_op();
    80006830:	ffffe097          	auipc	ra,0xffffe
    80006834:	770080e7          	jalr	1904(ra) # 80004fa0 <end_op>
      return -1;
    80006838:	54fd                	li	s1,-1
    8000683a:	bf79                	j	800067d8 <sys_open+0xe4>
    iunlockput(ip);
    8000683c:	854a                	mv	a0,s2
    8000683e:	ffffe097          	auipc	ra,0xffffe
    80006842:	c3e080e7          	jalr	-962(ra) # 8000447c <iunlockput>
    end_op();
    80006846:	ffffe097          	auipc	ra,0xffffe
    8000684a:	75a080e7          	jalr	1882(ra) # 80004fa0 <end_op>
    return -1;
    8000684e:	54fd                	li	s1,-1
    80006850:	b761                	j	800067d8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006852:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006856:	04691783          	lh	a5,70(s2)
    8000685a:	02f99223          	sh	a5,36(s3)
    8000685e:	bf2d                	j	80006798 <sys_open+0xa4>
    itrunc(ip);
    80006860:	854a                	mv	a0,s2
    80006862:	ffffe097          	auipc	ra,0xffffe
    80006866:	ac6080e7          	jalr	-1338(ra) # 80004328 <itrunc>
    8000686a:	bfb1                	j	800067c6 <sys_open+0xd2>
      fileclose(f);
    8000686c:	854e                	mv	a0,s3
    8000686e:	fffff097          	auipc	ra,0xfffff
    80006872:	b7e080e7          	jalr	-1154(ra) # 800053ec <fileclose>
    iunlockput(ip);
    80006876:	854a                	mv	a0,s2
    80006878:	ffffe097          	auipc	ra,0xffffe
    8000687c:	c04080e7          	jalr	-1020(ra) # 8000447c <iunlockput>
    end_op();
    80006880:	ffffe097          	auipc	ra,0xffffe
    80006884:	720080e7          	jalr	1824(ra) # 80004fa0 <end_op>
    return -1;
    80006888:	54fd                	li	s1,-1
    8000688a:	b7b9                	j	800067d8 <sys_open+0xe4>

000000008000688c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000688c:	7175                	addi	sp,sp,-144
    8000688e:	e506                	sd	ra,136(sp)
    80006890:	e122                	sd	s0,128(sp)
    80006892:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006894:	ffffe097          	auipc	ra,0xffffe
    80006898:	68c080e7          	jalr	1676(ra) # 80004f20 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000689c:	08000613          	li	a2,128
    800068a0:	f7040593          	addi	a1,s0,-144
    800068a4:	4501                	li	a0,0
    800068a6:	ffffd097          	auipc	ra,0xffffd
    800068aa:	e46080e7          	jalr	-442(ra) # 800036ec <argstr>
    800068ae:	02054963          	bltz	a0,800068e0 <sys_mkdir+0x54>
    800068b2:	4681                	li	a3,0
    800068b4:	4601                	li	a2,0
    800068b6:	4585                	li	a1,1
    800068b8:	f7040513          	addi	a0,s0,-144
    800068bc:	00000097          	auipc	ra,0x0
    800068c0:	cd2080e7          	jalr	-814(ra) # 8000658e <create>
    800068c4:	cd11                	beqz	a0,800068e0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800068c6:	ffffe097          	auipc	ra,0xffffe
    800068ca:	bb6080e7          	jalr	-1098(ra) # 8000447c <iunlockput>
  end_op();
    800068ce:	ffffe097          	auipc	ra,0xffffe
    800068d2:	6d2080e7          	jalr	1746(ra) # 80004fa0 <end_op>
  return 0;
    800068d6:	4501                	li	a0,0
}
    800068d8:	60aa                	ld	ra,136(sp)
    800068da:	640a                	ld	s0,128(sp)
    800068dc:	6149                	addi	sp,sp,144
    800068de:	8082                	ret
    end_op();
    800068e0:	ffffe097          	auipc	ra,0xffffe
    800068e4:	6c0080e7          	jalr	1728(ra) # 80004fa0 <end_op>
    return -1;
    800068e8:	557d                	li	a0,-1
    800068ea:	b7fd                	j	800068d8 <sys_mkdir+0x4c>

00000000800068ec <sys_mknod>:

uint64
sys_mknod(void)
{
    800068ec:	7135                	addi	sp,sp,-160
    800068ee:	ed06                	sd	ra,152(sp)
    800068f0:	e922                	sd	s0,144(sp)
    800068f2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800068f4:	ffffe097          	auipc	ra,0xffffe
    800068f8:	62c080e7          	jalr	1580(ra) # 80004f20 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800068fc:	08000613          	li	a2,128
    80006900:	f7040593          	addi	a1,s0,-144
    80006904:	4501                	li	a0,0
    80006906:	ffffd097          	auipc	ra,0xffffd
    8000690a:	de6080e7          	jalr	-538(ra) # 800036ec <argstr>
    8000690e:	04054a63          	bltz	a0,80006962 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006912:	f6c40593          	addi	a1,s0,-148
    80006916:	4505                	li	a0,1
    80006918:	ffffd097          	auipc	ra,0xffffd
    8000691c:	d90080e7          	jalr	-624(ra) # 800036a8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006920:	04054163          	bltz	a0,80006962 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006924:	f6840593          	addi	a1,s0,-152
    80006928:	4509                	li	a0,2
    8000692a:	ffffd097          	auipc	ra,0xffffd
    8000692e:	d7e080e7          	jalr	-642(ra) # 800036a8 <argint>
     argint(1, &major) < 0 ||
    80006932:	02054863          	bltz	a0,80006962 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006936:	f6841683          	lh	a3,-152(s0)
    8000693a:	f6c41603          	lh	a2,-148(s0)
    8000693e:	458d                	li	a1,3
    80006940:	f7040513          	addi	a0,s0,-144
    80006944:	00000097          	auipc	ra,0x0
    80006948:	c4a080e7          	jalr	-950(ra) # 8000658e <create>
     argint(2, &minor) < 0 ||
    8000694c:	c919                	beqz	a0,80006962 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000694e:	ffffe097          	auipc	ra,0xffffe
    80006952:	b2e080e7          	jalr	-1234(ra) # 8000447c <iunlockput>
  end_op();
    80006956:	ffffe097          	auipc	ra,0xffffe
    8000695a:	64a080e7          	jalr	1610(ra) # 80004fa0 <end_op>
  return 0;
    8000695e:	4501                	li	a0,0
    80006960:	a031                	j	8000696c <sys_mknod+0x80>
    end_op();
    80006962:	ffffe097          	auipc	ra,0xffffe
    80006966:	63e080e7          	jalr	1598(ra) # 80004fa0 <end_op>
    return -1;
    8000696a:	557d                	li	a0,-1
}
    8000696c:	60ea                	ld	ra,152(sp)
    8000696e:	644a                	ld	s0,144(sp)
    80006970:	610d                	addi	sp,sp,160
    80006972:	8082                	ret

0000000080006974 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006974:	7135                	addi	sp,sp,-160
    80006976:	ed06                	sd	ra,152(sp)
    80006978:	e922                	sd	s0,144(sp)
    8000697a:	e526                	sd	s1,136(sp)
    8000697c:	e14a                	sd	s2,128(sp)
    8000697e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006980:	ffffc097          	auipc	ra,0xffffc
    80006984:	a5a080e7          	jalr	-1446(ra) # 800023da <myproc>
    80006988:	892a                	mv	s2,a0
  
  begin_op();
    8000698a:	ffffe097          	auipc	ra,0xffffe
    8000698e:	596080e7          	jalr	1430(ra) # 80004f20 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006992:	08000613          	li	a2,128
    80006996:	f6040593          	addi	a1,s0,-160
    8000699a:	4501                	li	a0,0
    8000699c:	ffffd097          	auipc	ra,0xffffd
    800069a0:	d50080e7          	jalr	-688(ra) # 800036ec <argstr>
    800069a4:	04054b63          	bltz	a0,800069fa <sys_chdir+0x86>
    800069a8:	f6040513          	addi	a0,s0,-160
    800069ac:	ffffe097          	auipc	ra,0xffffe
    800069b0:	042080e7          	jalr	66(ra) # 800049ee <namei>
    800069b4:	84aa                	mv	s1,a0
    800069b6:	c131                	beqz	a0,800069fa <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800069b8:	ffffe097          	auipc	ra,0xffffe
    800069bc:	862080e7          	jalr	-1950(ra) # 8000421a <ilock>
  if(ip->type != T_DIR){
    800069c0:	04449703          	lh	a4,68(s1)
    800069c4:	4785                	li	a5,1
    800069c6:	04f71063          	bne	a4,a5,80006a06 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800069ca:	8526                	mv	a0,s1
    800069cc:	ffffe097          	auipc	ra,0xffffe
    800069d0:	910080e7          	jalr	-1776(ra) # 800042dc <iunlock>
  iput(p->cwd);
    800069d4:	15093503          	ld	a0,336(s2)
    800069d8:	ffffe097          	auipc	ra,0xffffe
    800069dc:	9fc080e7          	jalr	-1540(ra) # 800043d4 <iput>
  end_op();
    800069e0:	ffffe097          	auipc	ra,0xffffe
    800069e4:	5c0080e7          	jalr	1472(ra) # 80004fa0 <end_op>
  p->cwd = ip;
    800069e8:	14993823          	sd	s1,336(s2)
  return 0;
    800069ec:	4501                	li	a0,0
}
    800069ee:	60ea                	ld	ra,152(sp)
    800069f0:	644a                	ld	s0,144(sp)
    800069f2:	64aa                	ld	s1,136(sp)
    800069f4:	690a                	ld	s2,128(sp)
    800069f6:	610d                	addi	sp,sp,160
    800069f8:	8082                	ret
    end_op();
    800069fa:	ffffe097          	auipc	ra,0xffffe
    800069fe:	5a6080e7          	jalr	1446(ra) # 80004fa0 <end_op>
    return -1;
    80006a02:	557d                	li	a0,-1
    80006a04:	b7ed                	j	800069ee <sys_chdir+0x7a>
    iunlockput(ip);
    80006a06:	8526                	mv	a0,s1
    80006a08:	ffffe097          	auipc	ra,0xffffe
    80006a0c:	a74080e7          	jalr	-1420(ra) # 8000447c <iunlockput>
    end_op();
    80006a10:	ffffe097          	auipc	ra,0xffffe
    80006a14:	590080e7          	jalr	1424(ra) # 80004fa0 <end_op>
    return -1;
    80006a18:	557d                	li	a0,-1
    80006a1a:	bfd1                	j	800069ee <sys_chdir+0x7a>

0000000080006a1c <sys_exec>:

uint64
sys_exec(void)
{
    80006a1c:	7145                	addi	sp,sp,-464
    80006a1e:	e786                	sd	ra,456(sp)
    80006a20:	e3a2                	sd	s0,448(sp)
    80006a22:	ff26                	sd	s1,440(sp)
    80006a24:	fb4a                	sd	s2,432(sp)
    80006a26:	f74e                	sd	s3,424(sp)
    80006a28:	f352                	sd	s4,416(sp)
    80006a2a:	ef56                	sd	s5,408(sp)
    80006a2c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006a2e:	08000613          	li	a2,128
    80006a32:	f4040593          	addi	a1,s0,-192
    80006a36:	4501                	li	a0,0
    80006a38:	ffffd097          	auipc	ra,0xffffd
    80006a3c:	cb4080e7          	jalr	-844(ra) # 800036ec <argstr>
    return -1;
    80006a40:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006a42:	0c054a63          	bltz	a0,80006b16 <sys_exec+0xfa>
    80006a46:	e3840593          	addi	a1,s0,-456
    80006a4a:	4505                	li	a0,1
    80006a4c:	ffffd097          	auipc	ra,0xffffd
    80006a50:	c7e080e7          	jalr	-898(ra) # 800036ca <argaddr>
    80006a54:	0c054163          	bltz	a0,80006b16 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006a58:	10000613          	li	a2,256
    80006a5c:	4581                	li	a1,0
    80006a5e:	e4040513          	addi	a0,s0,-448
    80006a62:	ffffa097          	auipc	ra,0xffffa
    80006a66:	26c080e7          	jalr	620(ra) # 80000cce <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006a6a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006a6e:	89a6                	mv	s3,s1
    80006a70:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006a72:	02000a13          	li	s4,32
    80006a76:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006a7a:	00391793          	slli	a5,s2,0x3
    80006a7e:	e3040593          	addi	a1,s0,-464
    80006a82:	e3843503          	ld	a0,-456(s0)
    80006a86:	953e                	add	a0,a0,a5
    80006a88:	ffffd097          	auipc	ra,0xffffd
    80006a8c:	b86080e7          	jalr	-1146(ra) # 8000360e <fetchaddr>
    80006a90:	02054a63          	bltz	a0,80006ac4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006a94:	e3043783          	ld	a5,-464(s0)
    80006a98:	c3b9                	beqz	a5,80006ade <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006a9a:	ffffa097          	auipc	ra,0xffffa
    80006a9e:	048080e7          	jalr	72(ra) # 80000ae2 <kalloc>
    80006aa2:	85aa                	mv	a1,a0
    80006aa4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006aa8:	cd11                	beqz	a0,80006ac4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006aaa:	6605                	lui	a2,0x1
    80006aac:	e3043503          	ld	a0,-464(s0)
    80006ab0:	ffffd097          	auipc	ra,0xffffd
    80006ab4:	bb0080e7          	jalr	-1104(ra) # 80003660 <fetchstr>
    80006ab8:	00054663          	bltz	a0,80006ac4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006abc:	0905                	addi	s2,s2,1
    80006abe:	09a1                	addi	s3,s3,8
    80006ac0:	fb491be3          	bne	s2,s4,80006a76 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ac4:	10048913          	addi	s2,s1,256
    80006ac8:	6088                	ld	a0,0(s1)
    80006aca:	c529                	beqz	a0,80006b14 <sys_exec+0xf8>
    kfree(argv[i]);
    80006acc:	ffffa097          	auipc	ra,0xffffa
    80006ad0:	f0a080e7          	jalr	-246(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006ad4:	04a1                	addi	s1,s1,8
    80006ad6:	ff2499e3          	bne	s1,s2,80006ac8 <sys_exec+0xac>
  return -1;
    80006ada:	597d                	li	s2,-1
    80006adc:	a82d                	j	80006b16 <sys_exec+0xfa>
      argv[i] = 0;
    80006ade:	0a8e                	slli	s5,s5,0x3
    80006ae0:	fc040793          	addi	a5,s0,-64
    80006ae4:	9abe                	add	s5,s5,a5
    80006ae6:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffcfe80>
  int ret = exec(path, argv);
    80006aea:	e4040593          	addi	a1,s0,-448
    80006aee:	f4040513          	addi	a0,s0,-192
    80006af2:	fffff097          	auipc	ra,0xfffff
    80006af6:	156080e7          	jalr	342(ra) # 80005c48 <exec>
    80006afa:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006afc:	10048993          	addi	s3,s1,256
    80006b00:	6088                	ld	a0,0(s1)
    80006b02:	c911                	beqz	a0,80006b16 <sys_exec+0xfa>
    kfree(argv[i]);
    80006b04:	ffffa097          	auipc	ra,0xffffa
    80006b08:	ed2080e7          	jalr	-302(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006b0c:	04a1                	addi	s1,s1,8
    80006b0e:	ff3499e3          	bne	s1,s3,80006b00 <sys_exec+0xe4>
    80006b12:	a011                	j	80006b16 <sys_exec+0xfa>
  return -1;
    80006b14:	597d                	li	s2,-1
}
    80006b16:	854a                	mv	a0,s2
    80006b18:	60be                	ld	ra,456(sp)
    80006b1a:	641e                	ld	s0,448(sp)
    80006b1c:	74fa                	ld	s1,440(sp)
    80006b1e:	795a                	ld	s2,432(sp)
    80006b20:	79ba                	ld	s3,424(sp)
    80006b22:	7a1a                	ld	s4,416(sp)
    80006b24:	6afa                	ld	s5,408(sp)
    80006b26:	6179                	addi	sp,sp,464
    80006b28:	8082                	ret

0000000080006b2a <sys_pipe>:

uint64
sys_pipe(void)
{
    80006b2a:	7139                	addi	sp,sp,-64
    80006b2c:	fc06                	sd	ra,56(sp)
    80006b2e:	f822                	sd	s0,48(sp)
    80006b30:	f426                	sd	s1,40(sp)
    80006b32:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006b34:	ffffc097          	auipc	ra,0xffffc
    80006b38:	8a6080e7          	jalr	-1882(ra) # 800023da <myproc>
    80006b3c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006b3e:	fd840593          	addi	a1,s0,-40
    80006b42:	4501                	li	a0,0
    80006b44:	ffffd097          	auipc	ra,0xffffd
    80006b48:	b86080e7          	jalr	-1146(ra) # 800036ca <argaddr>
    return -1;
    80006b4c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006b4e:	0e054063          	bltz	a0,80006c2e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006b52:	fc840593          	addi	a1,s0,-56
    80006b56:	fd040513          	addi	a0,s0,-48
    80006b5a:	fffff097          	auipc	ra,0xfffff
    80006b5e:	dcc080e7          	jalr	-564(ra) # 80005926 <pipealloc>
    return -1;
    80006b62:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006b64:	0c054563          	bltz	a0,80006c2e <sys_pipe+0x104>
  fd0 = -1;
    80006b68:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006b6c:	fd043503          	ld	a0,-48(s0)
    80006b70:	fffff097          	auipc	ra,0xfffff
    80006b74:	4e8080e7          	jalr	1256(ra) # 80006058 <fdalloc>
    80006b78:	fca42223          	sw	a0,-60(s0)
    80006b7c:	08054c63          	bltz	a0,80006c14 <sys_pipe+0xea>
    80006b80:	fc843503          	ld	a0,-56(s0)
    80006b84:	fffff097          	auipc	ra,0xfffff
    80006b88:	4d4080e7          	jalr	1236(ra) # 80006058 <fdalloc>
    80006b8c:	fca42023          	sw	a0,-64(s0)
    80006b90:	06054863          	bltz	a0,80006c00 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006b94:	4691                	li	a3,4
    80006b96:	fc440613          	addi	a2,s0,-60
    80006b9a:	fd843583          	ld	a1,-40(s0)
    80006b9e:	68a8                	ld	a0,80(s1)
    80006ba0:	ffffb097          	auipc	ra,0xffffb
    80006ba4:	8ea080e7          	jalr	-1814(ra) # 8000148a <copyout>
    80006ba8:	02054063          	bltz	a0,80006bc8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006bac:	4691                	li	a3,4
    80006bae:	fc040613          	addi	a2,s0,-64
    80006bb2:	fd843583          	ld	a1,-40(s0)
    80006bb6:	0591                	addi	a1,a1,4
    80006bb8:	68a8                	ld	a0,80(s1)
    80006bba:	ffffb097          	auipc	ra,0xffffb
    80006bbe:	8d0080e7          	jalr	-1840(ra) # 8000148a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006bc2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006bc4:	06055563          	bgez	a0,80006c2e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006bc8:	fc442783          	lw	a5,-60(s0)
    80006bcc:	07e9                	addi	a5,a5,26
    80006bce:	078e                	slli	a5,a5,0x3
    80006bd0:	97a6                	add	a5,a5,s1
    80006bd2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006bd6:	fc042503          	lw	a0,-64(s0)
    80006bda:	0569                	addi	a0,a0,26
    80006bdc:	050e                	slli	a0,a0,0x3
    80006bde:	9526                	add	a0,a0,s1
    80006be0:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006be4:	fd043503          	ld	a0,-48(s0)
    80006be8:	fffff097          	auipc	ra,0xfffff
    80006bec:	804080e7          	jalr	-2044(ra) # 800053ec <fileclose>
    fileclose(wf);
    80006bf0:	fc843503          	ld	a0,-56(s0)
    80006bf4:	ffffe097          	auipc	ra,0xffffe
    80006bf8:	7f8080e7          	jalr	2040(ra) # 800053ec <fileclose>
    return -1;
    80006bfc:	57fd                	li	a5,-1
    80006bfe:	a805                	j	80006c2e <sys_pipe+0x104>
    if(fd0 >= 0)
    80006c00:	fc442783          	lw	a5,-60(s0)
    80006c04:	0007c863          	bltz	a5,80006c14 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006c08:	01a78513          	addi	a0,a5,26
    80006c0c:	050e                	slli	a0,a0,0x3
    80006c0e:	9526                	add	a0,a0,s1
    80006c10:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006c14:	fd043503          	ld	a0,-48(s0)
    80006c18:	ffffe097          	auipc	ra,0xffffe
    80006c1c:	7d4080e7          	jalr	2004(ra) # 800053ec <fileclose>
    fileclose(wf);
    80006c20:	fc843503          	ld	a0,-56(s0)
    80006c24:	ffffe097          	auipc	ra,0xffffe
    80006c28:	7c8080e7          	jalr	1992(ra) # 800053ec <fileclose>
    return -1;
    80006c2c:	57fd                	li	a5,-1
}
    80006c2e:	853e                	mv	a0,a5
    80006c30:	70e2                	ld	ra,56(sp)
    80006c32:	7442                	ld	s0,48(sp)
    80006c34:	74a2                	ld	s1,40(sp)
    80006c36:	6121                	addi	sp,sp,64
    80006c38:	8082                	ret
    80006c3a:	0000                	unimp
    80006c3c:	0000                	unimp
	...

0000000080006c40 <kernelvec>:
    80006c40:	7111                	addi	sp,sp,-256
    80006c42:	e006                	sd	ra,0(sp)
    80006c44:	e40a                	sd	sp,8(sp)
    80006c46:	e80e                	sd	gp,16(sp)
    80006c48:	ec12                	sd	tp,24(sp)
    80006c4a:	f016                	sd	t0,32(sp)
    80006c4c:	f41a                	sd	t1,40(sp)
    80006c4e:	f81e                	sd	t2,48(sp)
    80006c50:	fc22                	sd	s0,56(sp)
    80006c52:	e0a6                	sd	s1,64(sp)
    80006c54:	e4aa                	sd	a0,72(sp)
    80006c56:	e8ae                	sd	a1,80(sp)
    80006c58:	ecb2                	sd	a2,88(sp)
    80006c5a:	f0b6                	sd	a3,96(sp)
    80006c5c:	f4ba                	sd	a4,104(sp)
    80006c5e:	f8be                	sd	a5,112(sp)
    80006c60:	fcc2                	sd	a6,120(sp)
    80006c62:	e146                	sd	a7,128(sp)
    80006c64:	e54a                	sd	s2,136(sp)
    80006c66:	e94e                	sd	s3,144(sp)
    80006c68:	ed52                	sd	s4,152(sp)
    80006c6a:	f156                	sd	s5,160(sp)
    80006c6c:	f55a                	sd	s6,168(sp)
    80006c6e:	f95e                	sd	s7,176(sp)
    80006c70:	fd62                	sd	s8,184(sp)
    80006c72:	e1e6                	sd	s9,192(sp)
    80006c74:	e5ea                	sd	s10,200(sp)
    80006c76:	e9ee                	sd	s11,208(sp)
    80006c78:	edf2                	sd	t3,216(sp)
    80006c7a:	f1f6                	sd	t4,224(sp)
    80006c7c:	f5fa                	sd	t5,232(sp)
    80006c7e:	f9fe                	sd	t6,240(sp)
    80006c80:	85bfc0ef          	jal	ra,800034da <kerneltrap>
    80006c84:	6082                	ld	ra,0(sp)
    80006c86:	6122                	ld	sp,8(sp)
    80006c88:	61c2                	ld	gp,16(sp)
    80006c8a:	7282                	ld	t0,32(sp)
    80006c8c:	7322                	ld	t1,40(sp)
    80006c8e:	73c2                	ld	t2,48(sp)
    80006c90:	7462                	ld	s0,56(sp)
    80006c92:	6486                	ld	s1,64(sp)
    80006c94:	6526                	ld	a0,72(sp)
    80006c96:	65c6                	ld	a1,80(sp)
    80006c98:	6666                	ld	a2,88(sp)
    80006c9a:	7686                	ld	a3,96(sp)
    80006c9c:	7726                	ld	a4,104(sp)
    80006c9e:	77c6                	ld	a5,112(sp)
    80006ca0:	7866                	ld	a6,120(sp)
    80006ca2:	688a                	ld	a7,128(sp)
    80006ca4:	692a                	ld	s2,136(sp)
    80006ca6:	69ca                	ld	s3,144(sp)
    80006ca8:	6a6a                	ld	s4,152(sp)
    80006caa:	7a8a                	ld	s5,160(sp)
    80006cac:	7b2a                	ld	s6,168(sp)
    80006cae:	7bca                	ld	s7,176(sp)
    80006cb0:	7c6a                	ld	s8,184(sp)
    80006cb2:	6c8e                	ld	s9,192(sp)
    80006cb4:	6d2e                	ld	s10,200(sp)
    80006cb6:	6dce                	ld	s11,208(sp)
    80006cb8:	6e6e                	ld	t3,216(sp)
    80006cba:	7e8e                	ld	t4,224(sp)
    80006cbc:	7f2e                	ld	t5,232(sp)
    80006cbe:	7fce                	ld	t6,240(sp)
    80006cc0:	6111                	addi	sp,sp,256
    80006cc2:	10200073          	sret
    80006cc6:	00000013          	nop
    80006cca:	00000013          	nop
    80006cce:	0001                	nop

0000000080006cd0 <timervec>:
    80006cd0:	34051573          	csrrw	a0,mscratch,a0
    80006cd4:	e10c                	sd	a1,0(a0)
    80006cd6:	e510                	sd	a2,8(a0)
    80006cd8:	e914                	sd	a3,16(a0)
    80006cda:	6d0c                	ld	a1,24(a0)
    80006cdc:	7110                	ld	a2,32(a0)
    80006cde:	6194                	ld	a3,0(a1)
    80006ce0:	96b2                	add	a3,a3,a2
    80006ce2:	e194                	sd	a3,0(a1)
    80006ce4:	4589                	li	a1,2
    80006ce6:	14459073          	csrw	sip,a1
    80006cea:	6914                	ld	a3,16(a0)
    80006cec:	6510                	ld	a2,8(a0)
    80006cee:	610c                	ld	a1,0(a0)
    80006cf0:	34051573          	csrrw	a0,mscratch,a0
    80006cf4:	30200073          	mret
	...

0000000080006cfa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006cfa:	1141                	addi	sp,sp,-16
    80006cfc:	e422                	sd	s0,8(sp)
    80006cfe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006d00:	0c0007b7          	lui	a5,0xc000
    80006d04:	4705                	li	a4,1
    80006d06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006d08:	c3d8                	sw	a4,4(a5)
}
    80006d0a:	6422                	ld	s0,8(sp)
    80006d0c:	0141                	addi	sp,sp,16
    80006d0e:	8082                	ret

0000000080006d10 <plicinithart>:

void
plicinithart(void)
{
    80006d10:	1141                	addi	sp,sp,-16
    80006d12:	e406                	sd	ra,8(sp)
    80006d14:	e022                	sd	s0,0(sp)
    80006d16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d18:	ffffb097          	auipc	ra,0xffffb
    80006d1c:	696080e7          	jalr	1686(ra) # 800023ae <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006d20:	0085171b          	slliw	a4,a0,0x8
    80006d24:	0c0027b7          	lui	a5,0xc002
    80006d28:	97ba                	add	a5,a5,a4
    80006d2a:	40200713          	li	a4,1026
    80006d2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006d32:	00d5151b          	slliw	a0,a0,0xd
    80006d36:	0c2017b7          	lui	a5,0xc201
    80006d3a:	953e                	add	a0,a0,a5
    80006d3c:	00052023          	sw	zero,0(a0)
}
    80006d40:	60a2                	ld	ra,8(sp)
    80006d42:	6402                	ld	s0,0(sp)
    80006d44:	0141                	addi	sp,sp,16
    80006d46:	8082                	ret

0000000080006d48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006d48:	1141                	addi	sp,sp,-16
    80006d4a:	e406                	sd	ra,8(sp)
    80006d4c:	e022                	sd	s0,0(sp)
    80006d4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006d50:	ffffb097          	auipc	ra,0xffffb
    80006d54:	65e080e7          	jalr	1630(ra) # 800023ae <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006d58:	00d5179b          	slliw	a5,a0,0xd
    80006d5c:	0c201537          	lui	a0,0xc201
    80006d60:	953e                	add	a0,a0,a5
  return irq;
}
    80006d62:	4148                	lw	a0,4(a0)
    80006d64:	60a2                	ld	ra,8(sp)
    80006d66:	6402                	ld	s0,0(sp)
    80006d68:	0141                	addi	sp,sp,16
    80006d6a:	8082                	ret

0000000080006d6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006d6c:	1101                	addi	sp,sp,-32
    80006d6e:	ec06                	sd	ra,24(sp)
    80006d70:	e822                	sd	s0,16(sp)
    80006d72:	e426                	sd	s1,8(sp)
    80006d74:	1000                	addi	s0,sp,32
    80006d76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006d78:	ffffb097          	auipc	ra,0xffffb
    80006d7c:	636080e7          	jalr	1590(ra) # 800023ae <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006d80:	00d5151b          	slliw	a0,a0,0xd
    80006d84:	0c2017b7          	lui	a5,0xc201
    80006d88:	97aa                	add	a5,a5,a0
    80006d8a:	c3c4                	sw	s1,4(a5)
}
    80006d8c:	60e2                	ld	ra,24(sp)
    80006d8e:	6442                	ld	s0,16(sp)
    80006d90:	64a2                	ld	s1,8(sp)
    80006d92:	6105                	addi	sp,sp,32
    80006d94:	8082                	ret

0000000080006d96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006d96:	1141                	addi	sp,sp,-16
    80006d98:	e406                	sd	ra,8(sp)
    80006d9a:	e022                	sd	s0,0(sp)
    80006d9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006d9e:	479d                	li	a5,7
    80006da0:	06a7c963          	blt	a5,a0,80006e12 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006da4:	00025797          	auipc	a5,0x25
    80006da8:	25c78793          	addi	a5,a5,604 # 8002c000 <disk>
    80006dac:	00a78733          	add	a4,a5,a0
    80006db0:	6789                	lui	a5,0x2
    80006db2:	97ba                	add	a5,a5,a4
    80006db4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006db8:	e7ad                	bnez	a5,80006e22 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006dba:	00451793          	slli	a5,a0,0x4
    80006dbe:	00027717          	auipc	a4,0x27
    80006dc2:	24270713          	addi	a4,a4,578 # 8002e000 <disk+0x2000>
    80006dc6:	6314                	ld	a3,0(a4)
    80006dc8:	96be                	add	a3,a3,a5
    80006dca:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006dce:	6314                	ld	a3,0(a4)
    80006dd0:	96be                	add	a3,a3,a5
    80006dd2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006dd6:	6314                	ld	a3,0(a4)
    80006dd8:	96be                	add	a3,a3,a5
    80006dda:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80006dde:	6318                	ld	a4,0(a4)
    80006de0:	97ba                	add	a5,a5,a4
    80006de2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006de6:	00025797          	auipc	a5,0x25
    80006dea:	21a78793          	addi	a5,a5,538 # 8002c000 <disk>
    80006dee:	97aa                	add	a5,a5,a0
    80006df0:	6509                	lui	a0,0x2
    80006df2:	953e                	add	a0,a0,a5
    80006df4:	4785                	li	a5,1
    80006df6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006dfa:	00027517          	auipc	a0,0x27
    80006dfe:	21e50513          	addi	a0,a0,542 # 8002e018 <disk+0x2018>
    80006e02:	ffffc097          	auipc	ra,0xffffc
    80006e06:	00c080e7          	jalr	12(ra) # 80002e0e <wakeup>
}
    80006e0a:	60a2                	ld	ra,8(sp)
    80006e0c:	6402                	ld	s0,0(sp)
    80006e0e:	0141                	addi	sp,sp,16
    80006e10:	8082                	ret
    panic("free_desc 1");
    80006e12:	00003517          	auipc	a0,0x3
    80006e16:	b2650513          	addi	a0,a0,-1242 # 80009938 <syscalls+0x380>
    80006e1a:	ffff9097          	auipc	ra,0xffff9
    80006e1e:	710080e7          	jalr	1808(ra) # 8000052a <panic>
    panic("free_desc 2");
    80006e22:	00003517          	auipc	a0,0x3
    80006e26:	b2650513          	addi	a0,a0,-1242 # 80009948 <syscalls+0x390>
    80006e2a:	ffff9097          	auipc	ra,0xffff9
    80006e2e:	700080e7          	jalr	1792(ra) # 8000052a <panic>

0000000080006e32 <virtio_disk_init>:
{
    80006e32:	1101                	addi	sp,sp,-32
    80006e34:	ec06                	sd	ra,24(sp)
    80006e36:	e822                	sd	s0,16(sp)
    80006e38:	e426                	sd	s1,8(sp)
    80006e3a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006e3c:	00003597          	auipc	a1,0x3
    80006e40:	b1c58593          	addi	a1,a1,-1252 # 80009958 <syscalls+0x3a0>
    80006e44:	00027517          	auipc	a0,0x27
    80006e48:	2e450513          	addi	a0,a0,740 # 8002e128 <disk+0x2128>
    80006e4c:	ffffa097          	auipc	ra,0xffffa
    80006e50:	cf6080e7          	jalr	-778(ra) # 80000b42 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e54:	100017b7          	lui	a5,0x10001
    80006e58:	4398                	lw	a4,0(a5)
    80006e5a:	2701                	sext.w	a4,a4
    80006e5c:	747277b7          	lui	a5,0x74727
    80006e60:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006e64:	0ef71163          	bne	a4,a5,80006f46 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006e68:	100017b7          	lui	a5,0x10001
    80006e6c:	43dc                	lw	a5,4(a5)
    80006e6e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006e70:	4705                	li	a4,1
    80006e72:	0ce79a63          	bne	a5,a4,80006f46 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e76:	100017b7          	lui	a5,0x10001
    80006e7a:	479c                	lw	a5,8(a5)
    80006e7c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006e7e:	4709                	li	a4,2
    80006e80:	0ce79363          	bne	a5,a4,80006f46 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006e84:	100017b7          	lui	a5,0x10001
    80006e88:	47d8                	lw	a4,12(a5)
    80006e8a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006e8c:	554d47b7          	lui	a5,0x554d4
    80006e90:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006e94:	0af71963          	bne	a4,a5,80006f46 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e98:	100017b7          	lui	a5,0x10001
    80006e9c:	4705                	li	a4,1
    80006e9e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006ea0:	470d                	li	a4,3
    80006ea2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006ea4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006ea6:	c7ffe737          	lui	a4,0xc7ffe
    80006eaa:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcf75f>
    80006eae:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006eb0:	2701                	sext.w	a4,a4
    80006eb2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006eb4:	472d                	li	a4,11
    80006eb6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006eb8:	473d                	li	a4,15
    80006eba:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006ebc:	6705                	lui	a4,0x1
    80006ebe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006ec0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006ec4:	5bdc                	lw	a5,52(a5)
    80006ec6:	2781                	sext.w	a5,a5
  if(max == 0)
    80006ec8:	c7d9                	beqz	a5,80006f56 <virtio_disk_init+0x124>
  if(max < NUM)
    80006eca:	471d                	li	a4,7
    80006ecc:	08f77d63          	bgeu	a4,a5,80006f66 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006ed0:	100014b7          	lui	s1,0x10001
    80006ed4:	47a1                	li	a5,8
    80006ed6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006ed8:	6609                	lui	a2,0x2
    80006eda:	4581                	li	a1,0
    80006edc:	00025517          	auipc	a0,0x25
    80006ee0:	12450513          	addi	a0,a0,292 # 8002c000 <disk>
    80006ee4:	ffffa097          	auipc	ra,0xffffa
    80006ee8:	dea080e7          	jalr	-534(ra) # 80000cce <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006eec:	00025717          	auipc	a4,0x25
    80006ef0:	11470713          	addi	a4,a4,276 # 8002c000 <disk>
    80006ef4:	00c75793          	srli	a5,a4,0xc
    80006ef8:	2781                	sext.w	a5,a5
    80006efa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80006efc:	00027797          	auipc	a5,0x27
    80006f00:	10478793          	addi	a5,a5,260 # 8002e000 <disk+0x2000>
    80006f04:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006f06:	00025717          	auipc	a4,0x25
    80006f0a:	17a70713          	addi	a4,a4,378 # 8002c080 <disk+0x80>
    80006f0e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006f10:	00026717          	auipc	a4,0x26
    80006f14:	0f070713          	addi	a4,a4,240 # 8002d000 <disk+0x1000>
    80006f18:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006f1a:	4705                	li	a4,1
    80006f1c:	00e78c23          	sb	a4,24(a5)
    80006f20:	00e78ca3          	sb	a4,25(a5)
    80006f24:	00e78d23          	sb	a4,26(a5)
    80006f28:	00e78da3          	sb	a4,27(a5)
    80006f2c:	00e78e23          	sb	a4,28(a5)
    80006f30:	00e78ea3          	sb	a4,29(a5)
    80006f34:	00e78f23          	sb	a4,30(a5)
    80006f38:	00e78fa3          	sb	a4,31(a5)
}
    80006f3c:	60e2                	ld	ra,24(sp)
    80006f3e:	6442                	ld	s0,16(sp)
    80006f40:	64a2                	ld	s1,8(sp)
    80006f42:	6105                	addi	sp,sp,32
    80006f44:	8082                	ret
    panic("could not find virtio disk");
    80006f46:	00003517          	auipc	a0,0x3
    80006f4a:	a2250513          	addi	a0,a0,-1502 # 80009968 <syscalls+0x3b0>
    80006f4e:	ffff9097          	auipc	ra,0xffff9
    80006f52:	5dc080e7          	jalr	1500(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006f56:	00003517          	auipc	a0,0x3
    80006f5a:	a3250513          	addi	a0,a0,-1486 # 80009988 <syscalls+0x3d0>
    80006f5e:	ffff9097          	auipc	ra,0xffff9
    80006f62:	5cc080e7          	jalr	1484(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006f66:	00003517          	auipc	a0,0x3
    80006f6a:	a4250513          	addi	a0,a0,-1470 # 800099a8 <syscalls+0x3f0>
    80006f6e:	ffff9097          	auipc	ra,0xffff9
    80006f72:	5bc080e7          	jalr	1468(ra) # 8000052a <panic>

0000000080006f76 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006f76:	7119                	addi	sp,sp,-128
    80006f78:	fc86                	sd	ra,120(sp)
    80006f7a:	f8a2                	sd	s0,112(sp)
    80006f7c:	f4a6                	sd	s1,104(sp)
    80006f7e:	f0ca                	sd	s2,96(sp)
    80006f80:	ecce                	sd	s3,88(sp)
    80006f82:	e8d2                	sd	s4,80(sp)
    80006f84:	e4d6                	sd	s5,72(sp)
    80006f86:	e0da                	sd	s6,64(sp)
    80006f88:	fc5e                	sd	s7,56(sp)
    80006f8a:	f862                	sd	s8,48(sp)
    80006f8c:	f466                	sd	s9,40(sp)
    80006f8e:	f06a                	sd	s10,32(sp)
    80006f90:	ec6e                	sd	s11,24(sp)
    80006f92:	0100                	addi	s0,sp,128
    80006f94:	8aaa                	mv	s5,a0
    80006f96:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006f98:	00c52c83          	lw	s9,12(a0)
    80006f9c:	001c9c9b          	slliw	s9,s9,0x1
    80006fa0:	1c82                	slli	s9,s9,0x20
    80006fa2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006fa6:	00027517          	auipc	a0,0x27
    80006faa:	18250513          	addi	a0,a0,386 # 8002e128 <disk+0x2128>
    80006fae:	ffffa097          	auipc	ra,0xffffa
    80006fb2:	c24080e7          	jalr	-988(ra) # 80000bd2 <acquire>
  for(int i = 0; i < 3; i++){
    80006fb6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006fb8:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006fba:	00025c17          	auipc	s8,0x25
    80006fbe:	046c0c13          	addi	s8,s8,70 # 8002c000 <disk>
    80006fc2:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006fc4:	4b0d                	li	s6,3
    80006fc6:	a0ad                	j	80007030 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006fc8:	00fc0733          	add	a4,s8,a5
    80006fcc:	975e                	add	a4,a4,s7
    80006fce:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006fd2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006fd4:	0207c563          	bltz	a5,80006ffe <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006fd8:	2905                	addiw	s2,s2,1
    80006fda:	0611                	addi	a2,a2,4
    80006fdc:	19690d63          	beq	s2,s6,80007176 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006fe0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006fe2:	00027717          	auipc	a4,0x27
    80006fe6:	03670713          	addi	a4,a4,54 # 8002e018 <disk+0x2018>
    80006fea:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006fec:	00074683          	lbu	a3,0(a4)
    80006ff0:	fee1                	bnez	a3,80006fc8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006ff2:	2785                	addiw	a5,a5,1
    80006ff4:	0705                	addi	a4,a4,1
    80006ff6:	fe979be3          	bne	a5,s1,80006fec <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006ffa:	57fd                	li	a5,-1
    80006ffc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006ffe:	01205d63          	blez	s2,80007018 <virtio_disk_rw+0xa2>
    80007002:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80007004:	000a2503          	lw	a0,0(s4)
    80007008:	00000097          	auipc	ra,0x0
    8000700c:	d8e080e7          	jalr	-626(ra) # 80006d96 <free_desc>
      for(int j = 0; j < i; j++)
    80007010:	2d85                	addiw	s11,s11,1
    80007012:	0a11                	addi	s4,s4,4
    80007014:	ffb918e3          	bne	s2,s11,80007004 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80007018:	00027597          	auipc	a1,0x27
    8000701c:	11058593          	addi	a1,a1,272 # 8002e128 <disk+0x2128>
    80007020:	00027517          	auipc	a0,0x27
    80007024:	ff850513          	addi	a0,a0,-8 # 8002e018 <disk+0x2018>
    80007028:	ffffc097          	auipc	ra,0xffffc
    8000702c:	c5a080e7          	jalr	-934(ra) # 80002c82 <sleep>
  for(int i = 0; i < 3; i++){
    80007030:	f8040a13          	addi	s4,s0,-128
{
    80007034:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80007036:	894e                	mv	s2,s3
    80007038:	b765                	j	80006fe0 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000703a:	00027697          	auipc	a3,0x27
    8000703e:	fc66b683          	ld	a3,-58(a3) # 8002e000 <disk+0x2000>
    80007042:	96ba                	add	a3,a3,a4
    80007044:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80007048:	00025817          	auipc	a6,0x25
    8000704c:	fb880813          	addi	a6,a6,-72 # 8002c000 <disk>
    80007050:	00027697          	auipc	a3,0x27
    80007054:	fb068693          	addi	a3,a3,-80 # 8002e000 <disk+0x2000>
    80007058:	6290                	ld	a2,0(a3)
    8000705a:	963a                	add	a2,a2,a4
    8000705c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80007060:	0015e593          	ori	a1,a1,1
    80007064:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80007068:	f8842603          	lw	a2,-120(s0)
    8000706c:	628c                	ld	a1,0(a3)
    8000706e:	972e                	add	a4,a4,a1
    80007070:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007074:	20050593          	addi	a1,a0,512
    80007078:	0592                	slli	a1,a1,0x4
    8000707a:	95c2                	add	a1,a1,a6
    8000707c:	577d                	li	a4,-1
    8000707e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80007082:	00461713          	slli	a4,a2,0x4
    80007086:	6290                	ld	a2,0(a3)
    80007088:	963a                	add	a2,a2,a4
    8000708a:	03078793          	addi	a5,a5,48
    8000708e:	97c2                	add	a5,a5,a6
    80007090:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80007092:	629c                	ld	a5,0(a3)
    80007094:	97ba                	add	a5,a5,a4
    80007096:	4605                	li	a2,1
    80007098:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000709a:	629c                	ld	a5,0(a3)
    8000709c:	97ba                	add	a5,a5,a4
    8000709e:	4809                	li	a6,2
    800070a0:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800070a4:	629c                	ld	a5,0(a3)
    800070a6:	973e                	add	a4,a4,a5
    800070a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800070ac:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800070b0:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800070b4:	6698                	ld	a4,8(a3)
    800070b6:	00275783          	lhu	a5,2(a4)
    800070ba:	8b9d                	andi	a5,a5,7
    800070bc:	0786                	slli	a5,a5,0x1
    800070be:	97ba                	add	a5,a5,a4
    800070c0:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    800070c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800070c8:	6698                	ld	a4,8(a3)
    800070ca:	00275783          	lhu	a5,2(a4)
    800070ce:	2785                	addiw	a5,a5,1
    800070d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800070d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800070d8:	100017b7          	lui	a5,0x10001
    800070dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800070e0:	004aa783          	lw	a5,4(s5)
    800070e4:	02c79163          	bne	a5,a2,80007106 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    800070e8:	00027917          	auipc	s2,0x27
    800070ec:	04090913          	addi	s2,s2,64 # 8002e128 <disk+0x2128>
  while(b->disk == 1) {
    800070f0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800070f2:	85ca                	mv	a1,s2
    800070f4:	8556                	mv	a0,s5
    800070f6:	ffffc097          	auipc	ra,0xffffc
    800070fa:	b8c080e7          	jalr	-1140(ra) # 80002c82 <sleep>
  while(b->disk == 1) {
    800070fe:	004aa783          	lw	a5,4(s5)
    80007102:	fe9788e3          	beq	a5,s1,800070f2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80007106:	f8042903          	lw	s2,-128(s0)
    8000710a:	20090793          	addi	a5,s2,512
    8000710e:	00479713          	slli	a4,a5,0x4
    80007112:	00025797          	auipc	a5,0x25
    80007116:	eee78793          	addi	a5,a5,-274 # 8002c000 <disk>
    8000711a:	97ba                	add	a5,a5,a4
    8000711c:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80007120:	00027997          	auipc	s3,0x27
    80007124:	ee098993          	addi	s3,s3,-288 # 8002e000 <disk+0x2000>
    80007128:	00491713          	slli	a4,s2,0x4
    8000712c:	0009b783          	ld	a5,0(s3)
    80007130:	97ba                	add	a5,a5,a4
    80007132:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80007136:	854a                	mv	a0,s2
    80007138:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000713c:	00000097          	auipc	ra,0x0
    80007140:	c5a080e7          	jalr	-934(ra) # 80006d96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80007144:	8885                	andi	s1,s1,1
    80007146:	f0ed                	bnez	s1,80007128 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80007148:	00027517          	auipc	a0,0x27
    8000714c:	fe050513          	addi	a0,a0,-32 # 8002e128 <disk+0x2128>
    80007150:	ffffa097          	auipc	ra,0xffffa
    80007154:	b36080e7          	jalr	-1226(ra) # 80000c86 <release>
}
    80007158:	70e6                	ld	ra,120(sp)
    8000715a:	7446                	ld	s0,112(sp)
    8000715c:	74a6                	ld	s1,104(sp)
    8000715e:	7906                	ld	s2,96(sp)
    80007160:	69e6                	ld	s3,88(sp)
    80007162:	6a46                	ld	s4,80(sp)
    80007164:	6aa6                	ld	s5,72(sp)
    80007166:	6b06                	ld	s6,64(sp)
    80007168:	7be2                	ld	s7,56(sp)
    8000716a:	7c42                	ld	s8,48(sp)
    8000716c:	7ca2                	ld	s9,40(sp)
    8000716e:	7d02                	ld	s10,32(sp)
    80007170:	6de2                	ld	s11,24(sp)
    80007172:	6109                	addi	sp,sp,128
    80007174:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80007176:	f8042503          	lw	a0,-128(s0)
    8000717a:	20050793          	addi	a5,a0,512
    8000717e:	0792                	slli	a5,a5,0x4
  if(write)
    80007180:	00025817          	auipc	a6,0x25
    80007184:	e8080813          	addi	a6,a6,-384 # 8002c000 <disk>
    80007188:	00f80733          	add	a4,a6,a5
    8000718c:	01a036b3          	snez	a3,s10
    80007190:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80007194:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80007198:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000719c:	7679                	lui	a2,0xffffe
    8000719e:	963e                	add	a2,a2,a5
    800071a0:	00027697          	auipc	a3,0x27
    800071a4:	e6068693          	addi	a3,a3,-416 # 8002e000 <disk+0x2000>
    800071a8:	6298                	ld	a4,0(a3)
    800071aa:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800071ac:	0a878593          	addi	a1,a5,168
    800071b0:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    800071b2:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800071b4:	6298                	ld	a4,0(a3)
    800071b6:	9732                	add	a4,a4,a2
    800071b8:	45c1                	li	a1,16
    800071ba:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800071bc:	6298                	ld	a4,0(a3)
    800071be:	9732                	add	a4,a4,a2
    800071c0:	4585                	li	a1,1
    800071c2:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800071c6:	f8442703          	lw	a4,-124(s0)
    800071ca:	628c                	ld	a1,0(a3)
    800071cc:	962e                	add	a2,a2,a1
    800071ce:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcf00e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    800071d2:	0712                	slli	a4,a4,0x4
    800071d4:	6290                	ld	a2,0(a3)
    800071d6:	963a                	add	a2,a2,a4
    800071d8:	058a8593          	addi	a1,s5,88
    800071dc:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800071de:	6294                	ld	a3,0(a3)
    800071e0:	96ba                	add	a3,a3,a4
    800071e2:	40000613          	li	a2,1024
    800071e6:	c690                	sw	a2,8(a3)
  if(write)
    800071e8:	e40d19e3          	bnez	s10,8000703a <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800071ec:	00027697          	auipc	a3,0x27
    800071f0:	e146b683          	ld	a3,-492(a3) # 8002e000 <disk+0x2000>
    800071f4:	96ba                	add	a3,a3,a4
    800071f6:	4609                	li	a2,2
    800071f8:	00c69623          	sh	a2,12(a3)
    800071fc:	b5b1                	j	80007048 <virtio_disk_rw+0xd2>

00000000800071fe <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800071fe:	1101                	addi	sp,sp,-32
    80007200:	ec06                	sd	ra,24(sp)
    80007202:	e822                	sd	s0,16(sp)
    80007204:	e426                	sd	s1,8(sp)
    80007206:	e04a                	sd	s2,0(sp)
    80007208:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000720a:	00027517          	auipc	a0,0x27
    8000720e:	f1e50513          	addi	a0,a0,-226 # 8002e128 <disk+0x2128>
    80007212:	ffffa097          	auipc	ra,0xffffa
    80007216:	9c0080e7          	jalr	-1600(ra) # 80000bd2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000721a:	10001737          	lui	a4,0x10001
    8000721e:	533c                	lw	a5,96(a4)
    80007220:	8b8d                	andi	a5,a5,3
    80007222:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007224:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007228:	00027797          	auipc	a5,0x27
    8000722c:	dd878793          	addi	a5,a5,-552 # 8002e000 <disk+0x2000>
    80007230:	6b94                	ld	a3,16(a5)
    80007232:	0207d703          	lhu	a4,32(a5)
    80007236:	0026d783          	lhu	a5,2(a3)
    8000723a:	06f70163          	beq	a4,a5,8000729c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000723e:	00025917          	auipc	s2,0x25
    80007242:	dc290913          	addi	s2,s2,-574 # 8002c000 <disk>
    80007246:	00027497          	auipc	s1,0x27
    8000724a:	dba48493          	addi	s1,s1,-582 # 8002e000 <disk+0x2000>
    __sync_synchronize();
    8000724e:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007252:	6898                	ld	a4,16(s1)
    80007254:	0204d783          	lhu	a5,32(s1)
    80007258:	8b9d                	andi	a5,a5,7
    8000725a:	078e                	slli	a5,a5,0x3
    8000725c:	97ba                	add	a5,a5,a4
    8000725e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007260:	20078713          	addi	a4,a5,512
    80007264:	0712                	slli	a4,a4,0x4
    80007266:	974a                	add	a4,a4,s2
    80007268:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000726c:	e731                	bnez	a4,800072b8 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000726e:	20078793          	addi	a5,a5,512
    80007272:	0792                	slli	a5,a5,0x4
    80007274:	97ca                	add	a5,a5,s2
    80007276:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80007278:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000727c:	ffffc097          	auipc	ra,0xffffc
    80007280:	b92080e7          	jalr	-1134(ra) # 80002e0e <wakeup>

    disk.used_idx += 1;
    80007284:	0204d783          	lhu	a5,32(s1)
    80007288:	2785                	addiw	a5,a5,1
    8000728a:	17c2                	slli	a5,a5,0x30
    8000728c:	93c1                	srli	a5,a5,0x30
    8000728e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80007292:	6898                	ld	a4,16(s1)
    80007294:	00275703          	lhu	a4,2(a4)
    80007298:	faf71be3          	bne	a4,a5,8000724e <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000729c:	00027517          	auipc	a0,0x27
    800072a0:	e8c50513          	addi	a0,a0,-372 # 8002e128 <disk+0x2128>
    800072a4:	ffffa097          	auipc	ra,0xffffa
    800072a8:	9e2080e7          	jalr	-1566(ra) # 80000c86 <release>
}
    800072ac:	60e2                	ld	ra,24(sp)
    800072ae:	6442                	ld	s0,16(sp)
    800072b0:	64a2                	ld	s1,8(sp)
    800072b2:	6902                	ld	s2,0(sp)
    800072b4:	6105                	addi	sp,sp,32
    800072b6:	8082                	ret
      panic("virtio_disk_intr status");
    800072b8:	00002517          	auipc	a0,0x2
    800072bc:	71050513          	addi	a0,a0,1808 # 800099c8 <syscalls+0x410>
    800072c0:	ffff9097          	auipc	ra,0xffff9
    800072c4:	26a080e7          	jalr	618(ra) # 8000052a <panic>
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
