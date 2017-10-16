/* Low Level Forth Floating Point Primitives for This Forth 95-04-02 */

static void floatcheck(void);  /* Prototype */

static void floatcheck(void)
{
	if ((unsigned)(F - fstack) > FLOATING_STACK)
		sorry("(Floating Stack Error)");
}

Immediate(`FLITERAL') fliteral(); Done

Execution(`D>F')
	unsigned long ul = *S--;
	fpush (double)ul + ((double)top * 4.294967296e9);
	pop;
Done

# define FORMIDABLE 4.294967296e9

Execution(`F>D')
	double x = ftop; fpop;
	
	if (x < 0.0) {
		x = -x;
		push (long)(x / FORMIDABLE);
		*++S = (unsigned long)(x - (((long)(x/FORMIDABLE)) * FORMIDABLE));
		if (*S)
			*S = -*S, top = ~top;
		else
			top =  -top;
	} else {
		push (long)(x / FORMIDABLE);
		*++S = (unsigned long)(x - (((long)(x/FORMIDABLE)) * FORMIDABLE));
	}
Done

ifdef(`SUPER',`
void fliteral(void)
{
	if (! state) return;
	nextlast = last, last = c(NEXT);
	u.Double = ftop, fpop;
	c(u.Long);
}
	Behavior
		u.Long = code[I++];
		fpush u.Double;
	Done
',`
void fliteral(void)
{
	if (! state) return ;
	nextlast = last, last = c(NEXT);
	u.Double = ftop, fpop;
	c(u.Short[0]), c(u.Short[1]), c(u.Short[2]), c(u.Short[3]);
}
	Behavior
		u.Short[0] = code[I++], u.Short[1] = code[I++],
		u.Short[2] = code[I++], u.Short[3] = code[I++],
		fpush u.Double;
	Done
')
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Floating Point Stack Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`FDEPTH') push F - fstack; Done
Execution(`FDROP') fpop; Done
Execution(`FDUP') *++F = ftop; Done
Execution(`FNIP') F--; Done				/* Not Standard */
Execution(`FOVER') fpush F[-1]; Done
Execution(`FSWAP') f = ftop, ftop = *F, *F = f; Done
Execution(`FROT')
		f = F[-1], F[-1] = *F, *F = ftop, ftop = f;
Done

Execution(`FPICK') *++F = ftop, ftop = F[-top], pop; Done /* Not Standard */

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */
/* Floating Point Operations */
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

Execution(`F.')
	fprintf(usrout, "%G ", ftop);
	fpop;
Done

Execution(`F+') ftop += *F--; Done
Execution(`F-') ftop = *F-- - ftop; Done
Execution(`F*') ftop *= *F--; Done
Execution(`F/') ftop = *F-- / ftop; Done

Execution(`FSQRT') ftop = sqrt(ftop); Done
Execution(`F**') ftop = pow(*F--, ftop); Done

Execution(`FABS') ftop = fabs(ftop); Done
Execution(`FLN')  ftop =log(ftop); Done
Execution(`FEXP') ftop = exp(ftop); Done
Execution(`FSIN') ftop = sin(ftop); Done
Execution(`FCOS') ftop = cos(ftop); Done
Execution(`FTAN') ftop = tan(ftop); Done
Execution(`FACOS') ftop = acos(ftop); Done
Execution(`FASIN') ftop = asin(ftop); Done
Execution(`FATAN') ftop = atan(ftop); Done
Execution(`FATAN2') ftop = atan2(*F--, ftop); Done

Execution(`F<')	push *F-- < ftop LOGICAL; fpop; Done
Execution(`F>') push *F-- > ftop LOGICAL; fpop; Done  /* Not Standard */
Execution(`F0<') push ftop < 0.0 LOGICAL; fpop; Done
Execution(`F0=') push ftop == 0.0 LOGICAL; fpop; Done

Execution(`FLOOR') ftop = floor(ftop); Done

Execution(`>FLOAT')
	char *pp;
	
	/* Make NUL-terminated string at &data[finger] from *S,top */
	move((char*)&data[finger], &data[*S], top);
	data[finger+top] = EOS;
	S--;
	f = strtod((char*)&data[finger], &pp);
	if (*pp == EOS)
		fpush f, top = TRUE;
	else {
		while (*pp == SPACE) pp++;
		if (*pp == EOS)
		         fpush f, top = TRUE;
		else
		          top = FALSE;
	}
Done

Execution(`F!')
        u.Double = ftop, fpop;
        move(&data[top], &u.Double, sizeof(double)), pop;
Done

Execution(`F@')
        move(&u.Double, &data[top], sizeof(double)), pop;
        fpush u.Double;
Done
