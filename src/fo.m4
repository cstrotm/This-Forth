static char sccsid[] = "@(#)ThisForth 1.0.0d Wil Baden 95-04-02";

ifdef(`SUPER',`define(`LONG')')

ifdef(`LONG',`# define LONG')

ifdef(`FUN',`# define FUN')

typedef ifdef(`LONG',`long',`short') instruction;

# include "fo.h"
# include <signal.h>

static void sigabrt proto((int));
static void interpret proto((int));

# define nestingcheck()	if ((unsigned)(R - rack) > RETURN_STACK_CELLS)\
			sorry("(Nesting Error)")

# define stackcheck() if ((unsigned)(S - stack) > STACK_CELLS)\
			sorry("(Stack Error)")

# define STACKCHECK /* stackcheck(); */

include(`llfc.m4')

static void literal proto((void));
static void literalize proto((int normally, int literally));

/*` Optimize:	n `$1'    x n `$1'    '*/
define(`Literation',
	`Immediate(`$1') ifelse(`$4',,,
	`if (state && last == doLITERAL && nextlast == doLITERAL)
		push code[next-3] `$4' code[next-1],
		next -= 4, last = 0, literal();
	else') literalize(NEXT, incr(NEXT)); Done
	Behavior `$2'; Done	Behavior `$3'; Done',
')

static void (nestingcheck)(void);
static void (stackcheck)(void);

define(`REDUNDANT')
define(`ENHANCEMENT')

/* This is sacred.*/

define(`beORDINARY',OPER) define(`NAME',`ORDINARY')

Primitive
	if (! state)
		interpret(xt);
	else
		nextlast = last, last = c(xt);
Done

define(`beNEST',OPER) define(`NAME',`NEST')

Primitive
	*++R = I, I = xt;
	nestingcheck();
Done

define(`NAME',`UNRECOGNIZED')

Com(0) Com(0) Behavior /* For unrecognized words */
	cell n, t, s, i;
	int sign;
	n = t = 0;
	s = POCKET + 1, i = data[POCKET];
	if (data[s] == '-' && i > 1 && data[s + 1] != DECIMAL_POINT)
		sign = '-', ++s, --i;
	else
		sign = '+';
	number(&n, &t, &s, &i);
	if (sign == '-') {
		if (n)
			n = -n, t = ~t;
		else
			t = -t;
	}
	if (i == 0)
		push n, literal();
	else if (i == 1 && data[s] == DECIMAL_POINT)
		push n, literal(), push t, literal();
	else {
ifdef(`FLOATING',`
		char * pp;
		if (BASE == 10
		&& (f = strtod((char *) &data[POCKET + 1], &pp), *pp == EOS)
		)
			fpush f, fliteral();
		else
')
			HUH ;
	}
Done		Com(0)

Primitive xt = code[xt]; recurse; Done

/* The following are placed here to be easy to find. */

/* CURRENT */ Com(0) /* CONTEXT */ times(WORDLISTS,`Com(0)')

/* CURRENT and CONTEXT should be defined in fo.h */

define(`FORTH',NEXT) Com(0) times(NEW_WORDLISTS,`Com(-1)')

define(`GILDED',(NEXT - CURRENT))

/* Such is sacred. */

/*` Core Extension Words in Low Level Forth Kernel
:NONAME ?DO C" CASE ENDCASE MARKER NIP PARSE PICK ROLL SOURCE-ID U> UNUSED
'*/

Execution(`EXIT') define(`doEXIT',THIS)
	I = *R--;
Done

Behavior define(`doFILTEREXECUTE',THIS)	
	filterword(POCKET);
	lookup(link, POCKET);
	xt = code(link);
	recurse;
Done

# ifdef CLASSIC
static void interpret(n) int n;
# else
static void interpret(int n)
# endif
{
	code[TRAMPOLINE] = n;
	code[TRAMPOLINE + 1] = doEXIT;
	*++R = I, I = TRAMPOLINE;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

define(`NAME',`LITERAL')
Behavior
	push code[I++];
Done	define(`doLITERAL',THIS)

define(`NAME',`BRANCH')
define(`doBRANCH',NEXT)
	Behavior I += code[I]; STACKCHECK Done

define(`NAME',`CONSTANT')
define(`beCONSTANT',OPER)
	Primitive
		push code[xt], literal();
	Done

ifdef(`LONG',,`
define(`beLCONSTANT',OPER)
	Primitive
		u.Short[0] = code[xt++], u.Short[1] = code[xt],
			push u.Long, literal();
	Done
')
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* `: EXPOUND BEGIN filterexecute AGAIN ;' */

WORD(`expound') ADOPT(beORDINARY) Com(beNEST)
	BEGIN Com(doFILTEREXECUTE) AGAIN

/* `: QUIT restart EXPOUND ;' */

Execution(`QUIT') restart(); Done
	define(`doQUIT',THIS)

Execution(`ABORT')
	type(&data[source+1], data[source]);
	S = stack; top = *S = 0;
	/* restart(); */
	xt = decr(doQUIT); recurse;
Done
	define(doABORT,THIS)

Execution(`BYE') longjmp(jmpbuf, 2); Done
	define(`doBYE',THIS)

Immediate(`;') COMPILE_ONLY
	if (leaves) sorry("leave ?") ;
	if
	(  last != doBRANCH
	&& last != doQUIT
	&& last != doABORT
	&& last != doBYE
	)
		c(doEXIT);
	last = 0;
	state = FALSE;
	code[next] = previous = currentdefinition ;
	if (previous && code[previous + 1]) code[code[CURRENT]] = previous ;
	if (level != S - stack)
		type(&data[code[previous +1]+1],data[code[previous+1]]),
		fprintf(stdout, " (Incomplete) " ) ;
	here = aligned(here);
	if (next >= TRAMPOLINE)
		sorry("(Code space exceeded)");
	if (finger >= WALL - sizeof(cell))
		sorry("(Name space exceeded)");
Done

Execution(`:')
	adopt((primitive) beORDINARY), c(beNEST);
	previous = code[previous];
	level = S - stack;
	leaves = 0;
	state = TRUE;
	last = 0;
Done

static void literalize(int normally, int literally)
{
	if (! state)
		interpret(normally);
	else if (last == doLITERAL)
		last = code[next-2] = literally;
	else
		nextlast = last, last = c(normally);
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Stack Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`DROP') pop; Done define(`doDROP',THIS)
Execution(`DUP') *++S = top; Done define(`doDUP',THIS)
Execution(`NIP') S--; Done define(`doNIP',THIS)
Execution(`OVER') push S[-1]; Done define(`doOVER',THIS)

Immediate(`ROT')
Optimization
	if (last == NEXT) 
		last = code[next-1] = incr(NEXT);
	else if (last == incr(NEXT))
		--next, last = nextlast, nextlast = 0;
Execution
	Behavior
		w = S[-1], S[-1] = *S, *S = top, top = w;
	Done
	Behavior
		w = top, top = *S, *S = S[-1], S[-1] = w;
	Done

Execution(`SWAP') w = top, top = *S, *S = w; Done define(`doSWAP',THIS)
Execution(`?DUP') if (top) *++S = top ; Done define(`doQUEDUP',THIS)
Execution(`2DROP') S--, pop; Done
Execution(`2DUP') w = *S, *++S = top, *++S = w; Done
Execution(`2OVER') push S[-2], w = S[-3], *++S = w; Done

Execution(`2SWAP')
	w = S[-1], S[-1] = top, top = w;
	w = S[-2], S[-2] = *S, *S = w;
Done

/*` Optimize:	n PICK    '*/
Literation(`PICK',`top = S[-top]',`push S[-code[I++]]')

Execution(`ROLL')
	for (n = top, top = S[-top]; n; --n)
		S[-n] = S[-(n - 1)];
	S--;
Done

Execution(`>R') *++R = top, pop; Done
Execution(`R>') push *R--; Done
Execution(`R@') push *R; Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Status Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`DEPTH') push S - stack - 1; Done
Execution(`HERE') push here; Done
Execution(`NESTING') push R - rack; Done
Execution(`OUTSIDE') push S - stack - 1 - level; Done
Execution(`SOURCE-ID') push files ? (cell) usrin : 0; Done
Execution(`UNUSED') push DATAROOM - here; Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Arithmetic and Logical Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*` Optimize:	n LSHIFT    x n LSHIFT    '*/
Literation(`LSHIFT',`top = *S-- << top',`top = top << code[I++]',`<<')
	define(`doLITLSHIFT',THIS)

/*` Optimize:	 n +    x n +    x + n +    0 +   '*/
Immediate(`+') define(`doPLUS',THIS)
Optimization
	if (last == doLITERAL) {
		if (nextlast == doLITERAL) {
			w = code[next-3] + code[next-1];
			ifdef(`LONG',`
				next -= 2, operand = w;
			',`
			if (isshort(w))
				next -= 2, operand = w;
			else
				push w, next -= 4, literal(), last = c(NEXT);
			')
			nextlast = 0;
		} else if (nextlast == incr(NEXT)) {
			w = code[next-3] + code[next-1];
			if (w == 0)
				next -= 4, last = 0;
			else ifdef(`LONG',`
				next -= 2, operand = w, last = incr(NEXT);
			',`
			if (isshort(w))
				next -= 2, operand = w, last = incr(NEXT);
			else
				next -= 4, push w, literal(), last = c(NEXT);
			')
			nextlast = 0;
		} else {
			if (operand == 0)
				next += -2, last = nextlast, nextlast = 0;
			else
				last = code[next-2] = incr(NEXT);
		}
	} else if (last == doSWAP) {
		-- next;
		last = nextlast; nextlast = 0;
		xt = doPLUS;
		recurse;
		/*NOTREACHED*/
	}
Execution
	Behavior top += *S--; Done
	Behavior top += code[I++]; Done

/*` Optimize:	 n -    x n -    x + n -    0 -    SWAP -    '*/
Immediate(`-')
Optimization
	if (last == doLITERAL && operand != -operand) {
		operand = -operand, xt = doPLUS;
		recurse;
		/*NOTREACHED*/
	} else if (last == doSWAP)
		last = operation = incr(NEXT);
Execution
	Behavior top = *S-- - top; Done
	Behavior top -= *S--; Done

/*` Optimize:	x n *    b *    1 *    '*/
Immediate(`*')
Optimization
	if (last == doLITERAL) {
		if (nextlast == doLITERAL)
			push operand, next += -2,
			top *= operand, next += -2,
			last = 0, literal();
		else if ((operand & operand - 1) == 0) {
			for (n = 0; (operand = (unsigned) operand >> 1) != 0; ++ n)
				;
			if (n)
				last = code[next-2] = doLITLSHIFT, code[next-1] = n;
			else
				next -= 2, last = nextlast, nextlast = 0;
		} else
			nextlast = last, last = c(NEXT);
	}
Execution
	Behavior top *= *S--; Done

/*` Optimize:	x n /    1 /    '*/
Immediate(`/')
Optimization
	if (last == doLITERAL) {
		if (operand == 1)
			next -= 2, last = nextlast, nextlast = 0;
		else if (nextlast == doLITERAL)
			push code[next-3] / code[next-1],
			next -= 4, last = 0, literal();
		else
			nextlast = last, last = c(NEXT);
	}
Execution
	Behavior top = top ? *S-- / top : (S--, 0) ; Done

Execution(`2/') top = (signed long) top >> 1; Done

/* Data Space Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/*` Optimize:	x @   dup @ '*/
Immediate(`@')
Optimization
	if (last == doLITERAL)
		last = code[next-2] = incr(NEXT);
	else if (last == doDUP)
		last = operation = eval(NEXT + 2);
Execution
	Behavior top = data(top); Done
	Behavior push data(code[I++]); Done
	Behavior push data(top); Done

/*` Optimize:	x !   swap !   '*/
Immediate(`!')
Optimization
	if (last == doLITERAL)
		last = code[next-2] = incr(NEXT);
	else if (last == doSWAP)
		last = operation = eval(NEXT + 2);
Execution
	Behavior data(top) = *S--, pop; Done
	Behavior data(code[I++]) = top, pop; Done
	Behavior data(*S--) = top, pop; Done

/*` Optimize:	x +!   swap +!  '*/
Immediate(`+!')
Optimization
	if (last == doLITERAL)
		last = code[next-2] = incr(NEXT);
	else if (last == doSWAP)
		last = operation = eval(NEXT + 2);
Execution
	Behavior data(top) += *S--, pop; Done
	Behavior data(code[I++]) += top, pop; Done
	Behavior data(*S--) += top, pop; Done

Execution(`C@') top = data[top]; Done
Execution(`C!') data[top] = *S--, pop; Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`>') top = *S-- > top LOGICAL; Done define(`doGREATER',THIS)

/*` Optimize:	n <    SWAP <    '*/
Immediate(`<')
Optimization
	if (last == doLITERAL){
		if (operand == 0)
			-- next, last = operation = eval(NEXT+2);
		else
			last = code[next-2] = incr(NEXT);
	} else if (last == doSWAP)
		last = operation = doGREATER;
Execution
	Behavior top = *S-- < top LOGICAL; Done
	Behavior top = top < code[I++] LOGICAL; Done define(`doLITLESS',THIS)
	Behavior top = top < 0 LOGICAL; Done define(`doNEGATIVE',THIS)

/*` Optimize:	n =    n OVER =    DUP n =   '*/
Immediate(`=')
Optimization
	if (last == doLITERAL) {
		if (nextlast == doDUP) {
			-- next, last = code[next-2] = eval(NEXT + 2),
			operand = code[next], nextlast = 0;
		} else if (operand == 0) {
			-- next, last = operation = eval(NEXT + 3);
		} else
			last = code[next-2] = eval(NEXT + 1);
	} else if (last == doOVER && nextlast == doLITERAL)  {
		-- next; last = code[next-2] = eval(NEXT + 2), nextlast = 0;
	}
Execution
	Behavior top = *S-- == top LOGICAL; Done
	Behavior top = top == code[I++] LOGICAL; Done define(`doLITEQUAL',THIS)
	Behavior push top == code[I++] LOGICAL; Done define(`doDUPLITEQUAL',THIS)
	Behavior top = ! top LOGICAL; Done define(`doNOUGHT',THIS)

/*` Optimize:	n ALIGNED    '*/
Immediate(`ALIGNED')
Optimization
	if (last == doLITERAL)
		operand = aligned(operand);
Execution
	Behavior top = aligned(top); Done

Execution(`ALLOT')
	if (!(LOWER(here + top - NAMEROOM, DATAROOM - NAMEROOM + 1)))
		sorry("(Data space error)");
	here += top, pop;
Done

/*` Optimize:	n AND    x n AND    '*/
Literation(`AND',`top &= *S--',`top &= code[I++]',`&')
	define(`doLITAND',THIS)

/*` Optimize:	n CELLS    '*/
Immediate(`CELLS')
Optimization
	if (last == doLITERAL)
		push operand, next += -2, top *= sizeof(cell),
		last = nextlast, literal();
Execution
	Behavior top *= sizeof(cell); Done

Execution(`COMPARE') /* c-addr1 u1 c-addr2 u2 -- n */
/*
Compare the string specified by c-addr1 u1 to the string specified by
c-addr2 u2.

The strings are compared, beginning at the given addresses, character by
character, up to the length of the shorter string or until a difference
is found.

If the two strings are identical, n is zero.

If the two strings are identical up to the length of the shorter string,
n is minus-one (-1) if u1 is less than u2 and one (1) otherwise.

If the two strings are not identical up to the length of the shorter
string, n is minus-one (-1) if the first non-matching character in the
string specified by c-addr1 u1 has a lesser numeric value than the
corresponding character in the string specified by c-addr2 u2 and one
(1) otherwise.
*/
	n = S[-1] < top ? S[-1] : top;
	d = memcmp((char *) &data[S[-2]], (char *) &data[*S], n);
	if (d == 0 && S[-1] != top)
		d = S[-1] < top ? -1 : 1;
	S -= 3;
	top = d;
Done

/*` Optimize:	b MOD    '*/
Immediate(`MOD')
Optimization
	if (last == doLITERAL && (operand & operand - 1) == 0)
		last = code[next-2] = doLITAND,
		-- operand;
Execution
	Behavior top = top ? *S-- % top : *S--; Done

Execution(`/MOD')
	if (top != 0)
		w = *S / top, *S -= w * top, top = w;
Done

WORD(`*/mod')define(`NAME',``SCALE'')
ADOPT(beORDINARY)Behavior
	scale();
Done

Execution(`NEGATE') top = -top; Done

/*` Optimize:	n OR    x n OR    '*/
Literation(`OR',`top |= *S--',`top |= code[I++]',`|')

/*` Optimize:	n RSHIFT   x n RSHIFT    '*/
Immediate(`RSHIFT')
	if (state && last == doLITERAL && nextlast == doLITERAL)
		w = code[next - 3],
		push (unsigned long) w >> code[next-1],
		next -= 4, nextlast = 0, literal();
	else
		literalize(NEXT, incr(NEXT));
Done
	Behavior top = (unsigned long) *S-- >> top; Done
	Behavior top = (unsigned long) top >> code[I++]; Done

Execution(`U>') top = LOWER(top, *S) LOGICAL; S--; Done define(`doHIGHER',THIS)

/*` Optimize:	n U<    SWAP U<    '*/
Immediate(`U<')
Optimization
	if (last == doLITERAL)
			last = code[next-2] = incr(NEXT);
	else if (last == doSWAP)
			last = code[next-1] = doHIGHER;
Execution
	Behavior top = LOWER(*S, top) LOGICAL; S--; Done
	Behavior top = LOWER(top, code[I]) LOGICAL; I++; Done

/*` Optimize:	n UNDER+    '*/
Literation(`UNDER+',`S[-1] += top, pop',`*S += code[I++]')

/*` Optimize:	n XOR    x n XOR    '*/
Literation(`XOR',`top ^= *S--',`top ^= code[I++]',`^')

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* `Control Flow' */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

define(`CONDITION',`condition();')
define(`BRANCH',`last = c(doBRANCH);')

/*` Optimize:
{ DUP  ?DUP  0<  FALSE  DUP 0=  ?DUP 0=  0< NOT  0= NOT } { IF WHILE UNTIL }
'*/
void condition proto((void))
{
	if (last == doDUP) /*` DUP IF '*/

		last = operation = NEXT;
		
		Behavior I += top ? 1 : code[I]; Done define(`doDUPIF',THIS)

	else if (last == doQUEDUP) /*` ?DUP IF '*/

		last = operation = NEXT;
	
		Behavior I += top ? 1 : (pop, code[I]); Done

	else if (last == doNEGATIVE) /*` 0< IF '*/

		last = operation = NEXT;
		
		Behavior I += top < 0 ? 1 : code[I], pop; Done

	else if (last == doLITERAL && operand == 0) /*` 0 IF '*/
	
		-- next, last = operation = doBRANCH;

	else if (last == doDUPLITEQUAL && operand == 0) /*` DUP 0 = IF or 0 OVER = IF '*/

		-- next, last = operation = NEXT;

		Behavior I += top ? code[I] : 1; Done
		
	else if (last == doNOUGHT) {
			
		if	(nextlast == doQUEDUP) /*` ?DUP 0= IF or ORIF '*/
		
			-- next, last = operation = NEXT;

			Behavior I += top ? code[I] : (pop, 1); Done

		else if (nextlast == doNEGATIVE) /*` 0< not IF '*/

			-- next, last = operation = NEXT;
			
			Behavior I += top < 0 ? code[I] : 1, pop; Done

		else if (nextlast == doDUPLITEQUAL && code[next-2] == 0) /*` DUP 0= not IF '*/

			next -= 2, last = operand = doDUPIF;

		else if (nextlast == doNOUGHT)	/*` 0= 0= IF '*/
					
			-- next, last = operation = NEXT;

			Behavior I += top ? 1 : code[I], pop; Done define(`doIF',THIS)

		else				/*` 0= IF ' */
		
			last = operation = NEXT;

			Behavior I += top ? code[I]: 1, pop; Done
		
	} else

		last = c(doIF);

}

Immediate(`IF') SELF_COMPILE
	CONDITION
	push next, c(0);
Done

Immediate(`ELSE') COMPILE_ONLY
	BRANCH
	if (top <= 0 || code[top]) HOW ;
	w = top, top = next, c(0);
	code[w] = next - w;
Done

Immediate(`THEN') COMPILE_ONLY
	if (top <= 0 || top >= next || code[top]) HOW ;
	code[top] = next - top, pop;
	last =  0; COMPLETE
Done

Immediate(`CASE') SELF_COMPILE
	push 0;
Done

Immediate(`ENDCASE') COMPILE_ONLY
	if (last == doLITERAL)
		next -= 2;
	else
		c(doDROP);
	last = 0;
	while (top) {
		if (top <= 0 || top >= next || code[top]) HOW ;
		code[top] = next - top, pop;
	}
	pop; COMPLETE
Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Immediate(`BEGIN') SELF_COMPILE
	push next; last = 0;
Done

Immediate(`WHILE') COMPILE_ONLY
	CONDITION
	*++S = next, c(0); 
Done

Immediate(`UNTIL') COMPILE_ONLY
	if (last == doLITERAL && operand != 0)
		next -= 2;
	else {
		CONDITION
		n = next, c(top - n);
	}
	if (top <= 0 || ! code[top]) HOW ;
	pop; last = 0; COMPLETE 
Done

Immediate(`REPEAT') COMPILE_ONLY
	BRANCH
	if (top <= 0 || ! code[top]) HOW ;
	w = next, c(top - w), pop;
	if (top <= 0 || code[top]) HOW ;
	code[top] = next - top, pop;
	last = 0; COMPLETE 
Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Immediate(`DO') SELF_COMPILE
	last = c(NEXT), push -next;
Done
	Behavior
		*++R = *S, *++R = top - *S--, pop;
	Done

Immediate(`?DO') SELF_COMPILE
	last = c(NEXT), push -next, c(0);
Done
	Behavior
		I += top == *S ? code[I]
			: (*++R = *S, *++R = top - *S, 1),
			S--, pop;
	Done

Execution(`UNLOOP') define(`doUNLOOP',THIS)
	R -= 2;
Done

Immediate(`LEAVE') COMPILE_ONLY
	c(doUNLOOP), last = c(doBRANCH), c(leaves);
	leaves = next - 1;
Done

Immediate(`LOOP') define(`doLOOP',THIS) COMPILE_ONLY
	if (top >= 0) HOW ;
	last = c(NEXT);
	rake(); COMPLETE 
Done
	Behavior
		if ((++ * R) == 0)
			++ I, R -= 2;
		else
			I += code[I]; STACKCHECK 
	Done

/*` Optimize:	1 +LOOP   '*/
Immediate(`+LOOP') COMPILE_ONLY
	if (nextlast == doLITERAL && operand == 1) {
		next -= 2;
		xt = doLOOP;
		recurse;
	}
	if (top >= 0) HOW ;
	last = c(NEXT);
	rake(); COMPLETE
Done
	Behavior
		w = *R, *R += top;
		if ((w ^ *R) < 0 && (w ^ top) < 0)
			++ I, R -= 2;
		else
			I += code[I]; STACKCHECK 
		pop;
	Done

static void rake proto((void))
{	/* Gather the leaves.*/
	int n = next;
	top = - top;
	if (code[top])
		c(top - n);
	else
		c(top + 1 - n), code[top] = next - top;
	for ( ; leaves > top; leaves = n)
		n = code[leaves], code[leaves] = next - leaves;
	pop;
}

Execution(`I') push R[0] + R[-1]; Done
Execution(`J') push R[-2] + R[-3]; Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Nominate(`Left Parenthesis')define(`LENGTH',1)
1,40, /* 40 == left parenthesis */ ADOPT(OPER)Primitive
	while (
		(c = char()) != ')'
	&&
		c != EOF
	&&
		! (usrin == stdin && c == EOL)
	) ;
Done

/*` Optimize:	n >BODY   ['] x >BODY    '*/
Immediate(`>BODY')
Optimization
	if (last == doLITERAL)
		operand = code[operand + 1];
Execution
	Behavior top = code[top + 1]; Done

Immediate(`C\"')
	parse(QUOTE);
	if (! state)
		push shelve();
	else {
		last = c(doLITERAL);
		c(textliteral());
	}
Done

Execution(`GET-CHAR') push char(); Done
Execution(`STACK-CHAR') unchar(top); pop; Done

Execution(`NEXT-CHAR')
	push char();
	if (top != EOF) unchar(top) ;
Done

Immediate(`[CHAR]')
        parseword((int) SPACE);
        push data[finger] ? data[finger+1] : EOL;
        literal();
Done

Immediate(`SLITERAL')
	if (state) {
		/* Make counted string at finger from *S,top */
		move(&data[finger+1], &data[*S--], top);
		data[finger] = top, pop;
		nextlast = last, last = c(NEXT);
		c(textliteral());
	}
Done
	Behavior w = code[I++];	push data[w]; *++S = w + 1; Done
	define(`doSLITERAL',THIS)
	
/*` Optimize:	n COUNT    C" ccc" COUNT    '*/
Immediate(`COUNT') literalize(NEXT, doSLITERAL); Done
	Behavior *++S = top + 1; top = data[top]; Done

Execution(`CR') emit(EOL); Done
Execution(`EMIT') emit(top); pop; Done
Execution(`EXECUTE') xt = top, pop; recurse; Done

Execution(`FIND')
	memcpy(&data[finger], &data[top], data[top] + 1);
	lookup(link, finger);
	if (link)
		*++S = code(link),
		top = code[code(link)] == beORDINARY ? -1 : 1;
	else
		push 0;
Done

Execution(`FILL')
	memset(data + S[-1], top, *S), S -= 2, pop;
Done

Execution(`IMMEDIATE')
	if (code[code(previous)] == beORDINARY)
		code[code(previous)] = eval(OPER + 1);
	else if (code[code(previous)] == beCONSTANT)
		code[code(previous)] = eval(OPER + 2);
	else
		sorry("(Can't be made `IMMEDIATE')") ;
Done
	define(`beIMMEDIATE',OPER)
	Primitive recurse; Done
	Primitive push code[xt]; Done

Execution(`INLINE')
	if (code[code(previous)] != beORDINARY || code[code(previous) + 1] != beNEST)
		HOW ;
	/* Set immediate behavior to copy compiled code to object. */
	code[code(previous)] = incr(OPER);
	code[code(previous) + 1] = next - 3 - code(previous);
Done
	Primitive
		if (state)
			for (n = 0; n < code[xt]; ++ n)
				c(code[xt + 1 + n]);
		else
			*++R = I, I = xt + 1;
	Done

Immediate(`LITERAL') literal(); Done
ifdef(`LONG',`
void literal proto((void))
{
	if (! state) return;
	nextlast = last, last = c(doLITERAL), c(top), pop;
}
',`
void literal proto((void))
{
	if (! state) return ;
	nextlast = last;
	if (isshort(top))
		last = c(doLITERAL), c(top);
	else
		u.Long = top, last = c(NEXT),
			c(u.Short[0]), c(u.Short[1]);
	pop;
}
	Behavior
		u.Short[0] = code[I++], u.Short[1] = code[I++], push u.Long;
	Done
')

REDUNDANT(`
Execution(`MIN') if (*S-- < top) top = S[1]; Done
Execution(`MAX') if (*S-- > top) top = S[1]; Done
')

Execution(`MOVE')
	move(&data[*S], &data[S[-1]], top), S -= 2, pop;
Done

Execution(`:NONAME')
	currentdefinition = next, dataspace = here, namespace = finger;
	c(0), c(0); push next;
	c(beORDINARY), c(beNEST);
	level = S - stack;
	leaves = 0;
	state = TRUE;
Done

Execution(`>NUMBER')
	cell n3, n2, n, t;
	t = top, n = *S--, n2 = *S--, n3 = *S;
	number(&n3, &n2, &n, &t);
	*S = n3, *++S = n2, *++S = n, top = t;
Done

Execution(`PARSE')
	parse((int) top);
	*++S = shelve() + 1, top = data[*S - 1];
Done

Immediate(`PLEASE') SELF_COMPILE
	c(NEXT);
	n = 0;
	do d = char(); while (! isgraph(d));
	while ((c = char()) != d && c != EOF) {
		if (n < COUNTED_STRING_MAX)
			data[++ n + finger] = c ;
		if (c == EOL) {
			while (isspace(c = char())) ;
			unchar(c);
		}
	}
	data[finger] = n;

	c(textliteral());
	COMPLETE
Done
	Behavior
		for (n = data[code[I]]; n; -- n)
			if ((c = data[code[I] + n]) != PARAMETER)
				unchar(c);
			/*
			else if (n > 1
			&& data[code[I] + n - 1] == PARAMETER
			) {
				unchar(PARAMETER); -- n;
			}
			*/
			else {
				while (top > 0)
					unchar(data[* S + --top]);
				--S,  pop;
				stackcheck();
			}
		I++;
	Done

Immediate(`RECURSE') COMPILE_ONLY
	nextlast = last, last = c(code(currentdefinition) + 1);
Done

Execution(`SEARCH-WORDLIST') /* c-addr u wid -- 0 | xt 1 | xt -1 */
/*
Find the definition identified by the string c-addr u in the word list
identified by wid . If the definition is not found, return zero. If
the definition is found, return its execution token xt and one (1) if
the definition is immediate, minus-one (-1) otherwise.
*/
	/* Make counted string at finger from S[-1],*S */
	move(&data[finger + 1], &data[S[-1]], data[* S]);
	data[finger] = *S--, S--;
	monocase(finger);
	source = finger;
	if ((link = searchwordlist(&data[finger], top)) != 0)
		*++S = code(link),
		top = code[code(link)] == beORDINARY ? -1 : 1;
	else
		top = 0;
Done

Execution(`SPACES')
	while (top-- > 0) emit(SPACE) ;
	pop;
Done

Execution(`STATE')
	data(WALL - sizeof(cell)) = state;
	push WALL - sizeof(cell);
Done

Execution(`TIME&DATE')
	struct tm * broken_down_time;
	time_t time_now;

	time_now = time(NULL);
	broken_down_time = localtime(&time_now);
	push broken_down_time->tm_sec;
	push broken_down_time->tm_min;
	push broken_down_time->tm_hour;
	push broken_down_time->tm_mday;
	push broken_down_time->tm_mon + 1;
	push broken_down_time->tm_year + 1900;
Done

Execution(`TYPE') type(&data[*S--], top), pop; Done

REDUNDANT(`
Execution(`WITHIN') /* OVER - >R - R> U< */
	w = *S--,
	top = LOWER(*S - w, top - w) LOGICAL;
	S--;
Done
')

Execution(`WORD')
	parseword((int) top);
	top = shelve();
Done

Immediate(`[')
	state = FALSE;
Done

REDUNDANT(`
Immediate(`\\')
	while ((c = char()) >= 0 && c != EOL) ;
	unchar(EOL);
Done
')

Execution(`]') state = TRUE; Done

Execution(`D+')
	S[-2] += *S;
	top += S[-1] + LOWER(S[-2], *S);
	S -= 2;
Done

Execution(`D-')
	top = S[-1] - top - LOWER(S[-2], *S);
	S[-2] -= *S;
	S -= 2;
Done

Execution(`UM*')
	cell n, t;
	t = top, n = *S;
	umul(&n, &t);
	*S = n, top = t;
Done

Execution(`UM/MOD')
	cell n2, n, t;
	t = top, n = *S--, n2 = *S;
	udiv(&n2, &n, t);
	*S = n2, top = n;
Done

Execution(`M*')
	cell n, t;
	t = top, n = *S;
	smul(& n, &t);
	*S = n, top = t;
Done

Execution(`SM/REM')
	cell n2, n, t;
	t = top, n = *S--, n2 = *S;
	sdiv(&n2, &n, t);
	*S = n2, top = n;
Done

Execution(`FM/MOD')
	cell n2, n, t;
	t = top, n = *S--, n2 = *S;
	fdiv(&n2, &n, t);
	*S = n2, top = n;
Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* `CONSTANT' `DOES>' */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`CONSTANT')
	ifdef(`LONG',`adopt(beCONSTANT), c(top);',`
	if (isshort(top))
		adopt(beCONSTANT), c(top);
	else
		adopt(beLCONSTANT),
		u.Long = top, c(u.Short[0]), c(u.Short[1]);
	')
	pop;
	code[code[CURRENT]] = code[next] = previous = currentdefinition;
	here = aligned(here);
Done

Execution(`DOES>')
	if (code[code(previous)] == beCONSTANT) {
		if (previous != next - 4) HOW;
		code[code(previous)] = incr(OPER), c(eval(OPER + 2)), c(I);
		code[next] = previous = currentdefinition;
	} else if (code[code(previous)] == incr(OPER)
	       || code[code(previous)] == eval(OPER + 2))
	{
		code[code(previous) + 3] = I;
	} else if (code[code(previous)] == beIMMEDIATE + 1)  {
		code[next-2] = OPER + 3, c(OPER + 2), c(I);
		code[next] = previous = currentdefinition;
	} else HOW;
	I = *R--;
Done
	Primitive
		if (! state)
			interpret(++xt);
		else
			nextlast = last, last = c(++xt);
	Done
	Primitive
		push code[xt - 2];
		*++R = I, I = code[xt];
	Done
	Primitive
		++xt; recurse;
	Done

Execution(`|') if (anonymous) HOW ;
	anonymous = TRUE;
Done

Execution(`||') if (anonymous) HOW ;
	for (
		link = code[code[CURRENT]];
		localname != LOCALNAME;
		link = code[link]
	)
		if (ifdef(`LONG',,`(unsigned short)') code[link + 1] >= LOCALNAME)
			localname = ifdef(`LONG',,`(unsigned short)') code[link + 1],
			code[link + 1] = 0;
	anonymous = FALSE;
Done

WORD(`base') ADOPT(beCONSTANT) Com(NAMEROOM)

Execution(`MARKER') if (anonymous) HOW ;
	adopt(beORDINARY), c(incr(OPER)), c(namespace), c(here);
	for (n = 0; n < GILDED; ++ n)
		c(code[CURRENT + n]);
	code[code[CURRENT]] = code[next] = previous = currentdefinition;
Done
Primitive
	next = xt - 4;
	finger = code[xt++];
	here = code[xt++];
	for (n = 0; n < GILDED; ++ n)
		code[CURRENT + n] = code[xt++];
	code[code[CURRENT]] = previous = currentdefinition = code[next];
Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* File primitives. */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`STREAM')
	cpps[files] = cpp, cpp = cp;
	file[files ++] = usrin;
	device = usrin = top ? (FILE *) top : stdin;
	pop;
Done

Execution(`UNSTREAM')
	if (files)
		device = usrin = file[--files],
		cp = cpp,
		cpp = cpps[files];
	else
		if (stream() == NULL)
			device = usrin = stdin;
Done

Execution(`DISPLAY')
	usrout = top ? (FILE *) top : stdout;
	pop;
Done

Execution(`FOPEN')
{	/* Standard C Library */
	char filemode[4];
	/* Make NUL-terminated string at &data[POCKET+1] from S[-2],S[-1] */
	move(&data[POCKET + 1], &data[S[-2]], S[-1]),
		data[POCKET + S[-1] + 1] = EOS,
			data[POCKET] = S[-1];
	/* Make NUL-terminated string at filemode from *S,top */
	move(filemode, &data[* S], top), filemode[top] = EOS;
	S -= 3;
	top = (cell) fopen((char *)&data[POCKET + 1], filemode);
}
Done

Execution(`FFLUSH') top = fflush(top ? (FILE *) top : usrout); Done

Execution(`FCLOSE')
	top = (cell) fclose(top ? (FILE *) top : usrin);
Done

Execution(`FSEEK')
	if (! S[-1] || (FILE *) S[-1] == usrin) cp = cpp ;
	top = fseek(S[-1] ? (FILE *) S[-1] : usrin, *S, top);
	S -= 2;
Done

Execution(`FTELL')
	top = ftell(top ? (FILE *) top : usrin) - (cp - cpp);
Done

Execution(`ERROR?')
	push ferror(device), clearerr(device);
Done

sinclude(`custom.m4')

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Implementation Words */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`HAS') top = (unsigned) code[top]; Done

Execution(`PATCH') code[(unsigned) top] = *S--, pop; Done

Execution(`ARGUMENT')
	if (++parg < pargc) {
		data[finger] = strlen(pargv[parg]);
		strcpy((char *) &data[finger + 1], pargv[parg]);
	} else
		data[finger] = 0;
	n = shelve();
	push data[n], *++S = n + 1;
Done

Execution(`SYSTEM')
	/* Make NUL-terminated string at &data[finger] from *S,top */
	move(&data[finger], &data[*S--], top);
	data[finger + top] = EOS;
	top = system((char *) &data[finger]);
Done

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`VERSION')
	printf("%s   incr(OPER) Primitives\n", sccsid);
	printf("Used: Codespace %d, Namespace %d, Dataspace %d\n",
		next, finger, here - NAMEROOM);
Done

ifdef(`EXTENDED',`include(`rth.m4')')

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

divert(UTILITIES)

# ifdef CLASSIC
void adopt (primitive) primitive functionnumber;
# else
void adopt (primitive functionnumber)
# endif
{	/* Get the next word and build a header.*/
	if (code[CURRENT] == 0) sorry("(New Definitions Not Allowed)") ;
	currentdefinition = next, dataspace = here, namespace = finger;
	if (! lexer(&data[finger])) sorry("(End of File)") ;
	monocase(finger);
	previous = code[code[CURRENT]];
	if (anonymous) {
		c(previous), previous = currentdefinition;
		move(
			&data[localname], &data[finger], data[finger] + 1
		);
		c(localname), localname += data[localname] + 1;
		anonymous = FALSE;
	} else {
		source = finger;
		link = searchwordlist(&data[finger], previous);
		c(previous), previous = currentdefinition;
		if (link) {
			type(&data[finger+1], data[finger]),
			fprintf(stdout, " (Redefined) ");
			c(code[link + 1]);
		} else
			c(textliteral());
	}
	c(functionnumber);
}

# ifdef CLASSIC
CodeLocation findword (s) DataAddress s;
# else
CodeLocation findword (DataAddress s)
# endif
{	/* The internal function for FIND */
	CodeLocation i;
	CodeLocation link;
	unsigned char * word = &data[s];

	monocase(s);

	source = s;
	for (i = 0; i < 8 && code[i + CONTEXT] != 0; ++i) {
		link = searchwordlist(word, code[code[i + CONTEXT]]);
		if (link != 0) return link ;
	}

	return (CodeLocation) 0;
}

# ifdef CLASSIC
void number (n3, n2, n, t) cell * n3; cell * n2; cell * n; cell * t;
# else
void number (cell *n3, cell *n2, cell *n, cell *t)
# endif
{
	cell a, b;
	while (*t && LOWER(a = todigit(data[*n]), BASE)) {
		b = BASE;
		umul(n3, &b);
		*n2 *= BASE;
		*n2 += b;
		*n3 += a;
		if (LOWER(*n3, a)) ++ *n2;
		++ *n, -- *t;
	}
}

void    restart proto((void))
{	/* Back out of everything. */
	fflush(usrout);
	if (usrout != stdout)
		fclose(usrout);
	usrout = stdout;
	while (files) {
		if (usrin != stdin)
			fclose(usrin);
		usrin = file[--files];
	}
	if (usrin != stdin)
		fclose(usrin);
	usrin = stdin;
	cp = cpp = CS;
	if (progress)
		currentdefinition = progress, progress = 0;
	if (state)
		next = currentdefinition, here = dataspace, finger = namespace;
	while (char() != EOL) ; unchar(EOL);
	anonymous = state = FALSE, level = 0;
	longjmp(jmpbuf, 1);
}

# ifdef CLASSIC
CodeLocation	searchwordlist (word, previous) unsigned char * word; CodeLocation previous;
# else
CodeLocation	searchwordlist (unsigned char * word, CodeLocation previous)
# endif
{	/* The internal function for SEARCH-WORDLIST */
	int link;
	unsigned char *str, *pat;
	int n;

	link = previous;

	for (;;) {
		str = word, pat = &data[ifdef(`LONG',,`(unsigned short)')code[link+1]];
		if ((n = *word) == *pat) {
			while (n && *++str == *++pat)
				--n;
			if (n == 0) break ;
		}
		link = code[link];
	}
	return link;
}

# ifdef CLASSIC
int lexer (charp) unsigned char *charp;
# else
int lexer (unsigned char * charp)
# endif
{   /* Get a graphic word of max length WIDTH .*/
	int c, n;
	while ((c = char()) != EOF  && ! isgraph(c)) {
		if (c == EOL) {
			linebreak = ftell(usrin);
			if (usrin == stdin && cp == cpp) {
				if (! state)
					printf("(OK)\n");
				for (n = S - stack; n > 0; -- n)
					printf("    ");
			}
		}
	}
	for (n = 0; c != EOF && isgraph(c); c = char()) {
		if (n < WIDTH)
			++ n ;
		else
			move(&charp[WIDTH - 10],&charp[WIDTH - 9], 10);
		charp[n] = c;
	}
	charp[0] = n, charp[n + 1] = EOS;

	if (c == EOL) unchar(c);

	return n;
}

FILE    * stream proto((void))
{   /* Open next file.*/
	if (usrin && usrin != stdin)
		fclose(usrin);
	if (files)
		usrin = file[--files],
			cp = cpp, cpp = cpps[files];
	else if (++parg >= pargc || ! strcmp(pargv[parg], "-")) {
		usrin = stdin; unchar(EOL);
	} else
		if ((usrin = fopen(pargv[parg], "r")) == NULL)
			printf("Can't open %s.\n", pargv[parg]) ;
	return usrin;
}

# ifdef CLASSIC
void    monocase (caddr) long caddr;
# else
void    monocase (DataAddress caddr)
# endif
{   /* Convert word to lowercase if no lowercase in word.*/
	int n;
	for (n = data[caddr]; n && ! islower(data[caddr + n]); -- n) ;
	if (! n)
		for (n = data[caddr]; n; -- n)
			data[caddr + n] = tolower(data[caddr + n]);
}

DataAddress shelve proto((void))
{
	DataAddress result;
	if (shelf + data[finger] >= POCKET) shelf = WALL ;
	move(&data[shelf], &data[finger], data[finger] + 1);
	result = shelf, shelf += data[finger] + 1;
	return result;
}

DataAddress textliteral proto((void))
{	/* Find location of text-literal for string at &data[finger]. */
	unsigned char * str, * pat;
	register int i, n;
	for (n = 0;; n += data[n] + 1)  {
		str = &data[n], pat = &data[finger];
		i = * str;
		if (i == * pat)  {
			while (i && *++str == *++pat) --i ;
			if (i == 0) break ;
		}
	}
	if (n == finger) finger += data[finger] + 1 ;
	return n;
}

# ifdef CLASSIC
void    parseword (delimiter) int delimiter;
# else
void    parseword (int delimiter)
# endif
{
	int c;
	int n = 0;
	if (delimiter == SPACE) {
		while ((c = char()) != EOF && c != EOL && ! isgraph(c)) ;
		while (isgraph(c)) {
			if (n < COUNTED_STRING_MAX)
				data[++ n + finger] = c;
			c = char();
		}
		if (c == EOL /* && n */) unchar(EOL) ;
	} else {
		while ((c = char()) != EOF && c != EOL && c == delimiter) ;
		while (c != EOF && c != EOL && c != delimiter) {
			if (n < COUNTED_STRING_MAX)
				data[++ n + finger] = c ;
			c = char();
		}
		if (c == EOL && delimiter != EOL) unchar(EOL) ;
	}
	data[finger] = n;
}

# ifdef CLASSIC
void    parse (delimiter) int delimiter;
# else
void	parse (int delimiter)
# endif
{
	int c;
	int n = 0;
	while ((c = char()) != EOF && c != EOL && c != delimiter)
		if (n < COUNTED_STRING_MAX)
			data[++ n + finger] = c ;
	if (c == EOL && delimiter != EOL) unchar(EOL) ;
	data[finger] = n;
}

# ifdef CLASSIC
void    type (str, n) unsigned char * str; long n;
# else
void	type (unsigned char * str, long n)
# endif
{   /* Display n chars of str.*/
	while (n -- > 0) emit(* str++) ;
}

# if defined(SIGABRT) || defined(SIGINT)
# ifdef CLASSIC
static void	sigabrt (exception) int exception;
# else
static void	sigabrt (int exception)
# endif
{
	(void) exception;
	sorry("(Interrupt)");
}
# endif

# ifdef CLASSIC
void    sorry (error) char *error;
# else
void	sorry (char * error)
# endif
{	/* Display error message, then skip everything to newline.*/
	int c;
	fprintf(stdout, "%s ", error);
	type(&data[source+1],data[source]);
	if (usrin != stdin) {
		 emit(EOL);
		(void) fseek(usrin, linebreak, 0);
		while ((c = char()) != EOL) emit(c);
		unchar(EOL);
	}
	S = stack; top = * S = 0;

	restart();
}

divert(MAIN)

# define SELF_COMPILE if (! state) namespace=finger,dataspace=here,\
	state=TRUE,progress=next,next=TRAMPOLINE+2,colevel=S-stack;
# define COMPLETE if (progress && colevel == S-stack)\
	c(doEXIT),finger=namespace,next=progress,progress=0,state=FALSE,\
		*++R=I, I=TRAMPOLINE+2;
# define HOW sorry("(Misused)");
# define HUH sorry("(Unrecognized)");
# define COMPILE_ONLY if (! state) sorry("(Compile Only)") ;

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

FILE * usrin = NULL, * usrout = NULL;
int parg; int pargc; char ** pargv;

char CS[CHARACTERROOM];

union { double Double; long Long; short Short[4]; } u;

cell rack[RETURN_STACK_CELLS + 3], *R = rack;
cell stack[STACK_CELLS + 3], *S = stack, top;
ifdef(`FLOATING',`
double fstack[FLOATING_STACK + 2], *F = fstack, ftop; /* floating point stack */
')
unsigned int currentdefinition, context, previous, link, I;
int colevel, leaves, level, progress, state = FALSE;
DataAddress finger, here;
DataAddress shelf = WALL;
DataAddress dataspace, namespace;
int last, nextlast;
unsigned localname = LOCALNAME;
int anonymous = FALSE;

FILE * file[maxfiles];
FILE * device = NULL;
char* cpps[maxfiles]; /* Character Pointer Pointer Stack */
char* cpp = CS; /* Character Pointer Pointer */
char* cp = CS; /* Character Pointer */
long bol[maxfiles];
long linebreak;
int files = 0;

jmp_buf jmpbuf;

unsigned char dataload[FINGER] = { 0, /* `Next name at' FINGER */
	undivert(NAMESPACE)
};

static instruction codeload[NEXT]={ /* `Next instruction at' NEXT */
	undivert(CODESPACE)
};

unsigned char * data;

static instruction * code;

undivert(UTILITIES)

undivert(PROTOTYPES)

divert(MAIN)

ifdef(`FUN',`
void (*fun[])(void) = {
undivert(FUNCTIONS)
};
	int xt;
	cell w;
	int n;
	int c;
	int d;
	ifdef(`FLOATING',`double f;')
undivert(PRIMITIVES)
int main(int argc, char ** argv) {
',`
int main(int argc, char ** argv) {
	register int xt;
	register cell w;
	register int n;
	register int c;
	int d;
	ifdef(`FLOATING',`double f;')
')
	/* Skeleton for the Kernel */
	usrin = stdin;
	device = stdin;
	usrout = stdout;
	pargc = argc, pargv = argv;
	setbuf(stdin,NULL);

	if ((data = malloc(DATAROOM * sizeof(char))) == 0 ||
		(code = malloc(CODEROOM * sizeof(instruction))) == 0
	) {
		fprintf(stderr, "Can't allocate memory.\n");
		return EXIT_FAILURE;
	}
	for (finger = 0; finger < FINGER; ++finger)
		data[finger] = dataload[finger];
	for (next = 0; next < NEXT; ++next)
		code[next] = codeload[next];

	currentdefinition = 0, code[next] = code[FORTH] = previous = LAST;
	code[CURRENT] = code[CONTEXT] = FORTH;
	BASE = 10;
	here = NAMEROOM + sizeof(cell);
	
	signal(SIGABRT, &sigabrt);

	if (stream() == NULL) return EXIT_FAILURE ;
# ifdef HI
	unchar(EOL); unchar('I'); unchar('H');
# endif
	switch (setjmp(jmpbuf))
	{
	case 0: case 1: break;
	case 2: return EXIT_SUCCESS;
	default: return EXIT_FAILURE;
	}
# ifdef SIGINT
	signal(SIGINT,&sigabrt);
# endif
# ifdef SIGABRT
	signal(SIGABRT,&sigabrt);
# endif
	I = START;
	R = rack;
	rack[0] = 0;

	/* PRIMITIVE INTERPRETER */

	for (;/* ever */;) {
		xt = code[I++]; /* `Number of codes' = OPER */
	ifdef(`FUN',`
		if (LOWER(code[xt], OPER))
			fun[code[xt++]]();
		else {
	',`
		RECURSE: switch(code[xt++]) { /* `NATIVE OPERATIONS' */
			undivert(PRIMITIVES)
		default:
	')
			printf("%ld: %ld ", I - 1, code[--xt]);
			sorry("(Invalid Instruction in Simulated Machine)");
		}

	}
}
