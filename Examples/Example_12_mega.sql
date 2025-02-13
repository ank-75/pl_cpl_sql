-------------------------------------------------------------------------------
--Демонстрация различных возможностей------------------------------------------
-------------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
    ind 		integer; 
    dt 			date; 
   
    cursor cur_main_1(arg_ varchar2) is 
        select * 
            from /*##db=db_PG##*/ 
                test.table_name_dub nmrd 
            where nmrd.status = 0 and 
                  nmrd.name like '%'||arg_||'%' 
           order by nmrd.name;
          
    cursor cur_main_2(arg_ varchar2) is 
        select nmrd.id,
               nmrd."name",
               nmrd.qt_doctor
            from /*##db=db_PG##*/ 
                test.table_name_dub nmrd 
            where nmrd.name like '%'||arg_||'%' 
           order by nmrd.name;          
               
    cnt 			integer; 
    patt_name 		varchar2; 
    start_id 		number; 
    c_d_id 			number(10); 
    c_d_name 		varchar2; 
    c_d_input_q 	number; 
    new_dt date; 
begin 
    patt_name := 'Релиф';
   
    dbms_output.put_line('---MegaTest-----'); 
    dbms_output.put_line('---Test 1-----'); 
   
    -- Откроем курсор и внутри цикла for выполним курсор 
    for rec in cur_main_1(patt_name) loop 
        select count(*) 
            into cnt 
        from /*##db=db_PG##*/ 
             test.table_name_dub mr 
        where mr.name = rec.name; 
        dbms_output.put_line(' Name='||rec.name||', cnt='||cnt); 
        dbms_output.put_line('rec.id='||rec.id); 
    end loop;
   
    dbms_output.put_line('---Test 2-----'); 
    ind := 0; 
   
    -- Откроем курсор без предварительного определения курсорной переменной 
    for rec in (select * 
                from /*##db=db_PG##*/ 
                    test.table_name_dub nmrd 
	            where nmrd.status = 0 and 
	                  nmrd.name like '%'||arg_||'%'
                order by nmrd.name) loop 
        ind := ind + 1; 
        dbms_output.put_line(ind||') Name='||rec.name||', id='||rec.id); 
    end loop; 
   
    dbms_output.put_line('---Test 3-----');
   
    start_id := 0; 
    -- Цикл for по индексу 
    for i in 1..5 loop 
        start_id := start_id + i; 
        dbms_output.put_line('start_id='||start_id); 
    end loop;
   
    dbms_output.put_line('---Test 4-----'); 
    ind := 0; 
    -- Цикл loop с выходом по условию 
    loop 
        ind := ind + 1; 
        dbms_output.put_line('ind='||ind); 
        if ind > 10 then 
            exit; 
        end if; 
    end loop; 
    dbms_output.put_line('Stop ind='||ind); 
   
   
    dbms_output.put_line('---Test 5-----');
    ind := 0; 
   
    -- Открытие курсора и выбор данных из него с помощью оператора - fetch 
    open cur_main_2(patt_name); 
    loop 
        ind := ind + 1;
        fetch cur_main_2 into c_d_id, c_d_name, c_d_input_q; 
        dbms_output.put_line(ind||') c_d_id='||c_d_id||', c_d_name='||c_d_name||', c_d_input_q='||c_d_input_q);
       
        if cur_main_2%notfound then 
            dbms_output.put_line('cur_main_2%notfound'); 
            exit; 
        else 
            dbms_output.put_line('cur_main_2%found'); 
        end if;
    end loop; 
    close cur_main_2; 
   
    dbms_output.put_line('---Test 6-----'); 
	
    -- Встроенные функции - sysdate, upper, lower, substr, instr, chr и т.д. 
    dbms_output.put_line('sysdate='||sysdate); 
    new_dt := sysdate + (1/12); 
    dbms_output.put_line('new_dt='||new_dt); 
    dbms_output.put_line('upper='||upper(patt_name)); 
    dbms_output.put_line('lower='||lower(patt_name)); 
    dbms_output.put_line('substr='||substr(patt_name, 1, 5)); 
    dbms_output.put_line('instr='||instr(patt_name, '1'));
   
end;
$$