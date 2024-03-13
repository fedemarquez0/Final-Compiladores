%{
#include <stdio.h>
#include <string.h>
#include "listaSimbolos.h"

void yyerror();
extern int yylex();
extern int yylineno;
void main();
char *ConcatenaStr(char *a, char *b);

Lista tablaSimb; /* Lista enlazada para la tabla de simbolos*/
Tipo tipo; /* varibale global para identificar el tipo VARIABLE o CONSTANTE */
int contCadenas=0; /* contador de cadenas para el valor de los Strings */

int errores_sintacticos = 0; /* contador para la cantidad de errores sintacticos */
int errores_semanticos = 0; /* contador para la cantidad de errores semanticos */
extern int errores_lexicos; /* Traemos el contador del lexico.l para poder verificar a la hora de generar el archivo .s*/

char *obtenerEtiqueta();
int contadorEtiquetas = 1;

%}

%code requires{
#include "listaCodigo.h"
}

%union{
char *string;
ListaC Lcod;
}

%type <Lcod> expr state stat_list asig id_list declarations print_list print_item read_list

%token BEGINN END READ WRITE VOID CONST VAR IF ELSE WHILE PRINT RPAR LPAR RLLA LLLA SEMICOLON COMA EQ
 
%token <string> STR ID INTLIT

%left SUMA MENOS
%left POR DIV 

%%

program : {remove("MiPrograma.s"); tablaSimb=creaLS();} VOID ID LPAR RPAR LLLA declarations stat_list RLLA {	if(errores_lexicos == 0 && errores_sintacticos == 0 && errores_semanticos == 0){
																													guardarArchivoTS(tablaSimb);
																													concatenaLC($7,$8);
																													guardarArchivoLC($7);
																												}
																												liberaLS(tablaSimb);
																												liberaLC($8);
																												liberaLC($7);
																											}

declarations : declarations VAR {tipo=VARIABLE;} id_list SEMICOLON { $$ = creaLC(); concatenaLC($$, $1); concatenaLC($$,$4); liberaLC($1);liberaLC($4);}
			| declarations CONST {tipo=CONSTANTE;} id_list SEMICOLON { $$ = creaLC(); concatenaLC($$, $1); concatenaLC($$,$4); liberaLC($1);liberaLC($4);}
			|	/* lambda */ { $$ = creaLC(); }
			;
id_list : asig { $$ = $1; }
		| id_list COMA asig { $$ = creaLC(); concatenaLC($$, $1); concatenaLC($$,$3); liberaLC($1); liberaLC($3);}
		;
asig : ID { if (!perteneceTablaS(tablaSimb,$1)) {anadeEntrada(tablaSimb,$1, tipo,0);}
				else {printf("ERROR SEMANTICO: Variable %s ya declarada en la linea %d \n", $1, yylineno); errores_semanticos++;} 
			$$ = creaLC();
		  }
	| ID EQ expr {	if (!perteneceTablaS(tablaSimb,$1)) {
						anadeEntrada(tablaSimb,$1, tipo,0);
						$$ = creaLC();
						concatenaLC($$, $3);
						Operacion oper = crearOperacion("sw", recuperaResLC($3),ConcatenaStr("_",$1),NULL);
						guardaResLC($$,oper.res);
						insertaLC($$, finalLC($$),oper);
						liberarRegistro(recuperaResLC($3));
						liberaLC($3);
					}
					else {printf("ERROR SEMANTICO: Variable %s ya declarada en linea %d \n", $1, yylineno); errores_semanticos++;} 
				 }
	;
stat_list : stat_list state { $$ = creaLC(); concatenaLC($$,$1); concatenaLC($$,$2); liberaLC($1); liberaLC($2);} 
	   | /* lambda */   { $$ = creaLC(); }
	   ;

