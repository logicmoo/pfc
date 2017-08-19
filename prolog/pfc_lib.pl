/*   
  LogicMOO Base FOL/PFC Setup
% Dec 13, 2035
% Douglas Miles

*/
:- if(('$current_source_module'(SM),'context_module'(M),'$current_typein_module'(CM),asserta(baseKB:'using_pfc'(M,CM,SM,pfc_lib)))).
:- module(pfc_lib,[]).
:- set_prolog_flag(gc,false).
:- endif.

:- use_module(library(each_call_cleanup)).
:- user:use_module(library(must_trace)).
:- user:use_module(library(file_scope)).
:- set_prolog_flag_until_eof(access_level,system).

kb_wankage(M:F/A):- 
   M:multifile(M:F/A),
   M:module_transparent(M:F/A),
   M:dynamic(M:F/A),
   M:export(M:F/A),
   do_import(system,M,F,A),
   do_import(user,M,F,A),
   do_import(pfc_lib,M,F,A),
   do_import(header_sane,M,F,A),
   M:kb_global(M:F/A).

:- user:use_module(library(virtualize_source)).

:- dynamic(rdf_rewrite:(~)/1).
:- kb_wankage(rdf_rewrite:arity/2).
:- kb_wankage(baseKB:genlMt/2).
:- kb_wankage(baseKB:mtHybrid/1).
:- kb_wankage(baseKB:mtProlog/1).


:- user:use_module(library(hook_hybrid)).
:- user:use_module(library(logicmoo_util_strings)).


%:- listing(arity/2).
%:- listing(baseKB:_).

:- set_prolog_flag_until_eof(debug,true).

:- if(\+ current_prolog_flag(lm_pfc_lean,_)).
:- set_prolog_flag(lm_pfc_lean,true).
:- endif.


kb_shared_base(M:FA):-!,kb_shared(M:FA).
kb_shared_base(FA):-kb_local(baseKB:FA).
kb_local_base(M:FA):-!,kb_local(M:FA).
kb_local_base(FA):-kb_local(baseKB:FA).
kb_global_base(M:FA):-!,kb_global(M:FA).
kb_global_base(FA):- kb_local(baseKB:FA).



% :- kb_global_base(baseKB:genlMt/2).

:- kb_global(baseKB:mpred_prop/4).

:- baseKB:forall(between(1,11,A),kb_local(t/A)).
:- baseKB:forall(between(5,7,A),kb_local(mpred_f/A)).

:- user:use_module(library(loop_check)).
:- use_module(library(attvar_serializer)).
% :- kb_shared_base(baseKB:admittedArgument/3).
%:- set_prolog_flag(runtime_speed,0). % 0 = dont care
:- set_prolog_flag(runtime_speed, 1). % 1 = default
:- set_prolog_flag(runtime_debug, 1). % 2 = important but dont sacrifice other features for it
:- set_prolog_flag(runtime_safety, 3).  % 3 = very important
:- set_prolog_flag(unsafe_speedups, false).
:- set_prolog_flag(pfc_booted,false).

:- use_module(library(prolog_pack)).
pfc_rescan_autoload_pack_packages_part_1:- dmsg("SCAN AUTOLOADING PACKAGES..."),
 forall('$pack':pack(Pack, _),
  forall(((pack_property(Pack, directory(PackDir)),prolog_pack:pack_info_term(PackDir,autoload(true)))),
  (access_file(PackDir,write) -> prolog_pack:post_install_autoload(PackDir, [autoload(true)]) ; dmsg(cannot_access_file(PackDir,write))))),
 dmsg(".. SCAN AUTOLOADING COMPLETE"),!.
:- current_prolog_flag(lm_no_autoload,true) -> true; pfc_rescan_autoload_pack_packages_part_1.

:- meta_predicate pack_autoload_packages(0).
pack_autoload_packages(NeedExistingIndex):- 
 forall(user:expand_file_search_path(library(''),Dir),
  ignore(( (\+ NeedExistingIndex ; absolute_file_name('INDEX',_Absolute,[relative_to(Dir),access(read),file_type(prolog),file_errors(fail)]))->
   maybe_index_autoload_dir(Dir)))),
 reload_library_index.



maybe_index_autoload_dir(PackDir):- \+ access_file(PackDir,write),!,dmsg(cannot_write_autoload_dir(PackDir)).
maybe_index_autoload_dir(PackDir):- user:library_directory(PackDir), make_library_index(PackDir, ['*.pl']),dmsg(update_library_index(PackDir)).
maybe_index_autoload_dir(PackDir):- fail,
  prolog_pack:pack_info_term(PackDir,autoload(true)),
  prolog_pack:post_install_autoload(PackDir, [autoload(true)]) ,
  dmsg(post_install_autoload(PackDir,write)).  
