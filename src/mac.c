/* PLATFORM for Code Warrior	Wil Baden	94-10-07 */

# include <stdio.h>
# include <stdlib.h>
# include <ctype.h>
# include <console.h>
# include <SIOUX.h>

# define main(x,y) MAIN(x,y)

extern int main(int argc, char ** argv);

#define	MAX_ARGS					 50

#ifndef	true
#define	true						  1
#define false						  0
#endif

static	int		argc = 1;			/* final argument count  */
static	char		*argv[MAX_ARGS]	= { "" };	/* array of pointers	 */
static	char		command[256];			/* input line buffer	 */
static	int		filename = false;		/* TRUE iff file name	 */

static void openfile(FILE *file, char *mode);
static void cString (char * progname, StringPtr apname);

/*************************************************************************
 *																		 *
 *  Local routine to open a file in argv[--argc] after closing its		 *
 *  previous existence.													 *
 *																		 *
 *************************************************************************/

static void openfile( FILE *file, char *mode)
	{

	if ( (file = freopen( argv[--argc], mode, file ) ) == NULL)
		SysBeep( 5L ), ExitToShell();
	filename = false;
	}


/*************************************************************************
 *																		 *
 *  New main routine.  Prompts for command line then calls user's main   *
 *  now called "MAIN" with the argument list and redirected I/O.		 *
 *																		 *
 *************************************************************************/

static void cString (char * progname, StringPtr apname)
{
	short i;
	for (i = *apname++; i-- != 0; *progname++ = *apname++) ;
	*progname = '\0';
}

void (main)(void)
	{
	char			c;							/* temp for EOLN check	 */
	register char	*cp;						/* index in command line */
	char			*mode;						/* local file mode		 */
	FILE			*file;						/* file to change		 */
	StringPtr		progname;
	
	extern tSIOUXSettings SIOUXSettings;

# ifndef CurApName
# define CurApName 0x910
# endif
	
	SIOUXSettings.showstatusline = 0;
	SIOUXSettings.tabspaces = 8;

	cString(( char *) progname, (StringPtr) CurApName);
	 
	fputs((char *) progname, stderr), fputc(' ', stderr), fflush(stderr);

	gets( command );							/* allow user to edit	 */
	cp = &command[0];							/* start of buffer		 */
	argv[0] = (char *) progname;				/* program name 		 */

	while (argc < MAX_ARGS)
		{ /* up to MAX_ARGS entries */
		while (isspace( *cp++ )) ;
		if ( !*--cp )
			break;
		else if ( *cp == '<' )
			{ /* redirect stdin */
			cp++;
			file = stdin;
			mode = "r";
			filename = true;
			}
		else if ( *cp == '>' )
			{
			mode = "w";
			filename = true;
			if (*++cp == '>')
				{
				mode = "a";
				cp++;
				}
			file = stdout;
			}
		else
			{ /* either an argument or a filename */
			c = (*cp == '\'' || *cp == '\"') ? *cp++ : ' ';
			argv[argc++] = cp;
			if (c == ' ')
				while ( *++cp && !isspace( *cp ) ) ;
			else
				while ( *++cp && *cp != c) ;
			c = *cp;
			*cp++ = '\0';
			if (filename)
				openfile( file, mode );
			if (!c)
				break;
			}
		}
	if (main( argc, argv ) == EXIT_SUCCESS)
		fflush(NULL);
	else
		{
		puts("Abnormal Termination.");
		puts("Press Return.");
		gets( command );
		}
	ExitToShell();
	}
