#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include <windows.h>
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

PG_MODULE_MAGIC;

extern PGDLLEXPORT void _PG_init(void);
extern PGDLLEXPORT Datum pl_cpl_sql_call_handler(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum pl_cpl_sql_inline_handler(PG_FUNCTION_ARGS);
extern PGDLLEXPORT Datum pl_cpl_sql_validator(PG_FUNCTION_ARGS);

//-------------------------------------------------
//---��������� ��������� ��� �������� ����������--- 
//---���������/�������-----------------------------
typedef struct {
    char** ArgName;
    char** ArgValue;
    char** ArgType;
    int     count;
} TArgsArray;

//-------------------------------------------------
//---��������� ��������� ��� �������� ����������--- 
//---� ����������� ���������/�������---------------
typedef struct {
    char* ProcSrc;
    char* RetType;
} THandlerInputInfoCallRec;

//-------------------------------------------------
//---��������� ��������� ��� �������� ��������----- 
//---��� ���������� ���������� �����---------------
typedef struct {
    char* Errors;
    char* Messages;
    char* Result;
    int     OutType;
} THandlerResultCallRec;

//-------------------------------------------------
//---��������� ��������� ��� �������� ��������----- 
//---��� ���������� ���������� �����---------------
typedef struct {
    char* Errors;
    char* Messages;
    int     OutType;
} THandlerResultRec;

//-------------------------------------------------
//---��������� ��������� ��� �������� ����������--- 
//---� ����������� ���������/�������---------------
typedef struct {
    char* ProcSrc;
    char* RetType;
    char* Args;
} THandlerInputInfoRec;

//-------------------------------------------------
//typedef char* (__stdcall* My_Validator_Func)(char*);
typedef THandlerResultCallRec* (__stdcall* Pl_Cpl_Sql_Call_Func)(THandlerInputInfoCallRec*, TArgsArray*);

//-------------------------------------------------
typedef THandlerResultRec* (__stdcall* Pl_Cpl_Sql_inline_Func)(char*);

//-------------------------------------------------
typedef THandlerResultRec* (__stdcall* Pl_Cpl_Sql_Validate_Func)(THandlerInputInfoRec*);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
PG_FUNCTION_INFO_V1(pl_cpl_sql_call_handler);

//-----------------------------------------------------------
//---������� ���������� ���������----------------------------
void _ShowError(const char* mess) {
    ereport(ERROR,
        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
            errmsg("%s", mess)));
}

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// ���������� ������� ��� ���������� ����
Datum pl_cpl_sql_call_handler(PG_FUNCTION_ARGS) {

    HeapTuple	    pl_tuple;
    Datum		    ret;
    char* prosrc;
    bool		    isnull;
    FmgrInfo* arg_out_func;
    Form_pg_type    type_struct;
    HeapTuple	    type_tuple;
    Form_pg_proc    pl_struct;
    volatile MemoryContext proc_cxt = NULL;
    Oid* argtypes;
    char** argnames;
    char* argmodes;
    char* proname;
    Form_pg_type    pg_type_entry;
    Oid			    result_typioparam;
    Oid			    prorettype;
    FmgrInfo	    result_in_func;
    int			    numargs;
    size_t          length;

    PG_TRY();
    {
        //-----------------------------------------
        //---����������������� ���������, ������� ����� ���������� � �������� ������� ����������
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

        //---����� ����������� ���������/�������
        prosrc = DatumGetCString(DirectFunctionCall1(textout, ret));

        //-------------------------------------------------
        //---������� ����� ��������� ������� � ���������---
        //-------------------------------------------------
        length = strlen(prosrc);
        input_info_struct->ProcSrc = (char*)palloc((length + 1) * sizeof(char)); // �������� ������ ��� ������
        strcpy(input_info_struct->ProcSrc, prosrc);

        //-------------------------------------------------
        proc_cxt = AllocSetContextCreate(TopMemoryContext, "PL_CPL_SQL function", ALLOCSET_SMALL_SIZES);

        //-------------------------------------------------
        arg_out_func = (FmgrInfo*)palloc0(fcinfo->nargs * sizeof(FmgrInfo));

        //---������� ��������� �������
        numargs = get_func_arg_info(pl_tuple, &argtypes, &argnames, &argmodes);

        //-------------------------------------------------
        //---������ � �����������--------------------------
        TArgsArray args_arr;
        args_arr.count = numargs;
        args_arr.ArgName = palloc(numargs * sizeof(char*));
        args_arr.ArgValue = palloc(numargs * sizeof(char*));
        args_arr.ArgType = palloc(numargs * sizeof(char*));

        //-------------------------------------------------
        //---������� ��� ���������-------------------------
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
            //---�������� �������� ����������
            args_arr.ArgName[i] = argnames[i];
            args_arr.ArgValue[i] = value;
            args_arr.ArgType[i] = format_type_be(argtypes[i]);

            param_count++;
        }

        /* ��� ������������� �������� */
        prorettype = pl_struct->prorettype;
        ReleaseSysCache(pl_tuple);

        //---������� � ���������------------
        length = strlen(format_type_be(prorettype));
        input_info_struct->RetType = (char*)palloc((length + 1) * sizeof(char)); // �������� ������ ��� ������

        strcpy(input_info_struct->RetType, format_type_be(prorettype));

        char* exec_result;

        //-----------------------------------
        //--������������ ����������
        HINSTANCE hlib = LoadLibraryW(L"pl_cpl_sql_lib.dll");

        if (hlib) {
            Pl_Cpl_Sql_Call_Func ProcAdd = (Pl_Cpl_Sql_Call_Func)GetProcAddress(hlib, "pl_cpl_sql_call_handler");
            if (ProcAdd) {
                THandlerResultCallRec* result = ProcAdd(input_info_struct, &args_arr); // ����� ������� �� DLL

                FreeLibrary(hlib);

                //---��������� ��� ���������
                if (result->OutType == 1) {
                    //---���� ���� ������ ������
                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }

                if (result->OutType == 2) {
                    //---���� ���� ������ ��������� (����� ��������� ������ NOTICE)
                    elog(NOTICE, "%s", result->Messages);
                }

                if (result->OutType == 3) {
                    //---���� ���� ������ � ���������
                    elog(NOTICE, "%s", result->Messages);

                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }

                //---������ ���� ��� ������������� �������� �� void
                if (prorettype != VOIDOID) {
                    //---���������� ���������� ���������
                    length = strlen(result->Result);
                    exec_result = (char*)palloc((length + 1) * sizeof(char)); // �������� ������ ��� ������
                    strcpy(exec_result, result->Result);
                }
            }
            else {
                FreeLibrary(hlib);

                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("ERR-01: Runtime error!")));
            }
        }
        else {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("ERR-02: Library not found!")));
        }

        //---���� ��� ������������� ��������
        if (prorettype == VOIDOID)
        {
            //---�������
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

            //ReleaseSysCache(pl_tuple); // ����������� ���

            ret = InputFunctionCall(&result_in_func, exec_result, result_typioparam, -1);

        }
    }
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    //---���������� ��������
    PG_RETURN_DATUM(ret);
}

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
PG_FUNCTION_INFO_V1(pl_cpl_sql_inline_handler);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// ���������� ������� ��� ���������� ���������� ����� do $$ begin end; $$
Datum pl_cpl_sql_inline_handler(PG_FUNCTION_ARGS) {

    LOCAL_FCINFO(fake_fcinfo, 0);
    InlineCodeBlock* codeblock = (InlineCodeBlock*)DatumGetPointer(PG_GETARG_DATUM(0));

    //---������������������ ��������� ��� �������� ��������----
    THandlerResultRec* result_struct = (THandlerResultRec*)palloc(sizeof(THandlerResultRec));

    result_struct->Errors = (char*)palloc(100 * sizeof(char)); // �������� ������ ��� ������
    result_struct->Messages = (char*)palloc(100 * sizeof(char)); // �������� ������ ��� ������

    strcpy(result_struct->Errors, "");
    strcpy(result_struct->Messages, "");

    //--������������ ����������
    HINSTANCE hlib = LoadLibraryW(L"pl_cpl_sql_lib.dll");

    if (hlib) {
        Pl_Cpl_Sql_inline_Func ProcAdd = (Pl_Cpl_Sql_inline_Func)GetProcAddress(hlib, "pl_cpl_sql_inline_handler");
        if (ProcAdd) {

            THandlerResultRec* result = ProcAdd(codeblock->source_text); // ����� ������� �� DLL

            //---��������� ������
            FreeLibrary(hlib);

            //---��������� ��� ���������
            if (result->OutType == 1) {
                //---���� ���� ������ ������
                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("%s", result->Errors)));
            }

            if (result->OutType == 2) {
                //---���� ���� ������ ��������� (����� ��������� ������ NOTICE)
                elog(NOTICE, "%s", result->Messages);
            }

            if (result->OutType == 3) {
                //---���� ���� ������ � ���������
                elog(NOTICE, "%s", result->Messages);

                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("%s", result->Errors)));
            }

        }
        else {
            FreeLibrary(hlib);

            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("ERR-01: ������ ��� ���������� ���������!")));
        }
    }
    else {
        ereport(ERROR,
            (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                errmsg("ERR-02: ���������� �� �������!")));
    }
    PG_RETURN_VOID();

}

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// �������� ������� ����������
PG_FUNCTION_INFO_V1(pl_cpl_sql_validator);