maybe_index_autoload_dir(PackDir):- asserta(user:library_directory(PackDir)), make_library_index(PackDir, ['*.pl']), dmsg(created_library_index_for(PackDir)).

pfc_rescan_autoload_pack_packages_part_2 :- pack_autoload_packages(true).

:- current_prolog_flag(lm_no_autoload,true) -> true; pfc_rescan_autoload_pack_packages_part_2.



input_from_file:- prolog_load_context(stream,Stream),current_input(Stream).

:- module_transparent(intern_predicate/1).
:- module_transparent(intern_predicate/2).
intern_predicate(MFA):- '$current_typein_module'(To),intern_predicate(To,MFA).
intern_predicate(To,From:F/A):-!,
  From:module_transparent(From:F/A),
  From:export(From:F/A),To:export(From:F/A),To:export(From:F/A),
  From:compile_predicates([F/A]),system:lock_predicate(From:F/A),
  export(From:F/A),export(From:F/A),
  pfc:export(From:F/A),pfc:export(From:F/A),
  user:export(From:F/A),user:export(From:F/A),
  baseKB:export(From:F/A),baseKB:export(From:F/A),
  system:export(From:F/A),system:export(From:F/A),!.
intern_predicate(To,F/A):- '$current_source_module'(M),intern_predicate(To,M:F/A).

scan_missed_source:-!.
scan_missed_source:-
  prolog_load_context(file,File),scan_missed_source(File),
  prolog_load_context(source,SFile),!,
  (SFile==File-> true; scan_missed_source(SFile)).

scan_missed_source(SFile):-prolog_load_context(module,M),
   forall(source_file(Pred,SFile),scan_missed_source(M,Pred,SFile)).

scan_missed_source(M,Pred,SFile):- \+ M:clause(Pred,_,_),!,nop(dmsg(scan_missed_source(M,Pred,SFile))).
scan_missed_source(M,Pred,SFile):- doall((M:clause(Pred,_,Ref),
  (clause_property(Ref,file(SFile)) -> visit_pfc_file_ref(M,Ref) ; visit_pfc_non_file_ref(M,Ref)))).

visit_pfc_file_ref(M,Ref):- system:clause(H,B,Ref),dmsg(visit_pfc_file_ref(M,H,B)).
visit_pfc_non_file_ref(M,Ref):- system:clause(H,B,Ref),dmsg(visit_pfc_non_file_ref(M,H,B)).



:- intern_predicate(system,intern_predicate/1).

:- intern_predicate(system,intern_predicate/2).

'?='(ConsqIn):- fully_expand(ConsqIn,Consq),call_u(Consq),forall(mpred_why(Consq,Ante),wdmsg(Ante)).
'?=>'(AnteIn):- fully_expand(AnteIn,Ante),call_u(Ante),forall(mpred_why(Consq,Ante),wdmsg(Consq)).

:- lock_predicate(pfc:'?='/1).
:- lock_predicate(pfc:'?=>'/1).

:- thread_local(t_l:disable_px).

:- include('pfc2.0/mpred_header.pi').

/*
:- nop(kb_shared((
   bt/2, %basePFC
   hs/1, %basePFC
   nt/3, %basePFC
   pk/3, %basePFC
   pt/2, %basePFC
   que/1, %basePFC
   pm/1, %basePFC
   spft/3, %basePFC
   tms/1 %basePFC
   ))).
:- nop(kb_shared( ('~') /1)).
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DUMPST ON WARNINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

skip_warning(informational).
skip_warning(information).
skip_warning(debug).

skip_warning(discontiguous).
skip_warning(query).
skip_warning(banner).
skip_warning(silent).
skip_warning(debug_no_topic).
skip_warning(break).
skip_warning(io_warning).
skip_warning(interrupt).
skip_warning(statistics).
% skip_warning(check).
skip_warning(compiler_warnings).


skip_warning(T):- \+ compound(T),!,fail.
skip_warning(_:T):- !, compound(T),functor(T,F,_),skip_warning(F).
skip_warning(T):-compound(T),functor(T,F,_),skip_warning(F).
base_message(T1,T2,_):- skip_warning(T1);skip_warning(T2);(thread_self(M),M\==main).
base_message(_,_,_):- \+ current_predicate(dumpST/0),!.
base_message(T,Type,Warn):- dmsg(message_hook(T,Type,Warn)),dumpST,dmsg(message_hook(T,Type,Warn)),!,fail.

:- multifile prolog:message//1, user:message_hook/3.
user:message_hook(T,Type,Warn):- fail, ( \+ current_prolog_flag(runtime_debug,0)),
   catch(once(base_message(T,Type,Warn)),_,fail),fail.

% :- use_module(library(logicmoo_utils)).
:- if( \+ current_predicate(each_call_cleanup/3)).
:- user:use_module(library(each_call_cleanup)).
:- endif.

/*
% Make YALL require ">>" syntax (the problem was it autoloads when its sees PFC code containing "/" and gripes all the time)

disable_yall:- multifile(yall:lambda_functor/1),
   dynamic(yall:lambda_functor/1),
   with_no_mpred_expansions(use_module(yall:library(yall),[])),
   retractall(yall:lambda_functor('/')).

:- disable_yall.
*/

