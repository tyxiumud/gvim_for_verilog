# Verilog 生成脚本说明

[返回 README](../README.md)

本项目的实例化由 `vlog_inst_gen` 插件生成，另外保留两项自定义功能：

- `,ig`：从当前文件中的模块生成实例化模板；输出模式由参数设定。
- `,tb`：从当前模块生成 testbench 骨架。
- `,ii` / `,oo`：把一行“位宽 信号名”展开为对齐的端口声明（`input` / `output`）。

对应的实现位于：

```text
pack/vlog_inst_gen/start/vlog_inst_gen/plugin/vlog_inst_gen.vim
pack/user_define/start/user_define/autoload/verilog_tools.vim
pack/user_define/start/user_define/plugin/vlog_tb_gen.vim
pack/user_define/start/user_define/autoload/verilog_port.vim
```

`verilog_tools.vim` 只保留模块头解析器，供 `,ig` 的可选位宽功能使用；原先自写的 `,in` 实例化命令已移除。

## `,ig` 生成与模式参数

在普通模式下，`,ig` 立即运行 `:VlogInstGen`，生成实例化内容并复制到剪贴板。通过 `g:vlog_inst_gen_mode` 设定模式，默认值为 `2`；可在 `.vimrc` 中设置，例如 `let g:vlog_inst_gen_mode = 1`。

| 模式 | 按 `,ig` 后的结果 |
| --- | --- |
| 0 | 复制到剪贴板，并在命令区显示生成内容 |
| 1 | 只复制到剪贴板 |
| 2 | 复制到剪贴板，并在分屏中显示生成内容 |
| 3 | 复制到剪贴板，并更新当前文件头部的插件实例化注释块 |

模式 3 会改动当前 Buffer，请确认生成结果后再保存文件。

### 可选的位宽和方向备注

仓库自带的 `vlog_inst_gen` 插件保持原有的端口顺序、`,ig` 快捷键和四种输出模式。本仓库的 `.vimrc` 已开启两个独立选项：

```vim
let g:vlog_inst_gen_connect_width = 1
let g:vlog_inst_gen_direction_comment = 1
```

- `g:vlog_inst_gen_connect_width`：把模块声明的 packed 位宽附在连接信号后，例如 `.data(data[WIDTH-1:0])`；设为 `0` 时只输出 `.data(data)`。
- `g:vlog_inst_gen_direction_comment`：在连接行末自动添加 `//input`、`//output` 或 `//inout`；设为 `0` 时不添加。`)` 与 `//` 之间没有空格。
- `g:vlog_inst_gen_keep_comments`：默认 `0`，删除源模块端口列表中独立一行的 `//` 注释；设为 `1` 时保留，如 `//mac to pcs`、`//config`。此项与自动方向标注相互独立。

插件本身的这三个选项默认都是 `0`。位宽通过仓库中的纯 Vimscript 模块头解析器读取，条件编译分支另有逐行回退；无法解析复杂宏或非 ANSI 声明时，插件仍会生成连接，但部分位宽可能缺失。方向标注使用插件本身解析的端口方向，不依赖 `i_`、`o_` 等命名前缀。

连接信号后的 `[WIDTH-1:0]` 在 Verilog 中是实际的位选取。粘贴实例化结果后，需要确认目标信号已声明且位宽和参数一致。

## 当前运行环境

`,ig` 和它的可选位宽解析器都使用 Vimscript，不依赖 Python。`,tb` 仍通过旧式 `:python` 接口读取和写入 Vim Buffer；使用 `,tb` 前在 Vim/GVim 中执行：

```vim
:echo has('python')
```

- 返回 `1`：当前 Vim 可以执行旧版 `,tb` 脚本。
- 返回 `0`：按 `,tb` 会报错，但不影响 `,ig`。

这里检查的是 `python`，不是 `python3`。`,tb` 后续可迁移到纯 Vimscript 解析器；目前请使用 `,ig` 生成实例化模板。

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

为了让可选位宽解析器稳定识别，建议满足以下条件：

- `,ig` 可以处理同一文件中的多个模块；`,tb` 目前建议一个文件只放一个目标模块。
- 模块头使用 Verilog-2001 ANSI 端口声明，并以 `);` 结束。
- 端口方向使用 `input`、`output` 或 `inout`。
- 参数可以带类型、packed 位宽、下划线和表达式默认值。
- 同一声明中的多个端口会继承方向、类型和 packed 位宽。
- 生成后仍需人工检查宏、条件编译、interface 和其他复杂 SystemVerilog 结构。

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

## 使用 `,ii` / `,oo` 展开端口声明

`,ii` 和 `,oo` 把光标所在行的一对“位宽 信号名”展开成对齐的 Verilog 端口声明，分别生成 `input` 和 `output`。它不依赖 Python，兼容 Vim 7.4。

