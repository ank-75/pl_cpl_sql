--------------------------------------------------------------------------------------------------------------------
--Определим функцию в БД, которая выполняет соединение с БД, выполняет запрос и возвращает данные-------------------
--------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION test.test_read_data_from_db(patt text)
 RETURNS text
 LANGUAGE pl_cpl_sql
AS $function$
declare 
        -- 
    cursor cur_main_pg is 
        select * 
         from /*##db=db_PG##*/ 
             apt.table_name nmr 
         where nmr.status = 0 and
               upper(nmr."name") like '%'||upper(patt)||'%'
        order by nmr."name"; 
    -- 
    ind  integer; 
    tmp  varchar2; 
begin 
    -- 
    dbms_output.put_line('--Start--'); 
    dbms_output.put_line('--patt='||patt);   
    -- 
   tmp := '';
    for rec in cur_main_pg loop
      if tmp = '' then
    	tmp := json_io.record_to_json(rec);
      else
        tmp := tmp||','||chr(10)||json_io.record_to_json(rec);
      end if;
    end loop; 
    return tmp;
END;
$function$
;