:- set_prolog_flag_until_eof(access_level,system).

/*
% baseKB:startup_option(datalog,sanity). %  Run datalog sanity tests while starting
% baseKB:startup_option(clif,sanity). %  Run datalog sanity tests while starting
:- set_prolog_flag(fileerrors,false).
:- set_prolog_flag(gc,false).
:- set_prolog_flag(gc,true).
:- set_prolog_flag(optimise,false).
:- set_prolog_flag(last_call_optimisation,false).
:- set_prolog_flag(debug,true).
:- debug.
*/
%:- guitracer.
%:- set_prolog_flag(access_level,system).

% :- set_prolog_flag(logicmoo_autoload,false).
% :- set_prolog_flag(logicmoo_autoload,true).

% must be xref-ing or logicmoo_autoload or used as include file
:- set_prolog_flag(logicmoo_include,lmbase:skip_module_decl).
% lmbase:skip_module_decl:- source_location(F,L),wdmsg(lmbase:skip_module_decl(F:L)),!,fail.
lmbase:skip_module_decl:- prolog_load_context(file,F), prolog_load_context(source,S),S\=F,!.
lmbase:skip_module_decl:-!,fail.
lmbase:skip_module_decl:-
   (current_prolog_flag(xref,true)-> false ;
    (current_prolog_flag(logicmoo_autoload,true)-> false ;
      ((prolog_load_context(file,F),  prolog_load_context(source,F))
             -> throw(error(format(":- include(~w).",[F]),reexport(F))) ; true))). 

%%% TODO one day :- set_prolog_flag(logicmoo_include,fail).


baseKB:mpred_skipped_module(eggdrop).
:- forall(current_module(CM),assert(baseKB:mpred_skipped_module(CM))).
:- retractall(baseKB:mpred_skipped_module(pfc_lib)).

% ================================================
% DBASE_T System
% ================================================    

:- multifile(baseKB:safe_wrap/4).
:- dynamic(baseKB:safe_wrap/4).

:- if((current_prolog_flag(runtime_debug,D),D>1)).
:- dmsg("Ensuring PFC Loaded").
:- endif.

:- use_module(library(subclause_expansion)).
:- reexport(library('pfc2.0/mpred_core.pl')).
:- system:reexport(library('pfc2.0/mpred_at_box.pl')).

:- user:use_module(library('file_scope')).
% :- virtualize_source_file.
:- module_transparent(baseKB:prologBuiltin/1).
:- multifile baseKB:prologBuiltin/1.
:- discontiguous baseKB:prologBuiltin/1.
:- dynamic baseKB:prologBuiltin/1.

:- reexport(library('pfc2.0/mpred_expansion.pl')).
:- reexport(library('pfc2.0/mpred_loader.pl')).
:- reexport(library('pfc2.0/mpred_database.pl')).
:- reexport(library('pfc2.0/mpred_listing.pl')).
:- reexport(library('pfc2.0/mpred_prolog_file.pl')).
:- reexport(library('pfc2.0/mpred_terms.pl')).


%:- autoload([verbose(false)]).



%baseKB:sanity_check:- findall(U,(current_module(U),default_module(U,baseKB)),L),must(L==[baseKB]).
baseKB:sanity_check:- doall((current_module(M),setof(U,(current_module(U),default_module(U,M),U\==M),L),
     wdmsg(imports_eache :- (L,[sees(M)])))).
