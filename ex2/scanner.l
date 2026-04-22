%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int line_num = 1;
%}

letter      [A-Za-z]
digit       [0-9]
identifier  {letter}({letter}|{digit})*
integer     {digit}+
string      '([^'\n]|'')*'

%%

[ \t\r\a]+     ; // 空白字符
\n             { line_num++; } // 记录行号

"/*"([^*]|\*+[^*/])*\*+"/" ; // 匹配多行注释，直接跳过不返回Token

and        return 1;
array      return 2;
begin      return 3;
bool       return 4;
call       return 5;
case       return 6;
char       return 7;
constant   return 8;
dim        return 9;
do         return 10;
else       return 11;
end        return 12;
false      return 13;
for        return 14;
if         return 15;
input      return 16;
integer    return 17;
not        return 18;
of         return 19;
or         return 20;
output     return 21;
procedure  return 22;
program    return 23;
read       return 24;
real       return 25;
repeat     return 26;
set        return 27;
stop       return 28;
then       return 29;
to         return 30;
true       return 31;
until      return 32;
var        return 33;
while      return 34;
write      return 35;

{identifier}   return 36; // 标识符
{integer}      return 37; // 整数常量
{string}       return 38; // 字符串常量

":="       return 51;
".."       return 47;
"<="       return 54;
"<>"       return 55;
">="       return 58;

"("        return 39;
")"        return 40;
"*"        return 41;
"+"        return 43;
","        return 44;
"-"        return 45;
"."        return 46;
"/"        return 48;
":"        return 50;
";"        return 52;
"<"        return 53;
"="        return 56;
">"        return 57;
"["        return 59;
"]"        return 60;

"/*"([^*]|\*+[^*/])* { printf("Error: line %d annotation missing */\n", line_num); }
'[^'\n]*           { printf("Error: line %d string missing quotation marks\n", line_num); }
.                  { printf("Error: line %d illegal character %s\n", line_num, yytext); }

%%

#define T_AND 1
#define T_ARRAY 2
#define T_BEGIN 3
#define T_BOOL 4
#define T_CALL 5
#define T_CASE 6
#define T_CHAR 7
#define T_CONSTANT 8
#define T_DIM 9
#define T_DO 10
#define T_ELSE 11
#define T_END 12
#define T_FALSE 13
#define T_FOR 14
#define T_IF 15
#define T_INPUT 16
#define T_INTEGER 17
#define T_NOT 18
#define T_OF 19
#define T_OR 20
#define T_OUTPUT 21
#define T_PROCEDURE 22
#define T_PROGRAM 23
#define T_READ 24
#define T_REAL 25
#define T_REPEAT 26
#define T_SET 27
#define T_STOP 28
#define T_THEN 29
#define T_TO 30
#define T_TRUE 31
#define T_UNTIL 32
#define T_VAR 33
#define T_WHILE 34
#define T_WRITE 35

// 标识符与常数
#define T_ID 36
#define T_INT_CONST 37
#define T_CHAR_CONST 38

// 运算符与界符
#define T_LPAREN 39
#define T_RPAREN 40
#define T_MUL 41
#define T_ADD 43
#define T_COMMA 44
#define T_SUB 45
#define T_DOT 46
#define T_DOTDOT 47
#define T_DIV 48
#define T_COLON 50
#define T_ASSIGN 51
#define T_SEMICOLON 52
#define T_LT 53
#define T_LE 54
#define T_NE 55
#define T_EQ 56
#define T_GT 57
#define T_GE 58
#define T_LBRACKET 59
#define T_RBRACKET 60

void parse_program();
void parse_var_decl();
void parse_id_list();
void parse_compound_stmt();
void parse_statement();
void parse_assign();
void parse_if();
void parse_while();
void parse_repeat();
void parse_bool_expression();
void parse_bool_term();
void parse_bool_factor();
void parse_rel_expression();
char* parse_expr();
char* parse_term();
char* parse_factor();

int lookahead; // 存储当前token的种别码
int next_quad = 0; // 下条指令的下标

typedef struct {
    char op[10], arg1[20], arg2[20], res[20];
} Quaternion;

Quaternion codes[500];

// 用于存储需要回填的跳转指令位置
typedef struct {
    int addrs[50];  // 存储需要回填的四元式下标
    int count;      // 数量
} JumpList;

JumpList true_list;   // 为真时的跳转列表
JumpList false_list;  // 为假时的跳转列表

void init_list(JumpList* list) {
    list->count = 0;
}

void add_to_list(JumpList* list, int addr) {
    list->addrs[list->count++] = addr;
}

