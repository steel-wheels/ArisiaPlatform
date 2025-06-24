# Introduction

This document describes about the ArisiaScript language.
The ArisiaScript is frame oriented language to declare hierarchical GUI components.

This language borrows the concept of the *frame* from [The Newton Script Programming Language](https://www.newted.org/download/manuals/NewtonScriptProgramLanguage.pdf). The Newton Script supports Pascal like syntax, but the ArisiaScript supports TypeScript syntax.

## Sample
<pre>
{
        ok_button: {
                class:          Button
                title:          "OK"
                clicked: event() %{
                        console.log("button pressed) ;
                %}
        }
}
</pre>


# Transpile 

The ArisiaScript code will be translated into the JavaScript code.


# Grammar

<pre>
frame
    :  '{' frame_slot_list_opt '}'
    ;

frame_slot_list_opt
    : /* empty */
    | frame_slot_list
    ;

frame_slot_list
    : frame_slot
    | frame_slot_list ',' frame_slot
    ;

frame_slot
    | SYMBOL ':' object
    ;

object
    : simple_literal
    | path_expression
    | frame
    | array
    ;

simple_literal
    : CHARACTER
    | STRING
    | INTEGER
    | REAL
    | TRUE
    | FALSE
    | NIL
    ;

path_expression
    : SYMBOL
    | path_expression '.' SYMBOL
    ;

array
    : '[' object_list_opt ']'
    ;

</pre>


# References

* The NewtonScript Programming Language: https://www.newted.org/download/manuals/NewtonScriptProgramLanguage.pdf