baseKB:sanity_check:- doall((current_module(M),setof(U,(current_module(U),default_module(M,U),U\==M),L),wdmsg(imports(M):-L))).
baseKB:sanity_check:- doall((baseKB:mtProlog(M),
    setof(U,(current_module(U),default_module(M,U),U\==M),L),wdmsg(imports(M):-L))).


%:- rtrace((mpred_at_box:defaultAssertMt(G40331),rtrace(set_prolog_flag(G40331:unknown,warning)))).
%:- dbreak.
:- must(set_prolog_flag(abox:unknown,error)).
%:- locally(t_l:side_effect_ok,doall(call_no_cuts(module_local_init(abox,baseKB)))).
% :- forall(baseKB:sanity_check,true).


:- if( \+ prolog_load_context(reload,true)).
:-module_transparent(hook_database:ain/1).
:-module_transparent(hook_database:aina/1).
:-module_transparent(hook_database:ainz/1).
:-multifile(hook_database:ain/1).
:-multifile(hook_database:aina/1).
:-multifile(hook_database:ainz/1).
:-dynamic(hook_database:ain/1).
:-dynamic(hook_database:aina/1).
:-dynamic(hook_database:ainz/1).

:-module_transparent(mpred_core:mpred_ain/1).
:-module_transparent(mpred_core:mpred_aina/1).
:-module_transparent(mpred_core:mpred_ainz/1).
:-multifile(mpred_core:mpred_ain/1).
:-multifile(mpred_core:mpred_aina/1).
:-multifile(mpred_core:mpred_ainz/1).
:-dynamic(mpred_core:mpred_ain/1).
:-dynamic(mpred_core:mpred_aina/1).
:-dynamic(mpred_core:mpred_ainz/1).
:-hook_database:export(mpred_core:mpred_ain/1).
:-hook_database:export(mpred_core:mpred_aina/1).
:-hook_database:export(mpred_core:mpred_ainz/1).

:-asserta_new((hook_database:ainz(G):- !, mpred_ainz(G))).
:-asserta_new((hook_database:ain(M:G):- !, M:mpred_ain(M:G))).
:-asserta_new((hook_database:aina(G):- !, mpred_aina(G))).
:- endif.

% Load boot base file
user:lmbf:- 
 locally( set_prolog_flag(mpred_te,true),
  locally( set_prolog_flag(subclause_expansion,true),
   locally(set_prolog_flag(pfc_booted,false),
     with_umt(baseKB,
  prolog_statistics:time((reexport(baseKB:library(logicmoo/pfc/'system_base.pfc')))))))),
  set_prolog_flag(pfc_booted,true).

/*
:- set_prolog_flag(unknown,error).
:- set_prolog_flag(user:unknown,error).
:- set_prolog_flag(lmcode:unknown,error).
:- set_prolog_flag(baseKB:unknown,error).
*/
:- sanity(current_prolog_flag(unknown,error)).
:- sanity(current_prolog_flag(user:unknown,error)).

in_goal_expansion:- prolog_current_frame(F),
   prolog_frame_attribute(F,parent_goal,expand_goal(_,_,_,_)).

in_clause_expand(I):-  nb_current('$goal_term',Was),same_terms(I, Was),!,fail.
in_clause_expand(I):-  
   (nb_current_or_nil('$source_term',TermWas),\+ same_terms(TermWas, I)),
   (nb_current_or_nil('$term',STermWas),\+ same_terms(STermWas, I)),!,
   fail.
in_clause_expand(_).


% SHOULD NOT NEED THIS 
%          maybe_should_rename(M,O):-current_prolog_flag(do_renames,term_expansion),if_defined(do_renames(M,O)),!.
maybe_should_rename(O,O).


:- multifile(baseKB:ignore_file_mpreds/1).
:- dynamic(baseKB:ignore_file_mpreds/1).
:- multifile(baseKB:expect_file_mpreds/1).
:- dynamic(baseKB:expect_file_mpreds/1).

% baseKB:expect_file_mpreds(File):- prolog_load_context(file,File),t_l:current_lang(pfc).
% baseKB:expect_file_mpreds(File):- prolog_load_context(source,File),t_l:current_lang(pfc),source_location(SFile,_W), \+ baseKB:ignore_file_mpreds(SFile),!.

% file late late joiners
:- if( \+ prolog_load_context(reload,true)).
:- source_location(File, _)-> during_boot((asserta(baseKB:ignore_file_mpreds(File)))).
:- doall((module_property(M,file(File)),module_property(M,class(CT)),memberchk(CT,[library,system]),asserta(baseKB:ignore_file_mpreds(File)))).
%:- doall((source_file(File),asserta(baseKB:ignore_file_mpreds(File)))).
:- doall((virtualize_ereq(F,A),base_kb_dynamic(F,A))).
:- endif.

