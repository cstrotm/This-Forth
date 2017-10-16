/*` Custom Primitives for Unix -- Skip Carter '*/

Execution(`OPEN-PIPE')

	char filemode[4];
	/* Make NUL-terminated string at &data[POCKET+1] from S[-2],S[-1] */
	move(&data[POCKET + 1], &data[S[-2]], S[-1]),
		data[POCKET + S[-1] + 1] = EOS,
			data[POCKET] = S[-1];
	/* Make NUL-terminated string at filemode from *S,top */
	move(filemode, &data[* S], top), filemode[top] = EOS;
	S -= 2;

	*S = (cell) popen((char *)&data[POCKET + 1], filemode);
	top = *S ? 0 : -1; 

Done

Execution(`CLOSE-PIPE')
	top = (cell) pclose( (FILE *) top );
Done

ifdef(`FILEHDL',`include(`filehdl.m4')')

ifdef(`USE_XDR',`include(`xdr.m4')')

Execution(`STDIN') push (cell)stdin; Done

Execution(`GETENV')

	char *env;

        /* Make NUL-terminated string at &data[finger] from *S,top */
        move((char*)&data[finger], &data[*S], top);
        data[finger+top] = EOS;

        env = (char*) getenv((char *)&data[finger] );

	if ( env )
	{
		top = strlen( env );

		move( (char *)&data[*S], env, top);
	}
	else
	{
		top = 0;
		data[ *S ] = '\0';
	}

Done

Execution(`TIMESTAMP')

        time_t clock;

        clock = time((time_t *) 0);

	top = 24;

	move( (char *)&data[*S], ctime( &clock ), top);

Done
