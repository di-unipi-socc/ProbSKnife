application(smallExample,[],[north,center,south]).

software(north,
        [data1],
        [],
        10,
        ([],[center,south])
        ).

software(center,
        [data2],
        [],
        10,
        ([],[north,south])
        ).

software(south,
        [data3],
        [],
        10,
        ([],[north,center])
        ).

hardware(hw1,[],[],([],north)).

g_lattice_higherThan(top, low).

tag(data1, top).
tag(data2, top).
tag(data3, top).

tagChange(data1,top,0.7).
tagChange(data1,low,0.3).
tagChange(data2,top,0.2).
tagChange(data2,low,0.8).
tagChange(data3,top,0.6).
tagChange(data3,low,0.4).