:- discontiguous(baseKB:'$pldoc'/4).


baseKB:ignore_file_mpreds(File):- atom(File),check_ignore_file_mpreds(File).

check_ignore_file_mpreds(File):- baseKB:expect_file_mpreds(File),!,fail.
check_ignore_file_mpreds(File):- ( atom_concat(_,'.pfc.pl',File);atom_concat(_,'.plmoo',File);atom_concat(_,'.clif',File);atom_concat(_,'.pfc',File)),!,asserta(baseKB:expect_file_mpreds(File)),fail.
check_ignore_file_mpreds(File):- baseKB:expect_file_mpreds(Stem),atom_concat(Stem,_,File),!,asserta(baseKB:expect_file_mpreds(File)),!,fail.
check_ignore_file_mpreds(File):- baseKB:ignore_file_mpreds(Stem),atom_concat(Stem,_,File),!,asserta(baseKB:ignore_file_mpreds(File)).
%check_ignore_file_mpreds(File):- module_property(M,file(File)),module_property(M,class(library)),asserta(baseKB:ignore_file_mpreds(File)),!.
% check_ignore_file_mpreds(File):- baseKB:ignore_file_mpreds(File),!.
% check_ignore_file_mpreds(File):- asserta(baseKB:expect_file_mpreds(File)),!,fail.

cannot_expand_current_file:- prolog_load_context(module,M),module_property(M,class(library)),!.
cannot_expand_current_file:- source_location(File,_)->baseKB:ignore_file_mpreds(File),!.


in_dialect_pfc:- is_pfc_file. % \+ current_prolog_flag(dialect_pfc,cwc),!.

%is_pfc_module(SM):- clause_b(using_pfc(SM,_, SM, pfc_toplevel)),!.
%is_pfc_module(SM):- clause_b(using_pfc(SM,_, SM, pfc_mod)),!,baseKB:mtCanAssert(SM).
is_pfc_module(SM):- clause_b(mtHybrid(SM)).

% First checks to confirm there is nothing inhibiting
must_not_be_pfc_file:- is_pfc_file0, rtrace(is_pfc_file0),trace,!,fail.
must_not_be_pfc_file:- !.

is_pfc_file:- current_prolog_flag(never_pfc,true),!,must_not_be_pfc_file,!,fail.
is_pfc_file:- notrace(is_pfc_file0),!.

is_pfc_file0:- source_location(File,_W),!,is_pfc_file(File),!.
is_pfc_file0:- prolog_load_context(module, M),is_pfc_module(M),!,clause_b(mtHybrid(M)).
%is_pfc_file0:- source_context_module(M),is_pfc_module(M).

:- meta_predicate is_pfc_file(:).
is_pfc_file(M:File):- is_pfc_file(M,File).
is_pfc_file(_,File):- atom_concat(_,'.pfc.pl',File);atom_concat(_,'.clif',File);atom_concat(_,'.plmoo',File);atom_concat(_,'.pfc',File),!.
is_pfc_file(_,File):- call(call,lmcache:mpred_directive_value(File, language, Lang)),!,(Lang==pfc;Lang==clif;Lang==fwd).
is_pfc_file(_,File):- baseKB:ignore_file_mpreds(File),!,fail.
is_pfc_file(_,File):- baseKB:expect_file_mpreds(File),!.
is_pfc_file(M,Other):- prolog_load_context(source, File),Other\==File,!,is_pfc_file(M,File).
%is_pfc_file(M,_):- prolog_load_context(module, SM), SM\==M,!, is_pfc_module(SM).
%is_pfc_file(M,_):- is_pfc_module(M).


sub_atom(F,C):- sub_atom(F,_,_,_,C).

only_expand(':-'(I), ':-'(M)):- !,in_dialect_pfc,fully_expand('==>'(I),M),!.
only_expand(I,OO):- fail, notrace(must_pfc(I,M)),  
  % current_why(S),!,
  S= mfl(Module, File, Line),source_location(File,Line),prolog_load_context(module,Module),
  conjuncts_to_list(M,O), !, %  [I]\=@=O,
  make_load_list(O,S,OO).

make_load_list([C|O],S,[baseKB:spft(C,S,ax), :- mpred_enqueue_w_mode(S,direct,C)|OO]):- clause_asserted(C),!, make_load_list(O,S,OO).
make_load_list([C|O],S,[C, baseKB:spft(C,S,ax), :- mpred_enqueue_w_mode(S,direct,C)|OO]):-  is_loadin(C),!,make_load_list(O,S,OO).
make_load_list(_,_,[]):-!.  

