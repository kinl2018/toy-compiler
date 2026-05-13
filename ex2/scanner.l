%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct node node;
#define YYSTYPE node
#include "y.tab.h"
extern void filloperator(node *n, char *op);
extern void filllexeme(node *n, char *yytext);
extern int yyerror(char *msg);
%}

%option yylineno
letter      [A-Za-z]
digit       [0-9]
 // 空格
ws	[delim]+ 
 // <标识符> -> <字母>│<标识符> <数字>│<标识符> <字母>
identifier {letter}({letter}|{digit})*
 //整数
integer {digit}+
 //字符常数和错误的字符常数
char_const ['][^']*[']
false_char_const ['][^']*
 //注释和错误的注释
comment [/][*].*[*][/]
false_comment [/][*].*
%%

[ \t\r\a]+   ; // 空白字符
[\n]         ; // 换行符
and          return AND;
array        return ARR;
begin        return BEG;
bool         return BOOL;
call         return CALL;
case         return CASE;
char         return CHR;
constant     return CONST;
dim          return DIM;
do           return DO;
else         return ELSE;
end          return END;
false        return BOOLFALSE;
for          return FOR;
if           return IF;
input        return INPUT;
integer      return INT;
not          return NOT;
of           return OF;
or           return OR;
output       return OUTPUT;
procedure    return PROCEDURE;
program      return PROGRAM;
read         return READ;
real         return REAL;
repeat       return REPEAT;
set          return SET;
stop         return STOP;
then         return THEN;
to           return TO;
true         return BOOLTRUE;
until        return UNTIL;
var          return VAR;
while        return WHILE;
write        return WRITE;
"("          return LB;
")"          return RB;
"*"          return MUL;
"*/"         return RCOMMENT;
"+"          return ADD;
","          return COMMA;
"-"          return SUB;
"."          return DOT;
".."         return TDOT;
"/"          return DIV;
"/*"         return LCOMMENT;
":"          return COLON;
":="         { filloperator(&yylval, yytext); return ASSIGN; }
";"          return SEMI;
"<"|"<="|">"|">="|"<>"|"="    { filloperator(&yylval, yytext); return RELOP; }
"["          return LC;
"]"          return RC;

{ws}    { }
{identifier} {  // 标识符
    filllexeme(&yylval, yytext);
    return id;
}
{integer} { 
    filllexeme(&yylval, yytext);
    return INTEGER; 
}
{char_const} { //字符常数
    return TRUECHAR;
}
{false_char_const} { //错误字符常数
    printf("Wrong Character Constant Format: %s\n", yytext); 
    return FALSECHAR;
}
{comment} {  // 注释
    //printf("This is a comment, do not show this: %s\n", yytext); 
    return TRUECOMMENT;
}
{false_comment} {  // 错误注释
    printf("Wrong Comment Format: %s\n", yytext); 
    return FALSECOMMENT;
}
. {  //其他非法字符
    yyerror(yytext);
    return ILLEGALCHR;
}

%%