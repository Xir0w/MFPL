/*
      mfpl.y

  Specifications for the MFPL language, bison input file.

      To create syntax analyzer:

        flex mfpl.l
        bison mfpl.y
        g++ mfpl.tab.c -o mfpl_parser
        mfpl_parser < inputFileName
 */

/*
 *  Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <cstring> 
#include <stack>
#include "SymbolTable.h"
using namespace std;


#define ADD   1
#define SUB   2
#define MULT  3
#define DIV  4
#define LT  5
#define GT 6
#define LE 7
#define GE 8 
#define EQ 9
#define NE 10
#define AND 11
#define OR 12
int lineNum = 1;

stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

bool isIntCompatible(const int theType);
bool isStrCompatible(const int theType);
bool isIntOrStrCompatible(const int theType);

void beginScope();
void endScope();
void cleanUp();
TYPE_INFO findEntryInAnyScope(const string theName);

void printRule(const char*, const char*);
int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  cleanUp();
  exit(1);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  char* text;
  int num;
  TYPE_INFO typeInfo;
};

/*
 *  Token declarations
*/
%token  T_LPAREN T_RPAREN 
%token  T_IF T_LETSTAR T_PRINT T_INPUT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT   
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type <text> T_IDENT T_STRCONST
%type <typeInfo> N_EXPR N_PARENTHESIZED_EXPR N_ARITHLOGIC_EXPR  
%type <typeInfo> N_CONST N_IF_EXPR N_PRINT_EXPR N_INPUT_EXPR 
%type <typeInfo> N_LET_EXPR N_EXPR_LIST  
%type <num> N_BIN_OP T_INTCONST N_ARITH_OP N_LOG_OP N_REL_OP  

/*
 *  Starting point.
 */
%start  N_START

/*
 *  Translation rules.
 */
%%
N_START   : N_EXPR
      {
      printRule("START", "EXPR");
      printf("\n---- Completed parsing ----\n\n");
      printf("\nValue of the expression is: ");
      switch($1.type)
      {
        case(INT):
        {
          printf("%i\n",$1.value.iValue);
          break;
        }
        case(STR):
        {
          printf("%s\n",$1.value.sValue);
          break;
        }
        case(BOOL):
        {
          if($1.value.bValue == true)
            printf("t\n");
          else
            printf("nil\n");
          break;
        }
      }
      return 0;
      }
      ;
N_EXPR    : N_CONST
      {
      printRule("EXPR", "CONST");
      $$.type = $1.type;
      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        }
      }
      }
                | T_IDENT
                {
      printRule("EXPR", "IDENT");
                  string ident = string($1);
                  TYPE_INFO exprTypeInfo = 
            findEntryInAnyScope(ident);
                  if (exprTypeInfo.type == UNDEFINED) {
                    yyerror("Undefined identifier");
                    return(0);
                }
                  $$.type = exprTypeInfo.type;
                                switch(exprTypeInfo.type)
      {
        case(INT):
        {
          $$.value.iValue = exprTypeInfo.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = exprTypeInfo.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = exprTypeInfo.value.bValue;
        } 
        }
                }
                | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
                {
      printRule("EXPR", "( PARENTHESIZED_EXPR )");
      $$.type = $2.type;
            switch($2.type)
      {
        case(INT):
        {
          $$.value.iValue = $2.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $2.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $2.value.bValue;
        } 
      }}
      ;
N_CONST   : T_INTCONST
      {
      printRule("CONST", "INTCONST");
                  $$.type = INT;
                  $$.value.iValue = $1;
      }
                | T_STRCONST
      {
      printRule("CONST", "STRCONST");
                  $$.type = STR; 
                  $$.value.sValue = $1;
      }
                | T_T
                {
      printRule("CONST", "t");
                  $$.type = BOOL; 
                  $$.value.bValue = true; 
      }
                | T_NIL
                {
      printRule("CONST", "nil");
      $$.type = BOOL; 
      $$.value.bValue = false;
      }
      ;
