### 食用方法

step 1: 进入相应的文件夹，如`cd ex1`或`cd ex2`

step 2: 编译相关文件

```bash
flex scanner.l
gcc lex.yy.c -o scanner
./scanner
```

`flex scanner.l`得到flex编译后的产物lex.yy.c，如果`flex`指令无效的话请尝试`win_flex`。

### Requirement

flex，详见老师压缩包里的'1必须安装的工具-win_flex_bison-2.5.20.zip'

### Acknowledgement

Claude Sonnet 4.5，在所有人眼里小克都是全世界最nice的llm！

Gemini 3.1pro，虽然此物又懒又笨但顺便感谢一下吧，框架搭起来也有芥末奶的一份功劳。