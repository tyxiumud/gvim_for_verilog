# ALE 与 Verilog 检查器使用指南

[返回 README](../README.md)

ALE（Asynchronous Lint Engine）负责在 Vim 中调度外部检查器、收集结果并显示错误。ALE 本身不包含 Verilog 编译器或 linter，因此每台电脑可以根据已经安装的工具选择不同配置。

## 当前仓库的默认配置

`.vimrc` 当前使用：

```vim
let b:ale_linters = ['xvlog']
```

`b:` 表示 Buffer 局部变量。这条设置只影响执行 `.vimrc` 时的当前 Buffer，不会强制其他 Buffer 或其他用户都使用 `xvlog`。

这种方式适合保留个人环境差异。如果新建或切换到另一个 Verilog Buffer，该 Buffer 没有 `b:ale_linters` 时，ALE 会按自己的默认规则选择已注册的检查器。

## `.f` Verilog 文件列表

Vim 默认把 `.f` 后缀识别为 Fortran 源文件，ALE 随后可能启动 Fortran 检查器。Verilog 工程通常又使用 `.f` 保存源文件列表，因此本仓库在 `.vimrc` 中将它定义为单独的 `verilog_filelist` 文件类型，并只对这种 Buffer 关闭 ALE：

```vim
augroup verilog_filelist
    autocmd!
    autocmd BufNewFile,BufRead *.f setlocal filetype=verilog_filelist
    autocmd FileType verilog_filelist let b:ale_enabled = 0
augroup END
```

这里使用独立的自动命令组，不会清理 Vim 内置 `filetypedetect` 组中的其他规则。`b:ale_enabled` 是 Buffer 局部变量，不影响 `.v`、`.sv` 或其他文件中的 ALE 检查。

打开 `.f` 文件后，可以确认设置结果：

```vim
:set filetype?
:echo get(b:, 'ale_enabled', 1)
```

预期分别显示 `filetype=verilog_filelist` 和 `0`。如果需要编辑真正的 Fortran `.f` 源文件，应删除这段配置、换用其他文件列表后缀，或者把匹配规则限制到特定工程目录。

## 选择适合自己的检查器

常见选择如下：

| 检查器 | 适用场景 | 需要安装的外部工具 |
| --- | --- | --- |
| `xvlog` | Vivado/Xilinx 设计与仿真流程 | Xilinx Vivado |
| `iverilog` | 轻量、开源的 Verilog 编译检查 | Icarus Verilog |
| `verilator` | 较严格的 lint、风格和可综合性检查 | Verilator |
| `vlog` | ModelSim/Questa 流程 | ModelSim 或 Questa |
| `yosys` | 偏综合流程的语法和设计检查 | Yosys |
| `hdl-checker` | 多工具 HDL 项目与编辑器集成 | HDL Checker |

ALE 不会自动安装这些工具。选择某个 linter 之前，先确认对应命令在启动 GVim 的环境中可用。

## 三种配置范围

### 只修改当前 Buffer

在当前 Verilog 文件中执行：

```vim
:let b:ale_linters = ['xvlog']
:ALELint
```

也可以临时组合多个检查器：

```vim
:let b:ale_linters = ['iverilog', 'verilator']
```

关闭当前 Buffer 的所有 linter：

```vim
:let b:ale_linters = []
```

### 每个 Verilog Buffer 分别设置

如果希望每次打开 Verilog/SystemVerilog 文件时都创建 Buffer 局部设置，可以在 `.vimrc` 中使用：

```vim
augroup verilog_ale
    autocmd!
    autocmd FileType verilog,systemverilog,verilog_systemverilog let b:ale_linters = ['xvlog']
augroup END
```

变量仍然属于各自 Buffer，但无需手动执行命令。

### 全局按文件类型设置

如果整台电脑都使用同一套工具，可以改为：

```vim
let g:ale_linters = {
\   'verilog': ['xvlog'],
\   'systemverilog': ['xvlog'],
\   'verilog_systemverilog': ['xvlog'],
\}
```

不要同时保留冲突的 `b:ale_linters`；Buffer 局部设置的优先级高于全局设置。

## 确认工具是否可用

以 `xvlog` 为例，在 GVim 中执行：

```vim
:echo executable('xvlog')
```

- 返回 `1`：GVim 能找到 `xvlog`。
- 返回 `0`：需要配置 Vivado 环境或 PATH。

Windows 可以把实际 Vivado 安装目录中的 `bin` 加入 PATH，也可以从已经配置 Vivado 环境的终端启动 GVim。Linux 通常可以先加载 Vivado 提供的 `settings64.sh`，再从同一终端启动 GVim。

使用其他检查器时，将命令名替换为 `iverilog`、`verilator`、`vlog` 或 `yosys` 即可。

## 常用 ALE 命令

| 命令 | 功能 |
| --- | --- |
| `:ALEInfo` | 查看当前 Buffer 的文件类型、linter、可执行文件和完整配置 |
| `:ALELint` | 立即检查当前 Buffer |
| `:ALEToggle` | 全局开关 ALE |
| `:ALEEnable` | 启用 ALE |
| `:ALEDisable` | 禁用 ALE |
| `:ALEInfoToFile <文件>` | 将诊断信息写入文件，便于排查问题 |
| `:copen` | 打开 quickfix 结果列表 |
| `:cclose` | 关闭 quickfix 结果列表 |

## 当前结果列表行为

仓库配置使用 quickfix 而不是 location list：

```vim
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_open_list = 1
let g:ale_keep_list_window_open = 1
```

这会在发现问题时自动打开并保持 quickfix 窗口。如果希望只显示行号旁的标记，不自动打开列表，可以改为：

```vim
let g:ale_open_list = 0
let g:ale_keep_list_window_open = 0
```

## 排查步骤

### ALE 没有加载

```vim
:echo exists(':ALEInfo')
```

返回 `0` 时，检查文件是否位于：

```text
pack/ale/start/ale/plugin/ale.vim
```

### ALE 加载了，但没有诊断

依次检查：

```vim
:set filetype?
:echo get(b:, 'ale_linters', '未设置')
:echo executable('xvlog')
:ALEInfo
```

重点查看 `ALEInfo` 中的 enabled linters、executable 和 command history。

### 新 Buffer 使用了不同检查器

这是 `b:ale_linters` 的作用域导致的正常现象。根据需要在新 Buffer 中重新设置，或选择上面的 FileType 自动命令/全局字典方案。

### 从终端能运行检查器，GVim 中却找不到

GVim 继承的是启动它时的环境变量。桌面快捷方式、普通终端和 Vivado 命令行可能拥有不同 PATH。请从已配置环境的终端启动 GVim，或把工具路径加入系统环境变量后重新启动 GVim。
