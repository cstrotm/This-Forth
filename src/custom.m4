/* `This file is to define your custom primitives.'    94-04-02 */

ifdef(`FLOATING',`include(`floating.m4')')

ifdef(`MAC',`sinclude(`mac.m4')')

ifdef(`PC',`sinclude(`pc.m4')')

ifdef(`unix',`sinclude(`unix.m4')')

ifdef(`STRETCHING',`sinclude(`stretchg.m4')')