state : ID EQ expr SEMICOLON {	if (!perteneceTablaS(tablaSimb,$1)) {printf("ERROR SEMANTICO: Variable %s no declarada en la linea %d \n", $1, yylineno); errores_semanticos++;}
									else if (esConstante(tablaSimb,$1)) {printf("ERROR SEMANTICO: Asignacion constante a la variable %s en la linea %d \n",$1, yylineno); errores_semanticos++;}
									else {
										$$ = creaLC();
										concatenaLC($$,$3);
										Operacion oper = crearOperacion("sw", recuperaResLC($3),ConcatenaStr("_",$1),NULL);
										guardaResLC($$,oper.res);
										insertaLC($$,finalLC($$),oper);
										liberarRegistro(recuperaResLC($3));
										liberaLC($3);
									}
							 }
	| LLLA stat_list RLLA {	$$ = $2;}

	| IF LPAR expr RPAR state ELSE state {	$$ = $3;
											char * etiqueta1 = obtenerEtiqueta();
											Operacion oper = crearOperacion("beqz", recuperaResLC($3), etiqueta1, NULL);
											insertaLC($$,finalLC($$),oper);
											liberarRegistro(recuperaResLC($3));
											concatenaLC($$,$5);
											char * etiqueta2 = obtenerEtiqueta();
											oper = crearOperacion("b", etiqueta2, NULL, NULL);
											insertaLC($$,finalLC($$),oper);
											oper = crearOperacion(ConcatenaStr(etiqueta1,":"), NULL, NULL, NULL);
											insertaLC($$,finalLC($$),oper);
											concatenaLC($$,$7);
											oper = crearOperacion(ConcatenaStr(etiqueta2,":"), NULL, NULL, NULL);
											insertaLC($$,finalLC($$),oper);
											liberaLC($5);
											liberaLC($7);
										 }
	| IF LPAR expr RPAR state {	$$ = $3;
								char * etiqueta = obtenerEtiqueta();
								Operacion oper = crearOperacion("beqz", recuperaResLC($3), etiqueta, NULL);
								insertaLC($$,finalLC($$),oper);
								liberarRegistro(recuperaResLC($3));
								concatenaLC($$,$5);
								oper = crearOperacion(ConcatenaStr(etiqueta,":"), NULL, NULL, NULL);
								insertaLC($$,finalLC($$),oper);
								liberaLC($5);
							  }
	| WHILE LPAR expr RPAR state {	$$ = creaLC();
									char * etiqueta1 = obtenerEtiqueta();
									char * etiqueta2 = obtenerEtiqueta();
									Operacion oper = crearOperacion(ConcatenaStr(etiqueta1,":"), NULL, NULL, NULL);
									insertaLC($$,finalLC($$),oper);
									concatenaLC($$,$3);
									oper = crearOperacion("beqz", recuperaResLC($3), etiqueta2, NULL);
									insertaLC($$,finalLC($$),oper);
									liberarRegistro(recuperaResLC($3));
									concatenaLC($$,$5);
									oper = crearOperacion("b", etiqueta1, NULL, NULL);
									insertaLC($$,finalLC($$),oper);
									oper = crearOperacion(ConcatenaStr(etiqueta2,":"), NULL, NULL, NULL);
									insertaLC($$,finalLC($$),oper);
									liberaLC($3);
									liberaLC($5);
								 }
	| PRINT print_list SEMICOLON { $$ = $2;}
	| READ read_list SEMICOLON { $$ = $2;}
	;

print_list : print_item { $$ = $1;}
	     | print_list COMA print_item	{$$ = creaLC();
		 								concatenaLC($$,$1);
										concatenaLC($$,$3);
										liberaLC($1);
										liberaLC($3);
										}
	     ;
	     
print_item : expr {	$$ = creaLC();
					concatenaLC($$,$1);
					Operacion oper = crearOperacion("move", "$a0",recuperaResLC($1), NULL);
					insertaLC($$,finalLC($$),oper);
					oper = crearOperacion("li", "$v0","1", NULL);
					insertaLC($$,finalLC($$),oper);
					oper = crearOperacion("syscall", NULL, NULL, NULL);
					insertaLC($$,finalLC($$),oper);
					liberarRegistro(recuperaResLC($1));
					liberaLC($1);
				  }
	      | STR	{	anadeEntrada(tablaSimb,$1,CADENA,++contCadenas);
					$$ = creaLC();
					char str[20];
					sprintf(str, "$str%d", contCadenas);
					Operacion oper = crearOperacion("la", "$a0",strdup(str), NULL);
					insertaLC($$,finalLC($$),oper);
					oper = crearOperacion("li", "$v0","4", NULL);
					insertaLC($$,finalLC($$),oper);
					oper = crearOperacion("syscall", NULL, NULL, NULL);
					insertaLC($$,finalLC($$),oper);
				}
	      ;

