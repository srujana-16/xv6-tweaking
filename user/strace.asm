
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <traceError>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/param.h"
void traceError(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    if (argc < 3 || (argv[1][NUL] < '0' || argv[1][NUL] > '9'))
   8:	4789                	li	a5,2
   a:	02a7da63          	bge	a5,a0,3e <traceError+0x3e>
   e:	6588                	ld	a0,8(a1)
  10:	00054783          	lbu	a5,0(a0)
  14:	fd07879b          	addiw	a5,a5,-48
  18:	0ff7f793          	andi	a5,a5,255
  1c:	4725                	li	a4,9
  1e:	02f76063          	bltu	a4,a5,3e <traceError+0x3e>
    {
        printf("WRONG FORMAT\n");
        exit(1);
    }

    if (trace(atoi(argv[1])) < NUL)
  22:	00000097          	auipc	ra,0x0
  26:	240080e7          	jalr	576(ra) # 262 <atoi>
  2a:	00000097          	auipc	ra,0x0
  2e:	3e0080e7          	jalr	992(ra) # 40a <trace>
  32:	02054363          	bltz	a0,58 <traceError+0x58>
    {
        printf("TRACE FAILED\n");
        exit(1);
    }
}
  36:	60a2                	ld	ra,8(sp)
  38:	6402                	ld	s0,0(sp)
  3a:	0141                	addi	sp,sp,16
  3c:	8082                	ret
        printf("WRONG FORMAT\n");
  3e:	00001517          	auipc	a0,0x1
  42:	86250513          	addi	a0,a0,-1950 # 8a0 <malloc+0xf0>
  46:	00000097          	auipc	ra,0x0
  4a:	6ac080e7          	jalr	1708(ra) # 6f2 <printf>
        exit(1);
  4e:	4505                	li	a0,1
  50:	00000097          	auipc	ra,0x0
  54:	312080e7          	jalr	786(ra) # 362 <exit>
        printf("TRACE FAILED\n");
  58:	00001517          	auipc	a0,0x1
  5c:	85850513          	addi	a0,a0,-1960 # 8b0 <malloc+0x100>
  60:	00000097          	auipc	ra,0x0
  64:	692080e7          	jalr	1682(ra) # 6f2 <printf>
        exit(1);
  68:	4505                	li	a0,1
  6a:	00000097          	auipc	ra,0x0
  6e:	2f8080e7          	jalr	760(ra) # 362 <exit>

0000000000000072 <main>:
int main(int argc, char *argv[])
{
  72:	712d                	addi	sp,sp,-288
  74:	ee06                	sd	ra,280(sp)
  76:	ea22                	sd	s0,272(sp)
  78:	e626                	sd	s1,264(sp)
  7a:	e24a                	sd	s2,256(sp)
  7c:	1200                	addi	s0,sp,288
  7e:	84aa                	mv	s1,a0
  80:	892e                	mv	s2,a1
    char *nargv[MAXARG];
    traceError(argc, argv);
  82:	00000097          	auipc	ra,0x0
  86:	f7e080e7          	jalr	-130(ra) # 0 <traceError>

    for (int i = 2; i < argc && i < MAXARG; i++)
  8a:	4789                	li	a5,2
  8c:	0297d663          	bge	a5,s1,b8 <main+0x46>
  90:	01090793          	addi	a5,s2,16
  94:	ee040713          	addi	a4,s0,-288
  98:	ffd4869b          	addiw	a3,s1,-3
  9c:	1682                	slli	a3,a3,0x20
  9e:	9281                	srli	a3,a3,0x20
  a0:	068e                	slli	a3,a3,0x3
  a2:	96be                	add	a3,a3,a5
  a4:	10090593          	addi	a1,s2,256
    {
        int j = i - 2;
        nargv[j] = argv[i];
  a8:	6390                	ld	a2,0(a5)
  aa:	e310                	sd	a2,0(a4)
    for (int i = 2; i < argc && i < MAXARG; i++)
  ac:	00d78663          	beq	a5,a3,b8 <main+0x46>
  b0:	07a1                	addi	a5,a5,8
  b2:	0721                	addi	a4,a4,8
  b4:	feb79ae3          	bne	a5,a1,a8 <main+0x36>
    }
    exec(nargv[0], nargv);
  b8:	ee040593          	addi	a1,s0,-288
  bc:	ee043503          	ld	a0,-288(s0)
  c0:	00000097          	auipc	ra,0x0
  c4:	2da080e7          	jalr	730(ra) # 39a <exec>
    exit(0);
  c8:	4501                	li	a0,0
  ca:	00000097          	auipc	ra,0x0
  ce:	298080e7          	jalr	664(ra) # 362 <exit>

00000000000000d2 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  d2:	1141                	addi	sp,sp,-16
  d4:	e406                	sd	ra,8(sp)
  d6:	e022                	sd	s0,0(sp)
  d8:	0800                	addi	s0,sp,16
  extern int main();
  main();
  da:	00000097          	auipc	ra,0x0
  de:	f98080e7          	jalr	-104(ra) # 72 <main>
  exit(0);
  e2:	4501                	li	a0,0
  e4:	00000097          	auipc	ra,0x0
  e8:	27e080e7          	jalr	638(ra) # 362 <exit>

00000000000000ec <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  ec:	1141                	addi	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f2:	87aa                	mv	a5,a0
  f4:	0585                	addi	a1,a1,1
  f6:	0785                	addi	a5,a5,1
  f8:	fff5c703          	lbu	a4,-1(a1)
  fc:	fee78fa3          	sb	a4,-1(a5)
 100:	fb75                	bnez	a4,f4 <strcpy+0x8>
    ;
  return os;
}
 102:	6422                	ld	s0,8(sp)
 104:	0141                	addi	sp,sp,16
 106:	8082                	ret

