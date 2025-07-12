# Introduction

This document describes about the ArisiaScript language.
The ArisiaScript is frame oriented language to declare hierarchical GUI components.

This language borrows the concept of the *frame* from [The Newton Script Programming Language](https://www.newted.org/download/manuals/NewtonScriptProgramLanguage.pdf). The Newton Script supports Pascal like syntax, but the ArisiaScript supports TypeScript syntax.

## Sample
<pre>
{
        ok_button: {
                class:          "Button"
                title:          "OK"
                clicked: event %{
                        console.log("button pressed) ;
                %}
        }
}
</pre>


# Transpile 

The ArisiaScript code will be translated into the JavaScript code.

For example, following ArisiaScript will be transpiled into the JavaScript.
<pre>
{
        ok_button: {
                class:          "Button"
                title:          "OK"
                clicked: event %{
                        console.log("button pressed) ;
                %}
        }
}
</pre>

Generated JavaScript is:
<pre>
let ok_button = allocateFrame("Button") ;
ok_button.setValue("title", "OK") ;
ok_button.setEvent("clicked", function(){
	console.log("button pressed) ;
}) ;
</pre>


# Grammar

## Reserved words
<code>event</code>

## Syntax

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
    | event_function
    ;

object_list_opt
    : /* empty */
    | object_list
    ;

object_list:
    : object
    | object_list ',' object
    ;

simple_literal
    : STRING
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

event_function
    : _EVENT_ '%{' TEXT '}%'
    ;

</pre>


# References
* The NewtonScript Programming Language: https://www.newted.org/download/manuals/NewtonScriptProgramLanguage.pdf

# Related links
* [ArisiaCard](https://github.com/steel-wheels/ArisiaCard): The application which supports ArisiaStack.
* [Steel Wheels Project](https://github.com/steel-wheels/Project): The developper's web site