void merge_list(JumpList* target, JumpList* src) {
    for (int i = 0; i < src->count; i++) {
        target->addrs[target->count++] = src->addrs[i];
    }
}

void backpatch_list(JumpList* list, int target_addr) {
    char target_str[10];
    sprintf(target_str, "%d", target_addr);
    for (int i = 0; i < list->count; i++) {
        strcpy(codes[list->addrs[i]].res, target_str);
    }
}

void emit(char* op, char* arg1, char* arg2, char* res)
{
    strcpy(codes[next_quad].op, op);
    strcpy(codes[next_quad].arg1, arg1);
    strcpy(codes[next_quad].arg2, arg2);
    strcpy(codes[next_quad].res, res);
    next_quad++;
}

void backpatch(int quad_index, int target_line)
{
    sprintf(codes[quad_index].res, "%d", target_line);
}

int temp_no = 1;

char* new_temp()
{
    char* t = (char*)malloc(10);
    sprintf(t, "T%d", temp_no++);
    return t;
}

void match(int expected)
{
    if (lookahead == expected) 
        lookahead = yylex(); // 匹配成功, 读下一个单词
    else
    {
        printf("Grammar error, expecting %d, got %d\n", expected, lookahead);
        exit(1);
    }
}

void parse_id_list()
{
    match(T_ID);
    while (lookahead == T_COMMA) {
        match(T_COMMA);
        match(T_ID);
    }
}

void parse_var_decl() 
{
    if (lookahead == T_VAR) {
        match(T_VAR);
        while (lookahead == T_ID) {
            parse_id_list();
            match(T_COLON);
            if (lookahead == T_INTEGER || lookahead == T_BOOL || lookahead == T_CHAR) 
                match(lookahead);
            match(T_SEMICOLON);
        }
    }
}

void parse_compound_stmt() 
{
    match(T_BEGIN);
    while (lookahead != T_END) {
        parse_statement();
        if (lookahead == T_SEMICOLON) 
            match(T_SEMICOLON);
    }
    match(T_END);
}

char* parse_factor()
{
    char* result = (char*)malloc(20);
    if (lookahead == T_ID || lookahead == T_INT_CONST || lookahead == T_CHAR_CONST)
    {
        strcpy(result, yytext);
        match(lookahead);
    }
    else if (lookahead == T_LPAREN)
    {
        match(T_LPAREN);
        result = parse_expr();
        match(T_RPAREN);
    }
    return result;
}

char* parse_term()
{
    char* left = parse_factor();
    while (lookahead == T_MUL || lookahead == T_DIV)
    {
        int op_type = lookahead;
        match(lookahead);
        char* right = parse_factor();
        char* target = new_temp();
        if (op_type == T_MUL) 
            emit("*", left, right, target);
        else 
            emit("/", left, right, target);
        left = target;
    }
    return left;
}

char* parse_expr()
{
    char* left = parse_term();
    while (lookahead == T_ADD || lookahead == T_SUB)
    {
        int op_type = lookahead;
        match(lookahead);
        char* right = parse_term();
        char* target = new_temp();
        if (op_type == T_ADD) 
            emit("+", left, right, target);
        else 
            emit("-", left, right, target);
        left = target;
    }
    return left;
}

void parse_rel_expression()
{
    char* arg1 = parse_expr();
    char op[10];
    
    if (lookahead == T_LT) strcpy(op, "j<");
    else if (lookahead == T_GT) strcpy(op, "j>");
    else if (lookahead == T_LE) strcpy(op, "j<=");
    else if (lookahead == T_GE) strcpy(op, "j>=");
    else if (lookahead == T_EQ) strcpy(op, "j=");
    else if (lookahead == T_NE) strcpy(op, "j<>");
    else {
        printf("Error: expecting relational operator\n");
        exit(1);
    }
    
    match(lookahead);
    char* arg2 = parse_expr();

    // 生成条件跳转指令
    emit(op, arg1, arg2, "0");
    add_to_list(&true_list, next_quad - 1);  // 记录需要回填的真出口
    
    // 生成无条件跳转（假出口）
    emit("j", "-", "-", "0");
    add_to_list(&false_list, next_quad - 1); // 记录需要回填的假出口
}

