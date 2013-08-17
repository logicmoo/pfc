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

:- begin_pfc.
:- set_defaultAssertMt(cycKB1).

loves(sally,joe).

:- mpred_test(clause_u(cycKB1:loves(_,_))).

:- mpred_test(\+clause_u(baseKB:loves(_,_))).

:- mpred_test(\+clause_u(header_sane:loves(_,_))).




