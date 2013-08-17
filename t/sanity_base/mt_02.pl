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

% :- set_defaultAssertMt(myMt).

:- begin_pfc.

arity(loves,2).
baseKB:predicateConventionMt(loves,socialMt).

:- if(true).
mt1:like(sally,joe).
:- else.
:- rtrace(ain(==>mt1:like(sally,joe))).
%:- (ain(==>mt1:like(sally,joe))).
:- xlisting(like).
:- break.
:- rtrace(ain(==>mt1:like(sally,joe))).
:- break.
:- endif.

:- mt1:export(mt1:like/2).
:- header_sane:import(mt1:like/2).
:- xlisting(like/2).

genlMt(mt1,socialMt).

% this will raise upward the assertion.. is this OK?
:- (ain(like(A,B)==>loves(B,A))).

:- xlisting(loves/2).

:- mpred_must(socialMt:loves(joe,sally)).


