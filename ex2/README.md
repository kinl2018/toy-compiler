### 食用方法

step 1: 进入相应的文件夹，如`cd ex2`

step 2: 编译相关文件

```bash
bison -d -y parser.y
flex scanner.l
gcc y.tab.c lex.yy.c -o compiler
./compiler
```

如果`flex`指令无效的话请尝试`win_flex`，同理`bison`。

### Requirement

flex和bison，详见老师压缩包里的'1必须安装的工具-win_flex_bison-2.5.20.zip'

### Acknowledgement

大部分代码参考自https://github.com/perfsakuya/Compiler_Experiment，本人只做了小小改动，感恩的心！