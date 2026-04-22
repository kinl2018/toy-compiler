%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int line_num = 1;
%}

letter      [A-Za-z]
digit       [0-9]
identifier  {letter}({letter}|{digit})*
integer {digit}+
string '([^'\n]|'')*'
%%

[ \t\r\a]+     ; // 空白字符
\n             { line_num++; } // 记录行号
"/*"[^\n]*"*/" ; // 匹配完整注释，直接跳过不返回Token
and return 1;
array return 2;
begin return 3;
bool return 4;
call return 5;
case return 6;
char return 7;
constant return 8;
dim return 9;
do return 10;
else return 11;
end return 12;
false return 13;
for return 14;
if return 15;
input return 16;
integer return 17;
not return 18;
of return 19;
or return 20;
output return 21;
procedure return 22;
program return 23;
read return 24;
real return 25;
repeat return 26;
set return 27;
stop return 28;
then return 29;
to return 30;
true return 31;
until return 32;
var return 33;
while return 34;
write return 35;
{identifier} return 36; // 标识符
{integer} return 37;
{string} return 38;
"(" return 39;
")" return 40;
"*" return 41;
"*/" return 42;
"+" return 43;
","          return 44;
"-" return 45;
"." return 46;
".." return 47;
"/" return 48;
"/*" return 49;
":"          return 50;
":=" return 51;
";"          return 52;
"<" return 53;
"<=" return 54;
"<>" return 55;
"=" return 56;
">" return 57;
">=" return 58;
"[" return 59;
"]" return 60;

"/*"[^\n]* { printf("Error: line %d annotation missing */\n", line_num); }
'[^'\n]* { printf("Error: line %d string missing quotation marks\n", line_num); }
.                { printf("Error: line %d lllegal character %s\n", line_num, yytext); }
%%
char sym_table[1000][100];
int sym_count = 0;
int get_id(char *str) {
    for (int i = 0; i < sym_count; i++) {
        if (strcmp(sym_table[i], str) == 0) {
            return i + 1;
        }
    }
    strcpy(sym_table[sym_count], str);
    sym_count++;
    return sym_count;
}
int main(int argc, char const *argv[]) {
	char filename[100];
    
    printf("input your filename: ");
    scanf("%s", filename);

    FILE *fp = fopen(filename, "r");
    if (!fp) {
        printf("fail opening: %s\n", filename);
        return 1;
    }
    yyin = fp;
    int type, count = 0;
    while (type = yylex()) {
        if (type == 36 || type == 37 || type == 38) {
            printf("(%2d , %-2d)\t", type, get_id(yytext));
        }
        else {
            printf("(%2d , - )\t", type);
        }
        ++count;
        if (count % 5 == 0) {
            printf("\n");
        }
    }
    if (count % 5 != 0) {
        printf("\n");
    }
    fclose(fp);
    return 0;
}

int yywrap() {
    return 1;
}