do
LANGUAGE pl_cpl_sql
$$
declare 
        -- 
    cursor cur_main_pg is 
        select * 
         from /*##db=db_PG##*/ 
             apt.n_medic_regs nmr 
         where nmr.status = 0
        order by nmr."name"; 
    -- 
    ind  integer; 
begin 
    -- Открытие курсоров в разных соединениях и отдельный запуск функций в них 
    -- 
    dbms_output.put_line('--Start--PG'); 
    -- 
    ind := 0;
    for rec in cur_main_pg loop
    	ind := ind + 1;
    	dbms_output.put_line(ind||') rec: '||json_io.record_to_json(rec));
    end loop; 
end; 
$$