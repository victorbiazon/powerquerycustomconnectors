let 
    //Código da função
    func = 
        (
            entityType as text,
            optional objectType as text,
            optional propertyList as list
        ) =>

        let
            Fonte = 
                if entityType = "objects"
                then getObjects(objectType, propertyList)
                else if entityType = "properties"
                    then getProperties(objectType)
                    else getEngagements()
        in
            Fonte,

    //Funções auxiliares
    getObjects = 
        (
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
                        archived = "false",
                        after = "0",
                        hapikey = "af52ca65-599a-4d1a-aa5c-018dce40bff1"
                    ]
                else
                    [
                        limit = "100",
                        properties = properties,
                        archived = "false",
                        after = "0",
                        hapikey = "af52ca65-599a-4d1a-aa5c-018dce40bff1"
                    ], 
            func = 
                (
                    relativePath as text,
                    query as record
                ) as record =>

                let
                    importar = 
                        Json.Document(
                            Web.Contents(
                                "https://api.hubapi.com/",
                                [
                                    RelativePath = relativePath,
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
                    Retorno = [dados = dados, relativePath = relativePath, query = Record.TransformFields(query, {"after", each next})]
                in
                    Retorno,
            Retorno = List.Generate(
                () => [dados = null, relativePath = relativePath, query = query],
                each _[query][after] <> null,
                each func(_[relativePath], _[query]),
                each _[dados]
            ),
            #"Remover Primeira Linha" = List.RemoveNulls(Retorno),
            #"Convertido para Tabela" = Table.FromList(#"Remover Primeira Linha", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido3" = Table.ExpandListColumn(#"Convertido para Tabela", "Column1"),
            #"Column1 Expandido" = Table.ExpandRecordColumn(#"Column1 Expandido3", "Column1", {"id", "properties", "createdAt", "updatedAt", "archived"}, {"id", "properties", "createdAt", "updatedAt", "archived"})
        in
            #"Column1 Expandido",

    getProperties = 
        (
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
                                    hapikey = "af52ca65-599a-4d1a-aa5c-018dce40bff1"
                                ]
                        ]
                    ), 
                    65001
                ),
            dados = importar[results],
            paraTabela = Table.FromList(dados, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
        in
            paraTabela,

    getEngagements = 
        () as table =>

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
                                            hapikey = "af52ca65-599a-4d1a-aa5c-018dce40bff1"
                                        ]
                                ]
                            ), 
                            65001
                        ),
                    dados = importar[results],
                    next = try importar[offset] otherwise null,
                    Retorno = [dados = dados, next = next]
                in
                    Retorno,
            
            Retorno = List.Generate(
                () => [dados = null, next = "0"],
                each _[next] <> null,
                each func(Text.From(_[next])),
                each _[dados]
            ),
            #"Remover Primeira Linha" = List.RemoveNulls(Retorno),
            #"Convertido para Tabela" = Table.FromList(#"Remover Primeira Linha", Splitter.SplitByNothing(), null, null, ExtraValues.Error),
            #"Column1 Expandido3" = Table.ExpandListColumn(#"Convertido para Tabela", "Column1"),
            #"Column1 Expandido" = Table.ExpandRecordColumn(#"Column1 Expandido3", "Column1", {"engagement", "associations", "attachments", "metadata"}, {"engagement", "associations", "attachments", "metadata"})
        in
            #"Column1 Expandido",

    //Documentação dos parâmetros
    Doc_func = 
        type function (
            entityType as (type text meta [
                Documentation.FieldCaption = "Tipo",
                Documentation.AllowedValues = {"objects", "properties", "engagements"}
            ]),
             optional objectType as (type text meta [
                Documentation.FieldCaption = "Objeto",
                Documentation.AllowedValues = {"company", "contact", "deal", "ticket"}
            ]),
            optional propertyList as (type list meta [
                Documentation.FieldCaption = "Propriedades"
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