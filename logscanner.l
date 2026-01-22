%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int total_logins = 0;
int total_add = 0;
int total_checkout = 0;

typedef struct {
    int id;
    double total;
} Checkout;

Checkout checkouts[100];
int checkout_count = 0;

int id_atual = 0;

%}

TIMESTAMP   [0-9]{4}-[0-9]{2}-[0-9]{2}[ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}
ID      USER=[0-9]+
VALOR       [0-9]+(\.[0-9][0-9])?

%%

{TIMESTAMP} { }

{ID} {
    sscanf(yytext, "USER=%d", &id_atual);
}

LOGIN {
    total_logins++;
}

ADD_TO_CART {
    total_add++;
}

CHECKOUT {
    total_checkout++;
}

TOTAL={VALOR} {
    double valor;
    sscanf(yytext, "TOTAL=%lf", &valor);
    checkouts[checkout_count].id = id_atual;
    checkouts[checkout_count].total = valor;
    checkout_count++;
}

ITEM=[a-zA-Z0-9_]+ { }

PRECO={VALOR} { }

\n      { }
[ \t]+  { }

. { }

%%

int main(int argc, char *argv[]) {

    if(argc < 2) {
        printf("Uso: %s ficheiro_log.txt\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if(!f) {
        perror("Erro ao abrir ficheiro");
        return 1;
    }

    yyin = f;
    yylex();
    fclose(f);

    printf("\n===== RESUMO (PARTE I) =====\n");
    printf("LOGINS: %d\n", total_logins);
    printf("ADD_TO_CART: %d\n", total_add);
    printf("CHECKOUT: %d\n", total_checkout);

    printf("\n===== LISTA DE CHECKOUTS =====\n");
    for(int i = 0; i < checkout_count; i++) {
        printf("Id: %d | Total: %.2f\n",
               checkouts[i].id, checkouts[i].total);
    }

    return 0;
}