0000000000000108 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 108:	1141                	addi	sp,sp,-16
 10a:	e422                	sd	s0,8(sp)
 10c:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 10e:	00054783          	lbu	a5,0(a0)
 112:	cb91                	beqz	a5,126 <strcmp+0x1e>
 114:	0005c703          	lbu	a4,0(a1)
 118:	00f71763          	bne	a4,a5,126 <strcmp+0x1e>
    p++, q++;
 11c:	0505                	addi	a0,a0,1
 11e:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 120:	00054783          	lbu	a5,0(a0)
 124:	fbe5                	bnez	a5,114 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 126:	0005c503          	lbu	a0,0(a1)
}
 12a:	40a7853b          	subw	a0,a5,a0
 12e:	6422                	ld	s0,8(sp)
 130:	0141                	addi	sp,sp,16
 132:	8082                	ret

0000000000000134 <strlen>:

uint
strlen(const char *s)
{
 134:	1141                	addi	sp,sp,-16
 136:	e422                	sd	s0,8(sp)
 138:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 13a:	00054783          	lbu	a5,0(a0)
 13e:	cf91                	beqz	a5,15a <strlen+0x26>
 140:	0505                	addi	a0,a0,1
 142:	87aa                	mv	a5,a0
 144:	4685                	li	a3,1
 146:	9e89                	subw	a3,a3,a0
 148:	00f6853b          	addw	a0,a3,a5
 14c:	0785                	addi	a5,a5,1
 14e:	fff7c703          	lbu	a4,-1(a5)
 152:	fb7d                	bnez	a4,148 <strlen+0x14>
    ;
  return n;
}
 154:	6422                	ld	s0,8(sp)
 156:	0141                	addi	sp,sp,16
 158:	8082                	ret
  for(n = 0; s[n]; n++)
 15a:	4501                	li	a0,0
 15c:	bfe5                	j	154 <strlen+0x20>

000000000000015e <memset>:

void*
memset(void *dst, int c, uint n)
{
 15e:	1141                	addi	sp,sp,-16
 160:	e422                	sd	s0,8(sp)
 162:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 164:	ce09                	beqz	a2,17e <memset+0x20>
 166:	87aa                	mv	a5,a0
 168:	fff6071b          	addiw	a4,a2,-1
 16c:	1702                	slli	a4,a4,0x20
 16e:	9301                	srli	a4,a4,0x20
 170:	0705                	addi	a4,a4,1
 172:	972a                	add	a4,a4,a0
    cdst[i] = c;
 174:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 178:	0785                	addi	a5,a5,1
 17a:	fee79de3          	bne	a5,a4,174 <memset+0x16>
  }
  return dst;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strchr>:

char*
strchr(const char *s, char c)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb99                	beqz	a5,1a4 <strchr+0x20>
    if(*s == c)
 190:	00f58763          	beq	a1,a5,19e <strchr+0x1a>
  for(; *s; s++)
 194:	0505                	addi	a0,a0,1
 196:	00054783          	lbu	a5,0(a0)
 19a:	fbfd                	bnez	a5,190 <strchr+0xc>
      return (char*)s;
  return 0;
 19c:	4501                	li	a0,0
}
 19e:	6422                	ld	s0,8(sp)
 1a0:	0141                	addi	sp,sp,16
 1a2:	8082                	ret
  return 0;
 1a4:	4501                	li	a0,0
 1a6:	bfe5                	j	19e <strchr+0x1a>

00000000000001a8 <gets>:

