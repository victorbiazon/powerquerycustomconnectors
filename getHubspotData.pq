let 
    //Código da função
    func = 
        (
            apiKey as text,
            entityType as text,
            optional objectType as text,
            optional propertyList as list
        ) =>

        let
            Fonte = 
                if entityType = "objects"
                then getObjects(apiKey, objectType, propertyList)
                else if entityType = "properties"
                    then getProperties(apiKey, objectType)
                    else if entityType = "engagements"
                        then getEngagements(apiKey)
                        else if entityType = "calling dispositions"
                            then getDispositions(apiKey)
                            else if entityType = "owners"
                                then getOwners(apiKey)
                                else if entityType = "pipelines"
                                    then getPipelines(apiKey, objectType)
                                    else Table.FromValue("Tipo inválido.")
        in
            Fonte,

    //Funções auxiliares
    getObjects = 
        (
            apiKey as text,
            objectType as text,
            optional propertyList as list
        ) as table =>

        let
            object = 
                if objectType = "ticket"
                then "tickets"
                else if objectType = "company"
                    then "companies"
                    else if objectType = "deal"
                        then "deals"
                        else if objectType = "contact"
                            then "contacts"
                            else "",
            relativePath = Text.Combine({"crm/v3/objects/", object}),
            properties = Text.Combine(propertyList, ","),
            query = 
                if propertyList = null
                then
                    [
                        limit = "100",
                        associations = "company",
                        archived = "false",
                        after = "0",
                        hapikey = apiKey
                    ]
                else
                    [
                        limit = "100",
                        associations = "company",
                        properties = properties,
                        archived = "false",
                        after = "0",
                        hapikey = apiKey
                    ], 
            func = 
                (
                    optional after as text
                ) as record =>

                let
                    importar = 
                        Json.Document(
                            Web.Contents(
                                "https://api.hubapi.com/",
                                [
                                    RelativePath = relativePath,
                                    Query = Record.TransformFields(query, {"after", each after})
                                ]
                            ), 
                            65001
                        ),
                    dados = importar[results],
                    next = 
                        try
                            let
                                paging = importar[paging],
                                next = paging[next],
                                after = next[after]
                            in
                                after
                        otherwise null,
                    Retorno = 
                        if after = null
                        then [dados = null, next = null, previous = null]
                        else [dados = dados, next = next, previous = after]
                in
                    Retorno,
            Retorno = List.Generate(
                () => [dados = null, next = "0", previous = "0"],
                each _[previous] <> null,
                each func(Text.From(_[next])),
                each _[dados]
            ),
            #"Remover Primeira Linha" = List.RemoveNulls(Retorno),
            #"Convertido para Tabela" = Table.FromList(#"Remover Primeira Linha", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido3" = Table.ExpandListColumn(#"Convertido para Tabela", "Column1"),
            #"Column1 Expandido" = Table.ExpandRecordColumn(#"Column1 Expandido3", "Column1", {"id", "properties", "createdAt", "updatedAt", "archived", "associations"}, {"id", "properties", "createdAt", "updatedAt", "archived", "associations"})
        in
            #"Column1 Expandido",

    getProperties = 
        (
            apiKey as text,
            objectType as text
        )
        as table =>

        let
            relativePath = Text.Combine({"crm/v3/properties/", objectType}),
            importar = 
                Json.Document(
                    Web.Contents(
                        "https://api.hubapi.com/",
                        [
                            RelativePath = relativePath,
                            Query = 
                                [
                                    archived = "false",
                                    hapikey = apiKey
                                ]
                        ]
                    ), 
                    65001
                ),
            dados = importar[results],
            paraTabela = Table.FromList(dados, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido" = Table.ExpandRecordColumn(paraTabela, "Column1", {"updatedAt", "createdAt", "name", "label", "type", "fieldType", "description", "groupName", "options", "displayOrder", "calculated", "externalOptions", "hasUniqueValue", "hidden", "modificationMetadata", "formField"}, {"updatedAt", "createdAt", "name", "label", "type", "fieldType", "description", "groupName", "options", "displayOrder", "calculated", "externalOptions", "hasUniqueValue", "hidden", "modificationMetadata", "formField"})
        in    
            #"Column1 Expandido",

    getEngagements = 
        (
            apiKey as text    
        ) as table =>

        let
            func = 
                (
                    optional offset as text
                ) as record =>
                let
                    importar = 
                        Json.Document(
                            Web.Contents(
                                "https://api.hubapi.com/",
                                [
                                    RelativePath = "engagements/v1/engagements/paged",
                                    Query = 
                                        [
                                            limit = "250",
                                            offset = offset,
                                            hapikey = apiKey
                                        ]
                                ]
                            ), 
                            65001
                        ),
                    dados = importar[results],
                    next = 
                        if importar[hasMore] = true
                        then importar[offset]
                        else null,
                    Retorno = 
                        if offset = null
                        then [dados = null, next = null, previous = null]
                        else [dados = dados, next = next, previous = offset]
                in
                    Retorno,
            
            Retorno = List.Generate(
                () => [dados = null, next = "0", previous = "0"],
                each _[previous] <> null,
                each func(Text.From(_[next])),
                each _[dados]
            ),
            #"Remover Primeira Linha" = List.RemoveNulls(Retorno),
            #"Convertido para Tabela" = Table.FromList(#"Remover Primeira Linha", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido3" = Table.ExpandListColumn(#"Convertido para Tabela", "Column1"),
            #"Column1 Expandido" = Table.ExpandRecordColumn(#"Column1 Expandido3", "Column1", {"engagement", "associations", "attachments", "metadata"}, {"engagement", "associations", "attachments", "metadata"})
        in
            #"Column1 Expandido",

    getDispositions =
        (
            apiKey as text
        ) as table =>

        let
            importar = 
                Json.Document(
                    Web.Contents(
                        "https://api.hubapi.com/",
                        [
                            RelativePath = "calling/v1/dispositions",
                            Query = 
                                [
                                    hapikey = apiKey
                                ]
                        ]
                    ), 
                    65001
                ),
            #"Convertido para Tabela" = Table.FromList(importar, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido" = Table.ExpandRecordColumn(#"Convertido para Tabela", "Column1", {"id", "label", "deleted"}, {"id", "label", "deleted"})
        in
            #"Column1 Expandido",
    
    getOwners = 
        (
            apiKey as text
        ) as any =>

        let
            func = 
                (
                    optional after as text
                ) as record =>

                let
                    query = 
                        if after = "0"
                        then [
                            limit = "500",
                            hapikey = apiKey
                        ]
                        else [
                            limit = "500",
                            after = after,
                            hapikey = apiKey
                        ],
                    importar = 
                        Json.Document(
                            Web.Contents(
                                "https://api.hubapi.com/",
                                [
                                    RelativePath = "crm/v3/owners",
                                    Query = query
                                ]
                            ), 
                            65001
                        ),
                    dados = importar[results],
                    next = 
                        try
                            let
                                paging = importar[paging],
                                next = paging[next],
                                after = next[after]
                            in
                                after
                        otherwise null,
                    Retorno = 
                        if after = null
                        then [dados = null, next = null, previous = null]
                        else [dados = dados, next = next, previous = after]
                in
                    Retorno,
            
            Retorno = List.Generate(
                () => [dados = null, next = "0", previous = "0"],
                each _[previous] <> null,
                each func(Text.From(_[next])),
                each _[dados]
            ),
            #"Remover Primeira Linha" = List.RemoveNulls(Retorno),
            #"Convertido para Tabela" = Table.FromList(#"Remover Primeira Linha", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido" = Table.ExpandListColumn(#"Convertido para Tabela", "Column1"),
            #"Column1 Expandido1" = Table.ExpandRecordColumn(#"Column1 Expandido", "Column1", {"id", "email", "firstName", "lastName", "userId", "createdAt", "updatedAt", "archived", "teams"}, {"id", "email", "firstName", "lastName", "userId", "createdAt", "updatedAt", "archived", "teams"})
        in
            #"Column1 Expandido1",

    getPipelines = 
        (
            apiKey as text,
            objectType as text
        )
        as table =>

        let
            relativePath = Text.Combine({"crm/v3/pipelines/", objectType}),
            importar = 
                Json.Document(
                    Web.Contents(
                        "https://api.hubapi.com/",
                        [
                            RelativePath = relativePath,
                            Query = 
                                [
                                    archived = "false",
                                    hapikey = apiKey
                                ]
                        ]
                    ), 
                    65001
                ),
            dados = importar[results],
            paraTabela = Table.FromList(dados, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido" = Table.ExpandRecordColumn(paraTabela, "Column1", {"label", "displayOrder", "id", "stages", "createdAt", "updatedAt", "archived"}, {"label", "displayOrder", "id", "stages", "createdAt", "updatedAt", "archived"})
        in
            #"Column1 Expandido",

    //Documentação dos parâmetros
    Doc_func = 
        type function (
            apiKey as (type text meta [
                Documentation.FieldCaption = "Chave de API"
            ]),
            entityType as (type text meta [
                Documentation.FieldCaption = "Tipo",
                Documentation.AllowedValues = {"objects", "properties", "engagements", "calling dispositions", "owners", "pipelines"}
            ]),
             optional objectType as (type text meta [
                Documentation.FieldCaption = "Objeto",
                Documentation.AllowedValues = {"company", "contact", "deal", "ticket"}
            ]),
            optional propertyList as (type list meta [
                Documentation.FieldCaption = "Propriedades do Objeto"
            ])
        ) as table meta Documentation_Metadata,

    //Documentação da função
    Documentation_Metadata = 
        [
            Documentation.Name = "getHubspotData",
            Documentation.Description = "Função que retorna o conteúdo de objetos do Hubspot."/*,
            Documentation.Examples = 
                {
                    [
                        Description = "Exporta Dados sem parâmetros dinâmicos",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)""{'empresa':'000000','codigo':'00000','chave':'xxxxxxxxxxxxxxxx','tipoSaida':''}"",#(tab)//Parâmetro#(cr,lf,tab)false,#(tab)//Filtra Data#(cr,lf))",
                        Result = "Lista de registros do resultado do Exporta Dados, conteúdo variável"
                    ]
                }*/
        ]
in
    Value.ReplaceType(
        func, Doc_func
    )