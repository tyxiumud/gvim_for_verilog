# 自定义实例化与 Testbench 生成脚本

[返回 README](../README.md)

本项目包含三项自行编写的 Verilog 辅助功能：

- `,in`：从当前模块生成实例化模板。
- `,tb`：从当前模块生成 testbench 骨架。
- `,ii` / `,oo`：把一行“位宽 信号名”展开为对齐的端口声明（`input` / `output`）。

`,in`、`,tb` 与 `vlog_inst_gen` 插件相互独立，源代码位于：

```text
pack/user_define/start/user_define/plugin/vlog_inst_gen.vim
pack/user_define/start/user_define/plugin/vlog_tb_gen.vim
```

`,ii` / `,oo` 的实现位于：

```text
pack/user_define/start/user_define/autoload/verilog_port.vim
```

## 当前运行环境

`,in` 已改为纯 Vimscript 实现，不依赖 Python，并保持对 Vim 7.4 可用语法的兼容。`,tb` 仍通过旧式 `:python` 接口读取和写入 Vim Buffer；使用 `,tb` 前在 Vim/GVim 中执行：

```vim
:echo has('python')
```

- 返回 `1`：当前 Vim 可以执行旧版 `,tb` 脚本。
- 返回 `0`：按 `,tb` 会报错，但不影响纯 Vimscript 的 `,in`。

这里检查的是 `python`，不是 `python3`。`,tb` 后续会迁移到共享的纯 Vimscript 解析器；迁移完成前，可以使用 `,in` 或 `,ig` 生成实例化模板。

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

为了让当前轻量解析器稳定识别，建议满足以下条件：

- 一个文件只放一个需要生成的模块。
- 模块头使用 Verilog-2001 ANSI 端口声明，并以 `);` 结束。
- 端口方向使用 `input`、`output` 或 `inout`。
- 参数可以带类型、packed 位宽、下划线和表达式默认值。
- 同一声明中的多个端口会继承方向、类型和 packed 位宽。
- 生成后仍需人工检查宏、条件编译、interface 和其他复杂 SystemVerilog 结构。

## 使用 `,in` 生成实例化模板

1. 打开包含目标模块的 Verilog 文件。
2. 确认光标所在 Buffer 是需要解析的模块。
3. 在普通模式下按 `,in`。
4. 脚本创建一个名为 `inst_<module>.v` 的 Buffer，并在新标签页中显示生成内容；同名 Buffer 或文件存在时会自动添加数字后缀。

生成结果包含：

- 模块名和默认实例名 `U_<MODULE>_0`。
- 参数传递模板。
- `input`、`output`、`inout` 端口连接。
- 向量连接默认保留原始 packed 位宽，例如 `.data(data[WIDTH-1:0])`。
- 按最长端口名计算的基础对齐。

生成结果是未保存的普通 Buffer。确认结果后，请复制到目标文件或使用 `:write` 保存。

如果临时不希望连接信号携带 packed 位宽，可以在 `.vimrc` 中设置：

```vim
let g:verilog_gen_connect_width = 0
```

默认值为 `1`，符合本项目显式显示端口位宽的习惯。

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

输入行只接受恰好两个字段，格式为 `位宽 信号名`（位宽可以是数字或表达式）。字段数不对或位宽/信号名为空时会报错，不会破坏原内容。

### 输出示例

输入：

```text
8  data_i
1  clk
32 data_bus
```

对每一行依次按 `,ii` 后：

```verilog
input  wire [8-1: 0]  data_i,
input  wire           clk,
input  wire [32-1: 0] data_bus,
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

### 与 F6 宏的关系

`,ii` / `,oo` 是较新的实现，已取代旧的 `<F6>` 端口对齐宏。`<F6>` 仍保留在 `.vimrc` 中，但它使用写死的列位置和按键序列，信号名过长时会错位；建议新工作流统一使用 `,ii` / `,oo`，后续可从 `.vimrc` 移除 `<F6>` 映射。

### 扩展：支持 inout

`verilog_port#Format` 已支持 `inout` 方向，但默认只映射了 `,ii`（input）和 `,oo`（output）。如果需要，可在 `.vimrc` 中自行添加：

```vim
nnoremap <leader>io :call verilog_port#Expand('inout')<CR>
```

## 当前限制

### Testbench 生成器的 Python 接口较旧

`,tb` 使用 `:python`，很多现代 Vim 构建只支持 Python 3，或者完全不带 Python。`,in` 已经移除这项依赖；`,tb` 后续也会复用同一个纯 Vimscript 解析器。

### 解析器不是完整语法分析器

当前实现适合结构规则的模块头，但不是完整的 Verilog/SystemVerilog 语法解析器。以下情况需要特别检查：

- Verilog-95 非 ANSI 端口声明。
- 一个文件中存在多个模块。
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

返回 `0` 时，`,tb` 暂时无法使用；`,in` 和 `,ig` 仍可正常生成实例化模板。

### 提示找不到 ANSI module 或端口列表

检查：

- 模块头是否以 `);` 结束。
- 模块是否采用 ANSI 风格端口声明。
- 文件中是否包含多个模块、特殊宏或预处理结构。
- 是否在正确的 Verilog Buffer 中执行快捷键。

### 端口或参数缺失

先确认模块使用 Verilog-2001 ANSI 端口列表。`,in` 会识别参数类型、表达式、共享端口声明和 packed 位宽；遇到 interface、宏生成的模块头或其他复杂 SystemVerilog 结构时，可以使用 `,ig` 对比并人工检查。

## 后续优化方向

建议按以下顺序演进：

1. 让 `,tb` 复用 `,in` 已采用的共享模块、参数和端口解析器，移除旧式 Python 依赖。
2. 增加更多 SystemVerilog、宏、多模块和数组端口测试样例。
3. 让时钟周期、复位极性、仿真结束时间和 FSDB/VCD 波形格式可配置。
4. 改善错误信息，在具体行号提示无法识别的声明。

后续优化时，建议先保留一组真实模块作为回归样例，再逐步替换解析器，避免功能迁移过程中改变已有输出格式。
