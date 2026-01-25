%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_USERS 1000

typedef struct {
    int id;
    int logins;
    int adds;
    int checkouts;
    double total_spent;
} User;

User users[MAX_USERS];
int user_count = 0;
int current_user = 0;
int lexical_errors = 0;

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
    return NULL; // Should not happen
}

%}

TIMESTAMP   [0-9]{4}-[0-9]{2}-[0-9]{2}[ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}
INVALID_ID  USER=[^0-9][a-zA-Z0-9]*
ID      USER=[0-9]+
VALOR       [0-9]+(\.[0-9][0-9])?

%%

{TIMESTAMP} { }

{INVALID_ID} {
    current_user = 0;
    lexical_errors++;
}

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

TOTAL={VALOR} {
    double valor;
    sscanf(yytext, "TOTAL=%lf", &valor);
    if(current_user != 0) {
        User* u = find_or_add_user(current_user);
        if(u) u->total_spent += valor;
    }
}

ITEM=[a-zA-Z0-9_]+ { }

PRECO={VALOR} { }

\n      { }
[ \t]+  { }

. {
    if(*yytext != ' ' && *yytext != '\t' && *yytext != '\n') {
        lexical_errors++;
    }
}

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

    for(int i = 0; i < user_count; i++) {
        printf("UTILIZADOR %d\n", users[i].id);
        printf("   Logins: %d\n", users[i].logins);
        printf("   Produtos adicionados: %d\n", users[i].adds);
        printf("   Compras: %d\n", users[i].checkouts);
        printf("   Total gastos: %.2f\n", users[i].total_spent);
    }

    if(lexical_errors > 0) {
        // printf("Erros lexicos detectados: %d\n", lexical_errors);
    }

    return 0;
}
