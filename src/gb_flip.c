/* gb_flip
 * D. E. Knuth, _The Stanford GraphBase_, Addison-Wesley, ISBN 0-201-54275-7
 */

# include <stdio.h>
# include "gb_flip.h"

/* Private Declarations */

static long A[56] = {-1};

/* External Declarations */

long *gb_fptr = A;

# define gb_next_rand() (*gb_fptr >= 0 ? *gb_fptr-- : gb_flip_cycle())

/* External Functions */

long gb_flip_cycle(void)
{
	register long *ii, *jj;
	
	for (ii = &A[1], jj = &A[32]; jj <= &A[55]; ii++, jj++)
		*ii = mod_diff(*ii, *jj);
	for (jj = &A[1]; ii<= &A[55]; ii++, jj++)
		*ii = mod_diff(*ii, *jj);
	gb_fptr = &A[54];
	return A[55];
}

void gb_init_rand(long seed)
{
	register long i;
	register long prev = seed, next = 1;
	
	seed = prev = mod_diff(prev, 0);
	A[55] = prev;
	for (i = 21; i; i =(i + 21) % 55) {
		A[i] = next;
		/* Compute a new next value. */
		next = mod_diff(prev, next);
		if (seed & 1)
			seed = 0x40000000 + (seed >> 1);
		else
			seed >>= 1;
		next = mod_diff(next, seed);

		prev = A[i];
	}
	/* Get the array values ``warmed up''. */
	(void) gb_flip_cycle();
	(void) gb_flip_cycle();
	(void) gb_flip_cycle();
	(void) gb_flip_cycle();
	(void) gb_flip_cycle();
}

long gb_unif_rand(long m)
{
	register unsigned long t = two_to_the_31 - (two_to_the_31 % m);
	register long r;
	
	do {
		r = gb_next_rand();
	} while (t <= (unsigned long) r);
	return r % m;
}

int gb_flip(void) 
{
	int j;
	
	gb_init_rand(-314159L);
	if (gb_next_rand() != 119318998) {
		fprintf(stderr,"Failure on the first try.\n");
		return -1;
	}
	for (j = 1; j <= 133; j++) gb_next_rand();
	if (gb_unif_rand(0x55555555L) != 748103812) {
		fprintf(stderr,"Failure on the second try.\n");
		return -2;
	}
	/* fprintf(stderr,"OK, the gb_flip_routines seem to work.\n"); */
	return 0;
}

