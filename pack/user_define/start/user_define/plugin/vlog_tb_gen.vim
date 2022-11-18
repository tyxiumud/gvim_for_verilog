"not apply for vlog_95,best option is vlog_2001
"can't support use this function for one file multule times
function! Autotb()
python << EOF
import vim,re

# feature : find module_head index line 
# input : all lines
# output : index form module to end-of module define
def find_moulde(lines):
    module_block_index = []
    for i in range(len(lines)):
        module_start_line = re.findall('^module\s[a-zA-z]+',lines[i])
        module_end_line = re.findall('[)];$',lines[i])
        if(module_start_line != []):
            module_block_index.append(i)
        if(module_end_line != []):
            module_block_index.append(i+1)
            break
    if(len(module_block_index) != 2):
        raise('Not find your module block')
    return module_block_index

# 输入：每一行的代码列表
# 输出：每一行没有任何注释的代码，列表形式
# 函数描述：清除所有注释内容
def clear_commonts(lines,module_index):  
    block_comment_index = []  # record block comment index
    # remove // comment 
    for i in range(module_index[0],module_index[1]):
        lines[i] = re.sub('//.*$','',lines[i]) # 去掉//注释的语句
        all_pairs = re.findall('/\*',lines[i])
        if(all_pairs != []):
            block_comment_index.append(i)
        if(re.search('\*/',lines[i])!=None): # find paired */
            block_comment_index.append(i)
    # print(block_comment_index)
    if(len(block_comment_index)%2!=0):
        raise('ERROR: /* and */ not paired')
    else:
        for i in range(int(len(block_comment_index)/2)):
            left_index = block_comment_index[i*2]
            right_index = block_comment_index[i*2+1]
            if(left_index==right_index):               # inline /* */
                lines[left_index] = re.sub('/\*.*\*/','',lines[left_index])
            else: 
                for j in range(left_index+1,right_index):  # delet comment in block /* */
                    lines[j] = ''
                lines[left_index] = re.sub('/\*.*$','',lines[left_index])
                lines[right_index] = re.sub('^.*\*/','',lines[right_index])
    return lines

# 找到模块名
def find_inst_name(line):
    pattern = re.compile('(module)\s+(\w+)')
    if(pattern.search(line)!=None):
        return pattern.search(line).group(2)
    else:
        return ''

# 文本行转换为字符串
def lines2string(lines):
    string = ''
    for l in lines:
      string += l
    return string

# 获取输入输出端口名以及位宽,符号
def find_port_and_width(s):
    signed_flag = 0
    l_tmp = re.sub('(input)|(output)|(inout)','',s,1) # count=1 will not sub these word in signal name
    l_tmp = re.sub('(wire)|(reg)','',l_tmp,1)
    if(re.search('\sunsigned[\s\[]',l_tmp)!=None):
        signed_flag = 'unsigned'
    elif(re.search('\ssigned[\s\[]',l_tmp)!=None):
        signed_flag = 'signed'
    else:
        signed_flag = ' '
    l_tmp = re.sub('(signed)|(unsigned)','',l_tmp,1)
    l_tmp = re.sub('\s','',l_tmp)
    if(re.search('\[.+\]',l_tmp)!=None):
        width = re.search('\[.+\]',l_tmp).group(0)
        l_tmp = re.sub('\[.+\]','',l_tmp)
    else:
        width = '1'
    # print(l_tmp)
    if(re.search('\w+(?=[;,\s\)])',l_tmp)!=None):
        port_name = re.search('\w+(?=[;,\s\)])',l_tmp).group(0)
    else:
        raise('Port name lost!')
    #print(width,port_name,signed_flag)
    return width,port_name,signed_flag

# 寻找模块例化中定义段parameter变量
def find_parameter(s):
    l_tmp = re.sub('parameter','',s)
    l_tmp = re.sub('\s','',l_tmp)
    name_search = re.search('\w+(?=\=)',l_tmp)#匹配=前的字母
    val_search = re.search('(?<=\=)[\w\+\-\*/\%\$\'`]+',l_tmp)#匹配=后的
    name = name_search.group(0)
    val = val_search.group(0)
    return name,val

