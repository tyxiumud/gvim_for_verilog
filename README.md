> gvim_for_verilog 是用于分享总结写Verilog的VIM配置方案，重点在于简洁使用！！！有问题以及改进欢迎提PR，或者直接联系邮箱823300630@qq.com

# 使用方式

对于linux用户，输入 `cd ~ `然后` gvim .vimrc`，将提供的配置文件`.vimrc`中的配置粘贴到该文件中即可。对于windows用户，打开GVIM的安装路径，可以看到`_vimrc`文件，就是GVIM的配置文件。
同时本库还提供了一下插件，对应的插件及其功能演示在下文`VIM插件推荐`会进行介绍。使用的时候需要确保你的VIM版本在8.0及其以上，在此版本下，VIM有了自己的插件管理工具，简单来讲就是管理插件安装与卸载的工具。打开vim安装的根目录，会有一个pack文件，将库里pack目录下的文件夹复制到vim的根目录pack文件夹下即可使用这些插件，担心会对VIM有很大影响的可以删除对应的插件即可。或是将其放置到opt目录下，更详细的使用方式见VIM的官方指南（:help package）。

# VIM插件推荐

## NERDTREE[树形目录]安装与使用
### 功能描述
打开一个文件树，方便使用鼠标或是光标进行打开文件的选择
### 演示

### 安装与配置
插件地址：https://www.vim.org/scripts/script.php?script_id=1658

## 自动实例化脚本
### 功能描述
对你的verilog文件产生一个实例化模板，方便再更高的层次进行实例化调用
### 演示

### 安装与配置

插件地址：https://www.vim.org/scripts/script.php?script_id=4151

## 状态栏美化插件-airline



## 括号自动补全插件-auto_pairs_master



# 其他

在`.vimrc`中`<cr>`表示回车的意思，`M`表示`Alt`的意思，`C`表示`Ctrl`的意思
