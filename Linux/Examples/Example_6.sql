 do
 LANGUAGE pl_cpl_sql
 $$
 declare 
    file1 text_io.file_type; 
    str_full varchar2; 
    str varchar2; 
begin 
    -- Откроем файл для чтения 
	file1 := text_io.fopen( '/home/alex/Examples/my_json_file.txt', 'r', 'UTF8'); 
	--Можем вычислить все содержимое за один раз 
	str_full := text_io.get_file_content(file1); 
	--Либо загружаем содержимое файла построчно 
	for i in 1..text_io.count_lines(file1) loop 
	    str := text_io.get_line( file1, i); 
	    dbms_output.put_line('line = '||str); 
	end loop; 
	-- Закроем файл 
    text_io.fclose( file1 ); 
end;        
$$