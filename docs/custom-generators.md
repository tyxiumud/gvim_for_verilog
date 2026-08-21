# 自定义实例化与 Testbench 生成脚本

[返回 README](../README.md)

本项目包含两项自行编写的 Verilog 辅助功能：

- `,in`：从当前模块生成实例化模板。
- `,tb`：从当前模块生成 testbench 骨架。

这两个功能与 `vlog_inst_gen` 插件相互独立，源代码分别位于：

```text
pack/user_define/start/user_define/plugin/vlog_inst_gen.vim
pack/user_define/start/user_define/plugin/vlog_tb_gen.vim
```

## 当前运行环境

脚本嵌入在 Vim function 中，通过旧式 `:python` 接口读取和写入 Vim Buffer。使用前在 Vim/GVim 中执行：

```vim
:echo has('python')
```

- 返回 `1`：当前 Vim 可以执行这两个脚本。
- 返回 `0`：当前 Vim 没有脚本所需的 Python 接口，按 `,in` 或 `,tb` 会报错。

这里检查的是 `python`，不是 `python3`。脚本后续计划迁移到 Python 3；迁移完成前，可以使用纯 Vimscript 的 `,ig` 生成实例化模板。

## 建议的模块格式

脚本主要面向 Verilog-2001 的 ANSI 风格端口声明，例如：

```verilog
module data_pipe #(
    parameter WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rst_n,
    input  wire [WIDTH-1:0]     data_i,
    output wire [WIDTH-1:0]     data_o
);

endmodule
```

为了让当前正则解析器稳定识别，建议满足以下条件：

- 一个文件只放一个需要生成的模块。
- `module` 从行首开始书写。
- 模块头使用 Verilog-2001 端口声明，并以单独的 `);` 结束。
- 端口方向使用 `input`、`output` 或 `inout`。
- 参数名使用大写字母，参数默认值优先使用简单数字。
- 生成后人工检查复杂位宽、宏、条件编译和特殊参数表达式。

## 使用 `,in` 生成实例化模板

1. 打开包含目标模块的 Verilog 文件。
2. 确认光标所在 Buffer 是需要解析的模块。
3. 在普通模式下按 `,in`。
4. 脚本创建一个名为 `inst` 的 Buffer，并在新标签页中显示生成内容。

生成结果包含：

- 模块名和默认实例名 `U_<MODULE>_0`。
- 参数传递模板。
- `input`、`output`、`inout` 端口连接。
- 按最长端口名计算的基础对齐。

`inst` 是未保存的辅助 Buffer。确认结果后，请复制到目标文件或使用 `:write` 保存到明确路径。

## 使用 `,tb` 生成 testbench

1. 打开包含目标模块的 Verilog 文件。
2. 在普通模式下按 `,tb`。
3. 脚本创建 `tb_<module>.v` Buffer，并在新标签页中显示 testbench 骨架。

当前模板会自动生成：

- `` `timescale 1ns/1ps ``。
- `TB_<module>` 顶层模块。
- 参数、本地输入/输出/inout 信号声明。
- DUT 实例化及端口连接。
- 输入信号初始值。
- 名称中包含 `clk` 的输入信号对应的 `always #1` 时钟。
- 名称中包含 `rst` 的输入信号对应的基础复位过程。
- FSDB 波形文件、`$fsdbDumpvars` 和仿真结束模板。

生成的 Buffer 默认未保存，需要检查后手动写入文件。

## 当前限制

### Python 接口较旧

脚本使用 `:python`，很多现代 Vim 构建只支持 Python 3，或者完全不带 Python。迁移时需要把 Vim 接口切换到 `:python3`，并同步检查 Python 3 的字符串与 Buffer 行为。

### 解析器基于正则表达式

当前实现适合结构规则的模块头，但不是完整的 Verilog/SystemVerilog 语法解析器。以下情况需要特别检查：

- Verilog-95 非 ANSI 端口声明。
- 一个文件中存在多个模块。
- `ifdef`、宏展开或复杂预处理结构。
- interface、modport、结构体或其他 SystemVerilog 特性。
- 多端口合并声明、复杂参数类型和多行表达式。
- 模块头结束行带有额外字符或行尾注释。

### Testbench 模板带有项目假设

- 时钟周期固定为 `always #1`。
- 所有包含 `rst` 的输入都使用相同的初始过程，未区分高有效和低有效。
- 波形模板使用 FSDB 系统任务，需要相应仿真器和 Verdi/FSDB 支持。
- 仿真结束时间固定为 `#1000`。

这些内容适合作为可编辑骨架，不应在所有项目中直接照搬。

## 常见问题

### 按快捷键提示 `E319` 或 Python 不可用

```vim
:echo has('python')
```

返回 `0` 时，当前只能更换带 Python 接口的 Vim，或暂时使用 `,ig`。后续迁移到 Python 3 后可解除这一限制。

### 提示找不到 module block

检查：

- `module` 前是否存在缩进。
- 模块头是否以 `);` 结束。
- 文件中是否包含多个模块或特殊宏结构。
- 是否在正确的 Verilog Buffer 中执行快捷键。

### 端口或参数缺失

先把复杂声明改写为更标准的 Verilog-2001 ANSI 形式，再尝试生成。也可以先使用 `,ig` 对比结果，帮助定位当前正则没有覆盖的语法。

## 后续优化方向

建议按以下顺序演进：

1. 将 `:python` 迁移为 Python 3，并在缺少接口时给出友好提示。
2. 抽出共享的模块、参数和端口解析逻辑，避免实例化与 testbench 脚本重复实现。
3. 增加 Verilog-2001、SystemVerilog、宏和多模块测试样例。
4. 让时钟周期、复位极性、仿真结束时间和 FSDB/VCD 波形格式可配置。
5. 改善错误信息，在具体行号提示无法识别的声明。
6. 将生成结果改成可命名、可预览并明确保存状态的临时 Buffer。

后续优化时，建议先保留一组真实模块作为回归样例，再逐步替换解析器，避免功能迁移过程中改变已有输出格式。
