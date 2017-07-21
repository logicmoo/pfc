/* <module>
%
%  PFC is a language extension for prolog.
%
%  It adds a new type of module inheritance
%
% Dec 13, 2035
% Douglas Miles
*/
%  was_module(header_sane,[]).

:- include(test_header).

:- mpred_trace_exec.
:- begin_pfc.

%:- sanity(current_prolog_flag(retry_undefined,true)).
%:- set_prolog_flag(retry_undefined,true).

:- mpred_test(mtHybrid(header_sane)).
:- mpred_test(\+ mtProlog(header_sane)).
%:- mpred_test(tMicrotheory(header_sane)).

genlMt(kb1,header_sane).

:- mpred_test(\+ mtProlog(kb1)).
:- mpred_test(\+ mtHybrid(kb1)).

%:- mpred_test(tMicrotheory(kb1)).