N_PARENTHESIZED_EXPR  : N_ARITHLOGIC_EXPR 
        {
        printRule("PARENTHESIZED_EXPR",
                                "ARITHLOGIC_EXPR");
        $$.type = $1.type;
              switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        }}
                      | N_IF_EXPR 
        {
        printRule("PARENTHESIZED_EXPR", "IF_EXPR");
        $$.type = $1.type;
                      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        } 
        }
                      | N_LET_EXPR 
        {
        printRule("PARENTHESIZED_EXPR", 
                                "LET_EXPR");
        $$.type = $1.type;
                      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        } 
        }
                      | N_PRINT_EXPR 
        {
        printRule("PARENTHESIZED_EXPR", 
              "PRINT_EXPR");
        $$.type = $1.type;
                      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        } 
        }
                      | N_INPUT_EXPR 
        {
        printRule("PARENTHESIZED_EXPR",
              "INPUT_EXPR");
        $$.type = $1.type;
                      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        } 
        }
                     | N_EXPR_LIST 
        {
        printRule("PARENTHESIZED_EXPR",
                  "EXPR_LIST");
        $$.type = $1.type;
                      switch($1.type)
      {
        case(INT):
        {
          $$.value.iValue = $1.value.iValue;
        }
        case(STR):
        {
          $$.value.sValue = $1.value.sValue;
        }
        case(BOOL):
        {
          $$.value.bValue = $1.value.bValue;
        } 
        } 
        }
        ;