char*
gets(char *buf, int max)
{
 1a8:	711d                	addi	sp,sp,-96
 1aa:	ec86                	sd	ra,88(sp)
 1ac:	e8a2                	sd	s0,80(sp)
 1ae:	e4a6                	sd	s1,72(sp)
 1b0:	e0ca                	sd	s2,64(sp)
 1b2:	fc4e                	sd	s3,56(sp)
 1b4:	f852                	sd	s4,48(sp)
 1b6:	f456                	sd	s5,40(sp)
 1b8:	f05a                	sd	s6,32(sp)
 1ba:	ec5e                	sd	s7,24(sp)
 1bc:	1080                	addi	s0,sp,96
 1be:	8baa                	mv	s7,a0
 1c0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c2:	892a                	mv	s2,a0
 1c4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c6:	4aa9                	li	s5,10
 1c8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ca:	89a6                	mv	s3,s1
 1cc:	2485                	addiw	s1,s1,1
 1ce:	0344d863          	bge	s1,s4,1fe <gets+0x56>
    cc = read(0, &c, 1);
 1d2:	4605                	li	a2,1
 1d4:	faf40593          	addi	a1,s0,-81
 1d8:	4501                	li	a0,0
 1da:	00000097          	auipc	ra,0x0
 1de:	1a0080e7          	jalr	416(ra) # 37a <read>
    if(cc < 1)
 1e2:	00a05e63          	blez	a0,1fe <gets+0x56>
    buf[i++] = c;
 1e6:	faf44783          	lbu	a5,-81(s0)
 1ea:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ee:	01578763          	beq	a5,s5,1fc <gets+0x54>
 1f2:	0905                	addi	s2,s2,1
 1f4:	fd679be3          	bne	a5,s6,1ca <gets+0x22>
  for(i=0; i+1 < max; ){
 1f8:	89a6                	mv	s3,s1
 1fa:	a011                	j	1fe <gets+0x56>
 1fc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1fe:	99de                	add	s3,s3,s7
 200:	00098023          	sb	zero,0(s3)
  return buf;
}
 204:	855e                	mv	a0,s7
 206:	60e6                	ld	ra,88(sp)
 208:	6446                	ld	s0,80(sp)
 20a:	64a6                	ld	s1,72(sp)
 20c:	6906                	ld	s2,64(sp)
 20e:	79e2                	ld	s3,56(sp)
 210:	7a42                	ld	s4,48(sp)
 212:	7aa2                	ld	s5,40(sp)
 214:	7b02                	ld	s6,32(sp)
 216:	6be2                	ld	s7,24(sp)
 218:	6125                	addi	sp,sp,96
 21a:	8082                	ret

000000000000021c <stat>:

int
stat(const char *n, struct stat *st)
{
 21c:	1101                	addi	sp,sp,-32
 21e:	ec06                	sd	ra,24(sp)
 220:	e822                	sd	s0,16(sp)
 222:	e426                	sd	s1,8(sp)
 224:	e04a                	sd	s2,0(sp)
 226:	1000                	addi	s0,sp,32
 228:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 22a:	4581                	li	a1,0
 22c:	00000097          	auipc	ra,0x0
 230:	176080e7          	jalr	374(ra) # 3a2 <open>
  if(fd < 0)
 234:	02054563          	bltz	a0,25e <stat+0x42>
 238:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 23a:	85ca                	mv	a1,s2
 23c:	00000097          	auipc	ra,0x0
 240:	17e080e7          	jalr	382(ra) # 3ba <fstat>
 244:	892a                	mv	s2,a0
  close(fd);
 246:	8526                	mv	a0,s1
 248:	00000097          	auipc	ra,0x0
 24c:	142080e7          	jalr	322(ra) # 38a <close>
  return r;
}
 250:	854a                	mv	a0,s2
 252:	60e2                	ld	ra,24(sp)
 254:	6442                	ld	s0,16(sp)
 256:	64a2                	ld	s1,8(sp)
 258:	6902                	ld	s2,0(sp)
 25a:	6105                	addi	sp,sp,32
 25c:	8082                	ret
    return -1;
 25e:	597d                	li	s2,-1
 260:	bfc5                	j	250 <stat+0x34>

0000000000000262 <atoi>:

int
atoi(const char *s)
{
 262:	1141                	addi	sp,sp,-16
 264:	e422                	sd	s0,8(sp)
 266:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 268:	00054603          	lbu	a2,0(a0)
 26c:	fd06079b          	addiw	a5,a2,-48
 270:	0ff7f793          	andi	a5,a5,255
 274:	4725                	li	a4,9
 276:	02f76963          	bltu	a4,a5,2a8 <atoi+0x46>
 27a:	86aa                	mv	a3,a0
  n = 0;
 27c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 27e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 280:	0685                	addi	a3,a3,1
 282:	0025179b          	slliw	a5,a0,0x2
 286:	9fa9                	addw	a5,a5,a0
 288:	0017979b          	slliw	a5,a5,0x1
 28c:	9fb1                	addw	a5,a5,a2
 28e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 292:	0006c603          	lbu	a2,0(a3)
 296:	fd06071b          	addiw	a4,a2,-48
 29a:	0ff77713          	andi	a4,a4,255
 29e:	fee5f1e3          	bgeu	a1,a4,280 <atoi+0x1e>
  return n;
}
 2a2:	6422                	ld	s0,8(sp)
 2a4:	0141                	addi	sp,sp,16
 2a6:	8082                	ret
  n = 0;
 2a8:	4501                	li	a0,0
 2aa:	bfe5                	j	2a2 <atoi+0x40>

00000000000002ac <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2ac:	1141                	addi	sp,sp,-16
 2ae:	e422                	sd	s0,8(sp)
 2b0:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2b2:	02b57663          	bgeu	a0,a1,2de <memmove+0x32>
    while(n-- > 0)
 2b6:	02c05163          	blez	a2,2d8 <memmove+0x2c>
 2ba:	fff6079b          	addiw	a5,a2,-1
 2be:	1782                	slli	a5,a5,0x20
 2c0:	9381                	srli	a5,a5,0x20
 2c2:	0785                	addi	a5,a5,1
 2c4:	97aa                	add	a5,a5,a0
  dst = vdst;
 2c6:	872a                	mv	a4,a0
      *dst++ = *src++;
 2c8:	0585                	addi	a1,a1,1
 2ca:	0705                	addi	a4,a4,1
 2cc:	fff5c683          	lbu	a3,-1(a1)
 2d0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2d4:	fee79ae3          	bne	a5,a4,2c8 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2d8:	6422                	ld	s0,8(sp)
 2da:	0141                	addi	sp,sp,16
 2dc:	8082                	ret
    dst += n;
 2de:	00c50733          	add	a4,a0,a2
    src += n;
 2e2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2e4:	fec05ae3          	blez	a2,2d8 <memmove+0x2c>
 2e8:	fff6079b          	addiw	a5,a2,-1
 2ec:	1782                	slli	a5,a5,0x20
 2ee:	9381                	srli	a5,a5,0x20
 2f0:	fff7c793          	not	a5,a5
 2f4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2f6:	15fd                	addi	a1,a1,-1
 2f8:	177d                	addi	a4,a4,-1
 2fa:	0005c683          	lbu	a3,0(a1)
 2fe:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 302:	fee79ae3          	bne	a5,a4,2f6 <memmove+0x4a>
 306:	bfc9                	j	2d8 <memmove+0x2c>

0000000000000308 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e422                	sd	s0,8(sp)
 30c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 30e:	ca05                	beqz	a2,33e <memcmp+0x36>
 310:	fff6069b          	addiw	a3,a2,-1
 314:	1682                	slli	a3,a3,0x20
 316:	9281                	srli	a3,a3,0x20
 318:	0685                	addi	a3,a3,1
 31a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 31c:	00054783          	lbu	a5,0(a0)
 320:	0005c703          	lbu	a4,0(a1)
 324:	00e79863          	bne	a5,a4,334 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 328:	0505                	addi	a0,a0,1
    p2++;
 32a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 32c:	fed518e3          	bne	a0,a3,31c <memcmp+0x14>
  }
  return 0;
 330:	4501                	li	a0,0
 332:	a019                	j	338 <memcmp+0x30>
      return *p1 - *p2;
 334:	40e7853b          	subw	a0,a5,a4
}
 338:	6422                	ld	s0,8(sp)
 33a:	0141                	addi	sp,sp,16
 33c:	8082                	ret
  return 0;
 33e:	4501                	li	a0,0
 340:	bfe5                	j	338 <memcmp+0x30>

