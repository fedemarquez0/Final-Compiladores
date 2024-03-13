#include "listaCodigo.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <assert.h>

/*
TODO:
array de registros t
instrucciones

*/

int registroTemporales[10] = {0};


struct PosicionListaCRep {
  Operacion dato;
  struct PosicionListaCRep *sig;
};

struct ListaCRep {
  PosicionListaC cabecera;
  PosicionListaC ultimo;
  int n;
  char *res;
};

typedef struct PosicionListaCRep *NodoPtr;

char * getRegistroTemporal() {
  for (int i = 0; i < 10; i++) {
    if (registroTemporales[i] == 0) {
      registroTemporales[i] = 1;
      char ret[14];
      sprintf(ret, "$t%d", i);
      return strdup(ret);
    }
  }
  printf("ERROR INTERNO: no hay registro temporales.\n");
  exit(1);
}

void liberarRegistro(char * reg) {
  int i = atoi(reg + 2);
  registroTemporales[i] = 0;
}

ListaC creaLC() {
  ListaC nueva = malloc(sizeof(struct ListaCRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaCRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  nueva->res = NULL;
  return nueva;
}

void liberaLC(ListaC codigo) {
  while (codigo->cabecera != NULL) {
    NodoPtr borrar = codigo->cabecera;
    codigo->cabecera = borrar->sig;
    free(borrar);
  }
  free(codigo);
}

void insertaLC(ListaC codigo, PosicionListaC p, Operacion o) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaCRep));
  nuevo->dato = o;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (codigo->ultimo == p) {
    codigo->ultimo = nuevo;
  }
  (codigo->n)++;
}

Operacion recuperaLC(ListaC codigo, PosicionListaC p) {
  assert(p != codigo->ultimo);
  return p->sig->dato;
}

PosicionListaC buscaLC(ListaC codigo, PosicionListaC p, char *clave, Campo campo) {
  NodoPtr aux = p;
  char *info;
  while (aux->sig != NULL) {
    switch (campo) {
      case OPERACION: 
        info = aux->sig->dato.op;
        break;
      case ARGUMENTO1:
        info = aux->sig->dato.arg1;
        break;
      case ARGUMENTO2:
        info = aux->sig->dato.arg2;
        break;
      case RESULTADO:
        info = aux->sig->dato.res;
        break;
    }
    if (info != NULL && !strcmp(info,clave)) break;
	  aux = aux->sig;
  }
  return aux;
}

void asignaLC(ListaC codigo, PosicionListaC p, Operacion o) {
  assert(p != codigo->ultimo);
  p->sig->dato = o;
}

int longitudLC(ListaC codigo) {
  return codigo->n;
}

PosicionListaC inicioLC(ListaC codigo) {
  return codigo->cabecera;
}

PosicionListaC finalLC(ListaC codigo) {
  return codigo->ultimo;
}

void concatenaLC(ListaC codigo1, ListaC codigo2) {
  NodoPtr aux = codigo2->cabecera;
  while (aux->sig != NULL) {
    insertaLC(codigo1,finalLC(codigo1),aux->sig->dato);
    aux = aux->sig;
  }
}

PosicionListaC siguienteLC(ListaC codigo, PosicionListaC p) {
  assert(p != codigo->ultimo);
  return p->sig;
}

void guardaResLC(ListaC codigo, char *res) {
  codigo->res = res;
}

/* Recupera el registro resultado de una lista de codigo */
char * recuperaResLC(ListaC codigo) {
  return codigo->res;
}

Operacion crearOperacion(char * op, char * res, char * arg1, char * arg2){
    Operacion oper;
    oper.op = op;
    oper.res = res;
    oper.arg1 = arg1;
    oper.arg2 = arg2;
    return oper;
}

void LCimprimir(ListaC codigo) {
    printf("##################\n");
    printf("# Seccion de codigo\n");
    printf("  .text\n");
    printf("  .globl main\n");
    printf("main:\n");
    Operacion oper;
    PosicionListaC p = inicioLC(codigo);
    while (p != finalLC(codigo)) {
        oper = recuperaLC(codigo,p);
        printf("  %s",oper.op);
        if (oper.res) printf(" %s",oper.res);
        if (oper.arg1) printf(", %s",oper.arg1);
        if (oper.arg2) printf(", %s",oper.arg2);
        printf("\n");
        p = siguienteLC(codigo,p);
    }
  printf("\n");
}

void guardarArchivoLC(ListaC codigo) {
    FILE *f = fopen ("MiPrograma.s","ab");
    if(f==NULL) {printf("Error de apertura en el archivo"); exit(1);}
    else{
        fprintf(f,"##################\n");
        fprintf(f,"# Seccion de codigo\n");
        fprintf(f,"  .text\n");
        fprintf(f,"  .globl main\n");
        fprintf(f,"main:\n");
        Operacion oper;
        PosicionListaC p = inicioLC(codigo);
        while (p != finalLC(codigo)) {
            oper = recuperaLC(codigo,p);
            fprintf(f,"  %s",oper.op);
            if (oper.res) fprintf(f," %s",oper.res);
            if (oper.arg1) fprintf(f,", %s",oper.arg1);
            if (oper.arg2) fprintf(f,", %s",oper.arg2);
            fprintf(f,"\n");
            p = siguienteLC(codigo,p);
        }
        fprintf(f,"\n");
        fprintf(f,"##############\n");
        fprintf(f,"# Fin\n");
        fprintf(f,"  li $v0, 10\n");
        fprintf(f,"  syscall\n");
        fclose(f);
    }
}