
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c6010113          	addi	sp,sp,-928 # 80008c60 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	ace70713          	addi	a4,a4,-1330 # 80008b20 <timer_scratch>
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
    80000068:	ecc78793          	addi	a5,a5,-308 # 80005f30 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb257>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
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
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	580080e7          	jalr	1408(ra) # 800026ac <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ad450513          	addi	a0,a0,-1324 # 80010c60 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ac448493          	addi	s1,s1,-1340 # 80010c60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b5290913          	addi	s2,s2,-1198 # 80010cf8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	32a080e7          	jalr	810(ra) # 800024f6 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f20080e7          	jalr	-224(ra) # 800020fa <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	440080e7          	jalr	1088(ra) # 80002656 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	a3650513          	addi	a0,a0,-1482 # 80010c60 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a2050513          	addi	a0,a0,-1504 # 80010c60 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	a8f72023          	sw	a5,-1408(a4) # 80010cf8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	98e50513          	addi	a0,a0,-1650 # 80010c60 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	40a080e7          	jalr	1034(ra) # 80002702 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	96050513          	addi	a0,a0,-1696 # 80010c60 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	93c70713          	addi	a4,a4,-1732 # 80010c60 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	91278793          	addi	a5,a5,-1774 # 80010c60 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	97c7a783          	lw	a5,-1668(a5) # 80010cf8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	8d070713          	addi	a4,a4,-1840 # 80010c60 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	8c048493          	addi	s1,s1,-1856 # 80010c60 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	88470713          	addi	a4,a4,-1916 # 80010c60 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	90f72723          	sw	a5,-1778(a4) # 80010d00 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	84878793          	addi	a5,a5,-1976 # 80010c60 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	8cc7a023          	sw	a2,-1856(a5) # 80010cfc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	8b450513          	addi	a0,a0,-1868 # 80010cf8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	e5a080e7          	jalr	-422(ra) # 800022a6 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	7fa50513          	addi	a0,a0,2042 # 80010c60 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00022797          	auipc	a5,0x22
    80000482:	f9278793          	addi	a5,a5,-110 # 80022410 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	7c07a823          	sw	zero,2000(a5) # 80010d20 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	54f72e23          	sw	a5,1372(a4) # 80008ae0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	760dad83          	lw	s11,1888(s11) # 80010d20 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	70a50513          	addi	a0,a0,1802 # 80010d08 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	5a650513          	addi	a0,a0,1446 # 80010d08 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	58a48493          	addi	s1,s1,1418 # 80010d08 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	54a50513          	addi	a0,a0,1354 # 80010d28 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	2d67a783          	lw	a5,726(a5) # 80008ae0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	2a273703          	ld	a4,674(a4) # 80008ae8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2a27b783          	ld	a5,674(a5) # 80008af0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	4b8a0a13          	addi	s4,s4,1208 # 80010d28 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	27048493          	addi	s1,s1,624 # 80008ae8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	27098993          	addi	s3,s3,624 # 80008af0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	a00080e7          	jalr	-1536(ra) # 800022a6 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	44650513          	addi	a0,a0,1094 # 80010d28 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1ee7a783          	lw	a5,494(a5) # 80008ae0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1f47b783          	ld	a5,500(a5) # 80008af0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	1e473703          	ld	a4,484(a4) # 80008ae8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	418a0a13          	addi	s4,s4,1048 # 80010d28 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1d048493          	addi	s1,s1,464 # 80008ae8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1d090913          	addi	s2,s2,464 # 80008af0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7ca080e7          	jalr	1994(ra) # 800020fa <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	3e248493          	addi	s1,s1,994 # 80010d28 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	18f73b23          	sd	a5,406(a4) # 80008af0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	35848493          	addi	s1,s1,856 # 80010d28 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00023797          	auipc	a5,0x23
    80000a16:	b9678793          	addi	a5,a5,-1130 # 800235a8 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	32e90913          	addi	s2,s2,814 # 80010d60 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	29250513          	addi	a0,a0,658 # 80010d60 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00023517          	auipc	a0,0x23
    80000ae6:	ac650513          	addi	a0,a0,-1338 # 800235a8 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	25c48493          	addi	s1,s1,604 # 80010d60 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	24450513          	addi	a0,a0,580 # 80010d60 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	21850513          	addi	a0,a0,536 # 80010d60 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	c5470713          	addi	a4,a4,-940 # 80008af8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	968080e7          	jalr	-1688(ra) # 80002842 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	08e080e7          	jalr	142(ra) # 80005f70 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	05e080e7          	jalr	94(ra) # 80001f48 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	8c8080e7          	jalr	-1848(ra) # 8000281a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	8e8080e7          	jalr	-1816(ra) # 80002842 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	ff8080e7          	jalr	-8(ra) # 80005f5a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	006080e7          	jalr	6(ra) # 80005f70 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	1ba080e7          	jalr	442(ra) # 8000312c <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	85e080e7          	jalr	-1954(ra) # 800037d8 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	7fc080e7          	jalr	2044(ra) # 8000477e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	0ee080e7          	jalr	238(ra) # 80006078 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d28080e7          	jalr	-728(ra) # 80001cba <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b4f72c23          	sw	a5,-1192(a4) # 80008af8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	b4c7b783          	ld	a5,-1204(a5) # 80008b00 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	88a7b823          	sd	a0,-1904(a5) # 80008b00 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	36248493          	addi	s1,s1,866 # 80011bc8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001880:	00017a17          	auipc	s4,0x17
    80001884:	948a0a13          	addi	s4,s4,-1720 # 800181c8 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if (pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018ba:	19848493          	addi	s1,s1,408
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	47e50513          	addi	a0,a0,1150 # 80010d80 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	47e50513          	addi	a0,a0,1150 # 80010d98 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	29e48493          	addi	s1,s1,670 # 80011bc8 <proc>
  {
    initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    8000194c:	00017997          	auipc	s3,0x17
    80001950:	87c98993          	addi	s3,s3,-1924 # 800181c8 <tickslock>
    initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
    p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e4bc                	sd	a5,72(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    8000197e:	19848493          	addi	s1,s1,408
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	3fa50513          	addi	a0,a0,1018 # 80010db0 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	3a270713          	addi	a4,a4,930 # 80010d80 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first)
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	06a7a783          	lw	a5,106(a5) # 80008a80 <first.1729>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	e3a080e7          	jalr	-454(ra) # 8000285a <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0407a823          	sw	zero,80(a5) # 80008a80 <first.1729>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	d1e080e7          	jalr	-738(ra) # 80003758 <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	33090913          	addi	s2,s2,816 # 80010d80 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	02278793          	addi	a5,a5,34 # 80008a84 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	06093683          	ld	a3,96(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b84:	7128                	ld	a0,96(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80001b94:	6ca8                	ld	a0,88(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	68ac                	ld	a1,80(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001ba6:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001bb2:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bdc:	00010497          	auipc	s1,0x10
    80001be0:	fec48493          	addi	s1,s1,-20 # 80011bc8 <proc>
    80001be4:	00016917          	auipc	s2,0x16
    80001be8:	5e490913          	addi	s2,s2,1508 # 800181c8 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if (p->state == UNUSED)
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c04:	19848493          	addi	s1,s1,408
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a0bd                	j	80001c7c <allocproc+0xac>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  p->ctime = ticks;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	ef27a783          	lw	a5,-270(a5) # 80008b10 <ticks>
    80001c26:	d8dc                	sw	a5,52(s1)
      if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c28:	fffff097          	auipc	ra,0xfffff
    80001c2c:	ed2080e7          	jalr	-302(ra) # 80000afa <kalloc>
    80001c30:	892a                	mv	s2,a0
    80001c32:	f0a8                	sd	a0,96(s1)
    80001c34:	c939                	beqz	a0,80001c8a <allocproc+0xba>
  p->pagetable = proc_pagetable(p);
    80001c36:	8526                	mv	a0,s1
    80001c38:	00000097          	auipc	ra,0x0
    80001c3c:	e52080e7          	jalr	-430(ra) # 80001a8a <proc_pagetable>
    80001c40:	892a                	mv	s2,a0
    80001c42:	eca8                	sd	a0,88(s1)
  if (p->pagetable == 0)
    80001c44:	cd39                	beqz	a0,80001ca2 <allocproc+0xd2>
  memset(&p->context, 0, sizeof(p->context));
    80001c46:	07000613          	li	a2,112
    80001c4a:	4581                	li	a1,0
    80001c4c:	06848513          	addi	a0,s1,104
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	096080e7          	jalr	150(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c58:	00000797          	auipc	a5,0x0
    80001c5c:	da678793          	addi	a5,a5,-602 # 800019fe <forkret>
    80001c60:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c62:	64bc                	ld	a5,72(s1)
    80001c64:	6705                	lui	a4,0x1
    80001c66:	97ba                	add	a5,a5,a4
    80001c68:	f8bc                	sd	a5,112(s1)
  p->rtime = 0;
    80001c6a:	1604a823          	sw	zero,368(s1)
  p->etime = 0;
    80001c6e:	0204ac23          	sw	zero,56(s1)
  p->ctime = ticks;
    80001c72:	00007797          	auipc	a5,0x7
    80001c76:	e9e7a783          	lw	a5,-354(a5) # 80008b10 <ticks>
    80001c7a:	d8dc                	sw	a5,52(s1)
}
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	60e2                	ld	ra,24(sp)
    80001c80:	6442                	ld	s0,16(sp)
    80001c82:	64a2                	ld	s1,8(sp)
    80001c84:	6902                	ld	s2,0(sp)
    80001c86:	6105                	addi	sp,sp,32
    80001c88:	8082                	ret
    freeproc(p);
    80001c8a:	8526                	mv	a0,s1
    80001c8c:	00000097          	auipc	ra,0x0
    80001c90:	eec080e7          	jalr	-276(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c94:	8526                	mv	a0,s1
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	008080e7          	jalr	8(ra) # 80000c9e <release>
    return 0;
    80001c9e:	84ca                	mv	s1,s2
    80001ca0:	bff1                	j	80001c7c <allocproc+0xac>
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	ed4080e7          	jalr	-300(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	ff0080e7          	jalr	-16(ra) # 80000c9e <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	b7d1                	j	80001c7c <allocproc+0xac>

0000000080001cba <userinit>:
{
    80001cba:	1101                	addi	sp,sp,-32
    80001cbc:	ec06                	sd	ra,24(sp)
    80001cbe:	e822                	sd	s0,16(sp)
    80001cc0:	e426                	sd	s1,8(sp)
    80001cc2:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc4:	00000097          	auipc	ra,0x0
    80001cc8:	f0c080e7          	jalr	-244(ra) # 80001bd0 <allocproc>
    80001ccc:	84aa                	mv	s1,a0
  initproc = p;
    80001cce:	00007797          	auipc	a5,0x7
    80001cd2:	e2a7bd23          	sd	a0,-454(a5) # 80008b08 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cd6:	03400613          	li	a2,52
    80001cda:	00007597          	auipc	a1,0x7
    80001cde:	db658593          	addi	a1,a1,-586 # 80008a90 <initcode>
    80001ce2:	6d28                	ld	a0,88(a0)
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	68e080e7          	jalr	1678(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cec:	6785                	lui	a5,0x1
    80001cee:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cf0:	70b8                	ld	a4,96(s1)
    80001cf2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf6:	70b8                	ld	a4,96(s1)
    80001cf8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfa:	4641                	li	a2,16
    80001cfc:	00006597          	auipc	a1,0x6
    80001d00:	50458593          	addi	a1,a1,1284 # 80008200 <digits+0x1c0>
    80001d04:	16048513          	addi	a0,s1,352
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	130080e7          	jalr	304(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001d10:	00006517          	auipc	a0,0x6
    80001d14:	50050513          	addi	a0,a0,1280 # 80008210 <digits+0x1d0>
    80001d18:	00002097          	auipc	ra,0x2
    80001d1c:	462080e7          	jalr	1122(ra) # 8000417a <namei>
    80001d20:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001d24:	478d                	li	a5,3
    80001d26:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	f74080e7          	jalr	-140(ra) # 80000c9e <release>
}
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret

0000000080001d3c <growproc>:
{
    80001d3c:	1101                	addi	sp,sp,-32
    80001d3e:	ec06                	sd	ra,24(sp)
    80001d40:	e822                	sd	s0,16(sp)
    80001d42:	e426                	sd	s1,8(sp)
    80001d44:	e04a                	sd	s2,0(sp)
    80001d46:	1000                	addi	s0,sp,32
    80001d48:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	c7c080e7          	jalr	-900(ra) # 800019c6 <myproc>
    80001d52:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d54:	692c                	ld	a1,80(a0)
  if (n > 0)
    80001d56:	01204c63          	bgtz	s2,80001d6e <growproc+0x32>
  else if (n < 0)
    80001d5a:	02094663          	bltz	s2,80001d86 <growproc+0x4a>
  p->sz = sz;
    80001d5e:	e8ac                	sd	a1,80(s1)
  return 0;
    80001d60:	4501                	li	a0,0
}
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6902                	ld	s2,0(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d6e:	4691                	li	a3,4
    80001d70:	00b90633          	add	a2,s2,a1
    80001d74:	6d28                	ld	a0,88(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	6b6080e7          	jalr	1718(ra) # 8000142c <uvmalloc>
    80001d7e:	85aa                	mv	a1,a0
    80001d80:	fd79                	bnez	a0,80001d5e <growproc+0x22>
      return -1;
    80001d82:	557d                	li	a0,-1
    80001d84:	bff9                	j	80001d62 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d86:	00b90633          	add	a2,s2,a1
    80001d8a:	6d28                	ld	a0,88(a0)
    80001d8c:	fffff097          	auipc	ra,0xfffff
    80001d90:	658080e7          	jalr	1624(ra) # 800013e4 <uvmdealloc>
    80001d94:	85aa                	mv	a1,a0
    80001d96:	b7e1                	j	80001d5e <growproc+0x22>

0000000080001d98 <fork>:
{
    80001d98:	7179                	addi	sp,sp,-48
    80001d9a:	f406                	sd	ra,40(sp)
    80001d9c:	f022                	sd	s0,32(sp)
    80001d9e:	ec26                	sd	s1,24(sp)
    80001da0:	e84a                	sd	s2,16(sp)
    80001da2:	e44e                	sd	s3,8(sp)
    80001da4:	e052                	sd	s4,0(sp)
    80001da6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001da8:	00000097          	auipc	ra,0x0
    80001dac:	c1e080e7          	jalr	-994(ra) # 800019c6 <myproc>
    80001db0:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80001db2:	00000097          	auipc	ra,0x0
    80001db6:	e1e080e7          	jalr	-482(ra) # 80001bd0 <allocproc>
    80001dba:	10050f63          	beqz	a0,80001ed8 <fork+0x140>
    80001dbe:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dc0:	05093603          	ld	a2,80(s2)
    80001dc4:	6d2c                	ld	a1,88(a0)
    80001dc6:	05893503          	ld	a0,88(s2)
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	7b6080e7          	jalr	1974(ra) # 80001580 <uvmcopy>
    80001dd2:	04054a63          	bltz	a0,80001e26 <fork+0x8e>
  np->sz = p->sz;
    80001dd6:	05093783          	ld	a5,80(s2)
    80001dda:	04f9b823          	sd	a5,80(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dde:	06093683          	ld	a3,96(s2)
    80001de2:	87b6                	mv	a5,a3
    80001de4:	0609b703          	ld	a4,96(s3)
    80001de8:	12068693          	addi	a3,a3,288
    80001dec:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df0:	6788                	ld	a0,8(a5)
    80001df2:	6b8c                	ld	a1,16(a5)
    80001df4:	6f90                	ld	a2,24(a5)
    80001df6:	01073023          	sd	a6,0(a4)
    80001dfa:	e708                	sd	a0,8(a4)
    80001dfc:	eb0c                	sd	a1,16(a4)
    80001dfe:	ef10                	sd	a2,24(a4)
    80001e00:	02078793          	addi	a5,a5,32
    80001e04:	02070713          	addi	a4,a4,32
    80001e08:	fed792e3          	bne	a5,a3,80001dec <fork+0x54>
  np->trace_mask = p->trace_mask;
    80001e0c:	17492783          	lw	a5,372(s2)
    80001e10:	16f9aa23          	sw	a5,372(s3)
  np->trapframe->a0 = 0;
    80001e14:	0609b783          	ld	a5,96(s3)
    80001e18:	0607b823          	sd	zero,112(a5)
    80001e1c:	0d800493          	li	s1,216
  for (i = 0; i < NOFILE; i++)
    80001e20:	15800a13          	li	s4,344
    80001e24:	a03d                	j	80001e52 <fork+0xba>
    freeproc(np);
    80001e26:	854e                	mv	a0,s3
    80001e28:	00000097          	auipc	ra,0x0
    80001e2c:	d50080e7          	jalr	-688(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e30:	854e                	mv	a0,s3
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	e6c080e7          	jalr	-404(ra) # 80000c9e <release>
    return -1;
    80001e3a:	5a7d                	li	s4,-1
    80001e3c:	a069                	j	80001ec6 <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e3e:	00003097          	auipc	ra,0x3
    80001e42:	9d2080e7          	jalr	-1582(ra) # 80004810 <filedup>
    80001e46:	009987b3          	add	a5,s3,s1
    80001e4a:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80001e4c:	04a1                	addi	s1,s1,8
    80001e4e:	01448763          	beq	s1,s4,80001e5c <fork+0xc4>
    if (p->ofile[i])
    80001e52:	009907b3          	add	a5,s2,s1
    80001e56:	6388                	ld	a0,0(a5)
    80001e58:	f17d                	bnez	a0,80001e3e <fork+0xa6>
    80001e5a:	bfcd                	j	80001e4c <fork+0xb4>
  np->cwd = idup(p->cwd);
    80001e5c:	15893503          	ld	a0,344(s2)
    80001e60:	00002097          	auipc	ra,0x2
    80001e64:	b36080e7          	jalr	-1226(ra) # 80003996 <idup>
    80001e68:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6c:	4641                	li	a2,16
    80001e6e:	16090593          	addi	a1,s2,352
    80001e72:	16098513          	addi	a0,s3,352
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	fc2080e7          	jalr	-62(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e7e:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e82:	854e                	mv	a0,s3
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e1a080e7          	jalr	-486(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e8c:	0000f497          	auipc	s1,0xf
    80001e90:	f0c48493          	addi	s1,s1,-244 # 80010d98 <wait_lock>
    80001e94:	8526                	mv	a0,s1
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	d54080e7          	jalr	-684(ra) # 80000bea <acquire>
  np->parent = p;
    80001e9e:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80001ea2:	8526                	mv	a0,s1
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	dfa080e7          	jalr	-518(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001eac:	854e                	mv	a0,s3
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	d3c080e7          	jalr	-708(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001eb6:	478d                	li	a5,3
    80001eb8:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ebc:	854e                	mv	a0,s3
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	de0080e7          	jalr	-544(ra) # 80000c9e <release>
}
    80001ec6:	8552                	mv	a0,s4
    80001ec8:	70a2                	ld	ra,40(sp)
    80001eca:	7402                	ld	s0,32(sp)
    80001ecc:	64e2                	ld	s1,24(sp)
    80001ece:	6942                	ld	s2,16(sp)
    80001ed0:	69a2                	ld	s3,8(sp)
    80001ed2:	6a02                	ld	s4,0(sp)
    80001ed4:	6145                	addi	sp,sp,48
    80001ed6:	8082                	ret
    return -1;
    80001ed8:	5a7d                	li	s4,-1
    80001eda:	b7f5                	j	80001ec6 <fork+0x12e>

0000000080001edc <time_updates>:
{
    80001edc:	7179                	addi	sp,sp,-48
    80001ede:	f406                	sd	ra,40(sp)
    80001ee0:	f022                	sd	s0,32(sp)
    80001ee2:	ec26                	sd	s1,24(sp)
    80001ee4:	e84a                	sd	s2,16(sp)
    80001ee6:	e44e                	sd	s3,8(sp)
    80001ee8:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++) {
    80001eea:	00010497          	auipc	s1,0x10
    80001eee:	cde48493          	addi	s1,s1,-802 # 80011bc8 <proc>
    if (p->state == RUNNING) {
    80001ef2:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++) {
    80001ef4:	00016917          	auipc	s2,0x16
    80001ef8:	2d490913          	addi	s2,s2,724 # 800181c8 <tickslock>
    80001efc:	a811                	j	80001f10 <time_updates+0x34>
    release(&p->lock); 
    80001efe:	8526                	mv	a0,s1
    80001f00:	fffff097          	auipc	ra,0xfffff
    80001f04:	d9e080e7          	jalr	-610(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++) {
    80001f08:	19848493          	addi	s1,s1,408
    80001f0c:	03248063          	beq	s1,s2,80001f2c <time_updates+0x50>
    acquire(&p->lock);
    80001f10:	8526                	mv	a0,s1
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	cd8080e7          	jalr	-808(ra) # 80000bea <acquire>
    if (p->state == RUNNING) {
    80001f1a:	4c9c                	lw	a5,24(s1)
    80001f1c:	ff3791e3          	bne	a5,s3,80001efe <time_updates+0x22>
      p->rtime++;
    80001f20:	1704a783          	lw	a5,368(s1)
    80001f24:	2785                	addiw	a5,a5,1
    80001f26:	16f4a823          	sw	a5,368(s1)
    80001f2a:	bfd1                	j	80001efe <time_updates+0x22>
}
    80001f2c:	70a2                	ld	ra,40(sp)
    80001f2e:	7402                	ld	s0,32(sp)
    80001f30:	64e2                	ld	s1,24(sp)
    80001f32:	6942                	ld	s2,16(sp)
    80001f34:	69a2                	ld	s3,8(sp)
    80001f36:	6145                	addi	sp,sp,48
    80001f38:	8082                	ret

0000000080001f3a <set_priority>:
{
    80001f3a:	1141                	addi	sp,sp,-16
    80001f3c:	e422                	sd	s0,8(sp)
    80001f3e:	0800                	addi	s0,sp,16
}
    80001f40:	4501                	li	a0,0
    80001f42:	6422                	ld	s0,8(sp)
    80001f44:	0141                	addi	sp,sp,16
    80001f46:	8082                	ret

0000000080001f48 <scheduler>:
{
    80001f48:	7139                	addi	sp,sp,-64
    80001f4a:	fc06                	sd	ra,56(sp)
    80001f4c:	f822                	sd	s0,48(sp)
    80001f4e:	f426                	sd	s1,40(sp)
    80001f50:	f04a                	sd	s2,32(sp)
    80001f52:	ec4e                	sd	s3,24(sp)
    80001f54:	e852                	sd	s4,16(sp)
    80001f56:	e456                	sd	s5,8(sp)
    80001f58:	e05a                	sd	s6,0(sp)
    80001f5a:	0080                	addi	s0,sp,64
    80001f5c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f60:	00779a93          	slli	s5,a5,0x7
    80001f64:	0000f717          	auipc	a4,0xf
    80001f68:	e1c70713          	addi	a4,a4,-484 # 80010d80 <pid_lock>
    80001f6c:	9756                	add	a4,a4,s5
    80001f6e:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f72:	0000f717          	auipc	a4,0xf
    80001f76:	e4670713          	addi	a4,a4,-442 # 80010db8 <cpus+0x8>
    80001f7a:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f7c:	498d                	li	s3,3
        p->state = RUNNING;
    80001f7e:	4b11                	li	s6,4
        c->proc = p;
    80001f80:	079e                	slli	a5,a5,0x7
    80001f82:	0000fa17          	auipc	s4,0xf
    80001f86:	dfea0a13          	addi	s4,s4,-514 # 80010d80 <pid_lock>
    80001f8a:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f8c:	00016917          	auipc	s2,0x16
    80001f90:	23c90913          	addi	s2,s2,572 # 800181c8 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f9c:	10079073          	csrw	sstatus,a5
    80001fa0:	00010497          	auipc	s1,0x10
    80001fa4:	c2848493          	addi	s1,s1,-984 # 80011bc8 <proc>
    80001fa8:	a03d                	j	80001fd6 <scheduler+0x8e>
        p->state = RUNNING;
    80001faa:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001fae:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001fb2:	06848593          	addi	a1,s1,104
    80001fb6:	8556                	mv	a0,s5
    80001fb8:	00000097          	auipc	ra,0x0
    80001fbc:	7f8080e7          	jalr	2040(ra) # 800027b0 <swtch>
        c->proc = 0;
    80001fc0:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001fc4:	8526                	mv	a0,s1
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	cd8080e7          	jalr	-808(ra) # 80000c9e <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fce:	19848493          	addi	s1,s1,408
    80001fd2:	fd2481e3          	beq	s1,s2,80001f94 <scheduler+0x4c>
      acquire(&p->lock);
    80001fd6:	8526                	mv	a0,s1
    80001fd8:	fffff097          	auipc	ra,0xfffff
    80001fdc:	c12080e7          	jalr	-1006(ra) # 80000bea <acquire>
      if (p->state == RUNNABLE)
    80001fe0:	4c9c                	lw	a5,24(s1)
    80001fe2:	ff3791e3          	bne	a5,s3,80001fc4 <scheduler+0x7c>
    80001fe6:	b7d1                	j	80001faa <scheduler+0x62>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	9d0080e7          	jalr	-1584(ra) # 800019c6 <myproc>
    80001ffe:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	b70080e7          	jalr	-1168(ra) # 80000b70 <holding>
    80002008:	c93d                	beqz	a0,8000207e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000200a:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    8000200c:	2781                	sext.w	a5,a5
    8000200e:	079e                	slli	a5,a5,0x7
    80002010:	0000f717          	auipc	a4,0xf
    80002014:	d7070713          	addi	a4,a4,-656 # 80010d80 <pid_lock>
    80002018:	97ba                	add	a5,a5,a4
    8000201a:	0a87a703          	lw	a4,168(a5)
    8000201e:	4785                	li	a5,1
    80002020:	06f71763          	bne	a4,a5,8000208e <sched+0xa6>
  if (p->state == RUNNING)
    80002024:	4c98                	lw	a4,24(s1)
    80002026:	4791                	li	a5,4
    80002028:	06f70b63          	beq	a4,a5,8000209e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000202c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002030:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002032:	efb5                	bnez	a5,800020ae <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002034:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002036:	0000f917          	auipc	s2,0xf
    8000203a:	d4a90913          	addi	s2,s2,-694 # 80010d80 <pid_lock>
    8000203e:	2781                	sext.w	a5,a5
    80002040:	079e                	slli	a5,a5,0x7
    80002042:	97ca                	add	a5,a5,s2
    80002044:	0ac7a983          	lw	s3,172(a5)
    80002048:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000204a:	2781                	sext.w	a5,a5
    8000204c:	079e                	slli	a5,a5,0x7
    8000204e:	0000f597          	auipc	a1,0xf
    80002052:	d6a58593          	addi	a1,a1,-662 # 80010db8 <cpus+0x8>
    80002056:	95be                	add	a1,a1,a5
    80002058:	06848513          	addi	a0,s1,104
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	754080e7          	jalr	1876(ra) # 800027b0 <swtch>
    80002064:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002066:	2781                	sext.w	a5,a5
    80002068:	079e                	slli	a5,a5,0x7
    8000206a:	97ca                	add	a5,a5,s2
    8000206c:	0b37a623          	sw	s3,172(a5)
}
    80002070:	70a2                	ld	ra,40(sp)
    80002072:	7402                	ld	s0,32(sp)
    80002074:	64e2                	ld	s1,24(sp)
    80002076:	6942                	ld	s2,16(sp)
    80002078:	69a2                	ld	s3,8(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret
    panic("sched p->lock");
    8000207e:	00006517          	auipc	a0,0x6
    80002082:	19a50513          	addi	a0,a0,410 # 80008218 <digits+0x1d8>
    80002086:	ffffe097          	auipc	ra,0xffffe
    8000208a:	4be080e7          	jalr	1214(ra) # 80000544 <panic>
    panic("sched locks");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	19a50513          	addi	a0,a0,410 # 80008228 <digits+0x1e8>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4ae080e7          	jalr	1198(ra) # 80000544 <panic>
    panic("sched running");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	19a50513          	addi	a0,a0,410 # 80008238 <digits+0x1f8>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49e080e7          	jalr	1182(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	19a50513          	addi	a0,a0,410 # 80008248 <digits+0x208>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48e080e7          	jalr	1166(ra) # 80000544 <panic>

00000000800020be <yield>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020c8:	00000097          	auipc	ra,0x0
    800020cc:	8fe080e7          	jalr	-1794(ra) # 800019c6 <myproc>
    800020d0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b18080e7          	jalr	-1256(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020da:	478d                	li	a5,3
    800020dc:	cc9c                	sw	a5,24(s1)
  sched();
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	f0a080e7          	jalr	-246(ra) # 80001fe8 <sched>
  release(&p->lock);
    800020e6:	8526                	mv	a0,s1
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	bb6080e7          	jalr	-1098(ra) # 80000c9e <release>
}
    800020f0:	60e2                	ld	ra,24(sp)
    800020f2:	6442                	ld	s0,16(sp)
    800020f4:	64a2                	ld	s1,8(sp)
    800020f6:	6105                	addi	sp,sp,32
    800020f8:	8082                	ret

00000000800020fa <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020fa:	7179                	addi	sp,sp,-48
    800020fc:	f406                	sd	ra,40(sp)
    800020fe:	f022                	sd	s0,32(sp)
    80002100:	ec26                	sd	s1,24(sp)
    80002102:	e84a                	sd	s2,16(sp)
    80002104:	e44e                	sd	s3,8(sp)
    80002106:	1800                	addi	s0,sp,48
    80002108:	89aa                	mv	s3,a0
    8000210a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000210c:	00000097          	auipc	ra,0x0
    80002110:	8ba080e7          	jalr	-1862(ra) # 800019c6 <myproc>
    80002114:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	ad4080e7          	jalr	-1324(ra) # 80000bea <acquire>
  release(lk);
    8000211e:	854a                	mv	a0,s2
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b7e080e7          	jalr	-1154(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002128:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212c:	4789                	li	a5,2
    8000212e:	cc9c                	sw	a5,24(s1)

  sched();
    80002130:	00000097          	auipc	ra,0x0
    80002134:	eb8080e7          	jalr	-328(ra) # 80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002138:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b60080e7          	jalr	-1184(ra) # 80000c9e <release>
  acquire(lk);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	aa2080e7          	jalr	-1374(ra) # 80000bea <acquire>
}
    80002150:	70a2                	ld	ra,40(sp)
    80002152:	7402                	ld	s0,32(sp)
    80002154:	64e2                	ld	s1,24(sp)
    80002156:	6942                	ld	s2,16(sp)
    80002158:	69a2                	ld	s3,8(sp)
    8000215a:	6145                	addi	sp,sp,48
    8000215c:	8082                	ret

000000008000215e <waitx>:
{
    8000215e:	711d                	addi	sp,sp,-96
    80002160:	ec86                	sd	ra,88(sp)
    80002162:	e8a2                	sd	s0,80(sp)
    80002164:	e4a6                	sd	s1,72(sp)
    80002166:	e0ca                	sd	s2,64(sp)
    80002168:	fc4e                	sd	s3,56(sp)
    8000216a:	f852                	sd	s4,48(sp)
    8000216c:	f456                	sd	s5,40(sp)
    8000216e:	f05a                	sd	s6,32(sp)
    80002170:	ec5e                	sd	s7,24(sp)
    80002172:	e862                	sd	s8,16(sp)
    80002174:	e466                	sd	s9,8(sp)
    80002176:	e06a                	sd	s10,0(sp)
    80002178:	1080                	addi	s0,sp,96
    8000217a:	8b2a                	mv	s6,a0
    8000217c:	8bae                	mv	s7,a1
    8000217e:	8c32                	mv	s8,a2
  struct proc *p = myproc();
    80002180:	00000097          	auipc	ra,0x0
    80002184:	846080e7          	jalr	-1978(ra) # 800019c6 <myproc>
    80002188:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000218a:	0000f517          	auipc	a0,0xf
    8000218e:	c0e50513          	addi	a0,a0,-1010 # 80010d98 <wait_lock>
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	a58080e7          	jalr	-1448(ra) # 80000bea <acquire>
    havekids = 0;
    8000219a:	4c81                	li	s9,0
        if(np->state == ZOMBIE){
    8000219c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000219e:	00016997          	auipc	s3,0x16
    800021a2:	02a98993          	addi	s3,s3,42 # 800181c8 <tickslock>
        havekids = 1;
    800021a6:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021a8:	0000fd17          	auipc	s10,0xf
    800021ac:	bf0d0d13          	addi	s10,s10,-1040 # 80010d98 <wait_lock>
    havekids = 0;
    800021b0:	8766                	mv	a4,s9
    for(np = proc; np < &proc[NPROC]; np++){
    800021b2:	00010497          	auipc	s1,0x10
    800021b6:	a1648493          	addi	s1,s1,-1514 # 80011bc8 <proc>
    800021ba:	a049                	j	8000223c <waitx+0xde>
          pid = np->pid;
    800021bc:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    800021c0:	1704a703          	lw	a4,368(s1)
    800021c4:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    800021c8:	58dc                	lw	a5,52(s1)
    800021ca:	9f3d                	addw	a4,a4,a5
    800021cc:	5c9c                	lw	a5,56(s1)
    800021ce:	9f99                	subw	a5,a5,a4
    800021d0:	00fba023          	sw	a5,0(s7) # fffffffffffff000 <end+0xffffffff7ffdba58>
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800021d4:	000b0e63          	beqz	s6,800021f0 <waitx+0x92>
    800021d8:	4691                	li	a3,4
    800021da:	02c48613          	addi	a2,s1,44
    800021de:	85da                	mv	a1,s6
    800021e0:	05893503          	ld	a0,88(s2)
    800021e4:	fffff097          	auipc	ra,0xfffff
    800021e8:	4a0080e7          	jalr	1184(ra) # 80001684 <copyout>
    800021ec:	02054563          	bltz	a0,80002216 <waitx+0xb8>
          freeproc(np);
    800021f0:	8526                	mv	a0,s1
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	986080e7          	jalr	-1658(ra) # 80001b78 <freeproc>
          release(&np->lock);
    800021fa:	8526                	mv	a0,s1
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	aa2080e7          	jalr	-1374(ra) # 80000c9e <release>
          release(&wait_lock);
    80002204:	0000f517          	auipc	a0,0xf
    80002208:	b9450513          	addi	a0,a0,-1132 # 80010d98 <wait_lock>
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	a92080e7          	jalr	-1390(ra) # 80000c9e <release>
          return pid;
    80002214:	a09d                	j	8000227a <waitx+0x11c>
            release(&np->lock);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a86080e7          	jalr	-1402(ra) # 80000c9e <release>
            release(&wait_lock);
    80002220:	0000f517          	auipc	a0,0xf
    80002224:	b7850513          	addi	a0,a0,-1160 # 80010d98 <wait_lock>
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	a76080e7          	jalr	-1418(ra) # 80000c9e <release>
            return -1;
    80002230:	59fd                	li	s3,-1
    80002232:	a0a1                	j	8000227a <waitx+0x11c>
    for(np = proc; np < &proc[NPROC]; np++){
    80002234:	19848493          	addi	s1,s1,408
    80002238:	03348463          	beq	s1,s3,80002260 <waitx+0x102>
      if(np->parent == p){
    8000223c:	60bc                	ld	a5,64(s1)
    8000223e:	ff279be3          	bne	a5,s2,80002234 <waitx+0xd6>
        acquire(&np->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	9a6080e7          	jalr	-1626(ra) # 80000bea <acquire>
        if(np->state == ZOMBIE){
    8000224c:	4c9c                	lw	a5,24(s1)
    8000224e:	f74787e3          	beq	a5,s4,800021bc <waitx+0x5e>
        release(&np->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
        havekids = 1;
    8000225c:	8756                	mv	a4,s5
    8000225e:	bfd9                	j	80002234 <waitx+0xd6>
    if(!havekids || p->killed){
    80002260:	c701                	beqz	a4,80002268 <waitx+0x10a>
    80002262:	02892783          	lw	a5,40(s2)
    80002266:	cb8d                	beqz	a5,80002298 <waitx+0x13a>
      release(&wait_lock);
    80002268:	0000f517          	auipc	a0,0xf
    8000226c:	b3050513          	addi	a0,a0,-1232 # 80010d98 <wait_lock>
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	a2e080e7          	jalr	-1490(ra) # 80000c9e <release>
      return -1;
    80002278:	59fd                	li	s3,-1
}
    8000227a:	854e                	mv	a0,s3
    8000227c:	60e6                	ld	ra,88(sp)
    8000227e:	6446                	ld	s0,80(sp)
    80002280:	64a6                	ld	s1,72(sp)
    80002282:	6906                	ld	s2,64(sp)
    80002284:	79e2                	ld	s3,56(sp)
    80002286:	7a42                	ld	s4,48(sp)
    80002288:	7aa2                	ld	s5,40(sp)
    8000228a:	7b02                	ld	s6,32(sp)
    8000228c:	6be2                	ld	s7,24(sp)
    8000228e:	6c42                	ld	s8,16(sp)
    80002290:	6ca2                	ld	s9,8(sp)
    80002292:	6d02                	ld	s10,0(sp)
    80002294:	6125                	addi	sp,sp,96
    80002296:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002298:	85ea                	mv	a1,s10
    8000229a:	854a                	mv	a0,s2
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	e5e080e7          	jalr	-418(ra) # 800020fa <sleep>
    havekids = 0;
    800022a4:	b731                	j	800021b0 <waitx+0x52>

00000000800022a6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800022a6:	7139                	addi	sp,sp,-64
    800022a8:	fc06                	sd	ra,56(sp)
    800022aa:	f822                	sd	s0,48(sp)
    800022ac:	f426                	sd	s1,40(sp)
    800022ae:	f04a                	sd	s2,32(sp)
    800022b0:	ec4e                	sd	s3,24(sp)
    800022b2:	e852                	sd	s4,16(sp)
    800022b4:	e456                	sd	s5,8(sp)
    800022b6:	0080                	addi	s0,sp,64
    800022b8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800022ba:	00010497          	auipc	s1,0x10
    800022be:	90e48493          	addi	s1,s1,-1778 # 80011bc8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800022c2:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800022c4:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800022c6:	00016917          	auipc	s2,0x16
    800022ca:	f0290913          	addi	s2,s2,-254 # 800181c8 <tickslock>
    800022ce:	a821                	j	800022e6 <wakeup+0x40>
        p->state = RUNNABLE;
    800022d0:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9c8080e7          	jalr	-1592(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800022de:	19848493          	addi	s1,s1,408
    800022e2:	03248463          	beq	s1,s2,8000230a <wakeup+0x64>
    if (p != myproc())
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	6e0080e7          	jalr	1760(ra) # 800019c6 <myproc>
    800022ee:	fea488e3          	beq	s1,a0,800022de <wakeup+0x38>
      acquire(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	8f6080e7          	jalr	-1802(ra) # 80000bea <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022fc:	4c9c                	lw	a5,24(s1)
    800022fe:	fd379be3          	bne	a5,s3,800022d4 <wakeup+0x2e>
    80002302:	709c                	ld	a5,32(s1)
    80002304:	fd4798e3          	bne	a5,s4,800022d4 <wakeup+0x2e>
    80002308:	b7e1                	j	800022d0 <wakeup+0x2a>
    }
  }
}
    8000230a:	70e2                	ld	ra,56(sp)
    8000230c:	7442                	ld	s0,48(sp)
    8000230e:	74a2                	ld	s1,40(sp)
    80002310:	7902                	ld	s2,32(sp)
    80002312:	69e2                	ld	s3,24(sp)
    80002314:	6a42                	ld	s4,16(sp)
    80002316:	6aa2                	ld	s5,8(sp)
    80002318:	6121                	addi	sp,sp,64
    8000231a:	8082                	ret

000000008000231c <reparent>:
{
    8000231c:	7179                	addi	sp,sp,-48
    8000231e:	f406                	sd	ra,40(sp)
    80002320:	f022                	sd	s0,32(sp)
    80002322:	ec26                	sd	s1,24(sp)
    80002324:	e84a                	sd	s2,16(sp)
    80002326:	e44e                	sd	s3,8(sp)
    80002328:	e052                	sd	s4,0(sp)
    8000232a:	1800                	addi	s0,sp,48
    8000232c:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000232e:	00010497          	auipc	s1,0x10
    80002332:	89a48493          	addi	s1,s1,-1894 # 80011bc8 <proc>
      pp->parent = initproc;
    80002336:	00006a17          	auipc	s4,0x6
    8000233a:	7d2a0a13          	addi	s4,s4,2002 # 80008b08 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000233e:	00016997          	auipc	s3,0x16
    80002342:	e8a98993          	addi	s3,s3,-374 # 800181c8 <tickslock>
    80002346:	a029                	j	80002350 <reparent+0x34>
    80002348:	19848493          	addi	s1,s1,408
    8000234c:	01348d63          	beq	s1,s3,80002366 <reparent+0x4a>
    if (pp->parent == p)
    80002350:	60bc                	ld	a5,64(s1)
    80002352:	ff279be3          	bne	a5,s2,80002348 <reparent+0x2c>
      pp->parent = initproc;
    80002356:	000a3503          	ld	a0,0(s4)
    8000235a:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	f4a080e7          	jalr	-182(ra) # 800022a6 <wakeup>
    80002364:	b7d5                	j	80002348 <reparent+0x2c>
}
    80002366:	70a2                	ld	ra,40(sp)
    80002368:	7402                	ld	s0,32(sp)
    8000236a:	64e2                	ld	s1,24(sp)
    8000236c:	6942                	ld	s2,16(sp)
    8000236e:	69a2                	ld	s3,8(sp)
    80002370:	6a02                	ld	s4,0(sp)
    80002372:	6145                	addi	sp,sp,48
    80002374:	8082                	ret

0000000080002376 <exit>:
{
    80002376:	7179                	addi	sp,sp,-48
    80002378:	f406                	sd	ra,40(sp)
    8000237a:	f022                	sd	s0,32(sp)
    8000237c:	ec26                	sd	s1,24(sp)
    8000237e:	e84a                	sd	s2,16(sp)
    80002380:	e44e                	sd	s3,8(sp)
    80002382:	e052                	sd	s4,0(sp)
    80002384:	1800                	addi	s0,sp,48
    80002386:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	63e080e7          	jalr	1598(ra) # 800019c6 <myproc>
    80002390:	89aa                	mv	s3,a0
  if (p == initproc)
    80002392:	00006797          	auipc	a5,0x6
    80002396:	7767b783          	ld	a5,1910(a5) # 80008b08 <initproc>
    8000239a:	0d850493          	addi	s1,a0,216
    8000239e:	15850913          	addi	s2,a0,344
    800023a2:	02a79363          	bne	a5,a0,800023c8 <exit+0x52>
    panic("init exiting");
    800023a6:	00006517          	auipc	a0,0x6
    800023aa:	eba50513          	addi	a0,a0,-326 # 80008260 <digits+0x220>
    800023ae:	ffffe097          	auipc	ra,0xffffe
    800023b2:	196080e7          	jalr	406(ra) # 80000544 <panic>
      fileclose(f);
    800023b6:	00002097          	auipc	ra,0x2
    800023ba:	4ac080e7          	jalr	1196(ra) # 80004862 <fileclose>
      p->ofile[fd] = 0;
    800023be:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800023c2:	04a1                	addi	s1,s1,8
    800023c4:	01248563          	beq	s1,s2,800023ce <exit+0x58>
    if (p->ofile[fd])
    800023c8:	6088                	ld	a0,0(s1)
    800023ca:	f575                	bnez	a0,800023b6 <exit+0x40>
    800023cc:	bfdd                	j	800023c2 <exit+0x4c>
  begin_op();
    800023ce:	00002097          	auipc	ra,0x2
    800023d2:	fc8080e7          	jalr	-56(ra) # 80004396 <begin_op>
  iput(p->cwd);
    800023d6:	1589b503          	ld	a0,344(s3)
    800023da:	00001097          	auipc	ra,0x1
    800023de:	7b4080e7          	jalr	1972(ra) # 80003b8e <iput>
  end_op();
    800023e2:	00002097          	auipc	ra,0x2
    800023e6:	034080e7          	jalr	52(ra) # 80004416 <end_op>
  p->cwd = 0;
    800023ea:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    800023ee:	0000f497          	auipc	s1,0xf
    800023f2:	9aa48493          	addi	s1,s1,-1622 # 80010d98 <wait_lock>
    800023f6:	8526                	mv	a0,s1
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	7f2080e7          	jalr	2034(ra) # 80000bea <acquire>
  reparent(p);
    80002400:	854e                	mv	a0,s3
    80002402:	00000097          	auipc	ra,0x0
    80002406:	f1a080e7          	jalr	-230(ra) # 8000231c <reparent>
  wakeup(p->parent);
    8000240a:	0409b503          	ld	a0,64(s3)
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	e98080e7          	jalr	-360(ra) # 800022a6 <wakeup>
  acquire(&p->lock);
    80002416:	854e                	mv	a0,s3
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	7d2080e7          	jalr	2002(ra) # 80000bea <acquire>
  p->xstate = status;
    80002420:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002424:	4795                	li	a5,5
    80002426:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000242a:	00006797          	auipc	a5,0x6
    8000242e:	6e67a783          	lw	a5,1766(a5) # 80008b10 <ticks>
    80002432:	02f9ac23          	sw	a5,56(s3)
  release(&wait_lock);
    80002436:	8526                	mv	a0,s1
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	866080e7          	jalr	-1946(ra) # 80000c9e <release>
  sched();
    80002440:	00000097          	auipc	ra,0x0
    80002444:	ba8080e7          	jalr	-1112(ra) # 80001fe8 <sched>
  panic("zombie exit");
    80002448:	00006517          	auipc	a0,0x6
    8000244c:	e2850513          	addi	a0,a0,-472 # 80008270 <digits+0x230>
    80002450:	ffffe097          	auipc	ra,0xffffe
    80002454:	0f4080e7          	jalr	244(ra) # 80000544 <panic>

0000000080002458 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002458:	7179                	addi	sp,sp,-48
    8000245a:	f406                	sd	ra,40(sp)
    8000245c:	f022                	sd	s0,32(sp)
    8000245e:	ec26                	sd	s1,24(sp)
    80002460:	e84a                	sd	s2,16(sp)
    80002462:	e44e                	sd	s3,8(sp)
    80002464:	1800                	addi	s0,sp,48
    80002466:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002468:	0000f497          	auipc	s1,0xf
    8000246c:	76048493          	addi	s1,s1,1888 # 80011bc8 <proc>
    80002470:	00016997          	auipc	s3,0x16
    80002474:	d5898993          	addi	s3,s3,-680 # 800181c8 <tickslock>
  {
    acquire(&p->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	770080e7          	jalr	1904(ra) # 80000bea <acquire>
    if (p->pid == pid)
    80002482:	589c                	lw	a5,48(s1)
    80002484:	01278d63          	beq	a5,s2,8000249e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	814080e7          	jalr	-2028(ra) # 80000c9e <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002492:	19848493          	addi	s1,s1,408
    80002496:	ff3491e3          	bne	s1,s3,80002478 <kill+0x20>
  }
  return -1;
    8000249a:	557d                	li	a0,-1
    8000249c:	a829                	j	800024b6 <kill+0x5e>
      p->killed = 1;
    8000249e:	4785                	li	a5,1
    800024a0:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800024a2:	4c98                	lw	a4,24(s1)
    800024a4:	4789                	li	a5,2
    800024a6:	00f70f63          	beq	a4,a5,800024c4 <kill+0x6c>
      release(&p->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	7f2080e7          	jalr	2034(ra) # 80000c9e <release>
      return 0;
    800024b4:	4501                	li	a0,0
}
    800024b6:	70a2                	ld	ra,40(sp)
    800024b8:	7402                	ld	s0,32(sp)
    800024ba:	64e2                	ld	s1,24(sp)
    800024bc:	6942                	ld	s2,16(sp)
    800024be:	69a2                	ld	s3,8(sp)
    800024c0:	6145                	addi	sp,sp,48
    800024c2:	8082                	ret
        p->state = RUNNABLE;
    800024c4:	478d                	li	a5,3
    800024c6:	cc9c                	sw	a5,24(s1)
    800024c8:	b7cd                	j	800024aa <kill+0x52>

00000000800024ca <setkilled>:

void setkilled(struct proc *p)
{
    800024ca:	1101                	addi	sp,sp,-32
    800024cc:	ec06                	sd	ra,24(sp)
    800024ce:	e822                	sd	s0,16(sp)
    800024d0:	e426                	sd	s1,8(sp)
    800024d2:	1000                	addi	s0,sp,32
    800024d4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	714080e7          	jalr	1812(ra) # 80000bea <acquire>
  p->killed = 1;
    800024de:	4785                	li	a5,1
    800024e0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024e2:	8526                	mv	a0,s1
    800024e4:	ffffe097          	auipc	ra,0xffffe
    800024e8:	7ba080e7          	jalr	1978(ra) # 80000c9e <release>
}
    800024ec:	60e2                	ld	ra,24(sp)
    800024ee:	6442                	ld	s0,16(sp)
    800024f0:	64a2                	ld	s1,8(sp)
    800024f2:	6105                	addi	sp,sp,32
    800024f4:	8082                	ret

00000000800024f6 <killed>:

int killed(struct proc *p)
{
    800024f6:	1101                	addi	sp,sp,-32
    800024f8:	ec06                	sd	ra,24(sp)
    800024fa:	e822                	sd	s0,16(sp)
    800024fc:	e426                	sd	s1,8(sp)
    800024fe:	e04a                	sd	s2,0(sp)
    80002500:	1000                	addi	s0,sp,32
    80002502:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	6e6080e7          	jalr	1766(ra) # 80000bea <acquire>
  k = p->killed;
    8000250c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	78c080e7          	jalr	1932(ra) # 80000c9e <release>
  return k;
}
    8000251a:	854a                	mv	a0,s2
    8000251c:	60e2                	ld	ra,24(sp)
    8000251e:	6442                	ld	s0,16(sp)
    80002520:	64a2                	ld	s1,8(sp)
    80002522:	6902                	ld	s2,0(sp)
    80002524:	6105                	addi	sp,sp,32
    80002526:	8082                	ret

0000000080002528 <wait>:
{
    80002528:	715d                	addi	sp,sp,-80
    8000252a:	e486                	sd	ra,72(sp)
    8000252c:	e0a2                	sd	s0,64(sp)
    8000252e:	fc26                	sd	s1,56(sp)
    80002530:	f84a                	sd	s2,48(sp)
    80002532:	f44e                	sd	s3,40(sp)
    80002534:	f052                	sd	s4,32(sp)
    80002536:	ec56                	sd	s5,24(sp)
    80002538:	e85a                	sd	s6,16(sp)
    8000253a:	e45e                	sd	s7,8(sp)
    8000253c:	e062                	sd	s8,0(sp)
    8000253e:	0880                	addi	s0,sp,80
    80002540:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002542:	fffff097          	auipc	ra,0xfffff
    80002546:	484080e7          	jalr	1156(ra) # 800019c6 <myproc>
    8000254a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000254c:	0000f517          	auipc	a0,0xf
    80002550:	84c50513          	addi	a0,a0,-1972 # 80010d98 <wait_lock>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	696080e7          	jalr	1686(ra) # 80000bea <acquire>
    havekids = 0;
    8000255c:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000255e:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002560:	00016997          	auipc	s3,0x16
    80002564:	c6898993          	addi	s3,s3,-920 # 800181c8 <tickslock>
        havekids = 1;
    80002568:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000256a:	0000fc17          	auipc	s8,0xf
    8000256e:	82ec0c13          	addi	s8,s8,-2002 # 80010d98 <wait_lock>
    havekids = 0;
    80002572:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002574:	0000f497          	auipc	s1,0xf
    80002578:	65448493          	addi	s1,s1,1620 # 80011bc8 <proc>
    8000257c:	a0bd                	j	800025ea <wait+0xc2>
          pid = pp->pid;
    8000257e:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002582:	000b0e63          	beqz	s6,8000259e <wait+0x76>
    80002586:	4691                	li	a3,4
    80002588:	02c48613          	addi	a2,s1,44
    8000258c:	85da                	mv	a1,s6
    8000258e:	05893503          	ld	a0,88(s2)
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	0f2080e7          	jalr	242(ra) # 80001684 <copyout>
    8000259a:	02054563          	bltz	a0,800025c4 <wait+0x9c>
          freeproc(pp);
    8000259e:	8526                	mv	a0,s1
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	5d8080e7          	jalr	1496(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800025a8:	8526                	mv	a0,s1
    800025aa:	ffffe097          	auipc	ra,0xffffe
    800025ae:	6f4080e7          	jalr	1780(ra) # 80000c9e <release>
          release(&wait_lock);
    800025b2:	0000e517          	auipc	a0,0xe
    800025b6:	7e650513          	addi	a0,a0,2022 # 80010d98 <wait_lock>
    800025ba:	ffffe097          	auipc	ra,0xffffe
    800025be:	6e4080e7          	jalr	1764(ra) # 80000c9e <release>
          return pid;
    800025c2:	a0b5                	j	8000262e <wait+0x106>
            release(&pp->lock);
    800025c4:	8526                	mv	a0,s1
    800025c6:	ffffe097          	auipc	ra,0xffffe
    800025ca:	6d8080e7          	jalr	1752(ra) # 80000c9e <release>
            release(&wait_lock);
    800025ce:	0000e517          	auipc	a0,0xe
    800025d2:	7ca50513          	addi	a0,a0,1994 # 80010d98 <wait_lock>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	6c8080e7          	jalr	1736(ra) # 80000c9e <release>
            return -1;
    800025de:	59fd                	li	s3,-1
    800025e0:	a0b9                	j	8000262e <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025e2:	19848493          	addi	s1,s1,408
    800025e6:	03348463          	beq	s1,s3,8000260e <wait+0xe6>
      if (pp->parent == p)
    800025ea:	60bc                	ld	a5,64(s1)
    800025ec:	ff279be3          	bne	a5,s2,800025e2 <wait+0xba>
        acquire(&pp->lock);
    800025f0:	8526                	mv	a0,s1
    800025f2:	ffffe097          	auipc	ra,0xffffe
    800025f6:	5f8080e7          	jalr	1528(ra) # 80000bea <acquire>
        if (pp->state == ZOMBIE)
    800025fa:	4c9c                	lw	a5,24(s1)
    800025fc:	f94781e3          	beq	a5,s4,8000257e <wait+0x56>
        release(&pp->lock);
    80002600:	8526                	mv	a0,s1
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	69c080e7          	jalr	1692(ra) # 80000c9e <release>
        havekids = 1;
    8000260a:	8756                	mv	a4,s5
    8000260c:	bfd9                	j	800025e2 <wait+0xba>
    if (!havekids || killed(p))
    8000260e:	c719                	beqz	a4,8000261c <wait+0xf4>
    80002610:	854a                	mv	a0,s2
    80002612:	00000097          	auipc	ra,0x0
    80002616:	ee4080e7          	jalr	-284(ra) # 800024f6 <killed>
    8000261a:	c51d                	beqz	a0,80002648 <wait+0x120>
      release(&wait_lock);
    8000261c:	0000e517          	auipc	a0,0xe
    80002620:	77c50513          	addi	a0,a0,1916 # 80010d98 <wait_lock>
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	67a080e7          	jalr	1658(ra) # 80000c9e <release>
      return -1;
    8000262c:	59fd                	li	s3,-1
}
    8000262e:	854e                	mv	a0,s3
    80002630:	60a6                	ld	ra,72(sp)
    80002632:	6406                	ld	s0,64(sp)
    80002634:	74e2                	ld	s1,56(sp)
    80002636:	7942                	ld	s2,48(sp)
    80002638:	79a2                	ld	s3,40(sp)
    8000263a:	7a02                	ld	s4,32(sp)
    8000263c:	6ae2                	ld	s5,24(sp)
    8000263e:	6b42                	ld	s6,16(sp)
    80002640:	6ba2                	ld	s7,8(sp)
    80002642:	6c02                	ld	s8,0(sp)
    80002644:	6161                	addi	sp,sp,80
    80002646:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002648:	85e2                	mv	a1,s8
    8000264a:	854a                	mv	a0,s2
    8000264c:	00000097          	auipc	ra,0x0
    80002650:	aae080e7          	jalr	-1362(ra) # 800020fa <sleep>
    havekids = 0;
    80002654:	bf39                	j	80002572 <wait+0x4a>

0000000080002656 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002656:	7179                	addi	sp,sp,-48
    80002658:	f406                	sd	ra,40(sp)
    8000265a:	f022                	sd	s0,32(sp)
    8000265c:	ec26                	sd	s1,24(sp)
    8000265e:	e84a                	sd	s2,16(sp)
    80002660:	e44e                	sd	s3,8(sp)
    80002662:	e052                	sd	s4,0(sp)
    80002664:	1800                	addi	s0,sp,48
    80002666:	84aa                	mv	s1,a0
    80002668:	892e                	mv	s2,a1
    8000266a:	89b2                	mv	s3,a2
    8000266c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266e:	fffff097          	auipc	ra,0xfffff
    80002672:	358080e7          	jalr	856(ra) # 800019c6 <myproc>
  if (user_dst)
    80002676:	c08d                	beqz	s1,80002698 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002678:	86d2                	mv	a3,s4
    8000267a:	864e                	mv	a2,s3
    8000267c:	85ca                	mv	a1,s2
    8000267e:	6d28                	ld	a0,88(a0)
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	004080e7          	jalr	4(ra) # 80001684 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002688:	70a2                	ld	ra,40(sp)
    8000268a:	7402                	ld	s0,32(sp)
    8000268c:	64e2                	ld	s1,24(sp)
    8000268e:	6942                	ld	s2,16(sp)
    80002690:	69a2                	ld	s3,8(sp)
    80002692:	6a02                	ld	s4,0(sp)
    80002694:	6145                	addi	sp,sp,48
    80002696:	8082                	ret
    memmove((char *)dst, src, len);
    80002698:	000a061b          	sext.w	a2,s4
    8000269c:	85ce                	mv	a1,s3
    8000269e:	854a                	mv	a0,s2
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	6a6080e7          	jalr	1702(ra) # 80000d46 <memmove>
    return 0;
    800026a8:	8526                	mv	a0,s1
    800026aa:	bff9                	j	80002688 <either_copyout+0x32>

00000000800026ac <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026ac:	7179                	addi	sp,sp,-48
    800026ae:	f406                	sd	ra,40(sp)
    800026b0:	f022                	sd	s0,32(sp)
    800026b2:	ec26                	sd	s1,24(sp)
    800026b4:	e84a                	sd	s2,16(sp)
    800026b6:	e44e                	sd	s3,8(sp)
    800026b8:	e052                	sd	s4,0(sp)
    800026ba:	1800                	addi	s0,sp,48
    800026bc:	892a                	mv	s2,a0
    800026be:	84ae                	mv	s1,a1
    800026c0:	89b2                	mv	s3,a2
    800026c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026c4:	fffff097          	auipc	ra,0xfffff
    800026c8:	302080e7          	jalr	770(ra) # 800019c6 <myproc>
  if (user_src)
    800026cc:	c08d                	beqz	s1,800026ee <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    800026ce:	86d2                	mv	a3,s4
    800026d0:	864e                	mv	a2,s3
    800026d2:	85ca                	mv	a1,s2
    800026d4:	6d28                	ld	a0,88(a0)
    800026d6:	fffff097          	auipc	ra,0xfffff
    800026da:	03a080e7          	jalr	58(ra) # 80001710 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    800026de:	70a2                	ld	ra,40(sp)
    800026e0:	7402                	ld	s0,32(sp)
    800026e2:	64e2                	ld	s1,24(sp)
    800026e4:	6942                	ld	s2,16(sp)
    800026e6:	69a2                	ld	s3,8(sp)
    800026e8:	6a02                	ld	s4,0(sp)
    800026ea:	6145                	addi	sp,sp,48
    800026ec:	8082                	ret
    memmove(dst, (char *)src, len);
    800026ee:	000a061b          	sext.w	a2,s4
    800026f2:	85ce                	mv	a1,s3
    800026f4:	854a                	mv	a0,s2
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	650080e7          	jalr	1616(ra) # 80000d46 <memmove>
    return 0;
    800026fe:	8526                	mv	a0,s1
    80002700:	bff9                	j	800026de <either_copyin+0x32>

0000000080002702 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002702:	715d                	addi	sp,sp,-80
    80002704:	e486                	sd	ra,72(sp)
    80002706:	e0a2                	sd	s0,64(sp)
    80002708:	fc26                	sd	s1,56(sp)
    8000270a:	f84a                	sd	s2,48(sp)
    8000270c:	f44e                	sd	s3,40(sp)
    8000270e:	f052                	sd	s4,32(sp)
    80002710:	ec56                	sd	s5,24(sp)
    80002712:	e85a                	sd	s6,16(sp)
    80002714:	e45e                	sd	s7,8(sp)
    80002716:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002718:	00006517          	auipc	a0,0x6
    8000271c:	9b050513          	addi	a0,a0,-1616 # 800080c8 <digits+0x88>
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	e6e080e7          	jalr	-402(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002728:	0000f497          	auipc	s1,0xf
    8000272c:	60048493          	addi	s1,s1,1536 # 80011d28 <proc+0x160>
    80002730:	00016917          	auipc	s2,0x16
    80002734:	bf890913          	addi	s2,s2,-1032 # 80018328 <bcache+0x148>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002738:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000273a:	00006997          	auipc	s3,0x6
    8000273e:	b4698993          	addi	s3,s3,-1210 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002742:	00006a97          	auipc	s5,0x6
    80002746:	b46a8a93          	addi	s5,s5,-1210 # 80008288 <digits+0x248>
    printf("\n");
    8000274a:	00006a17          	auipc	s4,0x6
    8000274e:	97ea0a13          	addi	s4,s4,-1666 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002752:	00006b97          	auipc	s7,0x6
    80002756:	b76b8b93          	addi	s7,s7,-1162 # 800082c8 <states.1773>
    8000275a:	a00d                	j	8000277c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000275c:	ed06a583          	lw	a1,-304(a3)
    80002760:	8556                	mv	a0,s5
    80002762:	ffffe097          	auipc	ra,0xffffe
    80002766:	e2c080e7          	jalr	-468(ra) # 8000058e <printf>
    printf("\n");
    8000276a:	8552                	mv	a0,s4
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e22080e7          	jalr	-478(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002774:	19848493          	addi	s1,s1,408
    80002778:	03248163          	beq	s1,s2,8000279a <procdump+0x98>
    if (p->state == UNUSED)
    8000277c:	86a6                	mv	a3,s1
    8000277e:	eb84a783          	lw	a5,-328(s1)
    80002782:	dbed                	beqz	a5,80002774 <procdump+0x72>
      state = "???";
    80002784:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002786:	fcfb6be3          	bltu	s6,a5,8000275c <procdump+0x5a>
    8000278a:	1782                	slli	a5,a5,0x20
    8000278c:	9381                	srli	a5,a5,0x20
    8000278e:	078e                	slli	a5,a5,0x3
    80002790:	97de                	add	a5,a5,s7
    80002792:	6390                	ld	a2,0(a5)
    80002794:	f661                	bnez	a2,8000275c <procdump+0x5a>
      state = "???";
    80002796:	864e                	mv	a2,s3
    80002798:	b7d1                	j	8000275c <procdump+0x5a>
  }
}
    8000279a:	60a6                	ld	ra,72(sp)
    8000279c:	6406                	ld	s0,64(sp)
    8000279e:	74e2                	ld	s1,56(sp)
    800027a0:	7942                	ld	s2,48(sp)
    800027a2:	79a2                	ld	s3,40(sp)
    800027a4:	7a02                	ld	s4,32(sp)
    800027a6:	6ae2                	ld	s5,24(sp)
    800027a8:	6b42                	ld	s6,16(sp)
    800027aa:	6ba2                	ld	s7,8(sp)
    800027ac:	6161                	addi	sp,sp,80
    800027ae:	8082                	ret

00000000800027b0 <swtch>:
    800027b0:	00153023          	sd	ra,0(a0)
    800027b4:	00253423          	sd	sp,8(a0)
    800027b8:	e900                	sd	s0,16(a0)
    800027ba:	ed04                	sd	s1,24(a0)
    800027bc:	03253023          	sd	s2,32(a0)
    800027c0:	03353423          	sd	s3,40(a0)
    800027c4:	03453823          	sd	s4,48(a0)
    800027c8:	03553c23          	sd	s5,56(a0)
    800027cc:	05653023          	sd	s6,64(a0)
    800027d0:	05753423          	sd	s7,72(a0)
    800027d4:	05853823          	sd	s8,80(a0)
    800027d8:	05953c23          	sd	s9,88(a0)
    800027dc:	07a53023          	sd	s10,96(a0)
    800027e0:	07b53423          	sd	s11,104(a0)
    800027e4:	0005b083          	ld	ra,0(a1)
    800027e8:	0085b103          	ld	sp,8(a1)
    800027ec:	6980                	ld	s0,16(a1)
    800027ee:	6d84                	ld	s1,24(a1)
    800027f0:	0205b903          	ld	s2,32(a1)
    800027f4:	0285b983          	ld	s3,40(a1)
    800027f8:	0305ba03          	ld	s4,48(a1)
    800027fc:	0385ba83          	ld	s5,56(a1)
    80002800:	0405bb03          	ld	s6,64(a1)
    80002804:	0485bb83          	ld	s7,72(a1)
    80002808:	0505bc03          	ld	s8,80(a1)
    8000280c:	0585bc83          	ld	s9,88(a1)
    80002810:	0605bd03          	ld	s10,96(a1)
    80002814:	0685bd83          	ld	s11,104(a1)
    80002818:	8082                	ret

000000008000281a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000281a:	1141                	addi	sp,sp,-16
    8000281c:	e406                	sd	ra,8(sp)
    8000281e:	e022                	sd	s0,0(sp)
    80002820:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002822:	00006597          	auipc	a1,0x6
    80002826:	ad658593          	addi	a1,a1,-1322 # 800082f8 <states.1773+0x30>
    8000282a:	00016517          	auipc	a0,0x16
    8000282e:	99e50513          	addi	a0,a0,-1634 # 800181c8 <tickslock>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	328080e7          	jalr	808(ra) # 80000b5a <initlock>
}
    8000283a:	60a2                	ld	ra,8(sp)
    8000283c:	6402                	ld	s0,0(sp)
    8000283e:	0141                	addi	sp,sp,16
    80002840:	8082                	ret

0000000080002842 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e422                	sd	s0,8(sp)
    80002846:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00003797          	auipc	a5,0x3
    8000284c:	65878793          	addi	a5,a5,1624 # 80005ea0 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002854:	6422                	ld	s0,8(sp)
    80002856:	0141                	addi	sp,sp,16
    80002858:	8082                	ret

000000008000285a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000285a:	1141                	addi	sp,sp,-16
    8000285c:	e406                	sd	ra,8(sp)
    8000285e:	e022                	sd	s0,0(sp)
    80002860:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	164080e7          	jalr	356(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000286a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000286e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002870:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002874:	00004617          	auipc	a2,0x4
    80002878:	78c60613          	addi	a2,a2,1932 # 80007000 <_trampoline>
    8000287c:	00004697          	auipc	a3,0x4
    80002880:	78468693          	addi	a3,a3,1924 # 80007000 <_trampoline>
    80002884:	8e91                	sub	a3,a3,a2
    80002886:	040007b7          	lui	a5,0x4000
    8000288a:	17fd                	addi	a5,a5,-1
    8000288c:	07b2                	slli	a5,a5,0xc
    8000288e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002890:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002894:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002896:	180026f3          	csrr	a3,satp
    8000289a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000289c:	7138                	ld	a4,96(a0)
    8000289e:	6534                	ld	a3,72(a0)
    800028a0:	6585                	lui	a1,0x1
    800028a2:	96ae                	add	a3,a3,a1
    800028a4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028a6:	7138                	ld	a4,96(a0)
    800028a8:	00000697          	auipc	a3,0x0
    800028ac:	13e68693          	addi	a3,a3,318 # 800029e6 <usertrap>
    800028b0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028b2:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028b4:	8692                	mv	a3,tp
    800028b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028c8:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028ca:	6f18                	ld	a4,24(a4)
    800028cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028d0:	6d28                	ld	a0,88(a0)
    800028d2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028d4:	00004717          	auipc	a4,0x4
    800028d8:	7c870713          	addi	a4,a4,1992 # 8000709c <userret>
    800028dc:	8f11                	sub	a4,a4,a2
    800028de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800028e0:	577d                	li	a4,-1
    800028e2:	177e                	slli	a4,a4,0x3f
    800028e4:	8d59                	or	a0,a0,a4
    800028e6:	9782                	jalr	a5
}
    800028e8:	60a2                	ld	ra,8(sp)
    800028ea:	6402                	ld	s0,0(sp)
    800028ec:	0141                	addi	sp,sp,16
    800028ee:	8082                	ret

00000000800028f0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028f0:	1101                	addi	sp,sp,-32
    800028f2:	ec06                	sd	ra,24(sp)
    800028f4:	e822                	sd	s0,16(sp)
    800028f6:	e426                	sd	s1,8(sp)
    800028f8:	e04a                	sd	s2,0(sp)
    800028fa:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028fc:	00016917          	auipc	s2,0x16
    80002900:	8cc90913          	addi	s2,s2,-1844 # 800181c8 <tickslock>
    80002904:	854a                	mv	a0,s2
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	2e4080e7          	jalr	740(ra) # 80000bea <acquire>
  ticks++;
    8000290e:	00006497          	auipc	s1,0x6
    80002912:	20248493          	addi	s1,s1,514 # 80008b10 <ticks>
    80002916:	409c                	lw	a5,0(s1)
    80002918:	2785                	addiw	a5,a5,1
    8000291a:	c09c                	sw	a5,0(s1)
  time_updates();
    8000291c:	fffff097          	auipc	ra,0xfffff
    80002920:	5c0080e7          	jalr	1472(ra) # 80001edc <time_updates>
  wakeup(&ticks);
    80002924:	8526                	mv	a0,s1
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	980080e7          	jalr	-1664(ra) # 800022a6 <wakeup>
  release(&tickslock);
    8000292e:	854a                	mv	a0,s2
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	36e080e7          	jalr	878(ra) # 80000c9e <release>
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret

0000000080002944 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002944:	1101                	addi	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	e426                	sd	s1,8(sp)
    8000294c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002952:	00074d63          	bltz	a4,8000296c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002956:	57fd                	li	a5,-1
    80002958:	17fe                	slli	a5,a5,0x3f
    8000295a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000295c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000295e:	06f70363          	beq	a4,a5,800029c4 <devintr+0x80>
  }
}
    80002962:	60e2                	ld	ra,24(sp)
    80002964:	6442                	ld	s0,16(sp)
    80002966:	64a2                	ld	s1,8(sp)
    80002968:	6105                	addi	sp,sp,32
    8000296a:	8082                	ret
     (scause & 0xff) == 9){
    8000296c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002970:	46a5                	li	a3,9
    80002972:	fed792e3          	bne	a5,a3,80002956 <devintr+0x12>
    int irq = plic_claim();
    80002976:	00003097          	auipc	ra,0x3
    8000297a:	632080e7          	jalr	1586(ra) # 80005fa8 <plic_claim>
    8000297e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002980:	47a9                	li	a5,10
    80002982:	02f50763          	beq	a0,a5,800029b0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002986:	4785                	li	a5,1
    80002988:	02f50963          	beq	a0,a5,800029ba <devintr+0x76>
    return 1;
    8000298c:	4505                	li	a0,1
    } else if(irq){
    8000298e:	d8f1                	beqz	s1,80002962 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002990:	85a6                	mv	a1,s1
    80002992:	00006517          	auipc	a0,0x6
    80002996:	96e50513          	addi	a0,a0,-1682 # 80008300 <states.1773+0x38>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bf4080e7          	jalr	-1036(ra) # 8000058e <printf>
      plic_complete(irq);
    800029a2:	8526                	mv	a0,s1
    800029a4:	00003097          	auipc	ra,0x3
    800029a8:	628080e7          	jalr	1576(ra) # 80005fcc <plic_complete>
    return 1;
    800029ac:	4505                	li	a0,1
    800029ae:	bf55                	j	80002962 <devintr+0x1e>
      uartintr();
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	ffe080e7          	jalr	-2(ra) # 800009ae <uartintr>
    800029b8:	b7ed                	j	800029a2 <devintr+0x5e>
      virtio_disk_intr();
    800029ba:	00004097          	auipc	ra,0x4
    800029be:	b3c080e7          	jalr	-1220(ra) # 800064f6 <virtio_disk_intr>
    800029c2:	b7c5                	j	800029a2 <devintr+0x5e>
    if(cpuid() == 0){
    800029c4:	fffff097          	auipc	ra,0xfffff
    800029c8:	fd6080e7          	jalr	-42(ra) # 8000199a <cpuid>
    800029cc:	c901                	beqz	a0,800029dc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029ce:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029d2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029d4:	14479073          	csrw	sip,a5
    return 2;
    800029d8:	4509                	li	a0,2
    800029da:	b761                	j	80002962 <devintr+0x1e>
      clockintr();
    800029dc:	00000097          	auipc	ra,0x0
    800029e0:	f14080e7          	jalr	-236(ra) # 800028f0 <clockintr>
    800029e4:	b7ed                	j	800029ce <devintr+0x8a>

00000000800029e6 <usertrap>:
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	e04a                	sd	s2,0(sp)
    800029f0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800029f6:	1007f793          	andi	a5,a5,256
    800029fa:	e3b1                	bnez	a5,80002a3e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029fc:	00003797          	auipc	a5,0x3
    80002a00:	4a478793          	addi	a5,a5,1188 # 80005ea0 <kernelvec>
    80002a04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a08:	fffff097          	auipc	ra,0xfffff
    80002a0c:	fbe080e7          	jalr	-66(ra) # 800019c6 <myproc>
    80002a10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a12:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	14102773          	csrr	a4,sepc
    80002a18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a1e:	47a1                	li	a5,8
    80002a20:	02f70763          	beq	a4,a5,80002a4e <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a24:	00000097          	auipc	ra,0x0
    80002a28:	f20080e7          	jalr	-224(ra) # 80002944 <devintr>
    80002a2c:	892a                	mv	s2,a0
    80002a2e:	c151                	beqz	a0,80002ab2 <usertrap+0xcc>
  if(killed(p))
    80002a30:	8526                	mv	a0,s1
    80002a32:	00000097          	auipc	ra,0x0
    80002a36:	ac4080e7          	jalr	-1340(ra) # 800024f6 <killed>
    80002a3a:	c929                	beqz	a0,80002a8c <usertrap+0xa6>
    80002a3c:	a099                	j	80002a82 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	8e250513          	addi	a0,a0,-1822 # 80008320 <states.1773+0x58>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	afe080e7          	jalr	-1282(ra) # 80000544 <panic>
    if(killed(p))
    80002a4e:	00000097          	auipc	ra,0x0
    80002a52:	aa8080e7          	jalr	-1368(ra) # 800024f6 <killed>
    80002a56:	e921                	bnez	a0,80002aa6 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a58:	70b8                	ld	a4,96(s1)
    80002a5a:	6f1c                	ld	a5,24(a4)
    80002a5c:	0791                	addi	a5,a5,4
    80002a5e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a64:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a68:	10079073          	csrw	sstatus,a5
    syscall();
    80002a6c:	00000097          	auipc	ra,0x0
    80002a70:	2d8080e7          	jalr	728(ra) # 80002d44 <syscall>
  if(killed(p))
    80002a74:	8526                	mv	a0,s1
    80002a76:	00000097          	auipc	ra,0x0
    80002a7a:	a80080e7          	jalr	-1408(ra) # 800024f6 <killed>
    80002a7e:	c911                	beqz	a0,80002a92 <usertrap+0xac>
    80002a80:	4901                	li	s2,0
    exit(-1);
    80002a82:	557d                	li	a0,-1
    80002a84:	00000097          	auipc	ra,0x0
    80002a88:	8f2080e7          	jalr	-1806(ra) # 80002376 <exit>
  if(which_dev == 2)
    80002a8c:	4789                	li	a5,2
    80002a8e:	04f90f63          	beq	s2,a5,80002aec <usertrap+0x106>
  usertrapret();
    80002a92:	00000097          	auipc	ra,0x0
    80002a96:	dc8080e7          	jalr	-568(ra) # 8000285a <usertrapret>
}
    80002a9a:	60e2                	ld	ra,24(sp)
    80002a9c:	6442                	ld	s0,16(sp)
    80002a9e:	64a2                	ld	s1,8(sp)
    80002aa0:	6902                	ld	s2,0(sp)
    80002aa2:	6105                	addi	sp,sp,32
    80002aa4:	8082                	ret
      exit(-1);
    80002aa6:	557d                	li	a0,-1
    80002aa8:	00000097          	auipc	ra,0x0
    80002aac:	8ce080e7          	jalr	-1842(ra) # 80002376 <exit>
    80002ab0:	b765                	j	80002a58 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ab6:	5890                	lw	a2,48(s1)
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	88850513          	addi	a0,a0,-1912 # 80008340 <states.1773+0x78>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	ace080e7          	jalr	-1330(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ac8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002acc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ad0:	00006517          	auipc	a0,0x6
    80002ad4:	8a050513          	addi	a0,a0,-1888 # 80008370 <states.1773+0xa8>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	ab6080e7          	jalr	-1354(ra) # 8000058e <printf>
    setkilled(p);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	00000097          	auipc	ra,0x0
    80002ae6:	9e8080e7          	jalr	-1560(ra) # 800024ca <setkilled>
    80002aea:	b769                	j	80002a74 <usertrap+0x8e>
    yield();
    80002aec:	fffff097          	auipc	ra,0xfffff
    80002af0:	5d2080e7          	jalr	1490(ra) # 800020be <yield>
    80002af4:	bf79                	j	80002a92 <usertrap+0xac>

0000000080002af6 <kerneltrap>:
{
    80002af6:	7179                	addi	sp,sp,-48
    80002af8:	f406                	sd	ra,40(sp)
    80002afa:	f022                	sd	s0,32(sp)
    80002afc:	ec26                	sd	s1,24(sp)
    80002afe:	e84a                	sd	s2,16(sp)
    80002b00:	e44e                	sd	s3,8(sp)
    80002b02:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b04:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b08:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b0c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b10:	1004f793          	andi	a5,s1,256
    80002b14:	cb85                	beqz	a5,80002b44 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b16:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b1a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b1c:	ef85                	bnez	a5,80002b54 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b1e:	00000097          	auipc	ra,0x0
    80002b22:	e26080e7          	jalr	-474(ra) # 80002944 <devintr>
    80002b26:	cd1d                	beqz	a0,80002b64 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b28:	4789                	li	a5,2
    80002b2a:	06f50a63          	beq	a0,a5,80002b9e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b2e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b32:	10049073          	csrw	sstatus,s1
}
    80002b36:	70a2                	ld	ra,40(sp)
    80002b38:	7402                	ld	s0,32(sp)
    80002b3a:	64e2                	ld	s1,24(sp)
    80002b3c:	6942                	ld	s2,16(sp)
    80002b3e:	69a2                	ld	s3,8(sp)
    80002b40:	6145                	addi	sp,sp,48
    80002b42:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	84c50513          	addi	a0,a0,-1972 # 80008390 <states.1773+0xc8>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9f8080e7          	jalr	-1544(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b54:	00006517          	auipc	a0,0x6
    80002b58:	86450513          	addi	a0,a0,-1948 # 800083b8 <states.1773+0xf0>
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	9e8080e7          	jalr	-1560(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002b64:	85ce                	mv	a1,s3
    80002b66:	00006517          	auipc	a0,0x6
    80002b6a:	87250513          	addi	a0,a0,-1934 # 800083d8 <states.1773+0x110>
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	a20080e7          	jalr	-1504(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b76:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b7a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	86a50513          	addi	a0,a0,-1942 # 800083e8 <states.1773+0x120>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	a08080e7          	jalr	-1528(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002b8e:	00006517          	auipc	a0,0x6
    80002b92:	87250513          	addi	a0,a0,-1934 # 80008400 <states.1773+0x138>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9ae080e7          	jalr	-1618(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b9e:	fffff097          	auipc	ra,0xfffff
    80002ba2:	e28080e7          	jalr	-472(ra) # 800019c6 <myproc>
    80002ba6:	d541                	beqz	a0,80002b2e <kerneltrap+0x38>
    80002ba8:	fffff097          	auipc	ra,0xfffff
    80002bac:	e1e080e7          	jalr	-482(ra) # 800019c6 <myproc>
    80002bb0:	4d18                	lw	a4,24(a0)
    80002bb2:	4791                	li	a5,4
    80002bb4:	f6f71de3          	bne	a4,a5,80002b2e <kerneltrap+0x38>
      yield();
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	506080e7          	jalr	1286(ra) # 800020be <yield>
    80002bc0:	b7bd                	j	80002b2e <kerneltrap+0x38>

0000000080002bc2 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	1000                	addi	s0,sp,32
    80002bcc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	df8080e7          	jalr	-520(ra) # 800019c6 <myproc>
  switch (n) {
    80002bd6:	4795                	li	a5,5
    80002bd8:	0497e163          	bltu	a5,s1,80002c1a <argraw+0x58>
    80002bdc:	048a                	slli	s1,s1,0x2
    80002bde:	00006717          	auipc	a4,0x6
    80002be2:	95270713          	addi	a4,a4,-1710 # 80008530 <states.1773+0x268>
    80002be6:	94ba                	add	s1,s1,a4
    80002be8:	409c                	lw	a5,0(s1)
    80002bea:	97ba                	add	a5,a5,a4
    80002bec:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bee:	713c                	ld	a5,96(a0)
    80002bf0:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bf2:	60e2                	ld	ra,24(sp)
    80002bf4:	6442                	ld	s0,16(sp)
    80002bf6:	64a2                	ld	s1,8(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret
    return p->trapframe->a1;
    80002bfc:	713c                	ld	a5,96(a0)
    80002bfe:	7fa8                	ld	a0,120(a5)
    80002c00:	bfcd                	j	80002bf2 <argraw+0x30>
    return p->trapframe->a2;
    80002c02:	713c                	ld	a5,96(a0)
    80002c04:	63c8                	ld	a0,128(a5)
    80002c06:	b7f5                	j	80002bf2 <argraw+0x30>
    return p->trapframe->a3;
    80002c08:	713c                	ld	a5,96(a0)
    80002c0a:	67c8                	ld	a0,136(a5)
    80002c0c:	b7dd                	j	80002bf2 <argraw+0x30>
    return p->trapframe->a4;
    80002c0e:	713c                	ld	a5,96(a0)
    80002c10:	6bc8                	ld	a0,144(a5)
    80002c12:	b7c5                	j	80002bf2 <argraw+0x30>
    return p->trapframe->a5;
    80002c14:	713c                	ld	a5,96(a0)
    80002c16:	6fc8                	ld	a0,152(a5)
    80002c18:	bfe9                	j	80002bf2 <argraw+0x30>
  panic("argraw");
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	7f650513          	addi	a0,a0,2038 # 80008410 <states.1773+0x148>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	922080e7          	jalr	-1758(ra) # 80000544 <panic>

0000000080002c2a <fetchaddr>:
{
    80002c2a:	1101                	addi	sp,sp,-32
    80002c2c:	ec06                	sd	ra,24(sp)
    80002c2e:	e822                	sd	s0,16(sp)
    80002c30:	e426                	sd	s1,8(sp)
    80002c32:	e04a                	sd	s2,0(sp)
    80002c34:	1000                	addi	s0,sp,32
    80002c36:	84aa                	mv	s1,a0
    80002c38:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c3a:	fffff097          	auipc	ra,0xfffff
    80002c3e:	d8c080e7          	jalr	-628(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c42:	693c                	ld	a5,80(a0)
    80002c44:	02f4f863          	bgeu	s1,a5,80002c74 <fetchaddr+0x4a>
    80002c48:	00848713          	addi	a4,s1,8
    80002c4c:	02e7e663          	bltu	a5,a4,80002c78 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c50:	46a1                	li	a3,8
    80002c52:	8626                	mv	a2,s1
    80002c54:	85ca                	mv	a1,s2
    80002c56:	6d28                	ld	a0,88(a0)
    80002c58:	fffff097          	auipc	ra,0xfffff
    80002c5c:	ab8080e7          	jalr	-1352(ra) # 80001710 <copyin>
    80002c60:	00a03533          	snez	a0,a0
    80002c64:	40a00533          	neg	a0,a0
}
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6902                	ld	s2,0(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret
    return -1;
    80002c74:	557d                	li	a0,-1
    80002c76:	bfcd                	j	80002c68 <fetchaddr+0x3e>
    80002c78:	557d                	li	a0,-1
    80002c7a:	b7fd                	j	80002c68 <fetchaddr+0x3e>

0000000080002c7c <fetchstr>:
{
    80002c7c:	7179                	addi	sp,sp,-48
    80002c7e:	f406                	sd	ra,40(sp)
    80002c80:	f022                	sd	s0,32(sp)
    80002c82:	ec26                	sd	s1,24(sp)
    80002c84:	e84a                	sd	s2,16(sp)
    80002c86:	e44e                	sd	s3,8(sp)
    80002c88:	1800                	addi	s0,sp,48
    80002c8a:	892a                	mv	s2,a0
    80002c8c:	84ae                	mv	s1,a1
    80002c8e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d36080e7          	jalr	-714(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002c98:	86ce                	mv	a3,s3
    80002c9a:	864a                	mv	a2,s2
    80002c9c:	85a6                	mv	a1,s1
    80002c9e:	6d28                	ld	a0,88(a0)
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	afc080e7          	jalr	-1284(ra) # 8000179c <copyinstr>
    80002ca8:	00054e63          	bltz	a0,80002cc4 <fetchstr+0x48>
  return strlen(buf);
    80002cac:	8526                	mv	a0,s1
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	1bc080e7          	jalr	444(ra) # 80000e6a <strlen>
}
    80002cb6:	70a2                	ld	ra,40(sp)
    80002cb8:	7402                	ld	s0,32(sp)
    80002cba:	64e2                	ld	s1,24(sp)
    80002cbc:	6942                	ld	s2,16(sp)
    80002cbe:	69a2                	ld	s3,8(sp)
    80002cc0:	6145                	addi	sp,sp,48
    80002cc2:	8082                	ret
    return -1;
    80002cc4:	557d                	li	a0,-1
    80002cc6:	bfc5                	j	80002cb6 <fetchstr+0x3a>

0000000080002cc8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	e426                	sd	s1,8(sp)
    80002cd0:	1000                	addi	s0,sp,32
    80002cd2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	eee080e7          	jalr	-274(ra) # 80002bc2 <argraw>
    80002cdc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cde:	4501                	li	a0,0
    80002ce0:	60e2                	ld	ra,24(sp)
    80002ce2:	6442                	ld	s0,16(sp)
    80002ce4:	64a2                	ld	s1,8(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	1000                	addi	s0,sp,32
    80002cf4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cf6:	00000097          	auipc	ra,0x0
    80002cfa:	ecc080e7          	jalr	-308(ra) # 80002bc2 <argraw>
    80002cfe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d00:	4501                	li	a0,0
    80002d02:	60e2                	ld	ra,24(sp)
    80002d04:	6442                	ld	s0,16(sp)
    80002d06:	64a2                	ld	s1,8(sp)
    80002d08:	6105                	addi	sp,sp,32
    80002d0a:	8082                	ret

0000000080002d0c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d0c:	7179                	addi	sp,sp,-48
    80002d0e:	f406                	sd	ra,40(sp)
    80002d10:	f022                	sd	s0,32(sp)
    80002d12:	ec26                	sd	s1,24(sp)
    80002d14:	e84a                	sd	s2,16(sp)
    80002d16:	1800                	addi	s0,sp,48
    80002d18:	84ae                	mv	s1,a1
    80002d1a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d1c:	fd840593          	addi	a1,s0,-40
    80002d20:	00000097          	auipc	ra,0x0
    80002d24:	fca080e7          	jalr	-54(ra) # 80002cea <argaddr>
  return fetchstr(addr, buf, max);
    80002d28:	864a                	mv	a2,s2
    80002d2a:	85a6                	mv	a1,s1
    80002d2c:	fd843503          	ld	a0,-40(s0)
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	f4c080e7          	jalr	-180(ra) # 80002c7c <fetchstr>
}
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6942                	ld	s2,16(sp)
    80002d40:	6145                	addi	sp,sp,48
    80002d42:	8082                	ret

0000000080002d44 <syscall>:
  0
};

void
syscall(void)
{
    80002d44:	7139                	addi	sp,sp,-64
    80002d46:	fc06                	sd	ra,56(sp)
    80002d48:	f822                	sd	s0,48(sp)
    80002d4a:	f426                	sd	s1,40(sp)
    80002d4c:	f04a                	sd	s2,32(sp)
    80002d4e:	ec4e                	sd	s3,24(sp)
    80002d50:	e852                	sd	s4,16(sp)
    80002d52:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	c72080e7          	jalr	-910(ra) # 800019c6 <myproc>
    80002d5c:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80002d5e:	06053983          	ld	s3,96(a0)
    80002d62:	0a89b783          	ld	a5,168(s3)
    80002d66:	0007849b          	sext.w	s1,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d6a:	37fd                	addiw	a5,a5,-1
    80002d6c:	475d                	li	a4,23
    80002d6e:	00f76f63          	bltu	a4,a5,80002d8c <syscall+0x48>
    80002d72:	00349713          	slli	a4,s1,0x3
    80002d76:	00005797          	auipc	a5,0x5
    80002d7a:	7d278793          	addi	a5,a5,2002 # 80008548 <syscalls>
    80002d7e:	97ba                	add	a5,a5,a4
    80002d80:	639c                	ld	a5,0(a5)
    80002d82:	c789                	beqz	a5,80002d8c <syscall+0x48>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d84:	9782                	jalr	a5
    80002d86:	06a9b823          	sd	a0,112(s3)
    80002d8a:	a015                	j	80002dae <syscall+0x6a>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d8c:	86a6                	mv	a3,s1
    80002d8e:	16090613          	addi	a2,s2,352
    80002d92:	03092583          	lw	a1,48(s2)
    80002d96:	00005517          	auipc	a0,0x5
    80002d9a:	68250513          	addi	a0,a0,1666 # 80008418 <states.1773+0x150>
    80002d9e:	ffffd097          	auipc	ra,0xffffd
    80002da2:	7f0080e7          	jalr	2032(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002da6:	06093783          	ld	a5,96(s2)
    80002daa:	577d                	li	a4,-1
    80002dac:	fbb8                	sd	a4,112(a5)
  }

    // trace 
    if (p->trace_mask >> num) 
    80002dae:	17492783          	lw	a5,372(s2)
    80002db2:	4097d7bb          	sraw	a5,a5,s1
    80002db6:	eb89                	bnez	a5,80002dc8 <syscall+0x84>

      // value of the syscall
      printf(") -> %d\n", p->trapframe->a0);
    }

}
    80002db8:	70e2                	ld	ra,56(sp)
    80002dba:	7442                	ld	s0,48(sp)
    80002dbc:	74a2                	ld	s1,40(sp)
    80002dbe:	7902                	ld	s2,32(sp)
    80002dc0:	69e2                	ld	s3,24(sp)
    80002dc2:	6a42                	ld	s4,16(sp)
    80002dc4:	6121                	addi	sp,sp,64
    80002dc6:	8082                	ret
      printf("%d: syscall %s (", p->pid, syscall_names[num]);
    80002dc8:	00005997          	auipc	s3,0x5
    80002dcc:	78098993          	addi	s3,s3,1920 # 80008548 <syscalls>
    80002dd0:	00349793          	slli	a5,s1,0x3
    80002dd4:	97ce                	add	a5,a5,s3
    80002dd6:	67f0                	ld	a2,200(a5)
    80002dd8:	03092583          	lw	a1,48(s2)
    80002ddc:	00005517          	auipc	a0,0x5
    80002de0:	65c50513          	addi	a0,a0,1628 # 80008438 <states.1773+0x170>
    80002de4:	ffffd097          	auipc	ra,0xffffd
    80002de8:	7aa080e7          	jalr	1962(ra) # 8000058e <printf>
      for(int i = NUL; i<syscall_argc[num]; i++)
    80002dec:	048a                	slli	s1,s1,0x2
    80002dee:	94ce                	add	s1,s1,s3
    80002df0:	1904a983          	lw	s3,400(s1)
    80002df4:	03305863          	blez	s3,80002e24 <syscall+0xe0>
    80002df8:	4481                	li	s1,0
        printf("%d ", syscall_argm);
    80002dfa:	00005a17          	auipc	s4,0x5
    80002dfe:	656a0a13          	addi	s4,s4,1622 # 80008450 <states.1773+0x188>
        argint(i, &syscall_argm);
    80002e02:	fcc40593          	addi	a1,s0,-52
    80002e06:	8526                	mv	a0,s1
    80002e08:	00000097          	auipc	ra,0x0
    80002e0c:	ec0080e7          	jalr	-320(ra) # 80002cc8 <argint>
        printf("%d ", syscall_argm);
    80002e10:	fcc42583          	lw	a1,-52(s0)
    80002e14:	8552                	mv	a0,s4
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	778080e7          	jalr	1912(ra) # 8000058e <printf>
      for(int i = NUL; i<syscall_argc[num]; i++)
    80002e1e:	2485                	addiw	s1,s1,1
    80002e20:	ff3491e3          	bne	s1,s3,80002e02 <syscall+0xbe>
      printf(") -> %d\n", p->trapframe->a0);
    80002e24:	06093783          	ld	a5,96(s2)
    80002e28:	7bac                	ld	a1,112(a5)
    80002e2a:	00005517          	auipc	a0,0x5
    80002e2e:	62e50513          	addi	a0,a0,1582 # 80008458 <states.1773+0x190>
    80002e32:	ffffd097          	auipc	ra,0xffffd
    80002e36:	75c080e7          	jalr	1884(ra) # 8000058e <printf>
}
    80002e3a:	bfbd                	j	80002db8 <syscall+0x74>

0000000080002e3c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e44:	fec40593          	addi	a1,s0,-20
    80002e48:	4501                	li	a0,0
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	e7e080e7          	jalr	-386(ra) # 80002cc8 <argint>
  exit(n);
    80002e52:	fec42503          	lw	a0,-20(s0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	520080e7          	jalr	1312(ra) # 80002376 <exit>
  return 0;  // not reached
}
    80002e5e:	4501                	li	a0,0
    80002e60:	60e2                	ld	ra,24(sp)
    80002e62:	6442                	ld	s0,16(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e68:	1141                	addi	sp,sp,-16
    80002e6a:	e406                	sd	ra,8(sp)
    80002e6c:	e022                	sd	s0,0(sp)
    80002e6e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	b56080e7          	jalr	-1194(ra) # 800019c6 <myproc>
}
    80002e78:	5908                	lw	a0,48(a0)
    80002e7a:	60a2                	ld	ra,8(sp)
    80002e7c:	6402                	ld	s0,0(sp)
    80002e7e:	0141                	addi	sp,sp,16
    80002e80:	8082                	ret

0000000080002e82 <sys_fork>:

uint64
sys_fork(void)
{
    80002e82:	1141                	addi	sp,sp,-16
    80002e84:	e406                	sd	ra,8(sp)
    80002e86:	e022                	sd	s0,0(sp)
    80002e88:	0800                	addi	s0,sp,16
  return fork();
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	f0e080e7          	jalr	-242(ra) # 80001d98 <fork>
}
    80002e92:	60a2                	ld	ra,8(sp)
    80002e94:	6402                	ld	s0,0(sp)
    80002e96:	0141                	addi	sp,sp,16
    80002e98:	8082                	ret

0000000080002e9a <sys_wait>:

uint64
sys_wait(void)
{
    80002e9a:	1101                	addi	sp,sp,-32
    80002e9c:	ec06                	sd	ra,24(sp)
    80002e9e:	e822                	sd	s0,16(sp)
    80002ea0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ea2:	fe840593          	addi	a1,s0,-24
    80002ea6:	4501                	li	a0,0
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	e42080e7          	jalr	-446(ra) # 80002cea <argaddr>
  return wait(p);
    80002eb0:	fe843503          	ld	a0,-24(s0)
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	674080e7          	jalr	1652(ra) # 80002528 <wait>
}
    80002ebc:	60e2                	ld	ra,24(sp)
    80002ebe:	6442                	ld	s0,16(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <sys_waitx>:

uint64
sys_waitx(void)
{
    80002ec4:	7139                	addi	sp,sp,-64
    80002ec6:	fc06                	sd	ra,56(sp)
    80002ec8:	f822                	sd	s0,48(sp)
    80002eca:	f426                	sd	s1,40(sp)
    80002ecc:	f04a                	sd	s2,32(sp)
    80002ece:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80002ed0:	fd840593          	addi	a1,s0,-40
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	e14080e7          	jalr	-492(ra) # 80002cea <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80002ede:	fd040593          	addi	a1,s0,-48
    80002ee2:	4505                	li	a0,1
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	e06080e7          	jalr	-506(ra) # 80002cea <argaddr>
  argaddr(2, &addr2);
    80002eec:	fc840593          	addi	a1,s0,-56
    80002ef0:	4509                	li	a0,2
    80002ef2:	00000097          	auipc	ra,0x0
    80002ef6:	df8080e7          	jalr	-520(ra) # 80002cea <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80002efa:	fc040613          	addi	a2,s0,-64
    80002efe:	fc440593          	addi	a1,s0,-60
    80002f02:	fd843503          	ld	a0,-40(s0)
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	258080e7          	jalr	600(ra) # 8000215e <waitx>
    80002f0e:	892a                	mv	s2,a0
  struct proc* p = myproc();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	ab6080e7          	jalr	-1354(ra) # 800019c6 <myproc>
    80002f18:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f1a:	4691                	li	a3,4
    80002f1c:	fc440613          	addi	a2,s0,-60
    80002f20:	fd043583          	ld	a1,-48(s0)
    80002f24:	6d28                	ld	a0,88(a0)
    80002f26:	ffffe097          	auipc	ra,0xffffe
    80002f2a:	75e080e7          	jalr	1886(ra) # 80001684 <copyout>
    return -1;
    80002f2e:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80002f30:	00054f63          	bltz	a0,80002f4e <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80002f34:	4691                	li	a3,4
    80002f36:	fc040613          	addi	a2,s0,-64
    80002f3a:	fc843583          	ld	a1,-56(s0)
    80002f3e:	6ca8                	ld	a0,88(s1)
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	744080e7          	jalr	1860(ra) # 80001684 <copyout>
    80002f48:	00054a63          	bltz	a0,80002f5c <sys_waitx+0x98>
    return -1;
  return ret;
    80002f4c:	87ca                	mv	a5,s2
}
    80002f4e:	853e                	mv	a0,a5
    80002f50:	70e2                	ld	ra,56(sp)
    80002f52:	7442                	ld	s0,48(sp)
    80002f54:	74a2                	ld	s1,40(sp)
    80002f56:	7902                	ld	s2,32(sp)
    80002f58:	6121                	addi	sp,sp,64
    80002f5a:	8082                	ret
    return -1;
    80002f5c:	57fd                	li	a5,-1
    80002f5e:	bfc5                	j	80002f4e <sys_waitx+0x8a>

0000000080002f60 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f60:	7179                	addi	sp,sp,-48
    80002f62:	f406                	sd	ra,40(sp)
    80002f64:	f022                	sd	s0,32(sp)
    80002f66:	ec26                	sd	s1,24(sp)
    80002f68:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f6a:	fdc40593          	addi	a1,s0,-36
    80002f6e:	4501                	li	a0,0
    80002f70:	00000097          	auipc	ra,0x0
    80002f74:	d58080e7          	jalr	-680(ra) # 80002cc8 <argint>
  addr = myproc()->sz;
    80002f78:	fffff097          	auipc	ra,0xfffff
    80002f7c:	a4e080e7          	jalr	-1458(ra) # 800019c6 <myproc>
    80002f80:	6924                	ld	s1,80(a0)
  if(growproc(n) < 0)
    80002f82:	fdc42503          	lw	a0,-36(s0)
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	db6080e7          	jalr	-586(ra) # 80001d3c <growproc>
    80002f8e:	00054863          	bltz	a0,80002f9e <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f92:	8526                	mv	a0,s1
    80002f94:	70a2                	ld	ra,40(sp)
    80002f96:	7402                	ld	s0,32(sp)
    80002f98:	64e2                	ld	s1,24(sp)
    80002f9a:	6145                	addi	sp,sp,48
    80002f9c:	8082                	ret
    return -1;
    80002f9e:	54fd                	li	s1,-1
    80002fa0:	bfcd                	j	80002f92 <sys_sbrk+0x32>

0000000080002fa2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fa2:	7139                	addi	sp,sp,-64
    80002fa4:	fc06                	sd	ra,56(sp)
    80002fa6:	f822                	sd	s0,48(sp)
    80002fa8:	f426                	sd	s1,40(sp)
    80002faa:	f04a                	sd	s2,32(sp)
    80002fac:	ec4e                	sd	s3,24(sp)
    80002fae:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fb0:	fcc40593          	addi	a1,s0,-52
    80002fb4:	4501                	li	a0,0
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	d12080e7          	jalr	-750(ra) # 80002cc8 <argint>
  acquire(&tickslock);
    80002fbe:	00015517          	auipc	a0,0x15
    80002fc2:	20a50513          	addi	a0,a0,522 # 800181c8 <tickslock>
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	c24080e7          	jalr	-988(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002fce:	00006917          	auipc	s2,0x6
    80002fd2:	b4292903          	lw	s2,-1214(s2) # 80008b10 <ticks>
  while(ticks - ticks0 < n){
    80002fd6:	fcc42783          	lw	a5,-52(s0)
    80002fda:	cf9d                	beqz	a5,80003018 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fdc:	00015997          	auipc	s3,0x15
    80002fe0:	1ec98993          	addi	s3,s3,492 # 800181c8 <tickslock>
    80002fe4:	00006497          	auipc	s1,0x6
    80002fe8:	b2c48493          	addi	s1,s1,-1236 # 80008b10 <ticks>
    if(killed(myproc())){
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	9da080e7          	jalr	-1574(ra) # 800019c6 <myproc>
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	502080e7          	jalr	1282(ra) # 800024f6 <killed>
    80002ffc:	ed15                	bnez	a0,80003038 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ffe:	85ce                	mv	a1,s3
    80003000:	8526                	mv	a0,s1
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	0f8080e7          	jalr	248(ra) # 800020fa <sleep>
  while(ticks - ticks0 < n){
    8000300a:	409c                	lw	a5,0(s1)
    8000300c:	412787bb          	subw	a5,a5,s2
    80003010:	fcc42703          	lw	a4,-52(s0)
    80003014:	fce7ece3          	bltu	a5,a4,80002fec <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003018:	00015517          	auipc	a0,0x15
    8000301c:	1b050513          	addi	a0,a0,432 # 800181c8 <tickslock>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	c7e080e7          	jalr	-898(ra) # 80000c9e <release>
  return 0;
    80003028:	4501                	li	a0,0
}
    8000302a:	70e2                	ld	ra,56(sp)
    8000302c:	7442                	ld	s0,48(sp)
    8000302e:	74a2                	ld	s1,40(sp)
    80003030:	7902                	ld	s2,32(sp)
    80003032:	69e2                	ld	s3,24(sp)
    80003034:	6121                	addi	sp,sp,64
    80003036:	8082                	ret
      release(&tickslock);
    80003038:	00015517          	auipc	a0,0x15
    8000303c:	19050513          	addi	a0,a0,400 # 800181c8 <tickslock>
    80003040:	ffffe097          	auipc	ra,0xffffe
    80003044:	c5e080e7          	jalr	-930(ra) # 80000c9e <release>
      return -1;
    80003048:	557d                	li	a0,-1
    8000304a:	b7c5                	j	8000302a <sys_sleep+0x88>

000000008000304c <sys_kill>:

uint64
sys_kill(void)
{
    8000304c:	1101                	addi	sp,sp,-32
    8000304e:	ec06                	sd	ra,24(sp)
    80003050:	e822                	sd	s0,16(sp)
    80003052:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003054:	fec40593          	addi	a1,s0,-20
    80003058:	4501                	li	a0,0
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	c6e080e7          	jalr	-914(ra) # 80002cc8 <argint>
  return kill(pid);
    80003062:	fec42503          	lw	a0,-20(s0)
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	3f2080e7          	jalr	1010(ra) # 80002458 <kill>
}
    8000306e:	60e2                	ld	ra,24(sp)
    80003070:	6442                	ld	s0,16(sp)
    80003072:	6105                	addi	sp,sp,32
    80003074:	8082                	ret

0000000080003076 <sys_uptime>:
  
// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003076:	1101                	addi	sp,sp,-32
    80003078:	ec06                	sd	ra,24(sp)
    8000307a:	e822                	sd	s0,16(sp)
    8000307c:	e426                	sd	s1,8(sp)
    8000307e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003080:	00015517          	auipc	a0,0x15
    80003084:	14850513          	addi	a0,a0,328 # 800181c8 <tickslock>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	b62080e7          	jalr	-1182(ra) # 80000bea <acquire>
  xticks = ticks;
    80003090:	00006497          	auipc	s1,0x6
    80003094:	a804a483          	lw	s1,-1408(s1) # 80008b10 <ticks>
  release(&tickslock);
    80003098:	00015517          	auipc	a0,0x15
    8000309c:	13050513          	addi	a0,a0,304 # 800181c8 <tickslock>
    800030a0:	ffffe097          	auipc	ra,0xffffe
    800030a4:	bfe080e7          	jalr	-1026(ra) # 80000c9e <release>
  return xticks;
}
    800030a8:	02049513          	slli	a0,s1,0x20
    800030ac:	9101                	srli	a0,a0,0x20
    800030ae:	60e2                	ld	ra,24(sp)
    800030b0:	6442                	ld	s0,16(sp)
    800030b2:	64a2                	ld	s1,8(sp)
    800030b4:	6105                	addi	sp,sp,32
    800030b6:	8082                	ret

00000000800030b8 <sys_trace>:

uint64
sys_trace(void){
    800030b8:	1141                	addi	sp,sp,-16
    800030ba:	e406                	sd	ra,8(sp)
    800030bc:	e022                	sd	s0,0(sp)
    800030be:	0800                	addi	s0,sp,16
  if (argint(NUL, &myproc()->trace_mask) < NUL)
    800030c0:	fffff097          	auipc	ra,0xfffff
    800030c4:	906080e7          	jalr	-1786(ra) # 800019c6 <myproc>
    800030c8:	17450593          	addi	a1,a0,372
    800030cc:	4501                	li	a0,0
    800030ce:	00000097          	auipc	ra,0x0
    800030d2:	bfa080e7          	jalr	-1030(ra) # 80002cc8 <argint>
    return -1;

  return NUL;
}
    800030d6:	957d                	srai	a0,a0,0x3f
    800030d8:	60a2                	ld	ra,8(sp)
    800030da:	6402                	ld	s0,0(sp)
    800030dc:	0141                	addi	sp,sp,16
    800030de:	8082                	ret

00000000800030e0 <sys_set_priority>:

uint64
sys_set_priority(void)
{
    800030e0:	1101                	addi	sp,sp,-32
    800030e2:	ec06                	sd	ra,24(sp)
    800030e4:	e822                	sd	s0,16(sp)
    800030e6:	1000                	addi	s0,sp,32
  int pid;
  int priority;
  if(argint(0, &priority) < 0)
    800030e8:	fe840593          	addi	a1,s0,-24
    800030ec:	4501                	li	a0,0
    800030ee:	00000097          	auipc	ra,0x0
    800030f2:	bda080e7          	jalr	-1062(ra) # 80002cc8 <argint>
    return -1;
    800030f6:	57fd                	li	a5,-1
  if(argint(0, &priority) < 0)
    800030f8:	02054563          	bltz	a0,80003122 <sys_set_priority+0x42>
  if(argint(1, &pid) < 0)
    800030fc:	fec40593          	addi	a1,s0,-20
    80003100:	4505                	li	a0,1
    80003102:	00000097          	auipc	ra,0x0
    80003106:	bc6080e7          	jalr	-1082(ra) # 80002cc8 <argint>
    return -1;
    8000310a:	57fd                	li	a5,-1
  if(argint(1, &pid) < 0)
    8000310c:	00054b63          	bltz	a0,80003122 <sys_set_priority+0x42>
  return set_priority(priority,pid);
    80003110:	fec42583          	lw	a1,-20(s0)
    80003114:	fe842503          	lw	a0,-24(s0)
    80003118:	fffff097          	auipc	ra,0xfffff
    8000311c:	e22080e7          	jalr	-478(ra) # 80001f3a <set_priority>
    80003120:	87aa                	mv	a5,a0
    80003122:	853e                	mv	a0,a5
    80003124:	60e2                	ld	ra,24(sp)
    80003126:	6442                	ld	s0,16(sp)
    80003128:	6105                	addi	sp,sp,32
    8000312a:	8082                	ret

000000008000312c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000312c:	7179                	addi	sp,sp,-48
    8000312e:	f406                	sd	ra,40(sp)
    80003130:	f022                	sd	s0,32(sp)
    80003132:	ec26                	sd	s1,24(sp)
    80003134:	e84a                	sd	s2,16(sp)
    80003136:	e44e                	sd	s3,8(sp)
    80003138:	e052                	sd	s4,0(sp)
    8000313a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000313c:	00005597          	auipc	a1,0x5
    80003140:	60458593          	addi	a1,a1,1540 # 80008740 <syscall_argc+0x68>
    80003144:	00015517          	auipc	a0,0x15
    80003148:	09c50513          	addi	a0,a0,156 # 800181e0 <bcache>
    8000314c:	ffffe097          	auipc	ra,0xffffe
    80003150:	a0e080e7          	jalr	-1522(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003154:	0001d797          	auipc	a5,0x1d
    80003158:	08c78793          	addi	a5,a5,140 # 800201e0 <bcache+0x8000>
    8000315c:	0001d717          	auipc	a4,0x1d
    80003160:	2ec70713          	addi	a4,a4,748 # 80020448 <bcache+0x8268>
    80003164:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003168:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000316c:	00015497          	auipc	s1,0x15
    80003170:	08c48493          	addi	s1,s1,140 # 800181f8 <bcache+0x18>
    b->next = bcache.head.next;
    80003174:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003176:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003178:	00005a17          	auipc	s4,0x5
    8000317c:	5d0a0a13          	addi	s4,s4,1488 # 80008748 <syscall_argc+0x70>
    b->next = bcache.head.next;
    80003180:	2b893783          	ld	a5,696(s2)
    80003184:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003186:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000318a:	85d2                	mv	a1,s4
    8000318c:	01048513          	addi	a0,s1,16
    80003190:	00001097          	auipc	ra,0x1
    80003194:	4c4080e7          	jalr	1220(ra) # 80004654 <initsleeplock>
    bcache.head.next->prev = b;
    80003198:	2b893783          	ld	a5,696(s2)
    8000319c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000319e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031a2:	45848493          	addi	s1,s1,1112
    800031a6:	fd349de3          	bne	s1,s3,80003180 <binit+0x54>
  }
}
    800031aa:	70a2                	ld	ra,40(sp)
    800031ac:	7402                	ld	s0,32(sp)
    800031ae:	64e2                	ld	s1,24(sp)
    800031b0:	6942                	ld	s2,16(sp)
    800031b2:	69a2                	ld	s3,8(sp)
    800031b4:	6a02                	ld	s4,0(sp)
    800031b6:	6145                	addi	sp,sp,48
    800031b8:	8082                	ret

00000000800031ba <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031ba:	7179                	addi	sp,sp,-48
    800031bc:	f406                	sd	ra,40(sp)
    800031be:	f022                	sd	s0,32(sp)
    800031c0:	ec26                	sd	s1,24(sp)
    800031c2:	e84a                	sd	s2,16(sp)
    800031c4:	e44e                	sd	s3,8(sp)
    800031c6:	1800                	addi	s0,sp,48
    800031c8:	89aa                	mv	s3,a0
    800031ca:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031cc:	00015517          	auipc	a0,0x15
    800031d0:	01450513          	addi	a0,a0,20 # 800181e0 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	a16080e7          	jalr	-1514(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031dc:	0001d497          	auipc	s1,0x1d
    800031e0:	2bc4b483          	ld	s1,700(s1) # 80020498 <bcache+0x82b8>
    800031e4:	0001d797          	auipc	a5,0x1d
    800031e8:	26478793          	addi	a5,a5,612 # 80020448 <bcache+0x8268>
    800031ec:	02f48f63          	beq	s1,a5,8000322a <bread+0x70>
    800031f0:	873e                	mv	a4,a5
    800031f2:	a021                	j	800031fa <bread+0x40>
    800031f4:	68a4                	ld	s1,80(s1)
    800031f6:	02e48a63          	beq	s1,a4,8000322a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031fa:	449c                	lw	a5,8(s1)
    800031fc:	ff379ce3          	bne	a5,s3,800031f4 <bread+0x3a>
    80003200:	44dc                	lw	a5,12(s1)
    80003202:	ff2799e3          	bne	a5,s2,800031f4 <bread+0x3a>
      b->refcnt++;
    80003206:	40bc                	lw	a5,64(s1)
    80003208:	2785                	addiw	a5,a5,1
    8000320a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000320c:	00015517          	auipc	a0,0x15
    80003210:	fd450513          	addi	a0,a0,-44 # 800181e0 <bcache>
    80003214:	ffffe097          	auipc	ra,0xffffe
    80003218:	a8a080e7          	jalr	-1398(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000321c:	01048513          	addi	a0,s1,16
    80003220:	00001097          	auipc	ra,0x1
    80003224:	46e080e7          	jalr	1134(ra) # 8000468e <acquiresleep>
      return b;
    80003228:	a8b9                	j	80003286 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000322a:	0001d497          	auipc	s1,0x1d
    8000322e:	2664b483          	ld	s1,614(s1) # 80020490 <bcache+0x82b0>
    80003232:	0001d797          	auipc	a5,0x1d
    80003236:	21678793          	addi	a5,a5,534 # 80020448 <bcache+0x8268>
    8000323a:	00f48863          	beq	s1,a5,8000324a <bread+0x90>
    8000323e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003240:	40bc                	lw	a5,64(s1)
    80003242:	cf81                	beqz	a5,8000325a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003244:	64a4                	ld	s1,72(s1)
    80003246:	fee49de3          	bne	s1,a4,80003240 <bread+0x86>
  panic("bget: no buffers");
    8000324a:	00005517          	auipc	a0,0x5
    8000324e:	50650513          	addi	a0,a0,1286 # 80008750 <syscall_argc+0x78>
    80003252:	ffffd097          	auipc	ra,0xffffd
    80003256:	2f2080e7          	jalr	754(ra) # 80000544 <panic>
      b->dev = dev;
    8000325a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000325e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003262:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003266:	4785                	li	a5,1
    80003268:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000326a:	00015517          	auipc	a0,0x15
    8000326e:	f7650513          	addi	a0,a0,-138 # 800181e0 <bcache>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	a2c080e7          	jalr	-1492(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000327a:	01048513          	addi	a0,s1,16
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	410080e7          	jalr	1040(ra) # 8000468e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003286:	409c                	lw	a5,0(s1)
    80003288:	cb89                	beqz	a5,8000329a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000328a:	8526                	mv	a0,s1
    8000328c:	70a2                	ld	ra,40(sp)
    8000328e:	7402                	ld	s0,32(sp)
    80003290:	64e2                	ld	s1,24(sp)
    80003292:	6942                	ld	s2,16(sp)
    80003294:	69a2                	ld	s3,8(sp)
    80003296:	6145                	addi	sp,sp,48
    80003298:	8082                	ret
    virtio_disk_rw(b, 0);
    8000329a:	4581                	li	a1,0
    8000329c:	8526                	mv	a0,s1
    8000329e:	00003097          	auipc	ra,0x3
    800032a2:	fca080e7          	jalr	-54(ra) # 80006268 <virtio_disk_rw>
    b->valid = 1;
    800032a6:	4785                	li	a5,1
    800032a8:	c09c                	sw	a5,0(s1)
  return b;
    800032aa:	b7c5                	j	8000328a <bread+0xd0>

00000000800032ac <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032ac:	1101                	addi	sp,sp,-32
    800032ae:	ec06                	sd	ra,24(sp)
    800032b0:	e822                	sd	s0,16(sp)
    800032b2:	e426                	sd	s1,8(sp)
    800032b4:	1000                	addi	s0,sp,32
    800032b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b8:	0541                	addi	a0,a0,16
    800032ba:	00001097          	auipc	ra,0x1
    800032be:	46e080e7          	jalr	1134(ra) # 80004728 <holdingsleep>
    800032c2:	cd01                	beqz	a0,800032da <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032c4:	4585                	li	a1,1
    800032c6:	8526                	mv	a0,s1
    800032c8:	00003097          	auipc	ra,0x3
    800032cc:	fa0080e7          	jalr	-96(ra) # 80006268 <virtio_disk_rw>
}
    800032d0:	60e2                	ld	ra,24(sp)
    800032d2:	6442                	ld	s0,16(sp)
    800032d4:	64a2                	ld	s1,8(sp)
    800032d6:	6105                	addi	sp,sp,32
    800032d8:	8082                	ret
    panic("bwrite");
    800032da:	00005517          	auipc	a0,0x5
    800032de:	48e50513          	addi	a0,a0,1166 # 80008768 <syscall_argc+0x90>
    800032e2:	ffffd097          	auipc	ra,0xffffd
    800032e6:	262080e7          	jalr	610(ra) # 80000544 <panic>

00000000800032ea <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032ea:	1101                	addi	sp,sp,-32
    800032ec:	ec06                	sd	ra,24(sp)
    800032ee:	e822                	sd	s0,16(sp)
    800032f0:	e426                	sd	s1,8(sp)
    800032f2:	e04a                	sd	s2,0(sp)
    800032f4:	1000                	addi	s0,sp,32
    800032f6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032f8:	01050913          	addi	s2,a0,16
    800032fc:	854a                	mv	a0,s2
    800032fe:	00001097          	auipc	ra,0x1
    80003302:	42a080e7          	jalr	1066(ra) # 80004728 <holdingsleep>
    80003306:	c92d                	beqz	a0,80003378 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003308:	854a                	mv	a0,s2
    8000330a:	00001097          	auipc	ra,0x1
    8000330e:	3da080e7          	jalr	986(ra) # 800046e4 <releasesleep>

  acquire(&bcache.lock);
    80003312:	00015517          	auipc	a0,0x15
    80003316:	ece50513          	addi	a0,a0,-306 # 800181e0 <bcache>
    8000331a:	ffffe097          	auipc	ra,0xffffe
    8000331e:	8d0080e7          	jalr	-1840(ra) # 80000bea <acquire>
  b->refcnt--;
    80003322:	40bc                	lw	a5,64(s1)
    80003324:	37fd                	addiw	a5,a5,-1
    80003326:	0007871b          	sext.w	a4,a5
    8000332a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000332c:	eb05                	bnez	a4,8000335c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000332e:	68bc                	ld	a5,80(s1)
    80003330:	64b8                	ld	a4,72(s1)
    80003332:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003334:	64bc                	ld	a5,72(s1)
    80003336:	68b8                	ld	a4,80(s1)
    80003338:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000333a:	0001d797          	auipc	a5,0x1d
    8000333e:	ea678793          	addi	a5,a5,-346 # 800201e0 <bcache+0x8000>
    80003342:	2b87b703          	ld	a4,696(a5)
    80003346:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003348:	0001d717          	auipc	a4,0x1d
    8000334c:	10070713          	addi	a4,a4,256 # 80020448 <bcache+0x8268>
    80003350:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003352:	2b87b703          	ld	a4,696(a5)
    80003356:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003358:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000335c:	00015517          	auipc	a0,0x15
    80003360:	e8450513          	addi	a0,a0,-380 # 800181e0 <bcache>
    80003364:	ffffe097          	auipc	ra,0xffffe
    80003368:	93a080e7          	jalr	-1734(ra) # 80000c9e <release>
}
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	64a2                	ld	s1,8(sp)
    80003372:	6902                	ld	s2,0(sp)
    80003374:	6105                	addi	sp,sp,32
    80003376:	8082                	ret
    panic("brelse");
    80003378:	00005517          	auipc	a0,0x5
    8000337c:	3f850513          	addi	a0,a0,1016 # 80008770 <syscall_argc+0x98>
    80003380:	ffffd097          	auipc	ra,0xffffd
    80003384:	1c4080e7          	jalr	452(ra) # 80000544 <panic>

0000000080003388 <bpin>:

void
bpin(struct buf *b) {
    80003388:	1101                	addi	sp,sp,-32
    8000338a:	ec06                	sd	ra,24(sp)
    8000338c:	e822                	sd	s0,16(sp)
    8000338e:	e426                	sd	s1,8(sp)
    80003390:	1000                	addi	s0,sp,32
    80003392:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003394:	00015517          	auipc	a0,0x15
    80003398:	e4c50513          	addi	a0,a0,-436 # 800181e0 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	84e080e7          	jalr	-1970(ra) # 80000bea <acquire>
  b->refcnt++;
    800033a4:	40bc                	lw	a5,64(s1)
    800033a6:	2785                	addiw	a5,a5,1
    800033a8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033aa:	00015517          	auipc	a0,0x15
    800033ae:	e3650513          	addi	a0,a0,-458 # 800181e0 <bcache>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	8ec080e7          	jalr	-1812(ra) # 80000c9e <release>
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	64a2                	ld	s1,8(sp)
    800033c0:	6105                	addi	sp,sp,32
    800033c2:	8082                	ret

00000000800033c4 <bunpin>:

void
bunpin(struct buf *b) {
    800033c4:	1101                	addi	sp,sp,-32
    800033c6:	ec06                	sd	ra,24(sp)
    800033c8:	e822                	sd	s0,16(sp)
    800033ca:	e426                	sd	s1,8(sp)
    800033cc:	1000                	addi	s0,sp,32
    800033ce:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033d0:	00015517          	auipc	a0,0x15
    800033d4:	e1050513          	addi	a0,a0,-496 # 800181e0 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	812080e7          	jalr	-2030(ra) # 80000bea <acquire>
  b->refcnt--;
    800033e0:	40bc                	lw	a5,64(s1)
    800033e2:	37fd                	addiw	a5,a5,-1
    800033e4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033e6:	00015517          	auipc	a0,0x15
    800033ea:	dfa50513          	addi	a0,a0,-518 # 800181e0 <bcache>
    800033ee:	ffffe097          	auipc	ra,0xffffe
    800033f2:	8b0080e7          	jalr	-1872(ra) # 80000c9e <release>
}
    800033f6:	60e2                	ld	ra,24(sp)
    800033f8:	6442                	ld	s0,16(sp)
    800033fa:	64a2                	ld	s1,8(sp)
    800033fc:	6105                	addi	sp,sp,32
    800033fe:	8082                	ret

0000000080003400 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003400:	1101                	addi	sp,sp,-32
    80003402:	ec06                	sd	ra,24(sp)
    80003404:	e822                	sd	s0,16(sp)
    80003406:	e426                	sd	s1,8(sp)
    80003408:	e04a                	sd	s2,0(sp)
    8000340a:	1000                	addi	s0,sp,32
    8000340c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000340e:	00d5d59b          	srliw	a1,a1,0xd
    80003412:	0001d797          	auipc	a5,0x1d
    80003416:	4aa7a783          	lw	a5,1194(a5) # 800208bc <sb+0x1c>
    8000341a:	9dbd                	addw	a1,a1,a5
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	d9e080e7          	jalr	-610(ra) # 800031ba <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003424:	0074f713          	andi	a4,s1,7
    80003428:	4785                	li	a5,1
    8000342a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000342e:	14ce                	slli	s1,s1,0x33
    80003430:	90d9                	srli	s1,s1,0x36
    80003432:	00950733          	add	a4,a0,s1
    80003436:	05874703          	lbu	a4,88(a4)
    8000343a:	00e7f6b3          	and	a3,a5,a4
    8000343e:	c69d                	beqz	a3,8000346c <bfree+0x6c>
    80003440:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003442:	94aa                	add	s1,s1,a0
    80003444:	fff7c793          	not	a5,a5
    80003448:	8ff9                	and	a5,a5,a4
    8000344a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000344e:	00001097          	auipc	ra,0x1
    80003452:	120080e7          	jalr	288(ra) # 8000456e <log_write>
  brelse(bp);
    80003456:	854a                	mv	a0,s2
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	e92080e7          	jalr	-366(ra) # 800032ea <brelse>
}
    80003460:	60e2                	ld	ra,24(sp)
    80003462:	6442                	ld	s0,16(sp)
    80003464:	64a2                	ld	s1,8(sp)
    80003466:	6902                	ld	s2,0(sp)
    80003468:	6105                	addi	sp,sp,32
    8000346a:	8082                	ret
    panic("freeing free block");
    8000346c:	00005517          	auipc	a0,0x5
    80003470:	30c50513          	addi	a0,a0,780 # 80008778 <syscall_argc+0xa0>
    80003474:	ffffd097          	auipc	ra,0xffffd
    80003478:	0d0080e7          	jalr	208(ra) # 80000544 <panic>

000000008000347c <balloc>:
{
    8000347c:	711d                	addi	sp,sp,-96
    8000347e:	ec86                	sd	ra,88(sp)
    80003480:	e8a2                	sd	s0,80(sp)
    80003482:	e4a6                	sd	s1,72(sp)
    80003484:	e0ca                	sd	s2,64(sp)
    80003486:	fc4e                	sd	s3,56(sp)
    80003488:	f852                	sd	s4,48(sp)
    8000348a:	f456                	sd	s5,40(sp)
    8000348c:	f05a                	sd	s6,32(sp)
    8000348e:	ec5e                	sd	s7,24(sp)
    80003490:	e862                	sd	s8,16(sp)
    80003492:	e466                	sd	s9,8(sp)
    80003494:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003496:	0001d797          	auipc	a5,0x1d
    8000349a:	40e7a783          	lw	a5,1038(a5) # 800208a4 <sb+0x4>
    8000349e:	10078163          	beqz	a5,800035a0 <balloc+0x124>
    800034a2:	8baa                	mv	s7,a0
    800034a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034a6:	0001db17          	auipc	s6,0x1d
    800034aa:	3fab0b13          	addi	s6,s6,1018 # 800208a0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034b4:	6c89                	lui	s9,0x2
    800034b6:	a061                	j	8000353e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034b8:	974a                	add	a4,a4,s2
    800034ba:	8fd5                	or	a5,a5,a3
    800034bc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034c0:	854a                	mv	a0,s2
    800034c2:	00001097          	auipc	ra,0x1
    800034c6:	0ac080e7          	jalr	172(ra) # 8000456e <log_write>
        brelse(bp);
    800034ca:	854a                	mv	a0,s2
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	e1e080e7          	jalr	-482(ra) # 800032ea <brelse>
  bp = bread(dev, bno);
    800034d4:	85a6                	mv	a1,s1
    800034d6:	855e                	mv	a0,s7
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	ce2080e7          	jalr	-798(ra) # 800031ba <bread>
    800034e0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034e2:	40000613          	li	a2,1024
    800034e6:	4581                	li	a1,0
    800034e8:	05850513          	addi	a0,a0,88
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	7fa080e7          	jalr	2042(ra) # 80000ce6 <memset>
  log_write(bp);
    800034f4:	854a                	mv	a0,s2
    800034f6:	00001097          	auipc	ra,0x1
    800034fa:	078080e7          	jalr	120(ra) # 8000456e <log_write>
  brelse(bp);
    800034fe:	854a                	mv	a0,s2
    80003500:	00000097          	auipc	ra,0x0
    80003504:	dea080e7          	jalr	-534(ra) # 800032ea <brelse>
}
    80003508:	8526                	mv	a0,s1
    8000350a:	60e6                	ld	ra,88(sp)
    8000350c:	6446                	ld	s0,80(sp)
    8000350e:	64a6                	ld	s1,72(sp)
    80003510:	6906                	ld	s2,64(sp)
    80003512:	79e2                	ld	s3,56(sp)
    80003514:	7a42                	ld	s4,48(sp)
    80003516:	7aa2                	ld	s5,40(sp)
    80003518:	7b02                	ld	s6,32(sp)
    8000351a:	6be2                	ld	s7,24(sp)
    8000351c:	6c42                	ld	s8,16(sp)
    8000351e:	6ca2                	ld	s9,8(sp)
    80003520:	6125                	addi	sp,sp,96
    80003522:	8082                	ret
    brelse(bp);
    80003524:	854a                	mv	a0,s2
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	dc4080e7          	jalr	-572(ra) # 800032ea <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000352e:	015c87bb          	addw	a5,s9,s5
    80003532:	00078a9b          	sext.w	s5,a5
    80003536:	004b2703          	lw	a4,4(s6)
    8000353a:	06eaf363          	bgeu	s5,a4,800035a0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000353e:	41fad79b          	sraiw	a5,s5,0x1f
    80003542:	0137d79b          	srliw	a5,a5,0x13
    80003546:	015787bb          	addw	a5,a5,s5
    8000354a:	40d7d79b          	sraiw	a5,a5,0xd
    8000354e:	01cb2583          	lw	a1,28(s6)
    80003552:	9dbd                	addw	a1,a1,a5
    80003554:	855e                	mv	a0,s7
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	c64080e7          	jalr	-924(ra) # 800031ba <bread>
    8000355e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003560:	004b2503          	lw	a0,4(s6)
    80003564:	000a849b          	sext.w	s1,s5
    80003568:	8662                	mv	a2,s8
    8000356a:	faa4fde3          	bgeu	s1,a0,80003524 <balloc+0xa8>
      m = 1 << (bi % 8);
    8000356e:	41f6579b          	sraiw	a5,a2,0x1f
    80003572:	01d7d69b          	srliw	a3,a5,0x1d
    80003576:	00c6873b          	addw	a4,a3,a2
    8000357a:	00777793          	andi	a5,a4,7
    8000357e:	9f95                	subw	a5,a5,a3
    80003580:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003584:	4037571b          	sraiw	a4,a4,0x3
    80003588:	00e906b3          	add	a3,s2,a4
    8000358c:	0586c683          	lbu	a3,88(a3)
    80003590:	00d7f5b3          	and	a1,a5,a3
    80003594:	d195                	beqz	a1,800034b8 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003596:	2605                	addiw	a2,a2,1
    80003598:	2485                	addiw	s1,s1,1
    8000359a:	fd4618e3          	bne	a2,s4,8000356a <balloc+0xee>
    8000359e:	b759                	j	80003524 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	1f050513          	addi	a0,a0,496 # 80008790 <syscall_argc+0xb8>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	fe6080e7          	jalr	-26(ra) # 8000058e <printf>
  return 0;
    800035b0:	4481                	li	s1,0
    800035b2:	bf99                	j	80003508 <balloc+0x8c>

00000000800035b4 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035b4:	7179                	addi	sp,sp,-48
    800035b6:	f406                	sd	ra,40(sp)
    800035b8:	f022                	sd	s0,32(sp)
    800035ba:	ec26                	sd	s1,24(sp)
    800035bc:	e84a                	sd	s2,16(sp)
    800035be:	e44e                	sd	s3,8(sp)
    800035c0:	e052                	sd	s4,0(sp)
    800035c2:	1800                	addi	s0,sp,48
    800035c4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035c6:	47ad                	li	a5,11
    800035c8:	02b7e763          	bltu	a5,a1,800035f6 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800035cc:	02059493          	slli	s1,a1,0x20
    800035d0:	9081                	srli	s1,s1,0x20
    800035d2:	048a                	slli	s1,s1,0x2
    800035d4:	94aa                	add	s1,s1,a0
    800035d6:	0504a903          	lw	s2,80(s1)
    800035da:	06091e63          	bnez	s2,80003656 <bmap+0xa2>
      addr = balloc(ip->dev);
    800035de:	4108                	lw	a0,0(a0)
    800035e0:	00000097          	auipc	ra,0x0
    800035e4:	e9c080e7          	jalr	-356(ra) # 8000347c <balloc>
    800035e8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035ec:	06090563          	beqz	s2,80003656 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800035f0:	0524a823          	sw	s2,80(s1)
    800035f4:	a08d                	j	80003656 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800035f6:	ff45849b          	addiw	s1,a1,-12
    800035fa:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035fe:	0ff00793          	li	a5,255
    80003602:	08e7e563          	bltu	a5,a4,8000368c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003606:	08052903          	lw	s2,128(a0)
    8000360a:	00091d63          	bnez	s2,80003624 <bmap+0x70>
      addr = balloc(ip->dev);
    8000360e:	4108                	lw	a0,0(a0)
    80003610:	00000097          	auipc	ra,0x0
    80003614:	e6c080e7          	jalr	-404(ra) # 8000347c <balloc>
    80003618:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000361c:	02090d63          	beqz	s2,80003656 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003620:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003624:	85ca                	mv	a1,s2
    80003626:	0009a503          	lw	a0,0(s3)
    8000362a:	00000097          	auipc	ra,0x0
    8000362e:	b90080e7          	jalr	-1136(ra) # 800031ba <bread>
    80003632:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003634:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003638:	02049593          	slli	a1,s1,0x20
    8000363c:	9181                	srli	a1,a1,0x20
    8000363e:	058a                	slli	a1,a1,0x2
    80003640:	00b784b3          	add	s1,a5,a1
    80003644:	0004a903          	lw	s2,0(s1)
    80003648:	02090063          	beqz	s2,80003668 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000364c:	8552                	mv	a0,s4
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	c9c080e7          	jalr	-868(ra) # 800032ea <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003656:	854a                	mv	a0,s2
    80003658:	70a2                	ld	ra,40(sp)
    8000365a:	7402                	ld	s0,32(sp)
    8000365c:	64e2                	ld	s1,24(sp)
    8000365e:	6942                	ld	s2,16(sp)
    80003660:	69a2                	ld	s3,8(sp)
    80003662:	6a02                	ld	s4,0(sp)
    80003664:	6145                	addi	sp,sp,48
    80003666:	8082                	ret
      addr = balloc(ip->dev);
    80003668:	0009a503          	lw	a0,0(s3)
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	e10080e7          	jalr	-496(ra) # 8000347c <balloc>
    80003674:	0005091b          	sext.w	s2,a0
      if(addr){
    80003678:	fc090ae3          	beqz	s2,8000364c <bmap+0x98>
        a[bn] = addr;
    8000367c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003680:	8552                	mv	a0,s4
    80003682:	00001097          	auipc	ra,0x1
    80003686:	eec080e7          	jalr	-276(ra) # 8000456e <log_write>
    8000368a:	b7c9                	j	8000364c <bmap+0x98>
  panic("bmap: out of range");
    8000368c:	00005517          	auipc	a0,0x5
    80003690:	11c50513          	addi	a0,a0,284 # 800087a8 <syscall_argc+0xd0>
    80003694:	ffffd097          	auipc	ra,0xffffd
    80003698:	eb0080e7          	jalr	-336(ra) # 80000544 <panic>

000000008000369c <iget>:
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	e052                	sd	s4,0(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	89aa                	mv	s3,a0
    800036ae:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036b0:	0001d517          	auipc	a0,0x1d
    800036b4:	21050513          	addi	a0,a0,528 # 800208c0 <itable>
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	532080e7          	jalr	1330(ra) # 80000bea <acquire>
  empty = 0;
    800036c0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036c2:	0001d497          	auipc	s1,0x1d
    800036c6:	21648493          	addi	s1,s1,534 # 800208d8 <itable+0x18>
    800036ca:	0001f697          	auipc	a3,0x1f
    800036ce:	c9e68693          	addi	a3,a3,-866 # 80022368 <log>
    800036d2:	a039                	j	800036e0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036d4:	02090b63          	beqz	s2,8000370a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036d8:	08848493          	addi	s1,s1,136
    800036dc:	02d48a63          	beq	s1,a3,80003710 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036e0:	449c                	lw	a5,8(s1)
    800036e2:	fef059e3          	blez	a5,800036d4 <iget+0x38>
    800036e6:	4098                	lw	a4,0(s1)
    800036e8:	ff3716e3          	bne	a4,s3,800036d4 <iget+0x38>
    800036ec:	40d8                	lw	a4,4(s1)
    800036ee:	ff4713e3          	bne	a4,s4,800036d4 <iget+0x38>
      ip->ref++;
    800036f2:	2785                	addiw	a5,a5,1
    800036f4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036f6:	0001d517          	auipc	a0,0x1d
    800036fa:	1ca50513          	addi	a0,a0,458 # 800208c0 <itable>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	5a0080e7          	jalr	1440(ra) # 80000c9e <release>
      return ip;
    80003706:	8926                	mv	s2,s1
    80003708:	a03d                	j	80003736 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000370a:	f7f9                	bnez	a5,800036d8 <iget+0x3c>
    8000370c:	8926                	mv	s2,s1
    8000370e:	b7e9                	j	800036d8 <iget+0x3c>
  if(empty == 0)
    80003710:	02090c63          	beqz	s2,80003748 <iget+0xac>
  ip->dev = dev;
    80003714:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003718:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000371c:	4785                	li	a5,1
    8000371e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003722:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003726:	0001d517          	auipc	a0,0x1d
    8000372a:	19a50513          	addi	a0,a0,410 # 800208c0 <itable>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	570080e7          	jalr	1392(ra) # 80000c9e <release>
}
    80003736:	854a                	mv	a0,s2
    80003738:	70a2                	ld	ra,40(sp)
    8000373a:	7402                	ld	s0,32(sp)
    8000373c:	64e2                	ld	s1,24(sp)
    8000373e:	6942                	ld	s2,16(sp)
    80003740:	69a2                	ld	s3,8(sp)
    80003742:	6a02                	ld	s4,0(sp)
    80003744:	6145                	addi	sp,sp,48
    80003746:	8082                	ret
    panic("iget: no inodes");
    80003748:	00005517          	auipc	a0,0x5
    8000374c:	07850513          	addi	a0,a0,120 # 800087c0 <syscall_argc+0xe8>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	df4080e7          	jalr	-524(ra) # 80000544 <panic>

0000000080003758 <fsinit>:
fsinit(int dev) {
    80003758:	7179                	addi	sp,sp,-48
    8000375a:	f406                	sd	ra,40(sp)
    8000375c:	f022                	sd	s0,32(sp)
    8000375e:	ec26                	sd	s1,24(sp)
    80003760:	e84a                	sd	s2,16(sp)
    80003762:	e44e                	sd	s3,8(sp)
    80003764:	1800                	addi	s0,sp,48
    80003766:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003768:	4585                	li	a1,1
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	a50080e7          	jalr	-1456(ra) # 800031ba <bread>
    80003772:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003774:	0001d997          	auipc	s3,0x1d
    80003778:	12c98993          	addi	s3,s3,300 # 800208a0 <sb>
    8000377c:	02000613          	li	a2,32
    80003780:	05850593          	addi	a1,a0,88
    80003784:	854e                	mv	a0,s3
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	5c0080e7          	jalr	1472(ra) # 80000d46 <memmove>
  brelse(bp);
    8000378e:	8526                	mv	a0,s1
    80003790:	00000097          	auipc	ra,0x0
    80003794:	b5a080e7          	jalr	-1190(ra) # 800032ea <brelse>
  if(sb.magic != FSMAGIC)
    80003798:	0009a703          	lw	a4,0(s3)
    8000379c:	102037b7          	lui	a5,0x10203
    800037a0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037a4:	02f71263          	bne	a4,a5,800037c8 <fsinit+0x70>
  initlog(dev, &sb);
    800037a8:	0001d597          	auipc	a1,0x1d
    800037ac:	0f858593          	addi	a1,a1,248 # 800208a0 <sb>
    800037b0:	854a                	mv	a0,s2
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	b40080e7          	jalr	-1216(ra) # 800042f2 <initlog>
}
    800037ba:	70a2                	ld	ra,40(sp)
    800037bc:	7402                	ld	s0,32(sp)
    800037be:	64e2                	ld	s1,24(sp)
    800037c0:	6942                	ld	s2,16(sp)
    800037c2:	69a2                	ld	s3,8(sp)
    800037c4:	6145                	addi	sp,sp,48
    800037c6:	8082                	ret
    panic("invalid file system");
    800037c8:	00005517          	auipc	a0,0x5
    800037cc:	00850513          	addi	a0,a0,8 # 800087d0 <syscall_argc+0xf8>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	d74080e7          	jalr	-652(ra) # 80000544 <panic>

00000000800037d8 <iinit>:
{
    800037d8:	7179                	addi	sp,sp,-48
    800037da:	f406                	sd	ra,40(sp)
    800037dc:	f022                	sd	s0,32(sp)
    800037de:	ec26                	sd	s1,24(sp)
    800037e0:	e84a                	sd	s2,16(sp)
    800037e2:	e44e                	sd	s3,8(sp)
    800037e4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037e6:	00005597          	auipc	a1,0x5
    800037ea:	00258593          	addi	a1,a1,2 # 800087e8 <syscall_argc+0x110>
    800037ee:	0001d517          	auipc	a0,0x1d
    800037f2:	0d250513          	addi	a0,a0,210 # 800208c0 <itable>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	364080e7          	jalr	868(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800037fe:	0001d497          	auipc	s1,0x1d
    80003802:	0ea48493          	addi	s1,s1,234 # 800208e8 <itable+0x28>
    80003806:	0001f997          	auipc	s3,0x1f
    8000380a:	b7298993          	addi	s3,s3,-1166 # 80022378 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000380e:	00005917          	auipc	s2,0x5
    80003812:	fe290913          	addi	s2,s2,-30 # 800087f0 <syscall_argc+0x118>
    80003816:	85ca                	mv	a1,s2
    80003818:	8526                	mv	a0,s1
    8000381a:	00001097          	auipc	ra,0x1
    8000381e:	e3a080e7          	jalr	-454(ra) # 80004654 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003822:	08848493          	addi	s1,s1,136
    80003826:	ff3498e3          	bne	s1,s3,80003816 <iinit+0x3e>
}
    8000382a:	70a2                	ld	ra,40(sp)
    8000382c:	7402                	ld	s0,32(sp)
    8000382e:	64e2                	ld	s1,24(sp)
    80003830:	6942                	ld	s2,16(sp)
    80003832:	69a2                	ld	s3,8(sp)
    80003834:	6145                	addi	sp,sp,48
    80003836:	8082                	ret

0000000080003838 <ialloc>:
{
    80003838:	715d                	addi	sp,sp,-80
    8000383a:	e486                	sd	ra,72(sp)
    8000383c:	e0a2                	sd	s0,64(sp)
    8000383e:	fc26                	sd	s1,56(sp)
    80003840:	f84a                	sd	s2,48(sp)
    80003842:	f44e                	sd	s3,40(sp)
    80003844:	f052                	sd	s4,32(sp)
    80003846:	ec56                	sd	s5,24(sp)
    80003848:	e85a                	sd	s6,16(sp)
    8000384a:	e45e                	sd	s7,8(sp)
    8000384c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000384e:	0001d717          	auipc	a4,0x1d
    80003852:	05e72703          	lw	a4,94(a4) # 800208ac <sb+0xc>
    80003856:	4785                	li	a5,1
    80003858:	04e7fa63          	bgeu	a5,a4,800038ac <ialloc+0x74>
    8000385c:	8aaa                	mv	s5,a0
    8000385e:	8bae                	mv	s7,a1
    80003860:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003862:	0001da17          	auipc	s4,0x1d
    80003866:	03ea0a13          	addi	s4,s4,62 # 800208a0 <sb>
    8000386a:	00048b1b          	sext.w	s6,s1
    8000386e:	0044d593          	srli	a1,s1,0x4
    80003872:	018a2783          	lw	a5,24(s4)
    80003876:	9dbd                	addw	a1,a1,a5
    80003878:	8556                	mv	a0,s5
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	940080e7          	jalr	-1728(ra) # 800031ba <bread>
    80003882:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003884:	05850993          	addi	s3,a0,88
    80003888:	00f4f793          	andi	a5,s1,15
    8000388c:	079a                	slli	a5,a5,0x6
    8000388e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003890:	00099783          	lh	a5,0(s3)
    80003894:	c3a1                	beqz	a5,800038d4 <ialloc+0x9c>
    brelse(bp);
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	a54080e7          	jalr	-1452(ra) # 800032ea <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000389e:	0485                	addi	s1,s1,1
    800038a0:	00ca2703          	lw	a4,12(s4)
    800038a4:	0004879b          	sext.w	a5,s1
    800038a8:	fce7e1e3          	bltu	a5,a4,8000386a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	f4c50513          	addi	a0,a0,-180 # 800087f8 <syscall_argc+0x120>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	cda080e7          	jalr	-806(ra) # 8000058e <printf>
  return 0;
    800038bc:	4501                	li	a0,0
}
    800038be:	60a6                	ld	ra,72(sp)
    800038c0:	6406                	ld	s0,64(sp)
    800038c2:	74e2                	ld	s1,56(sp)
    800038c4:	7942                	ld	s2,48(sp)
    800038c6:	79a2                	ld	s3,40(sp)
    800038c8:	7a02                	ld	s4,32(sp)
    800038ca:	6ae2                	ld	s5,24(sp)
    800038cc:	6b42                	ld	s6,16(sp)
    800038ce:	6ba2                	ld	s7,8(sp)
    800038d0:	6161                	addi	sp,sp,80
    800038d2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038d4:	04000613          	li	a2,64
    800038d8:	4581                	li	a1,0
    800038da:	854e                	mv	a0,s3
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	40a080e7          	jalr	1034(ra) # 80000ce6 <memset>
      dip->type = type;
    800038e4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038e8:	854a                	mv	a0,s2
    800038ea:	00001097          	auipc	ra,0x1
    800038ee:	c84080e7          	jalr	-892(ra) # 8000456e <log_write>
      brelse(bp);
    800038f2:	854a                	mv	a0,s2
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	9f6080e7          	jalr	-1546(ra) # 800032ea <brelse>
      return iget(dev, inum);
    800038fc:	85da                	mv	a1,s6
    800038fe:	8556                	mv	a0,s5
    80003900:	00000097          	auipc	ra,0x0
    80003904:	d9c080e7          	jalr	-612(ra) # 8000369c <iget>
    80003908:	bf5d                	j	800038be <ialloc+0x86>

000000008000390a <iupdate>:
{
    8000390a:	1101                	addi	sp,sp,-32
    8000390c:	ec06                	sd	ra,24(sp)
    8000390e:	e822                	sd	s0,16(sp)
    80003910:	e426                	sd	s1,8(sp)
    80003912:	e04a                	sd	s2,0(sp)
    80003914:	1000                	addi	s0,sp,32
    80003916:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003918:	415c                	lw	a5,4(a0)
    8000391a:	0047d79b          	srliw	a5,a5,0x4
    8000391e:	0001d597          	auipc	a1,0x1d
    80003922:	f9a5a583          	lw	a1,-102(a1) # 800208b8 <sb+0x18>
    80003926:	9dbd                	addw	a1,a1,a5
    80003928:	4108                	lw	a0,0(a0)
    8000392a:	00000097          	auipc	ra,0x0
    8000392e:	890080e7          	jalr	-1904(ra) # 800031ba <bread>
    80003932:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003934:	05850793          	addi	a5,a0,88
    80003938:	40c8                	lw	a0,4(s1)
    8000393a:	893d                	andi	a0,a0,15
    8000393c:	051a                	slli	a0,a0,0x6
    8000393e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003940:	04449703          	lh	a4,68(s1)
    80003944:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003948:	04649703          	lh	a4,70(s1)
    8000394c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003950:	04849703          	lh	a4,72(s1)
    80003954:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003958:	04a49703          	lh	a4,74(s1)
    8000395c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003960:	44f8                	lw	a4,76(s1)
    80003962:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003964:	03400613          	li	a2,52
    80003968:	05048593          	addi	a1,s1,80
    8000396c:	0531                	addi	a0,a0,12
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	3d8080e7          	jalr	984(ra) # 80000d46 <memmove>
  log_write(bp);
    80003976:	854a                	mv	a0,s2
    80003978:	00001097          	auipc	ra,0x1
    8000397c:	bf6080e7          	jalr	-1034(ra) # 8000456e <log_write>
  brelse(bp);
    80003980:	854a                	mv	a0,s2
    80003982:	00000097          	auipc	ra,0x0
    80003986:	968080e7          	jalr	-1688(ra) # 800032ea <brelse>
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6902                	ld	s2,0(sp)
    80003992:	6105                	addi	sp,sp,32
    80003994:	8082                	ret

0000000080003996 <idup>:
{
    80003996:	1101                	addi	sp,sp,-32
    80003998:	ec06                	sd	ra,24(sp)
    8000399a:	e822                	sd	s0,16(sp)
    8000399c:	e426                	sd	s1,8(sp)
    8000399e:	1000                	addi	s0,sp,32
    800039a0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039a2:	0001d517          	auipc	a0,0x1d
    800039a6:	f1e50513          	addi	a0,a0,-226 # 800208c0 <itable>
    800039aa:	ffffd097          	auipc	ra,0xffffd
    800039ae:	240080e7          	jalr	576(ra) # 80000bea <acquire>
  ip->ref++;
    800039b2:	449c                	lw	a5,8(s1)
    800039b4:	2785                	addiw	a5,a5,1
    800039b6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039b8:	0001d517          	auipc	a0,0x1d
    800039bc:	f0850513          	addi	a0,a0,-248 # 800208c0 <itable>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	2de080e7          	jalr	734(ra) # 80000c9e <release>
}
    800039c8:	8526                	mv	a0,s1
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6105                	addi	sp,sp,32
    800039d2:	8082                	ret

00000000800039d4 <ilock>:
{
    800039d4:	1101                	addi	sp,sp,-32
    800039d6:	ec06                	sd	ra,24(sp)
    800039d8:	e822                	sd	s0,16(sp)
    800039da:	e426                	sd	s1,8(sp)
    800039dc:	e04a                	sd	s2,0(sp)
    800039de:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039e0:	c115                	beqz	a0,80003a04 <ilock+0x30>
    800039e2:	84aa                	mv	s1,a0
    800039e4:	451c                	lw	a5,8(a0)
    800039e6:	00f05f63          	blez	a5,80003a04 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039ea:	0541                	addi	a0,a0,16
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	ca2080e7          	jalr	-862(ra) # 8000468e <acquiresleep>
  if(ip->valid == 0){
    800039f4:	40bc                	lw	a5,64(s1)
    800039f6:	cf99                	beqz	a5,80003a14 <ilock+0x40>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6902                	ld	s2,0(sp)
    80003a00:	6105                	addi	sp,sp,32
    80003a02:	8082                	ret
    panic("ilock");
    80003a04:	00005517          	auipc	a0,0x5
    80003a08:	e0c50513          	addi	a0,a0,-500 # 80008810 <syscall_argc+0x138>
    80003a0c:	ffffd097          	auipc	ra,0xffffd
    80003a10:	b38080e7          	jalr	-1224(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a14:	40dc                	lw	a5,4(s1)
    80003a16:	0047d79b          	srliw	a5,a5,0x4
    80003a1a:	0001d597          	auipc	a1,0x1d
    80003a1e:	e9e5a583          	lw	a1,-354(a1) # 800208b8 <sb+0x18>
    80003a22:	9dbd                	addw	a1,a1,a5
    80003a24:	4088                	lw	a0,0(s1)
    80003a26:	fffff097          	auipc	ra,0xfffff
    80003a2a:	794080e7          	jalr	1940(ra) # 800031ba <bread>
    80003a2e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a30:	05850593          	addi	a1,a0,88
    80003a34:	40dc                	lw	a5,4(s1)
    80003a36:	8bbd                	andi	a5,a5,15
    80003a38:	079a                	slli	a5,a5,0x6
    80003a3a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a3c:	00059783          	lh	a5,0(a1)
    80003a40:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a44:	00259783          	lh	a5,2(a1)
    80003a48:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a4c:	00459783          	lh	a5,4(a1)
    80003a50:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a54:	00659783          	lh	a5,6(a1)
    80003a58:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a5c:	459c                	lw	a5,8(a1)
    80003a5e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a60:	03400613          	li	a2,52
    80003a64:	05b1                	addi	a1,a1,12
    80003a66:	05048513          	addi	a0,s1,80
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	2dc080e7          	jalr	732(ra) # 80000d46 <memmove>
    brelse(bp);
    80003a72:	854a                	mv	a0,s2
    80003a74:	00000097          	auipc	ra,0x0
    80003a78:	876080e7          	jalr	-1930(ra) # 800032ea <brelse>
    ip->valid = 1;
    80003a7c:	4785                	li	a5,1
    80003a7e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a80:	04449783          	lh	a5,68(s1)
    80003a84:	fbb5                	bnez	a5,800039f8 <ilock+0x24>
      panic("ilock: no type");
    80003a86:	00005517          	auipc	a0,0x5
    80003a8a:	d9250513          	addi	a0,a0,-622 # 80008818 <syscall_argc+0x140>
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	ab6080e7          	jalr	-1354(ra) # 80000544 <panic>

0000000080003a96 <iunlock>:
{
    80003a96:	1101                	addi	sp,sp,-32
    80003a98:	ec06                	sd	ra,24(sp)
    80003a9a:	e822                	sd	s0,16(sp)
    80003a9c:	e426                	sd	s1,8(sp)
    80003a9e:	e04a                	sd	s2,0(sp)
    80003aa0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aa2:	c905                	beqz	a0,80003ad2 <iunlock+0x3c>
    80003aa4:	84aa                	mv	s1,a0
    80003aa6:	01050913          	addi	s2,a0,16
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00001097          	auipc	ra,0x1
    80003ab0:	c7c080e7          	jalr	-900(ra) # 80004728 <holdingsleep>
    80003ab4:	cd19                	beqz	a0,80003ad2 <iunlock+0x3c>
    80003ab6:	449c                	lw	a5,8(s1)
    80003ab8:	00f05d63          	blez	a5,80003ad2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003abc:	854a                	mv	a0,s2
    80003abe:	00001097          	auipc	ra,0x1
    80003ac2:	c26080e7          	jalr	-986(ra) # 800046e4 <releasesleep>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret
    panic("iunlock");
    80003ad2:	00005517          	auipc	a0,0x5
    80003ad6:	d5650513          	addi	a0,a0,-682 # 80008828 <syscall_argc+0x150>
    80003ada:	ffffd097          	auipc	ra,0xffffd
    80003ade:	a6a080e7          	jalr	-1430(ra) # 80000544 <panic>

0000000080003ae2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ae2:	7179                	addi	sp,sp,-48
    80003ae4:	f406                	sd	ra,40(sp)
    80003ae6:	f022                	sd	s0,32(sp)
    80003ae8:	ec26                	sd	s1,24(sp)
    80003aea:	e84a                	sd	s2,16(sp)
    80003aec:	e44e                	sd	s3,8(sp)
    80003aee:	e052                	sd	s4,0(sp)
    80003af0:	1800                	addi	s0,sp,48
    80003af2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003af4:	05050493          	addi	s1,a0,80
    80003af8:	08050913          	addi	s2,a0,128
    80003afc:	a021                	j	80003b04 <itrunc+0x22>
    80003afe:	0491                	addi	s1,s1,4
    80003b00:	01248d63          	beq	s1,s2,80003b1a <itrunc+0x38>
    if(ip->addrs[i]){
    80003b04:	408c                	lw	a1,0(s1)
    80003b06:	dde5                	beqz	a1,80003afe <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b08:	0009a503          	lw	a0,0(s3)
    80003b0c:	00000097          	auipc	ra,0x0
    80003b10:	8f4080e7          	jalr	-1804(ra) # 80003400 <bfree>
      ip->addrs[i] = 0;
    80003b14:	0004a023          	sw	zero,0(s1)
    80003b18:	b7dd                	j	80003afe <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b1a:	0809a583          	lw	a1,128(s3)
    80003b1e:	e185                	bnez	a1,80003b3e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b20:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b24:	854e                	mv	a0,s3
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	de4080e7          	jalr	-540(ra) # 8000390a <iupdate>
}
    80003b2e:	70a2                	ld	ra,40(sp)
    80003b30:	7402                	ld	s0,32(sp)
    80003b32:	64e2                	ld	s1,24(sp)
    80003b34:	6942                	ld	s2,16(sp)
    80003b36:	69a2                	ld	s3,8(sp)
    80003b38:	6a02                	ld	s4,0(sp)
    80003b3a:	6145                	addi	sp,sp,48
    80003b3c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b3e:	0009a503          	lw	a0,0(s3)
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	678080e7          	jalr	1656(ra) # 800031ba <bread>
    80003b4a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b4c:	05850493          	addi	s1,a0,88
    80003b50:	45850913          	addi	s2,a0,1112
    80003b54:	a811                	j	80003b68 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b56:	0009a503          	lw	a0,0(s3)
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	8a6080e7          	jalr	-1882(ra) # 80003400 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b62:	0491                	addi	s1,s1,4
    80003b64:	01248563          	beq	s1,s2,80003b6e <itrunc+0x8c>
      if(a[j])
    80003b68:	408c                	lw	a1,0(s1)
    80003b6a:	dde5                	beqz	a1,80003b62 <itrunc+0x80>
    80003b6c:	b7ed                	j	80003b56 <itrunc+0x74>
    brelse(bp);
    80003b6e:	8552                	mv	a0,s4
    80003b70:	fffff097          	auipc	ra,0xfffff
    80003b74:	77a080e7          	jalr	1914(ra) # 800032ea <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b78:	0809a583          	lw	a1,128(s3)
    80003b7c:	0009a503          	lw	a0,0(s3)
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	880080e7          	jalr	-1920(ra) # 80003400 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b88:	0809a023          	sw	zero,128(s3)
    80003b8c:	bf51                	j	80003b20 <itrunc+0x3e>

0000000080003b8e <iput>:
{
    80003b8e:	1101                	addi	sp,sp,-32
    80003b90:	ec06                	sd	ra,24(sp)
    80003b92:	e822                	sd	s0,16(sp)
    80003b94:	e426                	sd	s1,8(sp)
    80003b96:	e04a                	sd	s2,0(sp)
    80003b98:	1000                	addi	s0,sp,32
    80003b9a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b9c:	0001d517          	auipc	a0,0x1d
    80003ba0:	d2450513          	addi	a0,a0,-732 # 800208c0 <itable>
    80003ba4:	ffffd097          	auipc	ra,0xffffd
    80003ba8:	046080e7          	jalr	70(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bac:	4498                	lw	a4,8(s1)
    80003bae:	4785                	li	a5,1
    80003bb0:	02f70363          	beq	a4,a5,80003bd6 <iput+0x48>
  ip->ref--;
    80003bb4:	449c                	lw	a5,8(s1)
    80003bb6:	37fd                	addiw	a5,a5,-1
    80003bb8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bba:	0001d517          	auipc	a0,0x1d
    80003bbe:	d0650513          	addi	a0,a0,-762 # 800208c0 <itable>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	0dc080e7          	jalr	220(ra) # 80000c9e <release>
}
    80003bca:	60e2                	ld	ra,24(sp)
    80003bcc:	6442                	ld	s0,16(sp)
    80003bce:	64a2                	ld	s1,8(sp)
    80003bd0:	6902                	ld	s2,0(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bd6:	40bc                	lw	a5,64(s1)
    80003bd8:	dff1                	beqz	a5,80003bb4 <iput+0x26>
    80003bda:	04a49783          	lh	a5,74(s1)
    80003bde:	fbf9                	bnez	a5,80003bb4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003be0:	01048913          	addi	s2,s1,16
    80003be4:	854a                	mv	a0,s2
    80003be6:	00001097          	auipc	ra,0x1
    80003bea:	aa8080e7          	jalr	-1368(ra) # 8000468e <acquiresleep>
    release(&itable.lock);
    80003bee:	0001d517          	auipc	a0,0x1d
    80003bf2:	cd250513          	addi	a0,a0,-814 # 800208c0 <itable>
    80003bf6:	ffffd097          	auipc	ra,0xffffd
    80003bfa:	0a8080e7          	jalr	168(ra) # 80000c9e <release>
    itrunc(ip);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00000097          	auipc	ra,0x0
    80003c04:	ee2080e7          	jalr	-286(ra) # 80003ae2 <itrunc>
    ip->type = 0;
    80003c08:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	cfc080e7          	jalr	-772(ra) # 8000390a <iupdate>
    ip->valid = 0;
    80003c16:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c1a:	854a                	mv	a0,s2
    80003c1c:	00001097          	auipc	ra,0x1
    80003c20:	ac8080e7          	jalr	-1336(ra) # 800046e4 <releasesleep>
    acquire(&itable.lock);
    80003c24:	0001d517          	auipc	a0,0x1d
    80003c28:	c9c50513          	addi	a0,a0,-868 # 800208c0 <itable>
    80003c2c:	ffffd097          	auipc	ra,0xffffd
    80003c30:	fbe080e7          	jalr	-66(ra) # 80000bea <acquire>
    80003c34:	b741                	j	80003bb4 <iput+0x26>

0000000080003c36 <iunlockput>:
{
    80003c36:	1101                	addi	sp,sp,-32
    80003c38:	ec06                	sd	ra,24(sp)
    80003c3a:	e822                	sd	s0,16(sp)
    80003c3c:	e426                	sd	s1,8(sp)
    80003c3e:	1000                	addi	s0,sp,32
    80003c40:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	e54080e7          	jalr	-428(ra) # 80003a96 <iunlock>
  iput(ip);
    80003c4a:	8526                	mv	a0,s1
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	f42080e7          	jalr	-190(ra) # 80003b8e <iput>
}
    80003c54:	60e2                	ld	ra,24(sp)
    80003c56:	6442                	ld	s0,16(sp)
    80003c58:	64a2                	ld	s1,8(sp)
    80003c5a:	6105                	addi	sp,sp,32
    80003c5c:	8082                	ret

0000000080003c5e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c5e:	1141                	addi	sp,sp,-16
    80003c60:	e422                	sd	s0,8(sp)
    80003c62:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c64:	411c                	lw	a5,0(a0)
    80003c66:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c68:	415c                	lw	a5,4(a0)
    80003c6a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c6c:	04451783          	lh	a5,68(a0)
    80003c70:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c74:	04a51783          	lh	a5,74(a0)
    80003c78:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c7c:	04c56783          	lwu	a5,76(a0)
    80003c80:	e99c                	sd	a5,16(a1)
}
    80003c82:	6422                	ld	s0,8(sp)
    80003c84:	0141                	addi	sp,sp,16
    80003c86:	8082                	ret

0000000080003c88 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c88:	457c                	lw	a5,76(a0)
    80003c8a:	0ed7e963          	bltu	a5,a3,80003d7c <readi+0xf4>
{
    80003c8e:	7159                	addi	sp,sp,-112
    80003c90:	f486                	sd	ra,104(sp)
    80003c92:	f0a2                	sd	s0,96(sp)
    80003c94:	eca6                	sd	s1,88(sp)
    80003c96:	e8ca                	sd	s2,80(sp)
    80003c98:	e4ce                	sd	s3,72(sp)
    80003c9a:	e0d2                	sd	s4,64(sp)
    80003c9c:	fc56                	sd	s5,56(sp)
    80003c9e:	f85a                	sd	s6,48(sp)
    80003ca0:	f45e                	sd	s7,40(sp)
    80003ca2:	f062                	sd	s8,32(sp)
    80003ca4:	ec66                	sd	s9,24(sp)
    80003ca6:	e86a                	sd	s10,16(sp)
    80003ca8:	e46e                	sd	s11,8(sp)
    80003caa:	1880                	addi	s0,sp,112
    80003cac:	8b2a                	mv	s6,a0
    80003cae:	8bae                	mv	s7,a1
    80003cb0:	8a32                	mv	s4,a2
    80003cb2:	84b6                	mv	s1,a3
    80003cb4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cb6:	9f35                	addw	a4,a4,a3
    return 0;
    80003cb8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cba:	0ad76063          	bltu	a4,a3,80003d5a <readi+0xd2>
  if(off + n > ip->size)
    80003cbe:	00e7f463          	bgeu	a5,a4,80003cc6 <readi+0x3e>
    n = ip->size - off;
    80003cc2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc6:	0a0a8963          	beqz	s5,80003d78 <readi+0xf0>
    80003cca:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ccc:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cd0:	5c7d                	li	s8,-1
    80003cd2:	a82d                	j	80003d0c <readi+0x84>
    80003cd4:	020d1d93          	slli	s11,s10,0x20
    80003cd8:	020ddd93          	srli	s11,s11,0x20
    80003cdc:	05890613          	addi	a2,s2,88
    80003ce0:	86ee                	mv	a3,s11
    80003ce2:	963a                	add	a2,a2,a4
    80003ce4:	85d2                	mv	a1,s4
    80003ce6:	855e                	mv	a0,s7
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	96e080e7          	jalr	-1682(ra) # 80002656 <either_copyout>
    80003cf0:	05850d63          	beq	a0,s8,80003d4a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	5f4080e7          	jalr	1524(ra) # 800032ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cfe:	013d09bb          	addw	s3,s10,s3
    80003d02:	009d04bb          	addw	s1,s10,s1
    80003d06:	9a6e                	add	s4,s4,s11
    80003d08:	0559f763          	bgeu	s3,s5,80003d56 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d0c:	00a4d59b          	srliw	a1,s1,0xa
    80003d10:	855a                	mv	a0,s6
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	8a2080e7          	jalr	-1886(ra) # 800035b4 <bmap>
    80003d1a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d1e:	cd85                	beqz	a1,80003d56 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d20:	000b2503          	lw	a0,0(s6)
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	496080e7          	jalr	1174(ra) # 800031ba <bread>
    80003d2c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2e:	3ff4f713          	andi	a4,s1,1023
    80003d32:	40ec87bb          	subw	a5,s9,a4
    80003d36:	413a86bb          	subw	a3,s5,s3
    80003d3a:	8d3e                	mv	s10,a5
    80003d3c:	2781                	sext.w	a5,a5
    80003d3e:	0006861b          	sext.w	a2,a3
    80003d42:	f8f679e3          	bgeu	a2,a5,80003cd4 <readi+0x4c>
    80003d46:	8d36                	mv	s10,a3
    80003d48:	b771                	j	80003cd4 <readi+0x4c>
      brelse(bp);
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	fffff097          	auipc	ra,0xfffff
    80003d50:	59e080e7          	jalr	1438(ra) # 800032ea <brelse>
      tot = -1;
    80003d54:	59fd                	li	s3,-1
  }
  return tot;
    80003d56:	0009851b          	sext.w	a0,s3
}
    80003d5a:	70a6                	ld	ra,104(sp)
    80003d5c:	7406                	ld	s0,96(sp)
    80003d5e:	64e6                	ld	s1,88(sp)
    80003d60:	6946                	ld	s2,80(sp)
    80003d62:	69a6                	ld	s3,72(sp)
    80003d64:	6a06                	ld	s4,64(sp)
    80003d66:	7ae2                	ld	s5,56(sp)
    80003d68:	7b42                	ld	s6,48(sp)
    80003d6a:	7ba2                	ld	s7,40(sp)
    80003d6c:	7c02                	ld	s8,32(sp)
    80003d6e:	6ce2                	ld	s9,24(sp)
    80003d70:	6d42                	ld	s10,16(sp)
    80003d72:	6da2                	ld	s11,8(sp)
    80003d74:	6165                	addi	sp,sp,112
    80003d76:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d78:	89d6                	mv	s3,s5
    80003d7a:	bff1                	j	80003d56 <readi+0xce>
    return 0;
    80003d7c:	4501                	li	a0,0
}
    80003d7e:	8082                	ret

0000000080003d80 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d80:	457c                	lw	a5,76(a0)
    80003d82:	10d7e863          	bltu	a5,a3,80003e92 <writei+0x112>
{
    80003d86:	7159                	addi	sp,sp,-112
    80003d88:	f486                	sd	ra,104(sp)
    80003d8a:	f0a2                	sd	s0,96(sp)
    80003d8c:	eca6                	sd	s1,88(sp)
    80003d8e:	e8ca                	sd	s2,80(sp)
    80003d90:	e4ce                	sd	s3,72(sp)
    80003d92:	e0d2                	sd	s4,64(sp)
    80003d94:	fc56                	sd	s5,56(sp)
    80003d96:	f85a                	sd	s6,48(sp)
    80003d98:	f45e                	sd	s7,40(sp)
    80003d9a:	f062                	sd	s8,32(sp)
    80003d9c:	ec66                	sd	s9,24(sp)
    80003d9e:	e86a                	sd	s10,16(sp)
    80003da0:	e46e                	sd	s11,8(sp)
    80003da2:	1880                	addi	s0,sp,112
    80003da4:	8aaa                	mv	s5,a0
    80003da6:	8bae                	mv	s7,a1
    80003da8:	8a32                	mv	s4,a2
    80003daa:	8936                	mv	s2,a3
    80003dac:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dae:	00e687bb          	addw	a5,a3,a4
    80003db2:	0ed7e263          	bltu	a5,a3,80003e96 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003db6:	00043737          	lui	a4,0x43
    80003dba:	0ef76063          	bltu	a4,a5,80003e9a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dbe:	0c0b0863          	beqz	s6,80003e8e <writei+0x10e>
    80003dc2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dc4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dc8:	5c7d                	li	s8,-1
    80003dca:	a091                	j	80003e0e <writei+0x8e>
    80003dcc:	020d1d93          	slli	s11,s10,0x20
    80003dd0:	020ddd93          	srli	s11,s11,0x20
    80003dd4:	05848513          	addi	a0,s1,88
    80003dd8:	86ee                	mv	a3,s11
    80003dda:	8652                	mv	a2,s4
    80003ddc:	85de                	mv	a1,s7
    80003dde:	953a                	add	a0,a0,a4
    80003de0:	fffff097          	auipc	ra,0xfffff
    80003de4:	8cc080e7          	jalr	-1844(ra) # 800026ac <either_copyin>
    80003de8:	07850263          	beq	a0,s8,80003e4c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dec:	8526                	mv	a0,s1
    80003dee:	00000097          	auipc	ra,0x0
    80003df2:	780080e7          	jalr	1920(ra) # 8000456e <log_write>
    brelse(bp);
    80003df6:	8526                	mv	a0,s1
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	4f2080e7          	jalr	1266(ra) # 800032ea <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e00:	013d09bb          	addw	s3,s10,s3
    80003e04:	012d093b          	addw	s2,s10,s2
    80003e08:	9a6e                	add	s4,s4,s11
    80003e0a:	0569f663          	bgeu	s3,s6,80003e56 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e0e:	00a9559b          	srliw	a1,s2,0xa
    80003e12:	8556                	mv	a0,s5
    80003e14:	fffff097          	auipc	ra,0xfffff
    80003e18:	7a0080e7          	jalr	1952(ra) # 800035b4 <bmap>
    80003e1c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e20:	c99d                	beqz	a1,80003e56 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e22:	000aa503          	lw	a0,0(s5)
    80003e26:	fffff097          	auipc	ra,0xfffff
    80003e2a:	394080e7          	jalr	916(ra) # 800031ba <bread>
    80003e2e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e30:	3ff97713          	andi	a4,s2,1023
    80003e34:	40ec87bb          	subw	a5,s9,a4
    80003e38:	413b06bb          	subw	a3,s6,s3
    80003e3c:	8d3e                	mv	s10,a5
    80003e3e:	2781                	sext.w	a5,a5
    80003e40:	0006861b          	sext.w	a2,a3
    80003e44:	f8f674e3          	bgeu	a2,a5,80003dcc <writei+0x4c>
    80003e48:	8d36                	mv	s10,a3
    80003e4a:	b749                	j	80003dcc <writei+0x4c>
      brelse(bp);
    80003e4c:	8526                	mv	a0,s1
    80003e4e:	fffff097          	auipc	ra,0xfffff
    80003e52:	49c080e7          	jalr	1180(ra) # 800032ea <brelse>
  }

  if(off > ip->size)
    80003e56:	04caa783          	lw	a5,76(s5)
    80003e5a:	0127f463          	bgeu	a5,s2,80003e62 <writei+0xe2>
    ip->size = off;
    80003e5e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e62:	8556                	mv	a0,s5
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	aa6080e7          	jalr	-1370(ra) # 8000390a <iupdate>

  return tot;
    80003e6c:	0009851b          	sext.w	a0,s3
}
    80003e70:	70a6                	ld	ra,104(sp)
    80003e72:	7406                	ld	s0,96(sp)
    80003e74:	64e6                	ld	s1,88(sp)
    80003e76:	6946                	ld	s2,80(sp)
    80003e78:	69a6                	ld	s3,72(sp)
    80003e7a:	6a06                	ld	s4,64(sp)
    80003e7c:	7ae2                	ld	s5,56(sp)
    80003e7e:	7b42                	ld	s6,48(sp)
    80003e80:	7ba2                	ld	s7,40(sp)
    80003e82:	7c02                	ld	s8,32(sp)
    80003e84:	6ce2                	ld	s9,24(sp)
    80003e86:	6d42                	ld	s10,16(sp)
    80003e88:	6da2                	ld	s11,8(sp)
    80003e8a:	6165                	addi	sp,sp,112
    80003e8c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e8e:	89da                	mv	s3,s6
    80003e90:	bfc9                	j	80003e62 <writei+0xe2>
    return -1;
    80003e92:	557d                	li	a0,-1
}
    80003e94:	8082                	ret
    return -1;
    80003e96:	557d                	li	a0,-1
    80003e98:	bfe1                	j	80003e70 <writei+0xf0>
    return -1;
    80003e9a:	557d                	li	a0,-1
    80003e9c:	bfd1                	j	80003e70 <writei+0xf0>

0000000080003e9e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e9e:	1141                	addi	sp,sp,-16
    80003ea0:	e406                	sd	ra,8(sp)
    80003ea2:	e022                	sd	s0,0(sp)
    80003ea4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ea6:	4639                	li	a2,14
    80003ea8:	ffffd097          	auipc	ra,0xffffd
    80003eac:	f16080e7          	jalr	-234(ra) # 80000dbe <strncmp>
}
    80003eb0:	60a2                	ld	ra,8(sp)
    80003eb2:	6402                	ld	s0,0(sp)
    80003eb4:	0141                	addi	sp,sp,16
    80003eb6:	8082                	ret

0000000080003eb8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003eb8:	7139                	addi	sp,sp,-64
    80003eba:	fc06                	sd	ra,56(sp)
    80003ebc:	f822                	sd	s0,48(sp)
    80003ebe:	f426                	sd	s1,40(sp)
    80003ec0:	f04a                	sd	s2,32(sp)
    80003ec2:	ec4e                	sd	s3,24(sp)
    80003ec4:	e852                	sd	s4,16(sp)
    80003ec6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ec8:	04451703          	lh	a4,68(a0)
    80003ecc:	4785                	li	a5,1
    80003ece:	00f71a63          	bne	a4,a5,80003ee2 <dirlookup+0x2a>
    80003ed2:	892a                	mv	s2,a0
    80003ed4:	89ae                	mv	s3,a1
    80003ed6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	457c                	lw	a5,76(a0)
    80003eda:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003edc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ede:	e79d                	bnez	a5,80003f0c <dirlookup+0x54>
    80003ee0:	a8a5                	j	80003f58 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ee2:	00005517          	auipc	a0,0x5
    80003ee6:	94e50513          	addi	a0,a0,-1714 # 80008830 <syscall_argc+0x158>
    80003eea:	ffffc097          	auipc	ra,0xffffc
    80003eee:	65a080e7          	jalr	1626(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003ef2:	00005517          	auipc	a0,0x5
    80003ef6:	95650513          	addi	a0,a0,-1706 # 80008848 <syscall_argc+0x170>
    80003efa:	ffffc097          	auipc	ra,0xffffc
    80003efe:	64a080e7          	jalr	1610(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f02:	24c1                	addiw	s1,s1,16
    80003f04:	04c92783          	lw	a5,76(s2)
    80003f08:	04f4f763          	bgeu	s1,a5,80003f56 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0c:	4741                	li	a4,16
    80003f0e:	86a6                	mv	a3,s1
    80003f10:	fc040613          	addi	a2,s0,-64
    80003f14:	4581                	li	a1,0
    80003f16:	854a                	mv	a0,s2
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	d70080e7          	jalr	-656(ra) # 80003c88 <readi>
    80003f20:	47c1                	li	a5,16
    80003f22:	fcf518e3          	bne	a0,a5,80003ef2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f26:	fc045783          	lhu	a5,-64(s0)
    80003f2a:	dfe1                	beqz	a5,80003f02 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f2c:	fc240593          	addi	a1,s0,-62
    80003f30:	854e                	mv	a0,s3
    80003f32:	00000097          	auipc	ra,0x0
    80003f36:	f6c080e7          	jalr	-148(ra) # 80003e9e <namecmp>
    80003f3a:	f561                	bnez	a0,80003f02 <dirlookup+0x4a>
      if(poff)
    80003f3c:	000a0463          	beqz	s4,80003f44 <dirlookup+0x8c>
        *poff = off;
    80003f40:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f44:	fc045583          	lhu	a1,-64(s0)
    80003f48:	00092503          	lw	a0,0(s2)
    80003f4c:	fffff097          	auipc	ra,0xfffff
    80003f50:	750080e7          	jalr	1872(ra) # 8000369c <iget>
    80003f54:	a011                	j	80003f58 <dirlookup+0xa0>
  return 0;
    80003f56:	4501                	li	a0,0
}
    80003f58:	70e2                	ld	ra,56(sp)
    80003f5a:	7442                	ld	s0,48(sp)
    80003f5c:	74a2                	ld	s1,40(sp)
    80003f5e:	7902                	ld	s2,32(sp)
    80003f60:	69e2                	ld	s3,24(sp)
    80003f62:	6a42                	ld	s4,16(sp)
    80003f64:	6121                	addi	sp,sp,64
    80003f66:	8082                	ret

0000000080003f68 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f68:	711d                	addi	sp,sp,-96
    80003f6a:	ec86                	sd	ra,88(sp)
    80003f6c:	e8a2                	sd	s0,80(sp)
    80003f6e:	e4a6                	sd	s1,72(sp)
    80003f70:	e0ca                	sd	s2,64(sp)
    80003f72:	fc4e                	sd	s3,56(sp)
    80003f74:	f852                	sd	s4,48(sp)
    80003f76:	f456                	sd	s5,40(sp)
    80003f78:	f05a                	sd	s6,32(sp)
    80003f7a:	ec5e                	sd	s7,24(sp)
    80003f7c:	e862                	sd	s8,16(sp)
    80003f7e:	e466                	sd	s9,8(sp)
    80003f80:	1080                	addi	s0,sp,96
    80003f82:	84aa                	mv	s1,a0
    80003f84:	8b2e                	mv	s6,a1
    80003f86:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f88:	00054703          	lbu	a4,0(a0)
    80003f8c:	02f00793          	li	a5,47
    80003f90:	02f70363          	beq	a4,a5,80003fb6 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f94:	ffffe097          	auipc	ra,0xffffe
    80003f98:	a32080e7          	jalr	-1486(ra) # 800019c6 <myproc>
    80003f9c:	15853503          	ld	a0,344(a0)
    80003fa0:	00000097          	auipc	ra,0x0
    80003fa4:	9f6080e7          	jalr	-1546(ra) # 80003996 <idup>
    80003fa8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003faa:	02f00913          	li	s2,47
  len = path - s;
    80003fae:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003fb0:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fb2:	4c05                	li	s8,1
    80003fb4:	a865                	j	8000406c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fb6:	4585                	li	a1,1
    80003fb8:	4505                	li	a0,1
    80003fba:	fffff097          	auipc	ra,0xfffff
    80003fbe:	6e2080e7          	jalr	1762(ra) # 8000369c <iget>
    80003fc2:	89aa                	mv	s3,a0
    80003fc4:	b7dd                	j	80003faa <namex+0x42>
      iunlockput(ip);
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	c6e080e7          	jalr	-914(ra) # 80003c36 <iunlockput>
      return 0;
    80003fd0:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	60e6                	ld	ra,88(sp)
    80003fd6:	6446                	ld	s0,80(sp)
    80003fd8:	64a6                	ld	s1,72(sp)
    80003fda:	6906                	ld	s2,64(sp)
    80003fdc:	79e2                	ld	s3,56(sp)
    80003fde:	7a42                	ld	s4,48(sp)
    80003fe0:	7aa2                	ld	s5,40(sp)
    80003fe2:	7b02                	ld	s6,32(sp)
    80003fe4:	6be2                	ld	s7,24(sp)
    80003fe6:	6c42                	ld	s8,16(sp)
    80003fe8:	6ca2                	ld	s9,8(sp)
    80003fea:	6125                	addi	sp,sp,96
    80003fec:	8082                	ret
      iunlock(ip);
    80003fee:	854e                	mv	a0,s3
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	aa6080e7          	jalr	-1370(ra) # 80003a96 <iunlock>
      return ip;
    80003ff8:	bfe9                	j	80003fd2 <namex+0x6a>
      iunlockput(ip);
    80003ffa:	854e                	mv	a0,s3
    80003ffc:	00000097          	auipc	ra,0x0
    80004000:	c3a080e7          	jalr	-966(ra) # 80003c36 <iunlockput>
      return 0;
    80004004:	89d2                	mv	s3,s4
    80004006:	b7f1                	j	80003fd2 <namex+0x6a>
  len = path - s;
    80004008:	40b48633          	sub	a2,s1,a1
    8000400c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004010:	094cd463          	bge	s9,s4,80004098 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004014:	4639                	li	a2,14
    80004016:	8556                	mv	a0,s5
    80004018:	ffffd097          	auipc	ra,0xffffd
    8000401c:	d2e080e7          	jalr	-722(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004020:	0004c783          	lbu	a5,0(s1)
    80004024:	01279763          	bne	a5,s2,80004032 <namex+0xca>
    path++;
    80004028:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000402a:	0004c783          	lbu	a5,0(s1)
    8000402e:	ff278de3          	beq	a5,s2,80004028 <namex+0xc0>
    ilock(ip);
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	9a0080e7          	jalr	-1632(ra) # 800039d4 <ilock>
    if(ip->type != T_DIR){
    8000403c:	04499783          	lh	a5,68(s3)
    80004040:	f98793e3          	bne	a5,s8,80003fc6 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004044:	000b0563          	beqz	s6,8000404e <namex+0xe6>
    80004048:	0004c783          	lbu	a5,0(s1)
    8000404c:	d3cd                	beqz	a5,80003fee <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000404e:	865e                	mv	a2,s7
    80004050:	85d6                	mv	a1,s5
    80004052:	854e                	mv	a0,s3
    80004054:	00000097          	auipc	ra,0x0
    80004058:	e64080e7          	jalr	-412(ra) # 80003eb8 <dirlookup>
    8000405c:	8a2a                	mv	s4,a0
    8000405e:	dd51                	beqz	a0,80003ffa <namex+0x92>
    iunlockput(ip);
    80004060:	854e                	mv	a0,s3
    80004062:	00000097          	auipc	ra,0x0
    80004066:	bd4080e7          	jalr	-1068(ra) # 80003c36 <iunlockput>
    ip = next;
    8000406a:	89d2                	mv	s3,s4
  while(*path == '/')
    8000406c:	0004c783          	lbu	a5,0(s1)
    80004070:	05279763          	bne	a5,s2,800040be <namex+0x156>
    path++;
    80004074:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004076:	0004c783          	lbu	a5,0(s1)
    8000407a:	ff278de3          	beq	a5,s2,80004074 <namex+0x10c>
  if(*path == 0)
    8000407e:	c79d                	beqz	a5,800040ac <namex+0x144>
    path++;
    80004080:	85a6                	mv	a1,s1
  len = path - s;
    80004082:	8a5e                	mv	s4,s7
    80004084:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004086:	01278963          	beq	a5,s2,80004098 <namex+0x130>
    8000408a:	dfbd                	beqz	a5,80004008 <namex+0xa0>
    path++;
    8000408c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000408e:	0004c783          	lbu	a5,0(s1)
    80004092:	ff279ce3          	bne	a5,s2,8000408a <namex+0x122>
    80004096:	bf8d                	j	80004008 <namex+0xa0>
    memmove(name, s, len);
    80004098:	2601                	sext.w	a2,a2
    8000409a:	8556                	mv	a0,s5
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	caa080e7          	jalr	-854(ra) # 80000d46 <memmove>
    name[len] = 0;
    800040a4:	9a56                	add	s4,s4,s5
    800040a6:	000a0023          	sb	zero,0(s4)
    800040aa:	bf9d                	j	80004020 <namex+0xb8>
  if(nameiparent){
    800040ac:	f20b03e3          	beqz	s6,80003fd2 <namex+0x6a>
    iput(ip);
    800040b0:	854e                	mv	a0,s3
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	adc080e7          	jalr	-1316(ra) # 80003b8e <iput>
    return 0;
    800040ba:	4981                	li	s3,0
    800040bc:	bf19                	j	80003fd2 <namex+0x6a>
  if(*path == 0)
    800040be:	d7fd                	beqz	a5,800040ac <namex+0x144>
  while(*path != '/' && *path != 0)
    800040c0:	0004c783          	lbu	a5,0(s1)
    800040c4:	85a6                	mv	a1,s1
    800040c6:	b7d1                	j	8000408a <namex+0x122>

00000000800040c8 <dirlink>:
{
    800040c8:	7139                	addi	sp,sp,-64
    800040ca:	fc06                	sd	ra,56(sp)
    800040cc:	f822                	sd	s0,48(sp)
    800040ce:	f426                	sd	s1,40(sp)
    800040d0:	f04a                	sd	s2,32(sp)
    800040d2:	ec4e                	sd	s3,24(sp)
    800040d4:	e852                	sd	s4,16(sp)
    800040d6:	0080                	addi	s0,sp,64
    800040d8:	892a                	mv	s2,a0
    800040da:	8a2e                	mv	s4,a1
    800040dc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040de:	4601                	li	a2,0
    800040e0:	00000097          	auipc	ra,0x0
    800040e4:	dd8080e7          	jalr	-552(ra) # 80003eb8 <dirlookup>
    800040e8:	e93d                	bnez	a0,8000415e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ea:	04c92483          	lw	s1,76(s2)
    800040ee:	c49d                	beqz	s1,8000411c <dirlink+0x54>
    800040f0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040f2:	4741                	li	a4,16
    800040f4:	86a6                	mv	a3,s1
    800040f6:	fc040613          	addi	a2,s0,-64
    800040fa:	4581                	li	a1,0
    800040fc:	854a                	mv	a0,s2
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	b8a080e7          	jalr	-1142(ra) # 80003c88 <readi>
    80004106:	47c1                	li	a5,16
    80004108:	06f51163          	bne	a0,a5,8000416a <dirlink+0xa2>
    if(de.inum == 0)
    8000410c:	fc045783          	lhu	a5,-64(s0)
    80004110:	c791                	beqz	a5,8000411c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004112:	24c1                	addiw	s1,s1,16
    80004114:	04c92783          	lw	a5,76(s2)
    80004118:	fcf4ede3          	bltu	s1,a5,800040f2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000411c:	4639                	li	a2,14
    8000411e:	85d2                	mv	a1,s4
    80004120:	fc240513          	addi	a0,s0,-62
    80004124:	ffffd097          	auipc	ra,0xffffd
    80004128:	cd6080e7          	jalr	-810(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000412c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004130:	4741                	li	a4,16
    80004132:	86a6                	mv	a3,s1
    80004134:	fc040613          	addi	a2,s0,-64
    80004138:	4581                	li	a1,0
    8000413a:	854a                	mv	a0,s2
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	c44080e7          	jalr	-956(ra) # 80003d80 <writei>
    80004144:	1541                	addi	a0,a0,-16
    80004146:	00a03533          	snez	a0,a0
    8000414a:	40a00533          	neg	a0,a0
}
    8000414e:	70e2                	ld	ra,56(sp)
    80004150:	7442                	ld	s0,48(sp)
    80004152:	74a2                	ld	s1,40(sp)
    80004154:	7902                	ld	s2,32(sp)
    80004156:	69e2                	ld	s3,24(sp)
    80004158:	6a42                	ld	s4,16(sp)
    8000415a:	6121                	addi	sp,sp,64
    8000415c:	8082                	ret
    iput(ip);
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	a30080e7          	jalr	-1488(ra) # 80003b8e <iput>
    return -1;
    80004166:	557d                	li	a0,-1
    80004168:	b7dd                	j	8000414e <dirlink+0x86>
      panic("dirlink read");
    8000416a:	00004517          	auipc	a0,0x4
    8000416e:	6ee50513          	addi	a0,a0,1774 # 80008858 <syscall_argc+0x180>
    80004172:	ffffc097          	auipc	ra,0xffffc
    80004176:	3d2080e7          	jalr	978(ra) # 80000544 <panic>

000000008000417a <namei>:

struct inode*
namei(char *path)
{
    8000417a:	1101                	addi	sp,sp,-32
    8000417c:	ec06                	sd	ra,24(sp)
    8000417e:	e822                	sd	s0,16(sp)
    80004180:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004182:	fe040613          	addi	a2,s0,-32
    80004186:	4581                	li	a1,0
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	de0080e7          	jalr	-544(ra) # 80003f68 <namex>
}
    80004190:	60e2                	ld	ra,24(sp)
    80004192:	6442                	ld	s0,16(sp)
    80004194:	6105                	addi	sp,sp,32
    80004196:	8082                	ret

0000000080004198 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004198:	1141                	addi	sp,sp,-16
    8000419a:	e406                	sd	ra,8(sp)
    8000419c:	e022                	sd	s0,0(sp)
    8000419e:	0800                	addi	s0,sp,16
    800041a0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041a2:	4585                	li	a1,1
    800041a4:	00000097          	auipc	ra,0x0
    800041a8:	dc4080e7          	jalr	-572(ra) # 80003f68 <namex>
}
    800041ac:	60a2                	ld	ra,8(sp)
    800041ae:	6402                	ld	s0,0(sp)
    800041b0:	0141                	addi	sp,sp,16
    800041b2:	8082                	ret

00000000800041b4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041b4:	1101                	addi	sp,sp,-32
    800041b6:	ec06                	sd	ra,24(sp)
    800041b8:	e822                	sd	s0,16(sp)
    800041ba:	e426                	sd	s1,8(sp)
    800041bc:	e04a                	sd	s2,0(sp)
    800041be:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041c0:	0001e917          	auipc	s2,0x1e
    800041c4:	1a890913          	addi	s2,s2,424 # 80022368 <log>
    800041c8:	01892583          	lw	a1,24(s2)
    800041cc:	02892503          	lw	a0,40(s2)
    800041d0:	fffff097          	auipc	ra,0xfffff
    800041d4:	fea080e7          	jalr	-22(ra) # 800031ba <bread>
    800041d8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041da:	02c92683          	lw	a3,44(s2)
    800041de:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041e0:	02d05763          	blez	a3,8000420e <write_head+0x5a>
    800041e4:	0001e797          	auipc	a5,0x1e
    800041e8:	1b478793          	addi	a5,a5,436 # 80022398 <log+0x30>
    800041ec:	05c50713          	addi	a4,a0,92
    800041f0:	36fd                	addiw	a3,a3,-1
    800041f2:	1682                	slli	a3,a3,0x20
    800041f4:	9281                	srli	a3,a3,0x20
    800041f6:	068a                	slli	a3,a3,0x2
    800041f8:	0001e617          	auipc	a2,0x1e
    800041fc:	1a460613          	addi	a2,a2,420 # 8002239c <log+0x34>
    80004200:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004202:	4390                	lw	a2,0(a5)
    80004204:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004206:	0791                	addi	a5,a5,4
    80004208:	0711                	addi	a4,a4,4
    8000420a:	fed79ce3          	bne	a5,a3,80004202 <write_head+0x4e>
  }
  bwrite(buf);
    8000420e:	8526                	mv	a0,s1
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	09c080e7          	jalr	156(ra) # 800032ac <bwrite>
  brelse(buf);
    80004218:	8526                	mv	a0,s1
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	0d0080e7          	jalr	208(ra) # 800032ea <brelse>
}
    80004222:	60e2                	ld	ra,24(sp)
    80004224:	6442                	ld	s0,16(sp)
    80004226:	64a2                	ld	s1,8(sp)
    80004228:	6902                	ld	s2,0(sp)
    8000422a:	6105                	addi	sp,sp,32
    8000422c:	8082                	ret

000000008000422e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000422e:	0001e797          	auipc	a5,0x1e
    80004232:	1667a783          	lw	a5,358(a5) # 80022394 <log+0x2c>
    80004236:	0af05d63          	blez	a5,800042f0 <install_trans+0xc2>
{
    8000423a:	7139                	addi	sp,sp,-64
    8000423c:	fc06                	sd	ra,56(sp)
    8000423e:	f822                	sd	s0,48(sp)
    80004240:	f426                	sd	s1,40(sp)
    80004242:	f04a                	sd	s2,32(sp)
    80004244:	ec4e                	sd	s3,24(sp)
    80004246:	e852                	sd	s4,16(sp)
    80004248:	e456                	sd	s5,8(sp)
    8000424a:	e05a                	sd	s6,0(sp)
    8000424c:	0080                	addi	s0,sp,64
    8000424e:	8b2a                	mv	s6,a0
    80004250:	0001ea97          	auipc	s5,0x1e
    80004254:	148a8a93          	addi	s5,s5,328 # 80022398 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004258:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000425a:	0001e997          	auipc	s3,0x1e
    8000425e:	10e98993          	addi	s3,s3,270 # 80022368 <log>
    80004262:	a035                	j	8000428e <install_trans+0x60>
      bunpin(dbuf);
    80004264:	8526                	mv	a0,s1
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	15e080e7          	jalr	350(ra) # 800033c4 <bunpin>
    brelse(lbuf);
    8000426e:	854a                	mv	a0,s2
    80004270:	fffff097          	auipc	ra,0xfffff
    80004274:	07a080e7          	jalr	122(ra) # 800032ea <brelse>
    brelse(dbuf);
    80004278:	8526                	mv	a0,s1
    8000427a:	fffff097          	auipc	ra,0xfffff
    8000427e:	070080e7          	jalr	112(ra) # 800032ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004282:	2a05                	addiw	s4,s4,1
    80004284:	0a91                	addi	s5,s5,4
    80004286:	02c9a783          	lw	a5,44(s3)
    8000428a:	04fa5963          	bge	s4,a5,800042dc <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000428e:	0189a583          	lw	a1,24(s3)
    80004292:	014585bb          	addw	a1,a1,s4
    80004296:	2585                	addiw	a1,a1,1
    80004298:	0289a503          	lw	a0,40(s3)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	f1e080e7          	jalr	-226(ra) # 800031ba <bread>
    800042a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042a6:	000aa583          	lw	a1,0(s5)
    800042aa:	0289a503          	lw	a0,40(s3)
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	f0c080e7          	jalr	-244(ra) # 800031ba <bread>
    800042b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042b8:	40000613          	li	a2,1024
    800042bc:	05890593          	addi	a1,s2,88
    800042c0:	05850513          	addi	a0,a0,88
    800042c4:	ffffd097          	auipc	ra,0xffffd
    800042c8:	a82080e7          	jalr	-1406(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042cc:	8526                	mv	a0,s1
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	fde080e7          	jalr	-34(ra) # 800032ac <bwrite>
    if(recovering == 0)
    800042d6:	f80b1ce3          	bnez	s6,8000426e <install_trans+0x40>
    800042da:	b769                	j	80004264 <install_trans+0x36>
}
    800042dc:	70e2                	ld	ra,56(sp)
    800042de:	7442                	ld	s0,48(sp)
    800042e0:	74a2                	ld	s1,40(sp)
    800042e2:	7902                	ld	s2,32(sp)
    800042e4:	69e2                	ld	s3,24(sp)
    800042e6:	6a42                	ld	s4,16(sp)
    800042e8:	6aa2                	ld	s5,8(sp)
    800042ea:	6b02                	ld	s6,0(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    800042f0:	8082                	ret

00000000800042f2 <initlog>:
{
    800042f2:	7179                	addi	sp,sp,-48
    800042f4:	f406                	sd	ra,40(sp)
    800042f6:	f022                	sd	s0,32(sp)
    800042f8:	ec26                	sd	s1,24(sp)
    800042fa:	e84a                	sd	s2,16(sp)
    800042fc:	e44e                	sd	s3,8(sp)
    800042fe:	1800                	addi	s0,sp,48
    80004300:	892a                	mv	s2,a0
    80004302:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004304:	0001e497          	auipc	s1,0x1e
    80004308:	06448493          	addi	s1,s1,100 # 80022368 <log>
    8000430c:	00004597          	auipc	a1,0x4
    80004310:	55c58593          	addi	a1,a1,1372 # 80008868 <syscall_argc+0x190>
    80004314:	8526                	mv	a0,s1
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	844080e7          	jalr	-1980(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000431e:	0149a583          	lw	a1,20(s3)
    80004322:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004324:	0109a783          	lw	a5,16(s3)
    80004328:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000432a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000432e:	854a                	mv	a0,s2
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	e8a080e7          	jalr	-374(ra) # 800031ba <bread>
  log.lh.n = lh->n;
    80004338:	4d3c                	lw	a5,88(a0)
    8000433a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000433c:	02f05563          	blez	a5,80004366 <initlog+0x74>
    80004340:	05c50713          	addi	a4,a0,92
    80004344:	0001e697          	auipc	a3,0x1e
    80004348:	05468693          	addi	a3,a3,84 # 80022398 <log+0x30>
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	1782                	slli	a5,a5,0x20
    80004350:	9381                	srli	a5,a5,0x20
    80004352:	078a                	slli	a5,a5,0x2
    80004354:	06050613          	addi	a2,a0,96
    80004358:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000435a:	4310                	lw	a2,0(a4)
    8000435c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000435e:	0711                	addi	a4,a4,4
    80004360:	0691                	addi	a3,a3,4
    80004362:	fef71ce3          	bne	a4,a5,8000435a <initlog+0x68>
  brelse(buf);
    80004366:	fffff097          	auipc	ra,0xfffff
    8000436a:	f84080e7          	jalr	-124(ra) # 800032ea <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000436e:	4505                	li	a0,1
    80004370:	00000097          	auipc	ra,0x0
    80004374:	ebe080e7          	jalr	-322(ra) # 8000422e <install_trans>
  log.lh.n = 0;
    80004378:	0001e797          	auipc	a5,0x1e
    8000437c:	0007ae23          	sw	zero,28(a5) # 80022394 <log+0x2c>
  write_head(); // clear the log
    80004380:	00000097          	auipc	ra,0x0
    80004384:	e34080e7          	jalr	-460(ra) # 800041b4 <write_head>
}
    80004388:	70a2                	ld	ra,40(sp)
    8000438a:	7402                	ld	s0,32(sp)
    8000438c:	64e2                	ld	s1,24(sp)
    8000438e:	6942                	ld	s2,16(sp)
    80004390:	69a2                	ld	s3,8(sp)
    80004392:	6145                	addi	sp,sp,48
    80004394:	8082                	ret

0000000080004396 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004396:	1101                	addi	sp,sp,-32
    80004398:	ec06                	sd	ra,24(sp)
    8000439a:	e822                	sd	s0,16(sp)
    8000439c:	e426                	sd	s1,8(sp)
    8000439e:	e04a                	sd	s2,0(sp)
    800043a0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043a2:	0001e517          	auipc	a0,0x1e
    800043a6:	fc650513          	addi	a0,a0,-58 # 80022368 <log>
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	840080e7          	jalr	-1984(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800043b2:	0001e497          	auipc	s1,0x1e
    800043b6:	fb648493          	addi	s1,s1,-74 # 80022368 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ba:	4979                	li	s2,30
    800043bc:	a039                	j	800043ca <begin_op+0x34>
      sleep(&log, &log.lock);
    800043be:	85a6                	mv	a1,s1
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffe097          	auipc	ra,0xffffe
    800043c6:	d38080e7          	jalr	-712(ra) # 800020fa <sleep>
    if(log.committing){
    800043ca:	50dc                	lw	a5,36(s1)
    800043cc:	fbed                	bnez	a5,800043be <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ce:	509c                	lw	a5,32(s1)
    800043d0:	0017871b          	addiw	a4,a5,1
    800043d4:	0007069b          	sext.w	a3,a4
    800043d8:	0027179b          	slliw	a5,a4,0x2
    800043dc:	9fb9                	addw	a5,a5,a4
    800043de:	0017979b          	slliw	a5,a5,0x1
    800043e2:	54d8                	lw	a4,44(s1)
    800043e4:	9fb9                	addw	a5,a5,a4
    800043e6:	00f95963          	bge	s2,a5,800043f8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043ea:	85a6                	mv	a1,s1
    800043ec:	8526                	mv	a0,s1
    800043ee:	ffffe097          	auipc	ra,0xffffe
    800043f2:	d0c080e7          	jalr	-756(ra) # 800020fa <sleep>
    800043f6:	bfd1                	j	800043ca <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043f8:	0001e517          	auipc	a0,0x1e
    800043fc:	f7050513          	addi	a0,a0,-144 # 80022368 <log>
    80004400:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	89c080e7          	jalr	-1892(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000440a:	60e2                	ld	ra,24(sp)
    8000440c:	6442                	ld	s0,16(sp)
    8000440e:	64a2                	ld	s1,8(sp)
    80004410:	6902                	ld	s2,0(sp)
    80004412:	6105                	addi	sp,sp,32
    80004414:	8082                	ret

0000000080004416 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004416:	7139                	addi	sp,sp,-64
    80004418:	fc06                	sd	ra,56(sp)
    8000441a:	f822                	sd	s0,48(sp)
    8000441c:	f426                	sd	s1,40(sp)
    8000441e:	f04a                	sd	s2,32(sp)
    80004420:	ec4e                	sd	s3,24(sp)
    80004422:	e852                	sd	s4,16(sp)
    80004424:	e456                	sd	s5,8(sp)
    80004426:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004428:	0001e497          	auipc	s1,0x1e
    8000442c:	f4048493          	addi	s1,s1,-192 # 80022368 <log>
    80004430:	8526                	mv	a0,s1
    80004432:	ffffc097          	auipc	ra,0xffffc
    80004436:	7b8080e7          	jalr	1976(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000443a:	509c                	lw	a5,32(s1)
    8000443c:	37fd                	addiw	a5,a5,-1
    8000443e:	0007891b          	sext.w	s2,a5
    80004442:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004444:	50dc                	lw	a5,36(s1)
    80004446:	efb9                	bnez	a5,800044a4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004448:	06091663          	bnez	s2,800044b4 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000444c:	0001e497          	auipc	s1,0x1e
    80004450:	f1c48493          	addi	s1,s1,-228 # 80022368 <log>
    80004454:	4785                	li	a5,1
    80004456:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffd097          	auipc	ra,0xffffd
    8000445e:	844080e7          	jalr	-1980(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004462:	54dc                	lw	a5,44(s1)
    80004464:	06f04763          	bgtz	a5,800044d2 <end_op+0xbc>
    acquire(&log.lock);
    80004468:	0001e497          	auipc	s1,0x1e
    8000446c:	f0048493          	addi	s1,s1,-256 # 80022368 <log>
    80004470:	8526                	mv	a0,s1
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	778080e7          	jalr	1912(ra) # 80000bea <acquire>
    log.committing = 0;
    8000447a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000447e:	8526                	mv	a0,s1
    80004480:	ffffe097          	auipc	ra,0xffffe
    80004484:	e26080e7          	jalr	-474(ra) # 800022a6 <wakeup>
    release(&log.lock);
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffd097          	auipc	ra,0xffffd
    8000448e:	814080e7          	jalr	-2028(ra) # 80000c9e <release>
}
    80004492:	70e2                	ld	ra,56(sp)
    80004494:	7442                	ld	s0,48(sp)
    80004496:	74a2                	ld	s1,40(sp)
    80004498:	7902                	ld	s2,32(sp)
    8000449a:	69e2                	ld	s3,24(sp)
    8000449c:	6a42                	ld	s4,16(sp)
    8000449e:	6aa2                	ld	s5,8(sp)
    800044a0:	6121                	addi	sp,sp,64
    800044a2:	8082                	ret
    panic("log.committing");
    800044a4:	00004517          	auipc	a0,0x4
    800044a8:	3cc50513          	addi	a0,a0,972 # 80008870 <syscall_argc+0x198>
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	098080e7          	jalr	152(ra) # 80000544 <panic>
    wakeup(&log);
    800044b4:	0001e497          	auipc	s1,0x1e
    800044b8:	eb448493          	addi	s1,s1,-332 # 80022368 <log>
    800044bc:	8526                	mv	a0,s1
    800044be:	ffffe097          	auipc	ra,0xffffe
    800044c2:	de8080e7          	jalr	-536(ra) # 800022a6 <wakeup>
  release(&log.lock);
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7d6080e7          	jalr	2006(ra) # 80000c9e <release>
  if(do_commit){
    800044d0:	b7c9                	j	80004492 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044d2:	0001ea97          	auipc	s5,0x1e
    800044d6:	ec6a8a93          	addi	s5,s5,-314 # 80022398 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044da:	0001ea17          	auipc	s4,0x1e
    800044de:	e8ea0a13          	addi	s4,s4,-370 # 80022368 <log>
    800044e2:	018a2583          	lw	a1,24(s4)
    800044e6:	012585bb          	addw	a1,a1,s2
    800044ea:	2585                	addiw	a1,a1,1
    800044ec:	028a2503          	lw	a0,40(s4)
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	cca080e7          	jalr	-822(ra) # 800031ba <bread>
    800044f8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044fa:	000aa583          	lw	a1,0(s5)
    800044fe:	028a2503          	lw	a0,40(s4)
    80004502:	fffff097          	auipc	ra,0xfffff
    80004506:	cb8080e7          	jalr	-840(ra) # 800031ba <bread>
    8000450a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000450c:	40000613          	li	a2,1024
    80004510:	05850593          	addi	a1,a0,88
    80004514:	05848513          	addi	a0,s1,88
    80004518:	ffffd097          	auipc	ra,0xffffd
    8000451c:	82e080e7          	jalr	-2002(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004520:	8526                	mv	a0,s1
    80004522:	fffff097          	auipc	ra,0xfffff
    80004526:	d8a080e7          	jalr	-630(ra) # 800032ac <bwrite>
    brelse(from);
    8000452a:	854e                	mv	a0,s3
    8000452c:	fffff097          	auipc	ra,0xfffff
    80004530:	dbe080e7          	jalr	-578(ra) # 800032ea <brelse>
    brelse(to);
    80004534:	8526                	mv	a0,s1
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	db4080e7          	jalr	-588(ra) # 800032ea <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000453e:	2905                	addiw	s2,s2,1
    80004540:	0a91                	addi	s5,s5,4
    80004542:	02ca2783          	lw	a5,44(s4)
    80004546:	f8f94ee3          	blt	s2,a5,800044e2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000454a:	00000097          	auipc	ra,0x0
    8000454e:	c6a080e7          	jalr	-918(ra) # 800041b4 <write_head>
    install_trans(0); // Now install writes to home locations
    80004552:	4501                	li	a0,0
    80004554:	00000097          	auipc	ra,0x0
    80004558:	cda080e7          	jalr	-806(ra) # 8000422e <install_trans>
    log.lh.n = 0;
    8000455c:	0001e797          	auipc	a5,0x1e
    80004560:	e207ac23          	sw	zero,-456(a5) # 80022394 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004564:	00000097          	auipc	ra,0x0
    80004568:	c50080e7          	jalr	-944(ra) # 800041b4 <write_head>
    8000456c:	bdf5                	j	80004468 <end_op+0x52>

000000008000456e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000456e:	1101                	addi	sp,sp,-32
    80004570:	ec06                	sd	ra,24(sp)
    80004572:	e822                	sd	s0,16(sp)
    80004574:	e426                	sd	s1,8(sp)
    80004576:	e04a                	sd	s2,0(sp)
    80004578:	1000                	addi	s0,sp,32
    8000457a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000457c:	0001e917          	auipc	s2,0x1e
    80004580:	dec90913          	addi	s2,s2,-532 # 80022368 <log>
    80004584:	854a                	mv	a0,s2
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	664080e7          	jalr	1636(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000458e:	02c92603          	lw	a2,44(s2)
    80004592:	47f5                	li	a5,29
    80004594:	06c7c563          	blt	a5,a2,800045fe <log_write+0x90>
    80004598:	0001e797          	auipc	a5,0x1e
    8000459c:	dec7a783          	lw	a5,-532(a5) # 80022384 <log+0x1c>
    800045a0:	37fd                	addiw	a5,a5,-1
    800045a2:	04f65e63          	bge	a2,a5,800045fe <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045a6:	0001e797          	auipc	a5,0x1e
    800045aa:	de27a783          	lw	a5,-542(a5) # 80022388 <log+0x20>
    800045ae:	06f05063          	blez	a5,8000460e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045b2:	4781                	li	a5,0
    800045b4:	06c05563          	blez	a2,8000461e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045b8:	44cc                	lw	a1,12(s1)
    800045ba:	0001e717          	auipc	a4,0x1e
    800045be:	dde70713          	addi	a4,a4,-546 # 80022398 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045c2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045c4:	4314                	lw	a3,0(a4)
    800045c6:	04b68c63          	beq	a3,a1,8000461e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045ca:	2785                	addiw	a5,a5,1
    800045cc:	0711                	addi	a4,a4,4
    800045ce:	fef61be3          	bne	a2,a5,800045c4 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045d2:	0621                	addi	a2,a2,8
    800045d4:	060a                	slli	a2,a2,0x2
    800045d6:	0001e797          	auipc	a5,0x1e
    800045da:	d9278793          	addi	a5,a5,-622 # 80022368 <log>
    800045de:	963e                	add	a2,a2,a5
    800045e0:	44dc                	lw	a5,12(s1)
    800045e2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045e4:	8526                	mv	a0,s1
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	da2080e7          	jalr	-606(ra) # 80003388 <bpin>
    log.lh.n++;
    800045ee:	0001e717          	auipc	a4,0x1e
    800045f2:	d7a70713          	addi	a4,a4,-646 # 80022368 <log>
    800045f6:	575c                	lw	a5,44(a4)
    800045f8:	2785                	addiw	a5,a5,1
    800045fa:	d75c                	sw	a5,44(a4)
    800045fc:	a835                	j	80004638 <log_write+0xca>
    panic("too big a transaction");
    800045fe:	00004517          	auipc	a0,0x4
    80004602:	28250513          	addi	a0,a0,642 # 80008880 <syscall_argc+0x1a8>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	f3e080e7          	jalr	-194(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000460e:	00004517          	auipc	a0,0x4
    80004612:	28a50513          	addi	a0,a0,650 # 80008898 <syscall_argc+0x1c0>
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	f2e080e7          	jalr	-210(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000461e:	00878713          	addi	a4,a5,8
    80004622:	00271693          	slli	a3,a4,0x2
    80004626:	0001e717          	auipc	a4,0x1e
    8000462a:	d4270713          	addi	a4,a4,-702 # 80022368 <log>
    8000462e:	9736                	add	a4,a4,a3
    80004630:	44d4                	lw	a3,12(s1)
    80004632:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004634:	faf608e3          	beq	a2,a5,800045e4 <log_write+0x76>
  }
  release(&log.lock);
    80004638:	0001e517          	auipc	a0,0x1e
    8000463c:	d3050513          	addi	a0,a0,-720 # 80022368 <log>
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	65e080e7          	jalr	1630(ra) # 80000c9e <release>
}
    80004648:	60e2                	ld	ra,24(sp)
    8000464a:	6442                	ld	s0,16(sp)
    8000464c:	64a2                	ld	s1,8(sp)
    8000464e:	6902                	ld	s2,0(sp)
    80004650:	6105                	addi	sp,sp,32
    80004652:	8082                	ret

0000000080004654 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004654:	1101                	addi	sp,sp,-32
    80004656:	ec06                	sd	ra,24(sp)
    80004658:	e822                	sd	s0,16(sp)
    8000465a:	e426                	sd	s1,8(sp)
    8000465c:	e04a                	sd	s2,0(sp)
    8000465e:	1000                	addi	s0,sp,32
    80004660:	84aa                	mv	s1,a0
    80004662:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004664:	00004597          	auipc	a1,0x4
    80004668:	25458593          	addi	a1,a1,596 # 800088b8 <syscall_argc+0x1e0>
    8000466c:	0521                	addi	a0,a0,8
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	4ec080e7          	jalr	1260(ra) # 80000b5a <initlock>
  lk->name = name;
    80004676:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000467a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000467e:	0204a423          	sw	zero,40(s1)
}
    80004682:	60e2                	ld	ra,24(sp)
    80004684:	6442                	ld	s0,16(sp)
    80004686:	64a2                	ld	s1,8(sp)
    80004688:	6902                	ld	s2,0(sp)
    8000468a:	6105                	addi	sp,sp,32
    8000468c:	8082                	ret

000000008000468e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000468e:	1101                	addi	sp,sp,-32
    80004690:	ec06                	sd	ra,24(sp)
    80004692:	e822                	sd	s0,16(sp)
    80004694:	e426                	sd	s1,8(sp)
    80004696:	e04a                	sd	s2,0(sp)
    80004698:	1000                	addi	s0,sp,32
    8000469a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000469c:	00850913          	addi	s2,a0,8
    800046a0:	854a                	mv	a0,s2
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	548080e7          	jalr	1352(ra) # 80000bea <acquire>
  while (lk->locked) {
    800046aa:	409c                	lw	a5,0(s1)
    800046ac:	cb89                	beqz	a5,800046be <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046ae:	85ca                	mv	a1,s2
    800046b0:	8526                	mv	a0,s1
    800046b2:	ffffe097          	auipc	ra,0xffffe
    800046b6:	a48080e7          	jalr	-1464(ra) # 800020fa <sleep>
  while (lk->locked) {
    800046ba:	409c                	lw	a5,0(s1)
    800046bc:	fbed                	bnez	a5,800046ae <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046be:	4785                	li	a5,1
    800046c0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046c2:	ffffd097          	auipc	ra,0xffffd
    800046c6:	304080e7          	jalr	772(ra) # 800019c6 <myproc>
    800046ca:	591c                	lw	a5,48(a0)
    800046cc:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046ce:	854a                	mv	a0,s2
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	5ce080e7          	jalr	1486(ra) # 80000c9e <release>
}
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6902                	ld	s2,0(sp)
    800046e0:	6105                	addi	sp,sp,32
    800046e2:	8082                	ret

00000000800046e4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046e4:	1101                	addi	sp,sp,-32
    800046e6:	ec06                	sd	ra,24(sp)
    800046e8:	e822                	sd	s0,16(sp)
    800046ea:	e426                	sd	s1,8(sp)
    800046ec:	e04a                	sd	s2,0(sp)
    800046ee:	1000                	addi	s0,sp,32
    800046f0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046f2:	00850913          	addi	s2,a0,8
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	4f2080e7          	jalr	1266(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004700:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004704:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004708:	8526                	mv	a0,s1
    8000470a:	ffffe097          	auipc	ra,0xffffe
    8000470e:	b9c080e7          	jalr	-1124(ra) # 800022a6 <wakeup>
  release(&lk->lk);
    80004712:	854a                	mv	a0,s2
    80004714:	ffffc097          	auipc	ra,0xffffc
    80004718:	58a080e7          	jalr	1418(ra) # 80000c9e <release>
}
    8000471c:	60e2                	ld	ra,24(sp)
    8000471e:	6442                	ld	s0,16(sp)
    80004720:	64a2                	ld	s1,8(sp)
    80004722:	6902                	ld	s2,0(sp)
    80004724:	6105                	addi	sp,sp,32
    80004726:	8082                	ret

0000000080004728 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004728:	7179                	addi	sp,sp,-48
    8000472a:	f406                	sd	ra,40(sp)
    8000472c:	f022                	sd	s0,32(sp)
    8000472e:	ec26                	sd	s1,24(sp)
    80004730:	e84a                	sd	s2,16(sp)
    80004732:	e44e                	sd	s3,8(sp)
    80004734:	1800                	addi	s0,sp,48
    80004736:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004738:	00850913          	addi	s2,a0,8
    8000473c:	854a                	mv	a0,s2
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	4ac080e7          	jalr	1196(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004746:	409c                	lw	a5,0(s1)
    80004748:	ef99                	bnez	a5,80004766 <holdingsleep+0x3e>
    8000474a:	4481                	li	s1,0
  release(&lk->lk);
    8000474c:	854a                	mv	a0,s2
    8000474e:	ffffc097          	auipc	ra,0xffffc
    80004752:	550080e7          	jalr	1360(ra) # 80000c9e <release>
  return r;
}
    80004756:	8526                	mv	a0,s1
    80004758:	70a2                	ld	ra,40(sp)
    8000475a:	7402                	ld	s0,32(sp)
    8000475c:	64e2                	ld	s1,24(sp)
    8000475e:	6942                	ld	s2,16(sp)
    80004760:	69a2                	ld	s3,8(sp)
    80004762:	6145                	addi	sp,sp,48
    80004764:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004766:	0284a983          	lw	s3,40(s1)
    8000476a:	ffffd097          	auipc	ra,0xffffd
    8000476e:	25c080e7          	jalr	604(ra) # 800019c6 <myproc>
    80004772:	5904                	lw	s1,48(a0)
    80004774:	413484b3          	sub	s1,s1,s3
    80004778:	0014b493          	seqz	s1,s1
    8000477c:	bfc1                	j	8000474c <holdingsleep+0x24>

000000008000477e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000477e:	1141                	addi	sp,sp,-16
    80004780:	e406                	sd	ra,8(sp)
    80004782:	e022                	sd	s0,0(sp)
    80004784:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004786:	00004597          	auipc	a1,0x4
    8000478a:	14258593          	addi	a1,a1,322 # 800088c8 <syscall_argc+0x1f0>
    8000478e:	0001e517          	auipc	a0,0x1e
    80004792:	d2250513          	addi	a0,a0,-734 # 800224b0 <ftable>
    80004796:	ffffc097          	auipc	ra,0xffffc
    8000479a:	3c4080e7          	jalr	964(ra) # 80000b5a <initlock>
}
    8000479e:	60a2                	ld	ra,8(sp)
    800047a0:	6402                	ld	s0,0(sp)
    800047a2:	0141                	addi	sp,sp,16
    800047a4:	8082                	ret

00000000800047a6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047a6:	1101                	addi	sp,sp,-32
    800047a8:	ec06                	sd	ra,24(sp)
    800047aa:	e822                	sd	s0,16(sp)
    800047ac:	e426                	sd	s1,8(sp)
    800047ae:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047b0:	0001e517          	auipc	a0,0x1e
    800047b4:	d0050513          	addi	a0,a0,-768 # 800224b0 <ftable>
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	432080e7          	jalr	1074(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c0:	0001e497          	auipc	s1,0x1e
    800047c4:	d0848493          	addi	s1,s1,-760 # 800224c8 <ftable+0x18>
    800047c8:	0001f717          	auipc	a4,0x1f
    800047cc:	ca070713          	addi	a4,a4,-864 # 80023468 <disk>
    if(f->ref == 0){
    800047d0:	40dc                	lw	a5,4(s1)
    800047d2:	cf99                	beqz	a5,800047f0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d4:	02848493          	addi	s1,s1,40
    800047d8:	fee49ce3          	bne	s1,a4,800047d0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047dc:	0001e517          	auipc	a0,0x1e
    800047e0:	cd450513          	addi	a0,a0,-812 # 800224b0 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4ba080e7          	jalr	1210(ra) # 80000c9e <release>
  return 0;
    800047ec:	4481                	li	s1,0
    800047ee:	a819                	j	80004804 <filealloc+0x5e>
      f->ref = 1;
    800047f0:	4785                	li	a5,1
    800047f2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047f4:	0001e517          	auipc	a0,0x1e
    800047f8:	cbc50513          	addi	a0,a0,-836 # 800224b0 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	4a2080e7          	jalr	1186(ra) # 80000c9e <release>
}
    80004804:	8526                	mv	a0,s1
    80004806:	60e2                	ld	ra,24(sp)
    80004808:	6442                	ld	s0,16(sp)
    8000480a:	64a2                	ld	s1,8(sp)
    8000480c:	6105                	addi	sp,sp,32
    8000480e:	8082                	ret

0000000080004810 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004810:	1101                	addi	sp,sp,-32
    80004812:	ec06                	sd	ra,24(sp)
    80004814:	e822                	sd	s0,16(sp)
    80004816:	e426                	sd	s1,8(sp)
    80004818:	1000                	addi	s0,sp,32
    8000481a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000481c:	0001e517          	auipc	a0,0x1e
    80004820:	c9450513          	addi	a0,a0,-876 # 800224b0 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3c6080e7          	jalr	966(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	02f05263          	blez	a5,80004852 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004832:	2785                	addiw	a5,a5,1
    80004834:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004836:	0001e517          	auipc	a0,0x1e
    8000483a:	c7a50513          	addi	a0,a0,-902 # 800224b0 <ftable>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	460080e7          	jalr	1120(ra) # 80000c9e <release>
  return f;
}
    80004846:	8526                	mv	a0,s1
    80004848:	60e2                	ld	ra,24(sp)
    8000484a:	6442                	ld	s0,16(sp)
    8000484c:	64a2                	ld	s1,8(sp)
    8000484e:	6105                	addi	sp,sp,32
    80004850:	8082                	ret
    panic("filedup");
    80004852:	00004517          	auipc	a0,0x4
    80004856:	07e50513          	addi	a0,a0,126 # 800088d0 <syscall_argc+0x1f8>
    8000485a:	ffffc097          	auipc	ra,0xffffc
    8000485e:	cea080e7          	jalr	-790(ra) # 80000544 <panic>

0000000080004862 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004862:	7139                	addi	sp,sp,-64
    80004864:	fc06                	sd	ra,56(sp)
    80004866:	f822                	sd	s0,48(sp)
    80004868:	f426                	sd	s1,40(sp)
    8000486a:	f04a                	sd	s2,32(sp)
    8000486c:	ec4e                	sd	s3,24(sp)
    8000486e:	e852                	sd	s4,16(sp)
    80004870:	e456                	sd	s5,8(sp)
    80004872:	0080                	addi	s0,sp,64
    80004874:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004876:	0001e517          	auipc	a0,0x1e
    8000487a:	c3a50513          	addi	a0,a0,-966 # 800224b0 <ftable>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	36c080e7          	jalr	876(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004886:	40dc                	lw	a5,4(s1)
    80004888:	06f05163          	blez	a5,800048ea <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000488c:	37fd                	addiw	a5,a5,-1
    8000488e:	0007871b          	sext.w	a4,a5
    80004892:	c0dc                	sw	a5,4(s1)
    80004894:	06e04363          	bgtz	a4,800048fa <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004898:	0004a903          	lw	s2,0(s1)
    8000489c:	0094ca83          	lbu	s5,9(s1)
    800048a0:	0104ba03          	ld	s4,16(s1)
    800048a4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048a8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048ac:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048b0:	0001e517          	auipc	a0,0x1e
    800048b4:	c0050513          	addi	a0,a0,-1024 # 800224b0 <ftable>
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	3e6080e7          	jalr	998(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800048c0:	4785                	li	a5,1
    800048c2:	04f90d63          	beq	s2,a5,8000491c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048c6:	3979                	addiw	s2,s2,-2
    800048c8:	4785                	li	a5,1
    800048ca:	0527e063          	bltu	a5,s2,8000490a <fileclose+0xa8>
    begin_op();
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	ac8080e7          	jalr	-1336(ra) # 80004396 <begin_op>
    iput(ff.ip);
    800048d6:	854e                	mv	a0,s3
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	2b6080e7          	jalr	694(ra) # 80003b8e <iput>
    end_op();
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	b36080e7          	jalr	-1226(ra) # 80004416 <end_op>
    800048e8:	a00d                	j	8000490a <fileclose+0xa8>
    panic("fileclose");
    800048ea:	00004517          	auipc	a0,0x4
    800048ee:	fee50513          	addi	a0,a0,-18 # 800088d8 <syscall_argc+0x200>
    800048f2:	ffffc097          	auipc	ra,0xffffc
    800048f6:	c52080e7          	jalr	-942(ra) # 80000544 <panic>
    release(&ftable.lock);
    800048fa:	0001e517          	auipc	a0,0x1e
    800048fe:	bb650513          	addi	a0,a0,-1098 # 800224b0 <ftable>
    80004902:	ffffc097          	auipc	ra,0xffffc
    80004906:	39c080e7          	jalr	924(ra) # 80000c9e <release>
  }
}
    8000490a:	70e2                	ld	ra,56(sp)
    8000490c:	7442                	ld	s0,48(sp)
    8000490e:	74a2                	ld	s1,40(sp)
    80004910:	7902                	ld	s2,32(sp)
    80004912:	69e2                	ld	s3,24(sp)
    80004914:	6a42                	ld	s4,16(sp)
    80004916:	6aa2                	ld	s5,8(sp)
    80004918:	6121                	addi	sp,sp,64
    8000491a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000491c:	85d6                	mv	a1,s5
    8000491e:	8552                	mv	a0,s4
    80004920:	00000097          	auipc	ra,0x0
    80004924:	34c080e7          	jalr	844(ra) # 80004c6c <pipeclose>
    80004928:	b7cd                	j	8000490a <fileclose+0xa8>

000000008000492a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000492a:	715d                	addi	sp,sp,-80
    8000492c:	e486                	sd	ra,72(sp)
    8000492e:	e0a2                	sd	s0,64(sp)
    80004930:	fc26                	sd	s1,56(sp)
    80004932:	f84a                	sd	s2,48(sp)
    80004934:	f44e                	sd	s3,40(sp)
    80004936:	0880                	addi	s0,sp,80
    80004938:	84aa                	mv	s1,a0
    8000493a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000493c:	ffffd097          	auipc	ra,0xffffd
    80004940:	08a080e7          	jalr	138(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004944:	409c                	lw	a5,0(s1)
    80004946:	37f9                	addiw	a5,a5,-2
    80004948:	4705                	li	a4,1
    8000494a:	04f76763          	bltu	a4,a5,80004998 <filestat+0x6e>
    8000494e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004950:	6c88                	ld	a0,24(s1)
    80004952:	fffff097          	auipc	ra,0xfffff
    80004956:	082080e7          	jalr	130(ra) # 800039d4 <ilock>
    stati(f->ip, &st);
    8000495a:	fb840593          	addi	a1,s0,-72
    8000495e:	6c88                	ld	a0,24(s1)
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	2fe080e7          	jalr	766(ra) # 80003c5e <stati>
    iunlock(f->ip);
    80004968:	6c88                	ld	a0,24(s1)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	12c080e7          	jalr	300(ra) # 80003a96 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004972:	46e1                	li	a3,24
    80004974:	fb840613          	addi	a2,s0,-72
    80004978:	85ce                	mv	a1,s3
    8000497a:	05893503          	ld	a0,88(s2)
    8000497e:	ffffd097          	auipc	ra,0xffffd
    80004982:	d06080e7          	jalr	-762(ra) # 80001684 <copyout>
    80004986:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000498a:	60a6                	ld	ra,72(sp)
    8000498c:	6406                	ld	s0,64(sp)
    8000498e:	74e2                	ld	s1,56(sp)
    80004990:	7942                	ld	s2,48(sp)
    80004992:	79a2                	ld	s3,40(sp)
    80004994:	6161                	addi	sp,sp,80
    80004996:	8082                	ret
  return -1;
    80004998:	557d                	li	a0,-1
    8000499a:	bfc5                	j	8000498a <filestat+0x60>

000000008000499c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000499c:	7179                	addi	sp,sp,-48
    8000499e:	f406                	sd	ra,40(sp)
    800049a0:	f022                	sd	s0,32(sp)
    800049a2:	ec26                	sd	s1,24(sp)
    800049a4:	e84a                	sd	s2,16(sp)
    800049a6:	e44e                	sd	s3,8(sp)
    800049a8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049aa:	00854783          	lbu	a5,8(a0)
    800049ae:	c3d5                	beqz	a5,80004a52 <fileread+0xb6>
    800049b0:	84aa                	mv	s1,a0
    800049b2:	89ae                	mv	s3,a1
    800049b4:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b6:	411c                	lw	a5,0(a0)
    800049b8:	4705                	li	a4,1
    800049ba:	04e78963          	beq	a5,a4,80004a0c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049be:	470d                	li	a4,3
    800049c0:	04e78d63          	beq	a5,a4,80004a1a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c4:	4709                	li	a4,2
    800049c6:	06e79e63          	bne	a5,a4,80004a42 <fileread+0xa6>
    ilock(f->ip);
    800049ca:	6d08                	ld	a0,24(a0)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	008080e7          	jalr	8(ra) # 800039d4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049d4:	874a                	mv	a4,s2
    800049d6:	5094                	lw	a3,32(s1)
    800049d8:	864e                	mv	a2,s3
    800049da:	4585                	li	a1,1
    800049dc:	6c88                	ld	a0,24(s1)
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	2aa080e7          	jalr	682(ra) # 80003c88 <readi>
    800049e6:	892a                	mv	s2,a0
    800049e8:	00a05563          	blez	a0,800049f2 <fileread+0x56>
      f->off += r;
    800049ec:	509c                	lw	a5,32(s1)
    800049ee:	9fa9                	addw	a5,a5,a0
    800049f0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049f2:	6c88                	ld	a0,24(s1)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	0a2080e7          	jalr	162(ra) # 80003a96 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049fc:	854a                	mv	a0,s2
    800049fe:	70a2                	ld	ra,40(sp)
    80004a00:	7402                	ld	s0,32(sp)
    80004a02:	64e2                	ld	s1,24(sp)
    80004a04:	6942                	ld	s2,16(sp)
    80004a06:	69a2                	ld	s3,8(sp)
    80004a08:	6145                	addi	sp,sp,48
    80004a0a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a0c:	6908                	ld	a0,16(a0)
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	3ce080e7          	jalr	974(ra) # 80004ddc <piperead>
    80004a16:	892a                	mv	s2,a0
    80004a18:	b7d5                	j	800049fc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a1a:	02451783          	lh	a5,36(a0)
    80004a1e:	03079693          	slli	a3,a5,0x30
    80004a22:	92c1                	srli	a3,a3,0x30
    80004a24:	4725                	li	a4,9
    80004a26:	02d76863          	bltu	a4,a3,80004a56 <fileread+0xba>
    80004a2a:	0792                	slli	a5,a5,0x4
    80004a2c:	0001e717          	auipc	a4,0x1e
    80004a30:	9e470713          	addi	a4,a4,-1564 # 80022410 <devsw>
    80004a34:	97ba                	add	a5,a5,a4
    80004a36:	639c                	ld	a5,0(a5)
    80004a38:	c38d                	beqz	a5,80004a5a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a3a:	4505                	li	a0,1
    80004a3c:	9782                	jalr	a5
    80004a3e:	892a                	mv	s2,a0
    80004a40:	bf75                	j	800049fc <fileread+0x60>
    panic("fileread");
    80004a42:	00004517          	auipc	a0,0x4
    80004a46:	ea650513          	addi	a0,a0,-346 # 800088e8 <syscall_argc+0x210>
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	afa080e7          	jalr	-1286(ra) # 80000544 <panic>
    return -1;
    80004a52:	597d                	li	s2,-1
    80004a54:	b765                	j	800049fc <fileread+0x60>
      return -1;
    80004a56:	597d                	li	s2,-1
    80004a58:	b755                	j	800049fc <fileread+0x60>
    80004a5a:	597d                	li	s2,-1
    80004a5c:	b745                	j	800049fc <fileread+0x60>

0000000080004a5e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a5e:	715d                	addi	sp,sp,-80
    80004a60:	e486                	sd	ra,72(sp)
    80004a62:	e0a2                	sd	s0,64(sp)
    80004a64:	fc26                	sd	s1,56(sp)
    80004a66:	f84a                	sd	s2,48(sp)
    80004a68:	f44e                	sd	s3,40(sp)
    80004a6a:	f052                	sd	s4,32(sp)
    80004a6c:	ec56                	sd	s5,24(sp)
    80004a6e:	e85a                	sd	s6,16(sp)
    80004a70:	e45e                	sd	s7,8(sp)
    80004a72:	e062                	sd	s8,0(sp)
    80004a74:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a76:	00954783          	lbu	a5,9(a0)
    80004a7a:	10078663          	beqz	a5,80004b86 <filewrite+0x128>
    80004a7e:	892a                	mv	s2,a0
    80004a80:	8aae                	mv	s5,a1
    80004a82:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a84:	411c                	lw	a5,0(a0)
    80004a86:	4705                	li	a4,1
    80004a88:	02e78263          	beq	a5,a4,80004aac <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a8c:	470d                	li	a4,3
    80004a8e:	02e78663          	beq	a5,a4,80004aba <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a92:	4709                	li	a4,2
    80004a94:	0ee79163          	bne	a5,a4,80004b76 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a98:	0ac05d63          	blez	a2,80004b52 <filewrite+0xf4>
    int i = 0;
    80004a9c:	4981                	li	s3,0
    80004a9e:	6b05                	lui	s6,0x1
    80004aa0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004aa4:	6b85                	lui	s7,0x1
    80004aa6:	c00b8b9b          	addiw	s7,s7,-1024
    80004aaa:	a861                	j	80004b42 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004aac:	6908                	ld	a0,16(a0)
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	22e080e7          	jalr	558(ra) # 80004cdc <pipewrite>
    80004ab6:	8a2a                	mv	s4,a0
    80004ab8:	a045                	j	80004b58 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aba:	02451783          	lh	a5,36(a0)
    80004abe:	03079693          	slli	a3,a5,0x30
    80004ac2:	92c1                	srli	a3,a3,0x30
    80004ac4:	4725                	li	a4,9
    80004ac6:	0cd76263          	bltu	a4,a3,80004b8a <filewrite+0x12c>
    80004aca:	0792                	slli	a5,a5,0x4
    80004acc:	0001e717          	auipc	a4,0x1e
    80004ad0:	94470713          	addi	a4,a4,-1724 # 80022410 <devsw>
    80004ad4:	97ba                	add	a5,a5,a4
    80004ad6:	679c                	ld	a5,8(a5)
    80004ad8:	cbdd                	beqz	a5,80004b8e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ada:	4505                	li	a0,1
    80004adc:	9782                	jalr	a5
    80004ade:	8a2a                	mv	s4,a0
    80004ae0:	a8a5                	j	80004b58 <filewrite+0xfa>
    80004ae2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ae6:	00000097          	auipc	ra,0x0
    80004aea:	8b0080e7          	jalr	-1872(ra) # 80004396 <begin_op>
      ilock(f->ip);
    80004aee:	01893503          	ld	a0,24(s2)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	ee2080e7          	jalr	-286(ra) # 800039d4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004afa:	8762                	mv	a4,s8
    80004afc:	02092683          	lw	a3,32(s2)
    80004b00:	01598633          	add	a2,s3,s5
    80004b04:	4585                	li	a1,1
    80004b06:	01893503          	ld	a0,24(s2)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	276080e7          	jalr	630(ra) # 80003d80 <writei>
    80004b12:	84aa                	mv	s1,a0
    80004b14:	00a05763          	blez	a0,80004b22 <filewrite+0xc4>
        f->off += r;
    80004b18:	02092783          	lw	a5,32(s2)
    80004b1c:	9fa9                	addw	a5,a5,a0
    80004b1e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b22:	01893503          	ld	a0,24(s2)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	f70080e7          	jalr	-144(ra) # 80003a96 <iunlock>
      end_op();
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	8e8080e7          	jalr	-1816(ra) # 80004416 <end_op>

      if(r != n1){
    80004b36:	009c1f63          	bne	s8,s1,80004b54 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b3a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b3e:	0149db63          	bge	s3,s4,80004b54 <filewrite+0xf6>
      int n1 = n - i;
    80004b42:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b46:	84be                	mv	s1,a5
    80004b48:	2781                	sext.w	a5,a5
    80004b4a:	f8fb5ce3          	bge	s6,a5,80004ae2 <filewrite+0x84>
    80004b4e:	84de                	mv	s1,s7
    80004b50:	bf49                	j	80004ae2 <filewrite+0x84>
    int i = 0;
    80004b52:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b54:	013a1f63          	bne	s4,s3,80004b72 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b58:	8552                	mv	a0,s4
    80004b5a:	60a6                	ld	ra,72(sp)
    80004b5c:	6406                	ld	s0,64(sp)
    80004b5e:	74e2                	ld	s1,56(sp)
    80004b60:	7942                	ld	s2,48(sp)
    80004b62:	79a2                	ld	s3,40(sp)
    80004b64:	7a02                	ld	s4,32(sp)
    80004b66:	6ae2                	ld	s5,24(sp)
    80004b68:	6b42                	ld	s6,16(sp)
    80004b6a:	6ba2                	ld	s7,8(sp)
    80004b6c:	6c02                	ld	s8,0(sp)
    80004b6e:	6161                	addi	sp,sp,80
    80004b70:	8082                	ret
    ret = (i == n ? n : -1);
    80004b72:	5a7d                	li	s4,-1
    80004b74:	b7d5                	j	80004b58 <filewrite+0xfa>
    panic("filewrite");
    80004b76:	00004517          	auipc	a0,0x4
    80004b7a:	d8250513          	addi	a0,a0,-638 # 800088f8 <syscall_argc+0x220>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	9c6080e7          	jalr	-1594(ra) # 80000544 <panic>
    return -1;
    80004b86:	5a7d                	li	s4,-1
    80004b88:	bfc1                	j	80004b58 <filewrite+0xfa>
      return -1;
    80004b8a:	5a7d                	li	s4,-1
    80004b8c:	b7f1                	j	80004b58 <filewrite+0xfa>
    80004b8e:	5a7d                	li	s4,-1
    80004b90:	b7e1                	j	80004b58 <filewrite+0xfa>

0000000080004b92 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b92:	7179                	addi	sp,sp,-48
    80004b94:	f406                	sd	ra,40(sp)
    80004b96:	f022                	sd	s0,32(sp)
    80004b98:	ec26                	sd	s1,24(sp)
    80004b9a:	e84a                	sd	s2,16(sp)
    80004b9c:	e44e                	sd	s3,8(sp)
    80004b9e:	e052                	sd	s4,0(sp)
    80004ba0:	1800                	addi	s0,sp,48
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ba6:	0005b023          	sd	zero,0(a1)
    80004baa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bae:	00000097          	auipc	ra,0x0
    80004bb2:	bf8080e7          	jalr	-1032(ra) # 800047a6 <filealloc>
    80004bb6:	e088                	sd	a0,0(s1)
    80004bb8:	c551                	beqz	a0,80004c44 <pipealloc+0xb2>
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	bec080e7          	jalr	-1044(ra) # 800047a6 <filealloc>
    80004bc2:	00aa3023          	sd	a0,0(s4)
    80004bc6:	c92d                	beqz	a0,80004c38 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bc8:	ffffc097          	auipc	ra,0xffffc
    80004bcc:	f32080e7          	jalr	-206(ra) # 80000afa <kalloc>
    80004bd0:	892a                	mv	s2,a0
    80004bd2:	c125                	beqz	a0,80004c32 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bd4:	4985                	li	s3,1
    80004bd6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bda:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bde:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004be2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004be6:	00004597          	auipc	a1,0x4
    80004bea:	8a258593          	addi	a1,a1,-1886 # 80008488 <states.1773+0x1c0>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	f6c080e7          	jalr	-148(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004bf6:	609c                	ld	a5,0(s1)
    80004bf8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004bfc:	609c                	ld	a5,0(s1)
    80004bfe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c02:	609c                	ld	a5,0(s1)
    80004c04:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c08:	609c                	ld	a5,0(s1)
    80004c0a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c0e:	000a3783          	ld	a5,0(s4)
    80004c12:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c16:	000a3783          	ld	a5,0(s4)
    80004c1a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c1e:	000a3783          	ld	a5,0(s4)
    80004c22:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c26:	000a3783          	ld	a5,0(s4)
    80004c2a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c2e:	4501                	li	a0,0
    80004c30:	a025                	j	80004c58 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c32:	6088                	ld	a0,0(s1)
    80004c34:	e501                	bnez	a0,80004c3c <pipealloc+0xaa>
    80004c36:	a039                	j	80004c44 <pipealloc+0xb2>
    80004c38:	6088                	ld	a0,0(s1)
    80004c3a:	c51d                	beqz	a0,80004c68 <pipealloc+0xd6>
    fileclose(*f0);
    80004c3c:	00000097          	auipc	ra,0x0
    80004c40:	c26080e7          	jalr	-986(ra) # 80004862 <fileclose>
  if(*f1)
    80004c44:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c48:	557d                	li	a0,-1
  if(*f1)
    80004c4a:	c799                	beqz	a5,80004c58 <pipealloc+0xc6>
    fileclose(*f1);
    80004c4c:	853e                	mv	a0,a5
    80004c4e:	00000097          	auipc	ra,0x0
    80004c52:	c14080e7          	jalr	-1004(ra) # 80004862 <fileclose>
  return -1;
    80004c56:	557d                	li	a0,-1
}
    80004c58:	70a2                	ld	ra,40(sp)
    80004c5a:	7402                	ld	s0,32(sp)
    80004c5c:	64e2                	ld	s1,24(sp)
    80004c5e:	6942                	ld	s2,16(sp)
    80004c60:	69a2                	ld	s3,8(sp)
    80004c62:	6a02                	ld	s4,0(sp)
    80004c64:	6145                	addi	sp,sp,48
    80004c66:	8082                	ret
  return -1;
    80004c68:	557d                	li	a0,-1
    80004c6a:	b7fd                	j	80004c58 <pipealloc+0xc6>

0000000080004c6c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c6c:	1101                	addi	sp,sp,-32
    80004c6e:	ec06                	sd	ra,24(sp)
    80004c70:	e822                	sd	s0,16(sp)
    80004c72:	e426                	sd	s1,8(sp)
    80004c74:	e04a                	sd	s2,0(sp)
    80004c76:	1000                	addi	s0,sp,32
    80004c78:	84aa                	mv	s1,a0
    80004c7a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	f6e080e7          	jalr	-146(ra) # 80000bea <acquire>
  if(writable){
    80004c84:	02090d63          	beqz	s2,80004cbe <pipeclose+0x52>
    pi->writeopen = 0;
    80004c88:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c8c:	21848513          	addi	a0,s1,536
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	616080e7          	jalr	1558(ra) # 800022a6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c98:	2204b783          	ld	a5,544(s1)
    80004c9c:	eb95                	bnez	a5,80004cd0 <pipeclose+0x64>
    release(&pi->lock);
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	ffe080e7          	jalr	-2(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	d54080e7          	jalr	-684(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004cb2:	60e2                	ld	ra,24(sp)
    80004cb4:	6442                	ld	s0,16(sp)
    80004cb6:	64a2                	ld	s1,8(sp)
    80004cb8:	6902                	ld	s2,0(sp)
    80004cba:	6105                	addi	sp,sp,32
    80004cbc:	8082                	ret
    pi->readopen = 0;
    80004cbe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cc2:	21c48513          	addi	a0,s1,540
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	5e0080e7          	jalr	1504(ra) # 800022a6 <wakeup>
    80004cce:	b7e9                	j	80004c98 <pipeclose+0x2c>
    release(&pi->lock);
    80004cd0:	8526                	mv	a0,s1
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	fcc080e7          	jalr	-52(ra) # 80000c9e <release>
}
    80004cda:	bfe1                	j	80004cb2 <pipeclose+0x46>

0000000080004cdc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cdc:	7159                	addi	sp,sp,-112
    80004cde:	f486                	sd	ra,104(sp)
    80004ce0:	f0a2                	sd	s0,96(sp)
    80004ce2:	eca6                	sd	s1,88(sp)
    80004ce4:	e8ca                	sd	s2,80(sp)
    80004ce6:	e4ce                	sd	s3,72(sp)
    80004ce8:	e0d2                	sd	s4,64(sp)
    80004cea:	fc56                	sd	s5,56(sp)
    80004cec:	f85a                	sd	s6,48(sp)
    80004cee:	f45e                	sd	s7,40(sp)
    80004cf0:	f062                	sd	s8,32(sp)
    80004cf2:	ec66                	sd	s9,24(sp)
    80004cf4:	1880                	addi	s0,sp,112
    80004cf6:	84aa                	mv	s1,a0
    80004cf8:	8aae                	mv	s5,a1
    80004cfa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	cca080e7          	jalr	-822(ra) # 800019c6 <myproc>
    80004d04:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d06:	8526                	mv	a0,s1
    80004d08:	ffffc097          	auipc	ra,0xffffc
    80004d0c:	ee2080e7          	jalr	-286(ra) # 80000bea <acquire>
  while(i < n){
    80004d10:	0d405463          	blez	s4,80004dd8 <pipewrite+0xfc>
    80004d14:	8ba6                	mv	s7,s1
  int i = 0;
    80004d16:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d18:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d1a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d1e:	21c48c13          	addi	s8,s1,540
    80004d22:	a08d                	j	80004d84 <pipewrite+0xa8>
      release(&pi->lock);
    80004d24:	8526                	mv	a0,s1
    80004d26:	ffffc097          	auipc	ra,0xffffc
    80004d2a:	f78080e7          	jalr	-136(ra) # 80000c9e <release>
      return -1;
    80004d2e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d30:	854a                	mv	a0,s2
    80004d32:	70a6                	ld	ra,104(sp)
    80004d34:	7406                	ld	s0,96(sp)
    80004d36:	64e6                	ld	s1,88(sp)
    80004d38:	6946                	ld	s2,80(sp)
    80004d3a:	69a6                	ld	s3,72(sp)
    80004d3c:	6a06                	ld	s4,64(sp)
    80004d3e:	7ae2                	ld	s5,56(sp)
    80004d40:	7b42                	ld	s6,48(sp)
    80004d42:	7ba2                	ld	s7,40(sp)
    80004d44:	7c02                	ld	s8,32(sp)
    80004d46:	6ce2                	ld	s9,24(sp)
    80004d48:	6165                	addi	sp,sp,112
    80004d4a:	8082                	ret
      wakeup(&pi->nread);
    80004d4c:	8566                	mv	a0,s9
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	558080e7          	jalr	1368(ra) # 800022a6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d56:	85de                	mv	a1,s7
    80004d58:	8562                	mv	a0,s8
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	3a0080e7          	jalr	928(ra) # 800020fa <sleep>
    80004d62:	a839                	j	80004d80 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d64:	21c4a783          	lw	a5,540(s1)
    80004d68:	0017871b          	addiw	a4,a5,1
    80004d6c:	20e4ae23          	sw	a4,540(s1)
    80004d70:	1ff7f793          	andi	a5,a5,511
    80004d74:	97a6                	add	a5,a5,s1
    80004d76:	f9f44703          	lbu	a4,-97(s0)
    80004d7a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d7e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d80:	05495063          	bge	s2,s4,80004dc0 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004d84:	2204a783          	lw	a5,544(s1)
    80004d88:	dfd1                	beqz	a5,80004d24 <pipewrite+0x48>
    80004d8a:	854e                	mv	a0,s3
    80004d8c:	ffffd097          	auipc	ra,0xffffd
    80004d90:	76a080e7          	jalr	1898(ra) # 800024f6 <killed>
    80004d94:	f941                	bnez	a0,80004d24 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d96:	2184a783          	lw	a5,536(s1)
    80004d9a:	21c4a703          	lw	a4,540(s1)
    80004d9e:	2007879b          	addiw	a5,a5,512
    80004da2:	faf705e3          	beq	a4,a5,80004d4c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004da6:	4685                	li	a3,1
    80004da8:	01590633          	add	a2,s2,s5
    80004dac:	f9f40593          	addi	a1,s0,-97
    80004db0:	0589b503          	ld	a0,88(s3)
    80004db4:	ffffd097          	auipc	ra,0xffffd
    80004db8:	95c080e7          	jalr	-1700(ra) # 80001710 <copyin>
    80004dbc:	fb6514e3          	bne	a0,s6,80004d64 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004dc0:	21848513          	addi	a0,s1,536
    80004dc4:	ffffd097          	auipc	ra,0xffffd
    80004dc8:	4e2080e7          	jalr	1250(ra) # 800022a6 <wakeup>
  release(&pi->lock);
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	ed0080e7          	jalr	-304(ra) # 80000c9e <release>
  return i;
    80004dd6:	bfa9                	j	80004d30 <pipewrite+0x54>
  int i = 0;
    80004dd8:	4901                	li	s2,0
    80004dda:	b7dd                	j	80004dc0 <pipewrite+0xe4>

0000000080004ddc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ddc:	715d                	addi	sp,sp,-80
    80004dde:	e486                	sd	ra,72(sp)
    80004de0:	e0a2                	sd	s0,64(sp)
    80004de2:	fc26                	sd	s1,56(sp)
    80004de4:	f84a                	sd	s2,48(sp)
    80004de6:	f44e                	sd	s3,40(sp)
    80004de8:	f052                	sd	s4,32(sp)
    80004dea:	ec56                	sd	s5,24(sp)
    80004dec:	e85a                	sd	s6,16(sp)
    80004dee:	0880                	addi	s0,sp,80
    80004df0:	84aa                	mv	s1,a0
    80004df2:	892e                	mv	s2,a1
    80004df4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004df6:	ffffd097          	auipc	ra,0xffffd
    80004dfa:	bd0080e7          	jalr	-1072(ra) # 800019c6 <myproc>
    80004dfe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e00:	8b26                	mv	s6,s1
    80004e02:	8526                	mv	a0,s1
    80004e04:	ffffc097          	auipc	ra,0xffffc
    80004e08:	de6080e7          	jalr	-538(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e0c:	2184a703          	lw	a4,536(s1)
    80004e10:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e14:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e18:	02f71763          	bne	a4,a5,80004e46 <piperead+0x6a>
    80004e1c:	2244a783          	lw	a5,548(s1)
    80004e20:	c39d                	beqz	a5,80004e46 <piperead+0x6a>
    if(killed(pr)){
    80004e22:	8552                	mv	a0,s4
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	6d2080e7          	jalr	1746(ra) # 800024f6 <killed>
    80004e2c:	e941                	bnez	a0,80004ebc <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2e:	85da                	mv	a1,s6
    80004e30:	854e                	mv	a0,s3
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	2c8080e7          	jalr	712(ra) # 800020fa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e3a:	2184a703          	lw	a4,536(s1)
    80004e3e:	21c4a783          	lw	a5,540(s1)
    80004e42:	fcf70de3          	beq	a4,a5,80004e1c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e46:	09505263          	blez	s5,80004eca <piperead+0xee>
    80004e4a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e4c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e4e:	2184a783          	lw	a5,536(s1)
    80004e52:	21c4a703          	lw	a4,540(s1)
    80004e56:	02f70d63          	beq	a4,a5,80004e90 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e5a:	0017871b          	addiw	a4,a5,1
    80004e5e:	20e4ac23          	sw	a4,536(s1)
    80004e62:	1ff7f793          	andi	a5,a5,511
    80004e66:	97a6                	add	a5,a5,s1
    80004e68:	0187c783          	lbu	a5,24(a5)
    80004e6c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e70:	4685                	li	a3,1
    80004e72:	fbf40613          	addi	a2,s0,-65
    80004e76:	85ca                	mv	a1,s2
    80004e78:	058a3503          	ld	a0,88(s4)
    80004e7c:	ffffd097          	auipc	ra,0xffffd
    80004e80:	808080e7          	jalr	-2040(ra) # 80001684 <copyout>
    80004e84:	01650663          	beq	a0,s6,80004e90 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e88:	2985                	addiw	s3,s3,1
    80004e8a:	0905                	addi	s2,s2,1
    80004e8c:	fd3a91e3          	bne	s5,s3,80004e4e <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e90:	21c48513          	addi	a0,s1,540
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	412080e7          	jalr	1042(ra) # 800022a6 <wakeup>
  release(&pi->lock);
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	e00080e7          	jalr	-512(ra) # 80000c9e <release>
  return i;
}
    80004ea6:	854e                	mv	a0,s3
    80004ea8:	60a6                	ld	ra,72(sp)
    80004eaa:	6406                	ld	s0,64(sp)
    80004eac:	74e2                	ld	s1,56(sp)
    80004eae:	7942                	ld	s2,48(sp)
    80004eb0:	79a2                	ld	s3,40(sp)
    80004eb2:	7a02                	ld	s4,32(sp)
    80004eb4:	6ae2                	ld	s5,24(sp)
    80004eb6:	6b42                	ld	s6,16(sp)
    80004eb8:	6161                	addi	sp,sp,80
    80004eba:	8082                	ret
      release(&pi->lock);
    80004ebc:	8526                	mv	a0,s1
    80004ebe:	ffffc097          	auipc	ra,0xffffc
    80004ec2:	de0080e7          	jalr	-544(ra) # 80000c9e <release>
      return -1;
    80004ec6:	59fd                	li	s3,-1
    80004ec8:	bff9                	j	80004ea6 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eca:	4981                	li	s3,0
    80004ecc:	b7d1                	j	80004e90 <piperead+0xb4>

0000000080004ece <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ece:	1141                	addi	sp,sp,-16
    80004ed0:	e422                	sd	s0,8(sp)
    80004ed2:	0800                	addi	s0,sp,16
    80004ed4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ed6:	8905                	andi	a0,a0,1
    80004ed8:	c111                	beqz	a0,80004edc <flags2perm+0xe>
      perm = PTE_X;
    80004eda:	4521                	li	a0,8
    if(flags & 0x2)
    80004edc:	8b89                	andi	a5,a5,2
    80004ede:	c399                	beqz	a5,80004ee4 <flags2perm+0x16>
      perm |= PTE_W;
    80004ee0:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ee4:	6422                	ld	s0,8(sp)
    80004ee6:	0141                	addi	sp,sp,16
    80004ee8:	8082                	ret

0000000080004eea <exec>:

int
exec(char *path, char **argv)
{
    80004eea:	df010113          	addi	sp,sp,-528
    80004eee:	20113423          	sd	ra,520(sp)
    80004ef2:	20813023          	sd	s0,512(sp)
    80004ef6:	ffa6                	sd	s1,504(sp)
    80004ef8:	fbca                	sd	s2,496(sp)
    80004efa:	f7ce                	sd	s3,488(sp)
    80004efc:	f3d2                	sd	s4,480(sp)
    80004efe:	efd6                	sd	s5,472(sp)
    80004f00:	ebda                	sd	s6,464(sp)
    80004f02:	e7de                	sd	s7,456(sp)
    80004f04:	e3e2                	sd	s8,448(sp)
    80004f06:	ff66                	sd	s9,440(sp)
    80004f08:	fb6a                	sd	s10,432(sp)
    80004f0a:	f76e                	sd	s11,424(sp)
    80004f0c:	0c00                	addi	s0,sp,528
    80004f0e:	84aa                	mv	s1,a0
    80004f10:	dea43c23          	sd	a0,-520(s0)
    80004f14:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	aae080e7          	jalr	-1362(ra) # 800019c6 <myproc>
    80004f20:	892a                	mv	s2,a0

  begin_op();
    80004f22:	fffff097          	auipc	ra,0xfffff
    80004f26:	474080e7          	jalr	1140(ra) # 80004396 <begin_op>

  if((ip = namei(path)) == 0){
    80004f2a:	8526                	mv	a0,s1
    80004f2c:	fffff097          	auipc	ra,0xfffff
    80004f30:	24e080e7          	jalr	590(ra) # 8000417a <namei>
    80004f34:	c92d                	beqz	a0,80004fa6 <exec+0xbc>
    80004f36:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	a9c080e7          	jalr	-1380(ra) # 800039d4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f40:	04000713          	li	a4,64
    80004f44:	4681                	li	a3,0
    80004f46:	e5040613          	addi	a2,s0,-432
    80004f4a:	4581                	li	a1,0
    80004f4c:	8526                	mv	a0,s1
    80004f4e:	fffff097          	auipc	ra,0xfffff
    80004f52:	d3a080e7          	jalr	-710(ra) # 80003c88 <readi>
    80004f56:	04000793          	li	a5,64
    80004f5a:	00f51a63          	bne	a0,a5,80004f6e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f5e:	e5042703          	lw	a4,-432(s0)
    80004f62:	464c47b7          	lui	a5,0x464c4
    80004f66:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f6a:	04f70463          	beq	a4,a5,80004fb2 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	fffff097          	auipc	ra,0xfffff
    80004f74:	cc6080e7          	jalr	-826(ra) # 80003c36 <iunlockput>
    end_op();
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	49e080e7          	jalr	1182(ra) # 80004416 <end_op>
  }
  return -1;
    80004f80:	557d                	li	a0,-1
}
    80004f82:	20813083          	ld	ra,520(sp)
    80004f86:	20013403          	ld	s0,512(sp)
    80004f8a:	74fe                	ld	s1,504(sp)
    80004f8c:	795e                	ld	s2,496(sp)
    80004f8e:	79be                	ld	s3,488(sp)
    80004f90:	7a1e                	ld	s4,480(sp)
    80004f92:	6afe                	ld	s5,472(sp)
    80004f94:	6b5e                	ld	s6,464(sp)
    80004f96:	6bbe                	ld	s7,456(sp)
    80004f98:	6c1e                	ld	s8,448(sp)
    80004f9a:	7cfa                	ld	s9,440(sp)
    80004f9c:	7d5a                	ld	s10,432(sp)
    80004f9e:	7dba                	ld	s11,424(sp)
    80004fa0:	21010113          	addi	sp,sp,528
    80004fa4:	8082                	ret
    end_op();
    80004fa6:	fffff097          	auipc	ra,0xfffff
    80004faa:	470080e7          	jalr	1136(ra) # 80004416 <end_op>
    return -1;
    80004fae:	557d                	li	a0,-1
    80004fb0:	bfc9                	j	80004f82 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fb2:	854a                	mv	a0,s2
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	ad6080e7          	jalr	-1322(ra) # 80001a8a <proc_pagetable>
    80004fbc:	8baa                	mv	s7,a0
    80004fbe:	d945                	beqz	a0,80004f6e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc0:	e7042983          	lw	s3,-400(s0)
    80004fc4:	e8845783          	lhu	a5,-376(s0)
    80004fc8:	c7ad                	beqz	a5,80005032 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fca:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fcc:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004fce:	6c85                	lui	s9,0x1
    80004fd0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fd4:	def43823          	sd	a5,-528(s0)
    80004fd8:	ac0d                	j	8000520a <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fda:	00004517          	auipc	a0,0x4
    80004fde:	92e50513          	addi	a0,a0,-1746 # 80008908 <syscall_argc+0x230>
    80004fe2:	ffffb097          	auipc	ra,0xffffb
    80004fe6:	562080e7          	jalr	1378(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fea:	8756                	mv	a4,s5
    80004fec:	012d86bb          	addw	a3,s11,s2
    80004ff0:	4581                	li	a1,0
    80004ff2:	8526                	mv	a0,s1
    80004ff4:	fffff097          	auipc	ra,0xfffff
    80004ff8:	c94080e7          	jalr	-876(ra) # 80003c88 <readi>
    80004ffc:	2501                	sext.w	a0,a0
    80004ffe:	1aaa9a63          	bne	s5,a0,800051b2 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80005002:	6785                	lui	a5,0x1
    80005004:	0127893b          	addw	s2,a5,s2
    80005008:	77fd                	lui	a5,0xfffff
    8000500a:	01478a3b          	addw	s4,a5,s4
    8000500e:	1f897563          	bgeu	s2,s8,800051f8 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80005012:	02091593          	slli	a1,s2,0x20
    80005016:	9181                	srli	a1,a1,0x20
    80005018:	95ea                	add	a1,a1,s10
    8000501a:	855e                	mv	a0,s7
    8000501c:	ffffc097          	auipc	ra,0xffffc
    80005020:	05c080e7          	jalr	92(ra) # 80001078 <walkaddr>
    80005024:	862a                	mv	a2,a0
    if(pa == 0)
    80005026:	d955                	beqz	a0,80004fda <exec+0xf0>
      n = PGSIZE;
    80005028:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000502a:	fd9a70e3          	bgeu	s4,s9,80004fea <exec+0x100>
      n = sz - i;
    8000502e:	8ad2                	mv	s5,s4
    80005030:	bf6d                	j	80004fea <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005032:	4a01                	li	s4,0
  iunlockput(ip);
    80005034:	8526                	mv	a0,s1
    80005036:	fffff097          	auipc	ra,0xfffff
    8000503a:	c00080e7          	jalr	-1024(ra) # 80003c36 <iunlockput>
  end_op();
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	3d8080e7          	jalr	984(ra) # 80004416 <end_op>
  p = myproc();
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	980080e7          	jalr	-1664(ra) # 800019c6 <myproc>
    8000504e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005050:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80005054:	6785                	lui	a5,0x1
    80005056:	17fd                	addi	a5,a5,-1
    80005058:	9a3e                	add	s4,s4,a5
    8000505a:	757d                	lui	a0,0xfffff
    8000505c:	00aa77b3          	and	a5,s4,a0
    80005060:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005064:	4691                	li	a3,4
    80005066:	6609                	lui	a2,0x2
    80005068:	963e                	add	a2,a2,a5
    8000506a:	85be                	mv	a1,a5
    8000506c:	855e                	mv	a0,s7
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	3be080e7          	jalr	958(ra) # 8000142c <uvmalloc>
    80005076:	8b2a                	mv	s6,a0
  ip = 0;
    80005078:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000507a:	12050c63          	beqz	a0,800051b2 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000507e:	75f9                	lui	a1,0xffffe
    80005080:	95aa                	add	a1,a1,a0
    80005082:	855e                	mv	a0,s7
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	5ce080e7          	jalr	1486(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    8000508c:	7c7d                	lui	s8,0xfffff
    8000508e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005090:	e0043783          	ld	a5,-512(s0)
    80005094:	6388                	ld	a0,0(a5)
    80005096:	c535                	beqz	a0,80005102 <exec+0x218>
    80005098:	e9040993          	addi	s3,s0,-368
    8000509c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050a0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800050a2:	ffffc097          	auipc	ra,0xffffc
    800050a6:	dc8080e7          	jalr	-568(ra) # 80000e6a <strlen>
    800050aa:	2505                	addiw	a0,a0,1
    800050ac:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050b0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050b4:	13896663          	bltu	s2,s8,800051e0 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050b8:	e0043d83          	ld	s11,-512(s0)
    800050bc:	000dba03          	ld	s4,0(s11)
    800050c0:	8552                	mv	a0,s4
    800050c2:	ffffc097          	auipc	ra,0xffffc
    800050c6:	da8080e7          	jalr	-600(ra) # 80000e6a <strlen>
    800050ca:	0015069b          	addiw	a3,a0,1
    800050ce:	8652                	mv	a2,s4
    800050d0:	85ca                	mv	a1,s2
    800050d2:	855e                	mv	a0,s7
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	5b0080e7          	jalr	1456(ra) # 80001684 <copyout>
    800050dc:	10054663          	bltz	a0,800051e8 <exec+0x2fe>
    ustack[argc] = sp;
    800050e0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050e4:	0485                	addi	s1,s1,1
    800050e6:	008d8793          	addi	a5,s11,8
    800050ea:	e0f43023          	sd	a5,-512(s0)
    800050ee:	008db503          	ld	a0,8(s11)
    800050f2:	c911                	beqz	a0,80005106 <exec+0x21c>
    if(argc >= MAXARG)
    800050f4:	09a1                	addi	s3,s3,8
    800050f6:	fb3c96e3          	bne	s9,s3,800050a2 <exec+0x1b8>
  sz = sz1;
    800050fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050fe:	4481                	li	s1,0
    80005100:	a84d                	j	800051b2 <exec+0x2c8>
  sp = sz;
    80005102:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005104:	4481                	li	s1,0
  ustack[argc] = 0;
    80005106:	00349793          	slli	a5,s1,0x3
    8000510a:	f9040713          	addi	a4,s0,-112
    8000510e:	97ba                	add	a5,a5,a4
    80005110:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005114:	00148693          	addi	a3,s1,1
    80005118:	068e                	slli	a3,a3,0x3
    8000511a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000511e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005122:	01897663          	bgeu	s2,s8,8000512e <exec+0x244>
  sz = sz1;
    80005126:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000512a:	4481                	li	s1,0
    8000512c:	a059                	j	800051b2 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000512e:	e9040613          	addi	a2,s0,-368
    80005132:	85ca                	mv	a1,s2
    80005134:	855e                	mv	a0,s7
    80005136:	ffffc097          	auipc	ra,0xffffc
    8000513a:	54e080e7          	jalr	1358(ra) # 80001684 <copyout>
    8000513e:	0a054963          	bltz	a0,800051f0 <exec+0x306>
  p->trapframe->a1 = sp;
    80005142:	060ab783          	ld	a5,96(s5)
    80005146:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000514a:	df843783          	ld	a5,-520(s0)
    8000514e:	0007c703          	lbu	a4,0(a5)
    80005152:	cf11                	beqz	a4,8000516e <exec+0x284>
    80005154:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005156:	02f00693          	li	a3,47
    8000515a:	a039                	j	80005168 <exec+0x27e>
      last = s+1;
    8000515c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005160:	0785                	addi	a5,a5,1
    80005162:	fff7c703          	lbu	a4,-1(a5)
    80005166:	c701                	beqz	a4,8000516e <exec+0x284>
    if(*s == '/')
    80005168:	fed71ce3          	bne	a4,a3,80005160 <exec+0x276>
    8000516c:	bfc5                	j	8000515c <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    8000516e:	4641                	li	a2,16
    80005170:	df843583          	ld	a1,-520(s0)
    80005174:	160a8513          	addi	a0,s5,352
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	cc0080e7          	jalr	-832(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005180:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005184:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005188:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000518c:	060ab783          	ld	a5,96(s5)
    80005190:	e6843703          	ld	a4,-408(s0)
    80005194:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005196:	060ab783          	ld	a5,96(s5)
    8000519a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000519e:	85ea                	mv	a1,s10
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	986080e7          	jalr	-1658(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051a8:	0004851b          	sext.w	a0,s1
    800051ac:	bbd9                	j	80004f82 <exec+0x98>
    800051ae:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051b2:	e0843583          	ld	a1,-504(s0)
    800051b6:	855e                	mv	a0,s7
    800051b8:	ffffd097          	auipc	ra,0xffffd
    800051bc:	96e080e7          	jalr	-1682(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800051c0:	da0497e3          	bnez	s1,80004f6e <exec+0x84>
  return -1;
    800051c4:	557d                	li	a0,-1
    800051c6:	bb75                	j	80004f82 <exec+0x98>
    800051c8:	e1443423          	sd	s4,-504(s0)
    800051cc:	b7dd                	j	800051b2 <exec+0x2c8>
    800051ce:	e1443423          	sd	s4,-504(s0)
    800051d2:	b7c5                	j	800051b2 <exec+0x2c8>
    800051d4:	e1443423          	sd	s4,-504(s0)
    800051d8:	bfe9                	j	800051b2 <exec+0x2c8>
    800051da:	e1443423          	sd	s4,-504(s0)
    800051de:	bfd1                	j	800051b2 <exec+0x2c8>
  sz = sz1;
    800051e0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051e4:	4481                	li	s1,0
    800051e6:	b7f1                	j	800051b2 <exec+0x2c8>
  sz = sz1;
    800051e8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051ec:	4481                	li	s1,0
    800051ee:	b7d1                	j	800051b2 <exec+0x2c8>
  sz = sz1;
    800051f0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051f4:	4481                	li	s1,0
    800051f6:	bf75                	j	800051b2 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051f8:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051fc:	2b05                	addiw	s6,s6,1
    800051fe:	0389899b          	addiw	s3,s3,56
    80005202:	e8845783          	lhu	a5,-376(s0)
    80005206:	e2fb57e3          	bge	s6,a5,80005034 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000520a:	2981                	sext.w	s3,s3
    8000520c:	03800713          	li	a4,56
    80005210:	86ce                	mv	a3,s3
    80005212:	e1840613          	addi	a2,s0,-488
    80005216:	4581                	li	a1,0
    80005218:	8526                	mv	a0,s1
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	a6e080e7          	jalr	-1426(ra) # 80003c88 <readi>
    80005222:	03800793          	li	a5,56
    80005226:	f8f514e3          	bne	a0,a5,800051ae <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000522a:	e1842783          	lw	a5,-488(s0)
    8000522e:	4705                	li	a4,1
    80005230:	fce796e3          	bne	a5,a4,800051fc <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005234:	e4043903          	ld	s2,-448(s0)
    80005238:	e3843783          	ld	a5,-456(s0)
    8000523c:	f8f966e3          	bltu	s2,a5,800051c8 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005240:	e2843783          	ld	a5,-472(s0)
    80005244:	993e                	add	s2,s2,a5
    80005246:	f8f964e3          	bltu	s2,a5,800051ce <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000524a:	df043703          	ld	a4,-528(s0)
    8000524e:	8ff9                	and	a5,a5,a4
    80005250:	f3d1                	bnez	a5,800051d4 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005252:	e1c42503          	lw	a0,-484(s0)
    80005256:	00000097          	auipc	ra,0x0
    8000525a:	c78080e7          	jalr	-904(ra) # 80004ece <flags2perm>
    8000525e:	86aa                	mv	a3,a0
    80005260:	864a                	mv	a2,s2
    80005262:	85d2                	mv	a1,s4
    80005264:	855e                	mv	a0,s7
    80005266:	ffffc097          	auipc	ra,0xffffc
    8000526a:	1c6080e7          	jalr	454(ra) # 8000142c <uvmalloc>
    8000526e:	e0a43423          	sd	a0,-504(s0)
    80005272:	d525                	beqz	a0,800051da <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005274:	e2843d03          	ld	s10,-472(s0)
    80005278:	e2042d83          	lw	s11,-480(s0)
    8000527c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005280:	f60c0ce3          	beqz	s8,800051f8 <exec+0x30e>
    80005284:	8a62                	mv	s4,s8
    80005286:	4901                	li	s2,0
    80005288:	b369                	j	80005012 <exec+0x128>

000000008000528a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000528a:	7179                	addi	sp,sp,-48
    8000528c:	f406                	sd	ra,40(sp)
    8000528e:	f022                	sd	s0,32(sp)
    80005290:	ec26                	sd	s1,24(sp)
    80005292:	e84a                	sd	s2,16(sp)
    80005294:	1800                	addi	s0,sp,48
    80005296:	892e                	mv	s2,a1
    80005298:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000529a:	fdc40593          	addi	a1,s0,-36
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	a2a080e7          	jalr	-1494(ra) # 80002cc8 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052a6:	fdc42703          	lw	a4,-36(s0)
    800052aa:	47bd                	li	a5,15
    800052ac:	02e7eb63          	bltu	a5,a4,800052e2 <argfd+0x58>
    800052b0:	ffffc097          	auipc	ra,0xffffc
    800052b4:	716080e7          	jalr	1814(ra) # 800019c6 <myproc>
    800052b8:	fdc42703          	lw	a4,-36(s0)
    800052bc:	01a70793          	addi	a5,a4,26
    800052c0:	078e                	slli	a5,a5,0x3
    800052c2:	953e                	add	a0,a0,a5
    800052c4:	651c                	ld	a5,8(a0)
    800052c6:	c385                	beqz	a5,800052e6 <argfd+0x5c>
    return -1;
  if(pfd)
    800052c8:	00090463          	beqz	s2,800052d0 <argfd+0x46>
    *pfd = fd;
    800052cc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052d0:	4501                	li	a0,0
  if(pf)
    800052d2:	c091                	beqz	s1,800052d6 <argfd+0x4c>
    *pf = f;
    800052d4:	e09c                	sd	a5,0(s1)
}
    800052d6:	70a2                	ld	ra,40(sp)
    800052d8:	7402                	ld	s0,32(sp)
    800052da:	64e2                	ld	s1,24(sp)
    800052dc:	6942                	ld	s2,16(sp)
    800052de:	6145                	addi	sp,sp,48
    800052e0:	8082                	ret
    return -1;
    800052e2:	557d                	li	a0,-1
    800052e4:	bfcd                	j	800052d6 <argfd+0x4c>
    800052e6:	557d                	li	a0,-1
    800052e8:	b7fd                	j	800052d6 <argfd+0x4c>

00000000800052ea <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052ea:	1101                	addi	sp,sp,-32
    800052ec:	ec06                	sd	ra,24(sp)
    800052ee:	e822                	sd	s0,16(sp)
    800052f0:	e426                	sd	s1,8(sp)
    800052f2:	1000                	addi	s0,sp,32
    800052f4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052f6:	ffffc097          	auipc	ra,0xffffc
    800052fa:	6d0080e7          	jalr	1744(ra) # 800019c6 <myproc>
    800052fe:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005300:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffdbb30>
    80005304:	4501                	li	a0,0
    80005306:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005308:	6398                	ld	a4,0(a5)
    8000530a:	cb19                	beqz	a4,80005320 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000530c:	2505                	addiw	a0,a0,1
    8000530e:	07a1                	addi	a5,a5,8
    80005310:	fed51ce3          	bne	a0,a3,80005308 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005314:	557d                	li	a0,-1
}
    80005316:	60e2                	ld	ra,24(sp)
    80005318:	6442                	ld	s0,16(sp)
    8000531a:	64a2                	ld	s1,8(sp)
    8000531c:	6105                	addi	sp,sp,32
    8000531e:	8082                	ret
      p->ofile[fd] = f;
    80005320:	01a50793          	addi	a5,a0,26
    80005324:	078e                	slli	a5,a5,0x3
    80005326:	963e                	add	a2,a2,a5
    80005328:	e604                	sd	s1,8(a2)
      return fd;
    8000532a:	b7f5                	j	80005316 <fdalloc+0x2c>

000000008000532c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000532c:	715d                	addi	sp,sp,-80
    8000532e:	e486                	sd	ra,72(sp)
    80005330:	e0a2                	sd	s0,64(sp)
    80005332:	fc26                	sd	s1,56(sp)
    80005334:	f84a                	sd	s2,48(sp)
    80005336:	f44e                	sd	s3,40(sp)
    80005338:	f052                	sd	s4,32(sp)
    8000533a:	ec56                	sd	s5,24(sp)
    8000533c:	e85a                	sd	s6,16(sp)
    8000533e:	0880                	addi	s0,sp,80
    80005340:	8b2e                	mv	s6,a1
    80005342:	89b2                	mv	s3,a2
    80005344:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005346:	fb040593          	addi	a1,s0,-80
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	e4e080e7          	jalr	-434(ra) # 80004198 <nameiparent>
    80005352:	84aa                	mv	s1,a0
    80005354:	16050063          	beqz	a0,800054b4 <create+0x188>
    return 0;

  ilock(dp);
    80005358:	ffffe097          	auipc	ra,0xffffe
    8000535c:	67c080e7          	jalr	1660(ra) # 800039d4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005360:	4601                	li	a2,0
    80005362:	fb040593          	addi	a1,s0,-80
    80005366:	8526                	mv	a0,s1
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	b50080e7          	jalr	-1200(ra) # 80003eb8 <dirlookup>
    80005370:	8aaa                	mv	s5,a0
    80005372:	c931                	beqz	a0,800053c6 <create+0x9a>
    iunlockput(dp);
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	8c0080e7          	jalr	-1856(ra) # 80003c36 <iunlockput>
    ilock(ip);
    8000537e:	8556                	mv	a0,s5
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	654080e7          	jalr	1620(ra) # 800039d4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005388:	000b059b          	sext.w	a1,s6
    8000538c:	4789                	li	a5,2
    8000538e:	02f59563          	bne	a1,a5,800053b8 <create+0x8c>
    80005392:	044ad783          	lhu	a5,68(s5)
    80005396:	37f9                	addiw	a5,a5,-2
    80005398:	17c2                	slli	a5,a5,0x30
    8000539a:	93c1                	srli	a5,a5,0x30
    8000539c:	4705                	li	a4,1
    8000539e:	00f76d63          	bltu	a4,a5,800053b8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053a2:	8556                	mv	a0,s5
    800053a4:	60a6                	ld	ra,72(sp)
    800053a6:	6406                	ld	s0,64(sp)
    800053a8:	74e2                	ld	s1,56(sp)
    800053aa:	7942                	ld	s2,48(sp)
    800053ac:	79a2                	ld	s3,40(sp)
    800053ae:	7a02                	ld	s4,32(sp)
    800053b0:	6ae2                	ld	s5,24(sp)
    800053b2:	6b42                	ld	s6,16(sp)
    800053b4:	6161                	addi	sp,sp,80
    800053b6:	8082                	ret
    iunlockput(ip);
    800053b8:	8556                	mv	a0,s5
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	87c080e7          	jalr	-1924(ra) # 80003c36 <iunlockput>
    return 0;
    800053c2:	4a81                	li	s5,0
    800053c4:	bff9                	j	800053a2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053c6:	85da                	mv	a1,s6
    800053c8:	4088                	lw	a0,0(s1)
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	46e080e7          	jalr	1134(ra) # 80003838 <ialloc>
    800053d2:	8a2a                	mv	s4,a0
    800053d4:	c921                	beqz	a0,80005424 <create+0xf8>
  ilock(ip);
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	5fe080e7          	jalr	1534(ra) # 800039d4 <ilock>
  ip->major = major;
    800053de:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053e2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053e6:	4785                	li	a5,1
    800053e8:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800053ec:	8552                	mv	a0,s4
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	51c080e7          	jalr	1308(ra) # 8000390a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053f6:	000b059b          	sext.w	a1,s6
    800053fa:	4785                	li	a5,1
    800053fc:	02f58b63          	beq	a1,a5,80005432 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005400:	004a2603          	lw	a2,4(s4)
    80005404:	fb040593          	addi	a1,s0,-80
    80005408:	8526                	mv	a0,s1
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	cbe080e7          	jalr	-834(ra) # 800040c8 <dirlink>
    80005412:	06054f63          	bltz	a0,80005490 <create+0x164>
  iunlockput(dp);
    80005416:	8526                	mv	a0,s1
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	81e080e7          	jalr	-2018(ra) # 80003c36 <iunlockput>
  return ip;
    80005420:	8ad2                	mv	s5,s4
    80005422:	b741                	j	800053a2 <create+0x76>
    iunlockput(dp);
    80005424:	8526                	mv	a0,s1
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	810080e7          	jalr	-2032(ra) # 80003c36 <iunlockput>
    return 0;
    8000542e:	8ad2                	mv	s5,s4
    80005430:	bf8d                	j	800053a2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005432:	004a2603          	lw	a2,4(s4)
    80005436:	00003597          	auipc	a1,0x3
    8000543a:	4f258593          	addi	a1,a1,1266 # 80008928 <syscall_argc+0x250>
    8000543e:	8552                	mv	a0,s4
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	c88080e7          	jalr	-888(ra) # 800040c8 <dirlink>
    80005448:	04054463          	bltz	a0,80005490 <create+0x164>
    8000544c:	40d0                	lw	a2,4(s1)
    8000544e:	00003597          	auipc	a1,0x3
    80005452:	4e258593          	addi	a1,a1,1250 # 80008930 <syscall_argc+0x258>
    80005456:	8552                	mv	a0,s4
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	c70080e7          	jalr	-912(ra) # 800040c8 <dirlink>
    80005460:	02054863          	bltz	a0,80005490 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005464:	004a2603          	lw	a2,4(s4)
    80005468:	fb040593          	addi	a1,s0,-80
    8000546c:	8526                	mv	a0,s1
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	c5a080e7          	jalr	-934(ra) # 800040c8 <dirlink>
    80005476:	00054d63          	bltz	a0,80005490 <create+0x164>
    dp->nlink++;  // for ".."
    8000547a:	04a4d783          	lhu	a5,74(s1)
    8000547e:	2785                	addiw	a5,a5,1
    80005480:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005484:	8526                	mv	a0,s1
    80005486:	ffffe097          	auipc	ra,0xffffe
    8000548a:	484080e7          	jalr	1156(ra) # 8000390a <iupdate>
    8000548e:	b761                	j	80005416 <create+0xea>
  ip->nlink = 0;
    80005490:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005494:	8552                	mv	a0,s4
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	474080e7          	jalr	1140(ra) # 8000390a <iupdate>
  iunlockput(ip);
    8000549e:	8552                	mv	a0,s4
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	796080e7          	jalr	1942(ra) # 80003c36 <iunlockput>
  iunlockput(dp);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	78c080e7          	jalr	1932(ra) # 80003c36 <iunlockput>
  return 0;
    800054b2:	bdc5                	j	800053a2 <create+0x76>
    return 0;
    800054b4:	8aaa                	mv	s5,a0
    800054b6:	b5f5                	j	800053a2 <create+0x76>

00000000800054b8 <sys_dup>:
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	ec26                	sd	s1,24(sp)
    800054c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054c2:	fd840613          	addi	a2,s0,-40
    800054c6:	4581                	li	a1,0
    800054c8:	4501                	li	a0,0
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	dc0080e7          	jalr	-576(ra) # 8000528a <argfd>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054d4:	02054363          	bltz	a0,800054fa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054d8:	fd843503          	ld	a0,-40(s0)
    800054dc:	00000097          	auipc	ra,0x0
    800054e0:	e0e080e7          	jalr	-498(ra) # 800052ea <fdalloc>
    800054e4:	84aa                	mv	s1,a0
    return -1;
    800054e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054e8:	00054963          	bltz	a0,800054fa <sys_dup+0x42>
  filedup(f);
    800054ec:	fd843503          	ld	a0,-40(s0)
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	320080e7          	jalr	800(ra) # 80004810 <filedup>
  return fd;
    800054f8:	87a6                	mv	a5,s1
}
    800054fa:	853e                	mv	a0,a5
    800054fc:	70a2                	ld	ra,40(sp)
    800054fe:	7402                	ld	s0,32(sp)
    80005500:	64e2                	ld	s1,24(sp)
    80005502:	6145                	addi	sp,sp,48
    80005504:	8082                	ret

0000000080005506 <sys_read>:
{
    80005506:	7179                	addi	sp,sp,-48
    80005508:	f406                	sd	ra,40(sp)
    8000550a:	f022                	sd	s0,32(sp)
    8000550c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000550e:	fd840593          	addi	a1,s0,-40
    80005512:	4505                	li	a0,1
    80005514:	ffffd097          	auipc	ra,0xffffd
    80005518:	7d6080e7          	jalr	2006(ra) # 80002cea <argaddr>
  argint(2, &n);
    8000551c:	fe440593          	addi	a1,s0,-28
    80005520:	4509                	li	a0,2
    80005522:	ffffd097          	auipc	ra,0xffffd
    80005526:	7a6080e7          	jalr	1958(ra) # 80002cc8 <argint>
  if(argfd(0, 0, &f) < 0)
    8000552a:	fe840613          	addi	a2,s0,-24
    8000552e:	4581                	li	a1,0
    80005530:	4501                	li	a0,0
    80005532:	00000097          	auipc	ra,0x0
    80005536:	d58080e7          	jalr	-680(ra) # 8000528a <argfd>
    8000553a:	87aa                	mv	a5,a0
    return -1;
    8000553c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000553e:	0007cc63          	bltz	a5,80005556 <sys_read+0x50>
  return fileread(f, p, n);
    80005542:	fe442603          	lw	a2,-28(s0)
    80005546:	fd843583          	ld	a1,-40(s0)
    8000554a:	fe843503          	ld	a0,-24(s0)
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	44e080e7          	jalr	1102(ra) # 8000499c <fileread>
}
    80005556:	70a2                	ld	ra,40(sp)
    80005558:	7402                	ld	s0,32(sp)
    8000555a:	6145                	addi	sp,sp,48
    8000555c:	8082                	ret

000000008000555e <sys_write>:
{
    8000555e:	7179                	addi	sp,sp,-48
    80005560:	f406                	sd	ra,40(sp)
    80005562:	f022                	sd	s0,32(sp)
    80005564:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005566:	fd840593          	addi	a1,s0,-40
    8000556a:	4505                	li	a0,1
    8000556c:	ffffd097          	auipc	ra,0xffffd
    80005570:	77e080e7          	jalr	1918(ra) # 80002cea <argaddr>
  argint(2, &n);
    80005574:	fe440593          	addi	a1,s0,-28
    80005578:	4509                	li	a0,2
    8000557a:	ffffd097          	auipc	ra,0xffffd
    8000557e:	74e080e7          	jalr	1870(ra) # 80002cc8 <argint>
  if(argfd(0, 0, &f) < 0)
    80005582:	fe840613          	addi	a2,s0,-24
    80005586:	4581                	li	a1,0
    80005588:	4501                	li	a0,0
    8000558a:	00000097          	auipc	ra,0x0
    8000558e:	d00080e7          	jalr	-768(ra) # 8000528a <argfd>
    80005592:	87aa                	mv	a5,a0
    return -1;
    80005594:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005596:	0007cc63          	bltz	a5,800055ae <sys_write+0x50>
  return filewrite(f, p, n);
    8000559a:	fe442603          	lw	a2,-28(s0)
    8000559e:	fd843583          	ld	a1,-40(s0)
    800055a2:	fe843503          	ld	a0,-24(s0)
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	4b8080e7          	jalr	1208(ra) # 80004a5e <filewrite>
}
    800055ae:	70a2                	ld	ra,40(sp)
    800055b0:	7402                	ld	s0,32(sp)
    800055b2:	6145                	addi	sp,sp,48
    800055b4:	8082                	ret

00000000800055b6 <sys_close>:
{
    800055b6:	1101                	addi	sp,sp,-32
    800055b8:	ec06                	sd	ra,24(sp)
    800055ba:	e822                	sd	s0,16(sp)
    800055bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055be:	fe040613          	addi	a2,s0,-32
    800055c2:	fec40593          	addi	a1,s0,-20
    800055c6:	4501                	li	a0,0
    800055c8:	00000097          	auipc	ra,0x0
    800055cc:	cc2080e7          	jalr	-830(ra) # 8000528a <argfd>
    return -1;
    800055d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055d2:	02054463          	bltz	a0,800055fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055d6:	ffffc097          	auipc	ra,0xffffc
    800055da:	3f0080e7          	jalr	1008(ra) # 800019c6 <myproc>
    800055de:	fec42783          	lw	a5,-20(s0)
    800055e2:	07e9                	addi	a5,a5,26
    800055e4:	078e                	slli	a5,a5,0x3
    800055e6:	97aa                	add	a5,a5,a0
    800055e8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800055ec:	fe043503          	ld	a0,-32(s0)
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	272080e7          	jalr	626(ra) # 80004862 <fileclose>
  return 0;
    800055f8:	4781                	li	a5,0
}
    800055fa:	853e                	mv	a0,a5
    800055fc:	60e2                	ld	ra,24(sp)
    800055fe:	6442                	ld	s0,16(sp)
    80005600:	6105                	addi	sp,sp,32
    80005602:	8082                	ret

0000000080005604 <sys_fstat>:
{
    80005604:	1101                	addi	sp,sp,-32
    80005606:	ec06                	sd	ra,24(sp)
    80005608:	e822                	sd	s0,16(sp)
    8000560a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000560c:	fe040593          	addi	a1,s0,-32
    80005610:	4505                	li	a0,1
    80005612:	ffffd097          	auipc	ra,0xffffd
    80005616:	6d8080e7          	jalr	1752(ra) # 80002cea <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000561a:	fe840613          	addi	a2,s0,-24
    8000561e:	4581                	li	a1,0
    80005620:	4501                	li	a0,0
    80005622:	00000097          	auipc	ra,0x0
    80005626:	c68080e7          	jalr	-920(ra) # 8000528a <argfd>
    8000562a:	87aa                	mv	a5,a0
    return -1;
    8000562c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000562e:	0007ca63          	bltz	a5,80005642 <sys_fstat+0x3e>
  return filestat(f, st);
    80005632:	fe043583          	ld	a1,-32(s0)
    80005636:	fe843503          	ld	a0,-24(s0)
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	2f0080e7          	jalr	752(ra) # 8000492a <filestat>
}
    80005642:	60e2                	ld	ra,24(sp)
    80005644:	6442                	ld	s0,16(sp)
    80005646:	6105                	addi	sp,sp,32
    80005648:	8082                	ret

000000008000564a <sys_link>:
{
    8000564a:	7169                	addi	sp,sp,-304
    8000564c:	f606                	sd	ra,296(sp)
    8000564e:	f222                	sd	s0,288(sp)
    80005650:	ee26                	sd	s1,280(sp)
    80005652:	ea4a                	sd	s2,272(sp)
    80005654:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005656:	08000613          	li	a2,128
    8000565a:	ed040593          	addi	a1,s0,-304
    8000565e:	4501                	li	a0,0
    80005660:	ffffd097          	auipc	ra,0xffffd
    80005664:	6ac080e7          	jalr	1708(ra) # 80002d0c <argstr>
    return -1;
    80005668:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000566a:	10054e63          	bltz	a0,80005786 <sys_link+0x13c>
    8000566e:	08000613          	li	a2,128
    80005672:	f5040593          	addi	a1,s0,-176
    80005676:	4505                	li	a0,1
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	694080e7          	jalr	1684(ra) # 80002d0c <argstr>
    return -1;
    80005680:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005682:	10054263          	bltz	a0,80005786 <sys_link+0x13c>
  begin_op();
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	d10080e7          	jalr	-752(ra) # 80004396 <begin_op>
  if((ip = namei(old)) == 0){
    8000568e:	ed040513          	addi	a0,s0,-304
    80005692:	fffff097          	auipc	ra,0xfffff
    80005696:	ae8080e7          	jalr	-1304(ra) # 8000417a <namei>
    8000569a:	84aa                	mv	s1,a0
    8000569c:	c551                	beqz	a0,80005728 <sys_link+0xde>
  ilock(ip);
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	336080e7          	jalr	822(ra) # 800039d4 <ilock>
  if(ip->type == T_DIR){
    800056a6:	04449703          	lh	a4,68(s1)
    800056aa:	4785                	li	a5,1
    800056ac:	08f70463          	beq	a4,a5,80005734 <sys_link+0xea>
  ip->nlink++;
    800056b0:	04a4d783          	lhu	a5,74(s1)
    800056b4:	2785                	addiw	a5,a5,1
    800056b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	24e080e7          	jalr	590(ra) # 8000390a <iupdate>
  iunlock(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	3d0080e7          	jalr	976(ra) # 80003a96 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056ce:	fd040593          	addi	a1,s0,-48
    800056d2:	f5040513          	addi	a0,s0,-176
    800056d6:	fffff097          	auipc	ra,0xfffff
    800056da:	ac2080e7          	jalr	-1342(ra) # 80004198 <nameiparent>
    800056de:	892a                	mv	s2,a0
    800056e0:	c935                	beqz	a0,80005754 <sys_link+0x10a>
  ilock(dp);
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	2f2080e7          	jalr	754(ra) # 800039d4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056ea:	00092703          	lw	a4,0(s2)
    800056ee:	409c                	lw	a5,0(s1)
    800056f0:	04f71d63          	bne	a4,a5,8000574a <sys_link+0x100>
    800056f4:	40d0                	lw	a2,4(s1)
    800056f6:	fd040593          	addi	a1,s0,-48
    800056fa:	854a                	mv	a0,s2
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	9cc080e7          	jalr	-1588(ra) # 800040c8 <dirlink>
    80005704:	04054363          	bltz	a0,8000574a <sys_link+0x100>
  iunlockput(dp);
    80005708:	854a                	mv	a0,s2
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	52c080e7          	jalr	1324(ra) # 80003c36 <iunlockput>
  iput(ip);
    80005712:	8526                	mv	a0,s1
    80005714:	ffffe097          	auipc	ra,0xffffe
    80005718:	47a080e7          	jalr	1146(ra) # 80003b8e <iput>
  end_op();
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	cfa080e7          	jalr	-774(ra) # 80004416 <end_op>
  return 0;
    80005724:	4781                	li	a5,0
    80005726:	a085                	j	80005786 <sys_link+0x13c>
    end_op();
    80005728:	fffff097          	auipc	ra,0xfffff
    8000572c:	cee080e7          	jalr	-786(ra) # 80004416 <end_op>
    return -1;
    80005730:	57fd                	li	a5,-1
    80005732:	a891                	j	80005786 <sys_link+0x13c>
    iunlockput(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	500080e7          	jalr	1280(ra) # 80003c36 <iunlockput>
    end_op();
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	cd8080e7          	jalr	-808(ra) # 80004416 <end_op>
    return -1;
    80005746:	57fd                	li	a5,-1
    80005748:	a83d                	j	80005786 <sys_link+0x13c>
    iunlockput(dp);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	4ea080e7          	jalr	1258(ra) # 80003c36 <iunlockput>
  ilock(ip);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	27e080e7          	jalr	638(ra) # 800039d4 <ilock>
  ip->nlink--;
    8000575e:	04a4d783          	lhu	a5,74(s1)
    80005762:	37fd                	addiw	a5,a5,-1
    80005764:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	1a0080e7          	jalr	416(ra) # 8000390a <iupdate>
  iunlockput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	4c2080e7          	jalr	1218(ra) # 80003c36 <iunlockput>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	c9a080e7          	jalr	-870(ra) # 80004416 <end_op>
  return -1;
    80005784:	57fd                	li	a5,-1
}
    80005786:	853e                	mv	a0,a5
    80005788:	70b2                	ld	ra,296(sp)
    8000578a:	7412                	ld	s0,288(sp)
    8000578c:	64f2                	ld	s1,280(sp)
    8000578e:	6952                	ld	s2,272(sp)
    80005790:	6155                	addi	sp,sp,304
    80005792:	8082                	ret

0000000080005794 <sys_unlink>:
{
    80005794:	7151                	addi	sp,sp,-240
    80005796:	f586                	sd	ra,232(sp)
    80005798:	f1a2                	sd	s0,224(sp)
    8000579a:	eda6                	sd	s1,216(sp)
    8000579c:	e9ca                	sd	s2,208(sp)
    8000579e:	e5ce                	sd	s3,200(sp)
    800057a0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057a2:	08000613          	li	a2,128
    800057a6:	f3040593          	addi	a1,s0,-208
    800057aa:	4501                	li	a0,0
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	560080e7          	jalr	1376(ra) # 80002d0c <argstr>
    800057b4:	18054163          	bltz	a0,80005936 <sys_unlink+0x1a2>
  begin_op();
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	bde080e7          	jalr	-1058(ra) # 80004396 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057c0:	fb040593          	addi	a1,s0,-80
    800057c4:	f3040513          	addi	a0,s0,-208
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	9d0080e7          	jalr	-1584(ra) # 80004198 <nameiparent>
    800057d0:	84aa                	mv	s1,a0
    800057d2:	c979                	beqz	a0,800058a8 <sys_unlink+0x114>
  ilock(dp);
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	200080e7          	jalr	512(ra) # 800039d4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057dc:	00003597          	auipc	a1,0x3
    800057e0:	14c58593          	addi	a1,a1,332 # 80008928 <syscall_argc+0x250>
    800057e4:	fb040513          	addi	a0,s0,-80
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	6b6080e7          	jalr	1718(ra) # 80003e9e <namecmp>
    800057f0:	14050a63          	beqz	a0,80005944 <sys_unlink+0x1b0>
    800057f4:	00003597          	auipc	a1,0x3
    800057f8:	13c58593          	addi	a1,a1,316 # 80008930 <syscall_argc+0x258>
    800057fc:	fb040513          	addi	a0,s0,-80
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	69e080e7          	jalr	1694(ra) # 80003e9e <namecmp>
    80005808:	12050e63          	beqz	a0,80005944 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000580c:	f2c40613          	addi	a2,s0,-212
    80005810:	fb040593          	addi	a1,s0,-80
    80005814:	8526                	mv	a0,s1
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	6a2080e7          	jalr	1698(ra) # 80003eb8 <dirlookup>
    8000581e:	892a                	mv	s2,a0
    80005820:	12050263          	beqz	a0,80005944 <sys_unlink+0x1b0>
  ilock(ip);
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	1b0080e7          	jalr	432(ra) # 800039d4 <ilock>
  if(ip->nlink < 1)
    8000582c:	04a91783          	lh	a5,74(s2)
    80005830:	08f05263          	blez	a5,800058b4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005834:	04491703          	lh	a4,68(s2)
    80005838:	4785                	li	a5,1
    8000583a:	08f70563          	beq	a4,a5,800058c4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000583e:	4641                	li	a2,16
    80005840:	4581                	li	a1,0
    80005842:	fc040513          	addi	a0,s0,-64
    80005846:	ffffb097          	auipc	ra,0xffffb
    8000584a:	4a0080e7          	jalr	1184(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000584e:	4741                	li	a4,16
    80005850:	f2c42683          	lw	a3,-212(s0)
    80005854:	fc040613          	addi	a2,s0,-64
    80005858:	4581                	li	a1,0
    8000585a:	8526                	mv	a0,s1
    8000585c:	ffffe097          	auipc	ra,0xffffe
    80005860:	524080e7          	jalr	1316(ra) # 80003d80 <writei>
    80005864:	47c1                	li	a5,16
    80005866:	0af51563          	bne	a0,a5,80005910 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000586a:	04491703          	lh	a4,68(s2)
    8000586e:	4785                	li	a5,1
    80005870:	0af70863          	beq	a4,a5,80005920 <sys_unlink+0x18c>
  iunlockput(dp);
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	3c0080e7          	jalr	960(ra) # 80003c36 <iunlockput>
  ip->nlink--;
    8000587e:	04a95783          	lhu	a5,74(s2)
    80005882:	37fd                	addiw	a5,a5,-1
    80005884:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005888:	854a                	mv	a0,s2
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	080080e7          	jalr	128(ra) # 8000390a <iupdate>
  iunlockput(ip);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	3a2080e7          	jalr	930(ra) # 80003c36 <iunlockput>
  end_op();
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	b7a080e7          	jalr	-1158(ra) # 80004416 <end_op>
  return 0;
    800058a4:	4501                	li	a0,0
    800058a6:	a84d                	j	80005958 <sys_unlink+0x1c4>
    end_op();
    800058a8:	fffff097          	auipc	ra,0xfffff
    800058ac:	b6e080e7          	jalr	-1170(ra) # 80004416 <end_op>
    return -1;
    800058b0:	557d                	li	a0,-1
    800058b2:	a05d                	j	80005958 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058b4:	00003517          	auipc	a0,0x3
    800058b8:	08450513          	addi	a0,a0,132 # 80008938 <syscall_argc+0x260>
    800058bc:	ffffb097          	auipc	ra,0xffffb
    800058c0:	c88080e7          	jalr	-888(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058c4:	04c92703          	lw	a4,76(s2)
    800058c8:	02000793          	li	a5,32
    800058cc:	f6e7f9e3          	bgeu	a5,a4,8000583e <sys_unlink+0xaa>
    800058d0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058d4:	4741                	li	a4,16
    800058d6:	86ce                	mv	a3,s3
    800058d8:	f1840613          	addi	a2,s0,-232
    800058dc:	4581                	li	a1,0
    800058de:	854a                	mv	a0,s2
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	3a8080e7          	jalr	936(ra) # 80003c88 <readi>
    800058e8:	47c1                	li	a5,16
    800058ea:	00f51b63          	bne	a0,a5,80005900 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058ee:	f1845783          	lhu	a5,-232(s0)
    800058f2:	e7a1                	bnez	a5,8000593a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058f4:	29c1                	addiw	s3,s3,16
    800058f6:	04c92783          	lw	a5,76(s2)
    800058fa:	fcf9ede3          	bltu	s3,a5,800058d4 <sys_unlink+0x140>
    800058fe:	b781                	j	8000583e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005900:	00003517          	auipc	a0,0x3
    80005904:	05050513          	addi	a0,a0,80 # 80008950 <syscall_argc+0x278>
    80005908:	ffffb097          	auipc	ra,0xffffb
    8000590c:	c3c080e7          	jalr	-964(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005910:	00003517          	auipc	a0,0x3
    80005914:	05850513          	addi	a0,a0,88 # 80008968 <syscall_argc+0x290>
    80005918:	ffffb097          	auipc	ra,0xffffb
    8000591c:	c2c080e7          	jalr	-980(ra) # 80000544 <panic>
    dp->nlink--;
    80005920:	04a4d783          	lhu	a5,74(s1)
    80005924:	37fd                	addiw	a5,a5,-1
    80005926:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000592a:	8526                	mv	a0,s1
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	fde080e7          	jalr	-34(ra) # 8000390a <iupdate>
    80005934:	b781                	j	80005874 <sys_unlink+0xe0>
    return -1;
    80005936:	557d                	li	a0,-1
    80005938:	a005                	j	80005958 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000593a:	854a                	mv	a0,s2
    8000593c:	ffffe097          	auipc	ra,0xffffe
    80005940:	2fa080e7          	jalr	762(ra) # 80003c36 <iunlockput>
  iunlockput(dp);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	2f0080e7          	jalr	752(ra) # 80003c36 <iunlockput>
  end_op();
    8000594e:	fffff097          	auipc	ra,0xfffff
    80005952:	ac8080e7          	jalr	-1336(ra) # 80004416 <end_op>
  return -1;
    80005956:	557d                	li	a0,-1
}
    80005958:	70ae                	ld	ra,232(sp)
    8000595a:	740e                	ld	s0,224(sp)
    8000595c:	64ee                	ld	s1,216(sp)
    8000595e:	694e                	ld	s2,208(sp)
    80005960:	69ae                	ld	s3,200(sp)
    80005962:	616d                	addi	sp,sp,240
    80005964:	8082                	ret

0000000080005966 <sys_open>:

uint64
sys_open(void)
{
    80005966:	7131                	addi	sp,sp,-192
    80005968:	fd06                	sd	ra,184(sp)
    8000596a:	f922                	sd	s0,176(sp)
    8000596c:	f526                	sd	s1,168(sp)
    8000596e:	f14a                	sd	s2,160(sp)
    80005970:	ed4e                	sd	s3,152(sp)
    80005972:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005974:	f4c40593          	addi	a1,s0,-180
    80005978:	4505                	li	a0,1
    8000597a:	ffffd097          	auipc	ra,0xffffd
    8000597e:	34e080e7          	jalr	846(ra) # 80002cc8 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005982:	08000613          	li	a2,128
    80005986:	f5040593          	addi	a1,s0,-176
    8000598a:	4501                	li	a0,0
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	380080e7          	jalr	896(ra) # 80002d0c <argstr>
    80005994:	87aa                	mv	a5,a0
    return -1;
    80005996:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005998:	0a07c963          	bltz	a5,80005a4a <sys_open+0xe4>

  begin_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	9fa080e7          	jalr	-1542(ra) # 80004396 <begin_op>

  if(omode & O_CREATE){
    800059a4:	f4c42783          	lw	a5,-180(s0)
    800059a8:	2007f793          	andi	a5,a5,512
    800059ac:	cfc5                	beqz	a5,80005a64 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059ae:	4681                	li	a3,0
    800059b0:	4601                	li	a2,0
    800059b2:	4589                	li	a1,2
    800059b4:	f5040513          	addi	a0,s0,-176
    800059b8:	00000097          	auipc	ra,0x0
    800059bc:	974080e7          	jalr	-1676(ra) # 8000532c <create>
    800059c0:	84aa                	mv	s1,a0
    if(ip == 0){
    800059c2:	c959                	beqz	a0,80005a58 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059c4:	04449703          	lh	a4,68(s1)
    800059c8:	478d                	li	a5,3
    800059ca:	00f71763          	bne	a4,a5,800059d8 <sys_open+0x72>
    800059ce:	0464d703          	lhu	a4,70(s1)
    800059d2:	47a5                	li	a5,9
    800059d4:	0ce7ed63          	bltu	a5,a4,80005aae <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	dce080e7          	jalr	-562(ra) # 800047a6 <filealloc>
    800059e0:	89aa                	mv	s3,a0
    800059e2:	10050363          	beqz	a0,80005ae8 <sys_open+0x182>
    800059e6:	00000097          	auipc	ra,0x0
    800059ea:	904080e7          	jalr	-1788(ra) # 800052ea <fdalloc>
    800059ee:	892a                	mv	s2,a0
    800059f0:	0e054763          	bltz	a0,80005ade <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059f4:	04449703          	lh	a4,68(s1)
    800059f8:	478d                	li	a5,3
    800059fa:	0cf70563          	beq	a4,a5,80005ac4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059fe:	4789                	li	a5,2
    80005a00:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a04:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a08:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a0c:	f4c42783          	lw	a5,-180(s0)
    80005a10:	0017c713          	xori	a4,a5,1
    80005a14:	8b05                	andi	a4,a4,1
    80005a16:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a1a:	0037f713          	andi	a4,a5,3
    80005a1e:	00e03733          	snez	a4,a4
    80005a22:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a26:	4007f793          	andi	a5,a5,1024
    80005a2a:	c791                	beqz	a5,80005a36 <sys_open+0xd0>
    80005a2c:	04449703          	lh	a4,68(s1)
    80005a30:	4789                	li	a5,2
    80005a32:	0af70063          	beq	a4,a5,80005ad2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	05e080e7          	jalr	94(ra) # 80003a96 <iunlock>
  end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	9d6080e7          	jalr	-1578(ra) # 80004416 <end_op>

  return fd;
    80005a48:	854a                	mv	a0,s2
}
    80005a4a:	70ea                	ld	ra,184(sp)
    80005a4c:	744a                	ld	s0,176(sp)
    80005a4e:	74aa                	ld	s1,168(sp)
    80005a50:	790a                	ld	s2,160(sp)
    80005a52:	69ea                	ld	s3,152(sp)
    80005a54:	6129                	addi	sp,sp,192
    80005a56:	8082                	ret
      end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	9be080e7          	jalr	-1602(ra) # 80004416 <end_op>
      return -1;
    80005a60:	557d                	li	a0,-1
    80005a62:	b7e5                	j	80005a4a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a64:	f5040513          	addi	a0,s0,-176
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	712080e7          	jalr	1810(ra) # 8000417a <namei>
    80005a70:	84aa                	mv	s1,a0
    80005a72:	c905                	beqz	a0,80005aa2 <sys_open+0x13c>
    ilock(ip);
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	f60080e7          	jalr	-160(ra) # 800039d4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a7c:	04449703          	lh	a4,68(s1)
    80005a80:	4785                	li	a5,1
    80005a82:	f4f711e3          	bne	a4,a5,800059c4 <sys_open+0x5e>
    80005a86:	f4c42783          	lw	a5,-180(s0)
    80005a8a:	d7b9                	beqz	a5,800059d8 <sys_open+0x72>
      iunlockput(ip);
    80005a8c:	8526                	mv	a0,s1
    80005a8e:	ffffe097          	auipc	ra,0xffffe
    80005a92:	1a8080e7          	jalr	424(ra) # 80003c36 <iunlockput>
      end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	980080e7          	jalr	-1664(ra) # 80004416 <end_op>
      return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	b76d                	j	80005a4a <sys_open+0xe4>
      end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	974080e7          	jalr	-1676(ra) # 80004416 <end_op>
      return -1;
    80005aaa:	557d                	li	a0,-1
    80005aac:	bf79                	j	80005a4a <sys_open+0xe4>
    iunlockput(ip);
    80005aae:	8526                	mv	a0,s1
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	186080e7          	jalr	390(ra) # 80003c36 <iunlockput>
    end_op();
    80005ab8:	fffff097          	auipc	ra,0xfffff
    80005abc:	95e080e7          	jalr	-1698(ra) # 80004416 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	b761                	j	80005a4a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ac4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ac8:	04649783          	lh	a5,70(s1)
    80005acc:	02f99223          	sh	a5,36(s3)
    80005ad0:	bf25                	j	80005a08 <sys_open+0xa2>
    itrunc(ip);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	00e080e7          	jalr	14(ra) # 80003ae2 <itrunc>
    80005adc:	bfa9                	j	80005a36 <sys_open+0xd0>
      fileclose(f);
    80005ade:	854e                	mv	a0,s3
    80005ae0:	fffff097          	auipc	ra,0xfffff
    80005ae4:	d82080e7          	jalr	-638(ra) # 80004862 <fileclose>
    iunlockput(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	14c080e7          	jalr	332(ra) # 80003c36 <iunlockput>
    end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	924080e7          	jalr	-1756(ra) # 80004416 <end_op>
    return -1;
    80005afa:	557d                	li	a0,-1
    80005afc:	b7b9                	j	80005a4a <sys_open+0xe4>

0000000080005afe <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005afe:	7175                	addi	sp,sp,-144
    80005b00:	e506                	sd	ra,136(sp)
    80005b02:	e122                	sd	s0,128(sp)
    80005b04:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	890080e7          	jalr	-1904(ra) # 80004396 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b0e:	08000613          	li	a2,128
    80005b12:	f7040593          	addi	a1,s0,-144
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	1f4080e7          	jalr	500(ra) # 80002d0c <argstr>
    80005b20:	02054963          	bltz	a0,80005b52 <sys_mkdir+0x54>
    80005b24:	4681                	li	a3,0
    80005b26:	4601                	li	a2,0
    80005b28:	4585                	li	a1,1
    80005b2a:	f7040513          	addi	a0,s0,-144
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	7fe080e7          	jalr	2046(ra) # 8000532c <create>
    80005b36:	cd11                	beqz	a0,80005b52 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	0fe080e7          	jalr	254(ra) # 80003c36 <iunlockput>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	8d6080e7          	jalr	-1834(ra) # 80004416 <end_op>
  return 0;
    80005b48:	4501                	li	a0,0
}
    80005b4a:	60aa                	ld	ra,136(sp)
    80005b4c:	640a                	ld	s0,128(sp)
    80005b4e:	6149                	addi	sp,sp,144
    80005b50:	8082                	ret
    end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	8c4080e7          	jalr	-1852(ra) # 80004416 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	b7fd                	j	80005b4a <sys_mkdir+0x4c>

0000000080005b5e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b5e:	7135                	addi	sp,sp,-160
    80005b60:	ed06                	sd	ra,152(sp)
    80005b62:	e922                	sd	s0,144(sp)
    80005b64:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	830080e7          	jalr	-2000(ra) # 80004396 <begin_op>
  argint(1, &major);
    80005b6e:	f6c40593          	addi	a1,s0,-148
    80005b72:	4505                	li	a0,1
    80005b74:	ffffd097          	auipc	ra,0xffffd
    80005b78:	154080e7          	jalr	340(ra) # 80002cc8 <argint>
  argint(2, &minor);
    80005b7c:	f6840593          	addi	a1,s0,-152
    80005b80:	4509                	li	a0,2
    80005b82:	ffffd097          	auipc	ra,0xffffd
    80005b86:	146080e7          	jalr	326(ra) # 80002cc8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b8a:	08000613          	li	a2,128
    80005b8e:	f7040593          	addi	a1,s0,-144
    80005b92:	4501                	li	a0,0
    80005b94:	ffffd097          	auipc	ra,0xffffd
    80005b98:	178080e7          	jalr	376(ra) # 80002d0c <argstr>
    80005b9c:	02054b63          	bltz	a0,80005bd2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ba0:	f6841683          	lh	a3,-152(s0)
    80005ba4:	f6c41603          	lh	a2,-148(s0)
    80005ba8:	458d                	li	a1,3
    80005baa:	f7040513          	addi	a0,s0,-144
    80005bae:	fffff097          	auipc	ra,0xfffff
    80005bb2:	77e080e7          	jalr	1918(ra) # 8000532c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb6:	cd11                	beqz	a0,80005bd2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bb8:	ffffe097          	auipc	ra,0xffffe
    80005bbc:	07e080e7          	jalr	126(ra) # 80003c36 <iunlockput>
  end_op();
    80005bc0:	fffff097          	auipc	ra,0xfffff
    80005bc4:	856080e7          	jalr	-1962(ra) # 80004416 <end_op>
  return 0;
    80005bc8:	4501                	li	a0,0
}
    80005bca:	60ea                	ld	ra,152(sp)
    80005bcc:	644a                	ld	s0,144(sp)
    80005bce:	610d                	addi	sp,sp,160
    80005bd0:	8082                	ret
    end_op();
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	844080e7          	jalr	-1980(ra) # 80004416 <end_op>
    return -1;
    80005bda:	557d                	li	a0,-1
    80005bdc:	b7fd                	j	80005bca <sys_mknod+0x6c>

0000000080005bde <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bde:	7135                	addi	sp,sp,-160
    80005be0:	ed06                	sd	ra,152(sp)
    80005be2:	e922                	sd	s0,144(sp)
    80005be4:	e526                	sd	s1,136(sp)
    80005be6:	e14a                	sd	s2,128(sp)
    80005be8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bea:	ffffc097          	auipc	ra,0xffffc
    80005bee:	ddc080e7          	jalr	-548(ra) # 800019c6 <myproc>
    80005bf2:	892a                	mv	s2,a0
  
  begin_op();
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	7a2080e7          	jalr	1954(ra) # 80004396 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bfc:	08000613          	li	a2,128
    80005c00:	f6040593          	addi	a1,s0,-160
    80005c04:	4501                	li	a0,0
    80005c06:	ffffd097          	auipc	ra,0xffffd
    80005c0a:	106080e7          	jalr	262(ra) # 80002d0c <argstr>
    80005c0e:	04054b63          	bltz	a0,80005c64 <sys_chdir+0x86>
    80005c12:	f6040513          	addi	a0,s0,-160
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	564080e7          	jalr	1380(ra) # 8000417a <namei>
    80005c1e:	84aa                	mv	s1,a0
    80005c20:	c131                	beqz	a0,80005c64 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	db2080e7          	jalr	-590(ra) # 800039d4 <ilock>
  if(ip->type != T_DIR){
    80005c2a:	04449703          	lh	a4,68(s1)
    80005c2e:	4785                	li	a5,1
    80005c30:	04f71063          	bne	a4,a5,80005c70 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c34:	8526                	mv	a0,s1
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	e60080e7          	jalr	-416(ra) # 80003a96 <iunlock>
  iput(p->cwd);
    80005c3e:	15893503          	ld	a0,344(s2)
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	f4c080e7          	jalr	-180(ra) # 80003b8e <iput>
  end_op();
    80005c4a:	ffffe097          	auipc	ra,0xffffe
    80005c4e:	7cc080e7          	jalr	1996(ra) # 80004416 <end_op>
  p->cwd = ip;
    80005c52:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c56:	4501                	li	a0,0
}
    80005c58:	60ea                	ld	ra,152(sp)
    80005c5a:	644a                	ld	s0,144(sp)
    80005c5c:	64aa                	ld	s1,136(sp)
    80005c5e:	690a                	ld	s2,128(sp)
    80005c60:	610d                	addi	sp,sp,160
    80005c62:	8082                	ret
    end_op();
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	7b2080e7          	jalr	1970(ra) # 80004416 <end_op>
    return -1;
    80005c6c:	557d                	li	a0,-1
    80005c6e:	b7ed                	j	80005c58 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c70:	8526                	mv	a0,s1
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	fc4080e7          	jalr	-60(ra) # 80003c36 <iunlockput>
    end_op();
    80005c7a:	ffffe097          	auipc	ra,0xffffe
    80005c7e:	79c080e7          	jalr	1948(ra) # 80004416 <end_op>
    return -1;
    80005c82:	557d                	li	a0,-1
    80005c84:	bfd1                	j	80005c58 <sys_chdir+0x7a>

0000000080005c86 <sys_exec>:

uint64
sys_exec(void)
{
    80005c86:	7145                	addi	sp,sp,-464
    80005c88:	e786                	sd	ra,456(sp)
    80005c8a:	e3a2                	sd	s0,448(sp)
    80005c8c:	ff26                	sd	s1,440(sp)
    80005c8e:	fb4a                	sd	s2,432(sp)
    80005c90:	f74e                	sd	s3,424(sp)
    80005c92:	f352                	sd	s4,416(sp)
    80005c94:	ef56                	sd	s5,408(sp)
    80005c96:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c98:	e3840593          	addi	a1,s0,-456
    80005c9c:	4505                	li	a0,1
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	04c080e7          	jalr	76(ra) # 80002cea <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ca6:	08000613          	li	a2,128
    80005caa:	f4040593          	addi	a1,s0,-192
    80005cae:	4501                	li	a0,0
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	05c080e7          	jalr	92(ra) # 80002d0c <argstr>
    80005cb8:	87aa                	mv	a5,a0
    return -1;
    80005cba:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cbc:	0c07c263          	bltz	a5,80005d80 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cc0:	10000613          	li	a2,256
    80005cc4:	4581                	li	a1,0
    80005cc6:	e4040513          	addi	a0,s0,-448
    80005cca:	ffffb097          	auipc	ra,0xffffb
    80005cce:	01c080e7          	jalr	28(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cd2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cd6:	89a6                	mv	s3,s1
    80005cd8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cda:	02000a13          	li	s4,32
    80005cde:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ce2:	00391513          	slli	a0,s2,0x3
    80005ce6:	e3040593          	addi	a1,s0,-464
    80005cea:	e3843783          	ld	a5,-456(s0)
    80005cee:	953e                	add	a0,a0,a5
    80005cf0:	ffffd097          	auipc	ra,0xffffd
    80005cf4:	f3a080e7          	jalr	-198(ra) # 80002c2a <fetchaddr>
    80005cf8:	02054a63          	bltz	a0,80005d2c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005cfc:	e3043783          	ld	a5,-464(s0)
    80005d00:	c3b9                	beqz	a5,80005d46 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d02:	ffffb097          	auipc	ra,0xffffb
    80005d06:	df8080e7          	jalr	-520(ra) # 80000afa <kalloc>
    80005d0a:	85aa                	mv	a1,a0
    80005d0c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d10:	cd11                	beqz	a0,80005d2c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d12:	6605                	lui	a2,0x1
    80005d14:	e3043503          	ld	a0,-464(s0)
    80005d18:	ffffd097          	auipc	ra,0xffffd
    80005d1c:	f64080e7          	jalr	-156(ra) # 80002c7c <fetchstr>
    80005d20:	00054663          	bltz	a0,80005d2c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d24:	0905                	addi	s2,s2,1
    80005d26:	09a1                	addi	s3,s3,8
    80005d28:	fb491be3          	bne	s2,s4,80005cde <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d2c:	10048913          	addi	s2,s1,256
    80005d30:	6088                	ld	a0,0(s1)
    80005d32:	c531                	beqz	a0,80005d7e <sys_exec+0xf8>
    kfree(argv[i]);
    80005d34:	ffffb097          	auipc	ra,0xffffb
    80005d38:	cca080e7          	jalr	-822(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d3c:	04a1                	addi	s1,s1,8
    80005d3e:	ff2499e3          	bne	s1,s2,80005d30 <sys_exec+0xaa>
  return -1;
    80005d42:	557d                	li	a0,-1
    80005d44:	a835                	j	80005d80 <sys_exec+0xfa>
      argv[i] = 0;
    80005d46:	0a8e                	slli	s5,s5,0x3
    80005d48:	fc040793          	addi	a5,s0,-64
    80005d4c:	9abe                	add	s5,s5,a5
    80005d4e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d52:	e4040593          	addi	a1,s0,-448
    80005d56:	f4040513          	addi	a0,s0,-192
    80005d5a:	fffff097          	auipc	ra,0xfffff
    80005d5e:	190080e7          	jalr	400(ra) # 80004eea <exec>
    80005d62:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d64:	10048993          	addi	s3,s1,256
    80005d68:	6088                	ld	a0,0(s1)
    80005d6a:	c901                	beqz	a0,80005d7a <sys_exec+0xf4>
    kfree(argv[i]);
    80005d6c:	ffffb097          	auipc	ra,0xffffb
    80005d70:	c92080e7          	jalr	-878(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d74:	04a1                	addi	s1,s1,8
    80005d76:	ff3499e3          	bne	s1,s3,80005d68 <sys_exec+0xe2>
  return ret;
    80005d7a:	854a                	mv	a0,s2
    80005d7c:	a011                	j	80005d80 <sys_exec+0xfa>
  return -1;
    80005d7e:	557d                	li	a0,-1
}
    80005d80:	60be                	ld	ra,456(sp)
    80005d82:	641e                	ld	s0,448(sp)
    80005d84:	74fa                	ld	s1,440(sp)
    80005d86:	795a                	ld	s2,432(sp)
    80005d88:	79ba                	ld	s3,424(sp)
    80005d8a:	7a1a                	ld	s4,416(sp)
    80005d8c:	6afa                	ld	s5,408(sp)
    80005d8e:	6179                	addi	sp,sp,464
    80005d90:	8082                	ret

0000000080005d92 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d92:	7139                	addi	sp,sp,-64
    80005d94:	fc06                	sd	ra,56(sp)
    80005d96:	f822                	sd	s0,48(sp)
    80005d98:	f426                	sd	s1,40(sp)
    80005d9a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	c2a080e7          	jalr	-982(ra) # 800019c6 <myproc>
    80005da4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005da6:	fd840593          	addi	a1,s0,-40
    80005daa:	4501                	li	a0,0
    80005dac:	ffffd097          	auipc	ra,0xffffd
    80005db0:	f3e080e7          	jalr	-194(ra) # 80002cea <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005db4:	fc840593          	addi	a1,s0,-56
    80005db8:	fd040513          	addi	a0,s0,-48
    80005dbc:	fffff097          	auipc	ra,0xfffff
    80005dc0:	dd6080e7          	jalr	-554(ra) # 80004b92 <pipealloc>
    return -1;
    80005dc4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dc6:	0c054463          	bltz	a0,80005e8e <sys_pipe+0xfc>
  fd0 = -1;
    80005dca:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dce:	fd043503          	ld	a0,-48(s0)
    80005dd2:	fffff097          	auipc	ra,0xfffff
    80005dd6:	518080e7          	jalr	1304(ra) # 800052ea <fdalloc>
    80005dda:	fca42223          	sw	a0,-60(s0)
    80005dde:	08054b63          	bltz	a0,80005e74 <sys_pipe+0xe2>
    80005de2:	fc843503          	ld	a0,-56(s0)
    80005de6:	fffff097          	auipc	ra,0xfffff
    80005dea:	504080e7          	jalr	1284(ra) # 800052ea <fdalloc>
    80005dee:	fca42023          	sw	a0,-64(s0)
    80005df2:	06054863          	bltz	a0,80005e62 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005df6:	4691                	li	a3,4
    80005df8:	fc440613          	addi	a2,s0,-60
    80005dfc:	fd843583          	ld	a1,-40(s0)
    80005e00:	6ca8                	ld	a0,88(s1)
    80005e02:	ffffc097          	auipc	ra,0xffffc
    80005e06:	882080e7          	jalr	-1918(ra) # 80001684 <copyout>
    80005e0a:	02054063          	bltz	a0,80005e2a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e0e:	4691                	li	a3,4
    80005e10:	fc040613          	addi	a2,s0,-64
    80005e14:	fd843583          	ld	a1,-40(s0)
    80005e18:	0591                	addi	a1,a1,4
    80005e1a:	6ca8                	ld	a0,88(s1)
    80005e1c:	ffffc097          	auipc	ra,0xffffc
    80005e20:	868080e7          	jalr	-1944(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e24:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e26:	06055463          	bgez	a0,80005e8e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e2a:	fc442783          	lw	a5,-60(s0)
    80005e2e:	07e9                	addi	a5,a5,26
    80005e30:	078e                	slli	a5,a5,0x3
    80005e32:	97a6                	add	a5,a5,s1
    80005e34:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e38:	fc042503          	lw	a0,-64(s0)
    80005e3c:	0569                	addi	a0,a0,26
    80005e3e:	050e                	slli	a0,a0,0x3
    80005e40:	94aa                	add	s1,s1,a0
    80005e42:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005e46:	fd043503          	ld	a0,-48(s0)
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	a18080e7          	jalr	-1512(ra) # 80004862 <fileclose>
    fileclose(wf);
    80005e52:	fc843503          	ld	a0,-56(s0)
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	a0c080e7          	jalr	-1524(ra) # 80004862 <fileclose>
    return -1;
    80005e5e:	57fd                	li	a5,-1
    80005e60:	a03d                	j	80005e8e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e62:	fc442783          	lw	a5,-60(s0)
    80005e66:	0007c763          	bltz	a5,80005e74 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e6a:	07e9                	addi	a5,a5,26
    80005e6c:	078e                	slli	a5,a5,0x3
    80005e6e:	94be                	add	s1,s1,a5
    80005e70:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005e74:	fd043503          	ld	a0,-48(s0)
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	9ea080e7          	jalr	-1558(ra) # 80004862 <fileclose>
    fileclose(wf);
    80005e80:	fc843503          	ld	a0,-56(s0)
    80005e84:	fffff097          	auipc	ra,0xfffff
    80005e88:	9de080e7          	jalr	-1570(ra) # 80004862 <fileclose>
    return -1;
    80005e8c:	57fd                	li	a5,-1
}
    80005e8e:	853e                	mv	a0,a5
    80005e90:	70e2                	ld	ra,56(sp)
    80005e92:	7442                	ld	s0,48(sp)
    80005e94:	74a2                	ld	s1,40(sp)
    80005e96:	6121                	addi	sp,sp,64
    80005e98:	8082                	ret
    80005e9a:	0000                	unimp
    80005e9c:	0000                	unimp
	...

0000000080005ea0 <kernelvec>:
    80005ea0:	7111                	addi	sp,sp,-256
    80005ea2:	e006                	sd	ra,0(sp)
    80005ea4:	e40a                	sd	sp,8(sp)
    80005ea6:	e80e                	sd	gp,16(sp)
    80005ea8:	ec12                	sd	tp,24(sp)
    80005eaa:	f016                	sd	t0,32(sp)
    80005eac:	f41a                	sd	t1,40(sp)
    80005eae:	f81e                	sd	t2,48(sp)
    80005eb0:	fc22                	sd	s0,56(sp)
    80005eb2:	e0a6                	sd	s1,64(sp)
    80005eb4:	e4aa                	sd	a0,72(sp)
    80005eb6:	e8ae                	sd	a1,80(sp)
    80005eb8:	ecb2                	sd	a2,88(sp)
    80005eba:	f0b6                	sd	a3,96(sp)
    80005ebc:	f4ba                	sd	a4,104(sp)
    80005ebe:	f8be                	sd	a5,112(sp)
    80005ec0:	fcc2                	sd	a6,120(sp)
    80005ec2:	e146                	sd	a7,128(sp)
    80005ec4:	e54a                	sd	s2,136(sp)
    80005ec6:	e94e                	sd	s3,144(sp)
    80005ec8:	ed52                	sd	s4,152(sp)
    80005eca:	f156                	sd	s5,160(sp)
    80005ecc:	f55a                	sd	s6,168(sp)
    80005ece:	f95e                	sd	s7,176(sp)
    80005ed0:	fd62                	sd	s8,184(sp)
    80005ed2:	e1e6                	sd	s9,192(sp)
    80005ed4:	e5ea                	sd	s10,200(sp)
    80005ed6:	e9ee                	sd	s11,208(sp)
    80005ed8:	edf2                	sd	t3,216(sp)
    80005eda:	f1f6                	sd	t4,224(sp)
    80005edc:	f5fa                	sd	t5,232(sp)
    80005ede:	f9fe                	sd	t6,240(sp)
    80005ee0:	c17fc0ef          	jal	ra,80002af6 <kerneltrap>
    80005ee4:	6082                	ld	ra,0(sp)
    80005ee6:	6122                	ld	sp,8(sp)
    80005ee8:	61c2                	ld	gp,16(sp)
    80005eea:	7282                	ld	t0,32(sp)
    80005eec:	7322                	ld	t1,40(sp)
    80005eee:	73c2                	ld	t2,48(sp)
    80005ef0:	7462                	ld	s0,56(sp)
    80005ef2:	6486                	ld	s1,64(sp)
    80005ef4:	6526                	ld	a0,72(sp)
    80005ef6:	65c6                	ld	a1,80(sp)
    80005ef8:	6666                	ld	a2,88(sp)
    80005efa:	7686                	ld	a3,96(sp)
    80005efc:	7726                	ld	a4,104(sp)
    80005efe:	77c6                	ld	a5,112(sp)
    80005f00:	7866                	ld	a6,120(sp)
    80005f02:	688a                	ld	a7,128(sp)
    80005f04:	692a                	ld	s2,136(sp)
    80005f06:	69ca                	ld	s3,144(sp)
    80005f08:	6a6a                	ld	s4,152(sp)
    80005f0a:	7a8a                	ld	s5,160(sp)
    80005f0c:	7b2a                	ld	s6,168(sp)
    80005f0e:	7bca                	ld	s7,176(sp)
    80005f10:	7c6a                	ld	s8,184(sp)
    80005f12:	6c8e                	ld	s9,192(sp)
    80005f14:	6d2e                	ld	s10,200(sp)
    80005f16:	6dce                	ld	s11,208(sp)
    80005f18:	6e6e                	ld	t3,216(sp)
    80005f1a:	7e8e                	ld	t4,224(sp)
    80005f1c:	7f2e                	ld	t5,232(sp)
    80005f1e:	7fce                	ld	t6,240(sp)
    80005f20:	6111                	addi	sp,sp,256
    80005f22:	10200073          	sret
    80005f26:	00000013          	nop
    80005f2a:	00000013          	nop
    80005f2e:	0001                	nop

0000000080005f30 <timervec>:
    80005f30:	34051573          	csrrw	a0,mscratch,a0
    80005f34:	e10c                	sd	a1,0(a0)
    80005f36:	e510                	sd	a2,8(a0)
    80005f38:	e914                	sd	a3,16(a0)
    80005f3a:	6d0c                	ld	a1,24(a0)
    80005f3c:	7110                	ld	a2,32(a0)
    80005f3e:	6194                	ld	a3,0(a1)
    80005f40:	96b2                	add	a3,a3,a2
    80005f42:	e194                	sd	a3,0(a1)
    80005f44:	4589                	li	a1,2
    80005f46:	14459073          	csrw	sip,a1
    80005f4a:	6914                	ld	a3,16(a0)
    80005f4c:	6510                	ld	a2,8(a0)
    80005f4e:	610c                	ld	a1,0(a0)
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	30200073          	mret
	...

0000000080005f5a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f5a:	1141                	addi	sp,sp,-16
    80005f5c:	e422                	sd	s0,8(sp)
    80005f5e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f60:	0c0007b7          	lui	a5,0xc000
    80005f64:	4705                	li	a4,1
    80005f66:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f68:	c3d8                	sw	a4,4(a5)
}
    80005f6a:	6422                	ld	s0,8(sp)
    80005f6c:	0141                	addi	sp,sp,16
    80005f6e:	8082                	ret

0000000080005f70 <plicinithart>:

void
plicinithart(void)
{
    80005f70:	1141                	addi	sp,sp,-16
    80005f72:	e406                	sd	ra,8(sp)
    80005f74:	e022                	sd	s0,0(sp)
    80005f76:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a22080e7          	jalr	-1502(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f80:	0085171b          	slliw	a4,a0,0x8
    80005f84:	0c0027b7          	lui	a5,0xc002
    80005f88:	97ba                	add	a5,a5,a4
    80005f8a:	40200713          	li	a4,1026
    80005f8e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f92:	00d5151b          	slliw	a0,a0,0xd
    80005f96:	0c2017b7          	lui	a5,0xc201
    80005f9a:	953e                	add	a0,a0,a5
    80005f9c:	00052023          	sw	zero,0(a0)
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret

0000000080005fa8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fa8:	1141                	addi	sp,sp,-16
    80005faa:	e406                	sd	ra,8(sp)
    80005fac:	e022                	sd	s0,0(sp)
    80005fae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fb0:	ffffc097          	auipc	ra,0xffffc
    80005fb4:	9ea080e7          	jalr	-1558(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fb8:	00d5179b          	slliw	a5,a0,0xd
    80005fbc:	0c201537          	lui	a0,0xc201
    80005fc0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fc2:	4148                	lw	a0,4(a0)
    80005fc4:	60a2                	ld	ra,8(sp)
    80005fc6:	6402                	ld	s0,0(sp)
    80005fc8:	0141                	addi	sp,sp,16
    80005fca:	8082                	ret

0000000080005fcc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fcc:	1101                	addi	sp,sp,-32
    80005fce:	ec06                	sd	ra,24(sp)
    80005fd0:	e822                	sd	s0,16(sp)
    80005fd2:	e426                	sd	s1,8(sp)
    80005fd4:	1000                	addi	s0,sp,32
    80005fd6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	9c2080e7          	jalr	-1598(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fe0:	00d5151b          	slliw	a0,a0,0xd
    80005fe4:	0c2017b7          	lui	a5,0xc201
    80005fe8:	97aa                	add	a5,a5,a0
    80005fea:	c3c4                	sw	s1,4(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6105                	addi	sp,sp,32
    80005ff4:	8082                	ret

0000000080005ff6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ff6:	1141                	addi	sp,sp,-16
    80005ff8:	e406                	sd	ra,8(sp)
    80005ffa:	e022                	sd	s0,0(sp)
    80005ffc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ffe:	479d                	li	a5,7
    80006000:	04a7cc63          	blt	a5,a0,80006058 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006004:	0001d797          	auipc	a5,0x1d
    80006008:	46478793          	addi	a5,a5,1124 # 80023468 <disk>
    8000600c:	97aa                	add	a5,a5,a0
    8000600e:	0187c783          	lbu	a5,24(a5)
    80006012:	ebb9                	bnez	a5,80006068 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006014:	00451613          	slli	a2,a0,0x4
    80006018:	0001d797          	auipc	a5,0x1d
    8000601c:	45078793          	addi	a5,a5,1104 # 80023468 <disk>
    80006020:	6394                	ld	a3,0(a5)
    80006022:	96b2                	add	a3,a3,a2
    80006024:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006028:	6398                	ld	a4,0(a5)
    8000602a:	9732                	add	a4,a4,a2
    8000602c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006030:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006034:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006038:	953e                	add	a0,a0,a5
    8000603a:	4785                	li	a5,1
    8000603c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006040:	0001d517          	auipc	a0,0x1d
    80006044:	44050513          	addi	a0,a0,1088 # 80023480 <disk+0x18>
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	25e080e7          	jalr	606(ra) # 800022a6 <wakeup>
}
    80006050:	60a2                	ld	ra,8(sp)
    80006052:	6402                	ld	s0,0(sp)
    80006054:	0141                	addi	sp,sp,16
    80006056:	8082                	ret
    panic("free_desc 1");
    80006058:	00003517          	auipc	a0,0x3
    8000605c:	92050513          	addi	a0,a0,-1760 # 80008978 <syscall_argc+0x2a0>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e4080e7          	jalr	1252(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006068:	00003517          	auipc	a0,0x3
    8000606c:	92050513          	addi	a0,a0,-1760 # 80008988 <syscall_argc+0x2b0>
    80006070:	ffffa097          	auipc	ra,0xffffa
    80006074:	4d4080e7          	jalr	1236(ra) # 80000544 <panic>

0000000080006078 <virtio_disk_init>:
{
    80006078:	1101                	addi	sp,sp,-32
    8000607a:	ec06                	sd	ra,24(sp)
    8000607c:	e822                	sd	s0,16(sp)
    8000607e:	e426                	sd	s1,8(sp)
    80006080:	e04a                	sd	s2,0(sp)
    80006082:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006084:	00003597          	auipc	a1,0x3
    80006088:	91458593          	addi	a1,a1,-1772 # 80008998 <syscall_argc+0x2c0>
    8000608c:	0001d517          	auipc	a0,0x1d
    80006090:	50450513          	addi	a0,a0,1284 # 80023590 <disk+0x128>
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	ac6080e7          	jalr	-1338(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000609c:	100017b7          	lui	a5,0x10001
    800060a0:	4398                	lw	a4,0(a5)
    800060a2:	2701                	sext.w	a4,a4
    800060a4:	747277b7          	lui	a5,0x74727
    800060a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060ac:	14f71e63          	bne	a4,a5,80006208 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060b0:	100017b7          	lui	a5,0x10001
    800060b4:	43dc                	lw	a5,4(a5)
    800060b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060b8:	4709                	li	a4,2
    800060ba:	14e79763          	bne	a5,a4,80006208 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060be:	100017b7          	lui	a5,0x10001
    800060c2:	479c                	lw	a5,8(a5)
    800060c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060c6:	14e79163          	bne	a5,a4,80006208 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ca:	100017b7          	lui	a5,0x10001
    800060ce:	47d8                	lw	a4,12(a5)
    800060d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060d2:	554d47b7          	lui	a5,0x554d4
    800060d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060da:	12f71763          	bne	a4,a5,80006208 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e6:	4705                	li	a4,1
    800060e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ea:	470d                	li	a4,3
    800060ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060f0:	c7ffe737          	lui	a4,0xc7ffe
    800060f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb1b7>
    800060f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060fa:	2701                	sext.w	a4,a4
    800060fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fe:	472d                	li	a4,11
    80006100:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006102:	0707a903          	lw	s2,112(a5)
    80006106:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006108:	00897793          	andi	a5,s2,8
    8000610c:	10078663          	beqz	a5,80006218 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006110:	100017b7          	lui	a5,0x10001
    80006114:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006118:	43fc                	lw	a5,68(a5)
    8000611a:	2781                	sext.w	a5,a5
    8000611c:	10079663          	bnez	a5,80006228 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006120:	100017b7          	lui	a5,0x10001
    80006124:	5bdc                	lw	a5,52(a5)
    80006126:	2781                	sext.w	a5,a5
  if(max == 0)
    80006128:	10078863          	beqz	a5,80006238 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000612c:	471d                	li	a4,7
    8000612e:	10f77d63          	bgeu	a4,a5,80006248 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	9c8080e7          	jalr	-1592(ra) # 80000afa <kalloc>
    8000613a:	0001d497          	auipc	s1,0x1d
    8000613e:	32e48493          	addi	s1,s1,814 # 80023468 <disk>
    80006142:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006144:	ffffb097          	auipc	ra,0xffffb
    80006148:	9b6080e7          	jalr	-1610(ra) # 80000afa <kalloc>
    8000614c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	9ac080e7          	jalr	-1620(ra) # 80000afa <kalloc>
    80006156:	87aa                	mv	a5,a0
    80006158:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000615a:	6088                	ld	a0,0(s1)
    8000615c:	cd75                	beqz	a0,80006258 <virtio_disk_init+0x1e0>
    8000615e:	0001d717          	auipc	a4,0x1d
    80006162:	31273703          	ld	a4,786(a4) # 80023470 <disk+0x8>
    80006166:	cb6d                	beqz	a4,80006258 <virtio_disk_init+0x1e0>
    80006168:	cbe5                	beqz	a5,80006258 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000616a:	6605                	lui	a2,0x1
    8000616c:	4581                	li	a1,0
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	b78080e7          	jalr	-1160(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006176:	0001d497          	auipc	s1,0x1d
    8000617a:	2f248493          	addi	s1,s1,754 # 80023468 <disk>
    8000617e:	6605                	lui	a2,0x1
    80006180:	4581                	li	a1,0
    80006182:	6488                	ld	a0,8(s1)
    80006184:	ffffb097          	auipc	ra,0xffffb
    80006188:	b62080e7          	jalr	-1182(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000618c:	6605                	lui	a2,0x1
    8000618e:	4581                	li	a1,0
    80006190:	6888                	ld	a0,16(s1)
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	b54080e7          	jalr	-1196(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000619a:	100017b7          	lui	a5,0x10001
    8000619e:	4721                	li	a4,8
    800061a0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061a2:	4098                	lw	a4,0(s1)
    800061a4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061a8:	40d8                	lw	a4,4(s1)
    800061aa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ae:	6498                	ld	a4,8(s1)
    800061b0:	0007069b          	sext.w	a3,a4
    800061b4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061b8:	9701                	srai	a4,a4,0x20
    800061ba:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061be:	6898                	ld	a4,16(s1)
    800061c0:	0007069b          	sext.w	a3,a4
    800061c4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061c8:	9701                	srai	a4,a4,0x20
    800061ca:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061ce:	4685                	li	a3,1
    800061d0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800061d2:	4705                	li	a4,1
    800061d4:	00d48c23          	sb	a3,24(s1)
    800061d8:	00e48ca3          	sb	a4,25(s1)
    800061dc:	00e48d23          	sb	a4,26(s1)
    800061e0:	00e48da3          	sb	a4,27(s1)
    800061e4:	00e48e23          	sb	a4,28(s1)
    800061e8:	00e48ea3          	sb	a4,29(s1)
    800061ec:	00e48f23          	sb	a4,30(s1)
    800061f0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061f4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f8:	0727a823          	sw	s2,112(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6902                	ld	s2,0(sp)
    80006204:	6105                	addi	sp,sp,32
    80006206:	8082                	ret
    panic("could not find virtio disk");
    80006208:	00002517          	auipc	a0,0x2
    8000620c:	7a050513          	addi	a0,a0,1952 # 800089a8 <syscall_argc+0x2d0>
    80006210:	ffffa097          	auipc	ra,0xffffa
    80006214:	334080e7          	jalr	820(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006218:	00002517          	auipc	a0,0x2
    8000621c:	7b050513          	addi	a0,a0,1968 # 800089c8 <syscall_argc+0x2f0>
    80006220:	ffffa097          	auipc	ra,0xffffa
    80006224:	324080e7          	jalr	804(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	7c050513          	addi	a0,a0,1984 # 800089e8 <syscall_argc+0x310>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	314080e7          	jalr	788(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	7d050513          	addi	a0,a0,2000 # 80008a08 <syscall_argc+0x330>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	304080e7          	jalr	772(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	7e050513          	addi	a0,a0,2016 # 80008a28 <syscall_argc+0x350>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2f4080e7          	jalr	756(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006258:	00002517          	auipc	a0,0x2
    8000625c:	7f050513          	addi	a0,a0,2032 # 80008a48 <syscall_argc+0x370>
    80006260:	ffffa097          	auipc	ra,0xffffa
    80006264:	2e4080e7          	jalr	740(ra) # 80000544 <panic>

0000000080006268 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006268:	7159                	addi	sp,sp,-112
    8000626a:	f486                	sd	ra,104(sp)
    8000626c:	f0a2                	sd	s0,96(sp)
    8000626e:	eca6                	sd	s1,88(sp)
    80006270:	e8ca                	sd	s2,80(sp)
    80006272:	e4ce                	sd	s3,72(sp)
    80006274:	e0d2                	sd	s4,64(sp)
    80006276:	fc56                	sd	s5,56(sp)
    80006278:	f85a                	sd	s6,48(sp)
    8000627a:	f45e                	sd	s7,40(sp)
    8000627c:	f062                	sd	s8,32(sp)
    8000627e:	ec66                	sd	s9,24(sp)
    80006280:	e86a                	sd	s10,16(sp)
    80006282:	1880                	addi	s0,sp,112
    80006284:	892a                	mv	s2,a0
    80006286:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006288:	00c52c83          	lw	s9,12(a0)
    8000628c:	001c9c9b          	slliw	s9,s9,0x1
    80006290:	1c82                	slli	s9,s9,0x20
    80006292:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006296:	0001d517          	auipc	a0,0x1d
    8000629a:	2fa50513          	addi	a0,a0,762 # 80023590 <disk+0x128>
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	94c080e7          	jalr	-1716(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800062a6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062a8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800062aa:	0001db17          	auipc	s6,0x1d
    800062ae:	1beb0b13          	addi	s6,s6,446 # 80023468 <disk>
  for(int i = 0; i < 3; i++){
    800062b2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800062b4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062b6:	0001dc17          	auipc	s8,0x1d
    800062ba:	2dac0c13          	addi	s8,s8,730 # 80023590 <disk+0x128>
    800062be:	a8b5                	j	8000633a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800062c0:	00fb06b3          	add	a3,s6,a5
    800062c4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062c8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062ca:	0207c563          	bltz	a5,800062f4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062ce:	2485                	addiw	s1,s1,1
    800062d0:	0711                	addi	a4,a4,4
    800062d2:	1f548a63          	beq	s1,s5,800064c6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800062d6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062d8:	0001d697          	auipc	a3,0x1d
    800062dc:	19068693          	addi	a3,a3,400 # 80023468 <disk>
    800062e0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800062e2:	0186c583          	lbu	a1,24(a3)
    800062e6:	fde9                	bnez	a1,800062c0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062e8:	2785                	addiw	a5,a5,1
    800062ea:	0685                	addi	a3,a3,1
    800062ec:	ff779be3          	bne	a5,s7,800062e2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062f0:	57fd                	li	a5,-1
    800062f2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062f4:	02905a63          	blez	s1,80006328 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800062f8:	f9042503          	lw	a0,-112(s0)
    800062fc:	00000097          	auipc	ra,0x0
    80006300:	cfa080e7          	jalr	-774(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006304:	4785                	li	a5,1
    80006306:	0297d163          	bge	a5,s1,80006328 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000630a:	f9442503          	lw	a0,-108(s0)
    8000630e:	00000097          	auipc	ra,0x0
    80006312:	ce8080e7          	jalr	-792(ra) # 80005ff6 <free_desc>
      for(int j = 0; j < i; j++)
    80006316:	4789                	li	a5,2
    80006318:	0097d863          	bge	a5,s1,80006328 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000631c:	f9842503          	lw	a0,-104(s0)
    80006320:	00000097          	auipc	ra,0x0
    80006324:	cd6080e7          	jalr	-810(ra) # 80005ff6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006328:	85e2                	mv	a1,s8
    8000632a:	0001d517          	auipc	a0,0x1d
    8000632e:	15650513          	addi	a0,a0,342 # 80023480 <disk+0x18>
    80006332:	ffffc097          	auipc	ra,0xffffc
    80006336:	dc8080e7          	jalr	-568(ra) # 800020fa <sleep>
  for(int i = 0; i < 3; i++){
    8000633a:	f9040713          	addi	a4,s0,-112
    8000633e:	84ce                	mv	s1,s3
    80006340:	bf59                	j	800062d6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006342:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006346:	00479693          	slli	a3,a5,0x4
    8000634a:	0001d797          	auipc	a5,0x1d
    8000634e:	11e78793          	addi	a5,a5,286 # 80023468 <disk>
    80006352:	97b6                	add	a5,a5,a3
    80006354:	4685                	li	a3,1
    80006356:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006358:	0001d597          	auipc	a1,0x1d
    8000635c:	11058593          	addi	a1,a1,272 # 80023468 <disk>
    80006360:	00a60793          	addi	a5,a2,10
    80006364:	0792                	slli	a5,a5,0x4
    80006366:	97ae                	add	a5,a5,a1
    80006368:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000636c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006370:	f6070693          	addi	a3,a4,-160
    80006374:	619c                	ld	a5,0(a1)
    80006376:	97b6                	add	a5,a5,a3
    80006378:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000637a:	6188                	ld	a0,0(a1)
    8000637c:	96aa                	add	a3,a3,a0
    8000637e:	47c1                	li	a5,16
    80006380:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006382:	4785                	li	a5,1
    80006384:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006388:	f9442783          	lw	a5,-108(s0)
    8000638c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006390:	0792                	slli	a5,a5,0x4
    80006392:	953e                	add	a0,a0,a5
    80006394:	05890693          	addi	a3,s2,88
    80006398:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000639a:	6188                	ld	a0,0(a1)
    8000639c:	97aa                	add	a5,a5,a0
    8000639e:	40000693          	li	a3,1024
    800063a2:	c794                	sw	a3,8(a5)
  if(write)
    800063a4:	100d0d63          	beqz	s10,800064be <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063ac:	00c7d683          	lhu	a3,12(a5)
    800063b0:	0016e693          	ori	a3,a3,1
    800063b4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800063b8:	f9842583          	lw	a1,-104(s0)
    800063bc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063c0:	0001d697          	auipc	a3,0x1d
    800063c4:	0a868693          	addi	a3,a3,168 # 80023468 <disk>
    800063c8:	00260793          	addi	a5,a2,2
    800063cc:	0792                	slli	a5,a5,0x4
    800063ce:	97b6                	add	a5,a5,a3
    800063d0:	587d                	li	a6,-1
    800063d2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063d6:	0592                	slli	a1,a1,0x4
    800063d8:	952e                	add	a0,a0,a1
    800063da:	f9070713          	addi	a4,a4,-112
    800063de:	9736                	add	a4,a4,a3
    800063e0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800063e2:	6298                	ld	a4,0(a3)
    800063e4:	972e                	add	a4,a4,a1
    800063e6:	4585                	li	a1,1
    800063e8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063ea:	4509                	li	a0,2
    800063ec:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800063f0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063f4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800063f8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063fc:	6698                	ld	a4,8(a3)
    800063fe:	00275783          	lhu	a5,2(a4)
    80006402:	8b9d                	andi	a5,a5,7
    80006404:	0786                	slli	a5,a5,0x1
    80006406:	97ba                	add	a5,a5,a4
    80006408:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000640c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006410:	6698                	ld	a4,8(a3)
    80006412:	00275783          	lhu	a5,2(a4)
    80006416:	2785                	addiw	a5,a5,1
    80006418:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000641c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006420:	100017b7          	lui	a5,0x10001
    80006424:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006428:	00492703          	lw	a4,4(s2)
    8000642c:	4785                	li	a5,1
    8000642e:	02f71163          	bne	a4,a5,80006450 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006432:	0001d997          	auipc	s3,0x1d
    80006436:	15e98993          	addi	s3,s3,350 # 80023590 <disk+0x128>
  while(b->disk == 1) {
    8000643a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000643c:	85ce                	mv	a1,s3
    8000643e:	854a                	mv	a0,s2
    80006440:	ffffc097          	auipc	ra,0xffffc
    80006444:	cba080e7          	jalr	-838(ra) # 800020fa <sleep>
  while(b->disk == 1) {
    80006448:	00492783          	lw	a5,4(s2)
    8000644c:	fe9788e3          	beq	a5,s1,8000643c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006450:	f9042903          	lw	s2,-112(s0)
    80006454:	00290793          	addi	a5,s2,2
    80006458:	00479713          	slli	a4,a5,0x4
    8000645c:	0001d797          	auipc	a5,0x1d
    80006460:	00c78793          	addi	a5,a5,12 # 80023468 <disk>
    80006464:	97ba                	add	a5,a5,a4
    80006466:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000646a:	0001d997          	auipc	s3,0x1d
    8000646e:	ffe98993          	addi	s3,s3,-2 # 80023468 <disk>
    80006472:	00491713          	slli	a4,s2,0x4
    80006476:	0009b783          	ld	a5,0(s3)
    8000647a:	97ba                	add	a5,a5,a4
    8000647c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006480:	854a                	mv	a0,s2
    80006482:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006486:	00000097          	auipc	ra,0x0
    8000648a:	b70080e7          	jalr	-1168(ra) # 80005ff6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000648e:	8885                	andi	s1,s1,1
    80006490:	f0ed                	bnez	s1,80006472 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006492:	0001d517          	auipc	a0,0x1d
    80006496:	0fe50513          	addi	a0,a0,254 # 80023590 <disk+0x128>
    8000649a:	ffffb097          	auipc	ra,0xffffb
    8000649e:	804080e7          	jalr	-2044(ra) # 80000c9e <release>
}
    800064a2:	70a6                	ld	ra,104(sp)
    800064a4:	7406                	ld	s0,96(sp)
    800064a6:	64e6                	ld	s1,88(sp)
    800064a8:	6946                	ld	s2,80(sp)
    800064aa:	69a6                	ld	s3,72(sp)
    800064ac:	6a06                	ld	s4,64(sp)
    800064ae:	7ae2                	ld	s5,56(sp)
    800064b0:	7b42                	ld	s6,48(sp)
    800064b2:	7ba2                	ld	s7,40(sp)
    800064b4:	7c02                	ld	s8,32(sp)
    800064b6:	6ce2                	ld	s9,24(sp)
    800064b8:	6d42                	ld	s10,16(sp)
    800064ba:	6165                	addi	sp,sp,112
    800064bc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064be:	4689                	li	a3,2
    800064c0:	00d79623          	sh	a3,12(a5)
    800064c4:	b5e5                	j	800063ac <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064c6:	f9042603          	lw	a2,-112(s0)
    800064ca:	00a60713          	addi	a4,a2,10
    800064ce:	0712                	slli	a4,a4,0x4
    800064d0:	0001d517          	auipc	a0,0x1d
    800064d4:	fa050513          	addi	a0,a0,-96 # 80023470 <disk+0x8>
    800064d8:	953a                	add	a0,a0,a4
  if(write)
    800064da:	e60d14e3          	bnez	s10,80006342 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800064de:	00a60793          	addi	a5,a2,10
    800064e2:	00479693          	slli	a3,a5,0x4
    800064e6:	0001d797          	auipc	a5,0x1d
    800064ea:	f8278793          	addi	a5,a5,-126 # 80023468 <disk>
    800064ee:	97b6                	add	a5,a5,a3
    800064f0:	0007a423          	sw	zero,8(a5)
    800064f4:	b595                	j	80006358 <virtio_disk_rw+0xf0>

00000000800064f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064f6:	1101                	addi	sp,sp,-32
    800064f8:	ec06                	sd	ra,24(sp)
    800064fa:	e822                	sd	s0,16(sp)
    800064fc:	e426                	sd	s1,8(sp)
    800064fe:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006500:	0001d497          	auipc	s1,0x1d
    80006504:	f6848493          	addi	s1,s1,-152 # 80023468 <disk>
    80006508:	0001d517          	auipc	a0,0x1d
    8000650c:	08850513          	addi	a0,a0,136 # 80023590 <disk+0x128>
    80006510:	ffffa097          	auipc	ra,0xffffa
    80006514:	6da080e7          	jalr	1754(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006518:	10001737          	lui	a4,0x10001
    8000651c:	533c                	lw	a5,96(a4)
    8000651e:	8b8d                	andi	a5,a5,3
    80006520:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006522:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006526:	689c                	ld	a5,16(s1)
    80006528:	0204d703          	lhu	a4,32(s1)
    8000652c:	0027d783          	lhu	a5,2(a5)
    80006530:	04f70863          	beq	a4,a5,80006580 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006534:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006538:	6898                	ld	a4,16(s1)
    8000653a:	0204d783          	lhu	a5,32(s1)
    8000653e:	8b9d                	andi	a5,a5,7
    80006540:	078e                	slli	a5,a5,0x3
    80006542:	97ba                	add	a5,a5,a4
    80006544:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006546:	00278713          	addi	a4,a5,2
    8000654a:	0712                	slli	a4,a4,0x4
    8000654c:	9726                	add	a4,a4,s1
    8000654e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006552:	e721                	bnez	a4,8000659a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006554:	0789                	addi	a5,a5,2
    80006556:	0792                	slli	a5,a5,0x4
    80006558:	97a6                	add	a5,a5,s1
    8000655a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000655c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006560:	ffffc097          	auipc	ra,0xffffc
    80006564:	d46080e7          	jalr	-698(ra) # 800022a6 <wakeup>

    disk.used_idx += 1;
    80006568:	0204d783          	lhu	a5,32(s1)
    8000656c:	2785                	addiw	a5,a5,1
    8000656e:	17c2                	slli	a5,a5,0x30
    80006570:	93c1                	srli	a5,a5,0x30
    80006572:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006576:	6898                	ld	a4,16(s1)
    80006578:	00275703          	lhu	a4,2(a4)
    8000657c:	faf71ce3          	bne	a4,a5,80006534 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006580:	0001d517          	auipc	a0,0x1d
    80006584:	01050513          	addi	a0,a0,16 # 80023590 <disk+0x128>
    80006588:	ffffa097          	auipc	ra,0xffffa
    8000658c:	716080e7          	jalr	1814(ra) # 80000c9e <release>
}
    80006590:	60e2                	ld	ra,24(sp)
    80006592:	6442                	ld	s0,16(sp)
    80006594:	64a2                	ld	s1,8(sp)
    80006596:	6105                	addi	sp,sp,32
    80006598:	8082                	ret
      panic("virtio_disk_intr status");
    8000659a:	00002517          	auipc	a0,0x2
    8000659e:	4c650513          	addi	a0,a0,1222 # 80008a60 <syscall_argc+0x388>
    800065a2:	ffffa097          	auipc	ra,0xffffa
    800065a6:	fa2080e7          	jalr	-94(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
