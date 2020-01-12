function void error_display(string comp,string debug_verb,string err_msg);
    if(comp =="SLAVE")
        $display("%t,APB SLAVE %s: %s \n",$time,debug_verb, err_msg);
    else if(comp =="BRIDGE")
        $display("%t,APB BRIDGE %s: %s \n",$time,debug_verb, err_msg);
endfunction
