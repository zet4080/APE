% This file is part of the Attempto Parsing Engine (APE).
% Copyright 2008-2011, Attempto Group, University of Zurich (see http://attempto.ifi.uzh.ch).
%
% The Attempto Parsing Engine (APE) is free software: you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by the Free Software
% Foundation, either version 3 of the License, or (at your option) any later version.
%
% The Attempto Parsing Engine (APE) is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
% PURPOSE. See the GNU Lesser General Public License for more details.
%
% You should have received a copy of the GNU Lesser General Public License along with the Attempto
% Parsing Engine (APE). If not, see http://www.gnu.org/licenses/.


:- module(drs_to_xml, [
		drs_to_xmlatom/2,     % +DRS, -XMLAtom
		drs_to_xmlterm/2      % +DRS, -XMLTerm
	]).

/** <module> XML markup generation for Attempto DRS

This module creates an XML representation for an Attempto DRS (as
generated by APE).

@author Tobias Kuhn
@version 2009-03-16
*/

:- use_module(xmlterm_to_xmlatom, [
		xmlterm_to_xmlatom/2
	]).


% The following operators are used in the DRS.
:- op(400, fx, -).
:- op(400, fx, ~).
:- op(500, xfx, =>).
:- op(500, xfx, v).


%% drs_to_xmlatom(+DRS, -XMLAtom) is det
%
% Generates an XML representation (as an atom) for the DRS.

drs_to_xmlatom(DRS, XMLAtom) :-
    copy_term(DRS, DRSCopy),
    numbervars(DRSCopy, 0, _),
    drs_to_xmlterm(DRSCopy, XMLTerm),
    xmlterm_to_xmlatom(XMLTerm, XMLAtom).


%% drs_to_xmlterm(+DRS, -XMLTerm) is det
%
% Generates a Prolog-style XML representation (using element/3) for
% the DRS.

drs_to_xmlterm(drs(Dom, Conds), element('DRS', [domain=DomC], Content)) :-
    convert_vars(Dom, DomC),
    convert_conds(Conds, Content).


%% write_nv(+Arg, +Term) is det
%
% Writes Term onto the standard output. The variable representations
% '$VAR'(_) are printed as capital letters A, B, C, etc. Together with the
% format_predicate declaration, this allows us to use the placeholder '~v'
% in format/3.

write_nv(_, Term) :-
    write_term(Term, [numbervars(true), quoted(true)]).

% '~v' in format/3 is used to pretty print variables.
:- format_predicate(v, write_nv(_Arg, _Term)).


%% convert(+Term, -Atom) is det
%
% Converts Term into an atom. The variable representations '$VAR'(_) are
% pretty printed as capital letters.

convert(In, Out) :-
    format(atom(Out), '~v', [In]).


%% convert_vars(+VarList, -Atom) is det
%
% Converts a list of variables into an atom that contains the variable names
% separated by blank spaces.

convert_vars([], '').

% no blank space added, if there is only one variable
convert_vars([V], Out) :-
    convert(V, Out),
    !.

convert_vars([V|Rest], Out) :-
    convert_vars(Rest, OutRest),
    convert(V, OutV),
    atom_concat(' ', OutRest, OutTemp),
    atom_concat(OutV, OutTemp, Out).


%% convert_conds(+CondList, -XMLTerm) is det
%
% Generates a Prolog-style XML representation for the list of conditions.

convert_conds([], []).

convert_conds([Term-SentenceID/TokenID|RestIn], [element(Name, AttsC, [])|RestOut]) :-
    Term =.. [Name|Atts],
    create_attlist(Name, Atts, AttsTemp),
    append(AttsTemp, [sentid=SentenceID, tokid=TokenID], AttsC),
    convert_conds(RestIn, RestOut).

convert_conds([- DRSIn|RestIn], [element('Negation', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([~ DRSIn|RestIn], [element('NAF', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([can(DRSIn)|RestIn], [element('Possibility', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([must(DRSIn)|RestIn], [element('Necessity', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([should(DRSIn)|RestIn], [element('Recommendation', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([may(DRSIn)|RestIn], [element('Admissibility', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([question(DRSIn)|RestIn], [element('Question', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([command(DRSIn)|RestIn], [element('Command', [], [DRSOut])|RestOut]) :-
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).

convert_conds([CondsIn|RestIn], [element('PredicateGroup', [], CondsOut)|RestOut]) :-
	is_list(CondsIn),
    convert_conds(CondsIn, CondsOut),
    convert_conds(RestIn, RestOut).

convert_conds([DRSIn1 => DRSIn2|RestIn], [element('Implication', [], [DRSOut1,DRSOut2])|RestOut]) :-
    drs_to_xmlterm(DRSIn1, DRSOut1),
    drs_to_xmlterm(DRSIn2, DRSOut2),
    convert_conds(RestIn, RestOut).

convert_conds([DRSIn1 v DRSIn2|RestIn], [element('Disjunction', [], [DRSOut1,DRSOut2])|RestOut]) :-
    drs_to_xmlterm(DRSIn1, DRSOut1),
    drs_to_xmlterm(DRSIn2, DRSOut2),
    convert_conds(RestIn, RestOut).

convert_conds([V:DRSIn|RestIn], [element('Proposition', [ref=VC], [DRSOut])|RestOut]) :-
    convert(V, VC),
    drs_to_xmlterm(DRSIn, DRSOut),
    convert_conds(RestIn, RestOut).


%% create_attlist(+PredName, +ArgList, -XMLTerm) is det
%
% Creates a list of name/value pairs for the arguments ArgList of the
% predicate PredName.

create_attlist(modifier_pp, [X,Prep,Y], [ref=XC,prep=Prep,obj=YC]) :-
    convert(X, XC),
    convert(Y, YC).

create_attlist(modifier_adv, [X,Adv,Deg], [ref=XC,adverb=Adv,degree=Deg]) :-
    convert(X, XC).

create_attlist(object, [X,Noun,S,I,J,N], [ref=XC,noun=Noun,struct=S,unit=I,numrel=J,num=N]) :-
    convert(X, XC).

create_attlist(predicate, [E,Verb,X], [ref=EC,verb=Verb,subj=XC]) :-
    convert(E, EC),
    convert(X, XC).

create_attlist(predicate, [E,Verb,X,Y], [ref=EC,verb=Verb,subj=XC,obj=YC]) :-
    var_or_expr(Y),
    convert(E, EC),
    convert(X, XC),
    convert(Y, YC).

create_attlist(predicate, [E,Verb,X,Y,Z], [ref=EC,verb=Verb,subj=XC,obj=YC,indobj=ZC]) :-
    var_or_expr(Z),
    convert(E, EC),
    convert(X, XC),
    convert(Y, YC),
    convert(Z, ZC).

create_attlist(has_part, [X,Y], [group=XC,member=YC]) :-
    convert(X, XC),
    convert(Y, YC).

create_attlist(property, [X,Adj,Deg], [ref=XC,adj=Adj,degree=Deg]) :-
    convert(X, XC).

create_attlist(property, [X,Adj,Deg,Y], [ref=XC,adj=Adj,degree=Deg,obj=YC]) :-
    var_or_expr(Y),
    convert(X, XC),
    convert(Y, YC).

create_attlist(property, [X,Adj,Y,Deg,CompTarget,Z], [ref=XC,adj=Adj,obj1=YC,degree=Deg,comptarget=CompTarget,obj2=ZC]) :-
    convert(X, XC),
    convert(Y, YC),
    convert(Z, ZC).

create_attlist(query, [X,Q], [obj=XC,question=Q]) :-
    convert(X, XC).

create_attlist(relation, [X,R,Y], [obj1=XC,rel=R,obj2=YC]) :-
    convert(X, XC),
    convert(Y, YC).

create_attlist(formula, [A,O,B], [obj1=AC,op=O,obj2=BC]) :-
    convert(A, AC),
    convert(B, BC).


%% var_or_expr(+Term) is det
%
% Succeeds if the term is a (numbervared) variable or an ACE expression.

var_or_expr(X) :-
    X =.. [F,_|_],
    member(F, ['$VAR', string, int, real, expr, set, list, named]).