# 寻找模块的输入输出
def find_input_output(lines):
    inst_dict = {'name':'','input':[],'output':[],'inout':[],'para':[]}
    string = lines2string(lines)
    # print(string)
    inst_dict['name'] = find_inst_name(string)
    output_pattern = re.compile('\Woutput[\[\s][\w\s\[\]:\+\-\*/\(\)%\{\}\'`]+[,|;]') 
# include 0-9 a-z A-Z [:] \n  匹配 [使用\[  44\s：匹配一个空白字符，比如：空格、\n \r \t  []表示一个集合   \[\s] 表示 [ ]  \w	匹配字母、数字、下划线。 \W	匹配非字母数字及下划线
# [ \[\s ] 第一组   [ \w\s\[\]:\+\-\*/\(\)%\{\}\'` ] 第二组
    input_pattern = re.compile('\Winput[\[\s][\w\s\[\]:\+\-\*/\(\)%\{\}\'`]+[,|;]') # include 0-9 a-z A-Z [:] \n 
    inout_pattern = re.compile('\Winout[\[\s][\w\s\[\]:\+\-\*/\(\)%\{\}\'`]+[,|;]') # include 0-9 a-z A-Z [:] \n 
    input_list = input_pattern.findall(string)
    # print('input_list is',input_list)
    output_list = output_pattern.findall(string)
    inout_list = inout_pattern.findall(string)
    
    para_pattern = re.compile('parameter\s+[A-Z]+\s+=\s+[0-9]*')
    para_list = para_pattern.findall(string)
    if(para_list != None):
        for l in para_list:
            inst_dict['para'].append(find_parameter(l))       
    else:
        inst_dict['para'] = []
    
    for l in input_list:
        inst_dict['input'].append(find_port_and_width(l))
    for l in output_list:
        inst_dict['output'].append(find_port_and_width(l))
    for l in inout_list:
        inst_dict['inout'].append(find_port_and_width(l))
    print('inst_dict is',inst_dict)
    return inst_dict


def max_len(ll,mode=0):
    max_len_num = 1
    for l in ll:
        if(len(l[mode])>max_len_num):
            max_len_num = len(l[mode])
    return max_len_num

def build_input_port_tb(in_list,mode='input'):
    max_in_len_width = max_len(in_list,0)
    max_in_len_signed = max_len(in_list,2)
    string = ''
    net_type = {'input':'reg','output':'wire','inout':'reg'}
    for in_port in in_list:
        in_name = in_port[1]
        width = in_port[0] if in_port[0]!='1' else ''
        signed_type = in_port[2]
        added_len_signed = max_in_len_signed - len(signed_type)
        added_len_width =  max_in_len_width - len(width)
        s = '%s %s '%(net_type[mode],signed_type) + added_len_signed*' '
        s += '%s'%(width) + added_len_width*' ' + ' %s;\n'%(in_name)
        string += s
    return string

def build_para_tb(in_list):
    max_in_len = max_len(in_list,0)
    string = ''
    for in_port in in_list:
        in_name = in_port[0]
        number = in_port[1]
        added_len = max_in_len - len(in_name)
        s = 'parameter %s '%(in_name) + added_len*' ' +'= %s;\n'%(number)
        string += s
    return string

# 寻找模块中的clk和rst
def find_clk_and_rst(in_list):
    rst = []
    s = ''
    for l in in_list:
        name = l[1]
        if(re.search('clk',name,re.I)!=None):
            s += 'always #1 %s'%name + ' = ~%s;\n'%name
    for l in in_list:
        name = l[1]
        if(re.search('rst',name,re.I)!=None):
            rst.append(name)
    return s,rst

def input_initial_tb(in_list,rst):
    string = 'initial begin\n'
    str_rst = ''
    for i in in_list:
        s = '  %s = 0;\n'%i[1]
        string += s
        if(i[1] in rst):
            s = '  #2  %s = 1;\n'%i[1]
            str_rst += s
    string += str_rst + 'end\n'
    return string
    
