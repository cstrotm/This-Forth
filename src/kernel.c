static char sccsid[] = "@(#)ThisForthKernel.c    Wil Baden   95-03-27 ";
# include "fo.h"

extern cell *S, top;

static void na_over_b proto((unsigned long, unsigned long, unsigned long));

void scale proto((void)) /* Star-Slash-Mod */
{
	int sq = 0, sr = 0;
	unsigned long n, a, b;
	b = top < 0 ? (sq = sr = 1, -top) : top;
	a = *S < 0 ? (sq ^= 1, -*S--) : *S--;
	n = *S < 0 ? (sq ^= 1, -*S) : *S;
	na_over_b(n, a, b);
	if (sq) top = -top;
	if (sq ^ sr) *S = -*S;
}
/*
D. E. Knuth, _The Stanford GraphBase_, Addison-Wesley, ISBN 0-201-54275-7, p.322.

Integer scaling. Here's a general-purpose routine to compute floor[na/b]
exactly without risking integer overflow, given integers n >= 0 and
0 < a <= b. The idea is to solve the problem first for n/2, if n is
too large.

We are careful to precompute values so that integer overflow cannot
occur when b is very large.
*/

#define el_gordo 0x7fffffff

# ifdef CLASSIC
static void na_over_b (n, a, b)
unsigned long n; unsigned long a; unsigned long b;
# else
static void na_over_b (unsigned long n, unsigned long a, unsigned long b)
# endif
{
	unsigned long nmax = (unsigned long) el_gordo / a; /* The largest n so that na doesn't overflow. */
	unsigned long r, k, q, br;
	unsigned long a_thresh, b_thresh;
	unsigned long bit = 0;

	if (n <= nmax) {
		/* return (n * a) / b; */
		top = (n * a) / b;
		*S = (n * a) % b;
		return;
	}
	a_thresh = b - a; b_thresh = (b + 1) >> 1;  /* ceil[b/2] */
	k = 0;
	do  {
		bit <<= 1;
		bit |= n & 1;
		n >>= 1;
		k++;
	} while (n > nmax);
	r = n * a; q = r / b; r = r - q * b;
	/* Maintain quotient q and remainder r while increasing n back to
	its original value. */
	do  {
		k--;
		q <<= 1;
		if (r < b_thresh)
			r <<= 1;
		else
			q++, br = (b - r) << 1, r = b - br;
		if (bit & 1)  {
			if (r < a_thresh)
			r += a;
			else
			q++, r -= a_thresh;
		}
		bit >>= 1;
	} while (k);
	/* return q; */
	top = q;
	*S = r;
}

#define CELL_SIZE ((sizeof(long) / sizeof(char)) * CHAR_BIT)
#define HALF_CELL_SIZE (CELL_SIZE / 2)

#define lowpart(t) ((unsigned long) (t) & ((1L << HALF_CELL_SIZE) - 1))
#define highpart(t) ((unsigned long) (t) >> HALF_CELL_SIZE)

# ifdef CLASSIC
void	umul (n, t) cell * n; cell * t;
# else
void	umul (cell * n, cell * t)
# endif
{
	unsigned long x0, x1, x2, x3;
	unsigned long ul, vl, uh, vh;

	ul = lowpart(*t);
	uh = highpart(*t);
	vl = lowpart(*n);
	vh = highpart(*n);

	x0 = ul * vl;
	x1 = ul * vh;
	x2 = uh * vl;
	x3 = uh * vh;

	x1 += highpart(x0);
	x1 += x2;
	if (LOWER(x1, x2))      /* Did we get a carry? */
		x3 += 1L << HALF_CELL_SIZE; /* Yes, add it in the proper posi. */

	*t = x3 + highpart(x1);
	*n = lowpart(x1) << HALF_CELL_SIZE | lowpart(x0);
}

# ifdef CLASSIC
void	smul (n, t) cell * n; cell * t;
# else
void	smul (cell * n, cell * t)
# endif
{
	long multiplicand = *n, multiplier = *t;
	umul(n, t);
	if (multiplier < 0) *t -= multiplicand;
	if (multiplicand < 0) *t -= multiplier;
}

