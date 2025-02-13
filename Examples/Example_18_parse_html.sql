----------------------------------------------------------------------------------------------------------------------
--Загрузка содержимого новостного сайта (с помощью пакета http_io) и его парсинг (разбор) (с помощью пакета html_io)--
----------------------------------------------------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
    http_req http_io.req; 
    http_resp http_io.resp; 
   html_doc  html;
begin 
	dbms_output.put_line('Парсинг новостного сайта - https://www.yarnews.net/news/bymonth/2024/12/0/'||chr(10));

    http_req := http_io.begin_request('https://www.yarnews.net/news/bymonth/2024/12/0/', 'GET'); 
    http_io.set_header(http_req, 'Content-Type', 'html/text'); 
    http_resp := http_io.get_response(http_req); 
   
   	html_doc := http_resp.response_text;
  
    --Обходим массив с разобранными вершинами html-документа  
   	for i in 1..html_io.get_node_count(html_doc) loop
   	  /*
	     dbms_output.put_line('level='||html_io.get_node_prop(html_doc, i, 'level')||                          
	     					  ', type='||html_io.get_node_prop(html_doc, i, 'type')||
	                          ', path='||html_io.get_node_prop(html_doc, i, 'path')||
	                          ', name='||html_io.get_node_prop(html_doc, i, 'name')||
							  ', val='||html_io.get_node_prop(html_doc, i, 'value')||	                          
	                          ', attrs='||html_io.get_node_all_attr(html_doc,i)
	                         );   	
   	  */
     if (html_io.get_node_prop(html_doc, i, 'level') = 12) and
        ((instr(html_io.get_node_prop(html_doc, i, 'path'),'/a') > 0) or
         (instr(html_io.get_node_prop(html_doc, i, 'path'),'/h3') > 0) or          
         (instr(html_io.get_node_prop(html_doc, i, 'path'),'/span') > 0)         
        ) 
        then
          if html_io.get_node_prop(html_doc, i, 'value') != '' then
            --Выводим отобранную информацию на экран		  
	        dbms_output.put_line(html_io.get_node_prop(html_doc, i, 'value'));
	      end if;
     end if;
   end loop;   
end;    
$$; 