0000000000000342 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 342:	1141                	addi	sp,sp,-16
 344:	e406                	sd	ra,8(sp)
 346:	e022                	sd	s0,0(sp)
 348:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 34a:	00000097          	auipc	ra,0x0
 34e:	f62080e7          	jalr	-158(ra) # 2ac <memmove>
}
 352:	60a2                	ld	ra,8(sp)
 354:	6402                	ld	s0,0(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret

000000000000035a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 35a:	4885                	li	a7,1
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <exit>:
.global exit
exit:
 li a7, SYS_exit
 362:	4889                	li	a7,2
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <wait>:
.global wait
wait:
 li a7, SYS_wait
 36a:	488d                	li	a7,3
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 372:	4891                	li	a7,4
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <read>:
.global read
read:
 li a7, SYS_read
 37a:	4895                	li	a7,5
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <write>:
.global write
write:
 li a7, SYS_write
 382:	48c1                	li	a7,16
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <close>:
.global close
close:
 li a7, SYS_close
 38a:	48d5                	li	a7,21
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <kill>:
.global kill
kill:
 li a7, SYS_kill
 392:	4899                	li	a7,6
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <exec>:
.global exec
exec:
 li a7, SYS_exec
 39a:	489d                	li	a7,7
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <open>:
.global open
open:
 li a7, SYS_open
 3a2:	48bd                	li	a7,15
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3aa:	48c5                	li	a7,17
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3b2:	48c9                	li	a7,18
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3ba:	48a1                	li	a7,8
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <link>:
.global link
link:
 li a7, SYS_link
 3c2:	48cd                	li	a7,19
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3ca:	48d1                	li	a7,20
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3d2:	48a5                	li	a7,9
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <dup>:
.global dup
dup:
 li a7, SYS_dup
 3da:	48a9                	li	a7,10
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3e2:	48ad                	li	a7,11
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ea:	48b1                	li	a7,12
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3f2:	48b5                	li	a7,13
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3fa:	48b9                	li	a7,14
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 402:	48e1                	li	a7,24
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <trace>:
.global trace
trace:
 li a7, SYS_trace
 40a:	48d9                	li	a7,22
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 412:	48dd                	li	a7,23
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 41a:	1101                	addi	sp,sp,-32
 41c:	ec06                	sd	ra,24(sp)
 41e:	e822                	sd	s0,16(sp)
 420:	1000                	addi	s0,sp,32
 422:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 426:	4605                	li	a2,1
 428:	fef40593          	addi	a1,s0,-17
 42c:	00000097          	auipc	ra,0x0
 430:	f56080e7          	jalr	-170(ra) # 382 <write>
}
 434:	60e2                	ld	ra,24(sp)
 436:	6442                	ld	s0,16(sp)
 438:	6105                	addi	sp,sp,32
 43a:	8082                	ret

