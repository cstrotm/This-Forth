/** @(#)fo.h	Wil Baden	95-04-02 **/

# ifdef	LONG

# define	CODEROOM 	32760
# define	DATAROOM 	534288
# define	NAMEROOM 	12000
# define	CHARACTERROOM	2000
# define	SHELF_CHARS	1024
# define	RETURN_STACK_CELLS 250
# define	STACK_CELLS 	500

# else

# define	CODEROOM 	4500
# define	DATAROOM 	50000
# define	NAMEROOM 	6000
# define	CHARACTERROOM	1000
# define	SHELF_CHARS	1024
# define	RETURN_STACK_CELLS 50
# define	STACK_CELLS 	100

# endif

# ifdef CLASSIC
# define	proto(x) ()
typedef	char	* Generic;
typedef long	Length;
# else
# include	<stdlib.h>
# include	<stddef.h>
# define	proto(x) x
typedef	void	* Generic;
typedef size_t	Length;
# endif

typedef	int	primitive;
typedef int	behavior;
typedef long	cell;
typedef unsigned int	CodeLocation;
typedef unsigned int	DataAddress;
typedef int	Flag;

# include	<stdio.h>
# include	<string.h>
# include	<ctype.h>
# include	<limits.h>
# include	<time.h>
# include	<setjmp.h>
# include	<math.h>
# include	<stdlib.h>

# ifndef	FILENAME_MAX
# define	FILENAME_MAX	64
# endif

# define	MAXLINE		132

# ifndef	SEEK_SET
# define	SEEK_SET	0
# endif

# undef		FORTH83
# define	FORTH83		/* Use Forth-83 canonical true. */

# define	FLOATING_STACK	10
# define	COUNTED_STRING_MAX 255
# define	LOCALNAMEROOM 1000
# define	LOCALNAME	(DATAROOM - LOCALNAMEROOM)
# define	maxfiles 8
# define	WIDTH		31
# define	HOLD_CHARS	80
# define	POCKET		(NAMEROOM - HOLD_CHARS)
# define	WALL		(POCKET - SHELF_CHARS)

# define	PARAMETER	'~'
# define	EOL	'\n'
# define	EOS	'\0'
# define	SPACE	' '
# define	DECIMAL_POINT	'.'
# define	TICK '\''
# define	QUOTE '\"'

# undef 	FALSE
# undef 	TRUE
# define	FALSE	0
# define	TRUE	~0
# ifdef 	FORTH83
# define	LOGICAL ? TRUE : FALSE
# else
# define	LOGICAL
# endif
# ifndef EXIT_FAILURE
# define	EXIT_FAILURE	1
# endif
# ifndef EXIT_SUCCESS
# define	EXIT_SUCCESS	0
# endif

# define	CURRENT	4
# define	CONTEXT 5

# define	WORDLISTS	8

# define	BASE		data(NAMEROOM)

/*# define LOWER(x,y) (((x)^(y))&HIGH_BIT?((y)&HIGH_BIT)!=0:(x)<(y))*/
# define LOWER(x,y) ((unsigned long)(x)<(unsigned long)(y))

/* `aligned' assumes sizeof(cell) is a power of 2. */
# define	aligned(x)	((x) + (sizeof(cell) - 1) & ~(sizeof(cell) - 1))
# define	data(x)	*(cell*)&data[x]
# define	c(x)	code[next++] = x
# define	char()	(cp != cpp ? *--cp : getc(usrin))
# define	code(w)	(w + 2)		/* Execution Token */
# define	element -
# define	emit(c) putc(c, usrout)
# define	filterword(s) \
 while(!lexer(&data[s]))if(!stream())exit(parg<pargc) 
# define	fpop	ftop = *F--, floatcheck()
# define	fpush	*++F = ftop, floatcheck(), ftop =
# define 	isshort(w) (SHRT_MIN <= (w) && (w) <= SHRT_MAX)
# ifdef	FUN
# define	leave	return
# else
# define	leave	break
# endif
# define	lookup(link, s) link = findword(s)
# define	next	code[0]
# define 	operand code[next - 1]
# define	operation code[next - 1]
# define	pop	top = *S--
# define	push	*++S = top, top =

# ifdef FUN
# define	recurse	do{ fun[code[xt++]](); return; }while(0)
# else
# define	recurse	goto RECURSE
# endif

# define	source	code[1]

# define	todigit(c) ((unsigned) ((c) - '0') < 10 ? (c) - '0':\
	(unsigned) (((c)|0x20) - 'a') < 26 ? ((c)|0x20) - 'a' + 10 : -1)

# define	unchar(c)	do { *cp++ = (c); if (cp>=CS+CHARACTERROOM)\
				sorry("(Macro Overflow)"); } while(0)

void	adopt		proto((primitive functionnumber));
void	condition	proto((void));
void	fliteral	proto((void));
long	IntSqrt		proto((long x));
int 	lexer		proto((unsigned char *charp));
CodeLocation	findword	proto((DataAddress s));
int 	main		proto((int argc, char** argv));
Generic	(move)          proto((Generic dest, Generic src, Length len));
void	monocase	proto((DataAddress caddr));
void	parse		proto((int delimiter));
void	parseword	proto((int delimiter));
void	restart		proto((void));
CodeLocation	searchwordlist	proto((unsigned char* str, CodeLocation wid));
void	scale		proto((void));
DataAddress    shelve      	proto((void));
void	sorry		proto((char* error));
FILE*	stream		proto((void));
DataAddress	textliteral	proto((void));
void 	number		proto((cell *n3, cell *n2, cell *n, cell *t));
void	type		proto((unsigned char* str, long n));
void	udiv		proto((cell * n2, cell * n, cell t));
void	umul		proto((cell * n, cell * t));
void	smul		proto((cell * n, cell * t));
void	sdiv		proto((cell * n2, cell * n, cell t));
void	fdiv		proto((cell * n2, cell * n, cell t));

# ifdef THINK_C
# define main(argc,argv) MAIN(argc,argv)
# endif
# ifdef __MWERKS__
# define main(argc,argv) MAIN(argc,argv)
# endif

# ifdef main
int 	MAIN		proto((int argc, char** argv));
# endif
