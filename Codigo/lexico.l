%{
#include "sintactico.tab.h"
#include <string.h>
#include <stdbool.h>
bool maxnumero();
int errores_lexicos = 0;
%}
digito	[0-9]
letra	[a-zA-Z]
entero	{digito}+
%option yylineno
%%
"/*"([^*]|[*]+[^*/])*[*]+"/"            ;
"/*"([^*]|[*]+[^*/])*[*]*               {printf("ERROR LEXICO: comentario no acabado en la linea: %d\n", yylineno); errores_lexicos++;}
"//".*\n                                ;
[ \n\t\r]+                              ;
void					                return VOID;
var					                    return VAR;
const					                return CONST;
if					                    return IF;
else					                return ELSE;
while					                return WHILE;
print					                return PRINT;
read					                return READ;
{letra}({letra}|{digito}|_){0,15}	    {yylval.string=strdup(yytext);return ID;}	
{letra}({letra}|{digito}|_){16,}	    {printf("ERROR LEXICO: id demasiado largo en la linea %d: %s\n", yylineno, yytext); errores_lexicos++;}
{entero}				                {yylval.string=strdup(yytext); if (maxnumero()) return INTLIT;}
";"					                    return SEMICOLON;
","					                    return COMA;
"+"					                    return SUMA;
"-"					                    return MENOS;
"*"					                    return POR;
"/"					                    return DIV;
"="					                    return EQ;
"("					                    return LPAR;
")"					                    return RPAR;
"{"					                    return LLLA;
"}"					                    return RLLA;
\"([^\"\n]|\\.)*\"				        {yylval.string=strdup(yytext);return STR;}
[^[:alnum:]()/\*\\{};,+="_\- \n\t\r]*	{printf("ERROR LEXICO: caracteres no alidos en la linea %d: %s\n", yylineno, yytext); errores_lexicos++;}
%%
bool maxnumero() {
    if (atoll(yytext) > 2147483648) {
        printf("ERROR LEXICO: entero fuera de rango en la linea %d: %s\n", yylineno, yytext);
        errores_lexicos ++;
        return false;
    }
    return true;
}
