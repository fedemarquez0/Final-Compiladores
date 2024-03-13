salida: main.c lex.yy.c sintactico.tab.c listaSimbolos.c listaCodigo.c
	gcc lex.yy.c main.c sintactico.tab.c listaSimbolos.c listaCodigo.c -lfl -o salida

sintactico.tab.c sintactico.tab.h : sintactico.y
	bison -d sintactico.y

lex.yy.c: lexico.l sintactico.tab.h
	flex lexico.l
