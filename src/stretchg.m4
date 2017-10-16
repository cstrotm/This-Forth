/*` "stretchg.m4"   Custom Functions for Stretching Forth	95-02-14 '*/

/*` Subject to changes. '*/

long IntSqrt proto((long));

Execution(`SQRTK') top = IntSqrt(top); Done

# ifdef	CLASSIC
long IntSqrt (x) long x;
# else
long IntSqrt (long x)
# endif
{   /* Nearest integer to 1024 * the square root of x */
	register long y, m, q = 2;
	int k;
	if (x <= 0) return 0 ;
	for (k = 25, m = 0x20000000; x < m; k --, m >>= 2) ;
	y = (x >= m + m) ? 1 : 0;
	do {
		y += (x & m) ? y + 1 : y;
		m >>= 1;
		y += (x & m) ? y - q + 1 : y - q;
		q += q;
		if (y > q)
			y -= q, q += 2;
		else if (y <= 0)
			q -= 2, y += q;
		m >>= 1;
	} while (--k);
	return q >> 1;
}

# include "gb_flip.h"

Execution(`RANDOM')	push gb_next_rand();		Done

Execution(`SET-RANDOM')	gb_init_rand(top), pop;		Done

Execution(`GET-RANDOM') top = gb_unif_rand(top);	Done

