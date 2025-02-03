#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "catalog/pg_proc.h"
#include "utils/syscache.h"

#include "access/htup_details.h"
#include "access/table.h"
#include "access/xact.h"
#include "catalog/catalog.h"
#include "catalog/dependency.h"
#include "catalog/indexing.h"
#include "catalog/objectaccess.h"
#include "catalog/pg_language.h"
#include "catalog/pg_namespace.h"
#include "catalog/pg_proc.h"
#include "catalog/pg_transform.h"
#include "catalog/pg_type.h"
#include "commands/defrem.h"
#include "executor/functions.h"
#include "funcapi.h"
#include "mb/pg_wchar.h"
#include "miscadmin.h"
#include "nodes/nodeFuncs.h"
#include "parser/parse_coerce.h"
#include "pgstat.h"
#include "rewrite/rewriteHandler.h"
#include "tcop/pquery.h"
#include "tcop/tcopprot.h"
#include "utils/acl.h"
#include "utils/lsyscache.h"
#include "utils/regproc.h"
#include "utils/rel.h"
#include <wchar.h>
#include <dlfcn.h>

PG_MODULE_MAGIC;

extern PGDLLEXPORT void _PG_init(void);
extern PGDLLEXPORT Datum pl_cpl_sql_call_handler(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum pl_cpl_sql_inline_handler(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum pl_cpl_sql_validator(PG_FUNCTION_ARGS);

//-------------------------------------------------
//---Определим структуру для передачи аргументов--- 
//---процедуры/функции-----------------------------
typedef struct {
    char** ArgName;
    char** ArgValue;
    char** ArgType;
    int     count;
} TArgsArray;

//-------------------------------------------------
//---Определим структуру для передачи информации--- 
//---о выполняемой процедуры/функции---------------
typedef struct {
    char* ProcSrc;
    char* RetType;
} THandlerInputInfoCallRec;

//-------------------------------------------------
//---Определим структуру для возврата значений----- 
//---при выполнении анонимного блока---------------
typedef struct {
    char* Errors;
    char* Messages;
    char* Result;
    int     OutType;
} THandlerResultCallRec;

//-------------------------------------------------
//---Определим структуру для возврата значений----- 
//---при выполнении анонимного блока---------------
typedef struct {
    char* Errors;
    char* Messages;
    int     OutType;
} THandlerResultRec;

//-------------------------------------------------
//---Определим структуру для передачи информации--- 
//---о проверяемой процедуры/функции---------------
typedef struct {
    char* ProcSrc;
    char* RetType;
    char* Args;
} THandlerInputInfoRec;

//-------------------------------------------------
//typedef char* My_Validator_Func(char*);
//typedef THandlerResultCallRec* (__stdcall* Pl_Cpl_Sql_Call_Func)(THandlerInputInfoCallRec*, TArgsArray*);
typedef THandlerResultCallRec* (*Pl_Cpl_Sql_Call_Func)(THandlerInputInfoCallRec*, TArgsArray*);

//-------------------------------------------------
//typedef THandlerResultRec* (__stdcall* Pl_Cpl_Sql_inline_Func)(char*);
typedef THandlerResultRec* (*Pl_Cpl_Sql_inline_Func)(char*);

//-------------------------------------------------
//typedef THandlerResultRec* (__stdcall* Pl_Cpl_Sql_Validate_Func)(THandlerInputInfoRec*);
typedef THandlerResultRec* (*Pl_Cpl_Sql_Validate_Func)(THandlerInputInfoRec*);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
PG_FUNCTION_INFO_V1(pl_cpl_sql_call_handler);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// Реализация функции для выполнения кода
Datum pl_cpl_sql_call_handler(PG_FUNCTION_ARGS) {

    HeapTuple	    pl_tuple;
    Datum		    ret;
    char* 			prosrc;
    bool		    isnull;
    FmgrInfo* 		arg_out_func;
    Form_pg_type    type_struct;
    HeapTuple	    type_tuple;
    Form_pg_proc    pl_struct;
    volatile MemoryContext proc_cxt = NULL;
    Oid* 			argtypes;
    char** 			argnames;
    char* 			argmodes;
    char* 			proname;
    Form_pg_type    pg_type_entry;
    Oid			    result_typioparam;
    Oid			    prorettype;
    FmgrInfo	    result_in_func;
    int			    numargs;
    size_t          length;

    PG_TRY();
    {
        //-----------------------------------------
        //---Проинициализируем структуру, которую будем передавать в качестве входных параметров
        THandlerInputInfoCallRec* input_info_struct = (THandlerInputInfoCallRec*)palloc(sizeof(THandlerInputInfoCallRec));

        //-----------------------------------------
        pl_tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(fcinfo->flinfo->fn_oid));

        //-----------------------------------------
        if (!HeapTupleIsValid(pl_tuple))
            elog(ERROR, "cache lookup failed for function %u",
                fcinfo->flinfo->fn_oid);

        //-----------------------------------------
        pl_struct = (Form_pg_proc)GETSTRUCT(pl_tuple);

        proname = pstrdup(NameStr(pl_struct->proname));

        ret = SysCacheGetAttr(PROCOID, pl_tuple, Anum_pg_proc_prosrc, &isnull);

        if (isnull)
            elog(ERROR, "could not find source text of function \"%s\"",
                proname);

        //---Текст исполняемой процедуры/функции
        prosrc = DatumGetCString(DirectFunctionCall1(textout, ret));

        //-------------------------------------------------
        //---Запишем текст процедуры функции в структуру---
        //-------------------------------------------------
        length = strlen(prosrc);
        input_info_struct->ProcSrc = (char*)palloc((length + 1) * sizeof(char)); // Выделяем память для строки
        strcpy(input_info_struct->ProcSrc, prosrc);

        //-------------------------------------------------
        proc_cxt = AllocSetContextCreate(TopMemoryContext, "PL_CPL_SQL function", ALLOCSET_SMALL_SIZES);

        //-------------------------------------------------
        arg_out_func = (FmgrInfo*)palloc0(fcinfo->nargs * sizeof(FmgrInfo));

        //---Получим аргументы функции
        numargs = get_func_arg_info(pl_tuple, &argtypes, &argnames, &argmodes);

        //-------------------------------------------------
        //---Массив с параметрами--------------------------
        TArgsArray args_arr;
        args_arr.count = numargs;
        args_arr.ArgName = palloc(numargs * sizeof(char*));
        args_arr.ArgValue = palloc(numargs * sizeof(char*));
        args_arr.ArgType = palloc(numargs * sizeof(char*));

        //-------------------------------------------------
        //---Обойдем все аргументы-------------------------
        int param_count = 0;
        int pos = 0;
        for (int i = 0; i < numargs; i++)
        {
            Oid			    argtype = pl_struct->proargtypes.values[i];
            char* value;

            Assert(argtypes[i] == pl_struct->proargtypes.values[pos]);

            type_tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(argtype));
            if (!HeapTupleIsValid(type_tuple))
                elog(ERROR, "cache lookup failed for type %u", argtype);

            type_struct = (Form_pg_type)GETSTRUCT(type_tuple);
            fmgr_info_cxt(type_struct->typoutput, &(arg_out_func[i]), proc_cxt);
            ReleaseSysCache(type_tuple);

            value = OutputFunctionCall(&arg_out_func[i], fcinfo->args[i].value);

            //----------------------------------
            //---Сохраним значения параметров
            args_arr.ArgName[i] = argnames[i];
            args_arr.ArgValue[i] = value;
            args_arr.ArgType[i] = format_type_be(argtypes[i]);

            param_count++;
        }

        /* Тип возвращаемого значения */
        prorettype = pl_struct->prorettype;
        ReleaseSysCache(pl_tuple);

        //---Запишем в структуру------------
        length = strlen(format_type_be(prorettype));
        input_info_struct->RetType = (char*)palloc((length + 1) * sizeof(char)); // Выделяем память для строки

        strcpy(input_info_struct->RetType, format_type_be(prorettype));

        char* exec_result;

        //-----------------------------------
        //--Присоединяем библиотеку
		void* hlib = dlopen("libpl_cpl_sql_lib.so", RTLD_NOW | RTLD_GLOBAL);

        if (hlib) {
            Pl_Cpl_Sql_Call_Func ProcAdd = (Pl_Cpl_Sql_Call_Func)dlsym(hlib, "pl_cpl_sql_call_handler");

            if (ProcAdd) {
                THandlerResultCallRec* result = ProcAdd(input_info_struct, &args_arr); // Вызов функции из DLL

		        //---Освободим память
				dlclose(hlib);

                //---Определим тип сообщения
                if (result->OutType == 1) {
                    //---Если была только ошибка
                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }

                if (result->OutType == 2) {
                    //---Если было только сообщение (вывод сообщения уровня NOTICE)
                    elog(NOTICE, "%s", result->Messages);
                }

                if (result->OutType == 3) {
                    //---Если была ошибка и сообщение
                    elog(NOTICE, "%s", result->Messages);

                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }

                //---Только если тип возвращаемого значения не void
                if (prorettype != VOIDOID) {
                    //---Обработаем полученный результат
                    length = strlen(result->Result);
                    exec_result = (char*)palloc((length + 1) * sizeof(char)); // Выделяем память для строки
                    strcpy(exec_result, result->Result);
                }
            }
            else {
                //---Освободим память
				dlclose(hlib);

                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("ERR-01: Runtime error!")));
            }
        }
        else {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("ERR-02: Библиотека не найдена!")));
        }

        //---Если нет возвращаемого значения
        if (prorettype == VOIDOID)
        {
            //---Выходим
            PG_RETURN_NULL();
        }
        else {
            type_tuple = SearchSysCache1(TYPEOID, ObjectIdGetDatum(prorettype));

            if (!HeapTupleIsValid(type_tuple))
                elog(ERROR, "cache lookup failed for type %u", prorettype);

            pg_type_entry = (Form_pg_type)GETSTRUCT(type_tuple);

            result_typioparam = getTypeIOParam(type_tuple);

            fmgr_info_cxt(pg_type_entry->typinput, &result_in_func, proc_cxt);
            ReleaseSysCache(type_tuple);

            ret = InputFunctionCall(&result_in_func, exec_result, result_typioparam, -1);

        }
    }
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    //---Возвращаем значение
    PG_RETURN_DATUM(ret);
}

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
PG_FUNCTION_INFO_V1(pl_cpl_sql_inline_handler);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// Реализация функции для выполнения анонимного блока do $$ begin end; $$
Datum pl_cpl_sql_inline_handler(PG_FUNCTION_ARGS) {

    LOCAL_FCINFO(fake_fcinfo, 0);
    InlineCodeBlock* codeblock = (InlineCodeBlock*)DatumGetPointer(PG_GETARG_DATUM(0));

    PG_TRY();
    {

		//--Присоединяем библиотеку
		void* hlib = dlopen("libpl_cpl_sql_lib.so", RTLD_NOW | RTLD_GLOBAL);

		if (hlib) {
		    Pl_Cpl_Sql_inline_Func ProcAdd = (Pl_Cpl_Sql_inline_Func)dlsym(hlib, "pl_cpl_sql_inline_handler");

		    if (ProcAdd) {

		        THandlerResultRec* result = ProcAdd(codeblock->source_text); // Вызов функции из DLL

		        //---Освободим память
				dlclose(hlib);

		        //---Определим тип сообщения
		        if (result->OutType == 1) {
		            //---Если была только ошибка
		            ereport(ERROR,
		                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
		                    errmsg("%s", result->Errors)));
		        }

		        if (result->OutType == 2) {
		            //---Если было только сообщение (вывод сообщения уровня NOTICE)
		            elog(NOTICE, "%s", result->Messages);
		        }

		        if (result->OutType == 3) {
		            //---Если была ошибка и сообщение
		            elog(NOTICE, "%s", result->Messages);

		            ereport(ERROR,
		                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
		                    errmsg("%s", result->Errors)));
		        }

		    }
		    else {
		        //---Освободим память
				dlclose(hlib);

		        ereport(ERROR,
		            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
		                errmsg("ERR-01: Ошибка при выполнении валидации!")));
		    }
		}
		else {
		    ereport(ERROR,
		        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
		            errmsg("ERR-02: Библиотека не найдена!")));
		}

	}
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    PG_RETURN_VOID();
}

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// Прототип функции валидатора
PG_FUNCTION_INFO_V1(pl_cpl_sql_validator);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// Реализация функции для выполнения проверки корректности кода
Datum pl_cpl_sql_validator(PG_FUNCTION_ARGS) {

    Oid             func_oid = PG_GETARG_OID(0);

    char* 			prosrc;
    int			    numargs;
    Oid* 			argtypes;
    char** 			argnames;
    char* 			argmodes;
    Form_pg_proc    pl_struct;
    char* 			proname;
    bool		    isnull;
    Datum		    ret;
    FmgrInfo* 		arg_out_func;
    Form_pg_type    type_struct;
    HeapTuple	    type_tuple;
    int             i;
    int             pos;
    Oid* 			types;
    Oid			    rettype;

    PG_TRY();
    {

        //-----------------------------------------
        //---Проинициализируем структуру, которую будем передавать в качестве входных параметров
        THandlerInputInfoRec* input_info_struct = (THandlerInputInfoRec*)palloc(sizeof(THandlerInputInfoRec));

        input_info_struct->Args = (char*)palloc(200 * sizeof(char)); // Выделяем память для строки
        input_info_struct->RetType = (char*)palloc(100 * sizeof(char)); // Выделяем память для строки

        //---Присвоим значения по умолчанию
        strcpy(input_info_struct->Args, "");
        strcpy(input_info_struct->RetType, "");

        //-----------------------------------------
        // Получаем кортеж функции по OID
        HeapTuple tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(func_oid));
        if (!HeapTupleIsValid(tuple)) {
            ereport(ERROR, (errmsg("Function with OID %u does not exist", func_oid)));
        }

        //--------------------------------------
        //---Получим текст функции для проверки и выполнения
        pl_struct = (Form_pg_proc)GETSTRUCT(tuple);
        proname = pstrdup(NameStr(pl_struct->proname));

        ret = SysCacheGetAttr(PROCOID, tuple, Anum_pg_proc_prosrc, &isnull);
        if (isnull)
            elog(ERROR, "could not find source text of function \"%s\"",
                proname);

        //--------------------------------------
        //---Текст исполняемой процедуры/функции
        prosrc = DatumGetCString(DirectFunctionCall1(textout, ret));

        size_t length = strlen(prosrc);
        input_info_struct->ProcSrc = (char*)palloc((length + 1) * sizeof(char)); // Выделяем память для строки

        //---Сохраним в структуру текст проверяемой функции
        strcpy(input_info_struct->ProcSrc, prosrc);

        //--------------------------------------
        //---Получим кол-во аргументов функции
        numargs = get_func_arg_info(tuple, &types, &argnames, &argmodes);

        //--------------------------------------
        //---Переберем все аргументы процедуры/функции
        for (i = pos = 0; i < numargs; i++)
        {
            HeapTuple	    argTypeTup;
            Form_pg_type    argTypeStruct;
            char* value;

            Assert(types[i] == pl_struct->proargtypes.values[pos]);

            argTypeTup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(types[i]));
            if (!HeapTupleIsValid(argTypeTup))
                elog(ERROR, "cache lookup failed for type %u", types[i]);

            argTypeStruct = (Form_pg_type)GETSTRUCT(argTypeTup);

            ReleaseSysCache(argTypeTup);

            //---Сохраним данные в структуру
            strcat(input_info_struct->Args, argnames[i]);
            strcat(input_info_struct->Args, ",");
        }

        //_ShowError(input_info_struct->Args);

        //---Определим тип возвращаемого значения
        rettype = pl_struct->prorettype;

        //---Сохраним данные в структуру
        strcat(input_info_struct->RetType, format_type_be(rettype));

        //----------------------------------------------------
        //----------------------------------------------------
        //--Присоединяем библиотеку

		void* hlib = dlopen("libpl_cpl_sql_lib.so", RTLD_NOW | RTLD_GLOBAL);

        if (hlib) {
            Pl_Cpl_Sql_Validate_Func ProcAdd = (Pl_Cpl_Sql_Validate_Func)dlsym(hlib, "pl_cpl_sql_validator");

            if (ProcAdd) {
                THandlerResultRec* result = ProcAdd(input_info_struct); // Вызов функции из DLL

                //---Освободим память
				dlclose(hlib);

                //---если обранужилась ошибка
                if (result->OutType == 1) {
                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }
            }
            else {
		        //---Освободим память
				dlclose(hlib);

                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("ERR-01: Ошибка при выполнении валидации!")));
            }
        }
        else {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("ERR-02: Библиотека не найдена!")));
        }

        ReleaseSysCache(tuple); // Освобождаем кэш
    }
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    // Если все проверки пройдены, просто возвращаем
    PG_RETURN_VOID();
}

//-----------------------------------------------------------
// Основная функция для создания языка
void _PG_init(void)
{
    // Вывод сообщения в лог при инициализации
    elog(INFO, "pl_cpl_sql has been initialized.");
}
