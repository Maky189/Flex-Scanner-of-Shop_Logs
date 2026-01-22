%{
/*
 * ===============================================================
 *  Projeto: Análise Léxica com Flex para Processamento de Logs
 *  Autores: Kelly Fortes, Marcos Gomes, Aulindo Correia
 *
 *  Objetivo (o que este scanner faz atualmente):
 *   - Lê um ficheiro de log e reconhece padrões básicos:
 *     TIMESTAMP, USER, ACTION, ITEM, PRECO, TOTAL
 *   - Conta quantas vezes aparecem: LOGIN, ADD_TO_CART, CHECKOUT
 *   - Guarda numa lista os CHECKOUTS (USER atual + TOTAL encontrado)
 *   - No fim imprime um resumo e a lista dos checkouts
 *
 * ================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Contadores globais (Parte I): */
int total_logins = 0;
int total_add = 0;
int total_checkout = 0;

/*
 * Estrutura para guardar cada checkout encontrado.
 * - id: o utilizador associado (capturado pela regra USER=...)
 * - total: valor do TOTAL=... capturado depois
 */
typedef struct {
    int id;
    double total;
} Checkout;

/* Array fixo para armazenar até 100 checkouts (podes aumentar depois). */
Checkout checkouts[100];
int checkout_count = 0;

/*
 * Guarda o "USER atual" lido mais recentemente.
 * Ideia: quando aparece TOTAL=, associamos ao id_atual.
 */
int id_atual = 0;

%}

/* =========================
   DEFINIÇÕES (MACROS REGEX)
 */

/*
 * TIMESTAMP:
 * Reconhece datas no formato:
 *  YYYY-MM-DD HH:MM:SS
 * Nota: isto reconhece apenas o "formato"
 */
TIMESTAMP   [0-9]{4}-[0-9]{2}-[0-9]{2}[ ]+[0-9]{2}:[0-9]{2}:[0-9]{2}

/*
 * ID:
 * Reconhece o identificador do utilizador no formato:
 *  USER=123
 */
ID      USER=[0-9]+

/*
 * VALOR:
 * Reconhece valores monetários simples no formato:
 *  10
 *  10.50
 * Nota: aceita "10.5"? -> não, porque exige 2 casas decimais se tiver ponto.
 */
VALOR       [0-9]+(\.[0-9][0-9])?

%%

/* =========================
   REGRAS (o coração do Flex)
 */

/*
 * {TIMESTAMP} { }
 * Quando encontra um timestamp, ele simplesmente IGNORA.
 * (Não incrementa contador, não guarda, não valida.)
 */
{TIMESTAMP} { }

/*
 * {ID} { ... }
 * Quando encontra "USER=numero", extrai o número e guarda em id_atual.
 * Isso permite que, mais tarde, quando aparecer "TOTAL=...", saibamos
 * qual utilizador estava associado (assume que o USER vem antes do TOTAL).
 */
{ID} {
    sscanf(yytext, "USER=%d", &id_atual);
}

/*
 * LOGIN { ... }
 * Sempre que aparece a palavra LOGIN no texto, incrementa o contador.
 * (Mesmo que esteja em lugar errado — porque a regra não exige contexto.)
 */
LOGIN {
    total_logins++;
}

/*
 * ADD_TO_CART { ... }
 * Sempre que aparece ADD_TO_CART no texto, incrementa o contador.
 */
ADD_TO_CART {
    total_add++;
}

/*
 * CHECKOUT { ... }
 * Sempre que aparece CHECKOUT no texto, incrementa o contador.
 */
CHECKOUT {
    total_checkout++;
}

/*
 * TOTAL={VALOR} { ... }
 * Regra importante:
 * - Quando aparece TOTAL=xx.xx (ou TOTAL=xx), extrai o valor numérico
 * - Guarda um registo de checkout (id_atual + valor) no array checkouts[]
 * - Incrementa checkout_count
 */

TOTAL={VALOR} {
    double valor;
    sscanf(yytext, "TOTAL=%lf", &valor);

    checkouts[checkout_count].id = id_atual;
    checkouts[checkout_count].total = valor;
    checkout_count++;
}

/*
 * ITEM
 * Reconhece itens do tipo:
 *  ITEM=Mouse
 *  ITEM=Produto_12
 * e ignora (não guarda nem conta).
 */
ITEM=[a-zA-Z0-9_]+ { }

/*
 * PRECO={VALOR} { }
 * Reconhece PRECO=xx.xx e ignora (não guarda nem conta).
 */
PRECO={VALOR} { }

/*
 * \n { }
 * Ignora quebras de linha.
 * (Aqui seria um bom lugar para contar linhas / validar formato por linha.)
 */
\n      { }

/*
 * [ \t]+ { }
 * Ignora espaços e tabulações.
 */
[ \t]+  { }

/*
 * . { }
 * Coringa: qualquer caractere não reconhecido por regras anteriores.
 * Aqui está sendo ignorado silenciosamente.
 * (Na Parte II, isto poderia gerar "erro léxico".)
 */
. { }

%%


int main(int argc, char *argv[]) {

    /*
     * Verifica se foi passado o ficheiro na linha de comando:
     * Ex: ./logscanner ficheiro_log.txt
     */
    if(argc < 2) {
        printf("Uso: %s ficheiro_log.txt\n", argv[0]);
        return 1;
    }

    /*
     * Abre o ficheiro de entrada e atribui ao yyin (input do Flex).
     */
    FILE *f = fopen(argv[1], "r");
    if(!f) {
        perror("Erro ao abrir ficheiro");
        return 1;
    }

    /*
     * yyin é uma variável global do Flex.
     * yylex() começa a varrer o ficheiro aplicando as regras acima.
     */
    yyin = f;
    yylex();
    fclose(f);

    /*
     * Depois do yylex terminar (EOF), imprime os resultados da Parte I.
     */
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
