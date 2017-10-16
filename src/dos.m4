/*` Custom Primitives for DOS -- Skip Carter '*/

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