//-----------------------------------------------------------
//-----------------------------------------------------------
//-----------------------------------------------------------
// ���������� ������� ��� ���������� �������� ������������ ����
Datum pl_cpl_sql_validator(PG_FUNCTION_ARGS) {

    Oid             func_oid = PG_GETARG_OID(0);

    char*           prosrc;
    int			    numargs;
    Oid*            argtypes;
    char**          argnames;
    char*           argmodes;
    Form_pg_proc    pl_struct;
    char*           proname;
    bool		    isnull;
    Datum		    ret;
    FmgrInfo*       arg_out_func;
    Form_pg_type    type_struct;
    HeapTuple	    type_tuple;
    int             i;
    int             pos;
    Oid*            types;
    Oid			    rettype;

    PG_TRY();
    {

        //-----------------------------------------
        //---����������������� ���������, ������� ����� ���������� � �������� ������� ����������
        THandlerInputInfoRec* input_info_struct = (THandlerInputInfoRec*)palloc(sizeof(THandlerInputInfoRec));

        input_info_struct->Args = (char*)palloc(200 * sizeof(char)); // �������� ������ ��� ������
        input_info_struct->RetType = (char*)palloc(100 * sizeof(char)); // �������� ������ ��� ������

        //---�������� �������� �� ���������
        strcpy(input_info_struct->Args, "");
        strcpy(input_info_struct->RetType, "");

        //-----------------------------------------
        // �������� ������ ������� �� OID
        HeapTuple tuple = SearchSysCache1(PROCOID, ObjectIdGetDatum(func_oid));
        if (!HeapTupleIsValid(tuple)) {
            ereport(ERROR, (errmsg("Function with OID %u does not exist", func_oid)));
        }

        //--------------------------------------
        //---������� ����� ������� ��� �������� � ����������
        pl_struct = (Form_pg_proc)GETSTRUCT(tuple);
        proname = pstrdup(NameStr(pl_struct->proname));

        ret = SysCacheGetAttr(PROCOID, tuple, Anum_pg_proc_prosrc, &isnull);
        if (isnull)
            elog(ERROR, "could not find source text of function \"%s\"",
                proname);

        //--------------------------------------
        //---����� ����������� ���������/�������
        prosrc = DatumGetCString(DirectFunctionCall1(textout, ret));

        size_t length = strlen(prosrc);
        input_info_struct->ProcSrc = (char*)palloc((length + 1) * sizeof(char)); // �������� ������ ��� ������

        //---�������� � ��������� ����� ����������� �������
        strcpy(input_info_struct->ProcSrc, prosrc);

        //--------------------------------------
        //---������� ���-�� ���������� �������
        numargs = get_func_arg_info(tuple, &types, &argnames, &argmodes);

        //--------------------------------------
        //---��������� ��� ��������� ���������/�������
        for (i = pos = 0; i < numargs; i++)
        {
            HeapTuple	    argTypeTup;
            Form_pg_type    argTypeStruct;
            char*           value;

            Assert(types[i] == pl_struct->proargtypes.values[pos]);

            argTypeTup = SearchSysCache1(TYPEOID, ObjectIdGetDatum(types[i]));
            if (!HeapTupleIsValid(argTypeTup))
                elog(ERROR, "cache lookup failed for type %u", types[i]);

            argTypeStruct = (Form_pg_type)GETSTRUCT(argTypeTup);

            ReleaseSysCache(argTypeTup);

            //---�������� ������ � ���������
            strcat(input_info_struct->Args, argnames[i]);
            strcat(input_info_struct->Args, ",");
        }

        //_ShowError(input_info_struct->Args);

        //---��������� ��� ������������� ��������
        rettype = pl_struct->prorettype;

        //---�������� ������ � ���������
        strcat(input_info_struct->RetType, format_type_be(rettype));

        //----------------------------------------------------
        //----------------------------------------------------
        //--������������ ����������

        HINSTANCE hlib = LoadLibraryW(L"pl_cpl_sql_lib.dll");

        if (hlib) {
            Pl_Cpl_Sql_Validate_Func ProcAdd = (Pl_Cpl_Sql_Validate_Func)GetProcAddress(hlib, "pl_cpl_sql_validator");
            if (ProcAdd) {
                THandlerResultRec* result = ProcAdd(input_info_struct); // ����� ������� �� DLL

                FreeLibrary(hlib);

                //---���� ������������ ������
                if (result->OutType == 1) {
                    ereport(ERROR,
                        (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                            errmsg("%s", result->Errors)));
                }
            }
            else {
                FreeLibrary(hlib);

                ereport(ERROR,
                    (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                        errmsg("ERR-01: ������ ��� ���������� ���������!")));
            }
        }
        else {
            ereport(ERROR,
                (errcode(ERRCODE_INVALID_PARAMETER_VALUE),
                    errmsg("ERR-02: ���������� �� �������!")));
        }

        ReleaseSysCache(tuple); // ����������� ���
    }
    PG_CATCH();
    {
        PG_RE_THROW();
    }
    PG_END_TRY();

    // ���� ��� �������� ��������, ������ ����������
    PG_RETURN_VOID();
}

//-----------------------------------------------------------
// �������� ������� ��� �������� �����
void _PG_init(void)
{
    // ����� ��������� � ��� ��� �������������
    elog(INFO, "pl_cpl_sql has been initialized.");
}
