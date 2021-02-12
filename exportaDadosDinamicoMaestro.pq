let 
    //Código da função
    exportaDadosDinamico =
        (
            parametro,   
            filtra_data,
            optional atualizar_data_fim,
            optional parametro_data_inicio, 
            optional parametro_data_fim, 
            optional limite_tempo
        ) =>

        let 
            Resultado =
                if filtra_data = true
                then exportaDadosDinamicoPorData(
                    parametro, 
                    parametro_data_inicio, 
                    parametro_data_fim, 
                    limite_tempo, 
                    atualizar_data_fim
                )
                else exportaDados(parametro)
        in
            Resultado,
    

    //Documentação dos parâmetros
    Doc_func = 
        type function (
            parametro as (type text meta [
                Documentation.FieldCaption = "Parâmetro",
                Documentation.SampleValues = {"{'empresa':'000'...}"}
            ]),
            filtra_data as (type logical meta [
                Documentation.FieldCaption = "Filtra data",
                Documentation.AllowedValues = {true, false}
            ]),
            optional atualizar_data_fim as (type logical meta [
                Documentation.FieldCaption = "Atualiza data fim dinamicamente",
                Documentation.AllowedValues = {true, false}
            ]),
            optional parametro_data_inicio as (type text meta [
                Documentation.FieldCaption = "Nome do parâmetro de data inicial",
                Documentation.SampleValues = {"""dataInicio"""}
            ]), 
            optional parametro_data_fim as (type text meta [
                Documentation.FieldCaption = "Nome do parâmetro de data final",
                Documentation.SampleValues = {"""dataFim"""}
            ]), 
            optional limite_tempo as (type number meta [
                Documentation.FieldCaption = "Limite de data (dias)",
                Documentation.SampleValues = {"30"}
            ])
        ) as table meta Documentation_Metadata,

    //Documentação da função
    Documentation_Metadata = 
        [
            Documentation.Name = "exportaDadosDinamicoMaestro",
            Documentation.Description = "Função que retorna o conteúdo de um Exporta Dados do Maestro, com requests dinâmicas para Exporta Dados com limite de data.",
            Documentation.Examples = 
                {
                    [
                        Description = "Exporta Dados sem parâmetros dinâmicos",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)""{'empresa':'000000','codigo':'00000','chave':'xxxxxxxxxxxxxxxx','tipoSaida':''}"",#(tab)//Parâmetro#(cr,lf,tab)false,#(tab)//Filtra Data#(cr,lf))",
                        Result = "Lista de registros do resultado do Exporta Dados, conteúdo variável"
                    ],
                    [
                        Description = "Exporta Dados com limite de data, atualização dinâmica até uma data fim definida",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)""{'empresa':'000000','codigo':'00000','chave':'xxxxxxxxxxxxxxxx','tipoSaida':'','dataInicial':'01/01/2020','dataFinal':'31/12/2020'}"",#(tab)//Parâmetro#(cr,lf,tab)true,#(tab)//Filtra Data#(cr,lf,tab)false,#(tab)//Atualiza data fim automaticamente#(cr,lf,tab)""dataInicial"",#(tab)//Nome do parâmetro de data inicial#(cr,lf,tab)""dataFinal"",#(tab)//Nome do parâmetro de data final#(cr,lf,tab)30#(tab)//Limite de data (dias)#(cr,lf))",
                        Result = "Lista de registros do resultado do Exporta Dados, conteúdo variável"
                    ],
                    [
                        Description = "Exporta Dados com parâmetro de data, atualização sem data fim definida",
                        Code = "exportaDadosDinamico(#(cr,lf,tab)""{'empresa':'000000','codigo':'00000','chave':'xxxxxxxxxxxxxxxx','tipoSaida':'','dataInicio':'01/01/2020','dataFim':'31/12/2020'}"",#(tab)//Parâmetro#(cr,lf,tab)true,#(tab)//Filtra Data#(cr,lf,tab)true,#(tab)//Atualiza data fim automaticamente#(cr,lf,tab)""dataInicio"",#(tab)//Nome do parâmetro de data inicial#(cr,lf,tab)""dataFim"",#(tab)//Nome do parâmetro de data final#(cr,lf,tab)60#(tab)//Limite de data (dias)#(cr,lf))",
                        Result = "Lista de registros do resultado do Exporta Dados, conteúdo variável"
                    ]
                }
        ],

    //Função auxiliar
    exportaDadosDinamicoPorData = 
        (
            parametro as text, 
            parametro_data_inicio as text, 
            parametro_data_fim as text, 
            limite_tempo as number, 
            atualizar_data_fim as logical
        ) as table =>

        let
            Datas = extrairDatas(parametro,parametro_data_inicio,parametro_data_fim,atualizar_data_fim),
            Diferenca = Duration.Days(Datas{1} - Datas{0}),
            ListaDatas = 
                if Diferenca <= limite_tempo 
                then {[Inicio=Datas{0}, Fim=Datas{1}]} 
                else List.Generate(
                    ()=> [
                        Inicio=Datas{0},
                        Fim=Inicio+#duration(limite_tempo-1,0,0,0)
                    ], 
                    each [Fim] < Datas{1}, 
                    each [
                        Inicio=[Fim]+#duration(1,0,0,0),
                        Fim=(
                            if Inicio+#duration(limite_tempo-1,0,0,0) <= Datas{1}
                            then Inicio+#duration(limite_tempo-1,0,0,0)
                            else Datas{1}
                        )
                    ]
                ),
            AcrescentarUltima =
                if List.Last(ListaDatas)[Fim] = Datas{1}
                then ListaDatas
                else List.Combine(
                    {
                        ListaDatas, 
                        {
                            [
                                Inicio=List.Last(ListaDatas)[Fim]+#duration(1,0,0,0), 
                                Fim=Datas{1}
                            ]
                        }
                    }
                ),
            Query = importarDados(
                parametro, 
                AcrescentarUltima, 
                parametro_data_inicio, 
                parametro_data_fim, 
                0, 
                List.Count(AcrescentarUltima)
            ),
            Resultado = Table.FromList(Query, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
        in
            Resultado,
    
    //Função auxiliar
    exportaDados = 
        (
            parametro as text
        ) as table =>

        let
            Query = 
                try Json.Document(
                    Web.Contents(
                        "https://www.maestro.inf.br/",
                        [
                            RelativePath="MExportaDados/exportadados", 
                            Query=
                                [
                                    parametro=alterarParametro(
                                        parametro, 
                                        "tipoSaida", 
                                        "json"
                                    )
                                ]
                        ]
                    ), 
                    65000
                ) 
                otherwise {},
            Resultado = Table.FromList(Query, Splitter.SplitByNothing(), null, null, ExtraValues.Error)
        in
            Resultado,

    //Função auxiliar
    extrairDatas = 
        (
            parametro as text,
            parametro_data_inicio as text,
            parametro_data_fim as text,
            atualizar_data_fim as logical
        )
        as list =>

        let
            Limpar = Text.BetweenDelimiters(parametro,"{","}"),
            Separar = Text.Split(Limpar, "','"),
            Tabela = Table.FromList(Separar, Splitter.SplitTextByDelimiter(":"), null, null, ExtraValues.Error),
            #"Valor Substituído" = Table.ReplaceValue(Tabela,"'","",Replacer.ReplaceText,{"Column1", "Column2"}),
            Filtro = Table.SelectRows(#"Valor Substituído", each [Column1] = parametro_data_inicio or [Column1] = parametro_data_fim),
            RemoverColunas = Table.RemoveColumns(Filtro, "Column1"),
            AlterarTipo = Table.TransformColumnTypes(RemoverColunas, {"Column2", type date}),
            ParaLista = AlterarTipo[Column2],
            Resultado = 
                if atualizar_data_fim = true
                then {ParaLista{0}, Date.From(DateTimeZone.SwitchZone(DateTimeZone.UtcNow(), -3))}
                else ParaLista
        in
            Resultado,

    //Função auxiliar
    alterarDatas = 
        (
            parametro as text,
            parametro_data_inicio as text,
            parametro_data_fim as text,
            data_inicio as date,
            data_fim as date
        )
        as text =>

        let
            Limpar = Text.BetweenDelimiters(parametro,"{","}"),
            Separar = Text.Split(Limpar, "','"),
            Tabela = Table.FromList(Separar, Splitter.SplitTextByDelimiter(":"), null, null, ExtraValues.Error),
            #"Valor Substituído" = Table.ReplaceValue(Tabela,"'","",Replacer.ReplaceText,{"Column1", "Column2"}),
            Transpose = Table.Transpose(#"Valor Substituído"),
            PromoverCabecalhos = Table.PromoteHeaders(Transpose),
            NovasDatas = Table.TransformColumns(PromoverCabecalhos, {{parametro_data_inicio, each Text.From(data_inicio)},{parametro_data_fim, each Text.From(data_fim)},{"tipoSaida", each "json"}}),
            RebaixarCabecalhos = Table.DemoteHeaders(NovasDatas),
            Transpose1 = Table.Transpose(RebaixarCabecalhos),
            TransformarColunas = Table.TransformColumns(Transpose1,{{"Column1", each Text.Combine({"'", _, "'"})},{"Column2", each Text.Combine({"'", _, "'"})}}),
            JuntarColunas = Table.CombineColumns(TransformarColunas, {"Column1", "Column2"}, Combiner.CombineTextByDelimiter(":", QuoteStyle.None), "Column1"),
            ParaLista = JuntarColunas[Column1],
            CombinarPartes = Text.Combine(ParaLista, ","),
            InserirChaves = Text.Combine({"{", CombinarPartes, "}"})
        in
            InserirChaves,

    //Função auxiliar        
    importarDados = 
        (
            parametro as text,
            datas as list,
            parametro_data_inicio as text,
            parametro_data_fim as text,
            cont as number,
            limite as number,
            optional lista_resultado as list
        )
        as list =>

        let
            DefinirLista = 
                if lista_resultado = null 
                then {} 
                else lista_resultado,
            ListaResultado = 
                if cont < limite
                then List.Combine(
                    {
                        DefinirLista,
                        try Json.Document(
                            Web.Contents(
                                "https://www.maestro.inf.br/",
                                [
                                    RelativePath="MExportaDados/exportadados",
                                    Query=
                                        [
                                            parametro=alterarDatas(
                                                parametro,
                                                parametro_data_inicio,
                                                parametro_data_fim,
                                                datas{cont}[Inicio],
                                                datas{cont}[Fim]
                                            )
                                        ]
                                ]
                            ),
                            65000
                        )
                        otherwise {}
                    }
                )
                else DefinirLista,
            Retorno = 
                if cont < limite
                then @importarDados(
                    parametro, 
                    datas, 
                    parametro_data_inicio, 
                    parametro_data_fim, 
                    cont+1,
                    limite, 
                    ListaResultado
                )
                else ListaResultado
        in
            Retorno,

    //Função auxiliar
    alterarParametro = 
        (
            parametro as text,
            nome_campo as text,
            valor as text
        )
        as text =>

        let
            Limpar = Text.BetweenDelimiters(parametro,"{","}"),
            Separar = Text.Split(Limpar, "','"),
            Tabela = Table.FromList(Separar, Splitter.SplitTextByDelimiter(":"), null, null, ExtraValues.Error),
            #"Valor Substituído" = Table.ReplaceValue(Tabela,"'","",Replacer.ReplaceText,{"Column1", "Column2"}),
            Transpose = Table.Transpose(#"Valor Substituído"),
            PromoverCabecalhos = Table.PromoteHeaders(Transpose),
            NovasDatas = Table.TransformColumns(PromoverCabecalhos, {{nome_campo, each Text.From(valor)}}),
            RebaixarCabecalhos = Table.DemoteHeaders(NovasDatas),
            Transpose1 = Table.Transpose(RebaixarCabecalhos),
            TransformarColunas = Table.TransformColumns(Transpose1,{{"Column1", each Text.Combine({"'", _, "'"})},{"Column2", each Text.Combine({"'", _, "'"})}}),
            JuntarColunas = Table.CombineColumns(TransformarColunas, {"Column1", "Column2"}, Combiner.CombineTextByDelimiter(":", QuoteStyle.None), "Column1"),
            ParaLista = JuntarColunas[Column1],
            CombinarPartes = Text.Combine(ParaLista, ","),
            InserirChaves = Text.Combine({"{", CombinarPartes, "}"})
        in
            InserirChaves
in
    Value.ReplaceType(
        exportaDadosDinamico, Doc_func
    )