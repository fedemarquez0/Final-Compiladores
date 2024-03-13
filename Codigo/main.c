#include <stdio.h>
#include <stdlib.h>

extern char *yytext;
extern int  yyleng;
extern FILE *yyin;
extern int yyparse();
extern int errores_lexicos;
extern int errores_sintacticos;
extern int errores_semanticos;
FILE *fich;
int main(int argc, char *argv[]) {
	if (argc != 2) {
		printf("Uso correcto: %s fichero\n",argv[0]);
		exit(1);
	}
	FILE *fich = fopen(argv[1],"r");
	if (fich == 0) {
		printf("No se puede abrir %s\n",argv[1]);
		exit(1);
	}
	yyin = fich;
	yyparse();
	fclose(fich);
	if(errores_lexicos != 0 || errores_sintacticos != 0 || errores_semanticos != 0){
		printf("\nCANTIDAD DE ERRORES:\n");
		printf("  - Errores lexicos: %d \n",errores_lexicos);
		printf("  - Errores sintacticos: %d \n",errores_sintacticos);
		printf("  - Errores semanticos: %d \n",errores_semanticos);
	}
	else{
		printf("Compilacion realizada con exito.\n");
	}
}
