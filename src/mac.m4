/* `Macintosh Dependent			94-10-07 '*/

Execution(`COUNTER') 	push TickCount(); Done

Execution(`KEY?')
	KeyMap theMap;

	GetKeys(theMap);
	push
	( ((long*)theMap)[0]
	| ((long*)theMap)[1]
	| ((long*)theMap)[2]
	| ((long*)theMap)[3]
	) LOGICAL;
Done

static void	pcpy proto((StringPtr d, StringPtr s));

Execution(`GET-FILE')	/*` ( -- filename . ) '*/
	SFTypeList theTypeList = {'TEXT'};
	StandardFileReply theReply;

	StandardGetFile(0L, 1, theTypeList, &theReply);

	if (theReply.sfGood == 0)
		data[finger] = 0;
	else if (HSetVol(0L, theReply.sfFile.vRefNum, theReply.sfFile.parID))
		data[finger] = 0;
	else
		pcpy((StringPtr)&data[finger], (StringPtr)theReply.sfFile.name);
	
	n = shelve();
	push data[n], *++S = n + 1;
Done

Execution(`PUT-FILE')  /*` ( filename . -- filename2 . ) '*/
	StandardFileReply theReply;
	
	Str255 theDefaultName;
	
	move(theDefaultName + 1, &data[*S--], top);
	theDefaultName[0] = top, pop;

	StandardPutFile("\pNew File", theDefaultName, &theReply);

	if (theReply.sfGood == 0)
		data[finger] = 0;
	else if (HSetVol(0L, theReply.sfFile.vRefNum, theReply.sfFile.parID))
		data[finger] = 0;
	else
		pcpy((StringPtr)&data[finger], (StringPtr)theReply.sfFile.name);
	
	n = shelve();
	push data[n], *++S = n + 1;
Done

Execution(`DELETE-FILE')	/*` someFileName . -- '*/
	Str255 theFileName;
	move(theFileName, &data[*S--], top), theFileName[top] = EOS;
	top = remove((char*)theFileName);
Done

# include <SIOUX.h>

extern tSIOUXSettings SIOUXSettings;

Execution(`SET-TABSPACES')	SIOUXSettings.tabspaces = top, pop; Done

# ifdef CLASSIC
static void	pcpy (d, s) StringPtr d; StringPtr s;
# else
static void	pcpy (StringPtr d, StringPtr s)
# endif
{
	short	i = *s;

	do {*d++ = *s++; } while (i-- != 0) ;
	
}