000000000000043c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 43c:	7139                	addi	sp,sp,-64
 43e:	fc06                	sd	ra,56(sp)
 440:	f822                	sd	s0,48(sp)
 442:	f426                	sd	s1,40(sp)
 444:	f04a                	sd	s2,32(sp)
 446:	ec4e                	sd	s3,24(sp)
 448:	0080                	addi	s0,sp,64
 44a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 44c:	c299                	beqz	a3,452 <printint+0x16>
 44e:	0805c863          	bltz	a1,4de <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 452:	2581                	sext.w	a1,a1
  neg = 0;
 454:	4881                	li	a7,0
 456:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 45a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 45c:	2601                	sext.w	a2,a2
 45e:	00000517          	auipc	a0,0x0
 462:	46a50513          	addi	a0,a0,1130 # 8c8 <digits>
 466:	883a                	mv	a6,a4
 468:	2705                	addiw	a4,a4,1
 46a:	02c5f7bb          	remuw	a5,a1,a2
 46e:	1782                	slli	a5,a5,0x20
 470:	9381                	srli	a5,a5,0x20
 472:	97aa                	add	a5,a5,a0
 474:	0007c783          	lbu	a5,0(a5)
 478:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 47c:	0005879b          	sext.w	a5,a1
 480:	02c5d5bb          	divuw	a1,a1,a2
 484:	0685                	addi	a3,a3,1
 486:	fec7f0e3          	bgeu	a5,a2,466 <printint+0x2a>
  if(neg)
 48a:	00088b63          	beqz	a7,4a0 <printint+0x64>
    buf[i++] = '-';
 48e:	fd040793          	addi	a5,s0,-48
 492:	973e                	add	a4,a4,a5
 494:	02d00793          	li	a5,45
 498:	fef70823          	sb	a5,-16(a4)
 49c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4a0:	02e05863          	blez	a4,4d0 <printint+0x94>
 4a4:	fc040793          	addi	a5,s0,-64
 4a8:	00e78933          	add	s2,a5,a4
 4ac:	fff78993          	addi	s3,a5,-1
 4b0:	99ba                	add	s3,s3,a4
 4b2:	377d                	addiw	a4,a4,-1
 4b4:	1702                	slli	a4,a4,0x20
 4b6:	9301                	srli	a4,a4,0x20
 4b8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4bc:	fff94583          	lbu	a1,-1(s2)
 4c0:	8526                	mv	a0,s1
 4c2:	00000097          	auipc	ra,0x0
 4c6:	f58080e7          	jalr	-168(ra) # 41a <putc>
  while(--i >= 0)
 4ca:	197d                	addi	s2,s2,-1
 4cc:	ff3918e3          	bne	s2,s3,4bc <printint+0x80>
}
 4d0:	70e2                	ld	ra,56(sp)
 4d2:	7442                	ld	s0,48(sp)
 4d4:	74a2                	ld	s1,40(sp)
 4d6:	7902                	ld	s2,32(sp)
 4d8:	69e2                	ld	s3,24(sp)
 4da:	6121                	addi	sp,sp,64
 4dc:	8082                	ret
    x = -xx;
 4de:	40b005bb          	negw	a1,a1
    neg = 1;
 4e2:	4885                	li	a7,1
    x = -xx;
 4e4:	bf8d                	j	456 <printint+0x1a>

