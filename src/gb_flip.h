# define gb_next_rand() (*gb_fptr >= 0 ? *gb_fptr-- : gb_flip_cycle())
# define mod_diff(x,y) (((x) - (y)) & 0x7FFFFFFF)
# define two_to_the_31 ((unsigned long) 0x80000000)

extern long *gb_fptr;

extern long gb_flip_cycle(void);
extern void gb_init_rand(long seed);
extern long gb_unif_rand(long m);
extern int gb_flip(void);