N_ARITHLOGIC_EXPR : N_UN_OP N_EXPR
        {
        printRule("ARITHLOGIC_EXPR", 
                  "UN_OP EXPR");
                      $$.type = BOOL;
                      if($2.value.bValue)
                      {
                        $$.value.bValue = false;
                      }
                      else
                      {
                        $$.value.bValue = true;
                      }
        }
        | N_BIN_OP N_EXPR N_EXPR
        {
        printRule("ARITHLOGIC_EXPR", 
                  "BIN_OP EXPR EXPR");
                      $$.type = BOOL;
                      /*switch ($1)
                      {
                        case (ARITHMETIC_OP) :
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) {
                          yyerror("Arg 1 must be integer");
                          return(0);
                        }
                        if (!isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        break;

        case (LOGICAL_OP) :
                        break;

                      case (RELATIONAL_OP) :
                        if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                        break;
                      } */ // end switch
                      switch ($1)
                      {
                      case (ADD) :
                      {
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) {
                          yyerror("Arg 1 must be integer");
                          return(0);
                        }
                        if (!isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                          $$.value.iValue = $2.value.iValue + $3.value.iValue;
                          break;
                       }

                      case (SUB) :
                      {
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) {
                          yyerror("Arg 1 must be integer");
                          return(0);
                        }
                        if (!isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                          $$.value.iValue = $2.value.iValue - $3.value.iValue;
                          break;
                       }

                       case (MULT) :
                      {
                        
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) {
                          yyerror("Arg 1 must be integer");
                          return(0);
                        }
                        if (!isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                          $$.value.iValue = $2.value.iValue * $3.value.iValue;
                          break;
                       }

                      case (DIV) :
                      {
                        
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) {
                          yyerror("Arg 1 must be integer");
                          return(0);
                        }
                        if (!isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        if($3.value.iValue == 0)
                        {
                          return yyerror("attempted division by zero");
                        }
                        $$.value.iValue = $2.value.iValue / $3.value.iValue;
                        break;
                       }

                       case(AND):
                       {
                        $$.value.bValue = $2.value.bValue && $3.value.bValue;
                        break;
                       }
                       case(OR):
                       {
                        $$.value.bValue = $2.value.bValue || $3.value.bValue;
                        break;
                       }
                       case(LT):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                             if ($2.value.iValue < $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                           else                              if ($2.value.sValue < $3.value.sValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                        break;
                       }
                       case(GT):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                             if ($2.value.iValue > $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                          else                              if ($2.value.sValue > $3.value.sValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                        break;
                       }
                       case(LE):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                             if ($2.value.iValue <= $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                           else                              if ($2.value.sValue <= $3.value.sValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                        break;
                       }
                       case(GE):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                              if ($2.value.iValue >= $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                           else                              if ($2.value.sValue >= $3.value.sValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                        break;
                       }
                       case(EQ):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                            if ($2.value.iValue == $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                     else                             
                      if (strcmp($2.value.sValue,$3.value.sValue) == 0)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                       }
                       break;
                       case(NE):
                       {
                                                if (!isIntOrStrCompatible($2.type)) {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) {
                          yyerror("Arg 2 must be integer");
                          return(0);
                        }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                             if($2.type == INT){
                             if ($2.value.iValue != $3.value.iValue)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                           }
                              else   if   (strcmp($2.value.sValue , $3.value.sValue) != 0)
                             {
                              $$.value.bValue = true;
                             }
                             else
                             {
                              $$.value.bValue = false;                              
                             }
                        break;
                       }

                      }  // end switch
        }
                      ;
N_IF_EXPR     : T_IF N_EXPR N_EXPR N_EXPR
      {
      printRule("IF_EXPR", "if EXPR EXPR EXPR"); 
        if($2.type == INT)
        {
          $2.value.bValue = true;
        }
                if($2.value.bValue == false)
                {
                                       switch($4.type)
      {
        case(INT):
        {
          $$.value.iValue = $4.value.iValue;
          $$.type = INT;
          break;
        }
        case(STR):
        {
            $$.value.sValue = $4.value.sValue;
            $$.type = STR;
          break;
        }
        case(BOOL):
        {
          $$.value.bValue = $4.value.bValue;
                    $$.type = BOOL;
          break;
        } 
        }
                }
                else                                       switch($3.type)
      {
        case(INT):
        {
          $$.value.iValue = $3.value.iValue;
                    $$.type = INT;
          break;
        }
        case(STR):
        {
          $$.value.sValue = $3.value.sValue;
                    $$.type = STR;
          break;
        }
        case(BOOL):
        {
          $$.value.bValue = $3.value.bValue;
                    $$.type = BOOL;
          break;
        } 
        }

      }
      ;
N_LET_EXPR      : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN 
                  N_EXPR
      {
      printRule("LET_EXPR", 
            "let* ( ID_EXPR_LIST ) EXPR");
      endScope();
      $$.type = $5.type; 
      switch($5.type)
      {
        case(INT):
        {
          $$.value.iValue = $5.value.iValue;
                    $$.type = INT;
          break;
        }
        case(STR):
        {
          $$.value.sValue = $5.value.sValue;
                    $$.type = STR;
          break;
        }
        case(BOOL):
        {
          $$.value.bValue = $5.value.bValue;
                    $$.type = BOOL;
          break;
        } 
        }

      }
      ;
N_ID_EXPR_LIST  : /* epsilon */
      {
      printRule("ID_EXPR_LIST", "epsilon");
      }
                | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN 
      {
      printRule("ID_EXPR_LIST", 
                          "ID_EXPR_LIST ( IDENT EXPR )");
      string lexeme = string($3);
                 TYPE_INFO exprTypeInfo = $4;
                 printf("___Adding %s to symbol table\n", $3);
                 switch($4.type)
                 {
                   case(INT):{
                    bool success = scopeStack.top().addEntry
                    (SYMBOL_TABLE_ENTRY(lexeme,exprTypeInfo, $4.value.iValue));
                    if (! success) {
                      yyerror("Multiply defined identifier");
                      return(0);
                    } 
                    break;}
                  case(STR):{
                    bool success = scopeStack.top().addEntry
                    (SYMBOL_TABLE_ENTRY(lexeme,exprTypeInfo, $4.value.sValue));
                      if (! success) {
                        yyerror("Multiply defined identifier");
                        return(0);
                      } 
                    break;}
                  case(BOOL):{
                    bool success = scopeStack.top().addEntry
                    (SYMBOL_TABLE_ENTRY(lexeme,exprTypeInfo, $4.value.bValue));
                      if (! success) {
                        yyerror("Multiply defined identifier");
                        return(0);
                      } 
                    break;}
                 };
                 
      }
      ;
N_PRINT_EXPR    : T_PRINT N_EXPR
      {
      printRule("PRINT_EXPR", "print EXPR");
      switch($2.type)
      {
        case(INT):
        {
          printf("%i\n", $2.value.iValue);
          $$.type = INT;
          $$.value.iValue = $2.value.iValue;
          break;
        }
        case(STR):
        {
          printf("%s\n", $2.value.sValue);
          $$.type = STR;
          $$.value.sValue = $2.value.sValue;
          break;
        }
        case(BOOL):
        {
          printf("%i\n", $2.value.bValue);
          $$.type = BOOL;
          $$.value.bValue = $2.value.bValue;
          break;
        } 
        }
      }
      ;
N_INPUT_EXPR    : T_INPUT
      {
      printRule("INPUT_EXPR", "input");
      $$.type = INT_OR_STR;
      string inputHolder;
      getline(cin, inputHolder);
      
        if( (inputHolder.at(0) >= 48 && inputHolder.at(0) <= 57) || inputHolder.at(0) == '+' || inputHolder.at(0) == '-')
        {
          $$.type = INT;
        }
        else
        {
          $$.type = STR;
        }

        switch($$.type){
        	case(INT):
        	{
        		$$.value.iValue = atoi(inputHolder.c_str());
        		break;
        	}
        	case(STR):
        	{
        		$$.value.sValue = const_cast<char*>(inputHolder.c_str());
        		break;
        	}
        }
      
      }
      ;
N_EXPR_LIST     : N_EXPR N_EXPR_LIST  
      {
      printRule("EXPR_LIST", "EXPR EXPR_LIST");
      $$.type = $2.type;
      switch($2.type)
      {
        case(INT):{
          $$.value.iValue = $2.value.iValue;
          break;
        }
        case(STR):{
          $$.value.sValue = $2.value.sValue;
          break;
        }
        case(BOOL):{
          $$.value.bValue = $2.value.bValue;
          break;
        }
      }
      }
                | N_EXPR
      {
      printRule("EXPR_LIST", "EXPR");
                $$.type = $1.type;
      }
      ;
N_BIN_OP       : N_ARITH_OP
      {
      printRule("BIN_OP", "ARITH_OP");
      $$ = $1;
      }
      |
      N_LOG_OP
      {
      printRule("BIN_OP", "LOG_OP");
      $$ = $1;
      }
      |
      N_REL_OP
      {
      printRule("BIN_OP", "REL_OP");
      $$ = $1;
      }
      ;
N_ARITH_OP       : T_ADD
      {
      printRule("ARITH_OP", "+");
      $$ = ADD;
      }
                | T_SUB
      {
      printRule("ARITH_OP", "-");
      $$ = SUB;
      }
      | T_MULT
      {
      printRule("ARITH_OP", "*");
      $$ = MULT;
      }
      | T_DIV
      {
      printRule("ARITH_OP", "/");
      $$ = DIV;
      }
      ;
N_REL_OP       : T_LT
      {
      printRule("REL_OP", "<");
      $$ = LT;
      } 
      | T_GT
      {
      printRule("REL_OP", ">");
      $$ = GT;
      } 
      | T_LE
      {
      printRule("REL_OP", "<=");
      $$ = LE;
      } 
      | T_GE
      {
      printRule("REL_OP", ">=");
      $$ = GE;
      } 
      | T_EQ
      {
      printRule("REL_OP", "=");
      $$ = EQ;
      } 
      | T_NE
      {
      printRule("REL_OP", "/=");
      $$ = NE;
      }
      ; 
N_LOG_OP       : T_AND
      {
      printRule("LOG_OP", "and");
      $$ = AND;
      } 
      | T_OR
      {
      printRule("LOG_OP", "or");
      $$ = OR;
      }
      ;
N_UN_OP      : T_NOT
      {
      printRule("UN_OP", "not");
      }
      ;
%%

#include "lex.yy.c"
extern FILE *yyin;

bool isIntCompatible(const int theType) {
  return((theType == INT) || (theType == INT_OR_STR) ||
         (theType == INT_OR_BOOL) || 
         (theType == INT_OR_STR_OR_BOOL));
}

bool isStrCompatible(const int theType) {
  return((theType == STR) || (theType == INT_OR_STR) ||
         (theType == STR_OR_BOOL) || 
         (theType == INT_OR_STR_OR_BOOL));
}

bool isIntOrStrCompatible(const int theType) {
  return(isStrCompatible(theType) || isIntCompatible(theType));
}

void printRule(const char* lhs, const char* rhs) {
  printf("%s -> %s\n", lhs, rhs);
  return;
}

void beginScope() {
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

void endScope() {
  scopeStack.pop();
  printf("\n___Exiting scope...\n\n");
}

TYPE_INFO findEntryInAnyScope(const string theName) {
  TYPE_INFO info = {UNDEFINED};
  if (scopeStack.empty( )) return(info);
  info = scopeStack.top().findEntry(theName);
  if (info.type != UNDEFINED)
    return(info);
  else { // check in "next higher" scope
     SYMBOL_TABLE symbolTable = scopeStack.top( );
     scopeStack.pop( );
     info = findEntryInAnyScope(theName);
     scopeStack.push(symbolTable); // restore the stack
     return(info);
  }
}

void cleanUp() {
  if (scopeStack.empty()) 
    return;
  else {
        scopeStack.pop();
        cleanUp();
  }
}

int main(int argc, char** argv) {
  if(argc<2)
  {
    printf("You must specify a file in the command line!\n");
    exit(1);
  }
  yyin = fopen(argv[1],"r");
  do {
  yyparse();
  } while (!feof(yyin));

  cleanUp();
  return 0;
}