# 生成模块例化代码
def build_inst(inst_dict):
    inst_name = inst_dict['name']
    name_len = len(inst_name)
    #print('name_len is',name_len)
    string = inst_name
    if(inst_dict['para']==[]):
        para_string = ' '
    else:
        para_string = ' #('
        para_max_in_len = max_len(inst_dict['para'],0)
        for i,para_port in enumerate(inst_dict['para']):
            #print(i,para_port)
            para_name = para_port[0]
            added_len = para_max_in_len - len(para_name)
            s = (i!=0)*(name_len+3)*' '+'.%s '%(para_name) + added_len*' '+'( '+ para_name +added_len*' '+' )'+(i!=len(inst_dict['para'])-1)*','+(i==len(inst_dict['para'])-1)*')'+'\n'
            para_string += s 

    string += para_string
    string += 'U_'+ inst_name.upper()+'_0'
    # port inst
    port_list = inst_dict['input']+inst_dict['output']+inst_dict['inout']
    port_max_in_len = max_len(port_list,1)
    port_string = '(\n'
    for i,port in enumerate(port_list):
        port_name = port[1]
        port_width = port[0]
        #print(port_width,type(port_width))
        if port_width == '1':
            port_width = ''
        added_len = port_max_in_len - len(port_name)
        s =  '  .%s '%(port_name) + added_len*' '+'('+ port_name + port_width +')'+(i!=len(port_list)-1)*','+(i==len(port_list)-1)*');'+'\n'
        port_string += s
    
    string += port_string
    return string

# 增加dumpvar相关命令，vcs+verdi调试需要
def add_dumpvars(name):
    string = '\ninitial begin\n' + '    $fsdbDumpfile(\"%s.fsdb\");\n'%name + '    $fsdbDumpvars(0,%s);\n'%name +'    $fsdbDumpMDA();\n    #1000 $finish;\nend\n\n\n'
    return string

# 增加头部信息
def add_head(name):
    import time
    now_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()) 
    string = "// -----------------------------------------------------------------  \n//            ALL RIGHTS RESERVED                                     \n// ----------------------------------------------------------------- \n// Filename      : %s.v                                              \n// Created On    : %s                                                \n// ----------------------------------------------------------------- \n// Description:  Verilog testbench fiel Auto Generator Scripts       \n// Version : v0-first generate tb file use python script             \n// ----------------------------------------------------------------- \n"%(name,now_time)
    return string

# 生成tb
def build_tb(inst_dict):
    string = add_head(name='TB_'+inst_dict['name'])
    string += '`timescale 1ns/1ps\n'
    string += 'module %s();\n\n'%('TB_'+inst_dict['name'])
    string += '//parameter\n'
    string += build_para_tb(inst_dict['para'])
    string += '\n//input\n'
    string += build_input_port_tb(inst_dict['input'],'input')
    string += '\n//output\n'
    string += build_input_port_tb(inst_dict['output'],'output') 
    string += '\n//inout\n'
    string += build_input_port_tb(inst_dict['inout'],'inout')
    string_clk,rst = find_clk_and_rst(inst_dict['input'])
    string += '\n'+string_clk+'\n'
    string += input_initial_tb(inst_dict['input'],rst)
    string += '\n'
    string += build_inst(inst_dict)
    string += '\n'
    string += add_dumpvars(name='TB_'+inst_dict['name'])
    string += '\n'
    string += '\nendmodule\n'
    return string



lines = []
for l in vim.current.buffer[:]:
  lines.append(l+'\n')  # string in buffer do not contain '\n'

if __name__ == "__main__":
    module_index = find_moulde(lines)
    clear_lines = clear_commonts(lines,module_index)
    inst_dict = find_input_output(clear_lines[module_index[0]:module_index[1]])
    tb_string = build_tb(inst_dict)
    #print(tb_string)

# 调用vim的python接口，生成一个新的窗口，在新窗口构建tb
inst_name = 'tb_'+ (inst_dict['name']).lower() +'.v'
vim.command("badd %s"%inst_name)
buffer_num = len(vim.buffers)
print(buffer_num)
vim.command("tabnew")
vim.command("b"+str(buffer_num))
vim.current.buffer[:] = tb_string.split('\n')
#vim.command('NERDTree')
EOF
endfunction

