gte(T1, T2):- T1=T2; (dif(T1,T2), maxType(T1,T2,T1)).
lt(T1, T2):- dif(T1,T2), minType(T1,T2,T1).

sumHW((CPU1, RAM1, HDD1),(CPU2, RAM2, HDD2),(CPU, RAM, HDD)) :-
    CPU is max(CPU1, CPU2),
    RAM is RAM1 + RAM2,
    HDD is HDD1 + HDD2.

labelSw(NewTags, Data,Characteristics, (MaxType,CharactSecType)):-
    dataLabel(NewTags, Data,Label),
    highestType(Label,MaxType),
    characteristicsLabel(NewTags, Characteristics, ListOfCharactTypes),
    lowestType(ListOfCharactTypes, CharactSecType).

%tagData(Labelling,Data,Label)
dataLabel(Labelling,[Data|Ds],[Type|Label]):-
    member((Data,Type),Labelling),
    dataLabel(Labelling,Ds, Label).
dataLabel(_,[],[]).
%tagCharacteristics(Labelling,ListOfCharacteristics,ListOfCharacteristicsTypes)
characteristicsLabel(_,[],[HighestType]):-
    highestType(HighestType).
characteristicsLabel(Labelling,[Charact|Characteristics],[Type|ListOfCharactTypes]):-
    member((Charact,Type),Labelling),
    characteristicsLabel(Labelling,Characteristics, ListOfCharactTypes).
characteristicsLabel(Labelling,[Charact|Characteristics],[HighestType|ListOfCharactTypes]):-
    \+ member((Charact,_),Labelling),
    highestType(HighestType),
    characteristicsLabel(Labelling,Characteristics, ListOfCharactTypes).


%find highest type in a list
highestType([T], T).
highestType([T1,T2|Ts], MaxT) :-
	highestType([T2|Ts], MaxTofRest),
	maxType(T1, MaxTofRest, MaxT).

%find max between two types
maxType(T1,T2,TMax):- once(innerMaxType(T1,T2,TMax)).
innerMaxType(X, X, X).
innerMaxType(X, Y, X) :- dif(X,Y), lattice_higherThan(X,Y).
innerMaxType(X, Y, Y) :- dif(X,Y), lattice_higherThan(Y,X).
innerMaxType(X, Y, Top) :-											%labels not reachable with path (on different branch) 
	dif(X,Y), \+ lattice_higherThan(X,Y), \+ lattice_higherThan(Y,X),
	lattice_higherThan(Top, X), lattice_higherThan(Top, Y),
	\+ (lattice_higherThan(Top, LowerTop), lattice_higherThan(LowerTop, X), lattice_higherThan(LowerTop, Y)).

%find lowest type in a list
lowestType([T], T).
lowestType([T1,T2|Ts], MinT) :-
	lowestType([T2|Ts], MinOfRest),
	minType(T1, MinOfRest, MinT).

%find min between two types
minType(T1,T2,TMin):- once(innerMinType(T1,T2,TMin)).
innerMinType(X, X, X).
innerMinType(X, Y, X) :- dif(X,Y), lattice_higherThan(Y,X).
innerMinType(X, Y, Y) :- dif(X,Y), lattice_higherThan(X,Y).
innerMinType(X, Y, Low) :-											%labels not reachable with path (on different branch) 
	dif(X,Y), \+ lattice_higherThan(X,Y), \+ lattice_higherThan(Y,X),
	lattice_higherThan(X,Low), lattice_higherThan(Y,Low),
	\+ (lattice_higherThan(HigherLow, Low), lattice_higherThan(X,HigherLow), lattice_higherThan(Y,HigherLow)).

%navigate the lattice    
lattice_higherThan(X, Y) :- g_lattice_higherThan(X,Y).
lattice_higherThan(X, Y) :- g_lattice_higherThan(X,W), lattice_higherThan(W,Y).

%highestType of the lattice
highestType(HighestType):- g_lattice_higherThan(HighestType,_), \+ (g_lattice_higherThan(_,HighestType)).

%lowest type of the lattice
lowestType(LowestType):- g_lattice_higherThan(_,LowestType), \+ (g_lattice_higherThan(LowestType,_)).

lowerType(This, Lower):- g_lattice_higherThan(This, Lower).
%lowerType(This, This):- lowestType(This).

%generates starting from a partitioning generate the list of links between components
%OldLinks = links accumulated (use [] at init)
%a link is (Sw1,Sw2,Cost,Status)
%the two software connected, the cost of changing the link and the status (in or out) of the link
links([((_,_),SWs)|Ps],OldLinks,NewLinks):-
    partitionLinks(SWs,OldLinks,PLinks),
    links(Ps,PLinks,NewLinks).
links([],L,L).
partitionLinks([SW|SWs],OldLinks,NewLinks):-
    software(SW,_,(_),C,(_,Linked)),
    createLinks(SW,Linked,[SW|SWs],C,OldLinks,SwLinks),
    partitionLinks(SWs,SwLinks,NewLinks).
partitionLinks([],L,L).

createLinks(Sw,[LSw|Linked],PSWs,SwCost,OldLinks,NewLinks):-
    \+ (member((Sw,LSw,_,_),OldLinks);member((LSw,Sw,_,_),OldLinks) ),
    software(LSw,_,_,C,_),
    LinkCost is SwCost + C,
    linksStatus(LSw,PSWs,Status),
    createLinks(Sw,Linked,PSWs,SwCost,[(Sw,LSw,LinkCost,Status)|OldLinks],NewLinks).
createLinks(Sw,[LSw|Linked],PSWs,SwCost,OldLinks,NewLinks):-
    (member((Sw,LSw,_,_),OldLinks);member((LSw,Sw,_,_),OldLinks)),
    createLinks(Sw,Linked,PSWs,SwCost,OldLinks,NewLinks).    
createLinks(_,[],_,_,L,L).

linksStatus(Sw,Sws,in):- member(Sw,Sws).
linksStatus(Sw,Sws,out):- \+ member(Sw,Sws).

partitionCharLabel(TChar,TData,safe):- gte(TChar,TData).
partitionCharLabel(TChar,TData,TChar):- lt(TChar,TData).

sumCosts([C|Cs],Tot):-
    sumCosts(Cs,SubTot),
    Tot is C + SubTot.
sumCosts([],0).