is_loadin(C):- strip_module(C,M,CC),is_loadin(M,CC).
is_loadin(_,CC):- must_pfc_p(CC),!.
is_loadin(_,(_:-_)):-!.
is_loadin(M,CC):- functor(CC,F,A),show_call(kb_local(M:F/A)),break.


must_pfc(IM,_):- is_never_pfc(IM),!,fail.
%must_pfc(IM,'==>'(IM)):- (in_dialect_pfc;must_pfc_p(IM)),!.
must_pfc(IM,SM:'==>'(IM)):- (in_dialect_pfc;must_pfc_p(IM)),!,source_module(SM),!.

must_pfc_exp(IM,MO):- in_dialect_pfc,fully_expand(IM,MO),!.
must_pfc_exp(IM,MO):- must_pfc_p(IM),!,fully_expand(IM,MO),!.

must_pfc_p('-->'(_,_)):-!,fail.
must_pfc_p(':-'(_,(CWC,_))):- atom(CWC),arg(_,v(bwc,fwc,awc,zwc),CWC),!.
must_pfc_p(':-'(_,(CWC,_))):- atom(CWC),arg(_,v(cwc),CWC),!,is_pfc_file.
must_pfc_p(':-'(Head,_)):- !, must_pfc_p(Head),!.
must_pfc_p('==>'(_,_)).
must_pfc_p('==>'(_)).
must_pfc_p('<==>'(_,_)).
must_pfc_p('<=='(_,_)).
must_pfc_p('<-'(_,_)).
must_pfc_p('<--'(_,_)).
must_pfc_p('->'(_,_)).
must_pfc_p('~'(_)).
must_pfc_p('--->'(_,_)).
must_pfc_p(_:P):- !, must_pfc_p(P),!.
must_pfc_p(FAB):-functor(FAB,F,A),must_pfc_fa(F,A),!.

must_pfc_fa(prologHybrid,_).
must_pfc_fa(F,A):- mpred_database_term(F,A,_),!.
must_pfc_fa(F,A):- clause_b(mpred_prop(M,F,A,_)),!, \+ clause_b(mpred_prop(M,F,A,prologBuiltin)).
must_pfc_fa(F,2):- sub_atom(F,'='),(atom_concat(_,'>',F);atom_concat('<',_,F)).


:- module_transparent(base_clause_expansion/2).

% module prefixed clauses for sure should be non pfc?
is_never_pfc(Var):- \+ callable(Var),!.
is_never_pfc(goal_expansion(_,_,_,_)).
is_never_pfc(':-'(_)).
is_never_pfc('-->'(_,_)):-!.
is_never_pfc(attr_unify_hook(_,_)):-!.

% TODO Maybe find a better spot?  see t/sanity_base/hard_mt_04a.pfc
is_never_pfc(M:C):- \+ is_never_pfc(C), \+ current_module(M),
   is_pfc_file,
   get_fileAssertMt(CMt),CMt:clause_b(mtHybrid(CMt)),
   CMt:ensure_abox(M),
   CMt:ain(genlMt(CMt,M)),!,fail.
is_never_pfc(_:C):- is_never_pfc(C).
is_never_pfc(':-'(C,_)):- !,is_never_pfc(C).


% base_clause_expansion(Var,Var):- current_prolog_flag(mpred_te,false),!.
base_clause_expansion(Var,Var):-var(Var),!.
base_clause_expansion( :- module(W,List), :- writetln(module(W,List))):- is_pfc_file,!.
base_clause_expansion(:-(I),:-(I)):- !.
base_clause_expansion(IM,':-'(ain(==>(IM)))):- atomic(IM),(sub_atom(IM,';');sub_atom(IM,'(')),!.
base_clause_expansion(IM,IM):- \+ callable(IM),!.
% base_clause_expansion(In,Out):- only_expand(In,Out),!.
base_clause_expansion(NeverPFC, EverPFC):- is_never_pfc(NeverPFC),!,NeverPFC=EverPFC.
base_clause_expansion('?=>'(I), ':-'(O)):- !, sanity(nonvar(I)), fully_expand('==>'(I),O),!. % @TODO NOT NEEDED REALY UNLESS DO mpred_expansion:reexport(library('pfc2.0/mpred_expansion.pl')),
base_clause_expansion(IN, ':-'(ain(ASSERT))):- must_pfc(IN,ASSERT).

