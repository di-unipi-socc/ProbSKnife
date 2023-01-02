%application(appId, listOfComponents)
application(cloudModel, [network, disk],[userConfig, appManager, authenticator, aiLearning, apiGateway, db]).
%application(iotApp2, [network, disk],[userConfig2, appManager, authenticator, aiLearning2, apiGateway, db]).

%software(componentId, ListOfData,ListOfCharacteristics,[LinkedHW, LinkedSW])
%hardware(componentId, ListOfData,ListOfCharacteristics,[LinkedHW, LinkedSW])
software( userConfig, 
            [userPreferences], %data
            [dataLibrary],% ListOfCharacteristics
            10,%link cost
            ([],[aiLearning, appManager, authenticator, db]) %linked components (hw,sw)
            ).

software( appManager, 
            [iotMeasurements, userRequests, iotCommands, iotEvents], 
            [],
            20,
            ([],[aiLearning, userConfig, authenticator, db]) 
            ).

software( authenticator, 
            [iotMeasurements, userRequests, iotCommands, iotEvents, networkData, userPreferences], 
            [tlsLibrary],
            30,
            ([],[userConfig, appManager, apiGateway]) 
            ).

software( aiLearning, 
            [iotMeasurements, userPreferences], 
            [aiFramework],
            10,
            ([],[userConfig, appManager]) 
            ).

software( apiGateway, 
            [networkData], 
            [networkLibrary],
            20,
            ([network],[authenticator]) 
            ).

software( db, 
            [iotMeasurements, userPreferences, cryptedData], 
            [dbms],
            50,
            ([disk],[userConfig, appManager]) 
            ).

software( userConfig2, 
            [userPreferences], %data
            [dataLibrary],% ListOfCharacteristics
            ([disk],[aiLearning2, appManager, authenticator, db]) %linked components (hw,sw)
            ).
software( aiLearning2, 
            [iotMeasurements, userPreferences], 
            [aiFramework],
            ([],[userConfig2, appManager]) 
            ).
%%%%%Hardware componenents

hardware( network, 
            [networkData], 
            [fromProvider],
            ([],[apiGateway]) 
            ).
hardware( disk, 
            [cryptedData], 
            [fromProvider],
            ([],[db]) 
            ).

hardware( disk2, 
            [cryptedData, userPreferences], 
            [fromProvider],
            ([],[db, userConfig2]) 
            ).

% lattice of security 
%g_lattice_higherThan(higherElement, lowerElement)
g_lattice_higherThan(top, medium).
g_lattice_higherThan(medium, low).

%policies for data
%tag(variable, security level)
tag(networkData, low).
tag(cryptedData, low).
tag(userPreferences, medium).
tag(userRequests, medium).
tag(iotMeasurements, top).
tag(iotEvents, top).
tag(iotCommands, top).

%policies for characteristics
tag(tlsLibrary, top).
tag(fromProvider, low).
tag(aiFramework, low).
tag(dbms, top).
tag(networkLibrary, low).
tag(dataLibrary, medium).



0.0::tagChange(networkData,    top);0.0::tagChange(networkData,    medium);1.0::tagChange(networkData,    low).
0.0::tagChange(cryptedData,    top);0.0::tagChange(cryptedData,    medium);1.0::tagChange(cryptedData,    low).
0.3::tagChange(userPreferences,top);0.5::tagChange(userPreferences,medium);0.2::tagChange(userPreferences,low).
0.3::tagChange(userRequests,   top);0.5::tagChange(userRequests,   medium);0.2::tagChange(userRequests,   low).
0.7::tagChange(iotMeasurements,top);0.2::tagChange(iotMeasurements,medium);0.1::tagChange(iotMeasurements,low).
0.7::tagChange(iotEvents,      top);0.2::tagChange(iotEvents,      medium);0.1::tagChange(iotEvents,      low).
0.8::tagChange(iotCommands,    top);0.1::tagChange(iotCommands,    medium);0.1::tagChange(iotCommands,    low).
0.7::tagChange(tlsLibrary,     top);0.2::tagChange(tlsLibrary,     medium);0.1::tagChange(tlsLibrary,     low).
0.1::tagChange(fromProvider,   top);0.3::tagChange(fromProvider,   medium);0.6::tagChange(fromProvider,   low).
0.2::tagChange(aiFramework,    top);0.3::tagChange(aiFramework,    medium);0.5::tagChange(aiFramework,    low).
0.5::tagChange(dbms,           top);0.3::tagChange(dbms,           medium);0.2::tagChange(dbms,           low).
0.1::tagChange(networkLibrary, top);0.2::tagChange(networkLibrary, medium);0.7::tagChange(networkLibrary, low).
0.3::tagChange(dataLibrary,    top);0.4::tagChange(dataLibrary,    medium);0.3::tagChange(dataLibrary,    low).




dataCharList([
    networkData,
    cryptedData,
    userPreferences,
    userRequests,
    iotMeasurements,
    iotEvents,
    iotCommands,
    tlsLibrary,
    fromProvider,
    aiFramework,
    dbms,
    networkLibrary,
    dataLibrary
]).
startingLabelling([
    (networkData, low),
    (cryptedData, low),
    (userPreferences, medium),
    (userRequests, medium),
    (iotMeasurements, top),
    (iotEvents, top),
    (iotCommands, top),
    (tlsLibrary, top),
    (fromProvider, low),
    (aiFramework, low),
    (dbms, top),
    (networkLibrary, low),
    (dataLibrary, medium)
]).