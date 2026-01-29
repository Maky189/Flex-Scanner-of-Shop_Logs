%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_USERS 1000

//Estrutura de Users

typedef struct {
    int id;
    int logins;
    int adds;
    int checkouts;
    double total_spent;
} User;


//Lista de Users
User users[MAX_USERS];
int user_count = 0;
int current_user = 0;
int lexical_errors = 0;
int linha = 1;

//Metodo de encontrar ou adicionar utilizador caso nao encontrado
User* find_or_add_user(int id) {
    for(int i = 0; i < user_count; i++) {
        if(users[i].id == id) {
            return &users[i];
        }
    }
    if(user_count < MAX_USERS) {
        users[user_count].id = id;
        users[user_count].logins = 0;
        users[user_count].adds = 0;
        users[user_count].checkouts = 0;
        users[user_count].total_spent = 0.0;
        return &users[user_count++];
    }
    return NULL;
}
%}

 //Expressoes regulares
TIMESTAMP   [0-9]{4}-[0-9]{2}-[0-9]{2}[ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}
ID          USER=[0-9]+
INVALID_ID  USER=[^0-9][a-zA-Z0-9]*
VALOR       [0-9]+(\.[0-9][0-9])?

%%

 //Tabela de simbolos, realiza contagens dos simbolos
{TIMESTAMP} { }

{ID} {
    sscanf(yytext, "USER=%d", &current_user);
}

LOGIN {
    if(current_user != 0) {
        User* u = find_or_add_user(current_user);
        if(u) u->logins++;
    }
}

ADD_TO_CART {
    if(current_user != 0) {
        User* u = find_or_add_user(current_user);
        if(u) u->adds++;
    }
}

CHECKOUT {
    if(current_user != 0) {
        User* u = find_or_add_user(current_user);
        if(u) u->checkouts++;
    }
}

ITEM=[a-zA-Z0-9_]+ { }

PRECO={VALOR} { }

TOTAL={VALOR} {
    double valor;
    sscanf(yytext, "TOTAL=%lf", &valor);
    if(current_user != 0) {
        User* u = find_or_add_user(current_user);
        if(u) u->total_spent += valor;
    }
}

{INVALID_ID} {
    printf("Erro lexico (linha %d): USER invalido -> %s\n", linha, yytext);
    lexical_errors++;
    current_user = 0;
}

(LOGON|BUY|PAY) {
    printf("Erro lexico (linha %d): acao invalida -> %s\n", linha, yytext);
    lexical_errors++;
}

PRECO=[^ \n]+ {
    printf("Erro lexico (linha %d): PRECO invalido -> %s\n", linha, yytext);
    lexical_errors++;
}

TOTAL=[^ \n]+ {
    printf("Erro lexico (linha %d): TOTAL invalido -> %s\n", linha, yytext);
    lexical_errors++;
}

[0-9]{4}-[^ ]+ {
    printf("Erro lexico (linha %d): Timestamp malformado -> %s\n", linha, yytext);
    lexical_errors++;
}

[A-Z]+=[^ \n]+ {
    printf("Erro lexico (linha %d): Campo invalido -> %s\n", linha, yytext);
    lexical_errors++;
}

\n      { linha++; }
[ \t]+  { }

. {
    printf("Erro lexico (linha %d): simbolo invalido -> %s\n", linha, yytext);
    lexical_errors++;
}

%%

int yywrap() {
    return 1;
}

int main(int argc, char *argv[]) {

    if(argc < 2) {
        printf("Uso: %s ficheiro_log.txt\n", argv[0]);
        return 1;
    }

    //Carregar o ficheiro
    FILE *f = fopen(argv[1], "r");
    if(!f) {
        perror("Erro ao abrir ficheiro");
        return 1;
    }
    
    //Inicia o processo e procura por erros lexicos
    yyin = f;
    yylex();
    fclose(f);

    printf("\nTotal de erros léxicos: %d\n", lexical_errors);

    return 0;
}
