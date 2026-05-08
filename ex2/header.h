#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<malloc.h>

typedef struct listelem{  // 存储需要回填的指令编号
    int instrno;
    struct listelem *next;
}listelem;

listelem *new_listelem(int no)
{
    listelem *elem = (listelem *)malloc(sizeof(listelem));
    elem->instrno = no;
    elem->next = NULL;
    return elem;
}

typedef struct instrlist{  // 存储整个指令列表
    listelem *head, *tail;
}instrlist;

instrlist *new_instrlist(int instrno)
{
    instrlist *list = (instrlist *)malloc(sizeof(instrlist));
    list->head = list->tail = new_listelem(instrno);
    return list;
}

instrlist *merge(instrlist *list1, instrlist *list2)
{
    if(list1 == NULL) return list2;
    if(list2 == NULL) return list1;
    list1->tail->next = list2->head;
    list1->tail = list2->tail;
    free(list2);
    return list1;
}

typedef struct node{
    instrlist *truelist, *falselist, *nextlist;
    char addr[256];
    char lexeme[256];
    char oper[3];
    int instr;
}node;

void filloperator(node *n, char *op) { strcpy(n->oper, op);}

void filllexeme(node *n, char *yytext) { strcpy(n->lexeme, yytext);}

void copyaddr(node *n, char *src) { strcpy(n->addr, src); }

void new_temp(node *n, int index) { sprintf(n->addr, "T%d", index); }

void copyaddr_fromnode(node *dest, node src) { strcpy(dest->addr, src.addr); }

typedef struct codelist{  // 中间代码的列表
    int linecnt, capacity;
    int temp_index;
    char **code;
}codelist;

codelist *new_codelist()
{
    codelist *list = (codelist *)malloc(sizeof(codelist));
    list->linecnt = 1;
    list->capacity = 1024;
    list->temp_index = 1;
    list->code = (char **)malloc(list->capacity * sizeof(char *));
    return list;
}

// 返回临时变量的索引
int get_temp_index(codelist *list) { return list->temp_index++; }

// 返回下一条指令的编号
int nextinstr(codelist *list) { return list->linecnt; }

void gen(codelist *list, char *str)
{
    if(list->linecnt >= list->capacity) {
        list->capacity += 1024;
        list->code = (char **)realloc(list->code, list->capacity * sizeof(char *));
    }
    list->code[list->linecnt] = (char *)malloc(strlen(str) + 20);
    strcpy(list->code[list->linecnt], str);
    list->linecnt++;
}

void gen_goto_blank(codelist *list)
{
    char tmp[1024];
    sprintf(tmp, "( j, -, -,");
    gen(list, tmp);
}

void gen_goto(codelist *list, int instrno)
{
    char tmp[1024];
    sprintf(tmp, "( j, -, -, %d)", instrno);
    gen(list, tmp);
}

void gen_if(codelist *list, node left, char *op, node right)
{
    char tmp[1024];
    sprintf(tmp, "(j%s, %s, %s,", op, left.addr, right.addr);
    gen(list, tmp);
}

void gen_1addr(codelist *list, node left, char *op) // 生成单地址中间代码
{
    char tmp[1024];
    sprintf(tmp, "(j%s, %s, -, %s)", op, left.addr);
    gen(list, tmp);
}

void gen_2addr(codelist *list, node left, char *op, node right)  // 生成二地址中间代码
{
    char tmp[1024];
    sprintf(tmp, "(%s, %s, -, %s)", op, right.addr, left.addr);
    gen(list, tmp);
}

void gen_3addr(codelist *list, node left, node op1, char *op, node op2)
{
    char tmp[1024];
    sprintf(tmp, "(%s, %s, %s, %s)", op, op1.addr, op2.addr, left.addr);
    gen(list, tmp);
}

void gen_assign(codelist *list, node left, node right) { gen_2addr(list, left, ":=", right); }

void backpatch(codelist *dst, instrlist *list, int instrno)
{
    if (!list) return;
    listelem *p = list->head;
    char tmp[20];
    sprintf(tmp, "%d)", instrno);
    while (p)
    {
        if (p->instrno < dst->linecnt) strcat(dst->code[p->instrno], tmp);
        p = p->next;
    }
}

void print(codelist *list, char *program_name)
{
    int i;
    printf("(0)\t(program,%s,-,-)\n", program_name);
    for (i = 1; i < list->linecnt; ++i)
    {
        if (!strcmp(list->code[i], "( j, -, -,")) printf("(%d)\t( j, -, -, %d)\n", i, list->linecnt);
        else printf("(%d)\t%s\n", i, list->code[i]);
    }
    printf("(%d)\t%s\n", i, "(sys, -, -, -)");
}