/*

base_kb_dynamic(F,A):- ain(mpred_prop(M,F,A,prologHybrid)),kb_shared(F/A).

base_clause_expansion('==>'(I),  ':-'(ain('==>'(O)))):- !, sanity(nonvar(I)),must( fully_expand('==>'(I),O)),
   mpred_core:get_consequent_functor(O,F,A),kb_shared_base(F/A),ain(mpred_prop(M,F,A,prologHybrid)).
base_clause_expansion('<-'(I,M),':-'(ain('<-'(I,M)))):- !,mpred_core:get_consequent_functor(I,F,A),base_kb_dynamic(F,A).
base_clause_expansion(':-'(I,(Cwc,O)),':-'(ain(':-'(I,(Cwc,O))))):- Cwc == cwc,!,mpred_core:get_consequent_functor(I,F,A),base_kb_dynamic(F,A).
base_clause_expansion(I, O):- mpred_core:get_consequent_functor(I,F,A)->base_clause_expansion_fa(I,O,F,A),!. % @TODO NOT NEEDED REALY UNLESS DO mpred_core:reexport(library('pfc2.0/mpred_core.pl')),

% Checks if **should** be doing base_expansion or not      
:- module_transparent(base_clause_expansion_fa/4).
base_clause_expansion_fa(_,_,F,A):- clause_b(mpred_prop(M,F,A,prologBuiltin)),!,fail.
base_clause_expansion_fa(I,O,F,A):- (needs_pfc(F,A) -> true ; base_kb_dynamic(F,A)),
  base_clause_expansion('==>'(I),O).
base_clause_expansion_fa(_,_,F,A):- ain(mpred_prop(M,F,A,prologBuiltin)),!,fail.

:- module_transparent(needs_pfc/2).
needs_pfc(F,_):- (clause_b(functorIsMacro(F));clause_b(functorDeclares(F))).
needs_pfc(F,A):- base_kb_dynamic(F,A).
needs_pfc(F,A):- clause_b(mpred_prop(M,F,_,prologHybrid)), \+ clause_b(mpred_prop(M,F,A,prologBuiltin)).

maybe_builtin(M : _ :-_):- atom(M),!.
maybe_builtin(M : _ ):- atom(M),!.
maybe_builtin(I) :- nonvar(I),get_consequent_functor(I,F,A),
   \+ (clause_b(functorIsMacro(F));clause_b(functorDeclares(F));clause_b(mpred_prop(M,F,A,prologHybrid))),
   ain(prologBui sltin(F/A)).

*/

% :- ( defaultAssertMt(_)->true;set_defaultAssertMt(baseKB)).



:- sanity((clause(baseKB:ignore_file_mpreds(_),B),compound(B))).

%:- autoload([verbose(false)]).
:- if(false).
:- statistics.
:- endif.

% :- ain(arity(functorDeclares, 1)).
% Load boot base file
%:- dynamic(isa/2).

%is_lm_mod(M):-atom_concat('logicmoo_i_',_,M).
%is_lm_mod(M):-atom_concat('common_logic_',_,M).
%is_lm_mod(M):-atom_concat('mpred_',_,M).
%is_lm_mod(M):-atom_concat('baseK',_,M).
is_lm_mod(M):-atom_concat('mud_',_,M).
make_exported(op(X,Y,Z),:-op(X,Y,Z)).
make_exported(Pred,:-export(Pred)).

term_expansion_UNUSED(:-module(M,List),Pos,ExportList,Pos):- nonvar(Pos),
  ((prolog_load_context(file,File),\+ prolog_load_context(source,File));is_lm_mod(M)),
   maplist(make_exported,List,ExportList).

%:- thread_local t_l:side_effect_ok/0.
%.
%goal_expansion(I,P1,O,P2):- current_prolog_flag(mpred_te,true),mpred_te(goal,system,I,P1,O,P2).
%term_expansion(I,P1,O,P2):- current_prolog_flag(mpred_te,true),mpred_te(term,system,I,P1,O,P2).

pfc_clause_expansion(I,O):- nonvar(I),I\==end_of_file,base_clause_expansion(I,M),!,I\=@=M,
   ((
      maybe_should_rename(M,MO), 
      ignore(( \+ same_expandsion(I,MO), dmsg(pfc_clause_expansion(I)-->MO))),
      maybe_directive_to_clauses(MO,O),
      ignore(( O\==MO , (dmsg(directive_to_clauses(I)-->O)))))),!.

