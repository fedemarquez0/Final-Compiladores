#include "listaSimbolos.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

struct PosicionListaRep {
  Simbolo dato;
  struct PosicionListaRep *sig;
};

struct ListaRep {
  PosicionLista cabecera;
  PosicionLista ultimo;
  int n;
};

typedef struct PosicionListaRep *NodoPtr;

Lista creaLS() {
  Lista nueva = malloc(sizeof(struct ListaRep));
  nueva->cabecera = malloc(sizeof(struct PosicionListaRep));
  nueva->cabecera->sig = NULL;
  nueva->ultimo = nueva->cabecera;
  nueva->n = 0;
  return nueva;
}

void liberaLS(Lista lista) {
  while (lista->cabecera != NULL) {
    NodoPtr borrar = lista->cabecera;
    lista->cabecera = borrar->sig;
    free(borrar);
  }
  free(lista);
}

void insertaLS(Lista lista, PosicionLista p, Simbolo s) {
  NodoPtr nuevo = malloc(sizeof(struct PosicionListaRep));
  nuevo->dato = s;
  nuevo->sig = p->sig;
  p->sig = nuevo;
  if (lista->ultimo == p) {
    lista->ultimo = nuevo;
  }
  (lista->n)++;
}

void suprimeLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  NodoPtr borrar = p->sig;
  p->sig = borrar->sig;
  if (lista->ultimo == borrar) {
    lista->ultimo = p;
  }
  free(borrar);
  (lista->n)--;
}

Simbolo recuperaLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig->dato;
}

PosicionLista buscaLS(Lista lista, char *nombre) {
  NodoPtr aux = lista->cabecera;
  while (aux->sig != NULL && strcmp(aux->sig->dato.nombre,nombre) != 0) {
    aux = aux->sig;
  }
  return aux;
}

void asignaLS(Lista lista, PosicionLista p, Simbolo s) {
  assert(p != lista->ultimo);
  p->sig->dato = s;
}

int longitudLS(Lista lista) {
  return lista->n;
}

PosicionLista inicioLS(Lista lista) {
  return lista->cabecera;
}

PosicionLista finalLS(Lista lista) {
  return lista->ultimo;
}

PosicionLista siguienteLS(Lista lista, PosicionLista p) {
  assert(p != lista->ultimo);
  return p->sig;
}

void anadeEntrada(Lista tablaSimb, char *nombre, Tipo tipo, int valor){
  Simbolo aux;
  aux.nombre = nombre;
  aux.tipo = tipo;
  aux.valor = valor;

  insertaLS(tablaSimb, finalLS(tablaSimb), aux);
  return;
}

void imprimirTablaS(Lista l){
  printf("##################\n");
  printf("# Seccion de datos\n");
  printf("  .data\n");
  PosicionLista p = inicioLS(l);
  /* Primero imprimimos las cadenas */
  while (p != finalLS(l)) {
    Simbolo aux = recuperaLS(l,p);
    if(aux.tipo == CADENA){
      printf("$str%d:\n",aux.valor);
      printf("  .asciiz %s\n",aux.nombre);
    }
    p = siguienteLS(l,p);
  }
  /* Despues imprimimos las variables */
  p = inicioLS(l);
  while (p != finalLS(l)) {
    Simbolo aux = recuperaLS(l,p);
    if(aux.tipo != CADENA){
      printf("_%s:\n",aux.nombre);
      printf("  .word %d\n",aux.valor);
    }
    p = siguienteLS(l,p);
  }
  printf("\n");
}

bool perteneceTablaS(Lista l, char *nombre){
  PosicionLista p = buscaLS(l,nombre);
  if (p != finalLS(l)) {
    return true;
  }
  return false;
}

bool esConstante(Lista l, char *nombre){
  PosicionLista p = buscaLS(l,nombre);
  if (p != finalLS(l)) {
    Simbolo aux = recuperaLS(l,p);
    if(aux.tipo == CONSTANTE){
      return true;
    }
  }
  return false;
}

void guardarArchivoTS(Lista l){
    FILE *f = fopen ("MiPrograma.s","wb");
    if(f==NULL) {printf("Error de apertura en el archivo"); exit(1);}
    else{
        //meter las cosas en el archivo
        fprintf(f,"##################\n");
        fprintf(f,"# Seccion de datos\n");
        fprintf(f,"  .data\n");
        PosicionLista p = inicioLS(l);
        while (p != finalLS(l)) {
            Simbolo aux = recuperaLS(l,p);
            if(aux.tipo == CADENA){
            fprintf(f,"$str%d:\n",aux.valor);
            fprintf(f,"  .asciiz %s\n",aux.nombre);
            }
            p = siguienteLS(l,p);
        }
        p = inicioLS(l);
        while (p != finalLS(l)) {
            Simbolo aux = recuperaLS(l,p);
            if(aux.tipo != CADENA){
            fprintf(f,"_%s:\n",aux.nombre);
            fprintf(f,"  .word %d\n",aux.valor);
            }
            p = siguienteLS(l,p);
        }
        fprintf(f,"\n");
        fclose(f);
    }
}