/** @(#)llfc.m4	Wil Baden 94-10-31	**/
/** Low Level Forth for C **/

undefine(`shift')

ifdef(`decr',,`define(`decr',`eval(($1)-1)')')

define(`NOWHERE',	-1)

divert(NOWHERE)

define(`MAIN',		0)
define(`NAMESPACE',	1)
define(`CODESPACE',	2)
define(`UTILITIES',	3)
define(`PRIMITIVES',	4) 
define(`PROTOTYPES',	5)
define(`FUNCTIONS',	6)

define(`cat',`$1$2$3$4$5$6$7$8$9')

define(`times',`ifelse(`$1',`0',,`$2'`times(decr($1),`$2')')')

define(`lowercase',
`translit(`$1',`ABCDEFGHIJKLMNOPQRSTUVWXYZ',`abcdefghijklmnopqrstuvwxyz')')

define(`TRAMPOLINE',(CODEROOM - 200))

define(`WORDLISTS',8)

define(`NEW_WORDLISTS',8)

define(`Com',`divert(CODESPACE)$1,define(`NEXT',incr(NEXT))')

define(`ADOPT',`Com(`
'LAST)define(`LAST',decr(NEXT))dnl
Com(FINGER)define(`FINGER',eval(FINGER+LENGTH+1))dnl
Com(/* NAME NEXT */ $1)	')

define(`Nominate',`divert(NAMESPACE)define(`NAME',`$1')')

define(`WORD',`Nominate($1) dnl
define(`LENGTH',ifelse(index(`$1',`\'),`-1',len($1),decr(len($1))))
LENGTH,Spell($1)')

define(`Primitive',
`ifdef(`FUN',`
divert(FUNCTIONS)cat(`fun',OPER),
divert(PROTOTYPES)void cat(`fun',OPER) proto((void));')
divert(PRIMITIVES)
ifdef(`FUN',`void cat(`fun',OPER) proto((void))',`case OPER:') { /* NAME decr(NEXT) */')

define(`Behavior',`Com(OPER)Primitive')

define(`Done',
`} ifdef(`FUN',,`break;')
define(`OPER',incr(OPER))divert(UTILITIES)define(`NAME',` ')')

define(`Compilation',`WORD(`$1')ADOPT(OPER)Primitive')

define(`Ordinary',`WORD(`$1')ADOPT(beORDINARY)Com(OPER)Primitive')

define(`Execution',`ifelse(`$1',,`Interpretation',
	`Ordinary(lowercase(``$1''))')')

define(`Immediate',`Compilation(lowercase(``$1''))')

define(`Optimization',`	if (! state) interpret(NEXT); else')

define(`Interpretation',`	else last = c(NEXT); Done')

define(`Copied', QuotedChar(`substr($1,0,1)'))
define(`Escaped',QuotedChar(`substr($1,0,2)'))

changequote([,])
define([QuotedChar],['$1',])
changequote

define(`Spell',
`ifelse(len(`$1'),0,,
substr(`$1',0,1),\,`Escaped($1)Spell(substr(`$1',2))',
`Copied($1)Spell(substr(`$1',1))')')

define(`THIS',	`decr(NEXT)')
define(`BEGIN',	`define(`START',NEXT)')
define(`AGAIN',	`Com(doBRANCH)Com(eval(START-NEXT))')

define(`LAST',	0)
define(`FINGER',	1)
define(`OPER',	0)
define(`NEXT',	0)

divert(UTILITIES)