00000000000004e6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4e6:	7119                	addi	sp,sp,-128
 4e8:	fc86                	sd	ra,120(sp)
 4ea:	f8a2                	sd	s0,112(sp)
 4ec:	f4a6                	sd	s1,104(sp)
 4ee:	f0ca                	sd	s2,96(sp)
 4f0:	ecce                	sd	s3,88(sp)
 4f2:	e8d2                	sd	s4,80(sp)
 4f4:	e4d6                	sd	s5,72(sp)
 4f6:	e0da                	sd	s6,64(sp)
 4f8:	fc5e                	sd	s7,56(sp)
 4fa:	f862                	sd	s8,48(sp)
 4fc:	f466                	sd	s9,40(sp)
 4fe:	f06a                	sd	s10,32(sp)
 500:	ec6e                	sd	s11,24(sp)
 502:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 504:	0005c903          	lbu	s2,0(a1)
 508:	18090f63          	beqz	s2,6a6 <vprintf+0x1c0>
 50c:	8aaa                	mv	s5,a0
 50e:	8b32                	mv	s6,a2
 510:	00158493          	addi	s1,a1,1
  state = 0;
 514:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 516:	02500a13          	li	s4,37
      if(c == 'd'){
 51a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 51e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 522:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 526:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 52a:	00000b97          	auipc	s7,0x0
 52e:	39eb8b93          	addi	s7,s7,926 # 8c8 <digits>
 532:	a839                	j	550 <vprintf+0x6a>
        putc(fd, c);
 534:	85ca                	mv	a1,s2
 536:	8556                	mv	a0,s5
 538:	00000097          	auipc	ra,0x0
 53c:	ee2080e7          	jalr	-286(ra) # 41a <putc>
 540:	a019                	j	546 <vprintf+0x60>
    } else if(state == '%'){
 542:	01498f63          	beq	s3,s4,560 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 546:	0485                	addi	s1,s1,1
 548:	fff4c903          	lbu	s2,-1(s1)
 54c:	14090d63          	beqz	s2,6a6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 550:	0009079b          	sext.w	a5,s2
    if(state == 0){
 554:	fe0997e3          	bnez	s3,542 <vprintf+0x5c>
      if(c == '%'){
 558:	fd479ee3          	bne	a5,s4,534 <vprintf+0x4e>
        state = '%';
 55c:	89be                	mv	s3,a5
 55e:	b7e5                	j	546 <vprintf+0x60>
      if(c == 'd'){
 560:	05878063          	beq	a5,s8,5a0 <vprintf+0xba>
      } else if(c == 'l') {
 564:	05978c63          	beq	a5,s9,5bc <vprintf+0xd6>
      } else if(c == 'x') {
 568:	07a78863          	beq	a5,s10,5d8 <vprintf+0xf2>
      } else if(c == 'p') {
 56c:	09b78463          	beq	a5,s11,5f4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 570:	07300713          	li	a4,115
 574:	0ce78663          	beq	a5,a4,640 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 578:	06300713          	li	a4,99
 57c:	0ee78e63          	beq	a5,a4,678 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 580:	11478863          	beq	a5,s4,690 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 584:	85d2                	mv	a1,s4
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e92080e7          	jalr	-366(ra) # 41a <putc>
        putc(fd, c);
 590:	85ca                	mv	a1,s2
 592:	8556                	mv	a0,s5
 594:	00000097          	auipc	ra,0x0
 598:	e86080e7          	jalr	-378(ra) # 41a <putc>
      }
      state = 0;
 59c:	4981                	li	s3,0
 59e:	b765                	j	546 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5a0:	008b0913          	addi	s2,s6,8
 5a4:	4685                	li	a3,1
 5a6:	4629                	li	a2,10
 5a8:	000b2583          	lw	a1,0(s6)
 5ac:	8556                	mv	a0,s5
 5ae:	00000097          	auipc	ra,0x0
 5b2:	e8e080e7          	jalr	-370(ra) # 43c <printint>
 5b6:	8b4a                	mv	s6,s2
      state = 0;
 5b8:	4981                	li	s3,0
 5ba:	b771                	j	546 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5bc:	008b0913          	addi	s2,s6,8
 5c0:	4681                	li	a3,0
 5c2:	4629                	li	a2,10
 5c4:	000b2583          	lw	a1,0(s6)
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	e72080e7          	jalr	-398(ra) # 43c <printint>
 5d2:	8b4a                	mv	s6,s2
      state = 0;
 5d4:	4981                	li	s3,0
 5d6:	bf85                	j	546 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5d8:	008b0913          	addi	s2,s6,8
 5dc:	4681                	li	a3,0
 5de:	4641                	li	a2,16
 5e0:	000b2583          	lw	a1,0(s6)
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	e56080e7          	jalr	-426(ra) # 43c <printint>
 5ee:	8b4a                	mv	s6,s2
      state = 0;
 5f0:	4981                	li	s3,0
 5f2:	bf91                	j	546 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5f4:	008b0793          	addi	a5,s6,8
 5f8:	f8f43423          	sd	a5,-120(s0)
 5fc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 600:	03000593          	li	a1,48
 604:	8556                	mv	a0,s5
 606:	00000097          	auipc	ra,0x0
 60a:	e14080e7          	jalr	-492(ra) # 41a <putc>
  putc(fd, 'x');
 60e:	85ea                	mv	a1,s10
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e08080e7          	jalr	-504(ra) # 41a <putc>
 61a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 61c:	03c9d793          	srli	a5,s3,0x3c
 620:	97de                	add	a5,a5,s7
 622:	0007c583          	lbu	a1,0(a5)
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	df2080e7          	jalr	-526(ra) # 41a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 630:	0992                	slli	s3,s3,0x4
 632:	397d                	addiw	s2,s2,-1
 634:	fe0914e3          	bnez	s2,61c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 638:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 63c:	4981                	li	s3,0
 63e:	b721                	j	546 <vprintf+0x60>
        s = va_arg(ap, char*);
 640:	008b0993          	addi	s3,s6,8
 644:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 648:	02090163          	beqz	s2,66a <vprintf+0x184>
        while(*s != 0){
 64c:	00094583          	lbu	a1,0(s2)
 650:	c9a1                	beqz	a1,6a0 <vprintf+0x1ba>
          putc(fd, *s);
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	dc6080e7          	jalr	-570(ra) # 41a <putc>
          s++;
 65c:	0905                	addi	s2,s2,1
        while(*s != 0){
 65e:	00094583          	lbu	a1,0(s2)
 662:	f9e5                	bnez	a1,652 <vprintf+0x16c>
        s = va_arg(ap, char*);
 664:	8b4e                	mv	s6,s3
      state = 0;
 666:	4981                	li	s3,0
 668:	bdf9                	j	546 <vprintf+0x60>
          s = "(null)";
 66a:	00000917          	auipc	s2,0x0
 66e:	25690913          	addi	s2,s2,598 # 8c0 <malloc+0x110>
        while(*s != 0){
 672:	02800593          	li	a1,40
 676:	bff1                	j	652 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 678:	008b0913          	addi	s2,s6,8
 67c:	000b4583          	lbu	a1,0(s6)
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	d98080e7          	jalr	-616(ra) # 41a <putc>
 68a:	8b4a                	mv	s6,s2
      state = 0;
 68c:	4981                	li	s3,0
 68e:	bd65                	j	546 <vprintf+0x60>
        putc(fd, c);
 690:	85d2                	mv	a1,s4
 692:	8556                	mv	a0,s5
 694:	00000097          	auipc	ra,0x0
 698:	d86080e7          	jalr	-634(ra) # 41a <putc>
      state = 0;
 69c:	4981                	li	s3,0
 69e:	b565                	j	546 <vprintf+0x60>
        s = va_arg(ap, char*);
 6a0:	8b4e                	mv	s6,s3
      state = 0;
 6a2:	4981                	li	s3,0
 6a4:	b54d                	j	546 <vprintf+0x60>
    }
  }
}
 6a6:	70e6                	ld	ra,120(sp)
 6a8:	7446                	ld	s0,112(sp)
 6aa:	74a6                	ld	s1,104(sp)
 6ac:	7906                	ld	s2,96(sp)
 6ae:	69e6                	ld	s3,88(sp)
 6b0:	6a46                	ld	s4,80(sp)
 6b2:	6aa6                	ld	s5,72(sp)
 6b4:	6b06                	ld	s6,64(sp)
 6b6:	7be2                	ld	s7,56(sp)
 6b8:	7c42                	ld	s8,48(sp)
 6ba:	7ca2                	ld	s9,40(sp)
 6bc:	7d02                	ld	s10,32(sp)
 6be:	6de2                	ld	s11,24(sp)
 6c0:	6109                	addi	sp,sp,128
 6c2:	8082                	ret

00000000000006c4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6c4:	715d                	addi	sp,sp,-80
 6c6:	ec06                	sd	ra,24(sp)
 6c8:	e822                	sd	s0,16(sp)
 6ca:	1000                	addi	s0,sp,32
 6cc:	e010                	sd	a2,0(s0)
 6ce:	e414                	sd	a3,8(s0)
 6d0:	e818                	sd	a4,16(s0)
 6d2:	ec1c                	sd	a5,24(s0)
 6d4:	03043023          	sd	a6,32(s0)
 6d8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6dc:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6e0:	8622                	mv	a2,s0
 6e2:	00000097          	auipc	ra,0x0
 6e6:	e04080e7          	jalr	-508(ra) # 4e6 <vprintf>
}
 6ea:	60e2                	ld	ra,24(sp)
 6ec:	6442                	ld	s0,16(sp)
 6ee:	6161                	addi	sp,sp,80
 6f0:	8082                	ret

00000000000006f2 <printf>:

void
printf(const char *fmt, ...)
{
 6f2:	711d                	addi	sp,sp,-96
 6f4:	ec06                	sd	ra,24(sp)
 6f6:	e822                	sd	s0,16(sp)
 6f8:	1000                	addi	s0,sp,32
 6fa:	e40c                	sd	a1,8(s0)
 6fc:	e810                	sd	a2,16(s0)
 6fe:	ec14                	sd	a3,24(s0)
 700:	f018                	sd	a4,32(s0)
 702:	f41c                	sd	a5,40(s0)
 704:	03043823          	sd	a6,48(s0)
 708:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 70c:	00840613          	addi	a2,s0,8
 710:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 714:	85aa                	mv	a1,a0
 716:	4505                	li	a0,1
 718:	00000097          	auipc	ra,0x0
 71c:	dce080e7          	jalr	-562(ra) # 4e6 <vprintf>
}
 720:	60e2                	ld	ra,24(sp)
 722:	6442                	ld	s0,16(sp)
 724:	6125                	addi	sp,sp,96
 726:	8082                	ret

0000000000000728 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 728:	1141                	addi	sp,sp,-16
 72a:	e422                	sd	s0,8(sp)
 72c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 72e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 732:	00001797          	auipc	a5,0x1
 736:	8ce7b783          	ld	a5,-1842(a5) # 1000 <freep>
 73a:	a805                	j	76a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 73c:	4618                	lw	a4,8(a2)
 73e:	9db9                	addw	a1,a1,a4
 740:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 744:	6398                	ld	a4,0(a5)
 746:	6318                	ld	a4,0(a4)
 748:	fee53823          	sd	a4,-16(a0)
 74c:	a091                	j	790 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 74e:	ff852703          	lw	a4,-8(a0)
 752:	9e39                	addw	a2,a2,a4
 754:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 756:	ff053703          	ld	a4,-16(a0)
 75a:	e398                	sd	a4,0(a5)
 75c:	a099                	j	7a2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 75e:	6398                	ld	a4,0(a5)
 760:	00e7e463          	bltu	a5,a4,768 <free+0x40>
 764:	00e6ea63          	bltu	a3,a4,778 <free+0x50>
{
 768:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 76a:	fed7fae3          	bgeu	a5,a3,75e <free+0x36>
 76e:	6398                	ld	a4,0(a5)
 770:	00e6e463          	bltu	a3,a4,778 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 774:	fee7eae3          	bltu	a5,a4,768 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 778:	ff852583          	lw	a1,-8(a0)
 77c:	6390                	ld	a2,0(a5)
 77e:	02059713          	slli	a4,a1,0x20
 782:	9301                	srli	a4,a4,0x20
 784:	0712                	slli	a4,a4,0x4
 786:	9736                	add	a4,a4,a3
 788:	fae60ae3          	beq	a2,a4,73c <free+0x14>
    bp->s.ptr = p->s.ptr;
 78c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 790:	4790                	lw	a2,8(a5)
 792:	02061713          	slli	a4,a2,0x20
 796:	9301                	srli	a4,a4,0x20
 798:	0712                	slli	a4,a4,0x4
 79a:	973e                	add	a4,a4,a5
 79c:	fae689e3          	beq	a3,a4,74e <free+0x26>
  } else
    p->s.ptr = bp;
 7a0:	e394                	sd	a3,0(a5)
  freep = p;
 7a2:	00001717          	auipc	a4,0x1
 7a6:	84f73f23          	sd	a5,-1954(a4) # 1000 <freep>
}
 7aa:	6422                	ld	s0,8(sp)
 7ac:	0141                	addi	sp,sp,16
 7ae:	8082                	ret

00000000000007b0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7b0:	7139                	addi	sp,sp,-64
 7b2:	fc06                	sd	ra,56(sp)
 7b4:	f822                	sd	s0,48(sp)
 7b6:	f426                	sd	s1,40(sp)
 7b8:	f04a                	sd	s2,32(sp)
 7ba:	ec4e                	sd	s3,24(sp)
 7bc:	e852                	sd	s4,16(sp)
 7be:	e456                	sd	s5,8(sp)
 7c0:	e05a                	sd	s6,0(sp)
 7c2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7c4:	02051493          	slli	s1,a0,0x20
 7c8:	9081                	srli	s1,s1,0x20
 7ca:	04bd                	addi	s1,s1,15
 7cc:	8091                	srli	s1,s1,0x4
 7ce:	0014899b          	addiw	s3,s1,1
 7d2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7d4:	00001517          	auipc	a0,0x1
 7d8:	82c53503          	ld	a0,-2004(a0) # 1000 <freep>
 7dc:	c515                	beqz	a0,808 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7de:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e0:	4798                	lw	a4,8(a5)
 7e2:	02977f63          	bgeu	a4,s1,820 <malloc+0x70>
 7e6:	8a4e                	mv	s4,s3
 7e8:	0009871b          	sext.w	a4,s3
 7ec:	6685                	lui	a3,0x1
 7ee:	00d77363          	bgeu	a4,a3,7f4 <malloc+0x44>
 7f2:	6a05                	lui	s4,0x1
 7f4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7f8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7fc:	00001917          	auipc	s2,0x1
 800:	80490913          	addi	s2,s2,-2044 # 1000 <freep>
  if(p == (char*)-1)
 804:	5afd                	li	s5,-1
 806:	a88d                	j	878 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 808:	00001797          	auipc	a5,0x1
 80c:	80878793          	addi	a5,a5,-2040 # 1010 <base>
 810:	00000717          	auipc	a4,0x0
 814:	7ef73823          	sd	a5,2032(a4) # 1000 <freep>
 818:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 81a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 81e:	b7e1                	j	7e6 <malloc+0x36>
      if(p->s.size == nunits)
 820:	02e48b63          	beq	s1,a4,856 <malloc+0xa6>
        p->s.size -= nunits;
 824:	4137073b          	subw	a4,a4,s3
 828:	c798                	sw	a4,8(a5)
        p += p->s.size;
 82a:	1702                	slli	a4,a4,0x20
 82c:	9301                	srli	a4,a4,0x20
 82e:	0712                	slli	a4,a4,0x4
 830:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 832:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 836:	00000717          	auipc	a4,0x0
 83a:	7ca73523          	sd	a0,1994(a4) # 1000 <freep>
      return (void*)(p + 1);
 83e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 842:	70e2                	ld	ra,56(sp)
 844:	7442                	ld	s0,48(sp)
 846:	74a2                	ld	s1,40(sp)
 848:	7902                	ld	s2,32(sp)
 84a:	69e2                	ld	s3,24(sp)
 84c:	6a42                	ld	s4,16(sp)
 84e:	6aa2                	ld	s5,8(sp)
 850:	6b02                	ld	s6,0(sp)
 852:	6121                	addi	sp,sp,64
 854:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 856:	6398                	ld	a4,0(a5)
 858:	e118                	sd	a4,0(a0)
 85a:	bff1                	j	836 <malloc+0x86>
  hp->s.size = nu;
 85c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 860:	0541                	addi	a0,a0,16
 862:	00000097          	auipc	ra,0x0
 866:	ec6080e7          	jalr	-314(ra) # 728 <free>
  return freep;
 86a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 86e:	d971                	beqz	a0,842 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 870:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 872:	4798                	lw	a4,8(a5)
 874:	fa9776e3          	bgeu	a4,s1,820 <malloc+0x70>
    if(p == freep)
 878:	00093703          	ld	a4,0(s2)
 87c:	853e                	mv	a0,a5
 87e:	fef719e3          	bne	a4,a5,870 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 882:	8552                	mv	a0,s4
 884:	00000097          	auipc	ra,0x0
 888:	b66080e7          	jalr	-1178(ra) # 3ea <sbrk>
  if(p == (char*)-1)
 88c:	fd5518e3          	bne	a0,s5,85c <malloc+0xac>
        return 0;
 890:	4501                	li	a0,0
 892:	bf45                	j	842 <malloc+0x92>