read_list : ID	{if (!perteneceTablaS(tablaSimb,$1)) {printf("ERROR SEMANTICO: Variable %s no declarada en la linea %d \n", $1, yylineno); errores_semanticos++;}
					else if (esConstante(tablaSimb,$1)) {printf("ERROR SEMANTICO: Asignacion constante a la variable %s en la linea %d \n",$1, yylineno); errores_semanticos++;}
					else{
						$$ = creaLC();
						Operacion oper = crearOperacion("li", "$v0","5", NULL);
						insertaLC($$,finalLC($$),oper);
						oper = crearOperacion("syscall", NULL, NULL, NULL);
						insertaLC($$,finalLC($$),oper);
						oper = crearOperacion("sw", "$v0",ConcatenaStr("_",$1), NULL);
						insertaLC($$,finalLC($$),oper);
					}
				}
	    | read_list COMA ID	{if (!perteneceTablaS(tablaSimb,$3)) {printf("ERROR SEMANTICO: Variable %s no declarada en la linea %d \n", $3, yylineno); errores_semanticos++;}
								else if (esConstante(tablaSimb,$3)) {printf("ERROR SEMANTICO: Asignacion constante a la variable %s en la linea %d \n",$3, yylineno); errores_semanticos++;}
								else{
									$$ = creaLC();
									concatenaLC($$,$1);
									Operacion oper = crearOperacion("li", "$v0","5", NULL);
									insertaLC($$,finalLC($$),oper);
									oper = crearOperacion("syscall", NULL, NULL, NULL);
									insertaLC($$,finalLC($$),oper);
									oper = crearOperacion("sw", "$v0",ConcatenaStr("_",$3), NULL);
									insertaLC($$,finalLC($$),oper);
									liberaLC($1);
								}
							}
	    ;
	
expr : expr SUMA expr {	$$ = creaLC();
						concatenaLC($$,$1);
						concatenaLC($$,$3);
						Operacion oper = crearOperacion("add",getRegistroTemporal(),recuperaResLC($1),recuperaResLC($3));
						guardaResLC($$,oper.res);
						insertaLC($$,finalLC($$),oper);
						liberarRegistro(recuperaResLC($1));
						liberarRegistro(recuperaResLC($3));
						liberaLC($1);
						liberaLC($3);
					  }
	| expr MENOS expr {	$$ = creaLC();
						concatenaLC($$,$1);
						concatenaLC($$,$3);
						Operacion oper = crearOperacion("sub",getRegistroTemporal(),recuperaResLC($1),recuperaResLC($3));
						guardaResLC($$,oper.res);
						insertaLC($$,finalLC($$),oper);
						liberarRegistro(recuperaResLC($1));
						liberarRegistro(recuperaResLC($3));
						liberaLC($1);
						liberaLC($3);
					  }
	| expr POR expr	 {	$$ = creaLC();
						concatenaLC($$,$1);
						concatenaLC($$,$3);
						Operacion oper = crearOperacion("mul",getRegistroTemporal(),recuperaResLC($1),recuperaResLC($3));
						guardaResLC($$,oper.res);
						insertaLC($$,finalLC($$),oper);
						liberarRegistro(recuperaResLC($1));
						liberarRegistro(recuperaResLC($3));
						liberaLC($1);
						liberaLC($3);
					}
	| expr DIV expr	{	$$ = creaLC();
						concatenaLC($$,$1);
						concatenaLC($$,$3);
						Operacion oper = crearOperacion("div",getRegistroTemporal(),recuperaResLC($1),recuperaResLC($3));
						guardaResLC($$,oper.res);
						insertaLC($$,finalLC($$),oper);
						liberarRegistro(recuperaResLC($1));
						liberarRegistro(recuperaResLC($3));
						liberaLC($1);
						liberaLC($3);
					}
	| MENOS expr {	$$ = creaLC();
					concatenaLC($$,$2);
					Operacion oper = crearOperacion("neg",getRegistroTemporal(),recuperaResLC($2),NULL);
					guardaResLC($$,oper.res);
					insertaLC($$,finalLC($$),oper);
					liberarRegistro(recuperaResLC($2));
					liberaLC($2);
				 }
	| LPAR expr RPAR {$$ = $2;}
	| ID {	if (!perteneceTablaS(tablaSimb,$1)) {printf("ERROR SEMANTICO: Variable %s no declarada en la linea %d \n", $1, yylineno); errores_semanticos++;}
			else{
				Operacion oper = crearOperacion("lw",getRegistroTemporal(),ConcatenaStr("_",$1),NULL);
				$$ = creaLC();
				guardaResLC($$,oper.res);
				insertaLC($$,finalLC($$),oper);
			}
		 }
	| INTLIT {	Operacion oper = crearOperacion("li",getRegistroTemporal(),$1,NULL);
				$$ = creaLC();
				guardaResLC($$,oper.res);
				insertaLC($$,finalLC($$),oper);
			 }
	;
%%

void yyerror() {
	printf("ERROR SINTACTICO: error en la linea %d\n", yylineno);
	errores_sintacticos++;
}

char *obtenerEtiqueta() {
	char aux[32];
	sprintf(aux,"$l%d",contadorEtiquetas++);
	return strdup(aux);
}

char *ConcatenaStr(char *a, char *b) {
	char concatena[50] = "";
	strcat(concatena, a);
	strcat(concatena, b);
	return strdup(concatena);
}