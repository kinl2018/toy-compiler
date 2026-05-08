%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "header.h"
#define YYSTYPE node

codelist *list;
char *prog_name;
extern int yylineno;
extern char *yytext;
extern int yylex();
int iserror = 0;
extern FILE *yyin;
int yyerror(char *msg);
%}

%token AND ARR BEG BOOL CALL CASE CHR CONST DIM DO ELSE END BOOLFALSE FOR IF INPUT INT NOT OF OR OUTPUT PROCEDURE PROGRAM READ REAL REPEAT SET STOP THEN TO BOOLTRUE UNTIL VAR WHILE WRITE RELOP
%token LB RB RCOMMENT LCOMMENT COMMA DOT TDOT COLON ASSIGN SEMI LT LE NE EQ RT RE LC RC
%token INTEGER id TRUECHAR FALSECHAR TRUECOMMENT FALSECOMMENT ILLEGALCHR

%left ADD SUB
%left MUL DIV 
%left AND
%left OR
%left NOT
%left '+' '-'
%left '*' '/'
%right '='
%right ASSIGN
%nonassoc WITHOUT_ELSE
%nonassoc ELSE
%start program

%%
// <程序> -> program <标识符> ; var <变量定义> begin <语句表> end . | program <标识符> ; begin <语句表> end .
program : PROGRAM program_name SEMI VAR var_def BEG statement_table END DOT M
{
	backpatch(list, $7.nextlist, $10.instr);
	YYACCEPT;
}
		|PROGRAM program_name SEMI BEG statement_table END DOT M
		{
			backpatch(list, $5.nextlist, $8.instr);
			YYACCEPT;
		};
program_name : id { prog_name = $1.lexeme; };
// <变量定义> -> <标识符表> : <类型> ; <变量定义> | <标识符表> : <类型> ;
var_def : id_table COLON type SEMI var_def | id_table COLON type SEMI ;
// <类型> -> integer | bool | char
type : INT | BOOL | CHR ;
// <标识符表> -> <标识符> , <标识符表> | <标识符>
id_table : id COMMA id_table | id ;
// 跳转下条指令
M : { $$.instr = nextinstr(list); };
// 生成待回填的空跳转
N : {
	$$.nextlist = new_instrlist(nextinstr(list));
	gen_goto_blank(list);
};
// <语句表> -> <语句> ; <语句表> | <语句>
statement_table : statement SEMI M statement_table
				{
					backpatch(list, $1.nextlist, $3.instr);
					$$.nextlist = $4.nextlist;
				}
				|statement { $$.nextlist = $1.nextlist; };
// <语句> -> <赋值句> │ <if句> │ <while句> │ <repeat句> │ <复合句>
statement : IF expression THEN M statement %prec WITHOUT_ELSE
			{
				backpatch(list, $2.truelist, $4.instr);
				$$.nextlist = merge($2.falselist, $5.nextlist);
			}
			|IF expression THEN M statement ELSE N M statement
			{
				backpatch(list, $2.truelist, $4.instr);
				backpatch(list, $2.falselist, $8.instr);
				$5.nextlist = merge($5.nextlist, $7.nextlist);
				$$.nextlist = merge($5.nextlist, $9.nextlist);
			}
			|WHILE M expression DO M statement
			{
				backpatch(list, $6.nextlist, $2.instr);
				backpatch(list, $3.truelist, $5.instr);
				$$.nextlist = $3.falselist;
				gen_goto(list, $2.instr);
			}
			|REPEAT M statement UNTIL M expression M statement
			{
				backpatch(list, $3.nextlist, $5.instr);
				backpatch(list, $6.falselist, $2.instr);
				backpatch(list, $6.truelist, $7.instr);
			}
			|calc_expression ASSIGN expression
			{
				copyaddr(&$1, $1.lexeme);
				gen_assign(list, $1, $3);
			}
			|BEG statement_table END { $$.nextlist = $2.nextlist; }
			|{} ;
// RELOP为关系符如<, <>, <=, >=, >, =
expression : expression AND M expression
			{
				backpatch(list, $1.truelist, $3.instr);
				$$.truelist = $4.truelist;
				$$.falselist = merge($1.falselist, $4.falselist);
			}
			|expression OR M expression
			{
				backpatch(list, $1.falselist, $3.instr);
				$$.falselist = $4.falselist;
				$$.truelist = merge($1.truelist, $4.truelist);
			}
			|NOT expression
			{
				$$.truelist = $2.falselist;
				$$.falselist = $2.truelist;
			}
			|calc_expression RELOP calc_expression
			{
				$$.truelist = new_instrlist(nextinstr(list));
				$$.falselist = new_instrlist(nextinstr(list)+1);
				gen_if(list, $1, $2.oper, $3);
				gen_goto_blank(list);
			}
			|calc_expression { copyaddr_fromnode(&$$, $1); };
calc_expression : INTEGER { copyaddr(&$$, $1.lexeme); }
				|calc_expression ADD calc_expression
				{
					new_temp(&$$, get_temp_index(list));
					gen_3addr(list, $$, $1, " +", $3);
				}
				|calc_expression SUB calc_expression 
                {
                    new_temp(&$$, get_temp_index(list));
                    gen_3addr(list, $$, $1, " -", $3);
                }
                |calc_expression MUL calc_expression 
                {
                    new_temp(&$$, get_temp_index(list)); 
                    gen_3addr(list, $$, $1, " *", $3);
                }

                |calc_expression DIV calc_expression 
                {
                    new_temp(&$$, get_temp_index(list)); 
                    gen_3addr(list, $$, $1, " /", $3);
                }
                |id { copyaddr(&$$, $1.lexeme); };

%%

char* removeNewline(char *str)
{
	size_t length = strlen(str);
	if (length > 0)
	{
		if (str[length - 1] == '\n') str[length - 1] == '\0';
	}
	else
	{
		free(str);
		str = strdup("null");
	}
	return str;
}

int main()
{
	char filename[100];
    printf("input your filename: ");
    scanf("%s", filename);
    list = new_codelist();
    FILE *fp = fopen(filename, "r");
    if (!fp)
    {
        printf("fail opening: %s\n", filename);
        return 1;
    }
    yyin = fp;
    yyparse();
    if (iserror == 1) printf("Process failed.\n");
    else print(list, prog_name);
    return 0;
}
int yyerror(char *msg)
{
	fprintf(stderr, "%s at line %d. Unexpected character: %s\n",msg, yylineno, removeNewline(yytext)); 
    iserror = 1;
    return 0;
}
int yywrap() { return 1; }