# define ShiftDivisor(bitshift,divisor) do { \
	bitshift = 0; \
	if (! (divisor & 0xFFFF0000)) bitshift += 16, divisor <<= 16; \
	if (! (divisor & 0xFF000000)) bitshift += 8, divisor <<= 8; \
	if (! (divisor & 0xF0000000)) bitshift += 4, divisor <<= 4; \
	if (! (divisor & 0xC0000000)) bitshift += 2, divisor <<= 2; \
	if (! (divisor & 0x80000000)) bitshift += 1, divisor <<= 1; \
	} while(0)

# ifdef CLASSIC
void	udiv (n2, n, t) cell * n2, cell * n; cell t;
# else
void	udiv (cell * n2, cell * n, cell t)
# endif
{
	unsigned long high_dividend, low_dividend, divisor;
	unsigned long d1, d0, q1, q0, r1, r0, m;
	int bitshift;
	divisor = t, high_dividend = *n, low_dividend = *n2;
	if (!LOWER(high_dividend,divisor)) sorry("(Divide overflow)");
	if (! high_dividend) {
		*n = low_dividend / divisor;
		*n2 = low_dividend % divisor;
	} else {
		ShiftDivisor(bitshift, divisor);
		if (bitshift) {
			high_dividend <<= bitshift;
			high_dividend |= low_dividend >> (CELL_SIZE - bitshift);
			low_dividend <<= bitshift;
		}
		d1 = highpart(divisor);
		d0 = lowpart(divisor);
		r1 = high_dividend % d1;
		q1 = high_dividend / d1;
		m = (unsigned long) q1 * d0;
		r1 = r1 << HALF_CELL_SIZE | highpart(low_dividend);
		if (LOWER(r1, m)) {
			q1--, r1 += divisor;
			if (!LOWER(r1, divisor) && LOWER(r1, m))
				q1--, r1 += divisor;
		}
		r1 -= m;
		r0 = r1 % d1;
		q0 = r1 / d1;
		m = (unsigned long) q0 * d0;
		r0 = r0 << HALF_CELL_SIZE | lowpart(low_dividend);
		if (LOWER(r0, m)) {
			q0--, r0 += divisor;
			if (!LOWER(r0, divisor) && LOWER(r0, m))
				q0--, r0 += divisor;
		}
		r0 -= m;
		*n = (unsigned long) q1 << HALF_CELL_SIZE | q0;
		*n2 = r0 >> bitshift;
	}
}

# define	ABS(x)	((x) < 0 ? -(x) : (x))

# ifdef CLASSIC
void	sdiv (n2, n, t) cell * n2, cell * n; cell t;
# else
void	sdiv (cell * n2, cell * n, cell t)
# endif
{
	long divi = *n, divisor = t;
	if (*n < 0)
		if (*n2)
			*n2 = -*n2, *n = ~*n;
		else
			*n = -*n;
	t = ABS(t);
	udiv(n2, n, t);
	if ((divi ^ divisor) < 0) *n = -*n;
	if (divi < 0) *n2 = -*n2 ;
}

# ifdef CLASSIC
void	fdiv (n2, n, t) cell * n2, cell * n; cell t;
# else
void	fdiv (cell * n2, cell * n, cell t)
# endif
{
	long divi = *n, divisor = t;
	if (*n < 0)
		if (*n2)
			*n2 = -*n2, *n = ~*n;
		else
			*n = -*n;
	t = ABS(t);
	udiv(n2, n, t);
	if (divisor < 0) *n2 = -*n2;
	if ((divi ^ divisor) < 0)  {
		*n = -*n;
		if (*n2)  {
			--*n;
			*n2 = divisor - *n2;
		}
	}
}

/** @(#)memmove.c after P. J. Plauger, _The Standard C Library_ **/

# ifdef CLASSIC
Generic (move) (dest, src, len) Generic dest; Generic src; Length len;
# else
Generic (move) (Generic dest, Generic src, Length len)
# endif
{
	char * whither = dest;
	const char * whence = src;

	if (whence < whither && whither < whence + len)
		for (whither += len, whence += len; len > 0; --len)
			*--whither = *--whence;
	else
		for( ; len > 0; --len)
			*whither++ = *whence++;
	return dest;
}