%maybe_directive_to_clauses(:- ain(A),Clauses):- loader_side_effect_capture_only(ain(A),Clauses).
%maybe_directive_to_clauses(:- ain(A),Clauses):- loader_side_effect_capture_only(ain(A),Clauses).
maybe_directive_to_clauses(O,O):-!.

same_expandsion(I,O):-var(I),!,I==O.
same_expandsion(I,O):-var(O),!,I==O.
same_expandsion(_:I,MO):-!,same_expandsion(I,MO).
same_expandsion(MO,_:I):-!,same_expandsion(I,MO).
same_expandsion('==>'(I),MO):-!,same_expandsion(I,MO).
same_expandsion(I,'==>'(MO)):-!,same_expandsion(I,MO).
same_expandsion(I,[MO|_]):-!,same_expandsion(I,MO).
same_expandsion(I, (:-ain(MO))):-!,same_expandsion(I,MO).
same_expandsion(I, (:-mpred_ain(MO))):-!,same_expandsion(I,MO).
same_expandsion(I,O):-I==O.

% prolog:message(ignored_weak_import(Into, From:PI))--> { nonvar(Into),Into \== system,dtrace(dmsg(ignored_weak_import(Into, From:PI))),fail}.
% prolog:message(Into)--> { nonvar(Into),functor_safe(Into,_F,A),A>1,arg(1,Into,N),\+ number(N),dtrace(wdmsg(Into)),fail}.

/*
:- multifile(user:clause_expansion/2).
user:clause_expansion(I,O):- pfc_clause_expansion(I,O).
*/

/*
:- multifile(clause_expansion/2).
clause_expansion(I,O):- pfc_clause_expansion(I,O).
*/


% term_expansion(I,P1,O,P2):- is_pfc_file,mpred_te(term,system,I,P1,O,P2).

module_uses_pfc(SM):- current_predicate(SM:'$uses_pfc_toplevel'/0).

:- multifile(pfc_goal_expansion/4).
:- dynamic(pfc_goal_expansion/4).
:- module_transparent(pfc_goal_expansion/4).
pfc_goal_expansion(I,P,O,PO):- 
 notrace(( \+ source_location(_,_),
     callable(I),          
     var(P), % Not a file goal     
     \+ current_prolog_flag(xref,true), 
     \+ current_prolog_flag(mpred_te,false),
     '$current_typein_module'(CM),
     prolog_load_context(module,SM),
     ((SM \== CM) -> module_uses_pfc(SM); module_uses_pfc(CM)), 
     (I \= (CM : call_u(_))), (I \= call_u(_)))),
     fully_expand(I,M),
     % notrace
     ((
     O=CM:call_u(M),
     PO=P)).


saveBaseKB:- tell(baseKB),listing(baseKB:_),told.

%baseKB:'==>'(Consq) :- sanity( \+ input_from_file), ain('==>'(Consq)),!.
%baseKB:'==>'(Ante,Consq):- sanity( \+ input_from_file), mpred_why(Consq,Ante).

:- set_prolog_flag(subclause_expansion,false).

:- multifile(system:clause_expansion/2).
:- module_transparent(system:clause_expansion/2).
:- module_transparent(pfc_clause_expansion/2).
:- system:export(pfc_clause_expansion/2).
:- '$set_source_module'(system).
system:clause_expansion(I,O):- pfc_clause_expansion(I,O).
:- '$set_source_module'(pfc_lib).
:- fixup_exports.

% :- ensure_abox(baseKB).

% :- dynamic(baseKB:spft/3).

:- multifile(system:goal_expansion/4).
:- dynamic(system:goal_expansion/4).
:- module_transparent(system:goal_expansion/4).
:- module_transparent(system:goal_expansion/2).

system:goal_expansion(I,P,O,PO):-
  % prolog_flag(mpred_te,true),
   pfc_goal_expansion(I,P,O,PO).

:- if(exists_source(library(retry_undefined))).

:- use_module(library(retry_undefined)).
:- install_retry_undefined.

:- else.

:- endif.

:- set_prolog_flag(subclause_expansion,true).
:- set_prolog_flag(mpred_te,true).

:- baseKB:ensure_loaded('pfclib/system_autoexec.pfc').

:- set_prolog_flag(mpred_te,false).
%:- set_prolog_flag(read_attvars,false).
:- set_prolog_flag(pfc_booted,true).
:- retractall(t_l:disable_px).

:- set_prolog_flag(mpred_te,true).
:- set_prolog_flag(retry_undefined,true).
