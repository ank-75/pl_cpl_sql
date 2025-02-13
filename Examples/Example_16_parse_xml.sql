-----------------------------------------------------------------------------
--Парсинг (разбор) xml-документа (с помощью пакета xml_io)-------------------
-----------------------------------------------------------------------------
do
LANGUAGE pl_cpl_sql
$$
declare 
    xml_doc xml := '<documents xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.99">
    <move_order_notification action_id="999">
        <subject_id id="111" nm="555">00000000111111</subject_id>
        <receiver_id>00000000222222</receiver_id>
        <operation_date>2022-01-21T19:34:45+03:00</operation_date>
        <doc_num>29</doc_num>
        <doc_date>22.01.2025</doc_date>
        <turnover_type>1</turnover_type>
        <source>1</source>
        <contract_type>1</contract_type>
        <order_details>
            <union>
                <sgtin id="123456">0777775300504315W5JAKZPV5MB</sgtin>
                <cost>543.4</cost>
                <vat_value>49.4</vat_value>
            </union>
            <union>
                <sgtin>0777775300504315W5JAKZPX5N8</sgtin>
                <cost>543.4</cost>
                <vat_value>49.4</vat_value>
            </union>
            <union>
                <sscc_detail>
                    <sscc>888888805613246464</sscc>
                    <detail>
                        <gtin>99999999563762</gtin>
                        <series_number>L191024</series_number>
                        <cost>27.58</cost>
                        <vat_value>2.51</vat_value>
                    </detail>
                </sscc_detail>
                <cost>27.58</cost>
                <vat_value>2.51</vat_value>
            </union>
            <union>
                <sscc_detail>
                    <sscc>888888805613242015</sscc>
                    <detail>
                        <gtin>99999999563762</gtin>
                        <series_number>L191024</series_number>
                        <cost>27.58</cost>
                        <vat_value>2.51</vat_value>
                    </detail>
                </sscc_detail>
                <cost>27.58</cost>
                <vat_value>2.51</vat_value>
            </union>
            <union>
                <sscc_detail>
                    <sscc>888888805613242084</sscc>
                    <detail>
                        <gtin>99999999563762</gtin>
                        <series_number>L191024</series_number>
                        <cost>27.58</cost>
                        <vat_value>2.51</vat_value>
                    </detail>
                </sscc_detail>
                <cost>27.58</cost>
                <vat_value>2.51</vat_value>
            </union>
            <union>
                <sscc_detail>
                    <sscc>888888805613246433</sscc>
                    <detail>
                        <gtin>99999999563762</gtin>
                        <series_number>L191024</series_number>
                        <cost>27.58</cost>
                        <vat_value>2.51</vat_value>
                    </detail>
                </sscc_detail>
                <cost>27.58</cost>
                <vat_value>2.51</vat_value>
            </union>
            <union>
                <sscc_detail>
                    <sscc>888888805613246457</sscc>
                    <detail>
                        <gtin>99999999563762</gtin>
                        <series_number>L191024</series_number>
                        <cost>27.58</cost>
                        <vat_value>2.51</vat_value>
                    </detail>
                </sscc_detail>
                <cost>27.58</cost>
                <vat_value>2.51</vat_value>
            </union>
        </order_details>
    </move_order_notification>
</documents>';

  xml_doc_2   xml;
begin 
   dbms_output.put_line('----Start---');
  
   --Обходим массив с разобранными вершинами xml-документа
   for i in 1..xml_io.get_node_count(xml_doc) loop 
     if instr(xml_io.get_node_prop(xml_doc, i, 'path'), '/union/') > 0 then
	     --Выводим полную информацию про вершины документа, отобранные по данному условию
	     dbms_output.put_line('level='||xml_io.get_node_prop(xml_doc, i, 'level')||                          
	     					  ', type='||xml_io.get_node_prop(xml_doc, i, 'type')||
	                          ', path='||xml_io.get_node_prop(xml_doc, i, 'path')||
	                          ', name='||xml_io.get_node_prop(xml_doc, i, 'name')||
							  ', val='||xml_io.get_node_prop(xml_doc, i, 'value')||	                          
	                          ', attrs='||xml_io.get_node_all_attr(xml_doc,i)
	                         );
     end if;
   end loop; 
end; 
$$