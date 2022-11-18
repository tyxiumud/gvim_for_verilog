function! Autoinstance()
python << EOF
import vim,re

lines = []
for l in vim.current.buffer[:]:
  lines.append(l+'\n')  # string in buffer do not contain '\n'

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

# 获取输入输出端口名以及位宽，符号
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
    
# 生成模块例化代码
def build_inst(inst_dict):
    inst_name = inst_dict['name']
    name_len = len(inst_name)
    # print('name_len is',name_len)
    string = inst_name
    if(inst_dict['para']==[]):
        para_string = ' '
    else:
        para_string = ' #(\n'
        para_max_in_len = max_len(inst_dict['para'],0)
        for i,para_port in enumerate(inst_dict['para']):
            para_name = para_port[0]
            added_len = para_max_in_len - len(para_name)
            s = (name_len+3)*' '+'.%s '%(para_name) + added_len*' '+'( '+ para_name +added_len*' '+' )'+(i!=len(inst_dict['para'])-1)*','+(i==len(inst_dict['para'])-1)*')'+'\n'
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
        if port_width == '1':
            port_width = ''
        added_len = port_max_in_len - len(port_name)
        s =  '  .%s '%(port_name) + added_len*' '+'('+ port_name + port_width +')'+(i!=len(port_list)-1)*','+(i==len(port_list)-1)*'\n);'+'\n'
        port_string += s
    
    string += port_string
    return string

if __name__ == "__main__":
    module_index = find_moulde(lines)
    clear_lines = clear_commonts(lines,module_index)
    inst_dict = find_input_output(clear_lines[module_index[0]:module_index[1]])
    inst_string = build_inst(inst_dict)
    #print(inst_string)

# 调用vim的python接口，生成一个新的窗口，在新窗口构建tb
vim.command("badd inst")
buffer_num = len(vim.buffers)
vim.command("tabnew")
vim.command("b"+str(buffer_num))
vim.current.buffer[:] = inst_string.split('\n')
EOF
endfunction