void parse_bool_factor()
{
    if (lookahead == T_NOT) {
        match(T_NOT);
        JumpList saved_true = true_list;
        JumpList saved_false = false_list;
        init_list(&true_list);
        init_list(&false_list);
        
        parse_bool_factor();  // 继续读 not 后面的内容
        
        // 交换真假出口
        JumpList temp = true_list;
        true_list = false_list;
        false_list = temp;
        
        merge_list(&true_list, &saved_true);
        merge_list(&false_list, &saved_false);
    }
    else if (lookahead == T_LPAREN) {
        match(T_LPAREN);
        parse_bool_expression();
        match(T_RPAREN);
    }
    else parse_rel_expression();
}

void parse_bool_term()
{
    parse_bool_factor();
    
    while (lookahead == T_AND) {
        match(T_AND);
        
        // 回填B1的真出口到当前位置（短路求值）
        backpatch_list(&true_list, next_quad);
        
        JumpList saved_false = false_list;
        init_list(&true_list);
        init_list(&false_list);
        
        parse_bool_factor();
        
        // 合并假出口
        merge_list(&false_list, &saved_false);
    }
}

void parse_bool_expression()
{
    parse_bool_term();
    
    while (lookahead == T_OR) {
        match(T_OR);
        
        // 回填B1的假出口到当前位置（短路求值）
        backpatch_list(&false_list, next_quad);
        
        JumpList saved_true = true_list;
        init_list(&true_list);
        init_list(&false_list);
        
        parse_bool_term();
        
        // 合并真出口
        merge_list(&true_list, &saved_true);
    }
}

void parse_statement()
{
    if (lookahead == T_WHILE) parse_while();
    else if (lookahead == T_IF) parse_if();
    else if (lookahead == T_ID) parse_assign();
    else if (lookahead == T_BEGIN) parse_compound_stmt();
    else if (lookahead == T_REPEAT) parse_repeat();
}

void parse_assign()
{
    char target_name[20];
    strcpy(target_name, yytext); 
    match(T_ID);
    match(T_ASSIGN);
    char* expr_result = parse_expr();
    emit(":=", expr_result, "-", target_name);
}

void parse_while()
{
    int start_line = next_quad;
    match(T_WHILE);
    
    init_list(&true_list);
    init_list(&false_list);
    parse_bool_expression();
    
    match(T_DO);
    
    // 回填真出口到循环体开始
    backpatch_list(&true_list, next_quad);
    
    parse_statement();
    
    // 跳回循环开始
    char start_str[10];
    sprintf(start_str, "%d", start_line);
    emit("j", "-", "-", start_str);
    
    // 回填假出口到循环后
    backpatch_list(&false_list, next_quad);
}

void parse_repeat()
{
	match(T_REPEAT);
	int start_line = next_quad;
	init_list(&true_list);
    init_list(&false_list);
    parse_statement();
    match(T_UNTIL);
    parse_bool_expression();
    backpatch_list(&false_list, start_line);  // 不满足终止条件，继续循环
    backpatch_list(&true_list, next_quad);
}

void parse_if()
{
    match(T_IF);
    
    init_list(&true_list);
    init_list(&false_list);
    parse_bool_expression();
    
    match(T_THEN);
    
    // 回填真出口到then语句
    backpatch_list(&true_list, next_quad);
    
    parse_statement();
    
    if (lookahead == T_ELSE) {
        // 生成跳过else的跳转
        int jump_over_else = next_quad;
        emit("j", "-", "-", "0");
        
        // 回填假出口到else语句
        backpatch_list(&false_list, next_quad);
        
        match(T_ELSE);
        parse_statement();
        
        // 回填跳过else的跳转
        backpatch(jump_over_else, next_quad);
    }
    else {
        // 回填假出口到if后
        backpatch_list(&false_list, next_quad);
    }
}

void parse_program() 
{
    match(T_PROGRAM);
    char prog_name[20];
    strcpy(prog_name, yytext);
    match(T_ID);
    match(T_SEMICOLON);

    emit("program", prog_name, "-", "-");
    
    parse_var_decl();
    parse_compound_stmt();
    
    match(T_DOT);
    emit("sys", "-", "-", "-");
}

int main(int argc, char const *argv[])
{
    char filename[100];
    
    printf("input your filename: ");
    scanf("%s", filename);

    FILE *fp = fopen(filename, "r");
    if (!fp)
    {
        printf("fail opening: %s\n", filename);
        return 1;
    }
    
    yyin = fp;
    lookahead = yylex();
    parse_program();
    
    for (int i = 0; i < next_quad; i++) 
        printf("(%2d)  (%s, %s, %s, %s)\n", i, codes[i].op, codes[i].arg1, codes[i].arg2, codes[i].res);
    
    fclose(yyin);
    return 0;
}

int yywrap() 
{
    return 1;
}