### 用法

1. 在普通模式下，把光标放在一行 `位宽 信号名` 上，例如 `8 data_i`。
2. 按 `,ii` 生成输入端口，或按 `,oo` 生成输出端口。
3. 当前行被替换为对齐后的声明，光标自动移到下一行；逐行重复即可快速列出一组端口。

输入行只接受恰好两个字段，格式为 `位宽 信号名`。位宽字段可以是数字、参数名或不含空格的表达式，例如 `8`、`DATA_WIDTH` 或 `WIDTH+1`；`WIDTH + 1 data_i` 会因为被拆成多个字段而报错。字段数不对或位宽/信号名为空时不会修改原内容。

### 输出示例

输入：

```text
8  data_i
1  clk
32 data_bus
```

对每一行依次按 `,ii` 后：

```verilog
    input   wire    [8      -1: 0]          data_i                                       ,
    input   wire                            clk                                          ,
    input   wire    [32     -1: 0]          data_bus                                     ,
```

位宽为 `1` 时按标量端口处理，不写 `[1-1: 0]` 区间，直接生成 `input wire clk,`；信号名列仍与其他多比特端口对齐。位宽大于 `1` 时按 `W-1: 0` 形式保留原始表达式，不预先求值；字段间按目标列对齐，某个信号名过长时后续字段会自动右移，不会像旧式宏那样因超长而错位。

### 调整对齐列

各字段的目标列由 `.vimrc` 中的 `g:verilog_port_columns` 控制：

```vim
let g:verilog_port_columns = {
\   'direction': 5,
\   'type': 13,
\   'width': 21,
\   'width_suffix': 29,
\   'name': 45,
\   'comma': 90,
\}
```

含义（均为从 1 开始的显示列，不是插入的空格数）：

- `direction`：`input` / `output` 起始列。
- `type`：`wire` 起始列。
- `width`：`[` 与位宽起始列。
- `width_suffix`：`-1: 0]` 起始列。
- `name`：信号名起始列。
- `comma`：行尾逗号起始列。

相邻目标列之差就是前一字段预留的宽度。只需修改对应的数字即可整体改变对齐风格，无需改动 `autoload/verilog_port.vim` 本身。

### 与 F6 的区别

`,ii` / `,oo` 根据“位宽 信号名”生成模块声明中的 `input` / `output` 行；`F6` 用于整理已经生成的模块实例化连接。两者处理的内容不同，不互相替代，因此当前都保留在 `.vimrc` 中。

### 扩展：支持 inout

`verilog_port#Format` 已支持 `inout` 方向，但默认只映射了 `,ii`（input）和 `,oo`（output）。如果需要，可在 `.vimrc` 中自行添加：

```vim
nnoremap <leader>io :call verilog_port#Expand('inout')<CR>
```

## 当前限制

### Testbench 生成器的 Python 接口较旧

`,tb` 使用 `:python`，很多现代 Vim 构建只支持 Python 3，或者完全不带 Python。`,ig` 不依赖它；`,tb` 后续可复用纯 Vimscript 解析器。

### 解析器不是完整语法分析器

当前实现适合结构规则的模块头，但不是完整的 Verilog/SystemVerilog 语法解析器。以下情况需要特别检查：

- Verilog-95 非 ANSI 端口声明。
- `,tb` 处理一个文件中的多个模块。
- `ifdef`、宏展开或复杂预处理结构。
- escaped identifier、interface、modport、结构体和部分复杂数组声明。
- 依赖预处理宏才能形成完整模块头的代码。

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

返回 `0` 时，`,tb` 暂时无法使用；`,ig` 仍可正常生成实例化模板。

### 提示找不到 ANSI module 或端口列表

检查：

- 模块头是否以 `);` 结束。
- 模块是否采用 ANSI 风格端口声明。
- 文件中是否包含多个模块、特殊宏或预处理结构。
- 是否在正确的 Verilog Buffer 中执行快捷键。

### 端口或参数缺失

先确认模块使用 Verilog-2001 ANSI 端口列表。`,ig` 的位宽解析器会识别参数类型、表达式、共享端口声明和 packed 位宽；遇到 interface、宏生成的模块头或其他复杂 SystemVerilog 结构时，请人工检查生成结果。

## 后续优化方向

建议按以下顺序演进：

1. 让 `,tb` 复用现有的纯 Vimscript 模块、参数和端口解析器，移除旧式 Python 依赖。
2. 增加更多 SystemVerilog、宏、多模块和数组端口测试样例。
3. 让时钟周期、复位极性、仿真结束时间和 FSDB/VCD 波形格式可配置。
4. 改善错误信息，在具体行号提示无法识别的声明。

后续优化时，建议先保留一组真实模块作为回归样例，再逐步替换解析器，避免功能迁移过程中改变已有输出格式。
